-- Migration 163: MA 2026 US Senate + Cambridge-area district races

-- ===============================================================
-- PART A: US Senate Markey races (primary + general)
-- office_id=NULL for both: statewide races appear for all MA users
-- ===============================================================
DO $$
DECLARE
  v_primary_id  UUID;
  v_general_id  UUID;
  v_senate_primary_race UUID;
  v_senate_general_race UUID;
BEGIN
  SELECT id INTO v_primary_id FROM essentials.elections
  WHERE name = '2026 Massachusetts State Primary' AND state = 'MA';

  SELECT id INTO v_general_id FROM essentials.elections
  WHERE name = '2026 Massachusetts General Election' AND state = 'MA';

  -- -----------------------------------------------
  -- US SENATE: Markey Democratic Primary (Sept 1)
  -- office_id=NULL: statewide race (shows for all MA users)
  -- primary_party='Democratic': required for primary races
  -- -----------------------------------------------
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (v_primary_id, NULL, 'U.S. Senate Massachusetts', 'Democratic', 1)
  ON CONFLICT (election_id, position_name, primary_party) DO NOTHING
  RETURNING id INTO v_senate_primary_race;

  IF v_senate_primary_race IS NULL THEN
    SELECT id INTO v_senate_primary_race FROM essentials.races
    WHERE election_id = v_primary_id
      AND position_name = 'U.S. Senate Massachusetts'
      AND primary_party = 'Democratic';
  END IF;

  -- Primary candidates (Democratic)
  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_senate_primary_race, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source
  FROM (VALUES
    ('Ed Markey', 'Ed', 'Markey', 'faf86b5b-5add-4afb-a8e2-96b3e8be4b78'::uuid, true, 'active', 'ballotpedia'),
    ('Seth Moulton', 'Seth', 'Moulton', NULL::uuid, false, 'active', 'ballotpedia'),
    ('William Gates', 'William', 'Gates', NULL::uuid, false, 'active', 'ballotpedia'),
    ('Alexander Rikleen', 'Alexander', 'Rikleen', NULL::uuid, false, 'active', 'ballotpedia')
  ) AS v(full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_senate_primary_race AND full_name = v.full_name
  );

  -- -----------------------------------------------
  -- US SENATE: General Election (Nov 3)
  -- office_id=NULL: statewide
  -- primary_party=NULL: general race (partial index WHERE primary_party IS NULL)
  -- -----------------------------------------------
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (v_general_id, NULL, 'U.S. Senate Massachusetts', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_senate_general_race;

  IF v_senate_general_race IS NULL THEN
    SELECT id INTO v_senate_general_race FROM essentials.races
    WHERE election_id = v_general_id
      AND position_name = 'U.S. Senate Massachusetts'
      AND primary_party IS NULL;
  END IF;

  -- General candidates (both parties)
  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_senate_general_race, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source
  FROM (VALUES
    ('Ed Markey', 'Ed', 'Markey', 'faf86b5b-5add-4afb-a8e2-96b3e8be4b78'::uuid, true, 'active', 'ballotpedia'),
    ('Nathan Bech', 'Nathan', 'Bech', NULL::uuid, false, 'active', 'ballotpedia'),
    ('John Deaton', 'John', 'Deaton', NULL::uuid, false, 'active', 'ballotpedia')
  ) AS v(full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_senate_general_race AND full_name = v.full_name
  );

END $$;

-- ===============================================================
-- PART B: Cambridge-area district general races (Nov 3, 2026)
-- office_id NOT NULL: district-linked races (geofence routing)
-- ===============================================================
DO $$
DECLARE
  v_general_id  UUID;
  v_ma05_race   UUID;
  v_ma07_race   UUID;
  v_d26_race    UUID;
  v_d27gen_race UUID;
  v_d28_race    UUID;
  v_h83_race    UUID;
  v_h84_race    UUID;
BEGIN
  SELECT id INTO v_general_id FROM essentials.elections
  WHERE name = '2026 Massachusetts General Election' AND state = 'MA';

  -- MA-05 (Katherine Clark)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (v_general_id, '395b6873-4743-4052-870a-a391e4ed4370', 'U.S. House MA-05', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_ma05_race;
  IF v_ma05_race IS NULL THEN
    SELECT id INTO v_ma05_race FROM essentials.races
    WHERE election_id = v_general_id AND position_name = 'U.S. House MA-05' AND primary_party IS NULL;
  END IF;

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_ma05_race, 'Katherine Clark', 'Katherine', 'Clark',
     '7bf73fb2-1b31-412e-913d-835bfd3e326d', true, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_ma05_race AND full_name = 'Katherine Clark'
  );

  -- MA-07 (Ayanna Pressley)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (v_general_id, '9011e2ed-f77b-4de0-92c3-d7911a0ae391', 'U.S. House MA-07', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_ma07_race;
  IF v_ma07_race IS NULL THEN
    SELECT id INTO v_ma07_race FROM essentials.races
    WHERE election_id = v_general_id AND position_name = 'U.S. House MA-07' AND primary_party IS NULL;
  END IF;

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_ma07_race, 'Ayanna Pressley', 'Ayanna', 'Pressley',
     'c61baf45-dc2a-4d78-b4b7-21b1e9d79464', true, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_ma07_race AND full_name = 'Ayanna Pressley'
  );

  -- 25D26 Middlesex and Suffolk (Sal DiDomenico)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (v_general_id, 'c3ea7a34-f13d-4804-9db7-7e3f62238cfc',
          'MA State Senate Middlesex and Suffolk District', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_d26_race;
  IF v_d26_race IS NULL THEN
    SELECT id INTO v_d26_race FROM essentials.races
    WHERE election_id = v_general_id
      AND position_name = 'MA State Senate Middlesex and Suffolk District' AND primary_party IS NULL;
  END IF;

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_d26_race, 'Sal DiDomenico', 'Sal', 'DiDomenico',
     'c7e94dda-1862-40fe-bda5-5fa2fe68f536', true, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_d26_race AND full_name = 'Sal DiDomenico'
  );

  -- 25D27 2nd Middlesex (general — open seat post-primary, no candidates yet)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (v_general_id, 'b1ed4e2a-4a9c-4b41-9e46-8500f608e026',
          'MA State Senate 2nd Middlesex District', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_d27gen_race;
  -- No candidates yet — winner of September primary TBD

  -- 25D28 Suffolk and Middlesex (William Brownsberger)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (v_general_id, 'e18eeea6-cdb2-42aa-833f-23267e6d813c',
          'MA State Senate Suffolk and Middlesex District', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_d28_race;
  IF v_d28_race IS NULL THEN
    SELECT id INTO v_d28_race FROM essentials.races
    WHERE election_id = v_general_id
      AND position_name = 'MA State Senate Suffolk and Middlesex District' AND primary_party IS NULL;
  END IF;

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_d28_race, 'William Brownsberger', 'William', 'Brownsberger',
     '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7', true, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_d28_race AND full_name = 'William Brownsberger'
  );

  -- 25083 25th Middlesex House (Marjorie Decker)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (v_general_id, 'a0e18b1e-478f-49b7-8ffb-351dc338875c',
          'MA House 25th Middlesex District', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_h83_race;
  IF v_h83_race IS NULL THEN
    SELECT id INTO v_h83_race FROM essentials.races
    WHERE election_id = v_general_id
      AND position_name = 'MA House 25th Middlesex District' AND primary_party IS NULL;
  END IF;

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_h83_race, 'Marjorie Decker', 'Marjorie', 'Decker',
     '2b1a645a-72ce-4c0f-80ec-17565a2d6d10', true, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_h83_race AND full_name = 'Marjorie Decker'
  );

  -- 25084 26th Middlesex House (Mike Connolly)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (v_general_id, '06e4afe2-cbcf-421c-a569-c15b7d55a236',
          'MA House 26th Middlesex District', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_h84_race;
  IF v_h84_race IS NULL THEN
    SELECT id INTO v_h84_race FROM essentials.races
    WHERE election_id = v_general_id
      AND position_name = 'MA House 26th Middlesex District' AND primary_party IS NULL;
  END IF;

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_h84_race, 'Mike Connolly', 'Mike', 'Connolly',
     '49963775-d2d5-4ae2-95cf-b2b8d0ed2a92', true, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_h84_race AND full_name = 'Mike Connolly'
  );

END $$;
