/**
 * import-mcc-district-polygons.ts — Idempotent import of 4 Monroe County Council
 * District polygons into essentials.geofence_boundaries and essentials.districts.
 *
 * Reads the GeoJSON file saved by fetch-mcc-district-polygons.ts and inserts
 * 4 rows into each table using the canonical PostGIS pattern from
 * load-ca-state-boundaries.ts.
 *
 * Schema produced:
 *   geofence_boundaries: geo_id='18105-mcc-d{N}', mtfcc='X-MCC-DIST', state='IN', source='monroe_county_gis'
 *   districts:           geo_id='18105-mcc-d{N}', district_type='COUNTY', district_id='election-mcc-d{N}'
 *
 * The X-MCC-DISTRICT mtfcc matches the LIKE 'X%' pattern in essentialsService.ts
 * line 574, so these polygons are picked up by the address-based politician lookup.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/import-mcc-district-polygons.ts           # Import (idempotent)
 *   npx tsx scripts/import-mcc-district-polygons.ts --check   # Read-only count check (no INSERT)
 *
 * Exit codes:
 *   0 — success (final_boundary_count=4 and final_district_count=4)
 *   1 — general error (DB connection failure, file parse error, etc.)
 *   2 — import succeeded but final counts don't match expectations
 *
 * Idempotency guarantees:
 *   - geofence_boundaries: ON CONFLICT (geo_id, mtfcc) DO NOTHING
 *   - districts: WHERE NOT EXISTS (SELECT 1 ... WHERE district_id = $3)
 *   Re-running produces inserted_boundary=0, inserted_district=0, and same final counts.
 *
 * Pitfall protections (per 121-RESEARCH.md § Common Pitfalls):
 *   - Pitfall 1: geo_id values are '18105-mcc-d{N}' (NOT '18105') — never reuse county-wide geo_id
 *   - Pitfall 2: both tables use mtfcc='X-MCC-DISTRICT' (logged as mtfcc_match=true)
 *   - Pitfall 3: county-wide row (18105, G4020) untouched — INSERT uses different geo_ids
 *   - Pitfall 4: ST_Force2D strips Z coordinates defensively
 *   - Pitfall 6: file-not-found produces clear error message with remediation steps
 *
 * References:
 *   - ev-accounts/backend/scripts/load-ca-state-boundaries.ts (canonical INSERT pattern)
 *   - 121-RESEARCH.md § Schema Proposal (D-05)
 *   - 121-RESEARCH.md § Pattern 3 — Idempotent District + Office Creation
 *   - link-monroe-county-races-to-geofences.sql §1a (district_id naming precedent)
 */

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

// Path to evidence file produced by fetch-mcc-district-polygons.ts
// scripts/ -> backend/ -> ev-accounts/ -> repo root (3 levels up)
const GEOJSON_PATH = path.resolve(
  __dirname,
  '..',
  '..',
  '..',
  '.planning',
  'phases',
  '121-county-council-d1-d4-geofence-repair',
  'evidence',
  'mcc-district-polygons.geojson',
);

// NOTE: essentials.geofence_boundaries.mtfcc is varchar(10) — must be ≤10 chars.
// 'X-MCC-DISTRICT' (14 chars) exceeds the limit; using 'X-MCC-DIST' (10 chars).
// Still matches the LIKE 'X%' pattern in essentialsService.ts line 574.
const MTFCC = 'X-MCC-DIST';
const STATE = 'IN';
const SOURCE = 'monroe_county_gis';

const CHECK_ONLY = process.argv.includes('--check');

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface GeoJsonGeometry {
  type: string;
  coordinates: unknown;
}

interface MccFeature {
  type: string;
  geometry: GeoJsonGeometry;
  properties: {
    CountyCouncil: string;
    Council?: string;
    Rep?: string;
    OBJECTID?: number;
    [key: string]: unknown;
  };
}

interface GeoJsonFeatureCollection {
  type: string;
  features: MccFeature[];
}

