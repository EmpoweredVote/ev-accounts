import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Mock the shared pool so importing netfileAdapter.ts (which reaches ../db.js at module
// scope) doesn't trigger env.ts's startup validation. Mirrors indianaAdapter.test.ts.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

import { createNetfileAdapter, assertNetfileRunHealthy } from './netfileAdapter.js';
import type { PoliticianSource } from '../campaignFinanceService.js';
import type { ContributionInsert } from './adapterInterface.js';

// ---------------------------------------------------------------------------
// Fixtures: the shapes the live API returned on 2026-09-24 for LACO.
//
// FPPC id 1417140 (Henderson) is NetFile committee 209512005. `filings/byFiler` answers
// `{"filings":[],"totalCount":0}` when handed the FPPC id; only `IdSearch?sosId=` maps one
// to the other.
// ---------------------------------------------------------------------------

interface Filing {
  id: string;
  formName: string;
  filerName: string;
  filingDate: string;
  sequenceNumber?: string;
  periodStart?: string | null;
  periodEnd?: string | null;
}

interface Tx {
  id: string;
  filingId: string;
  filerName: string;
  date?: string;
  amount?: number;
  schedule?: string;
  name?: string;
}

function filing(f: Filing) {
  return {
    formId: 'f', formGroupId: 'g', sequenceNumber: '0', reportNumber: '', periodStart: null,
    periodEnd: null, imageExternalReference: '', obfuscatedId: '', hasAttachment: false, ...f,
  };
}

function tx(t: Tx) {
  return {
    date: '2026-05-21T07:00:00Z', amount: 100, transactionType: 'F460A (Monetary contributions)',
    schedule: '460A', name: 'Donor, Dana', vendor: null, address: 'Los Angeles, CA, 90067',
    spendingCode: '', employer: '', occupation: '', ...t,
  };
}

interface Api {
  /**
   * The one agency these fixtures belong to (default LACO). Asked under any other agency the
   * mock answers as the live API does for an id that agency does not know: no committee, no
   * filing, no row. That is how the three West Hollywood links read 0 rows under LACO.
   */
  agency?: string;
  /** FPPC id → NetFile committee ids, as IdSearch answers. */
  idSearch?: Record<string, string[]>;
  /** NetFile filer id → its filings. Any other id answers the empty list, like the live API. */
  filings?: Record<string, ReturnType<typeof filing>[]>;
  /** Every transaction the search can return; a query matches on its words. */
  transactions?: ReturnType<typeof tx>[];
  /** Force a status for a path fragment, e.g. { SearchCampaignTransactions: 503 }. */
  status?: Record<string, number>;
  /** Override totalCount on the search, to model a short page walk. */
  totalCountBump?: number;
}

/** Serves the four NetFile endpoints the adapter reads, from in-memory fixtures. */
function mockApi(api: Api): ReturnType<typeof vi.fn> {
  const fetchMock = vi.fn(async (input: string) => {
    const url = new URL(input);
    const path = url.pathname;
    for (const [fragment, status] of Object.entries(api.status ?? {})) {
      if (path.includes(fragment)) return new Response('{}', { status });
    }
    const json = (body: unknown) => new Response(JSON.stringify(body), { status: 200 });
    const agency = url.searchParams.get('aid') ?? url.searchParams.get('agencyCode');
    const known = agency === (api.agency ?? 'LACO');

    if (path.endsWith('/IdSearch')) {
      const ids = (known && api.idSearch?.[url.searchParams.get('sosId') ?? '']) || [];
      return json({ committees: ids.map(id => ({ id, name: `committee ${id}` })), measures: [] });
    }
    if (path.endsWith('/filings/byFiler')) {
      const list = (known && api.filings?.[url.searchParams.get('filerId') ?? '']) || [];
      return json({ filings: list, totalCount: 0 });
    }
    if (path.endsWith('/SearchCampaignTransactions')) {
      const query = url.searchParams.get('query') ?? '';
      // The live search 500s on a ':' and matches nothing once a ',' is in the query.
      if (query.includes(':')) return new Response('{}', { status: 500 });
      if (query.includes(',')) return json({ items: [], totalCount: 0, hasNextPage: false });
      const words = query.toLowerCase().split(/\s+/).filter(Boolean);
      const hits = (known ? api.transactions ?? [] : []).filter(t => {
        const hay = `${t.filerName} ${t.name}`.toLowerCase();
        return words.every(w => hay.includes(w));
      });
      const pageSize = Number(url.searchParams.get('pageSize'));
      const page = Number(url.searchParams.get('currentPage'));
      const items = hits.slice((page - 1) * pageSize, page * pageSize);
      return json({
        aid: agency, items, pageSize, currentPage: page, pageCount: 0,
        totalCount: hits.length + (api.totalCountBump ?? 0),
        hasNextPage: page * pageSize < hits.length, hasPreviousPage: page > 1,
      });
    }
    return new Response('not found', { status: 404 });
  });
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

function source(externalId: string, id = `src-${externalId}`, agency: string | null = 'LACO'): PoliticianSource {
  return { id, external_id: externalId, netfile_agency: agency } as unknown as PoliticianSource;
}

const HENDERSON = 'Henderson for LA Community College Board 2028';

beforeEach(() => {
  poolQueryMock.mockReset();
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('netfileAdapter fetch: finding the committee', () => {
  it('maps the stored FPPC id to the NetFile committee id before reading filings', async () => {
    const fetchMock = mockApi({
      idSearch: { '1417140': ['209512005'] },
      filings: {
        '209512005': [filing({ id: '216803119', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2026-05-21T00:00:00Z' })],
      },
      transactions: [tx({ id: 'a', filingId: '216803119', filerName: HENDERSON })],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(got.records.map(r => r.id)).toEqual(['a']);
    const byFiler = fetchMock.mock.calls
      .map(c => new URL(c[0] as string))
      .filter(u => u.pathname.endsWith('/filings/byFiler'));
    expect(byFiler.map(u => u.searchParams.get('filerId'))).toEqual(['209512005']);
  });

  it('reads the stored id as a NetFile id when IdSearch knows no committee for it', async () => {
    const name = 'LA County: Lindsey Horvath for Supervisor 2026';
    mockApi({
      filings: { '216785710': [filing({ id: '217000001', formName: 'FPPC 460', filerName: name, filingDate: '2026-07-31T00:00:00Z' })] },
      transactions: [tx({ id: 'h', filingId: '217000001', filerName: name })],
    });

    const got = await createNetfileAdapter(2026).fetch(source('216785710'));

    expect(got.records.map(r => r.id)).toEqual(['h']);
  });

  it('returns no rows, without failing, when NetFile has no committee for the id at all', async () => {
    mockApi({});

    const got = await createNetfileAdapter(2026).fetch(source('1450349'));

    expect(got.records).toEqual([]);
  });
});

describe('netfileAdapter fetch: the agency comes from the link', () => {
  // Measured 2026-09-24: Chelsea Byers' committee 202019492 is a City of West Hollywood
  // filer. Under WEHO it has 15 filings and 282 Schedule A rows; under LACO, IdSearch,
  // filings/byFiler and the search all answer nothing, with HTTP 200.
  const BYERS = 'Chelsea Byers for West Hollywood City Council 2022';
  const weho: Api = {
    agency: 'WEHO',
    filings: { '202019492': [filing({ id: '203000001', formName: 'FPPC 460', filerName: BYERS, filingDate: '2022-11-01T00:00:00Z' })] },
    transactions: [tx({ id: 'b', filingId: '203000001', filerName: BYERS })],
  };

  it("reads all three endpoints under the link's own agency", async () => {
    const fetchMock = mockApi(weho);

    const got = await createNetfileAdapter(2026).fetch(source('202019492', 'src-byers', 'WEHO'));

    expect(got.records.map(r => r.id)).toEqual(['b']);
    const agencies = fetchMock.mock.calls.map(c => {
      const u = new URL(c[0] as string);
      return u.searchParams.get('aid') ?? u.searchParams.get('agencyCode');
    });
    expect(new Set(agencies)).toEqual(new Set(['WEHO']));
  });

  it('fails a link that names no agency, rather than guessing LA County', async () => {
    const fetchMock = mockApi(weho);

    await expect(createNetfileAdapter(2026).fetch(source('202019492', 'src-byers', null))).rejects.toThrow(
      /netfile_agency/
    );
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

describe('netfileAdapter fetch: reading the transactions', () => {
  it('drops punctuation from the committee name, which the search cannot take', async () => {
    const name = 'Tina Fredericks for PUSD Board Member, 2024';
    mockApi({
      idSearch: { '1461887': ['211581987'] },
      filings: { '211581987': [filing({ id: '212000001', formName: 'FPPC 460', filerName: name, filingDate: '2024-10-24T00:00:00Z' })] },
      transactions: [tx({ id: 't', filingId: '212000001', filerName: name })],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1461887'));

    expect(got.records.map(r => r.id)).toEqual(['t']);
  });

  it("keeps only rows reported on the committee's own filings", async () => {
    mockApi({
      idSearch: { '1417140': ['209512005'] },
      filings: { '209512005': [filing({ id: 'own', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2026-05-21T00:00:00Z' })] },
      transactions: [
        tx({ id: 'mine', filingId: 'own', filerName: HENDERSON }),
        // Another committee's filing, on which Henderson's committee is the DONOR.
        tx({ id: 'gave', filingId: 'other', filerName: 'Coalition for LA Community College Reform', name: HENDERSON }),
      ],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(got.records.map(r => r.id)).toEqual(['mine']);
  });

  it('drops the rows of a Form 460 that a later amendment replaced', async () => {
    const period = { periodStart: '2025-01-01T00:00:00+00:00', periodEnd: '2025-06-30T00:00:00+00:00' };
    mockApi({
      idSearch: { '1417140': ['209512005'] },
      filings: {
        '209512005': [
          filing({ id: 'amended', formName: 'FPPC 460 (Amendment)', filerName: HENDERSON, filingDate: '2025-07-17T00:00:00Z', sequenceNumber: '1', ...period }),
          filing({ id: 'original', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2025-07-16T00:00:00Z', ...period }),
          filing({ id: 'next', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2026-01-27T00:00:00Z', periodStart: '2025-07-01T00:00:00+00:00', periodEnd: '2025-12-31T00:00:00+00:00' }),
        ],
      },
      transactions: [
        tx({ id: 'o1', filingId: 'original', filerName: HENDERSON }),
        tx({ id: 'a1', filingId: 'amended', filerName: HENDERSON }),
        tx({ id: 'n1', filingId: 'next', filerName: HENDERSON }),
      ],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(got.records.map(r => r.id).sort()).toEqual(['a1', 'n1']);
  });

  // Horvath's committee (216785710), 2026-09-24: its history was imported as a second copy of
  // each report. For 2025-01-01..06-30 the copy filed LATER (07-30) holds no rows at all; the
  // one filed 07-24 holds all 289.
  it('keeps the copy of a report that carries rows when a later copy carries none', async () => {
    const name = 'LA County: Lindsey Horvath for Supervisor 2026';
    const period = { periodStart: '2025-01-01T00:00:00+00:00', periodEnd: '2025-06-30T00:00:00+00:00' };
    mockApi({
      filings: {
        '216785710': [
          filing({ id: 'empty', formName: 'FPPC 460', filerName: name, filingDate: '2025-07-30T00:00:00+00:00', ...period }),
          filing({ id: 'full', formName: 'FPPC 460', filerName: name, filingDate: '2025-07-24T00:00:00+00:00', ...period }),
        ],
      },
      transactions: [tx({ id: 'r1', filingId: 'full', filerName: name }), tx({ id: 'r2', filingId: 'full', filerName: name })],
    });

    const got = await createNetfileAdapter(2026).fetch(source('216785710'));

    expect(got.records.map(r => r.id).sort()).toEqual(['r1', 'r2']);
  });

  // Same committee: a full-year 2023 report (filed 2024-01-24) repeats the 160 rows of the
  // 2023-01-01..06-30 report (filed 2023-07-27). Keeping both counts each gift twice.
  it('drops a report whose period a later report with rows contains', async () => {
    mockApi({
      idSearch: { '1417140': ['209512005'] },
      filings: {
        '209512005': [
          filing({ id: 'h1', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2023-07-27T00:00:00+00:00', periodStart: '2023-01-01T00:00:00+00:00', periodEnd: '2023-06-30T00:00:00+00:00' }),
          filing({ id: 'year', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2024-01-24T00:00:00+00:00', periodStart: '2023-01-01T00:00:00+00:00', periodEnd: '2023-12-31T00:00:00+00:00' }),
          filing({ id: 'next', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2024-07-24T00:00:00+00:00', periodStart: '2024-01-01T00:00:00+00:00', periodEnd: '2024-06-30T00:00:00+00:00' }),
        ],
      },
      transactions: [
        tx({ id: 'h1-a', filingId: 'h1', filerName: HENDERSON }),
        tx({ id: 'year-a', filingId: 'year', filerName: HENDERSON }),
        tx({ id: 'next-a', filingId: 'next', filerName: HENDERSON }),
      ],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(got.records.map(r => r.id).sort()).toEqual(['next-a', 'year-a']);
  });

  it('keeps both reports when their periods only partly overlap', async () => {
    mockApi({
      idSearch: { '1417140': ['209512005'] },
      filings: {
        '209512005': [
          filing({ id: 'a', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2024-02-01T00:00:00+00:00', periodStart: '2024-01-01T00:00:00+00:00', periodEnd: '2024-01-20T00:00:00+00:00' }),
          filing({ id: 'b', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2024-03-01T00:00:00+00:00', periodStart: '2024-01-20T00:00:00+00:00', periodEnd: '2024-02-17T00:00:00+00:00' }),
        ],
      },
      transactions: [tx({ id: 'a1', filingId: 'a', filerName: HENDERSON }), tx({ id: 'b1', filingId: 'b', filerName: HENDERSON })],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(got.records.map(r => r.id).sort()).toEqual(['a1', 'b1']);
  });

  it('reads every page when the search holds more rows than one page', async () => {
    const many = Array.from({ length: 10_050 }, (_, i) => tx({ id: `r${i}`, filingId: 'own', filerName: HENDERSON }));
    mockApi({
      idSearch: { '1417140': ['209512005'] },
      filings: { '209512005': [filing({ id: 'own', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2026-05-21T00:00:00Z' })] },
      transactions: many,
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(got.records).toHaveLength(10_050);
  });
});

describe('netfileAdapter fetch: an error is never an empty answer', () => {
  it('fails when the transaction search answers an HTTP error', async () => {
    mockApi({
      idSearch: { '1417140': ['209512005'] },
      filings: { '209512005': [filing({ id: 'own', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2026-05-21T00:00:00Z' })] },
      status: { SearchCampaignTransactions: 503 },
    });

    await expect(createNetfileAdapter(2026).fetch(source('1417140'))).rejects.toThrow(/503/);
  });

  it('fails when the filings list answers an HTTP error', async () => {
    mockApi({ idSearch: { '1417140': ['209512005'] }, status: { 'filings/byFiler': 429 } });

    await expect(createNetfileAdapter(2026).fetch(source('1417140'))).rejects.toThrow(/429/);
  });

  it('fails when the committee lookup answers an HTTP error', async () => {
    mockApi({ status: { IdSearch: 500 } });

    await expect(createNetfileAdapter(2026).fetch(source('1417140'))).rejects.toThrow(/500/);
  });

  it('fails when the page walk returns fewer distinct rows than the search counted', async () => {
    mockApi({
      idSearch: { '1417140': ['209512005'] },
      filings: { '209512005': [filing({ id: 'own', formName: 'FPPC 460', filerName: HENDERSON, filingDate: '2026-05-21T00:00:00Z' })] },
      transactions: [tx({ id: 'a', filingId: 'own', filerName: HENDERSON })],
      totalCountBump: 1,
    });

    await expect(createNetfileAdapter(2026).fetch(source('1417140'))).rejects.toThrow(/2 counted, 1 read/);
  });
});

describe('netfileAdapter normalize', () => {
  const ps = source('1417140');
  const raw = (records: ReturnType<typeof tx>[]) => ({
    records: records as unknown as Record<string, unknown>[], totalExpected: records.length, totalFetched: records.length,
  });

  it('keeps a negative Schedule A amount, as the Cal-Access adapter does', async () => {
    const norm = await createNetfileAdapter(2026).normalize(
      raw([tx({ id: 'neg', filingId: 'f', filerName: HENDERSON, amount: -250 })]), ps,
    );

    expect(norm.contributions.map(c => c.amount)).toEqual([-250]);
    expect(norm.skipped).toBe(0);
  });

  it('counts the other schedules as deliberate exclusions, not as defects', async () => {
    const norm = await createNetfileAdapter(2026).normalize(
      raw([
        tx({ id: 'a', filingId: 'f', filerName: HENDERSON, schedule: '460A' }),
        tx({ id: 'e', filingId: 'f', filerName: HENDERSON, schedule: '460E' }),
        tx({ id: 'l', filingId: 'f', filerName: HENDERSON, schedule: '497P1' }),
      ]), ps,
    );

    expect(norm.contributions).toHaveLength(1);
    expect(norm.excluded).toBe(2);
    expect(norm.skipped).toBe(0);
  });

  it('dates a contribution by its UTC calendar day and rounds the cycle up to an even year', async () => {
    const norm = await createNetfileAdapter(2026).normalize(
      raw([tx({ id: 'd', filingId: 'f', filerName: HENDERSON, date: '2025-12-31T08:00:00Z' })]), ps,
    );

    expect(norm.contributions[0].contribution_date?.toISOString().slice(0, 10)).toBe('2025-12-31');
    expect(norm.contributions[0].election_cycle).toBe('2026');
  });
});

describe('netfileAdapter upsert: replace, then prune', () => {
  function contribution(key: string): ContributionInsert {
    return {
      politician_source_id: 'src-1417140', donor_id: null, committee_id: null, amount: 100,
      contribution_date: new Date('2026-05-21T07:00:00Z'), election_cycle: '2026', confidence_level: 'HIGH',
      data_source: 'la_county_netfile', source_transaction_id: key, raw_record: {}, donor_name_normalized: 'DONOR DANA',
    };
  }

  it("deletes this source's rows that the current filings no longer carry", async () => {
    poolQueryMock.mockImplementation(async (sql: string) => {
      if (sql.includes('INSERT INTO')) return { rows: [{ inserted: true }, { inserted: true }] };
      return { rows: [], rowCount: 3 };
    });

    await createNetfileAdapter(2026).upsert({
      contributions: [contribution('f1-a'), contribution('f1-b')], skipped: 0, totalParsed: 2,
    });

    const prune = poolQueryMock.mock.calls.find(c => String(c[0]).includes('DELETE FROM'));
    expect(prune).toBeDefined();
    expect(String(prune![0])).toContain("m.data_source = 'la_county_netfile'");
    expect(prune![1]).toEqual(['src-1417140', ['f1-a', 'f1-b']]);
  });

  it('never prunes when nothing was read, so a source the API stops showing keeps its rows', async () => {
    await createNetfileAdapter(2026).upsert({ contributions: [], skipped: 0, totalParsed: 0 });

    expect(poolQueryMock).not.toHaveBeenCalled();
  });

  it('does not prune after a failed batch, because the keep-set is not all in the table', async () => {
    poolQueryMock.mockImplementation(async (sql: string) => {
      if (sql.includes('INSERT INTO')) throw new Error('boom');
      return { rows: [], rowCount: 0 };
    });

    const res = await createNetfileAdapter(2026).upsert({
      contributions: [contribution('f1-a')], skipped: 0, totalParsed: 1,
    });

    expect(res.errors).toBe(1);
    expect(poolQueryMock.mock.calls.some(c => String(c[0]).includes('DELETE FROM'))).toBe(false);
  });
});

describe('assertNetfileRunHealthy: the job fails loudly instead of reading as a quiet month', () => {
  it('passes a run that read rows and lost no source', () => {
    expect(() => assertNetfileRunHealthy({ sources: 184, failed: 0, fetched: 14_914 })).not.toThrow();
  });

  it('fails a run in which any source failed', () => {
    expect(() => assertNetfileRunHealthy({ sources: 184, failed: 2, fetched: 14_000 })).toThrow(/2 of 184/);
  });

  it('fails a run that read no row from any source', () => {
    expect(() => assertNetfileRunHealthy({ sources: 184, failed: 0, fetched: 0 })).toThrow(/0 rows from all 184/);
  });
});
