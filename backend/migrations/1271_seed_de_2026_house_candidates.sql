-- 1271_seed_de_2026_house_candidates.sql
-- Phase 165-07: Earl Cooper (R) at -100048 — D-04 safe_start_seq=48 MANDATORY (seqs 1-47 = 26
--   unrelated legacy Wave-1 records; a lower seq would silently no-op-collide, Pitfall 6) +
--   McBride (-10000) renominated reuse. PROVISIONAL, cull >= 2026-09-15. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -100048, 'Earl Cooper', 'Earl', 'Cooper', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -100048);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Earl Cooper', 'Earl', 'Cooper', false, 'active', 'DE Dept of Elections 2026 candidate list (elections.delaware.gov genl_fcddt_2026; pre-primary qualified field, cull >= 2026-09-15)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'DE 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -100048
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sarah McBride', 'Sarah', 'McBride', true, 'active', 'DE Dept of Elections 2026 candidate list (elections.delaware.gov genl_fcddt_2026; pre-primary qualified field, cull >= 2026-09-15)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'DE 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -10000
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
