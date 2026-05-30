-- =============================================================================
-- Migration 151: Massachusetts State Senate — 40 Senators
-- =============================================================================
-- Dependencies:
--   Migration 150: essentials.chambers row for 'Massachusetts Senate' must exist
--   essentials.districts: STATE_UPPER rows with geo_ids 25D01–25D40, state='ma'
--
-- Pattern notes:
--   - CTE pattern: each senator is politician + office in one statement
--   - ON CONFLICT (external_id) DO NOTHING on politician inserts (idempotent)
--   - NOT EXISTS guard on office inserts (idempotent)
--   - chamber_id resolved via subquery — never hardcoded UUID
--   - state = 'ma' LOWERCASE in all district WHERE clauses (uppercase returns 0 rows)
--   - representing_state = 'MA' UPPERCASE in offices
--   - bio_url stored in urls column as ARRAY['https://malegislature.gov/...']
--   - email_addresses seeded only for Cambridge-area senators (25D26, 25D27, 25D28)
--   - DO NOT include slug column (GENERATED ALWAYS)
--
-- Idempotency:
--   Safe to re-run. Duplicate politician rows blocked by ON CONFLICT (external_id).
--   Duplicate office rows blocked by NOT EXISTS check on district_id + chamber_id.
-- =============================================================================

BEGIN;

