-- Migration 224: OR Federal Officials (2 US Senators + 6 US House Reps)
--
-- Seeds Oregon's 8 federal delegation members:
--   US Senators (NATIONAL_UPPER, shared district geo_id='41'):
--     - Ron Wyden (D, external_id=-4101001)
--     - Jeff Merkley (D, external_id=-4101002)
--   US House Reps (NATIONAL_LOWER, one per congressional district):
--     - Suzanne Bonamici (D, CD-01, geo_id=4101, external_id=-4102001)
--     - Cliff Bentz (R, CD-02, geo_id=4102, external_id=-4102002)
--     - Maxine Dexter (D, CD-03, geo_id=4103, external_id=-4102003)
--     - Val Hoyle (D, CD-04, geo_id=4104, external_id=-4102004)
--     - Janelle Bynum (D, CD-05, geo_id=4105, external_id=-4102005)
--     - Andrea Salinas (D, CD-06, geo_id=4106, external_id=-4102006)
--
-- Pre-flight finding (Task 1): Ron Wyden and Jeff Merkley already exist in DB
-- under external_ids -400065 and -400066 with correct office rows already linked
-- to the OR NATIONAL_UPPER district (geo_id='41'). This migration:
--   1. Updates their external_ids to the canonical -4101001/-4101002 scheme
--   2. Inserts 6 House rep politician rows (new)
--   3. Inserts 6 House rep office rows linked to their NATIONAL_LOWER districts
--   4. Back-fills office_id on House rep politician rows (senators already have office_id)
--
-- Idempotency guarantees:
--   - Senator UPDATE uses WHERE full_name = '...' AND external_id = <old_id>
--     (safe to re-run: if external_id already updated, WHERE clause matches 0 rows)
--   - House rep INSERTs use ON CONFLICT (external_id) DO NOTHING
--   - House rep office INSERTs use NOT EXISTS guard on (district_id, chamber_id)
--   - office_id back-fill uses WHERE office_id IS NULL
--
-- Senator uniqueness key: (district_id, politician_id) per Phase 51/STATE.md precedent.
--   Both senators share the same NATIONAL_UPPER district_id — using (district_id, chamber_id)
--   would block the 2nd senator's office. Pre-existing office rows already use this pattern.
--
-- Federal chamber names (verified Task 1 pre-flight):
--   US Senate:  name='U.S. Senate'
--   US House:   name='U.S. House of Representatives'
--
-- All districts pre-exist — NO INSERT INTO essentials.districts in this migration.
-- All 8 offices: is_appointed_position=false (all are voter-elected)
--
-- Party assignments: Wyden=Democrat, Merkley=Democrat, Bonamici=Democrat,
--   Bentz=Republican, Dexter=Democrat, Hoyle=Democrat, Bynum=Democrat, Salinas=Democrat

BEGIN;

-- ===== STEP 0: Pre-flight assertions =====
DO $$
DECLARE
  v_national_upper_count INT;
  v_national_lower_count INT;
  v_senate_count INT;
  v_house_count INT;
BEGIN
  -- Assert NATIONAL_UPPER OR district exists exactly once
  SELECT COUNT(*) INTO v_national_upper_count
  FROM essentials.districts
  WHERE district_type = 'NATIONAL_UPPER' AND state = 'OR' AND geo_id = '41';

  IF v_national_upper_count != 1 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Expected 1 NATIONAL_UPPER OR district (geo_id=41), found %', v_national_upper_count;
  END IF;

  -- Assert 6 NATIONAL_LOWER OR districts exist
  SELECT COUNT(*) INTO v_national_lower_count
  FROM essentials.districts
  WHERE district_type = 'NATIONAL_LOWER' AND state = 'OR'
    AND geo_id IN ('4101','4102','4103','4104','4105','4106');

  IF v_national_lower_count != 6 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Expected 6 NATIONAL_LOWER OR districts (geo_ids 4101-4106), found %', v_national_lower_count;
  END IF;

  -- Assert US Senate federal chamber exists
  SELECT COUNT(*) INTO v_senate_count
  FROM essentials.chambers
  WHERE name = 'U.S. Senate';

  IF v_senate_count != 1 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Expected 1 chamber with name=''U.S. Senate'', found %', v_senate_count;
  END IF;

  -- Assert US House federal chamber exists
  SELECT COUNT(*) INTO v_house_count
  FROM essentials.chambers
  WHERE name = 'U.S. House of Representatives';

  IF v_house_count != 1 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Expected 1 chamber with name=''U.S. House of Representatives'', found %', v_house_count;
  END IF;

  RAISE NOTICE 'Pre-flight passed: NATIONAL_UPPER=%, NATIONAL_LOWER=%, US Senate chambers=%, US House chambers=%',
    v_national_upper_count, v_national_lower_count, v_senate_count, v_house_count;
END $$;


-- ===== STEP 1: UPDATE existing senator external_ids to canonical OR scheme =====
-- Both senators already exist with correct office rows and office_id back-fill.
-- Only update external_id to match the -4101xxx scheme.
-- WHERE clause uses old external_id so re-run is a safe no-op.

UPDATE essentials.politicians
SET external_id = -4101001
WHERE full_name = 'Ron Wyden'
  AND external_id = -400065;

UPDATE essentials.politicians
SET external_id = -4101002
WHERE full_name = 'Jeff Merkley'
  AND external_id = -400066;


-- ===== STEP 2: US House Representatives (NATIONAL_LOWER, shared U.S. House chamber) =====
-- All 6 are new inserts — none pre-exist per Task 1 pre-flight.

-- ----- CD-01: Suzanne Bonamici (D) (-4102001) — geo_id 4101 -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Suzanne Bonamici', 'Suzanne', 'Bonamici', 'Democrat',
          true, false, false, true, -4102001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives'),
       p.id,
       'Representative', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4101' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'OR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
  );

-- ----- CD-02: Cliff Bentz (R) (-4102002) — geo_id 4102 -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cliff Bentz', 'Cliff', 'Bentz', 'Republican',
          true, false, false, true, -4102002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives'),
       p.id,
       'Representative', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4102' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'OR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
  );

-- ----- CD-03: Maxine Dexter (D) (-4102003) — geo_id 4103 -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maxine Dexter', 'Maxine', 'Dexter', 'Democrat',
          true, false, false, true, -4102003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives'),
       p.id,
       'Representative', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4103' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'OR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
  );

-- ----- CD-04: Val Hoyle (D) (-4102004) — geo_id 4104 -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Val Hoyle', 'Val', 'Hoyle', 'Democrat',
          true, false, false, true, -4102004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives'),
       p.id,
       'Representative', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4104' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'OR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
  );

-- ----- CD-05: Janelle Bynum (D) (-4102005) — geo_id 4105 -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janelle Bynum', 'Janelle', 'Bynum', 'Democrat',
          true, false, false, true, -4102005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives'),
       p.id,
       'Representative', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4105' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'OR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
  );

-- ----- CD-06: Andrea Salinas (D) (-4102006) — geo_id 4106 -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andrea Salinas', 'Andrea', 'Salinas', 'Democrat',
          true, false, false, true, -4102006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives'),
       p.id,
       'Representative', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4106' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'OR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
  );


-- ===== STEP 3: office_id back-fill scoped to OR House rep range =====
-- Senators already have office_id back-filled; only House reps need this.
-- Guards with p.office_id IS NULL for idempotency.
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4102999 AND -4102001
  AND p.office_id IS NULL;

COMMIT;
