/**
 * load-milledgeville-council-boundaries.ts
 *
 * Fetches the 6 single-member City Council district boundaries for the City of
 * Milledgeville, GA and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='milledgeville-ga-council-district-1'..'-6',
 *                                   mtfcc='X0042', state='ga'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0027 creates the district
 * rows, the government, the chambers, the offices; CC_0028 the people. They
 * refuse to run if these 6 boundaries are absent.
 *
 * Wave GA-3 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md
 * Roster: backend/data/seed-milledgeville-2026/ROSTERS.md
 * Slice:  .planning/knight-foundation/ga.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE SERVICE THE CITY'S OWN WEBSITE LINKS TO IS THE SUPERSEDED ONE, AND
 *      ONLY ONE DISTRICT IN SIX SAYS SO.
 *
 * Two layers publish Milledgeville council districts:
 *
 *   City_Council_Districts__2025__WFL1   PRIMARY, and what this loader reads.
 *   /FeatureServer/0                     Owned by the CITY's ArcGIS org
 *                                        (Ug5xGQbHsD8zuZzM), titled "City Council
 *                                        Districts (2025)", web map modified
 *                                        2025-09-22. Carries Pop / DX_DEV /
 *                                        Pop_DVP and a full racial + VAP
 *                                        breakdown: it is a redistricting PLAN.
 *
 *   ElectionGeography_dashboard_…        🔴 THE SUPERSEDED COPY. Baldwin COUNTY's
 *   /FeatureServer/2, filtered            org (Da8HZMsU25Hzzob3). Its six city
 *   electedoffice='Local Elected          rows were last edited 2021-2022. It
 *   Representative'                       parses perfectly, tiles the TIGER place
 *                                         to 0.023 sq mi, and is what the city's
 *                                         own council page links to.
 *
 * Compared district by district at each polygon's own interior point,
 * measured 2026-09-01:
 *
 *   D1 -> 1   symdiff 0.9865 sq mi
 *   D2 -> 2   symdiff 0.3704
 *   D3 -> 3   symdiff 0.0909
 *   D4 -> 1   symdiff 0.7142   🔴 THE ONLY POINT THAT DISAGREES
 *   D5 -> 5   symdiff 0.4938
 *   D6 -> 6   symdiff 0.5759
 *
 * FIVE OF SIX AGREE. Spot-checking three districts — D2, D3 and D5, say — would
 * have passed on the wrong map and handed District 4's residents District 1's
 * council member, silently, with every cheaper gate green. The whole city is
 * ~20.4 sq mi, so D1's 0.99 sq mi disagreement is ~13% of that district.
 *
 * This is GA-1's ruling repeating at city scale: TEST EVERY DISTRICT WHEN THE
 * WHOLE MAP IS PUBLISHED. A remap leaves most districts untouched, so a handful
 * of anchors is not a vintage test.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 A LAYER TITLED "(2025)" CAN STILL CARRY A PRE-2025 ROSTER.
 *
 * The primary's CouncilMem field reads:
 *
 *   D1 Lee   D2 Walden   D3 Shinholster   D4 Reynolds   D5 Mapp   D6 Chambers
 *
 * Walden, Reynolds and Chambers all left at the November 2025 election. The
 * GEOMETRY is the current plan; the ATTRIBUTE predates the election that the
 * plan was drawn for. Geometry vintage and attribute vintage are different
 * questions about the same row, and the layer's title answers only the first.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER. This loader requests DIST_ID
 *   and the plan-integrity fields, and never CouncilMem.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ THE PLAN'S POPULATION UNIVERSE IS 14,796 — 86.7% OF THE 2020 CENSUS COUNT.
 *
 * Milledgeville was 17,070 in the 2020 census. The plan's six districts sum to
 * 14,796, a gap of 2,274. The gap is UNEXPLAINED. The likeliest cause is an
 * excluded institutional group-quarters population — the city hosts Central
 * State Hospital — and District 4 is 97.2% voting age, which is the signature of
 * the Georgia College campus rather than of a normal residential district.
 *
 * 🔴 THE GATE DELIBERATELY DOES NOT TEST THE ABSOLUTE TOTAL. Gating on a number
 *    whose universe is not understood would either reject a correct layer or,
 *    worse, get re-baselined onto a wrong one. GATE 1 tests what the layer
 *    asserts about ITSELF — that the parts sum to the whole and the districts
 *    balance — and the vintage is established by GATE 2 and GATE 6 without
 *    reference to any population figure.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 GATE ORDER IS LOAD-BEARING (the FL-6 rule).
 *
 * The discriminating gates run FIRST. GATE 5's failure message says "re-measure
 * and update EXPECTED_SQ_MI" — advice that, followed at the wrong moment,
 * re-baselines the loader onto a bad map and makes every other gate agree with
 * it. A gate that invites re-baselining must never be the first to fire.
 *
 * ⚠ GATE 2 hard-fails only when the two layers are IDENTICAL, which is the real
 *   danger (it means this loader fetched the county copy twice). It does NOT
 *   fail if Baldwin County one day syncs its copy — a gate must not break on
 *   good news.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ THIS IS A CITY, GATED AGAINST THE TIGER PLACE — NOT AGAINST THE COUNTY.
 *
 * Milledgeville is 20.420 sq mi inside a 268.276 sq mi county. A county-tiling
 * gate would be meaningless. Measured 2026-09-01 against TIGER place 1351492:
 * 0.0258 sq mi of the place uncovered, 0.1168 sq mi of plan beyond it. The
 * overhang is the larger side, which is what annexation timing looks like.
 *
 * 🔴 geo_id IS A SLUG, NOT A NUMBER. Georgia's geo_id collision is THREE-WAY —
 *    13009 is Baldwin County AND House District 9 AND Senate District 9, and all
 *    three rows are in production. A numeric scheme would dodge that by luck; a
 *    slug cannot collide at all. Matches X0036 (bradenton-fl-council-ward-N) and
 *    X0041 (miami-fl-commission-district-N).
 *
 * 🔴 outSR=4326 IS LOAD-BEARING, as in every loader in this slice.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const CITY_ORG = 'https://services1.arcgis.com/Ug5xGQbHsD8zuZzM/arcgis/rest/services';
const COUNTY_ORG = 'https://services7.arcgis.com/Da8HZMsU25Hzzob3/arcgis/rest/services';

/**
 * PRIMARY. The CITY's own redistricting plan. Web map "City of Milledgeville
 * City Council Districts" modified 2025-09-22; the Web Experience that fronts it
 * modified 2026-03-02.
 *
 * ⚠ CouncilMem is deliberately NOT requested — see the header.
 */
