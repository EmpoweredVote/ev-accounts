#!/usr/bin/env node
/**
 * load-wayne-commission-boundaries.mjs — Knight program, wave MI-4.
 *
 * Fetches Wayne County's fifteen commission-district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='wayne-county-mi-commission-district-1'..'-15',
 *                                   mtfcc='X0066'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0142 creates the districts and their offices
 * and REFUSES TO RUN if these fifteen boundaries are absent — an office on a district with no
 * polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE COUNTY'S OWN LIVE FEATURE SERVICE IS THE SUPERSEDED MAP, AND ITS STATIC ZIP IS THE
 * CURRENT ONE. Wayne publishes four commission-district layers, which are two maps:
 *
 *   waynecountymi.gov  county_commission_districts.zip        PlanID 1566   <- CURRENT (authority)
 *   services1/7k5pwykhBf04bSfy (Eastern Michigan University)  PlanID 1566   <- identical, 2nd host
 *   services1/b6rkZNtCd6Mx2gvB (THE COUNTY'S OWN ArcGIS)      2012 plan     <- SUPERSEDED
 *   services2/HsXtOCMp1Nis1Ogr (Data Driven Detroit)          2012 plan     <- the control
 *
 * The county's own service and Data Driven Detroit's 2012 layer are byte-identical on all
 * fifteen districts (0.0000% area difference), and that service still names Jewel Ware, Ilona
 * Varga, Burton Leland, Gary Woronchak and Raymond Basham in its `Commission` field — people who
 * left the Commission years ago. It is owned by `kspivey_wayne`, the same county GIS user named
 * in the static zip's own metadata path, and ArcGIS reports it modified 2023-01-04, one day
 * AFTER the current zip was exported.
 * ▶ MI-3 reached for a live feature service in preference to a file. Here that rule loads the
 *   wrong Wayne. FRESHNESS IS A PROPERTY OF A FIELD, NOT OF A SOURCE — MI-2's SD-35 lesson,
 *   which was about occupancy, applies to geometry too.
 *
 * 🟢 SO THE VINTAGE IS PROVED FROM THE DATA, NOT FROM THE HOST. The Wayne County Apportionment
 * Commission adopted its plan on 2021-11-10 (resolution certified for that meeting, 5-0), and
 * the adopted "Staff Plan 2021" states a population for each of the fifteen districts. GATE 2
 * requires the loaded layer to reproduce all fifteen EXACTLY. It does, 15/15 — along with the
 * plan's stated total (1,793,411), ideal (119,561) and total deviation (9.48).
 * ⚠ THE LAYER'S TITLE DISAGREES WITH THE RESOLUTION AND THAT IS NOT A DEFECT. The shapefile is
 * titled "Kinloch Proposal with Sabree Edits" while the resolution adopts "the attached Staff
 * apportionment plan" — staff built the adopted plan from the Kinloch proposal with the chair's
 * edits. Names could not settle this; the fifteen numbers did.
 * ⚠ AND THE FILE'S OWN DATE IS NOT THE DATA'S DATE. The zip's members are stamped 2023-01-03,
 * but its ESRI lineage carries CreaDate 20211110 — the adoption date — and records the
 * 2023-01-03 step as an ExportFeatures re-export. A count cannot date a map; neither can a
 * timestamp on the container.
 * ⚠ The resolution PDF is a SCAN with an empty text layer. It had to be read as an image.
 *
 * 🔴 CLOSURE IS 95.963%, AND DETROIT'S BAND WOULD FAIL HERE. The fifteen districts cover
 * 645.2464 sq mi of TIGER county 26163's 672.3911. The deficit is water, proved rather than
 * assumed: the census gazetteer puts Wayne's land at 611.8390 sq mi and its water at 60.9070,
 * and GATE 6 locates all 627 Wayne tract internal points — 626 land in exactly one district and
 * the single miss is tract 26163990100, which has ALAND = 0 and 26.757 sq mi of Lake St. Clair.
 * MI-3 gated Detroit at 96.0–100.5% and that would REJECT correct Wayne data.
 * ▶ A CLOSURE THRESHOLD IS NOT PORTABLE. Fourth time in this programme.
 *
 * ⚠ waynecountymi.gov REFUSES A HALF-IMPERSONATION, AND THE RULE IS ABOUT THE CLIENT, NOT THE URL.
 * Measured 2026-09-25, on both a CMS page and this static zip:
 *     curl bare                  -> 200      curl -A '<Chrome UA>'      -> 403
 *     curl with full Chrome hdrs  -> 403      node fetch with a UA       -> 200
 * So a User-Agent is not a key here; pinning one onto curl is what gets refused, because the UA
 * then disagrees with the TLS fingerprint underneath it. michigan.gov at MI-1 was the opposite
 * way round, which is why neither behaviour can be assumed.
 * ▶ THE FIRST VERSION OF THIS COMMENT SAID "a browser User-Agent is refused", FULL STOP, AND THE
 *   CONTROL BELOW FAILED AND DISPROVED IT — node's fetch sends one and is served. A control is
 *   worth writing even when you are only documenting something.
 * This script therefore sends no User-Agent to the county and a browser one to ArcGIS, and
 * --wafcontrol asserts the only thing that must hold at runtime: the authority is reachable and
 * arrives whole.
 *
 *   node scripts/load-wayne-commission-boundaries.mjs --dry-run
 *   node scripts/load-wayne-commission-boundaries.mjs
 *   node scripts/load-wayne-commission-boundaries.mjs --control=N   (N=1..6, must FAIL)
 *   node scripts/load-wayne-commission-boundaries.mjs --wafcontrol  (proves the UA finding)
 */
