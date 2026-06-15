/**
 * load-worcester-council-boundaries.ts
 *
 * Fetches 5 pre-dissolved Worcester City Council district boundaries from the
 * City of Worcester's ArcGIS FeatureServer and inserts them into
 * essentials.geofence_boundaries.
 *
 * CRITICAL: Worcester uses Council_Districts_2026 FeatureServer (5 council districts).
 * Do NOT use MassGIS WARDSPRECINCTS2022_POLY for Worcester — that has 10 voting wards
 * (60 precincts), not the 5 council districts. See Pitfall 5 in 119-RESEARCH.md.
 *
 * CRITICAL: X0014 mtfcc claimed by this script for Phase 119 MA city council districts
 * (Worcester, Springfield, Lowell, Brockton, Quincy). X0013 = Boston.
 * (Registry: X0005=LA County, X0006=SF, X0007=SD, X0008=Fremont,
 *  X0009=Berkeley, X0010=SJ, X0011=Sacramento, X0012=Portland OR council, X0013=Boston MA)
 * X0014 = Worcester + Springfield + Lowell + Brockton + Quincy MA council/ward districts (Phase 119)
 *
 * Source: https://services1.arcgis.com/j8dqo2DJE7mVUBU1/arcgis/rest/services/
 *         Council_Districts_2026/FeatureServer/0/query
 * Field: 'Council_District' (SmallInteger, values 1–5)
 *
 * Each district stored with:
 *   geo_id  = 'worcester-ma-council-district-{N}'  (N = 1..5)
 *   mtfcc   = 'X0014'
 *   state   = '25'  (Massachusetts FIPS — NOT 'MA' or 'ma')
 *   source  = 'worcester_city_council_districts_2026'
 *
 * CRITICAL: outSR=4326 IS REQUIRED. Source may use Web Mercator (WKID 102100/3857).
 * CRITICAL: Test bulk where=1=1 first. If features.length < 5, fall back to
 *   per-Council_District individual queries. Portland OR had silent truncation.
 * CRITICAL: '-ma-' geo_id qualifier prevents namespace collision.
 * IDEMPOTENCY: ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures safe re-runs.
 * ST_MakeValid: Apply after ST_ForcePolygonCCW for polygon self-intersections.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-worcester-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-worcester-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

const ARCGIS_BASE_URL =
  'https://services1.arcgis.com/j8dqo2DJE7mVUBU1/arcgis/rest/services/Council_Districts_2026/FeatureServer/0/query';

const MTFCC          = 'X0014';
const STATE          = '25';           // Massachusetts FIPS (NOT 'MA' or 'ma')
const SOURCE         = 'worcester_city_council_districts_2026';
const EXPECTED_COUNT = 5;
const MAX_DISTRICT   = 5;
const FIELD_NAME     = 'Council_District'; // SmallInteger, values 1–5

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
  console.log('[load-worcester-council-boundaries] Fetching Worcester City Council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // ─── Pre-flight: verify X0014 namespace is unclaimed or only Worcester rows ──
  if (!DRY_RUN) {
    const precheck = await pool.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries WHERE mtfcc='X0014'
    `);
    const existingCount = parseInt(precheck.rows[0].cnt, 10);
    if (existingCount > 0) {
      const worcesterCheck = await pool.query<{ cnt: string }>(`
        SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries
        WHERE mtfcc='X0014' AND geo_id LIKE 'worcester-ma-council-district-%'
      `);
      const worcesterCount = parseInt(worcesterCheck.rows[0].cnt, 10);
      if (worcesterCount !== existingCount) {
        // There are X0014 rows that are NOT worcester rows — this is unexpected
        // but X0014 is shared by all Phase 119 cities; check if they're all Phase 119 cities
        const phase119Check = await pool.query<{ cnt: string }>(`
          SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries
          WHERE mtfcc='X0014'
            AND (
              geo_id LIKE 'worcester-ma-council-district-%'
              OR geo_id LIKE 'springfield-ma-council-ward-%'
              OR geo_id LIKE 'lowell-ma-council-district-%'
              OR geo_id LIKE 'brockton-ma-council-ward-%'
              OR geo_id LIKE 'quincy-ma-council-ward-%'
            )
        `);
        const phase119Count = parseInt(phase119Check.rows[0].cnt, 10);
        if (phase119Count !== existingCount) {
          console.error(`ERROR: X0014 mtfcc has ${existingCount} row(s) that are NOT Phase 119 MA city council district rows.`);
          console.error('  X0014 is claimed for Phase 119 MA city council districts. Aborting.');
          process.exit(1);
        }
        console.log(`  Pre-flight: X0014 has ${existingCount} existing Phase 119 MA rows — re-run OK`);
      } else {
        console.log(`  Pre-flight: X0014 has ${existingCount} existing Worcester MA rows — re-run OK`);
      }
    } else {
      console.log('  Pre-flight: X0014 is unclaimed — proceeding');
    }
  }

  // ─── Step 1a: Try bulk fetch (where=1=1) ────────────────────────────────────
  //
  // Worcester ArcGIS FeatureServer should support bulk GeoJSON retrieval.
  // Test with where=1=1 first. If features.length < EXPECTED_COUNT,
  // fall back to per-Council_District loop (Portland OR lesson — silent truncation).

  const districtMap = new Map<number, string>(); // distNum -> GeoJSON geometry string

  const bulkUrl = `${ARCGIS_BASE_URL}?where=1%3D1&outFields=${FIELD_NAME}&outSR=4326&f=geojson`;
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
        const rawDistrict = props[FIELD_NAME];
        // CRITICAL (T-119-W1): Validate Council_District field is integer in range 1..MAX_DISTRICT
        // before constructing geo_id — STRIDE Tampering mitigation. Never interpolate into SQL.
        const distNum = parseInt(String(rawDistrict ?? ''), 10);
        if (isNaN(distNum) || distNum < 1 || distNum > MAX_DISTRICT) {
          console.error(`ERROR: ${FIELD_NAME}='${rawDistrict}' out of range 1..${MAX_DISTRICT}`);
          process.exit(1);
        }
        if (districtMap.has(distNum)) {
          console.error(`ERROR: Duplicate features for district ${distNum}`);
          process.exit(1);
        }
        districtMap.set(distNum, JSON.stringify(feature.geometry));
        console.log(`  District ${distNum}: found via bulk (${FIELD_NAME}=${rawDistrict})`);
      }
    } else {
      const returned = bulkGeojson?.features?.length ?? 0;
      console.log(`  Bulk fetch returned ${returned} features (expected ${EXPECTED_COUNT}) — falling back to per-${FIELD_NAME} queries`);
    }
  } catch (err) {
    console.log(`  Bulk fetch failed (${(err as Error).message}) — falling back to per-${FIELD_NAME} queries`);
  }

  // ─── Step 1b: Per-Council_District fallback (if bulk didn't return all 5) ───
  //
  // CRITICAL: Validate distNum is integer in range 1..MAX_DISTRICT before constructing
  // geo_id string or running any query — T-119-W1 (STRIDE Tampering mitigation).

  if (!usedBulk) {
    console.log(`\n  Fetching per-${FIELD_NAME} (1..${MAX_DISTRICT}):`);
    for (let distNum = 1; distNum <= MAX_DISTRICT; distNum++) {
      const url = `${ARCGIS_BASE_URL}?where=${FIELD_NAME}%3D${distNum}&outFields=${FIELD_NAME}&outSR=4326&f=geojson`;
      console.log(`\n  Fetching ${FIELD_NAME}=${distNum}: ${url}`);

      let geojson: { type: string; features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }> };
      try {
        geojson = await fetchJson(url) as typeof geojson;
      } catch (err) {
        console.error(`ERROR fetching ${FIELD_NAME}=${distNum}:`, (err as Error).message);
        process.exit(1);
      }

      if (!geojson?.features?.length) {
        console.error(`ERROR: ${FIELD_NAME}=${distNum} returned no features`);
        process.exit(1);
      }

      const feature = geojson.features[0];
      const props = feature.properties || {};

      // Log available fields on first feature for diagnostics
      if (districtMap.size === 0) {
        console.log(`  Available fields: ${Object.keys(props).join(', ')}`);
      }

      // CRITICAL (T-119-W1): Validate Council_District field is integer in range 1..MAX_DISTRICT
      // before constructing geo_id or running any query. Never interpolate into SQL directly.
      const rawDistrict = props[FIELD_NAME];
      const parsedDistNum = parseInt(String(rawDistrict ?? ''), 10);
      if (isNaN(parsedDistNum) || parsedDistNum < 1 || parsedDistNum > MAX_DISTRICT) {
        console.error(`ERROR: ${FIELD_NAME}='${rawDistrict}' out of range 1..${MAX_DISTRICT}`);
        process.exit(1);
      }

      if (districtMap.has(parsedDistNum)) {
        console.error(`ERROR: Duplicate features for district ${parsedDistNum}`);
        process.exit(1);
      }

      districtMap.set(parsedDistNum, JSON.stringify(feature.geometry));
      console.log(`  District ${parsedDistNum}: found (${FIELD_NAME}=${rawDistrict})`);
    }
  }

  // Abort if we didn't collect all 5
  if (districtMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: Expected ${EXPECTED_COUNT} districts, got ${districtMap.size}`);
    process.exit(1);
  }
  console.log(`\n  Mapped ${districtMap.size} / ${EXPECTED_COUNT} districts`);

  // ─── Step 2: Insert into geofence_boundaries ─────────────────────────────────
  let inserted = 0;
  let skipped  = 0;

  for (const [distNum, geometryJson] of Array.from(districtMap.entries()).sort((a, b) => a[0] - b[0])) {
    // CRITICAL: '-ma-' qualifier prevents namespace collision with any future 'worcester-...' prefixes.
    // CRITICAL (T-119-W1): distNum already validated as integer 1..MAX_DISTRICT above.
    const geoId = `worcester-ma-council-district-${distNum}`;
    const name  = `District ${distNum}`;

    if (DRY_RUN) {
      console.log(`  [dry-run] Would insert: geo_id=${geoId}`);
      inserted++;
      continue;
    }

    try {
      // CRITICAL: Wrap geometry in ST_MakeValid(ST_ForcePolygonCCW(ST_SetSRID(ST_Force2D(
      // ST_GeomFromGeoJSON($6)), 4326))) — hardened PostGIS pipeline (mirrors Boston script).
      // CRITICAL (T-119-W1): All params via $N placeholders — NEVER string-interpolate into SQL.
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
      WHERE geo_id LIKE 'worcester-ma-council-district-%'
        AND mtfcc = $1
        AND state = $2
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`  Total Worcester MA council district rows in geofence_boundaries: ${total}`);
    if (total !== EXPECTED_COUNT) {
      console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows, found ${total}`);
    } else {
      console.log(`  All ${EXPECTED_COUNT} Worcester MA council districts loaded successfully.`);
    }
  }

  console.log('\n[load-worcester-council-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-worcester-council-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
