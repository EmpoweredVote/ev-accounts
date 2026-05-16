-- Migration 154: MA State Executives + role_canonical column + NATIONAL_UPPER district
--
-- Seeds the 6 Massachusetts statewide executives (Healey, Driscoll, Campbell,
-- Goldberg, DiZoglio, Galvin) with chambers, districts, politicians, and offices.
-- Adds the role_canonical column to offices for cross-state role queries.
-- Creates the MA NATIONAL_UPPER district for Plan 40-02 senators.
--
-- All inserts are idempotent (WHERE NOT EXISTS / ON CONFLICT) — safe to re-run.
--
-- Government UUID: 85783e20-3031-4d71-89a5-5dd61f4a593f (Commonwealth of Massachusetts)
--
-- CRITICAL:
-- - external_id -200002 is SKIPPED (already taken by Curren D. Price Jr., CA)
-- - state='MA' uppercase for STATE_EXEC and NATIONAL_UPPER
-- - slug is GENERATED on chambers — never insert it
-- - role_canonical column is added BEFORE the office inserts that use it

BEGIN;

-- ===== STEP 1: Add role_canonical column to offices =====
ALTER TABLE essentials.offices
ADD COLUMN IF NOT EXISTS role_canonical TEXT DEFAULT NULL;

-- ===== STEP 2: Create MA NATIONAL_UPPER district (shared by Warren + Markey in Plan 40-02) =====
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'MA', '25', 'Massachusetts', 'Massachusetts', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'NATIONAL_UPPER' AND state = 'MA'
);

-- ===== STEP 3: Create 6 STATE_EXEC districts (one per executive office) =====
-- All use state='MA' uppercase, geo_id='25' (MA FIPS), distinct labels matching chamber names.

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MA', '25', 'Massachusetts Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MA' AND label = 'Massachusetts Governor'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MA', '25', 'Massachusetts Lieutenant Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MA' AND label = 'Massachusetts Lieutenant Governor'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MA', '25', 'Massachusetts Attorney General', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MA' AND label = 'Massachusetts Attorney General'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MA', '25', 'Massachusetts Treasurer and Receiver-General', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MA' AND label = 'Massachusetts Treasurer and Receiver-General'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MA', '25', 'Massachusetts Auditor of the Commonwealth', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MA' AND label = 'Massachusetts Auditor of the Commonwealth'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MA', '25', 'Massachusetts Secretary of the Commonwealth', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MA' AND label = 'Massachusetts Secretary of the Commonwealth'
);

-- ===== STEP 4: Create 6 executive chambers =====
-- Pattern: "Massachusetts {Role}" — name and name_formal are identical.
-- All link to government_id = 85783e20-3031-4d71-89a5-5dd61f4a593f.
-- slug is a GENERATED column — do NOT insert it.

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Massachusetts Governor', 'Massachusetts Governor', '85783e20-3031-4d71-89a5-5dd61f4a593f'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Massachusetts Governor' AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Massachusetts Lieutenant Governor', 'Massachusetts Lieutenant Governor', '85783e20-3031-4d71-89a5-5dd61f4a593f'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Massachusetts Lieutenant Governor' AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Massachusetts Attorney General', 'Massachusetts Attorney General', '85783e20-3031-4d71-89a5-5dd61f4a593f'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Massachusetts Attorney General' AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Massachusetts Treasurer and Receiver-General', 'Massachusetts Treasurer and Receiver-General', '85783e20-3031-4d71-89a5-5dd61f4a593f'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Massachusetts Treasurer and Receiver-General' AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Massachusetts Auditor of the Commonwealth', 'Massachusetts Auditor of the Commonwealth', '85783e20-3031-4d71-89a5-5dd61f4a593f'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Massachusetts Auditor of the Commonwealth' AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Massachusetts Secretary of the Commonwealth', 'Massachusetts Secretary of the Commonwealth', '85783e20-3031-4d71-89a5-5dd61f4a593f'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Massachusetts Secretary of the Commonwealth' AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'
);

-- ===== STEP 5: Politicians + Offices (one CTE per executive) =====
-- All 6 executives are Democrat (confirmed from mass.gov). All is_incumbent=true, is_active=true.
-- Office title = the official role text (matches chamber name without "Massachusetts " prefix).
-- role_canonical set only for Secretary + Treasurer per CONTEXT.md decision.

-- ----- Governor: Maura Healey (-200001) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maura Healey', 'Maura', 'Healey', 'Democrat',
          true, false, false, true, -200001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Governor'
          AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'),
       p.id,
       'Governor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MA' AND d.label = 'Massachusetts Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Governor'
                            AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f')
  );

-- ----- Lieutenant Governor: Kim Driscoll (-200003) -----
-- (Note: -200002 is SKIPPED — already taken by Curren D. Price Jr.)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kim Driscoll', 'Kim', 'Driscoll', 'Democrat',
          true, false, false, true, -200003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Lieutenant Governor'
          AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'),
       p.id,
       'Lieutenant Governor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MA' AND d.label = 'Massachusetts Lieutenant Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Lieutenant Governor'
                            AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f')
  );

-- ----- Attorney General: Andrea Joy Campbell (-200004) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andrea Joy Campbell', 'Andrea', 'Campbell', 'Democrat',
          true, false, false, true, -200004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Attorney General'
          AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'),
       p.id,
       'Attorney General', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MA' AND d.label = 'Massachusetts Attorney General'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Attorney General'
                            AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f')
  );

-- ----- Treasurer and Receiver-General: Deborah B. Goldberg (-200005) — role_canonical='treasurer' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Deborah B. Goldberg', 'Deborah', 'Goldberg', 'Democrat',
          true, false, false, true, -200005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Treasurer and Receiver-General'
          AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'),
       p.id,
       'Treasurer and Receiver-General', 'MA', false, false, 'treasurer'
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MA' AND d.label = 'Massachusetts Treasurer and Receiver-General'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Treasurer and Receiver-General'
                            AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f')
  );

-- ----- Auditor of the Commonwealth: Diana DiZoglio (-200006) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Diana DiZoglio', 'Diana', 'DiZoglio', 'Democrat',
          true, false, false, true, -200006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Auditor of the Commonwealth'
          AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'),
       p.id,
       'Auditor of the Commonwealth', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MA' AND d.label = 'Massachusetts Auditor of the Commonwealth'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Auditor of the Commonwealth'
                            AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f')
  );

-- ----- Secretary of the Commonwealth: William Francis Galvin (-200007) — role_canonical='secretary_of_state' -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'William Francis Galvin', 'William', 'Galvin', 'Democrat',
          true, false, false, true, -200007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Secretary of the Commonwealth'
          AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'),
       p.id,
       'Secretary of the Commonwealth', 'MA', false, false, 'secretary_of_state'
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MA' AND d.label = 'Massachusetts Secretary of the Commonwealth'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'Massachusetts Secretary of the Commonwealth'
                            AND government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f')
  );

-- ===== STEP 6: office_id back-fill =====
-- Same pattern as migration 107 (TX). Scoped to external_id range -200010..-200001
-- which includes all 6 executives (-200001, -200003..-200007) plus headroom.
-- Guard with p.office_id IS NULL for idempotency.

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -200010 AND -200001
  AND p.office_id IS NULL;

COMMIT;
