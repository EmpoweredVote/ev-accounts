-- CC_0141_detroit_people.sql
-- Knight Foundation program, wave MI-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0140, which creates the government, districts, chambers and the
-- 18 offices.
--
-- Seats all 18 Detroit elected offices:
--    17 people created here, external_id band -2780017 .. -2780001
--     1 person REUSED  — Mary Waters already exists as a 2024 MI-13 congressional candidate
--     0 offices left unseated. DETROIT HAS NO VACANCY among its elected offices.
--
-- 🔴 THE ONE REUSED ROW, AND MI-2's LESSON APPLIED BEFORE THE GATE CAUGHT IT AGAIN.
-- `-261303` Mary Waters is the sitting at-large council member; production holds her because she
-- ran for U.S. Representative District 13. Candidate rows carry `is_incumbent = false`, and the
-- reps feed that address search serves requires
--     (is_active OR is_vacant) AND coalesce(is_incumbent, true) AND title NOT ILIKE 'Candidate for%'
-- so seating her without touching that flag would leave an at-large seat correctly filled and
-- INVISIBLE TO EVERY DETROIT RESIDENT — exactly what `REPS_FILTER_HIDDEN` caught on four
-- Michigan legislative seats in MI-2. It is fixed here in the same migration that seats her, and
-- gate 6 asserts the predicate rather than trusting the fix.
-- ▶ The name sweep ran on the GUARD'S OWN KEY (lower(first_name), lower(last_name), ACTIVE rows
--   only) across all 18 and returned exactly one hit — this one. No namesake override is needed,
--   so the duplicate guard stays LIVE for all 17 inserts.
--
-- 🔴 ONLY ONE TERM IS DATED, AND THE REASON MATTERS MORE THAN THE DATE.
--   · Mayor Mary Sheffield — 2026-01-01, `day`. She was sworn in as Detroit's 76th mayor on
--     2026-01-01, independently reported, and the office was open (Mike Duggan did not seek a
--     fourth term). Detroit's first woman mayor.
--   · The other 17 are open-ended at `unknown`.
-- 🔴🔴 AND THE REASON IS NOT "DETROIT PUBLISHES NOTHING" — IT IS THAT 2026-01-01 WOULD BE FALSE
-- FOR MOST OF THEM. All 18 offices were on the 2025-11-04 ballot and the winners' current TERM
-- began 2026-01-01, but `office_terms` records OCCUPANCY, not the current term: seven of the
-- nine council members were RE-ELECTED and have held their seats continuously for years — James
-- Tate since 2010. Writing 2026-01-01 for them would assert they arrived this year. ⚠ And their
-- own pages give the other trap: Tate's says "since November 2009" and "since 2010", which is
-- a FIRST election, not an occupancy start, and the two dates do not even agree with each other.
-- ▶ This is Akron exactly: the mayor is dated because the city published an oath date, and the
--   council is not, because a blanket rule would be wrong for the rows it does not govern.
-- ▶ Dating the other 17 arrivals is a recorded debt.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 THREE OF THE SEVEN POLICE COMMISSIONERS WON AS WRITE-IN CANDIDATES. Districts 1, 2 and 3
-- had NO candidate on the 2025 ballot and were won on write-ins (Ivey, Williams, Morris). They
-- are elected officeholders and are seated exactly like the other four; the fact is recorded
-- because "no candidate filed" is the shape that usually means a vacancy, and here it does not.
--
-- 🔴 THE ROSTER WAS CHANGE-CHECKED PAGE BY PAGE, NOT TAKEN FROM AN INDEX. All 17 individual
-- member pages plus the Mayor's Office page were fetched from detroitmi.gov and every one names
-- its own officeholder in the page body.
-- ⚠ `detroitmi.gov` sits behind a Cloudflare interstitial that answers a plain fetch with HTTP
--   403 "Just a moment...", so the sweep ran inside a real browser session and issued the 18
--   requests same-origin, which is what made the challenge cookie apply.
-- ⚠ A "does the page's own <title>/<h1> name them" test — the one that caught a dead member link
--   in MI-2 — reported 17 of 17 here and is NOT a finding: Detroit titles its pages by OFFICE
--   ("City Council District 2"), not by person. 17 of 17 is a uniform answer, and the uniform
--   answer was the test not matching this site's convention.
--
-- 🔴 PARTY IS NOT WRITTEN. Detroit's municipal elections are non-partisan in any case; party
-- lives on races.primary_party.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id),
-- and the at-large pair is assigned by a deterministic ordinal.

