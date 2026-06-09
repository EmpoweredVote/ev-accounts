-- Migration 313: Alexandria City Public Schools (ACPS) school board (VA-DEEP-02)
--
-- Purpose: Seeds ACPS school board (9 members) under a single TIGER UNSD SCHOOL district.
--   Alexandria City Public Schools  (geo_id='5100090') — 1 gov + 1 chamber + 1 SCHOOL district + 9 officials
-- Totals: 1 government, 1 chamber, 1 district, 9 politicians, 9 offices
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'va' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'VA' (uppercase). offices.representing_state = 'VA' (uppercase).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: G5420 geofence row inserted directly in this migration (no VA G5420 rows loaded by loader — D-03).
-- CRITICAL: geofence_boundaries.state = '51' (FIPS numeric string for Virginia).
-- CRITICAL: party=NULL on all 9 politicians (antipartisan — D-16).
-- CRITICAL: is_appointed=false, is_appointed_position=false on all (elected board members — D-17).
-- CRITICAL: Do NOT include tiger_geoid in district INSERT (D-08).
--
-- Roster verified 2026-06-09 from https://www.acps.k12.va.us/school-board/members-of-the-school-board
-- ACPS_GEOID: 5100090 (Virginia LEAID, confirmed Census TIGER UNSD geo_id)
-- External ID range: -5100090001 (Chair) through -5100090009 (last member alphabetically)
--
-- Applied to production Supabase via Supabase MCP (mcp__supabase-local is remote production DB).

-- =============================================================================
-- Pre-flight: RAISE EXCEPTION if government already exists (idempotency check)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Alexandria City Public Schools, Virginia, US') > 0 THEN
    RAISE EXCEPTION 'Migration 313 already applied — aborting re-run';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight: Verify external_id block is clear
-- Range: -5100090001 through -5100090009
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(5100090::bigint * 1000 + 9) AND -(5100090::bigint * 1000 + 1);
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -5100090001..-5100090009 is not clear (% rows found)', v_count;
  END IF;
END $$;

-- =============================================================================
-- Step 0: Insert ACPS G5420 geofence boundary
-- No VA G5420 rows loaded by TIGER loader (D-03) — must INSERT directly.
-- state='51' is FIPS numeric string for Virginia (matches geofence_boundaries convention).
-- =============================================================================
INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, state)
SELECT '5100090', 'G5420', '51'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries
  WHERE geo_id = '5100090' AND mtfcc = 'G5420'
);

-- =============================================================================
-- Step 1: Government row
-- type='LOCAL' matches school district type
-- governments.state = 'VA' uppercase (governments convention)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Alexandria City Public Schools, Virginia, US',
       'LOCAL', 'VA', NULL, '5100090'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Alexandria City Public Schools, Virginia, US'
);

-- =============================================================================
-- Step 2: School Board chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Board',
       'Alexandria City Public Schools Board',
       (SELECT id FROM essentials.governments
        WHERE name = 'Alexandria City Public Schools, Virginia, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Alexandria City Public Schools, Virginia, US')
);

-- =============================================================================
-- Step 3: SCHOOL district row
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='va' LOWERCASE — routing query uses geocoder output which is lowercase
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- CRITICAL: Do NOT include tiger_geoid column (D-08)
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'va', '5100090', 'Alexandria City Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '5100090' AND district_type = 'SCHOOL' AND state = 'va'
);

-- =============================================================================
-- Step 4: Politicians + offices (9 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan — D-16)
-- is_appointed=false, is_appointed_position=false (elected board members — D-17)
-- representing_state='VA' uppercase (offices convention)
-- is_incumbent=true (verified current board members)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- =============================================================================

-- ============================
-- ACPS SCHOOL BOARD — 9 members, geo_id='5100090'
-- All 9 board members link to the whole-district SCHOOL row (geo_id='5100090').
-- Source: https://www.acps.k12.va.us/school-board/members-of-the-school-board (verified 2026-06-09)
-- ============================

