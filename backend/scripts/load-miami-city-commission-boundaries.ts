/**
 * load-miami-city-commission-boundaries.ts
 *
 * Fetches the 5 single-member City Commission district boundaries for the City of
 * Miami, FL and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='miami-fl-commission-district-1'..'-5',
 *                                   mtfcc='X0041', state='fl'
 *
 * Writes ONLY to essentials.geofence_boundaries. The city migrations create the
 * district rows, the government, the chamber, the offices and the people; they
 * refuse to run if these 5 boundaries are absent.
 *
 * Wave FL-6 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-08-29-knight-fl-wave-6-miami-miami-dade.md
 * Slice:  .planning/knight-foundation/fl.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 MIAMI'S CITY COMMISSION MAP WAS STRUCK DOWN TWICE BY A FEDERAL COURT.
 *
 *   2022 map: adopted, sued (ACLU of Florida).
 *   2023 map: adopted after the suit, ALSO held unconstitutional.
 *   April 2024: Judge K. Michael Moore holds BOTH racially gerrymandered.
 *   May 2024: settlement -- the Commission adopts, 4-1, a map drawn by the
 *   plaintiffs, aligned to the Miami River, railroads and major roadways.
 *   That settlement map governs 2026 and is what both published layers contain
 *   (measured: they agree to 0.0134 sq mi on the union).
 *
 * ⚠ fl.md's FL-1 note that "only the congressional map was litigated after 2022"
 *   is true of the STATE maps and FALSE of Miami's city map.
 *
 * 🔴 THE PROVENANCE IS WHY THE VINTAGE GATE IS NOT OPTIONAL HERE. Loading a
 *    superseded Miami map does not merely publish stale lines -- it publishes a
 *    districting a federal court held to be a racial gerrymander.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 FOUR SERVICES ON THIS ORG LOOK LIKE COMMISSION DISTRICTS. TWO ARE.
 *
 * Measured 2026-08-29 across all 185 published services:
 *
 *   Commission_Districts       PRIMARY. schema edited 2024-07-08 (just after the
 *                              settlement), data edited 2025-12-17 (just after
 *                              the December runoff). COMDISTID, 5 rows.
 *   Commission_Districts_New   CROSS-CHECK. A genuine independent digitization of
 *                              the SAME settlement map: per-district symmetric
 *                              difference 0.0096..0.0940 sq mi.
 *                              ⚠ Named "_New" but its data edit is OLDER
 *                              (2025-06-24). THE NAME IS NOT THE VINTAGE -- the
 *                              third wave running to hit this.
 *   Enriched Commission        🔴 A 2017 PRE-LITIGATION VINTAGE, AND THE MOST
 *   Districts                  DANGEROUS OBJECT ON THIS SERVER. Same COMDISTID /
 *                              COMNAME / ADDRESS field names as the primary, same
 *                              esriGeometryPolygon, 5 rows keyed 1..5. A loader
 *                              pointed at it PARSES PERFECTLY. Edited 2017-07-19
 *                              -- five years before the first map that was struck
 *                              down. Its COMNAME reads Wifredo (Willy) Gort, Ken
 *                              Russell, Frank Carollo, Francis Suarez, Keon
 *                              Hardemon. GATE 1 exists for this layer.
 *   District_<32 hex>          NOT commission districts at all: 13 NEIGHBOURHOOD
 *                              polygons (Model City, Little Haiti, Wynwood,
 *                              Overtown, Downtown...). Its field is `district`,
 *                              holding a neighbourhood NAME, and it carries the
 *                              NEWEST edit date on the server (2026-06-01).
 *                              ⚠ Picking the most recently edited "district"
 *                              layer gets you neighbourhoods.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 GATE ORDER IS LOAD-BEARING, AND FL-6 TASK 1 PROVED WHY.
 *
 * The discriminating gates run FIRST: GATE 1 (this is not the 2017 map) and
 * GATE 2 (an independent digitization agrees). Only then the area gate, whose
 * failure message says "re-measure and update EXPECTED_SQ_MI" -- advice that,
 * followed at the wrong moment, re-baselines the loader onto a bad map and makes
 * every other gate agree with it. A gate that invites re-baselining must never be
 * the first to fire.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE ADDRESS FIELD IS FABRICATED. DO NOT READ IT, FOR ANYTHING.
 *
 * Measured on the primary 2026-08-29: D1 '3500 Pan American Drive', D2 '3501',
 * D3 '3502', D4 '3503', D5 '3504'. That is CITY HALL's address incremented once
 * per district. The 2017 layer carries the identical fabricated sequence, so it
 * has been inherited across at least nine years and two struck-down maps.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER either. COMNAME on the primary
 *   happens to look current; COMNAME on the 2017 layer names five people who
 *   between them have since become Mayor, moved to the COUNTY commission, or left
 *   office. This loader requests COMDISTID only.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ THIS IS A CITY, GATED AGAINST THE TIGER PLACE -- NOT AGAINST THE COUNTY.
 *
 * Miami is ~56 sq mi inside a ~2,389 sq mi county. A county-tiling gate would be
 * meaningless. The five districts are gated against TIGER place 1245000 (G4110),
 * with a 1.0 sq mi tolerance both ways because two agencies' city boundaries
 * differ by annexation timing: measured 0.4428 uncovered / 0.3056 overhang.
 *
 * 🔴 outSR=4326 IS LOAD-BEARING, as in every loader in this slice.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const ORG = 'https://services1.arcgis.com/CvuPhqcTQpZPT9qY/arcgis/rest/services';

/**
 * PRIMARY. Schema last edited 2024-07-08, right after the May 2024 settlement;
 * data last edited 2025-12-17, right after the December runoff.
 */
