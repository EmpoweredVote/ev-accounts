#!/usr/bin/env node
/**
 * load-fulton-commission-districts.mjs — Atlanta full seed, stage 4a geography.
 *
 * Fetches Fulton County's six commission district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='fulton-county-ga-commission-1'..'-6', mtfcc='X0078'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0240 creates the districts and their
 * offices and REFUSES TO RUN if these six boundaries are absent.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 SIX DISTRICTS, SEVEN SEATS. The Chairperson is elected AT LARGE and is not a district.
 * The chair's office hangs on the TIGER county polygon 13121/G4020, which is already in
 * production. Do not look for a seventh polygon — there isn't one, and a count gate expecting
 * seven would fail on correct data.
 *
 * 🔴 DO NOT COPY DEKALB HERE. DeKalb has NO at-large chair and instead elects a county-wide
 * CEO plus two SUPER districts overlaying its five. The two counties are structurally opposite
 * and standardising them would misdescribe both (ROSTERS.md R5, R6).
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE ROSTER COLUMN IS STALE BY TWO HOLDERS AND IS NEVER READ HERE.
 *
 * Both Fulton layers carry `CommName`. Measured 2026-10-17, District 4 reads "Natalie Hall" —
 * who LOST to Mo Ivory in 2024, and Ivory has since RESIGNED, leaving the seat vacant. So the
 * field is two holders behind on the one district whose occupancy is the hardest fact in the
 * wave. The other five are correct, which is what makes it dangerous.
 *
 * **Geometry from here. Occupancy from ROSTERS.md. Never mixed.**
 *
 *   node scripts/load-fulton-commission-districts.mjs --dry-run
 *   node scripts/load-fulton-commission-districts.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0',
  Accept: 'application/json,text/plain,*/*',
};

const ORG = 'https://services1.arcgis.com/AQDHTHDrZzfsFsB5/arcgis/rest/services';
// The ballot authority — the service behind the county's own precinct/district viewer.
const PRIMARY = `${ORG}/VotingDistrictsMapViewerAGOL/FeatureServer/2`;
// The GIS department's standalone copy of the same adopted map.
const CONFIRM = `${ORG}/Commission_Districts_2023/FeatureServer/0`;
// 🔴 The superseded 2013 map, still published alongside the current one.
const SUPERSEDED = `${ORG}/Political_CommissionDistricts_2013/FeatureServer/0`;

const MTFCC = 'X0078';
const EXPECTED = 6;
const COUNTY_GEO_ID = '13121';
const COUNTY_MTFCC = 'G4020';
const STATE_FIPS = '13';

// Tolerances as a percentage of each district's own area (symmetric difference / area).
// 🔴 SET FROM MEASUREMENT, WITH A GAP. A tolerance equal to the measured value cannot fail.
const AGREE_PCT = 0.5;  // GATE 2: every district must differ from the GIS copy by LESS than this
const DIFFER_PCT = 2.0; // GATE 3: at least one district must differ from the 2013 map by MORE

const COVERAGE_MIN_PCT = 99.0;

const SOURCE =
  'Fulton County Registration & Elections, ArcGIS org AQDHTHDrZzfsFsB5, feature service ' +
  'VotingDistrictsMapViewerAGOL layer 2 "Commission Districts", read 2026-10-17. This is the ' +
  'layer the county builds BALLOTS from (the Columbus arbiter rule, ga.md GA-4). 6 single-member ' +
  'districts; the Chairperson is AT LARGE and hangs on county polygon 13121/G4020. Vintage ' +
  'established GEOMETRICALLY: cross-checked live against the county GIS copy Commission_Districts_2023, ' +
  'which it AGREES with, and against Political_CommissionDistricts_2013, which it DISAGREES with. ' +
  '🔴 The CommName column is stale by TWO holders on District 4 and is NOT read.';

const DRY = process.argv.includes('--dry-run');
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

// 🔴 A GATE NOBODY HAS WATCHED FAIL IS NOT A GATE.
//   count    -> GATE 1  drop a district
//   agree    -> GATE 2  point the agreement check at the SUPERSEDED 2013 layer
//   vintage  -> GATE 3  point the disagreement check at the CONFIRM layer, i.e. ask the gate to
//                        tell a map apart from itself. It must refuse.
//   overlap  -> GATE 4  duplicate district 1's polygon onto district 2
//   probe    -> GATE 5  shift whichever district holds Atlanta City Hall away from it
//   coverage -> GATE 6  shrink district 3 to a sliver
//
// ⚠ GATES 2 AND 3 DELIBERATELY READ THE UNTAMPERED FETCH. They are claims about the PUBLISHED
// layers, not about our row list. Without this, `overlap`/`probe`/`coverage` would trip GATE 2
// first and SHADOW the gate they are meant to exercise.
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const districtOf = (p) => {
  const raw = String(p.District ?? p.DISTRICT ?? p.district ?? '');
  const m = raw.match(/(\d+)/);
  return m ? Number(m[1]) : NaN;
};

