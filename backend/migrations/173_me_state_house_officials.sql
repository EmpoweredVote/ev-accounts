-- Migration 173: Maine House of Representatives (132nd Legislature)
-- 150 named representatives + 1 vacant office (District 29 Javner deceased)
-- NOTE: District 94 (Cloutier resigned) was filled by Scott Harriman (D) via special election 2026.
--
-- Uses existing Maine House of Representatives chamber from Phase 50 migration 168 (no chamber INSERT).
-- Uses existing STATE_LOWER districts from Phase 49 TIGER load (no district INSERT).
-- Tribal representatives (Aaron Dana, Brian Reynolds) NOT seeded -- no STATE_LOWER district geofence.
-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians; WHERE NOT EXISTS on offices.
--
BEGIN;

-- ===== District 1 (23001): Lucien Daigle (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lucien Daigle', 'Lucien', 'Daigle', 'Republican',
          true, false, false, true, -232001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23001' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 2 (23002): Roger Albert (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roger Albert', 'Roger', 'Albert', 'Republican',
          true, false, false, true, -232002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23002' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 3 (23003): Mark Babin (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Babin', 'Mark', 'Babin', 'Republican',
          true, false, false, true, -232003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23003' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 4 (23004): Timothy Guerrette (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Timothy Guerrette', 'Timothy', 'Guerrette', 'Republican',
          true, false, false, true, -232004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23004' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 5 (23005): Joseph Underwood (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joseph Underwood', 'Joseph', 'Underwood', 'Republican',
          true, false, false, true, -232005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23005' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 6 (23006): Donald Ardell (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Donald Ardell', 'Donald', 'Ardell', 'Republican',
          true, false, false, true, -232006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23006' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 7 (23007): Gregory Swallow (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gregory Swallow', 'Gregory', 'Swallow', 'Republican',
          true, false, false, true, -232007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23007' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 8 (23008): Tracy Quint (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tracy Quint', 'Tracy', 'Quint', 'Republican',
          true, false, false, true, -232008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23008' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 9 (23009): Arthur Mingo (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Arthur Mingo', 'Arthur', 'Mingo', 'Republican',
          true, false, false, true, -232009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23009' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 10 (23010): William Tuell (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'William Tuell', 'William', 'Tuell', 'Republican',
          true, false, false, true, -232010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23010' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 11 (23011): Tiffany Strout (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tiffany Strout', 'Tiffany', 'Strout', 'Republican',
          true, false, false, true, -232011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23011' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 12 (23012): Billy Bob Faulkingham (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Billy Bob Faulkingham', 'Billy Bob', 'Faulkingham', 'Republican',
          true, false, false, true, -232012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23012' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 13 (23013): Russell White (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Russell White', 'Russell', 'White', 'Republican',
          true, false, false, true, -232013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23013' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 14 (23014): Gary Friedmann (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gary Friedmann', 'Gary', 'Friedmann', 'Democrat',
          true, false, false, true, -232014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23014' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 15 (23015): Holly Eaton (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Holly Eaton', 'Holly', 'Eaton', 'Democrat',
          true, false, false, true, -232015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23015' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 16 (23016): Nina Milliken (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nina Milliken', 'Nina', 'Milliken', 'Democrat',
          true, false, false, true, -232016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23016' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 17 (23017): Steven Bishop (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steven Bishop', 'Steven', 'Bishop', 'Republican',
          true, false, false, true, -232017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23017' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 18 (23018): Mathew McIntyre (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mathew McIntyre', 'Mathew', 'McIntyre', 'Republican',
          true, false, false, true, -232018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23018' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 19 (23019): Richard Campbell (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Campbell', 'Richard', 'Campbell', 'Republican',
          true, false, false, true, -232019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23019' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 20 (23020): Dani O'Halloran (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dani O''Halloran', 'Dani', 'O''Halloran', 'Democrat',
          true, false, false, true, -232020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23020' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 21 (23021): Ambureen Rana (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ambureen Rana', 'Ambureen', 'Rana', 'Democrat',
          true, false, false, true, -232021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23021' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 22 (23022): Laura Supica (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Laura Supica', 'Laura', 'Supica', 'Democrat',
          true, false, false, true, -232022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23022' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 23 (23023): Amy Roeder (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Amy Roeder', 'Amy', 'Roeder', 'Democrat',
          true, false, false, true, -232023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23023' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 24 (23024): Sean Faircloth (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sean Faircloth', 'Sean', 'Faircloth', 'Democrat',
          true, false, false, true, -232024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23024' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 25 (23025): Laurie Osher (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Laurie Osher', 'Laurie', 'Osher', 'Democrat',
          true, false, false, true, -232025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23025' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 26 (23026): James Dill (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Dill', 'James', 'Dill', 'Democrat',
          true, false, false, true, -232026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23026' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 27 (23027): Gary Drinkwater (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gary Drinkwater', 'Gary', 'Drinkwater', 'Republican',
          true, false, false, true, -232027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23027' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 28 (23028): Irene Gifford (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Irene Gifford', 'Irene', 'Gifford', 'Republican',
          true, false, false, true, -232028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23028' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 29 (23029): VACANT (Kathy Javner (R) deceased, no special election as of 2026-05-19) =====
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       NULL,
       'Representative', 'ME', false, true
FROM essentials.districts d
WHERE d.geo_id = '23029' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 30 (23030): James White (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James White', 'James', 'White', 'Republican',
          true, false, false, true, -232030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23030' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 31 (23031): Chad Perkins (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chad Perkins', 'Chad', 'Perkins', 'Republican',
          true, false, false, true, -232031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23031' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 32 (23032): Steven Foster (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steven Foster', 'Steven', 'Foster', 'Republican',
          true, false, false, true, -232032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23032' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 33 (23033): Kenneth Fredette (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kenneth Fredette', 'Kenneth', 'Fredette', 'Republican',
          true, false, false, true, -232033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23033' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 34 (23034): Abigail Griffin (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Abigail Griffin', 'Abigail', 'Griffin', 'Republican',
          true, false, false, true, -232034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23034' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 35 (23035): James Thorne (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Thorne', 'James', 'Thorne', 'Republican',
          true, false, false, true, -232035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23035' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 36 (23036): Kimberly Haggan (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kimberly Haggan', 'Kimberly', 'Haggan', 'Republican',
          true, false, false, true, -232036)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23036' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 37 (23037): Reagan Paul (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Reagan Paul', 'Reagan', 'Paul', 'Republican',
          true, false, false, true, -232037)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23037' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 38 (23038): Benjamin Hymes (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Benjamin Hymes', 'Benjamin', 'Hymes', 'Republican',
          true, false, false, true, -232038)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23038' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 39 (23039): Janice Dodge (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janice Dodge', 'Janice', 'Dodge', 'Democrat',
          true, false, false, true, -232039)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23039' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 40 (23040): D. Michael Ray (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'D. Michael Ray', 'D. Michael', 'Ray', 'Democrat',
          true, false, false, true, -232040)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23040' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 41 (23041): Victoria Doudera (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Victoria Doudera', 'Victoria', 'Doudera', 'Democrat',
          true, false, false, true, -232041)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23041' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 42 (23042): Valli Geiger (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Valli Geiger', 'Valli', 'Geiger', 'Democrat',
          true, false, false, true, -232042)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23042' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 43 (23043): Ann Matlack (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ann Matlack', 'Ann', 'Matlack', 'Democrat',
          true, false, false, true, -232043)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23043' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 44 (23044): William Pluecker (Independent) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'William Pluecker', 'William', 'Pluecker', 'Independent',
          true, false, false, true, -232044)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23044' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 45 (23045): Abden Simmons (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Abden Simmons', 'Abden', 'Simmons', 'Republican',
          true, false, false, true, -232045)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23045' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 46 (23046): Lydia Crafts (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lydia Crafts', 'Lydia', 'Crafts', 'Democrat',
          true, false, false, true, -232046)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23046' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 47 (23047): Wayne Farrin (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wayne Farrin', 'Wayne', 'Farrin', 'Democrat',
          true, false, false, true, -232047)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23047' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 48 (23048): Holly Stover (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Holly Stover', 'Holly', 'Stover', 'Democrat',
          true, false, false, true, -232048)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23048' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 49 (23049): Allison Hepler (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Allison Hepler', 'Allison', 'Hepler', 'Democrat',
          true, false, false, true, -232049)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23049' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 50 (23050): David Sinclair (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Sinclair', 'David', 'Sinclair', 'Democrat',
          true, false, false, true, -232050)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23050' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 51 (23051): Rafael Macias (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rafael Macias', 'Rafael', 'Macias', 'Democrat',
          true, false, false, true, -232051)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23051' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 52 (23052): Sally Cluchey (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sally Cluchey', 'Sally', 'Cluchey', 'Democrat',
          true, false, false, true, -232052)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23052' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 53 (23053): Michael Lemelin (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Lemelin', 'Michael', 'Lemelin', 'Republican',
          true, false, false, true, -232053)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23053' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 54 (23054): Karen Montell (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karen Montell', 'Karen', 'Montell', 'Democrat',
          true, false, false, true, -232054)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23054' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 55 (23055): Daniel Shagoury (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniel Shagoury', 'Daniel', 'Shagoury', 'Democrat',
          true, false, false, true, -232055)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23055' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 56 (23056): Randall Greenwood (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Randall Greenwood', 'Randall', 'Greenwood', 'Republican',
          true, false, false, true, -232056)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23056' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 57 (23057): Tavis Hasenfus (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tavis Hasenfus', 'Tavis', 'Hasenfus', 'Democrat',
          true, false, false, true, -232057)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23057' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 58 (23058): Sharon Frost (Unenrolled) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sharon Frost', 'Sharon', 'Frost', 'Unenrolled',
          true, false, false, true, -232058)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23058' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 59 (23059): David Rollins (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Rollins', 'David', 'Rollins', 'Democrat',
          true, false, false, true, -232059)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23059' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 60 (23060): William Bridgeo (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'William Bridgeo', 'William', 'Bridgeo', 'Democrat',
          true, false, false, true, -232060)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23060' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 61 (23061): Alicia Collins (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alicia Collins', 'Alicia', 'Collins', 'Republican',
          true, false, false, true, -232061)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23061' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 62 (23062): Katrina Smith (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Katrina Smith', 'Katrina', 'Smith', 'Republican',
          true, false, false, true, -232062)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23062' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 63 (23063): Paul Flynn (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Flynn', 'Paul', 'Flynn', 'Republican',
          true, false, false, true, -232063)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23063' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 64 (23064): Flavia DeBrito (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Flavia DeBrito', 'Flavia', 'DeBrito', 'Democrat',
          true, false, false, true, -232064)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23064' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 65 (23065): Cassie Julia (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cassie Julia', 'Cassie', 'Julia', 'Democrat',
          true, false, false, true, -232065)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23065' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 66 (23066): Robert Nutting (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Robert Nutting', 'Robert', 'Nutting', 'Republican',
          true, false, false, true, -232066)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23066' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 67 (23067): Shelley Rudnicki (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shelley Rudnicki', 'Shelley', 'Rudnicki', 'Republican',
          true, false, false, true, -232067)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23067' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 68 (23068): Amanda Collamore (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Amanda Collamore', 'Amanda', 'Collamore', 'Republican',
          true, false, false, true, -232068)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23068' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 69 (23069): Dean Cray (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dean Cray', 'Dean', 'Cray', 'Republican',
          true, false, false, true, -232069)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23069' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 70 (23070): Jennifer Poirier (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jennifer Poirier', 'Jennifer', 'Poirier', 'Republican',
          true, false, false, true, -232070)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23070' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 71 (23071): John Ducharme (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Ducharme', 'John', 'Ducharme', 'Republican',
          true, false, false, true, -232071)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23071' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 72 (23072): Elizabeth Caruso (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth Caruso', 'Elizabeth', 'Caruso', 'Republican',
          true, false, false, true, -232072)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23072' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 73 (23073): Michael Soboleski (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Soboleski', 'Michael', 'Soboleski', 'Republican',
          true, false, false, true, -232073)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23073' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 74 (23074): Randall Hall (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Randall Hall', 'Randall', 'Hall', 'Republican',
          true, false, false, true, -232074)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23074' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 75 (23075): Stephan Bunker (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephan Bunker', 'Stephan', 'Bunker', 'Democrat',
          true, false, false, true, -232075)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23075' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 76 (23076): Sheila Lyman (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sheila Lyman', 'Sheila', 'Lyman', 'Republican',
          true, false, false, true, -232076)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23076' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 77 (23077): Tammy Schmersal-Burgess (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tammy Schmersal-Burgess', 'Tammy', 'Schmersal-Burgess', 'Republican',
          true, false, false, true, -232077)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23077' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 78 (23078): Rachel Henderson (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rachel Henderson', 'Rachel', 'Henderson', 'Republican',
          true, false, false, true, -232078)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23078' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 79 (23079): Michael Lance (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Lance', 'Michael', 'Lance', 'Republican',
          true, false, false, true, -232079)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23079' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 80 (23080): Caldwell Jackson (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Caldwell Jackson', 'Caldwell', 'Jackson', 'Republican',
          true, false, false, true, -232080)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23080' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 81 (23081): Peter Wood (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Peter Wood', 'Peter', 'Wood', 'Republican',
          true, false, false, true, -232081)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23081' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 82 (23082): Nathan Wadsworth (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nathan Wadsworth', 'Nathan', 'Wadsworth', 'Republican',
          true, false, false, true, -232082)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23082' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 83 (23083): Marygrace Cimino (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marygrace Cimino', 'Marygrace', 'Cimino', 'Republican',
          true, false, false, true, -232083)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23083' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 84 (23084): Mark Walker (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Walker', 'Mark', 'Walker', 'Republican',
          true, false, false, true, -232084)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23084' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 85 (23085): Kimberly Pomerleau (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kimberly Pomerleau', 'Kimberly', 'Pomerleau', 'Republican',
          true, false, false, true, -232085)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23085' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 86 (23086): Rolf Olsen (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rolf Olsen', 'Rolf', 'Olsen', 'Republican',
          true, false, false, true, -232086)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23086' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 87 (23087): David Boyer (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Boyer', 'David', 'Boyer', 'Republican',
          true, false, false, true, -232087)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23087' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 88 (23088): Quentin Chapman (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Quentin Chapman', 'Quentin', 'Chapman', 'Republican',
          true, false, false, true, -232088)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23088' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 89 (23089): Adam Lee (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Adam Lee', 'Adam', 'Lee', 'Democrat',
          true, false, false, true, -232089)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23089' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 90 (23090): Laurel Libby (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Laurel Libby', 'Laurel', 'Libby', 'Republican',
          true, false, false, true, -232090)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23090' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 91 (23091): Joshua Morris (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joshua Morris', 'Joshua', 'Morris', 'Republican',
          true, false, false, true, -232091)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23091' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 92 (23092): Stephen Wood (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephen Wood', 'Stephen', 'Wood', 'Republican',
          true, false, false, true, -232092)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23092' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 93 (23093): Julia McCabe (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julia McCabe', 'Julia', 'McCabe', 'Democrat',
          true, false, false, true, -232093)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23093' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 94 (23094): Scott Harriman (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Scott Harriman', 'Scott', 'Harriman', 'Democrat',
          true, false, false, true, -232094)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23094' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 95 (23095): Mana Abdi (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mana Abdi', 'Mana', 'Abdi', 'Democrat',
          true, false, false, true, -232095)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23095' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 96 (23096): Michel Lajoie (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michel Lajoie', 'Michel', 'Lajoie', 'Democrat',
          true, false, false, true, -232096)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23096' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 97 (23097): Richard Mason (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Mason', 'Richard', 'Mason', 'Republican',
          true, false, false, true, -232097)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23097' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 98 (23098): Kilton Webb (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kilton Webb', 'Kilton', 'Webb', 'Democrat',
          true, false, false, true, -232098)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23098' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 99 (23099): Cheryl Golek (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cheryl Golek', 'Cheryl', 'Golek', 'Democrat',
          true, false, false, true, -232099)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23099' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 100 (23100): Daniel Ankeles (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniel Ankeles', 'Daniel', 'Ankeles', 'Democrat',
          true, false, false, true, -232100)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23100' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 101 (23101): Poppy Arford (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Poppy Arford', 'Poppy', 'Arford', 'Democrat',
          true, false, false, true, -232101)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23101' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 102 (23102): Melanie Sachs (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Melanie Sachs', 'Melanie', 'Sachs', 'Democrat',
          true, false, false, true, -232102)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23102' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 103 (23103): Arthur Bell (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Arthur Bell', 'Arthur', 'Bell', 'Democrat',
          true, false, false, true, -232103)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23103' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 104 (23104): Amy Arata (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Amy Arata', 'Amy', 'Arata', 'Republican',
          true, false, false, true, -232104)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23104' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 105 (23105): Anne Graham (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anne Graham', 'Anne', 'Graham', 'Democrat',
          true, false, false, true, -232105)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23105' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 106 (23106): Barbara Bagshaw (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Barbara Bagshaw', 'Barbara', 'Bagshaw', 'Republican',
          true, false, false, true, -232106)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23106' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 107 (23107): Mark Cooper (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Cooper', 'Mark', 'Cooper', 'Republican',
          true, false, false, true, -232107)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23107' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 108 (23108): Parnell Terry (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Parnell Terry', 'Parnell', 'Terry', 'Democrat',
          true, false, false, true, -232108)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23108' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 109 (23109): Eleanor Sato (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eleanor Sato', 'Eleanor', 'Sato', 'Democrat',
          true, false, false, true, -232109)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23109' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 110 (23110): Christina Mitchell (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christina Mitchell', 'Christina', 'Mitchell', 'Democrat',
          true, false, false, true, -232110)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23110' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 111 (23111): Amy Kuhn (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Amy Kuhn', 'Amy', 'Kuhn', 'Democrat',
          true, false, false, true, -232111)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23111' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 112 (23112): W. Edward Crockett (Unenrolled) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'W. Edward Crockett', 'W. Edward', 'Crockett', 'Unenrolled',
          true, false, false, true, -232112)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23112' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 113 (23113): Grayson Lookner (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Grayson Lookner', 'Grayson', 'Lookner', 'Democrat',
          true, false, false, true, -232113)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23113' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 114 (23114): Dylan Pugh (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dylan Pugh', 'Dylan', 'Pugh', 'Democrat',
          true, false, false, true, -232114)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23114' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 115 (23115): Michael Brennan (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Brennan', 'Michael', 'Brennan', 'Democrat',
          true, false, false, true, -232115)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23115' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 116 (23116): Samuel Zager (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Samuel Zager', 'Samuel', 'Zager', 'Democrat',
          true, false, false, true, -232116)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23116' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 117 (23117): Matt Moonen (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Moonen', 'Matt', 'Moonen', 'Democrat',
          true, false, false, true, -232117)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23117' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 118 (23118): Yusuf Yusuf (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Yusuf Yusuf', 'Yusuf', 'Yusuf', 'Democrat',
          true, false, false, true, -232118)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23118' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 119 (23119): Charles Skold (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charles Skold', 'Charles', 'Skold', 'Democrat',
          true, false, false, true, -232119)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23119' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 120 (23120): Deqa Dhalac (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Deqa Dhalac', 'Deqa', 'Dhalac', 'Democrat',
          true, false, false, true, -232120)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23120' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 121 (23121): Christopher Kessler (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christopher Kessler', 'Christopher', 'Kessler', 'Democrat',
          true, false, false, true, -232121)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23121' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 122 (23122): Matthew Beck (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matthew Beck', 'Matthew', 'Beck', 'Democrat',
          true, false, false, true, -232122)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23122' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 123 (23123): Michelle Boyer (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michelle Boyer', 'Michelle', 'Boyer', 'Democrat',
          true, false, false, true, -232123)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23123' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 124 (23124): Sophia Warren (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sophia Warren', 'Sophia', 'Warren', 'Democrat',
          true, false, false, true, -232124)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23124' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 125 (23125): Kelly Murphy (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kelly Murphy', 'Kelly', 'Murphy', 'Democrat',
          true, false, false, true, -232125)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23125' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 126 (23126): Drew Gattine (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Drew Gattine', 'Drew', 'Gattine', 'Democrat',
          true, false, false, true, -232126)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23126' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 127 (23127): Morgan Rielly (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Morgan Rielly', 'Morgan', 'Rielly', 'Democrat',
          true, false, false, true, -232127)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23127' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 128 (23128): Suzanne Salisbury (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Suzanne Salisbury', 'Suzanne', 'Salisbury', 'Democrat',
          true, false, false, true, -232128)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23128' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 129 (23129): Marshall Archer (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marshall Archer', 'Marshall', 'Archer', 'Democrat',
          true, false, false, true, -232129)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23129' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 130 (23130): Lynn Copeland (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lynn Copeland', 'Lynn', 'Copeland', 'Democrat',
          true, false, false, true, -232130)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23130' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 131 (23131): Lori Gramlich (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lori Gramlich', 'Lori', 'Gramlich', 'Democrat',
          true, false, false, true, -232131)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23131' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 132 (23132): Ryan Fecteau (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ryan Fecteau', 'Ryan', 'Fecteau', 'Democrat',
          true, false, false, true, -232132)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23132' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 133 (23133): Marc Malon (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marc Malon', 'Marc', 'Malon', 'Democrat',
          true, false, false, true, -232133)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23133' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 134 (23134): Traci Gere (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Traci Gere', 'Traci', 'Gere', 'Democrat',
          true, false, false, true, -232134)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23134' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 135 (23135): Daniel Sayre (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniel Sayre', 'Daniel', 'Sayre', 'Democrat',
          true, false, false, true, -232135)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23135' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 136 (23136): John Eder (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Eder', 'John', 'Eder', 'Republican',
          true, false, false, true, -232136)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23136' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 137 (23137): Nathan Carlow (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nathan Carlow', 'Nathan', 'Carlow', 'Republican',
          true, false, false, true, -232137)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23137' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 138 (23138): Mark Blier (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Blier', 'Mark', 'Blier', 'Republican',
          true, false, false, true, -232138)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23138' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 139 (23139): David Woodsome (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Woodsome', 'David', 'Woodsome', 'Republican',
          true, false, false, true, -232139)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23139' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 140 (23140): Wayne Parry (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wayne Parry', 'Wayne', 'Parry', 'Republican',
          true, false, false, true, -232140)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23140' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 141 (23141): Lucas Lanigan (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lucas Lanigan', 'Lucas', 'Lanigan', 'Republican',
          true, false, false, true, -232141)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23141' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 142 (23142): Anne-Marie Mastraccio (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anne-Marie Mastraccio', 'Anne-Marie', 'Mastraccio', 'Democrat',
          true, false, false, true, -232142)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23142' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 143 (23143): Ann Fredericks (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ann Fredericks', 'Ann', 'Fredericks', 'Republican',
          true, false, false, true, -232143)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23143' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 144 (23144): Jeffrey Adams (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeffrey Adams', 'Jeffrey', 'Adams', 'Republican',
          true, false, false, true, -232144)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23144' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 145 (23145): Robert Foley (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Robert Foley', 'Robert', 'Foley', 'Republican',
          true, false, false, true, -232145)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23145' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 146 (23146): Walter Runte (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Walter Runte', 'Walter', 'Runte', 'Democrat',
          true, false, false, true, -232146)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23146' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 147 (23147): Holly Sargent (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Holly Sargent', 'Holly', 'Sargent', 'Democrat',
          true, false, false, true, -232147)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23147' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 148 (23148): Thomas Lavigne (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thomas Lavigne', 'Thomas', 'Lavigne', 'Republican',
          true, false, false, true, -232148)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23148' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 149 (23149): Tiffany Roberts (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tiffany Roberts', 'Tiffany', 'Roberts', 'Democrat',
          true, false, false, true, -232149)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23149' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 150 (23150): Michele Meyer (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michele Meyer', 'Michele', 'Meyer', 'Democrat',
          true, false, false, true, -232150)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23150' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== District 151 (23151): Kristi Mathieson (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kristi Mathieson', 'Kristi', 'Mathieson', 'Democrat',
          true, false, false, true, -232151)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '23151' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Maine House of Representatives')
  );

-- ===== office_id back-fill =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -232151 AND -232001
  AND p.office_id IS NULL;

COMMIT;
