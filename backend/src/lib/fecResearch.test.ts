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

// ---------------------------------------------------------------------------
// Compound surnames — FEC files the whole surname before the comma
// ---------------------------------------------------------------------------
//
// Our full_name is "First [Middle] Last" with no marker for where the surname
// starts; FEC's is "LAST, FIRST MIDDLE", so FEC tells us exactly how many words
// the surname has. Comparing only our LAST word with FEC's whole surname scored
// "Catherine Cortez Masto" 0 against CORTEZ MASTO, CATHERINE — her own ID. Measured
// 2026-09-23: 3 of 102 sitting senators and 4 of 257 non-incumbent 2026 Senate
// candidates were sent to needs_research this way. The FEC names below were fetched
// that day, except Van Hollen's (the search API returned none for him on 2026-09-24).

describe('runFecAutoMatch — compound surnames', () => {
  const savedKey = process.env.FEC_API_KEY;

  beforeEach(() => {
    poolQueryMock.mockReset();
    acquireFecSlotMock.mockClear();
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(candidatesSearchResponse()));
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-09-23T12:00:00Z')); // FEC cycle 2026
    process.env.FEC_API_KEY = 'test-api-key';
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    if (savedKey === undefined) delete process.env.FEC_API_KEY;
    else process.env.FEC_API_KEY = savedKey;
  });

  /** Queue one politician, answer the full-name search, and return the result and what was written. */
  async function autoMatch(row: Record<string, unknown>, results: unknown[]) {
    poolQueryMock
      .mockResolvedValueOnce({ rows: [row] })
      .mockResolvedValueOnce({ rows: [{ id: 'src-1' }] }); // createSource INSERT
    (fetch as unknown as ReturnType<typeof vi.fn>).mockResolvedValueOnce(candidatesSearchResponse(results));

    const run = runFecAutoMatch();
    await vi.runAllTimersAsync();
    const summary = await run;

    const result = summary.results[0]!;
    expect(result.error).toBeNull();
    const [, , externalId, researchStatus] = poolQueryMock.mock.calls[1]![1] as string[];
    return { result, written: { externalId, researchStatus } };
  }

  const senateRow = (full_name: string, representing_state: string, is_candidate: boolean) =>
    queueRow({ full_name, representing_state, chamber_name: 'U.S. Senate', is_candidate });
  const fecRow = (candidate_id: string, name: string, election_years: number[]) =>
    ({ candidate_id, name, office: 'S', state: 'XX', party: 'DEM', election_years });

  it.each([
    ['Catherine Cortez Masto', 'NV', false, 'S6NV00200', 'CORTEZ MASTO, CATHERINE', [2016, 2022, 2028]],
    ['Chris Van Hollen', 'MD', false, 'S6MD03177', 'VAN HOLLEN, CHRIS', [2016, 2022, 2028]],
    ['Lisa Blunt Rochester', 'DE', false, 'S4DE00060', 'BLUNT ROCHESTER, LISA', [2024, 2030]],
    ['Alex De Paula', 'VA', true, 'S6VA00226', 'DE PAULA, ALEX', [2026]],
    ['Rachel Lee Fetty Anderson', 'WV', true, 'S6WV00188', 'FETTY ANDERSON, RACHEL LEE', [2026]],
    ['Melisa Lopez Franzen', 'MN', true, 'S6MN00465', 'LOPEZ FRANZEN, MELISA', [2026]],
    ['Sandy Spidel Neumann', 'KS', true, 'S6KS00262', 'SPIDEL NEUMANN, SANDY', [2026]],
  ] as const)('confirms %s onto their own FEC row at 0.9', async (fullName, state, isCandidate, id, fecName, years) => {
    const { result, written } = await autoMatch(senateRow(fullName, state, isCandidate), [fecRow(id, fecName, [...years])]);

    expect(result.confidence).toBe(0.9);
    expect(written).toEqual({ externalId: id, researchStatus: 'confirmed' });
  });

  it('keeps a generational suffix out of the surname', async () => {
    const { result } = await autoMatch(
      senateRow('Juan De La Cruz Jr.', 'TX', true),
      [fecRow('S6TX00001', 'DE LA CRUZ, JUAN', [2026])],
    );

    expect(result.confidence).toBe(0.9);
  });

  it('does not match a one-word surname to the last word of a compound one', async () => {
    const { result, written } = await autoMatch(
      senateRow('John Masto', 'NV', true),
      [fecRow('S6NV00200', 'CORTEZ MASTO, CATHERINE', [2016, 2022, 2028])],
    );

    expect(result.confidence).toBe(0);
    expect(written.researchStatus).toBe('needs_research');
  });

  it('does not match a person whose name holds only part of a compound surname', async () => {
    // "Catherine Masto" drops the first word of the surname; that is not the same surname.
    const { result } = await autoMatch(
      senateRow('Catherine Masto', 'NV', true),
      [fecRow('S6NV00200', 'CORTEZ MASTO, CATHERINE', [2016, 2022, 2028])],
    );

    expect(result.confidence).toBe(0);
  });
});
