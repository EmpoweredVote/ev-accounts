-- CC_0518 — Colorado: seat the 9 executive and board winners of 2026-11-03, from 2027-01-12.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS DOES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Nine seats across three bodies and **three instruments**, all commencing on the same day:
--
--   Governor · Attorney General · Secretary of State · Treasurer      (4)  Colo. Const. Art. IV § 1(1)
--   State Board of Education Districts 1 and 7                        (2)  C.R.S. § 22-2-105(1)
--   University of Colorado Regent, Districts 2, 6 and 7               (3)  C.R.S. § 23-20-105(2)
--
-- **4 re-elections and 5 handovers**, all 9 `called` rather than certified when this ran. The term
-- start is read from `essentials.office_swearing_in`, written by `CC_0516`.
--
-- 🔴 **THE LIEUTENANT GOVERNOR IS DATED AND IS NOT SEATED HERE.** `CC_0516` wrote it a row under
--   the same sentence of Art. IV § 1(1) as the other four executives, because the clause names all
--   five. It is absent from `office_pending_winner` because **its 2026 race carries seven
--   candidates and zero recorded results**. P2b asserts it stayed out of this selection and P5
--   asserts its race still has no winner — if one arrives, this wave is ten seats and not nine.
--
-- The nine legislative winners took office a day earlier, on 2027-01-11, under a designating joint
-- resolution, and were seated by their own file. ⚠ That file's slot is named **here in the header
-- and nowhere in the data**: Ruling B recovers a wave with `source LIKE '%<slot>%'`.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THREE SEATS CHANGE HANDS IN A CHAIN, AND THE CHAIN IS WHY NOBODY ENDS UP HOLDING TWO
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   Jared Polis   → **Phil Weiser**     takes the Governorship
--   Phil Weiser   → **Jena Griswold**   takes the Attorney General's office that Weiser leaves
--   Jena Griswold → **Amanda Gonzalez** takes the Secretary of State's office that Griswold leaves
--
-- **Three links, one day, and all three seats inside this one file.** That is New Mexico's
-- Stephanie Garcia Richard case two links deeper and the longest in this pass.
--
-- 🔴🔴 **SO ASSERTION 9's ZERO IS LOAD-BEARING HERE IN A WAY IT HAS NOT BEEN ANYWHERE ELSE.** In
--   Idaho the zero meant "nobody moved"; in Arizona and Alabama it had an outside fixture. Here it
--   is **produced by the chain closing on itself**: `seat_officeholder` closes the predecessor of
--   the seat it fills, so Weiser's Attorney General term is closed only because Griswold is seated
--   into it, and Griswold's Secretary of State term is closed only because Gonzalez is seated into
--   hers. ▶ **Drop any one of the three seatings and somebody holds two offices from 2027-01-12.**
--   Assertion 9b therefore asserts the chain by NAME — that the Attorney General's predecessor is
--   the Governor's winner, and the Secretary of State's predecessor is the Attorney General's
--   winner — because no count can express a chain, and assertion 9c asserts each of the three ends
--   with exactly one covering term.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ TWO WINNERS WILL STILL HOLD TWO SEATS, AND ONLY ONE OF THEM IS A RESULTS GAP
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   **Jeff Bridges**    takes the Treasurer's office and keeps **State Senate District 26**
--   **Amanda Gonzalez** takes the Secretary of State's office and keeps
--                       **Jefferson County Clerk and Recorder**
--
-- 🔴🔴 **AND THE TWO ARE INDISTINGUISHABLE FROM THE SEAT, WHICH MAKES "A DUAL HOLDER IMPLIES A
--   MISSING RESULT" FALSE.** Senate District 26 is **genuinely not up in 2026** — Colorado senators
--   serve four years (Art. V § 3(1)) and that seat was last elected in 2024 — so the absence of a
--   successor is **correct**, and nothing is missing. Jefferson County Clerk and Recorder carries
--   **no 2026 race in our data at all**, and county clerks do serve four-year terms from a 2023
--   start, so that one **is** a results gap in the county tier. Texas's five dual holders were all
--   results gaps of the same kind; Colorado has **one of each**, and the only way to tell them
--   apart is to read the body's term length. ▶ Assertion 9d asserts both kept terms are still
--   **open** rather than tidying either.
--
-- ⚠ **NEITHER IS CLOSED HERE.** Colo. Const. Art. V § 8 ("No senator or representative shall, while
--   serving as such, be appointed to any civil office under this state") bears on Bridges's
--   position, and so does Art. XII § 11. **This file takes no view**: the office he takes is
--   elective rather than appointive, we hold no resignation and no effective date for one, and a
--   `term_end` is a legal fact. An unsourced closure is what this pass refuses.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE CLOSURE DAY IS 2027-01-11 — WHICH IS THE OTHER GROUP'S START DAY AND 193 STRANGERS'
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor at `p_term_start - 1`, which is **2027-01-11**. That
-- day is:
--
--   • **this wave's sibling group's own start date** (9 Colorado legislative terms), and
--   • **Oregon's 75 and Washington's 118 legislative start dates** (193 more),
--   • and it carries **0 term ENDS** before this file.
--
-- Meanwhile this file's **start** day, 2027-01-12, carries **0 term starts** and **178 term ENDS**
-- — Maryland's, because 2027-01-12 is the day before the Maryland General Assembly's 2027-01-13.
--
-- 🔴🔴🔴 **SO EACH OF THIS FILE'S TWO DAYS IS BUSY IN THE COLUMN NOBODY CHECKS AND EMPTY IN THE
--   COLUMN EVERYBODY CHECKS, AND THE TWO MISTAKES ARE ONE COLUMN APART.** A `term_start` gate on
--   2027-01-12 reads 0 and discriminates nothing; a `term_end` gate on the same day reads 178 and
--   looks like an invasion. A `term_end` gate on 2027-01-11 reads 0 and discriminates nothing; a
--   `term_start` gate on the same day reads 202 and looks like one. Every count in this file names
--   its column and is a delta, and the before-image pins **all four** cells.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 ONE PREDECESSOR IS DATED, AND IT IS THE ONLY IN-DATA CONTROL ART. IV § 1(1) HAS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Eight of the nine predecessor terms carry `term_start IS NULL`. The ninth is **Jared Polis's
-- Governorship, starting 2019-01-08** — which is the second Tuesday of January 2019 and is
-- `CC_0516`'s assertion 3e, **the only dated Colorado state executive term in the database**.
-- `seat_officeholder` writes **nothing to a closed row's `source`**, so if that `term_start` moved
-- there would be no record of what it held and the clause would lose its corroboration silently.
-- Assertion 6b asserts it survived its own closure — Texas's `CC_0515` did the same for Greg
-- Abbott's 2015-01-20, and it is the same shape: **the row this wave closes is the row that
-- justifies the day it closes it on.**
--
-- ⚠ **AND NEITHER BOARD HAS ANY IN-DATA CONTROL AT ALL.** All 8 Regent and all 8 State Board of
--   Education term rows carry `term_start NULL`, written by `CC_0366` from the bodies' own rosters
--   with `how_started = 'unknown'`. Their day rests on documentary evidence only: five statutory
--   anchors for the Board of Education, and for the Regents a 1973 transitional provision that is
--   the weakest citation in the state. Asserted at 6d rather than left unsaid.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 ONE CERTAIN RESULTS GAP, NAMED AND NOT TIDIED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **State Board of Education District 3 was on the 2026 ballot and we hold no race row of any
-- year.** Three independent instruments say so: § 22-2-105(1)'s own arithmetic (the 1984 election
-- put Districts 1 and 3 on six-year terms commencing the second Tuesday in January 1985, and
-- 1985 + 6n reaches 2027); Colo. Const. Art. XII § 11 (an officer "elected to fill a vacancy" serves
-- only to "the expiration of the term during which the vacancy occurred", and Sherri Wright was
-- elected in November 2024 to the remainder of Stephen Varela's term); and the Colorado Department
-- of Education's own news release of 8 January 2025, which states that her "term of office runs
-- through January 2027". ▶ So the Board's 2026 cohort is **three** seats and this file seats
-- **two**, and **Sherri Wright will be left holding District 3 on our pages past the expiry of her
-- own term** — New Mexico's Public Education Commission District 7 shape. **The fix is the result,
-- not a closure here.** P5 gates on that seat having no race row **by name**.
--
-- 🟢 **THE REGENTS, BY CONTRAST, HAVE NO GAP.** § 23-20-102(2) partitions the nine seats into three
--   cohorts of three and 2002 + 6n reaches 2020, so Districts 2, 6 and 7 ran 2021–2027 and were up
--   in 2026; the body's own roster prints a "Current Term" range for every member and **all nine
--   agree with the statute**. Three of nine are pending and they are exactly those three.
--
-- 🔴 **This file OVERWRITES ONE VALUE PER SEAT: the predecessor's `term_end`, which was NULL on all
--   nine**, and sets `how_ended = 'term_expired'`. `seat_officeholder` does that with an
--   **unguarded** `UPDATE` and records nothing in the closed row's own `source`, so the pre-image
--   captured in `cc0518_pre` is the only record of what those rows held. All nine had
--   `term_end IS NULL` and `how_ended IS NULL` (P6 asserts both before writing).

-- @incumbency-decision: gated — this file opens 9 Colorado terms on 2027-01-12 and closes each
--   predecessor's own term at 2027-01-11, so it restates who held those nine seats on every
--   election day the closed terms no longer cover. 🔴 FIVE OF THE NINE ARE HANDOVERS and three of
--   those form a CHAIN in which each person's old term is closed by the next link's seating, so
--   three people appear on both sides of the guard at once: a newcomer whose race row still says
--   `is_incumbent = true`, or a departing officer whose row stops agreeing, is exactly the
--   contradiction `check:incumbency` would report on the NEXT merge under somebody else's name.
-- 🔴 THE GUARD'S SCOPE IS A UNION OF WINNERS AND PREDECESSORS, and here the union is genuinely
--    larger than either side — Weiser and Griswold are each a winner AND a predecessor, on
--    DIFFERENT seats, which is the case no per-office count can see.

BEGIN;

CREATE TEMP TABLE cc0518_pin ON COMMIT DROP AS
SELECT 9                                  AS expect_winners,
       9                                  AS expect_offices,
       4                                  AS expect_reelections,
       5                                  AS expect_new,
       9                                  AS expect_predecessors,
       1                                  AS expect_predecessors_dated,
       2                                  AS expect_dual_seat,
       9                                  AS expect_called,
       0                                  AS expect_terms_on_the_day_before,
       0                                  AS expect_terms_ending_prev_before,
       202                                AS expect_terms_starting_prev_before,
       178                                AS expect_terms_ending_on_the_day_before,
       '3fcba16c3e87f4f4d977e966936ed1af' AS expect_digest,
       DATE '2027-01-12'                  AS expect_term_start,
       DATE '2027-01-11'                  AS expect_predecessor_end,
       DATE '2019-01-08'                  AS expect_polis_start;

-- 🟢 NO SIBLING EXPANSION: every race is single-seat with one winner, so each winner is keyed on
--    the office that carried their own race and Ruling A is not engaged. ⚠ BOTH BOARDS ARE
--    STAGGERED — six of nine Regents and seven of nine Board of Education members are not leaving —
--    which is exactly the shape Ruling A REFUSES to assign, so taking the selection from
--    office_pending_winner rather than by title is load-bearing here.
-- 🔴 `is_reelection` TAKES BOTH ID CHECKS, or the expression is NULL on a holderless seat and
--    string_agg silently drops it from the digest. All nine are held; P3 measures it anyway.
CREATE TEMP TABLE cc0518_sel ON COMMIT DROP AS
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
   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD', 'STATE_BOARD_EDUCATION')
   AND w.election_date = DATE '2026-11-03';

-- 🔴 THE PREDECESSOR PRE-IMAGE. ⚠ EXACTLY ONE OF THESE NINE IS DATED — Jared Polis's 2019-01-08 —
--    and that row is CC_0516's assertion 3e, the only in-data corroboration Art. IV § 1(1) has in
--    this state. seat_officeholder writes nothing to a closed row's source, so this is the only
--    record of what these rows held.
CREATE TEMP TABLE cc0518_pre ON COMMIT DROP AS
SELECT s.office_id, s.label, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended
  FROM cc0518_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

-- 🔴🔴 THE TWO WINNERS WHO KEEP ANOTHER SEAT, captured by name so P8b and assertion 9d can speak
--    about them rather than about a count. Scoped to offices OUTSIDE this wave, which is what makes
--    the three-link chain disappear from this table: Weiser's Attorney General seat and Griswold's
--    Secretary of State seat are both INSIDE the wave and are closed by the next link's seating.
CREATE TEMP TABLE cc0518_dual ON COMMIT DROP AS
SELECT s.winner_name, s.label AS takes, t.id AS kept_term_id, t.office_id AS kept_office_id,
       d2.label AS keeps, d2.district_type AS keeps_type, t.term_start AS kept_start
  FROM cc0518_sel s
  JOIN essentials.office_terms t ON t.politician_id = s.politician_id
                                AND t.office_id <> s.office_id
  JOIN essentials.offices   o2 ON o2.id = t.office_id
  JOIN essentials.districts d2 ON d2.id = o2.district_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start)
   AND t.office_id NOT IN (SELECT office_id FROM cc0518_sel);