const getLayer = async (url, label) => {
  const r = await fetch(`${url}/query?where=1%3D1&outFields=*&returnGeometry=true&outSR=4326&f=geojson`, { headers: UA });
  const t = await r.text();
  if (!t.trim().startsWith('{')) fail(`${label}: not JSON (HTTP ${r.status}, ${t.length} bytes)`);
  const j = JSON.parse(t);
  if (j.error) fail(`${label}: ArcGIS error ${JSON.stringify(j.error).slice(0, 180)}`);
  const fs = j.features ?? [];
  if (!fs.length) fail(`${label}: ZERO features — this check would be blind. Fix it before loading.`);
  const bad = fs.filter((f) => !Number.isInteger(districtOf(f.properties)));
  if (bad.length) fail(`${label}: ${bad.length} feature(s) carry no readable district number — blind`);
  return fs;
};

const raw = await getLayer(PRIMARY, 'VotingDistrictsMapViewerAGOL/2');
console.log(`VotingDistrictsMapViewerAGOL layer 2: ${raw.length} features`);

let feats = raw;
if (CONTROL) {
  console.log(`\n⚠ CONTROL "${CONTROL}" ACTIVE — a gate MUST fail below, or the gate is worthless.\n`);
  if (CONTROL === 'count') feats = raw.slice(0, EXPECTED - 1);
}

// ── GATE 1: six districts, numbered 1..6 ─────────────────────────────────────
{
  const nums = feats.map((f) => districtOf(f.properties)).sort((a, b) => a - b);
  if (feats.length !== EXPECTED || new Set(nums).size !== EXPECTED || nums[0] !== 1 || nums[EXPECTED - 1] !== EXPECTED) {
    fail(`GATE 1: expected districts 1..${EXPECTED}, got [${nums.join(',')}]`);
  }
  console.log(`  GATE 1 PASSED: districts ${nums.join(',')} (the Chair is at-large, so there is no 7th polygon)`);
}

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const toRows = (fs) =>
  fs.map((f) => {
    const n = districtOf(f.properties);
    return {
      district: n,
      geo_id: `fulton-county-ga-commission-${n}`,
      name: `Fulton County Commission District ${n}`,
      geom: JSON.stringify(f.geometry),
    };
  });

let rows = toRows(feats);
const json = (rs) => JSON.stringify(rs.map((r) => ({ district: r.district, geo_id: r.geo_id, name: r.name, geom: r.geom })));

const AS_GEOM = `
  SELECT r.district, r.geo_id, r.name,
         ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326))) AS geom
    FROM jsonb_to_recordset($1::jsonb) AS r(district int, geo_id text, name text, geom text)`;

/** Per-district symmetric difference, as a percentage of the primary district's own area. */
const compare = async (a, b) =>
  q(
    `WITH x AS (SELECT r.district, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom),4326)) geom
                  FROM jsonb_to_recordset($1::jsonb) AS r(district int, geom text)),
          y AS (SELECT r.district, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom),4326)) geom
                  FROM jsonb_to_recordset($2::jsonb) AS r(district int, geom text))
     SELECT x.district,
            round((100 * ST_Area(ST_SymDifference(x.geom,y.geom)::geography)
                       / NULLIF(ST_Area(x.geom::geography),0))::numeric, 4) AS pct
       FROM x JOIN y ON y.district = x.district ORDER BY x.district`,
    [JSON.stringify(a.map((r) => ({ district: r.district, geom: r.geom }))),
     JSON.stringify(b.map((r) => ({ district: r.district, geom: r.geom })))],
  );

