-- Migration 257: CA city school board government + chambers + SCHOOL districts + officials + offices
--
-- Purpose: Seeds 6 CA city school districts:
--   San Francisco Unified SD    (geo_id='0634410') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   San Diego Unified SD        (geo_id='0634320') — 1 gov + 1 chamber + 1 SCHOOL district + 5 officials
--   Sacramento City Unified SD  (geo_id='0633840') — 1 gov + 1 chamber + 1 SCHOOL district + 7 officials
--   San José Unified SD         (geo_id='0634590') — 1 gov + 1 chamber + 1 SCHOOL district + 5 officials
--   Fremont Unified SD          (geo_id='0614400') — 1 gov + 1 chamber + 1 SCHOOL district + 5 officials
--   Berkeley Unified SD         (geo_id='0604740') — 1 gov + 1 chamber + 1 SCHOOL district + 5 officials
-- Totals: 6 governments, 6 chambers, 6 districts, 34 politicians, 34 offices
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'ca' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'CA' (uppercase). offices.representing_state = 'CA' (uppercase).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: All 6 G5420 geofence_boundaries rows already exist in production DB (pre-confirmed 2026-06-01).
-- CRITICAL: party=NULL on all 34 politicians (antipartisan — D-08).
-- CRITICAL: is_appointed=false, is_appointed_position=false on all (elected board members — D-09).
-- CRITICAL: Save this file as UTF-8 to preserve é characters (San José, José Magaña, José M. Navarro).
--
-- Coverage gap note (D-13): SJUSD covers the southern/central core of San Jose; residents in other
-- SJ ISDs (East Side Union, Evergreen, etc.) will not see a SCHOOL section in Phase 87. Same for
-- Sacramento City Unified — residents outside the SCUSD boundary see no SCHOOL section. A future
-- phase could add secondary ISDs.
--
-- Office title conventions per district (D-07):
--   SFUSD: 'Commissioner' (official SFUSD title — not 'Board Member')
--   SDUSD: 'Board Member (District [Letter])' — sub-district letters A–E
--   SCUSD: 'Board Member (Area [N])' — numbered areas 1–7
--   SJUSD: 'Board Member (Trustee Area [N])' — numbered trustee areas 1–5
--   FUSD:  'Board Member (Area [N])' — numbered areas 1–5
--   BUSD:  'Director' (official BUSD title — matches berkeleyschools.net official terminology)
--
-- Applied to production Supabase via Supabase MCP (mcp__supabase-local is remote production DB).
-- Pattern: Phase 86 migration 254_or_school_districts.sql (direct analog).

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE EXCEPTION if any of the 6 government names already exist
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name IN (
        'San Francisco Unified School District, California, US',
        'San Diego Unified School District, California, US',
        'Sacramento City Unified School District, California, US',
        'San José Unified School District, California, US',
        'Fremont Unified School District, California, US',
        'Berkeley Unified School District, California, US'
      )) > 0 THEN
    RAISE EXCEPTION 'Migration 257 already applied — aborting re-run';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight: Verify external_id block is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -870034 AND -870001;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -870001..-870034 is not clear (% rows found)', v_count;
  END IF;
END $$;

-- =============================================================================
-- Pre-flight: Verify all 6 G5420 geofences exist
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id IN ('0634410','0634320','0633840','0634590','0614400','0604740')
    AND mtfcc = 'G5420';
  IF v_count <> 6 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 6 G5420 geofence rows, found % (GEOIDs: 0634410/0634320/0633840/0634590/0614400/0604740)', v_count;
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government rows (6 school districts)
-- type='LOCAL' matches school district type (same as LAUSD and Phase 86 pattern)
-- governments.state = 'CA' uppercase (governments convention)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'San Francisco Unified School District, California, US',
       'LOCAL', 'CA', NULL, '0634410'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'San Francisco Unified School District, California, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'San Diego Unified School District, California, US',
       'LOCAL', 'CA', NULL, '0634320'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'San Diego Unified School District, California, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Sacramento City Unified School District, California, US',
       'LOCAL', 'CA', NULL, '0633840'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Sacramento City Unified School District, California, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'San José Unified School District, California, US',
       'LOCAL', 'CA', NULL, '0634590'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'San José Unified School District, California, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Fremont Unified School District, California, US',
       'LOCAL', 'CA', NULL, '0614400'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Fremont Unified School District, California, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Berkeley Unified School District, California, US',
       'LOCAL', 'CA', NULL, '0604740'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Berkeley Unified School District, California, US'
);

