-- Migration 1093: City of North Las Vegas, Nevada — structural seed
--
-- Creates the standalone City of North Las Vegas government, the North Las Vegas
-- City Council chamber (official_count=5), one LOCAL_EXEC district for the
-- directly-elected Mayor (on the existing Phase 158 G4110 city geofence), four
-- LOCAL ward districts (on the X0017 ward geofences loaded by
-- load-north-las-vegas-ward-boundaries.ts), and the 5 politician+office rows
-- (Mayor + 4 ward council members).
--
-- Mirrors 1084_henderson_city_council.sql (same standalone-government shape, same
-- two-district-type pattern). NLV has 4 wards (LV had 6), uses ARABIC-numeral
-- ward titles (NOT Henderson's Roman), and a directly-elected Mayor
-- (Goynes-Brown) NOT a rotational one.
--
-- STRUCTURAL: registers in the migration ledger as version 1093 (outside COMMIT).
--
-- Casing convention (do NOT vary):
--   districts.state            = 'nv'   (lowercase — routing join key; 'NV' = 0 rows)
--   governments.state          = 'NV'   (uppercase — governments table convention)
--   offices.representing_state = 'NV'   (uppercase — free-text label)
--   geofence_boundaries.state  = 'nv'   (lowercase — set by the ward loader)
--
-- Prerequisite: load-north-las-vegas-ward-boundaries.ts must have loaded the 4
-- X0017 ward geofences first (pre-flight asserts this).

BEGIN;

-- ─── Pre-flight ─────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of North Las Vegas, Nevada, US') > 0 THEN
    RAISE NOTICE 'City of North Las Vegas government row already exists — idempotent re-run';
  END IF;

  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE state = 'nv' AND mtfcc = 'X0017') < 4 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: fewer than 4 X0017 ward geofences — run load-north-las-vegas-ward-boundaries.ts first.';
  END IF;
END $$;

-- ─── Step 1: Government ─────────────────────────────────────────────────────
-- Standalone 'City of North Las Vegas, Nevada, US' (NOT nested under State of
-- Nevada geo_id='32'). CRITICAL: governments has NO unique constraint on geo_id
-- or name — WHERE NOT EXISTS is mandatory.
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of North Las Vegas, Nevada, US',
       'City', 'NV', NULL, '3251800'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of North Las Vegas, Nevada, US'
);

-- ─── Step 2: Chamber ────────────────────────────────────────────────────────
-- 'North Las Vegas City Council', official_count=5.
-- CRITICAL: the auto-generated path column is GENERATED ALWAYS — never include it
-- in the INSERT list. name_formal must be non-empty.
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'North Las Vegas City Council',
       'North Las Vegas City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of North Las Vegas, Nevada, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'North Las Vegas City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of North Las Vegas, Nevada, US')
);

-- ─── Step 3a: LOCAL_EXEC district (Mayor) ───────────────────────────────────
-- Uses the existing Phase 158 G4110 North Las Vegas geofence (geo_id='3251800')
-- — no new geofence row. state='nv' LOWERCASE — uppercase 'NV' matches ZERO
-- routing rows (silent no-op, the #1 failure mode).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'nv', '3251800', 'City of North Las Vegas', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '3251800' AND district_type = 'LOCAL_EXEC' AND state = 'nv'
);

-- ─── Step 3b: LOCAL ward districts (4) ──────────────────────────────────────
-- ARABIC-numeral labels ('Ward 1'..'Ward 4') — NLV official naming convention
-- (NOT Henderson's Roman 'Ward I'). mtfcc='X0017' is caught by the
-- essentialsService.ts X% catchall → routed to LOCAL (no backend change).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'north-las-vegas-nv-council-ward-1', 'Ward 1', 'X0017'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'north-las-vegas-nv-council-ward-1' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'north-las-vegas-nv-council-ward-2', 'Ward 2', 'X0017'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'north-las-vegas-nv-council-ward-2' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'north-las-vegas-nv-council-ward-3', 'Ward 3', 'X0017'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'north-las-vegas-nv-council-ward-3' AND district_type = 'LOCAL' AND state = 'nv'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', 'north-las-vegas-nv-council-ward-4', 'Ward 4', 'X0017'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'north-las-vegas-nv-council-ward-4' AND district_type = 'LOCAL' AND state = 'nv'
);

-- ─── Step 4: Politicians + offices (5 blocks) ───────────────────────────────
-- All party='Non-Partisan' (antipartisan — never displayed). Each block inserts
-- the politician (ON CONFLICT (external_id) DO NOTHING) then the office joined on
-- the district by geo_id + district_type + state='nv', guarded by NOT EXISTS
-- (district_id, politician_id). representing_state='NV' uppercase (free-text label).

-- BLOCK 1: Pamela Goynes-Brown (-3207001) — Mayor, directly elected (LOCAL_EXEC)
-- Term-limited but seated through Nov 30 2026 — NOT rotational.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pamela Goynes-Brown', 'Pamela', 'Goynes-Brown', 'Non-Partisan',
          true, false, false, true, -3207001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'North Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of North Las Vegas, Nevada, US')),
       p.id,
       'Mayor', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3251800'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Isaac E. Barrón (-3207002) — Ward 1 (accent preserved)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Isaac E. Barrón', 'Isaac', 'Barrón', 'Non-Partisan',
          true, false, false, true, -3207002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'North Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of North Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 1', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'north-las-vegas-nv-council-ward-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Ruth Garcia-Anderson (-3207003) — Ward 2 (elected full term Nov 2024, is_appointed=false)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ruth Garcia-Anderson', 'Ruth', 'Garcia-Anderson', 'Non-Partisan',
          true, false, false, true, -3207003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'North Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of North Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 2', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'north-las-vegas-nv-council-ward-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Scott Black (-3207004) — Ward 3
-- is_active=true, is_incumbent=true: seated incumbent despite advancing to the
-- Nov 2026 mayoral runoff; he serves Ward 3 until the outcome/inauguration
-- (the Carrie Cox parallel).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Scott Black', 'Scott', 'Black', 'Non-Partisan',
          true, false, false, true, -3207004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'North Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of North Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 3', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'north-las-vegas-nv-council-ward-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Richard Cherchio (-3207005) — Ward 4 (re-elected unopposed 2024)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Cherchio', 'Richard', 'Cherchio', 'Non-Partisan',
          true, false, false, true, -3207005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'North Las Vegas City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of North Las Vegas, Nevada, US')),
       p.id,
       'Council Member, Ward 4', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'north-las-vegas-nv-council-ward-4'
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
  AND p.external_id BETWEEN -3207005 AND -3207001
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
  WHERE name = 'City of North Las Vegas, Nevada, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 North Las Vegas government row, found %', v_gov_count;
  END IF;

  SELECT COUNT(*) INTO v_exec_count
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '3251800' AND d.district_type = 'LOCAL_EXEC' AND d.state = 'nv';
  IF v_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 LOCAL_EXEC Mayor office, found %', v_exec_count;
  END IF;

  SELECT COUNT(*) INTO v_local_count
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.mtfcc = 'X0017' AND d.district_type = 'LOCAL' AND d.state = 'nv';
  IF v_local_count <> 4 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 4 LOCAL ward offices, found %', v_local_count;
  END IF;

  -- Section-split detector: every X0017 ward geofence must have a matching LOCAL district.
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.state = 'nv'
    AND gb.mtfcc = 'X0017'
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
VALUES ('1093', 'north_las_vegas_city_council')
ON CONFLICT (version) DO NOTHING;
