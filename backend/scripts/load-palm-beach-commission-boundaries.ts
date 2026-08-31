/**
 * load-palm-beach-commission-boundaries.ts
 *
 * Fetches the 7 single-member County Commission district boundaries for Palm
 * Beach County, FL and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='palm-beach-fl-commissioner-district-1'..'-7',
 *                                   mtfcc='X0039', state='fl'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0014 creates the district
 * rows, the government, the two chambers, the offices and the people; it refuses
 * to run if these 7 boundaries are absent.
 *
 * Wave FL-5 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-08-28-knight-fl-wave-5-palm-beach-county.md
 * Slice:  .planning/knight-foundation/fl.md
 * Roster: data/seed-palm-beach-2026/ROSTERS.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 SEVEN SEATS AND SEVEN POLYGONS. THERE IS NO AT-LARGE COMMISSIONER.
 *
 * Manatee has 5 single-member + 2 at-large ("District 6" and "District 7").
 * Leon has 5 + 2 ("At Large, Group 1" and "At Large, Group 2"). Palm Beach has
 * 7 + 0 -- every commissioner is elected by the electors of one district.
 *
 * So the EXISTING county district for TIGER county 12099 carries ONLY the five
 * constitutional officers. Leon's carries 8 (2 at-large + 6 officers) and
 * Manatee's carries 7 (2 + 5). Three counties, three shapes.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THERE IS NO CITY HALF, so this wave has one loader and one migration.
 *
 * Palm Beach County is the only Knight jurisdiction in Florida with no municipal
 * wave. The Leon loader's sixth gate -- an independent city-limits control on the
 * polygon the city seats hang off -- has nothing to check here and is deleted
 * rather than stubbed.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE SEVEN DISTRICTS DO NOT TILE THE TIGER COUNTY, AND THAT IS CORRECT.
 *
 * Measured 2026-08-28: the union is 2227.669 sq mi against TIGER 12099's
 * 2383.201, leaving 155.5381 sq mi uncovered. The Leon gate ("uncovered <= 0.25
 * sq mi") FAILS here on a correct layer -- the same class of finding as
 * Bradenton's land-only ward layer, 600x larger.
 *
 * The uncovered area is ONE coherent part, 155.5209 sq mi with an interior point
 * at -80.0090, 26.6436: the Atlantic Ocean. TIGER's county polygon runs out to
 * the state's offshore limit; the commission districts stop at the shoreline.
 * The next-largest uncovered part is 0.0019 sq mi -- digitization noise. Lake
 * Okeechobee's Palm Beach share IS inside District 6 and is not part of the gap.
 *
 * 🔴 SO THE GATE ASSERTS STRUCTURE, NOT SLACK. Widening the tolerance to 156 sq
 * mi would accept a whole missing district (the smallest, District 3, is 36.6).
 * Instead: overhang ~ 0, self-overlap ~ 0, EXACTLY ONE large uncovered part, and
 * that part is offshore AND matches the cross-check service's own unassigned
 * blank polygon. See GATE 5 and GATE 6.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THREE SERVICES CLAIM TO BE THE COMMISSION DISTRICTS. ONLY ONE IS BOTH
 *    CURRENT AND INDEPENDENTLY CORROBORATED.
 *
 *   Commissioner_Districts/0     -- PRIMARY. The layer behind the county's own
 *                                   open-data "County Commission Districts".
 *   CountyCommission_2022/0      -- CROSS-CHECK. Genuinely independent: symmetric
 *                                   differences of 0.018..0.731 sq mi per
 *                                   district, 1.59 total against 2227.67 (0.07%).
 *   County_Commission_Districts/0 -- DECOY. Do NOT use. Its geometry is a near
 *                                   copy of the primary (0.0000 sq mi on five of
 *                                   seven, 0.0249 on the shared D2/D7 line), so
 *                                   it corroborates nothing, and its NAME field
 *                                   is FOUR YEARS STALE -- it still reads
 *                                   'DAVE KERNER' for D3 (left 2022) and
 *                                   'MACK BERNARD' for D7.
 *
 * ⚠ THE CROSS-CHECK SERVICE IS NAMED 2022 AND ITS LAYER IS NAMED
 *   CountyCommission_2026. Neither name is authority for which map is operative;
 *   the geometry comparison is. Do not pick a service by its name.
 *
 * ⚠ THE CROSS-CHECK RETURNS EIGHT ROWS. The eighth has CC = ' ' and is the
 *   Atlantic -- 155.6952 sq mi at -80.0091, 26.6456. A row-count gate of 7
 *   against that service fails on correct data. GATE 6 turns that blank row from
 *   a nuisance into the control that EXPLAINS the uncovered area.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER.
 *
 * The primary also carries NAME and PHONE, and today NAME happens to be current.
 * That is luck. The decoy service proves the failure mode from the same
 * publisher. This loader does not request NAME at all -- ROSTERS.md gets the
 * roster from each officeholder's own publisher.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ DISTRICT IS A SmallInteger HERE. Manatee's COMMDIST is an integer and its
 * loader tests Number.isInteger(); Leon's DISTRICT is TEXT and its loader uses a
 * regex on a trimmed string. The trimmed-string regex works on both, so it is
 * what this uses. Do NOT reintroduce Number.isInteger().
 *
 * ⚠ Shape__Area IS NOT THE VALUE TO GATE ON. It is in the service's own US
 * survey feet, and District 6 stretches far west of StatePlane Florida East's
 * zone of best fit. Every area below is computed from the reprojected 4326
 * geometry via ::geography.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 outSR=4326 IS LOAD-BEARING, AND THIS IS A THIRD PROJECTION FAMILY.
 *
 * Palm Beach publishes natively in NAD83(HARN) StatePlane Florida East FIPS
 * 0901, US survey feet -- not Manatee's EPSG:2237 and not Leon's EPSG:3857.
 * Dropping outSR writes projected feet into a geographic column. Nothing errors,
 * no row count changes, and every address probe simply comes back empty.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const ORG = 'https://services1.arcgis.com/ZWOoUZbtaYePLlPw/arcgis/rest/services';

/** PRIMARY. ENG.COMM_DIST_PY, 7 rows, DISTRICT is a SmallInteger. */
const PRIMARY_URL =
  `${ORG}/Commissioner_Districts/FeatureServer/0/query` +
  '?where=1%3D1&outFields=DISTRICT' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/**
 * CROSS-CHECK. Independent digitization.
 * ⚠ Service named 2022, layer named CountyCommission_2026. ⚠ Returns 8 rows;
 * the 8th has CC = ' ' and is the Atlantic (see GATE 6).
 */