// ── GATE 2: the ballot layer AGREES with the county GIS copy ─────────────────
{
  const other = toRows(await getLayer(CONTROL === 'agree' ? SUPERSEDED : CONFIRM, 'confirm layer'));
  if (other.length !== EXPECTED) fail(`GATE 2: the confirming layer has ${other.length} features, expected ${EXPECTED}`);
  const d = await compare(toRows(raw), other);
  if (d.length !== EXPECTED) fail(`GATE 2: only ${d.length} district(s) paired up — the district keys do not match`);
  const worst = Math.max(...d.map((x) => Number(x.pct)));
  console.log(`  GATE 2: worst per-district symmetric difference vs Commission_Districts_2023 = ${worst.toFixed(4)}%`);
  if (worst >= AGREE_PCT) fail(`GATE 2: the ballot layer DISAGREES with the county GIS copy by up to ${worst.toFixed(4)}% (limit ${AGREE_PCT}%) — two different maps. Do NOT load.`);
  console.log('  GATE 2 PASSED');
}

// ── GATE 3: the layer DISAGREES with the superseded 2013 map ─────────────────
// 🔴 The load-bearing one. Six is six under both vintages, so only geometry can date this map.
{
  const other = toRows(await getLayer(CONTROL === 'vintage' ? CONFIRM : SUPERSEDED, 'superseded layer'));
  const d = await compare(toRows(raw), other);
  if (d.length !== EXPECTED) fail(`GATE 3: only ${d.length} district(s) paired up — this check is blind`);
  const moved = d.filter((x) => Number(x.pct) > DIFFER_PCT).map((x) => x.district);
  const worst = Math.max(...d.map((x) => Number(x.pct)));
  console.log(`  GATE 3: worst difference vs the 2013 map = ${worst.toFixed(4)}%; districts moved: ${moved.join(',') || 'none'}`);
  if (!moved.length) {
    fail(
      `GATE 3: NO district differs from Political_CommissionDistricts_2013 by more than ${DIFFER_PCT}% — ` +
        `this layer may BE the superseded 2013 map, and the count (${EXPECTED}) cannot tell them apart. Do NOT load.`,
    );
  }
  console.log('  GATE 3 PASSED: this is not the 2013 map');
}

// ── GATE 4: the six districts do not overlap ─────────────────────────────────
{
  if (CONTROL === 'overlap') rows = rows.map((r) => (r.district === 2 ? { ...r, geom: rows.find((x) => x.district === 1).geom } : r));
  const [ov] = await q(
    `WITH d AS (${AS_GEOM})
     SELECT (SELECT count(*) FROM d a JOIN d b ON a.district < b.district
              WHERE ST_Area(ST_Intersection(a.geom,b.geom)::geography) > 1000)::int AS pairs`,
    [json(rows)],
  );
  if (ov.pairs > 0) fail(`GATE 4: ${ov.pairs} pair(s) of commission districts overlap by over 1000 m² — is this one map?`);
  console.log('  GATE 4 PASSED: no two districts overlap');
}

// ── GATE 5: the address probe the product actually runs ──────────────────────
// 🔴 EVERY ANCHOR IS GEOCODED (Census onelineaddress, Public_AR_Current, 2026-10-17) and then
//    CHECKED AGAINST PRODUCTION GEOMETRY for which county it falls in.
const FULTON_GOV = [-84.390034, 33.752699]; // 141 Pryor St SW — Fulton County Government Center. FULTON.
const CITY_HALL = [-84.39028, 33.747923];   // 55 Trinity Ave SW — Atlanta City Hall. FULTON.
const DECATUR = [-84.296456, 33.773683];    // 509 N McDonough St — Decatur city hall. DEKALB, NOT Fulton.
{
  if (CONTROL === 'probe') {
    const [hit] = await q(`WITH d AS (${AS_GEOM}) SELECT district FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326))`, [json(rows), CITY_HALL[0], CITY_HALL[1]]);
    if (!hit) fail('CONTROL probe: no district holds Atlanta City Hall to begin with — nothing to tamper');
    const shift = (co) => (typeof co[0] === 'number' ? [co[0] + 5, co[1]] : co.map(shift));
    rows = rows.map((r) => (r.district === hit.district
      ? { ...r, geom: JSON.stringify(((g) => ({ ...g, coordinates: shift(g.coordinates) }))(JSON.parse(r.geom))) }
      : r));
  }
  const [p] = await q(
    `WITH d AS (${AS_GEOM})
     SELECT (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326)))::int AS gov,
            (SELECT string_agg(district::text,',') FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326))) AS gov_d,
            (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($4,$5),4326)))::int AS city_hall,
            (SELECT string_agg(district::text,',') FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($4,$5),4326))) AS city_hall_d,
            (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($6,$7),4326)))::int AS decatur`,
    [json(rows), FULTON_GOV[0], FULTON_GOV[1], CITY_HALL[0], CITY_HALL[1], DECATUR[0], DECATUR[1]],
  );
  if (p.gov !== 1) fail(`GATE 5: the Fulton County Government Center falls in ${p.gov} commission district(s), expected exactly 1`);
  if (p.city_hall !== 1) fail(`GATE 5: Atlanta City Hall falls in ${p.city_hall} Fulton commission district(s), expected exactly 1`);
  if (p.decatur !== 0) {
    fail(
      `GATE 5: CONTROL FAILED — Decatur city hall falls in ${p.decatur} FULTON commission district(s). ` +
        `Decatur is in DEKALB County. This layer is the wrong ground, and every DeKalb address ` +
        `would be answered with a Fulton commissioner.`,
    );
  }
  console.log(`  GATE 5 PASSED: Government Center → district ${p.gov_d}; Atlanta City Hall → district ${p.city_hall_d}; Decatur → none (control)`);
}

