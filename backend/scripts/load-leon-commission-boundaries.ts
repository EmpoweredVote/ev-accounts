/**
 * load-leon-commission-boundaries.ts
 *
 * Fetches the 5 single-member County Commission district boundaries for Leon
 * County, FL and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='leon-fl-commissioner-district-1'..'-5',
 *                                   mtfcc='X0038', state='fl'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0013 creates the district
 * rows, the government, the chambers, the offices and the people; it refuses to
 * run if these 5 boundaries are absent.
 *
 * Wave FL-4 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-08-28-knight-fl-wave-4-tallahassee-leon.md
 * Slice:  .planning/knight-foundation/fl.md
 * Roster: data/seed-tallahassee-leon-2026/ROSTERS.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE BOARD HAS SEVEN MEMBERS AND THIS LOADS FIVE POLYGONS.
 *
 * Districts 1-5 are single-member. The other two are elected COUNTYWIDE and have
 * no polygon of their own -- their offices hang off the EXISTING COUNTY district
 * for TIGER county 12073, together with all SIX constitutional officers.
 *
 * ⚠ Leon calls them "At Large, Group 1" and "At Large, Group 2". MANATEE CALLS
 * ITS TWO "District 6" and "District 7". Two counties in one state, two
 * conventions -- follow the publisher, do not normalise.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 TALLAHASSEE NEEDS NO LAYER AT ALL, WHICH IS WHY THIS WAVE HAS ONE LOADER.
 *
 * Its city commission is ENTIRELY AT-LARGE -- five seats, and the Mayor is Seat 4
 * inside that numbering rather than a separate office. The Supervisor of
 * Elections states it directly: "City Commissioners and Mayor do not have
 * districts." So the TIGER place polygon 1270600, loaded by FL-1, carries every
 * city seat, and every Tallahassee address returns all five commissioners.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE PRIMARY IS THE SUPERVISOR OF ELECTIONS' OWN LAYER, AND fl.md ALREADY
 * TRUSTS THIS SERVICE. Layers 5 and 4 of SOE_DistrictsCurrent_D_WM are the FL
 * House 2022 and FL Senate 2022 services that the FL-1 vintage check used to
 * confirm the Tallahassee anchor as HD-9 / SD-3. Layer 1 is the commission
 * districts and layer 6 is the city limits.
 *
 * The county GIS overlay (TLC_OverlayCommissionDistrictFeature_D_WM) is the
 * cross-check. Measured 2026-08-28, both reprojected to 4326: the symmetric
 * difference is 0.0000 sq mi for all five districts -- the same finding as
 * Manatee's four services. So the choice cannot change an answer, and the second
 * service is a free independent control.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ DISTRICT IS TEXT HERE ('1'..'5'), NOT AN INTEGER.
 *
 * Manatee's service returns COMMDIST as a number and its loader tests
 * Number.isInteger(). Leon returns DISTRICT as a STRING, and
 * Number.isInteger('3') is FALSE -- that test would silently skip all five
 * districts and the loader would report "expected 5, got 0". This one parses the
 * way the Bradenton ward loader does, with a regex on a trimmed string.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ TOTALPOP20 IS 0 ON EVERY ROW in both services. It is a dead field. Do not
 * gate on it.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 outSR=4326 IS LOAD-BEARING. Both services are natively EPSG:3857. Dropping
 * outSR writes projected metres into a geographic column; no row count and no
 * NOT NULL catches it, and every address probe simply comes back empty.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const BASE =
  'https://intervector.leoncountyfl.gov/intervector/rest/services/MapServices';

const PRIMARY_URL =
  `${BASE}/SOE_DistrictsCurrent_D_WM/MapServer/1/query` +
  '?where=1%3D1&outFields=DISTRICT' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/** Independent digitization by the county GIS office. Cross-check only. */
const CROSSCHECK_URL =
  `${BASE}/TLC_OverlayCommissionDistrictFeature_D_WM/MapServer/0/query` +
  '?where=1%3D1&outFields=DISTRICT' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/**
 * Layer 6 of the SOE service: an INDEPENDENT digitization of the city boundary.
 * It checks the polygon the FIVE CITY SEATS will hang off -- which no other gate
 * in this wave touches, because Tallahassee has no district layer of its own.
 * Bradenton had no such control.
 */
