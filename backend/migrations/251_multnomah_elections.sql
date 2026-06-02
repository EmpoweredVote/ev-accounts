-- Migration 251: Multnomah County + smaller city 2026 race rows — Phase 85 Plan 01
-- Total: 18 race rows (2 county + 4 Gresham + 3 Troutdale + 4 Fairview + 2 Wood Village + 3 Maywood Park)

DO $$
DECLARE
  v_general_id UUID;
BEGIN
  -- OR 2026 General already exists in DB (id=de10e3a7-f5c2-47e6-acd7-ee87be9413db)
  -- SELECT it by name+state for resilience
  SELECT id INTO v_general_id FROM essentials.elections
  WHERE name = 'OR 2026 General' AND state = 'OR';

  IF v_general_id IS NULL THEN
    RAISE EXCEPTION 'OR 2026 General election row missing — cannot seed race rows';
  END IF;

  -- MULTNOMAH COUNTY (2 rows)
  -- Chair: Jessica Vega Pederson term ends 2026 (office_id verified from live DB)
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '4b4821cf-9a97-4044-8132-706290d22e27'::uuid,
    'Multnomah County Chair', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  -- Commissioner District 2: Shannon Singleton running for Chair; seat expires 2026
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '3f01e9e8-bac6-4f0c-9793-ed14fbe2b22b'::uuid,
    'Multnomah County Commissioner District 2', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  -- GRESHAM (4 rows)
  -- Mayor + Positions 2, 4, 6 on 2026 ballot (4-year staggered terms)
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '4658f141-8cfd-4739-a959-23322a3182e7'::uuid,
    'Gresham Mayor', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, 'be91f6d5-b46f-4ca2-9605-a1eb62b47c01'::uuid,
    'Gresham City Council Position 2', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '3c3cc31d-384e-4837-bd72-5c43faca3bc8'::uuid,
    'Gresham City Council Position 4', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '4cf1b2b1-e005-48d7-b8a4-67040d8199cd'::uuid,
    'Gresham City Council Position 6', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  -- TROUTDALE (3 rows)
  -- At-large council; 3 seats up: Jesse Davidson (Seat 1), Geoffrey Wunn (Seat 2), Zach Andrews (Seat 3)
  -- Seat numbers researcher-assigned by external_id order; distinct names required to avoid ON CONFLICT collapse
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '0b80a890-44f1-47be-bf6b-b17fc3eef9cb'::uuid,
    'Troutdale City Council Seat 1', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, 'f291ef52-c368-472c-bce1-948e803eaf23'::uuid,
    'Troutdale City Council Seat 2', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '10292aee-a4c1-4a74-88b2-b85e3ff40722'::uuid,
    'Troutdale City Council Seat 3', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  -- FAIRVIEW (4 rows)
  -- Mayor + Positions 4, 5, 6 on 2026 ballot (4-year terms)
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '0ff020a1-224f-4363-9c2f-8944b12ffcf2'::uuid,
    'Fairview Mayor', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '15f9aaf4-3d4b-4f34-9213-cb3a8ca19e94'::uuid,
    'Fairview City Council Position 4', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '15da3e65-a69f-429b-b0db-c4d450fb1c71'::uuid,
    'Fairview City Council Position 5', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, 'db927fb8-7627-4a22-b486-9888c22559b4'::uuid,
    'Fairview City Council Position 6', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  -- WOOD VILLAGE (2 rows)
  -- John Miner + Charlene Gothard terms end 12/31/2026; Mayor is council-selected (NOT on ballot)
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '8e42ac99-e2bb-4ea5-b8f6-02372ca0b4a6'::uuid,
    'Wood Village City Council Seat 1', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, 'c6c3259e-8883-4893-9fe4-50384d131f72'::uuid,
    'Wood Village City Council Seat 2', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  -- MAYWOOD PARK (3 rows)
  -- Jeff Baltzell, Miriam Berman, Thomas Welander on 2026 ballot
  -- Mayor Jim Akers is council-selected (NOT on ballot); Kevin Bussema term ends 2028 (NOT on ballot)
  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, '23370dd5-9602-40b7-a820-74fd4b5055a1'::uuid,
    'Maywood Park City Council Seat 1', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, 'bec2352c-e2ff-46c9-bdda-bd5bf13ae254'::uuid,
    'Maywood Park City Council Seat 2', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
  VALUES (gen_random_uuid(), v_general_id, 'bbd553e7-1e67-4504-96dc-5f5c017eabd5'::uuid,
    'Maywood Park City Council Seat 3', NULL, 1)
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

END $$;

-- Post-verify: ensure expected race row counts landed
DO $$
DECLARE
  v_county_count INTEGER;
  v_city_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_county_count
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.name = 'OR 2026 General'
    AND r.position_name ILIKE '%Multnomah County%';

  IF v_county_count < 2 THEN
    RAISE EXCEPTION 'Expected >= 2 Multnomah County race rows, found %', v_county_count;
  END IF;

  SELECT COUNT(*) INTO v_city_count
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.name = 'OR 2026 General'
    AND r.position_name ~ '(Gresham|Troutdale|Fairview|Wood Village|Maywood Park)';

  IF v_city_count < 16 THEN
    RAISE EXCEPTION 'Expected >= 16 city race rows, found %', v_city_count;
  END IF;

  RAISE NOTICE 'Post-verify PASSED: county_rows=%, city_rows=%', v_county_count, v_city_count;
END $$;

-- Migration ledger entry
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('251')
ON CONFLICT (version) DO NOTHING;