const PRIMARY_URL =
  `${ORG}/Commission_Districts/FeatureServer/0/query` +
  '?where=1%3D1&outFields=COMDISTID' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/**
 * CROSS-CHECK: an independent digitization of the SAME settlement map.
 * ⚠ Named "_New" but its data edit is OLDER (2025-06-24). The name is not the
 * vintage -- third wave running.
 */
const CROSSCHECK_URL =
  `${ORG}/Commission_Districts_New/FeatureServer/0/query` +
  '?where=1%3D1&outFields=COMDISTID' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/**
 * 🔴 THE 2017 PRE-LITIGATION VINTAGE, USED AS A NEGATIVE CONTROL. See GATE 1.
 * Identical field names to the primary. It must DIFFER, and by a lot.
 */
const VINTAGE_2017_URL =
  `${ORG}/Enriched%20Commission%20Districts/FeatureServer/0/query` +
  '?where=1%3D1&outFields=COMDISTID' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0041';

/** ⚠ 'fl', not FIPS '12' — consistent with X0036..X0040 in this slice. */
const STATE_CODE = 'fl';
const SOURCE = 'miamigis-agol-Commission_Districts-0-2026-08-29';
const GEO_ID_PREFIX = 'miami-fl-commission-district-';

/** TIGER place "Miami city". ⚠ Paired with mtfcc G4110 in every lookup. */
const PLACE_GEO_ID = '1245000';
const PLACE_MTFCC = 'G4110';

const EXPECTED_COUNT = 5;
const DISTRICTS = ['1', '2', '3', '4', '5'] as const;
const DISTRICT_KEY_RE = /^[1-5]$/;

/** Measured 2026-08-29 from the reprojected 4326 geometry via ::geography. */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 7.252,
  '2': 26.299,
  '3': 4.377,
  '4': 7.486,
  '5': 10.523,
};

/**
 * Control points.
 *
 * City Hall is the wave anchor. ⚠ It is in CITY district 2 and COUNTY district 7
 * -- the two are unrelated numbers over the same ground, which is exactly the
 * confusion this wave is most exposed to.
 *
 * ⚠ As in Task 1, these prove correct KEYING, not correct vintage. GATE 1 and
 *   GATE 2 are what discriminate between maps.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: string }> = [
  { name: 'Miami City Hall (3500 Pan American Dr)', lon: -80.234992579394, lat: 25.728661855119, district: '2' },
  { name: 'MDC Government Center (111 NW 1st St)', lon: -80.196332709513, lat: 25.775078850443, district: '5' },
  { name: 'District 1 interior', lon: -80.235383, lat: 25.793254, district: '1' },
  { name: 'District 2 interior', lon: -80.172787, lat: 25.771206, district: '2' },
  { name: 'District 3 interior', lon: -80.211016, lat: 25.763328, district: '3' },
  { name: 'District 4 interior', lon: -80.242542, lat: 25.755484, district: '4' },
  { name: 'District 5 interior', lon: -80.201079, lat: 25.812268, district: '5' },
];

/**
 * 🔴 HIALEAH IS THE CONTROL THIS WAVE MOST NEEDS.
 *
 * A large incorporated city INSIDE Miami-Dade that is NOT the City of Miami. The
 * failure this guards against is a city layer that has quietly become a county
 * layer, or a place polygon confused for the county: both would put a Hialeah
 * address inside a Miami city district and give that resident a commissioner they
 * cannot vote for. Measured 0 city hits.
 *
 * Fort Lauderdale is the second direction, outside the county entirely.
 */
