/**
 * load-elpaso-commissioner-boundaries.ts
 *
 * Fetches the 5 El Paso County (CO) Board of County Commissioners district
 * boundaries and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='el-paso-co-commissioner-district-1'..'-5',
 *                                   mtfcc='X0033', state='co'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structural migration creates
 * the LOCAL district rows, the commissioner offices and the terms. County-wide
 * row offices (Sheriff, Clerk & Recorder, Assessor, Treasurer, Coroner, Surveyor)
 * are NOT here — they hang off the county polygon, TIGER G4020 geo_id '08041',
 * which is already loaded.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * LAYER CHOICE — THE PLAINLY-NAMED LAYER IS THE STALE ONE. Read this before
 * "simplifying" the URL below to the obvious candidate.
 *
 * El Paso County publishes FOUR 5-feature commissioner-district layers:
 *
 *     Commissioner_Districts/0                        lastEdit 2022-01-13  SUPERSEDED
 *     ComDistricts/0                                  lastEdit 2019-02-12  SUPERSEDED
 *     Commissioner_Districts_PIO/11                   lastEdit 2026-08-17  <- CHOSEN
 *     Commissioner_Districts_Enriched_..._Dashboard/1 lastEdit 2026-08-20  derived
 *
 * All four return exactly 5 polygons, all four tile the county, and all four
 * satisfy the community lists on the county's District 2 and District 4 pages.
 * None of those checks discriminates. The two vintages disagree over ~11.7% of
 * the county's area.
 *
 * THE COUNTY REDISTRICTED IN 2023. The El Paso County Redistricting Commission
 * selected "Map 6 V2" on 2023-08-15 by a 5-0 vote. Any layer last edited in 2022
 * or 2019 therefore cannot be the operative map, whatever it is called.
 *
 * Four independent lines of evidence, all measured 2026-08-21, agree that
 * Commissioner_Districts_PIO/11 is Map 6 V2:
 *
 *   1. PRECINCT MOVES. The county's own Precinct_Moves_FM6_V2 layer (edited
 *      2023-08-09, six days before adoption) lists the 63 precincts that change
 *      district under Map 6. Its COM_DIST is the ORIGIN district, not the
 *      destination — proved by matching it against the pre-adoption
 *      PrecinctswithPop20Data layer, where it agrees 63/63. A layer that IS the
 *      adopted map must therefore disagree with those 63 origins. Measured:
 *        Commissioner_Districts/0   agrees 61/61  -> it is the SUPERSEDED map
 *        Commissioner_Districts_PIO/11 agrees 0/61 -> it is the NEW map
 *      and PIO's reassignments fall in coherent contiguous blocks (621-624 all
 *      D4->D5; 138/140/144/147 all D5->D1), which is what redistricting looks
 *      like and what noise does not.
 *
 *   2. POPULATION. Summing the county's own precinct populations:
 *        superseded map  146101 146000 128091 137874 135787  max dev 7.7%
 *        PIO (Map 6)     139430 140328 137442 131043 145610  max dev 5.6%
 *      The superseded map reproduces the pre-adoption precinct table EXACTLY,
 *      district for district. Map 6 is better balanced, which is the primary
 *      legal criterion of a redistricting.
 *
 *   3. HIGHWAY 94. The county's live District 4 page describes D4 as including
 *      "unincorporated areas south of Highway 94 such as Security/Widefield,
 *      Hanover, Rush, Ellicott, and Yoder". PIO's D4/D2 boundary is a clean
 *      east-west line at ~lat 38.83 across the whole eastern county. The
 *      superseded layer's D4 juts north of Highway 94 out east, contradicting
 *      the description the county publishes today.
 *
 *   4. TOPOLOGY. PIO tiles the county with 0.46/0.45 km2 of edge sliver and
 *      ZERO self-overlap; the superseded layer leaves 2.2/2.5 km2.
 *
 * ⚠ AN EARLIER READING OF THIS GOT IT BACKWARDS, twice. Picking the
 * primary-sounding name gives the 2022 map. Testing the moved precincts without
 * first establishing whether COM_DIST means origin or destination inverts the
 * answer and reads as a confident 61/61. Establish the sense of the field before
 * trusting the tally.
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * CRITICAL: outSR=4326 is mandatory. CRITICAL: f=geojson (NOT f=json).
 * CRITICAL: state='co' LOWERCASE — LOCAL-tier routing join key.
 *
 * COM_DIST is an INTEGER field holding 1..5.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-elpaso-commissioner-boundaries.ts --dry-run
 *   npx tsx scripts/load-elpaso-commissioner-boundaries.ts
 */

