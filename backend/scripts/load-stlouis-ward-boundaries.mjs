#!/usr/bin/env node
/**
 * load-stlouis-ward-boundaries.mjs — St. Louis MO deep seed, wave 3.
 *
 * Fetches the City of St. Louis's fourteen aldermanic ward polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='stlouis-mo-ward-1'..'-14', mtfcc='X0075'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0178 creates the districts and their offices
 * and REFUSES TO RUN if these fourteen boundaries are absent — an office on a district with no
 * polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE CITY PUBLISHES TWO WARD MAPS AND ONE OF THEM IS THE SUPERSEDED 28-WARD PLAN.
 * Measured 2026-09-28:
 *
 *   · GIS  — maps8.stlouis-mo.gov/arcgis/rest/services/STLOUIS/BOUNDARIES/MapServer/4 "Wards"
 *            returns FOURTEEN polygons, Ward 1..14.  ← the current map
 *   · Planning — /government/departments/planning/research/census/data/wards/index.cfm still
 *            publishes "Census Data by Ward" for wards 1..**28**.  ← STALE
 *
 * Two departments of one city, disagreeing. The stale one is the one a search for "St. Louis
 * ward data" reaches first, and it is ALSO the shape the spec already warned about for the
 * charter PDF, which still describes the 28-ward odd/even stagger. So the Planning page CANNOT
 * serve as a cross-publisher confirmation — it would fail — and it is recorded here so that the
 * next session does not reach for it.
 *
 * 🟢 THE COUNT IS DISCRIMINATING HERE, WHICH IS UNUSUAL. Wave 1 could not date Missouri's Senate
 * map by counting, because 34 is 34 under both plans. The Board of Aldermen went from 28 seats to
 * 14 at the April 2023 election, so a 28-feature layer IS the old plan and GATE 1 catches it.
 *
 * 🟢 GATE 2 IS A LIVE CROSS-PUBLISHER CHECK AGAINST A DIFFERENT DEPARTMENT. The Board of
 * Aldermen's own representation page is fetched and its ward headings counted. It is not GIS, and
 * it is not the stale Planning page.
 *
 * Two further independent readings, recorded but not re-fetched here because they are documents:
 *   · the Board of Election Commissioners' certified April 2023 summary carries the contests
 *     ALDERMAN WD 1 … ALDERMAN WD 14 — fourteen, from the election authority;
 *   · the Board's own 2023-2024 legislative-session roster holds fourteen wards, where the
 *     2022-2023 session holds twenty-seven.
 *
 * ⚠ NONE OF THIS DATES THE POLYGONS' GEOMETRY. It establishes that the layer has the right NUMBER
 * of wards for the board now sitting, and that they tile the city. Like Akron (OH-3), that is
 * recorded as a limitation rather than dressed up as a vintage proof.
 *
 * ⚠ The layer carries a field named `Ward11` alongside `Ward`. Its values are the zero-padded form
 * of the same number ('01'..'14'), not a 2011-vintage ward id — checked, because a field named for
 * a year is exactly where a superseded plan would hide.
 *
 *   node scripts/load-stlouis-ward-boundaries.mjs --dry-run
 *   node scripts/load-stlouis-ward-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0' };
const SERVICE =
  'https://maps8.stlouis-mo.gov/arcgis/rest/services/STLOUIS/BOUNDARIES/MapServer/4';
const REPRESENTATION_PAGE =
  'https://www.stlouis-mo.gov/government/departments/aldermen/representation/index.cfm';
const MTFCC = 'X0075';
const EXPECTED = 14;
const CITY_GEO_ID = '29510'; // TIGER county-equivalent, St. Louis city — already in production.
const CITY_MTFCC = 'G4020';  // 🔴 G4020, not G4110: the city is an INDEPENDENT CITY and wave 1
                             // deliberately did not load place 2965000 for the same ground.
const STATE_FIPS = '29';
const SOURCE =
  'City of St. Louis GIS, STLOUIS/BOUNDARIES MapServer layer 4 "Wards" ' +
  '(maps8.stlouis-mo.gov), 14 polygons Ward 1..14, read 2026-09-28. Cross-checked live against ' +
  "the Board of Aldermen's own representation page (14 wards), and against two documents: the " +
  'Board of Election Commissioners certified April 2023 summary, whose contests are ALDERMAN WD 1 ' +
  "through ALDERMAN WD 14, and the Board's own 2023-2024 legislative-session roster (14 wards, " +
  'against 27 in 2022-2023). NOTE the city ALSO publishes a stale 28-ward map on its Planning ' +
  "department's Census Data by Ward page; that is the superseded plan (MO-3)";

const DRY = process.argv.includes('--dry-run');
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

// 🔴 A GATE NOBODY HAS WATCHED FAIL IS NOT A GATE. --control=<name> tampers with the data so that
// exactly one gate must fire; each was run and each fired. Run them again after any edit here.
//   count   -> GATE 1   drop a ward
//   ward11  -> GATE 1   make Ward11 disagree with Ward (the 2011-vintage-field case)
//   publisher -> GATE 2 point the cross-publisher check at the city's OWN STALE 28-ward Planning
//                        page. It fires the BLIND branch and refuses to load -- which is the
//                        property that matters: swap this gate's source and it stops, it does not
//                        silently pass.
//   overlap -> GATE 3   duplicate ward 1's polygon onto ward 2
//   tile    -> GATE 5   SHRINK ward 13 to a sliver -- deleting it would drop the count and fire
//                        GATE 1 instead, which proves nothing about GATE 5
//   probe   -> GATE 4   move ONLY ward 14 (the City Hall ward) -- moving all of them would break
//                        the tiling gate first. This is why the probe runs BEFORE tiling.
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';
const tamper = (fs) => {
  if (!CONTROL) return fs;
  console.log(`\n⚠ CONTROL "${CONTROL}" ACTIVE — a gate MUST fail below, or the gate is worthless.\n`);
  const c = fs.map((f) => ({ ...f, properties: { ...f.properties } }));
  if (CONTROL === 'count') return c.slice(0, 13);
  if (CONTROL === 'ward11') { c[0].properties.Ward11 = '27'; return c; }
  if (CONTROL === 'overlap') { c[1].geometry = c[0].geometry; return c; }
  if (CONTROL === 'tile') {
    const t = c.find((f) => Number(f.properties.Ward) === 13);
    const ring = (t.geometry.type === 'Polygon' ? t.geometry.coordinates[0] : t.geometry.coordinates[0][0]);
    const [x, y] = ring[0];
    const d = 0.0005;
    t.geometry = { type: 'Polygon', coordinates: [[[x, y], [x + d, y], [x + d, y + d], [x, y + d], [x, y]]] };
    return c;
  }
  if (CONTROL === 'probe') {
    const t = c.find((f) => Number(f.properties.Ward) === 14);
    const shift = (co) => (typeof co[0] === 'number' ? [co[0] + 5, co[1]] : co.map(shift));
    t.geometry = { ...t.geometry, coordinates: shift(t.geometry.coordinates) };
    return c;
  }
  if (CONTROL === 'publisher') return c; // GATE 2 control: no tampering with features
  fail(`unknown --control=${CONTROL}`);
};

// ── Fetch the layer ──────────────────────────────────────────────────────────
const r = await fetch(
  `${SERVICE}/query?where=1%3D1&outFields=Ward,Ward11&returnGeometry=true&outSR=4326&f=geojson`,
  { headers: UA },
);
const t = await r.text();
if (!t.trim().startsWith('{')) fail(`not JSON (HTTP ${r.status}) from STLOUIS/BOUNDARIES layer 4`);
const j = JSON.parse(t);
if (j.error) fail(`ArcGIS error: ${JSON.stringify(j.error).slice(0, 160)}`);
const feats = tamper(j.features ?? []);
console.log(`STLOUIS/BOUNDARIES layer 4 "Wards": ${feats.length} features`);

// ── GATE 1: the shape of the layer ───────────────────────────────────────────
// 🔴 This is the gate that catches the 28-ward plan, and it can, because the seat count changed.
if (feats.length !== EXPECTED) {
  fail(
    `GATE 1: expected ${EXPECTED} features, got ${feats.length}` +
      (feats.length === 28 ? ' — THIS IS THE SUPERSEDED 28-WARD PLAN. Do not load it.' : ''),
  );
}
const nums = feats.map((f) => Number(f.properties.Ward));
const sorted = [...nums].sort((a, b) => a - b);
if (new Set(nums).size !== EXPECTED || sorted[0] !== 1 || sorted[EXPECTED - 1] !== EXPECTED) {
  fail(`GATE 1: wards are not 1..${EXPECTED} exactly — got ${sorted.join(',')}`);
}
// ⚠ Ward11 must be the zero-padded form of Ward, not a 2011-vintage identifier.
const odd = feats.filter(
  (f) => String(f.properties.Ward11 ?? '').replace(/^0+/, '') !== String(Number(f.properties.Ward)),
);
if (odd.length) {
  fail(
    `GATE 1: ${odd.length} feature(s) whose Ward11 is not the zero-padded Ward — ` +
      `Ward11 may be a 2011-vintage identifier and this may be a mixed layer`,
  );
}
console.log(`  GATE 1 PASSED: wards ${sorted.join(',')}, Ward11 agrees with Ward on all ${EXPECTED}`);

// ── GATE 2: a DIFFERENT city department publishes the same number of wards ───
// 🔴 Not GIS, and deliberately not the Planning department's Census-by-Ward page, which still
// publishes 28. If the Board's own page ever disagrees with the layer, stop and find out why.
const STALE_PLANNING_PAGE =
  'https://www.stlouis-mo.gov/government/departments/planning/research/census/data/wards/index.cfm';
const pr = await fetch(CONTROL === 'publisher' ? STALE_PLANNING_PAGE : REPRESENTATION_PAGE, { headers: UA });
const html = await pr.text();
if (!pr.ok || html.length < 5000) fail(`GATE 2: representation page returned HTTP ${pr.status}, ${html.length} bytes`);
const boardWards = new Set(
  [...html.matchAll(/Ward\s+0?(\d{1,2})\s+Alder(?:man|woman|person)/gi)].map((m) => Number(m[1])),
);
if (boardWards.size === 0) {
  fail(`GATE 2: parsed ZERO wards from the Board's representation page — the page shape changed, so this gate is blind. Fix it before loading.`);
}
if (boardWards.size !== EXPECTED) {
  fail(
    `GATE 2: the Board of Aldermen's own page lists ${boardWards.size} ward(s), the layer has ${EXPECTED} — ` +
      `two city publishers disagree. Do NOT load.`,
  );
}
console.log(`  GATE 2 PASSED: the Board's own representation page lists ${boardWards.size} wards, matching the layer`);

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const rows = feats.map((f) => {
  const n = Number(f.properties.Ward);
  return {
    geo_id: `stlouis-mo-ward-${n}`,
    name: `City of St. Louis Ward ${n}`,
    geom: JSON.stringify(f.geometry),
  };
});

// ── GATE 3: the fourteen wards do not overlap each other ─────────────────────
// 🔴 A layer that mixes two vintages usually shows up here first: two plans' wards overlap.
const [ov] = await q(
  `WITH d AS (SELECT r.geo_id,
                     ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)               AS raw,
                     ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                FROM jsonb_to_recordset($1::jsonb) AS r(geo_id text, name text, geom text))
   SELECT (SELECT count(*) FROM d a JOIN d b ON a.geo_id < b.geo_id
            WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 1000)::int AS pairs,
          (SELECT count(*) FROM d WHERE NOT ST_IsValid(raw))::int                  AS invalid_as_published`,
  [JSON.stringify(rows)],
);
if (ov.pairs > 0) fail(`GATE 3: ${ov.pairs} pair(s) of wards overlap by more than 1000 m² — is this one map?`);
console.log(`  GATE 3 PASSED: no two wards overlap (${ov.invalid_as_published} polygon(s) invalid as published)`);

// ── GATE 4: the address probe the product actually runs ─────────────────────
// 🔴 A boundary set that passes every structural gate can still fail the only question that
// matters. City Hall must land in exactly ONE ward, and a point outside the city in NONE.
const [probe] = await q(
  `WITH d AS (SELECT r.geo_id, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                FROM jsonb_to_recordset($1::jsonb) AS r(geo_id text, name text, geom text))
   SELECT (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint(-90.19935, 38.62700), 4326)))::int AS city_hall,
          (SELECT string_agg(geo_id, ',') FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint(-90.19935, 38.62700), 4326))) AS city_hall_ward,
          (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint(-90.32790, 38.64470), 4326)))::int AS clayton,
          (SELECT count(*) FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint(-87.63245, 41.88370), 4326)))::int AS chicago`,
  [JSON.stringify(rows)],
);
if (probe.city_hall !== 1) fail(`GATE 4: 1200 Market St (City Hall) falls in ${probe.city_hall} ward(s), expected exactly 1`);
if (probe.clayton !== 0) fail(`GATE 4: CONTROL failed — Clayton, outside the city, falls in ${probe.clayton} ward(s)`);
if (probe.chicago !== 0) fail(`GATE 4: CONTROL failed — Chicago falls in ${probe.chicago} ward(s)`);
console.log(`  GATE 4 PASSED: City Hall → ${probe.city_hall_ward}; Clayton and Chicago → no ward (controls)`);

// ── GATE 5: the fourteen wards tile the city ─────────────────────────────────
// St. Louis elects NO at-large aldermen, so the wards must partition the whole city — unlike Fort
// Wayne, where uncovered ground is correct. Threshold 99.5%, not 100%: the ward layer and the
// TIGER county-equivalent are two DIGITIZATIONS of one boundary and a sliver is expected.
const [cov] = await q(
  `WITH u AS (
     SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g), 4326))) AS geom
       FROM unnest($1::text[]) AS t(g)
   ), city AS (
     SELECT ST_MakeValid(geometry) AS geom FROM essentials.geofence_boundaries
      WHERE geo_id = $2 AND mtfcc = $3 AND state = $4
   )
   SELECT round((ST_Area(city.geom::geography)/2589988.11)::numeric, 4) AS city_sq_mi,
          round((ST_Area(u.geom::geography)/2589988.11)::numeric, 4)    AS wards_sq_mi,
          round((100 * ST_Area(ST_Intersection(city.geom, u.geom)::geography)
                     / ST_Area(city.geom::geography))::numeric, 3)      AS pct_covered,
          round((ST_Area(ST_Difference(u.geom, city.geom)::geography)/2589988.11)::numeric, 4) AS outside_city_sq_mi
     FROM u, city`,
  [rows.map((x) => x.geom), CITY_GEO_ID, CITY_MTFCC, STATE_FIPS],
);
if (!cov) fail(`GATE 5: the TIGER polygon ${CITY_GEO_ID}/${CITY_MTFCC} is not in production`);
console.log(
  `  city ${cov.city_sq_mi} sq mi · wards ${cov.wards_sq_mi} sq mi · ${cov.pct_covered}% of the city covered · ${cov.outside_city_sq_mi} sq mi of ward area lies outside it`,
);
if (Number(cov.pct_covered) < 99.5) fail(`GATE 5: the fourteen wards cover only ${cov.pct_covered}% of the city`);
console.log('  GATE 5 PASSED: the wards tile the city');

if (DRY) {
  console.log('\n--dry-run complete, nothing written.');
  await pool.end();
  process.exit(0);
}

await q('BEGIN');
const inserted = await q(
  `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
   SELECT r.geo_id, r.name, $4, $1,
          ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(r.geom)), 4326)), $2, now()
     FROM jsonb_to_recordset($3::jsonb) AS r(geo_id text, name text, geom text)
   ON CONFLICT (geo_id, mtfcc) DO NOTHING
   RETURNING geo_id`,
  [MTFCC, SOURCE, JSON.stringify(rows), STATE_FIPS],
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
     FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
if (valid.ok !== EXPECTED || valid.srids !== 1) {
  await q('ROLLBACK');
  fail(`post-write: ${valid.ok}/${valid.n} valid, ${valid.srids} SRID(s)`);
}
await q('COMMIT');
console.log(`post-write: ${valid.ok}/${valid.n} valid geometries, 1 SRID — committed.`);
await pool.end();
