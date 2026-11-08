// reconcile-la-psc-parishes.mjs — build the Louisiana PSC parish composition from TWO independent
// official statements and refuse to emit one unless they agree.
//
// Why two. The parish composition is the only gate that can catch two districts' geometries being
// swapped (CC_0369's control C, CC_0370's loader control C), so it must not come from the map it
// checks — and, ideally, not from a single page either.
//
//   1. THE BLOCK EQUIVALENCY FILE the Legislature publishes for Act 2 (HB2) of the 2022 First
//      Extraordinary Session: 142,874 rows of `<2020 census block GEOID> <district>`. A parish is
//      WHOLE in a district when every one of its blocks maps to that district. This is the plan as
//      enacted, at the finest grain there is.
//   2. THE COMMISSION'S OWN DISTRICT PAGES, lpsc.louisiana.gov/District1..5, each of which lists
//      its parishes and marks the divided ones with an asterisk, citing Act 2 by name.
//
// Neither is derived from the other and neither is derived from the shapefile. Where they agree,
// the composition is established; where they disagree, this script stops and says how.
//
// Usage (from backend/):
//   node data/state-exec-2026-results/reconcile-la-psc-parishes.mjs <bef.txt> <out.json>
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const [, , BEF, OUT] = process.argv;
if (!BEF || !OUT) throw new Error('usage: reconcile-la-psc-parishes.mjs <bef.txt> <out.json>');

// ── Statement 2: the commission's own pages, read 2026-11-07. Transcribed verbatim, asterisks and
//    all; the asterisk is the page's own mark for "divided according to precincts".
const LPSC_PAGES = {
  1: 'Jefferson*, Livingston*, Orleans*, Plaquemines, St. Bernard, St. Charles*, St. Helena, St. Tammany, Tangipahoa, Washington',
  2: 'Ascension*, Assumption*, East Baton Rouge*, East Feliciana, Iberville*, Lafayette, Lafourche, Livingston*, Pointe Coupee, St. Martin*, Terrebonne, West Baton Rouge*, West Feliciana',
  3: 'Ascension*, Assumption*, East Baton Rouge*, Iberville*, Jefferson*, Orleans*, St. Charles*, St. James, St. John Baptist, West Baton Rouge*',
  4: 'Acadia, Allen, Avoyelles, Beauregard, Calcasieu, Cameron, Evangeline, Grant, Iberia, Jefferson Davis, LaSalle, Rapides, St. Landry, St. Martin*, St. Mary, Vermilion, Vernon',
  5: 'Bienville, Bossier, Caddo, Caldwell, Catahoula, Claiborne, Concordia, DeSoto, East Carroll, Franklin, Jackson, Lincoln, Madison, Morehouse, Natchitoches, Ouachita, Red River, Richland, Sabine, Tensas, Union, Webster, West Carroll, Winn',
};

// ── Statement 1: the block equivalency file.
const lines = fs.readFileSync(BEF, 'utf8').split(/\r?\n/).filter(Boolean);
if (lines.length < 100_000) throw new Error(`the block file holds only ${lines.length} rows — too few to be Louisiana`);
const byParish = new Map();
for (const l of lines) {
  const m = l.match(/^(\d{15})\s+(\d+)\s*$/);
  if (!m) throw new Error(`block file: cannot read ${JSON.stringify(l)}`);
  const [, geoid, d] = m;
  if (!geoid.startsWith('22')) throw new Error(`block file: ${geoid} is not in Louisiana`);
  const fips = geoid.slice(2, 5);
  const n = Number(d);
  if (!(n >= 1 && n <= 5)) throw new Error(`block file: district ${d}`);
  if (!byParish.has(fips)) byParish.set(fips, new Map());
  const mm = byParish.get(fips);
  mm.set(n, (mm.get(n) || 0) + 1);
}
if (byParish.size !== 64) throw new Error(`the block file covers ${byParish.size} parishes, and Louisiana has 64`);

// ── The parish names and FIPS production holds, so the output keys match what the gate will join on.
const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();
const { rows: parishes } = await client.query(
  `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE state='22' AND mtfcc='G4020' ORDER BY name`);
await client.end();
if (parishes.length !== 64) throw new Error(`production holds ${parishes.length} Louisiana parish polygons, expected 64`);

