-- 1241_seed_ia_2026_house_candidates.sql
-- Phase 164-05 Task 3: 9 new IA politicians + 11 active race_candidates onto the 4
--   IA 2026 Statewide General races. Reuse 2 renominated incumbents (-19001 Miller-Meeks/-19003
--   Nunn). OPEN SEATS (D-05): Hinson -19002 (IA-2, retired) + Feenstra -19004 (IA-4, retired) NO row.
--   external_id band -(19*10000+cd*100+seq), standard seq start 1. ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -190101, 'Christina Bohannan', 'Christina', 'Bohannan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -190101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -190102, 'Michael Bridgford', 'Michael', 'Bridgford', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -190102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -190201, 'Joe Mitchell', 'Joe', 'Mitchell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -190201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -190202, 'Lindsay James', 'Lindsay', 'James', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -190202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -190203, 'Dave Bushaw', 'Dave', 'Bushaw', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -190203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -190204, 'Rick Stewart', 'Rick', 'Stewart', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -190204);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -190301, 'Sarah Trone Garriott', 'Sarah', 'Trone Garriott', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -190301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -190401, 'Chris McGowan', 'Chris', 'McGowan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -190401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -190402, 'Dave Dawson', 'Dave', 'Dawson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -190402);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mariannette Miller-Meeks', 'Mariannette', 'Miller-Meeks', true, 'active', 'IA 2026 US House field (IA SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Iowa); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -19001
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1901'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mariannette Miller-Meeks'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christina Bohannan', 'Christina', 'Bohannan', false, 'active', 'IA 2026 US House field (IA SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Iowa); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -190101
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1901'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christina Bohannan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Bridgford', 'Michael', 'Bridgford', false, 'active', 'IA 2026 US House field (independent/minor-party filing; IA SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -190102
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1901'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Bridgford'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joe Mitchell', 'Joe', 'Mitchell', false, 'active', 'IA 2026 US House field (IA SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Iowa); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -190201
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1902'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joe Mitchell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lindsay James', 'Lindsay', 'James', false, 'active', 'IA 2026 US House field (IA SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Iowa); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -190202
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1902'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lindsay James'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dave Bushaw', 'Dave', 'Bushaw', false, 'active', 'IA 2026 US House field (independent/minor-party filing; IA SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -190203
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1902'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dave Bushaw'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rick Stewart', 'Rick', 'Stewart', false, 'active', 'IA 2026 US House field (independent/minor-party filing; IA SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -190204
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1902'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rick Stewart'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Zachary Nunn', 'Zachary', 'Nunn', true, 'active', 'IA 2026 US House field (IA SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Iowa); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -19003
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1903'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Zachary Nunn'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sarah Trone Garriott', 'Sarah', 'Trone Garriott', false, 'active', 'IA 2026 US House field (IA SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Iowa); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -190301
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1903'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Sarah Trone Garriott'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris McGowan', 'Chris', 'McGowan', false, 'active', 'IA 2026 US House field (IA SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Iowa); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -190401
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1904'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris McGowan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dave Dawson', 'Dave', 'Dawson', false, 'active', 'IA 2026 US House field (IA SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Iowa); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -190402
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = '1904'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dave Dawson'));

COMMIT;
