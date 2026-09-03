/**
 * scheduler.ts
 * node-cron scheduler bootstrap — delegates to runConsensusPass which handles
 * its own overlap guard (module-level isRunning flag in consensusBatchJob.ts).
 *
 * This file intentionally contains NO isRunning flag — that logic lives
 * entirely inside runConsensusPass.
 */

import cron from 'node-cron';
import { runConsensusPass } from './jobs/consensusBatchJob.js';
import { runRotationPass } from './services/questRotation.js';
import { logger } from './lib/logger.js';

/**
 * startConsensusScheduler — registers the 5-minute consensus cron job.
 *
 * Called once at server startup (from index.ts). The cron fires every 5
 * minutes; runConsensusPass handles the overlap guard internally.
 */
export function startConsensusScheduler(): void {
  cron.schedule(
    '*/5 * * * *',
    async () => {
      const start = Date.now();
      try {
        await runConsensusPass();
        logger.info('Consensus batch job cycle completed', { durationMs: Date.now() - start });
      } catch (error) {
        logger.error('Consensus batch job failed', { error: String(error) });
      }
    },
    { timezone: 'UTC' }
  );

  logger.info('Consensus scheduler started — running every 5 minutes');
}

/**
 * startRotationScheduler — registers the 4am UTC daily quest rotation cron job.
 *
 * Called once at server startup (from index.ts). Sweeps expired assignments and
 * re-assigns quests for all users active in the last 30 days.
 */
export function startRotationScheduler(): void {
  cron.schedule(
    '0 4 * * *',
    async () => {
      const start = Date.now();
      try {
        await runRotationPass();
        logger.info('Quest rotation pass completed', { durationMs: Date.now() - start });
      } catch (error) {
        logger.error('Quest rotation pass failed', { error: String(error) });
      }
    },
    { timezone: 'UTC' }
  );

  logger.info('Quest rotation scheduler started — running daily at 4am UTC');
}
