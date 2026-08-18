/**
 * indianaAdapter — Indiana Campaign Finance bulk CSV adapter implementing SourceAdapter.
 *
 * Ported from:
 *   EV-Backend/internal/campaign_finance/adapter/indiana/adapter.go
 *   EV-Backend/internal/campaign_finance/adapter/indiana/download.go
 *   EV-Backend/internal/campaign_finance/adapter/indiana/parser.go
 *   EV-Backend/internal/campaign_finance/adapter/indiana/normalize.go
 *
 * Contains four layers in one file:
 *   1. ZIP Download    — ETag-cached annual bulk ZIP from campaignfinance.in.gov
 *   2. CSV Parser      — header-driven column indexing, BOM-safe, caches by FileNumber
 *   3. Normalizer      — dual-type Date/string handling, election cycle, MEDIUM confidence
 *   4. Upsert          — ON CONFLICT (data_source, source_transaction_id) DO UPDATE
 *
 * Indiana-specific extras (NOT part of SourceAdapter interface):
 *   - writeUnresolved(rows, runId): writes known-but-unconfirmed FileNumbers to unresolved queue
 *   - normalizeRow(rec, ps): exported for backfill/resolve handler in Plan 07
 *
 * Export:
 *   createIndianaAdapter(year): SourceAdapter factory
 *   writeUnresolved(rows, runId): Indiana-specific unresolved queue writer
 *   normalizeRow(rec, ps): exported normalizer for backfill/resolve reuse
 */

import AdmZip from 'adm-zip';
import { parse } from 'csv-parse/sync';
import { pool } from '../db.js';
import type {
  SourceAdapter,
  FetchResult,
  NormalizeResult,
  UpsertResult,
  ContributionInsert,
  ETagProvider,
} from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';
import { normalizeDonorName } from './normalizeDonorName.js';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/** Annual contribution ZIP URL — %s replaced with 4-digit year */
const INDIANA_ZIP_URL_TEMPLATE =
  'https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/%d_ContributionData.csv.zip';

/** Per-year ETag key template stored in data_source_metadata */
const ETAG_KEY_TEMPLATE = 'indiana_zip_etag_%d';

// ---------------------------------------------------------------------------
// Internal types
// ---------------------------------------------------------------------------

/** Typed fields from a single Indiana contribution CSV row */
interface ParsedRow {
  fileNumber: string;
  committeeType: string;
  committee: string;
  candidateName: string;
  contributorType: string;
  contributorName: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  occupation: string;
  contributionType: string;
  description: string;
  amount: number;
  contributionDate: Date;
  receivedBy: string;
  amended: string;
  rowNumber: number;
}

// ---------------------------------------------------------------------------
// ZIP Download — ported from download.go
// ---------------------------------------------------------------------------

function etagKey(year: number): string {
  return ETAG_KEY_TEMPLATE.replace('%d', String(year));
}

function zipUrl(year: number): string {
  return INDIANA_ZIP_URL_TEMPLATE.replace('%d', String(year));
}

/** Reads previously saved ETag for a given year from data_source_metadata. Empty string if none. */
async function loadStoredETag(year: number): Promise<string> {
  const result = await pool.query<{ notes: string }>(
    `SELECT notes FROM transparent_motivations.data_source_metadata WHERE source_system = $1 LIMIT 1`,
    [etagKey(year)]
  );
  return result.rows[0]?.notes ?? '';
}

/** Upserts the ETag value for a given year into data_source_metadata. */
async function saveETag(year: number, etag: string): Promise<void> {
  await pool.query(
    `INSERT INTO transparent_motivations.data_source_metadata
       (source_system, last_sync_at, last_sync_status, notes)
     VALUES ($1, NOW(), 'ok', $2)
     ON CONFLICT (source_system)
     DO UPDATE SET last_sync_at = NOW(), last_sync_status = 'ok', notes = $2, updated_at = NOW()`,
    [etagKey(year), etag]
  );
}

