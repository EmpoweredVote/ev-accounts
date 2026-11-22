/**
 * fecBurstResume — finish a FEC daily burst that a dyno restart cut short.
 *
 * THE PROBLEM. The 06:00 UTC FEC burst walks 662 confirmed sources with a 3s delay
 * between each, so it runs 33+ minutes at minimum. This service has
 * `autoDeploy: yes` on `master`, so any push landing in that window replaces the dyno
 * and the burst simply stops. Confirmed in the logs for 2026-08-17:
 *
 *   06:00:00.105  [campaignFinanceScheduler] fec-ingest: starting
 *   06:27:57.903  ==> Deploying...
 *                 (no "fec-ingest: complete" — it stopped at 220 of 662)
 *
 * Measured across 10 days, runs STARTED per day were 220, 202, 339, 339, 130, 126,
 * 162, 88, 70 and 15 — against 662 confirmed sources. The burst had not completed once.
 *
 * 🔴 WHY THIS WAS INVISIBLE. A source that never runs writes no row, so a failure-count
 * query returns zero and the job looks perfectly healthy. Orphaned 'running' rows catch
 * only the subset where the kill landed *inside* a run; a kill during the 3s sleep
 * leaves no trace at all. The only honest health metric is
 * runs-started vs. confirmed-source count.
 *
 * WHY A CURSOR AND NOT A GRACEFUL DRAIN. Render's SIGTERM grace period is ~30 seconds
 * against a 33-minute job, so draining cannot work. Resume can — and it repairs
 * truncation from ANY cause (platform restart, OOM, crash), not just deploys.
 *
 * WHY NO CURSOR TABLE. Progress is DERIVED from ingestion_runs, mirroring the existing
 * `maybeResumeBackfillOnBoot` / `countPendingBackfillPairs` precedent in fecBackfill.ts.
 * Stored cursors drift when a run is deleted, retried or pruned; a derived one cannot.
 */

import { pool } from './db.js';

/**
 * Start of the burst window: the most recent 06:00 UTC.
 *
 * Anchored to the burst hour rather than midnight on purpose. A burst legitimately
 * spills hours past its start (observed finishing as late as 15:32), so a midnight
 * anchor would mark yesterday's tail as satisfying today, and a rolling "24h ago"
 * window would slide a little further each day.
 */
export const BURST_WINDOW_START_SQL = `
  (date_trunc('day', now() AT TIME ZONE 'UTC')
     + interval '6 hours'
     - CASE WHEN (now() AT TIME ZONE 'UTC') < date_trunc('day', now() AT TIME ZONE 'UTC') + interval '6 hours'
            THEN interval '1 day' ELSE interval '0' END) AT TIME ZONE 'UTC'
`;

/**
 * Order a FEC walk LEAST RECENTLY TRIED FIRST: the source whose last attempt (of any outcome) is
 * oldest runs first, and sources never tried run LAST.
 *
 * WHY AN ORDER THAT ROTATES (2026-11-21, ev-cto watchlist #102). From 2026-11-19 the burst was
 * cut at Render's 12-hour ceiling three days running (808, 1,099 and 1,165 of 1,656 sources).
 * The walk order was fixed (known sources, then ps.id), so a cut-off run dropped the SAME tail
 * every day and those campaigns went stale indefinitely. Ordered by last attempt, the sources a
 * cut-off run misses go first tomorrow, so every known source is tried at least once in two
 * days even if each run only gets through half the list. The burst also stops itself before the
 * ceiling now (FEC_BURST_BUDGET_MINUTES in campaignFinanceScheduler.ts), so the tail is skipped
 * cleanly instead of killed.
 *
 * WHY LAST ATTEMPT, NOT LAST SUCCESS (2026-11-22). The first version ordered by last SUCCESS.
 * A source that hits the 10-minute per-source cap (FEC_PER_SOURCE_TIMEOUT_MS) records no
 * success, so it stayed the stalest and led the next run again: on 2026-11-22 the run spent its
 * first 2.5 hours on 16 sources, most of them timing out, and 13 of that day's 20 failures had
 * already failed earlier in the week. Counting a failed or killed ('running') attempt as tried
 * sends it to the back of tomorrow's queue. It is still retried every day or two; it just no
 * longer blocks everyone behind it.
 *
 * WHY NEVER-TRIED LAST. An incremental source takes ~1.6s; a source that has never been
 * ingested pulls its whole contribution history (~45s on 2026-09-25, all of it waiting on the
 * shared ~1,000 req/hr FEC key). On 2026-09-25, 959 of 1,631 sources were new and an
 * interleaved walk ran past 12:00 UTC. A backfill has no stored data to go stale yet, so it
 * waits until the daily refresh of what voters can already see is done.
 *
 * "Last attempt" is over ALL history, not just this burst window, so the resume pass keeps the
 * same order as the burst it is finishing.
 *
 * Expects the politician_sources table aliased as `ps`. Reads ingestion_runs through its
 * politician_source_id index (~270k rows, 68 MB on 2026-11-21).
 */
