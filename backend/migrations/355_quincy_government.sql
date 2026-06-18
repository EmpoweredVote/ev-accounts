-- Migration 355: City of Quincy government (MA-TIER2-02)
--
-- Purpose: Seeds City of Quincy government and City Council.
--   - 1 government row: 'City of Quincy, Massachusetts, US' (type='LOCAL', state='MA', city='Quincy', geo_id='2555745')
--   - 1 chamber row: 'City Council' (name_formal='Quincy City Council'; no slug — GENERATED ALWAYS)
--   - 1 LOCAL_EXEC district row: geo_id='2555745', mtfcc=NULL, state='ma', label='Quincy (Citywide)' (Mayor)
--   - 1 LOCAL district row: geo_id='2555745', mtfcc=NULL, state='ma', label='Quincy' (9 councillors)
--   - 10 politicians: Mayor Koch (-255574501) + 6 ward councillors (-255574502..-255574507) + 3 at-large (-255574508..-255574510)
--   - 10 offices: Mayor links to LOCAL_EXEC; 9 councillors to LOCAL district
--   - office_id back-fill on all 10 politicians
--
-- NOTE: geo_id='2555745' is a non-round GEOID — use exact string in all queries.
-- Quincy G4110 geofence (geo_id='2555745') already loaded from v5.0 — do NOT re-insert.
--
-- ROSTER: All-new council inaugurated January 2026 (7 of 9 seats changed hands in November 2025 election).
-- DO NOT seed pre-2026 council members (stale 2024 roster — replaced Jan 2026).
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state = 'ma' (lowercase) for LOCAL, LOCAL_EXEC — matches routing queries.
-- CRITICAL: governments.state = 'MA' (uppercase) — government table convention.
-- CRITICAL: offices.representing_state = 'MA' (uppercase) — offices table convention.
-- CRITICAL: mtfcc=NULL on LOCAL_EXEC and LOCAL district rows (no per-ward geofences).
-- CRITICAL: party=NULL (antipartisan design — D-15).
-- CRITICAL: is_appointed=false for all 10 (Mayor + councillors are popularly elected — D-16).
-- CRITICAL: Ziqiang Yuan goes by "Susan" — store formal name full_name='Ziqiang Yuan' (A6).
-- CRITICAL: Anne Mahoney is Council President — procedural title; office title='City Councilor' (A1).
--
-- Roster verified from quincyma.gov/government/elected_officials/ 2026:
--   Mayor Thomas P. Koch (seventh term, confirmed Feb 2026)
--   Ward 1: David Jacobs
--   Ward 2: Richard Ash
--   Ward 3: Walter Hubley
--   Ward 4: Virginia Ryan
--   Ward 5: Maggie McKee
--   Ward 6: Deborah Riley
--   At-Large: Noel DiBona
--   At-Large: Anne Mahoney (Council President — procedural title; office title='City Councilor')
--   At-Large: Ziqiang Yuan (goes by "Susan" — store formal name 'Ziqiang Yuan')
--
-- Applied to production via _apply-migration-355.ts.

-- =============================================================================
-- Pre-flight 1: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Quincy, Massachusetts, US') > 0 THEN
    RAISE NOTICE 'City of Quincy government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Assert Quincy G4110 geofence is present (do NOT re-insert)
-- geo_id='2555745' is non-round — exact string required.
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2555745' AND mtfcc = 'G4110';
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Quincy G4110 geofence (geo_id=2555745) not found. Expected from Phase 38 MA TIGER load.';
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: Quincy G4110 geofence present';
END $$;

-- =============================================================================
-- Pre-flight 3: Assert external_id range -255574510..-255574501 is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -255574510 AND -255574501;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -255574501..-255574510 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: external_id range is clear';
END $$;

-- =============================================================================
-- Step 1: Government row (City of Quincy, Massachusetts, US)
-- type='LOCAL', state='MA' (uppercase), city='Quincy', geo_id='2555745'
-- WHERE NOT EXISTS guard — governments has no unique constraint on geo_id (D-14).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Quincy, Massachusetts, US',
       'LOCAL', 'MA', 'Quincy', '2555745'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Quincy, Massachusetts, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- Single chamber covers all 9 seats (6 ward + 3 at-large).
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list (D-13).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Quincy City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Quincy, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Quincy, Massachusetts, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district (Mayor Koch — citywide)
-- geo_id='2555745' matches existing G4110 geofence_boundary.
-- state='ma' LOWERCASE (D-10 — routing query convention).
-- mtfcc=NULL — no TIGER mtfcc for LOCAL_EXEC districts (D-12).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'ma', '2555745', 'Quincy (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2555745' AND district_type = 'LOCAL_EXEC' AND state = 'ma'
);

