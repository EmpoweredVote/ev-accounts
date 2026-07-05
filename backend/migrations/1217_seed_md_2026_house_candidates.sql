-- 1217_seed_md_2026_house_candidates.sql
-- Phase 162-08: MD CANDIDATES-ONLY seed onto the 8 PRE-EXISTING MD U.S. House races
--   (2026 Maryland General Election; races NOT created here -- reuse existing_race_id).
--   12 new MD politicians + 13 challenger race_candidates (12 new by external_id + Adrian
--   Boafo reused by pid 1da26040/external_id -2420067) + 7 renominated-incumbent race_candidates
--   (Harris/Olszewski/Elfreth/Ivey/McClain Delaney/Mfume/Raskin, reusing existing pids). Hoyer
--   MD-5 RETIRED -> NO incumbent row (open seat). DECIDED field -> NOT PROVISIONAL. Every
--   race_candidates INSERT guarded by NOT EXISTS (race_id, politician_id). sqlStr()-escaped.
--   ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party untouched.
BEGIN;

-- Mark the 8 existing MD races with the decided/open-window wording (description-only; idempotent)
UPDATE essentials.races
SET description = 'Confirmed nominees + declared-so-far minor-party field; unaffiliated window open to 2026-08-03'
WHERE id IN ('cb9a70c8-626b-43ed-9267-9531d2403535'::uuid,'01c39962-63fe-4f5d-ac56-a546e09374a6'::uuid,'34ae857f-a68e-40c6-a1bd-1bc9266dce5b'::uuid,'1df5607b-36f4-45f6-a94f-adabba5811da'::uuid,'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997'::uuid,'d5d7f27a-e421-46d8-af73-da225ea625a0'::uuid,'a6b83f0d-bc99-4f29-9d39-a87025d55a01'::uuid,'52874d42-9b2b-47c9-a87b-c11801627eb2'::uuid)
  AND (description IS NULL OR description NOT LIKE '%unaffiliated window open%');

-- (a) 12 new challenger/open-seat/minor-party records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240101, 'Dan Schwartz', 'Dan', 'Schwartz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240201, 'Dave Wallace', 'Dave', 'Wallace', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240301, 'Berney Flowers', 'Berney', 'Flowers', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240401, 'George McDermott', 'George', 'McDermott', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240501, 'Chris Chaffee', 'Chris', 'Chaffee', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240502, 'Jonathan Burruss', 'Jonathan', 'Burruss', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240503, 'Brian Jordan', 'Brian', 'Jordan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240601, 'Robin Ficker', 'Robin', 'Ficker', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240602, 'Moshe Landman', 'Moshe', 'Landman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240701, 'Scott Collier', 'Scott', 'Collier', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240801, 'Cheryl Riley', 'Cheryl', 'Riley', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -240802, 'Nancy Wallace', 'Nancy', 'Wallace', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -240802);

