-- Migration 1375: AZ 2026 Tucson-metro local race shells (exactly 6)
-- Phase 199 (AZ 2026 Elections & Discovery), Plan 03.
--
-- Pure structure: 6 local race shells, NO candidates. primary_party NULL on every shell.
-- All shells anchor to the pre-existing "AZ 2026 Statewide General" (resolved by name).
--
-- Confirmed 2026 cycle (RESEARCH §4e):
--   South Tucson City Council  seats=3   (geo_id 0468850)
--   Oro Valley Mayor           seats=1   (office b3c8f75c -> geo_id 0451600)
--   Oro Valley Town Council    seats=3   (geo_id 0451600)
--   Marana Mayor               seats=1   (office ac3daf57 -> geo_id 0444270)
--   Marana Town Council        seats=4   (geo_id 0444270)
--   Sahuarita Town Council     seats=3   (geo_id 0462140, no mayor race -- council appoints)
--
-- NEGATIVE scope (proven by post-verify):
--   ZERO Pima County Board of Supervisors shells (county supervisors run presidential years; 2024->2028).
--   ZERO City of Tucson shells (Tucson runs odd-year; note "South Tucson City Council" is a DIFFERENT
--   city and is legitimately seeded -- the Tucson negatives are scoped to 'Tucson Mayor'/'%Tucson Ward%').
--
-- VISIBILITY: fetchGovernmentRaceRows matches office->chamber->government by g.geo_id, so each anchor
-- MUST chain to the correct city geo_id (not merely be non-NULL). Mayors use verified office_id
-- literals; councils use a deterministic chamber->government ORDER BY o.id LIMIT 1 subquery.
--
-- Idempotent: ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING.

-- Mayors (seats=1) -- verified office_ids that chain to their city geo_id.
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT
  (SELECT id FROM essentials.elections WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ'),
  v.office_id::uuid, v.position_name, NULL, 1
FROM (VALUES
  ('b3c8f75c-e8f9-4097-ab14-5790e380f9df', 'Oro Valley Mayor'),
  ('ac3daf57-c50a-4056-af79-acdda23551df', 'Marana Mayor')
) AS v(office_id, position_name)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- Councils (at-large) -- deterministic council office anchor via chamber -> government geo_id.
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT
  (SELECT id FROM essentials.elections WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ'),
  anchor.office_id, v.position_name, NULL, v.seats
FROM (VALUES
  ('0468850', 'South Tucson City Council', 3),
  ('0451600', 'Oro Valley Town Council',   3),
  ('0444270', 'Marana Town Council',       4),
  ('0462140', 'Sahuarita Town Council',    3)
) AS v(geo_id, position_name, seats)
JOIN LATERAL (
  SELECT o.id AS office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = v.geo_id AND ch.name ILIKE '%council%'
  ORDER BY o.id LIMIT 1
) anchor ON TRUE
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- Post-verify: exactly the 6 named shells (non-NULL office_id), each chaining to its expected
-- government geo_id; and the two negative facts (zero Pima BoS, zero City of Tucson).
DO $$
DECLARE
  v_gen uuid;
  v_cnt int;
  v_null int;
  v_bad int;
  v_sup int;
  v_tuc int;
BEGIN
  SELECT id INTO v_gen FROM essentials.elections WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ';

  SELECT COUNT(*) INTO v_cnt FROM essentials.races
  WHERE election_id = v_gen AND primary_party IS NULL
    AND position_name IN ('Oro Valley Mayor','Marana Mayor','South Tucson City Council',
                          'Oro Valley Town Council','Marana Town Council','Sahuarita Town Council');
  IF v_cnt <> 6 THEN RAISE EXCEPTION 'Migration 1375: expected 6 local shells, got %', v_cnt; END IF;

  SELECT COUNT(*) INTO v_null FROM essentials.races
  WHERE election_id = v_gen AND primary_party IS NULL AND office_id IS NULL
    AND position_name IN ('Oro Valley Mayor','Marana Mayor','South Tucson City Council',
                          'Oro Valley Town Council','Marana Town Council','Sahuarita Town Council');
  IF v_null <> 0 THEN RAISE EXCEPTION 'Migration 1375: % local shells with NULL office_id', v_null; END IF;

  SELECT COUNT(*) INTO v_bad
  FROM (VALUES
    ('Oro Valley Mayor','0451600'),
    ('Oro Valley Town Council','0451600'),
    ('Marana Mayor','0444270'),
    ('Marana Town Council','0444270'),
    ('South Tucson City Council','0468850'),
    ('Sahuarita Town Council','0462140')
  ) AS exp(position_name, geo_id)
  JOIN essentials.races r ON r.election_id = v_gen AND r.primary_party IS NULL AND r.position_name = exp.position_name
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id IS DISTINCT FROM exp.geo_id;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Migration 1375: % local shells do not chain to expected geo_id', v_bad; END IF;

  SELECT COUNT(*) INTO v_sup FROM essentials.races WHERE election_id = v_gen AND position_name LIKE '%Supervisor%';
  IF v_sup <> 0 THEN RAISE EXCEPTION 'Migration 1375: % Supervisor (Pima BoS) races present (expected 0)', v_sup; END IF;

  SELECT COUNT(*) INTO v_tuc FROM essentials.races
  WHERE election_id = v_gen AND (position_name = 'Tucson Mayor' OR position_name LIKE '%Tucson Ward%');
  IF v_tuc <> 0 THEN RAISE EXCEPTION 'Migration 1375: % City-of-Tucson races present (expected 0)', v_tuc; END IF;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('1375') ON CONFLICT (version) DO NOTHING;
