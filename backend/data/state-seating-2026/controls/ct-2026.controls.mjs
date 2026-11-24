/**
 * Connecticut 2026 — the control suite for `CC_0509` (dates) and `CC_0510` (seating), run on
 * 2026-11-24 before either was applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     data/state-seating-2026/controls/ct-2026.controls.mjs
 *
 * ⚠ **ONCE THE CHAIN IS APPLIED THIS SUITE CANNOT BE RE-RUN, AND THAT IS CORRECT.** The negative
 *   control fails and the harness refuses to report. It is kept as the RECORD of what was tested.
 *   `--check` validates every needle without touching the database.
 *
 * ── WHAT THIS STATE MADE DIFFERENT ──────────────────────────────────────────────────────────
 *
 * 🔴🔴 **THE DATE RESTS ON ONE IN-DATA ROW, AND EXACTLY ONE RIVAL RULE SURVIVES IT.** Connecticut
 *   holds a single dated state term — Ned Lamont's Governorship, 2019-01-09 — and of the six
 *   rivals computed beside `art. IV § 2`, *the second Wednesday in January* reproduces it
 *   exactly. That rival gives **2027-01-13**, which is the Maryland General Assembly's live day,
 *   178 rows. The Senate Journal of **January 4, 2023** is what refuses it, and in that cycle
 *   **two different rivals** survive instead — the first Wednesday in January and **Maine's**
 *   "first Wednesday after the first Tuesday", which is already on this very calendar square.
 *   **Neither cycle separates the clause alone; the two together leave nothing standing.**
 *   `CC_0509`'s assertion 3d asserts all three numbers — 1, 2 and 0 — and **C5, C6 and C7 are one
 *   control each**, because a gate with three arms is three gates.
 *
 * 🟢🟢 **C7 IS THE ONE WORTH READING.** The three survivor counts are *coupled*: any rival that
 *   enters the intersection also moves one of the first two counts, so a naive tamper always
 *   fires on an earlier arm and the intersection gate is never reached — `CLAUDE.md`'s *a gate no
 *   control reaches is a gate nobody has tested, and two gates catching one fault is what hides
 *   it*. C7 therefore **swaps the first- and second-Wednesday expressions in the 2023 column
 *   only**, in one contiguous replacement: 2019 is untouched so `survive_2019` stays 1, the 2023
 *   set still has exactly two members so `survive_2023` stays 2, and the second Wednesday is now
 *   in **both** — so `survive_both` becomes 1 and the last arm in the chain fires for the first
 *   time. ▶ **Only a tamper that leaves every other count correct and self-consistent tests the
 *   last gate in a chain.**
 *
 * ⚠ **AND THE FIRST RUN OF C5, C6 AND C7 FOUND A REAL DEFECT IN `CC_0509`, WHICH IS WHY THEIR
 *   NEEDLES NOW POINT AT A CONSTANT.** All three printed a self-contradiction — *"1 of the 6
 *   rival rules reproduce Lamont's 2019-01-09, expected exactly 1"* — because the condition and
 *   the message each held their own copy of the expectation. That is verbatim Oregon's finding:
 *   the copies agree in the shipped file, so the defect is invisible until a control makes them
 *   disagree, and nothing else ever does. 3d's three expectations now live in `exp_2019`,
 *   `exp_2023` and `exp_both`, and these three controls tamper the constant.
 *
 * 🔴🔴 **AND C5 IS A CONTROL ON A CHECK KEPT IN ORDER TO PASS.** `survive_2019 = 1` is the file
 *   asserting what its own in-data control LETS THROUGH. If that number ever stopped being 1 the
 *   file would quietly stop recording why a document was needed, with every other count still
 *   green. This is Idaho's C4 one state later, on a different shape.
 *
 * 🔴🔴 **TWO OF THE USUAL CONTROLS HAVE NOTHING REAL TO STAND ON — IDAHO'S SHAPE, A SECOND
 *   TIME.** All five winners are re-elections.
 *   • There is **no handover anywhere in the state**, so `CC_0510`'s `P6` arm asserting that a
 *     handover's predecessor is not the winner is **unreachable by construction**.
 *   • **No winner holds any office outside the wave**, so `P8`'s "nobody holds two seats" zero
 *     has **no natural fixture**. **C16 plants one — by REASSIGNING an existing federal term,
 *     never by inserting one.** A term with `term_start IS NULL` has an unbounded daterange and
 *     `office_terms_no_overlap` rejects anything beside it; that is the `(unparsed)` green RED
 *     that cost New Mexico's C20 and Nebraska's C16 a rebuild each. ▶ A planted fixture proves
 *     the gate FIRES; it does not prove the gate reads the rows a real double-holder would
 *     occupy. `P8b` asserts the absence itself.
 *
 * 🔴 **THE TWO GAPS BOTH GET A REAL FIXTURE, NOT A LITERAL TAMPER.** C10 gives the Secretary of
 *   the State a race row — the sixth office `art. IV § 1` names, with none of any year — and C11
 *   gives Connecticut a legislative office row by **re-typing an existing district**, which is
 *   the gate that matters most here: `art. III § 10` commences the whole General Assembly on
 *   **2027-01-06, this wave's own day**, so such a seat is invisible to every delta.
 *
 * ── WHAT IS NOT TESTED, AND WHY ─────────────────────────────────────────────────────────────
 *
 * Recorded as **backstops, not tested gates** — `CC_0510`'s `P3` re-election count, its five-name
 * check and `P6`'s predecessor-identity arms all sit below the pinned digest, so any realistic
 * tamper moves the digest two gates earlier. `CC_0509`'s `P2` is Alabama's shape: dropping a
 * title from the selection changes the TOTAL, so `P1` fires first. And `CC_0510`'s `P6` handover
 * arm is unreachable in a state with no handover.
 */
