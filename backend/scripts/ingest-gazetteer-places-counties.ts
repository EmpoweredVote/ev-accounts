/**
 * ingest-gazetteer-places-counties.ts
 *
 * Downloads the nationwide US Census Gazetteer Places file (incorporated
 * places AND Census Designated Places — they ship in one file, D-08) and the
 * nationwide Gazetteer Counties file, and upserts them into:
 *
 *   essentials.gazetteer_places   (geo_id PK, name, state, lsad, aland_sqmi, intptlat, intptlong)
 *   essentials.gazetteer_counties (geo_id PK, name, state, aland_sqmi, intptlat, intptlong)
 *
 * per migration 1378 (Phase 212 Plan 01). This is the RSLV-02 nationwide
 * place-name fallback source for the resolver's Gazetteer branch.
 *
 * Unlike TIGER shapefile products (cd/cd119, sldu, sldl, place — all per-state
 * only), the Census Gazetteer Files genuinely DO ship as single nationwide
 * zips (RESEARCH.md Pitfall 2): `{vintage}_Gaz_place_national.zip` and
 * `{vintage}_Gaz_counties_national.zip` at www2.census.gov. Do NOT reuse the
 * per-state iteration pattern from load-national-house-districts.ts /
 * load-state-tiger-boundaries.ts for this ingest — that pattern exists
 * because TIGER cd/place/sldu/sldl have no national file; the Gazetteer does.
 *
 * D-09: county subdivisions / townships / MCDs are NEVER downloaded here —
 * that is a separate Gazetteer file (cousub) and out of scope.
 *
 * D-10: vintage is matched to the TIGER vintage already used for the
 * project's geofence loads (the 2024 cd119 set) — this script targets the
 * 2024 Gazetteer vintage by default but resolves the exact header layout
 * from the downloaded file itself at run time (never hardcodes column
 * indexes for an unverified vintage — RESEARCH.md Open Question 3 / A2).
 *
 * D-11: idempotent — INSERT ... ON CONFLICT (geo_id) DO UPDATE. A second,
 * identical run changes zero row counts (net-zero re-run).
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/ingest-gazetteer-places-counties.ts --dry-run
 *   npx tsx scripts/ingest-gazetteer-places-counties.ts
 *
 * This file authors + unit-tests the parsing/upsert-construction logic only
 * (Phase 212 Plan 02). The live run against the production DB happens in
 * Plan 03 — this script must not be invoked against a live DB by this plan.
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import AdmZip from 'adm-zip';
import { pool } from '../src/lib/db.js';

// ─── Constants ────────────────────────────────────────────────────────────────

// Gazetteer vintage matched to the TIGER cd119/2024-era set (D-10). Verify the
// exact current-vintage URL against www2.census.gov at execute time — never
// assume a hardcoded vintage is still current without confirming the file
// downloads successfully (RESEARCH.md Open Question 3).
const GAZETTEER_VINTAGE = '2024';
const GAZETTEER_BASE = 'https://www2.census.gov/geo/docs/maps-data/data/gazetteer';

const PLACES_FILE_NAME = `${GAZETTEER_VINTAGE}_Gaz_place_national.zip`;
const COUNTIES_FILE_NAME = `${GAZETTEER_VINTAGE}_Gaz_counties_national.zip`;
const PLACES_URL = `${GAZETTEER_BASE}/${GAZETTEER_VINTAGE}_Gazetteer/${PLACES_FILE_NAME}`;
const COUNTIES_URL = `${GAZETTEER_BASE}/${GAZETTEER_VINTAGE}_Gazetteer/${COUNTIES_FILE_NAME}`;

const DRY_RUN = process.argv.includes('--dry-run');

// ─── Parsed record shapes ──────────────────────────────────────────────────────

export interface GazetteerPlaceRecord {
  geo_id: string;
  name: string;
  state: string;
  lsad: string;
  aland_sqmi: string;
  intptlat: string;
  intptlong: string;
}

export interface GazetteerCountyRecord {
  geo_id: string;
  name: string;
  state: string;
  aland_sqmi: string;
  intptlat: string;
  intptlong: string;
}

// ─── Header-index resolver ─────────────────────────────────────────────────────

/**
 * Resolve the column index for a logical field name from a tab-delimited
 * header row. Header field names are matched case-insensitively and with
 * surrounding whitespace trimmed (Gazetteer headers occasionally carry
 * trailing padding).
 *
 * Throws if the column is not found — never silently falls back to a
 * hardcoded index (D-09/A2: column layout must be verified, not assumed).
 */
