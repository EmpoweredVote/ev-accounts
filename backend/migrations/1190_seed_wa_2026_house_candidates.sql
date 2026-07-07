-- 1190_seed_wa_2026_house_candidates.sql
-- Phase 161-04 Task 2: 60 new WA politicians + 69 active race_candidates
--   onto the 10 WA 2026 Statewide General races. Reuse 9 renominated incumbents by external_id;
--   WA-4 Dan Newhouse (-53004) RETIRED -> NO active row (open-seat convention, mirrors
--   AZ-1/AZ-5 from Phase 161-02 and MI-10/MI-11 from Phase 159). ANTIPARTISAN: party never
--   stored; races untouched. Field: 160-field-table-p161.csv WA rows.
BEGIN;

-- 60 new challenger/open-seat/indep/minor-party records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530101, 'Benjamin Kincaid', 'Benjamin', 'Kincaid', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530102, 'Bryce Nickel', 'Bryce', 'Nickel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530103, 'James Etzkorn', 'James', 'Etzkorn', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530104, 'Hunter Gordon', 'Hunter', 'Gordon', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530105, 'Mary Silva', 'Mary', 'Silva', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530106, 'Catherine Hildebrand', 'Catherine', 'Hildebrand', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530106);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530201, 'Edwin H. Feller', 'Edwin', 'H. Feller', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530202, 'Tomas Scheel', 'Tomas', 'Scheel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530203, 'Devin Hermanson', 'Devin', 'Hermanson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530301, 'Brent Hennrich', 'Brent', 'Hennrich', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530302, 'John P. Roco', 'John', 'P. Roco', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530303, 'John Saulie-Rohman', 'John', 'Saulie-Rohman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530303);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530304, 'Troy Rasband', 'Troy', 'Rasband', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530304);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530305, 'John Braun', 'John', 'Braun', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530305);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530306, 'Antony Barran', 'Antony', 'Barran', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530306);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530307, 'Austin Braswell', 'Austin', 'Braswell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530307);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530308, 'Lawrence Kellogg', 'Lawrence', 'Kellogg', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530308);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530401, 'Jacek "Jack" Kobiesa', 'Jacek', '"Jack" Kobiesa', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530402, 'Amanda McKinney', 'Amanda', 'McKinney', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530403, 'John Duresky', 'John', 'Duresky', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530404, 'John C. Hughs', 'John', 'C. Hughs', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530405, 'Favian Valencia', 'Favian', 'Valencia', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530405);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530406, 'Jerrod Sessler', 'Jerrod', 'Sessler', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530406);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530407, 'Devin Poore', 'Devin', 'Poore', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530407);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530408, 'Ken Vaz', 'Ken', 'Vaz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530408);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530409, 'Zac Rossi', 'Zac', 'Rossi', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530409);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530410, 'Elpidia Saavedra', 'Elpidia', 'Saavedra', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530410);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530411, 'Matt Boehnke', 'Matt', 'Boehnke', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530411);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530501, 'Nate Powell', 'Nate', 'Powell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530502, 'Carmela Conroy', 'Carmela', 'Conroy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530503, 'Matthew Hayes', 'Matthew', 'Hayes', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530504, 'Bajun R. Mavalwalla', 'Bajun', 'R. Mavalwalla', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530504);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530505, 'Michael McGarr', 'Michael', 'McGarr', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530505);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530506, 'Kevin Fagan', 'Kevin', 'Fagan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530506);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530507, 'Kyle Usrey', 'Kyle', 'Usrey', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530507);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530508, 'Andrew Bartleson', 'Andrew', 'Bartleson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530508);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530509, 'Ann Marie Danimus', 'Ann', 'Marie Danimus', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530509);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530510, 'Richard Freudenberg', 'Richard', 'Freudenberg', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530510);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530511, 'David Womack', 'David', 'Womack', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530511);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530601, 'Brian P. O''Gorman', 'Brian', 'P. O''Gorman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530602, 'Teresa Fox', 'Teresa', 'Fox', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530603, 'Macy Jones', 'Macy', 'Jones', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530604, 'Leon Lawson', 'Leon', 'Lawson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530604);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530701, 'David W. Blomstrom', 'David', 'W. Blomstrom', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530702, 'Nirav Sheth', 'Nirav', 'Sheth', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530702);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530703, 'Gwen Kirkland', 'Gwen', 'Kirkland', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530703);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530801, 'Trinh Ha', 'Trinh', 'Ha', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530802, 'Spencer Meline', 'Spencer', 'Meline', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530802);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530803, 'Keith Arnold', 'Keith', 'Arnold', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530803);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530804, 'Andres Valleza', 'Andres', 'Valleza', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530804);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530805, 'Bob Hagglund', 'Bob', 'Hagglund', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530805);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530901, 'Jacob Perasso', 'Jacob', 'Perasso', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530901);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530902, 'Kshama Sawant', 'Kshama', 'Sawant', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530902);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530903, 'Melissa Chaudhry', 'Melissa', 'Chaudhry', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530903);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -530904, 'Doug Basler', 'Doug', 'Basler', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -530904);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -531001, 'Adam Arafat', 'Adam', 'Arafat', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -531001);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -531002, 'Kurtis Engle', 'Kurtis', 'Engle', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -531002);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -531003, 'Alex Scheel', 'Alex', 'Scheel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -531003);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -531004, 'Derek Maynes', 'Derek', 'Maynes', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -531004);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -531005, 'Chris D. Chung', 'Chris', 'D. Chung', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -531005);

