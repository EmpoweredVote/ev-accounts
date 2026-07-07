-- 1277_seed_mt_2026_house_candidates.sql
-- Phase 165-08: MT-1 OPEN all-new field (Flint -300101, Forstag -300102, Sheedy -300103; Zinke
--   eb9fac1d NO row) + MT-2 Miller -300285 / McCracken -300286 (D-04 safe_start_seq=85) +
--   Downing (-30002) renominated reuse. DECIDED. EXCLUDED pending-independents (cert to
--   2026-08-20 -> 167): Persico, Eisenhauer. NOT EXISTS guards; sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -300101, 'Aaron Flint', 'Aaron', 'Flint', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -300101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -300102, 'Sam Forstag', 'Sam', 'Forstag', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -300102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -300103, 'Nick Sheedy', 'Nick', 'Sheedy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -300103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -300285, 'Brian Miller', 'Brian', 'Miller', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -300285);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -300286, 'Patrick McCracken', 'Patrick', 'McCracken', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -300286);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Aaron Flint', 'Aaron', 'Flint', false, 'active', 'MT candidate filing (candidatefiling.mt.gov e=450002928; decided Jun-2 primary; independent cert window to 2026-08-20 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'MT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3001'
JOIN essentials.politicians p ON p.external_id = -300101
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sam Forstag', 'Sam', 'Forstag', false, 'active', 'MT candidate filing (candidatefiling.mt.gov e=450002928; decided Jun-2 primary; independent cert window to 2026-08-20 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'MT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3001'
JOIN essentials.politicians p ON p.external_id = -300102
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nick Sheedy', 'Nick', 'Sheedy', false, 'active', 'MT candidate filing (candidatefiling.mt.gov e=450002928; decided Jun-2 primary; independent cert window to 2026-08-20 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'MT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3001'
JOIN essentials.politicians p ON p.external_id = -300103
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brian Miller', 'Brian', 'Miller', false, 'active', 'MT candidate filing (candidatefiling.mt.gov e=450002928; decided Jun-2 primary; independent cert window to 2026-08-20 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'MT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3002'
JOIN essentials.politicians p ON p.external_id = -300285
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Patrick McCracken', 'Patrick', 'McCracken', false, 'active', 'MT candidate filing (candidatefiling.mt.gov e=450002928; decided Jun-2 primary; independent cert window to 2026-08-20 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'MT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3002'
JOIN essentials.politicians p ON p.external_id = -300286
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Troy Downing', 'Troy', 'Downing', true, 'active', 'MT candidate filing (candidatefiling.mt.gov e=450002928; decided Jun-2 primary; independent cert window to 2026-08-20 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'MT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3002'
JOIN essentials.politicians p ON p.external_id = -30002
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
