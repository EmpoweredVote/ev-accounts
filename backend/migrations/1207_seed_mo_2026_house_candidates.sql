-- 1207_seed_mo_2026_house_candidates.sql
-- Phase 162-02 Task 2: 58 new MO politicians + 65 active race_candidates
--   onto the 8 MO 2026 House races (3 general + 5 withheld "Polygon Pending", per 162-01 severity
--   routing). Reuse 7 renominated incumbents by external_id; MO-6 Sam Graves (-29006, RETIRED) -> NO
--   active row (open-seat convention, mirrors TN-6/TN-9 and AZ-1/AZ-5). MO-1 Cori Bush is a NEW record
--   (no prior essentials.politicians row -- 162-02 Task 1 lookup returned 0). race_candidates inserts
--   join by district geo_id (not election name), so severe-district candidates are wired identically
--   regardless of the election-visibility substitution -- seeding is complete for severe districts even
--   though the race itself does not surface on /elections.
--   ANTIPARTISAN: party never stored; races untouched. Field: 160-field-table-p162.csv MO rows,
--   cross-checked Wikipedia "2026 US House elections in Missouri" (cites the MO SOS candidate filing list).
BEGIN;

-- 58 new challenger/open-seat records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290101, 'Cori Bush', 'Cori', 'Bush', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290102, 'Carl Harris', 'Carl', 'Harris', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290103, 'Carl E. Henderson', 'Carl', 'E. Henderson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290104, 'Alissa Murphy', 'Alissa', 'Murphy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290105, 'Paul Berry', 'Paul', 'Berry', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290106, 'Andrew Jones', 'Andrew', 'Jones', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290106);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290107, 'Tom Schmitz', 'Tom', 'Schmitz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290107);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290201, 'Elizabeth Sparks-Holmes', 'Elizabeth', 'Sparks-Holmes', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290202, 'Peter Pfeifer', 'Peter', 'Pfeifer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290203, 'Ryan Sheridan', 'Ryan', 'Sheridan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290204, 'Brandon Wilkinson', 'Brandon', 'Wilkinson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290204);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290205, 'Tim Bilash', 'Tim', 'Bilash', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290205);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290206, 'Chuck Summers', 'Chuck', 'Summers', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290206);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290207, 'Nick Vivio', 'Nick', 'Vivio', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290207);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290208, 'Joan VonDras', 'Joan', 'VonDras', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290208);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290209, 'Fred Wellman', 'Fred', 'Wellman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290209);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290210, 'Brandon Coulter Daugherty', 'Brandon', 'Coulter Daugherty', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290210);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290301, 'John Fraser', 'John', 'Fraser', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290302, 'Mike Conner', 'Mike', 'Conner', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290303, 'Tommy Holstein', 'Tommy', 'Holstein', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290303);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290304, 'Bethany Mann', 'Bethany', 'Mann', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290304);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290305, 'Paul Wilson', 'Paul', 'Wilson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290305);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290306, 'Jim Higgins', 'Jim', 'Higgins', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290306);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290401, 'Heather Shelton', 'Heather', 'Shelton', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290402, 'Scott Vera', 'Scott', 'Vera', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290403, 'Jeanette Cass', 'Jeanette', 'Cass', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290404, 'Hartzell Gray', 'Hartzell', 'Gray', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290405, 'Jordan Herrera', 'Jordan', 'Herrera', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290405);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290406, 'Randy Miller', 'Randy', 'Miller', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290406);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290407, 'G Rick', 'G', 'Rick', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290407);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290408, 'Ashleigh Rogers', 'Ashleigh', 'Rogers', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290408);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290409, 'Wayne Russell', 'Wayne', 'Russell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290409);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290410, 'Thomas Holbrook', 'Thomas', 'Holbrook', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290410);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290501, 'Micah Beebe', 'Micah', 'Beebe', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290502, 'Rick Brattin', 'Rick', 'Brattin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290503, 'Taylor Burks', 'Taylor', 'Burks', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290504, 'Brett Hueffmeier', 'Brett', 'Hueffmeier', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290504);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290505, 'Berton A. Knox', 'Berton', 'A. Knox', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290505);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290506, 'Brad Patty', 'Brad', 'Patty', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290506);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290507, 'Randall Langkraehr', 'Randall', 'Langkraehr', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290507);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290601, 'James Ingram', 'James', 'Ingram', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290602, 'Cody J. Oshel', 'Cody', 'J. Oshel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290603, 'Nathanael Schultz', 'Nathanael', 'Schultz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290604, 'Chris Stigall', 'Chris', 'Stigall', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290604);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290605, 'Nathan Willett', 'Nathan', 'Willett', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290605);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290606, 'Matt Levine', 'Matt', 'Levine', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290606);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290607, 'Scot Pondelick', 'Scot', 'Pondelick', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290607);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290608, 'Josh Smead', 'Josh', 'Smead', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290608);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290609, 'Andy Maidment', 'Andy', 'Maidment', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290609);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290701, 'John Casey', 'John', 'Casey', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290702, 'Grayson Hunt', 'Grayson', 'Hunt', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290702);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290703, 'Missi Hesketh', 'Missi', 'Hesketh', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290703);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290704, 'Kevin Craig', 'Kevin', 'Craig', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290704);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290801, 'Gordon Heslop', 'Gordon', 'Heslop', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290802, 'Frank Barnitz', 'Frank', 'Barnitz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290802);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290803, 'Clayton Harbison', 'Clayton', 'Harbison', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290803);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290804, 'Christopher Reichard', 'Christopher', 'Reichard', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290804);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -290805, 'Rebecca Sharpe Lombard', 'Rebecca', 'Sharpe Lombard', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -290805);

