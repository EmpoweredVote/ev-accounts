-- Migration 354: City of Brockton government (MA-TIER2-02)
--
-- Purpose: Seeds City of Brockton government and City Council.
--   - 1 government row: 'City of Brockton, Massachusetts, US' (type='LOCAL', state='MA', city='Brockton', geo_id='2509000')
--   - 1 chamber row: 'City Council' (name_formal='Brockton City Council'; no slug — GENERATED ALWAYS)
--   - 1 LOCAL_EXEC district row: geo_id='2509000', mtfcc=NULL, state='ma', label='Brockton (Citywide)'
--   - 1 LOCAL district row: geo_id='2509000', mtfcc=NULL, state='ma', label='Brockton'
--   - 12 politicians: Mayor Rodrigues (-250900001) + 7 ward councillors (-250900002..-250900008) + 4 at-large (-250900009..-250900012)
--   - 12 offices
--   - office_id back-fill on all 12
--
-- CRITICAL: Mayor is Moises M. Rodrigues (51st Mayor, inaugurated 2026-01-05). The prior mayor lost in Nov 2025.
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state = 'ma' (lowercase) for LOCAL, LOCAL_EXEC — matches routing queries.
-- CRITICAL: governments.state = 'MA' (uppercase) — government table convention.
-- CRITICAL: offices.representing_state = 'MA' (uppercase) — offices table convention.
-- CRITICAL: mtfcc=NULL on LOCAL_EXEC and LOCAL district rows.
-- CRITICAL: party=NULL (antipartisan design).
-- CRITICAL: is_appointed=false for all 12 (all popularly elected).
--
-- Brockton G4110 geofence (geo_id='2509000') already in geofence_boundaries from Phase 38 MA TIGER load.
--
-- Roster verified 2026-06-10 from brockton.ma.us/government/city-council/ + brockton.ma.us/news/:
--   Mayor Moises M. Rodrigues (LOCAL_EXEC) — inaugurated 2026-01-05
--   Ward 1: Marlon D. Green
--   Ward 2: Maria T. Tavares
--   Ward 3: Philip E. Griffin
--   Ward 4: Susan Nicastro
--   Ward 5: Jeffrey A. Thompson
--   Ward 6: John Lally (Council President — procedural title not stored as office)
--   Ward 7: Shirley Asack
--   At-Large: Carla Darosa
--   At-Large: Jeff Charnel
--   At-Large: Winthrop Farwell Jr. (last_name='Farwell')
--   At-Large: David C. Teixeira
--
-- State casing reference:
--   geofence_boundaries.state = '25'  (FIPS numeric — do NOT query/insert)
--   essentials.districts.state = 'ma' (lowercase postal)
--   essentials.governments.state = 'MA' (uppercase postal)
--   essentials.offices.representing_state = 'MA' (uppercase postal)
--
-- Applied to production via mcp__supabase-local__execute_sql (authoritative)
-- and _apply-migration-354.ts (fallback harness).

-- =============================================================================
-- Pre-flight 1: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Brockton, Massachusetts, US') > 0 THEN
    RAISE NOTICE 'City of Brockton government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Assert Brockton G4110 geofence is present
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2509000' AND mtfcc = 'G4110';
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Brockton G4110 geofence (geo_id=2509000) not found. Expected from Phase 38 MA TIGER load.';
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: Brockton G4110 geofence present';
END $$;

-- =============================================================================
-- Pre-flight 3: Assert external_id range -250900001..-250900012 is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -250900012 AND -250900001;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -250900001..-250900012 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: external_id range is clear';
END $$;

-- =============================================================================
-- Step 1: Government row (City of Brockton, Massachusetts, US)
-- type='LOCAL', state='MA' (uppercase), city='Brockton', geo_id='2509000'
-- WHERE NOT EXISTS guard — governments has no unique constraint on geo_id.
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Brockton, Massachusetts, US',
       'LOCAL', 'MA', 'Brockton', '2509000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Brockton, Massachusetts, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- Single chamber covers Mayor + 11 council seats.
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Brockton City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Brockton, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Brockton, Massachusetts, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district (Mayor — citywide)
-- geo_id='2509000' matches existing G4110 geofence_boundary.
-- state='ma' LOWERCASE — routing query convention.
-- mtfcc=NULL — no TIGER mtfcc for LOCAL_EXEC districts.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'ma', '2509000', 'Brockton (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2509000' AND district_type = 'LOCAL_EXEC' AND state = 'ma'
);

-- =============================================================================
-- Step 3b: LOCAL district (all 11 councillors share single citywide LOCAL district)
-- Tier 2 pattern: district encoded in office title, NOT per-district geofences.
-- mtfcc=NULL — no TIGER mtfcc for LOCAL districts.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', '2509000', 'Brockton', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2509000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (12 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='MA' uppercase
-- Mayor links to LOCAL_EXEC district; all councillors link to LOCAL district.
-- Ward title = 'City Councilor (Ward N)'; at-large title = 'City Councilor'
-- =============================================================================

