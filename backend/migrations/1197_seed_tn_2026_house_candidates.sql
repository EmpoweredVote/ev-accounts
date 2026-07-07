-- 1197_seed_tn_2026_house_candidates.sql
-- Phase 161-06 Task 1: 73 new TN politicians + 80 active race_candidates
--   onto the 9 TN 2026 House races (4 general + 5 withheld "Polygon Pending", per 161-01 severity
--   routing). Reuse 7 renominated incumbents by external_id; TN-6 John W. Rose (-47006, RETIRED) and
--   TN-9 Steve Cohen (-47009, REDISTRICTED/withdrew) -> NO active row (open-seat convention, mirrors
--   AZ-1/AZ-5). race_candidates inserts join by district geo_id (not election name), so severe-district
--   candidates are wired identically regardless of the election-visibility substitution -- seeding is
--   complete for severe districts even though the race itself does not surface on /elections.
--   ANTIPARTISAN: party never stored; races untouched. Field: 160-field-table-p161.csv TN rows,
--   cross-checked Wikipedia per-district TN House pages + TN SOS certified candidate list.
BEGIN;

-- 73 new challenger/open-seat/indep records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470101, 'Kristi Burke', 'Kristi', 'Burke', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470102, 'Hernan H. Garcia', 'Hernan', 'H. Garcia', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470103, 'David S. Kerr, Jr.', 'David', 'S. Kerr, Jr.', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470104, 'Joshua Ray Ashburn', 'Joshua', 'Ray Ashburn', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470105, 'Richard G. Baker', 'Richard', 'G. Baker', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470106, 'Chris Campbell', 'Chris', 'Campbell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470106);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470107, 'Billy Cody', 'Billy', 'Cody', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470107);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470108, 'Tyler Brice Mitchell McClain', 'Tyler', 'Brice Mitchell McClain', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470108);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470201, 'Michaela Barnett', 'Michaela', 'Barnett', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470202, 'Bruce Fine', 'Bruce', 'Fine', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470203, 'Adam Heimerman', 'Adam', 'Heimerman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470301, 'Anna Golladay', 'Anna', 'Golladay', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470302, 'Bryan Martin', 'Bryan', 'Martin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470303, 'Dean Arnold', 'Dean', 'Arnold', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470303);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470304, 'Jean Howard-Hill', 'Jean', 'Howard-Hill', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470304);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470305, 'Rodney Joe King', 'Rodney', 'Joe King', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470305);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470306, 'Donnie Lynn Ownby', 'Donnie', 'Lynn Ownby', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470306);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470307, 'Edward John Roland', 'Edward', 'John Roland', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470307);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470401, 'Thomas E. Davis', 'Thomas', 'E. Davis', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470402, 'Joshua James', 'Joshua', 'James', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470403, 'Harold "Rocky" Jones', 'Harold', '"Rocky" Jones', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470404, 'Victoria Broderick', 'Victoria', 'Broderick', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470405, 'Mike Cortese', 'Mike', 'Cortese', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470405);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470406, 'Cliff Huffman', 'Cliff', 'Huffman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470406);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470407, 'Tim Lanier', 'Tim', 'Lanier', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470407);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470408, 'Joyce E. Neal', 'Joyce', 'E. Neal', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470408);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470409, 'Jacob Kristopher Anders', 'Jacob', 'Kristopher Anders', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470409);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470410, 'Clay Faircloth', 'Clay', 'Faircloth', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470410);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470501, 'Charlie Hatcher', 'Charlie', 'Hatcher', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470502, 'Yolanda Cooper-Sutton', 'Yolanda', 'Cooper-Sutton', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470503, 'DeVante R. Hill', 'DeVante', 'R. Hill', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470504, 'Rachel Hurley', 'Rachel', 'Hurley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470504);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470505, 'Carrie Ann Iacomini', 'Carrie', 'Ann Iacomini', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470505);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470506, 'Chaz Molder', 'Chaz', 'Molder', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470506);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470507, 'James A. Johnson', 'James', 'A. Johnson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470507);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470508, 'Micheál (Me-Haul) O''Leary', 'Micheál', '(Me-Haul) O''Leary', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470508);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470601, 'Natisha Brooks', 'Natisha', 'Brooks', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470602, 'Johnny Garrett', 'Johnny', 'Garrett', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470603, 'Jon Henry', 'Jon', 'Henry', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470604, 'Van Hilleary', 'Van', 'Hilleary', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470604);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470605, 'Lore Bergman', 'Lore', 'Bergman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470605);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470606, 'Mike Croley', 'Mike', 'Croley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470606);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470607, 'Christopher Martin Finley', 'Christopher', 'Martin Finley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470607);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470608, 'Miriam Leibowitz', 'Miriam', 'Leibowitz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470608);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470609, 'Chaney Mosley', 'Chaney', 'Mosley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470609);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470610, 'Christopher B. Monday', 'Christopher', 'B. Monday', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470610);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470611, 'Angus Purdy', 'Angus', 'Purdy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470611);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470701, 'Darden Copeland', 'Darden', 'Copeland', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470702, 'Vincent Dixie', 'Vincent', 'Dixie', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470702);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470703, 'Saletta Holloway', 'Saletta', 'Holloway', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470703);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470704, 'Joshua Warren Sales', 'Joshua', 'Warren Sales', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470704);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470705, 'Andrew J. Koontz', 'Andrew', 'J. Koontz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470705);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470706, 'Lowell Reynolds', 'Lowell', 'Reynolds', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470706);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470801, 'Dewey Gordon Bryan', 'Dewey', 'Gordon Bryan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470802, 'Jordan D. Hinders', 'Jordan', 'D. Hinders', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470802);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470803, 'Heidi Kuhn', 'Heidi', 'Kuhn', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470803);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470804, 'Leonard Perkins', 'Leonard', 'Perkins', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470804);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470805, 'Adam D. Austill', 'Adam', 'D. Austill', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470805);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470806, 'Wendell "Wells" Blankenship', 'Wendell', '"Wells" Blankenship', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470806);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470807, 'Antonio Futch', 'Antonio', 'Futch', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470807);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470808, 'Pamela Jeanine "P." Moses', 'Pamela', 'Jeanine "P." Moses', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470808);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470809, 'Horace Taylor', 'Horace', 'Taylor', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470809);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470810, 'Henry J. Ward, III', 'Henry', 'J. Ward, III', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470810);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470901, 'Charlotte Bergmann', 'Charlotte', 'Bergmann', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470901);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470902, 'Brent Taylor', 'Brent', 'Taylor', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470902);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470903, 'Jeremy Thompson', 'Jeremy', 'Thompson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470903);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470904, 'Todd Warner', 'Todd', 'Warner', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470904);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470905, 'M. LaTroy A-Williams', 'M.', 'LaTroy A-Williams', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470905);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470906, 'London Lamar', 'London', 'Lamar', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470906);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470907, 'Justin J. Pearson', 'Justin', 'J. Pearson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470907);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470908, 'Jim Torino', 'Jim', 'Torino', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470908);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470909, 'Dennis Clark', 'Dennis', 'Clark', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470909);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -470910, 'Michelle Davis Head', 'Michelle', 'Davis Head', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -470910);

