/**
 * load-la-county-supervisor-boundaries.ts
 *
 * Fetches the 5 LA County Supervisorial District boundaries from the LA County
 * GIS ArcGIS MapServer and inserts them into essentials.geofence_boundaries.
 *
 * Each district is stored with:
 *   geo_id  = 'ocd-division/country:us/state:ca/county:los_angeles/council_district:{N}'
 *   mtfcc   = 'X0005'
 *   state   = '06'
 *   source  = 'la_county_geohub_supervisor_districts_2024'
 *
 * These geo_ids match existing rows in essentials.districts (district_type='LOCAL'),
 * so resolve_user_jurisdiction will find the correct supervisor district for any
 * LA County address. The X0005 mtfcc falls through to the X% fallback rule in
 * essentialsService.ts which maps it to district_type IN ('LOCAL', 'COUNTY').
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures idempotency.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-la-county-supervisor-boundaries.ts --dry-run
 *   npx tsx scripts/load-la-county-supervisor-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// LA County GIS — Supervisorial Districts (Current), Layer 27 (public, no auth)
// outSR=4326 is mandatory — native CRS is CA State Plane feet
const ARCGIS_URL =
  'https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/27/query' +
  '?where=1%3D1&outFields=*&outSR=4326&f=geojson';

const MTFCC          = 'X0005';
const STATE          = '06';
const SOURCE         = 'la_county_geohub_supervisor_districts_2024';
const EXPECTED_COUNT = 5;
const MAX_DISTRICT   = 5;

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
  console.log('[load-la-county-supervisor-boundaries] Fetching LA County Supervisorial District boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // Step 1: Fetch GeoJSON from ArcGIS
  console.log(`\n  Fetching: ${ARCGIS_URL}`);
  let geojson: { type: string; features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }> };
  try {
    geojson = await fetchJson(ARCGIS_URL) as typeof geojson;
  } catch (err) {
    console.error('ERROR fetching supervisorial districts:', (err as Error).message);
    process.exit(1);
  }

  if (!geojson?.features?.length) {
    console.error('ERROR: No features returned from ArcGIS. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${geojson.features.length} features`);
  if (geojson.features.length > 0) {
    console.log(`  Available fields: ${Object.keys(geojson.features[0]?.properties || {}).join(', ')}`);
  }

  // Step 2: Map features to district numbers
  const districtMap = new Map<number, string>(); // distNum -> GeoJSON geometry string

  for (const feature of geojson.features) {
    const props = feature.properties || {};

    // DISTRICT field is a 1-char string: "1"–"5"
    const rawDistrict = props['DISTRICT'];
    if (rawDistrict == null) {
      // Try SUPERVISORIAL_DISTRICT as fallback
      const rawAlt = props['SUPERVISORIAL_DISTRICT'] ?? props['SUP_DIST'] ?? props['DISTRICT_NUM'];
      if (rawAlt == null) {
        console.warn(`  WARNING: Feature missing DISTRICT field — properties: ${JSON.stringify(props)}`);
        continue;
      }
      const distNum = parseInt(String(rawAlt), 10);
      if (isNaN(distNum) || distNum < 1 || distNum > MAX_DISTRICT) {
        console.warn(`  WARNING: Alternate district value '${rawAlt}' out of range 1-${MAX_DISTRICT} — skipping`);
        continue;
      }
      districtMap.set(distNum, JSON.stringify(feature.geometry));
      console.log(`  District ${distNum}: found (via fallback field)`);
      continue;
    }

    const distNum = parseInt(String(rawDistrict), 10);
    if (isNaN(distNum) || distNum < 1 || distNum > MAX_DISTRICT) {
      console.warn(`  WARNING: DISTRICT value '${rawDistrict}' out of range 1-${MAX_DISTRICT} — skipping`);
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
    console.error('ERROR: Could not extract any district numbers. Dumping first feature properties for diagnosis:');
    console.error(JSON.stringify(geojson.features[0]?.properties, null, 2));
    process.exit(1);
  }

  console.log(`\n  Mapped ${districtMap.size} / ${EXPECTED_COUNT} districts`);

  // Step 3: Insert into geofence_boundaries
  let inserted = 0;
  let skipped  = 0;

  for (const [distNum, geometryJson] of Array.from(districtMap.entries()).sort((a, b) => a[0] - b[0])) {
    const geoId = `ocd-division/country:us/state:ca/county:los_angeles/council_district:${distNum}`;
    const name  = `Los Angeles County Supervisorial District ${distNum}`;

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

  // Step 4: Summary
  console.log('\n  Summary:');
  console.log(`    Inserted: ${inserted}`);
  console.log(`    Skipped (already existed): ${skipped}`);

  // Step 5: Post-insert verification (not in dry-run)
  if (!DRY_RUN) {
    const verify = await pool.query(`
      SELECT COUNT(*) AS cnt
      FROM essentials.geofence_boundaries
      WHERE geo_id LIKE 'ocd-division/country:us/state:ca/county:los_angeles/council_district:%'
        AND mtfcc = $1
        AND state = $2
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`  Total LA County Supervisor rows in geofence_boundaries: ${total}`);
    if (total !== EXPECTED_COUNT) {
      console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows, found ${total}`);
    } else {
      console.log(`  All ${EXPECTED_COUNT} supervisorial districts loaded successfully.`);
    }
  }

  console.log('\n[load-la-county-supervisor-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-la-county-supervisor-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
