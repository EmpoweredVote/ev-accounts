-- Migration 261: TX Collin County school board government + chambers + SCHOOL districts + officials + offices
--
-- Purpose: Seeds 5 TX Collin County ISDs:
--   Plano ISD        (geo_id='4835100') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   McKinney ISD     (geo_id='4829850') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   Allen ISD        (geo_id='4807890') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   Frisco ISD       (geo_id='4820010') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   Richardson ISD   (geo_id='4837020') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
-- Totals: 5 governments, 5 chambers, 5 districts, 35 politicians, 35 offices
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'tx' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'TX' (uppercase). offices.representing_state = 'TX' (uppercase).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: All 5 G5420 geofence_boundaries rows must exist before this migration (run loader first).
-- CRITICAL: party=NULL on all 35 politicians (antipartisan).
-- CRITICAL: is_appointed=false, is_appointed_position=false on all (elected board members).
-- CRITICAL: Save this file as UTF-8 to preserve é character (Debbie Rentería — Richardson ISD).
-- CRITICAL: Richardson ISD uses hybrid seat structure — Districts 1-5 + At-Large Places 6-7.
--           Use 'Board Member, District [N]' for Districts 1-5 and 'Board Member, Place [N]' for At-Large 6-7.
--
-- Coverage gap note (D-16): Residents in smaller Collin County ISDs (Prosper, Wylie, Celina, Lovejoy,
-- Princeton, etc.) will not see a SCHOOL section in Phase 88. A future phase could add these if needed.
--
-- Applied to production Supabase via Supabase MCP (mcp__supabase-local is remote production DB).
-- Pattern: Phase 87 migration 257_ca_city_school_boards.sql (direct analog).

BEGIN;

-- =============================================================================
-- Pre-flight 1: RAISE EXCEPTION if any of the 5 government names already exist
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name IN (
        'Plano Independent School District, Texas, US',
        'McKinney Independent School District, Texas, US',
        'Allen Independent School District, Texas, US',
        'Frisco Independent School District, Texas, US',
        'Richardson Independent School District, Texas, US'
      )) > 0 THEN
    RAISE EXCEPTION 'Migration 261 already applied — aborting re-run';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Verify external_id block is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -880035 AND -880001;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -880001..-880035 is not clear (% rows found)', v_count;
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 3: Verify all 5 G5420 geofences exist (loader must run first)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id IN ('4835100','4829850','4807890','4820010','4837020')
    AND mtfcc = 'G5420';
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 5 G5420 geofence rows, found % (run load-tx-school-boundaries.ts first)', v_count;
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government rows (5 school districts)
-- type='LOCAL' matches school district type (same as LAUSD and Phase 86/87 pattern)
-- governments.state = 'TX' uppercase (governments convention)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Plano Independent School District, Texas, US',
       'LOCAL', 'TX', NULL, '4835100'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Plano Independent School District, Texas, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'McKinney Independent School District, Texas, US',
       'LOCAL', 'TX', NULL, '4829850'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'McKinney Independent School District, Texas, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Allen Independent School District, Texas, US',
       'LOCAL', 'TX', NULL, '4807890'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Allen Independent School District, Texas, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Frisco Independent School District, Texas, US',
       'LOCAL', 'TX', NULL, '4820010'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Frisco Independent School District, Texas, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Richardson Independent School District, Texas, US',
       'LOCAL', 'TX', NULL, '4837020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Richardson Independent School District, Texas, US'
);