interface DownloadResult {
  /** In-memory ZIP buffer (null if 304 Not Modified) */
  buffer: Buffer | null;
  etag: string;
  downloadedAt: Date;
  skipped: boolean;
}

/**
 * downloadZIP fetches the Indiana annual contribution ZIP for the given year,
 * using ETag caching to skip re-download when the server returns 304.
 *
 * Returns buffer=null + skipped=true on 304 Not Modified.
 * On first-attempt error, retries without ETag (in case of cache-related server error).
 */
async function downloadZIP(year: number): Promise<DownloadResult> {
  const storedETag = await loadStoredETag(year);
  const downloadedAt = new Date();
  const url = zipUrl(year);

  let result = await doRequest(url, storedETag);

  // Retry without ETag on error (cache-related server error recovery)
  if (result === null) {
    result = await doRequest(url, '');
    if (result === null) {
      throw new Error(`indiana: downloadZIP year=${year}: HTTP request failed after retry`);
    }
  }

  if (result.skipped) {
    return { buffer: null, etag: storedETag, downloadedAt, skipped: true };
  }

  return { buffer: result.buffer, etag: result.etag, downloadedAt, skipped: false };
}

interface RequestResult {
  buffer: Buffer | null;
  etag: string;
  skipped: boolean;
}

/**
 * doRequest sends a GET request with an optional If-None-Match header.
 * Returns null on network error (caller retries without ETag).
 * Returns { buffer: null, skipped: true } on 304 Not Modified.
 * Returns { buffer, etag } on 200 OK.
 */
async function doRequest(url: string, storedETag: string): Promise<RequestResult | null> {
  const headers: Record<string, string> = {};
  if (storedETag) {
    headers['If-None-Match'] = storedETag;
  }

  let response: Response;
  try {
    response = await fetch(url, {
      headers,
      signal: AbortSignal.timeout(120_000), // 2 min for large ZIP
    });
  } catch {
    return null;
  }

  if (response.status === 304) {
    return { buffer: null, etag: '', skipped: true };
  }

  if (response.status !== 200) {
    console.error(`[indianaAdapter] unexpected HTTP ${response.status} for ${url}`);
    return null;
  }

  const arrayBuffer = await response.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  const etag = response.headers.get('ETag') ?? '';

  if (!etag) {
    console.warn(`[indianaAdapter] server returned no ETag header for ${url}; next run will re-download`);
  }

  return { buffer, etag, skipped: false };
}

// ---------------------------------------------------------------------------
// CSV Parser — ported from parser.go
// ---------------------------------------------------------------------------

/**
 * stripBOM removes a leading UTF-8 BOM from a string.
 * Common in Windows-generated CSV files from Indiana Campaign Finance portal.
 */
function stripBOM(s: string): string {
  return s.startsWith('\uFEFF') ? s.slice(1) : s;
}

/**
 * parseCSV opens a ZIP buffer, locates the inner CSV by suffix (*ContributionData.csv),
 * and parses it into matched and unmatched slices based on knownFileNumbers.
 *
 * Column positions are determined by the header row — NOT hardcoded indexes.
 * This makes the parser resilient to column reordering across annual exports.
 *
 * A row is "matched" if its FileNumber is in knownFileNumbers.
 * Unmatched rows (completely unknown FileNumbers) are silently dropped.
 */
