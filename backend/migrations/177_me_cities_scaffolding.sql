-- =============================================================================
-- Migration 177: Maine 23-city scaffolding
-- Created: 2026-05-19
--
-- Creates all 23 Maine incorporated city (G4110) governments, LOCAL district
-- rows, City Council chambers (and school chambers where applicable), and
-- skeletal office rows (politician_id=NULL, is_vacant=true).
--
-- Per city, in order:
--   Step 1: INSERT government row (idempotent via WHERE NOT EXISTS on geo_id)
--   Step 2: INSERT LOCAL district row (Cambridge migration 167 pattern)
--   Step 3: INSERT chamber row(s) (idempotent via government_id + name)
--   Step 4: INSERT office rows (idempotent via chamber_id + title)
--   Step 5: UPDATE offices SET district_id = <LOCAL district id> WHERE district_id IS NULL
--
-- Creates 23 LOCAL districts (district_type='LOCAL', mtfcc='G4110', state='me')
-- so getRepresentativesByAddress can JOIN office.district_id -> district.id
-- (Migration 167 is the exact precedent for this pattern.)
--
-- Mayor modeling:
--   - Voter-elected on-council Mayor: title='Mayor', is_appointed_position=false
--   - Council-selected Mayor (Bangor, South Portland, Presque Isle, Rockland):
--       title='Mayor', is_appointed_position=true
--   - No Mayor at all (Bath, Old Town): no Mayor row, all rows titled 'Council Member (...)'
--
-- Label convention: NO seat_label column exists on essentials.offices.
-- Seat identifiers are embedded in the title column:
--   Mayor: title='Mayor'
--   Ward seats: title='Council Member (Ward N)'
--   District seats: title='Council Member (District N)'
--   At-large (multiple): title='Council Member (At-Large N)'
--   At-large (single): title='Council Member (At-Large)'
--   School board: title='School Board Member (Ward N)' / '(District N)' / '(At-Large N)'
--
-- ALL offices are skeletal: politician_id=NULL, is_vacant=true.
-- Plan 53-02 fills Portland; Phase 54 fills the other 22.
--
-- CRITICAL: NO slug in chamber INSERT (GENERATED ALWAYS).
-- CRITICAL: NO election_method ALTER TABLE (already added in migration 157).
-- CRITICAL: NO TIGER-sourced district inserts (STATE_UPPER, STATE_LOWER,
--           NATIONAL_LOWER, COUNTY) — those exist from Phase 49 TIGER load.
--           ONLY LOCAL district rows are inserted here.
-- CRITICAL: WHERE NOT EXISTS (no ON CONFLICT) on governments AND districts
--           (no unique constraint on geo_id on either table).
--
-- Cities covered (23 total):
--   1. Portland     (2360545) — 2 chambers (Council 9 RCV + Board of Public Ed 9 RCV)
--   2. Lewiston     (2338740) — 2 chambers (Council 8 + school ~9 ward-based)
--   3. Bangor       (2302795) — 1 chamber (Council 9 at-large; Mayor council-selected)
--   4. South Portland (2371990) — 1 chamber (Council 7; Mayor council-selected)
--   5. Auburn       (2302060) — 1 chamber (Council 8: Mayor+5W+2AL)
--   6. Biddeford    (2304860) — 1 chamber (Council 9: Mayor+7W+2AL)
--   7. Sanford      (2365725) — 1 chamber (Council 7: Mayor+6AL)
--   8. Augusta      (2302100) — 2 chambers (Council 9 + school 9)
--   9. Saco         (2364675) — 1 chamber (Council 8: Mayor+7W)
--  10. Westbrook    (2382105) — 2 chambers (Council 7 RCV + school 7 RCV)
--  11. Waterville   (2380740) — 1 chamber (Council 8: Mayor+7W)
--  12. Brewer       (2306925) — 1 chamber (Council 5: Mayor+4AL)
--  13. Presque Isle (2360825) — 1 chamber (Council 7 at-large; Mayor council-selected)
--  14. Bath         (2303355) — 1 chamber (Council 9; NO Mayor row)
--  15. Ellsworth    (2323200) — 1 chamber (Council 7: Mayor+6AL)
--  16. Gardiner     (2327085) — 1 chamber (Council 8: Mayor+4D+3AL)
--  17. Hallowell    (2330550) — 1 chamber (Council 8: Mayor+4W+3AL)
--  18. Calais       (2309585) — 1 chamber (Council 7: Mayor+6AL)
--  19. Belfast      (2303950) — 1 chamber (Council 6: Mayor+5W)
--  20. Old Town     (2355225) — 1 chamber (Council 7; NO Mayor row)
--  21. Eastport     (2321730) — 1 chamber (Council 5: Mayor+4AL)
--  22. Rockland     (2363590) — 1 chamber (Council 5 at-large; Mayor council-selected)
--  23. Caribou      (2310565) — 1 chamber (Council 7 at-large)
-- =============================================================================