import 'dotenv/config';
import dns from 'node:dns';
import { Pool } from 'pg';

// The county's ArcGIS host resolves to an unreachable IPv6 address from some
// networks; Node prefers it and the fetch dies with ENETUNREACH. Observed
// 2026-08-21.
dns.setDefaultResultOrder('ipv4first');

const EPC_DISTRICT_URL =
  'https://services3.arcgis.com/r1Gf4AJYRBIM0N25/arcgis/rest/services/' +
  'Commissioner_Districts_PIO/FeatureServer/11/query' +
  '?where=1%3D1&outFields=COM_DIST' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC          = 'X0033';
const STATE_CODE     = 'co';
const SOURCE         = 'elpasoco.com-arcgis-Commissioner_Districts_PIO-map6v2-2026';
const GEO_ID_PREFIX  = 'el-paso-co-commissioner-district-';
const COUNTY_GEO_ID  = '08041';
const EXPECTED_COUNT = 5;

/**
 * Positive control.
 *
 * The first five points are the ones that MATTER: each sits in a precinct that
 * MOVED under Map 6, so the adopted map and the superseded map give different
 * answers there. Each holds thousands of residents — these are not slivers.
 * The remaining points are stable landmarks covering all five districts; they
 * confirm the parse but pass against BOTH maps, so on their own they would prove
 * nothing.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: number }> = [
  // Discriminating — superseded map says D4/D5/D2/D3/D3 respectively.
  { name: 'Precinct 624 area, pop 5,687 (was D4)',  lon: -104.7381, lat: 38.7908, district: 5 },
  { name: 'Precinct 154 area, pop 4,096 (was D5)',  lon: -104.7458, lat: 38.8960, district: 2 },
  { name: 'Precinct 139 area, pop 3,124 (was D2)',  lon: -104.6987, lat: 38.8448, district: 4 },
  { name: 'Precinct 602 area, pop 3,020 (was D3)',  lon: -104.8127, lat: 38.7913, district: 4 },
  { name: 'The Broadmoor (was D3)',                 lon: -104.8480, lat: 38.7917, district: 4 },
  // Stable landmarks — TIGER 2024 place/CDP centroids where noted.
  { name: 'Black Forest',                           lon: -104.7000, lat: 39.0200, district: 1 },
  { name: 'Calhan (TIGER 0811260)',                 lon: -104.2997, lat: 39.0351, district: 2 },
  { name: 'Ramah (TIGER 0862660)',                  lon: -104.1679, lat: 39.1209, district: 2 },
  { name: 'Monument (TIGER 0851800)',               lon: -104.8730, lat: 39.0917, district: 3 },
  { name: 'Colorado Springs City Hall',             lon: -104.8235, lat: 38.8339, district: 3 },
  { name: 'Fountain (TIGER 0827865)',               lon: -104.6963, lat: 38.7134, district: 4 },
  { name: 'Ellicott CDP (TIGER 0824235)',           lon: -104.3776, lat: 38.8263, district: 4 },
  { name: 'Palmer Park',                            lon: -104.7770, lat: 38.8760, district: 5 },
];

/**
 * The five districts must tile the county. Measured 2026-08-21: 0.46 km2 spills
 * outside the TIGER county polygon and 0.45 km2 of county is uncovered, both
 * edge digitizing against a different source. 5 km2 leaves room for a TIGER
 * vintage change without admitting a real hole.
 */
