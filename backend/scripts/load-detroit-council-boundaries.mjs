#!/usr/bin/env node
/**
 * load-detroit-council-boundaries.mjs — Knight program, wave MI-3.
 *
 * Fetches Detroit's seven council-district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='detroit-mi-council-district-1'..'-7', mtfcc='X0065'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0140 creates the districts and their offices
 * and REFUSES TO RUN if these seven boundaries are absent — an office on a district with no
 * polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 ONE LAYER SERVES TWO ELECTED BODIES. Detroit elects seven council members AND seven
 * Board of Police Commissioners from the SAME districts — "Police Commissioner districts have
 * identical boundaries to the City Council districts". So each polygon loaded here will carry
 * TWO offices, and a Detroit address correctly returns BOTH a council member and a police
 * commissioner. ⚠ That is the Long Beach fan-out shape and it is CORRECT here, for the same
 * reason IN-5's three county commissioners were: the charter says both are elected by the
 * voters of that district. No coverage or fan-out check can tell the two cases apart — only
 * the charter can.
 *
 * 🔴🔴 THREE LAYERS, AND THE VINTAGE QUESTION IS REAL. Detroit's open data portal publishes
 * `city_council_districts_2013`, `city_council_districts_2026`, AND `Council_Districts` titled
 * "Current Detroit City Council Districts" — plus a "2026 to 2013 Council District Crosswalk",
 * which is the city itself saying these are two different maps.
 * 🟢 THE 2026 LAYER DATES ITSELF, IN ITS OWN DESCRIPTION: "City Council selected the boundaries
 * illustrated here by an 8-1 vote on February 6, 2024. These boundaries will be used to
 * determine resident districts when voting in 2025 municipal elections, and will officially
 * take effect January 1, 2026." The sitting members took office 2026-01-01. So the 2026 map is
 * the one that represents Detroit today, and the 2013 map is superseded.
 * ⚠ NOTE THIS IS THE OPPOSITE ANSWER TO MI-1's SENATE. There the new map was authorised for a
 * FUTURE election, so the sitting members still represented the OLD one. Here the new map took
 * effect on the same day the new members did. **"Which map is newer" is never the question;
 * "which map do the sitting members represent" is.**
 * 🟢 `Council_Districts` ("Current") turns out to be BYTE-IDENTICAL to the 2026 layer —
 * measured, not assumed: same vertex count and zero area difference on all seven. So the city
 * publishes the operative map under two names, and GATE 2 uses that as two-publisher agreement.
 * ⚠ It would have been easy to read "Current" as the live map and be right by luck; Horry
 * County's `CurrentCouncilDistricts` was the SUPERSEDED map under exactly that name.
 *
 * ⚠ THE LAYER SAYS IT IS NOT THE LEGAL BOUNDARY: "This Council Districts map is for
 * illustrative purposes only... For the official geographic boundaries, please refer to the
 * geographical boundaries formally approved by the Detroit City Council on February 6, 2024."
 * The legal boundary is a street-by-street description, and the layer carries it per district in
 * a `legal_description` field. GATE 3 asserts all seven are present and non-trivial, so the
 * polygons are at least accompanied by the text they render.
 *
 * 🔴 AND THE CLOSURE GATE HAD TO BE MEASURED, NOT COPIED. Akron's ten wards tile its place
 * polygon at 99.971% and OH-3 gated at 99.5%. Detroit's seven cover **97.42%** of TIGER place
 * `2622000` — 139.22 sq mi against the place's 142.90 — because the TIGER place polygon includes
 * the Detroit River out to the international boundary while the districts tile the LAND
 * (~138.75 sq mi). Akron's threshold would FAIL on correct Detroit data. This is the Great
 * Lakes term from MI-1 for a third time, and Fort Wayne/Columbus's rule: gate the structure,
 * and set a coverage bound from a measurement.
 *
 *   node scripts/load-detroit-council-boundaries.mjs --dry-run
 *   node scripts/load-detroit-council-boundaries.mjs
 *   node scripts/load-detroit-council-boundaries.mjs --control=N   (N=1..5, must FAIL)
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0' };
const ORG = 'https://services2.arcgis.com/qvkbeam7Wirps6zC/arcgis/rest/services';
const LIVE = `${ORG}/city_council_districts_2026/FeatureServer/0`;
const MIRROR = `${ORG}/Council_Districts/FeatureServer/0`;           // "Current", second publisher name
const SUPERSEDED = `${ORG}/city_council_districts_2013/FeatureServer/0`; // the control

const MTFCC = 'X0065';
const EXPECTED = 7;
const PLACE_GEO_ID = '2622000'; // TIGER place, Detroit city — already in production (142.9027 sq mi)
const STATE_FIPS = '26';

// Coverage bound, MEASURED 2026-09-24 at 97.423%. The deficit is TIGER's water, not a hole in
// the map, so the window is set around the measurement rather than at "almost 100%".
const COVER_MIN = 0.96;
const COVER_MAX = 1.005;

const SOURCE =
  'City of Detroit Open Data, city_council_districts_2026 layer 0 ' +
  '(services2.arcgis.com/qvkbeam7Wirps6zC); boundaries selected by Detroit City Council 8-1 on ' +
  '2024-02-06 under 2012 Charter Sec. 3-108, used for the 2025 municipal elections and in effect ' +
  'from 2026-01-01; byte-identical to the same portal\'s "Current Detroit City Council Districts" ' +
  'layer, and materially different from city_council_districts_2013; read 2026-09-24 (MI-3)';

const ARG = process.argv.slice(2);
const DRY = ARG.includes('--dry-run');
const CONTROL = Number((ARG.find((a) => a.startsWith('--control=')) || '').split('=')[1] || 0);

const fail = (m) => { console.error(`\n🔴 ${m}\n`); process.exit(1); };
const ok = (m) => console.log(`  ${m}`);

async function layer(url, where = '1=1') {
  const r = await fetch(`${url}/query?where=${encodeURIComponent(where)}&outFields=*&outSR=4326&f=geojson`, { headers: UA });
  if (!r.ok) fail(`${url} -> HTTP ${r.status}`);
  const j = await r.json();
  if (j.exceededTransferLimit === true) fail(`${url} paged — a truncated layer must never be loaded`);
  return j.features || [];
}
const numOf = (p) => parseInt(String(p.district_number ?? p.DistrictNu ?? p.council_district ?? ''), 10);
const ringA = (r) => { let s = 0; for (let i = 0, j = r.length - 1; i < r.length; j = i++) s += r[j][0] * r[i][1] - r[i][0] * r[j][1]; return Math.abs(s / 2); };
const polys = (g) => (g.type === 'Polygon' ? [g.coordinates] : g.coordinates);
const areaOf = (g) => { let a = 0; for (const p of polys(g)) { a += ringA(p[0]); for (let k = 1; k < p.length; k++) a -= ringA(p[k]); } return a; };
const vertsOf = (g) => { let n = 0; for (const p of polys(g)) for (const r of p) n += r.length; return n; };

console.log(`\nMI-3 — Detroit council / police-commission district boundaries -> ${MTFCC}`);
if (CONTROL) console.log(`🧪 CONTROL ${CONTROL} ACTIVE — this run MUST FAIL.\n`);

let live = await layer(LIVE);
let mirror = await layer(MIRROR);
const old2013 = await layer(SUPERSEDED);

if (CONTROL === 1) live = live.slice(0, 6);                                   // wrong count
if (CONTROL === 2) mirror = old2013;                                          // "Current" is the superseded map
if (CONTROL === 3) live = live.map((f, i) => (i === 0 ? { ...f, properties: { ...f.properties, legal_description: '' } } : f));
// ⚠ Control 5 is caught by GATE 2a, not 2b: swapping the LIVE layer for the 2013 map makes it
// stop matching "Current" before 2b ever asks whether the redraw is present. Both are the right
// family of test, and 2b still has its own control in 2 — but a control that fires on an earlier
// gate has not exercised the later one (MI-2's gate-3 lesson).
if (CONTROL === 5) live = old2013;                                            // load the superseded map outright

// ── GATE 1: the shape of the layer ───────────────────────────────────────────
if (live.length !== EXPECTED) fail(`GATE 1: expected ${EXPECTED} features, got ${live.length}`);
const nums = live.map((f) => numOf(f.properties)).sort((a, b) => a - b);
if (nums.join(',') !== [1, 2, 3, 4, 5, 6, 7].join(',')) fail(`GATE 1: districts are not 1..7 exactly — got ${nums.join(',')}`);
ok(`GATE 1 PASSED: districts ${nums.join(',')}`);

// ── GATE 2: two publisher names, one map ─────────────────────────────────────
// The city serves the operative map as BOTH `city_council_districts_2026` and the layer titled
// "Current Detroit City Council Districts". They must be the same map, and BOTH must differ
// from the 2013 map — otherwise "Current" is stale and this wave is loading the wrong Detroit.
{
  const byNum = (fs) => new Map(fs.map((f) => [numOf(f.properties), f.geometry]));
  const L = byNum(live), M = byNum(mirror), O = byNum(old2013);
  const mismatch = [];
  for (const [d, g] of L) {
    const m = M.get(d);
    if (!m) { mismatch.push(`D${d} missing from the "Current" layer`); continue; }
    const rel = Math.abs(areaOf(g) - areaOf(m)) / areaOf(g);
    if (rel > 1e-9 || vertsOf(g) !== vertsOf(m)) mismatch.push(`D${d} differs from "Current" (rel ${rel.toExponential(2)}, verts ${vertsOf(g)} vs ${vertsOf(m)})`);
  }
  if (mismatch.length) fail(`GATE 2a: the 2026 layer and the "Current" layer are not the same map —\n    ${mismatch.join('\n    ')}`);
  let changed = 0;
  for (const [d, g] of L) { const o = O.get(d); if (o && Math.abs(areaOf(g) - areaOf(o)) / areaOf(g) > 0.005) changed++; }
  if (changed === 0) fail('GATE 2b: the loaded map is indistinguishable from the 2013 map — the redraw is not present, so this is the superseded Detroit');
  ok(`GATE 2 PASSED: "Current" matches the 2026 layer on all ${EXPECTED}, and ${changed} of ${EXPECTED} districts differ from 2013`);
}

// ── GATE 3: the legal description travels with each polygon ──────────────────
{
  const missing = live.filter((f) => String(f.properties.legal_description || '').trim().length < 80)
    .map((f) => `D${numOf(f.properties)}`);
  if (missing.length) fail(`GATE 3: ${missing.length} district(s) carry no legal_description — the layer is "for illustrative purposes only", so the text it renders must be present: ${missing.join(', ')}`);
  ok(`GATE 3 PASSED: all ${EXPECTED} districts carry a street-by-street legal_description`);
}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

// 🔴 X CODES HAVE NO USABLE ALLOCATOR. `steward slot X` exists and works, but its X sequence is
// UNSEEDED: it returned X_0001 while production's X0001 already holds 207 rows. That reservation
// was marked abandoned with its reason. So this code is read from prod's max IN THE SAME SESSION
// as the write, and the gate below refuses if anything already occupies it.
{
  const { rows } = await client.query(`SELECT max(mtfcc) AS mx FROM essentials.geofence_boundaries WHERE mtfcc ~ '^X[0-9]{4}$'`);
  const taken = await client.query('SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1', [MTFCC]);
  console.log(`  X-code check: prod max is ${rows[0].mx}, this wave takes ${MTFCC}, currently holding ${taken.rows[0].n} row(s)`);
  if (taken.rows[0].n > 0 && taken.rows[0].n !== EXPECTED) fail(`${MTFCC} already holds ${taken.rows[0].n} row(s) that are not this wave's ${EXPECTED} — pick the next free code`);
  if (rows[0].mx >= MTFCC && taken.rows[0].n === 0) fail(`prod max X code is ${rows[0].mx}, so ${MTFCC} is not free — another wave took it since this script was written`);
}

// ── GATE 4: no two districts overlap, and they cover the city within the measured band ──
const geoms = live.map((f) => ({ d: numOf(f.properties), gj: JSON.stringify(f.geometry) }));
const ovl = await client.query(
  `WITH g AS (SELECT d, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj),4326)) AS geom
                FROM unnest($1::int[], $2::text[]) AS t(d, gj))
   SELECT count(*)::int AS pairs FROM g a JOIN g b ON a.d < b.d
    WHERE ST_Area(ST_Intersection(a.geom,b.geom)::geography) > 1000`,
  [geoms.map((x) => x.d), geoms.map((x) => x.gj)]
);
if (ovl.rows[0].pairs > 0) fail(`GATE 4a: ${ovl.rows[0].pairs} pair(s) of districts overlap by more than 1000 m² — is this one map?`);

const cov = await client.query(
  `WITH g AS (SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj),4326))) AS u
                FROM unnest($1::text[]) AS t(gj)),
        p AS (SELECT geometry AS geom FROM essentials.geofence_boundaries
               WHERE state=$2 AND mtfcc='G4110' AND geo_id=$3)
   SELECT ST_Area(g.u::geography)/ST_Area(p.geom::geography) AS ratio,
          ST_Area(ST_Difference(g.u, p.geom)::geography)/2589988.11 AS outside_sq_mi,
          ST_Area(ST_Difference(p.geom, g.u)::geography)/2589988.11 AS uncovered_sq_mi
     FROM g, p`,
  [geoms.map((x) => x.gj), STATE_FIPS, PLACE_GEO_ID]
);
const { ratio, outside_sq_mi, uncovered_sq_mi } = cov.rows[0];
const r = Number(ratio);
console.log(`  coverage: ${(r * 100).toFixed(3)}% of TIGER place ${PLACE_GEO_ID}; ${Number(uncovered_sq_mi).toFixed(3)} sq mi uncovered, ${Number(outside_sq_mi).toFixed(3)} sq mi outside the city`);
if (CONTROL === 4 || r < COVER_MIN || r > COVER_MAX) {
  fail(`GATE 4b: coverage ${(r * 100).toFixed(3)}% is outside the measured band ${(COVER_MIN * 100).toFixed(1)}%–${(COVER_MAX * 100).toFixed(1)}%. ` +
       `The expected value is ~97.4%: the districts tile Detroit's LAND while TIGER's place polygon includes the Detroit River.`);
}
ok(`GATE 4 PASSED: no overlap, coverage ${(r * 100).toFixed(3)}% inside the measured band`);

if (DRY) { console.log('\nDRY RUN — nothing written.\n'); await client.end(); process.exit(0); }

// ── write ────────────────────────────────────────────────────────────────────
let inserted = 0, existed = 0;
for (const f of live) {
  const d = numOf(f.properties);
  const geoId = `detroit-mi-council-district-${d}`;
  const res = await client.query(
    `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
     SELECT $1::text, $2::text, $3::text, $4::text, $5::text,
            ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($6::text),4326)), $7::text, now()
      WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id=$1::text AND mtfcc=$5::text)`,
    [geoId, `ocd-division/country:us/state:mi/place:detroit/council_district:${d}`,
     `Detroit City Council District ${d}`, STATE_FIPS, MTFCC, JSON.stringify(f.geometry), SOURCE]
  );
  if (res.rowCount === 1) inserted++; else existed++;
}
console.log(`\n  inserted ${inserted}, already existed ${existed}`);

const after = await client.query(
  `SELECT count(*)::int AS n,
          count(*) FILTER (WHERE NOT ST_IsValid(geometry))::int AS invalid,
          count(*) FILTER (WHERE ST_SRID(geometry) <> 4326)::int AS wrong_srid
     FROM essentials.geofence_boundaries WHERE mtfcc = $1`, [MTFCC]);
const a = after.rows[0];
if (a.n !== EXPECTED || a.invalid || a.wrong_srid) fail(`post-write: ${a.n} rows, ${a.invalid} invalid, ${a.wrong_srid} wrong SRID`);
console.log(`  post-write: ${a.n} rows, 0 invalid, 0 wrong SRID\n✅ MI-3 boundaries loaded as ${MTFCC}.\n`);
await client.end();
