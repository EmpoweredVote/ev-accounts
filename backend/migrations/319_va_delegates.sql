-- Migration 308: Virginia House of Delegates Officials
-- 100 delegates (HD-1 through HD-100); HD-20 is VACANT (Maldonado resigned 2026-05-31).
--
-- Analog: generate_or_house.ps1 (migration 227, Oregon House of Representatives, single-member)
-- Reference SQL output: 227_or_state_house.sql
-- Phase 101, Requirement VA-GOV-04
--
-- Uses existing House of Delegates chamber from migration 304 (no chamber INSERT).
-- Uses existing STATE_LOWER districts from VA TIGER load (no district INSERT).
-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians; WHERE NOT EXISTS on offices.
--
-- external_id range: -5120001 (HD-01) through -5120100 (HD-100)
-- geo_id format: '51' + district_num.PadLeft(3, '0')  e.g. HD-1 -> '51001', HD-50 -> '51050', HD-100 -> '51100'
-- CRITICAL: d.state = 'va' (lowercase) - TIGER loader casing for STATE_LOWER districts
-- CRITICAL: d.district_type = 'STATE_LOWER' required - geo_ids 51001-51040 exist in BOTH
--           STATE_UPPER (senators) and STATE_LOWER (delegates); omitting district_type causes ambiguous subquery
-- CRITICAL: NOT EXISTS guard uses (district_id, chamber_id) - single-member pattern (NOT district_id, politician_id)
-- HD-20: Michelle Maldonado resigned May 31, 2026; no replacement seated; seeded as is_vacant=true, is_active=false
--
BEGIN;

