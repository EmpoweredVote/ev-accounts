/**
 * measure-place-coverage.mjs
 *
 * Does a city's district set cover every part of the city, and what lies outside it?
 *
 *   node measure-place-coverage.mjs <districts.geojson> <TIGER place geo_id> <district field>
 *   node measure-place-coverage.mjs _duluth-new.geojson   2717000 CouncilDist
 *   node measure-place-coverage.mjs _stpaul-wards.geojson 2758000 district
 *
 * The two directions ask DIFFERENT questions and only one of them gates a seeding wave:
 *
 *   place MINUS districts  -> a city address that lands in NO district, and nothing errors.
 *                             This is the one that must be ~0.
 *   districts MINUS place  -> district area outside the city. Harmless when it is water or
 *                             unincorporated township; it has to be explained, not waved through.
 *
 * Neither "the union equals the place area" nor "the districts tile the place" is the right gate.
 * Fort Wayne's districts fell SHORT of its place polygon and that was correct; Duluth's overhang
 * Lake Superior by 11 sq mi and that is correct too. Saint Paul's seven wards happen to tile its
 * place exactly. All three are right, and only the first measurement distinguishes them.
 *
 * Read-only: opens a transaction, uses TEMP tables, and always ROLLBACKs.
 */
import fs from 'fs';
import pg from 'pg';

const [GEOJSON, PLACE, DISTFIELD] = process.argv.slice(2);
const new_ = JSON.parse(fs.readFileSync(GEOJSON, 'utf8'));
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
await client.query('BEGIN');
await client.query("SET LOCAL statement_timeout = '180s'");
await client.query(`CREATE TEMP TABLE d_new(dist int, geom geometry) ON COMMIT DROP`);
for (const f of new_.features) {
  await client.query(
    `INSERT INTO d_new(dist, geom) VALUES ($1, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($2), 4326)))`,
    [Number(f.properties[DISTFIELD]), JSON.stringify(f.geometry)],
  );
}
const q = async (sql) => (await client.query(sql)).rows;

const sqmi = `/2589988.11`;
const [a] = await q(`
  WITH u AS (SELECT ST_Union(geom) g FROM d_new),
       p AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id='${PLACE}')
  SELECT round((ST_Area(u.g::geography)${sqmi})::numeric,3)                                  AS districts_sq_mi,
         round((ST_Area(p.g::geography)${sqmi})::numeric,3)                                  AS place_sq_mi,
         round((ST_Area(ST_Difference(p.g,u.g)::geography)${sqmi})::numeric,4)               AS place_not_covered,
         round((ST_Area(ST_Difference(u.g,p.g)::geography)${sqmi})::numeric,3)               AS districts_outside_place,
         round((100*ST_Area(ST_Intersection(p.g,u.g)::geography)/ST_Area(p.g::geography))::numeric,3) AS pct_of_place_covered
  FROM u, p`);
console.log('districts union      ', a.districts_sq_mi, 'sq mi');
console.log('TIGER place          ', a.place_sq_mi, 'sq mi');
console.log('place NOT covered    ', a.place_not_covered, 'sq mi   <- a city address with no district');
console.log('districts OUTSIDE    ', a.districts_outside_place, 'sq mi   <- explain this');
console.log('pct of place covered ', a.pct_of_place_covered, '%');

console.log('\n--- is the excess water? intersect it with the districts-outside area ---');
for (const r of await q(`
  WITH u AS (SELECT ST_Union(geom) g FROM d_new),
       p AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id='${PLACE}'),
       x AS (SELECT ST_Difference(u.g,p.g) g FROM u,p)
  SELECT gb.geo_id, gb.name, gb.mtfcc,
         round((ST_Area(ST_Intersection(x.g, ST_MakeValid(gb.geometry))::geography)${sqmi})::numeric,3) AS overlap_sq_mi
  FROM x JOIN essentials.geofence_boundaries gb
    ON gb.mtfcc = 'G4020' AND gb.state = '27' AND ST_Intersects(x.g, ST_MakeValid(gb.geometry))
  WHERE ST_Area(ST_Intersection(x.g, ST_MakeValid(gb.geometry))::geography) > 0
  ORDER BY overlap_sq_mi DESC LIMIT 8`)) {
  console.log(`  ${r.mtfcc} ${r.geo_id} ${String(r.name).padEnd(28)} ${r.overlap_sq_mi} sq mi`);
}

await client.query('ROLLBACK');
await client.end();
