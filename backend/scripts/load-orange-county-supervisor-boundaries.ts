#!/usr/bin/env -S npx tsx
/**
 * load-orange-county-supervisor-boundaries.ts
 *
 * Loads the five Orange County (California) Supervisorial District boundaries from the county's own GIS
 * server (OC Public Works, ocgis.com "Map_Layers/Supervisorial_Districts", layer 0):
 *
 *   essentials.geofence_boundaries   mtfcc='X-OC-SUP', state='06', one row per district
 *   geo_id = 'ocd-division/country:us/state:ca/county:orange/council_district:N'  (the form the two
 *            existing district rows already carry, and the form LA County's supervisors use)
 *
 * Writes ONLY to essentials.geofence_boundaries. Migration CA_0238 points the districts at these boundaries
 * and refuses to run if they are absent.
 *
 * WHY (measured 2026-09-24)
 * -------------------------
 *   The board had 2 of 5 seats (District 1 Nguyen, District 4 Chaffee), both on OCD geo_ids with NO
 *   geofence, so no address reached either (reachability baseline UNREACHABLE ca|COUNTY 2).
 *
 * WHY A NAMED X-CODE
 * ------------------
 *   There is no central X-code registry, and another open branch (knight/oh-slice8) is taking the numbered
 *   codes in sequence (X0063, X0064 are in production but not on master). A named code cannot collide:
 *   'X-OC-SUP' follows 'X-RC-SUP' (Racine supervisors) and 'X-DC-SUP' (Dane). The address join's X catch-all
 *   admits it for COUNTY districts (districtQueries.ts GEOFENCE_DISTRICT_JOIN, geoIdGuard.ts).
 *
 * GATES
 * -----
 *   1  exactly five features, DISTRICT 1-5 once each, and each feature's NAME is the member the board's own
 *      page (board.oc.gov, read 2026-09-24) lists for that district — the layer is the current map, not a
 *      redistricting draft
 *   2  valid multipolygons
 *   3  no district overlaps another (> 0.001 sq mi)
 *   4  CLOSURE: >= 99.5% of the union lies inside the county's own G4020 polygon (06059), and every
 *      incorporated place wholly in the county that is NOT on the coast is >= 99.9% covered. (The TIGER
 *      county and coastal-city polygons include ocean — 06059 is 949.7 sq mi, the land districts 798.8 —
 *      so coverage of the county polygon itself cannot be gated.)
 *   5  CONTROL: SCAG's regional supervisorial layer (maps.scag.ca.gov, OpenData/Supervisorial_boundary_scag,
 *      YEAR 2023 = the 2021 redistricting map) agrees per district: symmetric difference under 2% of the
 *      district's area. Measured 2026-09-24: 0.077-0.860% (D1's is coastline generalisation).
 *
 * Usage (DATABASE_URL from backend/.env, or in the environment):
 *   npx tsx scripts/load-orange-county-supervisor-boundaries.ts --dry-run
 *   npx tsx scripts/load-orange-county-supervisor-boundaries.ts
 */
import 'dotenv/config';
import { Pool } from 'pg';

const OC_LAYER = 'https://ocgis.com/arcpub/rest/services/Map_Layers/Supervisorial_Districts/MapServer/0';
const SCAG_LAYER = 'https://maps.scag.ca.gov/scaggis/rest/services/OpenData/Supervisorial_boundary_scag/MapServer/0';
const MTFCC = 'X-OC-SUP';
const STATE_CODE = '06';
const COUNTY_GEO_ID = '06059';
const SOURCE =
  'OC Public Works GIS, ocgis.com/arcpub Map_Layers/Supervisorial_Districts/MapServer/0 (2021 redistricting map, ' +
  'adopted 2021-12-07), read 2026-09-24; NAME field matches board.oc.gov on all five districts; control SCAG ' +
  'Supervisorial_boundary_scag (YEAR 2023) symmetric difference <= 0.86% per district';
/** GATE 1 — the board's own roster (board.oc.gov, read 2026-09-24), by district. */
const ROSTER: Record<number, string> = {
  1: 'Janet Nguyen', 2: 'Vicente Sarmiento', 3: 'Donald P. Wagner', 4: 'Doug Chaffee', 5: 'Katrina Foley',
};
const MAX_OVERLAP_SQ_MI = 0.001;
const MIN_UNION_IN_COUNTY_PCT = 99.5;
const MIN_INLAND_PLACE_COVERED_PCT = 99.9;
/** Coastal cities whose TIGER polygon includes ocean; GATE 4 does not hold them to the inland threshold. */
const COASTAL_PLACES = ['Seal Beach city', 'Huntington Beach city', 'Newport Beach city', 'Laguna Beach city',
                        'Dana Point city', 'San Clemente city'];
const CONTROL_MAX_SYMDIFF_PCT = 2.0;
const SQM_PER_SQMI = 2589988.110336;
const DRY_RUN = process.argv.includes('--dry-run');