BEGIN;

-- ─── 1. The 17 new people ─────────────────────────────────────────────────────
CREATE TEMP TABLE det_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO det_people(external_id, full_name, first_name, last_name) VALUES
  (-2780001, 'Mary Sheffield',            'Mary',      'Sheffield'),
  (-2780002, 'Janice M. Winfrey',         'Janice',    'Winfrey'),
  (-2780003, 'James Tate',                'James',     'Tate'),
  (-2780004, 'Angela Whitfield-Calloway', 'Angela',    'Whitfield-Calloway'),
  (-2780005, 'Scott Benson',              'Scott',     'Benson'),
  (-2780006, 'Latisha Johnson',           'Latisha',   'Johnson'),
  (-2780007, 'Renata Miller',             'Renata',    'Miller'),
  (-2780008, 'Gabriela Santiago-Romero',  'Gabriela',  'Santiago-Romero'),
  (-2780009, 'Denzel Anton McCampbell',   'Denzel',    'McCampbell'),
  (-2780010, 'Coleman A. Young II',       'Coleman',   'Young'),
  (-2780011, 'Henrietta Ivey',            'Henrietta', 'Ivey'),
  (-2780012, 'Lavish T. Williams',        'Lavish',    'Williams'),
  (-2780013, 'Darious Morris',            'Darious',   'Morris'),
  (-2780014, 'Scott Boman',               'Scott',     'Boman'),
  (-2780015, 'Beverly J. Watts',          'Beverly',   'Watts'),
  (-2780016, 'Lisa Carter',               'Lisa',      'Carter'),
  (-2780017, 'Victoria Camille',          'Victoria',  'Camille');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       $$City of Detroit official pages, detroitmi.gov — /government/city-council and each member's own page, /government/boards/board-police-commissioners and each commissioner's own page, /government/city-clerk and /government/mayors-office; office inventory from the 2012 Detroit City Charter's enumeration of "the elective officers of the city"; change-checked against all 18 individual pages, every one of which names its own officeholder; read 2026-09-24 (MI-3) (CC_0141, MI-3)$$,
       true, true
FROM det_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The reused row is an INCUMBENT now ────────────────────────────────────
-- See the header. Guarded on the current value, so a re-run updates 0 rows.
UPDATE essentials.politicians
   SET is_incumbent = true
 WHERE external_id = -261303
   AND is_incumbent IS DISTINCT FROM true;

-- ─── 3. The 18 terms ──────────────────────────────────────────────────────────
-- `ord` disambiguates the two at-large council seats, which share a title and a district.
CREATE TEMP TABLE det_terms(chamber_name text, title text, ord int, external_id bigint,
                            term_start date, start_precision text) ON COMMIT DROP;

INSERT INTO det_terms(chamber_name, title, ord, external_id, term_start, start_precision) VALUES
  ('Office of the Mayor',      'Mayor',      1, -2780001, DATE '2026-01-01', 'day'),
  ('Office of the City Clerk', 'City Clerk', 1, -2780002, NULL, 'unknown'),
  ('Detroit City Council', 'Council Member, District 1', 1, -2780003, NULL, 'unknown'),
  ('Detroit City Council', 'Council Member, District 2', 1, -2780004, NULL, 'unknown'),
  ('Detroit City Council', 'Council Member, District 3', 1, -2780005, NULL, 'unknown'),
  ('Detroit City Council', 'Council Member, District 4', 1, -2780006, NULL, 'unknown'),
  ('Detroit City Council', 'Council Member, District 5', 1, -2780007, NULL, 'unknown'),
  ('Detroit City Council', 'Council Member, District 6', 1, -2780008, NULL, 'unknown'),
  ('Detroit City Council', 'Council Member, District 7', 1, -2780009, NULL, 'unknown'),
  ('Detroit City Council', 'Council Member, At Large',   1, -2780010, NULL, 'unknown'),
  ('Detroit City Council', 'Council Member, At Large',   2,  -261303, NULL, 'unknown'),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 1', 1, -2780011, NULL, 'unknown'),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 2', 1, -2780012, NULL, 'unknown'),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 3', 1, -2780013, NULL, 'unknown'),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 4', 1, -2780014, NULL, 'unknown'),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 5', 1, -2780015, NULL, 'unknown'),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 6', 1, -2780016, NULL, 'unknown'),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 7', 1, -2780017, NULL, 'unknown');

