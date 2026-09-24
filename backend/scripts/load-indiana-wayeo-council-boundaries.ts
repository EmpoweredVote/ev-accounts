#!/usr/bin/env -S npx tsx
/**
 * load-indiana-wayeo-council-boundaries.ts
 *
 * Loads county council district boundaries for eight Indiana counties from the Indiana GIO statewide
 * county-council layer (the one behind the Secretary of State "Who Are Your Elected Officials" lookup,
 * WAYEO — the same layer load-lake-county-council-boundaries.ts took Lake's seven from, X0051):
 *
 *   essentials.geofence_boundaries   mtfcc='X0062', state='in', one row per seat that EXISTS today
 *
 * Writes ONLY to essentials.geofence_boundaries. The follow-up migration (CA_0217) points the districts at
 * these boundaries and refuses to run if they are absent.
 *
 * WHY (measured 2026-09-24)
 * -------------------------
 *   15 council seats have a district with NO geofence, so no address reaches them (reachability
 *   baseline UNREACHABLE in|COUNTY 15): Greene 1-4, Lawrence 1-4, Jackson 1, Morgan 4, and five
 *   Indianapolis City-County Council seats (8, 12, 13, 14, 18).
 *   12 more district seats — Brown, Martin and Owen Districts 1-4 — sit on the WHOLE-COUNTY district
 *   (geo_id = the county FIPS), so every resident is shown all four district members.
 *
 * WHY ONE X-CODE FOR EIGHT COUNTIES
 * ---------------------------------
 *   There is no central X-code registry; each loader takes the next free code (X0061 was the highest
 *   in production and on every remote ref, 2026-09-24). This loader reads ONE layer, so it takes ONE
 *   code: X0062 = "Indiana county council districts, statewide WAYEO layer". geo_ids stay unique per
 *   seat, so (geo_id, mtfcc) cannot collide across counties.
 *
 * GEO_IDS
 * -------
 *   The eleven Greene / Lawrence / Jackson / Morgan and five Indianapolis districts already carry a
 *   geo_id of the legacy Indiana form <state fips><county fips><5-digit seat> ('1805500001'), the form
 *   Monroe's council districts use ('1810500001', loaded from the county's own layer). This loader keeps
 *   those. Brown / Martin / Owen get new ids in the same form ('1801300001'); their district rows are
 *   repointed by CA_0217.
 *
 * GATES — the Lake loader's, generalised
 * --------------------------------------
 *   1  statewide feature count ~398 (a layer that changed size may be a different map); per county the
 *      expected number of districts (4; Marion 25), keyed '<fips3>-District N', one polygon each
 *   2  valid multipolygons
 *   3  no district overlaps another in the same county
 *   4  CLOSURE: the county's districts tile the county's own G4020 polygon (uncovered / outside tiny)
 *   5  VINTAGE: every precinct of the county in the Indiana GIO Voting_District_Boundaries_2024 layer
 *      sits wholly (>= 99%) inside exactly one district, and the precincts use every district.
 *      Indiana county council districts follow precinct lines; a stale map splits precincts of its own
 *      era (this is what caught Gary's 2014 layer in IN-9).
 *      🔴 WHY 2024 AND NOT 2026. The seats this loads are held by members elected in 2022 (district
 *      seats, terms 2022-2026 — e.g. browncounty-in.gov/182 lists Districts 1-4 "Jan 1, 2022 - Dec 31,
 *      2026") and, for Indianapolis, in 2023 under General Ordinance 18, 2022 (adopted 2022-05-02,
 *      indy.gov "Council District Map"). The geography they REPRESENT is the 2022 map, and 2024 is the
 *      latest precinct vintage of that era. Measured 2026-09-24: Brown County merged 11 precincts into 10
 *      for 2026 and the new JACKSON 2 lies 65% / 35% across Districts 1 and 2, while all 11 of its 2023 AND
 *      2024 precincts nest perfectly in this layer — so the 2026 precincts either split a council line or
 *      come with a new council map for the 2026 election. Either way that is the NEXT term's geography.
 *      The 2026 nesting is therefore REPORTED per county, not gated: a split there is a flag for whoever
 *      seeds the 2026 races, not a reason to withhold the current map from today's residents.
 *      SLIVER allowance: a precinct also nests if >= 95% of it is in one district and the rest totals
 *      <= 0.03 sq mi. Marion's 6 of 621 need it (strips 0.006-0.022 sq mi, 13-27 m wide) and need it
 *      identically against Indianapolis's own council layer (6b) — precinct-layer digitisation, not map.
 *   6  CONTROLS — the same layer, for two counties whose districts we ALREADY hold from an independent
 *      county source, must agree with them: Monroe (county election-map layer, 2022) and Allen (county
 *      Election Board). Per district, the symmetric difference must be under 1% of its area. If the
 *      state layer drifted from the counties' own maps, this is where it shows. Measured 2026-09-24:
 *      Monroe 0.000% in all four, Allen <= 0.005%.
 *   6b Marion's 25 against gis.indy.gov's own City Council layer (MapIndy sde_Voting/21, General
 *      Ordinance 18, 2022): 0.000% in all 25 — the state layer IS the city's.
 *   Detached fragments under 0.5 sq mi are REPORTED (not gated): a real unincorporated pocket and a
 *   digitising artefact look the same to a threshold.
 *
 * Usage (DATABASE_URL from backend/.env, or in the environment):
 *   npx tsx scripts/load-indiana-wayeo-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-indiana-wayeo-council-boundaries.ts
 */
