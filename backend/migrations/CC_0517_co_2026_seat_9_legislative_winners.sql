-- CC_0517 — Colorado: seat the 9 legislative winners of 2026-11-03, from 2027-01-11.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS DOES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Nine seats: State House Districts 14, 16, 17, 18, 20 and 56, and State Senate Districts 9, 11
-- and 35. **7 re-elections and 2 handovers**, all 9 `called` rather than certified when this ran.
-- The term start is read from `essentials.office_swearing_in`, written by `CC_0516`, which dates
-- these nine under **Colo. Const. Art. V § 7 + C.R.S. § 2-2-303.5(3) + HOUSE JOINT RESOLUTION
-- 26-1031** with basis **`published`** — the first `published` basis in this pass.
--
-- The other nine Colorado winners take office a day later, on 2027-01-12, under three different
-- instruments, and are seated by their own file. ⚠ That file's slot is named **here in the header
-- and nowhere in the data**: Ruling B recovers a wave with `source LIKE '%<slot>%'`, so naming a
-- sibling slot in a `source` column makes these rows answer to that wave's query. Texas's first
-- chain rehearsal aborted exactly that way, with 12 rows claiming to be its sibling's.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE CLOSURE DAY IS 2027-01-10 AND 193 TERMS ALREADY END THERE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor at `p_term_start - 1`, which is **2027-01-10** — and
-- that is the day before **2027-01-11**, the start date Oregon's 75 and Washington's 118
-- legislative seats already carry. So **193 terms end on 2027-01-10 before this file runs, and not
-- one of them is Colorado's.** A "nothing else ends on this day" assertion written as a **total**
-- would report all 193 as a fault. Texas's did, on 68 rows. Assertion 6c is therefore a **delta
-- plus a Colorado scope**, and the before-image of that column is pinned.
--
-- 🔴🔴 **AND THE START DAY IS THE SAME SHAPE FROM THE OTHER SIDE.** 2027-01-11 carries **193 terms
--   and 193 swearing-in rows** before this file, under two `rule_id`s that both literally contain
--   the words **`second-monday-january`** (`or-const-art4-s4-second-monday-january` 75,
--   `wa-rcw-44-04-021-second-monday-january` 118). Colorado's nine arrive there under a
--   **designated** day that merely coincides — the second Monday is a rival this state's own data
--   cannot refuse and which is right in 2027, and only three joint resolutions refuse it. So
--   assertion 3 is a delta and requires every row on the day to belong to a **named** rule, and
--   Colorado's is named for what it is.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 ALL NINE PREDECESSORS ARE DATED, AND SEVEN OF THEM ARE THE DATE CONTROL'S OWN FIXTURE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Arizona's shape, in a sharper form. The nine terms this file closes carry these starts:
--
--   State House District 14   Ava Flanell           **2025-10-11**  (a Saturday — an appointment)
--   State House District 16   Rebecca Keltie          2025-01-08
--   State House District 17   Regina English          2023-01-09
--   State House District 18   Amy Paschal             2025-01-08
--   State House District 20   Jarvis Caldwell         2025-01-08
--   State House District 56   Chris Richardson        2025-01-08
--   State Senate District 9   Lynda Zamora Wilson   **2025-07-08**  (a Tuesday in July — ditto)
--   State Senate District 11  Tony Exum               2023-01-09
--   State Senate District 35  Rod Pelton              2023-01-09
--
-- 🔴 **Seven of the nine sit on the 2023-01-09 and 2025-01-08 clusters that `CC_0516`'s assertion
--   3d reads as its in-data control.** Closing a term writes `term_end`, not `term_start`, so the
--   control's counts are unaffected — but `seat_officeholder` writes **nothing to a closed row's
--   `source`**, so if a `term_start` ever did move there would be no record of what it held and
--   the date control would silently stop reproducing. Assertion 6b asserts all nine starts are
--   byte-for-byte what the pre-image captured.
--
-- 🟢 **AND THE TWO APPOINTMENTS ARE WHY THE GATE IS "THEY DID NOT MOVE" AND NOT "THEY ARE ON A
--   CLUSTER DAY".** Flanell's 2025-10-11 and Zamora Wilson's 2025-07-08 are **correct rows** —
--   Colorado fills legislative vacancies by party vacancy committee and does so often, which is
--   why the state carries seventeen off-cluster legislative term starts. A check shaped "every
--   predecessor starts on a cycle day" would fail honestly on two real rows. **Idaho's lesson —
--   the discriminating field is the month, and an appointment is not a cycle start — reached from
--   the predecessor side.**
--
-- ⚠ **Ava Flanell is both the predecessor and the winner on District 14**, having been appointed
--   in October 2025 and elected in 2026, so her own undated-by-cycle term is the one this file
--   closes. That is a re-election and `p_allow_reelection` is what lets it close.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT THIS FILE DOES NOT TOUCH
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴🔴 **FIFTY-NINE COLORADO HOUSE SEATS AND THIRTY-TWO SENATE SEATS HAVE NO 2026 WINNER, AND THE
--   CONSTITUTION MAKES THE HOUSE'S SHARE CERTAIN.** Art. V § 3(1) gives every representative a
--   **two-year** term, so all 65 House seats were on the 2026 ballot as a matter of law; we hold 9
--   House races and 6 winners. Art. V § 5 divides the Senate "so that one-half of the senators, as
--   nearly as practicable, may be chosen biennially" — 17 or 18 of 35 — and we hold 3.
--   ⚠ **The gap comes in two shapes that are identical from the seat**: Districts 15, 21 and 22
--   carry a 2026 race whose candidates all have `result IS NULL`, and 56 House and 32 Senate seats
--   carry **no race row of any year**. P5 gates on both counts *staying* what they are: if one
--   gains a winner this wave is larger and the pin is stale.
--   🟢 All twelve legislative races we do hold come from one source — the Colorado Secretary of
--   State's 2026 general election candidate list — and cover House 14–22 and 56 and Senate 9, 11
--   and 35, which is El Paso County plus three. A **partial load of a statewide publication**,
--   which is the more hopeful diagnosis and the one that tells the results programme where to look.
--
-- ⚠ **State House District 32 is flagged `is_vacant`** and has no 2026 race of any kind, so there
--   is no winner to seat and no flag to clear. A future-dated seating does not clear a flag in any
--   case; assertion 8 asserts the flagged count did not move.
--
-- 🟢 **NOBODY IN THIS WAVE WILL HOLD TWO SEATS.** Not one of the nine winners holds an office
--   outside these nine. ⚠ **That zero has no natural fixture here**, which is Idaho's position —
--   so it is asserted as an absence (P8b) rather than offered as a tested gate, and the two real
--   dual holders in this state are both in the other file, where a control can reach them.
--
-- 🔴 **This file OVERWRITES ONE VALUE PER SEAT: the predecessor's `term_end`, which was NULL on all
--   nine**, and sets `how_ended = 'term_expired'`. `seat_officeholder` does that with an
--   **unguarded** `UPDATE` and records nothing in the closed row's own `source`, so the pre-image
--   captured in `cc0517_pre` is the only record of what those rows held. All nine had
--   `term_end IS NULL` and `how_ended IS NULL` (P6 asserts both before writing).

