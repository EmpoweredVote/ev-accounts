-- Migration 311: VA Federal Officials (11 US House Reps)
--
-- US Senators are ALREADY SEEDED (Warner ext=-400080, Kaine ext=-400079).
-- This migration asserts their existence then seeds only the 11 House reps.
--
-- Uses existing shared federal chambers (no new chambers created):
--   U.S. Senate                    7cbe07bc-84b8-433b-952b-540e7de18a92
--   U.S. House of Representatives  c2facc31-7b13-428c-b7b9-32d0d3b95f76
--
-- CRITICAL: state='VA' UPPERCASE for NATIONAL_UPPER/NATIONAL_LOWER (Pitfall 5)
-- CRITICAL: Senator offices already exist — do NOT re-insert senators
-- CRITICAL: NOT EXISTS guard for House reps uses (district_id, chamber_id) — single-member federal
-- All inserts idempotent (ON CONFLICT DO NOTHING / NOT EXISTS guards).
--
-- Roster (11 House Reps, 119th Congress, verified 2026-06-08):
--   VA-01: Rob Wittman (Republican) — geo_id 5101
--   VA-02: Jen Kiggans (Republican) — geo_id 5102
--   VA-03: Bobby Scott (Democrat) — geo_id 5103
--   VA-04: Jennifer McClellan (Democrat) — geo_id 5104
--   VA-05: Ben Cline (Republican) — geo_id 5105 (won special election; NOT Bob Good)
--   VA-06: Morgan Griffith (Republican) — geo_id 5106
--   VA-07: Eugene Vindman (Democrat) — geo_id 5107
--   VA-08: Don Beyer (Democrat) — geo_id 5108 (Alexandria = VA-8)
--   VA-09: John McGuire (Republican) — geo_id 5109 (won special election)
--   VA-10: Suhas Subramanyam (Democrat) — geo_id 5110
--   VA-11: James Walkinshaw (Democrat) — geo_id 5111

BEGIN;

-- ===== STEP 1 + STEP 2: Pre-flight assertions (OR-style combined block) =====
DO $$
DECLARE
  v_national_upper_count INT;
  v_national_lower_count INT;
  v_senate_count INT;
  v_house_count INT;
  v_senator_count INT;
BEGIN
  -- (a) Assert exactly 1 NATIONAL_UPPER VA district (geo_id='51')
  SELECT COUNT(*) INTO v_national_upper_count
  FROM essentials.districts
  WHERE district_type = 'NATIONAL_UPPER' AND state = 'VA' AND geo_id = '51';

  IF v_national_upper_count != 1 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Expected 1 NATIONAL_UPPER VA district (geo_id=51), found %', v_national_upper_count;
  END IF;

  -- (b) Assert exactly 11 NATIONAL_LOWER VA districts (geo_ids 5101-5111)
  SELECT COUNT(*) INTO v_national_lower_count
  FROM essentials.districts
  WHERE district_type = 'NATIONAL_LOWER' AND state = 'VA'
    AND geo_id IN ('5101','5102','5103','5104','5105','5106','5107','5108','5109','5110','5111');

  IF v_national_lower_count != 11 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Expected 11 NATIONAL_LOWER VA districts (geo_ids 5101-5111), found %', v_national_lower_count;
  END IF;

  -- (c) Assert U.S. Senate chamber exists exactly once
  SELECT COUNT(*) INTO v_senate_count
  FROM essentials.chambers
  WHERE name = 'U.S. Senate';

  IF v_senate_count != 1 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Expected 1 chamber with name=''U.S. Senate'', found %', v_senate_count;
  END IF;

  -- (d) Assert U.S. House of Representatives chamber exists exactly once
  SELECT COUNT(*) INTO v_house_count
  FROM essentials.chambers
  WHERE name = 'U.S. House of Representatives';

  IF v_house_count != 1 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Expected 1 chamber with name=''U.S. House of Representatives'', found %', v_house_count;
  END IF;

  -- (e) Assert both VA US senators already seeded (Warner=-400080, Kaine=-400079)
  SELECT COUNT(*) INTO v_senator_count
  FROM essentials.politicians
  WHERE external_id IN (-400080, -400079);

  IF v_senator_count != 2 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: VA US senators not found (ext -400080/-400079); expected 2, found %', v_senator_count;
  END IF;

  RAISE NOTICE 'Pre-flight passed: NATIONAL_UPPER=%, NATIONAL_LOWER=%, Senate chambers=%, House chambers=%, VA senators=%',
    v_national_upper_count, v_national_lower_count, v_senate_count, v_house_count, v_senator_count;