-- (b)+(c) 13 challenger + 7 incumbent race_candidates (NOT EXISTS on (race_id, politician_id))
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'cb9a70c8-626b-43ed-9267-9531d2403535'::uuid, p.id, 'Dan Schwartz', 'Dan', 'Schwartz', false, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240101
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'cb9a70c8-626b-43ed-9267-9531d2403535'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '01c39962-63fe-4f5d-ac56-a546e09374a6'::uuid, p.id, 'Dave Wallace', 'Dave', 'Wallace', false, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240201
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '01c39962-63fe-4f5d-ac56-a546e09374a6'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '34ae857f-a68e-40c6-a1bd-1bc9266dce5b'::uuid, p.id, 'Berney Flowers', 'Berney', 'Flowers', false, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240301
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '34ae857f-a68e-40c6-a1bd-1bc9266dce5b'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '1df5607b-36f4-45f6-a94f-adabba5811da'::uuid, p.id, 'George McDermott', 'George', 'McDermott', false, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240401
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '1df5607b-36f4-45f6-a94f-adabba5811da'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997'::uuid, p.id, 'Adrian Boafo', 'Adrian', 'Boafo', false, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.id = '1da26040-98b4-4eb0-aa1f-3ec05b297a29'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997'::uuid, p.id, 'Chris Chaffee', 'Chris', 'Chaffee', false, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240501
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997'::uuid, p.id, 'Jonathan Burruss', 'Jonathan', 'Burruss', false, 'active', 'MD SBE 2026 declared unaffiliated/minor-party general field (window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240502
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997'::uuid, p.id, 'Brian Jordan', 'Brian', 'Jordan', false, 'active', 'MD SBE 2026 declared unaffiliated/minor-party general field (window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240503
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'd5d7f27a-e421-46d8-af73-da225ea625a0'::uuid, p.id, 'Robin Ficker', 'Robin', 'Ficker', false, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240601
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'd5d7f27a-e421-46d8-af73-da225ea625a0'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'd5d7f27a-e421-46d8-af73-da225ea625a0'::uuid, p.id, 'Moshe Landman', 'Moshe', 'Landman', false, 'active', 'MD SBE 2026 declared unaffiliated/minor-party general field (window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240602
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'd5d7f27a-e421-46d8-af73-da225ea625a0'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'a6b83f0d-bc99-4f29-9d39-a87025d55a01'::uuid, p.id, 'Scott Collier', 'Scott', 'Collier', false, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240701
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'a6b83f0d-bc99-4f29-9d39-a87025d55a01'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '52874d42-9b2b-47c9-a87b-c11801627eb2'::uuid, p.id, 'Cheryl Riley', 'Cheryl', 'Riley', false, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240801
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '52874d42-9b2b-47c9-a87b-c11801627eb2'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '52874d42-9b2b-47c9-a87b-c11801627eb2'::uuid, p.id, 'Nancy Wallace', 'Nancy', 'Wallace', false, 'active', 'MD SBE 2026 declared unaffiliated/minor-party general field (window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.external_id = -240802
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '52874d42-9b2b-47c9-a87b-c11801627eb2'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'cb9a70c8-626b-43ed-9267-9531d2403535'::uuid, p.id, 'Andy Harris', 'Andy', 'Harris', true, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.id = 'ff596d3f-3056-43e2-a80a-8c4b8fd9abde'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'cb9a70c8-626b-43ed-9267-9531d2403535'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '01c39962-63fe-4f5d-ac56-a546e09374a6'::uuid, p.id, 'Johnny Olszewski', 'Johnny', 'Olszewski', true, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.id = '504ff19d-5db9-4093-9cba-d36fcb70f1b6'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '01c39962-63fe-4f5d-ac56-a546e09374a6'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '34ae857f-a68e-40c6-a1bd-1bc9266dce5b'::uuid, p.id, 'Sarah Elfreth', 'Sarah', 'Elfreth', true, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.id = '87560825-eced-4690-be06-88549f0f83cf'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '34ae857f-a68e-40c6-a1bd-1bc9266dce5b'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '1df5607b-36f4-45f6-a94f-adabba5811da'::uuid, p.id, 'Glenn Ivey', 'Glenn', 'Ivey', true, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.id = 'e59ec991-3948-4369-913c-63c62dc3ece5'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '1df5607b-36f4-45f6-a94f-adabba5811da'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'd5d7f27a-e421-46d8-af73-da225ea625a0'::uuid, p.id, 'April McClain Delaney', 'April', 'McClain Delaney', true, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.id = 'da087947-83af-4ca2-91c8-1f9e0bf887a9'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'd5d7f27a-e421-46d8-af73-da225ea625a0'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'a6b83f0d-bc99-4f29-9d39-a87025d55a01'::uuid, p.id, 'Kweisi Mfume', 'Kweisi', 'Mfume', true, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.id = '6e2f5cf7-4e00-4a83-b1d7-b3f2ea4c1ffd'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'a6b83f0d-bc99-4f29-9d39-a87025d55a01'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '52874d42-9b2b-47c9-a87b-c11801627eb2'::uuid, p.id, 'Jamie Raskin', 'Jamie', 'Raskin', true, 'active', 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)'
FROM essentials.politicians p
WHERE p.id = '731c674f-8f44-4df3-8b04-3b70be39a1bd'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '52874d42-9b2b-47c9-a87b-c11801627eb2'::uuid AND rc.politician_id = p.id);

COMMIT;