-- BLOCK 1: Michelle Rief (Chair) — -5100090001
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michelle Rief', 'Michelle', 'Rief', NULL,
          true, false, false, true, -5100090001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Board'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Alexandria City Public Schools, Virginia, US')),
       p.id,
       'School Board Chair', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5100090'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Christopher Harris (Vice Chair) — -5100090002
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christopher Harris', 'Christopher', 'Harris', NULL,
          true, false, false, true, -5100090002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Board'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Alexandria City Public Schools, Virginia, US')),
       p.id,
       'School Board Vice Chair', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5100090'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Abdulahi Abdalla (Member, alphabetical #1) — -5100090003
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Abdulahi Abdalla', 'Abdulahi', 'Abdalla', NULL,
          true, false, false, true, -5100090003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Board'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Alexandria City Public Schools, Virginia, US')),
       p.id,
       'School Board Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5100090'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Tim Beaty (Member, alphabetical #2) — -5100090004
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tim Beaty', 'Tim', 'Beaty', NULL,
          true, false, false, true, -5100090004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Board'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Alexandria City Public Schools, Virginia, US')),
       p.id,
       'School Board Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5100090'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Kelly Carmichael Booz (Member, alphabetical #3) — -5100090005
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kelly Carmichael Booz', 'Kelly', 'Carmichael Booz', NULL,
          true, false, false, true, -5100090005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Board'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Alexandria City Public Schools, Virginia, US')),
       p.id,
       'School Board Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5100090'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Donna Kenley (Member, alphabetical #4) — -5100090006
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Donna Kenley', 'Donna', 'Kenley', NULL,
          true, false, false, true, -5100090006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Board'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Alexandria City Public Schools, Virginia, US')),
       p.id,
       'School Board Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5100090'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Ryan Reyna (Member, alphabetical #5) — -5100090007
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ryan Reyna', 'Ryan', 'Reyna', NULL,
          true, false, false, true, -5100090007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Board'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Alexandria City Public Schools, Virginia, US')),
       p.id,
       'School Board Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5100090'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: Alexander Crider Scioscia (Member, alphabetical #6) — -5100090008
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alexander Crider Scioscia', 'Alexander', 'Scioscia', NULL,
          true, false, false, true, -5100090008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Board'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Alexandria City Public Schools, Virginia, US')),
       p.id,
       'School Board Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5100090'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Ashley Simpson Baird (Member, alphabetical #7) — -5100090009
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ashley Simpson Baird', 'Ashley', 'Simpson Baird', NULL,
          true, false, false, true, -5100090009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Board'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Alexandria City Public Schools, Virginia, US')),
       p.id,
       'School Board Member', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5100090'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 9 ACPS school board officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -(5100090::bigint * 1000 + 9) AND -(5100090::bigint * 1000 + 1)
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure.
-- Gate (a): government row count = 1
-- Gate (b): chamber count = 1
-- Gate (c): SCHOOL district count = 1
-- Gate (d): politician count = 9
-- Gate (e): office count = 9 (linked to SCHOOL district)
-- Gate (f): section-split = 0 orphan geofences
-- Gate (g): office_id back-fill complete (0 NULL)
-- =============================================================================
DO $$
DECLARE
  v_gov_count     INTEGER;
  v_chamber_count INTEGER;
  v_dist_count    INTEGER;
  v_pol_count     INTEGER;
  v_off_count     INTEGER;
  v_split_count   INTEGER;
  v_null_count    INTEGER;
BEGIN
  -- Gate (a): 1 government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'Alexandria City Public Schools, Virginia, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 ACPS government row, found %', v_gov_count;
  END IF;

  -- Gate (b): 1 School Board chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Alexandria City Public Schools, Virginia, US');
  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 School Board chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 1 SCHOOL district row
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'va'
    AND geo_id = '5100090';
  IF v_dist_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 SCHOOL district row for geo_id=5100090, found %', v_dist_count;
  END IF;

  -- Gate (d): 9 politicians in external_id range
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(5100090::bigint * 1000 + 9) AND -(5100090::bigint * 1000 + 1);
  IF v_pol_count <> 9 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 9 politicians in -5100090009..-5100090001 range, found %', v_pol_count;
  END IF;

  -- Gate (e): 9 offices linked to SCHOOL district
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'SCHOOL'
    AND d.geo_id = '5100090'
    AND d.state = 'va';
  IF v_off_count <> 9 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 9 offices linked to SCHOOL district geo_id=5100090, found %', v_off_count;
  END IF;

  -- Gate (f): Section-split check — G5420 geofence has SCHOOL district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '5100090'
    AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'SCHOOL'
        AND d.state = 'va'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split returned % orphan rows (G5420 geofence without SCHOOL district row)', v_split_count;
  END IF;

  -- Gate (g): Office_id back-fill complete
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(5100090::bigint * 1000 + 9) AND -(5100090::bigint * 1000 + 1)
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in -5100090009..-5100090001 range still have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 313 post-verification PASSED: gov_count=%, chamber_count=%, dist_count=%, pol_count=%, off_count=%, section_split=%, null_office_ids=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('313')
ON CONFLICT (version) DO NOTHING;