export function resolveHeaderIndex(headerFields: string[], candidates: string[]): number {
  const normalized = headerFields.map((h) => h.trim().toUpperCase());
  for (const candidate of candidates) {
    const idx = normalized.indexOf(candidate.toUpperCase());
    if (idx !== -1) return idx;
  }
  throw new Error(
    `Gazetteer header resolution failed: none of [${candidates.join(', ')}] present in header. ` +
      `Available: [${headerFields.join(', ')}]. This is the vintage/column-drift failure mode ` +
      `(RESEARCH.md Open Question 3 / Assumptions Log A2) — verify the current record layout ` +
      `and add the new variant to the candidate list.`,
  );
}

// ─── Pure line parsers (unit-testable, no DB/network) ──────────────────────────

/**
 * Parse a single tab-delimited Gazetteer Places data line into a record,
 * given the header's own field order (never a hardcoded column index).
 * Returns null for a blank line.
 */
export function parsePlacesLine(
  line: string,
  headerFields: string[],
): GazetteerPlaceRecord | null {
  if (line.trim().length === 0) return null;
  const fields = line.split('\t').map((s) => s.trim());

  const uspsIdx = resolveHeaderIndex(headerFields, ['USPS']);
  const geoidIdx = resolveHeaderIndex(headerFields, ['GEOID']);
  const nameIdx = resolveHeaderIndex(headerFields, ['NAME']);
  const lsadIdx = resolveHeaderIndex(headerFields, ['LSAD']);
  const alandSqmiIdx = resolveHeaderIndex(headerFields, ['ALAND_SQMI']);
  const intptlatIdx = resolveHeaderIndex(headerFields, ['INTPTLAT']);
  const intptlongIdx = resolveHeaderIndex(headerFields, ['INTPTLONG']);

  return {
    geo_id: fields[geoidIdx] ?? '',
    name: fields[nameIdx] ?? '',
    state: fields[uspsIdx] ?? '', // USPS column = state, verbatim (never inferred from name)
    lsad: fields[lsadIdx] ?? '',
    aland_sqmi: fields[alandSqmiIdx] ?? '',
    intptlat: fields[intptlatIdx] ?? '',
    intptlong: fields[intptlongIdx] ?? '',
  };
}

/**
 * Parse a single tab-delimited Gazetteer Counties data line into a record.
 * Same shape as parsePlacesLine minus LSAD/FUNCSTAT (Counties file has no
 * LSAD column).
 */
export function parseCountiesLine(
  line: string,
  headerFields: string[],
): GazetteerCountyRecord | null {
  if (line.trim().length === 0) return null;
  const fields = line.split('\t').map((s) => s.trim());

  const uspsIdx = resolveHeaderIndex(headerFields, ['USPS']);
  const geoidIdx = resolveHeaderIndex(headerFields, ['GEOID']);
  const nameIdx = resolveHeaderIndex(headerFields, ['NAME']);
  const alandSqmiIdx = resolveHeaderIndex(headerFields, ['ALAND_SQMI']);
  const intptlatIdx = resolveHeaderIndex(headerFields, ['INTPTLAT']);
  const intptlongIdx = resolveHeaderIndex(headerFields, ['INTPTLONG']);

  return {
    geo_id: fields[geoidIdx] ?? '',
    name: fields[nameIdx] ?? '',
    state: fields[uspsIdx] ?? '',
    aland_sqmi: fields[alandSqmiIdx] ?? '',
    intptlat: fields[intptlatIdx] ?? '',
    intptlong: fields[intptlongIdx] ?? '',
  };
}

