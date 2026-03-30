/**
 * campaignFinanceScheduler — Redis distributed lock, adapter dispatch, FEC scheduled job,
 * and SQS long-poll worker for campaign finance ingestion.
 *
 * Ported from:
 *   EV-Backend/internal/campaign_finance/scheduler/scheduler.go
 *   EV-Backend/internal/campaign_finance/scheduler/lock.go
 *   EV-Backend/internal/campaign_finance/scheduler/sqs_worker.go
 *
 * Architecture:
 *   - Redis lock (UPSTASH_REDIS_URL) with in-process Map fallback for local dev
 *   - runAdapterForAll(adapterName) dispatches to the right factory + runIngestion
 *   - runFecScheduledJob() wraps FEC dispatch with lock acquire/release
 *   - startSqsWorker() long-polls SQS for EventBridge-dispatched adapter jobs
 *   - pingHealthcheck() fire-and-forget HC ping on success
 *
 * Non-fatal init: missing REDIS_URL logs warning, scheduler still starts using
 * in-process Map fallback (single-instance protection only).
 * Non-fatal SQS: missing SQS_INGEST_QUEUE_URL logs warning, worker does not start.
 */

import { Redis } from '@upstash/redis';
import {
  SQSClient,
  ReceiveMessageCommand,
  DeleteMessageCommand,
} from '@aws-sdk/client-sqs';
import { env } from './env.js';
import { runIngestion } from './adapters/runIngestion.js';
import { createFecAdapter } from './adapters/fecAdapter.js';
import { createCalAccessAdapter } from './adapters/calAccessAdapter.js';
import { createIndianaAdapter } from './adapters/indianaAdapter.js';
import { writeUnresolved } from './adapters/indianaAdapter.js';
import { createSocrataAdapter } from './adapters/socrataAdapter.js';
import { pool } from './db.js';

const sleep = (ms: number): Promise<void> => new Promise(resolve => setTimeout(resolve, ms));

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface PoliticianSourceRow {
  id: string;
  essentials_politician_id: string;
  source_system: string;
  external_id: string;
  research_status: string;
  notes: string;
  created_at: string;
  updated_at: string;
}

// ---------------------------------------------------------------------------
// Redis Distributed Lock
// ---------------------------------------------------------------------------

/**
 * Redis client singleton — initialized lazily. Null if REDIS_URL is absent
 * or initialization fails (fallback to in-process map).
 */
let redisClient: Redis | null = null;
let redisInitAttempted = false;

function getRedisClient(): Redis | null {
  if (redisInitAttempted) return redisClient;
  redisInitAttempted = true;

  if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) {
    console.warn(
      '[campaignFinanceScheduler] UPSTASH_REDIS_REST_URL/TOKEN not set — using in-process lock fallback (single-instance only)'
    );
    return null;
  }

  try {
    redisClient = Redis.fromEnv();
    return redisClient;
  } catch (err) {
    console.warn(
      '[campaignFinanceScheduler] Redis init failed — using in-process lock fallback:',
      err
    );
    return null;
  }
}

/**
 * In-process mutex fallback Map — tracks acquired lock keys.
 * Only prevents concurrent runs within the same Node process.
 * Used when Redis is unavailable (local dev, missing REDIS_URL).
 */
const inProcessLocks = new Map<string, boolean>();

/** Lock TTL in seconds: 10 minutes = 2x FEC max runtime (~5 min) */
const LOCK_TTL_SECONDS = 600;

/**
 * acquireLock attempts to acquire a distributed lock for the given key.
 * Uses Redis SET NX EX when available; falls back to in-process Map.
 * Returns true if the lock was acquired, false if already held.
 */
export async function acquireLock(key: string, ttlSeconds = LOCK_TTL_SECONDS): Promise<boolean> {
  const redis = getRedisClient();

  if (redis !== null) {
    try {
      // SET key 1 NX EX ttl — returns 'OK' if set, null if already held
      const result = await redis.set(key, '1', { nx: true, ex: ttlSeconds });
      return result === 'OK';
    } catch (err) {
      console.warn(`[campaignFinanceScheduler] Redis acquireLock failed, using in-process fallback:`, err);
      // Fall through to in-process fallback
    }
  }

  // In-process fallback
  if (inProcessLocks.get(key)) {
    return false;
  }
  inProcessLocks.set(key, true);
  // Simulate TTL: release after ttlSeconds
  setTimeout(() => inProcessLocks.delete(key), ttlSeconds * 1000);
  return true;
}

