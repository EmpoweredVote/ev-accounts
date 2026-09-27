#!/usr/bin/env node
/**
 * load-sedgwick-bocc-boundaries.mjs — Knight program, wave KS-4.
 *
 * Builds Sedgwick County's five commission district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='sedgwick-ks-commission-district-1'..'-5', mtfcc='X0071'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration (CC_0161) creates the
 * districts and their offices and REFUSES TO RUN if these five boundaries are absent — an office on
 * a district with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE VINTAGE GATE IS IMPORTED, NOT COPIED. `verify-sedgwick-bocc-vintage.mjs` runs here before
 * a single row is written, so the write is gated by the real gate rather than by a reimplementation
 * that can drift out of agreement. Same arrangement as the Wichita loader in KS-3.
 *
 * 🔴 THREE PUBLISHERS, ONE DIGITIZATION. The city of Wichita serves this map as COWGIS/Districts
 * layer 1 `BOCC`, and the county serves it twice — Op_ElectionBOCC_Dynamic_SP layer 0 and
 * Op_Election_Dynamic_SP layer 6. All three report Shape.STArea() agreeing to one part in 10^8.
 * A city and a county agreeing looks like independent corroboration and is not. The county's own
 * dedicated service is used here because it is the publisher of record for the county's own seats.
 * ⚠ Op_Election_Dynamic_SP layer 1 is `Election Dropboxes`, a POINT layer — the KS-3 handoff note
 * named the wrong index on the wrong host.
 *
 * ⚠ THE FOUR COUNTYWIDE OFFICES AND THE DISTRICT ATTORNEY NEED NO POLYGON HERE. Clerk, Treasurer,
 * Register of Deeds and Sheriff are elected countywide, and KSA 4-219 makes Sedgwick County alone
 * the 18th judicial district, so all five hang on the TIGER county boundary 20173 / G4020 already in
 * production. Only the five commission districts need custom geometry.
 *
 * ⚠ X0071 WAS CHOSEN BY READING, NOT BY COUNTING — X0001..X0070 were in use, X0070 being KS-3's
 * Wichita council districts. Nothing allocates custom MTFCC codes; the steward allocates migration
 * slots only. A concurrent slice could take the same code and no mechanism would notice. Recorded
 * as a gap, the same as in KS-3.
 *
 * Usage:
 *   node scripts/load-sedgwick-bocc-boundaries.mjs --dry-run
 *   node scripts/load-sedgwick-bocc-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
import { run as verifyVintage } from './verify-sedgwick-bocc-vintage.mjs';
dotenv.config();

const DRY_RUN = process.argv.includes('--dry-run');
const UA = { 'User-Agent': 'ev-accounts/ks-slice14' };
const LAYER =
  'https://gismaps.sedgwickcounty.org/arcgis/rest/services/Map/Op_ElectionBOCC_Dynamic_SP/MapServer/0';
const MTFCC = 'X0071';
const EXPECTED = 5;
const STATE_FIPS = '20';
const COUNTY_GEO_ID = '20173'; // TIGER county, Sedgwick County — already in production
const SOURCE =
  'Sedgwick County GIS, Map/Op_ElectionBOCC_Dynamic_SP/MapServer layer 0 "County Commission ' +
  'Districts" (gismaps.sedgwickcounty.org). Five districts, BOCCDistNO contiguous 1..5. Vintage ' +
  'proved by POPULATION DEVIATION rather than against a prior map, because no prior map is ' +
  'published: the five districts are balanced on 2020 census counts to 0.16% total deviation and ' +
  'account for Sedgwick County 2020 population EXACTLY (523,824 = TIGERweb Counties layer 82, ' +
  'GEOID 20173), with 0 blocks in two districts. A map drawn on 2010 counts cannot be balanced on ' +
  '2020 counts, which is what KSA 19-204 forces reapportionment to fix. NOT independently ' +
  'corroborated: the City of Wichita and the county election service publish the identical ' +
  'geometry, agreeing to one part in 10^8. Read 2026-09-27 (KS-4)';

const fail = (m) => { console.error(`\n🔴 ${m}`); process.exit(1); };

async function fetchDistricts() {
  const url = `${LAYER}/query?where=1%3D1&outFields=BOCCDistNO,BOCCRepNM&outSR=4326&returnGeometry=true&f=geojson`;
  const r = await fetch(url, { headers: UA });
  const text = await r.text();
  // 🔴 A CLEAN HTTP 200 LIES — judge the body, not the status. The county's WAF answers a blocked
  // request with an HTML "Request Rejected" page and a 200.
  if (/^\s*</.test(text)) fail(`BOCC layer: HTML, not JSON (${r.status})`);
  const j = JSON.parse(text);
  if (j.error) fail(`BOCC layer: ${JSON.stringify(j.error)}`);
  // A truncated answer is also a clean 200.
  if (j.exceededTransferLimit) fail('BOCC layer: the service paged — refusing a partial map');
  const feats = j.features ?? [];
  if (feats.length !== EXPECTED) fail(`BOCC layer: ${feats.length} features, expected ${EXPECTED}`);
  const byNum = new Map();
  for (const f of feats) {
    const n = Number(f.properties.BOCCDistNO);
    if (!Number.isInteger(n) || n < 1 || n > EXPECTED) fail(`bad BOCCDistNO ${f.properties.BOCCDistNO}`);
    if (byNum.has(n)) fail(`duplicate BOCCDistNO ${n}`);
    byNum.set(n, f);
  }
  for (let n = 1; n <= EXPECTED; n++) if (!byNum.has(n)) fail(`district ${n} absent`);
  return byNum;
}

// ── The vintage gate, run before anything else ────────────────────────────────────────────────
console.log('running the vintage gate (verify-sedgwick-bocc-vintage.mjs)…\n');
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
   SELECT 'sedgwick-ks-commission-district-' || p.district,
          'Sedgwick County Commission District ' || p.district,
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

// Coverage against the county polygon. Unlike Wichita's council districts, these are expected to
// TILE the county — a county boundary does not move by annexation — so the coverage figure is
// asserted, not merely reported. Measured out of the database before loading: 99.9932%.
const [cov] = await q(
  `WITH d AS (SELECT ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc = $1),
        c AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE geo_id = $2 AND mtfcc = 'G4020')
   SELECT round((ST_Area(c.g::geography)/2589988.11)::numeric, 3) AS county_sq_mi,
          round((ST_Area(d.g::geography)/2589988.11)::numeric, 3) AS districts_sq_mi,
          round((100*ST_Area(ST_Intersection(c.g, d.g)::geography)/ST_Area(c.g::geography))::numeric, 3) AS pct_county_covered,
          round((ST_Area(ST_Difference(d.g, c.g)::geography)/2589988.11)::numeric, 3) AS outside_county
     FROM d, c`, [MTFCC, COUNTY_GEO_ID]);
console.log(`\ncoverage: county ${cov.county_sq_mi} sq mi · districts ${cov.districts_sq_mi} sq mi · ` +
            `${cov.pct_county_covered}% of the county covered · ${cov.outside_county} sq mi outside it`);
if (Number(cov.pct_county_covered) < 99.5) {
  await q('ROLLBACK');
  fail(`the five districts cover only ${cov.pct_county_covered}% of Sedgwick County. They are supposed ` +
       `to tile it — a gap this large means an address in the hole resolves to no commissioner.`);
}

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
  console.log(`\n✅ committed — ${EXPECTED} ${MTFCC} boundaries are in production.`);
}
await client.end();
