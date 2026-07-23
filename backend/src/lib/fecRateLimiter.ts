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

// ---------------------------------------------------------------------------
// acquireFecSlot — the single chokepoint every outbound FEC HTTP request must
// acquire from before firing (FEC-03).
// ---------------------------------------------------------------------------

/**
 * Resolves immediately when the current UTC-minute bucket is under budget;
 * otherwise polls (short sleep, re-check) until a fresh bucket opens. Never
 * throws — Redis absence or a transient Redis error degrades to in-process
 * counting rather than failing the caller.
 */
export async function acquireFecSlot(): Promise<void> {
  for (;;) {
    const bucket = new Date().toISOString().slice(0, 16); // YYYY-MM-DDTHH:MM
    const key = `fec:ratelimit:${bucket}`;
    const redis = getRedisClient();

    let count: number;
    if (redis) {
      try {
        count = await redis.incr(key);
        if (count === 1) {
          await redis.expire(key, BUCKET_TTL_SECONDS);
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

    await sleep(POLL_INTERVAL_MS);
  }
}
