-- Migration 246: Multnomah smaller cities government + chambers + districts + officials + offices
--
-- Purpose: Seeds 5 incorporated Multnomah County cities outside Portland:
--   Gresham    (geo_id='4131250') — 1 gov + 1 chamber + 2 districts + 7 officials + 7 offices
--   Troutdale  (geo_id='4174850') — 1 gov + 1 chamber + 2 districts + 7 officials + 7 offices
--   Fairview   (geo_id='4124250') — 1 gov + 1 chamber + 2 districts + 7 officials + 7 offices
--   Wood Village (geo_id='4183950') — 1 gov + 1 chamber + 2 districts + 5 officials + 5 offices
--   Maywood Park (geo_id='4146730') — 1 gov + 1 chamber + 2 districts + 5 officials + 5 offices
-- Totals: 5 governments, 5 chambers, 10 districts, 31 politicians, 31 offices
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='LOCAL_EXEC' for Mayor; district_type='LOCAL' for council (NOT 'COUNTY').
-- CRITICAL: Gresham is at-large Position 1-6 (research override of CONTEXT.md D-05);
--           NO ward geofences — X0013-X0018 NOT needed.
-- CRITICAL: Wood Village Mayor (-4183951) and Maywood Park Mayor (-4146731) are
--           council-selected — is_appointed=true + is_appointed_position=true on those rows only.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if any city government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name IN (
        'City of Gresham, Oregon, US',
        'City of Troutdale, Oregon, US',
        'City of Fairview, Oregon, US',
        'City of Wood Village, Oregon, US',
        'City of Maywood Park, Oregon, US'
      )) > 0 THEN
    RAISE NOTICE 'One or more city government rows already exist — idempotent re-run';
  END IF;
END $$;


-- =============================================================================
-- GRESHAM (geo_id='4131250')
-- 7 officials: Mayor Travis Stovall + 6 councilors (Position 1-6, at-large)
-- Mayor is directly elected (is_appointed_position=false)
-- =============================================================================

-- Step 1: Government row
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Gresham, Oregon, US',
       'LOCAL', 'OR', 'Gresham', '4131250'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Gresham, Oregon, US'
);

-- Step 2: City Council chamber (slug GENERATED ALWAYS — never include in column list)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Gresham City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Gresham, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Gresham, Oregon, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — citywide)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4131250', 'Gresham (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4131250' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- Step 4: LOCAL at-large district (all 6 councilors share this)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4131250', 'Gresham (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4131250' AND district_type = 'LOCAL' AND state = 'or'
);

-- Step 5: Mayor Travis Stovall (-4131251) — directly elected
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Travis Stovall', 'Travis', 'Stovall', NULL,
          true, false, false, true, -4131251)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Gresham, Oregon, US')),
       p.id,
       'Mayor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4131250'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Council Member Position 1 Kayla Brown (-4131252)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kayla Brown', 'Kayla', 'Brown', NULL,
          true, false, false, true, -4131252)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Gresham, Oregon, US')),
       p.id,
       'Council Member (Position 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4131250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Council Member Position 2 Eddy Morales (-4131253)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eddy Morales', 'Eddy', 'Morales', NULL,
          true, false, false, true, -4131253)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Gresham, Oregon, US')),
       p.id,
       'Council Member (Position 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4131250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Council Member Position 3 Cathy Keathley (-4131254)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cathy Keathley', 'Cathy', 'Keathley', NULL,
          true, false, false, true, -4131254)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Gresham, Oregon, US')),
       p.id,
       'Council Member (Position 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4131250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Council Member Position 4 Jerry Hinton (-4131255)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jerry Hinton', 'Jerry', 'Hinton', NULL,
          true, false, false, true, -4131255)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Gresham, Oregon, US')),
       p.id,
       'Council Member (Position 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4131250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: Council Member Position 5 Sue Piazza (-4131256)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sue Piazza', 'Sue', 'Piazza', NULL,
          true, false, false, true, -4131256)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Gresham, Oregon, US')),
       p.id,
       'Council Member (Position 5)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4131250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 11: Council Member Position 6 Janine Gladfelter (-4131257)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janine Gladfelter', 'Janine', 'Gladfelter', NULL,
          true, false, false, true, -4131257)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Gresham, Oregon, US')),
       p.id,
       'Council Member (Position 6)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4131250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );


