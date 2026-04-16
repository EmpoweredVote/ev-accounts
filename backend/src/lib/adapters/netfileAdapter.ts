/**
 * netfileAdapter — LA County Netfile (FPPC CA-460) Excel bulk export adapter
 * implementing SourceAdapter.
 *
 * LA County uses ASP.NET WebForms at public.netfile.com/pub2/?aid=LACO.
 * The site exposes year-by-year Excel exports via a WebForms postback:
 *   1. GET the page to collect __VIEWSTATE, __VIEWSTATEGENERATOR, __EVENTVALIDATION + cookies
 *   2. POST with ctl00$phBody$GetExcelAmend and the target year
 *   3. Parse the returned Excel buffer with xlsx (already installed in ev-accounts)
 *
 * Download strategy: lazy singleton — the Excel file for the configured year is
 * downloaded ONCE on first fetch() call, then all rows are cached in memory.
 * Subsequent fetch() calls for different politicians filter from the in-memory cache.
 * This mirrors the calAccessAdapter ZIP-once pattern.
 *
 * FPPC CA-460 field mapping (Schedule A contributions):
 *   Filer_ID    -> politician_sources.external_id (filter key)
 *   Tran_ID     -> composite source_transaction_id
 *   Tran_Amt1   -> amount
 *   Tran_Date   -> contribution_date (JS Date via cellDates:true)
 *   Form_Type   -> must be 'A' (Schedule A only)
 *   Memo_Code   -> skip if present and non-empty
 *
 * Export: createNetfileAdapter(year) — factory function.
 */

import * as XLSX from 'xlsx';
import AdmZip from 'adm-zip';
import { pool } from '../db.js';
import type {
  SourceAdapter,
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

const NETFILE_BASE_URL = 'https://public.netfile.com/pub2/Default.aspx';
const NETFILE_AGENCY = 'LACO';
const SCHEDULE_A_SHEET = 'A-Contributions';
const FORM_TYPE_A = 'A';

// ---------------------------------------------------------------------------
// WebForms postback — GET then POST to download Excel
// ---------------------------------------------------------------------------

/**
 * extractHiddenField extracts a hidden form field value from raw HTML using regex.
 * Matches both id="fieldName" and name="fieldName" patterns with value="..." nearby.
 */
function extractHiddenField(html: string, fieldName: string): string {
  // Match: id="fieldName" ... value="..." or value="..." ... id="fieldName"
  // Also handles name="fieldName" value="..."
  const patterns = [
    new RegExp(`id="${escapeRegex(fieldName)}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`name="${escapeRegex(fieldName)}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`value="([^"]*)"[^>]*id="${escapeRegex(fieldName)}"`, 'i'),
    new RegExp(`value="([^"]*)"[^>]*name="${escapeRegex(fieldName)}"`, 'i'),
  ];

  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match) {
      return match[1] ?? '';
    }
  }

  // ASP.NET VIEWSTATE fields are sometimes very long — try a targeted regex
  const viewstatePattern = new RegExp(`<input[^>]+id="${escapeRegex(fieldName)}"[^>]*value="([^"]*)"`, 'i');
  const vsMatch = html.match(viewstatePattern);
  if (vsMatch) {
    return vsMatch[1] ?? '';
  }

  return '';
}

function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * extractCookies parses Set-Cookie headers from a fetch Response.
 * Returns a semicolon-joined cookie string suitable for a Cookie request header.
 */
function extractCookies(response: Response): string {
  const setCookieHeader = response.headers.get('set-cookie');
  if (!setCookieHeader) return '';

  // Multiple Set-Cookie headers are joined with commas in the Fetch API
  // Each cookie is "name=value; attributes" — we only need name=value pairs
  return setCookieHeader
    .split(/,(?=[^;]+=[^;]+;|[^;]+=)/)
    .map((cookie) => cookie.trim().split(';')[0]?.trim() ?? '')
    .filter(Boolean)
    .join('; ');
}

/**
 * downloadNetfileExcel performs the WebForms GET + POST dance to download
 * the Excel file for the given agency and year.
 *
 * Returns a Buffer containing the raw Excel bytes.
 */
