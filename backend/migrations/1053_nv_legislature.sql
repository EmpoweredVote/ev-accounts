-- Migration 1053: Nevada State Legislature (structural seed)
--
-- Phase 160 (NV-LEG-01 / NV-LEG-02). STRUCTURAL migration (registered in the
-- migration ledger OUTSIDE the transaction at the bottom of this file).
--
-- Creates two chambers under the State of Nevada government (geo_id = '32'):
--   - Nevada State Senate    (parent of 21 STATE_UPPER offices, SD-1..SD-21)
--   - Nevada Assembly        (parent of 42 STATE_LOWER offices, AD-1..AD-42)
-- Then inserts all 63 sitting legislators and links each to its PRE-EXISTING
-- SLDU/SLDL district row loaded by Phase 158 (NO district INSERT), and
-- back-fills politicians.office_id per chamber range.
--
-- external_id ranges (non-colliding):
--   Senate   -3203001 (SD-1)  .. -3203021 (SD-21)
--   Assembly -3204001 (AD-1)  .. -3204042 (AD-42)
--
-- District keying: geo_id = '32' + LPAD(district_number, 3, '0')
--   e.g. SD-5 -> '32005', AD-42 -> '32042'.
--
-- CRITICAL casing rules (verified against OR/VA analogs):
--   - Legislature district join uses LOWERCASE state ('nv'). Uppercase 'NV'
--     here matches ZERO districts (silent no-op). Phase 159 STATE_EXEC used
--     uppercase 'NV' deliberately; THIS legislature phase is the inverse.
--   - district_type is MANDATORY in every office WHERE clause. STATE_UPPER and
--     STATE_LOWER share the same numeric geo_id space (32001-32042); omitting
--     district_type yields an ambiguous/duplicate-district subquery.
--   - representing_state on the office is the UPPERCASE free-text label 'NV'
--     (NOT the district join key).
--
-- The chambers INSERT excludes the auto-generated path column (it is GENERATED
-- ALWAYS; including it raises a non-DEFAULT-value error). name_formal must
-- never be empty (empty value breaks profile-page render).
--
-- Idempotent: chambers guarded by NOT EXISTS; politicians ON CONFLICT
-- (external_id) DO NOTHING; offices guarded by NOT EXISTS on
-- (district_id, chamber_id); back-fills guarded by office_id IS NULL.
--
-- Diacritics preserved in full_name: Fabian Doñate (SD-10),
-- Cecelia González (AD-16), Cinthia Zermeño Moore (AD-11).

BEGIN;

-- ============================================================
-- Pre-flight: assert the State of Nevada government exists
-- ============================================================
DO $$
DECLARE
  gov_count integer;
BEGIN
  SELECT COUNT(*) INTO gov_count
  FROM essentials.governments
  WHERE geo_id = '32';
  IF gov_count <> 1 THEN
    RAISE EXCEPTION 'Expected exactly 1 government with geo_id=32, found %', gov_count;
  END IF;
END $$;

-- ============================================================
-- STEP 1: Chambers (idempotent, auto-generated path column excluded)
-- ============================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Nevada State Senate',
       'Nevada State Senate',
       (SELECT id FROM essentials.governments WHERE geo_id = '32')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Nevada State Senate'
    AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Nevada Assembly',
       'Nevada State Assembly',
       (SELECT id FROM essentials.governments WHERE geo_id = '32')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Nevada Assembly'
    AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')
);

-- ============================================================
-- STEP 2: Politicians + Offices linked to EXISTING SLDU/SLDL districts
-- ============================================================