const PRIMARY_URL =
  `${CITY_ORG}/City_Council_Districts__2025__WFL1/FeatureServer/0/query` +
  '?where=1%3D1&outFields=DIST_ID,Pop,DX_DEV,Pop_DVP,White,Black,Other,Pop_VAP' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/**
 * 🔴 THE SUPERSEDED 2021-2022 COUNTY COPY, USED AS A NEGATIVE CONTROL. See
 * GATE 2. Its district number lives in `name` as the string 'City District N'.
 */
const SUPERSEDED_URL =
  `${COUNTY_ORG}/ElectionGeography_dashboard_e2083915d81d4dbb99831a31d3e97369/FeatureServer/2/query` +
  "?where=electedoffice%3D%27Local%20Elected%20Representative%27&outFields=name" +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0042';

/** ⚠ 'ga', not FIPS '13' — consistent with X0036..X0041 in this program. */
const STATE_CODE = 'ga';
const SOURCE = 'milledgeville-agol-City_Council_Districts_2025-0-2026-09-01';
const GEO_ID_PREFIX = 'milledgeville-ga-council-district-';

/** TIGER place "Milledgeville city". ⚠ Paired with mtfcc G4110 in every lookup. */
const PLACE_GEO_ID = '1351492';
const PLACE_MTFCC = 'G4110';

