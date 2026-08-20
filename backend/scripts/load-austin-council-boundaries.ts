/**
 * load-austin-council-boundaries.ts
 *
 * Fetches the 10 Austin City Council single-member district boundaries from the
 * City of Austin ArcGIS Online FeatureServer and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='austin-tx-council-district-1'..'-10',
 *                                   mtfcc='X0030', state='tx'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structural migration
 * creates the LOCAL district rows and REPOINTS the existing council offices.
 *
 * LAYER CHOICE — the same trap as Seattle, and here it actually bites. The
 * City of Austin org publishes FOUR layers that each return exactly 10 polygons,
 * so a headcount cannot tell them apart:
 *
 *     BOUNDARIES_single_member_districts  <- CURRENT (post-2021 commission map)
 *     CouncilDistricts_Web_2              <- also current (created 2022-06-28)
 *     Council_Districts                   <- STALE 2016 map, despite the name
 *     City_Council_Districts_2016         <- explicitly the 2016 map
 *
 * Measured 2026-08-19 on a 2,301-point grid over Travis County: the canonical
 * layer and Council_Districts disagree on 267 points — 11.6% of the city's
 * area — because Austin redistricted after the 2020 census. Loading the
 * plainest-named layer would have silently mis-assigned roughly one Austin
 * address in nine, with no error and no failing count. The discriminating
 * probe: Windsor Park (-97.690, 30.310) is District 4 on the current map and
 * District 1 on the 2016 map.
 *
 * CRITICAL: outSR=4326 is mandatory. CRITICAL: f=geojson (NOT f=json).
 * CRITICAL: state='tx' LOWERCASE — LOCAL-tier routing join key.
 *
 * COUNCIL_DISTRICT is an INTEGER field holding 1..10. Note that Austin has TEN
 * districts, so the trailing-digit parse used by the 7-district Seattle loader
 * (`right(geo_id, 1)`) is WRONG here — it maps district 10 onto '0'. The number
 * is parsed from the field, and the migration parses back with split_part.
 * There is no member-name field on this layer, so identity cannot be keyed off
 * a name that changes with elections.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-austin-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-austin-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';

const AUSTIN_DISTRICT_URL =
  'https://services.arcgis.com/0L95CJ0VTaxqcmED/arcgis/rest/services/' +
  'BOUNDARIES_single_member_districts/FeatureServer/0/query' +
  '?where=1%3D1&outFields=COUNCIL_DISTRICT' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC          = 'X0030';
const STATE_CODE     = 'tx';
const SOURCE         = 'austintexas.gov-arcgis-BOUNDARIES_single_member_districts-2026';
const GEO_ID_PREFIX  = 'austin-tx-council-district-';
const EXPECTED_COUNT = 10;

/**
 * Positive control. A uniform answer is a broken detector until a known point
 * resolves to a known district, so the load refuses to write unless the current
 * map's signature holds. Windsor Park is the point that MOVED in redistricting:
 * District 4 now, District 1 on the superseded map.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: number }> = [
  { name: 'Windsor Park (moved in 2021 redistricting)', lon: -97.6900, lat: 30.3100, district: 4 },
  { name: 'Austin City Hall',                           lon: -97.7470, lat: 30.2649, district: 9 },
  { name: 'Circle C (southwest)',                       lon: -97.8800, lat: 30.2100, district: 8 },
  { name: 'The Domain (north)',                         lon: -97.7256, lat: 30.4009, district: 7 },
];

const DRY_RUN = process.argv.includes('--dry-run');

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

type Feature = { properties: Record<string, unknown>; geometry: object | null };

/** Ray-cast point-in-polygon over a GeoJSON Polygon/MultiPolygon, holes honoured. */
function pointInGeometry(geom: any, lon: number, lat: number): boolean {
  const polys: number[][][][] = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  for (const poly of polys) {
    let inOuter = false;
    let inHole = false;
    poly.forEach((ring, idx) => {
      let hit = false;
      for (let a = 0, b = ring.length - 1; a < ring.length; b = a++) {
        const [xi, yi] = ring[a];
        const [xj, yj] = ring[b];
        if ((yi > lat) !== (yj > lat) && lon < ((xj - xi) * (lat - yi)) / (yj - yi) + xi) hit = !hit;
      }
      if (idx === 0) inOuter = hit;
      else if (hit) inHole = true;
    });
    if (inOuter && !inHole) return true;
  }
  return false;
}

async function main() {
  console.log('[load-austin-council-boundaries] Fetching Austin council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = (await (await fetch(AUSTIN_DISTRICT_URL)).json()) as { features?: Feature[] };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the Austin FeatureServer. Check the URL.');
    process.exit(1);
  }
  console.log(`  Received ${response.features.length} features`);

  const distMap = new Map<number, { geoId: string; name: string; geomStr: string; geom: any }>();
  for (const feature of response.features) {
    const raw = String(feature.properties['COUNCIL_DISTRICT'] ?? '');
    const dist = parseInt(raw.replace(/\D+/g, ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: COUNCIL_DISTRICT '${raw}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: district ${dist} has no geometry — skipping`);
      continue;
    }
    if (distMap.has(dist)) {
      console.error(`ERROR: district ${dist} appeared twice. Aborting rather than guessing.`);
      process.exit(1);
    }
    distMap.set(dist, {
      geoId: `${GEO_ID_PREFIX}${dist}`,
      name: `Austin City Council District ${dist}`,
      geomStr: JSON.stringify(feature.geometry),
      geom: feature.geometry,
    });
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting.`);
    process.exit(1);
  }
  console.log(`  Parsed districts: ${[...distMap.keys()].sort((a, b) => a - b).join(', ')}`);

  // ─── Positive control: prove this is the CURRENT map before writing ────────
  console.log('\n  Positive control (refuses the stale 2016 map):');
  let controlFailures = 0;
  for (const cp of CONTROL_POINTS) {
    const found = [...distMap.entries()]
      .filter(([, v]) => pointInGeometry(v.geom, cp.lon, cp.lat))
      .map(([d]) => d);
    const ok = found.length === 1 && found[0] === cp.district;
    if (!ok) controlFailures++;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  ${cp.name}: expected D${cp.district}, got ${found.length ? found.map((d) => 'D' + d).join('+') : 'none'}`,
    );
  }
  if (controlFailures > 0) {
    console.error(
      `\nERROR: ${controlFailures} control point(s) failed. This is NOT the current Austin map ` +
        `(or the layer changed). Refusing to write. Re-verify the layer before loading.`,
    );
    await pool.end();
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0, alreadyExists = 0, repaired = 0;
  for (const [dist, { geoId, name, geomStr }] of [...distMap.entries()].sort((a, b) => a[0] - b[0])) {
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
  console.error('[load-austin-council-boundaries] Fatal error:', err);
  process.exit(1);
});
