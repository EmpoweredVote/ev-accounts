-- Migration 1075: City of Las Vegas government + chamber + Mayor + 6 ward council members
--
-- Phase 162 (CLARK-02) — STRUCTURAL (registers in the migration ledger). Idempotent.
--
-- Purpose: Seeds the City of Las Vegas with ward-precise council routing.
--   - 1 government row: 'City of Las Vegas, Nevada, US' (type='City', state='NV', geo_id='3240000')
--     standalone — NOT nested under State of Nevada (geo_id='32'), no parent linkage [D-03]
--   - 1 chamber row: 'Las Vegas City Council' (name_formal='Las Vegas City Council', official_count=7)
--   - TWO district types:
--       * 1 LOCAL_EXEC district on the existing G4110 city geofence (geo_id='3240000') for the Mayor
--       * 6 LOCAL districts on the X0015 ward geofences (geo_id='las-vegas-nv-council-ward-1'..'-6')
--   - 7 politicians + offices:
--       -3205001 Shelley Berkley            (Mayor — directly elected at-large, LOCAL_EXEC) [D-02]
--       -3205002 Brian Knudsen              (Council Member, Ward 1)
--       -3205003 Kara Kelley                (Council Member, Ward 2 — appointed Sept 2025)
--       -3205004 Olivia Diaz                (Council Member, Ward 3)
--       -3205005 Francis Allen-Palenske     (Council Member, Ward 4)
--       -3205006 Shondra Summers-Armstrong  (Council Member, Ward 5)
--       -3205007 Nancy E. Brune             (Council Member, Ward 6)
--   - office_id back-fill on all 7 politicians
--
-- The Mayor is DIRECTLY ELECTED at-large (NOT rotational): she gets her own LOCAL_EXEC office
-- with title='Mayor' on the city-wide geofence. No ward member is flagged as Mayor Pro Tem via a
-- title-on-seat; ward titles are plain 'Council Member, Ward N'. [D-02, Pitfall 4]
--
-- CRITICAL: the auto-generated path column on essentials.chambers must never appear in INSERT list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'nv' (lowercase) for LOCAL_EXEC / LOCAL types to match routing
--   queries. Using uppercase 'NV' in the office WHERE clauses matches ZERO rows (silent no-op).
-- CRITICAL: governments.state = 'NV' (uppercase) and offices.representing_state = 'NV' (uppercase)
--   are table conventions / free-text labels — NOT the district join key.

BEGIN;

-- =============================================================================
-- Pre-flight: idempotency notice + assert the 6 X0015 ward geofences exist
-- (loaded by load-lv-ward-boundaries.ts before this migration is applied).
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Las Vegas, Nevada, US') > 0 THEN
    RAISE NOTICE 'City of Las Vegas government row already exists — idempotent re-run';
  END IF;

  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE state = 'nv' AND mtfcc = 'X0015') < 6 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: fewer than 6 X0015 ward geofences — run load-lv-ward-boundaries.ts first.';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (City of Las Vegas, Nevada, US)
-- type='City'; state='NV' uppercase (governments table convention).
-- standalone — no government_id/parent linkage to State of Nevada (D-03).
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Las Vegas, Nevada, US',
       'City', 'NV', NULL, '3240000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Las Vegas, Nevada, US'
);

-- =============================================================================
-- Step 2: Las Vegas City Council chamber (official_count=7)
-- CRITICAL: the auto-generated path column is GENERATED ALWAYS — never include in INSERT list.
-- name_formal must NOT be empty.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Las Vegas City Council',
       'Las Vegas City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Las Vegas, Nevada, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Las Vegas City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Las Vegas, Nevada, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district for the directly-elected Mayor (city-wide G4110)
-- Uses the EXISTING Phase 158 G4110 city geofence (geo_id='3240000') — no new geofence row.
-- state='nv' LOWERCASE — uppercase 'NV' matches ZERO routing rows (silent no-op).
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'nv', '3240000', 'City of Las Vegas', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '3240000' AND district_type = 'LOCAL_EXEC' AND state = 'nv'
);

-- =============================================================================
-- Step 3b: LOCAL districts for each ward (X0015 ward geofences)
-- One per ward; pre-flight asserts the geofences exist. state='nv' lowercase.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'las-vegas-nv-council-ward-1', 'Ward 1', 'X0015'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'las-vegas-nv-council-ward-1' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'las-vegas-nv-council-ward-2', 'Ward 2', 'X0015'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'las-vegas-nv-council-ward-2' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'las-vegas-nv-council-ward-3', 'Ward 3', 'X0015'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'las-vegas-nv-council-ward-3' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'las-vegas-nv-council-ward-4', 'Ward 4', 'X0015'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'las-vegas-nv-council-ward-4' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'las-vegas-nv-council-ward-5', 'Ward 5', 'X0015'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'las-vegas-nv-council-ward-5' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'las-vegas-nv-council-ward-6', 'Ward 6', 'X0015'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'las-vegas-nv-council-ward-6' AND district_type = 'LOCAL' AND state = 'nv'
);

