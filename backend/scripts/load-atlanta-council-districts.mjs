#!/usr/bin/env node
/**
 * load-atlanta-council-districts.mjs — Atlanta full seed, stage 3 geography.
 *
 * Fetches Atlanta's twelve City Council district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='atlanta-ga-council-1'..'-12', mtfcc='X0077'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0238 creates the districts and their
 * offices and REFUSES TO RUN if these twelve boundaries are absent — an office on a district
 * with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE SOURCE IS FULTON COUNTY'S ELECTIONS LAYER, NOT THE CITY'S.
 *
 * Fulton County Registration & Elections publishes `VotingDistrictsMapViewerAGOL`, the service
 * behind the county's own precinct/district viewer — the layers it builds BALLOTS from. Layer 8
 * is "City Council Districts" for every municipality in the county, Atlanta among them.
 *
 * That is the Columbus arbiter pattern (`ga.md`, GA-4): when several layers publish the same
 * districts, the one the county builds ballots from is the authority on geometry.
 *
 * ⚠ ATLANTA IS NOT WHOLLY INSIDE FULTON. 6.55% of the city is in DeKalb County, so a Fulton
 *   product could plausibly clip at the county line. IT DOES NOT — GATE 5 proves it with a real
 *   DeKalb-side Atlanta address, and GATE 6 proves it a second time from an unrelated source.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THIS LAYER'S ROSTER COLUMN IS STALE AND IS NEVER READ HERE.
 *
 * Layer 8 carries an `Officers` field. Measured 2026-10-17, it is correct on 9 of 12 districts
 * and wrong on 3 — and the staleness carries TWO DIFFERENT VINTAGES inside one column:
 *
 *   District 2  "Amir R. Farokhi"           — Kelsea Bond holds it
 *   District 11 "Marci Collier Overstreet"  — Wayne Martin holds it; she left in Jan 2026
 *   District 7  "Howard Shook"              — Thomas Worthy holds it; Shook left in Jan 2022
 *
 * Fresh on 9 of 12 is the most dangerous ratio, because the layer reads as maintained.
 * `ga.md` records that freshness is a property of a field, not of a row; Atlanta adds that it is
 * a property of a field IN a row. **Geometry from here. Occupancy from ROSTERS.md. Never mixed.**
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THIRTEEN ROWS, TWELVE DISTRICTS. District 12 is MULTI-PART.
 *
 * The layer returns 13 Atlanta rows. District 12 appears twice, as two DIFFERENT polygons —
 * 1,014 vertices and 27 vertices, the second about 2% of the first. It is one district held by
 * one person, stored as a main body plus a small detached exclave.
 *
 * So the rows are DISSOLVED on DistrNum into a MULTIPOLYGON. A pre-flight asserting
 * "12 polygons for 12 seats" would FAIL ON CORRECT DATA. GATE 1 asserts 12 districts AFTER
 * dissolve and separately asserts that District 12 has exactly 2 parts, so a future change in
 * either direction is caught rather than absorbed.
 *
 *   node scripts/load-atlanta-council-districts.mjs --dry-run
 *   node scripts/load-atlanta-council-districts.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0',
  Accept: 'application/json,text/plain,*/*',
};

const LAYER =
  'https://services1.arcgis.com/AQDHTHDrZzfsFsB5/arcgis/rest/services/' +
  'VotingDistrictsMapViewerAGOL/FeatureServer/8';

const MTFCC = 'X0077';
const EXPECTED = 12;
const PLACE_GEO_ID = '1304000'; // TIGER place, Atlanta city — already in production (GA-1).
const PLACE_MTFCC = 'G4110';
const DEKALB_GEO_ID = '13089';
const COUNTY_MTFCC = 'G4020';
const STATE_FIPS = '13';

// District 12's exclave. Measured 2026-10-17: OBJECTID 2 has 1014 vertices, OBJECTID 35 has 27.
const MULTIPART_DISTRICT = 12;
const MULTIPART_PARTS = 2;

