-- CC_0487 — Washington: the start date for all 118 legislative seats won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ONE DATE, ONE CITATION, AND THE CITATION IS A STATUTE RATHER THAN THE CONSTITUTION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-11  House of Representatives (95) and Senate (23) — the second Monday in January
--
-- Washington was SOURCED on 2026-11-22 and the source was RE-READ on 2026-11-23 for this file;
-- the write-up is in backend/data/state-seating-2026/DATES.md § WA. This file writes the rows.
-- It seats nobody. CC_0488 seats.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE CONSTITUTION DOES NOT ANSWER THIS, AND THE PROVISION THAT LOOKS LIKE IT DOES GIVES
--     THE RIGHT ANSWER FROM THE WRONG PLACE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Wash. Const. Art. II fixes the LENGTH of a legislative term and never its start:
--
--   § 5  "…members of the house of representatives shall be elected biennially and their term
--         of office shall be two years…"
--   § 6  "…They shall be elected for the term of four years, one-half of their number retiring
--         every two years."
--
-- 🔴 **Art. III, § 4 DOES name a commencement — for the EXECUTIVES.** "The terms of all officers
--    named in section one of this article shall commence on the second Monday in January after
--    their election until otherwise provided by law." That is **the same day**, which is exactly
--    what makes it dangerous: a file that cited Art. III § 4 for a legislator would be right
--    about the date and wrong about the law, and nothing downstream could tell. Washington's
--    nine STATE_EXEC offices are not in this wave at all — none was on the 2026 ballot —
--    and assertion 5 refuses if one is dated here.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITY — RCW 44.04.021, "Commencement of terms of office", quoted in full
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   "The regular term of office of each senator and representative shall commence on the second
--    Monday in January following the date of election."
--   [ 1987 c 13 § 1; 1981 c 288 § 68. Formerly RCW 44.07B.870. ]
--
-- The second Monday in January 2027 is **2027-01-11**. Assertion 3 computes it rather than
-- trusting the literal.
--
-- ⚠ **THE WORD "regular" IS LOAD-BEARING**, and it is why the existing data has outliers. A term
--   filled by appointment is not a regular term; in Washington a county legislative authority
--   appoints to a legislative vacancy at any time of year. Those rows are outside this statute by
--   its own words rather than in conflict with it.
--
-- ⚠ **WASHINGTON'S SESSION CONVENES THE SAME DAY** — RCW 44.04.010: "Regular sessions of the
--   legislature shall be held annually, commencing on the second Monday of January." 🔴 **THAT
--   COINCIDENCE IS NOT A REASON TO CITE THE SESSION STATUTE.** 44.04.021 says when the TERM
--   begins; 44.04.010 would still be true if the term began elsewhere, and Maine is this pass's
--   proof that the two can be different days.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- TERM START OR OATH? — TERM START, A CALENDAR DATE, AND THE OATH FALLS ON THE SAME DAY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- RCW 44.04.021 names a day of the calendar and attaches no condition to it — not qualification,
-- not an oath, not the seating of the chamber. Wash. Const. Art. I, § 6 governs only the MODE of
-- administering an oath and conditions nothing. So Washington's date is a term start, and the
-- oath is a separate event that happens to fall on it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 THE CONTROL — SEVEN BIENNIA OF THE LEGISLATURE'S OWN MEMBER SERVICE, AND IT DISCRIMINATES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `essentials.office_terms` holds 147 Washington legislative terms sourced from the Legislature's
-- own member web service (`wslwebservices.leg.wa.gov SponsorService`) reconciled against
-- Ballotpedia rosters, retrieved 2026-08-13 by a pass that never read this statute. Computing the
-- second Monday independently, for seven cycles this file does not write:
--
--     cycle   second Monday   rows in our data on that day   rows on the FIRST Monday
--     2013    2013-01-14      5                              0
--     2015    2015-01-12      6                              0
--     2017    2017-01-09      7                              0
--     2019    2019-01-14      12                             0
--     2021    2021-01-11      16                             0
--     2023    2023-01-09      23                             0
--     2025    2025-01-13      25                             0
--
-- 🟢 **SEVEN FOR SEVEN ACROSS 94 ROWS, AND THE OBVIOUS WRONG RULE SCORES ZERO SEVEN TIMES.**
--    The nearest mistake available here is writing `first Monday` where the statute says second —
--    one `+ 7` away in the formula, and a real Monday in the right month either way. That rule
--    lands on a day with **no Washington legislative term on it in any of the seven cycles**, so
--    this control separates the two rules instead of merely agreeing with one of them.
--    Assertion 3 runs it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 A CORRECTION TO DATES.md § WA: THE OFF-DATES ARE **NOT** ALL APPOINTMENTS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The ledger explains the 53 rows that do not sit on a second Monday as "appointments to
-- vacancies". That is true of 26 of them — scattered through the calendar, which is the signature
-- of a county appointment. **It is not true of the other 27, and the difference matters.**
--
-- 27 Washington legislative terms start on **January 1st**, spread over 1999–2019, and the source
-- string says the assumed-office date came from the **Ballotpedia** half of the reconciliation.
-- 🔴 **TWO OF THE 27 ARE IN EVEN YEARS (2014-01-01 and 2016-01-01), WHERE NO REGULAR LEGISLATIVE
-- TERM CAN BEGIN AT ALL.** So January 1st here is a year-precision artifact — a date rounded to
-- the first of the year because the day was not known — and not a claim about a term start.
-- Assertion 3d records it, because "the off-dates are appointments" invites the next reader to
-- treat 27 imprecise rows as evidence of a second rule.
--
-- ⚠ **IT DOES NOT WEAKEN THE CONTROL ABOVE.** 27 rows at one to seven a year over twenty years,
--   in odd AND even years alike, are not a biennial spine; the seven clusters of 5 to 25 are.
--   And the statute is the authority — the member service is corroboration, not the source.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT MUST NOT BE SWEPT IN, AND WHY EACH IS ABSENT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Washington holds 98 House offices, 49 Senate offices and 9 statewide executives. This file
-- dates 95 and 23 and no executive. Every gap is accounted for:
--
-- • **25 SENATE SEATS ARE GENUINELY MID-TERM AND HAVE NO 2026 RACE AT ALL.** The chamber is
--   staggered — "one-half of their number retiring every two years" — so 24 of 49 were on this
--   ballot. 🔴 **THIS IS NOT RULING A**: each pending Senate office carries exactly one winner.
--   Ruling A is about a multi-seat RACE attaching several winners to one office row.
--
-- • **FOUR SEATS WERE ON THE 2026 BALLOT AND OUR DATA HAS NO WINNER FOR THEM.** 🔴 **THE LEDGER
--   SAYS THREE, AND THE FOURTH IS IN THE SENATE** — DATES.md § WA framed all 26 non-pending
--   Senate seats as mid-term, and 25 of them are:
--
--       Legislative (House) District 12   State Representative (Position 1)
--       Legislative (House) District 23   State Representative (Position 1)
--       Legislative (House) District 25   State Representative (Position 2)
--       Legislative (Senate) District 35  State Senator
--
--   ⚠ **THEY ARE NOT UNDECIDED — THEY ARE UNRECORDED, AND THE TWO LOOK ALIKE.** Every candidate
--   row on all four carries `result = 'advanced'`, which is the **August top-two PRIMARY**
--   result; the November result was never written. The other 114 seats in these two chambers do
--   carry a `won` row, so the general-election feed did run. 🔴 **DO NOT INFER A WINNER FROM
--   `advanced`, FROM INCUMBENCY, OR FROM THE PRIMARY MARGIN** — two of the four had primaries
--   inside 600 votes. This is the results programme's work, not a dating gap. P2 names all four
--   and refuses if any has since acquired a winner, because then the wave is no longer 118 and
--   CC_0488's pin is stale.
--
-- • **THE NINE STATE EXECUTIVES** — none was on the 2026 ballot. ⚠ Their existing term rows
--   disagree with Art. III § 4 by two days (two read `2025-01-15`, written by migration 1459 as
--   "first day in office", where the second Monday of January 2025 was `2025-01-13`; one already
--   reads `2025-01-13`). 🔴 **KNOWN, OUT OF SCOPE, AND NOT TO BE "FIXED" HERE** — a date is
--   corrected by re-sourcing it, not by copying a neighbour's.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS FILE WRITES NO TERM AND SEATS NOBODY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Overwrites nothing: P0 refuses if any of the 118 already carries a row for this election.
-- ⚠ 10 OTHER Washington offices DO carry a 2026-11-03 row already — the congressional and US
--   Senate seats, from the federal programme. None is in this selection and assertion 6 pins the
--   Washington total at 10 + 118.
--
-- Sources, opened and read:
--   https://app.leg.wa.gov/RCW/default.aspx?cite=44.04.021 — the Code Reviser's own publication
--     of the Revised Code of Washington. Fetched 2026-11-22 and AGAIN 2026-11-23 for this file;
--     HTTP 200, 107,820 bytes both times, text identical.
--   https://leg.wa.gov/media/o3fg0ey1/washington-state-constitution.pdf — the Code Reviser's
--     current arrangement of the state constitution (HTTP 200, application/pdf, 1,939,842 bytes,
--     footer-dated 2025-12-11), read 2026-11-22 for Art. II §§ 5–6 and Art. III § 4.