// ── GATE 6: the six districts tile the county ────────────────────────────────
// There is no un-districted ground: every Fulton resident has one district commissioner plus
// the at-large chair. ⚠ Gate the STRUCTURE, not perfect coverage.
{
  if (CONTROL === 'coverage') {
    rows = rows.map((r) => {
      if (r.district !== 3) return r;
      const g = JSON.parse(r.geom);
      const ring = g.type === 'Polygon' ? g.coordinates[0] : g.coordinates[0][0];
      const [x, y] = ring[0];
      return { ...r, geom: JSON.stringify({ type: 'Polygon', coordinates: [[[x, y], [x + 0.001, y], [x + 0.001, y + 0.001], [x, y + 0.001], [x, y]]] }) };
    });
  }
  const [cov] = await q(
    `WITH d AS (${AS_GEOM}),
          u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) geom FROM d),
          c AS (SELECT geometry geom FROM essentials.geofence_boundaries
                 WHERE geo_id=$2 AND mtfcc=$3 AND state=$4)
     SELECT round((100*ST_Area(ST_Intersection(u.geom,c.geom)::geography)
                      / NULLIF(ST_Area(c.geom::geography),0))::numeric,3) AS pct FROM u,c`,
    [json(rows), COUNTY_GEO_ID, COUNTY_MTFCC, STATE_FIPS],
  );
  if (cov.pct === null) fail(`GATE 6: TIGER county ${COUNTY_GEO_ID}/${COUNTY_MTFCC} is not in production`);
  console.log(`  GATE 6: the 6 districts cover ${cov.pct}% of Fulton County`);
  if (Number(cov.pct) < COVERAGE_MIN_PCT) fail(`GATE 6: the districts cover only ${cov.pct}% of Fulton County (floor ${COVERAGE_MIN_PCT}%) — a district is missing or this is the wrong ground.`);
  console.log('  GATE 6 PASSED');
}

if (CONTROL) fail(`CONTROL "${CONTROL}" reached the end WITHOUT firing a gate. The gate it targets is worthless. Fix it.`);

// ── Write ────────────────────────────────────────────────────────────────────
const [before] = await q(`SELECT count(*)::int n FROM essentials.geofence_boundaries WHERE mtfcc=$1`, [MTFCC]);
console.log(`\n  ${MTFCC} currently holds ${before.n} row(s) in production`);

if (DRY) {
  console.table(await q(`WITH d AS (${AS_GEOM}) SELECT geo_id, name, round((ST_Area(geom::geography)/1e6)::numeric,3) km2 FROM d ORDER BY district`, [json(rows)]));
  console.log('\n--dry-run: nothing written.');
  await pool.end();
  process.exit(0);
}

const [{ written }] = await q(
  `WITH d AS (${AS_GEOM}), ins AS (
     INSERT INTO essentials.geofence_boundaries (geo_id,name,state,mtfcc,geometry,source,imported_at)
     SELECT d.geo_id,d.name,$2,$3,d.geom,$4,now() FROM d
     ON CONFLICT (geo_id,mtfcc) DO NOTHING RETURNING 1)
   SELECT count(*)::int AS written FROM ins`,
  [json(rows), STATE_FIPS, MTFCC, SOURCE],
);
console.log(`  inserted ${written} boundary row(s) (idempotent: a re-run inserts 0)`);
const [after] = await q(`SELECT count(*)::int n FROM essentials.geofence_boundaries WHERE mtfcc=$1`, [MTFCC]);
if (after.n !== EXPECTED) fail(`POST: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED}`);
console.log(`  POST PASSED: ${MTFCC} holds ${after.n} rows`);
await pool.end();
