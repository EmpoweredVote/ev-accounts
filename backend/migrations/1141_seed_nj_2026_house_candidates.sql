-- 1141_seed_nj_2026_house_candidates.sql
-- Phase 157 Wave 2 (157-03): seed the certified Nov-3 general field onto the 12 NJ House races
-- (157-01 scaffold, mig 1140). Inserts 15 NEW essentials.politicians + 26 race_candidates
-- (11 reused incumbents NJ-1..11 + 15 new challengers/minor-line). NJ-8 uncontested = Menendez only.
-- FIELD SOURCE: 154-FIELD-TABLE.md NJ section (Wikipedia + newjerseyglobe). NJ primary held -> DECIDED.
-- NJ-11 Mejia (93874414-...) REUSED as special-seated incumbent (already in DB); Joe Hathaway new.
-- NJ-12 Watson Coleman (a75a3e6e-... , -34012) RETIRED -> NO active race_candidates row; her nominees
-- Adam Hamawy + Gregg Mele are NEW. This is a RETIREMENT, not a vacancy: office + record already exist,
-- so NO office is created (contrast GA-13 in mig 1127).
-- DEDUP (D-03, live-verified 2026-07-01): all 15 new names returned 0 prior records. external_id band
-- -341299..-340101 verified: only 3 UNRELATED Utah legislator records (Kohler -340539/Grover -340436/
-- Peterson -340305) exist in the numeric band; none collide with the 15 assigned NJ ids; none are NJ
-- House candidates (gate _new_cands is scoped to active NJ race_candidates, so they are excluded).
-- ANTIPARTISAN (D-06): party NOT stored on the card; no essentials.offices rows for challengers; never office_id NULL.
-- Idempotent: politicians guarded by NOT EXISTS(external_id); race_candidates by NOT EXISTS(race_id, lower(full_name)).

BEGIN;