BEGIN;

CREATE TEMP TABLE cc0487_sel ON COMMIT DROP AS
SELECT o.id AS office_id, d.district_type, o.title, d.label AS seat
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'wa'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

-- The four seats that were on the ballot and have no recorded winner, named so that a file which
-- refuses can say WHICH one moved rather than only that a count changed.
CREATE TEMP TABLE cc0487_unrecorded ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Legislative (House) District 12',  'State Representative (Position 1)'),
  ('Legislative (House) District 23',  'State Representative (Position 1)'),
  ('Legislative (House) District 25',  'State Representative (Position 2)'),
  ('Legislative (Senate) District 35', 'State Senator')
) AS v(seat, title);

CREATE TEMP TABLE cc0487_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'wa' AND s.election_date = DATE '2026-11-03')      AS rows_wa;

DO $$
DECLARE n bigint; v_missing text;
BEGIN
  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. This file
  -- writes no term, so on a second run all 118 seats are still pending and every P1 check would
  -- pass; the operator would be told the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0487_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 118 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — exactly the two bodies this file was written against, counted per chamber. One date
  -- covers both, so a miscount is the only way this state goes wrong in the count.
  SELECT count(*) INTO n FROM cc0487_sel;
  IF n <> 118 THEN
    RAISE EXCEPTION 'P1: % Washington legislative seats are pending, expected 118. The data '
                    'moved under this file — see P2, which names the four seats most likely to '
                    'have moved it.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0487_sel WHERE district_type = 'STATE_LOWER';
  IF n <> 95 THEN
    RAISE EXCEPTION 'P1: % House seats, expected 95 of the 98 (three carry a 2026 race with no '
                    'recorded winner).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0487_sel WHERE district_type = 'STATE_UPPER';
  IF n <> 23 THEN
    RAISE EXCEPTION 'P1: % Senate seats, expected 23 of the 49. The chamber is staggered: 25 are '
                    'genuinely mid-term with no 2026 race, and Legislative (Senate) District 35 '
                    'was on the ballot with no recorded winner.', n;
  END IF;

  -- P2 — 🔴 THE FOUR UNRECORDED SEATS ARE STILL UNRECORDED, AND EACH IS NAMED. If the results
  -- programme has written a winner for one, this wave is 119 seats and CC_0488's pinned digest is
  -- stale. That is a GOOD reason to stop, and the message says so rather than reading as damage.
  SELECT count(*), string_agg(u.seat || ' / ' || u.title, '; ' ORDER BY u.seat)
    INTO n, v_missing
    FROM cc0487_unrecorded u
    JOIN essentials.districts d ON d.label = u.seat AND lower(d.state) = 'wa'
    JOIN essentials.offices o   ON o.district_id = d.id AND o.title = u.title
   WHERE EXISTS (SELECT 1 FROM essentials.office_pending_winner w
                  WHERE w.office_id = o.id AND w.election_date = DATE '2026-11-03');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the four unrecorded seats now carry a 2026 winner: %. That is new '
                    'data, not damage — re-derive the wave (it is no longer 118) and re-pin '
                    'CC_0488 before applying either file.', n, v_missing;
  END IF;

  -- P2b — and the four are really the offices this file thinks they are. A label or title that
  -- no longer matches would make the check above vacuously pass.
  SELECT count(*) INTO n
    FROM cc0487_unrecorded u
    JOIN essentials.districts d ON d.label = u.seat AND lower(d.state) = 'wa'
    JOIN essentials.offices o   ON o.district_id = d.id AND o.title = u.title;
  IF n <> 4 THEN
    RAISE EXCEPTION 'P2b: % of the four named unrecorded seats resolve to an office, expected 4. '
                    'P2 above asserted nothing for the ones that did not resolve.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-11',
       'statute',
       'wa-rcw-44-04-021-second-monday-january',
       'RCW 44.04.021, "Commencement of terms of office" — "The regular term of office of each '
         || 'senator and representative shall commence on the second Monday in January following '
         || 'the date of election." [1987 c 13 § 1; 1981 c 288 § 68. Formerly RCW 44.07B.870.] '
         || 'The second Monday in January 2027 is the 11th. The statute names the day the TERM '
         || 'begins and conditions it on nothing — not qualification, not an oath. 🔴 THE '
         || 'CONSTITUTION DOES NOT ANSWER THIS: Wash. Const. Art. II §§ 5-6 fix only the LENGTH '
         || 'of a legislative term. Art. III § 4 names the second Monday in January for the '
         || 'STATE EXECUTIVES, which is the same day — citing it for a legislator would give the '
         || 'right answer from the wrong provision.',
       'https://app.leg.wa.gov/RCW/default.aspx?cite=44.04.021 — the Code Reviser''s own '
         || 'publication of the Revised Code of Washington, fetched and read 2026-11-22 and '
         || 'again 2026-11-23 (HTTP 200, 107,820 bytes both times, text identical). The '
         || 'constitutional sections were read from '
         || 'https://leg.wa.gov/media/o3fg0ey1/washington-state-constitution.pdf (HTTP 200, '
         || 'application/pdf, 1,939,842 bytes, footer-dated 2025-12-11). Controlled against '
         || 'seven cycles this file does not write: 94 Washington legislative terms already in '
         || 'essentials.office_terms, sourced from the Legislature''s own member web service '
         || '(wslwebservices.leg.wa.gov SponsorService, retrieved 2026-08-13 by a pass that '
         || 'never read this statute), cluster on the independently computed second Monday in '
         || 'every one of 2013, 2015, 2017, 2019, 2021, 2023 and 2025 — 5, 6, 7, 12, 16, 23 and '
         || '25 rows — while the nearest wrong rule, the FIRST Monday, lands on a day with zero '
         || 'Washington legislative terms in all seven.',
       '🔴 WASHINGTON''S SESSION CONVENES THE SAME DAY (RCW 44.04.010), AND THAT IS NOT WHY THIS '
         || 'DATE IS WHAT IT IS. 44.04.021 says when the term begins; 44.04.010 would still be '
         || 'true if it began elsewhere. ⚠ The word "regular" in the statute is load-bearing: a '
         || 'term filled by a county legislative authority''s appointment to a vacancy is not a '
         || 'regular term and does not start on this day, which is why 26 existing Washington '
         || 'rows sit at scattered dates. ⚠ A FURTHER 27 existing rows read January 1st and are '
         || 'a year-precision artifact of the Ballotpedia half of that source, NOT appointments '
         || 'and NOT term starts — two of them fall in even years, where no regular legislative '
         || 'term can begin. ⚠ 25 Senate seats are genuinely mid-term (the chamber is staggered) '
         || 'and four seats were on this ballot with no recorded winner: House districts 12 '
         || '(Pos. 1), 23 (Pos. 1) and 25 (Pos. 2) and Senate district 35. Those four are '
         || 'UNRECORDED, not undecided — every candidate row on them still carries the August '
         || 'top-two primary result. Written by CC_0487.'
  FROM cc0487_sel c;

