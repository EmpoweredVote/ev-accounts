/**
 * Nebraska 2026 — the control suite for `CC_0507` (dates) and `CC_0508` (seating), run on
 * 2026-11-24 before either was applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     data/state-seating-2026/controls/ne-2026.controls.mjs
 *
 * ⚠ **ONCE THE CHAIN IS APPLIED THIS SUITE CANNOT BE RE-RUN, AND THAT IS CORRECT.** The negative
 *   control fails and the harness refuses to report. It is kept as the RECORD of what was tested.
 *   `--check` validates every needle without touching the database.
 *
 * ── WHAT THIS STATE MADE DIFFERENT ──────────────────────────────────────────────────────────
 *
 * 🔴🔴 **THE DANGEROUS WRONG RULE IS NOT A NEAR MISS BY A WEEK — IT IS A SHORTHAND THAT LANDS ON
 *   THE RIGHT DAY IN THIS CYCLE, AND NO TAMPER CAN MAKE THE FILE REFUSE IT.** "The first Thursday
 *   in January" gives 2027-01-07 exactly as Art. XVII-5's "first Thursday AFTER the first Tuesday"
 *   does. A file written from the shorthand would produce the right date and pass every count. So
 *   `CC_0507`'s assertion 3d **asserts that the shorthand matches Nebraska's one dated term**,
 *   rather than asserting that it does not — the gate is in the file *to be watched passing*,
 *   because that is the only way the blindness gets recorded.
 *   • **C5 is the control-of-a-control**: it breaks the shorthand arm's expectation and watches it
 *     refuse. Without C5, the day the two rules stop coinciding this file would quietly start
 *     discriminating and nobody would notice the argument had changed, with every number green.
 *   ▶ This is Idaho's C4 one state later, and it is the second time in the pass that a check kept
 *     in order to PASS has needed a control of its own.
 *
 * 🔴🔴 **"NOBODY HOLDS TWO SEATS" HAS NO NATURAL FIXTURE — IDAHO'S CASE, NOT NEW MEXICO'S.** Not
 *   one of the 13 winners holds a term on any office outside the one they won. Arizona had six
 *   chamber switchers, Alabama had Tommy Tuberville, New Mexico had Stephanie Garcia Richard with
 *   both legs inside its wave. **Nebraska has nobody, and C17 plants one.**
 *   • ▶ **A planted fixture proves the gate FIRES; it does not prove the gate reads the rows a
 *     real double-holder would occupy.** `P8b` asserts the absence itself so the next reader
 *     inherits a measurement.
 *   • ⚠ **New Mexico's lesson is carried**: the fixture goes on **Mike Hilgers, a RE-ELECTED
 *     INCUMBENT**. `P8` asks whether a winner holds MORE THAN ONE office, so a winner who holds
 *     nothing ends with exactly one and `P8` passes *honestly* while a later gate fires — which
 *     is what happened to New Mexico's C19 on Debra Haaland.
 *   • ⚠ **And the fixture is built by REASSIGNING an existing term, not by inserting a second
 *     one.** A term with `term_start IS NULL` has an unbounded daterange, so
 *     `office_terms_no_overlap` rejects any second term on that office — New Mexico's C20 died on
 *     exactly that and printed an `(unparsed)` green RED. Reassigning also leaves
 *     `offices_missing_terms` unmoved, so assertion 13 does not fire two gates late instead.
 *
 * 🔴🔴 **THE DUPLICATE PERSON ROW IS CAUGHT BY THE DIGEST, NOT BY THE GATE NAMED FOR IT, AND C16
 *   MEASURES THAT.** Two active `Mike Foley` rows exist and they collide on **both** (full_name)
 *   and (first_name, last_name), so the database's own duplicate-name trigger cannot tell them
 *   apart either. `P4` names both of them — but re-pointing the winner at the orphan changes
 *   `politician_id`, which is inside the digest, so `P3` fires two gates earlier. **C15 reaches
 *   `P4` instead by a tamper the digest cannot see**: it gives the orphan a term, leaving the
 *   winner alone. Both are recorded, because "the duplicate is caught" and "the gate written for
 *   the duplicate is tested" are different claims.
 *
 * 🔴 **TWO OF THE FOUR NEAR MISSES ARE ONE DAY APART AND ONE OF THEM IS 200 LIVE ROWS.**
 *   2027-01-06 is what **Maine's rule** gives — `me-const-art5-pt1-s2-first-wed-after-first-tue-
 *   january`, which is this clause's own sentence with Wednesday in place of Thursday — and it is
 *   also where **Nebraska's own 49 absent unicameral seats** belong under Art. III-10 and
 *   § 32-122. C2 and C9 aim at it. 2027-01-04, the first Monday, carries 241 rows and 229 terms.
 *
 * ── WHAT IS NOT TESTED, AND WHY ─────────────────────────────────────────────────────────────
 *
 * Recorded as **backstops, not tested gates**:
 *   • `CC_0508`'s `P3` re-election and handover counts and its 13-name check, and `P6`'s
 *     predecessor-identity arms — all sit below the pinned digest, so any realistic tamper moves
 *     the digest two gates earlier (C16 measured this).
 *   • `CC_0508`'s `P4` first arm (the winner points at the sourced Foley row) — same reason.
 *   • `CC_0507`'s `P2` selection-completeness arm — dropping a body changes the TOTAL, so `P1`
 *     fires first. Alabama's and New Mexico's shape.
 *   • `CC_0508`'s `P5` — the same data tamper reaches `CC_0507`'s assertion 3e first, which is the
 *     right order: the chain refuses before anything is written. C10 records which one fired.
 */
