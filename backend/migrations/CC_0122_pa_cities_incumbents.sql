-- CC_0122_pa_cities_incumbents.sql
-- Knight Foundation program, wave PA-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0121.
--
-- Seats all 26 offices: Philadelphia 18 (Mayor + 10 district + 7 at-large) and State College 8
-- (Mayor + 7 at-large). 25 people created with the duplicate-name guard ARMED, 1 with it lifted,
-- 0 reused. external_id band -2743026 .. -2743001. NO vacancies — every seat is filled today.
--
-- 🟢 FOUR ARRIVALS ARE DOCUMENTED AND ARE WRITTEN AT THE PRECISION THE SOURCE SUPPORTS:
--   Cherelle L. Parker (Mayor) — 2024-01-01 at day precision, how_started 'elected'.
--     Cherelle L. Parker took the oath privately on Monday 2024-01-01 and was publicly sworn in as the city''s 100th mayor on 2024-01-02. The tenure starts at the oath; the ceremony is a ceremony.
--   Michael Driscoll (Councilmember, District 6) — 2022-06-10 at day precision, how_started 'elected'.
--     Michael Driscoll won the May 2022 special election for the 6th District, resigned his PA House seat and, in his own page''s words, "was sworn in as a member of Philadelphia City Council on June 10, 2022".
--   Anthony Phillips (Councilmember, District 9) — 2022-01-01 at year precision, how_started 'elected'.
--     Anthony Phillips won a 2022 SPECIAL election to complete the term Cherelle Parker resigned, and was returned in 2023. His page gives the year and no date, so the year is what is written.
--   Susan Venegoni (Council Member, At Large) — 2026-02-01 at month precision, how_started 'appointed'.
--     Council APPOINTED Susan Venegoni on Monday 2026-02-09 to serve the remainder of Josh Portney''s term (to 2027-12-31). Her oath is reported only as "as early as Tuesday", so the day is not known and month precision is the honest floor. ▶ A day is available from the borough''s own minutes if it is ever wanted.
--
-- 🔴 THE OTHER 22 ARE OPEN-ENDED AT 'unknown', AND NO CONSTITUTIONAL DATE IS INVENTED. Members
-- elected in 2023 took office on 2024-01-01 — but writing that for everyone would be positively
-- WRONG for the incumbents among them, whose occupancy is CONTINUOUS from an earlier swearing-in
-- (CO-3's rule), and for the two who arrived at 2022 special elections. "First elected" is not a
-- term start and fails in both directions.
--
-- 🔴 A NAME THAT AN ACTIVE ROW ALREADY HOLDS, READ BEFORE IT WAS CLASSIFIED:
--   PHL|D9: The existing Anthony W. Phillips (external_id -5507073) is a CANDIDATE FOR THE WISCONSIN ASSEMBLY, district 56, election 2026-08-11. The roster Anthony Phillips is the Councilmember for Philadelphia''s 9th District. Different state, different office, different person.
-- ⚠ The guard is lifted for that row ALONE. The other 25 are inserted with it ARMED, so a namesake
-- nobody anticipated still stops this migration.
-- ⚠ A surname-only pass over every production row with a Pennsylvania connection returned eight
-- more matches — Kendra Brooks against Michele Brooks (PA SD-50) and Bob Brooks, Curtis Jones Jr.
-- against Tom and Mike Jones, Jeffery Young Jr. against Regina G. Young (PA HD-185) and Marty
-- Young, Cherelle L. Parker against Darisha K. Parker (PA HD-198), John Hayes against James
-- Hayes. Every one is a different person, and three of them are rows THIS PROGRAM seated a few
-- hours earlier in PA-2. A shared surname is never the answer on its own.
--
-- Idempotent: people NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*).

BEGIN;

CREATE TEMP TABLE pa3_people(external_id bigint, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO pa3_people(external_id, full_name, first_name, last_name) VALUES
  (-2743001, 'Cherelle L. Parker', 'Cherelle', 'Parker'),
  (-2743002, 'Mark Squilla', 'Mark', 'Squilla'),
  (-2743003, 'Kenyatta Johnson', 'Kenyatta', 'Johnson'),
  (-2743004, 'Jamie Gauthier', 'Jamie', 'Gauthier'),
  (-2743005, 'Curtis Jones, Jr.', 'Curtis', 'Jones'),
  (-2743006, 'Jeffery Young, Jr.', 'Jeffery', 'Young'),
  (-2743007, 'Michael Driscoll', 'Michael', 'Driscoll'),
  (-2743008, 'Quetcy Lozada', 'Quetcy', 'Lozada'),
  (-2743009, 'Cindy Bass', 'Cindy', 'Bass'),
  (-2743011, 'Brian J. O’Neill', 'Brian', 'O’Neill'),
  (-2743012, 'Katherine Gilmore Richardson', 'Katherine', 'Richardson'),
  (-2743013, 'Isaiah Thomas', 'Isaiah', 'Thomas'),
  (-2743014, 'Jim Harrity', 'Jim', 'Harrity'),
  (-2743015, 'Nina Ahmad', 'Nina', 'Ahmad'),
  (-2743016, 'Rue Landau', 'Rue', 'Landau'),
  (-2743017, 'Kendra Brooks', 'Kendra', 'Brooks'),
  (-2743018, 'Nicolas O’Rourke', 'Nicolas', 'O’Rourke'),
  (-2743019, 'Ezra Nanes', 'Ezra', 'Nanes'),
  (-2743020, 'Evan Myers', 'Evan', 'Myers'),
  (-2743021, 'Gopal Balachandran', 'Gopal', 'Balachandran'),
  (-2743022, 'John Hayes', 'John', 'Hayes'),
  (-2743023, 'Matt Herndon', 'Matt', 'Herndon'),
  (-2743024, 'Kevin Kassab', 'Kevin', 'Kassab'),
  (-2743025, 'Nalini Krishnankutty', 'Nalini', 'Krishnankutty'),
  (-2743026, 'Susan Venegoni', 'Susan', 'Venegoni');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3) (CC_0122, PA-3)'
