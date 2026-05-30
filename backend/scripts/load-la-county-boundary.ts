/**
 * load-la-county-boundary.ts
 *
 * Downloads the TIGER/Line 2024 national county shapefile and inserts the
 * Los Angeles County, CA boundary (GEOID 06037, MTFCC G4020) into
 * essentials.geofence_boundaries.
 *
 * This boundary is required for the browse-by-area PostGIS intersection query
 * that cascades from the county down to find all city, council-district, and
 * school-district boundaries within LA County — and therefore all the
 * politicians assigned to those districts.
 *
 * Without this row, browse-by-area for LA County returns only the 3 county
 * officers whose districts are directly tagged geo_id='06037'. City Council
 * members, the Mayor, CA senators, etc. do not appear.
 *
 * Usage (from backend/):
 *   npx tsx scripts/load-la-county-boundary.ts
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures idempotency.
 *
 * The national county ZIP (~120MB) is downloaded to the backend/ working
 * directory and deleted after the script completes.
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import * as shapefile from 'shapefile';
import AdmZip from 'adm-zip';
import { Pool } from 'pg';

// ─── Config ──────────────────────────────────────────────────────────────────

const TIGER_URL = 'https://www2.census.gov/geo/tiger/TIGER2024/COUNTY/tl_2024_us_county.zip';
const ZIP_NAME  = 'tl_2024_us_county.zip';
const DIR_NAME  = 'tl_2024_us_county';
const WORK_DIR  = path.resolve(process.cwd()); // backend/

const TARGET_STATEFP  = '06';  // California
const TARGET_COUNTYFP = '037'; // Los Angeles County
const TARGET_GEOID    = '06037';
const TARGET_MTFCC    = 'G4020';

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── DB Pool ─────────────────────────────────────────────────────────────────

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

function downloadFile(url: string, dest: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (fs.existsSync(dest)) {
      console.log(`  Already downloaded: ${path.basename(dest)}`);
      return resolve();
    }
    console.log(`  Downloading ${url} ...`);
    const file = fs.createWriteStream(dest);
    https.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        file.close();
        fs.unlinkSync(dest);
        return downloadFile(response.headers.location!, dest).then(resolve).catch(reject);
      }
      if (response.statusCode !== 200) {
        file.close();
        fs.unlinkSync(dest);
        return reject(new Error(`HTTP ${response.statusCode} for ${url}`));
      }
      let downloaded = 0;
      response.on('data', (chunk: Buffer) => {
        downloaded += chunk.length;
        process.stdout.write(`\r  Downloaded: ${(downloaded / 1024 / 1024).toFixed(1)} MB`);
      });
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        process.stdout.write('\n');
        resolve();
      });
    }).on('error', (err) => {
      if (fs.existsSync(dest)) fs.unlinkSync(dest);
      reject(err);
    });
  });
}

function extractZip(zipPath: string, destDir: string): void {
  console.log(`  Extracting to ${path.basename(destDir)}/ ...`);
  fs.mkdirSync(destDir, { recursive: true });
  const zip = new AdmZip(zipPath);
  zip.extractAllTo(destDir, true);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log('[load-la-county-boundary] Loading Los Angeles County CA (GEOID 06037, MTFCC G4020)');

  const zipPath    = path.join(WORK_DIR, ZIP_NAME);
  const extractDir = path.join(WORK_DIR, DIR_NAME);
  const shpPath    = path.join(extractDir, `${DIR_NAME}.shp`);
  const dbfPath    = path.join(extractDir, `${DIR_NAME}.dbf`);
  const dirExistedBefore = fs.existsSync(extractDir);

  // ── Step 1: Download ────────────────────────────────────────────────────────

  try {
    await downloadFile(TIGER_URL, zipPath);
  } catch (err) {
    console.error('ERROR downloading county shapefile:', (err as Error).message);
    process.exit(1);
  }

  // ── Step 2: Extract ─────────────────────────────────────────────────────────

  if (!dirExistedBefore) {
    try {
      extractZip(zipPath, extractDir);
    } catch (err) {
      console.error('ERROR extracting ZIP:', (err as Error).message);
      process.exit(1);
    }
  }

  // ── Step 3: Read shapefile and find Los Angeles County ──────────────────────

  console.log(`  Reading shapefile: ${path.basename(shpPath)} ...`);
  let source: shapefile.Source;
  try {
    source = await shapefile.open(shpPath, dbfPath, { encoding: 'utf-8' });
  } catch (err) {
    console.error('ERROR opening shapefile:', (err as Error).message);
    process.exit(1);
  }

  let totalScanned = 0;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let laFeature: any = null;

  let result = await source.read();
  while (!result.done) {
    totalScanned++;
    const feature = result.value;
    const props   = feature.properties as Record<string, string>;

    if (props.STATEFP === TARGET_STATEFP && props.COUNTYFP === TARGET_COUNTYFP) {
      laFeature = feature;
      console.log(`  Found LA County: GEOID=${props.GEOID}, NAME=${props.NAME}, MTFCC=${props.MTFCC}`);
      break;
    }
    result = await source.read();
  }

  // Count remaining records for reporting
  if (laFeature !== null) {
    let remaining = await source.read();
    while (!remaining.done) {
      totalScanned++;
      remaining = await source.read();
    }
  }

  console.log(`  Total county records scanned: ${totalScanned}`);

  if (!laFeature) {
    console.error(`ERROR: LA County (STATEFP=${TARGET_STATEFP}, COUNTYFP=${TARGET_COUNTYFP}) not found in shapefile`);
    process.exit(1);
  }

  // ── Step 4: Insert into essentials.geofence_boundaries ────────────────────

  const props   = laFeature.properties as Record<string, string>;
  const geojson = JSON.stringify(laFeature.geometry);
  const name    = props.NAMELSAD || props.NAME || 'Los Angeles County';
  const mtfcc   = props.MTFCC || TARGET_MTFCC;

  if (mtfcc !== TARGET_MTFCC) {
    console.warn(`  WARNING: Shapefile MTFCC is '${mtfcc}', expected '${TARGET_MTFCC}'. Using '${TARGET_MTFCC}'.`);
  } else {
    console.log(`  Shapefile MTFCC: ${mtfcc} (matches expected G4020)`);
  }

  try {
    const gbResult = await pool.query(`
      INSERT INTO essentials.geofence_boundaries
        (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
      VALUES (
        $1, $2, $3, $4, $5,
        public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326),
        'census_tiger_2024',
        now()
      )
      ON CONFLICT (geo_id, mtfcc) DO NOTHING
    `, [
      TARGET_GEOID,                                              // $1 geo_id
      'ocd-division/country:us/state:ca/county:los_angeles',    // $2 ocd_id
      name,                                                      // $3 name
      TARGET_STATEFP,                                            // $4 state = '06' (FIPS, not 'CA')
      TARGET_MTFCC,                                              // $5 mtfcc = 'G4020'
      geojson,                                                   // $6 geometry GeoJSON
    ]);

    if (gbResult.rowCount && gbResult.rowCount > 0) {
      console.log(`  Inserted LA County boundary (geo_id=${TARGET_GEOID}, mtfcc=${TARGET_MTFCC}).`);
    } else {
      console.log(`  Already exists (geo_id=${TARGET_GEOID}, mtfcc=${TARGET_MTFCC}). Skipped.`);
    }
  } catch (err) {
    console.error('ERROR inserting into geofence_boundaries:', (err as Error).message);
    process.exit(1);
  }

  // ── Step 5: Clean up ────────────────────────────────────────────────────────

  console.log('  Cleaning up temp files ...');
  if (!dirExistedBefore && fs.existsSync(extractDir)) {
    fs.rmSync(extractDir, { recursive: true, force: true });
    console.log(`  Removed: ${DIR_NAME}/`);
  }
  if (fs.existsSync(zipPath)) {
    fs.unlinkSync(zipPath);
    console.log(`  Removed: ${ZIP_NAME}`);
  }

  console.log('\n[load-la-county-boundary] Done.');
  console.log('Verify with:');
  console.log(`  SELECT geo_id, name, state, mtfcc, ST_GeometryType(geometry), ST_SRID(geometry), ST_IsValid(geometry)`);
  console.log(`    FROM essentials.geofence_boundaries WHERE geo_id = '06037' AND mtfcc = 'G4020';`);
  console.log('Then test browse: POST /api/essentials/browse/by-area { "geo_id": "06037", "mtfcc": "G4020" }');
}

main()
  .catch((err) => {
    console.error('[load-la-county-boundary] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
