-- =============================================================================
-- Migration 078: Beverly Hills June 2, 2026 races + candidates + discovery jurisdiction
--
-- Races:
--   City Council (3 seats, at-large): 11 candidates
--   City Treasurer: 1 candidate (Fisher, incumbent, unopposed)
--
-- Notable: John Mirisch barred from ballot (court ruled Feb 26, 2026 — exceeded
--   Beverly Hills' 3-term lifetime limit from Measure TL, 2022).
--
-- Source: beverlyhills.org/1757/Meet-the-June-2026-Candidates (official)
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id  UUID := '1ebca37f-cf96-47f4-bc2b-47ef266721fe';
  v_office_cc    UUID;
  v_office_treas UUID;
  v_race_council UUID;
  v_race_treas   UUID;
BEGIN

  -- Beverly Hills Councilmember office (anchor for at-large council race)
  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Beverly Hills', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_cc;

  -- Beverly Hills City Treasurer office
  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('City Treasurer', 'Beverly Hills', 'CA', 'City Treasurer', 1)
  RETURNING id INTO v_office_treas;

  -- City Council race (3 seats, at-large)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_cc, 'Beverly Hills City Council', 3)
  RETURNING id INTO v_race_council;

  -- City Treasurer race
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_treas, 'Beverly Hills City Treasurer', 1)
  RETURNING id INTO v_race_treas;

  -- -----------------------------------------------------------------------
  -- City Council candidates (ballot order per official city candidate page)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source) VALUES
    (v_race_council, 'Roger Tanenbaum',       'Roger',    'Tanenbaum',  'Literary Chief Executive',                                        false, NULL,                                              'clerk_official'),
    (v_race_council, 'Rebecca Pynoos',         'Rebecca',  'Pynoos',     'Beverly Hills City Commissioner',                                 false, 'https://www.rebeccapynoos.com',                    'clerk_official'),
    (v_race_council, 'Jonathan Mariande',      'Jonathan', 'Mariande',   'Documentary Filmmaker',                                           false, NULL,                                              'clerk_official'),
    (v_race_council, 'Andy Licht',             'Andy',     'Licht',      'Beverly Hills Commissioner / Businessman',                        false, 'https://www.andylichtforbeverlyhills.com',         'clerk_official'),
    (v_race_council, 'Ariel Rofeim',           'Ariel',    'Rofeim',     'Attorney',                                                        false, NULL,                                              'clerk_official'),
    (v_race_council, 'Lester Friedman',        'Lester',   'Friedman',   'Beverly Hills Councilmember / Attorney-At-Law',                   true,  'https://www.friedmanforcouncil.com',               'clerk_official'),
    (v_race_council, 'Sharona R. Nazarian',    'Sharona',  'Nazarian',   'Beverly Hills Councilmember',                                     true,  'https://www.sharonanazarian.com',                  'clerk_official'),
    (v_race_council, 'Russell Stuart',         'Russell',  'Stuart',     'Beverly Hills Unified School District Governing Board Member',    false, 'https://www.russellstuart.com',                    'clerk_official'),
    (v_race_council, 'Clayton M. Saunders',    'Clayton',  'Saunders',   'Entrepreneur',                                                    false, NULL,                                              'clerk_official'),
    (v_race_council, 'Barry Axelrod',          'Barry',    'Axelrod',    'Business Consultant',                                             false, NULL,                                              'clerk_official'),
    (v_race_council, 'Andrew Kole',            'Andrew',   'Kole',       'Writer / Animal Rescue / Consultant',                             false, NULL,                                              'clerk_official');

  -- -----------------------------------------------------------------------
  -- City Treasurer candidate (unopposed)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source) VALUES
    (v_race_treas, 'Howard S. Fisher', 'Howard', 'Fisher', 'Treasurer, Beverly Hills', true, 'clerk_official');

END $$;

-- Add Beverly Hills to discovery_jurisdictions
INSERT INTO essentials.discovery_jurisdictions (
  jurisdiction_geoid,
  jurisdiction_name,
  state,
  election_date,
  source_url,
  allowed_domains
) VALUES (
  '0606308',
  'Beverly Hills',
  'CA',
  '2026-06-02',
  'https://beverlyhills.org/1757/Meet-the-June-2026-Candidates',
  ARRAY['beverlyhills.org', 'ballotpedia.org']
);

COMMIT;
