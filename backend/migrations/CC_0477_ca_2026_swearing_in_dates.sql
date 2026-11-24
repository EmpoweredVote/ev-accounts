-- CC_0477 — California: the start dates for all 99 state seats won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 2026-12-07 IS FOURTEEN DAYS AWAY AND IT CARRIES 92 SEATS.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2026-12-07  State Assembly (75) and State Senate (17)
--   2027-01-04  Governor, Lieutenant Governor, Attorney General, Controller, Secretary of
--               State, Treasurer (6) and Board of Equalization District 3 (1)
--
-- California was SOURCED on 2026-11-22; the write-up is in
-- backend/data/state-seating-2026/DATES.md § CA. This file writes the rows. It seats nobody.
--
-- 🟢 AND NOBODY NEEDS CREATING. California is the first large state in this pass with no
--    `winner_no_record` blocker at all: every one of the 99 winners already has a politicians
--    row, so step 4 of the register's recipe is skipped outright and CC_0478/CC_0479 follow this
--    file directly.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- TWO CLAUSES, AND THE SECOND ONE IS NOT IN THE ARTICLE ANYONE WOULD SEARCH
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Cal. Const. art. IV, § 2(a)(3) — the Legislature:
--
--   "The terms of a Senator or a Member of the Assembly SHALL COMMENCE ON THE FIRST MONDAY IN
--    DECEMBER NEXT FOLLOWING HER OR HIS ELECTION."
--
-- The first Monday in December 2026 is the **7th**.
--
-- ⚠ Art. IV, § 3(a) convenes the Legislature at noon on that SAME day — "The Legislature shall
--   convene in regular session at noon on the first Monday in December of each even-numbered
--   year and each house shall immediately organize". So California is a same-day state and the
--   oath question costs nothing here. 🔴 CITE § 2(a)(3) ANYWAY: § 3(a) is a convening rule, and
--   Maine is this pass's proof that the two can fall a day apart (CC_0473: term 12-01,
--   convening 12-02, 183 seats).
--
-- Cal. Const. art. II, § 20 — everything else the constitution makes elective:
--
--   "TERMS OF ELECTIVE OFFICES PROVIDED FOR BY THIS CONSTITUTION, OTHER THAN MEMBERS OF THE
--    LEGISLATURE, COMMENCE ON THE MONDAY AFTER JANUARY 1 FOLLOWING ELECTION. The election shall
--    be held in the last even-numbered year before the term expires."
--
-- The Monday after January 1, 2027 is the **4th**.
--
-- 🟢🟢 THAT ONE CLAUSE DATES ALL SEVEN NON-LEGISLATIVE OFFICES, AND IT IS THE ONE A PER-OFFICE
--    SEARCH NEVER REACHES. Art. V, § 2 gives the Governor office "from the Monday after January
--    1 following the election"; art. V, § 11 puts the Lieutenant Governor, Attorney General,
--    Controller, Secretary of State and Treasurer on "the same term as the Governor"; and
--    art. XIII, § 17 gives Board of Equalization members "4-year terms at gubernatorial
--    elections" and NAMES NO COMMENCEMENT AT ALL. Without art. II, § 20 the Board of
--    Equalization would have had to be refused the way Maryland's Comptroller was. ▶ Art. II,
--    § 20 lives in the VOTING article, not the executive one, which is why reading articles IV,
--    V and XIII in order never reaches it. LOOK FOR A CONSTITUTION'S GENERAL TERM-COMMENCEMENT
--    CLAUSE BEFORE CONCLUDING AN OFFICE HAS NONE.
--
-- 🔴 "THE MONDAY AFTER JANUARY 1" IS NOT "THE FIRST MONDAY OF JANUARY", AND THE TWO AGREE THIS
--    CYCLE BY LUCK. They diverge by a full week whenever January 1 is itself a Monday: in 2024
--    the first Monday of January was the 1st and the Monday after January 1 was the 8th. 2027's
--    January 1 is a Friday, so both give 2027-01-04. Assertion 3c evaluates BOTH readings for
--    2024 — a year this file does not write — and refuses unless they differ, which is what
--    proves the clause was implemented as written rather than as remembered.
--
--    ⚠ This matters beyond pedantry here: `essentials.chambers.inauguration_rules` carries
--      "1st Monday in the new year following election" for three California executives and
--      cites nothing. That rule row is the WRONG rule and agrees with the right one this cycle.
--      A rule row earns its way in by its own citation or not at all.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- TERM START OR OATH? — TERM START, BOTH ROWS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Art. IV, § 2(a)(3) says "shall commence on"; art. II, § 20 says "commence on". Both name
-- calendar dates and neither conditions the start on qualification, so this is Idaho's shape,
-- not Nevada's.
--
-- ⚠ Art. V, § 2 adds that the Governor holds office "from the Monday after January 1 following
--   the election UNTIL A SUCCESSOR QUALIFIES". That bounds the END of the predecessor's tenure —
--   the same holdover shape as Massachusetts — and does not move this term's start.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE CONTROLS ARE DERIVED FROM THE RULES, AND CHECKED AGAINST CYCLES THIS FILE DOES NOT
--    WRITE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Assertion 3 computes both clauses in SQL, as written, and then measures them against terms
-- already in `essentials.office_terms` that were written by passes which never saw either
-- clause:
--
--   * the December formula gives 2022-12-05 for the 2022 cycle — 59 California legislative
--     terms already start exactly there;
--   * the January formula gives 2019-01-07 for the 2018 cycle — 5 California executive terms
--     already start exactly there.
--
-- Every even cycle in our data agrees: 2014-12-01 (2 rows), 2016-12-05 (5), 2018-12-03 (3),
-- 2020-12-07 (4), 2022-12-05 (59), 2024-12-02 (37). No biennial cluster sits anywhere else.
--
-- ⚠ THE BOARD OF EQUALIZATION CORROBORATION IS PARTLY CIRCULAR AND IS RECORDED AS SUCH. Its
--   four term rows (2019-01-07 ×3, 2023-01-02 ×1) were written by CA_0205, whose own `source`
--   says the day came "from the Wikipedia BOE membership table, the first Monday after January
--   1" — the Board's own Board-Members-Listing.pdf gives years only. So those rows do not
--   independently confirm art. II, § 20. What has changed is the direction of support: CA_0205
--   guessed a day from an aggregator, and the guess is now backed by a clause. The clause is the
--   authority; the rows are corroboration that the state behaves as it reads. 🟢 ASSERTION 3e
--   THEREFORE COUNTS THE FIVE EXECUTIVE ROWS ONLY, AND LEAVES THE THREE CIRCULAR ONES OUT.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT MUST NOT BE SWEPT IN, AND WHY EACH IS ABSENT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- California holds 18 `STATE_EXEC` office rows and 4 `STATE_BOARD` rows; this file dates 6 and
-- 1. Assertions 4, 5, 6 and 7 measure every exclusion rather than trusting the selection.
--
--   • TWELVE STATE_EXEC OFFICES THAT ARE NOT ELECTIVE, OR NOT PENDING — Auditor, Director of
--     Industrial Relations, five Public Utilities Commissioners, Secretary for Natural
--     Resources, Secretary of Agriculture and a legacy "Board of Equalization Member" row are
--     appointed. Art. II, § 20 reaches ELECTIVE offices only, so none of them has a term
--     commencement to record against a general election.
--
--   • SUPERINTENDENT OF PUBLIC INSTRUCTION AND COMMISSIONER OF INSURANCE are elective and WERE
--     on the 2026 ballot, and neither is in `office_pending_winner`: nobody has recorded their
--     results. That is a results gap, the same class as Massachusetts' Secretary of the
--     Commonwealth, and it belongs to the results programme. 🔴 THEIR DATES WOULD NOT BE THESE
--     ONES IF THEY WERE ADDED: the Superintendent is constitutional but carries its OWN clause
--     (art. IX, § 2, "first Monday after the first day of January"), and the Insurance
--     Commissioner is STATUTORY — so art. II, § 20, "provided for by this Constitution", does
--     not reach it at all and it would need its own citation. Dating them here would be a claim
--     this pass has not earned.
--
--   • BOARD OF EQUALIZATION DISTRICTS 1, 2 AND 4 are mid-term. Art. XIII, § 17 elects the Board
--     at gubernatorial elections, but only District 3 is pending in 2026.
--
--   • TWO CALIFORNIA SCHOOL BOARD SEATS carry a 2026-11-03 race and are outside the four state
--     district types. They belong to the 2026-12-11 California school-board wave.
--
-- ⚠ THE BOARD OF EQUALIZATION OFFICE IS `STATE_BOARD` AND HAS `chamber_id = NULL`. 🔴 AN INNER
--   JOIN TO `essentials.chambers` SILENTLY DROPS IT — that happened while measuring this state
--   and made California read as 98 offices instead of 99. ▶ Join chambers LEFT, or not at all,
--   when counting offices. This file does not join chambers.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS FILE WRITES NO TERM AND SEATS NOBODY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Overwrites nothing: P0 refuses if any of the 99 already carries a row for this election.
-- ⚠ 388 OTHER California offices DO carry a 2026-11-03 swearing-in row already — county, local,
--   local-executive, congressional and school seats from other programmes. None of them is in
--   this selection and assertion 7 pins the California total at 388 + 99.
--
-- Sources, read 2026-11-22 (Legislative Counsel of California, the state's own publication):
--   https://leginfo.legislature.ca.gov/faces/codes_displayText.xhtml?lawCode=CONS&article=IV
--     (184,845 B) — art. IV, §§ 2 and 3.
--   https://leginfo.legislature.ca.gov/faces/codes_displayText.xhtml?lawCode=CONS&article=V
--     (148,650 B) — art. V, §§ 2 and 11.
--   https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=CONS&sectionNum=SEC.%2020.&article=II
--     — art. II, § 20, the clause that dates all seven statewide offices.
--   https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=CONS&sectionNum=SEC.%2017.&article=XIII
--     — art. XIII, § 17, which names no commencement.
--   ⚠ leginfo rate-limits: a third codes_displayText fetch in quick succession returned HTTP 403
--     at 5,643 bytes. That is throttling, not a WAF block and not a missing page — slow down or
--     switch transport rather than concluding the document is gone.

BEGIN;

CREATE TEMP TABLE cc0477_sel ON COMMIT DROP AS
SELECT o.id AS office_id, d.district_type, o.title, d.label AS seat
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'ca'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC', 'STATE_BOARD')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0477_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'ca' AND s.election_date = DATE '2026-11-03')      AS rows_ca;

DO $$
DECLARE n bigint;
BEGIN
  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. This file
  -- writes no term, so on a second run all 99 are still pending and every P1 check below would
  -- pass; the operator would then be told the data moved when what happened is that they ran it
  -- twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0477_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 99 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — exactly the bodies this file was written against.
  SELECT count(*) INTO n FROM cc0477_sel;
  IF n <> 99 THEN
    RAISE EXCEPTION 'P1: % California state seats are pending, expected 99. The data moved '
                    'under this file.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0477_sel WHERE district_type = 'STATE_LOWER';
  IF n <> 75 THEN
    RAISE EXCEPTION 'P1: % Assembly seats, expected 75 of the 80 (the other 5 carry no recorded '
                    '2026 result in our data).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0477_sel WHERE district_type = 'STATE_UPPER';
  IF n <> 17 THEN
    RAISE EXCEPTION 'P1: % Senate seats, expected 17. The California Senate is staggered and '
                    'only half of it is elected each cycle.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0477_sel WHERE district_type = 'STATE_EXEC';
  IF n <> 6 THEN
    RAISE EXCEPTION 'P1: % state executives are pending, expected 6 (Governor, Lieutenant '
                    'Governor, Attorney General, Controller, Secretary of State, Treasurer).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0477_sel
   WHERE district_type = 'STATE_EXEC'
     AND title NOT IN ('Governor', 'Lieutenant Governor', 'Attorney General', 'Controller',
                       'Secretary of State', 'Treasurer');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % pending state executive(s) are not one of the six this file names. '
                    'California carries 18 STATE_EXEC rows and twelve of them are appointed.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0477_sel WHERE district_type = 'STATE_BOARD';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P1: % STATE_BOARD seats, expected 1 (Board of Equalization District 3; '
                    'districts 1, 2 and 4 are mid-term).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0477_sel
   WHERE district_type = 'STATE_BOARD' AND title <> 'Board of Equalization District 3';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: a pending STATE_BOARD seat is not Board of Equalization District 3.';
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       CASE WHEN c.district_type IN ('STATE_LOWER', 'STATE_UPPER')
            THEN DATE '2026-12-07' ELSE DATE '2027-01-04' END,
       'statute',
       CASE WHEN c.district_type IN ('STATE_LOWER', 'STATE_UPPER')
            THEN 'ca-const-art4-s2a3-first-monday-december'
            ELSE 'ca-const-art2-s20-monday-after-january-1' END,
       CASE c.district_type
         WHEN 'STATE_LOWER' THEN
           'Cal. Const. art. IV, § 2(a)(3) — "The terms of a Senator or a Member of the '
             || 'Assembly shall commence on the first Monday in December next following her or '
             || 'his election." The first Monday in December 2026 is the 7th. The clause names '
             || 'the day the TERM begins; art. IV, § 3(a) convenes the Legislature at noon on '
             || 'the same day, so the oath falls on the term start rather than after it.'
         WHEN 'STATE_UPPER' THEN
           'Cal. Const. art. IV, § 2(a)(3) — "The terms of a Senator or a Member of the '
             || 'Assembly shall commence on the first Monday in December next following her or '
             || 'his election." The same clause covers both houses. The first Monday in '
             || 'December 2026 is the 7th. Art. IV, § 3(a) convenes the Legislature at noon on '
             || 'the same day.'
         ELSE
           'Cal. Const. art. II, § 20 — "Terms of elective offices provided for by this '
             || 'Constitution, other than Members of the Legislature, commence on the Monday '
             || 'after January 1 following election." The Monday after January 1, 2027 is the '
             || '4th. '
             || CASE WHEN c.district_type = 'STATE_BOARD'
                  THEN 'Art. XIII, § 17 elects Board of Equalization members to "4-year terms '
                         || 'at gubernatorial elections" and names no commencement at all, so '
                         || 'art. II, § 20 is the only clause that dates this seat.'
                  ELSE 'Art. V, § 2 gives the Governor office "from the Monday after January 1 '
                         || 'following the election", and art. V, § 11 puts the Lieutenant '
                         || 'Governor, Attorney General, Controller, Secretary of State and '
                         || 'Treasurer on "the same term as the Governor".'
                END
       END,
       'https://leginfo.legislature.ca.gov/faces/codes_displayText.xhtml?lawCode=CONS&article='
         || CASE WHEN c.district_type IN ('STATE_LOWER', 'STATE_UPPER') THEN 'IV' ELSE 'V' END
         || ' and https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?'
         || 'lawCode=CONS&sectionNum=SEC.%2020.&article=II — the Legislative Counsel of '
         || 'California''s own publication of the state constitution, read 2026-11-22. '
         || CASE WHEN c.district_type IN ('STATE_LOWER', 'STATE_UPPER')
              THEN 'Controlled against cycles this file does not write: the same clause gives '
                     || '2022-12-05 for the 2022 cycle, which is the term_start already '
                     || 'recorded for 59 California legislative seats, and 2024-12-02 for 2024 '
                     || '(37 rows). Every even cycle in essentials.office_terms clusters on a '
                     || 'first Monday in December and none sits anywhere else.'
              ELSE 'Controlled against a cycle this file does not write: the same clause gives '
                     || '2019-01-07 for the 2018 cycle, which is the term_start already '
                     || 'recorded for five California statewide executives.'
            END,
       CASE WHEN c.district_type IN ('STATE_LOWER', 'STATE_UPPER')
         THEN 'Written by CC_0477. California is a same-day state: art. IV, § 3(a) convenes the '
                || 'Legislature at noon on the first Monday in December, the same day § 2(a)(3) '
                || 'begins the term. Cite § 2(a)(3) — the convening rule is a different fact '
                || 'and in Maine the two fall a day apart.'
         ELSE '🔴 THE CLAUSE IS "THE MONDAY AFTER JANUARY 1", NOT "THE FIRST MONDAY OF JANUARY". '
                || 'The two readings diverge by a week whenever January 1 is itself a Monday '
                || '(in 2024: the 1st against the 8th). They agree for 2027 because January 1 '
                || 'is a Friday. essentials.chambers.inauguration_rules carries the WRONG '
                || 'reading for three California executives and cites nothing; it is not the '
                || 'authority for this row. Written by CC_0477.'
       END
  FROM cc0477_sel c;

DO $$
DECLARE n bigint; b record; d date; d2 date;
BEGIN
  SELECT * INTO b FROM cc0477_before;

  -- 1. 92 legislative rows on 2026-12-07, 7 statewide rows on 2027-01-04.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0477_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-07'
     AND c.district_type IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 92 THEN
    RAISE EXCEPTION '1: % of 92 legislative seats carry 2026-12-07.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0477_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2027-01-04'
     AND c.district_type IN ('STATE_EXEC', 'STATE_BOARD');
  IF n <> 7 THEN
    RAISE EXCEPTION '1: % of 7 statewide seats carry 2027-01-04.', n;
  END IF;

  -- 2. Repo-wide, exactly 99 rows were added — no other office was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 99 THEN
    RAISE EXCEPTION '2: office_swearing_in went % -> %, a delta of %, expected 99.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 3. 🔴🔴 BOTH CLAUSES EVALUATED AS WRITTEN, IN SQL, AND AGAINST CYCLES THIS FILE DOES NOT
  --    WRITE. A control derived from the rows under test would move with the defect; these are
  --    derived from the rules and then measured against terms recorded by earlier passes.
  --
  --    (a) the first Monday in December 2026
  SELECT DATE '2026-12-01' + ((8 - EXTRACT(ISODOW FROM DATE '2026-12-01'))::int % 7) INTO d;
  IF d <> DATE '2026-12-07' THEN
    RAISE EXCEPTION '3a: the first Monday in December 2026 computes as %, not 2026-12-07.', d;
  END IF;

  --    (b) the Monday AFTER January 1, 2027 — strictly after, so a January 1 that is itself a
  --        Monday moves the answer a week forward.
  SELECT DATE '2027-01-01'
         + (CASE WHEN (8 - EXTRACT(ISODOW FROM DATE '2027-01-01'))::int % 7 = 0
                 THEN 7 ELSE (8 - EXTRACT(ISODOW FROM DATE '2027-01-01'))::int % 7 END)
    INTO d;
  IF d <> DATE '2027-01-04' THEN
    RAISE EXCEPTION '3b: the Monday after January 1, 2027 computes as %, not 2027-01-04.', d;
  END IF;

  --    (c) 🔴🔴 THE TWO JANUARY READINGS MUST DIVERGE IN 2024, A YEAR THIS FILE DOES NOT WRITE.
  --        "The Monday after January 1" gives 2024-01-08; "the first Monday of January" — the
  --        reading chambers.inauguration_rules carries, uncited — gives 2024-01-01. If this
  --        assertion finds them equal, the formula above is the wrong rule and happens to agree
  --        for 2027.
  SELECT DATE '2024-01-01'
         + (CASE WHEN (8 - EXTRACT(ISODOW FROM DATE '2024-01-01'))::int % 7 = 0
                 THEN 7 ELSE (8 - EXTRACT(ISODOW FROM DATE '2024-01-01'))::int % 7 END)
    INTO d;
  SELECT DATE '2024-01-01' + ((8 - EXTRACT(ISODOW FROM DATE '2024-01-01'))::int % 7) INTO d2;
  IF d <> DATE '2024-01-08' OR d2 <> DATE '2024-01-01' OR d = d2 THEN
    RAISE EXCEPTION '3c: in 2024 "the Monday after January 1" computes as % and "the first '
                    'Monday of January" as %. Expected 2024-01-08 and 2024-01-01 — two '
                    'different days. The clause has been implemented as the wrong rule.', d, d2;
  END IF;

  --    (d) the December clause, for the 2022 cycle, against 59 terms already in the database.
  SELECT DATE '2022-12-01' + ((8 - EXTRACT(ISODOW FROM DATE '2022-12-01'))::int % 7) INTO d;
  IF d <> DATE '2022-12-05' THEN
    RAISE EXCEPTION '3d: the formula gives % for the 2022 cycle, but the first Monday in '
                    'December 2022 was the 5th. The formula is wrong.', d;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ca' AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND t.term_start = d;
  IF n <> 59 THEN
    RAISE EXCEPTION '3d: % California legislative term(s) start %, expected 59. The clause that '
                    'dates 2026-12-07 should also explain the terms already in the database, '
                    'and it does not.', n, d;
  END IF;

  --    (e) the January clause, for the 2018 cycle, against the 5 EXECUTIVE terms already
  --        recorded. ⚠ The three Board of Equalization rows that also start that day are left
  --        out on purpose: CA_0205 took their day from an aggregator reading this same rule, so
  --        counting them would be measuring this clause against itself.
  SELECT DATE '2019-01-01'
         + (CASE WHEN (8 - EXTRACT(ISODOW FROM DATE '2019-01-01'))::int % 7 = 0
                 THEN 7 ELSE (8 - EXTRACT(ISODOW FROM DATE '2019-01-01'))::int % 7 END)
    INTO d;
  IF d <> DATE '2019-01-07' THEN
    RAISE EXCEPTION '3e: the formula gives % for the 2018 cycle, but the Monday after January '
                    '1, 2019 was the 7th. The formula is wrong.', d;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ca' AND dd.district_type = 'STATE_EXEC' AND t.term_start = d;
  IF n <> 5 THEN
    RAISE EXCEPTION '3e: % California executive term(s) start %, expected 5.', n, d;
  END IF;

  -- 4. 🔴 THE TWELVE APPOINTED STATE_EXEC OFFICES WERE NOT DATED. Art. II, § 20 reaches ELECTIVE
  --    offices only.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ca' AND dd.district_type = 'STATE_EXEC'
     AND s.election_date = DATE '2026-11-03'
     AND o.title IN ('Auditor', 'Director of Industrial Relations',
                     'Public Utilities Commissioner', 'Secretary for Natural Resources',
                     'Secretary of Agriculture', 'Board of Equalization Member');
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % appointed California state office(s) were dated against a general '
                    'election.', n;
  END IF;

  -- 5. 🔴 THE SUPERINTENDENT AND THE INSURANCE COMMISSIONER WERE NOT DATED. Both are elective
  --    and both were on the 2026 ballot; neither has a recorded result, and NEITHER TAKES THESE
  --    DATES. The Superintendent carries its own clause (art. IX, § 2) and the Insurance
  --    Commissioner is statutory, so art. II, § 20 — "provided for by this Constitution" — does
  --    not reach it at all.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ca' AND s.election_date = DATE '2026-11-03'
     AND o.title IN ('Superintendent of Public Instruction', 'Commissioner of Insurance');
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % office(s) with no recorded 2026 result were dated, and their clauses '
                    'are not the two in this file.', n;
  END IF;

  -- 6. 🔴 BOARD OF EQUALIZATION DISTRICTS 1, 2 AND 4 WERE NOT DATED — they are mid-term.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ca' AND dd.district_type = 'STATE_BOARD'
     AND s.election_date = DATE '2026-11-03'
     AND o.title <> 'Board of Equalization District 3';
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % mid-term Board of Equalization seat(s) were dated.', n;
  END IF;

  -- 7. 🔴 NOTHING OUTSIDE THE FOUR STATE DISTRICT TYPES GOT A ROW FROM THIS FILE. 388 other
  --    California offices already carried a 2026-11-03 row — county, local, local-executive,
  --    congressional and school seats from other programmes, INCLUDING the two school board
  --    seats that carry a 2026-11-03 race and belong to the 2026-12-11 wave. The California
  --    total must move by exactly the 99 this file wrote.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ca' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_ca + 99 THEN
    RAISE EXCEPTION '7: California rows for this election went % -> %, a delta of %, expected '
                    '99.', b.rows_ca, n, n - b.rows_ca;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ca' AND s.election_date = DATE '2026-11-03'
     AND dd.district_type = 'SCHOOL'
     AND s.swearing_in_date IN (DATE '2026-12-07', DATE '2027-01-04');
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % California school board seat(s) carry one of this file''s two dates.',
      n;
  END IF;

  -- 8. No term was written. CC_0478 and CC_0479 seat.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0477_sel c ON c.office_id = t.office_id
   WHERE t.term_start IN (DATE '2026-12-07', DATE '2027-01-04');
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0477 OK: 92 California legislative seats dated 2026-12-07 (Cal. Const. '
               'art. IV §2(a)(3), first Monday in December, controlled against the 59 terms '
               'already recorded at 2022-12-05) and 7 statewide seats dated 2027-01-04 '
               '(art. II §20, the Monday after January 1 — NOT the first Monday of January, '
               'which differs by a week in 2024 — controlled against the 5 executive terms at '
               '2019-01-07); 12 appointed offices, the Superintendent, the Insurance '
               'Commissioner, Board of Equalization districts 1/2/4 and 2 school board seats '
               'all left undated; no terms written.';
END $$;

COMMIT;
