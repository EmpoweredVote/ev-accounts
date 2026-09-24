import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import AdmZip from 'adm-zip';
import iconv from 'iconv-lite';

// Mock the shared pool so importing calAccessAdapter.ts (which reaches ../db.js at module
// scope) doesn't trigger env.ts's startup validation. Mirrors ocpfAdapter.test.ts.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

import {
  createCalAccessAdapter,
  indexFilings,
  parseReceipts,
  readBody,
} from './calAccessAdapter.js';
import type { PoliticianSource } from '../campaignFinanceService.js';
import type { ContributionInsert } from './adapterInterface.js';

// ---------------------------------------------------------------------------
// Fixture: a tiny Cal-Access export with the two tables the adapter reads.
// Column order follows the real 2026-09-23 export headers (trimmed to what matters).
// ---------------------------------------------------------------------------

const FILER_FILINGS_HEADER = ['FILER_ID', 'FILING_ID', 'PERIOD_ID', 'FORM_ID', 'FILING_SEQUENCE'];
const RCPT_HEADER = [
  'FILING_ID', 'AMEND_ID', 'LINE_ITEM', 'REC_TYPE', 'FORM_TYPE', 'TRAN_ID', 'ENTITY_CD',
  'CTRIB_NAML', 'CTRIB_NAMF', 'CTRIB_EMP', 'CTRIB_OCC', 'RCPT_DATE', 'AMOUNT', 'CMTE_ID',
];

type Rcpt = Partial<Record<(typeof RCPT_HEADER)[number], string>>;

function rcpt(r: Rcpt): string[] {
  const base: Rcpt = {
    AMEND_ID: '0', LINE_ITEM: '1', REC_TYPE: 'RCPT', FORM_TYPE: 'A', TRAN_ID: 't',
    ENTITY_CD: 'IND', CTRIB_NAML: 'Donor', CTRIB_NAMF: 'Dana', CTRIB_EMP: '', CTRIB_OCC: '',
    RCPT_DATE: '3/12/2019 12:00:00 AM', AMOUNT: '100', CMTE_ID: '',
  };
  const row = { ...base, ...r };
  return RCPT_HEADER.map(c => row[c] ?? '');
}

function tsv(header: string[], rows: string[][]): Buffer {
  const text = [header, ...rows].map(r => r.join('\t')).join('\r\n') + '\r\n';
  return iconv.encode(text, 'win1252');
}

// Filer 100 is a target. Filer 999 is someone else, who received money FROM filer 100's
// committee (the row the old CMTE_ID filter used to attribute to 100).
const FILINGS: string[][] = [
  ['100', 'F1', '', 'F460', '0'],
  ['100', 'F2', '', 'F460', '0'],
  ['100', 'F2', '', 'F460', '1'], // F2 was amended once
  ['200', 'F3', '', 'F460', '0'],
  ['999', 'F9', '', 'F460', '0'],
];

const RECEIPTS: string[][] = [
  rcpt({ FILING_ID: 'F1', LINE_ITEM: '1', CTRIB_NAML: 'Pérez', AMOUNT: '250' }),
  rcpt({ FILING_ID: 'F1', LINE_ITEM: '2', FORM_TYPE: 'C', ENTITY_CD: 'COM', CTRIB_NAML: 'Some PAC', CMTE_ID: '555', AMOUNT: '40' }),
  rcpt({ FILING_ID: 'F1', LINE_ITEM: '3', FORM_TYPE: 'I', CTRIB_NAML: 'Bank interest', AMOUNT: '3' }),
  rcpt({ FILING_ID: 'F1', LINE_ITEM: '4', AMOUNT: 'abc' }),
  rcpt({ FILING_ID: 'F2', AMEND_ID: '0', LINE_ITEM: '1', AMOUNT: '500' }),
  rcpt({ FILING_ID: 'F2', AMEND_ID: '1', LINE_ITEM: '1', AMOUNT: '600' }),
  rcpt({ FILING_ID: 'F3', LINE_ITEM: '1', AMOUNT: '70' }),
  // Filer 100's committee GAVE this to filer 999. It is not a contribution to 100.
  rcpt({ FILING_ID: 'F9', LINE_ITEM: '1', ENTITY_CD: 'COM', CTRIB_NAML: 'Friends of 100', CMTE_ID: '100', AMOUNT: '9999' }),
];

function buildZip(): Buffer {
  const zip = new AdmZip();
  zip.addFile('CalAccess/DATA/FILER_FILINGS_CD.TSV', tsv(FILER_FILINGS_HEADER, FILINGS));
  zip.addFile('CalAccess/DATA/RCPT_CD.TSV', tsv(RCPT_HEADER, RECEIPTS));
  return zip.toBuffer();
}

