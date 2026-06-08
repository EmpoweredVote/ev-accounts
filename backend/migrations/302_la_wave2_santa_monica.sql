BEGIN;

-- =============================================================================
-- Migration 302: Santa Monica council gap-fill (4 Dec 2024 sworn-in members)
-- Phase 108-la-county-city-officials, Plan 02 (Wave 2), Task 3
-- =============================================================================
-- Pre-flight (migration 300) confirmed:
--   sm_office_count = 6 (all Council Member, all attached to LOCAL at-large district)
--   Existing: Phil Brock (-201400), Lana Negrete (-201401), Christine Parra (-201403),
--             Caroline Torosis (-201404), Oscar de la Torre (-201402), Jesse Zwick (-201405)
--   Current 7 members per RESEARCH.md (sworn in Dec 2024):
--     Lana Negrete ✓ (present), Jesse Zwick ✓ (present), Caroline Torosis ✓ (present),
--     Dan Hall (MISSING), Ellis Raskin (MISSING), Barry Snell (MISSING),
--     Natalya Zernitskaya (MISSING)
--   SM government: 'City of Santa Monica, California, US' (id=6adde220-8840-4e90-a005-49d51a7c1cd8)
--   SM City Council chamber: 821c8683-0844-44aa-9b1e-f26dc3897db1
--   SM LOCAL district: 407f8312-2f5b-4841-bebd-0f569efd6906, geo_id=0670000
-- =============================================================================

-- Step A — geo_id backfill (idempotent)
UPDATE essentials.districts
SET geo_id = '0670000'
WHERE label LIKE 'Santa Monica%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0670000';

-- Also set geo_id and city on the SM government row (currently NULL)
UPDATE essentials.governments
SET geo_id = '0670000',
    city = 'Santa Monica'
WHERE id = '6adde220-8840-4e90-a005-49d51a7c1cd8'
  AND (geo_id IS DISTINCT FROM '0670000' OR city IS DISTINCT FROM 'Santa Monica');

-- Step B — Government and chamber already exist; no inserts needed.
-- SM government: id=6adde220-8840-4e90-a005-49d51a7c1cd8
-- SM City Council chamber: id=821c8683-0844-44aa-9b1e-f26dc3897db1

-- Step C — LOCAL district already exists (id=407f8312, geo_id=0670000). No insert needed.

-- Step D — Insert 4 missing council members (sworn in December 2024)
-- All attach to the single LOCAL at-large district (geo_id=0670000).
-- External_id range: -700030..-700036 per RESEARCH.md allocation.
-- Lana Negrete is already in DB at -201401; start at -700030 for the 4 missing members.

-- Dan Hall (sworn in Dec 2024, external_id=-700030)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (
    gen_random_uuid(),
    'Dan Hall',
    'Dan',
    'Hall',
    NULL,
    true,
    false,
    false,
    true,
    -700030,
    'https://www.santamonica.gov/councilmember-dan-hall'
  )
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT
  gen_random_uuid(),
  d.id,
  '821c8683-0844-44aa-9b1e-f26dc3897db1',  -- SM City Council chamber
  p.id,
  'Council Member',
  'CA',
  false,
  false,
  NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0670000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.politician_id = p.id
  );

-- Ellis Raskin (sworn in Dec 2024, external_id=-700031)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (
    gen_random_uuid(),
    'Ellis Raskin',
    'Ellis',
    'Raskin',
    NULL,
    true,
    false,
    false,
    true,
    -700031,
    'https://www.santamonica.gov/councilmember-ellis-raskin'
  )
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT
  gen_random_uuid(),
  d.id,
  '821c8683-0844-44aa-9b1e-f26dc3897db1',
  p.id,
  'Council Member',
  'CA',
  false,
  false,
  NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0670000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.politician_id = p.id
  );

-- Barry Snell (sworn in Dec 2024, external_id=-700032)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (
    gen_random_uuid(),
    'Barry Snell',
    'Barry',
    'Snell',
    NULL,
    true,
    false,
    false,
    true,
    -700032,
    'https://www.santamonica.gov/councilmember-barry-snell'
  )
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT
  gen_random_uuid(),
  d.id,
  '821c8683-0844-44aa-9b1e-f26dc3897db1',
  p.id,
  'Council Member',
  'CA',
  false,
  false,
  NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0670000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.politician_id = p.id
  );

-- Natalya Zernitskaya (sworn in Dec 2024, external_id=-700033)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (
    gen_random_uuid(),
    'Natalya Zernitskaya',
    'Natalya',
    'Zernitskaya',
    NULL,
    true,
    false,
    false,
    true,
    -700033,
    'https://www.santamonica.gov/councilmember-natalya-zernitskaya'
  )
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT
  gen_random_uuid(),
  d.id,
  '821c8683-0844-44aa-9b1e-f26dc3897db1',
  p.id,
  'Council Member',
  'CA',
  false,
  false,
  NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0670000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.politician_id = p.id
  );

-- Step E — office_id back-fill for newly inserted Santa Monica politicians
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700039 AND -700030
  AND p.office_id IS NULL;

COMMIT;
