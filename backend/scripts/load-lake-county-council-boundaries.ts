#!/usr/bin/env -S npx tsx
/**
 * load-lake-county-council-boundaries.ts
 *
 * Fetches the 7 Lake County Council district boundaries and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='lake-county-in-council-district-1'..'-7',
 *                                   mtfcc='X0051', state='in'
 *
 * Writes ONLY to essentials.geofence_boundaries. The seating migration creates the districts and
 * offices and refuses to run if these seven boundaries are absent.
 *
 * Wave IN-9 of the Knight Foundation cities program — Indiana debt 3.
 * Roster:  backend/data/seed-lake-county-2026/ROSTERS.md
 * Record:  .planning/knight-foundation/in-debt.md  (Debt 3)
 * Tracker: .planning/knight-foundation/PROGRAM.md
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🟢🟢 THE SOURCE IS THE STATE, NOT THE COUNTY, AND THE COUNTY'S OWN PAGE SAYS SO IN PROSE.
 *
 * `lakecountyin.gov/departments/council/find-my-council-district` tells residents to use the
 * Secretary of State's "Who Are Your Elected Officials" map (WAYEO, `in.wayeo.us`) and filter to
 * the County level. So Lake County delegates the lookup to the state, and no county-published
 * council layer was ever going to exist. IN-6 and the first half of IN-9 both swept the county's
 * ArcGIS orgs for a *layer*; the answer was a *sentence*.
 *
 * 🔴 THE LAYER IS STATEWIDE — 398 polygons across 93 county values. GATE 1 therefore filters on
 * County='Lake' and asserts SEVEN, because Lake is the only Indiana county with a seven-district
 * council (89 counties have 4, St. Joseph has 9, Marion has 25). A loader that forgot the filter
 * would happily load somebody else's districts.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 GATE 6 IS THE VINTAGE GATE AND IT IS THE WHOLE REASON THIS WAVE IS SAFE.
 *
 * Gary's six seats were blocked for three waves because the plausible layers were the WRONG YEAR:
 * a city-published GeoJSON from 2014, and TIGER 2020 precincts that dissolve into a map which
 * *looks* right and puts three named precincts in the wrong districts. A layer with the right
 * county, the right count and the right naming can still be the wrong vintage.
 *
 * So this layer was checked against the county's OWN map — `CC_District_Map3X5.pdf`, prepared by
 * the Lake County Board of Elections & Registration in Esri ArcMap 10.8.1 on 2022-01-26, the
 * post-2020-census redistricting map. That PDF has no extractable geometry, but its precinct
 * labels are live text with coordinates, so it can be compared rather than admired:
 *
 *     339 of 339 precincts agree.  Zero disagreements.
 *
 * That comparison is frozen into
 * `backend/data/seed-lake-county-2026/wayeo-vs-county-2022-precinct-gate.json`, and GATE 6
 * re-derives the live assignment and requires it to still match. If the state republishes a
 * different map, this loader FAILS rather than silently seating a new one.
 *
 * ⚠ TWO EARLIER RUNS OF THAT COMPARISON WERE WRONG, IN OPPOSITE DIRECTIONS, AND BOTH LOOKED
 *   LIKE FINDINGS: a vertex-based nesting test reported 153 of 342 precincts "straddling" (it was
 *   measuring on-edge ambiguity, because precinct vertices lie exactly on district edges), and
 *   colour-sampling the PDF *around each precinct's label* reported nine disagreements, two of
 *   which were simply `SJ 13` and `SJ 19` swapped with each other. Sampling strictly inside each
 *   polygon fixed both. 🔴 Neither error was visible without a control: the interior detector has
 *   to keep reporting Gary, Hammond, Hobart and Crown Point as GENUINELY split (it does), and the
 *   PDF comparison has to COLLAPSE when aimed wrongly (339/339 becomes 51.5% at a 200pt shift).
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * ⚠ FOUR DETACHED FRAGMENTS, ALL ISLANDS INSIDE DISTRICT 6. DO NOT "CLEAN" THEM.
 *
 *   D7  0.0387 sq mi   28 addresses   the 2022 map paints it D7 on 1494 of 1494 samples  -> REAL
 *   D7  0.0077 sq mi    1 address     D7 on 1586 of 1586                                 -> REAL
 *   D3  0.00095 sq mi   0 addresses   no district colour at all (road corridor)          -> artefact
 *   D4  0.00120 sq mi   0 addresses   no district colour at all                          -> artefact
 *
 * The two real ones are unincorporated pockets inside Crown Point, which is what an Indiana
 * county council map looks like where a city has annexed around a township remnant. GATE 7 pins
 * the inventory so a future change in it reaches a human.
 *
 * Usage:
 *   npx tsx scripts/load-lake-county-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-lake-county-council-boundaries.ts
 */
