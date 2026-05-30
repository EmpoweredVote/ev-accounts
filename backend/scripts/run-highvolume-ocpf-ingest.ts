/**
 * run-highvolume-ocpf-ingest.ts
 *
 * Targeted OCPF ingest for the 10 high-volume statewide MA filers that time out
 * at per-quarter granularity (~300 pages × 0.5s ≈ 150s → timeout at 180s).
 * Splits each calendar quarter into individual months (~100 pages × 0.5s ≈ 50s)
 * to stay well within the 3-minute budget.
 *
 * Resume logic honours legacy full-year, per-quarter, AND new per-month cycle keys.
 *
 * Usage (from C:\EV-Accounts\backend):
 *   npx tsx scripts/run-highvolume-ocpf-ingest.ts
 */

import 'dotenv/config';
import pg from 'pg';
import { runIngestion } from '../src/lib/adapters/runIngestion.js';
import { createOcpfAdapter } from '../src/lib/adapters/ocpfAdapter.js';
import type { Month } from '../src/lib/adapters/ocpfAdapter.js';

if (!process.env['DATABASE_URL']) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/**
 * 10 high-volume statewide MA filers.
 * Each generates 75k+ contributions per quarter and reliably times out at
 * per-quarter granularity. This script splits each quarter into 3 monthly
 * chunks (~25k/month = ~100 pages = ~50s each) to stay under the 3-min budget.
 */
const HIGH_VOLUME_CPFIDS = new Set<string>([
  '13783', '12008', '15470', '15465', '15268',
  '15931', '15710', '15483', '13736', '10176',
]);

/**
 * Subset that are so large they time out even at monthly granularity (~300 pages/month).
 * These use 7-day weekly chunks (~70 pages/week = ~35s) with cycle keys YYYY-WNN.
 */
const WEEK_GRANULARITY_CPFIDS = new Set<string>(['15931', '15710']);

const OCPF_START_YEAR = 2001;
const PER_YEAR_TIMEOUT_MS = 3 * 60 * 1000; // kept for naming consistency with cambridge script

// ---------------------------------------------------------------------------
// isFutureMonth
// ---------------------------------------------------------------------------

/**
 * isFutureMonth returns true when the first day of (year, month) has not
 * yet arrived as of `now` (UTC). Used to skip months with no possible data.
 */
function isFutureMonth(year: number, month: Month, now: Date): boolean {
  const monthStart = Date.UTC(year, month - 1, 1);
  return now.getTime() < monthStart;
}

/**
 * weekWindows returns all 7-day windows for a calendar year as
 * { weekNum, start, end } objects. The last window extends to Dec 31
 * to avoid leaving a gap. Dates are in MM/DD/YYYY format for the OCPF API.
 */
function weekWindows(year: number): Array<{ weekNum: number; start: string; end: string }> {
  const fmt = (d: Date) => {
    const mm = String(d.getUTCMonth() + 1).padStart(2, '0');
    const dd = String(d.getUTCDate()).padStart(2, '0');
    return `${mm}/${dd}/${d.getUTCFullYear()}`;
  };
  const windows: Array<{ weekNum: number; start: string; end: string }> = [];
  let cursor = new Date(Date.UTC(year, 0, 1)); // Jan 1
  const yearEnd = new Date(Date.UTC(year, 11, 31)); // Dec 31
  let weekNum = 1;
  while (cursor <= yearEnd) {
    const windowStart = new Date(cursor);
    const windowEnd = new Date(Date.UTC(cursor.getUTCFullYear(), cursor.getUTCMonth(), cursor.getUTCDate() + 6));
    const effectiveEnd = windowEnd > yearEnd ? yearEnd : windowEnd;
    windows.push({ weekNum, start: fmt(windowStart), end: fmt(effectiveEnd) });
    cursor = new Date(Date.UTC(effectiveEnd.getUTCFullYear(), effectiveEnd.getUTCMonth(), effectiveEnd.getUTCDate() + 1));
    weekNum++;
  }
  return windows;
}

