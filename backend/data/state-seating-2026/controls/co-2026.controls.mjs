/**
 * Colorado 2026 — the control suite for `CC_0516` (dates, 19 offices across two days), `CC_0517`
 * (9 legislative seats on 2027-01-11) and `CC_0518` (9 executive and board seats on 2027-01-12),
 * run 2026-11-25 before any of the three was applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     data/state-seating-2026/controls/co-2026.controls.mjs
 *
 * ⚠ **ONCE THE CHAIN IS APPLIED THIS SUITE CANNOT BE RE-RUN, AND THAT IS CORRECT.** The negative
 *   control fails and the harness refuses to report. It is kept as the RECORD of what was tested.
 *   `--check` validates every needle without touching the database.
 *
 * ── WHAT THIS STATE MADE DIFFERENT ──────────────────────────────────────────────────────────
 *
 * 🔴🔴🔴 **THE RIVAL RULE THIS STATE CANNOT REFUSE IS SITTING ON ITS OWN CALENDAR SQUARE, UNDER A
 *   `rule_id` THAT SAYS SO IN WORDS.** Colorado's legislative day is **designated** by HOUSE JOINT
 *   RESOLUTION 26-1031, not computed — and "the second Monday in January" gives the same
 *   2027-01-11 in this cycle. That day already carries **193 terms** under
 *   `or-const-art4-s4-second-monday-january` (75) and `wa-rcw-44-04-021-second-monday-january`
 *   (118). Arizona's warning was that a rival's `rule_id` *may even share its words*; this one
 *   shares the words, the day **and** the year. ▶ **C11 is the only thing in this suite that can
 *   see it**: it re-dates Colorado's nine seats under Washington's `rule_id`, leaving the DAY
 *   untouched, so every date gate in all three files passes and only `CC_0517`'s P4 notices.
 *
 * 🔴🔴 **C5 AND C6 ARE CONTROLS ON A GATE KEPT GREEN ON PURPOSE, AND THE GATE IS AN ABSENCE.** A
 *   `published` basis is the claim that the day comes from a document rather than a formula, so
 *   the evidence for it is that **every formula fails**. `CC_0516`'s assertion 3d runs nine rules
 *   over four prior cycles and asserts the statutory default reproduces exactly **2** and the
 *   second Monday exactly **1** — numbers kept in order to *pass*, because they are what records
 *   the rival that survives. Nothing else in this suite would ever make either move. This is
 *   Idaho's C4, Connecticut's C5 and Texas's C5 on a fourth shape.
 *
 * 🔴🔴 **C7 IS THE ONLY MECHANICAL TRACE OF A WRONG CITATION, AND IT IS CHECKED BY POSITION
 *   BECAUSE TEXAS PROVED A SUBSTRING TEST CANNOT SEE IT.** `DATES.md § CO` attributes the State
 *   Board of Education's five "second Tuesday in January" anchors to **C.R.S. § 22-2-104(1)**.
 *   That section is *"Offices and positions - nature"* and contains **no date of any kind**; every
 *   quoted word is in **§ 22-2-105(1)**. 🔴 **The DAY is unaffected**, so no count, digest or view
 *   can tell the right citation from the wrong one. And the `authority` field **names § 22-2-104
 *   in its own body**, because it explains the correction — so a `LIKE '%§ 22-2-105(1)%'` test
 *   would be satisfied by the sentence that exists to record the error. Assertion 7 checks the
 *   **front** of the field; C7 swaps the opening citation to the ledger's wrong one and nothing
 *   else in the file moves.
 *
 * 🔴🔴 **C18 RE-PLANTS TEXAS's SHARED-CLOSURE-DAY DEFECT IN A BIGGER FORM.** `CC_0517`'s closure
 *   day is **2027-01-10**, the day before Oregon's 75 and Washington's 118 legislative terms
 *   begin, so **193 terms already end there**. Texas's first rehearsal asserted that as a TOTAL
 *   and fired on 68 innocent rows; here it would fire on 193. C18 reverts assertion 6c to the
 *   total and watches it report other states' correct rows as a fault.
 *
 * 🔴🔴 **C23 IS PURPOSE-BUILT TO REACH THE CHAIN GATE, AND NOTHING ELSE CAN.** Three of
 *   `CC_0518`'s five handovers form a chain — Polis → Weiser (Governor), Weiser → Griswold
 *   (Attorney General), Griswold → Gonzalez (Secretary of State) — and assertion 9's zero is
 *   produced by that chain closing on itself rather than by nobody moving. C23 reassigns the
 *   Secretary of State's predecessor term to somebody else, which leaves the digest, every count,
 *   the handover/re-election split and the name list all **correct**, and `P7` is the first gate
 *   that notices. This is Connecticut's C7 discipline: any obvious tamper fires two gates earlier.
 *
 * ── THE RESULT, MEASURED 2026-11-25 ─────────────────────────────────────────────────────────
 *
 * **32 of 32 went red and the negative control passed**; **28 fired on the gate they were aimed
 * at**. 🔴 **THE FIRST RUN FOUND THREE DEFECTS IN THIS SUITE AND NONE IN THE MIGRATIONS**, which
 * is the other reason to run controls rather than review them:
 *
 * • **C11 AND C19 CAME BACK AS `(unparsed)` GREEN REDS.** Both set `race_candidates.result` and
 *   neither set `result_source`, so the CHECK constraint `race_candidates_result_needs_source`
 *   rejected the UPDATE and **the tamper never applied**. The harness reported red for a fault
 *   that was its own. Verbatim the Maryland and Arizona and Alabama cases in `PICKUP.md`: **read
 *   the message, not the colour**, and a fixture built out of live rows needs as much reading as
 *   the gate does.
 * • **C4 FIRED TWO GATES EARLY.** Moving `grp_a_day` to Monday 2027-01-18 — Alabama's live day —
 *   left the INSERT saying 2027-01-11, so assertion 1 caught the disagreement before 3a could ask
 *   whether the day was lawfully designable. Narrowing the WINDOW instead reaches 3a.
 * • **C17 FIRED ON P6.** Capturing a NULL `term_start` in the pre-image moves P6's "all nine
 *   predecessors are dated" count from nine to zero. Capturing each start **one day late** keeps
 *   that count at nine and leaves 6b as the first gate that can see it.
 *
 * ── WHAT IS NOT TESTED, AND WHY ─────────────────────────────────────────────────────────────
 *
 * Recorded as **backstops, not tested gates**, each with the gate its tamper ACTUALLY fired on:
 *
 * • **`CC_0516`'s assertion 3c, the order gate** (Group A must precede Group B, because Art. IV
 *   § 3 requires the canvass on the legislature's organisation day). It reads only the two date
 *   CONSTANTS, and assertions 1 and 2 compare every written row against those same constants — so
 *   any tamper that moves one fires two gates earlier. **C3 is the attempt and it fired on
 *   assertion 1.** The relation is a real claim and it is covered; it is not tested.
 * • **`CC_0516`'s assertion 2, the per-group arm.** **C2 fired on assertion 1**, which compares
 *   each row against its own group's constant and is strictly stronger. Covered, not tested.
 * • 🔴🔴 **`CC_0516`'s P5 no-winner arm and `CC_0517`'s P5 named-seat arm are BOTH COUPLED TO THE
 *   SELECTION SIZE, AND THAT IS A STRUCTURAL FACT RATHER THAN A WEAK TAMPER.** Recording a winner
 *   on the Lieutenant Governor's race, or on House District 21, puts that office into
 *   `office_pending_winner` — so the selection grows and **P1 (C11) and P2 (C19) refuse it two
 *   gates earlier**. There is no tamper that gives a race a winner without growing the wave. ▶ The
 *   arms are therefore covered by the size gates, and the *reachable* parts of P5 have their own
 *   controls instead: **C31** removes a Lieutenant Governor candidate (seven becomes six while the
 *   office stays unpending) and **C32** moves the House gap's pinned 59 to 58.
 * • **`CC_0517`'s assertion 6b** is proved to FIRE by C17, which tampers the pre-image's own
 *   capture. It is **not** proved to catch a real move made by `seat_officeholder`, because the
 *   gate compares the live rows against the pre-image this file itself captured and any data
 *   tamper lands in both images. Different claims, said plainly.
 * • **`CC_0516`'s assertion 5 "no strangers on 2027-01-12"** cannot discriminate, because that
 *   square carried **0 rows** before this file. Said in the file rather than offered as a
 *   measurement, exactly as Texas's 2027-01-19 was.
 */

