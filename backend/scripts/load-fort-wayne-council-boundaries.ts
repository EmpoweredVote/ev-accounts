#!/usr/bin/env -S npx tsx
/**
 * load-fort-wayne-council-boundaries.ts
 *
 * Fetches the 6 Fort Wayne City Council district boundaries and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='fort-wayne-in-council-district-1'..'-6',
 *                                   mtfcc='X0048', state='in'
 *
 * Writes ONLY to essentials.geofence_boundaries. The IN-3 structure migration creates the six
 * districts and their offices, and refuses to run if these six boundaries are absent.
 *
 * Wave IN-3 of the Knight Foundation cities program.
 * Spec:    docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Roster:  backend/data/seed-fort-wayne-2026/ROSTERS.md
 * Tracker: .planning/knight-foundation/PROGRAM.md
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * SOURCE — the Allen County Election Board's own district service, which is the body that
 * draws and administers these districts:
 *
 *   https://gis1.acimap.us/imapweb/rest/services/Election_Board/EBdistricts/MapServer
 *     group layer 65 "Fort Wayne City Council"
 *       -> 66..71  FW_City_Cncl_Dist_1 .. _6, ONE feature each, keyed City_Dist='FW N'
 *
 * 🟢 UNLIKE SANTA CLARA, FORT WAYNE HAS NO COMPETING LAYER TO ARBITRATE. The Election Board
 * publishes one council-district layer, as six single-feature layers under one group. There is
 * no second digitisation to invert against, so the GA-4 arbitration problem does not arise --
 * and this comment exists so the next reader knows that was CHECKED, not assumed.
 *
 * 🔴 THE LAYER CARRIES AN FW_Council_Rep FIELD AND IT IS EMPTY IN EVERY DISTRICT.
 * Measured 2026-09-10: districts 1, 2, 4, 5 and 6 return "" and district 3 returns null. So
 * Santa Clara's GATE 2 -- compare the layer's roster field against the verified roster as a
 * VINTAGE test -- IS NOT AVAILABLE HERE. A field that looks like a source and holds nothing is
 * worse than no field, because it invites exactly the sentence "the Election Board confirms the
 * roster". It does not. GATE 2 below asserts the field is EMPTY, so that the day it is populated
 * this loader fails and someone decides what it means.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER regardless. The roster that reaches the
 * database comes from the city's own Council page, cross-checked, per ROSTERS.md.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE SIX DISTRICTS DO NOT TILE THE TIGER PLACE POLYGON, AND THAT IS CORRECT.
 * Measured 2026-09-10 against production's own 1825000/G4110:
 *
 *     place                     112.0932 sq mi
 *     union of the 6 districts  111.0025 sq mi
 *     place NOT covered           1.2524 sq mi   (one 1.1340 piece + one 0.0390 piece)
 *     districts OUTSIDE place     0.1617 sq mi
 *
 * The 1.1340 sq mi piece is centred at (-85.04700, 41.02744). The Election Board's OWN precinct
 * layer reports that point as precinct "ADAMS G" with City_Dist = 'COUNTY' -- unincorporated
 * Allen County, with no Fort Wayne council representation at all. So this is a disagreement
 * between TIGER's place polygon and the county's city limits, NOT a hole in the council map.
 * The gate below therefore bounds the gap rather than requiring closure: a Columbus/Fort Benning
 * situation, not a Macon-Bibb one.
 *
 * 🟢 THE LAYER WAS CROSS-CHECKED AGAINST AN INDEPENDENT RECORD. The same precinct layer carries
 * a City_Dist per precinct (187 of 278 precincts are FW 1..6, 64 are COUNTY). Every one of the
 * six district polygons was tested at its own interior point against that field: 6 of 6 agree,
 * and each returned a DIFFERENT value -- so the check discriminates rather than agreeing with
 * everything. The gap point returning 'COUNTY' is a seventh distinct answer from the same field.
 *
 * ⚠ POPULATION IS NOT WRITTEN. The district layer carries no population field. The precinct
 * layer has Precinct_Population, but summing precincts into districts is a derivation this wave
 * has not verified, so districts.population stays NULL rather than carrying a computed guess.
 *
 * Usage:
 *   npx tsx scripts/load-fort-wayne-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-fort-wayne-council-boundaries.ts
 */
