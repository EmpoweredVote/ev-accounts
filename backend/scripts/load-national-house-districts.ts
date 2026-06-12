/**
 * load-national-house-districts.ts
 *
 * Downloads per-state TIGER 2024 CD119 shapefiles for all 50 states + DC and
 * imports every district into:
 *
 *   essentials.geofence_boundaries  geo_id=GEOID, mtfcc='G5200', state=STATEFP
 *   essentials.geo_districts         layer='us_house', geoid=GEOID
 *
 * Note: The TIGER 2024 national single-file (tl_2024_us_cd119.zip) does not
 * exist. TIGER publishes per-state files: tl_2024_{FIPS}_cd119.zip.
 * This script iterates all 50 states + DC (51 files total).
 *
 * Both inserts are idempotent (ON CONFLICT DO NOTHING).
 * CA rows (52 already imported in Phase 69-71) will be silently skipped.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-national-house-districts.ts --dry-run
 *   npx tsx scripts/load-national-house-districts.ts
 *
 * Deviation note: Plan specified tl_2024_us_cd119.zip (single national file)
 * but Census does not publish that file. Per-state files are the correct approach
 * and match how load-state-tiger-boundaries.ts works.
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

// ─── Constants ────────────────────────────────────────────────────────────────

const TIGER_BASE = 'https://www2.census.gov/geo/tiger/TIGER2024/CD';
const MTFCC      = 'G5200';
const LAYER      = 'us_house';
const SOURCE     = 'census_tiger_2024';
// Skip codes for non-voting/placeholder districts.
// NOTE: '00' is intentionally NOT in this set. At-large states (AK, DE, MT,
// ND, SD, VT, WY) use CD119FP='00' for their single voting House member.
// ZZ, ZZZ, 000 are TIGER placeholder codes for non-voting territories — those
// should be skipped. Removing '00' from the plan's SKIP_CODES set is a bug fix.
const SKIP_CODES = new Set(['ZZ', 'ZZZ', '000']);
const EXPECTED_MIN = 435;

// 50 states only. DC (FIPS 11) and territories (60=AS, 66=GU, 69=MP, 72=PR, 78=VI)
// are excluded — their delegates are non-voting and have no matching NATIONAL_LOWER
// district records in essentials.districts.
const STATE_FIPS_CODES: string[] = [
  '01', '02', '04', '05', '06', '08', '09', '10', '12',
  '13', '15', '16', '17', '18', '19', '20', '21', '22', '23',
  '24', '25', '26', '27', '28', '29', '30', '31', '32', '33',
  '34', '35', '36', '37', '38', '39', '40', '41', '42', '44',
  '45', '46', '47', '48', '49', '50', '51', '53', '54', '55',
  '56',
];

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

// ─── Column resolver (handles TIGER vintage drift) ────────────────────────────

/**
 * Resolve a logical column name to whichever physical dbf field is present.
 * Throws if none of the candidates match.
 */
function resolveColumn(record: Record<string, unknown>, candidates: string[]): string {
  for (const c of candidates) {
    if (c in record) return c;
  }
  throw new Error(
    `Column resolution failed: none of [${candidates.join(', ')}] present in record. ` +
    `Available: [${Object.keys(record).join(', ')}]. ` +
    `This is the NAMELSAD/GEOID column drift failure mode — add the new variant to the candidate list.`
  );
}

const GEOID_CANDIDATES    = ['GEOID', 'GEOID20', 'GEOID10'];
const CD119FP_CANDIDATES  = ['CD119FP', 'CDFP', 'CD118FP'];
const NAMELSAD_CANDIDATES = ['NAMELSAD', 'NAMELSAD20', 'NAMELSAD10', 'NAMELSAD_1'];
const STATEFP_CANDIDATES  = ['STATEFP', 'STATEFP20', 'STATEFP10'];

// ─── downloadWithRedirects (copied verbatim from load-state-tiger-boundaries.ts) ──

