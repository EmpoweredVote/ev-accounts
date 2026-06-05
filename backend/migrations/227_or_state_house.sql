-- Migration 227: Oregon House of Representatives Officials
-- 60 house reps, all districts filled, no vacancies.
--
-- Uses existing Oregon House of Representatives chamber from Phase 73 migration 222 (no chamber INSERT).
-- Uses existing STATE_LOWER districts from Phase 72 TIGER load (no district INSERT).
-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians; WHERE NOT EXISTS on offices.
--
-- external_id range: -4120001 (HD-01) through -4120060 (HD-60)
-- geo_id format: '41' + district_num.PadLeft(3, '0')  e.g. HD-01 -> '41001', HD-33 -> '41033', HD-60 -> '41060'
-- CRITICAL: d.state = 'or' (lowercase) - TIGER loader casing for STATE_UPPER/STATE_LOWER
-- CRITICAL: district_type = 'STATE_LOWER' required - geo_ids 41001-41030 exist in BOTH
--           STATE_UPPER and STATE_LOWER; omitting district_type causes ambiguous subquery
--
BEGIN;

-- ===== HD-1 (41001): Court Boice (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Court Boice', 'Court', 'Boice', 'Republican',
          true, false, false, true, -4120001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41001' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-2 (41002): Virgle Osborne (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Virgle Osborne', 'Virgle', 'Osborne', 'Republican',
          true, false, false, true, -4120002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41002' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-3 (41003): Dwayne Yunker (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dwayne Yunker', 'Dwayne', 'Yunker', 'Republican',
          true, false, false, true, -4120003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41003' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-4 (41004): Alek Skarlatos (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alek Skarlatos', 'Alek', 'Skarlatos', 'Republican',
          true, false, false, true, -4120004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41004' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-5 (41005): Pam Marsh (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pam Marsh', 'Pam', 'Marsh', 'Democratic',
          true, false, false, true, -4120005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41005' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-6 (41006): Kim Wallan (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kim Wallan', 'Kim', 'Wallan', 'Republican',
          true, false, false, true, -4120006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41006' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-7 (41007): John Lively (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Lively', 'John', 'Lively', 'Democratic',
          true, false, false, true, -4120007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41007' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-8 (41008): Lisa Fragala (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Fragala', 'Lisa', 'Fragala', 'Democratic',
          true, false, false, true, -4120008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41008' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-9 (41009): Boomer Wright (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Boomer Wright', 'Boomer', 'Wright', 'Republican',
          true, false, false, true, -4120009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41009' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-10 (41010): David Gomberg (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Gomberg', 'David', 'Gomberg', 'Democratic',
          true, false, false, true, -4120010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41010' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-11 (41011): Jami Cate (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jami Cate', 'Jami', 'Cate', 'Republican',
          true, false, false, true, -4120011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41011' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-12 (41012): Darin Harbick (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Darin Harbick', 'Darin', 'Harbick', 'Republican',
          true, false, false, true, -4120012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41012' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-13 (41013): Nancy Nathanson (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nancy Nathanson', 'Nancy', 'Nathanson', 'Democratic',
          true, false, false, true, -4120013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41013' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-14 (41014): Julie Fahey (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julie Fahey', 'Julie', 'Fahey', 'Democratic',
          true, false, false, true, -4120014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41014' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-15 (41015): Shelly Boshart Davis (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shelly Boshart Davis', 'Shelly', 'Boshart Davis', 'Republican',
          true, false, false, true, -4120015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41015' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-16 (41016): Sarah Finger McDonald (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sarah Finger McDonald', 'Sarah', 'Finger McDonald', 'Democratic',
          true, false, false, true, -4120016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41016' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-17 (41017): Ed Diehl (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ed Diehl', 'Ed', 'Diehl', 'Republican',
          true, false, false, true, -4120017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41017' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-18 (41018): Rick Lewis (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rick Lewis', 'Rick', 'Lewis', 'Republican',
          true, false, false, true, -4120018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41018' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-19 (41019): Tom Andersen (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tom Andersen', 'Tom', 'Andersen', 'Democratic',
          true, false, false, true, -4120019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41019' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-20 (41020): Paul Evans (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Evans', 'Paul', 'Evans', 'Democratic',
          true, false, false, true, -4120020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41020' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-21 (41021): Kevin Mannix (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Mannix', 'Kevin', 'Mannix', 'Republican',
          true, false, false, true, -4120021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41021' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-22 (41022): Lesly Muñoz (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lesly Muñoz', 'Lesly', 'Muñoz', 'Democratic',
          true, false, false, true, -4120022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41022' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-23 (41023): Anna Scharf (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anna Scharf', 'Anna', 'Scharf', 'Republican',
          true, false, false, true, -4120023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41023' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-24 (41024): Lucetta Elmer (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lucetta Elmer', 'Lucetta', 'Elmer', 'Republican',
          true, false, false, true, -4120024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41024' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-25 (41025): Ben Bowman (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ben Bowman', 'Ben', 'Bowman', 'Democratic',
          true, false, false, true, -4120025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41025' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-26 (41026): Sue Rieke Smith (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sue Rieke Smith', 'Sue', 'Rieke Smith', 'Democratic',
          true, false, false, true, -4120026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41026' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-27 (41027): Ken Helm (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ken Helm', 'Ken', 'Helm', 'Democratic',
          true, false, false, true, -4120027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41027' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-28 (41028): Dacia Grayber (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dacia Grayber', 'Dacia', 'Grayber', 'Democratic',
          true, false, false, true, -4120028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41028' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-29 (41029): Susan McLain (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Susan McLain', 'Susan', 'McLain', 'Democratic',
          true, false, false, true, -4120029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41029' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-30 (41030): Nathan Sosa (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nathan Sosa', 'Nathan', 'Sosa', 'Democratic',
          true, false, false, true, -4120030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41030' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-31 (41031): Darcey Edwards (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Darcey Edwards', 'Darcey', 'Edwards', 'Republican',
          true, false, false, true, -4120031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41031' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-32 (41032): Cyrus Javadi (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cyrus Javadi', 'Cyrus', 'Javadi', 'Democratic',
          true, false, false, true, -4120032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41032' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-33 (41033): Shannon Isadore (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shannon Isadore', 'Shannon', 'Isadore', 'Democratic',
          true, false, false, true, -4120033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41033' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-34 (41034): Mari Watanabe (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mari Watanabe', 'Mari', 'Watanabe', 'Democratic',
          true, false, false, true, -4120034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41034' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-35 (41035): Farrah Chaichi (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Farrah Chaichi', 'Farrah', 'Chaichi', 'Democratic',
          true, false, false, true, -4120035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41035' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-36 (41036): Hai Pham (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Hai Pham', 'Hai', 'Pham', 'Democratic',
          true, false, false, true, -4120036)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41036' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-37 (41037): Jules Walters (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jules Walters', 'Jules', 'Walters', 'Democratic',
          true, false, false, true, -4120037)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41037' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-38 (41038): Daniel Nguyến (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniel Nguyến', 'Daniel', 'Nguyến', 'Democratic',
          true, false, false, true, -4120038)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41038' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-39 (41039): April Dobson (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'April Dobson', 'April', 'Dobson', 'Democratic',
          true, false, false, true, -4120039)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41039' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-40 (41040): Annessa Hartman (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Annessa Hartman', 'Annessa', 'Hartman', 'Democratic',
          true, false, false, true, -4120040)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41040' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-41 (41041): Mark Gamba (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Gamba', 'Mark', 'Gamba', 'Democratic',
          true, false, false, true, -4120041)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41041' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-42 (41042): Rob Nosse (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rob Nosse', 'Rob', 'Nosse', 'Democratic',
          true, false, false, true, -4120042)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41042' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-43 (41043): Tawna D. Sanchez (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tawna D. Sanchez', 'Tawna', 'Sanchez', 'Democratic',
          true, false, false, true, -4120043)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41043' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-44 (41044): Travis Nelson (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Travis Nelson', 'Travis', 'Nelson', 'Democratic',
          true, false, false, true, -4120044)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41044' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-45 (41045): Thủy Trần (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thủy Trần', 'Thủy', 'Trần', 'Democratic',
          true, false, false, true, -4120045)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41045' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-46 (41046): Willy Chotzen (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Willy Chotzen', 'Willy', 'Chotzen', 'Democratic',
          true, false, false, true, -4120046)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41046' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-47 (41047): Andrea Valderrama (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andrea Valderrama', 'Andrea', 'Valderrama', 'Democratic',
          true, false, false, true, -4120047)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41047' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-48 (41048): Lamar Wise (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lamar Wise', 'Lamar', 'Wise', 'Democratic',
          true, false, false, true, -4120048)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41048' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-49 (41049): Zach Hudson (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Zach Hudson', 'Zach', 'Hudson', 'Democratic',
          true, false, false, true, -4120049)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41049' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-50 (41050): Ricki Ruiz (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ricki Ruiz', 'Ricki', 'Ruiz', 'Democratic',
          true, false, false, true, -4120050)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41050' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-51 (41051): Matt Bunch (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Bunch', 'Matt', 'Bunch', 'Republican',
          true, false, false, true, -4120051)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41051' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-52 (41052): Jeff Helfrich (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeff Helfrich', 'Jeff', 'Helfrich', 'Republican',
          true, false, false, true, -4120052)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41052' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-53 (41053): Emerson Levy (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Emerson Levy', 'Emerson', 'Levy', 'Democratic',
          true, false, false, true, -4120053)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41053' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-54 (41054): Jason Kropf (Democratic) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jason Kropf', 'Jason', 'Kropf', 'Democratic',
          true, false, false, true, -4120054)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41054' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-55 (41055): E. Werner Reschke (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'E. Werner Reschke', 'E. Werner', 'Reschke', 'Republican',
          true, false, false, true, -4120055)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41055' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-56 (41056): Emily McIntire (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Emily McIntire', 'Emily', 'McIntire', 'Republican',
          true, false, false, true, -4120056)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41056' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-57 (41057): Gregory Smith (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gregory Smith', 'Gregory', 'Smith', 'Republican',
          true, false, false, true, -4120057)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41057' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-58 (41058): Bobby Levy (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bobby Levy', 'Bobby', 'Levy', 'Republican',
          true, false, false, true, -4120058)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41058' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-59 (41059): Vikki Breese-Iverson (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vikki Breese-Iverson', 'Vikki', 'Breese-Iverson', 'Republican',
          true, false, false, true, -4120059)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41059' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== HD-60 (41060): Mark Owens (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Owens', 'Mark', 'Owens', 'Republican',
          true, false, false, true, -4120060)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41060' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

-- ===== office_id back-fill =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4120060 AND -4120001
  AND p.office_id IS NULL;

COMMIT;