import 'dotenv/config';
import { Pool } from 'pg';

const HOST = 'https://gis1.acimap.us/imapweb/rest/services/Election_Board/EBdistricts/MapServer';

/** Layer id per district. outSR=4326 is load-bearing on every ArcGIS fetch. */
const LAYER_FOR_DISTRICT: Record<string, number> = {
  '1': 66, '2': 67, '3': 68, '4': 69, '5': 70, '6': 71,
};
const districtUrl = (layer: number) =>
  `${HOST}/${layer}/query?where=1%3D1&outFields=City_Dist,FW_Council_Rep` +
  `&returnGeometry=true&outSR=4326&f=geojson`;

/** The Election Board's precinct layer — the independent cross-check, not a roster source. */
const precinctAtPointUrl = (lon: number, lat: number) =>
  `${HOST}/0/query?geometry=${lon},${lat}&geometryType=esriGeometryPoint&inSR=4326` +
  `&spatialRel=esriSpatialRelIntersects&outFields=Precinct,City_Dist&returnGeometry=false&f=json`;

const MTFCC = 'X0048';
/**
 * state = 'in', not FIPS '18'.
 * ⚠ The column holds both styles, and the split is by MTFCC era, not by state: every private
 * MTFCC from X0030 up uses lowercase USPS (tx, tn, fl, ga, ca, co, nc), while X0001-X0029 and
 * ALL TIGER layers use 2-digit FIPS -- including Indiana's own G5220/G5210 rows, which are '18'.
 * So Indiana will carry BOTH conventions after this load, in different layers, correctly.
 * Nothing in the address-resolution path reads it: electionService joins on geo_id and ST_Covers
 * with no state filter, and the coverage services filter on `state` only for TIGER MTFCCs.
 */
const STATE_CODE = 'in';
const SOURCE =
  'acimap-Election_Board-EBdistricts-FW_City_Cncl_Dist_1..6-2026-09-10 (Knight IN-3); ' +
  'the Allen County Election Board\'s own council-district service, cross-checked at every ' +
  'district\'s interior point against the same service\'s precinct-level City_Dist field';
const GEO_ID_PREFIX = 'fort-wayne-in-council-district-';
const OCD_PREFIX = 'ocd-division/country:us/state:in/place:fort_wayne/council_district:';

const PLACE_GEO_ID = '1825000';
const PLACE_MTFCC = 'G4110';

const EXPECTED_COUNT = 6;
const DISTRICTS = ['1', '2', '3', '4', '5', '6'] as const;

/** GATE 3 — measured 2026-09-10 against production PostGIS, ST_MakeValid first. */
const EXPECTED_AREA_SQ_MI: Record<string, number> = {
  '1': 16.9381, '2': 15.3684, '3': 23.6799, '4': 27.5695, '5': 12.2542, '6': 15.1924,
};
const AREA_TOLERANCE_PCT = 2;

const EXPECTED_UNION_SQ_MI = 111.0025;
const UNION_TOLERANCE_SQ_MI = 1.0;

/** GATE 4 — measured at zero on all fifteen pairs; nothing above 0.0001 sq mi exists. */
const MAX_PAIR_OVERLAP_SQ_MI = 0.001;

/**
 * GATE 5 — the coverage BOUND, not a closure requirement. See the header: the uncovered ground
 * is unincorporated Allen County by the Election Board's own precinct record, so requiring
 * closure against TIGER would be requiring the wrong thing. These bounds sit just above the
 * measured values so a materially different load fails.
 */
