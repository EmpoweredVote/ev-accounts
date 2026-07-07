-- 1243_seed_ar_2026_house_candidates.sql
-- Phase 164-06 Task 2: 6 new AR politicians + 10 active race_candidates onto the 4
--   AR 2026 Statewide General races. Reuse 4 renominated incumbents (-5001..-5004). No open seats.
--   external_id band -(5*10000+cd*100+seq), standard seq 1. ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -50101, 'Terri Yarbrough Green', 'Terri', 'Yarbrough Green', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -50101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -50102, 'Steve Parsons', 'Steve', 'Parsons', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -50102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -50201, 'Chris Jones', 'Chris', 'Jones', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -50201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -50301, 'Robb Ryerse', 'Robb', 'Ryerse', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -50301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -50302, 'Bobby Wilson', 'Bobby', 'Wilson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -50302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -50401, 'James Russell', 'James', 'Russell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -50401);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eric A. "Rick" Crawford', 'Eric', 'A. "Rick" Crawford', true, 'active', 'AR 2026 US House field (AR SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Arkansas); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -5001
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Eric A. "Rick" Crawford'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Terri Yarbrough Green', 'Terri', 'Yarbrough Green', false, 'active', 'AR 2026 US House field (AR SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Arkansas); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -50101
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Terri Yarbrough Green'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Steve Parsons', 'Steve', 'Parsons', false, 'active', 'AR 2026 US House field (minor-party/independent filing; AR SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -50102
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Steve Parsons'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'J. French Hill', 'J.', 'French Hill', true, 'active', 'AR 2026 US House field (AR SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Arkansas); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -5002
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0502'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('J. French Hill'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Jones', 'Chris', 'Jones', false, 'active', 'AR 2026 US House field (AR SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Arkansas); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -50201
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0502'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris Jones'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Steve Womack', 'Steve', 'Womack', true, 'active', 'AR 2026 US House field (AR SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Arkansas); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -5003
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Steve Womack'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Robb Ryerse', 'Robb', 'Ryerse', false, 'active', 'AR 2026 US House field (AR SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Arkansas); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -50301
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Robb Ryerse'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bobby Wilson', 'Bobby', 'Wilson', false, 'active', 'AR 2026 US House field (minor-party/independent filing; AR SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -50302
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bobby Wilson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bruce Westerman', 'Bruce', 'Westerman', true, 'active', 'AR 2026 US House field (AR SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Arkansas); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -5004
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bruce Westerman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James Russell', 'James', 'Russell', false, 'active', 'AR 2026 US House field (AR SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Arkansas); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -50401
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = '0504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James Russell'));

COMMIT;