export const FEC_LEAST_RECENTLY_TRIED_ORDER_SQL = `
  (SELECT max(prior.started_at)
     FROM transparent_motivations.ingestion_runs prior
    WHERE prior.politician_source_id = ps.id
      AND prior.adapter_name = 'fec'
  ) ASC NULLS LAST,
  ps.id
`;

/**
 * Confirmed FEC sources with NO terminal success inside the current burst window.
 *
 * 🔴 Only 'completed' and 'completed_with_warning' count as done. A 'running' row is
 * precisely the wreckage of a killed process, and a 'failed' row deserves the retry —
 * treating either as done would skip the sources most in need of a rerun.
 */
export const pendingFecSourcesSql = `
  SELECT ps.id, ps.essentials_politician_id, ps.source_system, ps.external_id,
         ps.research_status, ps.notes, ps.created_at, ps.updated_at
    FROM transparent_motivations.politician_sources ps
   WHERE ps.source_system IN ('fec_house', 'fec_senate')
     AND ps.research_status = 'confirmed'
     AND NOT EXISTS (
           SELECT 1
             FROM transparent_motivations.ingestion_runs r
            WHERE r.politician_source_id = ps.id
              AND r.adapter_name = 'fec'
              AND r.status IN ('completed', 'completed_with_warning')
              AND r.started_at >= ${BURST_WINDOW_START_SQL}
         )
   ORDER BY ${FEC_LEAST_RECENTLY_TRIED_ORDER_SQL}
`;

export interface ResumeResult {
  status: 'complete' | 'resumed' | 'skipped_locked';
  pending: number;
  ran: number;
}

/**
 * resumeFecBurstIfIncomplete runs only the sources this burst window still owes.
 *
 * Takes the SAME lock as the 06:00 cron, so if a burst is genuinely in flight this
 * yields instead of running a second copy against the shared FEC API key.
 */
export async function resumeFecBurstIfIncomplete(): Promise<ResumeResult> {
  const { runFecForSources, currentFecCycle, acquireLock, releaseLock, FEC_LOCK_KEY } =
    await import('./campaignFinanceScheduler.js');

  const pendingResult = await pool.query(pendingFecSourcesSql);
  const pending = pendingResult.rows;

  if (pending.length === 0) {
    console.log('[fecBurstResume] burst window already complete — nothing to resume');
    return { status: 'complete', pending: 0, ran: 0 };
  }

  const acquired = await acquireLock(FEC_LOCK_KEY);
  if (!acquired) {
    console.log(
      `[fecBurstResume] ${pending.length} source(s) pending but the FEC lock is held ` +
      `(a burst is in flight) — leaving it to the running job`
    );
    return { status: 'skipped_locked', pending: pending.length, ran: 0 };
  }

  try {
    console.warn(
      `[fecBurstResume] resuming truncated burst: ${pending.length} source(s) had no ` +
      `successful run since the 06:00 UTC window opened`
    );
    await runFecForSources(pending, currentFecCycle());
    console.log(`[fecBurstResume] resume pass done: ${pending.length} source(s) attempted`);
    return { status: 'resumed', pending: pending.length, ran: pending.length };
  } finally {
    await releaseLock(FEC_LOCK_KEY).catch((err) =>
      console.warn('[fecBurstResume] releaseLock failed (non-fatal):', err)
    );
  }
}

/**
 * Delay before the boot-time resume, mirroring fecBackfill's AUTORESUME_DELAY_MS.
 * Lets the server bind its port and pass Render's health check before starting what
 * can be 20+ minutes of ingestion work.
 */
const RESUME_BOOT_DELAY_MS = 15_000;

/**
 * maybeResumeFecBurstOnBoot — called once at server startup.
 *
 * A restart is the exact event that truncates a burst, so boot is exactly when the
 * remainder should be picked up. Deliberately DEFAULT-ON (unlike the historical
 * backfill's opt-in FEC_BACKFILL_AUTORESUME): a truncated daily burst is a silent
 * correctness bug, not an optional extra. Set FEC_BURST_AUTORESUME=0 to disable.
 *
 * Fire-and-forget; failures are logged and never block startup.
 */
export function maybeResumeFecBurstOnBoot(): void {
  if (process.env.FEC_BURST_AUTORESUME === '0') {
    console.log('[fecBurstResume] boot resume disabled via FEC_BURST_AUTORESUME=0');
    return;
  }
  setTimeout(() => {
    void resumeFecBurstIfIncomplete().catch((err) =>
      console.error('[fecBurstResume] boot resume failed:', err instanceof Error ? err.message : String(err))
    );
  }, RESUME_BOOT_DELAY_MS);
}
