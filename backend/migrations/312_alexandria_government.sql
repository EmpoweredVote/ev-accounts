-- Migration 312: Alexandria, Virginia city government (VA-DEEP-01)
--
-- Purpose: Seeds City of Alexandria government and City Council under geo_id='5101000'.
--   - 1 government row: 'City of Alexandria, Virginia, US' (type='LOCAL', state='VA', city='Alexandria', geo_id='5101000')
--   - 1 chamber row: 'City Council' (name_formal='Alexandria City Council'; no slug — GENERATED ALWAYS)
--   - 1 LOCAL_EXEC district row: geo_id='5101000', mtfcc=NULL, state='va', district_type='LOCAL_EXEC' (Mayor)
--   - 1 LOCAL district row: geo_id='5101000', mtfcc=NULL, state='va', district_type='LOCAL' (at-large council)
--   - 7 politicians: Mayor Gaskins (-5101000001) + 6 Council Members (-5101000002..-5101000007)
--   - 7 offices: Mayor links to LOCAL_EXEC; 6 Council Members link to LOCAL district
--   - office_id back-fill on all 7 politicians
--
-- Geofence boundary (G4110, geo_id='5101000', state='51') was loaded in Phase 100 — do NOT re-insert.
-- Analog: migration 277 (Leonardtown government — LOCAL/LOCAL_EXEC pattern).
-- Applied to production Supabase via Supabase MCP.
--
-- Roster verified 2026-06-08 from alexandriava.gov/Council:
--   Mayor Alyia Gaskins
--   Vice Mayor Sarah Bagley (title='Council Member' — Vice Mayor is procedural, not a separate office)
--   Council: Canek Aguirre, John Chapman, Abdel-Rahman Elnoubi, Jacinta E. Greene, Sandy Marks
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'va' (lowercase) for LOCAL/LOCAL_EXEC to match routing queries.
-- CRITICAL: governments.state = 'VA' (uppercase) — government table convention.
-- CRITICAL: governments.type = 'LOCAL' (not 'County') for independent city.
-- CRITICAL: mtfcc=NULL on LOCAL and LOCAL_EXEC district rows (migration 246/277 pattern).
-- NOTE: Alexandria is an independent city — geo_id='5101000' (G4110) is the LOCAL tier, NOT '51510' (COUNTY).

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Alexandria, Virginia, US') > 0 THEN
    RAISE NOTICE 'City of Alexandria government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (City of Alexandria, Virginia, US)
-- type='LOCAL' — independent city (NOT 'County')
-- state='VA' uppercase (governments table convention).
-- city='Alexandria' (populated for LOCAL governments)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Alexandria, Virginia, US',
       'LOCAL', 'VA', 'Alexandria', '5101000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Alexandria, Virginia, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Alexandria City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Alexandria, Virginia, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Alexandria, Virginia, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district (Mayor — citywide)
-- geo_id='5101000' matches the existing G4110 geofence_boundary loaded in Phase 100.
-- state='va' LOWERCASE — matches routing query convention.
-- mtfcc=NULL — no TIGER mtfcc code for LOCAL_EXEC districts (migration 246/277 pattern).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'va', '5101000', 'Alexandria (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '5101000' AND district_type = 'LOCAL_EXEC' AND state = 'va'
);

-- =============================================================================
-- Step 3b: LOCAL district (all 6 council members share this — at-large)
-- mtfcc=NULL — no TIGER mtfcc code for LOCAL districts (migration 246/277 pattern).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'va', '5101000', 'Alexandria (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '5101000' AND district_type = 'LOCAL' AND state = 'va'
);

-- =============================================================================
-- Step 4: Politicians + offices (7 blocks — Mayor + 6 Council Members)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='VA' uppercase (offices table convention)
-- Mayor office links to LOCAL_EXEC district; all council offices link to LOCAL district.
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- =============================================================================

-- BLOCK 1: Mayor Alyia Gaskins (-5101000001) — links to LOCAL_EXEC district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alyia Gaskins', 'Alyia', 'Gaskins', NULL,
          true, false, false, true, -5101000001)
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
                               WHERE name = 'City of Alexandria, Virginia, US')),
       p.id,
       'Mayor', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5101000'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Council Member Canek Aguirre (-5101000002) — links to LOCAL district
