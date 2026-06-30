-- 1118_seed_pa_2026_house_candidates.sql
-- Phase 155 Wave 2 (155-03): seed the certified Nov-3 MAJOR-PARTY field onto the 17 PA House races
-- (155-01 scaffold, mig 1117). Inserts 17 NEW essentials.politicians + 33 race_candidates
-- (16 sitting incumbents REUSED is_incumbent=true via 154 incumbent_pid + 17 new challengers/open-seat).
--
-- FIELD SOURCE: 154-FIELD-TABLE.md PA section + per-district Wikipedia URLs, RE-CONFIRMED live 2026-06-30
-- against Ballotpedia/Wikipedia certified general field. DEDUP (D-03, live-verified 2026-06-30): all 17 new
-- names returned 0 prior records -> all genuinely NEW. PA-8 "Robert P. Bresnahan, Jr." (ac16b65b…) IS
-- renominated (154-field-table.csv comma artifact); challenger Paige Cognetti (D) new. PA-3 Evans retired ->
-- NO active row; Chris Rabb (D) unopposed (no R qualified) -> seeded as sole active candidate.
--
-- ⚠ PA INDEPENDENTS DEFERRED (D-03 inclusion bar): PA's independent nomination-paper deadline is Aug 3, 2026;
-- as of 2026-06-30 NO independent is ballot-certified. Declared-only independents (PA-10 Isabelle Harman,
-- PA-13 Cody Thomas, + Hoban/Patel/Wilder/Singelis) are OMITTED here and deferred to a post-Aug-10 date-gated
-- re-check. "Steven Long" (PA-10) dropped entirely — stale 2022 carryover, no 2026 evidence.
--
-- ANTIPARTISAN (D-06): party NOT stored on the card; no essentials.offices rows for challengers; never office_id NULL.
-- Idempotent: politicians guarded by NOT EXISTS(external_id); race_candidates by NOT EXISTS(race_id, lower(full_name)).

BEGIN;

