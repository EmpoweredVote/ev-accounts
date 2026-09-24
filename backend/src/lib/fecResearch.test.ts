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

import {
  searchFecCandidates,
  getUnmatchedFederalPoliticians,
  runFecAutoMatch,
} from './fecResearch.js';

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

// ---------------------------------------------------------------------------
// The queue — candidates are in it ON PURPOSE (ruling 2026-09-23, Chris Andrews)
// ---------------------------------------------------------------------------
//
// The queue predates the migration-196 "Candidate for U.S. Senate — <State>"
// placeholder offices, so for months it caught their holders only by accident —
// and hid most of them behind `p.is_vacant = false` until CA_0195 backfilled the
// NULLs. Candidates file with the FEC, and the dedicated candidate script
// (scripts/senate-candidate-fec.ts, deleted in #676) joined the dropped
// offices.politician_id, so this queue is now their route in. These tests pin
// that the SQL says so.

function queueRow(overrides: Record<string, unknown> = {}) {
  return {
    id: 'pol-1',
    full_name: 'Jane Doe',
    bioguide_id: null,
    chamber_name: 'U.S. House of Representatives',
    representing_state: 'UT',
    is_candidate: false,
    ...overrides,
  };
}

describe('getUnmatchedFederalPoliticians — the FEC research queue', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
  });

  it('names candidacy in the SELECT, from the placeholder title, instead of catching it by accident', async () => {
    poolQueryMock.mockResolvedValueOnce({ rows: [] });

    await getUnmatchedFederalPoliticians();

    const sql = String(poolQueryMock.mock.calls[0]![0]);
    expect(sql).toMatch(/\(COALESCE\(o\.title, ''\) ILIKE 'Candidate for%'\)\s+AS is_candidate/);
  });

  it('queues a person once, and a seat held beats a seat sought', async () => {
    // A sitting U.S. Representative running for Senate holds BOTH a House seat and a
    // Senate placeholder. Plain DISTINCT keeps both (the chamber differs), which
    // would research one person twice, as H and as S.
    poolQueryMock.mockResolvedValueOnce({ rows: [] });

    await getUnmatchedFederalPoliticians();

    const sql = String(poolQueryMock.mock.calls[0]![0]);
    expect(sql).toContain('SELECT DISTINCT ON (p.id)');
    expect(sql).toMatch(/ORDER BY p\.id,[\s\S]*?\(COALESCE\(o\.title, ''\) ILIKE 'Candidate for%'\) ASC/);
  });

  it('files a Senate candidate under the office sought and marks the row as a candidacy', async () => {
    poolQueryMock.mockResolvedValueOnce({
      rows: [queueRow({ chamber_name: 'U.S. Senate', representing_state: 'VA', is_candidate: true })],
    });

    const [row] = await getUnmatchedFederalPoliticians();

    expect(row).toMatchObject({ fec_office: 'S', source_system: 'fec_senate', is_candidate: true });
  });

  it('does not mark a sitting representative as a candidate', async () => {
    poolQueryMock.mockResolvedValueOnce({ rows: [queueRow()] });

    const [row] = await getUnmatchedFederalPoliticians();

    expect(row).toMatchObject({ fec_office: 'H', source_system: 'fec_house', is_candidate: false });
  });
});

describe('runFecAutoMatch — a candidate with no FEC hit', () => {
  const savedKey = process.env.FEC_API_KEY;

  beforeEach(() => {
    poolQueryMock.mockReset();
    acquireFecSlotMock.mockClear();
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(candidatesSearchResponse()));
    vi.useFakeTimers();
    process.env.FEC_API_KEY = 'test-api-key';
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    if (savedKey === undefined) delete process.env.FEC_API_KEY;
    else process.env.FEC_API_KEY = savedKey;
  });

  it('does not tell the reviewer a candidate "may be newly elected"', async () => {
    poolQueryMock
      .mockResolvedValueOnce({
        rows: [queueRow({ chamber_name: 'U.S. Senate', representing_state: 'OK', is_candidate: true })],
      })
      .mockResolvedValueOnce({ rows: [{ id: 'src-1' }] }); // createSource INSERT

    const run = runFecAutoMatch();
    await vi.runAllTimersAsync(); // the last-name fallback sleeps between searches
    const summary = await run;

    const [result] = summary.results;
    expect(result).toMatchObject({ status: 'needs_research', is_candidate: true });
    expect(result!.notes).not.toMatch(/newly elected/);
    expect(result!.notes).toMatch(/not have filed/);
  });
});
