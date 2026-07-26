import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

/**
 * Regression tests for the 2026-07-26 production incident: Upstash hit its request limit,
 * `cache.get` threw `ERR max requests limit exceeded`, and because this module only guarded
 * `Redis.fromEnv()` the error propagated through
 * fecBulkLoader.buildCandidateCommitteeMap -> resolveCommitteeIds -> runIngestion — failing
 * 102 FEC ingestion runs in a single 06:00 UTC cron hour.
 *
 * A cache is optional by definition: losing it must cost a cache MISS, never a thrown error.
 */

const redisGet = vi.fn();
const redisSet = vi.fn();
const redisDel = vi.fn();
vi.mock('@upstash/redis', () => ({
  Redis: {
    fromEnv: () => ({ get: redisGet, set: redisSet, del: redisDel }),
  },
}));
vi.mock('./env.js', () => ({ env: {} }));

/** Fresh module instance per test — `cache` is a module-scoped singleton. */
async function freshCache() {
  vi.resetModules();
  process.env.UPSTASH_REDIS_REST_URL = 'https://example.upstash.io';
  process.env.UPSTASH_REDIS_REST_TOKEN = 'token';
  return (await import('./cache.js')).cache;
}

const UPSTASH_LIMIT = new Error('Command failed: ERR max requests limit exceeded. Limit: 10000');