const CROSSCHECK_URL =
  `${ORG}/CountyCommission_2022/FeatureServer/0/query` +
  '?where=1%3D1&outFields=CC' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0039';
/**
 * ⚠ 'fl', NOT the 2-digit FIPS '12'.
 *
 * geofence_boundaries.state holds FIPS for TIGER layers -- county 12099/G4020 is
 * state '12'. But every PRIVATE X-code layer in this slice was written with the
 * USPS-ish lower-case code: X0036, X0037 and X0038 are all 'fl'. Nothing joins on
 * this column for X codes (check-address-reachability.mjs joins geo_id only), so
 * the load-bearing consideration is consistency with the slice. Follow FL-3/FL-4.
 */
const STATE_CODE = 'fl';
const SOURCE = 'pbcgov-agol-Commissioner_Districts-0-2026-08-28';
const GEO_ID_PREFIX = 'palm-beach-fl-commissioner-district-';
const COUNTY_GEO_ID = '12099';
const EXPECTED_COUNT = 7;

const DISTRICTS = ['1', '2', '3', '4', '5', '6', '7'] as const;

/**
 * Measured 2026-08-28 from the reprojected 4326 geometry via ::geography.
 *
 * ⚠ District 6 is 1594 sq mi -- 72% of the county, the western Glades and the
 * Lake Okeechobee shore -- and District 3 is 36.6. The tolerance below is a
 * PERCENTAGE for exactly that reason: 1% of D6 is 43x 1% of D3.
 */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 304.108,
  '2': 84.413,
  '3': 36.644,
  '4': 65.772,
  '5': 89.944,
  '6': 1594.186,
  '7': 52.612,
};