const NEGATIVE_CONTROLS: Array<{ name: string; lon: number; lat: number }> = [
  { name: 'Hialeah (in Miami-Dade, NOT in Miami)', lon: -80.2781, lat: 25.8576 },
  { name: 'Fort Lauderdale, Broward County', lon: -80.1373, lat: 26.1224 },
];

const AREA_TOLERANCE_PCT = 1;

/**
 * 🔴 A TOLERANCE, NOT ST_Equals. Two digitizations of one boundary are never
 * bit-identical. Measured per district 2026-08-29: D1 0.0512, D2 0.0504,
 * D3 0.0133, D4 0.0096, D5 0.0940. 0.25 is ~2.7x the worst, and 17x smaller than
 * the SMALLEST district (D3, 4.377 sq mi), so a missing or duplicated district
 * cannot hide underneath it.
 */
const CROSSCHECK_TOLERANCE_SQ_MI = 0.25;

/** Place gate. Measured 0.4428 uncovered / 0.3056 overhang / 0.0001 self-overlap. */
const PLACE_TOLERANCE_SQ_MI = 1.0;
const SELF_OVERLAP_TOLERANCE_SQ_MI = 0.25;

/**
 * 🔴 THE VINTAGE GATE. The 2017 layer must DIFFER.
 *
 * Measured symmetric difference, primary vs Enriched 2017, per district:
 *   D1 0.5269   D2 1.5454   D3 1.6569   D4 1.7351   D5 0.7149
 *
 * 🔴 D1 (0.5269) and D5 (0.7149) are the SMALL movers -- barely 2x the
 * cross-check tolerance. A spot check on either is weak evidence. The gate checks
 * D4, D3 and D2, which moved 3x further, and each threshold sits at ~60% of the
 * measured value so an ordinary re-digitization cannot trip it.
 */