import 'dotenv/config';
import { Pool } from 'pg';

const WAYEO =
  'https://services6.arcgis.com/3BIBAkkTYicFwv1e/arcgis/rest/services/WAYEO_WebMap_WFL1/FeatureServer/8';
/** GATE 5 runs against the 2024 precincts (hard) and REPORTS against the 2026 precincts. See the header. */
interface PrecinctLayer { vintage: string; url: string; field: string; order: string }
const PRECINCTS_2024: PrecinctLayer = { vintage: '2024', field: 'p24', order: 'fid',
  url: 'https://gisdata.in.gov/server/rest/services/Hosted/Voting_District_Boundaries_2024/FeatureServer/1' };
const PRECINCTS_2026: PrecinctLayer = { vintage: '2026', field: 'p26', order: 'objectid',
  url: 'https://gisdata.in.gov/server/rest/services/Hosted/Voting_District_Boundaries_2026/FeatureServer/0' };

const MTFCC = 'X0062';
/** state = 'in', not FIPS '18' — the private-MTFCC convention (X0048..X0051 are 'in'). */
const STATE_CODE = 'in';
const SOURCE =
  'wayeo-WAYEO_WebMap_WFL1-layer8-County_Council_Districts-2026-09-24 (layer lastEditDate 2025-03-18); ' +
  'the Indiana GIO statewide county-council layer behind the Secretary of State "Who Are Your Elected ' +
  'Officials" lookup (same layer as X0051 Lake); vintage-gated by nesting every Indiana GIO ' +
  'Voting_District_Boundaries_2024 precinct of the county in one district (2022-map terms); controls ' +
  'Monroe (county election-map layer 2022) 0.000%, Allen (county Election Board) <=0.005%, Marion vs ' +
  'gis.indy.gov City Council (General Ordinance 18, 2022) 0.000%';

interface Target {
  county: string;            // WAYEO `County` value
  fips3: string;             // WAYEO councildistrictid prefix and precinct-layer `county`
  countyGeoId: string;       // G4020 geo_id in production
  expected: number;          // districts in the layer for this county
  load: Record<string, string>; // district number -> geo_id to insert (only seats that exist)
  body: string;              // for the boundary name
  ocd: string;               // ocd county slug
}

