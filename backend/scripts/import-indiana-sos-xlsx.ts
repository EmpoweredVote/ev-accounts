/**
 * import-indiana-sos-xlsx.ts — Indiana Secretary of State XLSX candidate roster importer.
 *
 * Purpose:
 *   Seeds essentials.politicians rows for any Indiana SoS candidate not already in our DB.
 *   Default scope: Monroe County (the Bloomington pilot's stress-test jurisdiction).
 *
 *   This is DISTINCT from importElectionData.ts, which populates essentials.elections /
 *   races / race_candidates. This script fills the UPSTREAM gap by creating the
 *   essentials.politicians rows that election imports and finance ingest both depend on.
 *
 * Idempotency contract:
 *   Re-running the script with the same XLSX and same flags produces ZERO new rows.
 *   The INSERT uses ON CONFLICT DO NOTHING plus normalized-name lookup to guarantee this.
 *
 * Usage:
 *   npx tsx scripts/import-indiana-sos-xlsx.ts                         # dry-run, Monroe County
 *   npx tsx scripts/import-indiana-sos-xlsx.ts --county Monroe         # dry-run, Monroe County (explicit)
 *   npx tsx scripts/import-indiana-sos-xlsx.ts --county Marion         # dry-run, Marion County (Indianapolis)
 *   npx tsx scripts/import-indiana-sos-xlsx.ts --all-counties          # dry-run, all counties
 *   npx tsx scripts/import-indiana-sos-xlsx.ts --county Monroe --limit 25  # dry-run, first 25 rows
 *   npx tsx scripts/import-indiana-sos-xlsx.ts --county Monroe --commit    # commit mode (no inserts without --insert-unmatched)
 *   npx tsx scripts/import-indiana-sos-xlsx.ts --county Monroe --commit --insert-unmatched  # commit + insert new politicians
 *   npx tsx scripts/import-indiana-sos-xlsx.ts --xlsx-path /tmp/saved.xlsx  # read local file instead of downloading
 *   npx tsx scripts/import-indiana-sos-xlsx.ts --xlsx-url https://...       # override download URL
 *
 * Requires:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * Does NOT touch:
 *   essentials.offices, transparent_motivations.politician_sources, essentials.races,
 *   essentials.race_candidates — those linkages are owned by other scripts
 *   (discover-indiana-candidates.ts, confirm-indiana.ts, importElectionData.ts).
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import * as https from 'https';
import * as http from 'http';
import { Pool } from 'pg';
import { normalizeDonorName } from '../src/lib/adapters/normalizeDonorName.js';

// =============================================================================
// Types
// =============================================================================

interface RawRow {
  office: string;        // from OFFICE column, trimmed
  candidateName: string; // from CANDIDATE NAME, trimmed
  party: string;         // from POLITICAL PARTY, trimmed
  district: string;      // from DISTRICT, trimmed
  dateFiled: string;     // ISO date (YYYY-MM-DD) converted from Excel serial
  rowIndex: number;      // 1-based index within the data rows (for review CSV traceability)
}

type MatchStatus =
  | 'matched_existing'           // Normalized name matches exactly one active politician; has confirmed source
  | 'matched_existing_no_source' // Matches one politician; no confirmed indiana/fec/cal_access source
  | 'matched_ambiguous'          // Normalized name matches 2+ active politicians
  | 'unmatched';                 // No active politician with that normalized name

interface MatchResult {
  status: MatchStatus;
  politicianId: string | null;
}

interface ReviewRow {
  candidateName: string;
  office: string;
  district: string;
  party: string;
  dateFiled: string;
  rowIndex: number;
  matchStatus: MatchStatus;
  politicianId: string | null;
  recommendedAction: string;
}

interface ParsedName {
  firstName: string;
  lastName: string;
  fullName: string;
}

// =============================================================================
// CLI argument parsing
// =============================================================================

const args = process.argv.slice(2);

function getFlag(name: string): string | undefined {
  const idx = args.indexOf(name);
  if (idx === -1) return undefined;
  const val = args[idx + 1];
  if (!val || val.startsWith('--')) return undefined;
  return val;
}

function hasFlag(name: string): boolean {
  return args.includes(name);
}

// Detect unknown flags to reject them with a usage banner
const KNOWN_FLAGS = new Set([
  '--county', '--xlsx-url', '--xlsx-path', '--all-counties',
  '--dry-run', '--commit', '--insert-unmatched', '--limit',
  '--review-csv-dir',
]);

for (const arg of args) {
  if (arg.startsWith('--') && !KNOWN_FLAGS.has(arg)) {
    console.error(`ERROR: Unknown flag: ${arg}`);
    console.error('');
    console.error('Usage: npx tsx scripts/import-indiana-sos-xlsx.ts [options]');
    console.error('');
    console.error('Options:');
    console.error('  --county <name>         County filter (default: Monroe). Case-insensitive substring match.');
    console.error('  --all-counties          Disable county filter entirely.');
    console.error('  --xlsx-url <url>        Override XLSX download URL (skips auto-discovery).');
    console.error('  --xlsx-path <path>      Read a local XLSX file instead of downloading.');
    console.error('  --dry-run               Preview mode (default; no DB writes).');
    console.error('  --commit                Write to DB. Without --insert-unmatched, does NOT insert new politicians.');
    console.error('  --insert-unmatched      When combined with --commit, insert unmatched candidates into essentials.politicians.');
    console.error('  --limit <n>             Process only the first N filtered rows.');
    console.error('  --review-csv-dir <dir>  Directory to write review CSV (default: scripts/ dir).');
    process.exit(1);
  }
}

const countyFilter = getFlag('--county') ?? 'Monroe';
const allCounties = hasFlag('--all-counties');
const xlsxUrl = getFlag('--xlsx-url');
const xlsxPath = getFlag('--xlsx-path');
const isCommit = hasFlag('--commit');
const isDryRun = !isCommit || hasFlag('--dry-run');
const insertUnmatched = hasFlag('--insert-unmatched');
const limitStr = getFlag('--limit');
const limit = limitStr ? parseInt(limitStr, 10) : undefined;
// Resolve __dirname equivalent for ESM/tsx (works on Windows + Linux)
function getScriptDir(): string {
  try {
    // ESM: use import.meta.url
    const u = new URL(import.meta.url);
    const p = u.pathname;
    // On Windows: /C:/foo/bar → C:/foo/bar
    return path.dirname(p.replace(/^\/([A-Z]:)/, '$1'));
  } catch {
    return process.cwd();
  }
}

const SCRIPT_DIR = getScriptDir();
const REVIEW_CSV_DIR = getFlag('--review-csv-dir') ?? SCRIPT_DIR;

// Print resolved flags
console.log('=================================================================');
console.log('import-indiana-sos-xlsx.ts — Indiana SoS Candidate Roster Importer');
console.log('=================================================================');
console.log(`County filter:    ${allCounties ? 'ALL COUNTIES' : countyFilter}`);
console.log(`Mode:             ${isCommit ? 'COMMIT' : 'DRY-RUN'}`);
console.log(`Insert unmatched: ${insertUnmatched}`);
console.log(`Limit:            ${limit ?? 'none'}`);
console.log(`Review CSV dir:   ${REVIEW_CSV_DIR}`);
if (xlsxPath) console.log(`XLSX source:      local file: ${xlsxPath}`);
else if (xlsxUrl) console.log(`XLSX source:      URL override: ${xlsxUrl}`);
else console.log(`XLSX source:      auto-discover from Indiana SoS index page`);
console.log('');

// =============================================================================
// DB pool
// =============================================================================

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// =============================================================================
// Download helpers — redirect-following pattern from importElectionData.ts lines 133-157
// =============================================================================

/** Downloads a file from `url` to `destPath`, following HTTP 301/302 redirects. */
function downloadFile(url: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(destPath);
    const protocol = url.startsWith('https') ? https : http;
    protocol.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        const redirectUrl = response.headers.location!;
        file.close();
        fs.unlinkSync(destPath);
        downloadFile(redirectUrl, destPath).then(resolve).catch(reject);
        return;
      }
      if (response.statusCode !== 200) {
        file.close();
        reject(new Error(`HTTP ${response.statusCode} for ${url}`));
        return;
      }
      response.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      file.close();
      fs.unlink(destPath, () => reject(err));
    });
  });
}

