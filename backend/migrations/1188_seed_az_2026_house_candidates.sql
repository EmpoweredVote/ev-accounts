-- 1188_seed_az_2026_house_candidates.sql
-- Phase 161-02 Task 2: 32 new AZ politicians + 39 active race_candidates
--   onto the 9 AZ 2026 Statewide General races. Reuse 7 renominated incumbents by external_id;
--   AZ-1 David Schweikert (-4001) + AZ-5 Andy Biggs (-4005) RETIRED -> NO active row (open-seat
--   convention, mirrors MI-10/MI-11). ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p161.csv AZ rows, cross-checked Wikipedia per-district AZ House pages.
BEGIN;

-- 32 new challenger/open-seat/indep/L/G records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40101, 'Joseph Chaplik', 'Joseph', 'Chaplik', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40102, 'Jay Feely', 'Jay', 'Feely', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40103, 'John Trobough', 'John', 'Trobough', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40104, 'Marlene Galán-Woods', 'Marlene', 'Galán-Woods', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40105, 'Rick McCartney', 'Rick', 'McCartney', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40106, 'Amish Shah', 'Amish', 'Shah', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40106);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40107, 'Jonathan Treble', 'Jonathan', 'Treble', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40107);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40108, 'Christopher Ajluni', 'Christopher', 'Ajluni', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40108);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40109, 'Monica Alponte', 'Monica', 'Alponte', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40109);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40110, 'David Redkey', 'David', 'Redkey', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40110);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40201, 'Eric Descheenie', 'Eric', 'Descheenie', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40202, 'Jonathan Nez', 'Jonathan', 'Nez', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40203, 'Curtis Goodwin', 'Curtis', 'Goodwin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40301, 'Alan Aversa', 'Alan', 'Aversa', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40401, 'Kai Newkirk', 'Kai', 'Newkirk', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40402, 'Jerone Davison', 'Jerone', 'Davison', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40403, 'Zuhdi Jasser', 'Zuhdi', 'Jasser', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40404, 'Tisha Benoit', 'Tisha', 'Benoit', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40405, 'John Fillmore', 'John', 'Fillmore', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40405);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40501, 'Mark Lamb', 'Mark', 'Lamb', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40502, 'Daniel Keenan', 'Daniel', 'Keenan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40503, 'Blake Bracht', 'Blake', 'Bracht', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40504, 'Brian Hualde', 'Brian', 'Hualde', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40504);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40505, 'Chris James', 'Chris', 'James', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40505);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40506, 'Elizabeth Lee', 'Elizabeth', 'Lee', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40506);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40601, 'JoAnna Mendoza', 'JoAnna', 'Mendoza', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40602, 'Iman Bah', 'Iman', 'Bah', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40603, 'Jereme Peters', 'Jereme', 'Peters', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40701, 'Daniel Butierez', 'Daniel', 'Butierez', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40801, 'Bernadette Greene-Placentia', 'Bernadette', 'Greene-Placentia', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40802, 'Raymond Keeler', 'Raymond', 'Keeler', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40802);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -40901, 'Danielle Sterbinsky', 'Danielle', 'Sterbinsky', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -40901);

-- 39 active race_candidates (7 incumbents reused + 32 new; Schweikert/Biggs excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joseph Chaplik', 'Joseph', 'Chaplik', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40101
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joseph Chaplik'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jay Feely', 'Jay', 'Feely', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40102
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jay Feely'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Trobough', 'John', 'Trobough', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40103
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Trobough'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Marlene Galán-Woods', 'Marlene', 'Galán-Woods', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40104
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Marlene Galán-Woods'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rick McCartney', 'Rick', 'McCartney', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40105
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rick McCartney'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Amish Shah', 'Amish', 'Shah', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40106
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Amish Shah'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jonathan Treble', 'Jonathan', 'Treble', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40107
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jonathan Treble'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christopher Ajluni', 'Christopher', 'Ajluni', false, 'active', 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40108
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christopher Ajluni'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Monica Alponte', 'Monica', 'Alponte', false, 'active', 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40109
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Monica Alponte'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David Redkey', 'David', 'Redkey', false, 'active', 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40110
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0401'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('David Redkey'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Elijah Crane', 'Elijah', 'Crane', true, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -4002
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0402'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Elijah Crane'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eric Descheenie', 'Eric', 'Descheenie', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40201
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0402'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Eric Descheenie'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jonathan Nez', 'Jonathan', 'Nez', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40202
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0402'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jonathan Nez'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Curtis Goodwin', 'Curtis', 'Goodwin', false, 'active', 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40203
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0402'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Curtis Goodwin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Yassamin Ansari', 'Yassamin', 'Ansari', true, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -4003
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0403'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Yassamin Ansari'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Alan Aversa', 'Alan', 'Aversa', false, 'active', 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40301
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0403'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Alan Aversa'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Greg Stanton', 'Greg', 'Stanton', true, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -4004
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0404'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Greg Stanton'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kai Newkirk', 'Kai', 'Newkirk', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40401
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0404'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kai Newkirk'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jerone Davison', 'Jerone', 'Davison', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40402
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0404'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jerone Davison'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Zuhdi Jasser', 'Zuhdi', 'Jasser', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40403
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0404'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Zuhdi Jasser'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tisha Benoit', 'Tisha', 'Benoit', false, 'active', 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40404
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0404'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tisha Benoit'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Fillmore', 'John', 'Fillmore', false, 'active', 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40405
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0404'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Fillmore'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mark Lamb', 'Mark', 'Lamb', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40501
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0405'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mark Lamb'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Daniel Keenan', 'Daniel', 'Keenan', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40502
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0405'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Daniel Keenan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Blake Bracht', 'Blake', 'Bracht', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40503
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0405'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Blake Bracht'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brian Hualde', 'Brian', 'Hualde', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40504
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0405'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brian Hualde'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris James', 'Chris', 'James', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40505
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0405'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris James'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Elizabeth Lee', 'Elizabeth', 'Lee', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40506
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0405'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Elizabeth Lee'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Juan Ciscomani', 'Juan', 'Ciscomani', true, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -4006
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0406'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Juan Ciscomani'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'JoAnna Mendoza', 'JoAnna', 'Mendoza', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40601
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0406'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('JoAnna Mendoza'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Iman Bah', 'Iman', 'Bah', false, 'active', 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40602
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0406'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Iman Bah'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jereme Peters', 'Jereme', 'Peters', false, 'active', 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40603
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0406'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jereme Peters'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Adelita S. Grijalva', 'Adelita', 'S. Grijalva', true, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -4007
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0407'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Adelita S. Grijalva'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Daniel Butierez', 'Daniel', 'Butierez', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40701
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0407'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Daniel Butierez'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Abraham J. Hamadeh', 'Abraham', 'J. Hamadeh', true, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -4008
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0408'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Abraham J. Hamadeh'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bernadette Greene-Placentia', 'Bernadette', 'Greene-Placentia', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40801
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0408'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bernadette Greene-Placentia'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Raymond Keeler', 'Raymond', 'Keeler', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40802
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0408'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Raymond Keeler'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Paul A. Gosar', 'Paul', 'A. Gosar', true, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -4009
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0409'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Paul A. Gosar'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Danielle Sterbinsky', 'Danielle', 'Sterbinsky', false, 'active', 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -40901
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = '0409'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Danielle Sterbinsky'));

COMMIT;
