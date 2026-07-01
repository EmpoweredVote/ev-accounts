-- 1147_seed_mi_2026_house_candidates.sql
-- Phase 159-01 Task 2: 56 new MI politicians + 67 active race_candidates
--   onto the 13 MI 2026 Statewide General races. Reuse 11 incumbents by external_id;
--   MI-10 John James (-26010) + MI-11 Haley Stevens (-26011) VACATE -> NO active row (open-seat
--   convention, mirrors NJ-12 Watson Coleman). ANTIPARTISAN: party never stored; races untouched.
--   Field: MI BOE PRI-2026 report; declared indep/Green provisional (MI filing deadline 2026-07-16).
BEGIN;

-- 56 new challenger/open-seat/indep/Green records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260101, 'Callie Barr', 'Callie', 'Barr', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260102, 'Kyle Blomquist', 'Kyle', 'Blomquist', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260103, 'Wayne Stiles', 'Wayne', 'Stiles', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260104, 'Matthew DenOtter', 'Matthew', 'DenOtter', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260105, 'Justin Michal', 'Justin', 'Michal', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260106, 'Zebulon Featherly', 'Zebulon', 'Featherly', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260106);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260107, 'Thomas Latza', 'Thomas', 'Latza', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260107);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260201, 'Ben Ambrose', 'Ben', 'Ambrose', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260202, 'Jamie Hill', 'Jamie', 'Hill', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260203, 'Clyde Welford', 'Clyde', 'Welford', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260301, 'Ryan Cushman', 'Ryan', 'Cushman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260302, 'Terri DeBoer', 'Terri', 'DeBoer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260401, 'Diop Harris II', 'Diop', 'Harris II', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260402, 'Sean McCann', 'Sean', 'McCann', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260403, 'Philip Tanis', 'Philip', 'Tanis', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260501, 'Christian Vukasovich', 'Christian', 'Vukasovich', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260502, 'James Bronke', 'James', 'Bronke', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260601, 'Heather Smiley', 'Heather', 'Smiley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260602, 'Clyde Shabazz', 'Clyde', 'Shabazz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260701, 'Bridget Brink', 'Bridget', 'Brink', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260702, 'William Lawrence', 'William', 'Lawrence', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260702);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260703, 'Matt Maasdam', 'Matt', 'Maasdam', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260703);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260704, 'Muhammad Salman Rais', 'Muhammad', 'Salman Rais', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260704);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260705, 'Alexandra Prieditis', 'Alexandra', 'Prieditis', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260705);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260801, 'Amir Hassan', 'Amir', 'Hassan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260802, 'Al Lemmo', 'Al', 'Lemmo', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260802);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260803, 'Thomas J. Smith', 'Thomas', 'J. Smith', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260803);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260901, 'Ray Pooley', 'Ray', 'Pooley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260901);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260902, 'Jasen Cartwright', 'Jasen', 'Cartwright', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260902);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -260903, 'Fernando Valdez', 'Fernando', 'Valdez', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -260903);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261001, 'Eric Chung', 'Eric', 'Chung', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261001);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261002, 'Tim Greimel', 'Tim', 'Greimel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261002);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261003, 'Christina Bertrand Hines', 'Christina', 'Bertrand Hines', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261003);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261004, 'Michael Bouchard', 'Michael', 'Bouchard', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261004);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261005, 'Steffan Demetropoulos', 'Steffan', 'Demetropoulos', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261005);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261006, 'Justin Kirk', 'Justin', 'Kirk', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261006);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261007, 'Robert Lulgjuraj', 'Robert', 'Lulgjuraj', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261007);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261101, 'Stu Baker', 'Stu', 'Baker', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261102, 'Aisha Farooqi', 'Aisha', 'Farooqi', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261103, 'Jeremy Moss', 'Jeremy', 'Moss', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261104, 'Michelle Mary Murphy', 'Michelle', 'Mary Murphy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261105, 'John Paul Torres', 'John', 'Paul Torres', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261106, 'Don Ufford', 'Don', 'Ufford', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261106);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261107, 'Ethan Baker', 'Ethan', 'Baker', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261107);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261108, 'Tony J. Prieto', 'Tony', 'J. Prieto', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261108);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261201, 'Allen Downer', 'Allen', 'Downer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261202, 'Shanelle Jackson', 'Shanelle', 'Jackson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261203, 'Byron H. Nolen', 'Byron', 'H. Nolen', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261204, 'James D. Hooper', 'James', 'D. Hooper', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261204);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261301, 'John Goci', 'John', 'Goci', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261302, 'Donavan McKinney', 'Donavan', 'McKinney', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261303, 'Mary Waters', 'Mary', 'Waters', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261303);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261304, 'Martell D. Bivings', 'Martell', 'D. Bivings', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261304);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261305, 'Raphiel King', 'Raphiel', 'King', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261305);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261306, 'T.P. Nykoriak', 'T.P.', 'Nykoriak', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261306);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -261307, 'Maurice Morton', 'Maurice', 'Morton', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -261307);