CREATE TEMP TABLE cc0518_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                               AS terms_all,
       -- ⚠ EMPTY. Colorado is the first state on this day, so a "no strangers" gate here
       --    discriminates nothing and this file says so rather than offering it as a measurement.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-12')
                                                                                    AS terms_on_the_day,
       -- 🔴🔴 AND THE SAME DAY CARRIES 178 TERM ENDS — Maryland's, because 2027-01-12 is the day
       --    before the Maryland General Assembly's 2027-01-13. The day is empty in one column and
       --    busy in the other, and the two mistakes are one column apart.
       (SELECT count(*) FROM essentials.office_terms WHERE term_end = DATE '2027-01-12')
                                                                                    AS terms_ending_on_the_day,
       -- 🔴🔴 THE CLOSURE DAY IS THE SIBLING GROUP'S START DAY. 0 terms END on 2027-01-11, and 202
       --    START there once CC_0517 has run (Oregon 75 + Washington 118 + Colorado's own 9).
       (SELECT count(*) FROM essentials.office_terms WHERE term_end = DATE '2027-01-11')
                                                                                    AS terms_ending_prev,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-11')
                                                                                    AS terms_starting_prev,
       (SELECT count(*) FROM essentials.office_terms t
          JOIN essentials.offices o   ON o.id = t.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE t.term_end = DATE '2027-01-11' AND lower(d.state) = 'co')            AS terms_ending_prev_co,
       -- The near misses, AS TERMS.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-13')
                                                                                    AS terms_jan13,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                    AS terms_jan4,
       (SELECT count(*) FROM essentials.politicians)                                AS politicians,
       (SELECT count(*) FROM essentials.offices)                                    AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                    AS vacant_all,
       (SELECT count(*) FROM cc0518_pre)                                            AS predecessors,
       (SELECT count(*) FROM cc0518_dual)                                           AS dual_seat,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                                AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                    AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices_missing_terms)                      AS missing_all;