function downloadWithRedirects(url: string, destPath: string, redirectDepth = 0): Promise<void> {
  return new Promise((resolve, reject) => {
    if (redirectDepth > 5) {
      return reject(new Error(`Too many redirects (>5) for ${url}`));
    }
    // Cache gate: skip if file exists AND is non-zero (zero = incomplete download)
    if (fs.existsSync(destPath) && fs.statSync(destPath).size > 0) {
      return resolve(); // silently cached
    }
    // Remove stale zero-byte file before re-downloading
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
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
      reject(err);
    });
  });
}

// ─── extractZip (copied verbatim from load-state-tiger-boundaries.ts) ────────

function extractZip(zipPath: string, destDir: string): void {
  fs.mkdirSync(destDir, { recursive: true });
  const zip = new AdmZip(zipPath);
  zip.extractAllTo(destDir, true);
}

// ─── streamShapefile (copied verbatim from load-state-tiger-boundaries.ts) ───

async function streamShapefile(
  shpPath: string,
  dbfPath: string,
  onRecord: (geom: unknown, props: Record<string, unknown>) => Promise<void>,
): Promise<void> {
  const source = await shapefile.open(shpPath, dbfPath, { encoding: 'utf-8' });
  let result = await source.read();
  while (!result.done) {
    const feature = result.value;
    await onRecord(feature.geometry, feature.properties as Record<string, unknown>);
    result = await source.read();
  }
}

// ─── Process a single state FIPS ──────────────────────────────────────────────

interface StateCounts {
  inserted_boundary: number;
  inserted_geo: number;
  skipped: number;
  already_exists: number;
  processed: number;
}