const range = (fips5: string, ns: number[]) =>
  Object.fromEntries(ns.map((n) => [String(n), `${fips5}${String(n).padStart(5, '0')}`]));

const TARGETS: Target[] = [
  { county: 'Greene',   fips3: '055', countyGeoId: '18055', expected: 4,  load: range('18055', [1, 2, 3, 4]), body: 'Greene County Council',   ocd: 'greene' },
  { county: 'Lawrence', fips3: '093', countyGeoId: '18093', expected: 4,  load: range('18093', [1, 2, 3, 4]), body: 'Lawrence County Council', ocd: 'lawrence' },
  { county: 'Jackson',  fips3: '071', countyGeoId: '18071', expected: 4,  load: range('18071', [1]),          body: 'Jackson County Council',  ocd: 'jackson' },
  { county: 'Morgan',   fips3: '109', countyGeoId: '18109', expected: 4,  load: range('18109', [4]),          body: 'Morgan County Council',   ocd: 'morgan' },
  { county: 'Brown',    fips3: '013', countyGeoId: '18013', expected: 4,  load: range('18013', [1, 2, 3, 4]), body: 'Brown County Council',    ocd: 'brown' },
  { county: 'Martin',   fips3: '101', countyGeoId: '18101', expected: 4,  load: range('18101', [1, 2, 3, 4]), body: 'Martin County Council',   ocd: 'martin' },
  { county: 'Owen',     fips3: '119', countyGeoId: '18119', expected: 4,  load: range('18119', [1, 2, 3, 4]), body: 'Owen County Council',     ocd: 'owen' },
  { county: 'Marion',   fips3: '097', countyGeoId: '18097', expected: 25, load: range('18097', [8, 12, 13, 14, 18]), body: 'Indianapolis City-County Council', ocd: 'marion' },
];

/** GATE 6 — counties whose districts we already hold from an independent county source. */
interface Control { county: string; fips3: string; countyGeoId: string; expected: number; mtfcc: string; geoId: (n: string) => string; }
const CONTROLS: Control[] = [
  { county: 'Monroe', fips3: '105', countyGeoId: '18105', expected: 4, mtfcc: 'X0001', geoId: (n) => `18105${n.padStart(5, '0')}` },
  { county: 'Allen',  fips3: '003', countyGeoId: '18003', expected: 4, mtfcc: 'X0049', geoId: (n) => `allen-county-in-council-district-${n}` },
];

const EXPECTED_STATEWIDE_FEATURES = 398;
const STATEWIDE_TOLERANCE = 40;
const MAX_PAIR_OVERLAP_SQ_MI = 0.001;
const MAX_UNCOVERED_SQ_MI = 1.0;
const MAX_OUTSIDE_SQ_MI = 1.0;
const INSIDE_FRACTION = 0.99;
const OUTSIDE_FRACTION = 0.01;
const SLIVER_MIN_TOP_FRACTION = 0.95;
const SLIVER_MAX_REST_SQ_MI = 0.03;
/** GATE 6b — Indianapolis's own City-County Council layer (MapIndy sde_Voting, "City Council", 25). */
const INDY_COUNCIL = 'https://gis.indy.gov/server/rest/services/sde_Voting/sde_Voting/MapServer/21';
const CONTROL_MAX_SYMDIFF_PCT = 1.0;
const FRAGMENT_MAX_SQ_MI = 0.5;
const SQM_PER_SQMI = 2589988.110336;
const DRY_RUN = process.argv.includes('--dry-run');

interface Feature { properties?: Record<string, unknown> | null; geometry?: unknown }

function fail(msg: string): never { console.error(`\n❌ ${msg}`); process.exit(1); }

