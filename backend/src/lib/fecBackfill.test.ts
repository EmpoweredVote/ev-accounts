import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Mock ./env.js per this codebase's convention (see discoveryCron.test.ts /
// fecResearch.test.ts) — nothing here reads it directly, but the modules
// fecBackfill.ts imports do at module scope.
vi.mock('./env.js', () => ({ env: { DATABASE_URL: 'postgres://test' } }));

// Mock the shared pool so no real DB connection is attempted.
const poolQueryMock = vi.fn();
vi.mock('./db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

// fecBackfill.ts pulls in the full scheduler/adapter graph at module scope for its
// (unused-by-these-tests) orchestration functions — mock those modules wholesale so
// importing fecBackfill.ts stays lightweight and deterministic.
vi.mock('./campaignFinanceScheduler.js', () => ({
  currentFecCycle: vi.fn(() => '2026'),
  acquireLock: vi.fn(),
  releaseLock: vi.fn(),
  renewLock: vi.fn(),
  FEC_LOCK_KEY: 'campaign-finance:fec-ingest',
}));
vi.mock('./adapters/runIngestion.js', () => ({ runIngestion: vi.fn() }));
vi.mock('./adapters/fecAdapter.js', () => ({ createFecAdapter: vi.fn() }));

// Mock the shared FEC rate limiter (FEC-03, 174-01) so this test can assert the
// limiter is acquired before every outbound fetch in this file's two HTTP helpers.
const acquireFecSlotMock = vi.fn().mockResolvedValue(undefined);
vi.mock('./fecRateLimiter.js', () => ({
  acquireFecSlot: (...args: unknown[]) => acquireFecSlotMock(...args),
}));

import { populateFecCandidateCycles, populateFecCandidateTotals } from './fecBackfill.js';

function candidatesResponse(results: unknown[] = [{ cycles: [2026], election_years: [2026] }]) {
  return { ok: true, status: 200, json: async () => ({ results }) };
}

function totalsResponse(results: unknown[] = []) {
  return { ok: true, status: 200, json: async () => ({ results }) };
}

describe('fecBackfill (FEC-03 deviation) — shared limiter gate on the two backfill call sites', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
    acquireFecSlotMock.mockClear();
    process.env.FEC_API_KEY = 'test-api-key';
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete process.env.FEC_API_KEY;
  });

  it('populateFecCandidateCycles awaits acquireFecSlot before fetching a candidate\'s cycles', async () => {
    poolQueryMock.mockImplementation(async (sql: string) => {
      if (String(sql).includes('SELECT DISTINCT ps.external_id')) {
        return { rows: [{ external_id: 'CAND1' }] };
      }
      return { rows: [] }; // the INSERT ... ON CONFLICT upsert
    });
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockResolvedValue(candidatesResponse());

    await populateFecCandidateCycles();

    expect(acquireFecSlotMock).toHaveBeenCalledTimes(1);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const acquireOrder = acquireFecSlotMock.mock.invocationCallOrder[0]!;
    const fetchOrder = fetchMock.mock.invocationCallOrder[0]!;
    expect(acquireOrder).toBeLessThan(fetchOrder);
  });

  it('populateFecCandidateTotals awaits acquireFecSlot before fetching a candidate\'s totals', async () => {
    poolQueryMock.mockImplementation(async (sql: string) => {
      if (String(sql).includes('SELECT DISTINCT ps.external_id')) {
        return { rows: [{ external_id: 'CAND2' }] };
      }
      return { rows: [] }; // CREATE TABLE / ALTER TABLE / INSERT upsert, all no-ops here
    });
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockResolvedValue(totalsResponse());

    await populateFecCandidateTotals();

    expect(acquireFecSlotMock).toHaveBeenCalledTimes(1);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const acquireOrder = acquireFecSlotMock.mock.invocationCallOrder[0]!;
    const fetchOrder = fetchMock.mock.invocationCallOrder[0]!;
    expect(acquireOrder).toBeLessThan(fetchOrder);
  });
});
