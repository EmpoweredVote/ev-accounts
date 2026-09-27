#!/usr/bin/env node
/**
 * load-lexington-council-boundaries.mjs — Knight program, wave KY-3.
 *
 * Builds Lexington-Fayette's twelve Urban County Council district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='lexington-fayette-ky-council-district-1'..'-12',
 *                                   mtfcc='X0068'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration creates the districts and
 * their offices and REFUSES TO RUN if these twelve boundaries are absent — an office on a district
 * with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 LEXINGTON PUBLISHES FOUR COUNCIL-DISTRICT LAYERS AND ALL FOUR CARRY EXACTLY 12 FEATURES.
 * `Council_District`, `Council_District_2012`, `Council_District_2002`, `Council_District_1972`,
 * all in the same ArcGIS organisation. A COUNT CANNOT TELL THEM APART — this is the Duluth trap,
 * where the superseded map returned the same feature count as the live one.
 *
 * ⚠ AND THE OBVIOUS TEST IS TOO WEAK. Locating each 2012 district's centroid inside the current
 * layer agrees 11 of 12 — a 92% agreement rate, which is the level North Dakota proved a
 * STRUCK-DOWN map can pass. Centroids sit deep inside a district and survive most boundary moves.
 *
 * 🟢 THE AREA TEST IS THE DISCRIMINATING ONE, AND IT IS BUILT INTO THIS SCRIPT. Measured
 * 2026-09-26: ALL TWELVE districts differ in area from the 2012 map, by 1.0% to 44.9%, while the
 * TOTAL area is preserved to 0.03%. That is the exact signature of a redistricting — the same
 * county, redistributed — and it is not something a stale copy can produce.
 * Supporting, but not sufficient on their own:
 *   * the three superseded layers carry an explicit year in their name; the live one does not;
 *   * the live layer's catalogue `modified` is 2025-12-16 against 2024-09-13 for the other three;
 *   * its `REP` attribute matches the city's own councilmember roster 12 of 12.
 * ⚠ THE `REP` MATCH IS NOT A VINTAGE PROOF. KY-2 found the state's own GIS layer carrying a STALE
 * roster beside CORRECT geometry — attributes and geometry are independent, and neither vouches
 * for the other. It is recorded as corroboration, nothing more.
 *
 * 🟢 THE PLACE POLYGON IS EXACTLY COTERMINOUS WITH THE COUNTY, AND THAT WAS MEASURED, NOT ASSUMED
 * FROM THE WORD "CONSOLIDATED": TIGER place 2146027 and county 21067 are both 285.567 sq mi with
 * ZERO difference in either direction and 100.000% coverage. The control discriminates — Duluth's
 * place covers 1.169% of St. Louis County. So citywide seats may hang on either polygon; this
 * slice uses the place GEOID, which is Duluth's precedent.
 *
 * Usage:
 *   node scripts/load-lexington-council-boundaries.mjs --dry-run
 *   node scripts/load-lexington-council-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const DRY_RUN = process.argv.includes('--dry-run');
const UA = { 'User-Agent': 'ev-accounts/ky-slice13' };
const ORG = 'https://services1.arcgis.com/Mg7DLdfYcSWIaDnu/arcgis/rest/services';
const LIVE = `${ORG}/Council_District/FeatureServer/0`;
const PRIOR = `${ORG}/Council_District_2012/FeatureServer/0`;
const MTFCC = 'X0068';
const EXPECTED = 12;
const STATE_FIPS = '21';
const PLACE_GEO_ID = '2146027'; // TIGER place, Lexington-Fayette urban county — already in prod
const SOURCE =
  'Lexington-Fayette Urban County Government, Council_District feature service ' +
  '(services1.arcgis.com/Mg7DLdfYcSWIaDnu, catalogue modified 2025-12-16). Vintage proved against ' +
  'the superseded Council_District_2012 layer: all 12 districts differ in area by 1.0%-44.9% while ' +
  'the total is preserved to 0.03%, the signature of a redistricting. A centroid test was ' +
  'insufficient (11/12 agreement) and is recorded as such. The layer REP attribute matches the ' +
  "city's own councilmember roster 12/12, as corroboration only. Read 2026-09-26 (KY-3)";

const fail = (m) => { console.error(`\n🔴 ${m}`); process.exit(1); };

async function fetchLayer(base, label, fields = 'DISTRICT') {
  const url = `${base}/query?where=1%3D1&outFields=${fields}&outSR=4326&returnGeometry=true&f=geojson`;
  const r = await fetch(url, { headers: UA });
  if (!r.ok) fail(`${label}: HTTP ${r.status}`);
  const j = await r.json();
  if (j.error) fail(`${label}: ${JSON.stringify(j.error)}`);
  // 🔴 A TRUNCATED ANSWER IS A CLEAN HTTP 200. Refuse a paged response.
  if (j.exceededTransferLimit) fail(`${label}: the service paged the response — refusing a partial map`);
  const feats = j.features ?? [];
  if (feats.length !== EXPECTED) fail(`${label}: ${feats.length} features, expected ${EXPECTED}`);
  const byNum = new Map();
  for (const f of feats) {
    const n = Number(f.properties.DISTRICT);
    if (!Number.isInteger(n) || n < 1 || n > EXPECTED) fail(`${label}: bad DISTRICT ${f.properties.DISTRICT}`);
    if (byNum.has(n)) fail(`${label}: duplicate DISTRICT ${n}`);
    byNum.set(n, f);
  }
  for (let n = 1; n <= EXPECTED; n++) if (!byNum.has(n)) fail(`${label}: district ${n} absent`);
  return byNum;
}

/** Planar shoelace area in square degrees — used ONLY to compare two layers with each other,
 *  never as a real-world area. The comparison is scale-free, so the projection does not matter. */
