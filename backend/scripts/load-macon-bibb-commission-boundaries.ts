/**
 * load-macon-bibb-commission-boundaries.ts
 *
 * Fetches the 9 single-member Commission district boundaries for Macon-Bibb
 * County, GA (Macon-Bibb County consolidated government) and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='macon-bibb-ga-commission-district-1'..'-9',
 *                                   mtfcc='X0045', state='ga'
 *
 * Writes ONLY to essentials.geofence_boundaries. The GA-5 structure migration
 * creates the district rows, the government, the chambers and the offices; the
 * occupancy migration the people. They refuse to run if these 9 are absent.
 *
 * Wave GA-5 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Roster: backend/data/seed-macon-bibb-2026/ROSTERS.md
 * Slice:  .planning/knight-foundation/ga.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 FIVE LAYERS PUBLISH THESE DISTRICTS. FOUR ARE THE SAME MAP. ONE IS NOT —
 *      AND THE ODD ONE OUT IS LISTED *FIRST* IN THE COUNTY'S OWN WEB MAP.
 *
 * Measured 2026-09-01, per-district symmetric difference against the primary,
 * in sq mi, after ST_MakeValid:
 *
 *                                            D1..D9        total
 *   2022_Bibb_County_Commission_Redistricted  0.0000       0.0000   ← ARBITER
 *   County_Commissioners_2020                 0.0000       0.0000
 *   County_Commission                         0.0000       0.0000
 *   ElectoralDistricts/3 (Board of Elections) ~0.01 each   0.0914
 *   CountyDistrict                            2.8 – 33.7 145.7215   ← SUPERSEDED
 *
 * ⚠ THE SERVICE NAMES ARE BACKWARDS. `County_Commissioners_2020` sounds stale
 *   and is CURRENT — its *layer* is named "County Commissioners 2024" and its
 *   description says "based off the 2020 census", i.e. the post-2022 plan.
 *   `CountyDistrict` sounds current and generic, and is the OLD plan: its union
 *   is 255.3656 sq mi (0.46 too large) and it misses the county by 1.1846.
 *
 * ⚠ GA-4 (Columbus) found two layers that INVERT — the one with the fresh roster
 *   carried the superseded geometry. MACON-BIBB DOES NOT INVERT. That is a
 *   measurement, not an inheritance: geometry vintage and attribute vintage were
 *   tested separately here precisely because Columbus proved they can disagree.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THERE IS NO `Elections Combinations` TABLE IN BIBB. THE ARBITER IS THE
 *    ADOPTED PLAN, AND THE PRIMARY IS WHAT THE COUNTY SHOWS VOTERS.
 *
 * GA-4's arbiter was the county's precinct × district ballot-building table.
 * Bibb publishes no such layer. Two things replaced it:
 *
 *   PRIMARY  Hosted/CountyCommissioners2024 on maconbibb.spatialitics.net —
 *            a DIFFERENT PORTAL from the county's ArcGIS Online org. Found by
 *            reading the iframe on maconbibb.us/commissioners/: this is the
 *            service the county's own "Find Your Commissioner" widget queries,
 *            so it is what the county tells voters their district is.
 *
 *   ARBITER  2022_Bibb_County_Commission_Redistricted — the adopted redistricting
 *            plan as drawn, carrying per-district population deviations and an
 *            ideal value of 17,483 (× 9 = 157,347, Bibb's 2020 population). It is
 *            the plan of record and it is independent of the county's operational
 *            GIS, which is what makes it a real arbiter rather than a second copy.
 *
 * ▶ WHEN THERE IS NO BALLOT-BUILDING TABLE, ASK WHAT THE JURISDICTION'S OWN
 *   LOOKUP TOOL QUERIES — then arbitrate it against the adopted plan.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER. This loader requests the
 *   district number and nothing else, even though the primary happens to carry
 *   the only current roster in Bibb. The roster comes from the county's
 *   commissioners page and the press — see ROSTERS.md.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE COLUMBUS COVERAGE GATE INVERTS HERE, AND GETTING IT BACKWARDS WOULD
 *      PASS ON A MAP THAT HAD LOST A DISTRICT.
 *
 * Columbus: 8 districts covering 146.24 of the county's 221.011 sq mi, leaving
 * 74.79 sq mi (Fort Benning) in NO council district — correctly — so GA-4's
 * instruction was "gate the STRUCTURE, not full coverage".
 *
 * Macon-Bibb: the 9 districts TILE THE WHOLE COUNTY. Measured 2026-09-01:
 *
 *     union of the 9      254.9060 sq mi
 *     Bibb County 13021   254.9059 sq mi
 *     county not covered    0.0139 sq mi
 *     beyond the county     0.0140 sq mi
 *
 * So GATE 6 asserts FULL COVERAGE. A structure-only gate would pass on a map
 * that had silently dropped a district.
 *
 * 🔴 Charter Sec. 9(a) excludes "the city limits of the City of Payne City" from
 *    the districting plan. Payne City was a municipality inside Bibb, and if it
 *    still existed these districts would NOT tile the county. It dissolved into
 *    the consolidated government and appears nowhere in the TIGER 2024 place
 *    file — and the 0.0139 sq mi above PROVES that rather than assuming it,
 *    because Payne City's footprint is far larger than the residual.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 GATE ORDER IS LOAD-BEARING (the FL-6 rule, restated by GA-3 and GA-4).
 *
 * GATE 1 is the discriminator and runs first. GATE 5's failure message invites
 * re-measuring EXPECTED_SQ_MI, which — followed at the wrong moment — would
 * re-baseline this loader onto the wrong map and make every later gate agree
 * with it. A gate that invites re-baselining must never fire first.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 EVERY NEGATIVE CONTROL'S COUNTY IS ASSERTED, NOT LABELLED (the GA-3 Hancock
 *    defect turned into code). All six verified 2026-09-01.
 *
 * ⚠ Because the districts tile the county, NO point inside Bibb can serve as a
 *   negative control — unlike Columbus, where the Fort Benning gap was available
 *   and was the discriminating one. Every control here is therefore OUTSIDE the
 *   county, and the discriminating one is MACON COUNTY 13193.
 *
 * 🔴 "MACON COUNTY" IS NOT MACON'S COUNTY. Production holds both 13021 Bibb
 *    County (which contains the city of Macon) and 13193 Macon County, a rural
 *    county ~60 miles away. A name-based lookup for Macon's parent county
 *    returns the wrong row, so 13193 is carried here as a standing control.
 *
 * 🔴 geo_id IS A SLUG, NOT A NUMBER. Georgia's geo_id collision is THREE-WAY:
 *    13021 is Bibb County AND State House District 21 AND State Senate District
 *    21 — which was hit live while measuring this wave. A slug cannot collide.
 *    Matches X0042/X0043 (Milledgeville, Baldwin) and X0044 (Columbus).
 *
 * 🔴 outSR=4326 IS LOAD-BEARING, as in every loader in this slice.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const AGOL = 'https://services2.arcgis.com/zPFLSOZ5HzUzzTQb/arcgis/rest/services';
const PORTAL = 'https://maconbibb.spatialitics.net/server/rest/services/Hosted';

/**
 * PRIMARY — the service behind the county's own "Find Your Commissioner" widget.
 * ⚠ repname1/name2/photo/email are deliberately NOT requested. See the header.
 */
