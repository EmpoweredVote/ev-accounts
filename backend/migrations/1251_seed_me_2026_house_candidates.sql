-- 1251_seed_me_2026_house_candidates.sql
-- Phase 165-01: ME CANDIDATES-ONLY seed onto the 2 PRE-EXISTING ME U.S. House races
--   ('2026 Maine General Election'; NO elections/races INSERT — reuse existing race UUIDs).
--   Ronald Russell (-230103, ME-1) + Matthew Dunlap (-230203, ME-2) — live scan 2026-07-07
--   found NO dormant pids -> both create-new. Pingree (a93b5364-f9bc-406b-b175-8c452dcaf276) and
--   LePage (c58647c9-1ac0-43a4-9682-c0c7198631b9) rows normalized 'filed'->'active' (is_incumbent untouched).
--   DECIDED field; ME generals are RCV. NOT EXISTS guards; sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

-- (a) 2 new ME politicians (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -230103, 'Ronald Russell', 'Ronald', 'Russell', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -230103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -230203, 'Matthew Dunlap', 'Matthew', 'Dunlap', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -230203);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'd92aa73a-17db-4ba1-bfaf-46640f66f8f5'::uuid, p.id, 'Ronald Russell', 'Ronald', 'Russell', false, 'active', 'ME 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Maine; RCV general)'
FROM essentials.politicians p
WHERE p.external_id = -230103
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'd92aa73a-17db-4ba1-bfaf-46640f66f8f5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'aa63d55d-80b8-42b9-9aa5-0713387f65fb'::uuid, p.id, 'Matthew Dunlap', 'Matthew', 'Dunlap', false, 'active', 'ME 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Maine; RCV general)'
FROM essentials.politicians p
WHERE p.external_id = -230203
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'aa63d55d-80b8-42b9-9aa5-0713387f65fb'::uuid AND rc.politician_id = p.id);

-- (b) normalize the 2 pre-existing 'filed' rows to 'active' (idempotent; flags untouched)
UPDATE essentials.race_candidates SET candidate_status = 'active'
WHERE id IN ('a93b5364-f9bc-406b-b175-8c452dcaf276'::uuid, 'c58647c9-1ac0-43a4-9682-c0c7198631b9'::uuid)
  AND candidate_status = 'filed';

COMMIT;
