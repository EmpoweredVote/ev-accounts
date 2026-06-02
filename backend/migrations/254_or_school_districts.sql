-- Migration 254: OR school district government + chambers + SCHOOL districts + officials + offices
--
-- Purpose: Seeds 6 Multnomah County school districts:
--   Portland Public Schools       (geo_id='4110040') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   Parkrose School District 3    (geo_id='4109480') — 1 gov + 1 chamber + 1 SCHOOL district + 5 officials
--   Reynolds School District 7    (geo_id='4110520') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   Centennial School District 28J (geo_id='4102800') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   David Douglas School District 40 (geo_id='4103940') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   Riverdale School District 51J  (geo_id='4110560') — 1 gov + 1 chamber + 1 SCHOOL district + 5 officials
-- Totals: 6 governments, 6 chambers, 6 districts, 38 politicians, 38 offices
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: G5420 geofence_boundaries rows must exist BEFORE this migration runs (loaded by loader script).
-- CRITICAL: party=NULL on all 38 politicians (antipartisan — D-11).
-- CRITICAL: is_appointed=false, is_appointed_position=false on all (elected board members — D-12).
-- CRITICAL: Save this file as UTF-8 to preserve ñ and é characters (Reynolds + David Douglas names).
--
-- Applied to production Supabase via Supabase MCP (mcp__supabase-local is remote production DB).

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE EXCEPTION if any of the 6 government names already exist
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name IN (
        'Portland Public Schools, Oregon, US',
        'Parkrose School District 3, Oregon, US',
        'Reynolds School District 7, Oregon, US',
        'Centennial School District 28J, Oregon, US',
        'David Douglas School District 40, Oregon, US',
        'Riverdale School District 51J, Oregon, US'
      )) > 0 THEN
    RAISE EXCEPTION 'Migration 254 already applied — aborting re-run';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government rows (6 school districts)
-- type='LOCAL' matches school district type (same as LAUSD pattern)
-- governments.state = 'OR' uppercase (governments convention)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Portland Public Schools, Oregon, US',
       'LOCAL', 'OR', NULL, '4110040'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Portland Public Schools, Oregon, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Parkrose School District 3, Oregon, US',
       'LOCAL', 'OR', NULL, '4109480'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Parkrose School District 3, Oregon, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Reynolds School District 7, Oregon, US',
       'LOCAL', 'OR', NULL, '4110520'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Reynolds School District 7, Oregon, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Centennial School District 28J, Oregon, US',
       'LOCAL', 'OR', NULL, '4102800'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Centennial School District 28J, Oregon, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'David Douglas School District 40, Oregon, US',
       'LOCAL', 'OR', NULL, '4103940'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'David Douglas School District 40, Oregon, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Riverdale School District 51J, Oregon, US',
       'LOCAL', 'OR', NULL, '4110560'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Riverdale School District 51J, Oregon, US'
);

-- =============================================================================
-- Step 2: Board of Education chambers (6 — one per district)
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'Portland Public Schools Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'Portland Public Schools, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Portland Public Schools, Oregon, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'Parkrose School District 3 Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'Parkrose School District 3, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Parkrose School District 3, Oregon, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'Reynolds School District 7 Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'Reynolds School District 7, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Reynolds School District 7, Oregon, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'Centennial School District 28J Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'Centennial School District 28J, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Centennial School District 28J, Oregon, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'David Douglas School District 40 Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'David Douglas School District 40, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'David Douglas School District 40, Oregon, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'Riverdale School District 51J Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'Riverdale School District 51J, Oregon, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Riverdale School District 51J, Oregon, US')
);

-- =============================================================================
-- Step 3: SCHOOL district rows (6 — one per district)
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='or' LOWERCASE — routing query uses geocoder output which is lowercase
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4110040', 'Portland Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4110040' AND district_type = 'SCHOOL' AND state = 'or'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4109480', 'Parkrose School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4109480' AND district_type = 'SCHOOL' AND state = 'or'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4110520', 'Reynolds School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4110520' AND district_type = 'SCHOOL' AND state = 'or'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4102800', 'Centennial School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4102800' AND district_type = 'SCHOOL' AND state = 'or'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4103940', 'David Douglas School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4103940' AND district_type = 'SCHOOL' AND state = 'or'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4110560', 'Riverdale School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4110560' AND district_type = 'SCHOOL' AND state = 'or'
);