BEGIN;

-- ===== 1. Portland (geo_id 2360545) =====
-- 2 chambers: City Council (9 seats: Mayor+D1-D5+AL1-AL3, RCV)
--             Board of Public Education (9 seats: D1-D5+AL1-AL4, RCV)
-- Mayor is voter-elected, on-council. Both chambers use RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
  v_school_id   UUID;
BEGIN
  -- Step 1: Government
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Portland, Maine, US', 'LOCAL', 'ME', NULL, '2360545'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2360545');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2360545';

  -- Step 2: LOCAL district row (required for address routing)
  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2360545', 'LOCAL', 'G4110', 'me', 'Portland'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2360545' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2360545' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  -- Step 3a: City Council chamber (9 seats, RCV)
  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url, election_method)
  SELECT v_gov_id, 'City Council', 'Portland City Council',
         9, 'full', 'https://www.portlandmaine.gov/723/City-Council', 'rcv'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  -- Step 3b: Board of Public Education (9 seats, RCV)
  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url, election_method)
  SELECT v_gov_id, 'Board of Public Education', 'Portland Board of Public Education',
         9, 'full', 'https://www.portlandschools.org/board', 'rcv'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'Board of Public Education'
  );

  SELECT id INTO v_school_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'Board of Public Education';

  -- Step 4a: Council offices (9 rows: Mayor + District 1-5 + At-Large 1-3)
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (District ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 5) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (District ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 3) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  -- Step 4b: School Board offices (9 rows: District 1-5 + At-Large 1-4)
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_school_id, NULL, 'School Board Member (District ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 5) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_school_id AND title = 'School Board Member (District ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_school_id, NULL, 'School Board Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_school_id AND title = 'School Board Member (At-Large ' || s.n::text || ')'
  );

  -- Step 5: Link all Portland offices to Portland LOCAL district
  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id IN (v_council_id, v_school_id)
    AND district_id IS NULL;
END $$;

-- ===== 2. Lewiston (geo_id 2338740) =====
-- 2 chambers: City Council (8 seats: Mayor+Ward 1-7)
--             School Committee (8 seats: Ward 1-7 + At-Large)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
  v_school_id   UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Lewiston, Maine, US', 'LOCAL', 'ME', NULL, '2338740'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2338740');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2338740';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2338740', 'LOCAL', 'G4110', 'me', 'Lewiston'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2338740' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2338740' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Lewiston City Council',
         8, 'full', 'https://www.lewistonmaine.gov/133/City-Council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'School Committee', 'Lewiston School Committee',
         8, 'full', 'https://www.lewistonpublicschools.org/school-committee'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'School Committee'
  );

  SELECT id INTO v_school_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'School Committee';

  -- Council: Mayor + Ward 1-7
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 7) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (Ward ' || s.n::text || ')'
  );

  -- School Committee: Ward 1-7 + At-Large
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_school_id, NULL, 'School Committee Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 7) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_school_id AND title = 'School Committee Member (Ward ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_school_id, NULL, 'School Committee Member (At-Large)', 'ME', false, true
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_school_id AND title = 'School Committee Member (At-Large)'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id IN (v_council_id, v_school_id)
    AND district_id IS NULL;
END $$;

-- ===== 3. Bangor (geo_id 2302795) =====
-- 1 chamber: City Council (9 at-large seats)
-- Mayor is COUNCIL-SELECTED (Chair of Council) -> is_appointed_position=true
-- No school chamber (school dept not a city-elected body)
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Bangor, Maine, US', 'LOCAL', 'ME', NULL, '2302795'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2302795');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2302795';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2302795', 'LOCAL', 'G4110', 'me', 'Bangor'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2302795' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2302795' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Bangor City Council',
         9, 'full', 'https://www.bangormaine.gov/169/City-Council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  -- Mayor is council-selected (Chair) -> is_appointed_position=true
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', true, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  -- 8 at-large council members (total 9 including Mayor)
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 8) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 4. South Portland (geo_id 2371990) =====
-- 1 chamber: City Council (7 seats: Mayor+District 1-5+At-Large 1-2)
-- Mayor is COUNCIL-SELECTED -> is_appointed_position=true
-- No school chamber
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of South Portland, Maine, US', 'LOCAL', 'ME', NULL, '2371990'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2371990');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2371990';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2371990', 'LOCAL', 'G4110', 'me', 'South Portland'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2371990' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2371990' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'South Portland City Council',
         8, 'full', 'https://www.southportland.org/departments/city-council/'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  -- Mayor is council-selected -> is_appointed_position=true
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', true, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  -- 5 district seats + 2 at-large seats
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (District ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 5) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (District ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 2) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 5. Auburn (geo_id 2302060) =====
-- 1 chamber: City Council (8 seats: Mayor+Ward 1-5+At-Large 1-2)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Auburn, Maine, US', 'LOCAL', 'ME', NULL, '2302060'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2302060');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2302060';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2302060', 'LOCAL', 'G4110', 'me', 'Auburn'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2302060' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2302060' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Auburn City Council',
         8, 'full', 'https://www.auburnmaine.gov/139/City-Council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 5) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (Ward ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 2) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 6. Biddeford (geo_id 2304860) =====
