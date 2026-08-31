/**
 * load-miami-dade-commission-boundaries.ts
 *
 * Fetches the 13 single-member County Commission district boundaries for
 * Miami-Dade County, FL and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='miami-dade-fl-commissioner-district-1'..'-13',
 *                                   mtfcc='X0040', state='fl'
 *
 * Writes ONLY to essentials.geofence_boundaries. The county migration creates the
 * district rows, the government, the chambers, the offices and the people; it
 * refuses to run if these 13 boundaries are absent.
 *
 * Wave FL-6 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-08-29-knight-fl-wave-6-miami-miami-dade.md
 * Slice:  .planning/knight-foundation/fl.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THIRTEEN SEATS AND THIRTEEN POLYGONS. THERE IS NO AT-LARGE COMMISSIONER.
 *
 * Manatee has 5 single-member + 2 at-large, Leon 5 + 2, Palm Beach 7 + 0,
 * Miami-Dade 13 + 0. Four counties, four shapes. Never inherit the template.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE DISTRICTS DO TILE THE TIGER COUNTY -- THE OPPOSITE OF PALM BEACH.
 *
 * Measured 2026-08-29 against TIGER 12086: 0.0315 sq mi uncovered, 0.0320
 * overhang, 0.0000 self-overlap. Miami-Dade's districts cover the bay and the
 * offshore; Palm Beach's stop at the shoreline and leave 155 sq mi of Atlantic
 * uncovered.
 *
 * 🔴 SO FL-5's STRUCTURAL GATE IS NOT IMPORTED HERE -- IT WOULD FAIL ON CORRECT
 *    DATA. It demands exactly one uncovered part sized 150..160 sq mi offshore.
 *    Miami-Dade has no such gap. This uses the tight Leon-shaped gate instead:
 *    three quantities, one 0.25 sq mi tolerance. Two adjacent counties, two
 *    conventions, neither gate portable. MEASURE THE TILING BEFORE CHOOSING THE
 *    GATE.
 *
 * ⚠ DO NOT WIDEN THE 0.25 TOLERANCE. The smallest district is 24.323 sq mi, so
 *   a flat tolerance any larger starts to admit a missing district -- which
 *   means residents with NO county commissioner, and nothing errors.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THERE IS NO INDEPENDENT CROSS-CHECK FOR THIS LAYER, AND THAT IS A FINDING.
 *
 * Palm Beach and Miami city each publish two current digitizations of one map,
 * so their loaders can corroborate. Miami-Dade publishes exactly ONE current
 * digitization. The other three polygon services are HISTORICAL VINTAGES --
 * CommissionDistrict2011, CommissionDistrict2001_gdb, CommissionDistrict1992_gdb
 * -- and TBLCOMMISSIONDISTRICT is a Table with no geometry at all.
 *
 * So GATE 1 inverts the usual test: the 2011 layer is a NEGATIVE control that
 * must DIFFER, not a cross-check that must agree.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE VINTAGE GATE RUNS FIRST, AND THE ORDER IS LOAD-BEARING.
 *
 * Measured 2026-08-29 by pointing PRIMARY_URL at CommissionDistrict2011:
 *
 *   - ALL 17 CONTROL POINTS PASS on the wrong map. Every one of the 13 interior
 *     points and both negative controls. The point gates cannot discriminate
 *     between the two vintages AT ALL -- the districts moved, but not far enough
 *     to move an interior point out of its own district.
 *   - The area gate DOES fire, on District 2 at 3.76% -- but its remedy text says
 *     "re-measure and update EXPECTED_SQ_MI in the same commit". An editor who
 *     follows that advice RE-BASELINES THE LOADER ONTO THE 2011 MAP, and every
 *     gate then passes on it.
 *   - District 1 is 0.21% apart, INSIDE the 1% tolerance, so it passes the area
 *     gate on the wrong map too.
 *
 * 🔴 SO "WHICH MAP IS THIS?" MUST BE ANSWERED BEFORE ANY GATE WHOSE FAILURE
 *    MESSAGE INVITES RE-BASELINING. The vintage gate is cheap, it is the only
 *    gate that can tell the vintages apart, and its message names the actual
 *    cause. It runs first. Do not reorder it below the area gate.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER.
 *
 * The primary also carries COMMNAME, and today it happens to be current. That is
 * luck. Two services from THIS SAME PUBLISHER prove the failure mode: both
 * CommissionDistrict2011 and TBLCOMMISSIONDISTRICT still name Jean Monestime and
 * Sally A. Heyman, neither of whom holds a seat. This loader requests ID only.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 outSR=4326 IS LOAD-BEARING. Miami-Dade publishes natively in EPSG:3857 (Web
 * Mercator), as Leon does. Dropping outSR writes projected metres into a
 * geographic column. Nothing errors, no row count changes, and every address
 * probe simply comes back empty.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const ORG = 'https://services.arcgis.com/8Pc9XBTAsYuxx9Ny/arcgis/rest/services';

/** PRIMARY. 13 polygons, ID SmallInteger, COMMNAME current as of 2026-08-29. */
const PRIMARY_URL =
  `${ORG}/CommissionDistrict_gdb/FeatureServer/0/query` +
  '?where=1%3D1&outFields=ID' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/**
 * 🔴 A HISTORICAL VINTAGE, USED AS A NEGATIVE CONTROL. See GATE 1.
 *
 * Verified 2026-08-29: this service returns the SAME 13 ids, the SAME
 * esriFieldTypeSmallInteger ID field, the SAME esriGeometryPolygon type and the
 * SAME native wkid 3857 as the primary. It is indistinguishable from the primary
 * by shape alone. Only the geometry tells them apart.
 */
