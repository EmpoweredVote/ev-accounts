-- Migration 1120: Washington County government + chamber + COUNTY district + 4 LOCAL X0018 districts + 5 officials + offices
--
-- Phase 175 (WASH-01) — STRUCTURAL (registers in the migration ledger). Idempotent.
--
-- Purpose: Seeds Washington County Board of County Commissioners under geo_id='41067'.
--   - 1 government row: 'Washington County, Oregon, US' (type='County', state='OR', geo_id='41067')
--     standalone — NOT nested under State of Oregon; no parent government linkage.
--   - 1 chamber row: 'Board of County Commissioners'
--     (name_formal='Washington County Board of County Commissioners', official_count=5)
--   - 1 COUNTY district row: geo_id='41067', mtfcc='G4020', state='or', district_type='COUNTY'
--     (Wave-0 confirms this row already exists; WHERE NOT EXISTS guard is a no-op)
--   - 4 LOCAL district rows: geo_id='washco-or-commissioner-district-1'..'-4',
--     district_type='LOCAL', state='or', mtfcc='X0018'
--     (pre-flight asserts 4 X0018 geofences were loaded first by the loader script)
--   - 5 politicians: Chair (-410100) + Commissioners D1-D4 (-410110..-410113)
--       -410100 Kathryn Harrington   (Chair, county-wide)
--       -410110 Nafisa Fai           (District 1)
--       -410111 Pam Treece           (District 2)
--       -410112 Jason Snider         (District 3)
--       -410113 Jerry Willey         (District 4)
--   - Chair office links to COUNTY district (geo_id='41067') — routes county-wide
--   - Commissioner offices each link to their own LOCAL X0018 district — per-district routing
--   - office_id back-fill on all 5 politicians
--
-- Split routing model: Chair (COUNTY) + exactly 1 matched commissioner (LOCAL X0018)
-- per WashCo address. No section-split; no empty LOCAL section.
--
-- Geofence boundary (G4020, geo_id='41067', state='41') was loaded in Phase 72 OR TIGER.
-- X0018 geofences must be loaded by load-washco-commissioner-boundaries.ts BEFORE this migration.
--
-- CRITICAL: the auto-generated column on essentials.chambers must never appear in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard on name.
-- CRITICAL: districts.state must be 'or' (lowercase) for COUNTY and LOCAL types to match routing queries.
--   Using uppercase 'OR' in districts causes silent zero-match on routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase) and offices.representing_state = 'OR' (uppercase)
--   are table conventions / free-text labels — NOT the district join key.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Washington County, Oregon, US') > 0 THEN
    RAISE NOTICE 'Washington County government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (Washington County, Oregon, US)
-- type='County' matches Multnomah County precedent (migration 244).
-- state='OR' uppercase (governments table convention).
-- standalone — no government_id/parent linkage to State of Oregon.
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Washington County, Oregon, US',
       'County', 'OR', NULL, '41067'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Washington County, Oregon, US'
);

-- =============================================================================
-- Step 2: Board of County Commissioners chamber
-- CRITICAL: the auto-generated column is GENERATED ALWAYS — never include in INSERT column list.
-- Body name: 'Board of County Commissioners' (verified washingtoncountyor.gov/bcc).
-- official_count=5 (Chair + 4 district commissioners).
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Board of County Commissioners',
       'Washington County Board of County Commissioners',
       (SELECT id FROM essentials.governments WHERE name = 'Washington County, Oregon, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of County Commissioners'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Washington County, Oregon, US')
);

-- =============================================================================
-- Step 3a: COUNTY district row (Chair routes here — county-wide)
-- geo_id='41067' matches the existing G4020 geofence_boundary loaded in Phase 72 OR TIGER.
-- state='or' LOWERCASE — matches routing query WHERE d.state = $1 (geocoder returns lowercase 'or').
-- Wave-0 confirmed this row already exists; WHERE NOT EXISTS guard is a no-op.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'COUNTY', 'or', '41067', 'Washington County', 'G4020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '41067' AND district_type = 'COUNTY' AND state = 'or'
);

-- =============================================================================
-- Step 3b: Pre-flight geofence assertion + 4 LOCAL X0018 district rows
-- The pre-flight asserts that load-washco-commissioner-boundaries.ts ran first.
-- =============================================================================

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE state = 'or' AND mtfcc = 'X0018') < 4 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: fewer than 4 X0018 geofences found — run load-washco-commissioner-boundaries.ts before applying this migration.';
  END IF;
END $$;

-- LOCAL district for Commissioner District 1 (Nafisa Fai)
-- state='or' lowercase; district_type='LOCAL'; mtfcc='X0018'
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', 'washco-or-commissioner-district-1',
       'Washington County Commissioner District 1', 'X0018'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'washco-or-commissioner-district-1' AND district_type = 'LOCAL' AND state = 'or'
);