const CITY_LIMITS_URL =
  `${BASE}/SOE_DistrictsCurrent_D_WM/MapServer/6/query` +
  '?where=1%3D1&outFields=NAME' +
  '&returnGeometry=true&f=geojson&outSR=4326';

const MTFCC = 'X0038';
const STATE_CODE = 'fl';
const SOURCE = 'leoncountyfl-intervector-SOE_DistrictsCurrent-1-2026-08-28';
const GEO_ID_PREFIX = 'leon-fl-commissioner-district-';
const COUNTY_GEO_ID = '12073';
const PLACE_GEO_ID = '1270600';
const EXPECTED_COUNT = 5;

const DISTRICTS = ['1', '2', '3', '4', '5'] as const;

/** Measured 2026-08-28 against the SOE layer, reprojected to 4326, geodesic. */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 99.81, '2': 227.69, '3': 74.20, '4': 202.59, '5': 97.50,
};

/**
 * Control points.
 *
 * City hall is the wave anchor and the only INDEPENDENT positive control: it was
 * confirmed as commission District 5 by BOTH services, and as HD-9 / SD-3 by the
 * two legislative layers in the same service that fl.md already cites.
 *
 * The five district centroids are SELF-CONSISTENCY controls, measured 2026-08-28.
 * Every one was verified to fall inside its own district, which is not
 * guaranteed -- a centroid of a concave or multipart district can land outside
 * it, and that is exactly why they were checked before being written down here
 * rather than computed at run time.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: string }> = [
  { name: 'Tallahassee City Hall (300 S Adams St)', lon: -84.2820030, lat: 30.4395411, district: '5' },
  { name: 'District 1 centroid', lon: -84.2000764, lat: 30.3438491, district: '1' },
  { name: 'District 2 centroid', lon: -84.4722536, lat: 30.3730867, district: '2' },
  { name: 'District 3 centroid', lon: -84.3170205, lat: 30.5425024, district: '3' },
  { name: 'District 4 centroid', lon: -84.1465919, lat: 30.5875637, district: '4' },
  { name: 'District 5 centroid', lon: -84.1472307, lat: 30.4392055, district: '5' },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL. Thomasville is in Thomas County, GEORGIA, about
 * 35 miles north across the state line. It must fall in NO Leon County
 * commission district.
 *
 * Without a negative control, a query that cannot fire at all still passes every
 * positive control, because a geometry test that never runs returns "not found"
 * for the negative case and nobody reads the negative case.
 */
const NEGATIVE_CONTROL = { name: 'Thomasville, Thomas County GA', lon: -83.9788, lat: 30.8366 };

/**
 * 🔴 A TOLERANCE, NOT ST_Equals. Two digitizations of one boundary are never
 * bit-identical.
 *
 * Measured 2026-08-28: the two services agree to 0.0000 sq mi per district; the
 * five districts leave 0.0040 sq mi of TIGER county 12073 uncovered and overhang
 * it by 0.0006 sq mi, with 0.0000 sq mi of self-overlap. 0.25 sq mi is 60x the
 * worst of those and 297x smaller than the SMALLEST district (District 3, 74.20
 * sq mi), so a genuinely missing or duplicated district cannot hide underneath it.
 */
const TOLERANCE_SQ_MI = 0.25;

/** Per-district area tolerance, per cent. Measured differences were 0.00%. */
const AREA_TOLERANCE_PCT = 1;

/**
 * City-limits tolerance, as a percentage of the TIGER place polygon's area.
 *
 * Measured 2026-08-28: SOE 105.456 sq mi against TIGER 105.477 sq mi, a
 * symmetric difference of 0.441 sq mi = 0.42% of TIGER. Two agencies' city
 * boundaries differ by annexation timing, so this is a real agreement rather
 * than an identity. 3% leaves room for one annexation cycle.
 *
 * ⚠ The LOAD-BEARING assertion is not this percentage -- it is that the TIGER
 * polygon covers city hall. If that fails, all five city seats are unreachable
 * from the wave's own anchor address.
 */