-- 67 active race_candidates (11 incumbents reused + 56 new; James/Stevens excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jack Bergman', 'Jack', 'Bergman', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26001
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2601'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jack Bergman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Callie Barr', 'Callie', 'Barr', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260101
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2601'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Callie Barr'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kyle Blomquist', 'Kyle', 'Blomquist', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260102
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2601'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kyle Blomquist'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Wayne Stiles', 'Wayne', 'Stiles', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260103
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2601'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Wayne Stiles'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matthew DenOtter', 'Matthew', 'DenOtter', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260104
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2601'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matthew DenOtter'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Justin Michal', 'Justin', 'Michal', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260105
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2601'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Justin Michal'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Zebulon Featherly', 'Zebulon', 'Featherly', false, 'active', 'Declared indep/Green (politics1.com/mi.htm + Ballotpedia); provisional — MI filing deadline 2026-07-16'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260106
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2601'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Zebulon Featherly'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Thomas Latza', 'Thomas', 'Latza', false, 'active', 'Declared indep/Green (politics1.com/mi.htm + Ballotpedia); provisional — MI filing deadline 2026-07-16'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260107
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2601'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Thomas Latza'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John R. Moolenaar', 'John', 'R. Moolenaar', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26002
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2602'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John R. Moolenaar'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ben Ambrose', 'Ben', 'Ambrose', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260201
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2602'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ben Ambrose'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jamie Hill', 'Jamie', 'Hill', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260202
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2602'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jamie Hill'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Clyde Welford', 'Clyde', 'Welford', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260203
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2602'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Clyde Welford'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Hillary J. Scholten', 'Hillary', 'J. Scholten', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26003
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2603'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Hillary J. Scholten'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ryan Cushman', 'Ryan', 'Cushman', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260301
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2603'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ryan Cushman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Terri DeBoer', 'Terri', 'DeBoer', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260302
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2603'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Terri DeBoer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bill Huizenga', 'Bill', 'Huizenga', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26004
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2604'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bill Huizenga'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Diop Harris II', 'Diop', 'Harris II', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260401
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2604'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Diop Harris II'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sean McCann', 'Sean', 'McCann', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260402
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2604'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Sean McCann'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Philip Tanis', 'Philip', 'Tanis', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260403
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2604'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Philip Tanis'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tim Walberg', 'Tim', 'Walberg', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26005
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2605'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tim Walberg'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christian Vukasovich', 'Christian', 'Vukasovich', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260501
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2605'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christian Vukasovich'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James Bronke', 'James', 'Bronke', false, 'active', 'Declared indep/Green (politics1.com/mi.htm + Ballotpedia); provisional — MI filing deadline 2026-07-16'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260502
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2605'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James Bronke'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Debbie Dingell', 'Debbie', 'Dingell', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26006
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2606'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Debbie Dingell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Heather Smiley', 'Heather', 'Smiley', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260601
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2606'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Heather Smiley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Clyde Shabazz', 'Clyde', 'Shabazz', false, 'active', 'Declared indep/Green (politics1.com/mi.htm + Ballotpedia); provisional — MI filing deadline 2026-07-16'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260602
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2606'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Clyde Shabazz'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tom Barrett', 'Tom', 'Barrett', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26007
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2607'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tom Barrett'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bridget Brink', 'Bridget', 'Brink', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260701
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2607'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bridget Brink'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'William Lawrence', 'William', 'Lawrence', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260702
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2607'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('William Lawrence'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matt Maasdam', 'Matt', 'Maasdam', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260703
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2607'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Matt Maasdam'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Muhammad Salman Rais', 'Muhammad', 'Salman Rais', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260704
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2607'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Muhammad Salman Rais'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Alexandra Prieditis', 'Alexandra', 'Prieditis', false, 'active', 'Declared indep/Green (politics1.com/mi.htm + Ballotpedia); provisional — MI filing deadline 2026-07-16'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260705
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2607'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Alexandra Prieditis'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kristen McDonald Rivet', 'Kristen', 'McDonald Rivet', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26008
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2608'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kristen McDonald Rivet'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Amir Hassan', 'Amir', 'Hassan', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260801
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2608'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Amir Hassan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Al Lemmo', 'Al', 'Lemmo', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260802
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2608'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Al Lemmo'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Thomas J. Smith', 'Thomas', 'J. Smith', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260803
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2608'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Thomas J. Smith'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lisa C. McClain', 'Lisa', 'C. McClain', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26009
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2609'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lisa C. McClain'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ray Pooley', 'Ray', 'Pooley', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260901
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2609'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ray Pooley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jasen Cartwright', 'Jasen', 'Cartwright', false, 'active', 'Declared indep/Green (politics1.com/mi.htm + Ballotpedia); provisional — MI filing deadline 2026-07-16'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260902
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2609'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jasen Cartwright'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Fernando Valdez', 'Fernando', 'Valdez', false, 'active', 'Declared indep/Green (politics1.com/mi.htm + Ballotpedia); provisional — MI filing deadline 2026-07-16'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -260903
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2609'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Fernando Valdez'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eric Chung', 'Eric', 'Chung', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261001
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2610'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Eric Chung'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tim Greimel', 'Tim', 'Greimel', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261002
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2610'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tim Greimel'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christina Bertrand Hines', 'Christina', 'Bertrand Hines', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261003
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2610'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christina Bertrand Hines'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Bouchard', 'Michael', 'Bouchard', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261004
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2610'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Bouchard'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Steffan Demetropoulos', 'Steffan', 'Demetropoulos', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261005
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2610'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Steffan Demetropoulos'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Justin Kirk', 'Justin', 'Kirk', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261006
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2610'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Justin Kirk'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Robert Lulgjuraj', 'Robert', 'Lulgjuraj', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261007
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2610'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Robert Lulgjuraj'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Stu Baker', 'Stu', 'Baker', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261101
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2611'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Stu Baker'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Aisha Farooqi', 'Aisha', 'Farooqi', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261102
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2611'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Aisha Farooqi'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jeremy Moss', 'Jeremy', 'Moss', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261103
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2611'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jeremy Moss'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michelle Mary Murphy', 'Michelle', 'Mary Murphy', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261104
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2611'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michelle Mary Murphy'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Paul Torres', 'John', 'Paul Torres', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261105
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2611'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Paul Torres'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Don Ufford', 'Don', 'Ufford', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261106
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2611'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Don Ufford'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ethan Baker', 'Ethan', 'Baker', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261107
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2611'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ethan Baker'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tony J. Prieto', 'Tony', 'J. Prieto', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261108
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2611'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tony J. Prieto'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rashida Tlaib', 'Rashida', 'Tlaib', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26012
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2612'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rashida Tlaib'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Allen Downer', 'Allen', 'Downer', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261201
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2612'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Allen Downer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Shanelle Jackson', 'Shanelle', 'Jackson', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261202
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2612'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Shanelle Jackson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Byron H. Nolen', 'Byron', 'H. Nolen', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261203
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2612'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Byron H. Nolen'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James D. Hooper', 'James', 'D. Hooper', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261204
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2612'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James D. Hooper'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Shri Thanedar', 'Shri', 'Thanedar', true, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -26013
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2613'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Shri Thanedar'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Goci', 'John', 'Goci', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261301
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2613'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Goci'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Donavan McKinney', 'Donavan', 'McKinney', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261302
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2613'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Donavan McKinney'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mary Waters', 'Mary', 'Waters', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261303
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2613'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mary Waters'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Martell D. Bivings', 'Martell', 'D. Bivings', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261304
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2613'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Martell D. Bivings'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Raphiel King', 'Raphiel', 'King', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261305
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2613'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Raphiel King'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'T.P. Nykoriak', 'T.P.', 'Nykoriak', false, 'active', 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261306
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2613'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('T.P. Nykoriak'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Maurice Morton', 'Maurice', 'Morton', false, 'active', 'Declared indep/Green (politics1.com/mi.htm + Ballotpedia); provisional — MI filing deadline 2026-07-16'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -261307
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = '2613'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Maurice Morton'));

COMMIT;