-- LOCAL district for Commissioner District 2 (Pam Treece)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', 'washco-or-commissioner-district-2',
       'Washington County Commissioner District 2', 'X0018'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'washco-or-commissioner-district-2' AND district_type = 'LOCAL' AND state = 'or'
);

-- LOCAL district for Commissioner District 3 (Jason Snider)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', 'washco-or-commissioner-district-3',
       'Washington County Commissioner District 3', 'X0018'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'washco-or-commissioner-district-3' AND district_type = 'LOCAL' AND state = 'or'
);

-- LOCAL district for Commissioner District 4 (Jerry Willey)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', 'washco-or-commissioner-district-4',
       'Washington County Commissioner District 4', 'X0018'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'washco-or-commissioner-district-4' AND district_type = 'LOCAL' AND state = 'or'
);

-- =============================================================================
-- Step 4: Politicians + offices (5 blocks — Chair + Commissioners D1-D4)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan — Washington County offices are nonpartisan on ballot)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='OR' uppercase (offices table free-text convention)
-- role_canonical NULL on all 5 — Chair is modeled as title-on-seat, not LOCAL_EXEC
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- Chair links to COUNTY district (geo_id='41067'); D1-D4 each link to their LOCAL X0018 district.
-- =============================================================================

-- BLOCK 1: Chair Kathryn Harrington (-410100) — routes county-wide via COUNTY district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kathryn Harrington', 'Kathryn', 'Harrington', NULL,
          true, false, false, true, -410100)
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
                               WHERE name = 'Washington County, Oregon, US')),
       p.id,
       'County Chair', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41067'
  AND d.district_type = 'COUNTY'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Commissioner District 1 Nafisa Fai (-410110) — routes via LOCAL X0018 D1 district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nafisa Fai', 'Nafisa', 'Fai', NULL,
          true, false, false, true, -410110)
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
                               WHERE name = 'Washington County, Oregon, US')),
       p.id,
       'Commissioner, District 1', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'washco-or-commissioner-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Commissioner District 2 Pam Treece (-410111) — routes via LOCAL X0018 D2 district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pam Treece', 'Pam', 'Treece', NULL,
          true, false, false, true, -410111)
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
                               WHERE name = 'Washington County, Oregon, US')),
       p.id,
       'Commissioner, District 2', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'washco-or-commissioner-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Commissioner District 3 Jason Snider (-410112) — routes via LOCAL X0018 D3 district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jason Snider', 'Jason', 'Snider', NULL,
          true, false, false, true, -410112)
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
                               WHERE name = 'Washington County, Oregon, US')),
       p.id,
       'Commissioner, District 3', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'washco-or-commissioner-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Commissioner District 4 Jerry Willey (-410113) — routes via LOCAL X0018 D4 district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jerry Willey', 'Jerry', 'Willey', NULL,
          true, false, false, true, -410113)
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
                               WHERE name = 'Washington County, Oregon, US')),
       p.id,
       'Commissioner, District 4', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'washco-or-commissioner-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 5 Washington County officials.
-- WHERE p.office_id IS NULL for idempotency. BETWEEN: more-negative bound first.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -410113 AND -410100
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count must be exactly 1
-- Gate (b): Chair office on COUNTY district (geo_id='41067') must be exactly 1
-- Gate (c): commissioner offices on LOCAL X0018 districts must be exactly 4
-- Gate (d): section-split detector must return 0 orphan rows for the COUNTY geofence
-- =============================================================================
DO $$
DECLARE
  v_gov_count          INTEGER;
  v_chair_offices      INTEGER;
  v_commissioner_offices INTEGER;
  v_split_count        INTEGER;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'Washington County, Oregon, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 WashCo government row, found %', v_gov_count;
  END IF;

  -- Gate (b): Chair office on COUNTY district (geo_id='41067') = 1
  SELECT COUNT(*) INTO v_chair_offices
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '41067'
    AND d.district_type = 'COUNTY'
    AND d.state = 'or';

  IF v_chair_offices <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Chair office on COUNTY district geo_id=41067, found %', v_chair_offices;
  END IF;

  -- Gate (c): commissioner offices on LOCAL X0018 districts = 4
  SELECT COUNT(*) INTO v_commissioner_offices
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'washco-or-commissioner-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'or';

  IF v_commissioner_offices <> 4 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 4 commissioner offices on LOCAL districts, found %', v_commissioner_offices;
  END IF;

  -- Gate (d): section-split detector for COUNTY geofence (geo_id=41067, mtfcc=G4020)
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '41067'
    AND gb.mtfcc = 'G4020'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'COUNTY'
        AND d.state = 'or'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=41067', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov_count=%, chair_offices=%, commissioner_offices=%, split_orphans=%',
    v_gov_count, v_chair_offices, v_commissioner_offices, v_split_count;
END $$;

COMMIT;

-- =============================================================================
-- Step 7: Migration ledger registration (OUTSIDE the transaction)
-- Structural migration registers with the 2-column (version, name) form.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1120', 'washco_commission')
ON CONFLICT (version) DO NOTHING;
