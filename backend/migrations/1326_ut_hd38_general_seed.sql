-- =====================================================================================
-- Seed: HD-38 general race on the 2026 Utah General — the open-seat matchup the
-- primary-only UT model couldn't represent (companion to mig 1325's UFP seed).
--
-- WHY: HD-38's only primary race was Republican (McConnehey beat Vindas 60.6-39.4,
--   Vindas culled in mig 1323). The general is McConnehey (R) vs Sergio Sotelo
--   (Unaffiliated) — Sotelo, like the third-party field, never appears in a party
--   primary, so he was unseeded. Flagged in
--   `.planning/todos/2026-07-09-ut-primary-losers-cull.md`; same independent-
--   candidate evidence-parity rule as mig 1325.
--
-- EVIDENCE: Ballotpedia "Utah House of Representatives District 38" fetched
--   2026-07-12 via /wiki/api.php parse: "Chris McConnehey (R) and Sergio Sotelo
--   (Unaffiliated) ... There are no incumbents in this race." Matches the
--   2026-07-09 agent pass. 'Unaffiliated' is Utah's official ballot designation
--   (kept over the NE seed's 'Independent' label). ~Sept-Oct voteinfo.utah.gov
--   pamphlet re-check re-verifies officially.
--
-- MODEL: identical to mig 1325 — general race with primary_party='' on the
--   "2026 Utah General" election (created by 1325), district office_id kept for
--   geofencing; R winner copied from the primary race's active row; Sotelo created
--   (data_source='ballotpedia', external_id NULL per UT-challenger convention).
--
-- AUDIT-ONLY / unregistered (no schema_migrations ledger entry). Idempotent.
-- =====================================================================================

BEGIN;

-- 1. General race (election must exist from mig 1325)
INSERT INTO essentials.races (position_name, primary_party, election_id, office_id, seats)
SELECT DISTINCT pr.position_name, '', ge.id, pr.office_id, 1
FROM essentials.races pr
JOIN essentials.elections pe ON pe.id = pr.election_id AND pe.name = '2026 Utah Primary'
JOIN essentials.elections ge ON ge.name = '2026 Utah General'
WHERE pr.position_name = 'Utah State House District 38'
AND NOT EXISTS (
  SELECT 1 FROM essentials.races g
  WHERE g.election_id = ge.id AND g.position_name = pr.position_name);

-- 2. Sergio Sotelo (Unaffiliated)
INSERT INTO essentials.politicians (full_name, first_name, last_name, party, is_active, is_incumbent, data_source)
SELECT 'Sergio Sotelo', 'Sergio', 'Sotelo', 'Unaffiliated', true, false, 'ballotpedia'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p
  WHERE p.full_name = 'Sergio Sotelo' AND p.data_source = 'ballotpedia');

-- 3a. Copy the primary's active candidate (McConnehey) into the general
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, candidate_status, is_incumbent, source)
SELECT g.id, rc.politician_id, rc.full_name, rc.first_name, rc.last_name, 'active', rc.is_incumbent, 'ballotpedia'
FROM essentials.races pr
JOIN essentials.elections pe ON pe.id = pr.election_id AND pe.name = '2026 Utah Primary'
JOIN essentials.race_candidates rc ON rc.race_id = pr.id AND rc.candidate_status = 'active'
JOIN essentials.elections ge ON ge.name = '2026 Utah General'
JOIN essentials.races g ON g.election_id = ge.id AND g.position_name = pr.position_name
WHERE pr.position_name = 'Utah State House District 38'
AND NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates x
  WHERE x.race_id = g.id AND x.politician_id = rc.politician_id);

-- 3b. Sotelo into the general
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, candidate_status, is_incumbent, source)
SELECT g.id, p.id, p.full_name, p.first_name, p.last_name, 'active', false, 'ballotpedia'
FROM essentials.elections ge
JOIN essentials.races g ON g.election_id = ge.id AND g.position_name = 'Utah State House District 38'
JOIN essentials.politicians p ON p.full_name = 'Sergio Sotelo' AND p.data_source = 'ballotpedia'
WHERE ge.name = '2026 Utah General'
AND NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates x
  WHERE x.race_id = g.id AND x.politician_id = p.id);

COMMIT;