FROM pa3_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE pa3_namesakes(external_id bigint, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO pa3_namesakes(external_id, full_name, first_name, last_name) VALUES
  (-2743010, 'Anthony Phillips', 'Anthony', 'Phillips');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3) (CC_0122, PA-3)'
FROM pa3_namesakes n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 26 terms ─────────────────────────────────────────────────────────────────
-- ⚠ The at-large seats are interchangeable: seven offices share one title on one district. Each
-- person is matched to the Nth such office by a deterministic row number, so a re-run pairs the
-- same person with the same office rather than shuffling them.
CREATE TEMP TABLE pa3_terms(ord int, external_id bigint, title text, district_geo_id text, district_mtfcc text,
                            gov_geo_id text, term_start date, start_precision text, how_started text, source text)
  ON COMMIT DROP;
INSERT INTO pa3_terms VALUES
  (0, -2743001::bigint, 'Mayor', '4260000', 'G4110', '4260000', '2024-01-01'::date, 'day', 'elected', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (1, -2743002::bigint, 'Councilmember, District 1', 'phl-council-district-1', 'X0058', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (2, -2743003::bigint, 'Councilmember, District 2', 'phl-council-district-2', 'X0058', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (3, -2743004::bigint, 'Councilmember, District 3', 'phl-council-district-3', 'X0058', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (4, -2743005::bigint, 'Councilmember, District 4', 'phl-council-district-4', 'X0058', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (5, -2743006::bigint, 'Councilmember, District 5', 'phl-council-district-5', 'X0058', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (6, -2743007::bigint, 'Councilmember, District 6', 'phl-council-district-6', 'X0058', '4260000', '2022-06-10'::date, 'day', 'elected', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (7, -2743008::bigint, 'Councilmember, District 7', 'phl-council-district-7', 'X0058', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (8, -2743009::bigint, 'Councilmember, District 8', 'phl-council-district-8', 'X0058', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (9, -2743010::bigint, 'Councilmember, District 9', 'phl-council-district-9', 'X0058', '4260000', '2022-01-01'::date, 'year', 'elected', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (10, -2743011::bigint, 'Councilmember, District 10', 'phl-council-district-10', 'X0058', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (11, -2743012::bigint, 'Councilmember, At Large', '4260000', 'G4110', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (12, -2743013::bigint, 'Councilmember, At Large', '4260000', 'G4110', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (13, -2743014::bigint, 'Councilmember, At Large', '4260000', 'G4110', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (14, -2743015::bigint, 'Councilmember, At Large', '4260000', 'G4110', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (15, -2743016::bigint, 'Councilmember, At Large', '4260000', 'G4110', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (16, -2743017::bigint, 'Councilmember, At Large', '4260000', 'G4110', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (17, -2743018::bigint, 'Councilmember, At Large', '4260000', 'G4110', '4260000', NULL::date, 'unknown', 'unknown', 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; all 17 council members change-checked against their own member page 2026-09-18 (PA-3)'),
  (18, -2743019::bigint, 'Mayor', '4273808', 'G4110', '4273808', NULL::date, 'unknown', 'unknown', 'Borough of State College, https://statecollegepa.us/603/Borough-Council-Mayor, read 2026-09-18; the borough publishes NO per-member page, so the change-check is the certified Centre County 2025 municipal result (the three seats up were won by the three sitting incumbents, unopposed) plus the documented February 2026 appointment (PA-3)'),
  (19, -2743020::bigint, 'Council Member, At Large', '4273808', 'G4110', '4273808', NULL::date, 'unknown', 'unknown', 'Borough of State College, https://statecollegepa.us/603/Borough-Council-Mayor, read 2026-09-18; the borough publishes NO per-member page, so the change-check is the certified Centre County 2025 municipal result (the three seats up were won by the three sitting incumbents, unopposed) plus the documented February 2026 appointment (PA-3)'),
  (20, -2743021::bigint, 'Council Member, At Large', '4273808', 'G4110', '4273808', NULL::date, 'unknown', 'unknown', 'Borough of State College, https://statecollegepa.us/603/Borough-Council-Mayor, read 2026-09-18; the borough publishes NO per-member page, so the change-check is the certified Centre County 2025 municipal result (the three seats up were won by the three sitting incumbents, unopposed) plus the documented February 2026 appointment (PA-3)'),
  (21, -2743022::bigint, 'Council Member, At Large', '4273808', 'G4110', '4273808', NULL::date, 'unknown', 'unknown', 'Borough of State College, https://statecollegepa.us/603/Borough-Council-Mayor, read 2026-09-18; the borough publishes NO per-member page, so the change-check is the certified Centre County 2025 municipal result (the three seats up were won by the three sitting incumbents, unopposed) plus the documented February 2026 appointment (PA-3)'),
  (22, -2743023::bigint, 'Council Member, At Large', '4273808', 'G4110', '4273808', NULL::date, 'unknown', 'unknown', 'Borough of State College, https://statecollegepa.us/603/Borough-Council-Mayor, read 2026-09-18; the borough publishes NO per-member page, so the change-check is the certified Centre County 2025 municipal result (the three seats up were won by the three sitting incumbents, unopposed) plus the documented February 2026 appointment (PA-3)'),
  (23, -2743024::bigint, 'Council Member, At Large', '4273808', 'G4110', '4273808', NULL::date, 'unknown', 'unknown', 'Borough of State College, https://statecollegepa.us/603/Borough-Council-Mayor, read 2026-09-18; the borough publishes NO per-member page, so the change-check is the certified Centre County 2025 municipal result (the three seats up were won by the three sitting incumbents, unopposed) plus the documented February 2026 appointment (PA-3)'),
  (24, -2743025::bigint, 'Council Member, At Large', '4273808', 'G4110', '4273808', NULL::date, 'unknown', 'unknown', 'Borough of State College, https://statecollegepa.us/603/Borough-Council-Mayor, read 2026-09-18; the borough publishes NO per-member page, so the change-check is the certified Centre County 2025 municipal result (the three seats up were won by the three sitting incumbents, unopposed) plus the documented February 2026 appointment (PA-3)'),
  (25, -2743026::bigint, 'Council Member, At Large', '4273808', 'G4110', '4273808', '2026-02-01'::date, 'month', 'appointed', 'Borough of State College, https://statecollegepa.us/603/Borough-Council-Mayor, read 2026-09-18; the borough publishes NO per-member page, so the change-check is the certified Centre County 2025 municipal result (the three seats up were won by the three sitting incumbents, unopposed) plus the documented February 2026 appointment (PA-3)');

WITH offices_numbered AS (
  SELECT o.id AS office_id, o.title, d.geo_id AS district_geo_id, d.mtfcc AS district_mtfcc,
         g.geo_id AS gov_geo_id,
         row_number() OVER (PARTITION BY g.geo_id, o.title, d.geo_id, d.mtfcc ORDER BY o.id) AS rn
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808')
), terms_numbered AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.gov_geo_id, t.title, t.district_geo_id, t.district_mtfcc ORDER BY t.ord) AS rn
  FROM pa3_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.office_id, p.id, t.term_start, NULL, t.start_precision, t.how_started, t.source || ' (CC_0122, PA-3)'
FROM terms_numbered t
JOIN offices_numbered o
  ON o.gov_geo_id = t.gov_geo_id AND o.title = t.title
 AND o.district_geo_id = t.district_geo_id AND o.district_mtfcc = t.district_mtfcc AND o.rn = t.rn
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.office_id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE v_people int; v_off int; v_terms int; v_seated int; v_dated int; v_ended int; v_fanout int; v_unfilled int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN -2743026 AND -2743001;
  IF v_people <> 26 THEN RAISE EXCEPTION 'PA-3 occupancy: expected 26 people in the band, got %', v_people; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808');
  IF v_off <> 26 THEN RAISE EXCEPTION 'PA-3 occupancy: expected 26 offices, got %', v_off; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808');
  IF v_terms <> 26 THEN RAISE EXCEPTION 'PA-3 occupancy: expected 26 terms, got %', v_terms; END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*) — office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id) INTO v_seated FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808');
  IF v_seated <> 26 THEN RAISE EXCEPTION 'PA-3 occupancy: expected 26 seated offices, got %', v_seated; END IF;

  SELECT count(*) INTO v_unfilled FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808') AND ot.id IS NULL;
  IF v_unfilled <> 0 THEN RAISE EXCEPTION 'PA-3 occupancy: % office(s) got no term at all', v_unfilled; END IF;

  SELECT count(*) INTO v_dated FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808') AND ot.term_start IS NOT NULL;
  IF v_dated <> 4 THEN
    RAISE EXCEPTION 'PA-3 occupancy: expected 4 dated terms, got %', v_dated;
  END IF;

  SELECT count(*) INTO v_ended FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808') AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'PA-3 occupancy: % term(s) carry a term_end', v_ended; END IF;

  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808')
    GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_fanout <> 0 THEN RAISE EXCEPTION 'PA-3 occupancy: % person(s) hold two city seats', v_fanout; END IF;

  RAISE NOTICE 'PA-3 occupancy OK: 26 offices, 26 terms, 26 seated, % dated, 0 ended', v_dated;
END $$;

COMMIT;
