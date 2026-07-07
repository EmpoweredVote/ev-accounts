-- 1263_seed_id_2026_house_candidates.sql
-- Phase 165-05: 8 new ID challengers (multi-party: D/Constitution/Libertarian/Independent;
--   -160101..-160103 ID-1, -160201..-160205 ID-2, seq from 1, band empty live) + Fulcher (-16001)
--   and Simpson (-16002) renominated reuse (is_incumbent=true). DECIDED.
--   NOT EXISTS on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -160101, 'Kaylee Peterson', 'Kaylee', 'Peterson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -160101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -160102, 'Brendan Gomez', 'Brendan', 'Gomez', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -160102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -160103, 'Sarah Zabel', 'Sarah', 'Zabel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -160103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -160201, 'Elinor Gilbreath', 'Elinor', 'Gilbreath', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -160201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -160202, 'Will Johanson', 'Will', 'Johanson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -160202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -160203, 'Carta Sierra', 'Carta', 'Sierra', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -160203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -160204, 'Emre Houser', 'Emre', 'Houser', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -160204);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -160205, 'Tripp Hutchinson', 'Tripp', 'Hutchinson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -160205);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kaylee Peterson', 'Kaylee', 'Peterson', false, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1601'
JOIN essentials.politicians p ON p.external_id = -160101
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brendan Gomez', 'Brendan', 'Gomez', false, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1601'
JOIN essentials.politicians p ON p.external_id = -160102
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sarah Zabel', 'Sarah', 'Zabel', false, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1601'
JOIN essentials.politicians p ON p.external_id = -160103
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Elinor Gilbreath', 'Elinor', 'Gilbreath', false, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1602'
JOIN essentials.politicians p ON p.external_id = -160201
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Will Johanson', 'Will', 'Johanson', false, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1602'
JOIN essentials.politicians p ON p.external_id = -160202
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Carta Sierra', 'Carta', 'Sierra', false, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1602'
JOIN essentials.politicians p ON p.external_id = -160203
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Emre Houser', 'Emre', 'Houser', false, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1602'
JOIN essentials.politicians p ON p.external_id = -160204
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tripp Hutchinson', 'Tripp', 'Hutchinson', false, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1602'
JOIN essentials.politicians p ON p.external_id = -160205
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Russ Fulcher', 'Russ', 'Fulcher', true, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1601'
JOIN essentials.politicians p ON p.external_id = -16001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael K. Simpson', 'Michael', 'K. Simpson', true, 'active', 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'ID 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1602'
JOIN essentials.politicians p ON p.external_id = -16002
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
