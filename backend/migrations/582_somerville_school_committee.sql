-- Migration 582: Somerville Public Schools school committee (SOMERVILLE-01)
--
-- Purpose: Seeds Somerville Public Schools school committee under SCHOOL district.
--   geo_id='2510890' (NCES LEAID for Somerville Public Schools, MA FIPS=25)
-- Totals: 1 government, 1 chamber, 1 SCHOOL district, 7 new politicians, 9 offices
--   (7 elected + 2 ex-officio)
--
-- G5420 geofence inserted directly (no MA G5420 TIGER loader).
-- 7 new politicians (-2510890001..-2510890007, is_appointed=false, elected, Ward 1-7)
-- Mayor Wilson (external_id=-2562535001) linked via subquery — NO new politician INSERT
-- Council President Davis (external_id=-2562535011) linked via subquery — NO new politician INSERT
-- 9 offices total in SCHOOL district (7 elected + 2 ex-officio)
-- office_id back-fill excludes BOTH -2562535001 (Mayor) AND -2562535011 (Davis) — back-fill range: -2510890001 through -2510890007 only
--
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: districts.state='ma' lowercase; governments.state='MA' uppercase; offices.representing_state='MA' uppercase.
-- CRITICAL: slug is GENERATED ALWAYS on chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint — WHERE NOT EXISTS guard on name.
-- CRITICAL: SC geo_id is '2510890' (NCES LEAID) — NOT '2562535' (city geo_id).
-- CRITICAL: geofence_boundaries.state='25' (Massachusetts FIPS numeric string).
-- CRITICAL: party=NULL on all politicians (antipartisan).
-- CRITICAL: is_appointed=false for all 7 ward-elected SC members (elected).
-- CRITICAL: is_appointed_position=false (public governing body).
-- CRITICAL: Mayor Wilson (external_id=-2562535001) seeded in migration 581 — DO NOT re-insert.
-- CRITICAL: Council President Davis (external_id=-2562535011) seeded in migration 581 — DO NOT re-insert.
-- CRITICAL: office_id back-fill (Step 5) EXCLUDES both -2562535001 (Mayor) AND -2562535011 (Davis).
--           Both must keep pointing to their LOCAL_EXEC / LOCAL office_ids from migration 581.
--
-- CRITICAL DIFFERENCE FROM NEWTON (579): Somerville has TWO ex-officio members, not one.
-- Both ex-officio blocks use subquery on existing external_ids. Back-fill must exclude BOTH.
--
-- 7 elected members (all Jan 2026 — ward-based election Nov 2025):
--   -2510890001 Emily Ackman       (Ward 1, Chair)
--   -2510890002 Elizabeth Eldridge (Ward 2)
--   -2510890003 Michele Lippens    (Ward 3) — NOTE: 'Michele' one L per somerville.k12.ma.us
--   -2510890004 Andre L. Green     (Ward 4)
--   -2510890005 Laura Pitone       (Ward 5)
--   -2510890006 Emma Stellman      (Ward 6)
--   -2510890007 Leiran Biton       (Ward 7, Vice Chair)
-- 8th office: Mayor Jake Wilson (external_id=-2562535001) — ex officio, links existing row
-- 9th office: Lance L. Davis (external_id=-2562535011) — ex officio, links existing row
--
-- Sources: somerville.k12.ma.us/district-leadership/somerville-school-committee (2026-06-14)
--          nces.ed.gov (LEAID=2510890), thesomervilletimes.com (Davis re-elected President 2026)
-- Applied to production Supabase via mcp__supabase-local (remote production DB)

-- =============================================================================
-- Pre-flight 1: RAISE EXCEPTION if government already exists (idempotency check)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Somerville Public Schools, Massachusetts, US') > 0 THEN
    RAISE EXCEPTION 'Migration 582 already applied — aborting re-run';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Verify external_id block for SC members is clear
-- Range: -2510890001 through -2510890007
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2510890::bigint * 1000 + 7) AND -(2510890::bigint * 1000 + 1);
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -2510890001..-2510890007 is not clear (% rows found)', v_count;
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 3: Verify Mayor Wilson (external_id=-2562535001) exists from migration 581
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id = -2562535001;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Mayor Wilson (external_id=-2562535001) not found — run migration 581 first';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 4: Verify Council President Davis (external_id=-2562535011) exists from migration 581
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id = -2562535011;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Council President Davis (external_id=-2562535011) not found — run migration 581 first';
  END IF;
END $$;