-- 1 chamber: City Council (9 seats: Mayor+Ward 1-7+At-Large 1-2)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Biddeford, Maine, US', 'LOCAL', 'ME', NULL, '2304860'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2304860');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2304860';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2304860', 'LOCAL', 'G4110', 'me', 'Biddeford'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2304860' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2304860' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Biddeford City Council',
         10, 'full', 'https://www.biddefordmaine.org/193/City-Council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 7) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (Ward ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 2) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 7. Sanford (geo_id 2365725) =====
-- 1 chamber: City Council (7 seats: Mayor+At-Large 1-6)
-- Mayor is voter-elected, on-council (defaulted from research). No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Sanford, Maine, US', 'LOCAL', 'ME', NULL, '2365725'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2365725');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2365725';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2365725', 'LOCAL', 'G4110', 'me', 'Sanford'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2365725' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2365725' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Sanford City Council',
         7, 'full', 'https://www.sanfordmaine.org/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 6) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 8. Augusta (geo_id 2302100) =====
-- 2 chambers: City Council (9 seats: Mayor+Ward 1-4+At-Large 1-4)
--             School Committee (9 seats: Ward 1-4+At-Large 1-4+Chair)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
  v_school_id   UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Augusta, Maine, US', 'LOCAL', 'ME', NULL, '2302100'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2302100');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2302100';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2302100', 'LOCAL', 'G4110', 'me', 'Augusta'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2302100' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2302100' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Augusta City Council',
         9, 'full', 'https://www.augustamaine.gov/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'School Committee', 'Augusta School Committee',
         9, 'full', 'https://www.augustamaine.gov/school-committee'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'School Committee'
  );

  SELECT id INTO v_school_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'School Committee';

  -- Council: Mayor + Ward 1-4 + At-Large 1-4
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (Ward ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  -- School Committee: Chair + Ward 1-4 + At-Large 1-4
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_school_id, NULL, 'School Board Chair', 'ME', false, true
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices WHERE chamber_id = v_school_id AND title = 'School Board Chair'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_school_id, NULL, 'School Committee Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_school_id AND title = 'School Committee Member (Ward ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_school_id, NULL, 'School Committee Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_school_id AND title = 'School Committee Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id IN (v_council_id, v_school_id)
    AND district_id IS NULL;
END $$;

-- ===== 9. Saco (geo_id 2364675) =====
-- 1 chamber: City Council (8 seats: Mayor+Ward 1-7)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Saco, Maine, US', 'LOCAL', 'ME', NULL, '2364675'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2364675');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2364675';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2364675', 'LOCAL', 'G4110', 'me', 'Saco'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2364675' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2364675' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Saco City Council',
         8, 'full', 'https://www.sacomaine.org/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 7) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (Ward ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 10. Westbrook (geo_id 2382105) =====
-- 2 chambers: City Council (7 seats: Mayor+Ward 1-5+At-Large 1-2, RCV)
--             School Board (7 seats: Ward 1-5+At-Large 1-2, RCV)
-- Mayor is voter-elected, on-council. Both chambers use RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
  v_school_id   UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Westbrook, Maine, US', 'LOCAL', 'ME', NULL, '2382105'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2382105');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2382105';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2382105', 'LOCAL', 'G4110', 'me', 'Westbrook'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2382105' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2382105' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url, election_method)
  SELECT v_gov_id, 'City Council', 'Westbrook City Council',
         8, 'full', 'https://www.westbrookmaine.com/city-council', 'rcv'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url, election_method)
  SELECT v_gov_id, 'School Board', 'Westbrook School Board',
         7, 'full', 'https://www.westbrookschools.org/school-board', 'rcv'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'School Board'
  );

  SELECT id INTO v_school_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'School Board';

  -- Council: Mayor + Ward 1-5 + At-Large 1-2
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 5) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (Ward ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 2) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  -- School Board: Ward 1-5 + At-Large 1-2
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_school_id, NULL, 'School Board Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 5) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_school_id AND title = 'School Board Member (Ward ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_school_id, NULL, 'School Board Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 2) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_school_id AND title = 'School Board Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id IN (v_council_id, v_school_id)
    AND district_id IS NULL;
END $$;

-- ===== 11. Waterville (geo_id 2380740) =====
-- 1 chamber: City Council (8 seats: Mayor+Ward 1-7)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Waterville, Maine, US', 'LOCAL', 'ME', NULL, '2380740'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2380740');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2380740';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2380740', 'LOCAL', 'G4110', 'me', 'Waterville'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2380740' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2380740' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Waterville City Council',
         8, 'full', 'https://www.watervilleme.gov/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 7) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (Ward ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 12. Brewer (geo_id 2306925) =====
