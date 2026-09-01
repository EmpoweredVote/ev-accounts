import { describe, it, expect, vi } from 'vitest';
import type { Options } from 'express-rate-limit';
import { UpstashRateLimitStore } from './rateLimitStore.js';

function fakeRedis() {
  return {
    incr: vi.fn(),
    pexpire: vi.fn().mockResolvedValue(1),
    pttl: vi.fn(),
    get: vi.fn(),
    decr: vi.fn().mockResolvedValue(0),
    del: vi.fn().mockResolvedValue(1),
  };
}

// Minimal Options stand-in — the store only reads windowMs.
const opts = (windowMs: number) => ({ windowMs }) as unknown as Options;

describe('UpstashRateLimitStore', () => {
  it('increments a shared counter and sets the window TTL only on the first hit', async () => {
    const redis = fakeRedis();
    const store = new UpstashRateLimitStore(redis as never, 'auth');
    store.init(opts(900_000));

    redis.incr.mockResolvedValueOnce(1);
    redis.pttl.mockResolvedValueOnce(900_000);
    const first = await store.increment('1.2.3.4');
    expect(first.totalHits).toBe(1);
    expect(redis.incr).toHaveBeenCalledWith('erl:auth:1.2.3.4');
    expect(redis.pexpire).toHaveBeenCalledWith('erl:auth:1.2.3.4', 900_000);
    expect(first.resetTime).toBeInstanceOf(Date);

    redis.incr.mockResolvedValueOnce(2);
    redis.pttl.mockResolvedValueOnce(800_000);
    const second = await store.increment('1.2.3.4');
    expect(second.totalHits).toBe(2);
    // TTL is set once, not re-applied on later hits (a fixed window).
    expect(redis.pexpire).toHaveBeenCalledTimes(1);
  });

  it('namespaces keys per limiter so different limiters never share a counter', async () => {
    const redis = fakeRedis();
    redis.incr.mockResolvedValue(1);
    redis.pttl.mockResolvedValue(1000);
    const auth = new UpstashRateLimitStore(redis as never, 'auth');
    const feedback = new UpstashRateLimitStore(redis as never, 'feedback');
    await auth.increment('ip');
    await feedback.increment('ip');
    expect(redis.incr).toHaveBeenCalledWith('erl:auth:ip');
    expect(redis.incr).toHaveBeenCalledWith('erl:feedback:ip');
  });

  it('resetKey deletes the namespaced counter', async () => {
    const redis = fakeRedis();
    const store = new UpstashRateLimitStore(redis as never, 'auth');
    await store.resetKey('1.2.3.4');
    expect(redis.del).toHaveBeenCalledWith('erl:auth:1.2.3.4');
  });
});
