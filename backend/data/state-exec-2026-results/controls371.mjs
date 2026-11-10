// Controls on CC_0371. Each tamper is asserted PRESENT before it is run.
//
// ⚠ A TAMPER THAT DID NOT APPLY LOOKS EXACTLY LIKE A PASS, and a control can also fail for the
//   WRONG REASON — CC_0370 had both. Read the message each one produces, never the exit code.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
if (!SP || !SRC) throw new Error('usage: controls371.mjs <outdir> <migration.sql>');
fs.mkdirSync(SP, { recursive: true });
const base = fs.readFileSync(SRC, 'utf8');
const write = (name, text, checks) => {
  const out = `${SP}/${name}`;
  fs.writeFileSync(out, text);
  const back = fs.readFileSync(out, 'utf8');
  if (back.length < 12000) throw new Error(`${name}: TAMPER FILE TRUNCATED (${back.length} bytes)`);
  if (back === base) throw new Error(`${name}: TAMPER DID NOT CHANGE THE FILE`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${back.length} bytes)`);
};
const one = (needle, label) => {
  const n = base.split(needle).length - 1;
  if (n !== 1) throw new Error(`TAMPER TARGET "${label}" occurs ${n} times, not once`);
  return needle;
};

const SEAT_START = '-- ─── Seat every current member ───';
const SEAT_END = '-- ─── The races and their results ───';
const sIdx = base.indexOf(SEAT_START), eIdx = base.indexOf(SEAT_END);
if (sIdx < 0 || eIdx < 0 || eIdx <= sIdx) throw new Error('cannot find the seating section');
const SEATED_GATE = one(`  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 5 offices have no term and would raise the drift metric', n; END IF;
`, 'the every-office-is-seated gate');

const L = {
  seatD1: one(`  (1, 'Eric Skrmetta', true, true),`, 'the District 1 seat'),
  seatD5: one(`  (5, 'Foster Campbell', true, true);`, 'the District 5 seat'),
  coussan: one(`  ('Jean-Paul Coussan', 'Jean-Paul', 'Coussan',`, 'the Jean-Paul Coussan seed'),
  layer: one(` || ' District ' || s.d, 'X-ST-BOARD', s.d::text, 'residency'`, 'the district layer code'),
  officeJoin: one(`    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc`, 'the office-to-district join'),
  // ⚠ NOT an anchor parish. CC_0370's equivalent control first moved the District 2 anchor and
  //   died on the "an anchor is not assigned whole to its district" pre-gate — a correct failure
  //   for a gate that was not under test. Lafourche is whole in District 2 and anchors nothing.
  lafourche: one(`  ('Lafourche Parish', 2),`, "the plan's Lafourche Parish row"),
  hilferty: one(`  (1, 'Stephanie Hilferty', 'won', false, false),`, "Stephanie Hilferty's candidacy"),
};

// A — 🔴 remove the seating step AND the gate that catches it first, so the drift baseline is the
//     only thing left between 5 empty offices and production.
write('u371A-baseline-is-the-last-net.sql',
  (base.slice(0, sIdx) + '-- TAMPER: the entire seating step is removed\n' + base.slice(eIdx))
    .replace(SEATED_GATE, '  -- TAMPER: the every-office-is-seated gate is removed too\n'),
  [['the seating section was not removed', s => !s.includes('INSERT INTO essentials.office_terms')],
   ['the seated gate was not removed', s => !s.includes('would raise the drift metric')],
   ['the baseline assertion is gone too', s => s.includes('must never be raised')]]);

// B — 🔴 file the districts under a layer that matches no polygon. Everything is still created
//     and nothing errors; the five seats are simply invisible to every Louisiana address.
write('u371B-wrong-layer-code.sql',
  base.replace(L.layer, ` || ' District ' || s.d, 'X0099', s.d::text, 'residency'`),
  [['the layer code was not altered', s => s.includes(`|| s.d, 'X0099', s.d::text`)]]);

// C — 🔴 put two commissioners in each other's seat, in the seat table only. Target: the gate
//     that the anchor table and the seat table must agree before either is used.
write('u371C-two-members-in-each-others-seat.sql',
  base.replace(L.seatD1, `  (1, 'Foster Campbell', true, true),`)
      .replace(L.seatD5, `  (5, 'Eric Skrmetta', true, true);`),
  [['the members were not swapped', s => s.includes(`  (1, 'Foster Campbell', true, true),`) && s.includes(`  (5, 'Eric Skrmetta', true, true);`)]]);

// D — 🔴🔴 THE ONE WORTH READING. Reverse the office-to-district join by one expression, so
//     office "District 1" is attached to district 5's row and so on. The seat and anchor tables
//     still AGREE, every polygon is right, the parish gate passes, 5 districts and 5 offices are
//     created, all 5 are seated and every count balances. Only the chain from a point on the
//     ground to a named commissioner can see it.
write('u371D-offices-attached-to-the-wrong-districts.sql',
  base.replace(L.officeJoin, `    FROM seat s JOIN made_district md ON md.d = 6 - s.d CROSS JOIN made_chamber mc`),
  [['the join was not reversed', s => s.includes('ON md.d = 6 - s.d')]]);

// E — 🔴 claim in the plan table that Lafourche Parish is in District 5. The migration carries
//     its own copy of the parish gate, generated from the reconciliation file, and that copy had
//     only ever been watched passing.
write('u371E-plan-says-lafourche-is-in-5.sql',
  base.replace(L.lafourche, `  ('Lafourche Parish', 5),`),
  [['the plan row was not altered', s => s.includes(`  ('Lafourche Parish', 5),`)]]);

// F — drop the hyphen from a hyphenated given name. Target: the exact-reconstruction split gate.
//     🔴 EIGHTH APPEARANCE of this defect class; the first where the compound is a FIRST name
//     joined by a hyphen rather than a surname.
write('u371F-bad-split.sql',
  base.replace(L.coussan, `  ('Jean-Paul Coussan', 'Jean', 'Coussan',`),
  [['split not altered', s => s.includes(`  ('Jean-Paul Coussan', 'Jean', 'Coussan',`)]]);

// G — mark the District 1 winner as the incumbent. She is not: Eric Skrmetta holds that seat and
//     was not on the ballot. Target: the two gates that cross-check the incumbent flag against
//     the seat's holder, and the one that says NO candidacy here may carry it.
write('u371G-winner-claimed-as-incumbent.sql',
  base.replace(L.hilferty, `  (1, 'Stephanie Hilferty', 'won', false, true),`),
  [['the flag was not altered', s => s.includes(`  (1, 'Stephanie Hilferty', 'won', false, true),`)]]);