const EXPECTED_COUNT = 6;
const DISTRICTS = ['1', '2', '3', '4', '5', '6'] as const;
const DISTRICT_KEY_RE = /^[1-6]$/;

/** Measured 2026-09-01 from the reprojected 4326 geometry via ::geography. */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 7.4071,
  '2': 5.3299,
  '3': 2.8095,
  '4': 0.9231,
  '5': 1.2126,
  '6': 2.8293,
};

/**
 * Control points. The first two are real addresses and are the ones that matter;
 * the rest are each district's own guaranteed-interior point.
 *
 * ⚠ These prove correct KEYING, not correct vintage. GATE 1 and GATE 2 are what
 *   discriminate between maps — and D4's interior point is precisely where the
 *   superseded copy disagrees, so it is doing double duty here.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: string }> = [
  { name: 'Milledgeville City Hall (119 E Hancock St)', lon: -83.226730175561, lat: 33.081230307104, district: '2' },
  { name: 'Baldwin County Govt Building (1601 N Columbia St)', lon: -83.238, lat: 33.0995, district: '5' },
  { name: 'District 1 interior', lon: -83.306516, lat: 33.115625, district: '1' },
  { name: 'District 2 interior', lon: -83.219991, lat: 33.054189, district: '2' },
  { name: 'District 3 interior', lon: -83.220224, lat: 33.105645, district: '3' },
  { name: 'District 4 interior', lon: -83.257993, lat: 33.076199, district: '4' },
  { name: 'District 5 interior', lon: -83.237712, lat: 33.095616, district: '5' },
  { name: 'District 6 interior', lon: -83.250102, lat: 33.121502, district: '6' },
];

/**
 * 🔴 THE COUNTY IS THE CONTROL THIS WAVE MOST NEEDS.
 *
 * Milledgeville is a small city inside a large county, and the failure this
 * guards against is a city layer that has quietly become a COUNTY layer — which
 * would put a rural Baldwin resident inside a city council district and give
 * them a council member they cannot vote for. Baldwin is 268 sq mi against the
 * city's 20, so that mistake is 13x too big and still tiles something.
 *
 * Macon-Bibb and Columbus are the second direction: the other two Knight
 * jurisdictions in this slice, which must never resolve here.
 *
 * ⚠ Note the Baldwin County Government Building is INSIDE the city (District 5)
 *   and is therefore a control point above, not a negative control. The county
 *   seat's own HQ being in the city is exactly the trap this pair separates.
 *
 * 🔴 CORRECTED 2026-09-01 WHILE MEASURING TASK 2. The first version of this list
 *    carried (-83.12, 33.16) labelled "Rural Baldwin County". Resolved against
 *    TIGER G4020, that point is in HANCOCK COUNTY (13141), not Baldwin. The gate
 *    still passed, and passed for a true reason — the point is outside the city
 *    either way — but it was NOT testing what its label claimed, and so the one
 *    case that actually discriminates a city layer from a county layer, a point
 *    INSIDE Baldwin and OUTSIDE Milledgeville, was never tested at all.
 *    A mislabelled control is worse than a missing one: it reads as covered.
 *    Both points are now here, each verified against TIGER and each labelled
 *    with the county it is really in.
 */
const NEGATIVE_CONTROLS: Array<{ name: string; lon: number; lat: number }> = [
  // 🔴 THE DISCRIMINATING ONE: in Baldwin County (13009), in no TIGER place.
  { name: 'Rural Baldwin County, in the county but OUTSIDE the city', lon: -83.153077, lat: 33.067385 },
  { name: 'Hancock County (13141), adjacent', lon: -83.12, lat: 33.16 },
  { name: 'Macon-Bibb County (GA-4 jurisdiction)', lon: -83.6940595, lat: 32.8089903 },
  { name: 'Columbus city (GA-5 jurisdiction)', lon: -84.8749462, lat: 32.5101909 },
];

const AREA_TOLERANCE_PCT = 2;

/**
 * GATE 6, measured 2026-09-01: 0.0258 uncovered, 0.1168 beyond. The overhang is
 * the larger side, consistent with annexation the 2024 TIGER vintage has not
 * caught up with. 🔴 A TOLERANCE, NOT ST_Equals — two agencies never digitize one
 * boundary identically.
 */
