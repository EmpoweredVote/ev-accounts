#!/usr/bin/env node
/**
 * load-phl-council-boundaries.mjs — Knight program, wave PA-3.
 *
 * Fetches Philadelphia's ten council-district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='phl-council-district-1'..'-10', mtfcc='X0058'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0121 creates the districts and their offices
 * and REFUSES TO RUN if these ten boundaries are absent — an office on a district with no polygon
 * is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE CITY PUBLISHES FIVE COUNCIL-DISTRICT LAYERS AND EVERY ONE HAS TEN FEATURES NUMBERED
 * 1-10: Council_Districts_1990, _2000, _2016, _2024 and council_districts_2024_2. A count cannot
 * tell them apart, and neither can a city-wide spread of addresses — see
 * scripts/verify-phl-council-districts.mjs, which found that all 54 Free Library branches agree
 * with BOTH the 2024 and the superseded 2016 map. What separates them is the ~4% of addresses the
 * 2022 remap actually moved: on those, the 2024 layer matches the City's own address service 6/6
 * and the 2016 layer 0/6.
 *
 * ⚠ council_districts_2024_2 is a COPY: identical feature count and identical total Shape__Area
 * to the layer loaded here. It is not loaded, and it is not evidence of anything.
 *
 *   node scripts/load-phl-council-boundaries.mjs --dry-run
 *   node scripts/load-phl-council-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };
const ARC = 'https://services.arcgis.com/fLeGjb7u4uXqeF9q/arcgis/rest/services';
const LAYER = 'Council_Districts_2024';
const OLD_LAYER = 'Council_Districts_2016';
const MTFCC = 'X0058';
const EXPECTED = 10;
const PLACE_GEO_ID = '4260000';   // TIGER place, Philadelphia city — already in production
const SOURCE = 'City of Philadelphia, Council_Districts_2024 (services.arcgis.com/fLeGjb7u4uXqeF9q); '
  + 'vintage proved against api.phila.gov/ais council_district_2024 on the changed population (PA-3)';

const DRY = process.argv.includes('--dry-run');
const fail = (m) => { console.error(`\n🔴 ${m}`); process.exit(1); };

async function arcgis(service) {
  const url = `${ARC}/${service}/FeatureServer/0/query?where=1%3D1&outFields=*&outSR=4326&f=geojson`;
  const r = await fetch(url, { headers: UA });
  const t = await r.text();
  if (!t.trim().startsWith('{')) fail(`not JSON (HTTP ${r.status}) from ${service}`);
  const j = JSON.parse(t);
  if (j.error) fail(`ArcGIS error from ${service}: ${JSON.stringify(j.error).slice(0, 160)}`);
  return j.features;
}

const feats = await arcgis(LAYER);
console.log(`${LAYER}: ${feats.length} features`);

// ── GATE 1: the shape of the layer ───────────────────────────────────────────
if (feats.length !== EXPECTED) fail(`GATE 1: expected ${EXPECTED} features, got ${feats.length}`);
const nums = feats.map((f) => Number(f.properties.district_num ?? f.properties.DISTRICT ?? f.properties.district));
const sorted = [...nums].sort((a, b) => a - b);
if (new Set(nums).size !== EXPECTED || sorted[0] !== 1 || sorted[EXPECTED - 1] !== EXPECTED) {
  fail(`GATE 1: districts are not 1..${EXPECTED} exactly — got ${sorted.join(',')}`);
}
console.log(`  GATE 1 PASSED: districts ${sorted.join(',')}`);

// ── GATE 2: this is not the superseded map ───────────────────────────────────
// 🔴 A NAME IS NOT A VINTAGE. If the layer being loaded were byte-identical to the 2016 plan,
// every downstream check would still pass and every Philadelphia address would resolve to a
// district drawn for the previous decade.
const old = await arcgis(OLD_LAYER);
let identical = 0;
for (const f of feats) {
  const n = Number(f.properties.district_num ?? f.properties.DISTRICT ?? f.properties.district);
  const o = old.find((x) => Number(x.properties.district_num ?? x.properties.DISTRICT ?? x.properties.district) === n);
  if (o && JSON.stringify(o.geometry) === JSON.stringify(f.geometry)) identical++;
}
if (identical === EXPECTED) fail(`GATE 2: every district is byte-identical to ${OLD_LAYER} — this is the superseded map`);
console.log(`  GATE 2 PASSED: ${identical} of ${EXPECTED} districts identical to the 2016 plan (the maps differ)`);

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

// ── GATE 3: coverage of the city the districts are supposed to tile ──────────
// Philadelphia's ten districts cover the whole city; the place polygon is already in production
// and is measured, not assumed. ⚠ Not every city tiles — Fort Wayne's six districts correctly
// leave 1.13 sq mi uncovered — so this gate belongs to THIS city, not to the loader.
const rows = feats.map((f) => ({
  geo_id: `phl-council-district-${Number(f.properties.district_num ?? f.properties.DISTRICT ?? f.properties.district)}`,
  name: `Philadelphia City Council District ${Number(f.properties.district_num ?? f.properties.DISTRICT ?? f.properties.district)}`,
  geom: JSON.stringify(f.geometry),
}));

const [cov] = await q(
  `WITH u AS (
     SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g), 4326))) AS geom
     FROM unnest($1::text[]) AS t(g)
   ), place AS (
     SELECT geometry AS geom FROM essentials.geofence_boundaries
     WHERE geo_id = $2 AND mtfcc = 'G4110' AND state = '42'
   )
   SELECT round((ST_Area(place.geom::geography)/2589988.11)::numeric, 3)                       AS place_sq_mi,
          round((ST_Area(u.geom::geography)/2589988.11)::numeric, 3)                           AS districts_sq_mi,
          round((100 * ST_Area(ST_Intersection(place.geom, u.geom)::geography)
                     / ST_Area(place.geom::geography))::numeric, 3)                            AS pct_covered
   FROM u, place`,
  [rows.map((r) => r.geom), PLACE_GEO_ID],
);
if (!cov) fail(`GATE 3: the TIGER place polygon ${PLACE_GEO_ID} is not in production`);
console.log(`  city ${cov.place_sq_mi} sq mi · districts ${cov.districts_sq_mi} sq mi · ${cov.pct_covered}% of the city covered`);
if (Number(cov.pct_covered) < 99) fail(`GATE 3: the ten districts cover only ${cov.pct_covered}% of Philadelphia`);
console.log('  GATE 3 PASSED: the districts tile the city');

if (DRY) {
  console.log('\n--dry-run complete, nothing written.');
  await pool.end();
  process.exit(0);
}

await q('BEGIN');
const inserted = await q(
  `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
   SELECT r.geo_id, r.name, '42', $1,
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
   FROM essentials.geofence_boundaries WHERE mtfcc = $1`, [MTFCC]);
if (valid.ok !== valid.n || valid.srids !== 1) {
  await q('ROLLBACK');
  fail(`post-write: ${valid.n - valid.ok} invalid geometry/ies, ${valid.srids} distinct SRIDs`);
}
await q('COMMIT');
console.log(`✓ ${MTFCC} holds ${after.n} valid boundaries in one SRID`);
await pool.end();