import pg from 'pg';
import fs from 'fs';
import os from 'os';
import path from 'path';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';
import * as dotenv from 'dotenv';
dotenv.config();

const BROWSER = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0' };

// The authority: the county's own GIS Data page. Sent BARE — a User-Agent gets 403 here.
const ZIP_URL =
  'https://www.waynecountymi.gov/files/assets/mainsite/v/1/information-technology/' +
  'maps-amp-data/documents/county_commission_districts.zip';
// Second publisher of the SAME plan, used for agreement only.
const MIRROR =
  'https://services1.arcgis.com/7k5pwykhBf04bSfy/arcgis/rest/services/' +
  'Wayne_County_Commission_Districts_/FeatureServer/0';
// The county's OWN live service — the SUPERSEDED 2012 map. The control, not a source.
const SUPERSEDED =
  'https://services1.arcgis.com/b6rkZNtCd6Mx2gvB/arcgis/rest/services/' +
  'County_Commission_Districts/FeatureServer/0';

const GAZ_URL =
  'https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_tracts_national.zip';
const GAZ_DIR = 'data/seed-mi-2026/_authority';       // provisioned by MI-1
const GAZ_FILE = '2020_Gaz_tracts_national.txt';

const MTFCC = 'X0066';
const EXPECTED = 15;
const COUNTY_GEO_ID = '26163';
const COUNTY_MTFCC = 'G4020';
const STATE_FIPS = '26';
const PLAN_ID = 1566;

// The adopted Wayne County Apportionment Commission Staff Plan 2021, Population Table, Section 2.
// These fifteen numbers ARE the vintage test: the 2011 plan is built on the 2010 census and its
// districts cannot reproduce them.
const ADOPTED_POP = {
  1: 123596, 2: 116654, 3: 123978, 4: 120512, 5: 125741,
  6: 122909, 7: 124080, 8: 116760, 9: 116957, 10: 114816,
  11: 114403, 12: 119700, 13: 118274, 14: 117797, 15: 117234,
};
const ADOPTED_TOTAL = 1793411; // the plan states this, "not including 150 people housed in two
                               // blocks that are detention centers according to the State of Michigan"
const ADOPTED_IDEAL = 119561;
const ADOPTED_DEVIATION = 9.48;

// Coverage bound, MEASURED 2026-09-25 at 95.963%. The deficit is Lake St. Clair and the Detroit
// River, not a hole in the map, so the window is set around the measurement.
const COVER_MIN = 0.95;
const COVER_MAX = 1.005;

