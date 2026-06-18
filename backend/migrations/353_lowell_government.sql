-- Migration 353: City of Lowell government (MA-TIER2-02 — Plan E council-manager)
--
-- Purpose: Seeds City of Lowell government and City Council using Plan E (council-manager) model.
--   - 1 government row: 'City of Lowell, Massachusetts, US' (type='LOCAL', state='MA', city='Lowell', geo_id='2537000')
--   - 1 chamber row: 'City Council' (name_formal='Lowell City Council'; no slug — GENERATED ALWAYS)
--   - 1 LOCAL district row: geo_id='2537000', mtfcc=NULL, state='ma', label='Lowell'
--   - 12 politicians: City Manager Golden (-253700001) + Mayor Gitschier (-253700002) + 10 councillors (-253700003..-253700012)
--   - 12 offices: all link to the single LOCAL district (no exec district — council-manager model)
--   - office_id back-fill on all 12 politicians
--
-- Lowell is Plan E (council-manager) — no exec district; single LOCAL district only.
-- City Manager + Mayor are is_appointed=true (Cambridge precedent: Huang + Siddiqui).
-- The 10 councillors are is_appointed=false (popularly elected).
-- Lowell geo_id='2537000' (G4110) already in geofence_boundaries (v5.0) — do NOT re-insert.
--
-- CRITICAL: Only a single LOCAL district for Lowell — council-manager model, no exec district (Pitfall 2).
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state = 'ma' (lowercase) for LOCAL — matches routing queries.
-- CRITICAL: governments.state = 'MA' (uppercase) — government table convention.
-- CRITICAL: offices.representing_state = 'MA' (uppercase) — offices table convention.
-- CRITICAL: mtfcc=NULL on LOCAL district row (no per-district geofences for Lowell).
-- CRITICAL: party=NULL (antipartisan design — D-15).
-- CRITICAL: is_appointed=true for City Manager and council-elected Mayor; is_appointed=false for all 10 councillors.
--
-- Roster verified 2026-06-10 from lowellma.gov/533/Meet-the-City-Council + lowellma.gov/198/City-Manager:
--   City Manager: Thomas A. Golden, Jr.
--   Mayor (council-elected, at-large): Erik R. Gitschier
--   Councillors-at-Large: Rita Mercier, Vesna Nuon
--   District 1: Daniel Rourke
--   District 2: Corey Robinson
--   District 3: Belinda M. Juran
--   District 4: Sean McDonough
--   District 5: Kimberly Scott
--   District 6: Sokhary Chau
--   District 7: Sidney L. Liang
--   District 8: John Descoteaux
--
-- Applied to production via mcp__supabase-local__execute_sql.

-- =============================================================================
-- Pre-flight 1: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Lowell, Massachusetts, US') > 0 THEN
    RAISE NOTICE 'City of Lowell government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Assert Lowell G4110 geofence is present (do NOT re-insert)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2537000' AND mtfcc = 'G4110';
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Lowell G4110 geofence (geo_id=2537000) not found. Expected from Phase 38 MA TIGER load.';
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: Lowell G4110 geofence present';
END $$;

-- =============================================================================
-- Pre-flight 3: Assert external_id range -253700012..-253700001 is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -253700012 AND -253700001;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -253700001..-253700012 is not clear (% rows found)', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: external_id range is clear';
END $$;

-- =============================================================================
-- Step 1: Government row (City of Lowell, Massachusetts, US)
-- type='LOCAL', state='MA' (uppercase), city='Lowell', geo_id='2537000'
-- WHERE NOT EXISTS guard — governments has no unique constraint on geo_id (D-14).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Lowell, Massachusetts, US',
       'LOCAL', 'MA', 'Lowell', '2537000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Lowell, Massachusetts, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- Single chamber covers all 12 seats (City Manager + Mayor + 10 councillors).
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list (D-13).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'City Council',
       'Lowell City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Lowell, Massachusetts, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Lowell, Massachusetts, US')
);

-- =============================================================================
-- Step 3: LOCAL district (all 12 officials share this single district)
-- Lowell is Plan E (council-manager) — single LOCAL district only, no exec district.
-- Cambridge precedent: is_appointed officials (City Manager + council-elected Mayor)
-- live in the same LOCAL district as the elected councillors.
-- geo_id='2537000' matches existing G4110 geofence_boundary.
-- state='ma' LOWERCASE (D-10 — routing query convention).
-- mtfcc=NULL — no per-district TIGER boundaries for Lowell council seats.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', '2537000', 'Lowell', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2537000' AND district_type = 'LOCAL' AND state = 'ma'
);
-- No exec district INSERT for Lowell (council-manager city — Pitfall 2)