-- =============================================================================
-- Step 4: Politicians + offices (38 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan — D-11)
-- is_appointed=false, is_appointed_position=false (elected board members — D-12)
-- representing_state='OR' uppercase (offices convention)
-- is_incumbent=true (verified current board members)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- =============================================================================

-- ============================
-- PORTLAND PUBLIC SCHOOLS (PPS) — 7 members, geo_id='4110040'
-- Zones are residency eligibility zones, NOT sub-district geofences.
-- All 7 board members link to the whole-district row (geo_id='4110040').
-- Source: https://www.pps.net/board/board-of-education/board-members (verified 2026-06-01)
-- ============================

-- BLOCK 1: Edward Wang (Chair, Zone 7) — -860001
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Edward Wang', 'Edward', 'Wang', NULL,
          true, false, false, true, -860001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Portland Public Schools, Oregon, US')),
       p.id,
       'Board Member (Zone 7)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110040'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Michelle DePass (Vice-Chair, Zone 2) — -860002
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michelle DePass', 'Michelle', 'DePass', NULL,
          true, false, false, true, -860002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Portland Public Schools, Oregon, US')),
       p.id,
       'Board Member (Zone 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110040'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Christy Splitt (Zone 1) — -860003
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christy Splitt', 'Christy', 'Splitt', NULL,
          true, false, false, true, -860003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Portland Public Schools, Oregon, US')),
       p.id,
       'Board Member (Zone 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110040'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Patte Sullivan (Zone 3) — -860004
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Patte Sullivan', 'Patte', 'Sullivan', NULL,
          true, false, false, true, -860004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Portland Public Schools, Oregon, US')),
       p.id,
       'Board Member (Zone 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110040'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Rashelle Chase-Miller (Zone 4) — -860005
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rashelle Chase-Miller', 'Rashelle', 'Chase-Miller', NULL,
          true, false, false, true, -860005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Portland Public Schools, Oregon, US')),
       p.id,
       'Board Member (Zone 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110040'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Virginia La Forte (Zone 5) — -860006
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Virginia La Forte', 'Virginia', 'La Forte', NULL,
          true, false, false, true, -860006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Portland Public Schools, Oregon, US')),
       p.id,
       'Board Member (Zone 5)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110040'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Stephanie Engelsman (Zone 6) — -860007
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephanie Engelsman', 'Stephanie', 'Engelsman', NULL,
          true, false, false, true, -860007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Portland Public Schools, Oregon, US')),
       p.id,
       'Board Member (Zone 6)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110040'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- PARKROSE SCHOOL DISTRICT 3 — 5 members, geo_id='4109480'
-- Source: https://www.parkrose.com/school-board (verified 2026-06-01)
-- ============================

-- BLOCK 8: Paul Tabron Jr. (Position 1 Chair) — -860011
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Tabron Jr.', 'Paul', 'Tabron Jr.', NULL,
          true, false, false, true, -860011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Parkrose School District 3, Oregon, US')),
       p.id,
       'Board Member (Position 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4109480'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Brenda Rivas (Position 2 Vice Chair) — -860012
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brenda Rivas', 'Brenda', 'Rivas', NULL,
          true, false, false, true, -860012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Parkrose School District 3, Oregon, US')),
       p.id,
       'Board Member (Position 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4109480'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: Joash Bullock (Position 3) — -860013
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joash Bullock', 'Joash', 'Bullock', NULL,
          true, false, false, true, -860013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Parkrose School District 3, Oregon, US')),
       p.id,
       'Board Member (Position 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4109480'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: Adolfo Jimenez (Position 4) — -860014
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Adolfo Jimenez', 'Adolfo', 'Jimenez', NULL,
          true, false, false, true, -860014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Parkrose School District 3, Oregon, US')),
       p.id,
       'Board Member (Position 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4109480'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: Mariah Galaviz (Position 5) — -860015
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mariah Galaviz', 'Mariah', 'Galaviz', NULL,
          true, false, false, true, -860015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Parkrose School District 3, Oregon, US')),
       p.id,
       'Board Member (Position 5)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4109480'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- REYNOLDS SCHOOL DISTRICT 7 — 7 members, geo_id='4110520'