function source(externalId: string, id = `src-${externalId}`): PoliticianSource {
  return { id, external_id: externalId } as unknown as PoliticianSource;
}

function zipResponse(body: Buffer, etag = '"etag-1"'): Response {
  return new Response(new Uint8Array(body), {
    status: 200,
    headers: { 'content-length': String(body.length), ETag: etag },
  });
}

// ---------------------------------------------------------------------------

describe('calAccessAdapter parse: who received the money', () => {
  it('attributes a receipt to the filer of its FILING, not to CMTE_ID', async () => {
    const zip = new AdmZip(buildZip());
    const filings = await indexFilings(zip, new Set(['100']));
    const parse = await parseReceipts(zip, filings);

    const rows = parse.rowsByFiler.get('100') ?? [];
    // F1 A + F1 C + F2 (latest amendment only). Never the F9 row filer 100's committee gave.
    expect(rows.map(r => `${r.filingID}_${r.amendID}_${r.lineItem}`).sort())
      .toEqual(['F1_0_1', 'F1_0_2', 'F2_1_1']);
    expect(rows.some(r => r.filingID === 'F9')).toBe(false);
    expect(parse.rowsByFiler.has('999')).toBe(false);
    expect(parse.rowsByFiler.has('200')).toBe(false);
  });

  it('keeps only the latest amendment of a filing', async () => {
    const zip = new AdmZip(buildZip());
    const parse = await parseReceipts(zip, await indexFilings(zip, new Set(['100'])));
    const f2 = (parse.rowsByFiler.get('100') ?? []).filter(r => r.filingID === 'F2');
    expect(f2).toHaveLength(1);
    expect(f2[0].amendID).toBe(1);
    expect(f2[0].amount).toBe(600);
  });

  it('counts other schedules and superseded amendments as excluded, bad values as skipped', async () => {
    const zip = new AdmZip(buildZip());
    const parse = await parseReceipts(zip, await indexFilings(zip, new Set(['100'])));
    // Schedule I row + the F2 amendment-0 row.
    expect(parse.excludedByFiler.get('100')).toBe(2);
    // AMOUNT 'abc'.
    expect(parse.skippedByFiler.get('100')).toBe(1);
    expect(parse.totalParsed).toBe(RECEIPTS.length);
  });

  it('decodes Windows-1252 and keeps the contributor committee id', async () => {
    const zip = new AdmZip(buildZip());
    const parse = await parseReceipts(zip, await indexFilings(zip, new Set(['100'])));
    const rows = parse.rowsByFiler.get('100') ?? [];
    expect(rows.find(r => r.lineItem === 1 && r.filingID === 'F1')?.ctribNameL).toBe('Pérez');
    const pac = rows.find(r => r.formType === 'C');
    expect(pac?.CMTE_ID).toBe('555');
    expect(pac?.entityCd).toBe('COM');
    expect(pac?.filerID).toBe('100');
  });

  it('rejects an export whose RCPT_CD header lacks a required column', async () => {
    const zip = new AdmZip();
    zip.addFile('CalAccess/DATA/FILER_FILINGS_CD.TSV', tsv(FILER_FILINGS_HEADER, FILINGS));
    zip.addFile('CalAccess/DATA/RCPT_CD.TSV', tsv(RCPT_HEADER.filter(c => c !== 'FILING_ID'), []));
    const filings = await indexFilings(zip, new Set(['100']));
    await expect(parseReceipts(zip, filings)).rejects.toThrow(/required column "FILING_ID"/);
  });
});

