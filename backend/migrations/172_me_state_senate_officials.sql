-- Migration 172: Maine State Senate Officials (132nd Legislature)
-- 35 senators, all districts filled, no vacancies.
--
-- Uses existing Maine Senate chamber from Phase 50 migration 168 (no chamber INSERT).
-- Uses existing STATE_UPPER districts from Phase 49 TIGER load (no district INSERT).
-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians; WHERE NOT EXISTS on offices.
--
BEGIN;

-- ===== District 1 (23001): Susan Bernard (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Susan Bernard', 'Susan', 'Bernard', 'Republican',
          true, false, false, true, -231001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23001' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 2 (23002): Trey L. Stewart (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Trey L. Stewart', 'Trey', 'Stewart', 'Republican',
          true, false, false, true, -231002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23002' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 3 (23003): Bradlee T. Farrin (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bradlee T. Farrin', 'Bradlee', 'Farrin', 'Republican',
          true, false, false, true, -231003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23003' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 4 (23004): Stacey K. Guerin (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stacey K. Guerin', 'Stacey', 'Guerin', 'Republican',
          true, false, false, true, -231004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23004' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 5 (23005): Russell J. Black (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Russell J. Black', 'Russell', 'Black', 'Republican',
          true, false, false, true, -231005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23005' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 6 (23006): Marianne Moore (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marianne Moore', 'Marianne', 'Moore', 'Republican',
          true, false, false, true, -231006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23006' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 7 (23007): Nicole C. Grohoski (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nicole C. Grohoski', 'Nicole', 'Grohoski', 'Democrat',
          true, false, false, true, -231007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23007' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 8 (23008): Mike Tipping (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Tipping', 'Mike', 'Tipping', 'Democrat',
          true, false, false, true, -231008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23008' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 9 (23009): Joseph M. Baldacci (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joseph M. Baldacci', 'Joseph', 'Baldacci', 'Democrat',
          true, false, false, true, -231009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23009' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 10 (23010): David Haggan (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Haggan', 'David', 'Haggan', 'Republican',
          true, false, false, true, -231010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23010' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 11 (23011): Chip Curry (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chip Curry', 'Chip', 'Curry', 'Democrat',
          true, false, false, true, -231011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23011' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 12 (23012): Pinny H. Beebe-Center (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pinny H. Beebe-Center', 'Pinny', 'Beebe-Center', 'Democrat',
          true, false, false, true, -231012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23012' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 13 (23013): Cameron D. Reny (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cameron D. Reny', 'Cameron', 'Reny', 'Democrat',
          true, false, false, true, -231013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23013' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 14 (23014): Craig V. Hickman (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Craig V. Hickman', 'Craig', 'Hickman', 'Democrat',
          true, false, false, true, -231014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23014' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 15 (23015): Richard Bradstreet (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Bradstreet', 'Richard', 'Bradstreet', 'Republican',
          true, false, false, true, -231015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23015' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 16 (23016): Scott Cyrway (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Scott Cyrway', 'Scott', 'Cyrway', 'Republican',
          true, false, false, true, -231016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23016' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 17 (23017): Jeffrey L. Timberlake (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeffrey L. Timberlake', 'Jeffrey', 'Timberlake', 'Republican',
          true, false, false, true, -231017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23017' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 18 (23018): Richard A. Bennett (Independent) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard A. Bennett', 'Richard', 'Bennett', 'Independent',
          true, false, false, true, -231018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23018' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 19 (23019): Joseph Martin (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joseph Martin', 'Joseph', 'Martin', 'Republican',
          true, false, false, true, -231019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23019' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 20 (23020): Bruce Bickford (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bruce Bickford', 'Bruce', 'Bickford', 'Republican',
          true, false, false, true, -231020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23020' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 21 (23021): Peggy R. Rotundo (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Peggy R. Rotundo', 'Peggy', 'Rotundo', 'Democrat',
          true, false, false, true, -231021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23021' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 22 (23022): James D. Libby (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James D. Libby', 'James', 'Libby', 'Republican',
          true, false, false, true, -231022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23022' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 23 (23023): Matthea E. L. Daughtry (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matthea E. L. Daughtry', 'Matthea', 'Daughtry', 'Democrat',
          true, false, false, true, -231023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23023' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 24 (23024): Denise Tepler (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Denise Tepler', 'Denise', 'Tepler', 'Democrat',
          true, false, false, true, -231024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23024' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 25 (23025): Teresa S. Pierce (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Teresa S. Pierce', 'Teresa', 'Pierce', 'Democrat',
          true, false, false, true, -231025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23025' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 26 (23026): Timothy E. Nangle (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Timothy E. Nangle', 'Timothy', 'Nangle', 'Democrat',
          true, false, false, true, -231026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23026' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 27 (23027): Jill C. Duson (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jill C. Duson', 'Jill', 'Duson', 'Democrat',
          true, false, false, true, -231027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23027' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 28 (23028): Rachel Talbot Ross (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rachel Talbot Ross', 'Rachel', 'Talbot Ross', 'Democrat',
          true, false, false, true, -231028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23028' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 29 (23029): Anne M. Carney (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anne M. Carney', 'Anne', 'Carney', 'Democrat',
          true, false, false, true, -231029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23029' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 30 (23030): Stacy F. Brenner (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stacy F. Brenner', 'Stacy', 'Brenner', 'Democrat',
          true, false, false, true, -231030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23030' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 31 (23031): Donna Bailey (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Donna Bailey', 'Donna', 'Bailey', 'Democrat',
          true, false, false, true, -231031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23031' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 32 (23032): Henry L. Ingwersen (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Henry L. Ingwersen', 'Henry', 'Ingwersen', 'Democrat',
          true, false, false, true, -231032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23032' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 33 (23033): Matt A. Harrington (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt A. Harrington', 'Matt', 'Harrington', 'Republican',
          true, false, false, true, -231033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23033' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 34 (23034): Joseph Rafferty (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joseph Rafferty', 'Joseph', 'Rafferty', 'Democrat',
          true, false, false, true, -231034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23034' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== District 35 (23035): Mark W. Lawrence (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark W. Lawrence', 'Mark', 'Lawrence', 'Democrat',
          true, false, false, true, -231035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23035' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine Senate')
  );

-- ===== office_id back-fill =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -231035 AND -231001
  AND p.office_id IS NULL;

COMMIT;