const SOURCE =
  'Wayne County GIS Data, county_commission_districts.zip (waynecountymi.gov); PlanID 1566, ' +
  'titled "Kinloch Proposal with Sabree Edits", which is the Staff apportionment plan adopted ' +
  'by the Wayne County Apportionment Commission 5-0 on 2021-11-10 under Home Rule Charter ' +
  'Sec. 2.111-2.115 and first used at the 2022 election — identified by reproducing all 15 of ' +
  'the adopted plan\'s district populations exactly, not by its title; ESRI lineage CreaDate ' +
  '20211110; byte-identical to the copy served by services1.arcgis.com/7k5pwykhBf04bSfy, and ' +
  'materially different from the county\'s own superseded 2012 service; read 2026-09-25 (MI-4)';

const ARG = process.argv.slice(2);
const DRY = ARG.includes('--dry-run');
const WAFCONTROL = ARG.includes('--wafcontrol');
const CONTROL = Number((ARG.find((a) => a.startsWith('--control=')) || '').split('=')[1] || 0);

const fail = (m) => { console.error(`\n🔴 ${m}\n`); process.exit(1); };
const ok = (m) => console.log(`  ${m}`);

const ringA = (r) => { let s = 0; for (let i = 0, j = r.length - 1; i < r.length; j = i++) s += r[j][0] * r[i][1] - r[i][0] * r[j][1]; return Math.abs(s / 2); };
const polys = (g) => (g.type === 'Polygon' ? [g.coordinates] : g.coordinates);
const areaOf = (g) => { let a = 0; for (const p of polys(g)) { a += ringA(p[0]); for (let k = 1; k < p.length; k++) a -= ringA(p[k]); } return a; };
const vertsOf = (g) => { let n = 0; for (const p of polys(g)) for (const r of p) n += r.length; return n; };

async function arcgis(url) {
  const r = await fetch(`${url}/query?where=1%3D1&outFields=*&outSR=4326&f=geojson`, { headers: BROWSER });
  if (!r.ok) fail(`${url} -> HTTP ${r.status}`);
  const j = await r.json();
  if (j.exceededTransferLimit === true) fail(`${url} paged — a truncated layer must never be loaded`);
  return j.features || [];
}

/** The county's zip, read as a shapefile. Sent BARE: a User-Agent is 403ed here. */
async function countyZip() {
  const r = await fetch(ZIP_URL);
  if (!r.ok) fail(`the county zip -> HTTP ${r.status}`);
  const buf = Buffer.from(await r.arrayBuffer());
  // ⚠ A clean 200 can carry a truncated body. Refuse anything that is not a whole zip.
  if (buf.length < 50_000) fail(`the county zip is ${buf.length} bytes — too small to be whole`);
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'wayne-cc-'));
  new AdmZip(buf).extractAllTo(dir, true);
  const shp = [];
  const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) walk(p); else if (p.endsWith('.shp')) shp.push(p);
  } };
  walk(dir);
  if (shp.length !== 1) fail(`expected exactly one .shp in the county zip, found ${shp.length}`);
  const out = [];
  const src = await shapefile.open(shp[0], shp[0].replace(/\.shp$/, '.dbf'));
  for (let rec = await src.read(); !rec.done; rec = await src.read()) out.push(rec.value);
  return out;
}

const numOf = (p) => parseInt(String(p.Dis_Number ?? p.District_N ?? String(p.District ?? '').replace(/\D/g, '')), 10);

console.log(`\nMI-4 — Wayne County commission district boundaries -> ${MTFCC}`);
if (CONTROL) console.log(`🧪 CONTROL ${CONTROL} ACTIVE — this run MUST FAIL.\n`);

