BEGIN;

-- Migration 219: Sacramento government structure
--
-- Creates:
--   1 government row: 'City of Sacramento' (type='LOCAL', state='CA', geo_id='0664000')
--   2 chamber rows:   Mayor, City Council
--   8 district rows:  LOCAL council districts (sacramento-council-district-1 through 8, state='CA')
--   1 district row:   LOCAL_EXEC Sacramento citywide district (geo_id='0664000', for Mayor)
--
-- Idempotent via WHERE NOT EXISTS guards:
--   - essentials.governments has NO unique constraint on geo_id
--   - essentials.districts has NO unique constraint on (geo_id, district_type)
--   - DO NOT use ON CONFLICT (geo_id, district_type) — that constraint does not exist
--   - essentials.chambers.slug is a GENERATED column — never include in INSERT columns
--
-- Sacramento has 2 elected offices: Mayor (citywide) and 8 Council Members (by district).
-- City Attorney, City Auditor, City Treasurer, and City Clerk are ALL APPOINTED by City
-- Council per the Sacramento City Charter. Confirmed by appointment records:
--   - Susana Alcala Wood, City Attorney (long-serving appointed)
--   - Jorge Martinez, City Attorney (appointed Feb 2026 per appointment records)
--   - Yvonne Ahrary, City Auditor (appointed Oct 2024 per appointment records)
-- Do NOT create chambers for any of these positions.
--
-- Sacramento uses a two-round runoff system (June primary + November runoff) as of 2026-05-23.
-- The "Better Ballot Sacramento" RCV initiative was still collecting signatures as of May 2026
-- and has not yet qualified for the ballot. If RCV passes in a future election, update
-- election_method='rcv' for both chambers at that time.
--
-- After this migration, plan 66-02 seeds politicians and their office rows.

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Government row (City of Sacramento)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Sacramento', 'LOCAL', 'CA', 'Sacramento', '0664000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Sacramento' AND state = 'CA'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Chambers (slug is GENERATED — never include in INSERT)
-- 2 chambers: Mayor and City Council
-- City Attorney, City Auditor, City Treasurer, City Clerk are appointed — NO chambers
-- Sacramento uses two-round runoff as of 2026-05-23. RCV initiative (Better Ballot
-- Sacramento) pending signature collection; not yet on ballot. If RCV passes in a
-- future election, update election_method='rcv' at that time.
-- ─────────────────────────────────────────────────────────────────────────────

-- Mayor chamber (citywide, independently elected)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Sacramento',
       (SELECT id FROM essentials.governments WHERE name = 'City of Sacramento' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Sacramento' AND state = 'CA')
);

-- City Council chamber (8 single-member districts)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Sacramento City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Sacramento' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Sacramento' AND state = 'CA')
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: 8 council district rows (LOCAL)
-- CRITICAL: NO ON CONFLICT — the unique constraint on (geo_id, district_type) does not exist.
-- Column is 'label' (not 'name').
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('sacramento-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('sacramento-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('sacramento-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('sacramento-council-district-4', 'LOCAL', 'District 4', 'CA'),
  ('sacramento-council-district-5', 'LOCAL', 'District 5', 'CA'),
  ('sacramento-council-district-6', 'LOCAL', 'District 6', 'CA'),
  ('sacramento-council-district-7', 'LOCAL', 'District 7', 'CA'),
  ('sacramento-council-district-8', 'LOCAL', 'District 8', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 4: Sacramento citywide LOCAL_EXEC district (for Mayor citywide office)
-- Reuses geo_id='0664000' (Sacramento TIGER G4110 boundary from Phase 57)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0664000', 'LOCAL_EXEC', 'Sacramento (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0664000' AND state = 'CA' AND district_type IN ('LOCAL', 'LOCAL_EXEC')
);

COMMIT;