-- 1) 17 new PA candidate politicians (negative external_id band -(42*10000+cd*100+seq)).
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    (-420101, 'Bob Harvie', 'Bob', 'Harvie'),
    (-420201, 'Jessica Arriaga', 'Jessica', 'Arriaga'),
    (-420301, 'Chris Rabb', 'Chris', 'Rabb'),
    (-420401, 'Aurora Stuski', 'Aurora', 'Stuski'),
    (-420501, 'Nicholas Manganaro', 'Nicholas', 'Manganaro'),
    (-420601, 'Marty Young', 'Marty', 'Young'),
    (-420701, 'Bob Brooks', 'Bob', 'Brooks'),
    (-420801, 'Paige Cognetti', 'Paige', 'Cognetti'),
    (-420901, 'Rachel Wallace', 'Rachel', 'Wallace'),
    (-421001, 'Janelle Stelson', 'Janelle', 'Stelson'),
    (-421101, 'Nancy Mannion', 'Nancy', 'Mannion'),
    (-421201, 'James Hayes', 'James', 'Hayes'),
    (-421301, 'Beth Farnham', 'Beth', 'Farnham'),
    (-421401, 'David Alan Bradstock', 'David', 'Alan Bradstock'),
    (-421501, 'Ray Bilger', 'Ray', 'Bilger'),
    (-421601, 'Justin Wagner', 'Justin', 'Wagner'),
    (-421701, 'Tony Guy', 'Tony', 'Guy')
) AS v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2) 33 race_candidates onto the 17 PA races. politician_id = reuse uuid (incumbent) OR resolved
--    by external_id (new). candidate_status='active'. Guard: NOT EXISTS (race_id, lower(full_name)).
INSERT INTO essentials.race_candidates (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), v.race_id::uuid, COALESCE(v.pid_uuid::uuid, np.id), v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.src
FROM (VALUES
    ('e58302b2-f366-4721-82a5-c722165da604', 'a5d68f92-d5e2-4fa1-a191-a64e8ebb2ada', NULL, 'Brian K. Fitzpatrick', 'Brian', 'K. Fitzpatrick', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_1'),
    ('e58302b2-f366-4721-82a5-c722165da604', NULL, -420101, 'Bob Harvie', 'Bob', 'Harvie', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_1'),
    ('54e81562-7c92-4a69-acca-ecc3978460b6', '6d11b72d-fb42-49ca-b44f-89ef02defbb7', NULL, 'Brendan F. Boyle', 'Brendan', 'F. Boyle', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_2'),
    ('54e81562-7c92-4a69-acca-ecc3978460b6', NULL, -420201, 'Jessica Arriaga', 'Jessica', 'Arriaga', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_2'),
    ('a287fef6-1971-4fb3-b7e2-6b6de98840c9', NULL, -420301, 'Chris Rabb', 'Chris', 'Rabb', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_3'),
    ('c8212399-3939-4c7d-9e98-e0a50ba18f61', 'bf942e86-fe8c-496f-9a36-212e9f9403e3', NULL, 'Madeleine Dean', 'Madeleine', 'Dean', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_4'),
    ('c8212399-3939-4c7d-9e98-e0a50ba18f61', NULL, -420401, 'Aurora Stuski', 'Aurora', 'Stuski', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_4'),
    ('40c89e2a-10a4-466d-bc5e-467cd5a0e872', 'ba906956-7359-4b26-8f1b-0d8f8d60b9fc', NULL, 'Mary Gay Scanlon', 'Mary', 'Gay Scanlon', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_5'),
    ('40c89e2a-10a4-466d-bc5e-467cd5a0e872', NULL, -420501, 'Nicholas Manganaro', 'Nicholas', 'Manganaro', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_5'),
    ('d5b6b18d-fb62-449a-9e88-05f79c2136b9', 'abf87328-e0fa-4ebd-89e6-6f1631e5a5c2', NULL, 'Chrissy Houlahan', 'Chrissy', 'Houlahan', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_6'),
    ('d5b6b18d-fb62-449a-9e88-05f79c2136b9', NULL, -420601, 'Marty Young', 'Marty', 'Young', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_6'),
    ('05d85109-d170-4c51-b3a8-b1d443ae148b', '38f9fb6c-b2de-4a79-a9fa-82f400a6a6f2', NULL, 'Ryan Mackenzie', 'Ryan', 'Mackenzie', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_7'),
    ('05d85109-d170-4c51-b3a8-b1d443ae148b', NULL, -420701, 'Bob Brooks', 'Bob', 'Brooks', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_7'),
    ('e50986de-5238-4289-b629-e9f790aca537', 'ac16b65b-c438-40e4-b192-1a01418c2225', NULL, 'Robert P. Bresnahan, Jr.', 'Robert', 'P. Bresnahan, Jr.', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_8'),
    ('e50986de-5238-4289-b629-e9f790aca537', NULL, -420801, 'Paige Cognetti', 'Paige', 'Cognetti', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_8'),
    ('237f60e5-e00a-465b-8556-00f82d95e722', '345511a8-3f1a-40a7-96a6-b87d6ec011b1', NULL, 'Daniel Meuser', 'Daniel', 'Meuser', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_9'),
    ('237f60e5-e00a-465b-8556-00f82d95e722', NULL, -420901, 'Rachel Wallace', 'Rachel', 'Wallace', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_9'),
    ('6cd9bb32-ee8b-45c7-b319-0a4abe9fcbe8', '7412719e-e468-4ce7-85fb-26516ca7610f', NULL, 'Scott Perry', 'Scott', 'Perry', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_10'),
    ('6cd9bb32-ee8b-45c7-b319-0a4abe9fcbe8', NULL, -421001, 'Janelle Stelson', 'Janelle', 'Stelson', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_10'),
    ('6bbfcea8-1983-4729-905a-2673c5f32650', 'a4f800f0-6634-47c6-a340-ca494544d9b5', NULL, 'Lloyd Smucker', 'Lloyd', 'Smucker', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_11'),
    ('6bbfcea8-1983-4729-905a-2673c5f32650', NULL, -421101, 'Nancy Mannion', 'Nancy', 'Mannion', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_11'),
    ('91cc8aea-08c2-4066-aa49-96b85b6ff307', '117883ff-7a9a-42cb-b42b-82223f1d618d', NULL, 'Summer L. Lee', 'Summer', 'L. Lee', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_12'),
    ('91cc8aea-08c2-4066-aa49-96b85b6ff307', NULL, -421201, 'James Hayes', 'James', 'Hayes', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_12'),
    ('aa9b7309-f89e-48ea-ab81-41a2575c2692', '7a858437-ac72-45bf-a2b7-3cc130ca6584', NULL, 'John Joyce', 'John', 'Joyce', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_13'),
    ('aa9b7309-f89e-48ea-ab81-41a2575c2692', NULL, -421301, 'Beth Farnham', 'Beth', 'Farnham', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_13'),
    ('961cb419-8666-4c70-9161-1d7c3f0b01f0', '6840c7e6-2169-43a4-8490-1e73c8704cbd', NULL, 'Guy Reschenthaler', 'Guy', 'Reschenthaler', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_14'),
    ('961cb419-8666-4c70-9161-1d7c3f0b01f0', NULL, -421401, 'David Alan Bradstock', 'David', 'Alan Bradstock', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_14'),
    ('7fa6fcae-daa1-4a36-a717-66896ef18ca6', '6cf68d79-f822-47c4-b702-1f14f20270e4', NULL, 'Glenn Thompson', 'Glenn', 'Thompson', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_15'),
    ('7fa6fcae-daa1-4a36-a717-66896ef18ca6', NULL, -421501, 'Ray Bilger', 'Ray', 'Bilger', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_15'),
    ('9028e51d-9f0a-4bd2-a020-80c4e2b336ae', '4c34d7a5-ceea-493f-a6a4-cb5d14763593', NULL, 'Mike Kelly', 'Mike', 'Kelly', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_16'),
    ('9028e51d-9f0a-4bd2-a020-80c4e2b336ae', NULL, -421601, 'Justin Wagner', 'Justin', 'Wagner', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_16'),
    ('17bc3486-ddd4-4d84-8913-1773be070161', 'c20345d9-e451-4813-8645-985734fedba3', NULL, 'Christopher R. Deluzio', 'Christopher', 'R. Deluzio', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_17'),
    ('17bc3486-ddd4-4d84-8913-1773be070161', NULL, -421701, 'Tony Guy', 'Tony', 'Guy', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Pennsylvania#District_17')
) AS v(race_id, pid_uuid, pid_ext, full_name, first_name, last_name, is_incumbent, src)
LEFT JOIN essentials.politicians np ON np.external_id = v.pid_ext::int
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND lower(rc.full_name) = lower(v.full_name)
);

COMMIT;
