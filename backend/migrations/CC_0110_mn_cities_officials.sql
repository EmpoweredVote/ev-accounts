-- CC_0110_mn_cities_officials.sql
-- Knight Foundation program, wave MN-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0109, which creates the governments, chambers, districts and the
-- 18 offices.
--
-- Seats all 18 Duluth and Saint Paul city offices: **18 people created**, external_id band
-- -2734100 .. -2734001. **0 vacancies.**
--
-- 🟢 EVERY TERM IS DATED, AND THAT IS UNUSUAL FOR THIS PROGRAM. MN-2 wrote all 200 legislative
-- terms open-ended at 'unknown' because neither chamber publishes a date. Both cities do, so all
-- 18 of these carry a real term_start at 'day' precision:
--
--   2024-01-01  6  Duluth, elected November 2023 -- first Monday in January
--   2026-01-05  4  Duluth, elected November 2025 -- first Monday in January
--   2024-01-09  6  Saint Paul council, sworn in at the Ordway Center
--   2025-08-27  1  Saint Paul Ward 4, sworn in after the 2025-08-12 special election
--   2026-01-02  1  Saint Paul Mayor, sworn in as the city's 56th mayor
--
-- Duluth's boundary is the charter's own: ch. II s 4 has an appointee serve "until the first
-- Monday in January after the next municipal election", and every term-expiry date the city
-- publishes -- 2028-01-03, 2030-01-07 -- is a first Monday. The start is therefore derived from
-- the city's OWN published dates plus the charter's four-year term, not invented.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate. The stated
-- expiries are recorded in data/mn-cities-roster.json for the audit trail and are not loaded.
--
-- 🔴🔴 THE CHANGE-CHECK SIGNAL FOR A CITY COUNCIL IS AN EXPIRED DATE, NOT A BANNER. A word
-- scanner over all 18 member pages -- resigned, vacant, appointed, sworn in, stepping down,
-- interim -- returned ONE benign biographical hit, and all six of its positive controls fired.
-- It was still blind: Terese Tomanek's page says "Term Expires: January 5, 2026", read on
-- 2026-09-14. Nothing on the page is worded as a problem. ⚠ A control proves a detector is not
-- broken; it cannot prove the detector is looking at the right thing.
--
-- 🔴 ALL FOUR DULUTH AT-LARGE PAGES STATE THE SAME EXPIRED DATE, and the roster is right while
-- the pages are wrong. The DISTRIBUTION gave it away -- Duluth staggers its council, so its
-- expiries must not be uniform. November 2023 elected Forsman and Nephew at large; November 2025
-- elected Tomanek (re-elected) and Johnson (a newcomer, whose page states an expiry that predates
-- his own term). Settled against the election record, not against the page.
--
-- 🔴 THREE SEATS HAD TURNED OVER MID-TERM AND EACH WAS READ:
--   Duluth District 2  -- Mike Mayou resigned on moving out of the district; Deborah DeLuca was
--                         appointed INTERIM by unanimous council vote and served until the first
--                         Monday in January, as the charter requires; Diane Desotelle won the
--                         November general with 80%. The interim holder is NOT modelled: this
--                         wave seats who holds the seat today.
--   Duluth District 4  -- appeared in BOTH the 2023 and 2025 election listings, which read as a
--                         contradiction until the special election to the unexpired PARTIAL term
--                         explained it. Clanaugh beat Swenson in November 2025, 53% to 46%.
--   Saint Paul Ward 4  -- Council President Mitra Jalali resigned effective 2025-03-08; Molly
--                         Coleman won the 2025-08-12 special and was sworn in 2025-08-27. ⚠ Saint
--                         Paul's own council index says flatly that "Councilmembers were elected
--                         to a 4-year term in 2023", which is WRONG FOR THIS SEAT.
--
-- 🟢 NONE OF THE 18 NAMES COLLIDES WITH AN ACTIVE POLITICIAN ROW. Zero exact
-- (first_name, last_name) matches, so essentials.politician_name_duplicate_guard blocks nothing
-- and there is nobody to reuse. ⚠ Kaohly Her exists in production under NO spelling -- checked
-- '%kaohly%' -- even though she is the same person the Minnesota House's Leadership tab still
-- lists for HD-64A. She left that seat by defeating the incumbent mayor on 2025-11-04, which is
-- what MN-2 found and could not explain from House sources alone.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party, never on a person or an office.
-- Duluth's municipal elections are non-partisan by charter (ch. VI s 38) in any case.
--
-- 🔴 DULUTH'S FOUR AT-LARGE OFFICES SHARE ONE TITLE, so a person is joined to a seat through the
-- INTERNAL ordinal CC_0109 wrote into `description`. Nothing reads that as a seat name.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── 18 people ──────────────────────────────────────────────────────────────────

CREATE TEMP TABLE mn3_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[], source text)
  ON COMMIT DROP;
