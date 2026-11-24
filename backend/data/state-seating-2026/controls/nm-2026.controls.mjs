/**
 * New Mexico 2026 — the control suite for `CC_0505` (dates) and `CC_0506` (seating), run on
 * 2026-11-24 before either was applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     data/state-seating-2026/controls/nm-2026.controls.mjs
 *
 * ⚠ **ONCE THE CHAIN IS APPLIED THIS SUITE CANNOT BE RE-RUN, AND THAT IS CORRECT.** The negative
 *   control fails and the harness refuses to report. It is kept as the RECORD of what was tested.
 *   `--check` validates every needle without touching the database.
 *
 * ── WHAT THIS STATE MADE DIFFERENT ──────────────────────────────────────────────────────────
 *
 * 🟢🟢 **THE "NOBODY HOLDS TWO SEATS" ZERO HAS A REAL FIXTURE HERE, AND C19–C21 ARE THE TRIO THAT
 *   PROVES IT.** Stephanie Garcia Richard is the sitting Commissioner of Public Lands and this
 *   wave's winner of the Lieutenant Governorship, and **both legs are inside the wave on one
 *   day** — Juan Sanchez III is seated into the seat she leaves, which is the only reason her old
 *   term closes. Idaho (`CC_0504`) had no such person anywhere in the state and its `P8` rested
 *   entirely on a **planted** second term. `REGISTER.md`: *a planted fixture proves the gate
 *   FIRES; it does not prove the gate reads the rows a real double-holder would occupy.* Here it
 *   does, and the three controls test three different things about it:
 *   • **C19** plants a second term on a *different* winner, so `P8` fires on somebody who is not
 *     the real fixture — proving the gate is not keyed to her by accident.
 *   • **C20** moves her vacated seat OUTSIDE the wave. Every count stays the same and the shape
 *     stays the same; what changes is whether the seat she leaves has a successor in this file.
 *     That is the whole distinction between Oregon's Helfrich (closes itself) and Utah's Fiefia
 *     (left holding two, because that seat's own result was missing).
 *   • **C21** DELETES her Public Lands term, so the fixture disappears and `P9`'s count reads 0.
 *     🔴🔴 **THAT IS THE CONTROL-OF-A-CONTROL.** `P9` is in the file to assert the fixture EXISTS;
 *     if it ever quietly stopped existing, the zero in assertion 9 would go vacuous — Idaho's
 *     state — while every number in the file stayed green. A gate kept in order to find something
 *     needs a control that takes the something away.
 *
 * 🔴🔴 **C15 IS THE ONE NO NUMBER CAN SEE.** `CC_0505`'s whole contribution over the ledger is
 *   **Art. XX § 3(A)** — the general clause, found by a 270-section sweep, that commences "every
 *   state, county or district officer" on January 1 and so DISCHARGES Art. V § 1's "unless
 *   otherwise provided in the constitution of New Mexico". A file citing only the two specific
 *   instruments would write **identical rows on the identical day** and every count, delta and
 *   digest in both files would be unchanged. Only assertion 7b reads the authority TEXT. This is
 *   Maryland's C8 (§ 1 against § 3, the same day) and Washington's three-citations-one-date,
 *   one state later.
 *
 * 🔴 **THE DANGEROUS NEAR MISS IS THE FIRST MONDAY, AND IT IS POPULATED.** 2027-01-01 is a FRIDAY
 *   and a public holiday, so "the next working day" produces 2027-01-04 — where Arizona,
 *   Wisconsin, California and Idaho already hold **241 swearing-in rows and 229 terms** under five
 *   rule_ids, two of which call it a first Monday. C1, C2 and C4 aim at that day from three
 *   directions: the written value, the arithmetic, and the Friday assertion that explains why the
 *   misreading is tempting at all.
 *   ⚠ **The other two near misses are EMPTY days** — 2027-01-19 (the third Tuesday, New Mexico's
 *   own session convening day under Art. IV § 5(A)) and 2026-12-31 (the day these terms end) carry
 *   **zero rows repo-wide**, so refusing them discriminates only on the New Mexico side. C3 still
 *   aims at the third Tuesday's arithmetic, because a mis-derived near miss is a near miss that
 *   has stopped being one.
 *
 * 🟢 **C7 AND C8 TEST OPPOSITE HALVES OF A ONE-ROW CORPUS.** New Mexico holds exactly ONE dated
 *   state-tier term — Michelle Lujan Grisham's Governorship from 2019-01-01, written from the
 *   Governor's own office press release of that day and never derived from any clause in these
 *   files. Assertion 3d asserts it matches January 1st AND that both wrong rules match **zero**.
 *   C7 breaks the discrimination (the wrong rules expected to match 1) and C8 removes the fixture
 *   (so the control has nothing left to read). ▶ **A control with one fixture must refuse to
 *   report when it loses it**, which is why 3d counts its rows before testing them.
 *
 * 🔴🔴 **C9 AND C11 ARE THE TWO GAPS, AND BOTH HAVE REAL SHAPES.** Public Education Commission
 *   District 7 was on this ballot under HB 9 § 3(C) and we hold no race row for it, so Patricia
 *   Gipson keeps a seat she lost; and New Mexico's 70 House seats do not exist in our data at all
 *   although Art. XX § 3(A) puts them on **this file's own day** — the one state in the pass where
 *   the missing body would be absorbed into the day the wave itself created rather than standing
 *   out from it. Both gates exist so a later arrival stops the file instead of being swallowed.
 *
 * ── WHAT IS NOT TESTED, AND WHY ─────────────────────────────────────────────────────────────
 *
 * Recorded as **backstops, not tested gates** — `CC_0506`'s `P3` re-election/handover counts and
 * its 11-name check sit BELOW the pinned digest, so any realistic tamper moves the digest two
 * gates earlier (C18 measured this). `CC_0505`'s `P2` selection-completeness arm is the same shape
 * as Alabama's and Idaho's: dropping a body from the selection changes the TOTAL, so `P1` fires
 * first. `CC_0506`'s assertion 10b (the source line saying RE-ELECTED or HANDOVER) is reachable
 * only by a tamper on the source string itself, which tests the literal rather than the claim.
 */