-- =============================================================================
-- Step 4: Politicians + offices (12 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design — D-15)
-- is_appointed=true for City Manager and council-elected Mayor (Cambridge precedent)
-- is_appointed=false for all 10 elected councillors
-- is_appointed_position=true for City Manager office; false for all councillor offices
-- representing_state='MA' uppercase (D-11)
-- All 12 offices link to the single LOCAL district (geo_id='2537000')
-- =============================================================================

-- BLOCK 1: City Manager Thomas A. Golden, Jr. (-253700001) — is_appointed=true
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thomas A. Golden, Jr.', 'Thomas', 'Golden', NULL,
          true, true, false, true, -253700001)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Manager', 'MA', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Mayor Erik R. Gitschier (-253700002) — is_appointed=true (council-elected)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Erik R. Gitschier', 'Erik', 'Gitschier', NULL,
          true, true, false, true, -253700002)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'Mayor', 'MA', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Councillor-at-Large Rita Mercier (-253700003) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rita Mercier', 'Rita', 'Mercier', NULL,
          true, false, false, true, -253700003)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Councillor-at-Large Vesna Nuon (-253700004) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vesna Nuon', 'Vesna', 'Nuon', NULL,
          true, false, false, true, -253700004)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: District 1 Councillor Daniel Rourke (-253700005) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniel Rourke', 'Daniel', 'Rourke', NULL,
          true, false, false, true, -253700005)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor (District 1)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: District 2 Councillor Corey Robinson (-253700006) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Corey Robinson', 'Corey', 'Robinson', NULL,
          true, false, false, true, -253700006)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor (District 2)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: District 3 Councillor Belinda M. Juran (-253700007) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Belinda M. Juran', 'Belinda', 'Juran', NULL,
          true, false, false, true, -253700007)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor (District 3)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: District 4 Councillor Sean McDonough (-253700008) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sean McDonough', 'Sean', 'McDonough', NULL,
          true, false, false, true, -253700008)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor (District 4)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: District 5 Councillor Kimberly Scott (-253700009) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kimberly Scott', 'Kimberly', 'Scott', NULL,
          true, false, false, true, -253700009)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor (District 5)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: District 6 Councillor Sokhary Chau (-253700010) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sokhary Chau', 'Sokhary', 'Chau', NULL,
          true, false, false, true, -253700010)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor (District 6)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: District 7 Councillor Sidney L. Liang (-253700011) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sidney L. Liang', 'Sidney', 'Liang', NULL,
          true, false, false, true, -253700011)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor (District 7)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: District 8 Councillor John Descoteaux (-253700012) — is_appointed=false
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Descoteaux', 'John', 'Descoteaux', NULL,
          true, false, false, true, -253700012)
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
                               WHERE name = 'City of Lowell, Massachusetts, US')),
       p.id,
       'City Councilor (District 8)', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2537000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ma'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 12 Lowell officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -253700012 AND -253700001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (7 gates)
-- Raises EXCEPTION on any failure.
-- Gate (a): 1 government row
-- Gate (b): 1 City Council chamber
-- Gate (c): 1 district row (LOCAL only — council-manager city, no exec district)
-- Gate (d): 12 politicians in external_id range
-- Gate (e): 12 offices linked to Lowell LOCAL district
-- Gate (f): section-split = 0 orphan geofences for geo_id='2537000'
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
  WHERE name = 'City of Lowell, Massachusetts, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Lowell government row, found %', v_gov_count;
  END IF;

  -- Gate (b): City Council chamber
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Lowell, Massachusetts, US');

  IF v_chamber_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City Council chamber, found %', v_chamber_count;
  END IF;

  -- Gate (c): 1 district row (LOCAL only — council-manager city has no exec district)
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2537000'
    AND district_type = 'LOCAL';

  IF v_dist_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Lowell LOCAL district row, found % (council-manager model — no exec district)', v_dist_count;
  END IF;

  -- Gate (d): 12 politicians
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -253700012 AND -253700001;

  IF v_pol_count <> 12 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 12 politicians in range -253700001..-253700012, found %', v_pol_count;
  END IF;

  -- Gate (e): 12 offices linked to Lowell LOCAL district
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.state = 'ma'
    AND d.geo_id = '2537000'
    AND d.district_type = 'LOCAL';

  IF v_off_count <> 12 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 12 offices linked to Lowell LOCAL district, found %', v_off_count;
  END IF;

  -- Gate (f): section-split detector
  -- Lowell G4110 geofence must have at least one LOCAL district row
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2537000'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.state = 'ma'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=2537000', v_split_count;
  END IF;

  -- Gate (g): office_id back-fill completeness
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -253700012 AND -253700001
    AND office_id IS NULL;

  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in external_id range have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 353 post-verification PASSED: gov=%, chambers=%, districts=%, politicians=%, offices=%, split_orphans=%, null_office_ids=%',
    v_gov_count, v_chamber_count, v_dist_count, v_pol_count, v_off_count, v_split_count, v_null_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('353')
ON CONFLICT (version) DO NOTHING;