/**
 * Control points.
 *
 * The Governmental Center is the wave anchor and the INDEPENDENT positive
 * control: it is the address the acceptance probe uses, and it must resolve to
 * District 7.
 *
 * The seven interior points are SELF-CONSISTENCY controls, measured 2026-08-28
 * with ST_PointOnSurface. Every one was verified to fall inside exactly one
 * district BEFORE being written down here, rather than computed at run time --
 * ST_PointOnSurface is guaranteed to be on the surface, but the check that it is
 * on the RIGHT district's surface is the whole point.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: string }> = [
  { name: 'PBC Governmental Center (301 N Olive Ave)', lon: -80.051906016174, lat: 26.71529321541, district: '7' },
  { name: 'District 1 interior', lon: -80.249834, lat: 26.835495, district: '1' },
  { name: 'District 2 interior', lon: -80.150363, lat: 26.669630, district: '2' },
  { name: 'District 3 interior', lon: -80.116475, lat: 26.624964, district: '3' },
  { name: 'District 4 interior', lon: -80.109651, lat: 26.458135, district: '4' },
  { name: 'District 5 interior', lon: -80.175017, lat: 26.441057, district: '5' },
  { name: 'District 6 interior', lon: -80.529972, lat: 26.646274, district: '6' },
  { name: 'District 7 interior', lon: -80.039961, lat: 26.623871, district: '7' },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL, IN TWO DIRECTIONS.
 *
 * Without a negative control, a geometry test that cannot fire at all still
 * passes every positive control, because "not found" is the expected answer for
 * the negative case and nobody reads the negative case.
 *
 * Two directions because Palm Beach borders five counties and the failure could
 * be asymmetric: Fort Lauderdale is immediately SOUTH across the Broward line in
 * the dense coastal strip, and the city of Okeechobee is NORTH-WEST across the
 * lake in the sparse interior. Both measured at 0 hits on 2026-08-28.
 */
const NEGATIVE_CONTROLS: Array<{ name: string; lon: number; lat: number }> = [
  { name: 'Fort Lauderdale, Broward County', lon: -80.1373, lat: 26.1224 },
  { name: 'City of Okeechobee, Okeechobee County', lon: -80.4550, lat: 27.4467 },
];

/** Per-district area tolerance, per cent. Measured differences were 0.00%. */
const AREA_TOLERANCE_PCT = 1;

/**
 * 🔴 A TOLERANCE, NOT ST_Equals. Two digitizations of one boundary are never
 * bit-identical.
 *
 * Measured 2026-08-28, primary vs CountyCommission_2026, symmetric difference per
 * district: D1 0.4900, D2 0.0538, D3 0.0181, D4 0.1683, D5 0.0540, D6 0.7313,
 * D7 0.0744. Worst is 0.7313; total 1.59 sq mi against 2227.67 (0.07%).
 *
 * 1.5 is 2x the worst measured difference and 24x smaller than the SMALLEST
 * district (D3, 36.644 sq mi), so a genuinely missing or duplicated district
 * cannot hide underneath it.
 */
const CROSSCHECK_TOLERANCE_SQ_MI = 1.5;

/**
 * GATE 5 thresholds. See the header: the districts legitimately leave the
 * Atlantic uncovered, so the gate constrains STRUCTURE.
 */
const EDGE_TOLERANCE_SQ_MI = 0.05; // overhang, self-overlap, and "is this gap part big?"
const OFFSHORE_LON_EAST_OF = -80.05; // the one legitimate gap's interior point
const OCEAN_GAP_SQ_MI_MIN = 150;
const OCEAN_GAP_SQ_MI_MAX = 160;

/** GATE 6: the uncovered gap against the cross-check's own unassigned polygon. */
const GAP_VS_BLANK_TOLERANCE_SQ_MI = 1.0; // measured 0.2359

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

/**
 * Fetch a district layer.
 *
 * ⚠ Returns the BLANK-keyed features separately rather than dropping them. The
 * cross-check service carries the Atlantic as an unassigned row, and GATE 6 needs
 * it. Silently skipping it would throw away the control that explains the
 * uncovered area.
 */
async function fetchDistricts(
  url: string,
  field: string,
  label: string,
): Promise<{ byKey: Map<string, any>; blanks: any[] }> {
  const response = (await (await fetch(url)).json()) as { features?: Feature[] };
  if (!response?.features?.length) {
    console.error(`ERROR: no features returned from ${label}. Check the URL.`);
    await pool.end();
    process.exit(1);
  }
  const byKey = new Map<string, any>();
  const blanks: any[] = [];
  for (const feature of response.features) {
    // ⚠ Trimmed STRING, not Number.isInteger(). DISTRICT is a SmallInteger on the
    //   primary and CC is text on the cross-check; String(n).trim() handles both.
    const key = String(feature.properties[field] ?? '').trim();
    if (!feature.geometry) {
      console.warn(`  WARNING (${label}): ${field}='${key}' has no geometry — skipping`);
      continue;
    }
    if (key === '') {
      blanks.push(feature.geometry);
      continue;
    }
    if (!/^[1-7]$/.test(key)) {
      console.warn(`  WARNING (${label}): ${field} '${key}' out of range — skipping`);
      continue;
    }
    if (byKey.has(key)) {
      console.error(`ERROR (${label}): district ${key} appeared twice. Aborting rather than guessing.`);
      await pool.end();
      process.exit(1);
    }
    byKey.set(key, feature.geometry);
  }
  return { byKey, blanks };
}

