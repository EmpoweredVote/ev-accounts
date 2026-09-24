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
import { createIndianaAdapter, indianaYears } from './adapters/indianaAdapter.js';
import { writeUnresolved } from './adapters/indianaAdapter.js';
import { createSocrataAdapter } from './adapters/socrataAdapter.js';
import { createNetfileAdapter, assertNetfileRunHealthy } from './adapters/netfileAdapter.js';
import { createOcpfAdapter } from './adapters/ocpfAdapter.js';
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
  netfile_agency: string | null;
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

/**
 * renewLock extends the TTL on a lock this process already holds. Used by
 * long-running jobs (e.g. the historical backfill) that outlive LOCK_TTL_SECONDS
 * and must keep other FEC consumers (the 6h cron) locked out for their duration.
 *
 * Uses SET EX WITHOUT nx — deliberately re-asserts the key. Only call from the
 * lock holder; a heartbeat every ~TTL/2 keeps the lock alive.
 */
export async function renewLock(key: string, ttlSeconds = LOCK_TTL_SECONDS): Promise<void> {
  const redis = getRedisClient();
  if (redis !== null) {
    try {
      await redis.set(key, '1', { ex: ttlSeconds });
      return;
    } catch (err) {
      console.warn(`[campaignFinanceScheduler] Redis renewLock failed:`, err);
    }
  }
  // In-process fallback: refresh the auto-expiry timer.
  if (inProcessLocks.get(key)) {
    inProcessLocks.set(key, true);
  }
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
 * runFecForSources walks a list of FEC sources through the ingestion pipeline.
 *
 * Extracted from runAdapterForAll so the daily 06:00 burst and the restart-resume path
 * (fecBurstResume.ts) drive the SAME loop. Duplicating it would let the two drift on the
 * inter-source delay, which is what keeps the shared FEC key under 1,000 req/hr.
 *
 * Non-aborting: a per-source failure is logged and the walk continues.
 *
 * 🔴 EVERY SOURCE IS TIME-BOUNDED, and that bound is load-bearing. On 2026-08-18 this loop
 * stopped dead: it logged "Fetching committee C00492785 for candidate S2TX00312" at
 * 06:23:43 and emitted nothing for the next 29 minutes while /api/health answered 200 in
 * 4ms. Catching errors is not enough — A HANG IS NOT AN ERROR. Nothing threw, so the catch
 * never ran, and the remaining ~500 sources simply never happened.
 *
 * The stall was inside acquireFecSlot's unbounded for(;;) (bounded in the same change), but
 * this timeout deliberately does NOT depend on that diagnosis being complete. It is the
 * backstop that guarantees the walk advances no matter what stalls underneath — a hung
 * socket, a wedged Redis round-trip, a future retry loop nobody has written yet.
 *
 * Note the failure mode this protects against is silent: a source that never runs writes no
 * ingestion_runs row, so a failure-count query reports the burst as healthy. Runs STARTED
 * vs. confirmed-source count is the only honest metric.
 */
export async function runFecForSources(
  sources: PoliticianSourceRow[],
  cycle: string
): Promise<void> {
  // Generous next to a normal source (seconds), tight next to a 33-minute walk of 662.
  const PER_SOURCE_TIMEOUT_MS = parseInt(process.env.FEC_PER_SOURCE_TIMEOUT_MS ?? '', 10) || 10 * 60 * 1000;

  for (let i = 0; i < sources.length; i++) {
    const ps = sources[i];
    if (i > 0) await sleep(3000); // 3s between politicians — keeps FEC API under 1000 req/hr

    const controller = new AbortController();
    let timeoutId: ReturnType<typeof setTimeout> | undefined;

    // 🔴 RACE the work, do not merely signal it. Aborting only helps code that CHECKS the
    // signal; anything that hangs without checking (a wedged socket in a library, a poll
    // loop nobody threaded the signal into) would leave `await runIngestion(...)` pending
    // forever and the walk stalled — the exact 2026-08-18 failure this is meant to end.
    // A unit test caught this: signalling alone did not free the loop.
    const timeoutReached = new Promise<never>((_, reject) => {
      timeoutId = setTimeout(() => {
        const err = new Error(
          `[fec] per-source timeout (${PER_SOURCE_TIMEOUT_MS}ms): source=${ps.id} cycle=${cycle}`
        );
        controller.abort(err);  // ask cooperative code to stop and free its socket
        reject(err);            // and move on regardless of whether it does
      }, PER_SOURCE_TIMEOUT_MS);
    });

    try {
      const adapter = createFecAdapter(cycle);
      // The signal reaches the FEC fetch path via runIngestion -> fetchStream, and reaches
      // the rate-limiter's poll loop because acquireFecSlot now accepts one.
      const work = runIngestion(adapter, ps, cycle, controller.signal);
      // Abandoned work may settle later; swallow it so it cannot surface as an unhandled
      // rejection and take the process down after we have already moved on.
      work.catch(() => {});
      await Promise.race([work, timeoutReached]);
      console.log(`[campaignFinanceScheduler] fec: source=${ps.id} cycle=${cycle} done`);
    } catch (err) {
      console.error(
        `[campaignFinanceScheduler] fec: source=${ps.id} cycle=${cycle} error:`,
        err instanceof Error ? err.message : String(err)
      );
      // Leave no row wedged in 'running' — the reaper would otherwise wait hours for it.
      await pool.query(
        `UPDATE transparent_motivations.ingestion_runs
         SET status = 'failed', completed_at = NOW(), notes = $1
         WHERE status = 'running'
           AND politician_source_id = $2
           AND election_cycle = $3`,
        [err instanceof Error ? err.message : String(err), ps.id, cycle]
      ).catch((e: unknown) => console.warn('[campaignFinanceScheduler] fec: zombie cleanup failed:', e));
      // Non-aborting: continue to next source
    } finally {
      if (timeoutId) clearTimeout(timeoutId);
    }
  }
}

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
            research_status, notes, created_at, updated_at, netfile_agency
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
      await runFecForSources(sources, cycle);
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
      // Download the shared ZIP and parse it ONCE for every source (prepare), run each
      // politician through the pipeline from that parse, then saveETag() for the next run.
      // A download or parse failure throws: it is global, so no per-source run would help.
      const adapter = createCalAccessAdapter();
      await adapter.prepare(sources.map(ps => ps.external_id));

      // 304 Not Modified — nothing changed since the last full run. Write no per-source
      // runs (they would all be empty); stamp the metadata row so the day still shows a run.
      if (adapter.zipWasSkipped()) {
        console.log('[campaignFinanceScheduler] cal_access: ZIP unchanged (304), no sources processed');
        try {
          await adapter.markNotModified();
        } catch (err) {
          console.warn('[campaignFinanceScheduler] cal_access: markNotModified failed (non-fatal):', err);
        }
        break;
      }

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

      // Save ETag after all politicians
      try {
        await adapter.saveETag();
      } catch (err) {
        console.warn('[campaignFinanceScheduler] cal_access: saveETag failed (non-fatal):', err);
      }
      break;
    }

    case 'indiana': {
      // Last year's file AND this year's: an officeholder off this year's ballot files only
      // the annual report, which lands in last year's file (see indianaYears).
      // A download or parse failure throws, as for cal_access: it is global, and a run that
      // swallowed it used to exit 0 with no per-source runs at all.
      const adapter = createIndianaAdapter(indianaYears());
      await adapter.preDownload();

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

      // Freshness stamp read by campaignFinanceService (last_sync_at / X-Data-Updated-At).
      // Year-agnostic: the read used to name 'indiana_zip_etag_2026', which 2027 would have
      // left frozen.
      try {
        await pool.query(
          `INSERT INTO transparent_motivations.data_source_metadata
             (source_system, last_sync_at, last_sync_status, last_record_count)
           VALUES ('indiana', NOW(), 'ok', $1)
           ON CONFLICT (source_system) DO UPDATE
             SET last_sync_at = NOW(), last_sync_status = 'ok',
                 last_record_count = EXCLUDED.last_record_count, updated_at = NOW()`,
          [adapter.confirmedRowCount()]
        );
      } catch (err) {
        console.warn('[campaignFinanceScheduler] indiana: data_source_metadata update failed (non-fatal):', err);
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

    case 'la_county_netfile': {
      const year = new Date().getFullYear();
      const adapter = createNetfileAdapter(year);
      let failed = 0;
      for (const ps of sources) {
        try {
          await runIngestion(adapter, ps, String(year));
          console.log(`[campaignFinanceScheduler] la_county_netfile: source=${ps.id} year=${year} done`);
        } catch (err) {
          failed++;
          console.error(
            `[campaignFinanceScheduler] la_county_netfile: source=${ps.id} error:`,
            err instanceof Error ? err.message : String(err)
          );
        }
      }
      // Every source has had its run first; only then does the job fail, so one bad source
      // never stops the others. Five months of 0-row runs exited 0 before this check.
      assertNetfileRunHealthy({ sources: sources.length, failed, fetched: adapter.fetchedRowCount() });
      break;
    }

    case 'ocpf': {
      // ONE run per source, full history, no chunking.
      //
      // The OCPF receipts endpoint returns a filer's ENTIRE history in a single response:
      // measured live 2026-08-17, the largest of the 20 sources (cpf 15710, 2001–present) is
      // 89,557 records in ~5 s. The loop this replaced issued 2001→now × 4 quarters ≈ 104
      // requests and 104 ingestion_runs rows PER SOURCE to subdivide that one call. Its
      // sizing came from the phantom page loop fixed in f80efc02 — "75k+ contributions per
      // quarter" was the same 250 rows re-appended ~300 times; cpf 15710's true worst
      // quarter is 5,754 records.
      //
      // Re-fetching everything each tick is also strictly MORE correct than the resume-skip
      // it replaces: contributions upsert on (data_source, source_transaction_id), so repeat
      // rows are updates rather than duplicates, and late filings or amendments landing in an
      // already-'completed' quarter — which the skip could never revisit — now get picked up.
      const OCPF_CYCLE_KEY = 'all';
      const PER_SOURCE_TIMEOUT_MS = 3 * 60 * 1000; // ~36x the measured worst case

      for (const ps of sources) {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(new Error(
          `[ocpf] per-source timeout (${PER_SOURCE_TIMEOUT_MS}ms): source=${ps.id}`
        )), PER_SOURCE_TIMEOUT_MS);

        try {
          await runIngestion(
            createOcpfAdapter(controller.signal),
            ps,
            OCPF_CYCLE_KEY
          );
          console.log(`[campaignFinanceScheduler] ocpf: source=${ps.id} done`);
        } catch (err) {
          console.error(
            `[campaignFinanceScheduler] ocpf: source=${ps.id} error:`,
            err instanceof Error ? err.message : String(err)
          );
          await pool.query(
            `UPDATE transparent_motivations.ingestion_runs
             SET status = 'failed', completed_at = NOW(), notes = $1
             WHERE status = 'running'
               AND politician_source_id = $2
               AND election_cycle = $3`,
            [err instanceof Error ? err.message : String(err), ps.id, OCPF_CYCLE_KEY]
          ).catch((e: unknown) => console.warn('[campaignFinanceScheduler] ocpf: zombie cleanup failed:', e));
        } finally {
          clearTimeout(timeoutId);
        }
      }
      break;
    }

    default:
      throw new Error(`[campaignFinanceScheduler] unknown adapter: ${adapterName}`);
  }
}

