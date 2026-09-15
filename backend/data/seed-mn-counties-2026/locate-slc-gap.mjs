/**
 * WHERE is the 122 sq mi of St. Louis County that its commissioner districts do not cover?
 *
 * 98.220% is below the 99.9% MN-3 used, and a number alone cannot say whether that is a defect.
 * Fort Wayne's districts legitimately fell short of its place polygon (unincorporated county) and
 * Bradenton's ward layer was land-only, so the gate there ran against TIGER AREALAND rather than
 * the polygon. Either could apply here — or the layer could be the wrong map, which is what the
 * gate exists to catch. Measure where the hole IS before deciding.
 */
import fs from 'fs';
import pg from 'pg';

const gj = JSON.parse(fs.readFileSync('_slc-districts.geojson', 'utf8'));
const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();
await c.query('BEGIN');
await c.query(`SET LOCAL statement_timeout = '300s'`);
await c.query(`CREATE TEMP TABLE d(num int, geom geometry) ON COMMIT DROP`);
for (const f of gj.features) {
  await c.query(`INSERT INTO d(num, geom) VALUES ($1, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($2),4326)))`,
    [Number(f.properties.DISTRICTID), JSON.stringify(f.geometry)]);
}
const q = async (s, p = []) => (await c.query(s, p)).rows;

console.log('-- the uncovered area, broken into pieces, largest first --');
for (const r of await q(`
  WITH u AS (SELECT ST_Union(geom) g FROM d),
       p AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id='27137' AND mtfcc='G4020'),
       gap AS (SELECT (ST_Dump(ST_Difference(p.g,u.g))).geom AS g FROM u,p)
  SELECT round((ST_Area(g::geography)/2589988.11)::numeric,3) AS sq_mi,
         round(ST_X(ST_PointOnSurface(g))::numeric,4) AS lon,
         round(ST_Y(ST_PointOnSurface(g))::numeric,4) AS lat
  FROM gap WHERE ST_Area(g::geography)/2589988.11 > 0.5
  ORDER BY sq_mi DESC LIMIT 12`)) {
  console.log(`  ${String(r.sq_mi).padStart(9)} sq mi at (${r.lon}, ${r.lat})`);
}

console.log('\n-- how many pieces, and how much is in the biggest one --');
const [s] = await q(`
  WITH u AS (SELECT ST_Union(geom) g FROM d),
       p AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id='27137' AND mtfcc='G4020'),
       gap AS (SELECT (ST_Dump(ST_Difference(p.g,u.g))).geom AS g FROM u,p)
  SELECT count(*) AS pieces,
         round((sum(ST_Area(g::geography))/2589988.11)::numeric,3) AS total_sq_mi,
         round((max(ST_Area(g::geography))/2589988.11)::numeric,3) AS biggest_sq_mi,
         count(*) FILTER (WHERE ST_Area(g::geography)/2589988.11 < 0.01) AS slivers
  FROM gap`);
console.log(`  ${s.pieces} piece(s), ${s.total_sq_mi} sq mi total, biggest ${s.biggest_sq_mi} sq mi, ${s.slivers} under 0.01 sq mi`);

console.log('\n-- does the gap touch Lake Superior? test the biggest piece against the state waters --');
for (const r of await q(`
  WITH u AS (SELECT ST_Union(geom) g FROM d),
       p AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id='27137' AND mtfcc='G4020'),
       gap AS (SELECT ST_Difference(p.g,u.g) g FROM u,p)
  SELECT round((ST_Area(gap.g::geography)/2589988.11)::numeric,3) AS gap_sq_mi,
         round(ST_XMin(gap.g)::numeric,4) AS xmin, round(ST_YMin(gap.g)::numeric,4) AS ymin,
         round(ST_XMax(gap.g)::numeric,4) AS xmax, round(ST_YMax(gap.g)::numeric,4) AS ymax
  FROM gap`)) {
  console.log(`  gap bbox: lon ${r.xmin}..${r.xmax}, lat ${r.ymin}..${r.ymax}  (${r.gap_sq_mi} sq mi)`);
}

await c.query('ROLLBACK');
await c.end();