/** Fetches a URL and returns the response body as a string, following redirects. */
function fetchString(url: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    protocol.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        const redirectUrl = response.headers.location!;
        fetchString(redirectUrl).then(resolve).catch(reject);
        return;
      }
      if (response.statusCode !== 200) {
        reject(new Error(`HTTP ${response.statusCode} for ${url}`));
        return;
      }
      let body = '';
      response.on('data', (chunk: Buffer) => { body += chunk.toString(); });
      response.on('end', () => resolve(body));
    }).on('error', reject);
  });
}

// =============================================================================
// XLSX URL discovery
// =============================================================================

const FALLBACK_XLSX_URL = 'https://www.in.gov/sos/elections/files/Primary-Candidate-List-3.25.26.xlsx';
const SOS_INDEX_URL = 'https://www.in.gov/sos/elections/candidate-information/';

/**
 * Fetches the Indiana SoS candidate-information index page and extracts the
 * first href pointing to a Primary-Candidate-List-*.xlsx file.
 * Falls back to the hardcoded 2026 Primary URL if discovery fails.
 */
async function findCurrentXlsxUrl(): Promise<string> {
  try {
    const html = await fetchString(SOS_INDEX_URL);
    const match = html.match(/href="([^"]*\/sos\/elections\/files\/Primary-Candidate-List-[^"]+\.xlsx)"/i);
    if (match) {
      const href = match[1];
      // Resolve relative or absolute
      if (href.startsWith('http')) return href;
      return `https://www.in.gov${href}`;
    }
    console.warn(`[discover] No Primary-Candidate-List-*.xlsx href found on ${SOS_INDEX_URL}`);
    console.warn(`[discover] Using fallback URL: ${FALLBACK_XLSX_URL}`);
    return FALLBACK_XLSX_URL;
  } catch (err: any) {
    console.warn(`[discover] Index page fetch failed (${err.message}). Using fallback URL: ${FALLBACK_XLSX_URL}`);
    return FALLBACK_XLSX_URL;
  }
}

