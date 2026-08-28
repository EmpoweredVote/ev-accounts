/**
 * load-davidson-council-boundaries.ts
 *
 * Fetches the 35 Metropolitan Council district boundaries for Nashville /
 * Davidson County (TN) and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='nashville-tn-council-district-1'..'-35',
 *                                   mtfcc='X0035', state='tn'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structural migration
 * creates the district rows, the government, the chambers and the offices; it
 * refuses to run if these 35 boundaries are absent.
 *
 * Wave 1a of the Nashville deep-seed program.
 * Spec: .planning/todos/2026-08-27-nashville-davidson-deep-seed.md
 * Plan: docs/superpowers/plans/2026-08-27-nashville-wave-1a.md
 * Roster: data/seed-nashville-davidson-2026/ROSTERS.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 WHY THE COUNTY POLYGON, AND NOT THE TIGER PLACE, IS THE PARENT.
 *
 * TIGER files Nashville as place 4752006, "Nashville-Davidson metropolitan
 * government (balance)". The word balance is doing real work: it EXCLUDES the
 * six satellite cities — Belle Meade, Berry Hill, Forest Hills, Goodlettsville,
 * Oak Hill and Ridgetop. Those residents elect the Metro Council anyway,
 * because Nashville is a consolidated city-county and the Council is its county
 * legislature as well as its city one.
 *
 * Measured 2026-08-27 against this layer: Belle Meade City Hall falls in council
 * district 23, Goodlettsville City Hall in 10, Berry Hill in 26, Forest Hills in
 * 34, Oak Hill in 25, Ridgetop in 10. Hanging Metro seats off the place polygon
 * would return NO representative for any of those addresses, and nothing would
 * error. So the countywide seats hang off TIGER county 47037, and the tiling gate
 * below asserts these 35 polygons cover that county exactly once.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 outSR=4326 IS LOAD-BEARING. The service's native spatial reference is
 * EPSG:3857 (web mercator) — read off the MapServer's own metadata, which
 * reports wkid 102100 / latestWkid 3857. Dropping outSR writes projected metres
 * into a geographic column. No row count and no NOT NULL would catch it; the
 * polygons would simply sit in the wrong hemisphere and every address probe
 * would come back empty.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ ON THE CONTROL POINTS. Buncombe's loader could check its polygons against an
 * INDEPENDENT layer already in the database (TIGER sldl), because a statute ties
 * the two together. Nashville has no such twin: no other digitization of the
 * council districts is loaded, and TN has no sldl/sldu or place layer in prod at
 * all. So the control points below are SELF-CONSISTENCY checks — each point must
 * fall in exactly one district, and in the district this same layer reported on
 * 2026-08-27. They would not catch a wholesale re-digitization of the layer.
 *
 * The two gates that ARE independent follow them: a point outside Davidson
 * County must fall in no district, and the 35 districts must tile TIGER county
 * 47037, which is a different agency's digitization of a different boundary.
 */

import { Pool } from 'pg';

const COUNCIL_URL =
  'https://maps.nashville.gov/arcgis/rest/services/' +
  'Elections/PoliticalDistricts/MapServer/0/query' +
  '?where=1%3D1&outFields=DISTRICT%2CDistrictName' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0035';
const STATE_CODE = 'tn';
const SOURCE = 'nashvillegov-arcgis-Elections-PoliticalDistricts-0-2026-08-27';
const GEO_ID_PREFIX = 'nashville-tn-council-district-';
const COUNTY_GEO_ID = '47037';
const EXPECTED_COUNT = 35;

/**
 * Self-consistency controls, measured against this layer on 2026-08-27. Five of
 * the six are satellite-city halls: they are precisely the cases that break if
 * anyone ever swaps this layer for the TIGER place polygon.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: number }> = [
  { name: 'Metro Courthouse', lon: -86.7761, lat: 36.1665, district: 19 },
  { name: 'Belle Meade City Hall', lon: -86.8583, lat: 36.1006, district: 23 },
  { name: 'Goodlettsville City Hall', lon: -86.7133, lat: 36.3231, district: 10 },
  { name: 'Berry Hill City Hall', lon: -86.7657, lat: 36.1183, district: 26 },
  { name: 'Forest Hills', lon: -86.8419, lat: 36.0705, district: 34 },
  { name: 'Oak Hill', lon: -86.7856, lat: 36.0663, district: 25 },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL. Brentwood is in Williamson County, immediately
 * south of Davidson. It must fall in NO council district. Without this, a query
 * that cannot fire at all still passes every positive control, because a
 * geometry test that never runs returns "not found" for the negative case and
 * the positive cases are the only ones anyone reads.
 *
 * Proved able to fail on 2026-08-27 by pointing it at the Metro Courthouse
 * instead: the loader reported `FAIL Brentwood: expected no district, got D19`
 * and refused to write.
 */
const NEGATIVE_CONTROL = { name: 'Brentwood, Williamson County', lon: -86.7828, lat: 35.9739 };

/**
 * Tiling tolerance against TIGER county 47037, which measures 1360.42 km2 in
 * prod. Measured on the 2026-08-27 dry run, the 35 fetched polygons give:
 *
 *   outside county    1.144 km2
 *   county uncovered  1.286 km2
 *   self-overlap      0.000 km2   <- exactly zero: the layer does not overlap itself
 *
 * The first two are edge digitizing between Metro GIS and TIGER's county
 * outline, not holes. 2.0 km2 leaves 0.71 km2 of headroom above the worst of
 * them for a TIGER vintage change, while sitting 3.7x below the SMALLEST council
 * district — District 18 at 7.467 km2, measured in prod after the load — so a
 * genuinely missing or duplicated district cannot hide underneath it.
 */