-- 80 active race_candidates (7 incumbents reused + 73 new; Rose/Cohen excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Diana Harshbarger', 'Diana', 'Harshbarger', true, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -47001
WHERE d.geo_id = '4701' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Diana Harshbarger'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kristi Burke', 'Kristi', 'Burke', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470101
WHERE d.geo_id = '4701' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kristi Burke'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Hernan H. Garcia', 'Hernan', 'H. Garcia', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470102
WHERE d.geo_id = '4701' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Hernan H. Garcia'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David S. Kerr, Jr.', 'David', 'S. Kerr, Jr.', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470103
WHERE d.geo_id = '4701' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('David S. Kerr, Jr.'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joshua Ray Ashburn', 'Joshua', 'Ray Ashburn', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470104
WHERE d.geo_id = '4701' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joshua Ray Ashburn'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Richard G. Baker', 'Richard', 'G. Baker', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470105
WHERE d.geo_id = '4701' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Richard G. Baker'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Campbell', 'Chris', 'Campbell', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470106
WHERE d.geo_id = '4701' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris Campbell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Billy Cody', 'Billy', 'Cody', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470107
WHERE d.geo_id = '4701' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Billy Cody'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tyler Brice Mitchell McClain', 'Tyler', 'Brice Mitchell McClain', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470108
WHERE d.geo_id = '4701' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tyler Brice Mitchell McClain'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tim Burchett', 'Tim', 'Burchett', true, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -47002
WHERE d.geo_id = '4702' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tim Burchett'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michaela Barnett', 'Michaela', 'Barnett', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470201
WHERE d.geo_id = '4702' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michaela Barnett'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bruce Fine', 'Bruce', 'Fine', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470202
WHERE d.geo_id = '4702' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bruce Fine'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Adam Heimerman', 'Adam', 'Heimerman', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470203
WHERE d.geo_id = '4702' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Adam Heimerman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Charles J. "Chuck" Fleischmann', 'Charles', 'J. "Chuck" Fleischmann', true, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -47003
WHERE d.geo_id = '4703' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Charles J. "Chuck" Fleischmann'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Anna Golladay', 'Anna', 'Golladay', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470301
WHERE d.geo_id = '4703' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Anna Golladay'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bryan Martin', 'Bryan', 'Martin', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470302
WHERE d.geo_id = '4703' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bryan Martin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dean Arnold', 'Dean', 'Arnold', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470303
WHERE d.geo_id = '4703' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dean Arnold'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jean Howard-Hill', 'Jean', 'Howard-Hill', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470304
WHERE d.geo_id = '4703' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jean Howard-Hill'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rodney Joe King', 'Rodney', 'Joe King', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470305
WHERE d.geo_id = '4703' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rodney Joe King'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Donnie Lynn Ownby', 'Donnie', 'Lynn Ownby', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470306
WHERE d.geo_id = '4703' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Donnie Lynn Ownby'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Edward John Roland', 'Edward', 'John Roland', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470307
WHERE d.geo_id = '4703' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Edward John Roland'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Scott DesJarlais', 'Scott', 'DesJarlais', true, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -47004
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Scott DesJarlais'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Thomas E. Davis', 'Thomas', 'E. Davis', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470401
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Thomas E. Davis'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joshua James', 'Joshua', 'James', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470402
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joshua James'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Harold "Rocky" Jones', 'Harold', '"Rocky" Jones', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470403
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Harold "Rocky" Jones'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Victoria Broderick', 'Victoria', 'Broderick', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470404
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Victoria Broderick'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mike Cortese', 'Mike', 'Cortese', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470405
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mike Cortese'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Cliff Huffman', 'Cliff', 'Huffman', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470406
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Cliff Huffman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tim Lanier', 'Tim', 'Lanier', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470407
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tim Lanier'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joyce E. Neal', 'Joyce', 'E. Neal', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470408
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joyce E. Neal'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jacob Kristopher Anders', 'Jacob', 'Kristopher Anders', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470409
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jacob Kristopher Anders'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Clay Faircloth', 'Clay', 'Faircloth', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470410
WHERE d.geo_id = '4704' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Clay Faircloth'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andrew Ogles', 'Andrew', 'Ogles', true, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -47005
WHERE d.geo_id = '4705' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andrew Ogles'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Charlie Hatcher', 'Charlie', 'Hatcher', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470501
WHERE d.geo_id = '4705' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Charlie Hatcher'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Yolanda Cooper-Sutton', 'Yolanda', 'Cooper-Sutton', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470502
WHERE d.geo_id = '4705' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Yolanda Cooper-Sutton'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'DeVante R. Hill', 'DeVante', 'R. Hill', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470503
WHERE d.geo_id = '4705' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('DeVante R. Hill'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rachel Hurley', 'Rachel', 'Hurley', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470504
WHERE d.geo_id = '4705' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rachel Hurley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Carrie Ann Iacomini', 'Carrie', 'Ann Iacomini', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470505
WHERE d.geo_id = '4705' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Carrie Ann Iacomini'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chaz Molder', 'Chaz', 'Molder', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470506
WHERE d.geo_id = '4705' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chaz Molder'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James A. Johnson', 'James', 'A. Johnson', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470507
WHERE d.geo_id = '4705' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James A. Johnson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Micheál (Me-Haul) O''Leary', 'Micheál', '(Me-Haul) O''Leary', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470508
WHERE d.geo_id = '4705' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Micheál (Me-Haul) O''Leary'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Natisha Brooks', 'Natisha', 'Brooks', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470601
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Natisha Brooks'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Johnny Garrett', 'Johnny', 'Garrett', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470602
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Johnny Garrett'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jon Henry', 'Jon', 'Henry', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470603
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jon Henry'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Van Hilleary', 'Van', 'Hilleary', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470604
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Van Hilleary'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lore Bergman', 'Lore', 'Bergman', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470605
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lore Bergman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mike Croley', 'Mike', 'Croley', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470606
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mike Croley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christopher Martin Finley', 'Christopher', 'Martin Finley', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470607
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christopher Martin Finley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Miriam Leibowitz', 'Miriam', 'Leibowitz', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470608
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Miriam Leibowitz'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chaney Mosley', 'Chaney', 'Mosley', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470609
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chaney Mosley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christopher B. Monday', 'Christopher', 'B. Monday', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470610
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christopher B. Monday'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Angus Purdy', 'Angus', 'Purdy', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470611
WHERE d.geo_id = '4706' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Angus Purdy'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matt Van Epps', 'Matt', 'Van Epps', true, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -47007
WHERE d.geo_id = '4707' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matt Van Epps'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Darden Copeland', 'Darden', 'Copeland', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470701
WHERE d.geo_id = '4707' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Darden Copeland'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Vincent Dixie', 'Vincent', 'Dixie', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470702
WHERE d.geo_id = '4707' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Vincent Dixie'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Saletta Holloway', 'Saletta', 'Holloway', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470703
WHERE d.geo_id = '4707' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Saletta Holloway'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joshua Warren Sales', 'Joshua', 'Warren Sales', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470704
WHERE d.geo_id = '4707' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joshua Warren Sales'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andrew J. Koontz', 'Andrew', 'J. Koontz', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470705
WHERE d.geo_id = '4707' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andrew J. Koontz'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lowell Reynolds', 'Lowell', 'Reynolds', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470706
WHERE d.geo_id = '4707' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lowell Reynolds'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David Kustoff', 'David', 'Kustoff', true, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -47008
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('David Kustoff'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dewey Gordon Bryan', 'Dewey', 'Gordon Bryan', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470801
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dewey Gordon Bryan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jordan D. Hinders', 'Jordan', 'D. Hinders', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470802
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jordan D. Hinders'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Heidi Kuhn', 'Heidi', 'Kuhn', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470803
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Heidi Kuhn'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Leonard Perkins', 'Leonard', 'Perkins', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470804
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Leonard Perkins'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Adam D. Austill', 'Adam', 'D. Austill', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470805
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Adam D. Austill'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Wendell "Wells" Blankenship', 'Wendell', '"Wells" Blankenship', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470806
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Wendell "Wells" Blankenship'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Antonio Futch', 'Antonio', 'Futch', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470807
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Antonio Futch'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Pamela Jeanine "P." Moses', 'Pamela', 'Jeanine "P." Moses', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470808
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Pamela Jeanine "P." Moses'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Horace Taylor', 'Horace', 'Taylor', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470809
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Horace Taylor'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Henry J. Ward, III', 'Henry', 'J. Ward, III', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470810
WHERE d.geo_id = '4708' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Henry J. Ward, III'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Charlotte Bergmann', 'Charlotte', 'Bergmann', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470901
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Charlotte Bergmann'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brent Taylor', 'Brent', 'Taylor', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470902
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brent Taylor'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jeremy Thompson', 'Jeremy', 'Thompson', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470903
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jeremy Thompson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Todd Warner', 'Todd', 'Warner', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470904
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Todd Warner'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'M. LaTroy A-Williams', 'M.', 'LaTroy A-Williams', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470905
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('M. LaTroy A-Williams'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'London Lamar', 'London', 'Lamar', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470906
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('London Lamar'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Justin J. Pearson', 'Justin', 'J. Pearson', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470907
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Justin J. Pearson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jim Torino', 'Jim', 'Torino', false, 'active', 'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list May 29, 2026), cross-checked Ballotpedia'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470908
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jim Torino'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dennis Clark', 'Dennis', 'Clark', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470909
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dennis Clark'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michelle Davis Head', 'Michelle', 'Davis Head', false, 'active', 'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, cull >= 2026-08-07'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -470910
WHERE d.geo_id = '4709' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michelle Davis Head'));

COMMIT;
