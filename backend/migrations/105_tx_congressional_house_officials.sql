-- Migration 105: TX US House Representatives (119th Congress)
--
-- Seeds 37 TX House politicians + 38 offices (TX-1..TX-38; TX-23 is vacant
-- as of April 14, 2026 — office row exists with is_vacant=true, no politician).
--
-- Depends on Plan 19-01 having loaded the 38 NATIONAL_LOWER TX districts
-- (geo_ids '4801'..'4838') via load-us-congressional-boundaries.ts + migration 104.
--
-- US House chamber UUID resolved from live DB:
--   c2facc31-7b13-428c-b7b9-32d0d3b95f76
--   (chamber.name_formal = 'United States House of Representatives')
--
-- external_id pattern: -100300 - district_number (e.g. TX-1 = -100301, TX-38 = -100338)
-- -100323 is intentionally unused (TX-23 vacancy has no politician row)

BEGIN;

-- TX-1: Nathaniel Moran (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nathaniel Moran', 'Nathaniel', 'Moran', 'Republican', true, false, false, true, -100301)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4801' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-2: Dan Crenshaw (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dan Crenshaw', 'Dan', 'Crenshaw', 'Republican', true, false, false, true, -100302)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4802' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-3: Keith Self (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Keith Self', 'Keith', 'Self', 'Republican', true, false, false, true, -100303)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4803' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-4: Pat Fallon (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pat Fallon', 'Pat', 'Fallon', 'Republican', true, false, false, true, -100304)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4804' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-5: Lance Gooden (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lance Gooden', 'Lance', 'Gooden', 'Republican', true, false, false, true, -100305)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4805' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-6: Jake Ellzey (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jake Ellzey', 'Jake', 'Ellzey', 'Republican', true, false, false, true, -100306)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4806' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-7: Lizzie Fletcher (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lizzie Fletcher', 'Lizzie', 'Fletcher', 'Democrat', true, false, false, true, -100307)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4807' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-8: Morgan Luttrell (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Morgan Luttrell', 'Morgan', 'Luttrell', 'Republican', true, false, false, true, -100308)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4808' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-9: Al Green (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Al Green', 'Al', 'Green', 'Democrat', true, false, false, true, -100309)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4809' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-10: Michael McCaul (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael McCaul', 'Michael', 'McCaul', 'Republican', true, false, false, true, -100310)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4810' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-11: August Pfluger (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'August Pfluger', 'August', 'Pfluger', 'Republican', true, false, false, true, -100311)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4811' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-12: Craig Goldman (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Craig Goldman', 'Craig', 'Goldman', 'Republican', true, false, false, true, -100312)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4812' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-13: Ronny Jackson (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ronny Jackson', 'Ronny', 'Jackson', 'Republican', true, false, false, true, -100313)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4813' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-14: Randy Weber (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Randy Weber', 'Randy', 'Weber', 'Republican', true, false, false, true, -100314)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4814' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-15: Monica De La Cruz (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Monica De La Cruz', 'Monica', 'De La Cruz', 'Republican', true, false, false, true, -100315)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4815' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-16: Veronica Escobar (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Veronica Escobar', 'Veronica', 'Escobar', 'Democrat', true, false, false, true, -100316)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4816' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-17: Pete Sessions (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pete Sessions', 'Pete', 'Sessions', 'Republican', true, false, false, true, -100317)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4817' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-18: Christian Menefee (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christian Menefee', 'Christian', 'Menefee', 'Democrat', true, false, false, true, -100318)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4818' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-19: Jodey Arrington (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jodey Arrington', 'Jodey', 'Arrington', 'Republican', true, false, false, true, -100319)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4819' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-20: Joaquin Castro (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joaquin Castro', 'Joaquin', 'Castro', 'Democrat', true, false, false, true, -100320)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4820' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-21: Chip Roy (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chip Roy', 'Chip', 'Roy', 'Republican', true, false, false, true, -100321)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4821' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-22: Troy Nehls (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Troy Nehls', 'Troy', 'Nehls', 'Republican', true, false, false, true, -100322)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4822' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-23: VACANT — office row only, no politician
-- (Seat vacant as of April 14, 2026; external_id -100323 intentionally unused)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, NULL,
       'Representative', 'TX', false, true
FROM essentials.districts d
WHERE d.geo_id = '4823' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-24: Beth Van Duyne (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Beth Van Duyne', 'Beth', 'Van Duyne', 'Republican', true, false, false, true, -100324)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4824' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-25: Roger Williams (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roger Williams', 'Roger', 'Williams', 'Republican', true, false, false, true, -100325)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4825' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-26: Brandon Gill (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brandon Gill', 'Brandon', 'Gill', 'Republican', true, false, false, true, -100326)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4826' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-27: Michael Cloud (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Cloud', 'Michael', 'Cloud', 'Republican', true, false, false, true, -100327)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4827' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-28: Henry Cuellar (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Henry Cuellar', 'Henry', 'Cuellar', 'Democrat', true, false, false, true, -100328)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4828' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-29: Sylvia Garcia (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sylvia Garcia', 'Sylvia', 'Garcia', 'Democrat', true, false, false, true, -100329)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4829' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-30: Jasmine Crockett (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jasmine Crockett', 'Jasmine', 'Crockett', 'Democrat', true, false, false, true, -100330)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4830' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-31: John Carter (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Carter', 'John', 'Carter', 'Republican', true, false, false, true, -100331)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4831' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-32: Julie Johnson (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julie Johnson', 'Julie', 'Johnson', 'Democrat', true, false, false, true, -100332)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4832' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-33: Marc Veasey (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marc Veasey', 'Marc', 'Veasey', 'Democrat', true, false, false, true, -100333)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4833' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-34: Vicente Gonzalez (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vicente Gonzalez', 'Vicente', 'Gonzalez', 'Democrat', true, false, false, true, -100334)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4834' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-35: Greg Casar (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Greg Casar', 'Greg', 'Casar', 'Democrat', true, false, false, true, -100335)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4835' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-36: Brian Babin (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Babin', 'Brian', 'Babin', 'Republican', true, false, false, true, -100336)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4836' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-37: Lloyd Doggett (D)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lloyd Doggett', 'Lloyd', 'Doggett', 'Democrat', true, false, false, true, -100337)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4837' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

-- TX-38: Wesley Hunt (R)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wesley Hunt', 'Wesley', 'Hunt', 'Republican', true, false, false, true, -100338)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid, p.id,
       'Representative', 'TX', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4838' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'::uuid
  );

COMMIT;
