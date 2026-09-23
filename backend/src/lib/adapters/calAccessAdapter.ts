/**
 * calAccessAdapter — Cal-Access (California) bulk ZIP adapter implementing SourceAdapter.
 *
 * Ported from:
 *   EV-Backend/internal/campaign_finance/adapter/calaccess/adapter.go
 *   EV-Backend/internal/campaign_finance/adapter/calaccess/download.go
 *   EV-Backend/internal/campaign_finance/adapter/calaccess/parser.go
 *
 * Contains three layers in one file:
 *   1. ZIP Downloader     — ETag caching, 304 detection, retry without ETag on error
 *   2. TSV Parser         — Windows-1252 decode via iconv-lite, csv-parse streaming, recipient filter
 *   3. Normalizer+Upsert  — election cycle rounding, ON CONFLICT DO UPDATE, ETag metadata save
 *
 * Export: createCalAccessAdapter() — factory function.
 *
 * CRITICAL notes:
 *   - Cal-Access uses Windows-1252 encoding, NOT UTF-8. iconv-lite decodes before csv-parse.
 *   - csv-parse may reuse row buffers in streaming mode — copy field values immediately.
 *   - ETag key: cal_access_zip_etag (transparent_motivations.data_source_metadata)
 *   - Total rows key: cal_access_last_total_rows
 *
 * 🔴 WHO RECEIVED A RECEIPT IS NOT IN RCPT_CD. It is the filer of the filing the receipt is
 * reported on: RCPT_CD.FILING_ID -> FILER_FILINGS_CD.FILER_ID. RCPT_CD.CMTE_ID is the
 * CONTRIBUTOR's committee id, filled only when the contributor is itself a committee. Until
 * 2026-09-23 this adapter matched CMTE_ID, so every "contribution" it stored was money the
 * politician's committee GAVE to someone else: all 2,901 rows named the politician's own
 * committee as the donor (e.g. "Tony Thurmond for Superintendent 2018" giving to Tony
 * Thurmond), and Newsom's 2022 governor committee held 87 rows. The Go original had the same
 * filter and, per 5ec34c16, "never ran against real data".
 *
 * 🔴 PARSE ONCE PER RUN. RCPT_CD.TSV is 3.8 GB decompressed (19.3M rows). The adapter used to
 * re-stream it for every politician_source: ~9.4 min each (ingestion_runs avg, 3,203 runs),
 * so 619 confirmed sources would take ~97 h — far past Render's 12 h cron cap. Call
 * prepare(filerIds) once with every source's filer id; fetch() then serves from memory.
 */

import { pool } from '../db.js';
import AdmZip from 'adm-zip';
import { parse as csvParse } from 'csv-parse';
import iconv from 'iconv-lite';
import { createInflateRaw } from 'zlib';
import { Readable, Transform } from 'stream';
import type {
  SourceAdapter,
  ETagProvider,
  FetchResult,
  NormalizeResult,
  UpsertResult,
  ContributionInsert,
} from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';
import { normalizeDonorName } from './normalizeDonorName.js';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const CAL_ACCESS_ZIP_URL = 'https://campaignfinance.cdn.sos.ca.gov/dbwebexport.zip';
const ETAG_METADATA_KEY = 'cal_access_zip_etag';
const TOTAL_ROWS_METADATA_KEY = 'cal_access_last_total_rows';
// Full paths inside the Cal-Access ZIP archive (not just the filename).
// adm-zip.getEntry() requires the full path.
const RCPT_TSV_NAME = 'CalAccess/DATA/RCPT_CD.TSV';
const FILER_FILINGS_TSV_NAME = 'CalAccess/DATA/FILER_FILINGS_CD.TSV';

// Required columns in RCPT_CD.TSV header — if any are absent, parsing aborts.
const REQUIRED_COLUMNS = [
  'AMOUNT', 'RCPT_DATE', 'FILING_ID',
  'AMEND_ID', 'LINE_ITEM', 'REC_TYPE', 'FORM_TYPE',
];

// Required columns in FILER_FILINGS_CD.TSV header.
const FILER_FILINGS_REQUIRED_COLUMNS = ['FILER_ID', 'FILING_ID', 'FILING_SEQUENCE'];

/**
 * RCPT_CD schedules that are contributions RECEIVED by the filer.
 *   A — Form 460 Schedule A, monetary contributions received
 *   C — Form 460 Schedule C, non-monetary (in-kind) contributions received
 * Deliberately excluded (counted as `excluded`, never as defects):
 *   I      — Schedule I, miscellaneous increases to cash (interest, refunds, rebates)
 *   A-1    — contributions transferred to a special-election committee
 *   F401A  — slate-mailer organisation payments received
 *   F496P3 — receipts of an independent-expenditure filer, not a candidate's fundraising
 */
