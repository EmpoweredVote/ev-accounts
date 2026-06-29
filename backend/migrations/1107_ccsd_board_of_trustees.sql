-- Migration 1107: Clark County School District government + Board of School Trustees + SCHOOL district + 11 trustees
--
-- Purpose: Deep-seeds the Clark County School District (CCSD — 5th-largest US district):
--   1 government 'Clark County School District, Nevada, US' (type='LOCAL', geo_id='3200060')
--   1 chamber 'Board of School Trustees' (official_count=11)
--   1 shared SCHOOL district on geo_id='3200060' (the SF/SD/Portland single-shared-district pattern)
--   11 trustees: 7 elected (Districts A-G) + 4 appointed (per NV AB175/2023, by jurisdiction)
--
-- CRITICAL: the auto-generated column on essentials.chambers is GENERATED ALWAYS — never in the INSERT list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'nv' (lowercase) to match routing queries (uppercase = 0 rows).
-- CRITICAL: governments.state = 'NV' (uppercase). offices.representing_state = 'NV' (uppercase).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: the G5420 geofence row (geo_id='3200060') must exist BEFORE this migration runs (loaded by load-ccsd-school-boundary.ts).
-- CRITICAL: party=NULL on all 11 trustees (antipartisan).
-- CRITICAL: 7 elected → is_appointed=false / is_appointed_position=false; 4 appointed → both TRUE, title carries jurisdiction (NO fabricated district letter).
-- CRITICAL: board officers (President/VP/Clerk) are titles on existing elected trustees — NOT separate seats (11 seats, not 14).
-- CRITICAL: Save this file as UTF-8 (Esparza-Stoffregan + en-dash in appointed titles).
--
-- Applied to production Supabase via psql -f (DATABASE_URL from C:/EV-Accounts/backend/.env).

BEGIN;

-- =============================================================================
-- Pre-flight: idempotent NOTICE if the CCSD government already exists
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Clark County School District, Nevada, US') > 0 THEN
    RAISE NOTICE 'Clark County School District government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row
-- type='LOCAL' matches the school-district precedent (254_or). state='NV' uppercase.
-- WHERE NOT EXISTS guard — governments has no unique constraint on geo_id.
-- Standalone (geo_id='3200060'), NOT nested under State of Nevada (geo_id='32').
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Clark County School District, Nevada, US',
       'LOCAL', 'NV', NULL, '3200060'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Clark County School District, Nevada, US'
);

-- =============================================================================
-- Step 2: Board of School Trustees chamber
-- The auto-generated column is GENERATED ALWAYS — never in the INSERT list.
-- official_count=11 (7 elected + 4 appointed). name_formal non-empty.
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Board of School Trustees',
       'Clark County School District Board of School Trustees',
       (SELECT id FROM essentials.governments WHERE name = 'Clark County School District, Nevada, US'),
       11
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of School Trustees'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Clark County School District, Nevada, US')
);

-- =============================================================================
-- Step 3: ONE shared SCHOOL district (the SF/SD/Portland single-shared-district pattern)
-- district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT'); state='nv' LOWERCASE; mtfcc='G5420'.
-- All 11 trustee offices attach here. NOT one district per trustee.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'nv', '3200060', 'Clark County School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '3200060' AND district_type = 'SCHOOL' AND state = 'nv'
);

-- =============================================================================
-- Step 4: Politicians + offices (11 blocks)
-- 7 ELECTED (Districts A-G): is_appointed=false, is_appointed_position=false, title='Trustee, District X'.
-- 4 APPOINTED (AB175/2023): is_appointed=true, is_appointed_position=true, title='Trustee, Appointed - <Jurisdiction>'.
-- party=NULL; is_active=true; is_incumbent=true. representing_state='NV' uppercase.
-- All 11 link to the ONE SCHOOL district (geo_id='3200060', district_type='SCHOOL', state='nv').
-- ON CONFLICT (external_id) DO NOTHING; office guard NOT EXISTS (district_id, politician_id).
-- =============================================================================

