BEGIN;

-- Migration 207: San Diego government structure
--
-- Creates:
--   1 government row: 'City of San Diego' (type='LOCAL', state='CA', geo_id='0666000')
--   3 chamber rows:   City Council, Mayor, City Attorney (all under SD government)
--   9 district rows:  LOCAL council districts (sd-council-district-1 through 9, state='CA')
--   1 district row:   LOCAL_EXEC SD-wide district (geo_id='0666000', for Mayor + City Attorney)
--
-- Idempotent via WHERE NOT EXISTS guards:
--   - essentials.governments has NO unique constraint on geo_id
--   - essentials.districts has NO unique constraint on (geo_id, district_type)
--   - DO NOT use ON CONFLICT (geo_id, district_type) — that constraint does not exist
--   - essentials.chambers.slug is a GENERATED column — never include in INSERT columns
--
-- After this migration, plan 65-02 seeds the 11 politicians (9 council members +
-- Mayor + City Attorney) and their office rows.

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Government row (City of San Diego)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of San Diego', 'LOCAL', 'CA', 'San Diego', '0666000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of San Diego' AND state = 'CA'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Chambers (slug is GENERATED — never include in INSERT)
-- ─────────────────────────────────────────────────────────────────────────────

-- City Council chamber (district-based, 9 seats)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'San Diego City Council',
       (SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')
);

-- Mayor chamber (citywide, independently elected)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of San Diego',
       (SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')
);

-- City Attorney chamber (citywide, independently elected)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Attorney', 'San Diego City Attorney',
       (SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Attorney'
    AND government_id = (SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: 9 council district rows (LOCAL)
-- CRITICAL: NO ON CONFLICT — the unique constraint on (geo_id, district_type) does not exist.
-- Column is 'label' (not 'name').
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('sd-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('sd-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('sd-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('sd-council-district-4', 'LOCAL', 'District 4', 'CA'),
  ('sd-council-district-5', 'LOCAL', 'District 5', 'CA'),
  ('sd-council-district-6', 'LOCAL', 'District 6', 'CA'),
  ('sd-council-district-7', 'LOCAL', 'District 7', 'CA'),
  ('sd-council-district-8', 'LOCAL', 'District 8', 'CA'),
  ('sd-council-district-9', 'LOCAL', 'District 9', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 4: SD-wide LOCAL_EXEC district (for citywide offices: Mayor + City Attorney)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0666000', 'LOCAL_EXEC', 'San Diego (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0666000' AND state = 'CA' AND district_type IN ('LOCAL', 'LOCAL_EXEC')
);

COMMIT;