DO $$
DECLARE n bigint; b record; y int; first_mon date; second_mon date; expect int;
BEGIN
  SELECT * INTO b FROM cc0487_before;

  -- 1. All 118 carry the one date.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0487_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2027-01-11';
  IF n <> 118 THEN
    RAISE EXCEPTION '1: % of 118 seats carry 2027-01-11.', n;
  END IF;

  -- 2. Exactly one distinct date was written. Washington's two chambers share a clause AND a
  --    day; a second date would mean something outside this statute reached the selection.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0487_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 1.', n;
  END IF;

  -- 3. 🔴🔴 THE STATUTE EVALUATED AS WRITTEN, AND CONTROLLED AGAINST SEVEN CYCLES THIS FILE DOES
  --    NOT WRITE — WITH THE WRONG RULE RUN BESIDE IT EACH TIME.
  --
  --    (a) the second Monday in January 2027, computed rather than typed.
  SELECT DATE '2027-01-01' + ((8 - EXTRACT(ISODOW FROM DATE '2027-01-01'))::int % 7)
    INTO first_mon;
  second_mon := first_mon + 7;
  IF second_mon <> DATE '2027-01-11' THEN
    RAISE EXCEPTION '3a: first Monday in January 2027 computes as %, so the second computes as '
                    '%, not 2027-01-11.', first_mon, second_mon;
  END IF;

  --    ⚠ AND IT IS GENUINELY THE SECOND, NOT THE FIRST. The two differ by one `+ 7`, and both
  --      are real Mondays in the right month, so the arithmetic must be stated from both sides.
  IF first_mon = second_mon OR EXTRACT(DAY FROM second_mon)::int NOT BETWEEN 8 AND 14 THEN
    RAISE EXCEPTION '3a: % is not the second Monday of its month (first Monday %). The second '
                    'Monday always falls on the 8th through the 14th.', second_mon, first_mon;
  END IF;

  --    (b) 🟢🟢 SEVEN BIENNIA OF THE LEGISLATURE'S OWN MEMBER SERVICE. For each cycle the right
  --        rule must hit the recorded cluster and the WRONG rule — the first Monday — must hit
  --        nothing. A control that only confirmed the right rule could not tell the two apart.
  FOREACH y IN ARRAY ARRAY[2013, 2015, 2017, 2019, 2021, 2023, 2025] LOOP
    SELECT make_date(y, 1, 1) + ((8 - EXTRACT(ISODOW FROM make_date(y, 1, 1)))::int % 7)
      INTO first_mon;
    second_mon := first_mon + 7;
    expect := (ARRAY[5, 6, 7, 12, 16, 23, 25])[(y - 2011) / 2];

    SELECT count(*) INTO n
      FROM essentials.office_terms t
      JOIN essentials.offices o    ON o.id = t.office_id
      JOIN essentials.districts dd ON dd.id = o.district_id
     WHERE lower(dd.state) = 'wa' AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
       AND t.term_start = second_mon;
    IF n <> expect THEN
      RAISE EXCEPTION '3b: % Washington legislative term(s) start on %, the computed second '
                      'Monday in January %, expected %. The member service and this statute '
                      'agreed on seven cycles when this file was written.', n, second_mon, y,
        expect;
    END IF;

    SELECT count(*) INTO n
      FROM essentials.office_terms t
      JOIN essentials.offices o    ON o.id = t.office_id
      JOIN essentials.districts dd ON dd.id = o.district_id
     WHERE lower(dd.state) = 'wa' AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
       AND t.term_start = first_mon;
    IF n <> 0 THEN
      RAISE EXCEPTION '3c: % Washington legislative term(s) start on %, the FIRST Monday in '
                      'January % — the rule this statute does NOT state. When this file was '
                      'written that day was empty in all seven cycles, which is what makes the '
                      'control discriminate between the two rules rather than merely agree with '
                      'one.', n, first_mon, y;
    END IF;
  END LOOP;

  --    (d) ⚠ THE 27 JANUARY-1 ROWS ARE A PRECISION ARTIFACT, NOT A SECOND RULE — ASSERTED SO A
  --        FUTURE READER DOES NOT TAKE DATES.md's "the off-dates are appointments" at face value.
  --        Two of them fall in EVEN years, where no regular legislative term can begin at all.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'wa' AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND to_char(t.term_start, 'MM-DD') = '01-01';
  IF n <> 27 THEN
    RAISE EXCEPTION '3d: % Washington legislative term(s) start on January 1st, expected 27. '
                    'These are a year-precision artifact of the Ballotpedia half of the source, '
                    'not appointments and not term starts. If the count has moved, re-read them '
                    'before trusting the clusters in 3b.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'wa' AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND to_char(t.term_start, 'MM-DD') = '01-01'
     AND EXTRACT(YEAR FROM t.term_start)::int % 2 = 0;
  IF n <> 2 THEN
    RAISE EXCEPTION '3d: % of the January-1 rows fall in an EVEN year, expected 2 (2014 and '
                    '2016). That is the evidence they are imprecise rather than real term '
                    'starts, because no regular Washington legislative term begins in an even '
                    'year.', n;
  END IF;

  -- 4. 🔴 THE FOUR SEATS WITH NO RECORDED WINNER WERE NOT DATED. Dating one would assert that
  --    this pass had looked at a result it has not.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
    JOIN cc0487_unrecorded u     ON u.seat = dd.label AND u.title = o.title
   WHERE lower(dd.state) = 'wa' AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % of the four seats with no recorded 2026 winner were dated.', n;
  END IF;

  -- 5. 🔴🔴 NO WASHINGTON STATE EXECUTIVE WAS DATED. Art. III § 4 puts them on the SAME DAY, so
  --    a row here would be right about the date and wrong about the law — and none of them was
  --    on the 2026 ballot in the first place. This is the gate that catches the wrong provision.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'wa' AND dd.district_type = 'STATE_EXEC'
     AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % Washington state executive(s) were dated by this file. They share the '
                    'day (Wash. Const. Art. III § 4) and NOT the authority, and none was on the '
                    '2026 ballot.', n;
  END IF;

  -- 6. Washington rows for this election moved by exactly 118. 10 were already there — the
  --    congressional and US Senate seats, from the federal programme.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'wa' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_wa + 118 THEN
    RAISE EXCEPTION '6: Washington rows for this election went % -> %, a delta of %, expected '
                    '118.', b.rows_wa, n, n - b.rows_wa;
  END IF;

  -- 7. Repo-wide, exactly 118 rows were added — no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 118 THEN
    RAISE EXCEPTION '7: office_swearing_in went % -> %, a delta of %, expected 118.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 8. No term was written. CC_0488 seats.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0487_sel c ON c.office_id = t.office_id
   WHERE t.term_start = DATE '2027-01-11';
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0487 OK: 118 Washington legislative seats (95 House, 23 Senate) dated '
               '2027-01-11 — the second Monday in January, RCW 44.04.021, a STATUTE and not the '
               'constitution. The day was computed from a formula, not typed, and controlled '
               'against seven biennia of the Legislature''s own member service: 94 rows on the '
               'computed second Monday, zero on the first Monday, in every cycle. Four seats '
               'with an unrecorded 2026 result and all nine state executives left undated.';
END $$;

COMMIT;
