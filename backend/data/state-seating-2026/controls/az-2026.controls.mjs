/**
 * Arizona 2026 — the control suite run against `CC_0497` and `CC_0498` before they were applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     ../data/state-seating-2026/controls/az-2026.controls.mjs
 *
 * ⚠ **A SUITE CANNOT BE RE-RUN ONCE ITS CHAIN IS APPLIED** — the negative control fails and the
 *   harness refuses to report, which is correct. This file is the RECORD of what was tested.
 *   `--check` validates the needles against the migrations without touching the database.
 *
 * 🔴🔴 **THE ONE ARIZONA CAN DO THAT MARYLAND COULD NOT: C13 TESTS RULING A'S EQUALITY CLAUSE
 *   WITH A REAL STAGGERED BODY.** Maryland had to manufacture one by deleting a winner from a
 *   three-member district, because all 67 of its contests passed equality exactly. Arizona holds
 *   the worked counter-example from Ruling A itself — the **Corporation Commission**: five office
 *   rows, two winners, and neither winner holding any of the five. `CC_0498` excludes it by
 *   title, so the tamper is simply to stop excluding it, and `P2a` must refuse the whole file
 *   rather than hand two of five sitting commissioners' chairs to people who did not win them.
 *   That is the gate with the real-world cost, tested against the body it was written for.
 *
 * 🔴 **AND C13b RUNS THE SUPERSEDED CLAUSE BESIDE IT.** With "at least" in place of equality the
 *   Commission is ADMITTED, and the only thing that notices is the pin's row count — two gates
 *   later, reporting "the data moved under this file" instead of "this body is staggered". That
 *   is the backstop problem stated as a measurement, and it is why Ruling A sits above the pin.
 *
 * ⚠ **TWO CONTROLS HERE EXIST ONLY BECAUSE OF A CORRECTION TO CC_0496's TEMPLATE.** Maryland
 *   wrote the Ruling A paragraph into the `source` of every non-anchored seat, including
 *   single-seat successions no ruling touched. CC_0498 writes it only for a non-anchored winner
 *   of a multi-seat race — 24 rows of 39 — and C19 checks the claim in both directions: a fill
 *   that does not say so cannot be audited, and a single-seat handover that CLAIMS a ruling
 *   decided it is the same defect pointing the other way.
 *
 * ⚠ **AND C20 IS THE POSITIVE CONTROL FOR A ZERO.** `P8` asserts that nobody is left holding two
 *   seats. Arizona's answer is zero, and a detector that has never found anything has not been
 *   shown to work — Maryland's found Kipke, Utah's found Fiefia. C20 plants one.
 */
