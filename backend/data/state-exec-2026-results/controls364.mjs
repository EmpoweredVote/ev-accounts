// Controls on CC_0364. Each tamper is asserted PRESENT in the file before it is run, because a
// tamper that did not apply is a control that proved nothing and it looks exactly like a pass.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
const base = fs.readFileSync(SRC, 'utf8');
const write = (name, text, checks) => {
  const out = `${SP}/${name}`;
  fs.writeFileSync(out, text);
  const back = fs.readFileSync(out, 'utf8');
  if (back.length < 20000) throw new Error(`${name}: TAMPER FILE TRUNCATED (${back.length} bytes)`);
  if (back === base) throw new Error(`${name}: TAMPER DID NOT CHANGE THE FILE`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${back.length} bytes)`);
};
const one = (needle, label) => {
  const n = base.split(needle).length - 1;
  if (n !== 1) throw new Error(`TAMPER TARGET "${label}" occurs ${n} times, not once`);
  return needle;
};

const SEAT_SECTION_START = '-- ─── 4. Seat every current member ───';
const SEAT_SECTION_END = '-- ─── 5. The races, each on the office whose seat was up ───';
const sIdx = base.indexOf(SEAT_SECTION_START), eIdx = base.indexOf(SEAT_SECTION_END);
if (sIdx < 0 || eIdx < 0 || eIdx <= sIdx) throw new Error('cannot find the seating section');
const seatSection = base.slice(sIdx, eIdx);

const L = {
  miFips: one(`  ('MI SBE', 'MI', 'Michigan', '26',`, 'the MI SBE body row'),
  msuLast: one(`  ('MI MSU#8', 'MI MSU', 'Michigan State University Trustee', 'Rema Vassar', false, false, 2029, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),\n`, 'the eighth MSU seat'),
  craddick: one(`  ('TX RRC#2', 'TX RRC', 'Texas Railroad Commissioner', 'Christi Craddick', false, false, 2031,`, 'the Christi Craddick seat'),
  hering: one(`  ('Mary Anne Hering', 'Mary Anne', 'Hering',`, 'the Mary Anne Hering seed'),
  rosenthalPin: one(`  ('Jon Rosenthal', 'f5f63005-94a6-4170-b120-a421ea5a8f3b'::uuid)`, 'the Jon Rosenthal pin'),
};

// A — 🔴 DO NOT SEAT ANYONE. The whole seating step is removed, which is what this file would be
//     if it had been written as a results migration instead of an occupancy act: 35 offices
//     created and left empty would take the unflagged drift baseline from 238 to 273 and hand
//     the next person a red master-only gate for drift nobody introduced.
//     Target: the post-verify's "every new office is seated" gate and the 238 assertion.
write('u364A-offices-left-unseated.sql',
  base.slice(0, sIdx) + '-- TAMPER: the entire seating step is removed\n' + base.slice(eIdx),
  [['the seating section was not removed', s => !s.includes('INSERT INTO essentials.office_terms')],
   ['the races section is gone too', s => s.includes(SEAT_SECTION_END)]]);

// B — claim Michigan's FIPS is Minnesota's. Target: the gate that the geo_id this file writes is
//     the one the state's own statewide districts already use. 🔴 geo_id is a LOOKUP KEY, so a
//     wrong one is not a typo — it is eight board members no Michigan address can ever reach.
write('u364B-wrong-fips.sql',
  base.replace(L.miFips, `  ('MI SBE', 'MI', 'Michigan', '27',`),
  [['FIPS not altered', s => s.includes(`('MI SBE', 'MI', 'Michigan', '27',`)]]);

// C — file the eighth Michigan State University trustee under the State Board of Education, so
//     MSU creates 7 seats and the SBE 9. Target: the gate that each body creates its WHOLE
//     membership. 🔴 This is the claim that separates this file from "create the seat that was
//     up": a chamber of 7 where official_count says 8 reads as a vacancy that is not there, and
//     CLAUDE.md treats a complete chamber as the signature of a real vacancy.
//     ⚠ The seat is MOVED, not deleted, on purpose. Deleting it was the first attempt and the row
//       count gate caught it first ("expected 37 seats, found 36") — a correct catch for a
//       different claim, and the seventh time in this series a tamper was shadowed. A tamper has
//       to satisfy every earlier gate to reach its own.
write('u364C-body-not-whole.sql',
  base.replace(L.msuLast, L.msuLast.replace(`('MI MSU#8', 'MI MSU',`, `('MI MSU#8', 'MI SBE',`)),
  [['the eighth MSU seat was not refiled', s => s.includes(`('MI MSU#8', 'MI SBE',`)],
   ['the row count changed', s => (s.match(/'MI MSU#/g) || []).length === (base.match(/'MI MSU#/g) || []).length]]);

// D — say the Texas seat on the 2026 ballot was Christi Craddick's, not Jim Wright's. Target: the
//     gate that checks the ballot column against the term-end years the bodies publish.
//     🔴 THIS IS THE CLAIM A DECEMBER SEATING PASS WILL ACT ON. Attach the race to the wrong
//     office and Jon Rosenthal replaces the chairman, whose term runs to 2031, instead of Wright.
write('u364D-race-on-the-wrong-seat.sql',
  base.replace(L.craddick, `  ('TX RRC#2', 'TX RRC', 'Texas Railroad Commissioner', 'Christi Craddick', true, false, 2031,`),
  [['the ballot flag was not moved', s => s.includes(`'Christi Craddick', true, false, 2031,`)]]);

// E — point the Jon Rosenthal pin at Roger Victory's row: a real, active politician, so nothing
//     about the uuid looks wrong. Target: the gate that every pinned person is still the person
//     this file names. 🔴 A pinned uuid is the one thing in the file no name check can verify
//     unless it is written to.
write('u364E-pin-points-at-someone-else.sql',
  base.replace(L.rosenthalPin, `  ('Jon Rosenthal', '8a85a630-0c68-498e-8e8f-631451fb59b1'::uuid)`),
  [['the pin was not repointed', s => s.includes(`('Jon Rosenthal', '8a85a630-0c68-498e-8e8f-631451fb59b1'::uuid)`)]]);

// F — drop half of a compound given name. Target: the exact-reconstruction split gate.
//     🔴 FOURTH APPEARANCE OF THIS DEFECT: "Mary Anne Hering" still ENDS WITH "Hering", so the
//     containment form CC_0360 shipped cannot see a corrupted given name at all.
write('u364F-bad-split.sql',
  base.replace(L.hering, `  ('Mary Anne Hering', 'Mary', 'Hering',`),
  [['split not altered', s => s.includes(`('Mary Anne Hering', 'Mary', 'Hering',`)]]);

// G — 🔴 THE ONE THAT PROVES THE NUMBER. A removes the seating and is caught by the post-verify's
//     "every new office is seated" gate, which never lets the 238 assertion run. G removes that
//     gate as well, so the only thing left between 35 empty offices and production is the drift
//     baseline itself — the assertion other sessions and the master-only gate actually depend on.
//     Two edits, deliberately: a file written as a results migration would carry neither.
const SEATED_GATE = one(`  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 37 offices have no term and would raise the drift metric', n; END IF;
`, 'the every-office-is-seated gate');
write('u364G-baseline-is-the-last-net.sql',
  (base.slice(0, sIdx) + '-- TAMPER: the entire seating step is removed\n' + base.slice(eIdx))
    .replace(SEATED_GATE, '  -- TAMPER: the every-office-is-seated gate is removed too\n'),
  [['the seating section was not removed', s => !s.includes('INSERT INTO essentials.office_terms')],
   ['the seated gate was not removed', s => !s.includes('would raise the drift metric')],
   ['the baseline assertion is gone too', s => s.includes('must never be raised')]]);
