-- 1235_seed_or_2026_house_candidates.sql
-- Phase 164-03: OR CANDIDATES-ONLY seed onto the 6 PRE-EXISTING OR U.S. House races
--   ('OR 2026 General'; races NOT created here -- reuse existing_race_id, D-03). 7 new OR
--   politicians + 7 challenger race_candidates + 6 renominated-incumbent race_candidates
--   (Bonamici/Bentz/Dexter/Hoyle/Bynum/Salinas, reused by external_id -4102001..-4102006). DECIDED
--   field -> NOT PROVISIONAL (OR unaffiliated/minor window open to 2026-08-25 -> Phase 167). Every
--   race_candidates INSERT guarded by NOT EXISTS (race_id, politician_id). OR-1 new record uses seq
--   14 (D-04; seqs 10-13 = OR local officials). sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

-- Mark the 6 existing OR races with the decided/open-window wording (description-only; idempotent)
UPDATE essentials.races
SET description = 'Confirmed general field; OR unaffiliated/minor-party window open to 2026-08-25 -> Phase 167'
WHERE id IN ('8dfd6e35-f91d-4d14-bcec-ae983035da51'::uuid,'504a156a-d4e6-4abe-9a85-a418c0135805'::uuid,'61297fac-c98d-4ad4-b93f-b2e36722bd6a'::uuid,'c5023da0-985e-4e1c-817c-a843849ef6e9'::uuid,'17a4b696-5c15-4f2b-9390-ce1864d57f37'::uuid,'dd25e913-2496-40fa-a735-c9b1d7f68df8'::uuid)
  AND (description IS NULL OR description NOT LIKE '%unaffiliated/minor-party window open%');

-- (a) 7 new challenger records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -410114, 'Barbara Kahl', 'Barbara', 'Kahl', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -410114);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -410201, 'Chris Beck', 'Chris', 'Beck', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -410201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -410301, 'Loran Ayles', 'Loran', 'Ayles', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -410301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -410401, 'Monique DeSpain', 'Monique', 'DeSpain', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -410401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -410402, 'Justin Filip', 'Justin', 'Filip', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -410402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -410501, 'Patti Adair', 'Patti', 'Adair', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -410501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -410601, 'David Russ', 'David', 'Russ', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -410601);

-- (b)+(c) 7 challenger + 6 incumbent race_candidates (NOT EXISTS on (race_id, politician_id))
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '8dfd6e35-f91d-4d14-bcec-ae983035da51'::uuid, p.id, 'Barbara Kahl', 'Barbara', 'Kahl', false, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -410114
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '8dfd6e35-f91d-4d14-bcec-ae983035da51'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '504a156a-d4e6-4abe-9a85-a418c0135805'::uuid, p.id, 'Chris Beck', 'Chris', 'Beck', false, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -410201
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '504a156a-d4e6-4abe-9a85-a418c0135805'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '61297fac-c98d-4ad4-b93f-b2e36722bd6a'::uuid, p.id, 'Loran Ayles', 'Loran', 'Ayles', false, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -410301
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '61297fac-c98d-4ad4-b93f-b2e36722bd6a'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'c5023da0-985e-4e1c-817c-a843849ef6e9'::uuid, p.id, 'Monique DeSpain', 'Monique', 'DeSpain', false, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -410401
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'c5023da0-985e-4e1c-817c-a843849ef6e9'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'c5023da0-985e-4e1c-817c-a843849ef6e9'::uuid, p.id, 'Justin Filip', 'Justin', 'Filip', false, 'active', 'OR SoS 2026 declared minor-party/independent general field (window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -410402
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'c5023da0-985e-4e1c-817c-a843849ef6e9'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '17a4b696-5c15-4f2b-9390-ce1864d57f37'::uuid, p.id, 'Patti Adair', 'Patti', 'Adair', false, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -410501
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '17a4b696-5c15-4f2b-9390-ce1864d57f37'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'dd25e913-2496-40fa-a735-c9b1d7f68df8'::uuid, p.id, 'David Russ', 'David', 'Russ', false, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -410601
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'dd25e913-2496-40fa-a735-c9b1d7f68df8'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '8dfd6e35-f91d-4d14-bcec-ae983035da51'::uuid, p.id, 'Suzanne Bonamici', 'Suzanne', 'Bonamici', true, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -4102001
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '8dfd6e35-f91d-4d14-bcec-ae983035da51'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '504a156a-d4e6-4abe-9a85-a418c0135805'::uuid, p.id, 'Cliff Bentz', 'Cliff', 'Bentz', true, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -4102002
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '504a156a-d4e6-4abe-9a85-a418c0135805'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '61297fac-c98d-4ad4-b93f-b2e36722bd6a'::uuid, p.id, 'Maxine Dexter', 'Maxine', 'Dexter', true, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -4102003
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '61297fac-c98d-4ad4-b93f-b2e36722bd6a'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'c5023da0-985e-4e1c-817c-a843849ef6e9'::uuid, p.id, 'Val Hoyle', 'Val', 'Hoyle', true, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -4102004
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'c5023da0-985e-4e1c-817c-a843849ef6e9'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '17a4b696-5c15-4f2b-9390-ce1864d57f37'::uuid, p.id, 'Janelle Bynum', 'Janelle', 'Bynum', true, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -4102005
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '17a4b696-5c15-4f2b-9390-ce1864d57f37'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'dd25e913-2496-40fa-a735-c9b1d7f68df8'::uuid, p.id, 'Andrea Salinas', 'Andrea', 'Salinas', true, 'active', 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)'
FROM essentials.politicians p
WHERE p.external_id = -4102006
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'dd25e913-2496-40fa-a735-c9b1d7f68df8'::uuid AND rc.politician_id = p.id);

COMMIT;
