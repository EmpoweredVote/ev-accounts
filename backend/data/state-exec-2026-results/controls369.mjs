// Controls on CC_0369. Each tamper is asserted PRESENT before it is run.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
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
  IF n <> 0 THEN RAISE EXCEPTION '% of the 15 offices have no term and would raise the drift metric', n; END IF;
`, 'the every-office-is-seated gate');

const L = {
  d2: one(`  (2, 'LJ Francis', 'Corpus Christi', true, true),`, 'the District 2 seat'),
  d15: one(`  (15, 'Aaron Kinsey', 'Midland', false, false);`, 'the District 15 seat'),
  perez: one(`  ('Marisa B. Perez-Diaz', 'Marisa B.', 'Perez-Diaz',`, 'the Marisa B. Perez-Diaz seed'),
  layer: one(` || ' District ' || s.d, 'X0003', s.d::text, 'residency'`, 'the district layer code'),
};

// A — 🔴 remove the seating step AND the gate that catches it first, so the drift baseline is the
//     only thing left between 15 empty offices and production.
write('u369A-baseline-is-the-last-net.sql',
  (base.slice(0, sIdx) + '-- TAMPER: the entire seating step is removed\n' + base.slice(eIdx))
    .replace(SEATED_GATE, '  -- TAMPER: the every-office-is-seated gate is removed too\n'),
  [['the seating section was not removed', s => !s.includes('INSERT INTO essentials.office_terms')],
   ['the seated gate was not removed', s => !s.includes('would raise the drift metric')],
   ['the baseline assertion is gone too', s => s.includes('must never be raised')]]);

// B — 🔴 file the districts under the wrong layer code. The key is (geo_id, mtfcc), so an X0099
//     district matches no polygon at all: the districts, offices and terms are still created and
//     nothing errors, and the fifteen seats are simply invisible to every Texas address. This is
//     the empty-geo_id failure in its commonest disguise — a key nothing can ever match.
//     Target: the gate that each district MEETS a geofence row on (geo_id, mtfcc).
write('u369B-wrong-layer-code.sql',
  base.replace(L.layer, ` || ' District ' || s.d, 'X0099', s.d::text, 'residency'`),
  [['the layer code was not altered', s => s.includes(`|| s.d, 'X0099', s.d::text`)]]);

// C — 🔴🔴 THE ONE WORTH READING. Swap the members of Districts 2 and 15 — Corpus Christi's LJ
//     Francis and Midland's Aaron Kinsey. Every polygon is untouched and correct, every office
//     is created and seated, the chamber is whole, and the counts all balance. Only two people
//     sit in each other's seat, and the only thing that can tell is the chain that starts at a
//     point on the ground: Corpus Christi must reach LJ Francis and Midland must reach Aaron
//     Kinsey, through geofence -> district -> office -> current holder.
write('u369C-two-members-in-each-others-seat.sql',
  base.replace(L.d2, `  (2, 'Aaron Kinsey', 'Corpus Christi', true, true),`)
      .replace(L.d15, `  (15, 'LJ Francis', 'Midland', false, false);`),
  [['the members were not swapped', s => s.includes(`(2, 'Aaron Kinsey', 'Corpus Christi'`) && s.includes(`(15, 'LJ Francis', 'Midland'`)]]);

// D — drop the middle initial from a compound given name. Target: the exact-reconstruction split
//     gate. 🔴 SIXTH APPEARANCE: "Marisa B. Perez-Diaz" still ends with "Perez-Diaz".
write('u369D-bad-split.sql',
  base.replace(L.perez, `  ('Marisa B. Perez-Diaz', 'Marisa', 'Perez-Diaz',`),
  [['split not altered', s => s.includes(`('Marisa B. Perez-Diaz', 'Marisa', 'Perez-Diaz',`)]]);
