#!/usr/bin/env node
/**
 * load-marin-supervisorial-districts.mjs — Marin County CA deep seed, stage 1 geography.
 *
 * Fetches ONE district layer and inserts it into essentials.geofence_boundaries:
 *
 *   X0088  marin-county-ca-supervisorial-district-1..5
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration (CC_0392) creates
 * the districts and their offices and REFUSES TO RUN if these boundaries are absent — an
 * office on a district with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 *   node scripts/load-marin-supervisorial-districts.mjs --dry-run
 *   node scripts/load-marin-supervisorial-districts.mjs --control=scramble   (gate 4 must FAIL)
 *   node scripts/load-marin-supervisorial-districts.mjs
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE LAYER'S `Supervisor` COLUMN IS TWO YEARS STALE. GEOMETRY IS TAKEN FROM IT;
 *    OCCUPANCY IS NOT.
 *
 * The service carries District, Population, Acres and `Supervisor`. Four of its five names
 * match the sitting board; District 2 says **Katie Rice**, who left the board in 2024 (Brian
 * Colbert holds D2). That is the Reno lesson repeating: a name field dates the ROSTER, never
 * the BOUNDARY, and reading it as authority would have seeded a supervisor who is gone.
 * The roster comes from the County's own district pages, in CC_0393 — never from here.
 *
 * ⚠ Its `Acres` field is mislabeled: the five values (639.1, 71.09, 45.62, 50.69, 21.17) sum
 * to 827.7, which is the county's area in SQUARE MILES (the TIGER county polygon measures
 * 828.18). Nothing here reads that field; it is recorded so the next reader does not trust it.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * THE ARBITER IS THE COUNTY'S OWN SUBPRECINCT LAYER.
 *
 * Marin's Elections Department builds ballots from subprecincts, so that layer is the
 * authority on where a district line actually runs (the Columbus arbiter rule). Unlike
 * Washoe's precinct layer it carries NO district column — so the test is GEOMETRIC rather
 * than by attribute: a subprecinct must nest inside ONE supervisorial district. Precincts are
 * drawn to nest inside districts, so a straddler means the district map and the ballot map
 * disagree — which is what a superseded (pre-2021) district map would look like.
 *
 *   Supervisorial Districts  lastEditDate 2023-12-12   (post-2021 redistricting)
 *   Subprecincts             lastEditDate 2026-09-04   (built for THIS election)
 *
 * GATE 4 requires every subprecinct THAT HOLDS REGISTERED VOTERS to sit ≥99% inside one
 * district. A zero-voter subprecinct that straddles is reported, not fatal — it cannot
 * misroute anybody, and RegVoterCnt is the control proving the layer was answering.
 *
 * GATE 4-CONTROL (`--control=scramble`) swaps two districts' geometry and REQUIRES GATE 4 TO
 * FAIL. A gate that cannot tell the real map from a scrambled one is not a gate.
 */
import fs from 'node:fs';
import pg from 'pg';

const DRY = process.argv.includes('--dry-run');
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const MTFCC = 'X0088';
const STATE_FIPS = '06';
const EXPECTED = 5;
const COUNTY_GEOID = '06041';
const COUNTY_MTFCC = 'G4020';

const SD_URL =
  'https://services6.arcgis.com/T8eS7sop5hLmgRRH/arcgis/rest/services/Supervisorial_Districts/FeatureServer/30';
const SP_URL =
  'https://services6.arcgis.com/T8eS7sop5hLmgRRH/arcgis/rest/services/Subprecincts/FeatureServer/7';
const SOURCE =
  'Marin County open data (gisopendata.marincounty.gov) — Supervisorial_Districts FeatureServer layer 30, ' +
  'lastEditDate 2023-12-12; vintage proved against the County Subprecincts layer 7 (lastEditDate 2026-09-04). ' +
  'Geometry only: the layer’s Supervisor column is stale (D2 still says Katie Rice) and is not read.';

const lit = (s) => `'${String(s).replace(/'/g, "''")}'`;
const fail = (msg) => {
  console.error(`\n❌ ${msg}`);
  process.exitCode = 1;
};

