-- Migration 109: TX State Senate officials (89th Legislature)
--
-- Seeds 30 TX state senators + 31 offices (D1..D31; D4 is vacant — office row
-- exists with is_vacant=true, politician_id NULL, no politician row inserted).
--
-- Depends on:
--   Plan 21-01: 31 STATE_UPPER districts (geo_ids '48001'..'48031') loaded via
--               load-tx-state-boundaries.ts + TIGER/Line 2024 SLDU shapefile.
--   Plan 21-02: 'Texas State Senate' chamber (UUID 0b970b1c-5308-4a56-bfe9-b74ae9e58ea2)
--               exists under government_id 8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9.
--
-- geo_id formula: '48' + LPAD(district_number::text, 3, '0') → 5-char TIGER GEOID
--   D1  = '48001'
--   D9  = '48009'
--   D14 = '48014'
--   D31 = '48031'
--
-- external_id pattern: -(100400 + district_number)
--   D1  Bryan Hughes  = -100401
--   D31 Kevin Sparks  = -100431
--   D4  vacancy       = -100404 (intentionally unused — no politician row)
--
-- Democrats: D6, D13, D14, D15, D16, D19, D20, D21, D23, D26, D27, D29
-- All others: Republican
--
-- Special name handling:
--   D9:  Taylor Rehmet (verified from senate.texas.gov 2026-05-04; NOT Rehmert)
--   D20: Juan "Chuy" Hinojosa — full_name includes nickname in quotes
--   D26: José Menéndez — diacritic preserved in full_name
--   D29: César Blanco — diacritic preserved in full_name
--
-- Task 1 roster verification (2026-05-04):
--   senate.texas.gov was cross-referenced against 21-RESEARCH.md canonical list.
--   All 30 senators confirmed. D4 vacancy confirmed still in effect.
--   D9 spelling: 'Taylor Rehmet' (not Rehmert) — confirmed from official senate.texas.gov.
--   No discrepancies found. All names match exactly.
--
-- Idempotent:
--   - politicians INSERTs use ON CONFLICT (external_id) DO NOTHING
--   - offices INSERTs guarded by NOT EXISTS on (district_id, chamber_id)
--   - office_id back-fill uses WHERE p.office_id IS NULL guard

BEGIN;

-- ===== D1: Bryan Hughes (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bryan Hughes', 'Bryan', 'Hughes', 'Republican',
          true, false, false, true, -100401)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48001' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D2: Bob Hall (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bob Hall', 'Bob', 'Hall', 'Republican',
          true, false, false, true, -100402)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48002' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D3: Robert Nichols (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Robert Nichols', 'Robert', 'Nichols', 'Republican',
          true, false, false, true, -100403)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48003' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D4: VACANT — office row only, no politician =====
-- external_id -100404 intentionally unused (no politician row)
-- Seat has been vacant throughout 89th Legislature (as of 2026-05-04).
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       NULL,
       'Senator', 'TX', false, true
FROM essentials.districts d
WHERE d.geo_id = '48004' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D5: Charles Schwertner (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charles Schwertner', 'Charles', 'Schwertner', 'Republican',
          true, false, false, true, -100405)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48005' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D6: Carol Alvarado (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carol Alvarado', 'Carol', 'Alvarado', 'Democrat',
          true, false, false, true, -100406)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48006' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D7: Paul Bettencourt (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Bettencourt', 'Paul', 'Bettencourt', 'Republican',
          true, false, false, true, -100407)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48007' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D8: Angela Paxton (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angela Paxton', 'Angela', 'Paxton', 'Republican',
          true, false, false, true, -100408)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48008' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D9: Taylor Rehmet (R) =====
