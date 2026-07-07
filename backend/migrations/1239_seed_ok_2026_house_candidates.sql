-- 1239_seed_ok_2026_house_candidates.sql
-- Phase 164-05 Task 2: 10 new OK politicians + 14 active race_candidates onto the 5
--   OK 2026 Statewide General races. Reuse 4 renominated incumbents (-40002 Brecheen/-40003 Lucas/
--   -40004 Cole/-40005 Bice). OPEN SEAT (D-05): Hern -40001 (OK-1, retired) NO row. external_id band
--   -(40*10000+cd*100+seq); OK-1 uses in-century seq 44/45 (-400144/-400145) to avoid the 43 occupied
--   seqs AND the OK-3 cross-boundary collision. ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400144, 'Mark Tedford', 'Mark', 'Tedford', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400144);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400145, 'John Croisant', 'John', 'Croisant', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400145);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400201, 'Brandon Wade', 'Brandon', 'Wade', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400202, 'Ronnie Hopkins', 'Ronnie', 'Hopkins', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400301, 'Suzie Byrd', 'Suzie', 'Byrd', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400401, 'Mitchell Jacob', 'Mitchell', 'Jacob', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400402, 'Rocco Bonacci', 'Rocco', 'Bonacci', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400501, 'Jena Nelson', 'Jena', 'Nelson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400502, 'Robert P. Henri', 'Robert', 'P. Henri', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -400503, 'Austin Nieves', 'Austin', 'Nieves', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -400503);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mark Tedford', 'Mark', 'Tedford', false, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400144
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4001'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mark Tedford'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Croisant', 'John', 'Croisant', false, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400145
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4001'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Croisant'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Josh Brecheen', 'Josh', 'Brecheen', true, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40002
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4002'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Josh Brecheen'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brandon Wade', 'Brandon', 'Wade', false, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400201
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4002'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brandon Wade'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ronnie Hopkins', 'Ronnie', 'Hopkins', false, 'active', 'OK 2026 US House field (independent/minor-party filing; OK SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400202
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4002'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ronnie Hopkins'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Frank D. Lucas', 'Frank', 'D. Lucas', true, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40003
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4003'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Frank D. Lucas'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Suzie Byrd', 'Suzie', 'Byrd', false, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400301
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4003'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Suzie Byrd'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tom Cole', 'Tom', 'Cole', true, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40004
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tom Cole'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mitchell Jacob', 'Mitchell', 'Jacob', false, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400401
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mitchell Jacob'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rocco Bonacci', 'Rocco', 'Bonacci', false, 'active', 'OK 2026 US House field (independent/minor-party filing; OK SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400402
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rocco Bonacci'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Stephanie I. Bice', 'Stephanie', 'I. Bice', true, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40005
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4005'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Stephanie I. Bice'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jena Nelson', 'Jena', 'Nelson', false, 'active', 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400501
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4005'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jena Nelson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Robert P. Henri', 'Robert', 'P. Henri', false, 'active', 'OK 2026 US House field (independent/minor-party filing; OK SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400502
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4005'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Robert P. Henri'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Austin Nieves', 'Austin', 'Nieves', false, 'active', 'OK 2026 US House field (independent/minor-party filing; OK SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -400503
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = '4005'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Austin Nieves'));

COMMIT;
