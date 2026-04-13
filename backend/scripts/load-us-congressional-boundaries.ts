/**
 * load-us-congressional-boundaries.ts
 *
 * Downloads the TIGER/Line 2024 per-state congressional district shapefiles
 * for all 50 states + DC and loads all House districts into
 * essentials.geofence_boundaries + essentials.districts.
 *
 * Usage:
 *   npx tsx scripts/load-us-congressional-boundaries.ts --dry-run   # preview, no DB writes
 *   npx tsx scripts/load-us-congressional-boundaries.ts              # live run
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING on geofence_boundaries,
 * WHERE NOT EXISTS guard on districts.
 *
 * Already-downloaded ZIPs are reused (not re-downloaded). Extracted dirs are cleaned
 * up after each state unless the dir existed before the script ran.
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import * as shapefile from 'shapefile';
import AdmZip from 'adm-zip';
import { Pool } from 'pg';

// ─── Config ──────────────────────────────────────────────────────────────────

const TIGER_BASE = 'https://www2.census.gov/geo/tiger/TIGER2024/CD';
const WORK_DIR   = path.resolve(process.cwd()); // backend/

const isDryRun = process.argv.includes('--dry-run');

// ─── All state FIPS codes (50 states + DC) ───────────────────────────────────

const ALL_STATE_FIPS = [
  '01','02','04','05','06','08','09','10','11','12',
  '13','15','16','17','18','19','20','21','22','23',
  '24','25','26','27','28','29','30','31','32','33',
  '34','35','36','37','38','39','40','41','42','44',
  '45','46','47','48','49','50','51','53','54','55','56',
];

// Non-voting delegate territories to skip at the district level
const SKIP_FIPS = new Set(['60','66','69','72','78']);

// ─── FIPS → state abbreviation ────────────────────────────────────────────────

const FIPS_TO_STATE: Record<string, string> = {
  '01':'al','02':'ak','04':'az','05':'ar','06':'ca',
  '08':'co','09':'ct','10':'de','11':'dc','12':'fl',
  '13':'ga','15':'hi','16':'id','17':'il','18':'in',
  '19':'ia','20':'ks','21':'ky','22':'la','23':'me',
  '24':'md','25':'ma','26':'mi','27':'mn','28':'ms',
  '29':'mo','30':'mt','31':'ne','32':'nv','33':'nh',
  '34':'nj','35':'nm','36':'ny','37':'nc','38':'nd',
  '39':'oh','40':'ok','41':'or','42':'pa','44':'ri',
  '45':'sc','46':'sd','47':'tn','48':'tx','49':'ut',
  '50':'vt','51':'va','53':'wa','54':'wv','55':'wi',
  '56':'wy',
};

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
      return resolve(); // already downloaded
    }
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
      response.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      if (fs.existsSync(dest)) fs.unlinkSync(dest);
      reject(err);
    });
  });
}

function extractZip(zipPath: string, destDir: string): void {
  fs.mkdirSync(destDir, { recursive: true });
  const zip = new AdmZip(zipPath);
  zip.extractAllTo(destDir, true);
}

// ─── Per-state loader ─────────────────────────────────────────────────────────

async function loadState(fips: string, totals: {
  inserted_boundary: number;
  inserted_district: number;
  already_exists: number;
  skipped_zz: number;
  errors: number;
}): Promise<void> {
  const stateAbbr = FIPS_TO_STATE[fips];
  const name      = `tl_2024_${fips}_cd119`;
  const zipPath   = path.join(WORK_DIR, `${name}.zip`);
  const extractDir = path.join(WORK_DIR, name);
  const shpPath   = path.join(extractDir, `${name}.shp`);
  const dbfPath   = path.join(extractDir, `${name}.dbf`);
  const dirExistedBefore = fs.existsSync(extractDir);

  // Download
  const url = `${TIGER_BASE}/${name}.zip`;
  try {
    if (!fs.existsSync(zipPath)) {
      process.stdout.write(`  [${stateAbbr?.toUpperCase() ?? fips}] Downloading...`);
    }
    await downloadFile(url, zipPath);
    if (!dirExistedBefore) {
      process.stdout.write(` extracting...`);
      extractZip(zipPath, extractDir);
    }
    process.stdout.write(` reading...\n`);
  } catch (err) {
    console.error(`\n  [${fips}] Download/extract failed: ${(err as Error).message}`);
    totals.errors++;
    return;
  }

  // Read shapefile
  let source: shapefile.Source;
  try {
    source = await shapefile.open(shpPath, dbfPath, { encoding: 'utf-8' });
  } catch (err) {
    console.error(`  [${fips}] Could not open shapefile: ${(err as Error).message}`);
    totals.errors++;
    return;
  }

  let result = await source.read();
  while (!result.done) {
    const feature = result.value;
    const props   = feature.properties as Record<string, string>;

    const statefp  = props.STATEFP;
    const cd119fp  = props.CD119FP;
    const geoid    = props.GEOID;
    const namelsad = props.NAMELSAD;

    if (SKIP_FIPS.has(statefp)) {
      result = await source.read();
      continue;
    }

    if (cd119fp === 'ZZ') {
      totals.skipped_zz++;
      result = await source.read();
      continue;
    }

    const districtNum = parseInt(cd119fp, 10);
    const label = districtNum === 0
      ? `${(stateAbbr ?? fips).toUpperCase()} At Large`
      : namelsad;

    const ocdId = districtNum === 0
      ? `ocd-division/country:us/state:${stateAbbr}/cd:at-large`
      : `ocd-division/country:us/state:${stateAbbr}/cd:${districtNum}`;

    if (isDryRun) {
      console.log(`  [dry-run] ${geoid} — ${label}`);
      totals.inserted_boundary++;
      result = await source.read();
      continue;
    }

    const geojson = JSON.stringify(feature.geometry);

    try {
      const gbResult = await pool.query(`
        INSERT INTO essentials.geofence_boundaries
          (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
        VALUES (
          $1, $2, $3, $4, 'G5200',
          public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($5)), 4326),
          'census_tiger_2024',
          now()
        )
        ON CONFLICT (geo_id, mtfcc) DO NOTHING
      `, [geoid, ocdId, namelsad, statefp, geojson]);

      const dResult = await pool.query(`
        INSERT INTO essentials.districts
          (geo_id, ocd_id, label, district_type, state, mtfcc)
        SELECT $1, $2, $3, 'NATIONAL_LOWER', $4, 'G5200'
        WHERE NOT EXISTS (
          SELECT 1 FROM essentials.districts
          WHERE geo_id = $1 AND district_type = 'NATIONAL_LOWER'
        )
      `, [geoid, ocdId, label, (stateAbbr ?? fips).toUpperCase()]);

      if (gbResult.rowCount && gbResult.rowCount > 0) {
        totals.inserted_boundary++;
        totals.inserted_district += (dResult.rowCount ?? 0);
      } else {
        totals.already_exists++;
      }
    } catch (err) {
      console.error(`  [${fips}] ERROR on ${geoid}: ${(err as Error).message}`);
      totals.errors++;
    }

    result = await source.read();
  }

  // Clean up extracted dir if we created it (don't delete pre-existing dirs)
  if (!isDryRun && !dirExistedBefore && fs.existsSync(extractDir)) {
    fs.rmSync(extractDir, { recursive: true, force: true });
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log(`[load-cd] Mode: ${isDryRun ? 'DRY-RUN (no DB writes)' : 'LIVE'}`);
  console.log(`[load-cd] Loading congressional districts for ${ALL_STATE_FIPS.length} states + DC...\n`);

  const totals = {
    inserted_boundary: 0,
    inserted_district: 0,
    already_exists: 0,
    skipped_zz: 0,
    errors: 0,
  };

  for (const fips of ALL_STATE_FIPS) {
    const abbr = (FIPS_TO_STATE[fips] ?? fips).toUpperCase();
    process.stdout.write(`[${abbr}] `);
    await loadState(fips, totals);
  }

  console.log('\n=== Summary ===');
  if (isDryRun) {
    console.log(`  Would insert:              ${totals.inserted_boundary} boundaries`);
  } else {
    console.log(`  Inserted (boundaries):     ${totals.inserted_boundary}`);
    console.log(`  Inserted (districts):      ${totals.inserted_district}`);
    console.log(`  Already existed (skipped): ${totals.already_exists}`);
  }
  console.log(`  Skipped (ZZ at-large):     ${totals.skipped_zz}`);
  console.log(`  Errors:                    ${totals.errors}`);

  if (isDryRun) {
    console.log('\nDRY-RUN complete — no database writes made.');
  } else {
    console.log('\nLoad complete. Run the backfill script to populate existing users:');
    console.log('  npx tsx scripts/backfill-pre-phase49-geo-ids.ts');
  }
}

main()
  .catch((err) => {
    console.error('[load-cd] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
