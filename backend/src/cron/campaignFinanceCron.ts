/**
 * campaignFinanceCron — node-cron registration for the FEC 6-hour ingestion job.
 *
 * Registers a job that fires every 6 hours (`0 *\/6 * * *` cron) UTC and calls
 * runFecScheduledJob() from campaignFinanceScheduler.
 *
 * Redis distributed lock inside runFecScheduledJob() prevents concurrent
 * execution across Render instances. Missing Redis degrades to in-process
 * mutex fallback (single-instance protection only).
 *
 * NOT started in test environments (NODE_ENV=test). Cron registration is
 * guarded in index.ts via `if (env.NODE_ENV !== 'test')`.
 *
 * Ported from:
 *   EV-Backend/internal/campaign_finance/scheduler/fec_schedule.go
 */

import cron from 'node-cron';
import { runFecScheduledJob } from '../lib/campaignFinanceScheduler.js';

/**
 * startCampaignFinanceCron registers the FEC ingestion cron job.
 * Fires every 6 hours UTC. Non-fatal — errors inside runFecScheduledJob
 * are caught and logged there; this wrapper catches any unhandled rejection.
 */
export function startCampaignFinanceCron(): void {
  cron.schedule(
    '0 */6 * * *',
    async () => {
      try {
        await runFecScheduledJob();
      } catch (err) {
        console.error('[cron] Unhandled error in FEC ingest job:', err);
      }
    },
    {
      timezone: 'UTC',
      name: 'fec-ingest',
    }
  );
  console.log('[cron] Campaign finance FEC ingest job registered (every 6 hours UTC)');
}
