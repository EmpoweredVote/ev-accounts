/**
 * campaignFinanceCron — node-cron registration for the FEC daily ingestion job.
 *
 * Registers a job that fires once daily at 06:00 UTC (`0 6 * * *` cron) and calls
 * runFecScheduledJob() from campaignFinanceScheduler.
 *
 * FEC-03: changed from every-6-hours to once-daily. FEC's Schedule A
 * `min_load_date`/`max_load_date` incremental filter (FEC-02) is date-only
 * granularity, so running the refresh sub-daily re-scanned the same calendar
 * day's window up to 4x with zero additional freshness — pure waste of the
 * shared rate-limit budget. 06:00 UTC gives a safety margin after FEC's
 * observed ~03:05 UTC nightly batch-load cluster (174-RESEARCH-amendments.md A3).
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
import { runFecScheduledJob, runAdapterForAll } from '../lib/campaignFinanceScheduler.js';
import { runNetfileIngestWithSummaries } from '../lib/localFinanceSummary.js';

/**
 * startCampaignFinanceCron registers the FEC ingestion cron job.
 * Fires once daily at 06:00 UTC. Non-fatal — errors inside runFecScheduledJob
 * are caught and logged there; this wrapper catches any unhandled rejection.
 */
export function startCampaignFinanceCron(): void {
  cron.schedule(
    '0 6 * * *',
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
  console.log('[cron] Campaign finance FEC ingest job registered (daily at 06:00 UTC)');

  cron.schedule(
    '0 3 1 * *',
    async () => {
      try {
        await runNetfileIngestWithSummaries(); // ingest, then the local finance_summary writers
      } catch (err) {
        console.error('[cron] Unhandled error in Netfile ingest job:', err);
      }
    },
    {
      timezone: 'UTC',
      name: 'netfile-ingest',
    }
  );
  console.log('[cron] Campaign finance Netfile ingest job registered (monthly, 1st at 03:00 UTC)');

  cron.schedule(
    '0 4 1 * *',
    async () => {
      try {
        await runAdapterForAll('ocpf');
      } catch (err) {
        console.error('[cron] Unhandled error in OCPF ingest job:', err);
      }
    },
    {
      timezone: 'UTC',
      name: 'ocpf-ingest',
    }
  );
  console.log('[cron] Campaign finance OCPF ingest job registered (monthly, 1st at 04:00 UTC)');
}