// ── the WAF finding, proved on demand ────────────────────────────────────────
if (WAFCONTROL) {
  const bare = await fetch(ZIP_URL);
  const bytes = bare.ok ? Buffer.from(await bare.arrayBuffer()) : Buffer.alloc(0);
  const isZip = bytes.length > 4 && bytes[0] === 0x50 && bytes[1] === 0x4b;
  let shp = 0;
  if (isZip) shp = new AdmZip(bytes).getEntries().filter((e) => e.entryName.endsWith('.shp')).length;
  console.log(`  bare request -> HTTP ${bare.status}, ${bytes.length} bytes, zip=${isZip}, .shp members=${shp}`);
  if (!bare.ok) fail('WAF CONTROL: the county refused a bare request. Re-measure before trusting this loader.');
  if (!isZip || shp !== 1) fail(`WAF CONTROL: a 200 arrived but it is not one whole shapefile (zip=${isZip}, shp=${shp}). A clean 200 can carry a truncated or substituted body.`);
  console.log('\n✅ The authority is reachable bare and arrives whole.\n');
  await new Promise((r) => setTimeout(r, 50));
  process.exit(0);
}

let live = await countyZip();
let mirror = await arcgis(MIRROR);
const old2012 = await arcgis(SUPERSEDED);

// Controls. Each MOVES or RETITLES rather than adding or removing, so it cannot be caught by an
// earlier gate's quantity check — MI-2's gate-3 lesson, which MI-3 hit for the third time.
if (CONTROL === 1) live = live.slice(0, 14);                                        // wrong count
if (CONTROL === 2) live = live.map((f, i) => (i === 0 ? { ...f, properties: { ...f.properties, TotalPop: ADOPTED_POP[1] + 1 } } : f)); // one population off by one
if (CONTROL === 3) live = live.map((f) => ({ ...f, properties: { ...f.properties, PlanID: 1565 } }));  // a different plan id
if (CONTROL === 4) mirror = old2012;                                                 // the second publisher is stale
// ⚠ CONTROL 5 TOOK TWO ATTEMPTS AND BOTH WRONG ONES LOOKED REASONABLE.
//   `live = old2012`          -> GATE 2 rejects it (the 2012 layer has no TotalPop). 3b unreached.
//   swap only live's geometry -> GATE 3a rejects it (it stops matching the mirror). 3b unreached.
// GATE 3b only fires when the loaded map and its second publisher AGREE with each other and are
// both the superseded map. So the control has to move BOTH, keeping the adopted plan's properties
// so GATE 2 still passes. MI-3's gate-3 shadowing lesson, third occurrence, caught by running it.
if (CONTROL === 5) {
  const O = new Map(old2012.map((f) => [numOf(f.properties), f.geometry]));
  const swap = (fs_) => fs_.map((f) => ({ ...f, geometry: O.get(numOf(f.properties)) ?? f.geometry }));
  live = swap(live);
  mirror = swap(mirror);
}
// CONTROL 8 gives D2 D1's polygon, in BOTH the layer and its mirror so GATE 3a stays quiet, and
// leaves every property untouched so GATES 1-2 do. The two districts then coincide exactly and
// only GATE 4 can speak. (Moving one side only would trip 3a, as control 5 taught.)
if (CONTROL === 8) {
  const dupe = (fs_) => { const g1 = fs_.find((f) => numOf(f.properties) === 1).geometry;
    return fs_.map((f) => (numOf(f.properties) === 2 ? { ...f, geometry: g1 } : f)); };
  live = dupe(live);
  mirror = dupe(mirror);
}

// ── GATE 1: the shape of the layer ───────────────────────────────────────────
if (live.length !== EXPECTED) fail(`GATE 1: expected ${EXPECTED} features, got ${live.length}`);
const nums = live.map((f) => numOf(f.properties)).sort((a, b) => a - b);
const want = Array.from({ length: EXPECTED }, (_, i) => i + 1);
if (nums.join(',') !== want.join(',')) fail(`GATE 1: districts are not 1..${EXPECTED} exactly — got ${nums.join(',')}`);
ok(`GATE 1 PASSED: districts ${nums.join(',')}`);

