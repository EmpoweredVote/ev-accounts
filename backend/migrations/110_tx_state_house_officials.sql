-- Migration 110: TX State House Representatives (89th Legislature)
--
-- Seeds 150 TX state representatives + 150 offices (D1..D150). No vacancies.
-- All offices linked to 'Texas House of Representatives' chamber (Plan 21-02).
--
-- Depends on:
--   Plan 21-01: 150 STATE_LOWER districts (geo_ids '48001'..'48150') loaded via
--               load-tx-state-boundaries.ts + TIGER/Line 2024 SLDL shapefile.
--   Plan 21-02 (migration 108): 'Texas House of Representatives' chamber exists
--               (UUID 5ac03af0-938f-4a31-84f1-e7a644711e0e) under
--               government_id 8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9.
--
-- geo_id formula: '48' + LPAD(district_number::text, 3, '0') → 5-char TIGER GEOID
--   D1   = '48001'
--   D49  = '48049'
--   D100 = '48100'
--   D150 = '48150'
--
-- external_id pattern: -(100500 + district_number)
--   D1   Gary VanDeaver   = -100501
--   D150 Valoree Swanson  = -100650
--
-- Task 1 roster verification (2026-05-04, completed before Task 2 checkpoint):
--   house.texas.gov + capitol.texas.gov cross-referenced against canonical list.
--   All 150 seats confirmed active. No vacancies.
--   7 name-form discrepancies resolved — all kept canonical form from approved list.
--   D115 upgraded to full form 'Cassandra Garcia Hernandez'.
--   Party: 88 Republican, 62 Democrat. Approved by user at Task 2 checkpoint.
--
-- Special name handling:
--   D3:  Cecil Bell Jr.         — suffix in full_name, last_name='Bell'
--   D30: AJ Louderback          — initials, no periods
--   D52: Caroline Harris Davila — compound last name
--   D90: Ramon Romero Jr.       — suffix in full_name, last_name='Romero'
--   D102: Ana-Maria Ramos       — hyphenated first name
--   D115: Cassandra Garcia Hernandez — compound last name (upgraded from 'Cassandra Hernandez')
--   D116: Trey Martinez Fischer  — compound last name
--   D120: Barbara Gervin-Hawkins — hyphenated last name
--   D136: John Bucy III          — suffix in full_name, last_name='Bucy'
--   D139: Charlene Ward Johnson  — compound last name
--   D142: Harold Dutton Jr.      — suffix in full_name, last_name='Dutton'
--   D144: Mary Ann Perez         — two-word first name
--   D148: Penny Morales Shaw     — compound last name
--
-- Idempotent:
--   - politicians INSERTs use ON CONFLICT (external_id) DO NOTHING
--   - offices INSERTs guarded by NOT EXISTS on (district_id, chamber_id)
--   - office_id back-fill uses WHERE p.office_id IS NULL guard

BEGIN;

