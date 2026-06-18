-- Migration 347: City of Boston government (MA-DEEP-01)
--
-- Purpose: Seeds City of Boston government and City Council.
--   - 1 government row: 'City of Boston, Massachusetts, US' (type='LOCAL', state='MA', city='Boston', geo_id='2507000')
--   - 1 chamber row: 'City Council' (name_formal='Boston City Council'; no slug — GENERATED ALWAYS)
--   - 1 LOCAL_EXEC district row: geo_id='2507000', mtfcc=NULL, state='ma', label='Boston (Citywide)' (Mayor)
--   - 1 LOCAL district row (at-large): geo_id='2507000', mtfcc=NULL, state='ma', label='Boston (At-Large)' (4 at-large councillors)
--   - 9 LOCAL district rows (per-district): geo_id='boston-ma-council-district-{N}', mtfcc='X0013', state='ma', label='District N'
--   - 14 politicians: Mayor Wu (-2507000001) + 4 at-large councillors (-2507000002..-2507000005) + 9 district councillors (-2507000006..-2507000014)
--   - 14 offices: Mayor links to LOCAL_EXEC; 4 at-large to LOCAL at-large; 9 district councillors to per-district LOCAL rows
--   - office_id back-fill on all 14 politicians
--
-- X0013 geofences loaded by load-boston-council-boundaries.ts — MUST run BEFORE this migration.
-- Boston geo_id='2507000' (G4110) already in geofence_boundaries (v5.0) — do NOT re-insert.
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state = 'ma' (lowercase) for LOCAL, LOCAL_EXEC — matches routing queries.
-- CRITICAL: governments.state = 'MA' (uppercase) — government table convention.
-- CRITICAL: offices.representing_state = 'MA' (uppercase) — offices table convention.
-- CRITICAL: mtfcc=NULL on LOCAL_EXEC and LOCAL at-large district rows only.
-- CRITICAL: mtfcc='X0013' on the 9 per-district LOCAL rows.
-- CRITICAL: party=NULL (antipartisan design — D-15).
-- CRITICAL: is_appointed=false for all 14 (Mayor + councillors are popularly elected — D-16).
--
-- Roster verified 2026-06-10 from boston.gov/departments/city-council:
--   Mayor Michelle Wu (LOCAL_EXEC)
--   At-Large: Ruthzee Louijeune, Julia M. Mejia, Erin J. Murphy, Henry Santana
--   District 1: Gabriela Coletta Zapata
--   District 2: Edward M. Flynn
--   District 3: John FitzGerald
--   District 4: Brian Worrell
--   District 5: Enrique J. Pepén (NOTE: é accent preserved — Pitfall 6)
--   District 6: Benjamin J. Weber
--   District 7: Miniard Culpepper
--   District 8: Sharon Durkan
--   District 9: Liz Breadon (Council President — procedural title; office title='City Councillor' per A1)
--
-- Applied to production via _apply-migration-347.ts.

-- =============================================================================
-- Pre-flight 1: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Boston, Massachusetts, US') > 0 THEN
    RAISE NOTICE 'City of Boston government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Assert Boston G4110 geofence is present (D-18 — do NOT re-insert)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2507000' AND mtfcc = 'G4110';
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Boston G4110 geofence (geo_id=2507000) not found. Expected from Phase 38 MA TIGER load.';
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: Boston G4110 geofence present';
END $$;

-- =============================================================================
-- Pre-flight 3: Assert 9 X0013 council-district geofences are loaded
-- (Must run load-boston-council-boundaries.ts before this migration — Pitfall 4)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'boston-ma-council-district-%' AND mtfcc = 'X0013';
  IF v_count < 9 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 9 X0013 boston-ma-council-district-* rows, found %. Run load-boston-council-boundaries.ts first.', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: % X0013 council-district geofences present', v_count;
END $$;

-- =============================================================================
-- Pre-flight 4: Assert external_id range -2507000001..-2507000014 is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -2507000014 AND -2507000001;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -2507000001..-2507000014 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 4 PASSED: external_id range is clear';
END $$;

