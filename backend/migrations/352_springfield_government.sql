-- Migration 352: City of Springfield government (MA-TIER2-02)
--
-- Purpose: Seeds City of Springfield government and City Council.
--   - 1 government row: 'City of Springfield, Massachusetts, US' (type='LOCAL', state='MA', city='Springfield', geo_id='2567000')
--   - 1 chamber row: 'City Council' (name_formal='Springfield City Council'; no slug — GENERATED ALWAYS)
--   - 1 LOCAL_EXEC district row: geo_id='2567000', mtfcc=NULL, state='ma', label='Springfield (Citywide)' (Mayor)
--   - 1 LOCAL district row: geo_id='2567000', mtfcc=NULL, state='ma', label='Springfield' (all 13 councillors)
--   - 14 politicians: Mayor Sarno (-256700001) + 8 ward + 5 at-large councillors (-256700002..-256700014)
--   - 14 offices
--   - office_id back-fill on all 14
--
-- Springfield G4110 geofence (geo_id='2567000') already loaded from v5.0 Phase 38 MA TIGER load.
-- NO per-ward/district geofences — Tier 2 encodes seat in office title only (Maine Tier 2 pattern).
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state = 'ma' (lowercase) for LOCAL, LOCAL_EXEC — matches routing queries.
-- CRITICAL: governments.state = 'MA' (uppercase) — government table convention.
-- CRITICAL: offices.representing_state = 'MA' (uppercase) — offices table convention.
-- CRITICAL: mtfcc=NULL on LOCAL and LOCAL_EXEC district rows (no per-ward geofences for Tier 2).
-- CRITICAL: party=NULL (antipartisan design).
-- CRITICAL: is_appointed=false for all 14 (Mayor + councillors are popularly elected).
-- CRITICAL: Fenton (-256700002) title='City Councilor (Ward 2)' NOT 'Council President' (Pitfall 7).
--
-- Roster verified from springfield-ma.gov/cos/city-council-members:
--   Mayor Domenic J. Sarno (LOCAL_EXEC)
--   Ward: Fenton (W2), Edwards (W3), Perez (W1), Brown (W4), Click-Bruce (W5), Davila (W6), Martin (W7), Govan (W8)
--   At-Large: Hurst, Delgado, Walsh, Whitfield, Santaniello
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight 1: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Springfield, Massachusetts, US') > 0 THEN
    RAISE NOTICE 'City of Springfield government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Assert Springfield G4110 geofence is present
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2567000' AND mtfcc = 'G4110';
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Springfield G4110 geofence (geo_id=2567000) not found. Expected from Phase 38 MA TIGER load.';
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: Springfield G4110 geofence present';
END $$;

-- =============================================================================
-- Pre-flight 3: Assert external_id range -256700001..-256700014 is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -256700014 AND -256700001;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -256700001..-256700014 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: external_id range is clear';
END $$;

-- =============================================================================
-- Step 1: Government row (City of Springfield, Massachusetts, US)
-- type='LOCAL', state='MA' (uppercase), city='Springfield', geo_id='2567000'
-- WHERE NOT EXISTS guard — governments has no unique constraint on geo_id.
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Springfield, Massachusetts, US',
       'LOCAL', 'MA', 'Springfield', '2567000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Springfield, Massachusetts, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- Single chamber covers all 13 council seats (8 ward + 5 at-large).
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Springfield City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Springfield, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Springfield, Massachusetts, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district (Mayor Sarno — citywide)
-- geo_id='2567000' matches existing G4110 geofence_boundary.
-- state='ma' LOWERCASE — routing query convention.
-- mtfcc=NULL — no TIGER mtfcc for LOCAL_EXEC districts.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'ma', '2567000', 'Springfield (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2567000' AND district_type = 'LOCAL_EXEC' AND state = 'ma'
);

-- =============================================================================
-- Step 3b: LOCAL district (all 13 councillors share single city-wide LOCAL district)
-- Tier 2 pattern: no per-ward geofences; ward/at-large distinction encoded in office title only.
-- mtfcc=NULL — no TIGER mtfcc for this manually-inserted LOCAL district.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', '2567000', 'Springfield', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2567000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (14 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='MA' uppercase
-- Mayor links to LOCAL_EXEC district; all 13 councillors link to LOCAL district.
-- =============================================================================

-- BLOCK 1: Mayor Domenic J. Sarno (-256700001) — links to LOCAL_EXEC district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Domenic J. Sarno', 'Domenic', 'Sarno', NULL,
          true, false, false, true, -256700001)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'Mayor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Ward 2 Councilor Michael A. Fenton (-256700002)