-- =============================================================================
-- TROUTDALE (geo_id='4174850')
-- 7 officials: Mayor David Ripma + 6 City Councilors (at-large, no position numbers)
-- Mayor is directly elected (is_appointed_position=false)
-- =============================================================================

-- Step 1: Government row
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Troutdale, Oregon, US',
       'LOCAL', 'OR', 'Troutdale', '4174850'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Troutdale, Oregon, US'
);

-- Step 2: City Council chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Troutdale City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Troutdale, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Troutdale, Oregon, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — citywide)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4174850', 'Troutdale (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4174850' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- Step 4: LOCAL at-large district (all 6 councilors share this)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4174850', 'Troutdale (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4174850' AND district_type = 'LOCAL' AND state = 'or'
);

-- Step 5: Mayor David Ripma (-4174851) — directly elected
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Ripma', 'David', 'Ripma', NULL,
          true, false, false, true, -4174851)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Troutdale, Oregon, US')),
       p.id,
       'Mayor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174850'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: City Councilor Carol Allen (-4174852)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carol Allen', 'Carol', 'Allen', NULL,
          true, false, false, true, -4174852)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Troutdale, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: City Councilor Jesse Davidson (-4174853)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jesse Davidson', 'Jesse', 'Davidson', NULL,
          true, false, false, true, -4174853)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Troutdale, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: City Councilor John Leamy (-4174854)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Leamy', 'John', 'Leamy', NULL,
          true, false, false, true, -4174854)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Troutdale, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: City Councilor Glenn White (-4174855)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Glenn White', 'Glenn', 'White', NULL,
          true, false, false, true, -4174855)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Troutdale, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: City Councilor Geoffrey Wunn (-4174856)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Geoffrey Wunn', 'Geoffrey', 'Wunn', NULL,
          true, false, false, true, -4174856)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Troutdale, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 11: City Councilor Zach Andrews (-4174857)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Zach Andrews', 'Zach', 'Andrews', NULL,
          true, false, false, true, -4174857)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Troutdale, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );


-- =============================================================================
-- FAIRVIEW (geo_id='4124250')
-- 7 officials: Mayor Keith Kudrna + 6 councilors (Position 1-6, at-large)
-- Mayor is directly elected (is_appointed_position=false)
-- NOTE: E'an Todd's apostrophe is escaped as '' (doubled ASCII apostrophe U+0027)
-- =============================================================================

-- Step 1: Government row
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Fairview, Oregon, US',
       'LOCAL', 'OR', 'Fairview', '4124250'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Fairview, Oregon, US'
);

-- Step 2: City Council chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Fairview City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Fairview, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Fairview, Oregon, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — citywide)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4124250', 'Fairview (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4124250' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- Step 4: LOCAL at-large district (all 6 councilors share this)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4124250', 'Fairview (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4124250' AND district_type = 'LOCAL' AND state = 'or'
);

-- Step 5: Mayor Keith Kudrna (-4124251) — directly elected
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Keith Kudrna', 'Keith', 'Kudrna', NULL,
          true, false, false, true, -4124251)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Fairview, Oregon, US')),
       p.id,
       'Mayor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4124250'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Council Member Position 1 Jeff Dennerline (-4124252)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeff Dennerline', 'Jeff', 'Dennerline', NULL,
          true, false, false, true, -4124252)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Fairview, Oregon, US')),
       p.id,
       'Council Member (Position 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4124250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Council Member Position 2 Steve Marker (-4124253)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Marker', 'Steve', 'Marker', NULL,
          true, false, false, true, -4124253)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Fairview, Oregon, US')),
       p.id,
       'Council Member (Position 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4124250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Council Member Position 3 E'an Todd (-4124254)
