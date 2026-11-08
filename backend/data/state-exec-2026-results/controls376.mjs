// Controls on migrations/CC_0376_nh_executive_council.sql.
// Each tamper is a single, surgical edit to the generated SQL, asserted PRESENT in the written
// file before it is run — a sed that silently produced a 0-byte file once got "DRY RUN OK" out of
// an empty migration, and an empty tamper proves nothing.
//
// 🔴🔴 RUN THESE BEFORE THE REAL APPLY. This migration CREATES, and its own idempotence gates
//   refuse once the chamber and districts exist. A tamper run afterwards stops at "the chamber
//   this file creates already exists" — which is a real gate, but not the gate under test, and it
//   would look like a pass for the wrong reason. That is the shadowing failure CC_0370 and
//   CC_0372 both paid for.
//
// ⚠ Read the MESSAGE each one produces, never the exit code.
//
// Usage (from backend/):
//   node data/state-exec-2026-results/controls376.mjs <outdir>
//   then: node scripts/dry-run-migration.mjs <outdir>/<file>   for each
import fs from 'node:fs';

const SRC = 'C:/ev-accounts-nh/backend/migrations/CC_0376_nh_executive_council.sql';
const OUTDIR = process.argv[2];
if (!OUTDIR) throw new Error('usage: controls376.mjs <outdir>');
fs.mkdirSync(OUTDIR, { recursive: true });

const base = fs.readFileSync(SRC, 'utf8');
if (base.length < 20000) throw new Error(`${SRC} is only ${base.length} bytes — emit it first`);

// Replace exactly one occurrence, and refuse if it is not there exactly once.
function one(text, find, replace, label) {
  const parts = text.split(find);
  if (parts.length !== 2) {
    throw new Error(`${label}: the anchor text occurs ${parts.length - 1} time(s), expected exactly 1:\n  ${find}`);
  }
  return parts[0] + replace + parts[1];
}

