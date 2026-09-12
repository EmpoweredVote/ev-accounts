#!/usr/bin/env -S npx tsx
/**
 * load-allen-county-council-boundaries.ts
 *
 * Fetches the 4 Allen County Council district boundaries and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='allen-county-in-council-district-1'..'-4',
 *                                   mtfcc='X0049', state='in'
 *
 * Writes ONLY to essentials.geofence_boundaries. The IN-5 migration creates the districts and
 * offices and refuses to run if these four boundaries are absent.
 *
 * Wave IN-5 of the Knight Foundation cities program (stage 4, Allen County).
 * Roster:  backend/data/seed-allen-county-2026/ROSTERS.md
 * Tracker: .planning/knight-foundation/PROGRAM.md
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 ONLY THE COUNTY COUNCIL DISTRICTS ARE LOADED. THE COMMISSIONER DISTRICTS ARE NOT, AND
 *    THAT IS THE CENTRAL DECISION OF THIS WAVE.
 *
 * The same Election Board service publishes Comm_Dist_1/2/3 (layers 17-19), and hanging the
 * three County Commissioner offices on them would be WRONG. Under Indiana law a county
 * commissioner must RESIDE in a district but is ELECTED BY THE ENTIRE COUNTY -- every registered
 * voter in Allen County votes for all three. Putting them on district polygons would show a
 * voter ONE of the three commissioners they actually elect.
 *
 * So the commissioner districts are a residency rule for candidates, not an electoral geography,
 * and the three offices hang on the county polygon 18003/G4020 instead. The county council is
 * different: its four district members ARE elected by district, and its three at-large members
 * are elected countywide.
 *
 * ⚠ This is the inverse of the Long Beach failure. There, nine councilmembers shared one polygon
 * and every address returned all nine, which was wrong. Here, every county address SHOULD return
 * all three commissioners, because that is who the voter elects.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE LAYER CARRIES A County_Council_Rep FIELD AND IT IS NULL IN ALL FOUR DISTRICTS, exactly
 * as Fort Wayne's FW_Council_Rep was empty in all six. It is NOT a roster source, and GATE 2
 * asserts it stays empty so the day it is populated somebody decides what it means.
 *
 * 🟢 UNLIKE FORT WAYNE, THESE FOUR DO TILE THEIR PARENT. Measured 2026-09-10 against production's
 * own 18003/G4020 county polygon: union 660.0234 sq mi against 659.983, with 0.0354 uncovered and
 * 0.0756 outside -- sliver noise between two digitisations of one boundary, not a real gap. So
 * GATE 5 requires CLOSURE here, where Fort Wayne's equivalent could only bound the gap. The
 * difference is real and is why the two loaders gate differently.
 *
 * 🟢 CROSS-CHECKED against the same service's precinct-level County_Council_Dist field at every
 * district's own interior point: 4 of 4 agree, each returning a DIFFERENT value.
 *
 * Usage:
 *   npx tsx scripts/load-allen-county-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-allen-county-council-boundaries.ts
 */
import 'dotenv/config';
import { Pool } from 'pg';

const HOST = 'https://gis1.acimap.us/imapweb/rest/services/Election_Board/EBdistricts/MapServer';
const LAYER_FOR_DISTRICT: Record<string, number> = { '1': 21, '2': 22, '3': 23, '4': 24 };
const districtUrl = (layer: number) =>
  `${HOST}/${layer}/query?where=1%3D1&outFields=County_Council_Dist,County_Council_Rep` +
  `&returnGeometry=true&outSR=4326&f=geojson`;
const precinctAtPointUrl = (lon: number, lat: number) =>
  `${HOST}/0/query?geometry=${lon},${lat}&geometryType=esriGeometryPoint&inSR=4326` +
  `&spatialRel=esriSpatialRelIntersects&outFields=Precinct,County_Council_Dist&returnGeometry=false&f=json`;

const MTFCC = 'X0049';
/** state = 'in', not FIPS '18' — the private-MTFCC convention from X0030 up. See X0048. */
const STATE_CODE = 'in';
const SOURCE =
  'acimap-Election_Board-EBdistricts-Cty_Cncl_Dist_1..4-2026-09-10 (Knight IN-5); ' +
  "the Allen County Election Board's own county-council-district service, cross-checked at every " +
  "district's interior point against the same service's precinct-level County_Council_Dist field";
const GEO_ID_PREFIX = 'allen-county-in-council-district-';
const OCD_PREFIX = 'ocd-division/country:us/state:in/county:allen/council_district:';

const COUNTY_GEO_ID = '18003';
const COUNTY_MTFCC = 'G4020';
const EXPECTED_COUNT = 4;
const DISTRICTS = ['1', '2', '3', '4'] as const;

/** GATE 3 — measured 2026-09-10 against production PostGIS, ST_MakeValid first. */
const EXPECTED_AREA_SQ_MI: Record<string, number> = {
  '1': 204.2679, '2': 179.1733, '3': 144.9529, '4': 131.6293,
};
const AREA_TOLERANCE_PCT = 2;
const EXPECTED_UNION_SQ_MI = 660.0234;
const UNION_TOLERANCE_SQ_MI = 1.0;
const MAX_PAIR_OVERLAP_SQ_MI = 0.001;