const MAX_PLACE_UNCOVERED_SQ_MI = 0.15;
const MAX_BEYOND_PLACE_SQ_MI = 0.4;

/**
 * GATE 2. Total symmetric difference against the superseded copy, measured
 * 3.2317 sq mi across the six. Anything at or below this floor means the two
 * fetches returned the SAME layer, i.e. this loader is pointed at the county
 * copy twice.
 */
const MIN_TOTAL_SYMDIFF_SQ_MI = 0.01;

/** GATE 1. Worst measured deviation is D4 at +7.54%. */
const MAX_ABS_POP_DEVIATION_PCT = 10;

const DRY_RUN = process.argv.includes('--dry-run');

type Feature = { properties: Record<string, unknown>; geometry: unknown };

async function fetchLayer(url: string, label: string, keyOf: (p: Record<string, unknown>) => string | null) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${label}: HTTP ${res.status} ${res.statusText}`);
  const body = (await res.json()) as { features?: Feature[]; error?: unknown };
  if (body.error) throw new Error(`${label}: ArcGIS error ${JSON.stringify(body.error)}`);
  const feats = body.features ?? [];
  const out = new Map<string, Feature>();
  for (const f of feats) {
    const k = keyOf(f.properties ?? {});
    if (k === null || !DISTRICT_KEY_RE.test(k)) continue;
    if (out.has(k)) throw new Error(`${label}: duplicate district key ${k}`);
    if (!f.geometry) throw new Error(`${label}: district ${k} has no geometry`);
    out.set(k, f);
  }
  return { all: feats.length, keyed: out };
}

function fail(msg: string): never {
  console.error(`\nERROR: ${msg}`);
  process.exit(1);
}

async function main() {
  console.log('[load-milledgeville-council-boundaries] City of Milledgeville, GA — 6 council districts');
  console.log(`  Primary:    ${PRIMARY_URL.split('?')[0]}`);
  console.log(`  Superseded: ${SUPERSEDED_URL.split('?')[0]}`);
  console.log(`  Target:     mtfcc=${MTFCC} state=${STATE_CODE}${DRY_RUN ? '   [DRY RUN]' : ''}\n`);

  const primary = await fetchLayer(PRIMARY_URL, 'primary', (p) =>
    p.DIST_ID === undefined || p.DIST_ID === null ? null : String(p.DIST_ID),
  );
  console.log(`  Primary returned ${primary.all} features, ${primary.keyed.size} keyed 1..${EXPECTED_COUNT}`);

  if (primary.keyed.size !== EXPECTED_COUNT) {
    fail(`expected ${EXPECTED_COUNT} districts, got ${primary.keyed.size}.`);
  }
  const missing = DISTRICTS.filter((d) => !primary.keyed.has(d));
  if (missing.length) fail(`districts ${missing.join(', ')} are absent.`);

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  // ─── GATE 1: PLAN IDENTITY — the parts sum to the whole, and it balances ────
  // 🔴 This is the discriminator. The superseded county copy carries NONE of
  //    these fields, so a loader pointed at it dies here rather than at an area
  //    gate whose advice is "re-measure".
  console.log('\nGATE 1 — plan identity (the superseded copy has none of these fields)');
  let planTotal = 0;
  let worstDev = 0;
  for (const d of DISTRICTS) {
    const p = primary.keyed.get(d)!.properties;
    const need = ['Pop', 'DX_DEV', 'Pop_DVP', 'White', 'Black', 'Other', 'Pop_VAP'];
    for (const f of need) {
      if (typeof p[f] !== 'number') {
        fail(
          `district ${d} has no numeric '${f}'. This layer is not a redistricting plan — ` +
            `it is almost certainly Baldwin County's superseded copy.`,
        );
      }
    }
    const pop = p.Pop as number;
    const parts = (p.White as number) + (p.Black as number) + (p.Other as number);
    if (parts !== pop) {
      fail(`district ${d}: White+Black+Other = ${parts} but Pop = ${pop}. Parts do not sum to the whole.`);
    }
    const dev = Math.abs(p.Pop_DVP as number);
    if (dev > MAX_ABS_POP_DEVIATION_PCT) {
      fail(`district ${d} deviates ${(p.Pop_DVP as number).toFixed(2)}%, over the ${MAX_ABS_POP_DEVIATION_PCT}% limit.`);
    }
    worstDev = Math.max(worstDev, dev);
    planTotal += pop;
    console.log(
      `  D${d}: Pop ${String(pop).padStart(5)}  dev ${(p.Pop_DVP as number).toFixed(2).padStart(6)}%  ` +
        `VAP ${String(p.Pop_VAP).padStart(5)}  parts sum ✓`,
    );
  }
  console.log(`  Plan universe ${planTotal.toLocaleString()}, worst deviation ${worstDev.toFixed(2)}%`);
  console.log(
    `  ⚠ 2020 census city population is 17,070. The ${(17070 - planTotal).toLocaleString()} gap is ` +
      `UNEXPLAINED and deliberately not gated — see the header.`,
  );

  // ─── GATE 2: the superseded copy must not BE the primary ───────────────────
  console.log('\nGATE 2 — divergence from the superseded 2021-2022 county copy');
  const superseded = await fetchLayer(SUPERSEDED_URL, 'superseded', (p) => {
    const m = /(\d+)\s*$/.exec(String(p.name ?? ''));
    return m ? m[1] : null;
  });
  console.log(`  Superseded returned ${superseded.all} features, ${superseded.keyed.size} keyed`);
  if (superseded.keyed.size !== EXPECTED_COUNT) {
    fail(`the superseded copy has ${superseded.keyed.size} keyed districts, expected ${EXPECTED_COUNT}.`);
  }

  let totalSymDiff = 0;
  let pointDisagreements = 0;
  for (const d of DISTRICTS) {
    const a = JSON.stringify(primary.keyed.get(d)!.geometry);
    const b = JSON.stringify(superseded.keyed.get(d)!.geometry);
    const r = await pool.query(
      `WITH x AS (SELECT public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)) AS a,
                         public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($2),4326)) AS b)
       SELECT public.ST_Area(public.ST_SymDifference(a,b)::geography)/2589988.110336 AS symdiff,
              public.ST_Contains(b, public.ST_PointOnSurface(a)) AS same_at_our_point
         FROM x`,
      [a, b],
    );
    const { symdiff, same_at_our_point: same } = r.rows[0] as { symdiff: number; same_at_our_point: boolean };
    totalSymDiff += symdiff;
    if (!same) pointDisagreements++;
    console.log(
      `  D${d}: symdiff ${symdiff.toFixed(4)} sq mi   interior point ${same ? 'agrees' : '🔴 DISAGREES'}`,
    );
  }
  console.log(
    `  Total symmetric difference ${totalSymDiff.toFixed(4)} sq mi; ` +
      `${pointDisagreements} of ${EXPECTED_COUNT} interior points disagree`,
  );
  if (totalSymDiff < MIN_TOTAL_SYMDIFF_SQ_MI) {
    fail(
      `the two layers are IDENTICAL (${totalSymDiff.toFixed(6)} sq mi apart). This loader has fetched ` +
        `the same service twice — check PRIMARY_URL.`,
    );
  }
  if (pointDisagreements === 0) {
    console.log(
      '  ⚠ NOTE: every interior point now agrees. Measured 2026-09-01, District 4 disagreed. Either ' +
        'Baldwin County has synced its copy — good news, not an error — or the primary has changed. ' +
        'GATE 5 and GATE 6 decide which.',
    );
  }

  // ─── GATE 3: control points ────────────────────────────────────────────────
  console.log('\nGATE 3 — control points');
  for (const c of CONTROL_POINTS) {
    const hits: string[] = [];
    for (const d of DISTRICTS) {
      const r = await pool.query(
        `SELECT public.ST_Contains(
                  public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)),
                  public.ST_SetSRID(public.ST_MakePoint($2,$3),4326)) AS hit`,
        [JSON.stringify(primary.keyed.get(d)!.geometry), c.lon, c.lat],
      );
      if ((r.rows[0] as { hit: boolean }).hit) hits.push(d);
    }
    if (hits.length !== 1 || hits[0] !== c.district) {
      fail(`${c.name}: expected district ${c.district}, got [${hits.join(', ') || 'none'}].`);
    }
    console.log(`  ✓ ${c.name} -> District ${hits[0]}`);
  }

  // ─── GATE 4: negative controls ─────────────────────────────────────────────
  console.log('\nGATE 4 — negative controls (must match NO district)');
  for (const n of NEGATIVE_CONTROLS) {
    const hits: string[] = [];
    for (const d of DISTRICTS) {
      const r = await pool.query(
        `SELECT public.ST_Contains(
                  public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)),
                  public.ST_SetSRID(public.ST_MakePoint($2,$3),4326)) AS hit`,
        [JSON.stringify(primary.keyed.get(d)!.geometry), n.lon, n.lat],
      );
      if ((r.rows[0] as { hit: boolean }).hit) hits.push(d);
    }
    if (hits.length !== 0) {
      fail(`${n.name} fell inside district(s) [${hits.join(', ')}]. This layer is not the CITY's.`);
    }
    console.log(`  ✓ ${n.name} -> no district`);
  }

  // ─── GATE 5: per-district area ─────────────────────────────────────────────
  console.log(`\nGATE 5 — per-district area (±${AREA_TOLERANCE_PCT}% of the 2026-09-01 measurement)`);
  for (const d of DISTRICTS) {
    const r = await pool.query(
      `SELECT public.ST_Area(
                public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326))::geography
              )/2589988.110336 AS sq_mi`,
      [JSON.stringify(primary.keyed.get(d)!.geometry)],
    );
    const got = (r.rows[0] as { sq_mi: number }).sq_mi;
    const want = EXPECTED_SQ_MI[d];
    const driftPct = Math.abs((got - want) / want) * 100;
    if (driftPct > AREA_TOLERANCE_PCT) {
      fail(
        `district ${d} is ${got.toFixed(4)} sq mi, expected ${want} (${driftPct.toFixed(2)}% drift).\n` +
          `  If the city has adopted a NEW plan this is correct and EXPECTED_SQ_MI must be re-measured —\n` +
          `  but do that ONLY after GATE 1 and GATE 2 have passed, or you will re-baseline onto a bad map.`,
      );
    }
    console.log(`  ✓ D${d}: ${got.toFixed(4)} sq mi (${driftPct.toFixed(2)}% drift)`);
  }

  // ─── GATE 6: the 6 districts vs the TIGER PLACE (not the county) ───────────
  console.log(`\nGATE 6 — union vs TIGER place ${PLACE_GEO_ID} (${PLACE_MTFCC})`);
  const geoms = DISTRICTS.map((d) => JSON.stringify(primary.keyed.get(d)!.geometry));
  const u = await pool.query(
    `WITH parts AS (
       SELECT public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON(g),4326)) AS g
         FROM unnest($1::text[]) AS g
     ), u AS (SELECT public.ST_Union(g) AS g FROM parts),
       t AS (SELECT geometry AS g FROM essentials.geofence_boundaries
              WHERE geo_id = $2 AND mtfcc = $3)
     SELECT public.ST_Area(u.g::geography)/2589988.110336 AS union_sq_mi,
            public.ST_Area(t.g::geography)/2589988.110336 AS place_sq_mi,
            public.ST_Area(public.ST_Difference(t.g,u.g)::geography)/2589988.110336 AS uncovered,
            public.ST_Area(public.ST_Difference(u.g,t.g)::geography)/2589988.110336 AS beyond
       FROM u, t`,
    [geoms, PLACE_GEO_ID, PLACE_MTFCC],
  );
  if (u.rowCount === 0) {
    fail(`TIGER place ${PLACE_GEO_ID}/${PLACE_MTFCC} is not in essentials.geofence_boundaries. Run GA-1 first.`);
  }
  const { union_sq_mi: unionSqMi, place_sq_mi: placeSqMi, uncovered, beyond } = u.rows[0] as Record<string, number>;
  console.log(`  TIGER place ${placeSqMi.toFixed(4)} sq mi, districts union ${unionSqMi.toFixed(4)} sq mi`);
  console.log(`  place uncovered ${uncovered.toFixed(4)}, beyond place ${beyond.toFixed(4)}`);
  if (uncovered > MAX_PLACE_UNCOVERED_SQ_MI || beyond > MAX_BEYOND_PLACE_SQ_MI) {
    fail(
      `the ${EXPECTED_COUNT} districts do not agree with TIGER place ${PLACE_GEO_ID}: ` +
        `${uncovered.toFixed(4)} uncovered (max ${MAX_PLACE_UNCOVERED_SQ_MI}), ` +
        `${beyond.toFixed(4)} beyond (max ${MAX_BEYOND_PLACE_SQ_MI}).`,
    );
  }

  // ─── GATE 7: the slot is free ──────────────────────────────────────────────
  console.log(`\nGATE 7 — ${MTFCC} is unclaimed`);
  const claimed = await pool.query(
    `SELECT count(*)::int AS n, min(geo_id) AS example
       FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
    [MTFCC],
  );
  const { n: claimedN, example } = claimed.rows[0] as { n: number; example: string | null };
  if (claimedN > 0) {
    const ours = await pool.query(
      `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
        WHERE mtfcc = $1 AND geo_id LIKE $2`,
      [MTFCC, `${GEO_ID_PREFIX}%`],
    );
    if ((ours.rows[0] as { n: number }).n !== claimedN) {
      fail(`${MTFCC} already holds ${claimedN} rows that are not ours (e.g. ${example}). Take the next code.`);
    }
    console.log(`  ${MTFCC} holds ${claimedN} rows, all ours — this is a re-run`);
  } else {
    console.log(`  ✓ ${MTFCC} is unclaimed`);
  }

  console.log('\nAll gates passed.');

  if (DRY_RUN) {
    console.log('DRY-RUN complete — no database writes made.');
    await pool.end();
    process.exit(0);
  }

  // ─── Write ─────────────────────────────────────────────────────────────────
  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;
  for (const d of DISTRICTS) {
    const geoId = `${GEO_ID_PREFIX}${d}`;
    const name = `Milledgeville City Council District ${d}`;
    const geomStr = JSON.stringify(primary.keyed.get(d)!.geometry);
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
      console.log(`  District ${d} (${geoId}): skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    if (row.valid !== true) {
      console.error(`  District ${d} (${geoId}): ST_IsValid=false — applying ST_MakeValid`);
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
        console.error(`  ERROR: District ${d} still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  District ${d} (${geoId}): repaired via ST_MakeValid`);
    } else {
      console.log(`  District ${d} (${geoId}): inserted (${row.gtype}, valid)`);
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
            COUNT(*) FILTER (WHERE public.ST_SRID(geometry) <> 4326)::int AS wrong_srid,
            COUNT(*) FILTER (WHERE state <> '${STATE_CODE}')::int AS wrong_state
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const {
    n,
    invalid,
    wrong_srid: wrongSrid,
    wrong_state: wrongState,
  } = check.rows[0] as { n: number; invalid: number; wrong_srid: number; wrong_state: number };
  console.log(`  In DB now:       ${n} rows (${invalid} invalid, ${wrongSrid} wrong SRID, ${wrongState} wrong state)`);

  await pool.end();
  if (n !== EXPECTED_COUNT || invalid !== 0 || wrongSrid !== 0 || wrongState !== 0) {
    console.error(
      `ERROR: expected ${EXPECTED_COUNT} valid rows in SRID 4326 and state '${STATE_CODE}', got ${n} ` +
        `with ${invalid} invalid, ${wrongSrid} in the wrong SRID and ${wrongState} in the wrong state.`,
    );
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
