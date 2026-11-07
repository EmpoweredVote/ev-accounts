// Controls on CC_0366. Each tamper is asserted PRESENT before it is run.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
const base = fs.readFileSync(SRC, 'utf8');
const write = (name, text, checks) => {
  const out = `${SP}/${name}`;
  fs.writeFileSync(out, text);
  const back = fs.readFileSync(out, 'utf8');
  if (back.length < 18000) throw new Error(`${name}: TAMPER FILE TRUNCATED (${back.length} bytes)`);
  if (back === base) throw new Error(`${name}: TAMPER DID NOT CHANGE THE FILE`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${back.length} bytes)`);
};
const one = (needle, label) => {
  const n = base.split(needle).length - 1;
  if (n !== 1) throw new Error(`TAMPER TARGET "${label}" occurs ${n} times, not once`);
  return needle;
};

const SEAT_START = '-- ─── 5. Seat every current member ───';
const SEAT_END = '-- ─── 6. The nine races and their results ───';
const sIdx = base.indexOf(SEAT_START), eIdx = base.indexOf(SEAT_END);
if (sIdx < 0 || eIdx < 0 || eIdx <= sIdx) throw new Error('cannot find the seating section');

const SEATED_GATE = one(`  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 26 offices have no term and would raise the drift metric', n; END IF;
`, 'the every-office-is-seated gate');

const L = {
  // the INSERT that writes the copied polygons — the ONE place the copy is tied to a source
  polyJoin: one(`  JOIN essentials.geofence_boundaries src ON src.mtfcc = 'G5200' AND src.geo_id = mp.src_geo_id;`, 'the polygon-copy source join'),
  atLarge: one(`  ('CO SBE#9', 'CO SBE', 'State Board of Education Member, At-Large', 'Kathy Plomer', false, false, NULL, 'statewide', NULL, NULL),`, 'the CO SBE at-large seat'),
  james: one(`  ('CO REGENTS#1', 'CO REGENTS', 'University of Colorado Regent, District 1', 'Wanda James', false, false, 2029, 'cd', 1, NULL),`, 'the Wanda James seat'),
  gaD3: one(`  ('GA PSC#3', 'GA PSC', 'Public Service Commissioner, District 3', 'Peter Hubbard', true, true, NULL, 'statewide', NULL, 'Georgia Public Service Commission District 3'),`, 'the Georgia District 3 seat'),
  brown: one(`  ('Kristi Burton Brown', 'Kristi', 'Burton Brown',`, 'the Kristi Burton Brown seed'),
};

// A — 🔴 THE ONE THAT PROVES THE NUMBER. The whole seating step is removed AND so is the
//     post-verify gate that would catch it first, leaving the drift baseline as the only thing
//     between 26 empty offices and production. That baseline is what the master-only gate and
//     every other session depend on.
write('u366A-baseline-is-the-last-net.sql',
  (base.slice(0, sIdx) + '-- TAMPER: the entire seating step is removed\n' + base.slice(eIdx))
    .replace(SEATED_GATE, '  -- TAMPER: the every-office-is-seated gate is removed too\n'),
  [['the seating section was not removed', s => !s.includes('INSERT INTO essentials.office_terms')],
   ['the seated gate was not removed', s => !s.includes('would raise the drift metric')],
   ['the baseline assertion is gone too', s => s.includes('must never be raised')]]);

// B — 🔴🔴 THE GEOMETRY ONE. Copy each board district from the NEXT congressional district along:
//     District 1 gets CD2's polygon, District 2 gets CD3's. Every polygon is still a real,
//     valid, 4326 Colorado congressional district, and the set still tiles the state, so shape,
//     projection and coverage all look perfect — and every voter is told the wrong board member.
//     Target: the gate that each copy ST_Equals the congressional district it CLAIMS to be.
write('u366B-polygon-off-by-one.sql',
  base.replace(L.polyJoin, `  JOIN essentials.geofence_boundaries src ON src.mtfcc = 'G5200'\n   AND src.geo_id = b.fips || lpad(((s.cd % 8) + 1)::text, 2, '0'); -- TAMPER: the next district along`),
  [['the source join was not shifted', s => s.includes(`lpad(((s.cd % 8) + 1)::text, 2, '0'); -- TAMPER`)]]);

// C — file Colorado's at-large board member under the Regents, so the State Board creates 8 of
//     its 9 seats and the Regents 10 of theirs. Target: the whole-membership gate.
//     ⚠ The seat is MOVED, not deleted: deleting it would trip the row-count gate first, which is
//       a correct catch for a different claim. A tamper must satisfy every earlier gate.
write('u366C-body-not-whole.sql',
  base.replace(L.atLarge, L.atLarge.replace(`('CO SBE#9', 'CO SBE',`, `('CO SBE#9', 'CO REGENTS',`)),
  [['the at-large seat was not refiled', s => s.includes(`('CO SBE#9', 'CO REGENTS',`)],
   ['the row count changed', s => (s.match(/'CO SBE#/g) || []).length === (base.match(/'CO SBE#/g) || []).length]]);

// D — say Wanda James's seat was on the 2026 ballot. Her own board publishes her term as running
//     to 2029. Target: the gate that checks the ballot column against the published term-end year.
//     🔴 Get this wrong and a December pass retires a regent with three years left.
write('u366D-wrong-seat-on-the-ballot.sql',
  base.replace(L.james, L.james.replace(`'Wanda James', false, false, 2029,`, `'Wanda James', true, false, 2029,`)),
  [['the ballot flag was not set', s => s.includes(`'Wanda James', true, false, 2029,`)]]);

// E — 🔴 RE-ASSERT THE MISTAKE THIS FILE EXISTS TO CORRECT: treat Georgia's "District 3" as real
//     geography. Georgia's commissioners are chosen statewide and the district is a residency
//     rule, so the body declares no polygon layer at all. Target: the gate that a body with
//     districted seats must declare the layer its polygons load into.
write('u366E-georgia-treated-as-districted.sql',
  base.replace(L.gaD3, L.gaD3.replace(`NULL, 'statewide', NULL,`, `NULL, 'cd', 3,`)),
  [['the Georgia seat was not made districted', s => s.includes(`'Peter Hubbard', true, true, NULL, 'cd', 3,`)]]);

// F — drop half of a compound surname. Target: the exact-reconstruction split gate.
//     🔴 FIFTH APPEARANCE: "Kristi Burton Brown" still ENDS WITH "Brown", so the containment form
//     CC_0360 shipped cannot see this at all.
//     ⚠ The first draft of this tamper wrote ('Kristi Burton', 'Brown'), which RECONSTRUCTS the
//       name exactly and so proves nothing — a tamper that cannot trip the comparison tests
//       nothing at all. It drops the middle name instead.
write('u366F-bad-split.sql',
  base.replace(L.brown, `  ('Kristi Burton Brown', 'Kristi', 'Brown',`),
  [['split not altered', s => s.includes(`('Kristi Burton Brown', 'Kristi', 'Brown',`)]]);
