-- CC_0473 — Maine: the start dates for all 184 seats won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 2026-12-01 IS EIGHT DAYS AWAY AND IT IS THE NEAREST DEADLINE IN THE PASS.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2026-12-01  House of Representatives (149) and Senate (34)
--   2027-01-06  Governor (1)
--
-- Maine was SOURCED on 2026-11-22 and re-derived independently on 2026-11-23, by a reader who
-- had not seen the first write-up, landing on the same two dates. This file writes the rows.
-- ⚠ It does NOT seat anybody, and seating Maine is NOT unblocked by it: **77 of the 183
-- legislative winners have no `politicians` row** — 61 House, 16 Senate, the largest seeding job
-- in the pass. That, not the date, is Maine's critical path.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE TERM BEGINS THE DAY *BEFORE* THE LEGISLATURE CONVENES, AND EVERY PUBLISHED ACCOUNT
--     GIVES THE CONVENING DATE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Me. Const. art. IV, pt. First, § 2:
--   "The House of Representatives shall consist of 151 members, to be elected by the qualified
--    electors, and HOLD THEIR OFFICE 2 YEARS FROM THE DAY NEXT PRECEDING THE FIRST WEDNESDAY IN
--    DECEMBER following the general election."
--
-- Me. Const. art. IV, pt. Second, § 1 — the Senate has no date of its own and takes the House's:
--   "The Senate shall consist of an odd number of Senators, not less than 31 nor more than 35,
--    ELECTED AT THE SAME TIME AND FOR THE SAME TERM AS REPRESENTATIVES …"
--
-- Art. IV, pt. Third, § 1 convenes the Legislature "on the first Wednesday of December following
-- the general election" — 2026-12-02. The term clause puts the term start ONE DAY EARLIER, and
-- that one day is the whole point of the words "the day next preceding".
--
-- 🔴 SO 2026-12-02 IS THE NUMBER EVERY SOURCE PUBLISHES AND IT IS NOT THE TERM START. A pass
--    that reached for the date in the newspapers would be one day wrong on 183 seats. The `notes`
--    column of every legislative row below says so, because the next reader will meet the
--    convening date first everywhere else.
--
-- 🟢🟢 THE LEGISLATURE'S OWN AGENDA FOR THIS CYCLE NAMES BOTH DAYS. The 133rd Legislature's
--    "Pre-Legislative Conference & Convening Day Agenda", published by the Legislative Council of
--    the 132nd (legislature.maine.gov/doc/12791, read 2026-11-23): "Tuesday, December 1st —
--    Pre-Legislative Conference for All Members"; "Wednesday, December 2nd — Convening of the
--    133rd Maine Legislature, 10:00 AM, Senate Chamber". The members-elect are in Augusta on the
--    day their terms begin and are sworn the next morning. One document, both days, this cycle,
--    from the body itself.
--
-- 🟢 AND `21-A M.R.S. § 725`, "Commencement of term of office", is the statute book's whole
--    answer: "County officials elected at the general election take office on January 1st
--    directly following election day. THE TERMS OF OTHER OFFICIALS COMMENCE ON THE DAY PROVIDED
--    IN THE CONSTITUTION OF THE STATE OF MAINE." The Legislature declined to restate the date and
--    named the constitution as the only source, so there is no statutory override to find.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE GOVERNOR — 2027-01-06
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Me. Const. art. V, pt. First, § 2: the Governor "shall HOLD THE OFFICE FOR 4 YEARS FROM THE
-- FIRST WEDNESDAY AFTER THE FIRST TUESDAY OF JANUARY next following the election and until the
-- successor to the Governor has been duly elected and qualified."
--
-- The start is a calendar formula; "until the successor … has been duly elected and qualified"
-- bounds the END. So this is Idaho's shape, not Nevada's: the oath is a separate event and must
-- not be rendered as the term start.
--
-- 🔴 "THE FIRST WEDNESDAY AFTER THE FIRST TUESDAY OF JANUARY" IS NOT "THE FIRST WEDNESDAY OF
--    JANUARY", AND THE TWO AGREE THIS CYCLE BY LUCK. They differ whenever 1 January is a
--    Wednesday: then the plain reading gives the 1st and this clause gives the 8th. 2027 is not
--    such a year — both give 2027-01-06 — so the distinction costs nothing here and would cost a
--    week in, for example, the 2024 cycle. Assertion 3 computes the clause AS WRITTEN.
--
-- 🟢🟢 THE CONTROL IS EXACT AND COMES FROM A PASS THAT NEVER SAW THIS CLAUSE. The same formula
--    gives 2019-01-02 for the 2018 cycle, and `essentials.office_terms` already carries Janet
--    Mills' term starting exactly 2019-01-02, written by `CA_0352` from maine.gov and nga.org.
--    Assertion 3 re-measures that agreement inside this transaction rather than asserting it in
--    a comment.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT MUST NOT BE SWEPT IN, AND WHY EACH IS ABSENT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Maine holds 154 House offices, 35 Senate offices and 4 state executives; this file dates 149,
-- 34 and 1. Every one of the 9 differences is correct and has its own reason:
--
--   • THREE TRIBAL HOUSE SEATS — Penobscot Nation, Passamaquoddy Tribe, Houlton Band of Maliseet
--     Indians. Seated under the Legislature's Joint Rules 206(3) and 316 by their nations, NOT
--     under art. IV pt. First § 2's "151 members" and not at a general election. ⚠ 154 = 151 + 3
--     and both numbers are right about different things: A CHAMBER CAN HOLD SEATS ITS
--     CONSTITUTION'S MEMBERSHIP NUMBER DOES NOT COUNT. Reading 154 ≠ 151 as a defect would be
--     Connecticut's fabricated missing-office finding all over again.
--
--   • THREE SEATS WITH A RACE AND NO RECORDED RESULT — State House 86, State House 96, State
--     Senate 18. A results gap, not a dating one, and invisible to `office_pending_winner`
--     exactly as Nevada's Assembly District 22 was. ⚠ Maine runs ranked-choice voting, so "the
--     rounds are unfinished" is the obvious explanation and the wrong one: art. IV pt. First § 5
--     and pt. Second § 5 decide these seats BY PLURALITY. Senate 18's sitting holder Rick Bennett
--     appears in the 2026 Governor's race with result 'lost', so that seat is simply open.
--
--   • THREE EXECUTIVES CHOSEN BY THE LEGISLATURE — Secretary of State (art. V pt. Second § 1),
--     Treasurer (art. V pt. Third § 1) and Attorney General (art. IX § 11), each "chosen
--     biennially … by joint ballot of the Senators and Representatives in convention". They have
--     a term start and this pass will never see it, because it is keyed to a legislative election
--     that is not the 2026-11-03 general.
--
-- Assertions 4, 5 and 6 measure all three exclusions rather than trusting the selection.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS FILE WRITES NO TERM AND SEATS NOBODY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Overwrites nothing: P2 refuses if any of the 184 already carries a row for this election.
--
-- Sources, read 2026-11-23 unless noted:
--   https://legislature.maine.gov/ros/LawsOfMaine/App/views/constitution.html — the Revisor of
--     Statutes' own publication of the constitution. 🟢 The page at /const/ is a JavaScript
--     application that returns a 5,654-byte stub to curl, but the application fetches ONE static
--     file and that file is the whole constitution: 125,817 characters of text to a bare curl.
--   https://legislature.maine.gov/statutes/21-A/title21-Asec725.html — 21-A M.R.S. § 725.
--   https://legislature.maine.gov/doc/12791 — the 133rd's Convening Day agenda (PDF, 347,908 B).
--   The 2024 House journal and the pre-1975 constitutional text, read 2026-11-22, are cited in
--   backend/data/state-seating-2026/DATES.md § ME.

