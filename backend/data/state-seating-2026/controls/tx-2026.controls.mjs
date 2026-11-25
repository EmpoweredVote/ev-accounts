/**
 * Texas 2026 — the control suite for `CC_0513` (dates), `CC_0514` (12 seats on 2027-01-01) and
 * `CC_0515` (the Governor and Lieutenant Governor on 2027-01-19), run 2026-11-25 before any of
 * the three was applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     data/state-seating-2026/controls/tx-2026.controls.mjs
 *
 * ⚠ **ONCE THE CHAIN IS APPLIED THIS SUITE CANNOT BE RE-RUN, AND THAT IS CORRECT.** The negative
 *   control fails and the harness refuses to report. It is kept as the RECORD of what was tested.
 *   `--check` validates every needle without touching the database.
 *
 * ── WHAT THIS STATE MADE DIFFERENT ──────────────────────────────────────────────────────────
 *
 * 🔴🔴 **TWO DEFECTS WERE FOUND BY RUNNING THINGS RATHER THAN BY READING THEM, AND BOTH ARE NOW
 *   CONTROLS.** Neither was a date error, and no count, digest or review would have caught
 *   either.
 *
 *   • **C16 — the closure day is SHARED, and the first rehearsal of `CC_0514` fired on 68
 *     innocent rows.** Its assertion 6c asked, as a TOTAL, that no term outside the pre-image
 *     ends on 2026-12-31. But that is the day *before* 2027-01-01, so Utah's 50 and New Mexico's
 *     11 seatings closed their own predecessors on it — 68 terms already ended there. The gate
 *     reported real, correct rows as a fault. ▶ **The shared-square rule reaches `term_end`, a
 *     column nobody thinks of as a date**, and 6c is now a delta plus a Texas scope.
 *   • **C17 — a migration's `source` narrative named its sibling's slot, and Ruling B recovers a
 *     wave with `source LIKE '%<slot>%'`.** `CC_0514`'s prose explained what `CC_0515` does and
 *     named it, so all 12 of its rows answered to `CC_0515`'s own P1 — the chain aborted with
 *     *"12 office_terms row(s) already cite CC_0515. Applied before."* **The prose was correct
 *     and the recovery key was poisoned.** ▶ A cross-reference belongs in the header, never in a
 *     column a recovery query matches on. Both seating files now carry a `7b` gate for it, and
 *     C17 re-plants the exact text that caused it.
 *
 * 🟢🟢 **C6 IS THE CONTROL ON THE GATE THAT CAUGHT THE DOCUMENTS.** `DATES.md § TX`'s prose and
 *   `PICKUP.md`'s handoff both say **eleven** offices take 2027-01-01; the table in the same
 *   section says 5 + 7, and production says **12**. Had the file been written from the prose it
 *   would have dated eleven, and `CC_0514`'s P4 would have refused the twelfth seat **after**
 *   writing eleven terms. C6 plants `11` as `CC_0513`'s Group A expectation and watches P1 go
 *   red — so the gate that corrected two documents has a control of its own.
 *
 * 🔴🔴 **C7 AND C18 ARE THE ONLY MECHANICAL TRACE OF THE WASHINGTON DEFECT IN THIS STATE.**
 *   Art. IV § 4 installs the **Governor** and names the Lieutenant Governor nowhere;
 *   § 601.003(c) excludes that office too; so Art. IV § 16(a) is the only instrument that dates
 *   it. `DATES.md` cites § 4 for both. **The DATE is right either way**, so no count, digest or
 *   view can tell the correct citation from the wrong one — only a gate that reads the
 *   `authority` text and the `rule_id` can. C7 strips § 16(a) from the Lieutenant Governor's
 *   authority; C18 gives that office the Governor's `rule_id`.
 *
 * 🔴🔴 **C5 IS A CONTROL ON A CHECK KEPT IN ORDER TO PASS — AND THE CHECK IS AN IDENTITY.**
 *   `CC_0513`'s assertion 3c asserts that "the first Tuesday after the second Tuesday" and "the
 *   third Tuesday" agree in **all 39** odd years 1975–2051, because they are the same rule and
 *   this file must not claim to have refused a tautology. Nothing else in the suite would ever
 *   make that number move. This is Idaho's C4 and Connecticut's C5, on a third shape: a gate kept
 *   green on purpose still needs a control.
 *
 * 🔴🔴 **C8 IS THE ARIZONA CORPORATION COMMISSION, REACHED FROM THE DATING SIDE.** Texas holds
 *   **three** `Texas Railroad Commissioner` rows in one district, all identically titled, all
 *   held, and only one up — a staggered body. Ruling A's rule is not needed (the race is
 *   single-seat and already attached to the leaving member's seat) but its *counter-example*
 *   shape is present, and the dating risk is the mirror of Maryland's: a selection that expanded
 *   to the sibling titles would date two commissioners whose terms run on. C8 makes exactly that
 *   expansion.
 *
 * 🔴🔴 **AND THE FIRST RUN FOUND TWO MORE DEFECTS, BOTH IN GATES THIS SUITE WAS WRITTEN TO
 *   TEST — WHICH IS THE WHOLE ARGUMENT FOR RUNNING CONTROLS RATHER THAN REVIEWING GATES.**
 *
 *   • **C7 CAME BACK GREEN.** `CC_0513`'s assertion 7 asked whether the Lieutenant Governor's
 *     authority contained `'§ 16(a)'` **anywhere**. It does — twice — because the text goes on to
 *     explain that § 4 names only the Governor. So swapping the OPENING citation to § 4 left the
 *     gate satisfied **by the sentence that explains the distinction the gate exists to enforce**.
 *     ▶ A citation is the instrument a row is dated UNDER: a claim about the front of the field,
 *     not about whether a string occurs in it. Assertion 7 now checks all three groups' authority
 *     by `LIKE 'prefix%'`, and C7 trips it.
 *   • **C8 FIRED ON P1, TWO GATES ABOVE ITS TARGET** — a sibling EXPANSION adds rows, so the total
 *     refuses it before the Railroad Commission arm is reached. That is recorded as a backstop
 *     below; **C22 is the tamper that reaches P5**, by SWAPPING the selected commissioner instead
 *     of adding one, which leaves every count in the file correct. The first P5 counted selected
 *     siblings to one and passed while dating a commissioner who is not leaving; it now asserts
 *     the selected row **carries the 2026 race**, which is the only thing that tells the three
 *     identical rows apart. ▶ `CLAUDE.md`'s *a predicate reads the SHAPE of a value, never what
 *     the value is* — reached through a count.
 *
 * ── WHAT IS NOT TESTED, AND WHY ─────────────────────────────────────────────────────────────
 *
 * Recorded as **backstops, not tested gates**:
 *
 * • **C8's target, `CC_0513`'s P5 sibling-expansion arm**, is unreachable by an expansion tamper
 *   because P1's total catches it first. Two gates catching one fault is what hides it, so the
 *   expansion arm is covered by P1 and the arm that matters is tested by C22 instead.
 * • **`CC_0514`'s P3 name list and P6 predecessor-identity arms** sit below the pinned digest, so
 *   any realistic tamper moves the digest two gates earlier. Measured, not assumed: C12 swaps a
 *   winner and fires on P3's digest, never on the name list.
 * • **`CC_0515`'s assertion 3 "no other state on 2027-01-19"** cannot be made to discriminate:
 *   the day carries **0 rows** before this file, so there is no stranger to plant that would not
 *   also be a stranger to assertion 3b. ⚠ `CC_0513`'s note says this outright rather than letting
 *   an empty-day gate read as a measurement.
 * • **`CC_0514`'s assertion 5 vacancy arm** has no fixture here: 0 of 14 Texas offices are flagged
 *   `is_vacant`, so C15 plants one rather than finding one. A planted fixture proves the gate
 *   FIRES; it does not prove it reads the rows a real flagged seat would occupy.
 */
