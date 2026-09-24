import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import AdmZip from 'adm-zip';
import iconv from 'iconv-lite';

// Mock the shared pool so importing indianaAdapter.ts (which reaches ../db.js at module
// scope) doesn't trigger env.ts's startup validation. Mirrors calAccessAdapter.test.ts.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

import { createIndianaAdapter, indianaYears, writeUnresolved } from './indianaAdapter.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

// ---------------------------------------------------------------------------
// Fixture: the header of the live export, checked 2026-09-23 for 2025 and 2026. The donor
// column is `Name`, the contribution type `Type`, the receiver `Received_By`.
// ---------------------------------------------------------------------------

const HEADER = [
  'FileNumber', 'CommitteeType', 'Committee', 'CandidateName', 'ContributorType', 'Name',
  'Address', 'City', 'State', 'Zip', 'Occupation', 'Type', 'Description', 'Amount',
  'ContributionDate', 'Received_By', 'Amended',
];

type Row = Partial<Record<(typeof HEADER)[number], string>>;

function row(r: Row): string[] {
  const base: Row = {
    CommitteeType: 'Candidate', Committee: 'Friends of Someone', CandidateName: 'Some One',
    ContributorType: 'Individual', Name: 'Donor, Dana', Address: '1 Main St', City: 'Bloomington',
    State: 'IN', Zip: '47401', Occupation: '', Type: 'Direct', Description: '', Amount: '100.0000',
    ContributionDate: '2025-11-18 00:00:00', Received_By: 'Treasurer', Amended: '0',
  };
  const merged = { ...base, ...r };
  return HEADER.map(c => merged[c] ?? '');
}

function csvBuffer(header: string[], rows: string[][]): Buffer {
  const quote = (v: string) => `"${v}"`;
  const text = [header, ...rows].map(r => r.map(quote).join(',')).join('\r\n') + '\r\n';
  return iconv.encode(text, 'win1252');
}

function zipFor(year: number, rows: string[][], header = HEADER): Buffer {
  const zip = new AdmZip();
  zip.addFile(`${year}_ContributionData.csv`, csvBuffer(header, rows));
  return zip.toBuffer();
}

function source(externalId: string, id = `src-${externalId}`): PoliticianSource {
  return { id, external_id: externalId } as unknown as PoliticianSource;
}

interface SourceRow { id: string; external_id: string; research_status: string }

/** Answers the adapter's two queries: the politician_sources read, and ETag saves. */
function mockDb(sources: SourceRow[]): void {
  poolQueryMock.mockImplementation(async (sql: string) => {
    if (sql.includes('FROM transparent_motivations.politician_sources')) return { rows: sources };
    return { rows: [] };
  });
}

