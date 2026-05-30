-- =============================================================================
-- Migration 187: Longview TX District 3 City Council Runoff — June 13, 2026
--
-- Context: Wray Wade's term expired May 2026. No candidate won outright in the
-- May 2026 election, triggering a runoff between Brandon Smith and Marlena Cooper.
-- Wade is serving in a hold-over capacity until the runoff winner is seated.
--
-- After the June 13 result is certified, a follow-up migration will:
--   1. Close Wray Wade's politician record (is_active = false)
--   2. Insert the winner as a new politician on the District 3 office
--   3. Mark the winning race_candidate with candidate_status = 'elected'
--
-- Sources:
--   https://www.longviewtexas.gov/3308/City-Election-Results
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id UUID;
  v_race_id     UUID;
  v_office_id   UUID := 'b3085207-009b-4e57-9d58-d820dcde3e61';
BEGIN

  INSERT INTO essentials.elections (
    name, election_date, election_type, jurisdiction_level, state, description
  ) VALUES (
    'Longview TX City Council District 3 Runoff 2026',
    '2026-06-13',
    'special',
    'city',
    'TX',
    'Runoff election for Longview City Council District 3. Wray Wade did not seek re-election; no candidate achieved a majority in the May 2026 general election.'
  ) RETURNING id INTO v_election_id;

  INSERT INTO essentials.races (
    election_id, office_id, position_name, seats, primary_party
  ) VALUES (
    v_election_id,
    v_office_id,
    'Council Member District 3',
    1,
    NULL
  ) RETURNING id INTO v_race_id;

  INSERT INTO essentials.race_candidates (
    race_id, full_name, first_name, last_name,
    is_incumbent, candidate_status, source
  ) VALUES
    (v_race_id, 'Brandon Smith',  'Brandon', 'Smith',  false, 'active', 'longviewtexas.gov'),
    (v_race_id, 'Marlena Cooper', 'Marlena', 'Cooper', false, 'active', 'longviewtexas.gov');

  RAISE NOTICE 'Inserted: Longview D3 Runoff election % / race % — Brandon Smith, Marlena Cooper',
    v_election_id, v_race_id;

END $$;

COMMIT;
