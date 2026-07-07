-- 1221_seed_wi_2026_house_candidates.sql
-- Phase 163-02 Task 2: 28 new WI politicians + 35 active race_candidates
--   onto the 8 WI 2026 Statewide General races. Reuse 7 renominated incumbents by external_id;
--   WI-7 Thomas P. Tiffany (-55007) ran for Governor -> NO active row (open-seat convention, mirrors
--   AZ-1/AZ-5, MN-2 Craig). ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p163.csv WI rows, from Wikipedia 2026 US House elections in Wisconsin
--   + local news (postcrescent.com, wxow.com). WI-2 legitimately has only 2 all-D candidates
--   (Pocan + Alexander) -- no Republican filed, verified, not an error.
BEGIN;

-- 28 new challenger/open-seat/indep records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550101, 'Miguel Aranda', 'Miguel', 'Aranda', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550102, 'Mitchell Berman', 'Mitchell', 'Berman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550103, 'Peter Burgelis', 'Peter', 'Burgelis', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550104, 'Lorenzo Santos', 'Lorenzo', 'Santos', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550201, 'Douglas Alexander', 'Douglas', 'Alexander', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550301, 'Emily Berge', 'Emily', 'Berge', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550302, 'Rebecca Cooke', 'Rebecca', 'Cooke', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550303, 'Rustin Provance', 'Rustin', 'Provance', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550303);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550401, 'Amy Donahue', 'Amy', 'Donahue', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550402, 'Purnima Nath', 'Purnima', 'Nath', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550403, 'Tim Rogers', 'Tim', 'Rogers', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550404, 'Arthur Burks', 'Arthur', 'Burks', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550501, 'Andrew Beck', 'Andrew', 'Beck', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550601, 'Amanda Bell', 'Amanda', 'Bell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550602, 'Brad Smith', 'Brad', 'Smith', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550603, 'Matthew Arndt', 'Matthew', 'Arndt', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550604, 'Elizabeth Fitzgibbon', 'Elizabeth', 'Fitzgibbon', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550604);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550605, 'Michael Thurow', 'Michael', 'Thurow', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550605);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550701, 'Michael Alfonso', 'Michael', 'Alfonso', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550702, 'Niina Baum', 'Niina', 'Baum', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550702);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550703, 'Jessi Ebben', 'Jessi', 'Ebben', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550703);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550704, 'Kevin Hermening', 'Kevin', 'Hermening', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550704);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550705, 'Chris Armstrong', 'Chris', 'Armstrong', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550705);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550706, 'Fred Clark', 'Fred', 'Clark', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550706);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550707, 'Ginger Murray', 'Ginger', 'Murray', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550707);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550801, 'Rick Crosson', 'Rick', 'Crosson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550802, 'Katrina deVille', 'Katrina', 'deVille', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550802);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550803, 'Mark Scheffler', 'Mark', 'Scheffler', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550803);

-- 35 active race_candidates (7 incumbents reused + 28 new; Tiffany excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bryan Steil', 'Bryan', 'Steil', true, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -55001
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bryan Steil'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Miguel Aranda', 'Miguel', 'Aranda', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550101
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Miguel Aranda'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mitchell Berman', 'Mitchell', 'Berman', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550102
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mitchell Berman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Peter Burgelis', 'Peter', 'Burgelis', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550103
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Peter Burgelis'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lorenzo Santos', 'Lorenzo', 'Santos', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550104
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lorenzo Santos'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mark Pocan', 'Mark', 'Pocan', true, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -55002
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5502'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mark Pocan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Douglas Alexander', 'Douglas', 'Alexander', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550201
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5502'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Douglas Alexander'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Derrick Van Orden', 'Derrick', 'Van Orden', true, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -55003
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Derrick Van Orden'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Emily Berge', 'Emily', 'Berge', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550301
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Emily Berge'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rebecca Cooke', 'Rebecca', 'Cooke', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550302
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rebecca Cooke'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rustin Provance', 'Rustin', 'Provance', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia/local news (postcrescent.com, wxow.com) independent/minor-party filing; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550303
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rustin Provance'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gwen Moore', 'Gwen', 'Moore', true, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -55004
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gwen Moore'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Amy Donahue', 'Amy', 'Donahue', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550401
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Amy Donahue'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Purnima Nath', 'Purnima', 'Nath', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550402
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Purnima Nath'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tim Rogers', 'Tim', 'Rogers', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550403
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tim Rogers'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Arthur Burks', 'Arthur', 'Burks', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia/local news (postcrescent.com, wxow.com) independent/minor-party filing; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550404
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Arthur Burks'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Scott Fitzgerald', 'Scott', 'Fitzgerald', true, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -55005
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5505'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Scott Fitzgerald'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andrew Beck', 'Andrew', 'Beck', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550501
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5505'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andrew Beck'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Glenn Grothman', 'Glenn', 'Grothman', true, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -55006
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5506'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Glenn Grothman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Amanda Bell', 'Amanda', 'Bell', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550601
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5506'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Amanda Bell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brad Smith', 'Brad', 'Smith', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550602
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5506'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brad Smith'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matthew Arndt', 'Matthew', 'Arndt', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia/local news (postcrescent.com, wxow.com) independent/minor-party filing; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550603
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5506'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matthew Arndt'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Elizabeth Fitzgibbon', 'Elizabeth', 'Fitzgibbon', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia/local news (postcrescent.com, wxow.com) independent/minor-party filing; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550604
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5506'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Elizabeth Fitzgibbon'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Thurow', 'Michael', 'Thurow', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia/local news (postcrescent.com, wxow.com) independent/minor-party filing; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550605
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5506'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Thurow'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Alfonso', 'Michael', 'Alfonso', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550701
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5507'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Alfonso'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Niina Baum', 'Niina', 'Baum', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550702
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5507'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Niina Baum'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jessi Ebben', 'Jessi', 'Ebben', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550703
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5507'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jessi Ebben'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kevin Hermening', 'Kevin', 'Hermening', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550704
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5507'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kevin Hermening'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Armstrong', 'Chris', 'Armstrong', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550705
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5507'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris Armstrong'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Fred Clark', 'Fred', 'Clark', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550706
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5507'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Fred Clark'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ginger Murray', 'Ginger', 'Murray', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550707
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5507'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ginger Murray'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tony Wied', 'Tony', 'Wied', true, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -55008
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5508'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tony Wied'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rick Crosson', 'Rick', 'Crosson', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550801
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5508'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rick Crosson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Katrina deVille', 'Katrina', 'deVille', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550802
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5508'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Katrina deVille'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mark Scheffler', 'Mark', 'Scheffler', false, 'active', '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -550803
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = '5508'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mark Scheffler'));

COMMIT;
