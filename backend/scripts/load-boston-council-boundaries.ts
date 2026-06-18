/**
 * load-boston-council-boundaries.ts
 *
 * Fetches 9 City of Boston City Council district boundaries from the City's
 * ArcGIS FeatureServer and inserts them into essentials.geofence_boundaries.
 *
 * Source: https://services.arcgis.com/sFnw0xNflSi8J0uh/arcgis/rest/services/
 *         CityCouncilDistricts_2023_5_25/FeatureServer/0/query
 * Boundaries: 2023-2032 (effective 2023 municipal election)
 *
 * Each district stored with:
 *   geo_id  = 'boston-ma-council-district-{N}'  (N = 1..9)
 *   mtfcc   = 'X0013'
 *   state   = '25'  (Massachusetts FIPS — NOT 'MA' or 'ma')
 *   source  = 'boston_city_council_districts_2023'
 *
 * CRITICAL: outSR=4326 IS REQUIRED. Source uses Web Mercator (WKID 102100/3857).
 * CRITICAL: Test bulk where=1=1 first. If features.length < 9, fall back to
 *   per-DISTRICT individual queries (where=DISTRICT%3D{N}). Portland OR had
 *   silent truncation at 3 of 4 features with bulk fetch.
 * CRITICAL: '-ma-' geo_id qualifier prevents namespace collision with any
 *   future 'boston-...' prefix conflicts.
 * CRITICAL: X0013 mtfcc claimed by this script for Boston council districts.
 *   (Registry: X0005=LA County, X0006=SF, X0007=SD, X0008=Fremont,
 *    X0009=Berkeley, X0010=SJ, X0011=Sacramento, X0012=Portland OR council)
 *   Next available is X0014.
 *
 * IDEMPOTENCY: ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures safe re-runs.
 * ST_MakeValid: Apply after ST_ForcePolygonCCW for polygon self-intersections.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-boston-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-boston-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

const ARCGIS_BASE_URL =
  'https://services.arcgis.com/sFnw0xNflSi8J0uh/arcgis/rest/services/CityCouncilDistricts_2023_5_25/FeatureServer/0/query';

const MTFCC          = 'X0013';
const STATE          = '25';           // Massachusetts FIPS (NOT 'MA' or 'ma')
const SOURCE         = 'boston_city_council_districts_2023';
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
  console.log('[load-boston-council-boundaries] Fetching Boston City Council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // ─── Pre-flight: verify X0013 is unclaimed (or only Boston MA rows) ──────────
  if (!DRY_RUN) {
    const precheck = await pool.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries WHERE mtfcc='X0013'
    `);
    const existingCount = parseInt(precheck.rows[0].cnt, 10);
    if (existingCount > 0) {
      const bostonCheck = await pool.query<{ cnt: string }>(`
        SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries
        WHERE mtfcc='X0013' AND geo_id LIKE 'boston-ma-council-district-%'
      `);
      const bostonCount = parseInt(bostonCheck.rows[0].cnt, 10);
      if (bostonCount !== existingCount) {
        console.error(`ERROR: X0013 mtfcc already has ${existingCount} row(s) that are NOT boston-ma-council-district rows.`);
        console.error('  This script claims X0013 for Boston MA council districts. Aborting.');
        process.exit(1);
      }
      console.log(`  Pre-flight: X0013 has ${existingCount} existing Boston MA rows — re-run OK`);
    } else {
      console.log('  Pre-flight: X0013 is unclaimed — proceeding');
    }
  }

  // ─── Step 1a: Try bulk fetch (where=1=1) ────────────────────────────────────
  //
  // Boston ArcGIS FeatureServer may support bulk GeoJSON retrieval.
  // Test with where=1=1 first. If features.length < EXPECTED_COUNT,
  // fall back to per-DISTRICT loop (Portland OR lesson — silent truncation).

  const districtMap = new Map<number, string>(); // distNum -> GeoJSON geometry string

  const bulkUrl = `${ARCGIS_BASE_URL}?where=1%3D1&outFields=DISTRICT,Councilor,LONGNAME&outSR=4326&f=geojson`;
  console.log(`\n  Attempting bulk fetch: ${bulkUrl}`);

  let usedBulk = false;
  try {
    const bulkGeojson = await fetchJson(bulkUrl) as {
      type: string;
      features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }>;
    };

    if (bulkGeojson?.features?.length === EXPECTED_COUNT) {
      console.log(`  Bulk fetch returned ${bulkGeojson.features.length} features — using bulk results`);
      usedBulk = true;

      for (const feature of bulkGeojson.features) {
        const props = feature.properties || {};
        const rawDistrict = props['DISTRICT'];
        const distNum = parseInt(String(rawDistrict ?? ''), 10);
        if (isNaN(distNum) || distNum < 1 || distNum > MAX_DISTRICT) {
          console.error(`ERROR: DISTRICT='${rawDistrict}' out of range 1..${MAX_DISTRICT}`);
          process.exit(1);
        }
        if (districtMap.has(distNum)) {
          console.error(`ERROR: Duplicate features for district ${distNum}`);
          process.exit(1);
        }
        districtMap.set(distNum, JSON.stringify(feature.geometry));
        console.log(`  District ${distNum}: found via bulk (DISTRICT=${rawDistrict})`);
      }
    } else {
      const returned = bulkGeojson?.features?.length ?? 0;
      console.log(`  Bulk fetch returned ${returned} features (expected ${EXPECTED_COUNT}) — falling back to per-DISTRICT queries`);
    }
  } catch (err) {
    console.log(`  Bulk fetch failed (${(err as Error).message}) — falling back to per-DISTRICT queries`);
  }

  // ─── Step 1b: Per-DISTRICT fallback (if bulk didn't return all 9) ────────────
  //
  // CRITICAL: Validate distNum is integer in range 1..MAX_DISTRICT before constructing
  // geo_id string or running any query — T-108-01 (STRIDE Tampering mitigation).

  if (!usedBulk) {
    console.log(`\n  Fetching per-DISTRICT (1..${MAX_DISTRICT}):`);
    for (let distNum = 1; distNum <= MAX_DISTRICT; distNum++) {
      const url = `${ARCGIS_BASE_URL}?where=DISTRICT%3D${distNum}&outFields=DISTRICT,Councilor,LONGNAME&outSR=4326&f=geojson`;
      console.log(`\n  Fetching DISTRICT=${distNum}: ${url}`);

      let geojson: { type: string; features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }> };
      try {
        geojson = await fetchJson(url) as typeof geojson;
      } catch (err) {
        console.error(`ERROR fetching DISTRICT=${distNum}:`, (err as Error).message);
        process.exit(1);
      }

      if (!geojson?.features?.length) {
        console.error(`ERROR: DISTRICT=${distNum} returned no features`);
        process.exit(1);
      }

      const feature = geojson.features[0];
      const props = feature.properties || {};

      // Log available fields on first feature for diagnostics
      if (districtMap.size === 0) {
        console.log(`  Available fields: ${Object.keys(props).join(', ')}`);
      }

      // CRITICAL (T-108-01): Validate DISTRICT field is integer in range 1..MAX_DISTRICT
      // before constructing geo_id or running any query. Never interpolate into SQL directly.
      const rawDistrict = props['DISTRICT'];
      const parsedDistNum = parseInt(String(rawDistrict ?? ''), 10);
      if (isNaN(parsedDistNum) || parsedDistNum < 1 || parsedDistNum > MAX_DISTRICT) {
        console.error(`ERROR: DISTRICT='${rawDistrict}' out of range 1..${MAX_DISTRICT}`);
        process.exit(1);
      }

      if (districtMap.has(parsedDistNum)) {
        console.error(`ERROR: Duplicate features for district ${parsedDistNum}`);
        process.exit(1);
      }

      districtMap.set(parsedDistNum, JSON.stringify(feature.geometry));
      console.log(`  District ${parsedDistNum}: found (DISTRICT=${rawDistrict})`);
    }
  }

  // Abort if we didn't collect all 9
  if (districtMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: Expected ${EXPECTED_COUNT} districts, got ${districtMap.size}`);
    process.exit(1);
  }
  console.log(`\n  Mapped ${districtMap.size} / ${EXPECTED_COUNT} districts`);

  // ─── Step 2: Insert into geofence_boundaries ─────────────────────────────────
  let inserted = 0;
  let skipped  = 0;

  for (const [distNum, geometryJson] of Array.from(districtMap.entries()).sort((a, b) => a[0] - b[0])) {
    // CRITICAL: '-ma-' qualifier prevents namespace collision with any future 'boston-...' prefixes.
    // CRITICAL (T-108-01): distNum already validated as integer 1..MAX_DISTRICT above.
    const geoId = `boston-ma-council-district-${distNum}`;
    const name  = `District ${distNum}`;

    if (DRY_RUN) {
      console.log(`  [dry-run] Would insert: geo_id=${geoId}`);
      inserted++;
      continue;
    }

    try {
      // CRITICAL (T-108-02): Wrap geometry in ST_MakeValid(ST_ForcePolygonCCW(ST_SetSRID(ST_Force2D(
      // ST_GeomFromGeoJSON($6)), 4326))) — hardened PostGIS pipeline.
      // CRITICAL (T-108-01): All params via $N placeholders — NEVER string-interpolate into SQL.
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
      WHERE geo_id LIKE 'boston-ma-council-district-%'
        AND mtfcc = $1
        AND state = $2
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`  Total Boston MA council district rows in geofence_boundaries: ${total}`);
    if (total !== EXPECTED_COUNT) {
      console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows, found ${total}`);
    } else {
      console.log(`  All ${EXPECTED_COUNT} Boston MA council districts loaded successfully.`);
    }
  }

  console.log('\n[load-boston-council-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-boston-council-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
