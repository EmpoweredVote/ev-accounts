-- 1227_seed_al_2026_house_candidates.sql
-- Phase 163-04 Task 2: 21 new AL politicians + 27 active race_candidates
--   onto the 7 AL 2026 House races (6 general + 1 withheld "Polygon Pending" AL-2, per 163-01 routing).
--   Reuse 6 renominated incumbents by external_id; AL-1 Barry Moore (-1001, retired->Senate) -> NO
--   active row (open-seat convention, mirrors WI-7/CO-1/SC-1/SC-5). race_candidates inserts join by
--   district geo_id (not election name), so AL-2's severe-district candidates are wired identically
--   regardless of the election-visibility substitution -- seeding is complete for AL-2 even though its
--   race does not surface on /elections. ANTIPARTISAN: party never stored; offices untouched.
--   Field: 160-field-table-p163.csv AL rows, Wikipedia 2026 US House elections in Alabama.
BEGIN;

-- 21 new challenger/open-seat records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10101, 'Lucas Burger', 'Lucas', 'Burger', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10102, 'Jerry Carl', 'Jerry', 'Carl', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10103, 'John Mills', 'John', 'Mills', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10104, 'Austin Sidwell', 'Austin', 'Sidwell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10105, 'Clyde Jones', 'Clyde', 'Jones', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10201, 'Hampton Harris', 'Hampton', 'Harris', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10202, 'Christian Horn', 'Christian', 'Horn', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10203, 'Rhett Marques', 'Rhett', 'Marques', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10204, 'David Matthews', 'David', 'Matthews', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10204);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10205, 'Joshua McKee', 'Joshua', 'McKee', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10205);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10206, 'James Richardson', 'James', 'Richardson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10206);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10301, 'Lee McInnis', 'Lee', 'McInnis', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10401, 'Amanda Pusczek', 'Amanda', 'Pusczek', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10501, 'Andrew Sneed', 'Andrew', 'Sneed', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10601, 'Case Dixon', 'Case', 'Dixon', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10602, 'Jacob Bouma-Sims', 'Jacob', 'Bouma-Sims', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10603, 'Ashtyn Kennedy', 'Ashtyn', 'Kennedy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10604, 'Maurice Mercer', 'Maurice', 'Mercer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10604);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10605, 'Keith Pilkington', 'Keith', 'Pilkington', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10605);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10701, 'Ammie Akin', 'Ammie', 'Akin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -10702, 'David Perry', 'David', 'Perry', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -10702);

-- 27 active race_candidates (6 incumbents reused + 21 new; Moore excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lucas Burger', 'Lucas', 'Burger', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10101
WHERE d.geo_id = '0101' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lucas Burger'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jerry Carl', 'Jerry', 'Carl', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10102
WHERE d.geo_id = '0101' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jerry Carl'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Mills', 'John', 'Mills', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10103
WHERE d.geo_id = '0101' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Mills'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Austin Sidwell', 'Austin', 'Sidwell', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10104
WHERE d.geo_id = '0101' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Austin Sidwell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Clyde Jones', 'Clyde', 'Jones', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10105
WHERE d.geo_id = '0101' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Clyde Jones'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Shomari Figures', 'Shomari', 'Figures', true, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -1002
WHERE d.geo_id = '0102' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Shomari Figures'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Hampton Harris', 'Hampton', 'Harris', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10201
WHERE d.geo_id = '0102' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Hampton Harris'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christian Horn', 'Christian', 'Horn', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10202
WHERE d.geo_id = '0102' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christian Horn'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rhett Marques', 'Rhett', 'Marques', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10203
WHERE d.geo_id = '0102' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rhett Marques'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David Matthews', 'David', 'Matthews', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10204
WHERE d.geo_id = '0102' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('David Matthews'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joshua McKee', 'Joshua', 'McKee', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10205
WHERE d.geo_id = '0102' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joshua McKee'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James Richardson', 'James', 'Richardson', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10206
WHERE d.geo_id = '0102' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James Richardson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mike Rogers', 'Mike', 'Rogers', true, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -1003
WHERE d.geo_id = '0103' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mike Rogers'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lee McInnis', 'Lee', 'McInnis', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10301
WHERE d.geo_id = '0103' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lee McInnis'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Robert Aderholt', 'Robert', 'Aderholt', true, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -1004
WHERE d.geo_id = '0104' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Robert Aderholt'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Amanda Pusczek', 'Amanda', 'Pusczek', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10401
WHERE d.geo_id = '0104' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Amanda Pusczek'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dale Strong', 'Dale', 'Strong', true, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -1005
WHERE d.geo_id = '0105' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dale Strong'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andrew Sneed', 'Andrew', 'Sneed', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10501
WHERE d.geo_id = '0105' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andrew Sneed'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gary Palmer', 'Gary', 'Palmer', true, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -1006
WHERE d.geo_id = '0106' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gary Palmer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Case Dixon', 'Case', 'Dixon', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10601
WHERE d.geo_id = '0106' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Case Dixon'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jacob Bouma-Sims', 'Jacob', 'Bouma-Sims', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10602
WHERE d.geo_id = '0106' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jacob Bouma-Sims'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ashtyn Kennedy', 'Ashtyn', 'Kennedy', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10603
WHERE d.geo_id = '0106' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ashtyn Kennedy'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Maurice Mercer', 'Maurice', 'Mercer', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10604
WHERE d.geo_id = '0106' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Maurice Mercer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Keith Pilkington', 'Keith', 'Pilkington', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10605
WHERE d.geo_id = '0106' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Keith Pilkington'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Terri Sewell', 'Terri', 'Sewell', true, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -1007
WHERE d.geo_id = '0107' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Terri Sewell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ammie Akin', 'Ammie', 'Akin', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10701
WHERE d.geo_id = '0107' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ammie Akin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David Perry', 'David', 'Perry', false, 'active', '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; AL-3/4/5 decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -10702
WHERE d.geo_id = '0107' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('David Perry'));

COMMIT;
