#!/usr/bin/env node
/**
 * load-wichita-council-boundaries.mjs — Knight program, wave KS-3.
 *
 * Builds Wichita's six City Council district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='wichita-ks-council-district-1'..'-6', mtfcc='X0070'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration creates the districts and
 * their offices and REFUSES TO RUN if these six boundaries are absent — an office on a district with
 * no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE VINTAGE GATE IS IMPORTED, NOT COPIED. `verify-wichita-council-vintage.mjs` is run here
 * before a single row is written, so the write is gated by the real gate rather than by a
 * reimplementation of it that can drift out of agreement. Lexington's loader re-ran its vintage
 * check at write time for the same reason; this goes one step further by sharing the code.
 *
 * WHY THE GATE IS A POPULATION TEST AND NOT AN AREA COMPARISON. Every earlier slice proved vintage
 * against a prior map. Wichita publishes none: all 23 layers of COWGIS/Districts enumerated (exactly
 * one is council districts, no `_2012` twin), every city ArcGIS folder enumerated, four Wayback
 * captures all from 2026, both city redistricting pages hard 404, and the county's Hosted folder
 * access-restricted even through Playwright. So the gate asks whether the six districts are BALANCED
 * ON 2020 COUNTS, which the superseded map cannot be — it was drawn on 2010 data and was out of
 * balance by 2022, which is why it was replaced. Measured: 2.40% total deviation, and the six
 * districts account for Wichita city's 2020 population to 0.08%.
 *
 * 🔴 THE COUNTY IS NOT AN INDEPENDENT CHECK, AND ONLY MEASURING SHOWED THAT. Sedgwick County's
 * election service publishes six Wichita districts with the same numbers and the same member names.
 * Reprojected to 4326 its areas agree with the city's to NINE DECIMAL PLACES and its vertex counts
 * match one for one across all 24,716 vertices — it is the same source geometry reprojected from
 * EPSG:3420. It corroborates that the ballot-issuing system holds this boundary. It is not a second
 * opinion, and "two independent sources agree" would have been false.
 *
 * ⚠ THE MAYOR NEEDS NO POLYGON HERE. Wichita's mayor is elected at large, so the structure migration
 * hangs that office on the TIGER place boundary 2079000 / G4110 already in production — the pattern
 * every other LOCAL_EXEC mayor in this database uses.
 *
 * ⚠ ANNEXATION MOVES THIS BOUNDARY BETWEEN REDISTRICTINGS. Comparing the 2026-05-09 Wayback capture
 * with today, every district's area moved and the TOTAL GREW 0.211%. A redistricting redistributes
 * area and preserves the total; a growing total is the city annexing land. So this layer is not a
 * frozen artifact and a byte-comparison against Map B as adopted would be the wrong test.
 *
 * Usage:
 *   node scripts/load-wichita-council-boundaries.mjs --dry-run
 *   node scripts/load-wichita-council-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
import { run as verifyVintage } from './verify-wichita-council-vintage.mjs';
dotenv.config();

const DRY_RUN = process.argv.includes('--dry-run');
const UA = { 'User-Agent': 'ev-accounts/ks-slice14' };
const LAYER = 'https://gismaps.wichita.gov/ageweb/rest/services/COWGIS/Districts/MapServer/3';
const MTFCC = 'X0070';
const EXPECTED = 6;
const STATE_FIPS = '20';
const PLACE_GEO_ID = '2079000'; // TIGER place, Wichita city — already in production
const SOURCE =
  'City of Wichita GIS, COWGIS/Districts/MapServer layer 3 "Council Districts" ' +
  '(gismaps.wichita.gov). Six districts, COUNCIL contiguous 1..6. Vintage proved by POPULATION ' +
  'DEVIATION rather than against a prior map, because Wichita publishes none: the six districts are ' +
  'balanced on 2020 census counts to 2.40% total deviation, inside the five percent the Commission ' +
  'of Electors was appointed to work to, and account for Wichita city 2020 population to 0.08% ' +
  '(397,864 against 397,532). A map drawn on 2010 counts cannot be balanced on 2020 counts. Map B ' +
  'was adopted 2022-11-01 and took effect 2023-01-01. Corroborated, NOT independently, by Sedgwick ' +
  "County's election service, which serves the identical geometry reprojected. Read 2026-09-27 (KS-3)";

const fail = (m) => { console.error(`\n🔴 ${m}`); process.exit(1); };

async function fetchDistricts() {
  const url = `${LAYER}/query?where=1%3D1&outFields=COUNCIL&outSR=4326&returnGeometry=true&f=geojson`;
  const r = await fetch(url, { headers: UA });
  const text = await r.text();
  // 🔴 A CLEAN HTTP 200 LIES — judge the body, not the status.
  if (/^\s*</.test(text)) fail(`council layer: HTML, not JSON (${r.status})`);
  const j = JSON.parse(text);
  if (j.error) fail(`council layer: ${JSON.stringify(j.error)}`);
  // A truncated answer is also a clean 200.
  if (j.exceededTransferLimit) fail('council layer: the service paged — refusing a partial map');
  const feats = j.features ?? [];
  if (feats.length !== EXPECTED) fail(`council layer: ${feats.length} features, expected ${EXPECTED}`);
  const byNum = new Map();
  for (const f of feats) {
    const n = Number(f.properties.COUNCIL);
    if (!Number.isInteger(n) || n < 1 || n > EXPECTED) fail(`bad COUNCIL ${f.properties.COUNCIL}`);
    if (byNum.has(n)) fail(`duplicate COUNCIL ${n}`);
    byNum.set(n, f);
  }
  for (let n = 1; n <= EXPECTED; n++) if (!byNum.has(n)) fail(`district ${n} absent`);
  return byNum;
}

// ── The vintage gate, run before anything else ────────────────────────────────────────────────
console.log('running the vintage gate (verify-wichita-council-vintage.mjs)…\n');
let deviation;
try {
  deviation = await verifyVintage(null);
} catch (e) {
  fail(`the vintage gate did not pass, so nothing is written: ${e.message}`);
}
console.log(`\n✅ vintage gate passed — ${deviation.toFixed(2)}% total deviation. Proceeding.\n`);

const byNum = await fetchDistricts();
const parts = [];
for (let n = 1; n <= EXPECTED; n++) parts.push({ district: n, g: byNum.get(n).geometry });
console.log(`fetched ${parts.length} district polygons`);

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();
const q = async (text, params) => (await client.query(text, params)).rows;

await q('BEGIN');
const [before] = await q('SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1', [MTFCC]);
console.log(`\n${MTFCC} before: ${before.n} row(s)`);
if (before.n !== 0 && before.n !== EXPECTED) {
  await q('ROLLBACK');
  fail(`${MTFCC} already holds ${before.n} rows — neither empty nor complete. Refusing to guess.`);
}

const inserted = await q(
  `WITH p AS (
     SELECT (e->>'district')::int AS district,
            ST_SetSRID(ST_GeomFromGeoJSON(e->'g'), 4326) AS g
       FROM jsonb_array_elements($3::jsonb) AS e
   )
   INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
   SELECT 'wichita-ks-council-district-' || p.district,
          'Wichita City Council District ' || p.district,
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
          count(DISTINCT ST_SRID(geometry))::int AS srids,
          count(*) FILTER (WHERE geometry IS NULL OR ST_IsEmpty(geometry))::int AS bad
     FROM essentials.geofence_boundaries WHERE mtfcc = $1`, [MTFCC]);
if (valid.ok !== EXPECTED || valid.srids !== 1 || valid.bad !== 0) {
  await q('ROLLBACK');
  fail(`post-write: ${valid.ok}/${EXPECTED} valid, ${valid.srids} SRID(s), ${valid.bad} null/empty`);
}

// Coverage against the place polygon. Wichita's council districts are expected to tile the city,
// so this is reported as a measurement rather than asserted at a threshold — annexation means the
// two layers are maintained on different cadences and need not agree exactly.
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

// Per-district control: every district must resolve to exactly one district, and to ITSELF.
// A uniform pass from a probe nobody has watched fail is not evidence, so the negative half runs too.
const [ctl] = await q(
  `SELECT count(*)::int AS n,
          count(*) FILTER (WHERE hits = 1)::int AS exactly_one,
          count(*) FILTER (WHERE self)::int AS resolved_self
     FROM (SELECT b.geo_id,
             (SELECT count(*) FROM essentials.geofence_boundaries x
               WHERE x.mtfcc = $1 AND ST_Contains(x.geometry, ST_PointOnSurface(b.geometry))) AS hits,
             EXISTS (SELECT 1 FROM essentials.geofence_boundaries x
                      WHERE x.mtfcc = $1 AND x.geo_id = b.geo_id
                        AND ST_Contains(x.geometry, ST_PointOnSurface(b.geometry))) AS self
             FROM essentials.geofence_boundaries b WHERE b.mtfcc = $1) t`, [MTFCC]);
console.log(`per-district: ${ctl.n} probed · ${ctl.exactly_one} resolve to exactly one · ${ctl.resolved_self} resolve to themselves`);
if (ctl.exactly_one !== EXPECTED || ctl.resolved_self !== EXPECTED) {
  await q('ROLLBACK');
  fail('per-district control failed — districts overlap or a polygon does not contain its own point');
}

// The negative half: each district's point must NOT fall in any OTHER district.
const [neg] = await q(
  `SELECT count(*)::int AS leaks FROM essentials.geofence_boundaries b
     JOIN essentials.geofence_boundaries x
       ON x.mtfcc = $1 AND x.geo_id <> b.geo_id
      AND ST_Contains(x.geometry, ST_PointOnSurface(b.geometry))
    WHERE b.mtfcc = $1`, [MTFCC]);
console.log(`negative control: ${neg.leaks} cross-district leak(s) (must be 0)`);
if (neg.leaks !== 0) { await q('ROLLBACK'); fail(`${neg.leaks} district point(s) fall inside another district`); }

if (DRY_RUN) {
  await q('ROLLBACK');
  console.log('\n--dry-run: ROLLED BACK, nothing written.');
} else {
  await q('COMMIT');
  console.log(`\n🟢 COMMITTED — ${EXPECTED} Wichita council district boundaries at mtfcc ${MTFCC}.`);
}
await client.end();
