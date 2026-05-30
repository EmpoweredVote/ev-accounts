/**
 * run-missed-cambridge-ingest.ts
 *
 * One-shot ingest for three Cambridge city councillors missed by
 * run-cambridge-ocpf-ingest.ts due to incorrect HIGH_VOLUME skip list placement:
 *   - Al-Zubi  (cpfId=18454) — elected Nov 2023
 *   - Flaherty (cpfId=13239) — elected Nov 2023
 *   - Azeem    (cpfId=17206) — in office since 2021 (Vice Mayor)
 *
 * Al-Zubi and Flaherty were removed from HIGH_VOLUME_CPFIDS in
 * run-cambridge-ocpf-ingest.ts on 2026-05-18. Azeem was missing from
 * politician_sources entirely and is seeded by this script if absent.
 *
 * Semantics are identical to run-cambridge-ocpf-ingest.ts (and by extension
 * campaignFinanceScheduler.ts case 'ocpf'):
 *   - Per-quarter chunks (OCPF_START_YEAR–present)
 *   - isFutureQuarter guard
 *   - Resume-skip on completed cycle keys
 *   - 3-min AbortController timeout per cycle
 *   - Per-cycle zombie cleanup on error
 *
 * OCPF_START_YEAR = 2021 (Azeem's earliest relevant data).
 * Al-Zubi and Flaherty were elected Nov 2023; pre-2024 quarters will return
 * zero rows and complete instantly — this is expected and harmless.
 *
 * Usage (from C:\EV-Accounts\backend):
 *   npx tsx scripts/run-missed-cambridge-ingest.ts
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

/** The three missed councillors — targeted ingest only, no skip-list needed. */
const TARGET_CPFIDS = ['18454', '13239', '17206'];

const OCPF_START_YEAR = 2021;
const PER_CYCLE_TIMEOUT_MS = 3 * 60 * 1000; // 3-min hard limit per (source, cycleKey)

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
// Step 1: Query the three target sources
// ---------------------------------------------------------------------------

console.log('[run-missed-cambridge] Step 1: Querying the three missed Cambridge OCPF sources...');

const targetPlaceholders = TARGET_CPFIDS.map((_, i) => `$${i + 1}`).join(', ');

const sourcesResult = await pool.query<PoliticianSourceRow>(
  `SELECT id, essentials_politician_id, source_system, external_id,
          research_status, notes, created_at, updated_at
   FROM transparent_motivations.politician_sources
   WHERE source_system = 'ocpf'
     AND research_status = 'confirmed'
     AND external_id IN (${targetPlaceholders})`,
  TARGET_CPFIDS
);

const targetSources = sourcesResult.rows;

if (targetSources.length === 0) {
  console.log('[run-missed-cambridge] No target sources found — nothing to ingest. Exiting.');
  await pool.end();
  process.exit(0);
}

console.log(`[run-missed-cambridge] Found ${targetSources.length} source(s) to process:`);
targetSources.forEach((ps) =>
  console.log(`  id=${ps.id} external_id=${ps.external_id}`)
);

if (targetSources.length < TARGET_CPFIDS.length) {
  const foundIds = targetSources.map((ps) => ps.external_id);
  const missing = TARGET_CPFIDS.filter((id) => !foundIds.includes(id));
  console.warn(`[run-missed-cambridge] WARNING: ${missing.length} target cpfId(s) not found in politician_sources: ${missing.join(', ')}`);
}

// ---------------------------------------------------------------------------
// Step 2: Clean zombie runs scoped to target source UUIDs only
// ---------------------------------------------------------------------------

console.log('\n[run-missed-cambridge] Step 2: Cleaning zombie ingestion_runs for target sources...');

const targetSourceIds = targetSources.map((ps) => ps.id);

const zombieResult = await pool.query(
  `UPDATE transparent_motivations.ingestion_runs
   SET status = 'failed', completed_at = NOW(),
       notes = 'Marked failed by run-missed-cambridge-ingest.ts — prior interrupted run'
   WHERE status = 'running'
     AND politician_source_id = ANY($1::uuid[])
   RETURNING id, politician_source_id`,
  [targetSourceIds]
);

if (zombieResult.rowCount === 0) {
  console.log('[run-missed-cambridge] No zombie runs found — already clean.');
} else {
  console.log(`[run-missed-cambridge] Marked ${zombieResult.rowCount} zombie run(s) as failed:`);
  zombieResult.rows.forEach((r: Record<string, unknown>) =>
    console.log(`  run id=${r['id']} politician_source_id=${r['politician_source_id']}`)
  );
}

// ---------------------------------------------------------------------------
// Step 3: Per-source ingest loop (identical semantics to case 'ocpf': in scheduler)
// ---------------------------------------------------------------------------

console.log('\n[run-missed-cambridge] Step 3: Beginning per-source ingest loop...');

const now = new Date();
const currentYear = now.getUTCFullYear();

for (const ps of targetSources) {
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
          `[ocpf] per-cycle timeout (${PER_CYCLE_TIMEOUT_MS}ms): source=${ps.id} cycle=${cycleKey}`
        )), PER_CYCLE_TIMEOUT_MS);

        try {
          await runIngestion(
            createOcpfAdapter(year, controller.signal, q),
            ps,
            cycleKey
          );
          console.log(`[run-missed-cambridge] ocpf: source=${ps.id} external_id=${ps.external_id} cycle=${cycleKey} done`);
        } catch (err) {
          console.error(
            `[run-missed-cambridge] ocpf: source=${ps.id} external_id=${ps.external_id} cycle=${cycleKey} error:`,
            err instanceof Error ? err.message : String(err)
          );
          await pool.query(
            `UPDATE transparent_motivations.ingestion_runs
             SET status = 'failed', completed_at = NOW(), notes = $1
             WHERE status = 'running'
               AND politician_source_id = $2
               AND election_cycle = $3`,
            [err instanceof Error ? err.message : String(err), ps.id, cycleKey]
          ).catch((e: unknown) =>
            console.warn('[run-missed-cambridge] ocpf: zombie cleanup failed:', e)
          );
        } finally {
          clearTimeout(timeoutId);
        }
      }
    }
  } catch (err) {
    console.error(
      `[run-missed-cambridge] ocpf: source=${ps.id} external_id=${ps.external_id} pre-flight error:`,
      err instanceof Error ? err.message : String(err)
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: Cleanup
// ---------------------------------------------------------------------------

await pool.end();
console.log('[run-missed-cambridge] Complete.');