// 🔴 GATE 6's expectation comes from a SOURCE UNRELATED TO ANY GIS LAYER: the Georgia SOS
// certified return for the 2025-11-04 municipal general. Each county reports the precincts it
// ran for each council contest, so a district with a real DeKalb electorate must hold real
// DeKalb ground. DeKalb votes cast, measured from dekalb-2025muni.json:
//   D5 10,327 · D6 928 · D1 27 · D7 1 · every other district 0.
const DEKALB_SUBSTANTIAL = new Set([1, 5, 6]); // the districts that drew MORE THAN 100 DeKalb votes
const DEKALB_SLIVER = new Set([7]);            // drew a DeKalb vote, but only one

// 🔴🔴 THRESHOLD SET FROM MEASUREMENT, WITH A 60× GAP — AND THE FIRST ATTEMPT WAS WRONG.
//
// Measured m² of each district inside DeKalb, 2026-10-17:
//   D5 18,605,822 · D6 4,321,383 · D1 130,397 │ D2 2,152 · D7 1,813 · D12 8 │ all others 0
//
// The first version of this gate asserted that the districts drawing DeKalb PRECINCTS are
// exactly the districts holding DeKalb GROUND. It fired, and it was the gate that was wrong:
//
//   🔴 D7's DeKalb sliver (1,813 m²) is SMALLER than D2's (2,152 m²), yet D7 drew a certified
//      DeKalb vote and D2 drew none.
//
// A precinct is assigned to a county by that county's own voter records, so a tiny sliver can
// hold a handful of registered addresses while a slightly larger one holds none. **Polygon area
// and precinct assignment do not agree at sliver scale, and neither source is in error.** So the
// gate compares only what the two genuinely agree on — SUBSTANTIAL presence — and separately
// asserts that D7 reaches DeKalb at all, because a certified vote was cast there.
//
// The gap between D1 (130,397, the smallest substantial) and D2 (2,152, the largest sliver) is
// about 60×, so the threshold sits in open space rather than on its own measurement.
const DEKALB_MIN_M2 = 100_000;

// The union of the twelve must cover the city. Atlanta is 353.23 km²; the tolerance allows for
// two independent digitisations of the same city limit, not for a missing district.
const COVERAGE_MIN_PCT = 99.0;

const SOURCE =
  'Fulton County Registration & Elections, ArcGIS org AQDHTHDrZzfsFsB5, feature service ' +
  'VotingDistrictsMapViewerAGOL layer 8 "City Council Districts", filtered CityName=\'Atlanta\', ' +
  'read 2026-10-17. This is the layer the county builds BALLOTS from (the Columbus arbiter rule, ' +
  'ga.md GA-4). 13 rows dissolved to 12 districts: District 12 is multi-part, a main body plus a ' +
  'detached exclave. Cross-county coverage PROVED — the layer carries Atlanta\'s DeKalb portion, ' +
  'confirmed by a DeKalb-side Atlanta address and independently by the SOS certified 2025 return, ' +
  'in which districts 1, 5, 6 and 7 drew DeKalb precincts. ' +
  '🔴 The layer\'s Officers column is STALE on 3 of 12 with two distinct vintages and is NOT read.';

const DRY = process.argv.includes('--dry-run');
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

// 🔴 A GATE NOBODY HAS WATCHED FAIL IS NOT A GATE. --control=<name> tampers so that exactly one
// gate must fire. Run every one of these after any edit to this file.
//   count     -> GATE 1  drop district 9
//   multipart -> GATE 1b collapse District 12 to a single part
//   overlap   -> GATE 2  duplicate district 1's geometry onto district 3
//   coverage  -> GATE 4  delete district 10's geometry area (shrink to a sliver)
//   probe     -> GATE 5  shift whichever district holds the Kirkwood anchor away from it
//   dekalb    -> GATE 6  shift district 5 fully out of DeKalb
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const districtOf = (p) => {
  const raw = String(p.DistrNum ?? p.distrnum ?? '');
  const m = raw.match(/(\d+)/);
  return m ? Number(m[1]) : NaN;
};

