-- 1130_seed_nc_2026_house_candidates.sql
-- Phase 156 Wave 2: seed the certified Nov-3 general field onto the 14 NC House races
-- (156-01 scaffold, mig 1127). Inserts 25 NEW essentials.politicians + 39 race_candidates.
-- FIELD SOURCE: 154-FIELD-TABLE.md NC section (Wikipedia/Ballotpedia). NC all-renominated: all 14
-- incumbents are the 2026 nominees, reused is_incumbent=true (INCL. NC-6 Addison P. McDowell -37006,
-- the only zero-stance incumbent — reused here; his full-24 stances are pushed in 156-09, NOT here).
-- D-02 seed-all: heaviest third-party field — Libertarians NC-1/2/3/4/5/7/10/11/13, a Green (NC-13
-- Anthony Aguilar), an Independent (NC-11 John Rogers). Dedup D-03: Richard Ojeda (!= Luis A. Ojeda),
-- Laurie Buckhout (2024 nominee), John Rogers (!= KY John H. Rogers -210145) all returned 0 -> NEW.
-- DEDUP (D-03, live-verified 2026-06-30): all 25 new names returned 0 prior real records
-- (only FEC committee-name junk / different-person homonyms; e.g. Luis A. Ojeda != Richard Ojeda,
-- KY John H. Rogers -210145 != NC-11 John Rogers). external_id band NC verified collision-free (62-id sweep).
-- ANTIPARTISAN (D-06): party NOT stored on the card; no essentials.offices rows for challengers; never office_id NULL.
-- Idempotent: politicians guarded by NOT EXISTS(external_id); race_candidates by NOT EXISTS(race_id, lower(full_name)).

BEGIN;

