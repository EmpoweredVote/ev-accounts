/**
 * 1641-al-generate-polygon-import.mts — Phase 164.1-05: Alabama 2026 congressional
 * district polygons → essentials.geofence_boundaries as mtfcc='G5200V26'.
 *
 * PROVENANCE: Alabama Secretary of State "State District Maps"
 * (sos.alabama.gov/alabama-votes/state-district-maps) — "2023_CONGRESSIONAL_PLAN.zip"
 * posted 2026-06-03 (the day after the SCOTUS stay in Milligan v. Allen,
 * 2026-06-02, reinstated the 2023 legislature map / SB5 over the interim
 * court-ordered map), certified 2026-06-10 per the adjacent certification PDF.
 * 7 features, DISTRICT field '1'-'7', GCS NAD83 (degrees).
 *
 * MAP-DIRECTION PROOF (Pitfall 4, captured at execution 2026-07-07): the
 * shapefile's own demographic fields give District 2 F_BLACK = 0.399313
 * (~39.9% — the severe/reinstated map), NOT ~48.7% (the interim map);
 * District 7 remains the single Black-opportunity district (F_BLACK 0.513).
 *
 * NOTE: sos.alabama.gov's TLS chain is missing an intermediate for plain curl
 * and rejects default UAs — download used a browser UA + -k; the map's
 * substance is independently validated by the BVAP figures above and the
 * 1641-verify.sql tiling/area gates.
 *
 * geo_ids 0101-0107 PERSIST; only shapes change. MTFCC='G5200V26' (D-01)
 * keeps every consumer except the elections opt-in join on the old vintage.
 *
 * D-04 / Pitfall 2: the essentials.geo_districts insert is INTENTIONALLY
 * OMITTED — this import touches ONLY essentials.geofence_boundaries.
 * Geometry repaired at insert (ST_CollectionExtract(ST_MakeValid(…),3)).
 * Idempotent: ON CONFLICT (geo_id, mtfcc) DO NOTHING.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/1641-al-generate-polygon-import.mts --dry-run
 *   npx tsx scripts/1641-al-generate-polygon-import.mts
 * The zip must already exist at .tmp-1641-al/al2023.zip (downloaded with a
 * browser UA — see NOTE above); the script downloads it if missing.
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

// ─── Constants ────────────────────────────────────────────────────────────────

const ZIP_URL =
  'https://www.sos.alabama.gov/sites/default/files/06-03-2026/2023_CONGRESSIONAL_PLAN.zip';

const MTFCC      = 'G5200V26';
const SOURCE     = 'al_sos_2026';
const STATE_FIPS = '01';
const EXPECTED   = 7;

const DRY_RUN = process.argv.includes('--dry-run');

// ─── DB Pool ──────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Column resolver (cloned from load-national-house-districts.ts) ──────────

function resolveColumn(record: Record<string, unknown>, candidates: string[]): string {
  for (const c of candidates) {
    if (c in record) return c;
  }
  throw new Error(
    `Column resolution failed: none of [${candidates.join(', ')}] present in record. ` +
    `Available: [${Object.keys(record).join(', ')}].`
  );
}

const DISTRICT_CANDIDATES = ['DISTRICT', 'District', 'district', 'DISTRICT_I', 'DIST_NUM'];

function download(url: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (fs.existsSync(destPath) && fs.statSync(destPath).size > 0) {
      return resolve(); // cached
    }
    const file = fs.createWriteStream(destPath);
    https.get(
      url,
      {
        // sos.alabama.gov rejects default UAs; its chain is also incomplete for
        // strict verification (see header NOTE) — substance validated downstream.
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' },
        rejectUnauthorized: false,
      },
      (response) => {
        if (response.statusCode !== 200) {
          file.close();
          if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
          return reject(new Error(`HTTP ${response.statusCode} for ${url}`));
        }
        response.pipe(file);
        file.on('finish', () => { file.close(); resolve(); });
      }
    ).on('error', (err) => {
      if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
      reject(err);
    });
  });
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[1641-al-generate-polygon-import] AL 2026 congressional districts (2023 plan, SCOTUS-reinstated) → G5200V26');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const tmpDir = path.join(process.cwd(), '.tmp-1641-al');
  fs.mkdirSync(tmpDir, { recursive: true });
  const zipPath = path.join(tmpDir, 'al2023.zip');
  const extractDir = path.join(tmpDir, 'ext');

  await download(ZIP_URL, zipPath);
  if (!fs.existsSync(extractDir)) {
    new AdmZip(zipPath).extractAllTo(extractDir, true);
  }

  const files = fs.readdirSync(extractDir);
  const shpFile = files.find((f) => f.endsWith('.shp'));
  const dbfFile = files.find((f) => f.endsWith('.dbf'));
  if (!shpFile || !dbfFile) {
    throw new Error(`No .shp/.dbf in ${extractDir}. Files: ${files.join(', ')}`);
  }

  const source = await shapefile.open(
    path.join(extractDir, shpFile),
    path.join(extractDir, dbfFile),
    { encoding: 'utf-8' }
  );

  let inserted = 0;
  let alreadyExists = 0;
  const seen = new Set<string>();

  let result = await source.read();
  while (!result.done) {
    const feature = result.value;
    const props = feature.properties as Record<string, unknown>;
    const districtCol = resolveColumn(props, DISTRICT_CANDIDATES);
    const districtNum = Number(String(props[districtCol]).trim());
    if (!Number.isInteger(districtNum) || districtNum < 1 || districtNum > EXPECTED) {
      throw new Error(`Bad district number ${String(props[districtCol])} (expected 1-${EXPECTED})`);
    }
    const geoId = STATE_FIPS + String(districtNum).padStart(2, '0'); // 0101-0107
    if (seen.has(geoId)) {
      throw new Error(`Duplicate district ${geoId} in shapefile`);
    }
    seen.add(geoId);
    const name = `Congressional District ${districtNum}`;

    // Map-direction sentinel (Pitfall 4): hard-fail if District 2's own
    // demographic fields look like the interim (~48.7% BVAP) map.
    if (districtNum === 2) {
      const fBlack = Number(props['F_BLACK']);
      if (Number.isFinite(fBlack) && Math.abs(fBlack - 0.399) > 0.02) {
        throw new Error(
          `AL-2 F_BLACK=${fBlack} — expected ~0.399 (reinstated 2023 map). ` +
          `~0.487 means the WRONG (interim) map was downloaded. Aborting.`
        );
      }
      console.log(`  map-direction check: AL-2 F_BLACK=${fBlack} (~39.9% severe/reinstated map) OK`);
    }

    if (DRY_RUN) {
      console.log(`  [dry-run] geo_id=${geoId} name=${name} mtfcc=${MTFCC} source=${SOURCE}`);
    } else {
      const geomJson = JSON.stringify(feature.geometry);
      const res = await pool.query(
        `INSERT INTO essentials.geofence_boundaries
           (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
         VALUES ($1, NULL, $2, $3, $4,
           ST_CollectionExtract(ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($5)), 4326)), 3),
           $6, now())
         ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
        [geoId, name, STATE_FIPS, MTFCC, geomJson, SOURCE],
      );
      if ((res.rowCount ?? 0) > 0) {
        inserted++;
        console.log(`  inserted geo_id=${geoId} (${name})`);
      } else {
        alreadyExists++;
        console.log(`  already_exists geo_id=${geoId} (${name})`);
      }
    }
    result = await source.read();
  }

  if (seen.size !== EXPECTED) {
    throw new Error(`Expected exactly ${EXPECTED} AL districts, processed ${seen.size}`);
  }

  if (DRY_RUN) {
    console.log(`\nDRY-RUN complete — ${seen.size} AL districts (expected ${EXPECTED}).`);
  } else {
    console.log(`\n=== Summary ===`);
    console.log(`  geofence_boundaries inserted:        ${inserted}`);
    console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
    console.log(`  geo_districts: INTENTIONALLY UNTOUCHED (D-04 no-touch)`);
  }

  await pool.end();
}

main().catch((err) => {
  console.error('[1641-al-generate-polygon-import] Fatal error:', err);
  process.exit(1);
});
