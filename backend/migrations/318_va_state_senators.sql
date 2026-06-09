-- Migration 307: Virginia State Senate Officials
-- 40 senators, no vacancies.
--
-- Source analogs: 273_md_state_senators.sql, generate_md_senate.ps1
-- Phase: 101 (VA State Government DB)
-- Requirement: VA-GOV-03
--
-- Uses existing Virginia Senate chamber from Phase 101 migration 304.
-- Uses existing STATE_UPPER districts from Phase 100 TIGER load.
-- Idempotent: ON CONFLICT (external_id) DO NOTHING; WHERE NOT EXISTS on offices.
--
-- external_id range: -5110001 (SD-1 French) through -5110040 (SD-40 Favola)
-- geo_id format: '51' + district_num.PadLeft(3, '0')  e.g. SD-1 -> '51001', SD-40 -> '51040'
-- CRITICAL: d.state = 'va' (lowercase) - TIGER loader casing for STATE_UPPER/STATE_LOWER
-- CRITICAL: district_type = 'STATE_UPPER' required - geo_ids 51001-51040 exist in BOTH
--           STATE_UPPER and STATE_LOWER (100% overlap); omitting causes 2 offices per senator
-- CRITICAL: Idempotent via ON CONFLICT (external_id) + NOT EXISTS (district_id, chamber_id)
--
BEGIN;

