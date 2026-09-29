#!/usr/bin/env node
/**
 * load-stlouis-county-council-boundaries.mjs — St. Louis MO deep seed, wave 4.
 *
 * Fetches St. Louis COUNTY's seven council district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='stlouis-county-mo-council-1'..'-7', mtfcc='X0076'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0181 creates the districts and their offices
 * and REFUSES TO RUN if these seven boundaries are absent — an office on a district with no
 * polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE COUNTY IS NOT THE CITY. St. Louis city seceded in 1876 and is an independent city.
 * These seven polygons must cover the COUNTY and must NOT contain St. Louis City Hall. GATE 5
 * asserts exactly that, because it is this wave's central confusion.
 *
 * 🔴🔴 AND `St. Louis County` ALREADY EXISTS IN PRODUCTION IN MINNESOTA (geo_id 27137), which
 * also has a SEVEN-member elected board. Nothing here matches on a label; the geo_ids are
 * explicit and the county polygon is keyed on (geo_id, mtfcc).
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE COUNT CANNOT DATE THIS MAP. Seven is seven under the 2019 plan and under the current
 * one — the same problem wave 1 hit with Missouri's 34 Senate districts. Charter § 2.035 orders
 * reapportionment within thirty days before June 1 each tenth year, so the current map comes from
 * the 2021 commission. The county publishes THREE layers on ArcGIS org w657bnjzrjguNyOy, all with
 * exactly 7 features, measured 2026-09-29:
 *
 *   · Council_Districts_WFL1        internally `Council_Districts_2023`  ← loaded here
 *   · Council_District_Plan_2022    the 2021 commission's plan
 *   · County_Council_Districts_2019 the SUPERSEDED map
 *
 * 🟢 The first two are the SAME MAP. Grid-sampled at 160 × 160 over the county bbox, 11,527 of
 * 11,527 interior points assign to the same district, 0 different, 0 one-sided. The 2019 layer
 * disagrees on 217 points (1.88%). See county-results/cmp_maps.py.
 *
 * So the vintage evidence is geometric, not numeric, and it runs BOTH ways:
 *   GATE 2 — the layer must AGREE with Council_District_Plan_2022 (it is that plan);
 *   GATE 3 — the layer must DISAGREE with County_Council_Districts_2019 (it is not the old one).
 * Either gate alone is worthless. GATE 2 alone would pass on two copies of the 2019 map; GATE 3
 * alone would pass on any unrelated geometry.
 *
 * ⚠ Two digitizations of one boundary need a TOLERANCE, not equality. AGREE_PCT and DIFFER_PCT
 * are set from the measured values printed by a real run, with a gap between them, so neither
 * gate sits on its own measurement.
 *
 *   node scripts/load-stlouis-county-council-boundaries.mjs --dry-run
 *   node scripts/load-stlouis-county-council-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0' };
const ORG = 'https://services2.arcgis.com/w657bnjzrjguNyOy/arcgis/rest/services';
const PRIMARY = `${ORG}/Council_Districts_WFL1/FeatureServer/0`;
const CONFIRM = `${ORG}/Council_District_Plan_2022/FeatureServer/0`;
const SUPERSEDED = `${ORG}/County_Council_Districts_2019/FeatureServer/0`;

const MTFCC = 'X0076';
const EXPECTED = 7;
const COUNTY_GEO_ID = '29189'; // TIGER county, St. Louis County MO — already in production.
const COUNTY_MTFCC = 'G4020';
const STATE_FIPS = '29';

// Tolerances, as a percentage of each district's own area (symmetric difference / area).
// 🔴 SET FROM MEASUREMENT, WITH A GAP. A tolerance equal to the measured value cannot fail.
const AGREE_PCT = 0.5; // GATE 2: every district must differ from the 2022 plan by LESS than this
const DIFFER_PCT = 2.0; // GATE 3: at least one district must differ from 2019 by MORE than this

const SOURCE =
  'St. Louis County GIS, ArcGIS org w657bnjzrjguNyOy, feature service Council_Districts_WFL1 ' +
  '(titled "St. Louis County Council District Boundaries", internally Council_Districts_2023), ' +
  '7 polygons DISTRICT 1..7, read 2026-09-29. Vintage established GEOMETRICALLY because the count ' +
  'cannot date this map — 7 is 7 under both plans. Cross-checked live against the county\'s own ' +
  'Council_District_Plan_2022 (the 2021 reapportionment commission\'s plan, charter § 2.035) which ' +
  'it AGREES with, and against County_Council_Districts_2019 which it DISAGREES with. ' +
  'NOTE the county publishes all three layers simultaneously; the 2019 one is superseded (MO-4)';

const DRY = process.argv.includes('--dry-run');
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

// 🔴 A GATE NOBODY HAS WATCHED FAIL IS NOT A GATE. --control=<name> tampers so that exactly one
// gate must fire. Each was run and each fired. Run them again after any edit here.
//   count    -> GATE 1  drop a district
//   agree    -> GATE 2  point the agreement check at the SUPERSEDED 2019 layer
//   vintage  -> GATE 3  point the disagreement check at the 2022 plan, i.e. ask the gate to tell
//                        a map apart from itself. It must refuse.
//   overlap  -> GATE 4  duplicate district 1's polygon onto district 2
//   probe    -> GATE 5  shift the Clayton district away
//   tile     -> GATE 6  shrink district 3 to a sliver (deleting it would fire GATE 1 instead,
//                        which proves nothing about GATE 6)
//
// ⚠ GATES 2 AND 3 DELIBERATELY READ THE UNTAMPERED FETCH. They are claims about the PUBLISHED
// layers, not about our row list. Without this, `overlap`/`probe`/`tile` would trip GATE 2 first
// and shadow the gate they are meant to exercise — the shadowing wave 3 had to reorder around.
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';
const tamper = (fs) => {
  if (!CONTROL) return fs;
  console.log(`\n⚠ CONTROL "${CONTROL}" ACTIVE — a gate MUST fail below, or the gate is worthless.\n`);
  const c = fs.map((f) => ({ ...f, properties: { ...f.properties } }));
  if (CONTROL === 'count') return c.slice(0, 6);
  if (CONTROL === 'overlap') { c[1].geometry = c[0].geometry; return c; }
  if (CONTROL === 'tile') {
    const t = c.find((f) => districtOf(f.properties) === 3);
    const ring = t.geometry.type === 'Polygon' ? t.geometry.coordinates[0] : t.geometry.coordinates[0][0];
    const [x, y] = ring[0];
    const d = 0.0005;
    t.geometry = { type: 'Polygon', coordinates: [[[x, y], [x + d, y], [x + d, y + d], [x, y + d], [x, y]]] };
    return c;
  }
  if (CONTROL === 'probe') {
    // Shift whichever district holds the county government center. Found below, so defer.
    return c;
  }
  if (CONTROL === 'agree' || CONTROL === 'vintage') return c; // handled at the fetch URLs
  fail(`unknown --control=${CONTROL}`);
};

// ⚠ THE THREE LAYERS DO NOT AGREE ON THE FIELD NAME. Council_Districts_WFL1 and
// Council_District_Plan_2022 carry `DISTRICT`; County_Council_Districts_2019 carries `COUNTY_COU`
// (with `NAME` = "Council District N"). So `outFields=*`, and the number is resolved explicitly
// — a hard-coded field name made GATE 3 error out rather than compare, which is a gate that
// cannot fail for the wrong reason but also cannot pass for the right one.
const districtOf = (props) => {
  for (const k of ['DISTRICT', 'COUNTY_COU']) {
    const v = Number(props?.[k]);
    if (Number.isInteger(v) && v >= 1 && v <= EXPECTED) return v;
  }
  const m = String(props?.NAME ?? '').match(/(\d+)\s*$/);
  if (m) return Number(m[1]);
  return NaN;
};

const getLayer = async (url, label) => {
  const r = await fetch(
    `${url}/query?where=1%3D1&outFields=*&returnGeometry=true&outSR=4326&f=geojson`,
    { headers: UA },
  );
  const t = await r.text();
  if (!t.trim().startsWith('{')) fail(`${label}: not JSON (HTTP ${r.status})`);
  const j = JSON.parse(t);
  if (j.error) fail(`${label}: ArcGIS error ${JSON.stringify(j.error).slice(0, 160)}`);
  const fs = j.features ?? [];
  if (!fs.length) fail(`${label}: ZERO features — this check would be blind. Fix it before loading.`);
  const bad = fs.filter((f) => !Number.isInteger(districtOf(f.properties)));
  if (bad.length) fail(`${label}: ${bad.length} feature(s) carry no readable district number — this check would be blind`);
  return fs;
};

// ── Fetch ────────────────────────────────────────────────────────────────────
const raw = await getLayer(PRIMARY, 'Council_Districts_WFL1');
console.log(`Council_Districts_WFL1: ${raw.length} features`);
const feats = tamper(raw);

// ── GATE 1: the shape of the layer ───────────────────────────────────────────
if (feats.length !== EXPECTED) fail(`GATE 1: expected ${EXPECTED} features, got ${feats.length}`);
const nums = feats.map((f) => districtOf(f.properties));
const sorted = [...nums].sort((a, b) => a - b);
if (new Set(nums).size !== EXPECTED || sorted[0] !== 1 || sorted[EXPECTED - 1] !== EXPECTED) {
  fail(`GATE 1: districts are not 1..${EXPECTED} exactly — got ${sorted.join(',')}`);
}
console.log(`  GATE 1 PASSED: districts ${sorted.join(',')}`);

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const toRows = (fs) =>
  fs.map((f) => {
    const n = districtOf(f.properties);
    return {
      geo_id: `stlouis-county-mo-council-${n}`,
      name: `St. Louis County Council District ${n}`,
      district: n,
      geom: JSON.stringify(f.geometry),
    };
  });

/** Per-district symmetric difference, as a percentage of the primary district's own area. */
const compare = async (aRows, bRows) =>
  q(
    `WITH a AS (SELECT r.district, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                  FROM jsonb_to_recordset($1::jsonb) AS r(district int, geom text)),
          b AS (SELECT r.district, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                  FROM jsonb_to_recordset($2::jsonb) AS r(district int, geom text))
     SELECT a.district,
            round((100 * ST_Area(ST_SymDifference(a.geom, b.geom)::geography)
                       / NULLIF(ST_Area(a.geom::geography), 0))::numeric, 4) AS pct
       FROM a JOIN b ON b.district = a.district
      ORDER BY a.district`,
    [JSON.stringify(aRows.map((r) => ({ district: r.district, geom: r.geom }))),
     JSON.stringify(bRows.map((r) => ({ district: r.district, geom: r.geom })))],
  );

