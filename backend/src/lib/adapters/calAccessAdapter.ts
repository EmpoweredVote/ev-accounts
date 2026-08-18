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
 *   2. TSV Parser         — Windows-1252 decode via iconv-lite, csv-parse streaming, FILER_ID filter
 *   3. Normalizer+Upsert  — election cycle rounding, ON CONFLICT DO UPDATE, ETag metadata save
 *
 * Export: createCalAccessAdapter() — factory function.
 *
 * CRITICAL notes:
 *   - Cal-Access uses Windows-1252 encoding, NOT UTF-8. iconv-lite decodes before csv-parse.
 *   - csv-parse may reuse row buffers in streaming mode — copy field values immediately.
 *   - ETag key: cal_access_zip_etag (transparent_motivations.data_source_metadata)
 *   - Total rows key: cal_access_last_total_rows
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
// Full path inside the Cal-Access ZIP archive (not just the filename).
// The ZIP contains CalAccess/DATA/RCPT_CD.TSV — adm-zip.getEntry() requires the full path.
const RCPT_TSV_NAME = 'CalAccess/DATA/RCPT_CD.TSV';

// Required columns in RCPT_CD.TSV header — if any are absent, parsing aborts.
const REQUIRED_COLUMNS = [
  'CMTE_ID', 'AMOUNT', 'RCPT_DATE', 'FILING_ID',
  'AMEND_ID', 'LINE_ITEM', 'REC_TYPE', 'FORM_TYPE',
];

// ---------------------------------------------------------------------------
// Internal row types
// ---------------------------------------------------------------------------

interface ParsedRow {
  CMTE_ID: string;
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

interface SkippedRow {
  rowNum: number;
  errorType: string;
  detail: string;
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
    signal: AbortSignal.timeout(300_000), // 5 min timeout for large ZIP
  });

  if (response.status === 304) {
    return { body: null, etag: storedETag ?? '' };
  }

  if (response.status === 200) {
    const arrayBuffer = await response.arrayBuffer();
    return {
      body: Buffer.from(arrayBuffer),
      etag: response.headers.get('ETag') ?? '',
    };
  }

  throw new Error(`calAccessAdapter: unexpected HTTP status ${response.status} ${response.statusText}`);
}

/**
 * downloadZIP downloads the Cal-Access bulk ZIP using conditional GET (If-None-Match).
 * On network error, retries once without the ETag.
 */
