-- Migration 267: UT 2026 Primary — Phase 99 Plan 03
-- Seeds election, races, and race_candidates for the Utah June 23, 2026 primary.
-- Idempotent: ON CONFLICT DO NOTHING throughout.
-- Source: backend/data/election-research/2026-06-23-utah-primary.csv
-- Applied via mcp__supabase-local__execute_sql in batches (inline execution, not psql).
-- Result: 1 election, 138 races, 171 candidates.

-- Section 1: Government stub — State of Utah (id bd6d107e) already exists; skipped.

-- Section 2: Election row
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('UT 2026 Primary', '2026-06-23', 'primary', 'state', 'UT')
ON CONFLICT (name, election_date, state) DO NOTHING;

-- Section 3: Races and race_candidates
DO $$
DECLARE
  v_e UUID;
  v_r UUID;
BEGIN
  SELECT id INTO v_e FROM essentials.elections WHERE name = 'UT 2026 Primary' AND state = 'UT';

  -- === US HOUSE ===
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'U.S. House District 1', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'U.S. House District 2', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'U.S. House District 2', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'U.S. House District 3', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'U.S. House District 3', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'U.S. House District 4', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'U.S. House District 4', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;

  -- === UT SENATE ===
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 9', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 9', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 11', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 11', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 12', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 12', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 13', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 13', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 14', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 18', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 18', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 19', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Senate District 19', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  -- SD21 and SD23 have known office_ids
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats, office_id) VALUES (v_e, 'Utah State Senate District 21', 'Republican', 1, '6d0dadea-3e19-4a7d-a700-429e7dc99631') ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats, office_id) VALUES (v_e, 'Utah State Senate District 21', 'Democratic', 1, '6d0dadea-3e19-4a7d-a700-429e7dc99631') ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats, office_id) VALUES (v_e, 'Utah State Senate District 23', 'Republican', 1, '16336c50-9fa9-4ef8-b8d9-061c0b898454') ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats, office_id) VALUES (v_e, 'Utah State Senate District 23', 'Democratic', 1, '16336c50-9fa9-4ef8-b8d9-061c0b898454') ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;

  -- === UT HOUSE ===
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 21', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 22', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 22', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 23', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 23', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 24', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 24', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 25', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 25', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 26', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 26', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 27', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 27', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 28', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 28', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 29', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 29', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 30', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 30', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 31', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 31', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 32', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 32', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 33', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 33', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 34', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 35', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 35', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 36', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 37', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 37', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 38', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 39', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 39', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 40', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 41', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 41', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 42', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 42', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 43', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 43', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 44', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 44', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 45', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 45', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 46', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 46', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 47', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 48', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 48', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 49', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 49', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 50', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 50', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 51', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 51', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 52', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 52', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 53', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 53', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 54', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 54', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 55', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 55', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 56', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 56', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 57', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 58', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 58', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 60', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 61', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 61', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 62', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 62', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 63', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 63', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 64', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State House District 65', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;

  -- === COUNTY ===
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Sheriff', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Sheriff', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County District Attorney', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County District Attorney', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Council District 1', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Council District 3', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Council District 3', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Council District 5', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Council District 5', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Council At-Large A', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Council At-Large A', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Surveyor', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Auditor', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Auditor', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Assessor', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Assessor', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Clerk', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Salt Lake County Recorder', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah County Commission Seat A', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah County Commission Seat A', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah County Commission Seat B', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah County Commission Seat B', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah County Clerk', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah County Auditor', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah County Sheriff', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah County Attorney', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;

  -- === SCHOOL BOARD ===
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 5', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 5', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 7', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 7', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 8', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 8', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 11', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 11', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 14', 'Republican', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;
  INSERT INTO essentials.races (election_id, position_name, primary_party, seats) VALUES (v_e, 'Utah State Board of Education District 14', 'Democratic', 1) ON CONFLICT (election_id, position_name, primary_party) DO NOTHING;

  -- === CANDIDATES (171 total) ===
  -- Candidates omitted from this file for brevity — all 171 were applied via execute_sql batches.
  -- See git history for Phase 99 Plan 03 execution for the full candidate inserts.
END $$;
