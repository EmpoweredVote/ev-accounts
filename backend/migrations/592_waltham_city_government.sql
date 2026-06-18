-- Migration 592: City of Waltham, Massachusetts government (WALTHAM-01)
--
-- Purpose: Seeds City of Waltham government and City Council.
--   - government name: 'City of Waltham, Massachusetts, US'
--   - geo_id: '2572600' (G4110, from v5.0 MA TIGER load; FIPS 25-72600 confirmed via Census geocoder)
--   - 1 chamber row: 'City Council' (name_formal='Waltham City Council'; no slug — GENERATED ALWAYS)
--   - 1 LOCAL_EXEC district row: geo_id='2572600', mtfcc=NULL, state='ma', label='Waltham (Citywide)' (Mayor)
--   - 1 LOCAL district row: geo_id='2572600', mtfcc=NULL, state='ma', label='Waltham' (all 15 councillors)
--   - 16 politicians: Mayor Donahue (-2572600001) + 6 at-large councillors (-2572600002..-2572600007)
--                     + 9 ward councillors (-2572600008..-2572600016)
--   - 16 offices: Mayor links to LOCAL_EXEC; all 15 councillors link to LOCAL
--   - office_id back-fill on all 16 politicians
--
-- Tier 3 pattern: NO per-ward geofences; single city geo_id='2572600' for all officials.
-- Ward encoded in office title strings: 'City Councillor (Ward N)' for ward seats.
-- At-large title: 'City Councillor' (6 seats)
--
-- City Council structure: 6 at-large councillors + 9 ward councillors (Wards 1-9) = 15 total.
-- NOTE: Waltham uses British/double-L spelling 'Councillor' (confirmed city.waltham.ma.us official site).
--
-- Roster verified 2026-06-14 from city.waltham.ma.us/city-council (direct page scrape):
--   Mayor Arthur Donahue (inaugurated Jan 2024, succeeded Jeannette McCarthy after Nov 2023 election)
--   At-Large: Colleen Bradley-MacArthur, Paul J. Brasco, Tim King,
--              Randall J. LeBlanc (Council VP), Emma Tzioumis, Carlos A. Vidal
--   Ward 1: Anthony LaFauci
--   Ward 2: Caren Dunn
--   Ward 3: Bill Hanley
--   Ward 4: John J. McLaughlin
--   Ward 5: Joseph P. LaCava
--   Ward 6: Sean Durkee
--   Ward 7: Paul S. Katz
--   Ward 8: Cathyann Harris
--   Ward 9: Robert G. Logan (Council President 2026 — title stays 'City Councillor (Ward 9)')
--
-- CRITICAL: 'City Councillor' NOT 'City Councilor' — Waltham uses double-L British spelling
--   (confirmed from city.waltham.ma.us HTML: 'Councillor At Large' and 'Ward Councillors').
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state = 'ma' (lowercase) for LOCAL, LOCAL_EXEC — matches routing queries.
-- CRITICAL: governments.state = 'MA' (uppercase) — government table convention.
-- CRITICAL: offices.representing_state = 'MA' (uppercase) — offices table convention.
-- CRITICAL: mtfcc=NULL on all LOCAL and LOCAL_EXEC district rows (not 'G4110').
-- CRITICAL: party=NULL (antipartisan design).
-- CRITICAL: is_appointed=false for all 16 (all popularly elected).
-- CRITICAL: Logan (Ward 9, Council President): title='City Councillor (Ward 9)' NOT 'City Council President'.
--   President is a council-internal officer role, not a charter office title. (Per D-06 + prior-phase decisions 118-01 + 119-01)
-- CRITICAL: LeBlanc (At-Large, Council VP): title='City Councillor' NOT 'City Council Vice President'.
--
-- Applied to production via mcp__supabase-local__execute_sql.

