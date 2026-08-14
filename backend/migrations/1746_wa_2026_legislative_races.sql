-- 1746_wa_2026_legislative_races.sql
-- 122 WA legislative races on the existing "WA 2026 Statewide General" election:
-- 24 State Senate districts + 98 State Representative seats, with the FULL
-- pre-primary filed field (295 candidates).
--
-- WHICH SENATE DISTRICTS: read from the source, never inferred. WA senators
-- serve staggered 4-year terms, so only ~half the 49 districts appear on any
-- even-year ballot. The 24 on the 2026 ballot are:
--   6, 7, 8, 13, 15, 21, 26, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 42, 43, 44, 45, 46, 47, 48
-- All 98 House seats are up (2-year terms).
--
-- SOURCE: WA SoS candidate-filing CSV export for the 2026 primary
-- (voter.votewa.gov CandidateList e=898). The on-screen grid paginates at 100
-- rows of 1,108 — scraping it instead of exporting would have silently
-- truncated the field. Cross-checked against the official results feed at
-- results.votewa.gov, which reports the same 24 Senate + 98 House contests.
--
-- NOT YET CULLED. These are pre-primary rows: WA is a TOP-TWO primary, so a
-- major-party filer is exactly as provisional as an independent — only two
-- advance per race. provisional_until = 2026-08-24, matching the 69
-- congressional rows already on this election. The cull gates on the CERTIFIED
-- canvass, not on election-night numbers.
--
-- position_name must be distinct across the whole election (partial unique
-- indexes on (election_id, position_name)). WA's two-per-district House seats
-- make this sharp — Position 1 and Position 2 are separately labelled.
--
-- IDEMPOTENCY: this schema DOES have unique indexes here —
--   races_election_office_party_uniq (election_id, office_id, coalesce(primary_party,'~nonpartisan~'))
--   race_candidates_race_name_key_uniq (race_id, candidate_name_key(full_name))
-- NOT EXISTS is still used throughout so the file is safe to re-run and never
-- depends on inferring a partial index.
--
-- Office lookup keys on (geo_id, district_type, mtfcc, title): geo_id alone is
-- NOT unique in WA (53033 is King County, LD33 Senate and LD33 House at once),
-- and STATE_UPPER=G5210 / STATE_LOWER=G5220 is inverted vs a plain TIGER read.

-- WA House of Representatives Legislative District 1 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 1 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53001' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 1 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Davina Duerr',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Davina Duerr'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 1 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Davina Duerr'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Maggie Wang',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Maggie Wang'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 1 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Maggie Wang'));

-- WA House of Representatives Legislative District 1 Position 2  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 1 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53001' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 1 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jeff Lyon',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jeff Lyon'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 1 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jeff Lyon'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Shelley Kloba',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Shelley Kloba'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 1 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Shelley Kloba'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Cliff Moon',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Cliff Moon'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 1 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Cliff Moon'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jenne Alderks',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jenne Alderks'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 1 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jenne Alderks'));

-- WA House of Representatives Legislative District 2 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 2 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53002' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 2 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'William Dehnel',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'William Dehnel'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 2 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('William Dehnel'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Andrew Barkis',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Andrew Barkis'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 2 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Andrew Barkis'));

-- WA House of Representatives Legislative District 2 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 2 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53002' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 2 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Angela Taylor',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Angela Taylor'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 2 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Angela Taylor'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Martin L Miller',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Martin L Miller'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 2 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Martin L Miller'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Matt Marshall',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Matt Marshall'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 2 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Matt Marshall'));

-- WA House of Representatives Legislative District 3 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 3 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53003' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 3 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Natasha Hill',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Natasha Hill'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 3 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Natasha Hill'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'John Kness',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'John Kness'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 3 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('John Kness'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tony Kiepe',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tony Kiepe'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 3 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tony Kiepe'));

-- WA House of Representatives Legislative District 3 Position 2  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 3 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53003' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 3 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Natalie Poulson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Natalie Poulson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 3 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Natalie Poulson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Pam Kohlmeier',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Pam Kohlmeier'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 3 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Pam Kohlmeier'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Luc Jasmin III',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Luc Jasmin III'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 3 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Luc Jasmin III'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Donovan Arnold DeLeon',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Donovan Arnold DeLeon'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 3 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Donovan Arnold DeLeon'));

-- WA House of Representatives Legislative District 4 Position 1  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 4 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53004' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 4 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Trent Maier',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Trent Maier'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 4 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Trent Maier'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Hillary Q. Pham',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Hillary Q. Pham'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 4 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Hillary Q. Pham'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Debra Long',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Debra Long'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 4 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Debra Long'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'George Wagner',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'George Wagner'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 4 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('George Wagner'));

