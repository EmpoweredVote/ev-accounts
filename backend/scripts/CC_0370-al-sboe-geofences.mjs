#!/usr/bin/env node
/**
 * CC_0370-al-sboe-geofences.mjs — Alabama's eight State Board of Education districts
 * -> essentials.geofence_boundaries as mtfcc='X0003',
 *    geo_id 'ocd-division/country:us/state:al/sboe:1'..':8'.
 * Run BEFORE migration CC_0370, whose districts point at these rows.
 *
 * PROVENANCE: the Alabama Legislative Reapportionment Office's ArcGIS feature service
 *   _2021_Alabama_State_Bd_of_Education — the 2021 plan, which is the whole of Code of Alabama
 *   § 16-3-1.1. Fetched and parsed by scripts/CC_0370-fetch-al-sboe-arcgis.mjs, whose header
 *   carries the service URL, the per-district sha256 digests and why this service and not the
 *   two unattributed copies of the same plan on ArcGIS Online.
 *
 * 🔴 THE SERVICE IS WEB MERCATOR (EPSG:3857). The fetch asks for outSR=4326 and bounds-checks
 *   every one of the 71,244 coordinate pairs against Alabama; this loader checks each polygon's
 *   bounding box again after INSERT. Taken as served and labelled 4326, the metres would be
 *   valid, correctly shaped polygons matching no address on Earth — the Holladay failure.
 *
 * WHY mtfcc X0003 AND NOT A NEW LAYER. districtQueries.ts and geoIdGuard.ts already admit
 *   (X0003, STATE_BOARD_EDUCATION) for Utah's, Colorado's and Texas's boards, and that rule is
 *   NOT state-scoped, so these rows join with no read-path change. The geo_id carries the state,
 *   so nothing collides.
 *
 * STOP GUARDS (all inside the insert transaction, against the inserted rows):
 *   - exactly 8 rows, districts 1..8, each once;
 *   - every geometry SRID 4326, valid, non-empty, and inside the Alabama bounding box;
 *   - the union covers at least 99.5% of our TIGER Alabama state outline (G4000 '01').
 *     Independent geometry the official map has to reproduce;
 *   - no two districts overlap by more than 0.001% of the smaller;
 *   - 🟢 THE STATUTE GATE. Code of Alabama § 16-3-1.1 names, county by county, what is in each
 *     district. 62 of Alabama's 67 counties are assigned whole; the other five are split by
 *     census tract and block. So: each of the 62 must lie inside the one district the statute
 *     names, and each of the 5 must be shared by EXACTLY the districts the statute names and no
 *     others. This is the law itself, written before this GIS file was made, and it is the only
 *     check here that can catch two districts' geometries being SWAPPED — a label swap passes
 *     every structural test (the Texas control C lesson).
 *     ⚠ IT IS AN AREA TEST, NOT ST_Covers, AND THAT WAS MEASURED BEFORE IT WAS CHOSEN. Strict
 *       ST_Covers failed on 55 of the 62, because the plan's line work and TIGER's disagree by
 *       slivers along shared boundaries. Measured against production: every whole county is
 *       99.9966%–100% inside its statutory district, and the largest sliver that leaks into any
 *       OTHER district is 0.0034% (Bullock into D2). The thresholds below — 99.9% in, 0.01% out
 *       — therefore sit about 30x clear of both. The five splits are real: Mobile D1 50.68% /
 *       D5 49.31%, Jefferson D4 45.88% / D7 42.54% / D3 11.58%, Montgomery D5 88.67% / D3
 *       11.33%, Talladega D6 87.71% / D3 12.29%, Tuscaloosa D4 56.31% / D7 43.69%. The smallest
 *       true share is 11.33% and the largest sliver on a split county is 0.0023%, so the 0.5%
 *       floor cannot confuse the two;
 *   - all 656 Alabama ZCTAs (G6350) resolve to exactly one district by interior point.
 *     ⚠ Alabama has no G4110 incorporated places in production, which is what Texas used; the
 *       ZCTAs are the point-resolution population available here, and the counties above are
 *       the stronger test in any case because they tile the state exactly.
 *
 * ON CONFLICT (geo_id, mtfcc) DO NOTHING, so a re-run inserts nothing.
 *
 * Usage (from backend/):
 *   node scripts/CC_0370-al-sboe-geofences.mjs --geojson <path> --dry-run   # every guard, then ROLLBACK
 *   node scripts/CC_0370-al-sboe-geofences.mjs --geojson <path>             # same, then COMMIT
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const MTFCC = 'X0003';
const STATE_FIPS = '01';
const SOURCE = 'al_reapportionment_2021_sboe_plan';
const PREFIX = 'ocd-division/country:us/state:al/sboe:';
const GEOID = n => `${PREFIX}${n}`;

const DRY_RUN = process.argv.includes('--dry-run');
const gi = process.argv.indexOf('--geojson');
const GEOJSON_PATH = gi > -1 ? process.argv[gi + 1] : undefined;
if (!GEOJSON_PATH) throw new Error('--geojson <path> is required');

/**
 * Code of Alabama § 16-3-1.1, as enacted in the 2021 First Special Session (the "McClendon SBOE
 * Plan 1"). Transcribed from the Legislature's own bill text,
 * https://www.legislature.state.al.us/pdf/2021-Reapportionment/BlockInfo/
 *   2021_Alabama_State_Bd_of_Education_Bill_Text.pdf
 * (149,869 bytes, sha256 a227996ae40943a8fca4fe33b99adb67a734993955b3690be9ba5a4c44b38ab9,
 *  downloaded 2026-11-07), which lists each district as a set of whole counties followed by the
 * tracts and blocks of the counties it splits.
 *
 * ⚠ District 5's header reads "… Wilcox County, Mo County:" in the published text. It is Mobile:
 *   the tract list that follows runs 2.00–35.01 and District 1's runs 31.00–70.00, which is one
 *   county divided between two districts, and Montgomery is named separately in the same section
 *   with its own tracts. The gate below tests that reading rather than assuming it — if Mobile's
 *   other half is in some other district, this file stops.
 */