/**
 * runAdapterForSources runs the cal_access ingestion pipeline for a specific list
 * of politician_sources row IDs (UUIDs from politician_sources.id).
 *
 * Use this for targeted ingest of newly seeded politicians — avoids writing a run for
 * every confirmed source. The ZIP is still downloaded and parsed once (prepare).
 *
 * Only supports cal_access — other adapters don't have the same bulk-parse bottleneck.
 */
export async function runAdapterForSources(sourceIds: string[]): Promise<void> {
  if (sourceIds.length === 0) {
    console.warn('[campaignFinanceScheduler] runAdapterForSources: no source IDs provided');
    return;
  }

  const placeholders = sourceIds.map((_, i) => `$${i + 1}`).join(', ');
  const result = await pool.query<PoliticianSourceRow>(
    `SELECT id, essentials_politician_id, source_system, external_id,
            research_status, notes, created_at, updated_at, netfile_agency
     FROM transparent_motivations.politician_sources
     WHERE id IN (${placeholders})
       AND research_status = 'confirmed'`,
    sourceIds
  );

  const sources = result.rows;
  if (sources.length === 0) {
    console.warn('[campaignFinanceScheduler] runAdapterForSources: no confirmed sources found for provided IDs');
    return;
  }

  console.log(`[campaignFinanceScheduler] runAdapterForSources: running ${sources.length} cal_access source(s)`);

  const adapter = createCalAccessAdapter();
  await adapter.prepare(sources.map(ps => ps.external_id));

  if (adapter.zipWasSkipped()) {
    console.log('[campaignFinanceScheduler] runAdapterForSources: ZIP unchanged (304), no data processed');
    return;
  }

  for (const ps of sources) {
    try {
      await runIngestion(adapter, ps, '');
      console.log(`[campaignFinanceScheduler] cal_access: source=${ps.id} (${ps.external_id}) done`);
    } catch (err) {
      console.error(
        `[campaignFinanceScheduler] cal_access: source=${ps.id} error:`,
        err instanceof Error ? err.message : String(err)
      );
    }
  }

  // Intentionally do NOT save the ETag here. Targeted runs only process a subset
  // of sources, so saving the ETag would cause subsequent targeted runs to 304-skip
  // and miss their data. ETag ownership belongs to the full scheduled run only.
  console.log('[campaignFinanceScheduler] runAdapterForSources: complete (ETag not saved — owned by full scheduler)');
}

