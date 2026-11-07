#!/usr/bin/env node
/**
 * CC_0371-la-psc-geofences.mjs — Louisiana's five Public Service Commission districts
 * -> essentials.geofence_boundaries as mtfcc='X-ST-BOARD',
 *    geo_id 'ocd-division/country:us/state:la/psc:1'..':5'.
 * Run BEFORE migration CC_0371, whose districts point at these rows.
 *
 * PROVENANCE: HB2_PSC_221ES, the plan adopted by Act 2 (HB2) of the 2022 First Extraordinary
 *   Session, from the Louisiana Legislature's redistricting site. Converted to GeoJSON by
 *   scripts/CC_0371-parse-la-psc-kml.mjs, whose header carries the URL, byte counts, sha256
 *   digests, the .prj reading and the bill-by-bill check that the 2026 Regular Session's
 *   redistricting did not touch this map.
 *
 * WHY mtfcc X-ST-BOARD AND NOT X0003. X0003 is the board-of-education layer. A Public Service
 *   Commission is not one, so these rows go under X-ST-BOARD with district_type STATE_BOARD —
 *   the pair CC_0366 added to districtQueries.ts and geoIdGuard.ts for the University of
 *   Colorado Regents. ⚠ That read-path line is on this branch and NOT yet deployed, so these
 *   seats answer an address only after it merges and the backend deploys. Colorado's regents are
 *   in the same position; CC_0366 measured it.
 *   ⚠ `geofence_boundaries.mtfcc` is varchar(10) and 'X-ST-BOARD' is exactly 10.
 *
 * STOP GUARDS (all inside the insert transaction, against the inserted rows):
 *   - exactly 5 rows, districts 1..5, each once;
 *   - every geometry SRID 4326, valid, non-empty, and inside the Louisiana bounding box.
 *     🔴 Nothing that needs lon/lat to BE lon/lat runs before this one — CC_0370 lost a CRS
 *     control to a ::geography area in the same SELECT, which crashed PostGIS first;
 *   - the union covers at least 99.5% of our TIGER Louisiana state outline (G4000 '22');
 *   - no two districts overlap by more than 0.001% of the smaller;
 *   - 🟢 THE PARISH GATE, from the composition reconciled in
 *     data/state-exec-2026-results/la-psc-parishes-2026-11-07.json. That file is built by
 *     reconcile-la-psc-parishes.mjs from TWO independent official statements — the Legislature's
 *     142,874-row block equivalency file for Act 2, and the commission's own five district pages
 *     — which agree on all 64 parishes. 54 are whole and 10 are split. Each whole parish must lie
 *     inside the one district it is assigned, and each split parish must be shared by exactly the
 *     districts named. This is the only check here that can catch two districts' geometries being
 *     SWAPPED: a label swap passes every structural test (CC_0369 control C, CC_0370 loader
 *     control C);
 *   - all 539 Louisiana ZCTAs (G6350) resolve to exactly one district.
 *     ⚠ Louisiana, like Alabama, has no G4110 incorporated places in production.
 *
 * ON CONFLICT (geo_id, mtfcc) DO NOTHING, so a re-run inserts nothing.
 *
 * Usage (from backend/):
 *   node scripts/CC_0371-la-psc-geofences.mjs --geojson <path> --dry-run   # every guard, then ROLLBACK
 *   node scripts/CC_0371-la-psc-geofences.mjs --geojson <path>             # same, then COMMIT
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const MTFCC = 'X-ST-BOARD';
const STATE_FIPS = '22';
const SOURCE = 'la_act2_2022_1es_psc_plan';
const PREFIX = 'ocd-division/country:us/state:la/psc:';
const GEOID = n => `${PREFIX}${n}`;
const PARISHES = 'data/state-exec-2026-results/la-psc-parishes-2026-11-07.json';

const DRY_RUN = process.argv.includes('--dry-run');
const gi = process.argv.indexOf('--geojson');
const GEOJSON_PATH = gi > -1 ? process.argv[gi + 1] : undefined;
if (!GEOJSON_PATH) throw new Error('--geojson <path> is required');

// A parish counts as being SPLIT into a district only if this much of its area is (percent),
// and a whole parish must be at least WHOLE_FLOOR% inside its own with no more than
// LEAK_CEILING% anywhere else. Measured against production before they were chosen — see the
// numbers printed by a clean run, and NOTES.md.
const SHARE_FLOOR = 0.5;
const WHOLE_FLOOR = 99.9;
const LEAK_CEILING = 0.01;

const comp = JSON.parse(fs.readFileSync(PARISHES, 'utf8'));
const wholeList = comp.whole.map(w => [w.district, w.parish]);
const splitList = comp.split.map(s => [s.parish, s.districts.slice().sort((a, b) => a - b)]);
if (wholeList.length !== 54) throw new Error(`${PARISHES} holds ${wholeList.length} whole parishes, expected 54`);
if (splitList.length !== 10) throw new Error(`${PARISHES} holds ${splitList.length} split parishes, expected 10`);
if (wholeList.length + splitList.length !== 64) throw new Error('the parish table does not cover Louisiana\'s 64 parishes');

const GEOM = `public.ST_Multi(public.ST_CollectionExtract(public.ST_MakeValid(
  public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($2)), 4326)), 3))`;

const data = JSON.parse(fs.readFileSync(GEOJSON_PATH, 'utf8'));
if (!Array.isArray(data.districts) || data.districts.length !== 5) {
  throw new Error(`expected 5 districts in ${GEOJSON_PATH}, found ${data.districts?.length}`);
}

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
      [GEOID(d.district), JSON.stringify(d.geojson), `Louisiana Public Service Commission District ${d.district}`,
        STATE_FIPS, MTFCC, SOURCE]);
    inserted += r.rowCount;
  }
  console.log(`inserted ${inserted} row(s)`);

  // 🔴 THE CRS GUARD GOES FIRST AND CARRIES NO ::geography. Areas are measured at the end.
  const rows = await client.query(
    `SELECT geo_id, public.ST_SRID(geometry) srid, public.ST_IsValid(geometry) valid,
            public.ST_IsEmpty(geometry) empty,
            public.ST_XMin(geometry) xmin, public.ST_XMax(geometry) xmax,
            public.ST_YMin(geometry) ymin, public.ST_YMax(geometry) ymax
       FROM essentials.geofence_boundaries WHERE mtfcc = $1 AND state = $2 ORDER BY geo_id`, [MTFCC, STATE_FIPS]);
  if (rows.rowCount !== 5) fail(`${rows.rowCount} Louisiana rows under ${MTFCC}, expected 5`);
  for (const r of rows.rows) {
    if (r.srid !== 4326) fail(`${r.geo_id} is SRID ${r.srid}`);
    if (!r.valid) fail(`${r.geo_id} is not a valid geometry`);
    if (r.empty) fail(`${r.geo_id} is empty`);
    if (r.xmin < -95 || r.xmax > -88 || r.ymin < 28 || r.ymax > 34) {
      fail(`${r.geo_id} bbox ${r.xmin},${r.ymin} .. ${r.xmax},${r.ymax} is outside Louisiana — WRONG CRS`);
    }
  }
  const nums = rows.rows.map(r => Number(r.geo_id.split(':').pop())).sort((a, b) => a - b);
  if (nums.join(',') !== '1,2,3,4,5') fail(`districts are ${nums.join(',')}`);
  console.log('5 districts, all SRID 4326, valid, non-empty and inside the Louisiana bounding box');

  const cov = await client.query(
    `WITH u AS (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND state=$2),
          s AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='22')
     SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g)::geography)
                        / public.ST_Area(s.g::geography) * 100)::numeric, 3) AS pct_covered
       FROM u, s`, [MTFCC, STATE_FIPS]);
  const covered = Number(cov.rows[0].pct_covered);
  if (!(covered >= 99.5)) fail(`the 5 districts cover only ${covered}% of the Louisiana state outline`);
  console.log(`union covers ${covered}% of the TIGER Louisiana outline`);

  const ov = await client.query(
    `SELECT a.geo_id x, b.geo_id y,
            round((public.ST_Area(public.ST_Intersection(a.geometry,b.geometry)::geography)
                   / least(public.ST_Area(a.geometry::geography), public.ST_Area(b.geometry::geography))
                   * 100)::numeric, 6) pct
       FROM essentials.geofence_boundaries a JOIN essentials.geofence_boundaries b
         ON b.mtfcc=a.mtfcc AND b.state=a.state AND b.geo_id > a.geo_id
      WHERE a.mtfcc=$1 AND a.state=$2 AND public.ST_Intersects(a.geometry,b.geometry)
      ORDER BY pct DESC LIMIT 1`, [MTFCC, STATE_FIPS]);
  const worst = ov.rowCount ? Number(ov.rows[0].pct) : 0;
  if (worst > 0.001) fail(`${ov.rows[0].x} and ${ov.rows[0].y} overlap by ${worst}%`);
  console.log(`worst pairwise overlap ${worst}%`);

  // ─── 🟢 THE PARISH GATE ───
  const wholeQ = await client.query(
    `SELECT w.expect, w.parish, (co.geo_id IS NULL) AS parish_missing,
            (SELECT round((public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                           / public.ST_Area(co.geometry) * 100)::numeric, 4)
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id = $3 || w.expect::text) AS pct_in_own,
            (SELECT string_agg(replace(s.geo_id,$3,'') || '=' ||
                      round((public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                             / public.ST_Area(co.geometry) * 100)::numeric, 4) || '%', ', ')
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id <> $3 || w.expect::text
                AND public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                    > public.ST_Area(co.geometry) * $4) AS leaks
       FROM (VALUES ${wholeList.map((_, i) => `($${i * 2 + 5}::int, $${i * 2 + 6}::text)`).join(',')}) AS w(expect, parish)
       LEFT JOIN essentials.geofence_boundaries co ON co.state=$2 AND co.mtfcc='G4020' AND co.name=w.parish`,
    [MTFCC, STATE_FIPS, PREFIX, LEAK_CEILING / 100, ...wholeList.flatMap(([d, c]) => [d, c])]);
  if (wholeQ.rowCount !== 54) fail(`the whole-parish gate examined ${wholeQ.rowCount} rows, not 54`);
  const missing = wholeQ.rows.filter(r => r.parish_missing);
  if (missing.length) fail(`we hold no TIGER polygon for: ${missing.map(m => m.parish).join(', ')}`);
  const shortfall = wholeQ.rows.filter(r => !(Number(r.pct_in_own) >= WHOLE_FLOOR));
  if (shortfall.length) {
    fail(`Act 2 puts these parishes wholly in one district and the map does not: ` +
      shortfall.map(b => `${b.parish} is only ${b.pct_in_own ?? 0}% in D${b.expect}`).join('; '));
  }
  const leaking = wholeQ.rows.filter(r => r.leaks);
  if (leaking.length) {
    fail(`a parish Act 2 assigns whole reaches into another district by more than ${LEAK_CEILING}%: ` +
      leaking.map(b => `${b.parish} (Act 2 D${b.expect}) also ${b.leaks}`).join('; '));
  }
  const worstWhole = Math.min(...wholeQ.rows.map(r => Number(r.pct_in_own)));
  console.log(`all 54 whole parishes sit in exactly the district Act 2 assigns them ` +
    `(worst ${worstWhole}% in, nothing over ${LEAK_CEILING}% out)`);

  const splitQ = await client.query(
    `SELECT sp.parish, sp.expect,
            (SELECT string_agg(replace(s.geo_id,$3,''), ',' ORDER BY s.geo_id)
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2
                AND public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                    > public.ST_Area(co.geometry) * $4) AS shared_with,
            (SELECT min(round((public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                               / public.ST_Area(co.geometry) * 100)::numeric, 4))
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2
                AND public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                    > public.ST_Area(co.geometry) * $4) AS smallest_share
       FROM (VALUES ${splitList.map((_, i) => `($${i * 2 + 5}::text, $${i * 2 + 6}::text)`).join(',')}) AS sp(parish, expect)
       JOIN essentials.geofence_boundaries co ON co.state=$2 AND co.mtfcc='G4020' AND co.name=sp.parish`,
    [MTFCC, STATE_FIPS, PREFIX, SHARE_FLOOR / 100, ...splitList.flatMap(([c, ds]) => [c, ds.join(',')])]);
  if (splitQ.rowCount !== 10) fail(`the split-parish gate examined ${splitQ.rowCount} rows, not 10`);
  const badSplit = splitQ.rows.filter(r => String(r.shared_with) !== String(r.expect));
  if (badSplit.length) {
    fail(`a parish Act 2 splits is shared with the wrong districts: ` +
      badSplit.map(b => `${b.parish} -> ${b.shared_with ?? 'nothing'}, Act 2 says ${b.expect}`).join('; '));
  }
  console.log(`all 10 split parishes are shared by exactly the districts Act 2 names ` +
    `(${splitQ.rows.map(r => `${r.parish.replace(' Parish', '')}=${r.shared_with}`).join(' · ')})`);
  console.log(`  smallest true share on a split parish: ` +
    `${Math.min(...splitQ.rows.map(r => Number(r.smallest_share)))}% ` +
    `(the floor for counting a parish as split is ${SHARE_FLOOR}%)`);

  const zctas = await client.query(
    `SELECT count(*) zctas, count(*) FILTER (WHERE k=1) one, count(*) FILTER (WHERE k=0) none,
            count(*) FILTER (WHERE k>1) many
       FROM (SELECT (SELECT count(*) FROM essentials.geofence_boundaries s
                      WHERE s.mtfcc=$1 AND s.state=$2
                        AND public.ST_Covers(s.geometry, public.ST_PointOnSurface(z.geometry))) k
               FROM essentials.geofence_boundaries z WHERE z.state=$2 AND z.mtfcc='G6350') q`, [MTFCC, STATE_FIPS]);
  const zc = zctas.rows[0];
  if (Number(zc.zctas) < 500) fail(`the ZCTA gate examined only ${zc.zctas} rows`);
  if (Number(zc.none) !== 0 || Number(zc.many) !== 0) {
    fail(`${zc.none} Louisiana ZCTA(s) fall in NO district and ${zc.many} in more than one`);
  }
  console.log(`all ${zc.zctas} Louisiana ZCTAs resolve to exactly one district`);

  const areas = await client.query(
    `SELECT replace(geo_id,$3,'') d, round((public.ST_Area(geometry::geography)/2589988.11)::numeric) sq_miles
       FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND state=$2 ORDER BY geo_id`,
    [MTFCC, STATE_FIPS, PREFIX]);
  const totalSqMi = areas.rows.reduce((s, r) => s + Number(r.sq_miles), 0);
  console.log(`areas (sq mi): ${areas.rows.map(r => `${r.d}=${r.sq_miles}`).join(' ')} · total ${totalSqMi}`);
  ok = true;
} finally {
  if (ok && !DRY_RUN) { await client.query('COMMIT'); console.log('COMMITTED'); }
  else { await client.query('ROLLBACK'); console.log(ok ? 'DRY RUN OK — rolled back' : 'ROLLED BACK'); }
  await client.end();
}