export const CONTRIBUTION_FORM_TYPES: ReadonlySet<string> = new Set(['A', 'C']);

// ---------------------------------------------------------------------------
// Internal row types
// ---------------------------------------------------------------------------

export interface ParsedRow {
  /** The RECIPIENT: the filer of the filing this receipt is reported on. */
  filerID: string;
  /** The contributor's committee id, when the contributor is a committee (else ''). */
  CMTE_ID: string;
  entityCd: string;
  filingID: string;
  recType: string;
  formType: string;
  ctribNameL: string;
  ctribNameF: string;
  ctribEmp: string;
  ctribOcc: string;
  amount: number;
  tranDate: Date;
  amendID: number;
  lineItem: number;
}

/** FILING_ID -> who filed it, for the target filers only. */
export interface FilingIndex {
  /** FILING_ID -> FILER_ID */
  filer: Map<string, string>;
  /** FILING_ID -> the latest amendment on record (FILING_SEQUENCE; 0 = original). */
  latestAmend: Map<string, number>;
}

/** Receipts for the target filers, grouped by recipient FILER_ID. */
export interface ReceiptParse {
  rowsByFiler: Map<string, ParsedRow[]>;
  /** Defects on a target filer's own rows (bad amount, bad date). */
  skippedByFiler: Map<string, number>;
  /** Rule-based omissions: superseded amendments and non-contribution schedules. */
  excludedByFiler: Map<string, number>;
  /** Every data row in RCPT_CD (global cross-check). */
  totalParsed: number;
}

// ---------------------------------------------------------------------------
// ETag metadata helpers — ported from download.go
// ---------------------------------------------------------------------------

/**
 * loadStoredETag fetches the previously saved ETag from data_source_metadata.
 * Returns null if no record found.
 */
async function loadStoredETag(): Promise<string | null> {
  const result = await pool.query<{ notes: string }>(
    `SELECT notes FROM transparent_motivations.data_source_metadata
     WHERE source_system = $1 LIMIT 1`,
    [ETAG_METADATA_KEY]
  );
  if (result.rows.length === 0) return null;
  return result.rows[0].notes ?? null;
}

/**
 * saveETag upserts the ZIP ETag into data_source_metadata for cal_access_zip_etag.
 */
async function saveETag(etag: string): Promise<void> {
  await pool.query(
    `INSERT INTO transparent_motivations.data_source_metadata
       (source_system, last_sync_at, last_sync_status, notes)
     VALUES ($1, NOW(), 'ok', $2)
     ON CONFLICT (source_system)
     DO UPDATE SET last_sync_at = NOW(), last_sync_status = 'ok', notes = $2`,
    [ETAG_METADATA_KEY, etag]
  );
}

/**
 * markNotModified records that a run found the ZIP unchanged (304). The stored ETag is
 * kept. Without this an unchanged day writes nothing at all, and "did the job run?" has
 * no durable answer.
 */
async function markNotModified(): Promise<void> {
  await pool.query(
    `UPDATE transparent_motivations.data_source_metadata
        SET last_sync_at = NOW(), last_sync_status = 'not_modified'
      WHERE source_system = $1`,
    [ETAG_METADATA_KEY]
  );
}

/**
 * saveTotalRows upserts the global row count into data_source_metadata.
 */
async function saveTotalRows(totalRows: number): Promise<void> {
  await pool.query(
    `INSERT INTO transparent_motivations.data_source_metadata
       (source_system, last_sync_at, last_sync_status, notes)
     VALUES ($1, NOW(), 'ok', $2)
     ON CONFLICT (source_system)
     DO UPDATE SET last_sync_at = NOW(), last_sync_status = 'ok', notes = $2`,
    [TOTAL_ROWS_METADATA_KEY, String(totalRows)]
  );
}

// ---------------------------------------------------------------------------
// ZIP Download — ported from download.go
// ---------------------------------------------------------------------------

interface DownloadResult {
  /** ZIP file as Buffer, or null if 304 Not Modified */
  zipBuffer: Buffer | null;
  etag: string;
  downloadedAt: Date;
  skipped: boolean;
}

/**
 * readBody reads a response body into ONE buffer of the advertised length.
 *
 * response.arrayBuffer() holds every received chunk AND the assembled copy at once, so a
 * 1.58 GB ZIP peaks near 3.2 GB — the difference between a 2 GB and a 4 GB instance.
 * Filling a preallocated buffer peaks at the ZIP's own size. Falls back to arrayBuffer()
 * when the server sends no usable Content-Length.
 */