-- =============================================================================
-- Step 2: Board of Trustees chambers (5 — one per district)
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Trustees',
       'Plano Independent School District Board of Trustees',
       (SELECT id FROM essentials.governments WHERE name = 'Plano Independent School District, Texas, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Trustees'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Plano Independent School District, Texas, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Trustees',
       'McKinney Independent School District Board of Trustees',
       (SELECT id FROM essentials.governments WHERE name = 'McKinney Independent School District, Texas, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Trustees'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'McKinney Independent School District, Texas, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Trustees',
       'Allen Independent School District Board of Trustees',
       (SELECT id FROM essentials.governments WHERE name = 'Allen Independent School District, Texas, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Trustees'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Allen Independent School District, Texas, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Trustees',
       'Frisco Independent School District Board of Trustees',
       (SELECT id FROM essentials.governments WHERE name = 'Frisco Independent School District, Texas, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Trustees'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Frisco Independent School District, Texas, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Trustees',
       'Richardson Independent School District Board of Trustees',
       (SELECT id FROM essentials.governments WHERE name = 'Richardson Independent School District, Texas, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Trustees'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Richardson Independent School District, Texas, US')
);

-- =============================================================================
-- Step 3: SCHOOL district rows (5 — one per district)
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='tx' LOWERCASE — routing query uses geocoder output which is lowercase
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'tx', '4835100', 'Plano Independent School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4835100' AND district_type = 'SCHOOL' AND state = 'tx'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'tx', '4829850', 'McKinney Independent School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4829850' AND district_type = 'SCHOOL' AND state = 'tx'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'tx', '4807890', 'Allen Independent School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4807890' AND district_type = 'SCHOOL' AND state = 'tx'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'tx', '4820010', 'Frisco Independent School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4820010' AND district_type = 'SCHOOL' AND state = 'tx'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'tx', '4837020', 'Richardson Independent School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4837020' AND district_type = 'SCHOOL' AND state = 'tx'
);

-- =============================================================================
-- Step 4: Politicians + offices (35 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan — D-10)
-- is_appointed=false, is_appointed_position=false (elected board members — D-11)
-- representing_state='TX' uppercase (offices convention)
-- is_incumbent=true (verified current board members)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- =============================================================================

-- ============================
-- PLANO INDEPENDENT SCHOOL DISTRICT — 7 members, geo_id='4835100'
-- Office title: 'Board Member, Place [N]' (standard TX ISD place-based at-large)
-- Source: https://www.pisd.edu/about-our-district/board-of-trustees + election records [MEDIUM: place 4-7 inferred]
-- Note: Place 4-7 name-to-place assignment (A1-A4 in assumptions log) — inferred from official page + election records
-- ============================

-- BLOCK 1: Dr. Lauren Tyra (Board President, Place 1) — -880001
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dr. Lauren Tyra', 'Dr. Lauren', 'Tyra', NULL,
          true, false, false, true, -880001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Plano Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 1', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4835100'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Sam Johnson (Place 2) — -880002
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sam Johnson', 'Sam', 'Johnson', NULL,
          true, false, false, true, -880002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Plano Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 2', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4835100'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Nancy Humphrey (Board Vice President, Place 3) — -880003
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nancy Humphrey', 'Nancy', 'Humphrey', NULL,
          true, false, false, true, -880003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Plano Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 3', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4835100'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Michael Cook (Place 4) — -880004
-- [ASSUMED: name confirmed from official page; place number inferred — A1 in assumptions log]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Cook', 'Michael', 'Cook', NULL,
          true, false, false, true, -880004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Plano Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 4', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4835100'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Tarrah Lantz (Place 5) — -880005
-- [ASSUMED: name confirmed from official page; place number inferred — A1 in assumptions log]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tarrah Lantz', 'Tarrah', 'Lantz', NULL,
          true, false, false, true, -880005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Plano Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 5', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4835100'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Elisa Klein (Place 6) — -880006
-- [ASSUMED: name confirmed from official page; place number inferred — A1 in assumptions log]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elisa Klein', 'Elisa', 'Klein', NULL,
          true, false, false, true, -880006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Plano Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 6', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4835100'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Katherine Goodwin (Board Secretary, Place 7) — -880007
-- [ASSUMED: name confirmed from official page; place number inferred — A1 in assumptions log]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Katherine Goodwin', 'Katherine', 'Goodwin', NULL,
          true, false, false, true, -880007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Plano Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 7', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4835100'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- MCKINNEY INDEPENDENT SCHOOL DISTRICT — 7 members, geo_id='4829850'
-- Office title: 'Board Member, Place [N]' (standard TX ISD place-based at-large)
-- Source: mckinneyisd.net, election records, Community Impact articles [MEDIUM]
-- Note: Place 4 (Roxane Morrison) is ASSUMED per A2 in assumptions log
-- ============================

-- BLOCK 8: Harvey Oaxaca (Place 1) — -880008
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Harvey Oaxaca', 'Harvey', 'Oaxaca', NULL,
          true, false, false, true, -880008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'McKinney Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 1', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4829850'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Kenneth Ussery (Place 2) — -880009
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kenneth Ussery', 'Kenneth', 'Ussery', NULL,
          true, false, false, true, -880009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'McKinney Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 2', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4829850'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: Corey Homer (Place 3) — -880010
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Corey Homer', 'Corey', 'Homer', NULL,
          true, false, false, true, -880010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'McKinney Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 3', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4829850'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: Roxane Morrison (Board President, Place 4) — -880011
-- [ASSUMED: name from secondary sources — A2 in assumptions log; confirm on mckinneyisd.net/page/board-of-trustees]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roxane Morrison', 'Roxane', 'Morrison', NULL,
          true, false, false, true, -880011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'McKinney Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 4', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4829850'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: Lynn Sperry (Board Secretary, Place 5) — -880012
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lynn Sperry', 'Lynn', 'Sperry', NULL,
          true, false, false, true, -880012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'McKinney Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 5', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4829850'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 13: Stephanie O'Dell (Place 6) — -880013
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephanie O''Dell', 'Stephanie', 'O''Dell', NULL,
          true, false, false, true, -880013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'McKinney Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 6', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4829850'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 14: Amy Dankel (Board Vice President, Place 7) — -880014
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Amy Dankel', 'Amy', 'Dankel', NULL,
          true, false, false, true, -880014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'McKinney Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 7', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4829850'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- ALLEN INDEPENDENT SCHOOL DISTRICT — 7 members, geo_id='4807890'
-- Office title: 'Board Member, Place [N]' (standard TX ISD place-based at-large)
-- Source: allenisd.org + election results + Ballotpedia [MEDIUM — assembled from election records]
-- Note: Places 1-3 (Mitchell/Yost/Holley) from Ballotpedia; Places 4-5 (Kinnear/Campbell) verified May 2025 results
-- Place 6 (Dr. Polly Montgomery) and Place 7 (Bill Parker) from May 2023 election records
-- ============================

-- BLOCK 15: Sarah Mitchell (Place 1) — -880015
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sarah Mitchell', 'Sarah', 'Mitchell', NULL,
          true, false, false, true, -880015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Allen Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 1', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4807890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 16: Veronica Yost (Place 2) — -880016
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Veronica Yost', 'Veronica', 'Yost', NULL,
          true, false, false, true, -880016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Allen Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 2', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4807890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 17: John Holley (Place 3) — -880017
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Holley', 'John', 'Holley', NULL,
          true, false, false, true, -880017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Allen Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 3', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4807890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 18: Becca Kinnear (Place 4) — -880018
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Becca Kinnear', 'Becca', 'Kinnear', NULL,
          true, false, false, true, -880018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Allen Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 4', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4807890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 19: Amanda Campbell (Place 5) — -880019
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Amanda Campbell', 'Amanda', 'Campbell', NULL,
          true, false, false, true, -880019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Allen Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 5', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4807890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 20: Dr. Polly Montgomery (Place 6) — -880020
-- Name note: 'Dr. Polly' as first_name to follow honorific convention (same as Dr. Lauren Tyra)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dr. Polly Montgomery', 'Dr. Polly', 'Montgomery', NULL,
          true, false, false, true, -880020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Allen Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 6', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4807890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 21: Bill Parker (Place 7) — -880021
-- [A6 in assumptions log: elected May 2023 per election records]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bill Parker', 'Bill', 'Parker', NULL,
          true, false, false, true, -880021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Allen Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 7', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4807890'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- FRISCO INDEPENDENT SCHOOL DISTRICT — 7 members, geo_id='4820010'
-- Office title: 'Board Member, Place [N]' (standard TX ISD place-based at-large)
-- Source: https://www.friscoisd.org/about/board-of-trustees/meet-the-board [VERIFIED: 2026-06-02]
-- Note: Suresh Manduva, Renee Sample, Stephanie Elad won Places 1, 2, 3 in May 2026
-- Note: Mark Hill (Place 5, Board Secretary) — confirmed post-May 2025 replacement for Misty Wamhoff (A7)
-- Note: Frisco ISD extends into Denton County (D-13) — full G5420 polygon used, no clipping
-- ============================

-- BLOCK 22: Suresh Manduva (Place 1) — -880022
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Suresh Manduva', 'Suresh', 'Manduva', NULL,
          true, false, false, true, -880022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Frisco Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 1', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4820010'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 23: Renee Sample (Place 2) — -880023
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Renee Sample', 'Renee', 'Sample', NULL,
          true, false, false, true, -880023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Frisco Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 2', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4820010'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 24: Stephanie Elad (Place 3) — -880024
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephanie Elad', 'Stephanie', 'Elad', NULL,
          true, false, false, true, -880024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Frisco Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 3', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4820010'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 25: Dynette Davis (Board President, Place 4) — -880025
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dynette Davis', 'Dynette', 'Davis', NULL,
          true, false, false, true, -880025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Frisco Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 4', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4820010'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 26: Mark Hill (Board Secretary, Place 5) — -880026
-- [A7: Confirmed post-May 2025 as Secretary; listed on current friscoisd.org meet-the-board page]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Hill', 'Mark', 'Hill', NULL,
          true, false, false, true, -880026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Frisco Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 5', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4820010'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 27: Sherrie Salas (Place 6) — -880027
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sherrie Salas', 'Sherrie', 'Salas', NULL,
          true, false, false, true, -880027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Frisco Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 6', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4820010'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 28: Keith Maddox (Board Vice President, Place 7) — -880028
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Keith Maddox', 'Keith', 'Maddox', NULL,
          true, false, false, true, -880028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Frisco Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 7', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4820010'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- RICHARDSON INDEPENDENT SCHOOL DISTRICT — 7 members, geo_id='4837020'
-- HYBRID SEAT STRUCTURE: 5 Single-Member Districts + 2 At-Large Places
-- Single-member districts use title: 'Board Member, District [N]' (Districts 1-5)
-- At-large places use title: 'Board Member, Place [N]' (Places 6-7)
-- Source: https://web.risd.org/board/members/ [VERIFIED: 2026-06-02]
-- Note: Richardson ISD extends into Dallas County (D-14) — full G5420 polygon used
-- CRITICAL: File saved UTF-8 for é in Debbie Rentería (District 3)
-- ============================

-- BLOCK 29: Megan Timme (Single-Member District 1) — -880029
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Megan Timme', 'Megan', 'Timme', NULL,
          true, false, false, true, -880029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Richardson Independent School District, Texas, US')),
       p.id,
       'Board Member, District 1', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4837020'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 30: Vanessa Pacheco (Single-Member District 2) — -880030
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vanessa Pacheco', 'Vanessa', 'Pacheco', NULL,
          true, false, false, true, -880030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Richardson Independent School District, Texas, US')),
       p.id,
       'Board Member, District 2', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4837020'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 31: Debbie Rentería (Secretary, Single-Member District 3) — -880031
-- UTF-8 é character in 'Rentería' — file must be saved as UTF-8 (Pitfall 5)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Debbie Rentería', 'Debbie', 'Rentería', NULL,
          true, false, false, true, -880031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Richardson Independent School District, Texas, US')),
       p.id,
       'Board Member, District 3', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4837020'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 32: Regina Harris (Single-Member District 4) — -880032
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Regina Harris', 'Regina', 'Harris', NULL,
          true, false, false, true, -880032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Richardson Independent School District, Texas, US')),
       p.id,
       'Board Member, District 4', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4837020'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 33: Rachel McGowan (Vice President, Single-Member District 5) — -880033
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rachel McGowan', 'Rachel', 'McGowan', NULL,
          true, false, false, true, -880033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Richardson Independent School District, Texas, US')),
       p.id,
       'Board Member, District 5', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4837020'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 34: Eric Eager (At-Large Place 6) — -880034
-- At-large seat — uses 'Board Member, Place [N]' title convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eric Eager', 'Eric', 'Eager', NULL,
          true, false, false, true, -880034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Richardson Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 6', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4837020'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 35: Chris Poteet (President, At-Large Place 7) — -880035
-- At-large seat — uses 'Board Member, Place [N]' title convention
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chris Poteet', 'Chris', 'Poteet', NULL,
          true, false, false, true, -880035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Trustees'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Richardson Independent School District, Texas, US')),
       p.id,
       'Board Member, Place 7', 'TX', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4837020'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'tx'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 35 TX school board officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -880035 AND -880001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count = 5
-- Gate (b): chamber count = 5
-- Gate (c): SCHOOL district count = 5
-- Gate (d): politician count = 35
-- Gate (e): office count = 35 (linked to SCHOOL districts)
-- Gate (f): section-split = 0 orphan geofences
-- Gate (g): office_id back-fill complete (0 NULL)
-- =============================================================================
DO $$
DECLARE
  v_gov_count     INTEGER;
  v_chamber_count INTEGER;
  v_dist_count    INTEGER;
  v_pol_count     INTEGER;
  v_off_count     INTEGER;
  v_split_count   INTEGER;
  v_null_count    INTEGER;
BEGIN
  -- Gate (a): 5 government rows
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name IN (
    'Plano Independent School District, Texas, US',
    'McKinney Independent School District, Texas, US',
    'Allen Independent School District, Texas, US',
    'Frisco Independent School District, Texas, US',
    'Richardson Independent School District, Texas, US'
  );
  IF v_gov_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 government rows, found %', v_gov_count;
  END IF;

  -- Gate (b): 5 Board of Trustees chambers
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'Board of Trustees'
    AND government_id IN (
      SELECT id FROM essentials.governments
      WHERE name IN (
        'Plano Independent School District, Texas, US',
        'McKinney Independent School District, Texas, US',
        'Allen Independent School District, Texas, US',
        'Frisco Independent School District, Texas, US',
        'Richardson Independent School District, Texas, US'
      )
    );
  IF v_chamber_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 Board of Trustees chambers, found %', v_chamber_count;
  END IF;

  -- Gate (c): 5 SCHOOL district rows
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'tx'
    AND geo_id IN ('4835100','4829850','4807890','4820010','4837020');
  IF v_dist_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 SCHOOL district rows, found %', v_dist_count;
  END IF;

  -- Gate (d): 35 politicians in external_id range
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -880035 AND -880001;
  IF v_pol_count <> 35 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 35 politicians in -880035..-880001 range, found %', v_pol_count;
  END IF;

  -- Gate (e): 35 offices linked to SCHOOL districts
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'SCHOOL'
    AND d.geo_id IN ('4835100','4829850','4807890','4820010','4837020');
  IF v_off_count <> 35 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 35 offices linked to SCHOOL districts, found %', v_off_count;
  END IF;

  -- Gate (f): Section-split check — all 5 G5420 geofences have SCHOOL district rows
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id IN ('4835100','4829850','4807890','4820010','4837020')
    AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'SCHOOL'
        AND d.state = 'tx'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split returned % orphan rows (G5420 geofence without SCHOOL district row)', v_split_count;
  END IF;

  -- Gate (g): Office_id back-fill complete
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -880035 AND -880001
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in -880035..-880001 range still have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 261 post-verification PASSED: 5 govs, 5 chambers, 5 SCHOOL districts, 35 politicians, 35 offices, section-split=0, office_id back-fill complete';
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('261')
ON CONFLICT (version) DO NOTHING;

COMMIT;
