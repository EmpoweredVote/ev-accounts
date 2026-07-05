-- 1223_seed_co_2026_house_candidates.sql
-- Phase 163-03 Task 2: 9 new CO politicians + 16 active race_candidates
--   onto the 8 CO 2026 Statewide General races. Reuse 7 renominated incumbents by external_id;
--   CO-1 Diana DeGette (-8001) LOST her June-30 primary to Melat Kiros -> NO active row
--   (open-seat convention, mirrors AZ-1/AZ-5, MN-2 Craig, WI-7 Tiffany) -- she remains the sitting
--   Rep until Jan 2027 (politicians/offices rows + 19 stances untouched) but is not a CO-1
--   general-election candidate. ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p163.csv CO rows, from Wikipedia 2026 US House elections in Colorado.
BEGIN;

-- 9 new challenger records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -80101, 'Melat Kiros', 'Melat', 'Kiros', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -80101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -80102, 'Christy Peterson', 'Christy', 'Peterson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -80102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -80201, 'Kelley Dennison', 'Kelley', 'Dennison', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -80201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -80301, 'Dwayne Romero', 'Dwayne', 'Romero', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -80301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -80401, 'Eileen Laubacher', 'Eileen', 'Laubacher', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -80401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -80501, 'Jessica Killin', 'Jessica', 'Killin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -80501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -80601, 'Jason Clark', 'Jason', 'Clark', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -80601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -80701, 'Tim Bennett', 'Tim', 'Bennett', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -80701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -80801, 'Manny Rutinel', 'Manny', 'Rutinel', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -80801);

-- 16 active race_candidates (7 incumbents reused + 9 new; DeGette excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Melat Kiros', 'Melat', 'Kiros', false, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -80101
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0801'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Melat Kiros'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christy Peterson', 'Christy', 'Peterson', false, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -80102
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0801'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christy Peterson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joe Neguse', 'Joe', 'Neguse', true, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -8002
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0802'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joe Neguse'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kelley Dennison', 'Kelley', 'Dennison', false, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -80201
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0802'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kelley Dennison'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jeff Hurd', 'Jeff', 'Hurd', true, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -8003
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0803'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jeff Hurd'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dwayne Romero', 'Dwayne', 'Romero', false, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -80301
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0803'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dwayne Romero'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lauren Boebert', 'Lauren', 'Boebert', true, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -8004
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0804'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lauren Boebert'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eileen Laubacher', 'Eileen', 'Laubacher', false, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -80401
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0804'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Eileen Laubacher'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jeff Crank', 'Jeff', 'Crank', true, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -8005
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0805'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jeff Crank'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jessica Killin', 'Jessica', 'Killin', false, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -80501
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0805'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jessica Killin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jason Crow', 'Jason', 'Crow', true, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -8006
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0806'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jason Crow'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jason Clark', 'Jason', 'Clark', false, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -80601
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0806'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jason Clark'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brittany Pettersen', 'Brittany', 'Pettersen', true, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -8007
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0807'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brittany Pettersen'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tim Bennett', 'Tim', 'Bennett', false, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -80701
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0807'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tim Bennett'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gabe Evans', 'Gabe', 'Evans', true, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -8008
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0808'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gabe Evans'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Manny Rutinel', 'Manny', 'Rutinel', false, 'active', '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -80801
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = '0808'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Manny Rutinel'));

COMMIT;