-- NOTE: Aaron Muñoz and Ana Gonzalez Muñoz use Unicode ñ — file saved as UTF-8
-- Source: https://www.reynolds.k12.or.us/schoolboard (verified 2026-06-01)
-- ============================

-- BLOCK 13: Aaron Muñoz (Position 1) — -860021
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Aaron Muñoz', 'Aaron', 'Muñoz', NULL,
          true, false, false, true, -860021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Reynolds School District 7, Oregon, US')),
       p.id,
       'Board Member (Position 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110520'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 14: Joyce Rosenau (Position 2 Vice Chair) — -860022
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joyce Rosenau', 'Joyce', 'Rosenau', NULL,
          true, false, false, true, -860022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Reynolds School District 7, Oregon, US')),
       p.id,
       'Board Member (Position 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110520'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 15: Michael Reyes (Position 3 Chair) — -860023
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Reyes', 'Michael', 'Reyes', NULL,
          true, false, false, true, -860023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Reynolds School District 7, Oregon, US')),
       p.id,
       'Board Member (Position 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110520'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 16: Cayle Tern (Position 4) — -860024
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cayle Tern', 'Cayle', 'Tern', NULL,
          true, false, false, true, -860024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Reynolds School District 7, Oregon, US')),
       p.id,
       'Board Member (Position 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110520'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 17: Patty Carrera (Position 5) — -860025
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Patty Carrera', 'Patty', 'Carrera', NULL,
          true, false, false, true, -860025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Reynolds School District 7, Oregon, US')),
       p.id,
       'Board Member (Position 5)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110520'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 18: Ana Gonzalez Muñoz (Position 6) — -860026
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ana Gonzalez Muñoz', 'Ana', 'Gonzalez Muñoz', NULL,
          true, false, false, true, -860026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Reynolds School District 7, Oregon, US')),
       p.id,
       'Board Member (Position 6)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110520'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 19: Francisco Ibarra (Position 7) — -860027
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Francisco Ibarra', 'Francisco', 'Ibarra', NULL,
          true, false, false, true, -860027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Reynolds School District 7, Oregon, US')),
       p.id,
       'Board Member (Position 7)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110520'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- CENTENNIAL SCHOOL DISTRICT 28J — 7 members, geo_id='4102800'
-- Post-May 2025 election roster (Will Mohring moved from At Large to Zone 3/Position 3;
-- Michael Newman won newly vacated At Large seat — sworn in July 9, 2025)
-- Ronald Hardin: legal name used (dropping informal nickname "Jess")
-- Source: https://csd28j.org/boardmembers (verified 2026-06-01)
-- ============================