async function main() {
  console.log('[load-palm-beach-commission-boundaries] Fetching Palm Beach County commission districts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes (every gate below still runs for real)');

  const { byKey: primary, blanks: primaryBlanks } = await fetchDistricts(
    PRIMARY_URL,
    'DISTRICT',
    'Commissioner_Districts layer 0',
  );
  console.log(`  Received ${primary.size} keyed features from the primary layer, ${primaryBlanks.length} blank`);

  // ⚠ The PRIMARY must have no blank row. Only the cross-check carries the ocean.
  if (primaryBlanks.length !== 0) {
    console.error(
      `ERROR: the primary layer returned ${primaryBlanks.length} blank-keyed feature(s); 0 were ` +
        'measured on 2026-08-28. The service changed shape. Abort rather than guess which polygon ' +
        'is a district.',
    );
    await pool.end();
    process.exit(1);
  }
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

  // ─── GATE 1: control points ────────────────────────────────────────────────
  console.log('\n  Control points (the Governmental Center is the wave anchor):');
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

  // ─── GATE 2: the control of the control, in two directions ─────────────────
  for (const nc of NEGATIVE_CONTROLS) {
    const outside = sorted.filter(([, g]) => pointInGeometry(g, nc.lon, nc.lat));
    const negOk = outside.length === 0;
    if (!negOk) controlFailures++;
    console.log(
      `    ${negOk ? 'PASS' : 'FAIL'}  ${nc.name}: expected no district, got ${
        outside.length ? outside.map(([d]) => 'D' + d).join('+') : 'none'
      }`,
    );
  }
  if (controlFailures > 0) {
    console.error(`\nERROR: ${controlFailures} control(s) failed. Refusing to write.`);
    await pool.end();
    process.exit(1);
  }

  // ─── GATE 3: per-district area against the 2026-08-28 measurement ──────────
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
      `    ${ok ? 'PASS' : 'FAIL'}  District ${dist}: ${got.toFixed(3)} sq mi ` +
        `(expected ${want.toFixed(3)}, ${pct.toFixed(2)}% apart)`,
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

  // ─── GATE 4: cross-check against an independent digitization ───────────────
  console.log('\n  Cross-check vs CountyCommission_2026 (independent digitization):');
  const { byKey: cross, blanks: crossBlanks } = await fetchDistricts(
    CROSSCHECK_URL,
    'CC',
    'CountyCommission_2022 layer 0 (named CountyCommission_2026)',
  );
  // ⚠ Exactly one blank row was measured. Zero means the service dropped the
  //   ocean polygon and GATE 6 loses its control; two means it changed shape.
  if (crossBlanks.length !== 1) {
    console.error(
      `ERROR: the cross-check service returned ${crossBlanks.length} blank-keyed features; exactly ` +
        '1 was measured on 2026-08-28 (the Atlantic, 155.6952 sq mi at -80.0091, 26.6456). GATE 6 ' +
        'needs it to explain the uncovered area. Re-measure before proceeding.',
    );
    await pool.end();
    process.exit(1);
  }
  if (cross.size !== EXPECTED_COUNT) {
    console.error(`ERROR: the cross-check has ${cross.size} keyed districts, expected ${EXPECTED_COUNT}.`);
    await pool.end();
    process.exit(1);
  }
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
    const ok = sym <= CROSSCHECK_TOLERANCE_SQ_MI;
    console.log(`    ${ok ? 'PASS' : 'FAIL'}  District ${dist}: symmetric difference ${sym.toFixed(4)} sq mi`);
    if (!ok) {
      console.error(
        `ERROR: the two services disagree on district ${dist} by ${sym.toFixed(4)} sq mi, over the ` +
          `${CROSSCHECK_TOLERANCE_SQ_MI} tolerance. The worst measured difference on 2026-08-28 was ` +
          '0.7313 (District 6). One of them has been re-digitized or the board redrew. Settle which ' +
          'is the adopted plan, from the county, before loading either.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── GATE 5: the districts must cover the county's LAND, once ──────────────
  //
  // 🔴 NOT "uncovered <= tolerance". 155.54 sq mi of TIGER 12099 is the Atlantic
  //    and no district claims it. This asserts the SHAPE of the gap instead.
  const tileRes = await pool.query(
    `WITH d AS (
       SELECT public.ST_Multi(public.ST_MakeValid(
                public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326))) g
         FROM unnest($1::text[]) AS gj
     ), u AS (SELECT public.ST_UnaryUnion(public.ST_Collect(g)) g FROM d),
        c AS (SELECT geometry g FROM essentials.geofence_boundaries
               WHERE geo_id = $2 AND mtfcc = 'G4020'),
        gap AS (SELECT (public.ST_Dump(public.ST_Difference(c.g, u.g))).geom g FROM c, u),
        big AS (SELECT g, public.ST_Area(g::geography) / $3 AS sq_mi FROM gap
                 WHERE public.ST_Area(g::geography) / $3 > $4)
     SELECT (public.ST_Area(public.ST_Difference(u.g, c.g)::geography) / $3)::numeric(12,4) AS overhang,
            (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / $3), 0)::numeric(12,4)
               FROM d x JOIN d y ON public.ST_AsBinary(x.g) < public.ST_AsBinary(y.g)
              WHERE public.ST_Intersects(x.g, y.g)) AS self_overlap,
            (public.ST_Area(public.ST_Difference(c.g, u.g)::geography) / $3)::numeric(12,4) AS total_uncovered,
            (SELECT count(*) FROM big)::int AS big_gap_parts,
            (SELECT sq_mi::numeric(12,4) FROM big ORDER BY sq_mi DESC LIMIT 1) AS biggest_gap_sq_mi,
            (SELECT public.ST_X(public.ST_PointOnSurface(g))::numeric(12,4) FROM big ORDER BY sq_mi DESC LIMIT 1)
              AS biggest_gap_lon,
            (SELECT public.ST_AsGeoJSON(g) FROM big ORDER BY sq_mi DESC LIMIT 1) AS biggest_gap_geojson
       FROM u, c`,
    [sorted.map(([, g]) => JSON.stringify(g)), COUNTY_GEO_ID, SQ_M_PER_SQ_MI, EDGE_TOLERANCE_SQ_MI],
  );
  if (!tileRes.rows.length) {
    console.error(
      `ERROR: TIGER county polygon ${COUNTY_GEO_ID}/G4020 is not loaded. Refusing to write — ` +
        'CC_0014 hangs all five constitutional officers off its district.',
    );
    await pool.end();
    process.exit(1);
  }
  const t = tileRes.rows[0] as Record<string, string | number | null>;
  console.log(
    `\n  Tiling vs TIGER county ${COUNTY_GEO_ID}: ${t.total_uncovered} sq mi uncovered in total, ` +
      `of which ${t.big_gap_parts} part(s) exceed ${EDGE_TOLERANCE_SQ_MI} sq mi; ` +
      `overhang ${t.overhang}, self-overlap ${t.self_overlap}`,
  );
  console.log(
    `    biggest gap: ${t.biggest_gap_sq_mi} sq mi, interior point at lon ${t.biggest_gap_lon} ` +
      `(must be east of ${OFFSHORE_LON_EAST_OF} — the Atlantic)`,
  );

  const structureProblems: string[] = [];
  if (Number(t.overhang) > EDGE_TOLERANCE_SQ_MI) {
    structureProblems.push(`overhang ${t.overhang} > ${EDGE_TOLERANCE_SQ_MI} (measured 0.0060)`);
  }
  if (Number(t.self_overlap) > EDGE_TOLERANCE_SQ_MI) {
    structureProblems.push(`self-overlap ${t.self_overlap} > ${EDGE_TOLERANCE_SQ_MI} (measured 0.0120)`);
  }
  if (Number(t.big_gap_parts) !== 1) {
    structureProblems.push(`${t.big_gap_parts} large uncovered parts, expected exactly 1`);
  }
  if (t.biggest_gap_lon === null || Number(t.biggest_gap_lon) <= OFFSHORE_LON_EAST_OF) {
    structureProblems.push(
      `the biggest gap's interior point is at lon ${t.biggest_gap_lon}, not east of ` +
        `${OFFSHORE_LON_EAST_OF} — it is inland, so it is NOT the ocean`,
    );
  }
  const gapArea = Number(t.biggest_gap_sq_mi);
  if (!(gapArea >= OCEAN_GAP_SQ_MI_MIN && gapArea <= OCEAN_GAP_SQ_MI_MAX)) {
    structureProblems.push(
      `the biggest gap is ${t.biggest_gap_sq_mi} sq mi, outside the ` +
        `${OCEAN_GAP_SQ_MI_MIN}..${OCEAN_GAP_SQ_MI_MAX} band measured for the offshore area`,
    );
  }
  if (structureProblems.length) {
    console.error(
      `\nERROR: the ${EXPECTED_COUNT} districts do not cover Palm Beach County's land as measured.\n` +
        structureProblems.map((p) => `  - ${p}`).join('\n') +
        '\n\nMeasured 2026-08-28: 155.5381 sq mi uncovered in total, in exactly ONE part above ' +
        '0.05 sq mi (155.5209 sq mi, interior point -80.0090, 26.6436) — the Atlantic Ocean, which ' +
        "TIGER's county polygon includes and the commission districts do not. The next-largest " +
        'uncovered part is 0.0019 sq mi.\n' +
        '🔴 DO NOT WIDEN THIS INTO A 156 sq mi TOLERANCE. The smallest district is 36.6 sq mi, so a ' +
        'flat tolerance that size would silently accept a missing district — uncovered land means ' +
        'residents with NO county commissioner, and nothing errors.',
    );
    await pool.end();
    process.exit(1);
  }

  // ─── GATE 6: the gap IS the ocean, per an independent publisher ────────────
  //
  // 🔴 This is what makes GATE 5's gap EXPLAINED rather than tolerated. The
  //    cross-check service tiles the whole county and assigns the offshore area to
  //    a blank CC. If our gap equals its blank polygon, two independent
  //    digitizations agree about what is missing and why.
  const { rows: [g6] } = await pool.query(
    `SELECT public.ST_Area(public.ST_SymDifference(
              public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1::text), 4326)),
              public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($2::text), 4326))
            )::geography) / $3 AS symdiff_sq_mi`,
    [String(t.biggest_gap_geojson), JSON.stringify(crossBlanks[0]), SQ_M_PER_SQ_MI],
  );
  const gapVsBlank = Number(g6.symdiff_sq_mi);
  const g6ok = gapVsBlank <= GAP_VS_BLANK_TOLERANCE_SQ_MI;
  console.log(
    `\n  ${g6ok ? 'PASS' : 'FAIL'}  The uncovered gap vs CountyCommission_2026's unassigned blank ` +
      `polygon: symmetric difference ${gapVsBlank.toFixed(4)} sq mi (measured 0.2359)`,
  );
  if (!g6ok) {
    console.error(
      `ERROR: the uncovered area and the cross-check's blank polygon differ by ` +
        `${gapVsBlank.toFixed(4)} sq mi, over the ${GAP_VS_BLANK_TOLERANCE_SQ_MI} tolerance.\n` +
        'Two publishers no longer agree about which part of the county the commission districts ' +
        'omit. Until they do, the uncovered area is UNEXPLAINED and must not be written off as ' +
        'the ocean.',
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
    const name = `Palm Beach County Commissioner District ${dist}`;
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

  // 🔴 Re-read from the DATABASE. Every gate above ran on what was FETCHED.
  //    ST_SRID is the check that catches a dropped outSR: projected US survey
  //    feet store without error and every address probe comes back empty.
  const check = await pool.query(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid,
            COUNT(*) FILTER (WHERE public.ST_SRID(geometry) <> 4326)::int AS wrong_srid
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const { n, invalid, wrong_srid: wrongSrid } = check.rows[0] as {
    n: number;
    invalid: number;
    wrong_srid: number;
  };
  console.log(`  In DB now:       ${n} rows (${invalid} invalid, ${wrongSrid} wrong SRID)`);

  await pool.end();
  if (n !== EXPECTED_COUNT || invalid !== 0 || wrongSrid !== 0) {
    console.error(
      `ERROR: expected ${EXPECTED_COUNT} valid rows in SRID 4326, got ${n} with ${invalid} invalid ` +
        `and ${wrongSrid} in the wrong SRID.`,
    );
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
