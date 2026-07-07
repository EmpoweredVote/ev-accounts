-- 1265_seed_hi_2026_house_candidates.sql
-- Phase 165-06: 13 new HI candidates (In-Primary qualified field ONLY; -150101..-150107 HI-1,
--   -150201..-150206 HI-2, seq from 1, band empty live) + Case (-15001) and Tokuda (-15002)
--   renominated reuse on their crowded primaries (is_incumbent=true). PROVISIONAL, cull >=
--   2026-08-08. EXCLUDED status='Issued' non-filers: Belatti, Burd, Cuadra, Frazier, Gisa,
--   Curtis, Lucas-Tadeo, Martin. NOT EXISTS on (race_id, politician_id); sqlStr()-escaped.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150101, 'Jennifer Booker', 'Jennifer', 'Booker', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150102, 'Ben Fatula', 'Ben', 'Fatula', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150103, 'Jarrett Keohokalole', 'Jarrett', 'Keohokalole', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150104, 'Nicholas Kiswanto', 'Nicholas', 'Kiswanto', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150105, 'Nathan Berning', 'Nathan', 'Berning', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150106, 'Jordan Conley', 'Jordan', 'Conley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150106);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150107, 'Adriel Lam', 'Adriel', 'Lam', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150107);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150201, 'Kirill Basin', 'Kirill', 'Basin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150202, 'Greg Guithues', 'Greg', 'Guithues', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150203, 'Steven King', 'Steven', 'King', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150204, 'Brenton Awa', 'Brenton', 'Awa', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150204);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150205, 'Edward Codelia', 'Edward', 'Codelia', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150205);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -150206, 'Randall Terry', 'Randall', 'Terry', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -150206);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jennifer Booker', 'Jennifer', 'Booker', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1501'
JOIN essentials.politicians p ON p.external_id = -150101
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ben Fatula', 'Ben', 'Fatula', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1501'
JOIN essentials.politicians p ON p.external_id = -150102
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jarrett Keohokalole', 'Jarrett', 'Keohokalole', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1501'
JOIN essentials.politicians p ON p.external_id = -150103
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nicholas Kiswanto', 'Nicholas', 'Kiswanto', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1501'
JOIN essentials.politicians p ON p.external_id = -150104
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nathan Berning', 'Nathan', 'Berning', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1501'
JOIN essentials.politicians p ON p.external_id = -150105
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jordan Conley', 'Jordan', 'Conley', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1501'
JOIN essentials.politicians p ON p.external_id = -150106
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Adriel Lam', 'Adriel', 'Lam', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1501'
JOIN essentials.politicians p ON p.external_id = -150107
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kirill Basin', 'Kirill', 'Basin', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1502'
JOIN essentials.politicians p ON p.external_id = -150201
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Greg Guithues', 'Greg', 'Guithues', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1502'
JOIN essentials.politicians p ON p.external_id = -150202
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Steven King', 'Steven', 'King', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1502'
JOIN essentials.politicians p ON p.external_id = -150203
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brenton Awa', 'Brenton', 'Awa', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1502'
JOIN essentials.politicians p ON p.external_id = -150204
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Edward Codelia', 'Edward', 'Codelia', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1502'
JOIN essentials.politicians p ON p.external_id = -150205
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Randall Terry', 'Randall', 'Terry', false, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1502'
JOIN essentials.politicians p ON p.external_id = -150206
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ed Case', 'Ed', 'Case', true, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1501'
JOIN essentials.politicians p ON p.external_id = -15001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jill N. Tokuda', 'Jill', 'N. Tokuda', true, 'active', 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'HI 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '1502'
JOIN essentials.politicians p ON p.external_id = -15002
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