/** Serves one ZIP per year; a year with no entry answers 404, like an unpublished year. */
function mockFetch(byYear: Record<number, Buffer>): ReturnType<typeof vi.fn> {
  const fetchMock = vi.fn(async (url: string) => {
    const year = Number(/(\d{4})_ContributionData/.exec(url)?.[1]);
    const body = byYear[year];
    if (!body) return new Response('not found', { status: 404 });
    return new Response(new Uint8Array(body), { status: 200, headers: { ETag: `"etag-${year}"` } });
  });
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

beforeEach(() => {
  poolQueryMock.mockReset();
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('indianaYears', () => {
  it('reads the previous calendar year and the current one', () => {
    expect(indianaYears(new Date('2026-09-24T12:00:00Z'))).toEqual([2025, 2026]);
    // January: the annual report for the year just ended lands in last year's file.
    expect(indianaYears(new Date('2027-01-15T12:00:00Z'))).toEqual([2026, 2027]);
  });
});

describe('indianaAdapter parse: what the live export holds', () => {
  it('reads the donor from the Name column, decoded from Windows-1252', async () => {
    mockDb([{ id: 'src-7771', external_id: '7771', research_status: 'confirmed' }]);
    mockFetch({ 2025: zipFor(2025, [row({ FileNumber: '7771', Name: 'Pérez, Ana' })]) });

    const adapter = createIndianaAdapter([2025]);
    await adapter.preDownload();
    const ps = source('7771');
    const norm = await adapter.normalize(await adapter.fetch(ps), ps);

    expect(norm.contributions).toHaveLength(1);
    const c = norm.contributions[0];
    expect(c.raw_record.ContributorName).toBe('Pérez, Ana');
    expect(c.raw_record.ContributionType).toBe('Direct');
    expect(c.raw_record.ReceivedBy).toBe('Treasurer');
    expect(c.donor_name_normalized).not.toBe('anonymous');
    expect(c.source_transaction_id).toBe('7771|2025-11-18|Pérez, Ana|100.00');
  });

  it('keeps two donors who gave the same amount on the same day', async () => {
    mockDb([{ id: 'src-6289', external_id: '6289', research_status: 'confirmed' }]);
    mockFetch({
      2025: zipFor(2025, [
        row({ FileNumber: '6289', Name: 'Able, Ann', Amount: '250.0000' }),
        row({ FileNumber: '6289', Name: 'Baker, Bo', Amount: '250.0000' }),
      ]),
    });

    const adapter = createIndianaAdapter([2025]);
    await adapter.preDownload();
    const ps = source('6289');
    const norm = await adapter.normalize(await adapter.fetch(ps), ps);

    expect(norm.contributions.map(c => c.source_transaction_id)).toEqual([
      '6289|2025-11-18|Able, Ann|250.00',
      '6289|2025-11-18|Baker, Bo|250.00',
    ]);
  });

  it("keeps a donor's repeated identical gift as a second row", async () => {
    mockDb([{ id: 'src-6289', external_id: '6289', research_status: 'confirmed' }]);
    mockFetch({
      2025: zipFor(2025, [
        row({ FileNumber: '6289', Name: 'Able, Ann', Amount: '10.0000' }),
        row({ FileNumber: '6289', Name: 'Able, Ann', Amount: '10.0000' }),
      ]),
    });

    const adapter = createIndianaAdapter([2025]);
    await adapter.preDownload();
    const ps = source('6289');
    const norm = await adapter.normalize(await adapter.fetch(ps), ps);

    // The first keeps the plain key, so rows already stored under it are not re-keyed.
    expect(norm.contributions.map(c => c.source_transaction_id)).toEqual([
      '6289|2025-11-18|Able, Ann|10.00',
      '6289|2025-11-18|Able, Ann|10.00|#2',
    ]);
  });

  it('rejects an export whose header lacks the donor column', async () => {
    mockDb([{ id: 'src-1', external_id: '1', research_status: 'confirmed' }]);
    const header = HEADER.filter(c => c !== 'Name');
    mockFetch({ 2025: zipFor(2025, [row({ FileNumber: '1' }).filter((_, i) => HEADER[i] !== 'Name')], header) });

    const adapter = createIndianaAdapter([2025]);
    await expect(adapter.preDownload()).rejects.toThrow(/Name/);
  });
});

describe('indianaAdapter preDownload: every year, every run', () => {
  it('reads every requested year for the same committee', async () => {
    mockDb([{ id: 'src-7788', external_id: '7788', research_status: 'confirmed' }]);
    mockFetch({
      2025: zipFor(2025, [row({ FileNumber: '7788', ContributionDate: '2025-06-01 00:00:00' })]),
      2026: zipFor(2026, [row({ FileNumber: '7788', ContributionDate: '2026-02-01 00:00:00' })]),
    });

    const adapter = createIndianaAdapter([2025, 2026]);
    await adapter.preDownload();
    const ps = source('7788');
    const norm = await adapter.normalize(await adapter.fetch(ps), ps);

    expect(norm.contributions.map(c => c.contribution_date?.toISOString().slice(0, 10))).toEqual([
      '2025-06-01',
      '2026-02-01',
    ]);
    // Both files fall in the 2026 cycle.
    expect(new Set(norm.contributions.map(c => c.election_cycle))).toEqual(new Set(['2026']));
  });

  it('never sends a conditional request, so an unchanged file still yields its rows', async () => {
    mockDb([{ id: 'src-4676', external_id: '4676', research_status: 'confirmed' }]);
    const fetchMock = mockFetch({ 2026: zipFor(2026, [row({ FileNumber: '4676' })]) });

    // Two runs in a row: the second is the one a stored ETag used to turn into a 304.
    for (let run = 0; run < 2; run++) {
      const adapter = createIndianaAdapter([2026]);
      await adapter.preDownload();
      const got = await adapter.fetch(source('4676'));
      expect(got.records).toHaveLength(1);
    }

    for (const call of fetchMock.mock.calls) {
      const init = (call as unknown[])[1] as RequestInit | undefined;
      const headers = new Headers(init?.headers);
      expect(headers.has('If-None-Match')).toBe(false);
    }
  });

  it('treats a year the state has not published (404) as empty', async () => {
    mockDb([{ id: 'src-7771', external_id: '7771', research_status: 'confirmed' }]);
    mockFetch({ 2026: zipFor(2026, [row({ FileNumber: '7771' })]) });

    const adapter = createIndianaAdapter([2026, 2027]);
    await adapter.preDownload();
    expect((await adapter.fetch(source('7771'))).records).toHaveLength(1);
  });

  it('fails when no requested year exists at all', async () => {
    mockDb([{ id: 'src-7771', external_id: '7771', research_status: 'confirmed' }]);
    mockFetch({});

    const adapter = createIndianaAdapter([2026, 2027]);
    await expect(adapter.preDownload()).rejects.toThrow(/no bulk file/i);
  });

  it('queues rows of needs_research committees only, never not_applicable ones', async () => {
    mockDb([
      { id: 'src-1', external_id: '1', research_status: 'confirmed' },
      { id: 'src-2', external_id: '2', research_status: 'needs_research' },
      { id: 'src-3', external_id: '3', research_status: 'not_applicable' },
    ]);
    mockFetch({
      2025: zipFor(2025, [row({ FileNumber: '1' }), row({ FileNumber: '2' }), row({ FileNumber: '3' })]),
    });

    const adapter = createIndianaAdapter([2025]);
    await adapter.preDownload();

    expect(adapter.getUnmatchedRows().map(r => r.fileNumber)).toEqual(['2']);
    expect((await adapter.fetch(source('1'))).records).toHaveLength(1);
    expect((await adapter.fetch(source('3'))).records).toHaveLength(0);
  });
});

describe('writeUnresolved', () => {
  it('skips a row already queued under the same transaction key', async () => {
    mockDb([{ id: 'src-2', external_id: '2', research_status: 'needs_research' }]);
    mockFetch({ 2025: zipFor(2025, [row({ FileNumber: '2', Name: 'Able, Ann' })]) });
    const adapter = createIndianaAdapter([2025]);
    await adapter.preDownload();

    poolQueryMock.mockReset();
    poolQueryMock.mockResolvedValue({ rows: [] });
    await writeUnresolved(adapter.getUnmatchedRows(), 42);

    const [sql, params] = poolQueryMock.mock.calls[0] as [string, unknown[]];
    expect(sql).toMatch(/NOT EXISTS/);
    expect(sql).toMatch(/SourceTransactionId/);
    const raw = JSON.parse(params[2] as string);
    expect(raw.SourceTransactionId).toBe('2|2025-11-18|Able, Ann|100.00');
  });
});