async function fetchJson(url: string, label: string): Promise<any> {
  const r = await fetch(url, { headers: { 'User-Agent': 'EmpoweredVote-civic-data/1.0', 'Accept-Encoding': 'gzip' } });
  const text = await r.text();
  // A clean HTTP 200 can carry a truncated or WAF-substituted body. Only a full decode catches it.
  if (!r.ok) fail(`${label}: HTTP ${r.status}`);
  let j: any;
  try { j = JSON.parse(text); } catch { fail(`${label}: HTTP ${r.status} but the body is not JSON (${text.length} bytes).`); }
  if (j && j.error) fail(`${label}: service returned an error payload: ${JSON.stringify(j.error)}`);
  return j;
}

async function fetchCountyDistricts(county: string, fips3: string, expected: number): Promise<Map<string, Feature>> {
  const url = `${WAYEO}/query?where=${encodeURIComponent(`County='${county}'`)}` +
    `&outFields=County,CountyCouncil,councildistrictid&returnGeometry=true&outSR=4326&f=geojson`;
  const j = await fetchJson(url, `WAYEO County='${county}'`);
  const feats: Feature[] = Array.isArray(j.features) ? j.features : [];
  if (feats.length !== expected) fail(`GATE 1: County='${county}' returned ${feats.length} features, expected ${expected}.`);
  const byDistrict = new Map<string, Feature>();
  for (const f of feats) {
    const id = String(f.properties?.councildistrictid ?? '').trim();
    const m = new RegExp(`^${fips3}-District (\\d+)$`).exec(id);
    if (!m) fail(`GATE 1: ${county} carries councildistrictid ${JSON.stringify(id)}, expected "${fips3}-District N".`);
    if (!f.geometry) fail(`GATE 1: ${county} ${id} carries no geometry.`);
    if (byDistrict.has(m[1])) fail(`GATE 1: ${county} district ${m[1]} appears twice.`);
    byDistrict.set(m[1], f);
  }
  for (let n = 1; n <= expected; n++) if (!byDistrict.has(String(n))) fail(`GATE 1: ${county} district ${n} is missing.`);
  return byDistrict;
}

