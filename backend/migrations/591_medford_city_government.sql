-- Migration 591: City of Medford, Massachusetts government (MEDFORD-01 — city gov portion)
-- geo_id: '2540115' (G4110, confirmed in DB, state='25')
-- IMPORTANT: Medford renamed 'Board of Aldermen' → 'City Council' in 2020 charter reform; using 'City Council'
-- 1 chamber: 'City Council' (name_formal='Medford City Council')
-- 1 LOCAL_EXEC district: label='Medford (Citywide)', mtfcc=NULL, state='ma'
-- 1 LOCAL district: label='Medford', mtfcc=NULL, state='ma'
-- 8 politicians: Mayor Lungo-Koehn (-2540115001) + 7 at-large City Councilors (-2540115002..-2540115008)
-- CRITICAL: Mayor last_name='Lungo-Koehn' (hyphenated — store as-is)
-- CRITICAL: Medford City Council is 7 AT-LARGE members; there are NO ward seats (verified from medfordma.org/citycouncil/)
--   Per City Charter: "The Medford City Council consists of 7 elected at-large members, elected every two years"
--   2026-2028 Council members: Bears (President), Lazzaro (VP), Callahan, Leming, Mullane, Scarpelli, Tseng
-- CRITICAL: 'City Councilor' NOT 'City Councillor' — American spelling
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard
-- CRITICAL: districts.state = 'ma' (lowercase) for LOCAL, LOCAL_EXEC
-- CRITICAL: governments.state = 'MA' (uppercase)
-- CRITICAL: offices.representing_state = 'MA' (uppercase)
-- CRITICAL: mtfcc=NULL on all LOCAL and LOCAL_EXEC district rows (not 'G4110')
-- CRITICAL: party=NULL (antipartisan design)
-- CRITICAL: Isaac Bears goes by 'Zac'; official first_name stored as 'Isaac' (nickname dropped per DB convention)
-- CRITICAL: Council President Bears title stays 'City Councilor' — President is internal officer role (D-06)
-- School Committee seeded separately in migration 592 (Plan 04)
--
-- Roster verified 2026-06-15 from medfordma.org/citycouncil/:
--   Mayor Breanna Lungo-Koehn (third term, sworn in Jan 2020)
--   At-Large: Isaac Bears (Council President), Emily Lazzaro (Vice President), Anna Callahan,
--             Matt Leming, Liz Mullane, George Scarpelli, Justin Tseng
--
-- Applied to production via mcp__supabase-local__execute_sql.

-- =============================================================================
-- Pre-flight 1: RAISE EXCEPTION if government row already exists (abort on double-apply)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Medford, Massachusetts, US') > 0 THEN
    RAISE EXCEPTION 'Migration 591 already applied — aborting re-run: City of Medford government row already exists.';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Assert Medford G4110 geofence is present (from v5.0 MA TIGER load)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2540115' AND mtfcc = 'G4110';
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Medford G4110 geofence (geo_id=2540115) not found — must be loaded from v5.0 MA TIGER load.';
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: Medford G4110 geofence present (% rows)', v_count;
END $$;

-- =============================================================================
-- Pre-flight 3: Assert external_id range -2540115008..-2540115001 is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -2540115008 AND -2540115001;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -2540115001..-2540115008 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: external_id range is clear';
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Government row (City of Medford, Massachusetts, US)
-- type='LOCAL', state='MA' (uppercase), city='Medford', geo_id='2540115'
-- WHERE NOT EXISTS guard — governments has no unique constraint on geo_id.
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Medford, Massachusetts, US',
       'LOCAL', 'MA', 'Medford', '2540115'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Medford, Massachusetts, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- Single chamber covers all 7 at-large council seats.
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- CRITICAL: Board of Aldermen was renamed City Council in 2020 charter reform.
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Medford City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Medford, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Medford, Massachusetts, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district (Mayor Lungo-Koehn — citywide)
-- geo_id='2540115' matches existing G4110 geofence_boundary.
-- state='ma' LOWERCASE (routing query convention).
-- mtfcc=NULL — no TIGER mtfcc for LOCAL_EXEC districts.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'ma', '2540115', 'Medford (Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2540115' AND district_type = 'LOCAL_EXEC' AND state = 'ma'
);