// ── GATE 2: the layer IS the adopted plan, by its own numbers ────────────────
// The only test that separates the 2021 plan from the 2011 one without trusting a host, a title
// or a file date. A count of 15 is true of both plans.
{
  const bad = [];
  let total = 0;
  for (const f of live) {
    const d = numOf(f.properties);
    const pid = Number(f.properties.PlanID);
    const pop = Number(f.properties.TotalPop);
    total += Number.isFinite(pop) ? pop : 0;
    if (pid !== PLAN_ID) bad.push(`D${d} PlanID ${pid} (adopted plan is ${PLAN_ID})`);
    if (pop !== ADOPTED_POP[d]) bad.push(`D${d} population ${pop}, the adopted Staff Plan 2021 says ${ADOPTED_POP[d]}`);
  }
  if (bad.length) fail(`GATE 2: this is not the adopted plan —\n    ${bad.join('\n    ')}`);
  if (total !== ADOPTED_TOTAL) fail(`GATE 2: populations total ${total}, the adopted plan states ${ADOPTED_TOTAL}`);
  const ideal = Math.round(total / EXPECTED);
  const pops = live.map((f) => Number(f.properties.TotalPop));
  const dev = Number((((Math.max(...pops) - Math.min(...pops)) / (total / EXPECTED)) * 100).toFixed(2));
  if (ideal !== ADOPTED_IDEAL) fail(`GATE 2: ideal population ${ideal}, the adopted plan states ${ADOPTED_IDEAL}`);
  if (Math.abs(dev - ADOPTED_DEVIATION) > 0.01) fail(`GATE 2: total deviation ${dev}, the adopted plan states ${ADOPTED_DEVIATION}`);
  ok(`GATE 2 PASSED: PlanID ${PLAN_ID}, all ${EXPECTED} populations match the adopted Staff Plan 2021, total ${total}, ideal ${ideal}, deviation ${dev}`);
}

// ── GATE 3: two publishers, one map — and it is NOT the county's own service ─
{
  const byNum = (fs_) => new Map(fs_.map((f) => [numOf(f.properties), f.geometry]));
  const L = byNum(live), M = byNum(mirror), O = byNum(old2012);
  const mismatch = [];
  for (const [d, g] of L) {
    const m = M.get(d);
    if (!m) { mismatch.push(`D${d} missing from the second publisher`); continue; }
    const rel = Math.abs(areaOf(g) - areaOf(m)) / areaOf(g);
    if (rel > 1e-9 || vertsOf(g) !== vertsOf(m)) mismatch.push(`D${d} differs from the second publisher (rel ${rel.toExponential(2)}, verts ${vertsOf(g)} vs ${vertsOf(m)})`);
  }
  if (mismatch.length) fail(`GATE 3a: the county zip and the second publisher are not the same map —\n    ${mismatch.join('\n    ')}`);
  let changed = 0;
  for (const [d, g] of L) { const o = O.get(d); if (o && Math.abs(areaOf(g) - areaOf(o)) / areaOf(g) > 0.005) changed++; }
  if (changed !== EXPECTED) {
    fail(`GATE 3b: ${changed} of ${EXPECTED} districts differ from the county's own live service. ` +
         `All fifteen must: that service carries the SUPERSEDED 2012 plan, and anything less means ` +
         `this is the 2012 map, or the county has republished and the finding needs re-reading.`);
  }
  ok(`GATE 3 PASSED: the second publisher matches on all ${EXPECTED}, and all ${EXPECTED} differ from the county's own superseded service`);
}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

// 🔴 X CODES HAVE NO USABLE ALLOCATOR. `steward slot X` exists and works, but its X sequence is
// UNSEEDED: it returned X_0001 while production's X0001 already held 207 rows, and that
// reservation was abandoned with its reason. So this code is read from prod's max IN THE SAME
// SESSION as the write, and the gate below refuses if anything already occupies it.
{
  const { rows } = await client.query(`SELECT max(mtfcc) AS mx FROM essentials.geofence_boundaries WHERE mtfcc ~ '^X[0-9]{4}$'`);
  const taken = await client.query('SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1', [MTFCC]);
  console.log(`  X-code check: prod max is ${rows[0].mx}, this wave takes ${MTFCC}, currently holding ${taken.rows[0].n} row(s)`);
  if (taken.rows[0].n > 0 && taken.rows[0].n !== EXPECTED) fail(`${MTFCC} already holds ${taken.rows[0].n} row(s) that are not this wave's ${EXPECTED} — pick the next free code`);
  if (rows[0].mx >= MTFCC && taken.rows[0].n === 0) fail(`prod max X code is ${rows[0].mx}, so ${MTFCC} is not free — another wave took it since this script was written`);
}

