-- Migration 1100: City of Boulder City, Nevada — structural seed
--
-- Creates the standalone City of Boulder City government, the Boulder City City
-- Council chamber (official_count=5), one LOCAL_EXEC district for the
-- directly-elected at-large Mayor (on the existing Phase 158 G4110 city
-- geofence), ONE shared LOCAL district (also on the same G4110 city geofence)
-- carrying all 4 at-large council members, and the 5 politician+office rows
-- (Mayor + 4 at-large council members).
--
-- Boulder City is AT-LARGE (council-manager, special charter) — it has NO wards.
-- Unlike North Las Vegas (1093) / Henderson (1084) / Las Vegas, there is no ward
-- loader, no custom ward MTFCC, and no new geofence rows. All 5 officials attach
-- to the ONE existing Boulder City G4110 city geofence (geo_id='3206500'). The 4
-- council members share a SINGLE LOCAL district (the Clark County 1055
-- single-shared-district shape), NOT one district per member. The Mayor (Joe
-- Hardy) is directly elected on a separate ballot line — NOT rotational.
--
-- STRUCTURAL: registers in the migration ledger as version 1100 (outside COMMIT).
--
-- Casing convention (do NOT vary):
--   districts.state            = 'nv'   (lowercase — routing join key; 'NV' = 0 rows)
--   governments.state          = 'NV'   (uppercase — governments table convention)
--   offices.representing_state = 'NV'   (uppercase — free-text label)
--   geofence_boundaries.state  = '32'   (TIGER FIPS — set by the Phase 158 place loader)
--
-- Prerequisite: the Boulder City G4110 city geofence (geo_id='3206500') was
-- loaded by Phase 158. There is NO ward prerequisite (Boulder City has no wards).

BEGIN;

-- ─── Pre-flight ─────────────────────────────────────────────────────────────
-- Boulder City has no wards — there is NO ward-geofence assertion here (carrying
-- the NLV X0017 count check would fire on 0 rows). Only the idempotent
-- government-exists NOTICE.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Boulder City, Nevada, US') > 0 THEN
    RAISE NOTICE 'City of Boulder City government row already exists — idempotent re-run';
  END IF;
END $$;

-- ─── Step 1: Government ─────────────────────────────────────────────────────
-- Standalone 'City of Boulder City, Nevada, US' (NOT nested under State of
-- Nevada geo_id='32'). CRITICAL: governments has NO unique constraint on geo_id
-- or name — WHERE NOT EXISTS is mandatory.
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Boulder City, Nevada, US',
       'City', 'NV', NULL, '3206500'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Boulder City, Nevada, US'
);

-- ─── Step 2: Chamber ────────────────────────────────────────────────────────
-- 'Boulder City City Council', official_count=5.
-- CRITICAL: the auto-generated path column is GENERATED ALWAYS — never include it
-- in the INSERT list. name_formal must be non-empty.
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Boulder City City Council',
       'Boulder City City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Boulder City, Nevada, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Boulder City City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Boulder City, Nevada, US')
);

-- ─── Step 3a: LOCAL_EXEC district (Mayor) ───────────────────────────────────
-- Uses the existing Phase 158 G4110 Boulder City geofence (geo_id='3206500')
-- — no new geofence row. state='nv' LOWERCASE — uppercase 'NV' matches ZERO
-- routing rows (silent no-op, the #1 failure mode).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'nv', '3206500', 'City of Boulder City', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '3206500' AND district_type = 'LOCAL_EXEC' AND state = 'nv'
);

-- ─── Step 3b: ONE shared LOCAL district (4 at-large council members) ─────────
-- The Clark County 1055 single-shared-district pattern: a SINGLE LOCAL district
-- on the SAME geo_id='3206500' as the LOCAL_EXEC row. All 4 at-large council
-- members attach here — NOT one district per member, NO ward geo_ids. Boulder
-- City has no wards. Result: exactly 2 district rows on geo_id='3206500'.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'nv', '3206500', 'City of Boulder City', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '3206500' AND district_type = 'LOCAL' AND state = 'nv'
);

-- ─── Step 4: Politicians + offices (5 blocks) ───────────────────────────────
-- All party='Non-Partisan' (antipartisan — never displayed). Each block inserts
-- the politician (ON CONFLICT (external_id) DO NOTHING) then the office joined on
-- the district by geo_id + district_type + state='nv', guarded by NOT EXISTS
-- (district_id, politician_id). representing_state='NV' uppercase (free-text label).
-- The Mayor uses district_type='LOCAL_EXEC'; all 4 council members use
-- district_type='LOCAL' on the SAME shared district (geo_id='3206500').