async function downloadNetfileExcel(year: number): Promise<Buffer> {
  const pageUrl = `${NETFILE_BASE_URL}?aid=${NETFILE_AGENCY}`;

  console.log(`[netfileAdapter] GET ${pageUrl} to extract VIEWSTATE...`);

  // Step 1: GET the page to obtain hidden form fields and session cookies
  const getResp = await fetch(pageUrl, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36',
      Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    },
  });

  if (!getResp.ok) {
    throw new Error(`[netfileAdapter] GET page failed: HTTP ${getResp.status}`);
  }

  const html = await getResp.text();
  const cookies = extractCookies(getResp);

  // Extract ASP.NET hidden fields required for postback
  const viewState = extractHiddenField(html, '__VIEWSTATE');
  const viewStateGenerator = extractHiddenField(html, '__VIEWSTATEGENERATOR');
  const eventValidation = extractHiddenField(html, '__EVENTVALIDATION');

  if (!viewState) {
    console.warn('[netfileAdapter] __VIEWSTATE not found in page HTML — postback may fail');
  }

  // Step 2: POST to trigger Excel download
  // NOTE (2026-04-15): Netfile changed the year select field name from
  // 'ctl00$phBody$ddlYear' to 'ctl00$phBody$DateSelect'. The response is
  // now a ZIP containing the XLSX, not a raw XLSX. Handled below.
  const formBody = new URLSearchParams({
    __EVENTTARGET: 'ctl00$phBody$GetExcelAmend',
    __EVENTARGUMENT: '',
    __VIEWSTATE: viewState,
    __VIEWSTATEGENERATOR: viewStateGenerator,
    __EVENTVALIDATION: eventValidation,
    'ctl00$phBody$DateSelect': String(year),
  });

  const postHeaders: Record<string, string> = {
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36',
    'Content-Type': 'application/x-www-form-urlencoded',
    Referer: pageUrl,
    Accept:
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,*/*;q=0.8',
  };

  if (cookies) {
    postHeaders['Cookie'] = cookies;
  }

  console.log(`[netfileAdapter] POST ${pageUrl} — requesting year=${year} Excel export...`);

  const postResp = await fetch(pageUrl, {
    method: 'POST',
    headers: postHeaders,
    body: formBody.toString(),
  });

  if (!postResp.ok) {
    throw new Error(`[netfileAdapter] POST failed: HTTP ${postResp.status}`);
  }

  // Validate Content-Type — if we get HTML back, the postback failed
  const contentType = postResp.headers.get('content-type') ?? '';
  if (contentType.includes('text/html')) {
    throw new Error(
      `[netfileAdapter] POST returned HTML instead of file (year=${year}). ` +
        'Possible causes: year not available, site changed, VIEWSTATE extraction failed. ' +
        `Content-Type: ${contentType}`
    );
  }

  const arrayBuffer = await postResp.arrayBuffer();
  const rawBuffer = Buffer.from(arrayBuffer);

  console.log(
    `[netfileAdapter] Downloaded year=${year} (${(rawBuffer.length / 1024 / 1024).toFixed(1)} MB, ` +
      `content-type=${contentType})`
  );

  // Netfile now returns a ZIP containing the XLSX (as of 2026-04-15).
  // Detect by ZIP magic bytes PK\x03\x04 (0x50 0x4B).
  if (contentType.includes('zip') || (rawBuffer[0] === 0x50 && rawBuffer[1] === 0x4b)) {
    console.log(`[netfileAdapter] Extracting XLSX from ZIP (year=${year})...`);
    const zip = new AdmZip(rawBuffer);
    const entries = zip.getEntries();
    const xlsxEntry = entries.find(
      (e) => e.entryName.toLowerCase().endsWith('.xlsx') && !e.isDirectory
    );
    if (!xlsxEntry) {
      throw new Error(
        `[netfileAdapter] ZIP for year=${year} contains no .xlsx entry. ` +
          `Entries: ${entries.map((e) => e.entryName).join(', ')}`
      );
    }
    const xlsxBuffer = xlsxEntry.getData();
    console.log(
      `[netfileAdapter] Extracted "${xlsxEntry.entryName}" ` +
        `(${(xlsxBuffer.length / 1024 / 1024).toFixed(1)} MB) from ZIP`
    );
    return xlsxBuffer;
  }

  // Legacy: raw XLSX buffer
  return rawBuffer;
}

// ---------------------------------------------------------------------------
// Excel parser — parse XLSX buffer, extract Schedule A rows
// ---------------------------------------------------------------------------

/**
 * parseExcelRows parses the Netfile Excel buffer and returns all Schedule A rows.
 * Filters to Form_Type === 'A' and skips Memo_Code rows.
 */
function parseExcelRows(buffer: Buffer, year: number): Record<string, unknown>[] {
  const workbook = XLSX.read(buffer, { type: 'buffer', cellDates: true });

  const sheetName = SCHEDULE_A_SHEET;
  const ws = workbook.Sheets[sheetName];

  if (!ws) {
    const available = workbook.SheetNames.join(', ');
    throw new Error(
      `[netfileAdapter] Sheet "${sheetName}" not found in year=${year} workbook. ` +
        `Available sheets: ${available}`
    );
  }

  const allRows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });

  // Filter to Schedule A contributions only (Form_Type === 'A')
  const scheduleARows = allRows.filter((row) => row['Form_Type'] === FORM_TYPE_A);

  // Skip rows where Memo_Code is present and non-empty
  const nonMemoRows = scheduleARows.filter((row) => {
    const memoCode = row['Memo_Code'];
    return !memoCode || String(memoCode).trim() === '';
  });

  console.log(
    `[netfileAdapter] year=${year}: total_rows=${allRows.length} ` +
      `schedule_a=${scheduleARows.length} after_memo_filter=${nonMemoRows.length}`
  );

  return nonMemoRows;
}

