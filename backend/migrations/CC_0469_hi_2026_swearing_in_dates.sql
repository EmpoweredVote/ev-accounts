-- CC_0469 — Hawaii: the start dates for the five state-executive seats won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 ONE QUEUE ROW, TWO DATES, AND ONE OF THEM HAS ALREADY PASSED.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2026-11-03  Office of Hawaiian Affairs — At-large, Maui Resident and Oahu Resident Trustees
--               🔴 THE DAY OF THE ELECTION ITSELF, now twenty days past.
--   2026-12-07  Governor and Lieutenant Governor — noon on the first Monday in December.
--
-- Two dates in one `(state, district_type)` row means two waves. `classifyWave` raises
-- `date_disagrees` on Hawaii and is right to: CC_0470 seats the trustees, CC_0471 the
-- executives, and neither file may carry the other's date.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE TRUSTEES' TERMS BEGIN ON ELECTION DAY, BEFORE THE RESULT IS CERTIFIED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- HRS § 13D-5, "Term of office; vacancies":
--   "The term of office of members of the board shall be four years BEGINNING ON THE DAY OF THE
--    GENERAL ELECTION AT WHICH THEY ARE ELECTED, or if elected at a primary election, on the day
--    of the general election immediately following the primary election at which they are
--    elected, and ending on the day of the second general election after their election."
--
-- Not a January date, not a swearing-in, not a canvass — the election. This is the first body in
-- the pass whose term begins before its own result is certified, and the only one whose date was
-- already in the past at the moment it was sourced. ▶ "The date is in the future" is an
-- assumption, not a fact, and a queue sorted soonest-first cannot sort a date it has not read.
--
-- ⚠ THE SECOND LIMB CHANGES NOTHING THIS CYCLE AND WOULD IN ANOTHER. HRS § 13D-4(e)(3) lets a
--   primary candidate taking more than fifty per cent be declared elected without appearing on
--   the general ballot — and § 13D-5 still starts that person's term on the day of the FOLLOWING
--   general election. Both routes land on 2026-11-03 here.
--
-- 🟢 "ENDING ON THE DAY OF THE SECOND GENERAL ELECTION AFTER THEIR ELECTION" closes the
--    arithmetic: a four-year term expressed in elections rather than years, 2026-11-03 → 2030.
--
-- 🟢 THE STATUTE THAT DATES THE BODY ALSO CONFIRMS ITS SHAPE. HRS § 13D-1 composes the board of
--    nine — five island-residency seats and four at-large — and we hold exactly nine OHA office
--    rows. HRS § 13D-4(f) legislates for "any election with THREE available seats without a
--    residency requirement", and our data carries exactly three at-large winners.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE GOVERNOR AND LIEUTENANT GOVERNOR — ONE CLAUSE CARRIES BOTH
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Haw. Const. art. V, § 1: "THE TERM OF OFFICE OF THE GOVERNOR SHALL BEGIN AT NOON ON THE FIRST
-- MONDAY IN DECEMBER NEXT FOLLOWING THE GOVERNOR'S ELECTION and end at noon on the first Monday
-- in December, four years thereafter."
--
-- Haw. Const. art. V, § 2: the lieutenant governor "shall be elected at the same time, FOR THE
-- SAME TERM and in the same manner as the governor". One clause, two offices — the Georgia
-- pattern, where the subordinate officer rides on the Governor's own provision.
--
-- ⚠ THE CONSTITUTION SAYS "AT NOON" AND `swearing_in_date` IS A DATE COLUMN. The hour is not
--   representable and does not need to be: the column records the day a term begins. Saying so
--   here is the alternative to silently dropping half a sentence.
--
-- 🟢🟢 THE CONTROL IS THE FORMULA RUN AGAINST A YEAR THIS FILE IS NOT WRITING. Art. V § 1 names
--    a rule, not a choice, so it can be evaluated for 2022 and checked against a date already in
--    the database from a different source: Governor Green's `office_terms.term_start` is
--    2022-12-05, and the first Monday in December 2022 is 2022-12-05. Assertion 3 below computes
--    both years in SQL and refuses if either disagrees. A control derived from the rows under
--    test would move with the defect; this one is derived from the rule.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE SCHEMA FORBADE THIS DATE, AND THE CHECK IT FAILED WAS AN ASSUMPTION, NOT A FACT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `essentials.office_swearing_in` carried
--
--   CONSTRAINT office_swearing_in_after_election CHECK (swearing_in_date > election_date)
--
-- — STRICTLY after. Every state dated in this pass before Hawaii starts in November 2026 at the
-- earliest and the check never fired, so it read as a sound invariant for twenty states. It is
-- not one: HRS § 13D-5 starts an OHA trustee's term ON the day of the election, so the
-- constraint forbids recording a date the statute states in words.
--
-- 🔴 THE ONLY ALTERNATIVE WAS TO CARRY THE DATE AS A LITERAL IN THE SEATING FILE, which is the
--    one thing this pass refuses: a date written into a seating migration agrees with itself
--    however wrong it is. So the constraint is widened to `>=` — in **CC_0472**, which must be
--    applied BEFORE this file despite carrying a later slot number. P0 below refuses to start
--    until it finds the widened definition, so the order is enforced by the data rather than by
--    a comment.
--
-- ⚠ WHY THE DDL IS A SEPARATE FILE AND NOT THIS ONE. `ev_api` is not the owner of this table, so
--   `apply-migration-file.mjs` and `rehearse-migration-chain.mjs` cannot run DDL at all — they
--   fail with "must be owner of table office_swearing_in". Folding the ALTER in here would have
--   made this file impossible to rehearse. CC_0472 goes through the owner connection and carries
--   the positive control on the replacement constraint.
--
-- 🔴 THE CONSTRAINT WAS FOUND BY REHEARSAL, NOT BY READING. This file was written, rehearsed
--    against production on 2026-11-23, and aborted on its first INSERT with "violates check
--    constraint office_swearing_in_after_election". ▶ A SCHEMA RULE THAT TWENTY STATES NEVER
--    TOUCHED LOOKS EXACTLY LIKE A SOUND INVARIANT UNTIL THE TWENTY-FIRST ARRIVES.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHY THE AT-LARGE OFFICE IS DATED THOUGH IT CANNOT BE SEATED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The At-large race carries THREE winners on ONE office row against FOUR at-large offices, so
-- Ruling A's equality clause refuses it: the body is staggered and which seats are up is not in
-- our data. That is a refusal about WHO, not about WHEN. § 13D-5 dates every member of the board
-- identically, so the date is not in doubt and recording it makes the refusal exact instead of
-- vague.
--
-- ⚠ ONLY THE OFFICE ROW THAT CARRIES THE 2026 RACE IS DATED, not all four at-large rows. The
--   other three are not up this cycle; an `office_swearing_in` row keyed to the 2026-11-03
--   election would assert that they were.
-- ▶ INHERITED BY WHOEVER RESOLVES RULING A HERE: a Ruling-A wave seats a winner into a SIBLING
--   office, and the sibling has no date row. Either date the assigned offices in that file, or
--   read the date from the race-carrying office. Do not let its P4 read a NULL and conclude the
--   body is undated.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS FILE WRITES NO TERM AND SEATS NOBODY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Overwrites nothing: P2 refuses if any of the five already carries a row for this election.
--
-- Sources, fetched and read 2026-11-23:
--   https://lrb.hawaii.gov/constitution/  — the Legislative Reference Bureau's own publication
--     of the Hawaii Constitution; the whole document is served on one page (152,682 characters)
--     and its article links are in-page anchors, not URLs.
--   https://www.capitol.hawaii.gov/hrscurrent/Vol01_Ch0001-0042F/HRS0013D/HRS_0013D-0005.htm
--     (and -0001, -0004) — the Legislature's own publication of the HRS, one file per section.
--     ⚠ Those files are UTF-8 WITH A BOM.