const getLayer = async () => {
  const url =
    `${LAYER}/query?where=${encodeURIComponent("CityName='Atlanta'")}` +
    '&outFields=*&returnGeometry=true&outSR=4326&f=geojson';
  const r = await fetch(url, { headers: UA });
  const t = await r.text();
  // 🔴 A CLEAN HTTP 200 LIES IN FIVE WAYS. Parse before trusting the status.
  if (!t.trim().startsWith('{')) fail(`layer 8: not JSON (HTTP ${r.status}, ${t.length} bytes)`);
  const j = JSON.parse(t);
  if (j.error) fail(`layer 8: ArcGIS error ${JSON.stringify(j.error).slice(0, 180)}`);
  const fs = j.features ?? [];
  if (!fs.length) fail('layer 8: ZERO features — this load would be blind. Fix it before loading.');
  const bad = fs.filter((f) => !Number.isInteger(districtOf(f.properties)));
  if (bad.length) fail(`layer 8: ${bad.length} feature(s) carry no readable DistrNum — blind`);
  const stray = fs.filter((f) => String(f.properties.CityName).trim() !== 'Atlanta');
  if (stray.length) fail(`layer 8: ${stray.length} non-Atlanta row(s) survived the filter`);
  return fs;
};

const raw = await getLayer();
console.log(`layer 8, CityName='Atlanta': ${raw.length} rows`);

// ── Dissolve 13 rows to 12 districts ─────────────────────────────────────────
const byDistrict = new Map();
for (const f of raw) {
  const n = districtOf(f.properties);
  if (!byDistrict.has(n)) byDistrict.set(n, []);
  byDistrict.get(n).push(f.geometry);
}
let parts = [...byDistrict.entries()].map(([district, geoms]) => ({ district, geoms }));

if (CONTROL) {
  console.log(`\n⚠ CONTROL "${CONTROL}" ACTIVE — a gate MUST fail below, or the gate is worthless.\n`);
  if (CONTROL === 'count') parts = parts.filter((p) => p.district !== 9);
  if (CONTROL === 'multipart') {
    const t = parts.find((p) => p.district === MULTIPART_DISTRICT);
    t.geoms = t.geoms.slice(0, 1);
  }
}

// ── GATE 1: twelve districts, numbered 1..12, after dissolve ─────────────────
{
  const nums = parts.map((p) => p.district).sort((a, b) => a - b);
  if (parts.length !== EXPECTED || nums[0] !== 1 || nums[EXPECTED - 1] !== EXPECTED) {
    fail(`GATE 1: expected districts 1..${EXPECTED} after dissolve, got [${nums.join(',')}]`);
  }
  console.log(`  GATE 1 PASSED: ${raw.length} rows dissolved to districts ${nums.join(',')}`);

  // GATE 1b — the multi-part fact is asserted, not absorbed. If the county ever republishes
  // District 12 as one polygon, or splits another district, this fires instead of going quiet.
  for (const p of parts) {
    const want = p.district === MULTIPART_DISTRICT ? MULTIPART_PARTS : 1;
    if (p.geoms.length !== want) {
      fail(
        `GATE 1b: District ${p.district} arrived as ${p.geoms.length} row(s), expected ${want}. ` +
          `District ${MULTIPART_DISTRICT} is the ONLY multi-part district (a detached exclave). ` +
          `If the layer changed, re-measure before editing this constant.`,
      );
    }
  }
  console.log(`  GATE 1b PASSED: District ${MULTIPART_DISTRICT} is ${MULTIPART_PARTS} parts, every other is 1`);
}

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

/** One MULTIPOLYGON per district, built in PostGIS so the dissolve is the database's own. */
const rowsJson = () =>
  JSON.stringify(
    parts.map((p) => ({
      district: p.district,
      geo_id: `atlanta-ga-council-${p.district}`,
      name: `Atlanta City Council District ${p.district}`,
      geoms: p.geoms.map((g) => JSON.stringify(g)),
    })),
  );

const DISSOLVED = `
  WITH src AS (
    SELECT r.district, r.geo_id, r.name, r.geoms
      FROM jsonb_to_recordset($1::jsonb) AS r(district int, geo_id text, name text, geoms jsonb)
  ), exploded AS (
    SELECT s.district, s.geo_id, s.name,
           ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g.value #>> '{}'), 4326)) AS geom
      FROM src s CROSS JOIN LATERAL jsonb_array_elements(s.geoms) AS g(value)
  )
  SELECT district, geo_id, name,
         ST_Multi(ST_UnaryUnion(ST_Collect(geom))) AS geom
    FROM exploded GROUP BY district, geo_id, name`;

