-- 1253_seed_ut_2026_house_candidates.sql
-- Phase 165-02: UT candidate wiring per the BINDING 164.1-ut-wiring-contract.
--   Incumbent RE-LINK onto NEW district races (candidacy != office): Moore e365a1d4 -> 4902,
--   Maloy a7983eb6 -> 4903, Kennedy 9e3164d5 -> 4904 (is_incumbent=true, existing pids — NO new
--   politician records). 4901 (new compact SLC district) OPEN: McAdams b78f058c (reuse) + Riley
--   Owen/Jesse West/Elias Henry Montgomery (new). Primary-winner pid reuse: Crosby e3cbc264,
--   Udell a7e29796, Larsen 6708ceaa. Burgess Owens (retired) + all Jun-23 primary-losers: 0 rows.
--   12 new challengers at -(49*10000+cd*100+seq), seq from 1 (band empty live 2026-07-07).
--   NO writes to the offices / geo-districts / user-districts tables (dual-map design preserved).
--   NOT EXISTS guards on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

-- (a) 12 new challenger records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490101, 'Riley Owen', 'Riley', 'Owen', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490102, 'Jesse West', 'Jesse', 'West', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490103, 'Elias Henry Montgomery', 'Elias', 'Henry Montgomery', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490201, 'Daniel Cottam', 'Daniel', 'Cottam', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490202, 'Carlton E. Bowen', 'Carlton', 'E. Bowen', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490203, 'Robert M. Moesinger', 'Robert', 'M. Moesinger', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490301, 'Cassie Easley', 'Cassie', 'Easley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490302, 'Adonis Hooslyn', 'Adonis', 'Hooslyn', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490303, 'Ayden Scott', 'Ayden', 'Scott', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490303);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490304, 'Michael R. Stoddard', 'Michael', 'R. Stoddard', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490304);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490401, 'Taylor Wright', 'Taylor', 'Wright', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -490402, 'Steven Burt', 'Steven', 'Burt', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -490402);

-- (b) reused pids re-linked onto their NEW district's race
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'Ben McAdams', 'Ben', 'McAdams', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4901'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = 'b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'e365a1d4-2de3-4fb6-b416-d78227836553'::uuid, 'Blake Moore', 'Blake', 'Moore', true, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4902'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = 'e365a1d4-2de3-4fb6-b416-d78227836553'::uuid);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'e3cbc264-534e-4e47-a288-8ac389bf78f4'::uuid, 'Peter Crosby', 'Peter', 'Crosby', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4902'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = 'e3cbc264-534e-4e47-a288-8ac389bf78f4'::uuid);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'a7983eb6-bae0-4269-856b-f4554fb5ce29'::uuid, 'Celeste Maloy', 'Celeste', 'Maloy', true, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4903'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = 'a7983eb6-bae0-4269-856b-f4554fb5ce29'::uuid);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'a7e29796-a928-49cc-b795-973a4f69fafe'::uuid, 'Kent Udell', 'Kent', 'Udell', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4903'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = 'a7e29796-a928-49cc-b795-973a4f69fafe'::uuid);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '9e3164d5-ce71-4c50-9220-b969265ce551'::uuid, 'Mike Kennedy', 'Mike', 'Kennedy', true, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4904'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = '9e3164d5-ce71-4c50-9220-b969265ce551'::uuid);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '6708ceaa-ae51-4eee-93a3-d4a3be16254d'::uuid, 'Jonny Larsen', 'Jonny', 'Larsen', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4904'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = '6708ceaa-ae51-4eee-93a3-d4a3be16254d'::uuid);

-- (c) 12 new challenger race_candidates
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Riley Owen', 'Riley', 'Owen', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4901'
JOIN essentials.politicians p ON p.external_id = -490101
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jesse West', 'Jesse', 'West', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4901'
JOIN essentials.politicians p ON p.external_id = -490102
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Elias Henry Montgomery', 'Elias', 'Henry Montgomery', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4901'
JOIN essentials.politicians p ON p.external_id = -490103
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Daniel Cottam', 'Daniel', 'Cottam', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4902'
JOIN essentials.politicians p ON p.external_id = -490201
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Carlton E. Bowen', 'Carlton', 'E. Bowen', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4902'
JOIN essentials.politicians p ON p.external_id = -490202
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Robert M. Moesinger', 'Robert', 'M. Moesinger', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4902'
JOIN essentials.politicians p ON p.external_id = -490203
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Cassie Easley', 'Cassie', 'Easley', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4903'
JOIN essentials.politicians p ON p.external_id = -490301
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Adonis Hooslyn', 'Adonis', 'Hooslyn', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4903'
JOIN essentials.politicians p ON p.external_id = -490302
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ayden Scott', 'Ayden', 'Scott', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4903'
JOIN essentials.politicians p ON p.external_id = -490303
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael R. Stoddard', 'Michael', 'R. Stoddard', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4903'
JOIN essentials.politicians p ON p.external_id = -490304
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Taylor Wright', 'Taylor', 'Wright', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4904'
JOIN essentials.politicians p ON p.external_id = -490401
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Steven Burt', 'Steven', 'Burt', false, 'active', 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'UT 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '4904'
JOIN essentials.politicians p ON p.external_id = -490402
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