const VINTAGE_2011_URL =
  `${ORG}/CommissionDistrict2011/FeatureServer/0/query` +
  '?where=1%3D1&outFields=ID' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/** A Table, not a layer. GATE 6 documents that, once, so nobody reaches for it. */
const TBL_URL =
  `${ORG}/TBLCOMMISSIONDISTRICT/FeatureServer/0/query` +
  '?where=1%3D1&outFields=DISTRICT&returnGeometry=true&f=geojson&resultRecordCount=100';

const MTFCC = 'X0040';

/**
 * ⚠ 'fl', NOT the 2-digit FIPS '12'.
 *
 * geofence_boundaries.state holds FIPS for TIGER layers -- county 12086/G4020 is
 * state '12'. But every PRIVATE X-code layer in this slice was written with the
 * lower-case USPS-ish code: X0036..X0039 are all 'fl'. Nothing joins on this
 * column for X codes, so the load-bearing consideration is consistency with the
 * slice. Follow FL-3/FL-4/FL-5.
 */
const STATE_CODE = 'fl';
const SOURCE = 'miamidade-agol-CommissionDistrict_gdb-0-2026-08-29';
const GEO_ID_PREFIX = 'miami-dade-fl-commissioner-district-';
const COUNTY_GEO_ID = '12086';
const EXPECTED_COUNT = 13;

const DISTRICTS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13'] as const;

/**
 * ⚠ TWO DIGITS. FL-5's key regex is /^[1-7]$/ and a careless copy to /^[1-9]$/
 * would silently SKIP districts 10-13, then report "expected 13, got 9" --
 * an error message that points at the count, not at the regex that caused it.
 */
const DISTRICT_KEY_RE = /^(1[0-3]|[1-9])$/;

/**
 * Measured 2026-08-29 from the reprojected 4326 geometry via ::geography.
 *
 * ⚠ District 9 is 1111.772 sq mi and District 13 is 24.323 -- a 46x range, wider
 * than Palm Beach's 43x. The tolerance below is a PERCENTAGE for that reason.
 *
 * 🔴 IF THIS GATE FAILS, DO NOT UPDATE THESE NUMBERS UNTIL GATE 1 HAS PASSED.
 * The 2011 vintage is 3.76% off on District 2 and 0.21% off on District 1;
 * re-baselining here is how the wrong map gets accepted permanently.
 */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 33.372,
  '2': 28.911,
  '3': 26.175,
  '4': 61.584,
  '5': 50.141,
  '6': 35.926,
  '7': 115.374,
  '8': 188.016,
  '9': 1111.772,
  '10': 30.111,
  '11': 213.728,
  '12': 469.889,
  '13': 24.323,
};

