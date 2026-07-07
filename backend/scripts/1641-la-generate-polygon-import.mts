/**
 * 1641-la-generate-polygon-import.mts — Phase 164.1-05: Louisiana 2026 congressional
 * district polygons → essentials.geofence_boundaries as mtfcc='G5200V26'.
 *
 * PROVENANCE: Louisiana Legislature redistricting site (redist.legis.la.gov),
 * "Shapefile - Act_2_(2026_RS).zip" — SB121 / Act 2 (2026 Regular Session).
 * Download URL (relative-href quirk: resolves against /2026_Files/, NOT the
 * page path): https://redist.legis.la.gov/2026_Files/Act2Congress/Shapefile/
 * Shapefile%20-%20Act_2_%282026_RS%29.zip
 * 6 Polygon features, DISTRICT_I field 1-6, GCS NAD83 (degrees; WGS84-compatible).
 *
 * geo_ids 2201-2206 PERSIST; only shapes change. Rows carry MTFCC='G5200V26'
 * (D-01 vintage discriminator) so only the elections opt-in join resolves
 * against them; the reps feed stays on G5200.
 *
 * D-04 / Pitfall 2: the essentials.geo_districts insert of the analog
 * (load-national-house-districts.ts) is INTENTIONALLY OMITTED. This import
 * touches ONLY essentials.geofence_boundaries.
 *
 * Geometry is repaired at insert (ST_CollectionExtract(ST_MakeValid(…),3)) —
 * same guard that caught the TNMap district-3 ring self-intersection.
 *
 * Idempotent: ON CONFLICT (geo_id, mtfcc) DO NOTHING.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/1641-la-generate-polygon-import.mts --dry-run
 *   npx tsx scripts/1641-la-generate-polygon-import.mts
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
  'https://redist.legis.la.gov/2026_Files/Act2Congress/Shapefile/' +
  'Shapefile%20-%20Act_2_%282026_RS%29.zip';

const MTFCC      = 'G5200V26';
const SOURCE     = 'la_legis_2026';
const STATE_FIPS = '22';
const EXPECTED   = 6;

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

// ─── Primitives (cloned from load-national-house-districts.ts) ───────────────

function resolveColumn(record: Record<string, unknown>, candidates: string[]): string {
  for (const c of candidates) {
    if (c in record) return c;
  }
  throw new Error(
    `Column resolution failed: none of [${candidates.join(', ')}] present in record. ` +
    `Available: [${Object.keys(record).join(', ')}].`
  );
}

const DISTRICT_CANDIDATES = ['DISTRICT_I', 'DISTRICT', 'District_I', 'DISTRICTID', 'DIST_NUM'];

function downloadWithRedirects(url: string, destPath: string, redirectDepth = 0): Promise<void> {
  return new Promise((resolve, reject) => {
    if (redirectDepth > 5) {
      return reject(new Error(`Too many redirects (>5) for ${url}`));
    }
    if (fs.existsSync(destPath) && fs.statSync(destPath).size > 0) {
      return resolve(); // cached
    }
    if (fs.existsSync(destPath)) {
      fs.unlinkSync(destPath);
    }
    const file = fs.createWriteStream(destPath);
    https.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        file.close();
        if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
        const location = response.headers.location;
        if (!location) {
          return reject(new Error(`Redirect (${response.statusCode}) for ${url} missing Location`));
        }
        return downloadWithRedirects(location, destPath, redirectDepth + 1).then(resolve).catch(reject);
      }
      if (response.statusCode !== 200) {
        file.close();
        if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
        return reject(new Error(`HTTP ${response.statusCode} for ${url}`));
      }
      response.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
      reject(err);
    });
  });
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[1641-la-generate-polygon-import] LA 2026 congressional districts (SB121/Act 2) → G5200V26');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const tmpDir = path.join(process.cwd(), '.tmp-1641-la');
  fs.mkdirSync(tmpDir, { recursive: true });
  const zipPath = path.join(tmpDir, 'act2.zip');
  const extractDir = path.join(tmpDir, 'ext');

  await downloadWithRedirects(ZIP_URL, zipPath);
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
    const geoId = STATE_FIPS + String(districtNum).padStart(2, '0'); // 2201-2206
    if (seen.has(geoId)) {
      throw new Error(`Duplicate district ${geoId} in shapefile`);
    }
    seen.add(geoId);
    const name = `Congressional District ${districtNum}`;

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
    throw new Error(`Expected exactly ${EXPECTED} LA districts, processed ${seen.size}`);
  }

  if (DRY_RUN) {
    console.log(`\nDRY-RUN complete — ${seen.size} LA districts (expected ${EXPECTED}).`);
  } else {
    console.log(`\n=== Summary ===`);
    console.log(`  geofence_boundaries inserted:        ${inserted}`);
    console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
    console.log(`  geo_districts: INTENTIONALLY UNTOUCHED (D-04 no-touch)`);
  }

  await pool.end();
}

main().catch((err) => {
  console.error('[1641-la-generate-polygon-import] Fatal error:', err);
  process.exit(1);
});
