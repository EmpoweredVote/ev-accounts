-- Migration 585: Lynn Public Schools school committee (LYNN-01)
--
-- Purpose: Seeds Lynn Public Schools school committee under SCHOOL district.
--   geo_id='2507110' (NCES LEAID for Lynn Public Schools, MA FIPS=25)
-- Totals: 1 government, 1 chamber, 1 SCHOOL district, 6 new politicians, 7 offices
--   (6 elected at-large + 1 Mayor ex-officio linking existing politician external_id=-2537490001)
--
-- CRITICAL: G5420 geofence inserted directly (no MA G5420 TIGER loader).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: districts.state = 'ma' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'MA' (uppercase). offices.representing_state = 'MA' (uppercase).
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint — WHERE NOT EXISTS guard on name.
-- CRITICAL: geofence_boundaries.state = '25' (Massachusetts FIPS numeric string).
-- CRITICAL: party=NULL on all politicians (antipartisan).
-- CRITICAL: is_appointed=false for all 6 elected SC members.
-- CRITICAL: is_appointed_position=false (public governing body).
-- CRITICAL: Mayor Nicholson (external_id=-2537490001) seeded in migration 584 — DO NOT re-insert.
--           Block 7 uses subquery on existing politician; no new INSERT.
-- CRITICAL: office_id back-fill (Step 5) EXCLUDES external_id=-2537490001 — Mayor's office_id
--           must keep pointing to his LOCAL_EXEC office from migration 584.
-- CRITICAL: Lynn LEAID = 2507110 (NOT 2508610 Newton or 2510890 Somerville)
-- CRITICAL: Mary Jules is administrative Secretary (staff hire) — NOT seeded as SC politician.
--
-- 6 elected at-large members (all Jan 2026 — elected Nov 2025):
--   -2507110001 Brian K. Castellanos
--   -2507110002 Lorraine Gately       (Vice Chair — title stays 'School Committee Member' per D-07/Newton pattern)
--   -2507110003 Brenda Ortiz McGrath  (no hyphen — confirmed)
--   -2507110004 Lennin Peña           (ñ character — legal name)
--   -2507110005 Andrea L. Satterwhite
--   -2507110006 Tristan J. Smith
-- 7th office: Mayor Jared C. Nicholson (external_id=-2537490001) — ex officio Chair, links existing row
-- All 6 elected members use title='School Committee Member' (officer roles voted post-election, not charter offices)
--
-- Sources: lynnschools.org/committee, itemlive.com Nov 2025 election results, nces.ed.gov (LEAID=2507110)
-- Applied to production Supabase via mcp__supabase-local (remote production DB)

-- =============================================================================
-- Pre-flight 1: RAISE EXCEPTION if government already exists (idempotency check)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Lynn Public Schools, Massachusetts, US') > 0 THEN
    RAISE EXCEPTION 'Migration 585 already applied — aborting re-run: Lynn Public Schools government row already exists.';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Verify external_id block for SC members is clear
-- Range: -2507110001 through -2507110006
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2507110::bigint * 1000 + 6) AND -(2507110::bigint * 1000 + 1);
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -2507110001..-2507110006 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: external_id range -2507110001..-2507110006 is clear';
END $$;

-- =============================================================================
-- Pre-flight 3: Verify Mayor Nicholson (external_id=-2537490001) exists from migration 584
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id = -2537490001;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Mayor Nicholson (external_id=-2537490001) not found — run migration 584 first';
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: Mayor Nicholson (external_id=-2537490001) exists from migration 584';
END $$;

-- =============================================================================
-- Step 0: Insert Lynn Public Schools G5420 geofence boundary
-- No MA G5420 rows loaded by TIGER loader — must INSERT directly.
-- geo_id='2507110' (NCES LEAID for Lynn Public Schools)
-- state='25' is FIPS numeric string for Massachusetts (NOT 'ma' or 'MA').
-- =============================================================================
INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, state)
SELECT '2507110', 'G5420', '25'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries
  WHERE geo_id = '2507110' AND mtfcc = 'G5420'
);