-- 1) 25 new NC candidate politicians (negative external_id band -(37*10000+cd*100+seq)).
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    (-370101, 'Laurie Buckhout', 'Laurie', 'Buckhout'),
    (-370102, 'Tom Bailey', 'Tom', 'Bailey'),
    (-370201, 'Gene Douglass', 'Gene', 'Douglass'),
    (-370202, 'Matt Laszacs', 'Matt', 'Laszacs'),
    (-370301, 'Raymond Smith Jr.', 'Raymond', 'Smith Jr.'),
    (-370302, 'Daniel Cavender', 'Daniel', 'Cavender'),
    (-370401, 'Max Ganorkar', 'Max', 'Ganorkar'),
    (-370402, 'Guy Meilleur', 'Guy', 'Meilleur'),
    (-370501, 'Chuck Hubbard', 'Chuck', 'Hubbard'),
    (-370502, 'Robert Luffman', 'Robert', 'Luffman'),
    (-370601, 'Cyril Jefferson', 'Cyril', 'Jefferson'),
    (-370701, 'Kimberly Hardy', 'Kimberly', 'Hardy'),
    (-370702, 'Maad Abu-Ghazalah', 'Maad', 'Abu-Ghazalah'),
    (-370801, 'Colby Watson', 'Colby', 'Watson'),
    (-370901, 'Richard Ojeda', 'Richard', 'Ojeda'),
    (-371001, 'Ashley Bell', 'Ashley', 'Bell'),
    (-371002, 'Steven Feldman', 'Steven', 'Feldman'),
    (-371101, 'Jamie Ager', 'Jamie', 'Ager'),
    (-371102, 'Travis Groo', 'Travis', 'Groo'),
    (-371103, 'John Rogers', 'John', 'Rogers'),
    (-371201, 'Jack Codiga', 'Jack', 'Codiga'),
    (-371301, 'Paul Barringer', 'Paul', 'Barringer'),
    (-371302, 'Anthony Aguilar', 'Anthony', 'Aguilar'),
    (-371303, 'Steven Swinton', 'Steven', 'Swinton'),
    (-371401, 'Lakesha Womack', 'Lakesha', 'Womack')
) AS v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2) 39 race_candidates onto the 14 NC races. politician_id = reuse uuid
--    (incumbent) OR resolved by external_id (new). candidate_status='active'. Guard: NOT EXISTS (race_id, lower(full_name)).
INSERT INTO essentials.race_candidates (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), v.race_id::uuid, COALESCE(v.pid_uuid::uuid, np.id), v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.src
FROM (VALUES
    ('f97e2ceb-4dae-4922-8132-3dc89375f351', 'f38f8dde-2073-4a22-a577-2a96ea9c15c3', NULL, 'Donald G. Davis', 'Donald', 'G. Davis', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('f97e2ceb-4dae-4922-8132-3dc89375f351', NULL, -370101, 'Laurie Buckhout', 'Laurie', 'Buckhout', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('f97e2ceb-4dae-4922-8132-3dc89375f351', NULL, -370102, 'Tom Bailey', 'Tom', 'Bailey', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('e7194bc9-2297-40e9-93ff-4ac4e7a6f598', '291f71df-c5c2-4f0a-b6be-d762d7aec9dd', NULL, 'Deborah K. Ross', 'Deborah', 'K. Ross', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('e7194bc9-2297-40e9-93ff-4ac4e7a6f598', NULL, -370201, 'Gene Douglass', 'Gene', 'Douglass', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('e7194bc9-2297-40e9-93ff-4ac4e7a6f598', NULL, -370202, 'Matt Laszacs', 'Matt', 'Laszacs', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('d5edae06-65c7-4853-a15b-97731330295c', '6c2a7eee-dd04-4844-801d-5acddc4facba', NULL, 'Gregory F. Murphy', 'Gregory', 'F. Murphy', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('d5edae06-65c7-4853-a15b-97731330295c', NULL, -370301, 'Raymond Smith Jr.', 'Raymond', 'Smith Jr.', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('d5edae06-65c7-4853-a15b-97731330295c', NULL, -370302, 'Daniel Cavender', 'Daniel', 'Cavender', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('2be0f81f-42eb-412c-9637-4b93296cdde8', '248c67f9-b8bf-4627-b358-a0f49b47abe7', NULL, 'Valerie P. Foushee', 'Valerie', 'P. Foushee', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('2be0f81f-42eb-412c-9637-4b93296cdde8', NULL, -370401, 'Max Ganorkar', 'Max', 'Ganorkar', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('2be0f81f-42eb-412c-9637-4b93296cdde8', NULL, -370402, 'Guy Meilleur', 'Guy', 'Meilleur', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('b2e81abc-07b2-4280-b059-74655b4201c2', '21b9bbfb-cb9b-44ab-90d5-8d3c847b8485', NULL, 'Virginia Foxx', 'Virginia', 'Foxx', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('b2e81abc-07b2-4280-b059-74655b4201c2', NULL, -370501, 'Chuck Hubbard', 'Chuck', 'Hubbard', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('b2e81abc-07b2-4280-b059-74655b4201c2', NULL, -370502, 'Robert Luffman', 'Robert', 'Luffman', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('ebc2c793-6292-4724-be13-a5d09858ea61', '74579547-1454-475e-ab35-12cf88a998b9', NULL, 'Addison P. McDowell', 'Addison', 'P. McDowell', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('ebc2c793-6292-4724-be13-a5d09858ea61', NULL, -370601, 'Cyril Jefferson', 'Cyril', 'Jefferson', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('5be80001-9052-47dd-913d-704685975bb9', '1fd041d0-473c-45f5-bbfb-54b42aaabc8d', NULL, 'David Rouzer', 'David', 'Rouzer', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('5be80001-9052-47dd-913d-704685975bb9', NULL, -370701, 'Kimberly Hardy', 'Kimberly', 'Hardy', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('5be80001-9052-47dd-913d-704685975bb9', NULL, -370702, 'Maad Abu-Ghazalah', 'Maad', 'Abu-Ghazalah', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('45f2b223-e5ac-44ef-a50f-7234d682462e', 'a10b5487-6874-4395-b193-aee6980d5bfe', NULL, 'Mark Harris', 'Mark', 'Harris', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('45f2b223-e5ac-44ef-a50f-7234d682462e', NULL, -370801, 'Colby Watson', 'Colby', 'Watson', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('f2d5c863-a55c-4bed-a4c5-0dcaa490b90a', '951d32a1-8ff1-4c4f-be20-01efdf8f02dc', NULL, 'Richard Hudson', 'Richard', 'Hudson', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('f2d5c863-a55c-4bed-a4c5-0dcaa490b90a', NULL, -370901, 'Richard Ojeda', 'Richard', 'Ojeda', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_North_Carolina'),
    ('dbf2a5a4-32ff-4437-97d5-c51cc7903f47', '93573d4e-f9e8-41df-b1b4-cbb5b8006e3f', NULL, 'Pat Harrigan', 'Pat', 'Harrigan', true, 'https://ballotpedia.org/North_Carolina''s_10th_Congressional_District_election,_2026'),
    ('dbf2a5a4-32ff-4437-97d5-c51cc7903f47', NULL, -371001, 'Ashley Bell', 'Ashley', 'Bell', false, 'https://ballotpedia.org/North_Carolina''s_10th_Congressional_District_election,_2026'),
    ('dbf2a5a4-32ff-4437-97d5-c51cc7903f47', NULL, -371002, 'Steven Feldman', 'Steven', 'Feldman', false, 'https://ballotpedia.org/North_Carolina''s_10th_Congressional_District_election,_2026'),
    ('74af01ff-3f67-4a7c-915c-3a8e85830c0e', 'f7763de5-8cb1-439b-9176-2c16070c01df', NULL, 'Chuck Edwards', 'Chuck', 'Edwards', true, 'https://ballotpedia.org/North_Carolina''s_11th_Congressional_District_election,_2026'),
    ('74af01ff-3f67-4a7c-915c-3a8e85830c0e', NULL, -371101, 'Jamie Ager', 'Jamie', 'Ager', false, 'https://ballotpedia.org/North_Carolina''s_11th_Congressional_District_election,_2026'),
    ('74af01ff-3f67-4a7c-915c-3a8e85830c0e', NULL, -371102, 'Travis Groo', 'Travis', 'Groo', false, 'https://ballotpedia.org/North_Carolina''s_11th_Congressional_District_election,_2026'),
    ('74af01ff-3f67-4a7c-915c-3a8e85830c0e', NULL, -371103, 'John Rogers', 'John', 'Rogers', false, 'https://ballotpedia.org/North_Carolina''s_11th_Congressional_District_election,_2026'),
    ('0c3b0325-9ac5-40f2-aad9-17deb34a8ebe', '2c12afd3-178d-46c3-a4ea-a09f2f796ce9', NULL, 'Alma S. Adams', 'Alma', 'S. Adams', true, 'https://ballotpedia.org/North_Carolina''s_12th_Congressional_District_election,_2026'),
    ('0c3b0325-9ac5-40f2-aad9-17deb34a8ebe', NULL, -371201, 'Jack Codiga', 'Jack', 'Codiga', false, 'https://ballotpedia.org/North_Carolina''s_12th_Congressional_District_election,_2026'),
    ('7528fbba-c2ac-4009-b9e4-4fd9a13488d0', 'c432657b-d48d-4d3c-b2f2-6b83f6de47fc', NULL, 'Brad Knott', 'Brad', 'Knott', true, 'https://ballotpedia.org/North_Carolina''s_13th_Congressional_District_election,_2026'),
    ('7528fbba-c2ac-4009-b9e4-4fd9a13488d0', NULL, -371301, 'Paul Barringer', 'Paul', 'Barringer', false, 'https://ballotpedia.org/North_Carolina''s_13th_Congressional_District_election,_2026'),
    ('7528fbba-c2ac-4009-b9e4-4fd9a13488d0', NULL, -371302, 'Anthony Aguilar', 'Anthony', 'Aguilar', false, 'https://ballotpedia.org/North_Carolina''s_13th_Congressional_District_election,_2026'),
    ('7528fbba-c2ac-4009-b9e4-4fd9a13488d0', NULL, -371303, 'Steven Swinton', 'Steven', 'Swinton', false, 'https://ballotpedia.org/North_Carolina''s_13th_Congressional_District_election,_2026'),
    ('ed9f1b08-472d-451f-a425-74412a241d27', 'e27f0fc2-ef98-4592-ae87-f6320f2b847e', NULL, 'Tim Moore', 'Tim', 'Moore', true, 'https://ballotpedia.org/North_Carolina''s_14th_Congressional_District_election,_2026'),
    ('ed9f1b08-472d-451f-a425-74412a241d27', NULL, -371401, 'Lakesha Womack', 'Lakesha', 'Womack', false, 'https://ballotpedia.org/North_Carolina''s_14th_Congressional_District_election,_2026')
) AS v(race_id, pid_uuid, pid_ext, full_name, first_name, last_name, is_incumbent, src)
LEFT JOIN essentials.politicians np ON np.external_id = v.pid_ext::int
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND lower(rc.full_name) = lower(v.full_name)
);

COMMIT;