async function fetchCountyPrecincts(layer: PrecinctLayer, fips3: string): Promise<Feature[]> {
  const out: Feature[] = [];
  for (let offset = 0; ; offset += 1000) {
    const url = `${layer.url}/query?where=${encodeURIComponent(`county='${fips3}'`)}` +
      `&outFields=${layer.field},county&returnGeometry=true&outSR=4326&f=geojson` +
      `&orderByFields=${layer.order}&resultOffset=${offset}&resultRecordCount=1000`;
    const j = await fetchJson(url, `precincts ${layer.vintage} county='${fips3}' @${offset}`);
    const feats: Feature[] = Array.isArray(j.features) ? j.features : [];
    out.push(...feats);
    if (feats.length < 1000 && !j.properties?.exceededTransferLimit && !j.exceededTransferLimit) break;
  }
  if (out.length === 0) fail(`GATE 5: the ${layer.vintage} precinct layer returned no precincts for county '${fips3}'.`);
  return out;
}

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();
  const q = async (sql: string, params: unknown[] = []) => (await client.query(sql, params)).rows;

  console.log(`Indiana WAYEO county council districts -> ${MTFCC}${DRY_RUN ? '  (DRY RUN)' : ''}`);

  console.log('\nGATE 1 — statewide layer size');
  const total = Number((await fetchJson(`${WAYEO}/query?where=1%3D1&returnCountOnly=true&f=json`, 'statewide count')).count);
  if (Math.abs(total - EXPECTED_STATEWIDE_FEATURES) > STATEWIDE_TOLERANCE) {
    fail(`GATE 1: the statewide layer holds ${total} features, expected ~${EXPECTED_STATEWIDE_FEATURES}.`);
  }
  console.log(`  ✓ ${total} features statewide`);

  await q(`CREATE TEMP TABLE w_dist (county text, district text, geom geometry) ON COMMIT PRESERVE ROWS`);
  await q(`CREATE TEMP TABLE w_prec (vintage text, county text, label text, geom geometry) ON COMMIT PRESERVE ROWS`);
  const geomSql = `ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($GJ), 4326)), 3))`;
  const insertDistrict = async (county: string, key: string, f: Feature) =>
    q(`INSERT INTO w_dist VALUES ($1, $2, ${geomSql.replace('$GJ', '$3')})`, [county, key, JSON.stringify(f.geometry)]);
  const insertPrecinct = async (vintage: string, county: string, key: string, f: Feature) =>
    q(`INSERT INTO w_prec VALUES ($1, $2, $3, ${geomSql.replace('$GJ', '$4')})`, [vintage, county, key, JSON.stringify(f.geometry)]);

  const all = [...TARGETS.map((t) => ({ ...t, control: false as const })), ...CONTROLS.map((c) => ({ ...c, control: true as const }))];
  for (const c of all) {
    const byDistrict = await fetchCountyDistricts(c.county, c.fips3, c.expected);
    for (const [n, f] of byDistrict) await insertDistrict(c.county, n, f);
    const counts: string[] = [];
    for (const layer of [PRECINCTS_2024, PRECINCTS_2026]) {
      const precincts = await fetchCountyPrecincts(layer, c.fips3);
      for (const f of precincts) {
        const label = String(f.properties?.[layer.field] ?? '').trim();
        if (!label) fail(`GATE 5: a ${c.county} ${layer.vintage} precinct carries no ${layer.field} label.`);
        if (!f.geometry) fail(`GATE 5: ${c.county} ${layer.vintage} precinct ${label} carries no geometry.`);
        await insertPrecinct(layer.vintage, c.county, label, f);
      }
      counts.push(`${precincts.length} precincts ${layer.vintage}`);
    }
    console.log(`  ✓ ${c.county.padEnd(8)} ${c.expected} districts keyed ${c.fips3}-District 1..${c.expected}; ${counts.join(', ')}${c.control ? '  (control)' : ''}`);
  }

  console.log('\nGATE 2 — valid multipolygons');
  const bad = await q(`SELECT county, district, ST_GeometryType(geom) t, ST_IsValid(geom) v FROM w_dist
                       WHERE ST_GeometryType(geom) <> 'ST_MultiPolygon' OR NOT ST_IsValid(geom) OR ST_IsEmpty(geom)`);
  if (bad.length) fail(`GATE 2: ${bad.map((b: any) => `${b.county} D${b.district} ${b.t} valid=${b.v}`).join(', ')}`);
  console.log('  ✓ all valid');

  console.log('\nGATE 3 — no overlaps within a county');
  const laps = await q(`SELECT a.county, a.district a, b.district b, ST_Area(ST_Intersection(a.geom, b.geom)::geography)/$1 sq_mi
                        FROM w_dist a JOIN w_dist b ON a.county = b.county AND a.district < b.district
                        WHERE ST_Intersects(a.geom, b.geom) AND ST_Area(ST_Intersection(a.geom, b.geom)::geography)/$1 > $2`,
                       [SQM_PER_SQMI, MAX_PAIR_OVERLAP_SQ_MI]);
  if (laps.length) fail(`GATE 3: ${laps.map((l: any) => `${l.county} D${l.a}/D${l.b} ${Number(l.sq_mi).toFixed(4)}`).join(', ')}`);
  console.log('  ✓ no overlapping pair');

  console.log('\nGATE 4 — CLOSURE against each county polygon (G4020)');
  for (const c of all) {
    const [cov] = await q(
      `SELECT ST_Area(cb.geometry::geography)/$1 county_sq_mi, ST_Area(u.g::geography)/$1 union_sq_mi,
              ST_Area(ST_Difference(cb.geometry, u.g)::geography)/$1 uncovered,
              ST_Area(ST_Difference(u.g, cb.geometry)::geography)/$1 outside
         FROM essentials.geofence_boundaries cb, (SELECT ST_Union(geom) g FROM w_dist WHERE county = $2) u
        WHERE cb.geo_id = $3 AND cb.mtfcc = 'G4020'`, [SQM_PER_SQMI, c.county, c.countyGeoId]);
    if (!cov) fail(`GATE 4: county polygon ${c.countyGeoId}/G4020 is not in production.`);
    const line = `${c.county.padEnd(8)} county ${Number(cov.county_sq_mi).toFixed(2)} · union ${Number(cov.union_sq_mi).toFixed(2)} · ` +
                 `uncovered ${Number(cov.uncovered).toFixed(4)} · outside ${Number(cov.outside).toFixed(4)} sq mi`;
    if (Number(cov.uncovered) > MAX_UNCOVERED_SQ_MI || Number(cov.outside) > MAX_OUTSIDE_SQ_MI) fail(`GATE 4: ${line}`);
    console.log(`  ✓ ${line}`);
  }

  // A precinct NESTS if >= 99% of it lies in one district and no other district holds more than 1% —
  // the Lake rule — OR, the SLIVER allowance, if >= 95% lies in one district and everything else
  // totals <= 0.03 sq mi. Measured 2026-09-24 in Marion: 6 of 621 2024 precincts miss the 99% rule by
  // strips 0.007-0.022 sq mi, 13-27 m mean width, along district lines — and they miss it IDENTICALLY
  // against gis.indy.gov's own City Council layer, which is byte-for-byte the state layer (0.000%
  // symmetric difference in all 25 districts). They are the precinct layer's digitisation, not a
  // different map. A real vintage split looks like Brown's 2026 JACKSON 2: 5.38 sq mi, 35%.
  const nesting = async (vintage: string, county: string) => {
    const rows = await q(
      `WITH shares AS (
         SELECT p.label, d.district,
                CASE WHEN ST_Area(p.geom::geography) = 0 THEN 0
                     ELSE ST_Area(ST_Intersection(d.geom, p.geom)::geography) / ST_Area(p.geom::geography) END AS frac,
                ST_Area(ST_Intersection(d.geom, p.geom)::geography) / $4 AS sq_mi,
                ST_Area(p.geom::geography) / $4 AS prec_sq_mi
           FROM w_prec p
           JOIN w_dist d ON d.county = p.county AND ST_Intersects(d.geom, p.geom)
          WHERE p.vintage = $1 AND p.county = $2),
       ranked AS (SELECT *, row_number() OVER (PARTITION BY label ORDER BY frac DESC) AS rk FROM shares)
       SELECT label,
              max(frac) AS top_frac,
              min(district) FILTER (WHERE rk = 1) AS district,
              count(*) FILTER (WHERE rk > 1 AND frac > $3) AS partial,
              max(prec_sq_mi) - sum(sq_mi) FILTER (WHERE rk = 1) AS rest_sq_mi,
              string_agg(district || '=' || round(frac::numeric, 3), ' ' ORDER BY frac DESC) FILTER (WHERE frac > $3) AS shares
         FROM ranked GROUP BY label`, [vintage, county, OUTSIDE_FRACTION, SQM_PER_SQMI]);
    const [{ n }] = await q(`SELECT count(*)::int n FROM w_prec WHERE vintage = $1 AND county = $2`, [vintage, county]);
    const strict = (r: any) => Number(r.top_frac) >= INSIDE_FRACTION && Number(r.partial) === 0;
    const sliver = (r: any) => !strict(r) && Number(r.top_frac) >= SLIVER_MIN_TOP_FRACTION && Number(r.rest_sq_mi) <= SLIVER_MAX_REST_SQ_MI;
    return { n, rows, split: rows.filter((r: any) => !strict(r) && !sliver(r)), slivers: rows.filter(sliver),
             used: new Set(rows.map((r: any) => String(r.district))) };
  };

  console.log('\nGATE 5 — VINTAGE: every 2024 precinct nests in exactly one district, and all districts are used');
  for (const c of all) {
    const { n, rows, split, slivers, used } = await nesting(PRECINCTS_2024.vintage, c.county);
    if (rows.length !== n) fail(`GATE 5: ${c.county}: ${n} precincts but ${rows.length} intersect a district.`);
    if (split.length) {
      fail(`GATE 5: ${c.county}: ${split.length} of ${n} 2024 precinct(s) do not nest in exactly one district: ` +
           split.slice(0, 12).map((r: any) => `${r.label} (${r.shares}; rest ${Number(r.rest_sq_mi).toFixed(4)} sq mi)`).join(', ') +
           `\n    A split precinct of the current terms' era means the district layer is a different vintage.`);
    }
    if (used.size !== c.expected) fail(`GATE 5: ${c.county}: precincts resolve to ${used.size} of ${c.expected} districts — not discriminating.`);
    console.log(`  ✓ ${c.county.padEnd(8)} ${n} precincts, each inside one of ${used.size} districts` +
      (slivers.length ? `  (${slivers.length} by the sliver allowance: ` +
        slivers.map((r: any) => `${r.label} ${r.shares} rest ${Number(r.rest_sq_mi).toFixed(4)} sq mi`).join('; ') + ')' : ''));
  }

  console.log('\nREPORT — 2026 precincts that cross a district line (next-election geography; not gated)');
  for (const c of all) {
    const { n, split } = await nesting(PRECINCTS_2026.vintage, c.county);
    console.log(split.length
      ? `  ⚠ ${c.county.padEnd(8)} ${split.length} of ${n}: ` + split.map((r: any) => `${r.label} (${r.shares})`).join('; ')
      : `  · ${c.county.padEnd(8)} all ${n} nest`);
  }

  console.log('\nGATE 6 — CONTROLS: the state layer agrees with the county sources we already hold');
  for (const c of CONTROLS) {
    for (let n = 1; n <= c.expected; n++) {
      const [r] = await q(
        `SELECT ST_Area(w.geom::geography)/$1 w_sq_mi,
                ST_Area(ST_SymDifference(w.geom, ST_MakeValid(gb.geometry))::geography)/$1 symdiff_sq_mi
           FROM w_dist w, essentials.geofence_boundaries gb
          WHERE w.county = $2 AND w.district = $3 AND gb.geo_id = $4 AND gb.mtfcc = $5`,
        [SQM_PER_SQMI, c.county, String(n), c.geoId(String(n)), c.mtfcc]);
      if (!r) fail(`GATE 6: control ${c.county} D${n}: no production boundary ${c.geoId(String(n))}/${c.mtfcc}.`);
      const pct = Number(r.symdiff_sq_mi) / Number(r.w_sq_mi) * 100;
      const line = `${c.county} D${n}: ${Number(r.w_sq_mi).toFixed(2)} sq mi, symmetric difference ${Number(r.symdiff_sq_mi).toFixed(4)} sq mi (${pct.toFixed(3)}%)`;
      if (pct > CONTROL_MAX_SYMDIFF_PCT) fail(`GATE 6: ${line} — the state layer disagrees with the county's own map.`);
      console.log(`  ✓ ${line}`);
    }
  }

  console.log("\nGATE 6b — CONTROL: Marion's 25 against Indianapolis's own City Council layer (gis.indy.gov)");
  const indy = await fetchJson(`${INDY_COUNCIL}/query?where=1%3D1&outFields=COUNCIL&returnGeometry=true&outSR=4326&f=geojson`, 'gis.indy.gov City Council');
  const indyFeats: Feature[] = Array.isArray(indy.features) ? indy.features : [];
  if (indyFeats.length !== 25) fail(`GATE 6b: gis.indy.gov City Council returned ${indyFeats.length} features, expected 25.`);
  await q(`CREATE TEMP TABLE w_indy (district text, geom geometry) ON COMMIT PRESERVE ROWS`);
  for (const f of indyFeats) {
    await q(`INSERT INTO w_indy VALUES ($1, ${geomSql.replace('$GJ', '$2')})`, [String(Number(f.properties?.COUNCIL)), JSON.stringify(f.geometry)]);
  }
  const indyCmp = await q(
    `SELECT w.district, 100 * ST_Area(ST_SymDifference(w.geom, i.geom)::geography) / ST_Area(w.geom::geography) AS pct
       FROM w_dist w LEFT JOIN w_indy i ON i.district = w.district WHERE w.county = 'Marion' ORDER BY w.district::int`);
  const indyBad = indyCmp.filter((r: any) => r.pct == null || Number(r.pct) > CONTROL_MAX_SYMDIFF_PCT);
  if (indyCmp.length !== 25 || indyBad.length) {
    fail(`GATE 6b: ${indyBad.length} Marion district(s) disagree with gis.indy.gov: ` +
         indyBad.map((r: any) => `D${r.district} ${r.pct == null ? 'missing' : Number(r.pct).toFixed(3) + '%'}`).join(', '));
  }
  console.log(`  ✓ all 25 agree (max symmetric difference ${Math.max(...indyCmp.map((r: any) => Number(r.pct))).toFixed(3)}%)`);

  console.log('\nREPORT — detached fragments under 0.5 sq mi (not gated)');
  const frags = await q(
    `SELECT county, district, count(*) n, sum(sq_mi) total FROM (
        SELECT w.county, w.district, ST_Area(d.geom::geography)/$1 sq_mi FROM w_dist w, LATERAL ST_Dump(w.geom) d) s
      WHERE sq_mi < $2 GROUP BY county, district ORDER BY county, district`, [SQM_PER_SQMI, FRAGMENT_MAX_SQ_MI]);
  console.log(frags.length ? frags.map((f: any) => `  ${f.county} D${f.district}: ${f.n} fragment(s), ${Number(f.total).toFixed(5)} sq mi`).join('\n') : '  none');

  console.log('\nTO WRITE');
  const rows: { geo_id: string; ocd: string; name: string; county: string; district: string }[] = [];
  for (const t of TARGETS) {
    for (const [n, geoId] of Object.entries(t.load)) {
      rows.push({ geo_id: geoId, ocd: `ocd-division/country:us/state:in/county:${t.ocd}/council_district:${n}`,
                  name: `${t.body} District ${n}`, county: t.county, district: n });
    }
  }
  const existing = await q(`SELECT geo_id FROM essentials.geofence_boundaries WHERE mtfcc = $1 AND geo_id = ANY($2)`,
                           [MTFCC, rows.map((r) => r.geo_id)]);
  console.log(`  ${rows.length} boundaries: ` + rows.map((r) => r.geo_id).join(', '));
  console.log(`  already present: ${existing.length}`);

  if (DRY_RUN) { console.log('\nDRY RUN — nothing written.'); client.release(); await pool.end(); return; }

  console.log('\nWriting…');
  let inserted = 0;
  for (const r of rows) {
    const res = await q(
      `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
       SELECT $1, $2, $3, $4, $5, geom, $6, now() FROM w_dist WHERE county = $7 AND district = $8
       ON CONFLICT (geo_id, mtfcc) DO NOTHING RETURNING geo_id`,
      [r.geo_id, r.ocd, r.name, STATE_CODE, MTFCC, SOURCE, r.county, r.district]);
    inserted += res.length;
  }
  console.log(`  inserted ${inserted} boundary row(s)`);
  const [after] = await q(`SELECT count(*)::int n FROM essentials.geofence_boundaries WHERE mtfcc = $1`, [MTFCC]);
  if (after.n !== rows.length) fail(`post-write: ${MTFCC} holds ${after.n} rows, expected ${rows.length}.`);
  console.log(`  ✓ ${MTFCC} holds ${after.n} boundaries`);
  client.release();
  await pool.end();
}

main().catch((e) => fail(e instanceof Error ? e.message : String(e)));