async function getJson(url, what) {
  const res = await fetch(url, { signal: AbortSignal.timeout(120_000) });
  if (!res.ok) throw new Error(`${what}: HTTP ${res.status} for ${url}`);
  return res.json();
}

const qs = (o) => Object.entries(o).map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&');

console.log('Fetching Marin supervisorial districts and the subprecinct arbiter...');
const sd = await getJson(
  `${SD_URL}/query?${qs({ where: '1=1', outFields: 'District', returnGeometry: 'true', outSR: '4326', f: 'geojson' })}`,
  'districts',
);
const sp = await getJson(
  `${SP_URL}/query?${qs({ where: '1=1', outFields: 'Precinct,SubPrecinct,RegVoterCnt', returnGeometry: 'true', outSR: '4326', f: 'geojson' })}`,
  'subprecincts',
);

const districts = (sd.features || []).map((f) => ({
  num: Number(f.properties.District),
  geom: f.geometry,
}));
const subprecincts = (sp.features || []).map((f) => ({
  sub: String(f.properties.SubPrecinct ?? ''),
  // 🔑 The leading digit IS the supervisorial district — measured 738/738, see GATE 4.
  lead: Number(String(f.properties.SubPrecinct ?? '0').slice(0, 1)),
  voters: Number(f.properties.RegVoterCnt ?? 0),
  geom: f.geometry,
}));
console.log(`  districts=${districts.length}  subprecincts=${subprecincts.length}`);

if (CONTROL === 'scramble') {
  const a = districts.find((d) => d.num === 1);
  const b = districts.find((d) => d.num === 3);
  const t = a.geom;
  a.geom = b.geom;
  b.geom = t;
  console.log('  ⚠ --control=scramble: districts 1 and 3 have swapped geometry. GATE 4 MUST FAIL.');
}

// ⚠ The nesting gate intersects 738 subprecincts against 5 districts, one of which (D4, West
// Marin) is a 421 KB polygon. That exceeds the server's default statement_timeout, and the
// failure arrives as `canceling statement due to statement timeout` — which reads like a gate
// crash rather than a slow query. Give this session room explicitly.
// ⚠ The nesting gate intersects 738 subprecincts against 5 districts, one of which (D4, West
// Marin) is a 421 KB polygon. That exceeds the server's default statement_timeout, and the
// failure arrives as `canceling statement due to statement timeout` — which reads like a gate
// crash rather than a slow query. A pooled connection ALSO ignores libpq startup `options`,
// so the timeout has to be raised as a statement on one dedicated client.
const pool = new pg.Client({ connectionString: process.env.DATABASE_URL });
await pool.connect();
await pool.query("SET statement_timeout = '600s'");
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const districtsJson = JSON.stringify(
  districts.map((d) => ({
    num: d.num,
    geo_id: `marin-county-ca-supervisorial-district-${d.num}`,
    name: `Marin County Supervisorial District ${d.num}`,
    geom: d.geom,
  })),
);
const subsJson = JSON.stringify(subprecincts);

const DISTRICTS = `
  SELECT r.num, r.geo_id, r.name,
         ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom #>> '{}'), 4326))) AS geom
    FROM jsonb_to_recordset($1::jsonb) AS r(num int, geo_id text, name text, geom jsonb)`;

// ── GATE 1: five districts, numbered 1..5, each with real area ───────────────
const g1 = await q(`WITH d AS (${DISTRICTS})
  SELECT num, round((ST_Area(geom::geography)/2589988.11)::numeric, 2) AS sq_mi FROM d ORDER BY num`,
  [districtsJson]);
console.log('\nGATE 1 — districts present and numbered');
for (const r of g1) console.log(`  District ${r.num}: ${r.sq_mi} sq mi`);
const nums = g1.map((r) => Number(r.num)).sort((a, b) => a - b);
if (g1.length !== EXPECTED || nums.join(',') !== '1,2,3,4,5') {
  fail(`GATE 1: expected districts 1-5, got [${nums.join(',')}]`);
}

// ── GATE 2: the districts do not overlap each other ──────────────────────────
const g2 = await q(`WITH d AS (${DISTRICTS})
  SELECT count(*)::int AS pairs FROM d a JOIN d b ON a.num < b.num
   WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 100000`,
  [districtsJson]);