// =============================================================================
// Excel serial date conversion
// =============================================================================

/**
 * Converts an Excel serial date number to an ISO date string (YYYY-MM-DD).
 *
 * Excel's epoch is 1899-12-30 — it accounts for the Lotus 1-2-3 leap-year
 * bug where 1900 was incorrectly treated as a leap year. The offset of
 * Date.UTC(1899, 11, 30) (Dec 30, 1899) corrects for this.
 * See: https://support.microsoft.com/en-us/office/datevalue-function-df8b07d4-7761-4a93-bc33-b7471bbff252
 */
function excelSerialToISO(n: unknown): string {
  if (typeof n !== 'number' || !isFinite(n)) return String(n ?? '');
  const d = new Date(Date.UTC(1899, 11, 30) + n * 86400 * 1000);
  return d.toISOString().slice(0, 10); // YYYY-MM-DD
}

// =============================================================================
// County filter logic
//
// For Monroe County: the district text always includes "Monroe County" as a
// substring (e.g., "Monroe County Recorder", "Monroe County Commissioner, District 1",
// "Bloomington Township Trustee, Monroe County"). We match on "monroe county" to
// avoid false positives from "Monroe Township" in other Indiana counties.
//
// Additionally, state/federal legislative races use the district description
// (e.g., "State Representative District 60", "United States Representative, Ninth
// District") — these match via the district keywords from importElectionData.ts.
//
// For non-Monroe counties, a substring match on "<county> county" is used, e.g.,
// "marion county" for Marion/Indianapolis. This asymmetry is intentional and
// documented here for future maintainers.
// =============================================================================

// State/federal district keywords that cover Monroe County.
// Mirrors the MONROE_COUNTY_DISTRICTS list in importElectionData.ts.
const MONROE_DISTRICT_KEYWORDS = [
  'ninth district',   // IN-09 US House (contains Bloomington)
  'district 40',      // State Senate District 40 (Monroe County)
  'district 060',     // State House District 60 (zero-padded)
  'district 061',     // State House District 61
  'district 062',     // State House District 62
];

function matchesCountyFilter(row: { office: string; district: string }): boolean {
  if (allCounties) return true;

  const officeLower = row.office.toLowerCase();
  const districtLower = row.district.toLowerCase();

  if (countyFilter.toLowerCase() === 'monroe') {
    // Primary match: "monroe county" (with the word "county") anchors to Monroe County
    // and correctly excludes "Monroe Township" rows in other Indiana counties.
    if (officeLower.includes('monroe county') || districtLower.includes('monroe county')) {
      return true;
    }
    // Also capture state/federal legislative races that serve Monroe County
    // (the district field uses full names like "State Representative District 60").
    if (MONROE_DISTRICT_KEYWORDS.some(kw => districtLower.includes(kw) || officeLower.includes(kw))) {
      return true;
    }
    return false;
  }

  // Non-Monroe counties: match "<county> county" (e.g., "marion county")
  const target = `${countyFilter.toLowerCase()} county`;
  return officeLower.includes(target) || districtLower.includes(target);
}

