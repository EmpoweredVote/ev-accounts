-- 1237_seed_ky_2026_house_candidates.sql
-- Phase 164-04 Task 2: 15 new KY politicians + 19 active race_candidates
--   onto the 6 KY 2026 Statewide General races. Reuse 4 renominated incumbents by external_id
--   (-21001 Comer / -21002 Guthrie / -21003 McGarvey / -21005 Harold Rogers). OPEN SEATS (D-05):
--   Massie -21004 (KY-4, lost primary) and Barr -21006 (KY-6, retired) get NO active row. external_id
--   band -(21*10000+cd*100+seq); KY-1 seq 200 (-210300) avoids 98 MA state-leg collisions.
--   ANTIPARTISAN: party never stored; races untouched.
BEGIN;

-- 15 new challenger/open-seat/minor-party records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210300, 'John "Drew" Williams', 'John', '"Drew" Williams', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210300);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210201, 'Megan Wingfield', 'Megan', 'Wingfield', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210202, 'Thomas A. Loecken', 'Thomas', 'A. Loecken', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210301, 'Maria Teresa Rodriguez', 'Maria', 'Teresa Rodriguez', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210401, 'Ed Gallrein', 'Ed', 'Gallrein', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210402, 'Melissa Claire Strange', 'Melissa', 'Claire Strange', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210403, 'Mohammad Wael Ahmad', 'Mohammad', 'Wael Ahmad', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210404, 'Jeremy Todd', 'Jeremy', 'Todd', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210501, 'Ned Pillersdorf', 'Ned', 'Pillersdorf', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210502, 'Gerardo Serrano', 'Gerardo', 'Serrano', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210503, 'Mikel Wein', 'Mikel', 'Wein', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210601, 'Ralph Alvarado', 'Ralph', 'Alvarado', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210602, 'Zach Dembo', 'Zach', 'Dembo', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210603, 'Jay J Bowman', 'Jay', 'J Bowman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -210604, 'Pete Lynch', 'Pete', 'Lynch', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -210604);

-- 19 active race_candidates (4 incumbents reused + 15 new; Massie/Barr excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James Comer', 'James', 'Comer', true, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -21001
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2101'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James Comer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John "Drew" Williams', 'John', '"Drew" Williams', false, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210300
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2101'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John "Drew" Williams'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brett Guthrie', 'Brett', 'Guthrie', true, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -21002
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2102'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brett Guthrie'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Megan Wingfield', 'Megan', 'Wingfield', false, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210201
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2102'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Megan Wingfield'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Thomas A. Loecken', 'Thomas', 'A. Loecken', false, 'active', 'KY 2026 US House field (minor-party/independent filing; KY SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210202
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2102'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Thomas A. Loecken'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Morgan McGarvey', 'Morgan', 'McGarvey', true, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -21003
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2103'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Morgan McGarvey'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Maria Teresa Rodriguez', 'Maria', 'Teresa Rodriguez', false, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210301
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2103'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Maria Teresa Rodriguez'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ed Gallrein', 'Ed', 'Gallrein', false, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210401
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2104'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ed Gallrein'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Melissa Claire Strange', 'Melissa', 'Claire Strange', false, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210402
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2104'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Melissa Claire Strange'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mohammad Wael Ahmad', 'Mohammad', 'Wael Ahmad', false, 'active', 'KY 2026 US House field (minor-party/independent filing; KY SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210403
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2104'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mohammad Wael Ahmad'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jeremy Todd', 'Jeremy', 'Todd', false, 'active', 'KY 2026 US House field (minor-party/independent filing; KY SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210404
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2104'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jeremy Todd'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Harold Rogers', 'Harold', 'Rogers', true, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -21005
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2105'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Harold Rogers'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ned Pillersdorf', 'Ned', 'Pillersdorf', false, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210501
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2105'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ned Pillersdorf'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gerardo Serrano', 'Gerardo', 'Serrano', false, 'active', 'KY 2026 US House field (minor-party/independent filing; KY SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210502
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2105'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gerardo Serrano'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mikel Wein', 'Mikel', 'Wein', false, 'active', 'KY 2026 US House field (minor-party/independent filing; KY SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210503
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2105'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mikel Wein'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ralph Alvarado', 'Ralph', 'Alvarado', false, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210601
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2106'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ralph Alvarado'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Zach Dembo', 'Zach', 'Dembo', false, 'active', 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210602
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2106'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Zach Dembo'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jay J Bowman', 'Jay', 'J Bowman', false, 'active', 'KY 2026 US House field (minor-party/independent filing; KY SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210603
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2106'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jay J Bowman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Pete Lynch', 'Pete', 'Lynch', false, 'active', 'KY 2026 US House field (minor-party/independent filing; KY SoS + Wikipedia); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -210604
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = '2106'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Pete Lynch'));

COMMIT;
