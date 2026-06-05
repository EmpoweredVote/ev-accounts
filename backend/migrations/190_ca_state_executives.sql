-- Migration 190: CA State Executives (8 Constitutional Officers)
--
-- Seeds all 8 currently-serving California constitutional officers as politicians
-- with linked office rows and STATE_EXEC districts. Uses existing chambers from
-- Phase 59-01 migration 189 — DOES NOT create any chambers.
--
-- ALL 8 CA constitutional officers are popularly elected statewide.
-- Modeled as is_appointed=false, is_appointed_position=false for all.
--
-- All inserts are idempotent (WHERE NOT EXISTS / ON CONFLICT) — safe to re-run.
--
-- CRITICAL:
-- - Chamber names use SHORT form (no "California" prefix): "Governor", "Attorney General", etc.
-- - state='CA' UPPERCASE for STATE_EXEC districts
-- - geo_id='06' (California FIPS)
-- - Never hardcode government UUID — always subquery by name
-- - is_appointed=false and is_appointed_position=false for ALL 8 (all are voter-elected)
--
-- CA FIPS = 06; executive external_id range = -06000101 to -06000108
-- CA government UUID: e0f33bda-bfb5-4dd0-9816-576e6ce35fac
--   (use subquery by name in all references, not hardcoded UUID)
--
-- Officers seeded:
--   -06000101: Gavin C. Newsom — Governor
--   -06000102: Eleni Kounalakis — Lieutenant Governor
--   -06000103: Rob Bonta — Attorney General
--   -06000104: Shirley N. Weber — Secretary of State
--   -06000105: Malia M. Cohen — Controller
--   -06000106: Fiona Ma — Treasurer
--   -06000107: Ricardo Lara — Insurance Commissioner
--   -06000108: Tony Thurmond — Superintendent of Public Instruction

BEGIN;

-- ===== STEP 1: 8 STATE_EXEC districts (one per executive office) =====
-- state='CA' uppercase, geo_id='06' (California FIPS), distinct labels.
-- district_id and mtfcc are empty strings (no TIGER district subdivision needed).

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'CA', '06', 'California Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'CA' AND label = 'California Governor'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'CA', '06', 'California Lieutenant Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'CA' AND label = 'California Lieutenant Governor'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'CA', '06', 'California Attorney General', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'CA' AND label = 'California Attorney General'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'CA', '06', 'California Secretary of State', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'CA' AND label = 'California Secretary of State'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'CA', '06', 'California Controller', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'CA' AND label = 'California Controller'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'CA', '06', 'California Treasurer', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'CA' AND label = 'California Treasurer'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'CA', '06', 'California Insurance Commissioner', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'CA' AND label = 'California Insurance Commissioner'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'CA', '06', 'California Superintendent of Public Instruction', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'CA' AND label = 'California Superintendent of Public Instruction'
);

-- ===== STEP 2: Politicians + Offices (one CTE per executive) =====
-- All 8: party='Democrat', is_active=true, is_appointed=false, is_vacant=false, is_incumbent=true
-- All 8 offices: is_appointed_position=false, role_canonical=NULL, representing_state='CA'
-- Chamber lookup uses SHORT name (no "California" prefix) — CRITICAL

-- ----- Governor: Gavin C. Newsom (-06000101) — POPULARLY ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gavin C. Newsom', 'Gavin', 'Newsom', 'Democrat',
          true, false, false, true, -6000101)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Governor'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Governor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'CA' AND d.label = 'California Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Governor'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ----- Lieutenant Governor: Eleni Kounalakis (-06000102) — POPULARLY ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eleni Kounalakis', 'Eleni', 'Kounalakis', 'Democrat',
          true, false, false, true, -6000102)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Lieutenant Governor'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Lieutenant Governor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'CA' AND d.label = 'California Lieutenant Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Lieutenant Governor'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ----- Attorney General: Rob Bonta (-06000103) — POPULARLY ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rob Bonta', 'Rob', 'Bonta', 'Democrat',
          true, false, false, true, -6000103)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Attorney General'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Attorney General', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'CA' AND d.label = 'California Attorney General'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Attorney General'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ----- Secretary of State: Shirley N. Weber (-06000104) — POPULARLY ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shirley N. Weber', 'Shirley', 'Weber', 'Democrat',
          true, false, false, true, -6000104)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Secretary of State'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Secretary of State', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'CA' AND d.label = 'California Secretary of State'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Secretary of State'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ----- Controller: Malia M. Cohen (-06000105) — POPULARLY ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Malia M. Cohen', 'Malia', 'Cohen', 'Democrat',
          true, false, false, true, -6000105)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Controller'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Controller', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'CA' AND d.label = 'California Controller'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Controller'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ----- Treasurer: Fiona Ma (-06000106) — POPULARLY ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Fiona Ma', 'Fiona', 'Ma', 'Democrat',
          true, false, false, true, -6000106)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Treasurer'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Treasurer', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'CA' AND d.label = 'California Treasurer'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Treasurer'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ----- Insurance Commissioner: Ricardo Lara (-06000107) — POPULARLY ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ricardo Lara', 'Ricardo', 'Lara', 'Democrat',
          true, false, false, true, -6000107)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Commissioner of Insurance'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Insurance Commissioner', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'CA' AND d.label = 'California Insurance Commissioner'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Commissioner of Insurance'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ----- Superintendent of Public Instruction: Tony Thurmond (-06000108) — POPULARLY ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tony Thurmond', 'Tony', 'Thurmond', 'Democrat',
          true, false, false, true, -6000108)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Superintendent of Public Instruction'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')),
       p.id,
       'Superintendent of Public Instruction', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'CA' AND d.label = 'California Superintendent of Public Instruction'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Superintendent of Public Instruction'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California'))
  );

-- ===== STEP 3: office_id back-fill =====
-- Same pattern as migration 169 (ME) and 107 (TX). Scoped to CA exec range.
-- Guard with p.office_id IS NULL for idempotency.

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -6000108 AND -6000101
  AND p.office_id IS NULL;

COMMIT;
