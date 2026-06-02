-- Migration 240: Portland City Races for OR 2026 General — Phase 79 Plan 04
-- D-07 corrected: Portland D3/D4/Auditor ARE on 2026 ballot (2-year terms from 2024 charter stagger)
-- Mayor Wilson + D1 + D2 NOT up in 2026 (4-year terms)

DO $$
DECLARE
  v_general_id UUID;
BEGIN
  SELECT id INTO v_general_id FROM essentials.elections
  WHERE name = 'OR 2026 General' AND state = 'OR';

  -- District 3: Three seats — office_ids hardcoded from live DB (verified 2026-05-30)
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '3c893213-931d-4a51-9e6f-c1ae958cd900'::uuid,
    'Portland City Council District 3 Seat A', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, 'dcac1000-c76b-41a0-ab96-34553610b86f'::uuid,
    'Portland City Council District 3 Seat B', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, 'edbbd4f8-fb0c-4593-a08a-f26d8ae129be'::uuid,
    'Portland City Council District 3 Seat C', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  -- District 4: Three seats — office_ids hardcoded from live DB (verified 2026-05-30)
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '4906dd70-8966-42ab-a700-bc4976ff5058'::uuid,
    'Portland City Council District 4 Seat A', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '4ab40401-d5c6-43a3-a3d3-65e3449657c3'::uuid,
    'Portland City Council District 4 Seat B', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, 'bf096ce3-8757-40a5-b001-89705a1fa721'::uuid,
    'Portland City Council District 4 Seat C', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  -- City Auditor (hardcoded office_id from Phase 77 — a19813f9-ee4d-442d-b052-5c2f9f7db9c8)
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id,
    'a19813f9-ee4d-442d-b052-5c2f9f7db9c8'::uuid,
    'Portland City Auditor', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

END $$;