-- ===== SD-1 (51001): Timmy French (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Timmy French', 'Timmy', 'French', 'Republican',
          true, false, false, true, -5110001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51001' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-2 (51002): Mark D. Obenshain (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark D. Obenshain', 'Mark D.', 'Obenshain', 'Republican',
          true, false, false, true, -5110002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51002' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-3 (51003): Christopher T. Head (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christopher T. Head', 'Christopher T.', 'Head', 'Republican',
          true, false, false, true, -5110003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51003' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-4 (51004): David R. Suetterlein (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David R. Suetterlein', 'David R.', 'Suetterlein', 'Republican',
          true, false, false, true, -5110004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51004' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-5 (51005): T. Travis Hackworth (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'T. Travis Hackworth', 'T. Travis', 'Hackworth', 'Republican',
          true, false, false, true, -5110005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51005' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-6 (51006): Todd E. Pillion (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Todd E. Pillion', 'Todd E.', 'Pillion', 'Republican',
          true, false, false, true, -5110006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51006' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-7 (51007): William M. Stanley, Jr. (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'William M. Stanley, Jr.', 'William M.', 'Stanley', 'Republican',
          true, false, false, true, -5110007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51007' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-8 (51008): Mark J. Peake (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark J. Peake', 'Mark J.', 'Peake', 'Republican',
          true, false, false, true, -5110008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51008' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-9 (51009): Tammy Brankley Mulchi (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tammy Brankley Mulchi', 'Tammy', 'Brankley Mulchi', 'Republican',
          true, false, false, true, -5110009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51009' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-10 (51010): Luther H. Cifers, III (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Luther H. Cifers, III', 'Luther H.', 'Cifers', 'Republican',
          true, false, false, true, -5110010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51010' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-11 (51011): R. Creigh Deeds (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'R. Creigh Deeds', 'R. Creigh', 'Deeds', 'Democrat',
          true, false, false, true, -5110011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51011' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-12 (51012): Glen H. Sturtevant, Jr. (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Glen H. Sturtevant, Jr.', 'Glen H.', 'Sturtevant', 'Republican',
          true, false, false, true, -5110012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51012' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-13 (51013): Lashrecse D. Aird (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lashrecse D. Aird', 'Lashrecse D.', 'Aird', 'Democrat',
          true, false, false, true, -5110013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51013' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-14 (51014): Lamont Bagby (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lamont Bagby', 'Lamont', 'Bagby', 'Democrat',
          true, false, false, true, -5110014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51014' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-15 (51015): Michael J. Jones (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael J. Jones', 'Michael J.', 'Jones', 'Democrat',
          true, false, false, true, -5110015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51015' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-16 (51016): Schuyler T. VanValkenburg (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Schuyler T. VanValkenburg', 'Schuyler T.', 'VanValkenburg', 'Democrat',
          true, false, false, true, -5110016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51016' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-17 (51017): Emily M. Jordan (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Emily M. Jordan', 'Emily M.', 'Jordan', 'Republican',
          true, false, false, true, -5110017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51017' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-18 (51018): L. Louise Lucas (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'L. Louise Lucas', 'L. Louise', 'Lucas', 'Democrat',
          true, false, false, true, -5110018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51018' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-19 (51019): Christie New Craig (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christie New Craig', 'Christie', 'New Craig', 'Republican',
          true, false, false, true, -5110019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51019' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-20 (51020): Bill DeSteph (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bill DeSteph', 'Bill', 'DeSteph', 'Republican',
          true, false, false, true, -5110020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51020' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-21 (51021): Angelia Williams Graves (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angelia Williams Graves', 'Angelia', 'Williams Graves', 'Democrat',
          true, false, false, true, -5110021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51021' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-22 (51022): Aaron R. Rouse (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Aaron R. Rouse', 'Aaron R.', 'Rouse', 'Democrat',
          true, false, false, true, -5110022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51022' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-23 (51023): Mamie E. Locke (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mamie E. Locke', 'Mamie E.', 'Locke', 'Democrat',
          true, false, false, true, -5110023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51023' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-24 (51024): J.D. "Danny" Diggs (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'J.D. "Danny" Diggs', 'J.D.', 'Diggs', 'Republican',
          true, false, false, true, -5110024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51024' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-25 (51025): Richard H. Stuart (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard H. Stuart', 'Richard H.', 'Stuart', 'Republican',
          true, false, false, true, -5110025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51025' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-26 (51026): Ryan T. McDougle (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ryan T. McDougle', 'Ryan T.', 'McDougle', 'Republican',
          true, false, false, true, -5110026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51026' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-27 (51027): Tara A. Durant (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tara A. Durant', 'Tara A.', 'Durant', 'Republican',
          true, false, false, true, -5110027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51027' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-28 (51028): Bryce E. Reeves (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bryce E. Reeves', 'Bryce E.', 'Reeves', 'Republican',
          true, false, false, true, -5110028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51028' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-29 (51029): Jeremy S. McPike (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeremy S. McPike', 'Jeremy S.', 'McPike', 'Democrat',
          true, false, false, true, -5110029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51029' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-30 (51030): Danica A. Roem (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Danica A. Roem', 'Danica A.', 'Roem', 'Democrat',
          true, false, false, true, -5110030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51030' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-31 (51031): Russet W. Perry (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Russet W. Perry', 'Russet W.', 'Perry', 'Democrat',
          true, false, false, true, -5110031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51031' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-32 (51032): Kannan Srinivasan (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kannan Srinivasan', 'Kannan', 'Srinivasan', 'Democrat',
          true, false, false, true, -5110032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51032' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-33 (51033): Jennifer D. Carroll Foy (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jennifer D. Carroll Foy', 'Jennifer D.', 'Foy', 'Democrat',
          true, false, false, true, -5110033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51033' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-34 (51034): Scott A. Surovell (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Scott A. Surovell', 'Scott A.', 'Surovell', 'Democrat',
          true, false, false, true, -5110034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51034' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-35 (51035): David W. Marsden (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David W. Marsden', 'David W.', 'Marsden', 'Democrat',
          true, false, false, true, -5110035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51035' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-36 (51036): Stella G. Pekarsky (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stella G. Pekarsky', 'Stella G.', 'Pekarsky', 'Democrat',
          true, false, false, true, -5110036)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51036' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-37 (51037): Saddam Azlan Salim (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Saddam Azlan Salim', 'Saddam', 'Salim', 'Democrat',
          true, false, false, true, -5110037)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51037' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-38 (51038): Jennifer B. Boysko (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jennifer B. Boysko', 'Jennifer B.', 'Boysko', 'Democrat',
          true, false, false, true, -5110038)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51038' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-39 (51039): Elizabeth B. Bennett-Parker (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth B. Bennett-Parker', 'Elizabeth B.', 'Bennett-Parker', 'Democrat',
          true, false, false, true, -5110039)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51039' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== SD-40 (51040): Barbara A. Favola (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Barbara A. Favola', 'Barbara A.', 'Favola', 'Democrat',
          true, false, false, true, -5110040)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '51040' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== office_id back-fill =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -5110040 AND -5110001
  AND p.office_id IS NULL;

COMMIT;