-- =============================================================================
-- Step 0: Insert Somerville Public Schools G5420 geofence boundary
-- No MA G5420 rows loaded by TIGER loader — must INSERT directly.
-- geo_id='2510890' (NCES LEAID for Somerville Public Schools)
-- state='25' is FIPS numeric string for Massachusetts.
-- =============================================================================
INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, state)
SELECT '2510890', 'G5420', '25'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries
  WHERE geo_id = '2510890' AND mtfcc = 'G5420'
);

-- =============================================================================
-- Step 1: Government row — Somerville Public Schools
-- type='LOCAL' matches school district type
-- governments.state = 'MA' uppercase
-- city=NULL (school district spans the whole city, no single city value)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Somerville Public Schools, Massachusetts, US',
       'LOCAL', 'MA', NULL, '2510890'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Somerville Public Schools, Massachusetts, US'
);

-- =============================================================================
-- Step 2: School Committee chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Committee',
       'Somerville School Committee',
       (SELECT id FROM essentials.governments
        WHERE name = 'Somerville Public Schools, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Somerville Public Schools, Massachusetts, US')
);

-- =============================================================================
-- Step 3: SCHOOL district row
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='ma' LOWERCASE — routing query uses lowercase state
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- CRITICAL: geo_id='2510890' (NCES LEAID) — NOT '2562535' (city geo_id)
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ma', '2510890', 'Somerville Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2510890' AND district_type = 'SCHOOL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (7 elected blocks + 2 ex-officio blocks)
-- Pattern for blocks 1-7: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan)
-- is_appointed=false (all 7 ward members are popularly elected)
-- is_appointed_position=false (public governing body, not bureaucratic staff)
-- representing_state='MA' uppercase
-- is_incumbent=true (verified current committee members, Jan 2026)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- Blocks 8 (Mayor) + 9 (Davis): NO new politician INSERT — subquery on existing external_ids
-- =============================================================================

-- ============================
-- SOMERVILLE SCHOOL COMMITTEE — 7 elected members, geo_id='2510890'
-- All members link to the whole-district SCHOOL row (geo_id='2510890').
-- Source: somerville.k12.ma.us/district-leadership/somerville-school-committee (2026-06-14)
-- ============================

-- BLOCK 1: Emily Ackman (Ward 1, Chair) — -2510890001
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Emily Ackman', 'Emily', 'Ackman', NULL,
          true, false, false, true, -2510890001)
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
                               WHERE name = 'Somerville Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Chair', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2510890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Elizabeth Eldridge (Ward 2) — -2510890002
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth Eldridge', 'Elizabeth', 'Eldridge', NULL,
          true, false, false, true, -2510890002)
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
                               WHERE name = 'Somerville Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2510890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Michele Lippens (Ward 3) — -2510890003
-- NOTE: 'Michele' with ONE 'l' per official somerville.k12.ma.us page — NOT 'Michelle'
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michele Lippens', 'Michele', 'Lippens', NULL,
          true, false, false, true, -2510890003)
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
                               WHERE name = 'Somerville Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2510890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Andre L. Green (Ward 4) — -2510890004
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andre L. Green', 'Andre', 'Green', NULL,
          true, false, false, true, -2510890004)
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
                               WHERE name = 'Somerville Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2510890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Laura Pitone (Ward 5) — -2510890005
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Laura Pitone', 'Laura', 'Pitone', NULL,
          true, false, false, true, -2510890005)
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
                               WHERE name = 'Somerville Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2510890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Emma Stellman (Ward 6) — -2510890006
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Emma Stellman', 'Emma', 'Stellman', NULL,
          true, false, false, true, -2510890006)
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
                               WHERE name = 'Somerville Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Member', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2510890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Leiran Biton (Ward 7, Vice Chair) — -2510890007
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Leiran Biton', 'Leiran', 'Biton', NULL,
          true, false, false, true, -2510890007)
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
                               WHERE name = 'Somerville Public Schools, Massachusetts, US')),
       p.id,
       'School Committee Vice Chair', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2510890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: Mayor Jake Wilson (ex officio) — existing politician external_id=-2562535001
-- CRITICAL: DO NOT INSERT a new politician row.
-- Reuses existing politician from migration 581 via subquery on external_id=-2562535001.
-- Mayor is an ex-officio voting member of the School Committee.
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Somerville Public Schools, Massachusetts, US')),
       p.id,
       'Mayor (ex officio)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN (SELECT id FROM essentials.politicians WHERE external_id = -2562535001) p
WHERE d.geo_id = '2510890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Council President Lance L. Davis (ex officio) — existing politician external_id=-2562535011
-- CRITICAL: DO NOT INSERT a new politician row.
-- Reuses existing politician from migration 581 via subquery on external_id=-2562535011.
-- Council President is an ex-officio voting member of the School Committee.
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'School Committee'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Somerville Public Schools, Massachusetts, US')),
       p.id,
       'City Council President (ex officio)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN (SELECT id FROM essentials.politicians WHERE external_id = -2562535011) p
