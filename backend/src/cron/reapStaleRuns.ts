/**
 * reapStaleRuns — node-cron registration for the stale ingestion_runs reaper.
 *
 * Runs at 05:30 UTC daily, DELIBERATELY 30 minutes BEFORE the 06:00 FEC burst: the
 * previous day's abandoned rows are closed out before the next burst opens new ones,
 * so "how many runs are in flight right now?" is answerable at any point during a
 * burst instead of being polluted by every prior day's corpses.
 *
 * Also invoked once at startup (see index.ts). A restart is the very event that
 * strands these rows, so boot is exactly when a sweep pays off — the age threshold in
 * reapStaleIngestionRuns keeps a booting instance from touching a run that a draining
 * one is still finishing.
 *
 * NOT started in test environments; registration is guarded in index.ts.
 */

import cron from 'node-cron';
import { reapStaleIngestionRuns } from '../lib/reapStaleIngestionRuns.js';

export function startReapStaleRunsCron(): void {
  cron.schedule(
    '30 5 * * *',
    async () => {
      try {
        await reapStaleIngestionRuns();
      } catch (err) {
        console.error('[cron] Unhandled error in stale ingestion-run reaper:', err);
      }
    },
    {
      timezone: 'UTC',
      name: 'reap-stale-ingestion-runs',
    }
  );
  console.log('[cron] Stale ingestion-run reaper registered (daily at 05:30 UTC)');
}
