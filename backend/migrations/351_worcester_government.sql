-- Migration 351: City of Worcester government (MA-TIER2-01)
--
-- Purpose: Seeds City of Worcester government and City Council.
--   - 1 government row: 'City of Worcester, Massachusetts, US' (type='LOCAL', state='MA', city='Worcester', geo_id='2582000')
--   - 1 chamber row: 'City Council' (name_formal='Worcester City Council'; no slug — GENERATED ALWAYS)
--   - 1 LOCAL_EXEC district row: geo_id='2582000', mtfcc=NULL, state='ma', label='Worcester (Citywide)' (Mayor)
--   - 1 LOCAL district row: geo_id='2582000', mtfcc=NULL, state='ma', label='Worcester' (all councillors)
--   - 11 politicians: Mayor Petty (-258200001) + 5 at-large councillors (-258200002..-258200006) + 5 district councillors (-258200007..-258200011)
--   - 11 offices: Mayor links to LOCAL_EXEC; all 10 councillors link to LOCAL
--   - office_id back-fill on all 11 politicians
--
-- Tier 2 pattern: NO per-district geofences; single city geo_id='2582000' for all officials.
-- District/ward encoded in office title strings: 'City Councilor (District 1)' etc.
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state = 'ma' (lowercase) for LOCAL, LOCAL_EXEC — matches routing queries.
-- CRITICAL: governments.state = 'MA' (uppercase) — government table convention.
-- CRITICAL: offices.representing_state = 'MA' (uppercase) — offices table convention.
-- CRITICAL: mtfcc=NULL on all LOCAL and LOCAL_EXEC district rows (not 'G4110').
-- CRITICAL: party=NULL (antipartisan design).
-- CRITICAL: is_appointed=false for all 11 (all popularly elected).
--
-- Roster verified 2026-06-10 from worcesterma.gov/city-council/councilors:
--   Mayor Joseph M. Petty (LOCAL_EXEC, also serves as Councilor-at-Large — one office row)
--   At-Large: Khrystian E. King, Satya B. Mitra, Kathleen M. Toomey, Morris A. Bergman, Gary Rosen
--   District 1: Tony Economou
--   District 2: Robert A. Bilotta
--   District 3: John P. Fresolo
--   District 4: Luis A. Ojeda
--   District 5: Jose A. Rivera
--
-- Applied to production via mcp__supabase-local__execute_sql.

-- =============================================================================
-- Pre-flight 1: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Worcester, Massachusetts, US') > 0 THEN
    RAISE NOTICE 'City of Worcester government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Assert Worcester G4110 geofence is present
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2582000' AND mtfcc = 'G4110';
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Worcester G4110 geofence (geo_id=2582000) not found. Expected from v5.0 MA TIGER load.';
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: Worcester G4110 geofence present';
END $$;

-- =============================================================================
-- Pre-flight 3: Assert external_id range -258200001..-258200011 is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -258200011 AND -258200001;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -258200001..-258200011 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: external_id range is clear';
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Government row (City of Worcester, Massachusetts, US)
-- type='LOCAL', state='MA' (uppercase), city='Worcester', geo_id='2582000'
-- WHERE NOT EXISTS guard — governments has no unique constraint on geo_id.
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Worcester, Massachusetts, US',
       'LOCAL', 'MA', 'Worcester', '2582000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Worcester, Massachusetts, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- Single chamber covers all 10 council seats (5 at-large + 5 district).
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Worcester City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Worcester, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Worcester, Massachusetts, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district (Mayor Petty — citywide)
-- geo_id='2582000' matches existing G4110 geofence_boundary.
-- state='ma' LOWERCASE (routing query convention).
-- mtfcc=NULL — no TIGER mtfcc for LOCAL_EXEC districts.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'ma', '2582000', 'Worcester (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2582000' AND district_type = 'LOCAL_EXEC' AND state = 'ma'
);

-- =============================================================================
-- Step 3b: LOCAL district — all 10 councillors share this single city-wide district
-- Tier 2 pattern: no per-district geofences; ward/district encoded in office title.
-- mtfcc=NULL — no TIGER mtfcc for LOCAL districts.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', '2582000', 'Worcester', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2582000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (11 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='MA' uppercase
-- Mayor links to LOCAL_EXEC district; all councillors link to LOCAL district.
-- =============================================================================