const byFips = new Map(parishes.map(p => [p.geo_id.slice(2), p.name]));
// Two names the commission spells differently from TIGER: "St. John Baptist" for "St. John the
// Baptist", and "DeSoto" for "De Soto". Everything else matches once " Parish" is appended. Any
// third difference stops this script rather than being quietly absorbed.
const ALIAS = {
  'St. John Baptist': 'St. John the Baptist Parish',
  DeSoto: 'De Soto Parish',
};
const toTiger = s => ALIAS[s] || `${s} Parish`;
const tigerNames = new Set(parishes.map(p => p.name));

// ── Fold statement 2 into the same shape.
const pageAssign = new Map(); // tiger name -> {districts:Set, starred:Set}
for (const [d, csv] of Object.entries(LPSC_PAGES)) {
  for (const raw of csv.split(',').map(s => s.trim()).filter(Boolean)) {
    const starred = raw.endsWith('*');
    const name = toTiger(starred ? raw.slice(0, -1).trim() : raw);
    if (!tigerNames.has(name)) throw new Error(`the commission names "${raw}", which is not a parish we hold (tried "${name}")`);
    if (!pageAssign.has(name)) pageAssign.set(name, { districts: new Set(), starred: new Set() });
    const e = pageAssign.get(name);
    e.districts.add(Number(d));
    if (starred) e.starred.add(Number(d));
  }
}
if (pageAssign.size !== 64) throw new Error(`the commission's five pages name ${pageAssign.size} parishes, expected 64`);

// ── Compare, parish by parish.
const whole = [], split = [], disagreements = [];
for (const [fips, mm] of [...byParish.entries()].sort()) {
  const name = byFips.get(fips);
  if (!name) throw new Error(`the block file names parish FIPS 22${fips}, which production does not hold`);
  const befDs = [...mm.keys()].sort((a, b) => a - b);
  const page = pageAssign.get(name);
  if (!page) throw new Error(`no commission page names ${name}`);
  const pageDs = [...page.districts].sort((a, b) => a - b);

  if (befDs.join(',') !== pageDs.join(',')) {
    disagreements.push(`${name}: the block file says ${befDs.join('/')}, the commission's pages say ${pageDs.join('/')}`);
    continue;
  }
  // and the asterisk must mean what it says
  const befSplit = befDs.length > 1;
  const pageSplit = page.starred.size > 0;
  if (befSplit !== pageSplit) {
    disagreements.push(`${name}: the block file says ${befSplit ? 'split' : 'whole'}, the commission ${pageSplit ? 'stars it' : 'does not star it'}`);
    continue;
  }
  if (befSplit && page.starred.size !== pageDs.length) {
    disagreements.push(`${name}: the commission stars it in ${page.starred.size} of its ${pageDs.length} districts`);
    continue;
  }
  if (befSplit) split.push({ parish: name, fips, districts: befDs, blocks: befDs.map(d => mm.get(d)) });
  else whole.push({ parish: name, fips, district: befDs[0], blocks: mm.get(befDs[0]) });
}

console.log(`block file: 142,874 rows → 64 parishes; commission pages: 64 parishes`);
console.log(`WHOLE ${whole.length} · SPLIT ${split.length}`);
for (const s of split) console.log(`   ${s.parish.padEnd(26)} ${s.districts.join('/')}  (blocks ${s.blocks.join('/')})`);
if (disagreements.length) {
  console.error(`\n🔴 THE TWO STATEMENTS DISAGREE on ${disagreements.length} parish(es):`);
  for (const d of disagreements) console.error('   ' + d);
  process.exit(1);
}
if (whole.length + split.length !== 64) throw new Error(`${whole.length + split.length} parishes classified, expected 64`);
console.log('🟢 the block equivalency file and the commission\'s own district pages agree on all 64 parishes');

fs.writeFileSync(OUT, JSON.stringify({
  measured: '2026-11-07',
  plan: 'Act 2 (HB2) of the 2022 First Extraordinary Session — the Louisiana PSC districts in force',
  statement1: 'Legislature block equivalency file, PSC - Act 2 (HB2) 1st ES (2022).txt, 142,874 blocks',
  statement2: 'lpsc.louisiana.gov/District1..5, "Commission District Geographical Area", read 2026-11-07',
  note: 'A parish is WHOLE where every one of its 2020 census blocks maps to one district AND the commission does not star it. The two statements are independent of each other and of the map they are used to check.',
  whole, split,
}, null, 1));
console.log(`wrote ${OUT}`);