-- ===== D1: Gary VanDeaver (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gary VanDeaver', 'Gary', 'VanDeaver', 'Republican',
          true, false, false, true, -100501)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48001' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D2: Brent Money (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brent Money', 'Brent', 'Money', 'Republican',
          true, false, false, true, -100502)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48002' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D3: Cecil Bell Jr. (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cecil Bell Jr.', 'Cecil', 'Bell', 'Republican',
          true, false, false, true, -100503)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48003' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D4: Keith Bell (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Keith Bell', 'Keith', 'Bell', 'Republican',
          true, false, false, true, -100504)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48004' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D5: Cole Hefner (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cole Hefner', 'Cole', 'Hefner', 'Republican',
          true, false, false, true, -100505)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48005' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D6: Daniel Alders (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniel Alders', 'Daniel', 'Alders', 'Republican',
          true, false, false, true, -100506)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48006' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D7: Jay Dean (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jay Dean', 'Jay', 'Dean', 'Republican',
          true, false, false, true, -100507)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48007' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D8: Cody Harris (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cody Harris', 'Cody', 'Harris', 'Republican',
          true, false, false, true, -100508)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48008' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D9: Trent Ashby (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Trent Ashby', 'Trent', 'Ashby', 'Republican',
          true, false, false, true, -100509)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48009' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D10: Brian Harrison (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Harrison', 'Brian', 'Harrison', 'Republican',
          true, false, false, true, -100510)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48010' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D11: Joanne Shofner (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joanne Shofner', 'Joanne', 'Shofner', 'Republican',
          true, false, false, true, -100511)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48011' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D12: Trey Wharton (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Trey Wharton', 'Trey', 'Wharton', 'Republican',
          true, false, false, true, -100512)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48012' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D13: Angelia Orr (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angelia Orr', 'Angelia', 'Orr', 'Republican',
          true, false, false, true, -100513)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48013' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D14: Paul Dyson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Dyson', 'Paul', 'Dyson', 'Republican',
          true, false, false, true, -100514)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48014' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D15: Steve Toth (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Toth', 'Steve', 'Toth', 'Republican',
          true, false, false, true, -100515)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48015' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D16: Will Metcalf (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Will Metcalf', 'Will', 'Metcalf', 'Republican',
          true, false, false, true, -100516)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48016' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D17: Stan Gerdes (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stan Gerdes', 'Stan', 'Gerdes', 'Republican',
          true, false, false, true, -100517)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48017' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D18: Janis Holt (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janis Holt', 'Janis', 'Holt', 'Republican',
          true, false, false, true, -100518)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48018' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D19: Ellen Troxclair (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ellen Troxclair', 'Ellen', 'Troxclair', 'Republican',
          true, false, false, true, -100519)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48019' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D20: Terry Wilson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Terry Wilson', 'Terry', 'Wilson', 'Republican',
          true, false, false, true, -100520)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48020' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D21: Dade Phelan (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dade Phelan', 'Dade', 'Phelan', 'Republican',
          true, false, false, true, -100521)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48021' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D22: Christian Manuel (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christian Manuel', 'Christian', 'Manuel', 'Democrat',
          true, false, false, true, -100522)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48022' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D23: Terri Leo-Wilson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Terri Leo-Wilson', 'Terri', 'Leo-Wilson', 'Republican',
          true, false, false, true, -100523)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48023' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D24: Greg Bonnen (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Greg Bonnen', 'Greg', 'Bonnen', 'Republican',
          true, false, false, true, -100524)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48024' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D25: Cody Vasut (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cody Vasut', 'Cody', 'Vasut', 'Republican',
          true, false, false, true, -100525)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48025' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D26: Matt Morgan (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Morgan', 'Matt', 'Morgan', 'Republican',
          true, false, false, true, -100526)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48026' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D27: Ron Reynolds (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ron Reynolds', 'Ron', 'Reynolds', 'Democrat',
          true, false, false, true, -100527)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48027' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D28: Gary Gates (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gary Gates', 'Gary', 'Gates', 'Republican',
          true, false, false, true, -100528)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48028' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D29: Jeffrey Barry (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeffrey Barry', 'Jeffrey', 'Barry', 'Republican',
          true, false, false, true, -100529)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48029' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D30: AJ Louderback (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'AJ Louderback', 'AJ', 'Louderback', 'Republican',
          true, false, false, true, -100530)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48030' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D31: Ryan Guillen (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ryan Guillen', 'Ryan', 'Guillen', 'Republican',
          true, false, false, true, -100531)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48031' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D32: Todd Hunter (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Todd Hunter', 'Todd', 'Hunter', 'Republican',
          true, false, false, true, -100532)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48032' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D33: Katrina Pierson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Katrina Pierson', 'Katrina', 'Pierson', 'Republican',
          true, false, false, true, -100533)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48033' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D34: Denise Villalobos (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Denise Villalobos', 'Denise', 'Villalobos', 'Republican',
          true, false, false, true, -100534)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48034' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D35: Oscar Longoria (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Oscar Longoria', 'Oscar', 'Longoria', 'Democrat',
          true, false, false, true, -100535)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48035' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D36: Sergio Munoz (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sergio Munoz', 'Sergio', 'Munoz', 'Democrat',
          true, false, false, true, -100536)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48036' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D37: Janie Lopez (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janie Lopez', 'Janie', 'Lopez', 'Republican',
          true, false, false, true, -100537)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48037' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D38: Erin Gamez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Erin Gamez', 'Erin', 'Gamez', 'Democrat',
          true, false, false, true, -100538)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48038' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D39: Armando Martinez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Armando Martinez', 'Armando', 'Martinez', 'Democrat',
          true, false, false, true, -100539)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48039' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D40: Terry Canales (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Terry Canales', 'Terry', 'Canales', 'Democrat',
          true, false, false, true, -100540)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48040' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D41: Robert Guerra (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Robert Guerra', 'Robert', 'Guerra', 'Democrat',
          true, false, false, true, -100541)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48041' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D42: Richard Raymond (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Raymond', 'Richard', 'Raymond', 'Democrat',
          true, false, false, true, -100542)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48042' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D43: Jose Manuel Lozano (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jose Manuel Lozano', 'Jose', 'Lozano', 'Republican',
          true, false, false, true, -100543)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48043' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D44: Alan Schoolcraft (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alan Schoolcraft', 'Alan', 'Schoolcraft', 'Republican',
          true, false, false, true, -100544)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48044' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D45: Erin Zwiener (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Erin Zwiener', 'Erin', 'Zwiener', 'Democrat',
          true, false, false, true, -100545)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48045' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D46: Sheryl Cole (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sheryl Cole', 'Sheryl', 'Cole', 'Democrat',
          true, false, false, true, -100546)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48046' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D47: Vikki Goodwin (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vikki Goodwin', 'Vikki', 'Goodwin', 'Democrat',
          true, false, false, true, -100547)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48047' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D48: Donna Howard (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Donna Howard', 'Donna', 'Howard', 'Democrat',
          true, false, false, true, -100548)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48048' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D49: Gina Hinojosa (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gina Hinojosa', 'Gina', 'Hinojosa', 'Democrat',
          true, false, false, true, -100549)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48049' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D50: James Talarico (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Talarico', 'James', 'Talarico', 'Democrat',
          true, false, false, true, -100550)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48050' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D51: Lulu Flores (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lulu Flores', 'Lulu', 'Flores', 'Democrat',
          true, false, false, true, -100551)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48051' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D52: Caroline Harris Davila (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Caroline Harris Davila', 'Caroline', 'Harris Davila', 'Republican',
          true, false, false, true, -100552)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48052' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D53: Wesley Virdell (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wesley Virdell', 'Wesley', 'Virdell', 'Republican',
          true, false, false, true, -100553)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48053' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D54: Brad Buckley (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brad Buckley', 'Brad', 'Buckley', 'Republican',
          true, false, false, true, -100554)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48054' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D55: Hillary Hickland (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Hillary Hickland', 'Hillary', 'Hickland', 'Republican',
          true, false, false, true, -100555)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48055' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D56: Pat Curry (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pat Curry', 'Pat', 'Curry', 'Republican',
          true, false, false, true, -100556)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48056' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D57: Richard Hayes (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Hayes', 'Richard', 'Hayes', 'Republican',
          true, false, false, true, -100557)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48057' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D58: Helen Kerwin (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Helen Kerwin', 'Helen', 'Kerwin', 'Republican',
          true, false, false, true, -100558)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48058' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D59: Shelby Slawson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shelby Slawson', 'Shelby', 'Slawson', 'Republican',
          true, false, false, true, -100559)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48059' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D60: Mike Olcott (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Olcott', 'Mike', 'Olcott', 'Republican',
          true, false, false, true, -100560)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48060' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D61: Keresa Richardson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Keresa Richardson', 'Keresa', 'Richardson', 'Republican',
          true, false, false, true, -100561)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48061' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D62: Shelley Luther (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shelley Luther', 'Shelley', 'Luther', 'Republican',
          true, false, false, true, -100562)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48062' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D63: Ben Bumgarner (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ben Bumgarner', 'Ben', 'Bumgarner', 'Republican',
          true, false, false, true, -100563)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48063' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D64: Andy Hopper (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andy Hopper', 'Andy', 'Hopper', 'Republican',
          true, false, false, true, -100564)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48064' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D65: Mitch Little (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mitch Little', 'Mitch', 'Little', 'Republican',
          true, false, false, true, -100565)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48065' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D66: Matt Shaheen (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Shaheen', 'Matt', 'Shaheen', 'Republican',
          true, false, false, true, -100566)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48066' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D67: Jeff Leach (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeff Leach', 'Jeff', 'Leach', 'Republican',
          true, false, false, true, -100567)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48067' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D68: David Spiller (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Spiller', 'David', 'Spiller', 'Republican',
          true, false, false, true, -100568)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48068' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D69: James Frank (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Frank', 'James', 'Frank', 'Republican',
          true, false, false, true, -100569)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48069' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D70: Mihaela Plesa (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mihaela Plesa', 'Mihaela', 'Plesa', 'Democrat',
          true, false, false, true, -100570)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48070' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D71: Stan Lambert (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stan Lambert', 'Stan', 'Lambert', 'Republican',
          true, false, false, true, -100571)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48071' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D72: Drew Darby (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Drew Darby', 'Drew', 'Darby', 'Republican',
          true, false, false, true, -100572)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48072' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D73: Carrie Isaac (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carrie Isaac', 'Carrie', 'Isaac', 'Republican',
          true, false, false, true, -100573)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48073' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D74: Eddie Morales (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eddie Morales', 'Eddie', 'Morales', 'Democrat',
          true, false, false, true, -100574)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48074' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D75: Mary Gonzalez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mary Gonzalez', 'Mary', 'Gonzalez', 'Democrat',
          true, false, false, true, -100575)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48075' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);
