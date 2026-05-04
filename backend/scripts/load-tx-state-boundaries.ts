/**
 * load-tx-state-boundaries.ts
 *
 * Downloads the TIGER/Line 2024 TX State Senate (SLDU) and TX State House (SLDL)
 * shapefiles and loads all boundaries into essentials.geofence_boundaries +
 * essentials.districts.
 *
 * MTFCC mapping (RESOLVED — do not change):
 *   G5210 = State Legislative District Upper Chamber = SLDU (Senate) → STATE_UPPER
 *   G5220 = State Legislative District Lower Chamber = SLDL (House)  → STATE_LOWER
 *
 * Usage:
 *   npx tsx scripts/load-tx-state-boundaries.ts --dry-run   # preview, no DB writes
 *   npx tsx scripts/load-tx-state-boundaries.ts              # live run
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING on geofence_boundaries,
 * WHERE NOT EXISTS guard on districts.
 *
 * Already-downloaded ZIPs are reused (not re-downloaded). Extracted dirs are cleaned
 * up after each shapefile unless the dir existed before the script ran.
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import * as shapefile from 'shapefile';
import AdmZip from 'adm-zip';
import { Pool } from 'pg';

// ─── Config ──────────────────────────────────────────────────────────────────

const WORK_DIR  = path.resolve(process.cwd()); // backend/
const isDryRun  = process.argv.includes('--dry-run');

// ─── District definitions ─────────────────────────────────────────────────────

interface DistrictDef {
  shapefileName:   string;
  districtType:    'STATE_UPPER' | 'STATE_LOWER';
  mtfcc:           string;
  districtFpField: string;
  ocdKey:          string;
  label:           string;
  expectedCount:   number;
  tigerUrl:        string;
}

const DISTRICTS: DistrictDef[] = [
  {
    shapefileName:   'tl_2024_48_sldu',           // SLDU = State Legislative District UPPER
    districtType:    'STATE_UPPER',                // Senate
    mtfcc:           'G5210',                      // matches service join: G5210 ↔ STATE_UPPER
    districtFpField: 'SLDUST',
    ocdKey:          'sldu',
    label:           'TX Senate (SLDU)',
    expectedCount:   31,
    tigerUrl:        'https://www2.census.gov/geo/tiger/TIGER2024/SLDU/tl_2024_48_sldu.zip',
  },
  {
    shapefileName:   'tl_2024_48_sldl',           // SLDL = State Legislative District LOWER
    districtType:    'STATE_LOWER',                // House
    mtfcc:           'G5220',                      // matches service join: G5220 ↔ STATE_LOWER
    districtFpField: 'SLDLST',
    ocdKey:          'sldl',
    label:           'TX House (SLDL)',
    expectedCount:   150,
    tigerUrl:        'https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_48_sldl.zip',
  },
];

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

// ─── Per-district-type loader ─────────────────────────────────────────────────

interface Totals {
  inserted_boundary: number;
  inserted_district: number;
  already_exists:    number;
  skipped:           number;
  errors:            number;
}

async function loadDistrict(def: DistrictDef, totals: Totals): Promise<void> {
  const zipPath    = path.join(WORK_DIR, `${def.shapefileName}.zip`);
  const extractDir = path.join(WORK_DIR, def.shapefileName);
  const shpPath    = path.join(extractDir, `${def.shapefileName}.shp`);
  const dbfPath    = path.join(extractDir, `${def.shapefileName}.dbf`);
  const dirExistedBefore = fs.existsSync(extractDir);

  // Download
  try {
    if (!fs.existsSync(zipPath)) {
      process.stdout.write(`  [${def.label}] Downloading...`);
    } else {
      process.stdout.write(`  [${def.label}] ZIP cached, `);
    }
    await downloadFile(def.tigerUrl, zipPath);
    if (!dirExistedBefore) {
      process.stdout.write(` extracting...`);
      extractZip(zipPath, extractDir);
    }
    process.stdout.write(` reading...\n`);
  } catch (err) {
    console.error(`\n  [${def.label}] Download/extract failed: ${(err as Error).message}`);
    totals.errors++;
    return;
  }

  // Read shapefile
  let source: shapefile.Source;
  try {
    source = await shapefile.open(shpPath, dbfPath, { encoding: 'utf-8' });
  } catch (err) {
    console.error(`  [${def.label}] Could not open shapefile: ${(err as Error).message}`);
    totals.errors++;
    return;
  }

  let result = await source.read();
  while (!result.done) {
    const feature = result.value;
    const props   = feature.properties as Record<string, string>;

    const statefp    = props.STATEFP;
    const districtFp = props[def.districtFpField];
    const geoid      = props.GEOID; // read directly — TIGER pre-computes this

    // Skip non-TX features (should not occur but guard anyway)
    if (statefp !== '48') {
      totals.skipped++;
      result = await source.read();
      continue;
    }

    // Skip placeholder/at-large districts
    if (districtFp === 'ZZZ' || districtFp === '000') {
      totals.skipped++;
      result = await source.read();
      continue;
    }

    const districtNum = parseInt(districtFp, 10);
    const ocdId = `ocd-division/country:us/state:tx/${def.ocdKey}:${districtNum}`;
    const distLabel = `TX ${def.districtType === 'STATE_UPPER' ? 'Senate' : 'House'} District ${districtNum}`;

    if (isDryRun) {
      console.log(`  [dry-run] ${def.mtfcc}/${def.districtType} ${geoid} — ${distLabel}`);
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
          $1, $2, $3, $4, $5,
          public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326),
          'census_tiger_2024',
          now()
        )
        ON CONFLICT (geo_id, mtfcc) DO NOTHING
      `, [geoid, ocdId, distLabel, '48', def.mtfcc, geojson]);
      // Note: geofence_boundaries.state = '48' (FIPS code)

      const dResult = await pool.query(`
        INSERT INTO essentials.districts
          (geo_id, ocd_id, label, district_type, state, mtfcc)
        SELECT $1, $2, $3, $4, $5, $6
        WHERE NOT EXISTS (
          SELECT 1 FROM essentials.districts
          WHERE geo_id = $1 AND district_type = $4
        )
      `, [geoid, ocdId, distLabel, def.districtType, 'TX', def.mtfcc]);
      // Note: districts.state = 'TX' (abbreviation)

      if (gbResult.rowCount && gbResult.rowCount > 0) {
        totals.inserted_boundary++;
        totals.inserted_district += (dResult.rowCount ?? 0);
      } else {
        totals.already_exists++;
      }
    } catch (err) {
      console.error(`  [${def.label}] ERROR on ${geoid}: ${(err as Error).message}`);
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
  console.log(`[load-tx-state] Mode: ${isDryRun ? 'DRY-RUN (no DB writes)' : 'LIVE'}`);
  console.log(`[load-tx-state] Loading TX state legislative district boundaries...\n`);
  console.log(`  MTFCC mapping: G5210=Senate=STATE_UPPER, G5220=House=STATE_LOWER\n`);

  const globalTotals: Totals = {
    inserted_boundary: 0,
    inserted_district: 0,
    already_exists:    0,
    skipped:           0,
    errors:            0,
  };

  const perDef: Array<{ def: DistrictDef; totals: Totals }> = [];

  for (const def of DISTRICTS) {
    console.log(`\n── ${def.label} (expected: ${def.expectedCount} districts) ──`);
    const t: Totals = {
      inserted_boundary: 0,
      inserted_district: 0,
      already_exists:    0,
      skipped:           0,
      errors:            0,
    };
    await loadDistrict(def, t);

    perDef.push({ def, totals: t });

    globalTotals.inserted_boundary += t.inserted_boundary;
    globalTotals.inserted_district += t.inserted_district;
    globalTotals.already_exists    += t.already_exists;
    globalTotals.skipped           += t.skipped;
    globalTotals.errors            += t.errors;
  }

  console.log('\n=== Per-shapefile Summary ===');
  for (const { def, totals } of perDef) {
    console.log(`\n  ${def.label} (${def.mtfcc} → ${def.districtType}):`);
    if (isDryRun) {
      console.log(`    Would insert: ${totals.inserted_boundary} boundaries`);
    } else {
      console.log(`    Inserted (boundaries): ${totals.inserted_boundary}`);
      console.log(`    Inserted (districts):  ${totals.inserted_district}`);
      console.log(`    Already existed:       ${totals.already_exists}`);
    }
    console.log(`    Skipped (placeholder): ${totals.skipped}`);
    console.log(`    Errors:                ${totals.errors}`);
  }

  console.log('\n=== Grand Total ===');
  if (isDryRun) {
    console.log(`  Would insert: ${globalTotals.inserted_boundary} boundaries (${DISTRICTS.map(d => d.expectedCount).join(' SLDU + ')} SLDL expected)`);
  } else {
    console.log(`  Inserted (boundaries): ${globalTotals.inserted_boundary}`);
    console.log(`  Inserted (districts):  ${globalTotals.inserted_district}`);
    console.log(`  Already existed:       ${globalTotals.already_exists}`);
  }
  console.log(`  Skipped (placeholder): ${globalTotals.skipped}`);
  console.log(`  Errors:                ${globalTotals.errors}`);

  if (isDryRun) {
    console.log('\nDRY-RUN complete — no database writes made.');
  } else {
    console.log('\nLoad complete.');
    console.log('Verify with:');
    console.log('  psql "$DATABASE_URL" -c "SELECT mtfcc, COUNT(*) FROM essentials.geofence_boundaries WHERE state=\'48\' AND mtfcc IN (\'G5210\',\'G5220\') GROUP BY mtfcc;"');
  }
}

main()
  .catch((err) => {
    console.error('[load-tx-state] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
