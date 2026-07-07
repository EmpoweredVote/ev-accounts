-- 1225_seed_sc_2026_house_candidates.sql
-- Phase 163-05 Task 2: 16 new SC politicians + 21 active race_candidates
--   onto the 7 SC 2026 Statewide General races. Reuse 5 renominated incumbents by external_id;
--   SC-1 Nancy Mace (-45001) + SC-5 Ralph Norman (-45005) retired to run for Governor -> NO active
--   rows (open-seat convention, mirrors WI-7 Tiffany / CO-1 DeGette) -- they remain sitting Reps
--   until Jan 2027 (politicians/offices rows untouched) but are not 2026 general-election candidates.
--   ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p163.csv SC rows, from Wikipedia 2026 US House elections in South Carolina.
BEGIN;

-- 16 new challenger records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450101, 'Jenny Costa Honeycutt', 'Jenny', 'Costa Honeycutt', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450102, 'Nancy Lacore', 'Nancy', 'Lacore', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450103, 'Bill Reeside', 'Bill', 'Reeside', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450104, 'Margo Ellis', 'Margo', 'Ellis', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450201, 'Zyon Khalifa', 'Zyon', 'Khalifa', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450202, 'Dayna Alane Smith', 'Dayna', 'Alane Smith', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450301, 'Eunice Lehmacher', 'Eunice', 'Lehmacher', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450302, 'Brian Corriea', 'Brian', 'Corriea', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450401, 'Courtney McClain', 'Courtney', 'McClain', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450402, 'Jessica Ethridge', 'Jessica', 'Ethridge', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450501, 'Wes Climer', 'Wes', 'Climer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450502, 'Mallory Dittmer', 'Mallory', 'Dittmer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450503, 'Andy Kaplan', 'Andy', 'Kaplan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450601, 'John Peterson', 'John', 'Peterson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450602, 'Joseph Oddo', 'Joseph', 'Oddo', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -450701, 'John Vincent', 'John', 'Vincent', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -450701);

-- 21 active race_candidates (5 incumbents reused + 16 new; Mace + Norman excluded)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jenny Costa Honeycutt', 'Jenny', 'Costa Honeycutt', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450101
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jenny Costa Honeycutt'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nancy Lacore', 'Nancy', 'Lacore', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450102
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Nancy Lacore'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bill Reeside', 'Bill', 'Reeside', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450103
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bill Reeside'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Margo Ellis', 'Margo', 'Ellis', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450104
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4501'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Margo Ellis'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joe Wilson', 'Joe', 'Wilson', true, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -45002
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4502'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joe Wilson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Zyon Khalifa', 'Zyon', 'Khalifa', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450201
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4502'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Zyon Khalifa'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dayna Alane Smith', 'Dayna', 'Alane Smith', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450202
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4502'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Dayna Alane Smith'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sheri Biggs', 'Sheri', 'Biggs', true, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -45003
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Sheri Biggs'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eunice Lehmacher', 'Eunice', 'Lehmacher', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450301
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Eunice Lehmacher'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brian Corriea', 'Brian', 'Corriea', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450302
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4503'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brian Corriea'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'William R. Timmons IV', 'William', 'R. Timmons IV', true, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -45004
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('William R. Timmons IV'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Courtney McClain', 'Courtney', 'McClain', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450401
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Courtney McClain'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jessica Ethridge', 'Jessica', 'Ethridge', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450402
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4504'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jessica Ethridge'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Wes Climer', 'Wes', 'Climer', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450501
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4505'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Wes Climer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mallory Dittmer', 'Mallory', 'Dittmer', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450502
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4505'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mallory Dittmer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andy Kaplan', 'Andy', 'Kaplan', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450503
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4505'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andy Kaplan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James E. Clyburn', 'James', 'E. Clyburn', true, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -45006
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4506'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James E. Clyburn'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Peterson', 'John', 'Peterson', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450601
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4506'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Peterson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joseph Oddo', 'Joseph', 'Oddo', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450602
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4506'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joseph Oddo'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Russell Fry', 'Russell', 'Fry', true, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -45007
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4507'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Russell Fry'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John Vincent', 'John', 'Vincent', false, 'active', '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -450701
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = '4507'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John Vincent'));

COMMIT;