DO $$
DECLARE n bigint; d text; p record; b record; gov uuid; ag uuid; sos uuid;
BEGIN
  SELECT * INTO p FROM cc0518_pin;
  SELECT * INTO b FROM cc0518_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0518%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0518. Applied before.', n;
  END IF;

  -- P2 — 🔴 THE SIBLING FILE MUST HAVE RUN. This file's closure day is CC_0517's START day, and its
  --      before-image pins that square at 202 — Oregon 75, Washington 118 and Colorado's own 9. Run
  --      alone against production it would read 193 and every delta below would be measured against
  --      a state that never existed.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0517%';
  IF n <> 9 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) cite CC_0517, expected 9. That file seats Colorado''s '
                    'nine legislative winners on %, which is THIS file''s closure day, and this '
                    'file''s before-image expects % term starts there. Apply CC_0517 first.',
                    n, p.expect_predecessor_end, p.expect_terms_starting_prev_before;
  END IF;

  -- P2b — the shape of the selection.
  SELECT count(*) INTO n FROM cc0518_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2b: selection returned % winner rows, expected 9 — 4 executives, 2 State Board '
                    'of Education seats and 3 Regent seats.', n;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0518_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2b: % distinct offices, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0518_sel WHERE winner_count <> 1 OR COALESCE(seats, 1) <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2b: % of the 9 races are not single-seat with exactly one winner. 🔴 THIS '
                    'SELECTION KEYS EVERY WINNER ON THE RACE-CARRYING OFFICE, so a Ruling A '
                    'assignment to a sibling office would leave post-verify 1 unable to find the '
                    'term — after it had been written. ⚠ Both boards are staggered, which is the '
                    'shape Ruling A refuses outright.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0518_sel WHERE district_type = 'STATE_EXEC';
  IF n <> 4 THEN
    RAISE EXCEPTION 'P2b: % executive seat(s) in the selection, expected 4 — Governor, Attorney '
                    'General, Secretary of State and Treasurer. Art. IV § 1(1) names FIVE officers; '
                    'the Lieutenant Governor is the fifth and is dated by CC_0516 and seated by '
                    'nobody.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0518_sel WHERE district_type = 'STATE_BOARD_EDUCATION';
  IF n <> 2 THEN
    RAISE EXCEPTION 'P2b: % State Board of Education seat(s), expected 2 (Districts 1 and 7). '
                    '§ 22-2-105(1) puts THREE on this boundary; District 3 has no race row at all.',
                    n;
  END IF;
  SELECT count(*) INTO n FROM cc0518_sel WHERE district_type = 'STATE_BOARD';
  IF n <> 3 THEN
    RAISE EXCEPTION 'P2b: % Regent seat(s), expected 3 (Districts 2, 6 and 7).', n;
  END IF;
  -- 🔴 No legislative office may reach this selection: they took office a DAY EARLIER, and the two
  --    days are each other's near miss.
  SELECT count(*) INTO n FROM cc0518_sel WHERE district_type IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2b: % legislative office(s) reached this selection. They commence on the '
                    'DESIGNATED CONVENING DAY 2027-01-11 under Art. V § 7 with HJR26-1031 and were '
                    'seated by CC_0517; these nine commence on the SECOND TUESDAY. The two days are '
                    'ONE APART.', n;
  END IF;
  -- 🔴🔴 AND THE LIEUTENANT GOVERNOR MUST NOT BE HERE. It carries a swearing-in row for this very
  --    day, so a selection built from office_swearing_in rather than office_pending_winner would
  --    sweep it in and seat somebody we hold no winner for.
  SELECT count(*) INTO n FROM cc0518_sel WHERE title = 'Lieutenant Governor';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2b: the Lieutenant Governor reached this selection. It is DATED by CC_0516 for '
                    'this same day under the same sentence of Art. IV § 1(1), and it has NO '
                    'RECORDED WINNER — seven candidates, every result blank. Seating it would '
                    'invent an officeholder.';
  END IF;

  -- P3 — 🔴🔴 THE DIGEST, AND THE COUNT OF ROWS IT ACTUALLY EVALUATED.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text) INTO n
    FROM cc0518_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % row(s), so string_agg '
                    'silently dropped them. Add och.politician_id IS NOT NULL to is_reelection.',
                    p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text)) INTO d
    FROM cc0518_sel;
  IF d <> p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'MEMBERSHIP moved without the size moving. Re-derive before applying.',
                    d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0518_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected % — Lisa Escárcega (Board District 1), Karla Esser '
                    '(Board District 7), Ilana Spiegel (Regent District 6) and Nolbert Chavez '
                    '(Regent District 7). NOT ONE EXECUTIVE IS RE-ELECTED.', n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0518_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P3: % handovers, expected % — all four executives plus Regent District 2.',
                    n, p.expect_new;
  END IF;
  SELECT count(*) INTO n FROM cc0518_sel WHERE certainty = 'called';
  IF n <> p.expect_called THEN
    RAISE EXCEPTION 'P3: % of the 9 are `called`, expected % — Ruling B seats from a called result '
                    'and records which it was.', n, p.expect_called;
  END IF;
  -- 🔴 THE PIN NAMES THE PEOPLE, NOT ONLY THE COUNTS.
  SELECT count(*) INTO n
    FROM cc0518_sel s
   WHERE (s.label, s.winner_name) IN (
     VALUES ('Colorado Governor',                                    'Phil Weiser'),
            ('Colorado Attorney General',                            'Jena Griswold'),
            ('Colorado Secretary of State',                          'Amanda Gonzalez'),
            ('Colorado Treasurer',                                   'Jeff Bridges'),
            ('Colorado State Board of Education District 1',         'Lisa Escárcega'),
            ('Colorado State Board of Education District 7',         'Karla Esser'),
            ('University of Colorado Board of Regents District 2',   'Edie Hooton'),
            ('University of Colorado Board of Regents District 6',   'Ilana Spiegel'),
            ('University of Colorado Board of Regents District 7',   'Nolbert Chavez'));
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: only % of the 9 (office, winner) pairs match the names this file was '
                    'written against, expected %. ⚠ The Regents'' own roster writes District 6 as '
                    '"Ilana Dubin Spiegel" where our politicians row says "Ilana Spiegel"; this '
                    'gate uses the RACE''s spelling, which is what office_pending_winner returns, '
                    'and the identity is anchored on the SEAT.', n, p.expect_winners;
  END IF;

  -- P4 — every seat carries CC_0516's date, a basis that may seat somebody, and ITS OWN BODY's
  --      rule_id. 🔴 THREE INSTRUMENTS REACH ONE DAY HERE, and Connecticut's warning is that a
  --      later reader must not merge clauses that merely agree.
  SELECT count(*) INTO n FROM cc0518_sel WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 9 seats have no swearing-in date, or one that is not %. CC_0516 '
                    'must be applied first.', n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0518_sel WHERE basis NOT IN ('statute', 'published');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % date(s) have a basis that is neither statute nor published. AN ESTIMATE '
                    'MAY NOT SEAT ANYBODY — a term start is a legal fact.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0518_sel WHERE basis <> 'statute';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 9 seats are not dated with basis `statute`. These three bodies are '
                    'dated by a constitutional clause and two statutes; it is the LEGISLATURE whose '
                    'basis is `published`, because its day comes from a designating resolution.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0518_sel
   WHERE rule_id <> CASE district_type
                      WHEN 'STATE_EXEC'            THEN 'co-const-art4-s1-second-tuesday-january'
                      WHEN 'STATE_BOARD_EDUCATION' THEN 'co-crs-22-2-105-second-tuesday-january'
                      WHEN 'STATE_BOARD'           THEN 'co-crs-23-20-105-second-tuesday-january'
                    END;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 9 seats carry a rule_id that is not their own body''s. THREE '
                    'INSTRUMENTS REACH THIS ONE DAY — Colo. Const. Art. IV § 1(1) for the '
                    'executives, C.R.S. § 22-2-105(1) for the Board of Education, and C.R.S. '
                    '§ 23-20-105(2) for the Regents — and they are kept apart precisely so a later '
                    'reader cannot merge them. ⚠ The Regents'' is a 1973 TRANSITIONAL provision and '
                    'is the weakest citation in this state; borrowing it for another body, or '
                    'borrowing another body''s for the Regents, would hide that.', n;
  END IF;

  -- P5 — the results gaps, asked before writing, and the certain one named.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_BOARD_EDUCATION'
     AND d.label = 'Colorado State Board of Education District 3'
     AND EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: State Board of Education District 3 now carries % race row(s), expected 0 '
                    'of any year. Three instruments put that seat on the 2026 ballot — '
                    '§ 22-2-105(1)''s 1985 + 6n arithmetic, Art. XII § 11''s vacancy rule, and the '
                    'Department''s own release stating Sherri Wright''s term "runs through January '
                    '2027" — so if its result has arrived the Board''s cohort of THREE is complete '
                    'and this wave is larger than nine.', n;
  END IF;
  -- 🔴🔴 AND THE LIEUTENANT GOVERNOR'S RACE STILL HAS NO WINNER.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND o.title = 'Lieutenant Governor' AND rc.result = 'won';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: the Colorado Lieutenant Governor''s 2026 race now records % winner(s), '
                    'expected 0. CC_0516 dated that office under the same sentence of Art. IV '
                    '§ 1(1) as these four and left it unseated BECAUSE the result was missing. If '
                    'it has arrived, this wave is ten seats and the pin is stale.', n;
  END IF;

  -- P6 — the vacancy flags and the predecessor pre-image.
  SELECT count(*) INTO n
    FROM cc0518_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of the 9 offices are flagged is_vacant. A FUTURE-dated seating does not '
                    'clear the flag, so a flagged seat needs its own handover-day file.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0518_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) captured, expected % — one per seat.',
                    n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0518_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a term_end. seat_officeholder''s UPDATE '
                    'has NO term_end IS NULL guard, so it would overwrite a real end date and record '
                    'nothing of what it replaced.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0518_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a how_ended.', n;
  END IF;
  -- 🔴🔴 EXACTLY ONE PREDECESSOR IS DATED AND IT IS THE CONTROL FOR THIS FILE'S OWN RULE.
  SELECT count(*) INTO n FROM cc0518_pre WHERE term_start IS NOT NULL;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) carry a term_start, expected % — Jared Polis''s '
                    'Governorship from %, which is the second Tuesday of January 2019 and the ONLY '
                    'dated Colorado state executive term in the database. That row IS CC_0516''s '
                    'assertion 3e, so the row this file closes is the row that justifies the day it '
                    'closes it on.', n, p.expect_predecessors_dated, p.expect_polis_start;
  END IF;
  SELECT count(*) INTO n
    FROM cc0518_pre WHERE term_start = p.expect_polis_start;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P6: the predecessor dated % is not in the pre-image (% row(s)). Art. IV '
                    '§ 1(1)''s only in-data corroboration must be one of the rows this file closes, '
                    'or the pin was captured against different data.', p.expect_polis_start, n;
  END IF;
  -- The four re-elections must have the winner as their own predecessor; the five handovers must not.
  SELECT count(*) INTO n
    FROM cc0518_sel s JOIN cc0518_pre r ON r.office_id = s.office_id
   WHERE s.is_reelection AND r.politician_id IS DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % re-elected winner(s) are not the predecessor on their own seat.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0518_sel s JOIN cc0518_pre r ON r.office_id = s.office_id
   WHERE NOT s.is_reelection AND r.politician_id = s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % handover(s) have the winner as their own predecessor, which makes them '
                    're-elections the selection failed to recognise.', n;
  END IF;

  -- P7 — 🔴🔴 THE CHAIN, ASSERTED BY NAME BEFORE ANYTHING IS WRITTEN. No count can express a chain,
  --      and this one is why assertion 9's zero holds: each person's old term is closed only
  --      because the next link is seated into it.
  SELECT s.politician_id INTO gov FROM cc0518_sel s WHERE s.label = 'Colorado Governor';
  SELECT s.politician_id INTO ag  FROM cc0518_sel s WHERE s.label = 'Colorado Attorney General';
  SELECT s.politician_id INTO sos FROM cc0518_sel s WHERE s.label = 'Colorado Secretary of State';
  IF gov IS NULL OR ag IS NULL OR sos IS NULL THEN
    RAISE EXCEPTION 'P7: one of the three chained offices is missing from the selection (Governor %, '
                    'Attorney General %, Secretary of State %).', gov, ag, sos;
  END IF;
  SELECT count(*) INTO n
    FROM cc0518_pre r
   WHERE r.label = 'Colorado Attorney General' AND r.politician_id = gov;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: the Attorney General''s predecessor is not the Governor''s winner. The '
                    'chain this file depends on is Polis -> Weiser (Governor), Weiser -> Griswold '
                    '(Attorney General), Griswold -> Gonzalez (Secretary of State). If that first '
                    'link is broken, Phil Weiser holds two offices from %.', p.expect_term_start;
  END IF;
  SELECT count(*) INTO n
    FROM cc0518_pre r
   WHERE r.label = 'Colorado Secretary of State' AND r.politician_id = ag;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: the Secretary of State''s predecessor is not the Attorney General''s '
                    'winner. If that link is broken, Jena Griswold holds two offices from %.',
                    p.expect_term_start;
  END IF;

  -- P8 — the squares this file's deltas are measured against. ALL FOUR CELLS.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P8: % already carries % term(s), expected % — Colorado is the FIRST state on '
                    'that day, which is why no "no strangers here" gate on it discriminates '
                    'anything and this file does not offer one as a measurement.',
                    p.expect_term_start, b.terms_on_the_day, p.expect_terms_on_the_day_before;
  END IF;
  IF b.terms_ending_on_the_day <> p.expect_terms_ending_on_the_day_before THEN
    RAISE EXCEPTION 'P8: % carries % term END(s), expected % — Maryland''s, because that day is the '
                    'day before the Maryland General Assembly''s 2027-01-13. 🔴🔴 THE SAME DAY IS '
                    'EMPTY OF STARTS AND BUSY WITH ENDS, so a gate that reads the wrong column '
                    'there sees an invasion where there is none.',
                    p.expect_term_start, b.terms_ending_on_the_day,
                    p.expect_terms_ending_on_the_day_before;
  END IF;
  IF b.terms_ending_prev <> p.expect_terms_ending_prev_before THEN
    RAISE EXCEPTION 'P8: % already carries % term END(s), expected %. That is this file''s closure '
                    'day and it is EMPTY in that column.',
                    p.expect_predecessor_end, b.terms_ending_prev,
                    p.expect_terms_ending_prev_before;
  END IF;
  IF b.terms_starting_prev <> p.expect_terms_starting_prev_before THEN
    RAISE EXCEPTION 'P8: % carries % term START(s), expected % — Oregon 75, Washington 118 and '
                    'Colorado''s own 9 from CC_0517. 🔴🔴 THIS FILE''S CLOSURE DAY IS THE SIBLING '
                    'GROUP''S START DAY AND 193 STRANGERS'' START DAY, and it carries no ends at '
                    'all: the two mistakes are one column apart.',
                    p.expect_predecessor_end, b.terms_starting_prev,
                    p.expect_terms_starting_prev_before;
  END IF;
  IF b.terms_ending_prev_co <> 0 THEN
    RAISE EXCEPTION 'P8: % Colorado term(s) already end on %, expected 0. Every row on that day from '
                    'this state must be a predecessor this file named.',
                    b.terms_ending_prev_co, p.expect_predecessor_end;
  END IF;

  -- P8b — 🔴🔴 THE TWO DUAL-SEAT WINNERS, BY NAME AND BY KIND. The count alone cannot tell a
  --       results gap from a seat that is correctly not up, and Colorado has one of each.
  IF b.dual_seat <> p.expect_dual_seat THEN
    RAISE EXCEPTION 'P8b: % winner(s) of this wave hold an office outside it, expected % — Jeff '
                    'Bridges keeps State Senate District 26 and Amanda Gonzalez keeps Jefferson '
                    'County Clerk and Recorder.', b.dual_seat, p.expect_dual_seat;
  END IF;
  SELECT count(*) INTO n
    FROM cc0518_dual
   WHERE (winner_name, keeps) IN (
     VALUES ('Jeff Bridges',    'State Senate District 26'),
            ('Amanda Gonzalez', 'Jefferson County'));
  IF n <> p.expect_dual_seat THEN
    RAISE EXCEPTION 'P8b: only % of the % dual-seat pairs are the ones this file was written '
                    'against. ⚠ ONLY ONE OF THEM IS A RESULTS GAP: Senate District 26 is genuinely '
                    'not up in 2026 (four-year terms, last elected 2024) so it correctly has no '
                    'successor, while Jefferson County Clerk and Recorder carries no 2026 race in '
                    'our data and is a county-tier gap. They are indistinguishable from the seat, '
                    'so "a dual holder implies a missing result" is false and the pair is pinned by '
                    'name rather than by count.', n, p.expect_dual_seat;
  END IF;
