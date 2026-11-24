/**
 * Maryland 2026 — the control suite run against `CC_0494`, `CC_0495` and `CC_0496` before they
 * were applied.
 *
 *   node scripts/run-migration-controls.mjs \
 *     ../data/state-seating-2026/controls/md-2026.controls.mjs
 *
 * ⚠ **A SUITE CANNOT BE RE-RUN ONCE ITS CHAIN IS APPLIED** — the negative control fails and the
 *   harness refuses to report, which is correct. This file is the RECORD of what was tested, and
 *   the shape to copy for the next Ruling A state (Arizona). `--check` validates the needles
 *   against the migrations without touching the database.
 *
 * 🔴🔴 **THE ONE MARYLAND NEEDED THAT NO EARLIER STATE DID: C12.** REGISTER.md's step 6 warns
 *   that `WAVE_SELECTION_SQL` keys every winner on the **race-carrying** office, while Ruling A
 *   writes 30 of Maryland's 178 terms to a **sibling** office — so a post-verify built the
 *   published way joins `office_terms` back to an office that was never written, finds 114 of
 *   178, and aborts **after** the write. C12 reproduces exactly that by changing assertion 1's
 *   join to `s.race_office_id`, and watches it report the shortfall. It is the only control here
 *   that can reach a post-verify at all: every selection-shaped tamper is caught by the digest
 *   two gates earlier, which is the backstop problem this harness exists to record.
 */
// 🔴 THREE CONTROLS FIRED ON AN EARLIER GATE THAN THEY WERE AIMED AT, AND THAT IS RECORDED
// RATHER THAN CONTRIVED AROUND: C1 (aimed at assertion 3b, fired on assertion 1), C10 (aimed at
// P7, fired on P2) and C16 (aimed at P3h, fired on P2d). Each did its job; the gate it was aimed
// at is still untested. 🟢 THE TWO THAT MATTER MOST ARE TESTED: P2a, Ruling A's equality clause,
// by C15, and assertion 1, the Ruling A post-verify, by C12.
//
// ⚠ TWO TAMPERS FAILED ON A DATABASE CHECK CONSTRAINT BEFORE THEY EVER REACHED A MIGRATION —
// C11 (result without result_source) and C15 (certainty without result) — and the harness
// reported both as RED. A tamper that did not apply is a control that proved nothing, and here
// it looked like a success rather than a pass. ▶ READ THE MESSAGE, NOT THE COLOUR.

