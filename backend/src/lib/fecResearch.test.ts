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
  parseFecName,
  scoreMatch,
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

  it('names candidacy in the SELECT, from a race row or the placeholder title, instead of catching it by accident', async () => {
    poolQueryMock.mockResolvedValueOnce({ rows: [] });

    await getUnmatchedFederalPoliticians();

    const sql = String(poolQueryMock.mock.calls[0]![0]);
    expect(sql).toMatch(/\(seat\.via_race OR COALESCE\(o\.title, ''\) ILIKE 'Candidate for%'\)\s+AS is_candidate/);
  });

  // A candidate reaches the queue through a SEAT only if someone gave them a
  // "Candidate for …" placeholder. Most never got one: measured 2026-09-24, 1,018
  // people in upcoming federal races (972 House, 46 Senate) had no FEC row and no
  // seat the queue could see. Their race row names the office sought, which is
  // exactly what the FEC files a candidate under.
  it('reads the office sought from a federal race row, not only from a seat', async () => {
    poolQueryMock.mockResolvedValueOnce({ rows: [] });

    await getUnmatchedFederalPoliticians();

    const sql = String(poolQueryMock.mock.calls[0]![0]);
    expect(sql).toMatch(/FROM essentials\.race_candidates rc\s+JOIN essentials\.races r ON r\.id = rc\.race_id/);
    expect(sql).toMatch(/SELECT rc\.politician_id, r\.office_id, true AS via_race/);
  });

  it('takes a race only while it can still send the person to office', async () => {
    // Past elections, withdrawals and primary losers ("lost", "not_nominated") are
    // not running: researching them would confirm IDs for campaigns that are over.
    poolQueryMock.mockResolvedValueOnce({ rows: [] });

    await getUnmatchedFederalPoliticians();

    const sql = String(poolQueryMock.mock.calls[0]![0]);
    expect(sql).toContain('e.election_date >= CURRENT_DATE');
    expect(sql).toContain("rc.candidate_status IS DISTINCT FROM 'withdrawn'");
    expect(sql).toContain("(rc.result IS NULL OR rc.result = 'advanced')");
  });

  it('files a race-only Senate candidate under the Senate, as a candidacy', async () => {
    poolQueryMock.mockResolvedValueOnce({
      rows: [queueRow({ full_name: 'Sandy Spidel Neumann', chamber_name: 'U.S. Senate', representing_state: 'KS', is_candidate: true })],
    });

    const [row] = await getUnmatchedFederalPoliticians();

    expect(row).toMatchObject({ fec_office: 'S', source_system: 'fec_senate', representing_state: 'KS', is_candidate: true });
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

  it('ranks every seat, placeholder included, above a race row', async () => {
    // A sitting representative in a Senate race has a House seat AND a Senate race
    // row; a placeholder holder also has a race row for the same office. The seat
    // comes first in both cases, so a seat-based queue entry never changes.
    poolQueryMock.mockResolvedValueOnce({ rows: [] });

    await getUnmatchedFederalPoliticians();

    const sql = String(poolQueryMock.mock.calls[0]![0]);
    expect(sql).toMatch(/ORDER BY p\.id,\s+seat\.via_race ASC,\s+\(COALESCE\(o\.title, ''\) ILIKE 'Candidate for%'\) ASC/);
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
// Which of a person's FEC IDs — election_years decides what the name cannot
// ---------------------------------------------------------------------------
//
// A returning candidate has one FEC candidate ID per earlier campaign, under the
// SAME name, so name scoring ties them and an arbitrary one was confirmed. Three
// Senate candidates were confirmed onto their previous run's ID this way
// (found 2026-09-23). The FEC rows below are real, fetched that day, and in the
// order the FEC API returned them — stale ID first.
//
// A sitting member is different: one ID spans many cycles, and election_years
// lists ELECTIONS, not cycles. A senator not up until 2028 or 2030 has no 2026
// in it at all (Fetterman below), so "lists the current cycle" can only gate a
// candidate, never a member.

function fecRow(candidate_id: string, name: string, election_years: number[], overrides: Record<string, unknown> = {}) {
  return { candidate_id, name, office: 'S', state: 'XX', party: 'DEM', election_years, ...overrides };
}

const BOOKER_2020 = fecRow('S0KY00420', 'BOOKER, CHARLES', [2020, 2022]);
const BOOKER_2026 = fecRow('S6KY00385', 'BOOKER, CHARLES', [2026]);
const ROTH_2022 = fecRow('S2ID00178', 'ROTH, DAVID JORDAN', [2022]);
const SUNUNU_2002 = fecRow('S0NH00201', 'SUNUNU, JOHN E', [2002, 2008], { party: 'REP' });
const SUNUNU_2026 = fecRow('S6NH00208', 'SUNUNU, JOHN E', [2026], { party: 'REP' });
const SUNUNU_FATHER = fecRow('S0NH00045', 'SUNUNU, JOHN H', [1980], { party: 'REP' });
const FETTERMAN = fecRow('S6PA00274', 'FETTERMAN, JOHN KARL', [2016, 2022, 2028]);

describe('runFecAutoMatch — choosing between several FEC IDs for one person', () => {
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

  /** Queue one politician, answer each FEC search in turn, and return what was written. */
  async function autoMatch(row: Record<string, unknown>, ...searches: unknown[][]) {
    poolQueryMock
      .mockResolvedValueOnce({ rows: [row] })
      .mockResolvedValueOnce({ rows: [{ id: 'src-1' }] }); // createSource INSERT
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    for (const results of searches) fetchMock.mockResolvedValueOnce(candidatesSearchResponse(results));

    const run = runFecAutoMatch();
    await vi.runAllTimersAsync();
    const summary = await run;

    const result = summary.results[0]!;
    expect(result.error).toBeNull();
    const [, sourceSystem, externalId, researchStatus, notes] = poolQueryMock.mock.calls[1]![1] as string[];
    return { result, written: { sourceSystem, externalId, researchStatus, notes } };
  }

  const candidate = (full_name: string, representing_state: string) =>
    queueRow({ full_name, representing_state, chamber_name: 'U.S. Senate', is_candidate: true });
  const senator = (full_name: string, representing_state: string) =>
    queueRow({ full_name, representing_state, chamber_name: 'U.S. Senate', is_candidate: false });

  it('confirms the ID running this cycle when a returning candidate\'s old ID ties on name', async () => {
    const { written } = await autoMatch(candidate('Charles Booker', 'KY'), [BOOKER_2020, BOOKER_2026]);

    expect(written).toMatchObject({ externalId: 'S6KY00385', researchStatus: 'confirmed' });
  });

  it('passes over both an earlier campaign and a same-name relative from 1980', async () => {
    const { written } = await autoMatch(candidate('John Sununu', 'NH'), [SUNUNU_2002, SUNUNU_2026, SUNUNU_FATHER]);

    expect(written).toMatchObject({ externalId: 'S6NH00208', researchStatus: 'confirmed' });
  });

  it('prefers the current ID for a sitting member too, when two of theirs tie on name', async () => {
    const stale = fecRow('S0XX00001', 'DOE, JANE', [2010]);
    const current = fecRow('S2XX00002', 'DOE, JANE', [2022, 2028]);

    const { written } = await autoMatch(senator('Jane Doe', 'XX'), [stale, current]);

    expect(written).toMatchObject({ externalId: 'S2XX00002', researchStatus: 'confirmed' });
  });

  it('never confirms a candidate onto an ID that is not running this cycle', async () => {
    // Roth before his 2026 statement of candidacy was on file: only the 2022 ID exists.
    const { result, written } = await autoMatch(candidate('David Roth', 'ID'), [ROTH_2022]);

    expect(written.researchStatus).toBe('needs_research');
    expect(result.status).toBe('needs_research');
    const listed = JSON.parse(written.notes) as Array<{ candidate_id: string; election_years: number[] }>;
    expect(listed).toEqual([expect.objectContaining({ candidate_id: 'S2ID00178', election_years: [2022] })]);
  });

  it('does not let the single-result last-name fallback confirm a candidate onto an old ID either', async () => {
    // Full-name search misses (a nickname), the last-name retry finds one old ID; the
    // fallback's 0.8 bump must not outrank the cycle.
    const { written } = await autoMatch(candidate('Dave Roth', 'ID'), [], [ROTH_2022]);

    expect(written.researchStatus).toBe('needs_research');
  });

  it('still confirms a sitting senator who is not up this cycle', async () => {
    // FEC's own row: elections 2016, 2022, 2028 — no 2026, because he is not on this ballot.
    const { written } = await autoMatch(senator('John Fetterman', 'PA'), [FETTERMAN]);

    expect(written).toMatchObject({ externalId: 'S6PA00274', researchStatus: 'confirmed' });
  });

  it('still confirms a sitting member whose only ID has no election this cycle or later', async () => {
    // A member retiring at the end of this term keeps filing on the ID they hold.
    const retiring = queueRow({ full_name: 'Jane Doe', representing_state: 'UT' });
    const only = fecRow('H0UT01234', 'DOE, JANE', [2020, 2022, 2024], { office: 'H' });

    const { written } = await autoMatch(retiring, [only]);

    expect(written).toMatchObject({ externalId: 'H0UT01234', researchStatus: 'confirmed' });
  });

  it('counts an odd-year special election as part of its cycle', async () => {
    // FEC files a special under its own odd year: Patronis's FL-1 ID lists [2025, 2026].
    // In early 2025 it listed only the special, and 2025 belongs to cycle 2026.
    vi.setSystemTime(new Date('2025-03-01T12:00:00Z'));
    const patronis = fecRow('H6FL01390', 'PATRONIS, JIMMY JR.', [2025], { office: 'H' });
    const row = queueRow({ full_name: 'Jimmy Patronis', representing_state: 'FL', is_candidate: true });

    const { written } = await autoMatch(row, [patronis]);

    expect(written).toMatchObject({ externalId: 'H6FL01390', researchStatus: 'confirmed' });
  });

  it('sends it to review when the name favours an old ID and the cycle a newer one', async () => {
    // A retiring senator's own ID (exact first name) against a current one whose first
    // name only starts the same way. That can be the same person writing their name
    // short, or a different Janet running for the seat: the name cannot tell, so a
    // human does. Confirming either one is a guess.
    const own = fecRow('S2XX00001', 'DOE, JANE', [2014, 2020]);
    const other = fecRow('S6XX00002', 'DOE, JANET', [2026]);

    const { written } = await autoMatch(senator('Jane Doe', 'XX'), [own, other]);

    expect(written.researchStatus).toBe('needs_research');
    const listed = JSON.parse(written.notes) as Array<{ candidate_id: string }>;
    expect(listed.map(c => c.candidate_id).sort()).toEqual(['S2XX00001', 'S6XX00002']);
  });

  it('sends two IDs that tie on name AND on cycle to review instead of picking one', async () => {
    const first = fecRow('S6XX00001', 'DOE, JANE', [2026]);
    const second = fecRow('S6XX00002', 'DOE, JANE', [2026]);

    const { written } = await autoMatch(candidate('Jane Doe', 'XX'), [first, second]);

    expect(written.researchStatus).toBe('needs_research');
    const listed = JSON.parse(written.notes) as Array<{ candidate_id: string }>;
    expect(listed.map(c => c.candidate_id).sort()).toEqual(['S6XX00001', 'S6XX00002']);
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
// candidates were sent to needs_research this way. The FEC rows below are real.
// Van Hollen's came from /candidate/S6MD03441 on 2026-09-24: FEC files him under
// state DC, so a state=MD search does not return him at all.

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
    ['Chris Van Hollen', 'MD', false, 'S6MD03441', 'VAN HOLLEN, CHRIS', [2016, 2022, 2028]],
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

// ---------------------------------------------------------------------------
// The last-name fallback — a surname too short for FEC's search
// ---------------------------------------------------------------------------
//
// When the full-name search finds nothing (a nickname, or a middle name FEC holds
// only as an initial), the fallback retries with the last name alone. FEC's search
// rejects any keyword under 3 characters with HTTP 422, so for "Julie Trang Le" the
// retry for "le" failed on every run and she never left the queue (2026-09-24).
// FEC files her as "LE, JULIE T" — "Julie Le" finds her. The FEC row below is real.

describe('runFecAutoMatch — the last-name fallback', () => {
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

  /** Queue one politician, answer each FEC search in turn; return what was written and each search's q. */
  async function autoMatch(row: Record<string, unknown>, ...searches: unknown[][]) {
    poolQueryMock
      .mockResolvedValueOnce({ rows: [row] })
      .mockResolvedValueOnce({ rows: [{ id: 'src-1' }] }); // createSource INSERT
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    for (const results of searches) fetchMock.mockResolvedValueOnce(candidatesSearchResponse(results));

    const run = runFecAutoMatch();
    await vi.runAllTimersAsync();
    const summary = await run;

    const result = summary.results[0]!;
    expect(result.error).toBeNull();
    const queries = fetchMock.mock.calls.map(c => new URL(String(c[0])).searchParams.get('q'));
    const [, , externalId, researchStatus] = poolQueryMock.mock.calls[1]![1] as string[];
    return { result, queries, written: { externalId, researchStatus } };
  }

  const houseCandidate = (full_name: string, representing_state: string) =>
    queueRow({ full_name, representing_state, is_candidate: true });
  const JULIE_LE = { candidate_id: 'H6MN05399', name: 'LE, JULIE T', office: 'H', state: 'MN', party: 'DFL', election_years: [2026] };

  it('retries a surname under 3 characters as "first last", which FEC accepts', async () => {
    const { queries, written } = await autoMatch(houseCandidate('Julie Trang Le', 'MN'), [], [JULIE_LE]);

    expect(queries).toEqual(['Julie Trang Le', 'julie le']);
    expect(written).toEqual({ externalId: 'H6MN05399', researchStatus: 'confirmed' });
  });

  it('still retries a surname of 3 or more characters on its own', async () => {
    await expect(autoMatch(houseCandidate('Dave Roth', 'ID'), [], [])).resolves.toMatchObject({
      queries: ['Dave Roth', 'roth'],
    });
  });
});

// ---------------------------------------------------------------------------
// FEC name formatting the scorer must see through
// ---------------------------------------------------------------------------
//
// Found reviewing the 148 rows the 2026-09-24 auto-match left at needs_research
// (CA_0258): real people scored 0.6 or 0 against their own 2026 ID because FEC
// put a title before the given name, typed a double comma, or wrote a hyphenated
// surname with a space. All FEC names below are real.

describe('parseFecName / scoreMatch — FEC name formatting', () => {
  const person = (full_name: string) =>
    ({ id: 'p', full_name, bioguide_id: null } as unknown as Parameters<typeof scoreMatch>[0]);
  const fec = (name: string) => ({ candidate_id: 'H6XX00001', name } as unknown as Parameters<typeof scoreMatch>[1]);

  it('skips titles before the given name', () => {
    expect(parseFecName('RAZACK, MD JD, NIZAM')).toEqual({ first: 'nizam', last: 'razack' });
    expect(scoreMatch(person('Nizam Razack'), fec('RAZACK, MD JD, NIZAM'))).toBe(0.9);
  });

  it('skips the empty token a double comma leaves', () => {
    expect(parseFecName('BRINK,, BRIDGET')).toEqual({ first: 'bridget', last: 'brink' });
    expect(scoreMatch(person('Bridget Brink'), fec('BRINK,, BRIDGET'))).toBe(0.9);
  });

  it('reads a hyphen as a space, on either side', () => {
    expect(scoreMatch(person('Byron Sigcho-Lopez'), fec('SIGCHO LOPEZ, BYRON'))).toBe(0.9);
    expect(scoreMatch(person('Bernadette Greene-Placentia'), fec('GREENE PLACENTIA, BERNADETTE'))).toBe(0.9);
    expect(scoreMatch(person('Melisa Lopez Franzen'), fec('LOPEZ-FRANZEN, MELISA'))).toBe(0.9);
  });

  it('still does not match a one-word surname to one half of a hyphenated one', () => {
    expect(scoreMatch(person('Maria Lopez'), fec('SIGCHO-LOPEZ, MARIA'))).toBe(0);
  });

  it('leaves the given name empty when it holds only titles', () => {
    expect(parseFecName('SMITH, MR.')).toEqual({ first: '', last: 'smith' });
  });

  it('keeps a title that follows the given name out of the way, as before', () => {
    expect(parseFecName('DOUGLASS, EUGENE FARLEY DR.')).toEqual({ first: 'eugene', last: 'douglass' });
    expect(parseFecName('COESTER, C. MARK MR')).toEqual({ first: 'c', last: 'coester' });
  });
});

// ---------------------------------------------------------------------------
// Re-checking needs_research rows
// ---------------------------------------------------------------------------
//
// The queue used to skip anyone with ANY FEC row, so a needs_research row was
// final: a candidate who had not filed yet when the auto-match ran was never
// looked at again after they filed. After the 2026-09-24 run and review, 96 rows
// sat there (58 with no FEC record at all). A needs_research-only person now
// comes back once their row is older than the re-check interval, and the re-check
// rewrites that same row instead of adding a second one.

describe('getUnmatchedFederalPoliticians — re-checking needs_research rows', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
  });

  it('lets back in a person whose only FEC row is a needs_research row older than the interval', async () => {
    poolQueryMock.mockResolvedValueOnce({ rows: [] });

    await getUnmatchedFederalPoliticians();

    const sql = String(poolQueryMock.mock.calls[0]![0]);
    // any settled FEC row, or a needs_research row checked recently, still keeps the person out
    expect(sql).toMatch(
      /AND NOT EXISTS \(\s*SELECT 1\s+FROM transparent_motivations\.politician_sources ps\s+WHERE ps\.essentials_politician_id = p\.id\s+AND ps\.source_system LIKE 'fec%'\s+AND \(ps\.research_status <> 'needs_research'\s+OR ps\.updated_at >= now\(\) - interval '7 days'\)/,
    );
  });

  it('returns the needs_research row to re-check, or null for a first check', async () => {
    poolQueryMock.mockResolvedValueOnce({
      rows: [queueRow({ id: 'pol-1', recheck_source_id: 'src-old' }), queueRow({ id: 'pol-2', recheck_source_id: null })],
    });

    const rows = await getUnmatchedFederalPoliticians();

    expect(rows.map(r => r.recheck_source_id)).toEqual(['src-old', null]);
    expect(String(poolQueryMock.mock.calls[0]![0])).toMatch(/AS recheck_source_id/);
  });
});

describe('runFecAutoMatch — a re-check rewrites the existing row', () => {
  const savedKey = process.env.FEC_API_KEY;

  beforeEach(() => {
    poolQueryMock.mockReset();
    acquireFecSlotMock.mockClear();
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(candidatesSearchResponse()));
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-10-05T12:00:00Z')); // FEC cycle 2026
    process.env.FEC_API_KEY = 'test-api-key';
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    if (savedKey === undefined) delete process.env.FEC_API_KEY;
    else process.env.FEC_API_KEY = savedKey;
  });

  const VAN_HILLEARY_2026 = { candidate_id: 'H4TN04072', name: 'HILLEARY, VAN', office: 'H', state: 'TN', party: 'REP', election_years: [2000, 2002, 2026] };

  async function recheck(fecResults: unknown[]) {
    poolQueryMock
      .mockResolvedValueOnce({ rows: [queueRow({ full_name: 'Van Hilleary', representing_state: 'TN', is_candidate: true, recheck_source_id: 'src-old' })] })
      .mockResolvedValueOnce({ rows: [{ id: 'src-old' }] }); // the UPDATE
    (fetch as unknown as ReturnType<typeof vi.fn>).mockResolvedValueOnce(candidatesSearchResponse(fecResults));

    const run = runFecAutoMatch();
    await vi.runAllTimersAsync();
    const summary = await run;
    const [sql, params] = poolQueryMock.mock.calls[1]! as [string, unknown[]];
    return { result: summary.results[0]!, sql: String(sql), params };
  }

  it('UPDATEs the needs_research row in place when the person has now filed', async () => {
    const { result, sql, params } = await recheck([VAN_HILLEARY_2026]);

    expect(result).toMatchObject({ status: 'confirmed', selected_fec_id: 'H4TN04072', source_id: 'src-old', error: null });
    expect(sql).toMatch(/^\s*UPDATE transparent_motivations\.politician_sources/);
    expect(sql).not.toMatch(/INSERT/);
    expect(sql).toMatch(/updated_at = now\(\)/);
    expect(sql).toMatch(/WHERE id = \$1 AND research_status = 'needs_research'/);
    expect(params).toEqual(['src-old', 'fec_house', 'H4TN04072', 'confirmed', '']);
  });

  it('still rewrites the row when the answer is again needs_research, so it waits out the interval', async () => {
    const { result, sql, params } = await recheck([]);

    expect(result).toMatchObject({ status: 'needs_research', source_id: 'src-old', error: null });
    expect(sql).toMatch(/^\s*UPDATE transparent_motivations\.politician_sources/);
    expect(params[3]).toBe('needs_research');
  });

  it('reports an error and writes nothing else when the row was settled meanwhile', async () => {
    poolQueryMock
      .mockResolvedValueOnce({ rows: [queueRow({ full_name: 'Van Hilleary', representing_state: 'TN', is_candidate: true, recheck_source_id: 'src-old' })] })
      .mockResolvedValueOnce({ rows: [] }); // UPDATE matched nothing: someone confirmed or disputed it
    (fetch as unknown as ReturnType<typeof vi.fn>).mockResolvedValueOnce(candidatesSearchResponse([VAN_HILLEARY_2026]));

    const run = runFecAutoMatch();
    await vi.runAllTimersAsync();
    const summary = await run;

    expect(summary.results[0]!.error).toMatch(/no longer needs_research/);
    expect(summary.errors).toBe(1);
    expect(poolQueryMock).toHaveBeenCalledTimes(2);
  });
});
