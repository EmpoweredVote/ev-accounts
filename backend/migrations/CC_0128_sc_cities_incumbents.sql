-- CC_0128_sc_cities_incumbents.sql
-- Knight Foundation program, wave SC-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0127, which creates the governments, chambers, districts and the
-- 14 offices.
--
-- Seats all 14 Columbia and Myrtle Beach city offices:
--    14 people created here, external_id band -2745400 .. -2745301
--    0 people reused — no roster name matched an existing South Carolina row
--    0 offices left unseated — neither council has a vacancy today
--
-- 🔴🔴 EIGHT TERMS ARE DATED AND SIX ARE NOT, AND THE SPLIT IS NOT ABOUT EFFORT. Myrtle Beach
-- publishes a "Who Served When" history giving each member's service by month; Columbia
-- publishes election YEARS on member profiles and nothing else. An election year is not a term
-- start, so Columbia's six continuing members are written open-ended at 'unknown'.
--     COL 2026-01-05 (day  ) Sam P. Johnson
--     MB  2026-01-13 (day  ) Mark Kruea
--     MB  2000-11-01 (month) Michael "Mike" Chestnut
--     MB  2010-01-01 (month) C. H. "Mike" Lowder, Jr.
--     MB  2018-01-01 (month) Jackie Hatley
--     MB  2024-01-01 (month) Deborah "Debbie" K. Conner
--     MB  2024-01-01 (month) Bill McClure
--     MB  2026-01-13 (day  ) Philip N. Render
--
-- 🔴 A RE-ELECTION DOES NOT RESTART AN OCCUPANCY, AND THREE SEATS HERE WOULD HAVE BEEN WRONG.
-- Columbia's mayor, its District 1 and its District 4 members were all sworn in on 2026-01-05,
-- and Myrtle Beach's Lowder and Hatley on 2026-01-13 — every one of them a RE-election. Writing
-- the swearing-in would have restarted occupancies that never stopped: Lowder has served since
-- January 2010 and Hatley since January 2018.
--
-- 🔴 AND THE OPPOSITE CASE IS IN THE SAME WAVE. Myrtle Beach's Philip N. Render served from
-- January 2004 to December 2023, was OUT for the 2024-2025 term, and returned on 2026-01-13.
-- "First elected" would overstate his current occupancy by 22 years; the gap is why his date is
-- the swearing-in and not his first election.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 PARTY IS NOT WRITTEN. Both councils are elected non-partisan; party lives on
-- races.primary_party in any case.
--
-- 🔴 ONE ROSTER NAME MATCHES AN EXISTING ROW, AND IT IS A DIFFERENT PERSON:
--     columbia:Sam P. Johnson
--       The existing Sam Johnson (external_id -880002) holds BOARD MEMBER, PLACE 2 on a TEXAS school board. The roster Sam P. Johnson is the at-large councilman for Columbia, South Carolina, sworn in 2026-01-05. Different state, different office, different person. A surname pass over rows with any South Carolina connection also found three Johnsons and one Bailey — all state legislators seated by SC-2, all different people.
--
-- ⚠ THE GUARD IS LIFTED FOR 1 ROW, NOT FOR THE MIGRATION. The other 13 rows are inserted with
-- essentials.politicians' duplicate-name trigger ARMED, so a namesake nobody anticipated still
-- stops this migration.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*).

BEGIN;