import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const WAYEO =
  'https://services6.arcgis.com/3BIBAkkTYicFwv1e/arcgis/rest/services/WAYEO_WebMap_WFL1/FeatureServer/8';
const PRECINCTS =
  'https://services5.arcgis.com/8CXRnvSfSpwdf0R6/arcgis/rest/services/Selectable_Features/FeatureServer/4';

const districtsUrl = () =>
  `${WAYEO}/query?where=${encodeURIComponent("County='Lake'")}` +
  `&outFields=County,CountyCouncil,councildistrictid&returnGeometry=true&outSR=4326&f=geojson`;
const statewideCountUrl = () => `${WAYEO}/query?where=1%3D1&returnCountOnly=true&f=json`;
const precinctsUrl = () =>
  `${PRECINCTS}/query?where=1%3D1&outFields=P26&returnGeometry=true&outSR=4326&f=geojson&resultRecordCount=2000`;

const MTFCC = 'X0051';
/** state = 'in', not FIPS '18' — the private-MTFCC convention from X0030 up. See X0048, X0049. */
const STATE_CODE = 'in';
const SOURCE =
  'wayeo-WAYEO_WebMap_WFL1-layer8-County_Council_Districts-2026-09-11 (Knight IN-9); ' +
  'the Indiana GIO statewide county-council layer behind the Secretary of State "Who Are Your ' +
  'Elected Officials" lookup, which lakecountyin.gov names as the county answer to "find my ' +
  'council district"; vintage-gated 339/339 precincts against the county Board of Elections and ' +
  'Registration CC_District_Map3X5.pdf, created 2022-01-26';
const GEO_ID_PREFIX = 'lake-county-in-council-district-';
const OCD_PREFIX = 'ocd-division/country:us/state:in/county:lake/council_district:';

const COUNTY_GEO_ID = '18089';
const COUNTY_MTFCC = 'G4020';
const EXPECTED_COUNT = 7;
const DISTRICTS = ['1', '2', '3', '4', '5', '6', '7'] as const;

/** Lake is the ONLY Indiana county with seven council districts. Measured 2026-09-11. */
const EXPECTED_STATEWIDE_FEATURES = 398;
const STATEWIDE_TOLERANCE = 40;

/** GATE 3 — measured 2026-09-11 against production PostGIS, ST_MakeValid first. */
const EXPECTED_AREA_SQ_MI: Record<string, number> = {
  '1': 19.4019, '2': 38.4106, '3': 167.5757, '4': 41.2120,
  '5': 35.1709, '6': 64.9426, '7': 259.9237,
};
const AREA_TOLERANCE_PCT = 2;
const EXPECTED_UNION_SQ_MI = 626.6373;
const UNION_TOLERANCE_SQ_MI = 1.0;
const MAX_PAIR_OVERLAP_SQ_MI = 0.001;

/** GATE 5 — CLOSURE, not a bound: these seven tile the whole county, water included.
 *  Measured uncovered 0.0200 and outside 0.0287 against production's own 18089/G4020 — sliver
 *  noise between two digitisations of one boundary, not a real gap. */
const MAX_COUNTY_UNCOVERED_SQ_MI = 1.0;
const MAX_OUTSIDE_COUNTY_SQ_MI = 1.0;

