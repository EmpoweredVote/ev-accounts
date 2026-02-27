/**
 * calibrationLapse — node-cron registration for the daily calibration lapse job.
 *
 * Registers a job that fires at 02:00 UTC every day and calls
 * runCalibrationLapseJob() from cronService.
 *
 * Table-based idempotency (calibration_lapse_runs) ensures the job is safe
 * to re-run — duplicate execution produces no duplicate notifications or demotions.
 *
 * NOT started in test environments (NODE_ENV=test). Cron registration is
 * guarded in index.ts via `if (env.NODE_ENV !== 'test')`.
 */

import cron from 'node-cron';
import { runCalibrationLapseJob } from '../lib/cronService.js';

export function startCalibrationLapseCron(): void {
  cron.schedule(
    '0 2 * * *',
    async () => {
      try {
        await runCalibrationLapseJob();
      } catch (err) {
        console.error('[cron] Unhandled error in calibration lapse job:', err);
      }
    },
    {
      timezone: 'UTC',
      name: 'calibration-lapse',
    }
  );
  console.log('[cron] Calibration lapse job registered (daily 02:00 UTC)');
}