interface Feature { properties?: Record<string, unknown> | null; geometry?: unknown }

function fail(msg: string): never { console.error(`\n❌ ${msg}`); process.exit(1); }

async function fetchJson(url: string, label: string): Promise<any> {
  for (let attempt = 1; ; attempt++) {
    const r = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0 (EmpoweredVote civic data)', 'Accept-Encoding': 'gzip' } });
    const text = await r.text();
    let j: any = null;
    try { j = JSON.parse(text); } catch { /* handled below */ }
    const serverError = r.status >= 500 || (j && j.error && Number(j.error.code) >= 500);
    if (serverError && attempt < 5) {
      console.log(`    (${label}: server error, retry ${attempt}/4)`);
      await new Promise((res) => setTimeout(res, 3000 * attempt));
      continue;
    }
    if (!r.ok) fail(`${label}: HTTP ${r.status}`);
    if (j === null) fail(`${label}: HTTP ${r.status} but the body is not JSON (${text.length} bytes).`);
    if (j.error) fail(`${label}: service returned an error payload: ${JSON.stringify(j.error)}`);
    return j;
  }
}

async function fetchDistricts(layer: string, where: string, label: string): Promise<Map<number, Feature>> {
  const j = await fetchJson(`${layer}/query?where=${encodeURIComponent(where)}&outFields=DISTRICT,NAME` +
                            `&returnGeometry=true&outSR=4326&f=geojson`, label);
  const feats: Feature[] = Array.isArray(j.features) ? j.features : [];
  if (feats.length !== 5) fail(`GATE 1: ${label} returned ${feats.length} features, expected 5.`);
  const out = new Map<number, Feature>();
  for (const f of feats) {
    const n = Number(f.properties?.DISTRICT);
    if (!Number.isInteger(n) || n < 1 || n > 5) fail(`GATE 1: ${label} carries DISTRICT ${JSON.stringify(f.properties?.DISTRICT)}.`);
    if (out.has(n)) fail(`GATE 1: ${label} district ${n} appears twice.`);
    if (!f.geometry) fail(`GATE 1: ${label} district ${n} carries no geometry.`);
    out.set(n, f);
  }
  return out;
}

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();
  const q = async (sql: string, params: unknown[] = []) => (await client.query(sql, params)).rows;
  const sqmi = (e: string) => `(ST_Area((${e})::geography) / ${SQM_PER_SQMI})`;
  console.log(`Orange County CA supervisorial districts -> ${MTFCC}${DRY_RUN ? '  (DRY RUN)' : ''}`);

  console.log('\nGATE 1 — five districts, current members');
  const oc = await fetchDistricts(OC_LAYER, '1=1', 'ocgis Supervisorial_Districts');
  for (const [n, f] of oc) {
    const name = String(f.properties?.NAME ?? '').trim();
    if (name !== ROSTER[n]) fail(`GATE 1: district ${n} NAME is ${JSON.stringify(name)}, the board lists ${ROSTER[n]}.`);
  }
  console.log('  ✓ ' + [...oc.keys()].sort().map((n) => `D${n} ${ROSTER[n]}`).join(', '));

  const geomSql = (p: string) => `ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(${p})), 4326)), 3))`;
  await q(`CREATE TEMP TABLE oc_dist (n int PRIMARY KEY, geom geometry)`);
  await q(`CREATE TEMP TABLE oc_ctrl (n int PRIMARY KEY, geom geometry)`);
  for (const [n, f] of oc) await q(`INSERT INTO oc_dist VALUES ($1, ${geomSql('$2')})`, [n, JSON.stringify(f.geometry)]);

  console.log('\nGATE 2 — valid multipolygons');
  const bad = await q(`SELECT n FROM oc_dist WHERE geom IS NULL OR ST_IsEmpty(geom) OR NOT ST_IsValid(geom) OR GeometryType(geom) <> 'MULTIPOLYGON'`);
  if (bad.length) fail(`GATE 2: invalid geometry for district(s) ${bad.map((r) => r.n).join(', ')}.`);
  console.log('  ✓ all valid');

  console.log('\nGATE 3 — no overlaps');
  const ov = await q(`SELECT a.n a, b.n b, ${sqmi('ST_Intersection(a.geom, b.geom)')} mi FROM oc_dist a JOIN oc_dist b ON a.n < b.n
                       WHERE ST_Intersects(a.geom, b.geom) AND ${sqmi('ST_Intersection(a.geom, b.geom)')} > $1`, [MAX_OVERLAP_SQ_MI]);
  if (ov.length) fail(`GATE 3: overlaps ${ov.map((r) => `D${r.a}/D${r.b} ${Number(r.mi).toFixed(4)} sq mi`).join('; ')}.`);
  console.log('  ✓ none');

  console.log('\nGATE 4 — closure against the county and its inland cities');
  const [cl] = await q(`WITH u AS (SELECT ST_Union(geom) g FROM oc_dist),
                             k AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = 'G4020')
                        SELECT ${sqmi('u.g')} union_mi, 100 * ${sqmi('ST_Intersection(u.g, k.g)')} / ${sqmi('u.g')} in_pct FROM u, k`, [COUNTY_GEO_ID]);
  if (!cl) fail(`GATE 4: no G4020 geofence for ${COUNTY_GEO_ID}.`);
  if (Number(cl.in_pct) < MIN_UNION_IN_COUNTY_PCT) fail(`GATE 4: only ${Number(cl.in_pct).toFixed(3)}% of the districts lie in the county.`);
  const places = await q(`WITH u AS (SELECT ST_Union(geom) g FROM oc_dist),
                               k AS (SELECT geometry g FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = 'G4020')
                          SELECT gb.name, 100 * ${sqmi('ST_Intersection(gb.geometry, u.g)')} / ${sqmi('gb.geometry')} pct
                            FROM essentials.geofence_boundaries gb, u, k
                           WHERE gb.mtfcc = 'G4110' AND gb.state = $2 AND ST_Intersects(gb.geometry, k.g)
                             AND ST_Area(ST_Intersection(gb.geometry, k.g)::geography) > 0.9 * ST_Area(gb.geometry::geography)`,
                         [COUNTY_GEO_ID, STATE_CODE]);
  const inland = places.filter((p) => !COASTAL_PLACES.includes(p.name));
  const short = inland.filter((p) => Number(p.pct) < MIN_INLAND_PLACE_COVERED_PCT);
  if (inland.length < 25) fail(`GATE 4: only ${inland.length} inland cities found in the county; expected ~28.`);
  if (short.length) fail(`GATE 4: inland cities not covered: ${short.map((p) => `${p.name} ${Number(p.pct).toFixed(3)}%`).join('; ')}.`);
  console.log(`  ✓ ${Number(cl.union_mi).toFixed(1)} sq mi, ${Number(cl.in_pct).toFixed(3)}% inside ${COUNTY_GEO_ID}; ` +
              `${inland.length} inland cities >= ${MIN_INLAND_PLACE_COVERED_PCT}% covered`);

  console.log('\nGATE 5 — control: SCAG regional layer');
  const scag = await fetchDistricts(SCAG_LAYER, "COUNTY LIKE 'Orange%'", 'SCAG Supervisorial_boundary_scag Orange');
  for (const [n, f] of scag) await q(`INSERT INTO oc_ctrl VALUES ($1, ${geomSql('$2')})`, [n, JSON.stringify(f.geometry)]);
  const ctl = await q(`SELECT d.n, 100 * ${sqmi('ST_SymDifference(d.geom, c.geom)')} / ${sqmi('d.geom')} pct
                         FROM oc_dist d JOIN oc_ctrl c USING (n) ORDER BY d.n`);
  if (ctl.length !== 5) fail(`GATE 5: ${ctl.length} of 5 districts paired with the control.`);
  const off = ctl.filter((r) => Number(r.pct) >= CONTROL_MAX_SYMDIFF_PCT);
  if (off.length) fail(`GATE 5: disagrees with SCAG: ${off.map((r) => `D${r.n} ${Number(r.pct).toFixed(3)}%`).join('; ')}.`);
  console.log('  ✓ ' + ctl.map((r) => `D${r.n} ${Number(r.pct).toFixed(3)}%`).join(', '));

  const rows = [...oc.keys()].sort().map((n) => ({
    n, geo_id: `ocd-division/country:us/state:ca/county:orange/council_district:${n}`,
    name: `Orange County Supervisorial District ${n}`,
  }));
  const existing = await q(`SELECT geo_id FROM essentials.geofence_boundaries WHERE mtfcc = $1`, [MTFCC]);
  console.log(`\n  ${rows.length} boundaries; already present: ${existing.length}`);

  if (DRY_RUN) { console.log('\nDRY RUN — nothing written.'); client.release(); await pool.end(); return; }

  console.log('\nWriting…');
  let inserted = 0;
  for (const r of rows) {
    const res = await q(
      `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
       SELECT $1, $1, $2, $3, $4, ST_ForcePolygonCCW(geom), $5, now() FROM oc_dist WHERE n = $6
       ON CONFLICT (geo_id, mtfcc) DO NOTHING RETURNING geo_id`,
      [r.geo_id, r.name, STATE_CODE, MTFCC, SOURCE, r.n]);
    inserted += res.length;
  }
  console.log(`  inserted ${inserted} boundary row(s)`);
  const [after] = await q(`SELECT count(*)::int n FROM essentials.geofence_boundaries WHERE mtfcc = $1`, [MTFCC]);
  if (after.n !== 5) fail(`post-write: ${MTFCC} holds ${after.n} rows, expected 5.`);
  console.log(`  ✓ ${MTFCC} holds ${after.n} boundaries`);
  client.release();
  await pool.end();
}

main().catch((e) => fail(e instanceof Error ? e.message : String(e)));