-- =============================================================================
-- Step 2: Board of Education chambers (6 — one per district)
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'San Francisco Unified School District Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'San Francisco Unified School District, California, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'San Francisco Unified School District, California, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'San Diego Unified School District Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'San Diego Unified School District, California, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'San Diego Unified School District, California, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'Sacramento City Unified School District Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'Sacramento City Unified School District, California, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Sacramento City Unified School District, California, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'San José Unified School District Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'San José Unified School District, California, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'San José Unified School District, California, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'Fremont Unified School District Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'Fremont Unified School District, California, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Fremont Unified School District, California, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'Berkeley Unified School District Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'Berkeley Unified School District, California, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Berkeley Unified School District, California, US')
);

-- =============================================================================
-- Step 3: SCHOOL district rows (6 — one per district)
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='ca' LOWERCASE — routing query uses geocoder output which is lowercase
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ca', '0634410', 'San Francisco Unified School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0634410' AND district_type = 'SCHOOL' AND state = 'ca'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ca', '0634320', 'San Diego Unified School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0634320' AND district_type = 'SCHOOL' AND state = 'ca'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ca', '0633840', 'Sacramento City Unified School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0633840' AND district_type = 'SCHOOL' AND state = 'ca'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ca', '0634590', 'San José Unified School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0634590' AND district_type = 'SCHOOL' AND state = 'ca'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ca', '0614400', 'Fremont Unified School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0614400' AND district_type = 'SCHOOL' AND state = 'ca'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'ca', '0604740', 'Berkeley Unified School District', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0604740' AND district_type = 'SCHOOL' AND state = 'ca'
);

-- =============================================================================
-- Step 4: Politicians + offices (34 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan — D-08)
-- is_appointed=false, is_appointed_position=false (elected board members — D-09)
-- representing_state='CA' uppercase (offices convention)
-- is_incumbent=true (verified current board members)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- =============================================================================

-- ============================
-- SAN FRANCISCO UNIFIED SCHOOL DISTRICT (SFUSD) — 7 members, geo_id='0634410'
-- Office title: 'Commissioner' (official SFUSD terminology — not 'Board Member')
-- All 7 seats are at-large (no numbered sub-districts)
-- Source: https://www.sfusd.edu/about-sfusd/board-education (verified 2026-06-01)
-- ============================

-- BLOCK 1: Phil Kim (Board President) — -870001
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Phil Kim', 'Phil', 'Kim', NULL,
          true, false, false, true, -870001)
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
                               WHERE name = 'San Francisco Unified School District, California, US')),
       p.id,
       'Commissioner', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634410'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Jaime Huling (Board Vice President) — -870002
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jaime Huling', 'Jaime', 'Huling', NULL,
          true, false, false, true, -870002)
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
                               WHERE name = 'San Francisco Unified School District, California, US')),
       p.id,
       'Commissioner', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634410'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Matt Alexander (Commissioner) — -870003
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Alexander', 'Matt', 'Alexander', NULL,
          true, false, false, true, -870003)
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
                               WHERE name = 'San Francisco Unified School District, California, US')),
       p.id,
       'Commissioner', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634410'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Alida Fisher (Commissioner) — -870004
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alida Fisher', 'Alida', 'Fisher', NULL,
          true, false, false, true, -870004)
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
                               WHERE name = 'San Francisco Unified School District, California, US')),
       p.id,
       'Commissioner', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634410'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Parag Gupta (Commissioner) — -870005
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Parag Gupta', 'Parag', 'Gupta', NULL,
          true, false, false, true, -870005)
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
                               WHERE name = 'San Francisco Unified School District, California, US')),
       p.id,
       'Commissioner', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634410'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Supryia Ray (Commissioner) — -870006
-- Name note: official SFUSD spelling is 'Supryia' (not 'Supriya') per sfusd.edu
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Supryia Ray', 'Supryia', 'Ray', NULL,
          true, false, false, true, -870006)
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
                               WHERE name = 'San Francisco Unified School District, California, US')),
       p.id,
       'Commissioner', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634410'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Lisa Weissman-Ward (Commissioner) — -870007
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Weissman-Ward', 'Lisa', 'Weissman-Ward', NULL,
          true, false, false, true, -870007)
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
                               WHERE name = 'San Francisco Unified School District, California, US')),
       p.id,
       'Commissioner', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634410'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- SAN DIEGO UNIFIED SCHOOL DISTRICT (SDUSD) — 5 members, geo_id='0634320'
