/**
 * load-portland-council-boundaries.ts
 *
 * Fetches the 4 City of Portland (Oregon) City Council district boundaries
 * from the PortlandMaps.com ArcGIS MapServer (Public/Boundaries, Layer 17)
 * and inserts them into essentials.geofence_boundaries.
 *
 * These districts were created by Portland's 2024 charter reform (Measure 26-228,
 * approved Nov 2022, effective Jan 2025). They are NOT in TIGER 2024 and must be
 * sourced from the City of Portland's ArcGIS infrastructure.
 *
 * Each district is stored with:
 *   geo_id  = 'portland-or-council-district-{N}'  (N = 1..4)
 *   mtfcc   = 'X0012'
 *   state   = '41'  (Oregon FIPS — geofence_boundaries.state, NOT 'OR' or 'or')
 *   source  = 'portland_city_council_districts_2024'
 *
 * CRITICAL: outSR=4326 IS REQUIRED.
 * PortlandMaps MapServer Layer 17 uses Web Mercator (WKID 102100 / EPSG:3857)
 * natively. Without outSR=4326, ArcGIS returns geometries in Web Mercator meters
 * (6-7 digit values), PostGIS stores garbage, and ST_Covers returns 0 rows for
 * any lat/lon query.
 *
 * CRITICAL: Per-OBJECTID fetch loop required — do NOT use bulk where=1=1.
 * Bulk where=1=1 GeoJSON query silently returns only 3 of 4 features (geometry
 * transfer-size limit triggers before exceededTransferLimit flag is set). The
 * service returns no error and no pagination indicator — District 4 simply
 * disappears. Always fetch each district via its own URL:
 *   OBJECTID%3D1, OBJECTID%3D2, OBJECTID%3D3, OBJECTID%3D4
 * Verify districtMap.size === EXPECTED_COUNT (4) after the loop.
 *
 * CRITICAL: '-or-' geo_id qualifier prevents Portland Maine collision.
 * Portland ME uses the 'portland-...' prefix (Phase 53). All Portland OR
 * geo_ids must use 'portland-or-...' to avoid namespace collision.
 *
 * X0012 MTFCC: claimed by this script for Portland OR council districts.
 * (Registry: X0005=LA County, X0006=SF, X0007=SD, X0008=Fremont,
 *  X0009=Berkeley, X0010=SJ, X0011=Sacramento, X0012=Portland OR council)
 * Next available is X0013.
 *
 * IDEMPOTENCY: ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures safe re-runs.
 *
 * ST_MakeValid: Required for Portland district polygons — Districts 1 and 4
 * have self-intersections in the source GeoJSON that cause ST_IsValid to return
 * false. Without ST_MakeValid, ST_Covers returns incorrect results for points
 * inside those districts. ST_MakeValid is applied after ST_ForcePolygonCCW.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-portland-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-portland-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

const ARCGIS_BASE_URL =
  'https://www.portlandmaps.com/arcgis/rest/services/Public/Boundaries/MapServer/17/query';

const MTFCC           = 'X0012';
const STATE           = '41';           // Oregon FIPS (geofence_boundaries.state — not 'OR' or 'or')
const SOURCE          = 'portland_city_council_districts_2024';
const EXPECTED_COUNT  = 4;
const MAX_DISTRICT    = 4;

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

// ─── Helpers ──────────────────────────────────────────────────────────────────

function fetchJson(url: string): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    lib.get(url, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return fetchJson(res.headers.location).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode} fetching ${url}`));
      }
      const chunks: Buffer[] = [];
      res.on('data', (c: Buffer) => chunks.push(c));
      res.on('end', () => {
        try {
          resolve(JSON.parse(Buffer.concat(chunks).toString('utf8')));
        } catch (e) {
          reject(new Error(`JSON parse error: ${(e as Error).message}`));
        }
      });
    }).on('error', reject);
  });
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-portland-council-boundaries] Fetching Portland OR City Council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // ─── Pre-flight: verify X0012 is unclaimed (or only Portland OR rows) ─────────
  if (!DRY_RUN) {
    const precheck = await pool.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries WHERE mtfcc='X0012'
    `);
    const existingCount = parseInt(precheck.rows[0].cnt, 10);
    if (existingCount > 0) {
      const portlandCheck = await pool.query<{ cnt: string }>(`
        SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries
        WHERE mtfcc='X0012' AND geo_id LIKE 'portland-or-council-district-%'
      `);
      const portlandCount = parseInt(portlandCheck.rows[0].cnt, 10);
      if (portlandCount !== existingCount) {
        console.error(`ERROR: X0012 mtfcc already has ${existingCount} row(s) that are NOT portland-or-council-district rows.`);
        console.error('  This script claims X0012 for Portland OR council districts. Aborting.');
        process.exit(1);
      }
      console.log(`  Pre-flight: X0012 has ${existingCount} existing Portland OR rows — re-run OK`);
    } else {
      console.log('  Pre-flight: X0012 is unclaimed — proceeding');
    }
  }

  // ─── Step 1: Fetch each district individually by OBJECTID (NOT bulk where=1=1) ─
  //
  // IMPORTANT: Do NOT use a single bulk query (where=1=1). The bulk GeoJSON query
  // to MapServer Layer 17 silently returns only 3 of 4 features (geometry
  // transfer-size limit triggers before the exceededTransferLimit flag is set).
  // Always fetch each district via its own OBJECTID query.

  const districtMap = new Map<number, string>(); // distNum -> GeoJSON geometry string

  for (let objectId = 1; objectId <= EXPECTED_COUNT; objectId++) {
    const url = `${ARCGIS_BASE_URL}?where=OBJECTID%3D${objectId}&outFields=DISTRICT&outSR=4326&f=geojson`;
    console.log(`\n  Fetching OBJECTID=${objectId}: ${url}`);

    let geojson: { type: string; features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }> };
    try {
      geojson = await fetchJson(url) as typeof geojson;
    } catch (err) {
      console.error(`ERROR fetching OBJECTID=${objectId}:`, (err as Error).message);
      process.exit(1);
    }

    if (!geojson?.features?.length) {
      console.error(`ERROR: OBJECTID=${objectId} returned no features`);
      process.exit(1);
    }

    const feature = geojson.features[0];
    const props = feature.properties || {};

    // Log available fields on first feature for diagnostics
    if (districtMap.size === 0) {
      console.log(`  Available fields: ${Object.keys(props).join(', ')}`);
    }

    // CRITICAL: DISTRICT field is a STRING (values "1", "2", "3", "4"), NOT an integer.
    // Read DISTRICT property, not OBJECTID — they happen to match for this dataset but
    // always trust the data field, not the loop counter.
    const rawDistrict = props['DISTRICT'];
    const distNum = parseInt(String(rawDistrict ?? ''), 10);
    if (isNaN(distNum) || distNum < 1 || distNum > MAX_DISTRICT) {
      console.error(`ERROR: OBJECTID=${objectId} returned DISTRICT='${rawDistrict}' — out of range`);
      process.exit(1);
    }

    if (districtMap.has(distNum)) {
      console.error(`ERROR: Duplicate features for district ${distNum}`);
      process.exit(1);
    }

    districtMap.set(distNum, JSON.stringify(feature.geometry));
    console.log(`  District ${distNum}: found (DISTRICT=${rawDistrict})`);
  }

  // Abort if we didn't collect all 4
  if (districtMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: Expected ${EXPECTED_COUNT} districts, got ${districtMap.size}`);
    process.exit(1);
  }
  console.log(`\n  Mapped ${districtMap.size} / ${EXPECTED_COUNT} districts`);

  // ─── Step 2: Insert into geofence_boundaries ─────────────────────────────────
  let inserted = 0;
  let skipped  = 0;

  for (const [distNum, geometryJson] of Array.from(districtMap.entries()).sort((a, b) => a[0] - b[0])) {
    // CRITICAL: '-or-' qualifier prevents collision with Portland Maine's 'portland-...' namespace (Phase 53)
    const geoId = `portland-or-council-district-${distNum}`;
    const name  = `District ${distNum}`;

    if (DRY_RUN) {
      console.log(`  [dry-run] Would insert: geo_id=${geoId}`);
      inserted++;
      continue;
    }

    try {
      const result = await pool.query(`
        INSERT INTO essentials.geofence_boundaries
          (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
        VALUES ($1, $2, $3, $4, $5,
          public.ST_MakeValid(
            public.ST_ForcePolygonCCW(
              public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326)
            )
          ),
          $7, now())
        ON CONFLICT (geo_id, mtfcc) DO NOTHING
      `, [geoId, geoId, name, STATE, MTFCC, geometryJson, SOURCE]);

      if (result.rowCount && result.rowCount > 0) {
        console.log(`  Inserted: District ${distNum} (${geoId})`);
        inserted++;
      } else {
        console.log(`  Skipped (already exists): District ${distNum}`);
        skipped++;
      }
    } catch (err) {
      console.error(`  ERROR inserting District ${distNum}:`, (err as Error).message);
      process.exit(1);
    }
  }

  // ─── Step 3: Summary + verify ─────────────────────────────────────────────────
  console.log('\n  Summary:');
  console.log(`    Inserted: ${inserted}`);
  console.log(`    Skipped (already existed): ${skipped}`);

  if (!DRY_RUN) {
    const verify = await pool.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt
      FROM essentials.geofence_boundaries
      WHERE geo_id LIKE 'portland-or-council-district-%'
        AND mtfcc = $1
        AND state = $2
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`  Total Portland OR council district rows in geofence_boundaries: ${total}`);
    if (total !== EXPECTED_COUNT) {
      console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows, found ${total}`);
    } else {
      console.log(`  All ${EXPECTED_COUNT} Portland OR council districts loaded successfully.`);
    }
  }

  console.log('\n[load-portland-council-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-portland-council-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