const M = '../../../migrations';
const p = (f) => new URL(`${M}/${f}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

/** One Texas state office, by title, for a data tamper. */
const office = (title) => `
  SELECT o.id FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx'
     AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD_EDUCATION')
     AND o.title = '${title}'`;

export default {
  name: 'Texas 2026 — CC_0513 / CC_0514 / CC_0515',
  files: {
    dates: p('CC_0513_tx_2026_swearing_in_dates.sql'),
    seatA: p('CC_0514_tx_2026_seat_12_winners.sql'),
    seatB: p('CC_0515_tx_2026_seat_governor_lt_governor.sql'),
  },
  cleanChain: ['dates', 'seatA', 'seatB'],
  controls: [
    // ── CC_0513, the dates file ───────────────────────────────────────────────────────────────
    {
      // 🔴🔴 THE NEAR MISS THAT IS 241 LIVE ROWS. Reaching for "the first Monday in January"
      //    produces Wisconsin's, Arizona's, California's and Idaho's correct answer — never an
      //    absurd one. That is the whole reason this file computes rival rules at all.
      id: 'C1',
      label: "Group A written to 2027-01-04 — the first Monday, and 241 live rows in four states",
      aimedAt: 'assertion 1',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-01',\n       'statute',\n       'tx-govt-code-601-003-january-1',",
        replace: "       DATE '2027-01-04',\n       'statute',\n       'tx-govt-code-601-003-january-1',",
      }],
    },
    {
      // 🔴🔴 AND THE OTHER LIVE NEAR MISS IS ALABAMA'S DAY. A Monday misreading of Art. IV § 4
      //    lands the Texas Governor inside another state's cluster of 13.
      id: 'C2',
      label: "the Governor written to 2027-01-18 — the third MONDAY, which is Alabama's live day",
      aimedAt: 'assertion 1',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-19',\n       'statute',\n       'tx-const-art4-s4-installation',",
        replace: "       DATE '2027-01-18',\n       'statute',\n       'tx-const-art4-s4-installation',",
      }],
    },
    {
      // 🔴 "FIRST TUESDAY *AFTER* THE ORGANIZATION" READ AS "ON THE ORGANISATION". The walk starts
      //    the day AFTER the convening so the word "after" is in the arithmetic; drop the +1 and
      //    the clause collapses onto the convening day itself, 2027-01-12.
      id: 'C3',
      label: 'the installation walk started ON the convening day instead of after it',
      aimedAt: 'assertion 3b',
      chain: [{
        tamper: 'dates',
        find: '  installs  := (convenes + 1) + ((2 - EXTRACT(ISODOW FROM (convenes + 1))::int + 7) % 7);',
        replace: '  installs  := (convenes) + ((2 - EXTRACT(ISODOW FROM (convenes))::int + 7) % 7);',
      }],
    },
    {
      // 🔴 § 301.001's SECOND Tuesday read as the first — the convening day a week early, which
      //    moves the installation a week early with it.
      id: 'C4',
      label: "Gov't Code § 301.001's second Tuesday mis-derived as the first",
      aimedAt: 'assertion 3b',
      chain: [{
        tamper: 'dates',
        find: '  convenes  := first_tue + 7;',
        replace: '  convenes  := first_tue;',
      }],
    },
    {
      // 🔴🔴 A CONTROL ON A CHECK KEPT IN ORDER TO PASS, AND THE CHECK IS AN IDENTITY. 3c asserts
      //    that the third Tuesday IS the first Tuesday after the second, in all 39 odd years, so
      //    the file cannot claim to have refused a restatement of its own rule. Nothing else in
      //    this suite would ever move that number.
      id: 'C5',
      label: '🔴 the tautology gate expects 38 of 39 years instead of the measured 39',
      aimedAt: 'assertion 3c',
      chain: [{
        tamper: 'dates',
        find: '  identity_yrs CONSTANT int  := 39;  -- odd years 1975..2051 where the two statements of § 4 agree',
        replace: '  identity_yrs CONSTANT int  := 38;  -- odd years 1975..2051 where the two statements of § 4 agree',
      }],
    },
    {
      // 🟢🟢 THE LEDGER'S OWN ERROR, PLANTED. DATES.md § TX's prose and PICKUP.md both say
      //    "eleven"; the table says 5 + 7 and production says 12. A file written from the prose
      //    would have dated eleven and CC_0514's P4 would have refused the twelfth AFTER writing
      //    the other eleven's terms. This is the control on the gate that corrected two documents.
      id: 'C6',
      label: "🔴 Group A expected as ELEVEN — the number DATES.md and PICKUP.md both print",
      aimedAt: 'P1',
      chain: [{
        tamper: 'dates',
        find: "  SELECT count(*) INTO n FROM cc0513_sel WHERE grp = 'A';\n  IF n <> 12 THEN",
        replace: "  SELECT count(*) INTO n FROM cc0513_sel WHERE grp = 'A';\n  IF n <> 11 THEN",
      }],
    },
    {
      // 🔴🔴 THE WASHINGTON DEFECT, AND THE ONLY GATE THAT CAN SEE IT. Art. IV § 4 installs the
      //    GOVERNOR; the Lieutenant Governor is carried by § 16(a). The DATE is right either way,
      //    so a wrong citation is invisible to every count, digest and view. Strip § 16(a) from
      //    the authority and only assertion 7's text check notices.
      id: 'C7',
      label: "🔴 the Lieutenant Governor's authority citing § 4 instead of § 16(a)",
      aimedAt: 'assertion 7 (the § 16(a) arm)',
      chain: [{
        tamper: 'dates',
        find: "       'Tex. Const. Art. IV, § 16(a) — \"There shall also be a Lieutenant Governor, who shall be '",
        replace: "       'Tex. Const. Art. IV, § 4 — \"There shall also be a Lieutenant Governor, who shall be '",
      }],
    },
    {
      // 🔴🔴 THE ARIZONA CORPORATION COMMISSION, FROM THE DATING SIDE. Widen the selection to the
      //    sibling titles and two commissioners whose terms run to other cycles are dated
      //    2027-01-01. Every interchangeability clause would pass; only the equality of
      //    "pending rows" to "selected rows" refuses it.
      id: 'C8',
      label: '🔴 the selection widened to every Railroad Commissioner row — a sibling expansion',
      aimedAt: 'P5 (the Railroad Commission arm)',
      chain: [{
        tamper: 'dates',
        find: "   AND w.election_date = DATE '2026-11-03';\n\n-- The three Railroad Commissioner rows",
        replace:
          "   AND w.election_date = DATE '2026-11-03'\nUNION\nSELECT o.id, o.title, d.label, d.district_type, 'A'\n"
          + "  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id\n"
          + " WHERE lower(d.state) = 'tx' AND o.title = 'Texas Railroad Commissioner';\n\n"
          + '-- The three Railroad Commissioner rows',
      }],
    },
    {
      // 🔴 THE BOARD'S OWN ARITHMETIC. § 7.104(a) puts SEVEN of fifteen on this odd year's
      //    boundary and seven is what was pending — a cohort check independent of any date
      //    source. Expect eight (the other half of the stagger) and it must refuse.
      id: 'C9',
      label: "the Board cohort expected as EIGHT — § 7.104(a)'s other half of the stagger",
      aimedAt: 'assertion 3f',
      chain: [{
        tamper: 'dates',
        find: '  exp_sboe     CONSTANT int  := 7;',
        replace: '  exp_sboe     CONSTANT int  := 8;',
      }],
    },
    {
      // 🔴🔴 THE 181 ABSENT LEGISLATIVE SEATS, WITH A REAL FIXTURE. § 601.003(c) excludes them by
      //    name, so this gate is the statute's own exclusion as a measurement. The fixture gives
      //    one Texas House seat a 2026 race row — which is the shape that would make this wave
      //    larger than its pin.
      id: 'C10',
      label: '🔴 a Texas House seat given a 2026 race, which § 601.003(c) excludes by name',
      aimedAt: 'P6 (the legislative-race arm)',
      chain: [
        {
          sql: `INSERT INTO essentials.races (election_id, office_id, position_name, seats)
                SELECT (SELECT e.id FROM essentials.elections e
                         WHERE e.election_date = DATE '2026-11-03'
                           AND e.election_type = 'general' LIMIT 1),
                       o.id, 'TX House (control fixture)', 1
                  FROM essentials.offices o
                  JOIN essentials.districts d ON d.id = o.district_id
                 WHERE lower(d.state) = 'tx' AND d.district_type = 'STATE_LOWER'
                 LIMIT 1;`,
        },
        'dates',
      ],
    },
    {
      // 🔴 THE RIVAL ARITHMETIC ITSELF. 3d computes four wrong days and asserts each is the day it
      //    claims; break the third Monday and the refusals below it prove nothing.
      id: 'C11',
      label: 'the third-Monday near miss mis-derived as the second',
      aimedAt: 'assertion 3d (the arithmetic arm)',
      chain: [{
        tamper: 'dates',
        find: '  r_third_mon := r_first_mon + 14;',
        replace: '  r_third_mon := r_first_mon + 7;',
      }],
    },

    // ── CC_0514, the twelve seats on 2027-01-01 ───────────────────────────────────────────────
    {
      // 🔴 SWAP TWO WINNERS BETWEEN SEATS. ⚠ MEASURED AS A BACKSTOP: this fires on the DIGEST, two
      //    gates above the name list, which is why the name list is recorded as untested.
      id: 'C12',
      label: 'two Board winners swapped between their districts',
      aimedAt: 'P3 digest',
      chain: [
        'dates',
        {
          sql: `UPDATE essentials.race_candidates rc
                   SET politician_id = CASE rc.politician_id
                         WHEN (SELECT id FROM essentials.politicians WHERE full_name = 'Allison Bush')
                           THEN (SELECT id FROM essentials.politicians WHERE full_name = 'Michelle Palmer')
                         ELSE (SELECT id FROM essentials.politicians WHERE full_name = 'Allison Bush')
                       END
                 WHERE rc.result = 'won'
                   AND rc.politician_id IN (
                         SELECT id FROM essentials.politicians
                          WHERE full_name IN ('Allison Bush', 'Michelle Palmer'));`,
        },
        'seatA',
      ],
    },
    {
      // 🔴🔴 THE DUAL-SEAT GATE, WHICH IS KEPT IN ORDER TO PASS. Three winners keep a legislative
      //    seat because those seats have no 2026 result, and P8b asserts exactly three BY NAME so
      //    a fourth is caught rather than absorbed. Nothing else moves this number.
      id: 'C13',
      label: '🔴 the dual-seat count expected as 2 instead of the measured 3',
      aimedAt: 'P8b',
      chain: ['dates', {
        tamper: 'seatA',
        find: '       3                                  AS expect_dual_seat,',
        replace: '       2                                  AS expect_dual_seat,',
      }],
    },
    {
      // 🔴 THE PREDECESSOR PRE-IMAGE. All twelve are undated, which is unusual enough to be pinned
      //    rather than assumed — Texas's only dated state term belongs to CC_0515's wave.
      id: 'C14',
      label: 'a predecessor given a term_start, so the "all twelve undated" pin stops holding',
      aimedAt: 'P6 (the predecessors-dated arm)',
      chain: [
        'dates',
        {
          sql: `UPDATE essentials.office_terms SET term_start = DATE '2023-01-01'
                 WHERE office_id IN (${office('Texas Comptroller')}) AND term_start IS NULL;`,
        },
        'seatA',
      ],
    },
    {
      // ⚠ NO SEAT IS FLAGGED is_vacant IN TEXAS, so this fixture plants one. A planted fixture
      //   proves the gate FIRES; it does not prove it reads the rows a real flagged seat occupies.
      id: 'C15',
      label: 'a seat flagged is_vacant, which a future-dated seating must refuse rather than clear',
      aimedAt: 'P6 (the vacancy arm)',
      chain: [
        'dates',
        { sql: `UPDATE essentials.offices SET is_vacant = true WHERE id IN (${office('Texas Attorney General')});` },
        'seatA',
      ],
    },
    {
      // 🔴🔴 THE DEFECT THE FIRST REHEARSAL FOUND, RE-PLANTED. 6c asked as a TOTAL that nothing
      //    outside the pre-image ends on 2026-12-31 — and 68 terms already did, because that is
      //    the day before 2027-01-01 and Utah and New Mexico closed their predecessors there. The
      //    gate reported real rows as a fault. ▶ Reverting it to the total form is the control
      //    that proves the delta was necessary, and it goes red on innocent data.
      id: 'C16',
      label: '🔴 assertion 6c reverted to a TOTAL — the form that fired on 68 innocent rows',
      aimedAt: 'assertion 6c',
      chain: ['dates', {
        tamper: 'seatA',
        find: "  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_end = p.expect_predecessor_end;\n  IF n - b.terms_ending_prev <> p.expect_predecessors THEN",
        replace: "  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_end = p.expect_predecessor_end;\n  IF n <> p.expect_predecessors THEN",
      }],
    },
    {
      // 🔴🔴 THE OTHER DEFECT THE FIRST REHEARSAL FOUND, RE-PLANTED. Naming a sibling slot in the
      //    `source` narrative makes these rows answer to THAT wave's recovery query — Ruling B
      //    recovers with `source LIKE '%<slot>%'`. The chain aborted at CC_0515's P1 with "12
      //    office_terms row(s) already cite CC_0515".
      id: 'C17',
      label: "🔴 the sibling slot put back into this wave's source, poisoning Ruling B's recovery key",
      aimedAt: 'assertion 7b',
      chain: ['dates', {
        tamper: 'seatA',
        find: "                         || 'state senator, state representative — and the first two of those are '",
        replace: "                         || 'state senator, state representative — and CC_0515 seats the first two of those are '",
      }],
    },

    // ── CC_0515, the Governor and Lieutenant Governor ─────────────────────────────────────────
    {
      // 🔴🔴 THE WASHINGTON DEFECT AGAIN, FROM THE SEATING SIDE. P4 is the only gate that reads
      //    which instrument each of the two offices is dated under. The day is identical, so
      //    nothing else can tell them apart.
      id: 'C18',
      label: "🔴 the Lieutenant Governor given the Governor's rule_id — same day, wrong instrument",
      aimedAt: 'P4 (the rule_id arm)',
      chain: [
        'dates',
        'seatA',
        {
          sql: `UPDATE essentials.office_swearing_in
                   SET rule_id = 'tx-const-art4-s4-installation'
                 WHERE office_id IN (${office('Texas Lieutenant Governor')})
                   AND election_date = DATE '2026-11-03';`,
        },
        'seatB',
      ],
    },
    {
      // 🟢🟢 THE CLAUSE RE-DERIVED AGAINST THE 2015 CYCLE, WHICH IS THIS STATE'S ONLY IN-DATA
      //    CONTROL — and the row it is derived from is the row this file CLOSES. Move it and the
      //    derivation must refuse, because the 2027 date it produces would be unsupported.
      id: 'C19',
      label: "🔴 Greg Abbott's 2015-01-20 moved, so the only in-data control stops reproducing",
      aimedAt: 'P6 (the Abbott-start arm)',
      chain: [
        'dates',
        'seatA',
        {
          sql: `UPDATE essentials.office_terms SET term_start = DATE '2015-01-13'
                 WHERE office_id IN (${office('Texas Governor')}) AND term_start = DATE '2015-01-20';`,
        },
        'seatB',
      ],
    },
    {
      // 🔴 THE 2015 RE-DERIVATION ITSELF. P9b computes the clause against the 2015 cycle before any
      //    write; break the walk and it must stop matching the row.
      id: 'C20',
      label: 'the 2015 re-derivation walked from the wrong Tuesday',
      aimedAt: 'P9b',
      chain: ['dates', 'seatA', {
        tamper: 'seatB',
        find: "             + ((2 - EXTRACT(ISODOW FROM make_date(2015, 1, 1))::int + 7) % 7)) + 7;",
        replace: "             + ((2 - EXTRACT(ISODOW FROM make_date(2015, 1, 1))::int + 7) % 7)) + 14;",
      }],
    },
    {
      // 🔴🔴 THE ORDERING INTERLOCK. CC_0515 must not run before CC_0514 — its P9 reads 2027-01-01
      //    expecting Utah's 50 + New Mexico's 11 + CC_0514's 12. Running it with CC_0514 omitted
      //    is the real out-of-order case, and the gate names it.
      id: 'C21',
      label: '🔴 CC_0515 run WITHOUT CC_0514 — the out-of-order case, with no tamper at all',
      aimedAt: 'P2 (the still-pending arm)',
      chain: ['dates', 'seatB'],
    },
    {
      // 🔴🔴 THE CONTROL THAT COUNTING COULD NOT REACH, AND IT IS WHY P5 GREW AN ARM.
      //    C8's sibling EXPANSION adds rows, so P1's total fires first and P5 is never reached —
      //    recorded as a backstop. This tamper SWAPS instead: it drops the race-carrying Railroad
      //    Commissioner row and takes a sibling in its place, so the selection is still 14 rows,
      //    still 12 in Group A, still 7 Board seats, and still exactly one of three commissioners.
      //    **Every count in the file stays correct and the wrong commissioner is dated.** The
      //    first version of P5 counted selected siblings to one and passed; it now also asserts
      //    the selected row CARRIES THE 2026 RACE, which is the only thing that distinguishes the
      //    three. ▶ CLAUDE.md's *a predicate reads the SHAPE of a value, never what the value is*,
      //    reached through a count.
      id: 'C22',
      label: '🔴 the selected Railroad Commissioner SWAPPED for a sibling, with every count intact',
      aimedAt: 'P5 (the race-carrying arm)',
      chain: [{
        tamper: 'dates',
        find: "   AND w.election_date = DATE '2026-11-03';\n\n-- The three Railroad Commissioner rows",
        replace:
          "   AND w.election_date = DATE '2026-11-03'\n"
          + "   AND o.title <> 'Texas Railroad Commissioner'\n"
          // ⚠ The limited branch is WRAPPED. A bare `LIMIT 1` after a UNION ALL binds to the
          //   whole union, not to its second arm — the first build of this control collapsed the
          //   selection to a single row and fired on P1 saying "the selection holds 1 offices".
          + "UNION ALL\n"
          + "SELECT * FROM (\n"
          + "  SELECT o.id, o.title, d.label, d.district_type, 'A'\n"
          + "    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id\n"
          + "   WHERE lower(d.state) = 'tx' AND o.title = 'Texas Railroad Commissioner'\n"
          + "     AND NOT EXISTS (SELECT 1 FROM essentials.races r\n"
          + "                       JOIN essentials.elections e ON e.id = r.election_id\n"
          + "                      WHERE r.office_id = o.id AND e.election_date = DATE '2026-11-03')\n"
          + "   LIMIT 1) swapped_sibling;\n\n"
          + '-- The three Railroad Commissioner rows',
      }],
    },
  ],
};