-- =============================================================================
-- Step 3b: LOCAL district — all 7 at-large councilors share this single city-wide district
-- Tier 3 pattern: no per-ward geofences; Medford has no ward seats at all.
-- mtfcc=NULL — no TIGER mtfcc for LOCAL districts.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', '2540115', 'Medford', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2540115' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 4: Politicians + offices (8 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='MA' uppercase
-- Mayor links to LOCAL_EXEC district; all 7 councilors link to LOCAL district.
-- =============================================================================

-- BLOCK 1: Mayor Breanna Lungo-Koehn (-2540115001) — links to LOCAL_EXEC district
-- Hyphenated last name stored as-is: 'Lungo-Koehn'
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Breanna Lungo-Koehn', 'Breanna', 'Lungo-Koehn', NULL,
          true, false, false, true, -2540115001)
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
                               WHERE name = 'City of Medford, Massachusetts, US')),
       p.id,
       'Mayor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2540115'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: At-Large Councilor Isaac Bears (-2540115002) — Council President
-- Official name: Isaac B. "Zac" Bears; stored as Isaac Bears (drop middle initial, drop nickname per DB convention)
-- CRITICAL: title is 'City Councilor' — NOT 'City Council President' (internal officer role, not charter office)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Isaac Bears', 'Isaac', 'Bears', NULL,
          true, false, false, true, -2540115002)
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
                               WHERE name = 'City of Medford, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2540115'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: At-Large Councilor Emily Lazzaro (-2540115003) — Vice President
-- CRITICAL: title is 'City Councilor' — VP is an internal officer role, not a charter office
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Emily Lazzaro', 'Emily', 'Lazzaro', NULL,
          true, false, false, true, -2540115003)
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
                               WHERE name = 'City of Medford, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2540115'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: At-Large Councilor Anna Callahan (-2540115004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anna Callahan', 'Anna', 'Callahan', NULL,
          true, false, false, true, -2540115004)
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
                               WHERE name = 'City of Medford, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2540115'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: At-Large Councilor Matt Leming (-2540115005)
-- Official name: Matthew Leming; goes by Matt Leming per council listing
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Leming', 'Matt', 'Leming', NULL,
          true, false, false, true, -2540115005)
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
                               WHERE name = 'City of Medford, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2540115'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: At-Large Councilor Liz Mullane (-2540115006)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Liz Mullane', 'Liz', 'Mullane', NULL,
          true, false, false, true, -2540115006)
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
                               WHERE name = 'City of Medford, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2540115'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: At-Large Councilor George Scarpelli (-2540115007)
-- Official name: George A. Scarpelli — drop middle initial per DB convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'George Scarpelli', 'George', 'Scarpelli', NULL,
          true, false, false, true, -2540115007)
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
                               WHERE name = 'City of Medford, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2540115'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: At-Large Councilor Justin Tseng (-2540115008)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Justin Tseng', 'Justin', 'Tseng', NULL,
          true, false, false, true, -2540115008)
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
                               WHERE name = 'City of Medford, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2540115'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 8 Medford city officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -2540115008 AND -2540115001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (7 gates)
-- Raises EXCEPTION on any failure.
-- Gate (a): 1 government row
-- Gate (b): 1 City Council chamber
-- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
-- Gate (d): 8 politicians in external_id range
-- Gate (e): 8 offices linked to Medford districts
-- Gate (f): section-split = 0 orphan geofences for geo_id='2540115'
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
  WHERE name = 'City of Medford, Massachusetts, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Medford government row, found %', v_gov_count;
  END IF;

  -- Gate (b): City Council chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Medford, Massachusetts, US');

  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City Council chamber for Medford, found %', v_chamber_count;
  END IF;

  -- Gate (c): 2 district rows (1 LOCAL_EXEC + 1 LOCAL)
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2540115'
    AND district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_dist_count <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 2 Medford district rows (LOCAL_EXEC + LOCAL), found %', v_dist_count;
  END IF;

  -- Gate (d): 8 politicians
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -2540115008 AND -2540115001;

  IF v_pol_count <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 8 politicians in range -2540115001..-2540115008, found %', v_pol_count;
  END IF;

  -- Gate (e): 8 offices linked to Medford districts
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.state = 'ma'
    AND d.geo_id = '2540115'
    AND d.district_type IN ('LOCAL_EXEC', 'LOCAL');

  IF v_off_count <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 8 offices linked to Medford districts, found %', v_off_count;
  END IF;

  -- Gate (f): section-split detector
  -- Medford G4110 geofence must have at least one district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2540115'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.state = 'ma'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=2540115', v_split_count;
  END IF;

  -- Gate (g): office_id back-fill completeness
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -2540115008 AND -2540115001
    AND office_id IS NULL;

  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in external_id range have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 591 post-verification PASSED: gov=%, chambers=%, districts=%, politicians=%, offices=%, split_orphans=%, null_office_ids=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('591')
ON CONFLICT (version) DO NOTHING;

COMMIT;
