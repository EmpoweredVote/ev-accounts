-- 1232_seed_ks_2026_house_candidates.sql
-- Phase 164-01 Task 2: 22 new KS politicians + 26 active race_candidates
--   onto the 4 KS 2026 Statewide General races. Reuse 4 renominated incumbents by external_id
--   (-20001 Mann / -20002 Schmidt / -20003 Davids / -20004 Estes). No open seats in KS.
--   external_id band -(20*10000+cd*100+seq); D-04 sub-bands KS-1 seq 3, KS-2 seq 10 (avoid 11
--   legacy MA records). ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p164.csv KS rows.
BEGIN;

-- 22 new challenger/minor-party/independent records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200103, 'Colin McRoberts', 'Colin', 'McRoberts', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200104, 'Lauren Reinhold', 'Lauren', 'Reinhold', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200105, 'Steven Jacob', 'Steven', 'Jacob', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200106, 'Craig Musser', 'Craig', 'Musser', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200106);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200210, 'Chad Young', 'Chad', 'Young', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200210);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200211, 'Don Coover', 'Don', 'Coover', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200211);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200212, 'Braeden Curwick', 'Braeden', 'Curwick', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200212);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200301, 'Sarah Preu', 'Sarah', 'Preu', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200302, 'Eric Jenkins', 'Eric', 'Jenkins', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200303, 'Chase LaPorte', 'Chase', 'LaPorte', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200303);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200304, 'Gavin Solomon', 'Gavin', 'Solomon', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200304);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200305, 'Blake Stanley', 'Blake', 'Stanley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200305);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200401, 'Michael Gaynor', 'Michael', 'Gaynor', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200402, 'Frank McCollum', 'Frank', 'McCollum', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200403, 'Chris Carmichael', 'Chris', 'Carmichael', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200403);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200404, 'Katy Tyndell', 'Katy', 'Tyndell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200404);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200405, 'Cole Epley', 'Cole', 'Epley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200405);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200406, 'Ryan Gilbert', 'Ryan', 'Gilbert', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200406);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200407, 'Jordan Mitchell', 'Jordan', 'Mitchell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200407);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200408, 'Daniel Schneider', 'Daniel', 'Schneider', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200408);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200409, 'Drew Cranmer', 'Drew', 'Cranmer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200409);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -200410, 'Paul Catanese', 'Paul', 'Catanese', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -200410);

-- 26 active race_candidates (4 incumbents reused + 22 new)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Tracey Mann', 'Tracey', 'Mann', true, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -20001
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2001'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Tracey Mann'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Colin McRoberts', 'Colin', 'McRoberts', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200103
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2001'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Colin McRoberts'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lauren Reinhold', 'Lauren', 'Reinhold', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200104
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2001'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Lauren Reinhold'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Steven Jacob', 'Steven', 'Jacob', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; minor-party/independent filing); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200105
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2001'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Steven Jacob'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Craig Musser', 'Craig', 'Musser', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; minor-party/independent filing); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200106
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2001'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Craig Musser'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Derek Schmidt', 'Derek', 'Schmidt', true, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -20002
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2002'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Derek Schmidt'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chad Young', 'Chad', 'Young', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200210
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2002'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chad Young'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Don Coover', 'Don', 'Coover', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200211
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2002'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Don Coover'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Braeden Curwick', 'Braeden', 'Curwick', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200212
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2002'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Braeden Curwick'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sharice Davids', 'Sharice', 'Davids', true, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -20003
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2003'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Sharice Davids'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sarah Preu', 'Sarah', 'Preu', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200301
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2003'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Sarah Preu'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eric Jenkins', 'Eric', 'Jenkins', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200302
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2003'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Eric Jenkins'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chase LaPorte', 'Chase', 'LaPorte', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200303
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2003'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chase LaPorte'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gavin Solomon', 'Gavin', 'Solomon', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200304
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2003'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Gavin Solomon'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Blake Stanley', 'Blake', 'Stanley', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200305
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2003'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Blake Stanley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ron Estes', 'Ron', 'Estes', true, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -20004
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ron Estes'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Gaynor', 'Michael', 'Gaynor', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200401
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Gaynor'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Frank McCollum', 'Frank', 'McCollum', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200402
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Frank McCollum'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Chris Carmichael', 'Chris', 'Carmichael', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200403
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Chris Carmichael'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Katy Tyndell', 'Katy', 'Tyndell', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200404
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Katy Tyndell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Cole Epley', 'Cole', 'Epley', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200405
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Cole Epley'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ryan Gilbert', 'Ryan', 'Gilbert', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200406
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ryan Gilbert'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jordan Mitchell', 'Jordan', 'Mitchell', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200407
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jordan Mitchell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Daniel Schneider', 'Daniel', 'Schneider', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200408
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Daniel Schneider'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Drew Cranmer', 'Drew', 'Cranmer', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; minor-party/independent filing); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200409
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Drew Cranmer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Paul Catanese', 'Paul', 'Catanese', false, 'active', 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; minor-party/independent filing); provisional pre-primary field, cull >= 2026-08-05'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -200410
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = '2004'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Paul Catanese'));

COMMIT;