describe('calAccessAdapter prepare(): one download, one parse per run', () => {
  let fetchMock: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    poolQueryMock.mockReset();
    // loadStoredETag: no stored ETag.
    poolQueryMock.mockResolvedValue({ rows: [], rowCount: 0 });
    fetchMock = vi.fn(async () => zipResponse(buildZip()));
    vi.stubGlobal('fetch', fetchMock);
  });
  afterEach(() => vi.unstubAllGlobals());

  it('serves every prepared filer from one download', async () => {
    const adapter = createCalAccessAdapter();
    await adapter.prepare(['100', '200']);

    const a = await adapter.fetch(source('100'));
    const b = await adapter.fetch(source('200'));
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(a.records).toHaveLength(3);
    expect(b.records).toHaveLength(1);
    expect(a.records.every(r => r['FILER_ID'] === '100')).toBe(true);
  });

  it('refuses a filer that was not prepared once the ZIP is released', async () => {
    const adapter = createCalAccessAdapter();
    await adapter.prepare(['100']);
    await expect(adapter.fetch(source('200'))).rejects.toThrow(/was not in prepare\(\)/);
  });

  it('still works without prepare() for a single-filer caller', async () => {
    const adapter = createCalAccessAdapter();
    const res = await adapter.fetch(source('200'));
    expect(res.records).toHaveLength(1);
  });

  it('normalizes to FILING_AMEND_LINE ids and reports excluded and skipped rows', async () => {
    const adapter = createCalAccessAdapter();
    await adapter.prepare(['100']);
    const ps = source('100');
    const norm = await adapter.normalize(await adapter.fetch(ps), ps);
    expect(norm.contributions.map(c => c.source_transaction_id).sort()).toEqual(['F1_0_1', 'F1_0_2', 'F2_1_1']);
    expect(norm.contributions.every(c => c.election_cycle === '2020')).toBe(true); // 2019 rounds up
    expect(norm.excluded).toBe(2);
    expect(norm.skipped).toBe(1);
    expect(norm.totalParsed).toBe(6);
  });

  it('on 304 parses nothing and fetch returns no records', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ notes: '"etag-1"' }], rowCount: 1 });
    fetchMock.mockImplementation(async () => new Response(null, { status: 304 }));
    const adapter = createCalAccessAdapter();
    await adapter.prepare(['100']);
    expect(adapter.zipWasSkipped()).toBe(true);
    const res = await adapter.fetch(source('100'));
    expect(res.records).toHaveLength(0);
    const init = fetchMock.mock.calls[0][1] as RequestInit;
    expect((init.headers as Record<string, string>)['If-None-Match']).toBe('"etag-1"');
  });

  it('conditional: false ignores the stored ETag and always downloads', async () => {
    // The scheduled run has stored the current ETag. A conditional GET would be a 304 and
    // fetch() would return nothing without an error.
    poolQueryMock.mockResolvedValue({ rows: [{ notes: '"etag-1"' }], rowCount: 1 });
    fetchMock.mockImplementation(async (_url: string, init: RequestInit) =>
      (init.headers as Record<string, string>)['If-None-Match']
        ? new Response(null, { status: 304 })
        : zipResponse(buildZip()));
    const adapter = createCalAccessAdapter({ conditional: false });
    await adapter.prepare(['100']);
    expect(adapter.zipWasSkipped()).toBe(false);
    expect(poolQueryMock).not.toHaveBeenCalled();
    const init = fetchMock.mock.calls[0][1] as RequestInit;
    expect((init.headers as Record<string, string>)['If-None-Match']).toBeUndefined();
    expect((await adapter.fetch(source('100'))).records).toHaveLength(3);
  });

  // CloudFront answers If-None-Match with 304 only when the edge holds the object; on a miss it
  // sends the full 200 (the Render run of 2026-09-23 23:54 UTC re-read the unchanged 1.58 GB).
  function trackedZipResponse(etag: string): { response: Response; cancelled: () => boolean } {
    const bytes = new Uint8Array(buildZip());
    let wasCancelled = false;
    const body = new ReadableStream<Uint8Array>({
      pull(controller) { controller.enqueue(bytes); controller.close(); },
      cancel() { wasCancelled = true; },
    });
    const response = new Response(body, {
      status: 200,
      headers: { 'content-length': String(bytes.length), ETag: etag },
    });
    return { response, cancelled: () => wasCancelled };
  }

  it('treats a 200 that carries the stored ETag as unchanged and does not read the body', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ notes: '"etag-1"' }], rowCount: 1 });
    const tracked = trackedZipResponse('"etag-1"');
    fetchMock.mockImplementation(async () => tracked.response);
    const adapter = createCalAccessAdapter();
    await adapter.prepare(['100']);
    expect(adapter.zipWasSkipped()).toBe(true);
    expect(tracked.cancelled()).toBe(true);
    expect((await adapter.fetch(source('100'))).records).toHaveLength(0);
  });

  it('reads a 200 whose ETag differs from the stored one', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ notes: '"etag-old"' }], rowCount: 1 });
    const tracked = trackedZipResponse('"etag-new"');
    fetchMock.mockImplementation(async () => tracked.response);
    const adapter = createCalAccessAdapter();
    await adapter.prepare(['100']);
    expect(adapter.zipWasSkipped()).toBe(false);
    expect(adapter.getETag()).toBe('"etag-new"');
    expect((await adapter.fetch(source('100'))).records).toHaveLength(3);
  });

  it('still recognises the stored ETag on the retry that sends no If-None-Match', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ notes: '"etag-1"' }], rowCount: 1 });
    const tracked = trackedZipResponse('"etag-1"');
    fetchMock
      .mockImplementationOnce(async () => { throw new Error('socket hang up'); })
      .mockImplementationOnce(async () => tracked.response);
    const adapter = createCalAccessAdapter();
    await adapter.prepare(['100']);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect((fetchMock.mock.calls[1][1] as RequestInit & { headers: Record<string, string> }).headers['If-None-Match'])
      .toBeUndefined();
    expect(adapter.zipWasSkipped()).toBe(true);
    expect(tracked.cancelled()).toBe(true);
  });
});