const PRIMARY_URL =
  `${PORTAL}/CountyCommissioners2024/FeatureServer/0/query?where=1%3D1&outFields=commdist` +
  '&returnGeometry=true&outSR=4326&f=geojson';

/** THE ARBITER — the adopted 2022 redistricting plan as drawn. */
const ARBITER_URL =
  `${AGOL}/2022_Bibb_County_Commission_Redistricted/FeatureServer/0/query?where=1%3D1` +
  '&outFields=DISTRICT_N&returnGeometry=true&outSR=4326&f=geojson';

/** 🔴 THE SUPERSEDED COPY. Negative control for GATE 2 only. */
const SUPERSEDED_URL =
  `${AGOL}/CountyDistrict/FeatureServer/0/query?where=1%3D1&outFields=CommDist` +
  '&returnGeometry=true&outSR=4326&f=geojson';

const MTFCC = 'X0045';
const STATE_CODE = 'ga';
const SOURCE = 'macon-bibb-spatialitics-CountyCommissioners2024-2026-09-01';
const GEO_ID_PREFIX = 'macon-bibb-ga-commission-district-';

/** TIGER. ⚠ Always paired with its mtfcc — Georgia's collision is three-way. */
const PLACE_GEO_ID = '1349008';
const PLACE_MTFCC = 'G4110';
const COUNTY_GEO_ID = '13021';
const COUNTY_MTFCC = 'G4020';

