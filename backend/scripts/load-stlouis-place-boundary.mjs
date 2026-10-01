#!/usr/bin/env node
/**
 * load-stlouis-place-boundary.mjs — St. Louis MO deep seed, wave 3.
 *
 * Inserts ONE boundary: TIGER place 2965000 "St. Louis city" (MTFCC G4110) into
 * essentials.geofence_boundaries. Writes nothing else.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 WHY THIS IS NEEDED, AND WHY WAVE 1 WAS RIGHT TO SKIP THE PLACE LAYER.
 *
 * Wave 1 deliberately did not run the TIGER `place` layer for Missouri: it would have created a
 * second, coextensive `St. Louis city` DISTRICT row (place 2965000) for ground already held by the
 * county-equivalent row (county 29510). That reasoning was about DISTRICTS and it still stands —
 * this script creates no district.
 *
 * What wave 3 needs is a GEOFENCE the citywide seats can resolve through, and the county polygon
 * cannot serve:
 *
 *   districtQueries.GEOFENCE_DISTRICT_JOIN maps  G4020 -> COUNTY, JUDICIAL   (LOCAL_EXEC only for PR)
 *                                                G4110 -> LOCAL, LOCAL_EXEC
 *
 * So a `LOCAL_EXEC` district on the county polygon 29510/G4020 would be UNREACHABLE BY ANY ADDRESS
 * and nothing would error. Loading place 2965000 puts the Mayor, the Comptroller and the six
 * county-tier officers on exactly the shape Springfield already uses (LOCAL + LOCAL_EXEC on a
 * G4110 place), with no change to the join or to MTFCC_DISTRICT_TYPE_GUARD.
 *
 * ⚠ THE FOURTEEN WARDS DO NOT USE THIS POLYGON. They carry their own X0075 boundaries, which the
 * X catch-all in both the join and the guard admits for `LOCAL`.
 *
 * ⚠ AREALAND DISAGREES SLIGHTLY WITH THE WAVE-1 MEASUREMENT: TIGERweb reports 159,847,392 m²,
 * wave 1 read 159,853,177 m² from the 2024 shapefile — 5,785 m², 0.004%. Two vintages of one
 * boundary, recorded rather than reconciled.
 *
 *   node scripts/load-stlouis-place-boundary.mjs --dry-run
 *   node scripts/load-stlouis-place-boundary.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0' };
const SERVICE =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/Places_CouSub_ConCity_SubMCD/MapServer/4';
const GEO_ID = '2965000';
const MTFCC = 'G4110';
const STATE_FIPS = '29';
const SOURCE =
  'Census TIGERweb Places_CouSub_ConCity_SubMCD layer 4, GEOID 2965000 "St. Louis city", ' +
  'MTFCC G4110, AREALAND 159847392 m², read 2026-09-28. Loaded so the citywide seats can resolve: ' +
  'the county-equivalent polygon 29510/G4020 maps only to COUNTY/JUDICIAL, so a LOCAL_EXEC district ' +
  'on it would be unreachable by any address (MO-3)';

const DRY = process.argv.includes('--dry-run');
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

const url =
  `${SERVICE}/query?where=GEOID%3D%27${GEO_ID}%27&outFields=GEOID,NAME,MTFCC,STATE&returnGeometry=true&outSR=4326&f=geojson`;
const r = await fetch(url, { headers: UA });
const t = await r.text();
if (!t.trim().startsWith('{')) fail(`not JSON (HTTP ${r.status}) from TIGERweb`);
const j = JSON.parse(t);
if (j.error) fail(`TIGERweb error: ${JSON.stringify(j.error).slice(0, 160)}`);
let feats = j.features ?? [];

// 🔴 CONTROLS — each was run and each fired.
//   empty  -> GATE 1   no feature came back
//   attrs  -> GATE 2   the row is not the place we asked for
//   extent -> GATE 3   the polygon does not contain City Hall
if (CONTROL === 'empty') feats = [];
if (CONTROL === 'attrs' && feats[0]) feats[0].properties = { ...feats[0].properties, GEOID: '2970000', NAME: 'Springfield city' };
if (CONTROL === 'extent' && feats[0]) {
  const shift = (co) => (typeof co[0] === 'number' ? [co[0] + 5, co[1]] : co.map(shift));
  feats[0].geometry = { ...feats[0].geometry, coordinates: shift(feats[0].geometry.coordinates) };
}
if (CONTROL) console.log(`\n⚠ CONTROL "${CONTROL}" ACTIVE — a gate MUST fail below.\n`);

// ── GATE 1: exactly one feature ──────────────────────────────────────────────
if (feats.length !== 1) fail(`GATE 1: expected exactly 1 place feature, got ${feats.length}`);
const p = feats[0].properties;
console.log(`TIGERweb place: ${p.GEOID} "${p.NAME}" MTFCC ${p.MTFCC} STATE ${p.STATE}`);

// ── GATE 2: it is the place we asked for ─────────────────────────────────────
// 🔴 A generic name is a jurisdiction-collision risk. Assert the GEOID, the MTFCC and the state,
// not the name — "St. Louis" names a city in Missouri AND a county in Minnesota.
if (p.GEOID !== GEO_ID || p.MTFCC !== MTFCC || String(p.STATE) !== STATE_FIPS) {
  fail(`GATE 2: expected GEOID ${GEO_ID}/${MTFCC}/state ${STATE_FIPS}, got ${p.GEOID}/${p.MTFCC}/${p.STATE}`);
}
console.log('  GATE 2 PASSED: GEOID, MTFCC and state all match');

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;
const geom = JSON.stringify(feats[0].geometry);

// ── GATE 3: the polygon covers the city, and its controls hold ───────────────
// It must contain City Hall, exclude Clayton and Chicago, and agree with the fourteen wards this
// wave already loaded — a SECOND publisher of the same boundary.
const [g] = await q(
  `WITH pl AS (SELECT ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($1), 4326)) AS geom),
        w  AS (SELECT ST_Union(ST_MakeValid(geometry)) AS geom
                 FROM essentials.geofence_boundaries WHERE mtfcc = 'X0075')
   SELECT ST_Contains(pl.geom, ST_SetSRID(ST_MakePoint(-90.19935, 38.62700), 4326)) AS city_hall,
          ST_Contains(pl.geom, ST_SetSRID(ST_MakePoint(-90.32790, 38.64470), 4326)) AS clayton,
          ST_Contains(pl.geom, ST_SetSRID(ST_MakePoint(-87.63245, 41.88370), 4326)) AS chicago,
          round((ST_Area(pl.geom::geography)/2589988.11)::numeric, 4) AS place_sq_mi,
          round((100 * ST_Area(ST_Intersection(pl.geom, w.geom)::geography)
                     / ST_Area(pl.geom::geography))::numeric, 3)      AS pct_covered_by_wards
     FROM pl, w`,
  [geom],
);
console.log(`  place ${g.place_sq_mi} sq mi · ${g.pct_covered_by_wards}% of it covered by the 14 X0075 wards`);
if (!g.city_hall) fail('GATE 3: the place polygon does not contain 1200 Market St (City Hall)');
if (g.clayton) fail('GATE 3: CONTROL failed — the place polygon contains Clayton, which is outside the city');
if (g.chicago) fail('GATE 3: CONTROL failed — the place polygon contains Chicago');
if (Number(g.pct_covered_by_wards) < 99.0) {
  fail(`GATE 3: the 14 wards cover only ${g.pct_covered_by_wards}% of the place polygon — load the wards first, or the two disagree`);
}
console.log('  GATE 3 PASSED: contains City Hall, excludes Clayton and Chicago, agrees with the wards');

if (DRY) {
  console.log('\n--dry-run complete, nothing written.');
  await pool.end();
  process.exit(0);
}

const inserted = await q(
  `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
   VALUES ($1, $2, $3, $4, ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($5)), 4326)), $6, now())
   ON CONFLICT (geo_id, mtfcc) DO NOTHING
   RETURNING geo_id`,
  [GEO_ID, 'St. Louis city', STATE_FIPS, MTFCC, geom, SOURCE],
);
console.log(`\ninserted ${inserted.length} boundary row(s) (0 means it was already present)`);
const [after] = await q(
  `SELECT count(*)::int AS n, count(*) FILTER (WHERE ST_IsValid(geometry))::int AS ok
     FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = $2`,
  [GEO_ID, MTFCC],
);
if (after.n !== 1 || after.ok !== 1) fail(`post-write: ${after.ok}/${after.n} valid rows for ${GEO_ID}/${MTFCC}`);
console.log('post-write: 1/1 valid geometry — committed.');
await pool.end();