// ── GATE 2: the layer AGREES with the 2021 commission's plan ─────────────────
{
  const url = CONTROL === 'agree' ? SUPERSEDED : CONFIRM;
  const other = toRows(await getLayer(url, 'confirm layer'));
  if (other.length !== EXPECTED) fail(`GATE 2: the confirming layer has ${other.length} features, expected ${EXPECTED}`);
  const d = await compare(toRows(raw), other);
  if (d.length !== EXPECTED) fail(`GATE 2: only ${d.length} district(s) paired up — the DISTRICT keys do not match`);
  const worst = Math.max(...d.map((x) => Number(x.pct)));
  console.log(`  GATE 2: worst per-district symmetric difference vs the 2022 plan = ${worst.toFixed(4)}%`);
  if (worst >= AGREE_PCT) {
    fail(
      `GATE 2: the layer DISAGREES with Council_District_Plan_2022 by up to ${worst.toFixed(4)}% ` +
        `(limit ${AGREE_PCT}%) — these are two different maps. Do NOT load.`,
    );
  }
  console.log('  GATE 2 PASSED: this is the 2021 commission\'s plan');
}

// ── GATE 3: the layer DISAGREES with the superseded 2019 map ─────────────────
// 🔴 The load-bearing one. The count is identical across vintages, so only geometry can date it.
{
  const url = CONTROL === 'vintage' ? CONFIRM : SUPERSEDED;
  const other = toRows(await getLayer(url, 'superseded layer'));
  const d = await compare(toRows(raw), other);
  if (d.length !== EXPECTED) fail(`GATE 3: only ${d.length} district(s) paired up — this check is blind`);
  const worst = Math.max(...d.map((x) => Number(x.pct)));
  const moved = d.filter((x) => Number(x.pct) > DIFFER_PCT).map((x) => x.district);
  console.log(`  GATE 3: worst difference vs the 2019 map = ${worst.toFixed(4)}%; districts moved: ${moved.join(',') || 'none'}`);
  if (!moved.length) {
    fail(
      `GATE 3: NO district differs from County_Council_Districts_2019 by more than ${DIFFER_PCT}% — ` +
        `this layer may BE the superseded 2019 map, and the count (${EXPECTED}) cannot tell them apart. Do NOT load.`,
    );
  }
  console.log('  GATE 3 PASSED: this is not the 2019 map');
}