function areaOf(geom) {
  let total = 0;
  const polys = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  for (const poly of polys) {
    poly.forEach((ring, idx) => {
      let a = 0;
      for (let i = 0; i < ring.length - 1; i++) a += ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1];
      total += (a / 2) * (idx === 0 ? 1 : -1);
    });
  }
  return Math.abs(total);
}

const live = await fetchLayer(LIVE, 'Council_District', 'DISTRICT,REP');
const prior = await fetchLayer(PRIOR, 'Council_District_2012', 'DISTRICT');

// ── The vintage gate, re-run here rather than trusted from the day it was measured ──
let changed = 0;
let liveTotal = 0;
let priorTotal = 0;
const rows = [];
for (let n = 1; n <= EXPECTED; n++) {
  const a = areaOf(live.get(n).geometry);
  const b = areaOf(prior.get(n).geometry);
  liveTotal += a; priorTotal += b;
  const pct = b ? (Math.abs(a - b) / b) * 100 : 0;
  if (pct > 1) changed++;
  rows.push({ n, pct, rep: live.get(n).properties.REP });
}
const totalPct = priorTotal ? (Math.abs(liveTotal - priorTotal) / priorTotal) * 100 : 100;
console.log(`vintage check against Council_District_2012:`);
console.log(`  districts differing in area by >1%: ${changed}/${EXPECTED}`);
console.log(`  total area difference: ${totalPct.toFixed(4)}%`);
if (changed !== EXPECTED) {
  fail(
    `only ${changed} of ${EXPECTED} districts differ from the 2012 map by more than 1%. ` +
    `Either the live layer has gone stale and is serving the 2012 plan, or the 2012 layer was ` +
    `republished. A COUNT cannot tell these apart and a centroid test agrees 11/12 on the WRONG ` +
    `map, so this area test is the only discriminator here. Aborting before any DB write.`,
  );
}
if (totalPct > 1) {
  fail(
    `total area moved ${totalPct.toFixed(4)}% between the two layers. A redistricting redistributes ` +
    `a fixed county; a total that moves means the layers cover different territory. Aborting.`,
  );
}
console.log(`  ✅ all ${EXPECTED} districts moved, total preserved — this is the post-2020 map.`);