const M = '../../../migrations';
const p = (f) => new URL(`${M}/${f}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

/** One New Mexico office in this wave, by title, for a data tamper. */
const office = (title) => `
  SELECT o.id FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nm'
     AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD_EDUCATION')
     AND o.title = '${title}'`;

export default {
  name: 'New Mexico 2026 — CC_0505 / CC_0506',
  files: {
    dates: p('CC_0505_nm_2026_swearing_in_dates.sql'),
    seating: p('CC_0506_nm_2026_seat_11_winners.sql'),
  },
  cleanChain: ['dates', 'seating'],
  controls: [
    // ── CC_0505, the dates file ───────────────────────────────────────────────────────────────
    {
      // 🔴🔴 THE DANGEROUS WRONG ANSWER, WRITTEN. 241 live rows in four states sit on that day,
      //    and a Friday public holiday is what makes "the next working day" tempting.
      id: 'C1',
      label: 'write 2027-01-04 — the FIRST MONDAY, 241 live rows across four states',
      aimedAt: 'assertion 1',
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-01',\n       'statute',",
        replace: "       DATE '2027-01-04',\n       'statute',",
      }],
    },
    {
      id: 'C2',
      label: 'the first-Monday near miss mis-derived (a week late), so it stops being the near miss',
      aimedAt: 'assertion 3b',
      chain: [{
        tamper: 'dates',
        find: '  first_mon := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);',
        replace: '  first_mon := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7) + 7;',
      }],
    },
    {
      // 🔴 NEW MEXICO'S OWN SESSION CONVENING DAY, Art. IV § 5(A) — the convening-is-not-the-term
      //    trap, which has now bitten in Maine, California, Arizona and Idaho.
      id: 'C3',
      label: "the third Tuesday mis-derived — New Mexico's own session convening day",
      aimedAt: 'assertion 3b',
      chain: [{
        tamper: 'dates',
        find: '  third_tue := jan1 + ((2 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7) + 14;',
        replace: '  third_tue := jan1 + ((2 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7) + 7;',
      }],
    },
    {
      // ⚠ THE ASSERTION THAT EXPLAINS WHY THE NEAR MISS EXISTS AT ALL. If January 1st stopped
      //    being a Friday the first Monday would not be a tempting misreading, and this file's
      //    own argument for pinning it would be stale.
      id: 'C4',
      label: 'the Friday assertion broken — the reason the first Monday is tempting here',
      aimedAt: 'assertion 3a (the weekday arm)',
      chain: [{
        tamper: 'dates',
        find: '  IF EXTRACT(ISODOW FROM jan1)::int <> 5 THEN',
        replace: '  IF EXTRACT(ISODOW FROM jan1)::int <> 4 THEN',
      }],
    },
    {
      // 🟢 Art. V § 1's own cycle: "those officers elected at the general election in 1990 and all
      //    state executive officers elected thereafter".
      id: 'C5',
      label: "Art. V § 1's four-year cycle anchored on 1991 instead of 1990",
      aimedAt: 'assertion 3a (the executive cycle arm)',
      chain: [{
        tamper: 'dates',
        find: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1990) % 4 <> 0 THEN",
        replace: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1991) % 4 <> 0 THEN",
      }],
    },
    {
      // 🔴🔴 THE ARITHMETIC THAT PROVES THE COMMISSION'S 5 + 5 PARTITION, which is the whole
      //    answer to "is District 7 a missing result or an off-cycle seat?".
      id: 'C6',
      label: "HB 9 § 3(C)'s cycle anchored on 2023 — the partition that names the missing seat",
      aimedAt: 'assertion 3a (the Commission cycle arm)',
      chain: [{
        tamper: 'dates',
        find: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 2022) % 4 <> 0 THEN",
        replace: "  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 2023) % 4 <> 0 THEN",
      }],
    },
    {
      // 🔴🔴 THE DISCRIMINATION ARM. A control that only asks "does the computed day carry the
      //    recorded term?" is satisfied by any rule that lands there. This asserts the WRONG rules
      //    carry nothing — break that expectation and the control stops separating them.
      id: 'C7',
      label: 'the wrong rules expected to match the dated term as well as the right one',
      aimedAt: 'assertion 3d (the discrimination arm)',
      chain: [{
        tamper: 'dates',
        find: '  IF c_mon <> 0 OR c_tue <> 0 THEN',
        replace: '  IF c_mon <> 1 OR c_tue <> 1 THEN',
      }],
    },
    {
      // 🔴 A ONE-ROW CORPUS THAT LOSES ITS ROW MUST REFUSE TO REPORT. Nulling the only dated New
      //    Mexico term leaves assertion 3d with nothing to read.
      id: 'C8',
      label: "Michelle Lujan Grisham's 2019-01-01 nulled — the control's only fixture removed",
      aimedAt: 'assertion 3d (the fixture count)',
      chain: [
        {
          sql: `UPDATE essentials.office_terms
                   SET term_start = NULL, start_precision = 'unknown'
                 WHERE office_id IN (${office('Governor')}) AND term_start = DATE '2019-01-01';`,
        },
        'dates',
      ],
    },
    {
      // 🔴🔴 THE RESULTS GAP, WITH A REAL FIXTURE SHAPE: the missing race arrives. That makes the
      //    wave LARGER, and the file must stop rather than date four of five.
      id: 'C9',
      label: 'a 2026 race row appears on Public Education Commission District 7',
      aimedAt: 'P4',
      chain: [
        {
          sql: `INSERT INTO essentials.races (election_id, office_id, position_name, seats)
                  SELECT (SELECT id FROM essentials.elections
                           WHERE election_date = DATE '2026-11-03' LIMIT 1),
                         o.id, 'Public Education Commissioner (control fixture)', 1
                    FROM essentials.offices o
                   WHERE o.title = 'Public Education Commissioner, District 7';`,
        },
        'dates',
      ],
    },
    {
      // ⚠ THE PERSON THE GAP STRANDS. If her row moves, somebody has acted on the gap and this
      //    file's header is out of date.
      id: 'C10',
      label: "District 7's holder is no longer Patricia Gipson",
      aimedAt: 'P4 (the holder arm)',
      chain: [
        {
          sql: `UPDATE essentials.office_terms
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Michael Taylor' LIMIT 1)
                 WHERE office_id = (SELECT id FROM essentials.offices
                                     WHERE title = 'Public Education Commissioner, District 7')
                   AND term_end IS NULL;`,
        },
        'dates',
      ],
    },
    {
      // 🔴🔴 THE ABSENT LEGISLATURE, WHOSE DAY IS THIS FILE'S OWN DAY. This is the one state in
      //    the pass where a seeded legislative seat would be ABSORBED into the day the wave
      //    created — Art. XX § 3(A) commences "every state, county or district officer" on
      //    January 1, so nothing about the date would look wrong.
      id: 'C11',
      label: 'a New Mexico State House office row appears — on this file\'s own day',
      aimedAt: 'P5',
      chain: [
        {
          sql: `INSERT INTO essentials.districts (state, district_type, ocd_id, geo_id)
                  VALUES ('nm', 'STATE_LOWER', 'ocd-division/country:us/state:nm/sldl:999',
                          'control-fixture-nm-sldl-999');
                INSERT INTO essentials.offices (district_id, title)
                  SELECT id, 'State Representative' FROM essentials.districts
                   WHERE geo_id = 'control-fixture-nm-sldl-999';`,
        },
        'dates',
      ],
    },
    {
      id: 'C12',
      label: "the shared-day before-image pinned at 49 instead of Utah's real 50",
      aimedAt: 'P6',
      chain: [{ tamper: 'dates', find: '  IF b.rows_jan1 <> 50 THEN', replace: '  IF b.rows_jan1 <> 49 THEN' }],
    },
    {
      // ⚠ A CONTROL PROVES A GATE CAN FAIL, NOT THAT IT READ THE RIGHT ROWS. Making the day gate
      //    blind to New Mexico's own rules must report ELEVEN strangers — that number is the
      //    evidence the gate was reading real rows rather than passing over an empty set.
      id: 'C13',
      label: "assertion 4 stops recognising New Mexico's own rule_ids on 2027-01-01",
      aimedAt: 'assertion 4',
      chain: [{
        tamper: 'dates',
        find: "     AND s.rule_id NOT IN ('ut-const-art6-first-day-january',\n"
            + "                           'nm-const-art5-1-first-day-of-january',\n"
            + "                           'nm-22-3b-3-january-1-next-succeeding');",
        replace: "     AND s.rule_id NOT IN ('ut-const-art6-first-day-january');",
      }],
    },
    {
      // 🔴 TWO BODIES, TWO INSTRUMENTS, ONE DAY — so a seat under the wrong body's rule_id still
      //    carries the right DATE and no date check anywhere can see it.
      id: 'C14',
      label: "the Commission's four rows written under the executives' rule_id",
      aimedAt: 'assertion 7',
      chain: [{
        tamper: 'dates',
        find: "       CASE WHEN c.grp = 'exec' THEN 'nm-const-art5-1-first-day-of-january'\n"
            + "                                ELSE 'nm-22-3b-3-january-1-next-succeeding' END,",
        replace: "       'nm-const-art5-1-first-day-of-january',",
      }],
    },
    {
      // 🔴🔴 THE ONE NO NUMBER CAN SEE. Art. XX § 3(A) is this file's whole contribution over the
      //    ledger — the general clause that discharges Art. V § 1's carve-out and reaches BOTH
      //    bodies. Drop it from the authority text and every row, date, delta and digest in both
      //    files is byte-for-byte identical. Only assertion 7b reads the text.
      id: 'C15',
      label: '🔴 Art. XX § 3(A) dropped from the authority text — no count anywhere changes',
      aimedAt: 'assertion 7b',
      chain: [{
        tamper: 'dates',
        find: "           || 'FOURTH AGREES: Art. XX § 3(A), as amended November 3, 2020 — \"The term of office '",
        replace: "           || 'FOURTH AGREES: another clause, as amended November 3, 2020 — \"The term of office '",
      }],
    },
    {
      // 🟢 Art. XII § 6(B)'s own number, checked against the constitution rather than against the
      //    table itself. An eleventh row would make the 5 + 5 partition unsound.
      id: 'C16',
      label: "the Commission's constitutional size expected to be 11, not Art. XII § 6(B)'s ten",
      aimedAt: 'P3',
      chain: [{ tamper: 'dates', find: '  IF n <> 10 THEN', replace: '  IF n <> 11 THEN' }],
    },
    {
      id: 'C17',
      label: 'the dates file run twice in one transaction',
      aimedAt: 'P0',
      chain: ['dates', 'dates'],
    },

    // ── CC_0506, the seating file ─────────────────────────────────────────────────────────────
    {
      id: 'C18',
      label: "the Governor's winner re-pointed at the Secretary of State's winner",
      aimedAt: 'P3 digest',
      chain: [
        {
          sql: `UPDATE essentials.race_candidates
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Amanda López Askin' LIMIT 1)
                 WHERE id = (SELECT rc.id FROM essentials.race_candidates rc
                               JOIN essentials.races r     ON r.id = rc.race_id
                               JOIN essentials.elections e ON e.id = r.election_id
                               JOIN essentials.offices o   ON o.id = r.office_id
                               JOIN essentials.districts d ON d.id = o.district_id
                              WHERE lower(d.state) = 'nm' AND o.title = 'Governor'
                                AND e.election_date = DATE '2026-11-03' AND rc.result = 'won');`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🔴 A SECOND OPEN TERM ON A WINNER WHO IS **NOT** THE REAL FIXTURE — Debra Haaland given an
      //    unraced Commission seat. This proves the double-holder gate is not keyed to Stephanie
      //    Garcia Richard by accident, which a suite containing only her could not show.
      id: 'C19',
      label: '🔴 Raul Torrez, a re-elected winner, given a second open term outside the wave',
      aimedAt: 'P8',
      chain: [
        {
          // ⚠ IT HAS TO BE A WINNER WHO **ALREADY HOLDS** A SEAT. The first version of this
          //    planted the second term on Debra Haaland, who holds nothing — so she ended up with
          //    exactly ONE seat, P8 passed honestly, and P9's cross-office count fired instead.
          //    P8 asks "does a winner hold more than one office covering the handover day", and
          //    only somebody with a seat already can answer yes. Torrez is re-elected to the
          //    Attorney Generalship, so a second open term puts him at two.
          // ⚠ start_precision 'unknown' ON PURPOSE: with 'day' this becomes a second dated New
          //    Mexico state-tier term and the DATES file's assertion 3d fires two files early.
          sql: `DELETE FROM essentials.office_terms
                 WHERE office_id = (SELECT id FROM essentials.offices
                                     WHERE title = 'Public Education Commissioner, District 9');
                INSERT INTO essentials.office_terms
                  (office_id, politician_id, term_start, start_precision, how_started, source)
                  SELECT (SELECT id FROM essentials.offices
                           WHERE title = 'Public Education Commissioner, District 9'),
                         (SELECT id FROM essentials.politicians
                           WHERE full_name = 'Raul Torrez' LIMIT 1),
                         DATE '2026-12-01', 'unknown', 'elected', 'control fixture (C19)';`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🔴🔴 THE DISTINCTION THE WHOLE CHAIN TURNS ON, AND THE TAMPER LEAVES EVERY COUNT INTACT.
      //    Her vacated seat is moved OUTSIDE the wave, so nothing in this file fills it and she
      //    would hold two seats from 2027-01-01 — Utah's Doug Fiefia instead of Oregon's Jeff
      //    Helfrich. P9's first arm still counts exactly 1 cross-office term; only its second arm,
      //    which asks whether that seat is INSIDE the wave, can tell the two apart.
      id: 'C20',
      label: '🔴 the seat Stephanie Garcia Richard vacates moved OUTSIDE the wave',
      aimedAt: 'P9 (the inside-the-wave arm)',
      chain: [
        {
          // ⚠ THE SEAT SHE LEAVES MUST STILL HAVE A PREDECESSOR, OR P6 FIRES FIRST. The first
          //    version simply MOVED her Public Lands term onto District 8, which left Public
          //    Lands with nobody in it: P6's "one predecessor per seat" read 10 and fired two
          //    gates early. So Public Lands keeps a holder (Michael Taylor, who is not in the
          //    wave and is not the winner, so the handover arm still passes) and she is given an
          //    open term OUTSIDE the wave instead. Every count P9 reads stays at 1; the only
          //    thing that changes is whether the seat she leaves has a successor in this file.
          // ⚠ DELETED, NOT CLOSED. Closing District 8's term first made this die on
          //    office_terms_no_overlap and print an (unparsed) green RED: a term with term_start
          //    NULL has an UNBOUNDED daterange and overlaps any other term on the same office.
          //    Arizona's C5 printed the same shape.
          sql: `DELETE FROM essentials.office_terms
                 WHERE office_id = (SELECT id FROM essentials.offices
                                     WHERE title = 'Public Education Commissioner, District 8');
                UPDATE essentials.office_terms
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Michael Taylor' LIMIT 1)
                 WHERE office_id IN (${office('Commissioner of Public Lands')})
                   AND term_end IS NULL;
                INSERT INTO essentials.office_terms
                  (office_id, politician_id, term_start, start_precision, how_started, source)
                  SELECT (SELECT id FROM essentials.offices
                           WHERE title = 'Public Education Commissioner, District 8'),
                         (SELECT id FROM essentials.politicians
                           WHERE full_name = 'Stephanie Garcia Richard' LIMIT 1),
                         DATE '2026-12-01', 'unknown', 'elected', 'control fixture (C20)';`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🔴🔴 THE CONTROL-OF-A-CONTROL. P9 exists to assert the real fixture EXISTS. Delete it and
      //    the suite must notice — otherwise the zero in assertion 9 would quietly go vacuous
      //    (Idaho's state) with every number in both files still green.
      id: 'C21',
      label: '🔴 the real two-seat fixture REMOVED — P9 must refuse a vacuous zero',
      aimedAt: 'P9 (the fixture count)',
      chain: [
        {
          // ⚠ REASSIGNED, NOT DELETED. Deleting her Public Lands term left that office with no
          //    predecessor at all, so P6's "one per seat" count read 10 and fired two gates
          //    early — a real gate doing real work, and P9 still untested. Handing the term to
          //    somebody outside the wave keeps the predecessor count at 11 and the handover arm
          //    satisfied (Michael Taylor is not the winner either), and removes ONLY the thing
          //    P9 exists to find: a winner holding a seat other than the one they won.
          sql: `UPDATE essentials.office_terms
                   SET politician_id = (SELECT id FROM essentials.politicians
                                         WHERE full_name = 'Michael Taylor' LIMIT 1)
                 WHERE office_id IN (${office('Commissioner of Public Lands')})
                   AND term_end IS NULL;`,
        },
        'dates',
        'seating',
      ],
    },
    {
      // 🟢 THE LAW EXPLAINS TWO OF THE FIVE HANDOVERS, AND THAT IS CORROBORATION FROM OUTSIDE THE
      //    DATA. Art. V § 1's two-term limit bars Lujan Grisham from a third Governorship and
      //    Garcia Richard from a third as Commissioner.
      id: 'C22',
      label: "the term-limited pair gate expects 1 departure, not Art. V § 1's 2",
      aimedAt: 'P9 (the term-limit arm)',
      chain: ['dates', { tamper: 'seating', find: '  IF n <> 2 THEN\n    RAISE EXCEPTION \'P9: % of the 2 term-limited departures', replace: '  IF n <> 1 THEN\n    RAISE EXCEPTION \'P9: % of the 2 term-limited departures' }],
    },
    {
      id: 'C23',
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
      // 🟢🟢 THE ONE ROW THAT IS CC_0505'S ONLY IN-DATA EVIDENCE. Moving it must stop the chain:
      //    seat_officeholder writes nothing to a closed row's source, so a lost start is gone.
      //    ⚠ Expected to fire on the DATES file's assertion 3d rather than on the seating file's
      //    P6 — the same chaining Idaho's C14 measured, and the right order, because that row is
      //    the corroboration 3d reads.
      id: 'C24',
      label: "Michelle Lujan Grisham's 2019-01-01 moved onto the first Monday of that January",
      aimedAt: 'assertion 3d',
      chain: [
        {
          sql: `UPDATE essentials.office_terms SET term_start = DATE '2019-01-07'
                 WHERE office_id IN (${office('Governor')}) AND term_start = DATE '2019-01-01';`,
        },
        'dates',
        'seating',
      ],
    },
    {
      id: 'C25',
      label: "seat_officeholder given a literal 2027-01-04 — the first Monday",
      aimedAt: 'assertion 1',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: '      p_term_start       => s.term_start,',
          replace: "      p_term_start       => DATE '2027-01-04',",
        },
      ],
    },
    {
      // ⚠ Making the day gate blind to New Mexico must report ELEVEN strangers.
      id: 'C26',
      label: 'assertion 3 stops recognising New Mexico as an owner of 2027-01-01',
      aimedAt: 'assertion 3',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: "   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('nm', 'ut');",
          replace: "   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('zz', 'ut');",
        },
      ],
    },
    {
      id: 'C27',
      label: "the day's TERM before-image pinned at 49 instead of the real 50",
      aimedAt: 'P11',
      chain: [
        'dates',
        { tamper: 'seating', find: '       50                                 AS expect_terms_on_the_day_before,', replace: '       49                                 AS expect_terms_on_the_day_before,' },
      ],
    },
    {
      // ⚠ THE UNION THAT IDAHO COULD NOT EXERCISE. There the winners and the predecessors were the
      //    same seven people; here five seats change hands, so the guard's scope is genuinely
      //    wider than the winner set and the gate asserting so can be broken.
      id: 'C28',
      label: 'the incumbency guard scoped to the winners alone, not the union with predecessors',
      aimedAt: 'incumbency guard (the union arm)',
      chain: [
        'dates',
        {
          tamper: 'seating',
          find: 'SELECT politician_id FROM cc0506_sel WHERE politician_id IS NOT NULL\nUNION\nSELECT politician_id FROM cc0506_pre WHERE politician_id IS NOT NULL;',
          replace: 'SELECT politician_id FROM cc0506_sel WHERE politician_id IS NOT NULL;',
        },
      ],
    },
  ],
};
