-- 1129_seed_ga_2026_house_candidates.sql
-- Phase 156 Wave 2: seed the certified Nov-3 general field onto the 14 GA House races
-- (156-01 scaffold, mig 1127). Inserts 18 NEW essentials.politicians + 28 race_candidates.
-- FIELD SOURCE: 154-FIELD-TABLE.md GA section (Wikipedia/Ballotpedia/news, re-confirmed live).
-- WRINKLES (D-04): GA-1 Carter (ran Senate), GA-10 Collins (ran Senate), GA-11 Loudermilk (retired) get
-- NO active row — their sitting-incumbent pid is kept but absent from the field. GA-13 is a TRUE VACANCY
-- (David Scott died Apr 2026): no incumbent pid, both Clark (D) + Chavez (R) are new active non-incumbents.
-- GA-2..9,12,14 renominated -> incumbent reused is_incumbent=true. Dedup D-03: Jasmine Clark (GA state
-- rep), Houston Gaines (GA state rep), Shawn Harris, Jim Kingston all returned 0 prior records -> NEW.
-- DEDUP (D-03, live-verified 2026-06-30): all 18 new names returned 0 prior real records
-- (only FEC committee-name junk / different-person homonyms; e.g. Luis A. Ojeda != Richard Ojeda,
-- KY John H. Rogers -210145 != NC-11 John Rogers). external_id band GA verified collision-free (62-id sweep).
-- ANTIPARTISAN (D-06): party NOT stored on the card; no essentials.offices rows for challengers; never office_id NULL.
-- Idempotent: politicians guarded by NOT EXISTS(external_id); race_candidates by NOT EXISTS(race_id, lower(full_name)).

BEGIN;

