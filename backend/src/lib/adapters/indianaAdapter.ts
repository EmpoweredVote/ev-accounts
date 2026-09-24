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
 *   1. ZIP Download    — one annual bulk ZIP per year from campaignfinance.in.gov, every run
 *   2. CSV Parser      — Windows-1252, header-driven column indexing, caches by FileNumber
 *   3. Normalizer      — dual-type Date/string handling, election cycle, MEDIUM confidence
 *   4. Upsert          — ON CONFLICT (data_source, source_transaction_id) DO UPDATE
 *
 * 🔴 WHAT WAS WRONG UNTIL 2026-09-24 (measured on prod that day; see indianaAdapter.test.ts):
 *   - It read ONLY the current calendar year's file. An officeholder who is not on this year's
 *     ballot files no pre-primary report, so their money is in LAST year's file (the annual
 *     report). 58 active politicians held a confirmed committee and no data at all; 48 of them
 *     have rows in the 2025 file (Mike Braun 440, Todd Rokita 172, Rodric Bray 153).
 *   - It read columns the export does not carry: the donor is `Name`, not `ContributorName`
 *     (likewise `Type`, `Received_By`). Every stored donor was blank ("anonymous"), and because
 *     the donor is part of the transaction key, different donors who gave the same amount on
 *     the same day collapsed into one row: 10,419 rows in the 2026 file became 6,503.
 *   - A 304 made every source's run "completed" with 0 records (488 runs on 2026-04-03).
 *     Downloads are now unconditional — see downloadZIP.
 *
 * Indiana-specific extras (NOT part of SourceAdapter interface):
 *   - writeUnresolved(rows, runId): writes rows of needs_research FileNumbers to the unresolved queue
 *   - normalizeRow(rec, ps): exported for backfill/resolve handler in Plan 07
 *
 * Export:
 *   createIndianaAdapter(years): SourceAdapter factory
 *   indianaYears(now): the years a scheduled run reads
 *   writeUnresolved(rows, runId): Indiana-specific unresolved queue writer
 *   normalizeRow(rec, ps): exported normalizer for backfill/resolve reuse
 */

import AdmZip from 'adm-zip';
import { parse } from 'csv-parse/sync';
import iconv from 'iconv-lite';
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

/** Annual contribution ZIP URL — %d replaced with 4-digit year */
const INDIANA_ZIP_URL_TEMPLATE =
  'https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/%d_ContributionData.csv.zip';

/** Per-year ETag key template stored in data_source_metadata (provenance only — see downloadZIP) */
const ETAG_KEY_TEMPLATE = 'indiana_zip_etag_%d';

/**
 * Header names the parser accepts for each field, live name first. The live export (2025 and
 * 2026 files, checked 2026-09-23) says `Name`, `Type`, `Received_By`; the Go port read the
 * second spelling of each, which those files do not carry.
 */
const COLUMN_ALIASES = {
  contributorName: ['Name', 'ContributorName'],
  contributionType: ['Type', 'ContributionType'],
  receivedBy: ['Received_By', 'ReceivedBy'],
} as const;

/** A header without these cannot be ingested: fail the run rather than store blanks. */
const REQUIRED_COLUMNS: readonly (string | readonly string[])[] = [
  'FileNumber',
  'Amount',
  'ContributionDate',
  COLUMN_ALIASES.contributorName,
];

/**
 * indianaYears returns the calendar years a scheduled run reads: last year and this one.
 *
 * Last year is not optional. Its file holds the annual report (filed each January), which is
 * the ONLY report an officeholder who is not on this year's ballot files — before 2026-09-24,
 * reading this year alone left every such committee empty. Both years of an even-year cycle
 * normalize into that cycle; in an odd year, last year's file still receives late filings and
 * amendments for the cycle that just ended.
 */
export function indianaYears(now: Date = new Date()): number[] {
  const year = now.getUTCFullYear();
  return [year - 1, year];
}

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
  /** The bulk file the row came from. */
  year: number;
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