WITH ranked AS (
  SELECT o.id AS office_id, o.title, c.name AS chamber_name,
         row_number() OVER (PARTITION BY c.id, o.title ORDER BY o.id) AS ord
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Detroit, Michigan, US'
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT r.office_id, p.id, t.term_start, NULL, t.start_precision, 'unknown',
       $$City of Detroit official pages, detroitmi.gov, read 2026-09-24; Mayor's 2026-01-01 arrival from the reported swearing-in of Detroit's 76th mayor (CC_0141, MI-3)$$
FROM det_terms t
JOIN ranked r ON r.chamber_name = t.chamber_name AND r.title = t.title AND r.ord = t.ord
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = r.office_id AND ot.politician_id = p.id);

-- ─── post-verify gate ─────────────────────────────────────────────────────────
DO $gate$
DECLARE
  v_terms integer; v_seated integer; v_people integer; v_dated integer;
  v_ended integer; v_two integer; v_hidden integer; v_waters integer;
BEGIN
  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Detroit, Michigan, US';
  IF v_terms <> 18 THEN RAISE EXCEPTION 'MI-3 gate 1: expected 18 terms, found %', v_terms; END IF;

  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2780017 AND -2780001;
  IF v_people <> 17 THEN RAISE EXCEPTION 'MI-3 gate 2: expected 17 new people in the MI-3 band, found %', v_people; END IF;

  -- 🔴 Count och.politician_id, not och.*: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL holder and count(*) passes vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Detroit, Michigan, US';
  IF v_seated <> 18 THEN RAISE EXCEPTION 'MI-3 gate 3: expected 18 seated offices, found %', v_seated; END IF;

  SELECT count(*) FILTER (WHERE t.term_start IS NOT NULL),
         count(*) FILTER (WHERE t.term_end IS NOT NULL)
    INTO v_dated, v_ended
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Detroit, Michigan, US';
  IF v_dated <> 1 THEN RAISE EXCEPTION 'MI-3 gate 4: exactly ONE Detroit term is dated (the Mayor); found %', v_dated; END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'MI-3 gate 5: % term(s) carry a term_end — a future end silently self-vacates the seat', v_ended; END IF;

  -- The exclusion constraint forbids two people on one office; it cannot see one person on two.
  SELECT count(*) INTO v_two FROM (
    SELECT t.politician_id FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Detroit, Michigan, US'
     GROUP BY t.politician_id HAVING count(*) > 1) x;
  IF v_two <> 0 THEN RAISE EXCEPTION 'MI-3 gate 6: % person(s) hold two Detroit offices', v_two; END IF;

  -- 🔴 MI-2's defect, asserted rather than trusted: every seated Detroit official must survive
  -- the reps-feed predicate, not merely exist.
  SELECT count(*) INTO v_hidden
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Detroit, Michigan, US'
     AND NOT ((p.is_active = true OR o.is_vacant = true)
              AND coalesce(p.is_incumbent, true) = true
              AND coalesce(o.title, '') NOT ILIKE 'Candidate for%');
  IF v_hidden <> 0 THEN
    RAISE EXCEPTION 'MI-3 gate 7: % seated Detroit official(s) are hidden from the reps feed', v_hidden;
  END IF;

  SELECT count(*) INTO v_waters
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Detroit, Michigan, US' AND p.external_id = -261303;
  IF v_waters <> 1 THEN RAISE EXCEPTION 'MI-3 gate 8: the reused Mary Waters row should hold exactly 1 Detroit seat, found %', v_waters; END IF;

  RAISE NOTICE 'CC_0141 OK: 18 terms, 18 seated, 17 new people, 1 reused, 1 dated (the Mayor), 0 hidden from the reps feed.';
END
$gate$;

COMMIT;
