import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Mock ./env.js per this codebase's convention (see discoveryCron.test.ts) —
// fecResearch.ts does not read it directly, but ./db.js (imported both here and
// transitively via campaignFinanceService.js) does at module scope, and importing
// the real env.js would trigger its startup validation / process.exit(1) with no
// real DATABASE_URL set in a test environment.
vi.mock('./env.js', () => ({ env: { DATABASE_URL: 'postgres://test' } }));

// Mock the shared pool so importing fecResearch.ts (and campaignFinanceService.js,
// which it imports for createSource) never touches a real DB connection.
const poolQueryMock = vi.fn();
vi.mock('./db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

// Mock the shared FEC rate limiter (FEC-03, 174-01) so this test can assert the
// limiter is acquired before every candidate-search fetch without exercising real
// Redis/in-process pacing logic (that module has its own dedicated test file).
const acquireFecSlotMock = vi.fn().mockResolvedValue(undefined);
vi.mock('./fecRateLimiter.js', () => ({
  acquireFecSlot: (...args: unknown[]) => acquireFecSlotMock(...args),
}));

import { searchFecCandidates } from './fecResearch.js';

function candidatesSearchResponse(results: unknown[] = []) {
  return {
    ok: true,
    status: 200,
    json: async () => ({ results }),
  };
}

describe('fecResearch searchFecCandidates (FEC-03) — shared limiter gate', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
    acquireFecSlotMock.mockClear();
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('awaits acquireFecSlot before issuing the candidate-search fetch', async () => {
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockResolvedValue(candidatesSearchResponse());

    await searchFecCandidates('Jane Doe', 'CA', 'H', 'test-api-key');

    expect(acquireFecSlotMock).toHaveBeenCalledTimes(1);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const acquireOrder = acquireFecSlotMock.mock.invocationCallOrder[0]!;
    const fetchOrder = fetchMock.mock.invocationCallOrder[0]!;
    expect(acquireOrder).toBeLessThan(fetchOrder);
  });

  it('acquires a fresh slot on every call, including a repeated (last-name-fallback-style) search', async () => {
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockResolvedValue(candidatesSearchResponse());

    await searchFecCandidates('Jane Doe', 'CA', 'H', 'test-api-key');
    await searchFecCandidates('Doe', 'CA', 'H', 'test-api-key');

    expect(acquireFecSlotMock).toHaveBeenCalledTimes(2);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('propagates a fetch failure without swallowing it, after acquiring the limiter', async () => {
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockResolvedValue({ ok: false, status: 429, json: async () => ({}) });

    await expect(searchFecCandidates('Jane Doe', 'CA', 'H', 'test-api-key')).rejects.toThrow(/HTTP 429/);
    expect(acquireFecSlotMock).toHaveBeenCalledTimes(1);
  });
});
