-- Migration 579: Newton Public Schools school committee (NEWTON-01)
--
-- Purpose: Seeds Newton Public Schools school committee under SCHOOL district.
--   geo_id='2508610' (NCES LEAID for Newton Public Schools, MA FIPS=25)
-- Totals: 1 government, 1 chamber, 1 SCHOOL district, 8 new politicians, 9 offices
--   (8 elected + 1 Mayor ex-officio linking existing politician external_id=-2545560001)
--
-- CRITICAL: G5420 geofence inserted directly (no MA G5420 TIGER loader — D-05).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: districts.state = 'ma' (lowercase) to match routing queries (D-10).
-- CRITICAL: governments.state = 'MA' (uppercase). offices.representing_state = 'MA' (uppercase) (D-11).
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint — WHERE NOT EXISTS guard on name.
-- CRITICAL: geofence_boundaries.state = '25' (Massachusetts FIPS numeric string — D-20).
-- CRITICAL: party=NULL on all politicians (antipartisan — D-15).
-- CRITICAL: is_appointed=false for all 8 ward-elected SC members (elected — RESEARCH.md).
-- CRITICAL: is_appointed_position=false (public governing body).
-- CRITICAL: Mayor Laredo (external_id=-2545560001) seeded in migration 578 — DO NOT re-insert.
--           Block 9 uses subquery on existing politician; no new INSERT.
-- CRITICAL: office_id back-fill (Step 5) EXCLUDES external_id=-2545560001 — Mayor's office_id
--           must keep pointing to his LOCAL_EXEC office from migration 578.
--
-- 8 elected members (all Jan 2026 — ward-based election Nov 2025):
--   -2508610001 Arrianna Proia    (Ward 1)
--   -2508610002 Linda Swain       (Ward 2)
--   -2508610003 Jason Bhardwaj    (Ward 3, Vice Chair)
--   -2508610004 Tamika Olszewski  (Ward 4)
--   -2508610005 Ben Schlesinger   (Ward 5)
--   -2508610006 Jonathan Greene   (Ward 6)
--   -2508610007 Alicia Piedalue   (Ward 7, Chair)
--   -2508610008 Victor Lee        (Ward 8)
-- 9th office: Mayor Marc C. Laredo (external_id=-2545560001) — ex officio, links existing row
--
-- Sources: newton.k12.ma.us/school-committee, Newton Beacon Nov 2025, nces.ed.gov (LEAID=2508610)
-- Applied to production Supabase via mcp__supabase-local (remote production DB)

-- =============================================================================
-- Pre-flight 1: RAISE EXCEPTION if government already exists (idempotency check)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Newton Public Schools, Massachusetts, US') > 0 THEN
    RAISE EXCEPTION 'Migration 579 already applied — aborting re-run';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Verify external_id block for SC members is clear
-- Range: -2508610001 through -2508610008
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2508610::bigint * 1000 + 8) AND -(2508610::bigint * 1000 + 1);
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -2508610001..-2508610008 is not clear (% rows found)', v_count;
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 3: Verify Mayor Laredo (external_id=-2545560001) exists from migration 578
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id = -2545560001;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Mayor Laredo (external_id=-2545560001) not found — run migration 578 first';
  END IF;
END $$;

-- =============================================================================
-- Step 0: Insert Newton Public Schools G5420 geofence boundary
-- No MA G5420 rows loaded by TIGER loader (D-05) — must INSERT directly.
-- geo_id='2508610' (NCES LEAID for Newton Public Schools)
-- state='25' is FIPS numeric string for Massachusetts (D-20).
-- =============================================================================
INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, state)
SELECT '2508610', 'G5420', '25'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries
  WHERE geo_id = '2508610' AND mtfcc = 'G5420'
);

-- =============================================================================
-- Step 1: Government row — Newton Public Schools
-- type='LOCAL' matches school district type
-- governments.state = 'MA' uppercase (D-11)
-- city=NULL (school district spans the whole city, no single city value)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Newton Public Schools, Massachusetts, US',
       'LOCAL', 'MA', NULL, '2508610'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Newton Public Schools, Massachusetts, US'
);