// =============================================================================
// Name parsing helper — copied from discover-indiana-candidates.ts lines 236-290.
// Handles "LAST, FIRST" and "FIRST LAST" forms, strips suffixes Jr/Sr/II/III.
// =============================================================================

const SUFFIXES = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'jr.', 'sr.', '2nd', '3rd']);

function titleCase(s: string): string {
  return s.toLowerCase().split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
}

function parseCandidateName(rawInput: string): ParsedName {
  if (!rawInput || !rawInput.trim()) {
    return { firstName: '', lastName: '(unknown)', fullName: '(unknown)' };
  }

  let raw = rawInput.trim();
  if ((raw.startsWith('"') && raw.endsWith('"')) || (raw.startsWith("'") && raw.endsWith("'"))) {
    raw = raw.slice(1, -1).trim();
  }

  if (!raw) {
    return { firstName: '', lastName: '(unknown)', fullName: '(unknown)' };
  }

  let first = '';
  let last = '';

  if (raw.includes(',')) {
    const commaIdx = raw.indexOf(',');
    const rawLast = raw.slice(0, commaIdx).trim();
    const rawFirst = raw.slice(commaIdx + 1).trim();
    last = titleCase(rawLast);
    const firstTokens = rawFirst.split(/\s+/).filter(Boolean);
    const filtered = firstTokens.filter(t => !SUFFIXES.has(t.toLowerCase().replace('.', '')));
    first = filtered.length > 0 ? titleCase(filtered[0]) : '';
  } else {
    const tokens = raw.trim().split(/\s+/).filter(Boolean);
    if (tokens.length === 0) return { firstName: '', lastName: '(unknown)', fullName: '(unknown)' };
    if (tokens.length === 1) {
      last = titleCase(tokens[0]);
      first = '';
    } else {
      first = titleCase(tokens[0]);
      const lastToken = tokens[tokens.length - 1];
      if (SUFFIXES.has(lastToken.toLowerCase()) && tokens.length > 2) {
        last = titleCase(tokens[tokens.length - 2]);
      } else {
        last = titleCase(lastToken);
      }
    }
  }

  const fullName = first ? `${first} ${last}` : last;
  return { firstName: first, lastName: last, fullName };
}

// =============================================================================
// CSV cell escaping — mirrors seed-la-metro-from-discovery.ts lines 153-164
// =============================================================================