const VINTAGE_MUST_DIFFER: Array<{ district: string; minSqMi: number }> = [
  { district: '4', minSqMi: 1.0 }, // measured 1.7351
  { district: '3', minSqMi: 1.0 }, // measured 1.6569
  { district: '2', minSqMi: 0.9 }, // measured 1.5454
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
  // ⚠ ArcGIS answers a throttled or errored request with an HTML page, sometimes
  //   under a 200. Parsing that as JSON dies with "Unexpected token '<'", which
  //   names neither the service nor the cause. Observed live 2026-08-29 against
  //   the Enriched layer mid-run. Read the body once and say what came back.
  const raw = await (await fetch(url)).text();
  let response: { features?: Feature[] };
  try {
    response = JSON.parse(raw) as { features?: Feature[] };
  } catch {
    console.error(
      `ERROR: ${label} did not return JSON. First 200 characters:\n  ${raw.slice(0, 200).replace(/\s+/g, ' ')}\n` +
        'An HTML body here is normally throttling or a service error, NOT a bad URL — retry before ' +
        'changing anything.',
    );
    await pool.end();
    process.exit(1);
  }
  if (!response?.features?.length) {
    console.error(`ERROR: no features returned from ${label}. Check the URL.`);
    await pool.end();
    process.exit(1);
  }
  const byKey = new Map<string, any>();
  const blanks: any[] = [];
  for (const feature of response.features) {
    // ⚠ Trimmed STRING, not Number.isInteger(). COMDISTID is an integer here; the
    //   trimmed-string form works on both integer and text publishers (FL-5).
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
  console.log('[load-miami-city-commission-boundaries] Fetching City of Miami commission districts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes (every gate below still runs for real)');

  const { byKey: primary, blanks: primaryBlanks } = await fetchDistricts(
    PRIMARY_URL,
    'COMDISTID',
    'Commission_Districts layer 0',
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

  // ─── GATE 1: THE VINTAGE GATE — the 2017 layer MUST DIFFER ─────────────────
  //
  // 🔴 RUNS FIRST BY DESIGN (FL-6 Task 1's finding). "Enriched Commission
  //    Districts" carries the SAME COMDISTID/COMNAME/ADDRESS fields, the same
  //    geometry type and the same 5 keys as the primary, and dates to 2017 --
  //    before both of the maps a federal court struck down. A loader pointed at
  //    it parses perfectly and publishes a superseded gerrymander.
  console.log('\n  Vintage gate — the 2017 "Enriched" layer must DIFFER (it is NOT a cross-check):');
  const { byKey: vintage } = await fetchDistricts(
    VINTAGE_2017_URL,
    'COMDISTID',
    'Enriched Commission Districts layer 0 (2017)',
  );
  if (vintage.size !== EXPECTED_COUNT) {
    console.error(
      `ERROR: the 2017 vintage returned ${vintage.size} districts, expected ${EXPECTED_COUNT}. ` +
        'It is the negative control for the primary; without it the primary is unchecked.',
    );
    await pool.end();
    process.exit(1);
  }
  for (const { district, minSqMi } of VINTAGE_MUST_DIFFER) {
    const other = vintage.get(district);
    if (!other) {
      console.error(`ERROR: the 2017 vintage has no district ${district}.`);
      await pool.end();
      process.exit(1);
    }
    const sym = await symDiffSqMi(primary.get(district), other);
    const ok = sym >= minSqMi;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  District ${district}: ${sym.toFixed(4)} sq mi different from 2017 ` +
        `(must be at least ${minSqMi})`,
    );
    if (!ok) {
      console.error(
        `ERROR: District ${district} is only ${sym.toFixed(4)} sq mi different from the 2017 map, ` +
          `expected at least ${minSqMi}.\n` +
          'PRIMARY_URL is probably pointing at "Enriched Commission Districts", which is a 2017 ' +
          'PRE-LITIGATION vintage with identical field names.\n' +
          '🔴 Miami\'s 2022 and 2023 commission maps were BOTH held racially gerrymandered in April ' +
          '2024. The map in force is the May 2024 settlement map. Loading a superseded Miami map ' +
          'publishes a districting a federal court struck down.\n' +
          '⚠ DO NOT "fix" this by updating EXPECTED_SQ_MI.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── GATE 2: cross-check against an independent digitization ───────────────
  //
  // ⚠ Also runs before the area gate: it discriminates between maps, and its
  //   failure message tells the reader to settle which plan is adopted rather
  //   than to re-baseline.
  console.log('\n  Cross-check vs Commission_Districts_New (independent digitization of the same map):');
  const { byKey: cross } = await fetchDistricts(
    CROSSCHECK_URL,
    'COMDISTID',
    'Commission_Districts_New layer 0',
  );
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
    const sym = await symDiffSqMi(geom, other);
    const ok = sym <= CROSSCHECK_TOLERANCE_SQ_MI;
    console.log(`    ${ok ? 'PASS' : 'FAIL'}  District ${dist}: symmetric difference ${sym.toFixed(4)} sq mi`);
    if (!ok) {
      console.error(
        `ERROR: the two services disagree on district ${dist} by ${sym.toFixed(4)} sq mi, over the ` +
          `${CROSSCHECK_TOLERANCE_SQ_MI} tolerance. The worst measured difference on 2026-08-29 was ` +
          '0.0940 (District 5). One of them has been re-digitized, or the Commission redrew. Settle ' +
          'which is the adopted plan, from the City, before loading either.\n' +
          '⚠ Do not settle it by service NAME: "Commission_Districts_New" holds the OLDER data edit.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── GATE 3: control points ────────────────────────────────────────────────
  console.log('\n  Control points (City Hall is the wave anchor — CITY district 2, COUNTY district 7):');
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

  // ─── GATE 4: the control of the control — Hialeah is the important one ─────
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

  // ─── GATE 5: per-district area against the 2026-08-29 measurement ──────────
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
          'Either the layer was re-digitized, the Commission redrew, or outSR was dropped. ' +
          'Re-measure deliberately and update EXPECTED_SQ_MI in the same commit, with the reason.\n' +
          '🔴 GATES 1 and 2 passed, so this is neither the 2017 map nor a disagreement between the ' +
          'two current digitizations. If you reached this line with either gate disabled, re-enable ' +
          'it before touching these numbers.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── GATE 6: the 5 districts vs the TIGER PLACE (not the county) ───────────
  //
  // 🔴 The load-bearing assertion here is PLACE COVERS CITY HALL. The city
  //    migration hangs the Mayor off place 1245000; if that polygon does not
  //    cover the anchor, the Mayor is unreachable from the wave's own probe
  //    address and nothing errors.
  //
  // 🔴 geo_id is paired with mtfcc, as everywhere in this slice.
  const placeRes = await pool.query(
    `WITH d AS (SELECT public.ST_Multi(public.ST_MakeValid(
                  public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326))) g
                  FROM unnest($1::text[]) AS gj),
          u AS (SELECT public.ST_UnaryUnion(public.ST_Collect(g)) g FROM d),
          pl AS (SELECT geometry g FROM essentials.geofence_boundaries
                  WHERE geo_id = $2 AND mtfcc = $5)
     SELECT (public.ST_Area(public.ST_Difference(pl.g, u.g)::geography) / $3)::numeric(12,4) AS uncovered,
            (public.ST_Area(public.ST_Difference(u.g, pl.g)::geography) / $3)::numeric(12,4) AS overhang,
            (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / $3), 0)::numeric(12,4)
               FROM d x JOIN d y ON public.ST_AsBinary(x.g) < public.ST_AsBinary(y.g)
              WHERE public.ST_Intersects(x.g, y.g)) AS self_overlap,
            public.ST_Covers(pl.g, public.ST_SetSRID(public.ST_Point($4, $6), 4326)) AS place_covers_anchor
       FROM u, pl`,
    [
      sorted.map(([, g]) => JSON.stringify(g)),
      PLACE_GEO_ID,
      SQ_M_PER_SQ_MI,
      CONTROL_POINTS[0].lon,
      PLACE_MTFCC,
      CONTROL_POINTS[0].lat,
    ],
  );
  if (!placeRes.rows.length) {
    console.error(
      `ERROR: TIGER place polygon ${PLACE_GEO_ID}/${PLACE_MTFCC} is not loaded. Refusing to write — ` +
        'the city migration hangs the Mayor off it.',
    );
    await pool.end();
    process.exit(1);
  }
  const p = placeRes.rows[0] as Record<string, string | boolean>;
  console.log(
    `\n  Vs TIGER place ${PLACE_GEO_ID} (Miami city): ${p.uncovered} sq mi uncovered, ` +
      `${p.overhang} overhang, ${p.self_overlap} self-overlap`,
  );
  console.log(
    `    ${p.place_covers_anchor === true ? 'PASS' : 'FAIL'}  place ${PLACE_GEO_ID} covers the anchor ` +
      '(Miami City Hall) — the Mayor hangs off this polygon',
  );

  const placeProblems: string[] = [];
  if (Number(p.uncovered) > PLACE_TOLERANCE_SQ_MI) {
    placeProblems.push(`uncovered ${p.uncovered} > ${PLACE_TOLERANCE_SQ_MI} (measured 0.4428)`);
  }
  if (Number(p.overhang) > PLACE_TOLERANCE_SQ_MI) {
    placeProblems.push(`overhang ${p.overhang} > ${PLACE_TOLERANCE_SQ_MI} (measured 0.3056)`);
  }
  if (Number(p.self_overlap) > SELF_OVERLAP_TOLERANCE_SQ_MI) {
    placeProblems.push(`self-overlap ${p.self_overlap} > ${SELF_OVERLAP_TOLERANCE_SQ_MI} (measured 0.0001)`);
  }
  if (p.place_covers_anchor !== true) {
    placeProblems.push(
      `place ${PLACE_GEO_ID} does NOT cover Miami City Hall — the Mayor would be unreachable ` +
        'from the wave\'s own probe address',
    );
  }
  if (placeProblems.length) {
    console.error(
      `\nERROR: the ${EXPECTED_COUNT} districts do not agree with TIGER place ${PLACE_GEO_ID}.\n` +
        placeProblems.map((x) => `  - ${x}`).join('\n') +
        '\n\nMeasured 2026-08-29: 0.4428 uncovered / 0.3056 overhang / 0.0001 self-overlap, and the ' +
        'place DOES cover City Hall. The 1.0 sq mi tolerance is there because two agencies\' city ' +
        'boundaries differ by annexation timing — it is NOT slack for a missing district: the ' +
        'smallest district is 4.377 sq mi.',
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
    const name = `Miami City Commission District ${dist}`;
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
