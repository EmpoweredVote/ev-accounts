-- CC_0497 — Arizona: the start date for the 94 offices won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE FIRST MONDAY IN JANUARY — 2027-01-04
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-04  Senate (30 of 30) and House of Representatives (58 of 60)   Art. IV, Pt. 2, § 21
--   2027-01-04  Governor · Secretary of State · Attorney General · Treasurer ·
--               Superintendent of Public Instruction (5)                    Art. V, § 1(A)
--   2027-01-04  Corporation Commission (1 office row, DATED AND NOT SEATABLE) Art. XV, § 1(B)
--
-- Sourced 2026-11-22, every section re-read 2026-11-24 at the byte counts below; the write-up is
-- in backend/data/state-seating-2026/DATES.md § AZ. This file writes the rows and seats nobody:
-- CC_0498 seats. **There is no people file** — all 96 Arizona winner rows already carry a
-- politician_id, measured 2026-11-24 (Nevada needed 1 of 13, Maine 18 of 77, Maryland 25 of 85).
--
-- 🔴🔴 THIS FILE DATES 94 OFFICES WHILE ONLY 65 OF THEM CARRY A RACE, AND THAT IS RULING A.
--     Arizona elects two Representatives from every district in ONE multi-seat contest, and a
--     multi-seat race attaches ALL its winners to ONE office row. 29 House office rows carry 58
--     winners between them; the other 29 House offices in the same districts carry no race at
--     all. CC_0498 seats those winners into SIBLING offices under REGISTER.md's Ruling A, so
--     the seat that receives a term must carry the date — the seating file reads
--     office_swearing_in on the office it SEATS, not on the office that carried the race.
--     ▶ A date written only on the 65 race-carrying offices would abort CC_0498 at its P4 for
--     29 seats, AFTER the first seats were written. This is Maryland's CC_0494 lesson, and
--     Arizona is a HIGHER proportion: 29 of 29 pending House offices are multi-winner against
--     Maryland's 38 of 67.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE AUTHORITY — ARIZONA STATES ITS RULE AS AN ANCHOR YEAR, NOT AS A RECURRING FORMULA
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- None of the three provisions says "the first Monday in January following the election". Each
-- names a SPECIFIC PAST DATE and a term length, and the recurrence is implied. That is the shape
-- most likely to be misread as "this office has no rule".
--
--   Art. IV, Pt. 2, § 21 — titled *Term limits of members of state legislature*, which is why a
--     search for a term-START clause does not find it:
--     "The members of the first legislature shall hold office until the first Monday in January,
--      1913. The terms of office of the members of succeeding legislatures shall be two years."
--     1913 + 57×2 = 2027. ✔
--
--   Art. V, § 1(A) — "The executive department shall consist of the governor, lieutenant
--     governor, secretary of state, attorney general, state treasurer and superintendent of
--     public instruction, each of whom shall hold office for four years beginning on the first
--     Monday of January, 1971 next after the regular general election in 1970."
--     1971 + 14×4 = 2027. ✔
--
--   Art. XV, § 1(B) — "A corporation commission is hereby created to be composed of five persons
--     who shall be elected at the general election, and whose term of office shall be four
--     years … The two additional commission members shall be elected at the 2002 general
--     election for initial two-year terms beginning on the first Monday in January, 2003.
--     Thereafter, all terms shall be four-year terms."
--     2003 + 6×4 = 2027. ✔
--
-- All three anchors are a first Monday in January; all three lengths are whole numbers of years;
-- all three cycles land on 2027. The first Monday of January 2027 is 2027-01-04.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE NEAR MISS IS A LIVE DAY IN THIS STATE *AND* THE TERM START OF 193 SEATS ELSEWHERE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-01  the FIRST DAY of January — UTAH's rule (Ut. Const. Art. VI, Secs. 3(2), 4(2)),
--               50 live rows in our own data under ut-const-art6-first-day-january. Nothing in
--               Arizona law names it.
--   2027-01-04  the FIRST MONDAY — all three Arizona clauses, this file.
--   2027-01-11  the SECOND MONDAY — 🔴 ARIZONA'S OWN SESSION CONVENING DAY, Art. IV, Pt. 2, § 3:
--               "The sessions of the legislature shall be held annually at the capitol of the
--               state, and shall commence on the second Monday of January of each year."
--               AND the term start of 118 Washington seats (RCW 44.04.021) and 75 Oregon seats
--               (Or. Const. Art. IV § 4) — 193 rows already on that day.
--
-- 🔴 So reaching one week past the right answer in Arizona does not produce an absurd day. It
--   produces Arizona's own convening date, which 193 other seats already use as a TERM start.
--   Arizona is the second state in this pass where the term and the convening differ (Oregon is
--   the other, by eight days). Assertion 3 computes all three days and refuses the two this file
--   is not about.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 2027-01-04 IS ALREADY OCCUPIED BY TWO OTHER STATES, SO EVERY COUNT HERE IS A DELTA
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured 2026-11-24, before this file: **140 rows already carry 2027-01-04.**
--
--   wi  STATE_LOWER  99   wi-legislature-first-monday
--   wi  STATE_UPPER  17   wi-legislature-first-monday
--   wi  STATE_EXEC    5   wi-state-exec-first-monday
--   wi  COUNTY        2   wi-county-sheriff-59-20-2-b, wi-county-clerk-circuit-59-20-2-bm
--   ca  STATE_EXEC    6   ca-const-art2-s20-monday-after-january-1
--   ca  STATE_BOARD   1   ca-const-art2-s20-monday-after-january-1
--   ca  COUNTY        4   ca-const-vi-16c
--   ca  LOCAL         6   ca-water-principal-act
--
-- 🔴 **WISCONSIN'S RULE IS ALSO A FIRST MONDAY AND ITS rule_id EVEN SAYS SO.** A gate asking
--   "how many rows start on the first Monday of January 2027?" would read 234 after this file
--   and call it success. Washington and Oregon paid for this on 2027-01-11 (CC_0491 P5,
--   CC_0493 P10). ▶ P6 pins the before-image at 140, assertion 4 asserts the delta is exactly
--   94, and every row on the day must belong to a NAMED rule_id — so a fourth state is caught
--   rather than absorbed.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE CONTROL — THREE ARIZONA CYCLES IN OUR OWN DATA, AND THE WRONG RULES SCORE ZERO
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- essentials.office_terms, Arizona state tier, start_precision = 'day' (the ADR 0002 phase-2
-- backfill), computed independently of the clause:
--
--   cycle   first Monday   rows      second Monday   rows      January 1   rows
--   2021    2021-01-04        1      2021-01-11         0      2021-01-01     0
--   2023    2023-01-02       53      2023-01-09         0      2023-01-01     0
--   2025    2025-01-06       26      2025-01-13         0      2025-01-01     0
--
-- 🟢 **THREE FOR THREE, 80 ROWS, AND BOTH NEAR-MISS RULES SCORE ZERO IN ALL THREE CYCLES.**
--   That is what separates two rules rather than merely agreeing with one — Washington's
--   CC_0487 assertion 3 is the precedent. Assertion 3d runs it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE STATE MINE INSPECTOR IS REFUSED, AND ITS ARTICLE IS PUBLISHED TWICE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Art. XIX establishes the office and gives a term length with NO COMMENCEMENT AT ALL. Worse,
-- the constitution carries two competing versions of the same article, both from 1992:
--
--   const/19/0.htm    "Version amended by 1992 Proposition 101" — "shall serve for FOUR years.
--                     The initial four year term shall be served by the mine inspector elected
--                     in the general election held in November, 1994."
--   const/19/0.1.htm  "Version amended by 1992 Proposition 107" — "shall serve for a term of
--                     TWO years", plus a four-consecutive-term limit.
--
-- Neither names a day, and they disagree on the term length, so the office's cycle is not
-- settled by this text either. A.R.S. was searched and holds only the holdover provision
-- (§ 38-295: "Every officer shall continue to discharge the duties of the office, although the
-- term has expired, until a successor has qualified").
--
-- ▶ THE INFERENCE, WRITTEN DOWN AND NOT WRITTEN IN: every other Arizona state office starts on
--   the first Monday in January, so 2027-01-04 is the expected day. It is NOT CITED and is NOT
--   WRITTEN. The confirming document is the Secretary of State's canvass or the inspector's own
--   oath record, and the row it needs is basis = 'published' when that arrives. P4 asserts this
--   file dated nobody in that office; assertion 3c asserts it repo-wide.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ THE CORPORATION COMMISSION IS DATED HERE AND CANNOT BE SEATED — TWO SEPARATE QUESTIONS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Art. XV, § 1(B) gives the commission a day, so it gets an office_swearing_in row on the office
-- that carries the race — ONE row, not five. Dating all five would claim all five seats were on
-- the 2026 ballot, which is false: the body is STAGGERED.
--
-- 🔴🔴 RULING A REFUSES THE SEATING FOR A DIFFERENT REASON, AND THIS BODY IS THE WORKED
--   COUNTER-EXAMPLE IN THE RULING ITSELF. Five Commissioner office rows, one district, all
--   titled `Commissioner`, `seats` / `description` / `representation_note` NULL on every one and
--   one distinct `voting_powers` — so every interchangeability clause PASSES. The 2026 race
--   carries two winners, **Clara Pratte and Jonathon Hill, neither of whom holds any of the
--   five**. Under the superseded "at least" clause, 5 ≥ 2 passed too, nothing anchored, and the
--   rule fell through to "fill the remaining eligible offices" — where all five are remaining.
--   **There are ten ways to choose two of five and one of them is right.** Two sitting
--   commissioners with two to six years left would have been closed out on our pages while the
--   two actually leaving stayed. The equality clause refuses it, which is correct: which seats
--   are up is not in our data at all, and seating it needs the Commission's own published term
--   table, cited.
--
-- 🔴 **A DATE AND A SEAT ARE SEPARATE QUESTIONS, AND THIS OFFICE ANSWERS ONE AND NOT THE OTHER.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TWO HOUSE SEATS ARE UNDATED BECAUSE WE HOLD NO RESULT, AND THEY ARE UNRECORDED, NOT ABSENT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Art. IV, Pt. 2, § 21 gives every member of the legislature a TWO-YEAR term, and § 1(1) elects
-- two Representatives from each of the thirty districts — so **all 60 House seats and all 30
-- Senate seats were on this ballot as a matter of law**. We hold 58 House seats with a winner.
--
-- The other two are State House District 27, which carries a 2026 race for 2 seats, three
-- candidates — Deborah Howard, Lisa Fink, Tony Rivero — and NO `won` row. Every one of the three
-- carries `result = 'advanced'`, which is the **August top-two primary** result seeded by
-- CA_0282 from the Arizona Secretary of State's own primary canvass, not a November one still
-- being counted.
--
-- 🔴 **UNRECORDED HERE, NOT UNDECIDED THERE** — and both look identical from the seat. This is
--   Washington's four-seat class (CC_0487), not Utah's: Utah's 31 gap seats carried NO RACE ROW
--   AT ALL, which is a third class and a different repair. ▶ This belongs to the RESULTS
--   programme. P3 gates on those two seats staying unrecorded — if one gains a winner, the wave
--   is larger and this file's 94 is stale.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 ARIZONA ELECTED A LIEUTENANT GOVERNOR AND WE HOLD NO OFFICE AND NO CANDIDATE FOR IT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Art. V, § 1(A) names the lieutenant governor as part of the executive department — the clause
-- this file cites for the other five — and § 1(C) makes it a joint-ticket office: "a single vote
-- for a nominee for governor shall constitute a vote for that nominee's ticket, including the
-- nominee for lieutenant governor … For any winning candidate for governor at the general
-- election, that winning candidate's joint candidate for lieutenant governor is the winning
-- candidate for lieutenant governor."
--
-- Measured 2026-11-24: Arizona's eleven STATE_EXEC office rows are Attorney General, five
-- Commissioners, Governor, Secretary of State, State Mine Inspector, Superintendent of Public
-- Instruction and Treasurer. **There is no Lieutenant Governor office row and no Lieutenant
-- Governor candidate row anywhere in our Arizona data.**
--
-- ▶ This is CLAUDE.md's *an office with no term is invisible and nothing errors*, reached from
--   the seeding side: Arizona's first Lieutenant Governor takes office on 2027-01-04 and no
--   Arizona address will return them. **Creating that office is an occupancy act** — it must be
--   created AND seated in one file, or the unflagged drift baseline rises. We hold nobody to
--   seat, so it is not created here. It belongs to the results and seeding programme, and the
--   winner's name is on the Governor's ticket. Assertion 3e pins the absence so the next reader
--   finds this paragraph rather than re-deriving it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SOURCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   https://www.azleg.gov/const/4/21.p2.htm   1,133 B  HTTP 200  Art. IV, Pt. 2, § 21
--   https://www.azleg.gov/const/5/1.htm       2,370 B  HTTP 200  Art. V, § 1
--   https://www.azleg.gov/const/15/1.htm      1,715 B  HTTP 200  Art. XV, § 1
--   https://www.azleg.gov/const/4/1.p2.htm   13,810 B  HTTP 200  Art. IV, Pt. 2, § 1 (the 30
--                                                                districts, 1 Senator + 2 Reps)
--   https://www.azleg.gov/const/4/3.p2.htm      973 B  HTTP 200  Art. IV, Pt. 2, § 3 (the
--                                                                SESSION, the near miss)
--   https://www.azleg.gov/const/19/0.htm, …/19/0.1.htm — the two Mine Inspector versions.
--
-- All fetched with a full browser header set and read as text, 2026-11-22 and again 2026-11-24.
-- The Legislature's own publication of the Constitution of Arizona.
--
-- ⚠ **THE SECTION URL IS `/const/<article>/<section>.htm`, EXCEPT IN ARTICLE 4, WHERE PART 2 IS
--   `/const/4/<section>.p2.htm`.** Five plausible spellings of "Article 4, Part 2, Section 21"
--   return HTTP 404 — correctly, at 79,330 bytes; azleg does NOT soft-404. The working form was
--   taken from the article index's own links rather than guessed.
--
-- ⚠ **NO ARIZONA CHAMBER CARRIES AN `inauguration_rules` ROW**, so there was no lead to check
--   and nothing to re-source. (Alabama's cites a statute; three California executives name no
--   authority at all and carry the WRONG one of two rules that agree this cycle.)
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Term start or oath? — **TERM START**
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- All three provisions attach the term to a calendar day: "shall hold office until the first
-- Monday in January, 1913", "beginning on the first Monday of January, 1971", "initial two-year
-- terms beginning on the first Monday in January, 2003". None is conditioned on qualification,
-- so the oath is a separate event this date does not describe. (Contrast Nevada's six
-- executives, refused in CC_0465 because their terms begin ON qualification.)
--
-- basis: `statute` for all 94 rows.
-- rule_id: `az-const-first-monday-january`, with the per-body article in `authority`.