let rows = toRows(feats);

// ── GATE 4: the seven districts do not overlap ───────────────────────────────
const [ov] = await q(
  `WITH d AS (SELECT r.geo_id,
                     ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)               AS rawg,
                     ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                FROM jsonb_to_recordset($1::jsonb) AS r(geo_id text, geom text))
   SELECT (SELECT count(*) FROM d a JOIN d b ON a.geo_id < b.geo_id
            WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 1000)::int AS pairs,
          (SELECT count(*) FROM d WHERE NOT ST_IsValid(rawg))::int                 AS invalid_as_published`,
  [JSON.stringify(rows.map((r) => ({ geo_id: r.geo_id, geom: r.geom })))],
);
if (ov.pairs > 0) fail(`GATE 4: ${ov.pairs} pair(s) of council districts overlap by more than 1000 m² — is this one map?`);
console.log(`  GATE 4 PASSED: no two districts overlap (${ov.invalid_as_published} polygon(s) invalid as published)`);

// ── GATE 5: the address probe the product actually runs ──────────────────────
// 🔴🔴 THE CITY CONTROL IS THE ONE THAT MATTERS. 1200 Market St is St. Louis CITY HALL. The city
// is an independent city and is NOT in St. Louis County, so it must fall in ZERO council
// districts. If it falls in one, this layer is the wrong ground and every city address would be
// answered with a county council member.
// Every coordinate below is GEOCODED (Census onelineaddress, Public_AR_Current, 2026-09-29).
// 🔴 A hand-typed anchor manufactures a false result — wave 1 lost a day to one.
const CLAYTON = [-90.33842, 38.64973]; // 41 S Central Ave, Clayton — the County Government Center
const CITY_HALL = [-90.19843, 38.62741]; // 1200 Market St — St. Louis CITY Hall
const CHICAGO = [-87.63245, 41.8837]; // 100 W Randolph St — out of state