-- WA House of Representatives Legislative District 4 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 4 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53004' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 4 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Rob Chase',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Rob Chase'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 4 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Rob Chase'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Bob Curtis',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Bob Curtis'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 4 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Bob Curtis'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Rob Tupper',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Rob Tupper'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 4 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Rob Tupper'));

-- WA House of Representatives Legislative District 5 Position 1  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 5 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53005' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 5 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Topher Leritz',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Topher Leritz'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 5 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Topher Leritz'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Zach Hall',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Zach Hall'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 5 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Zach Hall'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Aimee Warmerdam',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Aimee Warmerdam'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 5 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Aimee Warmerdam'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Michelle Bennett',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Michelle Bennett'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 5 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Michelle Bennett'));

-- WA House of Representatives Legislative District 5 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 5 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53005' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 5 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Patrick Peacock',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Patrick Peacock'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 5 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Patrick Peacock'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Lisa Callan',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Lisa Callan'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 5 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Lisa Callan'));

-- WA House of Representatives Legislative District 6 Position 1  (7 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 6 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53006' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Sueann Davis',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Sueann Davis'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Sueann Davis'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Isaiah Paine',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Isaiah Paine'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Isaiah Paine'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Michaela Kelso',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Michaela Kelso'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Michaela Kelso'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jennifer Morton',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jennifer Morton'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jennifer Morton'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Nicolette Ocheltree',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Nicolette Ocheltree'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Nicolette Ocheltree'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Alan Nolan',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Alan Nolan'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Alan Nolan'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Julia Payne',
       (p.id IS NOT NULL), 'withdrawn', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Julia Payne'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Julia Payne'));

-- WA House of Representatives Legislative District 6 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 6 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53006' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jonathan Bingle',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jonathan Bingle'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jonathan Bingle'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Julia Payne',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Julia Payne'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Julia Payne'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Aaron M. Croft',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Aaron M. Croft'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 6 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Aaron M. Croft'));

-- WA House of Representatives Legislative District 7 Position 1  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 7 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53007' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 7 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Andrew Engell',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Andrew Engell'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 7 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Andrew Engell'));

-- WA House of Representatives Legislative District 7 Position 2  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 7 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53007' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 7 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Hunter Abell',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Hunter Abell'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 7 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Hunter Abell'));

-- WA House of Representatives Legislative District 8 Position 1  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 8 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53008' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 8 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Stephanie Barnard',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Stephanie Barnard'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 8 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Stephanie Barnard'));

-- WA House of Representatives Legislative District 8 Position 2  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 8 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53008' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 8 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'April Connors',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'April Connors'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 8 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('April Connors'));

-- WA House of Representatives Legislative District 9 Position 1  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 9 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53009' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 9 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Mary Dye',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Mary Dye'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 9 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Mary Dye'));

-- WA House of Representatives Legislative District 9 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 9 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53009' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 9 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Joe Schmick',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Joe Schmick'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 9 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Joe Schmick'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Karina Wallace',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Karina Wallace'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 9 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Karina Wallace'));

-- WA House of Representatives Legislative District 10 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 10 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53010' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 10 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Clyde Shavers',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Clyde Shavers'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 10 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Clyde Shavers'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Robert (Chili) Hicks',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Robert (Chili) Hicks'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 10 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Robert (Chili) Hicks'));

-- WA House of Representatives Legislative District 10 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 10 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53010' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 10 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Carrie R. Kennedy',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Carrie R. Kennedy'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 10 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Carrie R. Kennedy'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Dave Paul',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Dave Paul'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 10 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Dave Paul'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tim Hazelo',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tim Hazelo'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 10 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tim Hazelo'));

-- WA House of Representatives Legislative District 11 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 11 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53011' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 11 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ashley Fedan',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ashley Fedan'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 11 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ashley Fedan'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Christian Rombough',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Christian Rombough'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 11 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Christian Rombough'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'David Hackney',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'David Hackney'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 11 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('David Hackney'));

-- WA House of Representatives Legislative District 11 Position 2  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 11 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53011' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 11 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Steve Bergquist',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Steve Bergquist'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 11 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Steve Bergquist'));

-- WA House of Representatives Legislative District 12 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 12 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53012' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 12 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Brian Burnett',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Brian Burnett'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 12 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Brian Burnett'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Stacy Willoughby',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Stacy Willoughby'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 12 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Stacy Willoughby'));

-- WA House of Representatives Legislative District 12 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 12 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53012' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 12 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Mike Steele',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Mike Steele'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 12 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Mike Steele'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Adam James',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Adam James'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 12 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Adam James'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Maggie Adams',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Maggie Adams'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 12 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Maggie Adams'));

-- WA House of Representatives Legislative District 13 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 13 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53013' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 13 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tom Dent',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tom Dent'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 13 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tom Dent'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Juan "Jerry" Garcia',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Juan "Jerry" Garcia'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 13 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Juan "Jerry" Garcia'));

