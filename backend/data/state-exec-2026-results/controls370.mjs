// Controls on CC_0370. Each tamper is asserted PRESENT before it is run.
//
// ⚠ A TAMPER THAT DID NOT APPLY LOOKS EXACTLY LIKE A PASS — on 2026-10-26 a broken sed left a
//   0-byte file and dry-run-migration.mjs reported DRY RUN OK on it, because an empty migration
//   passes every gate it does not contain. So each file is read back and checked here first.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
if (!SP || !SRC) throw new Error('usage: controls370.mjs <outdir> <migration.sql>');
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
  IF n <> 0 THEN RAISE EXCEPTION '% of the 8 offices have no term and would raise the drift metric', n; END IF;
`, 'the every-office-is-seated gate');

const L = {
  seatD2: one(`  (2, 'Tracie West', true, true),`, 'the District 2 seat'),
  seatD6: one(`  (6, 'Marie Manning', true, true),`, 'the District 6 seat'),
  chestnut: one(`  ('Tonya Smith Chestnut', 'Tonya Smith', 'Chestnut',`, 'the Tonya Smith Chestnut seed'),
  layer: one(` || ' District ' || s.d, 'X0003', s.d::text, 'residency'`, 'the district layer code'),
  officeJoin: one(`    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc`, 'the office-to-district join'),
  // ⚠ NOT an anchor county. The first version of control E moved Houston County, which IS the
  //   District 2 anchor, and the run died on the earlier "an anchor county is not assigned whole
  //   to its district by the statute" pre-gate — a correct failure, for the wrong gate. Coffee
  //   County is assigned whole to District 1 by § 16-3-1.1 and anchors nothing.
  coffee: one(`  ('Coffee County', 1),`, "the statute's Coffee County row"),
  count9: one(`  VALUES ('State Board of Education', 'Alabama State Board of Education', 'f427572f-d37a-4828-b68b-7f2c4e6ee4cd'::uuid, 'full', 9, '4 years', true,`, 'the chamber official_count'),
};

// A — 🔴 remove the seating step AND the gate that catches it first, so the drift baseline is the
//     only thing left between 8 empty offices and production. Creating an office is an occupancy
//     act: an unseated one raises the 238 unflagged baseline and nothing else errors.
write('u370A-baseline-is-the-last-net.sql',
  (base.slice(0, sIdx) + '-- TAMPER: the entire seating step is removed\n' + base.slice(eIdx))
    .replace(SEATED_GATE, '  -- TAMPER: the every-office-is-seated gate is removed too\n'),
  [['the seating section was not removed', s => !s.includes('INSERT INTO essentials.office_terms')],
   ['the seated gate was not removed', s => !s.includes('would raise the drift metric')],
   ['the baseline assertion is gone too', s => s.includes('must never be raised')]]);

// B — 🔴 file the districts under the wrong layer code. The key is (geo_id, mtfcc), so an X0099
//     district matches no polygon at all: the districts, offices and terms are still created and
//     nothing errors, and the eight seats are simply invisible to every Alabama address. This is
//     the empty-geo_id failure in its commonest disguise — a key nothing can ever match.
//     Target: the gate that each district MEETS a geofence row on (geo_id, mtfcc).
write('u370B-wrong-layer-code.sql',
  base.replace(L.layer, ` || ' District ' || s.d, 'X0099', s.d::text, 'residency'`),
  [['the layer code was not altered', s => s.includes(`|| s.d, 'X0099', s.d::text`)]]);

// C — 🔴 put two members in each other's seat, in the seat table only. Every polygon is untouched
//     and correct, every office is created and seated, the counts all balance. Target: the gate
//     that the anchor table and the seat table — the two independent statements of the roster —
//     must agree before either is used. Without it, CC_0369 showed, the chain gate below would
//     resolve the holder the seating had just written and compare it with that same seating.
write('u370C-two-members-in-each-others-seat.sql',
  base.replace(L.seatD2, `  (2, 'Marie Manning', true, true),`)
      .replace(L.seatD6, `  (6, 'Tracie West', true, true),`),
  [['the members were not swapped', s => s.includes(`  (2, 'Marie Manning', true, true),`) && s.includes(`  (6, 'Tracie West', true, true),`)]]);

// D — 🔴🔴 THE ONE WORTH READING, AND IT IS NOT C. Reverse the office-to-district join by one
//     expression, so office "District 1" is attached to district 8's row and so on. The seat
//     table and the anchor table still AGREE, so C's gate passes. Every polygon is right, the
//     statute gate passes, 8 districts and 8 offices are created, all 8 are seated, the chamber
//     is whole and every count balances. The ONLY thing that can tell is the chain that starts
//     at a point on the ground: Baldwin County must reach Jackie Zeigler, Houston County must
//     reach Tracie West, through geofence -> district -> office -> current holder.
write('u370D-offices-attached-to-the-wrong-districts.sql',
  base.replace(L.officeJoin, `    FROM seat s JOIN made_district md ON md.d = 9 - s.d CROSS JOIN made_chamber mc`),
  [['the join was not reversed', s => s.includes('ON md.d = 9 - s.d')]]);

// E — 🔴 claim in the statute table that Coffee County is in District 6. The migration carries
//     its own copy of the statute gate, generated from the loader's table, and that copy had
//     only ever been watched passing. Target: the migration's whole-county arm.
write('u370E-statute-says-coffee-is-in-6.sql',
  base.replace(L.coffee, `  ('Coffee County', 6),`),
  [['the statute row was not altered', s => s.includes(`  ('Coffee County', 6),`)]]);

// F — drop the middle name from a compound given name. Target: the exact-reconstruction split
//     gate. 🔴 SEVENTH APPEARANCE of this defect class: "Tonya Smith Chestnut" is (Tonya Smith,
//     Chestnut), and "Smith" is a maiden name, not a surname.
write('u370F-bad-split.sql',
  base.replace(L.chestnut, `  ('Tonya Smith Chestnut', 'Tonya', 'Chestnut',`),
  [['split not altered', s => s.includes(`  ('Tonya Smith Chestnut', 'Tonya', 'Chestnut',`)]]);

// G — say the board has eight members. It has nine; the ninth is the Governor, ex officio. The
//     8-offices-for-9-members gap is a decision, and a decision nothing asserts is a decision
//     the next pass has to make again.
write('u370G-official-count-8.sql',
  base.replace(L.count9, L.count9.replace(`'full', 9, '4 years'`, `'full', 8, '4 years'`)),
  [['the official_count was not altered', s => s.includes(`'full', 8, '4 years', true,`)]]);
