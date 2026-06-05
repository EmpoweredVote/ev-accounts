-- Migration 275: MD Federal Officials (8 US House Reps)
--
-- US Senators are ALREADY SEEDED (Van Hollen ext=-400033, Alsobrooks ext=-400034).
-- This migration asserts their existence then seeds only the 8 House reps.
--
-- Uses existing shared federal chambers (no new chambers created):
--   U.S. Senate                    7cbe07bc-84b8-433b-952b-540e7de18a92
--   U.S. House of Representatives  c2facc31-7b13-428c-b7b9-32d0d3b95f76
--
-- CRITICAL: state='MD' UPPERCASE for NATIONAL_UPPER/NATIONAL_LOWER (Pitfall 5)
-- CRITICAL: Senator offices already exist — do NOT re-insert senators
-- CRITICAL: NOT EXISTS guard for House reps uses (district_id, chamber_id) — single-member federal
-- All inserts idempotent (ON CONFLICT DO NOTHING / NOT EXISTS guards).
--
-- Roster (8 House Reps, 119th Congress, verified 2026-06-05):
--   MD-01: Andy Harris (Republican) — geo_id 2401
--   MD-02: Johnny Olszewski (Democrat) — geo_id 2402
--   MD-03: Sarah Elfreth (Democrat) — geo_id 2403
--   MD-04: Glenn Ivey (Democrat) — geo_id 2404
--   MD-05: Steny Hoyer (Democrat) — geo_id 2405 [confirmed seated via hoyer.house.gov 2026-06-05]
--   MD-06: April McClain Delaney (Democrat) — geo_id 2406
--   MD-07: Kweisi Mfume (Democrat) — geo_id 2407
--   MD-08: Jamie Raskin (Democrat) — geo_id 2408

BEGIN;

-- ===== STEP 1: Assert MD NATIONAL_UPPER district exists =====
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.districts
      WHERE district_type = 'NATIONAL_UPPER' AND state = 'MD') <> 1 THEN
    RAISE EXCEPTION 'Pre-flight failed: MD NATIONAL_UPPER district not found';
  END IF;
END $$;

-- ===== STEP 2: Assert both US senators already seeded =====
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.politicians
      WHERE external_id IN (-400033, -400034)) <> 2 THEN
    RAISE EXCEPTION 'Pre-flight failed: MD US senators not found (ext -400033/-400034)';
  END IF;
END $$;

-- ===== STEP 3: US House Reps (NATIONAL_LOWER, shared U.S. House chamber) =====
-- NATIONAL_LOWER districts already exist from Phase 91:
--   geo_ids 2401..2408, state='MD' (uppercase per Pitfall 5)

-- ----- MD-01: Andy Harris (R) (-2440001) — geo_id '2401' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andy Harris', 'Andy', 'Harris', 'Republican',
          true, false, false, true, -2440001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2401' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- MD-02: Johnny Olszewski (D) (-2440002) — geo_id '2402' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Johnny Olszewski', 'Johnny', 'Olszewski', 'Democrat',
          true, false, false, true, -2440002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2402' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- MD-03: Sarah Elfreth (D) (-2440003) — geo_id '2403' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sarah Elfreth', 'Sarah', 'Elfreth', 'Democrat',
          true, false, false, true, -2440003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2403' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- MD-04: Glenn Ivey (D) (-2440004) — geo_id '2404' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Glenn Ivey', 'Glenn', 'Ivey', 'Democrat',
          true, false, false, true, -2440004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2404' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- MD-05: Steny Hoyer (D) (-2440005) — geo_id '2405' -----
-- Verified seated via hoyer.house.gov on 2026-06-05; announced no re-election bid
-- in 2026 but has not resigned mid-term; still current incumbent through end of term.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steny Hoyer', 'Steny', 'Hoyer', 'Democrat',
          true, false, false, true, -2440005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2405' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- MD-06: April McClain Delaney (D) (-2440006) — geo_id '2406' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'April McClain Delaney', 'April', 'McClain Delaney', 'Democrat',
          true, false, false, true, -2440006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2406' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- MD-07: Kweisi Mfume (D) (-2440007) — geo_id '2407' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kweisi Mfume', 'Kweisi', 'Mfume', 'Democrat',
          true, false, false, true, -2440007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2407' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- MD-08: Jamie Raskin (D) (-2440008) — geo_id '2408' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jamie Raskin', 'Jamie', 'Raskin', 'Democrat',
          true, false, false, true, -2440008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2408' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ===== STEP 4: office_id back-fill =====
-- Scoped to -2440008..-2440001 covering all 8 MD US House reps.
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -2440008 AND -2440001
  AND p.office_id IS NULL;

COMMIT;