const M = '../../../migrations';
const f = (name) =>
  new URL(`${M}/${name}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

// Subdistrict 1B is the vacancy fixture: ONE Delegate office, held by Jason C. Buckel, who is
// also its only 2026 winner. Closing his term removes the holder without changing which office
// anybody lands in — a multi-seat district would move the fill order too, and then the control
// would be testing two things at once.
const VACATE_1B = `UPDATE essentials.office_terms t
   SET term_end = DATE '2026-11-20', how_ended = 'resigned'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'md' AND d.label = 'State Legislative Subdistrict 1B'
   AND t.term_end IS NULL;`;

export default {
  name: 'Maryland 2026 — CC_0494 / CC_0495 / CC_0496',
  files: {
    dates: f('CC_0494_md_2026_swearing_in_dates.sql'),
    people: f('CC_0495_md_2026_link_60_winners_create_25.sql'),
    seating: f('CC_0496_md_general_assembly_2026_seat_178_winners.sql'),
  },
  cleanChain: ['dates', 'people', 'seating'],
  controls: [
    // ── CC_0494, the dates file ───────────────────────────────────────────────────────────────
    {
      // 🔴 IN MARYLAND THE NEAR MISS IS A LIVE DATE IN THE SAME STATE: the third Wednesday is
      //    the GOVERNOR's own commencement under Art. II § 1. A wave written one week late is
      //    not obviously absurd.
      id: 'C1',
      label: "write 2027-01-20 — the third Wednesday, which is the GOVERNOR's real date",
      aimedAt: 'assertion 3b',   // fired on assertion 1: a strict equality on the right date
                                 // catches ANY wrong day first, so 3b's 'no seat carries a
                                 // wrong Wednesday' arm is an unreachable backstop. Its
                                 // arithmetic arms are reachable and C2 tests them.
      chain: [{
        tamper: 'dates',
        find: "       DATE '2027-01-13',\n       'statute',",
        replace: "       DATE '2027-01-20',\n       'statute',",
      }],
    },
    {
      id: 'C2',
      label: 'the second Wednesday computed as the first Wednesday + 14',
      aimedAt: 'assertion 3a',
      chain: [{ tamper: 'dates', find: '  second_wed := first_wed + 7;', replace: '  second_wed := first_wed + 14;' }],
    },
    {
      // 🟢 THE STATE ARCHIVES' OWN SENTENCE. "Legislators elected in the 2022 General Election
      //    took office on January 11, 2023" is the only corroboration this date has outside the
      //    constitution, and assertion 3d re-derives it. Moving the expectation to the FIRST
      //    Wednesday of 2023 must break it — otherwise the gate is not reading the clause.
      id: 'C3',
      label: 'assertion 3d expects the sitting members to have taken office on 2023-01-04',
      aimedAt: 'assertion 3d',
      chain: [{
        tamper: 'dates',
        find: "        archives_2023     CONSTANT date := DATE '2023-01-11';   -- the Manual's own sentence",
        replace: "        archives_2023     CONSTANT date := DATE '2023-01-04';   -- the Manual's own sentence",
      }],
    },
    {
      // 🔴 THE HARLAN TRAP — the only Maryland legislative term carrying a start date is an
      //    APPOINTMENT, and the gate must be reading that row rather than asserting at it.
      id: 'C4',
      label: "assertion 3e expects Harlan's appointment on a different day",
      aimedAt: 'assertion 3e',
      chain: [{
        tamper: 'dates',
        find: "        harlan_expected   CONSTANT date := DATE '2026-08-03';",
        replace: "        harlan_expected   CONSTANT date := DATE '2026-08-04';",
      }],
    },
    {
      // 🔴 THE FOUR GAP CONTESTS ARE NAMED, AND THE NAMING IS LOAD-BEARING. Dropping District 6
      //    from the list must make the 10 undated seats stop being the ten this file measured.
      id: 'C5',
      label: 'P3 stops recognising District 6 as one of the four unrecorded contests',
      aimedAt: 'P3',
      chain: [{
        tamper: 'dates',
        find: "     AND d.label NOT IN ('State Legislative District 4', 'State Legislative District 6',\n                         'State Legislative District 31', 'State Legislative Subdistrict 34B');",
        replace: "     AND d.label NOT IN ('State Legislative District 4',\n                         'State Legislative District 31', 'State Legislative Subdistrict 34B');",
      }],
    },
    {
      // 🔴🔴 THE RULING A DEFECT, AT THE DATES FILE. Selecting only the race-carrying offices is
      //    what the published template does; it must not survive P1, because the 64 sibling
      //    seats would then reach CC_0496 undated and abort it after writing.
      id: 'C6',
      label: 'the dates file selects only the 114 race-carrying offices',
      aimedAt: 'P1',
      chain: [{
        tamper: 'dates',
        find: "  JOIN essentials.offices   o2 ON o2.district_id = r.district_id\n                              AND o2.chamber_id IS NOT DISTINCT FROM r.chamber_id\n                              AND o2.title = r.title\n  JOIN essentials.districts d2 ON d2.id = o2.district_id;",
        replace: "  JOIN essentials.offices   o2 ON o2.id = r.race_office_id\n  JOIN essentials.districts d2 ON d2.id = o2.district_id;",
      }],
    },
    {
      // Maryland's federal exclusion needed NATIONAL_LOWER only — Oregon's needed NATIONAL_UPPER
      // too, because Oregon had a Senate seat up. This proves the arm is load-bearing here.
      id: 'C7',
      label: "assertion 5 stops excusing Maryland's 8 congressional rows",
      aimedAt: 'assertion 5',
      chain: [{
        tamper: 'dates',
        find: "     AND NOT (dd.district_type = 'NATIONAL_LOWER'\n              AND s.swearing_in_date = DATE '2027-01-03'\n              AND s.rule_id = 'us-const-amend-xx-1');",
        replace: "     AND NOT (dd.district_type = 'NATIONAL_UPPER'\n              AND s.swearing_in_date = DATE '2027-01-03'\n              AND s.rule_id = 'us-const-amend-xx-1');",
      }],
    },

    // ── CC_0495, the people file ──────────────────────────────────────────────────────────────
    {
      // 🔴 A LINK TO SOMEBODY WHO HOLDS NO MARYLAND SEAT. This is the shape of the Mark Harris
      //    error: a name that matches, a person who does not.
      id: 'C8',
      label: "District 3's Ken Kerr linked to the MISSISSIPPI Kevin Ford",
      aimedAt: 'P4',
      chain: ['dates', {
        tamper: 'people',
        find: "'c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255', 'Ken Kerr',",
        replace: "'8ac69128-f1d9-44ee-8abb-da344684ab46', 'Ken Kerr',",
      }],
    },
    {
      // 🔴🔴 THE ONE THAT MATTERS MOST: a link to a REAL SITTING MARYLAND DELEGATE who sits in a
      //    DIFFERENT DISTRICT. P4 cannot see it — he is an active Maryland officeholder. Only
      //    P5, which scopes the match to the race's own eligible offices, can.
      id: 'C9',
      label: "District 3's Karen Simpson linked to David Moon, who sits for District 20",
      aimedAt: 'P5',
      chain: ['dates', {
        tamper: 'people',
        find: "'5946ad0c-ddf5-4674-840e-6968105042cd', 'Karen Simpson',",
        replace: "'96876928-53f8-4ed5-b2de-deab3a456d83', 'Karen Simpson',",
      }],
    },
    {
      // The deliberate duplicate, linked instead of created. P7 is written for exactly this, and
      // P2 is expected to catch it first — recorded rather than contrived around.
      id: 'C10',
      label: "Kevin Ford pointed at the Mississippi row instead of a new one",
      aimedAt: 'P7',   // fired on P2: the Mississippi id already exists, so 'the 25 new ids
                       // are new' catches it two gates before the one written for it. P7 is a
                       // backstop, not a tested gate.
      chain: ['dates', {
        tamper: 'people',
        find: "'938d4f3b-c204-4059-84d1-6f4999548e69', 'Kevin Ford',",
        replace: "'8ac69128-f1d9-44ee-8abb-da344684ab46', 'Kevin Ford',",
      }],
    },
    {
      // 🔴 THE MISSING RESULT ARRIVING. If District 31's Delegate contest gains a winner, Kipke's
      //    old seat IS in the wave, the "4 of 5 switchers" claim becomes false, and this file
      //    must refuse rather than quietly describe a world that has changed.
      id: 'C11',
      label: "District 31's Delegate contest gains a recorded winner",
      aimedAt: 'P6',
      chain: ['dates', {
        sql: `UPDATE essentials.race_candidates rc
   SET result = 'won', result_certainty = 'called',
       result_source = 'CONTROL C11 — must never reach production'
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'md' AND d.label = 'State Legislative District 31'
   AND d.district_type = 'STATE_LOWER'
   AND rc.id IN (SELECT rc2.id FROM essentials.race_candidates rc2
                  WHERE rc2.race_id = r.id ORDER BY rc2.full_name LIMIT 3);`,
      }, 'people'],
    },

    // ── CC_0496, the seating file ─────────────────────────────────────────────────────────────
    {
      // 🔴🔴 THE RULING A POST-VERIFY, AND THE ONLY CONTROL HERE THAT REACHES ONE. Built the
      //    published way — joining office_terms back on the RACE-CARRYING office — assertion 1
      //    looks for terms on 114 offices and finds them, but misses the 64 sibling seats. The
      //    message is the evidence: it must report a shortfall, not a vacuous zero.
      id: 'C12',
      label: 'post-verify 1 joins office_terms back on the RACE-CARRYING office',
      aimedAt: 'assertion 1',
      chain: ['dates', 'people', {
        tamper: 'seating',
        find: "    FROM essentials.office_terms t JOIN cc0496_sel s ON s.office_id = t.office_id\n   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;",
        replace: "    FROM essentials.office_terms t JOIN cc0496_sel s ON s.race_office_id = t.office_id\n   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;",
      }],
    },
    {
      // Ruling A's fill order is part of the claim, and the digest is what pins it. Reversing it
      // moves real people between real seats without changing a single count.
      id: 'C13',
      label: 'the Ruling A fill order reversed (office_id DESC)',
      aimedAt: 'P3 digest',
      chain: ['dates', 'people', {
        tamper: 'seating',
        find: "         row_number() OVER (PARTITION BY e.race_office_id ORDER BY e.office_id::text) AS rn\n    FROM cc0496_elig e",
        replace: "         row_number() OVER (PARTITION BY e.race_office_id ORDER BY e.office_id::text DESC) AS rn\n    FROM cc0496_elig e",
      }],
    },
    {
      // 🔴🔴 THE COVERAGE GATE. A seat loses its holder AND the library's published selection is
      //    used (no `och.politician_id IS NOT NULL`), so is_reelection goes NULL, the
      //    concatenation goes NULL, and string_agg drops the row — every count still reads 178.
      id: 'C14',
      label: "Subdistrict 1B falls vacant AND the library's published selection is used",
      aimedAt: 'P3 coverage',
      chain: ['dates', 'people', { sql: VACATE_1B }, {
        tamper: 'seating',
        find: "       (a.politician_id IS NOT NULL\n         AND och.politician_id IS NOT NULL\n         AND och.politician_id = a.politician_id)         AS is_reelection,",
        replace: "       (a.politician_id IS NOT NULL\n         AND och.politician_id = a.politician_id)         AS is_reelection,",
      }],
    },
    {
      // The SAME vacancy with the fix in place: the value becomes false instead of vanishing, so
      // the DIGEST gate catches it. Neither gate can see the other's fault — this is the pair
      // that proves they are complementary rather than redundant, on one input.
      id: 'C14b',
      label: 'the same vacancy, with the IS NOT NULL fix in place',
      aimedAt: 'P3 digest',
      chain: ['dates', 'people', { sql: VACATE_1B }, 'seating'],
    },
    {
      // 🔴🔴 RULING A'S EQUALITY CLAUSE — THE GATE WITH THE REAL-WORLD COST, AND THE ONE THAT
      //    ALMOST SHIPPED UNTESTED. District 20 loses one of its three recorded winners, so the
      //    race has 2 winners and 3 eligible offices: the shape of a STAGGERED body, where
      //    "fill the remaining offices" would hand a sitting member's chair to somebody who did
      //    not win it. The file must refuse rather than fill.
      //
      //    ⚠ THE FIRST VERSION OF THIS CONTROL COULD NOT GO RED, AND THAT IS WHY P2 MOVED. It
      //    widened the eligible set by dropping the `title` and `chamber_id` conditions — which
      //    changes nothing in Maryland, because a STATE_LOWER district row and a STATE_UPPER
      //    district row are separate rows and each holds only its own chamber's offices. The
      //    tamper was real, applied, and faultless. ▶ A tamper that does not create the fault
      //    is a control that proved nothing, and it looks exactly like a passing chain.
      id: 'C15',
      label: "District 20 loses one of its three winners — 2 winners, 3 eligible seats",
      aimedAt: 'P2a',
      chain: ['dates', 'people', {
        sql: `UPDATE essentials.race_candidates rc
   SET result = NULL, result_certainty = NULL, result_source = NULL
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03' AND rc.result = 'won'
   AND lower(d.state) = 'md' AND d.label = 'State Legislative District 20'
   AND d.district_type = 'STATE_LOWER'
   AND rc.id = (SELECT rc2.id FROM essentials.race_candidates rc2
                 WHERE rc2.race_id = r.id AND rc2.result = 'won'
                 ORDER BY rc2.full_name LIMIT 1);`,
      }, 'seating'],
    },
    {
      // The anchor is the half of Ruling A that is NOT arbitrary: a winner who already holds an
      // eligible seat keeps it. Inverting the test unseats 148 people into sibling chairs.
      id: 'C16',
      label: 'the incumbent anchor inverted (anchor to a seat you do NOT hold)',
      aimedAt: 'P3h',   // fired on P2d: inverting the anchor makes 270 assignment rows, so the
                        // bijection check catches it first. P2d is a real gate and this is the
                        // control that tested it; P3h remains a backstop.
      chain: ['dates', 'people', {
        tamper: 'seating',
        find: " WHERE w.politician_id IS NOT NULL AND och.politician_id = w.politician_id;",
        replace: " WHERE w.politician_id IS NOT NULL AND och.politician_id <> w.politician_id;",
      }],
    },
    {
      // Kipke's kept Delegate term is the visible trace of a missing result. If it closes before
      // this file runs, the claim in the header stops being true.
      id: 'C17',
      label: "Kipke's Delegate District 31 term closed before the file runs",
      aimedAt: 'P8',
      chain: ['dates', 'people', {
        sql: `UPDATE essentials.office_terms t
   SET term_end = DATE '2026-11-22', how_ended = 'resigned'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND t.politician_id = '0e0bdc53-b5a2-4292-aeb7-341a4c5bed08'
   AND lower(d.state) = 'md' AND d.label = 'State Legislative District 31'
   AND d.district_type = 'STATE_LOWER' AND t.term_end IS NULL;`,
      }, 'seating'],
    },
    {
      // Ruling B: the wave seats from a CALLED result and says so.
      id: 'C18',
      label: "District 20's result becomes certified",
      aimedAt: 'P11',
      chain: ['dates', 'people', {
        sql: `UPDATE essentials.race_candidates rc
   SET result_certainty = 'certified'
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'md' AND d.label = 'State Legislative District 20'
   AND d.district_type = 'STATE_LOWER';`,
      }, 'seating'],
    },
    {
      id: 'C19',
      label: 'the written term source stops saying "called, not certified"',
      aimedAt: 'assertion 15',
      chain: ['dates', 'people', {
        tamper: 'seating',
        find: "                         || 'called, not certified, when this ran. Confirmed candidate by '",
        replace: "                         || 'when this ran. Confirmed candidate by '",
      }],
    },
    {
      // 🔴 AN ARBITRARY-BUT-HONEST ASSIGNMENT THAT DOES NOT SAY SO CANNOT BE AUDITED. 30 of the
      //    178 terms were assigned rather than anchored; each must carry its own explanation.
      id: 'C20',
      label: 'the Ruling A explanation dropped from the assigned seats\' source',
      aimedAt: 'assertion 15 (Ruling A arm)',
      chain: ['dates', 'people', {
        tamper: 'seating',
        find: "                              'RULING A: Maryland elects up to three Delegates from one '",
        replace: "                              'Maryland elects up to three Delegates from one '",
      }],
    },
  ],
};