-- ===== 25D01: Paul W. Mark (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Paul W. Mark', 'Paul', 'Mark', 'Democrat',
          true, false, false, true, -210001,
          ARRAY['https://malegislature.gov/Legislators/Profile/PWM0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Berkshire-Hampden-Franklin-Hampshire District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D01' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D02: John C. Velis (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John C. Velis', 'John', 'Velis', 'Democrat',
          true, false, false, true, -210002,
          ARRAY['https://malegislature.gov/Legislators/Profile/JCV0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Hampden and Hampshire District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D02' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D03: Adam Gómez (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Adam Gómez', 'Adam', 'Gómez', 'Democrat',
          true, false, false, true, -210003,
          ARRAY['https://malegislature.gov/Legislators/Profile/A_G0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D03' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D04: Jacob R. Oliveira (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Jacob R. Oliveira', 'Jacob', 'Oliveira', 'Democrat',
          true, false, false, true, -210004,
          ARRAY['https://malegislature.gov/Legislators/Profile/JRO0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Hampden-Hampshire-Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D04' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D05: Joanne M. Comerford (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Joanne M. Comerford', 'Joanne', 'Comerford', 'Democrat',
          true, false, false, true, -210005,
          ARRAY['https://malegislature.gov/Legislators/Profile/JMC0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Hampshire-Franklin-Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D05' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D06: Peter J. Durant (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Peter J. Durant', 'Peter', 'Durant', 'Republican',
          true, false, false, true, -210006,
          ARRAY['https://malegislature.gov/Legislators/Profile/PJD0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Worcester and Hampshire District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D06' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D07: Ryan C. Fattman (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Ryan C. Fattman', 'Ryan', 'Fattman', 'Republican',
          true, false, false, true, -210007,
          ARRAY['https://malegislature.gov/Legislators/Profile/RCF0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Worcester and Hampden District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D07' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D08: Michael O. Moore (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael O. Moore', 'Michael', 'Moore', 'Democrat',
          true, false, false, true, -210008,
          ARRAY['https://malegislature.gov/Legislators/Profile/MOM0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Second Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D08' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D09: Robyn K. Kennedy (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Robyn K. Kennedy', 'Robyn', 'Kennedy', 'Democrat',
          true, false, false, true, -210009,
          ARRAY['https://malegislature.gov/Legislators/Profile/RKK0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, First Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D09' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D10: John J. Cronin (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John J. Cronin', 'John', 'Cronin', 'Democrat',
          true, false, false, true, -210010,
          ARRAY['https://malegislature.gov/Legislators/Profile/JJC0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Worcester and Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D10' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D11: Vanna Howard (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Vanna Howard', 'Vanna', 'Howard', 'Democrat',
          true, false, false, true, -210011,
          ARRAY['https://malegislature.gov/Legislators/Profile/V_H0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, First Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D11' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D12: James B. Eldridge (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'James B. Eldridge', 'James', 'Eldridge', 'Democrat',
          true, false, false, true, -210012,
          ARRAY['https://malegislature.gov/Legislators/Profile/JBE0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Middlesex and Worcester District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D12' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D13: Karen E. Spilka (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Karen E. Spilka', 'Karen', 'Spilka', 'Democrat',
          true, false, false, true, -210013,
          ARRAY['https://malegislature.gov/Legislators/Profile/KES0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Middlesex and Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D13' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D14: Rebecca L. Rausch (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Rebecca L. Rausch', 'Rebecca', 'Rausch', 'Democrat',
          true, false, false, true, -210014,
          ARRAY['https://malegislature.gov/Legislators/Profile/RLR0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Norfolk-Worcester-Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D14' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D15: Michael J. Barrett (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael J. Barrett', 'Michael', 'Barrett', 'Democrat',
          true, false, false, true, -210015,
          ARRAY['https://malegislature.gov/Legislators/Profile/MJB0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Third Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D15' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D16: Cynthia F. Friedman (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Cynthia F. Friedman', 'Cynthia', 'Friedman', 'Democrat',
          true, false, false, true, -210016,
          ARRAY['https://malegislature.gov/Legislators/Profile/CFF0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Fourth Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D16' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D17: Cynthia S. Creem (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Cynthia S. Creem', 'Cynthia', 'Creem', 'Democrat',
          true, false, false, true, -210017,
          ARRAY['https://malegislature.gov/Legislators/Profile/CSC0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Norfolk and Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D17' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D18: Michael F. Rush (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael F. Rush', 'Michael', 'Rush', 'Democrat',
          true, false, false, true, -210018,
          ARRAY['https://malegislature.gov/Legislators/Profile/MFR0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Norfolk and Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D18' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D19: Pavel M. Payano (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Pavel M. Payano', 'Pavel', 'Payano', 'Democrat',
          true, false, false, true, -210019,
          ARRAY['https://malegislature.gov/Legislators/Profile/PMP0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, First Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D19' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D20: Barry R. Finegold (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Barry R. Finegold', 'Barry', 'Finegold', 'Democrat',
          true, false, false, true, -210020,
          ARRAY['https://malegislature.gov/Legislators/Profile/BRF0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Second Essex and Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D20' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D21: Bruce E. Tarr (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Bruce E. Tarr', 'Bruce', 'Tarr', 'Republican',
          true, false, false, true, -210021,
          ARRAY['https://malegislature.gov/Legislators/Profile/BET0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, First Essex and Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D21' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D22: Joan B. Lovely (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Joan B. Lovely', 'Joan', 'Lovely', 'Democrat',
          true, false, false, true, -210022,
          ARRAY['https://malegislature.gov/Legislators/Profile/JBL0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Second Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D22' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D23: Jason M. Lewis (D) — member_code jml0 (lowercase) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Jason M. Lewis', 'Jason', 'Lewis', 'Democrat',
          true, false, false, true, -210023,
          ARRAY['https://malegislature.gov/Legislators/Profile/jml0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Fifth Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D23' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D24: Brendan P. Crighton (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Brendan P. Crighton', 'Brendan', 'Crighton', 'Democrat',
          true, false, false, true, -210024,
          ARRAY['https://malegislature.gov/Legislators/Profile/BPC0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Third Essex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D24' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D25: Lydia M. Edwards (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Lydia M. Edwards', 'Lydia', 'Edwards', 'Democrat',
          true, false, false, true, -210025,
          ARRAY['https://malegislature.gov/Legislators/Profile/LME0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Third Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D25' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D26: Sal N. DiDomenico (D) — Cambridge-area, email seeded =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls, email_addresses)
  VALUES (gen_random_uuid(), 'Sal N. DiDomenico', 'Sal', 'DiDomenico', 'Democrat',
          true, false, false, true, -210026,
          ARRAY['https://malegislature.gov/Legislators/Profile/SND0'],
          ARRAY['Sal.DiDomenico@masenate.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Middlesex and Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D26' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D27: Patricia D. Jehlen (D) — Cambridge-area, email seeded =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls, email_addresses)
  VALUES (gen_random_uuid(), 'Patricia D. Jehlen', 'Patricia', 'Jehlen', 'Democrat',
          true, false, false, true, -210027,
          ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0'],
          ARRAY['Patricia.Jehlen@masenate.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Second Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D27' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D28: William N. Brownsberger (D) — Cambridge-area, email seeded =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls, email_addresses)
  VALUES (gen_random_uuid(), 'William N. Brownsberger', 'William', 'Brownsberger', 'Democrat',
          true, false, false, true, -210028,
          ARRAY['https://malegislature.gov/Legislators/Profile/WNB0'],
          ARRAY['William.Brownsberger@masenate.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Suffolk and Middlesex District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D28' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D29: Liz Miranda (D) — bio_url uses L%20M0 (URL-encoded space) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Liz Miranda', 'Liz', 'Miranda', 'Democrat',
          true, false, false, true, -210029,
          ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Second Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D29' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D30: Nick Collins (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Nick Collins', 'Nick', 'Collins', 'Democrat',
          true, false, false, true, -210030,
          ARRAY['https://malegislature.gov/Legislators/Profile/N_C0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, First Suffolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D30' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D31: Patrick M. O'Connor (R) — apostrophe escaped as O''Connor =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Patrick M. O''Connor', 'Patrick', 'O''Connor', 'Republican',
          true, false, false, true, -210031,
          ARRAY['https://malegislature.gov/Legislators/Profile/PMO'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, First Plymouth and Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D31' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D32: John F. Keenan (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'John F. Keenan', 'John', 'Keenan', 'Democrat',
          true, false, false, true, -210032,
          ARRAY['https://malegislature.gov/Legislators/Profile/JFK0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Norfolk and Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D32' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D33: William J. Driscoll (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'William J. Driscoll', 'William', 'Driscoll', 'Democrat',
          true, false, false, true, -210033,
          ARRAY['https://malegislature.gov/Legislators/Profile/WJD0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Norfolk-Plymouth-Bristol District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D33' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D34: Michael D. Brady (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael D. Brady', 'Michael', 'Brady', 'Democrat',
          true, false, false, true, -210034,
          ARRAY['https://malegislature.gov/Legislators/Profile/MDB0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Second Plymouth and Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D34' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D35: Paul R. Feeney (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Paul R. Feeney', 'Paul', 'Feeney', 'Democrat',
          true, false, false, true, -210035,
          ARRAY['https://malegislature.gov/Legislators/Profile/PRF0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Bristol and Norfolk District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D35' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D36: Kelly A. Dooner (R) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Kelly A. Dooner', 'Kelly', 'Dooner', 'Republican',
          true, false, false, true, -210036,
          ARRAY['https://malegislature.gov/Legislators/Profile/KAD0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Third Bristol and Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D36' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D37: Michael J. Rodrigues (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Michael J. Rodrigues', 'Michael', 'Rodrigues', 'Democrat',
          true, false, false, true, -210037,
          ARRAY['https://malegislature.gov/Legislators/Profile/MJR0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, First Bristol and Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D37' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D38: Mark C. Montigny (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Mark C. Montigny', 'Mark', 'Montigny', 'Democrat',
          true, false, false, true, -210038,
          ARRAY['https://malegislature.gov/Legislators/Profile/MCM0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Second Bristol and Plymouth District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D38' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D39: Dylan A. Fernandes (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Dylan A. Fernandes', 'Dylan', 'Fernandes', 'Democrat',
          true, false, false, true, -210039,
          ARRAY['https://malegislature.gov/Legislators/Profile/DAF0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Plymouth and Barnstable District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D39' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

-- ===== 25D40: Julian A. Cyr (D) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls)
  VALUES (gen_random_uuid(), 'Julian A. Cyr', 'Julian', 'Cyr', 'Democrat',
          true, false, false, true, -210040,
          ARRAY['https://malegislature.gov/Legislators/Profile/JAC0'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate'),
       p.id,
       'Senator, Cape and Islands District', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '25D40' AND d.district_type = 'STATE_UPPER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Senate')
  );

COMMIT;
