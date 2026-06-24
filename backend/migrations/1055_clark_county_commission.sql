-- Migration 1055: Clark County government + chamber + COUNTY district + 7 officials + offices
--
-- Phase 161 (CLARK-01) — STRUCTURAL (registers in the migration ledger). Idempotent.
--
-- Purpose: Seeds Clark County Board of County Commissioners under geo_id='32003'.
--   - 1 government row: 'Clark County, Nevada, US' (type='County', state='NV', geo_id='32003')
--     standalone — NOT nested under State of Nevada (geo_id='32'), no parent linkage [D-04]
--   - 1 chamber row: 'Board of County Commissioners'
--     (name_formal='Clark County Board of County Commissioners')
--   - 1 COUNTY district row: idempotent guard only (Phase 158 already loaded geo_id=32003)
--   - 7 politicians: Chair (-3200301) + Commissioners (-3200302..-3200307)
--       -3200301 Michael Naft        (District A — Chair, title-on-seat)
--       -3200302 Marilyn Kirkpatrick  (District B)
--       -3200303 April Becker         (District C)
--       -3200304 William McCurdy II   (District D — Vice-Chair, title-on-seat)
--       -3200305 Tick Segerblom       (District E)
--       -3200306 Justin Jones         (District F)
--       -3200307 James B. Gibson      (District G)
--   - 7 offices: all linked to the single pre-existing COUNTY district (geo_id='32003')
--   - office_id back-fill on all 7 politicians
--
-- Chair (Naft) and Vice-Chair (McCurdy) are modeled as display-ordering titles on their
-- commissioner seats — there is NO phantom 8th office row, no role_canonical, no LOCAL_EXEC.
--
-- CRITICAL: the auto-generated path column on essentials.chambers must never appear in INSERT list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'nv' (lowercase) for COUNTY type to match routing queries.
--   Using uppercase 'NV' in the office WHERE clauses matches ZERO rows (silent no-op).
-- CRITICAL: governments.state = 'NV' (uppercase) and offices.representing_state = 'NV' (uppercase)
--   are table conventions / free-text labels — NOT the district join key.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Clark County, Nevada, US') > 0 THEN
    RAISE NOTICE 'Clark County government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (Clark County, Nevada, US)
-- type='County' matches Multnomah County precedent (migration 244).
-- state='NV' uppercase (governments table convention).
-- standalone — no government_id/parent linkage to State of Nevada (D-04).
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Clark County, Nevada, US',
       'County', 'NV', NULL, '32003'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Clark County, Nevada, US'
);

-- =============================================================================
-- Step 2: Board of County Commissioners chamber
-- CRITICAL: the auto-generated path column is GENERATED ALWAYS — never include in INSERT list.
-- name_formal must NOT be empty.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of County Commissioners',
       'Clark County Board of County Commissioners',
       (SELECT id FROM essentials.governments WHERE name = 'Clark County, Nevada, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of County Commissioners'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Clark County, Nevada, US')
);

-- =============================================================================
-- Step 3: COUNTY district row (idempotent no-op — Phase 158 already loaded geo_id=32003)
-- geo_id='32003' matches the existing G4020 geofence_boundary loaded in Phase 158.
-- state='nv' LOWERCASE — matches routing query WHERE d.state = $1 (geocoder returns lowercase 'nv').
-- mtfcc='G4020' matches the geofence_boundaries row for ST_Covers JOIN.
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state). NEVER skip this guard.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'COUNTY', 'nv', '32003', 'Clark County', 'G4020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '32003' AND district_type = 'COUNTY' AND state = 'nv'
);

-- =============================================================================
-- Step 4: Politicians + offices (7 blocks — Commissioners District A-G)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party stored (antipartisan — never displayed): 6 Democratic + Becker Republican
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='NV' uppercase (offices table free-text label)
-- role_canonical NULL on all 7 — Chair/Vice-Chair are display-ordering only (groupHierarchy.js)
-- Idempotency: external_id upsert no-op on politicians (conflict on external_id does nothing)
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- All 7 offices link to the SAME single COUNTY district (county-wide routing model)
-- =============================================================================

-- BLOCK 1: Commissioner District A Michael Naft (-3200301) [Chair — title-on-seat]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Naft', 'Michael', 'Naft', 'Democratic',
          true, false, false, true, -3200301)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of County Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County, Nevada, US')),
       p.id,
       'Commissioner (District A)', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32003'
  AND d.district_type = 'COUNTY'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Commissioner District B Marilyn Kirkpatrick (-3200302)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marilyn Kirkpatrick', 'Marilyn', 'Kirkpatrick', 'Democratic',
          true, false, false, true, -3200302)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of County Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County, Nevada, US')),
       p.id,
       'Commissioner (District B)', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32003'
  AND d.district_type = 'COUNTY'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Commissioner District C April Becker (-3200303) [Republican]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'April Becker', 'April', 'Becker', 'Republican',
          true, false, false, true, -3200303)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of County Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County, Nevada, US')),
       p.id,
       'Commissioner (District C)', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32003'
  AND d.district_type = 'COUNTY'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Commissioner District D William McCurdy II (-3200304) [Vice-Chair — title-on-seat]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'William McCurdy II', 'William', 'McCurdy II', 'Democratic',
          true, false, false, true, -3200304)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of County Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County, Nevada, US')),
       p.id,
       'Commissioner (District D)', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32003'
  AND d.district_type = 'COUNTY'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Commissioner District E Tick Segerblom (-3200305)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tick Segerblom', 'Tick', 'Segerblom', 'Democratic',
          true, false, false, true, -3200305)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of County Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County, Nevada, US')),
       p.id,
       'Commissioner (District E)', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32003'
  AND d.district_type = 'COUNTY'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Commissioner District F Justin Jones (-3200306)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Justin Jones', 'Justin', 'Jones', 'Democratic',
          true, false, false, true, -3200306)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of County Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County, Nevada, US')),
       p.id,
       'Commissioner (District F)', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32003'
  AND d.district_type = 'COUNTY'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Commissioner District G James B. Gibson (-3200307)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James B. Gibson', 'James B.', 'Gibson', 'Democratic',
          true, false, false, true, -3200307)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of County Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County, Nevada, US')),
       p.id,
       'Commissioner (District G)', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '32003'
  AND d.district_type = 'COUNTY'
  AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 7 Clark County commissioners.
-- WHERE p.office_id IS NULL for idempotency. BETWEEN: more-negative bound first.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -3200307 AND -3200301
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count must be exactly 1
-- Gate (b): offices linked to COUNTY district must be exactly 7
-- Gate (c): section-split detector must return 0 orphan rows
-- =============================================================================
DO $$
DECLARE
  v_gov_count INTEGER;
  v_office_count INTEGER;
  v_split_count INTEGER;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'Clark County, Nevada, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Clark County government row, found %', v_gov_count;
  END IF;

  -- Gate (b): offices linked to COUNTY district
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '32003'
    AND d.district_type = 'COUNTY'
    AND d.state = 'nv';

  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 offices linked to geo_id=32003 COUNTY district, found %', v_office_count;
  END IF;

  -- Gate (c): section-split detector
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '32003'
    AND gb.mtfcc = 'G4020'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'COUNTY'
        AND d.state = 'nv'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=32003', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov_count=%, office_count=%, split_orphans=%',
    v_gov_count, v_office_count, v_split_count;
END $$;

COMMIT;

-- =============================================================================
-- Step 7: Migration ledger registration (OUTSIDE the transaction)
-- Structural migration registers with the newer 2-column (version, name) form.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1055', 'clark_county_commission')
ON CONFLICT (version) DO NOTHING;