-- ─── 13 people with no active namesake — guard ARMED ──────────────────────────────
CREATE TEMP TABLE sc3_new_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc3_new_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2745301, 'Daniel J. Rickenmann', 'Daniel', 'Rickenmann', '{}'::text[]),
  (-2745302, 'Tina N. Herbert', 'Tina', 'Herbert', '{}'::text[]),
  (-2745303, 'Edward H. McDowell, Jr.', 'Edward', 'McDowell', '{}'::text[]),
  (-2745304, 'Will Brennan', 'Will', 'Brennan', '{}'::text[]),
  (-2745305, 'Peter M. Brown', 'Peter', 'Brown', '{}'::text[]),
  (-2745306, 'Tyler D. Bailey', 'Tyler', 'Bailey', '{}'::text[]),
  (-2745308, 'Mark Kruea', 'Mark', 'Kruea', '{}'::text[]),
  (-2745309, 'Michael "Mike" Chestnut', 'Michael', 'Chestnut', '{}'::text[]),
  (-2745310, 'C. H. "Mike" Lowder, Jr.', 'C.', 'Lowder', '{}'::text[]),
  (-2745311, 'Jackie Hatley', 'Jackie', 'Hatley', '{}'::text[]),
  (-2745312, 'Deborah "Debbie" K. Conner', 'Deborah', 'Conner', '{}'::text[]),
  (-2745313, 'Bill McClure', 'Bill', 'McClure', '{}'::text[]),
  (-2745314, 'Philip N. Render', 'Philip', 'Render', '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Columbia and Myrtle Beach city council pages (citycouncil.columbiasc.gov; cityofmyrtlebeach.com/government/mayor___city_council), cross-checked against the Municipal Association of South Carolina''s directory (masc.sc); arrivals from the cities'' own records, read 2026-09-20 (SC-3) (CC_0128, SC-3)', n.alternate_names
FROM sc3_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 1 person who shares a name with a DIFFERENT person — guard lifted ─────────
SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE sc3_namesake_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc3_namesake_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2745307, 'Sam P. Johnson', 'Sam', 'Johnson', '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Columbia and Myrtle Beach city council pages (citycouncil.columbiasc.gov; cityofmyrtlebeach.com/government/mayor___city_council), cross-checked against the Municipal Association of South Carolina''s directory (masc.sc); arrivals from the cities'' own records, read 2026-09-20 (SC-3) (CC_0128, SC-3)', n.alternate_names
FROM sc3_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 14 terms, one per office ─────────────────────────────────────────────────
-- ⚠ The at-large offices are indistinguishable by (district, title): six Myrtle Beach rows share
-- one. They are matched to people by ROW NUMBER within the group, which is why this table carries
-- the office title AND the government, and why the gate below counts holders per office.
CREATE TEMP TABLE sc3_terms(district_geo_id text, district_mtfcc text, title text, gov_geo_id text,
                            external_id bigint, term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO sc3_terms(district_geo_id, district_mtfcc, title, gov_geo_id, external_id, term_start, start_precision, how_started) VALUES
  ('4516000', 'G4110', 'Mayor', '4516000', -2745301::bigint, NULL::date, 'unknown', 'unknown'),
  ('cola-council-district-1', 'X0059', 'Council Member, District 1', '4516000', -2745302::bigint, NULL::date, 'unknown', 'unknown'),
  ('cola-council-district-2', 'X0059', 'Council Member, District 2', '4516000', -2745303::bigint, NULL::date, 'unknown', 'unknown'),
  ('cola-council-district-3', 'X0059', 'Council Member, District 3', '4516000', -2745304::bigint, NULL::date, 'unknown', 'unknown'),
  ('cola-council-district-4', 'X0059', 'Council Member, District 4', '4516000', -2745305::bigint, NULL::date, 'unknown', 'unknown'),
  ('4516000', 'G4110', 'Council Member, At Large', '4516000', -2745306::bigint, NULL::date, 'unknown', 'unknown'),
  ('4516000', 'G4110', 'Council Member, At Large', '4516000', -2745307::bigint, '2026-01-05'::date, 'day', 'elected'),
  ('4549075', 'G4110', 'Mayor', '4549075', -2745308::bigint, '2026-01-13'::date, 'day', 'elected'),
  ('4549075', 'G4110', 'Council Member, At Large', '4549075', -2745309::bigint, '2000-11-01'::date, 'month', 'elected'),
  ('4549075', 'G4110', 'Council Member, At Large', '4549075', -2745310::bigint, '2010-01-01'::date, 'month', 'elected'),
  ('4549075', 'G4110', 'Council Member, At Large', '4549075', -2745311::bigint, '2018-01-01'::date, 'month', 'elected'),
  ('4549075', 'G4110', 'Council Member, At Large', '4549075', -2745312::bigint, '2024-01-01'::date, 'month', 'elected'),
  ('4549075', 'G4110', 'Council Member, At Large', '4549075', -2745313::bigint, '2024-01-01'::date, 'month', 'elected'),
  ('4549075', 'G4110', 'Council Member, At Large', '4549075', -2745314::bigint, '2026-01-13'::date, 'day', 'elected');

WITH office_slot AS (
  SELECT o.id AS office_id, d.geo_id AS district_geo_id, d.mtfcc AS district_mtfcc, o.title,
         g.geo_id AS gov_geo_id,
         row_number() OVER (PARTITION BY g.geo_id, d.geo_id, d.mtfcc, o.title ORDER BY o.id) AS slot
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075')
), term_slot AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.gov_geo_id, t.district_geo_id, t.district_mtfcc, t.title
                                 ORDER BY t.external_id DESC) AS slot
    FROM sc3_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, ts.term_start, NULL, ts.start_precision, ts.how_started, 'Columbia and Myrtle Beach city council pages (citycouncil.columbiasc.gov; cityofmyrtlebeach.com/government/mayor___city_council), cross-checked against the Municipal Association of South Carolina''s directory (masc.sc); arrivals from the cities'' own records, read 2026-09-20 (SC-3) (CC_0128, SC-3)'
FROM term_slot ts
JOIN office_slot os
  ON os.gov_geo_id = ts.gov_geo_id AND os.district_geo_id = ts.district_geo_id
 AND os.district_mtfcc = ts.district_mtfcc AND os.title = ts.title AND os.slot = ts.slot
JOIN essentials.politicians p ON p.external_id = ts.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE
  v_people int; v_offices int; v_terms int; v_seated int; v_dated int; v_ended int;
  v_fanout int; v_double int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2745400 AND -2745301;
  IF v_people <> 14 THEN
    RAISE EXCEPTION 'SC-3 occupancy: expected 14 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075');
  IF v_offices <> 14 THEN RAISE EXCEPTION 'SC-3 occupancy: expected 14 city offices, got %', v_offices; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075');
  IF v_terms <> 14 THEN RAISE EXCEPTION 'SC-3 occupancy: expected 14 terms, got %', v_terms; END IF;

  -- 🔴 count och.politician_id, never count(*) — office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075');
  IF v_seated <> 14 THEN RAISE EXCEPTION 'SC-3 occupancy: expected 14 seated offices, got %', v_seated; END IF;

  SELECT count(*) INTO v_dated FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075')
     AND ot.term_start IS NOT NULL;
  IF v_dated <> 8 THEN
    RAISE EXCEPTION 'SC-3 occupancy: expected 8 dated term(s), got %', v_dated;
  END IF;

  -- The two dates that carry a rule. Render returned after a gap; Lowder never left.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
      JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE p.full_name = 'Philip N. Render' AND ot.term_start = DATE '2026-01-13' AND ot.start_precision = 'day'
  ) THEN
    RAISE EXCEPTION 'SC-3 occupancy: Render is not seated from 2026-01-13 — the return after a gap, not his 2004 arrival';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
      JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE p.last_name = 'Lowder' AND ot.term_start = DATE '2010-01-01' AND ot.start_precision = 'month'
  ) THEN
    RAISE EXCEPTION 'SC-3 occupancy: Lowder is not seated from January 2010 — a re-election does not restart an occupancy';
  END IF;

  SELECT count(*) INTO v_ended FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075')
     AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'SC-3 occupancy: % term(s) carry a term_end', v_ended; END IF;

  -- Nobody holds two of these 14 seats, and no office has two holders.
  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
     WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075')
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION 'SC-3 occupancy: % person(s) hold more than one of these city seats', v_fanout;
  END IF;

  SELECT count(*) INTO v_double FROM (
    SELECT ot.office_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
     WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075')
     GROUP BY ot.office_id HAVING count(*) > 1) y;
  IF v_double <> 0 THEN
    RAISE EXCEPTION 'SC-3 occupancy: % office(s) carry more than one term', v_double;
  END IF;

  RAISE NOTICE 'SC-3 occupancy OK: 14 offices, 14 terms, 14 seated, 8 dated, 0 ended';
END $$;

COMMIT;
