-- 1259_seed_ne_2026_house_candidates.sql
-- Phase 165-04: 7 new NE candidates (NE-1 Backemeyer -310101 / Sandman -310102; NE-2 OPEN field
--   Harding -310201 / Powell -310202 / Foreman -310203; NE-3 Stille -310360 / Else -310361, D-04
--   safe_start_seq=60) + Flood (-31001) and Smith (-31003) renominated reuse (is_incumbent=true).
--   NE-2 Bacon (0cc444a0, retired Jun-30-2025) gets NO row. EXCLUDED (not SoS-certified, petition
--   window to 2026-08-01 -> Phase 167): Ahlman (NE-1), Budke + Cohen (NE-3).
--   NOT EXISTS on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -310101, 'Chris Backemeyer', 'Chris', 'Backemeyer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -310101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -310102, 'Nik Sandman', 'Nik', 'Sandman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -310102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -310201, 'Brinker Harding', 'Brinker', 'Harding', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -310201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -310202, 'Denise Powell', 'Denise', 'Powell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -310202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -310203, 'Eric Foreman', 'Eric', 'Foreman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -310203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -310360, 'Becky Stille', 'Becky', 'Stille', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -310360);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -310361, 'David Else', 'David', 'Else', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -310361);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Backemeyer', 'Chris', 'Backemeyer', false, 'active', 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NE 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3101'
JOIN essentials.politicians p ON p.external_id = -310101
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nik Sandman', 'Nik', 'Sandman', false, 'active', 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NE 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3101'
JOIN essentials.politicians p ON p.external_id = -310102
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brinker Harding', 'Brinker', 'Harding', false, 'active', 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NE 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3102'
JOIN essentials.politicians p ON p.external_id = -310201
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Denise Powell', 'Denise', 'Powell', false, 'active', 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NE 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3102'
JOIN essentials.politicians p ON p.external_id = -310202
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eric Foreman', 'Eric', 'Foreman', false, 'active', 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NE 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3102'
JOIN essentials.politicians p ON p.external_id = -310203
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Becky Stille', 'Becky', 'Stille', false, 'active', 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NE 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3103'
JOIN essentials.politicians p ON p.external_id = -310360
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David Else', 'David', 'Else', false, 'active', 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NE 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3103'
JOIN essentials.politicians p ON p.external_id = -310361
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mike Flood', 'Mike', 'Flood', true, 'active', 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NE 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3101'
JOIN essentials.politicians p ON p.external_id = -31001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Adrian Smith', 'Adrian', 'Smith', true, 'active', 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NE 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3103'
JOIN essentials.politicians p ON p.external_id = -31003
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
