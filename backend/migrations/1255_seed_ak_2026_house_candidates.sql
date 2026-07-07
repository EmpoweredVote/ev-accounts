-- 1255_seed_ak_2026_house_candidates.sql
-- Phase 165-03: FULL AK top-four-RCV declared field — 14 new politicians (-20005..-20018,
--   D-04 safe_start_seq=5: seqs 1-4 are unrelated KS records in the polluted band) + Begich III
--   reuse (pid 07c7a121-520f-4651-a1a0-5f38d20f8e0b, external_id -2000, is_incumbent=true) = 15 active
--   race_candidates on the single at-large jungle race. RCV over-indulgence: every declared
--   candidate captured. NOT EXISTS guards on (race_id, politician_id); sqlStr()-escaped.
--   ANTIPARTISAN: party never stored on the card.
BEGIN;

-- (a) 14 new AK candidates (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20005, 'David R. Ambrose II', 'David', 'R. Ambrose II', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20005);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20006, 'Lady Donna Dutchess', 'Lady', 'Donna Dutchess', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20006);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20007, 'John E. Foddrill Sr.', 'John', 'E. Foddrill Sr.', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20007);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20008, 'Eddie Goldfarb', 'Eddie', 'Goldfarb', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20008);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20009, 'Eric Hafner', 'Eric', 'Hafner', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20009);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20010, 'Bill Hill', 'Bill', 'Hill', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20010);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20011, 'James C. "Jim" McDermott', 'James', 'C. "Jim" McDermott', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20011);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20012, 'Yaquelin Reynoso', 'Yaquelin', 'Reynoso', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20012);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20013, 'David Richey', 'David', 'Richey', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20013);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20014, 'Melanie A. Salazar', 'Melanie', 'A. Salazar', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20014);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20015, 'Matt Schultz', 'Matt', 'Schultz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20015);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20016, 'Clay Strickland', 'Clay', 'Strickland', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20016);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20017, 'John B. Williams', 'John', 'B. Williams', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20017);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -20018, 'Matthew "Bronco" Williams', 'Matthew', '"Bronco" Williams', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -20018);

-- (b) 15 race_candidates (Begich reuse + 14 new)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '07c7a121-520f-4651-a1a0-5f38d20f8e0b'::uuid, 'Nicholas J. Begich III', 'Nicholas', 'Begich', true, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = '07c7a121-520f-4651-a1a0-5f38d20f8e0b'::uuid);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David R. Ambrose II', 'David', 'R. Ambrose II', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20005
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lady Donna Dutchess', 'Lady', 'Donna Dutchess', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20006
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John E. Foddrill Sr.', 'John', 'E. Foddrill Sr.', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20007
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eddie Goldfarb', 'Eddie', 'Goldfarb', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20008
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Eric Hafner', 'Eric', 'Hafner', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20009
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bill Hill', 'Bill', 'Hill', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20010
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'James C. "Jim" McDermott', 'James', 'C. "Jim" McDermott', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20011
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Yaquelin Reynoso', 'Yaquelin', 'Reynoso', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20012
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David Richey', 'David', 'Richey', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20013
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Melanie A. Salazar', 'Melanie', 'A. Salazar', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20014
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matt Schultz', 'Matt', 'Schultz', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20015
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Clay Strickland', 'Clay', 'Strickland', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20016
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'John B. Williams', 'John', 'B. Williams', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20017
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matthew "Bronco" Williams', 'Matthew', '"Bronco" Williams', false, 'active', 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'AK 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -20018
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
