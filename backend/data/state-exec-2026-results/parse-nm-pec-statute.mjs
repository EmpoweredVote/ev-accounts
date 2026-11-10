// parse-nm-pec-statute.mjs — derive the county composition of New Mexico's ten Public Education
// Commission districts from the ENACTED statute, for the gate in CC_0372-nm-pec-geofences.mjs.
//
// 🔴 THE FIRST BILL I READ WAS NOT THE LAW. The 2021 Second Special Session filed two PEC
//    redistricting bills — HB 6 and HB 7 — and **both died**; HB 6's status line reads "Action
//    Postponed Indefinitely". The act in force is **HB 9, Laws 2021 (2nd S.S.), Chapter 3**,
//    signed 17 December 2021 ("PASSED/H (61-0) … PASSED/S (25-13) … SGND BY GOV (Dec. 17) Ch. 3").
//    Its precinct lists are NOT the same as HB 6's. A bill page is not evidence that a bill
//    became law: read the action line.
//      https://www.nmlegis.gov/Sessions/21%20Special2/final/HB0009.PDF
//      (37,233 bytes, sha256 58aaf6a75b2ec6e8b694dd1f875759f6c442cc5c1a868c00367164db9993944a,
//       downloaded 2026-11-07; text extracted with `pdftotext -layout`)
//
// HOW A COUNTY IS CLASSIFIED — 🟢 THE STATUTE SAYS IT OUTRIGHT, which is better than inferring
// it. Sections 6 to 15 define districts 1 to 10 as semicolon-separated clauses of two shapes:
//     "Catron county;"                       → the WHOLE county is in this district
//     "Cibola county precincts 1, 7 and 15;" → only those precincts are
// So a district's clause list distinguishes whole from partial by itself. The script then
// CROSS-CHECKS that against the other thing the text implies — the ten districts partition the
// state, so a whole county must appear in exactly one district and a partial county in two or
// more — and stops if the two readings ever disagree. It also refuses to emit unless the
// counties it finds are exactly the 33 New Mexico holds.
// ⚠ An earlier version matched only "<county> county precincts" and found 10 counties instead
//   of 33, because every WHOLE county is written without the word "precincts". A predicate reads
//   the shape of a value; read real rows before trusting what it caught.
//
// Usage (from backend/):
//   node data/state-exec-2026-results/parse-nm-pec-statute.mjs <hb9.txt> <out.json>
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const [, , SRC, OUT] = process.argv;
if (!SRC || !OUT) throw new Error('usage: parse-nm-pec-statute.mjs <hb9.txt> <out.json>');

const raw = fs.readFileSync(SRC, 'utf8');
// The extracted text runs about 11.5 KB; this only catches an empty or truncated file. The
// real guards are below: all twelve section marks, and exactly the 33 counties production holds.
if (raw.length < 8_000) throw new Error(`${SRC} is only ${raw.length} bytes — too short to be HB 9`);
// strip the running footer and the line numbers pdftotext leaves at the start of each line
const flat = raw.split(/\r?\n/)
  .map(l => l.replace(/HFL\/HSEIC\/HB 9\s*$/, '').replace(/^\s*\d+\s/, ' '))
  .filter(l => !/^\s*Page \d+\s*$/.test(l))
  .join(' ').replace(/\s+/g, ' ');

const WORDS = ['ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE', 'TEN'];
const marks = [];
for (let s = 6; s <= 17; s++) {
  const i = flat.indexOf(`SECTION ${s}. `);
  if (i < 0) throw new Error(`SECTION ${s}. not found`);
  marks.push(i);
}

const mentions = new Map(); // county -> Map(district -> 'whole' | 'partial')
const perDistrict = {};
for (let d = 1; d <= 10; d++) {
  const body = flat.slice(marks[d - 1], marks[d]);
  const head = `district ${WORDS[d - 1].toLowerCase()} is composed of `;
  const j = body.indexOf(head);
  if (j < 0) throw new Error(`D${d}: cannot find "${head}" — the statute's wording changed`);
  const text = body.slice(j + head.length).trim();
  const found = [...text.matchAll(/([A-Z][a-zA-Z]+(?: [A-Z][a-zA-Z]+)?) county/g)].map(m => ({
    county: m[1],
    // "X county precincts 1, 7 and 15" is partial; a bare "X county" is the whole of it.
    // ⚠ SINGULAR TOO: District 5 takes "Bernalillo county precinct 31" — one precinct, no "s".
    //   Matching only "precincts" read that as the whole of Bernalillo.
    kind: /^ precincts? \d/.test(text.slice(m.index + m[0].length)) ? 'partial' : 'whole',
  }));
  const seen = new Map();
  for (const f of found) {
    if (seen.has(f.county) && seen.get(f.county) !== f.kind) {
      throw new Error(`D${d}: ${f.county} county is named both whole and by precinct`);
    }
    seen.set(f.county, f.kind);
  }
  if (!seen.size) throw new Error(`D${d}: no county clause found`);
  perDistrict[d] = [...seen.entries()].map(([c, k]) => `${c}${k === 'partial' ? ' (precincts)' : ''}`);
  for (const [c, k] of seen) {
    if (!mentions.has(c)) mentions.set(c, new Map());
    mentions.get(c).set(d, k);
  }
}

// The names TIGER uses. "Dona Ana" in the statute is "Doña Ana County" in TIGER; everything else
// is "<name> County". A third difference stops this script rather than being absorbed.
const ALIAS = { 'Dona Ana': 'Doña Ana County' };
const toTiger = s => ALIAS[s] || `${s} County`;