/**
 * Control points.
 *
 * The Government Center is the wave anchor and the INDEPENDENT positive control.
 * The thirteen interior points are SELF-CONSISTENCY controls, measured
 * 2026-08-29 with ST_PointOnSurface. Every one was verified to fall inside
 * exactly one district BEFORE being written down here, rather than computed at
 * run time -- ST_PointOnSurface is guaranteed to be on the surface, but the check
 * that it is on the RIGHT district's surface is the whole point.
 *
 * ⚠ THESE POINTS CANNOT DETECT THE WRONG VINTAGE. All 17 pass against the 2011
 * map. They prove the districts are internally consistent and correctly keyed;
 * they prove nothing about WHICH apportionment this is. That is GATE 1's job.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: string }> = [
  { name: 'MDC Government Center (111 NW 1st St)', lon: -80.196332709513, lat: 25.775078850443, district: '5' },
  { name: 'Miami City Hall (3500 Pan American Dr)', lon: -80.234992579394, lat: 25.728661855119, district: '7' },
  { name: 'District 1 interior', lon: -80.254245, lat: 25.934698, district: '1' },
  { name: 'District 2 interior', lon: -80.234222, lat: 25.865057, district: '2' },
  { name: 'District 3 interior', lon: -80.200758, lat: 25.831319, district: '3' },
  { name: 'District 4 interior', lon: -80.116251, lat: 25.880842, district: '4' },
  { name: 'District 5 interior', lon: -80.100963, lat: 25.797388, district: '5' },
  { name: 'District 6 interior', lon: -80.297781, lat: 25.772683, district: '6' },
  { name: 'District 7 interior', lon: -80.206602, lat: 25.690727, district: '7' },
  { name: 'District 8 interior', lon: -80.229851, lat: 25.564458, district: '8' },
  { name: 'District 9 interior', lon: -80.511737, lat: 25.401600, district: '9' },
  { name: 'District 10 interior', lon: -80.359198, lat: 25.733445, district: '10' },
  { name: 'District 11 interior', lon: -80.651537, lat: 25.685401, district: '11' },
  { name: 'District 12 interior', lon: -80.598434, lat: 25.870111, district: '12' },
  { name: 'District 13 interior', lon: -80.308131, lat: 25.898553, district: '13' },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL.
 *
 * Without a negative control, a geometry test that cannot fire at all still
 * passes every positive control, because "not found" is the expected answer for
 * the negative case and nobody reads the negative case.
 *
 * Two directions: Fort Lauderdale is immediately NORTH across the Broward line in
 * the dense coastal strip, and Key West is far SOUTH-WEST in Monroe County --
 * which matters here because Miami-Dade's District 9 runs deep into the
 * Everglades and its southern reach borders Monroe.
 */
const NEGATIVE_CONTROLS: Array<{ name: string; lon: number; lat: number }> = [
  { name: 'Fort Lauderdale, Broward County', lon: -80.1373, lat: 26.1224 },
  { name: 'Key West, Monroe County', lon: -81.7800, lat: 24.5551 },
];

/** Per-district area tolerance, per cent. Measured differences were 0.00%. */
const AREA_TOLERANCE_PCT = 1;

/** GATE 5. Measured 0.0315 / 0.0320 / 0.0000 on 2026-08-29. */
const TILING_TOLERANCE_SQ_MI = 0.25;

/**
 * 🔴 THE VINTAGE GATE. CommissionDistrict2011 has the SAME field names, the SAME
 * geometry type and the SAME row count as the primary. A loader pointed at it
 * returns 13 valid polygons with plausible numbers and nothing errors.
 *
 * Measured symmetric difference, primary vs 2011, per district:
 *   D1 0.136   D2 1.325   D3 0.805   D4 5.385   D5 7.816
 *   D6 10.205  D7 16.339  D8 67.718  D9 126.132 D10 2.541
 *   D11 12.070 D12 6.291  D13 3.347
 *
 * 🔴 DISTRICT 1 MOVED BY 0.136 sq mi. A spot check there would PASS on the wrong
 * map. The gate therefore checks the districts that actually moved.
 */
const VINTAGE_MUST_DIFFER: Array<{ district: string; minSqMi: number }> = [
  { district: '9', minSqMi: 100 }, // measured 126.132
  { district: '8', minSqMi: 50 }, // measured  67.718
  { district: '7', minSqMi: 10 }, // measured  16.339
];

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

