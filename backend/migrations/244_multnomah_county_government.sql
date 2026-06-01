-- Migration 244: Multnomah County government + chamber + COUNTY district + 5 officials + offices
--
-- Purpose: Seeds Multnomah County Board of Commissioners under geo_id='41051'.
--   - 1 government row: 'Multnomah County, Oregon, US' (type='County', state='OR', geo_id='41051')
--   - 1 chamber row: 'Board of Commissioners' (name_formal='Multnomah County Board of Commissioners')
--   - 1 COUNTY district row: geo_id='41051', mtfcc='G4020', state='or', district_type='COUNTY'
--   - 5 politicians: Chair (-410001) + Commissioners D1-D4 (-410010..-410013)
--   - 5 offices: all linked to the COUNTY district (geo_id='41051')
--   - office_id back-fill on all 5 politicians
--
-- Geofence boundary (G4020, geo_id='41051', state='41') was loaded in Phase 72 — do NOT re-insert.
-- Applied to production Supabase via Supabase MCP.
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) for COUNTY type to match routing queries.
--   Confirmed: all OR COUNTY/LOCAL/STATE_UPPER/STATE_LOWER districts use 'or' (lowercase).
--   Only NATIONAL_LOWER + STATE_EXEC use 'OR' (uppercase).
-- CRITICAL: governments.state = 'OR' (uppercase) — government table convention.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Multnomah County, Oregon, US') > 0 THEN
    RAISE NOTICE 'Multnomah County government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (Multnomah County, Oregon, US)
-- type='County' matches TX pattern (migration 087). state='OR' uppercase (governments convention).
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Multnomah County, Oregon, US',
       'County', 'OR', NULL, '41051'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Multnomah County, Oregon, US'
);

-- =============================================================================
-- Step 2: Board of Commissioners chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Commissioners',
       'Multnomah County Board of Commissioners',
       (SELECT id FROM essentials.governments WHERE name = 'Multnomah County, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Commissioners'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Multnomah County, Oregon, US')
);

-- =============================================================================
-- Step 3: COUNTY district row
-- geo_id='41051' matches the existing G4020 geofence_boundary loaded in Phase 72.
-- state='or' LOWERCASE — matches routing query WHERE d.state = $1 (geocoder returns lowercase 'or').
-- mtfcc='G4020' matches the geofence_boundaries row for ST_Covers JOIN.
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'COUNTY', 'or', '41051', 'Multnomah County', 'G4020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '41051' AND district_type = 'COUNTY' AND state = 'or'
);

-- =============================================================================
-- Step 4: Politicians + offices (5 blocks — Chair + Commissioners D1-D4)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan — all Multnomah County offices are nonpartisan)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='OR' uppercase (offices convention)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- =============================================================================

-- BLOCK 1: County Chair Jessica Vega Pederson (-410001)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jessica Vega Pederson', 'Jessica', 'Vega Pederson', NULL,
          true, false, false, true, -410001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Multnomah County, Oregon, US')),
       p.id,
       'County Chair', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41051'
  AND d.district_type = 'COUNTY'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Commissioner District 1 Meghan Moyer (-410010)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Meghan Moyer', 'Meghan', 'Moyer', NULL,
          true, false, false, true, -410010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Multnomah County, Oregon, US')),
       p.id,
       'Commissioner (District 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41051'
  AND d.district_type = 'COUNTY'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Commissioner District 2 Shannon Singleton (-410011)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shannon Singleton', 'Shannon', 'Singleton', NULL,
          true, false, false, true, -410011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Multnomah County, Oregon, US')),
       p.id,
       'Commissioner (District 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41051'
  AND d.district_type = 'COUNTY'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Commissioner District 3 Julia Brim-Edwards (-410012)
-- Note: photo filename on multco.us has "Jullia" (double-l) — this is a typo; correct name is "Julia"
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julia Brim-Edwards', 'Julia', 'Brim-Edwards', NULL,
          true, false, false, true, -410012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Multnomah County, Oregon, US')),
       p.id,
       'Commissioner (District 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41051'
  AND d.district_type = 'COUNTY'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Commissioner District 4 Vince Jones-Dixon (-410013)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vince Jones-Dixon', 'Vince', 'Jones-Dixon', NULL,
          true, false, false, true, -410013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Commissioners'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Multnomah County, Oregon, US')),
       p.id,
       'Commissioner (District 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '41051'
  AND d.district_type = 'COUNTY'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 5 Multnomah County officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -410013 AND -410001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count must be exactly 1
-- Gate (b): offices linked to COUNTY district must be exactly 5
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
  WHERE name = 'Multnomah County, Oregon, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Multnomah County government row, found %', v_gov_count;
  END IF;

  -- Gate (b): offices linked to COUNTY district
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '41051'
    AND d.district_type = 'COUNTY'
    AND d.state = 'or';

  IF v_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 offices linked to geo_id=41051 COUNTY district, found %', v_office_count;
  END IF;

  -- Gate (c): section-split detector
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '41051'
    AND gb.mtfcc = 'G4020'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'COUNTY'
        AND d.state = 'or'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=41051', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov_count=%, office_count=%, split_orphans=%',
    v_gov_count, v_office_count, v_split_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('244')
ON CONFLICT (version) DO NOTHING;

COMMIT;