-- Alphabetical by last name (Aguirre = 1st of 6)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Canek Aguirre', 'Canek', 'Aguirre', NULL,
          true, false, false, true, -5101000002)
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
                               WHERE name = 'City of Alexandria, Virginia, US')),
       p.id,
       'Council Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5101000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Council Member Sarah Bagley (-5101000003) — links to LOCAL district
-- Alphabetical by last name (Bagley = 2nd of 6)
-- Note: Sarah Bagley is also Vice Mayor — that is a procedural role, not a separate elected office;
-- title remains 'Council Member' per Leonardtown convention (Pitfall 5 equivalent).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sarah Bagley', 'Sarah', 'Bagley', NULL,
          true, false, false, true, -5101000003)
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
                               WHERE name = 'City of Alexandria, Virginia, US')),
       p.id,
       'Council Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5101000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Council Member John Chapman (-5101000004) — links to LOCAL district
-- Alphabetical by last name (Chapman = 3rd of 6)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Chapman', 'John', 'Chapman', NULL,
          true, false, false, true, -5101000004)
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
                               WHERE name = 'City of Alexandria, Virginia, US')),
       p.id,
       'Council Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5101000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Council Member Abdel-Rahman Elnoubi (-5101000005) — links to LOCAL district
-- Alphabetical by last name (Elnoubi = 4th of 6)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Abdel-Rahman Elnoubi', 'Abdel-Rahman', 'Elnoubi', NULL,
          true, false, false, true, -5101000005)
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
                               WHERE name = 'City of Alexandria, Virginia, US')),
       p.id,
       'Council Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5101000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Council Member Jacinta E. Greene (-5101000006) — links to LOCAL district
-- Alphabetical by last name (Greene = 5th of 6)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jacinta E. Greene', 'Jacinta', 'Greene', NULL,
          true, false, false, true, -5101000006)
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
                               WHERE name = 'City of Alexandria, Virginia, US')),
       p.id,
       'Council Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5101000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Council Member Sandy Marks (-5101000007) — links to LOCAL district
-- Alphabetical by last name (Marks = 6th of 6)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sandy Marks', 'Sandy', 'Marks', NULL,
          true, false, false, true, -5101000007)
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
                               WHERE name = 'City of Alexandria, Virginia, US')),
       p.id,
       'Council Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5101000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 7 Alexandria officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -5101000007 AND -5101000001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the apply_migration transaction.
-- Gate (a): government row count must be exactly 1
-- Gate (b): offices linked to ANY district with geo_id='5101000' AND state='va' must be exactly 7
--   (covers both LOCAL_EXEC Mayor office + 6 LOCAL council offices)
-- Gate (c): section-split detector must return 0 orphan rows
-- Gate (d): politicians with office_id IS NULL in external_id range must be 0
-- =============================================================================
DO $$
DECLARE
  v_gov_count INTEGER;
  v_office_count INTEGER;
  v_split_count INTEGER;
  v_null_office_count INTEGER;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'City of Alexandria, Virginia, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Alexandria government row, found %', v_gov_count;
  END IF;

  -- Gate (b): ALL offices linked to Alexandria districts (LOCAL_EXEC + LOCAL combined)
  -- Do NOT filter on district_type — must count both Mayor (LOCAL_EXEC) and 6 council (LOCAL)
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '5101000'
    AND d.state = 'va';

  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 offices linked to geo_id=5101000 districts, found %', v_office_count;
  END IF;

  -- Gate (c): section-split detector
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '5101000'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.state = 'va'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=5101000', v_split_count;
  END IF;

  -- Gate (d): office_id back-fill completeness
  SELECT COUNT(*) INTO v_null_office_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -5101000007 AND -5101000001
    AND office_id IS NULL;

  IF v_null_office_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in external_id range have NULL office_id', v_null_office_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov_count=%, office_count=%, split_orphans=%, null_office_ids=%',
    v_gov_count, v_office_count, v_split_count, v_null_office_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('312')
ON CONFLICT (version) DO NOTHING;
