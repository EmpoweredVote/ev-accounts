-- CC_0112_mn_counties_officials.sql
-- Knight Foundation program, wave MN-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0111, which creates the governments, chambers, 14 commissioner
-- districts and the 19 offices.
--
-- Seats all 19 St. Louis and Ramsey county offices: **19 people created**, external_id band
-- -2735100 .. -2735001. **0 vacancies.**
--
-- 🔴🔴 THE PRECISION MIX IS 5 `day` · 7 `month` · 7 `year`, AND ITS UNEVENNESS IS THE POINT.
-- MN-2 wrote all 200 legislative terms open-ended at 'unknown' because neither chamber publishes
-- a date. MN-3's 18 city terms were ALL 'day', because both cities publish one. Neither shape
-- fits here, and flattening these 19 to match either would have been a fabrication:
--
--   day    5   the five CONSTITUTIONAL OFFICERS -- both sheriffs, both county attorneys, and
--              St. Louis's auditor. Minn. Stat. s 382.01 begins their term on the first Monday
--              in January next succeeding the election. All five were elected 2022-11-08, so all
--              five start 2023-01-02. A uniform answer normally needs suspicion; here it is
--              correct BY CONSTRUCTION, because Minnesota runs every county officer on the
--              gubernatorial cycle -- and it was still corroborated from five separate election
--              results rather than inferred once and copied.
--   month  7   all seven RAMSEY commissioners. Their pages say "began her term in January 2025"
--              and give no day.
--   year   7   all seven ST. LOUIS commissioners. Their pages publish a term EXPIRY and no
--              start; the start is expiry minus the four-year term.
--
-- 🔴🔴 s 382.01's CLEAN FIRST-MONDAY RULE DOES NOT GOVERN THE BOARD, AND THE PUBLISHED DATES
-- PROVE IT. s 375.01 gives a commissioner four years "and until their successors qualify", and
-- qualification happens at the board's organizational meeting -- the first Tuesday after the
-- first Monday -- not on a fixed calendar day. St. Louis's own two expiry cohorts follow
-- DIFFERENT rules and that is how it was caught:
--
--   2027-01-04   Monday    = the first Monday of that January
--   2029-01-09   TUESDAY   the first Monday is 2029-01-01, eight days earlier
--
-- MN-3 derived Duluth's starts as expiry minus four years because every published expiry was a
-- first Monday, which Duluth's charter names. THAT ARITHMETIC DOES NOT CARRY HERE, so no
-- commissioner start is written at 'day' precision in either county.
--
-- ⚠ THREE RAMSEY COMMISSIONER ROWS WERE CORRECTED BEFORE THIS FILE WAS WRITTEN. Moran, Ortega
--   and Xiong originally carried 2023-01-02 at 'day' -- which is s 382.01's first Monday, the
--   exact date the paragraph above rules out for the board. No page states a day for any of
--   them. They are written 2023-01-01 at 'month'; the month is certain, the day was not.
--   The roster JSON carries the correction and its reason per row.
--
-- 🔴 FOUR PAGES STATE A FIRST ARRIVAL AND IT READS EXACTLY LIKE A TERM START. This is MN-3's
--   Nelsie Yang trap, four more times, and each was settled against the election record:
--     Nancy Nilsen      "sworn in on January 3, 2019"   -> re-elected 2022-11-08, 60,787-13,838
--     Rafael E. Ortega  "elected ... in 1994"           -> re-elected 2022-11-08
--     Mary Jo McGuire   "has served ... since 2012"     -> re-elected 2024-11-05
--     Gordon Ramsay     "sworn in as Sheriff on January 10, 2023" -> that is the CEREMONY;
--                       s 382.01 begins the term on 2023-01-02, and the statutory date is recorded.
--
-- 🔴 "ELECTED IN 2023" IN A BODY THAT VOTES IN EVEN YEARS, AND IT WAS NOT A SPECIAL ELECTION.
--   Ramsey District 6's page says Mai Chong Xiong was "elected in 2023". Minnesota county
--   commissioners are elected in EVEN years, so that reads as a special. It is not one: she took
--   her seat in January 2023 having been elected in November 2022. A biography's loose phrasing
--   is not an election record -- and the same instinct is what correctly found the real one.
--
-- 🔴 ONE GENUINE MID-TERM CHANGE, IN 19. Ramsey District 3: Trista Martinson resigned, and
--   Garrison McMurtrey won the SPECIAL ELECTION on 2025-02-11, beginning his term that February.
--   A blanket "elected 2024" would have been wrong for this seat and only the per-member read
--   found it. Every other one of the 19 is a regular-cycle winner.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate. The stated
--   expiries are recorded in data/mn-counties-roster.json for the audit trail and are not loaded.
--
-- ⚠ ALL FIVE CONSTITUTIONAL OFFICERS ARE ON THE 2026-11-03 BALLOT, seven weeks out. The standing
--   rule applies: seat who holds the seat TODAY. A certified result is not a fact about who holds
--   the seat; only a special-election winner starts early.
--
-- 🟢 NONE OF THE 19 NAMES COLLIDES WITH AN EXISTING POLITICIAN. Zero exact (first_name,
--   last_name) matches -- proved with a positive control that DID find MN-3's Reinert, Yang and
--   Her. Ten surnames recur in production and six of those rows are Minnesota legislators
--   (Joe McDonald, Jeremy R. Miller, Nathan Nelson, Carla J. Nelson, Jay Xiong, Tou Xiong); every
--   one has a different given name, so there is nobody to reuse.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party, never on a person or an office.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── 19 people ──────────────────────────────────────────────────────────────────

