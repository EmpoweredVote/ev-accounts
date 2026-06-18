-- Migration 593: Medford School Committee (MEDFORD-01 — SC portion)
--
-- Purpose: Seeds Medford Public Schools school committee under SCHOOL district.
--   geo_id='2506600' (NCES LEAID for Medford Public Schools, MA FIPS=25)
-- Totals: 1 government, 1 chamber, 1 SCHOOL district, 6 new politicians, 7 offices
--   (6 elected at-large + 1 Mayor ex-officio linking existing politician external_id=-2540115001)
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
-- CRITICAL: Mayor Lungo-Koehn (external_id=-2540115001) seeded in migration 591 — DO NOT re-insert.
--           Block 7 uses subquery on existing politician; no new INSERT.
-- CRITICAL: office_id back-fill (Step 5) EXCLUDES external_id=-2540115001 — Mayor's office_id
--           must keep pointing to her LOCAL_EXEC office from migration 591.
-- CRITICAL: Medford LEAID = 2506600 (NOT 2507110 Lynn or 2508610 Newton or 2510890 Somerville)
--
-- Roster verified 2026-06-15 from https://www.mps02155.org/about/school-committee:
-- 6 elected at-large members + Mayor Lungo-Koehn as ex-officio Chairperson
--   -2506600001 Jenny Graham      (Vice Chair — title stays 'School Committee Member' per Newton pattern)
--   -2506600002 Mike Mastrobuoni
--   -2506600003 Aaron Olapade
--   -2506600004 Jessica Parks
--   -2506600005 Erika Reinfeld
--   -2506600006 Paul Ruseau       (Secretary — title stays 'School Committee Member' per Newton pattern)
-- 7th office: Mayor Breanna Lungo-Koehn (external_id=-2540115001) — ex officio Chairperson, links existing row
-- All 6 elected members use title='School Committee Member'
--
-- Sources: mps02155.org/about/school-committee (verified 2026-06-15), nces.ed.gov (LEAID=2506600)
-- Applied to production Supabase via mcp__supabase-local (remote production DB)

-- =============================================================================
-- Pre-flight 1: RAISE EXCEPTION if government already exists (idempotency check)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Medford Public Schools, Massachusetts, US') > 0 THEN
    RAISE EXCEPTION 'Migration 593 already applied — aborting re-run: Medford Public Schools government row already exists.';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Verify external_id block for SC members is clear
-- Range: -2506600001 through -2506600006
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2506600::bigint * 1000 + 6) AND -(2506600::bigint * 1000 + 1);
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -2506600001..-2506600006 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: external_id range -2506600001..-2506600006 is clear';
END $$;

-- =============================================================================
-- Pre-flight 3: Verify Mayor Lungo-Koehn (external_id=-2540115001) exists from migration 591
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id = -2540115001;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Mayor Lungo-Koehn (external_id=-2540115001) not found — run migration 591 first';
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: Mayor Lungo-Koehn (external_id=-2540115001) exists from migration 591';
END $$;

-- =============================================================================
-- Step 0: Insert Medford Public Schools G5420 geofence boundary
-- No MA G5420 rows loaded by TIGER loader — must INSERT directly.
-- geo_id='2506600' (NCES LEAID for Medford Public Schools)
-- state='25' is FIPS numeric string for Massachusetts (NOT 'ma' or 'MA').
-- =============================================================================
INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, state)
SELECT '2506600', 'G5420', '25'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries
  WHERE geo_id = '2506600' AND mtfcc = 'G5420'
);

-- =============================================================================
-- Step 1: Government row — Medford Public Schools
-- type='LOCAL' matches school district type
-- governments.state = 'MA' uppercase
-- city=NULL (school district spans the whole city, no single city value)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Medford Public Schools, Massachusetts, US',
       'LOCAL', 'MA', NULL, '2506600'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Medford Public Schools, Massachusetts, US'
);

-- =============================================================================
-- Step 2: School Committee chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- name_formal = 'Medford School Committee'
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Committee',
       'Medford School Committee',
       (SELECT id FROM essentials.governments
        WHERE name = 'Medford Public Schools, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Medford Public Schools, Massachusetts, US')
);

-- =============================================================================
-- Step 3: SCHOOL district row
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='ma' LOWERCASE — routing query uses lowercase state
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ma', '2506600', 'Medford Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2506600' AND district_type = 'SCHOOL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (6 elected blocks + 1 Mayor ex-officio block)
-- Pattern for blocks 1-6: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan)
-- is_appointed=false (all 6 at-large members are popularly elected)
-- is_appointed_position=false (public governing body, not bureaucratic staff)
-- representing_state='MA' uppercase
-- is_incumbent=true (verified current committee members)
-- title='School Committee Member' for all 6 elected members
--   (officer roles Vice Chair/Secretary are voted on by the committee, not charter offices)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- Block 7 (Mayor ex-officio): NO new politician INSERT — subquery on external_id=-2540115001
-- =============================================================================

-- ============================
-- MEDFORD SCHOOL COMMITTEE — 6 elected at-large members + 1 Mayor ex-officio, geo_id='2506600'
-- All members link to the whole-district SCHOOL row (geo_id='2506600').
-- Source: mps02155.org/about/school-committee (verified 2026-06-15)
-- ============================

