-- Migration 1150: City of Hillsboro government + chamber + districts + officials + offices
--
-- Purpose: Seeds the City of Hillsboro, Oregon (Washington County seat / largest west-metro city):
--   Hillsboro (geo_id='4134100') — 1 gov + 1 chamber + 2 districts + 7 officials + 7 offices
--
-- Form of government (RESEARCH-confirmed, re-verified at Wave-0 2026-07-01):
--   Council-manager. Mayor Beach Pace is DIRECTLY ELECTED (is_appointed_position=false).
--   6 Councilors elected AT-LARGE citywide; "Ward N / Position X" labels are candidacy-residency
--   descriptors only — NOT voting boundaries. NO wards — no custom geofences (D-01/D-02).
--   Structurally identical to Beaverton (migration 1131); this is a direct adaptation of that block.
--
-- CRITICAL: the generated identifier column on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='LOCAL_EXEC' for Mayor; district_type='LOCAL' for council (NOT 'COUNTY').
-- CRITICAL: at-large councilors — NO ward geofences (D-01/D-02).
-- CRITICAL: representing_city='Hillsboro' is set INLINE on every office INSERT (D-09) — unlike
--           Beaverton, which needed a follow-up backfill migration (1141), Hillsboro avoids that
--           gap entirely so the community banner derives correctly at first browse.
-- CRITICAL: Rob Harris (Ward 3, Position B) holds the Council President title — this is a title
--           on his seat, NOT a separate office row (D-07). ONE office row only.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE EXCEPTION if the Hillsboro government row already exists (hard abort guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Hillsboro, Oregon, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1150 already applied — aborting re-run';
  END IF;
END $$;


-- =============================================================================
-- HILLSBORO (geo_id='4134100')
-- 7 officials: Mayor Beach Pace + 6 councilors (Ward 1-3, Position A/B, at-large)
-- =============================================================================

-- Step 1: Government row
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Hillsboro, Oregon, US',
       'LOCAL', 'OR', 'Hillsboro', '4134100'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Hillsboro, Oregon, US'
);

-- Step 2: City Council chamber (generated identifier column omitted intentionally)
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'Hillsboro City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Hillsboro, Oregon, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Hillsboro, Oregon, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — citywide)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4134100', 'Hillsboro (Mayor, Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4134100' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- Step 4: LOCAL at-large district (all 6 councilors share this)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4134100', 'Hillsboro (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4134100' AND district_type = 'LOCAL' AND state = 'or'
);

-- Step 5: Mayor Beach Pace (-4134101) — directly elected
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Beach Pace', 'Beach', 'Pace', NULL,
          true, false, false, true, -4134101)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Hillsboro, Oregon, US')),
       p.id,
       'Mayor', 'OR', 'Hillsboro', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4134100'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Councilor Ward 1 Position A: Cristian Salgado (-4134102)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cristian Salgado', 'Cristian', 'Salgado', NULL,
          true, false, false, true, -4134102)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Hillsboro, Oregon, US')),
       p.id,
       'Councilor, Ward 1, Position A', 'OR', 'Hillsboro', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4134100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Councilor Ward 1 Position B: Saba Anvery (-4134103)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Saba Anvery', 'Saba', 'Anvery', NULL,
          true, false, false, true, -4134103)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Hillsboro, Oregon, US')),
       p.id,
       'Councilor, Ward 1, Position B', 'OR', 'Hillsboro', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4134100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Councilor Ward 2 Position A: Kipperlyn Sinclair (-4134104)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kipperlyn Sinclair', 'Kipperlyn', 'Sinclair', NULL,
          true, false, false, true, -4134104)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Hillsboro, Oregon, US')),
       p.id,
       'Councilor, Ward 2, Position A', 'OR', 'Hillsboro', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4134100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Councilor Ward 2 Position B: Elizabeth Case (-4134105)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth Case', 'Elizabeth', 'Case', NULL,
          true, false, false, true, -4134105)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Hillsboro, Oregon, US')),
       p.id,
       'Councilor, Ward 2, Position B', 'OR', 'Hillsboro', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4134100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: Councilor Ward 3 Position A: Olivia Alcaire (-4134106)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Olivia Alcaire', 'Olivia', 'Alcaire', NULL,
          true, false, false, true, -4134106)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Hillsboro, Oregon, US')),
       p.id,
       'Councilor, Ward 3, Position A', 'OR', 'Hillsboro', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4134100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 11: Councilor Ward 3 Position B: Rob Harris (-4134107)
-- Harris holds the Council President title — that is a title, not a separate seat.
-- ONE office row only (title text stays 'Councilor, Ward 3, Position B').
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rob Harris', 'Rob', 'Harris', NULL,
          true, false, false, true, -4134107)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Hillsboro, Oregon, US')),
       p.id,
       'Councilor, Ward 3, Position B', 'OR', 'Hillsboro', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4134100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- office_id back-fill (all 7 Hillsboro officials)
-- Explicit IN list; WHERE p.office_id IS NULL for idempotency
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -4134101,-4134102,-4134103,-4134104,-4134105,-4134106,-4134107
  )
  AND p.office_id IS NULL;


-- =============================================================================
-- Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction
-- Gates: (a) gov=1  (b) office=7  (c) section-split=0  (d) office_id back-fill nulls=0
--        (e) representing_city='Hillsboro' set inline on all 7 offices
-- =============================================================================
DO $$
DECLARE
  v_gov_count      INTEGER;
  v_office_count   INTEGER;
  v_split_count    INTEGER;
  v_null_count     INTEGER;
  v_repcity_count  INTEGER;
BEGIN

  -- Gate (a): Hillsboro government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Hillsboro, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Hillsboro gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b): Hillsboro offices linked to LOCAL/LOCAL_EXEC districts
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4134100' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Hillsboro office_count=%, expected 7', v_office_count;
  END IF;

  -- Gate (c): Section-split check — the G4110 geofence for 4134100 must have LOCAL and LOCAL_EXEC rows
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '4134100'
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
    -4134101,-4134102,-4134103,-4134104,-4134105,-4134106,-4134107
  )
  AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  -- Gate (e), Hillsboro-specific: representing_city set inline (no backfill mig needed, per D-09)
  SELECT COUNT(*) INTO v_repcity_count
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -4134107 AND -4134101
    AND o.representing_city = 'Hillsboro';
  IF v_repcity_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 Hillsboro offices have representing_city=Hillsboro', v_repcity_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: Hillsboro gov=1, offices=7, section-split=0, office_id nulls=0, representing_city=7';
END $$;


-- =============================================================================
-- Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1150')
ON CONFLICT (version) DO NOTHING;

COMMIT;