-- Official name: 'San Diego Unified School District' (NOT 'San Diego City Unified' — D-03)
-- Sub-districts lettered A–E; student members NOT seeded
-- Source: https://www.sandiegounified.org/about/board_of_education (verified 2026-06-01)
-- ============================

-- BLOCK 8: Sabrina Bazzo (District A, Board Vice President) — -870008
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sabrina Bazzo', 'Sabrina', 'Bazzo', NULL,
          true, false, false, true, -870008)
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
                               WHERE name = 'San Diego Unified School District, California, US')),
       p.id,
       'Board Member (District A)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Shana Hazan (District B) — -870009
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shana Hazan', 'Shana', 'Hazan', NULL,
          true, false, false, true, -870009)
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
                               WHERE name = 'San Diego Unified School District, California, US')),
       p.id,
       'Board Member (District B)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: Cody Petterson (District C) — -870010
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cody Petterson', 'Cody', 'Petterson', NULL,
          true, false, false, true, -870010)
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
                               WHERE name = 'San Diego Unified School District, California, US')),
       p.id,
       'Board Member (District C)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: Richard Barrera (District D, Board President) — -870011
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Barrera', 'Richard', 'Barrera', NULL,
          true, false, false, true, -870011)
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
                               WHERE name = 'San Diego Unified School District, California, US')),
       p.id,
       'Board Member (District D)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: Sharon Whitehurst-Payne (District E) — -870012
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sharon Whitehurst-Payne', 'Sharon', 'Whitehurst-Payne', NULL,
          true, false, false, true, -870012)
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
                               WHERE name = 'San Diego Unified School District, California, US')),
       p.id,
       'Board Member (District E)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- SACRAMENTO CITY UNIFIED SCHOOL DISTRICT (SCUSD) — 7 members, geo_id='0633840'
-- Numbered areas 1–7; student member NOT seeded
-- Name notes: 'Jose M. Navarro' (middle initial per scusd.edu), 'April K. Ybarra' (middle initial per scusd.edu)
-- Source: https://www.scusd.edu/about/board-of-education (verified 2026-06-01)
-- ============================

-- BLOCK 13: Tara Jeane (Area 1, President) — -870013
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tara Jeane', 'Tara', 'Jeane', NULL,
          true, false, false, true, -870013)
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
                               WHERE name = 'Sacramento City Unified School District, California, US')),
       p.id,
       'Board Member (Area 1)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0633840'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 14: Jasjit Singh (Area 2) — -870014
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jasjit Singh', 'Jasjit', 'Singh', NULL,
          true, false, false, true, -870014)
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
                               WHERE name = 'Sacramento City Unified School District, California, US')),
       p.id,
       'Board Member (Area 2)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0633840'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 15: Jose M. Navarro (Area 3) — -870015
-- Middle initial 'M.' included per scusd.edu official page
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jose M. Navarro', 'Jose', 'Navarro', NULL,
          true, false, false, true, -870015)
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
                               WHERE name = 'Sacramento City Unified School District, California, US')),
       p.id,
       'Board Member (Area 3)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0633840'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 16: April K. Ybarra (Area 4, 2nd Vice President) — -870016
-- Middle initial 'K.' included per scusd.edu official page
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'April K. Ybarra', 'April', 'Ybarra', NULL,
          true, false, false, true, -870016)
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
                               WHERE name = 'Sacramento City Unified School District, California, US')),
       p.id,
       'Board Member (Area 4)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0633840'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 17: Chinua Rhodes (Area 5) — -870017
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chinua Rhodes', 'Chinua', 'Rhodes', NULL,
          true, false, false, true, -870017)
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
                               WHERE name = 'Sacramento City Unified School District, California, US')),
       p.id,
       'Board Member (Area 5)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0633840'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 18: Taylor Kayatta (Area 6, 1st Vice President) — -870018
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Taylor Kayatta', 'Taylor', 'Kayatta', NULL,
          true, false, false, true, -870018)
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
                               WHERE name = 'Sacramento City Unified School District, California, US')),
       p.id,
       'Board Member (Area 6)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0633840'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 19: Michael Benjamin (Area 7) — -870019
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Benjamin', 'Michael', 'Benjamin', NULL,
          true, false, false, true, -870019)
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
                               WHERE name = 'Sacramento City Unified School District, California, US')),
       p.id,
       'Board Member (Area 7)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0633840'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- SAN JOSÉ UNIFIED SCHOOL DISTRICT (SJUSD) — 5 members, geo_id='0634590'
