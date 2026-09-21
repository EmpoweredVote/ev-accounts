#!/usr/bin/env -S npx tsx
/**
 * load-gary-council-boundaries.ts
 *
 * Builds Gary's 6 Common Council district boundaries by DISSOLVING the county's election
 * precincts, and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='gary-in-council-district-1'..'-6',
 *                                   mtfcc='X0050', state='in'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0096 creates the six districts and their
 * offices and refuses to run if these six boundaries are absent; CC_0097 seats the members.
 *
 * Wave IN-8 of the Knight Foundation cities program.
 * Spec:    docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Roster:  backend/data/seed-gary-2026/ROSTERS.md
 * Tracker: .planning/knight-foundation/PROGRAM.md
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * SOURCE — the Lake County SURVEYOR's public feature service:
 *
 *   https://services5.arcgis.com/8CXRnvSfSpwdf0R6/arcgis/rest/services/
 *       Selectable_Features/FeatureServer/4    "Election Precincts", 342 polygons, field P26
 *
 * 47 of those are Gary's, named `G<district> <precinct>` — so the council district is the
 * LEADING DIGIT, and the six districts are a dissolve rather than a published layer.
 *
 * 🔴🔴 WHY THIS WAVE EXISTS AT ALL, AND WHAT IN-4/IN-6 GOT WRONG.
 * IN-4 deferred Gary's six district seats because no usable boundary could be found, and IN-6
 * recorded that Lake County's open-data organisation (`lakecountyod`, 174 layers) is cadastral
 * and physical with NO electoral district layer. That was TRUE OF THE ORG IT SEARCHED and false
 * about the county: this layer lives in a DIFFERENT ArcGIS organisation, the Surveyor's
 * (`lakecountyhub-lakeingispro`), reachable from the county's own "Request GIS Map or Data"
 * link. ▶ A NEGATIVE RESULT IS ONLY EVER TRUE OF THE PLACE YOU LOOKED.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE VINTAGE GATE IS THE POINT OF THIS FILE, BECAUSE TWO WRONG MAPS WERE REJECTED FIRST.
 *
 *   1. `github.com/cityofgary/administrative-boundaries` — the City's OWN repo, 6 districts,
 *      EPSG 4326 GeoJSON, correctly named. ONE COMMIT, 2014-07-21: nine years older than the
 *      settlement map and older than the 2020 census. Rejected by IN-4.
 *   2. Census `tl_2020_18_vtd20` — all 52 Gary precincts under the SAME `G<d>-<p>` scheme,
 *      which dissolves into a six-district map that looks right at a glance. It is the
 *      PRE-SETTLEMENT assignment. Rejected 2026-09-11.
 *
 * Gary missed the statutory 2022-12-31 redistricting deadline, was sued (total deviation ~24%),
 * and adopted a new map under settlement on 2023-02-10, governing from the 2023 primary. Three
 * precincts tell the two vintages apart, and GATE 2 asserts all three:
 *
 *   precinct   TIGER 2020 puts it in     this layer & the county's 2024 PDF
 *   G4 01      districts 2 and 5         district 4
 *   G5 22      districts 1 and 4         district 5
 *   G5 28      district 4                district 5
 *
 * ⚠ `P26` IS READ AS "precincts, 2026" AND THAT IS AN INFERENCE, NOT A SOURCED FACT. What is
 * SOURCED is that this layer agrees with the Lake County Board of Elections' own published map
 * (`GARY CITY COUNCIL DISTRICTS 3X5.pdf`, Esri ArcMap, created 2024-03-01) on all three
 * precincts above, and TIGER 2020 agrees with it on none. Precinct counts fall 52 -> 47, which
 * is consolidation; consolidation does not move a district boundary unless it crosses one, and
 * GATE 3's single-polygon test plus GATE 5's closure bound are what would catch it if it did.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🟢 UNLIKE FORT WAYNE, GARY'S DISTRICTS ESSENTIALLY CLOSE. Measured 2026-09-11 against
 * production's own 1827000/G4110:
 *
 *     place                     50.663 sq mi
 *     union of the 6 districts  57.222 sq mi
 *     place NOT covered          0.105 sq mi   (0.21% — 41.3 + 19.2 + 5.0 + 4 tiny acres)
 *     districts OUTSIDE place    6.665 sq mi
 *
 * The 6.665 outside is LAKE MICHIGAN: TIGER measures Gary's water at 7.47 sq mi, and the
 * precincts run out to the city's lake boundary while the place polygon does not. That is
 * expected, and it is why GATE 5 bounds rather than requires equality.
 *
 * The 0.105 uncovered is a TIGER-vs-county limits disagreement of the same kind Fort Wayne
 * measured at 1.2524 sq mi — here an order of magnitude smaller. Of its seven pieces only one
 * is compact (5.0 acres, thinness 18); the rest are edge slivers up to thinness 29,523.
 *
 *   node --env-file=.env --import tsx scripts/load-gary-council-boundaries.ts --dry-run
 */