/** GATE 5 — CLOSURE, not a bound. Measured 0.0354 / 0.0756; these leave room for sliver noise
 *  while still failing anything that is a real gap. 🔴 The Fort Wayne loader deliberately does
 *  NOT do this — its city districts legitimately do not tile the place polygon. */
const MAX_COUNTY_UNCOVERED_SQ_MI = 1.0;
const MAX_OUTSIDE_COUNTY_SQ_MI = 1.0;

const DRY_RUN = process.argv.includes('--dry-run');
const SQM_PER_SQMI = 2589988.110336;

interface Feature { properties?: Record<string, unknown> | null; geometry?: unknown }

function fail(msg: string): never { console.error(`\n❌ ${msg}`); process.exit(1); }

async function fetchJson(url: string, label: string): Promise<any> {
  const r = await fetch(url, { headers: { 'User-Agent': 'EmpoweredVote-civic-data/1.0' } });
  if (!r.ok) fail(`${label}: HTTP ${r.status}`);
  const j = await r.json();
  if (j && j.error) fail(`${label}: service returned an error payload: ${JSON.stringify(j.error)}`);
  return j;
}

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const q = async (sql: string, params: unknown[] = []) => (await pool.query(sql, params)).rows;

  console.log(`Allen County Council districts -> ${MTFCC}${DRY_RUN ? '  (DRY RUN)' : ''}`);

  console.log('\nGATE 1 — four layers, one feature each, keyed County_Council_Dist = N');
  const byDistrict = new Map<string, Feature>();
  for (const d of DISTRICTS) {
    const layer = LAYER_FOR_DISTRICT[d];
    const j = await fetchJson(districtUrl(layer), `district ${d} (layer ${layer})`);
    const feats: Feature[] = Array.isArray(j.features) ? j.features : [];
    if (feats.length !== 1) fail(`GATE 1: layer ${layer} returned ${feats.length} features, expected 1.`);
    const got = String(feats[0].properties?.County_Council_Dist ?? '').trim();
    if (got !== d) fail(`GATE 1: layer ${layer} has County_Council_Dist ${JSON.stringify(got)}, expected ${d}.`);
    if (!feats[0].geometry) fail(`GATE 1: district ${d} carries no geometry.`);
    byDistrict.set(d, feats[0]);
  }
  console.log(`  ✓ ${EXPECTED_COUNT} districts, keys 1..4, one polygon each`);

  console.log('\nGATE 2 — County_Council_Rep is empty (it is NOT a roster source)');
  const populated: string[] = [];
  for (const d of DISTRICTS) {
    const v = byDistrict.get(d)!.properties?.County_Council_Rep;
    const s = v == null ? '' : String(v).trim();
    if (s !== '') populated.push(`D${d}="${s}"`);
  }
  if (populated.length) {
    fail(`GATE 2: County_Council_Rep is now populated (${populated.join(', ')}). It was null in all four\n` +
         `    when this loader was written. Decide what it means -- and do NOT start reading a roster\n` +
         `    out of a boundary layer.`);
  }
  console.log('  ✓ null in all four, as measured 2026-09-10');

  const rows = DISTRICTS.map((d) => ({
    district: d,
    geo_id: `${GEO_ID_PREFIX}${d}`,
    ocd_id: `${OCD_PREFIX}${d}`,
    name: `Allen County Council District ${d}`,
    geojson: JSON.stringify(byDistrict.get(d)!.geometry),
  }));

  await q('CREATE TEMP TABLE ac_load(district text, geo_id text, ocd_id text, name text, gj text) ON COMMIT PRESERVE ROWS');
  for (const r of rows) {
    await q('INSERT INTO ac_load VALUES ($1,$2,$3,$4,$5)', [r.district, r.geo_id, r.ocd_id, r.name, r.geojson]);
  }
  await q(`CREATE TEMP TABLE ac_geom AS
           SELECT district, geo_id, ocd_id, name,
                  ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj), 4326))) AS geom
           FROM ac_load`);

  console.log('\nGATE 3 — per-district area within tolerance');
  const areas = await q(`SELECT district, ST_Area(geom::geography)/$1 AS sq_mi,
                                ST_GeometryType(geom) AS gtype, ST_IsValid(geom) AS valid
                         FROM ac_geom ORDER BY district`, [SQM_PER_SQMI]);
  for (const a of areas) {
    const want = EXPECTED_AREA_SQ_MI[a.district];
    const got = Number(a.sq_mi);
    const drift = Math.abs(got - want) / want * 100;
    if (a.gtype !== 'ST_MultiPolygon') fail(`GATE 3: district ${a.district} is ${a.gtype}.`);
    if (!a.valid) fail(`GATE 3: district ${a.district} is not valid after ST_MakeValid.`);
    if (drift > AREA_TOLERANCE_PCT) fail(`GATE 3: district ${a.district} is ${got.toFixed(4)} sq mi, expected ~${want}.`);
    console.log(`  ✓ D${a.district} ${got.toFixed(4)} sq mi (${drift.toFixed(2)}% drift)`);
  }

  console.log('\nGATE 4 — no district overlaps another');
  const laps = await q(`SELECT a.district AS a, b.district AS b,
                               ST_Area(ST_Intersection(a.geom,b.geom)::geography)/$1 AS sq_mi
                        FROM ac_geom a JOIN ac_geom b ON a.district < b.district
                        WHERE ST_Intersects(a.geom,b.geom)
                          AND ST_Area(ST_Intersection(a.geom,b.geom)::geography)/$1 > $2`,
                       [SQM_PER_SQMI, MAX_PAIR_OVERLAP_SQ_MI]);
  if (laps.length) fail(`GATE 4: ${laps.length} overlapping pair(s).`);
  console.log('  ✓ all 6 pairs clean');

  console.log('\nGATE 5 — the four must CLOSE against the county polygon');
  const [cov] = await q(`SELECT ST_Area(c.geometry::geography)/$1 AS county_sq_mi,
                                ST_Area(u.g::geography)/$1 AS union_sq_mi,
                                ST_Area(ST_Difference(c.geometry, u.g)::geography)/$1 AS uncovered,
                                ST_Area(ST_Difference(u.g, c.geometry)::geography)/$1 AS outside
                         FROM essentials.geofence_boundaries c, (SELECT ST_Union(geom) AS g FROM ac_geom) u
                         WHERE c.geo_id=$2 AND c.mtfcc=$3`, [SQM_PER_SQMI, COUNTY_GEO_ID, COUNTY_MTFCC]);
  if (!cov) fail(`GATE 5: county polygon ${COUNTY_GEO_ID}/${COUNTY_MTFCC} is not in production.`);
  console.log(`    county ${Number(cov.county_sq_mi).toFixed(4)} · union ${Number(cov.union_sq_mi).toFixed(4)} · ` +
              `uncovered ${Number(cov.uncovered).toFixed(4)} · outside ${Number(cov.outside).toFixed(4)}`);
  if (Math.abs(Number(cov.union_sq_mi) - EXPECTED_UNION_SQ_MI) > UNION_TOLERANCE_SQ_MI) {
    fail(`GATE 5: union is ${Number(cov.union_sq_mi).toFixed(4)} sq mi, expected ~${EXPECTED_UNION_SQ_MI}.`);
  }
  if (Number(cov.uncovered) > MAX_COUNTY_UNCOVERED_SQ_MI) {
    fail(`GATE 5: ${Number(cov.uncovered).toFixed(4)} sq mi of Allen County has no council district. ` +
         `These four tile the county; a real gap means the wrong layer.`);
  }
  if (Number(cov.outside) > MAX_OUTSIDE_COUNTY_SQ_MI) {
    fail(`GATE 5: ${Number(cov.outside).toFixed(4)} sq mi lies outside the county.`);
  }
  console.log('  ✓ closes against the county');

  console.log("\nGATE 6 — every district agrees with the precinct County_Council_Dist");
  const pts = await q(`SELECT district, ST_X(ST_PointOnSurface(geom)) AS lon, ST_Y(ST_PointOnSurface(geom)) AS lat
                       FROM ac_geom ORDER BY district`);
  const seen = new Set<string>();
  for (const p of pts) {
    const j = await fetchJson(precinctAtPointUrl(Number(p.lon), Number(p.lat)), `precinct probe D${p.district}`);
    const f = (j.features || [])[0];
    const cd = f ? String(f.attributes?.County_Council_Dist ?? '') : '(no precinct)';
    if (cd !== String(p.district)) {
      fail(`GATE 6: district ${p.district}'s interior point sits in a precinct assigned to ${JSON.stringify(cd)}.`);
    }
    seen.add(cd);
    console.log(`  ✓ D${p.district} -> precinct ${f?.attributes?.Precinct} County_Council_Dist=${cd}`);
  }
  if (seen.size !== EXPECTED_COUNT) {
    fail(`GATE 6: the precinct field returned only ${seen.size} distinct value(s) across ${EXPECTED_COUNT} ` +
         `districts -- it is not discriminating, so its agreement proves nothing.`);
  }
  console.log(`  ✓ ${seen.size} distinct values across ${EXPECTED_COUNT} districts — the field discriminates`);

  if (DRY_RUN) { console.log('\nDRY RUN — nothing written.'); await pool.end(); return; }

  console.log('\nWriting…');
  const res = await q(
    `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
     SELECT geo_id, ocd_id, name, $1, $2, geom, $3, now() FROM ac_geom
     ON CONFLICT (geo_id, mtfcc) DO NOTHING RETURNING geo_id`,
    [STATE_CODE, MTFCC, SOURCE]);
  console.log(`  inserted ${res.length} boundary row(s)`);
  const [after] = await q(`SELECT count(*) AS n FROM essentials.geofence_boundaries WHERE mtfcc=$1`, [MTFCC]);
  if (Number(after.n) !== EXPECTED_COUNT) fail(`post-write: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED_COUNT}.`);
  console.log(`  ✓ ${MTFCC} holds ${after.n} boundaries`);
  await pool.end();
}

main().catch((e) => fail(e instanceof Error ? e.message : String(e)));
