-- 1275_seed_wy_2026_house_candidates.sql
-- Phase 165-07: WY OPEN-seat field — 14 active candidates = Chuck Gray (REUSE v2.18 WY-SoS pid
--   b503b679-773a-4eee-9c16-e73bff1a723f, race_candidates only) + 13 NEW (-560001..-560013, band empty
--   live). Hageman (1e08c7c7, -56000) -> Senate run, NO row. Field = 10 R + 2 D + 1 L + 1 I per the
--   authoritative WY SoS roster (plan's "18" was an authoring slip — see generator header).
--   PROVISIONAL, cull >= 2026-08-18. NOT EXISTS guards; sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560001, 'Jillian Balow', 'Jillian', 'Balow', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560001);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560002, 'Bo Biteman', 'Bo', 'Biteman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560002);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560003, 'Frank Chapman', 'Frank', 'Chapman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560003);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560004, 'Kevin Christensen', 'Kevin', 'Christensen', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560004);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560005, 'Richard Dodson', 'Richard', 'Dodson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560005);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560006, 'Steve Friess', 'Steve', 'Friess', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560006);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560007, 'David Giralt', 'David', 'Giralt', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560007);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560008, 'Reid Rasner', 'Reid', 'Rasner', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560008);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560009, 'Keith B. Goodenough', 'Keith', 'B. Goodenough', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560009);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560010, 'Lisa Kinney', 'Lisa', 'Kinney', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560010);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560011, 'Elena Del Real', 'Elena', 'Del Real', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560011);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560012, 'Shawn Johnson', 'Shawn', 'Johnson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560012);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -560013, 'Daniel Workman', 'Daniel', 'Workman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -560013);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'b503b679-773a-4eee-9c16-e73bff1a723f'::uuid, 'Chuck Gray', 'Chuck', 'Gray', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = 'b503b679-773a-4eee-9c16-e73bff1a723f'::uuid);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jillian Balow', 'Jillian', 'Balow', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bo Biteman', 'Bo', 'Biteman', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560002
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Frank Chapman', 'Frank', 'Chapman', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560003
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Kevin Christensen', 'Kevin', 'Christensen', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560004
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Richard Dodson', 'Richard', 'Dodson', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560005
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Steve Friess', 'Steve', 'Friess', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560006
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'David Giralt', 'David', 'Giralt', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560007
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Reid Rasner', 'Reid', 'Rasner', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560008
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Keith B. Goodenough', 'Keith', 'B. Goodenough', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560009
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lisa Kinney', 'Lisa', 'Kinney', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560010
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Elena Del Real', 'Elena', 'Del Real', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560011
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Shawn Johnson', 'Shawn', 'Johnson', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560012
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Daniel Workman', 'Daniel', 'Workman', false, 'active', 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'WY 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -560013
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