-- =============================================================================
-- Step 1: Government row (City of Boston, Massachusetts, US)
-- type='LOCAL', state='MA' (uppercase), city='Boston', geo_id='2507000'
-- WHERE NOT EXISTS guard — governments has no unique constraint on geo_id (D-14).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Boston, Massachusetts, US',
       'LOCAL', 'MA', 'Boston', '2507000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Boston, Massachusetts, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- Single chamber covers all 13 seats (4 at-large + 9 district) — Cambridge pattern.
-- election_method not set (chamber covers mixed at-large/FPTP seats; D-06 per-office).
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list (D-13).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Boston City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Boston, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Boston, Massachusetts, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district (Mayor Wu — citywide)
-- geo_id='2507000' matches existing G4110 geofence_boundary.
-- state='ma' LOWERCASE (D-10 — routing query convention).
-- mtfcc=NULL — no TIGER mtfcc for LOCAL_EXEC districts (D-12).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'ma', '2507000', 'Boston (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2507000' AND district_type = 'LOCAL_EXEC' AND state = 'ma'
);

-- =============================================================================
-- Step 3b: LOCAL district — at-large (4 at-large councillors share this)
-- mtfcc=NULL — no TIGER mtfcc for LOCAL at-large districts (D-12).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', '2507000', 'Boston (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2507000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 3c: LOCAL per-district rows (9 districts, one per council district)
-- geo_id = 'boston-ma-council-district-{N}'
-- mtfcc = 'X0013' — references geofences loaded by load-boston-council-boundaries.ts
-- state = 'ma' LOWERCASE (D-10)
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'boston-ma-council-district-1', 'District 1', 'X0013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'boston-ma-council-district-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'boston-ma-council-district-2', 'District 2', 'X0013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'boston-ma-council-district-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'boston-ma-council-district-3', 'District 3', 'X0013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'boston-ma-council-district-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'boston-ma-council-district-4', 'District 4', 'X0013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'boston-ma-council-district-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'boston-ma-council-district-5', 'District 5', 'X0013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'boston-ma-council-district-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'boston-ma-council-district-6', 'District 6', 'X0013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'boston-ma-council-district-6' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'boston-ma-council-district-7', 'District 7', 'X0013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'boston-ma-council-district-7' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'boston-ma-council-district-8', 'District 8', 'X0013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'boston-ma-council-district-8' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'boston-ma-council-district-9', 'District 9', 'X0013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'boston-ma-council-district-9' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (14 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design — D-15)
-- is_appointed=false, is_appointed_position=false (all popularly elected — D-16)
-- representing_state='MA' uppercase (D-11)
-- Mayor links to LOCAL_EXEC district; at-large councillors to LOCAL at-large district;
-- district councillors each link to their per-district LOCAL row.
-- =============================================================================

-- BLOCK 1: Mayor Michelle Wu (-2507000001) — links to LOCAL_EXEC district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michelle Wu', 'Michelle', 'Wu', NULL,
          true, false, false, true, -2507000001)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'Mayor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507000'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: At-Large Councillor Ruthzee Louijeune (-2507000002) — links to LOCAL at-large district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ruthzee Louijeune', 'Ruthzee', 'Louijeune', NULL,
          true, false, false, true, -2507000002)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: At-Large Councillor Julia M. Mejia (-2507000003) — links to LOCAL at-large district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julia M. Mejia', 'Julia', 'Mejia', NULL,
          true, false, false, true, -2507000003)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: At-Large Councillor Erin J. Murphy (-2507000004) — links to LOCAL at-large district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Erin J. Murphy', 'Erin', 'Murphy', NULL,
          true, false, false, true, -2507000004)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: At-Large Councillor Henry Santana (-2507000005) — links to LOCAL at-large district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Henry Santana', 'Henry', 'Santana', NULL,
          true, false, false, true, -2507000005)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2507000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: District 1 Councillor Gabriela Coletta Zapata (-2507000006)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gabriela Coletta Zapata', 'Gabriela', 'Coletta Zapata', NULL,
          true, false, false, true, -2507000006)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'boston-ma-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: District 2 Councillor Edward M. Flynn (-2507000007)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Edward M. Flynn', 'Edward', 'Flynn', NULL,
          true, false, false, true, -2507000007)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'boston-ma-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: District 3 Councillor John FitzGerald (-2507000008)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John FitzGerald', 'John', 'FitzGerald', NULL,
          true, false, false, true, -2507000008)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'boston-ma-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: District 4 Councillor Brian Worrell (-2507000009)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Worrell', 'Brian', 'Worrell', NULL,
          true, false, false, true, -2507000009)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'boston-ma-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: District 5 Councillor Enrique J. Pepén (-2507000010)