-- BLOCK 1: Mayor Moises M. Rodrigues (-250900001) — links to LOCAL_EXEC district
-- CRITICAL: Rodrigues is the 51st Mayor (inaugurated 2026-01-05); the prior mayor was not re-elected.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Moises M. Rodrigues', 'Moises', 'Rodrigues', NULL,
          true, false, false, true, -250900001)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'Mayor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Ward 1 Councilor Marlon D. Green (-250900002)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marlon D. Green', 'Marlon', 'Green', NULL,
          true, false, false, true, -250900002)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 1)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Ward 2 Councilor Maria T. Tavares (-250900003)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maria T. Tavares', 'Maria', 'Tavares', NULL,
          true, false, false, true, -250900003)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 2)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Ward 3 Councilor Philip E. Griffin (-250900004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Philip E. Griffin', 'Philip', 'Griffin', NULL,
          true, false, false, true, -250900004)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 3)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Ward 4 Councilor Susan Nicastro (-250900005)
-- NOTE: Official brockton.ma.us spelling is 'Susan' (not 'Suan' as in some sources)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Susan Nicastro', 'Susan', 'Nicastro', NULL,
          true, false, false, true, -250900005)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 4)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Ward 5 Councilor Jeffrey A. Thompson (-250900006)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeffrey A. Thompson', 'Jeffrey', 'Thompson', NULL,
          true, false, false, true, -250900006)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 5)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Ward 6 Councilor John Lally (-250900007)
-- NOTE: John Lally also serves as Council President — procedural title NOT stored as office
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Lally', 'John', 'Lally', NULL,
          true, false, false, true, -250900007)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 6)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: Ward 7 Councilor Shirley Asack (-250900008)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shirley Asack', 'Shirley', 'Asack', NULL,
          true, false, false, true, -250900008)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 7)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: At-Large Councilor Carla Darosa (-250900009)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carla Darosa', 'Carla', 'Darosa', NULL,
          true, false, false, true, -250900009)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: At-Large Councilor Jeff Charnel (-250900010)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeff Charnel', 'Jeff', 'Charnel', NULL,
          true, false, false, true, -250900010)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: At-Large Councilor Winthrop Farwell Jr. (-250900011)
-- NOTE: last_name='Farwell' (not 'Farwell Jr.' — suffix stored in full_name only)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Winthrop Farwell Jr.', 'Winthrop', 'Farwell', NULL,
          true, false, false, true, -250900011)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: At-Large Councilor David C. Teixeira (-250900012)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David C. Teixeira', 'David', 'Teixeira', NULL,
          true, false, false, true, -250900012)
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
                               WHERE name = 'City of Brockton, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2509000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Links politicians.office_id → offices.id for all 12 Brockton officials.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -250900012 AND -250900001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification gates
-- Raises EXCEPTION on any gate failure — prevents partial/silent bad state.
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
  -- Gate 1: exactly 1 government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments WHERE name = 'City of Brockton, Massachusetts, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Brockton government row, found %', v_gov_count;
  END IF;

  -- Gate 2: exactly 1 chamber row for this government
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Brockton, Massachusetts, US');
  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Brockton City Council chamber, found %', v_chamber_count;
  END IF;

  -- Gate 3: exactly 2 districts (1 LOCAL_EXEC + 1 LOCAL)
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE state = 'ma' AND geo_id = '2509000'
    AND district_type IN ('LOCAL_EXEC', 'LOCAL');
  IF v_dist_count <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 2 Brockton district rows, found %', v_dist_count;
  END IF;

  -- Gate 4: exactly 12 politicians in the external_id block
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -250900012 AND -250900001;
  IF v_pol_count <> 12 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 12 Brockton politicians, found %', v_pol_count;
  END IF;

  -- Gate 5: exactly 12 offices linked to Brockton districts
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.state = 'ma' AND d.geo_id = '2509000'
    AND d.district_type IN ('LOCAL_EXEC', 'LOCAL');
  IF v_off_count <> 12 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 12 Brockton offices, found %', v_off_count;
  END IF;

  -- Gate 6: section-split check — geo_id=2509000 G4110 geofence must have a matching district
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2509000' AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = gb.geo_id AND d.state = 'ma');
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split orphan for geo_id=2509000 (count=%)', v_split_count;
  END IF;

  -- Gate 7: no NULL office_ids in the range
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -250900012 AND -250900001 AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % Brockton politicians have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 354 post-verification PASSED: gov=%, chambers=%, districts=%, politicians=%, offices=%, split_orphans=%, null_office_ids=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count;
END $$;

-- =============================================================================
-- Step 7: Migration ledger
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('354')
ON CONFLICT (version) DO NOTHING;
