-- =============================================================================
-- Migration 081: Avalon (Catalina Island) June 2, 2026 races + candidates
--
-- Races:
--   Mayor (1 seat): 4 candidates
--   City Council At-Large (2 seats): 4 candidates
--
-- Note: Exact California ballot designations unavailable online for most
-- candidates; designations marked NULL or sourced from Catalina Islander
-- reporting. Verify against official sample ballot when published.
--
-- Source: cityofavalon.gov election page, Catalina Islander, Ballotpedia
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id   UUID := '1ebca37f-cf96-47f4-bc2b-47ef266721fe';
  v_office_mayor  UUID;
  v_office_cc     UUID;
  v_race_mayor    UUID;
  v_race_council  UUID;
BEGIN

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Mayor', 'Avalon', 'CA', 'Mayor', 1)
  RETURNING id INTO v_office_mayor;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Avalon', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_cc;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_mayor, 'Avalon Mayor', 1)
  RETURNING id INTO v_race_mayor;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_cc, 'Avalon City Council', 2)
  RETURNING id INTO v_race_council;

  -- -----------------------------------------------------------------------
  -- Mayor candidates (ballot order per March 12, 2026 alphabet drawing)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source) VALUES
    (v_race_mayor, 'Cinde Cassidy',   'Cinde',   'Cassidy',  'Former Council Member, City of Avalon',   false, 'clerk_official'),
    (v_race_mayor, 'Daniel Felts',    'Daniel',  'Felts',    NULL,                                      false, 'clerk_official'),
    (v_race_mayor, 'Anni Marshall',   'Anni',    'Marshall', 'Mayor, City of Avalon',                   true,  'clerk_official'),
    (v_race_mayor, 'Grayson Kline',   'Grayson', 'Kline',    NULL,                                      false, 'clerk_official');

  -- -----------------------------------------------------------------------
  -- City Council at-large candidates (2 seats; ballot order)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source) VALUES
    (v_race_council, 'Donna Lopez',      'Donna',   'Lopez',   NULL,                                    false, 'clerk_official'),
    (v_race_council, 'Michael Ponce',    'Michael', 'Ponce',   NULL,                                    true,  'clerk_official'),
    (v_race_council, 'Jessica Romero',   'Jessica', 'Romero',  'Planning Commissioner, City of Avalon', false, 'clerk_official'),
    (v_race_council, 'Bre Bussard',      'Bre',     'Bussard', NULL,                                    false, 'clerk_official');

END $$;

-- Add Avalon to discovery_jurisdictions
INSERT INTO essentials.discovery_jurisdictions (
  jurisdiction_geoid,
  jurisdiction_name,
  state,
  election_date,
  source_url,
  allowed_domains
) VALUES (
  '0602364',
  'Avalon',
  'CA',
  '2026-06-02',
  'https://www.cityofavalon.gov/199/Election-Information',
  ARRAY['cityofavalon.gov', 'thecatalinaislander.com', 'ballotpedia.org']
);

COMMIT;