BEGIN;

-- ── The selection: every office this wave will DATE. ──────────────────────────────────────────
--
-- 🔴 THE LEGISLATIVE HALF EXPANDS TO SIBLINGS (Ruling A); THE EXECUTIVE HALF MUST NOT.
--    A sibling expansion over the Corporation Commission race would date all FIVE Commissioner
--    rows and claim that five seats were on the 2026 ballot. The executives are taken by their
--    own office row, by title, and the Mine Inspector is excluded by name.
CREATE TEMP TABLE cc0497_sel ON COMMIT DROP AS
WITH leg_race AS (
  SELECT o.id AS race_office_id, o.district_id, o.chamber_id, o.title, d.district_type
    FROM essentials.office_pending_winner w
    JOIN essentials.offices   o ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03'
), leg AS (
  SELECT DISTINCT o2.id                       AS office_id,
         r.district_type                      AS district_type,
         o2.title                             AS title,
         (o2.id = r.race_office_id)           AS carries_the_race,
         'leg'::text                          AS grp
    FROM leg_race r
    JOIN essentials.offices o2 ON o2.district_id = r.district_id
                              AND o2.chamber_id IS NOT DISTINCT FROM r.chamber_id
                              AND o2.title = r.title
), exec AS (
  SELECT o.id, d.district_type, o.title, TRUE AS carries_the_race,
         CASE WHEN o.title = 'Commissioner' THEN 'ccm' ELSE 'exec' END AS grp
    FROM essentials.office_pending_winner w
    JOIN essentials.offices   o ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az'
     AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03'
     AND o.title IN ('Governor', 'Secretary of State', 'Attorney General', 'Treasurer',
                     'Superintendent of Public Instruction', 'Commissioner')
)
SELECT office_id, district_type, title, carries_the_race, grp FROM leg
UNION ALL
SELECT id,        district_type, title, carries_the_race, grp FROM exec;

