/**
 * load-me-school-boundaries.ts
 *
 * Downloads the Maine TIGER UNSD shapefile from census.gov, filters to the
 * 8 target school districts by GEOID, and inserts
 * G5420 geofence_boundaries rows into essentials.geofence_boundaries.
 *
 * Each district is stored with:
 *   geo_id  = GEOID value directly (e.g. '2307320') — NOT a slug like LAUSD
 *   mtfcc   = 'G5420'
 *   state   = '23' (Maine FIPS)
 *   source  = 'tiger_unsd_me_2024'
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures idempotency.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-me-school-boundaries.ts --dry-run
 *   npx tsx scripts/load-me-school-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as fs from 'fs';
import * as path from 'path';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

// ─── Config ───────────────────────────────────────────────────────────────────

const TIGER_URL    = 'https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_23_unsd.zip';
const MTFCC        = 'G5420';
const STATE        = '23';           // Maine FIPS — geofence_boundaries.state convention
const SOURCE       = 'tiger_unsd_me_2024';
const EXPECTED_COUNT = 8;

// geo_id = GEOID field value directly (e.g. '2307320') — NOT a slug like LAUSD's 'lausd-board-district-N'
// The first 5 GEOIDs verified via NCES CCD district detail pages 2026-06-03.
const TARGET_GEOIDS = new Map<string, string>([
  ['2307320', 'Lewiston Public Schools'],
  ['2302820', 'Bangor School Department'],
  ['2312330', 'South Portland Public Schools'],
  ['2302610', 'Auburn Public Schools'],
  ['2303150', 'Biddeford Public Schools'],
  // Added for CA_0288 (2026-09-24): the three city school boards that were filed on their city's
  // LOCAL (G4110) district. GEOIDs read from tl_2024_23_unsd.dbf (NAME = Portland / Augusta /
  // Westbrook, PK-12).
  ['2309930', 'Portland Public Schools'],
  ['2302640', 'Augusta Public Schools'],
  ['2313560', 'Westbrook School Department'],
]);

const DRY_RUN = process.argv.includes('--dry-run');

const baseName = 'tl_2024_23_unsd';
const tmpRoot  = path.join(process.cwd(), '.tmp-me-school-unsd');
const zipPath  = path.join(tmpRoot, `${baseName}.zip`);
const destDir  = path.join(tmpRoot, baseName);

// ─── DB Pool ──────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Download `url` to `destPath`, following 301/302 redirects.
 * If `destPath` already exists on disk, the download is skipped (cache).
 */
