-- Migration 170: ME Federal Officials (2 US Senators + 2 US House Reps) + ME NATIONAL_UPPER district
--
-- Seeds the 4 federal officials representing Maine:
--   US Senators (NATIONAL_UPPER, shared U.S. Senate chamber):
--     - Susan M. Collins (R, senior senator, up 2026)
--     - Angus S. King, Jr. (I, junior senator)
--   US House Reps (NATIONAL_LOWER, shared U.S. House chamber):
--     - Chellie Pingree (D, ME-01, geo_id 2301 — Portland/southern coast)
--     - Jared Golden (D, ME-02, geo_id 2302 — Bangor/rural)
--
-- Creates the ME NATIONAL_UPPER district in Step 1 — it does NOT exist yet
-- (confirmed by Phase 51 research; only NATIONAL_LOWER districts exist from Phase 49).
--
-- Uses existing shared federal chambers — does NOT create any new chambers:
--   U.S. Senate                    7cbe07bc-84b8-433b-952b-540e7de18a92
--   U.S. House of Representatives  c2facc31-7b13-428c-b7b9-32d0d3b95f76
--
-- All inserts are idempotent (WHERE NOT EXISTS / ON CONFLICT) — safe to re-run.
--
-- CRITICAL:
-- - Collins is Republican; King is Independent; Pingree and Golden are Democrat
-- - state='ME' uppercase for NATIONAL_UPPER and NATIONAL_LOWER
-- - Senator office uniqueness key = (district_id, politician_id) because both
--   senators share the same district — NOT (district_id, chamber_id)
-- - NO new chambers created
-- - NO election_races rows created (Phase 51 is structural only)

BEGIN;

-- ===== STEP 1: Create ME NATIONAL_UPPER district (shared by Collins + King) =====
-- state='ME' uppercase, geo_id='23' (Maine FIPS), label='Maine', district_id='Maine'.
-- Matches pattern of MA NATIONAL_UPPER (created in migration 154).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'ME', '23', 'Maine', 'Maine', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'NATIONAL_UPPER' AND state = 'ME'
);

-- ===== STEP 2: US Senators (NATIONAL_UPPER, shared U.S. Senate chamber) =====

-- ----- Senior Senator: Susan M. Collins (R) (-230101) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Susan M. Collins', 'Susan', 'Collins', 'Republican',
          true, false, false, true, -230101)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'ME'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Junior Senator: Angus S. King, Jr. (I) (-230102) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angus S. King, Jr.', 'Angus', 'King', 'Independent',
          true, false, false, true, -230102)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'ME'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ===== STEP 3: US House Reps (NATIONAL_LOWER, shared U.S. House chamber) =====
-- NATIONAL_LOWER districts already exist from Phase 49:
--   geo_id='2301' state='ME' -> ME-01 (Pingree)
--   geo_id='2302' state='ME' -> ME-02 (Golden)

-- ----- ME-01: Chellie Pingree (D) (-230201) — geo_id 2301 -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chellie Pingree', 'Chellie', 'Pingree', 'Democrat',
          true, false, false, true, -230201)
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
       'Representative', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2301' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'ME'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- ME-02: Jared Golden (D) (-230202) — geo_id 2302 -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jared Golden', 'Jared', 'Golden', 'Democrat',
          true, false, false, true, -230202)
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
       'Representative', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'ME'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ===== STEP 4: office_id back-fill =====
-- Scoped to -230209..-230101 covering all 4 federal officials plus headroom.
-- Guard with p.office_id IS NULL for idempotency.

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -230209 AND -230101
  AND p.office_id IS NULL;

COMMIT;
