import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Mock the shared pool so importing ocpfAdapter.ts (which reaches ../db.js at module
// scope) doesn't trigger env.ts's startup validation in a test environment with no
// real DATABASE_URL. Mirrors fecAdapter.test.ts.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

import { createOcpfAdapter, parseOcpfAmount } from './ocpfAdapter.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

const PAGE_SIZE = 250;

function source(externalId = '12008'): PoliticianSource {
  return { id: 'src-1', external_id: externalId } as unknown as PoliticianSource;
}

/**
 * Reproduces the OCPF API's ACTUAL behaviour, confirmed live against
 * api.ocpf.us on 2026-08-17:
 *
 *   pageNumber is IGNORED. Pages 1, 2, 3, 50, 298, 500 and 1000 all returned the
 *   identical 250 records (same first ids 518289, 518326). pageSize IS honoured —
 *   pageSize=10 returns 10, pageSize=1000 returns the cycle's true total of 289.
 *
 * So a full first page is NOT evidence that another page exists, and the old
 * `items.length < PAGE_SIZE` exit condition could never fire for any committee
 * with >= 250 receipts in the window.
 */
function mockOcpfIgnoringPageNumber(total: number) {
  return vi.fn(async (url: string) => {
    const size = Number(new URL(url).searchParams.get('pageSize') ?? PAGE_SIZE);
    // pageNumber deliberately not read — the real API ignores it.
    const n = Math.min(size, total);
    const items = Array.from({ length: n }, (_, i) => ({ id: 518289 + i, amount: 1 }));
    return { status: 200, json: async () => ({ summary: null, items }) } as unknown as Response;
  });
}

describe('ocpfAdapter pagination', () => {
  beforeEach(() => vi.stubGlobal('fetch', vi.fn()));
  afterEach(() => vi.unstubAllGlobals());

  it('terminates and returns each record ONCE when the window holds more than one page', async () => {
    // 289 records — above PAGE_SIZE, so this is exactly the shape that used to loop
    // forever. (It was the real 2005-Q2 total for cpf 12008 back when the adapter still
    // took date windows; the adapter now always asks for the filer's full history.)
    const fetchMock = mockOcpfIgnoringPageNumber(289);
    vi.stubGlobal('fetch', fetchMock);

    const result = await createOcpfAdapter().fetch(source());

    // Before the fix this never returned — the loop appended the same 250 rows
    // ~300 times until the external 180s timeout aborted it.
    expect(result.records.length).toBe(289);

    // And every record must be distinct: the old loop's output was 300 copies.
    const ids = new Set(result.records.map((r) => (r as { id: number }).id));
    expect(ids.size).toBe(289);
  });

  it('issues ONE request per filer, not one per phantom page', async () => {
    const fetchMock = mockOcpfIgnoringPageNumber(289);
    vi.stubGlobal('fetch', fetchMock);

    await createOcpfAdapter().fetch(source());

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('still returns everything for a filer with less than one page of receipts', async () => {
    const fetchMock = mockOcpfIgnoringPageNumber(42);
    vi.stubGlobal('fetch', fetchMock);

    const result = await createOcpfAdapter().fetch(source());

    expect(result.records.length).toBe(42);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('handles the largest real committee (cpf 15710, 89,557 records) in one request', async () => {
    const fetchMock = mockOcpfIgnoringPageNumber(89_557);
    vi.stubGlobal('fetch', fetchMock);

    const result = await createOcpfAdapter().fetch(source('15710'));

    expect(result.records.length).toBe(89_557);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('sends NO date window — the chunking it replaced was sized in phantom pages', async () => {
    // The year/quarter/month/week chunking existed to keep each fetch inside a 3-minute
    // budget, sized as "~300 pages x 0.5s". Those pages were the same 250 rows re-appended.
    // Measured live 2026-08-17: cpf 15710's ENTIRE history is 89,557 records in ~5s, and its
    // worst single quarter is 5,754 — so the windows subdivided one short call. A StartDate
    // reappearing here means someone reintroduced a window without measuring it.
    const fetchMock = mockOcpfIgnoringPageNumber(289);
    vi.stubGlobal('fetch', fetchMock);

    await createOcpfAdapter().fetch(source());

    const url = new URL(fetchMock.mock.calls[0][0] as string);
    expect(url.searchParams.get('StartDate')).toBeNull();
    expect(url.searchParams.get('EndDate')).toBeNull();
    expect(url.searchParams.get('CpfId')).toBe('12008');
  });

  it('throws rather than silently truncating if the response fills the requested pageSize', async () => {
    // If OCPF ever caps pageSize, items.length === requested size is the ONLY
    // signal available (there is no total count — `summary` is null). Silently
    // returning a truncated set would undercount a filer's receipts, so this must
    // fail loudly instead.
    const fetchMock = vi.fn(async (url: string) => {
      const size = Number(new URL(url).searchParams.get('pageSize') ?? PAGE_SIZE);
      const items = Array.from({ length: size }, (_, i) => ({ id: i, amount: 1 }));
      return { status: 200, json: async () => ({ summary: null, items }) } as unknown as Response;
    });
    vi.stubGlobal('fetch', fetchMock);

    await expect(createOcpfAdapter().fetch(source())).rejects.toThrow(/truncat|cap/i);
  });
});

describe('parseOcpfAmount', () => {
  // OCPF sends PRESENTATION TEXT, not numbers. The old parser was
  // parseFloat(s.replace(/^[$]/, '')), which failed two ways at once.

  it('parses a thousands separator instead of TRUNCATING at it', () => {
    // 🔴 THE SILENT BUG. parseFloat("1,000.00") === 1, and that 1 was stored as a real
    // dollar figure. It capped the entire stored MA corpus at $999.00: 11,672 of 107,698
    // rows understated by $15,643,496.52 in total.
    expect(parseOcpfAmount('$1,000.00')).toBe(1000);
    expect(parseOcpfAmount('$12,345.67')).toBe(12345.67);
    // The largest real contribution in the corpus, previously stored as $945.
    expect(parseOcpfAmount('$945,000.00')).toBe(945000);
  });

  it('reads ACCOUNTING PARENTHESES as negative rather than dropping the row', () => {
    // The loud bug: parseFloat("($1,000.00)") === NaN, so the row was skipped entirely.
    // 609 records on cpf 15710 and 99 on 15931 never reached the database.
    expect(parseOcpfAmount('($1,000.00)')).toBe(-1000);
    expect(parseOcpfAmount('($5.00)')).toBe(-5);
    expect(parseOcpfAmount('(945,000.00)')).toBe(-945000);
  });

  it('handles plain and zero amounts', () => {
    expect(parseOcpfAmount('$50.00')).toBe(50);
    expect(parseOcpfAmount('$0.00')).toBe(0);
    expect(parseOcpfAmount('-$25.00')).toBe(-25);
    expect(parseOcpfAmount('100')).toBe(100);
    expect(parseOcpfAmount(42)).toBe(42);
  });

  it('REFUSES anything unrecognised instead of coercing it', () => {
    // The whole lesson of the comma defect: a wrong number that looks real is worse
    // than a skipped row. Anything not matching the expected shape must return null.
    for (const bad of ['', '   ', 'abc', '$', '$1.2.3', '--5', '12 dollars', null, undefined, {}]) {
      expect(parseOcpfAmount(bad as unknown)).toBeNull();
    }
    expect(parseOcpfAmount(NaN)).toBeNull();
  });
});

describe('ocpfAdapter normalize — amount fidelity', () => {
  beforeEach(() => vi.stubGlobal('fetch', vi.fn()));
  afterEach(() => vi.unstubAllGlobals());

  it('carries a four-figure amount and a negative through to the contribution', async () => {
    const items = [
      { id: 1, amount: '$1,000.00', date: '03/15/2024', firstName: 'A', lastName: 'B', electionYear: 2024 },
      { id: 2, amount: '($250.00)', date: '03/16/2024', firstName: 'C', lastName: 'D', electionYear: 2024 },
      { id: 3, amount: '$945,000.00', date: '03/17/2024', firstName: 'E', lastName: 'F', electionYear: 2024 },
    ];
    vi.stubGlobal('fetch', vi.fn(async () => (
      { status: 200, json: async () => ({ summary: null, items }) } as unknown as Response
    )));

    const adapter = createOcpfAdapter();
    const ps = source();
    const norm = await adapter.normalize(await adapter.fetch(ps), ps);

    // No row is dropped, and no amount is truncated.
    expect(norm.contributions.map((c) => c.amount)).toEqual([1000, -250, 945000]);
    expect(norm.skipped).toBe(0);
  });
});
