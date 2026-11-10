#!/usr/bin/env node
/**
 * CC_0373-ne-boards-geofences.mjs — Nebraska's three elected statewide boards
 * -> essentials.geofence_boundaries, one row per district.
 *
 *   --body psc      5 districts · mtfcc X-ST-BOARD · ocd-division/country:us/state:ne/psc:N      -> CC_0373
 *   --body sboe     8 districts · mtfcc X0003      · ocd-division/country:us/state:ne/sboe:N     -> CC_0374
 *   --body regents  8 districts · mtfcc X-ST-BOARD · ocd-division/country:us/state:ne/regents:N  -> CC_0375
 *
 * Run BEFORE the matching migration, whose districts point at these rows.
 *
 * PROVENANCE. The State of Nebraska's own GIS (gis.ne.gov), service
 *   PoliticalBoundaries_2021, published by the Legislative Research Office. Fetched and parsed
 *   by scripts/CC_0373-fetch-ne-boards-arcgis.mjs, whose header carries the service URL, the
 *   layer enumeration, the per-district sha256 digests and the CRS handling.
 *
 * 🔴🔴 TWO BODIES SHARE ONE MTFCC HERE, WHICH IS NEW. Louisiana's Public Service Commission and
 *   Colorado's Regents both live under X-ST-BOARD, but in different states, so a query keyed on
 *   (mtfcc, state) could not mix them. Nebraska puts the Public Service Commission AND the Board
 *   of Regents under X-ST-BOARD in state 31. **Every query below is scoped by the geo_id prefix
 *   as well as by (mtfcc, state)**, or the PSC's five districts and the Regents' eight would be
 *   counted, covered and overlap-tested as one thirteen-district body — which would pass some
 *   gates and fail others for reasons that have nothing to do with the data.
 *
 * WHY THESE LAYERS. The Board of Education is a state board of education, so it joins on the
 *   (X0003, STATE_BOARD_EDUCATION) rule already deployed. The Public Service Commission and the
 *   Board of Regents are not, and take (X-ST-BOARD, STATE_BOARD) — the rule CC_0366 added on
 *   this branch, which Louisiana's commission already uses and which the University of Colorado
 *   Regents, already in production, show is the right shelf for an elected university board.
 *
 * 🔴🔴 THERE IS NO STATUTORY COUNTY TEXT TO GATE ON. LB 5, LB 7 and LB 8 of the 2021 First
 *   Special Session each set their boundaries "by the adoption of maps by reference" and name no
 *   county. So this loader gates on TWO anchors, both from outside the GIS:
 *
 *   1. THE CANVASS ANCHOR — data/state-exec-2026-results/ne-<body>-counties-*.json, built from
 *      the Secretary of State's certified canvass books by parse-ne-canvass-counties.mjs. A
 *      county that cast votes in a district's race is in that district. This is the arm that
 *      catches two districts' geometries being SWAPPED, the way the statute gate did in Alabama,
 *      Louisiana and New Mexico.
 *   2. THE ENACTED-PLAN ANCHOR — data/state-exec-2026-results/ne-plan-populations-*.json, the
 *      population and deviation the Legislative Research Office prints on each district's own
 *      map sheet. It is checked against the GIS attribute before a row is inserted, and it is
 *      the ONLY thing that separates two districts whose county sets are identical.
 *
 * ⚠ WHAT THE CANVASS ANCHOR CANNOT DO, STATED RATHER THAN HIDDEN. Four districts lie wholly
 *   inside one county and therefore have no whole-county anchor at all: PSC 2 (Douglas),
 *   SBOE 4 and 8 (both Douglas), SBOE 1 (Lancaster), Regents 1 (Lancaster), Regents 4 and 8
 *   (both Douglas), Regents 2 (Douglas + Sarpy, both split). Most of them are still pinned,
 *   because their county SET is unique: PSC 2 is the only PSC district whose counties are
 *   exactly {Douglas}, so nothing can be swapped with it. Exactly two pairs are not pinned by
 *   county at all — **SBOE 4 with SBOE 8, and Regents 4 with Regents 8** — because each pair's
 *   county set is {Douglas} for both. Those four districts are separated only by anchor 2:
 *   SBOE 4 holds 245,713 people and SBOE 8 holds 246,703; Regents 4 holds 237,525 and Regents 8
 *   holds 245,234. Swap either pair and the population gate goes red. That is the whole reason
 *   the enacted sheets were read.
 *
 * 🔴 THE THRESHOLDS ARE MEASURED AGAINST PRODUCTION, NOT CARRIED OVER. New Mexico's 0.5% split
 *   floor refused a correct map there, which is why this is stated per state. Measured
 *   2026-11-07 across all three Nebraska bodies against our TIGER counties:
 *     - the smallest TRUE split share is 1.876912% — Burt County's sliver in SBOE District 6;
 *     - the largest FALSE share, a county merely grazing a district it is not in, is 0.006454%;
 *     - the worst whole-county containment is 99.9932% (Merrick County in SBOE 6);
 *     - the union of each body covers 99.9966% of the TIGER Nebraska outline;
 *     - no two districts of a body overlap at all.
 *   SHARE_FLOOR is therefore set at 0.1%: about nineteen times below the smallest real split and
 *   about fifteen times above the largest spurious one, which is as near the middle of that gap
 *   in log terms as a round number gets.
 *
 * 🟢 BURT AND CUMING ARE REALLY SPLIT, AND THE CANVASS SAID SO FIRST. The 2022 canvass records
 *   exactly one vote for each State Board of Education District 6 candidate in Burt County,
 *   which reads like a stray ballot filed under the wrong county. It is not: Burt is 98.12% in
 *   District 3 and 1.88% in District 6 on the enacted map, and Cuming is 87.71% / 12.29%. A
 *   two-ballot county entry turned out to be a real boundary. ▶ Measure before dismissing.
 *
 * ON CONFLICT (geo_id, mtfcc) DO NOTHING, so a re-run inserts nothing.
 *
 * Usage (from backend/):
 *   node scripts/CC_0373-ne-boards-geofences.mjs --body sboe --geojson <path> --dry-run
 *   node scripts/CC_0373-ne-boards-geofences.mjs --body sboe --geojson <path>
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const STATE_FIPS = '31';
const PLAN = 'data/state-exec-2026-results/ne-plan-populations-2026-11-07.json';

const BODIES = {
  psc: {
    count: 5, mtfcc: 'X-ST-BOARD', slot: 'CC_0373',
    prefix: 'ocd-division/country:us/state:ne/psc:',
    name: n => `Nebraska Public Service Commission District ${n}`,
    source: 'ne_lb5_2021_psc_plan',
    counties: 'data/state-exec-2026-results/ne-psc-counties-2026-11-07.json',
    act: 'LB 5 (2021 First Special Session), Neb. Rev. Stat. 75-101.01',
  },
  sboe: {
    count: 8, mtfcc: 'X0003', slot: 'CC_0374',
    prefix: 'ocd-division/country:us/state:ne/sboe:',
    name: n => `Nebraska State Board of Education District ${n}`,
    source: 'ne_lb7_2021_sboe_plan',
    counties: 'data/state-exec-2026-results/ne-sboe-counties-2026-11-07.json',
    act: 'LB 7 (2021 First Special Session), Neb. Rev. Stat. 79-311',
  },
  regents: {
    count: 8, mtfcc: 'X-ST-BOARD', slot: 'CC_0375',
    prefix: 'ocd-division/country:us/state:ne/regents:',
    name: n => `University of Nebraska Board of Regents District ${n}`,
    source: 'ne_lb8_am41_2021_regents_plan',
    counties: 'data/state-exec-2026-results/ne-regents-counties-2026-11-07.json',
    act: 'LB 8 as amended by AM41 (2021 First Special Session), Neb. Rev. Stat. 85-103.01',
  },
};

const argv = process.argv.slice(2);
const arg = k => { const i = argv.indexOf(k); return i > -1 ? argv[i + 1] : undefined; };
const DRY_RUN = argv.includes('--dry-run');
const BODY = arg('--body');
const GEOJSON_PATH = arg('--geojson');
if (!BODY || !BODIES[BODY]) throw new Error(`--body must be one of ${Object.keys(BODIES).join(', ')}`);
if (!GEOJSON_PATH) throw new Error('--geojson <path> is required');

const B = BODIES[BODY];
const MTFCC = B.mtfcc;
const PREFIX = B.prefix;
const N = B.count;
const GEOID = n => `${PREFIX}${n}`;

// 🔴 MEASURED 2026-11-07 AGAINST PRODUCTION — see the header. Do not carry these to another
//    state, and do not widen one to clear a red without measuring the distribution again.
const SHARE_FLOOR = 0.1;    // a county counts as split into a district only above this share
const WHOLE_FLOOR = 99.9;   // a whole county must be at least this much inside its own district
const LEAK_CEILING = 0.01;  // and at most this much in any other
// ⚠ COVER_FLOOR is 99.5 and the measured value is 99.9019%, NOT the 99.9966% the planar
//   measurement reported. Those are two different questions: 99.9966% is the ratio of planar
//   degree-areas, and this gate measures the ST_Difference in square metres on the spheroid,
//   which weights the Missouri River edge differently. Both are right; only one is this gate.
//   ▶ A threshold copied from a measurement made another way is not a measured threshold.
const COVER_FLOOR = 99.5;   // the union must cover at least this much of the TIGER state outline

const comp = JSON.parse(fs.readFileSync(B.counties, 'utf8'));
const wholeList = comp.whole.map(w => [w.district, w.county]);
const splitList = comp.split.map(s => [s.county, s.districts.slice().sort((a, b) => a - b)]);
if (wholeList.length + splitList.length !== 93) {
  throw new Error(`${B.counties} covers ${wholeList.length + splitList.length} counties, not Nebraska's 93`);
}

const plan = JSON.parse(fs.readFileSync(PLAN, 'utf8')).populations[BODY];
if (!plan || Object.keys(plan).length !== N) throw new Error(`${PLAN} holds no ${N}-district table for ${BODY}`);

const GEOM = `public.ST_Multi(public.ST_CollectionExtract(public.ST_MakeValid(
  public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($2)), 4326)), 3))`;

const data = JSON.parse(fs.readFileSync(GEOJSON_PATH, 'utf8'));
if (!Array.isArray(data.districts) || data.districts.length !== N) {
  throw new Error(`expected ${N} districts in ${GEOJSON_PATH}, found ${data.districts?.length}`);
}
if (data.body !== BODY) throw new Error(`${GEOJSON_PATH} was fetched for "${data.body}", not "${BODY}"`);

// ─── 🟢 ANCHOR 2, BEFORE ANYTHING IS WRITTEN: the enacted plan's own population table ───
for (const d of data.districts) {
  const want = plan[String(d.district)];
  if (!want) throw new Error(`the enacted plan table has no district ${d.district} for ${BODY}`);
  if (d.population !== want.population) {
    throw new Error(`district ${d.district}: the GIS says ${d.population} people, the enacted ` +
      `${B.act} map sheet says ${want.population}. One of them is not the plan in force — see ` +
      `the _the_trap note in ${PLAN}, which is exactly this failure for the Regents.`);
  }
}
console.log(`${N} districts match the population the enacted ${B.act} map sheet prints for each`);

const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();
await client.query('BEGIN');
let ok = false;
try {
  const fail = m => { throw new Error(`STOP: ${m}`); };

  let inserted = 0;
  for (const d of data.districts) {
    const r = await client.query(
      `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
       VALUES ($1, $1, $3, $4, $5, ${GEOM}, $6, now())
       ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
      [GEOID(d.district), JSON.stringify(d.geojson), B.name(d.district), STATE_FIPS, MTFCC, B.source]);
    inserted += r.rowCount;
  }
  console.log(`inserted ${inserted} row(s)`);

  // 🔴🔴 A DRY RUN THAT INSERTS NOTHING CHECKS ROWS THAT WERE ALREADY THERE, AND EVERY GATE
  //   BELOW THEN PASSES ON DATA THIS FILE DID NOT SUPPLY. The ON CONFLICT DO NOTHING above is
  //   what makes a real re-run idempotent, and it is also what makes a tampered dry run
  //   VACUOUS once the correct polygons are committed: CC_0372's CRS control and its
  //   label-swap control both reported "DRY RUN OK" that way, with "inserted 0 row(s)" one
  //   line above. A dry run is a rehearsal of the insert, so it has to actually insert.
  if (DRY_RUN && inserted !== N) {
    fail(`a dry run inserted ${inserted} of ${N} rows — the rest are already in the table, so `
      + 'the gates below would be checking those and not this file. Delete them first, or run '
      + 'the controls before the real load.');
  }

  // 🔴 NOTHING THAT NEEDS LON/LAT TO BE LON/LAT MAY RUN BEFORE THIS. CC_0370 lost a CRS control
  //    to a ::geography area in the same SELECT, which crashed PostGIS with
  //    "lwgeom_area_spher(oid) returned area < 0.0" before the bounding box was ever examined.
  const rows = await client.query(
    `SELECT geo_id, public.ST_SRID(geometry) srid, public.ST_IsValid(geometry) valid,
            public.ST_IsEmpty(geometry) empty,
            public.ST_XMin(geometry) xmin, public.ST_XMax(geometry) xmax,
            public.ST_YMin(geometry) ymin, public.ST_YMax(geometry) ymax
       FROM essentials.geofence_boundaries
      WHERE mtfcc = $1 AND state = $2 AND geo_id LIKE $3 || '%' ORDER BY geo_id`,
    [MTFCC, STATE_FIPS, PREFIX]);
  if (rows.rowCount !== N) fail(`${rows.rowCount} rows under ${MTFCC} with prefix ${PREFIX}, expected ${N}`);
  for (const r of rows.rows) {
    if (r.srid !== 4326) fail(`${r.geo_id} is SRID ${r.srid}`);
    if (!r.valid) fail(`${r.geo_id} is not a valid geometry`);
    if (r.empty) fail(`${r.geo_id} is empty`);
    if (r.xmin < -105 || r.xmax > -94.5 || r.ymin < 39 || r.ymax > 43.5) {
      fail(`${r.geo_id} bbox ${r.xmin},${r.ymin} .. ${r.xmax},${r.ymax} is outside Nebraska — WRONG CRS`);
    }
  }
  const nums = rows.rows.map(r => Number(r.geo_id.split(':').pop())).sort((a, b) => a - b);
  const want = Array.from({ length: N }, (_, i) => i + 1).join(',');
  if (nums.join(',') !== want) fail(`districts are ${nums.join(',')}, expected ${want}`);
  console.log(`${N} districts, all SRID 4326, valid, non-empty and inside the Nebraska bounding box`);

  const cov = await client.query(
    `WITH u AS (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries
                 WHERE mtfcc=$1 AND state=$2 AND geo_id LIKE $3 || '%'),
          s AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='31')
     SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g)::geography)
                        / public.ST_Area(s.g::geography) * 100)::numeric, 4) AS pct_covered
       FROM u, s`, [MTFCC, STATE_FIPS, PREFIX]);
  const covered = Number(cov.rows[0].pct_covered);
  if (!(covered >= COVER_FLOOR)) fail(`the ${N} districts cover only ${covered}% of the Nebraska state outline`);
  console.log(`union covers ${covered}% of the TIGER Nebraska outline (floor ${COVER_FLOOR}%)`);

  const ov = await client.query(
    `SELECT a.geo_id x, b.geo_id y,
            round((public.ST_Area(public.ST_Intersection(a.geometry,b.geometry)::geography)
                   / least(public.ST_Area(a.geometry::geography), public.ST_Area(b.geometry::geography))
                   * 100)::numeric, 6) pct
       FROM essentials.geofence_boundaries a JOIN essentials.geofence_boundaries b
         ON b.mtfcc=a.mtfcc AND b.state=a.state AND b.geo_id > a.geo_id AND b.geo_id LIKE $3 || '%'
      WHERE a.mtfcc=$1 AND a.state=$2 AND a.geo_id LIKE $3 || '%'
        AND public.ST_Intersects(a.geometry,b.geometry)
      ORDER BY pct DESC LIMIT 1`, [MTFCC, STATE_FIPS, PREFIX]);
  const worst = ov.rowCount ? Number(ov.rows[0].pct) : 0;
  if (worst > 0.001) fail(`${ov.rows[0].x} and ${ov.rows[0].y} overlap by ${worst}%`);
  console.log(`worst pairwise overlap ${worst}%`);

  // ─── 🟢 ANCHOR 1, THE CANVASS GATE ───
  const wholeQ = await client.query(
    `SELECT w.expect, w.county, (co.geo_id IS NULL) AS county_missing,
            (SELECT round((public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                           / public.ST_Area(co.geometry) * 100)::numeric, 4)
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id = $3 || w.expect::text) AS pct_in_own,
            (SELECT string_agg(replace(s.geo_id,$3,'') || '=' ||
                      round((public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                             / public.ST_Area(co.geometry) * 100)::numeric, 4) || '%', ', ')
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id LIKE $3 || '%' AND s.geo_id <> $3 || w.expect::text
                AND public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                    > public.ST_Area(co.geometry) * $4) AS leaks
       FROM (VALUES ${wholeList.map((_, i) => `($${i * 2 + 5}::int, $${i * 2 + 6}::text)`).join(',')}) AS w(expect, county)
       LEFT JOIN essentials.geofence_boundaries co ON co.state=$2 AND co.mtfcc='G4020' AND co.name=w.county`,
    [MTFCC, STATE_FIPS, PREFIX, LEAK_CEILING / 100, ...wholeList.flatMap(([d, c]) => [d, c])]);
  if (wholeQ.rowCount !== wholeList.length) fail(`the whole-county gate examined ${wholeQ.rowCount} rows, not ${wholeList.length}`);
  const missing = wholeQ.rows.filter(r => r.county_missing);
  if (missing.length) fail(`we hold no TIGER polygon for: ${missing.map(m => m.county).join(', ')}`);
  const shortfall = wholeQ.rows.filter(r => !(Number(r.pct_in_own) >= WHOLE_FLOOR));
  if (shortfall.length) {
    fail(`the canvass puts these counties wholly in one district and the map does not: ` +
      shortfall.map(b => `${b.county} is only ${b.pct_in_own ?? 0}% in D${b.expect}`).join('; '));
  }
  const leaking = wholeQ.rows.filter(r => r.leaks);
  if (leaking.length) {
    fail(`a county that voted in one district only reaches into another by more than ${LEAK_CEILING}%: ` +
      leaking.map(b => `${b.county} (canvass D${b.expect}) also ${b.leaks}`).join('; '));
  }
  const worstWhole = Math.min(...wholeQ.rows.map(r => Number(r.pct_in_own)));
  console.log(`all ${wholeList.length} whole counties sit in exactly the district that canvassed them ` +
    `(worst ${worstWhole}% in, nothing over ${LEAK_CEILING}% out)`);

  const splitQ = await client.query(
    `SELECT sp.county, sp.expect,
            (SELECT string_agg(replace(s.geo_id,$3,''), ',' ORDER BY (replace(s.geo_id,$3,''))::int)
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id LIKE $3 || '%'
                AND public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                    > public.ST_Area(co.geometry) * $4) AS shared_with,
            (SELECT min(round((public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                               / public.ST_Area(co.geometry) * 100)::numeric, 4))
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id LIKE $3 || '%'
                AND public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                    > public.ST_Area(co.geometry) * $4) AS smallest_share
       FROM (VALUES ${splitList.map((_, i) => `($${i * 2 + 5}::text, $${i * 2 + 6}::text)`).join(',')}) AS sp(county, expect)
       JOIN essentials.geofence_boundaries co ON co.state=$2 AND co.mtfcc='G4020' AND co.name=sp.county`,
    [MTFCC, STATE_FIPS, PREFIX, SHARE_FLOOR / 100, ...splitList.flatMap(([c, ds]) => [c, ds.join(',')])]);
  if (splitQ.rowCount !== splitList.length) fail(`the split-county gate examined ${splitQ.rowCount} rows, not ${splitList.length}`);
  const badSplit = splitQ.rows.filter(r => String(r.shared_with) !== String(r.expect));
  if (badSplit.length) {
    fail(`a county the canvass shows voting in several districts is shared with the wrong ones: ` +
      badSplit.map(b => `${b.county} -> ${b.shared_with ?? 'nothing'}, the canvass says ${b.expect}`).join('; '));
  }
  console.log(`all ${splitList.length} split counties are shared by exactly the districts that canvassed them ` +
    `(${splitQ.rows.map(r => `${r.county.replace(' County', '')}=${r.shared_with}`).join(' · ')})`);
  console.log(`  smallest true share on a split county: ` +
    `${Math.min(...splitQ.rows.map(r => Number(r.smallest_share)))}% (floor ${SHARE_FLOOR}%)`);

  // 🔴 THE ZCTA'S OWN REPRESENTATIVE POINT IS NOT ALWAYS IN NEBRASKA, AND THE FIRST VERSION OF
  //   THIS GATE READ THAT AS A HOLE IN THE DISTRICT MAP. Three of the 586 ZCTAs carried under
  //   state 31 straddle a state line, and ST_PointOnSurface lands on the far side: 68327 (66%
  //   in Nebraska) points into Kansas below the 40th parallel, 69212 (57%) into South Dakota
  //   above the 43rd, and 68110 into Carter Lake, Iowa — the enclave the Missouri River left on
  //   the Nebraska bank when it moved in 1877. Two of the three then looked like holes and the
  //   third like a district reaching outside the state. None of that is a fact about this map.
  //   ▶ So the point is taken from the part of the ZCTA that IS in Nebraska. Every ZCTA then
  //   has a point genuinely inside the state, every one must resolve to exactly one district,
  //   and there is no exclusion list to go stale.
  const zctas = await client.query(
    `WITH st AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='31'),
          p AS (SELECT z.geo_id,
                       public.ST_PointOnSurface(public.ST_CollectionExtract(
                         public.ST_Intersection(z.geometry, st.g), 3)) pt
                  FROM essentials.geofence_boundaries z, st
                 WHERE z.state=$2 AND z.mtfcc='G6350'
                   AND NOT public.ST_IsEmpty(public.ST_CollectionExtract(public.ST_Intersection(z.geometry, st.g), 3)))
     SELECT count(*) zctas,
            count(*) FILTER (WHERE k=1) one,
            count(*) FILTER (WHERE k=0) none,
            count(*) FILTER (WHERE k>1) many,
            string_agg(geo_id || '(k=' || k || ')', ', ') FILTER (WHERE k<>1) offenders
       FROM (SELECT p.geo_id,
                    (SELECT count(*) FROM essentials.geofence_boundaries s
                      WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id LIKE $3 || '%'
                        AND public.ST_Covers(s.geometry, p.pt)) k
               FROM p) q`,
    [MTFCC, STATE_FIPS, PREFIX]);
  const zc = zctas.rows[0];
  if (Number(zc.zctas) < 500) fail(`the ZCTA gate examined only ${zc.zctas} rows`);
  if (Number(zc.none) !== 0 || Number(zc.many) !== 0) {
    fail(`${zc.none} Nebraska ZCTA(s) fall in NO district and ${zc.many} in more than one: ${zc.offenders}`);
  }
  console.log(`all ${zc.zctas} Nebraska ZCTAs resolve to exactly one district ` +
    `(each tested at a point inside the state, not at its own centroid)`);

  const areas = await client.query(
    `SELECT replace(geo_id,$3,'') d, round((public.ST_Area(geometry::geography)/2589988.11)::numeric) sq_miles
       FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND state=$2 AND geo_id LIKE $3 || '%'
      ORDER BY (replace(geo_id,$3,''))::int`, [MTFCC, STATE_FIPS, PREFIX]);
  const totalSqMi = areas.rows.reduce((s, r) => s + Number(r.sq_miles), 0);
  console.log(`areas (sq mi): ${areas.rows.map(r => `${r.d}=${r.sq_miles}`).join(' ')} · total ${totalSqMi}`);
  ok = true;
} finally {
  if (ok && !DRY_RUN) { await client.query('COMMIT'); console.log('COMMITTED'); }
  else { await client.query('ROLLBACK'); console.log(ok ? 'DRY RUN OK — rolled back' : 'ROLLED BACK'); }
  await client.end();
}