-- @incumbency-decision: gated — this file opens 9 Colorado terms on 2027-01-11 and closes each
--   predecessor's own term at 2027-01-10, so it restates who held those nine seats on every
--   election day the closed terms no longer cover. ⚠ SEVEN OF THE NINE ARE RE-ELECTIONS, so the
--   arm that bites hardest is the one Idaho and Connecticut could not reach at all — but TWO
--   seats do change hands (District 16 and Senate District 9), and a newcomer whose race row still
--   says `is_incumbent = true` is exactly the contradiction `check:incumbency` would report on the
--   NEXT merge, under somebody else's name.
-- 🔴 THE GUARD'S SCOPE IS A UNION OF WINNERS AND PREDECESSORS. ⚠ Here the two sets OVERLAP almost
--    completely — seven of nine winners are their own predecessor — so the union is 11 people, not
--    18. Stated rather than left to be noticed, because a union that is nearly an intersection
--    looks like a scoping bug and is not one.

BEGIN;

CREATE TEMP TABLE cc0517_pin ON COMMIT DROP AS
SELECT 9                                  AS expect_winners,
       9                                  AS expect_offices,
       7                                  AS expect_reelections,
       2                                  AS expect_new,
       9                                  AS expect_predecessors,
       9                                  AS expect_predecessors_dated,
       0                                  AS expect_dual_seat,
       9                                  AS expect_called,
       193                                AS expect_terms_on_the_day_before,
       193                                AS expect_terms_ending_prev_before,
       0                                  AS expect_terms_ending_prev_co_before,
       'ec189254c645f12bd5ebfeb25bd80802' AS expect_digest,
       DATE '2027-01-11'                  AS expect_term_start,
       DATE '2027-01-10'                  AS expect_predecessor_end,
       'co-hjr26-1031-convening'          AS expect_rule_id;

-- 🟢 NO SIBLING EXPANSION: every race is single-seat with one winner, so each winner is keyed on
--    the office that carried their own race and Ruling A is not engaged.
-- 🔴 `is_reelection` TAKES BOTH ID CHECKS. Without `och.politician_id IS NOT NULL` the expression is
--    NULL on a holderless seat, `'…' || NULL` is NULL, `string_agg` SKIPS it, and the digest
--    silently covers fewer rows than every count claims — and it is the holderless seats it drops.
--    All nine are held here, so the defect cannot occur; P3 measures it anyway, because a control
--    proved the coverage gate and the digest gate are complementary rather than redundant.
CREATE TEMP TABLE cc0517_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       o.title                                           AS title,
       d.label                                           AS label,
       d.district_type                                   AS district_type,
       (win.value ->> 'id')::uuid                        AS politician_id,
       (win.value ->> 'name')                            AS winner_name,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id')) AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       si.rule_id                                        AS rule_id,
       och.politician_id                                 AS holder_before,
       w.certainty                                       AS certainty,
       w.winner_count                                    AS winner_count,
       w.seats                                           AS seats
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'co'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

-- 🔴 THE PREDECESSOR PRE-IMAGE. seat_officeholder closes these with an unguarded UPDATE and records
--    nothing in their source, so the only record of what they held is here. ⚠ ALL NINE ARE DATED,
--    and seven of their starts are the fixture CC_0516's date control reads.
CREATE TEMP TABLE cc0517_pre ON COMMIT DROP AS
SELECT s.office_id, s.label, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended
  FROM cc0517_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

-- Any winner who keeps a seat outside this wave. ⚠ EXPECTED EMPTY, and the emptiness is asserted
--    rather than assumed — a zero with no fixture is Idaho's position and is recorded as such.
CREATE TEMP TABLE cc0517_dual ON COMMIT DROP AS
SELECT s.winner_name, s.label AS takes, t.id AS kept_term_id, d2.label AS keeps
  FROM cc0517_sel s
  JOIN essentials.office_terms t ON t.politician_id = s.politician_id
                                AND t.office_id <> s.office_id
  JOIN essentials.offices   o2 ON o2.id = t.office_id
  JOIN essentials.districts d2 ON d2.id = o2.district_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start)
   AND t.office_id NOT IN (SELECT office_id FROM cc0517_sel);