const M = '../../../migrations';
const p = (f) => new URL(`${M}/${f}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

/** One Connecticut state-executive office, by title, for a data tamper. */
const office = (title) => `
  SELECT o.id FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ct' AND d.district_type = 'STATE_EXEC' AND o.title = '${title}'`;

export default {
  name: 'Connecticut 2026 — CC_0509 / CC_0510',
  files: {
    dates: p('CC_0509_ct_2026_swearing_in_dates.sql'),
    seating: p('CC_0510_ct_2026_seat_5_winners.sql'),
  },
  cleanChain: ['dates', 'seating'],
  controls: [
    // ── CC_0509, the dates file ───────────────────────────────────────────────────────────────
    {
      id: 'C1',
      label: 'the first Monday computed a week late',
      aimedAt: 'assertion 3a',
      chain: [{
        tamper: 'dates',
        find: '  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);',
        replace: '  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7) + 7;',
      }],
    },
    {
      // 🔴🔴 THE NEAR MISS THAT IS THE SURVIVING RIVAL *AND* 178 LIVE MARYLAND ROWS. Reaching one
      //    week past Connecticut's answer produces another state's correct answer, never an
      //    absurd one — which is the whole reason this file computes rival rules at all.
      id: 'C2',
      label: "write 2027-01-13 — the SECOND Wednesday, Maryland's day and the surviving rival",
      aimedAt: 'assertion 1',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-06',\n       'statute',",
        replace: "       DATE '2027-01-13',\n       'statute',",
      }],
    },
    {
      id: 'C3',
      label: 'the second-Wednesday near miss mis-derived as the third',
      aimedAt: 'assertion 3b (the arithmetic arm)',
      chain: [{
        tamper: 'dates',
        find: '  r_second_wed := r_first_wed + 7;',
        replace: '  r_second_wed := r_first_wed + 14;',
      }],
    },
    {
      // 🔴🔴 THE COINCIDENCE IS ASSERTED, NOT ASSUMED. Two rivals land on the clause's own day in
      //    2027, and one of them is MAINE's — already on this square with a row of its own. A
      //    gate that quietly assumed every rival differs would be wrong here, so 3c states the
      //    agreement and this control breaks it.
      id: 'C4',
      label: "Maine's rule mis-derived, so 3c's asserted 2027 coincidence stops holding",
      aimedAt: 'assertion 3c',
      chain: [{
        tamper: 'dates',
        find: '  r_maine := jan1 + ((2 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);               -- first Tuesday',
        replace: '  r_maine := jan1 + ((2 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7) + 7;           -- first Tuesday',
      }],
    },
    {
      // 🔴🔴 A CONTROL ON A CHECK KEPT IN ORDER TO PASS. survive_2019 = 1 is the file asserting
      //    what its own in-data row LETS THROUGH — the second Wednesday. If that ever stopped
      //    being 1, the file would silently stop recording why a document was needed.
      id: 'C5',
      label: 'the 2019 survivor count expects 0 rivals instead of the measured 1',
      aimedAt: 'assertion 3d (the 2019 arm)',
      chain: [{
        tamper: 'dates',
        find: '        exp_2019     CONSTANT int  := 1;  -- the second Wednesday, and nothing else',
        replace: '        exp_2019     CONSTANT int  := 0;  -- the second Wednesday, and nothing else',
      }],
    },
    {
      id: 'C6',
      label: 'the 2023 survivor count expects 1 rival instead of the measured 2',
      aimedAt: 'assertion 3d (the 2023 arm)',
      chain: [{
        tamper: 'dates',
        find: "        exp_2023     CONSTANT int  := 2;  -- the first Wednesday, and Maine's rule",
        replace: "        exp_2023     CONSTANT int  := 1;  -- the first Wednesday, and Maine's rule",
      }],
    },
    {
      // 🟢🟢 THE ONE THAT REACHES THE LAST ARM. The three counts are coupled, so every obvious
      //    tamper fires on an earlier arm and the intersection gate is never reached. Swapping
      //    the first- and second-Wednesday expressions IN THE 2023 COLUMN ONLY leaves 2019
      //    untouched (survive_2019 stays 1) and leaves the 2023 set the same size (survive_2023
      //    stays 2) while putting the second Wednesday into BOTH — so survive_both becomes 1.
      //    ▶ Only a tamper that leaves every other count correct and self-consistent tests the
      //    last gate in a chain.
      id: 'C7',
      label: '🔴 a rival made to survive BOTH cycles while both earlier counts stay correct',
      aimedAt: 'assertion 3d (the intersection arm)',
      chain: [{
        tamper: 'dates',
        find: "               WHEN 'first_wed'  THEN fw23\n               WHEN 'second_wed' THEN fw23 + 7",
        replace: "               WHEN 'first_wed'  THEN fw23 + 7\n               WHEN 'second_wed' THEN fw23",
      }],
    },
    {
      // 🔴 THE ONLY TEST THAT SEPARATES THE CODIFIED ARTICLE FROM THE SUPERSEDED 1965 ONE. The
      //    cycle arithmetic passes on both copies (1966 and 1974 are each divisible-by-four from
      //    2026); only the officer list discriminates, and a FIVE here is exactly the shape that
      //    reading the first ARTICLE FOURTH in the PDF produces.
      id: 'C8',
      label: 'the membership test expects five officers — the superseded 1965 reading',
      aimedAt: 'assertion 3f',
      chain: [{
        tamper: 'dates',
        find: "                     'Comptroller', 'Attorney General');\n  IF n <> 6 THEN",
        replace: "                     'Comptroller', 'Attorney General');\n  IF n <> 5 THEN",
      }],
    },
    {
      // ⚠ 1975 is used rather than 1966 BECAUSE 1966 WOULD PASS. The superseded article's own
      //   anchor year is divisible-by-four from 2026 just as the codified one is, which is the
      //   finding C8 exists for.
      id: 'C9',
      label: "art. IV § 1's quadrennial cycle anchored on 1975 instead of 1974",
      aimedAt: 'assertion 3a (the cycle arm)',
      chain: [{
        tamper: 'dates',
        find: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1974) % 4 <> 0 THEN",
        replace: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1975) % 4 <> 0 THEN",
      }],
    },
    {
      // 🔴 A REAL FIXTURE FOR THE SIXTH OFFICE. The Secretary of the State has no race row of any
      //    year and is deliberately not dated; a race arriving must stop the file rather than
      //    leave a seat silently skipped.
      id: 'C10',
      label: 'a race row appears on the Secretary of the State — the sixth office art. IV § 1 names',
      aimedAt: 'assertion 3g',
      chain: [
        {
          sql: `INSERT INTO essentials.races (election_id, office_id, position_name, seats)
                  SELECT (SELECT id FROM essentials.elections
                           WHERE election_date = DATE '2026-11-03' LIMIT 1),
                         o.id, 'Secretary of the State (control fixture)', 1
                    FROM essentials.offices o
                    JOIN essentials.districts d ON d.id = o.district_id
                   WHERE lower(d.state) = 'ct' AND d.district_type = 'STATE_EXEC'
                     AND o.title = 'Secretary of the State';`,
        },
        'dates',
      ],
    },
    {
      // 🔴🔴 THE ABSENT LEGISLATURE, WITH A REAL FIXTURE AND NOT A LITERAL. art. III § 10
      //    commences every member of the General Assembly on 2027-01-06 — THIS FILE'S OWN DAY —
      //    so such a seat is invisible to every delta. The fixture RE-TYPES an existing district
      //    rather than creating one, which leaves offices_missing_terms and every row count
      //    untouched, so nothing else can fire first.
      id: 'C11',
      label: '🔴 Connecticut gains a STATE_LOWER office row, whose own clause names this very day',
      aimedAt: 'P4',
      chain: [
        {
          sql: `UPDATE essentials.districts SET district_type = 'STATE_LOWER'
                 WHERE id = (SELECT d.id FROM essentials.districts d
                              WHERE lower(d.state) = 'ct' AND d.district_type = 'NATIONAL_LOWER'
                              ORDER BY d.id LIMIT 1);`,
        },
        'dates',
      ],
    },
    {
      id: 'C12',
      label: 'the crowded-day before-image pinned at 199 instead of the real 200',
      aimedAt: 'P5',
      chain: [{
        tamper: 'dates',
        find: '  IF b.rows_jan6 <> 200 THEN',
        replace: '  IF b.rows_jan6 <> 199 THEN',
      }],
    },
    {
      // ⚠ A CONTROL PROVES A GATE CAN FAIL, NOT THAT IT READ THE RIGHT ROWS. Making the day gate
      //   blind to Connecticut must report FIVE strangers — that number is the evidence.
      id: 'C13',
      label: "assertion 4 stops recognising Connecticut's own rows on 2027-01-06",
      aimedAt: 'assertion 4',
      chain: [{
        tamper: 'dates',
        find: "     AND NOT (lower(dd.state) = 'ct'\n              AND s.rule_id = 'ct-const-art4-s2-wed-following-first-monday-january')",
        replace: "     AND NOT (lower(dd.state) = 'zz'\n              AND s.rule_id = 'ct-const-art4-s2-wed-following-first-monday-january')",
      }],
    },
    {
      id: 'C14',
      label: 'the dates file run twice in one transaction',
      aimedAt: 'P0',
      chain: ['dates', 'dates'],
    },

    // ── CC_0510, the seating file ─────────────────────────────────────────────────────────────
    {
      id: 'C15',
      label: "the Governor's winner re-pointed at the Lieutenant Governor",
      aimedAt: 'P3 digest',
      chain: [
        {
          sql: `UPDATE essentials.race_candidates
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Susan Bysiewicz' LIMIT 1)
                 WHERE id = (SELECT rc.id FROM essentials.race_candidates rc
                               JOIN essentials.races r     ON r.id = rc.race_id
                               JOIN essentials.elections e ON e.id = r.election_id
                               JOIN essentials.offices o   ON o.id = r.office_id
                               JOIN essentials.districts d ON d.id = o.district_id
                              WHERE lower(d.state) = 'ct' AND o.title = 'Governor'
                                AND e.election_date = DATE '2026-11-03' AND rc.result = 'won');`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🔴🔴 THE PLANTED TWO-SEAT FIXTURE. Connecticut has no real one, so this is the ONLY thing
      //    that shows P8 can fire. ▶ REASSIGN, NEVER INSERT: a second term inserted beside one
      //    with term_start IS NULL dies on the office_terms_no_overlap EXCLUSION constraint and
      //    prints an (unparsed) green RED, which has now cost two states a rebuild. Reassigning
      //    an existing open federal term leaves the digest, the predecessor pre-image and
      //    offices_missing_terms all untouched, so no other gate fires first.
      id: 'C16',
      label: "🔴 a U.S. Senate term reassigned to Ned Lamont, who is being seated as Governor",
      aimedAt: 'P8',
      chain: [
        {
          sql: `UPDATE essentials.office_terms
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Ned Lamont' LIMIT 1)
                 WHERE id = (SELECT t.id FROM essentials.office_terms t
                               JOIN essentials.offices o   ON o.id = t.office_id
                               JOIN essentials.districts d ON d.id = o.district_id
                              WHERE lower(d.state) = 'ct'
                                AND d.district_type = 'NATIONAL_UPPER'
                                AND t.term_end IS NULL
                              ORDER BY t.term_start LIMIT 1);`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C17',
      label: "the Comptroller's predecessor term already carries a term_end",
      aimedAt: 'P6',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_end = DATE '2027-06-30'
                 WHERE office_id IN (${office('Comptroller')}) AND term_end IS NULL;`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🟢🟢 THE ONE ROW THE WHOLE DATE RESTS ON. Moving it must stop the chain: seat_officeholder
      //    writes nothing to a closed row's source, so a lost start is unrecoverable — and this
      //    is the only in-data corroboration art. IV § 2 has.
      //    ⚠ EXPECTED TO FIRE ON THE DATES FILE, NOT THE SEATING FILE, and that is the right
      //    order: the row is what CC_0509's own corroboration control reads, so the chain refuses
      //    before anything is written. The harness records which gate it actually reached.
      id: 'C18',
      label: "Ned Lamont's 2019-01-09 moved — the only corroboration art. IV § 2 has",
      aimedAt: 'assertion 3d (the clause arm)',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_start = DATE '2019-01-16'
                 WHERE office_id IN (${office('Governor')}) AND term_start = DATE '2019-01-09';`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C19',
      label: "the Treasurer's office flagged is_vacant before a future-dated seating",
      aimedAt: 'P6',
      chain: [
        { sql: `UPDATE essentials.offices SET is_vacant = true WHERE id IN (${office('Treasurer')});` },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C20',
      label: "seat_officeholder given a literal 2027-01-13 — Maryland's day, the surviving rival",
      aimedAt: 'assertion 1',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '      p_term_start       => s.term_start,',
          replace: "      p_term_start       => DATE '2027-01-13',",
        },
      ],
    },
    {
      id: 'C21',
      label: 'assertion 3 stops recognising Connecticut as an owner of 2027-01-06',
      aimedAt: 'assertion 3',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: "   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('ct', 'ma', 'me');",
          replace: "   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('zz', 'ma', 'me');",
        },
      ],
    },
    {
      // 🔴🔴 THE GATE THAT CARRIES THE ABSENT LEGISLATURE INTO THE SEATING FILE. The day's delta
      //    cannot see a Connecticut legislative term, because art. III § 10 puts it on exactly
      //    this date; 3b is what looks INSIDE the state. Inverting its membership test makes it
      //    read the wave's own five rows and report them as strangers.
      id: 'C22',
      label: "3b's in-state check inverted — it must then see this wave's own five terms",
      aimedAt: 'assertion 3b',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '     AND t.office_id NOT IN (SELECT office_id FROM cc0510_sel);',
          replace: '     AND t.office_id IN (SELECT office_id FROM cc0510_sel);',
        },
      ],
    },
    {
      id: 'C23',
      label: "the day's term before-image pinned at 199 instead of the real 200",
      aimedAt: 'P9',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '       200                                AS expect_terms_on_the_day_before,',
          replace: '       199                                AS expect_terms_on_the_day_before,',
        },
      ],
    },
    {
      id: 'C24',
      label: 'the seating file run twice in one transaction',
      aimedAt: 'P1',
      chain: ['dates', 'seating', 'seating'],
    },
  ],
};