BEGIN;

CREATE TEMP TABLE cc0469_sel ON COMMIT DROP AS
SELECT o.id AS office_id, o.title
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'hi'
   AND d.district_type = 'STATE_EXEC'
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0469_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in) AS rows_all;

DO $$
DECLARE n bigint; t text; d text;
BEGIN
  -- P0 — 🔴🔴 CC_0472 HAS BEEN APPLIED. Three of the five rows below carry a swearing-in date
  --    EQUAL to the election date, and the table's original constraint was strictly `>`. Without
  --    CC_0472 this file aborts on its first INSERT with a check-constraint violation, which
  --    reads as a broken file rather than as a missing predecessor. 🔴 THE SLOT NUMBERS RUN THE
  --    OTHER WAY — CC_0472 is applied BEFORE CC_0469 — because the need was only discovered when
  --    this file was rehearsed.
  SELECT pg_get_constraintdef(con.oid) INTO d
    FROM pg_constraint con
    JOIN pg_class c      ON c.oid = con.conrelid
    JOIN pg_namespace ns ON ns.oid = c.relnamespace
   WHERE ns.nspname = 'essentials' AND c.relname = 'office_swearing_in'
     AND con.conname = 'office_swearing_in_after_election';
  IF d IS DISTINCT FROM 'CHECK ((swearing_in_date >= election_date))' THEN
    RAISE EXCEPTION 'P0: office_swearing_in_after_election reads "%", not the widened "CHECK '
                    '((swearing_in_date >= election_date))". APPLY CC_0472 FIRST — Hawaii''s OHA '
                    'trustees'' terms begin ON election day (HRS §13D-5) and this table will '
                    'not hold that date until it has run.', coalesce(d, '(no such constraint)');
  END IF;

  -- P1 — exactly the five seats this file was written against, and they are the five it names.
  SELECT count(*) INTO n FROM cc0469_sel;
  IF n <> 5 THEN
    RAISE EXCEPTION 'P1: % Hawaii state-executive seats are pending, expected 5. The data moved '
                    'under this file.', n;
  END IF;

  SELECT string_agg(title, ' | ' ORDER BY title) INTO t FROM cc0469_sel;
  IF t <> 'Governor | Lieutenant Governor | Office of Hawaiian Affairs At-large Trustee | '
          'Office of Hawaiian Affairs Maui Resident Trustee | '
          'Office of Hawaiian Affairs Oahu Resident Trustee' THEN
    RAISE EXCEPTION 'P1: the five pending titles are "%", which is not the set this file dates. '
                    'Every date below is chosen BY TITLE, so a changed title would silently '
                    'send a seat to the wrong clause.', t;
  END IF;

  -- P2 — this file has not already been applied. Asked before anything else that could read as
  -- the data having moved: this file writes no term, so on a second run the five are still
  -- pending and P1 would pass.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0469_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the five already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       CASE WHEN c.title LIKE 'Office of Hawaiian Affairs%'
            THEN DATE '2026-11-03' ELSE DATE '2026-12-07' END,
       'statute',
       CASE WHEN c.title LIKE 'Office of Hawaiian Affairs%'
            THEN 'hi-hrs-13d-5-term-begins-on-election-day'
            ELSE 'hi-const-art5-noon-first-monday-december' END,
       CASE WHEN c.title LIKE 'Office of Hawaiian Affairs%'
         THEN 'HRS § 13D-5 — "The term of office of members of the board shall be four years '
                || 'beginning on the day of the general election at which they are elected, or '
                || 'if elected at a primary election, on the day of the general election '
                || 'immediately following the primary election at which they are elected, and '
                || 'ending on the day of the second general election after their election." The '
                || 'clause names the day the TERM begins and it is the election day itself; '
                || 'there is no separate oath date in chapter 13D.'
         ELSE 'Haw. Const. art. V, § 1 — "The term of office of the governor shall begin at noon '
                || 'on the first Monday in December next following the governor''s election and '
                || 'end at noon on the first Monday in December, four years thereafter." '
                || 'Art. V, § 2 elects the lieutenant governor "at the same time, for the same '
                || 'term and in the same manner as the governor", so one clause carries both '
                || 'offices. ⚠ The provision says "at noon"; swearing_in_date is a DATE and '
                || 'records the day, not the hour.'
       END,
       CASE WHEN c.title LIKE 'Office of Hawaiian Affairs%'
         THEN 'https://www.capitol.hawaii.gov/hrscurrent/Vol01_Ch0001-0042F/HRS0013D/'
                || 'HRS_0013D-0005.htm — the Hawaii State Legislature''s own publication of the '
                || 'Hawaii Revised Statutes, read 2026-11-23. Corroborated on the body''s shape '
                || 'by HRS § 13D-1 (a board of nine: five island-residency seats and four '
                || 'at-large, matching our nine OHA office rows) and HRS § 13D-4(f) ("any '
                || 'election with three available seats without a residency requirement", '
                || 'matching our three at-large winners).'
         ELSE 'https://lrb.hawaii.gov/constitution/ — the Hawaii Legislative Reference Bureau''s '
                || 'own publication of the state constitution, read 2026-11-23 (the whole '
                || 'document is served on one page; its article links are in-page anchors). '
                || 'Controlled against a date this file does not write: the same formula gives '
                || '2022-12-05 for the 2022 cycle, which is the term_start already recorded for '
                || 'Governor Green from an unrelated source.'
       END,
       CASE WHEN c.title = 'Office of Hawaiian Affairs At-large Trustee'
         THEN 'Written by CC_0469. ⚠ THIS OFFICE IS DATED BUT NOT SEATABLE: three winners sit on '
                || 'this one row against four at-large offices, so Ruling A''s equality clause '
                || 'refuses the race. The refusal is about WHO, not WHEN — § 13D-5 dates every '
                || 'member of the board identically. Only this row, the one carrying the 2026 '
                || 'race, is dated; the other three at-large offices were not up this cycle.'
         WHEN c.title LIKE 'Office of Hawaiian Affairs%'
         THEN 'Written by CC_0469 so CC_0470 can read the date rather than carry a literal. '
                || 'THIS DATE IS IN THE PAST: the term began on election day.'
         ELSE 'Written by CC_0469 so CC_0471 can read the date rather than carry a literal. '
                || 'Hawaii ships as two waves because its two bodies start on different days.'
       END
  FROM cc0469_sel c;

