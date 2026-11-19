// Build one tampered variant of CC_0456 and ASSERT THE FAULT IS PRESENT before it is run.
//
// 🔴 A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS:
//    dry-run-migration.mjs reports DRY RUN OK on a 0-byte file, because an empty migration
//    passes every gate it does not contain.
// 🔴 THE REPLACEMENT IS A FUNCTION, NEVER A STRING — in String.replace a `$$` in the
//    replacement is an escape for a single `$`, so an edit touching a dollar-quoted block
//    silently emits `$` and the file dies on a syntax error before reaching its gate.
// 🔴 EACH VARIANT CHANGES EXACTLY ONE THING THE SUITE CAN SEE. A tamper that trips three
//    assertions at once says the suite is alive but not which guard holds which claim.
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

const VARIANTS = {
  // A — 🔴🔴 THE ONE THAT MATTERS MOST. P5 is the only gate standing behind a human judgement:
  // which departing member's seat each at-large newcomer takes. Name the wrong person and the
  // file must refuse rather than seat Blades-Snell into a chair somebody else is sitting in.
  A: () => sub(
    "('e14ebd74-4cb2-5f6c-86a0-bbb97dc8c8eb'::uuid, 'Nancy Greenstein')",
    "('e14ebd74-4cb2-5f6c-86a0-bbb97dc8c8eb'::uuid, 'Rob Rader')",
    "P5's expected departing holder for the Santa Monica CCD seat"),

  // B — the pinned selection. Drop one office from the derivation and the count and the digest
  // must both stop matching. Proves P1 reads the rows it actually built, not a constant.
  // 🔴 THE FIRST DRAFT OF THIS CONTROL PROVED NOTHING AND PRINTED "DRY RUN OK". It excluded
  //    Altadena Library TA 3 — an office that carries no winner and was therefore never in the
  //    selection, so the edit applied cleanly and created no fault. The exclusion must name an
  //    office that IS selected; ABC Unified TA 2 is one, checked against production first.
  B: () => sub(
    "    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.result = 'won'\n), alrace AS (",
    "    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.result = 'won'\n   WHERE u.office_id <> '595e4e95-5eac-4ced-9ba3-79d3a7c39d97'::uuid\n), alrace AS (",
    "the single-seat derivation's row set"),

  // C — 🔴 `p_allow_reelection` GLOBALLY TRUE. This is the shape of the mistake worth catching:
  // it looks harmless, it makes the file "work", and it disarms the helper's own refusal on all
  // 72 rows — including the 32 seats that CHANGE HANDS, where that refusal is the guard.
  C: () => sub(
    '       (och.politician_id IS NOT DISTINCT FROM x.politician_id) AS allow_reelect',
    '       true AS allow_reelect -- TAMPER C',
    "the per-row allow_reelect derivation"),

  // D — 🔴🔴 THE CC_0434 REGRESSION, INSIDE THIS FILE'S OWN SCOPE. That file cleared
  // `is_vacant` across "every office this migration touched" and fired a new
  // DEAD_GEOGRAPHY ca|SCHOOL bucket within minutes. Injected after the write, so a pre-flight
  // gate cannot shadow it. Caught by V3b: a seat that closed no predecessor and no longer
  // reads vacant is a seat this file has quietly lied about.
  D: () => sub(
    '-- ─── Post-verify ──',
    `-- TAMPER D — the CC_0434 mistake, planted after the write.
UPDATE essentials.offices o SET is_vacant = false, vacant_since = NULL
 WHERE o.is_vacant AND EXISTS (SELECT 1 FROM cc0456_seatings s WHERE s.office_id = o.id);

-- ─── Post-verify ──`,
    'the post-verify header'),

  // E — 🔴 V5 IS A REPO-WIDE CLAIM AND D CANNOT TEST IT. D's flag clear lands inside the
  // selection, where the narrower V3b catches it first — a correct refusal at the wrong gate,
  // which leaves V5 untested and looks exactly like a working suite. This one clears the flag
  // on Altadena Library TA 3, a vacant office this file never touches, so V3b cannot see it and
  // only V5's repo-wide comparison is left to notice.
  E: () => sub(
    '-- ─── Post-verify ──',
    `-- TAMPER E — a flag cleared OUTSIDE this file's scope. V3b is blind to it by construction.
UPDATE essentials.offices SET is_vacant = false, vacant_since = NULL
 WHERE id = '6a08d6f1-900c-5675-a346-dbad51c309ea'::uuid;

-- ─── Post-verify ──`,
    'the post-verify header'),
};

const v = VARIANTS[LABEL];
if (!v) throw new Error(`unknown variant ${LABEL}`);
v();

if (s === before) throw new Error(`${LABEL}: EDIT DID NOT APPLY — file unchanged`);
if (s.length < 12000) throw new Error(`${LABEL}: result is only ${s.length} bytes — truncated`);
if ((s.match(/^BEGIN;$/gm) || []).length !== 1 || (s.match(/^COMMIT;$/gm) || []).length !== 1) {
  throw new Error(`${LABEL}: not exactly one transaction — the dry-run tool would commit for real`);
}
fs.writeFileSync(DEST, s);
console.log(`${LABEL}: fault present (${before.length} -> ${s.length} bytes)`);
