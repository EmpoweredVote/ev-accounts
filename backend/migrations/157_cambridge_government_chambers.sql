-- =============================================================================
-- Migration 157: Cambridge, MA — government row + City Council + School Committee chambers
--
-- Cambridge is a Council-Manager city with STV proportional elections.
-- Two chambers share one government row:
--   - City Council: 9 at-large seats
--   - School Committee: 6 at-large seats
-- Mayor is appointed by council (not a separately elected role — handled in migration 158).
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT.
-- CRITICAL: election_method column does not exist yet — ALTER TABLE runs first.
-- NOTE: essentials.governments has no unique constraint on geo_id — use WHERE NOT EXISTS.
-- =============================================================================

BEGIN;

-- Add election_method column (idempotent — ADD COLUMN IF NOT EXISTS)
ALTER TABLE essentials.chambers
  ADD COLUMN IF NOT EXISTS election_method TEXT DEFAULT NULL;

DO $$
DECLARE
  v_gov_id     UUID;
  v_council_id UUID;
  v_school_id  UUID;
BEGIN
  -- Cambridge government row (WHERE NOT EXISTS guard — no unique constraint on geo_id)
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  SELECT 'City of Cambridge, Massachusetts, US', 'LOCAL', 'MA', NULL, '2511000'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2511000')
  RETURNING id INTO v_gov_id;

  -- If government already existed, fetch its id
  IF v_gov_id IS NULL THEN
    SELECT id INTO v_gov_id
    FROM essentials.governments
    WHERE geo_id = '2511000';
  END IF;

  IF v_gov_id IS NULL THEN
    RAISE EXCEPTION 'Cambridge government row not found and could not be inserted';
  END IF;

  -- City Council chamber (9 at-large seats, STV proportional)
  SELECT id INTO v_council_id
  FROM essentials.chambers
  WHERE government_id = v_gov_id AND name = 'City Council';

  IF v_council_id IS NULL THEN
    INSERT INTO essentials.chambers
      (government_id, name, name_formal, official_count,
       policy_engagement_level, website_url, election_method)
    VALUES
      (v_gov_id,
       'City Council',
       'Cambridge City Council',
       9,
       'full',
       'https://www.cambridgema.gov/departments/citycouncil',
       'stv_proportional')
    RETURNING id INTO v_council_id;
  END IF;

  -- School Committee chamber (6 at-large seats, STV proportional)
  SELECT id INTO v_school_id
  FROM essentials.chambers
  WHERE government_id = v_gov_id AND name = 'School Committee';

  IF v_school_id IS NULL THEN
    INSERT INTO essentials.chambers
      (government_id, name, name_formal, official_count,
       policy_engagement_level, website_url, election_method)
    VALUES
      (v_gov_id,
       'School Committee',
       'Cambridge School Committee',
       6,
       'full',
       'https://www.cpsd.us/school_committee',
       'stv_proportional')
    RETURNING id INTO v_school_id;
  END IF;

  RAISE NOTICE 'Cambridge government id: %', v_gov_id;
  RAISE NOTICE 'City Council chamber id: %', v_council_id;
  RAISE NOTICE 'School Committee chamber id: %', v_school_id;
END $$;

COMMIT;
