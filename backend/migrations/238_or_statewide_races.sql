-- Migration 238: OR 2026 Statewide Races — Phase 79 Plan 02
-- Creates 8 race rows for the OR 2026 General election (November 3, 2026):
--   Governor of Oregon (Kotek incumbent)
--   U.S. Senate Oregon (Merkley incumbent — D-05: Jeff Merkley included;
--     Ron Wyden is NOT included — Wyden's term ends 2027 and is not up for reelection in 2026)
--   U.S. House OR-01 through OR-06 (all 6 congressional districts)
-- All rows reference the OR 2026 General election via subquery.
-- Candidate rows left empty — discovery agent populates via cron (D-11).
-- primary_party = NULL per D-04 (antipartisan design + combined model).

WITH gen_elec AS (
  SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND state = 'OR'
)
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT gen_random_uuid(), gen_elec.id, t.office_id_val::uuid, t.position_name_val, NULL, 1
FROM gen_elec, (VALUES
  ('780f76cd-2ec0-42fc-bb67-74a8911ca1c8', 'Governor of Oregon'),
  ('3db3e08a-ed6c-4365-9e5a-9af1f94c4372', 'U.S. Senate Oregon'),
  ('617febb8-3b45-4787-87af-8b8ecc008b05', 'U.S. House OR-01'),
  ('41b9876c-304d-4268-a751-25ea7e2009cc', 'U.S. House OR-02'),
  ('62cb1965-8401-430c-8681-03a3e22e7c77', 'U.S. House OR-03'),
  ('94d89181-58c5-42b3-886f-4538131fd461', 'U.S. House OR-04'),
  ('1207f28b-6eea-4113-889c-3127292e29b9', 'U.S. House OR-05'),
  ('1e17d814-d999-4399-974c-3b36ec825ba7', 'U.S. House OR-06')
) AS t(office_id_val, position_name_val)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
