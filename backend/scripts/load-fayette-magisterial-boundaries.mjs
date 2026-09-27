#!/usr/bin/env node
/**
 * load-fayette-magisterial-boundaries.mjs — Knight program, wave KY-4.
 *
 * Builds Fayette County's three Magisterial District polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='fayette-county-ky-magisterial-district-1'..'-3',
 *                                   mtfcc='X0069'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0154 creates the districts and their offices
 * and REFUSES TO RUN if these three boundaries are absent — an office on a district with no polygon
 * is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * ONE SET OF POLYGONS, USED TWICE. Ky. Const. § 99 elects, in each Justice's District, ONE Justice
 * of the Peace (Magistrate) AND ONE Constable. Fayette has three such districts, so these three
 * polygons carry SIX offices. The county's own certified November 2022 general results pair up
 * district by district, which is what established they are the same districts:
 *     D1 magistrate 18,904 / constable 18,950
 *     D2 magistrate 21,740 / constable 23,292
 *     D3 magistrate 22,851 / constable 22,684
 *
 * ⚠ THE FISCAL COURT IS NOT ON THESE POLYGONS. Fayette's three Fiscal Court Commissioners are
 * elected AT-LARGE — charter 11.02 says so, and the same certified results prove it: the
 * commissioners polled 66,529 / 66,114 / 503 at countywide scale against a 102,742-vote countywide
 * judge/executive race, while the magistrates and constables polled one-third of that. The
 * `DIST 1/2/3` on a commissioner ballot line is a SEAT NUMBER, not a geography.
 *
 * 🔴 THERE IS NO SUPERSEDED MAGISTERIAL LAYER, SO KY-3's AREA TEST CANNOT BE RUN HERE, AND THAT
 * ABSENCE IS THE FINDING RATHER THAN AN OVERSIGHT. Lexington publishes SIX council-district layers
 * (current plus _1972, _1982, _1992, _2002, _2012) and KY-3 proved the live one by area against
 * _2012. The catalogue carries exactly ONE magisterial layer. So vintage here rests on:
 *   * the publisher is the city's own GIS account, `gis_lfucg`;
 *   * item created 2020-12-18 — after the 2020 census, so it is not a pre-redistricting map;
 *   * `editingInfo.lastEditDate` 2025-04-24, inside the current term;
 *   * ⚠ its `MAGREP` attribute names `Chrysanthia Carr-Seals (D)` in district 3 — a person who
 *     took that seat only AFTER George Biggerstaff left it on 2023-08-26, so the layer has been
 *     maintained into the current term. THIS IS CORROBORATION, NOT PROOF. KY-2 found the state's
 *     own GIS layer carrying a STALE roster beside CORRECT geometry; attributes and geometry are
 *     independent and neither vouches for the other.
 * What IS proved here, by measurement, is COMPLETENESS and TILING: three disjoint districts that
 * cover the county. A stale map of the same county would also tile it, so tiling is a correctness
 * test, not a vintage test, and it is reported as such.
 *
 * `wkid 102679` / `latestWkid 2246` is KY State Plane North in FEET — `outSR=4326` is load-bearing,
 * exactly as it was in KY-1.
 *
 * Usage:
 *   node scripts/load-fayette-magisterial-boundaries.mjs --dry-run
 *   node scripts/load-fayette-magisterial-boundaries.mjs
 *
 * Controls — each tampers ONE expectation so the matching gate can be watched firing:
 *   KY4_CONTROL=count     expect 4 features, not 3        -> the feature-count gate
 *   KY4_CONTROL=coverage  demand 150% place coverage      -> the tiling gate
 *   KY4_CONTROL=disjoint  treat any overlap as fatal at 0 -> the disjointness gate
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const DRY_RUN = process.argv.includes('--dry-run');
const CONTROL = process.env.KY4_CONTROL || '';
const UA = { 'User-Agent': 'ev-accounts/ky-slice13' };
const ORG = 'https://services1.arcgis.com/Mg7DLdfYcSWIaDnu/arcgis/rest/services';
const LIVE = `${ORG}/Magisterial_District/FeatureServer/0`;
const MTFCC = 'X0069';
const EXPECTED = CONTROL === 'count' ? 4 : 3;
const STATE_FIPS = '21';
const PLACE_GEO_ID = '2146027'; // TIGER place, measured coterminous with county 21067 in KY-3
const MIN_PLACE_COVERAGE = CONTROL === 'coverage' ? 150 : 99.5;
// ⚠ THE DISJOINT CONTROL IS -1, NOT 0, AND THAT IS THE POINT. Set to 0 it did NOT fire: the three
// districts overlap by exactly 0.000000 sq mi, so `0 > 0` is false and the tamper silently passed —
// a control that cannot fail proves nothing about the gate behind it. -1 makes the true measurement
// trip the comparison, so the gate and its message are actually exercised.
const MAX_OVERLAP_SQ_MI = CONTROL === 'disjoint' ? -1 : 0.05;
const SOURCE =
  'Lexington-Fayette Urban County Government, Magisterial_District feature service ' +
  '(services1.arcgis.com/Mg7DLdfYcSWIaDnu, owner gis_lfucg, item created 2020-12-18, ' +
  'lastEditDate 2025-04-24). Three districts, proved disjoint and proved to tile the ' +
  'county/place polygon. NO SUPERSEDED MAGISTERIAL LAYER IS PUBLISHED, so KY-3\'s area-vs-prior ' +
  'vintage test could not be run and vintage rests on the publisher, the post-2020 creation date ' +
  'and the 2025 edit date; the layer MAGREP attribute naming a post-2023 arrival is corroboration ' +
  'only. These same three polygons carry BOTH the Magistrate and the Constable of each district ' +
  '(Ky. Const. s 99). Read 2026-09-26 (KY-4)';

const fail = (m) => { console.error(`\n🔴 ${m}`); process.exit(1); };

if (CONTROL) console.log(`⚠ KY4_CONTROL=${CONTROL} — a gate is being tampered with on purpose.\n`);

async function fetchLayer(base, label, fields) {
  const url = `${base}/query?where=1%3D1&outFields=${fields}&outSR=4326&returnGeometry=true&f=geojson`;
  const r = await fetch(url, { headers: UA });
  if (!r.ok) fail(`${label}: HTTP ${r.status}`);
  const j = await r.json();
  if (j.error) fail(`${label}: ${JSON.stringify(j.error)}`);
  // 🔴 A TRUNCATED ANSWER IS A CLEAN HTTP 200. Refuse a paged response.
  if (j.exceededTransferLimit) fail(`${label}: the service paged the response — refusing a partial map`);
  const feats = j.features ?? [];
  if (feats.length !== EXPECTED) {
    fail(`[magisterial count assertion] ${label}: ${feats.length} features, expected ${EXPECTED}`);
  }
  const byNum = new Map();
  for (const f of feats) {
    // 🔴 MAGISTERIAL is a smallint here, but never cast a district code blind — KY-1's rule,
    // where 'H001' parsed to NaN. Assert the parse instead of trusting it.
    const raw = f.properties.MAGISTERIAL;
    const n = Number(raw);
    if (!Number.isInteger(n) || n < 1 || n > EXPECTED) fail(`${label}: bad MAGISTERIAL ${JSON.stringify(raw)}`);
    if (byNum.has(n)) fail(`${label}: duplicate MAGISTERIAL ${n}`);
    byNum.set(n, f);
  }
  for (let n = 1; n <= EXPECTED; n++) if (!byNum.has(n)) fail(`${label}: district ${n} absent`);
  return byNum;
}

const live = await fetchLayer(LIVE, 'Magisterial_District', 'MAGISTERIAL,MAGREP');
console.log('layer roster (corroboration only, NOT written):');
for (let n = 1; n <= EXPECTED; n++) console.log(`  district ${n}: ${live.get(n).properties.MAGREP}`);

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
   SELECT 'fayette-county-ky-magisterial-district-' || p.district,
          'Fayette County Magisterial District ' || p.district,
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

// ── Tiling. Fayette is consolidated and the place polygon was measured coterminous with the
//    county in KY-3, so three magisterial districts must cover it. This proves COMPLETENESS.
//    It does NOT prove vintage — a superseded map of the same county would tile it too.
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
if (Number(cov.pct_place_covered) < MIN_PLACE_COVERAGE) {
  await q('ROLLBACK');
  fail(`[magisterial tiling assertion] the three districts cover only ${cov.pct_place_covered}% of ` +
       `the place polygon, expected at least ${MIN_PLACE_COVERAGE}%. An uncovered strip is an ` +
       `address that resolves to no magistrate and no constable, and nothing would error.`);
}

// ── Disjointness. Two digitizations of one boundary need a TOLERANCE, not ST_Equals or a bare
//    ST_Overlaps: shared edges produce sliver intersections of a few square feet.
const [ov] = await q(
  `WITH b AS (SELECT geo_id, geometry FROM essentials.geofence_boundaries WHERE mtfcc = $1)
   SELECT coalesce(round((max(ST_Area(ST_Intersection(a.geometry, c.geometry)::geography))/2589988.11)::numeric, 6), 0)
            AS max_overlap_sq_mi,
          count(*)::int AS pairs
     FROM b a JOIN b c ON a.geo_id < c.geo_id`, [MTFCC]);
console.log(`disjointness: ${ov.pairs} pair(s), largest overlap ${ov.max_overlap_sq_mi} sq mi`);
if (Number(ov.max_overlap_sq_mi) > MAX_OVERLAP_SQ_MI) {
  await q('ROLLBACK');
  fail(`[magisterial disjointness assertion] two districts overlap by ${ov.max_overlap_sq_mi} sq mi, ` +
       `above the ${MAX_OVERLAP_SQ_MI} sq mi sliver tolerance. An overlapping pair returns TWO ` +
       `magistrates and TWO constables to one address.`);
}

// ── Per-district control: every district must resolve to exactly one, and to itself.
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