-- =============================================================================
-- Step 2: School Committee chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Committee',
       'Newton School Committee',
       (SELECT id FROM essentials.governments
        WHERE name = 'Newton Public Schools, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Newton Public Schools, Massachusetts, US')
);

-- =============================================================================
-- Step 3: SCHOOL district row
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='ma' LOWERCASE — routing query uses lowercase state (D-10)
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ma', '2508610', 'Newton Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2508610' AND district_type = 'SCHOOL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (8 elected blocks + 1 Mayor ex-officio block)
-- Pattern for blocks 1-8: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan — D-15)
-- is_appointed=false (all 8 ward members are popularly elected — D-16)
-- is_appointed_position=false (public governing body, not bureaucratic staff)
-- representing_state='MA' uppercase (D-11)
-- is_incumbent=true (verified current committee members, Jan 2026)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- Block 9 (Mayor ex-officio): NO new politician INSERT — subquery on external_id=-2545560001
-- =============================================================================

-- ============================
-- NEWTON SCHOOL COMMITTEE — 8 elected members + 1 Mayor ex-officio, geo_id='2508610'
-- All members link to the whole-district SCHOOL row (geo_id='2508610').
-- Source: newton.k12.ma.us/school-committee (verified 2026-06-14)
-- ============================

-- BLOCK 1: Arrianna Proia (Ward 1) — -2508610001
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Arrianna Proia', 'Arrianna', 'Proia', NULL,
          true, false, false, true, -2508610001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Newton Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2508610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Linda Swain (Ward 2) — -2508610002
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Linda Swain', 'Linda', 'Swain', NULL,
          true, false, false, true, -2508610002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Newton Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2508610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Jason Bhardwaj (Ward 3, Vice Chair) — -2508610003
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jason Bhardwaj', 'Jason', 'Bhardwaj', NULL,
          true, false, false, true, -2508610003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Newton Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Vice Chair', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2508610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Tamika Olszewski (Ward 4) — -2508610004
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tamika Olszewski', 'Tamika', 'Olszewski', NULL,
          true, false, false, true, -2508610004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Newton Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2508610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Ben Schlesinger (Ward 5) — -2508610005
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ben Schlesinger', 'Ben', 'Schlesinger', NULL,
          true, false, false, true, -2508610005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Newton Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2508610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Jonathan Greene (Ward 6) — -2508610006
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jonathan Greene', 'Jonathan', 'Greene', NULL,
          true, false, false, true, -2508610006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Newton Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2508610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Alicia Piedalue (Ward 7, Chair) — -2508610007
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alicia Piedalue', 'Alicia', 'Piedalue', NULL,
          true, false, false, true, -2508610007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Newton Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Chair', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2508610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: Victor Lee (Ward 8) — -2508610008
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Victor Lee', 'Victor', 'Lee', NULL,
          true, false, false, true, -2508610008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Newton Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2508610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Mayor Marc C. Laredo (ex officio) — existing politician external_id=-2545560001
-- CRITICAL: DO NOT INSERT a new politician row.
-- Reuses existing politician from migration 578 via subquery on external_id=-2545560001.
-- Mayor is the 9th voting member of the School Committee.
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Newton Public Schools, Massachusetts, US')),
       p.id,
       'Mayor (ex officio)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN (SELECT id FROM essentials.politicians WHERE external_id = -2545560001) p
