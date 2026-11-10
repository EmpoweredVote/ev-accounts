#!/usr/bin/env node
/**
 * load-reno-washoe-districts.mjs — Reno NV + Washoe County deep seed, stage 1 geography.
 *
 * Fetches two district layers and inserts them into essentials.geofence_boundaries:
 *
 *   X0086  reno-nv-council-ward-1..6          City of Reno council wards
 *   X0087  washoe-nv-commission-district-1..5 Washoe County commission districts
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migrations (CC_0385 Reno,
 * CC_0386 Washoe) create the districts and their offices and REFUSE TO RUN if these
 * boundaries are absent — an office on a district with no polygon is unreachable by any
 * address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE OBVIOUSLY-NAMED RENO WARD LAYER IS THE SUPERSEDED ONE. READ THIS BEFORE EDITING.
 *
 * The City of Reno publishes TWO ward services on its own domains, and the one whose name
 * and folder look authoritative is the dead one:
 *
 *   citymaps.reno.gov  AdminAreas/Reno_Wards/MapServer   layers 8..12 → Ward1..Ward5  ❌ STALE
 *   pwmaps.reno.gov    PublicWorks/City_Wards/MapServer/0 → WARD ONE..WARD SIX        ✅ CURRENT
 *
 * Reno moved from five wards to six under a 2017 act of the Nevada Legislature (AB36); the
 * sixth ward replaced the at-large council seat at the 2024 general election, and the City
 * Charter now requires six (Reno City Charter § 1.050(1), § 2.010(1)). A loader that picked
 * by name would have seeded the five-ward map, and — this is the whole point — it would have
 * passed a row-count check, a roster cross-check and a reachability check, because every
 * Reno address still lands in SOME ward. See [[project_council_district_vintage_gate]].
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * THE ARBITER IS THE COUNTY'S VOTER PRECINCT LAYER, NOT EITHER WARD LAYER.
 *
 * Washoe County's Registrar of Voters conducts Reno's municipal elections, so the layer the
 * county builds BALLOTS from is the authority (the Columbus arbiter rule). OpenData layer 7
 * "Voter Precincts" carries RWARDS (Reno ward, 0 = outside Reno) and COMMISSION (commission
 * district) on every precinct, and its DATE_MOD runs to 2026-02-25 — it knows Ward 6.
 *
 * GATE 5 asserts that every Reno precinct's interior point falls in the ward its RWARDS says,
 * and every precinct's interior point falls in the commission district its COMMISSION says.
 * GATE 6 then runs the SAME test against the superseded five-ward layer and REQUIRES IT TO
 * FAIL — because a gate that cannot tell the current map from the dead one is not a gate.
 *
 * 🔴 BOTH ward layers carry a COUNCIL_MEMBER / REP column. Geometry is taken from them;
 * occupancy is NOT. A name field dates the roster, never the boundary — that is exactly how
 * Los Angeles served a 2012 council map for years while carrying a sitting member's name.
 *
 *   node scripts/load-reno-washoe-districts.mjs --dry-run
 *   node scripts/load-reno-washoe-districts.mjs --control=count
 *   node scripts/load-reno-washoe-districts.mjs
 */
