import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Mock the shared pool so importing netfileAdapter.ts (which reaches ../db.js at module
// scope) doesn't trigger env.ts's startup validation. Mirrors indianaAdapter.test.ts.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

import {
  createNetfileAdapter,
  assertNetfileRunHealthy,
  dropRepeatedReports,
  queryWords,
  type Connect2Transaction,
} from './netfileAdapter.js';
import type { PoliticianSource } from '../campaignFinanceService.js';
import type { ContributionInsert } from './adapterInterface.js';

// ---------------------------------------------------------------------------
// Fixtures: the shapes NetFile's Connect2 public API returned on 2026-11-12.
//
// FPPC id 1417140 is Henderson's committee, NetFile local id LACO-112501. Its rows carry the committee name as it
// was when each report was filed, so its 2024 reports read "... Board 2024" while the filer list says "... 2028".
// ---------------------------------------------------------------------------

const LACO = 625;
const WEHO = 197;

interface Filer {
  fppcId: string;
  localAgencyId: string;
  name: string;
}

function tx(t: Partial<Connect2Transaction> & { id: string; filingId: string; filerName: string }): Connect2Transaction {
  return {
    agency: LACO, filerFppcId: '1417140', filerLocalId: 'LACO-112501', date: '2026-05-21T00:00:00.0000000-07:00',
    amount: 100, transactionType: 0, name: 'Dana Donor', occupation: '', employer: '', line1: '', line2: '',
    city: 'Los Angeles', state: 'CA', zip: '90067', ...t,
  };
}

interface Api {
  /** Agency code → its committees, as campaign/list/filer answers. */
  filers?: Record<string, Filer[]>;
  /** Every transaction the search can return; a query matches when every word is in the filer or donor name. */
  transactions?: Connect2Transaction[];
  /** Words the profanity filter refuses (HTTP 400 ProfaneSearchException). */
  profane?: string[];
  /** Force a status for a path fragment, e.g. { 'transaction/query': 503 }. */
  status?: Record<string, number>;
  /** Override totalMatchingCount on full searches, to model a short page walk. */
  totalCountBump?: number;
}

/** Serves the two Connect2 endpoints the adapter reads, from in-memory fixtures. */
function mockApi(api: Api): ReturnType<typeof vi.fn> {
  const fetchMock = vi.fn(async (input: string) => {
    const url = new URL(input);
    const path = url.pathname;
    for (const [fragment, status] of Object.entries(api.status ?? {})) {
      if (path.includes(fragment)) return new Response('{}', { status });
    }
    const json = (body: unknown) => new Response(JSON.stringify(body), { status: 200 });

    if (path.endsWith('/campaign/list/filer')) {
      const all = (api.filers?.[url.searchParams.get('AID') ?? ''] ?? []).map((f, i) => ({
        id: `guid-${i}`, agency: url.searchParams.get('AID'), application: 'Campaign', ...f,
      }));
      const size = Number(url.searchParams.get('pageSize'));
      const page = Number(url.searchParams.get('currentPageIndex'));
      return json({ totalMatchingCount: all.length, filers: all.slice(page * size, (page + 1) * size) });
    }
    if (path.endsWith('/campaign/search/transaction/query')) {
      const query = url.searchParams.get('QueryString') ?? '';
      const words = query.toLowerCase().split(/\s+/).filter(Boolean);
      if (words.some(w => (api.profane ?? []).includes(w))) {
        return new Response('{"responseStatus":{"errorCode":"ProfaneSearchException"}}', { status: 400 });
      }
      const agency = Number(url.searchParams.get('Agency'));
      const hits = (api.transactions ?? []).filter(t => {
        const hay = `${t.filerName} ${t.name}`.toLowerCase();
        return t.agency === agency && words.every(w => hay.split(/[^a-z0-9]+/).includes(w));
      });
      const size = Number(url.searchParams.get('pageSize'));
      const page = Number(url.searchParams.get('currentPageIndex'));
      const bump = size > 1 ? api.totalCountBump ?? 0 : 0;
      return json({
        totalMatchingCount: hits.length + bump,
        totalMatchingPages: Math.max(1, Math.ceil(hits.length / size)),
        results: hits.slice(page * size, (page + 1) * size),
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
const HENDERSON_2024 = 'Henderson for College Board 2024';
const HENDERSON_FILER: Filer = { fppcId: '1417140', localAgencyId: 'LACO-112501', name: HENDERSON };

const ids = (records: Record<string, unknown>[]) => records.map(r => r.id).sort();

beforeEach(() => {
  poolQueryMock.mockReset();
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('netfileAdapter fetch: finding the committee', () => {
  it("reads an FPPC id's committee by its NetFile local id, which also covers reports filed while the FPPC id was Pending", async () => {
    mockApi({
      filers: { LACO: [HENDERSON_FILER] },
      transactions: [
        tx({ id: 'with-fppc', filingId: '2', filerName: HENDERSON }),
        tx({ id: 'pending', filingId: '1', filerName: HENDERSON, filerFppcId: 'Pending', name: 'Early Donor' }),
      ],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(ids(got.records)).toEqual(['pending', 'with-fppc']);
  });

  it('reads a link that stores the NetFile local id itself (CA_0375)', async () => {
    const luna = 'LA County: Luna for Sheriff 2026';
    mockApi({
      filers: { LACO: [{ fppcId: '1479270', localAgencyId: 'LACO-113718', name: luna }] },
      transactions: [tx({ id: 'l1', filingId: '9', filerName: luna, filerFppcId: '1479270', filerLocalId: 'LACO-113718' })],
    });

    const got = await createNetfileAdapter(2026).fetch(source('LACO-113718'));

    expect(ids(got.records)).toEqual(['l1']);
  });

  it("fails a link that still stores the retired REST API's 9-digit filer id, rather than reading nothing", async () => {
    mockApi({ filers: { LACO: [HENDERSON_FILER] } });

    await expect(createNetfileAdapter(2026).fetch(source('216785710'))).rejects.toThrow(/retired REST API.*CA_0375/);
  });

  it('returns no rows, without failing, when the agency lists no committee for the id', async () => {
    mockApi({ filers: { LACO: [HENDERSON_FILER] } });

    const got = await createNetfileAdapter(2026).fetch(source('1450349'));

    expect(got.records).toEqual([]);
  });

  it('reads the filer list once per run, however many links share the agency', async () => {
    const fetchMock = mockApi({ filers: { LACO: [HENDERSON_FILER] } });
    const adapter = createNetfileAdapter(2026);

    await adapter.fetch(source('1450349'));
    await adapter.fetch(source('1450350'));

    expect(fetchMock.mock.calls.filter(c => String(c[0]).includes('/campaign/list/filer'))).toHaveLength(1);
  });

  it('reads every page of a filer list longer than one page', async () => {
    const many: Filer[] = Array.from({ length: 1_500 }, (_, i) => ({ fppcId: String(2_000_000 + i), localAgencyId: `LACO-${i}`, name: `Committee ${i}` }));
    mockApi({ filers: { LACO: [...many, HENDERSON_FILER] }, transactions: [tx({ id: 'h', filingId: '1', filerName: HENDERSON })] });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(ids(got.records)).toEqual(['h']);
  });
});

describe('netfileAdapter fetch: the agency comes from the link', () => {
  const byers = 'Chelsea Byers for West Hollywood City Council 2022';
  const weho: Api = {
    filers: { WEHO: [{ fppcId: '1443689', localAgencyId: 'WEHO-112739', name: byers }] },
    transactions: [tx({ id: 'b1', filingId: '5', filerName: byers, agency: WEHO, filerFppcId: '1443689', filerLocalId: 'WEHO-112739' })],
  };

  it("searches under the link's own agency number", async () => {
    const fetchMock = mockApi(weho);

    const got = await createNetfileAdapter(2026).fetch(source('WEHO-112739', 'src-byers', 'WEHO'));

    expect(ids(got.records)).toEqual(['b1']);
    const searched = fetchMock.mock.calls
      .map(c => new URL(String(c[0])))
      .filter(u => u.pathname.endsWith('/transaction/query'))
      .map(u => u.searchParams.get('Agency'));
    expect(new Set(searched)).toEqual(new Set([String(WEHO)]));
  });

  it('fails a link that names no agency, rather than guessing LA County', async () => {
    const fetchMock = mockApi(weho);

    await expect(createNetfileAdapter(2026).fetch(source('WEHO-112739', 'src-byers', null))).rejects.toThrow(
      /no netfile_agency/
    );
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('fails a link whose agency has no Connect2 number, rather than searching every agency', async () => {
    const fetchMock = mockApi(weho);

    await expect(createNetfileAdapter(2026).fetch(source('1443689', 'src-x', 'SMCO'))).rejects.toThrow(/AGENCY_NUMBERS/);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

describe('netfileAdapter fetch: reading the transactions', () => {
  it('finds the reports filed under an older committee name through its rarest word', async () => {
    mockApi({
      filers: { LACO: [HENDERSON_FILER] },
      transactions: [
        tx({ id: 'old', filingId: '1', filerName: HENDERSON_2024, name: 'Early Donor' }),
        tx({ id: 'new', filingId: '2', filerName: HENDERSON }),
        // Many rows share the common words, so "Henderson" is the rarest.
        ...Array.from({ length: 5 }, (_, i) => tx({ id: `x${i}`, filingId: '7', filerName: 'Rivera for LA Community College Board', filerFppcId: '9', filerLocalId: 'LACO-9' })),
      ],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(ids(got.records)).toEqual(['new', 'old']);
  });

  it("keeps only the committee's own rows, never a row on which it is the donor", async () => {
    mockApi({
      filers: { LACO: [HENDERSON_FILER] },
      transactions: [
        tx({ id: 'own', filingId: '1', filerName: HENDERSON }),
        tx({ id: 'as-donor', filingId: '8', filerName: 'Other Committee', name: HENDERSON, filerFppcId: '1400000', filerLocalId: 'LACO-1' }),
      ],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(ids(got.records)).toEqual(['own']);
  });

  it('drops a word the profanity filter refuses instead of failing the search', async () => {
    const prang = 'LA County: Jeffrey Prang for Assessor 2026';
    mockApi({
      filers: { LACO: [{ fppcId: '1477771', localAgencyId: 'LACO-113732', name: prang }] },
      transactions: [tx({ id: 'p1', filingId: '3', filerName: prang, filerFppcId: '1477771', filerLocalId: 'LACO-113732' })],
      profane: ['assessor'],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1477771'));

    expect(ids(got.records)).toEqual(['p1']);
  });

  it("drops a report whose Schedule A rows all reappear on a later report (a consolidated report)", async () => {
    const day = (d: string) => `${d}T00:00:00.0000000-07:00`;
    mockApi({
      filers: { LACO: [HENDERSON_FILER] },
      transactions: [
        tx({ id: 'h1-a', filingId: '100', filerName: HENDERSON, date: day('2023-03-01'), amount: 500, name: 'Ann' }),
        tx({ id: 'h1-e', filingId: '100', filerName: HENDERSON, transactionType: 6, name: 'Printer' }),
        tx({ id: 'fy-a', filingId: '200', filerName: HENDERSON, date: day('2023-03-01'), amount: 500, name: 'Ann' }),
        tx({ id: 'fy-b', filingId: '200', filerName: HENDERSON, date: day('2023-09-01'), amount: 250, name: 'Bo' }),
      ],
    });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(ids(got.records)).toEqual(['fy-a', 'fy-b']);
  });

  it('reads every page when the search holds more rows than one page', async () => {
    const many = Array.from({ length: 5_050 }, (_, i) => tx({ id: `r${i}`, filingId: '1', filerName: HENDERSON, amount: i }));
    mockApi({ filers: { LACO: [HENDERSON_FILER] }, transactions: many });

    const got = await createNetfileAdapter(2026).fetch(source('1417140'));

    expect(got.records).toHaveLength(5_050);
  });
});

describe('dropRepeatedReports', () => {
  const row = (id: string, filingId: string, name: string, amount = 100) =>
    tx({ id, filingId, filerName: HENDERSON, name, amount });

  it('keeps both reports when the later one repeats only some of the earlier rows', () => {
    const rows = [row('a1', '1', 'Ann'), row('a2', '1', 'Bo'), row('b1', '2', 'Ann')];

    expect(dropRepeatedReports(rows).map(r => r.id)).toEqual(['a1', 'a2', 'b1']);
  });

  it('counts repeats with multiplicity: two equal gifts are not covered by one', () => {
    const rows = [row('a1', '1', 'Ann'), row('a2', '1', 'Ann'), row('b1', '2', 'Ann')];

    expect(dropRepeatedReports(rows).map(r => r.id)).toEqual(['a1', 'a2', 'b1']);
  });

  it('never drops the later report, even when the earlier one repeats it in full', () => {
    const rows = [row('a1', '1', 'Ann'), row('b1', '2', 'Ann')];

    expect(dropRepeatedReports(rows).map(r => r.id)).toEqual(['b1']);
  });
});

describe('queryWords', () => {
  it('keeps letters only: a year, a colon or a comma would narrow or break the search', () => {
    expect(queryWords('LA County: Luna for Sheriff 2026')).toEqual(['LA', 'County', 'Luna', 'for', 'Sheriff']);
    expect(queryWords('Tina Fredericks for PUSD Board Member, 2028')).toEqual(['Tina', 'Fredericks', 'for', 'PUSD', 'Board', 'Member']);
  });
});

describe('netfileAdapter fetch: an error is never an empty answer', () => {
  it('fails when the transaction search answers an HTTP error', async () => {
    mockApi({ filers: { LACO: [HENDERSON_FILER] }, status: { 'transaction/query': 503 } });

    await expect(createNetfileAdapter(2026).fetch(source('1417140'))).rejects.toThrow(/503/);
  });

  it('fails when the filer list answers an HTTP error — the 2026-11-01 run met a 401', async () => {
    mockApi({ status: { 'list/filer': 401 } });

    await expect(createNetfileAdapter(2026).fetch(source('1417140'))).rejects.toThrow(/401/);
  });

  it('fails when the page walk returns fewer distinct rows than the search counted', async () => {
    mockApi({
      filers: { LACO: [HENDERSON_FILER] },
      transactions: [tx({ id: 'a', filingId: '1', filerName: HENDERSON })],
      totalCountBump: 1,
    });

    await expect(createNetfileAdapter(2026).fetch(source('1417140'))).rejects.toThrow(/2 counted, 1 read/);
  });
});

describe('netfileAdapter normalize', () => {
  const ps = source('1417140');
  const raw = (records: Connect2Transaction[]) => ({
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
        tx({ id: 'a', filingId: 'f', filerName: HENDERSON, transactionType: 0 }),
        tx({ id: 'e', filingId: 'f', filerName: HENDERSON, transactionType: 6 }),
        tx({ id: 'l', filingId: 'f', filerName: HENDERSON, transactionType: 20 }),
      ]), ps,
    );

    expect(norm.contributions).toHaveLength(1);
    expect(norm.excluded).toBe(2);
    expect(norm.skipped).toBe(0);
  });

  it('reads the local-midnight date as the same instant the REST API gave, and rounds the cycle up', async () => {
    const norm = await createNetfileAdapter(2026).normalize(
      raw([tx({ id: 'd', filingId: 'f', filerName: HENDERSON, date: '2025-07-01T00:00:00.0000000-07:00' })]), ps,
    );

    expect(norm.contributions[0].contribution_date?.toISOString()).toBe('2025-07-01T07:00:00.000Z');
    expect(norm.contributions[0].election_cycle).toBe('2026');
  });

  it('keys a row by filing id and transaction id, as every row stored before 2026-11 is keyed', async () => {
    const norm = await createNetfileAdapter(2026).normalize(
      raw([tx({ id: '1a38e7a2-bdaa-4a23-8f2e-b4cf012d6f66', filingId: '217500560', filerName: HENDERSON, employer: 'LAUSD', occupation: 'Teacher', line1: '1 Main St' })]), ps,
    );

    const c = norm.contributions[0];
    expect(c.source_transaction_id).toBe('217500560-1a38e7a2-bdaa-4a23-8f2e-b4cf012d6f66');
    expect(c.raw_record).toMatchObject({
      schedule: '460A', contributor_name: 'Dana Donor', contributor_employer: 'LAUSD',
      contributor_occupation: 'Teacher', contributor_address: '1 Main St, Los Angeles, CA 90067',
    });
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
