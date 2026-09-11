/**
 * apiDataGovRateLimiter — a shared per-UTC-minute pacing gate for outbound
 * api.data.gov requests, keyed by service so each API (e.g. 'congress') gets its
 * own budget. Mirrors fecRateLimiter.ts's design (Redis INCR/EXPIRE per-minute
 * bucket, in-process fallback, bounded wait, AbortSignal) in a separate key
 * space. fecRateLimiter.ts is deliberately left untouched.
 *
 * Volume on the congress verification path is low, so the in-process fallback is
 * usually sufficient; the Redis path only matters when multiple instances run.
 */
import { Redis } from '@upstash/redis';

let redisClient: Redis | null = null;
let redisInitAttempted = false;

function getRedisClient(): Redis | null {
  if (redisInitAttempted) return redisClient;
  redisInitAttempted = true;
  if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) {
    return null;
  }
  try {
    redisClient = Redis.fromEnv();
    return redisClient;
  } catch (err) {
    console.warn('[apiDataGovRateLimiter] Redis init failed — using in-process fallback:', err);
    return null;
  }
}

const inProcessCounters = new Map<string, number>();
const BUCKET_TTL_SECONDS = 90;

function inProcessIncr(key: string): number {
  const n = (inProcessCounters.get(key) ?? 0) + 1;
  inProcessCounters.set(key, n);
  setTimeout(() => inProcessCounters.delete(key), BUCKET_TTL_SECONDS * 1000);
  return n;
}

const DEFAULT_BUDGET_PER_MINUTE = 15; // ~900/hr, 10% under the ~1,000/hr api.data.gov ceiling
const DEFAULT_MAX_WAIT_MS = 120_000;
const POLL_INTERVAL_MS = 2000;
const REDIS_OP_TIMEOUT_MS = 5000;

function getBudgetPerMinute(): number {
  const parsed = parseInt(process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_BUDGET_PER_MINUTE;
}

function getMaxWaitMs(): number {
  const parsed = parseInt(process.env.API_DATA_GOV_RATE_LIMIT_MAX_WAIT_MS ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_MAX_WAIT_MS;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

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

/**
 * Resolve when the current UTC-minute bucket for `service` is under budget;
 * otherwise poll until a fresh bucket opens. Throws after getMaxWaitMs() (a
 * per-minute bucket always frees within ~60s, so passing the ceiling means
 * something waiting will not fix) or when `signal` aborts.
 */
export async function acquireApiDataGovSlot(service: string, signal?: AbortSignal): Promise<void> {
  const deadline = Date.now() + getMaxWaitMs();
  for (;;) {
    if (signal?.aborted) {
      throw new Error(`[apiDataGovRateLimiter] aborted while waiting for a ${service} slot`);
    }
    const bucket = new Date().toISOString().slice(0, 16); // YYYY-MM-DDTHH:MM
    const key = `${service}:ratelimit:${bucket}`;
    const redis = getRedisClient();

    let count: number;
    if (redis) {
      try {
        count = await withTimeout(redis.incr(key), REDIS_OP_TIMEOUT_MS, '[apiDataGovRateLimiter] Redis incr timed out');
        if (count === 1) {
          await withTimeout(redis.expire(key, BUCKET_TTL_SECONDS), REDIS_OP_TIMEOUT_MS, '[apiDataGovRateLimiter] Redis expire timed out');
        }
      } catch (err) {
        console.warn('[apiDataGovRateLimiter] Redis incr failed — degrading to in-process counter:', err);
        count = inProcessIncr(key);
      }
    } else {
      count = inProcessIncr(key);
    }

    if (count <= getBudgetPerMinute()) return;

    if (Date.now() >= deadline) {
      throw new Error(
        `[apiDataGovRateLimiter] gave up waiting for a ${service} slot after ${getMaxWaitMs()}ms ` +
        `(bucket ${key} at ${count}/${getBudgetPerMinute()})`,
      );
    }
    await sleep(POLL_INTERVAL_MS);
  }
}