CREATE TEMP TABLE cc0497_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'az' AND s.election_date = DATE '2026-11-03')      AS rows_az,
       -- 🔴🔴 ARIZONA IS THE THIRD STATE ON THIS CALENDAR DAY. Wisconsin's 123 rows and
       -- California's 17 are already here, and Wisconsin's rule is ALSO a first Monday. The
       -- before-image is pinned so assertion 4 is a delta and never a total.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-04')                               AS rows_jan4,
       (SELECT count(*) FROM essentials.office_pending_winner w
          JOIN essentials.offices o   ON o.id = w.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'az' AND w.election_date = DATE '2026-11-03'
           AND d.district_type NOT IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC')) AS pending_below_state;

DO $$
DECLARE n bigint; m bigint;
BEGIN
  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. This file
  -- writes no term, so on a second run all 94 seats are still pending and every P1 check would
  -- pass; the operator would be told the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0497_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 94 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — the three bodies, and the Ruling A split inside the House.
  SELECT count(*) INTO n FROM cc0497_sel;
  IF n <> 94 THEN
    RAISE EXCEPTION 'P1: % Arizona seats are reachable from a 2026 race, expected 94 (30 Senate '
                    '+ 58 of the 60 House seats + 5 named executives + 1 Corporation Commission '
                    'row). The data moved under this file.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0497_sel WHERE district_type = 'STATE_UPPER';
  IF n <> 30 THEN
    RAISE EXCEPTION 'P1: % Senate seats reachable, expected 30 — THE WHOLE CHAMBER. Art. IV, '
                    'Pt. 2, § 21 gives every member a two-year term, so Arizona has no '
                    'staggered chamber and no Senate results gap (unlike Washington and '
                    'Oregon).', n;
  END IF;
  SELECT count(*) INTO n FROM cc0497_sel WHERE district_type = 'STATE_LOWER';
  IF n <> 58 THEN
    RAISE EXCEPTION 'P1: % House seats reachable, expected 58 of 60 — the missing 2 are State '
                    'House District 27, which we hold no recorded result for.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0497_sel WHERE grp = 'exec';
  IF n <> 5 THEN
    RAISE EXCEPTION 'P1: % named state executives reachable, expected 5 (Governor, Secretary of '
                    'State, Attorney General, Treasurer, Superintendent of Public Instruction).',
                    n;
  END IF;
  SELECT count(*) INTO n FROM cc0497_sel WHERE grp = 'ccm';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P1: % Corporation Commission row(s) in the selection, expected exactly 1 — '
                    'the office that carries the race. Dating all five would claim five seats '
                    'were on the 2026 ballot; the body is STAGGERED and two were.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0497_sel WHERE carries_the_race;
  IF n <> 65 THEN
    RAISE EXCEPTION 'P1: % of the 94 offices carry the race, expected 65 (30 Senate + 29 House '
                    '+ 5 executives + 1 Commission). The other 29 are Ruling A siblings and are '
                    'the whole reason this file dates 94 offices rather than 65.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0497_sel WHERE NOT carries_the_race;
  IF n <> 29 THEN
    RAISE EXCEPTION 'P1: % sibling offices, expected 29 — one per pending House district, '
                    'because every one of the 29 pending House offices carries two winners.', n;
  END IF;

  -- P2 — 🟢 THE CONSTITUTION'S OWN ARITHMETIC, CHECKED AGAINST OUR OFFICE ROWS. Art. IV, Pt. 2,
  -- § 1(1): "The senate shall be composed of one member elected from each of the thirty
  -- legislative districts … The house of representatives shall be composed of two members
  -- elected from each of the thirty legislative districts." This is what makes "2 seats are
  -- missing" a CERTAINTY rather than a suspicion — and it is also Ruling A's structural floor:
  -- if a district held three House offices, "fill a remaining eligible office" could claim a
  -- seat nobody elected.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_UPPER';
  IF n <> 30 THEN
    RAISE EXCEPTION 'P2: Arizona holds % Senate office rows, expected 30 (Art. IV, Pt. 2, '
                    '§ 1(1)).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_LOWER';
  IF n <> 60 THEN
    RAISE EXCEPTION 'P2: Arizona holds % House office rows, expected 60 — two from each of the '
                    'thirty districts (Art. IV, Pt. 2, § 1(1)).', n;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT o.district_id, count(*) AS per
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_LOWER'
     GROUP BY 1) z WHERE per <> 2;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % Arizona legislative district(s) do not hold exactly 2 House offices. '
                    'Art. IV, Pt. 2, § 1(1) gives every district two Representatives, so a '
                    'district holding one or three is a defect in our office rows and Ruling A '
                    'must not run over it.', n;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT o.district_id, count(*) AS per
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_UPPER'
     GROUP BY 1) z WHERE per <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % Arizona legislative district(s) do not hold exactly 1 Senate '
                    'office.', n;
  END IF;

  -- P3 — 🔴 THE TWO UNDATED HOUSE SEATS, NAMED, AND GATED ON STAYING UNRECORDED.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_LOWER'
     AND o.id NOT IN (SELECT office_id FROM cc0497_sel);
  IF n <> 2 THEN
    RAISE EXCEPTION 'P3: % House office(s) are unreachable from any 2026 race, expected 2. If '
                    'this has fallen, a result has arrived and this file''s 94 is stale; if it '
                    'has risen, a race has been withdrawn.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_LOWER'
     AND o.id NOT IN (SELECT office_id FROM cc0497_sel)
     AND d.label <> 'State House District 27';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % unreachable House seat(s) sit outside State House District 27 — the '
                    'one contest this file''s header measured. A second gap is a different fact '
                    'and needs reading.', n;
  END IF;
  -- 🔴 UNRECORDED, NOT ABSENT: District 27 carries a 2026 race with candidates and no winner.
  -- Utah's gap was 31 seats with NO RACE ROW AT ALL, which looks identical from the seat and is
  -- a different repair. ⚠ And every candidate on it carries result = 'advanced' — the AUGUST
  -- top-two primary result, never a November one still being counted.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_LOWER'
     AND d.label = 'State House District 27'
     AND EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id)
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                      WHERE rc.race_id = r.id AND rc.result = 'won');
  IF n <> 1 THEN
    RAISE EXCEPTION 'P3: the District 27 gap contest does not read as "candidates, no recorded '
                    'winner" (% such contests, expected 1). If a winner has reached our data '
                    'this wave is larger than 94; if the race has gone, the gap is a different '
                    'class — Utah''s 31 seats carried no race row at all.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.label = 'State House District 27'
     AND rc.result = 'advanced';
  IF n <> 3 THEN
    RAISE EXCEPTION 'P3: % District 27 candidate(s) carry result = ''advanced'', expected 3 '
                    '(Deborah Howard, Lisa Fink, Tony Rivero). ''advanced'' is the AUGUST '
                    'top-two primary result, not a November one still being counted — read the '
                    'result and its source before calling a seat undecided.', n;
  END IF;

  -- P4 — 🔴 THE MINE INSPECTOR IS PENDING AND IS NOT IN THIS SELECTION.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 7 THEN
    RAISE EXCEPTION 'P4: % Arizona state executive office rows are pending, expected 7 '
                    '(Governor, Secretary of State, Attorney General, Treasurer, '
                    'Superintendent, one Commissioner row and the State Mine Inspector).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03'
     AND o.title = 'State Mine Inspector'
     AND o.id IN (SELECT office_id FROM cc0497_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: the State Mine Inspector reached this file''s selection. It is REFUSED '
                    '— Art. XIX is published in two conflicting 1992 versions, neither of which '
                    'names a commencement day, and A.R.S. holds only the § 38-295 holdover '
                    'provision. It needs a published qualification date, recorded when it '
                    'happens.';
  END IF;
  -- 🔴🔴 AND THE COMMISSION'S OWN SHAPE IS PINNED, because the date this file writes for it is
  -- honest only while "which two of five seats are up" remains unanswerable from our data.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_EXEC' AND o.title = 'Commissioner';
  IF n <> 5 THEN
    RAISE EXCEPTION 'P4: Arizona holds % Commissioner office rows, expected 5 (Art. XV, § 1(B): '
                    '"composed of five persons"). The Ruling A refusal is measured against this '
                    'number.', n;
  END IF;
  SELECT jsonb_array_length(w.winners) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND o.title = 'Commissioner'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 2 THEN
    RAISE EXCEPTION 'P4: the Corporation Commission race carries % winner(s), expected 2. '
                    'Ruling A refuses it because 5 eligible offices <> 2 winners — a staggered '
                    'body, and which seats are up is not in our data. If this has become 5, the '
                    'refusal needs re-reading, not routing around.', n;
  END IF;

  -- P5 — ⚠ ARIZONA HAS NO PENDING SEAT BELOW THE STATE TIER THIS CYCLE. Oregon had 15 and a
  -- state-wide selection would have swept them in. Counted so that assertion 5's zero means
  -- something rather than being true by luck.
  SELECT pending_below_state INTO n FROM cc0497_before;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % Arizona pending seats now sit below the state tier, expected 0. They '
                    'are dated by their own rules; check that none has reached this file''s '
                    'selection.', n;
  END IF;

  -- P6 — 🔴🔴 TWO OTHER STATES ARE ALREADY ON 2027-01-04 AND ONE OF THEM CALLS ITS RULE A FIRST
  -- MONDAY TOO. The before-image is pinned at 140 and every existing row must belong to a NAMED
  -- rule, so a fourth state is caught rather than absorbed into Arizona's delta.
  SELECT rows_jan4 INTO m FROM cc0497_before;
  IF m <> 140 THEN
    RAISE EXCEPTION 'P6: % row(s) already carry 2027-01-04, expected 140 (Wisconsin 123 under '
                    'wi-legislature-first-monday / wi-state-exec-first-monday / two county '
                    'rules, California 17 under ca-const-art2-s20-monday-after-january-1 / '
                    'ca-const-vi-16c / ca-water-principal-act). A state has landed on Arizona''s '
                    'day since this file was written — name its rule_id before adding 94 to the '
                    'pile.', m;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
   WHERE s.swearing_in_date = DATE '2027-01-04'
     AND s.rule_id NOT IN ('wi-legislature-first-monday', 'wi-state-exec-first-monday',
                           'wi-county-sheriff-59-20-2-b', 'wi-county-clerk-circuit-59-20-2-bm',
                           'ca-const-art2-s20-monday-after-january-1', 'ca-const-vi-16c',
                           'ca-water-principal-act');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % row(s) on 2027-01-04 belong to a rule this file does not know. A date '
                    'shared by several states is a coincidence of calendars, never a shared '
                    'rule.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-04',
       'statute',
       'az-const-first-monday-january',
       CASE c.grp
         WHEN 'leg' THEN
           'Ariz. Const. Art. IV, Pt. 2, § 21 — "The members of the first legislature shall '
             || 'hold office until the first Monday in January, 1913. The terms of office of '
             || 'the members of succeeding legislatures shall be two years." 🔴 ARIZONA STATES '
             || 'ITS RULE AS AN ANCHOR YEAR PLUS A LENGTH, NOT AS A RECURRING FORMULA, which is '
             || 'the shape most likely to be misread as "this office has no rule"; and the '
             || 'section is TITLED "Term limits of members of state legislature", so a search '
             || 'for a term-start clause does not find it. 1913 + 57 two-year terms = 2027, and '
             || 'the first Monday of January 2027 is 2027-01-04. 🔴 CITED FROM § 21 (THE TERM) '
             || 'AND NOT § 3 (THE SESSION), which commences the legislature "on the second '
             || 'Monday of January of each year" — 2027-01-11, a week later, and the day 118 '
             || 'Washington and 75 Oregon seats take office under unrelated rules. Arizona is '
             || 'the second state in this pass where the term start and the convening differ.'
         WHEN 'exec' THEN
           'Ariz. Const. Art. V, § 1(A) — "The executive department shall consist of the '
             || 'governor, lieutenant governor, secretary of state, attorney general, state '
             || 'treasurer and superintendent of public instruction, each of whom shall hold '
             || 'office for four years beginning on the first Monday of January, 1971 next '
             || 'after the regular general election in 1970." 1971 + 14 four-year terms = 2027, '
             || 'and the first Monday of January 2027 is 2027-01-04. 🔴🔴 THE SAME CLAUSE NAMES '
             || 'A LIEUTENANT GOVERNOR AND WE HOLD NO SUCH OFFICE ROW AND NO SUCH CANDIDATE: '
             || '§ 1(C) makes it a joint-ticket office whose winner is decided by the vote for '
             || 'governor, Arizona''s first takes office on this same day, and no Arizona '
             || 'address will return them. Creating that office is an occupancy act and must be '
             || 'done together with a seating; it is not done here.'
         ELSE
           'Ariz. Const. Art. XV, § 1(B) — "A corporation commission is hereby created to be '
             || 'composed of five persons who shall be elected at the general election, and '
             || 'whose term of office shall be four years … The two additional commission '
             || 'members shall be elected at the 2002 general election for initial two-year '
             || 'terms beginning on the first Monday in January, 2003. Thereafter, all terms '
             || 'shall be four-year terms." 2003 + 6 four-year terms = 2027, and the first '
             || 'Monday of January 2027 is 2027-01-04. ⚠ THIS IS ONE ROW, ON THE OFFICE THAT '
             || 'CARRIES THE RACE, NOT FIVE: dating all five Commissioner rows would claim five '
             || 'seats were on the 2026 ballot and the body is STAGGERED — two were. 🔴🔴 AND '
             || 'THIS OFFICE IS DATED AND NOT SEATABLE. REGISTER.md''s Ruling A refuses it: the '
             || 'race carries 2 winners (Clara Pratte and Jonathon Hill, neither of whom holds '
             || 'any of the five) against 5 eligible offices, so nothing anchors and "fill the '
             || 'remaining eligible offices" would choose two of five outright — ten ways, one '
             || 'right. A date and a seat are separate questions and this office answers one.'
       END,
       'https://www.azleg.gov/const/4/21.p2.htm (HTTP 200, 1,133 B), …/const/5/1.htm (2,370 B), '
         || '…/const/15/1.htm (1,715 B), …/const/4/1.p2.htm (13,810 B, the thirty districts) and '
         || '…/const/4/3.p2.htm (973 B, the SESSION clause, this file''s near miss) — the '
         || 'Arizona Legislature''s own publication of the Constitution of Arizona, fetched with '
         || 'a full browser header set and read as text 2026-11-22 and again 2026-11-24 at the '
         || 'same byte counts. ⚠ THE SECTION URL IS /const/<article>/<section>.htm EXCEPT IN '
         || 'ARTICLE 4, WHERE PART 2 IS /const/4/<section>.p2.htm; five plausible spellings of '
         || '"Article 4, Part 2, Section 21" return HTTP 404 at 79,330 bytes — azleg does NOT '
         || 'soft-404 — so the working form was taken from the article index''s own links '
         || 'rather than guessed. 🟢 CORROBORATED BY THREE ARIZONA CYCLES IN OUR OWN DATA, '
         || 'computed independently of the clause: 80 state-tier office_terms rows with '
         || 'start_precision = ''day'' fall on 2021-01-04 (1), 2023-01-02 (53) and 2025-01-06 '
         || '(26) — every one a FIRST Monday — while the second Monday and January 1st carry '
         || 'ZERO rows in all three cycles. That separates the rules instead of merely agreeing '
         || 'with one. ⚠ NO ARIZONA CHAMBER CARRIES AN inauguration_rules ROW, so there was no '
         || 'lead to check and nothing to re-source.',
       '🔴 THREE CANDIDATE DAYS SIT IN THIS ONE MONTH AND BOTH WRONG ONES ARE LIVE SOMEWHERE. '
         || '2027-01-01 is the first DAY of January — UTAH''s rule under Ut. Const. Art. VI '
         || 'Secs. 3(2), 4(2), 50 live rows in our data — and nothing in Arizona law names it. '
         || '2027-01-04 is the first MONDAY, which all three Arizona clauses reach, and is this '
         || 'file. 2027-01-11 is the second MONDAY — ARIZONA''S OWN SESSION CONVENING DAY under '
         || 'Art. IV, Pt. 2, § 3, and the TERM start of 118 Washington seats (RCW 44.04.021) '
         || 'and 75 Oregon seats (Or. Const. Art. IV § 4). Reaching one week too far in Arizona '
         || 'does not produce an absurd day; it produces this state''s convening date, which '
         || '193 seats elsewhere already use as a term start. '
         || '🔴🔴 ARIZONA IS THE THIRD STATE ON 2027-01-04. 140 rows were already here — '
         || 'Wisconsin 123 (its rule is ALSO called a first Monday) and California 17 — so '
         || 'every count about this day is a DELTA that names the other states'' rule_ids. '
         || '🔴🔴 THIS FILE DATES 94 OFFICES AND ONLY 65 CARRY A RACE. Arizona elects two '
         || 'Representatives from every district in one multi-seat contest and a multi-seat '
         || 'race attaches all its winners to one office row, so CC_0498 seats 29 winners into '
         || 'SIBLING offices under REGISTER.md''s Ruling A. The seating file reads this table '
         || 'on the office it SEATS; a date written only on the race-carrying offices would '
         || 'abort it after writing. Every one of the 29 pending House offices is multi-winner '
         || '— a higher proportion than Maryland''s 38 of 67. '
         || '🔴 TWO HOUSE SEATS ARE DELIBERATELY NOT DATED: State House District 27 carries a '
         || '2026 race for two seats with three candidates — Deborah Howard, Lisa Fink and Tony '
         || 'Rivero — and no recorded winner. All three carry result = ''advanced'', which is '
         || 'the AUGUST top-two primary result seeded by CA_0282 from the Secretary of State''s '
         || 'own primary canvass, not a November one still being counted. Art. IV, Pt. 2, § 21 '
         || 'gives every member a two-year term and § 1(1) elects two Representatives from each '
         || 'of the thirty districts, so all 60 House seats were on this ballot as a matter of '
         || 'law and those two are certainly missing data. UNRECORDED here, not undecided '
         || 'there; it belongs to the results programme. '
         || '🔴 THE STATE MINE INSPECTOR IS REFUSED. Art. XIX is published in TWO conflicting '
         || '1992 versions — Proposition 101''s four-year term and Proposition 107''s two-year '
         || 'term — and NEITHER names a commencement day; A.R.S. holds only § 38-295''s '
         || 'holdover provision. The inference that it starts on the first Monday like every '
         || 'other Arizona state office is written down here and NOT written in. It needs a '
         || 'published qualification date from the Secretary of State''s canvass or the '
         || 'inspector''s own oath record. '
         || 'Written by CC_0497.'
  FROM cc0497_sel c;

DO $$
DECLARE n bigint; b record; jan1 date; first_mon date; second_mon date;
        y int; c_first bigint; c_second bigint; c_jan1 bigint; tot_first bigint := 0;
        az_day    CONSTANT date := DATE '2027-01-04';   -- the first Monday, this file
        az_jan1   CONSTANT date := DATE '2027-01-01';   -- Utah's rule
        az_second CONSTANT date := DATE '2027-01-11';   -- Arizona's SESSION, and WA + OR terms
BEGIN
  SELECT * INTO b FROM cc0497_before;

  -- 1. All 94 carry the one date.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0497_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = az_day;
  IF n <> 94 THEN
    RAISE EXCEPTION '1: % of 94 seats carry %.', n, az_day;
  END IF;

  -- 2. Exactly one distinct date was written. Three clauses, one day — which is NOT the default:
  --    Massachusetts' Amend. Art. LXIV § 1 is a SINGLE clause naming three days a fortnight
  --    apart, and Maryland's Governor sits one week past its legislature.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0497_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 1.', n;
  END IF;

  -- 3. 🔴🔴 THE CLAUSE EVALUATED AS WRITTEN, WITH BOTH WRONG RULES COMPUTED BESIDE IT.
  --    (a) "the first Monday in January" following the election — computed, not typed.
  jan1       := make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int + 1, 1, 1);
  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  second_mon := first_mon + 7;
  IF first_mon <> az_day THEN
    RAISE EXCEPTION '3a: the first Monday of January following 2026-11-03 computes as %, not %.',
      first_mon, az_day;
  END IF;
  --    (b) 🔴 THE TWO WRONG DAYS ARE REAL DAYS IN THE RIGHT MONTH AND BOTH ARE LIVE SOMEWHERE.
  IF second_mon <> az_second OR jan1 <> az_jan1 THEN
    RAISE EXCEPTION '3b: the near-miss arithmetic is broken — second Monday %, January 1st %. '
                    'Expected % and %. The comparison below proves nothing while this is wrong.',
      second_mon, jan1, az_second, az_jan1;
  END IF;
  IF first_mon = second_mon OR first_mon = jan1 OR second_mon = jan1 THEN
    RAISE EXCEPTION '3b: the three candidate days are not three distinct days (%, %, %).',
      jan1, first_mon, second_mon;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0497_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date IN (jan1, second_mon);
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % seat(s) carry one of the two wrong days — % (January 1st, UTAH''s '
                    'rule) or % (the second Monday, which is ARIZONA''S OWN SESSION CONVENING '
                    'DAY under Art. IV, Pt. 2, § 3 and the TERM start of 193 Washington and '
                    'Oregon seats).', n, jan1, second_mon;
  END IF;
  --    (c) 🔴 AND NO ARIZONA OFFICE OUTSIDE THIS SELECTION WAS DATED FOR THIS ELECTION. The
  --        Mine Inspector is refused and the other four Commissioner rows are not on the ballot.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'az' AND dd.district_type = 'STATE_EXEC'
     AND s.election_date = DATE '2026-11-03'
     AND s.office_id NOT IN (SELECT office_id FROM cc0497_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '3c: % Arizona state executive seat(s) outside this file''s selection carry '
                    'a date for this election. The State Mine Inspector is REFUSED (Art. XIX '
                    'names no day, in either of its two published 1992 versions) and the four '
                    'Commissioner rows that carry no race were not on the 2026 ballot.', n;
  END IF;
  --    (d) 🟢🟢 THE RULE RUN FOR THREE CYCLES THIS FILE DOES NOT WRITE, AGAINST OUR OWN ARIZONA
  --        TERMS — AND THE TWO WRONG RULES RUN BESIDE IT. A control that only asks "does the
  --        computed day carry the recorded cluster?" is satisfied by any rule that lands there.
  FOR y IN SELECT generate_series(2021, 2025, 2) LOOP
    jan1       := make_date(y, 1, 1);
    first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
    second_mon := first_mon + 7;
    SELECT count(*) FILTER (WHERE t.term_start = first_mon),
           count(*) FILTER (WHERE t.term_start = second_mon),
           count(*) FILTER (WHERE t.term_start = jan1)
      INTO c_first, c_second, c_jan1
      FROM essentials.office_terms t
      JOIN essentials.offices o    ON o.id = t.office_id
      JOIN essentials.districts dd ON dd.id = o.district_id
     WHERE lower(dd.state) = 'az'
       AND dd.district_type IN ('STATE_UPPER', 'STATE_LOWER', 'STATE_EXEC')
       AND t.start_precision = 'day' AND t.term_start IS NOT NULL;
    RAISE NOTICE '3d: % — first Monday % carries % row(s); second Monday % carries %; '
                 'January 1st % carries %.',
      y, first_mon, c_first, second_mon, c_second, jan1, c_jan1;
    IF c_first = 0 THEN
      RAISE EXCEPTION '3d: the first Monday of January % (%) carries no Arizona state term at '
                      'all. This control has lost its fixture and proves nothing — re-measure '
                      'before trusting the rule.', y, first_mon;
    END IF;
    IF c_second <> 0 OR c_jan1 <> 0 THEN
      RAISE EXCEPTION '3d: in % the SECOND Monday (%) carries % Arizona state term(s) and '
                      'January 1st (%) carries %. Both must be zero, or the three rules are not '
                      'distinguishable in our own data and this file''s day rests on agreement '
                      'rather than on discrimination.', y, second_mon, c_second, jan1, c_jan1;
    END IF;
    tot_first := tot_first + c_first;
  END LOOP;
  IF tot_first <> 80 THEN
    RAISE EXCEPTION '3d: % Arizona state terms fall on a first Monday across 2021, 2023 and '
                    '2025, expected 80 (1 + 53 + 26, measured 2026-11-24). The corpus has '
                    'moved; re-read the control before leaning on it.', tot_first;
  END IF;
  --    (e) 🔴🔴 ARIZONA HAS NO LIEUTENANT GOVERNOR OFFICE AND NO LIEUTENANT GOVERNOR CANDIDATE,
  --        AND THE ABSENCE IS PINNED SO THE NEXT READER FINDS THE HEADER RATHER THAN RE-DERIVING
  --        IT. Art. V § 1(A) creates the office, § 1(C) elects it on the governor's ticket, and
  --        its first holder takes office on this very day. Creating it is an occupancy act.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'az' AND o.title ILIKE '%lieutenant%';
  IF n <> 0 THEN
    RAISE EXCEPTION '3e: % Arizona Lieutenant Governor office row(s) now exist, expected 0 when '
                    'this file was written. If one has been created it must be SEATED in the '
                    'same file, or the unflagged drift baseline rises — read this file''s '
                    'header before going further.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'az' AND dd.district_type = 'STATE_EXEC';
  IF n <> 11 THEN
    RAISE EXCEPTION '3e: Arizona holds % STATE_EXEC office rows, expected 11 (Attorney General, '
                    'five Commissioners, Governor, Secretary of State, State Mine Inspector, '
                    'Superintendent of Public Instruction, Treasurer — and NO Lieutenant '
                    'Governor).', n;
  END IF;

  -- 4. 🔴🔴 THE 2027-01-04 DELTA, NAMED. Arizona is the THIRD state on this day and Wisconsin's
  --    rule is also a first Monday, so a gate reading the total would see 234 and call it
  --    success. Washington and Oregon paid for exactly this on 2027-01-11.
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = az_day;
  IF n <> b.rows_jan4 + 94 THEN
    RAISE EXCEPTION '4: rows on % went % -> %, a delta of %, expected 94.',
      az_day, b.rows_jan4, n, n - b.rows_jan4;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.swearing_in_date = az_day
     AND NOT (lower(dd.state) = 'az' AND s.rule_id = 'az-const-first-monday-january')
     AND s.rule_id NOT IN ('wi-legislature-first-monday', 'wi-state-exec-first-monday',
                           'wi-county-sheriff-59-20-2-b', 'wi-county-clerk-circuit-59-20-2-bm',
                           'ca-const-art2-s20-monday-after-january-1', 'ca-const-vi-16c',
                           'ca-water-principal-act');
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % row(s) on % belong to neither Arizona''s rule nor one of the seven '
                    'Wisconsin and California rules that were already here. A date shared by '
                    'several states is a coincidence of calendars, never a shared rule — name '
                    'the new one before absorbing it.', n, az_day;
  END IF;

  -- 5. Arizona rows for this election moved by exactly 94, and every row that is NOT one of the
  --    94 is one of the 9 federal seats the federal programme dated to 2027-01-03.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'az' AND s.election_date = DATE '2026-11-03'
     AND s.office_id NOT IN (SELECT office_id FROM cc0497_sel)
     AND NOT (dd.district_type = 'NATIONAL_LOWER'
              AND s.swearing_in_date = DATE '2027-01-03'
              AND s.rule_id = 'us-const-amend-xx-1');
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % Arizona row(s) for this election are neither one of this file''s 94 '
                    'nor one of the 9 NATIONAL_LOWER rows (2027-01-03, us-const-amend-xx-1).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'az' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_az + 94 THEN
    RAISE EXCEPTION '5: Arizona rows for this election went % -> %, a delta of %, expected 94.',
      b.rows_az, n, n - b.rows_az;
  END IF;

  -- 6. Repo-wide, exactly 94 rows were added — no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 94 THEN
    RAISE EXCEPTION '6: office_swearing_in went % -> %, a delta of %, expected 94.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 7. Every one of the 94 reads back as an Arizona row under this rule, with basis statute.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN cc0497_sel c            ON c.office_id = s.office_id
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03'
     AND lower(dd.state) = 'az'
     AND s.basis = 'statute'
     AND s.rule_id = 'az-const-first-monday-january';
  IF n <> 94 THEN
    RAISE EXCEPTION '7: % of 94 rows read back as an Arizona row with basis statute under '
                    'az-const-first-monday-january.', n;
  END IF;

  -- 7b. 🔴 THE THREE AUTHORITIES, COUNTED SEPARATELY. One rule_id covers three constitutional
  --     provisions here, so the only mechanical trace of "which clause dated this seat" is the
  --     authority text itself. Washington's lesson: a citation can be right about the date and
  --     wrong about the law, and no count can see it unless a count is written for it.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0497_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'leg'
     AND s.authority LIKE 'Ariz. Const. Art. IV, Pt. 2, § 21 %';
  IF n <> 88 THEN
    RAISE EXCEPTION '7b: % of the 88 legislative rows cite Art. IV, Pt. 2, § 21.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0497_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'exec'
     AND s.authority LIKE 'Ariz. Const. Art. V, § 1(A) %';
  IF n <> 5 THEN
    RAISE EXCEPTION '7b: % of the 5 executive rows cite Art. V, § 1(A).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0497_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'ccm'
     AND s.authority LIKE 'Ariz. Const. Art. XV, § 1(B) %';
  IF n <> 1 THEN
    RAISE EXCEPTION '7b: the Corporation Commission row does not cite Art. XV, § 1(B).';
  END IF;

  -- 8. District 27's two seats are still undated. This file dated what it can see a winner for.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts dd ON dd.id = o.district_id
    JOIN essentials.office_swearing_in s ON s.office_id = o.id
                                        AND s.election_date = DATE '2026-11-03'
   WHERE lower(dd.state) = 'az' AND dd.district_type = 'STATE_LOWER'
     AND o.id NOT IN (SELECT office_id FROM cc0497_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % of the two unrecorded District 27 seats were dated. A seat we hold no '
                    'winner for is not a seat this wave can schedule.', n;
  END IF;

  -- 9. No term was written. CC_0498 seats.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0497_sel c ON c.office_id = t.office_id
   WHERE t.term_start = az_day;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0497 OK: 94 Arizona seats dated % — THE FIRST MONDAY in January, from three '
               'separate provisions that each name an ANCHOR YEAR and a term length rather than '
               'a recurring formula: Art. IV, Pt. 2, § 21 (88 legislative seats, 1913 + 57x2), '
               'Art. V, § 1(A) (5 executives, 1971 + 14x4) and Art. XV, § 1(B) (1 Corporation '
               'Commission row, 2003 + 6x4). The day was computed and both wrong rules computed '
               'beside it: % (January 1st, UTAH''s rule) and % (the second Monday — ARIZONA''S '
               'OWN SESSION CONVENING DAY under Art. IV, Pt. 2, § 3, and the TERM start of 193 '
               'Washington and Oregon seats). The rules were run again over three Arizona '
               'cycles in our own data: 80 terms on a first Monday, ZERO on either wrong rule '
               'in all three. 94 offices were dated although only 65 carry a race — Ruling A '
               'seats 29 winners into sibling House offices and the seating file reads this '
               'table on the office it SEATS. Arizona is the THIRD state on this calendar day '
               '(Wisconsin 123, California 17), so every count here is a delta that names the '
               'other rules. Two House seats in District 27 were NOT dated: a 2026 race, three '
               'candidates all carrying the AUGUST primary''s ''advanced'', and no recorded '
               'winner. The State Mine Inspector is REFUSED — Art. XIX is published in two '
               'conflicting 1992 versions and neither names a day. The Corporation Commission '
               'is dated and NOT seatable: 2 winners against 5 eligible offices, which Ruling '
               'A refuses. Arizona also elected a LIEUTENANT GOVERNOR for which we hold no '
               'office row and no candidate row at all.',
    az_day, az_jan1, az_second;
END $$;

COMMIT;