const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();
const { rows: counties } = await client.query(
  `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE state='35' AND mtfcc='G4020' ORDER BY name`);
await client.end();
if (counties.length !== 33) throw new Error(`production holds ${counties.length} New Mexico county polygons, expected 33`);
const tigerNames = new Set(counties.map(c => c.name));

const whole = [], split = [];
for (const [c, ds] of [...mentions.entries()].sort()) {
  const name = toTiger(c);
  if (!tigerNames.has(name)) throw new Error(`the statute names "${c} county", which is not a county we hold (tried "${name}")`);
  const list = [...ds.keys()].sort((a, b) => a - b);
  const kinds = [...new Set(ds.values())];
  // 🔴 THE TWO READINGS MUST AGREE. The statute's own wording says whole or partial; the fact
  //    that the ten districts partition the state says a whole county appears once and a partial
  //    one appears twice or more. A county that appears once but is written by precinct would
  //    mean precincts assigned to nobody, and a county written whole in two districts would mean
  //    it is in both. Either is a reading error or a defect in the text, and both stop here.
  if (kinds.length !== 1) throw new Error(`${name} is named whole in one district and by precinct in another`);
  const kind = kinds[0];
  if (kind === 'whole' && list.length !== 1) throw new Error(`${name} is named WHOLE in ${list.length} districts (${list.join('/')})`);
  if (kind === 'partial' && list.length < 2) throw new Error(`${name} is named by precinct in only one district (${list[0]}) — some precincts would be unassigned`);
  if (kind === 'whole') whole.push({ county: name, district: list[0] });
  else split.push({ county: name, districts: list });
}
if (whole.length + split.length !== 33) {
  throw new Error(`the statute names ${whole.length + split.length} counties, and New Mexico has 33`);
}
const named = new Set([...whole.map(w => w.county), ...split.map(s => s.county)]);
const missed = [...tigerNames].filter(n => !named.has(n));
if (missed.length) throw new Error(`the statute names no precinct in: ${missed.join(', ')}`);

// ─── 🟢 A SECOND, INDEPENDENT STATEMENT OF THE SAME COMPOSITION ───
// The Legislative Council Service's own handbook page for the commission lists each district's
// counties in plain English, beside its members. It is not derived from the bill text parsed
// above and not derived from the GIS the loader checks, so it is a real second opinion — the
// same shape as the two-source reconciliation CC_0371 used for Louisiana.
//   https://www.nmlegis.gov/Publications/handbook/public_education_commission_25.pdf
//   (36,975 bytes, downloaded 2026-11-07)
// ⚠ Its "Term Expires" column does not survive text extraction intact and is NOT used; the
//   staggering comes from Section 3 of HB 9, which names the districts by number.
const HANDBOOK = {
  1: 'Bernalillo',
  2: 'Bernalillo',
  3: 'Bernalillo',
  4: 'Bernalillo, Los Alamos, Sandoval, Santa Fe',
  5: 'Bernalillo, Cibola, McKinley, Sandoval, San Juan, Socorro',
  6: 'Bernalillo, Catron, Cibola, Dona Ana, Grant, Hidalgo, Luna, Sierra, Socorro, Torrance, Valencia',
  7: 'Dona Ana, Otero',
  8: 'Chaves, Colfax, Curry, De Baca, Guadalupe, Harding, Lincoln, Mora, Quay, Roosevelt, San Miguel, Taos, Union',
  9: 'Chaves, Eddy, Lea, Otero',
  10: 'Rio Arriba, San Juan, Santa Fe, Taos',
};
const disagreements = [];
for (let d = 1; d <= 10; d++) {
  const fromBill = new Set(perDistrict[d].map(x => toTiger(x.replace(' (precincts)', ''))));
  const fromBook = new Set(HANDBOOK[d].split(',').map(s => toTiger(s.trim())));
  for (const c of fromBook) if (!tigerNames.has(c)) throw new Error(`the handbook names "${c}", which is not a county we hold`);
  const onlyBill = [...fromBill].filter(c => !fromBook.has(c));
  const onlyBook = [...fromBook].filter(c => !fromBill.has(c));
  if (onlyBill.length || onlyBook.length) {
    disagreements.push(`D${d}: HB 9 adds ${onlyBill.join('/') || '—'}, the handbook adds ${onlyBook.join('/') || '—'}`);
  }
}
if (disagreements.length) {
  console.error(`🔴 HB 9 AND THE LEGISLATIVE HANDBOOK DISAGREE on ${disagreements.length} district(s):`);
  for (const x of disagreements) console.error('   ' + x);
  process.exit(1);
}
console.log('🟢 HB 9 and the Legislative Council handbook agree on every district\'s county list');

for (let d = 1; d <= 10; d++) console.log(`D${String(d).padStart(2)}: ${perDistrict[d].join(', ')}`);
console.log(`\nWHOLE ${whole.length} · SPLIT ${split.length}`);
for (const s of split) console.log(`   ${s.county.padEnd(22)} ${s.districts.join('/')}`);

fs.writeFileSync(OUT, JSON.stringify({
  measured: '2026-11-07',
  plan: 'HB 9, Laws 2021 (2nd Special Session), Chapter 3 — the 2021 Educational Redistricting Act, signed 2021-12-17',
  source: 'https://www.nmlegis.gov/Sessions/21%20Special2/final/HB0009.PDF (the FINAL text; HB 6 and HB 7 were the PEC bills that DIED)',
  note: 'The ten districts partition the state, so a county named in exactly one district is WHOLE in it and a county named in two or more is SPLIT between exactly those.',
  perDistrict, whole, split,
}, null, 1));
console.log(`wrote ${OUT}`);