const WHOLE = {
  1: ['Baldwin', 'Butler', 'Coffee', 'Conecuh', 'Covington', 'Crenshaw', 'Escambia'],
  2: ['Barbour', 'Chambers', 'Clay', 'Cleburne', 'Dale', 'Geneva', 'Henry', 'Houston', 'Lee',
    'Pike', 'Randolph', 'Russell', 'Tallapoosa'],
  3: ['Bibb', 'Chilton', 'Coosa', 'Elmore', 'Shelby'],
  4: ['Greene', 'Hale', 'Pickens'],
  5: ['Autauga', 'Bullock', 'Choctaw', 'Clarke', 'Dallas', 'Lowndes', 'Macon', 'Marengo',
    'Monroe', 'Perry', 'Sumter', 'Washington', 'Wilcox'],
  6: ['Blount', 'Calhoun', 'Cherokee', 'Cullman', 'Etowah', 'Marshall', 'St. Clair'],
  7: ['Colbert', 'Fayette', 'Franklin', 'Lamar', 'Lauderdale', 'Lawrence', 'Marion', 'Morgan',
    'Walker', 'Winston'],
  8: ['DeKalb', 'Jackson', 'Limestone', 'Madison'],
};
const SPLIT = {
  Mobile: [1, 5],
  Jefferson: [3, 4, 7],
  Montgomery: [3, 5],
  Talladega: [3, 6],
  Tuscaloosa: [4, 7],
};
// A county counts as being SPLIT into a district only if this much of its area is (percent).
// Measured: smallest true share 11.33%, largest sliver on a split county 0.0023%.
const SHARE_FLOOR = 0.5;
// A whole county must be at least this much inside its statutory district, and no more than
// LEAK_CEILING in any other. Measured: worst 99.9966% in, worst 0.0034% out.
const WHOLE_FLOOR = 99.9;
const LEAK_CEILING = 0.01;

const wholeList = Object.entries(WHOLE).flatMap(([d, cs]) => cs.map(c => [Number(d), `${c} County`]));
const splitList = Object.entries(SPLIT).map(([c, ds]) => [`${c} County`, ds.slice().sort((a, b) => a - b)]);
if (wholeList.length !== 62) throw new Error(`the statute table holds ${wholeList.length} whole counties, expected 62`);
if (wholeList.length + splitList.length !== 67) throw new Error('the statute table does not cover Alabama\'s 67 counties');

