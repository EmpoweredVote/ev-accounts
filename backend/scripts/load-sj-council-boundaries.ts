/**
 * load-sj-council-boundaries.ts
 *
 * Fetches the 10 City of San Jose City Council district boundaries from the
 * City's ArcGIS MapServer (geo.sanjoseca.gov) and inserts them into
 * essentials.geofence_boundaries.
 *
 * Each district is stored with:
 *   geo_id  = 'sj-council-district-{N}'  (N = 1..10)
 *   mtfcc   = 'X0010'
 *   state   = '06'
 *   source  = 'sj_city_council_districts_2022'
 *
 * CRITICAL: outSR=4326 IS REQUIRED. The SJ ArcGIS MapServer uses
 * State Plane CA Zone 3 (WKID 102643, NAD 1983 StatePlane California III)
 * natively. Without outSR=4326, ArcGIS returns geometries in feet (six-digit
 * State Plane coordinates like (6295123.4, 1882346.2)), PostGIS stores garbage,
 * and ST_Covers returns 0 rows for any lat/lon query.
 *
 * The field name is DISTRICTINT (integer 1-10). The COUNCILMEMBER field holds the
 * current council member's name and MUST NOT be used for the boundary name
 * column — it changes with elections.
 *
 * X0010 falls through to the X% fallback rule in essentialsService.ts which
 * maps it to district_type IN ('LOCAL','COUNTY'). No service code change needed.
 *
 * San Jose City Charter provides for 10 single-member council districts.
 * TIGER does not publish San Jose council district polygons — this is the
 * authoritative source from the City of San Jose GIS Division.
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures idempotency.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-sj-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-sj-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

const ARCGIS_URL =
  'https://geo.sanjoseca.gov/server/rest/services/OPN/OPN_OpenDataService/MapServer/120/query' +
  '?where=1%3D1&outFields=DISTRICTINT%2CCOUNCILMEMBER&outSR=4326&f=geojson';

const MTFCC          = 'X0010';
const STATE          = '06';
const SOURCE         = 'sj_city_council_districts_2022';
const EXPECTED_COUNT = 10;
const MAX_DISTRICT   = 10;

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
  console.log('[load-sj-council-boundaries] Fetching San Jose City Council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // ─── Pre-flight: verify X0010 is unclaimed (or only SJ rows) ────────────────
  if (!DRY_RUN) {
    const precheck = await pool.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries WHERE mtfcc='X0010'
    `);
    const existingCount = parseInt(precheck.rows[0].cnt, 10);
    if (existingCount > 0) {
      // Check if existing rows are all SJ rows (idempotency re-run scenario)
      const sjCheck = await pool.query<{ cnt: string }>(`
        SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries
        WHERE mtfcc='X0010' AND geo_id LIKE 'sj-council-district-%'
      `);
      const sjCount = parseInt(sjCheck.rows[0].cnt, 10);
      if (sjCount !== existingCount) {
        console.error(`ERROR: X0010 mtfcc already has ${existingCount} row(s) that are NOT sj-council-district rows.`);
        console.error('  This script claims X0010 for San Jose council districts. Aborting to prevent conflict.');
        process.exit(1);
      }
      console.log(`  Pre-flight: X0010 has ${existingCount} existing SJ rows — re-run OK`);
    } else {
      console.log('  Pre-flight: X0010 is unclaimed — proceeding');
    }
  }

  // ─── Step 1: Fetch GeoJSON from ArcGIS ──────────────────────────────────────
  console.log(`\n  Fetching: ${ARCGIS_URL}`);
  let geojson: { type: string; features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }> };
  try {
    geojson = await fetchJson(ARCGIS_URL) as typeof geojson;
  } catch (err) {
    console.error('ERROR fetching council districts:', (err as Error).message);
    process.exit(1);
  }

  if (!geojson?.features?.length) {
    console.error('ERROR: No features returned from ArcGIS. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${geojson.features.length} features`);

  // ─── Step 2: Map features to district numbers ────────────────────────────────
  const districtMap = new Map<number, string>(); // distNum -> GeoJSON geometry string

  for (const feature of geojson.features) {
    const props = feature.properties || {};

    // Log available fields on first feature for diagnostics
    if (districtMap.size === 0) {
      console.log(`  Available fields: ${Object.keys(props).join(', ')}`);
    }

    const rawDistrict = props['DISTRICTINT'];  // integer 1-10 (was DISTRICT in Fremont)
    const distNum = parseInt(String(rawDistrict ?? ''), 10);

    if (isNaN(distNum) || distNum < 1 || distNum > MAX_DISTRICT) {
      console.warn(`  WARNING: DISTRICTINT value '${rawDistrict}' out of range — skipping`);
      continue;
    }

    if (districtMap.has(distNum)) {
      console.warn(`  WARNING: Duplicate features for district ${distNum} — keeping first`);
      continue;
    }

    districtMap.set(distNum, JSON.stringify(feature.geometry));
    console.log(`  District ${distNum}: found`);
  }

  if (districtMap.size === 0) {
    console.error('ERROR: Could not extract any district numbers. Dumping first feature properties:');
    console.error(JSON.stringify(geojson.features[0]?.properties, null, 2));
    process.exit(1);
  }

  console.log(`\n  Mapped ${districtMap.size} / ${EXPECTED_COUNT} districts`);

  // ─── Step 3: Insert into geofence_boundaries ────────────────────────────────
  let inserted = 0;
  let skipped  = 0;

  for (const [distNum, geometryJson] of Array.from(districtMap.entries()).sort((a, b) => a[0] - b[0])) {
    const geoId = `sj-council-district-${distNum}`;
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
          public.ST_ForcePolygonCCW(
            public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326)
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

  // ─── Step 4: Summary + verify ────────────────────────────────────────────────
  console.log('\n  Summary:');
  console.log(`    Inserted: ${inserted}`);
  console.log(`    Skipped (already existed): ${skipped}`);

  if (!DRY_RUN) {
    const verify = await pool.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt
      FROM essentials.geofence_boundaries
      WHERE geo_id LIKE 'sj-council-district-%'
        AND mtfcc = $1
        AND state = $2
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`    Total SJ council district rows in geofence_boundaries: ${total}`);
    if (total !== EXPECTED_COUNT) {
      console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows, found ${total}`);
    } else {
      console.log(`  All ${EXPECTED_COUNT} SJ council districts loaded successfully.`);
    }
  }

  console.log('\n[load-sj-council-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-sj-council-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
