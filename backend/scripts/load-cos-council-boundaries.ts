/**
 * load-cos-council-boundaries.ts
 *
 * Fetches the 6 Colorado Springs City Council district boundaries from the City
 * of Colorado Springs ArcGIS server and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='colorado-springs-co-council-district-1'..'-6',
 *                                   mtfcc='X0032', state='co'
 *
 * ...and the city-wide boundary the AT-LARGE seats need:
 *
 *   essentials.geofence_boundaries  geo_id='colorado-springs-co-city-limits',
 *                                   mtfcc='X0032', state='co'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structural migration
 * creates the LOCAL district rows, the council offices, and the terms.
 *
 * WHY THE CITY-WIDE POLYGON IS NOT THE TIGER PLACE POLYGON. The Mayor and the
 * three AT-LARGE councilmembers are elected city-wide, so they need a city-wide
 * shape. The obvious candidate is the TIGER place polygon (G4110, GEOID
 * 0816000), which the CO TIGER load already put in the table and which is what
 * Austin's city-wide row keys on. Measured 2026-08-21, that shape is STALE for
 * this purpose:
 *
 *     council districts union   538.29 km2
 *     TIGER place 0816000       524.34 km2
 *     in districts, not TIGER    14.42 km2   <- annexed after the TIGER snapshot
 *     in TIGER, not districts     0.47 km2
 *
 * Colorado Springs has annexed aggressively (Karman Line, Amara), and TIGER 2024
 * has not caught up. Hanging the city-wide seats off TIGER would mean ~14.4 km2
 * of the city returns its DISTRICT councilmember but no Mayor and no at-large
 * members — a partial answer, which is worse than an obvious blank because
 * nothing errors. So the city's own CityLimits layer is loaded under its own
 * geo_id and the city-wide offices point at that instead. The TIGER place row
 * stays where it is; it is still correct for census-shaped questions.
 *
 * LAYER CHOICE — the Austin trap, and here there are SEVEN candidates. Probed
 * 2026-08-21; every one of them returns exactly 6 polygons, so a headcount
 * cannot tell them apart:
 *
 *     CouncilDistrictSearch/council_districts/0      "Council Districts (Far Scale)"
 *     CouncilDistrictSearch/council_districts/1      "Council Districts (Near Scale)"   <- CHOSEN
 *     CouncilDistrictSearch/CouncilDistrictViewer/0  "Council Districts (Far Scale)"
 *     CouncilDistrictSearch/CouncilDistrictViewer/1  "Council Districts (Near Scale)"
 *     CouncilDistrictSearch/CouncilDistrictViewer/3  "Council Districts (Identify)"
 *     GeneralUse/AdministrationLocal/3               "Council Districts"
 *     GeneralUse/CouncilDist/0                       "City Council Districts"           <- STALE
 *
 * SIX OF THE SEVEN ARE IDENTICAL — 12,208 vertices, identical area, and zero
 * disagreement across a 5,254-point grid. Note in particular that "Far Scale"
 * and "Near Scale" are NOT a generalized/detailed pair as the names imply; they
 * are the same geometry published at two draw scales. Do not assume otherwise.
 *
 * GeneralUse/CouncilDist/0 is the odd one out and it is STALE. Two independent
 * tells, measured not guessed:
 *
 *   1. Its RepName values are the PREVIOUS council — Randy Helms (D2), Michelle
 *      Talarico (D3), Yolanda Avila (D4), Mike O'Malley (D6). The other six
 *      layers carry Casey / Williams / Gold / Rainey, which match the nine
 *      members listed on coloradosprings.gov/city-council exactly.
 *   2. It is missing ANNEXED TERRITORY. On a ~90 m grid the current layer covers
 *      289 points that the stale layer assigns to NO district at all — 243 of
 *      them in one block in the far south (D3), plus smaller blocks in the north
 *      (D2, D6). Loading the stale layer would leave those residents with no
 *      council member and no error.
 *
 * That second tell is why the control points below are not just landmarks. The
 * two maps agree almost everywhere, so a downtown probe passes on BOTH and
 * proves nothing. CONTROL_POINTS therefore leads with two points inside annexed
 * ground, which resolve on the current map and resolve to NOTHING on the stale
 * one. A uniform answer is a broken detector until a point that DISCRIMINATES
 * passes.
 *
 * COUNTY ENCLAVES. Colorado Springs is not simply-connected: 56 unincorporated
 * El Paso County pockets sit inside the city outline, and an address in one has
 * NO council member. The district polygons already model this correctly — of 52
 * testable enclave centroids, 51 fall outside every district. ONE does not, a
 * ~0.6 ha sliver near (-104.785, 38.981) where the district edge and the
 * city-limits edge were digitized differently; at ~35 m resolution it is 5 grid
 * points. That is a digitizing mismatch, not a swallowed neighborhood, and it is
 * NOT clipped here: re-cutting the city's authoritative district polygons
 * against a different layer's edges would make us the authority instead of the
 * city and would introduce fresh artifacts along the whole ~100 km boundary for
 * a sliver that plausibly contains no address. Instead the enclave overlap is a
 * NEGATIVE CONTROL with an allowance of 1 — if the city ever republishes a
 * layer that genuinely swallows an enclave, the load refuses.
 *
 * CRITICAL: outSR=4326 is mandatory. CRITICAL: f=geojson (NOT f=json).
 * CRITICAL: state='co' LOWERCASE — LOCAL-tier routing join key.
 *
 * DISTRICT is an INTEGER field holding 1..6. Identity is keyed off that number,
 * never off RepName — RepName changes with every election and is used here only
 * as a vintage tell in the log output.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-cos-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-cos-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';

const BASE = 'https://gis.coloradosprings.gov/arcgis/rest/services/';

const COS_DISTRICT_URL =
  `${BASE}CouncilDistrictSearch/council_districts/MapServer/1/query` +
  '?where=1%3D1&outFields=DISTRICT,RepName' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/** Layer 2 of the same service: the 56 unincorporated county pockets. */
