/**
 * discoverySweep — node-cron registration for the weekly candidate discovery sweep.
 *
 * Registers a job that fires at 02:00 UTC every Sunday and calls
 * runDiscoverySweep() from discoveryCron. The sweep iterates all
 * discovery_jurisdictions with elections within SWEEP_HORIZON_DAYS,
 * processing them sequentially with auto-upsert for high-confidence
 * candidates and a single combined sweep-summary email at the end.
 *
 * Lock collisions (manual trigger running): the sweep skips that run and
 * waits for the next Sunday — no catch-up logic.
 *
 * NOT started in test environments. Cron registration is guarded in
 * index.ts via `if (env.NODE_ENV !== 'test')`.
 */

import cron from 'node-cron';
import { runDiscoverySweep } from '../lib/discoveryCron.js';

export function startDiscoverySweepCron(): void {
  cron.schedule(
    // OPS-04: weekly (not daily) cadence is a deliberate cost choice. Each sweep
    // spends paid Anthropic calls proportional to the number of
    // discovery_jurisdictions whose election_date falls within
    // SWEEP_HORIZON_DAYS (see discoveryCron.ts) — running weekly instead of
    // daily bounds the recurring spend to ~1/7th while still catching upstream
    // source changes well ahead of any election. Sunday 02:00 UTC — one hour
    // before districtStaleness ('0 3 * * 0').
    '0 2 * * 0',
    async () => {
      try {
        await runDiscoverySweep();
      } catch (err) {
        console.error('[cron] Unhandled error in discovery sweep:', err);
      }
    },
    {
      timezone: 'UTC',
      name: 'discovery-sweep',
    }
  );
  console.log('[cron] Discovery sweep registered (weekly Sunday 02:00 UTC)');
}