async function downloadZIP(): Promise<DownloadResult> {
  const storedETag = await loadStoredETag();
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
      throw new Error(`calAccessAdapter: downloadZIP retry failed: ${retryErr}`);
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

interface ParseResult {
  rows: ParsedRow[];
  skipped: SkippedRow[];
  totalParsed: number;
}

/**
 * parseRCPT extracts RCPT_CD.TSV from the ZIP buffer, decodes Windows-1252,
 * and streams all contribution rows matching targetFilerIDs.
 *
 * CRITICAL:
 *   - Cal-Access uses Windows-1252 encoding — iconv-lite decodes before csv-parse.
 *   - csv-parse may reuse buffers in streaming mode — copy field values immediately.
 *   - totalParsed counts ALL data rows (global CCDC cross-check).
 *   - Rows for non-target filers are silently skipped (not counted in skipped[]).
 *   - RCPT_CD.TSV decompresses to ~4.2GB — stream-decompress to avoid V8 string limit.
 *     Uses getCompressedData() + zlib.createInflateRaw() to avoid holding full file in RAM.
 */
async function parseRCPT(zipBuffer: Buffer, targetFilerIDs: Set<string>): Promise<ParseResult> {
  // Extract RCPT_CD.TSV from ZIP buffer using adm-zip
  const zip = new AdmZip(zipBuffer);
  const entry = zip.getEntry(RCPT_TSV_NAME);
  if (!entry) {
    throw new Error(`calAccessAdapter: parseRCPT: ${RCPT_TSV_NAME} not found in ZIP`);
  }

  // Get the raw compressed bytes (not decompressed) to avoid holding 4.2GB in RAM.
  // stream-decompress with zlib.createInflateRaw(), transcode Windows-1252 → UTF-8 in chunks.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const compressedBytes: Buffer = (entry as any).getCompressedData();

  // iconv-lite streaming decoder — converts Windows-1252 chunks to UTF-8 strings.
  // We wrap it as a Transform stream that outputs UTF-8 Buffers.
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

  // Chain: compressed bytes → inflate → win1252→utf8 → csv-parse
  const source = Readable.from(compressedBytes);
  const inflater = createInflateRaw();
  source.pipe(inflater).pipe(win1252ToUtf8);

  return new Promise<ParseResult>((resolve, reject) => {
    const parsedRows: ParsedRow[] = [];
    const skippedRows: SkippedRow[] = [];
    let totalParsed = 0;
    let rowNum = 0;

    // Column index map — populated from header row
    const colIdx: Map<string, number> = new Map();
    let headerParsed = false;
    let minFieldsRequired = 0;

    // Optional column indexes — -1 if absent
    let ctribNameLIdx = -1;
    let ctribNameFIdx = -1;
    let ctribEmpIdx = -1;
    let ctribOccIdx = -1;

    // Helper: safe get from a string array by index
    const getField = (record: string[], idx: number): string => {
      if (idx < 0 || idx >= record.length) return '';
      return record[idx];
    };

    const parser = csvParse({
      delimiter: '\t',
      relax_column_count: true,
      skip_empty_lines: true,
    });

    parser.on('error', (err: Error) => {
      reject(new Error(`calAccessAdapter: parseRCPT: csv-parse error: ${err.message}`));
    });

    parser.on('readable', () => {
      let record: string[] | null;
      while ((record = parser.read() as string[] | null) !== null) {
        if (!headerParsed) {
          // First record is the header row — build column index map
          for (let i = 0; i < record.length; i++) {
            colIdx.set(record[i], i);
          }

          // Validate all required columns are present
          for (const col of REQUIRED_COLUMNS) {
            if (!colIdx.has(col)) {
              reject(new Error(`calAccessAdapter: parseRCPT: required column "${col}" not found in header`));
              parser.destroy();
              return;
            }
          }

          // Compute minimum fields required (max of required column indexes + 1)
          for (const col of REQUIRED_COLUMNS) {
            const idx = colIdx.get(col)!;
            if (idx + 1 > minFieldsRequired) {
              minFieldsRequired = idx + 1;
            }
          }

          // Optional column indexes
          ctribNameLIdx = colIdx.get('CTRIB_NAML') ?? -1;
          ctribNameFIdx = colIdx.get('CTRIB_NAMF') ?? -1;
          ctribEmpIdx   = colIdx.get('CTRIB_EMP') ?? -1;
          ctribOccIdx   = colIdx.get('CTRIB_OCC') ?? -1;

          headerParsed = true;
          continue;
        }

        rowNum++;
        totalParsed++;

        // Minimum field count check
        if (record.length < minFieldsRequired) {
          skippedRows.push({
            rowNum,
            errorType: 'field_count_mismatch',
            detail: `got ${record.length} fields, need at least ${minFieldsRequired}`,
          });
          continue;
        }

        // IMMEDIATELY copy required fields from potentially-reused buffer
        const cmteID      = record[colIdx.get('CMTE_ID')!];
        const amountStr   = record[colIdx.get('AMOUNT')!];
        const tranDateStr = record[colIdx.get('RCPT_DATE')!];
        const filingID    = record[colIdx.get('FILING_ID')!];
        const amendIDStr  = record[colIdx.get('AMEND_ID')!];
        const lineItemStr = record[colIdx.get('LINE_ITEM')!];
        const recType     = record[colIdx.get('REC_TYPE')!];
        const formType    = record[colIdx.get('FORM_TYPE')!];

        // Copy optional fields
        const ctribNameL = getField(record, ctribNameLIdx);
        const ctribNameF = getField(record, ctribNameFIdx);
        const ctribEmp   = getField(record, ctribEmpIdx);
        const ctribOcc   = getField(record, ctribOccIdx);

        // Validate CMTE_ID (required for FILER_ID filtering)
        if (!cmteID) {
          skippedRows.push({ rowNum, errorType: 'missing_required_field', detail: 'CMTE_ID' });
          continue;
        }

        // Filter: silently skip rows not belonging to our target filers
        if (!targetFilerIDs.has(cmteID)) {
          continue;
        }

        // Parse amount — skip row on error
        const amount = Number(amountStr);
        if (isNaN(amount) || amountStr.trim() === '') {
          skippedRows.push({ rowNum, errorType: 'amount_parse_error', detail: 'AMOUNT' });
          continue;
        }

        // Parse RCPT_DATE — format MM/DD/YYYY
        if (!tranDateStr) {
          skippedRows.push({ rowNum, errorType: 'missing_required_field', detail: 'RCPT_DATE' });
          continue;
        }

        const dateParts = tranDateStr.split('/');
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
          skippedRows.push({ rowNum, errorType: 'invalid_date', detail: 'RCPT_DATE' });
          continue;
        }

        // Parse AMEND_ID — non-fatal if missing (default 0)
        const amendID  = parseInt(amendIDStr, 10) || 0;
        const lineItem = parseInt(lineItemStr, 10) || 0;

        parsedRows.push({
          CMTE_ID: cmteID,
          filingID,
          recType,
          formType,
          ctribNameL,
          ctribNameF,
          ctribEmp,
          ctribOcc,
          amount,
          tranDate,
          amendID,
          lineItem,
        });
      }
    });

    parser.on('end', () => {
      resolve({ rows: parsedRows, skipped: skippedRows, totalParsed });
    });

    // Pipe streaming decoder into csv-parse (replaces parser.write(decodedBuffer))
    // Error propagation: inflate/transcode errors must reject the promise
    inflater.on('error', (err: Error) => {
      reject(new Error(`calAccessAdapter: parseRCPT: inflate error: ${err.message}`));
    });
    win1252ToUtf8.on('error', (err: Error) => {
      reject(new Error(`calAccessAdapter: parseRCPT: transcode error: ${err.message}`));
    });
    win1252ToUtf8.pipe(parser);
  });
}

