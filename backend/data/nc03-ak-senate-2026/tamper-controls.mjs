// Build one tampered copy of CC_0454 and ASSERT THE TAMPER IS PRESENT.
// 🔴 A tamper that did not apply is a control that proved nothing, and it looks like a pass:
// dry-run-migration.mjs reports DRY RUN OK on a 0-byte file, because an empty migration passes
// every gate it does not contain.
// 🔴 The replacement is a FUNCTION, never a string — in String.replace a `$$` in the replacement
// is an escape for a single `$`, so a tamper inserting a `DO $$` block silently emits `DO $`.
import fs from 'node:fs';
const [L, SRC, DEST] = process.argv.slice(2);
const before = fs.readFileSync(SRC, 'utf8');
let s = before;
const sub = (find, repl, label) => {
  const n = s.split(find).length - 1;
  if (n === 0) throw new Error(`control ${L}: anchor NOT FOUND — ${label}`);
  if (n > 1)  throw new Error(`control ${L}: anchor occurs ${n} times — ${label}`);
  s = s.replace(find, () => repl);
};

const E = {
  // P3 — a pinned id that names somebody else. The pin is what targets the write, so a stale
  // pin is the way a result lands on the wrong person.
  P3: () => sub("'NC-03',  'Raymond Smith Jr.',      '136139'",
                "'NC-03',  'Raymond Smyth Jr.',      '136139'", 'the NC-03 winner name'),

  // P7 — the winner is not the top vote-getter. This is the CA-48 mistake: ballot order read as
  // a result. `votes` and `result` are independent fields, so the swap breaks their agreement.
  P7: () => { sub("'NC-03',  'Raymond Smith Jr.',      '136139', false, 'won',  118434, 49.43",
                  "'NC-03',  'Raymond Smith Jr.',      '136139', false, 'lost', 118434, 49.43", 'Smith result');
              sub("'NC-03',  'Gregory F. Murphy',      '67890',  true,  'lost', 118176, 49.32",
                  "'NC-03',  'Gregory F. Murphy',      '67890',  true,  'won',  118176, 49.32", 'Murphy result'); },

  // P8 — 🔴 THE TWO SULLIVANS' AP IDENTITIES SWAPPED. Both lost, so `result` is unchanged and V2
  // cannot see this. It would put 131,844 votes and the words "the seat's incumbent" onto the man
  // who polled 4,760.
  // ⚠ REBUILT: the first draft swapped the rc_ids, and P3 (the pinned id must still name the
  // expected candidate) caught it first — an earlier gate shadowing the one under test, so the
  // control proved nothing about P8. This swaps ONLY the AP columns, leaving each `who` matching
  // its row, so P3 passes and the incumbency cross-check is the only thing that can object.
  P8: () => { sub("'AK-SEN', 'Dan S. Sullivan',        '64262',  true,  'lost', 131844, 45.80",
                  "'AK-SEN', 'Dan S. Sullivan',        '177716', false, 'lost',   4760,  1.65", 'Sullivan A AP identity');
              sub("'AK-SEN', 'Daniel J. Sullivan Jr.', '177716', false, 'lost',   4760,  1.65",
                  "'AK-SEN', 'Daniel J. Sullivan Jr.', '64262',  true,  'lost', 131844, 45.80", 'Sullivan B AP identity'); },

  // P9 — 🔴 ALASKA AS IT STOOD ON 2026-11-17, when AP held the race at Too Early to Call.
  // Peltola clears a majority EXCLUDING the write-ins and falls 52 short INCLUDING them, so the
  // ranked-choice rounds still decide it. The second arm of P9 must fire and the first must not.
  // (Sullivan's figure is back-solved to make the lines sum to the real 11-17 total; the control
  // is aimed at the gate, not at reproducing every candidate's count that day.)
  P9: () => { sub("'AK-SEN', 'Mary Peltola',           '70718',  false, 'won',  144302, 50.12",
                  "'AK-SEN', 'Mary Peltola',           '70718',  false, 'won',  141637, 49.98", 'Peltola votes');
              sub("'AK-SEN', 'Dan S. Sullivan',        '64262',  true,  'lost', 131844, 45.80",
                  "'AK-SEN', 'Dan S. Sullivan',        '64262',  true,  'lost', 130001, 45.80", 'Sullivan votes');
              sub('SELECT 885 AS votes', 'SELECT 874 AS votes', 'the write-in line');
              sub('IF v_den_excl <> 287011 THEN', 'IF v_den_excl <> 282503 THEN', 'excl pin');
              sub("Division of Elections says 287011', v_den_excl", "Division of Elections says 282503', v_den_excl", 'excl msg');
              sub('IF v_den_incl <> 287896 THEN', 'IF v_den_incl <> 283377 THEN', 'incl pin');
              sub("AP says 287896', v_den_incl", "AP says 283377', v_den_incl", 'incl msg'); },

  // V1 — 🔴 AN OVER-REACHING WRITE. The only control that tests what the migration does NOT do.
  // Touches one federal row outside the seven pins; V1's second half must name it.
  V1: () => sub('-- ─── Post-verify ─',
    `UPDATE essentials.race_candidates rc SET result_source = coalesce(rc.result_source,'') || ' tampered'
  WHERE rc.id = (SELECT rc2.id FROM essentials.race_candidates rc2
                   JOIN essentials.races r ON r.id = rc2.race_id
                   JOIN essentials.elections e ON e.id = r.election_id
                   JOIN essentials.offices o ON o.id = r.office_id
                   JOIN essentials.districts d ON d.id = o.district_id
                  WHERE e.election_date = DATE '2026-11-03'
                    AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
                    AND rc2.id NOT IN (SELECT rc_id FROM cc0454_calls) LIMIT 1);

-- ─── Post-verify ─`, 'the post-verify header'),

  // V9 — the file must seat nobody. Plant a 2027-01-03 term on one of these two seats.
  // ⚠ REBUILT: a bare INSERT never reached V9. Both seats carry an OPEN-ENDED current term, and
  // an open-ended range covers every future date, so `office_terms_no_overlap` rejected the row
  // first — the schema shadowing the gate under test. Closing the sitting term the day before is
  // both what makes the insert legal and what a real seating migration does, so the control now
  // reproduces the actual mistake it is guarding against.
  V9: () => sub('-- ─── Post-verify ─',
    `UPDATE essentials.office_terms SET term_end = DATE '2027-01-02'
  WHERE office_id = (SELECT r.office_id FROM essentials.races r
                      WHERE r.id = 'd5edae06-65c7-4853-a15b-97731330295c'::uuid)
    AND term_end IS NULL;

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision,
                                     how_started, source)
SELECT r.office_id, rc.politician_id, DATE '2027-01-03', 'day', 'elected', 'control V9 CC_0454'
  FROM cc0454_calls c
  JOIN essentials.races r ON r.id = c.race_id
  JOIN essentials.race_candidates rc ON rc.id = c.rc_id
 WHERE c.result = 'won' AND c.seat = 'NC-03' LIMIT 1;

-- ─── Post-verify ─`, 'the post-verify header'),
};

const e = E[L]; if (!e) throw new Error(`unknown control ${L}`);
e();
if (s === before) throw new Error(`control ${L}: TAMPER DID NOT APPLY — file unchanged`);
if (s.length < 8000) throw new Error(`control ${L}: result is only ${s.length} bytes — truncated`);
fs.writeFileSync(DEST, s);
console.log(`control ${L}: tamper present (${before.length} -> ${s.length} bytes)`);