-- =============================================================================
-- Step 4: Politicians + offices (7 blocks — Mayor + 6 ward members)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party stored (antipartisan — never displayed): Berkley 'Democratic', 6 council 'Non-Partisan'.
-- representing_state='NV' uppercase (offices table free-text label).
-- role_canonical NULL on all 7.
-- Idempotency: external_id upsert no-op on politicians; NOT EXISTS (district_id, politician_id) on offices.
-- =============================================================================

-- BLOCK 1: Mayor Shelley Berkley (-3205001) [directly elected at-large — LOCAL_EXEC]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shelley Berkley', 'Shelley', 'Berkley', 'Democratic',
          true, false, false, true, -3205001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Las Vegas, Nevada, US')),
       p.id,
       'Mayor', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3240000'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Council Member, Ward 1 Brian Knudsen (-3205002)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Knudsen', 'Brian', 'Knudsen', 'Non-Partisan',
          true, false, false, true, -3205002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 1', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'las-vegas-nv-council-ward-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Council Member, Ward 2 Kara Kelley (-3205003) [appointed Sept 2025 — is_appointed=true]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kara Kelley', 'Kara', 'Kelley', 'Non-Partisan',
          true, true, false, true, -3205003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 2', 'NV', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'las-vegas-nv-council-ward-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Council Member, Ward 3 Olivia Diaz (-3205004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Olivia Diaz', 'Olivia', 'Diaz', 'Non-Partisan',
          true, false, false, true, -3205004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 3', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'las-vegas-nv-council-ward-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Council Member, Ward 4 Francis Allen-Palenske (-3205005)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Francis Allen-Palenske', 'Francis', 'Allen-Palenske', 'Non-Partisan',
          true, false, false, true, -3205005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 4', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'las-vegas-nv-council-ward-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Council Member, Ward 5 Shondra Summers-Armstrong (-3205006)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shondra Summers-Armstrong', 'Shondra', 'Summers-Armstrong', 'Non-Partisan',
          true, false, false, true, -3205006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 5', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'las-vegas-nv-council-ward-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Council Member, Ward 6 Nancy E. Brune (-3205007)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nancy E. Brune', 'Nancy', 'Brune', 'Non-Partisan',
          true, false, false, true, -3205007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 6', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'las-vegas-nv-council-ward-6'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 7 LV City Council seats.
-- WHERE p.office_id IS NULL for idempotency. BETWEEN: more-negative bound first.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -3205007 AND -3205001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (two district types — Pitfall 2)
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count must be exactly 1
-- Gate (b): exactly 1 LOCAL_EXEC office (Mayor) on the city-wide district
-- Gate (c): exactly 6 LOCAL offices (ward members) on X0015 ward districts
-- Gate (d): section-split detector must return 0 orphan rows for any X0015 ward geofence
-- =============================================================================
DO $$
DECLARE
  v_gov_count INTEGER;
  v_exec_count INTEGER;
  v_local_count INTEGER;
  v_split_count INTEGER;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'City of Las Vegas, Nevada, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 LV government row, found %', v_gov_count;
  END IF;

  -- Gate (b): exactly 1 LOCAL_EXEC office (Mayor)
  SELECT COUNT(*) INTO v_exec_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '3240000' AND d.district_type = 'LOCAL_EXEC' AND d.state = 'nv';
  IF v_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 LOCAL_EXEC Mayor office, found %', v_exec_count;
  END IF;

  -- Gate (c): exactly 6 LOCAL ward offices
  SELECT COUNT(*) INTO v_local_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.mtfcc = 'X0015' AND d.district_type = 'LOCAL' AND d.state = 'nv';
  IF v_local_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 6 LOCAL ward offices, found %', v_local_count;
  END IF;

  -- Gate (d): section-split detector — every X0015 ward geofence must have a matching LOCAL district
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.state = 'nv'
    AND gb.mtfcc = 'X0015'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'LOCAL'
        AND d.state = 'nv'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan ward rows', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov=%, exec=%, local=%, split_orphans=%',
    v_gov_count, v_exec_count, v_local_count, v_split_count;
END $$;

COMMIT;

-- =============================================================================
-- Step 7: Migration ledger registration (OUTSIDE the transaction)
-- Structural migration registers with the 2-column (version, name) form.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1075', 'las_vegas_city_council')
ON CONFLICT (version) DO NOTHING;
