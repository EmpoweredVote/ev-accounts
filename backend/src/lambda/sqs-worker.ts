/**
 * Lambda handler for SQS campaign finance ingestion messages.
 * Triggered by Lambda SQS event source mapping (replaces the long-poll worker).
 */
import type { SQSEvent } from 'aws-lambda';
import { runAdapterForAll } from '../lib/campaignFinanceScheduler.js';

const VALID_ADAPTERS = ['fec', 'cal_access', 'indiana', 'la_socrata'] as const;

export async function handler(event: SQSEvent): Promise<void> {
  for (const record of event.Records) {
    try {
      const body = JSON.parse(record.body);
      const adapter = body.adapter as string;

      if (!VALID_ADAPTERS.includes(adapter as any)) {
        console.warn(`[sqs-worker] Unknown adapter: ${adapter}, skipping`);
        continue;
      }

      console.info(`[sqs-worker] Processing adapter: ${adapter}`);
      await runAdapterForAll(adapter);
      console.info(`[sqs-worker] Completed adapter: ${adapter}`);
    } catch (err) {
      console.error('[sqs-worker] Failed to process message:', record.body, err);
      // Don't rethrow — matches existing behavior of always deleting the message
    }
  }
}