/** GATE 6 — every current precinct must sit wholly inside exactly one district. */
const EXPECTED_PRECINCTS = 342;
const PRECINCT_TOLERANCE = 12;
const INSIDE_FRACTION = 0.99;
const OUTSIDE_FRACTION = 0.01;
const GATE_FILE = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '..', 'data', 'seed-lake-county-2026', 'wayeo-vs-county-2022-precinct-gate.json');

/** GATE 7 — the detached-fragment inventory, measured 2026-09-11. */
const FRAGMENT_MAX_SQ_MI = 0.5;
const EXPECTED_FRAGMENTS = 4;
const MAX_FRAGMENT_TOTAL_SQ_MI = 0.06;

const DRY_RUN = process.argv.includes('--dry-run');
const SQM_PER_SQMI = 2589988.110336;

interface Feature { properties?: Record<string, unknown> | null; geometry?: unknown }

function fail(msg: string): never { console.error(`\n❌ ${msg}`); process.exit(1); }

async function fetchJson(url: string, label: string): Promise<any> {
  const r = await fetch(url, { headers: { 'User-Agent': 'EmpoweredVote-civic-data/1.0' } });
  const text = await r.text();
  // 🔴 A clean HTTP 200 can carry a truncated or WAF-substituted body. Only a full decode catches it.
  if (!r.ok) fail(`${label}: HTTP ${r.status}`);
  let j: any;
  try { j = JSON.parse(text); }
  catch { fail(`${label}: HTTP ${r.status} but the body is not JSON (${text.length} bytes).`); }
  if (j && j.error) fail(`${label}: service returned an error payload: ${JSON.stringify(j.error)}`);
  return j;
}

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const q = async (sql: string, params: unknown[] = []) => (await pool.query(sql, params)).rows;

  console.log(`Lake County Council districts -> ${MTFCC}${DRY_RUN ? '  (DRY RUN)' : ''}`);

  console.log('\nGATE 1 — the statewide layer yields exactly seven Lake rows, keyed 089-District N');
  const total = await fetchJson(statewideCountUrl(), 'statewide count');
  const totalN = Number(total.count);
  if (Math.abs(totalN - EXPECTED_STATEWIDE_FEATURES) > STATEWIDE_TOLERANCE) {
    fail(`GATE 1: the statewide layer holds ${totalN} features, expected ~${EXPECTED_STATEWIDE_FEATURES}. ` +
         `A layer that changed size this much may be a different map.`);
  }
  const j = await fetchJson(districtsUrl(), "County='Lake'");
  const feats: Feature[] = Array.isArray(j.features) ? j.features : [];
  if (feats.length !== EXPECTED_COUNT) {
    fail(`GATE 1: County='Lake' returned ${feats.length} features, expected ${EXPECTED_COUNT}. ` +
         `Lake is the only Indiana county with a seven-district council — if this is 4, the filter ` +
         `is reading the wrong county.`);
  }
  const byDistrict = new Map<string, Feature>();
  for (const f of feats) {
    const name = String(f.properties?.CountyCouncil ?? '').trim();
    const id = String(f.properties?.councildistrictid ?? '').trim();
    const m = /^County District ([1-7])$/.exec(name);
    if (!m) fail(`GATE 1: unexpected CountyCouncil value ${JSON.stringify(name)}.`);
    if (id !== `089-District ${m[1]}`) {
      fail(`GATE 1: ${name} carries councildistrictid ${JSON.stringify(id)}, expected "089-District ${m[1]}". ` +
           `089 is Lake County's FIPS county code; a different prefix is a different county.`);
    }
    if (!f.geometry) fail(`GATE 1: ${name} carries no geometry.`);
    if (byDistrict.has(m[1])) fail(`GATE 1: district ${m[1]} appears twice.`);
    byDistrict.set(m[1], f);
  }
  for (const d of DISTRICTS) if (!byDistrict.has(d)) fail(`GATE 1: district ${d} is missing.`);
  console.log(`  ✓ statewide ${totalN} features; Lake = ${EXPECTED_COUNT}, keys 1..7, one polygon each`);

  const rows = DISTRICTS.map((d) => ({
    district: d,
    geo_id: `${GEO_ID_PREFIX}${d}`,
    ocd_id: `${OCD_PREFIX}${d}`,
    name: `Lake County Council District ${d}`,
    geojson: JSON.stringify(byDistrict.get(d)!.geometry),
  }));

  await q('CREATE TEMP TABLE lc_load(district text, geo_id text, ocd_id text, name text, gj text) ON COMMIT PRESERVE ROWS');
  for (const r of rows) {
    await q('INSERT INTO lc_load VALUES ($1,$2,$3,$4,$5)', [r.district, r.geo_id, r.ocd_id, r.name, r.geojson]);
  }
  await q(`CREATE TEMP TABLE lc_geom AS
           SELECT district, geo_id, ocd_id, name,
                  ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj), 4326))) AS geom
           FROM lc_load`);

  console.log('\nGATE 2 — geometry is valid multipolygon');
  for (const a of await q(`SELECT district, ST_GeometryType(geom) gtype, ST_IsValid(geom) valid,
                                  ST_NumGeometries(geom) parts FROM lc_geom ORDER BY district`)) {
    if (a.gtype !== 'ST_MultiPolygon') fail(`GATE 2: district ${a.district} is ${a.gtype}.`);
    if (!a.valid) fail(`GATE 2: district ${a.district} is not valid after ST_MakeValid.`);
    console.log(`  ✓ D${a.district} ${a.gtype}, ${a.parts} part(s)`);
  }

  console.log('\nGATE 3 — per-district area within tolerance');
  for (const a of await q(`SELECT district, ST_Area(geom::geography)/$1 AS sq_mi FROM lc_geom ORDER BY district`,
                          [SQM_PER_SQMI])) {
    const want = EXPECTED_AREA_SQ_MI[a.district];
    const got = Number(a.sq_mi);
    const drift = Math.abs(got - want) / want * 100;
    if (drift > AREA_TOLERANCE_PCT) fail(`GATE 3: district ${a.district} is ${got.toFixed(4)} sq mi, expected ~${want}.`);
    console.log(`  ✓ D${a.district} ${got.toFixed(4)} sq mi (${drift.toFixed(2)}% drift)`);
  }

  console.log('\nGATE 4 — no district overlaps another');
  const laps = await q(`SELECT a.district AS a, b.district AS b,
                               ST_Area(ST_Intersection(a.geom,b.geom)::geography)/$1 AS sq_mi
                        FROM lc_geom a JOIN lc_geom b ON a.district < b.district
                        WHERE ST_Intersects(a.geom,b.geom)
                          AND ST_Area(ST_Intersection(a.geom,b.geom)::geography)/$1 > $2`,
                       [SQM_PER_SQMI, MAX_PAIR_OVERLAP_SQ_MI]);
  if (laps.length) {
    fail(`GATE 4: ${laps.length} overlapping pair(s): ` +
         laps.map((l: any) => `D${l.a}/D${l.b} ${Number(l.sq_mi).toFixed(4)} sq mi`).join(', '));
  }
  console.log('  ✓ all 21 pairs clean');

  console.log('\nGATE 5 — the seven must CLOSE against the county polygon');
  const [cov] = await q(`SELECT ST_Area(c.geometry::geography)/$1 AS county_sq_mi,
                                ST_Area(u.g::geography)/$1 AS union_sq_mi,
                                ST_Area(ST_Difference(c.geometry, u.g)::geography)/$1 AS uncovered,
                                ST_Area(ST_Difference(u.g, c.geometry)::geography)/$1 AS outside
                         FROM essentials.geofence_boundaries c, (SELECT ST_Union(geom) AS g FROM lc_geom) u
                         WHERE c.geo_id=$2 AND c.mtfcc=$3`, [SQM_PER_SQMI, COUNTY_GEO_ID, COUNTY_MTFCC]);
  if (!cov) fail(`GATE 5: county polygon ${COUNTY_GEO_ID}/${COUNTY_MTFCC} is not in production.`);
  console.log(`    county ${Number(cov.county_sq_mi).toFixed(4)} · union ${Number(cov.union_sq_mi).toFixed(4)} · ` +
              `uncovered ${Number(cov.uncovered).toFixed(4)} · outside ${Number(cov.outside).toFixed(4)}`);
  if (Math.abs(Number(cov.union_sq_mi) - EXPECTED_UNION_SQ_MI) > UNION_TOLERANCE_SQ_MI) {
    fail(`GATE 5: union is ${Number(cov.union_sq_mi).toFixed(4)} sq mi, expected ~${EXPECTED_UNION_SQ_MI}.`);
  }
  if (Number(cov.uncovered) > MAX_COUNTY_UNCOVERED_SQ_MI) {
    fail(`GATE 5: ${Number(cov.uncovered).toFixed(4)} sq mi of Lake County has no council district. ` +
         `These seven tile the county; a real gap means the wrong layer.`);
  }
  if (Number(cov.outside) > MAX_OUTSIDE_COUNTY_SQ_MI) {
    fail(`GATE 5: ${Number(cov.outside).toFixed(4)} sq mi lies outside the county.`);
  }
  console.log('  ✓ closes against the county');

  console.log('\nGATE 6 — VINTAGE: every current precinct nests in one district, and the assignment');
  console.log("          still matches the one proved against the county's 2022 map");
  const pj = await fetchJson(precinctsUrl(), 'Lake County Surveyor precincts');
  const pfeats: Feature[] = Array.isArray(pj.features) ? pj.features : [];
  if (Math.abs(pfeats.length - EXPECTED_PRECINCTS) > PRECINCT_TOLERANCE) {
    fail(`GATE 6: the precinct layer returned ${pfeats.length} features, expected ~${EXPECTED_PRECINCTS}.`);
  }
  await q('CREATE TEMP TABLE lc_prec_load(label text, gj text) ON COMMIT PRESERVE ROWS');
  for (const f of pfeats) {
    const label = String(f.properties?.P26 ?? '').trim();
    if (!label) fail('GATE 6: a precinct carries no P26 label.');
    if (!f.geometry) fail(`GATE 6: precinct ${label} carries no geometry.`);
    await q('INSERT INTO lc_prec_load VALUES ($1,$2)', [label, JSON.stringify(f.geometry)]);
  }
  await q(`CREATE TEMP TABLE lc_prec AS
           SELECT label, ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj), 4326))) AS geom
           FROM lc_prec_load`);
  const nest = await q(
    `SELECT p.label,
            count(*) FILTER (WHERE f.frac >= $1) AS whole_in,
            min(d.district) FILTER (WHERE f.frac >= $1) AS district,
            count(*) FILTER (WHERE f.frac > $2 AND f.frac < $1) AS partial
     FROM lc_prec p
     JOIN LATERAL (SELECT d2.district, d2.geom FROM lc_geom d2 WHERE ST_Intersects(d2.geom, p.geom)) d ON true
     JOIN LATERAL (SELECT CASE WHEN ST_Area(p.geom::geography) = 0 THEN 0
                          ELSE ST_Area(ST_Intersection(d.geom, p.geom)::geography)
                               / ST_Area(p.geom::geography) END AS frac) f ON true
     GROUP BY p.label`, [INSIDE_FRACTION, OUTSIDE_FRACTION]);
  const split = nest.filter((r: any) => Number(r.whole_in) !== 1 || Number(r.partial) > 0);
  if (split.length) {
    fail(`GATE 6: ${split.length} precinct(s) do not nest inside exactly one district: ` +
         split.slice(0, 12).map((r: any) => `${r.label} (whole_in=${r.whole_in}, partial=${r.partial})`).join(', ') +
         `\n    Indiana county council districts follow precinct lines. A split precinct means the two ` +
         `layers are different vintages.`);
  }
  const live = new Map<string, string>(nest.map((r: any) => [r.label, String(r.district)]));
  if (live.size !== pfeats.length) fail(`GATE 6: ${pfeats.length} precincts but ${live.size} assignments.`);
  const distinct = new Set(live.values());
  if (distinct.size !== EXPECTED_COUNT) {
    fail(`GATE 6: precincts resolve to only ${distinct.size} distinct district(s) — the test is not ` +
         `discriminating, so its agreement proves nothing.`);
  }
  if (!fs.existsSync(GATE_FILE)) fail(`GATE 6: the frozen gate file is missing: ${GATE_FILE}`);
  const frozen = JSON.parse(fs.readFileSync(GATE_FILE, 'utf8')) as {
    rows: { precinct: string; wayeo_district: string | null; pdf_2022_district: string | null }[];
  };
  const drift: string[] = [];
  let compared = 0;
  for (const r of frozen.rows) {
    const now = live.get(r.precinct);
    if (now == null) { drift.push(`${r.precinct} has left the precinct layer`); continue; }
    compared++;
    if (r.wayeo_district && now !== r.wayeo_district) {
      drift.push(`${r.precinct}: was D${r.wayeo_district} (2022 map said D${r.pdf_2022_district ?? '?'}), now D${now}`);
    }
  }
  for (const label of live.keys()) {
    if (!frozen.rows.some((r) => r.precinct === label)) drift.push(`${label} is new since the gate was frozen`);
  }
  if (drift.length) {
    fail(`GATE 6: ${drift.length} precinct(s) have moved since the vintage comparison:\n    ` +
         drift.slice(0, 20).join('\n    ') +
         `\n    🔴 STOP. Either the state republished the districts or the county reprecincted. ` +
         `Re-run the comparison against the county's current published map before loading anything.`);
  }
  console.log(`  ✓ ${live.size} precincts, each wholly inside one of ${distinct.size} districts`);
  console.log(`  ✓ ${compared} agree with the frozen 2022-gated assignment, 0 drifted`);

  console.log('\nGATE 7 — the detached-fragment inventory is unchanged');
  const frags = await q(
    `SELECT district, count(*) AS n, coalesce(sum(sq_mi),0) AS total FROM (
        SELECT g.district, ST_Area((d.geom)::geography)/$1 AS sq_mi
        FROM lc_geom g, LATERAL ST_Dump(g.geom) d) s
     WHERE sq_mi < $2 GROUP BY district ORDER BY district`, [SQM_PER_SQMI, FRAGMENT_MAX_SQ_MI]);
  const nFrag = frags.reduce((a: number, r: any) => a + Number(r.n), 0);
  const totFrag = frags.reduce((a: number, r: any) => a + Number(r.total), 0);
  console.log(`    ${nFrag} fragment(s) under ${FRAGMENT_MAX_SQ_MI} sq mi, ${totFrag.toFixed(5)} sq mi total: ` +
              frags.map((r: any) => `D${r.district}x${r.n}`).join(' '));
  if (nFrag !== EXPECTED_FRAGMENTS || totFrag > MAX_FRAGMENT_TOTAL_SQ_MI) {
    fail(`GATE 7: expected ${EXPECTED_FRAGMENTS} fragments totalling under ${MAX_FRAGMENT_TOTAL_SQ_MI} sq mi. ` +
         `Two of the four are REAL (unincorporated pockets inside Crown Point, 29 addresses between ` +
         `them, painted District 7 on the county's own 2022 map) and two are empty digitising ` +
         `artefacts. A change here needs a human, not a cleanup.`);
  }
  console.log('  ✓ 4 fragments, inventory unchanged');

  if (DRY_RUN) { console.log('\nDRY RUN — nothing written.'); await pool.end(); return; }

  console.log('\nWriting…');
  const res = await q(
    `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
     SELECT geo_id, ocd_id, name, $1, $2, geom, $3, now() FROM lc_geom
     ON CONFLICT (geo_id, mtfcc) DO NOTHING RETURNING geo_id`,
    [STATE_CODE, MTFCC, SOURCE]);
  console.log(`  inserted ${res.length} boundary row(s)`);
  const [after] = await q(`SELECT count(*) AS n FROM essentials.geofence_boundaries WHERE mtfcc=$1`, [MTFCC]);
  if (Number(after.n) !== EXPECTED_COUNT) fail(`post-write: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED_COUNT}.`);
  console.log(`  ✓ ${MTFCC} holds ${after.n} boundaries`);
  await pool.end();
}

main().catch((e) => fail(e instanceof Error ? e.message : String(e)));