-- WA House of Representatives Legislative District 13 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 13 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53013' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 13 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Deanna Martinez',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Deanna Martinez'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 13 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Deanna Martinez'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Joshua Thompson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Joshua Thompson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 13 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Joshua Thompson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Don Myers',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Don Myers'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 13 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Don Myers'));

-- WA House of Representatives Legislative District 14 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 14 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53014' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 14 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Chelsea Dimas',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Chelsea Dimas'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 14 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Chelsea Dimas'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'William Chichenoff',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'William Chichenoff'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 14 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('William Chichenoff'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Gloria Mendoza',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Gloria Mendoza'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 14 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Gloria Mendoza'));

-- WA House of Representatives Legislative District 14 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 14 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53014' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 14 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Deb Manjarrez',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Deb Manjarrez'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 14 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Deb Manjarrez'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tony G Sandoval',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tony G Sandoval'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 14 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tony G Sandoval'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ezequiel Morfin',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ezequiel Morfin'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 14 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ezequiel Morfin'));

-- WA House of Representatives Legislative District 15 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 15 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53015' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 15 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Chris Corry',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Chris Corry'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 15 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Chris Corry'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jack McEntire',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jack McEntire'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 15 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jack McEntire'));

-- WA House of Representatives Legislative District 15 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 15 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53015' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 15 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Reedy Berg',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Reedy Berg'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 15 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Reedy Berg'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Chase Foster',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Chase Foster'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 15 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Chase Foster'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Liz Hallock',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Liz Hallock'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 15 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Liz Hallock'));

-- WA House of Representatives Legislative District 16 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 16 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53016' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 16 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Mark Klicker',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Mark Klicker'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 16 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Mark Klicker'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kyle Palmer',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kyle Palmer'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 16 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kyle Palmer'));

-- WA House of Representatives Legislative District 16 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 16 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53016' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 16 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Skyler Rude',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Skyler Rude'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 16 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Skyler Rude'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Derek Sarley',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Derek Sarley'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 16 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Derek Sarley'));

-- WA House of Representatives Legislative District 17 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 17 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53017' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 17 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kevin Waters',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kevin Waters'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 17 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kevin Waters'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Thomas Everett Haynes',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Thomas Everett Haynes'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 17 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Thomas Everett Haynes'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ben Christly',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ben Christly'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 17 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ben Christly'));

-- WA House of Representatives Legislative District 17 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 17 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53017' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 17 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Diana H. Perez',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Diana H. Perez'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 17 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Diana H. Perez'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'David Stuebe',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'David Stuebe'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 17 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('David Stuebe'));

-- WA House of Representatives Legislative District 18 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 18 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53018' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 18 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Stephanie McClintock',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Stephanie McClintock'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 18 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Stephanie McClintock'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Randi L. Knott',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Randi L. Knott'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 18 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Randi L. Knott'));

-- WA House of Representatives Legislative District 18 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 18 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53018' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 18 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'John Ley',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'John Ley'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 18 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('John Ley'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Deken Letinich',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Deken Letinich'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 18 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Deken Letinich'));

-- WA House of Representatives Legislative District 19 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 19 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53019' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 19 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jim Walsh',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jim Walsh'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 19 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jim Walsh'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kevin Moynihan',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kevin Moynihan'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 19 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kevin Moynihan'));

-- WA House of Representatives Legislative District 19 Position 2  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 19 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53019' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 19 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Daniel William Bradley',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Daniel William Bradley'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 19 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Daniel William Bradley'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jimi O''Hagan',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jimi O''Hagan'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 19 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jimi O''Hagan'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Terry Carlson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Terry Carlson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 19 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Terry Carlson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Joel McEntire',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Joel McEntire'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 19 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Joel McEntire'));

-- WA House of Representatives Legislative District 20 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 20 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53020' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 20 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Peter Abbarno',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Peter Abbarno'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 20 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Peter Abbarno'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Andy Zahn',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Andy Zahn'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 20 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Andy Zahn'));

-- WA House of Representatives Legislative District 20 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 20 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53020' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 20 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Evan Jones',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Evan Jones'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 20 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Evan Jones'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ed Orcutt',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ed Orcutt'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 20 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ed Orcutt'));

-- WA House of Representatives Legislative District 21 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 21 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53021' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 21 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jason Moon',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jason Moon'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 21 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jason Moon'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Strom Peterson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Strom Peterson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 21 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Strom Peterson'));

-- WA House of Representatives Legislative District 21 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 21 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53021' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 21 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Lillian Ortiz-Self',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Lillian Ortiz-Self'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 21 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Lillian Ortiz-Self'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Bruce Guthrie',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Bruce Guthrie'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 21 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Bruce Guthrie'));

-- WA House of Representatives Legislative District 22 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 22 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53022' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 22 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Beth Doglio',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Beth Doglio'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 22 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Beth Doglio'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Don Hewett',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Don Hewett'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 22 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Don Hewett'));

