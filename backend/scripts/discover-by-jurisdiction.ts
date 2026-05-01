/**
 * discover-by-jurisdiction.ts — Quick-009: Jurisdiction-first Cal-Access discovery.
 *
 * Given --jurisdiction "LOS ANGELES" --year 2026, finds ALL Cal-Access filers
 * whose mailing city matches the jurisdiction, matches each to essentials.politicians
 * by name, seeds confirmed politician_sources for matches, and writes a gaps CSV
 * for unmatched filers (potential missing politicians needing operator review).
 *
 * Idempotent: reseeding is a no-op via
 *   UNIQUE (essentials_politician_id, source_system, external_id) ON CONFLICT DO NOTHING.
 *
 * Usage:
 *   npx tsx scripts/discover-by-jurisdiction.ts --jurisdiction "LOS ANGELES" --year 2026 --dry-run
 *   npx tsx scripts/discover-by-jurisdiction.ts --jurisdiction "LOS ANGELES" --year 2026
 *   npx tsx scripts/discover-by-jurisdiction.ts --jurisdiction "OAKLAND" --year 2026 --dry-run
 *   npx tsx scripts/discover-by-jurisdiction.ts --jurisdiction "LOS ANGELES" --year 2026 --zip /path/to/dbwebexport.zip
 *
 * Flags:
 *   --jurisdiction <string>  REQUIRED. Case-insensitive match vs FILERNAME_CD.CITY.
 *   --year <int>             REQUIRED. Election cycle target year (e.g. 2026).
 *   --dry-run                Skip seeding INSERTs; still produce both CSVs.
 *   --zip <path>             Use local ZIP instead of downloading (reuse cached copy).
 *
 * Safety guards (hardcoded — NOT configurable):
 *   - NEVER inserts into essentials.politicians (read-only against that table)
 *   - NEVER deletes anything
 *   - NEVER filters by office type (jurisdiction-first = all offices covered)
 *   - Double-seeding is blocked by ON CONFLICT DO NOTHING at the DB level
 */

// ---------------------------------------------------------------------------
// JURISDICTION RESOLUTION STRATEGY
//
// Cal-Access ZIP TSV column audit (confirmed by inspection 2026-05-01):
//
//   FILER_TO_FILER_TYPE_CD.TSV:
//     Columns: FILER_ID, FILER_TYPE, ACTIVE, RACE, SESSION_ID, CATEGORY,
//              CATEGORY_TYPE, SUB_CATEGORY, EFFECT_DT, SUB_CATEGORY_TYPE,
//              ELECTION_TYPE, SUB_CATEGORY_A, NYQ_DT, PARTY_CD, COUNTY_CD,
//              DISTRICT_CD
//     COUNTY_CD is a numeric code (e.g. "18033") — not a jurisdiction name.
//     DISTRICT_CD is a numeric code — not a jurisdiction name.
//     NO CITY column in this TSV. Jurisdiction name is NOT available here.
//
//   FILERNAME_CD.TSV:
//     Columns: XREF_FILER_ID, FILER_ID, FILER_TYPE, STATUS, EFFECT_DT,
//              NAML, NAMF, NAMT, NAMS, ADR1, ADR2, CITY, ST, ZIP4, PHON, FAX, EMAIL
//     CITY = filer mailing address city (e.g. "LOS ANGELES", "OAKLAND")
//     This is a mailing address, NOT strictly the district served, but for local
//     candidate committees the mailing address almost always matches the city
//     of candidacy. Accepted as the jurisdiction proxy for v1.
//
//   FILER_FILINGS_CD.TSV:
//     Columns: FILER_ID, FILING_ID, PERIOD_ID, FORM_ID, FILING_SEQUENCE,
//              FILING_DATE, STMNT_TYPE, STMNT_STATUS, SESSION_ID, USER_ID,
//              SPECIAL_AUDIT, FINE_AUDIT, RPT_START, RPT_END, RPT_DATE, FILING_TYPE
//     352MB uncompressed — too large to parse synchronously in a discovery script
//     without blocking Node for many minutes. SKIPPED for year filtering.
//     Fallback used instead: EFFECT_DT year from FILER_TO_FILER_TYPE_CD.
//
//   LOOKUP_CODES_CD.TSV:
//     CODE_TYPE values are numeric ("10", "92", "93"...) — no county name mapping.
//     Not useful for jurisdiction resolution.
//
// FINAL STRATEGY:
//   Primary jurisdiction filter: FILERNAME_CD.CITY case-insensitive match to --jurisdiction
//   Year filter: EFFECT_DT year from FILER_TO_FILER_TYPE_CD in [year-2, year]
//     (year-2 instead of year-1 to cover late filers and multi-year cycles)
//   Name source: FILERNAME_CD.NAMF + NAML (candidate name)
//   No office-type filter: jurisdiction-first = all filer types covered
//
// TRADEOFFS:
//   - Mailing address CITY may miss county-level races (Sheriff, DA, Supervisors)
//     who use a county office address instead of a city address. These appear in
//     the gaps CSV for operator review.
//   - EFFECT_DT year filter is less precise than filing-date filter but avoids
//     loading 352MB synchronously. Future v2 can stream FILER_FILINGS_CD.TSV.
// ---------------------------------------------------------------------------

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import AdmZip from 'adm-zip';
import iconv from 'iconv-lite';
import { parse as parseCsv } from 'csv-parse/sync';

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);