describe('calAccessAdapter upsert: prune superseded rows', () => {
  // Block body: a hook that RETURNS a function has it called as a cleanup hook, and
  // mockReset() returns the mock itself.
  beforeEach(() => { poolQueryMock.mockReset(); });

  const contribution = (id: string): ContributionInsert => ({
    politician_source_id: 'src-100',
    donor_id: null,
    committee_id: null,
    amount: 1,
    contribution_date: new Date('2019-03-12'),
    election_cycle: '2020',
    confidence_level: 'HIGH',
    data_source: 'cal_access',
    source_transaction_id: id,
    raw_record: {},
    donor_name_normalized: 'dana donor',
  });

  it('deletes the source rows the export no longer carries, after a clean write', async () => {
    poolQueryMock.mockImplementation(async (sql: string) =>
      sql.includes('INSERT INTO') ? { rows: [{ is_insert: true }, { is_insert: false }] } : { rows: [], rowCount: 1 });

    const res = await createCalAccessAdapter().upsert({
      contributions: [contribution('F1_0_1'), contribution('F2_1_1')], skipped: 0, totalParsed: 2,
    });
    expect(res).toMatchObject({ inserted: 1, updated: 1, errors: 0 });

    const del = poolQueryMock.mock.calls.find(([sql]) => String(sql).includes('DELETE FROM'));
    expect(del).toBeDefined();
    expect(del![1]).toEqual(['src-100', ['F1_0_1', 'F2_1_1']]);
    const sql = String(del![0]);
    expect(sql).toContain("m.data_source = 'cal_access'");
    // The CTE that finds the source's rows must filter on politician_source_id ALONE, so the
    // planner can only use the per-source index (see pruneSuperseded).
    const cte = sql.slice(sql.indexOf('MATERIALIZED'), sql.indexOf('DELETE FROM'));
    expect(cte).toMatch(/WHERE politician_source_id = \$1\s*\)/);
    expect(cte).not.toContain('data_source =');
  });

  it('does not prune when a batch failed', async () => {
    poolQueryMock.mockImplementation(async (sql: string) => {
      if (sql.includes('INSERT INTO')) throw new Error('boom');
      return { rows: [], rowCount: 0 };
    });
    const res = await createCalAccessAdapter().upsert({
      contributions: [contribution('F1_0_1')], skipped: 0, totalParsed: 1,
    });
    expect(res.errors).toBe(1);
    expect(poolQueryMock.mock.calls.some(([sql]) => String(sql).includes('DELETE FROM'))).toBe(false);
  });

  it('does not prune when the export has nothing for the source', async () => {
    await createCalAccessAdapter().upsert({ contributions: [], skipped: 0, totalParsed: 0 });
    expect(poolQueryMock).not.toHaveBeenCalled();
  });

  it('only rewrites a conflicting row whose stored value changed', async () => {
    poolQueryMock.mockResolvedValue({ rows: [], rowCount: 0 });
    await createCalAccessAdapter().upsert({ contributions: [contribution('F1_0_1')], skipped: 0, totalParsed: 1 });
    const insert = String(poolQueryMock.mock.calls[0][0]);
    expect(insert).toMatch(/WHERE contributions\.donor_name_normalized IS DISTINCT FROM EXCLUDED\.donor_name_normalized/);
  });
});

describe('readBody', () => {
  it('fills one buffer of the advertised length', async () => {
    const body = Buffer.from('0123456789');
    const out = await readBody(zipResponse(body));
    expect(out.equals(body)).toBe(true);
  });

  it('throws when the body is shorter than Content-Length', async () => {
    const res = new Response(new Uint8Array(Buffer.from('0123')), { headers: { 'content-length': '10' } });
    await expect(readBody(res)).rejects.toThrow(/ended at 4 of Content-Length 10/);
  });
});
