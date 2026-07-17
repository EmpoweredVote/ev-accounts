-- Migration 1374: AZ 2026 legislative race shells (30 State Senate + 30 State House)
-- Phase 199 (AZ 2026 Elections & Discovery), Plan 02, Task 2.
--
-- Pure structure: 60 legislative race shells, NO candidates. primary_party NULL on every shell.
-- All shells anchor to the pre-existing "AZ 2026 Statewide General" (resolved by name).
--
-- Senate: 30 single-winner shells (seats=1), one per STATE_UPPER district (geo_id 04001..04030).
-- House:  30 shells with seats=2 (NOT 60). The partial-unique index
--         idx_races_election_position_no_party (election_id, position_name) WHERE primary_party IS NULL
--         forbids 60 identically-named shells; AZ House is 2 members per district => model as 30
--         seats=2 races. seats is never a fetch filter (electionService.ts), so candidates attach
--         by race_id regardless of seats.
--
-- office_id anchor: per-district LATERAL ORDER BY o.id LIMIT 1 (deterministic, non-NULL). For House
-- the district has 2 offices; either is a correct geography anchor (same district geo_id).
-- position_name uses the verified districts.label form ('State Senate District N' / 'State House
-- District N'), so it matches the app's expected labels exactly.
--
-- Idempotent: ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING.

-- 30 State Senate shells (seats=1)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT
  (SELECT id FROM essentials.elections WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ'),
  anchor.office_id, d.label, NULL, 1
FROM essentials.districts d
JOIN LATERAL (
  SELECT o.id AS office_id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE c.name = 'State Senate' AND o.district_id = d.id
  ORDER BY o.id LIMIT 1
) anchor ON TRUE
WHERE d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND d.geo_id BETWEEN '04001' AND '04030'
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- 30 State House shells (seats=2)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT
  (SELECT id FROM essentials.elections WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ'),
  anchor.office_id, d.label, NULL, 2
FROM essentials.districts d
JOIN LATERAL (
  SELECT o.id AS office_id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE c.name = 'House of Representatives' AND o.district_id = d.id
  ORDER BY o.id LIMIT 1
) anchor ON TRUE
WHERE d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND d.geo_id BETWEEN '04001' AND '04030'
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- Post-verify: 30 Senate + 30 House shells, all House seats=2, zero NULL office_id.
DO $$
DECLARE
  v_gen      uuid;
  v_senate   int;
  v_house    int;
  v_bad_seat int;
  v_null_off int;
BEGIN
  SELECT id INTO v_gen FROM essentials.elections WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ';

  SELECT COUNT(*) INTO v_senate FROM essentials.races
  WHERE election_id = v_gen AND primary_party IS NULL AND position_name LIKE 'State Senate District %';
  IF v_senate <> 30 THEN RAISE EXCEPTION 'Migration 1374: Senate shells = % (expected 30)', v_senate; END IF;

  SELECT COUNT(*) INTO v_house FROM essentials.races
  WHERE election_id = v_gen AND primary_party IS NULL AND position_name LIKE 'State House District %';
  IF v_house <> 30 THEN RAISE EXCEPTION 'Migration 1374: House shells = % (expected 30)', v_house; END IF;

  SELECT COUNT(*) INTO v_bad_seat FROM essentials.races
  WHERE election_id = v_gen AND primary_party IS NULL AND position_name LIKE 'State House District %' AND seats <> 2;
  IF v_bad_seat <> 0 THEN RAISE EXCEPTION 'Migration 1374: % House shells with seats<>2', v_bad_seat; END IF;

  SELECT COUNT(*) INTO v_null_off FROM essentials.races
  WHERE election_id = v_gen AND primary_party IS NULL
    AND (position_name LIKE 'State Senate District %' OR position_name LIKE 'State House District %')
    AND office_id IS NULL;
  IF v_null_off <> 0 THEN RAISE EXCEPTION 'Migration 1374: % legislative shells with NULL office_id', v_null_off; END IF;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('1374') ON CONFLICT (version) DO NOTHING;