WHERE d.geo_id = '2510890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill (7 SC elected members ONLY — NOT Mayor Wilson or Council President Davis)
-- CRITICAL: external_id=-2562535001 (Mayor Wilson) is intentionally EXCLUDED from this range.
-- CRITICAL: external_id=-2562535011 (Davis) is intentionally EXCLUDED from this range.
-- Both must keep pointing to their LOCAL_EXEC / LOCAL office_ids from migration 581.
-- Range: -2510890007 through -2510890001 (7 elected SC members only)
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -(2510890::bigint * 1000 + 7) AND -(2510890::bigint * 1000 + 1)
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure (10 gates).
-- Gate (a): government row count = 1
-- Gate (b): chamber count = 1
-- Gate (c): SCHOOL district count = 1
-- Gate (d): SC politician count = 7 (Mayor and Davis NOT in this range)
-- Gate (e): total offices linked to SCHOOL district = 9 (7 elected + 2 ex-officio)
-- Gate (f): section-split = 0 orphan geofences
-- Gate (g): office_id back-fill complete = 0 NULL in SC elected range
-- Gate (h): G5420 geofence present (geo_id='2510890', state='25')
-- Gate (i): Mayor Wilson office_id still points to LOCAL_EXEC district (not overwritten)
-- Gate (j): Council President Davis office_id still points to LOCAL district (not overwritten)
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
  v_davis_local_count INTEGER;
BEGIN
  -- Gate (a): 1 government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'Somerville Public Schools, Massachusetts, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 SPS government row, found %', v_gov_count;
  END IF;

  -- Gate (b): 1 School Committee chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Somerville Public Schools, Massachusetts, US');
  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 School Committee chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 1 SCHOOL district row
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'ma'
    AND geo_id = '2510890';
  IF v_dist_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 SCHOOL district row for geo_id=2510890, found %', v_dist_count;
  END IF;

  -- Gate (d): 7 politicians in SC range (Mayor and Davis NOT in this range)
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2510890::bigint * 1000 + 7) AND -(2510890::bigint * 1000 + 1);
  IF v_pol_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 SC politicians in -2510890007..-2510890001, found %', v_pol_count;
  END IF;

  -- Gate (e): 9 offices linked to SCHOOL district (7 elected + 2 ex-officio)
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'SCHOOL'
    AND d.geo_id = '2510890'
    AND d.state = 'ma';
  IF v_off_count <> 9 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 9 offices linked to SCHOOL district geo_id=2510890, found %', v_off_count;
  END IF;

  -- Gate (f): Section-split check — G5420 geofence has SCHOOL district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2510890'
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

  -- Gate (g): Office_id back-fill complete for 7 SC elected members
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -(2510890::bigint * 1000 + 7) AND -(2510890::bigint * 1000 + 1)
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in -2510890007..-2510890001 range still have NULL office_id', v_null_count;
  END IF;

  -- Gate (h): G5420 geofence present for Somerville Public Schools (geo_id='2510890', state='25')
  SELECT COUNT(*) INTO v_geo_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2510890'
    AND mtfcc = 'G5420'
    AND state = '25';
  IF v_geo_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 G5420 geofence for geo_id=2510890 state=25, found %', v_geo_count;
  END IF;

  -- Gate (i): Mayor Wilson office_id still points to LOCAL_EXEC district (not overwritten)
  SELECT COUNT(*) INTO v_mayor_exec_count
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE p.external_id = -2562535001
    AND d.district_type = 'LOCAL_EXEC'
    AND d.geo_id = '2562535';
  IF v_mayor_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor Wilson office_id back-fill overwrote LOCAL_EXEC — CRITICAL BUG (expected 1, found %)', v_mayor_exec_count;
  END IF;

  -- Gate (j): Council President Davis office_id still points to LOCAL district (not overwritten)
  SELECT COUNT(*) INTO v_davis_local_count
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE p.external_id = -2562535011
    AND d.district_type = 'LOCAL'
    AND d.geo_id = '2562535';
  IF v_davis_local_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Council President Davis office_id back-fill overwrote LOCAL — CRITICAL BUG (expected 1, found %)', v_davis_local_count;
  END IF;

  RAISE NOTICE 'Migration 582 post-verification PASSED: gov=%, chambers=%, districts=%, sc_politicians=%, total_school_offices=%, split_orphans=%, null_sc_office_ids=%, geo_count=%, mayor_local_exec_intact=%, davis_local_intact=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count,
    v_split_count, v_null_count, v_geo_count, v_mayor_exec_count, v_davis_local_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('582')
ON CONFLICT (version) DO NOTHING;