-- =============================================================================
-- Step 1: Government row — Lynn Public Schools
-- type='LOCAL' matches school district type
-- governments.state = 'MA' uppercase
-- city=NULL (school district spans the whole city, no single city value)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Lynn Public Schools, Massachusetts, US',
       'LOCAL', 'MA', NULL, '2507110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Lynn Public Schools, Massachusetts, US'
);

-- =============================================================================
-- Step 2: School Committee chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- name_formal = 'Lynn School Committee'
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Committee',
       'Lynn School Committee',
       (SELECT id FROM essentials.governments
        WHERE name = 'Lynn Public Schools, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Lynn Public Schools, Massachusetts, US')
);

-- =============================================================================
-- Step 3: SCHOOL district row
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='ma' LOWERCASE — routing query uses lowercase state
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ma', '2507110', 'Lynn Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2507110' AND district_type = 'SCHOOL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (6 elected blocks + 1 Mayor ex-officio block)
-- Pattern for blocks 1-6: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan)
-- is_appointed=false (all 6 at-large members are popularly elected)
-- is_appointed_position=false (public governing body, not bureaucratic staff)
-- representing_state='MA' uppercase
-- is_incumbent=true (verified current committee members, Jan 2026)
-- title='School Committee Member' for all 6 elected members
--   (officer roles Vice Chair/etc. are voted on by the committee post-election, not charter offices)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- Block 7 (Mayor ex-officio): NO new politician INSERT — subquery on external_id=-2537490001
-- =============================================================================

-- ============================
-- LYNN SCHOOL COMMITTEE — 6 elected at-large members + 1 Mayor ex-officio, geo_id='2507110'
-- All members link to the whole-district SCHOOL row (geo_id='2507110').
-- Source: lynnschools.org/domain/125 (verified 2026-06-14)
-- ============================

-- BLOCK 1: Brian K. Castellanos — -2507110001
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian K. Castellanos', 'Brian', 'Castellanos', NULL,
          true, false, false, true, -2507110001)
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
                               WHERE name = 'Lynn Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507110'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Lorraine Gately — -2507110002
-- Note: Gately is Vice Chair (elected by committee Jan 5 2026) but title stays
-- 'School Committee Member' — SC officer roles are not charter offices (Newton pattern)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lorraine Gately', 'Lorraine', 'Gately', NULL,
          true, false, false, true, -2507110002)
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
                               WHERE name = 'Lynn Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507110'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Brenda Ortiz McGrath — -2507110003
-- Note: NO hyphen in name (confirmed multiple news sources: "Brenda Ortiz McGrath")
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brenda Ortiz McGrath', 'Brenda', 'Ortiz McGrath', NULL,
          true, false, false, true, -2507110003)
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
                               WHERE name = 'Lynn Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507110'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Lennin Peña — -2507110004
-- CRITICAL: first_name='Lennin' (legal name, not nickname 'Lenny'), last_name='Peña' (ñ character)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lennin Peña', 'Lennin', 'Peña', NULL,
          true, false, false, true, -2507110004)
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
                               WHERE name = 'Lynn Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507110'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Andrea L. Satterwhite — -2507110005
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andrea L. Satterwhite', 'Andrea', 'Satterwhite', NULL,
          true, false, false, true, -2507110005)
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
                               WHERE name = 'Lynn Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507110'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Tristan J. Smith — -2507110006
-- Note: "Tristan J. Smith, Esq." per official site; Esq. omitted per DB convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tristan J. Smith', 'Tristan', 'Smith', NULL,
          true, false, false, true, -2507110006)
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
                               WHERE name = 'Lynn Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507110'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Mayor Jared C. Nicholson (ex officio, Chair) — existing politician external_id=-2537490001
-- CRITICAL: DO NOT INSERT a new politician row.
-- Reuses existing politician from migration 584 via subquery on external_id=-2537490001.
-- Mayor is the Chair of the School Committee (ex officio).
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Lynn Public Schools, Massachusetts, US')),
       p.id,
       'Mayor (ex officio)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN (SELECT id FROM essentials.politicians WHERE external_id = -2537490001) p