-- BLOCK 1: Emily Stevens (District A; Board President - officer title on seat, NOT a separate seat) — -3209001
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Emily Stevens', 'Emily', 'Stevens', NULL,
          true, false, false, true, -3209001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, District A', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Lydia Dominguez (District B; Board Clerk - officer title on seat) — -3209002
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lydia Dominguez', 'Lydia', 'Dominguez', NULL,
          true, false, false, true, -3209002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, District B', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Tameka Henry (District C) — -3209003
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tameka Henry', 'Tameka', 'Henry', NULL,
          true, false, false, true, -3209003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, District C', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Brenda Zamora (District D) — -3209004
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brenda Zamora', 'Brenda', 'Zamora', NULL,
          true, false, false, true, -3209004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, District D', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Lorena Biassotti (District E) — -3209005
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lorena Biassotti', 'Lorena', 'Biassotti', NULL,
          true, false, false, true, -3209005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, District E', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Irene Bustamante Adams (District F; Board Vice President - officer title on seat) — -3209006
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Irene Bustamante Adams', 'Irene', 'Bustamante Adams', NULL,
          true, false, false, true, -3209006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, District F', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Linda P. Cavazos (District G) — -3209007
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Linda P. Cavazos', 'Linda', 'Cavazos', NULL,
          true, false, false, true, -3209007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, District G', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: Isaac Barron (Appointed - City of North Las Vegas) — -3209008
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Isaac Barron', 'Isaac', 'Barron', NULL,
          true, true, false, true, -3209008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, Appointed – City of North Las Vegas', 'NV', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Ramona Esparza-Stoffregan (Appointed - City of Henderson) — -3209009
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ramona Esparza-Stoffregan', 'Ramona', 'Esparza-Stoffregan', NULL,
          true, true, false, true, -3209009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, Appointed – City of Henderson', 'NV', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: Adam Johnson (Appointed - City of Las Vegas) — -3209010
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Adam Johnson', 'Adam', 'Johnson', NULL,
          true, true, false, true, -3209010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, Appointed – City of Las Vegas', 'NV', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: Lisa Satory (Appointed - Clark County) — -3209011
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Satory', 'Lisa', 'Satory', NULL,
          true, true, false, true, -3209011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of School Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Clark County School District, Nevada, US')),
       p.id,
       'Trustee, Appointed – Clark County', 'NV', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill (all 11 trustees). BETWEEN: more-negative bound first.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -3209011 AND -3209001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (RAISE EXCEPTION on mismatch — rolls back)
-- Gate (a): government row count = 1
-- Gate (b): offices on the SCHOOL district = 11
-- Gate (c): elected/appointed split = 7 / 4
-- Gate (d): section-split detector = 0 orphan rows
-- =============================================================================
DO $$
DECLARE
  v_gov_count INTEGER;
  v_office_count INTEGER;
  v_elected_count INTEGER;
  v_appointed_count INTEGER;
  v_split_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'Clark County School District, Nevada, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 CCSD government row, found %', v_gov_count;
  END IF;

  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv';
  IF v_office_count <> 11 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 11 offices on the SCHOOL district, found %', v_office_count;
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE o.is_appointed_position = false),
    COUNT(*) FILTER (WHERE o.is_appointed_position = true)
  INTO v_elected_count, v_appointed_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '3200060' AND d.district_type = 'SCHOOL' AND d.state = 'nv';
  IF v_elected_count <> 7 OR v_appointed_count <> 4 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 elected / 4 appointed, found % / %', v_elected_count, v_appointed_count;
  END IF;

  -- Gate (d): section-split detector — the G5420 geofence must have a matching SCHOOL district
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '3200060'
    AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'SCHOOL'
        AND d.state = 'nv'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=3200060', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov_count=%, office_count=%, elected=%, appointed=%, split_orphans=%',
    v_gov_count, v_office_count, v_elected_count, v_appointed_count, v_split_count;
END $$;

COMMIT;

-- =============================================================================
-- Step 7: Migration ledger registration (OUTSIDE the transaction)
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1107', 'ccsd_board_of_trustees')
ON CONFLICT (version) DO NOTHING;
