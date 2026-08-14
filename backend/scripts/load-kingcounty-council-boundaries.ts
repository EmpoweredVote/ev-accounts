/**
 * load-kingcounty-council-boundaries.ts
 *
 * Fetches the 9 Metropolitan King County Council district boundaries from the
 * official King County ArcGIS Online FeatureServer and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='kingcounty-wa-council-district-1'..'-9',
 *                                   mtfcc='X0026', state='wa'
 *
 * This loader writes ONLY to essentials.geofence_boundaries — it does NOT touch
 * essentials.districts or essentials.offices. The structural migration creates
 * the LOCAL district rows and offices that reference these geofences.
 *
 * LAYER CHOICE — this is the trap on this dataset. King County publishes FIVE
 * council-district feature services:
 *     KCCDST_AREA_185        <- CURRENT (no year in the name)
 *     KCCDST_2012_AREA_3039  <- historic
 *     KCCDST_2005_AREA_3038  <- historic
 *     KCCDST_2002_AREA_3037  <- historic
 *     KCCDST_1992_AREA_3036  <- historic
 * The year-suffixed services load without error and would silently seed
 * obsolete boundaries. Only the unsuffixed KCCDST_AREA_185 is current.
 * (King County's old gisdata.kingcounty.gov REST root now redirects to an
 * HTML "we moved" page — the data lives on ArcGIS Online.)
 *
 * CRITICAL: outSR=4326 is mandatory — this layer's native CRS is WKID 2926
 * (Washington State Plane North, a projected CRS). Without outSR=4326,
 * ST_GeomFromGeoJSON stores state-plane feet, not degrees, and every
 * point-in-polygon lookup silently misses.
 * CRITICAL: f=geojson (NOT f=json) — returns a GeoJSON FeatureCollection whose
 * feature.geometry can go straight into ST_GeomFromGeoJSON.
 * CRITICAL: state='wa' LOWERCASE — required for the LOCAL-tier routing join key.
 *
 * KCCDST (a STRING field holding '1'..'9') is the district key. COUNCILMEM
 * carries the sitting member's name, but member names change with elections —
 * identity comes from KCCDST, never from COUNCILMEM (the San Diego lesson).
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-kingcounty-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-kingcounty-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

const KC_DISTRICT_URL =
  'https://services.arcgis.com/Ej0PsM5Aw677QF1W/arcgis/rest/services/' +
  'KCCDST_AREA_185/FeatureServer/0/query' +
  '?where=1%3D1&outFields=KCCDST,COUNCILMEM' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC          = 'X0026';   // next unclaimed after X0025 (Seattle council)
const STATE_CODE     = 'wa';      // CRITICAL: lowercase — LOCAL-tier routing key
const SOURCE         = 'kingcounty.gov-arcgis-KCCDST_AREA_185-council-districts-2026';
const GEO_ID_PREFIX  = 'kingcounty-wa-council-district-';
const EXPECTED_COUNT = 9;

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
  console.log('[load-kingcounty-council-boundaries] Fetching King County council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = await fetchJson(KC_DISTRICT_URL) as {
    features?: Array<{
      properties: { KCCDST?: number | string; COUNCILMEM?: string; [key: string]: unknown };
      geometry: object;
    }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the King County FeatureServer. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${response.features.length} features`);

  const distMap = new Map<number, { geoId: string; name: string; member: string; geomStr: string }>();

  for (const feature of response.features) {
    const rawDist = feature.properties['KCCDST'];
    const dist = parseInt(String(rawDist ?? ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: KCCDST '${rawDist}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: district ${dist} has no geometry — skipping`);
      continue;
    }
    const geoId  = `${GEO_ID_PREFIX}${dist}`;
    const name   = `King County Council District ${dist}`;
    const member = String(feature.properties['COUNCILMEM'] ?? '(unknown)');
    distMap.set(dist, { geoId, name, member, geomStr: JSON.stringify(feature.geometry) });
    console.log(`  KCCDST ${dist}: geo_id=${geoId}  (sitting member per GIS: ${member})`);
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting.`);
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: coords should be ~-122° lon, ~47° lat for King County, WA)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;

  for (const [dist, { geoId, name, geomStr }] of Array.from(distMap.entries()).sort((a, b) => a[0] - b[0])) {
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, '${MTFCC}', '${STATE_CODE}', $2,
         public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)),
         $4)
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
      console.error(`  District ${dist} (${geoId}): ST_IsValid=false (gtype=${row.gtype}) — applying ST_MakeValid`);
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
        console.error(`  ERROR: District ${dist} (${geoId}) still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  District ${dist} (${geoId}): repaired via ST_MakeValid (now valid)`);
    } else {
      console.log(`  District ${dist} (${geoId}): inserted (${row.gtype}, valid)`);
    }
    inserted++;
  }

  console.log(`\n=== Summary ===`);
  console.log(`  Inserted:       ${inserted}`);
  console.log(`  Already existed:${alreadyExists}`);
  console.log(`  Repaired:       ${repaired}`);

  const check = await pool.query(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const { n, invalid } = check.rows[0] as { n: number; invalid: number };
  console.log(`  In DB now:      ${n} rows (${invalid} invalid)`);
  await pool.end();
  if (n !== EXPECTED_COUNT || invalid !== 0) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} valid rows, got ${n} with ${invalid} invalid.`);
    process.exit(1);
  }
  console.log('OK');
}

main().catch((err) => {
  console.error('[load-kingcounty-council-boundaries] Fatal error:', err);
  process.exit(1);
});