/**
 * Records the ETag of the file this run read, per year. Provenance only: nothing sends it
 * back as If-None-Match any more.
 */
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
  /** In-memory ZIP buffer; null when the state has not published a file for the year (404). */
  buffer: Buffer | null;
  etag: string;
}

/**
 * downloadZIP fetches the Indiana annual contribution ZIP for the given year.
 *
 * 🔴 UNCONDITIONAL, ON PURPOSE. It used to send the stored ETag as If-None-Match, and on a 304
 * fetch() returned nothing for EVERY source — runIngestion then wrote a 'completed' run with 0
 * records for each one (488 on 2026-04-03, 618 on 2026-05-01), which since PR #681 tells
 * detectCoverageStatus that no data is owed. It also meant a committee confirmed after the last
 * download got nothing until the state next changed the file. The files are small (2025: 1.8 MB,
 * 2026: 0.8 MB), so reading them every run costs less than either failure.
 *
 * Returns buffer=null on 404: a year with no file yet (early January) is empty, not an error.
 * Any other failure is retried once, then thrown.
 */
async function downloadZIP(year: number): Promise<DownloadResult> {
  const url = zipUrl(year);
  const result = (await doRequest(url)) ?? (await doRequest(url));
  if (result === null) {
    throw new Error(`indiana: downloadZIP year=${year}: HTTP request failed after retry`);
  }
  return result;
}

/**
 * doRequest sends one GET. Returns null on a network error or an unexpected status (the
 * caller retries once), { buffer: null } on 404, and { buffer, etag } on 200.
 */
async function doRequest(url: string): Promise<DownloadResult | null> {
  let response: Response;
  try {
    response = await fetch(url, {
      signal: AbortSignal.timeout(120_000), // 2 min for large ZIP
    });
  } catch {
    return null;
  }

  if (response.status === 404) {
    return { buffer: null, etag: '' };
  }

  if (response.status !== 200) {
    console.error(`[indianaAdapter] unexpected HTTP ${response.status} for ${url}`);
    return null;
  }

  const arrayBuffer = await response.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  const etag = response.headers.get('ETag') ?? '';

  return { buffer, etag };
}

// ---------------------------------------------------------------------------
// CSV Parser — ported from parser.go
// ---------------------------------------------------------------------------

/**
 * stripBOM removes a leading UTF-8 BOM from a string.
 * Common in Windows-generated CSV files from Indiana Campaign Finance portal.
 */
function stripBOM(s: string): string {
  return s.startsWith('﻿') ? s.slice(1) : s;
}

/**
 * parseCSV opens a ZIP buffer, locates the inner CSV by suffix (*ContributionData.csv),
 * and parses it into matched and unmatched slices based on knownFileNumbers.
 *
 * The file is Windows-1252, not UTF-8 (the 2025 file has a bare 0xAE, "®"): decoding it as
 * UTF-8 turned every such byte into U+FFFD.
 *
 * Column positions are determined by the header row — NOT hardcoded indexes.
 * This makes the parser resilient to column reordering across annual exports.
 * A header missing a REQUIRED_COLUMNS entry throws: a renamed column is a run that
 * cannot be trusted, not a column of blanks.
 *
 * A row is "matched" if its FileNumber is in knownFileNumbers.
 * Unmatched rows (completely unknown FileNumbers) are silently dropped.
 */