WHERE d.geo_id = '2507110'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill (6 SC members ONLY — NOT Mayor Nicholson)
-- CRITICAL: external_id=-2537490001 (Mayor) is intentionally EXCLUDED from this range.
-- Mayor's office_id must continue pointing to his LOCAL_EXEC office from migration 584.
-- Range: -2507110006 through -2507110001 (6 elected SC members only)
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -(2507110::bigint * 1000 + 6) AND -(2507110::bigint * 1000 + 1)
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure (9 gates).
-- Gate (a): government row count = 1
-- Gate (b): chamber count = 1
-- Gate (c): SCHOOL district count = 1
-- Gate (d): SC politician count = 6 (Mayor NOT in range)
-- Gate (e): total offices linked to SCHOOL district = 7 (6 elected + 1 Mayor ex-officio)
-- Gate (f): section-split = 0 orphan geofences
-- Gate (g): office_id back-fill complete = 0 NULL in SC range
-- Gate (h): G5420 geofence present (geo_id='2507110', state='25')
-- Gate (i): Mayor Nicholson office_id still points to LOCAL_EXEC district (NOT overwritten)
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
  WHERE name = 'Lynn Public Schools, Massachusetts, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Lynn PS government row, found %', v_gov_count;
  END IF;

  -- Gate (b): 1 School Committee chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Lynn Public Schools, Massachusetts, US');
  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 School Committee chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 1 SCHOOL district row
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'ma'
    AND geo_id = '2507110';
  IF v_dist_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 SCHOOL district row for geo_id=2507110, found %', v_dist_count;
  END IF;

  -- Gate (d): 6 politicians in SC range (Mayor NOT in this range)
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2507110::bigint * 1000 + 6) AND -(2507110::bigint * 1000 + 1);
  IF v_pol_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 6 SC politicians in -2507110006..-2507110001, found %', v_pol_count;
  END IF;

  -- Gate (e): 7 offices linked to SCHOOL district (6 elected + 1 Mayor ex-officio)
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'SCHOOL'
    AND d.geo_id = '2507110'
    AND d.state = 'ma';
  IF v_off_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 offices linked to SCHOOL district geo_id=2507110, found %', v_off_count;
  END IF;

  -- Gate (f): Section-split check — G5420 geofence has SCHOOL district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2507110'
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

  -- Gate (g): Office_id back-fill complete for 6 SC members
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2507110::bigint * 1000 + 6) AND -(2507110::bigint * 1000 + 1)
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in -2507110006..-2507110001 range still have NULL office_id', v_null_count;
  END IF;

  -- Gate (h): G5420 geofence present for Lynn Public Schools (geo_id='2507110', state='25')
  SELECT COUNT(*) INTO v_geo_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2507110'
    AND mtfcc = 'G5420'
    AND state = '25';
  IF v_geo_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 G5420 geofence for geo_id=2507110 state=25, found %', v_geo_count;
  END IF;

  -- Gate (i): Mayor Nicholson office_id still points to LOCAL_EXEC district (not overwritten)
  -- CRITICAL: back-fill range -2507110006..-2507110001 must NOT have touched Mayor (-2537490001)
  SELECT COUNT(*) INTO v_mayor_exec_count
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE p.external_id = -2537490001
    AND d.district_type = 'LOCAL_EXEC'
    AND d.geo_id = '2537490';
  IF v_mayor_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor Nicholson office_id back-fill overwrote LOCAL_EXEC — CRITICAL BUG (expected 1, found %)', v_mayor_exec_count;
  END IF;

  RAISE NOTICE 'Migration 585 post-verification PASSED: gov=%, chambers=%, districts=%, sc_politicians=%, total_school_offices=%, split_orphans=%, null_sc_office_ids=%, geo_count=%, mayor_local_exec_intact=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count,
    v_split_count, v_null_count, v_geo_count, v_mayor_exec_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('585')
ON CONFLICT (version) DO NOTHING;