/**
 * Parse a full tab-delimited Gazetteer Places file's text content into
 * records, skipping the header row and any blank lines.
 */
export function parsePlacesFile(fileText: string): GazetteerPlaceRecord[] {
  const lines = fileText.split(/\r?\n/);
  if (lines.length === 0) return [];
  const headerFields = lines[0].split('\t');
  const records: GazetteerPlaceRecord[] = [];
  for (let i = 1; i < lines.length; i++) {
    const record = parsePlacesLine(lines[i], headerFields);
    if (record) records.push(record);
  }
  return records;
}

/**
 * Parse a full tab-delimited Gazetteer Counties file's text content into
 * records, skipping the header row and any blank lines.
 */
export function parseCountiesFile(fileText: string): GazetteerCountyRecord[] {
  const lines = fileText.split(/\r?\n/);
  if (lines.length === 0) return [];
  const headerFields = lines[0].split('\t');
  const records: GazetteerCountyRecord[] = [];
  for (let i = 1; i < lines.length; i++) {
    const record = parseCountiesLine(lines[i], headerFields);
    if (record) records.push(record);
  }
  return records;
}

// ─── Upsert SQL builders (construction-level idempotency guarantee, D-11) ─────
//
// Batched via UNNEST column-arrays (T-212-04 mitigation) — ONE round trip
// upserts an entire batch of N rows, never one round trip per row. The SQL
// shape is fixed regardless of batch size (7 array params for places, 6 for
// counties); the batch size only changes how many elements are inside each
// array, not the query text.

/** Parameterized, batched (UNNEST) upsert SQL for essentials.gazetteer_places — never string-interpolate field values. */
export function buildPlacesUpsertSql(): string {
  return `INSERT INTO essentials.gazetteer_places
       (geo_id, name, state, lsad, aland_sqmi, intptlat, intptlong)
     SELECT * FROM UNNEST(
       $1::text[], $2::text[], $3::text[], $4::text[],
       $5::numeric[], $6::double precision[], $7::double precision[]
     )
     ON CONFLICT (geo_id) DO UPDATE SET
       name = EXCLUDED.name,
       state = EXCLUDED.state,
       lsad = EXCLUDED.lsad,
       aland_sqmi = EXCLUDED.aland_sqmi,
       intptlat = EXCLUDED.intptlat,
       intptlong = EXCLUDED.intptlong`;
}

/** Parameterized, batched (UNNEST) upsert SQL for essentials.gazetteer_counties — never string-interpolate field values. */
export function buildCountiesUpsertSql(): string {
  return `INSERT INTO essentials.gazetteer_counties
       (geo_id, name, state, aland_sqmi, intptlat, intptlong)
     SELECT * FROM UNNEST(
       $1::text[], $2::text[], $3::numeric[], $4::double precision[], $5::double precision[]
     )
     ON CONFLICT (geo_id) DO UPDATE SET
       name = EXCLUDED.name,
       state = EXCLUDED.state,
       aland_sqmi = EXCLUDED.aland_sqmi,
       intptlat = EXCLUDED.intptlat,
       intptlong = EXCLUDED.intptlong`;
}

/** Per-row param tuple, in DB column order (geo_id, name, state, lsad, aland_sqmi, intptlat, intptlong). */
export function placeRecordToParams(r: GazetteerPlaceRecord): unknown[] {
  return [r.geo_id, r.name, r.state, r.lsad, r.aland_sqmi || null, r.intptlat || null, r.intptlong || null];
}

/** Per-row param tuple, in DB column order (geo_id, name, state, aland_sqmi, intptlat, intptlong). */
export function countyRecordToParams(r: GazetteerCountyRecord): unknown[] {
  return [r.geo_id, r.name, r.state, r.aland_sqmi || null, r.intptlat || null, r.intptlong || null];
}