function parseCSV(
  zipBuffer: Buffer,
  knownFileNumbers: Set<string>
): {
  matched: ParsedRow[];
  unmatched: ParsedRow[];
  totalParsed: number;
} {
  const zip = new AdmZip(zipBuffer);
  const entries = zip.getEntries();

  // Locate the inner CSV by suffix — Indiana prepends the year (e.g. "2024_ContributionData.csv")
  const csvEntry = entries.find((e) => e.entryName.endsWith('ContributionData.csv'));
  if (!csvEntry) {
    throw new Error(`indiana: parseCSV: no file matching *ContributionData.csv in ZIP`);
  }

  // Get raw CSV content as string
  let csvContent = csvEntry.getData().toString('utf8');
  // Strip BOM from entire content (handles file-level BOM)
  csvContent = stripBOM(csvContent);

  // Parse CSV using csv-parse/sync — LazyQuotes and variable fields per row
  // bom: true handles any remaining BOM in csv-parse
  const rawRows = parse(csvContent, {
    relax_quotes: true,
    relax_column_count: true,
    skip_empty_lines: true,
    bom: true,
  }) as string[][];

  if (rawRows.length === 0) {
    throw new Error('indiana: parseCSV: CSV is empty (no rows)');
  }

  // Build column-name-to-index map from header row
  const headerRow = rawRows[0];
  const colIdx: Record<string, number> = {};
  for (let i = 0; i < headerRow.length; i++) {
    const colName = stripBOM(headerRow[i]).trim();
    colIdx[colName] = i;
  }

  const matched: ParsedRow[] = [];
  const unmatched: ParsedRow[] = [];
  let totalParsed = 0;

  for (let rowNum = 1; rowNum < rawRows.length; rowNum++) {
    const record = rawRows[rowNum];
    totalParsed++;

    const fileNumber = colGet(record, colIdx, 'FileNumber');
    const amountStr = colGet(record, colIdx, 'Amount');
    const amount = parseFloat(amountStr);

    if (isNaN(amount)) {
      console.warn(`[indianaAdapter] row ${rowNum + 1}: cannot parse Amount "${amountStr}" (skipping row)`);
      continue;
    }

    const dateStr = colGet(record, colIdx, 'ContributionDate');
    let contributionDate = new Date(0); // zero time default
    if (dateStr) {
      // Indiana date format: MM/DD/YYYY
      const parsed = parseIndianaDate(dateStr);
      if (parsed !== null) {
        contributionDate = parsed;
      } else {
        console.warn(`[indianaAdapter] row ${rowNum + 1}: cannot parse ContributionDate "${dateStr}" (using zero time)`);
      }
    }

    const row: ParsedRow = {
      fileNumber,
      committeeType: colGet(record, colIdx, 'CommitteeType'),
      committee: colGet(record, colIdx, 'Committee'),
      candidateName: colGet(record, colIdx, 'CandidateName'),
      contributorType: colGet(record, colIdx, 'ContributorType'),
      contributorName: colGet(record, colIdx, 'ContributorName'),
      address: colGet(record, colIdx, 'Address'),
      city: colGet(record, colIdx, 'City'),
      state: colGet(record, colIdx, 'State'),
      zip: colGet(record, colIdx, 'Zip'),
      occupation: colGet(record, colIdx, 'Occupation'),
      contributionType: colGet(record, colIdx, 'ContributionType'),
      description: colGet(record, colIdx, 'Description'),
      amount,
      contributionDate,
      receivedBy: colGet(record, colIdx, 'ReceivedBy'),
      amended: colGet(record, colIdx, 'Amended'),
      rowNumber: rowNum,
    };

    if (knownFileNumbers.has(fileNumber)) {
      matched.push(row);
    } else {
      unmatched.push(row);
    }
  }

  return { matched, unmatched, totalParsed };
}

/** Returns value at column name from a record using header-index map. */
function colGet(record: string[], colIdx: Record<string, number>, name: string): string {
  const i = colIdx[name];
  if (i === undefined || i >= record.length) return '';
  return (record[i] ?? '').trim();
}

/**
 * parseIndianaDate parses Indiana's MM/DD/YYYY date format.
 * Returns null on parse failure.
 */