function getArgValue(flag: string): string | null {
  const idx = args.indexOf(flag);
  if (idx === -1 || !args[idx + 1]) return null;
  return args[idx + 1];
}

const jurisdictionArg = getArgValue('--jurisdiction');
const yearArg = getArgValue('--year');
const zipOverride = getArgValue('--zip');
const isDryRun = args.includes('--dry-run');

if (!jurisdictionArg || !yearArg) {
  console.error('ERROR: --jurisdiction and --year are required');
  console.error('');
  console.error('Usage:');
  console.error('  npx tsx scripts/discover-by-jurisdiction.ts --jurisdiction "LOS ANGELES" --year 2026 --dry-run');
  console.error('  npx tsx scripts/discover-by-jurisdiction.ts --jurisdiction "LOS ANGELES" --year 2026');
  console.error('  npx tsx scripts/discover-by-jurisdiction.ts --jurisdiction "OAKLAND" --year 2026 --dry-run');
  console.error('  npx tsx scripts/discover-by-jurisdiction.ts --jurisdiction "LOS ANGELES" --year 2026 --zip /path/to/dbwebexport.zip');
  process.exit(1);
}

const JURISDICTION = jurisdictionArg.trim().toUpperCase();
const TARGET_YEAR = parseInt(yearArg, 10);

if (isNaN(TARGET_YEAR) || TARGET_YEAR < 2000 || TARGET_YEAR > 2100) {
  console.error(`ERROR: --year must be a valid 4-digit year (got: "${yearArg}")`);
  process.exit(1);
}

if (zipOverride && !fs.existsSync(zipOverride)) {
  console.error(`ERROR: --zip file not found: ${zipOverride}`);
  process.exit(1);
}

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// Year window for EFFECT_DT filter — two years back to capture multi-cycle filers
const EFFECT_DT_YEAR_MIN = TARGET_YEAR - 2;

