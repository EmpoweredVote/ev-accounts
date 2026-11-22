-- CC_0463 — Indiana House: the start date for the three 2026 seats still unseated.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 READ WHAT THE SOURCE'S DATE IS A DATE *OF*. HERE IT IS A TERM START, NOT A SWEARING-IN.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Ind. Const. art. 4 § 3: senators and representatives "shall be elected for a term of four years
-- and two years respectively, FROM THE DAY NEXT AFTER THEIR GENERAL ELECTION". The provision
-- names the day the TERM begins and says nothing about an oath or an organising session — so
-- 2026-11-03 + 1 = 2026-11-04, and there is no oath-versus-term-start question to answer for
-- Indiana. That matters because this pass refuses to render one as the other, and states
-- genuinely differ: Wisconsin's two events fall on one day (CC_0462), Indiana has only the one
-- event in its constitution.
--
-- ⚠ THIS IS NOT A NEW READING. 24 Indiana House offices already carry a term starting
--   2026-11-04, written by CA_0374 and CA_0396, and every one of those rows quotes this same
--   clause in its own `source`. CA_0396 sourced its members from the legislature's own roster at
--   api.iga.in.gov, which is the chamber's own publication and outranks every aggregator. This
--   file records, in the register, the date those migrations were already applying.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHY ONLY THREE ROWS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The wave that follows (CC_0464) seats three offices, and `office_swearing_in` is keyed
-- (office_id, election_date). Writing a row for all 100 House offices would be a claim about 97
-- seats this pass does not touch and has not checked. The three are the ones whose winner is
-- recorded and whose seat is still unscheduled.
--
-- 🔴 THIS FILE WRITES NO TERM AND SEATS NOBODY. It records a date so that CC_0464 can READ one
--    rather than carry a literal — the rule the whole pass turns on. A date written into a
--    seating file agrees with itself however wrong it is.
--
-- Overwrites nothing: P1 refuses if any of the three already carries a row for this election, so
-- there is no prior value for this file to record.

BEGIN;

CREATE TEMP TABLE cc0463_sel ON COMMIT DROP AS
SELECT o.id AS office_id, d.label AS seat
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'in'
   AND d.district_type = 'STATE_LOWER'
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0463_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in) AS rows_all;

DO $$
DECLARE n bigint;
BEGIN
  -- P1 — exactly the three seats this file was written against, none of them already dated.
  SELECT count(*) INTO n FROM cc0463_sel;
  IF n <> 3 THEN
    RAISE EXCEPTION 'P1: % Indiana House seats are pending, expected 3. The data moved under '
                    'this file.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0463_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % of the three already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2026-11-04',
       'statute',
       'in-general-assembly-day-after',
       'Ind. Const. art. 4 § 3 — senators and representatives "shall be elected for a term of '
         || 'four years and two years respectively, from the day next after their general '
         || 'election". The clause names the day the TERM begins; it is not a swearing-in date '
         || 'and Indiana''s constitution sets no separate oath day for a member.',
       'https://iga.in.gov/laws/2025/ic/titles/constitution#constitution-article-4-section-3, '
         || 'the Indiana General Assembly''s own publication of the constitution, read '
         || '2026-11-21. The same clause is quoted in the source of all 24 Indiana House terms '
         || 'already starting 2026-11-04 (CA_0374, CA_0396).',
       'Written by CC_0463 so CC_0464 can read the date rather than carry a literal.'
  FROM cc0463_sel c;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0463_before;

  -- 1. Exactly three rows, on the three selected offices, carrying the day after the election.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0463_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-11-04';
  IF n <> 3 THEN
    RAISE EXCEPTION '1: % of 3 seats carry the date.', n;
  END IF;

  -- 2. Repo-wide, exactly three rows were added — no other office was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 3 THEN
    RAISE EXCEPTION '2: office_swearing_in went % -> %, a delta of %, expected 3.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 3. 🔴 THE DATE AGREES WITH THE 24 TERMS ALREADY WRITTEN UNDER THE SAME CLAUSE. If this file
  --    had read the provision differently from CA_0374 and CA_0396, Indiana would hold two
  --    answers for one chamber and nothing would have said so.
  SELECT count(DISTINCT t.term_start) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND d.district_type = 'STATE_LOWER'
     AND t.term_start >= DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '3: Indiana House carries % distinct post-election term starts, expected 1. '
                    'This chamber now holds more than one answer.', n;
  END IF;

  -- 4. No term was written. That is CC_0464's job, from the date this file just recorded.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0463_sel c ON c.office_id = t.office_id
   WHERE t.term_start = DATE '2026-11-04';
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % term(s) were written. This file records a date and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0463 OK: 3 Indiana House seats dated 2026-11-04 per Ind. Const. art. 4 §3; '
               'no terms written.';
END $$;

COMMIT;