import { Pool } from 'pg';

const SERVICE =
  'https://services5.arcgis.com/8CXRnvSfSpwdf0R6/arcgis/rest/services/Selectable_Features/FeatureServer/4';
const QUERY_URL =
  `${SERVICE}/query?where=${encodeURIComponent("P26 LIKE 'G%'")}` +
  '&outFields=P26&returnGeometry=true&outSR=4326&f=json';

const MTFCC = 'X0050';
/** state = 'in', not FIPS '18' — the private-MTFCC convention from X0030 up. See X0048/X0049. */
const STATE_CODE = 'in';
const SOURCE =
  'lakecountyin-surveyor-Selectable_Features-4-Election_Precincts-P26-2026-09-11 (Knight IN-8); ' +
  "Lake County Surveyor's public precinct layer, dissolved on the leading digit of P26, " +
  "vintage-gated against the Board of Elections' own 2024-03-01 district map on G4 01/G5 22/G5 28";
const GEO_ID_PREFIX = 'gary-in-council-district-';
const OCD_PREFIX = 'ocd-division/country:us/state:in/place:gary/council_district:';

const PLACE_GEO_ID = '1827000';
const PLACE_MTFCC = 'G4110';

const DISTRICTS = ['1', '2', '3', '4', '5', '6'] as const;
const EXPECTED_PRECINCTS = 47;
/** Measured 2026-09-11; the per-district precinct split is itself a shape of the map. */
const EXPECTED_PRECINCTS_PER_DISTRICT: Record<string, number> =
  { '1': 7, '2': 7, '3': 8, '4': 7, '5': 10, '6': 8 };

/** GATE 2 — the three precincts that separate the 2023 settlement map from TIGER 2020. */
const VINTAGE_PRECINCTS: Record<string, string> = {
  'G4 01': '4', 'G5 22': '5', 'G5 28': '5',
};
/**
 * 🔴 WATCH GATE 2 FAIL BEFORE TRUSTING IT. `GARY_VINTAGE_CONTROL=1` adds `G4 22` — a precinct
 * that exists ONLY in TIGER 2020's pre-settlement assignment and must be absent here. If the
 * gate stays green with it, the gate is not reading what it claims to read.
 */
if (process.env.GARY_VINTAGE_CONTROL === '1') VINTAGE_PRECINCTS['G4 22'] = '4';

/** GATE 4 — measured 2026-09-11 against production PostGIS, ST_MakeValid first. */
const EXPECTED_AREA_SQ_MI: Record<string, number> = {
  '1': 20.030, '2': 11.284, '3': 7.207, '4': 4.717, '5': 10.638, '6': 3.346,
};
const AREA_TOLERANCE_PCT = 2;
const EXPECTED_UNION_SQ_MI = 57.222;
const UNION_TOLERANCE_SQ_MI = 1.0;

/** GATE 5 — measured at zero on all fifteen pairs. */
const MAX_PAIR_OVERLAP_SQ_MI = 0.001;

/** GATE 6 — bounds, not equality. See the header for why each side is non-zero. */
const MAX_PLACE_UNCOVERED_SQ_MI = 0.30;  // measured 0.105
const MAX_OUTSIDE_PLACE_SQ_MI = 8.00;    // measured 6.665, and it is Lake Michigan

const DRY_RUN = process.argv.includes('--dry-run');
const SQM_PER_SQMI = 2589988.110336;

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

