/**
 * load-sf-supervisor-boundaries.ts
 *
 * Fetches the 11 SF Board of Supervisors District boundaries from DataSF
 * (Socrata rows.geojson endpoint) and inserts them into essentials.geofence_boundaries.
 *
 * Each district is stored with:
 *   geo_id  = 'sf-supervisor-district-{N}'
 *   mtfcc   = 'X0006'
 *   state   = '06'
 *   source  = 'sf_supervisor_districts_2022'
 *
 * IMPORTANT: DataSF is Socrata, NOT ArcGIS.
 *   - Do NOT append ?outSR=4326 (ArcGIS-only param — Socrata returns native WGS84)
 *   - District field is sup_dist_num (numeric), NOT DISTRICT
 *
 * Safe to re-run — ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures idempotency.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-sf-supervisor-boundaries.ts --dry-run
 *   npx tsx scripts/load-sf-supervisor-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// DataSF Socrata endpoint — native WGS84 GeoJSON; no outSR param needed
const DATASF_URL     = 'https://data.sfgov.org/api/views/f2zs-jevy/rows.geojson';
const MTFCC          = 'X0006';
const STATE          = '06';
const SOURCE         = 'sf_supervisor_districts_2022';
const EXPECTED_COUNT = 11;
const MAX_DISTRICT   = 11;

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
  console.log('[load-sf-supervisor-boundaries] Fetching SF Supervisor District boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // Pre-flight: check existing X0006 rows
  if (!DRY_RUN) {
    const preCheck = await pool.query(`
      SELECT COUNT(*) AS cnt
      FROM essentials.geofence_boundaries
      WHERE mtfcc = $1
    `, [MTFCC]);
    const existingCount = parseInt(preCheck.rows[0].cnt, 10);
    console.log(`\n  Pre-flight: ${existingCount} existing X0006 rows in geofence_boundaries`);
    if (existingCount > 0) {
      // Check they are all SF supervisor district rows
      const nonSfCheck = await pool.query(`
        SELECT COUNT(*) AS cnt
        FROM essentials.geofence_boundaries
        WHERE mtfcc = $1
          AND geo_id NOT LIKE 'sf-supervisor-district-%'
      `, [MTFCC]);
      const nonSfCount = parseInt(nonSfCheck.rows[0].cnt, 10);
      if (nonSfCount > 0) {
        console.error(`  ERROR: ${nonSfCount} X0006 row(s) exist that are NOT sf-supervisor-district-* — aborting`);
        process.exit(1);
      }
      console.log(`  All ${existingCount} existing X0006 rows are sf-supervisor-district-* rows (safe to continue)`);
    }
  }

  // Step 1: Fetch GeoJSON from DataSF Socrata
  console.log(`\n  Fetching: ${DATASF_URL}`);
  let geojson: { type: string; features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }> };
  try {
    geojson = await fetchJson(DATASF_URL) as typeof geojson;
  } catch (err) {
    console.error('ERROR fetching SF supervisor districts:', (err as Error).message);
    process.exit(1);
  }

  if (!geojson?.features?.length) {
    console.error('ERROR: No features returned from DataSF. Check the URL.');
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

    // DataSF uses sup_dist_num (numeric field) — NOT the ArcGIS DISTRICT field
    const rawDistrict = props['sup_dist_num'];
    const distNum = parseInt(String(rawDistrict ?? ''), 10);
    if (isNaN(distNum) || distNum < 1 || distNum > MAX_DISTRICT) {
      console.warn(`  WARNING: sup_dist_num value '${rawDistrict}' out of range — skipping`);
      continue;
    }

    if (districtMap.has(distNum)) {
      console.warn(`  WARNING: Duplicate features for district ${distNum} — keeping first`);
      continue;
    }

    districtMap.set(distNum, JSON.stringify(feature.geometry));
    console.log(`  District ${distNum}: found (sup_dist_num=${rawDistrict})`);
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
    const geoId = `sf-supervisor-district-${distNum}`;
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
      WHERE geo_id LIKE 'sf-supervisor-district-%'
        AND mtfcc = $1
        AND state = $2
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`  Total SF Supervisor District rows in geofence_boundaries: ${total}`);
    if (total !== EXPECTED_COUNT) {
      console.warn(`  WARNING: Expected ${EXPECTED_COUNT} rows, found ${total}`);
    } else {
      console.log(`  All ${EXPECTED_COUNT} supervisor districts loaded successfully.`);
    }
  }

  console.log('\n[load-sf-supervisor-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-sf-supervisor-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
