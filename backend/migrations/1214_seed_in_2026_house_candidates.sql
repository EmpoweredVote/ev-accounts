-- 1214_seed_in_2026_house_candidates.sql
-- Phase 162-07 Task 2: IN 2026 general field wiring. Per operator dedup decision (2026-07-04):
--   7 REUSE existing records (assign -180xxx external_ids), 5 NEW records, deactivate
--   2 junk duplicate "Brad Meyer" orphans. 9 incumbents reused by existing external_id (mixed
--   -18nnn + positive SoS ids). 21 active race_candidates total. ANTIPARTISAN: party never stored.
--   All statements guarded for idempotent 0-row re-apply.
BEGIN;

-- (a) assign band external_ids to the 7 reused discovery/bulk-seed records
UPDATE essentials.politicians SET external_id = -180202, is_active = true
WHERE id = 'cfca3142-3f46-4ff3-a77f-cbb2438929d8' AND external_id IS NULL;
UPDATE essentials.politicians SET external_id = -180301, is_active = true
WHERE id = 'e976e2c2-52c1-48c9-a5a6-4337d6740f71' AND external_id IS NULL;
UPDATE essentials.politicians SET external_id = -180501, is_active = true
WHERE id = 'ad47de71-253c-4710-976e-1d57b7787cae' AND external_id IS NULL;
UPDATE essentials.politicians SET external_id = -180601, is_active = true
WHERE id = '90342c06-b82a-4e86-8d89-152ab07a4c66' AND external_id IS NULL;
UPDATE essentials.politicians SET external_id = -180701, is_active = true
WHERE id = 'cda9e16f-b175-42ee-bc16-a8f110512392' AND external_id IS NULL;
UPDATE essentials.politicians SET external_id = -180901, is_active = true
WHERE id = '926943ad-ee64-4ddb-b9e7-6475a6a2d087' AND external_id IS NULL;
UPDATE essentials.politicians SET external_id = -180902, is_active = true
WHERE id = '8f08a551-71c8-43c4-9bcc-b18fd3ac0abc' AND external_id IS NULL;

-- (b) deactivate 2 junk duplicate "Brad Meyer" orphans
UPDATE essentials.politicians SET is_active = false WHERE id = '32d8cc05-7780-455a-8771-d3024c00522c' AND is_active = true;
UPDATE essentials.politicians SET is_active = false WHERE id = '9d124770-3beb-468f-89de-a56f2267b16e' AND is_active = true;

-- (c) 5 genuinely-new challenger records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -180101, 'Barb Regnitz', 'Barb', 'Regnitz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -180101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -180201, 'Jamee Decio', 'Jamee', 'Decio', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -180201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -180401, 'Drew Cox', 'Drew', 'Cox', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -180401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -180702, 'James Sceniak', 'James', 'Sceniak', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -180702);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -180801, 'Mary Allen', 'Mary', 'Allen', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -180801);

-- (d) 21 active race_candidates (12 challengers + 9 incumbents; join by external_id)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Frank Mrvan', 'Frank', 'Mrvan', true, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -18001
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1801'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Frank Mrvan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Barb Regnitz', 'Barb', 'Regnitz', false, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180101
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1801'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Barb Regnitz'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rudy Yakym III', 'Rudy', 'Yakym III', true, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -18002
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1802'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rudy Yakym III'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jamee Decio', 'Jamee', 'Decio', false, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180201
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1802'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jamee Decio'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'William Henry', 'William', 'Henry', false, 'active', 'IN SoS 2026 filings, declared minor-party/independent (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180202
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1802'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('William Henry'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Marlin Stutzman', 'Marlin', 'Stutzman', true, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -18003
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1803'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Marlin Stutzman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kelly Thompson', 'Kelly', 'Thompson', false, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180301
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1803'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Kelly Thompson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jim Baird', 'Jim', 'Baird', true, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = 499386
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1804'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jim Baird'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Drew Cox', 'Drew', 'Cox', false, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180401
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1804'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Drew Cox'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Victoria Spartz', 'Victoria', 'Spartz', true, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -18005
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1805'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Victoria Spartz'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'J.D. Ford', 'J.D.', 'Ford', false, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180501
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1805'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('J.D. Ford'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jefferson Shreve', 'Jefferson', 'Shreve', true, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -18006
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1806'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jefferson Shreve'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Cinde Wirth', 'Cinde', 'Wirth', false, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180601
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1806'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Cinde Wirth'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'André Carson', 'André', 'Carson', true, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = 499408
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1807'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('André Carson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Patrick McAuley', 'Patrick', 'McAuley', false, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180701
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1807'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Patrick McAuley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James Sceniak', 'James', 'Sceniak', false, 'active', 'IN SoS 2026 filings, declared minor-party/independent (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180702
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1807'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James Sceniak'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mark Messmer', 'Mark', 'Messmer', true, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = 499413
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1808'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mark Messmer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mary Allen', 'Mary', 'Allen', false, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180801
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1808'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mary Allen'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Erin Houchin', 'Erin', 'Houchin', true, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = 499417
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1809'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Erin Houchin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brad Meyer', 'Brad', 'Meyer', false, 'active', 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180901
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1809'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Brad Meyer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tonya Hudson', 'Tonya', 'Hudson', false, 'active', 'IN SoS 2026 filings, declared minor-party/independent (decided field, May-5 primary)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -180902
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = '1809'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tonya Hudson'));

COMMIT;