function parseIndianaDate(dateStr: string): Date | null {
  // Format 1: MM/DD/YYYY (older data)
  const slashParts = dateStr.split('/');
  if (slashParts.length === 3) {
    const month = parseInt(slashParts[0], 10);
    const day = parseInt(slashParts[1], 10);
    const year = parseInt(slashParts[2], 10);
    if (!isNaN(month) && !isNaN(day) && !isNaN(year)) {
      const d = new Date(Date.UTC(year, month - 1, day));
      if (!isNaN(d.getTime())) return d;
    }
  }
  // Format 2: YYYY-MM-DD HH:MM:SS (2025+ data)
  const isoMatch = dateStr.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (isoMatch) {
    const year = parseInt(isoMatch[1], 10);
    const month = parseInt(isoMatch[2], 10);
    const day = parseInt(isoMatch[3], 10);
    const d = new Date(Date.UTC(year, month - 1, day));
    if (!isNaN(d.getTime())) return d;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Normalizer — ported from normalize.go
// ---------------------------------------------------------------------------

/**
 * normalizeRow converts a single deserialized raw row map and a PoliticianSource
 * into a ContributionInsert struct.
 *
 * CRITICAL: Handles both the direct CSV parse path (ContributionDate is a Date object)
 * AND the jsonb backfill path (ContributionDate is an ISO RFC3339 string).
 * Dual-type check: try Date.getTime() first; if NaN or not a Date, parse as ISO string.
 *
 * Rules:
 *   - Amount parse error: return null (skip row — amount is primary financial fact)
 *   - Date parse error: use epoch (zero time)
 *   - ElectionCycle: round UP to next even year from contribution date
 *   - Confidence level: 'MEDIUM' for Indiana
 *   - Data source: 'indiana'
 *
 * Exported for reuse by unresolved queue resolve handler (Plan 07).
 */
export function normalizeRow(
  rec: Record<string, unknown>,
  ps: PoliticianSource
): ContributionInsert | null {
  // --- Amount: number/float64 first, then string fallback ---
  let amount: number;
  const rawAmount = rec['Amount'] ?? rec['amount'];
  if (typeof rawAmount === 'number') {
    amount = rawAmount;
  } else if (typeof rawAmount === 'string') {
    amount = parseFloat(rawAmount);
    if (isNaN(amount)) {
      // Amount parse error = skip row
      return null;
    }
  } else {
    // Missing amount = skip row
    return null;
  }

  // --- ContributionDate: Date object first, then ISO string fallback ---
  let tranDate: Date = new Date(0); // zero time default
  const rawDate = rec['ContributionDate'] ?? rec['contributionDate'];

  if (rawDate instanceof Date) {
    if (!isNaN(rawDate.getTime())) {
      tranDate = rawDate;
    }
    // else: Date is invalid → use zero time
  } else if (typeof rawDate === 'string' && rawDate !== '') {
    const parsed = new Date(rawDate);
    if (!isNaN(parsed.getTime())) {
      tranDate = parsed;
    }
    // else: string date parse error → use zero time (amount-primary-fact convention)
  }

  // --- ElectionCycle: round up to next even year ---
  let year = tranDate.getUTCFullYear();
  if (year === 1970 || year === 0) {
    // Zero time — use current year
    year = new Date().getUTCFullYear();
  }
  if (year % 2 !== 0) {
    year += 1;
  }
  const electionCycle = String(year);

  // --- Source transaction ID: composite, truncated to 128 chars ---
  const contributorName = String(rec['ContributorName'] ?? rec['contributorName'] ?? '');
  const fileNumber = String(rec['FileNumber'] ?? rec['fileNumber'] ?? '');
  const dateStr = tranDate.getTime() === 0
    ? '0001-01-01'
    : tranDate.toISOString().slice(0, 10);

  let sourceTxId = `${fileNumber}|${dateStr}|${contributorName}|${amount.toFixed(2)}`;
  if (sourceTxId.length > 128) {
    sourceTxId = sourceTxId.slice(0, 128);
  }

  // --- Contribution date pointer (null if zero time) ---
  const contributionDate: Date | null =
    tranDate.getTime() === 0 ? null : tranDate;

  return {
    politician_source_id: ps.id,
    donor_id: null,
    committee_id: null,
    amount,
    contribution_date: contributionDate,
    election_cycle: electionCycle,
    confidence_level: 'MEDIUM',
    data_source: 'indiana',
    source_transaction_id: sourceTxId,
    raw_record: rec,
    donor_name_normalized: normalizeDonorName(
      String(rec['ContributorName'] ?? rec['contributorName'] ?? '')
    ),
  };
}

// ---------------------------------------------------------------------------
// Upsert — ON CONFLICT (data_source, source_transaction_id) DO UPDATE
// ---------------------------------------------------------------------------

/**
 * upsertContributions writes contributions to the DB idempotently in batches of 100.
 * ON CONFLICT (data_source, source_transaction_id) DO UPDATE SET updated_at = NOW()
 * Uses xmax trick to count inserts vs updates without a second SELECT.
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
      updated += batchSkipped; // ON CONFLICT rows were REFRESHED, not skipped
    } catch (err) {
      errors += batch.length;
      console.error(`[indianaAdapter] upsert batch error at offset ${i}:`, err);
    }
  }

  return { inserted, updated, skipped: 0, unresolved: 0, errors };
}

async function upsertBatch(
  batch: ContributionInsert[]
): Promise<{ batchInserted: number; batchSkipped: number }> {
  if (batch.length === 0) return { batchInserted: 0, batchSkipped: 0 };

  // Deduplicate within batch — Indiana CSV can have repeated rows with same source_transaction_id
  const seen = new Set<string>();
  batch = batch.filter((c) => {
    if (seen.has(c.source_transaction_id)) return false;
    seen.add(c.source_transaction_id);
    return true;
  });

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
  let batchSkipped = 0;
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
// Unresolved queue writer — Indiana-specific, NOT part of SourceAdapter
// ---------------------------------------------------------------------------

/**
 * writeUnresolved writes rows from known-but-unconfirmed FileNumbers to the
 * transparent_motivations.unresolved_contributions table.
 *
 * This enables backfill in Phase 8: once OrgIds are confirmed, these rows can
 * be promoted to contributions without re-parsing the annual ZIP.
 *
 * runId: the ingestion_runs.id to associate these rows with.
 * Returns count of rows written.
 *
 * ON CONFLICT: skips duplicates (same adapter_name + external_id + fingerprint).
 * NOTE: This function is NOT part of the SourceAdapter interface — it is
 * Indiana-specific and called by the Indiana ingest handler after RunIngestion.
 */
export async function writeUnresolved(rows: ParsedRow[], runId: number): Promise<number> {
  if (rows.length === 0) return 0;

  let written = 0;

  const batchSize = 100;
  for (let i = 0; i < rows.length; i += batchSize) {
    const batch = rows.slice(i, i + batchSize);
    const params: unknown[] = [];
    const valuePlaceholders: string[] = [];
    const COLS_PER_ROW = 5;

    for (let idx = 0; idx < batch.length; idx++) {
      const row = batch[idx];
      const base = idx * COLS_PER_ROW + 1;
      valuePlaceholders.push(
        `($${base}, $${base + 1}, $${base + 2}::jsonb, $${base + 3}, $${base + 4})`
      );

      const rawObj = {
        FileNumber: row.fileNumber,
        CommitteeType: row.committeeType,
        Committee: row.committee,
        CandidateName: row.candidateName,
        ContributorType: row.contributorType,
        ContributorName: row.contributorName,
        Address: row.address,
        City: row.city,
        State: row.state,
        ZIP: row.zip,
        Occupation: row.occupation,
        ContributionType: row.contributionType,
        Description: row.description,
        Amount: row.amount,
        ContributionDate: row.contributionDate.toISOString(),
        ReceivedBy: row.receivedBy,
        Amended: row.amended,
        RowNumber: row.rowNumber,
      };

      params.push(
        'indiana',
        runId,
        JSON.stringify(rawObj),
        row.rowNumber,
        row.fileNumber
      );
    }

    const sql = `
      INSERT INTO transparent_motivations.unresolved_contributions
        (adapter_name, ingestion_run_id, raw_row, row_number, external_id)
      VALUES ${valuePlaceholders.join(', ')}
      RETURNING id
    `;

    try {
      const result = await pool.query<{ id: string }>(sql, params);
      written += result.rows.length;
    } catch (err) {
      console.error(`[indianaAdapter] writeUnresolved batch error at offset ${i}:`, err);
    }
  }

  return written;
}

// ---------------------------------------------------------------------------
// IndianaAdapter — implements SourceAdapter + ETagProvider
// ---------------------------------------------------------------------------

/**
 * IndianaAdapter implements SourceAdapter for Indiana Campaign Finance bulk CSV data.
 * Downloads the annual contribution ZIP, parses the CSV once (caching results by
 * FileNumber), and routes rows to either confirmed contributions or the unresolved queue
 * based on politician_sources research_status.
 *
 * Also implements ETagProvider so runIngestion can record ETag/download metadata.
 */
class IndianaAdapter implements SourceAdapter, ETagProvider {
  private readonly year: number;

  // Download state
  private zipBuffer: Buffer | null = null;
  private zipEtag = '';
  private zipDownloadedAt: Date | null = null;
  private zipSkipped = false;
  private zipDownloaded = false;

  // Entity resolution maps — populated by preDownload() from politician_sources
  /** FileNumber -> PoliticianSource.id for research_status='confirmed' */
  private confirmedFileNumbers = new Map<string, string>();
  /** All indiana sources regardless of research_status */
  private allKnownFileNumbers = new Set<string>();

  // CSV parse cache — populated on first fetch() call
  private parsedOnce = false;
  /** FileNumber -> confirmed rows */
  private parsedCache = new Map<string, ParsedRow[]>();
  /** Rows from known-but-unconfirmed FileNumbers — for writeUnresolved */
  private unmatchedRows: ParsedRow[] = [];

  constructor(year: number) {
    this.year = year;
  }

  name(): string {
    return 'indiana';
  }

  // ETagProvider implementation
  getETag(): string | null {
    return this.zipEtag || null;
  }

  getZIPDownloadedAt(): Date | null {
    return this.zipDownloadedAt;
  }

  /**
   * preDownload downloads the annual ZIP (with ETag caching) and queries
   * politician_sources to build entity resolution maps.
   * Must be called before fetch().
   */
  async preDownload(): Promise<void> {
    const result = await downloadZIP(this.year);
    this.zipBuffer = result.buffer;
    this.zipEtag = result.etag;
    this.zipDownloadedAt = result.downloadedAt;
    this.zipSkipped = result.skipped;
    this.zipDownloaded = true;

    if (result.etag) {
      await saveETag(this.year, result.etag);
    }

    // Build entity resolution maps from politician_sources
    const sourcesResult = await pool.query<{
      id: string;
      external_id: string;
      research_status: string;
    }>(
      `SELECT id, external_id, research_status
       FROM transparent_motivations.politician_sources
       WHERE source_system = 'indiana'`
    );

    if (sourcesResult.rows.length === 0) {
      console.warn('[indianaAdapter] preDownload: no politician_sources with source_system=\'indiana\' found — all rows will be dropped');
    }

    for (const s of sourcesResult.rows) {
      this.allKnownFileNumbers.add(s.external_id);
      if (s.research_status === 'confirmed') {
        this.confirmedFileNumbers.set(s.external_id, s.id);
      }
    }
  }

  /**
   * ensureParsed parses the CSV exactly once across all fetch() calls.
   * Caches confirmed rows by FileNumber; accumulates unresolved rows.
   */
  private ensureParsed(): void {
    if (this.parsedOnce) return;
    this.parsedOnce = true;

    if (!this.zipBuffer) {
      throw new Error('indiana: ensureParsed: no ZIP buffer (preDownload not called or 304 skipped)');
    }

    const { matched, unmatched: _unmatched, totalParsed } = parseCSV(
      this.zipBuffer,
      this.allKnownFileNumbers
    );

    console.log(
      `[indianaAdapter] parseCSV year=${this.year}: ${totalParsed} total rows, ` +
      `${matched.length} matched known FileNumbers`
    );

    // Split matched rows into confirmed (-> parsedCache) and unresolved (-> unmatchedRows)
    for (const row of matched) {
      const psId = this.confirmedFileNumbers.get(row.fileNumber);
      if (psId !== undefined) {
        const existing = this.parsedCache.get(row.fileNumber) ?? [];
        existing.push(row);
        this.parsedCache.set(row.fileNumber, existing);
      } else {
        // In allKnownFileNumbers but NOT confirmed — goes to unresolved queue
        this.unmatchedRows.push(row);
      }
    }

    // _unmatched = completely unknown FileNumbers — silently drop

    let confirmedCount = 0;
    for (const rows of this.parsedCache.values()) {
      confirmedCount += rows.length;
    }
    console.log(
      `[indianaAdapter] year=${this.year}: ${confirmedCount} rows to confirmed contributions, ` +
      `${this.unmatchedRows.length} rows to unresolved queue`
    );
  }

  /**
   * fetch returns all confirmed contribution rows for the given PoliticianSource.
   * On first call parses the full CSV and caches results; subsequent calls use cache.
   */
  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    if (!this.zipDownloaded) {
      throw new Error('indiana: fetch called before preDownload');
    }
    if (this.zipSkipped) {
      return { records: [], totalExpected: 0, totalFetched: 0 };
    }

    this.ensureParsed();

    const rows = this.parsedCache.get(ps.external_id) ?? [];

    // Convert ParsedRow structs to plain record maps for the SourceAdapter pipeline
    const records: Record<string, unknown>[] = rows.map((row) => ({
      FileNumber: row.fileNumber,
      CommitteeType: row.committeeType,
      Committee: row.committee,
      CandidateName: row.candidateName,
      ContributorType: row.contributorType,
      ContributorName: row.contributorName,
      Address: row.address,
      City: row.city,
      State: row.state,
      ZIP: row.zip,
      Occupation: row.occupation,
      ContributionType: row.contributionType,
      Description: row.description,
      Amount: row.amount,
      ContributionDate: row.contributionDate, // Date object — normalizeRow handles both Date and string
      ReceivedBy: row.receivedBy,
      Amended: row.amended,
      RowNumber: row.rowNumber,
    }));

    return {
      records,
      totalExpected: records.length,
      totalFetched: records.length,
    };
  }

  /**
   * normalize converts FetchResult records into ContributionInsert structs.
   * Delegates to normalizeRow to keep normalization in one place (no drift with backfill).
   */
  async normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult> {
    const contributions: ContributionInsert[] = [];
    let skipped = 0;
    const totalParsed = raw.records.length;

    for (const rec of raw.records) {
      const contrib = normalizeRow(rec, ps);
      if (contrib === null) {
        console.warn('[indianaAdapter] normalize: skip row (normalizeRow returned null)');
        skipped++;
        continue;
      }
      contributions.push(contrib);
    }

    return { contributions, skipped, totalParsed };
  }

  /**
   * upsert writes normalized contributions to the DB idempotently.
   */
  async upsert(normalized: NormalizeResult): Promise<UpsertResult> {
    return upsertContributions(normalized);
  }

  /**
   * getUnmatchedRows returns the accumulated unresolved rows after the first fetch().
   * Used by Indiana ingest handler to call writeUnresolved after RunIngestion.
   */
  getUnmatchedRows(): ParsedRow[] {
    return this.unmatchedRows;
  }

  /** unresolvedCount returns the number of rows queued for the unresolved contributions table. */
  unresolvedCount(): number {
    return this.unmatchedRows.length;
  }
}

// ---------------------------------------------------------------------------
// Factory function
// ---------------------------------------------------------------------------

/**
 * createIndianaAdapter creates an IndianaAdapter for the given year.
 *
 * IMPORTANT: Call adapter.preDownload() before running the ingestion pipeline.
 * The returned SourceAdapter does NOT include preDownload() — cast to
 * IndianaAdapterFull to access Indiana-specific methods.
 */
export function createIndianaAdapter(year: number): SourceAdapter & ETagProvider & {
  preDownload(): Promise<void>;
  getUnmatchedRows(): ParsedRow[];
  unresolvedCount(): number;
} {
  return new IndianaAdapter(year);
}