-- 1 chamber: City Council (5 seats: Mayor+At-Large 1-4)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Brewer, Maine, US', 'LOCAL', 'ME', NULL, '2306925'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2306925');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2306925';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2306925', 'LOCAL', 'G4110', 'me', 'Brewer'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2306925' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2306925' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Brewer City Council',
         5, 'full', 'https://www.brewermaine.gov/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 13. Presque Isle (geo_id 2360825) =====
-- 1 chamber: City Council (7 at-large seats)
-- Mayor is COUNCIL-SELECTED (Chair) -> is_appointed_position=true
-- No school chamber (MSAD#1, not city-elected)
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Presque Isle, Maine, US', 'LOCAL', 'ME', NULL, '2360825'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2360825');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2360825';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2360825', 'LOCAL', 'G4110', 'me', 'Presque Isle'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2360825' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2360825' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Presque Isle City Council',
         7, 'full', 'https://www.presqueisleme.us/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  -- Mayor is council-selected -> is_appointed_position=true
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', true, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  -- 6 at-large council members
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 6) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 14. Bath (geo_id 2303355) =====
-- 1 chamber: City Council (9 seats, NO Mayor row — Council Chair model)
-- All 9 office rows titled 'Council Member (At-Large N)'
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Bath, Maine, US', 'LOCAL', 'ME', NULL, '2303355'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2303355');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2303355';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2303355', 'LOCAL', 'G4110', 'me', 'Bath'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2303355' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2303355' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Bath City Council',
         9, 'full', 'https://www.cityofbath.com/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  -- NO Mayor row (Bath uses Council Chair model, not elected Mayor)
  -- 9 at-large council members
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 9) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 15. Ellsworth (geo_id 2323200) =====
-- 1 chamber: City Council (7 seats: Mayor+At-Large 1-6)
-- Mayor is voter-elected, on-council (defaulted from research). No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Ellsworth, Maine, US', 'LOCAL', 'ME', NULL, '2323200'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2323200');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2323200';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2323200', 'LOCAL', 'G4110', 'me', 'Ellsworth'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2323200' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2323200' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Ellsworth City Council',
         7, 'full', 'https://www.ellsworthmaine.gov/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 6) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 16. Gardiner (geo_id 2327085) =====
-- 1 chamber: City Council (8 seats: Mayor+District 1-4+At-Large 1-3)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Gardiner, Maine, US', 'LOCAL', 'ME', NULL, '2327085'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2327085');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2327085';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2327085', 'LOCAL', 'G4110', 'me', 'Gardiner'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2327085' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2327085' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Gardiner City Council',
         8, 'full', 'https://www.gardinermaine.com/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (District ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (District ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 3) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 17. Hallowell (geo_id 2330550) =====