// ---------------------------------------------------------------------------
// Upsert — ON CONFLICT (data_source, source_transaction_id) DO UPDATE
// ---------------------------------------------------------------------------

/**
 * upsertContributions writes contributions in batches of 100.
 * ON CONFLICT (data_source, source_transaction_id) DO UPDATE SET updated_at = NOW()
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
      const { batchInserted, batchSkipped } = await upsertBatch(batch);
      inserted += batchInserted;
      updated  += batchSkipped; // ON CONFLICT rows were REFRESHED, not skipped
    } catch (err) {
      // Per-batch error isolation — count errors and continue
      errors += batch.length;
      console.error(`[calAccessAdapter] upsert batch error at offset ${i}:`, err);
    }
  }

  return { inserted, updated, skipped: 0, unresolved: 0, errors };
}

async function upsertBatch(
  batch: ContributionInsert[]
): Promise<{ batchInserted: number; batchSkipped: number }> {
  if (batch.length === 0) return { batchInserted: 0, batchSkipped: 0 };

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
    RETURNING (xmax = 0) AS is_insert
  `;

  const result = await pool.query<{ is_insert: boolean }>(sql, params);

  let batchInserted = 0;
  let batchSkipped  = 0;
  for (const row of result.rows) {
    if (row.is_insert) {
      batchInserted++;
    } else {
      batchSkipped++;
    }
  }

  return { batchInserted, batchSkipped };
}

// ---------------------------------------------------------------------------
// CalAccessAdapter — implements SourceAdapter + ETagProvider
// ---------------------------------------------------------------------------

/**
 * CalAccessAdapter implements SourceAdapter for the Cal-Access daily bulk ZIP.
 *
 * Usage pattern (mirrors Go CalAccessAdapter):
 *   1. fetch() — downloads ZIP (or detects 304), parses RCPT_CD.TSV for politician
 *   2. normalize() — maps ParsedRows to ContributionInsert
 *   3. upsert() — idempotent DB write
 *   After all politicians: saveETag() to persist ETag + total row count
 *
 * ETagProvider is also implemented so runIngestion can capture ZIP metadata.
 */
class CalAccessAdapter implements SourceAdapter, ETagProvider {
  // ZIP state — shared across all politicians in one ingestion run
  private zipBuffer: Buffer | null = null;
  private zipETag: string = '';
  private zipDownloadedAt: Date | null = null;
  private zipSkipped: boolean = false;
  private zipDownloaded: boolean = false;

  // Global total (from first ParseRCPT call — same ZIP, same count every time)
  private globalTotalParsed: number = 0;
  private parsedOnce: boolean = false;

  // Per-politician state set in fetch(), consumed in normalize()
  private lastPoliticianSkipped: number = 0;
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

  /**
   * fetch downloads the ZIP (once per adapter instance) and parses RCPT_CD.TSV
   * for the given politician's FILER_ID (external_id from politician_sources).
   *
   * If the server returns 304 Not Modified, returns an empty FetchResult.
   * If the ZIP was already downloaded this run, reuses the buffer.
   */
  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    // Download ZIP on first call only
    if (!this.zipDownloaded) {
      const dl = await downloadZIP();
      this.zipBuffer       = dl.zipBuffer;
      this.zipETag         = dl.etag;
      this.zipDownloadedAt = dl.downloadedAt;
      this.zipSkipped      = dl.skipped;
      this.zipDownloaded   = true;
    }

    // 304 Not Modified — no new data
    if (this.zipSkipped) {
      return { records: [], totalExpected: 0, totalFetched: 0 };
    }

    if (!this.zipBuffer) {
      throw new Error('calAccessAdapter: fetch: zipBuffer is null but zipSkipped is false');
    }

    const targetFilerIDs = new Set<string>([ps.external_id]);
    const { rows, skipped, totalParsed } = await parseRCPT(this.zipBuffer, targetFilerIDs);

    // Record global total from first parse
    if (!this.parsedOnce) {
      this.globalTotalParsed = totalParsed;
      this.parsedOnce = true;
    }

    // Per-politician tracking for NormalizeResult.totalParsed
    this.lastPoliticianSkipped       = skipped.length;
    this.lastPoliticianTotalExamined = rows.length + skipped.length;

    // Convert ParsedRow[] to generic records[] for FetchResult
    const records: Record<string, unknown>[] = rows.map(row => ({
      CMTE_ID:     row.CMTE_ID,
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
 * Call adapter.saveETag() after all politicians to persist ETag + total row count.
 */
export function createCalAccessAdapter(): SourceAdapter & ETagProvider & {
  saveETag(): Promise<void>;
  zipWasSkipped(): boolean;
} {
  return new CalAccessAdapter();
}
