-- Migration 226: Oregon State Senate Officials
-- 30 senators, all districts filled, no vacancies.
--
-- Uses existing Oregon Senate chamber from Phase 73 migration 222 (no chamber INSERT).
-- Uses existing STATE_UPPER districts from Phase 72 TIGER load (no district INSERT).
-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians; WHERE NOT EXISTS on offices.
--
-- external_id range: -4110001 (SD-01) through -4110030 (SD-30)
-- geo_id format: '41' + district_num.PadLeft(3, '0')  e.g. SD-01 -> '41001', SD-17 -> '41017'
-- CRITICAL: d.state = 'or' (lowercase) - TIGER loader casing for STATE_UPPER/STATE_LOWER
-- CRITICAL: district_type = 'STATE_UPPER' required - geo_ids 41001-41030 exist in BOTH
--           STATE_UPPER and STATE_LOWER; omitting district_type causes ambiguous subquery
--
BEGIN;

-- ===== SD-1 (41001): David Brock Smith (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Brock Smith', 'David', 'Brock Smith', 'Republican',
          true, false, false, true, -4110001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41001' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-2 (41002): Noah Robinson (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Noah Robinson', 'Noah', 'Robinson', 'Republican',
          true, false, false, true, -4110002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41002' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-3 (41003): Jeff Golden (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeff Golden', 'Jeff', 'Golden', 'Democratic',
          true, false, false, true, -4110003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41003' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-4 (41004): Floyd Prozanski (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Floyd Prozanski', 'Floyd', 'Prozanski', 'Democratic',
          true, false, false, true, -4110004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41004' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-5 (41005): Dick Anderson (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dick Anderson', 'Dick', 'Anderson', 'Republican',
          true, false, false, true, -4110005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41005' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-6 (41006): Cedric Hayden (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cedric Hayden', 'Cedric', 'Hayden', 'Republican',
          true, false, false, true, -4110006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41006' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-7 (41007): James I. Manning Jr. (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James I. Manning Jr.', 'James', 'Manning', 'Democratic',
          true, false, false, true, -4110007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41007' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-8 (41008): Sara Gelser Blouin (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sara Gelser Blouin', 'Sara', 'Gelser Blouin', 'Democratic',
          true, false, false, true, -4110008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41008' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-9 (41009): Fred Girod (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Fred Girod', 'Fred', 'Girod', 'Republican',
          true, false, false, true, -4110009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41009' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-10 (41010): Deb Patterson (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Deb Patterson', 'Deb', 'Patterson', 'Democratic',
          true, false, false, true, -4110010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41010' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-11 (41011): Kim Thatcher (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kim Thatcher', 'Kim', 'Thatcher', 'Republican',
          true, false, false, true, -4110011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41011' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-12 (41012): Bruce Starr (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bruce Starr', 'Bruce', 'Starr', 'Republican',
          true, false, false, true, -4110012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41012' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-13 (41013): Courtney Neron Misslin (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Courtney Neron Misslin', 'Courtney', 'Neron Misslin', 'Democratic',
          true, false, false, true, -4110013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41013' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-14 (41014): Kate Lieber (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kate Lieber', 'Kate', 'Lieber', 'Democratic',
          true, false, false, true, -4110014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41014' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-15 (41015): Janeen Sollman (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janeen Sollman', 'Janeen', 'Sollman', 'Democratic',
          true, false, false, true, -4110015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41015' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-16 (41016): Suzanne Weber (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Suzanne Weber', 'Suzanne', 'Weber', 'Republican',
          true, false, false, true, -4110016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41016' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-17 (41017): Lisa Reynolds (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Reynolds', 'Lisa', 'Reynolds', 'Democratic',
          true, false, false, true, -4110017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41017' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-18 (41018): Wlnsvey Campos (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wlnsvey Campos', 'Wlnsvey', 'Campos', 'Democratic',
          true, false, false, true, -4110018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41018' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-19 (41019): Rob Wagner (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rob Wagner', 'Rob', 'Wagner', 'Democratic',
          true, false, false, true, -4110019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41019' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-20 (41020): Mark Meek (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Meek', 'Mark', 'Meek', 'Democratic',
          true, false, false, true, -4110020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41020' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-21 (41021): Kathleen Taylor (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kathleen Taylor', 'Kathleen', 'Taylor', 'Democratic',
          true, false, false, true, -4110021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41021' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-22 (41022): Lew Frederick (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lew Frederick', 'Lew', 'Frederick', 'Democratic',
          true, false, false, true, -4110022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41022' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-23 (41023): Khanh Pham (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Khanh Pham', 'Khanh', 'Pham', 'Democratic',
          true, false, false, true, -4110023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41023' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-24 (41024): Kayse Jama (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kayse Jama', 'Kayse', 'Jama', 'Democratic',
          true, false, false, true, -4110024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41024' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-25 (41025): Chris Gorsek (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chris Gorsek', 'Chris', 'Gorsek', 'Democratic',
          true, false, false, true, -4110025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41025' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-26 (41026): Christine Drazan (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christine Drazan', 'Christine', 'Drazan', 'Republican',
          true, false, false, true, -4110026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41026' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-27 (41027): Anthony Broadman (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anthony Broadman', 'Anthony', 'Broadman', 'Democratic',
          true, false, false, true, -4110027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41027' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-28 (41028): Diane Linthicum (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Diane Linthicum', 'Diane', 'Linthicum', 'Republican',
          true, false, false, true, -4110028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41028' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-29 (41029): Todd Nash (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Todd Nash', 'Todd', 'Nash', 'Republican',
          true, false, false, true, -4110029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41029' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== SD-30 (41030): Mike McLane (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike McLane', 'Mike', 'McLane', 'Republican',
          true, false, false, true, -4110030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41030' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== office_id back-fill =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4110030 AND -4110001
  AND p.office_id IS NULL;

COMMIT;
