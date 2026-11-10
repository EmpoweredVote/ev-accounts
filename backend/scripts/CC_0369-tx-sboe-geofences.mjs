#!/usr/bin/env node
/**
 * CC_0369-tx-sboe-geofences.mjs — Texas's fifteen State Board of Education districts
 * -> essentials.geofence_boundaries as mtfcc='X0003',
 *    geo_id 'ocd-division/country:us/state:tx/sboe:1'..':15'.
 * Run BEFORE migration CC_0369, whose districts point at these rows.
 *
 * PROVENANCE: PLANE2106, "STATE BOARD OF EDUCATION DISTRICTS, JANUARY 2023", the plan in force,
 *   from the Texas Legislative Council's Capitol Data Portal. The KML is converted to GeoJSON by
 *   scripts/CC_0369-parse-plane2106-kml.mjs, whose header carries the URLs, byte counts and
 *   sha256 digests. 🔴 THE KML, NOT THE SHAPEFILE: the shapefile in the same dataset is
 *   Texas-centric Lambert Conformal Conic in METRES, and loaded as 4326 it would be a valid,
 *   correctly shaped polygon matching no address on Earth.
 *
 * WHY mtfcc X0003 AND NOT A NEW LAYER. districtQueries.ts and geoIdGuard.ts already admit
 *   (X0003, STATE_BOARD_EDUCATION) for Utah's board, and that rule is NOT state-scoped, so these
 *   rows join with no read-path change. The geo_id carries the state, so nothing collides.
 *
 * STOP GUARDS (all inside the insert transaction, against the inserted rows):
 *   - exactly 15 rows, districts 1..15, each once;
 *   - every geometry SRID 4326, valid, non-empty, and inside the Texas bounding box;
 *   - the union covers at least 99.5% of our TIGER Texas state outline (G4000 '48').
 *     Measured 2026-11-07: 99.890%. This is the positive control — independent geometry the
 *     official map has to reproduce;
 *   - no two districts overlap by more than 0.001% of the smaller. Measured: 0.000000%;
 *   - all 1,228 Texas incorporated places (G4110) resolve to EXACTLY ONE district by interior
 *     point — none to zero, none to two. This is the question a voter actually asks;
 *   - nine board members' home towns lie WHOLLY inside the district they represent. The board's
 *     own roster gives the town and Texas law requires a member to be a bona fide resident of
 *     the district, so this is independent of the map being checked.
 *     ⚠ Six members' towns are split across districts and cannot anchor anything: El Paso,
 *       San Antonio, Pasadena, Houston, Pearland and Frisco. Measured, not assumed — Houston
 *       touches districts 4, 6, 7 and 8, and an interior point of it lands in 4.
 *
 * ON CONFLICT (geo_id, mtfcc) DO NOTHING, so a re-run inserts nothing.
 *
 * Usage (from backend/):
 *   node scripts/CC_0369-tx-sboe-geofences.mjs --geojson <path> --dry-run   # every guard, then ROLLBACK
 *   node scripts/CC_0369-tx-sboe-geofences.mjs --geojson <path>             # same, then COMMIT
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const MTFCC = 'X0003';
const STATE_FIPS = '48';
const SOURCE = 'tlc_plane2106_2023';
const GEOID = n => `ocd-division/country:us/state:tx/sboe:${n}`;

const DRY_RUN = process.argv.includes('--dry-run');
const gi = process.argv.indexOf('--geojson');
const GEOJSON_PATH = gi > -1 ? process.argv[gi + 1] : undefined;
if (!GEOJSON_PATH) throw new Error('--geojson <path> is required');

// (district, TIGER place name) for the nine member towns that lie wholly in one district.
const ANCHORS = [
  [2, 'Corpus Christi city'], [5, 'San Marcos city'], [8, 'Trinity city'], [9, 'Lufkin city'],
  [10, 'Florence city'], [11, 'Aledo city'], [12, 'Fairview town'], [13, 'DeSoto city'],
  [15, 'Midland city'],
];

const GEOM = `public.ST_Multi(public.ST_CollectionExtract(public.ST_MakeValid(
  public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($2)), 4326)), 3))`;

const data = JSON.parse(fs.readFileSync(GEOJSON_PATH, 'utf8'));
if (!Array.isArray(data.districts) || data.districts.length !== 15) {
  throw new Error(`expected 15 districts in ${GEOJSON_PATH}, found ${data.districts?.length}`);
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
      [GEOID(d.district), JSON.stringify(d.geojson), `Texas State Board of Education District ${d.district}`,
        STATE_FIPS, MTFCC, SOURCE]);
    inserted += r.rowCount;
  }
  console.log(`inserted ${inserted} row(s)`);

  const rows = await client.query(
    `SELECT geo_id, public.ST_SRID(geometry) srid, public.ST_IsValid(geometry) valid,
            public.ST_IsEmpty(geometry) empty,
            round((public.ST_Area(geometry::geography)/2589988.11)::numeric) sq_miles,
            public.ST_XMin(geometry) xmin, public.ST_XMax(geometry) xmax,
            public.ST_YMin(geometry) ymin, public.ST_YMax(geometry) ymax
       FROM essentials.geofence_boundaries WHERE mtfcc = $1 AND state = $2 ORDER BY geo_id`, [MTFCC, STATE_FIPS]);
  if (rows.rowCount !== 15) fail(`${rows.rowCount} Texas rows under ${MTFCC}, expected 15`);
  for (const r of rows.rows) {
    if (r.srid !== 4326) fail(`${r.geo_id} is SRID ${r.srid}`);
    if (!r.valid) fail(`${r.geo_id} is not a valid geometry`);
    if (r.empty) fail(`${r.geo_id} is empty`);
    if (r.xmin < -107 || r.xmax > -93 || r.ymin < 25 || r.ymax > 37) {
      fail(`${r.geo_id} bbox ${r.xmin},${r.ymin} .. ${r.xmax},${r.ymax} is outside Texas — WRONG CRS`);
    }
  }
  const nums = rows.rows.map(r => Number(r.geo_id.split(':').pop())).sort((a, b) => a - b);
  if (nums.join(',') !== Array.from({ length: 15 }, (_, i) => i + 1).join(',')) fail(`districts are ${nums.join(',')}`);
  console.log('15 districts, all SRID 4326, valid, non-empty and inside the Texas bounding box');

  const cov = await client.query(
    `WITH u AS (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND state=$2),
          s AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='48')
     SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g)::geography)
                        / public.ST_Area(s.g::geography) * 100)::numeric, 3) AS pct_of_texas_covered
       FROM u, s`, [MTFCC, STATE_FIPS]);
  const covered = Number(cov.rows[0].pct_of_texas_covered);
  if (!(covered >= 99.5)) fail(`the 15 districts cover only ${covered}% of the Texas state outline`);
  console.log(`union covers ${covered}% of the TIGER Texas outline`);

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

  const places = await client.query(
    `SELECT count(*) places, count(*) FILTER (WHERE k=1) one, count(*) FILTER (WHERE k=0) none,
            count(*) FILTER (WHERE k>1) many
       FROM (SELECT (SELECT count(*) FROM essentials.geofence_boundaries s
                      WHERE s.mtfcc=$1 AND s.state=$2
                        AND public.ST_Covers(s.geometry, public.ST_PointOnSurface(p.geometry))) k
               FROM essentials.geofence_boundaries p WHERE p.state=$2 AND p.mtfcc='G4110') z`, [MTFCC, STATE_FIPS]);
  const pl = places.rows[0];
  if (Number(pl.none) !== 0 || Number(pl.many) !== 0) {
    fail(`${pl.none} Texas place(s) fall in NO district and ${pl.many} in more than one`);
  }
  console.log(`all ${pl.places} Texas incorporated places resolve to exactly one district`);

  const anc = await client.query(
    `SELECT a.expect, a.town,
            (SELECT string_agg(replace(s.geo_id,'ocd-division/country:us/state:tx/sboe:',''), ',' ORDER BY s.geo_id)
               FROM essentials.geofence_boundaries s
              WHERE s.mtfcc=$1 AND s.state=$2 AND public.ST_Covers(s.geometry, p.geometry)) AS wholly_in
       FROM (VALUES ${ANCHORS.map((_, i) => `($${i * 2 + 3}::int, $${i * 2 + 4}::text)`).join(',')}) AS a(expect, town)
       LEFT JOIN essentials.geofence_boundaries p ON p.state=$2 AND p.mtfcc='G4110' AND p.name=a.town`,
    [MTFCC, STATE_FIPS, ...ANCHORS.flat()]);
  const bad = anc.rows.filter(r => String(r.wholly_in) !== String(r.expect));
  if (bad.length) fail(`anchor town(s) not wholly inside their member's district: ${bad.map(b => `${b.town} -> ${b.wholly_in}, expected ${b.expect}`).join('; ')}`);
  console.log(`all ${anc.rowCount} anchor towns lie wholly inside the district their board member represents`);

  ok = true;
} finally {
  if (ok && !DRY_RUN) { await client.query('COMMIT'); console.log('COMMITTED'); }
  else { await client.query('ROLLBACK'); console.log(ok ? 'DRY RUN OK — rolled back' : 'ROLLED BACK'); }
  await client.end();
}
