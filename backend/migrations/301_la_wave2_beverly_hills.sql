BEGIN;

-- =============================================================================
-- Migration 301: Beverly Hills council gap-fill + City Treasurer Howard Fisher
-- Phase 108-la-county-city-officials, Plan 02 (Wave 2), Task 2
-- =============================================================================
-- Pre-flight (migration 300) confirmed:
--   bh_office_count = 4 (3 Council Member + 1 Mayor)
--   Existing politicians: Craig A. Corman (-201154), John A. Mirisch (-201153),
--     Mary N. Wells (-201155), Lester Friedman (-200589, Mayor)
--   Missing: Sharona R. Nazarian (5th council seat) + Howard Fisher (City Treasurer)
--   BH government name: 'City of Beverly Hills, California, US'
--   BH City Council chamber exists: 9c1ac8de-42ef-4cf1-90ee-b5e8d9f5f5d6
--   No City Treasurer chamber exists for BH — create it here
-- =============================================================================

-- Step A — geo_id backfill (idempotent)
-- Ensure the BH LOCAL and LOCAL_EXEC districts have geo_id=0606308 set.
UPDATE essentials.districts
SET geo_id = '0606308'
WHERE label LIKE 'Beverly Hills%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0606308';

-- Also update the BH government row to set geo_id and city (currently NULL)
UPDATE essentials.governments
SET geo_id = '0606308',
    city = 'Beverly Hills'
WHERE id = 'd319e00d-07c4-44b3-99f5-390ea6453d59'
  AND (geo_id IS DISTINCT FROM '0606308' OR city IS DISTINCT FROM 'Beverly Hills');

-- Step B — City Treasurer chamber for Beverly Hills (does not exist yet)
-- CRITICAL: slug is GENERATED ALWAYS AS — never include in INSERT column list (Pitfall 4)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Treasurer', 'Beverly Hills City Treasurer',
       'd319e00d-07c4-44b3-99f5-390ea6453d59'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Treasurer'
    AND government_id = 'd319e00d-07c4-44b3-99f5-390ea6453d59'
);

-- Step C — district idempotency
-- LOCAL district for at-large council already exists (e0822ebc) — no insert needed
-- LOCAL_EXEC district for Mayor already exists (83e88f71) — it will serve Treasurer too
-- Both have geo_id=0606308 confirmed in pre-flight.
-- No additional district inserts required.

-- Step D — Insert Sharona R. Nazarian (5th council member, external_id=-700010)
-- The first 4 council/mayor seats are filled; only Nazarian is missing from the council.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (
    gen_random_uuid(),
    'Sharona R. Nazarian',
    'Sharona',
    'Nazarian',
    NULL,
    true,
    false,
    false,
    true,
    -700010,
    'https://en.wikipedia.org/wiki/Sharona_Nazarian'
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
  '9c1ac8de-42ef-4cf1-90ee-b5e8d9f5f5d6',  -- BH City Council chamber
  p.id,
  'Council Member',
  'CA',
  false,
  false,
  NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0606308'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.politician_id = p.id
  );

-- Step E — Insert Howard Fisher, City Treasurer (external_id=-700011)
-- He is popularly ELECTED per RESEARCH.md Tier 2 BH entry.
-- Attaches to LOCAL_EXEC district (same geo_id=0606308, district_type=LOCAL_EXEC)
-- which serves citywide elected offices.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (
    gen_random_uuid(),
    'Howard Fisher',
    'Howard',
    'Fisher',
    NULL,
    true,
    false,
    false,
    true,
    -700011,
    'https://www.beverlyhills.org/government/elected-offices/city-treasurer'
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
  (SELECT id FROM essentials.chambers
   WHERE name = 'City Treasurer'
     AND government_id = 'd319e00d-07c4-44b3-99f5-390ea6453d59'),
  p.id,
  'City Treasurer',
  'CA',
  false,
  false,
  NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0606308'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.politician_id = p.id
  );

-- Step F — office_id back-fill for newly inserted Beverly Hills politicians
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700019 AND -700010
  AND p.office_id IS NULL;

COMMIT;
