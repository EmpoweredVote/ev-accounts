/**
 * run-judicial-cal-access-smoketest.ts — operator-run end-to-end smoke test:
 * drives the UNMODIFIED calAccessAdapter.ts (fetch + normalize only) via the
 * Plan 30-02 fake-PoliticianSource wrapper, and writes attributed judicial
 * donation rows into judicial.donations for the seeded smoke-test judges.
 *
 * Usage:
 *   cd /c/EV-Accounts/backend && npx tsx scripts/run-judicial-cal-access-smoketest.ts
 *
 * Requires environment variables:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * Prerequisite: scripts/seed-judicial-smoketest-judges.ts must have been run
 * first, with real operator-verified cal_access_filer_ids populated on each
 * judicial.judges row (this script does NOT seed judges itself).
 *
 * IMPORTANT: All ingest is via direct function calls (not HTTP). Cloudflare
 * blocks POST to accounts.empowered.vote — never use curl/fetch against the
 * deployed API for this ingest.
 *
 * What it does:
 *   1. Queries judicial.judges for seeded rows (id, full_name, external_ids).
 *   2. Constructs ONE createCalAccessAdapter() instance for the whole run
 *      (shares the ZIP cache across all judges/filer IDs).
 *   3. For each judge, for each cal_access_filer_id: builds a fake
 *      PoliticianSource via buildFakePoliticianSource(judge.id, filerId),
 *      calls the adapter's unmodified fetch()/normalize(), then writes via
 *      writeJudicialDonations(). Per-judge/per-filer errors are isolated
 *      (logged, loop continues) rather than aborting the whole run.
 *   4. Does NOT call the adapter's contributions-table write method (D-11) or
 *      its ETag-persistence method — targeted/partial runs never save the
 *      shared production Cal-Access ETag cache (mirrors
 *      campaignFinanceScheduler.ts's runAdapterForSources(), lines ~564-568:
 *      "ETag ownership belongs to the full scheduled run only"). Does NOT
 *      route through the shared ingestion-run helper (couples to
 *      transparent_motivations.ingestion_runs + the adapter's own write path —
 *      wrong table, D-08/D-11). Per Discretion (a), plain structured
 *      console.log is the audit trail for this one-time smoke test.
 *   5. Before exit, runs the JUD-ING-06 post-run attribution assertion and
 *      logs the total judicial.donations row count.
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { createCalAccessAdapter } from '../src/lib/adapters/calAccessAdapter.js';
import { buildFakePoliticianSource, writeJudicialDonations } from '../src/lib/judicial/judicialCalAccessIngest.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

interface JudgeRow {
  id: string;
  full_name: string;
  court: string;
  external_ids: { cal_access_filer_ids?: string[] } | null;
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function main() {
  const startMs = Date.now();
  console.log('[run-judicial-cal-access-smoketest] Starting...');

  try {
    // Step 1: Load seeded judges.
    const judgesRes = await pool.query<JudgeRow>(
      `SELECT id, full_name, court, external_ids FROM judicial.judges ORDER BY full_name`
    );

    if (judgesRes.rows.length === 0) {
      console.error(
        '[run-judicial-cal-access-smoketest] ABORT: judicial.judges is empty. ' +
          'Run scripts/seed-judicial-smoketest-judges.ts first.'
      );
      process.exit(1);
    }

    console.log(`[run-judicial-cal-access-smoketest] Loaded ${judgesRes.rows.length} judge(s).`);

    // Step 2: One adapter instance for the whole run — shares the ZIP cache
    // across every judge/filer ID (unmodified calAccessAdapter.ts).
    const adapter = createCalAccessAdapter();

    let totalInserted = 0;
    let totalSkipped = 0;

    // Step 3: For each judge, for each filer ID, fetch -> normalize -> write.
    for (const judge of judgesRes.rows) {
      const filerIds = judge.external_ids?.cal_access_filer_ids ?? [];

      if (filerIds.length === 0) {
        console.warn(
          `[run-judicial-cal-access-smoketest] [judge=${judge.full_name}] no cal_access_filer_ids — skipping.`
        );
        continue;
      }

      for (const filerId of filerIds) {
        try {
          const fakePs = buildFakePoliticianSource(judge.id, filerId);
          const raw = await adapter.fetch(fakePs);
          const norm = await adapter.normalize(raw, fakePs);
          const { inserted, skipped } = await writeJudicialDonations(judge.id, norm.contributions);

          totalInserted += inserted;
          totalSkipped += skipped;

          console.log(
            `  [judge=${judge.full_name}, filerId=${filerId}] fetched=${raw.totalFetched}, ` +
              `parsed=${norm.totalParsed}, inserted=${inserted}, skipped=${skipped}`
          );
        } catch (err) {
          console.error(
            `  [judge=${judge.full_name}, filerId=${filerId}] error:`,
            err instanceof Error ? err.message : String(err)
          );
          // Non-aborting: continue to next filer/judge.
        }
      }
    }

    console.log(
      `\n[run-judicial-cal-access-smoketest] Run summary: totalInserted=${totalInserted}, totalSkipped=${totalSkipped}`
    );

    // Deliberately do NOT persist the adapter's ETag here — see file header /
    // Discretion (a) / campaignFinanceScheduler.ts lines ~564-568.

    // Step 4: JUD-ING-06 post-run attribution assertion.
    const badRes = await pool.query<{ count: string }>(
      `SELECT COUNT(*) FROM judicial.donations
       WHERE source_transaction_id = '' OR source_url = '' OR confidence_level IS NULL OR raw_record = '{}'::jsonb`
    );
    const badCount = Number(badRes.rows[0].count);
    if (badCount !== 0) {
      console.error(`[run-judicial-cal-access-smoketest] FAIL: attribution columns incomplete (${badCount} row(s))`);
      process.exit(1);
    }
    console.log('[run-judicial-cal-access-smoketest] JUD-ING-06 attribution assertion: PASSED (0 incomplete rows)');

    // Step 5: Log total judicial.donations row count (SC#2 confirmation).
    const totalRes = await pool.query<{ count: string }>(`SELECT COUNT(*) FROM judicial.donations`);
    console.log(`[run-judicial-cal-access-smoketest] Total judicial.donations rows: ${totalRes.rows[0].count}`);

    const durationMs = Date.now() - startMs;
    console.log(`\n[run-judicial-cal-access-smoketest] Completed in ${(durationMs / 1000).toFixed(1)}s`);
    process.exit(0);
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('[run-judicial-cal-access-smoketest] Fatal error:', err);
  process.exit(1);
});
