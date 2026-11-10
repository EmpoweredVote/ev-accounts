// Controls on CC_0372. Each tamper is asserted PRESENT before it is run, and each failure
// message is read rather than the exit code.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
if (!SP || !SRC) throw new Error('usage: controls372.mjs <outdir> <migration.sql>');
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
  IF n <> 0 THEN RAISE EXCEPTION '% of the 10 offices have no term and would raise the drift metric', n; END IF;
`, 'the every-office-is-seated gate');

const L = {
  seatD5: one(`  (5, 'Sharon E. Clahchischilliage', true, true),`, 'the District 5 seat'),
  seatD6: one(`  (6, 'Stewart Ingham', true, true),`, 'the District 6 seat'),
  chalk: one(`  ('Sharon E. Clahchischilliage', 'Sharon E.', 'Clahchischilliage',`, 'the Clahchischilliage seed'),
  layer: one(` || ' District ' || s.d, 'X0003', s.d::text, 'residency'`, 'the district layer code'),
  officeJoin: one(`    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc`, 'the office-to-district join'),
  // NOT an anchor county: Catron is District 6's anchor, Luna is simply whole in 6.
  luna: one(`  ('Luna County', 6),`, "the plan's Luna County row"),
};

// A — 🔴 remove the seating and the gate that catches it, leaving only the drift baseline.
write('u372A-baseline-is-the-last-net.sql',
  (base.slice(0, sIdx) + '-- TAMPER: the entire seating step is removed\n' + base.slice(eIdx))
    .replace(SEATED_GATE, '  -- TAMPER: the every-office-is-seated gate is removed too\n'),
  [['the seating section was not removed', s => !s.includes('INSERT INTO essentials.office_terms')],
   ['the seated gate was not removed', s => !s.includes('would raise the drift metric')],
   ['the baseline assertion is gone too', s => s.includes('must never be raised')]]);

// B — a layer code that matches no polygon: everything is created, nothing errors, and all ten
//     seats are invisible to every New Mexico address.
write('u372B-wrong-layer-code.sql',
  base.replace(L.layer, ` || ' District ' || s.d, 'X0099', s.d::text, 'residency'`),
  [['the layer code was not altered', s => s.includes(`|| s.d, 'X0099', s.d::text`)]]);

// C — two members in each other's seat, in the seat table only. Target: the gate that the
//     anchor table and the seat table must agree before either is used.
write('u372C-two-members-in-each-others-seat.sql',
  base.replace(L.seatD5, `  (5, 'Stewart Ingham', true, true),`)
      .replace(L.seatD6, `  (6, 'Sharon E. Clahchischilliage', true, true),`),
  [['the members were not swapped', s => s.includes(`  (5, 'Stewart Ingham', true, true),`) && s.includes(`  (6, 'Sharon E. Clahchischilliage', true, true),`)]]);

// D — 🔴🔴 reverse the office-to-district join. The seat and anchor tables still agree, every
//     polygon is right, the statute gate passes, ten offices are created and seated and every
//     count balances. Only the point-to-member chain can see it.
write('u372D-offices-attached-to-the-wrong-districts.sql',
  base.replace(L.officeJoin, `    FROM seat s JOIN made_district md ON md.d = 11 - s.d CROSS JOIN made_chamber mc`),
  [['the join was not reversed', s => s.includes('ON md.d = 11 - s.d')]]);

// E — the plan table claims Luna County for District 9. Target: the migration's own copy of the
//     statute gate, which had only ever been watched passing. Luna anchors nothing, so the
//     earlier anchor pre-gate does not shadow it (the mistake CC_0370's control E made first).
write('u372E-plan-says-luna-is-in-9.sql',
  base.replace(L.luna, `  ('Luna County', 9),`),
  [['the plan row was not altered', s => s.includes(`  ('Luna County', 9),`)]]);

// F — drop a middle initial from a compound given name. 🔴 NINTH appearance of the split defect.
write('u372F-bad-split.sql',
  base.replace(L.chalk, `  ('Sharon E. Clahchischilliage', 'Sharon', 'Clahchischilliage',`),
  [['split not altered', s => s.includes(`  ('Sharon E. Clahchischilliage', 'Sharon', 'Clahchischilliage',`)]]);