-- 69 active race_candidates (9 incumbents reused + 60 new; Newhouse excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Suzan K. DelBene', 'Suzan', 'K. DelBene', true, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -53001
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5301'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Suzan K. DelBene'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Benjamin Kincaid', 'Benjamin', 'Kincaid', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530101
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5301'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Benjamin Kincaid'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bryce Nickel', 'Bryce', 'Nickel', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530102
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5301'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bryce Nickel'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James Etzkorn', 'James', 'Etzkorn', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530103
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5301'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James Etzkorn'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Hunter Gordon', 'Hunter', 'Gordon', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530104
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5301'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Hunter Gordon'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mary Silva', 'Mary', 'Silva', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530105
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5301'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mary Silva'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Catherine Hildebrand', 'Catherine', 'Hildebrand', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530106
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5301'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Catherine Hildebrand'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rick Larsen', 'Rick', 'Larsen', true, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -53002
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5302'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rick Larsen'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Edwin H. Feller', 'Edwin', 'H. Feller', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530201
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5302'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Edwin H. Feller'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tomas Scheel', 'Tomas', 'Scheel', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530202
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5302'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tomas Scheel'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Devin Hermanson', 'Devin', 'Hermanson', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530203
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5302'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Devin Hermanson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Marie Gluesenkamp Perez', 'Marie', 'Gluesenkamp Perez', true, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -53003
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5303'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Marie Gluesenkamp Perez'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brent Hennrich', 'Brent', 'Hennrich', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530301
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5303'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brent Hennrich'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John P. Roco', 'John', 'P. Roco', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530302
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5303'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John P. Roco'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Saulie-Rohman', 'John', 'Saulie-Rohman', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530303
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5303'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Saulie-Rohman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Troy Rasband', 'Troy', 'Rasband', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530304
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5303'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Troy Rasband'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Braun', 'John', 'Braun', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530305
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5303'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Braun'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Antony Barran', 'Antony', 'Barran', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530306
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5303'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Antony Barran'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Austin Braswell', 'Austin', 'Braswell', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530307
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5303'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Austin Braswell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lawrence Kellogg', 'Lawrence', 'Kellogg', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530308
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5303'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lawrence Kellogg'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jacek "Jack" Kobiesa', 'Jacek', '"Jack" Kobiesa', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530401
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jacek "Jack" Kobiesa'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Amanda McKinney', 'Amanda', 'McKinney', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530402
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Amanda McKinney'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Duresky', 'John', 'Duresky', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530403
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Duresky'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John C. Hughs', 'John', 'C. Hughs', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530404
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John C. Hughs'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Favian Valencia', 'Favian', 'Valencia', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530405
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Favian Valencia'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jerrod Sessler', 'Jerrod', 'Sessler', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530406
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jerrod Sessler'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Devin Poore', 'Devin', 'Poore', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530407
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Devin Poore'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ken Vaz', 'Ken', 'Vaz', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530408
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ken Vaz'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Zac Rossi', 'Zac', 'Rossi', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530409
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Zac Rossi'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Elpidia Saavedra', 'Elpidia', 'Saavedra', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530410
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Elpidia Saavedra'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matt Boehnke', 'Matt', 'Boehnke', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530411
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5304'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matt Boehnke'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Baumgartner', 'Michael', 'Baumgartner', true, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -53005
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Baumgartner'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nate Powell', 'Nate', 'Powell', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530501
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Nate Powell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Carmela Conroy', 'Carmela', 'Conroy', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530502
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Carmela Conroy'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matthew Hayes', 'Matthew', 'Hayes', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530503
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matthew Hayes'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bajun R. Mavalwalla', 'Bajun', 'R. Mavalwalla', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530504
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bajun R. Mavalwalla'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael McGarr', 'Michael', 'McGarr', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530505
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael McGarr'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kevin Fagan', 'Kevin', 'Fagan', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530506
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kevin Fagan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kyle Usrey', 'Kyle', 'Usrey', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530507
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kyle Usrey'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andrew Bartleson', 'Andrew', 'Bartleson', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530508
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andrew Bartleson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ann Marie Danimus', 'Ann', 'Marie Danimus', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530509
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ann Marie Danimus'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Richard Freudenberg', 'Richard', 'Freudenberg', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530510
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Richard Freudenberg'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David Womack', 'David', 'Womack', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530511
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5305'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('David Womack'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Emily Randall', 'Emily', 'Randall', true, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -53006
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5306'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Emily Randall'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brian P. O''Gorman', 'Brian', 'P. O''Gorman', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530601
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5306'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brian P. O''Gorman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Teresa Fox', 'Teresa', 'Fox', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530602
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5306'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Teresa Fox'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Macy Jones', 'Macy', 'Jones', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530603
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5306'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Macy Jones'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Leon Lawson', 'Leon', 'Lawson', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530604
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5306'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Leon Lawson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Pramila Jayapal', 'Pramila', 'Jayapal', true, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -53007
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5307'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Pramila Jayapal'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David W. Blomstrom', 'David', 'W. Blomstrom', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530701
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5307'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('David W. Blomstrom'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nirav Sheth', 'Nirav', 'Sheth', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530702
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5307'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Nirav Sheth'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gwen Kirkland', 'Gwen', 'Kirkland', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530703
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5307'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gwen Kirkland'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kim Schrier', 'Kim', 'Schrier', true, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -53008
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5308'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kim Schrier'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Trinh Ha', 'Trinh', 'Ha', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530801
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5308'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Trinh Ha'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Spencer Meline', 'Spencer', 'Meline', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530802
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5308'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Spencer Meline'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Keith Arnold', 'Keith', 'Arnold', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530803
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5308'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Keith Arnold'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andres Valleza', 'Andres', 'Valleza', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530804
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5308'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andres Valleza'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bob Hagglund', 'Bob', 'Hagglund', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530805
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5308'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bob Hagglund'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Adam Smith', 'Adam', 'Smith', true, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -53009
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5309'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Adam Smith'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jacob Perasso', 'Jacob', 'Perasso', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530901
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5309'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jacob Perasso'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kshama Sawant', 'Kshama', 'Sawant', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530902
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5309'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kshama Sawant'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Melissa Chaudhry', 'Melissa', 'Chaudhry', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530903
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5309'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Melissa Chaudhry'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Doug Basler', 'Doug', 'Basler', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -530904
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5309'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Doug Basler'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Marilyn Strickland', 'Marilyn', 'Strickland', true, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -53010
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5310'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Marilyn Strickland'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Adam Arafat', 'Adam', 'Arafat', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -531001
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5310'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Adam Arafat'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kurtis Engle', 'Kurtis', 'Engle', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -531002
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5310'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kurtis Engle'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Alex Scheel', 'Alex', 'Scheel', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -531003
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5310'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Alex Scheel'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Derek Maynes', 'Derek', 'Maynes', false, 'active', 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -531004
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5310'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Derek Maynes'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris D. Chung', 'Chris', 'D. Chung', false, 'active', 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -531005
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = '5310'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris D. Chung'));

COMMIT;