const M = '../../../migrations';
const f = (name) =>
  new URL(`${M}/${name}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

// State Senate District 10 is the vacancy fixture: ONE Senate office, held by David C.
// Farnsworth, who is also its only 2026 winner. Closing his term removes the holder without
// changing which office anybody lands in — a House district would move the Ruling A fill order
// too, and then the control would be testing two things at once.
const VACATE_SD10 = `UPDATE essentials.office_terms t
   SET term_end = DATE '2026-11-20', how_ended = 'resigned'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'az' AND d.label = 'State Senate District 10'
   AND d.district_type = 'STATE_UPPER'
   AND t.term_end IS NULL;`;

export default {
  name: 'Arizona 2026 — CC_0497 / CC_0498',
  files: {
    dates: f('CC_0497_az_2026_swearing_in_dates.sql'),
    seating: f('CC_0498_az_2026_seat_93_winners.sql'),
  },
  cleanChain: ['dates', 'seating'],
  controls: [
    // ── CC_0497, the dates file ───────────────────────────────────────────────────────────────
    {
      // 🔴 IN ARIZONA THE NEAR MISS IS A LIVE DAY TWICE OVER: the second Monday is this state's
      //    own SESSION convening day under Art. IV, Pt. 2, § 3, AND the term start of 118
      //    Washington and 75 Oregon seats. A wave written one week late is not obviously absurd.
      id: 'C1',
      label: "write 2027-01-11 — the second Monday, Arizona's SESSION day and 193 WA/OR terms",
      aimedAt: 'assertion 3b',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-04',\n       'statute',",
        replace: "       DATE '2027-01-11',\n       'statute',",
      }],
    },
    {
      id: 'C2',
      label: 'the first Monday computed as the second Monday',
      aimedAt: 'assertion 3a',
      chain: [{
        tamper: 'dates',
        find: "  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);\n  second_mon := first_mon + 7;\n  IF first_mon <> az_day THEN",
        replace: "  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7) + 7;\n  second_mon := first_mon + 7;\n  IF first_mon <> az_day THEN",
      }],
    },
    {
      // 🟢🟢 THE HISTORICAL CONTROL'S DISCRIMINATING ARM. Assertion 3d runs all three candidate
      //    rules over three Arizona cycles in our own data and requires the two wrong ones to
      //    carry ZERO rows. Moving a single real term onto the second Monday of 2023 must make
      //    it go red — otherwise the gate agrees with the right rule rather than separating it
      //    from the wrong one, which is the Washington lesson (CC_0487 assertion 3).
      id: 'C3',
      label: 'one 2023 Arizona term moved onto the SECOND Monday (2023-01-09)',
      aimedAt: 'assertion 3d',
      chain: [{
        sql: `UPDATE essentials.office_terms t
   SET term_start = DATE '2023-01-09'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'az' AND d.district_type = 'STATE_UPPER'
   AND t.term_start = DATE '2023-01-02' AND t.start_precision = 'day'
   AND t.id = (SELECT t2.id FROM essentials.office_terms t2
                 JOIN essentials.offices o2 ON o2.id = t2.office_id
                 JOIN essentials.districts d2 ON d2.id = o2.district_id
                WHERE lower(d2.state) = 'az' AND d2.district_type = 'STATE_UPPER'
                  AND t2.term_start = DATE '2023-01-02' AND t2.start_precision = 'day'
                ORDER BY t2.id LIMIT 1);`,
      }, 'dates'],
    },
    {
      // The three-cycle claim itself. One cycle is 53 rows and still "agrees with the rule";
      // 80 across three is what makes it a corpus rather than a coincidence.
      id: 'C4',
      label: 'the historical control narrowed to a single cycle (2023 only)',
      aimedAt: 'assertion 3d (the 80-row total)',
      chain: [{
        tamper: 'dates',
        find: '  FOR y IN SELECT generate_series(2021, 2025, 2) LOOP',
        replace: '  FOR y IN SELECT generate_series(2023, 2023, 2) LOOP',
      }],
    },
    {
      // 🔴🔴 ARIZONA IS THE THIRD STATE ON 2027-01-04 AND WISCONSIN'S RULE IS ALSO CALLED A
      //    FIRST MONDAY. P6 requires every row already on the day to belong to a NAMED rule, so
      //    a fourth state is caught rather than absorbed into Arizona's delta.
      id: 'C5',
      label: 'an existing 2027-01-04 row given an unknown rule_id',
      aimedAt: 'P6',
      // ⚠ THE FIRST VERSION OF THIS CONTROL WENT RED ON A SYNTAX ERROR AND LOOKED LIKE A PASS
      //   OF THE SUITE. It said `WHERE id = (…)`; essentials.office_swearing_in has no `id` —
      //   its key is (office_id, election_date) — so the step died with `column "id" does not
      //   exist`, the harness could not parse a gate out of it, and the summary printed a green
      //   RED with "(unparsed)". ▶ READ THE MESSAGE, NOT THE COLOUR. Maryland's C11 and C15 died
      //   on a database CHECK constraint the same way.
      chain: [{
        sql: `UPDATE essentials.office_swearing_in
   SET rule_id = 'control-c5-some-fourth-state-rule'
 WHERE (office_id, election_date) = (
   SELECT office_id, election_date FROM essentials.office_swearing_in
    WHERE swearing_in_date = DATE '2027-01-04'
    ORDER BY office_id, election_date LIMIT 1);`,
      }, 'dates'],
    },
    {
      // 🔴 THE REFUSED OFFICE REACHING THE SELECTION. The Superintendent is swapped OUT and the
      //    State Mine Inspector swapped IN, so every count in P1 still reads what it expects and
      //    the tamper reaches the gate written for it rather than being caught by arithmetic.
      id: 'C6',
      label: 'the State Mine Inspector dated in place of the Superintendent',
      aimedAt: 'P4',
      chain: [{
        tamper: 'dates',
        find: "     AND o.title IN ('Governor', 'Secretary of State', 'Attorney General', 'Treasurer',\n                     'Superintendent of Public Instruction', 'Commissioner')",
        replace: "     AND o.title IN ('Governor', 'Secretary of State', 'Attorney General', 'Treasurer',\n                     'State Mine Inspector', 'Commissioner')",
      }],
    },
    {
      // Dating all five Commissioner rows would claim five seats were on the 2026 ballot. The
      // body is staggered and two were. P1's ccm/exec split is what holds that line.
      id: 'C7',
      label: 'the Corporation Commission row counted as an ordinary executive',
      aimedAt: 'P1 (the ccm/exec split)',
      chain: [{
        tamper: 'dates',
        find: "         CASE WHEN o.title = 'Commissioner' THEN 'ccm' ELSE 'exec' END AS grp",
        replace: "         'exec'::text AS grp",
      }],
    },
    {
      // 🔴 THE MISSING RESULT ARRIVING. If District 27 gains a winner the wave is 96 offices,
      //    not 94, and this file's pin is stale. ⚠ Lisa Fink and Tony Rivero are not only two of
      //    the three candidates — they are the SITTING members of those two seats.
      id: 'C8',
      label: "State House District 27 gains a recorded winner",
      aimedAt: 'P3',
      chain: [{
        sql: `UPDATE essentials.race_candidates rc
   SET result = 'won', result_certainty = 'called',
       result_source = 'CONTROL C8 — must never reach production'
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'az' AND d.label = 'State House District 27'
   AND rc.id IN (SELECT rc2.id FROM essentials.race_candidates rc2
                  WHERE rc2.race_id = r.id ORDER BY rc2.full_name LIMIT 2);`,
      }, 'dates'],
    },
    {
      // ⚠ 'advanced' IS THE AUGUST PRIMARY'S RESULT, NOT A NOVEMBER ONE STILL BEING COUNTED, and
      //   unrecorded looks identical to undecided from the seat. P3 reads the result rather than
      //   inferring from the absence of a winner.
      id: 'C9',
      label: "one District 27 candidate loses the primary's 'advanced' result",
      aimedAt: "P3 (the 'advanced' arm)",
      chain: [{
        sql: `UPDATE essentials.race_candidates rc
   SET result = NULL, result_certainty = NULL, result_source = NULL
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'az' AND d.label = 'State House District 27'
   AND rc.id = (SELECT rc2.id FROM essentials.race_candidates rc2
                 WHERE rc2.race_id = r.id ORDER BY rc2.full_name LIMIT 1);`,
      }, 'dates'],
    },
    {
      // 🔴 A CITATION CAN BE RIGHT ABOUT THE DATE AND WRONG ABOUT THE LAW, AND NO COUNT CAN SEE
      //    IT. One rule_id covers three constitutional provisions here, so assertion 7b is the
      //    only mechanical trace of which clause dated which seat. Arizona's § 3 — the SESSION —
      //    is the wrong citation that lands on a different day a week later, and § 21 is right.
      id: 'C10',
      label: 'the 88 legislative rows cite Art. IV, Pt. 2, § 3 (the SESSION) instead of § 21',
      aimedAt: 'assertion 7b',
      chain: [{
        tamper: 'dates',
        find: "           'Ariz. Const. Art. IV, Pt. 2, § 21 — \"The members of the first legislature shall '",
        replace: "           'Ariz. Const. Art. IV, Pt. 2, § 3 — \"The members of the first legislature shall '",
      }],
    },

    // ── CC_0498, the seating file ─────────────────────────────────────────────────────────────
    {
      // 🔴🔴 THE RULING A POST-VERIFY, AND THE ONLY CONTROL HERE THAT REACHES ONE. Built the way
      //    scripts/lib/seating-wave.mjs publishes it — joining office_terms back on the
      //    RACE-CARRYING office — assertion 1 finds the 64 race-carrying seats and misses the 29
      //    siblings, AFTER the write. The message is the evidence: it must report the shortfall,
      //    not a vacuous zero.
      id: 'C11',
      label: 'post-verify 1 joins office_terms back on the RACE-CARRYING office',
      aimedAt: 'assertion 1',
      chain: ['dates', {
        tamper: 'seating',
        find: "    FROM essentials.office_terms t JOIN cc0498_sel s ON s.office_id = t.office_id\n   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;",
        replace: "    FROM essentials.office_terms t JOIN cc0498_sel s ON s.race_office_id = t.office_id\n   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;",
      }],
    },
    {
      // Ruling A's fill order is part of the claim, and the digest is what pins it. Reversing it
      // moves real people between real seats without changing a single count.
      id: 'C12',
      label: 'the Ruling A fill order reversed (office_id DESC)',
      aimedAt: 'P3 digest',
      chain: ['dates', {
        tamper: 'seating',
        find: "         row_number() OVER (PARTITION BY e.race_office_id ORDER BY e.office_id::text) AS rn\n    FROM cc0498_elig e",
        replace: "         row_number() OVER (PARTITION BY e.race_office_id ORDER BY e.office_id::text DESC) AS rn\n    FROM cc0498_elig e",
      }],
    },
    {
      // 🔴🔴🔴 THE GATE WITH THE REAL-WORLD COST, TESTED AGAINST THE BODY IT WAS WRITTEN FOR.
      //    Stop excluding the Corporation Commission and a genuinely STAGGERED body enters the
      //    selection: 2 winners, 5 eligible offices, and neither winner holding any of the five.
      //    P2a must name it and refuse. Maryland had to manufacture this shape by deleting a
      //    winner; Arizona ships with it.
      id: 'C13',
      label: 'the Corporation Commission no longer excluded — 2 winners, 5 eligible seats',
      aimedAt: 'P2a',
      chain: ['dates', {
        tamper: 'seating',
        find: "   AND o.title NOT IN ('Commissioner', 'State Mine Inspector');\n\n-- Every Arizona state race, including the two this file refuses",
        replace: "   AND o.title NOT IN ('State Mine Inspector');\n\n-- Every Arizona state race, including the two this file refuses",
      }],
    },
    {
      // 🔴🔴 THE SUPERSEDED CLAUSE, RUN BESIDE THE RIGHT ONE. "At least" ADMITS the staggered
      //    body: 5 >= 2 passes, nothing anchors, and the fall-through fills two of the five
      //    seats outright. Watch WHICH gate notices, and what it says: if the answer is a row
      //    count reporting "the data moved under this file", then the clause carrying the
      //    real-world cost has no diagnosis of its own, which is exactly why Ruling A sits
      //    above the pin.
      id: 'C13b',
      label: 'the equality clause weakened to "at least", over a staggered House district',
      aimedAt: 'P2a (expected to PASS — watch which gate notices instead)',
      // ⚠ THE FIRST VERSION OF THIS CONTROL COULD NOT BE EXPRESSED IN THIS HARNESS, AND THE WAY
      //   IT FAILED IS WORTH WRITING DOWN. It used two `{tamper: 'seating'}` steps — one to
      //   admit the Corporation Commission, one to weaken the clause — and a step is a FILE,
      //   not an edit, so the chain ran the seating migration TWICE and died on its own P1,
      //   "93 office_terms row(s) already cite CC_0498. Applied before." It went red, on a gate
      //   that had nothing to do with the question. ▶ One tamper per step; put the second change
      //   in the DATA.
      //
      //   So the staggered shape is planted in the data instead: State House District 1 loses
      //   one of its two winners, exactly as C14 does. C14 watches the equality clause REFUSE
      //   it. Here the clause is weakened to "at least" — 2 eligible >= 1 winner — and P2a lets
      //   it through. 🔴 MEASURED: what notices is **P2d**, the bijection check, and all it can
      //   say is *"the assignment produced 92 rows for 93 winners"* — an arithmetic complaint,
      //   not "this body is staggered and which seats are up is not in our data". The operator
      //   would go looking for a lost winner. That is the backstop problem as a measurement,
      //   and it is why the equality clause has to be its own gate rather than something a
      //   later count happens to catch.
      chain: ['dates', {
        sql: `UPDATE essentials.race_candidates rc
   SET result = NULL, result_certainty = NULL, result_source = NULL
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03' AND rc.result = 'won'
   AND lower(d.state) = 'az' AND d.label = 'State House District 1'
   AND d.district_type = 'STATE_LOWER'
   AND rc.id = (SELECT rc2.id FROM essentials.race_candidates rc2
                 WHERE rc2.race_id = r.id AND rc2.result = 'won'
                 ORDER BY rc2.full_name LIMIT 1);`,
      }, {
        tamper: 'seating',
        find: "   WHERE z.winners <> z.eligible;",
        replace: "   WHERE z.eligible < z.winners;",
      }],
    },
    {
      // The same clause inside the body this wave actually fills. A House district with one
      // recorded winner and two seats is the staggered shape in miniature, and filling "the
      // remaining office" would hand a sitting member's chair to nobody who won it.
      id: 'C14',
      label: 'State House District 1 loses one of its two winners — 1 winner, 2 eligible seats',
      aimedAt: 'P2a',
      chain: ['dates', {
        sql: `UPDATE essentials.race_candidates rc
   SET result = NULL, result_certainty = NULL, result_source = NULL
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03' AND rc.result = 'won'
   AND lower(d.state) = 'az' AND d.label = 'State House District 1'
   AND d.district_type = 'STATE_LOWER'
   AND rc.id = (SELECT rc2.id FROM essentials.race_candidates rc2
                 WHERE rc2.race_id = r.id AND rc2.result = 'won'
                 ORDER BY rc2.full_name LIMIT 1);`,
      }, 'seating'],
    },
    {
      // The anchor is the half of Ruling A that is NOT arbitrary: a winner who already holds an
      // eligible seat keeps it. Inverting the test unseats 54 people into sibling chairs.
      id: 'C15',
      label: 'the incumbent anchor inverted (anchor to a seat you do NOT hold)',
      aimedAt: 'P3h',
      chain: ['dates', {
        tamper: 'seating',
        find: " WHERE w.politician_id IS NOT NULL AND och.politician_id = w.politician_id;",
        replace: " WHERE w.politician_id IS NOT NULL AND och.politician_id <> w.politician_id;",
      }],
    },
    {
      // 🔴🔴 THE COVERAGE GATE. A seat loses its holder AND the library's published selection is
      //    used (no `och.politician_id IS NOT NULL`), so is_reelection goes NULL, the
      //    concatenation goes NULL, and string_agg drops the row — every count still reads 93.
      id: 'C16',
      label: "Senate District 10 falls vacant AND the library's published selection is used",
      aimedAt: 'P3 coverage',
      chain: ['dates', { sql: VACATE_SD10 }, {
        tamper: 'seating',
        find: "       (a.politician_id IS NOT NULL\n         AND och.politician_id IS NOT NULL\n         AND och.politician_id = a.politician_id)         AS is_reelection,",
        replace: "       (a.politician_id IS NOT NULL\n         AND och.politician_id = a.politician_id)         AS is_reelection,",
      }],
    },
    {
      // The SAME vacancy with the fix in place: the value becomes false instead of vanishing, so
      // the DIGEST gate catches it. Neither gate can see the other's fault — this is the pair
      // that proves they are complementary rather than redundant, on one input.
      id: 'C16b',
      label: 'the same vacancy, with the IS NOT NULL fix in place',
      aimedAt: 'P3 digest',
      chain: ['dates', { sql: VACATE_SD10 }, 'seating'],
    },
    {
      // 🔴🔴 P2g RECOMPUTES EACH REFUSAL RATHER THAN NAMING IT. The Mine Inspector is refused ON
      //    THE DATE, and the inference that it follows the first Monday like every other Arizona
      //    office is written down in CC_0497's header and deliberately not written in. If a date
      //    row appears, the file must stop and make somebody read its authority.
      id: 'C17',
      label: 'the State Mine Inspector gains a swearing-in row after the dates file runs',
      aimedAt: 'P2g',
      chain: ['dates', {
        sql: `INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source)
SELECT o.id, DATE '2026-11-03', DATE '2027-01-04', 'statute', 'control-c17',
       'CONTROL C17 — must never reach production',
       'CONTROL C17 — must never reach production'
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'az' AND o.title = 'State Mine Inspector';`,
      }, 'seating'],
    },
    {
      // 🔴 THE OTHER HALF OF P2g. If the Commission's race ever carried five winners the body
      //    would stop being staggered from our side and the exclusion would need re-arguing —
      //    not quietly keeping, and not quietly dropping either.
      id: 'C18',
      label: "the Corporation Commission's race carries a third winner",
      aimedAt: 'P2g',
      // ⚠ THE FIRST VERSION OF THIS CONTROL DID NOT APPLY AND THE CHAIN PASSED. It looked for a
      //   Commission candidate with `result IS NULL` and there is none: the seven rows read
      //   won / won / lost / lost / lost / not_nominated / not_nominated. The harness reported
      //   DID NOT FIRE rather than a pass, which is the whole reason it re-reads what it built —
      //   "a tamper that did not apply is a control that proved nothing, and it looks like a
      //   pass". The tamper now promotes a real LOSER, Kevin Thompson.
      chain: ['dates', {
        sql: `UPDATE essentials.race_candidates rc
   SET result = 'won'
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'az' AND o.title = 'Commissioner'
   AND rc.full_name = 'Kevin Thompson' AND rc.result = 'lost';`,
      }, 'seating'],
    },
    {
      // ⚠ THE CORRECTION TO CC_0496's TEMPLATE, TESTED. Writing the Ruling A paragraph for every
      //   non-anchored seat puts it on 39 rows instead of 24 — including single-seat Senate and
      //   executive successions that no ruling decided. A row that claims a ruling settled it is
      //   the same defect as a fill that does not say so, pointing the other way.
      id: 'C19',
      label: 'the Ruling A paragraph written for every handover, not only for a fill',
      aimedAt: 'assertion 15 (Ruling A arm)',
      chain: ['dates', {
        tamper: 'seating',
        find: "                         || CASE WHEN r.ruling_a_fill THEN",
        replace: "                         || CASE WHEN NOT r.anchored THEN",
      }],
    },
    {
      // ⚠ THE POSITIVE CONTROL FOR P8's ZERO. Arizona expects nobody left holding two seats, and
      //   a detector that has never found anything has not been shown to work. Mark Finchem wins
      //   Senate District 1 and is given the sitting District 27 House term — a seat this wave
      //   cannot fill, because that contest has no recorded result. That is Maryland's Kipke and
      //   Utah's Fiefia, planted.
      id: 'C20',
      label: "a Senate winner given the open District 27 House term — the Kipke shape, planted",
      aimedAt: 'P8',
      chain: ['dates', {
        sql: `UPDATE essentials.office_terms
   SET politician_id = '489e2fc3-b47a-4304-b959-07e35f010da4'
 WHERE id = '555d4158-8503-4ffd-97f5-a39a2d9cba31';`,
      }, 'seating'],
    },
    {
      // 🔴🔴 THE 2027-01-04 DELTA ON TERMS. Arizona is the third state on this day and
      //    Wisconsin's rule is also a first Monday, so P10 pins the before-image rather than
      //    reading a total.
      id: 'C21',
      label: 'one Wisconsin term moved off 2027-01-04 before the seating file runs',
      aimedAt: 'P10',
      chain: ['dates', {
        sql: `UPDATE essentials.office_terms t
   SET term_start = DATE '2027-01-05'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'wi' AND t.term_start = DATE '2027-01-04'
   AND t.id = (SELECT t2.id FROM essentials.office_terms t2
                 JOIN essentials.offices o2 ON o2.id = t2.office_id
                 JOIN essentials.districts d2 ON d2.id = o2.district_id
                WHERE lower(d2.state) = 'wi' AND t2.term_start = DATE '2027-01-04'
                ORDER BY t2.id LIMIT 1);`,
      }, 'seating'],
    },
    {
      // Ruling B: the wave seats from a CALLED result and says so.
      id: 'C22',
      label: "Senate District 1's result becomes certified",
      aimedAt: 'P11',
      chain: ['dates', {
        sql: `UPDATE essentials.race_candidates rc
   SET result_certainty = 'certified'
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'az' AND d.label = 'State Senate District 1'
   AND d.district_type = 'STATE_UPPER';`,
      }, 'seating'],
    },
    {
      id: 'C23',
      label: 'the written term source stops saying "called, not certified"',
      aimedAt: 'assertion 15',
      chain: ['dates', {
        tamper: 'seating',
        find: "                         || 'called, not certified, when this ran. Term begins '",
        replace: "                         || 'when this ran. Term begins '",
      }],
    },
  ],
};