const EXPECTED_COUNT = 9;
const DISTRICTS = ['1', '2', '3', '4', '5', '6', '7', '8', '9'] as const;
const DISTRICT_KEY_RE = /^[1-9]$/;

/** Measured 2026-09-01 from the reprojected 4326 geometry via ::geography. */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 15.3954,
  '2': 19.4188,
  '3': 43.1113,
  '4': 28.9611,
  '5': 7.9834,
  '6': 59.6832,
  '7': 54.1395,
  '8': 15.0121,
  '9': 11.2011,
};

/**
 * Each district's own guaranteed-interior point (ST_PointOnSurface), measured
 * 2026-09-01. ⚠ These prove correct KEYING, not correct vintage — GATE 1 is what
 * establishes vintage. No street address is used: geocoding one would mean
 * inventing a coordinate, and the address probe belongs to the acceptance step
 * after the migrations, where it can be resolved properly.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: string }> = [
  { name: 'District 1 interior', lon: -83.735018, lat: 32.915999, district: '1' },
  { name: 'District 2 interior', lon: -83.634220, lat: 32.838874, district: '2' },
  { name: 'District 3 interior', lon: -83.547493, lat: 32.813022, district: '3' },
  { name: 'District 4 interior', lon: -83.725544, lat: 32.873258, district: '4' },
  { name: 'District 5 interior', lon: -83.664662, lat: 32.853065, district: '5' },
  { name: 'District 6 interior', lon: -83.811522, lat: 32.800209, district: '6' },
  { name: 'District 7 interior', lon: -83.666446, lat: 32.735820, district: '7' },
  { name: 'District 8 interior', lon: -83.686064, lat: 32.795052, district: '8' },
  { name: 'District 9 interior', lon: -83.706617, lat: 32.823133, district: '9' },
];

/**
 * 🔴 Each carries the county it must resolve to, and GATE 4 asserts it against
 *    TIGER. All six verified 2026-09-01. Every one is OUTSIDE Bibb, because the
 *    nine districts tile the county and no interior negative control exists.
 */
const NEGATIVE_CONTROLS: Array<{ name: string; lon: number; lat: number; county: string }> = [
  // 🔴 THE DISCRIMINATING ONE. "Macon County" is a DIFFERENT, rural county ~60
  //    miles from the city of Macon. Any loader that resolved Macon's parent
  //    county by NAME would have built this wave on 13193.
  { name: 'Macon County 13193 — the homonym, NOT Macon\'s county', lon: -84.045, lat: 32.358, county: '13193' },
  { name: 'Jones County, adjacent north', lon: -83.5605, lat: 33.025, county: '13169' },
  { name: 'Houston County, adjacent south', lon: -83.63, lat: 32.46, county: '13153' },
  { name: 'Monroe County, adjacent north-west', lon: -83.92, lat: 33.03, county: '13207' },
  { name: 'Milledgeville / Baldwin (GA-3 jurisdiction)', lon: -83.240614, lat: 33.087945, county: '13009' },
  { name: 'Columbus / Muscogee (GA-4 jurisdiction)', lon: -84.874946, lat: 32.510191, county: '13215' },
];

const AREA_TOLERANCE_PCT = 2;

/** GATE 1. The adopted plan and the primary measured 0.0000 on all nine. */
const MAX_ARBITER_SYMDIFF_SQ_MI = 0.01;