-- ===== D76: Suleman Lalani (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Suleman Lalani', 'Suleman', 'Lalani', 'Democrat',
          true, false, false, true, -100576)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48076' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D77: Vincent Perez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vincent Perez', 'Vincent', 'Perez', 'Democrat',
          true, false, false, true, -100577)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48077' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D78: Joe Moody (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joe Moody', 'Joe', 'Moody', 'Democrat',
          true, false, false, true, -100578)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48078' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D79: Claudia Ordaz (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Claudia Ordaz', 'Claudia', 'Ordaz', 'Democrat',
          true, false, false, true, -100579)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48079' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D80: Don McLaughlin (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Don McLaughlin', 'Don', 'McLaughlin', 'Republican',
          true, false, false, true, -100580)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48080' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D81: Brooks Landgraf (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brooks Landgraf', 'Brooks', 'Landgraf', 'Republican',
          true, false, false, true, -100581)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48081' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D82: Tom Craddick (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tom Craddick', 'Tom', 'Craddick', 'Republican',
          true, false, false, true, -100582)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48082' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D83: Dustin Burrows (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dustin Burrows', 'Dustin', 'Burrows', 'Republican',
          true, false, false, true, -100583)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48083' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D84: Carl Tepper (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carl Tepper', 'Carl', 'Tepper', 'Republican',
          true, false, false, true, -100584)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48084' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D85: Stan Kitzman (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stan Kitzman', 'Stan', 'Kitzman', 'Republican',
          true, false, false, true, -100585)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48085' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D86: John Smithee (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Smithee', 'John', 'Smithee', 'Republican',
          true, false, false, true, -100586)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48086' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D87: Caroline Fairly (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Caroline Fairly', 'Caroline', 'Fairly', 'Republican',
          true, false, false, true, -100587)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48087' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D88: Ken King (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ken King', 'Ken', 'King', 'Republican',
          true, false, false, true, -100588)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48088' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D89: Candy Noble (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Candy Noble', 'Candy', 'Noble', 'Republican',
          true, false, false, true, -100589)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48089' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D90: Ramon Romero Jr. (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ramon Romero Jr.', 'Ramon', 'Romero', 'Democrat',
          true, false, false, true, -100590)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48090' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D91: David Lowe (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Lowe', 'David', 'Lowe', 'Republican',
          true, false, false, true, -100591)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48091' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D92: Salman Bhojani (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Salman Bhojani', 'Salman', 'Bhojani', 'Democrat',
          true, false, false, true, -100592)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48092' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D93: Nate Schatzline (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nate Schatzline', 'Nate', 'Schatzline', 'Republican',
          true, false, false, true, -100593)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48093' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D94: Tony Tinderholt (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tony Tinderholt', 'Tony', 'Tinderholt', 'Republican',
          true, false, false, true, -100594)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48094' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D95: Nicole Collier (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nicole Collier', 'Nicole', 'Collier', 'Democrat',
          true, false, false, true, -100595)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48095' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D96: David Cook (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Cook', 'David', 'Cook', 'Republican',
          true, false, false, true, -100596)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48096' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D97: John McQueeney (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John McQueeney', 'John', 'McQueeney', 'Republican',
          true, false, false, true, -100597)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48097' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D98: Giovanni Capriglione (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Giovanni Capriglione', 'Giovanni', 'Capriglione', 'Republican',
          true, false, false, true, -100598)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48098' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D99: Charlie Geren (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charlie Geren', 'Charlie', 'Geren', 'Republican',
          true, false, false, true, -100599)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48099' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D100: Venton Jones (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Venton Jones', 'Venton', 'Jones', 'Democrat',
          true, false, false, true, -100600)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48100' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D101: Chris Turner (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chris Turner', 'Chris', 'Turner', 'Democrat',
          true, false, false, true, -100601)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48101' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D102: Ana-Maria Ramos (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ana-Maria Ramos', 'Ana-Maria', 'Ramos', 'Democrat',
          true, false, false, true, -100602)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48102' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D103: Rafael Anchia (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rafael Anchia', 'Rafael', 'Anchia', 'Democrat',
          true, false, false, true, -100603)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48103' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D104: Jessica Gonzalez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jessica Gonzalez', 'Jessica', 'Gonzalez', 'Democrat',
          true, false, false, true, -100604)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48104' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D105: Terry Meza (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Terry Meza', 'Terry', 'Meza', 'Democrat',
          true, false, false, true, -100605)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48105' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D106: Jared Patterson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jared Patterson', 'Jared', 'Patterson', 'Republican',
          true, false, false, true, -100606)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48106' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D107: Linda Garcia (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Linda Garcia', 'Linda', 'Garcia', 'Democrat',
          true, false, false, true, -100607)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48107' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D108: Morgan Meyer (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Morgan Meyer', 'Morgan', 'Meyer', 'Republican',
          true, false, false, true, -100608)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48108' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D109: Aicha Davis (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Aicha Davis', 'Aicha', 'Davis', 'Democrat',
          true, false, false, true, -100609)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48109' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D110: Toni Rose (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Toni Rose', 'Toni', 'Rose', 'Democrat',
          true, false, false, true, -100610)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48110' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D111: Yvonne Davis (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Yvonne Davis', 'Yvonne', 'Davis', 'Democrat',
          true, false, false, true, -100611)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48111' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D112: Angie Button (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angie Button', 'Angie', 'Button', 'Republican',
          true, false, false, true, -100612)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48112' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D113: Rhetta Bowers (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rhetta Bowers', 'Rhetta', 'Bowers', 'Democrat',
          true, false, false, true, -100613)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48113' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D114: John Bryant (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Bryant', 'John', 'Bryant', 'Democrat',
          true, false, false, true, -100614)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48114' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D115: Cassandra Garcia Hernandez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cassandra Garcia Hernandez', 'Cassandra', 'Garcia Hernandez', 'Democrat',
          true, false, false, true, -100615)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48115' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D116: Trey Martinez Fischer (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Trey Martinez Fischer', 'Trey', 'Martinez Fischer', 'Democrat',
          true, false, false, true, -100616)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48116' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D117: Philip Cortez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Philip Cortez', 'Philip', 'Cortez', 'Democrat',
          true, false, false, true, -100617)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48117' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D118: John Lujan (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Lujan', 'John', 'Lujan', 'Republican',
          true, false, false, true, -100618)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48118' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D119: Elizabeth Campos (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth Campos', 'Elizabeth', 'Campos', 'Democrat',
          true, false, false, true, -100619)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48119' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D120: Barbara Gervin-Hawkins (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Barbara Gervin-Hawkins', 'Barbara', 'Gervin-Hawkins', 'Democrat',
          true, false, false, true, -100620)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48120' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D121: Marc LaHood (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marc LaHood', 'Marc', 'LaHood', 'Republican',
          true, false, false, true, -100621)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48121' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D122: Mark Dorazio (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Dorazio', 'Mark', 'Dorazio', 'Republican',
          true, false, false, true, -100622)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48122' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D123: Diego Bernal (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Diego Bernal', 'Diego', 'Bernal', 'Democrat',
          true, false, false, true, -100623)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48123' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D124: Josey Garcia (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Josey Garcia', 'Josey', 'Garcia', 'Democrat',
          true, false, false, true, -100624)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48124' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D125: Ray Lopez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ray Lopez', 'Ray', 'Lopez', 'Democrat',
          true, false, false, true, -100625)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48125' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D126: Sam Harless (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sam Harless', 'Sam', 'Harless', 'Republican',
          true, false, false, true, -100626)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48126' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D127: Charles Cunningham (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charles Cunningham', 'Charles', 'Cunningham', 'Republican',
          true, false, false, true, -100627)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48127' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D128: Briscoe Cain (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Briscoe Cain', 'Briscoe', 'Cain', 'Republican',
          true, false, false, true, -100628)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48128' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D129: Dennis Paul (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dennis Paul', 'Dennis', 'Paul', 'Republican',
          true, false, false, true, -100629)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48129' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D130: Tom Oliverson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tom Oliverson', 'Tom', 'Oliverson', 'Republican',
          true, false, false, true, -100630)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48130' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D131: Alma Allen (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alma Allen', 'Alma', 'Allen', 'Democrat',
          true, false, false, true, -100631)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48131' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D132: Mike Schofield (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Schofield', 'Mike', 'Schofield', 'Republican',
          true, false, false, true, -100632)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48132' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D133: Mano DeAyala (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mano DeAyala', 'Mano', 'DeAyala', 'Republican',
          true, false, false, true, -100633)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48133' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D134: Ann Johnson (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ann Johnson', 'Ann', 'Johnson', 'Democrat',
          true, false, false, true, -100634)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48134' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D135: Jon Rosenthal (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jon Rosenthal', 'Jon', 'Rosenthal', 'Democrat',
          true, false, false, true, -100635)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48135' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D136: John Bucy III (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Bucy III', 'John', 'Bucy', 'Democrat',
          true, false, false, true, -100636)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48136' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D137: Gene Wu (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gene Wu', 'Gene', 'Wu', 'Democrat',
          true, false, false, true, -100637)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48137' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D138: Lacey Hull (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lacey Hull', 'Lacey', 'Hull', 'Republican',
          true, false, false, true, -100638)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48138' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D139: Charlene Ward Johnson (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charlene Ward Johnson', 'Charlene', 'Ward Johnson', 'Democrat',
          true, false, false, true, -100639)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48139' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D140: Armando Walle (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Armando Walle', 'Armando', 'Walle', 'Democrat',
          true, false, false, true, -100640)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48140' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D141: Senfronia Thompson (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Senfronia Thompson', 'Senfronia', 'Thompson', 'Democrat',
          true, false, false, true, -100641)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48141' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D142: Harold Dutton Jr. (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Harold Dutton Jr.', 'Harold', 'Dutton', 'Democrat',
          true, false, false, true, -100642)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48142' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D143: Ana Hernandez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ana Hernandez', 'Ana', 'Hernandez', 'Democrat',
          true, false, false, true, -100643)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48143' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D144: Mary Ann Perez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mary Ann Perez', 'Mary Ann', 'Perez', 'Democrat',
          true, false, false, true, -100644)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48144' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D145: Christina Morales (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christina Morales', 'Christina', 'Morales', 'Democrat',
          true, false, false, true, -100645)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48145' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D146: Lauren Ashley Simmons (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lauren Ashley Simmons', 'Lauren', 'Simmons', 'Democrat',
          true, false, false, true, -100646)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48146' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D147: Jolanda Jones (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jolanda Jones', 'Jolanda', 'Jones', 'Democrat',
          true, false, false, true, -100647)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48147' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D148: Penny Morales Shaw (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Penny Morales Shaw', 'Penny', 'Morales Shaw', 'Democrat',
          true, false, false, true, -100648)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48148' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D149: Hubert Vo (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Hubert Vo', 'Hubert', 'Vo', 'Democrat',
          true, false, false, true, -100649)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48149' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== D150: Valoree Swanson (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Valoree Swanson', 'Valoree', 'Swanson', 'Republican',
          true, false, false, true, -100650)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid,
       p.id, 'Representative', 'TX', false, false
FROM essentials.districts d CROSS JOIN ins_p p
WHERE d.geo_id = '48150' AND d.district_type = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = '5ac03af0-938f-4a31-84f1-e7a644711e0e'::uuid);

-- ===== Office ID back-fill =====
-- Link each politician to their office where office_id is still NULL
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.office_id IS NULL
  AND p.external_id BETWEEN -100650 AND -100501;

COMMIT;