/**
 * Transpose an array of per-row param tuples into column arrays for a
 * batched UNNEST upsert — e.g. [[a1,b1,c1],[a2,b2,c2]] -> [[a1,a2],[b1,b2],[c1,c2]].
 * This is what turns "one round trip per row" into "one round trip per batch".
 */
export function transposeToColumnArrays(rows: unknown[][]): unknown[][] {
  if (rows.length === 0) return [];
  const numCols = rows[0].length;
  const columns: unknown[][] = Array.from({ length: numCols }, () => []);
  for (const row of rows) {
    for (let c = 0; c < numCols; c++) {
      columns[c].push(row[c]);
    }
  }
  return columns;
}

// ─── Download + extract helpers (mirrors load-national-house-districts.ts) ────

function downloadWithRedirects(url: string, destPath: string, redirectDepth = 0): Promise<void> {
  return new Promise((resolve, reject) => {
    if (redirectDepth > 5) {
      return reject(new Error(`Too many redirects (>5) for ${url}`));
    }
    if (fs.existsSync(destPath) && fs.statSync(destPath).size > 0) {
      return resolve(); // silently cached
    }
    if (fs.existsSync(destPath)) {
      fs.unlinkSync(destPath);
    }
    const file = fs.createWriteStream(destPath);
    https
      .get(url, (response) => {
        if (response.statusCode === 301 || response.statusCode === 302) {
          file.close();
          if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
          const location = response.headers.location;
          if (!location) {
            return reject(new Error(`Redirect response (${response.statusCode}) for ${url} missing Location header`));
          }
          return downloadWithRedirects(location, destPath, redirectDepth + 1).then(resolve).catch(reject);
        }
        if (response.statusCode !== 200) {
          file.close();
          if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
          return reject(new Error(`HTTP ${response.statusCode} for ${url}`));
        }
        response.pipe(file);
        file.on('finish', () => {
          file.close();
          resolve();
        });
      })
      .on('error', (err) => {
        if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
        reject(err);
      });
  });
}

function extractZip(zipPath: string, destDir: string): void {
  fs.mkdirSync(destDir, { recursive: true });
  const zip = new AdmZip(zipPath);
  zip.extractAllTo(destDir, true);
}

/** Find the single .txt data file inside an extracted Gazetteer zip. */
function findGazetteerTextFile(extractDir: string): string {
  const files = fs.readdirSync(extractDir);
  const txtFile = files.find((f) => f.toLowerCase().endsWith('.txt'));
  if (!txtFile) {
    throw new Error(`No .txt file found in ${extractDir}. Files: ${files.join(', ')}`);
  }
  return path.join(extractDir, txtFile);
}

// ─── Batched upsert (T-212-04: batched inserts, single connection from shared pool) ──

// ~30k+ places nationwide — batch to keep round trips + statement size sane.
const BATCH_SIZE = 1000;

interface UpsertCounts {
  affected: number;
  batches: number;
}

function chunk<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

async function upsertPlaces(records: GazetteerPlaceRecord[]): Promise<UpsertCounts> {
  const sql = buildPlacesUpsertSql();
  const counts: UpsertCounts = { affected: 0, batches: 0 };
  const validRecords = records.filter((r) => r.geo_id); // never write a row with no geo_id
  for (const batch of chunk(validRecords, BATCH_SIZE)) {
    const rows = batch.map(placeRecordToParams);
    const columnArrays = transposeToColumnArrays(rows);
    const result = await pool.query(sql, columnArrays);
    counts.affected += result.rowCount ?? 0;
    counts.batches++;
  }
  return counts;
}