-- 1) 15 new NJ candidate politicians (negative external_id band -(34*10000+cd*100+seq)).
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    (-340101, 'Damon Galdo', 'Damon', 'Galdo'),
    (-340201, 'Zack Mullock', 'Zack', 'Mullock'),
    (-340301, 'Michael McGuire', 'Michael', 'McGuire'),
    (-340302, 'Steven Welzer', 'Steven', 'Welzer'),
    (-340303, 'Ryan Michael Kelly', 'Ryan', 'Michael Kelly'),
    (-340401, 'Rachel Peace', 'Rachel', 'Peace'),
    (-340501, 'Sean Kirrane', 'Sean', 'Kirrane'),
    (-340502, 'Adam Rueda', 'Adam', 'Rueda'),
    (-340601, 'Hillary Herzig', 'Hillary', 'Herzig'),
    (-340701, 'Rebecca Bennett', 'Rebecca', 'Bennett'),
    (-340901, 'Rosie Pino', 'Rosie', 'Pino'),
    (-341001, 'Carmen Bucco', 'Carmen', 'Bucco'),
    (-341101, 'Joe Hathaway', 'Joe', 'Hathaway'),
    (-341201, 'Adam Hamawy', 'Adam', 'Hamawy'),
    (-341202, 'Gregg Mele', 'Gregg', 'Mele')
) AS v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2) 26 race_candidates onto the 12 NJ races. politician_id = reuse uuid (incumbent) OR resolved by
--    external_id (new). candidate_status='active'. Guard: NOT EXISTS (race_id, lower(full_name)).
--    Watson Coleman (NJ-12 retired) intentionally has NO row here.
INSERT INTO essentials.race_candidates (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), v.race_id::uuid, COALESCE(v.pid_uuid::uuid, np.id), v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.src
FROM (VALUES
    ('86b52a52-b7ec-424b-8736-bf0f480b5e15', 'b74a616d-9c47-4328-8c25-b1a3dc0a4f9d', NULL, 'Donald Norcross', 'Donald', 'Norcross', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('86b52a52-b7ec-424b-8736-bf0f480b5e15', NULL, -340101, 'Damon Galdo', 'Damon', 'Galdo', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('bab7fa90-2102-420a-8b8f-0da4c8c655f1', 'ac328544-b0d7-4714-8487-e2467f9713e8', NULL, 'Jefferson Van Drew', 'Jefferson', 'Van Drew', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('bab7fa90-2102-420a-8b8f-0da4c8c655f1', NULL, -340201, 'Zack Mullock', 'Zack', 'Mullock', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('298389a6-f686-48db-a95e-3fb2ba62c10a', 'f0235587-d1e8-412d-970c-16b50b2b185f', NULL, 'Herbert C. Conaway, Jr.', 'Herbert', 'C. Conaway, Jr.', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('298389a6-f686-48db-a95e-3fb2ba62c10a', NULL, -340301, 'Michael McGuire', 'Michael', 'McGuire', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('298389a6-f686-48db-a95e-3fb2ba62c10a', NULL, -340302, 'Steven Welzer', 'Steven', 'Welzer', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('298389a6-f686-48db-a95e-3fb2ba62c10a', NULL, -340303, 'Ryan Michael Kelly', 'Ryan', 'Michael Kelly', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('3af838f9-b1c3-4ecb-b7f3-574b430dd7ff', '99022a78-79ea-417c-8a7c-0bc5f773e329', NULL, 'Christopher H. Smith', 'Christopher', 'H. Smith', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('3af838f9-b1c3-4ecb-b7f3-574b430dd7ff', NULL, -340401, 'Rachel Peace', 'Rachel', 'Peace', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('800d91c5-52b1-4780-b94f-9858d760f051', 'c4251d10-6fba-4a5a-b8a9-f4b2f4634f0d', NULL, 'Josh Gottheimer', 'Josh', 'Gottheimer', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('800d91c5-52b1-4780-b94f-9858d760f051', NULL, -340501, 'Sean Kirrane', 'Sean', 'Kirrane', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('800d91c5-52b1-4780-b94f-9858d760f051', NULL, -340502, 'Adam Rueda', 'Adam', 'Rueda', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('5ae7000e-bfc9-4cdf-94e2-923cc7ee63c3', '332de859-029c-43ff-baa7-0113ad436d0f', NULL, 'Frank Pallone, Jr.', 'Frank', 'Pallone, Jr.', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('5ae7000e-bfc9-4cdf-94e2-923cc7ee63c3', NULL, -340601, 'Hillary Herzig', 'Hillary', 'Herzig', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('102137a4-cde9-42a7-ac82-58a252c07366', '1bc949f5-0696-481c-979b-64cfd494983a', NULL, 'Thomas H. Kean, Jr.', 'Thomas', 'H. Kean, Jr.', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('102137a4-cde9-42a7-ac82-58a252c07366', NULL, -340701, 'Rebecca Bennett', 'Rebecca', 'Bennett', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('90c5e29a-a5a8-47ec-9003-4b4b851cca92', 'fc7a00d6-c552-4627-87f7-b0fc5cfe486c', NULL, 'Robert Menendez', 'Robert', 'Menendez', true, 'https://newjerseyglobe.com/congress/the-final-list-of-whos-running-for-congress-in-new-jersey-in-2026/'),
    ('b4f42a0f-0599-4d57-9776-d1375e69bfd3', '149d987d-78f6-4547-92d4-19b103a62f5e', NULL, 'Nellie Pou', 'Nellie', 'Pou', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey'),
    ('b4f42a0f-0599-4d57-9776-d1375e69bfd3', NULL, -340901, 'Rosie Pino', 'Rosie', 'Pino', false, 'https://thehill.com/homenews/campaign/new-jersey-rosie-pino-wins-republican-primary/'),
    ('371cbe0b-f54a-4338-b608-2a167a282ef1', 'c8cd097f-ce28-40b1-8236-18bc111ad868', NULL, 'LaMonica McIver', 'LaMonica', 'McIver', true, 'https://newjerseyglobe.com/congress/the-final-list-of-whos-running-for-congress-in-new-jersey-in-2026/'),
    ('371cbe0b-f54a-4338-b608-2a167a282ef1', NULL, -341001, 'Carmen Bucco', 'Carmen', 'Bucco', false, 'https://newjerseyglobe.com/congress/the-final-list-of-whos-running-for-congress-in-new-jersey-in-2026/'),
    ('c47045f6-6dd3-46c8-8615-9acbfbcf95e8', '93874414-6d14-4c12-87b2-d254b3855570', NULL, 'Analilia Mejia', 'Analilia', 'Mejia', true, 'https://ballotpedia.org/New_Jerseys_11th_Congressional_District_election,_2026'),
    ('c47045f6-6dd3-46c8-8615-9acbfbcf95e8', NULL, -341101, 'Joe Hathaway', 'Joe', 'Hathaway', false, 'https://ballotpedia.org/New_Jerseys_11th_Congressional_District_election,_2026'),
    ('f87e6f4b-6e82-40d8-a7a5-adfacb0988fd', NULL, -341201, 'Adam Hamawy', 'Adam', 'Hamawy', false, 'https://newjerseyglobe.com/congress/hamawy-wins-wide-open-nj-12-race-in-major-victory-for-the-left/'),
    ('f87e6f4b-6e82-40d8-a7a5-adfacb0988fd', NULL, -341202, 'Gregg Mele', 'Gregg', 'Mele', false, 'https://newjerseyglobe.com/congress/hamawy-wins-wide-open-nj-12-race-in-major-victory-for-the-left/')
) AS v(race_id, pid_uuid, pid_ext, full_name, first_name, last_name, is_incumbent, src)
LEFT JOIN essentials.politicians np ON np.external_id = v.pid_ext::int
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND lower(rc.full_name) = lower(v.full_name)
);

COMMIT;