describe('cache — degrades per operation, not just at init', () => {
  beforeEach(() => {
    redisGet.mockReset();
    redisSet.mockReset();
    redisDel.mockReset();
  });
  afterEach(() => {
    delete process.env.UPSTASH_REDIS_REST_URL;
    delete process.env.UPSTASH_REDIS_REST_TOKEN;
  });

  it('get() returns null instead of throwing when Redis is quota-exhausted', async () => {
    const cache = await freshCache();
    redisGet.mockRejectedValue(UPSTASH_LIMIT);

    // The incident: this call threw and failed the whole ingestion run.
    await expect(cache.get('fec:candidate-committee-map:2026')).resolves.toBeNull();
  });

  it('set() does not throw when Redis is quota-exhausted', async () => {
    const cache = await freshCache();
    redisSet.mockRejectedValue(UPSTASH_LIMIT);

    await expect(cache.set('k', { a: 1 }, 60)).resolves.toBeUndefined();
  });

  it('del() does not throw when Redis is quota-exhausted', async () => {
    const cache = await freshCache();
    redisDel.mockRejectedValue(UPSTASH_LIMIT);

    await expect(cache.del('k')).resolves.toBeUndefined();
  });

  it('a value written while Redis is down is still readable from the in-memory fallback', async () => {
    const cache = await freshCache();
    redisSet.mockRejectedValue(UPSTASH_LIMIT);
    redisGet.mockRejectedValue(UPSTASH_LIMIT);

    await cache.set('warm', { hit: true });
    // Without the fallback write in set(), the bulk map would be refetched for every source.
    await expect(cache.get<{ hit: boolean }>('warm')).resolves.toEqual({ hit: true });
  });

  it('stops calling Redis during the cooldown so an exhausted quota is not hammered', async () => {
    const cache = await freshCache();
    redisGet.mockRejectedValue(UPSTASH_LIMIT);

    for (let i = 0; i < 25; i++) await cache.get(`k${i}`);

    // One failing probe, then silence — not 25 more requests against a limit already exceeded.
    expect(redisGet).toHaveBeenCalledTimes(1);
  });

  it('still uses Redis on the happy path', async () => {
    const cache = await freshCache();
    redisGet.mockResolvedValue({ ok: 1 });
    redisSet.mockResolvedValue('OK');

    await expect(cache.get<{ ok: number }>('k')).resolves.toEqual({ ok: 1 });
    await cache.set('k', { ok: 1 }, 30);
    expect(redisGet).toHaveBeenCalledWith('k');
    expect(redisSet).toHaveBeenCalledWith('k', { ok: 1 }, { ex: 30 });
  });

  it('falls back cleanly when the credentials are absent', async () => {
    vi.resetModules();
    delete process.env.UPSTASH_REDIS_REST_URL;
    delete process.env.UPSTASH_REDIS_REST_TOKEN;
    const { cache } = await import('./cache.js');

    await cache.set('k', 'v');
    await expect(cache.get<string>('k')).resolves.toBe('v');
    expect(redisGet).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
// Bounded fallback
//
// The per-operation degrade above makes `set` mirror EVERY write into the process-local
// fallback, including while Redis is perfectly healthy. Before that change this Map was
// unreachable in production, so its unbounded growth cost nothing. Now it must be capped, or a
// long-lived dyno leaks: entries are pruned only on a `get` of that same expired key, and real
// callers write per-address, per-profile and per-user keys — `researchVerifier` writes per-URL
// with NO ttl, which the lazy expiry can never reclaim.
// ---------------------------------------------------------------------------

describe('cache — the in-memory fallback is bounded', () => {
  beforeEach(() => {
    redisGet.mockReset();
    redisSet.mockReset();
    redisDel.mockReset();
  });

  /**
   * Models the real incident shape: Redis is HEALTHY while writes accumulate (that is when the
   * mirror fills, and the leak this bound prevents), and only afterwards does Upstash start
   * rejecting — at which point reads fall through to the mirror and we can observe what survived.
   * Reading while Redis is healthy would return Redis's own answer and never touch the mirror.
   */
  async function fillWhileHealthyThenBreakRedis(
    write: (i: number) => Promise<void>,
    count: number,
  ) {
    redisSet.mockResolvedValue('OK');
    for (let i = 0; i < count; i++) await write(i);
    redisGet.mockRejectedValue(UPSTASH_LIMIT);
  }

  it('does not grow without limit when healthy writes are mirrored (the leak this prevents)', async () => {
    const cache = await freshCache();
    await fillWhileHealthyThenBreakRedis(
      (i) => cache.set(`geo:addr:${i}`, { lat: i, lng: i }, 86_400),
      6_000,
    );

    expect(await cache.get('geo:addr:5999')).toEqual({ lat: 5999, lng: 5999 });
    expect(await cache.get('geo:addr:0')).toBeNull();
  });

  it('caps entries written with NO ttl — the researchVerifier shape that can never expire', async () => {
    const cache = await freshCache();
    // cache.set(url, result) with no ttl => expiresAt null => lazy expiry can never reclaim it.
    await fillWhileHealthyThenBreakRedis(
      (i) => cache.set(`https://example.com/${i}`, { ok: true }),
      6_000,
    );

    expect(await cache.get('https://example.com/5999')).toEqual({ ok: true });
    expect(await cache.get('https://example.com/0')).toBeNull();
  });

  it('evicts EXPIRED entries in preference to live ones', async () => {
    vi.useFakeTimers();
    try {
      const cache = await freshCache();
      redisSet.mockResolvedValue('OK');

      // Written FIRST, so plain FIFO would evict it — the sweep must spare it because it is live.
      // Note the ordering: fill to just UNDER the cap, let those entries expire, and only then
      // cross the cap. Expiry has to precede the overflow, otherwise the sweep runs with nothing
      // reclaimable and correctly falls back to FIFO (which would take `keep-me`, the oldest).
      await cache.set('keep-me', 'important', 86_400);
      for (let i = 0; i < 4_998; i++) await cache.set(`short:${i}`, i, 60);
      vi.advanceTimersByTime(120_000); // every short:* entry is now expired
      await cache.set('trigger-a', 1, 86_400);
      await cache.set('trigger-b', 2, 86_400); // crosses the cap -> sweep

      redisGet.mockRejectedValue(UPSTASH_LIMIT);
      expect(await cache.get('keep-me')).toBe('important');
    } finally {
      vi.useRealTimers();
    }
  });

  it('a degraded write is still readable back, with the bound in force', async () => {
    const cache = await freshCache();
    redisGet.mockRejectedValue(UPSTASH_LIMIT);
    redisSet.mockRejectedValue(UPSTASH_LIMIT);

    await cache.set('warm', { v: 1 }, 300);
    expect(await cache.get('warm')).toEqual({ v: 1 });
  });
});