const M = '../../../migrations';
const p = (f) => new URL(`${M}/${f}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

/** One Colorado office, by district label, for a data tamper. */
const byLabel = (label) => `
  SELECT o.id FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.label = '${label}'`;

/** One Colorado state office, by title, for a data tamper. */
const byTitle = (title) => `
  SELECT o.id FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_EXEC' AND o.title = '${title}'`;

export default {
  name: 'Colorado 2026 — CC_0516 / CC_0517 / CC_0518',
  files: {
    dates: p('CC_0516_co_2026_swearing_in_dates.sql'),
    seatA: p('CC_0517_co_2026_seat_9_legislative_winners.sql'),
    seatB: p('CC_0518_co_2026_seat_9_executive_and_board_winners.sql'),
  },
  cleanChain: ['dates', 'seatA', 'seatB'],
  controls: [
    // ── CC_0516, the dates file ───────────────────────────────────────────────────────────────
    {
      // 🔴🔴 THE NEAR MISS THAT IS 178 LIVE ROWS, AND IT IS THIS STATE'S OWN STATUTORY DEFAULT.
      //    C.R.S. § 2-2-303.5(2) makes the second Wednesday the default, which is 2027-01-13 —
      //    the Maryland General Assembly's live start date. A file written from the statute
      //    instead of the resolution lands inside another state's cluster, never on an absurd day.
      id: 'C1',
      label: 'the legislature written to 2027-01-13 — the statutory default, and Maryland’s 178 live rows',
      aimedAt: 'assertion 1',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-11',\n       'published',\n       'co-hjr26-1031-convening',",
        replace: "       DATE '2027-01-13',\n       'published',\n       'co-hjr26-1031-convening',",
      }],
    },
    {
      // 🔴🔴 AND THE TIGHTEST NEAR MISS IS INSIDE THIS WAVE. The two groups are ONE DAY APART, so
      //    writing the legislature to the executives' day keeps the error entirely within the
      //    file — no other state's cluster is touched and the total across both days does not
      //    move. This is why assertion 2 counts each group separately and never a total.
      id: 'C2',
      label: 'the legislature written to 2027-01-12 — the sibling group’s own day, one day later',
      aimedAt: 'assertion 2 (the per-group arm)',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-11',\n       'published',\n       'co-hjr26-1031-convening',",
        replace: "       DATE '2027-01-12',\n       'published',\n       'co-hjr26-1031-convening',",
      }],
    },
    {
      // ⚠ AIMED AT THE ORDER GATE (assertion 3c) AND EXPECTED TO FIRE EARLIER. Art. IV § 3 requires
      //   the General Assembly to canvass the Governor's returns "upon the organization of the
      //   house, and before proceeding to other business", so the legislature must convene BEFORE
      //   the executives take office — true in all three gubernatorial cycles. But 3c reads only
      //   the two date CONSTANTS, and assertions 1 and 2 compare every written row against those
      //   same constants, so moving either fires two gates earlier. The recorded gate is the point.
      id: 'C3',
      label: 'the executives moved to 2027-01-11 — the order of the two groups reversed',
      aimedAt: 'assertion 3c (the order gate) — expected to be caught earlier',
      chain: [{
        tamper: 'dates',
        find: "  grp_b_day     CONSTANT date := DATE '2027-01-12';",
        replace: "  grp_b_day     CONSTANT date := DATE '2027-01-10';",
      }],
    },
    {
      // 🟢🟢 THE DESIGNATION WINDOW, WHICH NOTHING ELSE REACHES. C.R.S. § 2-2-303.5(3) and (4)
      //    confine every lawful designation to "on or after January 1 but prior to" the second
      //    Wednesday — for 2027, [2027-01-01 .. 2027-01-12]. That is the gate that BOUNDS the
      //    error rather than arguing about it, and the tamper has to be a MONDAY outside the
      //    window or the weekday arm fires first. 2027-01-18 is the third Monday — and Alabama's
      //    live day, 13 rows.
      // ⚠ THE TAMPER IS THE WINDOW, NOT THE DAY, AND A FIRST ATTEMPT PROVED WHY. Moving `grp_a_day`
      //   to Monday 2027-01-18 — the third Monday, and Alabama's live day — fired on assertion 1
      //   instead, because that gate compares every WRITTEN row against the same constant and the
      //   INSERT still said 2027-01-11. Reaching 3a needs the written day and the constant to
      //   agree, which is two edits in one file; narrowing the window instead leaves assertions 1
      //   and 2 passing and asks the one question 3a exists for: is this day one § 2-2-303.5 could
      //   lawfully have produced?
      id: 'C4',
      label: 'the designation window narrowed to end 2027-01-05 — 2027-01-11 no longer lawfully designable',
      aimedAt: 'assertion 3a (the window arm)',
      chain: [{
        tamper: 'dates',
        find: "  win_hi        CONSTANT date := DATE '2027-01-12';",
        replace: "  win_hi        CONSTANT date := DATE '2027-01-05';",
      }],
    },
    {
      // 🔴🔴 A CONTROL ON A GATE KEPT GREEN ON PURPOSE, AND IT RECORDS THE RIVAL THAT SURVIVES.
      //    "The second Monday in January" reproduces 2023-01-09 and gives 2027-01-11 — this file's
      //    own day — so nothing in our data can refuse it in the cycle being written. The file
      //    asserts that it reproduces EXACTLY ONE of the four prior cycles, as the record of a
      //    surviving rival. Nothing else in this suite would ever move that number.
      id: 'C5',
      label: 'the surviving second-Monday rival expected to reproduce TWO prior cycles instead of one',
      aimedAt: 'assertion 3d (the surviving-rival arm, kept green on purpose)',
      chain: [{
        tamper: 'dates',
        find: '  IF agree_2nd_mon <> 1 THEN',
        replace: '  IF agree_2nd_mon <> 2 THEN',
      }],
    },
    {
      // 🔴 AND THE OTHER ARM OF THE SAME GATE: the statutory default must FAIL in 2019 and 2023
      //    and hold in 2021 and 2025. If it reproduced three, the day would not be designated at
      //    all and the whole `published` basis would be wrong.
      id: 'C6',
      label: 'the statutory default expected to reproduce THREE prior cycles instead of two',
      aimedAt: 'assertion 3d (the default arm)',
      chain: [{
        tamper: 'dates',
        find: '  IF agree_dflt <> 2 THEN',
        replace: '  IF agree_dflt <> 3 THEN',
      }],
    },
    {
      // 🔴🔴🔴 THE LEDGER'S OWN WRONG CITATION, PLANTED. DATES.md § CO attributes the Board of
      //    Education's five anchors to § 22-2-104(1), which is "Offices and positions - nature"
      //    and holds no date. The DAY is identical either way, so this is the only mechanical
      //    trace the error leaves — and the `authority` body MENTIONS § 22-2-104 while explaining
      //    the correction, so a substring test would be satisfied by the sentence that records the
      //    defect. Checked by POSITION, which is what Texas's C7 cost.
      id: 'C7',
      label: 'the Board of Education’s authority opened with § 22-2-104(1) — the ledger’s own wrong section, which holds no date',
      aimedAt: 'assertion 7 (the authority-by-position arm)',
      chain: [{
        tamper: 'dates',
        find: "       'C.R.S. § 22-2-105(1) (State board of education - composition) — Colo. Const. Art. IX, § 1(1) '",
        replace: "       'C.R.S. § 22-2-104(1) (State board of education - composition) — Colo. Const. Art. IX, § 1(1) '",
      }],
    },
    {
      // 🔴 TWO CLAUSES THAT MERELY AGREE, MERGED. Three instruments reach 2027-01-12 and they are
      //    kept under three rule_ids precisely so a later reader cannot collapse them —
      //    Connecticut's warning. Giving the Regents the Board of Education's rule_id would hide
      //    that the Regents rest on a 1973 TRANSITIONAL provision and the Board on five current
      //    statutory anchors, which is the whole difference between a strong and a weak citation.
      id: 'C8',
      label: 'the Regents given the Board of Education’s rule_id — two clauses that agree, merged',
      aimedAt: 'assertion 7 (the rule_id arm)',
      chain: [{
        tamper: 'dates',
        find: "       'co-crs-23-20-105-second-tuesday-january',",
        replace: "       'co-crs-22-2-105-second-tuesday-january',",
      }],
    },
    {
      // 🔴🔴 THE CONTROL ON THE GATE THAT CORRECTED THE LEDGER. DATES.md § CO says eighteen offices
      //    and the pending set is eighteen — but Art. IV § 1(1) names FIVE executives, and the
      //    Lieutenant Governor is the fifth: it has a 2026 race with seven candidates and no
      //    recorded result. Dropping it would silently return the file to the ledger's number.
      id: 'C9',
      label: 'the Lieutenant Governor dropped from the selection — back to the ledger’s eighteen',
      aimedAt: 'P1 (the total, then the LTGOV arm)',
      chain: [{
        tamper: 'dates',
        find: "   AND d.district_type = 'STATE_EXEC'\n   AND o.title = 'Lieutenant Governor';",
        replace: "   AND d.district_type = 'STATE_EXEC'\n   AND o.title = 'Lieutenant Governor' AND false;",
      }],
    },
    {
      // 🔴🔴 THE CERTAIN RESULTS GAP, FILLED. State Board of Education District 3 was on the 2026
      //    ballot — § 22-2-105(1)'s 1985 + 6n arithmetic, Art. XII § 11's vacancy rule and the
      //    Department's own statement that Sherri Wright's term "runs through January 2027" all
      //    say so — and we hold no race row of any year. If one appears, the Board's cohort of
      //    three is complete and this wave is larger than it was pinned to be.
      id: 'C10',
      label: 'a race row planted on Board of Education District 3 — the certain gap closing',
      aimedAt: 'P7 (the District 3 arm, by name)',
      chain: [
        {
          sql: `INSERT INTO essentials.races (id, election_id, office_id, position_name, seats)
                SELECT gen_random_uuid(),
                       (SELECT id FROM essentials.elections WHERE election_date = DATE '2026-11-03' LIMIT 1),
                       (${byLabel('Colorado State Board of Education District 3')}),
                       'State Board of Education Member, District 3', 1;`,
        },
        'dates',
      ],
    },
    {
      // 🔴🔴 THE LIEUTENANT GOVERNOR'S RESULT ARRIVING. Art. IV § 3 makes the winner knowable in
      //    law — one vote for the pair — and our data records no pairing, so the office is dated
      //    and not seated. The moment a `won` row exists it becomes seatable and CC_0518 is a seat
      //    too small.
      id: 'C11',
      label: 'a winner recorded on the Lieutenant Governor’s race — the office becomes seatable',
      aimedAt: 'P5 (the no-winner arm)',
      chain: [
        {
          // ⚠ `result_source` IS NOT OPTIONAL, AND THE FIRST VERSION OF THIS TAMPER DID NOT KNOW.
          //   `race_candidates_result_needs_source` is a CHECK constraint, so setting `result`
          //   without a source made the tamper fail to apply and the harness reported the gate as
          //   `(unparsed)` — the green RED this pass has been bitten by twice. A fixture built out
          //   of live rows needs as much reading as the gate does.
          sql: `UPDATE essentials.race_candidates rc
                   SET result = 'won', result_certainty = 'called',
                       result_source = 'co-2026.controls.mjs C11 — planted fixture, not a real result'
                  FROM essentials.races r
                  JOIN essentials.elections e ON e.id = r.election_id
                 WHERE rc.race_id = r.id
                   AND e.election_date = DATE '2026-11-03'
                   AND r.office_id IN (${byTitle('Lieutenant Governor')})
                   AND rc.full_name = 'Lesley Dahlkemper';`,
        },
        'dates',
      ],
    },
    {
      // 🔴 THE SECOND-TUESDAY ARITHMETIC ITSELF. Every other gate about Group B's day is measured
      //    against this computation, so if it is wrong the comparisons below mean nothing. ⚠ The
      //    file says so in its own message, which is why the gate exists at all.
      id: 'C12',
      label: 'the second Tuesday computed as the FIRST — the arithmetic behind every Group B gate',
      aimedAt: 'assertion 3b',
      chain: [{
        tamper: 'dates',
        find: "          + ((2 - EXTRACT(dow FROM DATE '2027-01-01')::int + 7) % 7) + 7)::date INTO r_2nd_tue;",
        replace: "          + ((2 - EXTRACT(dow FROM DATE '2027-01-01')::int + 7) % 7))::date INTO r_2nd_tue;",
      }],
    },
    {
      // 🔴🔴 THE FIRST WAVE IN THIS PASS WHERE `published` DOES ANY WORK, so the basis is asserted
      //    positively rather than merely permitted. If these nine became `statute`, somebody has
      //    re-dated them from the default — which is 2027-01-13 and is Maryland's day.
      id: 'C13',
      label: 'the legislature’s basis changed from `published` to `statute`',
      aimedAt: 'assertion 7 (the basis arm)',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-11',\n       'published',",
        replace: "       DATE '2027-01-11',\n       'statute',",
      }],
    },

    // ── CC_0517, the nine legislative seats ───────────────────────────────────────────────────
    {
      // 🔴 THE DIGEST. Every count can pass while the MEMBERSHIP moves — a different winner, a
      //    different office, or a re-election that became a handover.
      id: 'C14',
      label: 'CC_0517’s selection digest moved by one character',
      aimedAt: 'P3 (the digest arm)',
      chain: ['dates', {
        tamper: 'seatA',
        find: "       'ec189254c645f12bd5ebfeb25bd80802' AS expect_digest,",
        replace: "       'ec189254c645f12bd5ebfeb25bd80803' AS expect_digest,",
      }],
    },
    {
      // 🔴🔴 ALL NINE PREDECESSORS ARE DATED HERE, WHICH IS UNUSUAL — Texas's twelve were all NULL —
      //    and SEVEN of those dates are the rows CC_0516's assertion 3d reads as its in-data
      //    control. The pin records the count so that losing one is reported rather than absorbed.
      id: 'C15',
      label: 'a legislative predecessor’s term_start blanked — the “all nine dated” pin stops holding',
      aimedAt: 'P6 (the predecessors-dated arm)',
      chain: [
        'dates',
        {
          sql: `UPDATE essentials.office_terms SET term_start = NULL
                 WHERE office_id IN (${byLabel('State House District 20')}) AND term_end IS NULL;`,
        },
        'seatA',
      ],
    },
    {
      // 🔴🔴🔴 TEXAS's SHARED-CLOSURE-DAY DEFECT, RE-PLANTED IN A BIGGER FORM. 2027-01-10 is the day
      //    BEFORE Oregon's 75 and Washington's 118 legislative terms begin, so 193 terms already
      //    end there and none is Colorado's. Asked as a TOTAL this gate reports every one of them
      //    as a fault — the shared-square rule reaching `term_end`, a column nobody thinks of as a
      //    date. Texas's version fired on 68 rows; this one would fire on 193.
      id: 'C16',
      label: 'assertion 6c reverted to a TOTAL — 193 innocent Oregon and Washington closures reported as a fault',
      aimedAt: 'assertion 6c (the delta arm)',
      chain: ['dates', {
        tamper: 'seatA',
        find: '  IF n - b.terms_ending_prev <> p.expect_predecessors THEN',
        replace: '  IF n <> p.expect_predecessors THEN',
      }],
    },
    {
      // ⚠ AIMED AT 6b AND PROVING ONLY THAT IT COMPARES. 6b asks whether a predecessor's term_start
      //   survived its own closure, which matters because seven of the nine are CC_0516's date
      //   control and seat_officeholder writes nothing to a closed row's source. But it compares
      //   the live rows against the pre-image THIS FILE captured, so no data tamper can separate
      //   them — whatever is planted is in both images. This tampers the CAPTURE instead. ▶ It
      //   proves the gate fires; it does NOT prove it would catch a real move. Different claims.
      //   ⚠ A FIRST ATTEMPT CAPTURED NULL AND FIRED ON P6 INSTEAD: P6 counts how many predecessors
      //   are dated and expects nine, so blanking the capture is caught two gates earlier. Moving
      //   each captured start by ONE DAY keeps that count at nine and leaves 6b as the first gate
      //   that can see the difference — which is the shape a real moved start would have.
      id: 'C17',
      label: 'the predecessor pre-image capturing every term_start one day late — 6b’s comparison broken while P6’s count holds',
      aimedAt: 'assertion 6b (fires; does not prove detection of a real move)',
      chain: ['dates', {
        tamper: 'seatA',
        find: 'SELECT s.office_id, s.label, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended\n  FROM cc0517_sel s',
        replace: 'SELECT s.office_id, s.label, t.id AS term_id, t.politician_id, (t.term_start + 1) AS term_start, t.term_end, t.how_ended\n  FROM cc0517_sel s',
      }],
    },
    {
      // 🔴🔴 RULING B's RECOVERY KEY, POISONED — TEXAS's C17 RE-PLANTED. A wave is recovered with
      //    `source LIKE '%<slot>%'`, so a sibling slot named anywhere in that column makes these
      //    rows answer to the sibling's query. Texas's first chain rehearsal aborted exactly this
      //    way, with 12 rows reported as already citing CC_0515.
      id: 'C18',
      label: 'the sibling slot CC_0518 written into CC_0517’s source narrative',
      aimedAt: 'assertion 7b',
      chain: ['dates', {
        tamper: 'seatA',
        find: "                         || 'load of a statewide publication. CC_0517',",
        replace: "                         || 'load of a statewide publication. See CC_0518. CC_0517',",
      }],
    },
    {
      // 🔴🔴 THE RESULTS GAP CLOSING ON ONE OF THE THREE NAMED SEATS. House Districts 15, 21 and 22
      //    carry a 2026 race whose candidates ALL have result IS NULL — not "advanced", which would
      //    be a primary result, but blank. They are the seats most likely to gain a winner while
      //    this branch is open, which is why P5 names them instead of counting them.
      id: 'C19',
      label: 'a winner recorded on House District 21 — one of the three blank-result races filling',
      aimedAt: 'P5 (the named blank-result arm)',
      chain: [
        'dates',
        {
          // ⚠ Same CHECK constraint as C11 — see its note.
          sql: `UPDATE essentials.race_candidates rc
                   SET result = 'won', result_certainty = 'called',
                       result_source = 'co-2026.controls.mjs C19 — planted fixture, not a real result'
                  FROM essentials.races r
                  JOIN essentials.elections e ON e.id = r.election_id
                 WHERE rc.race_id = r.id
                   AND e.election_date = DATE '2026-11-03'
                   AND r.office_id IN (${byLabel('State House District 21')})
                   AND rc.full_name = 'Brenda Miller';`,
        },
        'seatA',
      ],
    },
    {
      // 🔴🔴🔴 THE SHARPEST CONTROL IN THIS SUITE, AND THE ONLY ONE THAT CAN SEE THE RIVAL RULE.
      //    Colorado's nine legislative seats are re-dated under WASHINGTON's rule_id — which
      //    literally contains the words "second-monday-january", the rival this state's own data
      //    cannot refuse and which gives the right answer in 2027. THE DAY IS UNTOUCHED, so every
      //    date gate in all three files passes, the digest is unmoved, and the delta on 2027-01-11
      //    is still nine. Only P4's rule_id arm notices that the day has stopped being designated.
      id: 'C20',
      label: 'Colorado’s nine re-dated under Washington’s `second-monday-january` rule_id — the day identical',
      aimedAt: 'P4 (the rule_id arm)',
      chain: [
        'dates',
        {
          sql: `UPDATE essentials.office_swearing_in si
                   SET rule_id = 'wa-rcw-44-04-021-second-monday-january'
                  FROM essentials.offices o
                  JOIN essentials.districts d ON d.id = o.district_id
                 WHERE si.office_id = o.id
                   AND lower(d.state) = 'co'
                   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
                   AND si.election_date = DATE '2026-11-03';`,
        },
        'seatA',
      ],
    },

    // ── CC_0518, the nine executive and board seats ───────────────────────────────────────────
    {
      // 🔴🔴 THE CHAIN FILE RUN WITHOUT ITS SIBLING, WITH NO TAMPER AT ALL. This file's closure day
      //    is CC_0517's START day and its before-image pins that square at 202 — Oregon 75,
      //    Washington 118 and Colorado's own 9. Run alone it would read 193 and every delta would
      //    be measured against a state that never existed. Texas's C21, in a state where the two
      //    files' days actually touch.
      id: 'C21',
      label: 'CC_0518 run WITHOUT CC_0517 — no tamper at all',
      aimedAt: 'P2 (the sibling-applied arm)',
      chain: ['dates', 'seatB'],
    },
    {
      // 🔴🔴 THE IN-DATA CONTROL ITSELF, MOVED. Jared Polis's 2019-01-08 is the second Tuesday of
      //    January 2019 and the ONLY dated Colorado state executive term in the database — it is
      //    CC_0516's assertion 3e, and it is also one of the rows CC_0518 closes. Texas's C19
      //    shape: the row this wave closes is the row that justifies the day it closes it on.
      id: 'C22',
      label: 'Jared Polis’s 2019-01-08 moved — Art. IV § 1(1)’s only in-data corroboration stops reproducing',
      aimedAt: 'assertion 3e (CC_0516)',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_start = DATE '2019-01-15'
                 WHERE office_id IN (${byTitle('Governor')}) AND term_start = DATE '2019-01-08';`,
        },
        'dates',
      ],
    },
    {
      // 🔴🔴🔴 PURPOSE-BUILT TO REACH THE CHAIN GATE, BECAUSE NOTHING ELSE CAN. Reassigning the
      //    Secretary of State's predecessor term to somebody else leaves EVERY count correct — the
      //    digest (which covers office, winner and is_reelection, not the holder), the 4/5
      //    re-election split, the name list, the predecessor count, the handover identity check —
      //    and breaks only the fact that Griswold is the person Gonzalez succeeds. P7 is the first
      //    gate that notices, and without it Griswold would hold two offices from 2027-01-12.
      //    ⚠ The holder is reassigned to the OUTGOING TREASURER, who is leaving anyway, so no
      //    other seat's identity check moves either.
      id: 'C23',
      label: 'the Secretary of State’s predecessor reassigned — the chain broken with every count intact',
      aimedAt: 'P7 (the chain arm)',
      chain: [
        'dates', 'seatA',
        {
          sql: `UPDATE essentials.office_terms SET politician_id =
                  (SELECT t2.politician_id FROM essentials.office_terms t2
                    WHERE t2.office_id IN (${byTitle('Treasurer')}) AND t2.term_end IS NULL LIMIT 1)
                 WHERE office_id IN (${byTitle('Secretary of State')}) AND term_end IS NULL;`,
        },
        'seatB',
      ],
    },
    {
      // 🔴 ONE OF THE TWO DUAL-SEAT WINNERS, CLOSED. Jeff Bridges keeps State Senate District 26
      //    because that seat is genuinely not up until 2028; Amanda Gonzalez keeps Jefferson County
      //    Clerk and Recorder because that race is missing. Closing either would make the count
      //    one, and the pair is pinned because only reading the body's term length tells the two
      //    kinds apart.
      id: 'C24',
      label: 'Jeff Bridges’s Senate District 26 term closed — the dual-seat pair becomes one',
      aimedAt: 'P8b (the dual-seat count arm)',
      chain: [
        'dates', 'seatA',
        {
          sql: `UPDATE essentials.office_terms SET term_end = DATE '2026-12-31', how_ended = 'resigned'
                 WHERE office_id IN (${byLabel('State Senate District 26')}) AND term_end IS NULL;`,
        },
        'seatB',
      ],
    },
    {
      // 🔴 A COUNT IS NOT A NAME — TEXAS's C22 LESSON, ON A PAIR. The dual-seat count stays TWO
      //    while one of the kept seats is a different office, which is exactly the shape of
      //    somebody mis-reading which seat a winner keeps. Only the named pin separates them.
      id: 'C25',
      label: 'the dual-seat pin naming Senate District 25 instead of 26 — the count still two',
      aimedAt: 'P8b (the named arm)',
      chain: ['dates', 'seatA', {
        tamper: 'seatB',
        find: "     VALUES ('Jeff Bridges',    'State Senate District 26'),",
        replace: "     VALUES ('Jeff Bridges',    'State Senate District 25'),",
      }],
    },
    {
      // ⚠ AIMED AT P2b's LIEUTENANT-GOVERNOR ARM AND EXPECTED TO FIRE ON THE TOTAL. The Lieutenant
      //   Governor carries a swearing-in row for this very day, so a selection built from
      //   office_swearing_in rather than office_pending_winner would sweep it in and seat somebody
      //   we hold no winner for. An expansion adds a row, so the selection total refuses it two
      //   gates earlier — the recorded gate is the point, and C11 reaches the same risk from the
      //   other side by giving that race a winner.
      id: 'C26',
      label: 'the Lieutenant Governor swept into CC_0518’s selection — a dated seat with no winner',
      aimedAt: 'P2b (the Lieutenant-Governor arm) — expected to be caught by the total',
      chain: ['dates', 'seatA', {
        tamper: 'seatB',
        find: "   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD', 'STATE_BOARD_EDUCATION')\n   AND w.election_date = DATE '2026-11-03';",
        replace: "   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD', 'STATE_BOARD_EDUCATION')\n   AND w.election_date = DATE '2026-11-03'\nUNION ALL\nSELECT o.id, o.title, d.label, d.district_type, NULL::uuid, 'Lesley Dahlkemper', false,\n       si.swearing_in_date, si.basis, si.rule_id, NULL::uuid, 'called', 1, 1\n  FROM essentials.offices o\n  JOIN essentials.districts d ON d.id = o.district_id\n  JOIN essentials.office_swearing_in si ON si.office_id = o.id\n                                       AND si.election_date = DATE '2026-11-03'\n WHERE lower(d.state) = 'co' AND o.title = 'Lieutenant Governor';",
      }],
    },
    {
      // 🔴🔴 THE SQUARE THAT IS BUSY IN THE COLUMN NOBODY CHECKS. 2027-01-12 carries NO term starts
      //    and 178 term ENDS — Maryland's, because it is the day before the Maryland General
      //    Assembly's 2027-01-13. Pinning that cell at zero is the mistake a reader makes by
      //    analogy with the start column, and it is one column away from the truth.
      id: 'C27',
      label: 'the 178 Maryland term-ENDS on 2027-01-12 pinned as zero — the wrong column on this file’s own day',
      aimedAt: 'P8 (the ending-on-the-day arm)',
      chain: ['dates', 'seatA', {
        tamper: 'seatB',
        find: '       178                                AS expect_terms_ending_on_the_day_before,',
        replace: '       0                                  AS expect_terms_ending_on_the_day_before,',
      }],
    },
    {
      // 🔴 AND THE OTHER HALF OF THE SAME POINT: this file's CLOSURE day carries 202 term STARTS
      //    and no ends. A reader who pins it by analogy with the closure column writes zero and is
      //    193 + 9 rows wrong.
      id: 'C28',
      label: 'the 202 term-STARTS on 2027-01-11 pinned as 193 — the sibling file’s own nine forgotten',
      aimedAt: 'P8 (the starting-prev arm)',
      chain: ['dates', 'seatA', {
        tamper: 'seatB',
        find: '       202                                AS expect_terms_starting_prev_before,',
        replace: '       193                                AS expect_terms_starting_prev_before,',
      }],
    },
    {
      // 🔴 THE STAGGERED BOARDS, EXPANDED. Six of nine Regents and seven of nine Board of Education
      //    members are NOT leaving — the Arizona Corporation Commission shape, reached twice in one
      //    state — so a selection by title rather than by pending winner would seat members whose
      //    terms run on. This is the dating-side risk Texas found on the Railroad Commission,
      //    reached from the seating side.
      id: 'C29',
      label: 'the Regent selection expanded to every sibling seat — six members who are not leaving',
      aimedAt: 'P2b (the Regent-count arm)',
      chain: ['dates', 'seatA', {
        tamper: 'seatB',
        find: "   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD', 'STATE_BOARD_EDUCATION')\n   AND w.election_date = DATE '2026-11-03';",
        replace: "   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD', 'STATE_BOARD_EDUCATION')\n   AND w.election_date = DATE '2026-11-03'\nUNION ALL\nSELECT o.id, o.title, d.label, d.district_type, NULL::uuid, 'sibling', false,\n       DATE '2027-01-12', 'statute', 'co-crs-23-20-105-second-tuesday-january', NULL::uuid,\n       'called', 1, 1\n  FROM essentials.offices o\n  JOIN essentials.districts d ON d.id = o.district_id\n WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_BOARD'\n   AND NOT EXISTS (SELECT 1 FROM essentials.office_pending_winner w2\n                    WHERE w2.office_id = o.id AND w2.election_date = DATE '2026-11-03');",
      }],
    },
    {
      // 🔴🔴 THE ONLY TAMPER THAT REACHES P5's LIEUTENANT-GOVERNOR ARMS, AND C11 IS WHY IT IS
      //    NEEDED. Giving that race a WINNER puts the office into `office_pending_winner`, so the
      //    selection grows and P1 refuses it two gates earlier — the no-winner arm is coupled to
      //    the selection size and cannot be reached that way. Removing a CANDIDATE instead leaves
      //    the office unpending, P1 at nineteen, and P5 as the first gate that can see anything.
      //    ▶ Texas's "a count is not a name": the seven candidates are what make this office a
      //    results gap rather than an office with no contest, and that claim needs its own control.
      id: 'C31',
      label: 'one Lieutenant Governor candidate removed — seven becomes six while the office stays unpending',
      aimedAt: 'P5 (the candidate-count arm)',
      chain: [
        {
          sql: `DELETE FROM essentials.race_candidates rc
                 USING essentials.races r, essentials.elections e
                 WHERE rc.race_id = r.id AND e.id = r.election_id
                   AND e.election_date = DATE '2026-11-03'
                   AND r.office_id IN (${byTitle('Lieutenant Governor')})
                   AND rc.full_name = 'Frank Atwood';`,
        },
        'dates',
      ],
    },
    {
      // 🔴🔴 THE CONTROL ON THE GAP MEASUREMENT ITSELF. Art. V § 3(1) gives every representative a
      //    two-year term, so all 65 House seats were on the 2026 ballot as a matter of law and 59
      //    are certainly missing. C19 showed that FILLING one fires on the selection size two gates
      //    earlier, so the count arm needs a control of its own — and this is the number the whole
      //    "certainly missing" claim rests on. Texas's C6 shape: a control on the gate that
      //    measured a document's gap.
      id: 'C32',
      label: 'the House results gap pinned at 58 instead of 59 — the “certainly missing” count itself',
      aimedAt: 'P5 (the House-gap arm)',
      chain: ['dates', {
        tamper: 'seatA',
        find: '  IF n <> 59 THEN',
        replace: '  IF n <> 58 THEN',
      }],
    },
    {
      // 🔴 THE DRIFT BASELINE. This wave seats eighteen offices that all already had terms, so it
      //    must not move the baseline at all. 🔴 NEVER RAISE IT. ⚠ The red message reads "moved
      //    from 238 to 238", which is a self-contradiction — correctly so, because this tamper
      //    breaks the CONDITION and leaves the message's own copy of the number intact. In the
      //    shipped file the two agree. Noted so a later reader does not read the artefact as the
      //    Oregon defect.
      id: 'C30',
      label: 'the unflagged drift baseline pinned at 239 instead of 238',
      aimedAt: 'assertion 10 (CC_0518)',
      chain: ['dates', 'seatA', {
        tamper: 'seatB',
        find: '  IF n <> b.missing_unflagged THEN\n    RAISE EXCEPTION \'10: the unflagged drift baseline moved from % to %. 🔴 NEVER RAISE THIS \'',
        replace: '  IF n <> b.missing_unflagged + 1 THEN\n    RAISE EXCEPTION \'10: the unflagged drift baseline moved from % to %. 🔴 NEVER RAISE THIS \'',
      }],
    },
  ],
};