interface Counters {
  inserted_boundary: number;
  inserted_district: number;
  skipped_boundary: number;
  skipped_district: number;
  errors: number;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  // Step 0: Setup
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

  if (CHECK_ONLY) {
    console.error('[121-import] --check mode: read-only count check (no INSERT)');
    await runChecks(pool);
    await pool.end();
    return;
  }

  console.error('[121-import] Starting MCC district polygon import...');
  console.error(`[121-import] GeoJSON source: ${GEOJSON_PATH}`);

  // Step 1: Load GeoJSON file (Pitfall 6: clear error if missing)
  let geojson: GeoJsonFeatureCollection;
  try {
    const raw = fs.readFileSync(GEOJSON_PATH, 'utf8');
    geojson = JSON.parse(raw) as GeoJsonFeatureCollection;
  } catch (err) {
    const message = (err as NodeJS.ErrnoException).code === 'ENOENT'
      ? `GeoJSON file not found at ${GEOJSON_PATH}.\n  Run: npx tsx scripts/fetch-mcc-district-polygons.ts`
      : `Failed to parse GeoJSON: ${(err as Error).message}`;
    console.error(`[121-import] FAIL: ${message}`);
    await pool.end();
    process.exit(1);
  }

  // Step 2: Validate basic structure
  if (geojson.type !== 'FeatureCollection' || !Array.isArray(geojson.features)) {
    console.error('[121-import] FAIL: GeoJSON file is not a valid FeatureCollection');
    await pool.end();
    process.exit(1);
  }

  if (geojson.features.length !== 4) {
    console.error(`[121-import] FAIL: Expected 4 features, got ${geojson.features.length}`);
    await pool.end();
    process.exit(1);
  }

  // Step 3: Sort features by CountyCouncil ascending ("1" → "4")
  const features = [...geojson.features].sort((a, b) =>
    a.properties.CountyCouncil.localeCompare(b.properties.CountyCouncil),
  );

  // Step 4: Insert each feature
  const counters: Counters = {
    inserted_boundary: 0,
    inserted_district: 0,
    skipped_boundary: 0,
    skipped_district: 0,
    errors: 0,
  };

  for (const feature of features) {
    const N = feature.properties.CountyCouncil; // "1", "2", "3", or "4"
    const geoId = `18105-mcc-d${N}`; // e.g. '18105-mcc-d1'  (NEVER '18105' alone — Pitfall 1)
    const districtId = `election-mcc-d${N}`; // e.g. 'election-mcc-d1'
    const name = `Monroe County Council District ${N}`;
    const ocdId = `ocd-division/country:us/state:in/county:monroe/council_district:${N}`;
    const geojsonStr = JSON.stringify(feature.geometry); // geometry only, not whole feature

    console.error(`[121-import] Processing District ${N} → geo_id=${geoId}`);

    try {
      // INSERT 1: geofence_boundaries
      // Pitfall 4: ST_Force2D strips Z coordinates defensively
      // Pattern from load-ca-state-boundaries.ts lines 175-185
      const gbResult = await pool.query(
        `
        INSERT INTO essentials.geofence_boundaries
          (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
        VALUES (
          $1, $2, $3, $4, $5,
          public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326),
          '${SOURCE}',
          now()
        )
        ON CONFLICT (geo_id, mtfcc) DO NOTHING
        `,
        [geoId, ocdId, name, STATE, MTFCC, geojsonStr],
      );

      if (gbResult.rowCount && gbResult.rowCount > 0) {
        counters.inserted_boundary++;
        console.error(`[121-import]   geofence_boundaries: INSERTED ${geoId}`);
      } else {
        counters.skipped_boundary++;
        console.error(`[121-import]   geofence_boundaries: SKIPPED (already exists) ${geoId}`);
      }

      // INSERT 2: districts
      // Note: district_id is the stable key (per link-monroe-county-races-to-geofences.sql §1a)
      // Uses WHERE NOT EXISTS guard with district_id as the uniqueness key
      const dResult = await pool.query(
        `
        INSERT INTO essentials.districts
          (geo_id, district_type, label, state, mtfcc, district_id)
        SELECT $1, 'COUNTY', $2, '${STATE}', '${MTFCC}', $3
        WHERE NOT EXISTS (
          SELECT 1 FROM essentials.districts
          WHERE district_id = $3
        )
        `,
        [geoId, name, districtId],
      );

      if (dResult.rowCount && dResult.rowCount > 0) {
        counters.inserted_district++;
        console.error(`[121-import]   districts: INSERTED district_id=${districtId}`);
      } else {
        counters.skipped_district++;
        console.error(`[121-import]   districts: SKIPPED (already exists) district_id=${districtId}`);
      }
    } catch (err) {
      console.error(`[121-import] ERROR on District ${N} (${geoId}): ${(err as Error).message}`);
      counters.errors++;
    }
  }

