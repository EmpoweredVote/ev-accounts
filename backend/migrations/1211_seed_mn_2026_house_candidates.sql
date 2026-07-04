-- 1211_seed_mn_2026_house_candidates.sql
-- Phase 162-05 Task 2: 35 new MN politicians + 42 active race_candidates
--   onto the 8 MN 2026 Statewide General races. Reuse 7 renominated incumbents by external_id;
--   MN-2 Angie Craig (-27002) ran for US Senate -> NO active row (open-seat convention, mirrors
--   AZ-1/AZ-5). ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p162.csv MN rows, from candidates.sos.mn.gov 2026 federal filings.
BEGIN;

-- 35 new challenger/open-seat/indep records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270101, 'Gregory A. Goetzman', 'Gregory', 'A. Goetzman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270102, 'Oliver R. Morlan', 'Oliver', 'R. Morlan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270103, 'Alex Eaton', 'Alex', 'Eaton', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270104, 'Jake Johnson', 'Jake', 'Johnson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270201, 'Eric Pratt', 'Eric', 'Pratt', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270202, 'Abdi Abdulle', 'Abdi', 'Abdulle', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270203, 'Kaela Berg', 'Kaela', 'Berg', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270204, 'Matthew D. Klein', 'Matthew', 'D. Klein', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270204);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270205, 'Matt Little', 'Matt', 'Little', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270205);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270206, 'Hugh McTavish', 'Hugh', 'McTavish', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270206);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270207, 'Christopher Mosel', 'Christopher', 'Mosel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270207);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270301, 'Tyler Bass', 'Tyler', 'Bass', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270302, 'Quentin Wittrock', 'Quentin', 'Wittrock', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270401, 'Gene Rechtzigel', 'Gene', 'Rechtzigel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270402, 'Paul Wikstrom', 'Paul', 'Wikstrom', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270403, 'Paul Xiong', 'Paul', 'Xiong', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270404, 'Aswar Rahman', 'Aswar', 'Rahman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270501, 'DeVelle L. Jackson', 'DeVelle', 'L. Jackson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270502, 'Dalia Al-Aqidi', 'Dalia', 'Al-Aqidi', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270503, 'John Nagel', 'John', 'Nagel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270504, 'Angie Windhauser', 'Angie', 'Windhauser', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270504);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270505, 'Abbey Zieska', 'Abbey', 'Zieska', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270505);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270506, 'Julie Trang Le', 'Julie', 'Trang Le', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270506);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270507, 'Abena A. McKenzie', 'Abena', 'A. McKenzie', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270507);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270508, 'Latonya T. Reeves', 'Latonya', 'T. Reeves', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270508);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270509, 'Nate Schluter', 'Nate', 'Schluter', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270509);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270601, 'Chris Corey', 'Chris', 'Corey', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270602, 'Mike Foley', 'Mike', 'Foley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270603, 'Doug Chapin', 'Doug', 'Chapin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270701, 'Steve Carlson', 'Steve', 'Carlson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270702, 'Erik Osberg', 'Erik', 'Osberg', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270702);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270801, 'Anthony Hamilton', 'Anthony', 'Hamilton', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270802, 'Luke Gulbranson', 'Luke', 'Gulbranson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270802);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270803, 'John Munter', 'John', 'Munter', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270803);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -270804, 'Trina Swanson', 'Trina', 'Swanson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -270804);