export async function readBody(response: Response): Promise<Buffer> {
  const length = Number(response.headers.get('content-length'));
  if (!response.body || !Number.isSafeInteger(length) || length <= 0) {
    return Buffer.from(await response.arrayBuffer());
  }

  const out = Buffer.allocUnsafe(length);
  let offset = 0;
  for await (const chunk of response.body as unknown as AsyncIterable<Uint8Array>) {
    if (offset + chunk.length > length) {
      throw new Error(`calAccessAdapter: body is longer than Content-Length ${length}`);
    }
    out.set(chunk, offset);
    offset += chunk.length;
  }
  if (offset !== length) {
    throw new Error(`calAccessAdapter: body ended at ${offset} of Content-Length ${length} bytes`);
  }
  return out;
}

/**
 * doRequest sends one GET for the Cal-Access ZIP.
 * Returns null body on 304. Throws on unexpected status.
 */
async function doRequest(storedETag: string | null): Promise<{ body: Buffer | null; etag: string }> {
  const headers: Record<string, string> = {};
  if (storedETag) {
    headers['If-None-Match'] = storedETag;
  }

  const response = await fetch(CAL_ACCESS_ZIP_URL, {
    headers,
    signal: AbortSignal.timeout(900_000), // 15 min: 1.58 GB took ~5 min at 5.3 MB/s (2026-09-23)
  });

  if (response.status === 304) {
    return { body: null, etag: storedETag ?? '' };
  }

  if (response.status === 200) {
    return {
      body: await readBody(response),
      etag: response.headers.get('ETag') ?? '',
    };
  }

  throw new Error(`calAccessAdapter: unexpected HTTP status ${response.status} ${response.statusText}`);
}

/**
 * downloadZIP downloads the Cal-Access bulk ZIP using conditional GET (If-None-Match).
 * On network error, retries once without the ETag.
 *
 * conditional=false skips the stored ETag and always downloads — see CalAccessAdapterOptions.
 */
async function downloadZIP(conditional: boolean): Promise<DownloadResult> {
  const storedETag = conditional ? await loadStoredETag() : null;
  const downloadedAt = new Date();

  let result: { body: Buffer | null; etag: string };

  try {
    result = await doRequest(storedETag);
  } catch (firstErr) {
    // Retry once without If-None-Match on network error
    console.warn('[calAccessAdapter] Initial request failed, retrying without ETag:', firstErr);
    try {
      result = await doRequest(null);
    } catch (retryErr) {
      throw new Error(`calAccessAdapter: downloadZIP retry failed: ${retryErr}`, {
        cause: retryErr,
      });
    }
  }

  if (result.body === null) {
    // 304 Not Modified
    return { zipBuffer: null, etag: storedETag ?? '', downloadedAt, skipped: true };
  }

  if (!result.etag) {
    console.warn('[calAccessAdapter] downloadZIP: server did not return ETag header — skipping ETag save');
  }

  return { zipBuffer: result.body, etag: result.etag, downloadedAt, skipped: false };
}

// ---------------------------------------------------------------------------
// TSV Parser — ported from parser.go
// ---------------------------------------------------------------------------

/**
 * streamZipTsv streams one TSV entry of the ZIP through inflate -> Windows-1252 decode ->
 * csv-parse, calling onHeader once with the column index and onRecord for every data row.
 *
 * RCPT_CD.TSV decompresses to ~3.8 GB, past V8's string limit, so the entry is never
 * decompressed whole: getCompressedData() is a view into the ZIP buffer (no copy) and
 * zlib.createInflateRaw() inflates it in chunks.
 *
 * onHeader may throw to reject a header (missing required column); the stream stops.
 */