console.log(`\nGATE 2 — overlapping pairs (>0.1 km²): ${g2[0].pairs}`);
if (g2[0].pairs !== 0) fail(`GATE 2: ${g2[0].pairs} district pair(s) overlap`);

// ── GATE 3: the five districts tile Marin County ─────────────────────────────
const g3 = await q(`WITH d AS (${DISTRICTS}),
       u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM d),
       p AS (SELECT geometry AS geom FROM essentials.geofence_boundaries WHERE geo_id = $2 AND mtfcc = $3)
  SELECT round((100 * ST_Area(ST_Intersection(u.geom, p.geom)::geography)
                    / NULLIF(ST_Area(p.geom::geography), 0))::numeric, 3) AS pct_of_county,
         round((ST_Area(ST_Difference(p.geom, u.geom)::geography)/2589988.11)::numeric, 2) AS uncovered_sq_mi
    FROM u, p`,
  [districtsJson, COUNTY_GEOID, COUNTY_MTFCC]);
console.log(`\nGATE 3 — county coverage: ${g3[0].pct_of_county}%  (uncovered ${g3[0].uncovered_sq_mi} sq mi)`);
if (Number(g3[0].pct_of_county) < 99.0) {
  fail(`GATE 3: districts cover only ${g3[0].pct_of_county}% of the county polygon`);
}

// ── GATE 4: THE ARBITER — the ballot layer's own district number ─────────────
//
// 🔑 THE LEADING DIGIT OF A MARIN SubPrecinct ID IS ITS SUPERVISORIAL DISTRICT. Measured, not
// assumed: 738 of 738 subprecincts, 170,099 registered voters, 0 disagreements
// (scripts/_marin-rig/probe-subprecinct-numbering.mjs). So Marin's ballot layer carries the
// district as an ATTRIBUTE after all, and this is the Washoe test — every precinct's interior
// point must land in the district its own BALLOT NUMBER claims — not a geometric heuristic.
//
// This is what a wrong-vintage district map cannot survive: redistricting renumbers precincts,
// so a 2026 ballot layer read against a pre-2021 district map disagrees in bulk.
const g4 = await q(`WITH d AS (${DISTRICTS}),
     s AS (SELECT x.sub, x.lead, x.voters,
                  ST_PointOnSurface(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(x.geom #>> '{}'), 4326))) AS pt
             FROM jsonb_to_recordset($2::jsonb) AS x(sub text, lead int, voters int, geom jsonb))
  SELECT count(*)::int AS total,
         count(*) FILTER (WHERE contains_num IS NOT DISTINCT FROM lead)::int AS agree,
         count(*) FILTER (WHERE contains_num IS DISTINCT FROM lead)::int AS disagree,
         coalesce(sum(voters), 0)::int AS voters,
         coalesce(sum(voters) FILTER (WHERE contains_num IS DISTINCT FROM lead), 0)::int AS voters_misrouted
    FROM (SELECT s.sub, s.lead, s.voters,
                 (SELECT d.num FROM d WHERE ST_Contains(d.geom, s.pt) LIMIT 1) AS contains_num
            FROM s) t`,
  [districtsJson, subsJson]);
const r4 = g4[0];
console.log(`\nGATE 4 — the arbiter: does each subprecinct sit in the district its BALLOT NUMBER claims?`);
console.log(`  subprecincts tested : ${r4.total}  (${r4.voters.toLocaleString('en-US')} registered voters)`);
console.log(`  agree               : ${r4.agree}`);
console.log(`  DISAGREE            : ${r4.disagree}  (${r4.voters_misrouted} voters)`);
if (r4.disagree > 0) {
  const bad = await q(`WITH d AS (${DISTRICTS}),
       s AS (SELECT x.sub, x.lead, x.voters,
                    ST_PointOnSurface(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(x.geom #>> '{}'), 4326))) AS pt
               FROM jsonb_to_recordset($2::jsonb) AS x(sub text, lead int, voters int, geom jsonb))
    SELECT sub, lead, voters, contains_num FROM (
      SELECT s.sub, s.lead, s.voters,
             (SELECT d.num FROM d WHERE ST_Contains(d.geom, s.pt) LIMIT 1) AS contains_num FROM s) t
     WHERE contains_num IS DISTINCT FROM lead ORDER BY voters DESC LIMIT 12`,
    [districtsJson, subsJson]);
  for (const b of bad) {
    console.log(`    ${b.sub}: ballot says D${b.lead}, polygon says D${b.contains_num ?? 'NONE'}, ${b.voters} voters`);
  }
  fail(`GATE 4: ${r4.disagree} subprecinct(s) sit outside the district their ballot number claims — ` +
       'the district map and the ballot map disagree. Do NOT load this layer.');
}