DO $$
DECLARE n bigint; b record; d date;
BEGIN
  SELECT * INTO b FROM cc0469_before;

  -- 1. Three trustees on election day, two executives on the first Monday in December.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0469_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-11-03'
     AND c.title LIKE 'Office of Hawaiian Affairs%';
  IF n <> 3 THEN
    RAISE EXCEPTION '1: % of 3 OHA seats carry 2026-11-03.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0469_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-07'
     AND c.title IN ('Governor', 'Lieutenant Governor');
  IF n <> 2 THEN
    RAISE EXCEPTION '1: % of 2 executive seats carry 2026-12-07.', n;
  END IF;

  -- 2. Repo-wide, exactly five rows were added — no other office was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 5 THEN
    RAISE EXCEPTION '2: office_swearing_in went % -> %, a delta of %, expected 5.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 3. 🔴🔴 THE CONTROL: THE RULE, EVALUATED IN SQL, FOR A YEAR THIS FILE DOES NOT WRITE.
  --    "The first Monday in December" is a formula, so it can be computed rather than looked up
  --    — and the 2022 answer is checkable against a row already in the database, written from an
  --    unrelated source. A control derived from the rows under test would follow the defect.
  SELECT DATE '2026-12-01'
         + ((8 - EXTRACT(ISODOW FROM DATE '2026-12-01'))::int % 7) INTO d;
  IF d <> DATE '2026-12-07' THEN
    RAISE EXCEPTION '3: the first Monday in December 2026 computes as %, not 2026-12-07. The '
                    'date written above is not the one art. V § 1 names.', d;
  END IF;

  SELECT DATE '2022-12-01'
         + ((8 - EXTRACT(ISODOW FROM DATE '2022-12-01'))::int % 7) INTO d;
  IF d <> DATE '2022-12-05' THEN
    RAISE EXCEPTION '3: the formula gives % for 2022, but the first Monday in December 2022 was '
                    '2022-12-05. The formula itself is wrong.', d;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
   WHERE o.title = 'Governor' AND o.id IN (SELECT office_id FROM cc0469_sel)
     AND t.term_start = d;
  IF n <> 1 THEN
    RAISE EXCEPTION '3: Hawaii''s Governor carries % term(s) starting %, expected 1. The clause '
                    'that dates 2026-12-07 should also explain the term already in the '
                    'database, and it does not.', n, d;
  END IF;

  -- 3b. 🔴 THE THREE OHA ROWS ARE ON THE BOUNDARY CC_0472 OPENED, and they are the only rows in
  --     the whole table that are. If this count is ever 0 the equality rows did not land, and if
  --     it exceeds 3 something else has started writing a term that begins on its own election
  --     day without saying so.
  SELECT count(*) INTO n FROM essentials.office_swearing_in
   WHERE swearing_in_date = election_date;
  IF n <> 3 THEN
    RAISE EXCEPTION '3b: % row(s) in office_swearing_in begin on their own election day, '
                    'expected exactly the 3 OHA trustee seats.', n;
  END IF;

  -- 4. No term was written. CC_0470 and CC_0471 do that, from the dates recorded here.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0469_sel c ON c.office_id = t.office_id
   WHERE t.term_start IN (DATE '2026-11-03', DATE '2026-12-07');
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0469 OK: 3 OHA trustee seats dated 2026-11-03 (HRS §13D-5, the election day '
               'itself, already past) and 2 executives dated 2026-12-07 (Haw. Const. art. V '
               '§§1-2, noon on the first Monday in December); formula controlled against '
               'Governor Green''s recorded 2022-12-05; no terms written.';
END $$;

COMMIT;
