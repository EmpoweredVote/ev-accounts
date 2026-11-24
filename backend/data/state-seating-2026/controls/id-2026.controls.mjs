/**
 * Idaho 2026 — the control suite for `CC_0503` (dates) and `CC_0504` (seating), run on 2026-11-24
 * before either was applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     data/state-seating-2026/controls/id-2026.controls.mjs
 *
 * ⚠ **ONCE THE CHAIN IS APPLIED THIS SUITE CANNOT BE RE-RUN, AND THAT IS CORRECT.** The negative
 *   control fails and the harness refuses to report. It is kept as the RECORD of what was tested.
 *   `--check` validates every needle without touching the database.
 *
 * ── WHAT THIS STATE MADE DIFFERENT ──────────────────────────────────────────────────────────
 *
 * 🔴🔴 **IDAHO RETURNED ITS ENTIRE EXECUTIVE DEPARTMENT — SEVEN OF SEVEN ARE RE-ELECTIONS — SO
 *   TWO OF THE USUAL CONTROLS HAVE NOTHING REAL TO STAND ON.**
 *   • There is **no handover anywhere in the state**, so `CC_0504`'s `P6` arm asserting that a
 *     handover's predecessor is not the winner is **unreachable by construction**. No tamper can
 *     reach it without inventing a handover, which would be testing a different state.
 *   • **No winner holds any office outside the wave** — no chamber switcher, no cross-tier move —
 *     so `P8`'s "nobody holds two seats" zero has **no natural fixture**. Arizona had six
 *     switchers and Alabama had Tommy Tuberville; Idaho has nobody. **C9 plants one.** ▶ A planted
 *     fixture proves the gate FIRES; it does not prove the gate reads the rows a real
 *     double-holder would occupy. Both halves are recorded, because the honest claim is narrower
 *     than the green tick. `P8b` asserts the absence itself, so the next reader inherits a
 *     measurement rather than an assumption.
 *
 * 🟢🟢 **C4 AND C5 ARE THE PAIR THIS STATE EXISTS FOR, AND THEY TEST OPPOSITE HALVES OF ONE
 *   CONTROL.** `CC_0503`'s assertion 3d runs two tests over Idaho's three dated executive terms:
 *   a WEAK one (is it a Monday?) which admits all three, and a STRONG one (is it the first Monday
 *   of its own January?) which admits exactly two. The third row, Brandon D. Woolf's 2012-10-15,
 *   is a mid-term **appointment in October** that is **also a Monday** — so the weak test counts
 *   an appointment as evidence for an elected-term formula.
 *   • **C5** breaks the strong test's expectation and watches it refuse.
 *   • **C4** breaks the WEAK test's expectation — and that one matters more, because the weak
 *     test is in the file *to be watched passing*. If it ever stopped admitting all three, the
 *     control would silently stop demonstrating the trap it was written to record, and every
 *     number in the file would still be green.
 *   ▶ **A control kept in order to pass needs a control of its own.**
 *
 * 🔴 **AND TWO OF IDAHO'S THREE NEAR MISSES ARE NAMED BY ITS OWN CONSTITUTION.** 2027-01-11 is
 *   Art. III § 8's regular-session convening day *and* the term start of 193 Washington and Oregon
 *   seats; 2026-12-01 is Art. III § 3's **legislative** term start, which 289 Maine and California
 *   rows already carry and which Idaho's own 105 unraced legislative seats belong on. C2 and C3
 *   aim at those.
 *
 * ── WHAT IS NOT TESTED, AND WHY ─────────────────────────────────────────────────────────────
 *
 * Recorded as **backstops, not tested gates** — `CC_0504`'s `P3` re-election count, its 13-name
 * check and `P6`'s predecessor-identity arms all sit below the pinned digest, so any realistic
 * tamper moves the digest two gates earlier (C8 measured this). `CC_0503`'s `P2` is the same shape
 * as Alabama's: dropping a title from the selection changes the TOTAL, so `P1` fires first.
 */
