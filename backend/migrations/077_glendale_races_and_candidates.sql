-- =============================================================================
-- Migration 077: Glendale June 2, 2026 races + candidates + discovery jurisdiction
--
-- Races:
--   City Council (3 seats, at-large): 11 candidates
--   City Clerk: 2 candidates
--   City Treasurer: 1 candidate (Manoukian, incumbent)
--
-- Office mapping (incumbents already in DB):
--   Council Asatryan → 615de18c-2e85-4667-96c3-2b4c1527c31a
--   Council Brotman  → 0b17284a-a65f-4821-bf05-00476da671ea
--   Council (open)   → new office (Najarian not seeking reelection)
--   City Clerk       → new office
--   City Treasurer   → new office
--
-- Source: Outlook Newspapers, GEC endorsements, MyGlendale
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id  UUID := '1ebca37f-cf96-47f4-bc2b-47ef266721fe';
  v_office_cc    UUID; -- new at-large council office for open seat
  v_office_clerk UUID;
  v_office_treas UUID;
  v_race_council UUID;
  v_race_clerk   UUID;
  v_race_treas   UUID;
BEGIN

  -- New office for the open (Najarian) council seat
  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Glendale', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_cc;

  -- New City Clerk office
  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('City Clerk', 'Glendale', 'CA', 'City Clerk', 1)
  RETURNING id INTO v_office_clerk;

  -- New City Treasurer office
  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('City Treasurer', 'Glendale', 'CA', 'City Treasurer', 1)
  RETURNING id INTO v_office_treas;

  -- City Council race (3 seats — use one of the incumbent offices as the anchor)
  -- seats=3 signals to the UI that voters elect 3 candidates from this pool
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '615de18c-2e85-4667-96c3-2b4c1527c31a', 'Glendale City Council', 3)
  RETURNING id INTO v_race_council;

  -- City Clerk race
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_clerk, 'Glendale City Clerk', 1)
  RETURNING id INTO v_race_clerk;

  -- City Treasurer race
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_treas, 'Glendale City Treasurer', 1)
  RETURNING id INTO v_race_treas;

  -- -----------------------------------------------------------------------
  -- City Council candidates (incumbents first)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source) VALUES
    (v_race_council, 'Elen Asatryan',       'Elen',    'Asatryan',       'Councilmember, City of Glendale',  true,  'https://www.electelen.com',        'clerk_official'),
    (v_race_council, 'Dan Brotman',          'Dan',     'Brotman',        'Councilmember, City of Glendale',  true,  'https://www.danforglendale.com',   'clerk_official'),
    (v_race_council, 'Alek Bartrosouf',      'Alek',    'Bartrosouf',     'City Planner; Transportation Commissioner', false, 'https://www.alekforglendale.com', 'clerk_official'),
    (v_race_council, 'Alex Balekian',        'Alex',    'Balekian',       'Intensive Care Doctor',            false, NULL, 'clerk_official'),
    (v_race_council, 'Beth Brooks',          'Beth',    'Brooks',         'Retired Market Researcher',        false, NULL, 'clerk_official'),
    (v_race_council, 'Ronnie Gharibian',     'Ronnie',  'Gharibian',      'Finance Professional',             false, NULL, 'clerk_official'),
    (v_race_council, 'Gevorg Grigoryan',     'Gevorg',  'Grigoryan',      'Architect',                        false, NULL, 'clerk_official'),
    (v_race_council, 'Carolyn Kaloostian',   'Carolyn', 'Kaloostian',     'Family Physician',                 false, NULL, 'clerk_official'),
    (v_race_council, 'Davit Mnatsakanyan',   'Davit',   'Mnatsakanyan',   'Construction Company Owner',       false, NULL, 'clerk_official'),
    (v_race_council, 'Patrick Murphy',       'Patrick', 'Murphy',         'Retail Redevelopment Specialist',  false, NULL, 'clerk_official'),
    (v_race_council, 'Evelina Sarian',       'Evelina', 'Sarian',         'Small Business Owner',             false, NULL, 'clerk_official');

  -- -----------------------------------------------------------------------
  -- City Clerk candidates
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source) VALUES
    (v_race_clerk, 'Suzie Abajian',  'Suzie',  'Abajian', 'City Clerk, City of Glendale', true,  'clerk_official'),
    (v_race_clerk, 'Susan Wolfson',  'Susan',  'Wolfson', 'Certified Public Accountant',  false, 'clerk_official');

  -- -----------------------------------------------------------------------
  -- City Treasurer candidate
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source) VALUES
    (v_race_treas, 'Rafi Manoukian', 'Rafi', 'Manoukian', 'City Treasurer, City of Glendale', true, 'clerk_official');

END $$;

-- Add Glendale to discovery_jurisdictions
INSERT INTO essentials.discovery_jurisdictions (
  jurisdiction_geoid,
  jurisdiction_name,
  state,
  election_date,
  source_url,
  allowed_domains
) VALUES (
  '0630000',
  'Glendale',
  'CA',
  '2026-06-02',
  'https://www.glendalevotes.org/candidates',
  ARRAY['glendalevotes.org', 'ballotpedia.org']
);

COMMIT;
