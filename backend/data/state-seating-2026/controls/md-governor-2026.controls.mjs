/**
 * Maryland Governor 2026 — the control suite run against `CC_0499` and `CC_0500` before they were
 * applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     data/state-seating-2026/controls/md-governor-2026.controls.mjs
 *
 * ⚠ **A SUITE CANNOT BE RE-RUN ONCE ITS CHAIN IS APPLIED** — the negative control fails and the
 *   harness refuses to report, which is correct. This file is the RECORD of what was tested.
 *
 * 🔴🔴 **A ONE-OFFICE WAVE IS THE EASIEST PLACE FOR A GATE TO PASS VACUOUSLY, WHICH IS WHY THIS
 *   SUITE EXISTS AT ALL.** Every count in these two files is 1 or 0, and a count of 1 is true of
 *   whoever happens to be in the selection. The controls that matter here are the ones that keep
 *   the size the same and change *which* office, *which* person or *which* day:
 *
 *     C4  the Governor dated with the GENERAL ASSEMBLY's real day — one row, wrong seat's rule
 *     C7  the selection pointed at the Attorney General — one row, wrong office
 *     C9  the Governor's recorded winner replaced — one row, wrong person
 *
 * 🔴 **THE NEAR MISS IN THIS WAVE IS LIVE DATA, NOT A HYPOTHETICAL.** 2027-01-13 is the second
 *   Wednesday and it is the whole General Assembly's real commencement, written by `CC_0494` for
 *   178 seats on 2026-11-24. C1 writes it onto the Governor and watches the file refuse.
 */
