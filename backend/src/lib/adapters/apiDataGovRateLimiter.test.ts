import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks — @upstash/redis, per this codebase's vi.hoisted convention (see
// fecRateLimiter.test.ts) so mock references are available inside the
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
  delete process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE;
  delete process.env.API_DATA_GOV_RATE_LIMIT_MAX_WAIT_MS;
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
  process.env = { ...ORIGINAL_ENV };
});

describe('acquireApiDataGovSlot — Redis-backed path', () => {
  it('resolves immediately and increments the per-minute Redis key when under budget', async () => {
    vi.setSystemTime(new Date('2026-01-01T00:00:00.000Z'));
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '3';
    incrMock.mockResolvedValueOnce(1);
    expireMock.mockResolvedValueOnce('OK');

    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await acquireApiDataGovSlot('congress');

    expect(incrMock).toHaveBeenCalledTimes(1);
    expect(incrMock).toHaveBeenCalledWith('congress:ratelimit:2026-01-01T00:00');
    // .expire fires only on the FIRST increment of a bucket (count === 1).
    expect(expireMock).toHaveBeenCalledWith('congress:ratelimit:2026-01-01T00:00', 90);
  });

  it('does not call .expire on subsequent increments within the same bucket', async () => {
    vi.setSystemTime(new Date('2026-01-01T00:05:00.000Z'));
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '3';
    incrMock.mockResolvedValueOnce(2); // not the first increment of this bucket

    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await acquireApiDataGovSlot('congress');

    expect(expireMock).not.toHaveBeenCalled();
  });

  it('degrades to the in-process counter when Redis .incr throws, without rejecting', async () => {
    vi.setSystemTime(new Date('2026-01-02T00:00:00.000Z'));
    incrMock.mockRejectedValue(new Error('transient Redis error'));

    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');

    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();
    expect(incrMock).toHaveBeenCalledTimes(1);
    // in-process degrade path never calls Redis .expire.
    expect(expireMock).not.toHaveBeenCalled();
  });
});

describe('acquireApiDataGovSlot — in-process fallback (no Upstash env)', () => {
  it('resolves immediately while under the per-minute budget', async () => {
    delete process.env.UPSTASH_REDIS_REST_URL;
    delete process.env.UPSTASH_REDIS_REST_TOKEN;
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '3';
    vi.setSystemTime(new Date('2026-01-03T00:00:00.000Z'));

    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();
    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();
    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();

    expect(incrMock).not.toHaveBeenCalled();
    expect(fromEnvMock).not.toHaveBeenCalled();
  });

  it('keeps separate budgets per service key space', async () => {
    delete process.env.UPSTASH_REDIS_REST_URL;
    delete process.env.UPSTASH_REDIS_REST_TOKEN;
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '1';
    vi.setSystemTime(new Date('2026-01-04T00:00:00.000Z'));

    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await acquireApiDataGovSlot('congress'); // consume the single slot this minute
    // A different service has its own bucket, so this must still resolve.
    await expect(acquireApiDataGovSlot('other')).resolves.toBeUndefined();

    expect(incrMock).not.toHaveBeenCalled();
    expect(fromEnvMock).not.toHaveBeenCalled();
  });
});

describe('acquireApiDataGovSlot — bounded wait', () => {
  // 🔴 Mirrors fecRateLimiter.test.ts's bounded-wait suite: a for(;;) loop that
  // never returns and never throws is indistinguishable from a healthy idle
  // process. These tests exist so this module cannot recur that failure mode.

  it('throws after the configured max wait when the bucket never frees', async () => {
    vi.setSystemTime(new Date('2026-01-01T00:00:00.000Z'));
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '1';
    process.env.API_DATA_GOV_RATE_LIMIT_MAX_WAIT_MS = '10000';
    // Always over budget — the pre-fix loop could never exit this.
    incrMock.mockResolvedValue(999);

    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    const slot = acquireApiDataGovSlot('congress');
    const assertion = expect(slot).rejects.toThrow(/gave up waiting for a congress slot/);

    await vi.advanceTimersByTimeAsync(15000);
    await assertion;
  });

  it('rejects with /aborted/ when the signal aborts mid-wait (not pre-aborted)', async () => {
    vi.setSystemTime(new Date('2026-01-01T00:00:00.000Z'));
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '1';
    // Always over budget, so the loop is still polling — not yet settled — when we abort.
    incrMock.mockResolvedValue(999);

    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    const controller = new AbortController();
    const slot = acquireApiDataGovSlot('congress', controller.signal);
    const assertion = expect(slot).rejects.toThrow(/aborted/);

    // Let at least one poll cycle elapse (still over budget, signal not yet
    // aborted) before aborting mid-wait, so this genuinely exercises the
    // abort check on a later loop iteration rather than the first one.
    await vi.advanceTimersByTimeAsync(2500);
    controller.abort();
    await vi.advanceTimersByTimeAsync(2500);
    await assertion;
  });
});