// ── GATE 2: no two districts overlap ─────────────────────────────────────────
{
  const sql =
    CONTROL === 'overlap'
      ? `${DISSOLVED.replace('SELECT district, geo_id, name,', 'SELECT district, geo_id, name,')}`
      : DISSOLVED;
  let [ov] = await q(
    `WITH d AS (${sql})
     SELECT (SELECT count(*) FROM d a JOIN d b ON a.district < b.district
              WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 1000)::int AS pairs`,
    [rowsJson()],
  );
  if (CONTROL === 'overlap') {
    // Copy district 1's geometry onto district 3 and re-ask.
    const p1 = parts.find((p) => p.district === 1);
    parts.find((p) => p.district === 3).geoms = p1.geoms;
    [ov] = await q(
      `WITH d AS (${DISSOLVED})
       SELECT (SELECT count(*) FROM d a JOIN d b ON a.district < b.district
                WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 1000)::int AS pairs`,
      [rowsJson()],
    );
  }
  if (ov.pairs > 0) fail(`GATE 2: ${ov.pairs} pair(s) of council districts overlap by over 1000 m² — is this one map?`);
  console.log('  GATE 2 PASSED: no two districts overlap');
}

// ── GATE 3: the city polygon this must tile is actually in production ────────
const [place] = await q(
  `SELECT round((ST_Area(geometry::geography)/1e6)::numeric, 3) AS km2
     FROM essentials.geofence_boundaries
    WHERE geo_id = $1 AND mtfcc = $2 AND state = $3`,
  [PLACE_GEO_ID, PLACE_MTFCC, STATE_FIPS],
);
if (!place) fail(`GATE 3: TIGER place ${PLACE_GEO_ID}/${PLACE_MTFCC} is not in production — GA-1 must run first`);
console.log(`  GATE 3 PASSED: Atlanta place polygon present, ${place.km2} km²`);

// ── GATE 4: the twelve districts cover the city ──────────────────────────────
// The council has 12 district seats and no un-districted ground, so the union must cover the
// place polygon. ⚠ Gate the STRUCTURE, not perfect coverage — two digitisations of one city
// limit never match exactly, and Columbus proved a coverage gate can fail on correct data.
{
  if (CONTROL === 'coverage') {
    const t = parts.find((p) => p.district === 10);
    const g = JSON.parse(JSON.stringify(t.geoms[0]));
    const ring = g.type === 'Polygon' ? g.coordinates[0] : g.coordinates[0][0];
    const [x, y] = ring[0];
    const tiny = [[x, y], [x + 0.001, y], [x + 0.001, y + 0.001], [x, y + 0.001], [x, y]];
    t.geoms = [{ type: 'Polygon', coordinates: [tiny] }];
  }
  const [cov] = await q(
    `WITH d AS (${DISSOLVED}),
          u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM d),
          p AS (SELECT geometry AS geom FROM essentials.geofence_boundaries
                 WHERE geo_id = $2 AND mtfcc = $3 AND state = $4)
     SELECT round((100 * ST_Area(ST_Intersection(u.geom, p.geom)::geography)
                       / NULLIF(ST_Area(p.geom::geography), 0))::numeric, 3) AS pct_covered
       FROM u, p`,
    [rowsJson(), PLACE_GEO_ID, PLACE_MTFCC, STATE_FIPS],
  );
  console.log(`  GATE 4: the 12 districts cover ${cov.pct_covered}% of the Atlanta place polygon`);
  if (Number(cov.pct_covered) < COVERAGE_MIN_PCT) {
    fail(
      `GATE 4: the districts cover only ${cov.pct_covered}% of Atlanta (floor ${COVERAGE_MIN_PCT}%). ` +
        `A district is missing, clipped at the county line, or this is the wrong ground.`,
    );
  }
  console.log('  GATE 4 PASSED');
}