CREATE TEMP TABLE cc0517_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                               AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-11')
                                                                                    AS terms_on_the_day,
       -- 🔴🔴 THE CLOSURE DAY IS SHARED, AND IT IS A COLUMN NOBODY THINKS OF AS A DATE.
       --    2027-01-10 is the day BEFORE 2027-01-11, so Oregon's and Washington's seatings closed
       --    their own predecessors on it: 193 terms already end there and NONE is Colorado's.
       (SELECT count(*) FROM essentials.office_terms WHERE term_end = DATE '2027-01-10')
                                                                                    AS terms_ending_prev,
       (SELECT count(*) FROM essentials.office_terms t
          JOIN essentials.offices o   ON o.id = t.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE t.term_end = DATE '2027-01-10' AND lower(d.state) = 'co')            AS terms_ending_prev_co,
       -- The near misses, AS TERMS. 🔴 2027-01-13 is the STATUTORY DEFAULT this state did not use,
       --    and it is the Maryland General Assembly's live day.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-13')
                                                                                    AS terms_jan13,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                    AS terms_jan4,
       -- ⚠ The sibling group's day, which this file must not reach.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-12')
                                                                                    AS terms_jan12,
       (SELECT count(*) FROM essentials.politicians)                                AS politicians,
       (SELECT count(*) FROM essentials.offices)                                    AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                    AS vacant_all,
       (SELECT count(*) FROM cc0517_pre)                                            AS predecessors,
       (SELECT count(*) FROM cc0517_dual)                                           AS dual_seat,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                                AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                    AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices_missing_terms)                      AS missing_all;