-- =============================================================================
-- Step 3b: LOCAL district (9 councillors — 6 ward + 3 at-large share this district)
-- mtfcc=NULL — no per-ward geofences for Quincy (D-12).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', '2555745', 'Quincy', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2555745' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (10 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design — D-15)
-- is_appointed=false, is_appointed_position=false (all popularly elected — D-16)
-- representing_state='MA' uppercase (D-11)
-- Mayor links to LOCAL_EXEC district; all 9 councillors to LOCAL district.
-- =============================================================================

-- BLOCK 1: Mayor Thomas P. Koch (-255574501) — links to LOCAL_EXEC district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thomas P. Koch', 'Thomas', 'Koch', NULL,
          true, false, false, true, -255574501)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'Mayor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Ward 1 Councillor David Jacobs (-255574502)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Jacobs', 'David', 'Jacobs', NULL,
          true, false, false, true, -255574502)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 1)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Ward 2 Councillor Richard Ash (-255574503)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Ash', 'Richard', 'Ash', NULL,
          true, false, false, true, -255574503)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 2)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Ward 3 Councillor Walter Hubley (-255574504)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Walter Hubley', 'Walter', 'Hubley', NULL,
          true, false, false, true, -255574504)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 3)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Ward 4 Councillor Virginia Ryan (-255574505)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Virginia Ryan', 'Virginia', 'Ryan', NULL,
          true, false, false, true, -255574505)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 4)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Ward 5 Councillor Maggie McKee (-255574506)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maggie McKee', 'Maggie', 'McKee', NULL,
          true, false, false, true, -255574506)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 5)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Ward 6 Councillor Deborah Riley (-255574507)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Deborah Riley', 'Deborah', 'Riley', NULL,
          true, false, false, true, -255574507)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'City Councilor (Ward 6)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: At-Large Councillor Noel DiBona (-255574508)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Noel DiBona', 'Noel', 'DiBona', NULL,
          true, false, false, true, -255574508)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: At-Large Councillor Anne Mahoney (-255574509) [Council President — procedural title]
-- title='City Councilor' — procedural Council President title NOT stored as office (A1)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anne Mahoney', 'Anne', 'Mahoney', NULL,
          true, false, false, true, -255574509)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: At-Large Councillor Ziqiang Yuan (-255574510)
-- CRITICAL: full_name='Ziqiang Yuan' — goes by "Susan" but store formal name (A6)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ziqiang Yuan', 'Ziqiang', 'Yuan', NULL,
          true, false, false, true, -255574510)
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
                               WHERE name = 'City of Quincy, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2555745'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 10 Quincy officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -255574510 AND -255574501
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (7 gates)
-- Raises EXCEPTION on any failure.
-- Gate (a): 1 government row
-- Gate (b): 1 City Council chamber
-- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
-- Gate (d): 10 politicians in external_id range
-- Gate (e): 10 offices linked to Quincy districts
-- Gate (f): section-split = 0 orphan geofences for geo_id='2555745'
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
  WHERE name = 'City of Quincy, Massachusetts, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Quincy government row, found %', v_gov_count;
  END IF;

  -- Gate (b): City Council chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Quincy, Massachusetts, US');

  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City Council chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE geo_id = '2555745'
    AND state = 'ma'
    AND district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_dist_count <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 2 Quincy district rows, found %', v_dist_count;
  END IF;

  -- Gate (d): 10 politicians
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -255574510 AND -255574501;

  IF v_pol_count <> 10 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 10 politicians in range -255574501..-255574510, found %', v_pol_count;
  END IF;

  -- Gate (e): 10 offices linked to Quincy districts (LOCAL_EXEC + LOCAL combined)
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2555745'
    AND d.state = 'ma'
    AND d.district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_off_count <> 10 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 10 offices linked to Quincy districts, found %', v_off_count;
  END IF;

  -- Gate (f): section-split detector
  -- Quincy G4110 geofence must have at least one district row (no longer an orphan)
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2555745'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.state = 'ma'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=2555745', v_split_count;
  END IF;

  -- Gate (g): office_id back-fill completeness
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -255574510 AND -255574501
    AND office_id IS NULL;

  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in external_id range have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 355 post-verification PASSED: gov=%, chambers=%, districts=%, politicians=%, offices=%, split_orphans=%, null_office_ids=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('355')
ON CONFLICT (version) DO NOTHING;