-- BLOCK 20: David Linn (Position 1) — -860031
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Linn', 'David', 'Linn', NULL,
          true, false, false, true, -860031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Centennial School District 28J, Oregon, US')),
       p.id,
       'Board Member (Position 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4102800'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 21: Ronald Hardin (Position 2) — -860032
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ronald Hardin', 'Ronald', 'Hardin', NULL,
          true, false, false, true, -860032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Centennial School District 28J, Oregon, US')),
       p.id,
       'Board Member (Position 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4102800'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 22: Will Mohring (Position 3 Vice Chair) — -860033
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Will Mohring', 'Will', 'Mohring', NULL,
          true, false, false, true, -860033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Centennial School District 28J, Oregon, US')),
       p.id,
       'Board Member (Position 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4102800'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 23: Melissa Standley (Position 4) — -860034
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Melissa Standley', 'Melissa', 'Standley', NULL,
          true, false, false, true, -860034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Centennial School District 28J, Oregon, US')),
       p.id,
       'Board Member (Position 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4102800'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 24: Rose Solowski (Position 5 Chair) — -860035
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rose Solowski', 'Rose', 'Solowski', NULL,
          true, false, false, true, -860035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Centennial School District 28J, Oregon, US')),
       p.id,
       'Board Member (Position 5)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4102800'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 25: Michael Newman (Position 6) — -860036
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Newman', 'Michael', 'Newman', NULL,
          true, false, false, true, -860036)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Centennial School District 28J, Oregon, US')),
       p.id,
       'Board Member (Position 6)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4102800'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 26: Pam Shields (Position 7) — -860037
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pam Shields', 'Pam', 'Shields', NULL,
          true, false, false, true, -860037)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Centennial School District 28J, Oregon, US')),
       p.id,
       'Board Member (Position 7)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4102800'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- DAVID DOUGLAS SCHOOL DISTRICT 40 — 7 members, geo_id='4103940'
-- NOTE: José Gamero-Georgeson uses Unicode é — file saved as UTF-8
-- Sara Epstein: credential suffix ', MPH' dropped per LAUSD precedent
-- Stephanie D. Stephens: middle initial dropped per LAUSD precedent
-- Source: https://www.ddouglas.k12.or.us/school-board/board-members/ (verified 2026-06-01)
-- ============================

-- BLOCK 27: Althea Ender (Position 1) — -860041
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Althea Ender', 'Althea', 'Ender', NULL,
          true, false, false, true, -860041)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'David Douglas School District 40, Oregon, US')),
       p.id,
       'Board Member (Position 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4103940'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 28: Stephanie Stephens (Position 2) — -860042
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephanie Stephens', 'Stephanie', 'Stephens', NULL,
          true, false, false, true, -860042)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'David Douglas School District 40, Oregon, US')),
       p.id,
       'Board Member (Position 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4103940'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 29: Sara Epstein (Position 3) — -860043
-- Credential suffix ', MPH' dropped per LAUSD precedent (store legal name without degrees)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sara Epstein', 'Sara', 'Epstein', NULL,
          true, false, false, true, -860043)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'David Douglas School District 40, Oregon, US')),
       p.id,
       'Board Member (Position 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4103940'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 30: Muriel Jordan (Position 4) — -860044
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Muriel Jordan', 'Muriel', 'Jordan', NULL,
          true, false, false, true, -860044)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'David Douglas School District 40, Oregon, US')),
       p.id,
       'Board Member (Position 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4103940'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 31: Thomas Stephenson (Position 5) — -860045
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thomas Stephenson', 'Thomas', 'Stephenson', NULL,
          true, false, false, true, -860045)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'David Douglas School District 40, Oregon, US')),
       p.id,
       'Board Member (Position 5)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4103940'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 32: Heather Franklin (Position 6 Chair) — -860046
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Heather Franklin', 'Heather', 'Franklin', NULL,
          true, false, false, true, -860046)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'David Douglas School District 40, Oregon, US')),
       p.id,
       'Board Member (Position 6)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4103940'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 33: José Gamero-Georgeson (Position 7 Vice Chair) — -860047
-- Unicode é in first name — file saved as UTF-8
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'José Gamero-Georgeson', 'José', 'Gamero-Georgeson', NULL,
          true, false, false, true, -860047)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'David Douglas School District 40, Oregon, US')),
       p.id,
       'Board Member (Position 7)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4103940'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- RIVERDALE SCHOOL DISTRICT 51J — 5 members, geo_id='4110560'
-- Uses "Seat N" terminology per official website
-- Source: https://www.riverdaleschool.com/about-us/school-board-policy (verified 2026-06-01)
-- ============================

