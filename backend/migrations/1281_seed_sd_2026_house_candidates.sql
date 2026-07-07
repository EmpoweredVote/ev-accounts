-- 1281_seed_sd_2026_house_candidates.sql
-- Phase 165-08: SD OPEN-seat field — Marty Jackley (REUSE v2.18 SD-AG pid 2537050a-cd40-460e-9751-1d982dd73c25,
--   race_candidates only) + Nikki Gronli NEW at -460001. Johnson (4ec42691) -> Governor, NO row.
--   Pittman EXCLUDED permanently (absent from the authoritative SD SoS list). DECIDED + FINAL.
--   NOT EXISTS guards. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -460001, 'Nikki Gronli', 'Nikki', 'Gronli', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -460001);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '2537050a-cd40-460e-9751-1d982dd73c25'::uuid, 'Marty Jackley', 'Marty', 'Jackley', false, 'active', 'SD SoS certified candidate list (vip.sdsos.gov eid=774; decided; field final)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'SD 2026 Statewide General'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = '2537050a-cd40-460e-9751-1d982dd73c25'::uuid);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nikki Gronli', 'Nikki', 'Gronli', false, 'active', 'SD SoS certified candidate list (vip.sdsos.gov eid=774; decided; field final)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'SD 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -460001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
