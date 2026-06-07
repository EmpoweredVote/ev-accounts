-- Migration 276: St. Mary's County government + chamber + COUNTY district + 5 officials + offices
--
-- Purpose: Seeds St. Mary's County Board of County Commissioners under geo_id='24037'.
--   - 1 government row: 'St. Mary''s County, Maryland, US' (type='County', state='MD', geo_id='24037')
--   - 1 chamber row: 'Board of County Commissioners' (no slug — GENERATED ALWAYS)
--   - 1 COUNTY district row: geo_id='24037', mtfcc='G4020', state='md', district_type='COUNTY'
--   - 5 politicians: President (-24037001) + Commissioners D1-D4 (-24037002..-24037005)
--   - 5 offices: all linked to the COUNTY district (geo_id='24037')
--   - office_id back-fill on all 5 politicians
--
-- Geofence boundary (G4020, geo_id='24037', state='24') was loaded in Phase 91 — do NOT re-insert.
-- Applied to production Supabase via Supabase MCP.
-- D-05 RESOLVED (Option A): All 5 commissioners elected county-wide; one COUNTY district, 5 offices.
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'md' (lowercase) for COUNTY type to match routing queries.
-- CRITICAL: governments.state = 'MD' (uppercase) — government table convention.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'St. Mary''s County, Maryland, US') > 0 THEN
    RAISE NOTICE 'St. Mary''s County government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (St. Mary's County, Maryland, US)
-- type='County' matches Multnomah County precedent (migration 244).
-- state='MD' uppercase (governments table convention).
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'St. Mary''s County, Maryland, US',
       'County', 'MD', NULL, '24037'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'St. Mary''s County, Maryland, US'
);

-- =============================================================================
-- Step 2: Board of County Commissioners chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of County Commissioners',
       'St. Mary''s County Board of County Commissioners',
       (SELECT id FROM essentials.governments
        WHERE name = 'St. Mary''s County, Maryland, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of County Commissioners'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'St. Mary''s County, Maryland, US')
);

-- =============================================================================
-- Step 3: COUNTY district row
-- geo_id='24037' matches the existing G4020 geofence_boundary loaded in Phase 91.
-- state='md' LOWERCASE — matches routing query WHERE d.state = $1 (geocoder returns lowercase 'md').
-- mtfcc='G4020' matches the geofence_boundaries row for ST_Covers JOIN.
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'COUNTY', 'md', '24037', 'St. Mary''s County', 'G4020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '24037' AND district_type = 'COUNTY' AND state = 'md'
);

-- =============================================================================
-- Step 4: Politicians + offices (5 blocks — President + Commissioners D1-D4)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='MD' uppercase (offices table convention)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- All 5 offices link to the SAME COUNTY district (D-05 Option A — county-wide election model)
-- =============================================================================

-- BLOCK 1: President James R. Guy (-24037001)
-- Note: Goes by "Randy" but legal name is James R. Guy; full_name='James R. Guy'
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James R. Guy', 'James', 'Guy', NULL,
          true, false, false, true, -24037001)
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
                               WHERE name = 'St. Mary''s County, Maryland, US')),
       p.id,
       'President, Board of County Commissioners', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '24037'
  AND d.district_type = 'COUNTY'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Commissioner District 1 Eric Colvin (-24037002)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eric Colvin', 'Eric', 'Colvin', NULL,
          true, false, false, true, -24037002)
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
                               WHERE name = 'St. Mary''s County, Maryland, US')),
       p.id,
       'Commissioner, District 1', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '24037'
  AND d.district_type = 'COUNTY'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Commissioner District 2 Michael L. Hewitt (-24037003)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael L. Hewitt', 'Michael', 'Hewitt', NULL,
          true, false, false, true, -24037003)
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
                               WHERE name = 'St. Mary''s County, Maryland, US')),
       p.id,
       'Commissioner, District 2', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '24037'
  AND d.district_type = 'COUNTY'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Commissioner District 3 Mike Alderson, Jr. (-24037004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Alderson, Jr.', 'Mike', 'Alderson', NULL,
          true, false, false, true, -24037004)
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
                               WHERE name = 'St. Mary''s County, Maryland, US')),
       p.id,
       'Commissioner, District 3', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '24037'
  AND d.district_type = 'COUNTY'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Commissioner District 4 Scott R. Ostrow (-24037005)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Scott R. Ostrow', 'Scott', 'Ostrow', NULL,
          true, false, false, true, -24037005)
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
                               WHERE name = 'St. Mary''s County, Maryland, US')),
       p.id,
       'Commissioner, District 4', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '24037'
  AND d.district_type = 'COUNTY'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 5 St. Mary's County officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -24037005 AND -24037001
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
  WHERE name = 'St. Mary''s County, Maryland, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 St. Mary''s County government row, found %', v_gov_count;
  END IF;

  -- Gate (b): offices linked to COUNTY district
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '24037'
    AND d.district_type = 'COUNTY'
    AND d.state = 'md';

  IF v_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 offices linked to geo_id=24037 COUNTY district, found %', v_office_count;
  END IF;

  -- Gate (c): section-split detector
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '24037'
    AND gb.mtfcc = 'G4020'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'COUNTY'
        AND d.state = 'md'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=24037', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov_count=%, office_count=%, split_orphans=%',
    v_gov_count, v_office_count, v_split_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('276')
ON CONFLICT (version) DO NOTHING;

COMMIT;
