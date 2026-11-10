#!/usr/bin/env node
/**
 * CC_0376-nh-exec-geofences.mjs — load New Hampshire's five Executive Council districts into
 * essentials.geofence_boundaries, and gate them against geography production already trusts.
 *
 * The polygons come from CC_0376-fetch-nh-exec-arcgis.mjs (NHGRANIT layer 7, NHExecDists2022).
 * The labels come from CC_0376-parse-nh-council-statute.mjs (RSA 662:2 + the Census gazetteer).
 * Those two are independent, which is the only reason the second can check the first.
 *
 * LAYER. `X-ST-BOARD` with `district_type = 'STATE_BOARD'`. The Executive Council is an elected
 *   state-level body that is not a board of education, and its five seats are DISTRICTED, so it
 *   reaches a voter through the geofence join and not through buildStatewideQuery's closed type
 *   list. CC_0366 registered that pair in districtQueries.ts and geoIdGuard.ts and it is on
 *   master, so this body needs NO read-path change.
 *
 * THE GATES, in the order they run, weakest first:
 *   1. every row SRID 4326, valid, non-empty, bbox inside New Hampshire  — catches a CRS fault
 *   2. the union covers the TIGER state outline                          — catches a missing piece
 *   3. no two districts overlap                                          — catches a torn plan
 *   4. 🟢 THE TOWN GATE: 259 Census internal points, one per town, city and unincorporated place,
 *      each labelled by RSA 662:2, each of which must be covered by exactly one district AND by
 *      the district the statute names.
 *   5. the county composition, as a second and coarser view of the same evidence
 *   6. every New Hampshire ZCTA resolves to exactly one district
 *
 * 🔴🔴 GATE 4 IS THE ONE THAT MATTERS, AND IT IS WHY THIS BODY HAS NO UNPINNED DISTRICT.
 *   Gates 1-3 and 6 are shape tests: they pass just as happily on a map whose five labels have
 *   been permuted, because a permutation is still five disjoint polygons covering the state.
 *   Nebraska had to record two pairs of districts that no available evidence could separate, and
 *   New Mexico four. New Hampshire has none: the statute names every place in the state, so
 *   every district carries at least 20 test points and no permutation survives.
 *
 * 🔴 THE COUNTY ANCHOR THAT CARRIED ALABAMA AND LOUISIANA IS NEARLY EMPTY HERE — MEASURED.
 *   Only ONE of the ten counties (Carroll, district 1) lies wholly inside a district; nine are
 *   split, Hillsborough four ways. A file that reached for the familiar whole-county gate would
 *   have had a single usable row and would have LOOKED anchored. Gate 5 is kept because the
 *   county set per district is still a real constraint and it reads at a glance, but it is the
 *   corroboration, not the anchor.
 *
 * 🔴 RUN THE CONTROLS BEFORE THE REAL LOAD. The INSERT is ON CONFLICT DO NOTHING, so once the
 *   correct polygons are committed a tampered dry run inserts nothing and every gate below
 *   checks rows this file did not supply — CC_0372 lost two controls that way, both reporting
 *   "DRY RUN OK". A dry run that does not insert its full set is refused outright.
 *
 * Usage (from backend/):
 *   node scripts/CC_0376-nh-exec-geofences.mjs --geojson <districts.json> --composition <comp.json> [--dry-run] [--measure]
 *
 *   --measure  prints the county share distribution and the town/ZCTA margins, then rolls back.
 *              It exists so the floors below are MEASURED rather than carried from another state
 *              — the 0.5% split floor that worked for Alabama and Louisiana refused a correct
 *              New Mexico map.
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const STATE_FIPS = '33';
const MTFCC = 'X-ST-BOARD';
const PREFIX = 'ocd-division/country:us/state:nh/council:';
const SOURCE = 'nh_sb241_2022_council_plan';
const N = 5;
const GEOID = n => `${PREFIX}${n}`;
const NAME = n => `New Hampshire Executive Council District ${n}`;

const argv = process.argv.slice(2);
const arg = k => { const i = argv.indexOf(k); return i > -1 ? argv[i + 1] : undefined; };
const DRY_RUN = argv.includes('--dry-run');
const MEASURE = argv.includes('--measure');
const GEOJSON_PATH = arg('--geojson');
const COMP_PATH = arg('--composition');
if (!GEOJSON_PATH) throw new Error('--geojson <path> is required');
if (!COMP_PATH) throw new Error('--composition <path> is required');

// 🔴 MEASURED 2026-11-08 AGAINST PRODUCTION with --measure — see NOTES.md. Do not carry these to
//    another state, and do not widen one to clear a red without measuring the distribution again.
const SHARE_FLOOR = 0.05;   // a county counts as split into a district only above this share
const WHOLE_FLOOR = 99.5;   // a whole county must be at least this much inside its own district
const LEAK_CEILING = 0.05;  // and at most this much in any other
const COVER_FLOOR = 99.5;   // the union must cover at least this much of the TIGER state outline
const OVERLAP_CEILING = 0.001;

const comp = JSON.parse(fs.readFileSync(COMP_PATH, 'utf8'));
if (!Array.isArray(comp.towns) || !Array.isArray(comp.counties)) throw new Error(`${COMP_PATH} is not a composition file`);
if (comp.counties.length !== 10) throw new Error(`${COMP_PATH} covers ${comp.counties.length} counties, not New Hampshire's 10`);
const towns = comp.towns;
if (towns.length < 250) throw new Error(`${COMP_PATH} holds only ${towns.length} town test points`);
const wholeList = comp.counties.filter(c => c.whole).map(c => [c.district, c.name + ' County']);
const splitList = comp.counties.filter(c => !c.whole).map(c => [c.name + ' County', c.districts.slice().sort((a, b) => a - b)]);

const data = JSON.parse(fs.readFileSync(GEOJSON_PATH, 'utf8'));
if (!Array.isArray(data.districts) || data.districts.length !== N) {
  throw new Error(`expected ${N} districts in ${GEOJSON_PATH}, found ${data.districts?.length}`);
}
if (data.layerName !== 'NHExecDists2022') {
  throw new Error(`${GEOJSON_PATH} was fetched from layer "${data.layerName}", not NHExecDists2022 — ` +
    `layer 1 of that service is the superseded 2012 map`);
}

const GEOM = `public.ST_Multi(public.ST_CollectionExtract(public.ST_MakeValid(
  public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($2)), 4326)), 3))`;

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
      [GEOID(d.district), JSON.stringify(d.geojson), NAME(d.district), STATE_FIPS, MTFCC, SOURCE]);
    inserted += r.rowCount;
  }
  console.log(`inserted ${inserted} row(s)`);

  // 🔴🔴 A DRY RUN THAT INSERTS NOTHING CHECKS ROWS THAT WERE ALREADY THERE.
  if ((DRY_RUN || MEASURE) && inserted !== N) {
    fail(`a dry run inserted ${inserted} of ${N} rows — the rest are already in the table, so the `
      + 'gates below would be checking those and not this file. Delete them first, or run the '
      + 'controls before the real load.');
  }

  // ── 1. shape and CRS. 🔴 NOTHING NEEDING LON/LAT TO BE LON/LAT MAY RUN BEFORE THIS: CC_0370
  //    lost a CRS control to a ::geography area that crashed PostGIS before the bbox was read.
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
    if (r.xmin < -72.8 || r.xmax > -70.4 || r.ymin < 42.5 || r.ymax > 45.5) {
      fail(`${r.geo_id} bbox ${r.xmin},${r.ymin} .. ${r.xmax},${r.ymax} is outside New Hampshire — WRONG CRS. ` +
        `The NHGRANIT layer is native wkid 3437, NAD83 State Plane in US survey feet.`);
    }
  }
  const nums = rows.rows.map(r => Number(r.geo_id.split(':').pop())).sort((a, b) => a - b);
  const want = Array.from({ length: N }, (_, i) => i + 1).join(',');
  if (nums.join(',') !== want) fail(`districts are ${nums.join(',')}, expected ${want}`);
  console.log(`${N} districts, all SRID 4326, valid, non-empty and inside the New Hampshire bounding box`);

  // ── 2. coverage of the state outline.
  //    ⚠ THE G4000 ROW IS KEYED ON geo_id, NOT ON state. CLAUDE.md says geofence_boundaries.state
  //      holds 2-digit FIPS; that is true of every layer here EXCEPT G4000, where 52 of the 53
  //      rows hold a USPS code ('NH'). A state-outline lookup written as state = '33' returns
  //      nothing and reads as "we hold no outline for this state", which would quietly skip
  //      this gate. Measured 2026-11-08.
  const cov = await client.query(
    `WITH u AS (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries
                 WHERE mtfcc=$1 AND state=$2 AND geo_id LIKE $3 || '%'),
          s AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='33')
     SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g)::geography)
                        / public.ST_Area(s.g::geography) * 100)::numeric, 4) AS pct_covered
       FROM u, s`, [MTFCC, STATE_FIPS, PREFIX]);
  if (!cov.rowCount) fail('no TIGER state outline for New Hampshire (G4000, geo_id 33) — the coverage gate cannot run');
  const covered = Number(cov.rows[0].pct_covered);
  if (!(covered >= COVER_FLOOR)) fail(`the ${N} districts cover only ${covered}% of the New Hampshire state outline`);
  console.log(`union covers ${covered}% of the TIGER New Hampshire outline (floor ${COVER_FLOOR}%)`);

  // ── 3. pairwise overlap.
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
  if (worst > OVERLAP_CEILING) fail(`${ov.rows[0].x} and ${ov.rows[0].y} overlap by ${worst}%`);
  console.log(`worst pairwise overlap ${worst}%`);

  // ── 4. 🟢 THE TOWN GATE — the anchor. 259 points from the Census, 259 labels from RSA 662:2.
  const values = towns.map((_, i) => `($${i * 4 + 4}::text, $${i * 4 + 5}::int, $${i * 4 + 6}::float8, $${i * 4 + 7}::float8)`).join(',');
  const townQ = await client.query(
    `WITH t(name, expect, lon, lat) AS (VALUES ${values}),
          r AS (SELECT t.name, t.expect,
                       (SELECT string_agg(replace(s.geo_id,$3,''), ',' ORDER BY (replace(s.geo_id,$3,''))::int)
                          FROM essentials.geofence_boundaries s
                         WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id LIKE $3 || '%'
                           AND public.ST_Covers(s.geometry, public.ST_SetSRID(public.ST_MakePoint(t.lon, t.lat), 4326))) AS got
                  FROM t)
     SELECT count(*) AS examined,
            count(*) FILTER (WHERE got = expect::text) AS agree,
            count(*) FILTER (WHERE got IS NULL) AS nowhere,
            count(*) FILTER (WHERE got LIKE '%,%') AS many,
            string_agg(name || ': statute D' || expect || ', map ' || coalesce(got,'NOWHERE'), '; ')
              FILTER (WHERE got IS DISTINCT FROM expect::text) AS offenders
       FROM r`,
    [MTFCC, STATE_FIPS, PREFIX, ...towns.flatMap(t => [t.statuteName, t.district, t.lon, t.lat])]);
  const tq = townQ.rows[0];
  // ⚠ A control proves a verifier CAN fail; it does not prove it read the right rows. So the
  //   count it examined is asserted, not just its verdict.
  if (Number(tq.examined) !== towns.length) fail(`the town gate examined ${tq.examined} points, not ${towns.length}`);
  if (Number(tq.agree) !== towns.length) {
    fail(`${towns.length - Number(tq.agree)} of ${towns.length} towns fall in a district RSA 662:2 does not put ` +
      `them in (${tq.nowhere} in no district, ${tq.many} in more than one): ` +
      String(tq.offenders).slice(0, 900));
  }
  console.log(`🟢 all ${tq.examined} towns, cities and unincorporated places named by RSA 662:2 fall in exactly ` +
    `the district the statute assigns them — the map's labels are anchored`);

  // ── 5. the county composition, the coarser second view.
  if (wholeList.length) {
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
      fail(`the statute puts these counties wholly in one district and the map does not: ` +
        shortfall.map(b => `${b.county} is only ${b.pct_in_own ?? 0}% in D${b.expect}`).join('; '));
    }
    const leaking = wholeQ.rows.filter(r => r.leaks);
    if (leaking.length) {
      fail(`a county RSA 662:2 puts wholly in one district reaches into another by more than ${LEAK_CEILING}%: ` +
        leaking.map(b => `${b.county} (statute D${b.expect}) also ${b.leaks}`).join('; '));
    }
    console.log(`the ${wholeList.length} whole county sits in exactly the district RSA 662:2 names ` +
      `(${wholeQ.rows.map(r => `${r.county.replace(' County','')}=${r.pct_in_own}% in D${r.expect}`).join(', ')}, ` +
      `nothing over ${LEAK_CEILING}% out)`);
  }

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
                    > public.ST_Area(co.geometry) * $4) AS smallest_share,
            (SELECT string_agg(replace(s.geo_id,$3,'') || '=' ||
                      round((public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                             / public.ST_Area(co.geometry) * 100)::numeric, 4), ' ' ORDER BY (replace(s.geo_id,$3,''))::int)
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id LIKE $3 || '%'
                AND public.ST_Intersects(s.geometry, co.geometry)) AS all_shares
       FROM (VALUES ${splitList.map((_, i) => `($${i * 2 + 5}::text, $${i * 2 + 6}::text)`).join(',')}) AS sp(county, expect)
       JOIN essentials.geofence_boundaries co ON co.state=$2 AND co.mtfcc='G4020' AND co.name=sp.county`,
    [MTFCC, STATE_FIPS, PREFIX, SHARE_FLOOR / 100, ...splitList.flatMap(([c, ds]) => [c, ds.join(',')])]);
  if (splitQ.rowCount !== splitList.length) fail(`the split-county gate examined ${splitQ.rowCount} rows, not ${splitList.length}`);
  if (MEASURE) {
    console.log('\n--measure: every district share of every split county, including ones below the floor');
    for (const r of splitQ.rows) console.log(`  ${r.county.replace(' County','').padEnd(14)} statute ${String(r.expect).padEnd(9)} map ${r.all_shares}`);
  }
  const badSplit = splitQ.rows.filter(r => String(r.shared_with) !== String(r.expect));
  if (badSplit.length) {
    fail(`a county RSA 662:2 splits between districts is shared with the wrong ones: ` +
      badSplit.map(b => `${b.county} -> ${b.shared_with ?? 'nothing'}, the statute says ${b.expect}`).join('; '));
  }
  const smallestShare = Math.min(...splitQ.rows.map(r => Number(r.smallest_share)));
  console.log(`all ${splitList.length} split counties are shared by exactly the districts RSA 662:2 names ` +
    `(${splitQ.rows.map(r => `${r.county.replace(' County','')}=${r.shared_with}`).join(' · ')})`);
  console.log(`  smallest true share on a split county: ${smallestShare}% (floor ${SHARE_FLOOR}%)`);
  if (!MEASURE && smallestShare < SHARE_FLOOR * 2) {
    fail(`the smallest true county share is ${smallestShare}%, within 2x of the ${SHARE_FLOOR}% floor — ` +
      `re-measure the distribution with --measure and lower the floor`);
  }

  // ── 6. every New Hampshire ZCTA resolves to exactly one district.
  //    🔴 The point is taken from the part of the ZCTA inside the state: New Hampshire borders
  //    three states and a ZCTA's own representative point can land outside it, which reads as a
  //    hole in the district map and is not a fact about this map (the Nebraska lesson).
  const zctas = await client.query(
    `WITH st AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='33'),
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
  if (Number(zc.zctas) < 200) fail(`the ZCTA gate examined only ${zc.zctas} rows`);
  if (Number(zc.none) !== 0 || Number(zc.many) !== 0) {
    fail(`${zc.none} New Hampshire ZCTA(s) fall in NO district and ${zc.many} in more than one: ${zc.offenders}`);
  }
  console.log(`all ${zc.zctas} New Hampshire ZCTAs resolve to exactly one district ` +
    `(each tested at a point inside the state, not at its own centroid)`);

  const areas = await client.query(
    `SELECT replace(geo_id,$3,'') d, round((public.ST_Area(geometry::geography)/2589988.11)::numeric) sq_miles
       FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND state=$2 AND geo_id LIKE $3 || '%'
      ORDER BY (replace(geo_id,$3,''))::int`, [MTFCC, STATE_FIPS, PREFIX]);
  console.log(`areas (sq mi): ${areas.rows.map(r => `${r.d}=${r.sq_miles}`).join(' ')} · ` +
    `total ${areas.rows.reduce((s, r) => s + Number(r.sq_miles), 0)}`);
  ok = true;
} finally {
  if (ok && !DRY_RUN && !MEASURE) { await client.query('COMMIT'); console.log('COMMITTED'); }
  else { await client.query('ROLLBACK'); console.log(ok ? 'DRY RUN OK — rolled back' : 'ROLLED BACK'); }
  await client.end();
}