// ---------------------------------------------------------------------------
// FEC Forced Re-ingest — bypasses the "skip already-completed pair" guard
// ---------------------------------------------------------------------------

/** One (source, cycle) pair to force through the FEC pipeline. */
export interface FecReingestPair {
  sourceId: string;
  cycle: string;
}

export interface FecForcedReingestOptions {
  /** Delay between pairs (ms). Default 3000 — keeps the shared FEC key under its ceiling. */
  sleepBetweenMs?: number;
  /** Abort signal to stop the run cleanly between pairs. */
  signal?: AbortSignal;
  /** Per-pair progress callback. rows = contributions now stored for the pair. */
  onProgress?: (info: {
    index: number;
    total: number;
    pair: FecReingestPair;
    fullName: string;
    rows: number;
    error?: string;
  }) => void;
}

/**
 * runFecForcedReingest re-runs a given list of FEC (source, cycle) pairs through the
 * hardened adapter EVEN THOUGH each already has a prior completed ingestion_run.
 *
 * This is the forced path the completeness sweep (quick-030) needs: the normal
 * backfill getPending() skips any pair with a completed/completed_with_warning run,
 * so a truncated-but-"completed" mega-pair would never be re-fetched. runIngestion
 * itself never consults prior runs — it always creates a fresh run and ingests — so
 * "forcing" simply means selecting the truncated pairs directly and running them,
 * bypassing the getPending skip filter. Old truncated rows stay (ON CONFLICT dedups);
 * the raised cap lets the missing long-tail land.
 *
 * Non-aborting: per-pair errors are logged and reported; execution continues.
 */