-- CRITICAL (Pitfall 6): UTF-8 literal 'Enrique J. Pepén' — é accent preserved.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Enrique J. Pepén', 'Enrique', 'Pepén', NULL,
          true, false, false, true, -2507000010)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'boston-ma-council-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: District 6 Councillor Benjamin J. Weber (-2507000011)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Benjamin J. Weber', 'Benjamin', 'Weber', NULL,
          true, false, false, true, -2507000011)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'boston-ma-council-district-6'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: District 7 Councillor Miniard Culpepper (-2507000012)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Miniard Culpepper', 'Miniard', 'Culpepper', NULL,
          true, false, false, true, -2507000012)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'boston-ma-council-district-7'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 13: District 8 Councillor Sharon Durkan (-2507000013)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sharon Durkan', 'Sharon', 'Durkan', NULL,
          true, false, false, true, -2507000013)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'boston-ma-council-district-8'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 14: District 9 Councillor Liz Breadon (-2507000014) [Council President — procedural title]
-- title='City Councillor' per Alexandria procedural-title precedent (A1 — no separate President office)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Liz Breadon', 'Liz', 'Breadon', NULL,
          true, false, false, true, -2507000014)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'City of Boston, Massachusetts, US')),
       p.id,
       'City Councillor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'boston-ma-council-district-9'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 14 Boston council officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -2507000014 AND -2507000001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (7 gates)
-- Raises EXCEPTION on any failure.
-- Gate (a): 1 government row
-- Gate (b): 1 City Council chamber
-- Gate (c): 11 district rows (1 LOCAL_EXEC + 1 LOCAL at-large + 9 LOCAL per-district)
-- Gate (d): 14 politicians in external_id range
-- Gate (e): 14 offices linked to Boston districts
-- Gate (f): section-split = 0 orphan geofences
-- Gate (g): 0 NULL office_id in external_id range
-- =============================================================================
DO $$
DECLARE
  v_gov_count      INTEGER;
  v_chamber_count  INTEGER;
  v_dist_count     INTEGER;
  v_pol_count      INTEGER;
  v_off_count      INTEGER;
  v_split_count    INTEGER;
  v_null_count     INTEGER;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'City of Boston, Massachusetts, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Boston government row, found %', v_gov_count;
  END IF;

  -- Gate (b): City Council chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Boston, Massachusetts, US');

  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City Council chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 11 district rows
  -- 1 LOCAL_EXEC (geo_id='2507000') + 1 LOCAL at-large (geo_id='2507000') + 9 LOCAL per-district
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND (
      (geo_id = '2507000' AND district_type IN ('LOCAL_EXEC', 'LOCAL'))
      OR (geo_id LIKE 'boston-ma-council-district-%' AND district_type = 'LOCAL')
    );

  IF v_dist_count <> 11 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 11 Boston district rows, found %', v_dist_count;
  END IF;

  -- Gate (d): 14 politicians
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -2507000014 AND -2507000001;

  IF v_pol_count <> 14 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 14 politicians in range -2507000001..-2507000014, found %', v_pol_count;
  END IF;

  -- Gate (e): 14 offices linked to Boston districts (LOCAL_EXEC + LOCAL combined)
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.state = 'ma'
    AND (
      (d.geo_id = '2507000' AND d.district_type IN ('LOCAL_EXEC', 'LOCAL'))
      OR (d.geo_id LIKE 'boston-ma-council-district-%' AND d.district_type = 'LOCAL')
    );

  IF v_off_count <> 14 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 14 offices linked to Boston districts, found %', v_off_count;
  END IF;

  -- Gate (f): section-split detector
  -- Boston G4110 geofence must have at least one LOCAL_EXEC district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2507000'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.state = 'ma'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=2507000', v_split_count;
  END IF;

  -- Gate (g): office_id back-fill completeness
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -2507000014 AND -2507000001
    AND office_id IS NULL;

  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in external_id range have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 347 post-verification PASSED: gov=%, chambers=%, districts=%, politicians=%, offices=%, split_orphans=%, null_office_ids=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('347')
ON CONFLICT (version) DO NOTHING;