-- BLOCK 1: Jenny Graham — -2506600001
-- Note: Graham is Vice Chair (elected by committee) but title stays 'School Committee Member' — not a charter office
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jenny Graham', 'Jenny', 'Graham', NULL,
          true, false, false, true, -2506600001)
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
                               WHERE name = 'Medford Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2506600'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Mike Mastrobuoni — -2506600002
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Mastrobuoni', 'Mike', 'Mastrobuoni', NULL,
          true, false, false, true, -2506600002)
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
                               WHERE name = 'Medford Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2506600'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Aaron Olapade — -2506600003
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Aaron Olapade', 'Aaron', 'Olapade', NULL,
          true, false, false, true, -2506600003)
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
                               WHERE name = 'Medford Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2506600'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Jessica Parks — -2506600004
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jessica Parks', 'Jessica', 'Parks', NULL,
          true, false, false, true, -2506600004)
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
                               WHERE name = 'Medford Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2506600'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Erika Reinfeld — -2506600005
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Erika Reinfeld', 'Erika', 'Reinfeld', NULL,
          true, false, false, true, -2506600005)
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
                               WHERE name = 'Medford Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2506600'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Paul Ruseau — -2506600006
-- Note: Ruseau is Secretary (elected by committee) but title stays 'School Committee Member' — not a charter office
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Ruseau', 'Paul', 'Ruseau', NULL,
          true, false, false, true, -2506600006)
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
                               WHERE name = 'Medford Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2506600'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Mayor Breanna Lungo-Koehn (ex officio, Chairperson) — existing politician external_id=-2540115001
-- CRITICAL: DO NOT INSERT a new politician row.
-- Reuses existing politician from migration 591 via subquery on external_id=-2540115001.
-- Mayor is the Chairperson of the School Committee (ex officio).
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Medford Public Schools, Massachusetts, US')),
       p.id,
       'Mayor (ex officio)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN (SELECT id FROM essentials.politicians WHERE external_id = -2540115001) p
WHERE d.geo_id = '2506600'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill (6 SC members ONLY — NOT Mayor Lungo-Koehn)
-- CRITICAL: external_id=-2540115001 (Mayor) is intentionally EXCLUDED from this range.
-- Mayor's office_id must continue pointing to her LOCAL_EXEC office from migration 591.
-- Range: -2506600006 through -2506600001 (6 elected SC members only)
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -(2506600::bigint * 1000 + 6) AND -(2506600::bigint * 1000 + 1)
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
-- Gate (h): G5420 geofence present (geo_id='2506600', state='25')
-- Gate (i): Mayor Lungo-Koehn office_id still points to LOCAL_EXEC district (NOT overwritten)
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
  WHERE name = 'Medford Public Schools, Massachusetts, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Medford PS government row, found %', v_gov_count;
  END IF;

  -- Gate (b): 1 School Committee chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Medford Public Schools, Massachusetts, US');
  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 School Committee chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 1 SCHOOL district row
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'ma'
    AND geo_id = '2506600';
  IF v_dist_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 SCHOOL district row for geo_id=2506600, found %', v_dist_count;
  END IF;

  -- Gate (d): 6 politicians in SC range (Mayor NOT in this range)
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2506600::bigint * 1000 + 6) AND -(2506600::bigint * 1000 + 1);
  IF v_pol_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 6 SC politicians in -2506600006..-2506600001, found %', v_pol_count;
  END IF;

  -- Gate (e): 7 offices linked to SCHOOL district (6 elected + 1 Mayor ex-officio)
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'SCHOOL'
    AND d.geo_id = '2506600'
    AND d.state = 'ma';
  IF v_off_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 offices linked to SCHOOL district geo_id=2506600, found %', v_off_count;
  END IF;

  -- Gate (f): Section-split check — G5420 geofence has SCHOOL district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2506600'
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
  WHERE external_id BETWEEN -(2506600::bigint * 1000 + 6) AND -(2506600::bigint * 1000 + 1)
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in -2506600006..-2506600001 range still have NULL office_id', v_null_count;
  END IF;

  -- Gate (h): G5420 geofence present for Medford Public Schools (geo_id='2506600', state='25')
  SELECT COUNT(*) INTO v_geo_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2506600'
    AND mtfcc = 'G5420'
    AND state = '25';
  IF v_geo_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 G5420 geofence for geo_id=2506600 state=25, found %', v_geo_count;
  END IF;

  -- Gate (i): Mayor Lungo-Koehn office_id still points to LOCAL_EXEC district (not overwritten)
  -- CRITICAL: back-fill range -2506600006..-2506600001 must NOT have touched Mayor (-2540115001)
  SELECT COUNT(*) INTO v_mayor_exec_count
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE p.external_id = -2540115001
    AND d.district_type = 'LOCAL_EXEC'
    AND d.geo_id = '2540115';
  IF v_mayor_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor Lungo-Koehn office_id back-fill overwrote LOCAL_EXEC — CRITICAL BUG (expected 1, found %)', v_mayor_exec_count;
  END IF;

  RAISE NOTICE 'Migration 593 post-verification PASSED: gov=%, chambers=%, districts=%, sc_politicians=%, total_school_offices=%, split_orphans=%, null_sc_office_ids=%, geo_count=%, mayor_local_exec_intact=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count,
    v_split_count, v_null_count, v_geo_count, v_mayor_exec_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('593')
ON CONFLICT (version) DO NOTHING;