/**
 * GATE 2. Total symmetric difference against CountyDistrict measured 145.7215
 * sq mi across the nine. At or below this floor the two fetches returned the
 * SAME layer, i.e. this loader is pointed at one URL twice.
 * ⚠ It does NOT fail if Bibb one day syncs CountyDistrict to the operative map —
 *   a gate must not break on good news.
 */
const MIN_TOTAL_SYMDIFF_SQ_MI = 0.01;

/**
 * GATE 6 — 🔴 FULL COVERAGE, the inverse of Columbus. Measured 2026-09-01:
 * union 254.9060, county 254.9059, uncovered 0.0139, beyond 0.0140.
 */
const EXPECTED_UNION_SQ_MI = 254.906;
const UNION_TOLERANCE_SQ_MI = 1.5;
const MAX_COUNTY_UNCOVERED_SQ_MI = 0.5;
const MAX_BEYOND_COUNTY_SQ_MI = 0.5;

const DRY_RUN = process.argv.includes('--dry-run');

type Feature = { properties: Record<string, unknown>; geometry: unknown };

async function fetchLayer(
  url: string,
  label: string,
  keyOf: (p: Record<string, unknown>) => string | null,
  opts: { allowDuplicateKeys?: boolean } = {},
) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${label}: HTTP ${res.status} ${res.statusText}`);
  const body = (await res.json()) as { features?: Feature[]; error?: unknown };
  if (body.error) throw new Error(`${label}: ArcGIS error ${JSON.stringify(body.error)}`);
  const feats = body.features ?? [];
  const out = new Map<string, Feature[]>();
  for (const f of feats) {
    const k = keyOf(f.properties ?? {});
    if (k === null || !DISTRICT_KEY_RE.test(k)) continue;
    if (!f.geometry) throw new Error(`${label}: district ${k} has a row with no geometry`);
    const bucket = out.get(k);
    if (bucket) {
      if (!opts.allowDuplicateKeys) throw new Error(`${label}: duplicate district key ${k}`);
      bucket.push(f);
    } else {
      out.set(k, [f]);
    }
  }
  return { all: feats.length, keyed: out };
}

/**
 * Reads a district number out of whichever field the layer uses, stripping
 * ArcGIS's zero padding ('003' -> '3').
 * ⚠ The arbiter carries a tenth feature keyed 0 / 'Unassigned'. It is dropped
 *   here by DISTRICT_KEY_RE, and GATE 1's count check is what proves the drop
 *   removed exactly one row and not a real district.
 */
const distId =
  (...fields: string[]) =>
  (p: Record<string, unknown>): string | null => {
    for (const f of fields) {
      const raw = p[f];
      if (raw === undefined || raw === null) continue;
      const s = String(raw).trim().replace(/^0+/, '');
      if (s !== '') return s;
    }
    return null;
  };

function fail(msg: string): never {
  console.error(`\nERROR: ${msg}`);
  process.exit(1);
}

const SQM_PER_SQMI = 2589988.110336;

async function main() {
  console.log('[load-macon-bibb-commission-boundaries] Macon-Bibb County, GA — 9 commission districts');
  console.log(`  Primary:    ${PORTAL}/CountyCommissioners2024   (the county's own voter-facing service)`);
  console.log(`  Arbiter:    ${AGOL}/2022_Bibb_County_Commission_Redistricted   (the adopted plan)`);
  console.log(`  Superseded: ${AGOL}/CountyDistrict   (WRONG geometry, stale roster)`);
  console.log(`  Target:     mtfcc=${MTFCC} state=${STATE_CODE}${DRY_RUN ? '   [DRY RUN]' : ''}\n`);
  console.log('  ⚠ Macon-Bibb has NO at-large seats. 9 polygons is the whole body bar the Mayor.\n');

  const primary = await fetchLayer(PRIMARY_URL, 'primary (CountyCommissioners2024)', distId('commdist', 'districtid'));
  console.log(`  Primary returned ${primary.all} features, ${primary.keyed.size} keyed 1..${EXPECTED_COUNT}`);
  if (primary.keyed.size !== EXPECTED_COUNT) {
    fail(`expected ${EXPECTED_COUNT} districts, got ${primary.keyed.size}.`);
  }
  const missing = DISTRICTS.filter((d) => !primary.keyed.has(d));
  if (missing.length) fail(`districts ${missing.join(', ')} are absent.`);
  for (const d of DISTRICTS) {
    if (primary.keyed.get(d)!.length !== 1) {
      fail(`district ${d} returned ${primary.keyed.get(d)!.length} rows, expected 1.`);
    }
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const geomOf = (d: string) => JSON.stringify(primary.keyed.get(d)![0].geometry);

  // Stage every layer once, in one session, so every gate compares the same bytes.
  await pool.query('CREATE TEMP TABLE IF NOT EXISTS _mbc(src text, did text, geom geometry)');
  await pool.query('TRUNCATE _mbc');
  const stage = async (src: string, did: string, geojson: string) =>
    pool.query(
      `INSERT INTO _mbc VALUES ($1, $2,
         public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)))`,
      [src, did, geojson],
    );
  for (const d of DISTRICTS) await stage('primary', d, geomOf(d));

  const arbiter = await fetchLayer(ARBITER_URL, 'arbiter (adopted 2022 plan)', distId('DISTRICT_N', 'DISTRICT'));
  console.log(`  Arbiter returned ${arbiter.all} features, ${arbiter.keyed.size} keyed 1..${EXPECTED_COUNT}`);
  if (arbiter.keyed.size !== EXPECTED_COUNT) {
    fail(
      `the adopted plan keys to ${arbiter.keyed.size} districts, expected ${EXPECTED_COUNT}. ` +
        `⚠ It carries an extra 'Unassigned' feature keyed 0, which is dropped on purpose — ` +
        `this count is what proves only that one was dropped.`,
    );
  }
  for (const d of DISTRICTS) await stage('arbiter', d, JSON.stringify(arbiter.keyed.get(d)![0].geometry));

  // ─── GATE 1: THE ADOPTED PLAN — the discriminator, and it runs first ───────
  console.log('\nGATE 1 — per-district agreement with the ADOPTED 2022 redistricting plan');
  {
    const r = await pool.query<{ did: string; symdiff: string }>(
      `SELECT p.did,
              round((public.ST_Area(public.ST_SymDifference(p.g, a.g)::geography)/${SQM_PER_SQMI})::numeric, 4) AS symdiff
         FROM (SELECT did, public.ST_Union(geom) g FROM _mbc WHERE src='primary' GROUP BY did) p
         JOIN (SELECT did, public.ST_Union(geom) g FROM _mbc WHERE src='arbiter' GROUP BY did) a
           ON a.did = p.did
        ORDER BY p.did::int`,
    );
    if (r.rowCount !== EXPECTED_COUNT) fail(`GATE 1 compared ${r.rowCount} districts, expected ${EXPECTED_COUNT}.`);
    let worst = 0;
    for (const row of r.rows) {
      const v = Number(row.symdiff);
      worst = Math.max(worst, v);
      console.log(`  D${row.did}: symdiff ${v.toFixed(4)} sq mi`);
    }
    if (worst > MAX_ARBITER_SYMDIFF_SQ_MI) {
      fail(
        `GATE 1: worst symdiff ${worst.toFixed(4)} sq mi exceeds ${MAX_ARBITER_SYMDIFF_SQ_MI}. ` +
          `The service the county shows voters is NOT the plan the county adopted. ` +
          `Do NOT re-baseline the area constants — find out which one moved.`,
      );
    }
    console.log(`  ✓ worst ${worst.toFixed(4)} sq mi — the voter-facing map IS the adopted plan`);
  }

  // ─── GATE 2: the superseded copy must not BE the primary ───────────────────
  console.log('\nGATE 2 — divergence from the superseded CountyDistrict layer');
  {
    const superseded = await fetchLayer(SUPERSEDED_URL, 'superseded (CountyDistrict)', distId('CommDist', 'DISTRICTID'));
    console.log(`  Superseded returned ${superseded.all} features, ${superseded.keyed.size} keyed`);
    for (const d of DISTRICTS) {
      const f = superseded.keyed.get(d);
      if (f) await stage('superseded', d, JSON.stringify(f[0].geometry));
    }
    const r = await pool.query<{ total: string }>(
      `SELECT round(sum(public.ST_Area(public.ST_SymDifference(p.g, s.g)::geography)/${SQM_PER_SQMI})::numeric, 4) AS total
         FROM (SELECT did, public.ST_Union(geom) g FROM _mbc WHERE src='primary' GROUP BY did) p
         JOIN (SELECT did, public.ST_Union(geom) g FROM _mbc WHERE src='superseded' GROUP BY did) s
           ON s.did = p.did`,
    );
    const total = Number(r.rows[0]?.total ?? 0);
    if (total <= MIN_TOTAL_SYMDIFF_SQ_MI) {
      fail(
        `GATE 2: the primary and CountyDistrict differ by only ${total.toFixed(4)} sq mi. Either this ` +
          `loader fetched the same URL twice, or Bibb has synced them — check by hand before trusting either.`,
      );
    }
    console.log(`  ✓ ${total.toFixed(4)} sq mi total divergence — they are genuinely different maps`);
  }

  // ─── GATE 3: control points ────────────────────────────────────────────────
  console.log("\nGATE 3 — control points (each district's own interior point)");
  for (const c of CONTROL_POINTS) {
    const r = await pool.query<{ did: string }>(
      `SELECT did FROM (SELECT did, public.ST_Union(geom) g FROM _mbc WHERE src='primary' GROUP BY did) p
        WHERE public.ST_Covers(p.g, public.ST_SetSRID(public.ST_MakePoint($1,$2),4326))`,
      [c.lon, c.lat],
    );
    const got = r.rows.map((x) => x.did);
    if (got.length !== 1 || got[0] !== c.district) {
      fail(`GATE 3: ${c.name} resolved to [${got.join(', ') || 'nothing'}], expected exactly District ${c.district}.`);
    }
    console.log(`  ✓ ${c.name} → District ${got[0]}`);
  }

  // ─── GATE 4: negative controls, with their county ASSERTED not labelled ────
  console.log('\nGATE 4 — negative controls (must match NO commission district, and be where the label says)');
  for (const c of NEGATIVE_CONTROLS) {
    const county = await pool.query<{ geo_id: string; name: string }>(
      `SELECT geo_id, name FROM essentials.geofence_boundaries
        WHERE mtfcc=$1 AND state='13'
          AND public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint($2,$3),4326))`,
      [COUNTY_MTFCC, c.lon, c.lat],
    );
    const landedIn = county.rows[0]?.geo_id ?? null;
    if (landedIn !== c.county) {
      fail(
        `GATE 4: "${c.name}" claims county ${c.county} but TIGER puts it in ${landedIn ?? 'no county'}. ` +
          `A mislabelled control reads as covered — fix the point or the label (the GA-3 Hancock defect).`,
      );
    }
    const hit = await pool.query<{ did: string }>(
      `SELECT did FROM (SELECT did, public.ST_Union(geom) g FROM _mbc WHERE src='primary' GROUP BY did) p
        WHERE public.ST_Covers(p.g, public.ST_SetSRID(public.ST_MakePoint($1,$2),4326))`,
      [c.lon, c.lat],
    );
    if (hit.rowCount !== 0) {
      fail(`GATE 4: ${c.name} matched District ${hit.rows.map((x) => x.did).join(', ')} — it must match none.`);
    }
    console.log(`  ✓ ${c.name} → no district (county ${landedIn} confirmed)`);
  }

  // ─── GATE 5: per-district area ─────────────────────────────────────────────
  console.log(`\nGATE 5 — per-district area (±${AREA_TOLERANCE_PCT}% of the 2026-09-01 measurement)`);
  {
    const r = await pool.query<{ did: string; sq_mi: string }>(
      `SELECT did, round((public.ST_Area(public.ST_Union(geom)::geography)/${SQM_PER_SQMI})::numeric, 4) AS sq_mi
         FROM _mbc WHERE src='primary' GROUP BY did ORDER BY did::int`,
    );
    for (const row of r.rows) {
      const got = Number(row.sq_mi);
      const want = EXPECTED_SQ_MI[row.did];
      const devPct = Math.abs((got - want) / want) * 100;
      if (devPct > AREA_TOLERANCE_PCT) {
        fail(
          `GATE 5: District ${row.did} is ${got} sq mi, expected ~${want} (${devPct.toFixed(2)}% off). ` +
            `⚠ GATE 1 passed, so the map is right — re-measure and update EXPECTED_SQ_MI only after ` +
            `confirming GATE 1 is still green.`,
        );
      }
      console.log(`  ✓ D${row.did}: ${got.toFixed(4)} sq mi (${devPct.toFixed(2)}% from expected)`);
    }
  }

  // ─── GATE 6: 🔴 FULL COVERAGE — the inverse of the Columbus gate ───────────
  console.log('\nGATE 6 — FULL COVERAGE of Bibb County (🔴 the inverse of the Columbus/Fort Benning gate)');
  {
    const r = await pool.query<{
      union_sq_mi: string; county_sq_mi: string; uncovered: string; beyond: string; overlaps: string;
    }>(
      `WITH u AS (SELECT public.ST_Union(geom) g FROM _mbc WHERE src='primary'),
            c AS (SELECT public.ST_MakeValid(geometry) g FROM essentials.geofence_boundaries
                   WHERE geo_id=$1 AND mtfcc=$2)
       SELECT round((public.ST_Area(u.g::geography)/${SQM_PER_SQMI})::numeric,4) AS union_sq_mi,
              round((public.ST_Area(c.g::geography)/${SQM_PER_SQMI})::numeric,4) AS county_sq_mi,
              round((public.ST_Area(public.ST_Difference(c.g, u.g)::geography)/${SQM_PER_SQMI})::numeric,4) AS uncovered,
              round((public.ST_Area(public.ST_Difference(u.g, c.g)::geography)/${SQM_PER_SQMI})::numeric,4) AS beyond,
              (SELECT count(*) FROM _mbc a JOIN _mbc b
                 ON a.src='primary' AND b.src='primary' AND a.did < b.did
                WHERE public.ST_Area(public.ST_Intersection(a.geom,b.geom)::geography)/${SQM_PER_SQMI} > 0.001
              )::text AS overlaps
         FROM u, c`,
      [COUNTY_GEO_ID, COUNTY_MTFCC],
    );
    const g = r.rows[0];
    if (!g) fail(`GATE 6: county ${COUNTY_GEO_ID}/${COUNTY_MTFCC} is not in geofence_boundaries.`);
    const unionSqMi = Number(g.union_sq_mi);
    console.log(`  Union of the 9:        ${unionSqMi.toFixed(4)} sq mi (expected ~${EXPECTED_UNION_SQ_MI})`);
    console.log(`  Bibb County:           ${Number(g.county_sq_mi).toFixed(4)} sq mi`);
    console.log(`  County NOT covered:    ${Number(g.uncovered).toFixed(4)} sq mi`);
    console.log(`  Beyond the county:     ${Number(g.beyond).toFixed(4)} sq mi`);
    console.log(`  District overlaps:     ${g.overlaps}`);

    if (Math.abs(unionSqMi - EXPECTED_UNION_SQ_MI) > UNION_TOLERANCE_SQ_MI) {
      fail(`GATE 6: union ${unionSqMi} sq mi is more than ${UNION_TOLERANCE_SQ_MI} from the expected ${EXPECTED_UNION_SQ_MI}.`);
    }
    if (Number(g.uncovered) > MAX_COUNTY_UNCOVERED_SQ_MI) {
      fail(
        `GATE 6: ${g.uncovered} sq mi of Bibb County is in NO commission district. ` +
          `⚠ In Macon-Bibb the nine districts tile the whole county — this is NOT the Columbus/Fort ` +
          `Benning case, and a hole here means a district is missing or a boundary moved. ` +
          `(Charter Sec. 9(a) carved out the City of Payne City, which dissolved; its footprint is far ` +
          `larger than this tolerance, so a revived carve-out would fail here too.)`,
      );
    }
    if (Number(g.beyond) > MAX_BEYOND_COUNTY_SQ_MI) {
      fail(`GATE 6: ${g.beyond} sq mi of the districts falls OUTSIDE Bibb County.`);
    }
    if (Number(g.overlaps) !== 0) fail(`GATE 6: ${g.overlaps} district pair(s) overlap by more than 0.001 sq mi.`);
    console.log('  ✓ 9 districts, no overlaps, and they tile the county');
  }

  // ─── GATE 7: the slot is free ──────────────────────────────────────────────
  console.log(`\nGATE 7 — ${MTFCC} is unclaimed`);
  {
    const claimed = await pool.query<{ n: number; example: string | null }>(
      `SELECT count(*)::int AS n, min(geo_id) AS example
         FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
      [MTFCC],
    );
    const { n: claimedN, example } = claimed.rows[0]!;
    if (claimedN > 0) {
      const ours = await pool.query<{ n: number }>(
        `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
          WHERE mtfcc = $1 AND geo_id LIKE $2`,
        [MTFCC, `${GEO_ID_PREFIX}%`],
      );
      if (ours.rows[0]!.n !== claimedN) {
        fail(`${MTFCC} already holds ${claimedN} rows that are not ours (e.g. ${example}). Take the next code.`);
      }
      console.log(`  ${MTFCC} holds ${claimedN} rows, all ours — this is a re-run`);
    } else {
      console.log(`  ✓ ${MTFCC} is unclaimed`);
    }
  }

  // Also confirm the TIGER place exists — the structure migration hangs the
  // citywide district (the Mayor's) on it, and it is the one district GA-1 did
  // NOT create. ⚠ Macon-Bibb's place record IS the whole county (FUNCSTAT 'A',
  // no balance record), which is why it can be keyed on rather than the county.
  {
    const place = await pool.query<{ n: number }>(
      `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc=$2`,
      [PLACE_GEO_ID, PLACE_MTFCC],
    );
    if (place.rows[0]!.n !== 1) {
      fail(`TIGER place ${PLACE_GEO_ID}/${PLACE_MTFCC} is missing — the citywide district has nothing to hang on.`);
    }
    console.log(`  ✓ TIGER place ${PLACE_GEO_ID} present for the citywide district`);
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
    const name = `Macon-Bibb County Commission District ${d}`;
    const geomStr = geomOf(d);
    const result = await pool.query<{ gtype: string; valid: boolean }>(
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

    const row = result.rows[0]!;
    if (row.valid !== true) {
      console.error(`  District ${d} (${geoId}): ST_IsValid=false — applying ST_MakeValid`);
      await pool.query(
        `UPDATE essentials.geofence_boundaries
           SET geometry = public.ST_Multi(public.ST_MakeValid(
             public.ST_SetSRID(public.ST_GeomFromGeoJSON($2), 4326)))
         WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId, geomStr],
      );
      const recheck = await pool.query<{ valid: boolean }>(
        `SELECT public.ST_IsValid(geometry) AS valid
           FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId],
      );
      if (recheck.rows[0]?.valid !== true) {
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

  console.log('\n=== Summary ===');
  console.log(`  Inserted:        ${inserted}`);
  console.log(`  Already existed: ${alreadyExists}`);
  console.log(`  Repaired:        ${repaired}`);

  // 🔴 Re-read from the DATABASE. Every gate above ran on what was FETCHED.
  const check = await pool.query<{ n: number; invalid: number; wrong_srid: number; wrong_state: number }>(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid,
            COUNT(*) FILTER (WHERE public.ST_SRID(geometry) <> 4326)::int AS wrong_srid,
            COUNT(*) FILTER (WHERE state <> '${STATE_CODE}')::int AS wrong_state
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const { n, invalid, wrong_srid: wrongSrid, wrong_state: wrongState } = check.rows[0]!;
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
