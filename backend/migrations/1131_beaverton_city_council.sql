-- Migration 1131: City of Beaverton government + chamber + districts + officials + offices
--
-- Purpose: Seeds the City of Beaverton, Oregon (flagship west-metro city):
--   Beaverton (geo_id='4105350') — 1 gov + 1 chamber + 2 districts + 7 officials + 7 offices
--
-- Form of government (RESEARCH-confirmed, 2020 charter Measure 34-298):
--   Council-manager. Mayor Lacey Beaty is DIRECTLY ELECTED (is_appointed_position=false).
--   6 Councilors elected AT-LARGE in numbered Positions 1-6. NO wards — no custom geofences.
--   Structurally identical to Gresham (migration 246); this is a direct adaptation of that block.
--
-- CRITICAL: the generated identifier column on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='LOCAL_EXEC' for Mayor; district_type='LOCAL' for council (NOT 'COUNTY').
-- CRITICAL: at-large Positions 1-6 — NO ward geofences.
-- CRITICAL: Position 3 Edward Kimmi holds the rotational Council President title — this is a title,
--           NOT a separate seat: ONE office row only.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE EXCEPTION if the Beaverton government row already exists (hard abort guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Beaverton, Oregon, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1131 already applied — aborting re-run';
  END IF;
END $$;


-- =============================================================================
-- BEAVERTON (geo_id='4105350')
-- 7 officials: Mayor Lacey Beaty + 6 councilors (Position 1-6, at-large)
-- =============================================================================

-- Step 1: Government row
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Beaverton, Oregon, US',
       'LOCAL', 'OR', 'Beaverton', '4105350'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Beaverton, Oregon, US'
);

-- Step 2: City Council chamber (generated identifier column omitted intentionally)
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'Beaverton City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Beaverton, Oregon, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Beaverton, Oregon, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — citywide)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4105350', 'Beaverton (Mayor, Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4105350' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- Step 4: LOCAL at-large district (all 6 councilors share this)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4105350', 'Beaverton (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4105350' AND district_type = 'LOCAL' AND state = 'or'
);

-- Step 5: Mayor Lacey Beaty (-4105351) — directly elected
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lacey Beaty', 'Lacey', 'Beaty', NULL,
          true, false, false, true, -4105351)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
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
                               WHERE name = 'City of Beaverton, Oregon, US')),
       p.id,
       'Mayor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4105350'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Council Member Position 1 Ashley Hartmeier-Prigg (-4105352)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ashley Hartmeier-Prigg', 'Ashley', 'Hartmeier-Prigg', NULL,
          true, false, false, true, -4105352)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
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
                               WHERE name = 'City of Beaverton, Oregon, US')),
       p.id,
       'Council Member (Position 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4105350'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Council Member Position 2 Kevin Teater (-4105353)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Teater', 'Kevin', 'Teater', NULL,
          true, false, false, true, -4105353)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
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
                               WHERE name = 'City of Beaverton, Oregon, US')),
       p.id,
       'Council Member (Position 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4105350'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Council Member Position 3 Edward Kimmi (-4105354)
-- Kimmi holds the rotational Council President title — that is a title, not a separate seat.
-- ONE office row only.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Edward Kimmi', 'Edward', 'Kimmi', NULL,
          true, false, false, true, -4105354)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
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
                               WHERE name = 'City of Beaverton, Oregon, US')),
       p.id,
       'Council Member (Position 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4105350'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Council Member Position 4 Allison Tivnon (-4105355)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Allison Tivnon', 'Allison', 'Tivnon', NULL,
          true, false, false, true, -4105355)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
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
                               WHERE name = 'City of Beaverton, Oregon, US')),
       p.id,
       'Council Member (Position 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4105350'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: Council Member Position 5 John Dugger (-4105356)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Dugger', 'John', 'Dugger', NULL,
          true, false, false, true, -4105356)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
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
                               WHERE name = 'City of Beaverton, Oregon, US')),
       p.id,
       'Council Member (Position 5)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4105350'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 11: Council Member Position 6 Nadia Hasan (-4105357)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nadia Hasan', 'Nadia', 'Hasan', NULL,
          true, false, false, true, -4105357)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
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
                               WHERE name = 'City of Beaverton, Oregon, US')),
       p.id,
       'Council Member (Position 6)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4105350'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- office_id back-fill (all 7 Beaverton officials)
-- Explicit IN list; WHERE p.office_id IS NULL for idempotency
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -4105351,-4105352,-4105353,-4105354,-4105355,-4105356,-4105357
  )
  AND p.office_id IS NULL;


-- =============================================================================
-- Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction
-- Gates: (a) gov=1  (b) office=7  (c) section-split=0  (d) office_id back-fill nulls=0
-- =============================================================================
DO $$
DECLARE
  v_gov_count    INTEGER;
  v_office_count INTEGER;
  v_split_count  INTEGER;
  v_null_count   INTEGER;
BEGIN

  -- Gate (a): Beaverton government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Beaverton, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Beaverton gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b): Beaverton offices linked to LOCAL/LOCAL_EXEC districts
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4105350' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Beaverton office_count=%, expected 7', v_office_count;
  END IF;

  -- Gate (c): Section-split check — the G4110 geofence for 4105350 must have LOCAL and LOCAL_EXEC rows
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '4105350'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
        AND d.state = 'or'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows', v_split_count;
  END IF;

  -- Gate (d): office_id back-fill — all 7 politicians must have non-null office_id
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4105351,-4105352,-4105353,-4105354,-4105355,-4105356,-4105357
  )
  AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: Beaverton gov=1, offices=7, section-split=0, office_id back-fill complete';
END $$;


-- =============================================================================
-- Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1131')
ON CONFLICT (version) DO NOTHING;

COMMIT;