-- WA House of Representatives Legislative District 22 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 22 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53022' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 22 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Lisa Parshley',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Lisa Parshley'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 22 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Lisa Parshley'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jamie Keenan-deVargas',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jamie Keenan-deVargas'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 22 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jamie Keenan-deVargas'));

-- WA House of Representatives Legislative District 23 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 23 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53023' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 23 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Daria Ilgen',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Daria Ilgen'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 23 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Daria Ilgen'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tarra Simmons',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tarra Simmons'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 23 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tarra Simmons'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Joel Ard',
       (p.id IS NOT NULL), 'withdrawn', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Joel Ard'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 23 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Joel Ard'));

-- WA House of Representatives Legislative District 23 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 23 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53023' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 23 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Greg Nance',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Greg Nance'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 23 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Greg Nance'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Lance Byrd',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Lance Byrd'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 23 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Lance Byrd'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kristin Lillegard',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kristin Lillegard'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 23 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kristin Lillegard'));

-- WA House of Representatives Legislative District 24 Position 1  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 24 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53024' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Eric W. Pratt',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Eric W. Pratt'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Eric W. Pratt'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ted Bowen',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ted Bowen'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ted Bowen'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Adam Bernbaum',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Adam Bernbaum'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Adam Bernbaum'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Aiden I.R. Hamilton',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Aiden I.R. Hamilton'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Aiden I.R. Hamilton'));

-- WA House of Representatives Legislative District 24 Position 2  (5 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 24 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53024' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Bradley Nemo Callaway',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Bradley Nemo Callaway'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Bradley Nemo Callaway'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Patrick DePoe',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Patrick DePoe'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Patrick DePoe'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kaylee Kuehn',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kaylee Kuehn'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kaylee Kuehn'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Mark Hodgson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Mark Hodgson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Mark Hodgson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Marcia Kelbon',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Marcia Kelbon'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 24 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Marcia Kelbon'));

-- WA House of Representatives Legislative District 25 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 25 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53025' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 25 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'David Berg',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'David Berg'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 25 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('David Berg'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Nick Oloo',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Nick Oloo'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 25 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Nick Oloo'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Michael Keaton',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Michael Keaton'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 25 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Michael Keaton'));

-- WA House of Representatives Legislative District 25 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 25 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53025' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 25 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jenn Marie Strickling',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jenn Marie Strickling'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 25 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jenn Marie Strickling'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ren Fanony',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ren Fanony'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 25 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ren Fanony'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Cyndy Jacobsen',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Cyndy Jacobsen'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 25 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Cyndy Jacobsen'));

-- WA House of Representatives Legislative District 26 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 26 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53026' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 26 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'David Olson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'David Olson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 26 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('David Olson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Natalie Bornfleth',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Natalie Bornfleth'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 26 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Natalie Bornfleth'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Adison Richards',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Adison Richards'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 26 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Adison Richards'));

-- WA House of Representatives Legislative District 26 Position 2  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 26 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53026' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 26 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Randy Phillips',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Randy Phillips'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 26 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Randy Phillips'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tedd Wetherbee',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tedd Wetherbee'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 26 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tedd Wetherbee'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Renee Hernandez Greenfield',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Renee Hernandez Greenfield'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 26 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Renee Hernandez Greenfield'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Katy Cornell',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Katy Cornell'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 26 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Katy Cornell'));

-- WA House of Representatives Legislative District 27 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 27 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53027' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 27 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Laurie Jinkins',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Laurie Jinkins'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 27 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Laurie Jinkins'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Carole Sue Braaten',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Carole Sue Braaten'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 27 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Carole Sue Braaten'));

-- WA House of Representatives Legislative District 27 Position 2  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 27 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53027' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 27 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jake Fey',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jake Fey'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 27 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jake Fey'));

-- WA House of Representatives Legislative District 28 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 28 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53028' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 28 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Mari Leavitt',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Mari Leavitt'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 28 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Mari Leavitt'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kathy Richardson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kathy Richardson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 28 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kathy Richardson'));

-- WA House of Representatives Legislative District 28 Position 2  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 28 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53028' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 28 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Dan Bronoske',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Dan Bronoske'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 28 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Dan Bronoske'));

-- WA House of Representatives Legislative District 29 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 29 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53029' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Melanie Morgan',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Melanie Morgan'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Melanie Morgan'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Brett Johnson',
       (p.id IS NOT NULL), 'withdrawn', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Brett Johnson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Brett Johnson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Krista Perez',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Krista Perez'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Krista Perez'));