function downloadWithRedirects(url: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (fs.existsSync(destPath)) {
      return resolve();  // cache: skip if already downloaded
    }
    const file = fs.createWriteStream(destPath);
    https.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        file.close();
        if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
        return downloadWithRedirects(response.headers.location!, destPath).then(resolve).catch(reject);
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

/**
 * Extract `zipPath` to `destDir`. Returns a `cleanup()` that deletes destDir
 * only if it didn't pre-exist (so re-runs don't blow away a hand-extracted
 * shapefile cache).
 */
function extractZip(zipPath: string, destDir: string): { cleanup: () => void } {
  const dirExistedBefore = fs.existsSync(destDir);
  fs.mkdirSync(destDir, { recursive: true });
  const zip = new AdmZip(zipPath);
  zip.extractAllTo(destDir, true);
  return {
    cleanup: () => {
      if (!dirExistedBefore && fs.existsSync(destDir)) {
        fs.rmSync(destDir, { recursive: true, force: true });
      }
    },
  };
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-me-school-boundaries] Fetching ME UNSD boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  let cleanup: (() => void) | null = null;

  try {
    // Step 1: Create temp dir and download TIGER UNSD zip
    fs.mkdirSync(tmpRoot, { recursive: true });
    console.log(`\n  Downloading ${TIGER_URL}`);
    await downloadWithRedirects(TIGER_URL, zipPath);
    console.log(`  Download complete (or cache hit): ${zipPath}`);

    // Step 2: Extract zip
    console.log(`\n  Extracting ${baseName}.zip`);
    const extracted = extractZip(zipPath, destDir);
    cleanup = extracted.cleanup;

    // Step 3: Find .shp and .dbf files
    const entries = fs.readdirSync(destDir);
    const shpFile = entries.find((e) => e.toLowerCase().endsWith('.shp'));
    const dbfFile = entries.find((e) => e.toLowerCase().endsWith('.dbf'));
    if (!shpFile || !dbfFile) {
      throw new Error(`Missing .shp or .dbf in extracted directory. Files: ${entries.join(', ')}`);
    }
    const shpPath = path.join(destDir, shpFile);
    const dbfPath = path.join(destDir, dbfFile);
    console.log(`  Found shapefile: ${shpFile}`);

    // Step 4: Open shapefile and filter by GEOID
    const source = await shapefile.open(shpPath, dbfPath, { encoding: 'utf-8' });

    const districtMap = new Map<string, { name: string; geometryJson: string }>();
    let firstFeature = true;

    let result = await source.read();
    while (!result.done) {
      const feature = result.value;
      const props = feature.properties as Record<string, unknown>;

      // Log field names on first feature for diagnostic purposes (Pitfall 6)
      if (firstFeature) {
        firstFeature = false;
        const fieldNames = Object.keys(props);
        console.log(`\n  Shapefile fields (first feature): ${fieldNames.join(', ')}`);
        if (!fieldNames.includes('GEOID')) {
          console.error(`ERROR: 'GEOID' field not found in shapefile. Available: ${fieldNames.join(', ')}`);
          process.exit(1);
        }
      }

      // TIGER 2024 UNSD uses 'GEOID' field — confirmed by load-state-tiger-boundaries.ts LAYER_DISPATCH.unsd
      const geoid = String(props['GEOID'] ?? '');
      if (!TARGET_GEOIDS.has(geoid)) {
        result = await source.read();
        continue;
      }

      const name = TARGET_GEOIDS.get(geoid)!;
      const geometryJson = JSON.stringify(feature.geometry);
      districtMap.set(geoid, { name, geometryJson });
      console.log(`  Found GEOID=${geoid}: ${name}`);

      result = await source.read();
    }

    // Step 5: Assert every target GEOID was found
    if (districtMap.size !== EXPECTED_COUNT) {
      const foundGeoIds = Array.from(districtMap.keys());
      const missingGeoIds = Array.from(TARGET_GEOIDS.keys()).filter(g => !districtMap.has(g));
      console.error(`\nERROR: Expected ${EXPECTED_COUNT} GEOIDs, found ${districtMap.size}.`);
      console.error(`  Found:   ${foundGeoIds.join(', ')}`);
      console.error(`  Missing: ${missingGeoIds.join(', ')}`);
      process.exit(1);
    }

    console.log(`\n  All ${EXPECTED_COUNT} target GEOIDs found (districtMap.size === ${EXPECTED_COUNT})`);

    // Step 6: Insert into geofence_boundaries
    let inserted = 0;
    let skipped  = 0;

    for (const [geoId, { name, geometryJson }] of Array.from(districtMap.entries())) {
      if (DRY_RUN) {
        console.log(`  [dry-run] Would insert: geo_id=${geoId}, name="${name}"`);
        inserted++;
        continue;
      }

      try {
        const insertResult = await pool.query(`
          INSERT INTO essentials.geofence_boundaries
            (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
          VALUES ($1, $2, $3, $4, $5,
            public.ST_ForcePolygonCCW(
              public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326)
            ),
            $7, now())
          ON CONFLICT (geo_id, mtfcc) DO NOTHING
        `, [geoId, geoId, name, STATE, MTFCC, geometryJson, SOURCE]);

        if (insertResult.rowCount && insertResult.rowCount > 0) {
          console.log(`  Inserted: ${geoId} (${name})`);
          inserted++;
        } else {
          console.log(`  Skipped (already exists): ${geoId} (${name})`);
          skipped++;
        }
      } catch (err) {
        console.error(`  ERROR inserting ${geoId}:`, (err as Error).message);
        process.exit(1);
      }
    }

    // Step 7: Summary
    console.log('\n  Summary:');
    console.log(`    Inserted: ${inserted}`);
    console.log(`    Skipped (already existed): ${skipped}`);

    // Step 8: Post-insert verification (not in dry-run)
    if (!DRY_RUN) {
      const verify = await pool.query<{ cnt: string }>(`
        SELECT COUNT(*) AS cnt
        FROM essentials.geofence_boundaries
        WHERE state = $1
          AND mtfcc = $2
          AND source = $3
      `, [STATE, MTFCC, SOURCE]);
      const total = parseInt(verify.rows[0].cnt, 10);
      if (total !== EXPECTED_COUNT) {
        console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows in geofence_boundaries, found ${total}`);
      } else {
        console.log(`  All ${EXPECTED_COUNT} ME school district boundaries loaded successfully.`);
      }
    }

  } finally {
    if (cleanup) cleanup();
  }

  console.log('\n[load-me-school-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-me-school-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