-- 1) 18 new GA candidate politicians (negative external_id band -(13*10000+cd*100+seq)).
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    (-130101, 'Jim Kingston', 'Jim', 'Kingston'),
    (-130102, 'Amanda Hollowell', 'Amanda', 'Hollowell'),
    (-130201, 'Matt Day', 'Matt', 'Day'),
    (-130301, 'Maura Keller', 'Maura', 'Keller'),
    (-130401, 'James Duffe', 'James', 'Duffe'),
    (-130501, 'John Salvesen', 'John', 'Salvesen'),
    (-130601, 'Kevin Martin', 'Kevin', 'Martin'),
    (-130701, 'Anthony Kozycki', 'Anthony', 'Kozycki'),
    (-130801, 'Kelly Esti', 'Kelly', 'Esti'),
    (-130901, 'Caitlyn Gegen', 'Caitlyn', 'Gegen'),
    (-131001, 'Houston Gaines', 'Houston', 'Gaines'),
    (-131002, 'Pamela DeLancy', 'Pamela', 'DeLancy'),
    (-131101, 'John Cowan', 'John', 'Cowan'),
    (-131102, 'Chris Harden', 'Chris', 'Harden'),
    (-131201, 'Ceretta Smith', 'Ceretta', 'Smith'),
    (-131301, 'Jasmine Clark', 'Jasmine', 'Clark'),
    (-131302, 'Jonathan Chavez', 'Jonathan', 'Chavez'),
    (-131401, 'Shawn Harris', 'Shawn', 'Harris')
) AS v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2) 28 race_candidates onto the 14 GA races. politician_id = reuse uuid
--    (incumbent) OR resolved by external_id (new). candidate_status='active'. Guard: NOT EXISTS (race_id, lower(full_name)).
INSERT INTO essentials.race_candidates (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), v.race_id::uuid, COALESCE(v.pid_uuid::uuid, np.id), v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.src
FROM (VALUES
    ('6b16cb6a-159f-48b1-a1ed-eb2de73f2e84', NULL, -130101, 'Jim Kingston', 'Jim', 'Kingston', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('6b16cb6a-159f-48b1-a1ed-eb2de73f2e84', NULL, -130102, 'Amanda Hollowell', 'Amanda', 'Hollowell', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('4a924d50-196e-456a-bd98-bb708d712c41', 'a172a95a-b866-4ece-a7e2-47487c5ec471', NULL, 'Sanford D. Bishop, Jr.', 'Sanford', 'D. Bishop, Jr.', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('4a924d50-196e-456a-bd98-bb708d712c41', NULL, -130201, 'Matt Day', 'Matt', 'Day', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('e8808d20-f9ea-483e-a605-c423a5a11b4d', 'eabb384b-b541-4232-978a-fbb7fcad9290', NULL, 'Brian Jack', 'Brian', 'Jack', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('e8808d20-f9ea-483e-a605-c423a5a11b4d', NULL, -130301, 'Maura Keller', 'Maura', 'Keller', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('fdb1e1b0-847b-430a-a0ab-47d69a30eb66', '135f4a8f-6e03-453f-a5b2-9a3b338f26c3', NULL, 'Henry C. "Hank" Johnson, Jr.', 'Henry', 'C. "Hank" Johnson, Jr.', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('fdb1e1b0-847b-430a-a0ab-47d69a30eb66', NULL, -130401, 'James Duffe', 'James', 'Duffe', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('4688afb8-4f46-4849-8255-ff96d174d7ba', 'acb046eb-1db6-44bf-a50b-32d16df15057', NULL, 'Nikema Williams', 'Nikema', 'Williams', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('4688afb8-4f46-4849-8255-ff96d174d7ba', NULL, -130501, 'John Salvesen', 'John', 'Salvesen', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('0a2d5641-a3bd-4321-8fa6-820b49b28209', '66e69f62-7694-4e9a-89cf-8b699add8e1f', NULL, 'Lucy McBath', 'Lucy', 'McBath', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('0a2d5641-a3bd-4321-8fa6-820b49b28209', NULL, -130601, 'Kevin Martin', 'Kevin', 'Martin', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('e88a5aa0-3230-4143-8da7-e6b7e7100714', 'b295210e-a45d-4a80-8001-47cdc522a3e5', NULL, 'Richard McCormick', 'Richard', 'McCormick', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('e88a5aa0-3230-4143-8da7-e6b7e7100714', NULL, -130701, 'Anthony Kozycki', 'Anthony', 'Kozycki', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('26a8cc4d-5935-4b3f-a8a4-cc00100f08a9', '247e657a-8c30-4194-8702-81adce0beea4', NULL, 'Austin Scott', 'Austin', 'Scott', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('26a8cc4d-5935-4b3f-a8a4-cc00100f08a9', NULL, -130801, 'Kelly Esti', 'Kelly', 'Esti', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('33420d45-4f57-465e-903f-e02cac286769', '94d6a044-7a03-400d-8092-00aac9859c9b', NULL, 'Andrew S. Clyde', 'Andrew', 'S. Clyde', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('33420d45-4f57-465e-903f-e02cac286769', NULL, -130901, 'Caitlyn Gegen', 'Caitlyn', 'Gegen', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('2cb356e5-8239-4c69-aca4-7e32d4120668', NULL, -131001, 'Houston Gaines', 'Houston', 'Gaines', false, 'https://ballotpedia.org/Georgia''s_10th_Congressional_District_election,_2026'),
    ('2cb356e5-8239-4c69-aca4-7e32d4120668', NULL, -131002, 'Pamela DeLancy', 'Pamela', 'DeLancy', false, 'https://ballotpedia.org/Georgia''s_10th_Congressional_District_election,_2026'),
    ('f9d81306-025c-42b3-8262-c7a8460624ac', NULL, -131101, 'John Cowan', 'John', 'Cowan', false, 'https://www.atlantanewsfirst.com/2026/06/16/john-cowan-wins-gop-11th-district-runoff-will-face-democrat-chris-harden-this-fall/'),
    ('f9d81306-025c-42b3-8262-c7a8460624ac', NULL, -131102, 'Chris Harden', 'Chris', 'Harden', false, 'https://www.atlantanewsfirst.com/2026/06/16/john-cowan-wins-gop-11th-district-runoff-will-face-democrat-chris-harden-this-fall/'),
    ('1174435d-ff1b-4b9e-9bfd-eb822fe85ad9', '3de9e882-a816-42fc-ae70-aa93098c5d02', NULL, 'Rick W. Allen', 'Rick', 'W. Allen', true, 'https://www.wrdw.com/2026/06/17/ceretta-smith-wins-runoff-democratic-us-house-primary/'),
    ('1174435d-ff1b-4b9e-9bfd-eb822fe85ad9', NULL, -131201, 'Ceretta Smith', 'Ceretta', 'Smith', false, 'https://www.wrdw.com/2026/06/17/ceretta-smith-wins-runoff-democratic-us-house-primary/'),
    ('f8294135-070b-44bd-bf70-86638263f17d', NULL, -131301, 'Jasmine Clark', 'Jasmine', 'Clark', false, 'https://ballotpedia.org/Georgia''s_13th_Congressional_District_election,_2026'),
    ('f8294135-070b-44bd-bf70-86638263f17d', NULL, -131302, 'Jonathan Chavez', 'Jonathan', 'Chavez', false, 'https://ballotpedia.org/Georgia''s_13th_Congressional_District_election,_2026'),
    ('523e7af5-90a1-4dc2-82e7-e2ea94d33723', '8c4ce29b-84ae-445b-9531-9fdaceb5d420', NULL, 'Clay Fuller', 'Clay', 'Fuller', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia'),
    ('523e7af5-90a1-4dc2-82e7-e2ea94d33723', NULL, -131401, 'Shawn Harris', 'Shawn', 'Harris', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Georgia')
) AS v(race_id, pid_uuid, pid_ext, full_name, first_name, last_name, is_incumbent, src)
LEFT JOIN essentials.politicians np ON np.external_id = v.pid_ext::int
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND lower(rc.full_name) = lower(v.full_name)
);

COMMIT;