function streamZipTsv(
  zip: AdmZip,
  entryName: string,
  onHeader: (colIdx: Map<string, number>) => void,
  onRecord: (record: string[]) => void
): Promise<void> {
  const entry = zip.getEntry(entryName);
  if (!entry) {
    return Promise.reject(new Error(`calAccessAdapter: ${entryName} not found in ZIP`));
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const compressedBytes: Buffer = (entry as any).getCompressedData();

  // iconv-lite streaming decoder — converts Windows-1252 chunks to UTF-8 strings.
  const iconvDecoder = iconv.getDecoder('win1252');
  const win1252ToUtf8 = new Transform({
    transform(chunk: Buffer, _enc, cb) {
      const str: string = iconvDecoder.write(chunk);
      cb(null, Buffer.from(str, 'utf8'));
    },
    flush(cb) {
      const str: string | undefined = iconvDecoder.end();
      if (str) this.push(Buffer.from(str, 'utf8'));
      cb();
    },
  });

  const source = Readable.from(compressedBytes);
  const inflater = createInflateRaw();
  const parser = csvParse({
    delimiter: '\t',
    relax_column_count: true,
    skip_empty_lines: true,
  });

  return new Promise<void>((resolve, reject) => {
    let headerParsed = false;
    let failed = false;
    const fail = (err: Error): void => {
      if (failed) return;
      failed = true;
      parser.destroy();
      reject(err);
    };

    parser.on('error', (err: Error) => fail(new Error(`calAccessAdapter: ${entryName}: csv-parse error: ${err.message}`)));
    inflater.on('error', (err: Error) => fail(new Error(`calAccessAdapter: ${entryName}: inflate error: ${err.message}`)));
    win1252ToUtf8.on('error', (err: Error) => fail(new Error(`calAccessAdapter: ${entryName}: transcode error: ${err.message}`)));

    parser.on('readable', () => {
      let record: string[] | null;
      while (!failed && (record = parser.read() as string[] | null) !== null) {
        if (!headerParsed) {
          const colIdx = new Map<string, number>();
          for (let i = 0; i < record.length; i++) colIdx.set(record[i], i);
          try {
            onHeader(colIdx);
          } catch (err) {
            fail(err instanceof Error ? err : new Error(String(err)));
            return;
          }
          headerParsed = true;
          continue;
        }
        onRecord(record);
      }
    });

    parser.on('end', () => {
      if (!failed) resolve();
    });

    source.pipe(inflater).pipe(win1252ToUtf8).pipe(parser);
  });
}

function requireColumns(entryName: string, colIdx: Map<string, number>, required: string[]): void {
  for (const col of required) {
    if (!colIdx.has(col)) {
      throw new Error(`calAccessAdapter: ${entryName}: required column "${col}" not found in header`);
    }
  }
}

/**
 * indexFilings reads FILER_FILINGS_CD.TSV (378 MB decompressed, 2.9M rows) and returns,
 * for every filing made by one of targetFilerIDs, who filed it and its latest amendment.
 */
export async function indexFilings(zip: AdmZip, targetFilerIDs: Set<string>): Promise<FilingIndex> {
  const filer = new Map<string, string>();
  const latestAmend = new Map<string, number>();
  let filerIdx = -1;
  let filingIdx = -1;
  let seqIdx = -1;

  await streamZipTsv(
    zip,
    FILER_FILINGS_TSV_NAME,
    (colIdx) => {
      requireColumns(FILER_FILINGS_TSV_NAME, colIdx, FILER_FILINGS_REQUIRED_COLUMNS);
      filerIdx = colIdx.get('FILER_ID')!;
      filingIdx = colIdx.get('FILING_ID')!;
      seqIdx = colIdx.get('FILING_SEQUENCE')!;
    },
    (record) => {
      const filerID = record[filerIdx];
      if (!filerID || !targetFilerIDs.has(filerID)) return;
      const filingID = record[filingIdx];
      if (!filingID) return;
      filer.set(filingID, filerID);
      const seq = parseInt(record[seqIdx], 10) || 0;
      if (seq > (latestAmend.get(filingID) ?? -1)) latestAmend.set(filingID, seq);
    }
  );

  return { filer, latestAmend };
}

/**
 * parseReceipts streams RCPT_CD.TSV once and keeps the contributions RECEIVED on the
 * indexed filings, at their latest amendment only.
 *
 * Why the latest amendment only: an amended report restates the whole schedule under a
 * new AMEND_ID, and source_transaction_id embeds AMEND_ID, so keeping every version would
 * store the same contribution once per amendment.
 *
 * Rows on filings outside the index belong to other filers and are not counted anywhere.
 */
export async function parseReceipts(zip: AdmZip, filings: FilingIndex): Promise<ReceiptParse> {
  const rowsByFiler = new Map<string, ParsedRow[]>();
  const skippedByFiler = new Map<string, number>();
  const excludedByFiler = new Map<string, number>();
  const bump = (m: Map<string, number>, k: string): void => { m.set(k, (m.get(k) ?? 0) + 1); };
  let totalParsed = 0;

  let colIdx = new Map<string, number>();
  let minFieldsRequired = 0;
  const getField = (record: string[], col: string): string => {
    const idx = colIdx.get(col);
    if (idx === undefined || idx >= record.length) return '';
    return record[idx];
  };

  await streamZipTsv(
    zip,
    RCPT_TSV_NAME,
    (header) => {
      requireColumns(RCPT_TSV_NAME, header, REQUIRED_COLUMNS);
      colIdx = header;
      for (const col of REQUIRED_COLUMNS) {
        minFieldsRequired = Math.max(minFieldsRequired, header.get(col)! + 1);
      }
    },
    (record) => {
      totalParsed++;

      // Attribute first: only a target filer's own rows can be a defect worth counting.
      const filingID = getField(record, 'FILING_ID');
      const filerID = filingID ? filings.filer.get(filingID) : undefined;
      if (!filerID) return;

      if (record.length < minFieldsRequired) {
        bump(skippedByFiler, filerID);
        return;
      }

      // IMMEDIATELY copy fields from the potentially-reused buffer
      const amendID = parseInt(getField(record, 'AMEND_ID'), 10) || 0;
      const formType = getField(record, 'FORM_TYPE');
      if (amendID !== filings.latestAmend.get(filingID) || !CONTRIBUTION_FORM_TYPES.has(formType)) {
        bump(excludedByFiler, filerID);
        return;
      }

      // Parse amount — skip row on error
      const amountStr = getField(record, 'AMOUNT');
      const amount = Number(amountStr);
      if (isNaN(amount) || amountStr.trim() === '') {
        bump(skippedByFiler, filerID);
        return;
      }

      // Parse RCPT_DATE — format MM/DD/YYYY [HH:MM:SS AM]
      const tranDateStr = getField(record, 'RCPT_DATE');
      const dateParts = tranDateStr.split(' ')[0].split('/');
      let tranDate: Date | null = null;
      if (dateParts.length === 3) {
        const month = parseInt(dateParts[0], 10);
        const day   = parseInt(dateParts[1], 10);
        const year  = parseInt(dateParts[2], 10);
        if (!isNaN(month) && !isNaN(day) && !isNaN(year)) {
          // Construct as UTC to avoid local-timezone shifts
          tranDate = new Date(Date.UTC(year, month - 1, day));
        }
      }
      if (!tranDate || isNaN(tranDate.getTime())) {
        bump(skippedByFiler, filerID);
        return;
      }

      const row: ParsedRow = {
        filerID,
        CMTE_ID:    getField(record, 'CMTE_ID'),
        entityCd:   getField(record, 'ENTITY_CD'),
        filingID,
        recType:    getField(record, 'REC_TYPE'),
        formType,
        ctribNameL: getField(record, 'CTRIB_NAML'),
        ctribNameF: getField(record, 'CTRIB_NAMF'),
        ctribEmp:   getField(record, 'CTRIB_EMP'),
        ctribOcc:   getField(record, 'CTRIB_OCC'),
        amount,
        tranDate,
        amendID,
        lineItem: parseInt(getField(record, 'LINE_ITEM'), 10) || 0,
      };
      const list = rowsByFiler.get(filerID);
      if (list) list.push(row);
      else rowsByFiler.set(filerID, [row]);
    }
  );

  return { rowsByFiler, skippedByFiler, excludedByFiler, totalParsed };
}

/** parseZip — index the target filers' filings, then read their receipts. */
async function parseZip(zipBuffer: Buffer, targetFilerIDs: Set<string>): Promise<ReceiptParse> {
  const zip = new AdmZip(zipBuffer);
  const filings = await indexFilings(zip, targetFilerIDs);
  return parseReceipts(zip, filings);
}

// ---------------------------------------------------------------------------
// Upsert — ON CONFLICT (data_source, source_transaction_id) DO UPDATE
// ---------------------------------------------------------------------------

/**
 * upsertContributions writes contributions in batches of 100, then prunes the source's
 * cal_access rows that the export no longer carries.
 *
 * ON CONFLICT (data_source, source_transaction_id) DO UPDATE, but ONLY when a stored value
 * differs. The export is the full history and this runs daily, so an unconditional update
 * would rewrite every stored row every day for no change.
 * xmax=0 trick counts inserts vs updates without a second SELECT.
 */
async function upsertContributions(normalized: NormalizeResult): Promise<UpsertResult> {
  if (normalized.contributions.length === 0) {
    return { inserted: 0, updated: 0, skipped: 0, unresolved: 0, errors: 0 };
  }

  let inserted = 0;
  let updated = 0;
  let errors = 0;

  const batchSize = 100;
  for (let i = 0; i < normalized.contributions.length; i += batchSize) {
    const batch = normalized.contributions.slice(i, i + batchSize);
    try {
      const { batchInserted, batchUpdated } = await upsertBatch(batch);
      inserted += batchInserted;
      updated  += batchUpdated; // ON CONFLICT rows were REFRESHED, not skipped
    } catch (err) {
      // Per-batch error isolation — count errors and continue
      errors += batch.length;
      console.error(`[calAccessAdapter] upsert batch error at offset ${i}:`, err);
    }
  }

  // Prune only after a clean write: a failed batch means the keep-set is not all in the table.
  if (errors === 0) {
    await pruneSuperseded(normalized.contributions);
  }

  return { inserted, updated, skipped: 0, unresolved: 0, errors };
}

/**
 * pruneSuperseded deletes this source's cal_access rows that are not in the current export.
 *
 * The export is a full snapshot, so a stored row it no longer carries has been superseded:
 * an amendment restated the report under a new AMEND_ID (a new source_transaction_id), or
 * the line was withdrawn. Without this, every amendment would add a second copy of the
 * report's contributions and never remove the first.
 *
 * Never called with an empty keep-set (upsertContributions returns early), so a filer the
 * export suddenly shows nothing for keeps its rows rather than being emptied.
 */
async function pruneSuperseded(contributions: ContributionInsert[]): Promise<void> {
  const sourceID = contributions[0].politician_source_id;
  const keep = contributions.map(c => c.source_transaction_id);
  // Anti-join, not `NOT (id = ANY($2))`: a committee can hold ~29k rows (Newsom 2022), and
  // an array test per row is quadratic where a hashed anti-join is linear.
  //
  // 🔴 The source's rows are found through a MATERIALIZED CTE that filters on
  // politician_source_id ALONE, so the only usable index is the per-source one. With
  // `data_source = 'cal_access'` in the same WHERE, the planner took the (data_source,
  // source_transaction_id) unique index instead and read EVERY cal_access row for each
  // source: measured 2026-09-23, 9+ s per prune by the end of the first ingest (155k rows),
  // because contributions' statistics still counted almost no cal_access rows. 190k inserts
  // do not reach autovacuum's analyze threshold on a 28M-row table, so that plan would stay.
  const res = await pool.query(
    `WITH mine AS MATERIALIZED (
       SELECT id, data_source, source_transaction_id
         FROM transparent_motivations.contributions
        WHERE politician_source_id = $1
     )
     DELETE FROM transparent_motivations.contributions c
      USING mine m
      WHERE c.id = m.id
        AND m.data_source = 'cal_access'
        AND NOT EXISTS (SELECT 1 FROM unnest($2::text[]) AS k(id) WHERE k.id = m.source_transaction_id)`,
    [sourceID, keep]
  );
  if (res.rowCount) {
    console.log(`[calAccessAdapter] source=${sourceID}: pruned ${res.rowCount} superseded row(s)`);
  }
}

async function upsertBatch(
  batch: ContributionInsert[]
): Promise<{ batchInserted: number; batchUpdated: number }> {
  if (batch.length === 0) return { batchInserted: 0, batchUpdated: 0 };

  const params: unknown[] = [];
  const valuePlaceholders: string[] = [];
  const COLS_PER_ROW = 9;

  for (let idx = 0; idx < batch.length; idx++) {
    const c = batch[idx];
    const base = idx * COLS_PER_ROW + 1;
    valuePlaceholders.push(
      `($${base}, $${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6}, $${base + 7}::jsonb, $${base + 8})`
    );
    params.push(
      c.politician_source_id,
      c.amount,
      c.contribution_date ? c.contribution_date.toISOString() : null,
      c.election_cycle,
      c.confidence_level,
      c.data_source,
      c.source_transaction_id,
      JSON.stringify(c.raw_record),
      c.donor_name_normalized
    );
  }

  const sql = `
    INSERT INTO transparent_motivations.contributions
      (politician_source_id, amount, contribution_date, election_cycle,
       confidence_level, data_source, source_transaction_id, raw_record,
       donor_name_normalized)
    VALUES ${valuePlaceholders.join(', ')}
    ON CONFLICT (data_source, source_transaction_id)
    DO UPDATE SET
      updated_at = NOW(),
      donor_name_normalized = EXCLUDED.donor_name_normalized
    WHERE contributions.donor_name_normalized IS DISTINCT FROM EXCLUDED.donor_name_normalized
    RETURNING (xmax = 0) AS is_insert
  `;

  const result = await pool.query<{ is_insert: boolean }>(sql, params);

  let batchInserted = 0;
  let batchUpdated  = 0;
  for (const row of result.rows) {
    if (row.is_insert) {
      batchInserted++;
    } else {
      batchUpdated++;
    }
  }

  return { batchInserted, batchUpdated };
}

// ---------------------------------------------------------------------------
// CalAccessAdapter — implements SourceAdapter + ETagProvider
// ---------------------------------------------------------------------------

/**
 * CalAccessAdapter implements SourceAdapter for the Cal-Access daily bulk ZIP.
 *
 * Usage pattern:
 *   0. prepare(filerIds) — downloads the ZIP (or detects 304) and parses it ONCE for every
 *      filer in the run, then releases the ZIP buffer
 *   1. fetch() — returns the politician's receipts from the prepared parse
 *   2. normalize() — maps ParsedRows to ContributionInsert
 *   3. upsert() — idempotent DB write, then prune of superseded rows
 *   After all politicians: saveETag() to persist ETag + total row count
 *
 * fetch() without prepare() still works (one full parse per call) for single-filer callers.
 *
 * ETagProvider is also implemented so runIngestion can capture ZIP metadata.
 */
export interface CalAccessAdapterOptions {
  /**
   * true (default): send the stored ETag as If-None-Match, so an unchanged export is a 304
   * and the run parses nothing. That is right for the scheduled run, which owns the ETag.
   *
   * 🔴 false for any run that does not save the ETag (the judicial ingest). Once the scheduled
   * run has stored the current ETag, a conditional GET returns 304 until SOS publishes a new
   * export, and a 304 fetch() returns zero records without an error — the run would report
   * success and write nothing.
   */
  conditional?: boolean;
}

class CalAccessAdapter implements SourceAdapter, ETagProvider {
  constructor(private readonly options: CalAccessAdapterOptions = {}) {}

  // ZIP state — shared across all politicians in one ingestion run
  private zipBuffer: Buffer | null = null;
  private zipETag: string = '';
  private zipDownloadedAt: Date | null = null;
  private zipSkipped: boolean = false;
  private zipDownloaded: boolean = false;

  // The one parse for the whole run, set by prepare()
  private prepared: ReceiptParse | null = null;
  private preparedFilerIDs: Set<string> = new Set();

  // Global total (same ZIP, same count every time)
  private globalTotalParsed: number = 0;

  // Per-politician state set in fetch(), consumed in normalize()
  private lastPoliticianSkipped: number = 0;
  private lastPoliticianExcluded: number = 0;
  private lastPoliticianTotalExamined: number = 0;

  name(): string {
    return 'cal_access';
  }

  // ETagProvider implementation
  getETag(): string | null {
    return this.zipETag || null;
  }

  getZIPDownloadedAt(): Date | null {
    return this.zipDownloadedAt;
  }

  private async ensureDownloaded(): Promise<void> {
    if (this.zipDownloaded) return;
    const dl = await downloadZIP(this.options.conditional ?? true);
    this.zipBuffer       = dl.zipBuffer;
    this.zipETag         = dl.etag;
    this.zipDownloadedAt = dl.downloadedAt;
    this.zipSkipped      = dl.skipped;
    this.zipDownloaded   = true;
  }

  /**
   * prepare downloads the ZIP and parses it once for every filer in filerIDs, then drops
   * the ~1.6 GB ZIP buffer so the upsert phase runs without it. A 304 leaves nothing to
   * parse; check zipWasSkipped() afterwards.
   */
  async prepare(filerIDs: Iterable<string>): Promise<void> {
    if (this.prepared) {
      throw new Error('calAccessAdapter: prepare() may be called once per adapter');
    }
    await this.ensureDownloaded();
    if (this.zipSkipped) return;
    if (!this.zipBuffer) {
      throw new Error('calAccessAdapter: prepare: zipBuffer is null but zipSkipped is false');
    }

    const targets = new Set(filerIDs);
    this.prepared = await parseZip(this.zipBuffer, targets);
    this.preparedFilerIDs = targets;
    this.globalTotalParsed = this.prepared.totalParsed;
    this.zipBuffer = null;
  }

  /**
   * fetch returns the receipts filed by the given politician's filer (external_id from
   * politician_sources) — from the prepared parse when prepare() covered this filer,
   * otherwise by parsing the ZIP for this filer alone.
   *
   * If the server returned 304 Not Modified, returns an empty FetchResult.
   */
  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    await this.ensureDownloaded();

    // 304 Not Modified — no new data
    if (this.zipSkipped) {
      return { records: [], totalExpected: 0, totalFetched: 0 };
    }

    let parse: ReceiptParse;
    if (this.prepared && this.preparedFilerIDs.has(ps.external_id)) {
      parse = this.prepared;
    } else if (this.zipBuffer) {
      parse = await parseZip(this.zipBuffer, new Set([ps.external_id]));
      this.globalTotalParsed = parse.totalParsed;
    } else {
      throw new Error(
        `calAccessAdapter: fetch: filer ${ps.external_id} was not in prepare() and the ZIP has been released`
      );
    }

    const rows = parse.rowsByFiler.get(ps.external_id) ?? [];
    this.lastPoliticianSkipped       = parse.skippedByFiler.get(ps.external_id) ?? 0;
    this.lastPoliticianExcluded      = parse.excludedByFiler.get(ps.external_id) ?? 0;
    this.lastPoliticianTotalExamined = rows.length + this.lastPoliticianSkipped + this.lastPoliticianExcluded;

    // Convert ParsedRow[] to generic records[] for FetchResult
    const records: Record<string, unknown>[] = rows.map(row => ({
      FILER_ID:    row.filerID,
      CMTE_ID:     row.CMTE_ID,
      ENTITY_CD:   row.entityCd,
      FILING_ID:   row.filingID,
      REC_TYPE:    row.recType,
      FORM_TYPE:   row.formType,
      CTRIB_NAML:  row.ctribNameL,
      CTRIB_NAMF:  row.ctribNameF,
      CTRIB_EMP:   row.ctribEmp,
      CTRIB_OCC:   row.ctribOcc,
      AMOUNT:      row.amount,
      RCPT_DATE:   row.tranDate,
      AMEND_ID:    row.amendID,
      LINE_ITEM:   row.lineItem,
    }));

    return {
      records,
      totalExpected: records.length,
      totalFetched:  records.length,
    };
  }

  /**
   * normalize maps raw FetchResult records to ContributionInsert structs.
   *
   * ElectionCycle: round UP to next even year from contribution date.
   *   Odd year → year+1; Even year → unchanged.
   * source_transaction_id: FILING_ID_AMEND_ID_LINE_ITEM
   * Confidence: always HIGH for Cal-Access state filings.
   */
  async normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult> {
    const contributions: ContributionInsert[] = [];

    for (const rec of raw.records) {
      const filingID  = rec['FILING_ID'] as string ?? '';
      const amendID   = rec['AMEND_ID']  as number ?? 0;
      const lineItem  = rec['LINE_ITEM'] as number ?? 0;
      const amount    = rec['AMOUNT']    as number ?? 0;
      const tranDate  = rec['RCPT_DATE'] as Date | null ?? null;

      // Build election cycle: round contribution year up to next even year
      let electionCycle = '';
      if (tranDate) {
        const year = tranDate.getUTCFullYear();
        electionCycle = String(year % 2 !== 0 ? year + 1 : year);
      }

      // source_transaction_id: FILING_ID_AMEND_ID_LINE_ITEM
      const sourceTransactionId = `${filingID}_${amendID}_${lineItem}`;

      const ctribNameL = (rec['CTRIB_NAML'] as string | undefined) ?? '';
      const ctribNameF = (rec['CTRIB_NAMF'] as string | undefined) ?? '';
      const rawDonorName = `${ctribNameL} ${ctribNameF}`.trim();

      contributions.push({
        politician_source_id: ps.id,
        donor_id:    null,
        committee_id: null,
        amount,
        contribution_date: tranDate,
        election_cycle: electionCycle,
        confidence_level: 'HIGH',
        data_source: 'cal_access',
        source_transaction_id: sourceTransactionId,
        raw_record: rec,
        donor_name_normalized: normalizeDonorName(rawDonorName || null),
      });
    }

    return {
      contributions,
      skipped:     this.lastPoliticianSkipped,
      excluded:    this.lastPoliticianExcluded,
      totalParsed: this.lastPoliticianTotalExamined,
    };
  }

  /**
   * upsert writes normalized contributions idempotently in batches of 100.
   */
  async upsert(normalized: NormalizeResult): Promise<UpsertResult> {
    return upsertContributions(normalized);
  }

  /**
   * saveETag persists the ZIP ETag and global row count to data_source_metadata.
   * Call this after all politicians have been processed for the run.
   */
  async saveETag(): Promise<void> {
    if (this.zipETag) {
      await saveETag(this.zipETag);
    }
    if (this.globalTotalParsed > 0) {
      await saveTotalRows(this.globalTotalParsed);
    }
  }

  /**
   * markNotModified stamps last_sync_at on a 304 day. See the function of the same name.
   */
  async markNotModified(): Promise<void> {
    await markNotModified();
  }

  /**
   * zipWasSkipped reports whether the server returned 304 Not Modified.
   */
  zipWasSkipped(): boolean {
    return this.zipSkipped;
  }
}

// ---------------------------------------------------------------------------
// Factory function
// ---------------------------------------------------------------------------

/**
 * createCalAccessAdapter creates a CalAccessAdapter for Cal-Access bulk ZIP ingestion.
 * The ZIP is downloaded once per adapter instance (shared across all politicians in a run).
 * Call adapter.prepare(filerIds) before the per-politician loop, and adapter.saveETag()
 * after it to persist ETag + total row count. A run that does not save the ETag passes
 * { conditional: false } (see CalAccessAdapterOptions).
 */
export function createCalAccessAdapter(options: CalAccessAdapterOptions = {}): SourceAdapter & ETagProvider & {
  prepare(filerIDs: Iterable<string>): Promise<void>;
  saveETag(): Promise<void>;
  markNotModified(): Promise<void>;
  zipWasSkipped(): boolean;
} {
  return new CalAccessAdapter(options);
}