// ── GATE 5: the address probe the product actually runs ──────────────────────
// 🔴 EVERY ANCHOR IS GEOCODED (Census onelineaddress, Public_AR_Current, 2026-10-17) and each
//    was then CHECKED AGAINST PRODUCTION GEOMETRY for which county and city it falls in.
//    A hand-typed anchor manufactures a false result.
const CITY_HALL = [-84.39028, 33.747923];  // 55 Trinity Ave SW — Atlanta City Hall. Atlanta, FULTON.
const KIRKWOOD = [-84.332913, 33.74751];   // 1660 Memorial Dr SE — Atlanta, DEKALB. The cross-county anchor.
const DECATUR = [-84.296456, 33.773683];   // 509 N McDonough St — Decatur city hall. DEKALB, NOT Atlanta.
{
  if (CONTROL === 'probe') {
    const [hit] = await q(
      `WITH d AS (${DISSOLVED})
       SELECT district FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326))`,
      [rowsJson(), KIRKWOOD[0], KIRKWOOD[1]],
    );
    if (!hit) fail('CONTROL probe: no district holds the Kirkwood anchor to begin with — nothing to tamper');
    const shift = (co) => (typeof co[0] === 'number' ? [co[0] + 5, co[1]] : co.map(shift));
    const t = parts.find((p) => p.district === hit.district);
    t.geoms = t.geoms.map((g) => ({ ...g, coordinates: shift(g.coordinates) }));
  }
  const [probe] = await q(
    `WITH d AS (${DISSOLVED})
     SELECT (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326)))::int AS city_hall,
            (SELECT string_agg(district::text,',') FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326))) AS city_hall_d,
            (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($4,$5),4326)))::int AS kirkwood,
            (SELECT string_agg(district::text,',') FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($4,$5),4326))) AS kirkwood_d,
            (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($6,$7),4326)))::int AS decatur`,
    [rowsJson(), CITY_HALL[0], CITY_HALL[1], KIRKWOOD[0], KIRKWOOD[1], DECATUR[0], DECATUR[1]],
  );
  if (probe.city_hall !== 1) fail(`GATE 5: Atlanta City Hall falls in ${probe.city_hall} council district(s), expected exactly 1`);
  if (probe.kirkwood !== 1) {
    fail(
      `GATE 5: 1660 Memorial Dr SE — an ATLANTA address in DEKALB County — falls in ${probe.kirkwood} ` +
        `council district(s), expected exactly 1. This Fulton-published layer has CLIPPED at the ` +
        `county line, and 6.55% of Atlanta would answer with no council member and no error.`,
    );
  }
  if (probe.decatur !== 0) {
    fail(
      `GATE 5: CONTROL FAILED — Decatur city hall falls in ${probe.decatur} ATLANTA council district(s). ` +
        `Decatur is a separate city in DeKalb County. This layer bleeds beyond Atlanta.`,
    );
  }
  console.log(
    `  GATE 5 PASSED: City Hall → district ${probe.city_hall_d}; Kirkwood (Atlanta-in-DeKalb) → ` +
      `district ${probe.kirkwood_d}; Decatur → no district (control)`,
  );
}