-- 65 active race_candidates (7 incumbents reused + 58 new; Graves excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Wesley Bell', 'Wesley', 'Bell', true, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -29001
WHERE d.geo_id = '2901' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Wesley Bell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Cori Bush', 'Cori', 'Bush', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290101
WHERE d.geo_id = '2901' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Cori Bush'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Carl Harris', 'Carl', 'Harris', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290102
WHERE d.geo_id = '2901' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Carl Harris'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Carl E. Henderson', 'Carl', 'E. Henderson', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290103
WHERE d.geo_id = '2901' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Carl E. Henderson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Alissa Murphy', 'Alissa', 'Murphy', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290104
WHERE d.geo_id = '2901' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Alissa Murphy'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Paul Berry', 'Paul', 'Berry', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290105
WHERE d.geo_id = '2901' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Paul Berry'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andrew Jones', 'Andrew', 'Jones', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290106
WHERE d.geo_id = '2901' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andrew Jones'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tom Schmitz', 'Tom', 'Schmitz', false, 'active', 'Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate filing list); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290107
WHERE d.geo_id = '2901' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tom Schmitz'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ann Wagner', 'Ann', 'Wagner', true, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -29002
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ann Wagner'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Elizabeth Sparks-Holmes', 'Elizabeth', 'Sparks-Holmes', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290201
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Elizabeth Sparks-Holmes'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Peter Pfeifer', 'Peter', 'Pfeifer', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290202
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Peter Pfeifer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ryan Sheridan', 'Ryan', 'Sheridan', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290203
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ryan Sheridan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brandon Wilkinson', 'Brandon', 'Wilkinson', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290204
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brandon Wilkinson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tim Bilash', 'Tim', 'Bilash', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290205
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tim Bilash'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chuck Summers', 'Chuck', 'Summers', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290206
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chuck Summers'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nick Vivio', 'Nick', 'Vivio', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290207
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Nick Vivio'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joan VonDras', 'Joan', 'VonDras', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290208
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joan VonDras'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Fred Wellman', 'Fred', 'Wellman', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290209
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Fred Wellman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brandon Coulter Daugherty', 'Brandon', 'Coulter Daugherty', false, 'active', 'Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate filing list); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290210
WHERE d.geo_id = '2902' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brandon Coulter Daugherty'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Robert F. Onder, Jr.', 'Robert', 'F. Onder, Jr.', true, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -29003
WHERE d.geo_id = '2903' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Robert F. Onder, Jr.'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Fraser', 'John', 'Fraser', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290301
WHERE d.geo_id = '2903' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Fraser'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mike Conner', 'Mike', 'Conner', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290302
WHERE d.geo_id = '2903' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mike Conner'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tommy Holstein', 'Tommy', 'Holstein', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290303
WHERE d.geo_id = '2903' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tommy Holstein'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bethany Mann', 'Bethany', 'Mann', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290304
WHERE d.geo_id = '2903' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bethany Mann'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Paul Wilson', 'Paul', 'Wilson', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290305
WHERE d.geo_id = '2903' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Paul Wilson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jim Higgins', 'Jim', 'Higgins', false, 'active', 'Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate filing list); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290306
WHERE d.geo_id = '2903' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jim Higgins'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mark Alford', 'Mark', 'Alford', true, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -29004
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mark Alford'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Heather Shelton', 'Heather', 'Shelton', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290401
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Heather Shelton'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Scott Vera', 'Scott', 'Vera', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290402
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Scott Vera'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jeanette Cass', 'Jeanette', 'Cass', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290403
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jeanette Cass'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Hartzell Gray', 'Hartzell', 'Gray', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290404
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Hartzell Gray'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jordan Herrera', 'Jordan', 'Herrera', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290405
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jordan Herrera'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Randy Miller', 'Randy', 'Miller', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290406
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Randy Miller'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'G Rick', 'G', 'Rick', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290407
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('G Rick'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ashleigh Rogers', 'Ashleigh', 'Rogers', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290408
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ashleigh Rogers'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Wayne Russell', 'Wayne', 'Russell', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290409
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Wayne Russell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Thomas Holbrook', 'Thomas', 'Holbrook', false, 'active', 'Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate filing list); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290410
WHERE d.geo_id = '2904' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Thomas Holbrook'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Emanuel Cleaver', 'Emanuel', 'Cleaver', true, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -29005
WHERE d.geo_id = '2905' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Emanuel Cleaver'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Micah Beebe', 'Micah', 'Beebe', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290501
WHERE d.geo_id = '2905' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Micah Beebe'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rick Brattin', 'Rick', 'Brattin', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290502
WHERE d.geo_id = '2905' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rick Brattin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Taylor Burks', 'Taylor', 'Burks', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290503
WHERE d.geo_id = '2905' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Taylor Burks'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brett Hueffmeier', 'Brett', 'Hueffmeier', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290504
WHERE d.geo_id = '2905' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brett Hueffmeier'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Berton A. Knox', 'Berton', 'A. Knox', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290505
WHERE d.geo_id = '2905' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Berton A. Knox'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brad Patty', 'Brad', 'Patty', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290506
WHERE d.geo_id = '2905' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brad Patty'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Randall Langkraehr', 'Randall', 'Langkraehr', false, 'active', 'Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate filing list); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290507
WHERE d.geo_id = '2905' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Randall Langkraehr'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James Ingram', 'James', 'Ingram', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290601
WHERE d.geo_id = '2906' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James Ingram'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Cody J. Oshel', 'Cody', 'J. Oshel', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290602
WHERE d.geo_id = '2906' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Cody J. Oshel'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nathanael Schultz', 'Nathanael', 'Schultz', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290603
WHERE d.geo_id = '2906' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Nathanael Schultz'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Stigall', 'Chris', 'Stigall', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290604
WHERE d.geo_id = '2906' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris Stigall'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nathan Willett', 'Nathan', 'Willett', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290605
WHERE d.geo_id = '2906' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Nathan Willett'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matt Levine', 'Matt', 'Levine', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290606
WHERE d.geo_id = '2906' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matt Levine'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Scot Pondelick', 'Scot', 'Pondelick', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290607
WHERE d.geo_id = '2906' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Scot Pondelick'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Josh Smead', 'Josh', 'Smead', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290608
WHERE d.geo_id = '2906' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Josh Smead'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andy Maidment', 'Andy', 'Maidment', false, 'active', 'Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate filing list); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290609
WHERE d.geo_id = '2906' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andy Maidment'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eric Burlison', 'Eric', 'Burlison', true, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -29007
WHERE d.geo_id = '2907' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Eric Burlison'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Casey', 'John', 'Casey', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290701
WHERE d.geo_id = '2907' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Casey'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Grayson Hunt', 'Grayson', 'Hunt', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290702
WHERE d.geo_id = '2907' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Grayson Hunt'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Missi Hesketh', 'Missi', 'Hesketh', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290703
WHERE d.geo_id = '2907' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Missi Hesketh'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kevin Craig', 'Kevin', 'Craig', false, 'active', 'Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate filing list); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290704
WHERE d.geo_id = '2907' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kevin Craig'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jason Smith', 'Jason', 'Smith', true, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -29008
WHERE d.geo_id = '2908' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jason Smith'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gordon Heslop', 'Gordon', 'Heslop', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290801
WHERE d.geo_id = '2908' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gordon Heslop'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Frank Barnitz', 'Frank', 'Barnitz', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290802
WHERE d.geo_id = '2908' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Frank Barnitz'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Clayton Harbison', 'Clayton', 'Harbison', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290803
WHERE d.geo_id = '2908' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Clayton Harbison'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christopher Reichard', 'Christopher', 'Reichard', false, 'active', 'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290804
WHERE d.geo_id = '2908' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christopher Reichard'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rebecca Sharpe Lombard', 'Rebecca', 'Sharpe Lombard', false, 'active', 'Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate filing list); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -290805
WHERE d.geo_id = '2908' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rebecca Sharpe Lombard'));

COMMIT;