function slugify(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

// ---------------------------------------------------------------------------
// DB pool — always opened (need DB even for matching in dry-run)
// ---------------------------------------------------------------------------

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ---------------------------------------------------------------------------
// TSV types
// ---------------------------------------------------------------------------

interface FilerTypeRow {
  FILER_ID: string;
  EFFECT_DT: string;
  RACE?: string;
  DISTRICT_CD?: string;
  [key: string]: string | undefined;
}

interface FilerNameRow {
  FILER_ID: string;
  EFFECT_DT: string;
  NAML: string;
  NAMF: string;
  CITY?: string;
  ST?: string;
  [key: string]: string | undefined;
}

interface JurisdictionFiler {
  filer_id: string;
  full_name: string;
  first_name: string;
  last_name: string;
  committee_name: string;
  jurisdiction: string;
  last_effect_year: number;
  race_code: string;
  district_code: string;
}

// ---------------------------------------------------------------------------
// Helpers — copied inline from discover-cal-access-candidates.ts (loadTsv, deduplicateByFilerId)
// and discover-la-metro-cal-access.ts (normalize, extractNameParts, escapeCsv)
// ---------------------------------------------------------------------------

function loadTsv<T extends object>(zipBuffer: Buffer, entryPath: string): T[] {
  const zip = new AdmZip(zipBuffer);
  const entry = zip.getEntry(entryPath);
  if (!entry) throw new Error(`Entry not found in ZIP: ${entryPath}`);
  const rawBytes = entry.getData();
  const utf8 = iconv.decode(rawBytes, 'win1252');
  return parseCsv(utf8, {
    delimiter: '\t',
    columns: true,
    relax_column_count: true,
    quote: false,
    skip_empty_lines: true,
    trim: true,
  }) as T[];
}

function deduplicateByFilerId<T extends { FILER_ID: string; EFFECT_DT: string }>(rows: T[]): T[] {
  const map = new Map<string, T>();
  for (const row of rows) {
    const existing = map.get(row.FILER_ID);
    if (!existing || row.EFFECT_DT > existing.EFFECT_DT) {
      map.set(row.FILER_ID, row);
    }
  }
  return Array.from(map.values());
}

function normalize(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '') // strip combining accent marks
    .toLowerCase()
    .replace(/[.,/#!$%^&*;:{}=\-_`~()]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function extractNameParts(fullName: string): { first: string; last: string } | null {
  const cleaned = fullName
    .replace(/^(Dr\.|Mr\.|Ms\.|Mrs\.)\s+/i, '')
    .replace(/\s+(Jr\.|Sr\.|II|III|IV)$/i, '')
    .trim();
  const parts = cleaned.split(/\s+/).filter(Boolean);
  if (parts.length < 2) return null;
  return {
    first: normalize(parts[0]),
    last: normalize(parts[parts.length - 1]),
  };
}

function escapeCsv(s: string): string {
  const str = String(s ?? '');
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

// ---------------------------------------------------------------------------
// Phase A: Load ZIP and extract jurisdiction-filtered filers
// ---------------------------------------------------------------------------

async function loadZipBuffer(): Promise<Buffer> {
  if (zipOverride) {
    console.log(`[ZIP] Loading from local file: ${zipOverride}`);
    const buf = fs.readFileSync(zipOverride);
    console.log(`[ZIP] Loaded (${(buf.length / 1024 / 1024).toFixed(1)} MB)`);
    return buf;
  }

  // Read-only ETag check (does NOT save ETag back — no side effects)
  let storedETag: string | null = null;
  try {
    const etagRes = await pool.query<{ notes: string }>(
      `SELECT notes FROM transparent_motivations.data_source_metadata
       WHERE source_system = 'cal_access_zip_etag' LIMIT 1`
    );
    storedETag = etagRes.rows[0]?.notes ?? null;
  } catch {
    // ETag is optional — ignore error
  }

  const CAL_ACCESS_ZIP_URL = 'https://campaignfinance.cdn.sos.ca.gov/dbwebexport.zip';
  console.log(`[ZIP] Downloading Cal-Access bulk ZIP from ${CAL_ACCESS_ZIP_URL} ...`);
  console.log('[ZIP] This may take several minutes (ZIP ~1.5GB). Use --zip to reuse a cached copy.');

  const headers: Record<string, string> = {};
  if (storedETag) headers['If-None-Match'] = storedETag;

  const response = await fetch(CAL_ACCESS_ZIP_URL, {
    headers,
    signal: AbortSignal.timeout(600_000), // 10 min timeout
  });

  if (response.status === 304) {
    throw new Error(
      '[ZIP] Server returned 304 Not Modified but no local ZIP is cached.\n' +
      'Pass --zip /path/to/dbwebexport.zip to use a previously downloaded file.'
    );
  }
  if (response.status !== 200) {
    throw new Error(`[ZIP] HTTP ${response.status} ${response.statusText}`);
  }

  const buf = Buffer.from(await response.arrayBuffer());
  console.log(`[ZIP] Downloaded (${(buf.length / 1024 / 1024).toFixed(1)} MB)`);
  return buf;
}

function extractJurisdictionFilers(zipBuffer: Buffer): JurisdictionFiler[] {
  // ── Load FILERNAME_CD (has CITY — primary jurisdiction filter + candidate names)
  console.log('\n[Phase A] Loading FILERNAME_CD.TSV (primary jurisdiction + name source)...');
  const filerNameRows = loadTsv<FilerNameRow>(zipBuffer, 'CalAccess/DATA/FILERNAME_CD.TSV');
  console.log(`[Phase A]   Loaded ${filerNameRows.length} rows`);
  if (filerNameRows.length > 0) {
    console.log(`[Phase A]   Columns: ${Object.keys(filerNameRows[0]).join(', ')}`);
  }

  // ── Load FILER_TO_FILER_TYPE_CD (has EFFECT_DT, RACE, DISTRICT_CD for year filter + metadata)
  console.log('[Phase A] Loading FILER_TO_FILER_TYPE_CD.TSV (year filter + race/district metadata)...');
  const filerTypeRows = loadTsv<FilerTypeRow>(zipBuffer, 'CalAccess/DATA/FILER_TO_FILER_TYPE_CD.TSV');
  console.log(`[Phase A]   Loaded ${filerTypeRows.length} rows`);
  if (filerTypeRows.length > 0) {
    console.log(`[Phase A]   Columns: ${Object.keys(filerTypeRows[0]).join(', ')}`);
  }

  // ── FILER_FILINGS_CD year filter skipped (352MB uncompressed, too large for sync parse)
  console.log('[Phase A] Note: FILER_FILINGS_CD.TSV skipped (352MB) — using EFFECT_DT year proxy instead');

  // Deduplicate FILERNAME by FILER_ID (most recent EFFECT_DT wins)
  const dedupedNames = deduplicateByFilerId(filerNameRows);
  console.log(`[Phase A]   Deduped FILERNAME to ${dedupedNames.size ?? dedupedNames.length} unique filers`);

  // Build name map
  const nameMap = new Map<string, FilerNameRow>();
  for (const row of dedupedNames) {
    nameMap.set(row.FILER_ID, row);
  }

  // Deduplicate FILER_TO_FILER_TYPE by FILER_ID (most recent EFFECT_DT wins)
  const dedupedTypes = deduplicateByFilerId(filerTypeRows);
  const typeMap = new Map<string, FilerTypeRow>();
  for (const row of dedupedTypes) {
    typeMap.set(row.FILER_ID, row);
  }
  console.log(`[Phase A]   Deduped FILER_TO_FILER_TYPE to ${typeMap.size} unique filers`);

  const jurisdictionLower = JURISDICTION.toLowerCase();
  const result: JurisdictionFiler[] = [];
  let cityMatches = 0;
  let yearFiltered = 0;
  let noName = 0;

  // Iterate name rows (the ones with CITY) — filter by jurisdiction first
  for (const nameRow of dedupedNames) {
    const city = (nameRow.CITY ?? '').trim().toLowerCase();
    if (city !== jurisdictionLower) continue;

    // Only CA filers (ST='CA' or blank — blank may be CA)
    const state = (nameRow.ST ?? '').trim().toUpperCase();
    if (state && state !== 'CA') continue;

    cityMatches++;

    // Skip blank last name (committee with no candidate)
    const rawLast = (nameRow.NAML ?? '').trim();
    if (!rawLast) { noName++; continue; }

    const rawFirst = (nameRow.NAMF ?? '').trim();

    // Year filter via EFFECT_DT from FILER_TO_FILER_TYPE_CD
    const typeRow = typeMap.get(nameRow.FILER_ID);
    let effectYear = 0;
    if (typeRow?.EFFECT_DT) {
      // EFFECT_DT format: MM/DD/YYYY
      const dtParts = typeRow.EFFECT_DT.split('/');
      if (dtParts.length === 3) {
        effectYear = parseInt(dtParts[2], 10) || 0;
      }
    }

    // Apply year filter — if we have an EFFECT_DT year, use it; if unknown, include (conservative)
    if (effectYear > 0 && effectYear < EFFECT_DT_YEAR_MIN) {
      yearFiltered++;
      continue;
    }

    const fullName = rawFirst ? `${rawFirst} ${rawLast}` : rawLast;

    result.push({
      filer_id: nameRow.FILER_ID,
      full_name: fullName,
      first_name: rawFirst,
      last_name: rawLast,
      committee_name: fullName,
      jurisdiction: JURISDICTION,
      last_effect_year: effectYear,
      race_code: (typeRow?.RACE ?? '0').trim(),
      district_code: (typeRow?.DISTRICT_CD ?? '').trim(),
    });
  }

  console.log(`[Phase A]   Jurisdiction "${JURISDICTION}": ${cityMatches} city matches, ${yearFiltered} filtered by year (<${EFFECT_DT_YEAR_MIN}), ${noName} no-name, ${result.length} usable filers`);
  return result;
}

// ---------------------------------------------------------------------------
// Phase B: Load CA politicians from DB and match filers to politicians
// ---------------------------------------------------------------------------

interface CaPolitician {
  id: string;
  full_name: string;
  normalized: string;
}

async function loadCaPoliticians(): Promise<CaPolitician[]> {
  // Load ALL active CA politicians — NO office-type filter (jurisdiction-first covers all offices).
  // Four paths ensure we catch every politician that could plausibly be in CA:
  //   Path 1: Linked to CA government via offices/chambers/governments (most politicians)
  //   Path 2: Office has representing_state='CA' (less common, covers some edge cases)
  //   Path 3: Has a cal_access politician_source (Cal-Access-discovered, may lack office row)
  //   Path 4: Has a la_socrata politician_source (LA City confirmed politicians)
  //   Path 5: Is linked to an LA-area government by name pattern (catches bare politician rows
  //            added from Socrata/CSV import with no chamber/government linkage yet)
  const res = await pool.query<{ id: string; full_name: string }>(`
    -- Path 1: politicians linked to CA government via chamber chain
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.state = 'CA'
      AND p.is_active = true
      AND p.full_name IS NOT NULL
      AND p.full_name != ''

    UNION

    -- Path 2: offices with representing_state = 'CA'
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    WHERE o.representing_state = 'CA'
      AND p.is_active = true
      AND p.full_name IS NOT NULL
      AND p.full_name != ''

    UNION

    -- Path 3: politicians with a cal_access source (Cal-Access-discovered, may lack office)
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = p.id
    WHERE ps.source_system = 'cal_access'
      AND p.is_active = true
      AND p.full_name IS NOT NULL
      AND p.full_name != ''

    UNION

    -- Path 4: politicians with a la_socrata source (confirmed LA politicians)
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = p.id
    WHERE ps.source_system = 'la_socrata'
      AND p.is_active = true
      AND p.full_name IS NOT NULL
      AND p.full_name != ''

    UNION

    -- Path 5: active politicians with person-like names (2-4 words, <=55 chars) and NO offices.
    -- Catches bare politician rows added from Socrata/CSV/manual entry before office rows exist.
    -- Example: Marissa Roy (LA City Attorney 2026) — active, no office, no sources yet.
    -- Short name + word-count filter excludes committee-name rows (e.g. "ROY FOR CITY ATTORNEY").
    -- requireAllTerms word-boundary matching in Step 2 prevents false positives from this path.
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    WHERE p.is_active = true
      AND p.full_name IS NOT NULL
      AND p.full_name != ''
      AND length(p.full_name) <= 55
      AND array_length(string_to_array(trim(p.full_name), ' '), 1) BETWEEN 2 AND 4
      AND NOT EXISTS (
        SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id
      )

    ORDER BY full_name
  `);
  return res.rows.map(r => ({
    id: r.id,
    full_name: r.full_name,
    normalized: normalize(r.full_name),
  }));
}

type MatchStatus = 'matched' | 'no_match' | 'ambiguous_politician';

interface MatchResult {
  filer: JurisdictionFiler;
  match_status: MatchStatus;
  matched_politicians: CaPolitician[];
}

function matchFilerToPoliticians(filer: JurisdictionFiler, politicians: CaPolitician[]): MatchResult {
  const filerNorm = normalize(filer.full_name);
  const nameParts = extractNameParts(filer.full_name);

  if (!nameParts || nameParts.last.length < 3) {
    return { filer, match_status: 'no_match', matched_politicians: [] };
  }

  const { first, last } = nameParts;

  // Step 1: Exact normalized full-name match (fastest, most precise)
  const exactMatches = politicians.filter(p => p.normalized === filerNorm);
  if (exactMatches.length === 1) return { filer, match_status: 'matched', matched_politicians: exactMatches };
  if (exactMatches.length > 1) return { filer, match_status: 'ambiguous_politician', matched_politicians: exactMatches };

  // Step 2: requireAllTerms — first AND last must both appear as whole words.
  // IMPORTANT: tsx/esbuild compiles '\\b' as backspace (ASCII 8), NOT word boundary.
  // Use String.raw`\b` to get a literal backslash+b that RegExp interprets as \b.
  // Verified by testing: String.raw`\b` + word + String.raw`\b` → /\bword\b/ ✓
  const lastRe = new RegExp(String.raw`\b` + last + String.raw`\b`);
  const firstRe = new RegExp(String.raw`\b` + first + String.raw`\b`);
  const partialMatches = politicians.filter(p => lastRe.test(p.normalized) && firstRe.test(p.normalized));

  if (partialMatches.length === 1) return { filer, match_status: 'matched', matched_politicians: partialMatches };
  if (partialMatches.length > 1) return { filer, match_status: 'ambiguous_politician', matched_politicians: partialMatches };

  return { filer, match_status: 'no_match', matched_politicians: [] };
}

// ---------------------------------------------------------------------------
// Phase C: Seed politician_sources for matched filers (idempotent)
// Reused verbatim from seed-la-metro-from-discovery.ts:seedRow pattern
// ---------------------------------------------------------------------------

type SeedOutcome = 'inserted' | 'promoted' | 'already_confirmed' | 'skipped_dry_run' | 'not_seeded';

async function seedRow(
  politicianId: string,
  filerId: string,
  committeeName: string
): Promise<{ outcome: 'inserted' | 'promoted' | 'already_confirmed'; sourceRowId: string | null }> {
  const notes = JSON.stringify({ committee_name: committeeName, confirmed_by: 'discover-by-jurisdiction.ts' });

  // Attempt INSERT — ON CONFLICT DO NOTHING if triple (politician, cal_access, filer_id) exists
  const insertRes = await pool.query<{ id: string }>(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, 'cal_access', $2, 'confirmed', $3)
     ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING
     RETURNING id`,
    [politicianId, filerId, notes]
  );
  if (insertRes.rows[0]) return { outcome: 'inserted', sourceRowId: insertRes.rows[0].id };

  // Row existed — try to promote needs_research → confirmed
  const updateRes = await pool.query<{ id: string }>(
    `UPDATE transparent_motivations.politician_sources
     SET research_status = 'confirmed', notes = $3, updated_at = NOW()
     WHERE essentials_politician_id = $1
       AND source_system = 'cal_access'
       AND external_id = $2
       AND research_status != 'confirmed'
     RETURNING id`,
    [politicianId, filerId, notes]
  );
  if (updateRes.rows[0]) return { outcome: 'promoted', sourceRowId: updateRes.rows[0].id };

  // Already confirmed — fetch existing row ID
  const existingRes = await pool.query<{ id: string }>(
    `SELECT id FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1
       AND source_system = 'cal_access'
       AND external_id = $2`,
    [politicianId, filerId]
  );
  return { outcome: 'already_confirmed', sourceRowId: existingRes.rows[0]?.id ?? null };
}

// ---------------------------------------------------------------------------
// Phase D: CSV output types and writers
// ---------------------------------------------------------------------------

interface JurisdictionResultRow {
  filer_id: string;
  committee_name: string;
  jurisdiction: string;
  election_year: number;
  candidate_name: string;
  match_status: MatchStatus;
  politician_id: string;
  source_row_id: string;
  outcome: SeedOutcome;
  notes: string;
}

interface GapsRow {
  filer_id: string;
  candidate_name: string;
  committee_name: string;
  jurisdiction: string;
  last_filing_year: number;
  race_code: string;
  district_code: string;
  suggested_action: string;
  notes: string;
}

function writeJurisdictionResultsCSV(rows: JurisdictionResultRow[], outputPath: string): void {
  const header = 'filer_id,committee_name,jurisdiction,election_year,candidate_name,match_status,politician_id,source_row_id,outcome,notes';
  const lines = rows.map(r => [
    escapeCsv(r.filer_id),
    escapeCsv(r.committee_name),
    escapeCsv(r.jurisdiction),
    String(r.election_year),
    escapeCsv(r.candidate_name),
    escapeCsv(r.match_status),
    escapeCsv(r.politician_id),
    escapeCsv(r.source_row_id),
    escapeCsv(r.outcome),
    escapeCsv(r.notes),
  ].join(','));
  fs.writeFileSync(outputPath, [header, ...lines].join('\n'), 'utf8');
}

function writeGapsCSV(rows: GapsRow[], outputPath: string): void {
  const header = 'filer_id,candidate_name,committee_name,jurisdiction,last_filing_year,race_code,district_code,suggested_action,notes';
  const lines = rows.map(r => [
    escapeCsv(r.filer_id),
    escapeCsv(r.candidate_name),
    escapeCsv(r.committee_name),
    escapeCsv(r.jurisdiction),
    String(r.last_filing_year),
    escapeCsv(r.race_code),
    escapeCsv(r.district_code),
    escapeCsv(r.suggested_action),
    escapeCsv(r.notes),
  ].join(','));
  fs.writeFileSync(outputPath, [header, ...lines].join('\n'), 'utf8');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const startMs = Date.now();
  const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-');
  const slug = slugify(JURISDICTION);

  console.log('\n=== discover-by-jurisdiction.ts — Jurisdiction-First Cal-Access Discovery ===');
  console.log(`Jurisdiction:       ${JURISDICTION}`);
  console.log(`Election year:      ${TARGET_YEAR}  (EFFECT_DT filter: >= ${EFFECT_DT_YEAR_MIN})`);
  console.log(`Mode:               ${isDryRun ? 'DRY-RUN (no DB inserts)' : 'LIVE'}`);
  console.log(`ZIP:                ${zipOverride ?? '(download from Cal-Access CDN)'}`);
  console.log('');
  console.log('Jurisdiction resolution: FILERNAME_CD.CITY (mailing address proxy)');
  console.log('Year filter:             FILER_TO_FILER_TYPE_CD.EFFECT_DT (FILER_FILINGS_CD 352MB skipped)');
  console.log('Office-type filter:      NONE (jurisdiction-first = all offices)');
  console.log('');

  // Snapshot before-count for idempotency verification
  const beforeCountRes = await pool.query<{ count: string }>(
    `SELECT COUNT(*)::text AS count FROM transparent_motivations.politician_sources WHERE source_system = 'cal_access'`
  );
  const beforeCount = beforeCountRes.rows[0].count;
  console.log(`[DB] politician_sources[cal_access] before: ${beforeCount}`);

  // ── Phase A: Load ZIP and extract filers ──────────────────────────────────

  const zipBuffer = await loadZipBuffer();
  const filers = extractJurisdictionFilers(zipBuffer);

  if (filers.length === 0) {
    console.warn(`\n[WARN] No filers found for "${JURISDICTION}". Common values: "LOS ANGELES", "OAKLAND", "LONG BEACH".`);
  }

  // ── Phase B: Load politicians and match ───────────────────────────────────

  console.log('\n[Phase B] Loading CA politicians from DB (no office-type filter)...');
  const caPoliticians = await loadCaPoliticians();
  console.log(`[Phase B]   Loaded ${caPoliticians.length} active CA politicians`);

  console.log('[Phase B] Matching filers to politicians...');
  const matchResults: MatchResult[] = filers.map(f => matchFilerToPoliticians(f, caPoliticians));

  const matched = matchResults.filter(r => r.match_status === 'matched');
  const noMatch = matchResults.filter(r => r.match_status === 'no_match');
  const ambiguous = matchResults.filter(r => r.match_status === 'ambiguous_politician');
  console.log(`[Phase B]   matched=${matched.length}  no_match=${noMatch.length}  ambiguous=${ambiguous.length}`);

  // ── Phase C: Seed politician_sources ──────────────────────────────────────

  console.log(`\n[Phase C] Seeding politician_sources${isDryRun ? ' [DRY-RUN — skipping INSERTs]' : ''}...`);

  let countInserted = 0, countPromoted = 0, countAlready = 0, countSkipped = 0;
  const resultRows: JurisdictionResultRow[] = [];

  for (const mr of matchResults) {
    const { filer, match_status, matched_politicians } = mr;
    let politicianId = '';
    let sourceRowId = '';
    let outcome: SeedOutcome = 'not_seeded';
    let notes = '';

    if (match_status === 'matched') {
      const p = matched_politicians[0];
      politicianId = p.id;

      if (isDryRun) {
        outcome = 'skipped_dry_run';
        notes = `matches: ${p.full_name} (${p.id})`;
        countSkipped++;
      } else {
        try {
          const sr = await seedRow(p.id, filer.filer_id, filer.committee_name);
          outcome = sr.outcome;
          sourceRowId = sr.sourceRowId ?? '';
          notes = `matches: ${p.full_name}`;
          if (outcome === 'inserted') countInserted++;
          else if (outcome === 'promoted') countPromoted++;
          else countAlready++;
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          console.error(`  ERROR filer_id=${filer.filer_id}: ${msg}`);
          outcome = 'not_seeded';
          notes = `seed error: ${msg}`;
        }
      }
    } else if (match_status === 'ambiguous_politician') {
      outcome = 'not_seeded';
      notes = 'ambiguous matches: ' + matched_politicians.map(p => `${p.id}(${p.full_name})`).join('; ');
    }

    resultRows.push({
      filer_id: filer.filer_id,
      committee_name: filer.committee_name,
      jurisdiction: filer.jurisdiction,
      election_year: TARGET_YEAR,
      candidate_name: filer.full_name,
      match_status,
      politician_id: politicianId,
      source_row_id: sourceRowId,
      outcome,
      notes,
    });
  }

  // ── Phase D: Write CSVs ────────────────────────────────────────────────────

  const resultsFilename = `jurisdiction-results-${slug}-${TARGET_YEAR}-${timestamp}.csv`;
  const gapsFilename = `gaps-${slug}-${TARGET_YEAR}-${timestamp}.csv`;
  const scriptsDir = path.join(process.cwd(), 'scripts');
  const resultsPath = path.join(scriptsDir, resultsFilename);
  const gapsPath = path.join(scriptsDir, gapsFilename);

  writeJurisdictionResultsCSV(resultRows, resultsPath);

  // Gaps CSV: unmatched + ambiguous
  const gapRows: GapsRow[] = [];
  for (const mr of matchResults) {
    if (mr.match_status === 'matched') continue;
    const { filer, match_status, matched_politicians } = mr;
    const hasFirst = filer.first_name.trim().length > 0;
    const suggestedAction =
      match_status === 'ambiguous_politician'
        ? 'manual review — multiple candidates'
        : hasFirst
          ? 'create new politician'
          : 'create new politician (name needs research)';
    const gapNotes = match_status === 'ambiguous_politician'
      ? 'ambiguous: ' + matched_politicians.map(p => `${p.id}(${p.full_name})`).join('; ')
      : '';
    gapRows.push({
      filer_id: filer.filer_id,
      candidate_name: filer.full_name,
      committee_name: filer.committee_name,
      jurisdiction: filer.jurisdiction,
      last_filing_year: filer.last_effect_year,
      race_code: filer.race_code,
      district_code: filer.district_code,
      suggested_action: suggestedAction,
      notes: gapNotes,
    });
  }
  writeGapsCSV(gapRows, gapsPath);

  // After-count for idempotency check
  const afterCountRes = await pool.query<{ count: string }>(
    `SELECT COUNT(*)::text AS count FROM transparent_motivations.politician_sources WHERE source_system = 'cal_access'`
  );
  const afterCount = afterCountRes.rows[0].count;

  // ── Phase E: Summary ──────────────────────────────────────────────────────

  const elapsed = ((Date.now() - startMs) / 1000).toFixed(1);

  console.log('\n=== SUMMARY ===\n');
  console.log(`  Jurisdiction:            ${JURISDICTION}`);
  console.log(`  Election year:           ${TARGET_YEAR}`);
  console.log(`  Mode:                    ${isDryRun ? 'DRY-RUN' : 'LIVE'}`);
  console.log('');
  console.log(`  Total filers found:      ${filers.length}`);
  console.log(`  ├─ matched:              ${matched.length}`);
  console.log(`  ├─ no_match (gaps):      ${noMatch.length}`);
  console.log(`  └─ ambiguous_politician: ${ambiguous.length}`);
  console.log('');
  console.log('  Seed outcomes:');
  if (isDryRun) {
    console.log(`     skipped_dry_run:     ${countSkipped}`);
  } else {
    console.log(`     inserted:            ${countInserted}`);
    console.log(`     promoted:            ${countPromoted}`);
    console.log(`     already_confirmed:   ${countAlready}`);
  }
  console.log('');
  console.log(`  DB[politician_sources/cal_access]:`);
  console.log(`     before: ${beforeCount}  after: ${afterCount}  delta: ${parseInt(afterCount) - parseInt(beforeCount)}`);
  console.log('');
  console.log(`  Results CSV:  ${resultsPath}`);
  console.log(`  Gaps CSV:     ${gapsPath}`);
  console.log('');
  if (!isDryRun && (countInserted + countPromoted) > 0) {
    console.log('  Next step: ingest Cal-Access contributions for newly confirmed sources.');
    console.log(`  Note: ingest-la-metro-batch.ts uses a "city" column; results CSV has "jurisdiction".`);
    console.log(`  Workaround: copy source_row_ids from ${resultsFilename} where outcome="inserted" or`);
    console.log(`  "promoted" and run the Cal-Access adapter directly, or use a future`);
    console.log(`  ingest-by-source-ids.ts script (see Quick-009 design doc for follow-up).`);
    console.log('');
  }
  console.log(`[discover-by-jurisdiction] Completed in ${elapsed}s`);
}

main()
  .then(async () => { await pool.end(); process.exit(0); })
  .catch(async err => {
    console.error('[discover-by-jurisdiction] Fatal error:', err instanceof Error ? err.stack : String(err));
    await pool.end();
    process.exit(1);
  });