-- BLOCK 1: Mayor Joseph M. Petty (-258200001) — links to LOCAL_EXEC district
-- Mayor is also Councilor-at-Large; one office row in LOCAL_EXEC per A2 decision.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joseph M. Petty', 'Joseph', 'Petty', NULL,
          true, false, false, true, -258200001)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'Mayor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: At-Large Councillor Khrystian E. King (-258200002)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Khrystian E. King', 'Khrystian', 'King', NULL,
          true, false, false, true, -258200002)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: At-Large Councillor Satya B. Mitra (-258200003)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Satya B. Mitra', 'Satya', 'Mitra', NULL,
          true, false, false, true, -258200003)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: At-Large Councillor Kathleen M. Toomey (-258200004)
-- Goes by "Kate Toomey" colloquially; official name is "Kathleen M. Toomey".
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kathleen M. Toomey', 'Kathleen', 'Toomey', NULL,
          true, false, false, true, -258200004)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: At-Large Councillor Morris A. Bergman (-258200005)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Morris A. Bergman', 'Morris', 'Bergman', NULL,
          true, false, false, true, -258200005)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: At-Large Councillor Gary Rosen (-258200006)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gary Rosen', 'Gary', 'Rosen', NULL,
          true, false, false, true, -258200006)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: District 1 Councillor Tony Economou (-258200007)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tony Economou', 'Tony', 'Economou', NULL,
          true, false, false, true, -258200007)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor (District 1)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: District 2 Councillor Robert A. Bilotta (-258200008)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Robert A. Bilotta', 'Robert', 'Bilotta', NULL,
          true, false, false, true, -258200008)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor (District 2)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: District 3 Councillor John P. Fresolo (-258200009)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John P. Fresolo', 'John', 'Fresolo', NULL,
          true, false, false, true, -258200009)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor (District 3)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: District 4 Councillor Luis A. Ojeda (-258200010)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Luis A. Ojeda', 'Luis', 'Ojeda', NULL,
          true, false, false, true, -258200010)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor (District 4)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: District 5 Councillor Jose A. Rivera (-258200011)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jose A. Rivera', 'Jose', 'Rivera', NULL,
          true, false, false, true, -258200011)
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
                               WHERE name = 'City of Worcester, Massachusetts, US')),
       p.id,
       'City Councilor (District 5)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2582000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 11 Worcester officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -258200011 AND -258200001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (7 gates)
-- Raises EXCEPTION on any failure.
-- Gate (a): 1 government row
-- Gate (b): 1 City Council chamber
-- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
-- Gate (d): 11 politicians in external_id range
-- Gate (e): 11 offices linked to Worcester districts
-- Gate (f): section-split = 0 orphan geofences for geo_id='2582000'
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
  WHERE name = 'City of Worcester, Massachusetts, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Worcester government row, found %', v_gov_count;
  END IF;

  -- Gate (b): City Council chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Worcester, Massachusetts, US');

  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City Council chamber for Worcester, found %', v_chamber_count;
  END IF;

  -- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2582000'
    AND district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_dist_count <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 2 Worcester district rows (LOCAL_EXEC + LOCAL), found %', v_dist_count;
  END IF;

  -- Gate (d): 11 politicians
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -258200011 AND -258200001;

  IF v_pol_count <> 11 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 11 politicians in range -258200001..-258200011, found %', v_pol_count;
  END IF;

  -- Gate (e): 11 offices linked to Worcester districts
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.state = 'ma'
    AND d.geo_id = '2582000'
    AND d.district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_off_count <> 11 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 11 offices linked to Worcester districts, found %', v_off_count;
  END IF;

  -- Gate (f): section-split detector
  -- Worcester G4110 geofence must have at least one district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2582000'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.state = 'ma'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=2582000', v_split_count;
  END IF;

  -- Gate (g): office_id back-fill completeness
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -258200011 AND -258200001
    AND office_id IS NULL;

  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in external_id range have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 351 post-verification PASSED: gov=%, chambers=%, districts=%, politicians=%, offices=%, split_orphans=%, null_office_ids=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('351')
ON CONFLICT (version) DO NOTHING;

COMMIT;
