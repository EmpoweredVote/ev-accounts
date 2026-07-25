import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks — @upstash/redis, per this codebase's vi.hoisted convention
// (see discoveryCron.test.ts) so mock references are available inside the
// vi.mock factory regardless of hoisting order.
// ---------------------------------------------------------------------------

const incrMock = vi.hoisted(() => vi.fn());
const expireMock = vi.hoisted(() => vi.fn());
const fromEnvMock = vi.hoisted(() =>
  vi.fn(() => ({
    incr: incrMock,
    expire: expireMock,
  }))
);

vi.mock('@upstash/redis', () => ({
  Redis: { fromEnv: fromEnvMock },
}));

const ORIGINAL_ENV = { ...process.env };

beforeEach(() => {
  vi.resetModules();
  incrMock.mockReset();
  expireMock.mockReset();
  fromEnvMock.mockClear();
  process.env.UPSTASH_REDIS_REST_URL = 'https://example.upstash.io';
  process.env.UPSTASH_REDIS_REST_TOKEN = 'test-token';
  delete process.env.FEC_RATE_LIMIT_PER_MINUTE;
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
  process.env = { ...ORIGINAL_ENV };
});

describe('acquireFecSlot', () => {
  it('resolves immediately and increments the per-minute Redis key when under budget', async () => {
    vi.setSystemTime(new Date('2026-01-01T00:00:00.000Z'));
    incrMock.mockResolvedValueOnce(1);
    expireMock.mockResolvedValueOnce('OK');

    const { acquireFecSlot } = await import('./fecRateLimiter.js');
    await acquireFecSlot();

    expect(incrMock).toHaveBeenCalledTimes(1);
    expect(incrMock).toHaveBeenCalledWith('fec:ratelimit:2026-01-01T00:00');
    // .expire fires only on the FIRST increment of a bucket (count === 1).
    expect(expireMock).toHaveBeenCalledWith('fec:ratelimit:2026-01-01T00:00', 90);
  });

  it('does not call .expire on subsequent increments within the same bucket', async () => {
    vi.setSystemTime(new Date('2026-01-01T00:05:00.000Z'));
    incrMock.mockResolvedValueOnce(2); // not the first increment of this bucket

    const { acquireFecSlot } = await import('./fecRateLimiter.js');
    await acquireFecSlot();

    expect(expireMock).not.toHaveBeenCalled();
  });

  it('blocks when over budget and resolves once a new minute bucket opens', async () => {
    vi.setSystemTime(new Date('2026-01-01T00:00:59.000Z'));
    incrMock.mockResolvedValueOnce(20); // over the default budget of 15
    incrMock.mockResolvedValueOnce(1); // fresh bucket after the poll-back
    expireMock.mockResolvedValue('OK');

    const { acquireFecSlot } = await import('./fecRateLimiter.js');
    const slot = acquireFecSlot();

    // Never resolves while over budget — advancing less than the poll
    // interval must not settle the promise.
    await vi.advanceTimersByTimeAsync(500);
    let settled = false;
    void slot.then(() => {
      settled = true;
    });
    await Promise.resolve();
    expect(settled).toBe(false);

    // Advancing past the poll interval crosses the minute boundary in fake
    // time too, so the second incr() call lands in a fresh bucket.
    await vi.advanceTimersByTimeAsync(1600);
    await slot;

    expect(incrMock).toHaveBeenCalledTimes(2);
    expect(incrMock).toHaveBeenNthCalledWith(1, 'fec:ratelimit:2026-01-01T00:00');
    expect(incrMock).toHaveBeenNthCalledWith(2, 'fec:ratelimit:2026-01-01T00:01');
  });

  it('degrades to in-process counting when Redis .incr throws, without rejecting', async () => {
    vi.setSystemTime(new Date('2026-01-02T00:00:00.000Z'));
    incrMock.mockRejectedValue(new Error('transient Redis error'));

    const { acquireFecSlot } = await import('./fecRateLimiter.js');

    await expect(acquireFecSlot()).resolves.toBeUndefined();
    expect(incrMock).toHaveBeenCalledTimes(1);
    // in-process degrade path never calls .expire (Redis-only behavior).
    expect(expireMock).not.toHaveBeenCalled();
  });

  it('falls back to in-process counting when Redis env vars are absent', async () => {
    delete process.env.UPSTASH_REDIS_REST_URL;
    delete process.env.UPSTASH_REDIS_REST_TOKEN;
    vi.setSystemTime(new Date('2026-01-03T00:00:00.000Z'));

    const { acquireFecSlot } = await import('./fecRateLimiter.js');

    await expect(acquireFecSlot()).resolves.toBeUndefined();
    expect(incrMock).not.toHaveBeenCalled();
    expect(fromEnvMock).not.toHaveBeenCalled();
  });

  it('honors FEC_RATE_LIMIT_PER_MINUTE to change the gating threshold', async () => {
    process.env.FEC_RATE_LIMIT_PER_MINUTE = '1';
    vi.setSystemTime(new Date('2026-01-04T00:00:59.000Z'));
    incrMock.mockResolvedValueOnce(2); // over the overridden budget of 1
    incrMock.mockResolvedValueOnce(1); // fresh bucket, under the override
    expireMock.mockResolvedValue('OK');

    const { acquireFecSlot } = await import('./fecRateLimiter.js');
    const slot = acquireFecSlot();
    await vi.advanceTimersByTimeAsync(2100);
    await slot;

    expect(incrMock).toHaveBeenCalledTimes(2);
  });
});
