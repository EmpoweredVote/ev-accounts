/**
 * run-cambridge-ocpf-ingest.ts
 *
 * Cambridge-targeted OCPF ingest. Ingests contributions for confirmed Cambridge
 * city-council sources only, skipping the 12 known high-volume statewide MA
 * candidates (Healey, Galvin, Campbell, etc.) that generate 75k+ contributions
 * per quarter and time out repeatedly before the Cambridge sources are reached.
 *
 * Semantics are identical to campaignFinanceScheduler.ts case 'ocpf':
 *   - Per-quarter chunks (2001–present)
 *   - isFutureQuarter guard
 *   - Resume-skip on completed cycle keys
 *   - 3-min AbortController timeout per cycle
 *   - Per-cycle zombie cleanup on error
 *
 * Does NOT call runAdapterForAll — that would re-include statewide filers via
 * the scheduler's own unfiltered SELECT.
 *
 * Usage (from C:\EV-Accounts\backend):
 *   npx tsx scripts/run-cambridge-ocpf-ingest.ts
 */

import 'dotenv/config';
import pg from 'pg';
import { runIngestion } from '../src/lib/adapters/runIngestion.js';
import { createOcpfAdapter } from '../src/lib/adapters/ocpfAdapter.js';

if (!process.env['DATABASE_URL']) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/**
 * 10 high-volume statewide MA filers to skip.
 * Each takes 75k+ contributions per quarter and reliably times out before
 * the Cambridge city-council sources are reached in the full ingest.
 *
 * NOTE: 18454 (Al-Zubi) and 13239 (Flaherty) were removed 2026-05-18 —
 * both are Cambridge city councillors (elected Nov 2023) with minimal
 * contribution history; they were mistakenly included in the original list.
 */
const HIGH_VOLUME_CPFIDS = new Set<string>([
  '13783', '12008', '15470', '15465', '15268',
  '15931', '15710', '15483', '13736', '10176',
]);

const OCPF_START_YEAR = 2001;
const PER_YEAR_TIMEOUT_MS = 3 * 60 * 1000; // 3-min hard limit per (source, cycleKey)

// ---------------------------------------------------------------------------
// isFutureQuarter — copied verbatim from campaignFinanceScheduler.ts (not exported)
// ---------------------------------------------------------------------------

/**
 * isFutureQuarter returns true when the given (year, quarter) has not started yet
 * as of `now`. Used to avoid creating ingestion_runs rows for quarters that
 * cannot possibly have data yet (e.g. Q3 2026 in May 2026).
 *
 * A quarter is considered "arrived" once its first day has passed in UTC.
 * Quarter start months: Q1=Jan (0), Q2=Apr (3), Q3=Jul (6), Q4=Oct (9).
 */
function isFutureQuarter(year: number, quarter: 1 | 2 | 3 | 4, now: Date): boolean {
  const startMonth = (quarter - 1) * 3;
  const quarterStart = Date.UTC(year, startMonth, 1);
  return now.getTime() < quarterStart;
}

// ---------------------------------------------------------------------------
// PoliticianSourceRow type (mirrors campaignFinanceScheduler.ts)
// ---------------------------------------------------------------------------

interface PoliticianSourceRow {
  id: string;
  essentials_politician_id: string;
  source_system: string;
  external_id: string;
  research_status: string;
  notes: string;
  created_at: string;
  updated_at: string;
}

// ---------------------------------------------------------------------------
// Pool
// ---------------------------------------------------------------------------

const pool = new pg.Pool({ connectionString: process.env['DATABASE_URL'] });

// ---------------------------------------------------------------------------
// Step 1: Query filtered sources (exclude HIGH_VOLUME_CPFIDS)
// ---------------------------------------------------------------------------

console.log('[run-cambridge-ocpf] Step 1: Querying Cambridge OCPF sources (skipping statewide filers)...');

const skipPlaceholders = Array.from(HIGH_VOLUME_CPFIDS).map((_, i) => `$${i + 1}`).join(', ');

const sourcesResult = await pool.query<PoliticianSourceRow>(
  `SELECT id, essentials_politician_id, source_system, external_id,
          research_status, notes, created_at, updated_at
   FROM transparent_motivations.politician_sources
   WHERE source_system = 'ocpf'
     AND research_status = 'confirmed'
     AND external_id NOT IN (${skipPlaceholders})`,
  Array.from(HIGH_VOLUME_CPFIDS)
);

const filteredSources = sourcesResult.rows;

if (filteredSources.length === 0) {
  console.log('[run-cambridge-ocpf] No Cambridge sources found — nothing to ingest. Exiting.');
  await pool.end();
  process.exit(0);
}

console.log(`[run-cambridge-ocpf] Found ${filteredSources.length} source(s) to process:`);
filteredSources.forEach((ps) => console.log(`  id=${ps.id} external_id=${ps.external_id}`));

// ---------------------------------------------------------------------------
// Step 2: Clean zombie runs scoped to filtered source UUIDs only
// ---------------------------------------------------------------------------

