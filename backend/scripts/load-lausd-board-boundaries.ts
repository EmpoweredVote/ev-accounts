/**
 * load-lausd-board-boundaries.ts
 *
 * Fetches the 7 LAUSD Board District boundaries from the LA GeoHub
 * ArcGIS FeatureServer and inserts them into essentials.geofence_boundaries.
 *
 * Each district is stored with:
 *   geo_id  = 'lausd-board-district-{N}'  (N = 1..7)
 *   mtfcc   = 'G5420'
 *   state   = '06'
 *   source  = 'lausd_geohub_board_districts_2024'
 *
 * NOTE: There are already 346 G5420 rows for CA (TIGER UNSD). The smoke test
 * COUNT gate must filter by geo_id LIKE 'lausd-board-district-%', not raw mtfcc.
 *
 * NOTE for Phase 62: when creating districts rows for LAUSD board members,
 * use district_type = 'SCHOOL' (not 'SCHOOL_DISTRICT') to match essentialsService.ts.
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures idempotency.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-lausd-board-boundaries.ts --dry-run
 *   npx tsx scripts/load-lausd-board-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// LA GeoHub ArcGIS FeatureServer — LAUSD Board Districts (public, no auth required)
// outSR=4326 is mandatory — native CRS is CA State Plane feet
const ARCGIS_URL =
  'https://maps.lacity.org/lahub/rest/services/LAUSD_Schools/MapServer/7/query' +
  '?where=1%3D1&outFields=DISTRICT,MEMBER&outSR=4326&f=geojson';

const MTFCC          = 'G5420';
const STATE          = '06';
const SOURCE         = 'lausd_geohub_board_districts_2024';
const EXPECTED_COUNT = 7;
const MAX_DISTRICT   = 7;

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
  console.log('[load-lausd-board-boundaries] Fetching LAUSD Board District boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // Step 1: Fetch GeoJSON from ArcGIS
  console.log(`\n  Fetching: ${ARCGIS_URL}`);
  let geojson: { type: string; features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }> };
  try {
    geojson = await fetchJson(ARCGIS_URL) as typeof geojson;
  } catch (err) {
    console.error('ERROR fetching LAUSD board districts:', (err as Error).message);
    process.exit(1);
  }

  if (!geojson?.features?.length) {
    console.error('ERROR: No features returned from ArcGIS. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${geojson.features.length} features`);

  // Step 2: Map features to district numbers
  const districtMap = new Map<number, string>(); // distNum -> GeoJSON geometry string

  for (const feature of geojson.features) {
    const props = feature.properties || {};

    // Read the DISTRICT field — this is the board sub-district number 1-7
    const rawDistrict = props['DISTRICT'];
    if (rawDistrict == null) {
      console.warn(`  WARNING: Feature missing DISTRICT field — properties: ${JSON.stringify(props)}`);
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
    const member = props['MEMBER'] ? ` (${props['MEMBER']})` : '';
    console.log(`  District ${distNum}${member}: found`);
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
    // NOTE: Do NOT use the MEMBER field for name — board members change with elections;
    // the district number is stable.
    const geoId = `lausd-board-district-${distNum}`;
    const name  = `Board District ${distNum}`;
    // ocd_id: same as geoId (no OCD format exists for LAUSD sub-districts)

    if (DRY_RUN) {
      console.log(`  [dry-run] Would insert: geo_id=${geoId}, name="${name}"`);
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
      WHERE geo_id LIKE 'lausd-board-district-%'
        AND mtfcc = $1
        AND state = $2
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`  Total LAUSD board district rows in geofence_boundaries: ${total}`);
    if (total !== EXPECTED_COUNT) {
      console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows, found ${total}`);
    } else {
      console.log(`  All ${EXPECTED_COUNT} LAUSD board districts loaded successfully.`);
    }
  }

  console.log('\n[load-lausd-board-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-lausd-board-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