-- Name verified from senate.texas.gov 2026-05-04: 'Taylor Rehmet' (not Rehmert)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Taylor Rehmet', 'Taylor', 'Rehmet', 'Republican',
          true, false, false, true, -100409)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48009' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D10: Phil King (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Phil King', 'Phil', 'King', 'Republican',
          true, false, false, true, -100410)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48010' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D11: Mayes Middleton (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mayes Middleton', 'Mayes', 'Middleton', 'Republican',
          true, false, false, true, -100411)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48011' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D12: Tan Parker (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tan Parker', 'Tan', 'Parker', 'Republican',
          true, false, false, true, -100412)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48012' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D13: Borris Miles (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Borris Miles', 'Borris', 'Miles', 'Democrat',
          true, false, false, true, -100413)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48013' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D14: Sarah Eckhardt (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sarah Eckhardt', 'Sarah', 'Eckhardt', 'Democrat',
          true, false, false, true, -100414)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48014' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D15: Molly Cook (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Molly Cook', 'Molly', 'Cook', 'Democrat',
          true, false, false, true, -100415)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48015' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D16: Nathan Johnson (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nathan Johnson', 'Nathan', 'Johnson', 'Democrat',
          true, false, false, true, -100416)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48016' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D17: Joan Huffman (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joan Huffman', 'Joan', 'Huffman', 'Republican',
          true, false, false, true, -100417)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48017' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D18: Lois Kolkhorst (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lois Kolkhorst', 'Lois', 'Kolkhorst', 'Republican',
          true, false, false, true, -100418)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48018' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D19: Roland Gutierrez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roland Gutierrez', 'Roland', 'Gutierrez', 'Democrat',
          true, false, false, true, -100419)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48019' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D20: Juan "Chuy" Hinojosa (D) =====
-- full_name includes nickname in quotes per plan spec
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Juan "Chuy" Hinojosa', 'Juan', 'Hinojosa', 'Democrat',
          true, false, false, true, -100420)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48020' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D21: Judith Zaffirini (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Judith Zaffirini', 'Judith', 'Zaffirini', 'Democrat',
          true, false, false, true, -100421)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48021' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D22: Brian Birdwell (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Birdwell', 'Brian', 'Birdwell', 'Republican',
          true, false, false, true, -100422)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48022' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D23: Royce West (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Royce West', 'Royce', 'West', 'Democrat',
          true, false, false, true, -100423)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48023' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D24: Pete Flores (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pete Flores', 'Pete', 'Flores', 'Republican',
          true, false, false, true, -100424)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48024' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D25: Donna Campbell (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Donna Campbell', 'Donna', 'Campbell', 'Republican',
          true, false, false, true, -100425)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48025' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D26: José Menéndez (D) =====
-- Diacritics preserved: José Menéndez
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'José Menéndez', 'José', 'Menéndez', 'Democrat',
          true, false, false, true, -100426)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48026' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D27: Adam Hinojosa (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Adam Hinojosa', 'Adam', 'Hinojosa', 'Democrat',
          true, false, false, true, -100427)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48027' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D28: Charles Perry (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charles Perry', 'Charles', 'Perry', 'Republican',
          true, false, false, true, -100428)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48028' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D29: César Blanco (D) =====
-- Diacritic preserved: César Blanco
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'César Blanco', 'César', 'Blanco', 'Democrat',
          true, false, false, true, -100429)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48029' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D30: Brent Hagenbuch (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brent Hagenbuch', 'Brent', 'Hagenbuch', 'Republican',
          true, false, false, true, -100430)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48030' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== D31: Kevin Sparks (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Sparks', 'Kevin', 'Sparks', 'Republican',
          true, false, false, true, -100431)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid,
       p.id,
       'Senator', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '48031' AND d.district_type = 'STATE_UPPER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = '0b970b1c-5308-4a56-bfe9-b74ae9e58ea2'::uuid
  );

-- ===== office_id back-fill =====
-- Link politicians.office_id <- offices.id via offices.politician_id.
-- Pattern from migration 107. Scoped to full senator external_id range
-- -100431..-100401 (includes headroom; -100404 is unused so no politician row
-- exists for that value — the WHERE condition safely skips it).

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -100431 AND -100401
  AND p.office_id IS NULL;

COMMIT;