function parseCSV(
  zipBuffer: Buffer,
  year: number,
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
  let csvContent = iconv.decode(csvEntry.getData(), 'win1252');
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

  for (const required of REQUIRED_COLUMNS) {
    const names = typeof required === 'string' ? [required] : required;
    if (!names.some((n) => colIdx[n] !== undefined)) {
      throw new Error(
        `indiana: parseCSV year=${year}: header has no ${names.join(' / ')} column ` +
        `(header: ${headerRow.join(', ')})`
      );
    }
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
      console.warn(`[indianaAdapter] year=${year} row ${rowNum + 1}: cannot parse Amount "${amountStr}" (skipping row)`);
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
        console.warn(`[indianaAdapter] year=${year} row ${rowNum + 1}: cannot parse ContributionDate "${dateStr}" (using zero time)`);
      }
    }

    const row: ParsedRow = {
      fileNumber,
      committeeType: colGet(record, colIdx, 'CommitteeType'),
      committee: colGet(record, colIdx, 'Committee'),
      candidateName: colGet(record, colIdx, 'CandidateName'),
      contributorType: colGet(record, colIdx, 'ContributorType'),
      contributorName: colGetAny(record, colIdx, COLUMN_ALIASES.contributorName),
      address: colGet(record, colIdx, 'Address'),
      city: colGet(record, colIdx, 'City'),
      state: colGet(record, colIdx, 'State'),
      zip: colGet(record, colIdx, 'Zip'),
      occupation: colGet(record, colIdx, 'Occupation'),
      contributionType: colGetAny(record, colIdx, COLUMN_ALIASES.contributionType),
      description: colGet(record, colIdx, 'Description'),
      amount,
      contributionDate,
      receivedBy: colGetAny(record, colIdx, COLUMN_ALIASES.receivedBy),
      amended: colGet(record, colIdx, 'Amended'),
      rowNumber: rowNum,
      year,
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

/** Returns the value of the first alias the header carries. */
function colGetAny(record: string[], colIdx: Record<string, number>, names: readonly string[]): string {
  const name = names.find((n) => colIdx[n] !== undefined);
  return name === undefined ? '' : colGet(record, colIdx, name);
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

/** Max length of contributions.source_transaction_id (varchar(128)). */
const SOURCE_TX_ID_MAX = 128;

/**
 * transactionKey is a row's source_transaction_id: FileNumber|date|donor|amount, truncated to
 * 128 chars. The donor is part of it, so a blank donor (the column-name bug fixed 2026-09-24)
 * merged different donors' same-day, same-amount gifts into one row.
 */
function transactionKey(fileNumber: string, tranDate: Date, contributorName: string, amount: number): string {
  const dateStr = tranDate.getTime() === 0
    ? '0001-01-01'
    : tranDate.toISOString().slice(0, 10);
  const key = `${fileNumber}|${dateStr}|${contributorName}|${amount.toFixed(2)}`;
  return key.length > SOURCE_TX_ID_MAX ? key.slice(0, SOURCE_TX_ID_MAX) : key;
}

/** withOccurrence keys the n-th row sharing a transactionKey; the first keeps the plain key. */
function withOccurrence(key: string, n: number): string {
  if (n <= 1) return key;
  const suffix = `|#${n}`;
  return key.slice(0, SOURCE_TX_ID_MAX - suffix.length) + suffix;
}

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
  const sourceTxId = transactionKey(fileNumber, tranDate, contributorName, amount);

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
 * writeUnresolved writes rows of needs_research FileNumbers to the
 * transparent_motivations.unresolved_contributions table.
 *
 * This enables backfill in Phase 8: once OrgIds are confirmed, these rows can
 * be promoted to contributions without re-parsing the annual ZIP.
 *
 * runId: the ingestion_runs.id to associate these rows with.
 * Returns count of rows written.
 *
 * Idempotent: a row whose SourceTransactionId (the key normalizeRow would give it) is already
 * queued for the same FileNumber, in any status, is skipped. Until 2026-09-24 every run
 * appended the whole set again — harmless while the adapter ran by hand, not on a schedule.
 * NOTE: This function is NOT part of the SourceAdapter interface — it is
 * Indiana-specific and called by the Indiana ingest handler after RunIngestion.
 */
export async function writeUnresolved(rows: ParsedRow[], runId: number): Promise<number> {
  if (rows.length === 0) return 0;

  // Same keys normalize() would give these rows: occurrence counted per FileNumber.
  const occurrences = new Map<string, number>();
  const keys = rows.map((row) => {
    const base = transactionKey(row.fileNumber, row.contributionDate, row.contributorName, row.amount);
    const n = (occurrences.get(base) ?? 0) + 1;
    occurrences.set(base, n);
    return withOccurrence(base, n);
  });

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
        `($${base}::varchar, $${base + 1}::bigint, $${base + 2}::jsonb, $${base + 3}::int, $${base + 4}::varchar)`
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
        SourceFileYear: row.year,
        SourceTransactionId: keys[i + idx],
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
      SELECT v.adapter_name, v.ingestion_run_id, v.raw_row, v.row_number, v.external_id
      FROM (VALUES ${valuePlaceholders.join(', ')})
        AS v(adapter_name, ingestion_run_id, raw_row, row_number, external_id)
      WHERE NOT EXISTS (
        SELECT 1 FROM transparent_motivations.unresolved_contributions u
        WHERE u.adapter_name = v.adapter_name
          AND u.external_id = v.external_id
          AND u.raw_row->>'SourceTransactionId' = v.raw_row->>'SourceTransactionId'
      )
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
 * Downloads one annual contribution ZIP per requested year, parses each once (caching
 * results by FileNumber), and routes rows to either confirmed contributions or the
 * unresolved queue based on politician_sources research_status.
 *
 * Also implements ETagProvider so runIngestion can record ETag/download metadata.
 */
class IndianaAdapter implements SourceAdapter, ETagProvider {
  private readonly years: number[];

  // Download state
  private prepared = false;
  private etags: { year: number; etag: string }[] = [];
  private downloadedAt: Date | null = null;

  // CSV parse cache — populated by preDownload()
  /** FileNumber -> rows, for research_status='confirmed' FileNumbers, every year in order */
  private parsedCache = new Map<string, ParsedRow[]>();
  /** Rows from needs_research FileNumbers — for writeUnresolved */
  private unmatchedRows: ParsedRow[] = [];

  constructor(years: number[]) {
    if (years.length === 0) {
      throw new Error('indiana: createIndianaAdapter needs at least one year');
    }
    this.years = [...years].sort((a, b) => a - b);
  }

  name(): string {
    return 'indiana';
  }

  // ETagProvider implementation — one ETag per year read, e.g. `2025="a"; 2026="b"`
  getETag(): string | null {
    if (this.etags.length === 0) return null;
    return this.etags.map((e) => `${e.year}=${e.etag}`).join('; ');
  }

  getZIPDownloadedAt(): Date | null {
    return this.downloadedAt;
  }

  /**
   * preDownload reads politician_sources, then downloads and parses every requested year's
   * ZIP, caching the rows of known FileNumbers. Must be called before fetch().
   *
   * Throws on a failure no single source could survive — a download that fails after one
   * retry, an unreadable header, or no year published at all — so a scheduled run exits
   * non-zero instead of writing a "completed" empty run for every source.
   *
   * Only 'confirmed' FileNumbers load; 'needs_research' ones go to the unresolved queue.
   * 'not_applicable' and 'disputed' are the wrong committee, and their rows are dropped.
   */
  async preDownload(): Promise<void> {
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

    const confirmed = new Set<string>();
    const queued = new Set<string>();
    for (const s of sourcesResult.rows) {
      if (s.research_status === 'confirmed') confirmed.add(s.external_id);
      else if (s.research_status === 'needs_research') queued.add(s.external_id);
    }
    const known = new Set([...confirmed, ...queued]);

    this.downloadedAt = new Date();
    let published = 0;

    for (const year of this.years) {
      const { buffer, etag } = await downloadZIP(year);
      if (!buffer) {
        console.warn(`[indianaAdapter] year=${year}: no bulk file published (HTTP 404) — read as empty`);
        continue;
      }
      published++;

      const { matched, totalParsed } = parseCSV(buffer, year, known);
      let toConfirmed = 0;
      let toQueue = 0;
      for (const row of matched) {
        if (confirmed.has(row.fileNumber)) {
          const existing = this.parsedCache.get(row.fileNumber) ?? [];
          existing.push(row);
          this.parsedCache.set(row.fileNumber, existing);
          toConfirmed++;
        } else if (queued.has(row.fileNumber)) {
          this.unmatchedRows.push(row);
          toQueue++;
        }
      }
      console.log(
        `[indianaAdapter] year=${year}: ${totalParsed} total rows, ` +
        `${toConfirmed} rows to confirmed contributions, ${toQueue} rows to unresolved queue, ` +
        `etag=${etag || '(none)'}`
      );

      if (etag) {
        this.etags.push({ year, etag });
        await saveETag(year, etag);
      }
    }

    if (published === 0) {
      throw new Error(`indiana: no bulk file published for any of ${this.years.join(', ')}`);
    }
    this.prepared = true;
  }

  /**
   * fetch returns all confirmed contribution rows for the given PoliticianSource,
   * across every year read.
   */
  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    if (!this.prepared) {
      throw new Error('indiana: fetch called before preDownload');
    }

    const rows = this.parsedCache.get(ps.external_id) ?? [];

    // Convert ParsedRow structs to plain record maps for the SourceAdapter pipeline.
    // Keys keep their historical names (ContributorName, ContributionType, ReceivedBy):
    // backfill-donor-name-normalized.ts and the resolve handler read raw_record by them.
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
      SourceFileYear: row.year,
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
   *
   * A second row with the same key — the same donor giving the same amount on the same day,
   * which the file does carry — gets `|#2` (then `|#3`, ...) instead of being dropped as a
   * duplicate. The count of identical keys does not depend on row order, so the suffix is
   * stable across runs; the first row keeps the plain key.
   */
  async normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult> {
    const contributions: ContributionInsert[] = [];
    let skipped = 0;
    const totalParsed = raw.records.length;
    const occurrences = new Map<string, number>();

    for (const rec of raw.records) {
      const contrib = normalizeRow(rec, ps);
      if (contrib === null) {
        console.warn('[indianaAdapter] normalize: skip row (normalizeRow returned null)');
        skipped++;
        continue;
      }
      const n = (occurrences.get(contrib.source_transaction_id) ?? 0) + 1;
      occurrences.set(contrib.source_transaction_id, n);
      contrib.source_transaction_id = withOccurrence(contrib.source_transaction_id, n);
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
   * getUnmatchedRows returns the rows of needs_research FileNumbers read by preDownload().
   * Used by Indiana ingest handler to call writeUnresolved after RunIngestion.
   */
  getUnmatchedRows(): ParsedRow[] {
    return this.unmatchedRows;
  }

  /** unresolvedCount returns the number of rows queued for the unresolved contributions table. */
  unresolvedCount(): number {
    return this.unmatchedRows.length;
  }

  /** confirmedRowCount returns how many rows preDownload() read for confirmed FileNumbers. */
  confirmedRowCount(): number {
    let n = 0;
    for (const rows of this.parsedCache.values()) n += rows.length;
    return n;
  }
}

// ---------------------------------------------------------------------------
// Factory function
// ---------------------------------------------------------------------------

/**
 * createIndianaAdapter creates an IndianaAdapter that reads the given years' files.
 * A scheduled run passes indianaYears().
 *
 * IMPORTANT: Call adapter.preDownload() before running the ingestion pipeline.
 */
export function createIndianaAdapter(years: number[]): SourceAdapter & ETagProvider & {
  preDownload(): Promise<void>;
  getUnmatchedRows(): ParsedRow[];
  unresolvedCount(): number;
  confirmedRowCount(): number;
} {
  return new IndianaAdapter(years);
}