BEGIN;

CREATE TEMP TABLE cc0473_sel ON COMMIT DROP AS
SELECT o.id AS office_id, d.district_type, o.title, d.label AS seat
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'me'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0473_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in) AS rows_all;

DO $$
DECLARE n bigint;
BEGIN
  -- P1 — exactly the body this file was written against: 149 House + 34 Senate + 1 Governor.
  SELECT count(*) INTO n FROM cc0473_sel;
  IF n <> 184 THEN
    RAISE EXCEPTION 'P1: % Maine seats are pending, expected 184. The data moved under this '
                    'file.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0473_sel WHERE district_type = 'STATE_LOWER';
  IF n <> 149 THEN
    RAISE EXCEPTION 'P1: % House seats, expected 149 (154 offices less 3 tribal seats and 2 with '
                    'no recorded winner).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0473_sel WHERE district_type = 'STATE_UPPER';
  IF n <> 34 THEN
    RAISE EXCEPTION 'P1: % Senate seats, expected 34 (35 offices less State Senate District 18, '
                    'which has a race and no recorded result).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0473_sel WHERE district_type = 'STATE_EXEC';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P1: % state executives are pending, expected 1. Maine elects only the '
                    'Governor at a general election; the Secretary of State, Treasurer and '
                    'Attorney General are chosen by joint ballot of the Legislature.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0473_sel WHERE district_type = 'STATE_EXEC' AND title <> 'Governor';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % pending state executive(s) are not the Governor.', n;
  END IF;

  -- P2 — this file has not already been applied. Asked before anything that could read as the
  -- data having moved: this file writes no term, so on a second run all 184 are still pending
  -- and P1 would pass.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0473_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 184 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       CASE WHEN c.district_type = 'STATE_EXEC'
            THEN DATE '2027-01-06' ELSE DATE '2026-12-01' END,
       'statute',
       CASE WHEN c.district_type = 'STATE_EXEC'
            THEN 'me-const-art5-pt1-s2-first-wed-after-first-tue-january'
            ELSE 'me-const-art4-day-before-first-wed-december' END,
       CASE c.district_type
         WHEN 'STATE_LOWER' THEN
           'Me. Const. art. IV, pt. First, § 2 — the House of Representatives "shall consist of '
             || '151 members, to be elected by the qualified electors, and hold their office 2 '
             || 'years from the day next preceding the first Wednesday in December following the '
             || 'general election". The first Wednesday in December 2026 is the 2nd, so the day '
             || 'next preceding is 2026-12-01. The clause names the day the TERM begins; the '
             || 'oath (art. IX § 1) is a separate event taken at the convening on the 2nd.'
         WHEN 'STATE_UPPER' THEN
           'Me. Const. art. IV, pt. Second, § 1 — senators are "elected at the same time and for '
             || 'the same term as Representatives", so the Senate takes the House''s date from '
             || 'art. IV, pt. First, § 2: 2 years from the day next preceding the first '
             || 'Wednesday in December, which for 2026 is 2026-12-01. The Senate has no term '
             || 'clause of its own.'
         ELSE
           'Me. Const. art. V, pt. First, § 2 — the Governor "shall hold the office for 4 years '
             || 'from the first Wednesday after the first Tuesday of January next following the '
             || 'election and until the successor to the Governor has been duly elected and '
             || 'qualified". The first Tuesday of January 2027 is the 5th, so the first '
             || 'Wednesday after it is 2027-01-06. The start is a calendar formula; '
             || '"until the successor … has been duly elected and qualified" bounds the END, so '
             || 'the oath is a separate event.'
       END,
       'https://legislature.maine.gov/ros/LawsOfMaine/App/views/constitution.html — the Maine '
         || 'Revisor of Statutes'' own publication of the constitution, read 2026-11-22 and '
         || 're-read independently 2026-11-23. (The page at /const/ is a JavaScript application '
         || 'that returns a 5,654-byte stub to curl; this is the single static view file it '
         || 'loads, and it carries the whole text.) '
         || CASE WHEN c.district_type = 'STATE_EXEC'
              THEN 'Controlled against a date this file does not write: the same formula gives '
                     || '2019-01-02 for the 2018 cycle, which is the term_start already recorded '
                     || 'for Governor Janet Mills by CA_0352 from maine.gov and nga.org.'
              ELSE 'Corroborated by the Legislature''s own "133rd Pre-Legislative Conference & '
                     || 'Convening Day Agenda", https://legislature.maine.gov/doc/12791 (PDF, '
                     || 'read 2026-11-23), which puts the Pre-Legislative Conference on Tuesday '
                     || '1 December 2026 and "Convening of the 133rd Maine Legislature" at '
                     || '10:00 AM on Wednesday 2 December 2026; and by 21-A M.R.S. § 725, '
                     || '"Commencement of term of office", which restates no date and provides '
                     || 'that "the terms of other officials commence on the day provided in the '
                     || 'Constitution of the State of Maine".'
            END,
       CASE WHEN c.district_type = 'STATE_EXEC'
         THEN 'Written by CC_0473. Maine''s other three state executives — Secretary of State '
                || '(art. V pt. Second § 1), Treasurer (art. V pt. Third § 1) and Attorney '
                || 'General (art. IX § 11) — are chosen by joint ballot of the Legislature, not '
                || 'at a general election, and are deliberately not in this file.'
         ELSE '🔴 THE TERM BEGINS ONE DAY BEFORE THE LEGISLATURE CONVENES AND TAKES THE OATH. '
                || 'The Legislature convenes 2026-12-02, the first Wednesday of December '
                || '(art. IV pt. Third § 1), and that is the date every published account gives. '
                || 'It is NOT the term start. Written by CC_0473.'
       END
  FROM cc0473_sel c;