export async function runFecForcedReingest(
  pairs: FecReingestPair[],
  opts: FecForcedReingestOptions = {}
): Promise<{ ok: number; failed: number; rateLimited: boolean }> {
  const sleepBetweenMs = opts.sleepBetweenMs ?? 3000;
  if (pairs.length === 0) {
    console.warn('[campaignFinanceScheduler] runFecForcedReingest: no pairs provided');
    return { ok: 0, failed: 0, rateLimited: false };
  }

  // Resolve source rows once (confirmed FEC sources only).
  const ids = [...new Set(pairs.map((p) => p.sourceId))];
  const placeholders = ids.map((_, i) => `$${i + 1}`).join(', ');
  const rowsResult = await pool.query<PoliticianSourceRow & { full_name: string }>(
    `SELECT ps.id, ps.essentials_politician_id, ps.source_system, ps.external_id,
            ps.research_status, ps.notes, ps.created_at, ps.updated_at,
            COALESCE(p.full_name, '') AS full_name
     FROM transparent_motivations.politician_sources ps
     LEFT JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
     WHERE ps.id IN (${placeholders})
       AND ps.source_system LIKE 'fec%'
       AND ps.research_status = 'confirmed'`,
    ids
  );
  const byId = new Map(rowsResult.rows.map((r) => [r.id, r]));

  let ok = 0;
  let failed = 0;
  let rateLimited = false;

  for (let i = 0; i < pairs.length; i++) {
    if (opts.signal?.aborted) {
      console.log(`[campaignFinanceScheduler] runFecForcedReingest: aborted after ${i}/${pairs.length} pairs`);
      break;
    }
    const pair = pairs[i]!;
    const ps = byId.get(pair.sourceId);
    if (!ps) {
      failed++;
      opts.onProgress?.({ index: i, total: pairs.length, pair, fullName: '?', rows: 0, error: 'source not found or not a confirmed FEC source' });
      continue;
    }
    if (i > 0) await sleep(sleepBetweenMs);

    try {
      await runIngestion(createFecAdapter(pair.cycle), ps, pair.cycle, opts.signal);
      const c = await pool.query<{ n: string }>(
        `SELECT COUNT(*) n FROM transparent_motivations.contributions
         WHERE data_source = 'fec' AND politician_source_id = $1 AND election_cycle = $2`,
        [pair.sourceId, pair.cycle]
      );
      const rows = Number(c.rows[0]?.n ?? 0);
      ok++;
      opts.onProgress?.({ index: i, total: pairs.length, pair, fullName: ps.full_name, rows });
    } catch (err) {
      failed++;
      const msg = err instanceof Error ? err.message : String(err);
      console.error(`[campaignFinanceScheduler] runFecForcedReingest: source=${pair.sourceId} cycle=${pair.cycle} error: ${msg}`);
      opts.onProgress?.({ index: i, total: pairs.length, pair, fullName: ps.full_name, rows: 0, error: msg });

      // Graceful rate-limit stop: if the FEC key is exhausted, every remaining pair will
      // 429 too — stop the session cleanly instead of burning the whole budget failing
      // pair after pair. Already-committed rows persist; re-run later to resume.
      if (/rate limit|\b429\b|quota/i.test(msg)) {
        rateLimited = true;
        console.warn('[campaignFinanceScheduler] runFecForcedReingest: FEC rate limit hit — ending session early (resume later).');
        break;
      }
    }
  }

  return { ok, failed, rateLimited };
}

// ---------------------------------------------------------------------------
// FEC Scheduled Job — acquires Redis lock, runs FEC, releases lock
// ---------------------------------------------------------------------------

export const FEC_LOCK_KEY = 'campaign-finance:fec-ingest';

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
const VALID_SQS_ADAPTERS = new Set(['fec', 'cal_access', 'indiana', 'la_socrata', 'la_county_netfile', 'ocpf']);

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