END $$;


-- ===== STEP 3: US House Representatives (NATIONAL_LOWER, shared U.S. House chamber) =====
-- NATIONAL_LOWER districts already exist from Phase 100:
--   geo_ids 5101..5111, state='VA' (uppercase per Pitfall 5)

-- ----- VA-01: Rob Wittman (R) (-5102001) — geo_id '5101' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rob Wittman', 'Rob', 'Wittman', 'Republican',
          true, false, false, true, -5102001)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5101' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-02: Jen Kiggans (R) (-5102002) — geo_id '5102' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jen Kiggans', 'Jen', 'Kiggans', 'Republican',
          true, false, false, true, -5102002)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5102' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-03: Bobby Scott (D) (-5102003) — geo_id '5103' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bobby Scott', 'Bobby', 'Scott', 'Democrat',
          true, false, false, true, -5102003)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5103' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-04: Jennifer McClellan (D) (-5102004) — geo_id '5104' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jennifer McClellan', 'Jennifer', 'McClellan', 'Democrat',
          true, false, false, true, -5102004)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5104' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-05: Ben Cline (R) (-5102005) — geo_id '5105' -----
-- Per D-11 correction: Ben Cline won the 2025 special election (NOT Bob Good).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ben Cline', 'Ben', 'Cline', 'Republican',
          true, false, false, true, -5102005)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5105' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-06: Morgan Griffith (R) (-5102006) — geo_id '5106' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Morgan Griffith', 'Morgan', 'Griffith', 'Republican',
          true, false, false, true, -5102006)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5106' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-07: Eugene Vindman (D) (-5102007) — geo_id '5107' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eugene Vindman', 'Eugene', 'Vindman', 'Democrat',
          true, false, false, true, -5102007)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5107' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-08: Don Beyer (D) (-5102008) — geo_id '5108' -----
-- Alexandria is in VA-8; success criterion: Alexandria address returns Don Beyer.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Don Beyer', 'Don', 'Beyer', 'Democrat',
          true, false, false, true, -5102008)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5108' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-09: John McGuire (R) (-5102009) — geo_id '5109' -----
-- Per D-11 correction: John McGuire won the 2025 special election.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John McGuire', 'John', 'McGuire', 'Republican',
          true, false, false, true, -5102009)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5109' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-10: Suhas Subramanyam (D) (-5102010) — geo_id '5110' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Suhas Subramanyam', 'Suhas', 'Subramanyam', 'Democrat',
          true, false, false, true, -5102010)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5110' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- ----- VA-11: James Walkinshaw (D) (-5102011) — geo_id '5111' -----
-- Per D-11 correction: James Walkinshaw (NOT Gerry Connolly, who retired).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Walkinshaw', 'James', 'Walkinshaw', 'Democrat',
          true, false, false, true, -5102011)
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
       'U.S. Representative', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '5111' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );


-- ===== STEP 4: office_id back-fill =====
-- Scoped to -5102011..-5102001 covering all 11 VA US House reps.
-- Warner/Kaine excluded by both the BETWEEN range and the IS NULL guard.
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -5102011 AND -5102001
  AND p.office_id IS NULL;

COMMIT;
