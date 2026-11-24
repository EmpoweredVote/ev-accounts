/**
 * Alabama 2026 — the control suite for `CC_0501` (dates) and `CC_0502` (seating), run on
 * 2026-11-24 before either was applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     ../data/state-seating-2026/controls/al-2026.controls.mjs
 *
 * ⚠ **ONCE THE CHAIN IS APPLIED THIS SUITE CANNOT BE RE-RUN, AND THAT IS CORRECT.** The negative
 *   control fails and the harness refuses to report, rather than printing a column of triumphs.
 *   It is kept as the RECORD of what was tested and as the shape to copy next. `--check` validates
 *   every needle against the migrations without touching the database.
 *
 * ── WHAT THIS SUITE IS AIMED AT ─────────────────────────────────────────────────────────────
 *
 * 🔴🔴 **C4 IS THE ONE THAT MATTERS, BECAUSE IT IS THE ONLY CONTROL ON THE CLAUSE THAT CARRIES
 *   ALABAMA'S REAL-WORLD COST.** "The first Monday after the second Tuesday in January" coincides
 *   with the THIRD Monday in seven of Alabama's eight cycles between 2003 and 2031, and not in
 *   2019 — when the rule gave 2019-01-14, the day Alabama actually inaugurated, and the shorthand
 *   gave 2019-01-21. Assertion 3b's 2027 arm can be satisfied by any rule that lands on
 *   2027-01-18; only its 2019 arm can tell the two rules apart. C4 breaks the 2019 arithmetic and
 *   watches that arm go red. Without it, the file would have a date control that proves the
 *   shorthand and the rule agree — which is the thing they do seven times out of eight.
 *
 * 🔴 **C12 AND C13 ARE A CONTROL AND A CONTROL OF THAT CONTROL.** `P8` ("nobody in this wave ends
 *   up holding two seats") is a ZERO, and a zero proves nothing without a fixture. Alabama has
 *   exactly one: **Tommy Tuberville holds the U.S. Senate seat and won the Governorship**, and
 *   his Senate term was closed at 2027-01-02 by the federal programme. C12 reopens that term and
 *   watches `P9` refuse; C13 moves the term to somebody else so the fixture DISAPPEARS, and
 *   watches `P9` report "expected exactly 1" — which is the gate that stops the zero going
 *   vacuous if the fixture ever leaves.
 *
 * 🔴 **WHAT IS NOT TESTED, AND WHY — THE DIGEST SITS ABOVE ALMOST EVERYTHING.** `CC_0502`'s `P3`
 *   digest covers (office, winner, is_reelection) for all 13 rows, so **every realistic tamper
 *   aimed at the later named gates is caught by the digest two gates earlier**. Recorded as
 *   **backstops, not tested gates**:
 *     • `P3`'s re-election count and its 13-name check — any tamper that moves a winner or an
 *       incumbency flag moves the digest first.
 *     • `P6`'s "a re-election's predecessor is the winner" and "a handover's is not" arms — the
 *       same.
 *     • `CC_0501`'s `P2` ("the selection is the whole pending set") — dropping a title from the
 *       selection changes the TOTAL, so `P1` fires first (C9 measured this). `P2` would only be
 *       reachable by a tamper that both drops a seat and adjusts `P1`'s expectation, which is two
 *       edits to one file — and two tamper steps on one file run it twice, which is how Arizona's
 *       C13b died.
 *     • `CC_0502`'s assertions 3b and 9 — C11 and C12 reach assertion 1 and `P9` respectively,
 *       which sit earlier in the same chain of reasoning.
 *   ▶ This is REGISTER.md's known shape: a file that pins its selection by digest makes its later
 *   named gates unreachable. They stay in the files because the digest cannot say WHICH fact
 *   moved, and the operator reading the failure needs the sentence.
 *
 * ⚠ **AND ONE GATE HAS NO CONTROL AT ALL BY CONSTRUCTION**: `CC_0501`'s assertion 3f and
 *   `CC_0502`'s `P11` pin the State Board of Education's 4-of-8 split, which neither the statute
 *   ("as designated by the board") nor our own data can prove. A tamper could make them fire, but
 *   it would be testing the gate's arithmetic rather than the claim — the claim is a measurement
 *   with no corroborating source, and that is recorded in both file headers rather than dressed
 *   up as a verified fact.
 */
