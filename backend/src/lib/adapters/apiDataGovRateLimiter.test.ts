import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

const ORIGINAL_ENV = { ...process.env };

beforeEach(() => {
  vi.resetModules();
  // No UPSTASH_* env → module uses the in-process counter (single-instance path).
  delete process.env.UPSTASH_REDIS_REST_URL;
  delete process.env.UPSTASH_REDIS_REST_TOKEN;
  delete process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE;
  delete process.env.API_DATA_GOV_RATE_LIMIT_MAX_WAIT_MS;
});

afterEach(() => {
  vi.useRealTimers();
  process.env = { ...ORIGINAL_ENV };
});

describe('acquireApiDataGovSlot', () => {
  it('resolves immediately while under the per-minute budget', async () => {
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '3';
    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();
    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();
    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();
  });

  it('throws when aborted before a slot opens', async () => {
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '1';
    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await acquireApiDataGovSlot('congress'); // consume the single slot this minute
    const ac = new AbortController();
    ac.abort();
    await expect(acquireApiDataGovSlot('congress', ac.signal)).rejects.toThrow(/aborted/i);
  });

  it('keeps separate budgets per service key space', async () => {
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '1';
    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await acquireApiDataGovSlot('congress');
    // A different service has its own bucket, so this must still resolve.
    await expect(acquireApiDataGovSlot('other')).resolves.toBeUndefined();
  });
});