const geoms = live.map((f) => ({ d: numOf(f.properties), gj: JSON.stringify(f.geometry) }));

// ── GATE 4: no two districts overlap ─────────────────────────────────────────
const ovl = await client.query(
  `WITH g AS (SELECT d, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj),4326)) AS geom
                FROM unnest($1::int[], $2::text[]) AS t(d, gj))
   SELECT count(*)::int AS pairs FROM g a JOIN g b ON a.d < b.d
    WHERE ST_Area(ST_Intersection(a.geom,b.geom)::geography) > 1000`,
  [geoms.map((x) => x.d), geoms.map((x) => x.gj)]
);
if (ovl.rows[0].pairs > 0) fail(`GATE 4: ${ovl.rows[0].pairs} pair(s) of districts overlap by more than 1000 m² — is this one map?`);
ok('GATE 4 PASSED: no two districts overlap');

// ── GATE 5: coverage of the county, inside the MEASURED band ─────────────────
const cov = await client.query(
  `WITH g AS (SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj),4326))) AS u
                FROM unnest($1::text[]) AS t(gj)),
        c AS (SELECT geometry AS geom FROM essentials.geofence_boundaries
               WHERE mtfcc=$2 AND geo_id=$3)
   SELECT ST_Area(g.u::geography)/ST_Area(c.geom::geography) AS ratio,
          ST_Area(g.u::geography)/2589988.110336 AS districts_sq_mi,
          ST_Area(ST_Difference(c.geom, g.u)::geography)/2589988.110336 AS uncovered_sq_mi,
          ST_Area(ST_Difference(g.u, c.geom)::geography)/2589988.110336 AS outside_sq_mi
     FROM g, c`,
  [geoms.map((x) => x.gj), COUNTY_MTFCC, COUNTY_GEO_ID]
);
const { ratio, districts_sq_mi, uncovered_sq_mi, outside_sq_mi } = cov.rows[0];
const r = Number(ratio);
console.log(`  coverage: ${(r * 100).toFixed(3)}% of TIGER county ${COUNTY_GEO_ID} — ${Number(districts_sq_mi).toFixed(4)} sq mi of ${Number(districts_sq_mi) / r ? (Number(districts_sq_mi) / r).toFixed(4) : '?'}; ${Number(uncovered_sq_mi).toFixed(4)} uncovered, ${Number(outside_sq_mi).toFixed(4)} outside`);
if (CONTROL === 6 || r < COVER_MIN || r > COVER_MAX) {
  fail(`GATE 5: coverage ${(r * 100).toFixed(3)}% is outside the measured band ${(COVER_MIN * 100).toFixed(1)}%–${(COVER_MAX * 100).toFixed(1)}%. ` +
       `The expected value is ~95.96%: the districts tile Wayne's LAND while TIGER's county polygon includes Lake St. Clair and the Detroit River. ` +
       `Detroit's 96.0% floor at MI-3 would reject this correct data.`);
}
ok(`GATE 5 PASSED: coverage ${(r * 100).toFixed(3)}% inside the measured band`);

