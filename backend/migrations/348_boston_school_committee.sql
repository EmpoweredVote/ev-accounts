-- Migration 348: Boston School Committee (MA-DEEP-03)
--
-- Purpose: Seeds Boston Public Schools school committee (7 members) under SCHOOL district.
--   geo_id='2502790' (MA FIPS=25, BPS LEAID=02790 — same derivation as ACPS pattern)
-- Totals: 1 government, 1 chamber, 1 district, 7 politicians, 7 offices
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — WHERE NOT EXISTS guard.
-- CRITICAL: districts.state = 'ma' (lowercase) to match routing queries (D-10).
-- CRITICAL: governments.state = 'MA' (uppercase). offices.representing_state = 'MA' (uppercase) (D-11).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: G5420 geofence inserted directly in this migration (no MA G5420 loader — D-05).
-- CRITICAL: geofence_boundaries.state = '25' (Massachusetts FIPS numeric string — D-20).
-- CRITICAL: party=NULL on all 7 politicians (antipartisan — D-15).
-- CRITICAL: is_appointed=true for all 7 (mayor-appointed committee — D-16 override; RESEARCH.md Correction 2).
-- CRITICAL: is_appointed_position=false (public governing body, not bureaucratic staff — Assumption A2).
-- NOTE: election_method=NULL on chamber (no election — appointed committee — D-06).
-- NOTE: Do NOT seed the non-voting student rep or staff roles (Pitfall 2).
-- NOTE: BPS government row name = 'Boston Public Schools, Massachusetts, US' (D-19).
--
-- Current 7 members (verified 2026-06-10 from bostonpublicschools.org/school-committee/about/members):
--   -2502790001 Jeri Robinson (Chair)
--   -2502790002 Rachel Skerritt (Vice Chair)
--   -2502790003 Dr. Stephen Alkins (Member)
--   -2502790004 Rafaela Polanco Garcia (Member)
--   -2502790005 Franklin Peralta (Member)
--   -2502790006 Lydia Torres (Member)
--   -2502790007 Quoc Tran (Member)
--
-- Applied to production Supabase via _apply-migration-348.ts
-- (mcp__supabase-local is the remote production DB)

-- =============================================================================
-- Pre-flight: RAISE EXCEPTION if government already exists (idempotency check)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Boston Public Schools, Massachusetts, US') > 0 THEN
    RAISE EXCEPTION 'Migration 348 already applied — aborting re-run';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight: Verify external_id block is clear
-- Range: -2502790001 through -2502790007
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2502790::bigint * 1000 + 7) AND -(2502790::bigint * 1000 + 1);
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -2502790001..-2502790007 is not clear (% rows found)', v_count;
  END IF;
END $$;

-- =============================================================================
-- Step 0: Insert BPS G5420 geofence boundary
-- No MA G5420 rows loaded by TIGER loader (D-05) — must INSERT directly.
-- geo_id='2502790' (MA FIPS=25 + BPS LEAID=02790)
-- state='25' is FIPS numeric string for Massachusetts (matches geofence_boundaries convention — D-20).
-- =============================================================================
INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, state)
SELECT '2502790', 'G5420', '25'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries
  WHERE geo_id = '2502790' AND mtfcc = 'G5420'
);

-- =============================================================================
-- Step 1: Government row
-- type='LOCAL' matches school district type
-- governments.state = 'MA' uppercase (governments convention — D-11)
-- city=NULL (school district spans the whole city, no single city value)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Boston Public Schools, Massachusetts, US',
       'LOCAL', 'MA', NULL, '2502790'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Boston Public Schools, Massachusetts, US'
);

-- =============================================================================
-- Step 2: School Committee chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- election_method=NULL (appointed committee, no election — D-06).
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Committee',
       'Boston School Committee',
       (SELECT id FROM essentials.governments
        WHERE name = 'Boston Public Schools, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Boston Public Schools, Massachusetts, US')
);

-- =============================================================================
-- Step 3: SCHOOL district row
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='ma' LOWERCASE — routing query uses geocoder output which is lowercase (D-10)
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ma', '2502790', 'Boston Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2502790' AND district_type = 'SCHOOL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (7 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan — D-15)
-- is_appointed=true (mayor-appointed committee — D-16 override; RESEARCH.md Correction 2)
-- is_appointed_position=false (public governing body, not bureaucratic staff — Assumption A2)
-- representing_state='MA' uppercase (offices convention — D-11)
-- is_incumbent=true (verified current committee members)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- =============================================================================