const M = '../../../migrations';
const p = (f) => new URL(`${M}/${f}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

/** One Idaho state-executive office, by title, for a data tamper. */
const office = (title) => `
  SELECT o.id FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'id' AND d.district_type = 'STATE_EXEC' AND o.title = '${title}'`;

export default {
  name: 'Idaho 2026 — CC_0503 / CC_0504',
  files: {
    dates: p('CC_0503_id_2026_swearing_in_dates.sql'),
    seating: p('CC_0504_id_2026_seat_7_winners.sql'),
  },
  cleanChain: ['dates', 'seating'],
  controls: [
    // ── CC_0503, the dates file ───────────────────────────────────────────────────────────────
    {
      id: 'C1',
      label: 'the first Monday computed as January 1st + 7 (a week late)',
      aimedAt: 'assertion 3a',
      chain: [{
        tamper: 'dates',
        find: '  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);',
        replace: '  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7) + 7;',
      }],
    },
    {
      // 🔴 THE NEAR MISS THAT IS IDAHO'S OWN SESSION DAY *AND* 193 OTHER SEATS' TERM START.
      id: 'C2',
      label: "write 2027-01-11 — Idaho's own session convening day, and 193 live terms elsewhere",
      aimedAt: 'assertion 1',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-04',\n       'statute',",
        replace: "       DATE '2027-01-11',\n       'statute',",
      }],
    },
    {
      // 🔴 THE OTHER IN-STATE NEAR MISS: the LEGISLATURE's own day, under a different article.
      id: 'C3',
      label: "the organizational-session Thursday mis-derived (Art. III § 8's December day)",
      aimedAt: 'assertion 3b',
      chain: [{
        tamper: 'dates',
        find: '  dec_thu    := dec1 + ((4 - EXTRACT(ISODOW FROM dec1)::int + 7) % 7);',
        replace: '  dec_thu    := dec1 + ((5 - EXTRACT(ISODOW FROM dec1)::int + 7) % 7);',
      }],
    },
    {
      // 🔴🔴 THE CONTROL-OF-A-CONTROL. The weak test is in the file to be watched PASSING on a
      //    mid-term appointment. If it stopped admitting all three rows, assertion 3d would stop
      //    demonstrating the trap and every number would still read green.
      id: 'C4',
      label: 'the WEAK (weekday) test no longer admits all three dated rows',
      aimedAt: 'assertion 3d (the weak arm)',
      chain: [{ tamper: 'dates', find: '  IF c_weekday <> 3 THEN', replace: '  IF c_weekday <> 2 THEN' }],
    },
    {
      id: 'C5',
      label: 'the STRONG (first-Monday-of-its-own-January) test expects three rows, not two',
      aimedAt: 'assertion 3d (the strong arm)',
      chain: [{ tamper: 'dates', find: '  IF c_month <> 2 THEN', replace: '  IF c_month <> 3 THEN' }],
    },
    {
      // 🟢 The clause states its own cycle: "commencing with those elected in the year 1946".
      id: 'C6',
      label: "Art. IV § 1's four-year cycle anchored on 1947 instead of 1946",
      aimedAt: 'assertion 3a (the cycle arm)',
      chain: [{
        tamper: 'dates',
        find: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1946) % 4 <> 0 THEN",
        replace: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1947) % 4 <> 0 THEN",
      }],
    },
    {
      // ⚠ A CONTROL PROVES A GATE CAN FAIL, NOT THAT IT READ THE RIGHT ROWS. Making the day gate
      //    blind to Idaho must report SEVEN strangers — that number is the evidence.
      id: 'C7',
      label: "assertion 4 stops recognising Idaho's own rows on 2027-01-04",
      aimedAt: 'assertion 4',
      chain: [{
        tamper: 'dates',
        find: "     AND NOT (lower(dd.state) = 'id' AND s.rule_id = 'id-const-art4-s1-first-monday-january')",
        replace: "     AND NOT (lower(dd.state) = 'zz' AND s.rule_id = 'id-const-art4-s1-first-monday-january')",
      }],
    },
    {
      id: 'C8',
      label: 'the crowded-day before-image pinned at 233 instead of the real 234',
      aimedAt: 'P5',
      chain: [{ tamper: 'dates', find: '  IF b.rows_jan4 <> 234 THEN', replace: '  IF b.rows_jan4 <> 233 THEN' }],
    },
    {
      // 🔴🔴 THE LEGISLATURE INTERLOCK, with a REAL fixture: a 2026 race arrives on a seat whose
      //    terms run from December under a different article.
      id: 'C9',
      label: 'a 2026 race row appears on an Idaho Senate seat',
      aimedAt: 'P4',
      chain: [
        {
          sql: `INSERT INTO essentials.races (election_id, office_id, position_name, seats)
                  SELECT (SELECT id FROM essentials.elections
                           WHERE election_date = DATE '2026-11-03' LIMIT 1),
                         o.id, 'State Senator (control fixture)', 1
                    FROM essentials.offices o
                    JOIN essentials.districts d ON d.id = o.district_id
                   WHERE lower(d.state) = 'id' AND d.district_type = 'STATE_UPPER'
                   LIMIT 1;`,
        },
        'dates',
      ],
    },
    {
      id: 'C10',
      label: 'the dates file run twice in one transaction',
      aimedAt: 'P0',
      chain: ['dates', 'dates'],
    },

    // ── CC_0504, the seating file ─────────────────────────────────────────────────────────────
    {
      id: 'C11',
      label: "the Governor's winner re-pointed at the Lieutenant Governor",
      aimedAt: 'P3 digest',
      chain: [
        {
          sql: `UPDATE essentials.race_candidates
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Scott Bedke' LIMIT 1)
                 WHERE id = (SELECT rc.id FROM essentials.race_candidates rc
                               JOIN essentials.races r     ON r.id = rc.race_id
                               JOIN essentials.elections e ON e.id = r.election_id
                               JOIN essentials.offices o   ON o.id = r.office_id
                               JOIN essentials.districts d ON d.id = o.district_id
                              WHERE lower(d.state) = 'id' AND o.title = 'Governor'
                                AND e.election_date = DATE '2026-11-03' AND rc.result = 'won');`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🔴🔴 THE PLANTED TWO-SEAT FIXTURE. Idaho has no real one, so this is the ONLY thing that
      //    shows P8 can fire. The Governor is given a second open term on an office outside the
      //    wave — Idaho's own Senate seat 1, which carries no 2026 race.
      id: 'C12',
      label: '🔴 the Governor given a second open term on an unraced Senate seat',
      aimedAt: 'P8',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_end = DATE '2026-11-30'
                 WHERE office_id = (SELECT o.id FROM essentials.offices o
                                      JOIN essentials.districts d ON d.id = o.district_id
                                     WHERE lower(d.state) = 'id'
                                       AND d.district_type = 'STATE_UPPER'
                                     ORDER BY o.id LIMIT 1)
                   AND term_end IS NULL;
                INSERT INTO essentials.office_terms
                  (office_id, politician_id, term_start, start_precision, how_started, source)
                  SELECT (SELECT o.id FROM essentials.offices o
                            JOIN essentials.districts d ON d.id = o.district_id
                           WHERE lower(d.state) = 'id' AND d.district_type = 'STATE_UPPER'
                           ORDER BY o.id LIMIT 1),
                         (SELECT id FROM essentials.politicians
                           WHERE full_name = 'Brad Little' LIMIT 1),
                         DATE '2026-12-01', 'day', 'elected', 'control fixture (C12)';`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C13',
      label: "the Superintendent's predecessor term already carries a term_end",
      aimedAt: 'P6',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_end = DATE '2027-06-30'
                 WHERE office_id IN (${office('Superintendent of Public Instruction')})
                   AND term_end IS NULL;`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🟢🟢 THE TWO ROWS THAT ARE CC_0503'S ONLY IN-DATA EVIDENCE. Moving one must stop the file:
      //    seat_officeholder writes nothing to a closed row's source, so a lost start is gone.
      id: 'C14',
      label: "Brad Little's 2019-01-07 moved — the corroboration Art. IV § 1 rests on",
      // 🟢🟢 MEASURED: THIS FIRES ON `CC_0503` ASSERTION 3d, NOT ON `CC_0504` P6 — AND THAT IS THE
      //    RIGHT ORDER. Moving that date corrupts the very row the DATES file's corroboration
      //    control reads, so the chain refuses before the seating file is reached and nothing is
      //    written. The two files' gates are chained, which a per-file reading would not show.
      //    ▶ C20 below moves the OTHER dated row in a way 3d cannot see, which is what actually
      //    reaches P6.
      aimedAt: 'assertion 3d',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_start = DATE '2019-01-14'
                 WHERE office_id IN (${office('Governor')}) AND term_start = DATE '2019-01-07';`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C15',
      label: "the Treasurer's office flagged is_vacant before a future-dated seating",
      aimedAt: 'P6',
      chain: [
        { sql: `UPDATE essentials.offices SET is_vacant = true WHERE id IN (${office('Treasurer')});` },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C16',
      label: "seat_officeholder given a literal 2027-01-11 — Idaho's own session day",
      aimedAt: 'assertion 1',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '      p_term_start       => s.term_start,',
          replace: "      p_term_start       => DATE '2027-01-11',",
        },
      ],
    },
    {
      id: 'C17',
      label: 'assertion 3 stops recognising Idaho as an owner of 2027-01-04',
      aimedAt: 'assertion 3',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: "   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('id', 'az', 'wi', 'ca');",
          replace: "   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('zz', 'az', 'wi', 'ca');",
        },
      ],
    },
    {
      id: 'C18',
      label: "the day's term before-image pinned at 221 instead of the real 222",
      aimedAt: 'P9',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '       222                                AS expect_terms_on_the_day_before,',
          replace: '       221                                AS expect_terms_on_the_day_before,',
        },
      ],
    },
    {
      id: 'C19',
      label: 'the seating file run twice in one transaction',
      aimedAt: 'P1',
      chain: ['dates', 'seating', 'seating'],
    },
    {
      // 🔴🔴 THE TAMPER ASSERTION 3d CANNOT SEE, WHICH IS WHY IT REACHES P6. Woolf's appointment
      //    moves from 2012-10-15 to 2012-10-22 — still October, still a Monday — so every one of
      //    3d's three counts is unchanged (3 rows, 3 Mondays, 2 first-Mondays) and the dates file
      //    passes. The seating file's pre-image gate then catches it, because that gate asserts
      //    the dated start is one of three KNOWN VALUES rather than one of the right shape.
      //    ▶ A gate that reads a value and a gate that reads its shape are complementary, not
      //    redundant — and only a tamper that leaves the shape intact separates them.
      id: 'C20',
      label: "Woolf's appointment moved to another October Monday — invisible to assertion 3d",
      aimedAt: 'P6',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_start = DATE '2012-10-22'
                 WHERE office_id IN (${office('State Controller')})
                   AND term_start = DATE '2012-10-15';`,
        },
        'dates',
        'seating',
      ],
    },
  ],
};