/** Fetch a district layer, keyed by `field`. Blank-keyed rows are returned separately. */
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
    // ⚠ Trimmed STRING, not Number.isInteger(). ID is a SmallInteger here, but the
    //   trimmed-string regex works on both integer and text publishers (FL-5).
    const key = String(feature.properties[field] ?? '').trim();
    if (!feature.geometry) {
      console.warn(`  WARNING (${label}): ${field}='${key}' has no geometry — skipping`);
      continue;
    }
    if (key === '') {
      blanks.push(feature.geometry);
      continue;
    }
    if (!DISTRICT_KEY_RE.test(key)) {
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

/** Symmetric difference of two GeoJSON geometries, in square miles. */
async function symDiffSqMi(a: any, b: any): Promise<number> {
  const {
    rows: [r],
  } = await pool.query(
    `SELECT public.ST_Area(public.ST_SymDifference(
              public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1::text), 4326)),
              public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($2::text), 4326))
            )::geography) / $3 AS sq_mi`,
    [JSON.stringify(a), JSON.stringify(b), SQ_M_PER_SQ_MI],
  );
  return Number(r.sq_mi);
}

async function main() {
  console.log('[load-miami-dade-commission-boundaries] Fetching Miami-Dade County commission districts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes (every gate below still runs for real)');

  const { byKey: primary, blanks: primaryBlanks } = await fetchDistricts(
    PRIMARY_URL,
    'ID',
    'CommissionDistrict_gdb layer 0',
  );
  console.log(`  Received ${primary.size} keyed features from the primary layer, ${primaryBlanks.length} blank`);

  if (primaryBlanks.length !== 0) {
    console.error(
      `ERROR: the primary layer returned ${primaryBlanks.length} blank-keyed feature(s); 0 were ` +
        'measured on 2026-08-29. The service changed shape. Abort rather than guess which polygon ' +
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

  // ─── GATE 1: THE VINTAGE GATE — the 2011 layer MUST DIFFER ─────────────────
  //
  // 🔴 The gate no earlier wave needed, and it runs FIRST BY DESIGN. Miami-Dade
  //    publishes four polygon vintages, and the 2011 one is indistinguishable
  //    from the current one by field names, geometry type, native SRID and row
  //    count. Only geometry tells them apart, so only geometry can gate them.
  //
  // 🔴 IT MUST PRECEDE THE AREA GATE. Measured 2026-08-29 against the 2011 map:
  //    all 17 control points pass, and the area gate fails on District 2 with a
  //    message that invites re-baselining EXPECTED_SQ_MI onto the wrong map.
  //    This gate's message names the real cause. Let it speak first.
  console.log('\n  Vintage gate — CommissionDistrict2011 must DIFFER (it is NOT a cross-check):');
  const { byKey: vintage } = await fetchDistricts(VINTAGE_2011_URL, 'ID', 'CommissionDistrict2011 layer 0');
  if (vintage.size !== EXPECTED_COUNT) {
    console.error(
      `ERROR: the 2011 vintage returned ${vintage.size} districts, expected ${EXPECTED_COUNT}. ` +
        'It is the negative control for the primary; without it the primary is unchecked.',
    );
    await pool.end();
    process.exit(1);
  }
  for (const { district, minSqMi } of VINTAGE_MUST_DIFFER) {
    const other = vintage.get(district);
    if (!other) {
      console.error(`ERROR: the 2011 vintage has no district ${district}.`);
      await pool.end();
      process.exit(1);
    }
    const sym = await symDiffSqMi(primary.get(district), other);
    const ok = sym >= minSqMi;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  District ${district}: ${sym.toFixed(3)} sq mi different from 2011 ` +
        `(must be at least ${minSqMi})`,
    );
    if (!ok) {
      console.error(
        `ERROR: District ${district} is only ${sym.toFixed(3)} sq mi different from the 2011 map, ` +
          `expected at least ${minSqMi}.\n` +
          'PRIMARY_URL is probably pointing at a historical vintage. The current plan is the 2022 ' +
          'apportionment; CommissionDistrict2011/2001_gdb/1992_gdb are all still published.\n' +
          '⚠ District 1 moved by only 0.136 sq mi between the two maps, so a spot check THERE would ' +
          'pass on the wrong map. That is why this gate checks 9, 8 and 7.\n' +
          '⚠ DO NOT "fix" this by updating EXPECTED_SQ_MI. All 17 control points pass on the 2011 ' +
          'map and the area gate is only 3.76% off on its worst district — re-baselining would make ' +
          'every other gate agree with the wrong apportionment.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── GATE 2: control points ────────────────────────────────────────────────
  //
  // ⚠ These prove correct KEYING and internal consistency, not correct vintage.
  //   All 17 pass against the 2011 map. GATE 1 is what discriminates.
  console.log('\n  Control points (the Government Center is the wave anchor):');
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

  // ─── GATE 3: the control of the control, in two directions ─────────────────
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

  // ─── GATE 4: per-district area against the 2026-08-29 measurement ──────────
  console.log('\n  Per-district areas (vs the 2026-08-29 measurement):');
  for (const [dist, geom] of sorted) {
    const {
      rows: [a],
    } = await pool.query(
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
        `ERROR: district ${dist} is ${pct.toFixed(2)}% off its 2026-08-29 measurement.\n` +
          'Either the layer was re-digitized, the board redrew the districts, or outSR was ' +
          'dropped. Re-measure deliberately and update EXPECTED_SQ_MI in the same commit, with ' +
          'the reason.\n' +
          '🔴 GATE 1 (the vintage gate) passed, so this is NOT the 2011 map. If you reached this ' +
          'line with GATE 1 disabled, re-enable it before touching these numbers.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── GATE 5: the 13 districts must TILE the TIGER county ───────────────────
  //
  // 🔴 NOT FL-5's structural gate. See the header: Miami-Dade's districts cover
  //    the bay and the offshore, so a tight tolerance is the correct test here
  //    and FL-5's "exactly one 150..160 sq mi offshore gap" would fail.
  //
  // 🔴 `c` pairs geo_id WITH mtfcc: '12086' also matches a New York ZIP code in
  //    this table, and an unpaired lookup would silently compare against it.
  const tileRes = await pool.query(
    `WITH d AS (SELECT public.ST_Multi(public.ST_MakeValid(
                  public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326))) g
                  FROM unnest($1::text[]) AS gj),
          u AS (SELECT public.ST_UnaryUnion(public.ST_Collect(g)) g FROM d),
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
        'the county migration hangs the constitutional officers off its district.',
    );
    await pool.end();
    process.exit(1);
  }
  const t = tileRes.rows[0] as Record<string, string>;
  console.log(
    `\n  Tiling vs TIGER county ${COUNTY_GEO_ID}: ${t.county_uncovered} sq mi uncovered, ` +
      `${t.overhang} overhang, ${t.self_overlap} self-overlap (tolerance ${TILING_TOLERANCE_SQ_MI})`,
  );
  const tilingProblems: string[] = [];
  for (const [k, label] of [
    ['county_uncovered', 'uncovered'],
    ['overhang', 'overhang'],
    ['self_overlap', 'self-overlap'],
  ] as const) {
    if (Number(t[k]) > TILING_TOLERANCE_SQ_MI) {
      tilingProblems.push(`${label} ${t[k]} > ${TILING_TOLERANCE_SQ_MI}`);
    }
  }
  if (tilingProblems.length) {
    console.error(
      `\nERROR: the ${EXPECTED_COUNT} districts do not tile Miami-Dade County within ` +
        `${TILING_TOLERANCE_SQ_MI} sq mi.\n` +
        tilingProblems.map((p) => `  - ${p}`).join('\n') +
        '\n\nMeasured 2026-08-29: 0.0315 uncovered / 0.0320 overhang / 0.0000 self-overlap.\n' +
        "NOTE: Palm Beach's districts stop at the shoreline and leave 155 sq mi of Atlantic " +
        "uncovered; Miami-Dade's cover the bay and the offshore. DO NOT import FL-5's structural " +
        'gate here, and do not widen this one — the smallest district is 24.3 sq mi.',
    );
    await pool.end();
    process.exit(1);
  }

  // ─── GATE 6: TBLCOMMISSIONDISTRICT is NOT usable as geometry ───────────────
  //
  // ⚠ A documented probe, run once. The table is named like the primary and
  //   returns 13 rows, so a future editor will reach for it. It also still names
  //   Jean Monestime and Sally A. Heyman -- the roster-in-a-boundary-layer
  //   failure mode, from this same publisher.
  const tbl = (await (await fetch(TBL_URL)).json()) as { features?: Feature[] };
  const tblFeatures = tbl?.features ?? [];
  const withGeometry = tblFeatures.filter((f) => f.geometry != null).length;
  const tblOk = tblFeatures.length > 0 && withGeometry === 0;
  console.log(
    `\n  ${tblOk ? 'PASS' : 'FAIL'}  TBLCOMMISSIONDISTRICT probe: ${tblFeatures.length} features, ` +
      `${withGeometry} with geometry (expected 0 — it is a Table, not a layer)`,
  );
  if (!tblOk) {
    console.error(
      `ERROR: TBLCOMMISSIONDISTRICT returned ${withGeometry} feature(s) WITH geometry out of ` +
        `${tblFeatures.length}. It was a geometry-less Table on 2026-08-29. If it now carries ` +
        'polygons, someone must establish which vintage they are before anything uses them — the ' +
        'table still names commissioners who left office.',
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
    const name = `Miami-Dade County Commission District ${dist}`;
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
  //    ST_SRID is the check that catches a dropped outSR: projected metres store
  //    without error and every address probe comes back empty.
  const check = await pool.query(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid,
            COUNT(*) FILTER (WHERE public.ST_SRID(geometry) <> 4326)::int AS wrong_srid
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const {
    n,
    invalid,
    wrong_srid: wrongSrid,
  } = check.rows[0] as {
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
