#!/usr/bin/env node
/**
 * load-columbia-council-boundaries.mjs — Knight program, wave SC-3.
 *
 * Fetches Columbia's four council-district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='cola-council-district-1'..'-4', mtfcc='X0059'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0127 creates the districts and their offices
 * and REFUSES TO RUN if these four boundaries are absent — an office on a district with no
 * polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE LAYER CARRIES ONE ATTRIBUTE AND NO DATE. `CouncilDistrict` (ColaCityGIS,
 * services1.arcgis.com/Mnt8FoJcogKtoVBs) publishes four polygons and a single field, `LABEL`.
 * There is no adoption date, no plan name, and Columbia publishes no second boundary set — so
 * unlike Philadelphia, where a superseded layer sits beside the current one, there is nothing
 * here to diff against. A count of four is true of every Columbia map ever drawn.
 *
 * WHAT IS CHECKED INSTEAD, and it is checked in a separate tool so it can be re-run:
 * scripts/verify-sc-columbia-districts.mjs tests the polygons against the COUNCIL'S OWN
 * neighbourhood lists — text published by the council, not by GIS — geocoded through a third
 * party. 8 of 8 anchors agree, and two points outside the city match nothing.
 *
 * ⚠ THAT PROVES AGREEMENT WITH THE COUNCIL'S DESCRIPTION TODAY. It does not date the map, and
 * nothing available here can. Recorded as a limitation rather than dressed up as a vintage proof.
 *
 *   node scripts/load-columbia-council-boundaries.mjs --dry-run
 *   node scripts/load-columbia-council-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };
const SERVICE =
  'https://services1.arcgis.com/Mnt8FoJcogKtoVBs/arcgis/rest/services/CouncilDistrict/FeatureServer/0';
const MTFCC = 'X0059';
const EXPECTED = 4;
const PLACE_GEO_ID = '4516000'; // TIGER place, Columbia city — already in production
const SOURCE =
  'City of Columbia, CouncilDistrict (services1.arcgis.com/Mnt8FoJcogKtoVBs, ColaCityGIS); ' +
  "agreement with the council's own per-district neighbourhood lists verified 8/8 by " +
  'scripts/verify-sc-columbia-districts.mjs (SC-3)';

const DRY = process.argv.includes('--dry-run');
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

const r = await fetch(`${SERVICE}/query?where=1%3D1&outFields=*&outSR=4326&f=geojson`, { headers: UA });
const t = await r.text();
if (!t.trim().startsWith('{')) fail(`not JSON (HTTP ${r.status}) from CouncilDistrict`);
const j = JSON.parse(t);
if (j.error) fail(`ArcGIS error: ${JSON.stringify(j.error).slice(0, 160)}`);
const feats = j.features;
console.log(`CouncilDistrict: ${feats.length} features`);

// ── GATE 1: the shape of the layer ───────────────────────────────────────────
if (feats.length !== EXPECTED) fail(`GATE 1: expected ${EXPECTED} features, got ${feats.length}`);
const nums = feats.map((f) => Number(String(f.properties.LABEL).match(/\d+/)?.[0]));
const sorted = [...nums].sort((a, b) => a - b);
if (new Set(nums).size !== EXPECTED || sorted[0] !== 1 || sorted[EXPECTED - 1] !== EXPECTED) {
  fail(`GATE 1: districts are not 1..${EXPECTED} exactly — got ${sorted.join(',')}`);
}
console.log(`  GATE 1 PASSED: districts ${sorted.join(',')} (LABEL ${feats.map((f) => f.properties.LABEL).join(', ')})`);

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const rows = feats.map((f) => {
  const n = Number(String(f.properties.LABEL).match(/\d+/)[0]);
  return {
    geo_id: `cola-council-district-${n}`,
    name: `Columbia City Council District ${n}`,
    geom: JSON.stringify(f.geometry),
  };
});

// ── GATE 2: the four districts do not overlap each other ─────────────────────
// 🔴 A layer that mixes two vintages usually shows up here first: two plans' districts overlap.
// One of Columbia's four polygons is NOT valid as published, so every measurement below runs
// through ST_MakeValid — an invalid ring silently returns 0 area from ST_Intersection otherwise.
const [ov] = await q(
  `WITH d AS (SELECT r.geo_id,
                     ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)                AS raw,
                     ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326))  AS geom
                FROM jsonb_to_recordset($1::jsonb) AS r(geo_id text, name text, geom text))
   SELECT (SELECT count(*) FROM d a JOIN d b ON a.geo_id < b.geo_id
            WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 1000)::int AS pairs,
          (SELECT count(*) FROM d WHERE NOT ST_IsValid(raw))::int                  AS invalid_as_published`,
  [JSON.stringify(rows)],
);
if (ov.pairs > 0) fail(`GATE 2: ${ov.pairs} pair(s) of districts overlap by more than 1000 m² — is this one map?`);
console.log(`  GATE 2 PASSED: no two districts overlap (${ov.invalid_as_published} polygon(s) invalid as published, repaired on write)`);

// ── GATE 3: coverage of the city the districts are supposed to tile ──────────
// ⚠ Not every city tiles — Fort Wayne's six districts correctly leave 1.13 sq mi uncovered — so
// this gate belongs to THIS city. Columbia's four districts are a partition of the city.
const [cov] = await q(
  `WITH u AS (
     SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g), 4326))) AS geom
       FROM unnest($1::text[]) AS t(g)
   ), place AS (
     SELECT geometry AS geom FROM essentials.geofence_boundaries
      WHERE geo_id = $2 AND mtfcc = 'G4110' AND state = '45'
   )
   SELECT round((ST_Area(place.geom::geography)/2589988.11)::numeric, 3) AS place_sq_mi,
          round((ST_Area(u.geom::geography)/2589988.11)::numeric, 3)     AS districts_sq_mi,
          round((100 * ST_Area(ST_Intersection(place.geom, u.geom)::geography)
                     / ST_Area(place.geom::geography))::numeric, 3)      AS pct_covered,
          round((ST_Area(ST_Difference(u.geom, place.geom)::geography)/2589988.11)::numeric, 3) AS outside_city_sq_mi
     FROM u, place`,
  [rows.map((x) => x.geom), PLACE_GEO_ID],
);
if (!cov) fail(`GATE 3: the TIGER place polygon ${PLACE_GEO_ID} is not in production`);
console.log(
  `  city ${cov.place_sq_mi} sq mi · districts ${cov.districts_sq_mi} sq mi · ${cov.pct_covered}% of the city covered · ${cov.outside_city_sq_mi} sq mi of district area lies outside the TIGER place`,
);
if (Number(cov.pct_covered) < 99) fail(`GATE 3: the four districts cover only ${cov.pct_covered}% of Columbia`);
console.log('  GATE 3 PASSED: the districts tile the city');

if (DRY) {
  console.log('\n--dry-run complete, nothing written.');
  await pool.end();
  process.exit(0);
}

await q('BEGIN');
const inserted = await q(
  `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
   SELECT r.geo_id, r.name, '45', $1,
          ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(r.geom)), 4326)), $2, now()
     FROM jsonb_to_recordset($3::jsonb) AS r(geo_id text, name text, geom text)
   ON CONFLICT (geo_id, mtfcc) DO NOTHING
   RETURNING geo_id`,
  [MTFCC, SOURCE, JSON.stringify(rows)],
);
console.log(`\ninserted ${inserted.length} boundary row(s)`);

const [after] = await q('SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1', [MTFCC]);
if (after.n !== EXPECTED) {
  await q('ROLLBACK');
  fail(`post-write: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED}`);
}
const [valid] = await q(
  `SELECT count(*)::int AS n, count(*) FILTER (WHERE ST_IsValid(geometry))::int AS ok,
          count(DISTINCT ST_SRID(geometry))::int AS srids
     FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
if (valid.ok !== EXPECTED || valid.srids !== 1) {
  await q('ROLLBACK');
  fail(`post-write: ${valid.ok}/${valid.n} valid, ${valid.srids} SRID(s)`);
}
await q('COMMIT');
console.log(`post-write: ${valid.ok}/${valid.n} valid geometries, 1 SRID — committed.`);
await pool.end();
