/**
 * load-dc-ward-boundaries.ts
 *
 * Fetches the 8 DC Ward boundaries (Ward - 2022) from the DC DCGIS MapServer
 * (Administrative_Other_Boundaries_WebMercator, Layer 53) and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='11001'-'11008', mtfcc='G5220', state='11'
 *   essentials.geo_districts         layer='dc_ward', geoid='11001'-'11008'
 *
 * Both inserts are idempotent (ON CONFLICT ... DO NOTHING).
 *
 * TIGER note: tl_2024_11_sldl.zip returns 404 — Census does not publish a
 * standalone DC SLDL shapefile. DC GIS MapServer layer 53 is the canonical
 * source for DC ward polygons (Ward - 2022 vintage, native WGS84 via outSR=4326).
 *
 * GEOID: MapServer returns full GEOID like '610U600US11001'; we extract the
 * trailing 5 chars ('11001'-'11008') which match TIGER SLDL GEOID format.
 *
 * Geometry: MapServer returns Polygon; geo_districts expects MULTIPOLYGON.
 * ST_Multi() wraps the Polygon without altering coordinates.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-dc-ward-boundaries.ts --dry-run
 *   npx tsx scripts/load-dc-ward-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

const DCGIS_URL =
  'https://maps2.dcgis.dc.gov/dcgis/rest/services/DCGIS_DATA/' +
  'Administrative_Other_Boundaries_WebMercator/MapServer/53/query' +
  '?where=1%3D1&outFields=WARD%2CNAME%2CGEOID&outSR=4326&f=geojson';

const MTFCC          = 'G5220';
const STATE_FIPS     = '11';
const SOURCE         = 'dc_ward_2022';
const LAYER          = 'dc_ward';
const EXPECTED_COUNT = 8;

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
        try { resolve(JSON.parse(Buffer.concat(chunks).toString('utf8'))); }
        catch (e) { reject(new Error(`JSON parse error: ${(e as Error).message}`)); }
      });
    }).on('error', reject);
  });
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-dc-ward-boundaries] Fetching DC Ward - 2022 boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const geojson = await fetchJson(DCGIS_URL) as {
    type: string;
    features: Array<{
      type: string;
      geometry: { type: string; coordinates: unknown[] };
      properties: Record<string, unknown>;
    }>;
  };

  if (!geojson?.features?.length) {
    console.error('ERROR: No features returned from DC GIS. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${geojson.features.length} features`);

  // Build ward map keyed by WARD number
  const wardMap = new Map<number, { geoid: string; name: string; geomJson: string }>();

  for (const feature of geojson.features) {
    const props = feature.properties || {};
    const ward = parseInt(String(props['WARD'] ?? ''), 10);
    if (isNaN(ward) || ward < 1 || ward > EXPECTED_COUNT) {
      console.warn(`  WARNING: WARD '${props['WARD']}' out of range — skipping`);
      continue;
    }

    // Extract 5-char TIGER GEOID from full GEOID string (e.g. '610U600US11001' → '11001')
    const rawGeoid = String(props['GEOID'] ?? '');
    const geoid = rawGeoid.slice(-5);
    if (!/^11\d{3}$/.test(geoid)) {
      console.warn(`  WARNING: unexpected GEOID format '${rawGeoid}' for ward ${ward} — expected trailing '110XX'`);
      continue;
    }

    const name = String(props['NAME'] ?? `Ward ${ward}`);
    wardMap.set(ward, { geoid, name, geomJson: JSON.stringify(feature.geometry) });
    console.log(`  Ward ${ward}: GEOID=${geoid} NAME=${name}`);
  }

  if (wardMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} wards, got ${wardMap.size}. Aborting.`);
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    process.exit(0);
  }

  let insertedBoundary = 0;
  let insertedGeoDistrict = 0;
  let alreadyExists = 0;

  for (const [ward, { geoid, name, geomJson }] of Array.from(wardMap.entries()).sort((a, b) => a[0] - b[0])) {
    const districtNum = String(ward);

    // 1. geofence_boundaries
    const bResult = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
       VALUES ($1, NULL, $2, $3, $4,
         ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($5)), 4326),
         $6, now())
       ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
      [geoid, name, STATE_FIPS, MTFCC, geomJson, SOURCE],
    );
    if ((bResult.rowCount ?? 0) > 0) {
      insertedBoundary++;
    } else {
      alreadyExists++;
    }

    // 2. geo_districts (MULTIPOLYGON — ST_Multi wraps Polygon without altering coordinates)
    const gResult = await pool.query(
      `INSERT INTO essentials.geo_districts (layer, geoid, district_num, name, geom)
       VALUES ($1, $2, $3, $4,
         ST_Multi(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($5)), 4326))
       )
       ON CONFLICT (layer, geoid) DO NOTHING`,
      [LAYER, geoid, districtNum, name, geomJson],
    );
    if ((gResult.rowCount ?? 0) > 0) {
      insertedGeoDistrict++;
    }

    console.log(`  Ward ${ward} (${geoid}): boundary=${(bResult.rowCount??0)>0?'inserted':'skipped'} geo_district=${(gResult.rowCount??0)>0?'inserted':'skipped'}`);
  }

  await pool.end();

  console.log('\n=== Summary ===');
  console.log(`  geofence_boundaries inserted: ${insertedBoundary}`);
  console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
  console.log(`  geo_districts inserted: ${insertedGeoDistrict}`);

  console.log('\nVerify with:');
  console.log(`  SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE state = '11' AND mtfcc = 'G5220';  -- expect 8`);
  console.log(`  SELECT COUNT(*) FROM essentials.geo_districts WHERE layer = 'dc_ward';  -- expect 8`);
  console.log(`  SELECT geoid, district_num, name FROM essentials.geo_districts WHERE layer = 'dc_ward' ORDER BY geoid;`);
}

main().catch((err) => {
  console.error('[load-dc-ward-boundaries] Fatal error:', err);
  process.exit(1);
});
