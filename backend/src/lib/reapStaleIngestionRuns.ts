/**
 * reapStaleIngestionRuns — close out ingestion_runs rows abandoned in 'running'.
 *
 * WHY THESE EXIST, AND WHY IN-PROCESS ERROR HANDLING CANNOT PREVENT THEM
 *
 * runIngestion wraps its work in try/catch and writes a terminal status on both paths,
 * so an in-process exception never orphans a row. What orphans a row is the PROCESS
 * DYING mid-run: no JavaScript runs, so nothing marks the row.
 *
 * On this service that is routine rather than exceptional. `autoDeploy: yes` on
 * `master` means every push replaces the dyno, and the daily FEC burst takes 33+
 * minutes (662 confirmed sources x a 3s inter-source delay, plus per-source work). Any
 * push landing in that window kills the burst. Verified 2026-08-17:
 *
 *   06:00:00.105  [campaignFinanceScheduler] fec-ingest: starting
 *   06:27:57.903  ==> Deploying...
 *                 (no "fec-ingest: complete" — the burst stopped at 220 of 662)
 *
 * 🔴 ORPHANS UNDERCOUNT THE DAMAGE — do not use them as the health metric. A kill
 * landing inside the 3s `sleep` between sources leaves NO row in 'running' at all: the
 * previous run committed cleanly and the next never started. So a truncated burst
 * sometimes leaves an orphan and sometimes leaves nothing, while in both cases the
 * remaining sources are silently skipped. The real signal is runs-started vs. the
 * confirmed-source count.
 *
 * This reaper therefore does NOT fix truncation. It stops the *bookkeeping* from
 * rotting: a row stuck in 'running' forever is indistinguishable from one genuinely in
 * flight, which breaks every "is anything running?" query and slowly accumulates
 * (25 rows by 2026-08-17, oldest 2026-07-22; a manual cleanup of 11 in July grew back).
 */

import { pool } from './db.js';

/**
 * Age past which a 'running' row is certainly dead.
 *
 * A single runIngestion is minutes at worst — OCPF self-aborts at 180s per cycle and a
 * FEC source is bounded by its own page budget — so 3h is far beyond any legitimate
 * run while still leaving generous headroom. Env-overridable for the historical
 * backfill, which legitimately holds a run open far longer.
 */
const STALE_AFTER_HOURS = parseInt(process.env.INGESTION_STALE_AFTER_HOURS ?? '3', 10);

export interface ReapResult {
  reaped: number;
}

/**
 * reapStaleIngestionRuns marks abandoned 'running' rows as failed.
 *
 * Deliberately age-based rather than "everything running at startup": this service is
 * single-instance today, but during a deploy the old and new dynos overlap briefly, and
 * an unconditional sweep would let the booting instance kill a run the draining one is
 * still legitimately finishing.
 */
export async function reapStaleIngestionRuns(): Promise<ReapResult> {
  const result = await pool.query<{ id: string }>(
    `UPDATE transparent_motivations.ingestion_runs
        SET status       = 'failed',
            completed_at = NOW(),
            notes        = COALESCE(NULLIF(notes, ''), '')
                           || CASE WHEN COALESCE(notes, '') = '' THEN '' ELSE '; ' END
                           || 'abandoned in running for over ' || $1::text
                           || 'h - process died mid-run (deploy or restart); reaped'
      WHERE status = 'running'
        AND started_at < NOW() - ($1 || ' hours')::interval
      RETURNING id`,
    [STALE_AFTER_HOURS]
  );

  const reaped = result.rowCount ?? 0;
  if (reaped > 0) {
    console.warn(
      `[reapStaleIngestionRuns] reaped ${reaped} ingestion_runs row(s) abandoned in 'running' ` +
      `for more than ${STALE_AFTER_HOURS}h`
    );
  }
  return { reaped };
}