INSERT INTO mn3_people(external_id, full_name, first_name, last_name, alternate_names, source) VALUES
  (-2734001, 'Wendy Durrwachter', 'Wendy', 'Durrwachter', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734002, 'Diane Desotelle', 'Diane', 'Desotelle', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734003, 'Roz Randorf', 'Roz', 'Randorf', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734004, 'David Clanaugh', 'David', 'Clanaugh', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734005, 'Janet Kennedy', 'Janet', 'Kennedy', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734006, 'Arik Forsman', 'Arik', 'Forsman', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734007, 'Lynn Marie Nephew', 'Lynn', 'Nephew', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734008, 'Jordon Johnson', 'Jordon', 'Johnson', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734009, 'Terese Tomanek', 'Terese', 'Tomanek', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734010, 'Roger J. Reinert', 'Roger', 'Reinert', '{}'::text[], 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734011, 'Anika Bowie', 'Anika', 'Bowie', '{}'::text[], 'City of Saint Paul council and mayor pages, https://www.stpaul.gov/department/city-council ; Saint Paul City Charter; Council_Ward_/FeatureServer/0; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734012, 'Rebecca Noecker', 'Rebecca', 'Noecker', '{}'::text[], 'City of Saint Paul council and mayor pages, https://www.stpaul.gov/department/city-council ; Saint Paul City Charter; Council_Ward_/FeatureServer/0; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734013, 'Saura Jost', 'Saura', 'Jost', '{}'::text[], 'City of Saint Paul council and mayor pages, https://www.stpaul.gov/department/city-council ; Saint Paul City Charter; Council_Ward_/FeatureServer/0; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734014, 'Molly Coleman', 'Molly', 'Coleman', '{}'::text[], 'City of Saint Paul council and mayor pages, https://www.stpaul.gov/department/city-council ; Saint Paul City Charter; Council_Ward_/FeatureServer/0; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734015, 'HwaJeong Kim', 'HwaJeong', 'Kim', ARRAY['Hwa Jeong Kim']::text[], 'City of Saint Paul council and mayor pages, https://www.stpaul.gov/department/city-council ; Saint Paul City Charter; Council_Ward_/FeatureServer/0; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734016, 'Nelsie Yang', 'Nelsie', 'Yang', '{}'::text[], 'City of Saint Paul council and mayor pages, https://www.stpaul.gov/department/city-council ; Saint Paul City Charter; Council_Ward_/FeatureServer/0; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734017, 'Cheniqua Johnson', 'Cheniqua', 'Johnson', '{}'::text[], 'City of Saint Paul council and mayor pages, https://www.stpaul.gov/department/city-council ; Saint Paul City Charter; Council_Ward_/FeatureServer/0; change-checked against each member’s own page, read 2026-09-14 (MN-3)'),
  (-2734018, 'Kaohly Her', 'Kaohly', 'Her', ARRAY['Kaohly Vang Her']::text[], 'City of Saint Paul council and mayor pages, https://www.stpaul.gov/department/city-council ; Saint Paul City Charter; Council_Ward_/FeatureServer/0; change-checked against each member’s own page, read 2026-09-14 (MN-3)');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.source, n.alternate_names
FROM mn3_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 18 dated terms, one per office ─────────────────────────────────────────────

CREATE TEMP TABLE mn3_terms(place_geo_id text, district_geo_id text, title text, description text, external_id bigint, term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO mn3_terms(place_geo_id, district_geo_id, title, description, external_id, term_start, start_precision, how_started) VALUES
  ('2717000', 'duluth-mn-council-district-1', 'Councilor, District 1', NULL, -2734001, '2024-01-01'::date, 'day', 'elected'),
  ('2717000', 'duluth-mn-council-district-2', 'Councilor, District 2', NULL, -2734002, '2026-01-05'::date, 'day', 'elected'),
  ('2717000', 'duluth-mn-council-district-3', 'Councilor, District 3', NULL, -2734003, '2024-01-01'::date, 'day', 'elected'),
  ('2717000', 'duluth-mn-council-district-4', 'Councilor, District 4', NULL, -2734004, '2026-01-05'::date, 'day', 'elected'),
  ('2717000', 'duluth-mn-council-district-5', 'Councilor, District 5', NULL, -2734005, '2024-01-01'::date, 'day', 'elected'),
  ('2717000', '2717000', 'Councilor, At Large', 'Internal ordinal 1 of 4. Duluth does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.', -2734006, '2024-01-01'::date, 'day', 'elected'),
  ('2717000', '2717000', 'Councilor, At Large', 'Internal ordinal 2 of 4. Duluth does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.', -2734007, '2024-01-01'::date, 'day', 'elected'),
  ('2717000', '2717000', 'Councilor, At Large', 'Internal ordinal 3 of 4. Duluth does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.', -2734008, '2026-01-05'::date, 'day', 'elected'),
  ('2717000', '2717000', 'Councilor, At Large', 'Internal ordinal 4 of 4. Duluth does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.', -2734009, '2026-01-05'::date, 'day', 'elected'),
  ('2717000', '2717000', 'Mayor', NULL, -2734010, '2024-01-01'::date, 'day', 'elected'),
  ('2758000', 'saint-paul-mn-ward-1', 'Councilmember, Ward 1', NULL, -2734011, '2024-01-09'::date, 'day', 'elected'),
  ('2758000', 'saint-paul-mn-ward-2', 'Councilmember, Ward 2', NULL, -2734012, '2024-01-09'::date, 'day', 'elected'),
  ('2758000', 'saint-paul-mn-ward-3', 'Councilmember, Ward 3', NULL, -2734013, '2024-01-09'::date, 'day', 'elected'),
  ('2758000', 'saint-paul-mn-ward-4', 'Councilmember, Ward 4', NULL, -2734014, '2025-08-27'::date, 'day', 'elected'),
  ('2758000', 'saint-paul-mn-ward-5', 'Councilmember, Ward 5', NULL, -2734015, '2024-01-09'::date, 'day', 'elected'),
  ('2758000', 'saint-paul-mn-ward-6', 'Councilmember, Ward 6', NULL, -2734016, '2024-01-09'::date, 'day', 'elected'),
  ('2758000', 'saint-paul-mn-ward-7', 'Councilmember, Ward 7', NULL, -2734017, '2024-01-09'::date, 'day', 'elected'),
  ('2758000', '2758000', 'Mayor', NULL, -2734018, '2026-01-02'::date, 'day', 'elected');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       n.source || ' (CC_0110, MN-3)'
FROM mn3_terms t
JOIN essentials.districts d ON d.geo_id = t.district_geo_id AND d.district_type::text = 'LOCAL' AND lower(d.state) = 'mn'
JOIN essentials.governments g ON g.geo_id = t.place_geo_id
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.district_id = d.id AND o.chamber_id = c.id AND o.title = t.title
  AND o.description IS NOT DISTINCT FROM t.description
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN mn3_people n ON n.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_offices int; v_seated int; v_terms int; v_undated int; v_ended int;
  v_duluth int; v_stpaul int; v_distinct_al int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN -2734100 AND -2734001;
  IF v_people <> 18 THEN RAISE EXCEPTION 'MN-3 occupancy: expected 18 people in the reserved band, got %', v_people; END IF;

  SELECT count(*) INTO v_offices FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id IN ('2717000','2758000');
  IF v_offices <> 18 THEN RAISE EXCEPTION 'MN-3 occupancy: expected 18 offices, got %', v_offices; END IF;

  -- och.politician_id, never count(*): office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id),
         count(och.politician_id) FILTER (WHERE g.geo_id = '2717000'),
         count(och.politician_id) FILTER (WHERE g.geo_id = '2758000')
    INTO v_seated, v_duluth, v_stpaul
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.geo_id IN ('2717000','2758000');
  IF v_seated <> 18 THEN RAISE EXCEPTION 'MN-3 occupancy: expected 18 seated, got %', v_seated; END IF;
  IF v_duluth <> 10 OR v_stpaul <> 8 THEN
    RAISE EXCEPTION 'MN-3 occupancy: expected 10 Duluth + 8 Saint Paul, got % + %', v_duluth, v_stpaul;
  END IF;

  SELECT count(*), count(*) FILTER (WHERE t.term_start IS NULL), count(*) FILTER (WHERE t.term_end IS NOT NULL)
    INTO v_terms, v_undated, v_ended
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('2717000','2758000');
  IF v_terms <> 18 THEN RAISE EXCEPTION 'MN-3 occupancy: expected 18 term rows, got %', v_terms; END IF;
  -- 🟢 Unlike MN-2, EVERY term here is dated. An undated one means a source was lost.
  IF v_undated <> 0 THEN RAISE EXCEPTION 'MN-3 occupancy: % term(s) carry no term_start; both cities publish one', v_undated; END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'MN-3 occupancy: % term(s) carry a term_end; a future term_end self-vacates the seat', v_ended; END IF;

  -- Duluth's four at-large offices must hold FOUR DIFFERENT people.
  SELECT count(DISTINCT och.politician_id) INTO v_distinct_al
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.geo_id = '2717000' AND o.title = 'Councilor, At Large';
  IF v_distinct_al <> 4 THEN
    RAISE EXCEPTION 'MN-3 occupancy: Duluth at-large seats hold % distinct people, expected 4', v_distinct_al;
  END IF;

  RAISE NOTICE 'MN-3 occupancy OK: % people, % offices, % seated (% Duluth + % Saint Paul), % terms, 0 undated, 0 ended, % distinct at-large',
    v_people, v_offices, v_seated, v_duluth, v_stpaul, v_terms, v_distinct_al;
END $$;

COMMIT;