// ---------------------------------------------------------------------------
// Normalizer — FPPC CA-460 Schedule A → ContributionInsert
// ---------------------------------------------------------------------------

/**
 * normalizeRows converts raw Schedule A records to ContributionInsert structs.
 *
 * election_cycle: rounds UP to next even year from Tran_Date
 *   (same formula as socrataAdapter — odd year +1, even unchanged)
 *
 * source_transaction_id: composite `${Filer_ID}|${Tran_ID}`
 *   Tran_ID is assigned by Netfile and is unique within a filing.
 */
function normalizeRows(
  rows: Record<string, unknown>[],
  ps: PoliticianSource
): { contributions: ContributionInsert[]; skipped: number } {
  const contributions: ContributionInsert[] = [];
  let skipped = 0;

  for (const row of rows) {
    const filerId = String(row['Filer_ID'] ?? '');
    const tranId = String(row['Tran_ID'] ?? '');

    // amount — xlsx cellDates:true; numeric cells are already numbers
    const rawAmount = row['Tran_Amt1'];
    const amount = Number(rawAmount);
    if (!isFinite(amount)) {
      console.warn(
        `[netfileAdapter] skip — Tran_Amt1 parse failed ` +
          `(Filer_ID=${filerId} Tran_ID=${tranId} value=${JSON.stringify(rawAmount)})`
      );
      skipped++;
      continue;
    }

    // contribution_date — xlsx cellDates:true gives JS Date objects for date cells
    const rawDate = row['Tran_Date'];
    let contributionDate: Date | null = null;
    if (rawDate instanceof Date && !isNaN(rawDate.getTime())) {
      contributionDate = rawDate;
    } else if (typeof rawDate === 'string' && rawDate.trim() !== '') {
      // Fallback: parse string date
      const parsed = new Date(rawDate);
      if (!isNaN(parsed.getTime())) {
        contributionDate = parsed;
      }
    }

    if (contributionDate === null) {
      console.warn(
        `[netfileAdapter] skip — Tran_Date parse failed ` +
          `(Filer_ID=${filerId} Tran_ID=${tranId} value=${JSON.stringify(rawDate)})`
      );
      skipped++;
      continue;
    }

    // election_cycle: round UP to next even year
    let cycleYear = contributionDate.getFullYear();
    if (cycleYear % 2 !== 0) {
      cycleYear += 1;
    }
    const electionCycle = String(cycleYear);

    // source_transaction_id: Filer_ID|Tran_ID
    const sourceTransactionId = `${filerId}|${tranId}`;

    const tranNamL = String(row['Tran_NamL'] ?? '');
    const tranNamF = String(row['Tran_NamF'] ?? '');
    const rawDonorName = `${tranNamL} ${tranNamF}`.trim();

    contributions.push({
      politician_source_id: ps.id,
      donor_id: null,
      committee_id: null,
      amount,
      contribution_date: contributionDate,
      election_cycle: electionCycle,
      confidence_level: 'MEDIUM',
      data_source: 'la_county_netfile',
      source_transaction_id: sourceTransactionId,
      raw_record: row,
      donor_name_normalized: normalizeDonorName(rawDonorName || null),
    });
  }

  return { contributions, skipped };
}

// ---------------------------------------------------------------------------
// Upsert — batch insert with ON CONFLICT dedup (copied from socrataAdapter)
// ---------------------------------------------------------------------------

/**
 * upsertContributions writes normalized contributions to the DB idempotently.
 * Uses ON CONFLICT (data_source, source_transaction_id) DO UPDATE SET updated_at = NOW().
 * Processes in batches of 100 for per-batch error isolation.
 * Deduplicates by source_transaction_id before batching.
 */