const COS_ENCLAVE_URL =
  `${BASE}CouncilDistrictSearch/council_districts/MapServer/2/query` +
  '?where=1%3D1&outFields=LABEL' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=200';

/** The city's authoritative incorporated boundary — city-wide seats resolve on this. */
const COS_CITY_LIMITS_URL =
  `${BASE}GeneralUse/CityLimits/MapServer/0/query` +
  '?where=1%3D1&outFields=IN_CITY' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=10';

const MTFCC          = 'X0032';
const STATE_CODE     = 'co';
const SOURCE         = 'coloradosprings.gov-arcgis-CouncilDistrictSearch-council_districts-2026';
const CITY_SOURCE    = 'coloradosprings.gov-arcgis-GeneralUse-CityLimits-2026';
const GEO_ID_PREFIX  = 'colorado-springs-co-council-district-';
const CITY_GEO_ID    = 'colorado-springs-co-city-limits';
const EXPECTED_COUNT = 6;

/**
 * The city-wide polygon must not disagree with the districts that tile it. If
 * city limits ever cover ground no council district does, a resident there gets
 * a Mayor and no district member; the reverse strands the Mayor. Measured
 * 2026-08-21 the two agree to within a 0.47 km2 sliver, so this tolerance is
 * generous enough for digitizing noise and tight enough to catch a real drift.
 */
const CITY_VS_DISTRICTS_TOLERANCE_SQ_KM = 2.0;

