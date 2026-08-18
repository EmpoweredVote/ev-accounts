/**
 * fecRateLimiter — shared pacing gate for every outbound FEC API request (FEC-03).
 *
 * Backstop layered under the root-cause volume cut (FEC-01/FEC-02): even after
 * those land, this module gives the batch a real notion of the shared
 * api.data.gov ceiling (~1,000 req/hr) so concurrent call sites (fetchWithRetry,
 * resolveCommitteeIds' API fallback, runFecAutoMatch / fecResearch.ts) can never
 * collectively exceed it.
 *
 * House style mirrors `campaignFinanceScheduler.ts`'s acquireLock()/renewLock()
 * design (lazy Redis client init, in-process Map fallback, non-fatal degrade)
 * — replicated here in this module's own key space rather than imported, since
 * the two modules solve different problems (mutual-exclusion lock vs. a shared
 * per-minute counter).
 *
 * Design: a per-UTC-minute fixed-window counter (Redis INCR/EXPIRE, TTL 90s —
 * slightly wider than the 60s bucket) rather than a per-hour bucket, to avoid
 * the burst-then-stall anti-pattern (all budget consumed in the first minute
 * of the hour, then a long stall for the remainder).
 */

import { Redis } from '@upstash/redis';

// ---------------------------------------------------------------------------
// Lazy Redis client (module-local; not shared with campaignFinanceScheduler.ts)
// ---------------------------------------------------------------------------

let redisClient: Redis | null = null;
let redisInitAttempted = false;

function getRedisClient(): Redis | null {
  if (redisInitAttempted) return redisClient;
  redisInitAttempted = true;

  if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) {
    console.warn(
      '[fecRateLimiter] UPSTASH_REDIS_REST_URL/TOKEN not set — using in-process rate limit fallback (single-instance only)'
    );
    return null;
  }

  try {
    redisClient = Redis.fromEnv();
    return redisClient;
  } catch (err) {
    console.warn('[fecRateLimiter] Redis init failed — using in-process rate limit fallback:', err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// In-process fallback counter (used when Redis is absent or throws)
// ---------------------------------------------------------------------------

const inProcessCounters = new Map<string, number>();

/** Bucket TTL in seconds — slightly wider than the 60s bucket width. */
const BUCKET_TTL_SECONDS = 90;

function inProcessIncr(key: string): number {
  const n = (inProcessCounters.get(key) ?? 0) + 1;
  inProcessCounters.set(key, n);
  setTimeout(() => inProcessCounters.delete(key), BUCKET_TTL_SECONDS * 1000);
  return n;
}

// ---------------------------------------------------------------------------
// Budget (env-tunable, FEC-03)
// ---------------------------------------------------------------------------

const DEFAULT_BUDGET_PER_MINUTE = 15; // ~900/hr, 10% margin under the ~1,000/hr ceiling

function getBudgetPerMinute(): number {
  const parsed = parseInt(process.env.FEC_RATE_LIMIT_PER_MINUTE ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_BUDGET_PER_MINUTE;
}

// ---------------------------------------------------------------------------
// sleep helper (mirrors the existing idiom in fecAdapter.ts)
// ---------------------------------------------------------------------------

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/** Poll-back interval when over budget — never a stall longer than one tick. */
const POLL_INTERVAL_MS = 2000;

/**
 * Ceiling on how long acquireFecSlot will wait before giving up.
 *
 * 🔴 This exists because on 2026-08-18 the 06:00 burst STOPPED DEAD inside this function.
 * The walk logged "Fetching committee C00492785" at 06:23:43 and then nothing for 29
 * minutes, while /api/health kept answering 200 in 4ms. A for(;;) that neither returns nor
 * throws is indistinguishable from a healthy idle process, and the burst behind it never
 * advanced. Bucket keys are per-UTC-minute, so a genuine budget wait resolves within ~60s;
 * anything past two minutes is a stall, not back-pressure.
 */
const DEFAULT_MAX_WAIT_MS = 120_000;

function getMaxWaitMs(): number {
  const parsed = parseInt(process.env.FEC_RATE_LIMIT_MAX_WAIT_MS ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_MAX_WAIT_MS;
}

/**
 * Upstash speaks HTTP via fetch, which has NO default timeout — a Redis round-trip that
 * never settles blocks this function forever, silently. That is the leading suspect for
 * the 06:23:43 stall. Bound it and degrade to the in-process counter, exactly as a thrown
 * Redis error already does.
 */
const REDIS_OP_TIMEOUT_MS = 5000;

async function withTimeout<T>(work: Promise<T>, ms: number, label: string): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const bound = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error(label)), ms);
  });
  try {
    return await Promise.race([work, bound]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

// ---------------------------------------------------------------------------
// acquireFecSlot — the single chokepoint every outbound FEC HTTP request must
// acquire from before firing (FEC-03).
// ---------------------------------------------------------------------------

/**
 * Resolves immediately when the current UTC-minute bucket is under budget;
 * otherwise polls (short sleep, re-check) until a fresh bucket opens. Redis absence or a
 * transient Redis error degrades to in-process counting rather than failing the caller.
 *
 * 🔴 IT USED TO NEVER THROW, AND THAT WAS THE BUG. "Never throws" plus "loops until a
 * condition holds" means a caller can wait forever with no error, no log and no way out;
 * the 2026-08-18 burst halted here for 29 minutes on a live, healthy dyno. It now bounds
 * the wait (FEC_RATE_LIMIT_MAX_WAIT_MS) and honours an AbortSignal, so a stall surfaces as
 * a per-source failure the caller can log and step over instead of a silent halt.
 *
 * @param signal - optional AbortSignal; checked each poll so a per-source timeout upstream
 *   can actually interrupt a wait. Without it, an abort elsewhere could not reach this loop.
 */
export async function acquireFecSlot(signal?: AbortSignal): Promise<void> {
  const deadline = Date.now() + getMaxWaitMs();
  for (;;) {
    if (signal?.aborted) {
      throw new Error('[fecRateLimiter] aborted while waiting for a rate-limit slot');
    }
    const bucket = new Date().toISOString().slice(0, 16); // YYYY-MM-DDTHH:MM
    const key = `fec:ratelimit:${bucket}`;
    const redis = getRedisClient();

    let count: number;
    if (redis) {
      try {
        count = await withTimeout(
          redis.incr(key), REDIS_OP_TIMEOUT_MS, '[fecRateLimiter] Redis incr timed out'
        );
        if (count === 1) {
          await withTimeout(
            redis.expire(key, BUCKET_TTL_SECONDS), REDIS_OP_TIMEOUT_MS,
            '[fecRateLimiter] Redis expire timed out'
          );
        }
      } catch (err) {
        console.warn('[fecRateLimiter] Redis incr failed — degrading to in-process counter:', err);
        count = inProcessIncr(key);
      }
    } else {
      count = inProcessIncr(key);
    }

    if (count <= getBudgetPerMinute()) {
      return;
    }

    // A per-minute bucket always frees within ~60s. Passing the ceiling means something is
    // wrong that waiting will not fix, so fail loudly rather than stall the caller's walk.
    if (Date.now() >= deadline) {
      throw new Error(
        `[fecRateLimiter] gave up waiting for a slot after ${getMaxWaitMs()}ms ` +
        `(bucket ${key} at ${count}/${getBudgetPerMinute()})`
      );
    }

    await sleep(POLL_INTERVAL_MS);
  }
}
