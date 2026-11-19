// Build one variant of CC_0455 and ASSERT THE EDIT IS PRESENT.
// 🔴 A tamper that did not apply is a control that proved nothing, and it looks like a pass:
// dry-run-migration.mjs reports DRY RUN OK on a 0-byte file, because an empty migration passes
// every gate it does not contain.
// 🔴 The replacement is a FUNCTION, never a string — in String.replace a `$$` in the replacement
// is an escape for a single `$`, so an edit touching a `DO $$` block silently emits `DO $`.
import fs from 'node:fs';

const [LABEL, SRC, DEST] = process.argv.slice(2);
const before = fs.readFileSync(SRC, 'utf8');
let s = before;

const sub = (find, repl, what) => {
  const n = s.split(find).length - 1;
  if (n === 0) throw new Error(`${LABEL}: anchor NOT FOUND — ${what}`);
  if (n > 1) throw new Error(`${LABEL}: anchor occurs ${n} times — ${what}`);
  s = s.replace(find, () => repl);
};

// Relax the date gate. Every variant needs this: the calendar cannot be moved, and P1 is proven
// separately by running the file UNEDITED (it refuses, which is the control for P1 itself).
const relaxP1 = () =>
  sub("IF CURRENT_DATE < DATE '2027-01-03' THEN", 'IF false THEN -- P1 RELAXED FOR REHEARSAL',
      'the P1 date comparison');

// Make the two seats genuinely held TODAY, which is the only thing 2027-01-03 changes about the
// world this file reads. Backdating the term start is faithful: these offices hold exactly ONE
// term row each, so there is no overlap partner and `office_terms_no_overlap` cannot shadow it.
const seatThemToday = () =>
  sub('-- ─── Pre-flight ─',
`-- REHEARSAL SETUP — simulate 2027-01-03 by starting the already-written terms today.
UPDATE essentials.office_terms t
   SET term_start = CURRENT_DATE
  FROM cc0455_seats c
 WHERE t.office_id = c.office_id
   AND t.term_start = DATE '2027-01-03';

-- ─── Pre-flight ─`, 'the pre-flight header');

// Neuter P4 so a LATER gate can be reached. P4 is the "somebody must hold the seat" check and it
// correctly shadows V3; to test V3 at all, P4 must be stood down.
const neuterP4 = () =>
  sub("SELECT string_agg(c.seat || ' (' || c.expect_incoming || ')', ', ') INTO bad",
      'SELECT NULL::text INTO bad -- P4 NEUTERED FOR CONTROL B', "P4's finding query");

const VARIANTS = {
  // R — THE REHEARSAL. The file as it will run on 2027-01-03. Everything must PASS.
  R: () => { relaxP1(); seatThemToday(); },

  // A — 🔴 THE FILE RUN EARLY, WITH ONLY THE DATE GATE REMOVED. P4 must catch it: the seats are
  // empty, and clearing the flag on an unseated office is the documented way to create
  // DEAD_GEOGRAPHY. This proves P1 is not the only thing standing between today and that mistake.
  A: () => { relaxP1(); },

  // B — 🔴🔴 BOTH SAFETY GATES STOOD DOWN. Reaches the write with no officeholder, so the two
  // districts end with offices > 0, active_holders = 0, vacant_offices = 0. V3 must fire. This is
  // the master-only reachability check carried into the file, and it is the one gate whose whole
  // purpose is to catch what P1 exists to prevent.
  B: () => { relaxP1(); neuterP4(); },
};

const v = VARIANTS[LABEL];
if (!v) throw new Error(`unknown variant ${LABEL}`);
v();

if (s === before) throw new Error(`${LABEL}: EDIT DID NOT APPLY — file unchanged`);
if (s.length < 6000) throw new Error(`${LABEL}: result is only ${s.length} bytes — truncated`);
if ((s.match(/^BEGIN;$/gm) || []).length !== 1 || (s.match(/^COMMIT;$/gm) || []).length !== 1) {
  throw new Error(`${LABEL}: not exactly one transaction — the dry-run tool would commit for real`);
}
fs.writeFileSync(DEST, s);
console.log(`${LABEL}: edit present (${before.length} -> ${s.length} bytes)`);