-- WA House of Representatives Legislative District 29 Position 2  (6 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 29 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53029' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Darek Blum',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Darek Blum'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Darek Blum'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Patrick Stickney',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Patrick Stickney'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Patrick Stickney'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Erin Chapman-Smith',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Erin Chapman-Smith'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Erin Chapman-Smith'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Natasha Laitila',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Natasha Laitila'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Natasha Laitila'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Sheri Hayes',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Sheri Hayes'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Sheri Hayes'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Joe Bushnell',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Joe Bushnell'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 29 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Joe Bushnell'));

-- WA House of Representatives Legislative District 30 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 30 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53030' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 30 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jamila E. Taylor',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jamila E. Taylor'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 30 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jamila E. Taylor'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tiffany Bowyer',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tiffany Bowyer'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 30 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tiffany Bowyer'));

-- WA House of Representatives Legislative District 30 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 30 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53030' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 30 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kristine Reeves',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kristine Reeves'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 30 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kristine Reeves'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Paul McDaniel',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Paul McDaniel'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 30 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Paul McDaniel'));

-- WA House of Representatives Legislative District 31 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 31 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53031' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 31 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Drew Stokesbary',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Drew Stokesbary'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 31 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Drew Stokesbary'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Stephen Szczurko-Walton',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Stephen Szczurko-Walton'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 31 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Stephen Szczurko-Walton'));

-- WA House of Representatives Legislative District 31 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 31 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53031' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 31 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'John Bielka',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'John Bielka'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 31 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('John Bielka'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Joshua Penner',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Joshua Penner'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 31 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Joshua Penner'));

-- WA House of Representatives Legislative District 32 Position 1  (6 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 32 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53032' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jenna Nand',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jenna Nand'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jenna Nand'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Will Chen',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Will Chen'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Will Chen'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Keith Scully',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Keith Scully'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Keith Scully'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Danica Noble',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Danica Noble'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Danica Noble'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Lisa Rezac',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Lisa Rezac'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Lisa Rezac'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Chris Bloomquist',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Chris Bloomquist'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Chris Bloomquist'));

-- WA House of Representatives Legislative District 32 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 32 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53032' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Lauren Davis',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Lauren Davis'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Lauren Davis'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Imraan Siddiqi',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Imraan Siddiqi'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 32 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Imraan Siddiqi'));

-- WA House of Representatives Legislative District 33 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 33 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53033' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 33 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Edwin Obras',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Edwin Obras'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 33 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Edwin Obras'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Darryl K. Jones',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Darryl K. Jones'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 33 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Darryl K. Jones'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Chris Martinez',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Chris Martinez'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 33 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Chris Martinez'));

-- WA House of Representatives Legislative District 33 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 33 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53033' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 33 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Mia Su-Ling Gregerson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Mia Su-Ling Gregerson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 33 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Mia Su-Ling Gregerson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Yuri Marinchik',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Yuri Marinchik'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 33 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Yuri Marinchik'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Alex Andrade',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Alex Andrade'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 33 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Alex Andrade'));

-- WA House of Representatives Legislative District 34 Position 1  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 34 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53034' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 34 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Brianna K. Thomas',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Brianna K. Thomas'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 34 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Brianna K. Thomas'));

-- WA House of Representatives Legislative District 34 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 34 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53034' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 34 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Joe Fitzgibbon',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Joe Fitzgibbon'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 34 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Joe Fitzgibbon'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Mary Anito',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Mary Anito'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 34 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Mary Anito'));

-- WA House of Representatives Legislative District 35 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 35 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53035' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 35 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Dan Griffey',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Dan Griffey'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 35 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Dan Griffey'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Shaena Garberich',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Shaena Garberich'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 35 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Shaena Garberich'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jim Pierson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jim Pierson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 35 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jim Pierson'));

-- WA House of Representatives Legislative District 35 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 35 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53035' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 35 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Travis Couture',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Travis Couture'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 35 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Travis Couture'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Maria Littlesun',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Maria Littlesun'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 35 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Maria Littlesun'));

-- WA House of Representatives Legislative District 36 Position 1  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 36 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53036' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 36 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Julia Grant Reed',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Julia Grant Reed'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 36 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Julia Grant Reed'));

-- WA House of Representatives Legislative District 36 Position 2  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 36 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53036' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 36 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Liz Berry',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Liz Berry'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 36 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Liz Berry'));

-- WA House of Representatives Legislative District 37 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 37 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53037' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 37 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Sharon Tomiko Santos',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Sharon Tomiko Santos'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 37 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Sharon Tomiko Santos'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kelabe Tewolde',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kelabe Tewolde'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 37 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kelabe Tewolde'));

-- WA House of Representatives Legislative District 37 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 37 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53037' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 37 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jaelynn Scott',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jaelynn Scott'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 37 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jaelynn Scott'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Evon McCorkle',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Evon McCorkle'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 37 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Evon McCorkle'));

