BEGIN;

-- ===== California State Senate Chamber =====
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'California State Senate',
       'California State Senate',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'California State Senate'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

-- ===== SD-01: Megan Dahle (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Megan Dahle', 'Megan', 'Dahle', 'Republican',
          true, false, false, true, -6001001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06001'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-02: Mike McGuire (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike McGuire', 'Mike', 'McGuire', 'Democrat',
          true, false, false, true, -6001002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06002'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-03: Christopher Cabaldon (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christopher Cabaldon', 'Christopher', 'Cabaldon', 'Democrat',
          true, false, false, true, -6001003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06003'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-04: Marie Alvarado-Gil (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marie Alvarado-Gil', 'Marie', 'Alvarado-Gil', 'Republican',
          true, false, false, true, -6001004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06004'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-05: Jerry McNerney (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jerry McNerney', 'Jerry', 'McNerney', 'Democrat',
          true, false, false, true, -6001005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06005'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-06: Roger Niello (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roger Niello', 'Roger', 'Niello', 'Republican',
          true, false, false, true, -6001006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06006'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-07: Jesse Arreguín (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jesse Arreguín', 'Jesse', 'Arreguín', 'Democrat',
          true, false, false, true, -6001007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06007'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-08: Angelique Ashby (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angelique Ashby', 'Angelique', 'Ashby', 'Democrat',
          true, false, false, true, -6001008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06008'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-09: Tim Grayson (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tim Grayson', 'Tim', 'Grayson', 'Democrat',
          true, false, false, true, -6001009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06009'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-10: Aisha Wahab (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Aisha Wahab', 'Aisha', 'Wahab', 'Democrat',
          true, false, false, true, -6001010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06010'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-11: Scott Wiener (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Scott Wiener', 'Scott', 'Wiener', 'Democrat',
          true, false, false, true, -6001011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06011'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-12: Shannon Grove (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shannon Grove', 'Shannon', 'Grove', 'Republican',
          true, false, false, true, -6001012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06012'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-13: Josh Becker (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Josh Becker', 'Josh', 'Becker', 'Democrat',
          true, false, false, true, -6001013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06013'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-14: Anna Caballero (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anna Caballero', 'Anna', 'Caballero', 'Democrat',
          true, false, false, true, -6001014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06014'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-15: Dave Cortese (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dave Cortese', 'Dave', 'Cortese', 'Democrat',
          true, false, false, true, -6001015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06015'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-16: Melissa Hurtado (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Melissa Hurtado', 'Melissa', 'Hurtado', 'Democrat',
          true, false, false, true, -6001016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06016'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-17: John Laird (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Laird', 'John', 'Laird', 'Democrat',
          true, false, false, true, -6001017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06017'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-18: Steve Padilla (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Padilla', 'Steve', 'Padilla', 'Democrat',
          true, false, false, true, -6001018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06018'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-19: Rosilicie Ochoa Bogh (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rosilicie Ochoa Bogh', 'Rosilicie', 'Ochoa Bogh', 'Republican',
          true, false, false, true, -6001019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06019'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-20: Caroline Menjivar (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Caroline Menjivar', 'Caroline', 'Menjivar', 'Democrat',
          true, false, false, true, -6001020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06020'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-21: Monique Limón (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Monique Limón', 'Monique', 'Limón', 'Democrat',
          true, false, false, true, -6001021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06021'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-22: Susan Rubio (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Susan Rubio', 'Susan', 'Rubio', 'Democrat',
          true, false, false, true, -6001022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06022'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-23: Suzette Martinez Valladares (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Suzette Martinez Valladares', 'Suzette', 'Martinez Valladares', 'Republican',
          true, false, false, true, -6001023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06023'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-24: Benjamin Allen (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Benjamin Allen', 'Benjamin', 'Allen', 'Democrat',
          true, false, false, true, -6001024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06024'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-25: Sasha Renée Pérez (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sasha Renée Pérez', 'Sasha Renée', 'Pérez', 'Democrat',
          true, false, false, true, -6001025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06025'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-26: Maria Elena Durazo (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maria Elena Durazo', 'Maria Elena', 'Durazo', 'Democrat',
          true, false, false, true, -6001026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06026'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-27: Henry Stern (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Henry Stern', 'Henry', 'Stern', 'Democrat',
          true, false, false, true, -6001027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06027'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-28: Lola Smallwood-Cuevas (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lola Smallwood-Cuevas', 'Lola', 'Smallwood-Cuevas', 'Democrat',
          true, false, false, true, -6001028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06028'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-29: Eloise Gómez Reyes (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eloise Gómez Reyes', 'Eloise', 'Gómez Reyes', 'Democrat',
          true, false, false, true, -6001029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06029'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-30: Bob Archuleta (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bob Archuleta', 'Bob', 'Archuleta', 'Democrat',
          true, false, false, true, -6001030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06030'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-31: Sabrina Cervantes (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sabrina Cervantes', 'Sabrina', 'Cervantes', 'Democrat',
          true, false, false, true, -6001031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06031'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-32: Kelly Seyarto (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kelly Seyarto', 'Kelly', 'Seyarto', 'Republican',
          true, false, false, true, -6001032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06032'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-33: Lena Gonzalez (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lena Gonzalez', 'Lena', 'Gonzalez', 'Democrat',
          true, false, false, true, -6001033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06033'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-34: Thomas Umberg (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thomas Umberg', 'Thomas', 'Umberg', 'Democrat',
          true, false, false, true, -6001034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06034'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-35: Laura Richardson (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Laura Richardson', 'Laura', 'Richardson', 'Democrat',
          true, false, false, true, -6001035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06035'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-36: Tony Strickland (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tony Strickland', 'Tony', 'Strickland', 'Republican',
          true, false, false, true, -6001036)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06036'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-37: Steven "Steve" Choi (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steven "Steve" Choi', 'Steven', 'Choi', 'Republican',
          true, false, false, true, -6001037)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06037'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-38: Catherine S. Blakespear (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Catherine S. Blakespear', 'Catherine S.', 'Blakespear', 'Democrat',
          true, false, false, true, -6001038)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06038'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-39: Akilah Weber Pierson (Democrat) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Akilah Weber Pierson', 'Akilah', 'Weber Pierson', 'Democrat',
          true, false, false, true, -6001039)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06039'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== SD-40: Brian W. Jones (Republican) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian W. Jones', 'Brian W.', 'Jones', 'Republican',
          true, false, false, true, -6001040)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'California State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Senator', 'CA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '06040'
  AND d.district_type = 'STATE_UPPER'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'California State Senate'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== office_id back-fill =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -6001040 AND -6001001
  AND p.office_id IS NULL;

COMMIT;