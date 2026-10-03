import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Mock the shared pool so importing ocpfAdapter.ts (which reaches ../db.js at module
// scope) doesn't trigger env.ts's startup validation in a test environment with no
// real DATABASE_URL. Mirrors fecAdapter.test.ts.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

import { createOcpfAdapter, ocpfWindows, parseOcpfAmount } from './ocpfAdapter.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

const PAGE_SIZE = 250;

function source(externalId = '12008'): PoliticianSource {
  return { id: 'src-1', external_id: externalId } as unknown as PoliticianSource;
}

/** Parse OCPF's MM/DD/YYYY into a comparable yyyymmdd number. */
function ymd(mdy: string): number {
  const [m, d, y] = mdy.split('/').map(Number);
  return y * 10000 + m * 100 + d;
}

/**
 * Reproduces the OCPF API's ACTUAL behaviour, confirmed live against api.ocpf.us:
 *
 *   pageNumber is IGNORED (2026-08-17). Pages 1, 2, 3, 50, 298, 500 and 1000 all returned
 *   the identical 250 records (same first ids 518289, 518326). pageSize IS honoured —
 *   pageSize=10 returns 10, pageSize=1000 returns the window's true total of 289.
 *
 *   StartDate / EndDate filter INCLUSIVELY, and either may be sent alone (2026-10-02).
 *
 * `perYear` maps a calendar year to how many receipts the filer has that year; every
 * receipt is dated 06/15 of its year, except that each year's first receipt sits on
 * 01/01 and its last on 12/31 so the boundaries are exercised.
 */
function mockOcpf(perYear: Record<number, number>) {
  const all: { id: number; amount: number; date: string }[] = [];
  let id = 1;
  for (const [yearStr, n] of Object.entries(perYear)) {
    const y = Number(yearStr);
    for (let i = 0; i < n; i++) {
      const date = i === 0 ? `01/01/${y}` : i === n - 1 ? `12/31/${y}` : `06/15/${y}`;
      all.push({ id: id++, amount: 1, date });
    }
  }
  return vi.fn(async (url: string) => {
    const q = new URL(url).searchParams;
    const size = Number(q.get('pageSize') ?? PAGE_SIZE);
    const start = q.get('StartDate');
    const end = q.get('EndDate');
    // pageNumber deliberately not read — the real API ignores it.
    const inWindow = all.filter((r) =>
      (!start || ymd(r.date) >= ymd(start)) && (!end || ymd(r.date) <= ymd(end)));
    const items = inWindow.slice(0, size);
    return { status: 200, json: async () => ({ summary: null, items }) } as unknown as Response;
  });
}

const THIS_YEAR = new Date().getUTCFullYear();

describe('ocpfWindows', () => {
  it('covers before, every year, and after — with no gap and no overlap', () => {
    const w = ocpfWindows(1995, 1996);
    expect(w).toEqual([
      { end: '12/31/1994' },
      { start: '01/01/1995', end: '03/31/1995' },
      { start: '04/01/1995', end: '06/30/1995' },
      { start: '07/01/1995', end: '09/30/1995' },
      { start: '10/01/1995', end: '12/31/1995' },
      { start: '01/01/1996', end: '03/31/1996' },
      { start: '04/01/1996', end: '06/30/1996' },
      { start: '07/01/1996', end: '09/30/1996' },
      { start: '10/01/1996', end: '12/31/1996' },
      { start: '01/01/1997' },
    ]);
  });
});

describe('ocpfAdapter fetch', () => {
  beforeEach(() => vi.stubGlobal('fetch', vi.fn()));
  afterEach(() => vi.unstubAllGlobals());

  it('terminates and returns each record ONCE when a window holds more than one page', async () => {
    // 289 records in one year — above PAGE_SIZE, so this is exactly the shape that used to
    // loop forever (the real 2005-Q2 total for cpf 12008).
    vi.stubGlobal('fetch', mockOcpf({ 2005: 289 }));

    const result = await createOcpfAdapter().fetch(source());

    // Before the page-loop fix this never returned — the loop appended the same 250 rows
    // ~300 times until the external 180s timeout aborted it.
    expect(result.records.length).toBe(289);
    const ids = new Set(result.records.map((r) => (r as { id: number }).id));
    expect(ids.size).toBe(289);
  });

  it('sends ONE request per quarter window, plus the two open-ended edges', async () => {
    const fetchMock = mockOcpf({ 2005: 289 });
    vi.stubGlobal('fetch', fetchMock);

    await createOcpfAdapter().fetch(source());

    const urls = fetchMock.mock.calls.map((c) => new URL(c[0] as string).searchParams);
    // Four quarters of 1995..THIS_YEAR inclusive, plus "before" and "after".
    expect(urls.length).toBe((THIS_YEAR - 1995 + 1) * 4 + 2);
    expect(urls.every((q) => q.get('CpfId') === '12008')).toBe(true);
    // The edges are open-ended, so a record dated outside the year range is still read.
    expect(urls[0].get('StartDate')).toBeNull();
    expect(urls.at(-1)!.get('EndDate')).toBeNull();
  });

  it('reads the whole history across windows — nothing lost at a boundary or an edge', async () => {
    // Every year's receipts sit on 01/01, 06/15 and 12/31 — the edges of the first, second
    // and last quarter; 1990 is before the first quarter and THIS_YEAR+1 after the last.
    vi.stubGlobal('fetch', mockOcpf({ 1990: 3, 2001: 500, 2025: 382, [THIS_YEAR]: 29, [THIS_YEAR + 1]: 2 }));

    const result = await createOcpfAdapter().fetch(source('15710'));

    expect(result.records.length).toBe(3 + 500 + 382 + 29 + 2);
    const ids = new Set(result.records.map((r) => (r as { id: number }).id));
    expect(ids.size).toBe(result.records.length);
  });

  it('throws rather than silently truncating if a window fills the requested pageSize', async () => {
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

describe('ocpfAdapter fetchStream — memory bound', () => {
  beforeEach(() => vi.stubGlobal('fetch', vi.fn()));
  afterEach(() => vi.unstubAllGlobals());

  it('hands each quarter to onBatch before fetching the next, and buffers nothing itself', async () => {
    // 🔴 THE 2026-10-01 OOM. One full-history request for cpf 15710 (97,205 records,
    // 109 MB) overran the 512 MiB cron. Streaming by quarter bounds the peak to one quarter.
    const fetchMock = mockOcpf({ 2022: 214, 2024: 150, [THIS_YEAR]: 290 });
    vi.stubGlobal('fetch', fetchMock);

    const batches: number[] = [];
    const callsAtBatch: number[] = [];
    const adapter = createOcpfAdapter() as unknown as {
      fetchStream: (ps: PoliticianSource, onBatch: (r: Record<string, unknown>[]) => Promise<void>) =>
        Promise<{ records: unknown[]; totalFetched: number }>;
    };
    const result = await adapter.fetchStream(source('15710'), async (records) => {
      batches.push(records.length);
      callsAtBatch.push(fetchMock.mock.calls.length);
    });

    // One batch per non-empty quarter; no batch ever spans two. The mock dates each
    // year's receipts 01/01 (Q1), 06/15 (Q2) and 12/31 (Q4).
    expect(batches).toEqual([1, 212, 1, 1, 148, 1, 1, 288, 1]);
    // Each batch was delivered BEFORE the following window was requested.
    for (let i = 1; i < callsAtBatch.length; i++) {
      expect(callsAtBatch[i]).toBeGreaterThan(callsAtBatch[i - 1]);
    }
    // StreamingAdapter contract: records were streamed, not buffered.
    expect(result.records).toEqual([]);
    expect(result.totalFetched).toBe(214 + 150 + 290);
  });

  it('stops between windows when the signal aborts', async () => {
    vi.stubGlobal('fetch', mockOcpf({ 2000: 5, 2001: 5 }));
    const controller = new AbortController();
    const adapter = createOcpfAdapter() as unknown as {
      fetchStream: (ps: PoliticianSource, onBatch: () => Promise<void>, signal?: AbortSignal) => Promise<unknown>;
    };

    await expect(adapter.fetchStream(source(), async () => {
      controller.abort(new Error('per-source timeout'));
    }, controller.signal)).rejects.toThrow(/per-source timeout/);
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
    // Only the 2024 window holds these receipts, as on the real API.
    vi.stubGlobal('fetch', vi.fn(async (url: string) => {
      const in2024 = new URL(url).searchParams.get('StartDate') === '01/01/2024';
      return { status: 200, json: async () => ({ summary: null, items: in2024 ? items : [] }) } as unknown as Response;
    }));

    const adapter = createOcpfAdapter();
    const ps = source();
    const norm = await adapter.normalize(await adapter.fetch(ps), ps);

    // No row is dropped, and no amount is truncated.
    expect(norm.contributions.map((c) => c.amount)).toEqual([1000, -250, 945000]);
    expect(norm.skipped).toBe(0);
  });
});
