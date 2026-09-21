/**
 * Which Duluth council-district map is current — the 2012 one or the 2022 one?
 *
 * The City of Duluth publishes FIVE council districts numbered 1-5 in TWO different ArcGIS map
 * services, and 🔴 A COUNT PROVES NOTHING: both return exactly 5 features with the same numbers.
 *
 *   OLD  Precincts_Council_Boundaries_Duluth/MapServer/1   item modified 2021-01-08
 *   NEW  VotingDistricts/MapServer/16                      item modified 2023-03-09
 *
 * This script measures the symmetric difference per district in PostGIS, after ST_MakeValid,
 * because two digitisations of one boundary need a TOLERANCE, not ST_Equals.
 *
 *   node compare-duluth-vintages.mjs
 */
import fs from 'fs';
import pg from 'pg';

const old_ = JSON.parse(fs.readFileSync('_duluth-old.geojson', 'utf8'));
const new_ = JSON.parse(fs.readFileSync('_duluth-new.geojson', 'utf8'));

const key = (f, a, b) => f.properties[a] ?? f.properties[b];

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
await client.query('BEGIN');
await client.query(`CREATE TEMP TABLE d_old(dist int, geom geometry) ON COMMIT DROP`);
await client.query(`CREATE TEMP TABLE d_new(dist int, geom geometry, councilor text) ON COMMIT DROP`);

for (const f of old_.features) {
  await client.query(
    `INSERT INTO d_old(dist, geom) VALUES ($1, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($2), 4326)))`,
    [key(f, 'Cncl_Dist', 'CouncilDist'), JSON.stringify(f.geometry)],
  );
}
for (const f of new_.features) {
  await client.query(
    `INSERT INTO d_new(dist, geom, councilor) VALUES ($1, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($2), 4326)), $3)`,
    [key(f, 'CouncilDist', 'Cncl_Dist'), JSON.stringify(f.geometry), f.properties.Councilor ?? null],
  );
}

const q = async (sql) => (await client.query(sql)).rows;

console.log('--- per-district symmetric difference, square miles ---');
for (const r of await q(`
  SELECT o.dist,
         round((ST_Area(o.geom::geography)/2589988.11)::numeric,3) AS old_sq_mi,
         round((ST_Area(n.geom::geography)/2589988.11)::numeric,3) AS new_sq_mi,
         round((ST_Area(ST_SymDifference(o.geom, n.geom)::geography)/2589988.11)::numeric,3) AS symdiff_sq_mi,
         n.councilor
  FROM d_old o JOIN d_new n ON n.dist = o.dist ORDER BY o.dist`)) {
  console.log(`  district ${r.dist}  old ${String(r.old_sq_mi).padStart(8)}  new ${String(r.new_sq_mi).padStart(8)}  symdiff ${String(r.symdiff_sq_mi).padStart(8)}   ${r.councilor}`);
}

console.log('\n--- union of each set against the TIGER place polygon (geo_id 2717000) ---');
for (const r of await q(`
  SELECT 'old' AS which,
         round((ST_Area(ST_Union(geom)::geography)/2589988.11)::numeric,3) AS union_sq_mi FROM d_old
  UNION ALL
  SELECT 'new', round((ST_Area(ST_Union(geom)::geography)/2589988.11)::numeric,3) FROM d_new
  UNION ALL
  SELECT 'TIGER place', round((ST_Area(geometry::geography)/2589988.11)::numeric,3)
    FROM essentials.geofence_boundaries WHERE geo_id='2717000'`)) {
  console.log(`  ${r.which.padEnd(12)} ${r.union_sq_mi} sq mi`);
}

console.log('\n--- do the five districts of each set OVERLAP each other? (they must not) ---');
for (const t of ['d_old', 'd_new']) {
  const [r] = await q(`
    SELECT count(*) AS overlapping,
           round((COALESCE(sum(ST_Area(ST_Intersection(a.geom,b.geom)::geography)),0)/2589988.11)::numeric,4) AS overlap_sq_mi
    FROM ${t} a JOIN ${t} b ON b.dist > a.dist AND ST_Overlaps(a.geom,b.geom)`);
  console.log(`  ${t}: ${r.overlapping} overlapping pair(s), ${r.overlap_sq_mi} sq mi`);
}

await client.query('ROLLBACK');
await client.end();
