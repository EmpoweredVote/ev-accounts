-- 1269_seed_ri_2026_house_candidates.sql
-- Phase 165-07: 4 new RI challengers (-440101/-440102 RI-1; -440201/-440202 RI-2, band empty live)
--   + Amo (-44001) and Magaziner (-44002) renominated reuse. PROVISIONAL, cull >= 2026-09-09.
--   NOT EXISTS on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -440101, 'Kellie Keenan', 'Kellie', 'Keenan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -440101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -440102, 'Pedro DeSouza', 'Pedro', 'DeSouza', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -440102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -440201, 'Victor Mellor', 'Victor', 'Mellor', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -440201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -440202, 'Stephen Skoly', 'Stephen', 'Skoly', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -440202);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kellie Keenan', 'Kellie', 'Keenan', false, 'active', 'RI 2026 general field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Rhode_Island; pre-primary qualified field, cull >= 2026-09-09)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'RI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4401'
JOIN essentials.politicians p ON p.external_id = -440101
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Pedro DeSouza', 'Pedro', 'DeSouza', false, 'active', 'RI 2026 general field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Rhode_Island; pre-primary qualified field, cull >= 2026-09-09)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'RI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4401'
JOIN essentials.politicians p ON p.external_id = -440102
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Victor Mellor', 'Victor', 'Mellor', false, 'active', 'RI 2026 general field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Rhode_Island; pre-primary qualified field, cull >= 2026-09-09)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'RI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4402'
JOIN essentials.politicians p ON p.external_id = -440201
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Stephen Skoly', 'Stephen', 'Skoly', false, 'active', 'RI 2026 general field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Rhode_Island; pre-primary qualified field, cull >= 2026-09-09)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'RI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4402'
JOIN essentials.politicians p ON p.external_id = -440202
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gabe Amo', 'Gabe', 'Amo', true, 'active', 'RI 2026 general field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Rhode_Island; pre-primary qualified field, cull >= 2026-09-09)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'RI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4401'
JOIN essentials.politicians p ON p.external_id = -44001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Seth Magaziner', 'Seth', 'Magaziner', true, 'active', 'RI 2026 general field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Rhode_Island; pre-primary qualified field, cull >= 2026-09-09)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'RI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4402'
JOIN essentials.politicians p ON p.external_id = -44002
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
