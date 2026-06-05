/**
 * load-berkeley-council-boundaries.ts
 *
 * Fetches the 8 Berkeley City Council District boundaries from the City of Berkeley
 * Open Data Socrata endpoint and inserts them into essentials.geofence_boundaries.
 *
 * Each district is stored with:
 *   geo_id  = 'berkeley-council-district-{N}'
 *   mtfcc   = 'X0009'
 *   state   = '06'
 *   source  = 'berkeley_city_council_districts'
 *
 * IMPORTANT: Berkeley Open Data is Socrata, NOT ArcGIS.
 *   - Do NOT append ?outSR=4326 (ArcGIS-only param — Socrata returns native WGS84)
 *   - District field is 'district' (lowercase string, values "1"-"8")
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures idempotency.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-berkeley-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-berkeley-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// Berkeley Open Data Socrata endpoint — native WGS84 GeoJSON; no outSR param needed
const SOCRATA_URL    = 'https://data.cityofberkeley.info/resource/c8zs-8y7x.geojson?$limit=50';
const MTFCC          = 'X0009';
const STATE          = '06';
const SOURCE         = 'berkeley_city_council_districts';
const EXPECTED_COUNT = 8;
const MAX_DISTRICT   = 8;

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
  console.log('[load-berkeley-council-boundaries] Fetching Berkeley City Council District boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // Pre-flight: check if X0009 is claimed by non-Berkeley rows
  if (!DRY_RUN) {
    const precheck = await pool.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries WHERE mtfcc='X0009'
    `);
    const existingCount = parseInt(precheck.rows[0].cnt, 10);
    if (existingCount > 0) {
      const berkeleyCheck = await pool.query<{ cnt: string }>(`
        SELECT COUNT(*) AS cnt FROM essentials.geofence_boundaries
        WHERE mtfcc='X0009' AND geo_id LIKE 'berkeley-council-district-%'
      `);
      const berkeleyCount = parseInt(berkeleyCheck.rows[0].cnt, 10);
      if (berkeleyCount !== existingCount) {
        console.error(`ERROR: X0009 mtfcc already has ${existingCount} row(s) that are NOT berkeley-council-district rows.`);
        process.exit(1);
      }
      console.log(`  Pre-flight: X0009 has ${existingCount} existing Berkeley rows — re-run OK`);
    } else {
      console.log('  Pre-flight: X0009 is unclaimed — proceeding');
    }
  }

  // Step 1: Fetch GeoJSON from Berkeley Open Data Socrata
  console.log(`\n  Fetching: ${SOCRATA_URL}`);
  let geojson: { type: string; features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }> };
  try {
    geojson = await fetchJson(SOCRATA_URL) as typeof geojson;
  } catch (err) {
    console.error('ERROR fetching Berkeley council districts:', (err as Error).message);
    process.exit(1);
  }

  if (!geojson?.features?.length) {
    console.error('ERROR: No features returned from Berkeley Open Data. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${geojson.features.length} features`);
  if (geojson.features.length > 0) {
    // Log available fields on first feature as diagnostic aid
    console.log(`  Available fields: ${Object.keys(geojson.features[0]?.properties || {}).join(', ')}`);
  }

  // Step 2: Map features to district numbers
  const districtMap = new Map<number, string>(); // distNum -> GeoJSON geometry string

  for (const feature of geojson.features) {
    const props = feature.properties || {};

    // Berkeley Socrata uses 'district' (lowercase) with string values "1"-"8"
    const rawDistrict = props['district'];
    const distNum = parseInt(String(rawDistrict ?? ''), 10);
    if (isNaN(distNum) || distNum < 1 || distNum > MAX_DISTRICT) {
      console.warn(`  WARNING: district value '${rawDistrict}' out of range — skipping`);
      continue;
    }

    if (districtMap.has(distNum)) {
      console.warn(`  WARNING: Duplicate features for district ${distNum} — keeping first`);
      continue;
    }

    districtMap.set(distNum, JSON.stringify(feature.geometry));
    console.log(`  District ${distNum}: found (district=${rawDistrict})`);
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
    const geoId = `berkeley-council-district-${distNum}`;
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

  // Step 4: Summary
  console.log('\n  Summary:');
  console.log(`    Inserted: ${inserted}`);
  console.log(`    Skipped (already existed): ${skipped}`);

  // Step 5: Post-insert verification (not in dry-run)
  if (!DRY_RUN) {
    const verify = await pool.query(`
      SELECT COUNT(*) AS cnt
      FROM essentials.geofence_boundaries
      WHERE geo_id LIKE 'berkeley-council-district-%'
        AND mtfcc = $1
        AND state = $2
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`  Total Berkeley Council District rows in geofence_boundaries: ${total}`);
    if (total !== EXPECTED_COUNT) {
      console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows, found ${total}`);
    } else {
      console.log(`  All ${EXPECTED_COUNT} council districts loaded successfully.`);
    }
  }

  console.log('\n[load-berkeley-council-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-berkeley-council-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