/**
 * releaseLock releases a previously acquired lock.
 * Deletes the Redis key if Redis is available; clears in-process Map otherwise.
 */
export async function releaseLock(key: string): Promise<void> {
  const redis = getRedisClient();

  if (redis !== null) {
    try {
      await redis.del(key);
      return;
    } catch (err) {
      console.warn(`[campaignFinanceScheduler] Redis releaseLock failed:`, err);
      // Fall through to in-process cleanup
    }
  }

  inProcessLocks.delete(key);
}

// ---------------------------------------------------------------------------
// Healthcheck ping — fire-and-forget
// ---------------------------------------------------------------------------

/**
 * pingHealthcheck sends a fire-and-forget GET ping to the given URL.
 * Used with Healthchecks.io to monitor adapter success.
 * No-op if url is undefined or empty.
 */
export function pingHealthcheck(url: string | undefined): void {
  if (!url) return;
  fetch(url, { signal: AbortSignal.timeout(5_000) }).catch((err) => {
    console.warn(`[campaignFinanceScheduler] healthcheck ping failed for ${url}:`, err);
  });
}

// ---------------------------------------------------------------------------
// FEC cycle helper
// ---------------------------------------------------------------------------

/**
 * currentFecCycle returns the current FEC election cycle year as a string.
 * FEC cycles are even years; odd years round up to next even year.
 * e.g. 2025 -> "2026", 2026 -> "2026"
 */
export function currentFecCycle(): string {
  const year = new Date().getFullYear();
  return String(year % 2 !== 0 ? year + 1 : year);
}

// ---------------------------------------------------------------------------
// Adapter dispatch — runAdapterForAll
// ---------------------------------------------------------------------------

/**
 * runAdapterForAll queries all confirmed politician_sources for the given adapter's
 * source_system and runs the ingestion pipeline for each one.
 *
 * Adapter name mapping (URL slug -> source_system column value):
 *   'fec'        -> source_system='fec'
 *   'cal_access' -> source_system='cal_access'
 *   'indiana'    -> source_system='indiana'
 *   'la_socrata' -> source_system='la_socrata'
 *
 * Non-aborting: per-source errors are logged and skipped; execution continues to next source.
 *
 * Indiana-specific: calls writeUnresolved after all sources processed.
 * Cal-Access-specific: calls saveETag and checks zipWasSkipped.
 */
