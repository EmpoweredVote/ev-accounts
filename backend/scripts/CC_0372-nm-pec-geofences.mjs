#!/usr/bin/env node
/**
 * CC_0372-nm-pec-geofences.mjs — New Mexico's ten Public Education Commission districts
 * -> essentials.geofence_boundaries as mtfcc='X0003',
 *    geo_id 'ocd-division/country:us/state:nm/pec:1'..':10'.
 * Run BEFORE migration CC_0372, whose districts point at these rows.
 *
 * PROVENANCE: the New Mexico Secretary of State's redistricting GIS (UNM EDAC), layer
 *   SOS/Education/MapServer/8 — the HB 9 plan, Laws 2021 (2nd S.S.) Chapter 3. Fetched and
 *   parsed by scripts/CC_0372-fetch-nm-pec-arcgis.mjs, whose header carries the service URL, the
 *   per-district sha256 digests, the population check that identifies it as the 2020-census
 *   plan, and the note that HB 6 and HB 7 — the two PEC bills a search finds first — both died.
 *
 * 🔴 THE SERVICE IS NAD83 / UTM 13N (EPSG:26913), in metres. The fetch asks for outSR=4326 and
 *   bounds-checks all 83,186 coordinate pairs against New Mexico; this loader checks each
 *   polygon's bounding box again after INSERT.
 *
 * WHY mtfcc X0003. The Public Education Commission IS a state board of education, so these rows
 *   join on the (X0003, STATE_BOARD_EDUCATION) rule already in districtQueries.ts and
 *   geoIdGuard.ts — which is not state-scoped and IS deployed. No read-path change, and these
 *   seats answer an address as soon as the data is there.
 *
 * STOP GUARDS (all inside the insert transaction, against the inserted rows):
 *   - exactly 10 rows, districts 1..10, each once;
 *   - every geometry SRID 4326, valid, non-empty, inside the New Mexico bounding box. 🔴 This
 *     runs before anything that needs lon/lat to BE lon/lat — CC_0370 lost a CRS control to a
 *     ::geography area in the same SELECT, which crashed PostGIS first;
 *   - the union covers at least 99.5% of our TIGER New Mexico state outline (G4000 '35');
 *   - no two districts overlap by more than 0.001% of the smaller;
 *   - 🟢 THE STATUTE GATE. HB 9 defines each district as a list of counties, naming a county
 *     either whole ("Catron county;") or by precinct ("Cibola county precincts 1, 7 and 15;").
 *     23 of New Mexico's 33 counties are assigned whole and 10 are split. Each whole county must
 *     lie inside the one district the act names, and each split county must be shared by exactly
 *     the districts it names. This is the only check here that can catch two districts'
 *     geometries being SWAPPED — a label swap passes every structural test (CC_0369 control C);
 *   - all 372 New Mexico ZCTAs (G6350) resolve to exactly one district.
 *     ⚠ New Mexico, like Alabama and Louisiana, has no G4110 incorporated places in production.
 *
 * ⚠ BERNALILLO COUNTY IS SPLIT SIX WAYS and three districts (1, 2 and 3) lie entirely inside it,
 *   so the split arm of the gate carries most of the weight in the Albuquerque metro. The
 *   whole-county arm covers the other 23 counties and every district except 1, 2 and 3.
 *
 * ON CONFLICT (geo_id, mtfcc) DO NOTHING, so a re-run inserts nothing.
 *
 * Usage (from backend/):
 *   node scripts/CC_0372-nm-pec-geofences.mjs --geojson <path> --dry-run   # every guard, then ROLLBACK
 *   node scripts/CC_0372-nm-pec-geofences.mjs --geojson <path>             # same, then COMMIT
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const MTFCC = 'X0003';
const STATE_FIPS = '35';
const SOURCE = 'nm_hb9_2021_2ss_pec_plan';
const PREFIX = 'ocd-division/country:us/state:nm/pec:';
const GEOID = n => `${PREFIX}${n}`;
const COUNTIES = 'data/state-exec-2026-results/nm-pec-counties-2026-11-07.json';

const DRY_RUN = process.argv.includes('--dry-run');
const gi = process.argv.indexOf('--geojson');
const GEOJSON_PATH = gi > -1 ? process.argv[gi + 1] : undefined;
if (!GEOJSON_PATH) throw new Error('--geojson <path> is required');

// 🔴 THE SPLIT FLOOR IS 0.05% HERE, NOT THE 0.5% ALABAMA AND LOUISIANA USED, AND THE DIFFERENCE
//    IS A REAL FACT ABOUT NEW MEXICO. Otero County's District 7 slice — the Chaparral end, next
//    to Doña Ana — is **0.4962%** of the county, and at a 0.5% floor the gate reported
//    "Otero County -> 9, HB 9 says 7,9" and refused a map that was correct. Measured against
//    production: the smallest TRUE share is that 0.4962%, and every false share (a county
//    grazing a district it is not in) is 0.000000% to six decimal places, because this plan
//    shares TIGER's county line work exactly. 0.05% therefore sits ten times below the smallest
//    real split and far above anything spurious.
//    ▶ A threshold carried over from another state is a guess. Measure the distribution first.
const SHARE_FLOOR = 0.05;  // a county counts as split into a district only above this share
const WHOLE_FLOOR = 99.9;  // a whole county must be at least this much inside its own district
const LEAK_CEILING = 0.01; // and at most this much in any other

const comp = JSON.parse(fs.readFileSync(COUNTIES, 'utf8'));
const wholeList = comp.whole.map(w => [w.district, w.county]);
const splitList = comp.split.map(s => [s.county, s.districts.slice().sort((a, b) => a - b)]);
if (wholeList.length !== 23) throw new Error(`${COUNTIES} holds ${wholeList.length} whole counties, expected 23`);
if (splitList.length !== 10) throw new Error(`${COUNTIES} holds ${splitList.length} split counties, expected 10`);
if (wholeList.length + splitList.length !== 33) throw new Error('the county table does not cover New Mexico\'s 33 counties');

const GEOM = `public.ST_Multi(public.ST_CollectionExtract(public.ST_MakeValid(
  public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($2)), 4326)), 3))`;

const data = JSON.parse(fs.readFileSync(GEOJSON_PATH, 'utf8'));
if (!Array.isArray(data.districts) || data.districts.length !== 10) {
  throw new Error(`expected 10 districts in ${GEOJSON_PATH}, found ${data.districts?.length}`);
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
      [GEOID(d.district), JSON.stringify(d.geojson), `New Mexico Public Education Commission District ${d.district}`,
        STATE_FIPS, MTFCC, SOURCE]);
    inserted += r.rowCount;
  }
  console.log();

  console.log(`inserted ${inserted} row(s)`);

  // 🔴🔴 A DRY RUN THAT INSERTS NOTHING CHECKS ROWS THAT WERE ALREADY THERE, AND EVERY GATE
  //   BELOW THEN PASSES ON DATA THIS FILE DID NOT SUPPLY. The ON CONFLICT DO NOTHING above is
  //   what makes a real re-run idempotent, and it is also what makes a tampered dry run
  //   VACUOUS once the correct polygons are committed: CC_0372's CRS control and its
  //   label-swap control both reported "DRY RUN OK" that way, with "inserted 0 row(s)" one
  //   line above. A dry run is a rehearsal of the insert, so it has to actually insert.
  if (DRY_RUN && inserted !== 10) {
    fail(`a dry run inserted ${inserted} of 10 rows — the rest are already in the table, so `
      + 'the gates below would be checking those and not this file. Delete them first, or run '
      + 'the controls before the real load.');
  }

  const rows = await client.query(
    `SELECT geo_id, public.ST_SRID(geometry) srid, public.ST_IsValid(geometry) valid,
            public.ST_IsEmpty(geometry) empty,
            public.ST_XMin(geometry) xmin, public.ST_XMax(geometry) xmax,
            public.ST_YMin(geometry) ymin, public.ST_YMax(geometry) ymax
       FROM essentials.geofence_boundaries WHERE mtfcc = $1 AND state = $2 ORDER BY geo_id`, [MTFCC, STATE_FIPS]);
  if (rows.rowCount !== 10) fail(`${rows.rowCount} New Mexico rows under ${MTFCC}, expected 10`);
  for (const r of rows.rows) {
    if (r.srid !== 4326) fail(`${r.geo_id} is SRID ${r.srid}`);
    if (!r.valid) fail(`${r.geo_id} is not a valid geometry`);
    if (r.empty) fail(`${r.geo_id} is empty`);
    if (r.xmin < -110 || r.xmax > -102 || r.ymin < 30.5 || r.ymax > 37.5) {
      fail(`${r.geo_id} bbox ${r.xmin},${r.ymin} .. ${r.xmax},${r.ymax} is outside New Mexico — WRONG CRS`);
    }
  }
  const nums = rows.rows.map(r => Number(r.geo_id.split(':').pop())).sort((a, b) => a - b);
  if (nums.join(',') !== '1,2,3,4,5,6,7,8,9,10') fail(`districts are ${nums.join(',')}`);
  console.log('10 districts, all SRID 4326, valid, non-empty and inside the New Mexico bounding box');

  const cov = await client.query(
    `WITH u AS (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND state=$2),
          s AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='35')
     SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g)::geography)
                        / public.ST_Area(s.g::geography) * 100)::numeric, 3) AS pct_covered
       FROM u, s`, [MTFCC, STATE_FIPS]);
  const covered = Number(cov.rows[0].pct_covered);
  if (!(covered >= 99.5)) fail(`the 10 districts cover only ${covered}% of the New Mexico state outline`);
  console.log(`union covers ${covered}% of the TIGER New Mexico outline`);

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

  // ─── 🟢 THE STATUTE GATE ───
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
              WHERE s.mtfcc=$1 AND s.state=$2 AND s.geo_id <> $3 || w.expect::text
                AND public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                    > public.ST_Area(co.geometry) * $4) AS leaks
       FROM (VALUES ${wholeList.map((_, i) => `($${i * 2 + 5}::int, $${i * 2 + 6}::text)`).join(',')}) AS w(expect, county)
       LEFT JOIN essentials.geofence_boundaries co ON co.state=$2 AND co.mtfcc='G4020' AND co.name=w.county`,
    [MTFCC, STATE_FIPS, PREFIX, LEAK_CEILING / 100, ...wholeList.flatMap(([d, c]) => [d, c])]);
  if (wholeQ.rowCount !== 23) fail(`the whole-county gate examined ${wholeQ.rowCount} rows, not 23`);
  const missing = wholeQ.rows.filter(r => r.county_missing);
  if (missing.length) fail(`we hold no TIGER polygon for: ${missing.map(m => m.county).join(', ')}`);
  const shortfall = wholeQ.rows.filter(r => !(Number(r.pct_in_own) >= WHOLE_FLOOR));
  if (shortfall.length) {
    fail(`HB 9 puts these counties wholly in one district and the map does not: ` +
      shortfall.map(b => `${b.county} is only ${b.pct_in_own ?? 0}% in D${b.expect}`).join('; '));
  }
  const leaking = wholeQ.rows.filter(r => r.leaks);
  if (leaking.length) {
    fail(`a county HB 9 assigns whole reaches into another district by more than ${LEAK_CEILING}%: ` +
      leaking.map(b => `${b.county} (HB 9 D${b.expect}) also ${b.leaks}`).join('; '));
  }
  const worstWhole = Math.min(...wholeQ.rows.map(r => Number(r.pct_in_own)));
  console.log(`all 23 whole counties sit in exactly the district HB 9 assigns them ` +
    `(worst ${worstWhole}% in, nothing over ${LEAK_CEILING}% out)`);

  const splitQ = await client.query(
    `SELECT sp.county, sp.expect,
            (SELECT string_agg(replace(s.geo_id,$3,''), ',' ORDER BY (replace(s.geo_id,$3,''))::int)
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
       FROM (VALUES ${splitList.map((_, i) => `($${i * 2 + 5}::text, $${i * 2 + 6}::text)`).join(',')}) AS sp(county, expect)
       JOIN essentials.geofence_boundaries co ON co.state=$2 AND co.mtfcc='G4020' AND co.name=sp.county`,
    [MTFCC, STATE_FIPS, PREFIX, SHARE_FLOOR / 100, ...splitList.flatMap(([c, ds]) => [c, ds.join(',')])]);
  if (splitQ.rowCount !== 10) fail(`the split-county gate examined ${splitQ.rowCount} rows, not 10`);
  const badSplit = splitQ.rows.filter(r => String(r.shared_with) !== String(r.expect));
  if (badSplit.length) {
    fail(`a county HB 9 splits is shared with the wrong districts: ` +
      badSplit.map(b => `${b.county} -> ${b.shared_with ?? 'nothing'}, HB 9 says ${b.expect}`).join('; '));
  }
  console.log(`all 10 split counties are shared by exactly the districts HB 9 names ` +
    `(${splitQ.rows.map(r => `${r.county.replace(' County', '')}=${r.shared_with}`).join(' · ')})`);
  console.log(`  smallest true share on a split county: ` +
    `${Math.min(...splitQ.rows.map(r => Number(r.smallest_share)))}% (floor ${SHARE_FLOOR}%)`);

  const zctas = await client.query(
    `SELECT count(*) zctas, count(*) FILTER (WHERE k=1) one, count(*) FILTER (WHERE k=0) none,
            count(*) FILTER (WHERE k>1) many
       FROM (SELECT (SELECT count(*) FROM essentials.geofence_boundaries s
                      WHERE s.mtfcc=$1 AND s.state=$2
                        AND public.ST_Covers(s.geometry, public.ST_PointOnSurface(z.geometry))) k
               FROM essentials.geofence_boundaries z WHERE z.state=$2 AND z.mtfcc='G6350') q`, [MTFCC, STATE_FIPS]);
  const zc = zctas.rows[0];
  if (Number(zc.zctas) < 300) fail(`the ZCTA gate examined only ${zc.zctas} rows`);
  if (Number(zc.none) !== 0 || Number(zc.many) !== 0) {
    fail(`${zc.none} New Mexico ZCTA(s) fall in NO district and ${zc.many} in more than one`);
  }
  console.log(`all ${zc.zctas} New Mexico ZCTAs resolve to exactly one district`);

  const areas = await client.query(
    `SELECT replace(geo_id,$3,'') d, round((public.ST_Area(geometry::geography)/2589988.11)::numeric) sq_miles
       FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND state=$2 ORDER BY (replace(geo_id,$3,''))::int`,
    [MTFCC, STATE_FIPS, PREFIX]);
  const totalSqMi = areas.rows.reduce((s, r) => s + Number(r.sq_miles), 0);
  console.log(`areas (sq mi): ${areas.rows.map(r => `${r.d}=${r.sq_miles}`).join(' ')} · total ${totalSqMi}`);
  ok = true;
} finally {
  if (ok && !DRY_RUN) { await client.query('COMMIT'); console.log('COMMITTED'); }
  else { await client.query('ROLLBACK'); console.log(ok ? 'DRY RUN OK — rolled back' : 'ROLLED BACK'); }
  await client.end();
}
