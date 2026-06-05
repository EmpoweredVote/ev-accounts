BEGIN;

-- Migration 210: Fremont government structure
--
-- Creates:
--   1 government row: 'City of Fremont' (type='LOCAL', state='CA', geo_id='0626000')
--   2 chamber rows:   City Council, Mayor (NO City Attorney — Fremont's CA is APPOINTED)
--   6 district rows:  LOCAL council districts (fremont-council-district-1 through 6, state='CA')
--   1 district row:   LOCAL_EXEC Fremont-wide district (geo_id='0626000', for Mayor)
--
-- Idempotent via WHERE NOT EXISTS guards:
--   - essentials.governments has NO unique constraint on geo_id
--   - essentials.districts has NO unique constraint on (geo_id, district_type)
--   - DO NOT use ON CONFLICT (geo_id, district_type) — that constraint does not exist
--   - essentials.chambers.slug is a GENERATED column — never include in INSERT columns
--
-- Fremont adopted district-based council June 13, 2017 (6 districts).
-- City Attorney Rafael E. Alvarado Jr. is APPOINTED by City Council — do NOT create
-- a City Attorney chamber here. Only Mayor + City Council get chambers.
--
-- After this migration, plan 67-02 seeds politicians and their office rows.

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Government row (City of Fremont)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Fremont', 'LOCAL', 'CA', 'Fremont', '0626000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Fremont' AND state = 'CA'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Chambers (slug is GENERATED — never include in INSERT)
-- Only 2 chambers: City Council + Mayor. NO City Attorney (appointed position).
-- ─────────────────────────────────────────────────────────────────────────────

-- City Council chamber (district-based, 6 seats)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Fremont City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')
);

-- Mayor chamber (citywide, independently elected)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Fremont',
       (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: 6 council district rows (LOCAL)
-- CRITICAL: NO ON CONFLICT — the unique constraint on (geo_id, district_type) does not exist.
-- Column is 'label' (not 'name').
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('fremont-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('fremont-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('fremont-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('fremont-council-district-4', 'LOCAL', 'District 4', 'CA'),
  ('fremont-council-district-5', 'LOCAL', 'District 5', 'CA'),
  ('fremont-council-district-6', 'LOCAL', 'District 6', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 4: Fremont-wide LOCAL_EXEC district (for Mayor's citywide office)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0626000', 'LOCAL_EXEC', 'Fremont (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0626000' AND state = 'CA' AND district_type IN ('LOCAL', 'LOCAL_EXEC')
);

COMMIT;