async function upsertCounties(records: GazetteerCountyRecord[]): Promise<UpsertCounts> {
  const sql = buildCountiesUpsertSql();
  const counts: UpsertCounts = { affected: 0, batches: 0 };
  const validRecords = records.filter((r) => r.geo_id);
  for (const batch of chunk(validRecords, BATCH_SIZE)) {
    const rows = batch.map(countyRecordToParams);
    const columnArrays = transposeToColumnArrays(rows);
    const result = await pool.query(sql, columnArrays);
    counts.affected += result.rowCount ?? 0;
    counts.batches++;
  }
  return counts;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

export async function main(): Promise<void> {
  console.log('[ingest-gazetteer-places-counties] Nationwide Census Gazetteer Places + Counties ingest');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const tmpDir = path.join(process.cwd(), '.tmp-gazetteer');
  fs.mkdirSync(tmpDir, { recursive: true });

  // Places
  const placesZipPath = path.join(tmpDir, PLACES_FILE_NAME);
  const placesExtractDir = path.join(tmpDir, 'places');
  console.log(`  Downloading ${PLACES_URL} ...`);
  await downloadWithRedirects(PLACES_URL, placesZipPath);
  if (!fs.existsSync(placesExtractDir)) extractZip(placesZipPath, placesExtractDir);
  const placesTextPath = findGazetteerTextFile(placesExtractDir);
  const placesText = fs.readFileSync(placesTextPath, 'latin1');
  const placeRecords = parsePlacesFile(placesText);
  console.log(`  Parsed ${placeRecords.length} Places records (incorporated places + CDPs).`);

  // Counties
  const countiesZipPath = path.join(tmpDir, COUNTIES_FILE_NAME);
  const countiesExtractDir = path.join(tmpDir, 'counties');
  console.log(`  Downloading ${COUNTIES_URL} ...`);
  await downloadWithRedirects(COUNTIES_URL, countiesZipPath);
  if (!fs.existsSync(countiesExtractDir)) extractZip(countiesZipPath, countiesExtractDir);
  const countiesTextPath = findGazetteerTextFile(countiesExtractDir);
  const countiesText = fs.readFileSync(countiesTextPath, 'latin1');
  const countyRecords = parseCountiesFile(countiesText);
  console.log(`  Parsed ${countyRecords.length} Counties records.`);

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no DB writes performed.');
    console.log(`  Would upsert ${placeRecords.length} places, ${countyRecords.length} counties.`);
    return;
  }

  try {
    console.log('  Upserting places (batched via UNNEST, idempotent ON CONFLICT (geo_id) DO UPDATE)...');
    const placeCounts = await upsertPlaces(placeRecords);
    console.log(`  Places upserted: ${placeCounts.affected} rows across ${placeCounts.batches} batches`);

    console.log('  Upserting counties (batched via UNNEST, idempotent ON CONFLICT (geo_id) DO UPDATE)...');
    const countyCounts = await upsertCounties(countyRecords);
    console.log(`  Counties upserted: ${countyCounts.affected} rows across ${countyCounts.batches} batches`);

    console.log('\n=== Summary ===');
    console.log(`  gazetteer_places upserted:   ${placeCounts.affected} rows (${placeCounts.batches} batches)`);
    console.log(`  gazetteer_counties upserted: ${countyCounts.affected} rows (${countyCounts.batches} batches)`);
    console.log('\nIngest complete. Re-running this script is idempotent (D-11) — expect 0 net-new rows.');
    console.log('\nVerify with:');
    console.log(`  SELECT COUNT(*) FROM essentials.gazetteer_places;`);
    console.log(`  SELECT COUNT(*) FROM essentials.gazetteer_counties;`);
  } finally {
    await pool.end();
  }
}

// Only auto-run when executed directly (`npx tsx scripts/ingest-gazetteer-places-counties.ts ...`).
// Guards against side effects (DB connect, process.exit) when this module is
// imported for unit testing pure helpers (parsePlacesLine, parseCountiesLine, etc).
const isMainModule = (() => {
  try {
    return import.meta.url === `file://${process.argv[1]}`;
  } catch {
    return false;
  }
})();
if (isMainModule) {
  main().catch((err) => {
    console.error('[ingest-gazetteer-places-counties] Fatal error:', err);
    process.exit(1);
  });
}