const M = '../../../migrations';
const p = (f) => new URL(`${M}/${f}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

/** The one office we hold outside this wave that one of its winners also holds. */
const SENATE_TERM = `
  SELECT t.id FROM essentials.office_terms t
    JOIN essentials.politicians pol ON pol.id = t.politician_id
    JOIN essentials.offices o       ON o.id = t.office_id
    JOIN essentials.districts d     ON d.id = o.district_id
   WHERE pol.full_name = 'Tommy Tuberville'
     AND lower(d.state) = 'al' AND d.district_type = 'NATIONAL_UPPER'`;

/** One Alabama state office, by title, for a data tamper. */
const office = (title) => `
  SELECT o.id FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND o.title = '${title}'`;

export default {
  name: 'Alabama 2026 — CC_0501 / CC_0502',
  files: {
    dates: p('CC_0501_al_2026_swearing_in_dates.sql'),
    seating: p('CC_0502_al_2026_seat_13_winners.sql'),
  },
  cleanChain: ['dates', 'seating'],
  controls: [
    // ── CC_0501, the dates file ───────────────────────────────────────────────────────────────
    {
      id: 'C1',
      label: "write 2027-01-11 — the SECOND Monday, 193 live rows in Washington and Oregon",
      aimedAt: 'assertion 1',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-18',\n       'statute',",
        replace: "       DATE '2027-01-11',\n       'statute',",
      }],
    },
    {
      id: 'C2',
      label: 'the rule computed as the second Tuesday + 13 (a week late)',
      aimedAt: 'assertion 3a',
      chain: [{ tamper: 'dates', find: '  rule_day   := second_tue + 6;', replace: '  rule_day   := second_tue + 13;' }],
    },
    {
      id: 'C3',
      label: 'the third-Monday look-alike computed as the SECOND Monday',
      aimedAt: 'assertion 3b',
      chain: [{ tamper: 'dates', find: '  third_mon  := first_mon + 14;', replace: '  third_mon  := first_mon + 7;' }],
    },
    {
      // 🔴🔴 THE CONTROL ON THE CLAUSE THAT CARRIES THE COST. 3b's 2027 arm is satisfied by any
      //    rule landing on 2027-01-18; only the 2019 arm separates the rule from its shorthand.
      id: 'C4',
      label: 'the 2019 SEPARATOR broken — the rule made to agree with the third Monday there too',
      aimedAt: 'assertion 3b (the 2019 arm)',
      chain: [{ tamper: 'dates', find: '  r19 := t19 + 6;', replace: '  r19 := t19 + 13;' }],
    },
    {
      // 🔴 THE LEGISLATURE INTERLOCK, with a REAL fixture rather than a tampered expectation:
      //    an Alabama STATE_LOWER office appears, and the file must refuse rather than date it.
      //    § 46(a) commences those terms on 2026-11-04, 75 days before this file's day.
      id: 'C5',
      label: 'an Alabama State House office row appears before the dates file runs',
      aimedAt: 'P4',
      chain: [
        {
          sql: `INSERT INTO essentials.districts (state, district_type, label, geo_id)
                  VALUES ('AL', 'STATE_LOWER', 'Alabama State House District 1 (control fixture)',
                          'CTRL-AL-H1');
                INSERT INTO essentials.offices (district_id, title)
                  SELECT id, 'State Representative' FROM essentials.districts
                   WHERE geo_id = 'CTRL-AL-H1';`,
        },
        'dates',
      ],
    },
    {
      id: 'C6',
      label: "the two Public Service Commissioner rows cite § 16-3-1 instead of § 37-1-3(c)(1)",
      aimedAt: 'assertion 7b',
      chain: [{ tamper: 'dates', find: "         WHEN 'psc' THEN", replace: "         WHEN 'psc-disabled' THEN" }],
    },
    {
      // ⚠ A CONTROL PROVES A GATE CAN FAIL, NOT THAT IT READ THE RIGHT ROWS. Making the day gate
      //    blind to Alabama must report THIRTEEN strangers — that number is the evidence.
      id: 'C7',
      label: "assertion 4 stops recognising Alabama's own rows on 2027-01-18",
      aimedAt: 'assertion 4',
      chain: [{
        tamper: 'dates',
        find: "     AND NOT (lower(dd.state) = 'al'\n              AND s.rule_id = 'al-first-monday-after-second-tuesday-january');",
        replace: "     AND NOT (lower(dd.state) = 'zz'\n              AND s.rule_id = 'al-first-monday-after-second-tuesday-january');",
      }],
    },
    {
      id: 'C8',
      label: "the near-miss before-image pinned at 233 instead of the real 234 on 2027-01-04",
      aimedAt: 'P6',
      chain: [{ tamper: 'dates', find: '  IF b.rows_jan4 <> 234 OR b.rows_jan11 <> 193 THEN', replace: '  IF b.rows_jan4 <> 233 OR b.rows_jan11 <> 193 THEN' }],
    },
    {
      id: 'C9',
      label: 'the Treasurer dropped from the § 116 title list',
      aimedAt: 'P1',   // P2 ("the whole pending set") is the backstop; see the header.
      chain: [{
        tamper: 'dates',
        find: "                       'Secretary of State', 'Treasurer',",
        replace: "                       'Secretary of State',",
      }],
    },
    {
      id: 'C10',
      label: 'the dates file run twice in one transaction',
      aimedAt: 'P0',
      chain: ['dates', 'dates'],
    },

    // ── CC_0502, the seating file ─────────────────────────────────────────────────────────────
    {
      id: 'C11',
      label: "the Attorney General's winner re-pointed at Kay Ivey",
      aimedAt: 'P3 digest',
      chain: [
        {
          sql: `UPDATE essentials.race_candidates
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Kay Ivey' LIMIT 1)
                 WHERE id = (SELECT rc.id FROM essentials.race_candidates rc
                               JOIN essentials.races r     ON r.id = rc.race_id
                               JOIN essentials.elections e ON e.id = r.election_id
                               JOIN essentials.offices o   ON o.id = r.office_id
                               JOIN essentials.districts d ON d.id = o.district_id
                              WHERE lower(d.state) = 'al' AND o.title = 'Attorney General'
                                AND e.election_date = DATE '2026-11-03' AND rc.result = 'won');`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C12',
      label: "🔴 the Governor-elect's U.S. Senate term REOPENED — the two-seat fixture, live",
      aimedAt: 'P9',   // assertion 9 is the post-write backstop for the same fault.
      // 🔴🔴 READ THE MESSAGE, NOT THE COLOUR — THIS CONTROL WENT RED TWICE FOR THE WRONG REASON
      //    BEFORE IT REACHED ITS GATE, AND BOTH REDS LOOKED LIKE SUCCESS IN THE SUMMARY COLUMN.
      //      1. Simply reopening the Senate term (`term_end = NULL`) dies on the database's own
      //         `office_terms_no_overlap` exclusion constraint, because the federal programme has
      //         already seated his successor from 2027-01-03. The harness printed `(unparsed)`
      //         and `conflicting key value violates exclusion constraint` — a red that tests
      //         nothing in either Alabama file. (Maryland's two tampers died the same way.)
      //      2. DELETING the successor's term instead fires `CC_0501`'s **P2**: with no scheduled
      //         term, the U.S. Senate seat falls back into `office_pending_winner`, Alabama has 14
      //         pending seats, and one of them is not in the dates file's selection. 🟢 That is a
      //         real gate doing real work — a federal seat re-entering the pending set stops the
      //         state wave — but it is an EARLIER gate, so P9 stayed untested.
      //    ▶ So the successor's term is MOVED to 2027-02-01 rather than removed. The seat keeps a
      //    scheduled term (P2 passes), and the gap that opens is what lets the Governor-elect's
      //    Senate term be extended past the handover day, which is the fault P9 exists to refuse.
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_start = DATE '2027-02-01'
                 WHERE term_start = DATE '2027-01-03'
                   AND office_id IN (SELECT o.id FROM essentials.offices o
                                       JOIN essentials.districts d ON d.id = o.district_id
                                      WHERE lower(d.state) = 'al'
                                        AND d.district_type = 'NATIONAL_UPPER');
                UPDATE essentials.office_terms SET term_end = DATE '2027-01-31'
                 WHERE id IN (${SENATE_TERM});`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C13',
      label: "🔴 the two-seat FIXTURE removed — the Senate term moved to somebody else",
      aimedAt: 'P9',
      chain: [
        {
          sql: `UPDATE essentials.office_terms
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Kay Ivey' LIMIT 1)
                 WHERE id IN (${SENATE_TERM});`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C14',
      label: "the Treasurer's predecessor term already carries a term_end",
      aimedAt: 'P6',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_end = DATE '2027-06-30'
                 WHERE office_id IN (${office('Treasurer')}) AND term_end IS NULL;`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C15',
      label: "the Auditor's office flagged is_vacant before a future-dated seating",
      aimedAt: 'P6',
      chain: [
        { sql: `UPDATE essentials.offices SET is_vacant = true WHERE id IN (${office('Auditor')});` },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C16',
      label: 'seat_officeholder given a literal 2027-01-11 instead of the date it read',
      aimedAt: 'assertion 1',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '      p_term_start       => r.term_start,',
          replace: "      p_term_start       => DATE '2027-01-11',",
        },
      ],
    },
    {
      id: 'C17',
      label: "assertion 3 stops recognising Alabama as the owner of 2027-01-18",
      aimedAt: 'assertion 3',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: "   WHERE t.term_start = p.expect_term_start AND lower(d.state) <> 'al';",
          replace: "   WHERE t.term_start = p.expect_term_start AND lower(d.state) <> 'zz';",
        },
      ],
    },
    {
      id: 'C18',
      label: "the day's term before-image pinned at 1 instead of the real 0",
      aimedAt: 'P12',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '       0                                  AS expect_terms_on_the_day_before,',
          replace: '       1                                  AS expect_terms_on_the_day_before,',
        },
      ],
    },
    {
      id: 'C19',
      label: 'the seating file run twice in one transaction',
      aimedAt: 'P1',
      chain: ['dates', 'seating', 'seating'],
    },
  ],
};
