/**
 * Lambda handler for the campaign finance cron job.
 * Triggered by EventBridge Scheduler every 6 hours.
 */
import { runFecScheduledJob } from '../lib/campaignFinanceScheduler.js';

export async function handler(): Promise<{ statusCode: number; body: string }> {
  console.info('[cron-campaign-finance] Starting FEC scheduled job');
  try {
    await runFecScheduledJob();
    console.info('[cron-campaign-finance] Completed successfully');
    return { statusCode: 200, body: 'OK' };
  } catch (err) {
    console.error('[cron-campaign-finance] Failed:', err);
    throw err;
  }
}