-- PITFALL 7: apostrophe in E'an must be escaped as '' (doubled ASCII apostrophe U+0027)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'E''an Todd', 'E''an', 'Todd', NULL,
          true, false, false, true, -4124254)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Fairview, Oregon, US')),
       p.id,
       'Council Member (Position 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4124250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Council Member Position 4 Jenni Weber (-4124255)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jenni Weber', 'Jenni', 'Weber', NULL,
          true, false, false, true, -4124255)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Fairview, Oregon, US')),
       p.id,
       'Council Member (Position 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4124250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: Council Member Position 5 Steve Owen (-4124256)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Owen', 'Steve', 'Owen', NULL,
          true, false, false, true, -4124256)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Fairview, Oregon, US')),
       p.id,
       'Council Member (Position 5)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4124250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 11: Council Member Position 6 Paul Copeland (-4124257)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Copeland', 'Paul', 'Copeland', NULL,
          true, false, false, true, -4124257)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Fairview, Oregon, US')),
       p.id,
       'Council Member (Position 6)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4124250'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );


-- =============================================================================
-- WOOD VILLAGE (geo_id='4183950')
-- 5 officials: Mayor Jairo Rios-Campos (council-selected) + 4 councilors (at-large)
-- Mayor: is_appointed=true, is_appointed_position=true (chosen by council)
-- Charlene Gothard: is_appointed=true (appointed to fill vacancy)
-- =============================================================================

-- Step 1: Government row
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Wood Village, Oregon, US',
       'LOCAL', 'OR', 'Wood Village', '4183950'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Wood Village, Oregon, US'
);

-- Step 2: City Council chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Wood Village City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Wood Village, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Wood Village, Oregon, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — citywide)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4183950', 'Wood Village (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4183950' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- Step 4: LOCAL at-large district (all 4 councilors share this)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4183950', 'Wood Village (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4183950' AND district_type = 'LOCAL' AND state = 'or'
);

-- Step 5: Mayor Jairo Rios-Campos (-4183951) — council-selected
-- is_appointed=true on politician; is_appointed_position=true on office
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jairo Rios-Campos', 'Jairo', 'Rios-Campos', NULL,
          true, true, false, true, -4183951)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Wood Village, Oregon, US')),
       p.id,
       'Mayor', 'OR', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4183950'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Council President Dara Tan (-4183952) — elected at-large
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dara Tan', 'Dara', 'Tan', NULL,
          true, false, false, true, -4183952)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Wood Village, Oregon, US')),
       p.id,
       'Council President', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4183950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: City Councilor John Miner (-4183953)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Miner', 'John', 'Miner', NULL,
          true, false, false, true, -4183953)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Wood Village, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4183950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: City Councilor Charlene Gothard (-4183954) — appointed to fill vacancy
-- is_appointed=true on politician row; is_appointed_position=false (council seat, not Mayor)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charlene Gothard', 'Charlene', 'Gothard', NULL,
          true, true, false, true, -4183954)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Wood Village, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4183950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: City Councilor Patricia Smith (-4183955)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Patricia Smith', 'Patricia', 'Smith', NULL,
          true, false, false, true, -4183955)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Wood Village, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4183950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );


-- =============================================================================
-- MAYWOOD PARK (geo_id='4146730')
-- 5 officials: Mayor Jim Akers (council-selected) + Council President + 3 councilors (at-large)
-- Mayor: is_appointed=true, is_appointed_position=true (chosen by council)
-- =============================================================================

-- Step 1: Government row
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Maywood Park, Oregon, US',
       'LOCAL', 'OR', 'Maywood Park', '4146730'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Maywood Park, Oregon, US'
);

-- Step 2: City Council chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Maywood Park City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Maywood Park, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Maywood Park, Oregon, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — citywide)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4146730', 'Maywood Park (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4146730' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- Step 4: LOCAL at-large district (all councilors share this)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4146730', 'Maywood Park (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4146730' AND district_type = 'LOCAL' AND state = 'or'
);