const M = '../../../migrations';
const f = (name) =>
  new URL(`${M}/${name}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

export default {
  name: 'Maryland Governor 2026 — CC_0499 / CC_0500',
  files: {
    dates: f('CC_0499_md_governor_2026_swearing_in_date.sql'),
    seating: f('CC_0500_md_governor_2026_seat_1_winner.sql'),
  },
  cleanChain: ['dates', 'seating'],
  controls: [
    // ── CC_0499, the dates file ───────────────────────────────────────────────────────────────
    {
      // 🔴🔴 THE NEAR MISS IS 178 LIVE ROWS IN THIS STATE. Writing the General Assembly's own day
      //    onto the Governor is the single most plausible error here, and it produces a real
      //    Maryland date rather than an absurd one.
      id: 'C1',
      label: "write 2027-01-13 — the SECOND Wednesday, which is the General Assembly's real day",
      aimedAt: 'assertion 2b',   // fired on assertion 1: a strict equality on the right date
                                 // catches ANY wrong day first, so 2b's "carries a wrong Wednesday"
                                 // arm is an unreachable backstop. Its arithmetic arms are
                                 // reachable and C2 tests them.
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-20',\n       'statute',",
        replace: "       DATE '2027-01-13',\n       'statute',",
      }],
    },
    {
      id: 'C2',
      label: 'the third Wednesday computed as the second',
      aimedAt: 'assertion 2a',
      chain: [{
        tamper: 'dates',
        find: '  third_wed  := first_wed + 14;\n  fourth_wed := first_wed + 21;',
        replace: '  third_wed  := first_wed + 7;\n  fourth_wed := first_wed + 21;',
      }],
    },
    {
      // 🟢🟢 THE ONLY CORROBORATION THIS DATE HAS IN OUR OWN DATA. Wes Moore's 2023-01-18 was
      //    backfilled from msa.maryland.gov and never derived from Art. II § 1. Moving the
      //    expectation to the FIRST Wednesday of 2023 must break assertion 3a — otherwise the
      //    gate is not reading the clause at all.
      id: 'C3',
      label: "assertion 3 expects Wes Moore's term to have begun on 2023-01-04",
      aimedAt: 'assertion 3a',
      chain: [{
        tamper: 'dates',
        find: "        moore_start   CONSTANT date := DATE '2023-01-18';   -- migration 1459, from the Archives",
        replace: "        moore_start   CONSTANT date := DATE '2023-01-04';   -- migration 1459, from the Archives",
      }],
    },
    {
      // 🔴🔴 THE DISCRIMINATING ARM. Assertion 3c requires the SECOND Wednesday of January 2023
      //    to carry ZERO Maryland terms. One row on the third against zero on the second is what
      //    separates the two rules; agreement with one of them proves nothing. Moving Moore's
      //    own term onto the second Wednesday must make it go red.
      id: 'C4',
      label: "Wes Moore's 2023 term moved onto the SECOND Wednesday (2023-01-11)",
      aimedAt: 'assertion 3c',   // fired on 3b: moving Moore's term breaks the corroboration
                                 // check before the discriminating one can read the second
                                 // Wednesday. One row is the whole corpus, so the two arms
                                 // cannot be separated by any tamper that moves it.
      chain: [{
        sql: `UPDATE essentials.office_terms t
   SET term_start = DATE '2023-01-11'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
   AND o.title = 'Governor' AND t.term_end IS NULL;`,
      }, 'dates'],
    },
    {
      // 🔴 MARYLAND IS THE SECOND STATE ON 2027-01-20. P4 requires every row already there to
      //    belong to a NAMED rule, so a third state is caught rather than absorbed.
      id: 'C5',
      label: 'a Massachusetts 2027-01-20 row given an unknown rule_id',
      aimedAt: 'P4',
      chain: [{
        sql: `UPDATE essentials.office_swearing_in
   SET rule_id = 'control-c5-some-third-state-rule'
 WHERE (office_id, election_date) = (
   SELECT office_id, election_date FROM essentials.office_swearing_in
    WHERE swearing_in_date = DATE '2027-01-20'
    ORDER BY office_id, election_date LIMIT 1);`,
      }, 'dates'],
    },
    {
      // 🔴 THE REFUSALS. The Attorney General and the Comptroller have no day in law. Widening
      //    the selection to the whole STATE_EXEC tier dates all three.
      id: 'C6',
      label: 'the selection widened from the Governor to every Maryland state executive',
      aimedAt: 'P1',
      chain: [{
        tamper: 'dates',
        find: "   AND o.title = 'Governor'\n   AND w.election_date = DATE '2026-11-03';",
        replace: "   AND w.election_date = DATE '2026-11-03';",
      }],
    },
    {
      // 🔴🔴 THE SAME SIZE, THE WRONG OFFICE. One row is written either way, every count still
      //    reads 1, and only assertion 7 — which checks what the row IS — can tell them apart.
      //    This is the control a one-office wave most needs.
      id: 'C7',
      label: 'the selection pointed at the Attorney General instead of the Governor',
      aimedAt: 'assertion 7',    // fired on assertion 5: "no Maryland executive other than the
                                 // Governor was dated" sees the wrong office before the row's own
                                 // identity check reaches it. A real gate, and a better message —
                                 // it names the REFUSAL that was broken rather than the row that
                                 // reads oddly.
      chain: [{
        tamper: 'dates',
        find: "   AND o.title = 'Governor'\n   AND w.election_date = DATE '2026-11-03';",
        replace: "   AND o.title = 'Attorney General'\n   AND w.election_date = DATE '2026-11-03';",
      }],
    },
    {
      // 🔴 A CITATION CAN BE RIGHT ABOUT THE DATE AND WRONG ABOUT THE LAW. Art. II § 3 names the
      //    SAME DAY for the QUALIFICATION and then allows it to slip; § 1 is the TERM. No count
      //    can see the difference, which is why assertion 7 reads the authority text.
      id: 'C8',
      label: 'the row cites Art. II § 3 (the QUALIFICATION) instead of § 1 (the TERM)',
      aimedAt: 'assertion 7',
      chain: [{
        tamper: 'dates',
        find: "       'Md. Const. Art. II, § 1 — \"The executive power of the State shall be vested in a '",
        replace: "       'Md. Const. Art. II, § 3 — \"The executive power of the State shall be vested in a '",
      }],
    },
    {
      // 🔴🔴 THE LIEUTENANT GOVERNOR'S GAP, ARRIVING. Its term is this same day under Art. II
      //    § 1B, so a race row appearing makes this a two-office wave and both files stale.
      id: 'C9',
      label: "the Maryland Lieutenant Governor gains a 2026 race row",
      aimedAt: 'P5',
      chain: [{
        sql: `INSERT INTO essentials.races (election_id, office_id, position_name, seats)
SELECT (SELECT e.id FROM essentials.elections e
          WHERE e.election_date = DATE '2026-11-03' LIMIT 1),
       o.id, 'CONTROL C9 — must never reach production', 1
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'md' AND o.title = 'Lieutenant Governor';`,
      }, 'dates'],
    },

    // ── CC_0500, the seating file ─────────────────────────────────────────────────────────────
    {
      // 🔴🔴 THE SAME SIZE, THE WRONG PERSON. The selection still returns exactly one row and
      //    every count still reads 1; only the digest and the name check can see it. This is the
      //    whole argument for giving a one-row wave the full gate set.
      id: 'C10',
      label: "the Governor's recorded winner replaced with the Comptroller's",
      aimedAt: 'P3 digest',
      chain: ['dates', {
        sql: `UPDATE essentials.race_candidates rc
   SET politician_id = (SELECT rc2.politician_id
                          FROM essentials.race_candidates rc2
                          JOIN essentials.races r2 ON r2.id = rc2.race_id
                          JOIN essentials.offices o2 ON o2.id = r2.office_id
                          JOIN essentials.districts d2 ON d2.id = o2.district_id
                         WHERE lower(d2.state) = 'md' AND o2.title = 'Comptroller'
                           AND rc2.result = 'won' LIMIT 1)
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03' AND rc.result = 'won'
   AND lower(d.state) = 'md' AND o.title = 'Governor';`,
      }, 'seating'],
    },
    {
      // The re-election flag is what lets seat_officeholder close Moore's own term and open the
      // next. Inverting it makes the file claim a handover that is not happening.
      id: 'C11',
      label: 'the re-election test inverted',
      aimedAt: 'P3',
      chain: ['dates', {
        tamper: 'seating',
        find: "         AND och.politician_id::text = (win.value ->> 'id')) AS is_reelection,",
        replace: "         AND och.politician_id::text <> (win.value ->> 'id')) AS is_reelection,",
      }],
    },
    {
      // 🔴 THE PREDECESSOR'S START IS THE ONLY CORROBORATION CC_0499's RULE HAS IN OUR OWN DATA.
      //    If it moves, the evidence for the day this wave writes is gone — so P6 pins it.
      id: 'C12',
      label: "Wes Moore's 2023 term_start moved to the first Wednesday",
      aimedAt: 'P6',
      chain: ['dates', {
        sql: `UPDATE essentials.office_terms t
   SET term_start = DATE '2023-01-04'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
   AND o.title = 'Governor' AND t.term_end IS NULL;`,
      }, 'seating'],
    },
    {
      // 🔴 THE COVERAGE GATE. With one row, a NULL is_reelection empties the digest entirely —
      //    `string_agg` over nothing is NULL, and a NULL digest is not the pinned one. The
      //    vacancy is planted and the library's published expression (no IS NOT NULL) restored.
      id: 'C13',
      label: "the Governor's seat falls vacant AND the published is_reelection is used",
      aimedAt: 'P3 coverage',
      chain: ['dates', {
        sql: `UPDATE essentials.office_terms t
   SET term_end = DATE '2026-11-20', how_ended = 'resigned'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
   AND o.title = 'Governor' AND t.term_end IS NULL;`,
      }, {
        tamper: 'seating',
        find: "       ((win.value ->> 'id') IS NOT NULL\n         AND och.politician_id IS NOT NULL\n         AND och.politician_id::text = (win.value ->> 'id')) AS is_reelection,",
        replace: "       ((win.value ->> 'id') IS NOT NULL\n         AND och.politician_id::text = (win.value ->> 'id')) AS is_reelection,",
      }],
    },
    {
      // 🔴🔴 THE LIEUTENANT GOVERNOR SEATED BY MISTAKE. Its term IS this same day under Art. II
      //    § 1B, so a file that reached for "every Maryland executive whose term begins here"
      //    would seat an office nobody has recorded a winner for.
      id: 'C14',
      label: 'the seating selection widened to every Maryland state executive',
      aimedAt: 'P2',
      chain: ['dates', {
        tamper: 'seating',
        find: "   AND o.title = 'Governor'\n   AND w.election_date = DATE '2026-11-03';\n\nCREATE TEMP TABLE cc0500_pre",
        replace: "   AND w.election_date = DATE '2026-11-03';\n\nCREATE TEMP TABLE cc0500_pre",
      }],
    },
    {
      // Ruling B: the wave seats from a CALLED result and says so.
      id: 'C15',
      label: "the Governor's result becomes certified",
      aimedAt: 'P10',
      chain: ['dates', {
        sql: `UPDATE essentials.race_candidates rc
   SET result_certainty = 'certified'
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'md' AND o.title = 'Governor';`,
      }, 'seating'],
    },
    {
      id: 'C16',
      label: 'the written term source stops saying "called, not certified"',
      aimedAt: 'assertion 13',
      chain: ['dates', {
        tamper: 'seating',
        find: "                         || 'called, not certified, when this ran. Term begins '",
        replace: "                         || 'when this ran. Term begins '",
      }],
    },
    {
      // 🔴 THE 178 MUST STAY A WEEK EARLIER. Assertion 9b is the only thing in this wave that
      //    looks back at CC_0496's work and checks this file did not disturb it.
      id: 'C17',
      label: "one General Assembly term moved off 2027-01-13",
      aimedAt: 'assertion 9b',   // fired on P9: moving a term onto 2027-01-20 changes the
                                 // before-image of the shared day, which is checked first.
      chain: ['dates', {
        sql: `UPDATE essentials.office_terms t
   SET term_start = DATE '2027-01-20'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
   AND t.term_start = DATE '2027-01-13'
   AND t.id = (SELECT t2.id FROM essentials.office_terms t2
                 JOIN essentials.offices o2 ON o2.id = t2.office_id
                 JOIN essentials.districts d2 ON d2.id = o2.district_id
                WHERE lower(d2.state) = 'md' AND t2.term_start = DATE '2027-01-13'
                ORDER BY t2.id LIMIT 1);`,
      }, 'seating'],
    },
  ],
};