// ── GATE 6: cross-county reach agrees with the CERTIFIED ELECTION RETURN ─────
// 🔴 The load-bearing independent check. GATE 5 proves ONE DeKalb address resolves. This proves
// the whole cross-county shape against a source with no GIS lineage at all: which precincts each
// county actually ran for each council contest in the 2025 certified return.
{
  if (CONTROL === 'dekalb') {
    const t = parts.find((p) => p.district === 5);
    const shift = (co) => (typeof co[0] === 'number' ? [co[0] - 0.6, co[1]] : co.map(shift));
    t.geoms = t.geoms.map((g) => ({ ...g, coordinates: shift(g.coordinates) }));
  }
  const reach = await q(
    `WITH d AS (${DISSOLVED}),
          k AS (SELECT geometry AS geom FROM essentials.geofence_boundaries
                 WHERE geo_id = $2 AND mtfcc = $3 AND state = $4)
     SELECT d.district,
            round(ST_Area(ST_Intersection(d.geom, k.geom)::geography)::numeric, 0) AS m2_in_dekalb
       FROM d, k ORDER BY d.district`,
    [rowsJson(), DEKALB_GEO_ID, COUNTY_MTFCC, STATE_FIPS],
  );
  if (reach.length !== EXPECTED) fail(`GATE 6: only ${reach.length} district(s) measured — this check is blind`);
  // 🔴 PRINT THE MEASUREMENT BEFORE THE ASSERTION. A gate that only prints its verdict teaches a
  //    failure nothing, and this threshold must be re-derived whenever the map changes.
  console.log(
    '  GATE 6 measured m² in DeKalb: ' +
      reach.map((r) => `D${r.district}=${Number(r.m2_in_dekalb).toLocaleString('en-US')}`).join('  '),
  );
  const area = new Map(reach.map((r) => [r.district, Number(r.m2_in_dekalb)]));
  const got = new Set(reach.filter((r) => Number(r.m2_in_dekalb) > DEKALB_MIN_M2).map((r) => r.district));
  const missing = [...DEKALB_SUBSTANTIAL].filter((n) => !got.has(n));
  const extra = [...got].filter((n) => !DEKALB_SUBSTANTIAL.has(n));
  console.log(`  GATE 6: districts holding SUBSTANTIAL DeKalb ground = [${[...got].sort((a, b) => a - b).join(',')}]`);
  if (missing.length || extra.length) {
    fail(
      `GATE 6: cross-county reach DISAGREES with the certified 2025 return. ` +
        `Expected [${[...DEKALB_SUBSTANTIAL].join(',')}] to hold substantial DeKalb ground ` +
        `(they drew more than 100 DeKalb votes); missing [${missing.join(',') || 'none'}], ` +
        `unexpected [${extra.join(',') || 'none'}].`,
    );
  }
  // The sliver half. D7 drew ONE certified DeKalb vote, so its polygon must reach DeKalb at all —
  // but it must NOT reach substantially, or the vote count and the ground would disagree.
  for (const n of DEKALB_SLIVER) {
    const m2 = area.get(n) ?? 0;
    if (!(m2 > 0)) {
      fail(
        `GATE 6: District ${n} holds ZERO DeKalb ground, but the certified 2025 return records a ` +
          `DeKalb vote cast in it. The layer has clipped this district at the county line.`,
      );
    }
    if (m2 > DEKALB_MIN_M2) {
      fail(`GATE 6: District ${n} holds ${m2.toLocaleString('en-US')} m² in DeKalb but drew only one DeKalb vote — re-measure before trusting either source.`);
    }
  }
  console.log(`  GATE 6 PASSED: substantial presence agrees with the ballot record, and D${[...DEKALB_SLIVER].join(',')} reaches DeKalb as a sliver`);
}

if (CONTROL) fail(`CONTROL "${CONTROL}" reached the end WITHOUT firing a gate. The gate it targets is worthless. Fix it.`);

// ── Write ────────────────────────────────────────────────────────────────────
const existing = await q(
  `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
console.log(`\n  ${MTFCC} currently holds ${existing[0].n} row(s) in production`);

if (DRY) {
  const preview = await q(`WITH d AS (${DISSOLVED})
    SELECT geo_id, name, ST_NumGeometries(geom) AS parts,
           round((ST_Area(geom::geography)/1e6)::numeric,3) AS km2
      FROM d ORDER BY district`, [rowsJson()]);
  console.table(preview);
  console.log('\n--dry-run: nothing written.');
  await pool.end();
  process.exit(0);
}

const [{ written }] = await q(
  `WITH d AS (${DISSOLVED}),
        ins AS (
    INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
    SELECT d.geo_id, d.name, $2, $3, d.geom, $4, now() FROM d
    ON CONFLICT (geo_id, mtfcc) DO NOTHING
    RETURNING 1)
   SELECT count(*)::int AS written FROM ins`,
  [rowsJson(), STATE_FIPS, MTFCC, SOURCE],
);
console.log(`  inserted ${written} boundary row(s) (idempotent: a re-run inserts 0)`);

const [after] = await q(
  `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
if (after.n !== EXPECTED) fail(`POST: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED}`);
console.log(`  POST PASSED: ${MTFCC} holds ${after.n} rows`);
await pool.end();