const COUNTY_FIT_TOLERANCE_SQ_KM = 5.0;

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
  console.log('[load-elpaso-commissioner-boundaries] Fetching El Paso County commissioner districts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = (await (await fetch(EPC_DISTRICT_URL)).json()) as { features?: Feature[] };
  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the El Paso County FeatureServer. Check the URL.');
    process.exit(1);
  }
  console.log(`  Received ${response.features.length} features`);

  const distMap = new Map<number, { geoId: string; name: string; geomStr: string; geom: any }>();
  for (const feature of response.features) {
    const raw = String(feature.properties['COM_DIST'] ?? '');
    const dist = parseInt(raw.replace(/\D+/g, ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: COM_DIST '${raw}' out of range — skipping`);
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
      name: `El Paso County Commissioner District ${dist}`,
      geomStr: JSON.stringify(feature.geometry),
      geom: feature.geometry,
    });
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting.`);
    process.exit(1);
  }
  console.log(`  Parsed districts: ${[...distMap.keys()].sort((a, b) => a - b).join(', ')}`);

  // ─── Positive control: prove this is Map 6 V2, not the superseded 2022 map ──
  console.log('\n  Positive control (the first five refuse the superseded 2022 map):');
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
      `\nERROR: ${controlFailures} control point(s) failed. This is NOT the adopted Map 6 V2 ` +
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

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;
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

  // ─── Topology gate: the five districts must tile the county, once ──────────
  const topo = await pool.query(
    `WITH d AS (SELECT geo_id, geometry g FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'),
          u AS (SELECT public.ST_Union(g) g FROM d),
          c AS (SELECT geometry g FROM essentials.geofence_boundaries
                 WHERE geo_id = $1 AND mtfcc = 'G4020')
     SELECT (public.ST_Area(public.ST_Difference(u.g, c.g)::geography) / 1e6)::numeric(10,2) AS outside_county,
            (public.ST_Area(public.ST_Difference(c.g, u.g)::geography) / 1e6)::numeric(10,2) AS county_uncovered,
            (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / 1e6), 0)::numeric(10,3)
               FROM d x JOIN d y ON x.geo_id < y.geo_id
              WHERE public.ST_Intersects(x.g, y.g)) AS self_overlap
       FROM u, c`,
    [COUNTY_GEO_ID],
  );
  const t = topo.rows[0] as Record<string, string>;
  console.log(
    `  Tiling vs county ${COUNTY_GEO_ID}: outside ${t.outside_county} km2, uncovered ${t.county_uncovered} km2, ` +
    `overlap ${t.self_overlap} km2 (tolerance ${COUNTY_FIT_TOLERANCE_SQ_KM})`,
  );

  await pool.end();
  if (n !== EXPECTED_COUNT || invalid !== 0) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} valid rows, got ${n} with ${invalid} invalid.`);
    process.exit(1);
  }
  if (Number(t.outside_county) > COUNTY_FIT_TOLERANCE_SQ_KM ||
      Number(t.county_uncovered) > COUNTY_FIT_TOLERANCE_SQ_KM ||
      Number(t.self_overlap) > COUNTY_FIT_TOLERANCE_SQ_KM) {
    console.error(
      `ERROR: the commissioner districts do not tile El Paso County within ` +
      `${COUNTY_FIT_TOLERANCE_SQ_KM} km2. Uncovered county means residents with no commissioner; ` +
      `overlap means two. Investigate before trusting this load.`,
    );
    process.exit(1);
  }
  console.log('OK');
}

main().catch((err) => {
  console.error('[load-elpaso-commissioner-boundaries] Fatal error:', err);
  process.exit(1);
});