/**
 * Positive control. The first two points are the ones that MATTER: both sit on
 * ground annexed since the stale GeneralUse/CouncilDist/0 layer was published,
 * so they resolve here and resolve to NOTHING there. The rest are landmark
 * spread across all six districts — they confirm the parse, but on their own
 * they would pass against the stale layer too.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: number }> = [
  { name: 'Far-south annexation (absent from the stale layer)', lon: -104.7340, lat: 38.6650, district: 3 },
  { name: 'North annexation (absent from the stale layer)',     lon: -104.7170, lat: 38.9570, district: 2 },
  { name: 'City Hall, 107 N Nevada Ave',                        lon: -104.8235, lat: 38.8339, district: 3 },
  { name: 'Garden of the Gods visitor center',                  lon: -104.8694, lat: 38.8783, district: 1 },
  { name: 'Knob Hill (Platte & Circle)',                        lon: -104.7860, lat: 38.8420, district: 4 },
  { name: 'Palmer Park',                                        lon: -104.7770, lat: 38.8760, district: 5 },
  { name: 'Colorado Springs Airport',                           lon: -104.7008, lat: 38.8058, district: 4 },
  { name: 'Powers & Barnes (east)',                             lon: -104.7190, lat: 38.8880, district: 6 },
];

/**
 * Negative control allowance. Measured 2026-08-21: exactly ONE of 52 testable
 * enclave centroids falls inside a district polygon (the ~0.6 ha sliver near
 * -104.785, 38.981). Raising this number is not a fix — it is a decision that
 * more unincorporated ground may resolve to a council member, and it needs the
 * same scrutiny as any other claim about who represents whom.
 */
const ENCLAVE_OVERLAP_ALLOWANCE = 1;

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

/** Vertex mean of the largest outer ring. Crude, so callers must verify the
 *  result actually falls inside the shape before using it as a probe. */
function representativePoint(geom: any): [number, number] {
  const polys: number[][][][] = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  let best = polys[0][0];
  for (const p of polys) if (p[0].length > best.length) best = p[0];
  let x = 0;
  let y = 0;
  for (const [a, b] of best) { x += a; y += b; }
  return [x / best.length, y / best.length];
}