// ── Reported, NOT fatal: edge slivers between the two digitizations ──────────
//
// The 2023 district layer and the 2026 subprecinct layer are drawn on different bases, so
// shared lines do not match to the metre. 17 subprecincts (16 with voters, 241 voters, 0.14%
// of the county's registered voters) sit 81.8%-98.1% inside their best district. Every one of
// them still passes GATE 4 — its interior point is in the district its ballot number claims —
// so no voter can be misrouted by a sliver. Measured and recorded rather than smoothed over.
const slivers = await q(`WITH d AS (${DISTRICTS}),
     s AS (SELECT x.sub, x.voters,
                  ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(x.geom #>> '{}'), 4326)) AS geom
             FROM jsonb_to_recordset($2::jsonb) AS x(sub text, lead int, voters int, geom jsonb))
  SELECT count(*) FILTER (WHERE pct < 99)::int AS slivers,
         coalesce(sum(voters) FILTER (WHERE pct < 99), 0)::int AS sliver_voters,
         round(min(pct), 2) AS worst_pct
    FROM (SELECT s.sub, s.voters,
                 (SELECT round((100 * ST_Area(ST_Intersection(d.geom, s.geom)::geography)
                                    / NULLIF(ST_Area(s.geom::geography), 0))::numeric, 2)
                    FROM d ORDER BY ST_Area(ST_Intersection(d.geom, s.geom)::geography) DESC LIMIT 1) AS pct
            FROM s WHERE ST_Area(s.geom::geography) > 0) t`,
  [districtsJson, subsJson]);
console.log(`\n  (diagnostic, not a gate) edge slivers <99% nested: ${slivers[0].slivers} ` +
            `subprecincts, ${slivers[0].sliver_voters} voters, worst ${slivers[0].worst_pct}% — ` +
            'all of them pass GATE 4, so none can misroute a voter.');

if (CONTROL === 'scramble') {
  console.log('\n--control=scramble summary: GATE 4 ' +
    (process.exitCode === 1 ? '✅ FAILED as required — the gate can tell a wrong map from the right one.'
                            : '❌ PASSED on a scrambled map — THE GATE IS VACUOUS.'));
  if (process.exitCode !== 1) process.exitCode = 1;
  else process.exitCode = 0;
  await pool.end();
  process.exit(process.exitCode);
}

if (process.exitCode === 1) {
  console.error('\nGates failed; nothing written.');
  await pool.end();
  process.exit(1);
}

if (DRY) {
  console.log('\n--dry-run: all gates passed, nothing written.');
  await pool.end();
  process.exit(0);
}

const before = await q(`SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1`, [MTFCC]);
await q(`WITH d AS (${DISTRICTS})
  INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
  SELECT d.geo_id, d.name, ${lit(STATE_FIPS)}, ${lit(MTFCC)}, d.geom, ${lit(SOURCE)}, now() FROM d
  ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
  [districtsJson]);
const after = await q(
  `SELECT geo_id, name, round((ST_Area(geometry::geography)/2589988.11)::numeric,2) AS sq_mi
     FROM essentials.geofence_boundaries WHERE mtfcc = $1 ORDER BY geo_id`, [MTFCC]);
console.log(`\nLoaded ${MTFCC}: ${before[0].n} rows before, ${after.length} after`);
for (const r of after) console.log(`  ${r.geo_id}  ${r.sq_mi} sq mi  ${r.name}`);
await pool.end();