/** ESRI rings -> WKT MULTIPOLYGON. Rings are closed if the service did not close them. */
function ringsToWkt(rings: number[][][]): string {
  const parts = rings.map((ring) => {
    const pts = ring.map(([x, y]) => `${x.toFixed(8)} ${y.toFixed(8)}`);
    if (pts[0] !== pts[pts.length - 1]) pts.push(pts[0]);
    return `((${pts.join(',')}))`;
  });
  return `MULTIPOLYGON(${parts.join(',')})`;
}

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const q = async (sql: string, params: unknown[] = []) => (await pool.query(sql, params)).rows;

  console.log(`Gary Common Council districts -> ${MTFCC}${DRY_RUN ? '  (DRY RUN)' : ''}`);

  // ─── GATE 1: 47 Gary precincts, six districts, the expected split ────────────────────
  console.log('\nGATE 1 — 47 Gary precincts across exactly six districts');
  const j = await fetchJson(QUERY_URL, 'Election Precincts');
  const all: any[] = Array.isArray(j.features) ? j.features : [];
  const gary = all.filter((f) => /^G\d/.test(String(f.attributes?.P26 ?? '')));
  if (gary.length !== EXPECTED_PRECINCTS) {
    fail(`GATE 1: ${gary.length} Gary precincts, expected ${EXPECTED_PRECINCTS}. The county has ` +
         `re-split precincts; re-measure the dissolve before trusting it.`);
  }
  const byDistrict = new Map<string, any[]>();
  for (const f of gary) {
    const name = String(f.attributes.P26);
    const d = name[1];
    if (!(DISTRICTS as readonly string[]).includes(d)) fail(`GATE 1: precinct ${name} names district ${d}.`);
    if (!f.geometry?.rings) fail(`GATE 1: precinct ${name} carries no geometry.`);
    (byDistrict.get(d) ?? byDistrict.set(d, []).get(d)!).push(f);
  }
  if (byDistrict.size !== 6) fail(`GATE 1: ${byDistrict.size} distinct districts, expected 6.`);
  for (const d of DISTRICTS) {
    const got = byDistrict.get(d)!.length;
    const want = EXPECTED_PRECINCTS_PER_DISTRICT[d];
    if (got !== want) fail(`GATE 1: district ${d} has ${got} precincts, expected ${want}.`);
  }
  console.log(`  ✓ ${gary.length} precincts, 6 districts, split ` +
              DISTRICTS.map((d) => `${d}:${byDistrict.get(d)!.length}`).join(' '));

  // ─── GATE 2: the vintage, asserted on the three precincts that failed TIGER 2020 ─────
  console.log('\nGATE 2 — vintage: the three precincts that separate the settlement map from TIGER 2020');
  const names = new Set(gary.map((f) => String(f.attributes.P26)));
  for (const [precinct, district] of Object.entries(VINTAGE_PRECINCTS)) {
    if (!names.has(precinct)) {
      fail(`GATE 2: precinct ${JSON.stringify(precinct)} is ABSENT. TIGER 2020 does not carry it ` +
           `either — this layer may have reverted to the pre-settlement map. STOP and re-verify ` +
           `against the Board of Elections' published PDF before loading.`);
    }
    const actual = precinct[1];
    if (actual !== district) fail(`GATE 2: ${precinct} names district ${actual}, expected ${district}.`);
  }
  console.log(`  ✓ ${Object.keys(VINTAGE_PRECINCTS).join(', ')} all present, all in their post-settlement districts`);

  // ─── Dissolve in PostGIS, then gate the result ───────────────────────────────────────
  console.log('\nDissolving precincts into districts (PostGIS ST_Union)');
  await q('CREATE TEMP TABLE _gp(dist text, name text, geom geometry)');
  for (const f of gary) {
    await q('INSERT INTO _gp(dist,name,geom) VALUES ($1,$2,ST_MakeValid(ST_GeomFromText($3,4326)))',
            [String(f.attributes.P26)[1], String(f.attributes.P26), ringsToWkt(f.geometry.rings)]);
  }
  await q(`CREATE TEMP TABLE _gd AS
           SELECT dist, ST_MakeValid(ST_Union(geom)) AS geom FROM _gp GROUP BY dist`);

  // ─── GATE 3: each district is ONE connected polygon ──────────────────────────────────
  console.log('\nGATE 3 — each dissolved district is a single connected polygon');
  const parts = await q(
    `SELECT dist, ST_NumGeometries(geom) AS parts, GeometryType(geom) AS gtype, ST_IsValid(geom) AS valid
     FROM _gd ORDER BY dist`);
  for (const r of parts) {
    if (!r.valid) fail(`GATE 3: district ${r.dist} dissolves to an INVALID geometry.`);
    if (Number(r.parts) !== 1) {
      fail(`GATE 3: district ${r.dist} dissolves to ${r.parts} disconnected parts. A council ` +
           `district built from precincts must be contiguous; this means the P26 assignment ` +
           `disagrees with the map, or a precinct has moved.`);
    }
  }
  console.log(`  ✓ all six are one connected, valid polygon`);

  // ─── GATE 4: areas ───────────────────────────────────────────────────────────────────
  console.log('\nGATE 4 — per-district area within tolerance, and the union');
  const areas = await q(`SELECT dist, ST_Area(geom::geography)/$1 AS sq_mi FROM _gd ORDER BY dist`,
                        [SQM_PER_SQMI]);
  for (const r of areas) {
    const want = EXPECTED_AREA_SQ_MI[r.dist];
    const drift = Math.abs(Number(r.sq_mi) - want) / want * 100;
    if (drift > AREA_TOLERANCE_PCT) {
      fail(`GATE 4: district ${r.dist} is ${Number(r.sq_mi).toFixed(4)} sq mi, expected ~${want} ` +
           `(${drift.toFixed(2)}% drift, tolerance ${AREA_TOLERANCE_PCT}%).`);
    }
    console.log(`    district ${r.dist}: ${Number(r.sq_mi).toFixed(3)} sq mi  (${drift.toFixed(2)}% from measured)`);
  }
  const [u] = await q(`SELECT ST_Area(ST_Union(geom)::geography)/$1 AS sq_mi FROM _gd`, [SQM_PER_SQMI]);
  if (Math.abs(Number(u.sq_mi) - EXPECTED_UNION_SQ_MI) > UNION_TOLERANCE_SQ_MI) {
    fail(`GATE 4: union is ${Number(u.sq_mi).toFixed(4)} sq mi, expected ~${EXPECTED_UNION_SQ_MI}.`);
  }
  console.log(`  ✓ union ${Number(u.sq_mi).toFixed(3)} sq mi`);

  // ─── GATE 5: no two districts overlap ────────────────────────────────────────────────
  console.log('\nGATE 5 — no pairwise overlap');
  const [ov] = await q(
    `SELECT coalesce(max(ST_Area(ST_Intersection(a.geom,b.geom)::geography)/$1),0) AS worst
     FROM _gd a JOIN _gd b ON a.dist < b.dist WHERE ST_Intersects(a.geom,b.geom)`, [SQM_PER_SQMI]);
  if (Number(ov.worst) > MAX_PAIR_OVERLAP_SQ_MI) {
    fail(`GATE 5: worst pairwise overlap is ${Number(ov.worst).toFixed(6)} sq mi.`);
  }
  console.log(`  ✓ worst pair overlap ${Number(ov.worst).toFixed(6)} sq mi`);

  // ─── GATE 6: coverage BOUND against the place polygon ────────────────────────────────
  console.log('\nGATE 6 — coverage bound against TIGER place ' + PLACE_GEO_ID);
  const [cov] = await q(
    `WITH u AS (SELECT ST_MakeValid(ST_Union(geom)) g FROM _gd),
          p AS (SELECT geometry g FROM essentials.geofence_boundaries
                 WHERE geo_id=$1 AND mtfcc=$2)
     SELECT ST_Area(p.g::geography)/$3 AS place,
            ST_Area(ST_Difference(p.g,u.g)::geography)/$3 AS uncovered,
            ST_Area(ST_Difference(u.g,p.g)::geography)/$3 AS outside
     FROM u,p`, [PLACE_GEO_ID, PLACE_MTFCC, SQM_PER_SQMI]);
  if (!cov) fail(`GATE 6: place ${PLACE_GEO_ID}/${PLACE_MTFCC} is not in production.`);
  if (Number(cov.uncovered) > MAX_PLACE_UNCOVERED_SQ_MI) {
    fail(`GATE 6: ${Number(cov.uncovered).toFixed(4)} sq mi of Gary is covered by NO district ` +
         `(bound ${MAX_PLACE_UNCOVERED_SQ_MI}). Those addresses would return no councilmember.`);
  }
  if (Number(cov.outside) > MAX_OUTSIDE_PLACE_SQ_MI) {
    fail(`GATE 6: districts extend ${Number(cov.outside).toFixed(4)} sq mi beyond the place ` +
         `(bound ${MAX_OUTSIDE_PLACE_SQ_MI}).`);
  }
  console.log(`  ✓ place ${Number(cov.place).toFixed(3)}, uncovered ${Number(cov.uncovered).toFixed(3)}, ` +
              `outside ${Number(cov.outside).toFixed(3)} sq mi`);

  // ─── Write ───────────────────────────────────────────────────────────────────────────
  if (DRY_RUN) {
    console.log('\nDRY RUN — nothing written. All gates passed.');
    await pool.end();
    return;
  }
  console.log(`\nWriting ${DISTRICTS.length} boundaries`);
  for (const d of DISTRICTS) {
    const geoId = `${GEO_ID_PREFIX}${d}`;
    await q(
      `INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, state, name, ocd_id, geometry, source)
       SELECT $1,$2,$3,$4,$5, geom, $6 FROM _gd WHERE dist=$7
       ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
      [geoId, MTFCC, STATE_CODE, `Gary City Council District ${d}`, `${OCD_PREFIX}${d}`, SOURCE, d]);
    const [chk] = await q(
      `SELECT ST_Area(geometry::geography)/$1 AS sq_mi FROM essentials.geofence_boundaries
        WHERE geo_id=$2 AND mtfcc=$3`, [SQM_PER_SQMI, geoId, MTFCC]);
    if (!chk) fail(`write: ${geoId} is not present after insert.`);
    console.log(`  ✓ ${geoId}  ${Number(chk.sq_mi).toFixed(3)} sq mi`);
  }
  await pool.end();
  console.log('\nDone. CC_0096 can now create the districts and offices.');
}

main().catch((e) => fail(String(e)));
