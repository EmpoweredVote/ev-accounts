BEGIN;

-- Migration 213: Berkeley government structure
--
-- Creates:
--   1 government row: 'City of Berkeley' (type='LOCAL', state='CA', geo_id='0606000')
--   3 chamber rows:   Mayor, City Council, City Auditor
--                     (ALL THREE flagged with TODO Phase 69: set election_method='RCV')
--   8 district rows:  LOCAL council districts (berkeley-council-district-1 through 8, state='CA')
--   1 district row:   LOCAL_EXEC Berkeley-wide district (geo_id='0606000', for Mayor + City Auditor)
--
-- Idempotent via WHERE NOT EXISTS guards:
--   - essentials.governments has NO unique constraint on geo_id
--   - essentials.districts has NO unique constraint on (geo_id, district_type)
--   - DO NOT use ON CONFLICT (geo_id, district_type) — that constraint does not exist
--   - essentials.chambers.slug is a GENERATED column — never include in INSERT columns
--
-- Berkeley has 3 elected offices: Mayor (citywide), 8-member City Council (single-member
-- districts D1-D8), and City Auditor (citywide). ALL THREE use Ranked Choice Voting (RCV).
-- There is NO elected City Attorney (appointed by Council) and NO separate chamber for
-- Council President/Vice-President (governance appointment roles, not separate offices).
-- BOTH Mayor and City Auditor are citywide and FK to the single LOCAL_EXEC district.
--
-- After this migration, plan 68-02 seeds politicians and their office rows.

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Government row (City of Berkeley)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Berkeley', 'LOCAL', 'CA', 'Berkeley', '0606000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Berkeley' AND state = 'CA'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Chambers (slug is GENERATED — never include in INSERT)
-- 3 chambers: Mayor, City Council, City Auditor — ALL use RCV (TODO Phase 69)
-- ─────────────────────────────────────────────────────────────────────────────

-- Mayor chamber (citywide, independently elected via RCV)
-- TODO Phase 69: set election_method='RCV'
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Berkeley',
       (SELECT id FROM essentials.governments WHERE name = 'City of Berkeley' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Berkeley' AND state = 'CA')
);

-- City Council chamber (district-based, 8 single-member districts via RCV)
-- TODO Phase 69: set election_method='RCV'
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Berkeley City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Berkeley' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Berkeley' AND state = 'CA')
);

-- City Auditor chamber (citywide, independently elected via RCV)
-- TODO Phase 69: set election_method='RCV'
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Auditor', 'City Auditor of Berkeley',
       (SELECT id FROM essentials.governments WHERE name = 'City of Berkeley' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Auditor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Berkeley' AND state = 'CA')
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: 8 council district rows (LOCAL)
-- CRITICAL: NO ON CONFLICT — the unique constraint on (geo_id, district_type) does not exist.
-- Column is 'label' (not 'name').
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('berkeley-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('berkeley-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('berkeley-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('berkeley-council-district-4', 'LOCAL', 'District 4', 'CA'),
  ('berkeley-council-district-5', 'LOCAL', 'District 5', 'CA'),
  ('berkeley-council-district-6', 'LOCAL', 'District 6', 'CA'),
  ('berkeley-council-district-7', 'LOCAL', 'District 7', 'CA'),
  ('berkeley-council-district-8', 'LOCAL', 'District 8', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 4: Berkeley-wide LOCAL_EXEC district (for Mayor + City Auditor citywide offices)
-- Reuses geo_id='0606000' (Berkeley TIGER G4110 boundary from Phase 57)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0606000', 'LOCAL_EXEC', 'Berkeley (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0606000' AND state = 'CA' AND district_type IN ('LOCAL', 'LOCAL_EXEC')
);

COMMIT;