-- ===== SD-1 (32001): Michelee "Shelly" Cruz-Crawford (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michelee "Shelly" Cruz-Crawford', 'Michelee "Shelly"', 'Cruz-Crawford', 'Democratic',
          true, false, false, true, -3203001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32001' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-2 (32002): Edgar Flores (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Edgar Flores', 'Edgar', 'Flores', 'Democratic',
          true, false, false, true, -3203002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32002' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-3 (32003): Rochelle T. Nguyen (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rochelle T. Nguyen', 'Rochelle T.', 'Nguyen', 'Democratic',
          true, false, false, true, -3203003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32003' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-4 (32004): Dina Neal (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dina Neal', 'Dina', 'Neal', 'Democratic',
          true, false, false, true, -3203004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32004' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-5 (32005): Carrie Ann Buck (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carrie Ann Buck', 'Carrie Ann', 'Buck', 'Republican',
          true, false, false, true, -3203005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32005' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-6 (32006): Nicole J. Cannizzaro (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nicole J. Cannizzaro', 'Nicole J.', 'Cannizzaro', 'Democratic',
          true, false, false, true, -3203006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32006' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-7 (32007): Roberta Lange (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roberta Lange', 'Roberta', 'Lange', 'Democratic',
          true, false, false, true, -3203007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32007' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-8 (32008): Marilyn Dondero Loop (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marilyn Dondero Loop', 'Marilyn', 'Dondero Loop', 'Democratic',
          true, false, false, true, -3203008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32008' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-9 (32009): Melanie Scheible (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Melanie Scheible', 'Melanie', 'Scheible', 'Democratic',
          true, false, false, true, -3203009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32009' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-10 (32010): Fabian Doñate (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Fabian Doñate', 'Fabian', 'Doñate', 'Democratic',
          true, false, false, true, -3203010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32010' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-11 (32011): Lori Rogich (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lori Rogich', 'Lori', 'Rogich', 'Republican',
          true, false, false, true, -3203011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32011' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-12 (32012): Julie Pazina (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julie Pazina', 'Julie', 'Pazina', 'Democratic',
          true, false, false, true, -3203012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32012' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-13 (32013): Skip Daly (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Skip Daly', 'Skip', 'Daly', 'Democratic',
          true, false, false, true, -3203013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32013' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-14 (32014): Ira Hansen (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ira Hansen', 'Ira', 'Hansen', 'Republican',
          true, false, false, true, -3203014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32014' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-15 (32015): Angela D. Taylor (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angela D. Taylor', 'Angela D.', 'Taylor', 'Democratic',
          true, false, false, true, -3203015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32015' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-16 (32016): Lisa Krasner (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Krasner', 'Lisa', 'Krasner', 'Republican',
          true, false, false, true, -3203016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32016' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-17 (32017): Robin L. Titus (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Robin L. Titus', 'Robin L.', 'Titus', 'Republican',
          true, false, false, true, -3203017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32017' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-18 (32018): John C. Steinbeck (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John C. Steinbeck', 'John C.', 'Steinbeck', 'Republican',
          true, false, false, true, -3203018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32018' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-19 (32019): John Ellison (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Ellison', 'John', 'Ellison', 'Republican',
          true, false, false, true, -3203019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32019' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-20 (32020): Jeff Stone (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeff Stone', 'Jeff', 'Stone', 'Republican',
          true, false, false, true, -3203020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32020' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== SD-21 (32021): James Ohrenschall (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Ohrenschall', 'James', 'Ohrenschall', 'Democratic',
          true, false, false, true, -3203021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'State Senator', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32021' AND d.district_type = 'STATE_UPPER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-1 (32001): Daniele Monroe-Moreno (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniele Monroe-Moreno', 'Daniele', 'Monroe-Moreno', 'Democratic',
          true, false, false, true, -3204001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32001' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-2 (32002): Heidi Kasama (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Heidi Kasama', 'Heidi', 'Kasama', 'Republican',
          true, false, false, true, -3204002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32002' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-3 (32003): Selena Torres-Fossett (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Selena Torres-Fossett', 'Selena', 'Torres-Fossett', 'Democratic',
          true, false, false, true, -3204003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32003' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-4 (32004): Lisa K. Cole (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa K. Cole', 'Lisa K.', 'Cole', 'Republican',
          true, false, false, true, -3204004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32004' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-5 (32005): Brittney M. Miller (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brittney M. Miller', 'Brittney M.', 'Miller', 'Democratic',
          true, false, false, true, -3204005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32005' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-6 (32006): Jovan A. Jackson (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jovan A. Jackson', 'Jovan A.', 'Jackson', 'Democratic',
          true, false, false, true, -3204006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32006' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-7 (32007): Tanya P. Flanagan (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tanya P. Flanagan', 'Tanya P.', 'Flanagan', 'Democratic',
          true, false, false, true, -3204007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32007' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-8 (32008): Duy Nguyen (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Duy Nguyen', 'Duy', 'Nguyen', 'Democratic',
          true, false, false, true, -3204008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32008' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-9 (32009): Steve Yeager (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Yeager', 'Steve', 'Yeager', 'Democratic',
          true, false, false, true, -3204009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32009' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-10 (32010): Venise Karris (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Venise Karris', 'Venise', 'Karris', 'Democratic',
          true, false, false, true, -3204010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32010' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-11 (32011): Cinthia Zermeño Moore (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cinthia Zermeño Moore', 'Cinthia', 'Zermeño Moore', 'Democratic',
          true, false, false, true, -3204011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32011' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-12 (32012): Max E. Carter II (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Max E. Carter II', 'Max E.', 'Carter II', 'Democratic',
          true, false, false, true, -3204012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32012' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-13 (32013): Brian Hibbetts (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Hibbetts', 'Brian', 'Hibbetts', 'Republican',
          true, false, false, true, -3204013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32013' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-14 (32014): Erica Mosca (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Erica Mosca', 'Erica', 'Mosca', 'Democratic',
          true, false, false, true, -3204014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32014' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-15 (32015): Howard Watts III (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Howard Watts III', 'Howard', 'Watts III', 'Democratic',
          true, false, false, true, -3204015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32015' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-16 (32016): Cecelia González (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cecelia González', 'Cecelia', 'González', 'Democratic',
          true, false, false, true, -3204016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32016' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-17 (32017): Linda F. Hunt (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Linda F. Hunt', 'Linda F.', 'Hunt', 'Democratic',
          true, false, false, true, -3204017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32017' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-18 (32018): Venicia Considine (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Venicia Considine', 'Venicia', 'Considine', 'Democratic',
          true, false, false, true, -3204018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32018' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-19 (32019): Jason Patchett (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jason Patchett', 'Jason', 'Patchett', 'Republican',
          true, false, false, true, -3204019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32019' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-20 (32020): David Orentlicher (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Orentlicher', 'David', 'Orentlicher', 'Democratic',
          true, false, false, true, -3204020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32020' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-21 (32021): Elaine H. Marzola (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elaine H. Marzola', 'Elaine H.', 'Marzola', 'Democratic',
          true, false, false, true, -3204021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32021' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-22 (32022): Melissa R. Hardy (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Melissa R. Hardy', 'Melissa R.', 'Hardy', 'Republican',
          true, false, false, true, -3204022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32022' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-23 (32023): Danielle Gallant (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Danielle Gallant', 'Danielle', 'Gallant', 'Republican',
          true, false, false, true, -3204023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32023' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-24 (32024): Erica P. Roth (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Erica P. Roth', 'Erica P.', 'Roth', 'Democratic',
          true, false, false, true, -3204024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32024' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-25 (32025): Selena La Rue Hatch (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Selena La Rue Hatch', 'Selena', 'La Rue Hatch', 'Democratic',
          true, false, false, true, -3204025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32025' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-26 (32026): Rich DeLong (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rich DeLong', 'Rich', 'DeLong', 'Republican',
          true, false, false, true, -3204026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32026' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-27 (32027): Heather Goulding (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Heather Goulding', 'Heather', 'Goulding', 'Democratic',
          true, false, false, true, -3204027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32027' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-28 (32028): Reuben D'Silva (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Reuben D''Silva', 'Reuben', 'D''Silva', 'Democratic',
          true, false, false, true, -3204028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32028' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-29 (32029): Joe Dalia (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joe Dalia', 'Joe', 'Dalia', 'Democratic',
          true, false, false, true, -3204029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32029' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-30 (32030): Natha C. Anderson (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Natha C. Anderson', 'Natha C.', 'Anderson', 'Democratic',
          true, false, false, true, -3204030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32030' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-31 (32031): Jill Dickman (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jill Dickman', 'Jill', 'Dickman', 'Republican',
          true, false, false, true, -3204031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32031' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-32 (32032): Alexis M. Hansen (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alexis M. Hansen', 'Alexis M.', 'Hansen', 'Republican',
          true, false, false, true, -3204032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32032' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-33 (32033): Bert K. Gurr (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bert K. Gurr', 'Bert K.', 'Gurr', 'Republican',
          true, false, false, true, -3204033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32033' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-34 (32034): Hanadi Nadeem (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Hanadi Nadeem', 'Hanadi', 'Nadeem', 'Democratic',
          true, false, false, true, -3204034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32034' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-35 (32035): Rebecca Edgeworth (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rebecca Edgeworth', 'Rebecca', 'Edgeworth', 'Republican',
          true, false, false, true, -3204035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32035' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-36 (32036): Gregory T. Hafen II (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gregory T. Hafen II', 'Gregory T.', 'Hafen II', 'Republican',
          true, false, false, true, -3204036)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32036' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-37 (32037): Shea M. Backus (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shea M. Backus', 'Shea M.', 'Backus', 'Democratic',
          true, false, false, true, -3204037)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32037' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-38 (32038): Gregory S. Koenig (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gregory S. Koenig', 'Gregory S.', 'Koenig', 'Republican',
          true, false, false, true, -3204038)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32038' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-39 (32039): Blayne Osborn (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Blayne Osborn', 'Blayne', 'Osborn', 'Republican',
          true, false, false, true, -3204039)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32039' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-40 (32040): P. K. O'Neill (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'P. K. O''Neill', 'P. K.', 'O''Neill', 'Republican',
          true, false, false, true, -3204040)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32040' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-41 (32041): Sandra Jauregui (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sandra Jauregui', 'Sandra', 'Jauregui', 'Democratic',
          true, false, false, true, -3204041)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32041' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== AD-42 (32042): Tracy Brown-May (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tracy Brown-May', 'Tracy', 'Brown-May', 'Democratic',
          true, false, false, true, -3204042)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Nevada Assembly'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Assemblymember', 'NV', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32042' AND d.district_type = 'STATE_LOWER' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Nevada Assembly'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ============================================================
-- STEP 3: office_id back-fill (per chamber external_id range)
-- ============================================================

-- Senate back-fill (-3203001..-3203021)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -3203021 AND -3203001
  AND p.office_id IS NULL;

-- Assembly back-fill (-3204001..-3204042)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -3204042 AND -3204001
  AND p.office_id IS NULL;

COMMIT;

-- ============================================================
-- STEP 4: structural registration (OUTSIDE the transaction)
-- ============================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1053', 'nv_legislature')
ON CONFLICT (version) DO NOTHING;
