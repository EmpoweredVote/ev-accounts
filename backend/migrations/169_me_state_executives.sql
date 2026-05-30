-- Migration 169: ME State Executives (Governor, AG, SoS, Treasurer)
--
-- Seeds the 4 Maine statewide executives (Mills, Frey, Bellows, Perry) with
-- districts, politicians, and offices. Uses existing chambers from Phase 50
-- migration 168 — DOES NOT create any chambers.
--
-- AG, SoS, and Treasurer are legislature-elected in Maine (Joint Convention
-- elects each every 2 years). Modeled as is_appointed_position=true; no
-- election_races rows ever created for these offices.
--
-- Governor is elected by voters statewide. Modeled as is_appointed_position=false.
-- Governor Mills is term-limited; her re-election is NOT in this migration.
--
-- All inserts are idempotent (WHERE NOT EXISTS / ON CONFLICT) — safe to re-run.
--
-- CRITICAL:
-- - Treasurer = Joseph C. Perry (NOT Henry Beck; Beck left office 2025-01-06)
-- - state='ME' uppercase for STATE_EXEC
-- - chambers ALREADY EXIST from Phase 50 — only lookups, never inserts
-- - role_canonical column already exists (Phase 40 migration 154); no ALTER TABLE
-- - NO election_races rows
--
-- Maine FIPS = 23; State of Maine government UUID: da88de8b-9afa-4d87-86d5-7eb83c3e9792
--   (but use subquery by name in all references)

BEGIN;

-- ===== STEP 1: Create 4 STATE_EXEC districts (one per executive office) =====
-- state='ME' uppercase, geo_id='23' (Maine FIPS), distinct labels matching chamber names.

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'ME', '23', 'Maine Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'ME' AND label = 'Maine Governor'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'ME', '23', 'Maine Attorney General', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'ME' AND label = 'Maine Attorney General'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'ME', '23', 'Maine Secretary of State', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'ME' AND label = 'Maine Secretary of State'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'ME', '23', 'Maine Treasurer', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'ME' AND label = 'Maine Treasurer'
);

-- ===== STEP 2: Politicians + Offices (one CTE per executive) =====
-- All 4 are Democrats (confirmed from maine.gov pages). All is_incumbent=true, is_active=true.
-- Office title = the official role text.
-- is_appointed_position=true for AG/SoS/Treasurer; false for Governor.
-- role_canonical NULL for all 4 (cross-state mapping deferred).

-- ----- Governor: Janet T. Mills (-230001) — ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janet T. Mills', 'Janet', 'Mills', 'Democrat',
          true, false, false, true, -230001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Maine Governor'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')),
       p.id,
       'Governor', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'ME' AND d.label = 'Maine Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Maine Governor'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine'))
  );

-- ----- Attorney General: Aaron M. Frey (-230002) — LEGISLATURE-ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Aaron M. Frey', 'Aaron', 'Frey', 'Democrat',
          true, true, false, true, -230002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Maine Attorney General'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')),
       p.id,
       'Attorney General', 'ME', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'ME' AND d.label = 'Maine Attorney General'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Maine Attorney General'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine'))
  );

-- ----- Secretary of State: Shenna Bellows (-230003) — LEGISLATURE-ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shenna Bellows', 'Shenna', 'Bellows', 'Democrat',
          true, true, false, true, -230003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Maine Secretary of State'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')),
       p.id,
       'Secretary of State', 'ME', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'ME' AND d.label = 'Maine Secretary of State'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Maine Secretary of State'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine'))
  );

-- ----- Treasurer: Joseph C. Perry (-230004) — LEGISLATURE-ELECTED -----
-- CRITICAL: Henry Beck left office 2025-01-06. Joseph C. Perry is current.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joseph C. Perry', 'Joseph', 'Perry', 'Democrat',
          true, true, false, true, -230004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Maine Treasurer'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')),
       p.id,
       'Treasurer', 'ME', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'ME' AND d.label = 'Maine Treasurer'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Maine Treasurer'
                            AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine'))
  );

-- ===== STEP 3: office_id back-fill =====
-- Same pattern as migration 107 (TX) and 154 (MA). Scoped to -230010..-230001.
-- Guard with p.office_id IS NULL for idempotency.

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -230010 AND -230001
  AND p.office_id IS NULL;

COMMIT;
