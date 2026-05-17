-- Migration 162: MA 2026 election rows + 2nd Middlesex Democratic primary race
-- Applies after migration 161 (161_monica_rodriguez_topoff_stances)
-- Creates: 2x elections (primary + general), 1 race, 5 race_candidates

-- 1. September 1 Primary
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2026 Massachusetts State Primary', '2026-09-01', 'primary', 'state', 'MA')
ON CONFLICT (name, election_date, state) DO NOTHING;

-- 2. November 3 General
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2026 Massachusetts General Election', '2026-11-03', 'general', 'state', 'MA')
ON CONFLICT (name, election_date, state) DO NOTHING;

-- 3. 2nd Middlesex Democratic Primary race + candidates
DO $$
DECLARE
  v_primary_id UUID;
  v_race UUID;
BEGIN
  SELECT id INTO v_primary_id FROM essentials.elections
  WHERE name = '2026 Massachusetts State Primary' AND state = 'MA';

  -- Insert race (unique on election_id, position_name, primary_party)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (
    v_primary_id,
    'b1ed4e2a-4a9c-4b41-9e46-8500f608e026',  -- 2nd Middlesex district office (25D27)
    'MA State Senate 2nd Middlesex District',
    'Democratic',
    1
  )
  ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;

  -- Fetch the race id (whether just inserted or already existed)
  SELECT id INTO v_race FROM essentials.races
  WHERE election_id = v_primary_id
    AND position_name = 'MA State Senate 2nd Middlesex District'
    AND primary_party = 'Democratic';

  -- Azeem: existing Cambridge City Councillor politician (is_incumbent=false — open seat, Jehlen retiring)
  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_race, 'Burhan Azeem', 'Burhan', 'Azeem',
         'd2358e54-6860-4382-8c8d-95a3dabea874', false, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_race AND full_name = 'Burhan Azeem'
  );

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_race, 'Christine Barber', 'Christine', 'Barber',
         NULL, false, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_race AND full_name = 'Christine Barber'
  );

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_race, 'Tom Hopcroft', 'Tom', 'Hopcroft',
         NULL, false, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_race AND full_name = 'Tom Hopcroft'
  );

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_race, 'Matt McLaughlin', 'Matt', 'McLaughlin',
         NULL, false, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_race AND full_name = 'Matt McLaughlin'
  );

  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  SELECT v_race, 'Erika Uyterhoeven', 'Erika', 'Uyterhoeven',
         NULL, false, 'active', 'ballotpedia'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates
    WHERE race_id = v_race AND full_name = 'Erika Uyterhoeven'
  );
END $$;
