-- 1128_seed_oh_2026_house_candidates.sql
-- Phase 156 Wave 2: seed the certified Nov-3 general field onto the 15 OH House races
-- (156-01 scaffold, mig 1127). Inserts 19 NEW essentials.politicians + 34 race_candidates.
-- FIELD SOURCE: 154-FIELD-TABLE.md OH section (Wikipedia). OH all-renominated: all 15 incumbents
-- are the 2026 nominees, reused is_incumbent=true. D-02 seed-all: OH-1/9/15 Libertarian + OH-4
-- Independent Tamie Wilson seeded as party-agnostic active cards.
-- DEDUP (D-03, live-verified 2026-06-30): all 19 new names returned 0 prior real records
-- (only FEC committee-name junk / different-person homonyms; e.g. Luis A. Ojeda != Richard Ojeda,
-- KY John H. Rogers -210145 != NC-11 John Rogers). external_id band OH verified collision-free (62-id sweep).
-- ANTIPARTISAN (D-06): party NOT stored on the card; no essentials.offices rows for challengers; never office_id NULL.
-- Idempotent: politicians guarded by NOT EXISTS(external_id); race_candidates by NOT EXISTS(race_id, lower(full_name)).

BEGIN;

-- 1) 19 new OH candidate politicians (negative external_id band -(39*10000+cd*100+seq)).
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    (-390101, 'Eric Conroy', 'Eric', 'Conroy'),
    (-390102, 'John Hancock', 'John', 'Hancock'),
    (-390201, 'Jennifer Mazzuckelli', 'Jennifer', 'Mazzuckelli'),
    (-390301, 'Cleophus Dulaney', 'Cleophus', 'Dulaney'),
    (-390401, 'Joshua Kolasinski', 'Joshua', 'Kolasinski'),
    (-390402, 'Tamie Wilson', 'Tamie', 'Wilson'),
    (-390501, 'Brian Shaver', 'Brian', 'Shaver'),
    (-390601, 'Elizabeth Kirtley', 'Elizabeth', 'Kirtley'),
    (-390701, 'Brian Poindexter', 'Brian', 'Poindexter'),
    (-390801, 'Vanessa Enoch', 'Vanessa', 'Enoch'),
    (-390901, 'Derek Merrin', 'Derek', 'Merrin'),
    (-390902, 'Matthew Althaus', 'Matthew', 'Althaus'),
    (-391001, 'Kristina Knickerbocker', 'Kristina', 'Knickerbocker'),
    (-391101, 'Mike Kirchner', 'Mike', 'Kirchner'),
    (-391201, 'Jerrad Christian', 'Jerrad', 'Christian'),
    (-391301, 'Carey Coleman', 'Carey', 'Coleman'),
    (-391401, 'Maria Jukic', 'Maria', 'Jukic'),
    (-391501, 'Don Leonard', 'Don', 'Leonard'),
    (-391502, 'Brennan Barrington', 'Brennan', 'Barrington')
) AS v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2) 34 race_candidates onto the 15 OH races. politician_id = reuse uuid
--    (incumbent) OR resolved by external_id (new). candidate_status='active'. Guard: NOT EXISTS (race_id, lower(full_name)).
INSERT INTO essentials.race_candidates (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), v.race_id::uuid, COALESCE(v.pid_uuid::uuid, np.id), v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.src
FROM (VALUES
    ('c80c98c8-98c4-4df2-90d4-1f37681da294', '6cad043f-a4c0-48d5-af76-fdf70d319920', NULL, 'Greg Landsman', 'Greg', 'Landsman', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('c80c98c8-98c4-4df2-90d4-1f37681da294', NULL, -390101, 'Eric Conroy', 'Eric', 'Conroy', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('c80c98c8-98c4-4df2-90d4-1f37681da294', NULL, -390102, 'John Hancock', 'John', 'Hancock', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('d52a8639-4a2a-4a33-b464-75c10fd81dd2', '1938e59f-bd7c-45fb-8dd1-2f7591a0fc3d', NULL, 'David J. Taylor', 'David', 'J. Taylor', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('d52a8639-4a2a-4a33-b464-75c10fd81dd2', NULL, -390201, 'Jennifer Mazzuckelli', 'Jennifer', 'Mazzuckelli', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('1af68d00-f746-463d-9040-7f5b76822d13', 'dd93f609-82f5-4923-8a0e-d73b58120b80', NULL, 'Joyce Beatty', 'Joyce', 'Beatty', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('1af68d00-f746-463d-9040-7f5b76822d13', NULL, -390301, 'Cleophus Dulaney', 'Cleophus', 'Dulaney', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('9d550df5-6527-43db-a191-551ed79d5280', '09531f42-9724-4211-b33a-7f1af94b250e', NULL, 'Jim Jordan', 'Jim', 'Jordan', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('9d550df5-6527-43db-a191-551ed79d5280', NULL, -390401, 'Joshua Kolasinski', 'Joshua', 'Kolasinski', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('9d550df5-6527-43db-a191-551ed79d5280', NULL, -390402, 'Tamie Wilson', 'Tamie', 'Wilson', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('3a25f137-ce4c-48a7-ab56-5002bfb1e98b', 'e3c5cef5-08ff-4066-9fee-344733cb4137', NULL, 'Robert E. Latta', 'Robert', 'E. Latta', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('3a25f137-ce4c-48a7-ab56-5002bfb1e98b', NULL, -390501, 'Brian Shaver', 'Brian', 'Shaver', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('3773d04c-bc0b-416f-97e8-f8478185ce0f', '3fe892d9-3086-4088-a6d8-af7b3a8b80c1', NULL, 'Michael A. Rulli', 'Michael', 'A. Rulli', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('3773d04c-bc0b-416f-97e8-f8478185ce0f', NULL, -390601, 'Elizabeth Kirtley', 'Elizabeth', 'Kirtley', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('117f6d3e-54ac-47aa-8ff7-3e936421d0da', '02706ab4-75fc-4bbd-ae1e-b879c0955d3f', NULL, 'Max L. Miller', 'Max', 'L. Miller', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('117f6d3e-54ac-47aa-8ff7-3e936421d0da', NULL, -390701, 'Brian Poindexter', 'Brian', 'Poindexter', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('9c0ac72c-f3f6-411f-a756-5b2f4d16f483', 'd7f3b400-2d9f-4d23-bd02-9edea5274e92', NULL, 'Warren Davidson', 'Warren', 'Davidson', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('9c0ac72c-f3f6-411f-a756-5b2f4d16f483', NULL, -390801, 'Vanessa Enoch', 'Vanessa', 'Enoch', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('f5c5e04b-7062-4e26-ae76-90cb75a239df', '4d530660-da80-4d96-9c59-1a33ddf08e4b', NULL, 'Marcy Kaptur', 'Marcy', 'Kaptur', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('f5c5e04b-7062-4e26-ae76-90cb75a239df', NULL, -390901, 'Derek Merrin', 'Derek', 'Merrin', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('f5c5e04b-7062-4e26-ae76-90cb75a239df', NULL, -390902, 'Matthew Althaus', 'Matthew', 'Althaus', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('29948b99-ac91-48b3-82a5-5970f6a10ed5', '792fbe55-46f5-49db-8400-2ce2632fd1ea', NULL, 'Michael R. Turner', 'Michael', 'R. Turner', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('29948b99-ac91-48b3-82a5-5970f6a10ed5', NULL, -391001, 'Kristina Knickerbocker', 'Kristina', 'Knickerbocker', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('4892145e-6ec3-482a-85f8-c4d0f138fe68', 'e7f9cb36-33ae-4291-94da-57d956c822af', NULL, 'Shontel M. Brown', 'Shontel', 'M. Brown', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('4892145e-6ec3-482a-85f8-c4d0f138fe68', NULL, -391101, 'Mike Kirchner', 'Mike', 'Kirchner', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('064dc162-7e16-4e90-872f-e65ce6ee4625', 'd053e66a-762e-4514-8e16-2ae672ee47e1', NULL, 'Troy Balderson', 'Troy', 'Balderson', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('064dc162-7e16-4e90-872f-e65ce6ee4625', NULL, -391201, 'Jerrad Christian', 'Jerrad', 'Christian', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('8326e7dd-a298-4e2c-8452-7f83f7809f6f', '5dc95a47-7f94-46b3-b797-4bd2429ceb3e', NULL, 'Emilia Strong Sykes', 'Emilia', 'Strong Sykes', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('8326e7dd-a298-4e2c-8452-7f83f7809f6f', NULL, -391301, 'Carey Coleman', 'Carey', 'Coleman', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('bae92984-e4ca-4fbf-9484-0aedf93a4945', '811f725f-1eaa-4e67-9dbc-389698615e00', NULL, 'David P. Joyce', 'David', 'P. Joyce', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('bae92984-e4ca-4fbf-9484-0aedf93a4945', NULL, -391401, 'Maria Jukic', 'Maria', 'Jukic', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('14fc971f-1b7c-4d7d-aa79-8259a82fcfcf', '2dadf0d8-b767-4963-89ff-04441e995501', NULL, 'Mike Carey', 'Mike', 'Carey', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('14fc971f-1b7c-4d7d-aa79-8259a82fcfcf', NULL, -391501, 'Don Leonard', 'Don', 'Leonard', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio'),
    ('14fc971f-1b7c-4d7d-aa79-8259a82fcfcf', NULL, -391502, 'Brennan Barrington', 'Brennan', 'Barrington', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Ohio')
) AS v(race_id, pid_uuid, pid_ext, full_name, first_name, last_name, is_incumbent, src)
LEFT JOIN essentials.politicians np ON np.external_id = v.pid_ext::int
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND lower(rc.full_name) = lower(v.full_name)
);

COMMIT;