if (CONTROL === 'probe') {
  const [hit] = await q(
    `WITH d AS (SELECT r.district, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                  FROM jsonb_to_recordset($1::jsonb) AS r(district int, geom text))
     SELECT district FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2, $3), 4326))`,
    [JSON.stringify(rows.map((r) => ({ district: r.district, geom: r.geom }))), CLAYTON[0], CLAYTON[1]],
  );
  if (!hit) fail('CONTROL probe: no district holds Clayton to begin with');
  const shift = (co) => (typeof co[0] === 'number' ? [co[0] + 5, co[1]] : co.map(shift));
  rows = rows.map((r) =>
    r.district === hit.district
      ? { ...r, geom: JSON.stringify(((g) => ({ ...g, coordinates: shift(g.coordinates) }))(JSON.parse(r.geom))) }
      : r,
  );
}

const [probe] = await q(
  `WITH d AS (SELECT r.district, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                FROM jsonb_to_recordset($1::jsonb) AS r(district int, geom text))
   SELECT (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3), 4326)))::int AS clayton,
          (SELECT string_agg(district::text, ',') FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3), 4326))) AS clayton_district,
          (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($4,$5), 4326)))::int AS city_hall,
          (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($6,$7), 4326)))::int AS chicago`,
  [JSON.stringify(rows.map((r) => ({ district: r.district, geom: r.geom }))),
   CLAYTON[0], CLAYTON[1], CITY_HALL[0], CITY_HALL[1], CHICAGO[0], CHICAGO[1]],
);
if (probe.clayton !== 1) fail(`GATE 5: 41 S Central Ave, Clayton (the County Government Center) falls in ${probe.clayton} council district(s), expected exactly 1`);
if (probe.city_hall !== 0) {
  fail(
    `GATE 5: CONTROL FAILED — 1200 Market St, ST. LOUIS CITY HALL, falls in ${probe.city_hall} county council district(s). ` +
      `The city is an INDEPENDENT CITY and is not in St. Louis County. This layer is the wrong ground.`,
  );
}
if (probe.chicago !== 0) fail(`GATE 5: CONTROL FAILED — Chicago falls in ${probe.chicago} council district(s)`);
console.log(`  GATE 5 PASSED: Clayton → district ${probe.clayton_district}; St. Louis City Hall and Chicago → no district (controls)`);

