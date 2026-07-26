import { Redis } from '@upstash/redis';
import { env } from './env.js';

interface CacheClient {
  get<T>(key: string): Promise<T | null>;
  set(key: string, value: unknown, ttlSeconds?: number): Promise<void>;
  del(key: string): Promise<void>;
}

/**
 * Cap on entries held in the process-local fallback.
 *
 * This bound is load-bearing, not defensive tidiness. Before the per-operation degrade below,
 * this Map was only ever reached when Redis was absent or failed to construct, so on production
 * it stayed empty. Now that `set` mirrors EVERY write here (so a mid-run degrade still finds
 * warm entries), an unbounded Map would grow for the life of the dyno: entries are pruned only
 * on a `get` of that same expired key, and callers write high-cardinality keys —
 * `geocodingService` per address, `candidateService` per profile, `last_logout:${userId}`,
 * `slug_reservation:${userId}`. Worst of all, `researchVerifier` calls `cache.set(url, result)`
 * with NO ttl, so those entries get `expiresAt: null` and the lazy expiry check can never fire.
 * On a single long-lived Render dyno that already suffered a resource-exhaustion P1 on
 * 2026-07-22, that is a slow leak traded for a cron fix. 5,000 entries is far above the working
 * set of any current caller and small enough to be irrelevant to heap.
 */
const MAX_FALLBACK_ENTRIES = 5_000;

class InMemoryFallback implements CacheClient {
  private store = new Map<string, { value: unknown; expiresAt: number | null }>();

  async get<T>(key: string): Promise<T | null> {
    const entry = this.store.get(key);
    if (!entry) return null;
    if (entry.expiresAt && Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return null;
    }
    return entry.value as T;
  }

  async set(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
    this.store.set(key, {
      value,
      expiresAt: ttlSeconds ? Date.now() + ttlSeconds * 1000 : null,
    });
    this.evictIfOversized();
  }

  async del(key: string): Promise<void> {
    this.store.delete(key);
  }

  /** Exposed for tests asserting the bound actually holds. */
  size(): number {
    return this.store.size;
  }

  /**
   * Keep the Map at or below MAX_FALLBACK_ENTRIES. Drops genuinely-expired entries first —
   * that reclaims space without losing anything a caller could still read — and only then
   * evicts oldest-first. A Map iterates in insertion order, so the first key is the oldest
   * write; that is FIFO rather than true LRU, which is the right trade here because this is a
   * degraded-mode buffer, not the primary cache.
   *
   * Be clear about the limit: "expired first" only helps if something is expired AT SWEEP TIME.
   * Under a sustained burst of live entries there is nothing to reclaim, so a long-TTL value
   * written early can still be evicted by FIFO. That is acceptable here — every caller treats a
   * miss as normal, and the alternative (scanning for the furthest-from-expiry victim) buys
   * nothing for a buffer that only matters while Redis is down.
   */
  private evictIfOversized(): void {
    if (this.store.size <= MAX_FALLBACK_ENTRIES) return;

    const now = Date.now();
    for (const [k, entry] of this.store) {
      if (entry.expiresAt && now > entry.expiresAt) this.store.delete(k);
    }

    while (this.store.size > MAX_FALLBACK_ENTRIES) {
      const oldest = this.store.keys().next();
      if (oldest.done) break;
      this.store.delete(oldest.value);
    }
  }
}

/**
 * How long to stop calling Redis after a command fails. Without this, a rate-limited or
 * quota-exhausted Upstash gets hammered once per cache operation — each call spending another
 * request against the very limit that is already exceeded, and adding a round-trip of latency to
 * work that has a perfectly good in-memory answer.
 */
const REDIS_COOLDOWN_MS = 60_000;

/**
 * createCache returns a Redis-backed cache that DEGRADES PER OPERATION, not just at init.
 *
 * Why per-operation matters (production incident 2026-07-26): this module used to catch only
 * `Redis.fromEnv()` failing, so a healthy-at-startup client whose commands later failed threw
 * straight through to the caller. When Upstash hit its request limit, `cache.get` began throwing
 * `ERR max requests limit exceeded`. `fecBulkLoader.buildCandidateCommitteeMap` calls `cache.get`
 * first thing for EVERY politician_source, so the error propagated
 * buildCandidateCommitteeMap -> resolveCommitteeIds -> fetchStream -> runIngestion and marked the
 * run failed: **102 failed FEC ingestion runs in one 06:00 UTC cron hour**, completions down from
 * ~336/day to 136, with `ingestion_runs.errors` NULL so the cause was invisible from the DB.
 *
 * A cache is by definition optional — losing it must cost a cache miss, never a failed job. Both
 * other Redis users in this codebase (fecRateLimiter's per-minute counter,
 * campaignFinanceScheduler's distributed lock) already wrap each command and fall back in-process;
 * this module was the sole exception. It now follows the same house pattern.
 */
function createCache(): CacheClient {
  const fallback = new InMemoryFallback();

  if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) {
    console.warn('[cache] UPSTASH_REDIS_REST_URL/TOKEN not set — using in-memory fallback');
    return fallback;
  }

  let redis: Redis;
  try {
    redis = Redis.fromEnv();
  } catch {
    console.warn('[cache] Redis init failed — using in-memory fallback');
    return fallback;
  }

  // Timestamp until which Redis is considered unhealthy and skipped entirely.
  let skipRedisUntil = 0;
  let warned = false;

  function degrade(op: string, err: unknown): void {
    skipRedisUntil = Date.now() + REDIS_COOLDOWN_MS;
    // Log the first degrade loudly, then stay quiet — this fires once per cache operation and a
    // cron sweep does hundreds, which is how a real outage turns into unreadable logs.
    if (!warned) {
      warned = true;
      console.warn(
        `[cache] Redis ${op} failed — serving from in-memory fallback for the next ` +
        `${REDIS_COOLDOWN_MS / 1000}s (further failures logged at most once per cooldown): ` +
        (err instanceof Error ? err.message : String(err))
      );
    }
  }

  function redisUsable(): boolean {
    if (Date.now() >= skipRedisUntil) {
      warned = false; // allow one log per cooldown window
      return true;
    }
    return false;
  }

  return {
    async get<T>(key: string): Promise<T | null> {
      if (!redisUsable()) return fallback.get<T>(key);
      try {
        return await redis.get<T>(key);
      } catch (err) {
        degrade('get', err);
        return fallback.get<T>(key);
      }
    },
    async set(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
      // Always write the fallback too, so a mid-run degrade still finds warm entries this
      // process wrote before Redis went away.
      await fallback.set(key, value, ttlSeconds);
      if (!redisUsable()) return;
      try {
        if (ttlSeconds) {
          await redis.set(key, value, { ex: ttlSeconds });
        } else {
          await redis.set(key, value);
        }
      } catch (err) {
        degrade('set', err);
      }
    },
    async del(key: string): Promise<void> {
      await fallback.del(key);
      if (!redisUsable()) return;
      try {
        await redis.del(key);
      } catch (err) {
        degrade('del', err);
      }
    },
  };
}

export const cache = createCache();
