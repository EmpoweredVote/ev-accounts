/**
 * load-ca-state-boundaries.ts
 *
 * Loads California State Assembly (SLDL) and State Senate (SLDU) district
 * boundaries into essentials.geofence_boundaries + essentials.districts.
 *
 * Reads already-extracted TIGER/Line 2024 shapefiles. If the shapefiles are
 * not extracted yet, extract the ZIPs first:
 *   unzip tl_2024_06_sldl.zip -d tl_2024_06_sldl/
 *   unzip tl_2024_06_sldu.zip -d tl_2024_06_sldu/
 *
 * Expected shapefile locations (relative to repo root or backend/):
 *   tl_2024_06_sldl/tl_2024_06_sldl.shp   — CA Assembly (80 districts)
 *   tl_2024_06_sldu/tl_2024_06_sldu.shp   — CA Senate   (40 districts)
 *
 * Usage (from backend/):
 *   npx tsx scripts/load-ca-state-boundaries.ts --dry-run   # preview, no DB writes
 *   npx tsx scripts/load-ca-state-boundaries.ts              # live run
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING on geofence_boundaries,
 * WHERE NOT EXISTS guard on districts.
 *
 * MTFCC codes:
 *   G5210 — State Legislative District (Lower Chamber / Assembly)
 *   G5220 — State Legislative District (Upper Chamber / Senate)
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as shapefile from 'shapefile';
import { Pool } from 'pg';

// ─── Config ──────────────────────────────────────────────────────────────────

const isDryRun = process.argv.includes('--dry-run');

// Shapefiles may be in the repo root (one level up from backend/) or in backend/ itself.
// We search both locations.
const BACKEND_DIR  = path.resolve(process.cwd()); // where the script is run from (backend/)
const REPO_ROOT    = path.resolve(BACKEND_DIR, '..'); // one level up

function findShapefile(name: string): string {
  const candidates = [
    path.join(BACKEND_DIR, name, `${name}.shp`),
    path.join(REPO_ROOT, name, `${name}.shp`),
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  throw new Error(
    `Shapefile not found: ${name}.shp\n` +
    `Searched:\n` +
    candidates.map(p => `  ${p}`).join('\n') + '\n' +
    `Extract the ZIP first:\n` +
    `  unzip ${name}.zip -d ${name}/`
  );
}

// ─── District definitions ─────────────────────────────────────────────────────

interface DistrictDef {
  shapefileName: string;       // TIGER/Line base name (no extension)
  districtType: 'STATE_LOWER' | 'STATE_UPPER';
  mtfcc: string;               // MTFCC code: G5210 (lower) | G5220 (upper)
  districtFpField: string;     // DBF column holding the district number string (zero-padded)
  ocdKey: string;              // OCD-ID key: 'sldl' | 'sldu'
  label: string;               // Human label for logging
}

const DISTRICTS: DistrictDef[] = [
  {
    shapefileName:  'tl_2024_06_sldl',
    districtType:   'STATE_LOWER',
    mtfcc:          'G5210',
    districtFpField: 'SLDLST',
    ocdKey:         'sldl',
    label:          'CA Assembly (SLDL)',
  },
  {
    shapefileName:  'tl_2024_06_sldu',
    districtType:   'STATE_UPPER',
    mtfcc:          'G5220',
    districtFpField: 'SLDUST',
    ocdKey:         'sldu',
    label:          'CA Senate (SLDU)',
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

// ─── Per-dataset loader ───────────────────────────────────────────────────────

interface Totals {
  inserted_boundary: number;
  inserted_district: number;
  already_exists: number;
  errors: number;
}

async function loadDistricts(def: DistrictDef, totals: Totals): Promise<void> {
  console.log(`\n[${def.label}] Loading from ${def.shapefileName}.shp ...`);

  let shpPath: string;
  try {
    shpPath = findShapefile(def.shapefileName);
  } catch (err) {
    console.error(`  ERROR: ${(err as Error).message}`);
    totals.errors++;
    return;
  }

  const dbfPath = shpPath.replace('.shp', '.dbf');
  console.log(`  Shapefile: ${shpPath}`);

  let source: shapefile.Source;
  try {
    source = await shapefile.open(shpPath, dbfPath, { encoding: 'utf-8' });
  } catch (err) {
    console.error(`  ERROR opening shapefile: ${(err as Error).message}`);
    totals.errors++;
    return;
  }

  let count = 0;
  let result = await source.read();

  while (!result.done) {
    const feature  = result.value;
    const props    = feature.properties as Record<string, string>;

    const statefp    = props.STATEFP;
    const districtFp = props[def.districtFpField];
    const geoid      = props.GEOID;
    const namelsad   = props.NAMELSAD;

    // Skip non-CA features (should not appear in a CA-specific file, but guard anyway)
    if (statefp !== '06') {
      result = await source.read();
      continue;
    }

    // Skip placeholder/unassigned districts (ZZ equivalent for legislative files)
    if (!districtFp || districtFp === 'ZZZ' || districtFp === '000') {
      result = await source.read();
      continue;
    }

    const districtNum = parseInt(districtFp, 10);
    const ocdId = `ocd-division/country:us/state:ca/${def.ocdKey}:${districtNum}`;
    const name  = namelsad || `CA ${def.districtType === 'STATE_LOWER' ? 'Assembly' : 'Senate'} District ${districtNum}`;

    if (isDryRun) {
      console.log(`  [dry-run] ${geoid} — ${name} (ocd: ${ocdId})`);
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
      `, [geoid, ocdId, name, 'CA', def.mtfcc, geojson]);

      const dResult = await pool.query(`
        INSERT INTO essentials.districts
          (geo_id, ocd_id, label, district_type, state, mtfcc)
        SELECT $1, $2, $3, $4, 'CA', $5
        WHERE NOT EXISTS (
          SELECT 1 FROM essentials.districts
          WHERE geo_id = $1 AND district_type = $4
        )
      `, [geoid, ocdId, name, def.districtType, def.mtfcc]);

      if (gbResult.rowCount && gbResult.rowCount > 0) {
        totals.inserted_boundary++;
        totals.inserted_district += (dResult.rowCount ?? 0);
        count++;
        if (count % 10 === 0) {
          process.stdout.write(`  ... ${count} inserted\r`);
        }
      } else {
        totals.already_exists++;
      }
    } catch (err) {
      console.error(`\n  ERROR on ${geoid} (${name}): ${(err as Error).message}`);
      totals.errors++;
    }

    result = await source.read();
  }

  console.log(`  Done: ${count} new, ${totals.already_exists} already existed`);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log(`[load-ca-state-boundaries] Mode: ${isDryRun ? 'DRY-RUN (no DB writes)' : 'LIVE'}`);
  console.log(`[load-ca-state-boundaries] Loading CA Assembly + Senate district boundaries\n`);

  const totals: Totals = {
    inserted_boundary: 0,
    inserted_district: 0,
    already_exists: 0,
    errors: 0,
  };

  for (const def of DISTRICTS) {
    await loadDistricts(def, totals);
  }

  console.log('\n=== Summary ===');
  if (isDryRun) {
    console.log(`  Would insert: ${totals.inserted_boundary} boundaries`);
  } else {
    console.log(`  Inserted (boundaries): ${totals.inserted_boundary}`);
    console.log(`  Inserted (districts):  ${totals.inserted_district}`);
    console.log(`  Already existed:       ${totals.already_exists}`);
  }
  console.log(`  Errors:                ${totals.errors}`);

  if (isDryRun) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('Re-run without --dry-run to load into the database.');
  } else {
    console.log('\nLoad complete.');
    console.log('Verify with:');
    console.log(`  SELECT district_type, COUNT(*) FROM essentials.districts WHERE state = 'CA' GROUP BY district_type;`);
  }
}

main()
  .catch((err) => {
    console.error('[load-ca-state-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
