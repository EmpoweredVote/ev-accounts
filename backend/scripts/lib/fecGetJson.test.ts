import { describe, it, expect, vi, beforeEach, afterEach, type Mock } from 'vitest';

// The shared limiter is the pacing gate under test — count its calls, never wait on it.
const { acquireFecSlot } = vi.hoisted(() => ({ acquireFecSlot: vi.fn(async () => {}) }));
vi.mock('../../src/lib/fecRateLimiter.js', () => ({ acquireFecSlot }));

import { fecGetJson, parseRetryAfterMs, type FecGetOptions } from './fecGetJson.js';

function jsonResponse(status: number, body: unknown = {}, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json', ...headers } });
}

/** Resolves to the error a promise rejects with; fails the test if it resolves. */
async function rejection(p: Promise<unknown>): Promise<Error> {
  try {
    await p;
  } catch (e) {
    return e as Error;
  }
  throw new Error('expected the promise to reject');
}

const URL_WITH_KEY = 'https://api.open.fec.gov/v1/candidates/totals/?api_key=SECRET-KEY-123&candidate_id=S6MN00499';

describe('fecGetJson', () => {
  let fetchMock: Mock<typeof fetch>;
  let sleep: Mock<NonNullable<FecGetOptions['sleep']>>;

  beforeEach(() => {
    acquireFecSlot.mockClear();
    fetchMock = vi.fn();
    vi.stubGlobal('fetch', fetchMock);
    sleep = vi.fn(async () => {});
    vi.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('returns the parsed body and takes one limiter slot', async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse(200, { results: [{ receipts: 1 }] }));
    const body = await fecGetJson<{ results: unknown[] }>(URL_WITH_KEY, 'totals S6MN00499', { sleep });
    expect(body.results).toHaveLength(1);
    expect(acquireFecSlot).toHaveBeenCalledTimes(1);
    expect(sleep).not.toHaveBeenCalled();
  });

  it('retries a 429 and takes a fresh limiter slot for every attempt', async () => {
    fetchMock
      .mockResolvedValueOnce(jsonResponse(429))
      .mockResolvedValueOnce(jsonResponse(200, { ok: true }));
    const body = await fecGetJson<{ ok: boolean }>(URL_WITH_KEY, 'totals S6MN00499', { sleep });
    expect(body.ok).toBe(true);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(acquireFecSlot).toHaveBeenCalledTimes(2);
    expect(sleep).toHaveBeenCalledWith(2000);
  });

  it('backs off exponentially across repeated 429s', async () => {
    fetchMock
      .mockResolvedValueOnce(jsonResponse(429))
      .mockResolvedValueOnce(jsonResponse(429))
      .mockResolvedValueOnce(jsonResponse(429))
      .mockResolvedValueOnce(jsonResponse(200));
    await fecGetJson(URL_WITH_KEY, 'totals S6MN00499', { sleep });
    expect(sleep.mock.calls.map(c => c[0])).toEqual([2000, 4000, 8000]);
  });

  it('honours a server Retry-After, clamped to 120s', async () => {
    fetchMock
      .mockResolvedValueOnce(jsonResponse(429, {}, { 'retry-after': '7' }))
      .mockResolvedValueOnce(jsonResponse(429, {}, { 'retry-after': '3600' }))
      .mockResolvedValueOnce(jsonResponse(200));
    await fecGetJson(URL_WITH_KEY, 'totals S6MN00499', { sleep });
    expect(sleep.mock.calls.map(c => c[0])).toEqual([7000, 120_000]);
  });

  it('gives up after maxRetries and names the status, never the URL (it carries the api_key)', async () => {
    fetchMock.mockResolvedValue(jsonResponse(429));
    const err = await rejection(fecGetJson(URL_WITH_KEY, 'totals S6MN00499', { sleep, maxRetries: 2 }));
    expect(err).toBeInstanceOf(Error);
    expect(err.message).toContain('429');
    expect(err.message).toContain('totals S6MN00499');
    expect(err.message).not.toContain('SECRET-KEY-123');
    expect(fetchMock).toHaveBeenCalledTimes(3);
  });

  it('retries a timeout — near the ceiling FEC hangs instead of answering 429', async () => {
    const timeout = Object.assign(new Error('The operation was aborted due to timeout'), { name: 'TimeoutError' });
    fetchMock.mockRejectedValueOnce(timeout).mockResolvedValueOnce(jsonResponse(200, { ok: true }));
    const body = await fecGetJson<{ ok: boolean }>(URL_WITH_KEY, 'search S6GA00390', { sleep });
    expect(body.ok).toBe(true);
    expect(acquireFecSlot).toHaveBeenCalledTimes(2);
  });

  it('retries a 5xx', async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse(503)).mockResolvedValueOnce(jsonResponse(200));
    await fecGetJson(URL_WITH_KEY, 'totals S6MN00499', { sleep });
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('does not retry a 4xx other than 429', async () => {
    fetchMock.mockResolvedValue(jsonResponse(404));
    const err = await rejection(fecGetJson(URL_WITH_KEY, 'candidate/X/committees', { sleep }));
    expect(err.message).toContain('404');
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(sleep).not.toHaveBeenCalled();
  });

  it('does not leak the api_key when fetch itself throws with the URL in its message', async () => {
    fetchMock.mockRejectedValue(new TypeError(`fetch failed: ${URL_WITH_KEY}`));
    const err = await rejection(fecGetJson(URL_WITH_KEY, 'totals S6MN00499', { sleep, maxRetries: 1 }));
    expect(err.message).not.toContain('SECRET-KEY-123');
    expect(err.message).toContain('totals S6MN00499');
  });
});

describe('parseRetryAfterMs', () => {
  it('reads seconds', () => expect(parseRetryAfterMs('12')).toBe(12_000));
  it('returns null when absent or junk', () => {
    expect(parseRetryAfterMs(null)).toBeNull();
    expect(parseRetryAfterMs('soon')).toBeNull();
  });
  it('reads an HTTP date as a delay from now, never negative', () => {
    const past = new Date(Date.now() - 60_000).toUTCString();
    expect(parseRetryAfterMs(past)).toBe(0);
  });
});
