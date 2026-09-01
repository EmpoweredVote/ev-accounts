/**
 * rateLimitStore — a SHARED (cross-instance) store for express-rate-limit,
 * backed by the same Upstash Redis the FEC limiter already uses.
 *
 * WHY THIS EXISTS: express-rate-limit's default MemoryStore counts hits per
 * Node process. `ev-accounts-api` runs multiple instances on Render, so the
 * auth limiter's "10 / 15 min per IP" was really 10 × (instance count): requests
 * round-robin across instances and no single one reaches the cap. Verified in
 * production — 12 consecutive bad logins returned 401, never 429, with
 * `ratelimit-remaining` still 8. A shared counter makes the cap real.
 *
 * Degrades safely: when Upstash is not configured (local/dev), the factory
 * returns undefined and the caller lets express-rate-limit use its own
 * MemoryStore — matching fecRateLimiter's non-fatal fallback so a missing Redis
 * never breaks the auth routes.
 */
import { Redis } from '@upstash/redis';
import type { Store, Options, ClientRateLimitInfo } from 'express-rate-limit';

let redisClient: Redis | null = null;
let redisInitAttempted = false;

function getRedisClient(): Redis | null {
  if (redisInitAttempted) return redisClient;
  redisInitAttempted = true;

  if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) {
    console.warn(
      '[rateLimitStore] UPSTASH_REDIS_REST_URL/TOKEN not set — auth rate limit falls back to the per-instance MemoryStore (NOT shared across instances)'
    );
    return null;
  }
  try {
    redisClient = Redis.fromEnv();
    return redisClient;
  } catch (err) {
    console.warn('[rateLimitStore] Redis init failed — auth rate limit falls back to per-instance MemoryStore:', err);
    return null;
  }
}

/** A fixed-window counter store keyed per client, shared across instances. */
export class UpstashRateLimitStore implements Store {
  /** Window length; set from the limiter's options in init(). */
  private windowMs = 15 * 60 * 1000;
  /** Namespaced per limiter so different limiters never share a counter, and
   *  never collide with the FEC limiter's keys. */
  prefix: string;

  constructor(private readonly redis: Redis, namespace: string) {
    this.prefix = `erl:${namespace}:`;
  }

  init(options: Options): void {
    this.windowMs = options.windowMs;
  }

  private redisKey(key: string): string {
    return `${this.prefix}${key}`;
  }

  async increment(key: string): Promise<ClientRateLimitInfo> {
    const k = this.redisKey(key);
    const totalHits = await this.redis.incr(k);
    // Set the TTL only when the counter is first created; later hits in the same
    // window keep the original expiry (a true fixed window, not a sliding one).
    if (totalHits === 1) {
      await this.redis.pexpire(k, this.windowMs);
    }
    const ttl = await this.redis.pttl(k);
    const resetTime = ttl >= 0 ? new Date(Date.now() + ttl) : new Date(Date.now() + this.windowMs);
    return { totalHits, resetTime };
  }

  async decrement(key: string): Promise<void> {
    const k = this.redisKey(key);
    // Only decrement a live, positive counter (used by skipFailed/skipSuccess).
    const current = await this.redis.get<number>(k);
    if (typeof current === 'number' && current > 0) {
      await this.redis.decr(k);
    }
  }

  async resetKey(key: string): Promise<void> {
    await this.redis.del(this.redisKey(key));
  }
}

/**
 * Returns a shared store for express-rate-limit, or undefined to let the caller
 * fall back to express-rate-limit's own per-instance MemoryStore. Pass a unique
 * `namespace` per limiter so their counters don't collide. Use the result only
 * when defined:
 *   const store = createSharedRateLimitStore('auth');
 *   rateLimit({ ..., ...(store ? { store } : {}) });
 */
export function createSharedRateLimitStore(namespace: string): Store | undefined {
  const redis = getRedisClient();
  return redis ? new UpstashRateLimitStore(redis, namespace) : undefined;
}