// ── GATE 6: the seven districts tile the county ──────────────────────────────
// The council has no at-large members, so the districts must partition the whole county.
// Threshold 99.5%: the county layer and TIGER's 29189 are two digitizations of one boundary.
const [cov] = await q(
  `WITH u AS (SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g), 4326))) AS geom
                FROM unnest($1::text[]) AS t(g)),
        county AS (SELECT ST_MakeValid(geometry) AS geom FROM essentials.geofence_boundaries
                    WHERE geo_id = $2 AND mtfcc = $3 AND state = $4)
   SELECT round((ST_Area(county.geom::geography)/2589988.11)::numeric, 4) AS county_sq_mi,
          round((ST_Area(u.geom::geography)/2589988.11)::numeric, 4)      AS districts_sq_mi,
          round((100 * ST_Area(ST_Intersection(county.geom, u.geom)::geography)
                     / ST_Area(county.geom::geography))::numeric, 3)      AS pct_covered,
          round((ST_Area(ST_Difference(u.geom, county.geom)::geography)/2589988.11)::numeric, 4) AS outside_county_sq_mi
     FROM u, county`,
  [rows.map((x) => x.geom), COUNTY_GEO_ID, COUNTY_MTFCC, STATE_FIPS],
);
if (!cov) fail(`GATE 6: the TIGER polygon ${COUNTY_GEO_ID}/${COUNTY_MTFCC} is not in production`);
console.log(
  `  county ${cov.county_sq_mi} sq mi · districts ${cov.districts_sq_mi} sq mi · ${cov.pct_covered}% of the county covered · ${cov.outside_county_sq_mi} sq mi lies outside it`,
);
if (Number(cov.pct_covered) < 99.5) fail(`GATE 6: the seven districts cover only ${cov.pct_covered}% of the county`);
console.log('  GATE 6 PASSED: the districts tile the county');

if (DRY) {
  console.log('\n--dry-run complete, nothing written.');
  await pool.end();
  process.exit(0);
}
if (CONTROL) fail('a --control run must never write. Re-run without --control.');

await q('BEGIN');
const inserted = await q(
  `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
   SELECT r.geo_id, r.name, $4, $1,
          ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(r.geom)), 4326)), $2, now()
     FROM jsonb_to_recordset($3::jsonb) AS r(geo_id text, name text, geom text)
   ON CONFLICT (geo_id, mtfcc) DO NOTHING
   RETURNING geo_id`,
  [MTFCC, SOURCE, JSON.stringify(rows.map((r) => ({ geo_id: r.geo_id, name: r.name, geom: r.geom }))), STATE_FIPS],
);
console.log(`\ninserted ${inserted.length} boundary row(s)`);

const [after] = await q(
  `SELECT count(*)::int AS n, count(*) FILTER (WHERE ST_IsValid(geometry))::int AS ok,
          count(DISTINCT ST_SRID(geometry))::int AS srids
     FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
if (after.n !== EXPECTED || after.ok !== EXPECTED || after.srids !== 1) {
  await q('ROLLBACK');
  fail(`post-write: ${MTFCC} holds ${after.n} rows (${after.ok} valid, ${after.srids} SRID) — expected ${EXPECTED}/${EXPECTED}/1`);
}
await q('COMMIT');
console.log(`post-write: ${after.ok}/${after.n} valid geometries, 1 SRID — committed.`);
await pool.end();