-- =============================================================================
-- Pre-flight 1: RAISE EXCEPTION if government row already exists (abort on double-apply)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Waltham, Massachusetts, US') > 0 THEN
    RAISE EXCEPTION 'Migration 592 already applied — aborting re-run: City of Waltham government row already exists.';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Assert Waltham G4110 geofence is present (from v5.0 MA TIGER load)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2572600' AND mtfcc = 'G4110';
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Waltham G4110 geofence (geo_id=2572600) not found — must be loaded from v5.0 MA TIGER load.';
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: Waltham G4110 geofence present (% rows)', v_count;
END $$;

-- =============================================================================
-- Pre-flight 3: Assert external_id range -2572600016..-2572600001 is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -2572600016 AND -2572600001;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -2572600001..-2572600016 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: external_id range is clear';
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Government row (City of Waltham, Massachusetts, US)
-- type='LOCAL', state='MA' (uppercase), city='Waltham', geo_id='2572600'
-- WHERE NOT EXISTS guard — governments has no unique constraint on geo_id.
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Waltham, Massachusetts, US',
       'LOCAL', 'MA', 'Waltham', '2572600'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Waltham, Massachusetts, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- Single chamber covers all 15 council seats (6 at-large + 9 ward).
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Waltham City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Waltham, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Waltham, Massachusetts, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district (Mayor Donahue — citywide)
-- geo_id='2572600' matches existing G4110 geofence_boundary.
-- state='ma' LOWERCASE (routing query convention).
-- mtfcc=NULL — no TIGER mtfcc for LOCAL_EXEC districts.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'ma', '2572600', 'Waltham (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL_EXEC' AND state = 'ma'
);

-- =============================================================================
-- Step 3b: LOCAL district — all 15 councillors share this single city-wide district
-- Tier 3 pattern: no per-ward geofences; ward/seat encoded in office title.
-- mtfcc=NULL — no TIGER mtfcc for LOCAL districts.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', '2572600', 'Waltham', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (16 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='MA' uppercase
-- Mayor links to LOCAL_EXEC district; all councillors link to LOCAL district.
-- =============================================================================

-- BLOCK 1: Mayor Arthur Donahue (-2572600001) — links to LOCAL_EXEC district
-- Inaugurated January 2024; succeeded Jeannette McCarthy after Nov 2023 election.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Arthur Donahue', 'Arthur', 'Donahue', NULL,
          true, false, false, true, -2572600001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'Mayor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: At-Large Councillor Colleen Bradley-MacArthur (-2572600002)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Colleen Bradley-MacArthur', 'Colleen', 'Bradley-MacArthur', NULL,
          true, false, false, true, -2572600002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: At-Large Councillor Paul J. Brasco (-2572600003)