// ── GATE 6: every acre of LAND is in exactly one district ────────────────────
// Coverage against a water-bearing county polygon cannot tell a lawful water gap from a hole
// where people live. The census tract internal points are on land, so they can.
{
  const gazPath = path.join(GAZ_DIR, GAZ_FILE);
  if (!fs.existsSync(gazPath)) {
    console.log('  fetching the 2020 tract gazetteer (MI-1 normally leaves it cached)');
    const rz = await fetch(GAZ_URL, { headers: BROWSER });
    if (!rz.ok) fail(`gazetteer -> HTTP ${rz.status}`);
    fs.mkdirSync(GAZ_DIR, { recursive: true });
    new AdmZip(Buffer.from(await rz.arrayBuffer())).extractAllTo(GAZ_DIR, true);
  }
  const pts = [];
  for (const line of fs.readFileSync(gazPath, 'utf8').split(/\r?\n/).slice(1)) {
    const c = line.split('\t');
    if (c.length < 8 || !c[1].startsWith(COUNTY_GEO_ID)) continue;
    pts.push({ id: c[1], land: Number(c[4]), lon: Number(c[7]), lat: Number(c[6]) });
  }
  if (pts.length < 600) fail(`GATE 6: only ${pts.length} Wayne tract points read — the gazetteer is not whole`);
  // CONTROL 7 plants a land-bearing point outside every district. It touches no geometry, so
  // GATES 1-5 keep their exact values and only GATE 6's "unreachable residents" branch can fire.
  if (CONTROL === 7) pts.push({ id: 'CTRL-GRAND-RAPIDS', land: 1, lon: -85.6681, lat: 42.9634 });
  const hit = await client.query(
    `WITH g AS (SELECT d, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj),4326)) AS geom
                  FROM unnest($1::int[], $2::text[]) AS t(d,gj)),
          p AS (SELECT id, ST_SetSRID(ST_MakePoint(lon,lat),4326) AS pt
                  FROM unnest($3::text[], $4::float8[], $5::float8[]) AS t(id,lon,lat))
     SELECT p.id, count(g.d)::int AS hits, min(g.d) AS district
       FROM p LEFT JOIN g ON ST_Contains(g.geom, p.pt) GROUP BY p.id`,
    [geoms.map((x) => x.d), geoms.map((x) => x.gj), pts.map((p) => p.id), pts.map((p) => p.lon), pts.map((p) => p.lat)]
  );
  const land = new Map(pts.map((p) => [p.id, p.land]));
  const strayLand = hit.rows.filter((x) => x.hits === 0 && land.get(x.id) > 0).map((x) => x.id);
  const doubled = hit.rows.filter((x) => x.hits > 1).map((x) => x.id);
  const waterOut = hit.rows.filter((x) => x.hits === 0 && !(land.get(x.id) > 0)).map((x) => x.id);
  if (strayLand.length) fail(`GATE 6: ${strayLand.length} tract(s) WITH LAND fall in no district — residents there are unreachable: ${strayLand.join(', ')}`);
  if (doubled.length) fail(`GATE 6: ${doubled.length} tract(s) fall in more than one district: ${doubled.join(', ')}`);
  const per = new Map();
  for (const x of hit.rows) if (x.hits === 1) per.set(x.district, (per.get(x.district) ?? 0) + 1);
  const empty = want.filter((d) => !per.get(d));
  if (empty.length) fail(`GATE 6: district(s) ${empty.join(', ')} contain no tract internal point`);
  ok(`GATE 6 PASSED: ${hit.rows.length - waterOut.length} of ${hit.rows.length} tract points in exactly one district; ` +
     `the ${waterOut.length} outside are water-only tracts (${waterOut.join(', ')}); all ${EXPECTED} districts populated`);
}

if (DRY) { console.log('\nDRY RUN — nothing written.\n'); await client.end(); process.exit(0); }

// ── write ────────────────────────────────────────────────────────────────────
let inserted = 0, existed = 0;
for (const f of live) {
  const d = numOf(f.properties);
  const geoId = `wayne-county-mi-commission-district-${d}`;
  const res = await client.query(
    `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
     SELECT $1::text, $2::text, $3::text, $4::text, $5::text,
            ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($6::text),4326)), $7::text, now()
      WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id=$1::text AND mtfcc=$5::text)`,
    [geoId, `ocd-division/country:us/state:mi/county:wayne/council_district:${d}`,
     `Wayne County Commission District ${d}`, STATE_FIPS, MTFCC, JSON.stringify(f.geometry), SOURCE]
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
console.log(`  post-write: ${a.n} rows, 0 invalid, 0 wrong SRID\n✅ MI-4 boundaries loaded as ${MTFCC}.\n`);
await client.end();