  // Step 5: Pitfall 2 check — log mtfcc consistency
  const mtfccMatch = true; // Both inserts use the same MTFCC constant
  console.error(`[121-import] mtfcc_match=${mtfccMatch} (both tables use '${MTFCC}')`);

  // Step 6: Print counters
  console.error(`[121-import] inserted_boundary=${counters.inserted_boundary}`);
  console.error(`[121-import] inserted_district=${counters.inserted_district}`);
  console.error(`[121-import] skipped_boundary=${counters.skipped_boundary}`);
  console.error(`[121-import] skipped_district=${counters.skipped_district}`);

  if (counters.errors > 0) {
    console.error(`[121-import] WARN: ${counters.errors} error(s) encountered during import`);
  }

  // Step 7: Verification SELECT counts
  await runChecks(pool);

  await pool.end();
}

// ---------------------------------------------------------------------------
// Verification checks (used by both --check and after import)
// ---------------------------------------------------------------------------

async function runChecks(pool: pg.Pool): Promise<void> {
  // Count geofence_boundaries rows with our geo_ids
  const gbCount = await pool.query(
    `SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries WHERE geo_id LIKE '18105-mcc-d%' AND mtfcc = '${MTFCC}'`,
  );
  const finalBoundaryCount = parseInt(gbCount.rows[0].cnt, 10);

  // Count districts rows with our district_ids
  const dCount = await pool.query(
    `SELECT COUNT(*) AS cnt FROM essentials.districts WHERE district_id LIKE 'election-mcc-d%'`,
  );
  const finalDistrictCount = parseInt(dCount.rows[0].cnt, 10);

  // Verify county-wide row is untouched (Pitfall 3 / Acceptance Criteria)
  const countyWide = await pool.query(
    `SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '18105' AND mtfcc = 'G4020'`,
  );
  const countyWideIntact = countyWide.rows.length === 1;

  console.error(`[121-import] final_boundary_count=${finalBoundaryCount}`);
  console.error(`[121-import] final_district_count=${finalDistrictCount}`);
  console.error(`[121-import] county_wide_18105_g4020_intact=${countyWideIntact}`);

  if (finalBoundaryCount !== 4) {
    console.error(
      `[121-import] FAIL: Expected final_boundary_count=4, got ${finalBoundaryCount}`,
    );
    process.exitCode = 2;
  }

  if (finalDistrictCount !== 4) {
    console.error(
      `[121-import] FAIL: Expected final_district_count=4, got ${finalDistrictCount}`,
    );
    process.exitCode = 2;
  }

  if (!countyWideIntact) {
    console.error(
      '[121-import] FAIL: County-wide geofence row (geo_id=18105, mtfcc=G4020) is missing! This should never happen.',
    );
    process.exitCode = 2;
  }

  if (process.exitCode === undefined || process.exitCode === 0) {
    console.error('[121-import] All checks passed.');
  }
}

main().catch((err) => {
  console.error(`[121-import] Fatal error: ${(err as Error).message}`);
  process.exit(1);
});
