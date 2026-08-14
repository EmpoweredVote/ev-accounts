/**
 * load-seattle-council-boundaries.ts
 *
 * Fetches the 7 Seattle City Council district boundaries from the official
 * King County / Seattle ArcGIS Online FeatureServer and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='seattle-wa-council-district-1'..'-7',
 *                                   mtfcc='X0025', state='wa'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structural migration
 * creates the LOCAL district rows and offices that reference these.
 *
 * LAYER CHOICE — same trap as the King County council layer. Two services exist:
 *     SCCDST_AREA_2237       <- CURRENT (no year in the name)
 *     SCCDST_2015_AREA_3044  <- historic 2015 map
 * The 2015 service loads without error and would silently seed pre-redistricting
 * boundaries. Only the unsuffixed service is current.
 *
 * CRITICAL: outSR=4326 is mandatory — native CRS is WKID 2926 (Washington State
 * Plane North). Without it ST_GeomFromGeoJSON stores state-plane feet and every
 * point-in-polygon lookup silently misses.
 * CRITICAL: f=geojson (NOT f=json).
 * CRITICAL: state='wa' LOWERCASE — LOCAL-tier routing join key.
 *
 * SCCDST is a STRING field holding 'SCC1'..'SCC7' — parse the trailing digit for
 * the district number. There is no member-name field on this layer, so there is
 * no chance of keying identity off a name that changes with elections.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-seattle-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-seattle-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

const SEATTLE_DISTRICT_URL =
  'https://services.arcgis.com/Ej0PsM5Aw677QF1W/arcgis/rest/services/' +
  'SCCDST_AREA_2237/FeatureServer/0/query' +
  '?where=1%3D1&outFields=SCCDST,NAME' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC          = 'X0025';
const STATE_CODE     = 'wa';
const SOURCE         = 'seattle.gov-arcgis-SCCDST_AREA_2237-council-districts-2026';
const GEO_ID_PREFIX  = 'seattle-wa-council-district-';
const EXPECTED_COUNT = 7;

const DRY_RUN = process.argv.includes('--dry-run');

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

function fetchJson(url: string): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    lib.get(url, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return fetchJson(res.headers.location).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) return reject(new Error(`HTTP ${res.statusCode} fetching ${url}`));
      const chunks: Buffer[] = [];
      res.on('data', (c: Buffer) => chunks.push(c));
      res.on('end', () => {
        try { resolve(JSON.parse(Buffer.concat(chunks).toString('utf8'))); }
        catch (e) { reject(new Error(`JSON parse error: ${(e as Error).message}`)); }
      });
    }).on('error', reject);
  });
}

async function main() {
  console.log('[load-seattle-council-boundaries] Fetching Seattle council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = await fetchJson(SEATTLE_DISTRICT_URL) as {
    features?: Array<{ properties: { SCCDST?: string; NAME?: string; [k: string]: unknown }; geometry: object }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the Seattle FeatureServer. Check the URL.');
    process.exit(1);
  }
  console.log(`  Received ${response.features.length} features`);

  const distMap = new Map<number, { geoId: string; name: string; geomStr: string }>();
  for (const feature of response.features) {
    const raw = String(feature.properties['SCCDST'] ?? '');
    const dist = parseInt(raw.replace(/\D+/g, ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: SCCDST '${raw}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: district ${dist} has no geometry — skipping`);
      continue;
    }
    distMap.set(dist, {
      geoId: `${GEO_ID_PREFIX}${dist}`,
      name: `Seattle City Council District ${dist}`,
      geomStr: JSON.stringify(feature.geometry),
    });
    console.log(`  SCCDST ${raw}: geo_id=${GEO_ID_PREFIX}${dist}`);
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting.`);
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: coords should be ~-122.3° lon, ~47.6° lat for Seattle)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0, alreadyExists = 0, repaired = 0;
  for (const [dist, { geoId, name, geomStr }] of Array.from(distMap.entries()).sort((a, b) => a[0] - b[0])) {
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, '${MTFCC}', '${STATE_CODE}', $2,
         public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)), $4)
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid`,
      [geoId, name, geomStr, SOURCE],
    );

    if ((result.rowCount ?? 0) === 0) {
      alreadyExists++;
      console.log(`  District ${dist} (${geoId}): skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    if (row.valid !== true) {
      console.error(`  District ${dist} (${geoId}): ST_IsValid=false — applying ST_MakeValid`);
      await pool.query(
        `UPDATE essentials.geofence_boundaries
           SET geometry = public.ST_Multi(public.ST_MakeValid(
             public.ST_SetSRID(public.ST_GeomFromGeoJSON($2), 4326)))
         WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId, geomStr],
      );
      const recheck = await pool.query(
        `SELECT public.ST_IsValid(geometry) AS valid
           FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId],
      );
      if ((recheck.rows[0] as { valid: boolean })?.valid !== true) {
        console.error(`  ERROR: District ${dist} still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  District ${dist} (${geoId}): repaired via ST_MakeValid`);
    } else {
      console.log(`  District ${dist} (${geoId}): inserted (${row.gtype}, valid)`);
    }
    inserted++;
  }

  console.log(`\n=== Summary ===`);
  console.log(`  Inserted:        ${inserted}`);
  console.log(`  Already existed: ${alreadyExists}`);
  console.log(`  Repaired:        ${repaired}`);

  const check = await pool.query(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const { n, invalid } = check.rows[0] as { n: number; invalid: number };
  console.log(`  In DB now:       ${n} rows (${invalid} invalid)`);
  await pool.end();
  if (n !== EXPECTED_COUNT || invalid !== 0) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} valid rows, got ${n} with ${invalid} invalid.`);
    process.exit(1);
  }
  console.log('OK');
}

main().catch((err) => {
  console.error('[load-seattle-council-boundaries] Fatal error:', err);
  process.exit(1);
});
