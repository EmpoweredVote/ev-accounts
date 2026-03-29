/**
 * Lambda handler for the calibration lapse cron job.
 * Triggered by EventBridge Scheduler at 02:00 UTC daily.
 */
import { runCalibrationLapseJob } from '../lib/cronService.js';

export async function handler(): Promise<{ statusCode: number; body: string }> {
  console.info('[cron-calibration] Starting calibration lapse job');
  try {
    await runCalibrationLapseJob();
    console.info('[cron-calibration] Completed successfully');
    return { statusCode: 200, body: 'OK' };
  } catch (err) {
    console.error('[cron-calibration] Failed:', err);
    throw err; // Let Lambda retry / report failure
  }
}