async function processStateFips(
  fips: string,
  tmpDir: string,
  dryRun: boolean,
): Promise<StateCounts> {
  const fileName = `tl_2024_${fips}_cd119.zip`;
  const url      = `${TIGER_BASE}/${fileName}`;
  const zipPath  = path.join(tmpDir, fileName);
  const extractDir = path.join(tmpDir, `tl_2024_${fips}_cd119`);

  // Download (cached)
  await downloadWithRedirects(url, zipPath);

  // Extract
  if (!fs.existsSync(extractDir)) {
    extractZip(zipPath, extractDir);
  }

  // Find .shp and .dbf
  const files = fs.readdirSync(extractDir);
  const shpFile = files.find(f => f.endsWith('.shp'));
  const dbfFile = files.find(f => f.endsWith('.dbf'));
  if (!shpFile || !dbfFile) {
    throw new Error(`FIPS ${fips}: no .shp or .dbf in ${extractDir}. Files: ${files.join(', ')}`);
  }

  const counts: StateCounts = {
    inserted_boundary: 0,
    inserted_geo: 0,
    skipped: 0,
    already_exists: 0,
    processed: 0,
  };

  let firstRecord = true;

  await streamShapefile(
    path.join(extractDir, shpFile),
    path.join(extractDir, dbfFile),
    async (geometry, props) => {
      if (firstRecord && dryRun) {
        firstRecord = false;
        console.log(`    Columns: ${Object.keys(props).join(', ')}`);
      }
      firstRecord = false;

      const geoidCol    = resolveColumn(props, GEOID_CANDIDATES);
      const cd119fpCol  = resolveColumn(props, CD119FP_CANDIDATES);
      const namelsadCol = resolveColumn(props, NAMELSAD_CANDIDATES);
      const statefpCol  = resolveColumn(props, STATEFP_CANDIDATES);

      const geoid   = String(props[geoidCol]    ?? '').trim();
      const cd119fp = String(props[cd119fpCol]  ?? '').trim();
      const name    = String(props[namelsadCol] ?? '').trim();
      const state   = geoid.substring(0, 2);  // FIPS prefix e.g. '06'

      // Suppress unused variable warning
      void props[statefpCol];

      if (SKIP_CODES.has(cd119fp)) {
        counts.skipped++;
        if (dryRun) console.log(`    [dry-run] SKIP GEOID=${geoid} CD119FP=${cd119fp} NAME=${name}`);
        return;
      }

      counts.processed++;

      if (dryRun) {
        console.log(`    [dry-run] GEOID=${geoid} CD119FP=${cd119fp} NAME=${name}`);
        return;
      }

      const geomJson = JSON.stringify(geometry);

      // INSERT into essentials.geofence_boundaries
      const bResult = await pool.query(
        `INSERT INTO essentials.geofence_boundaries
           (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
         VALUES ($1, NULL, $2, $3, $4,
           ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($5)), 4326),
           $6, now())
         ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
        [geoid, name, state, MTFCC, geomJson, SOURCE],
      );
      if ((bResult.rowCount ?? 0) > 0) {
        counts.inserted_boundary++;
      } else {
        counts.already_exists++;
      }

      // INSERT into essentials.geo_districts
      const gResult = await pool.query(
        `INSERT INTO essentials.geo_districts (layer, geoid, district_num, name, geom)
         VALUES ($1, $2, $3, $4,
           ST_Multi(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($5)), 4326))
         )
         ON CONFLICT (layer, geoid) DO NOTHING`,
        [LAYER, geoid, cd119fp, name, geomJson],
      );
      if ((gResult.rowCount ?? 0) > 0) {
        counts.inserted_geo++;
      }
    },
  );

  return counts;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-national-house-districts] TIGER 2024 US CD119 — per-state files for all 50 states + DC');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');
  console.log(`  Processing ${STATE_FIPS_CODES.length} FIPS codes`);

  const tmpDir = path.join(process.cwd(), '.tmp-national-cd119');
  fs.mkdirSync(tmpDir, { recursive: true });

  let totalProcessed = 0;
  let totalInsertedBoundary = 0;
  let totalInsertedGeo = 0;
  let totalSkipped = 0;
  let totalAlreadyExists = 0;

  for (const fips of STATE_FIPS_CODES) {
    process.stdout.write(`  FIPS ${fips} ... `);
    try {
      const counts = await processStateFips(fips, tmpDir, DRY_RUN);
      totalProcessed        += counts.processed;
      totalInsertedBoundary += counts.inserted_boundary;
      totalInsertedGeo      += counts.inserted_geo;
      totalSkipped          += counts.skipped;
      totalAlreadyExists    += counts.already_exists;

      if (DRY_RUN) {
        console.log(`done (${counts.processed} districts, ${counts.skipped} skipped)`);
      } else {
        console.log(
          `done (geo_districts+${counts.inserted_geo}, boundaries+${counts.inserted_boundary}, ` +
          `skipped=${counts.skipped}, already=${counts.already_exists})`
        );
      }
    } catch (err) {
      console.error(`\n  ERROR for FIPS ${fips}:`, err);
      throw err;
    }
  }

  if (DRY_RUN) {
    console.log(`\nDRY-RUN complete — ${totalProcessed} districts across ${STATE_FIPS_CODES.length} states (${totalSkipped} placeholder codes skipped).`);
    process.exit(0);
  }

  try {
    // Assert minimum count
    if (totalProcessed < EXPECTED_MIN) {
      throw new Error(
        `Processed only ${totalProcessed} districts (expected >= ${EXPECTED_MIN}). ` +
        `Check SKIP_CODES and shapefile integrity.`
      );
    }

    console.log('\n=== Summary ===');
    console.log(`  geofence_boundaries inserted:        ${totalInsertedBoundary}`);
    console.log(`  geofence_boundaries already existed: ${totalAlreadyExists}`);
    console.log(`  geo_districts inserted:              ${totalInsertedGeo}  (expect ~383 new — 52 CA rows skip)`);
    console.log(`  skipped (placeholder codes):         ${totalSkipped}`);
    console.log(`  total processed:                     ${totalProcessed}`);
    console.log('\nLoad complete.');

    console.log('\nVerify with:');
    console.log(`  SELECT COUNT(*) FROM essentials.geo_districts WHERE layer = 'us_house';  -- expect >= 435`);
    console.log(`  SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE mtfcc = 'G5200';`);
    console.log(`  -- Spot-check CA rows preserved:`);
    console.log(`  SELECT geoid, district_num, name FROM essentials.geo_districts WHERE layer = 'us_house' AND geoid IN ('0601', '0630', '0652') ORDER BY geoid;`);
    console.log(`  -- Confirm TX rows inserted:`);
    console.log(`  SELECT geoid, district_num, name FROM essentials.geo_districts WHERE layer = 'us_house' AND geoid LIKE '48%' ORDER BY geoid LIMIT 3;`);
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('[load-national-house-districts] Fatal error:', err);
  process.exit(1);
});