const GEOM = `public.ST_Multi(public.ST_CollectionExtract(public.ST_MakeValid(
  public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($2)), 4326)), 3))`;

const data = JSON.parse(fs.readFileSync(GEOJSON_PATH, 'utf8'));
if (!Array.isArray(data.districts) || data.districts.length !== 8) {
  throw new Error(`expected 8 districts in ${GEOJSON_PATH}, found ${data.districts?.length}`);
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
      [GEOID(d.district), JSON.stringify(d.geojson), `Alabama State Board of Education District ${d.district}`,
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
  if (DRY_RUN && inserted !== 8) {
    fail(`a dry run inserted ${inserted} of 8 rows — the rest are already in the table, so `
      + 'the gates below would be checking those and not this file. Delete them first, or run '
      + 'the controls before the real load.');
  }

  // 🔴 NOTHING THAT NEEDS LON/LAT TO BE LON/LAT MAY RUN BEFORE THE CRS GUARD. The first version
  //   of this query also computed each district's area in square miles with a ::geography cast
  //   for the log line, and the Web Mercator control then died inside PostGIS —
  //   "lwgeom_area_spher(oid) returned area < 0.0" — before the bounding-box check was reached.
  //   The control failed, the transaction rolled back, and the guard it was written to test had
  //   never run. A gate that a shadowing crash gets to first is not a tested gate. Areas are
  //   measured further down, once the geometry is known to be lon/lat.
  const rows = await client.query(
    `SELECT geo_id, public.ST_SRID(geometry) srid, public.ST_IsValid(geometry) valid,
            public.ST_IsEmpty(geometry) empty,
            public.ST_XMin(geometry) xmin, public.ST_XMax(geometry) xmax,
            public.ST_YMin(geometry) ymin, public.ST_YMax(geometry) ymax
       FROM essentials.geofence_boundaries WHERE mtfcc = $1 AND state = $2 ORDER BY geo_id`, [MTFCC, STATE_FIPS]);
  if (rows.rowCount !== 8) fail(`${rows.rowCount} Alabama rows under ${MTFCC}, expected 8`);
  for (const r of rows.rows) {
    if (r.srid !== 4326) fail(`${r.geo_id} is SRID ${r.srid}`);
    if (!r.valid) fail(`${r.geo_id} is not a valid geometry`);
    if (r.empty) fail(`${r.geo_id} is empty`);
    if (r.xmin < -89 || r.xmax > -84.5 || r.ymin < 29.5 || r.ymax > 35.5) {
      fail(`${r.geo_id} bbox ${r.xmin},${r.ymin} .. ${r.xmax},${r.ymax} is outside Alabama — WRONG CRS`);
    }
  }
  const nums = rows.rows.map(r => Number(r.geo_id.split(':').pop())).sort((a, b) => a - b);
  if (nums.join(',') !== '1,2,3,4,5,6,7,8') fail(`districts are ${nums.join(',')}`);
  console.log('8 districts, all SRID 4326, valid, non-empty and inside the Alabama bounding box');

  const cov = await client.query(
    `WITH u AS (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND state=$2),
          s AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='01')
     SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g)::geography)
                        / public.ST_Area(s.g::geography) * 100)::numeric, 3) AS pct_covered
       FROM u, s`, [MTFCC, STATE_FIPS]);
  const covered = Number(cov.rows[0].pct_covered);
  if (!(covered >= 99.5)) fail(`the 8 districts cover only ${covered}% of the Alabama state outline`);
  console.log(`union covers ${covered}% of the TIGER Alabama outline`);

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
  // 62 whole counties: at least WHOLE_FLOOR% inside the district § 16-3-1.1 names, and at most
  // LEAK_CEILING% in any other.
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
  if (wholeQ.rowCount !== 62) fail(`the whole-county gate examined ${wholeQ.rowCount} rows, not 62`);
  const missing = wholeQ.rows.filter(r => r.county_missing);
  if (missing.length) fail(`we hold no TIGER polygon for: ${missing.map(m => m.county).join(', ')}`);
  const shortfall = wholeQ.rows.filter(r => !(Number(r.pct_in_own) >= WHOLE_FLOOR));
  if (shortfall.length) {
    fail(`the statute puts these counties wholly in one district and the map does not: ` +
      shortfall.map(b => `${b.county} is only ${b.pct_in_own ?? 0}% in D${b.expect}`).join('; '));
  }
  const leaking = wholeQ.rows.filter(r => r.leaks);
  if (leaking.length) {
    fail(`a county the statute assigns whole reaches into another district by more than ` +
      `${LEAK_CEILING}%: ` + leaking.map(b => `${b.county} (statute D${b.expect}) also ${b.leaks}`).join('; '));
  }
  const worstWhole = Math.min(...wholeQ.rows.map(r => Number(r.pct_in_own)));
  console.log(`all 62 whole counties sit in exactly the district § 16-3-1.1 assigns them ` +
    `(worst ${worstWhole}% in, nothing over ${LEAK_CEILING}% out)`);

  // 5 split counties: shared by exactly the districts the statute names, none other.
  const splitQ = await client.query(
    `SELECT sp.county, sp.expect,
            (SELECT string_agg(replace(s.geo_id,$3,''), ',' ORDER BY s.geo_id::text)
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2
                AND public.ST_Area(public.ST_Intersection(s.geometry, co.geometry))
                    > public.ST_Area(co.geometry) * $4) AS shared_with
       FROM (VALUES ${splitList.map((_, i) => `($${i * 2 + 5}::text, $${i * 2 + 6}::text)`).join(',')}) AS sp(county, expect)
       JOIN essentials.geofence_boundaries co ON co.state=$2 AND co.mtfcc='G4020' AND co.name=sp.county`,
    [MTFCC, STATE_FIPS, PREFIX, SHARE_FLOOR / 100, ...splitList.flatMap(([c, ds]) => [c, ds.join(',')])]);
  if (splitQ.rowCount !== 5) fail(`the split-county gate examined ${splitQ.rowCount} rows, not 5`);
  const badSplit = splitQ.rows.filter(r => String(r.shared_with) !== String(r.expect));
  if (badSplit.length) {
    fail(`a county the statute splits is shared with the wrong districts: ` +
      badSplit.map(b => `${b.county} -> ${b.shared_with ?? 'nothing'}, statute says ${b.expect}`).join('; '));
  }
  console.log(`all 5 split counties are shared by exactly the districts § 16-3-1.1 names ` +
    `(${splitQ.rows.map(r => `${r.county.replace(' County', '')}=${r.shared_with}`).join(' · ')})`);

  // Point resolution across the state.
  const zctas = await client.query(
    `SELECT count(*) zctas, count(*) FILTER (WHERE k=1) one, count(*) FILTER (WHERE k=0) none,
            count(*) FILTER (WHERE k>1) many
       FROM (SELECT (SELECT count(*) FROM essentials.geofence_boundaries s
                      WHERE s.mtfcc=$1 AND s.state=$2
                        AND public.ST_Covers(s.geometry, public.ST_PointOnSurface(z.geometry))) k
               FROM essentials.geofence_boundaries z WHERE z.state=$2 AND z.mtfcc='G6350') q`, [MTFCC, STATE_FIPS]);
  const zc = zctas.rows[0];
  if (Number(zc.zctas) < 600) fail(`the ZCTA gate examined only ${zc.zctas} rows`);
  if (Number(zc.none) !== 0 || Number(zc.many) !== 0) {
    fail(`${zc.none} Alabama ZCTA(s) fall in NO district and ${zc.many} in more than one`);
  }
  console.log(`all ${zc.zctas} Alabama ZCTAs resolve to exactly one district`);

  const areas = await client.query(
    `SELECT replace(geo_id,$3,'') d, round((public.ST_Area(geometry::geography)/2589988.11)::numeric) sq_miles
       FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND state=$2 ORDER BY geo_id`,
    [MTFCC, STATE_FIPS, PREFIX]);
  const totalSqMi = areas.rows.reduce((s, r) => s + Number(r.sq_miles), 0);
  console.log(`areas (sq mi): ${areas.rows.map(r => `${r.d}=${r.sq_miles}`).join(' ')} · total ${totalSqMi} ` +
    `(Alabama is 52,420)`);
  ok = true;
} finally {
  if (ok && !DRY_RUN) { await client.query('COMMIT'); console.log('COMMITTED'); }
  else { await client.query('ROLLBACK'); console.log(ok ? 'DRY RUN OK — rolled back' : 'ROLLED BACK'); }
  await client.end();
}