const M = '../../../migrations';
const p = (f) => new URL(`${M}/${f}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

/** One Nebraska office in this wave, by title, for a data tamper. */
const office = (title) => `
  SELECT o.id FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ne' AND o.title = '${title}'`;

export default {
  name: 'Nebraska 2026 — CC_0507 / CC_0508',
  files: {
    dates: p('CC_0507_ne_2026_swearing_in_dates.sql'),
    seating: p('CC_0508_ne_2026_seat_13_winners.sql'),
  },
  cleanChain: ['dates', 'seating'],
  controls: [
    // ── CC_0507, the dates file ───────────────────────────────────────────────────────────────
    {
      // 🔴 THE WORD "AFTER" IS THE ENTIRE DIFFERENCE BETWEEN THIS CLAUSE AND ITS SHORTHAND, so the
      //    arithmetic that implements it is the first thing to break.
      id: 'C1',
      label: 'the Thursday counted from January 1st instead of from the first Tuesday',
      aimedAt: 'assertion 3a',
      chain: [{
        tamper: 'dates',
        find: '  truth     := first_tue + (CASE WHEN EXTRACT(ISODOW FROM first_tue)::int < 4',
        replace: '  truth     := j1 + (CASE WHEN EXTRACT(ISODOW FROM first_tue)::int < 4',
      }],
    },
    {
      // 🔴🔴 THE NEAR MISS THAT IS MAINE'S RULE *AND* NEBRASKA'S OWN LEGISLATURE'S DAY, carrying
      //    200 live rows between Massachusetts and Maine.
      id: 'C2',
      label: "write 2027-01-06 — Maine's rule, the Legislature's day, 200 live rows",
      aimedAt: 'assertion 1',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-07',\n       'statute',",
        replace: "       DATE '2027-01-06',\n       'statute',",
      }],
    },
    {
      id: 'C3',
      label: 'the first Tuesday computed a week late, which drags the Thursday with it',
      aimedAt: 'assertion 3a',
      chain: [{
        tamper: 'dates',
        find: '  first_tue := j1 + ((2 - EXTRACT(ISODOW FROM j1)::int + 7) % 7);',
        replace: '  first_tue := j1 + ((2 - EXTRACT(ISODOW FROM j1)::int + 7) % 7) + 7;',
      }],
    },
    {
      // 🔴 THE SHORTHAND'S OWN ARITHMETIC. If it stops computing the first Thursday of January,
      //    the coincidence assertion below is comparing two copies of the same thing.
      id: 'C4',
      label: 'the shorthand mis-computed as the first Friday of January',
      aimedAt: 'assertion 3b (the coincidence arm)',
      chain: [{
        tamper: 'dates',
        find: '  shorthand := j1 + ((4 - EXTRACT(ISODOW FROM j1)::int + 7) % 7);',
        replace: '  shorthand := j1 + ((5 - EXTRACT(ISODOW FROM j1)::int + 7) % 7);',
      }],
    },
    {
      // 🔴🔴 THE CONTROL-OF-A-CONTROL. Assertion 3d's shorthand arm is in the file TO BE WATCHED
      //    PASSING: it records that Nebraska's one dated term CANNOT separate the clause from its
      //    shorthand, which is why the canvass book is load-bearing. If that arm ever stopped
      //    expecting a match, the file would silently stop recording the blindness it exists to
      //    record — and every number in it would still be green.
      id: 'C5',
      label: '🔴 the SHORTHAND arm of 3d no longer expects a match on the one dated term',
      aimedAt: 'assertion 3d (the shorthand arm)',
      chain: [{ tamper: 'dates', find: '  IF c_short <> 1 THEN', replace: '  IF c_short <> 0 THEN' }],
    },
    {
      id: 'C6',
      label: 'the in-data corroboration arm of 3d expects no match instead of one',
      aimedAt: 'assertion 3d (the corroboration arm)',
      chain: [{ tamper: 'dates', find: '  IF c_truth <> 1 THEN', replace: '  IF c_truth <> 0 THEN' }],
    },
    {
      // ⚠ A CONTROL PROVES A GATE CAN FAIL, NOT THAT IT READ THE RIGHT ROWS. Making the
      //    wrong-rules arm expect a match must fire on Nebraska's single fixture — and if it does
      //    not, the loop never saw that row.
      id: 'C7',
      label: "3d's four wrong rules expected to match once each instead of never",
      aimedAt: 'assertion 3d (the wrong-rules arm)',
      chain: [{
        tamper: 'dates',
        find: '  IF c_mon <> 0 OR c_tue <> 0 OR c_wedm <> 0 OR c_wedt <> 0 THEN',
        replace: '  IF c_mon <> 1 OR c_tue <> 1 OR c_wedm <> 1 OR c_wedt <> 1 THEN',
      }],
    },
    {
      // 🟢 Each body's statute names its own cycle, and those are what the "which seats were up"
      //    arithmetic rests on.
      id: 'C8',
      label: "the executives' four-year cycle anchored on 1995 instead of 1994",
      aimedAt: 'assertion 3a (the executive cycle arm)',
      chain: [{
        tamper: 'dates',
        find: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1994) % 4 <> 0 THEN\n"
            + "    RAISE EXCEPTION '3a: 2026 is not on the executives'' four-year cycle from 1994",
        replace: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1995) % 4 <> 0 THEN\n"
            + "    RAISE EXCEPTION '3a: 2026 is not on the executives'' four-year cycle from 1994",
      }],
    },
    {
      // 🔴🔴 THE ARM THAT PROVES REGENT DISTRICT 4 IS A VACANCY SEAT. If 2026 were on § 32-510's
      //    1994 six-year cycle, District 4 would be a regular election and three of its four
      //    cycle-mates would be missing from our data instead.
      id: 'C9',
      label: "the Regents' 1994 six-year cycle check inverted",
      aimedAt: 'assertion 3a (the District 4 arm)',
      chain: [{
        tamper: 'dates',
        find: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1994) % 6 = 0 THEN",
        replace: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1994) % 6 <> 0 THEN",
      }],
    },
    {
      id: 'C10',
      label: "the 2027-01-06 before-image pinned at 199 instead of the real 200",
      aimedAt: 'P6',
      chain: [{ tamper: 'dates', find: '  IF b.rows_wed <> 200 THEN', replace: '  IF b.rows_wed <> 199 THEN' }],
    },
    {
      // 🔴🔴 THE EVIDENCE THAT EXPLAINS REGENT DISTRICT 4, REMOVED. CC_0375's note is the only
      //    record of why a seat § 32-510 puts on the 1994 cycle was on the 2026 ballot, and the
      //    only record that the term CC_0508 opens is an unexpired remainder.
      //    ⚠ MEASURED: this fires on the DATES file's assertion 3e, not on CC_0508's P5, and that
      //    is the right order — the chain refuses before anything is written.
      id: 'C11',
      label: "CC_0375's Regent District 4 appointment note stripped from the term row",
      //    ⚠ MEASURED: it fires on the dates file's **P4**, the pre-check, not on its post-write
      //    restatement 3e — which is the right order, because the chain refuses before anything
      //    is written. 3e is therefore a BACKSTOP: it re-asserts after the write a fact P4 has
      //    already refused to proceed without, and no realistic tamper can reach it.
      aimedAt: 'P4',
      chain: [
        {
          sql: `UPDATE essentials.office_terms
                   SET source = 'control fixture (C11): the appointment note removed'
                 WHERE office_id IN (${office('University of Nebraska Regent, District 4')});`,
        },
        'dates',
      ],
    },
    {
      // 🔴 THE LEGISLATURE INTERLOCK. Those 49 seats belong on 2027-01-06, not on this day, so an
      //    arriving office must stop the file rather than borrow this clause.
      id: 'C12',
      label: 'a Nebraska legislative office row appears',
      aimedAt: 'P5',
      chain: [
        {
          sql: `INSERT INTO essentials.districts (state, district_type, label, geo_id, mtfcc)
                  VALUES ('NE', 'STATE_UPPER', 'Nebraska Legislature District 1 (control fixture)',
                          'ZZC12NE01', 'G5210');
                INSERT INTO essentials.offices (district_id, title)
                  SELECT id, 'State Senator (control fixture)'
                    FROM essentials.districts WHERE geo_id = 'ZZC12NE01';`,
        },
        'dates',
      ],
    },
    {
      id: 'C13',
      label: 'the dates file run twice in one transaction',
      aimedAt: 'P0',
      chain: ['dates', 'dates'],
    },
    {
      // 🔴🔴 THE ONE NO NUMBER CAN SEE. Dropping Art. XVII-5's first six words from the authority
      //    text leaves every row, date, delta and count byte-for-byte identical — and hands the
      //    next reader a rule they would apply to the Legislature, which is one day wrong. Only
      //    assertion 7b reads the text. This is Maryland's C8 and New Mexico's C15 a third time.
      id: 'C14',
      label: "🔴 the residual's first six words dropped from the authority text",
      aimedAt: 'assertion 7b',
      chain: [{
        tamper: 'dates',
        find: "       'Neb. Const. Art. XVII-5 - Terms of office of all elected officers: \"UNLESS OTHERWISE '\n"
            + "         || 'PROVIDED BY THIS CONSTITUTION OR BY LAW the terms of all elected officers shall '",
        replace: "       'Neb. Const. Art. XVII-5 - Terms of office of all elected officers: \"The '\n"
            + "         || 'terms of all elected officers shall '",
      }],
    },
    {
      // ⚠ A GATE THAT COUNTS BODIES BY district_type CANNOT SEE THAT STATE_BOARD IS TWO BODIES.
      //    Moving one Regent office into the Public Service Commission's chamber leaves the
      //    district_type counts identical and breaks the body-size arithmetic.
      id: 'C15',
      label: 'a Regent office moved into the Public Service Commission chamber',
      aimedAt: 'P3 (the body-size arm)',
      chain: [
        {
          sql: `UPDATE essentials.offices
                   SET chamber_id = (SELECT c.id FROM essentials.chambers c
                                       JOIN essentials.offices o2 ON o2.chamber_id = c.id
                                       JOIN essentials.districts d2 ON d2.id = o2.district_id
                                      WHERE lower(d2.state) = 'ne'
                                        AND c.name = 'Public Service Commission' LIMIT 1)
                 WHERE id IN (${office('University of Nebraska Regent, District 3')});`,
        },
        'dates',
      ],
    },

    // ── CC_0508, the seating file ─────────────────────────────────────────────────────────────
    {
      // 🔴🔴 THE DUPLICATE, REACHED BY A TAMPER THE DIGEST CANNOT SEE. Giving the orphan Mike
      //    Foley row a term changes nothing inside the digest — the winner and the holder are
      //    untouched — so P4's second arm is the gate that catches it.
      //    ⚠ **THE FIRST VERSION OF THIS CONTROL INSERTED A SECOND TERM AND DIED ON
      //    `office_terms_no_overlap`, PRINTING AN `(unparsed)` GREEN RED** — the same trap New
      //    Mexico's C20 paid for and that this file's own header warns about, walked into anyway.
      //    Every held Nebraska office outside the wave has a term with `term_start IS NULL`,
      //    whose daterange is UNBOUNDED, so no second term can sit beside it. ▶ Reassign an
      //    existing term instead: it leaves the digest, the predecessor pre-image and
      //    `offices_missing_terms` all untouched, and changes only the thing P4 looks for.
      id: 'C16',
      label: '🔴 the orphan Mike Foley row given a term of its own',
      aimedAt: 'P4 (the orphan arm)',
      chain: [
        'dates',
        {
          sql: `UPDATE essentials.office_terms
                   SET politician_id = '38277535-35fb-4e98-973e-8f00a43c4546'::uuid,
                       source = 'control fixture (C16): reassigned from Robert Schafer'
                 WHERE office_id IN (${office('University of Nebraska Regent, District 5')});`,
        },
        'seating',
      ],
    },
    {
      // ⚠ AND THE REALISTIC VERSION OF THE SAME DEFECT IS CAUGHT TWO GATES EARLIER, which is the
      //    finding rather than a failure: re-pointing the winner at the orphan moves politician_id,
      //    which is inside the digest. "The duplicate is caught" and "the gate written for the
      //    duplicate is tested" are different claims, and this control separates them.
      id: 'C17',
      label: "the Auditor's winner re-pointed at the orphan Mike Foley row",
      aimedAt: 'P3 digest',
      chain: [
        {
          sql: `UPDATE essentials.race_candidates
                   SET politician_id = '38277535-35fb-4e98-973e-8f00a43c4546'::uuid
                 WHERE id = (SELECT rc.id FROM essentials.race_candidates rc
                               JOIN essentials.races r     ON r.id = rc.race_id
                               JOIN essentials.elections e ON e.id = r.election_id
                               JOIN essentials.offices o   ON o.id = r.office_id
                               JOIN essentials.districts d ON d.id = o.district_id
                              WHERE lower(d.state) = 'ne'
                                AND o.title = 'Auditor of Public Accounts'
                                AND e.election_date = DATE '2026-11-03' AND rc.result = 'won');`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🔴🔴 THE PLANTED TWO-SEAT FIXTURE. Nebraska has no real one, so this is the ONLY thing
      //    that shows P8 can fire. ⚠ IT GOES ON A RE-ELECTED INCUMBENT — Mike Hilgers, Attorney
      //    General — because P8 asks whether a winner holds MORE THAN ONE office and somebody who
      //    holds nothing ends with exactly one, passing it honestly (New Mexico's C19 on Debra
      //    Haaland). ⚠ AND IT REASSIGNS rather than inserts: Regent District 3's term has
      //    term_start NULL, so its daterange is unbounded and a second term on that office would
      //    be rejected by office_terms_no_overlap (New Mexico's C20). Reassigning also leaves
      //    offices_missing_terms unmoved, so assertion 13 does not fire instead.
      id: 'C18',
      label: '🔴 Mike Hilgers, a re-elected winner, given a second seat outside the wave',
      aimedAt: 'P8',
      chain: [
        {
          sql: `UPDATE essentials.office_terms
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Mike Hilgers' AND is_active LIMIT 1),
                       source = 'control fixture (C18): reassigned from Jim Scheer'
                 WHERE office_id IN (${office('University of Nebraska Regent, District 3')});`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C19',
      label: "seat_officeholder given a literal 2027-01-06 — Maine's rule and the Legislature's day",
      aimedAt: 'assertion 1',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '      p_term_start       => s.term_start,',
          replace: "      p_term_start       => DATE '2027-01-06',",
        },
      ],
    },
    {
      // ⚠ MAKING THE DAY GATE BLIND TO NEBRASKA MUST REPORT THIRTEEN STRANGERS. That number is
      //    the evidence the gate read the right rows, not merely that it can fail.
      id: 'C20',
      label: "assertion 3 stops recognising Nebraska as an owner of 2027-01-07",
      aimedAt: 'assertion 3',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: "   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('ne', 'ma');",
          replace: "   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('zz', 'ma');",
        },
      ],
    },
    {
      id: 'C21',
      label: "the day's term before-image pinned at 1 instead of the real 2",
      aimedAt: 'P11',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '       2                                  AS expect_terms_on_the_day_before,',
          replace: '       1                                  AS expect_terms_on_the_day_before,',
        },
      ],
    },
    {
      // 🔴 THE PREDECESSOR PRE-IMAGE. seat_officeholder overwrites term_end without a guard and
      //    records nothing, so a predecessor that already carries one would lose a date no file
      //    has written down.
      id: 'C22',
      label: "the Secretary of State's predecessor term already carries a term_end",
      aimedAt: 'P6',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_end = DATE '2027-06-30'
                 WHERE office_id IN (${office('Secretary of State')}) AND term_end IS NULL;`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🔴🔴 THE UNEXPIRED-REMAINDER NOTE ON THE WRONG SEAT, which is worse than it being missing:
      //    it would tell a later reader that a regular four-year Board of Education seat ends
      //    early, and that Regent District 4's does not. Only 10c's second arm reads WHICH seat.
      id: 'C23',
      label: '🔴 the UNEXPIRED REMAINDER note written onto a Board of Education seat instead',
      aimedAt: 'assertion 10c (the which-seat arm)',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: "                         || CASE WHEN s.title = 'University of Nebraska Regent, District 4'",
          replace: "                         || CASE WHEN s.title = 'Nebraska State Board of Education Member, District 5'",
        },
      ],
    },
    {
      // ⚠ THE GUARD'S SCOPE IS A UNION, AND A UNION THAT HAS COLLAPSED TO THE WINNERS IS NARROWER
      //    THAN ITS NAME. Nebraska can exercise this because six seats are re-elections and seven
      //    are not; Idaho could not, because its two sets were identical.
      id: 'C24',
      label: 'the incumbency guard scoped to the winners alone instead of the union',
      aimedAt: 'incumbency guard',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: 'SELECT politician_id FROM cc0508_sel WHERE politician_id IS NOT NULL\nUNION\nSELECT politician_id FROM cc0508_pre WHERE politician_id IS NOT NULL;',
          replace: 'SELECT politician_id FROM cc0508_sel WHERE politician_id IS NOT NULL;',
        },
      ],
    },
    {
      id: 'C25',
      label: 'the seating file run twice in one transaction',
      aimedAt: 'P1',
      chain: ['dates', 'seating', 'seating'],
    },
  ],
};