function write(name, text, checks) {
  const p = `${OUTDIR}/${name}`;
  fs.writeFileSync(p, text);
  const back = fs.readFileSync(p, 'utf8');
  if (back.length < 20000) throw new Error(`${name}: TAMPER FILE IS ${back.length} BYTES — it proves nothing`);
  if (back === base) throw new Error(`${name}: TAMPER DID NOT APPLY — the file is identical to the original`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${back.length} bytes, ${back.length - base.length >= 0 ? '+' : ''}${back.length - base.length})`);
  return p;
}

// A — 🔴🔴 THE ONE THAT MATTERS: swap which councilor holds District 1 and District 3. Every
//     polygon is right, every race is right, the chamber is the right size — only two names are
//     on the wrong seats. This is the migration-level equivalent of the loader's label swap, and
//     the 259-town chain gate is the only thing that can see it.
{
  let t = base;
  t = one(t, `  (1, 'Joseph D. Kenney', 'r', true)`, `  (1, 'Janet Stevens', 'r', true)`, 'A/1');
  t = one(t, `  (3, 'Janet Stevens', 'r', true)`, `  (3, 'Joseph D. Kenney', 'r', true)`, 'A/3');
  write('t376A-holders-1-and-3-swapped.sql', t, [
    ['district 1 does not name Stevens', s => s.includes(`  (1, 'Janet Stevens', 'r', true)`)],
    ['district 3 does not name Kenney', s => s.includes(`  (3, 'Joseph D. Kenney', 'r', true)`)],
  ]);
}

// A2 — 🔴🔴 THE CHAIN-GATE TAMPER, AND IT EXISTS BECAUSE A WAS SHADOWED.
//      A swapped two councilors between seats and never reached the 259-town chain gate: the
//      `calls` consistency check fires first, because moving a holder leaves his race carrying no
//      incumbent. Two independent gates catching it is a good property of the file and a useless
//      property of the control — a tamper stopped by an earlier gate says nothing about a later
//      one. So this one leaves every name, race and flag alone and swaps which POLYGON districts
//      1 and 3 point at. The pre-create statute gate still passes, because it reads the geofence
//      rows directly by coordinate and never touches essentials.districts. Only the chain gate,
//      which walks point -> polygon -> district -> office -> holder, can see it.
{
  const find = `  SELECT 'STATE_BOARD', 'nh', 'ocd-division/country:us/state:nh/council:' || s.d, 'ocd-division/country:us/state:nh/council:' || s.d,`;
  const swap = `(CASE s.d WHEN 1 THEN 3 WHEN 3 THEN 1 ELSE s.d END)`;
  const t = one(base, find,
    `  SELECT 'STATE_BOARD', 'nh', 'ocd-division/country:us/state:nh/council:' || ${swap}, 'ocd-division/country:us/state:nh/council:' || ${swap},`,
    'A2');
  write('t376A2-districts-1-and-3-point-at-swapped-polygons.sql', t, [
    ['the geo_id expression was not swapped', s => s.includes(swap)],
    ['the seat table was touched', s => s.includes(`  (1, 'Joseph D. Kenney', 'r', true)`)],
    ['the calls table was touched', s => s.includes(`  (1, 'Luz Bay', 'won', 64227, false)`)],
  ]);
}

// A3 — 🔴🔴 THE TAMPER A2 WAS TRYING TO BE. A2 swapped the geo_ids and cancelled itself out,
//      because the office joins its district on a number derived FROM the geo_id. This swaps the
//      join instead: the District 1 office is attached to the District 3 district row, and vice
//      versa, leaving every geo_id, label, name, race and flag untouched. Now a District 3 town
//      really does reach Joseph D. Kenney, and the chain gate is the thing that has to say so.
{
  const find = `    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc`;
  const t = one(base, find,
    `    FROM seat s JOIN made_district md ON md.d = (CASE s.d WHEN 1 THEN 3 WHEN 3 THEN 1 ELSE s.d END) CROSS JOIN made_chamber mc`,
    'A3');
  write('t376A3-office-attached-to-the-wrong-district.sql', t, [
    ['the office join was not swapped', s => s.includes(`md.d = (CASE s.d WHEN 1 THEN 3 WHEN 3 THEN 1 ELSE s.d END)`)],
    ['the seat table was touched', s => s.includes(`  (1, 'Joseph D. Kenney', 'r', true)`)],
    ['a geo_id was touched', s => s.includes(`'ocd-division/country:us/state:nh/council:' || s.d, 'ocd-division/country:us/state:nh/council:' || s.d,`)],
  ]);
}

// A4 — 🔴🔴 THE CONTROL THAT FINALLY REACHES THE CHAIN GATE. A3 is stopped by the office/district
//      number check, which is the right gate for A3's fault but means the 259-town chain still
//      had no tamper of its own — and a gate no control reaches is a gate nobody has tested.
//      This leaves the districts, offices, geo_ids, labels, races, flags and people all correct
//      and swaps only WHO IS SEATED IN WHICH OFFICE: Kenney into the District 3 office, Stevens
//      into District 1. Every earlier gate reads `seat` and `calls`, which are untouched and
//      agree with each other. Only walking from a point on the ground to the name a voter is
//      shown can catch it.
{
  const find = `  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;`;
  const t = one(base, find,
    `  FROM seat s JOIN made_office mo ON mo.d = (CASE s.d WHEN 1 THEN 3 WHEN 3 THEN 1 ELSE s.d END) JOIN person pe ON pe.who = s.who;`,
    'A4');
  write('t376A4-right-people-seated-in-the-wrong-offices.sql', t, [
    ['the seating join was not swapped', s => s.includes(`mo.d = (CASE s.d WHEN 1 THEN 3 WHEN 3 THEN 1 ELSE s.d END) JOIN person pe`)],
    ['the office join was touched', s => s.includes(`    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc`)],
    ['the seat table was touched', s => s.includes(`  (1, 'Joseph D. Kenney', 'r', true)`)],
  ]);
}

// B — 🔴 move one anchor town into the wrong district. Albany is a real District 1 town; this
//     claims the statute puts it in District 2. The pre-create gate that compares the map against
//     RSA 662:2 has to catch it before anything is written.
{
  const find = `  ('Albany', 'Carroll', 1, `;
  const t = one(base, find, `  ('Albany', 'Carroll', 2, `, 'B');
  write('t376B-albany-moved-to-d2.sql', t, [
    ['Albany was not moved', s => s.includes(`  ('Albany', 'Carroll', 2, `)],
    ['the original Albany row survives', s => !s.includes(`  ('Albany', 'Carroll', 1, `)],
  ]);
}

// C — 🔴 call the losing candidate the winner in District 1, leaving the vote counts alone. The
//     "won" flag and the vote count are two separate facts and this is where they must agree.
{
  let t = base;
  t = one(t, `  (1, 'Luz Bay', 'won', 64227, false)`, `  (1, 'Luz Bay', 'lost', 64227, false)`, 'C/bay');
  t = one(t, `  (1, 'Joseph D. Kenney', 'lost', 60500, true)`, `  (1, 'Joseph D. Kenney', 'won', 60500, true)`, 'C/kenney');
  write('t376C-d1-winner-flipped.sql', t, [
    ['Bay is still the winner', s => s.includes(`  (1, 'Luz Bay', 'lost', 64227, false)`)],
    ['Kenney is not marked won', s => s.includes(`  (1, 'Joseph D. Kenney', 'won', 60500, true)`)],
  ]);
}

// D — 🔴 the term date. Art. 60's constitutional January date is the date the votes are COUNTED,
//     and a pass that reuses it as the oath date lands one day early. This plants exactly that
//     off-by-one on the 2025 term and the term-date gate must refuse it.
{
  const t = one(base, `SELECT mo.office_id, pe.pid, DATE '2025-01-09'`, `SELECT mo.office_id, pe.pid, DATE '2025-01-08'`, 'D');
  write('t376D-term-start-one-day-early.sql', t, [
    ['the term date was not changed', s => s.includes(`SELECT mo.office_id, pe.pid, DATE '2025-01-08'`)],
  ]);
}

// E — 🔴 record the council as staggered. It is not: all five seats are elected together, and a
//     December pass that believed otherwise would seat only the seats it thought were up.
{
  const t = one(base, `'2 years', false, 'https://www.council.nh.gov/'`, `'2 years', true, 'https://www.council.nh.gov/'`, 'E');
  write('t376E-council-marked-staggered.sql', t, [
    ['staggered_term was not set', s => s.includes(`'2 years', true, 'https://www.council.nh.gov/'`)],
  ]);
}

// F — 🔴 drop a town from the anchor table. The chain gate must notice it examined 258 rows and
//     not 259 — a gate that only reports "no mismatches" cannot tell a clean sweep from a short
//     one, which is why the count is asserted separately.
{
  const line = base.split('\n').find(l => l.startsWith(`  ('Wolfeboro', `));
  if (!line) throw new Error('F: no Wolfeboro anchor row found');
  // It is the last row of the district-1 block or mid-list; remove the line and fix the comma.
  const t = base.replace(line + '\n', '');
  if (t === base) throw new Error('F: the Wolfeboro row was not removed');
  write('t376F-one-anchor-town-dropped.sql', t, [
    ['Wolfeboro is still in the anchor table', s => !s.includes(`  ('Wolfeboro', `)],
  ]);
}

// G — 🟢 A CONTROL THAT MUST PASS. A comment added at the end changes the bytes and nothing else.
//     If this went red the suite would be refusing everything and the six above would mean nothing.
{
  const t = base.replace(/COMMIT;\s*$/, `-- control G: a harmless comment, to prove the suite is not refusing everything\nCOMMIT;\n`);
  write('t376G-harmless-comment.sql', t, [
    ['the comment was not added', s => s.includes('control G: a harmless comment')],
    ['COMMIT was lost', s => /COMMIT;\s*$/.test(s)],
  ]);
}

console.log('\nA, B, C, D, E, F must FAIL (read the message, not the exit code); G must PASS.');
console.log('🔴 Run them BEFORE applying the real migration, or the idempotence gates shadow them all.');