import pg from 'pg';
import fs from 'node:fs';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = {
  'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  Accept: 'application/json,text/plain,*/*',
};

const WARD_LAYER =
  'https://pwmaps.reno.gov/server/rest/services/PublicWorks/City_Wards/MapServer/0';
const WARD_LAYER_SUPERSEDED =
  'https://citymaps.reno.gov/server/rest/services/AdminAreas/Reno_Wards/MapServer';
const COUNTY_BASE =
  'https://wcgisweb.washoecounty.us/arcgis/rest/services/OpenData/OpenData/FeatureServer';
const COMM_LAYER = `${COUNTY_BASE}/4`;
const PRECINCT_LAYER = `${COUNTY_BASE}/7`;

const STATE_FIPS = '32';
const WARD_MTFCC = 'X0086';
const COMM_MTFCC = 'X0087';
const WARDS_EXPECTED = 6;
const COMM_EXPECTED = 5;

const RENO_PLACE = { geo_id: '3260600', mtfcc: 'G4110' };
const WASHOE_COUNTY = { geo_id: '32031', mtfcc: 'G4020' };

// Census ACS2024 TIGERweb, read 2026-11-09. Authoritative constants, not measurements of our
// own polygons. Reno place 3260600 and Washoe county 32031 each reconcile to the production
// polygon exactly when ALAND + AWATER are added (289.6 km² and 16,940.8 km²).
const RENO_ALAND_M2 = 282_280_412;
const RENO_AWATER_M2 = 7_338_575;
const WASHOE_ALAND_M2 = 16_358_036_307;
const WASHOE_AWATER_M2 = 582_745_905;

// Measured 2026-11-09 before this script existed: the wards leave 0.290 km² of the place
// polygon uncovered and the commission districts leave 0.8 km² of the county. These ceilings
// leave room for a redigitised edge and still fail long before a missing district.
const RENO_UNCOVERED_MAX_KM2 = 5.0;
const WASHOE_UNCOVERED_MAX_KM2 = 25.0;
const GAP_PROBE_MIN_KM2 = 1.0;

// 🔴 BASELINE ON IDENTITIES, NOT COUNTS. A count baseline cannot see a defect that REPLACES
// another — fix one precinct the week a different one drifts and the number is unchanged while
// the facts are not. So GATE 5 names the precincts it forgives, and reports any that leave.
//
// 9113 — commission only. Measured 2026-11-09: this 0.066 km² precinct STRADDLES the boundary
// between commission districts 1 and 5 (79.2% / 20.8%), while the Registrar assigns the whole
// precinct to district 1. Both layers come from the same county GIS, so one of the two is
// slightly stale along that edge. It is forgiven because it cannot misroute anybody: the
// county's OWN address-point layer (OpenData layer 8) holds ZERO addresses inside precinct
// 9113, against 185 in the surrounding bounding box — which is the positive control proving
// that layer was answering. No address, no wrong commissioner.
const KNOWN_COMMISSION_PRECINCT_MISMATCHES = new Set([9113]);
const KNOWN_WARD_PRECINCT_MISMATCHES = new Set();

const WARD_SOURCE =
  'City of Reno Public Works GIS, pwmaps.reno.gov PublicWorks/City_Wards/MapServer layer 0 ' +
  '"City Wards", 6 features WARD ONE..WARD SIX, read 2026-11-09. THE CURRENT SIX-WARD MAP. ' +
  'Reno moved from five wards to six under Nevada AB36 (2017); the sixth ward replaced the ' +
  'at-large council seat at the 2024 general election and the City Charter now requires six ' +
  '(Reno City Charter s 1.050(1), s 2.010(1)). 🔴 The city ALSO publishes the SUPERSEDED ' +
  'five-ward map at citymaps.reno.gov AdminAreas/Reno_Wards/MapServer layers 8-12, whose ' +
  'name and folder look more authoritative; picking by name seeds the dead map. VINTAGE ' +
  'PROVED against the Washoe County Registrar of Voters precinct layer (wcgisweb.washoecounty.us ' +
  'OpenData layer 7 "Voter Precincts", field RWARDS, DATE_MOD to 2026-02-25) — the layer the ' +
  'county builds BALLOTS from, the Columbus arbiter rule — on all 161 Reno precincts; the ' +
  'superseded five-ward layer disagrees with that same arbiter on a large minority of them, ' +
  'which is the converse test. Independently corroborated by the county GIS copy of the same ' +
  'six-ward map (OpenData layer 122 "Reno Wards"): 899 of 899 interior points agree. 🔴 Both ' +
  'ward layers carry a council-member name column and NEITHER is read for occupancy.';

const COMM_SOURCE =
  'Washoe County GIS, wcgisweb.washoecounty.us OpenData/OpenData/FeatureServer layer 4 ' +
  '"Commissioner Districts", 5 features CDNO 1..5, read 2026-11-09 — the county\'s own ' +
  'server, not a re-publication (the City of Reno and NDOT both republish copies, and an ' +
  'arcgis.com search returns those first). The five districts are disjoint and tile the ' +
  'census county polygon to 99.995%. VINTAGE PROVED against the same county Registrar ' +
  'precinct layer (OpenData layer 7, field COMMISSION) on all 472 Washoe precincts. 🔴 The ' +
  'layer\'s COMMISSIONER column is NOT read for occupancy.';

const DRY = process.argv.includes('--dry-run');
const EMIT = (process.argv.find((a) => a.startsWith('--emit-sql=')) || '').split('=').slice(1).join('=');
const lit = (s) => `'${String(s).replace(/'/g, "''")}'`;
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

// 🔴 A GATE NOBODY HAS WATCHED FAIL IS NOT A GATE. --control=<name> tampers so that exactly
// one gate must fire. Run every one of these after any edit to this file.
//   count     -> GATE 1  drop ward 6 (the ward the stale map does not have)
//   overlap   -> GATE 2  copy ward 1's geometry onto ward 3
//   coverage  -> GATE 4  shrink ward 4 (the largest) to a sliver
//   arbiter   -> GATE 5  swap wards 2 and 3, so the precinct arbiter must reject them
//   vacuous   -> GATE 6  feed the CURRENT map in place of the superseded one, so the
//                        converse test finds no disagreement and must complain
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const getJson = async (url, what) => {
  const r = await fetch(url, { headers: UA });
  const t = await r.text();
  // 🔴 A CLEAN HTTP 200 LIES IN SEVERAL WAYS. Parse before trusting the status.
  if (!t.trim().startsWith('{')) fail(`${what}: not JSON (HTTP ${r.status}, ${t.length} bytes)`);
  const j = JSON.parse(t);
  if (j.error) fail(`${what}: ArcGIS error ${JSON.stringify(j.error).slice(0, 200)}`);
  return j;
};

const queryGeo = async (base, fields, what) => {
  const url =
    `${base}/query?where=1%3D1&outFields=${encodeURIComponent(fields)}` +
    `&returnGeometry=true&outSR=4326&geometryPrecision=7&f=geojson`;
  const j = await getJson(url, what);
  const feats = j.features ?? [];
  if (!feats.length) fail(`${what}: ZERO features — this load would be blind.`);
  return feats;
};

const num = (v) => {
  const m = String(v ?? '').match(/(\d+)/);
  return m ? Number(m[1]) : NaN;
};

// ── Fetch everything up front ────────────────────────────────────────────────
const wardFeats = await queryGeo(WARD_LAYER, 'WARD,WARD_NUM', 'Reno Public Works City_Wards');
console.log(`Reno Public Works "City Wards": ${wardFeats.length} rows`);

const commFeats = await queryGeo(COMM_LAYER, 'CDNO,DISTRICT,COMMISSIONER', 'Washoe Commissioner Districts');
console.log(`Washoe County "Commissioner Districts": ${commFeats.length} rows`);

const precFeats = await queryGeo(
  PRECINCT_LAYER,
  'PRECINCT,RWARDS,COMMISSION',
  'Washoe Voter Precincts',
);
console.log(`Washoe County "Voter Precincts": ${precFeats.length} rows (the ballot arbiter)`);

// The superseded five-ward map, fetched only so GATE 6 can prove the arbiter discriminates.
const supersededFeats = [];
for (const [layerId, wardNum] of [[8, 1], [9, 2], [10, 3], [11, 4], [12, 5]]) {
  const fs_ = await queryGeo(
    `${WARD_LAYER_SUPERSEDED}/${layerId}`,
    '*',
    `citymaps superseded ward layer ${layerId}`,
  );
  for (const f of fs_) supersededFeats.push({ ward: wardNum, geometry: f.geometry });
}
console.log(`citymaps SUPERSEDED five-ward map: ${supersededFeats.length} rows (for GATE 6 only)`);

// ── Shape into {num, geoms} parts ────────────────────────────────────────────
const dissolve = (feats, keyFn) => {
  const by = new Map();
  for (const f of feats) {
    const n = keyFn(f.properties);
    if (!Number.isInteger(n)) fail(`a feature carries no readable district number — blind load`);
    if (!by.has(n)) by.set(n, []);
    by.get(n).push(f.geometry);
  }
  return [...by.entries()].map(([n, geoms]) => ({ num: n, geoms })).sort((a, b) => a.num - b.num);
};

let wards = dissolve(wardFeats, (p) => num(p.WARD_NUM ?? p.WARD));
let comms = dissolve(commFeats, (p) => num(p.CDNO ?? p.DISTRICT));
let superseded = (() => {
  const by = new Map();
  for (const f of supersededFeats) {
    if (!by.has(f.ward)) by.set(f.ward, []);
    by.get(f.ward).push(f.geometry);
  }
  return [...by.entries()].map(([n, geoms]) => ({ num: n, geoms })).sort((a, b) => a.num - b.num);
})();

if (CONTROL) {
  console.log(`\n⚠ CONTROL "${CONTROL}" ACTIVE — a gate MUST fail below, or the gate is worthless.\n`);
  if (CONTROL === 'count') wards = wards.filter((w) => w.num !== 6);
  if (CONTROL === 'overlap') wards.find((w) => w.num === 3).geoms = wards.find((w) => w.num === 1).geoms;
  if (CONTROL === 'arbiter') {
    const w2 = wards.find((w) => w.num === 2).geoms;
    wards.find((w) => w.num === 2).geoms = wards.find((w) => w.num === 3).geoms;
    wards.find((w) => w.num === 3).geoms = w2;
  }
  if (CONTROL === 'vacuous') superseded = wards.filter((w) => w.num <= 5).map((w) => ({ ...w }));
}

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 2 });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const partsJson = (parts, geoIdFn, nameFn) =>
  JSON.stringify(parts.map((p) => ({ num: p.num, geo_id: geoIdFn(p.num), name: nameFn(p.num), geoms: p.geoms })));

const wardsJson = () =>
  partsJson(wards, (n) => `reno-nv-council-ward-${n}`, (n) => `Reno City Council Ward ${n}`);
const commsJson = () =>
  partsJson(comms, (n) => `washoe-nv-commission-district-${n}`, (n) => `Washoe County Commission District ${n}`);
const supersededJson = () => partsJson(superseded, (n) => `superseded-${n}`, (n) => `superseded ward ${n}`);

const DISSOLVED = `
  SELECT r.num, r.geo_id, r.name,
         ST_Multi(ST_UnaryUnion(ST_Collect(
           ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g.value #>> '{}'), 4326))
         ))) AS geom
    FROM jsonb_to_recordset($1::jsonb) AS r(num int, geo_id text, name text, geoms jsonb)
    CROSS JOIN LATERAL jsonb_array_elements(r.geoms) AS g(value)
   GROUP BY r.num, r.geo_id, r.name`;

// Precinct interior points, computed once in PostGIS and reused by GATES 5 and 6.
const PRECINCTS = `
  SELECT p.precinct, p.rwards, p.commission,
         ST_PointOnSurface(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(p.geom #>> '{}'), 4326))) AS pt
    FROM jsonb_to_recordset($2::jsonb) AS p(precinct int, rwards int, commission int, geom jsonb)`;

const precinctsJson = JSON.stringify(
  precFeats.map((f) => ({
    precinct: Number(f.properties.PRECINCT),
    rwards: num(f.properties.RWARDS ?? 0) || 0,
    commission: num(f.properties.COMMISSION ?? 0) || 0,
    geom: f.geometry,
  })),
);

// ── GATE 1: the right districts, numbered contiguously ───────────────────────
{
  const check = (parts, expected, what) => {
    const nums = parts.map((p) => p.num);
    if (parts.length !== expected || nums[0] !== 1 || nums[expected - 1] !== expected) {
      fail(`GATE 1: expected ${what} 1..${expected} after dissolve, got [${nums.join(',')}]`);
    }
  };
  check(wards, WARDS_EXPECTED, 'Reno wards');
  check(comms, COMM_EXPECTED, 'Washoe commission districts');
  console.log(`  GATE 1 PASSED: wards ${wards.map((w) => w.num).join(',')} · commission ${comms.map((c) => c.num).join(',')}`);
}

// ── GATE 2: no two districts of the same layer overlap ───────────────────────
{
  for (const [json, what] of [[wardsJson(), 'Reno wards'], [commsJson(), 'Washoe commission districts']]) {
    const [ov] = await q(
      `WITH d AS (${DISSOLVED})
       SELECT (SELECT count(*) FROM d a JOIN d b ON a.num < b.num
                WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 100000)::int AS pairs`,
      [json],
    );
    if (ov.pairs > 0) fail(`GATE 2: ${ov.pairs} pair(s) of ${what} overlap by over 0.1 km² — is this one map?`);
  }
  console.log('  GATE 2 PASSED: neither layer self-overlaps');
}

// ── GATE 3: the parent polygons these must tile are in production ────────────
{
  for (const p of [RENO_PLACE, WASHOE_COUNTY]) {
    const [row] = await q(
      `SELECT name, round((ST_Area(geometry::geography)/1e6)::numeric,2) AS km2
         FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc=$2`,
      [p.geo_id, p.mtfcc],
    );
    if (!row) fail(`GATE 3: parent polygon ${p.geo_id}/${p.mtfcc} is not in production`);
    console.log(`  GATE 3: ${row.name} (${p.geo_id}/${p.mtfcc}) present, ${row.km2} km²`);
  }
  console.log('  GATE 3 PASSED');
}

// ── GATE 4: each layer covers at least its parent's CENSUS LAND AREA ─────────
// 🔴 A PERCENTAGE-OF-POLYGON GATE ASKS THE WRONG QUESTION — a place polygon includes water,
// and districts are drawn over land. What matters is whether a real address can fall outside
// every district, so the test is against ALAND, with the leftover gap pieces reported.
const gapsFor = {};
{
  const cases = [
    { name: 'Reno wards', json: wardsJson(), parent: RENO_PLACE, aland: RENO_ALAND_M2, awater: RENO_AWATER_M2, ceil: RENO_UNCOVERED_MAX_KM2 },
    { name: 'Washoe commission', json: commsJson(), parent: WASHOE_COUNTY, aland: WASHOE_ALAND_M2, awater: WASHOE_AWATER_M2, ceil: WASHOE_UNCOVERED_MAX_KM2 },
  ];
  for (const c of cases) {
    let json = c.json;
    if (CONTROL === 'coverage' && c.name === 'Reno wards') {
      const o = JSON.parse(json);
      o.find((r) => r.num === 4).geoms = [
        { type: 'Polygon', coordinates: [[[-119.81, 39.52], [-119.81, 39.521], [-119.809, 39.521], [-119.809, 39.52], [-119.81, 39.52]]] },
      ];
      json = JSON.stringify(o);
    }
    const [cov] = await q(
      `WITH d AS (${DISSOLVED}),
            u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM d),
            p AS (SELECT geometry AS geom FROM essentials.geofence_boundaries WHERE geo_id=$2 AND mtfcc=$3)
       SELECT round(ST_Area(ST_Intersection(u.geom,p.geom)::geography)::numeric,0) AS covered_m2,
              round(ST_Area(ST_Difference(p.geom,u.geom)::geography)::numeric,0)   AS uncovered_m2,
              round((100*ST_Area(ST_Intersection(u.geom,p.geom)::geography)
                        /NULLIF(ST_Area(p.geom::geography),0))::numeric,3)         AS pct
         FROM u,p`,
      [json, c.parent.geo_id, c.parent.mtfcc],
    );
    const coveredKm2 = Number(cov.covered_m2) / 1e6;
    const uncoveredKm2 = Number(cov.uncovered_m2) / 1e6;
    console.log(
      `  GATE 4 ${c.name}: cover ${coveredKm2.toFixed(1)} km² (${cov.pct}% of polygon); ` +
        `census land ${(c.aland / 1e6).toFixed(1)} km², water ${(c.awater / 1e6).toFixed(1)} km²; ` +
        `uncovered ${uncoveredKm2.toFixed(3)} km²`,
    );
    if (Number(cov.covered_m2) < c.aland) {
      fail(
        `GATE 4: ${c.name} cover ${coveredKm2.toFixed(1)} km², LESS than the census land area of ` +
          `${(c.aland / 1e6).toFixed(1)} km². Inhabited ground would sit outside every district and ` +
          `an address there would resolve to no seat.`,
      );
    }
    if (uncoveredKm2 > c.ceil) {
      fail(`GATE 4: ${c.name} leave ${uncoveredKm2.toFixed(3)} km² uncovered, over the ${c.ceil} km² ceiling.`);
    }
    gapsFor[c.name] = await q(
      `WITH d AS (${DISSOLVED}),
            u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM d),
            p AS (SELECT geometry AS geom FROM essentials.geofence_boundaries WHERE geo_id=$2 AND mtfcc=$3),
            parts AS (SELECT (ST_Dump(ST_Difference(p.geom,u.geom))).geom AS geom FROM p,u)
       SELECT round((ST_Area(geom::geography)/1e6)::numeric,3) AS km2,
              round(ST_Y(ST_PointOnSurface(geom))::numeric,6) AS lat,
              round(ST_X(ST_PointOnSurface(geom))::numeric,6) AS lon
         FROM parts WHERE ST_Area(geom::geography) >= $4 ORDER BY 1 DESC`,
      [c.json, c.parent.geo_id, c.parent.mtfcc, GAP_PROBE_MIN_KM2 * 1e6],
    );
    if (gapsFor[c.name].length) {
      console.log(`    ${gapsFor[c.name].length} uncovered piece(s) over ${GAP_PROBE_MIN_KM2} km²:`);
      for (const g of gapsFor[c.name]) console.log(`      ${g.km2} km² at ${g.lat},${g.lon}`);
    }
  }
  console.log('  GATE 4 PASSED');
}

// ── GATE 5: THE BALLOT ARBITER ───────────────────────────────────────────────
// Every Reno precinct's interior point must fall in the ward its RWARDS field names, and
// every Washoe precinct's interior point in the commission district its COMMISSION names.
// This is the vintage proof: it is the only test here that can tell the current six-ward map
// from the superseded five-ward one, and it comes from the body that prints the ballots.
{
  // field: which precinct column names the expected district; onlyReno: wards exist only inside Reno
  const cases = [
    { what: 'wards', json: wardsJson(), field: 'rwards', onlyReno: true, known: KNOWN_WARD_PRECINCT_MISMATCHES, min: 100 },
    { what: 'commission', json: commsJson(), field: 'commission', onlyReno: false, known: KNOWN_COMMISSION_PRECINCT_MISMATCHES, min: 400 },
  ];

  for (const c of cases) {
    const scope = c.onlyReno ? `pr.${c.field} > 0` : 'true';
    const rows = await q(
      `WITH d AS (${DISSOLVED}), pr AS (${PRECINCTS})
       SELECT pr.precinct, pr.${c.field} AS ballot, d2.num AS polygon
         FROM pr LEFT JOIN LATERAL (SELECT d.num FROM d WHERE ST_Contains(d.geom, pr.pt) LIMIT 1) d2 ON true
        WHERE ${scope}
        ORDER BY pr.precinct`,
      [c.json, precinctsJson],
    );

    // 🔴 A BLIND CHECK MUST NOT PASS. If the arbiter returns implausibly few precincts it has
    // stopped answering, and "0 disagreements" would be the most dangerous possible result.
    if (rows.length < c.min) {
      fail(
        `GATE 5: only ${rows.length} precincts carry a ${c.what} assignment, expected at least ` +
          `${c.min}. The arbiter is not answering, so a clean pass would mean nothing.`,
      );
    }

    const mismatched = rows.filter((r) => r.polygon === null || Number(r.polygon) !== Number(r.ballot));
    const ids = new Set(mismatched.map((r) => Number(r.precinct)));
    const unexpected = [...ids].filter((p) => !c.known.has(p));
    const healed = [...c.known].filter((p) => !ids.has(p));

    console.log(
      `  GATE 5 ${c.what}: ${rows.length} precincts — ${mismatched.length} mismatched ` +
        `(${c.known.size} known, ${unexpected.length} new)`,
    );

    if (unexpected.length) {
      const sample = mismatched
        .filter((r) => unexpected.includes(Number(r.precinct)))
        .slice(0, 15)
        .map((r) => `#${r.precinct} ballot=${r.ballot} polygon=${r.polygon ?? 'none'}`);
      fail(
        `GATE 5: the ${c.what} polygons disagree with the Washoe Registrar's precinct ` +
          `assignments on ${unexpected.length} precinct(s) that are NOT in the documented ` +
          `baseline: ${sample.join(', ')}. The Registrar prints the ballots, so the polygons ` +
          `are what is wrong here. Do not load until each one is explained.`,
      );
    }
    if (healed.length) {
      // Not a failure — but the baseline must shrink rather than quietly forgive nothing.
      console.log(
        `    ⚠ ${healed.length} baselined ${c.what} precinct(s) no longer mismatch (${healed.join(', ')}) — ` +
          `remove them from the KNOWN_* set in this file.`,
      );
    }
  }
  console.log('  GATE 5 PASSED: both layers match the ballot authority except where documented');
}

// ── GATE 6: THE CONVERSE — the arbiter must REJECT the superseded map ────────
// 🔴 A BLIND CHECK MUST NOT PASS. If GATE 5 would also accept the dead five-ward map, then it
// proves nothing about vintage and this whole file is decoration.
{
  // 🔴 COUNT ONLY WHERE BOTH MAPS GIVE AN ANSWER. The first version of this gate counted every
  // Reno precinct the superseded map failed to place — which handed it the 26 Ward 6 precincts
  // for free, because a FIVE-ward map can never assign a precinct whose ballot ward is 6. The
  // `--control=vacuous` run proved it: feeding the CURRENT map back in as the "superseded" one
  // still scored 26 and the gate passed, so it was measuring the absence of Ward 6 rather than
  // any difference in geometry. Restricting to ballot wards 1..5 that the old map does place
  // makes a truncated copy of the current map score 0, which is what the control needs.
  const [s] = await q(
    `WITH d AS (${DISSOLVED}), pr AS (${PRECINCTS})
     SELECT count(*) FILTER (WHERE pr.rwards BETWEEN 1 AND 5 AND d2.num IS NOT NULL)::int AS comparable,
            count(*) FILTER (WHERE pr.rwards BETWEEN 1 AND 5 AND d2.num IS NOT NULL
                               AND d2.num <> pr.rwards)::int AS mismatched
       FROM pr LEFT JOIN LATERAL (SELECT d.num FROM d WHERE ST_Contains(d.geom, pr.pt) LIMIT 1) d2 ON true`,
    [supersededJson(), precinctsJson],
  );
  const pct = s.comparable ? (100 * s.mismatched) / s.comparable : 0;
  console.log(
    `  GATE 6: on the ${s.comparable} precincts both maps place, the superseded five-ward map ` +
      `contradicts the arbiter ${s.mismatched} time(s) (${pct.toFixed(1)}%)`,
  );
  if (s.mismatched < 20) {
    fail(
      `GATE 6: the superseded five-ward map contradicts the Registrar on only ${s.mismatched} of ` +
        `the ${s.comparable} precincts both maps place. GATE 5 therefore cannot distinguish the ` +
        `current map from the dead one on geometry, so it is not evidence of vintage.`,
    );
  }
  console.log('  GATE 6 PASSED: the arbiter discriminates on geometry — GATE 5 is a real test');
}

// ── Write ────────────────────────────────────────────────────────────────────
const layers = [
  { mtfcc: WARD_MTFCC, expected: WARDS_EXPECTED, json: wardsJson(), source: WARD_SOURCE, what: 'Reno council wards' },
  { mtfcc: COMM_MTFCC, expected: COMM_EXPECTED, json: commsJson(), source: COMM_SOURCE, what: 'Washoe commission districts' },
];

for (const l of layers) {
  const [existing] = await q(
    `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc=$1`,
    [l.mtfcc],
  );
  console.log(`\n  ${l.mtfcc} currently holds ${existing.n} row(s) in production`);
  if (existing.n !== 0 && existing.n !== l.expected) {
    fail(`${l.mtfcc} already holds ${existing.n} row(s) that are not this load — somebody else took this code`);
  }
}

if (EMIT) {
  let sql =
    `-- ${WARD_MTFCC} Reno council wards (${WARDS_EXPECTED}) and ${COMM_MTFCC} Washoe commission districts (${COMM_EXPECTED}).\n` +
    `-- GENERATED by scripts/load-reno-washoe-districts.mjs on ${new Date().toISOString()}.\n` +
    `-- Every gate in that script passed before this file was written. Do not hand-edit.\n`;
  for (const l of layers) {
    sql +=
      `WITH d AS (\n` + DISSOLVED.replace('$1::jsonb', `${lit(l.json)}::jsonb`) + `\n)\n` +
      `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)\n` +
      `SELECT d.geo_id, d.name, ${lit(STATE_FIPS)}, ${lit(l.mtfcc)}, d.geom, ${lit(l.source)}, now() FROM d\n` +
      `ON CONFLICT (geo_id, mtfcc) DO NOTHING;\n`;
  }
  fs.writeFileSync(EMIT, sql);
  console.log(`  --emit-sql: wrote ${sql.length.toLocaleString('en-US')} bytes to ${EMIT}; nothing written to the database.`);
  await pool.end();
  process.exit(0);
}

if (DRY) {
  for (const l of layers) {
    const preview = await q(
      `WITH d AS (${DISSOLVED})
       SELECT geo_id, name, ST_NumGeometries(geom) AS parts,
              round((ST_Area(geom::geography)/1e6)::numeric,3) AS km2
         FROM d ORDER BY num`,
      [l.json],
    );
    console.log(`\n${l.mtfcc} — ${l.what}`);
    console.table(preview);
  }
  console.log('\n--dry-run: nothing written.');
  await pool.end();
  process.exit(0);
}

for (const l of layers) {
  const [{ written }] = await q(
    `WITH d AS (${DISSOLVED}), ins AS (
       INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
       SELECT d.geo_id, d.name, $2, $3, d.geom, $4, now() FROM d
       ON CONFLICT (geo_id, mtfcc) DO NOTHING RETURNING 1)
     SELECT count(*)::int AS written FROM ins`,
    [l.json, STATE_FIPS, l.mtfcc, l.source],
  );
  const [after] = await q(
    `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc=$1`,
    [l.mtfcc],
  );
  console.log(`  ${l.mtfcc}: inserted ${written} row(s) (idempotent: a re-run inserts 0); now holds ${after.n}`);
  if (after.n !== l.expected) fail(`POST: ${l.mtfcc} holds ${after.n} rows, expected ${l.expected}`);
}
console.log('\n  POST PASSED: both layers at their expected counts');
await pool.end();