async function main() {
  console.log('[load-cos-council-boundaries] Fetching Colorado Springs council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = (await (await fetch(COS_DISTRICT_URL)).json()) as { features?: Feature[] };
  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the Colorado Springs MapServer. Check the URL.');
    process.exit(1);
  }
  console.log(`  Received ${response.features.length} features`);

  const distMap = new Map<number, { geoId: string; name: string; geomStr: string; geom: any; rep: string }>();
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
      name: `Colorado Springs City Council District ${dist}`,
      geomStr: JSON.stringify(feature.geometry),
      geom: feature.geometry,
      rep: String(feature.properties['RepName'] ?? '(none)'),
    });
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting.`);
    process.exit(1);
  }
  console.log(`  Parsed districts: ${[...distMap.keys()].sort((a, b) => a - b).join(', ')}`);

  // Vintage tell only — NOT an assertion. Names change with every election; the
  // load must not start failing the morning after one.
  console.log('  RepName on this layer (informational — identity is keyed off DISTRICT):');
  for (const [d, v] of [...distMap.entries()].sort((a, b) => a[0] - b[0])) {
    console.log(`    D${d}  ${v.rep}`);
  }

  // ─── Positive control: prove this is the CURRENT map before writing ────────
  console.log('\n  Positive control (the first two refuse the stale GeneralUse layer):');
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
      `\nERROR: ${controlFailures} control point(s) failed. This is NOT the current Colorado Springs ` +
        `map (or the layer changed). Refusing to write. Re-verify the layer before loading.`,
    );
    await pool.end();
    process.exit(1);
  }

  // ─── Negative control: county enclaves must NOT resolve to a council member ─
  const enclaveRes = (await (await fetch(COS_ENCLAVE_URL)).json()) as { features?: Feature[] };
  if (!enclaveRes?.features?.length) {
    console.error('ERROR: enclave layer returned no features — the negative control cannot run. Aborting.');
    await pool.end();
    process.exit(1);
  }
  let tested = 0;
  let swallowed = 0;
  const swallowedDetail: string[] = [];
  for (const e of enclaveRes.features) {
    if (!e.geometry) continue;
    const [lon, lat] = representativePoint(e.geometry);
    if (!pointInGeometry(e.geometry, lon, lat)) continue; // concave shape — probe missed its own polygon
    tested++;
    const hit = [...distMap.entries()].find(([, v]) => pointInGeometry(v.geom, lon, lat));
    if (hit) {
      swallowed++;
      swallowedDetail.push(`${String(e.properties['LABEL'] ?? '?')} -> D${hit[0]} at ${lon.toFixed(4)},${lat.toFixed(4)}`);
    }
  }
  console.log(`\n  Negative control — county enclaves (${enclaveRes.features.length} pockets, ${tested} testable centroids):`);
  console.log(`    enclave centroids landing inside a council district: ${swallowed} (allowance ${ENCLAVE_OVERLAP_ALLOWANCE})`);
  for (const d of swallowedDetail) console.log(`      ${d}`);
  if (swallowed > ENCLAVE_OVERLAP_ALLOWANCE) {
    console.error(
      `\nERROR: ${swallowed} enclave centroids resolve to a council member, above the allowance of ` +
        `${ENCLAVE_OVERLAP_ALLOWANCE}. Unincorporated El Paso County ground would be told it has a ` +
        `Colorado Springs council member. Refusing to write.`,
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

  // ─── City-wide boundary for the Mayor + 3 at-large seats ──────────────────
  const cityRes = (await (await fetch(COS_CITY_LIMITS_URL)).json()) as { features?: Feature[] };
  const cityFeatures = (cityRes.features ?? []).filter((f) => f.geometry);
  if (cityFeatures.length !== 1) {
    console.error(`ERROR: expected exactly 1 city-limits polygon, got ${cityFeatures.length}. Aborting.`);
    await pool.end();
    process.exit(1);
  }
  const cityRow = await pool.query(
    `INSERT INTO essentials.geofence_boundaries
       (id, geo_id, mtfcc, state, name, geometry, source)
     VALUES (gen_random_uuid(), $1, '${MTFCC}', '${STATE_CODE}', $2,
       public.ST_Multi(public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326))), $4)
     ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
    [CITY_GEO_ID, 'City of Colorado Springs (city limits)', JSON.stringify(cityFeatures[0].geometry), CITY_SOURCE],
  );
  console.log(
    `\n  City limits (${CITY_GEO_ID}): ${(cityRow.rowCount ?? 0) > 0 ? 'inserted' : 'skipped (already exists)'}`,
  );

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
  console.log(`  In DB now:       ${n} rows (${invalid} invalid)  [6 districts + 1 city-wide]`);

  // City-wide vs districts agreement — the seats must tile the same city.
  const agree = await pool.query(
    `WITH d AS (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries
                 WHERE mtfcc = '${MTFCC}' AND geo_id <> $1),
          c AS (SELECT geometry g FROM essentials.geofence_boundaries
                 WHERE mtfcc = '${MTFCC}' AND geo_id = $1)
     SELECT (public.ST_Area(public.ST_Difference(c.g, d.g)::geography) / 1e6)::numeric(10,3) AS city_not_districts,
            (public.ST_Area(public.ST_Difference(d.g, c.g)::geography) / 1e6)::numeric(10,3) AS districts_not_city
       FROM d, c`,
    [CITY_GEO_ID],
  );
  const { city_not_districts, districts_not_city } = agree.rows[0] as Record<string, string>;
  console.log(`  City-wide vs districts:  city-only ${city_not_districts} km2, districts-only ${districts_not_city} km2 (tolerance ${CITY_VS_DISTRICTS_TOLERANCE_SQ_KM})`);

  await pool.end();
  if (n !== EXPECTED_COUNT + 1 || invalid !== 0) {
    console.error(`ERROR: expected ${EXPECTED_COUNT + 1} valid rows, got ${n} with ${invalid} invalid.`);
    process.exit(1);
  }
  if (Number(city_not_districts) > CITY_VS_DISTRICTS_TOLERANCE_SQ_KM ||
      Number(districts_not_city) > CITY_VS_DISTRICTS_TOLERANCE_SQ_KM) {
    console.error(
      `ERROR: city-wide boundary and council districts disagree by more than ` +
      `${CITY_VS_DISTRICTS_TOLERANCE_SQ_KM} km2. Some residents would get a Mayor with no district ` +
      `member, or the reverse. Investigate before trusting either shape.`,
    );
    process.exit(1);
  }
  console.log('OK');
}

main().catch((err) => {
  console.error('[load-cos-council-boundaries] Fatal error:', err);
  process.exit(1);
});
