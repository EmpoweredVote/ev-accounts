-- 1257_seed_nm_2026_house_candidates.sql
-- Phase 165-04: 3 new NM R challengers (Okpareke -350126, Cunningham -350251, Zamora -350382 —
--   D-04 safe_start_seq 26/51/82) + 3 renominated incumbents reused by external_id
--   (-35001..-35003, is_incumbent=true). DECIDED. NOT EXISTS on (race_id, politician_id);
--   sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -350126, 'Didi Okpareke', 'Didi', 'Okpareke', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -350126);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -350251, 'Greg Cunningham', 'Greg', 'Cunningham', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -350251);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -350382, 'Martin Zamora', 'Martin', 'Zamora', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -350382);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Didi Okpareke', 'Didi', 'Okpareke', false, 'active', 'NM SoS candidate portal (candidateportal.servis.sos.state.nm.us, eid=2917; decided general field)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NM 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3501'
JOIN essentials.politicians p ON p.external_id = -350126
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Greg Cunningham', 'Greg', 'Cunningham', false, 'active', 'NM SoS candidate portal (candidateportal.servis.sos.state.nm.us, eid=2917; decided general field)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NM 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3502'
JOIN essentials.politicians p ON p.external_id = -350251
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Martin Zamora', 'Martin', 'Zamora', false, 'active', 'NM SoS candidate portal (candidateportal.servis.sos.state.nm.us, eid=2917; decided general field)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NM 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3503'
JOIN essentials.politicians p ON p.external_id = -350382
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Melanie A. Stansbury', 'Melanie', 'A. Stansbury', true, 'active', 'NM SoS candidate portal (candidateportal.servis.sos.state.nm.us, eid=2917; decided general field)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NM 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3501'
JOIN essentials.politicians p ON p.external_id = -35001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gabe Vasquez', 'Gabe', 'Vasquez', true, 'active', 'NM SoS candidate portal (candidateportal.servis.sos.state.nm.us, eid=2917; decided general field)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NM 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3502'
JOIN essentials.politicians p ON p.external_id = -35002
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Teresa Leger Fernandez', 'Teresa', 'Leger Fernandez', true, 'active', 'NM SoS candidate portal (candidateportal.servis.sos.state.nm.us, eid=2917; decided general field)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NM 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3503'
JOIN essentials.politicians p ON p.external_id = -35003
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