END $$;

CREATE TEMP TABLE cc0518_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0518_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0518_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0518_guarded);

DO $$
DECLARE s record; v_seated int := 0;
BEGIN
  FOR s IN SELECT * FROM cc0518_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => s.office_id,
      p_politician_id    => s.politician_id,
      p_term_start       => s.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(s.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in: '
                         || CASE s.district_type
                              WHEN 'STATE_EXEC' THEN
                                'Colo. Const. Art. IV § 1(1), "The executive department shall '
                                || 'include the governor, lieutenant governor, secretary of state, '
                                || 'state treasurer, and attorney general, each of whom shall hold '
                                || 'his office for the term of four years, COMMENCING ON THE SECOND '
                                || 'TUESDAY OF JANUARY IN THE YEAR 1967, AND EACH FOURTH YEAR '
                                || 'THEREAFTER." An anchor-year rule: 1967 + 4n reaches 2027 and '
                                || 'the second Tuesday of January 2027 is 2027-01-12. The clause '
                                || 'carries NO escape hatch — the sentence ends at "each fourth '
                                || 'year thereafter" — and its tail (§ 1(2)) is a TERM LIMIT, not a '
                                || 'residual, which is verbatim Md. Const. Art. II § 1''s shape. '
                                || 'The ONE dated Colorado state executive term in the database, '
                                || 'Jared Polis''s 2019-01-08, is the second Tuesday of January '
                                || '2019 and reproduces it exactly. ⚠ Art. IV § 1(1) names FIVE '
                                || 'officers; the Lieutenant Governor is dated under this same '
                                || 'clause and is NOT seated, because its 2026 race carries seven '
                                || 'candidates and no recorded result. '
                              WHEN 'STATE_BOARD_EDUCATION' THEN
                                'C.R.S. § 22-2-105(1), which Colo. Const. Art. IX § 1(1) leaves the '
                                || 'terms to ("in such manner and for such terms as may be by law '
                                || 'prescribed") and which anchors every cohort on the same '
                                || 'weekday-of-month: terms commencing on the SECOND TUESDAY IN '
                                || 'JANUARY of 1983, 1985, 1987, 2003 and 2023, with six-year terms '
                                || 'thereafter under § 22-2-105(3). Five independent anchors, the '
                                || 'most recent from 2023. 🔴 DATES.md cites this as § 22-2-104(1), '
                                || 'which is "Offices and positions - nature" and contains no date '
                                || 'of any kind; the quote was right and the section number was '
                                || 'not. ⚠ THE 2026 COHORT IS THREE SEATS AND ONLY TWO ARE SEATED: '
                                || '1985 + 6n reaches 2027 for Districts 1 AND 3, and District 3 '
                                || 'has no race row of any year — proved three ways, including the '
                                || 'Department''s own statement that Sherri Wright''s term "runs '
                                || 'through January 2027". The fix is the result, not a closure. '
                              ELSE
                                'C.R.S. § 23-20-105(2). ⚠ THIS IS THE WEAKEST CITATION IN COLORADO '
                                || 'AND IT IS FLAGGED RATHER THAN SMOOTHED OVER: Colo. Const. '
                                || 'Art. IX § 12 gives "nine regents … elected in the manner '
                                || 'prescribed by law FOR TERMS OF SIX YEARS EACH" — a length, not '
                                || 'a commencement — and § 23-20-102 prescribes the manner and the '
                                || 'cycle and names no commencement at all. The only commencement '
                                || 'evidence is a 1973 TRANSITIONAL provision fixing three '
                                || 'appointed terms as "EXPIRING ON THE SECOND TUESDAY IN JANUARY, '
                                || '1975 … 1977 … 1979". Transitional text is what made Utah''s '
                                || 'Board of Education a refusal; the difference is that Utah''s '
                                || 'pointed at a DIFFERENT boundary from the legislature''s while '
                                || 'Colorado''s point at the SAME boundary as the executives and '
                                || 'the Board of Education, so they corroborate rather than '
                                || 'contradict. A sweep of all 29 constitutional articles found no '
                                || 'general commencement clause to repair it. 🟢 The body''s own '
                                || 'roster reconciles with § 23-20-102(2)''s three cohorts on ALL '
                                || 'NINE seats, and 2002 + 6n puts Districts 2, 6 and 7 on this '
                                || 'ballot, so this body has NO results gap. '
                            END
                         || '🟢 THE OATH IS NOT THIS DATE: Colo. Const. Art. XII § 8 requires every '
                         || 'civil officer to swear "BEFORE he enters upon the duties of his '
                         || 'office", and C.R.S. § 24-12-101 requires the oath taken, signed, '
                         || 'administered and filed "before the person enters upon the public '
                         || 'office or position", so it is a precondition to the term rather than '
                         || 'its start. '
                         || CASE WHEN s.is_reelection
                                 THEN 'RE-ELECTED INCUMBENT: the predecessor on this seat is the '
                                   || 'winner, and their own term is closed at '
                                   || to_char(s.term_start - 1, 'YYYY-MM-DD') || '. '
                                 ELSE 'HANDOVER: this seat changes hands. Five of this wave''s nine '
                                   || 'do, and the predecessor''s term is closed at '
                                   || to_char(s.term_start - 1, 'YYYY-MM-DD') || '. '
                            END
                         || '🔴 THREE OF THE FIVE HANDOVERS FORM A CHAIN: Phil Weiser leaves the '
                         || 'Attorney General''s office for the Governorship, Jena Griswold leaves '
                         || 'the Secretary of State''s office for his, and Amanda Gonzalez takes '
                         || 'hers. All three seats are in this file, and because seat_officeholder '
                         || 'closes only the predecessor of the seat it fills, each leaver''s old '
                         || 'term is closed ONLY because the next link is seated — drop any one '
                         || 'seating and somebody holds two offices from '
                         || to_char(s.term_start, 'YYYY-MM-DD') || '. '
                         || '⚠ THE CLOSURE DAY IS THE OTHER GROUP''S START DAY: 202 terms begin on '
                         || to_char(s.term_start - 1, 'YYYY-MM-DD')
                         || ' (Oregon 75, Washington 118 and Colorado''s own 9 legislative seats) '
                         || 'and none ended there before this file, so every count about it names '
                         || 'its column. CC_0518',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => s.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0518: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0518_guarded;
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
DECLARE n bigint; m text; b record; p record; gov uuid; ag uuid; sos uuid;
BEGIN
  SELECT * INTO b FROM cc0518_before;
  SELECT * INTO p FROM cc0518_pin;

  -- 1. Nine terms exist, on the offices this file selected, for the people it selected.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0518_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated term(s) on %, expected %.', n, p.expect_term_start,
                    p.expect_offices;
  END IF;

  -- 2. The read path answers for all nine.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0518_sel s ON s.office_id = nx.office_id
   WHERE nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seat(s).', n, p.expect_offices;
  END IF;
  -- 2b. 🔴 AND THE LIEUTENANT GOVERNOR DOES NOT. It carries a swearing-in row for this same day and
  --     must carry no term at all — office_next_term reads office_terms, so a date alone cannot put
  --     it there, and this asserts that nothing else did.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx
    JOIN essentials.offices o   ON o.id = nx.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND o.title = 'Lieutenant Governor';
  IF n <> 0 THEN
    RAISE EXCEPTION '2b: office_next_term answers for the Colorado Lieutenant Governor (% row(s)), '
                    'expected 0. It is DATED by CC_0516 and seated by nobody, because its 2026 race '
                    'has seven candidates and no recorded result.', n;
  END IF;

  -- 3. 🔴 THE DELTA ON THIS FILE'S OWN DAY. ⚠ AN EMPTY DAY DISCRIMINATES NOTHING: Colorado is the
  --    first state on 2027-01-12, so this is a count of this file's own rows and is not offered as
  --    a "no strangers" measurement.
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
   WHERE t.term_start = p.expect_term_start AND lower(d.state) <> 'co';
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to another state. Colorado is the first state on that '
                    'day, so any stranger is a second state arriving — but note that an empty '
                    'square cannot discriminate, so this gate only becomes a measurement once '
                    'somebody else is there.', n, p.expect_term_start;
  END IF;
  -- 3b. No Colorado term on this day outside this wave's nine offices. 🔴 THE LIEUTENANT GOVERNOR
  --     IS THE ROW THIS WOULD CATCH, and both boards' staggered siblings are the others.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(d.state) = 'co'
     AND t.office_id NOT IN (SELECT office_id FROM cc0518_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % Colorado term(s) begin on % outside this wave''s nine offices. The most '
                    'likely rows are the LIEUTENANT GOVERNOR, which is dated for this day and has '
                    'no winner, or a staggered sibling on either board — six of nine Regents and '
                    'seven of nine Board of Education members are not leaving.',
                    n, p.expect_term_start;
  END IF;
  -- 3c. 🔴 And none of the nine landed on a wrong day. ⚠ THE FIRST ENTRY IS THE SIBLING GROUP'S OWN
  --     DAY, one day earlier.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0518_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-11', DATE '2027-01-13', DATE '2027-01-04');
  IF n <> 0 THEN
    RAISE EXCEPTION '3c: % of this wave''s term(s) start on a wrong day — the sibling group''s '
                    '2027-01-11 (202 terms), the legislature''s statutory default 2027-01-13 (178 '
                    'terms: the Maryland General Assembly) or the first Monday 2027-01-04 (229 '
                    'terms: Wisconsin, Arizona, California, Idaho).', n;
  END IF;
  -- 3d. The near-miss days and the sibling's day did not move.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-11';
  IF n <> b.terms_starting_prev THEN
    RAISE EXCEPTION '3d: 2027-01-11 went % -> %, expected no change from this file. That is the '
                    'sibling group''s start day and 193 strangers'' — this file only ENDS terms '
                    'there.', b.terms_starting_prev, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-13';
  IF n <> b.terms_jan13 THEN
    RAISE EXCEPTION '3d: 2027-01-13 went % -> %, expected no change from this file.',
                    b.terms_jan13, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-04';
  IF n <> b.terms_jan4 THEN
    RAISE EXCEPTION '3d: 2027-01-04 went % -> %, expected no change from this file.',
                    b.terms_jan4, n;
  END IF;

  -- 4. 🔴 A FUTURE-DATED TERM MUST NOT MOVE THE CURRENT-HOLDER MAP. Nationwide digest.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text)) INTO m
    FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not change '
                    'who holds a seat TODAY.', b.holders_md5, m;
  END IF;

  -- 5. 🟢 THE FIVE HANDOVERS STILL ANSWER WITH THE OUTGOING PERSON.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0518_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of the 9 seats still answer office_current_holder with the person who held '
                    'them before this file, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0518_sel s ON s.office_id = och.office_id
   WHERE NOT s.is_reelection AND och.politician_id = s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % incoming winner(s) already answer as the CURRENT holder of a seat they do '
                    'not take until %. Jared Polis must still be Governor, Phil Weiser must still '
                    'be Attorney General and Jena Griswold must still be Secretary of State.',
                    n, p.expect_term_start;
  END IF;

  -- 6. The predecessors closed exactly where they were meant to, and nothing else moved.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0518_pre r ON r.term_id = t.id
   WHERE t.term_end = p.expect_predecessor_end AND t.how_ended = 'term_expired';
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at % with how_ended term_expired, expected % — '
                    'the exact rows named in the pre-image.',
                    n, p.expect_predecessor_end, p.expect_predecessors;
  END IF;
  -- 6b. 🔴🔴 JARED POLIS'S 2019-01-08 SURVIVED ITS OWN CLOSURE, AND THAT ROW IS THE ONLY IN-DATA
  --     CORROBORATION ART. IV § 1(1) HAS IN THIS STATE. seat_officeholder writes nothing to a
  --     closed row's source, so a moved term_start would be unrecoverable AND would silently stop
  --     CC_0516's assertion 3e reproducing, with every other number in both files still green.
  --     Texas's CC_0515 did exactly this for Greg Abbott's 2015-01-20.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0518_pre r ON r.term_id = t.id
   WHERE t.term_start IS DISTINCT FROM r.term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '6b: % closed predecessor term(s) had their term_start moved. Eight of the nine '
                    'were NULL and the ninth is Jared Polis''s %, which is the second Tuesday of '
                    'January 2019 and the row CC_0516''s assertion 3e reads.',
                    n, p.expect_polis_start;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_EXEC'
     AND t.term_start = p.expect_polis_start;
  IF n <> 1 THEN
    RAISE EXCEPTION '6b: Colorado now holds % state-executive term(s) starting %, expected exactly '
                    '1. That row is the ONLY dated Colorado state executive term and it is the '
                    'in-data control for the clause this file seats under.', n, p.expect_polis_start;
  END IF;
  -- 6c. 🔴🔴 NO TERM CLOSED ANYWHERE ELSE. ⚠ THE CLOSURE DAY WAS EMPTY IN THIS COLUMN, so this one
  --     CAN be a total — and that is stated, because the sibling file's equivalent gate could not
  --     be, and the difference is the whole lesson of this state's four squares.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_end = p.expect_predecessor_end;
  IF n - b.terms_ending_prev <> p.expect_predecessors THEN
    RAISE EXCEPTION '6c: terms ending on % went % -> %, a delta of %, expected % — one closure per '
                    'seat this file filled. ⚠ That day carried NO term ends before this file, '
                    'although it carries % term STARTS (Oregon 75, Washington 118, Colorado 9). A '
                    'gate reading the wrong column there would see 202 strangers.',
                    p.expect_predecessor_end, b.terms_ending_prev, n, n - b.terms_ending_prev,
                    p.expect_predecessors, b.terms_starting_prev;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_end = p.expect_predecessor_end AND lower(d.state) = 'co'
     AND t.id NOT IN (SELECT term_id FROM cc0518_pre);
  IF n <> 0 THEN
    RAISE EXCEPTION '6c: % Colorado term(s) outside the pre-image also end on %. '
                    'seat_officeholder closes only the predecessor of the seat it fills; something '
                    'else closed a term.', n, p.expect_predecessor_end;
  END IF;
  -- 6d. 🔴🔴 AND THIS FILE'S OWN START DAY CARRIES 178 TERM ENDS, WHICH IT MUST NOT HAVE TOUCHED.
  --     That is Maryland's, because 2027-01-12 is the day before the Maryland General Assembly's
  --     2027-01-13 start. The day is EMPTY of starts and BUSY with ends, and the two mistakes are
  --     one column apart.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_end = p.expect_term_start;
  IF n <> b.terms_ending_on_the_day THEN
    RAISE EXCEPTION '6d: terms ending on % went % -> %, expected no change. Those % are MARYLAND''s, '
                    'closed by its own seating because that day is the day before the Maryland '
                    'General Assembly''s 2027-01-13 — this file starts terms on that day and ends '
                    'none there.', p.expect_term_start, b.terms_ending_on_the_day, n,
                    b.terms_ending_on_the_day;
  END IF;
  -- 6e. ⚠ NEITHER BOARD HAS ANY IN-DATA CONTROL, AND THE ABSENCE IS ASSERTED. All 16 board term
  --     rows were term_start NULL before this file (CC_0366, from the bodies' own rosters,
  --     how_started "unknown"), and the five this file closes stay NULL.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0518_pre r ON r.term_id = t.id
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type IN ('STATE_BOARD', 'STATE_BOARD_EDUCATION') AND t.term_start IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '6e: % closed board predecessor term(s) now carry a term_start, expected 0. '
                    'Both boards rest on documentary evidence alone — their day has NO in-data '
                    'corroboration anywhere, which is asserted rather than left unsaid.', n;
  END IF;

  -- 7. Every new term carries the slot, so Ruling B's recovery path works.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0518_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0518%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '7: % of % new term(s) carry CC_0518 in their source.', n, p.expect_offices;
  END IF;
  -- 7b. 🔴🔴 AND THIS FILE'S ROWS MUST NOT ANSWER TO ANOTHER WAVE'S SLOT QUERY.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0518_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND (t.source LIKE '%CC_0516%' OR t.source LIKE '%CC_0517%');
  IF n <> 0 THEN
    RAISE EXCEPTION '7b: % of this wave''s term(s) name ANOTHER migration''s slot in their source. '
                    'Ruling B recovers a wave with source LIKE ''%%<slot>%%'', so these rows would '
                    'be returned as that wave''s — which is exactly what aborted Texas''s first '
                    'chain rehearsal. Describe the sibling file in the header, not in the data.', n;
  END IF;
  -- 7c. 🟢 AND THE SIBLING'S NINE STILL ANSWER ONLY TO ITS OWN SLOT.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0517%';
  IF n <> 9 THEN
    RAISE EXCEPTION '7c: % office_terms row(s) cite CC_0517, expected 9. If this file''s rows have '
                    'started answering to the sibling''s recovery query, the two waves are no '
                    'longer separable by slot.', n;
  END IF;

  -- 8. No person and no office was created or destroyed.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file.',
                    b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %. ⚠ Creating the missing State Board of Education '
                    'District 3 race, or any office, is an occupancy act and belongs to the results '
                    'and seeding programme.', b.offices, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '8: flagged-vacant offices moved from % to %. A FUTURE-dated seating does not '
                    'clear a vacancy flag.', b.vacant_all, n;
  END IF;

  -- 9. Nobody holds two of this wave's seats from the handover day.
  SELECT count(*) INTO n
    FROM (SELECT t.politician_id
            FROM essentials.office_terms t
           WHERE (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
             AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
             AND t.office_id IN (SELECT office_id FROM cc0518_sel)
           GROUP BY t.politician_id HAVING count(*) > 1) x;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % person/people hold more than one of THIS wave''s offices covering %. 🔴 '
                    'THIS ZERO IS PRODUCED BY THE CHAIN CLOSING ON ITSELF, not by nobody moving: '
                    'Weiser''s Attorney General term is closed only because Griswold is seated into '
                    'it, and Griswold''s Secretary of State term only because Gonzalez is seated '
                    'into hers.', n, p.expect_term_start;
  END IF;
  -- 9b. 🔴🔴 THE CHAIN, RE-ASSERTED AFTER THE WRITE AND BY NAME. Each of the three must end with
  --     exactly one covering term, and it must be the right one.
  SELECT s.politician_id INTO gov FROM cc0518_sel s WHERE s.label = 'Colorado Governor';
  SELECT s.politician_id INTO ag  FROM cc0518_sel s WHERE s.label = 'Colorado Attorney General';
  SELECT s.politician_id INTO sos FROM cc0518_sel s WHERE s.label = 'Colorado Secretary of State';
  SELECT count(*) INTO n
    FROM essentials.office_terms t
   WHERE t.politician_id = gov
     AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
     AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start);
  IF n <> 1 THEN
    RAISE EXCEPTION '9b: Phil Weiser holds % term(s) covering %, expected exactly 1 — the '
                    'Governorship. His Attorney General term is closed at % ONLY because Jena '
                    'Griswold is seated into that seat by this same file; drop that seating and he '
                    'holds two.', n, p.expect_term_start, p.expect_predecessor_end;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
   WHERE t.politician_id = ag
     AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
     AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start);
  IF n <> 1 THEN
    RAISE EXCEPTION '9b: Jena Griswold holds % term(s) covering %, expected exactly 1 — the Attorney '
                    'General''s office. Her Secretary of State term is closed at % ONLY because '
                    'Amanda Gonzalez is seated into it by this same file.',
                    n, p.expect_term_start, p.expect_predecessor_end;
  END IF;
  -- 9c. 🔴 And the person at the end of the chain holds TWO, which is correct and is the county
  --     tier's results gap rather than this file's defect.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
   WHERE t.politician_id = sos
     AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
     AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start);
  IF n <> 2 THEN
    RAISE EXCEPTION '9c: Amanda Gonzalez holds % term(s) covering %, expected exactly 2 — the '
                    'Secretary of State''s office and Jefferson County Clerk and Recorder, which '
                    'carries no 2026 race in our data and so gets no successor. ⚠ THAT IS A '
                    'COUNTY-TIER RESULTS GAP AND NOT A DEFECT THIS FILE INTRODUCES, and it is NOT '
                    'tidied: an unsourced closure is what this pass refuses.',
                    n, p.expect_term_start;
  END IF;
  -- 9d. 🔴🔴 AND BOTH KEPT TERMS ARE STILL OPEN, WHICH IS THE CORRECT OUTCOME — AND THE TWO ARE
  --     DIFFERENT KINDS. Senate District 26 is genuinely not up until 2028, so its openness is
  --     right and nothing is missing; Jefferson County Clerk and Recorder is a results gap. They
  --     are indistinguishable from the seat.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0518_dual x ON x.kept_term_id = t.id
   WHERE t.term_end IS NULL AND t.how_ended IS NULL;
  IF n <> p.expect_dual_seat THEN
    RAISE EXCEPTION '9d: % of the % term(s) kept by a winner of this wave are still open, expected '
                    'all of them. Jeff Bridges keeps State Senate District 26 — a four-year seat '
                    'last elected in 2024 and genuinely NOT up in 2026, so it correctly has no '
                    'successor — and Amanda Gonzalez keeps Jefferson County Clerk and Recorder, '
                    'which carries no 2026 race in our data at all. 🔴 ONE IS A RESULTS GAP AND ONE '
                    'IS NOT, and neither is tidied here: closing either would mean asserting an end '
                    'date from a clause nobody sourced.', n, p.expect_dual_seat;
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

  -- 11. The staggered siblings on both boards were not touched.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type IN ('STATE_BOARD', 'STATE_BOARD_EDUCATION')
     AND (t.term_start = p.expect_term_start OR t.source LIKE '%CC_0518%')
     AND t.office_id NOT IN (SELECT office_id FROM cc0518_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % board term(s) outside this wave now start on % or cite this file. Six of '
                    'nine Regents and seven of nine Board of Education members are NOT leaving — '
                    'both bodies are staggered, which is the Arizona Corporation Commission shape, '
                    'and a sibling expansion would seat somebody nobody elected.',
                    n, p.expect_term_start;
  END IF;

  RAISE NOTICE 'CC_0518 OK — 9 Colorado executive and board seats scheduled for % under THREE '
               'instruments: 4 executives (Art. IV § 1(1)), 2 State Board of Education seats '
               '(C.R.S. § 22-2-105(1)) and 3 Regent seats (C.R.S. § 23-20-105(2)). % re-elections '
               'and % handovers, all % called. Predecessors: % terms closed at % with how_ended '
               'term_expired, all nine previously having a NULL term_end. 🔴🔴 THREE OF THE FIVE '
               'HANDOVERS FORM A CHAIN — Polis -> Weiser (Governor), Weiser -> Griswold (Attorney '
               'General), Griswold -> Gonzalez (Secretary of State) — all on one day with all '
               'three seats inside this file, which is New Mexico''s Garcia Richard case two links '
               'deeper and the longest in this pass. SO ASSERTION 9''S ZERO IS PRODUCED BY THE '
               'CHAIN CLOSING ON ITSELF, not by nobody moving: drop any one seating and somebody '
               'holds two offices, which is why 9b asserts the chain BY NAME rather than by count. '
               '⚠ TWO WINNERS STILL HOLD TWO SEATS AND ONLY ONE IS A RESULTS GAP: Jeff Bridges '
               'keeps State Senate District 26, genuinely not up until 2028 so correctly without a '
               'successor, and Amanda Gonzalez keeps Jefferson County Clerk and Recorder, which '
               'carries no 2026 race at all. They are indistinguishable from the seat, so "a dual '
               'holder implies a missing result" is FALSE; both kept terms are asserted still '
               'OPEN. 🔴🔴 ALL FOUR OF THIS WAVE''S CALENDAR CELLS ARE BUSY IN ONE COLUMN AND EMPTY '
               'IN THE OTHER: this file''s start day % carried 0 STARTS and % ENDS (Maryland''s, '
               'because it is the day before 2027-01-13), while its closure day % carried 0 ENDS '
               'and % STARTS (Oregon 75, Washington 118, Colorado 9). Every count names its column '
               'and the before-image pins all four. 🔴 THE LIEUTENANT GOVERNOR IS DATED FOR THIS '
               'VERY DAY AND IS NOT SEATED — seven candidates, no recorded result — and 2b asserts '
               'office_next_term still does not answer for it. 🔴🔴 STATE BOARD OF EDUCATION '
               'DISTRICT 3 WAS ON THE 2026 BALLOT AND HAS NO RACE ROW OF ANY YEAR, proved by '
               '§ 22-2-105(1)''s 1985+6n arithmetic, by Art. XII § 11''s vacancy rule and by the '
               'Department''s own release stating Sherri Wright''s term "runs through January '
               '2027", so the Board''s cohort is THREE and this file seats TWO; the fix is the '
               'result. 🟢 THE REGENTS HAVE NO GAP — § 23-20-102(2)''s three cohorts reconcile with '
               'the body''s own roster on all nine seats. 🟢 Jared Polis''s 2019-01-08 survived its '
               'own closure, which matters because it is the ONLY in-data corroboration Art. IV '
               '§ 1(1) has in this state; ⚠ and NEITHER BOARD has any at all. The current-holder '
               'map is unchanged and the unflagged drift baseline is still %.',
               p.expect_term_start, p.expect_reelections, p.expect_new, p.expect_called,
               p.expect_predecessors, p.expect_predecessor_end,
               p.expect_term_start, b.terms_ending_on_the_day,
               p.expect_predecessor_end, b.terms_starting_prev,
               b.missing_unflagged;
END $$;

COMMIT;