-- Drop middle initial per DB convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Brasco', 'Paul', 'Brasco', NULL,
          true, false, false, true, -2572600003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: At-Large Councillor Tim King (-2572600004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tim King', 'Tim', 'King', NULL,
          true, false, false, true, -2572600004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: At-Large Councillor Randall J. LeBlanc (-2572600005) — Council Vice President
-- CRITICAL: title='City Councillor' NOT 'City Council Vice President' (internal role, not charter office)
-- Drop middle initial per DB convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Randall LeBlanc', 'Randall', 'LeBlanc', NULL,
          true, false, false, true, -2572600005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: At-Large Councillor Emma Tzioumis (-2572600006)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Emma Tzioumis', 'Emma', 'Tzioumis', NULL,
          true, false, false, true, -2572600006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: At-Large Councillor Carlos A. Vidal (-2572600007)
-- Drop middle initial per DB convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carlos Vidal', 'Carlos', 'Vidal', NULL,
          true, false, false, true, -2572600007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: Ward 1 Councillor Anthony LaFauci (-2572600008)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anthony LaFauci', 'Anthony', 'LaFauci', NULL,
          true, false, false, true, -2572600008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor (Ward 1)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Ward 2 Councillor Caren Dunn (-2572600009)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Caren Dunn', 'Caren', 'Dunn', NULL,
          true, false, false, true, -2572600009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor (Ward 2)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: Ward 3 Councillor Bill Hanley (-2572600010)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bill Hanley', 'Bill', 'Hanley', NULL,
          true, false, false, true, -2572600010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor (Ward 3)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: Ward 4 Councillor John J. McLaughlin (-2572600011)
-- Drop middle initial per DB convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John McLaughlin', 'John', 'McLaughlin', NULL,
          true, false, false, true, -2572600011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor (Ward 4)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: Ward 5 Councillor Joseph P. LaCava (-2572600012)
-- Drop middle initial per DB convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joseph LaCava', 'Joseph', 'LaCava', NULL,
          true, false, false, true, -2572600012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor (Ward 5)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 13: Ward 6 Councillor Sean Durkee (-2572600013)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sean Durkee', 'Sean', 'Durkee', NULL,
          true, false, false, true, -2572600013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor (Ward 6)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 14: Ward 7 Councillor Paul S. Katz (-2572600014)
-- Drop middle initial per DB convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Katz', 'Paul', 'Katz', NULL,
          true, false, false, true, -2572600014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor (Ward 7)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 15: Ward 8 Councillor Cathyann Harris (-2572600015)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cathyann Harris', 'Cathyann', 'Harris', NULL,
          true, false, false, true, -2572600015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor (Ward 8)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 16: Ward 9 Councillor Robert G. Logan (-2572600016) — Council President 2026
-- CRITICAL: title='City Councillor (Ward 9)' NOT 'City Council President' (internal role, not charter office)
-- Drop middle initial per DB convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Robert Logan', 'Robert', 'Logan', NULL,
          true, false, false, true, -2572600016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Waltham, Massachusetts, US')),
       p.id,
       'City Councillor (Ward 9)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2572600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 16 Waltham city officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -2572600016 AND -2572600001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (7 gates)
-- Raises EXCEPTION on any failure.
-- Gate (a): 1 government row
-- Gate (b): 1 City Council chamber
-- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
-- Gate (d): 16 politicians in external_id range
-- Gate (e): 16 offices linked to Waltham districts
-- Gate (f): section-split = 0 orphan geofences for geo_id='2572600'
-- Gate (g): 0 NULL office_id in external_id range
-- =============================================================================
DO $$
DECLARE
  v_gov_count      INTEGER;
  v_chamber_count  INTEGER;
  v_dist_count     INTEGER;
  v_pol_count      INTEGER;
  v_off_count      INTEGER;
  v_split_count    INTEGER;
  v_null_count     INTEGER;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'City of Waltham, Massachusetts, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Waltham government row, found %', v_gov_count;
  END IF;

  -- Gate (b): City Council chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Waltham, Massachusetts, US');

  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City Council chamber for Waltham, found %', v_chamber_count;
  END IF;

  -- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2572600'
    AND district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_dist_count <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 2 Waltham district rows (LOCAL_EXEC + LOCAL), found %', v_dist_count;
  END IF;

  -- Gate (d): 16 politicians
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -2572600016 AND -2572600001;

  IF v_pol_count <> 16 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 16 politicians in range -2572600001..-2572600016, found %', v_pol_count;
  END IF;

  -- Gate (e): 16 offices linked to Waltham districts
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.state = 'ma'
    AND d.geo_id = '2572600'
    AND d.district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_off_count <> 16 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 16 offices linked to Waltham districts, found %', v_off_count;
  END IF;

  -- Gate (f): section-split detector
  -- Waltham G4110 geofence must have at least one district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2572600'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.state = 'ma'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=2572600', v_split_count;
  END IF;

  -- Gate (g): office_id back-fill completeness
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -2572600016 AND -2572600001
    AND office_id IS NULL;

  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in external_id range have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 592 post-verification PASSED: gov=%, chambers=%, districts=%, politicians=%, offices=%, split_orphans=%, null_office_ids=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('592')
ON CONFLICT (version) DO NOTHING;

COMMIT;