const CITY_LIMITS_TOLERANCE_PCT = 3;

const SQ_M_PER_SQ_MI = 2_589_988.11;

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

async function fetchDistricts(url: string, label: string): Promise<Map<string, any>> {
  const response = (await (await fetch(url)).json()) as { features?: Feature[] };
  if (!response?.features?.length) {
    console.error(`ERROR: no features returned from ${label}. Check the URL.`);
    await pool.end();
    process.exit(1);
  }
  const out = new Map<string, any>();
  for (const feature of response.features) {
    // ⚠ DISTRICT is TEXT. Normalise the string; do NOT Number.isInteger() it.
    const dist = String(feature.properties['DISTRICT'] ?? '').trim();
    if (!/^[1-5]$/.test(dist)) {
      console.warn(`  WARNING (${label}): DISTRICT '${dist}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING (${label}): district ${dist} has no geometry — skipping`);
      continue;
    }
    if (out.has(dist)) {
      console.error(`ERROR (${label}): district ${dist} appeared twice. Aborting rather than guessing.`);
      await pool.end();
      process.exit(1);
    }
    out.set(dist, feature.geometry);
  }
  return out;
}

async function main() {
  console.log('[load-leon-commission-boundaries] Fetching Leon County commission districts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes (every gate below still runs for real)');

  const primary = await fetchDistricts(PRIMARY_URL, 'SOE_DistrictsCurrent layer 1');
  console.log(`  Received ${primary.size} features from the Supervisor of Elections layer`);

  if (primary.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${primary.size}. Aborting.`);
    await pool.end();
    process.exit(1);
  }
  const missing = DISTRICTS.filter((n) => !primary.has(n));
  if (missing.length) {
    console.error(`ERROR: districts ${missing.join(', ')} are absent. Aborting.`);
    await pool.end();
    process.exit(1);
  }
  const sorted = DISTRICTS.map((d) => [d, primary.get(d)] as [string, any]);
  console.log(`  Parsed districts 1..${EXPECTED_COUNT}, none missing, none duplicated`);

  // ─── Gate 1: control points ────────────────────────────────────────────────
  console.log('\n  Control points (city hall is independent; the centroids are self-consistency):');
  let controlFailures = 0;
  for (const cp of CONTROL_POINTS) {
    const found = sorted.filter(([, g]) => pointInGeometry(g, cp.lon, cp.lat)).map(([d]) => d);
    const ok = found.length === 1 && found[0] === cp.district;
    if (!ok) controlFailures++;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  ${cp.name}: expected D${cp.district}, got ${
        found.length ? found.map((d) => 'D' + d).join('+') : 'none'
      }`,
    );
  }

  // ─── Gate 2: the control of the control ────────────────────────────────────
  const outside = sorted.filter(([, g]) =>
    pointInGeometry(g, NEGATIVE_CONTROL.lon, NEGATIVE_CONTROL.lat),
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

  // ─── Gate 3: per-district area against the 2026-08-28 measurement ──────────
  console.log('\n  Per-district areas (vs the 2026-08-28 measurement):');
  for (const [dist, geom] of sorted) {
    const { rows: [a] } = await pool.query(
      `SELECT public.ST_Area(public.ST_MakeValid(
                public.ST_SetSRID(public.ST_GeomFromGeoJSON($1::text), 4326))::geography) / $2 AS sq_mi`,
      [JSON.stringify(geom), SQ_M_PER_SQ_MI],
    );
    const got = Number(a.sq_mi);
    const want = EXPECTED_SQ_MI[dist];
    const pct = (Math.abs(got - want) / want) * 100;
    const ok = pct <= AREA_TOLERANCE_PCT;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  District ${dist}: ${got.toFixed(2)} sq mi ` +
        `(expected ${want.toFixed(2)}, ${pct.toFixed(2)}% apart)`,
    );
    if (!ok) {
      console.error(
        `ERROR: district ${dist} is ${pct.toFixed(2)}% off its 2026-08-28 measurement.\n` +
          'Either the layer was re-digitized, the board redrew the districts, or outSR was ' +
          'dropped. Re-measure deliberately and update EXPECTED_SQ_MI in the same commit, with ' +
          'the reason.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── Gate 4: cross-check against the county GIS office's own digitization ──
  console.log('\n  Cross-check vs the county GIS overlay (independent digitization):');
  const cross = await fetchDistricts(CROSSCHECK_URL, 'TLC_OverlayCommissionDistrictFeature layer 0');
  for (const [dist, geom] of sorted) {
    const other = cross.get(dist);
    if (!other) {
      console.error(`ERROR: the cross-check service has no district ${dist}.`);
      await pool.end();
      process.exit(1);
    }
    const { rows: [d] } = await pool.query(
      `SELECT public.ST_Area(public.ST_SymDifference(
                public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1::text), 4326)),
                public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($2::text), 4326))
              )::geography) / $3 AS symdiff_sq_mi`,
      [JSON.stringify(geom), JSON.stringify(other), SQ_M_PER_SQ_MI],
    );
    const sym = Number(d.symdiff_sq_mi);
    const ok = sym <= TOLERANCE_SQ_MI;
    console.log(`    ${ok ? 'PASS' : 'FAIL'}  District ${dist}: symmetric difference ${sym.toFixed(4)} sq mi`);
    if (!ok) {
      console.error(
        `ERROR: the two services disagree on district ${dist} by ${sym.toFixed(4)} sq mi.\n` +
          'They agreed exactly on 2026-08-28. One of them has been updated. Settle which is the ' +
          'adopted plan, from the county, before loading either.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── Gate 5: the districts must tile Leon County, once ─────────────────────
  const tileRes = await pool.query(
    `WITH d AS (
       SELECT public.ST_Multi(public.ST_MakeValid(
                public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326))) g
         FROM unnest($1::text[]) AS gj
     ), u AS (SELECT public.ST_UnaryUnion(public.ST_Collect(g)) g FROM d),
        c AS (SELECT geometry g FROM essentials.geofence_boundaries
               WHERE geo_id = $2 AND mtfcc = 'G4020')
     SELECT (public.ST_Area(public.ST_Difference(c.g, u.g)::geography) / $3)::numeric(12,4) AS county_uncovered,
            (public.ST_Area(public.ST_Difference(u.g, c.g)::geography) / $3)::numeric(12,4) AS overhang,
            (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / $3), 0)::numeric(12,4)
               FROM d x JOIN d y ON public.ST_AsBinary(x.g) < public.ST_AsBinary(y.g)
              WHERE public.ST_Intersects(x.g, y.g)) AS self_overlap
       FROM u, c`,
    [sorted.map(([, g]) => JSON.stringify(g)), COUNTY_GEO_ID, SQ_M_PER_SQ_MI],
  );
  if (!tileRes.rows.length) {
    console.error(
      `ERROR: TIGER county polygon ${COUNTY_GEO_ID}/G4020 is not loaded. Refusing to write — ` +
        `CC_0013 hangs the two at-large seats and all six constitutional officers off it.`,
    );
    await pool.end();
    process.exit(1);
  }
  const t = tileRes.rows[0] as Record<string, string>;
  console.log(
    `\n  Tiling vs TIGER county ${COUNTY_GEO_ID}: ${t.county_uncovered} sq mi of county in no ` +
      `district, ${t.overhang} sq mi overhang, ${t.self_overlap} sq mi self-overlap ` +
      `(tolerance ${TOLERANCE_SQ_MI})`,
  );
  if (
    Number(t.county_uncovered) > TOLERANCE_SQ_MI ||
    Number(t.overhang) > TOLERANCE_SQ_MI ||
    Number(t.self_overlap) > TOLERANCE_SQ_MI
  ) {
    console.error(
      `ERROR: the 5 districts do not tile Leon County within ${TOLERANCE_SQ_MI} sq mi. Measured ` +
        `0.0040 uncovered / 0.0006 overhang / 0.0000 overlap on 2026-08-28. Uncovered county means ` +
        `residents with NO county commissioner and nothing errors; overlap means two.`,
    );
    await pool.end();
    process.exit(1);
  }

  // ─── Gate 6: the city polygon the FIVE CITY SEATS will hang off ────────────
  console.log(`\n  City-limits control (SOE layer 6 vs TIGER place ${PLACE_GEO_ID}):`);
  const cl = (await (await fetch(CITY_LIMITS_URL)).json()) as { features?: Feature[] };
  if (cl?.features?.length !== 1) {
    console.error(`ERROR: expected exactly 1 city-limits feature, got ${cl?.features?.length}.`);
    await pool.end();
    process.exit(1);
  }
  const clRes = await pool.query(
    `WITH soe AS (SELECT public.ST_MakeValid(
                    public.ST_SetSRID(public.ST_GeomFromGeoJSON($1::text), 4326)) g),
          tig AS (SELECT geometry g FROM essentials.geofence_boundaries
                   WHERE geo_id = $2 AND mtfcc = 'G4110')
     SELECT (public.ST_Area(soe.g::geography) / $3)::numeric(12,3) AS soe_sq_mi,
            (public.ST_Area(tig.g::geography) / $3)::numeric(12,3) AS tiger_sq_mi,
            (public.ST_Area(public.ST_SymDifference(soe.g, tig.g)::geography) / $3)::numeric(12,3) AS symdiff_sq_mi,
            (100 * public.ST_Area(public.ST_SymDifference(soe.g, tig.g)::geography)
                 / public.ST_Area(tig.g::geography))::numeric(12,2) AS symdiff_pct,
            public.ST_Covers(tig.g, public.ST_SetSRID(public.ST_MakePoint($4, $5), 4326)) AS tiger_covers_city_hall
       FROM soe, tig`,
    [JSON.stringify(cl.features[0].geometry), PLACE_GEO_ID, SQ_M_PER_SQ_MI,
     CONTROL_POINTS[0].lon, CONTROL_POINTS[0].lat],
  );
  if (!clRes.rows.length) {
    console.error(
      `ERROR: TIGER place ${PLACE_GEO_ID}/G4110 is not loaded. FL-1 must be applied first — all ` +
        `five Tallahassee city seats hang off it.`,
    );
    await pool.end();
    process.exit(1);
  }
  const c = clRes.rows[0] as Record<string, string | boolean>;
  console.log(
    `    SOE ${c.soe_sq_mi} sq mi vs TIGER ${c.tiger_sq_mi} sq mi; symmetric difference ` +
      `${c.symdiff_sq_mi} sq mi (${c.symdiff_pct}% of TIGER, tolerance ${CITY_LIMITS_TOLERANCE_PCT}%); ` +
      `TIGER covers city hall: ${c.tiger_covers_city_hall}`,
  );
  // 🔴 THE LOAD-BEARING ONE. If TIGER does not cover city hall, the wave's own
  // anchor returns none of the five city seats.
  if (c.tiger_covers_city_hall !== true) {
    console.error(
      `ERROR: TIGER place ${PLACE_GEO_ID} does not cover Tallahassee City Hall. All five city ` +
        `seats would be unreachable from the anchor address.`,
    );
    await pool.end();
    process.exit(1);
  }
  if (Number(c.symdiff_pct) > CITY_LIMITS_TOLERANCE_PCT) {
    console.error(
      `ERROR: the two city-boundary digitizations differ by ${c.symdiff_pct}% of the TIGER polygon, ` +
        `over the ${CITY_LIMITS_TOLERANCE_PCT}% tolerance. Measured 0.42% on 2026-08-28. Either ` +
        `Tallahassee annexed or the TIGER vintage moved — decide which polygon the city seats ` +
        `should hang off before loading.`,
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
  for (const [dist, geom] of sorted) {
    const geoId = `${GEO_ID_PREFIX}${dist}`;
    const name = `Leon County Commissioner District ${dist}`;
    const geomStr = JSON.stringify(geom);
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