-- WA House of Representatives Legislative District 38 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 38 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53038' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 38 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Julio Cortes',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Julio Cortes'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 38 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Julio Cortes'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Thomas (Jeff) Kelly',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Thomas (Jeff) Kelly'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 38 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Thomas (Jeff) Kelly'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Annie Fitzgerald',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Annie Fitzgerald'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 38 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Annie Fitzgerald'));

-- WA House of Representatives Legislative District 38 Position 2  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 38 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53038' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 38 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Mary Fosse',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Mary Fosse'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 38 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Mary Fosse'));

-- WA House of Representatives Legislative District 39 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 39 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53039' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 39 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Sam Low',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Sam Low'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 39 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Sam Low'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kathryn Lewandowsky',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kathryn Lewandowsky'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 39 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kathryn Lewandowsky'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Dusty Wisniew',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Dusty Wisniew'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 39 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Dusty Wisniew'));

-- WA House of Representatives Legislative District 39 Position 2  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 39 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53039' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 39 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Robert J Sutherland',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Robert J Sutherland'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 39 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Robert J Sutherland'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ida Keeley',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ida Keeley'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 39 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ida Keeley'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Lacey Sauvageau',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Lacey Sauvageau'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 39 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Lacey Sauvageau'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Steve Ewing',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Steve Ewing'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 39 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Steve Ewing'));

-- WA House of Representatives Legislative District 40 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 40 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53040' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 40 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Debra Lekanoff',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Debra Lekanoff'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 40 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Debra Lekanoff'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Cindy Carter',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Cindy Carter'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 40 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Cindy Carter'));

-- WA House of Representatives Legislative District 40 Position 2  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 40 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53040' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 40 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Salomon Rodrigue Mbouombouo',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Salomon Rodrigue Mbouombouo'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 40 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Salomon Rodrigue Mbouombouo'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Alex Ramel',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Alex Ramel'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 40 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Alex Ramel'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Joseph Segault',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Joseph Segault'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 40 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Joseph Segault'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Monte Jay Mahan',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Monte Jay Mahan'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 40 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Monte Jay Mahan'));

-- WA House of Representatives Legislative District 41 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 41 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53041' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 41 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Janice Zahn',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Janice Zahn'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 41 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Janice Zahn'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Elle Nguyen',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Elle Nguyen'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 41 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Elle Nguyen'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Alex Tsimerman',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Alex Tsimerman'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 41 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Alex Tsimerman'));

-- WA House of Representatives Legislative District 41 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 41 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53041' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 41 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Michael Rosen',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Michael Rosen'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 41 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Michael Rosen'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'My-Linh T Thai',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'My-Linh T Thai'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 41 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('My-Linh T Thai'));

-- WA House of Representatives Legislative District 42 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 42 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53042' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 42 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Alicia Rule',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Alicia Rule'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 42 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Alicia Rule'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Misty Flowers',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Misty Flowers'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 42 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Misty Flowers'));

-- WA House of Representatives Legislative District 42 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 42 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53042' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 42 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Joe Timmons',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Joe Timmons'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 42 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Joe Timmons'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Justin Pike',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Justin Pike'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 42 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Justin Pike'));

-- WA House of Representatives Legislative District 43 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 43 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53043' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 43 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Nicole Macri',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Nicole Macri'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 43 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Nicole Macri'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Alby Clendennin',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Alby Clendennin'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 43 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Alby Clendennin'));

-- WA House of Representatives Legislative District 43 Position 2  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 43 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53043' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 43 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Shaun Scott',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Shaun Scott'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 43 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Shaun Scott'));

-- WA House of Representatives Legislative District 44 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 44 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53044' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 44 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Chris Elder',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Chris Elder'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 44 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Chris Elder'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Brandy Donaghy',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Brandy Donaghy'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 44 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Brandy Donaghy'));

-- WA House of Representatives Legislative District 44 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 44 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53044' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 44 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tonya Stadlman',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tonya Stadlman'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 44 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tonya Stadlman'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'April Berg',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'April Berg'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 44 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('April Berg'));

-- WA House of Representatives Legislative District 45 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 45 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53045' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 45 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'JoAnn Tolentino',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'JoAnn Tolentino'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 45 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('JoAnn Tolentino'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Roger Goodman',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Roger Goodman'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 45 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Roger Goodman'));

-- WA House of Representatives Legislative District 45 Position 2  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 45 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53045' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 45 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Vanessa Kritzer',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Vanessa Kritzer'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 45 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Vanessa Kritzer'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'John P Gibbons',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'John P Gibbons'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 45 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('John P Gibbons'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Chandler Torbett',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Chandler Torbett'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 45 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Chandler Torbett'));

-- WA House of Representatives Legislative District 46 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 46 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53046' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 46 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Gerry Pollet',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Gerry Pollet'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 46 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Gerry Pollet'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ron Davis',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ron Davis'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 46 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ron Davis'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Will Dreher',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Will Dreher'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 46 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Will Dreher'));