export async function runAdapterForAll(adapterName: string): Promise<void> {
  // FEC sources are stored as 'fec_house' / 'fec_senate' — both map to the FEC adapter.
  const systemValues = adapterName === 'fec' ? ['fec_house', 'fec_senate'] : [adapterName];
  const placeholder = systemValues.map((_, i) => `$${i + 1}`).join(', ');

  const sourcesResult = await pool.query<PoliticianSourceRow>(
    `SELECT id, essentials_politician_id, source_system, external_id,
            research_status, notes, created_at, updated_at
     FROM transparent_motivations.politician_sources
     WHERE source_system IN (${placeholder})
       AND research_status = 'confirmed'`,
    systemValues
  );

  const sources = sourcesResult.rows;

  if (sources.length === 0) {
    console.warn(`[campaignFinanceScheduler] runAdapterForAll(${adapterName}): no confirmed sources found`);
    return;
  }

  console.log(
    `[campaignFinanceScheduler] runAdapterForAll(${adapterName}): running ${sources.length} source(s)`
  );

  switch (adapterName) {
    case 'fec': {
      const cycle = currentFecCycle();
      for (let i = 0; i < sources.length; i++) {
        const ps = sources[i];
        if (i > 0) await sleep(3000); // 3s between politicians — keeps FEC API under 1000 req/hr
        try {
          const adapter = createFecAdapter(cycle);
          await runIngestion(adapter, ps, cycle);
          console.log(`[campaignFinanceScheduler] fec: source=${ps.id} cycle=${cycle} done`);
        } catch (err) {
          console.error(
            `[campaignFinanceScheduler] fec: source=${ps.id} cycle=${cycle} error:`,
            err instanceof Error ? err.message : String(err)
          );
          // Non-aborting: continue to next source
        }
      }
      // Update freshness timestamp so X-Data-Updated-At header has a value
      try {
        await pool.query(
          `INSERT INTO transparent_motivations.data_source_metadata
             (source_system, last_sync_at, last_sync_status)
           VALUES ('fec', NOW(), 'ok')
           ON CONFLICT (source_system) DO UPDATE
             SET last_sync_at = NOW(), last_sync_status = 'ok', updated_at = NOW()`
        );
      } catch (err) {
        console.warn('[campaignFinanceScheduler] fec: data_source_metadata update failed (non-fatal):', err);
      }
      break;
    }

    case 'cal_access': {
      // Cal-Access downloads the shared ZIP lazily on first fetch() call.
      // Create adapter once, run each politician through the pipeline,
      // then call saveETag() to persist the ETag for next run.
      const adapter = createCalAccessAdapter();

      for (const ps of sources) {
        try {
          await runIngestion(adapter, ps, '');
          console.log(`[campaignFinanceScheduler] cal_access: source=${ps.id} done`);
        } catch (err) {
          console.error(
            `[campaignFinanceScheduler] cal_access: source=${ps.id} error:`,
            err instanceof Error ? err.message : String(err)
          );
        }
      }

      // Check if ZIP was unchanged (304 Not Modified) — skip ETag save if so
      if (adapter.zipWasSkipped()) {
        console.log('[campaignFinanceScheduler] cal_access: ZIP unchanged (304), no sources processed');
        break;
      }

      // Save ETag after all politicians
      try {
        await adapter.saveETag();
      } catch (err) {
        console.warn('[campaignFinanceScheduler] cal_access: saveETag failed (non-fatal):', err);
      }
      break;
    }

    case 'indiana': {
      const year = new Date().getFullYear();
      const adapter = createIndianaAdapter(year);

      try {
        await adapter.preDownload();
      } catch (err) {
        console.error(
          `[campaignFinanceScheduler] indiana: preDownload failed:`,
          err instanceof Error ? err.message : String(err)
        );
        return;
      }

      let lastRunId: number | null = null;

      for (const ps of sources) {
        try {
          await runIngestion(adapter, ps, '');
          // Get most recent run ID for writeUnresolved association
          const runResult = await pool.query<{ id: string }>(
            `SELECT id FROM transparent_motivations.ingestion_runs
             WHERE adapter_name = 'indiana' AND politician_source_id = $1
             ORDER BY started_at DESC LIMIT 1`,
            [ps.id]
          );
          if (runResult.rows[0]) {
            lastRunId = Number(runResult.rows[0].id);
          }
          console.log(`[campaignFinanceScheduler] indiana: source=${ps.id} done`);
        } catch (err) {
          console.error(
            `[campaignFinanceScheduler] indiana: source=${ps.id} error:`,
            err instanceof Error ? err.message : String(err)
          );
        }
      }

      // Write unresolved rows to queue
      const unmatchedRows = adapter.getUnmatchedRows();
      if (unmatchedRows.length > 0 && lastRunId !== null) {
        try {
          const written = await writeUnresolved(unmatchedRows, lastRunId);
          console.log(
            `[campaignFinanceScheduler] indiana: wrote ${written} unresolved rows (runId=${lastRunId})`
          );
        } catch (err) {
          console.warn('[campaignFinanceScheduler] indiana: writeUnresolved failed (non-fatal):', err);
        }
      }
      break;
    }

    case 'la_socrata': {
      for (const ps of sources) {
        try {
          const adapter = createSocrataAdapter();
          await runIngestion(adapter, ps, '');
          console.log(`[campaignFinanceScheduler] la_socrata: source=${ps.id} done`);
        } catch (err) {
          console.error(
            `[campaignFinanceScheduler] la_socrata: source=${ps.id} error:`,
            err instanceof Error ? err.message : String(err)
          );
        }
      }
      break;
    }

    default:
      throw new Error(`[campaignFinanceScheduler] unknown adapter: ${adapterName}`);
  }
}

// ---------------------------------------------------------------------------
// FEC Scheduled Job — acquires Redis lock, runs FEC, releases lock
// ---------------------------------------------------------------------------

const FEC_LOCK_KEY = 'campaign-finance:fec-ingest';

/**
 * runFecScheduledJob acquires the Redis lock, runs FEC ingestion for all
 * confirmed sources, then releases the lock.
 *
 * Non-fatal: errors are logged but never re-thrown.
 * Always releases lock in finally block.
 *
 * Called by campaignFinanceCron.ts every 6 hours.
 */