const COUNTY_FIT_TOLERANCE_SQ_KM = 2.0;

const DRY_RUN = process.argv.includes('--dry-run');

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

type Feature = { properties: Record<string, unknown>; geometry: any | null };

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
  console.log('[load-davidson-council-boundaries] Fetching Metro Council districts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes (every gate below still runs for real)');

  const response = (await (await fetch(COUNCIL_URL)).json()) as { features?: Feature[] };
  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the Nashville MapServer. Check the URL.');
    process.exit(1);
  }
  console.log(`  Received ${response.features.length} features`);

  const distMap = new Map<number, { geoId: string; name: string; geomStr: string; geom: any }>();
  for (const feature of response.features) {
    const raw = String(feature.properties['DISTRICT'] ?? '');
    const dist = parseInt(raw.replace(/\D+/g, ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: DISTRICT '${raw}' out of range — skipping`);
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
      name: `Nashville Metro Council District ${dist}`,
      geomStr: JSON.stringify(feature.geometry),
      geom: feature.geometry,
    });
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting.`);
    process.exit(1);
  }
  const missing = Array.from({ length: EXPECTED_COUNT }, (_, i) => i + 1).filter((n) => !distMap.has(n));
  if (missing.length) {
    console.error(`ERROR: districts ${missing.join(', ')} are absent. Aborting.`);
    process.exit(1);
  }
  const sorted = [...distMap.entries()].sort((a, b) => a[0] - b[0]);
  console.log(`  Parsed districts 1..${EXPECTED_COUNT}, none missing, none duplicated`);

  // ─── Gate 1: self-consistency controls ─────────────────────────────────────
  console.log('\n  Control points (self-consistency; five are satellite-city halls):');
  let controlFailures = 0;
  for (const cp of CONTROL_POINTS) {
    const found = sorted.filter(([, v]) => pointInGeometry(v.geom, cp.lon, cp.lat)).map(([d]) => d);
    const ok = found.length === 1 && found[0] === cp.district;
    if (!ok) controlFailures++;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  ${cp.name}: expected D${cp.district}, got ${
        found.length ? found.map((d) => 'D' + d).join('+') : 'none'
      }`,
    );
  }

  // ─── Gate 2: the control of the control ────────────────────────────────────
  const outside = sorted.filter(([, v]) =>
    pointInGeometry(v.geom, NEGATIVE_CONTROL.lon, NEGATIVE_CONTROL.lat),
  );
  const negOk = outside.length === 0;
  if (!negOk) controlFailures++;
  console.log(
    `    ${negOk ? 'PASS' : 'FAIL'}  ${NEGATIVE_CONTROL.name}: expected no district, got ${
      outside.length ? outside.map(([d]) => 'D' + d).join('+') : 'none'
    }`,
  );
  if (controlFailures > 0) {
    console.error(`\nERROR: ${controlFailures} control(s) failed. Refusing to write.`);
    await pool.end();
    process.exit(1);
  }

  // ─── Gate 3: the districts must tile Davidson County, once ─────────────────
  const tileRes = await pool.query(
    `WITH d AS (
       SELECT public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326)) g
         FROM unnest($1::text[]) AS gj
     ), u AS (SELECT public.ST_Union(g) g FROM d),
        c AS (SELECT geometry g FROM essentials.geofence_boundaries
               WHERE geo_id = $2 AND mtfcc = 'G4020')
     SELECT (public.ST_Area(public.ST_Difference(u.g, c.g)::geography) / 1e6)::numeric(10,3) AS outside_county,
            (public.ST_Area(public.ST_Difference(c.g, u.g)::geography) / 1e6)::numeric(10,3) AS county_uncovered,
            (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / 1e6), 0)::numeric(10,3)
               FROM d x JOIN d y ON public.ST_AsBinary(x.g) < public.ST_AsBinary(y.g)
              WHERE public.ST_Intersects(x.g, y.g)) AS self_overlap
       FROM u, c`,
    [sorted.map(([, v]) => v.geomStr), COUNTY_GEO_ID],
  );
  if (!tileRes.rows.length) {
    console.error(`ERROR: TIGER county polygon ${COUNTY_GEO_ID}/G4020 is not loaded. Refusing to write.`);
    await pool.end();
    process.exit(1);
  }
  const t = tileRes.rows[0] as Record<string, string>;
  console.log(
    `\n  Tiling vs TIGER county ${COUNTY_GEO_ID}: outside ${t.outside_county} km2, ` +
      `uncovered ${t.county_uncovered} km2, self-overlap ${t.self_overlap} km2 ` +
      `(tolerance ${COUNTY_FIT_TOLERANCE_SQ_KM})`,
  );
  if (
    Number(t.outside_county) > COUNTY_FIT_TOLERANCE_SQ_KM ||
    Number(t.county_uncovered) > COUNTY_FIT_TOLERANCE_SQ_KM ||
    Number(t.self_overlap) > COUNTY_FIT_TOLERANCE_SQ_KM
  ) {
    console.error(
      `ERROR: the council districts do not tile Davidson County within ` +
        `${COUNTY_FIT_TOLERANCE_SQ_KM} km2. Uncovered county means residents with no council ` +
        `member; overlap means two. Investigate before trusting this load.`,
    );
    await pool.end();
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — all gates passed, no database writes made.');
    await pool.end();
    process.exit(0);
  }

  // ─── Write ─────────────────────────────────────────────────────────────────
  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;
  for (const [dist, { geoId, name, geomStr }] of sorted) {
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
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
