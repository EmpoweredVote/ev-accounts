BEGIN;

-- Migration 217: San Jose government structure
--
-- Creates:
--   1 government row: 'City of San Jose' (type='LOCAL', state='CA', geo_id='0668000')
--   2 chamber rows:   Mayor, City Council
--                     (BOTH flagged with TODO Phase 69: set election_method='RCV')
--   10 district rows: LOCAL council districts (sj-council-district-1 through 10, state='CA')
--   1 district row:   LOCAL_EXEC San Jose citywide district (geo_id='0668000', for Mayor)
--
-- Idempotent via WHERE NOT EXISTS guards:
--   - essentials.governments has NO unique constraint on geo_id
--   - essentials.districts has NO unique constraint on (geo_id, district_type)
--   - DO NOT use ON CONFLICT (geo_id, district_type) — that constraint does not exist
--   - essentials.chambers.slug is a GENERATED column — never include in INSERT columns
--
-- San Jose has 2 elected offices: Mayor (citywide) and 10 Council Members (by district).
-- City Attorney and City Auditor are BOTH APPOINTED by the City Council per the San Jose
-- City Charter. Neither is a popularly-elected position. Do NOT create chambers for them.
-- San Jose uses Ranked Choice Voting (RCV) for both Mayor and City Council elections.
--
-- After this migration, plan 64-02 seeds politicians and their office rows.

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Government row (City of San Jose)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of San Jose', 'LOCAL', 'CA', 'San Jose', '0668000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of San Jose' AND state = 'CA'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Chambers (slug is GENERATED — never include in INSERT)
-- 2 chambers: Mayor and City Council — BOTH use RCV (TODO Phase 69)
-- City Attorney and City Auditor are appointed — NO chambers for them
-- ─────────────────────────────────────────────────────────────────────────────

-- Mayor chamber (citywide, independently elected via RCV)
-- TODO Phase 69: set election_method='RCV'
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of San Jose',
       (SELECT id FROM essentials.governments WHERE name = 'City of San Jose' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of San Jose' AND state = 'CA')
);

-- City Council chamber (10 single-member districts, elected via RCV)
-- TODO Phase 69: set election_method='RCV'
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'San Jose City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of San Jose' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of San Jose' AND state = 'CA')
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: 10 council district rows (LOCAL)
-- CRITICAL: NO ON CONFLICT — the unique constraint on (geo_id, district_type) does not exist.
-- Column is 'label' (not 'name').
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('sj-council-district-1',  'LOCAL', 'District 1',  'CA'),
  ('sj-council-district-2',  'LOCAL', 'District 2',  'CA'),
  ('sj-council-district-3',  'LOCAL', 'District 3',  'CA'),
  ('sj-council-district-4',  'LOCAL', 'District 4',  'CA'),
  ('sj-council-district-5',  'LOCAL', 'District 5',  'CA'),
  ('sj-council-district-6',  'LOCAL', 'District 6',  'CA'),
  ('sj-council-district-7',  'LOCAL', 'District 7',  'CA'),
  ('sj-council-district-8',  'LOCAL', 'District 8',  'CA'),
  ('sj-council-district-9',  'LOCAL', 'District 9',  'CA'),
  ('sj-council-district-10', 'LOCAL', 'District 10', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 4: San Jose citywide LOCAL_EXEC district (for Mayor citywide office)
-- Reuses geo_id='0668000' (San Jose TIGER G4110 boundary from Phase 57)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0668000', 'LOCAL_EXEC', 'San Jose (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0668000' AND state = 'CA' AND district_type IN ('LOCAL', 'LOCAL_EXEC')
);

COMMIT;