-- ===== HD-1 (51001): Patrick A. Hope (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Patrick A. Hope', 'Patrick A.', 'Hope', 'Democrat',
          true, false, false, true, -5120001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51001' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-2 (51002): Adele Y. McClure (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Adele Y. McClure', 'Adele Y.', 'McClure', 'Democrat',
          true, false, false, true, -5120002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51002' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-3 (51003): Alfonso H. Lopez (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alfonso H. Lopez', 'Alfonso H.', 'Lopez', 'Democrat',
          true, false, false, true, -5120003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51003' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-4 (51004): Charniele L. Herring (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charniele L. Herring', 'Charniele L.', 'Herring', 'Democrat',
          true, false, false, true, -5120004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51004' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-5 (51005): R. Kirk McPike (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'R. Kirk McPike', 'R. Kirk', 'McPike', 'Democrat',
          true, false, false, true, -5120005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51005' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-6 (51006): Richard C. Sullivan, Jr. (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard C. Sullivan, Jr.', 'Richard C.', 'Sullivan', 'Democrat',
          true, false, false, true, -5120006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51006' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-7 (51007): Karen Keys-Gamarra (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karen Keys-Gamarra', 'Karen', 'Keys-Gamarra', 'Democrat',
          true, false, false, true, -5120007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51007' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-8 (51008): Irene Shin (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Irene Shin', 'Irene', 'Shin', 'Democrat',
          true, false, false, true, -5120008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51008' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-9 (51009): Karrie K. Delaney (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karrie K. Delaney', 'Karrie K.', 'Delaney', 'Democrat',
          true, false, false, true, -5120009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51009' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-10 (51010): Dan Helmer (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dan Helmer', 'Dan', 'Helmer', 'Democrat',
          true, false, false, true, -5120010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51010' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-11 (51011): Gretchen M. Bulova (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gretchen M. Bulova', 'Gretchen M.', 'Bulova', 'Democrat',
          true, false, false, true, -5120011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51011' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-12 (51012): Holly M. Seibold (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Holly M. Seibold', 'Holly M.', 'Seibold', 'Democrat',
          true, false, false, true, -5120012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51012' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-13 (51013): Marcus B. Simon (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marcus B. Simon', 'Marcus B.', 'Simon', 'Democrat',
          true, false, false, true, -5120013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51013' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-14 (51014): Vivian E. Watts (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vivian E. Watts', 'Vivian E.', 'Watts', 'Democrat',
          true, false, false, true, -5120014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51014' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-15 (51015): Laura Jane Cohen (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Laura Jane Cohen', 'Laura Jane', 'Cohen', 'Democrat',
          true, false, false, true, -5120015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51015' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-16 (51016): Paul E. Krizek (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul E. Krizek', 'Paul E.', 'Krizek', 'Democrat',
          true, false, false, true, -5120016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51016' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-17 (51017): Garrett McGuire (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Garrett McGuire', 'Garrett', 'McGuire', 'Democrat',
          true, false, false, true, -5120017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51017' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-18 (51018): Kathy KL Tran (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kathy KL Tran', 'Kathy KL', 'Tran', 'Democrat',
          true, false, false, true, -5120018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51018' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-19 (51019): Rozia A. Henson, Jr. (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rozia A. Henson, Jr.', 'Rozia A.', 'Henson', 'Democrat',
          true, false, false, true, -5120019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51019' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-20 (51020): VACANT (Maldonado resigned 2026-05-31) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vacant', '', '', '',
          false, false, true, false, -5120020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, true
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51020' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-21 (51021): Josh Thomas (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Josh Thomas', 'Josh', 'Thomas', 'Democrat',
          true, false, false, true, -5120021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51021' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-22 (51022): Elizabeth R. Guzman (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth R. Guzman', 'Elizabeth R.', 'Guzman', 'Democrat',
          true, false, false, true, -5120022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51022' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-23 (51023): Margaret Angela Franklin (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Margaret Angela Franklin', 'Margaret Angela', 'Franklin', 'Democrat',
          true, false, false, true, -5120023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51023' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-24 (51024): Luke E. Torian (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Luke E. Torian', 'Luke E.', 'Torian', 'Democrat',
          true, false, false, true, -5120024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51024' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-25 (51025): Briana D. Sewell (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Briana D. Sewell', 'Briana D.', 'Sewell', 'Democrat',
          true, false, false, true, -5120025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51025' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-26 (51026): JJ Singh (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'JJ Singh', 'JJ', 'Singh', 'Democrat',
          true, false, false, true, -5120026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51026' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-27 (51027): Atoosa R. Reaser (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Atoosa R. Reaser', 'Atoosa R.', 'Reaser', 'Democrat',
          true, false, false, true, -5120027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51027' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-28 (51028): David A. Reid (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David A. Reid', 'David A.', 'Reid', 'Democrat',
          true, false, false, true, -5120028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51028' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-29 (51029): Fernando J. Martinez (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Fernando J. Martinez', 'Fernando J.', 'Martinez', 'Democrat',
          true, false, false, true, -5120029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51029' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-30 (51030): John C McAuliff (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John C McAuliff', 'John C', 'McAuliff', 'Democrat',
          true, false, false, true, -5120030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51030' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-31 (51031): Delores Oates (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Delores Oates', 'Delores', 'Oates', 'Republican',
          true, false, false, true, -5120031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51031' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-32 (51032): William D. Wiley (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'William D. Wiley', 'William D.', 'Wiley', 'Republican',
          true, false, false, true, -5120032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51032' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-33 (51033): Justin L. Pence (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Justin L. Pence', 'Justin L.', 'Pence', 'Republican',
          true, false, false, true, -5120033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51033' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-34 (51034): Tony O. Wilt (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tony O. Wilt', 'Tony O.', 'Wilt', 'Republican',
          true, false, false, true, -5120034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51034' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-35 (51035): Chris Runion (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chris Runion', 'Chris', 'Runion', 'Republican',
          true, false, false, true, -5120035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51035' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-36 (51036): Ellen H. McLaughlin (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ellen H. McLaughlin', 'Ellen H.', 'McLaughlin', 'Democrat',
          true, false, false, true, -5120036)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51036' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-37 (51037): Terry L. Austin (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Terry L. Austin', 'Terry L.', 'Austin', 'Republican',
          true, false, false, true, -5120037)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51037' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-38 (51038): Sam Rasoul (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sam Rasoul', 'Sam', 'Rasoul', 'Democrat',
          true, false, false, true, -5120038)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51038' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-39 (51039): Will P. Davis (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Will P. Davis', 'Will P.', 'Davis', 'Democrat',
          true, false, false, true, -5120039)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51039' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-40 (51040): Joseph P. McNamara (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joseph P. McNamara', 'Joseph P.', 'McNamara', 'Republican',
          true, false, false, true, -5120040)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51040' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-41 (51041): Lily V. Franklin (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lily V. Franklin', 'Lily V.', 'Franklin', 'Democrat',
          true, false, false, true, -5120041)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51041' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-42 (51042): Jason S. Ballard (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jason S. Ballard', 'Jason S.', 'Ballard', 'Republican',
          true, false, false, true, -5120042)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51042' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-43 (51043): James W. Morefield (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James W. Morefield', 'James W.', 'Morefield', 'Republican',
          true, false, false, true, -5120043)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51043' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-44 (51044): Israel D. O'Quinn (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Israel D. O''Quinn', 'Israel D.', 'O''Quinn', 'Republican',
          true, false, false, true, -5120044)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51044' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-45 (51045): Terry G. Kilgore (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Terry G. Kilgore', 'Terry G.', 'Kilgore', 'Republican',
          true, false, false, true, -5120045)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51045' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-46 (51046): Mitchell Cornett (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mitchell Cornett', 'Mitchell', 'Cornett', 'Republican',
          true, false, false, true, -5120046)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51046' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-47 (51047): Wren M. Williams (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wren M. Williams', 'Wren M.', 'Williams', 'Republican',
          true, false, false, true, -5120047)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51047' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-48 (51048): Eric J. Phillips (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eric J. Phillips', 'Eric J.', 'Phillips', 'Republican',
          true, false, false, true, -5120048)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51048' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-49 (51049): Madison Whittle (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Madison Whittle', 'Madison', 'Whittle', 'Republican',
          true, false, false, true, -5120049)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51049' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-50 (51050): Thomas C. Wright, Jr. (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thomas C. Wright, Jr.', 'Thomas C.', 'Wright', 'Republican',
          true, false, false, true, -5120050)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51050' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-51 (51051): Eric Zehr (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eric Zehr', 'Eric', 'Zehr', 'Republican',
          true, false, false, true, -5120051)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51051' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-52 (51052): Wendell S. Walker (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wendell S. Walker', 'Wendell S.', 'Walker', 'Republican',
          true, false, false, true, -5120052)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51052' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-53 (51053): Timothy P. Griffin (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Timothy P. Griffin', 'Timothy P.', 'Griffin', 'Republican',
          true, false, false, true, -5120053)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51053' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-54 (51054): Katrina E. Callsen (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Katrina E. Callsen', 'Katrina E.', 'Callsen', 'Democrat',
          true, false, false, true, -5120054)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51054' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-55 (51055): Amy J. Laufer (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Amy J. Laufer', 'Amy J.', 'Laufer', 'Democrat',
          true, false, false, true, -5120055)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51055' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-56 (51056): Thomas A. Garrett, Jr. (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thomas A. Garrett, Jr.', 'Thomas A.', 'Garrett', 'Republican',
          true, false, false, true, -5120056)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51056' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-57 (51057): May Nivar (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'May Nivar', 'May', 'Nivar', 'Democrat',
          true, false, false, true, -5120057)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51057' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-58 (51058): Rodney T. Willett (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rodney T. Willett', 'Rodney T.', 'Willett', 'Republican',
          true, false, false, true, -5120058)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51058' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-59 (51059): Hyland F. Fowler, Jr. (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Hyland F. Fowler, Jr.', 'Hyland F.', 'Fowler', 'Republican',
          true, false, false, true, -5120059)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51059' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-60 (51060): Scott A. Wyatt (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Scott A. Wyatt', 'Scott A.', 'Wyatt', 'Republican',
          true, false, false, true, -5120060)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51060' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-61 (51061): Michael J. Webert (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael J. Webert', 'Michael J.', 'Webert', 'Republican',
          true, false, false, true, -5120061)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51061' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-62 (51062): Karen Fleming Hamilton (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karen Fleming Hamilton', 'Karen Fleming', 'Hamilton', 'Democrat',
          true, false, false, true, -5120062)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51062' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-63 (51063): Phillip A. Scott (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Phillip A. Scott', 'Phillip A.', 'Scott', 'Republican',
          true, false, false, true, -5120063)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51063' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-64 (51064): Stacey A. Carroll (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stacey A. Carroll', 'Stacey A.', 'Carroll', 'Democrat',
          true, false, false, true, -5120064)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51064' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-65 (51065): Joshua G. Cole (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joshua G. Cole', 'Joshua G.', 'Cole', 'Democrat',
          true, false, false, true, -5120065)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51065' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-66 (51066): Nicole Cole (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nicole Cole', 'Nicole', 'Cole', 'Democrat',
          true, false, false, true, -5120066)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51066' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-67 (51067): Hillary Pugh Kent (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Hillary Pugh Kent', 'Hillary Pugh', 'Kent', 'Democrat',
          true, false, false, true, -5120067)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51067' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-68 (51068): M. Keith Hodges (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'M. Keith Hodges', 'M. Keith', 'Hodges', 'Republican',
          true, false, false, true, -5120068)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51068' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-69 (51069): Mark C. Downey (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark C. Downey', 'Mark C.', 'Downey', 'Republican',
          true, false, false, true, -5120069)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51069' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-70 (51070): Shelly A. Simonds (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shelly A. Simonds', 'Shelly A.', 'Simonds', 'Democrat',
          true, false, false, true, -5120070)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51070' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-71 (51071): Jessica L. Anderson (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jessica L. Anderson', 'Jessica L.', 'Anderson', 'Democrat',
          true, false, false, true, -5120071)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51071' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-72 (51072): R. Lee Ware (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'R. Lee Ware', 'R. Lee', 'Ware', 'Republican',
          true, false, false, true, -5120072)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51072' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-73 (51073): Leslie Chambers Mehta (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Leslie Chambers Mehta', 'Leslie Chambers', 'Mehta', 'Democrat',
          true, false, false, true, -5120073)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51073' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-74 (51074): Mike A. Cherry (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike A. Cherry', 'Mike A.', 'Cherry', 'Republican',
          true, false, false, true, -5120074)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51074' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-75 (51075): Lindsey Dougherty (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lindsey Dougherty', 'Lindsey', 'Dougherty', 'Democrat',
          true, false, false, true, -5120075)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51075' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-76 (51076): Debra D. Gardner (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Debra D. Gardner', 'Debra D.', 'Gardner', 'Democrat',
          true, false, false, true, -5120076)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51076' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-77 (51077): Charles H. Schmidt, Jr. (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charles H. Schmidt, Jr.', 'Charles H.', 'Schmidt', 'Republican',
          true, false, false, true, -5120077)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51077' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-78 (51078): Betsy B. Carr (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Betsy B. Carr', 'Betsy B.', 'Carr', 'Democrat',
          true, false, false, true, -5120078)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51078' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-79 (51079): Rae C. Cousins (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rae C. Cousins', 'Rae C.', 'Cousins', 'Democrat',
          true, false, false, true, -5120079)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51079' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-80 (51080): Destiny L. LeVere Bolling (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Destiny L. LeVere Bolling', 'Destiny L.', 'LeVere Bolling', 'Democrat',
          true, false, false, true, -5120080)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51080' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-81 (51081): Delores L. McQuinn (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Delores L. McQuinn', 'Delores L.', 'McQuinn', 'Democrat',
          true, false, false, true, -5120081)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51081' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-82 (51082): Kimberly Pope Adams (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kimberly Pope Adams', 'Kimberly Pope', 'Adams', 'Democrat',
          true, false, false, true, -5120082)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51082' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-83 (51083): Howard Otto Wachsmann, Jr. (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Howard Otto Wachsmann, Jr.', 'Howard Otto', 'Wachsmann', 'Republican',
          true, false, false, true, -5120083)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51083' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-84 (51084): Nadarius E. Clark (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nadarius E. Clark', 'Nadarius E.', 'Clark', 'Democrat',
          true, false, false, true, -5120084)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51084' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-85 (51085): Marcia S. Price (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marcia S. Price', 'Marcia S.', 'Price', 'Democrat',
          true, false, false, true, -5120085)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51085' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-86 (51086): Virgil Gene Thornton, Sr. (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Virgil Gene Thornton, Sr.', 'Virgil Gene', 'Thornton', 'Democrat',
          true, false, false, true, -5120086)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51086' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-87 (51087): Jeion A. Ward (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeion A. Ward', 'Jeion A.', 'Ward', 'Democrat',
          true, false, false, true, -5120087)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51087' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-88 (51088): Don Scott (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Don Scott', 'Don', 'Scott', 'Democrat',
          true, false, false, true, -5120088)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51088' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-89 (51089): Karen Robins Carnegie (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karen Robins Carnegie', 'Karen Robins', 'Carnegie', 'Democrat',
          true, false, false, true, -5120089)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51089' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-90 (51090): James A. Leftwich, Jr. (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James A. Leftwich, Jr.', 'James A.', 'Leftwich', 'Republican',
          true, false, false, true, -5120090)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51090' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-91 (51091): C. E. Hayes, Jr. (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'C. E. Hayes, Jr.', 'C. E.', 'Hayes', 'Democrat',
          true, false, false, true, -5120091)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51091' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-92 (51092): Bonita G. Anthony (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bonita G. Anthony', 'Bonita G.', 'Anthony', 'Democrat',
          true, false, false, true, -5120092)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51092' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-93 (51093): Jackie Hope Glass (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jackie Hope Glass', 'Jackie Hope', 'Glass', 'Democrat',
          true, false, false, true, -5120093)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51093' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-94 (51094): Phil M. Hernandez (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Phil M. Hernandez', 'Phil M.', 'Hernandez', 'Democrat',
          true, false, false, true, -5120094)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51094' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-95 (51095): Alex Q. Askew (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alex Q. Askew', 'Alex Q.', 'Askew', 'Democrat',
          true, false, false, true, -5120095)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51095' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-96 (51096): Kelly K. Convirs-Fowler (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kelly K. Convirs-Fowler', 'Kelly K.', 'Convirs-Fowler', 'Democrat',
          true, false, false, true, -5120096)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51096' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-97 (51097): Michael Feggans (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Feggans', 'Michael', 'Feggans', 'Democrat',
          true, false, false, true, -5120097)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51097' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-98 (51098): Andrew Rice (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andrew Rice', 'Andrew', 'Rice', 'Democrat',
          true, false, false, true, -5120098)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51098' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-99 (51099): Anne Ferrell H. Tata (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anne Ferrell H. Tata', 'Anne Ferrell H.', 'Tata', 'Republican',
          true, false, false, true, -5120099)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51099' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== HD-100 (51100): Robert S. Bloxom, Jr. (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Robert S. Bloxom, Jr.', 'Robert S.', 'Bloxom', 'Republican',
          true, false, false, true, -5120100)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Delegate', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51100' AND d.district_type = 'STATE_LOWER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'House of Delegates'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== office_id back-fill =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -5120100 AND -5120001
  AND p.office_id IS NULL;

COMMIT;