DO $$
DECLARE n bigint; d text; p record; b record;
BEGIN
  SELECT * INTO p FROM cc0517_pin;
  SELECT * INTO b FROM cc0517_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT. On a second run the seats have left office_pending_winner, so
  --      a count check fires first and blames the data for what is a repeat apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0517%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0517. Applied before.', n;
  END IF;

  -- P2 — the shape of the selection.
  SELECT count(*) INTO n FROM cc0517_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2: selection returned % winner rows, expected 9 — 6 House seats (Districts '
                    '14, 16, 17, 18, 20, 56) and 3 Senate seats (Districts 9, 11, 35).',
                    n;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0517_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2: % distinct offices, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0517_sel WHERE winner_count <> 1 OR COALESCE(seats, 1) <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 9 races are not single-seat with exactly one winner. 🔴 THIS '
                    'SELECTION KEYS EVERY WINNER ON THE RACE-CARRYING OFFICE, so a Ruling A '
                    'assignment to a sibling office would leave post-verify 1 unable to find the '
                    'term — after it had been written.', n;
  END IF;
  -- 🔴 No Group B office may reach this selection: they take office a DAY LATER, and one leaking
  --    in would be seated a day early under a rule that does not govern it.
  SELECT count(*) INTO n
    FROM cc0517_sel
   WHERE district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % non-legislative office(s) reached this selection. The executives and '
                    'both boards commence on the SECOND TUESDAY (2027-01-12) under Art. IV § 1(1), '
                    'C.R.S. § 22-2-105(1) and C.R.S. § 23-20-105(2); the legislature commences on '
                    'the DESIGNATED CONVENING DAY (2027-01-11). The two days are ONE APART and are '
                    'each other''s near miss, so a leak would look like a rounding error.', n;
  END IF;

  -- P3 — 🔴🔴 THE DIGEST, AND THE COUNT OF ROWS IT ACTUALLY EVALUATED.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text) INTO n
    FROM cc0517_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % row(s), so string_agg '
                    'silently dropped them. Add och.politician_id IS NOT NULL to is_reelection.',
                    p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text)) INTO d
    FROM cc0517_sel;
  IF d <> p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'MEMBERSHIP moved without the size moving — a different winner, a different '
                    'office, or a re-election that became a handover. Re-derive before applying.',
                    d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0517_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected % — only District 16 and Senate District 9 change '
                    'hands. A re-election is what switches p_allow_reelection on, which is what '
                    'lets seat_officeholder close the winner''s OWN predecessor term.',
                    n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0517_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P3: % handovers, expected % — Steph Vigil takes House District 16 from Rebecca '
                    'Keltie and Terri Carver takes Senate District 9 from Lynda Zamora Wilson.',
                    n, p.expect_new;
  END IF;
  SELECT count(*) INTO n FROM cc0517_sel WHERE certainty = 'called';
  IF n <> p.expect_called THEN
    RAISE EXCEPTION 'P3: % of the 9 are `called`, expected % — Ruling B seats from a called result '
                    'and records which it was, so a canvass reversal is recoverable by slot.',
                    n, p.expect_called;
  END IF;
  -- 🔴 THE PIN NAMES THE PEOPLE, NOT ONLY THE COUNTS. A digest proves the membership did not move;
  --    this proves the membership is the one a human read.
  SELECT count(*) INTO n
    FROM cc0517_sel s
   WHERE (s.label, s.winner_name) IN (
     VALUES ('State House District 14',  'Ava Flanell'),
            ('State House District 16',  'Steph Vigil'),
            ('State House District 17',  'Regina English'),
            ('State House District 18',  'Amy T Paschal'),
            ('State House District 20',  'Jarvis Caldwell'),
            ('State House District 56',  'Chris Richardson'),
            ('State Senate District 9',  'Terri Carver'),
            ('State Senate District 11', 'Tony Exum Sr'),
            ('State Senate District 35', 'Rod Pelton'));
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: only % of the 9 (office, winner) pairs match the names this file was '
                    'written against, expected %. ⚠ Three winner names differ from the '
                    'politicians row they point at — "Tony Exum Sr"/"Tony Exum" and "Amy T '
                    'Paschal"/"Amy Paschal" here — so this gate uses the RACE''s spelling, which '
                    'is what office_pending_winner returns.', n, p.expect_winners;
  END IF;

  -- P4 — every seat carries CC_0516's date, its rule, and a basis that may seat somebody.
  SELECT count(*) INTO n FROM cc0517_sel WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 9 seats have no swearing-in date, or one that is not %. CC_0516 '
                    'must be applied first — it dates nineteen Colorado offices across two days.',
                    n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0517_sel WHERE basis NOT IN ('statute', 'published');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % date(s) have a basis that is neither statute nor published. AN ESTIMATE '
                    'MAY NOT SEAT ANYBODY — a term start is a legal fact.', n;
  END IF;
  -- 🔴 AND THIS IS THE FIRST WAVE WHERE `published` DOES ANY WORK, so it is asserted positively
  --    rather than merely permitted: these nine are dated by a DESIGNATING RESOLUTION, and if the
  --    basis has become `statute` somebody has re-dated them from the default — which would be
  --    2027-01-13, the Maryland General Assembly's day.
  SELECT count(*) INTO n FROM cc0517_sel WHERE basis <> 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 9 seats are no longer dated with basis `published`. Colorado''s '
                    'legislative day comes from HOUSE JOINT RESOLUTION 26-1031, a document, not '
                    'from the statutory default — which would be 2027-01-13 and is the Maryland '
                    'General Assembly''s live start date, 178 rows.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0517_sel WHERE rule_id <> p.expect_rule_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 9 seats are dated under a rule_id other than %. ⚠ THE DAY IS '
                    'SHARED WITH TWO OTHER STATES WHOSE rule_ids BOTH CONTAIN THE WORDS '
                    '"second-monday-january" (Oregon 75, Washington 118), and the second Monday is '
                    'a rival that gives the right answer in 2027 — so a borrowed rule_id here '
                    'would be invisible to every count in this file.', n, p.expect_rule_id;
  END IF;

  -- P5 — 🔴🔴 THE ABSENT LEGISLATIVE SEATS, ASKED BEFORE WRITING, AND IN BOTH OF THEIR SHAPES.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_LOWER'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_pending_winner w
                      WHERE w.office_id = o.id AND w.election_date = DATE '2026-11-03');
  IF n <> 59 THEN
    RAISE EXCEPTION 'P5: % Colorado House seats have no 2026 winner, expected 59. Art. V § 3(1) '
                    'gives every representative a TWO-YEAR term, so all 65 were on the ballot as a '
                    'matter of law and every one of the 59 is certainly missing data. If this has '
                    'fallen, results have arrived and this wave is larger than the pin.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_UPPER'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_pending_winner w
                      WHERE w.office_id = o.id AND w.election_date = DATE '2026-11-03');
  IF n <> 32 THEN
    RAISE EXCEPTION 'P5: % Colorado Senate seats have no 2026 winner, expected 32. Art. V § 5 puts '
                    'one-half "as nearly as practicable" on each biennial ballot, so 17 or 18 of '
                    'the 35 were up.', n;
  END IF;
  -- 🔴 AND THE THREE SEATS WITH A RACE AND A BLANK RESULT ARE NAMED, not counted — they are the
  --    class that looks identical to "no race at all" from the seat, and they are the ones most
  --    likely to gain a winner while this branch is open.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co'
     AND d.label IN ('State House District 15', 'State House District 21',
                     'State House District 22')
     AND EXISTS (SELECT 1 FROM essentials.races r
                   JOIN essentials.elections e ON e.id = r.election_id
                   JOIN essentials.race_candidates rc ON rc.race_id = r.id
                  WHERE r.office_id = o.id AND e.election_date = DATE '2026-11-03'
                    AND rc.result = 'won');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % of House Districts 15, 21 and 22 now record a winner, expected 0. Those '
                    'three carry a 2026 race whose candidates ALL have result IS NULL — not '
                    '"advanced", which would be a primary result, but blank. If one has been '
                    'filled this wave is larger than nine and the pin is stale.', n;
  END IF;

  -- P6 — the vacancy flags and the predecessor pre-image.
  SELECT count(*) INTO n
    FROM cc0517_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of the 9 offices are flagged is_vacant. A FUTURE-dated seating does not '
                    'clear the flag — only a term that has already begun does — so a flagged seat '
                    'must be handled deliberately in its own handover-day file (CC_0480, CC_0486), '
                    'not swept along.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0517_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) captured, expected % — one per seat. A seat with two '
                    'covering terms, or none, is not a seat this file can close cleanly.',
                    n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0517_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a term_end. seat_officeholder''s '
                    'UPDATE has NO term_end IS NULL guard, so it would overwrite a real end date '
                    'and record nothing of what it replaced.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0517_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a how_ended.', n;
  END IF;
  -- 🔴🔴 ALL NINE ARE DATED, WHICH IS ARIZONA'S SHAPE AND IS PINNED RATHER THAN ASSUMED — and seven
  --    of those dates are the very rows CC_0516's assertion 3d reads as its in-data control.
  SELECT count(*) INTO n FROM cc0517_pre WHERE term_start IS NOT NULL;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) carry a term_start, expected % — ALL NINE are dated '
                    'here, unlike Texas''s twelve which were all NULL. Seven of the nine sit on the '
                    '2023-01-09 and 2025-01-08 clusters that CC_0516''s date control reads, and the '
                    'other two (2025-10-11 and 2025-07-08) are vacancy-committee appointments. '
                    'Closing a term writes term_end and not term_start, so the control''s counts '
                    'are unaffected — but seat_officeholder writes NOTHING to a closed row''s '
                    'source, so a moved start would be unrecoverable. Assertion 6b asserts none '
                    'moved.', n, p.expect_predecessors_dated;
  END IF;
  -- The seven re-elections must have the winner as their own predecessor; the two handovers must not.
  SELECT count(*) INTO n
    FROM cc0517_sel s JOIN cc0517_pre r ON r.office_id = s.office_id
   WHERE s.is_reelection AND r.politician_id IS DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % re-elected winner(s) are not the predecessor on their own seat. A '
                    're-election means seat_officeholder closes the winner''s OWN term, and '
                    'p_allow_reelection is what permits it.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0517_sel s JOIN cc0517_pre r ON r.office_id = s.office_id
   WHERE NOT s.is_reelection AND r.politician_id = s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % handover(s) have the winner as their own predecessor, which makes them '
                    're-elections the selection failed to recognise.', n;
  END IF;

  -- P7 — the squares this file's deltas are measured against.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P7: % already carries % term(s), expected % — Oregon 75 and Washington 118. '
                    'Every count about that day is a DELTA and a third state''s arrival is what '
                    'this file is.', p.expect_term_start, b.terms_on_the_day,
                    p.expect_terms_on_the_day_before;
  END IF;
  IF b.terms_ending_prev <> p.expect_terms_ending_prev_before THEN
    RAISE EXCEPTION 'P7: % already carries % term END(s), expected % — Oregon''s and Washington''s '
                    'seatings closed their own predecessors there, because it is the day before '
                    'their start date too. 🔴 THE SHARED-SQUARE RULE REACHES term_end, a column '
                    'nobody thinks of as a date: a TOTAL here would report all of them as a fault, '
                    'which is what Texas''s first rehearsal did on 68 rows.',
                    p.expect_predecessor_end, b.terms_ending_prev,
                    p.expect_terms_ending_prev_before;
  END IF;
  IF b.terms_ending_prev_co <> p.expect_terms_ending_prev_co_before THEN
    RAISE EXCEPTION 'P7: % Colorado term(s) already end on %, expected %. Every row on that day '
                    'from this state must be a predecessor this file named.',
                    b.terms_ending_prev_co, p.expect_predecessor_end,
                    p.expect_terms_ending_prev_co_before;
  END IF;
  IF b.terms_jan12 <> 0 THEN
    RAISE EXCEPTION 'P7: 2027-01-12 already carries % term(s), expected 0. That is the SIBLING '
                    'group''s day — the four executives, the two Board of Education seats and the '
                    'three Regents — and its file has not run yet. ⚠ It is also ONE DAY after this '
                    'file''s, so the two groups are each other''s near miss.', b.terms_jan12;
  END IF;

  -- P8 — nobody in this wave keeps a seat outside it. ⚠ A ZERO WITH NO FIXTURE, SAID SO.
  IF b.dual_seat <> p.expect_dual_seat THEN
    RAISE EXCEPTION 'P8: % winner(s) of this wave hold an office outside it, expected %. If that '
                    'has become non-zero, somebody will hold two seats from % and the reason needs '
                    'reading before this file runs.', b.dual_seat, p.expect_dual_seat,
                    p.expect_term_start;
  END IF;
  -- P8b — ⚠ AND THE ABSENCE IS ASSERTED AS AN ABSENCE. Not one of these nine winners holds any
  --       office outside these nine, so assertion 9's zero has NO NATURAL FIXTURE in this file —
  --       Idaho's position. The two real dual holders in Colorado (Jeff Bridges keeping Senate
  --       District 26, Amanda Gonzalez keeping Jefferson County Clerk and Recorder) are both
  --       winners of the OTHER group, where a control can reach the gate. Recorded so the next
  --       reader inherits a measurement rather than an assumption.
  SELECT count(*) INTO n
    FROM cc0517_sel s
    JOIN essentials.office_terms t ON t.politician_id = s.politician_id
   WHERE t.office_id NOT IN (SELECT office_id FROM cc0517_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8b: % term row(s) on offices outside this wave belong to one of its nine '
                    'winners, expected 0 of ANY date. This is the absence that makes assertion 9''s '
                    'zero vacuous, and it is asserted rather than assumed.', n;
  END IF;
END $$;

CREATE TEMP TABLE cc0517_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0517_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0517_pre WHERE politician_id IS NOT NULL;

CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM cc0517_guarded);

