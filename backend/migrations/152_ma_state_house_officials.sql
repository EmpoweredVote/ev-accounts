-- Migration 152: Massachusetts House of Representatives
-- 158 named representatives + 2 vacant offices (25042, 25075)

-- ===== 25001: Christopher R. Flanagan (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Christopher R. Flanagan', 'Christopher', 'Flanagan', 'Democrat',
          true, false, false, true, -210041,
          ARRAY['https://malegislature.gov/Legislators/Profile/CRF1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Barnstable District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25001' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25002: Kip A. Diggs (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kip A. Diggs', 'Kip', 'Diggs', 'Democrat',
          true, false, false, true, -210042,
          ARRAY['https://malegislature.gov/Legislators/Profile/KAD1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Barnstable District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25002' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25003: David T. Vieira (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'David T. Vieira', 'David', 'Vieira', 'Republican',
          true, false, false, true, -210043,
          ARRAY['https://malegislature.gov/Legislators/Profile/DTV1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Barnstable District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25003' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25004: Hadley Luddy (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Hadley Luddy', 'Hadley', 'Luddy', 'Democrat',
          true, false, false, true, -210044,
          ARRAY['https://malegislature.gov/Legislators/Profile/H_L1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 4th Barnstable District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25004' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25005: Steven G. Xiarhos (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Steven G. Xiarhos', 'Steven', 'Xiarhos', 'Republican',
          true, false, false, true, -210045,
          ARRAY['https://malegislature.gov/Legislators/Profile/SGX1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 5th Barnstable District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25005' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25006: Thomas W. Moakley (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Thomas W. Moakley', 'Thomas', 'Moakley', 'Democrat',
          true, false, false, true, -210046,
          ARRAY['https://malegislature.gov/Legislators/Profile/TWM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, Barnstable-Dukes-Nantucket District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25006' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25007: John Barrett (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John Barrett', 'John', 'Barrett', 'Democrat',
          true, false, false, true, -210047,
          ARRAY['https://malegislature.gov/Legislators/Profile/J_B1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Berkshire District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25007' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25008: Tricia Farley-Bouvier (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Tricia Farley-Bouvier', 'Tricia', 'Farley-Bouvier', 'Democrat',
          true, false, false, true, -210048,
          ARRAY['https://malegislature.gov/Legislators/Profile/TFB1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Berkshire District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25008' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25009: Leigh S. Davis (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Leigh S. Davis', 'Leigh', 'Davis', 'Democrat',
          true, false, false, true, -210049,
          ARRAY['https://malegislature.gov/Legislators/Profile/LSD1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Berkshire District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25009' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25010: Michael S. Chaisson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael S. Chaisson', 'Michael', 'Chaisson', 'Republican',
          true, false, false, true, -210050,
          ARRAY['https://malegislature.gov/Legislators/Profile/MSC1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25010' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25011: James K. Hawkins (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'James K. Hawkins', 'James', 'Hawkins', 'Democrat',
          true, false, false, true, -210051,
          ARRAY['https://malegislature.gov/Legislators/Profile/JKH1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25011' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25012: Lisa M. Field (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Lisa M. Field', 'Lisa', 'Field', 'Democrat',
          true, false, false, true, -210052,
          ARRAY['https://malegislature.gov/Legislators/Profile/LMF1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25012' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25013: Steven S. Howitt (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Steven S. Howitt', 'Steven', 'Howitt', 'Republican',
          true, false, false, true, -210053,
          ARRAY['https://malegislature.gov/Legislators/Profile/SSH1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 4th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25013' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25014: Justin Thurber (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Justin Thurber', 'Justin', 'Thurber', 'Republican',
          true, false, false, true, -210054,
          ARRAY['https://malegislature.gov/Legislators/Profile/J_T2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 5th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25014' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25015: Carole A. Fiola (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Carole A. Fiola', 'Carole', 'Fiola', 'Democrat',
          true, false, false, true, -210055,
          ARRAY['https://malegislature.gov/Legislators/Profile/CAF1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 6th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25015' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25016: Alan Silvia (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Alan Silvia', 'Alan', 'Silvia', 'Democrat',
          true, false, false, true, -210056,
          ARRAY['https://malegislature.gov/Legislators/Profile/A_S1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 7th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25016' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25017: Steven J. Ouellette (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Steven J. Ouellette', 'Steven', 'Ouellette', 'Democrat',
          true, false, false, true, -210057,
          ARRAY['https://malegislature.gov/Legislators/Profile/SJO1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 8th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25017' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25018: Christopher M. Markey (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Christopher M. Markey', 'Christopher', 'Markey', 'Democrat',
          true, false, false, true, -210058,
          ARRAY['https://malegislature.gov/Legislators/Profile/CMM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 9th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25018' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25019: Mark D. Sylvia (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Mark D. Sylvia', 'Mark', 'Sylvia', 'Democrat',
          true, false, false, true, -210059,
          ARRAY['https://malegislature.gov/Legislators/Profile/MDS1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 10th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25019' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25020: Christopher Hendricks (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Christopher Hendricks', 'Christopher', 'Hendricks', 'Democrat',
          true, false, false, true, -210060,
          ARRAY['https://malegislature.gov/Legislators/Profile/C_H1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 11th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25020' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25021: Norman J. Orrall (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Norman J. Orrall', 'Norman', 'Orrall', 'Republican',
          true, false, false, true, -210061,
          ARRAY['https://malegislature.gov/Legislators/Profile/NJO1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 12th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25021' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25022: Antonio F. Cabral (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Antonio F. Cabral', 'Antonio', 'Cabral', 'Democrat',
          true, false, false, true, -210062,
          ARRAY['https://malegislature.gov/Legislators/Profile/AFC1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 13th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25022' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25023: Adam J. Scanlon (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Adam J. Scanlon', 'Adam', 'Scanlon', 'Democrat',
          true, false, false, true, -210063,
          ARRAY['https://malegislature.gov/Legislators/Profile/AJS1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 14th Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25023' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25024: Dawne Shand (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Dawne Shand', 'Dawne', 'Shand', 'Democrat',
          true, false, false, true, -210064,
          ARRAY['https://malegislature.gov/Legislators/Profile/D_S1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25024' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25025: Kristin Kassner (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kristin Kassner', 'Kristin', 'Kassner', 'Democrat',
          true, false, false, true, -210065,
          ARRAY['https://malegislature.gov/Legislators/Profile/K_K2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25025' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25026: Andres X. Vargas (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Andres X. Vargas', 'Andres', 'Vargas', 'Democrat',
          true, false, false, true, -210066,
          ARRAY['https://malegislature.gov/Legislators/Profile/AXV1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25026' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25027: Estela A. Reyes (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Estela A. Reyes', 'Estela', 'Reyes', 'Democrat',
          true, false, false, true, -210067,
          ARRAY['https://malegislature.gov/Legislators/Profile/EAR1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 4th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25027' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25028: Andrew F. Tarr (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Andrew F. Tarr', 'Andrew', 'Tarr', 'Democrat',
          true, false, false, true, -210068,
          ARRAY['https://malegislature.gov/Legislators/Profile/AFT1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 5th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25028' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25029: Hannah L. Bowen (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Hannah L. Bowen', 'Hannah', 'Bowen', 'Democrat',
          true, false, false, true, -210069,
          ARRAY['https://malegislature.gov/Legislators/Profile/HLB1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 6th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25029' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25030: Manny Cruz (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Manny Cruz', 'Manny', 'Cruz', 'Democrat',
          true, false, false, true, -210070,
          ARRAY['https://malegislature.gov/Legislators/Profile/M_C3'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 7th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25030' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25031: Jennifer Balinsky Armini (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Jennifer Balinsky Armini', 'Jennifer', 'Armini', 'Democrat',
          true, false, false, true, -210071,
          ARRAY['https://malegislature.gov/Legislators/Profile/JBA1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 8th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25031' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25032: Donald H. Wong (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Donald H. Wong', 'Donald', 'Wong', 'Republican',
          true, false, false, true, -210072,
          ARRAY['https://malegislature.gov/Legislators/Profile/DHW1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 9th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25032' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25033: Daniel F. Cahill (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Daniel F. Cahill', 'Daniel', 'Cahill', 'Democrat',
          true, false, false, true, -210073,
          ARRAY['https://malegislature.gov/Legislators/Profile/DFC1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 10th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25033' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25034: Sean Reid (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Sean Reid', 'Sean', 'Reid', 'Democrat',
          true, false, false, true, -210074,
          ARRAY['https://malegislature.gov/Legislators/Profile/S_R1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 11th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25034' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25035: Thomas J. Walsh (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Thomas J. Walsh', 'Thomas', 'Walsh', 'Democrat',
          true, false, false, true, -210075,
          ARRAY['https://malegislature.gov/Legislators/Profile/TJW1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 12th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25035' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25036: Sally P. Kerans (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Sally P. Kerans', 'Sally', 'Kerans', 'Democrat',
          true, false, false, true, -210076,
          ARRAY['https://malegislature.gov/Legislators/Profile/SPK1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 13th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25036' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25037: Adrianne P. Ramos (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Adrianne P. Ramos', 'Adrianne', 'Ramos', 'Democrat',
          true, false, false, true, -210077,
          ARRAY['https://malegislature.gov/Legislators/Profile/APR1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 14th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25037' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25038: Ryan M. Hamilton (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Ryan M. Hamilton', 'Ryan', 'Hamilton', 'Democrat',
          true, false, false, true, -210078,
          ARRAY['https://malegislature.gov/Legislators/Profile/RMH2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 15th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25038' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25039: Francisco E. Paulino (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Francisco E. Paulino', 'Francisco', 'Paulino', 'Democrat',
          true, false, false, true, -210079,
          ARRAY['https://malegislature.gov/Legislators/Profile/FEP1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 16th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25039' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25040: Frank A. Moran (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Frank A. Moran', 'Frank', 'Moran', 'Democrat',
          true, false, false, true, -210080,
          ARRAY['https://malegislature.gov/Legislators/Profile/FAM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 17th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25040' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25041: Tram T. Nguyen (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Tram T. Nguyen', 'Tram', 'Nguyen', 'Democrat',
          true, false, false, true, -210081,
          ARRAY['https://malegislature.gov/Legislators/Profile/TTN1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 18th Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25041' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25042: VACANT =====
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       NULL,
       'Representative, 1st Franklin District', 'MA', false, true
FROM essentials.districts d
WHERE d.geo_id = '25042' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25043: Susannah L. Whipps (U) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Susannah L. Whipps', 'Susannah', 'Whipps', 'Unenrolled',
          true, false, false, true, -210082,
          ARRAY['https://malegislature.gov/Legislators/Profile/SLG1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Franklin District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25043' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25044: Todd M. Smola (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Todd M. Smola', 'Todd', 'Smola', 'Republican',
          true, false, false, true, -210083,
          ARRAY['https://malegislature.gov/Legislators/Profile/TMS2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25044' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25045: Brian M. Ashe (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Brian M. Ashe', 'Brian', 'Ashe', 'Democrat',
          true, false, false, true, -210084,
          ARRAY['https://malegislature.gov/Legislators/Profile/BMA1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25045' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25046: Nicholas A. Boldyga (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Nicholas A. Boldyga', 'Nicholas', 'Boldyga', 'Republican',
          true, false, false, true, -210085,
          ARRAY['https://malegislature.gov/Legislators/Profile/NAG1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25046' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25047: Kelly W. Pease (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kelly W. Pease', 'Kelly', 'Pease', 'Republican',
          true, false, false, true, -210086,
          ARRAY['https://malegislature.gov/Legislators/Profile/KWP1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 4th Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25047' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25048: Patricia A. Duffy (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Patricia A. Duffy', 'Patricia', 'Duffy', 'Democrat',
          true, false, false, true, -210087,
          ARRAY['https://malegislature.gov/Legislators/Profile/PAD1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 5th Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25048' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25049: Michael J. Finn (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael J. Finn', 'Michael', 'Finn', 'Democrat',
          true, false, false, true, -210088,
          ARRAY['https://malegislature.gov/Legislators/Profile/MJF1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 6th Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25049' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25050: Aaron L. Saunders (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Aaron L. Saunders', 'Aaron', 'Saunders', 'Democrat',
          true, false, false, true, -210089,
          ARRAY['https://malegislature.gov/Legislators/Profile/ALS1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 7th Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25050' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25051: Shirley A. Arriaga (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Shirley A. Arriaga', 'Shirley', 'Arriaga', 'Democrat',
          true, false, false, true, -210090,
          ARRAY['https://malegislature.gov/Legislators/Profile/SBA1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 8th Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25051' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25052: Orlando Ramos (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Orlando Ramos', 'Orlando', 'Ramos', 'Democrat',
          true, false, false, true, -210091,
          ARRAY['https://malegislature.gov/Legislators/Profile/O_R1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 9th Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25052' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25053: Carlos González (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Carlos González', 'Carlos', 'González', 'Democrat',
          true, false, false, true, -210092,
          ARRAY['https://malegislature.gov/Legislators/Profile/C_G1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 10th Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25053' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25054: Bud L. Williams (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Bud L. Williams', 'Bud', 'Williams', 'Democrat',
          true, false, false, true, -210093,
          ARRAY['https://malegislature.gov/Legislators/Profile/BLW1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 11th Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25054' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25055: Angelo J. Puppolo (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Angelo J. Puppolo', 'Angelo', 'Puppolo', 'Democrat',
          true, false, false, true, -210094,
          ARRAY['https://malegislature.gov/Legislators/Profile/AJP1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 12th Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25055' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25056: Lindsay Sabadosa (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Lindsay Sabadosa', 'Lindsay', 'Sabadosa', 'Democrat',
          true, false, false, true, -210095,
          ARRAY['https://malegislature.gov/Legislators/Profile/L_S1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Hampshire District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25056' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25057: Homar Gómez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Homar Gómez', 'Homar', 'Gómez', 'Democrat',
          true, false, false, true, -210096,
          ARRAY['https://malegislature.gov/Legislators/Profile/H_G1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Hampshire District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25057' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25058: Mindy Domb (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Mindy Domb', 'Mindy', 'Domb', 'Democrat',
          true, false, false, true, -210097,
          ARRAY['https://malegislature.gov/Legislators/Profile/M_D2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Hampshire District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25058' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25059: Margaret R. Scarsdale (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Margaret R. Scarsdale', 'Margaret', 'Scarsdale', 'Democrat',
          true, false, false, true, -210098,
          ARRAY['https://malegislature.gov/Legislators/Profile/MRS1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25059' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25060: James Arciero (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'James Arciero', 'James', 'Arciero', 'Democrat',
          true, false, false, true, -210099,
          ARRAY['https://malegislature.gov/Legislators/Profile/J_A1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25060' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25061: Kate Hogan (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kate Hogan', 'Kate', 'Hogan', 'Democrat',
          true, false, false, true, -210100,
          ARRAY['https://malegislature.gov/Legislators/Profile/K_H1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25061' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25062: Danielle W. Gregoire (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Danielle W. Gregoire', 'Danielle', 'Gregoire', 'Democrat',
          true, false, false, true, -210101,
          ARRAY['https://malegislature.gov/Legislators/Profile/DWG1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 4th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25062' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25063: David P. Linsky (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'David P. Linsky', 'David', 'Linsky', 'Democrat',
          true, false, false, true, -210102,
          ARRAY['https://malegislature.gov/Legislators/Profile/DPL1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 5th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25063' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25064: Priscila S. Sousa (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Priscila S. Sousa', 'Priscila', 'Sousa', 'Democrat',
          true, false, false, true, -210103,
          ARRAY['https://malegislature.gov/Legislators/Profile/PSS1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 6th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25064' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25065: Jack P. Lewis (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Jack P. Lewis', 'Jack', 'Lewis', 'Democrat',
          true, false, false, true, -210104,
          ARRAY['https://malegislature.gov/Legislators/Profile/JPL1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 7th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25065' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25066: James Arena-DeRosa (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'James Arena-DeRosa', 'James', 'Arena-DeRosa', 'Democrat',
          true, false, false, true, -210105,
          ARRAY['https://malegislature.gov/Legislators/Profile/JCD1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 8th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25066' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25067: Thomas M. Stanley (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Thomas M. Stanley', 'Thomas', 'Stanley', 'Democrat',
          true, false, false, true, -210106,
          ARRAY['https://malegislature.gov/Legislators/Profile/TMS1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 9th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25067' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25068: John J. Lawn (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John J. Lawn', 'John', 'Lawn', 'Democrat',
          true, false, false, true, -210107,
          ARRAY['https://malegislature.gov/Legislators/Profile/JJL2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 10th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25068' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25069: Amy M. Sangiolo (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Amy M. Sangiolo', 'Amy', 'Sangiolo', 'Democrat',
          true, false, false, true, -210108,
          ARRAY['https://malegislature.gov/Legislators/Profile/AMS3'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 11th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25069' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25070: Greg Schwartz (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Greg Schwartz', 'Greg', 'Schwartz', 'Democrat',
          true, false, false, true, -210109,
          ARRAY['https://malegislature.gov/Legislators/Profile/G_S1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 12th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25070' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25071: Carmine L. Gentile (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Carmine L. Gentile', 'Carmine', 'Gentile', 'Democrat',
          true, false, false, true, -210110,
          ARRAY['https://malegislature.gov/Legislators/Profile/CLG1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 13th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25071' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25072: Simon Cataldo (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Simon Cataldo', 'Simon', 'Cataldo', 'Democrat',
          true, false, false, true, -210111,
          ARRAY['https://malegislature.gov/Legislators/Profile/S_C1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 14th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25072' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25073: Michelle Ciccolo (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michelle Ciccolo', 'Michelle', 'Ciccolo', 'Democrat',
          true, false, false, true, -210112,
          ARRAY['https://malegislature.gov/Legislators/Profile/M_C2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 15th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25073' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25074: Rodney M. Elliott (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Rodney M. Elliott', 'Rodney', 'Elliott', 'Democrat',
          true, false, false, true, -210113,
          ARRAY['https://malegislature.gov/Legislators/Profile/RME1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 16th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25074' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25075: VACANT =====
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       NULL,
       'Representative, 17th Middlesex District', 'MA', false, true
FROM essentials.districts d
WHERE d.geo_id = '25075' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25076: Tara T. Hong (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Tara T. Hong', 'Tara', 'Hong', 'Democrat',
          true, false, false, true, -210114,
          ARRAY['https://malegislature.gov/Legislators/Profile/TTH1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 18th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25076' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25077: David Robertson (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'David Robertson', 'David', 'Robertson', 'Democrat',
          true, false, false, true, -210115,
          ARRAY['https://malegislature.gov/Legislators/Profile/D_R1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 19th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25077' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25078: Bradley H. Jones (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Bradley H. Jones', 'Bradley', 'Jones', 'Republican',
          true, false, false, true, -210116,
          ARRAY['https://malegislature.gov/Legislators/Profile/BHJ1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 20th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25078' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25079: Kenneth I. Gordon (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kenneth I. Gordon', 'Kenneth', 'Gordon', 'Democrat',
          true, false, false, true, -210117,
          ARRAY['https://malegislature.gov/Legislators/Profile/KIG1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 21st Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25079' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25080: Marc T. Lombardo (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Marc T. Lombardo', 'Marc', 'Lombardo', 'Republican',
          true, false, false, true, -210118,
          ARRAY['https://malegislature.gov/Legislators/Profile/MTL1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 22nd Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25080' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25081: Sean Garballey (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Sean Garballey', 'Sean', 'Garballey', 'Democrat',
          true, false, false, true, -210119,
          ARRAY['https://malegislature.gov/Legislators/Profile/S_G1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 23rd Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25081' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25082: David M. Rogers (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls,
     email_addresses)
  VALUES (gen_random_uuid(), 'David M. Rogers', 'David', 'Rogers', 'Democrat',
          true, false, false, true, -210120,
          ARRAY['https://malegislature.gov/Legislators/Profile/DMR1'],
          ARRAY['Dave.Rogers@mahouse.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 24th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25082' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25083: Marjorie C. Decker (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls,
     email_addresses)
  VALUES (gen_random_uuid(), 'Marjorie C. Decker', 'Marjorie', 'Decker', 'Democrat',
          true, false, false, true, -210121,
          ARRAY['https://malegislature.gov/Legislators/Profile/MCD1'],
          ARRAY['Marjorie.Decker@mahouse.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 25th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25083' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25084: Mike Connolly (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls,
     email_addresses)
  VALUES (gen_random_uuid(), 'Mike Connolly', 'Mike', 'Connolly', 'Democrat',
          true, false, false, true, -210122,
          ARRAY['https://malegislature.gov/Legislators/Profile/M_C1'],
          ARRAY['Mike.Connolly@mahouse.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 26th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25084' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25085: Erika Uyterhoeven (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Erika Uyterhoeven', 'Erika', 'Uyterhoeven', 'Democrat',
          true, false, false, true, -210123,
          ARRAY['https://malegislature.gov/Legislators/Profile/E_U1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 27th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25085' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25086: Joseph W. McGonagle (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Joseph W. McGonagle', 'Joseph', 'McGonagle', 'Democrat',
          true, false, false, true, -210124,
          ARRAY['https://malegislature.gov/Legislators/Profile/jwm1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 28th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25086' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25087: Steven C. Owens (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Steven C. Owens', 'Steven', 'Owens', 'Democrat',
          true, false, false, true, -210125,
          ARRAY['https://malegislature.gov/Legislators/Profile/SCO1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 29th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25087' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25088: Richard M. Haggerty (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Richard M. Haggerty', 'Richard', 'Haggerty', 'Democrat',
          true, false, false, true, -210126,
          ARRAY['https://malegislature.gov/Legislators/Profile/RMH1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 30th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25088' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25089: Michael S. Day (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael S. Day', 'Michael', 'Day', 'Democrat',
          true, false, false, true, -210127,
          ARRAY['https://malegislature.gov/Legislators/Profile/MSD1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 31st Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25089' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25090: Kate Lipper-Garabedian (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kate Lipper-Garabedian', 'Kate', 'Lipper-Garabedian', 'Democrat',
          true, false, false, true, -210128,
          ARRAY['https://malegislature.gov/Legislators/Profile/KLG1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 32nd Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25090' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25091: Steven Ultrino (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Steven Ultrino', 'Steven', 'Ultrino', 'Democrat',
          true, false, false, true, -210129,
          ARRAY['https://malegislature.gov/Legislators/Profile/S_G2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 33rd Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25091' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25092: Christine P. Barber (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Christine P. Barber', 'Christine', 'Barber', 'Democrat',
          true, false, false, true, -210130,
          ARRAY['https://malegislature.gov/Legislators/Profile/CPB2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 34th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25092' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25093: Paul J. Donato (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Paul J. Donato', 'Paul', 'Donato', 'Democrat',
          true, false, false, true, -210131,
          ARRAY['https://malegislature.gov/Legislators/Profile/PJD1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 35th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25093' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25094: Colleen M. Garry (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Colleen M. Garry', 'Colleen', 'Garry', 'Democrat',
          true, false, false, true, -210132,
          ARRAY['https://malegislature.gov/Legislators/Profile/CMG1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 36th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25094' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25095: Danillo Sena (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Danillo Sena', 'Danillo', 'Sena', 'Democrat',
          true, false, false, true, -210133,
          ARRAY['https://malegislature.gov/Legislators/Profile/DAS1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 37th Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25095' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25096: Bruce J. Ayers (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Bruce J. Ayers', 'Bruce', 'Ayers', 'Democrat',
          true, false, false, true, -210134,
          ARRAY['https://malegislature.gov/Legislators/Profile/BJA1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25096' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25097: Tackey Chan (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Tackey Chan', 'Tackey', 'Chan', 'Democrat',
          true, false, false, true, -210135,
          ARRAY['https://malegislature.gov/Legislators/Profile/T_C1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25097' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25098: Ronald Mariano (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Ronald Mariano', 'Ronald', 'Mariano', 'Democrat',
          true, false, false, true, -210136,
          ARRAY['https://malegislature.gov/Legislators/Profile/R_M1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25098' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25099: James M. Murphy (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'James M. Murphy', 'James', 'Murphy', 'Democrat',
          true, false, false, true, -210137,
          ARRAY['https://malegislature.gov/Legislators/Profile/JMM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 4th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25099' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25100: Mark J. Cusack (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Mark J. Cusack', 'Mark', 'Cusack', 'Democrat',
          true, false, false, true, -210138,
          ARRAY['https://malegislature.gov/Legislators/Profile/MJC1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 5th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25100' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25101: William C. Galvin (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'William C. Galvin', 'William', 'Galvin', 'Democrat',
          true, false, false, true, -210139,
          ARRAY['https://malegislature.gov/Legislators/Profile/WCG1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 6th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25101' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25102: Richard G. Wells (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Richard G. Wells', 'Richard', 'Wells', 'Democrat',
          true, false, false, true, -210140,
          ARRAY['https://malegislature.gov/Legislators/Profile/RGW1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 7th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25102' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25103: Edward R. Philips (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Edward R. Philips', 'Edward', 'Philips', 'Democrat',
          true, false, false, true, -210141,
          ARRAY['https://malegislature.gov/Legislators/Profile/ERP1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 8th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25103' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25104: Marcus S. Vaughn (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Marcus S. Vaughn', 'Marcus', 'Vaughn', 'Republican',
          true, false, false, true, -210142,
          ARRAY['https://malegislature.gov/Legislators/Profile/MSV1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 9th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25104' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25105: Jeffrey N. Roy (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Jeffrey N. Roy', 'Jeffrey', 'Roy', 'Democrat',
          true, false, false, true, -210143,
          ARRAY['https://malegislature.gov/Legislators/Profile/JNR1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 10th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25105' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25106: Paul McMurtry (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Paul McMurtry', 'Paul', 'McMurtry', 'Democrat',
          true, false, false, true, -210144,
          ARRAY['https://malegislature.gov/Legislators/Profile/P_M1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 11th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25106' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25107: John H. Rogers (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John H. Rogers', 'John', 'Rogers', 'Democrat',
          true, false, false, true, -210145,
          ARRAY['https://malegislature.gov/Legislators/Profile/JHR1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 12th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25107' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25108: Joshua Tarsky (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Joshua Tarsky', 'Joshua', 'Tarsky', 'Democrat',
          true, false, false, true, -210146,
          ARRAY['https://malegislature.gov/Legislators/Profile/J_T1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 13th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25108' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25109: Alice H. Peisch (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Alice H. Peisch', 'Alice', 'Peisch', 'Democrat',
          true, false, false, true, -210147,
          ARRAY['https://malegislature.gov/Legislators/Profile/AHP1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 14th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25109' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25110: Tommy Vitolo (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Tommy Vitolo', 'Tommy', 'Vitolo', 'Democrat',
          true, false, false, true, -210148,
          ARRAY['https://malegislature.gov/Legislators/Profile/T_V1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 15th Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25110' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25111: Michelle L. Badger (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michelle L. Badger', 'Michelle', 'Badger', 'Democrat',
          true, false, false, true, -210149,
          ARRAY['https://malegislature.gov/Legislators/Profile/MLB1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25111' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25112: John R. Gaskey (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John R. Gaskey', 'John', 'Gaskey', 'Republican',
          true, false, false, true, -210150,
          ARRAY['https://malegislature.gov/Legislators/Profile/JRG2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25112' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25113: Joan Meschino (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Joan Meschino', 'Joan', 'Meschino', 'Democrat',
          true, false, false, true, -210151,
          ARRAY['https://malegislature.gov/Legislators/Profile/J_M1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25113' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25114: Patrick J. Kearney (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Patrick J. Kearney', 'Patrick', 'Kearney', 'Democrat',
          true, false, false, true, -210152,
          ARRAY['https://malegislature.gov/Legislators/Profile/PJK1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 4th Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25114' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25115: David F. DeCoste (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'David F. DeCoste', 'David', 'DeCoste', 'Republican',
          true, false, false, true, -210153,
          ARRAY['https://malegislature.gov/Legislators/Profile/DFD1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 5th Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25115' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25116: Kenneth P. Sweezey (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kenneth P. Sweezey', 'Kenneth', 'Sweezey', 'Republican',
          true, false, false, true, -210154,
          ARRAY['https://malegislature.gov/Legislators/Profile/KPS1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 6th Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25116' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25117: Alyson Sullivan-Almeida (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Alyson Sullivan-Almeida', 'Alyson', 'Sullivan-Almeida', 'Republican',
          true, false, false, true, -210155,
          ARRAY['https://malegislature.gov/Legislators/Profile/AMS2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 7th Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25117' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25118: Dennis C. Gallagher (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Dennis C. Gallagher', 'Dennis', 'Gallagher', 'Democrat',
          true, false, false, true, -210156,
          ARRAY['https://malegislature.gov/Legislators/Profile/DCG2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 8th Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25118' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25119: Bridget M. Plouffe (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Bridget M. Plouffe', 'Bridget', 'Plouffe', 'Democrat',
          true, false, false, true, -210157,
          ARRAY['https://malegislature.gov/Legislators/Profile/BMP1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 9th Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25119' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25120: Michelle M. DuBois (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michelle M. DuBois', 'Michelle', 'DuBois', 'Democrat',
          true, false, false, true, -210158,
          ARRAY['https://malegislature.gov/Legislators/Profile/MMD1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 10th Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25120' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25121: Rita A. Mendes (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Rita A. Mendes', 'Rita', 'Mendes', 'Democrat',
          true, false, false, true, -210159,
          ARRAY['https://malegislature.gov/Legislators/Profile/RAM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 11th Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25121' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25122: Kathleen P. LaNatra (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kathleen P. LaNatra', 'Kathleen', 'LaNatra', 'Democrat',
          true, false, false, true, -210160,
          ARRAY['https://malegislature.gov/Legislators/Profile/KPL1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 12th Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25122' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25123: Adrian C. Madaro (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Adrian C. Madaro', 'Adrian', 'Madaro', 'Democrat',
          true, false, false, true, -210161,
          ARRAY['https://malegislature.gov/Legislators/Profile/ACM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25123' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25124: Daniel J. Ryan (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Daniel J. Ryan', 'Daniel', 'Ryan', 'Democrat',
          true, false, false, true, -210162,
          ARRAY['https://malegislature.gov/Legislators/Profile/djr1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25124' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25125: Aaron Michlewitz (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Aaron Michlewitz', 'Aaron', 'Michlewitz', 'Democrat',
          true, false, false, true, -210163,
          ARRAY['https://malegislature.gov/Legislators/Profile/AMM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25125' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25126: David Biele (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'David Biele', 'David', 'Biele', 'Democrat',
          true, false, false, true, -210164,
          ARRAY['https://malegislature.gov/Legislators/Profile/D_B1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 4th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25126' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25127: Christopher J. Worrell (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Christopher J. Worrell', 'Christopher', 'Worrell', 'Democrat',
          true, false, false, true, -210165,
          ARRAY['https://malegislature.gov/Legislators/Profile/CJW1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 5th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25127' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25128: Russell E. Holmes (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Russell E. Holmes', 'Russell', 'Holmes', 'Democrat',
          true, false, false, true, -210166,
          ARRAY['https://malegislature.gov/Legislators/Profile/REH1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 6th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25128' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25129: Chynah Tyler (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Chynah Tyler', 'Chynah', 'Tyler', 'Democrat',
          true, false, false, true, -210167,
          ARRAY['https://malegislature.gov/Legislators/Profile/C_T1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 7th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25129' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25130: Jay Livingstone (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Jay Livingstone', 'Jay', 'Livingstone', 'Democrat',
          true, false, false, true, -210168,
          ARRAY['https://malegislature.gov/Legislators/Profile/J_L1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 8th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25130' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25131: John F. Moran (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John F. Moran', 'John', 'Moran', 'Democrat',
          true, false, false, true, -210169,
          ARRAY['https://malegislature.gov/Legislators/Profile/JFM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 9th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25131' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25132: William F. MacGregor (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'William F. MacGregor', 'William', 'MacGregor', 'Democrat',
          true, false, false, true, -210170,
          ARRAY['https://malegislature.gov/Legislators/Profile/WFM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 10th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25132' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25133: Judith A. Garcia (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Judith A. Garcia', 'Judith', 'Garcia', 'Democrat',
          true, false, false, true, -210171,
          ARRAY['https://malegislature.gov/Legislators/Profile/JAG2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 11th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25133' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25134: Brandy Fluker-Reid (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Brandy Fluker-Reid', 'Brandy', 'Fluker-Reid', 'Democrat',
          true, false, false, true, -210172,
          ARRAY['https://malegislature.gov/Legislators/Profile/BFR1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 12th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25134' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25135: Daniel J. Hunt (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Daniel J. Hunt', 'Daniel', 'Hunt', 'Democrat',
          true, false, false, true, -210173,
          ARRAY['https://malegislature.gov/Legislators/Profile/djh1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 13th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25135' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25136: Rob Consalvo (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Rob Consalvo', 'Rob', 'Consalvo', 'Democrat',
          true, false, false, true, -210174,
          ARRAY['https://malegislature.gov/Legislators/Profile/R_C1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 14th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25136' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25137: Samantha Montaño (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Samantha Montaño', 'Samantha', 'Montaño', 'Democrat',
          true, false, false, true, -210175,
          ARRAY['https://malegislature.gov/Legislators/Profile/S_M1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 15th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25137' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25138: Jessica A. Giannino (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Jessica A. Giannino', 'Jessica', 'Giannino', 'Democrat',
          true, false, false, true, -210176,
          ARRAY['https://malegislature.gov/Legislators/Profile/JAG1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 16th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25138' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25139: Kevin G. Honan (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kevin G. Honan', 'Kevin', 'Honan', 'Democrat',
          true, false, false, true, -210177,
          ARRAY['https://malegislature.gov/Legislators/Profile/KGH1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 17th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25139' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25140: Michael J. Moran (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael J. Moran', 'Michael', 'Moran', 'Democrat',
          true, false, false, true, -210178,
          ARRAY['https://malegislature.gov/Legislators/Profile/MJM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 18th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25140' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25141: Jeffrey R. Turco (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Jeffrey R. Turco', 'Jeffrey', 'Turco', 'Democrat',
          true, false, false, true, -210179,
          ARRAY['https://malegislature.gov/Legislators/Profile/JRT1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 19th Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25141' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25142: Kimberly N. Ferguson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kimberly N. Ferguson', 'Kimberly', 'Ferguson', 'Republican',
          true, false, false, true, -210180,
          ARRAY['https://malegislature.gov/Legislators/Profile/KNF1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 1st Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25142' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25143: Jonathan D. Zlotnik (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Jonathan D. Zlotnik', 'Jonathan', 'Zlotnik', 'Democrat',
          true, false, false, true, -210181,
          ARRAY['https://malegislature.gov/Legislators/Profile/JDZ1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 2nd Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25143' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25144: Michael P. Kushmerek (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael P. Kushmerek', 'Michael', 'Kushmerek', 'Democrat',
          true, false, false, true, -210182,
          ARRAY['https://malegislature.gov/Legislators/Profile/MPK1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 3rd Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25144' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25145: Natalie Higgins (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Natalie Higgins', 'Natalie', 'Higgins', 'Democrat',
          true, false, false, true, -210183,
          ARRAY['https://malegislature.gov/Legislators/Profile/N_H1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 4th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25145' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25146: Donald R. Berthiaume (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Donald R. Berthiaume', 'Donald', 'Berthiaume', 'Republican',
          true, false, false, true, -210184,
          ARRAY['https://malegislature.gov/Legislators/Profile/DRB1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 5th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25146' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25147: John J. Marsi (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John J. Marsi', 'John', 'Marsi', 'Republican',
          true, false, false, true, -210185,
          ARRAY['https://malegislature.gov/Legislators/Profile/JJM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 6th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25147' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25148: Paul K. Frost (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Paul K. Frost', 'Paul', 'Frost', 'Republican',
          true, false, false, true, -210186,
          ARRAY['https://malegislature.gov/Legislators/Profile/PKF1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 7th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25148' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25149: Michael J. Soter (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael J. Soter', 'Michael', 'Soter', 'Republican',
          true, false, false, true, -210187,
          ARRAY['https://malegislature.gov/Legislators/Profile/MJS3'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 8th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25149' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25150: David K. Muradian (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'David K. Muradian', 'David', 'Muradian', 'Republican',
          true, false, false, true, -210188,
          ARRAY['https://malegislature.gov/Legislators/Profile/DKM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 9th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25150' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25151: Brian W. Murray (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Brian W. Murray', 'Brian', 'Murray', 'Democrat',
          true, false, false, true, -210189,
          ARRAY['https://malegislature.gov/Legislators/Profile/BWM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 10th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25151' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25152: Hannah E. Kane (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Hannah E. Kane', 'Hannah', 'Kane', 'Republican',
          true, false, false, true, -210190,
          ARRAY['https://malegislature.gov/Legislators/Profile/HEK1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 11th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25152' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25153: Meghan Kilcoyne (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Meghan Kilcoyne', 'Meghan', 'Kilcoyne', 'Democrat',
          true, false, false, true, -210191,
          ARRAY['https://malegislature.gov/Legislators/Profile/M_K1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 12th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25153' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25154: John J. Mahoney (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John J. Mahoney', 'John', 'Mahoney', 'Democrat',
          true, false, false, true, -210192,
          ARRAY['https://malegislature.gov/Legislators/Profile/JJM2'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 13th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25154' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25155: James J. O'Day (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'James J. O''Day', 'James', 'O''Day', 'Democrat',
          true, false, false, true, -210193,
          ARRAY['https://malegislature.gov/Legislators/Profile/JJO1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 14th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25155' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25156: Mary S. Keefe (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Mary S. Keefe', 'Mary', 'Keefe', 'Democrat',
          true, false, false, true, -210194,
          ARRAY['https://malegislature.gov/Legislators/Profile/MSK1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 15th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25156' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25157: Daniel M. Donahue (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Daniel M. Donahue', 'Daniel', 'Donahue', 'Democrat',
          true, false, false, true, -210195,
          ARRAY['https://malegislature.gov/Legislators/Profile/DMD1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 16th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25157' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25158: David A. LeBoeuf (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'David A. LeBoeuf', 'David', 'LeBoeuf', 'Democrat',
          true, false, false, true, -210196,
          ARRAY['https://malegislature.gov/Legislators/Profile/DAL1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 17th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25158' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25159: Joseph D. McKenna (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Joseph D. McKenna', 'Joseph', 'McKenna', 'Republican',
          true, false, false, true, -210197,
          ARRAY['https://malegislature.gov/Legislators/Profile/JDM1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 18th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25159' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
-- ===== 25160: Kate Donaghue (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kate Donaghue', 'Kate', 'Donaghue', 'Democrat',
          true, false, false, true, -210198,
          ARRAY['https://malegislature.gov/Legislators/Profile/K_D1'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives'),
       p.id,
       'Representative, 19th Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25160' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts House of Representatives')
  );