function escapeCsvCell(value: string): string {
  if (value.includes(',') || value.includes('"') || value.includes('\n') || value.includes('\r')) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

// =============================================================================
// Review CSV writer
// =============================================================================

function writeReviewCsv(rows: ReviewRow[], outputPath: string): void {
  const HEADER = 'candidate_name,office,district,party,date_filed,row_index,match_status,politician_id,recommended_action';
  const lines = rows.map(r => [
    escapeCsvCell(r.candidateName),
    escapeCsvCell(r.office),
    escapeCsvCell(r.district),
    escapeCsvCell(r.party),
    escapeCsvCell(r.dateFiled),
    String(r.rowIndex),
    r.matchStatus,
    r.politicianId ?? '',
    escapeCsvCell(r.recommendedAction),
  ].join(','));
  fs.writeFileSync(outputPath, [HEADER, ...lines].join('\n'), 'utf8');
}

const RECOMMENDED_ACTIONS: Record<MatchStatus, string> = {
  matched_existing: '',
  matched_existing_no_source: 'Politician exists; needs Indiana/FEC/Cal-Access source seeding (see quick-009 + Indiana confirm-indiana.ts)',
  matched_ambiguous: 'Multiple politicians match this normalized name — manually disambiguate before linking',
  unmatched: 'New candidate not in DB — review and re-run with --commit --insert-unmatched if confirmed',
};

// =============================================================================
// DB matching helpers
// =============================================================================

/**
 * matchCandidate checks `essentials.politicians` for an existing row matching
 * the given candidate name. We check BOTH the raw XLSX name AND the parsed
 * (normalized) name, because our INSERT stores the parsed form (e.g., "James Graham"
 * for XLSX "James H. (Jim) Graham"). Without this two-pass approach, idempotency
 * breaks on re-runs: the inserted row has `full_name = "James Graham"` but the
 * match query would look for `full_name = "James H. (Jim) Graham"` and miss it.
 */
async function matchCandidate(rawName: string, parsedName: string): Promise<MatchResult> {
  // Build a set of candidate names to try (raw + parsed, deduplicated)
  const namesToTry = rawName.toLowerCase() === parsedName.toLowerCase()
    ? [rawName]
    : [rawName, parsedName];

  // Cheap first-pass: SQL LOWER match(es) to avoid loading all politicians into JS
  const res = await pool.query<{ id: string; full_name: string; is_active: boolean }>(
    `SELECT id, full_name, is_active
     FROM essentials.politicians
     WHERE is_active = true
       AND full_name IS NOT NULL
       AND (${namesToTry.map((_, i) => `LOWER(full_name) = LOWER($${i + 1})`).join(' OR ')})
     LIMIT 10`,
    namesToTry
  );

  // JS-side normalize for precise matching (handles diacritics, hyphens, suffixes)
  // Accept a match on either the raw or parsed normalized form
  const normalizedRaw = normalizeDonorName(rawName);
  const normalizedParsed = normalizeDonorName(parsedName);
  const jsFinalMatches = res.rows.filter(r => {
    const normalizedDb = normalizeDonorName(r.full_name);
    return normalizedDb === normalizedRaw || normalizedDb === normalizedParsed;
  });

  // Deduplicate by id (in case multiple name forms matched the same row)
  const seenIds = new Set<string>();
  const uniqueMatches = jsFinalMatches.filter(r => {
    if (seenIds.has(r.id)) return false;
    seenIds.add(r.id);
    return true;
  });

  if (uniqueMatches.length === 0) {
    return { status: 'unmatched', politicianId: null };
  }
  if (uniqueMatches.length > 1) {
    return { status: 'matched_ambiguous', politicianId: null };
  }

  // Exactly one match — check if it has a confirmed source
  const politicianId = uniqueMatches[0].id;
  const sourceRes = await pool.query<{ source_system: string }>(
    `SELECT source_system
     FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1
       AND source_system IN ('indiana', 'fec', 'cal_access')
       AND research_status = 'confirmed'
     LIMIT 1`,
    [politicianId]
  );

  if ((sourceRes.rowCount ?? 0) === 0) {
    return { status: 'matched_existing_no_source', politicianId };
  }
  return { status: 'matched_existing', politicianId };
}

// =============================================================================
// Insert helpers (only used when --commit --insert-unmatched both set)
// =============================================================================

async function insertPolitician(
  client: import('pg').PoolClient,
  parsed: ParsedName
): Promise<string | null> {
  // SAVEPOINT pattern from discover-indiana-candidates.ts lines 552-595
  const spName = `sp_ins_${parsed.fullName.replace(/[^a-zA-Z0-9]/g, '_').slice(0, 40)}`;
  await client.query(`SAVEPOINT ${spName}`);

  try {
    // NOTE: is_incumbent=false — SoS filing data does NOT distinguish incumbents.
    // Two-pass incumbent matching from importElectionData.ts is out of scope here.
    // NOTE: office_title, representing_state, district_id left NULL — the XLSX
    //   gives us raw strings like "Monroe County Council District 3" that require
    //   a separate mapping pass (backfill-indiana-office-titles.ts pattern).
    const insertRes = await client.query<{ id: string }>(
      `INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, is_vacant)
       VALUES ($1, $2, $3, true, false, false)
       ON CONFLICT DO NOTHING
       RETURNING id`,
      [parsed.fullName, parsed.firstName, parsed.lastName]
    );

    if ((insertRes.rowCount ?? 0) > 0) {
      await client.query(`RELEASE SAVEPOINT ${spName}`);
      return insertRes.rows[0].id;
    }

    // ON CONFLICT hit — find the existing row
    const lookup = await client.query<{ id: string }>(
      `SELECT id FROM essentials.politicians WHERE LOWER(full_name) = LOWER($1) LIMIT 1`,
      [parsed.fullName]
    );
    await client.query(`RELEASE SAVEPOINT ${spName}`);
    return lookup.rows[0]?.id ?? null;
  } catch (err: any) {
    await client.query(`ROLLBACK TO SAVEPOINT ${spName}`);
    console.error(`  ERROR inserting "${parsed.fullName}": ${err.message}`);
    return null;
  }
}

// =============================================================================
// Main
// =============================================================================

async function main(): Promise<void> {
  const startMs = Date.now();

  // ─── Step 1: Resolve XLSX source ────────────────────────────────────────────

  let resolvedXlsxPath: string;
  let resolvedXlsxUrl = '(local file)';

  if (xlsxPath) {
    // Read local file
    if (!fs.existsSync(xlsxPath)) {
      console.error(`ERROR: Local XLSX file not found: ${xlsxPath}`);
      await pool.end();
      process.exit(1);
    }
    resolvedXlsxPath = xlsxPath;
    console.log(`[source] Using local XLSX file: ${xlsxPath}`);
  } else {
    // Download from URL
    if (xlsxUrl) {
      resolvedXlsxUrl = xlsxUrl;
    } else {
      resolvedXlsxUrl = await findCurrentXlsxUrl();
    }
    console.log(`[download] XLSX URL: ${resolvedXlsxUrl}`);

    const tmpPath = path.join(os.tmpdir(), `indiana-sos-${Date.now()}.xlsx`);
    try {
      await downloadFile(resolvedXlsxUrl, tmpPath);
      const sizeBytes = fs.statSync(tmpPath).size;
      console.log(`[download] Saved to: ${tmpPath} (${(sizeBytes / 1024 / 1024).toFixed(2)} MB)`);
      resolvedXlsxPath = tmpPath;
    } catch (err: any) {
      console.error(`ERROR: Failed to download XLSX from ${resolvedXlsxUrl}: ${err.message}`);
      try { fs.unlinkSync(tmpPath); } catch { /* ignore */ }
      await pool.end();
      process.exit(1);
    }
  }

  // ─── Step 2: Parse XLSX ─────────────────────────────────────────────────────

  let xlsx: any;
  try {
    const xlsxModule = await import('xlsx');
    xlsx = (xlsxModule as any).default ?? xlsxModule;
  } catch (err: any) {
    console.error(`ERROR: xlsx package not available: ${err.message}`);
    console.error('Install with: npm install --save-dev xlsx');
    await pool.end();
    process.exit(1);
  }

  const workbook = xlsx.readFile(resolvedXlsxPath);
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];

  // Read as raw arrays so we can find the header row dynamically.
  // The Indiana SoS XLSX structure (confirmed in sample-indiana-candidates.ts + 010-RESEARCH.md):
  //   Row 0: ["ALL COUNTIES", "2026 PRIMARY ELECTION - 5/5/2026"] (metadata)
  //   Row 1: [] (blank)
  //   Row 2: ["OFFICE", "CANDIDATE NAME", "POLITICAL PARTY", "DISTRICT", "DATE FILED"] (header)
  //   Row 3+: data rows
  const rawSheet: string[][] = xlsx.utils.sheet_to_json(worksheet, { header: 1, defval: '' });

  // Find header row by scanning first 10 rows
  let headerRowIdx = -1;
  const colIdx: Record<string, number> = {};

  for (let i = 0; i < Math.min(rawSheet.length, 10); i++) {
    const row = rawSheet[i];
    if (row[0] && String(row[0]).trim().toUpperCase() === 'OFFICE' &&
        row[1] && String(row[1]).trim().toUpperCase() === 'CANDIDATE NAME') {
      headerRowIdx = i;
      for (let j = 0; j < row.length; j++) {
        colIdx[String(row[j]).trim().toUpperCase()] = j;
      }
      break;
    }
  }

  if (headerRowIdx === -1) {
    console.error('ERROR: Could not find header row (OFFICE, CANDIDATE NAME) in the first 10 rows.');
    console.error('First 10 row first cells:');
    for (let i = 0; i < Math.min(rawSheet.length, 10); i++) {
      console.error(`  Row ${i}: ${JSON.stringify((rawSheet[i] ?? []).slice(0, 3))}`);
    }
    await pool.end();
    process.exit(1);
  }

  console.log(`[parse] Header row found at index ${headerRowIdx}`);
  console.log(`[parse] Columns: ${JSON.stringify(colIdx)}`);

  // Parse data rows
  const allRows: RawRow[] = [];
  for (let i = headerRowIdx + 1; i < rawSheet.length; i++) {
    const row = rawSheet[i];
    const office = String(row[colIdx['OFFICE']] ?? '').trim();
    const candidateName = String(row[colIdx['CANDIDATE NAME']] ?? '').trim();
    if (!candidateName) continue; // skip blank rows

    allRows.push({
      office,
      candidateName,
      party: String(row[colIdx['POLITICAL PARTY']] ?? '').trim(),
      district: String(row[colIdx['DISTRICT']] ?? '').trim(),
      dateFiled: excelSerialToISO(row[colIdx['DATE FILED']]),
      rowIndex: i - headerRowIdx, // 1-based
    });
  }

  console.log(`[parse] ${allRows.length} total data rows parsed`);

  // Apply county filter
  const filteredRows = allRows.filter(row => matchesCountyFilter(row));
  const filterLabel = allCounties ? 'ALL' : countyFilter;
  console.log(`[parse] ${allRows.length} total rows; ${filteredRows.length} match county filter "${filterLabel}"`);

  // Apply --limit (before matching, as documented in the plan)
  const processRows = limit ? filteredRows.slice(0, limit) : filteredRows;
  if (limit && filteredRows.length > limit) {
    console.log(`[limit] Processing first ${limit} of ${filteredRows.length} filtered rows`);
  }

  // Count distinct candidates
  const distinctNames = new Set(processRows.map(r => r.candidateName));
  console.log(`[parse] Distinct candidates in scope: ${distinctNames.size}`);
  console.log('');

  // ─── Step 3 (Task 1): Print banner + preview table ───────────────────────────

  if (!isCommit || processRows.length === 0) {
    console.log(`=== DRY-RUN PREVIEW${isCommit ? ' (Task 2 — with matching and DB)' : ' (no matching, no DB writes)'} ===`);
    console.log(`XLSX URL: ${resolvedXlsxUrl}`);
    console.log('');
    const header = '#'.padEnd(6) + 'CANDIDATE NAME'.padEnd(30) + 'OFFICE'.padEnd(35) + 'DISTRICT'.padEnd(45) + 'PARTY'.padEnd(15) + 'FILED';
    console.log(header);
    console.log('-'.repeat(header.length));

    const previewRows = processRows.slice(0, limit ?? 50);
    for (let i = 0; i < previewRows.length; i++) {
      const r = previewRows[i];
      console.log(
        String(i + 1).padEnd(6) +
        r.candidateName.slice(0, 28).padEnd(30) +
        r.office.slice(0, 33).padEnd(35) +
        r.district.slice(0, 43).padEnd(45) +
        r.party.slice(0, 13).padEnd(15) +
        r.dateFiled
      );
    }
    console.log('');
  }

  console.log(`[summary] county="${filterLabel}" rows_in=${allRows.length} rows_filtered=${filteredRows.length} unique_candidates=${distinctNames.size}`);

  if (!isCommit) {
    // Task 1 exit: no DB writes
    console.log('');
    console.log('[summary] Mode: DRY-RUN. Pass --commit to run DB matching and write review CSV.');
    console.log('[summary] Pass --commit --insert-unmatched to also insert new politicians.');
    await pool.end();
    process.exit(0);
  }

  // ─── Step 4 (Task 2): DB matching ───────────────────────────────────────────

  console.log('');
  console.log('=== PHASE 2: DB matching ===');

  const counts = {
    matched_existing: 0,
    matched_existing_no_source: 0,
    matched_ambiguous: 0,
    unmatched: 0,
  };

  const reviewRows: ReviewRow[] = [];
  let insertedCount = 0;

  // Process candidates — deduplicate by normalized name to avoid N queries for the same person
  const processedNames = new Map<string, MatchResult>();

  const candidatesToProcess = processRows;

  if (insertUnmatched && isCommit) {
    // Use a transaction with SAVEPOINT per-row for inserts
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      for (const row of candidatesToProcess) {
        const parsed = parseCandidateName(row.candidateName);
        // Cache key: normalize the parsed name (consistent with what gets inserted)
        const normalizedName = normalizeDonorName(parsed.fullName);

        let matchResult = processedNames.get(normalizedName);
        if (!matchResult) {
          matchResult = await matchCandidate(row.candidateName, parsed.fullName);
          processedNames.set(normalizedName, matchResult);
        }

        counts[matchResult.status]++;

        if (matchResult.status !== 'matched_existing') {
          reviewRows.push({
            candidateName: row.candidateName,
            office: row.office,
            district: row.district,
            party: row.party,
            dateFiled: row.dateFiled,
            rowIndex: row.rowIndex,
            matchStatus: matchResult.status,
            politicianId: matchResult.politicianId,
            recommendedAction: RECOMMENDED_ACTIONS[matchResult.status],
          });
        }

        if (matchResult.status === 'unmatched') {
          const newId = await insertPolitician(client, parsed);
          if (newId) {
            insertedCount++;
            // Update cache so duplicate rows use the correct ID
            processedNames.set(normalizedName, { status: 'unmatched', politicianId: newId });
            console.log(`  INSERT: "${parsed.fullName}" → id=${newId}`);
          }
        }
      }

      await client.query('COMMIT');
    } catch (err: any) {
      await client.query('ROLLBACK');
      console.error(`ERROR: Transaction rolled back: ${err.message}`);
    } finally {
      client.release();
    }
  } else {
    // Dry-run matching or commit-without-insert
    for (const row of candidatesToProcess) {
      const parsed = parseCandidateName(row.candidateName);
      const normalizedName = normalizeDonorName(parsed.fullName);

      let matchResult = processedNames.get(normalizedName);
      if (!matchResult) {
        matchResult = await matchCandidate(row.candidateName, parsed.fullName);
        processedNames.set(normalizedName, matchResult);
      }

      counts[matchResult.status]++;

      if (matchResult.status !== 'matched_existing') {
        reviewRows.push({
          candidateName: row.candidateName,
          office: row.office,
          district: row.district,
          party: row.party,
          dateFiled: row.dateFiled,
          rowIndex: row.rowIndex,
          matchStatus: matchResult.status,
          politicianId: matchResult.politicianId,
          recommendedAction: RECOMMENDED_ACTIONS[matchResult.status],
        });
      }
    }
  }

  // ─── Step 5: Write review CSV ────────────────────────────────────────────────

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const csvFilename = `indiana-sos-review-${timestamp}.csv`;
  const csvOutputPath = path.join(REVIEW_CSV_DIR, csvFilename);

  writeReviewCsv(reviewRows, csvOutputPath);
  console.log(`[review] CSV written: ${path.resolve(csvOutputPath)}`);
  console.log(`[review] Rows in CSV: ${reviewRows.length} (matched_existing rows excluded — those need no action)`);

  // ─── Step 6: Final summary ───────────────────────────────────────────────────

  const durationMs = Date.now() - startMs;

  console.log('');
  console.log('=== IMPORT SUMMARY ===');
  console.log(`Mode:                    ${isCommit ? 'COMMIT' : 'DRY-RUN'}`);
  console.log(`Insert unmatched:        ${insertUnmatched}`);
  console.log(`County filter:           ${allCounties ? 'ALL' : countyFilter}`);
  console.log(`XLSX rows total:         ${allRows.length.toLocaleString()}`);
  console.log(`Filtered to county:      ${filteredRows.length.toLocaleString()}`);
  console.log(`Processed (incl. limit): ${candidatesToProcess.length.toLocaleString()}`);
  console.log(`Distinct candidates:     ${distinctNames.size.toLocaleString()}`);
  console.log('');
  console.log('Match results:');
  console.log(`  matched_existing:           ${counts.matched_existing}`);
  console.log(`  matched_existing_no_source: ${counts.matched_existing_no_source}`);
  console.log(`  matched_ambiguous:           ${counts.matched_ambiguous}`);
  console.log(`  unmatched:                  ${counts.unmatched}`);
  console.log('');
  console.log(`Review CSV:               ${path.resolve(csvOutputPath)}`);
  console.log(`Inserted (this run):      ${insertedCount}${!insertUnmatched ? '  (--insert-unmatched not set — no inserts attempted)' : ''}`);

  if (insertedCount > 0) {
    console.log('');
    console.log(`[followup] Inserted ${insertedCount} new politicians with full_name only. Office/district/state fields left NULL —`);
    console.log('           backfill is a separate concern (see backfill-indiana-office-titles.ts pattern).');
  }

  console.log('');
  console.log(`Completed in ${(durationMs / 1000).toFixed(1)}s`);

  await pool.end();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('[import-indiana-sos-xlsx] Fatal error:', err);
  try { await pool.end(); } catch { /* ignore */ }
  process.exit(1);
});