-- WA House of Representatives Legislative District 46 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 46 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53046' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 46 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Darya Farivar',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Darya Farivar'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 46 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Darya Farivar'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Rodney ''Star'' Thornley',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Rodney ''Star'' Thornley'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 46 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Rodney ''Star'' Thornley'));

-- WA House of Representatives Legislative District 47 Position 1  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 47 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53047' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 47 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jasnoor Kaur Hans',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jasnoor Kaur Hans'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 47 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jasnoor Kaur Hans'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Cobi Clark',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Cobi Clark'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 47 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Cobi Clark'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Logan Evans',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Logan Evans'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 47 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Logan Evans'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Debra Jean Entenman',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Debra Jean Entenman'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 47 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Debra Jean Entenman'));

-- WA House of Representatives Legislative District 47 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 47 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53047' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 47 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Chris Stearns',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Chris Stearns'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 47 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Chris Stearns'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ted Cooke',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ted Cooke'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 47 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ted Cooke'));

-- WA House of Representatives Legislative District 48 Position 1  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 48 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53048' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 48 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Osman Salahuddin',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Osman Salahuddin'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 48 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Osman Salahuddin'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jeffery Poppe',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jeffery Poppe'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 48 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jeffery Poppe'));

-- WA House of Representatives Legislative District 48 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 48 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53048' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 48 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jessica Forsythe',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jessica Forsythe'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 48 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jessica Forsythe'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Amy Walen',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Amy Walen'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 48 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Amy Walen'));

-- WA House of Representatives Legislative District 49 Position 1  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 49 Position 1', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53049' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 1)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 49 Position 1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kim D. Harless',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kim D. Harless'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 49 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kim D. Harless'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Sarah Mittelman',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Sarah Mittelman'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 49 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Sarah Mittelman'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Mike Pond',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Mike Pond'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 49 Position 1'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Mike Pond'));

-- WA House of Representatives Legislative District 49 Position 2  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA House of Representatives Legislative District 49 Position 2', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53049' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_LOWER' AND d.mtfcc = 'G5220'
  AND o.title = 'State Representative (Position 2)'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 49 Position 2');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Monica Jurado Stonier',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Monica Jurado Stonier'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 49 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Monica Jurado Stonier'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Derek Thompson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Derek Thompson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA House of Representatives Legislative District 49 Position 2'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Derek Thompson'));

-- WA State Senate Legislative District 6  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 6', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53006' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 6');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jeff Holy',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jeff Holy'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 6'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jeff Holy'));

-- WA State Senate Legislative District 7  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 7', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53007' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 7');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Shelly Short',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Shelly Short'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 7'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Shelly Short'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ronald L McCoy',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ronald L McCoy'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 7'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ronald L McCoy'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Brandon Ray Medina',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Brandon Ray Medina'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 7'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Brandon Ray Medina'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'David Swoap',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'David Swoap'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 7'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('David Swoap'));

-- WA State Senate Legislative District 8  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 8', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53008' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 8');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Gabe Galbraith',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Gabe Galbraith'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 8'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Gabe Galbraith'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Douglas McKinley',
       (p.id IS NOT NULL), 'withdrawn', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Douglas McKinley'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 8'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Douglas McKinley'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Nikki Torres',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Nikki Torres'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 8'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Nikki Torres'));

-- WA State Senate Legislative District 13  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 13', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53013' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 13');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Alex Ybarra',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Alex Ybarra'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 13'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Alex Ybarra'));

-- WA State Senate Legislative District 15  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 15', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53015' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 15');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jeremie Dufault',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jeremie Dufault'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 15'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jeremie Dufault'));

-- WA State Senate Legislative District 21  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 21', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53021' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 21');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Marko Liias',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Marko Liias'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 21'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Marko Liias'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Riaz Khan',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Riaz Khan'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 21'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Riaz Khan'));

-- WA State Senate Legislative District 26  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 26', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53026' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 26');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Deborah Krishnadasan',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Deborah Krishnadasan'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 26'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Deborah Krishnadasan'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Gary Parker',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Gary Parker'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 26'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Gary Parker'));

-- WA State Senate Legislative District 29  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 29', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53029' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 29');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Sharlett Mena',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Sharlett Mena'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 29'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Sharlett Mena'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'David Anderson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'David Anderson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 29'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('David Anderson'));

-- WA State Senate Legislative District 30  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 30', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53030' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 30');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Claire Wilson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Claire Wilson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 30'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Claire Wilson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Michael Rutland',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Michael Rutland'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 30'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Michael Rutland'));

-- WA State Senate Legislative District 31  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 31', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53031' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 31');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tamara Stramel',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tamara Stramel'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 31'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tamara Stramel'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Phil Fortunato',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Phil Fortunato'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 31'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Phil Fortunato'));

