-- Migration 357: MA 2026 Statewide + Federal Races
-- Phase 110: MA 2026 Elections + Discovery
-- Date: 2026-06-11
--
-- PRE-CONDITIONS (asserted before running):
--   - 2 MA 2026 election rows exist (MA-ELECTIONS-01: SATISFIED)
--   - 2 MA discovery_jurisdictions rows exist for geo_id='25' (MA-ELECTIONS-04: SATISFIED)
--
-- ACTIONS:
--   1. UPDATE 2 NULL office_id rows on U.S. Senate Massachusetts races (both primary and general)
--   2. INSERT Governor + 9 US House general election races (with ON CONFLICT guard)
--   3. INSERT Healey into race_candidates for Governor race
--   4. Ledger entry
--   5. Post-verify DO $$ block

-- ==========================================================================
-- SECTION 1: Fix NULL office_id on U.S. Senate Massachusetts races
-- Must come BEFORE any INSERT statements
-- ==========================================================================
UPDATE essentials.races
SET office_id = '215e8e94-ab07-4ca8-b7a1-ccf7aec0c4f4'
WHERE position_name = 'U.S. Senate Massachusetts'
  AND election_id IN (
    SELECT id FROM essentials.elections
    WHERE state = 'MA' AND name LIKE '2026 Massachusetts%'
  )
  AND office_id IS NULL;

-- ==========================================================================
-- SECTION 2: INSERT statewide + federal general election races
-- Governor of Massachusetts + 9 US House races (MA-05 and MA-07 already exist;
-- ON CONFLICT guard makes this idempotent)
-- ==========================================================================
WITH gen_elec AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 Massachusetts General Election' AND state = 'MA'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT gen_elec.id, t.office_id_val::uuid, t.position_name_val, NULL, 1
FROM gen_elec, (VALUES
  ('21f9e818-904d-4a19-879b-438f447bcd68', 'Governor of Massachusetts'),
  ('2a3279e2-3d67-408a-971c-294ef602c293', 'U.S. House MA-01'),
  ('372f56fe-4f30-4526-80f2-1a66c5fe870b', 'U.S. House MA-02'),
  ('badb581b-e37f-4359-9735-e779ff2a7c71', 'U.S. House MA-03'),
  ('0b7dc3a6-310c-4c18-92bb-2e25230701e6', 'U.S. House MA-04'),
  ('395b6873-4743-4052-870a-a391e4ed4370', 'U.S. House MA-05'),
  ('5c4f577c-f8af-4d12-ba30-24129ff5d099', 'U.S. House MA-06'),
  ('9011e2ed-f77b-4de0-92c3-d7911a0ae391', 'U.S. House MA-07'),
  ('293d949e-69cf-45a0-85fa-9ae72aabef13', 'U.S. House MA-08'),
  ('7f423afd-6a6b-4741-8eeb-cff9577b006f', 'U.S. House MA-09')
) AS t(office_id_val, position_name_val)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- ==========================================================================
-- SECTION 3: INSERT Healey into race_candidates for Governor of Massachusetts
-- politician_id = 7cf1080e-6e7e-4f5b-be00-6fb170896a7c (Maura Healey)
-- is_incumbent = true; full_name required (NOT NULL constraint)
-- ON CONFLICT DO NOTHING (Markey already in Senate race_candidates from v5.0)
-- ==========================================================================
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, true
FROM essentials.races r
JOIN essentials.elections e ON r.election_id = e.id
JOIN essentials.politicians p ON p.id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c'
WHERE e.state = 'MA'
  AND r.position_name = 'Governor of Massachusetts'
  AND e.name = '2026 Massachusetts General Election'
ON CONFLICT DO NOTHING;

-- ==========================================================================
-- SECTION 4: Ledger entry
-- ==========================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('357')
ON CONFLICT (version) DO NOTHING;

-- ==========================================================================
-- SECTION 5: Post-verify DO $$ block
-- Raises exception if NULL office_id count > 0 or statewide/federal race count != 11
-- ==========================================================================
DO $$
DECLARE
  v_null_count INT;
  v_fed_count  INT;
BEGIN
  -- Check 1: No NULL office_id on MA general election races
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.state = 'MA'
    AND e.name = '2026 Massachusetts General Election'
    AND r.office_id IS NULL;

  IF v_null_count > 0 THEN
    RAISE EXCEPTION 'MA general races still have NULL office_id: %', v_null_count;
  END IF;

  -- Check 2: Exactly 11 statewide/federal MA general election races
  SELECT COUNT(*) INTO v_fed_count
  FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.state = 'MA'
    AND e.name = '2026 Massachusetts General Election'
    AND r.position_name IN (
      'Governor of Massachusetts',
      'U.S. Senate Massachusetts',
      'U.S. House MA-01',
      'U.S. House MA-02',
      'U.S. House MA-03',
      'U.S. House MA-04',
      'U.S. House MA-05',
      'U.S. House MA-06',
      'U.S. House MA-07',
      'U.S. House MA-08',
      'U.S. House MA-09'
    );

  IF v_fed_count <> 11 THEN
    RAISE EXCEPTION 'Expected 11 MA statewide/federal general races, found %', v_fed_count;
  END IF;

  RAISE NOTICE 'Migration 357 post-verify passed: 0 NULL office_ids, 11 statewide/federal races';
END $$;