function isFutureWeek(weekEnd: string, now: Date): boolean {
  // weekEnd is MM/DD/YYYY
  const [mm, dd, yyyy] = weekEnd.split('/').map(Number);
  return now.getTime() < Date.UTC(yyyy, mm - 1, dd + 1);
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
// Step 1: Query filtered sources (include ONLY HIGH_VOLUME_CPFIDS)
// ---------------------------------------------------------------------------

console.log('[run-highvolume-ocpf] Step 1: Querying high-volume OCPF sources...');

const sourcesResult = await pool.query<PoliticianSourceRow>(
  `SELECT id, essentials_politician_id, source_system, external_id,
          research_status, notes, created_at, updated_at
   FROM transparent_motivations.politician_sources
   WHERE source_system = 'ocpf'
     AND research_status = 'confirmed'
     AND external_id = ANY($1::text[])`,
  [Array.from(HIGH_VOLUME_CPFIDS)]
);

const filteredSources = sourcesResult.rows;

if (filteredSources.length === 0) {
  console.log('[run-highvolume-ocpf] No high-volume sources found — nothing to ingest. Exiting.');
  await pool.end();
  process.exit(0);
}

console.log(`[run-highvolume-ocpf] Found ${filteredSources.length} source(s) to process:`);
filteredSources.forEach((ps) => console.log(`  id=${ps.id} external_id=${ps.external_id}`));

// ---------------------------------------------------------------------------
// Step 2: Clean zombie runs scoped to filtered source UUIDs only
// ---------------------------------------------------------------------------

console.log('\n[run-highvolume-ocpf] Step 2: Cleaning zombie ingestion_runs for high-volume sources...');

const filteredSourceIds = filteredSources.map((ps) => ps.id);

const zombieResult = await pool.query(
  `UPDATE transparent_motivations.ingestion_runs
   SET status = 'failed', completed_at = NOW(),
       notes = 'Marked failed by run-highvolume-ocpf-ingest.ts — prior interrupted run'
   WHERE status = 'running'
     AND politician_source_id = ANY($1::uuid[])
   RETURNING id, politician_source_id`,
  [filteredSourceIds]
);

if (zombieResult.rowCount === 0) {
  console.log('[run-highvolume-ocpf] No zombie runs found — already clean.');
} else {
  console.log(`[run-highvolume-ocpf] Marked ${zombieResult.rowCount} zombie run(s) as failed:`);
  zombieResult.rows.forEach((r: Record<string, unknown>) =>
    console.log(`  run id=${r['id']} politician_source_id=${r['politician_source_id']}`)
  );
}

// ---------------------------------------------------------------------------
// Step 3: Per-source ingest loop (per-month chunking)
// ---------------------------------------------------------------------------

console.log('\n[run-highvolume-ocpf] Step 3: Beginning per-source ingest loop (per-month chunks)...');

const now = new Date();
const currentYear = now.getUTCFullYear();

for (const ps of filteredSources) {
  try {
    // Query all completed cycle keys for this source. The regex matches:
    //   - legacy full-year entries ('YYYY')
    //   - per-quarter entries ('YYYY-QN')
    //   - new per-month entries ('YYYY-MNN')
    // Legacy empty-string election_cycle rows (very old all-history runs) are
    // intentionally excluded by the regex so they don't mask any month.
    // Regex matches all supported cycle key formats including new YYYY-WNN
    const completedResult = await pool.query<{ election_cycle: string }>(
      `SELECT DISTINCT election_cycle
         FROM transparent_motivations.ingestion_runs
         WHERE adapter_name = 'ocpf'
           AND politician_source_id = $1
           AND status IN ('completed', 'completed_with_warning')
           AND election_cycle ~ '^[0-9]{4}(-Q[1-4]|-M(0[1-9]|1[0-2])|-W[0-9]{2})?$'`,
      [ps.id]
    );
    const completedCycles = new Set<string>(
      completedResult.rows.map((r) => r.election_cycle)
    );

    const useWeekly = WEEK_GRANULARITY_CPFIDS.has(ps.external_id);

    for (let year = OCPF_START_YEAR; year <= currentYear; year++) {
      const yearStr = String(year);

      // Backward-compat: full-year run already completed — skip everything
      if (year !== currentYear && completedCycles.has(yearStr)) {
        continue;
      }

      if (useWeekly) {
        // ── Weekly path for extremely high-volume sources ──────────────────
        for (const { weekNum, start, end } of weekWindows(year)) {
          if (isFutureWeek(end, now)) continue;

          const cycleKey = `${year}-W${String(weekNum).padStart(2, '0')}`;

          // Backward-compat: if the month containing this week's start date
          // was already completed at monthly granularity, skip.
          const [mm] = start.split('/').map(Number);
          const monthKey = `${year}-M${String(mm).padStart(2, '0')}`;
          const quarter = Math.ceil(mm / 3) as 1|2|3|4;
          const quarterKey = `${year}-Q${quarter}`;

          if (completedCycles.has(cycleKey) || completedCycles.has(monthKey) || completedCycles.has(quarterKey)) {
            continue;
          }

          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(new Error(
            `[ocpf-highvolume] per-cycle timeout (${PER_YEAR_TIMEOUT_MS}ms): source=${ps.id} cycle=${cycleKey}`
          )), PER_YEAR_TIMEOUT_MS);

          try {
            await runIngestion(
              createOcpfAdapter(undefined, controller.signal, undefined, undefined, { start, end }),
              ps,
              cycleKey
            );
            console.log(`[run-highvolume-ocpf] ocpf: source=${ps.id} cycle=${cycleKey} done`);
          } catch (err) {
            console.error(
              `[run-highvolume-ocpf] ocpf: source=${ps.id} cycle=${cycleKey} error:`,
              err instanceof Error ? err.message : String(err)
            );
            await pool.query(
              `UPDATE transparent_motivations.ingestion_runs
               SET status = 'failed', completed_at = NOW(), notes = $1
               WHERE status = 'running'
                 AND politician_source_id = $2
                 AND election_cycle = $3`,
              [err instanceof Error ? err.message : String(err), ps.id, cycleKey]
            ).catch((e: unknown) => console.warn('[run-highvolume-ocpf] zombie cleanup failed:', e));
          } finally {
            clearTimeout(timeoutId);
          }
        }
      } else {
        // ── Monthly path for regular high-volume sources ───────────────────
        const activeMonth = (now.getUTCMonth() + 1) as Month;

        for (let m = 1; m <= 12; m++) {
          const month = m as Month;

          if (isFutureMonth(year, month, now)) continue;

          const cycleKey = `${year}-M${String(month).padStart(2, '0')}`;
          const quarter = Math.ceil(month / 3) as 1 | 2 | 3 | 4;
          const quarterKey = `${year}-Q${quarter}`;
          const isCurrentActiveMonth = (year === currentYear && month === activeMonth);

          if (!isCurrentActiveMonth && (completedCycles.has(quarterKey) || completedCycles.has(cycleKey))) {
            continue;
          }

          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(new Error(
            `[ocpf-highvolume] per-cycle timeout (${PER_YEAR_TIMEOUT_MS}ms): source=${ps.id} cycle=${cycleKey}`
          )), PER_YEAR_TIMEOUT_MS);

          try {
            await runIngestion(
              createOcpfAdapter(year, controller.signal, undefined, month),
              ps,
              cycleKey
            );
            console.log(`[run-highvolume-ocpf] ocpf: source=${ps.id} cycle=${cycleKey} done`);
          } catch (err) {
            console.error(
              `[run-highvolume-ocpf] ocpf: source=${ps.id} cycle=${cycleKey} error:`,
              err instanceof Error ? err.message : String(err)
            );
            await pool.query(
              `UPDATE transparent_motivations.ingestion_runs
               SET status = 'failed', completed_at = NOW(), notes = $1
               WHERE status = 'running'
                 AND politician_source_id = $2
                 AND election_cycle = $3`,
              [err instanceof Error ? err.message : String(err), ps.id, cycleKey]
            ).catch((e: unknown) => console.warn('[run-highvolume-ocpf] zombie cleanup failed:', e));
          } finally {
            clearTimeout(timeoutId);
          }
        }
      }
    }
  } catch (err) {
    console.error(
      `[run-highvolume-ocpf] ocpf: source=${ps.id} pre-flight error:`,
      err instanceof Error ? err.message : String(err)
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: Cleanup
// ---------------------------------------------------------------------------

await pool.end();
console.log('[run-highvolume-ocpf] Complete.');
