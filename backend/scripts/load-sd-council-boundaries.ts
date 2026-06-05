/**
 * load-sd-council-boundaries.ts
 *
 * Fetches the 9 City of San Diego City Council district boundaries from the
 * City's DoIT_Public ArcGIS MapServer (Layer 5) and inserts them into
 * essentials.geofence_boundaries.
 *
 * Each district is stored with:
 *   geo_id  = 'sd-council-district-{N}'  (N = 1..9)
 *   mtfcc   = 'X0007'
 *   state   = '06'
 *   source  = 'sd_city_council_districts_2022'
 *
 * CRITICAL: outSR=4326 IS REQUIRED. webmaps.sandiego.gov uses State Plane
 * WKID 2230 natively (NAD 1983 StatePlane California VI, units in US survey feet).
 * Omitting outSR=4326 stores garbage coordinates (e.g. 6295123.4, 1882346.2)
 * and breaks ST_Covers spatial queries.
 *
 * The field name is DISTRICT (integer 1-9). The NAME field holds the current
 * council member's name (e.g. "Joe LaCava") and MUST NOT be used for the
 * boundary name column — it changes with elections.
 *
 * X0007 falls through to the X% fallback rule in essentialsService.ts which
 * maps it to district_type IN ('LOCAL','COUNTY'). No service code change needed.
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures idempotency.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-sd-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-sd-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

const ARCGIS_URL =
  'https://webmaps.sandiego.gov/arcgis/rest/services/DoIT_Public/DoIT_Public/MapServer/5/query' +
  '?where=1%3D1&outFields=DISTRICT%2CNAME&outSR=4326&f=geojson';

const MTFCC          = 'X0007';
const STATE          = '06';
const SOURCE         = 'sd_city_council_districts_2022';
const EXPECTED_COUNT = 9;
const MAX_DISTRICT   = 9;

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
  console.log('[load-sd-council-boundaries] Fetching San Diego City Council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // ─── Pre-flight: verify X0007 is unclaimed (or only SD rows) ────────────────
  if (!DRY_RUN) {
    const precheck = await pool.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries WHERE mtfcc='X0007'
    `);
    const existingCount = parseInt(precheck.rows[0].cnt, 10);
    if (existingCount > 0) {
      // Check if existing rows are all SD rows (idempotency re-run scenario)
      const sdCheck = await pool.query<{ cnt: string }>(`
        SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries
        WHERE mtfcc='X0007' AND geo_id LIKE 'sd-council-district-%'
      `);
      const sdCount = parseInt(sdCheck.rows[0].cnt, 10);
      if (sdCount !== existingCount) {
        console.error(`ERROR: X0007 mtfcc already has ${existingCount} row(s) that are NOT sd-council-district rows.`);
        console.error('  This script claims X0007 for San Diego council districts. Aborting to prevent conflict.');
        process.exit(1);
      }
      console.log(`  Pre-flight: X0007 has ${existingCount} existing SD rows — re-run OK`);
    } else {
      console.log('  Pre-flight: X0007 is unclaimed — proceeding');
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

    const rawDistrict = props['DISTRICT'];
    const distNum = parseInt(String(rawDistrict ?? ''), 10);

    if (isNaN(distNum) || distNum < 1 || distNum > MAX_DISTRICT) {
      console.warn(`  WARNING: DISTRICT value '${rawDistrict}' out of range — skipping`);
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
    const geoId = `sd-council-district-${distNum}`;
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
      WHERE geo_id LIKE 'sd-council-district-%'
        AND mtfcc = $1
        AND state = $2
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`    Total SD council district rows in geofence_boundaries: ${total}`);
    if (total !== EXPECTED_COUNT) {
      console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows, found ${total}`);
    } else {
      console.log(`  All ${EXPECTED_COUNT} SD council districts loaded successfully.`);
    }
  }

  console.log('\n[load-sd-council-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-sd-council-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