-- ============================
-- BOSTON SCHOOL COMMITTEE — 7 members, geo_id='2502790'
-- All 7 members link to the whole-district SCHOOL row (geo_id='2502790').
-- Source: bostonpublicschools.org/school-committee/about/members (verified 2026-06-10)
-- Only voting members seeded — non-voting student rep and staff are excluded.
-- ============================

-- BLOCK 1: Jeri Robinson (Chair) — -2502790001
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeri Robinson', 'Jeri', 'Robinson', NULL,
          true, true, false, true, -2502790001)
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
                               WHERE name = 'Boston Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Chair', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2502790'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Rachel Skerritt (Vice Chair) — -2502790002
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rachel Skerritt', 'Rachel', 'Skerritt', NULL,
          true, true, false, true, -2502790002)
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
                               WHERE name = 'Boston Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Vice Chair', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2502790'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Dr. Stephen Alkins (Member) — -2502790003
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dr. Stephen Alkins', 'Stephen', 'Alkins', NULL,
          true, true, false, true, -2502790003)
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
                               WHERE name = 'Boston Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2502790'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Rafaela Polanco Garcia (Member) — -2502790004
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rafaela Polanco Garcia', 'Rafaela', 'Polanco Garcia', NULL,
          true, true, false, true, -2502790004)
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
                               WHERE name = 'Boston Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2502790'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Franklin Peralta (Member) — -2502790005
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Franklin Peralta', 'Franklin', 'Peralta', NULL,
          true, true, false, true, -2502790005)
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
                               WHERE name = 'Boston Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2502790'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Lydia Torres (Member) — -2502790006
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lydia Torres', 'Lydia', 'Torres', NULL,
          true, true, false, true, -2502790006)
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
                               WHERE name = 'Boston Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2502790'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Quoc Tran (Member) — -2502790007
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Quoc Tran', 'Quoc', 'Tran', NULL,
          true, true, false, true, -2502790007)
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
                               WHERE name = 'Boston Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2502790'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 7 BPS school committee officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -(2502790::bigint * 1000 + 7) AND -(2502790::bigint * 1000 + 1)
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure.
-- Gate (a): government row count = 1
-- Gate (b): chamber count = 1
-- Gate (c): SCHOOL district count = 1
-- Gate (d): politician count = 7
-- Gate (e): office count = 7 (linked to SCHOOL district)
-- Gate (f): section-split = 0 orphan geofences
-- Gate (g): office_id back-fill complete (0 NULL)
-- Gate (h): G5420 geofence present for BPS
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
  v_geo_count     INTEGER;
BEGIN
  -- Gate (a): 1 government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'Boston Public Schools, Massachusetts, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 BPS government row, found %', v_gov_count;
  END IF;

  -- Gate (b): 1 School Committee chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Boston Public Schools, Massachusetts, US');
  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 School Committee chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 1 SCHOOL district row
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'ma'
    AND geo_id = '2502790';
  IF v_dist_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 SCHOOL district row for geo_id=2502790, found %', v_dist_count;
  END IF;

  -- Gate (d): 7 politicians in external_id range
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2502790::bigint * 1000 + 7) AND -(2502790::bigint * 1000 + 1);
  IF v_pol_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 politicians in BPS range -2502790007..-2502790001, found %', v_pol_count;
  END IF;

  -- Gate (e): 7 offices linked to SCHOOL district
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'SCHOOL'
    AND d.geo_id = '2502790'
    AND d.state = 'ma';
  IF v_off_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 offices linked to SCHOOL district geo_id=2502790, found %', v_off_count;
  END IF;

  -- Gate (f): Section-split check — G5420 geofence has SCHOOL district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2502790'
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

  -- Gate (g): Office_id back-fill complete
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2502790::bigint * 1000 + 7) AND -(2502790::bigint * 1000 + 1)
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in -2502790007..-2502790001 range still have NULL office_id', v_null_count;
  END IF;

  -- Gate (h): G5420 geofence present for BPS (geo_id='2502790', state='25')
  SELECT COUNT(*) INTO v_geo_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2502790'
    AND mtfcc = 'G5420'
    AND state = '25';
  IF v_geo_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 G5420 geofence for geo_id=2502790 state=25, found %', v_geo_count;
  END IF;

  RAISE NOTICE 'Migration 348 post-verification PASSED: gov_count=%, chamber_count=%, dist_count=%, pol_count=%, off_count=%, section_split=%, null_office_ids=%, geo_count=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count, v_geo_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('348')
ON CONFLICT (version) DO NOTHING;