-- WA State Senate Legislative District 32  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 32', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53032' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 32');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Cindy Ryu',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Cindy Ryu'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 32'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Cindy Ryu'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ira McBee',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ira McBee'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 32'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ira McBee'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jesse Salomon',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jesse Salomon'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 32'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jesse Salomon'));

-- WA State Senate Legislative District 33  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 33', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53033' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 33');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tina L. Orwall',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tina L. Orwall'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 33'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tina L. Orwall'));

-- WA State Senate Legislative District 34  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 34', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53034' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 34');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Emily Alvarado',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Emily Alvarado'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 34'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Emily Alvarado'));

-- WA State Senate Legislative District 35  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 35', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53035' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 35');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Carolina Mejia',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Carolina Mejia'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 35'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Carolina Mejia'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Drew C MacEwen',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Drew C MacEwen'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 35'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Drew C MacEwen'));

-- WA State Senate Legislative District 36  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 36', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53036' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 36');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Noel C. Frame',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Noel C. Frame'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 36'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Noel C. Frame'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jillian England',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jillian England'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 36'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jillian England'));

-- WA State Senate Legislative District 37  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 37', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53037' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 37');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Chipalo Street',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Chipalo Street'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 37'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Chipalo Street'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Emijah Smith',
       (p.id IS NOT NULL), 'withdrawn', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Emijah Smith'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 37'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Emijah Smith'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Tatiana Brown',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Tatiana Brown'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 37'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Tatiana Brown'));

-- WA State Senate Legislative District 38  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 38', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53038' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 38');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'June Robinson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'June Robinson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 38'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('June Robinson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Brad Bender',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Brad Bender'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 38'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Brad Bender'));

-- WA State Senate Legislative District 42  (4 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 42', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53042' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 42');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Michael Alvarez Shepard',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Michael Alvarez Shepard'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 42'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Michael Alvarez Shepard'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Eamonn Collins',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Eamonn Collins'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 42'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Eamonn Collins'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Ryan Bowman',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Ryan Bowman'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 42'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Ryan Bowman'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Erika Creydt',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Erika Creydt'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 42'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Erika Creydt'));

-- WA State Senate Legislative District 43  (3 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 43', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53043' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 43');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Hannah Sabio-Howell',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Hannah Sabio-Howell'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 43'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Hannah Sabio-Howell'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Heather-Marie Wilson',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Heather-Marie Wilson'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 43'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Heather-Marie Wilson'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Jamie Pedersen',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Jamie Pedersen'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 43'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Jamie Pedersen'));

-- WA State Senate Legislative District 44  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 44', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53044' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 44');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Sherri Larkin',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Sherri Larkin'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 44'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Sherri Larkin'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'John Lovick',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'John Lovick'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 44'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('John Lovick'));

-- WA State Senate Legislative District 45  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 45', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53045' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 45');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Manka Dhingra',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Manka Dhingra'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 45'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Manka Dhingra'));

-- WA State Senate Legislative District 46  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 46', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53046' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 46');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Javier Valdez',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Javier Valdez'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 46'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Javier Valdez'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Sandra Stephens',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Sandra Stephens'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 46'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Sandra Stephens'));

-- WA State Senate Legislative District 47  (2 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 47', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53047' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 47');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Claudia Kauffman',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Claudia Kauffman'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 47'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Claudia Kauffman'));

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Kristina Soltys',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Kristina Soltys'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 47'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Kristina Soltys'));

-- WA State Senate Legislative District 48  (1 filed)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id, 'WA State Senate Legislative District 48', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '53048' AND d.state ILIKE 'wa'
  AND d.district_type = 'STATE_UPPER' AND d.mtfcc = 'G5210'
  AND o.title = 'State Senator'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 48');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, 'Vandana Slatter',
       (p.id IS NOT NULL), 'active', DATE '2026-08-24', 'WA Secretary of State candidate filings for the 2026 primary (voter.votewa.gov CandidateList e=898, CSV export), cross-checked against the official results feed results.votewa.gov/results/public/api/elections/washington/20260804/data. Pre-primary field: WA runs a TOP-TWO primary, so only two candidates per race advance regardless of party. Provisional until the Secretary of State certifies the 2026-08-04 primary (county canvass 2026-08-18, state certification 2026-08-21); cull dated 2026-08-24 to match the existing WA 2026 congressional rows. Retrieved 2026-08-13.'
FROM essentials.races r
LEFT JOIN LATERAL (
  SELECT pol.id FROM essentials.politicians pol
  JOIN essentials.office_terms ot ON ot.politician_id = pol.id
  WHERE ot.office_id = r.office_id AND pol.full_name = 'Vandana Slatter'
  LIMIT 1
) p ON true
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d' AND r.position_name = 'WA State Senate Legislative District 48'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key('Vandana Slatter'));