-- NOTE: Official name includes accented 'é' in 'San José'
-- Numbered trustee areas 1–5; student members NOT seeded
-- Area assignments cross-referenced from Ballotpedia (sjusd.org board page does not display area numbers)
-- Name notes: 'José Magaña' includes accented characters — UTF-8 required
-- Source: https://sjusd.org/about/board-of-education (verified 2026-06-01)
-- Coverage gap: SJUSD covers the southern/central core of San Jose only
-- ============================

-- BLOCK 20: Teresa Castellanos (Trustee Area 1) — -870020
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Teresa Castellanos', 'Teresa', 'Castellanos', NULL,
          true, false, false, true, -870020)
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
                               WHERE name = 'San José Unified School District, California, US')),
       p.id,
       'Board Member (Trustee Area 1)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634590'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 21: José Magaña (Trustee Area 2, Board President) — -870021
-- Unicode: é in 'José', ñ in 'Magaña'
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'José Magaña', 'José', 'Magaña', NULL,
          true, false, false, true, -870021)
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
                               WHERE name = 'San José Unified School District, California, US')),
       p.id,
       'Board Member (Trustee Area 2)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634590'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 22: Carla Collins (Trustee Area 3) — -870022
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carla Collins', 'Carla', 'Collins', NULL,
          true, false, false, true, -870022)
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
                               WHERE name = 'San José Unified School District, California, US')),
       p.id,
       'Board Member (Trustee Area 3)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634590'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 23: Brian Wheatley (Trustee Area 4, Board Vice President) — -870023
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Wheatley', 'Brian', 'Wheatley', NULL,
          true, false, false, true, -870023)
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
                               WHERE name = 'San José Unified School District, California, US')),
       p.id,
       'Board Member (Trustee Area 4)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634590'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 24: Nicole Gribstad (Trustee Area 5) — -870024
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nicole Gribstad', 'Nicole', 'Gribstad', NULL,
          true, false, false, true, -870024)
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
                               WHERE name = 'San José Unified School District, California, US')),
       p.id,
       'Board Member (Trustee Area 5)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0634590'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- FREMONT UNIFIED SCHOOL DISTRICT (FUSD) — 5 members, geo_id='0614400'
-- Numbered areas 1–5; student member NOT seeded
-- Source: fremontunified.org/about/board/board-of-education-members (403 during research; roster confirmed via WebSearch 2026-06-01)
-- ============================

-- BLOCK 25: Sharon Coco (Area 1, Vice President) — -870025
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sharon Coco', 'Sharon', 'Coco', NULL,
          true, false, false, true, -870025)
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
                               WHERE name = 'Fremont Unified School District, California, US')),
       p.id,
       'Board Member (Area 1)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0614400'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 26: Larry Sweeney (Area 2) — -870026
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Larry Sweeney', 'Larry', 'Sweeney', NULL,
          true, false, false, true, -870026)
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
                               WHERE name = 'Fremont Unified School District, California, US')),
       p.id,
       'Board Member (Area 2)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0614400'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 27: Dianne Jones (Area 3, President) — -870027
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dianne Jones', 'Dianne', 'Jones', NULL,
          true, false, false, true, -870027)
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
                               WHERE name = 'Fremont Unified School District, California, US')),
       p.id,
       'Board Member (Area 3)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0614400'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 28: Rinu Nair (Area 4) — -870028
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rinu Nair', 'Rinu', 'Nair', NULL,
          true, false, false, true, -870028)
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
                               WHERE name = 'Fremont Unified School District, California, US')),
       p.id,
       'Board Member (Area 4)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0614400'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 29: Vivek Prasad (Area 5, Clerk) — -870029
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vivek Prasad', 'Vivek', 'Prasad', NULL,
          true, false, false, true, -870029)
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
                               WHERE name = 'Fremont Unified School District, California, US')),
       p.id,
       'Board Member (Area 5)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0614400'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- BERKELEY UNIFIED SCHOOL DISTRICT (BUSD) — 5 members, geo_id='0604740'
