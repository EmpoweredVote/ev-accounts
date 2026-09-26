-- CC_0153_lexington_fayette_incumbents.sql
-- Knight Foundation program, wave KY-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0152.
--
-- Seats all 16 elected officials of the Lexington-Fayette Urban County Government: the Mayor, three
-- at-large council members and twelve district council members. 16 people, 16 terms, 0 vacancies.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE OATH DATE IS NOT A RULE AND MUST NOT BE COMPUTED. Whitney Elliott Baxter assumed office
-- 2021-01-04 (a Monday) and Lisa Higgins-Hord's appointment runs through 2027-01-04 (a Monday),
-- which invites "the first Monday in January". The city's OWN record says the 2025-26 district
-- members took the oath on SUNDAY, JANUARY 12, 2025, at the Lexington Senior Center, administered
-- by Fayette District Judge Denotra Gunther. Computing the first Monday would have written
-- 2025-01-06 for five members -- wrong by six days. This is ND-3's finding, reproduced.
--
-- THAT CEREMONY RE-SWORE ALL TWELVE DISTRICT MEMBERS, INCUMBENTS INCLUDED, so 2025-01-12 is the
-- start of the 2025-26 TERM, not of continuous occupancy. It is used only for the five members the
-- archived-roster timeline shows ARRIVING then -- absent 2024-12-22, present 2025-01-17.
-- office_terms carries CONTINUOUS OCCUPANCY (North Carolina's rows reach back to 1999-01-01), so an
-- incumbent's re-swearing must never overwrite an earlier start.
--
-- TWO GAP CASES, the trap KY-2 found at state level: Chuck Ellinger II served at-large 2003-2014 and
-- returned in 2019; James Brown moved from a DISTRICT seat to at-large in 2022. Neither's first year
-- on the Council starts the seat he holds now.
--
-- TWO MEMBERS WERE APPOINTED, NOT ELECTED, and how_started records the difference: Lisa Higgins-Hord
-- (District 6, 2025-08-22, after Denise Gray resigned effective 2025-07-31) and Tom Eblen
-- (District 3, 2026-02-03, filling Hannah LeGris' unexpired term). Both dates come from the city's
-- own publications, which is the only thing that dates an appointed arrival.
--
-- NO NAMESAKES. All 16 names were checked against existing politicians and none collided; the
-- check was CONTROLLED with names known to exist (Steven Rudy and Gary Clemons, both seated by
-- KY-2, each returned 1), so the zero is a real answer and not a broken query.
-- external_id block -2762800..-2762785 measured EMPTY and clear of KY-2's -2763000..-2762863.
--
-- 'Shayla Lynch, J.D.' is published with a credential; the credential is not part of the name and
-- is not written.
-- Party is NOT written. Party is antipartisan and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 1. The 16 people ─────────────────────────────────────────────────────────

CREATE TEMP TABLE lex_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO lex_people(external_id, full_name, first_name, last_name) VALUES
  (-2762800, 'Linda Gorton', 'Linda', 'Gorton'),
  (-2762799, 'Dan Wu', 'Dan', 'Wu'),
  (-2762798, 'James Brown', 'James', 'Brown'),
  (-2762797, 'Chuck Ellinger II', 'Chuck', 'II'),
  (-2762796, 'Tyler Morton', 'Tyler', 'Morton'),
  (-2762795, 'Shayla Lynch', 'Shayla', 'Lynch'),
  (-2762794, 'Tom Eblen', 'Tom', 'Eblen'),
  (-2762793, 'Emma Curtis', 'Emma', 'Curtis'),
  (-2762792, 'Liz Sheehan', 'Liz', 'Sheehan'),
  (-2762791, 'Lisa Higgins-Hord', 'Lisa', 'Higgins-Hord'),
  (-2762790, 'Joseph Hale', 'Joseph', 'Hale'),
  (-2762789, 'Amy Beasley', 'Amy', 'Beasley'),
  (-2762788, 'Whitney Elliott Baxter', 'Whitney', 'Baxter'),
  (-2762787, 'Dave Sevigny', 'Dave', 'Sevigny'),
  (-2762786, 'Jennifer Reynolds', 'Jennifer', 'Reynolds'),
  (-2762785, 'Hil Boone', 'Hil', 'Boone');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Lexington-Fayette Urban County Government. Roster read from the city''s own Councilmembers page and all 15 individual member pages at lexingtonky.gov, cross-checked against 17 archived copies of the same roster (2024-12 to 2026-06) which supplied the arrival windows. Arrival days from the city''s own records: the 2025-01-12 swearing-in announcement, and the two appointment notices (Higgins-Hord 2025-08-22, Eblen 2026-02-03). Where no day is published the year of first taking the seat is used at year precision. Read 2026-09-26 (KY-3) (CC_0153, KY-3)', true, true
FROM lex_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 16 terms ──────────────────────────────────────────────────────────
--
-- The three at-large offices are interchangeable rows on one district with one title, so they are
-- matched by ROW NUMBER, not by any distinguishing attribute -- Arizona's and Duluth's shape.

CREATE TEMP TABLE lex_terms(
  external_id bigint, geo_id text, chamber_formal text, title text, slot int,
  term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO lex_terms(external_id, geo_id, chamber_formal, title, slot, term_start, start_precision, how_started) VALUES
  (-2762800, '2146027', 'Office of the Mayor of Lexington-Fayette, Kentucky', 'Mayor', 0, DATE '2019-01-01', 'year', 'elected'),
  (-2762799, '2146027', 'Lexington-Fayette Urban County Council', 'Council Member, At-Large', 0, DATE '2023-01-01', 'year', 'elected'),
  (-2762798, '2146027', 'Lexington-Fayette Urban County Council', 'Council Member, At-Large', 1, DATE '2023-01-01', 'year', 'elected'),
  (-2762797, '2146027', 'Lexington-Fayette Urban County Council', 'Council Member, At-Large', 2, DATE '2019-01-01', 'year', 'elected'),
  (-2762796, 'lexington-fayette-ky-council-district-1', 'Lexington-Fayette Urban County Council', 'Council Member, District 1', 0, DATE '2025-01-12', 'day', 'elected'),
  (-2762795, 'lexington-fayette-ky-council-district-2', 'Lexington-Fayette Urban County Council', 'Council Member, District 2', 0, DATE '2023-01-01', 'year', 'elected'),
  (-2762794, 'lexington-fayette-ky-council-district-3', 'Lexington-Fayette Urban County Council', 'Council Member, District 3', 0, DATE '2026-02-03', 'day', 'appointed'),
  (-2762793, 'lexington-fayette-ky-council-district-4', 'Lexington-Fayette Urban County Council', 'Council Member, District 4', 0, DATE '2025-01-12', 'day', 'elected'),
  (-2762792, 'lexington-fayette-ky-council-district-5', 'Lexington-Fayette Urban County Council', 'Council Member, District 5', 0, DATE '2021-01-01', 'year', 'elected'),
  (-2762791, 'lexington-fayette-ky-council-district-6', 'Lexington-Fayette Urban County Council', 'Council Member, District 6', 0, DATE '2025-08-22', 'day', 'appointed'),
  (-2762790, 'lexington-fayette-ky-council-district-7', 'Lexington-Fayette Urban County Council', 'Council Member, District 7', 0, DATE '2025-01-12', 'day', 'elected'),
  (-2762789, 'lexington-fayette-ky-council-district-8', 'Lexington-Fayette Urban County Council', 'Council Member, District 8', 0, DATE '2025-01-12', 'day', 'elected'),
  (-2762788, 'lexington-fayette-ky-council-district-9', 'Lexington-Fayette Urban County Council', 'Council Member, District 9', 0, DATE '2021-01-01', 'year', 'elected'),
  (-2762787, 'lexington-fayette-ky-council-district-10', 'Lexington-Fayette Urban County Council', 'Council Member, District 10', 0, DATE '2023-01-01', 'year', 'elected'),
  (-2762786, 'lexington-fayette-ky-council-district-11', 'Lexington-Fayette Urban County Council', 'Council Member, District 11', 0, DATE '2019-01-01', 'year', 'elected'),
  (-2762785, 'lexington-fayette-ky-council-district-12', 'Lexington-Fayette Urban County Council', 'Council Member, District 12', 0, DATE '2025-01-12', 'day', 'elected');

WITH office_slots AS (
  SELECT o.id AS office_id, c.name_formal AS chamber_formal, d.geo_id, o.title,
         (row_number() OVER (PARTITION BY c.name_formal, d.geo_id, o.title ORDER BY o.id) - 1)::int AS slot
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Lexington-Fayette Urban County Council', 'Office of the Mayor of Lexington-Fayette, Kentucky')
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, t.term_start, NULL, t.start_precision, t.how_started, 'Lexington-Fayette Urban County Government. Roster read from the city''s own Councilmembers page and all 15 individual member pages at lexingtonky.gov, cross-checked against 17 archived copies of the same roster (2024-12 to 2026-06) which supplied the arrival windows. Arrival days from the city''s own records: the 2025-01-12 swearing-in announcement, and the two appointment notices (Higgins-Hord 2025-08-22, Eblen 2026-02-03). Where no day is published the year of first taking the seat is used at year precision. Read 2026-09-26 (KY-3) (CC_0153, KY-3)'
FROM lex_terms t
JOIN office_slots os
  ON os.geo_id = t.geo_id AND os.chamber_formal = t.chamber_formal
 AND os.title = t.title AND os.slot = t.slot
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id);

-- ─── 3. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_day int; v_year int; v_unknown int;
  v_appointed int; v_ended int; v_dupes int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2762800 AND -2762785;
  IF v_people <> 16 THEN RAISE EXCEPTION 'CC_0153: expected 16 people, got %', v_people; END IF;

  SELECT count(*), count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown'),
         count(*) FILTER (WHERE ot.how_started = 'appointed'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_terms, v_day, v_year, v_unknown, v_appointed, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Lexington-Fayette Urban County Council', 'Office of the Mayor of Lexington-Fayette, Kentucky');

  IF v_terms <> 16 THEN RAISE EXCEPTION 'CC_0153: expected 16 terms, got %', v_terms; END IF;
  IF v_day <> 7 THEN RAISE EXCEPTION 'CC_0153: expected 7 day-precision terms, got %', v_day; END IF;
  IF v_year <> 9 THEN RAISE EXCEPTION 'CC_0153: expected 9 year-precision terms, got %', v_year; END IF;
  IF v_unknown <> 0 THEN RAISE EXCEPTION 'CC_0153: % term(s) have unknown precision; this wave dates every seat', v_unknown; END IF;
  IF v_appointed <> 2 THEN RAISE EXCEPTION 'CC_0153: expected 2 appointed arrivals, got %', v_appointed; END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'CC_0153: % term(s) already ended', v_ended; END IF;

  -- Count och.politician_id, never rows: office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.name_formal IN ('Lexington-Fayette Urban County Council', 'Office of the Mayor of Lexington-Fayette, Kentucky');
  IF v_seated <> 16 THEN RAISE EXCEPTION 'CC_0153: expected 16 seated, got %', v_seated; END IF;

  SELECT count(*) INTO v_dupes FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.name_formal IN ('Lexington-Fayette Urban County Council', 'Office of the Mayor of Lexington-Fayette, Kentucky')
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dupes <> 0 THEN RAISE EXCEPTION 'CC_0153: % person/people hold more than one Lexington seat', v_dupes; END IF;

  RAISE NOTICE 'CC_0153 OK: 16 people, 16 terms, 16 seated, % day / % year / 0 unknown, % appointed', v_day, v_year, v_appointed;
END $$;

COMMIT;
