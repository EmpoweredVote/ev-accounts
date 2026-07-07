-- 1279_seed_nd_2026_house_candidates.sql
-- Phase 165-08: Trygve Hammer (D-NPL) NEW at -380001 (band empty live) + Fedorchak (-38000)
--   renominated reuse. DECIDED. EXCLUDED pending-independents (window to 2026-08-31 -> 167):
--   Neville, Tuttle. NOT EXISTS guards. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -380001, 'Trygve Hammer', 'Trygve', 'Hammer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -380001);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Trygve Hammer', 'Trygve', 'Hammer', false, 'active', 'ND SoS certified candidate list (vip.sos.nd.gov eid=346; decided Jun-9 primary; petition window to 2026-08-31 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ND 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -380001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Julie Fedorchak', 'Julie', 'Fedorchak', true, 'active', 'ND SoS certified candidate list (vip.sos.nd.gov eid=346; decided Jun-9 primary; petition window to 2026-08-31 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ND 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -38000
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