DO $$
DECLARE n bigint; b record; d date;
BEGIN
  SELECT * INTO b FROM cc0473_before;

  -- 1. 183 legislative rows on 2026-12-01, 1 Governor row on 2027-01-06.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0473_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-01'
     AND c.district_type IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 183 THEN
    RAISE EXCEPTION '1: % of 183 legislative seats carry 2026-12-01.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0473_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2027-01-06'
     AND c.district_type = 'STATE_EXEC';
  IF n <> 1 THEN
    RAISE EXCEPTION '1: the Governor does not carry 2027-01-06.';
  END IF;

  -- 2. Repo-wide, exactly 184 rows were added — no other office was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 184 THEN
    RAISE EXCEPTION '2: office_swearing_in went % -> %, a delta of %, expected 184.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 3. 🔴🔴 BOTH CLAUSES EVALUATED AS WRITTEN, IN SQL, AND THE SECOND ONE AGAINST A YEAR THIS
  --    FILE DOES NOT WRITE. A control derived from the rows under test would move with the
  --    defect; these are derived from the rules.
  --
  --    (a) the day next preceding the first Wednesday in December 2026
  SELECT (DATE '2026-12-01' + ((10 - EXTRACT(ISODOW FROM DATE '2026-12-01'))::int % 7)) - 1
    INTO d;
  IF d <> DATE '2026-12-01' THEN
    RAISE EXCEPTION '3a: the day next preceding the first Wednesday in December 2026 computes as '
                    '%, not 2026-12-01.', d;
  END IF;

  --    (b) the first Wednesday AFTER the first Tuesday of January 2027 — note this is NOT "the
  --        first Wednesday of January", a different rule that happens to agree in 2027.
  SELECT ft.d + (CASE WHEN EXTRACT(ISODOW FROM ft.d) = 2 THEN 1 ELSE 0 END) INTO d
    FROM (SELECT DATE '2027-01-01'
                 + ((9 - EXTRACT(ISODOW FROM DATE '2027-01-01'))::int % 7) AS d) ft;
  IF d <> DATE '2027-01-06' THEN
    RAISE EXCEPTION '3b: the first Wednesday after the first Tuesday of January 2027 computes as '
                    '%, not 2027-01-06.', d;
  END IF;

  --    (c) the same formula for the 2018 cycle gives 2019-01-02, which must be the term already
  --        recorded for Maine's Governor by a pass that never saw this clause.
  SELECT ft.d + (CASE WHEN EXTRACT(ISODOW FROM ft.d) = 2 THEN 1 ELSE 0 END) INTO d
    FROM (SELECT DATE '2019-01-01'
                 + ((9 - EXTRACT(ISODOW FROM DATE '2019-01-01'))::int % 7) AS d) ft;
  IF d <> DATE '2019-01-02' THEN
    RAISE EXCEPTION '3c: the formula gives % for the 2018 cycle, but the first Wednesday after '
                    'the first Tuesday of January 2019 was 2019-01-02. The formula is wrong.', d;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0473_sel c ON c.office_id = t.office_id
   WHERE c.district_type = 'STATE_EXEC' AND t.term_start = d;
  IF n <> 1 THEN
    RAISE EXCEPTION '3c: Maine''s Governor carries % term(s) starting %, expected 1. The clause '
                    'that dates 2027-01-06 should also explain the term already in the database, '
                    'and it does not.', n, d;
  END IF;

  -- 4. 🔴 THE THREE TRIBAL HOUSE SEATS WERE NOT DATED. They are seated by their nations under
  --    Joint Rules 206(3) and 316, not at a general election, so a row keyed to 2026-11-03 would
  --    be a claim about an election they were not in.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND o.title = 'Tribal Representative'
     AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % tribal House seat(s) were dated against the general election.', n;
  END IF;

  -- 5. 🔴 THE THREE SEATS WITH NO RECORDED RESULT WERE NOT DATED. They are outside
  --    office_pending_winner because nobody recorded a winner, which is exactly as invisible as
  --    having no race. Dating them would quietly assert that this pass had looked at them.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND s.election_date = DATE '2026-11-03'
     AND d.label IN ('State House District 86', 'State House District 96',
                     'State Senate District 18');
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % seat(s) with no recorded 2026 winner were dated.', n;
  END IF;

  -- 6. 🔴 THE THREE EXECUTIVES THE LEGISLATURE CHOOSES WERE NOT DATED.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_EXEC'
     AND o.title IN ('Secretary of State', 'Treasurer', 'Attorney General')
     AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % executive(s) chosen by joint ballot of the Legislature were dated '
                    'against the general election.', n;
  END IF;

  -- 7. 🔴 THE CONVENING DATE WAS NOT WRITTEN ANYWHERE. 2026-12-02 is the number every published
  --    account gives and it is one day late. This is the single most likely way for this file to
  --    be wrong, so it is asserted rather than assumed.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0473_sel c ON c.office_id = s.office_id
   WHERE s.swearing_in_date = DATE '2026-12-02';
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % seat(s) carry 2026-12-02, the day the Legislature CONVENES. The term '
                    'begins the day next preceding it.', n;
  END IF;

  -- 8. No term was written. Seating Maine needs 77 politicians rows first.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0473_sel c ON c.office_id = t.office_id
   WHERE t.term_start IN (DATE '2026-12-01', DATE '2027-01-06');
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0473 OK: 183 Maine legislative seats dated 2026-12-01 (Me. Const. art. IV '
               'pt.1 §2 and pt.2 §1 — the day next preceding the first Wednesday in December, '
               'NOT the 12-02 convening) and the Governor 2027-01-06 (art. V pt.1 §2, '
               'controlled against Mills'' recorded 2019-01-02); 3 tribal seats, 3 seats with no '
               'recorded result and 3 legislature-chosen executives all left undated; no terms '
               'written.';
END $$;

COMMIT;
