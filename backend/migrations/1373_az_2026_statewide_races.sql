-- Migration 1373: AZ 2026 statewide race shells (6 single-winner + 1 Corporation Commission)
-- Phase 199 (AZ 2026 Elections & Discovery), Plan 02, Task 1.
--
-- Pure structure: 7 race shells, NO candidates. primary_party NULL on every shell.
-- All shells anchor to the pre-existing "AZ 2026 Statewide General" (resolved by name,
-- NOT by hardcoded UUID).
--
-- Corporation Commission: 2 of 5 seats up in 2026 (at-large 2-winner) => ONE race with
-- seats=2, NOT five shells. It MUST anchor to a STATE_EXEC office or fetchStatewideRaceRows
-- (electionService.ts ~118-121) will not surface the seats=2 race. The anchor subquery below
-- REQUIRES district_type='STATE_EXEC'; the WHERE ... IS NOT NULL guard refuses to insert a
-- non-visible (NULL/non-STATE_EXEC) anchor, and the post-verify RAISEs if the corp race is
-- missing.
--
-- Idempotent: ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING.

-- 6 statewide single-winner shells (seats=1), verified STATE_EXEC office_ids.
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT
  (SELECT id FROM essentials.elections WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ'),
  v.office_id::uuid, v.position_name, NULL, 1
FROM (VALUES
  ('4d870c55-7937-41ba-8716-7a30da7e3e06', 'Governor'),
  ('520719e6-cb1e-46a2-a99d-b83cc4d16d38', 'Secretary of State'),
  ('2214a2e6-e96b-4055-8d58-471a55e89922', 'Attorney General'),
  ('21f57932-e817-42a2-a5d6-55430990adfc', 'Treasurer'),
  ('ba26bb00-515a-4445-8cc5-b24f28107663', 'Superintendent of Public Instruction'),
  ('73481f59-8969-4734-bd69-cdf6d97df7a3', 'State Mine Inspector')
) AS v(office_id, position_name)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- 1 Corporation Commission race, seats=2, anchored to a STATE_EXEC corp office
-- (deterministic ORDER BY o.id LIMIT 1). WHERE ... IS NOT NULL refuses a non-visible anchor.
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT
  (SELECT id FROM essentials.elections WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ'),
  (SELECT o.id FROM essentials.offices o
     JOIN essentials.chambers c ON c.id = o.chamber_id
     JOIN essentials.districts d ON d.id = o.district_id
     WHERE c.name = 'Corporation Commission'
       AND o.representing_state IN ('AZ', 'Arizona')
       AND d.district_type = 'STATE_EXEC'
     ORDER BY o.id LIMIT 1),
  'Arizona Corporation Commission', NULL, 2
WHERE (SELECT o.id FROM essentials.offices o
     JOIN essentials.chambers c ON c.id = o.chamber_id
     JOIN essentials.districts d ON d.id = o.district_id
     WHERE c.name = 'Corporation Commission'
       AND o.representing_state IN ('AZ', 'Arizona')
       AND d.district_type = 'STATE_EXEC'
     ORDER BY o.id LIMIT 1) IS NOT NULL
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- Post-verify: exactly the 6 statewide shells (non-NULL office_id) + 1 seats=2 corp race
-- whose office chains to a STATE_EXEC district (so it surfaces in the statewide feed).
DO $$
DECLARE
  v_gen       uuid;
  v_statewide int;
  v_null_off  int;
  v_corp_seat int;
  v_corp_type text;
BEGIN
  SELECT id INTO v_gen FROM essentials.elections WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ';

  SELECT COUNT(*) INTO v_statewide
  FROM essentials.races
  WHERE election_id = v_gen AND primary_party IS NULL
    AND position_name IN ('Governor','Secretary of State','Attorney General','Treasurer',
                          'Superintendent of Public Instruction','State Mine Inspector');
  IF v_statewide <> 6 THEN
    RAISE EXCEPTION 'Migration 1373: expected 6 statewide shells, got %', v_statewide;
  END IF;

  SELECT COUNT(*) INTO v_null_off
  FROM essentials.races
  WHERE election_id = v_gen AND primary_party IS NULL
    AND position_name IN ('Governor','Secretary of State','Attorney General','Treasurer',
                          'Superintendent of Public Instruction','State Mine Inspector',
                          'Arizona Corporation Commission')
    AND office_id IS NULL;
  IF v_null_off <> 0 THEN
    RAISE EXCEPTION 'Migration 1373: % statewide/corp shells have NULL office_id', v_null_off;
  END IF;

  SELECT r.seats, d.district_type INTO v_corp_seat, v_corp_type
  FROM essentials.races r
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE r.election_id = v_gen AND r.position_name = 'Arizona Corporation Commission' AND r.primary_party IS NULL;

  IF v_corp_seat IS NULL THEN
    RAISE EXCEPTION 'Migration 1373: Corporation Commission race missing';
  END IF;
  IF v_corp_seat <> 2 THEN
    RAISE EXCEPTION 'Migration 1373: Corp Commission seats = % (expected 2)', v_corp_seat;
  END IF;
  IF v_corp_type IS DISTINCT FROM 'STATE_EXEC' THEN
    RAISE EXCEPTION 'Migration 1373: Corp Commission office district_type = % (expected STATE_EXEC)', v_corp_type;
  END IF;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('1373') ON CONFLICT (version) DO NOTHING;