const MAX_PLACE_UNCOVERED_SQ_MI = 2.0;   // measured 1.2524
const MAX_OUTSIDE_PLACE_SQ_MI = 1.0;     // measured 0.1617

const DRY_RUN = process.argv.includes('--dry-run');
const SQM_PER_SQMI = 2589988.110336;

interface Feature { properties?: Record<string, unknown> | null; geometry?: unknown }

function fail(msg: string): never {
  console.error(`\n❌ ${msg}`);
  process.exit(1);
}

async function fetchJson(url: string, label: string): Promise<any> {
  const r = await fetch(url, { headers: { 'User-Agent': 'EmpoweredVote-civic-data/1.0' } });
  if (!r.ok) fail(`${label}: HTTP ${r.status}`);
  const j = await r.json();
  // ⚠ ArcGIS reports failures INSIDE a 200 body, so r.ok is not the test.
  if (j && j.error) fail(`${label}: service returned an error payload: ${JSON.stringify(j.error)}`);
  return j;
}

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const q = async (sql: string, params: unknown[] = []) => (await pool.query(sql, params)).rows;

  console.log(`Fort Wayne City Council districts -> ${MTFCC}${DRY_RUN ? '  (DRY RUN)' : ''}`);

  // ─── GATE 1: six single-polygon layers, keyed FW 1..FW 6 ─────────────────────────────
  console.log('\nGATE 1 — six layers, one feature each, keyed City_Dist = "FW N"');
  const byDistrict = new Map<string, Feature>();
  for (const d of DISTRICTS) {
    const layer = LAYER_FOR_DISTRICT[d];
    const j = await fetchJson(districtUrl(layer), `district ${d} (layer ${layer})`);
    const feats: Feature[] = Array.isArray(j.features) ? j.features : [];
    if (feats.length !== 1) fail(`GATE 1: layer ${layer} returned ${feats.length} features, expected 1.`);
    const cd = String(feats[0].properties?.City_Dist ?? '').trim();
    if (cd !== `FW ${d}`) fail(`GATE 1: layer ${layer} has City_Dist ${JSON.stringify(cd)}, expected "FW ${d}".`);
    if (!feats[0].geometry) fail(`GATE 1: district ${d} carries no geometry.`);
    byDistrict.set(d, feats[0]);
  }
  console.log(`  ✓ ${EXPECTED_COUNT} districts, keys FW 1..FW 6, one polygon each`);

  // ─── GATE 2: the roster field is EMPTY, and must stay that way silently ──────────────
  console.log('\nGATE 2 — FW_Council_Rep is empty (it is NOT a roster source)');
  const populated: string[] = [];
  for (const d of DISTRICTS) {
    const v = byDistrict.get(d)!.properties?.FW_Council_Rep;
    const s = v == null ? '' : String(v).trim();
    if (s !== '') populated.push(`D${d}="${s}"`);
  }
  if (populated.length) {
    fail(
      `GATE 2: FW_Council_Rep is now populated (${populated.join(', ')}).\n` +
      `    It was empty in every district when this loader was written, so nothing downstream\n` +
      `    treats it as a source. Decide what it means before letting the load proceed --\n` +
      `    and do NOT simply start reading the roster out of a boundary layer.`,
    );
  }
  console.log('  ✓ empty in all six, as measured 2026-09-10');

  // ─── Build the rows, then measure them in PostGIS ────────────────────────────────────
  const rows = DISTRICTS.map((d) => ({
    district: d,
    geo_id: `${GEO_ID_PREFIX}${d}`,
    ocd_id: `${OCD_PREFIX}${d}`,
    name: `Fort Wayne City Council District ${d}`,
    geojson: JSON.stringify(byDistrict.get(d)!.geometry),
  }));

  await q('CREATE TEMP TABLE fw_load(district text, geo_id text, ocd_id text, name text, gj text) ON COMMIT PRESERVE ROWS');
  for (const r of rows) {
    await q('INSERT INTO fw_load VALUES ($1,$2,$3,$4,$5)', [r.district, r.geo_id, r.ocd_id, r.name, r.geojson]);
  }
  await q(`CREATE TEMP TABLE fw_geom AS
           SELECT district, geo_id, ocd_id, name,
                  ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj), 4326))) AS geom
           FROM fw_load`);

  // ─── GATE 3: per-district area ───────────────────────────────────────────────────────
  console.log('\nGATE 3 — per-district area within tolerance');
  const areas = await q(`SELECT district, ST_Area(geom::geography)/$1 AS sq_mi,
                                ST_GeometryType(geom) AS gtype, ST_IsValid(geom) AS valid
                         FROM fw_geom ORDER BY district`, [SQM_PER_SQMI]);
  for (const a of areas) {
    const want = EXPECTED_AREA_SQ_MI[a.district];
    const got = Number(a.sq_mi);
    const drift = Math.abs(got - want) / want * 100;
    if (a.gtype !== 'ST_MultiPolygon') fail(`GATE 3: district ${a.district} is ${a.gtype}, expected ST_MultiPolygon.`);
    if (!a.valid) fail(`GATE 3: district ${a.district} is not valid after ST_MakeValid.`);
    if (drift > AREA_TOLERANCE_PCT) {
      fail(`GATE 3: district ${a.district} is ${got.toFixed(4)} sq mi, expected ~${want} (${drift.toFixed(2)}% drift).`);
    }
    console.log(`  ✓ D${a.district} ${got.toFixed(4)} sq mi (${drift.toFixed(2)}% drift)`);
  }

  // ─── GATE 4: the six do not overlap each other ───────────────────────────────────────
  console.log('\nGATE 4 — no district overlaps another');
  const laps = await q(`SELECT a.district AS a, b.district AS b,
                               ST_Area(ST_Intersection(a.geom,b.geom)::geography)/$1 AS sq_mi
                        FROM fw_geom a JOIN fw_geom b ON a.district < b.district
                        WHERE ST_Intersects(a.geom, b.geom)
                          AND ST_Area(ST_Intersection(a.geom,b.geom)::geography)/$1 > $2
                        ORDER BY 3 DESC`, [SQM_PER_SQMI, MAX_PAIR_OVERLAP_SQ_MI]);
  if (laps.length) {
    fail(`GATE 4: ${laps.length} overlapping pair(s): ` +
         laps.map((l: any) => `D${l.a}/D${l.b} ${Number(l.sq_mi).toFixed(4)} sq mi`).join(', '));
  }
  console.log('  ✓ all 15 pairs clean');

  // ─── GATE 5: coverage BOUND against the TIGER place polygon ──────────────────────────
  console.log('\nGATE 5 — coverage against the place polygon, bounded not closed');
  const [cov] = await q(`SELECT ST_Area(p.geometry::geography)/$1 AS place_sq_mi,
                                ST_Area(u.g::geography)/$1 AS union_sq_mi,
                                ST_Area(ST_Difference(p.geometry, u.g)::geography)/$1 AS uncovered,
                                ST_Area(ST_Difference(u.g, p.geometry)::geography)/$1 AS outside
                         FROM essentials.geofence_boundaries p,
                              (SELECT ST_Union(geom) AS g FROM fw_geom) u
                         WHERE p.geo_id=$2 AND p.mtfcc=$3`, [SQM_PER_SQMI, PLACE_GEO_ID, PLACE_MTFCC]);
  if (!cov) fail(`GATE 5: the place polygon ${PLACE_GEO_ID}/${PLACE_MTFCC} is not in production.`);
  const unionDrift = Math.abs(Number(cov.union_sq_mi) - EXPECTED_UNION_SQ_MI);
  console.log(`    place ${Number(cov.place_sq_mi).toFixed(4)} · union ${Number(cov.union_sq_mi).toFixed(4)} · ` +
              `uncovered ${Number(cov.uncovered).toFixed(4)} · outside ${Number(cov.outside).toFixed(4)}`);
  if (unionDrift > UNION_TOLERANCE_SQ_MI) {
    fail(`GATE 5: union is ${Number(cov.union_sq_mi).toFixed(4)} sq mi, expected ~${EXPECTED_UNION_SQ_MI}.`);
  }
  if (Number(cov.uncovered) > MAX_PLACE_UNCOVERED_SQ_MI) {
    fail(`GATE 5: ${Number(cov.uncovered).toFixed(4)} sq mi of the place polygon has no council district ` +
         `(bound ${MAX_PLACE_UNCOVERED_SQ_MI}). The measured gap is unincorporated county; a larger one is not.`);
  }
  if (Number(cov.outside) > MAX_OUTSIDE_PLACE_SQ_MI) {
    fail(`GATE 5: ${Number(cov.outside).toFixed(4)} sq mi of council district lies outside the place polygon ` +
         `(bound ${MAX_OUTSIDE_PLACE_SQ_MI}).`);
  }
  console.log('  ✓ within the measured bounds');

  // ─── GATE 6: independent cross-check at every district's interior point ──────────────
  console.log("\nGATE 6 — every district agrees with the Election Board's precinct City_Dist");
  const pts = await q(`SELECT district, ST_X(ST_PointOnSurface(geom)) AS lon,
                                        ST_Y(ST_PointOnSurface(geom)) AS lat
                       FROM fw_geom ORDER BY district`);
  const seen = new Set<string>();
  for (const p of pts) {
    const j = await fetchJson(precinctAtPointUrl(Number(p.lon), Number(p.lat)), `precinct probe D${p.district}`);
    const f = (j.features || [])[0];
    const cd = f ? String(f.attributes?.City_Dist ?? '').trim() : '(no precinct)';
    if (cd !== `FW ${p.district}`) {
      fail(`GATE 6: district ${p.district}'s interior point sits in a precinct assigned to ` +
           `${JSON.stringify(cd)}, not "FW ${p.district}".`);
    }
    seen.add(cd);
    console.log(`  ✓ D${p.district} -> precinct ${f?.attributes?.Precinct} City_Dist=${cd}`);
  }
  // A field that returned the same value everywhere would agree with anything.
  if (seen.size !== EXPECTED_COUNT) {
    fail(`GATE 6: the precinct City_Dist field returned only ${seen.size} distinct value(s) across ` +
         `${EXPECTED_COUNT} districts -- it is not discriminating, so its agreement proves nothing.`);
  }
  console.log(`  ✓ ${seen.size} distinct values across ${EXPECTED_COUNT} districts — the field discriminates`);

  // ─── Write ───────────────────────────────────────────────────────────────────────────
  if (DRY_RUN) {
    console.log('\nDRY RUN — nothing written.');
    await pool.end();
    return;
  }

  console.log('\nWriting…');
  const res = await q(
    `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
     SELECT geo_id, ocd_id, name, $1, $2, geom, $3, now() FROM fw_geom
     ON CONFLICT (geo_id, mtfcc) DO NOTHING
     RETURNING geo_id`,
    [STATE_CODE, MTFCC, SOURCE],
  );
  console.log(`  inserted ${res.length} boundary row(s)`);

  const [after] = await q(
    `SELECT count(*) AS n FROM essentials.geofence_boundaries WHERE mtfcc=$1`, [MTFCC]);
  if (Number(after.n) !== EXPECTED_COUNT) {
    fail(`post-write: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED_COUNT}.`);
  }
  console.log(`  ✓ ${MTFCC} holds ${after.n} boundaries`);
  await pool.end();
}

main().catch((e) => fail(e instanceof Error ? e.message : String(e)));