console.log('\n[run-cambridge-ocpf] Step 2: Cleaning zombie ingestion_runs for Cambridge sources...');

const filteredSourceIds = filteredSources.map((ps) => ps.id);

const zombieResult = await pool.query(
  `UPDATE transparent_motivations.ingestion_runs
   SET status = 'failed', completed_at = NOW(),
       notes = 'Marked failed by run-cambridge-ocpf-ingest.ts — prior interrupted run'
   WHERE status = 'running'
     AND politician_source_id = ANY($1::uuid[])
   RETURNING id, politician_source_id`,
  [filteredSourceIds]
);

if (zombieResult.rowCount === 0) {
  console.log('[run-cambridge-ocpf] No zombie runs found — already clean.');
} else {
  console.log(`[run-cambridge-ocpf] Marked ${zombieResult.rowCount} zombie run(s) as failed:`);
  zombieResult.rows.forEach((r: Record<string, unknown>) =>
    console.log(`  run id=${r['id']} politician_source_id=${r['politician_source_id']}`)
  );
}

// ---------------------------------------------------------------------------
// Step 3: Per-source ingest loop (identical semantics to case 'ocpf': in scheduler)
// ---------------------------------------------------------------------------

console.log('\n[run-cambridge-ocpf] Step 3: Beginning per-source ingest loop...');

const now = new Date();
const currentYear = now.getUTCFullYear();

for (const ps of filteredSources) {
  try {
    // Query all completed cycle keys for this source. The regex matches BOTH
    // legacy full-year entries ('YYYY') and new per-quarter entries ('YYYY-QN').
    // Legacy empty-string election_cycle rows (very old all-history runs) are
    // intentionally excluded by the regex so they don't mask any quarter.
    const completedResult = await pool.query<{ election_cycle: string }>(
      `SELECT DISTINCT election_cycle
         FROM transparent_motivations.ingestion_runs
         WHERE adapter_name = 'ocpf'
           AND politician_source_id = $1
           AND status IN ('completed', 'completed_with_warning')
           AND election_cycle ~ '^[0-9]{4}(-Q[1-4])?$'`,
      [ps.id]
    );
    const completedCycles = new Set<string>(
      completedResult.rows.map((r) => r.election_cycle)
    );

    for (let year = OCPF_START_YEAR; year <= currentYear; year++) {
      const yearStr = String(year);

      // Backward-compat: if a full-year run completed previously, treat all
      // four quarters of that year as done. Do NOT re-fetch them.
      // Exception: always continue into current year (catches late filings).
      if (year !== currentYear && completedCycles.has(yearStr)) {
        continue;
      }

      // Active quarter of the current year (1-4, UTC month-based)
      const activeQuarter = (Math.floor(now.getUTCMonth() / 3) + 1) as 1 | 2 | 3 | 4;

      for (let q = 1 as 1 | 2 | 3 | 4; q <= 4; q = (q + 1) as 1 | 2 | 3 | 4) {
        // Skip quarters whose first calendar day has not arrived yet
        if (isFutureQuarter(year, q, now)) continue;

        const cycleKey = `${year}-Q${q}`;

        // Skip already-completed quarters, EXCEPT for the active quarter of the
        // current year which is re-run on every tick to catch late filings.
        const isCurrentActiveQuarter = (year === currentYear && q === activeQuarter);
        if (completedCycles.has(cycleKey) && !isCurrentActiveQuarter) {
          continue;
        }

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(new Error(
          `[ocpf] per-cycle timeout (${PER_YEAR_TIMEOUT_MS}ms): source=${ps.id} cycle=${cycleKey}`
        )), PER_YEAR_TIMEOUT_MS);

        try {
          await runIngestion(
            createOcpfAdapter(year, controller.signal, q),
            ps,
            cycleKey
          );
          console.log(`[run-cambridge-ocpf] ocpf: source=${ps.id} cycle=${cycleKey} done`);
        } catch (err) {
          console.error(
            `[run-cambridge-ocpf] ocpf: source=${ps.id} cycle=${cycleKey} error:`,
            err instanceof Error ? err.message : String(err)
          );
          await pool.query(
            `UPDATE transparent_motivations.ingestion_runs
             SET status = 'failed', completed_at = NOW(), notes = $1
             WHERE status = 'running'
               AND politician_source_id = $2
               AND election_cycle = $3`,
            [err instanceof Error ? err.message : String(err), ps.id, cycleKey]
          ).catch((e: unknown) => console.warn('[run-cambridge-ocpf] ocpf: zombie cleanup failed:', e));
        } finally {
          clearTimeout(timeoutId);
        }
      }
    }
  } catch (err) {
    console.error(
      `[run-cambridge-ocpf] ocpf: source=${ps.id} pre-flight error:`,
      err instanceof Error ? err.message : String(err)
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: Cleanup
// ---------------------------------------------------------------------------

await pool.end();
console.log('[run-cambridge-ocpf] Complete.');
