/**
 * backfill-pre-phase49-geo-ids.ts — One-time backfill for pre-Phase-49 Connected users.
 *
 * Usage:
 *   npx tsx scripts/backfill-pre-phase49-geo-ids.ts --dry-run   # preview, no DB writes
 *   npx tsx scripts/backfill-pre-phase49-geo-ids.ts              # live run
 *
 * What it does:
 *   Finds all Connected users who have encrypted coordinates (encrypted_lat IS NOT NULL),
 *   have given location consent (location_consent = true), and have not yet had their
 *   jurisdiction columns populated (congressional_geo_id IS NULL). For each such user,
 *   calls the resolve_user_jurisdiction RPC to derive geo_ids + district names and writes
 *   all 10 columns back to connect.connected_profiles.
 *
 * Critical constraints:
 *   - Only processes users with location_consent = true — the RPC raises an EXCEPTION for
 *     users with consent=false (it refuses to decrypt their coordinates).
 *   - Users whose coordinates fall outside all loaded boundaries log a warning and are
 *     counted as "still null (geofence gap)" — this is expected for users in states not
 *     yet loaded.
 *   - All writes gated behind if (!isDryRun).
 *   - Uses pool.query for all DB access — no Supabase client in scripts.
 */

import 'dotenv/config';
import { Pool } from 'pg';

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── Arg parsing ─────────────────────────────────────────────────────────────

const isDryRun = process.argv.includes('--dry-run');
console.log(`[backfill-pre-phase49-geo-ids] Mode: ${isDryRun ? 'DRY-RUN (no DB writes)' : 'LIVE RUN'}`);

// ─── DB Pool ─────────────────────────────────────────────────────────────────

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Types ────────────────────────────────────────────────────────────────────

interface JurisdictionResult {
  congressional:           string | null;
  congressional_name:      string | null;
  state_senate:            string | null;
  state_senate_name:       string | null;
  state_house:             string | null;
  state_house_name:        string | null;
  county:                  string | null;
  county_name:             string | null;
  school_district:         string | null;
  school_district_name:    string | null;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  // Find affected users: encrypted_lat present, location_consent=true, geo_ids not yet stored
  const { rows: affected } = await pool.query<{ user_id: string }>(
    `SELECT user_id
     FROM connect.connected_profiles
     WHERE encrypted_lat IS NOT NULL
       AND location_consent = true
       AND congressional_geo_id IS NULL`
  );

  console.log(`Found ${affected.length} users with encrypted coords but no geo_ids`);

  if (affected.length === 0) {
    console.log('Nothing to do.');
    return;
  }

  let fixed = 0;
  let stillNull = 0;
  let errors = 0;

  for (const { user_id } of affected) {
    try {
      // Call the RPC via pool.query — SECURITY DEFINER function needs Vault access.
      // The function decrypts encrypted_lat/lng from Vault and performs the spatial lookup.
      const { rows: rpcRows } = await pool.query<{ j: JurisdictionResult | null }>(
        `SELECT connect.resolve_user_jurisdiction($1) AS j`,
        [user_id]
      );
      const j = rpcRows[0]?.j ?? null;

      if (!j || !j.congressional) {
        console.log(`[backfill] ${user_id}: no boundary match (geofence gap)`);
        stillNull++;
        continue;
      }

      if (!isDryRun) {
        await pool.query(
          `UPDATE connect.connected_profiles
           SET congressional_geo_id         = $2,
               congressional_district_name  = $3,
               state_senate_geo_id          = $4,
               state_senate_district_name   = $5,
               state_house_geo_id           = $6,
               state_house_district_name    = $7,
               county_geo_id                = $8,
               county_name                  = $9,
               school_district_geo_id       = $10,
               school_district_name         = $11,
               updated_at                   = now()
           WHERE user_id = $1`,
          [
            user_id,
            j.congressional,      j.congressional_name,
            j.state_senate,       j.state_senate_name,
            j.state_house,        j.state_house_name,
            j.county,             j.county_name,
            j.school_district,    j.school_district_name,
          ]
        );
        console.log(`[backfill] ${user_id}: fixed (congressional=${j.congressional})`);
      } else {
        console.log(`[backfill] ${user_id}: would fix (congressional=${j.congressional})`);
      }
      fixed++;
    } catch (e) {
      console.error(`[backfill] ${user_id}: error — ${(e as Error).message}`);
      errors++;
    }
  }

  console.log(`\nSummary:`);
  console.log(`  Total affected:                ${affected.length}`);
  console.log(`  ${isDryRun ? 'Would fix' : 'Fixed'}:${' '.repeat(isDryRun ? 24 : 26)}${fixed}`);
  console.log(`  Still null (geofence gap):     ${stillNull}`);
  console.log(`  Errors:                        ${errors}`);

  if (isDryRun) {
    console.log('\nDRY-RUN complete — no database writes made.');
  } else {
    console.log('\nBackfill complete.');
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
}).finally(() => {
  void pool.end();
});