-- Office title: 'Director' (official BUSD terminology — matches berkeleyschools.net)
-- All 5 seats are at-large (no numbered sub-districts); student directors NOT seeded
-- Name note: 'Ka''Dijah Brown' includes apostrophe character
-- Source: https://www.berkeleyschools.net/schoolboard/ (verified 2026-06-01)
-- ============================

-- BLOCK 30: Mike Chang (President) — -870030
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Chang', 'Mike', 'Chang', NULL,
          true, false, false, true, -870030)
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
                               WHERE name = 'Berkeley Unified School District, California, US')),
       p.id,
       'Director', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0604740'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 31: Jennifer Corn (Vice President) — -870031
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jennifer Corn', 'Jennifer', 'Corn', NULL,
          true, false, false, true, -870031)
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
                               WHERE name = 'Berkeley Unified School District, California, US')),
       p.id,
       'Director', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0604740'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 32: Ka'Dijah Brown (Director) — -870032
-- Apostrophe in name per berkeleyschools.net official page
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ka''Dijah Brown', 'Ka''Dijah', 'Brown', NULL,
          true, false, false, true, -870032)
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
                               WHERE name = 'Berkeley Unified School District, California, US')),
       p.id,
       'Director', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0604740'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 33: Ana Vasudeo (Director) — -870033
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ana Vasudeo', 'Ana', 'Vasudeo', NULL,
          true, false, false, true, -870033)
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
                               WHERE name = 'Berkeley Unified School District, California, US')),
       p.id,
       'Director', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0604740'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 34: Jennifer Shanoski (Director/Clerk) — -870034
-- Listed as Director/Clerk on official page; Clerk is an officer role, not office title
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jennifer Shanoski', 'Jennifer', 'Shanoski', NULL,
          true, false, false, true, -870034)
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
                               WHERE name = 'Berkeley Unified School District, California, US')),
       p.id,
       'Director', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0604740'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'ca'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 34 CA school board officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -870034 AND -870001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count = 6
-- Gate (b): chamber count = 6
-- Gate (c): SCHOOL district count = 6
-- Gate (d): politician count = 34
-- Gate (e): office count = 34 (linked to SCHOOL districts)
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
    'San Francisco Unified School District, California, US',
    'San Diego Unified School District, California, US',
    'Sacramento City Unified School District, California, US',
    'San José Unified School District, California, US',
    'Fremont Unified School District, California, US',
    'Berkeley Unified School District, California, US'
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
        'San Francisco Unified School District, California, US',
        'San Diego Unified School District, California, US',
        'Sacramento City Unified School District, California, US',
        'San José Unified School District, California, US',
        'Fremont Unified School District, California, US',
        'Berkeley Unified School District, California, US'
      )
    );
  IF v_chamber_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 6 Board of Education chambers, found %', v_chamber_count;
  END IF;

  -- Gate (c): 6 SCHOOL district rows
  SELECT COUNT(*) INTO v_dist_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'ca'
    AND geo_id IN ('0634410','0634320','0633840','0634590','0614400','0604740');
  IF v_dist_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 6 SCHOOL district rows, found %', v_dist_count;
  END IF;

  -- Gate (d): 34 politicians in external_id range
  SELECT COUNT(*) INTO v_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -870034 AND -870001;
  IF v_pol_count <> 34 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 34 politicians in -870034..-870001 range, found %', v_pol_count;
  END IF;

  -- Gate (e): 34 offices linked to SCHOOL districts
  SELECT COUNT(*) INTO v_off_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'SCHOOL'
    AND d.geo_id IN ('0634410','0634320','0633840','0634590','0614400','0604740');
  IF v_off_count <> 34 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 34 offices linked to SCHOOL districts, found %', v_off_count;
  END IF;

  -- Gate (f): Section-split check — all 6 G5420 geofences have SCHOOL district rows
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id IN ('0634410','0634320','0633840','0634590','0614400','0604740')
    AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'SCHOOL'
        AND d.state = 'ca'
    );
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split returned % orphan rows (G5420 geofence without SCHOOL district row)', v_split_count;
  END IF;

  -- Gate (g): Office_id back-fill complete
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -870034 AND -870001
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in -870034..-870001 range still have NULL office_id', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 257 post-verification PASSED: 6 govs, 6 chambers, 6 SCHOOL districts, 34 politicians, 34 offices, section-split=0, office_id back-fill complete';
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('257')
ON CONFLICT (version) DO NOTHING;

COMMIT;
