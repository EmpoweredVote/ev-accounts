-- 1229_seed_la_2026_house_candidates.sql
-- Phase 163-06 Task 2: 27 new LA politicians + 32 active race_candidates
--   onto the 6 LA 2026 jungle races (4 general + 2 withheld "Polygon Pending" LA-2/LA-6, per 163-01
--   routing). Reuse 5 renominated incumbents by external_id ON the jungle ballot (is_incumbent=true);
--   LA-5 Julia Letlow (-22005, retired->Senate) -> NO row (open seat, 13 declared). race_candidates
--   join by district geo_id, so severe-district candidates are wired identically regardless of the
--   election-visibility substitution. ANTIPARTISAN: party never stored; offices untouched.
--   Field: 160-field-table-p163.csv LA rows, Wikipedia 2026 US House elections in Louisiana.
BEGIN;

-- 27 new challenger/open-seat records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220101, 'Randall Arrington', 'Randall', 'Arrington', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220102, 'Jim Long', 'Jim', 'Long', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220201, 'Renada Collins', 'Renada', 'Collins', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220301, 'John Day', 'John', 'Day', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220302, 'Tia LeBrun', 'Tia', 'LeBrun', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220303, 'Caleb Walker', 'Caleb', 'Walker', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220303);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220401, 'Josh Morott', 'Josh', 'Morott', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220402, 'Mike Nichols', 'Mike', 'Nichols', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220403, 'Conrad Cable', 'Conrad', 'Cable', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220404, 'Matt Gromlich', 'Matt', 'Gromlich', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220501, 'Misti Cordell', 'Misti', 'Cordell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220502, 'Michael Echols', 'Michael', 'Echols', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220503, 'Rick Edmonds', 'Rick', 'Edmonds', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220504, 'Austin Magee', 'Austin', 'Magee', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220504);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220505, 'Michael Mebruer', 'Michael', 'Mebruer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220505);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220506, 'Blake Miguez', 'Blake', 'Miguez', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220506);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220507, 'Sammy Wyatt', 'Sammy', 'Wyatt', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220507);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220508, 'Gabe Firment', 'Gabe', 'Firment', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220508);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220509, 'Jessee Fleenor', 'Jessee', 'Fleenor', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220509);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220510, 'Larry Foy', 'Larry', 'Foy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220510);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220511, 'Lindsay Garcia', 'Lindsay', 'Garcia', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220511);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220512, 'Dan McKay', 'Dan', 'McKay', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220512);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220513, 'Tania Nyman', 'Tania', 'Nyman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220513);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220601, 'Monique Appeaning', 'Monique', 'Appeaning', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220602, 'Larry Davis', 'Larry', 'Davis', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220603, 'Chris Johnson', 'Chris', 'Johnson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -220604, 'Peter Williams', 'Peter', 'Williams', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220604);

-- 32 active race_candidates (5 incumbents reused on jungle ballot + 27 new; Letlow excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Steve Scalise', 'Steve', 'Scalise', true, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -22001
WHERE d.geo_id = '2201' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Steve Scalise'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Randall Arrington', 'Randall', 'Arrington', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220101
WHERE d.geo_id = '2201' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Randall Arrington'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jim Long', 'Jim', 'Long', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220102
WHERE d.geo_id = '2201' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jim Long'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Troy Carter', 'Troy', 'Carter', true, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -22002
WHERE d.geo_id = '2202' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Troy Carter'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Renada Collins', 'Renada', 'Collins', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220201
WHERE d.geo_id = '2202' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Renada Collins'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Clay Higgins', 'Clay', 'Higgins', true, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -22003
WHERE d.geo_id = '2203' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Clay Higgins'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Day', 'John', 'Day', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220301
WHERE d.geo_id = '2203' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Day'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tia LeBrun', 'Tia', 'LeBrun', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220302
WHERE d.geo_id = '2203' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tia LeBrun'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Caleb Walker', 'Caleb', 'Walker', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220303
WHERE d.geo_id = '2203' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Caleb Walker'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mike Johnson', 'Mike', 'Johnson', true, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -22004
WHERE d.geo_id = '2204' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mike Johnson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Josh Morott', 'Josh', 'Morott', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220401
WHERE d.geo_id = '2204' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Josh Morott'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mike Nichols', 'Mike', 'Nichols', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220402
WHERE d.geo_id = '2204' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mike Nichols'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Conrad Cable', 'Conrad', 'Cable', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220403
WHERE d.geo_id = '2204' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Conrad Cable'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matt Gromlich', 'Matt', 'Gromlich', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220404
WHERE d.geo_id = '2204' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matt Gromlich'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Misti Cordell', 'Misti', 'Cordell', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220501
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Misti Cordell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Echols', 'Michael', 'Echols', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220502
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Echols'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rick Edmonds', 'Rick', 'Edmonds', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220503
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rick Edmonds'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Austin Magee', 'Austin', 'Magee', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220504
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Austin Magee'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Mebruer', 'Michael', 'Mebruer', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220505
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Mebruer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Blake Miguez', 'Blake', 'Miguez', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220506
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Blake Miguez'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sammy Wyatt', 'Sammy', 'Wyatt', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220507
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Sammy Wyatt'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gabe Firment', 'Gabe', 'Firment', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220508
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gabe Firment'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jessee Fleenor', 'Jessee', 'Fleenor', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220509
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jessee Fleenor'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Larry Foy', 'Larry', 'Foy', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220510
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Larry Foy'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lindsay Garcia', 'Lindsay', 'Garcia', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220511
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lindsay Garcia'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dan McKay', 'Dan', 'McKay', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220512
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dan McKay'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tania Nyman', 'Tania', 'Nyman', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220513
WHERE d.geo_id = '2205' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tania Nyman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Cleo Fields', 'Cleo', 'Fields', true, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -22006
WHERE d.geo_id = '2206' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Cleo Fields'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Monique Appeaning', 'Monique', 'Appeaning', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220601
WHERE d.geo_id = '2206' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Monique Appeaning'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Larry Davis', 'Larry', 'Davis', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220602
WHERE d.geo_id = '2206' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Larry Davis'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Johnson', 'Chris', 'Johnson', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220603
WHERE d.geo_id = '2206' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris Johnson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Peter Williams', 'Peter', 'Williams', false, 'active', '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -220604
WHERE d.geo_id = '2206' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Peter Williams'));

COMMIT;