export async function runFecScheduledJob(): Promise<void> {
  let lockAcquired = false;

  try {
    lockAcquired = await acquireLock(FEC_LOCK_KEY, LOCK_TTL_SECONDS);
    if (!lockAcquired) {
      console.log('[campaignFinanceScheduler] fec-ingest: lock held by another instance, skipping');
      return;
    }

    console.log('[campaignFinanceScheduler] fec-ingest: starting');
    await runAdapterForAll('fec');
    console.log('[campaignFinanceScheduler] fec-ingest: complete');

    // Optional healthcheck ping on success
    pingHealthcheck(process.env['HEALTHCHECK_FEC_URL']);
  } catch (err) {
    console.error(
      '[campaignFinanceScheduler] fec-ingest: error:',
      err instanceof Error ? err.message : String(err)
    );
  } finally {
    if (lockAcquired) {
      await releaseLock(FEC_LOCK_KEY).catch((err) => {
        console.warn('[campaignFinanceScheduler] fec-ingest: releaseLock failed (non-fatal):', err);
      });
    }
  }
}

// ---------------------------------------------------------------------------
// SQS Worker — long-polls queue, dispatches adapter runs
// ---------------------------------------------------------------------------

/** SQS message body shape sent by EventBridge */
interface SqsIngestMessage {
  adapter: string;
}

/** Valid adapter names accepted in SQS messages */
const VALID_SQS_ADAPTERS = new Set(['fec', 'cal_access', 'indiana', 'la_socrata']);

/**
 * startSqsWorker launches a background long-poll loop that reads from the
 * SQS_INGEST_QUEUE_URL queue and dispatches adapter runs in response to
 * EventBridge messages.
 *
 * Only starts if SQS_INGEST_QUEUE_URL env var is set.
 * Non-fatal: missing env var logs a warning and returns immediately.
 *
 * CRITICAL: Always deletes SQS message after processing — even on adapter
 * failure — to prevent EventBridge retry floods.
 */
export function startSqsWorker(): void {
  const queueUrl = env.SQS_INGEST_QUEUE_URL;

  if (!queueUrl) {
    console.warn(
      '[campaignFinanceScheduler] SQS_INGEST_QUEUE_URL not set — SQS worker disabled'
    );
    return;
  }

  const sqsClient = new SQSClient({});
  console.log(`[campaignFinanceScheduler] SQS worker: started, polling ${queueUrl}`);

  // Background loop — intentionally unhandled Promise (fire-and-forget pattern)
  void (async () => {
    for (;;) {
      try {
        const response = await sqsClient.send(
          new ReceiveMessageCommand({
            QueueUrl: queueUrl,
            MaxNumberOfMessages: 1,
            WaitTimeSeconds: 20, // Long-poll
          })
        );

        const messages = response.Messages ?? [];

        for (const msg of messages) {
          const body = msg.Body ?? '';
          const receiptHandle = msg.ReceiptHandle;

          let adapterName: string | undefined;

          try {
            const parsed = JSON.parse(body) as SqsIngestMessage;
            adapterName = parsed.adapter;
          } catch {
            console.warn(`[campaignFinanceScheduler] SQS: failed to parse message body: ${body}`);
          }

          // Dispatch adapter (errors logged, never re-thrown)
          if (adapterName && VALID_SQS_ADAPTERS.has(adapterName)) {
            try {
              console.log(`[campaignFinanceScheduler] SQS: dispatching adapter ${adapterName}`);
              await runAdapterForAll(adapterName);
              console.log(`[campaignFinanceScheduler] SQS: adapter ${adapterName} complete`);
              pingHealthcheck(process.env[`HEALTHCHECK_${adapterName.toUpperCase()}_URL`]);
            } catch (err) {
              console.error(
                `[campaignFinanceScheduler] SQS: adapter ${adapterName} failed:`,
                err instanceof Error ? err.message : String(err)
              );
            }
          } else if (adapterName) {
            console.warn(`[campaignFinanceScheduler] SQS: unknown adapter ${adapterName}, discarding`);
          }

          // CRITICAL: Always delete message — even on failure — prevents retry floods
          if (receiptHandle) {
            try {
              await sqsClient.send(
                new DeleteMessageCommand({
                  QueueUrl: queueUrl,
                  ReceiptHandle: receiptHandle,
                })
              );
            } catch (deleteErr) {
              console.error(
                '[campaignFinanceScheduler] SQS: failed to delete message:',
                deleteErr instanceof Error ? deleteErr.message : String(deleteErr)
              );
            }
          }
        }
      } catch (err) {
        console.error(
          '[campaignFinanceScheduler] SQS: receive error:',
          err instanceof Error ? err.message : String(err)
        );
        // Brief backoff before retrying
        await new Promise((resolve) => setTimeout(resolve, 5_000));
      }
    }
  })();
}