DO $$
DECLARE s record; v_seated int := 0;
BEGIN
  FOR s IN SELECT * FROM cc0517_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => s.office_id,
      p_politician_id    => s.politician_id,
      p_term_start       => s.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(s.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in. 🔴 THE TERM BEGINS ON AN EVENT AND '
                         || 'THE EVENT''S DAY IS DESIGNATED BY A DOCUMENT, WHICH IS WHY THE BASIS '
                         || 'IS `published` AND NOT `statute`: Colo. Const. Art. V § 7 provides '
                         || 'that "The term of service of the members of the general assembly shall '
                         || 'BEGIN ON THE CONVENING of the first regular session of the general '
                         || 'assembly next after their election", and that the assembly shall meet '
                         || '"NO LATER THAN the second Wednesday of January" — a deadline, not a '
                         || 'date. C.R.S. § 2-2-303.5(2) makes the second Wednesday the default '
                         || '"unless a different date is established", (3) lets the general '
                         || 'assembly "acting by JOINT RESOLUTION" designate a day "on or after '
                         || 'January 1 but prior to" the default, and HOUSE JOINT RESOLUTION '
                         || '26-1031 designates "MONDAY, JANUARY 11, 2027, as the convening date '
                         || 'for the First Regular Session of the Seventy-sixth General Assembly". '
                         || '🔴 THE STATUTORY DEFAULT WOULD HAVE BEEN TWO DAYS WRONG (2027-01-13), '
                         || 'which is the Maryland General Assembly''s live start date. 🔴 AND THE '
                         || 'SECOND MONDAY IS A RIVAL THAT GIVES THE RIGHT ANSWER IN 2027: over '
                         || 'four prior cycles of our own data the statutory default reproduces '
                         || 'exactly two (2021, 2025) and the second Monday exactly one (2023), and '
                         || 'no rule reproduces more than two of five — which is itself the '
                         || 'evidence that the day is designated rather than computed. What refuses '
                         || 'the second Monday is 2019-01-04, a FRIDAY, designated by HJR18-1021 in '
                         || 'words; HJR22-1025 designates 2023-01-09. 🟢 THE RESOLUTION CARRIES ITS '
                         || 'OWN CONTROL: its Joint Rule 22B deadline schedule prints 28 (ordinal '
                         || 'day, weekday, date) triples and all 28 agree with a 1st day of Monday '
                         || '2027-01-11, while 0 of 28 agree with the default. 🟢 THE OATH IS NOT '
                         || 'THIS DATE: Art. XII § 8 and C.R.S. § 24-12-101 both require the oath '
                         || 'BEFORE the officer enters upon the office, so it is a precondition to '
                         || 'the term; members are sworn after the body convenes. '
                         || CASE WHEN s.is_reelection
                                 THEN 'RE-ELECTED INCUMBENT: the predecessor on this seat is the '
                                   || 'winner, and their own term is closed at '
                                   || to_char(s.term_start - 1, 'YYYY-MM-DD') || '. '
                                 ELSE 'HANDOVER: this seat changes hands. Two of this wave''s nine '
                                   || 'do, and the predecessor''s term is closed at '
                                   || to_char(s.term_start - 1, 'YYYY-MM-DD') || '. '
                            END
                         || '⚠ THE CLOSURE DAY IS SHARED: 193 terms already end on '
                         || to_char(s.term_start - 1, 'YYYY-MM-DD')
                         || ' because it is the day before Oregon''s 75 and Washington''s 118 '
                         || 'legislative terms begin, so every count about it is a delta. '
                         || '🔴 FIFTY-NINE COLORADO HOUSE SEATS AND THIRTY-TWO SENATE SEATS HAVE NO '
                         || '2026 WINNER: Art. V § 3(1) gives representatives two-year terms so all '
                         || '65 House seats were on the ballot, and Art. V § 5 puts 17 or 18 of the '
                         || '35 Senate seats on each biennial ballot. Districts 15, 21 and 22 carry '
                         || 'a race with every result blank; 56 House and 32 Senate seats carry no '
                         || 'race row of any year. All twelve races we hold come from the Secretary '
                         || 'of State''s 2026 candidate list and cover House 14-22 and 56 and '
                         || 'Senate 9, 11 and 35 — El Paso County plus three — so this is a partial '
                         || 'load of a statewide publication. CC_0517',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => s.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0517: seat_officeholder called for % offices', v_seated;
END $$;

DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0517_guarded;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s))',
    v_planned, v_people, v_scoped;
  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id,
           b.politician_id,
           a.stored,
           a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b
      JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                  coalesce(pol.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(pol.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians pol ON pol.id = c.politician_id;
  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;
  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;

-- ── Post-verify. Read the output, not the exit code. ──────────────────────────────────────────
DO $$
DECLARE n bigint; m text; b record; p record;
BEGIN
  SELECT * INTO b FROM cc0517_before;
  SELECT * INTO p FROM cc0517_pin;

  -- 1. Nine terms exist, on the offices this file selected, for the people it selected.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0517_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated term(s) on %, expected %.', n, p.expect_term_start,
                    p.expect_offices;
  END IF;

  -- 2. The read path answers for all nine.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0517_sel s ON s.office_id = nx.office_id
   WHERE nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seat(s).', n, p.expect_offices;
  END IF;

  -- 3. 🔴🔴 THE DELTA ON A SHARED DAY, AND EVERY ROW ON IT MUST BELONG TO A NAMED STATE.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n - b.terms_on_the_day <> p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
                    p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day,
                    p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(d.state) NOT IN ('co', 'or', 'wa');
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to a state other than Colorado, Oregon or Washington. '
                    'THREE states share this calendar day under unrelated instruments — Oregon''s '
                    'constitution (75), RCW 44.04.021 (118) and Colorado''s HJR26-1031 (9) — and '
                    'TWO of those three rule_ids contain the words "second-monday-january" while '
                    'Colorado''s day is DESIGNATED and merely coincides. A fourth state must be '
                    'caught rather than absorbed into the count.', n, p.expect_term_start;
  END IF;
  -- 3b. No Colorado term on this day outside this wave's nine offices.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(d.state) = 'co'
     AND t.office_id NOT IN (SELECT office_id FROM cc0517_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % Colorado term(s) begin on % outside this wave''s nine offices.',
                    n, p.expect_term_start;
  END IF;
  -- 3c. 🔴 And none of the nine landed on a wrong day. ⚠ THE FIRST ENTRY IS THE SIBLING GROUP'S
  --     OWN DAY, one day later: the two groups are each other's near miss and the error would
  --     never leave this wave.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0517_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-12', DATE '2027-01-13', DATE '2027-01-04');
  IF n <> 0 THEN
    RAISE EXCEPTION '3c: % of this wave''s term(s) start on a wrong day — the sibling group''s '
                    '2027-01-12 (the second Tuesday, Art. IV § 1(1)), the STATUTORY DEFAULT '
                    '2027-01-13 (178 terms: the Maryland General Assembly) or the first Monday '
                    '2027-01-04 (229 terms: Wisconsin, Arizona, California, Idaho).', n;
  END IF;
  -- 3d. The near-miss days did not move.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-13';
  IF n <> b.terms_jan13 THEN
    RAISE EXCEPTION '3d: 2027-01-13 went % -> %, expected no change from this file. That is the day '
                    'Colorado''s own statutory default would have produced, and it is the Maryland '
                    'General Assembly''s live start date.', b.terms_jan13, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-04';
  IF n <> b.terms_jan4 THEN
    RAISE EXCEPTION '3d: 2027-01-04 went % -> %, expected no change from this file.',
                    b.terms_jan4, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-12';
  IF n <> 0 THEN
    RAISE EXCEPTION '3d: 2027-01-12 carries % term(s), expected 0 — that is the sibling group''s day '
                    'and its own file fills it. This file must not have reached it.', n;
  END IF;

  -- 4. 🔴 A FUTURE-DATED TERM MUST NOT MOVE THE CURRENT-HOLDER MAP. Nationwide digest.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text)) INTO m
    FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'change who holds a seat TODAY.', b.holders_md5, m;
  END IF;

  -- 5. 🟢 THE TWO HANDOVERS STILL ANSWER WITH THE OUTGOING PERSON. ⚠ Only two seats make this arm
  --    reachable at all; in Idaho and Connecticut every seat was a re-election and it was
  --    unreachable by construction.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0517_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of the 9 seats still answer office_current_holder with the person who '
                    'held them before this file, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0517_sel s ON s.office_id = och.office_id
   WHERE NOT s.is_reelection AND och.politician_id = s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % incoming winner(s) already answer as the CURRENT holder of a seat they do '
                    'not take until %. Rebecca Keltie must still hold House District 16 and Lynda '
                    'Zamora Wilson must still hold Senate District 9.', n, p.expect_term_start;
  END IF;

  -- 6. The predecessors closed exactly where they were meant to, and nothing else moved.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0517_pre r ON r.term_id = t.id
   WHERE t.term_end = p.expect_predecessor_end AND t.how_ended = 'term_expired';
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at % with how_ended term_expired, expected % — '
                    'the exact rows named in the pre-image.',
                    n, p.expect_predecessor_end, p.expect_predecessors;
  END IF;
  -- 6b. 🔴🔴 ALL NINE PREDECESSOR `term_start`s SURVIVED THEIR OWN CLOSURE, AND SEVEN OF THEM ARE
  --     CC_0516's DATE CONTROL. seat_officeholder writes nothing to a closed row's source, so a
  --     moved start would be unrecoverable — and it would silently stop the control reproducing,
  --     with every other number in both files still green. ⚠ This is asserted as "they did not
  --     move", NOT as "they are on a cycle day": two of the nine are vacancy-committee
  --     appointments (2025-10-11 and 2025-07-08) and a cycle-day check would fail honestly on
  --     correct rows. Idaho's lesson, from the predecessor side.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0517_pre r ON r.term_id = t.id
   WHERE t.term_start IS DISTINCT FROM r.term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '6b: % closed predecessor term(s) had their term_start moved. All nine were '
                    'dated before this file and nothing here writes a start to a predecessor; '
                    'seven of those dates are the rows CC_0516''s assertion 3d reads as its in-data '
                    'control.', n;
  END IF;
  -- 6c. 🔴🔴 NO TERM CLOSED ANYWHERE ELSE — AS A DELTA, BECAUSE THE CLOSURE DAY IS SHARED. 193
  --     terms already ended on 2027-01-10 before this file: Oregon's and Washington's seatings
  --     closed their own predecessors there, because it is the day before their start date too.
  --     A TOTAL here would report all 193 as a fault. Two arms: the delta, and the Colorado scope.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_end = p.expect_predecessor_end;
  IF n - b.terms_ending_prev <> p.expect_predecessors THEN
    RAISE EXCEPTION '6c: terms ending on % went % -> %, a delta of %, expected % — one closure per '
                    'seat this file filled. ⚠ That day is SHARED: % term(s) already ended on it '
                    'before this file, because it is the day before Oregon''s and Washington''s '
                    'own start date. This is a delta and never a total.',
                    p.expect_predecessor_end, b.terms_ending_prev, n, n - b.terms_ending_prev,
                    p.expect_predecessors, b.terms_ending_prev;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_end = p.expect_predecessor_end AND lower(d.state) = 'co'
     AND t.id NOT IN (SELECT term_id FROM cc0517_pre);
  IF n <> 0 THEN
    RAISE EXCEPTION '6c: % COLORADO term(s) outside the pre-image also end on %. Colorado had % '
                    'such row(s) before this file, so every one on that day must be a predecessor '
                    'this file named. seat_officeholder closes only the predecessor of the seat it '
                    'fills; something else closed a term.',
                    n, p.expect_predecessor_end, b.terms_ending_prev_co;
  END IF;

  -- 7. Every new term carries the slot, so Ruling B's recovery path works.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0517_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0517%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '7: % of % new term(s) carry CC_0517 in their source. A canvass reversal is '
                    'recovered with source LIKE ''%%CC_0517%%'', not from memory.',
                    n, p.expect_offices;
  END IF;
  -- 7b. 🔴🔴 AND THIS FILE'S ROWS MUST NOT ANSWER TO ANOTHER WAVE'S SLOT QUERY. Ruling B recovers a
  --     wave with `source LIKE '%<slot>%'`, so a sibling slot mentioned anywhere in this column
  --     makes these rows impersonate that wave. Texas's first chain rehearsal aborted exactly that
  --     way, with 12 rows reported as already citing their sibling. A cross-reference belongs in
  --     the header, never in a recovery key.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0517_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND (t.source LIKE '%CC_0516%' OR t.source LIKE '%CC_0518%');
  IF n <> 0 THEN
    RAISE EXCEPTION '7b: % of this wave''s term(s) name ANOTHER migration''s slot in their source. '
                    'Ruling B recovers a wave with source LIKE ''%%<slot>%%'', so these rows would '
                    'be returned as that wave''s. Describe the sibling file in the header instead '
                    'of in the data.', n;
  END IF;

  -- 8. No person and no office was created or destroyed. This wave has no people file.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file — all 18 '
                    'Colorado winners already existed, were active, and collided with nobody on '
                    '(full_name) OR on (first_name, last_name).', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '8: flagged-vacant offices moved from % to %. A FUTURE-dated seating does not '
                    'clear a vacancy flag, and State House District 32 — the one flagged Colorado '
                    'state seat — has no 2026 race and is not in this wave at all.',
                    b.vacant_all, n;
  END IF;

  -- 9. Nobody holds two of this wave's seats from the handover day. ⚠ A ZERO WITH NO FIXTURE: not
  --    one of these nine winners holds any office outside these nine (P8b asserts that absence),
  --    so this gate cannot be reached by a real double-holder in this file. Idaho's position,
  --    recorded as such. The two real Colorado dual holders are both in the sibling group.
  SELECT count(*) INTO n
    FROM (SELECT t.politician_id
            FROM essentials.office_terms t
           WHERE (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
             AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
             AND t.office_id IN (SELECT office_id FROM cc0517_sel)
           GROUP BY t.politician_id HAVING count(*) > 1) x;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % person/people hold more than one of THIS wave''s offices covering %.',
                    n, p.expect_term_start;
  END IF;

  -- 10. 🔴 THE DRIFT BASELINE IS UNMOVED. NEVER RAISE IT.
  SELECT count(*) INTO n
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id
   WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '10: the unflagged drift baseline moved from % to %. 🔴 NEVER RAISE THIS '
                    'BASELINE — this file seats 9 offices that already had terms, so it must not '
                    'move at all.', b.missing_unflagged, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '10: total drift moved from % to %.', b.missing_all, n;
  END IF;

  -- 11. The 91 absent legislative seats were not touched.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER')
     AND (t.term_start = p.expect_term_start OR t.source LIKE '%CC_0517%')
     AND t.office_id NOT IN (SELECT office_id FROM cc0517_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % Colorado legislative term(s) outside this wave now start on % or cite '
                    'this file. Fifty-nine House seats and thirty-two Senate seats have no 2026 '
                    'winner and this file must not have reached any of them.',
                    n, p.expect_term_start;
  END IF;

  RAISE NOTICE 'CC_0517 OK — 9 Colorado legislative seats scheduled for %: % re-elections and % '
               'handovers (Steph Vigil takes House District 16 from Rebecca Keltie, Terri Carver '
               'takes Senate District 9 from Lynda Zamora Wilson), all % called. Predecessors: % '
               'terms closed at % with how_ended term_expired, every one of them previously having '
               'a NULL term_end and a NULL how_ended, so no end date was overwritten. '
               '🔴🔴 ALL NINE PREDECESSORS WERE DATED — unlike Texas''s twelve, which were all '
               'NULL — and SEVEN of those dates (2023-01-09 and 2025-01-08) are the very rows '
               'CC_0516''s assertion 3d reads as its in-data control, so assertion 6b asserts not '
               'one start moved. ⚠ The other two are vacancy-committee appointments, 2025-10-11 '
               'and 2025-07-08, which is why that gate asks whether they MOVED and not whether '
               'they sit on a cycle day: a cycle-day check would fail honestly on two correct '
               'rows. 🔴🔴 THE DAY IS DESIGNATED, NOT COMPUTED — basis `published`, the first in '
               'this pass — and the second-Monday rival gives the same answer in 2027, so nothing '
               'in our own data refuses it; HJR18-1021''s FRIDAY 2019-01-04 does. '
               '🔴🔴 BOTH OF THIS FILE''S SQUARES ARE SHARED AND EACH IS BUSY IN ONE COLUMN ONLY: '
               '% carried % term STARTS before this file (Oregon 75, Washington 118, both under a '
               'rule_id containing "second-monday-january") and 0 ends, while the closure day % '
               'carried % term ENDS and 0 starts. Both are deltas; a total on either would report '
               'the other two states'' correct rows as a fault. 🔴 FIFTY-NINE HOUSE SEATS AND '
               'THIRTY-TWO SENATE SEATS HAVE NO 2026 WINNER, and Art. V § 3(1) put all 65 House '
               'seats on the ballot as a matter of law; Districts 15, 21 and 22 carry a race with '
               'every result blank and are gated by name. The current-holder map is unchanged and '
               'the unflagged drift baseline is still %.',
               p.expect_term_start, p.expect_reelections, p.expect_new, p.expect_called,
               p.expect_predecessors, p.expect_predecessor_end,
               p.expect_term_start, b.terms_on_the_day,
               p.expect_predecessor_end, b.terms_ending_prev,
               b.missing_unflagged;
END $$;

COMMIT;