const parts = [];
for (let n = 1; n <= EXPECTED; n++) parts.push({ district: n, g: live.get(n).geometry });

const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();
const q = async (text, params) => (await client.query(text, params)).rows;

await q('BEGIN');
const [before] = await q('SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1', [MTFCC]);
console.log(`\n${MTFCC} before: ${before.n} row(s)`);

const inserted = await q(
  `WITH p AS (
     SELECT (e->>'district')::int AS district,
            ST_SetSRID(ST_GeomFromGeoJSON(e->'g'), 4326) AS g
       FROM jsonb_array_elements($3::jsonb) AS e
   )
   INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
   SELECT 'lexington-fayette-ky-council-district-' || p.district,
          'Lexington-Fayette Urban County Council District ' || p.district,
          $4, $1, ST_MakeValid(p.g), $2, now()
     FROM p
   ON CONFLICT (geo_id, mtfcc) DO NOTHING
   RETURNING geo_id`,
  [MTFCC, SOURCE, JSON.stringify(parts), STATE_FIPS],
);
console.log(`inserted ${inserted.length} boundary row(s)`);

const [after] = await q('SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1', [MTFCC]);
if (after.n !== EXPECTED) { await q('ROLLBACK'); fail(`post-write: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED}`); }

const [valid] = await q(
  `SELECT count(*) FILTER (WHERE ST_IsValid(geometry))::int AS ok,
          count(DISTINCT ST_SRID(geometry))::int AS srids
     FROM essentials.geofence_boundaries WHERE mtfcc = $1`, [MTFCC]);
if (valid.ok !== EXPECTED || valid.srids !== 1) {
  await q('ROLLBACK');
  fail(`post-write: ${valid.ok}/${EXPECTED} valid geometries, ${valid.srids} distinct SRID(s)`);
}

// Coverage against the place polygon. Lexington-Fayette is consolidated and coterminous with the
// county, so the twelve districts are expected to tile it. Measured, then reported.
const [cov] = await q(
  `WITH d AS (SELECT ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc = $1),
        p AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE geo_id = $2 AND mtfcc = 'G4110')
   SELECT round((ST_Area(p.g::geography)/2589988.11)::numeric, 3) AS place_sq_mi,
          round((ST_Area(d.g::geography)/2589988.11)::numeric, 3) AS districts_sq_mi,
          round((100*ST_Area(ST_Intersection(p.g, d.g)::geography)/ST_Area(p.g::geography))::numeric, 3) AS pct_place_covered,
          round((ST_Area(ST_Difference(d.g, p.g)::geography)/2589988.11)::numeric, 3) AS outside_place
     FROM d, p`, [MTFCC, PLACE_GEO_ID]);
console.log(`\ncoverage: place ${cov.place_sq_mi} sq mi · districts ${cov.districts_sq_mi} sq mi · ` +
            `${cov.pct_place_covered}% of the place covered · ${cov.outside_place} sq mi outside it`);

// Per-district control: every district must resolve to exactly one, and to itself.
const [ctl] = await q(
  `SELECT count(*)::int AS n,
          count(*) FILTER (WHERE hits = 1)::int AS exactly_one
     FROM (SELECT b.geo_id,
             (SELECT count(*) FROM essentials.geofence_boundaries x
               WHERE x.mtfcc = $1 AND ST_Contains(x.geometry, ST_PointOnSurface(b.geometry))) AS hits
             FROM essentials.geofence_boundaries b WHERE b.mtfcc = $1) s`, [MTFCC]);
console.log(`per-district control: ${ctl.exactly_one}/${ctl.n} resolve to exactly one`);
if (ctl.exactly_one !== EXPECTED) { await q('ROLLBACK'); fail(`per-district control failed: ${ctl.exactly_one}/${EXPECTED}`); }

if (DRY_RUN) {
  await q('ROLLBACK');
  console.log('\nDRY RUN — rolled back, no rows written.');
} else {
  await q('COMMIT');
  console.log('\nCOMMITTED.');
}
await client.end();