-- BLOCK 34: Shaina Weinstein (Seat 1 Vice-Chair) — -860051
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shaina Weinstein', 'Shaina', 'Weinstein', NULL,
          true, false, false, true, -860051)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Riverdale School District 51J, Oregon, US')),
       p.id,
       'Board Member (Seat 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110560'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 35: Mina Stricklin (Seat 2 Chair) — -860052
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mina Stricklin', 'Mina', 'Stricklin', NULL,
          true, false, false, true, -860052)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Riverdale School District 51J, Oregon, US')),
       p.id,
       'Board Member (Seat 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110560'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 36: Michele Rosenbaum (Seat 3) — -860053
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michele Rosenbaum', 'Michele', 'Rosenbaum', NULL,
          true, false, false, true, -860053)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Riverdale School District 51J, Oregon, US')),
       p.id,
       'Board Member (Seat 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110560'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 37: Ali Lanenga (Seat 4) — -860054
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ali Lanenga', 'Ali', 'Lanenga', NULL,
          true, false, false, true, -860054)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Riverdale School District 51J, Oregon, US')),
       p.id,
       'Board Member (Seat 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110560'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 38: Milessa Lowrie (Seat 5) — -860055
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Milessa Lowrie', 'Milessa', 'Lowrie', NULL,
          true, false, false, true, -860055)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Education'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Riverdale School District 51J, Oregon, US')),
       p.id,
       'Board Member (Seat 5)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4110560'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 38 OR school board officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -860055 AND -860001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count = 6
-- Gate (b): chamber count = 6
-- Gate (c): SCHOOL district count = 6
-- Gate (d): politician count = 38
-- Gate (e): office count = 38 (linked to SCHOOL districts)
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
  -- Gate (a): 6 government rows
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name IN (
    'Portland Public Schools, Oregon, US',
    'Parkrose School District 3, Oregon, US',
    'Reynolds School District 7, Oregon, US',
    'Centennial School District 28J, Oregon, US',
    'David Douglas School District 40, Oregon, US',
    'Riverdale School District 51J, Oregon, US'
  );
  IF v_gov_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 6 government rows, found %', v_gov_count;
  END IF;

  -- Gate (b): 6 Board of Education chambers
  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id IN (
      SELECT id FROM essentials.governments
      WHERE name IN (
        'Portland Public Schools, Oregon, US',
        'Parkrose School District 3, Oregon, US',
        'Reynolds School District 7, Oregon, US',
        'Centennial School District 28J, Oregon, US',
        'David Douglas School District 40, Oregon, US',
        'Riverdale School District 51J, Oregon, US'
      )
    );
  IF v_chamber_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 6 Board of Education chambers, found %', v_chamber_count;
  END IF;

  -- Gate (c): 6 SCHOOL district rows
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'or'
    AND geo_id IN ('4110040','4109480','4110520','4102800','4103940','4110560');
  IF v_dist_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 6 SCHOOL district rows, found %', v_dist_count;
  END IF;

  -- Gate (d): 38 politicians in external_id range
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -860055 AND -860001;
  IF v_pol_count <> 38 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 38 politicians in -860055..-860001 range, found %', v_pol_count;
  END IF;

  -- Gate (e): 38 offices linked to SCHOOL districts
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'SCHOOL'
    AND d.geo_id IN ('4110040','4109480','4110520','4102800','4103940','4110560');
  IF v_off_count <> 38 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 38 offices linked to SCHOOL districts, found %', v_off_count;
  END IF;

  -- Gate (f): Section-split check — all 6 G5420 geofences have SCHOOL district rows
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id IN ('4110040','4109480','4110520','4102800','4103940','4110560')
    AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'SCHOOL'
        AND d.state = 'or'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split returned % orphan rows (G5420 geofence without SCHOOL district row)', v_split_count;
  END IF;

  -- Gate (g): Office_id back-fill complete
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -860055 AND -860001
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in -860055..-860001 range still have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 254 post-verification PASSED: 6 govs, 6 chambers, 6 SCHOOL districts, 38 politicians, 38 offices, section-split=0, office_id back-fill complete';
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('254')
ON CONFLICT (version) DO NOTHING;

COMMIT;