-- CRITICAL (Pitfall 7): title='City Councilor (Ward 2)' — NOT 'Council President'
-- Fenton holds the procedural 'Council President' role; DB stores the ward seat title only.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael A. Fenton', 'Michael', 'Fenton', NULL,
          true, false, false, true, -256700002)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 2)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Ward 3 Councilor Melvin A. Edwards (-256700003)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Melvin A. Edwards', 'Melvin', 'Edwards', NULL,
          true, false, false, true, -256700003)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 3)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Ward 1 Councilor Maria Perez (-256700004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maria Perez', 'Maria', 'Perez', NULL,
          true, false, false, true, -256700004)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 1)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Ward 4 Councilor Malo L. Brown (-256700005)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Malo L. Brown', 'Malo', 'Brown', NULL,
          true, false, false, true, -256700005)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 4)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Ward 5 Councilor Lavar Click-Bruce (-256700006)
-- Compound last name: last_name='Click-Bruce', first_name='Lavar'
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lavar Click-Bruce', 'Lavar', 'Click-Bruce', NULL,
          true, false, false, true, -256700006)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 5)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Ward 6 Councilor Victor G. Davila (-256700007)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Victor G. Davila', 'Victor', 'Davila', NULL,
          true, false, false, true, -256700007)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 6)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: Ward 7 Councilor Gerry Martin (-256700008)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gerry Martin', 'Gerry', 'Martin', NULL,
          true, false, false, true, -256700008)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 7)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Ward 8 Councilor Zaida Govan (-256700009)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Zaida Govan', 'Zaida', 'Govan', NULL,
          true, false, false, true, -256700009)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 8)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: At-Large Councilor Justin Hurst (-256700010)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Justin Hurst', 'Justin', 'Hurst', NULL,
          true, false, false, true, -256700010)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: At-Large Councilor Jose Delgado (-256700011)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jose Delgado', 'Jose', 'Delgado', NULL,
          true, false, false, true, -256700011)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: At-Large Councilor Kateri Walsh (-256700012)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kateri Walsh', 'Kateri', 'Walsh', NULL,
          true, false, false, true, -256700012)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 13: At-Large Councilor Tracye Whitfield (-256700013)
-- [Procedural Council President for at-large — title stored as 'City Councilor' per Pitfall 7]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tracye Whitfield', 'Tracye', 'Whitfield', NULL,
          true, false, false, true, -256700013)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 14: At-Large Councilor Brian Santaniello (-256700014)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Santaniello', 'Brian', 'Santaniello', NULL,
          true, false, false, true, -256700014)
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
                               WHERE name = 'City of Springfield, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2567000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 14 Springfield officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -256700014 AND -256700001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (7 gates)
-- Raises EXCEPTION on any failure.
-- Gate (a): 1 government row
-- Gate (b): 1 City Council chamber
-- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
-- Gate (d): 14 politicians in external_id range
-- Gate (e): 14 offices linked to Springfield districts
-- Gate (f): section-split = 0 orphan geofences for geo_id='2567000'
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
  WHERE name = 'City of Springfield, Massachusetts, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Springfield government row, found %', v_gov_count;
  END IF;

  -- Gate (b): City Council chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Springfield, Massachusetts, US');

  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City Council chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2567000'
    AND district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_dist_count <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 2 Springfield district rows, found %', v_dist_count;
  END IF;

  -- Gate (d): 14 politicians in external_id range
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -256700014 AND -256700001;

  IF v_pol_count <> 14 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 14 politicians in range -256700001..-256700014, found %', v_pol_count;
  END IF;

  -- Gate (e): 14 offices linked to Springfield districts (LOCAL_EXEC + LOCAL combined)
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.state = 'ma'
    AND d.geo_id = '2567000'
    AND d.district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_off_count <> 14 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 14 offices linked to Springfield districts, found %', v_off_count;
  END IF;

  -- Gate (f): section-split detector
  -- Springfield G4110 geofence must have at least one district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2567000'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.state = 'ma'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=2567000', v_split_count;
  END IF;

  -- Gate (g): office_id back-fill completeness
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -256700014 AND -256700001
    AND office_id IS NULL;

  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in external_id range have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 352 post-verification PASSED: gov=%, chambers=%, districts=%, politicians=%, offices=%, split_orphans=%, null_office_ids=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('352')
ON CONFLICT (version) DO NOTHING;
