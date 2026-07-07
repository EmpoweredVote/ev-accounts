-- 1261_seed_wv_2026_house_candidates.sql
-- Phase 165-05: 5 new WV challengers (-540101/-540102 WV-1; -540201..-540203 WV-2, seq from 1,
--   band empty live) + Miller (-54001) and Moore (-54002) renominated reuse (is_incumbent=true).
--   DECIDED. NOT EXISTS on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -540101, 'Vince George', 'Vince', 'George', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -540101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -540102, 'Isaiah Rucker', 'Isaiah', 'Rucker', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -540102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -540201, 'Ace Parsi', 'Ace', 'Parsi', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -540201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -540202, 'Pat Carney', 'Pat', 'Carney', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -540202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -540203, 'Chris Whitcomb', 'Chris', 'Whitcomb', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -540203);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Vince George', 'Vince', 'George', false, 'active', 'WV 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_West_Virginia; independent window to 2026-08-03 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WV 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '5401'
JOIN essentials.politicians p ON p.external_id = -540101
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Isaiah Rucker', 'Isaiah', 'Rucker', false, 'active', 'WV 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_West_Virginia; independent window to 2026-08-03 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WV 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '5401'
JOIN essentials.politicians p ON p.external_id = -540102
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ace Parsi', 'Ace', 'Parsi', false, 'active', 'WV 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_West_Virginia; independent window to 2026-08-03 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WV 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '5402'
JOIN essentials.politicians p ON p.external_id = -540201
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Pat Carney', 'Pat', 'Carney', false, 'active', 'WV 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_West_Virginia; independent window to 2026-08-03 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WV 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '5402'
JOIN essentials.politicians p ON p.external_id = -540202
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Whitcomb', 'Chris', 'Whitcomb', false, 'active', 'WV 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_West_Virginia; independent window to 2026-08-03 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WV 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '5402'
JOIN essentials.politicians p ON p.external_id = -540203
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Carol D. Miller', 'Carol', 'D. Miller', true, 'active', 'WV 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_West_Virginia; independent window to 2026-08-03 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WV 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '5401'
JOIN essentials.politicians p ON p.external_id = -54001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Riley M. Moore', 'Riley', 'M. Moore', true, 'active', 'WV 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_West_Virginia; independent window to 2026-08-03 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WV 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '5402'
JOIN essentials.politicians p ON p.external_id = -54002
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
