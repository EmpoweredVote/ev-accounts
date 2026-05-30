/**
 * recache-user-districts.ts — Admin bulk re-cache for connect.user_districts.
 *
 * Usage:
 *   npx tsx scripts/recache-user-districts.ts                         # re-cache ALL Connected users
 *   npx tsx scripts/recache-user-districts.ts --before=2026-05-09     # only users stale before date
 *   npx tsx scripts/recache-user-districts.ts --dry-run               # preview count, no DB writes
 *   npx tsx scripts/recache-user-districts.ts --user=<uuid>           # single user (per-user RPC)
 *
 * Purpose:
 *   After a redistricting event or new TIGER data import, admin operators run
 *   this script to refresh connect.user_districts for every affected Connected
 *   user without waiting for each user to update their location individually.
 *
 * Critical constraints:
 *   - Decryption happens entirely inside Postgres via the Vault location_encryption_key.
 *     No plaintext lat/lng ever enters Node.js.
 *   - Uses pool.query (raw pg) — NOT the Supabase JS client. The essentials schema is
 *     not in the PostgREST exposed list; direct Postgres access is required.
 *   - Idempotent: re-running produces the same connect.user_districts state because
 *     cache_user_districts uses ON CONFLICT (user_id, layer) DO UPDATE.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const LOG_PREFIX = '[recache-user-districts]';

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error(`${LOG_PREFIX} ERROR: DATABASE_URL is not set. Aborting.`);
  process.exit(1);
}

// ─── Arg parsing ─────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');

const beforeArg = args.find((a) => a.startsWith('--before='));
const cutoffDate: string | null = beforeArg ? beforeArg.replace('--before=', '') : null;

const userArg = args.find((a) => a.startsWith('--user='));
const targetUser: string | null = userArg ? userArg.replace('--user=', '') : null;

// Validate --before= if supplied
if (cutoffDate && isNaN(Date.parse(cutoffDate))) {
  console.error(`${LOG_PREFIX} ERROR: --before=${cutoffDate} is not a valid ISO date. Example: --before=2026-05-09`);
  process.exit(1);
}

// Build a timestamptz string for Postgres: full ISO-8601 with time at start of day UTC
const cutoffTimestamp: string | null = cutoffDate ? `${cutoffDate}T00:00:00Z` : null;

console.log(`${LOG_PREFIX} Mode: ${isDryRun ? 'DRY-RUN (no DB writes)' : 'LIVE RUN'}`);
if (targetUser) {
  console.log(`${LOG_PREFIX} Target user: ${targetUser}`);
} else if (cutoffTimestamp) {
  console.log(`${LOG_PREFIX} Cutoff: users with user_districts.resolved_at < ${cutoffTimestamp}`);
} else {
  console.log(`${LOG_PREFIX} Scope: ALL Connected users with encrypted coords + location_consent`);
}

// ─── DB Pool ─────────────────────────────────────────────────────────────────

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Types ────────────────────────────────────────────────────────────────────

interface RecacheRow {
  user_id: string;
  layers_resolved: number;
  status: string;
}

interface DryRunCount {
  would_process: string;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {

  // ── Single-user mode ──────────────────────────────────────────────────────

  if (targetUser) {
    if (isDryRun) {
      console.log(`${LOG_PREFIX} DRY-RUN: would call recache_user_districts_for_user('${targetUser}')`);
      return;
    }
    const { rows } = await pool.query<RecacheRow>(
      `SELECT user_id, layers_resolved, status
         FROM essentials.recache_user_districts_for_user($1)`,
      [targetUser]
    );
    const row = rows[0];
    if (!row) {
      console.error(`${LOG_PREFIX} No result row returned for user ${targetUser}`);
      process.exit(1);
    }
    console.log(`${LOG_PREFIX} user_id=${row.user_id}  layers_resolved=${row.layers_resolved}  status=${row.status}`);
    if (row.status.startsWith('error')) {
      process.exit(1);
    }
    return;
  }

  // ── Dry-run mode (bulk) ────────────────────────────────────────────────────

  if (isDryRun) {
    // Mirror the bulk function's HAVING clause to report the count without writing.
    const { rows } = await pool.query<DryRunCount>(
      `SELECT COUNT(*) AS would_process
         FROM (
           SELECT cp.user_id
             FROM connect.connected_profiles cp
             LEFT JOIN connect.user_districts ud ON ud.user_id = cp.user_id
            WHERE cp.encrypted_lat IS NOT NULL
              AND cp.location_consent = true
            GROUP BY cp.user_id
           HAVING ($1::timestamptz IS NULL
                   OR COALESCE(MIN(ud.resolved_at), '-infinity'::timestamptz) < $1::timestamptz)
         ) sub`,
      [cutoffTimestamp]
    );
    const count = rows[0]?.would_process ?? '0';
    console.log(`${LOG_PREFIX} DRY-RUN: ${count} user(s) would be processed.`);
    console.log(`${LOG_PREFIX} DRY-RUN complete — no database writes made.`);
    return;
  }

  // ── Live bulk run ─────────────────────────────────────────────────────────

  console.log(`${LOG_PREFIX} Calling essentials.recache_user_districts_bulk...`);

  const { rows } = await pool.query<RecacheRow>(
    `SELECT user_id, layers_resolved, status
       FROM essentials.recache_user_districts_bulk($1)`,
    [cutoffTimestamp]
  );

  // Tally results by status category
  let okCount = 0;
  let noCoordsCount = 0;
  let outOfCaCount = 0;
  let errorCount = 0;

  for (const row of rows) {
    if (row.status === 'ok' && row.layers_resolved > 0) {
      okCount++;
    } else if (row.status === 'ok' && row.layers_resolved === 0) {
      // Point resolved but matched zero TIGER districts — out-of-CA user
      outOfCaCount++;
      console.log(`${LOG_PREFIX} out-of-CA: ${row.user_id} (0 layers resolved)`);
    } else if (row.status === 'no_coords') {
      noCoordsCount++;
    } else if (row.status.startsWith('error')) {
      errorCount++;
      console.error(`${LOG_PREFIX} ERROR: ${row.user_id} — ${row.status}`);
    }
  }

  console.log(`\n${LOG_PREFIX} Summary:`);
  console.log(`${LOG_PREFIX}   Total processed:          ${rows.length}`);
  console.log(`${LOG_PREFIX}   Districts refreshed (ok): ${okCount}`);
  console.log(`${LOG_PREFIX}   Out-of-CA (0 layers):     ${outOfCaCount}`);
  console.log(`${LOG_PREFIX}   No coords / no consent:   ${noCoordsCount}`);
  console.log(`${LOG_PREFIX}   Errors:                   ${errorCount}`);

  if (errorCount > 0) {
    console.error(`\n${LOG_PREFIX} Completed with ${errorCount} error(s). See above for details.`);
    process.exit(1);
  } else {
    console.log(`\n${LOG_PREFIX} Re-cache complete.`);
  }
}

main()
  .catch((err: unknown) => {
    console.error(`${LOG_PREFIX} Fatal error:`, err);
    process.exit(1);
  })
  .finally(() => {
    void pool.end();
  });
