/**
 * districtStaleness — node-cron registration for the weekly district staleness job.
 *
 * Registers a job that fires at 03:00 UTC every Sunday and calls
 * runDistrictStalenessCheck() from districtStalenessService.
 *
 * District boundaries change over time (redistricting, annexations).
 * This ensures users' district assignments stay current without manual intervention.
 *
 * NOT started in test environments (NODE_ENV=test). Cron registration is
 * guarded in index.ts via `if (env.NODE_ENV !== 'test')`.
 */

import cron from 'node-cron';
import { runDistrictStalenessCheck } from '../lib/districtStalenessService.js';

export function startDistrictStalenessCron(): void {
  cron.schedule(
    '0 3 * * 0', // Sunday 3:00 AM UTC
    async () => {
      try {
        await runDistrictStalenessCheck();
      } catch (err) {
        console.error('[cron] Unhandled error in district staleness check:', err);
      }
    },
    {
      timezone: 'UTC',
      name: 'district-staleness',
    }
  );
  console.log('[cron] District staleness check registered (weekly Sunday 03:00 UTC)');
}