-- Step 5: Mayor Jim Akers (-4146731) — council-selected
-- is_appointed=true on politician; is_appointed_position=true on office
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jim Akers', 'Jim', 'Akers', NULL,
          true, true, false, true, -4146731)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Maywood Park, Oregon, US')),
       p.id,
       'Mayor', 'OR', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4146730'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Council President Kevin Bussema (-4146732)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Bussema', 'Kevin', 'Bussema', NULL,
          true, false, false, true, -4146732)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Maywood Park, Oregon, US')),
       p.id,
       'Council President', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4146730'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: City Councilor Jeff Baltzell (-4146733)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeff Baltzell', 'Jeff', 'Baltzell', NULL,
          true, false, false, true, -4146733)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Maywood Park, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4146730'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: City Councilor Miriam Berman (-4146734)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Miriam Berman', 'Miriam', 'Berman', NULL,
          true, false, false, true, -4146734)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Maywood Park, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4146730'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: City Councilor Thomas Welander (-4146735)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thomas Welander', 'Thomas', 'Welander', NULL,
          true, false, false, true, -4146735)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Maywood Park, Oregon, US')),
       p.id,
       'City Councilor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4146730'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );


-- =============================================================================
-- office_id back-fill (all 31 officials across all 5 cities)
-- Explicit IN list — NOT BETWEEN — because the 5 ranges are non-contiguous
-- WHERE p.office_id IS NULL for idempotency
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -4131251,-4131252,-4131253,-4131254,-4131255,-4131256,-4131257,
    -4174851,-4174852,-4174853,-4174854,-4174855,-4174856,-4174857,
    -4124251,-4124252,-4124253,-4124254,-4124255,-4124256,-4124257,
    -4183951,-4183952,-4183953,-4183954,-4183955,
    -4146731,-4146732,-4146733,-4146734,-4146735
  )
  AND p.office_id IS NULL;


-- =============================================================================
-- Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction
-- Gates:
--   (a) Per-city government count = 1 (5 checks)
--   (b) Per-city office count = 7 (Gresham/Troutdale/Fairview) or 5 (Wood Village/Maywood Park)
--   (c) Section-split check across all 5 G4110 geo_ids = 0 orphans
--   (d) office_id back-fill check = 0 nulls
-- =============================================================================
DO $$
DECLARE
  v_gov_count    INTEGER;
  v_office_count INTEGER;
  v_split_count  INTEGER;
  v_null_count   INTEGER;
BEGIN

  -- Gate (a1): Gresham government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Gresham, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Gresham gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b1): Gresham offices linked to LOCAL/LOCAL_EXEC districts
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4131250' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Gresham office_count=%, expected 7', v_office_count;
  END IF;

  -- Gate (a2): Troutdale government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Troutdale, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Troutdale gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b2): Troutdale offices
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4174850' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Troutdale office_count=%, expected 7', v_office_count;
  END IF;

  -- Gate (a3): Fairview government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Fairview, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Fairview gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b3): Fairview offices
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4124250' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Fairview office_count=%, expected 7', v_office_count;
  END IF;

  -- Gate (a4): Wood Village government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Wood Village, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Wood Village gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b4): Wood Village offices
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4183950' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Wood Village office_count=%, expected 5', v_office_count;
  END IF;

  -- Gate (a5): Maywood Park government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Maywood Park, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Maywood Park gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b5): Maywood Park offices
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4146730' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Maywood Park office_count=%, expected 5', v_office_count;
  END IF;

  -- Gate (c): Section-split check — all 5 G4110 geo_ids must have LOCAL and LOCAL_EXEC district rows
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id IN ('4131250','4174850','4124250','4183950','4146730')
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
        AND d.state = 'or'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows', v_split_count;
  END IF;

  -- Gate (d): office_id back-fill — all 31 politicians must have non-null office_id
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4131251,-4131252,-4131253,-4131254,-4131255,-4131256,-4131257,
    -4174851,-4174852,-4174853,-4174854,-4174855,-4174856,-4174857,
    -4124251,-4124252,-4124253,-4124254,-4124255,-4124256,-4124257,
    -4183951,-4183952,-4183953,-4183954,-4183955,
    -4146731,-4146732,-4146733,-4146734,-4146735
  )
  AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: all 5 city gates OK, section-split=0, office_id back-fill complete';
END $$;


-- =============================================================================
-- Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('246')
ON CONFLICT (version) DO NOTHING;

COMMIT;