CREATE TEMP TABLE mn4_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[], source text)
  ON COMMIT DROP;
INSERT INTO mn4_people(external_id, full_name, first_name, last_name, alternate_names, source) VALUES
  (-2735001, 'Annie Harala', 'Annie', 'Harala', '{}'::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735002, 'Patrick Boyle', 'Patrick', 'Boyle', '{}'::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735003, 'Ashley Grimm', 'Ashley', 'Grimm', '{}'::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735004, 'Paul McDonald', 'Paul', 'McDonald', '{}'::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735005, 'Keith Musolf', 'Keith', 'Musolf', '{}'::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735006, 'Keith Nelson', 'Keith', 'Nelson', '{}'::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735007, 'Mike Jugovich', 'Mike', 'Jugovich', '{}'::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735008, 'Gordon Ramsay', 'Gordon', 'Ramsay', '{}'::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735009, 'Kimberly J. Maki', 'Kimberly', 'Maki', ARRAY['Kim Maki']::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735010, 'Nancy Nilsen', 'Nancy', 'Nilsen', '{}'::text[], 'St. Louis County board and department pages, https://www.stlouiscountymn.gov/our-county/board-of-commissioners ; Minn. Stat. ss 382.01, 383C.136, 375.01; GeneralUse/Open_Data/MapServer/21; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735011, 'Tara Jebens-Singh', 'Tara', 'Jebens-Singh', '{}'::text[], 'Ramsey County board and department pages, https://www.ramseycountymn.gov/your-government/leadership/board-commissioners ; Minn. Stat. ss 382.01, 383A.20, 375.01; BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735012, 'Mary Jo McGuire', 'Mary Jo', 'McGuire', '{}'::text[], 'Ramsey County board and department pages, https://www.ramseycountymn.gov/your-government/leadership/board-commissioners ; Minn. Stat. ss 382.01, 383A.20, 375.01; BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735013, 'Garrison McMurtrey', 'Garrison', 'McMurtrey', '{}'::text[], 'Ramsey County board and department pages, https://www.ramseycountymn.gov/your-government/leadership/board-commissioners ; Minn. Stat. ss 382.01, 383A.20, 375.01; BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735014, 'Rena Moran', 'Rena', 'Moran', '{}'::text[], 'Ramsey County board and department pages, https://www.ramseycountymn.gov/your-government/leadership/board-commissioners ; Minn. Stat. ss 382.01, 383A.20, 375.01; BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735015, 'Rafael E. Ortega', 'Rafael', 'Ortega', ARRAY['Rafael Ortega']::text[], 'Ramsey County board and department pages, https://www.ramseycountymn.gov/your-government/leadership/board-commissioners ; Minn. Stat. ss 382.01, 383A.20, 375.01; BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735016, 'Mai Chong Xiong', 'Mai Chong', 'Xiong', '{}'::text[], 'Ramsey County board and department pages, https://www.ramseycountymn.gov/your-government/leadership/board-commissioners ; Minn. Stat. ss 382.01, 383A.20, 375.01; BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735017, 'Kelly Miller', 'Kelly', 'Miller', '{}'::text[], 'Ramsey County board and department pages, https://www.ramseycountymn.gov/your-government/leadership/board-commissioners ; Minn. Stat. ss 382.01, 383A.20, 375.01; BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735018, 'Bob Fletcher', 'Bob', 'Fletcher', '{}'::text[], 'Ramsey County board and department pages, https://www.ramseycountymn.gov/your-government/leadership/board-commissioners ; Minn. Stat. ss 382.01, 383A.20, 375.01; BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25; change-checked against each officer''s own page, read 2026-09-15 (MN-4)'),
  (-2735019, 'John Choi', 'John', 'Choi', '{}'::text[], 'Ramsey County board and department pages, https://www.ramseycountymn.gov/your-government/leadership/board-commissioners ; Minn. Stat. ss 382.01, 383A.20, 375.01; BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer/25; change-checked against each officer''s own page, read 2026-09-15 (MN-4)');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.source, n.alternate_names
FROM mn4_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 19 dated terms, one per office ─────────────────────────────────────────────
-- The commissioner seats join through their X0054/X0055 district; the five countywide seats
-- join through the county's own G4020 COUNTY district (27137, 27123).

CREATE TEMP TABLE mn4_terms(county_geo_id text, district_geo_id text, title text, external_id bigint, term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO mn4_terms(county_geo_id, district_geo_id, title, external_id, term_start, start_precision, how_started) VALUES
  ('27137', 'st-louis-mn-commissioner-district-1', 'Commissioner, District 1', -2735001, '2023-01-01'::date, 'year', 'elected'),
  ('27137', 'st-louis-mn-commissioner-district-2', 'Commissioner, District 2', -2735002, '2025-01-01'::date, 'year', 'elected'),
  ('27137', 'st-louis-mn-commissioner-district-3', 'Commissioner, District 3', -2735003, '2025-01-01'::date, 'year', 'elected'),
  ('27137', 'st-louis-mn-commissioner-district-4', 'Commissioner, District 4', -2735004, '2023-01-01'::date, 'year', 'elected'),
  ('27137', 'st-louis-mn-commissioner-district-5', 'Commissioner, District 5', -2735005, '2025-01-01'::date, 'year', 'elected'),
  ('27137', 'st-louis-mn-commissioner-district-6', 'Commissioner, District 6', -2735006, '2023-01-01'::date, 'year', 'elected'),
  ('27137', 'st-louis-mn-commissioner-district-7', 'Commissioner, District 7', -2735007, '2025-01-01'::date, 'year', 'elected'),
  ('27137', '27137', 'Sheriff', -2735008, '2023-01-02'::date, 'day', 'elected'),
  ('27137', '27137', 'County Attorney', -2735009, '2023-01-02'::date, 'day', 'elected'),
  ('27137', '27137', 'Auditor/Treasurer', -2735010, '2023-01-02'::date, 'day', 'elected'),
  ('27123', 'ramsey-mn-commissioner-district-1', 'Commissioner, District 1', -2735011, '2025-01-01'::date, 'month', 'elected'),
  ('27123', 'ramsey-mn-commissioner-district-2', 'Commissioner, District 2', -2735012, '2025-01-01'::date, 'month', 'elected'),
  ('27123', 'ramsey-mn-commissioner-district-3', 'Commissioner, District 3', -2735013, '2025-02-01'::date, 'month', 'elected'),
  ('27123', 'ramsey-mn-commissioner-district-4', 'Commissioner, District 4', -2735014, '2023-01-01'::date, 'month', 'elected'),
  ('27123', 'ramsey-mn-commissioner-district-5', 'Commissioner, District 5', -2735015, '2023-01-01'::date, 'month', 'elected'),
  ('27123', 'ramsey-mn-commissioner-district-6', 'Commissioner, District 6', -2735016, '2023-01-01'::date, 'month', 'elected'),
  ('27123', 'ramsey-mn-commissioner-district-7', 'Commissioner, District 7', -2735017, '2025-01-01'::date, 'month', 'elected'),
  ('27123', '27123', 'Sheriff', -2735018, '2023-01-02'::date, 'day', 'elected'),
  ('27123', '27123', 'County Attorney', -2735019, '2023-01-02'::date, 'day', 'elected');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       n.source || ' (CC_0112, MN-4)'
FROM mn4_terms t
JOIN essentials.districts d ON d.geo_id = t.district_geo_id AND d.district_type::text = 'COUNTY' AND lower(d.state) = 'mn'
JOIN essentials.governments g ON g.geo_id = t.county_geo_id
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.district_id = d.id AND o.chamber_id = c.id AND o.title = t.title
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN mn4_people n ON n.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_offices int; v_seated int; v_terms int; v_undated int; v_ended int;
  v_slc int; v_ram int; v_day int; v_month int; v_year int; v_unknown int; v_distinct int;
  v_comm_day int; v_officer_wrong int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN -2735100 AND -2735001;
  IF v_people <> 19 THEN RAISE EXCEPTION 'MN-4 occupancy: expected 19 people in the reserved band, got %', v_people; END IF;

  SELECT count(*) INTO v_offices FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id IN ('27137','27123');
  IF v_offices <> 19 THEN RAISE EXCEPTION 'MN-4 occupancy: expected 19 offices, got %', v_offices; END IF;

  -- och.politician_id, never count(*): office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id rather than an absent row and count(*) passes vacuously.
  SELECT count(och.politician_id),
         count(och.politician_id) FILTER (WHERE g.geo_id = '27137'),
         count(och.politician_id) FILTER (WHERE g.geo_id = '27123'),
         count(DISTINCT och.politician_id)
    INTO v_seated, v_slc, v_ram, v_distinct
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.geo_id IN ('27137','27123');
  IF v_seated <> 19 THEN RAISE EXCEPTION 'MN-4 occupancy: expected 19 seated, got %', v_seated; END IF;
  IF v_slc <> 10 OR v_ram <> 9 THEN
    RAISE EXCEPTION 'MN-4 occupancy: expected 10 St. Louis + 9 Ramsey seated, got % + %', v_slc, v_ram;
  END IF;
  -- 🔴 Nobody holds two of these seats. An external_id collision seats the wrong person silently.
  IF v_distinct <> 19 THEN
    RAISE EXCEPTION 'MN-4 occupancy: 19 seats are held by % distinct people', v_distinct;
  END IF;

  SELECT count(*), count(*) FILTER (WHERE t.term_start IS NULL), count(*) FILTER (WHERE t.term_end IS NOT NULL),
         count(*) FILTER (WHERE t.start_precision = 'day'),
         count(*) FILTER (WHERE t.start_precision = 'month'),
         count(*) FILTER (WHERE t.start_precision = 'year'),
         count(*) FILTER (WHERE t.start_precision = 'unknown')
    INTO v_terms, v_undated, v_ended, v_day, v_month, v_year, v_unknown
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('27137','27123');
  IF v_terms <> 19 THEN RAISE EXCEPTION 'MN-4 occupancy: expected 19 term rows, got %', v_terms; END IF;
  IF v_undated <> 0 THEN RAISE EXCEPTION 'MN-4 occupancy: % term(s) carry no term_start; every one of the 19 has a source', v_undated; END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'MN-4 occupancy: % term(s) carry a term_end; a future term_end self-vacates the seat', v_ended; END IF;
  IF v_unknown <> 0 THEN RAISE EXCEPTION 'MN-4 occupancy: % term(s) at unknown precision; MN-2''s shape is not this wave''s', v_unknown; END IF;

  -- 🔴🔴 THE MIX IS THE ASSERTION. Flattening it would be a fabrication in one direction or a
  --     loss of a sourced fact in the other.
  IF v_day <> 5 OR v_month <> 7 OR v_year <> 7 THEN
    RAISE EXCEPTION 'MN-4 occupancy: precision mix is % day / % month / % year, expected 5 / 7 / 7', v_day, v_month, v_year;
  END IF;

  -- 🔴 NO COMMISSIONER MAY CARRY A DAY. s 375.01 gives no statutory day, and St. Louis's own
  --    expiries land on a Monday in one cohort and a Tuesday in the other.
  SELECT count(*) INTO v_comm_day
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.mtfcc IN ('X0054','X0055') AND t.start_precision = 'day';
  IF v_comm_day <> 0 THEN
    RAISE EXCEPTION 'MN-4 occupancy: % commissioner term(s) claim a day; s 375.01 names none', v_comm_day;
  END IF;

  -- 🔴 AND EVERY CONSTITUTIONAL OFFICER MUST CARRY ONE, at s 382.01's first Monday, 2023-01-02.
  SELECT count(*) INTO v_officer_wrong
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('27137','27123') AND d.mtfcc = 'G4020'
    AND (t.start_precision <> 'day' OR t.term_start <> DATE '2023-01-02');
  IF v_officer_wrong <> 0 THEN
    RAISE EXCEPTION 'MN-4 occupancy: % countywide officer term(s) are not 2023-01-02 at day precision', v_officer_wrong;
  END IF;

  RAISE NOTICE 'MN-4 occupancy OK: % people, % offices, % seated (% St. Louis + % Ramsey), % terms, precision % day / % month / % year, 0 undated, 0 ended',
    v_people, v_offices, v_seated, v_slc, v_ram, v_terms, v_day, v_month, v_year;
END $$;

COMMIT;
