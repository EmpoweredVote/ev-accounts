-- Migration 1084: City of Henderson, Nevada — structural seed
--
-- Creates the standalone City of Henderson government, the Henderson City Council
-- chamber (official_count=5), one LOCAL_EXEC district for the directly-elected
-- Mayor (on the existing Phase 158 G4110 city geofence), four LOCAL ward districts
-- (on the X0016 ward geofences loaded by load-henderson-ward-boundaries.ts), and
-- the 5 politician+office rows (Mayor + 4 ward council members).
--
-- Mirrors 1075_las_vegas_city_council.sql (same standalone-government shape, same
-- two-district-type pattern). Henderson has 4 wards (LV had 6), uses Roman-numeral
-- ward titles, and a directly-elected Mayor (Romero) NOT a rotational one.
--
-- STRUCTURAL: registers in the migration ledger as version 1084 (outside COMMIT).
--
-- Casing convention (do NOT vary):
--   districts.state            = 'nv'   (lowercase — routing join key; 'NV' = 0 rows)
--   governments.state          = 'NV'   (uppercase — governments table convention)
--   offices.representing_state = 'NV'   (uppercase — free-text label)
--   geofence_boundaries.state  = 'nv'   (lowercase — set by the ward loader)
--
-- Prerequisite: load-henderson-ward-boundaries.ts must have loaded the 4 X0016
-- ward geofences first (pre-flight asserts this).

BEGIN;

-- ─── Pre-flight ─────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Henderson, Nevada, US') > 0 THEN
    RAISE NOTICE 'City of Henderson government row already exists — idempotent re-run';
  END IF;

  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE state = 'nv' AND mtfcc = 'X0016') < 4 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: fewer than 4 X0016 ward geofences — run load-henderson-ward-boundaries.ts first.';
  END IF;
END $$;

-- ─── Step 1: Government ─────────────────────────────────────────────────────
-- Standalone 'City of Henderson, Nevada, US' (NOT nested under State of Nevada
-- geo_id='32'). CRITICAL: governments has NO unique constraint on geo_id or name
-- — WHERE NOT EXISTS is mandatory.
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Henderson, Nevada, US',
       'City', 'NV', NULL, '3231900'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Henderson, Nevada, US'
);

-- ─── Step 2: Chamber ────────────────────────────────────────────────────────
-- 'Henderson City Council', official_count=5.
-- CRITICAL: the auto-generated path column is GENERATED ALWAYS — never include it
-- in the INSERT list. name_formal must be non-empty.
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Henderson City Council',
       'Henderson City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Henderson, Nevada, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Henderson City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Henderson, Nevada, US')
);

-- ─── Step 3a: LOCAL_EXEC district (Mayor) ───────────────────────────────────
-- Uses the existing Phase 158 G4110 Henderson geofence (geo_id='3231900') — no
-- new geofence row. state='nv' LOWERCASE — uppercase 'NV' matches ZERO routing
-- rows (silent no-op, the #1 failure mode).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'nv', '3231900', 'City of Henderson', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '3231900' AND district_type = 'LOCAL_EXEC' AND state = 'nv'
);

-- ─── Step 3b: LOCAL ward districts (4) ──────────────────────────────────────
-- label uses Roman numerals (matches official Henderson WARDNAME values); the
-- the geo_id identifier uses Arabic numerals for programmatic consistency. mtfcc='X0016'
-- is caught by the essentialsService.ts X% catchall → routed to LOCAL (no backend change).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'henderson-nv-council-ward-1', 'Ward I', 'X0016'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'henderson-nv-council-ward-1' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'henderson-nv-council-ward-2', 'Ward II', 'X0016'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'henderson-nv-council-ward-2' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'henderson-nv-council-ward-3', 'Ward III', 'X0016'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'henderson-nv-council-ward-3' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'henderson-nv-council-ward-4', 'Ward IV', 'X0016'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'henderson-nv-council-ward-4' AND district_type = 'LOCAL' AND state = 'nv'
);

-- ─── Step 4: Politicians + offices (5 blocks) ───────────────────────────────
-- All party='Non-Partisan' (antipartisan — never displayed). Each block inserts
-- the politician (ON CONFLICT (external_id) DO NOTHING) then the office joined on
-- the district by geo_id + district_type + state='nv', guarded by NOT EXISTS
-- (district_id, politician_id). representing_state='NV' uppercase (free-text label).

-- BLOCK 1: Michelle Romero (-3206001) — Mayor, directly elected (LOCAL_EXEC)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michelle Romero', 'Michelle', 'Romero', 'Non-Partisan',
          true, false, false, true, -3206001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Henderson City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Henderson, Nevada, US')),
       p.id,
       'Mayor', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3231900'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Jim Seebock (-3206002) — Ward I
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jim Seebock', 'Jim', 'Seebock', 'Non-Partisan',
          true, false, false, true, -3206002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Henderson City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Henderson, Nevada, US')),
       p.id,
       'Council Member, Ward I', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'henderson-nv-council-ward-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Monica Larson (-3206003) — Ward II (elected Nov 2024, is_appointed=false)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Monica Larson', 'Monica', 'Larson', 'Non-Partisan',
          true, false, false, true, -3206003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Henderson City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Henderson, Nevada, US')),
       p.id,
       'Council Member, Ward II', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'henderson-nv-council-ward-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Carrie Cox (-3206004) — Ward III
-- is_active=true, is_incumbent=true: seated incumbent despite the June 2026
-- primary loss; she serves until the Nov 2026 general.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carrie Cox', 'Carrie', 'Cox', 'Non-Partisan',
          true, false, false, true, -3206004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Henderson City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Henderson, Nevada, US')),
       p.id,
       'Council Member, Ward III', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'henderson-nv-council-ward-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Dan H. Stewart (-3206005) — Ward IV
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dan H. Stewart', 'Dan', 'Stewart', 'Non-Partisan',
          true, false, false, true, -3206005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Henderson City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Henderson, Nevada, US')),
       p.id,
       'Council Member, Ward IV', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'henderson-nv-council-ward-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ─── Step 5: office_id back-fill ────────────────────────────────────────────
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -3206005 AND -3206001
  AND p.office_id IS NULL;

-- ─── Step 6: Post-verification ──────────────────────────────────────────────
DO $$
DECLARE
  v_gov_count INTEGER;
  v_exec_count INTEGER;
  v_local_count INTEGER;
  v_split_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Henderson, Nevada, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Henderson government row, found %', v_gov_count;
  END IF;

  SELECT COUNT(*) INTO v_exec_count
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '3231900' AND d.district_type = 'LOCAL_EXEC' AND d.state = 'nv';
  IF v_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 LOCAL_EXEC Mayor office, found %', v_exec_count;
  END IF;

  SELECT COUNT(*) INTO v_local_count
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.mtfcc = 'X0016' AND d.district_type = 'LOCAL' AND d.state = 'nv';
  IF v_local_count <> 4 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 4 LOCAL ward offices, found %', v_local_count;
  END IF;

  -- Section-split detector: every X0016 ward geofence must have a matching LOCAL district.
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.state = 'nv'
    AND gb.mtfcc = 'X0016'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id AND d.district_type = 'LOCAL' AND d.state = 'nv'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan ward rows', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov=%, exec=%, local=%, split_orphans=%',
    v_gov_count, v_exec_count, v_local_count, v_split_count;
END $$;

COMMIT;

-- ─── Step 7: Migration ledger (OUTSIDE the transaction) ─────────────────────
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1084', 'henderson_city_council')
ON CONFLICT (version) DO NOTHING;