-- 42 active race_candidates (7 incumbents reused + 35 new; Craig excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brad Finstad', 'Brad', 'Finstad', true, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -27001
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2701'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brad Finstad'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gregory A. Goetzman', 'Gregory', 'A. Goetzman', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270101
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2701'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gregory A. Goetzman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Oliver R. Morlan', 'Oliver', 'R. Morlan', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270102
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2701'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Oliver R. Morlan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Alex Eaton', 'Alex', 'Eaton', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270103
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2701'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Alex Eaton'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jake Johnson', 'Jake', 'Johnson', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270104
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2701'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jake Johnson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eric Pratt', 'Eric', 'Pratt', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270201
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2702'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Eric Pratt'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Abdi Abdulle', 'Abdi', 'Abdulle', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270202
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2702'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Abdi Abdulle'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kaela Berg', 'Kaela', 'Berg', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270203
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2702'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kaela Berg'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matthew D. Klein', 'Matthew', 'D. Klein', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270204
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2702'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matthew D. Klein'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matt Little', 'Matt', 'Little', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270205
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2702'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matt Little'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Hugh McTavish', 'Hugh', 'McTavish', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270206
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2702'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Hugh McTavish'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christopher Mosel', 'Christopher', 'Mosel', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270207
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2702'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christopher Mosel'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kelly Morrison', 'Kelly', 'Morrison', true, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -27003
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2703'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kelly Morrison'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tyler Bass', 'Tyler', 'Bass', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270301
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2703'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tyler Bass'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Quentin Wittrock', 'Quentin', 'Wittrock', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270302
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2703'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Quentin Wittrock'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Betty McCollum', 'Betty', 'McCollum', true, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -27004
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2704'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Betty McCollum'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gene Rechtzigel', 'Gene', 'Rechtzigel', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270401
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2704'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gene Rechtzigel'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Paul Wikstrom', 'Paul', 'Wikstrom', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270402
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2704'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Paul Wikstrom'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Paul Xiong', 'Paul', 'Xiong', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270403
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2704'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Paul Xiong'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Aswar Rahman', 'Aswar', 'Rahman', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270404
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2704'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Aswar Rahman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ilhan Omar', 'Ilhan', 'Omar', true, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -27005
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ilhan Omar'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'DeVelle L. Jackson', 'DeVelle', 'L. Jackson', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, independent/minor-party filing); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270501
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('DeVelle L. Jackson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dalia Al-Aqidi', 'Dalia', 'Al-Aqidi', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270502
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dalia Al-Aqidi'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Nagel', 'John', 'Nagel', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270503
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Nagel'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Angie Windhauser', 'Angie', 'Windhauser', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270504
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Angie Windhauser'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Abbey Zieska', 'Abbey', 'Zieska', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270505
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Abbey Zieska'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Julie Trang Le', 'Julie', 'Trang Le', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270506
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Julie Trang Le'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Abena A. McKenzie', 'Abena', 'A. McKenzie', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270507
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Abena A. McKenzie'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Latonya T. Reeves', 'Latonya', 'T. Reeves', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270508
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Latonya T. Reeves'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nate Schluter', 'Nate', 'Schluter', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270509
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2705'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Nate Schluter'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tom Emmer', 'Tom', 'Emmer', true, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -27006
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2706'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tom Emmer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Corey', 'Chris', 'Corey', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270601
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2706'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris Corey'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mike Foley', 'Mike', 'Foley', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270602
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2706'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mike Foley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Doug Chapin', 'Doug', 'Chapin', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270603
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2706'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Doug Chapin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michelle Fischbach', 'Michelle', 'Fischbach', true, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -27007
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2707'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michelle Fischbach'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Steve Carlson', 'Steve', 'Carlson', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270701
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2707'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Steve Carlson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Erik Osberg', 'Erik', 'Osberg', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270702
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2707'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Erik Osberg'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Pete Stauber', 'Pete', 'Stauber', true, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -27008
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2708'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Pete Stauber'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Anthony Hamilton', 'Anthony', 'Hamilton', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270801
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2708'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Anthony Hamilton'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Luke Gulbranson', 'Luke', 'Gulbranson', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270802
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2708'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Luke Gulbranson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Munter', 'John', 'Munter', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270803
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2708'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Munter'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Trina Swanson', 'Trina', 'Swanson', false, 'active', 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -270804
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = '2708'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Trina Swanson'));

COMMIT;