-- BLOCK 1: Joe Hardy (-3208001) — Mayor, directly elected at-large (LOCAL_EXEC)
-- Term expires 2026 (on the June 9 / Nov 3 2026 ballot) but seated until
-- inauguration — NOT rotational, title='Mayor'.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joe Hardy', 'Joe', 'Hardy', 'Non-Partisan',
          true, false, false, true, -3208001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Boulder City City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Boulder City, Nevada, US')),
       p.id,
       'Mayor', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3206500'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Sherri Jorgensen (-3208002) — Council Member (at-large)
-- "Mayor Pro Tem" is an internal council designation, NOT a separately-elected
-- seat — seed title='Council Member', do NOT create a 6th seat or a 2nd
-- LOCAL_EXEC row.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sherri Jorgensen', 'Sherri', 'Jorgensen', 'Non-Partisan',
          true, false, false, true, -3208002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Boulder City City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Boulder City, Nevada, US')),
       p.id,
       'Council Member', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3206500'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Cokie Booth (-3208003) — Council Member (at-large)
-- Term expires 2026, on the ballot, seated.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cokie Booth', 'Cokie', 'Booth', 'Non-Partisan',
          true, false, false, true, -3208003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Boulder City City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Boulder City, Nevada, US')),
       p.id,
       'Council Member', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3206500'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Steve Walton (-3208004) — Council Member (at-large)
-- Term expires 2026, on the ballot, seated.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Walton', 'Steve', 'Walton', 'Non-Partisan',
          true, false, false, true, -3208004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Boulder City City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Boulder City, Nevada, US')),
       p.id,
       'Council Member', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3206500'
  AND d.district_type = 'LOCAL'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Denise E. Ashurst (-3208005) — Council Member (at-large)
-- Elected Nov 2024, term 2028 (accent/spelling preserved).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Denise E. Ashurst', 'Denise', 'Ashurst', 'Non-Partisan',
          true, false, false, true, -3208005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Boulder City City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Boulder City, Nevada, US')),
       p.id,
       'Council Member', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3206500'
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
  AND p.external_id BETWEEN -3208005 AND -3208001
  AND p.office_id IS NULL;

-- ─── Step 6: Post-verification ──────────────────────────────────────────────
DO $$
DECLARE
  v_gov_count INTEGER;
  v_exec_count INTEGER;
  v_local_count INTEGER;
  v_district_count INTEGER;
  v_split_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Boulder City, Nevada, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Boulder City government row, found %', v_gov_count;
  END IF;

  -- Exactly 2 district rows on geo_id='3206500' (1 LOCAL_EXEC + 1 LOCAL), NOT 4.
  SELECT COUNT(*) INTO v_district_count
  FROM essentials.districts
  WHERE geo_id = '3206500' AND state = 'nv';
  IF v_district_count <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 2 districts on geo_id=3206500 (1 LOCAL_EXEC + 1 LOCAL), found %', v_district_count;
  END IF;

  SELECT COUNT(*) INTO v_exec_count
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '3206500' AND d.district_type = 'LOCAL_EXEC' AND d.state = 'nv';
  IF v_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 LOCAL_EXEC Mayor office, found %', v_exec_count;
  END IF;

  -- 4 at-large council offices on the ONE shared LOCAL district (geo_id='3206500').
  SELECT COUNT(*) INTO v_local_count
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '3206500' AND d.district_type = 'LOCAL' AND d.state = 'nv';
  IF v_local_count <> 4 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 4 LOCAL at-large council offices, found %', v_local_count;
  END IF;

  -- Section-split detector: the G4110 Boulder City geofence (geo_id='3206500')
  -- must have a matching LOCAL district. The geofence row is state='32' (FIPS);
  -- the district is state='nv' — match on geo_id only.
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '3206500'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id AND d.district_type = 'LOCAL' AND d.state = 'nv'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan geofence rows', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov=%, districts=%, exec=%, local=%, split_orphans=%',
    v_gov_count, v_district_count, v_exec_count, v_local_count, v_split_count;
END $$;

COMMIT;

-- ─── Step 7: Migration ledger (OUTSIDE the transaction) ─────────────────────
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1100', 'boulder_city_city_council')
ON CONFLICT (version) DO NOTHING;