WHERE d.geo_id = '2508610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill (8 SC members ONLY — NOT Mayor Laredo)
-- CRITICAL: external_id=-2545560001 (Mayor) is intentionally EXCLUDED from this range.
-- Mayor's office_id must continue pointing to his LOCAL_EXEC office from migration 578.
-- Range: -2508610008 through -2508610001 (8 elected SC members only)
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -(2508610::bigint * 1000 + 8) AND -(2508610::bigint * 1000 + 1)
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure (9 gates).
-- Gate (a): government row count = 1
-- Gate (b): chamber count = 1
-- Gate (c): SCHOOL district count = 1
-- Gate (d): SC politician count = 8 (Mayor NOT in range)
-- Gate (e): total offices linked to SCHOOL district = 9 (8 elected + 1 Mayor ex-officio)
-- Gate (f): section-split = 0 orphan geofences
-- Gate (g): office_id back-fill complete = 0 NULL in SC range
-- Gate (h): G5420 geofence present (geo_id='2508610', state='25')
-- Gate (i): Mayor Laredo office_id still points to LOCAL_EXEC district
-- =============================================================================
DO $$
DECLARE
  v_gov_count        INTEGER;
  v_chamber_count    INTEGER;
  v_dist_count       INTEGER;
  v_pol_count        INTEGER;
  v_off_count        INTEGER;
  v_split_count      INTEGER;
  v_null_count       INTEGER;
  v_geo_count        INTEGER;
  v_mayor_exec_count INTEGER;
BEGIN
  -- Gate (a): 1 government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'Newton Public Schools, Massachusetts, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 NPS government row, found %', v_gov_count;
  END IF;

  -- Gate (b): 1 School Committee chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Newton Public Schools, Massachusetts, US');
  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 School Committee chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 1 SCHOOL district row
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'ma'
    AND geo_id = '2508610';
  IF v_dist_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 SCHOOL district row for geo_id=2508610, found %', v_dist_count;
  END IF;

  -- Gate (d): 8 politicians in SC range (Mayor NOT in this range)
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2508610::bigint * 1000 + 8) AND -(2508610::bigint * 1000 + 1);
  IF v_pol_count <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 8 SC politicians in -2508610008..-2508610001, found %', v_pol_count;
  END IF;

  -- Gate (e): 9 offices linked to SCHOOL district (8 elected + 1 Mayor ex-officio)
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'SCHOOL'
    AND d.geo_id = '2508610'
    AND d.state = 'ma';
  IF v_off_count <> 9 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 9 offices linked to SCHOOL district geo_id=2508610, found %', v_off_count;
  END IF;

  -- Gate (f): Section-split check — G5420 geofence has SCHOOL district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2508610'
    AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'SCHOOL'
        AND d.state = 'ma'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split returned % orphan rows (G5420 geofence without SCHOOL district row)', v_split_count;
  END IF;

  -- Gate (g): Office_id back-fill complete for 8 SC members
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2508610::bigint * 1000 + 8) AND -(2508610::bigint * 1000 + 1)
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in -2508610008..-2508610001 range still have NULL office_id', v_null_count;
  END IF;

  -- Gate (h): G5420 geofence present for Newton Public Schools (geo_id='2508610', state='25')
  SELECT COUNT(*) INTO v_geo_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2508610'
    AND mtfcc = 'G5420'
    AND state = '25';
  IF v_geo_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 G5420 geofence for geo_id=2508610 state=25, found %', v_geo_count;
  END IF;

  -- Gate (i): Mayor Laredo office_id still points to LOCAL_EXEC district (not overwritten)
  SELECT COUNT(*) INTO v_mayor_exec_count
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE p.external_id = -2545560001
    AND d.district_type = 'LOCAL_EXEC'
    AND d.geo_id = '2545560';
  IF v_mayor_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor Laredo office_id back-fill overwrote LOCAL_EXEC — CRITICAL BUG (expected 1, found %)', v_mayor_exec_count;
  END IF;

  RAISE NOTICE 'Migration 579 post-verification PASSED: gov=%, chambers=%, districts=%, sc_politicians=%, total_school_offices=%, split_orphans=%, null_sc_office_ids=%, geo_count=%, mayor_local_exec_intact=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count,
    v_split_count, v_null_count, v_geo_count, v_mayor_exec_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('579')
ON CONFLICT (version) DO NOTHING;