async function upsertContributions(contributions: ContributionInsert[]): Promise<UpsertResult> {
  if (contributions.length === 0) {
    return { inserted: 0, skipped: 0, unresolved: 0, errors: 0 };
  }

  // Deduplicate by source_transaction_id — prevents "ON CONFLICT DO UPDATE
  // command cannot affect row a second time" when two rows share a conflict key.
  const seen = new Map<string, ContributionInsert>();
  for (const c of contributions) {
    seen.set(c.source_transaction_id, c);
  }
  contributions = Array.from(seen.values());

  let totalInserted = 0;
  let totalSkipped = 0;
  let totalErrors = 0;

  const BATCH_SIZE = 100;

  for (let i = 0; i < contributions.length; i += BATCH_SIZE) {
    const batch = contributions.slice(i, i + BATCH_SIZE);

    try {
      const valuePlaceholders2 = batch.map((_, rowIdx) => {
        const base = rowIdx * 11;
        return `($${base + 1},$${base + 2},$${base + 3},$${base + 4},$${base + 5},$${base + 6},$${base + 7},$${base + 8},$${base + 9},$${base + 10},$${base + 11})`;
      });

      const params2: unknown[] = [];
      for (const c of batch) {
        params2.push(
          c.politician_source_id,
          c.donor_id,
          c.committee_id,
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
          (politician_source_id, donor_id, committee_id, amount, contribution_date,
           election_cycle, confidence_level, data_source, source_transaction_id, raw_record,
           donor_name_normalized)
        VALUES ${valuePlaceholders2.join(',')}
        ON CONFLICT (data_source, source_transaction_id)
          DO UPDATE SET
            updated_at = NOW(),
            donor_name_normalized = EXCLUDED.donor_name_normalized
        RETURNING (xmax = 0) AS inserted`;

      const result = await pool.query<{ inserted: boolean }>(sql, params2);

      for (const row of result.rows) {
        if (row.inserted) {
          totalInserted++;
        } else {
          totalSkipped++;
        }
      }
    } catch (err) {
      console.error(
        `[netfileAdapter] upsert batch error (i=${i}): ${err instanceof Error ? err.message : String(err)}`
      );
      totalErrors++;
    }
  }

  return { inserted: totalInserted, skipped: totalSkipped, unresolved: 0, errors: totalErrors };
}

// ---------------------------------------------------------------------------
// NetfileAdapter class — implements SourceAdapter
// ---------------------------------------------------------------------------

class NetfileAdapter implements SourceAdapter {
  private readonly year: number;

  /**
   * Lazy singleton for the parsed Excel rows.
   * null = not yet downloaded. Promise = download in progress or complete.
   * All calls share the same Promise to avoid concurrent downloads.
   */
  private rowsPromise: Promise<Record<string, unknown>[]> | null = null;

  constructor(year: number) {
    this.year = year;
  }

  name(): string {
    return 'la_county_netfile';
  }

  /**
   * fetch downloads the Netfile Excel file (once, lazily) and returns all rows
   * for the given politician's Filer_ID (from ps.external_id).
   *
   * The lazy download caches all rows in memory so subsequent politicians
   * in the same scheduler run do not re-download the file.
   */
  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    // Lazy download — shared across all fetch() calls for this adapter instance
    if (!this.rowsPromise) {
      this.rowsPromise = downloadNetfileExcel(this.year).then((buffer) =>
        parseExcelRows(buffer, this.year)
      );
    }

    const allRows = await this.rowsPromise;

    // Filter to this politician's Filer_ID
    const filerId = ps.external_id;
    const politicianRows = allRows.filter((row) => String(row['Filer_ID'] ?? '') === filerId);

    console.log(
      `[netfileAdapter] fetch: Filer_ID=${filerId} year=${this.year} ` +
        `rows_for_politician=${politicianRows.length} (all_rows=${allRows.length})`
    );

    return {
      records: politicianRows,
      totalExpected: politicianRows.length,
      totalFetched: politicianRows.length,
    };
  }

  async normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult> {
    const { contributions, skipped } = normalizeRows(raw.records, ps);

    return {
      contributions,
      skipped,
      totalParsed: raw.records.length,
    };
  }

  async upsert(normalized: NormalizeResult): Promise<UpsertResult> {
    return upsertContributions(normalized.contributions);
  }
}

// ---------------------------------------------------------------------------
// Factory export
// ---------------------------------------------------------------------------

/**
 * createNetfileAdapter returns a new NetfileAdapter for the given year.
 * The adapter downloads the LA County Netfile Excel file lazily on first fetch().
 * All politicians processed within the same adapter instance share one download.
 *
 * @param year - Calendar year of the Netfile Excel export (e.g. 2024)
 */
export function createNetfileAdapter(year: number): SourceAdapter {
  return new NetfileAdapter(year);
}
