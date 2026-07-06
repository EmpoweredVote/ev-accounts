-- 1234_seed_ct_2026_house_candidates.sql
-- Phase 164-02 Task 2: 17 new CT politicians + 22 active race_candidates
--   onto the 5 CT 2026 Statewide General races. Reuse 5 renominated/running incumbents by
--   external_id (-9001 Larson / -9002 Courtney / -9003 DeLauro / -9004 Himes / -9005 Hayes;
--   Larson is_incumbent reuse row = a genuine 4-way primary candidate, D-01). external_id band
--   -(9*10000+cd*100+seq), standard seq start 1. D-02 unconfirmed names all INCLUDED after a
--   directly-fetched re-verification (FEC + Ballotpedia): Bueno/Cerreta/Miressi/Botelho — Botelho
--   promoted HOLD->INCLUDE. ANTIPARTISAN: party never stored; races untouched.
BEGIN;

-- 17 new challenger/convention/petition records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90101, 'Luke Bronin', 'Luke', 'Bronin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90102, 'Jillian Gilchrest', 'Jillian', 'Gilchrest', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90103, 'Ruth Fortune', 'Ruth', 'Fortune', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90104, 'Amy Chai', 'Amy', 'Chai', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90201, 'George Austin', 'George', 'Austin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90301, 'Christopher Lancia', 'Christopher', 'Lancia', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90302, 'Rafael Irizarry', 'Rafael', 'Irizarry', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90303, 'Andrew Rice', 'Andrew', 'Rice', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90303);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90401, 'Michael Goldstein', 'Michael', 'Goldstein', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90402, 'Daniel Miressi', 'Daniel', 'Miressi', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90403, 'Luz Helena Bueno', 'Luz', 'Helena Bueno', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90404, 'Joseph Perez-Caputo', 'Joseph', 'Perez-Caputo', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90405, 'Damon Lawrence Cerreta', 'Damon', 'Lawrence Cerreta', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90405);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90501, 'Chris Shea', 'Chris', 'Shea', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90502, 'Jonathan De Barros', 'Jonathan', 'De Barros', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90503, 'Michele Botelho', 'Michele', 'Botelho', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -90504, 'Jackson Taddeo-Waite', 'Jackson', 'Taddeo-Waite', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -90504);

-- 22 active race_candidates (5 incumbents reused + 17 new)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John B. Larson', 'John', 'B. Larson', true, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -9001
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0901'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('John B. Larson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Luke Bronin', 'Luke', 'Bronin', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — Dem convention-endorsed nominee (beat Larson 214-204, May-11-2026 convention)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90101
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0901'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Luke Bronin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jillian Gilchrest', 'Jillian', 'Gilchrest', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — qualified at convention with 15%+ delegates'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90102
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0901'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jillian Gilchrest'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ruth Fortune', 'Ruth', 'Fortune', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — petitioned onto ballot with 3,743 signatures'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90103
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0901'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ruth Fortune'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Amy Chai', 'Amy', 'Chai', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — only GOP candidate, nominated by acclamation'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90104
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0901'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Amy Chai'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joe Courtney', 'Joe', 'Courtney', true, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -9002
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0902'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joe Courtney'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'George Austin', 'George', 'Austin', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — GOP convention-endorsed by acclamation, unopposed'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90201
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0902'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('George Austin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rosa L. DeLauro', 'Rosa', 'L. DeLauro', true, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -9003
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0903'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rosa L. DeLauro'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christopher Lancia', 'Christopher', 'Lancia', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — GOP convention-endorsed via roll call'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90301
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0903'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Christopher Lancia'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Rafael Irizarry', 'Rafael', 'Irizarry', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — qualified for primary at convention'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90302
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0903'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rafael Irizarry'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Andrew Rice', 'Andrew', 'Rice', false, 'active', 'CT 2026 US House field (petitioning independent / minor-party; FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — petitioning independent for general (eliminated at Dem convention)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90303
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0903'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Andrew Rice'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James A. Himes', 'James', 'A. Himes', true, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -9004
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0904'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('James A. Himes'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Goldstein', 'Michael', 'Goldstein', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — GOP convention-endorsed via roll call (FEC H6CT04143 status=C)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90401
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0904'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Goldstein'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Daniel Miressi', 'Daniel', 'Miressi', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — D-02 re-verified: qualified for primary at convention; FEC H6CT04150 status=C'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90402
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0904'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Daniel Miressi'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Luz Helena Bueno', 'Luz', 'Helena Bueno', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — D-02 re-verified: FEC Statement of Candidacy H6CT04176 filed 2026-04-08 (concrete signal, provisional-with-note)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90403
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0904'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Luz Helena Bueno'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Joseph Perez-Caputo', 'Joseph', 'Perez-Caputo', false, 'active', 'CT 2026 US House field (petitioning independent / minor-party; FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — eliminated at Dem convention (1.7%); running independent for general (FEC H6CT04127)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90404
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0904'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Joseph Perez-Caputo'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Damon Lawrence Cerreta', 'Damon', 'Lawrence Cerreta', false, 'active', 'CT 2026 US House field (petitioning independent / minor-party; FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — D-02 re-verified: FEC candidacy H0CT04237 (concrete signal, provisional-with-note)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90405
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0904'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Damon Lawrence Cerreta'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jahana Hayes', 'Jahana', 'Hayes', true, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -9005
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0905'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jahana Hayes'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Shea', 'Chris', 'Shea', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — GOP convention-endorsed via roll call (FEC H6CT05231 status=C)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90501
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0905'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris Shea'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jonathan De Barros', 'Jonathan', 'De Barros', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — qualified for primary at convention (FEC H6CT05223 status=C)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90502
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0905'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jonathan De Barros'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michele Botelho', 'Michele', 'Botelho', false, 'active', 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — D-02 re-verified HOLD->INCLUDE: FEC H2CT05230 status=C statutory + Ballotpedia lists her in the Aug-11 3-way GOP primary (supersedes stale May-16 two-way report)'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90503
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0905'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michele Botelho'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jackson Taddeo-Waite', 'Jackson', 'Taddeo-Waite', false, 'active', 'CT 2026 US House field (petitioning independent / minor-party; FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12 — former Dem convention candidate; filed FEC candidacy (H6CT05215) to run independent for general'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -90504
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = '0905'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jackson Taddeo-Waite'));

COMMIT;