-- 1 chamber: City Council (8 seats: Mayor+Ward 1-4+At-Large 1-3)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Hallowell, Maine, US', 'LOCAL', 'ME', NULL, '2330550'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2330550');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2330550';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2330550', 'LOCAL', 'G4110', 'me', 'Hallowell'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2330550' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2330550' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Hallowell City Council',
         8, 'full', 'https://www.hallowell.org/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (Ward ' || s.n::text || ')'
  );

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 3) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 18. Calais (geo_id 2309585) =====
-- 1 chamber: City Council (7 seats: Mayor+At-Large 1-6)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Calais, Maine, US', 'LOCAL', 'ME', NULL, '2309585'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2309585');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2309585';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2309585', 'LOCAL', 'G4110', 'me', 'Calais'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2309585' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2309585' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Calais City Council',
         7, 'full', 'https://www.calaismaine.org/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 6) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 19. Belfast (geo_id 2303950) =====
-- 1 chamber: City Council (6 seats: Mayor+Ward 1-5)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Belfast, Maine, US', 'LOCAL', 'ME', NULL, '2303950'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2303950');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2303950';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2303950', 'LOCAL', 'G4110', 'me', 'Belfast'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2303950' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2303950' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Belfast City Council',
         6, 'full', 'https://www.belfastmaine.org/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (Ward ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 5) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (Ward ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 20. Old Town (geo_id 2355225) =====
-- 1 chamber: City Council (7 seats, NO Mayor row — Council President model)
-- All 7 office rows titled 'Council Member (At-Large N)'
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Old Town, Maine, US', 'LOCAL', 'ME', NULL, '2355225'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2355225');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2355225';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2355225', 'LOCAL', 'G4110', 'me', 'Old Town'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2355225' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2355225' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Old Town City Council',
         7, 'full', 'https://www.oldtown.org/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  -- NO Mayor row (Old Town uses Council President model)
  -- 7 at-large council members
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 7) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 21. Eastport (geo_id 2321730) =====
-- 1 chamber: City Council (5 seats: Mayor+At-Large 1-4)
-- Mayor is voter-elected, on-council (defaulted from research). No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Eastport, Maine, US', 'LOCAL', 'ME', NULL, '2321730'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2321730');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2321730';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2321730', 'LOCAL', 'G4110', 'me', 'Eastport'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2321730' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2321730' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Eastport City Council',
         5, 'full', 'https://www.eastport.me.us/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 22. Rockland (geo_id 2363590) =====
-- 1 chamber: City Council (5 at-large seats)
-- Mayor is COUNCIL-SELECTED -> is_appointed_position=true
-- No school chamber
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Rockland, Maine, US', 'LOCAL', 'ME', NULL, '2363590'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2363590');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2363590';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2363590', 'LOCAL', 'G4110', 'me', 'Rockland'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2363590' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2363590' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Rockland City Council',
         5, 'full', 'https://www.rocklandmaine.gov/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  -- Mayor is council-selected -> is_appointed_position=true
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', true, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  -- 4 at-large council members
  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 4) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

-- ===== 23. Caribou (geo_id 2310565) =====
-- 1 chamber: City Council (7 at-large seats: Mayor+At-Large 1-6)
-- Mayor is voter-elected, on-council. No RCV.
DO $$
DECLARE
  v_gov_id      UUID;
  v_district_id UUID;
  v_council_id  UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Caribou, Maine, US', 'LOCAL', 'ME', NULL, '2310565'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2310565');

  SELECT id INTO v_gov_id FROM essentials.governments WHERE geo_id = '2310565';

  INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
  SELECT '2310565', 'LOCAL', 'G4110', 'me', 'Caribou'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = '2310565' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  );

  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '2310565' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
  LIMIT 1;

  INSERT INTO essentials.chambers
    (government_id, name, name_formal, official_count, policy_engagement_level, website_url)
  SELECT v_gov_id, 'City Council', 'Caribou City Council',
         7, 'full', 'https://www.caribou.me.us/city-council'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council'
  );

  SELECT id INTO v_council_id
  FROM essentials.chambers WHERE government_id = v_gov_id AND name = 'City Council';

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Mayor', 'ME', false, true
  WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE chamber_id = v_council_id AND title = 'Mayor');

  INSERT INTO essentials.offices (chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
  SELECT v_council_id, NULL, 'Council Member (At-Large ' || n::text || ')', 'ME', false, true
  FROM generate_series(1, 6) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE chamber_id = v_council_id AND title = 'Council Member (At-Large ' || s.n::text || ')'
  );

  UPDATE essentials.offices
  SET district_id = v_district_id
  WHERE chamber_id = v_council_id
    AND district_id IS NULL;
END $$;

COMMIT;
