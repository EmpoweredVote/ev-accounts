-- 1027_burbank_complete.sql
-- Phase 154 Wave 2 (BURB-01): finalize Burbank's 5-seat at-large roster.
-- Gov 3e3deaea-c5f4-4a68-b3ae-a79589f544ea; survivor council chamber 73422d25-c0a6-477a-b74f-2b38b94b6389
-- (5 bidirectional offices after mig 1026).
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-22 (154-02 Task 1): NO DRIFT.
--
-- ROTATIONAL MAYOR = TITLE ON A SEAT (West Covina 1011 / Downey model).
-- Burbank is AT-LARGE with a ROTATIONAL Mayor (no directly-elected LOCAL_EXEC Mayor).
-- Five council seats elected citywide; Mayor elected annually by/from the council at the
-- December reorganization meeting. CVRA ballot measures pending Nov 2026 — still at-large.
-- Current rotational state (Dec 15, 2025 reorganization meeting, valid through Dec 2026):
--   Mayor       = Tamala Takahashi    (pol ea6f7109, office 70e56076-e283-4e3e-88f0-9551ba6109f9)
--   Vice Mayor  = Zizette Mullins     (pol f933bd87, office 9969febe-0fe8-4a66-af5e-49eea7367390)
-- Sources: myBurbank.com Dec 2025 "Tamala Takahashi Elevated to Position of Burbank Mayor for 2026";
--          Granicus board roster; burbankca.gov newsroom.
-- Assumption A1: Dec 2025 reorg still current (next rotation Dec 2026; no mid-year change).
-- NO new politician. NO unlink. All 5 confirmed current per RESEARCH §Roster Verdict.
-- CRITICAL: official_count=5 (rotational Mayor IS one of the 5 at-large seats — NOT 4).
--   Unlike Inglewood's directly-elected Mayor (excluded from council count), Burbank's
--   rotational Mayor is just one of the 5 at-large council seats. West Covina 1011 precedent.
-- DO NOT create a LOCAL_EXEC Mayor office. DO NOT relabel 'At-Large' districts.
-- DO NOT unlink Mullins (she is Vice Mayor, not City Clerk — RESEARCH §Roster Verdict).
-- OUT OF SCOPE (untouched): Burbank Unified School District gov d5ffbb65-f0db-41ad-8d11-278b8fb9aedc.

BEGIN;

-- Part A: Mayor / Vice Mayor titles (rotational, title-on-seat), normalize the rest.
-- All guarded IS DISTINCT FROM for idempotency (re-run safe).
-- Current DB title convention for council members: 'Council Member' (pre-flight confirmed).

UPDATE essentials.offices SET title = 'Mayor'
 WHERE id = '70e56076-e283-4e3e-88f0-9551ba6109f9'
   AND title IS DISTINCT FROM 'Mayor'; -- Tamala Takahashi

UPDATE essentials.offices SET title = 'Vice Mayor'
 WHERE id = '9969febe-0fe8-4a66-af5e-49eea7367390'
   AND title IS DISTINCT FROM 'Vice Mayor'; -- Zizette Mullins

UPDATE essentials.offices SET title = 'Council Member'
 WHERE id IN (
   'f205911b-a255-42c4-aaf7-0b3a6588c4a8',  -- Nikki Perez
   'caea9243-c030-4676-b2f0-8e6662c663e0',  -- Christopher John Rizzotti
   '1294961c-40db-47ed-8caf-9a721073d902'   -- Konstantine Anthony
 )
   AND title IS DISTINCT FROM 'Council Member';

-- Part B: official_count = 5 (all 5 are council seats; rotational Mayor is included, not excluded).
-- Already 5 from Wave-1 survivor chamber (official_count=5 carried through); guard idempotent.
UPDATE essentials.chambers SET official_count = 5
 WHERE id = '73422d25-c0a6-477a-b74f-2b38b94b6389'
   AND official_count IS DISTINCT FROM 5;

COMMIT;

-- Register structural migration in the ledger (OUTSIDE the transaction block).
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1027', 'burbank_complete')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. 5 occupied offices under 73422d25, all bidirectional:
--    SELECT COUNT(*) FROM essentials.offices o
--      JOIN essentials.politicians p ON p.id=o.politician_id
--      WHERE o.chamber_id='73422d25-c0a6-477a-b74f-2b38b94b6389' AND p.office_id=o.id;
--    -> 5
-- 2. title 'Mayor' on Takahashi (70e56076), 'Vice Mayor' on Mullins (9969febe),
--    'Council Member' on Perez (f205911b), Rizzotti (caea9243), Anthony (1294961c):
--    SELECT o.title, p.full_name FROM essentials.offices o
--      JOIN essentials.politicians p ON p.id=o.politician_id
--      WHERE o.chamber_id='73422d25-c0a6-477a-b74f-2b38b94b6389' ORDER BY p.external_id;
-- 3. ZERO LOCAL_EXEC offices under this gov (query via districts join):
--    SELECT COUNT(*) FROM essentials.offices o
--      JOIN essentials.districts d ON d.id=o.district_id
--      WHERE d.government_id='3e3deaea-c5f4-4a68-b3ae-a79589f544ea'
--        AND d.district_type='LOCAL_EXEC';
--    -> 0
-- 4. official_count=5:
--    SELECT official_count FROM essentials.chambers WHERE id='73422d25-c0a6-477a-b74f-2b38b94b6389';
--    -> 5
-- 5. all 5 district labels = 'At-Large' (no relabeling):
--    SELECT COUNT(*) FROM essentials.offices o
--      JOIN essentials.districts d ON d.id=o.district_id
--      WHERE o.chamber_id='73422d25-c0a6-477a-b74f-2b38b94b6389' AND d.label='At-Large';
--    -> 5
-- 6. split-section check = 0 rows for gov 3e3deaea:
--    SELECT COUNT(DISTINCT gb.body_key) FROM essentials.government_bodies gb
--      WHERE gb.geo_id = '0608954';
--    -> 1 (clean, no split-section defect)
-- 7. ledger MAX includes 1027:
--    SELECT version, name FROM supabase_migrations.schema_migrations WHERE version='1027';
--    -> ('1027', 'burbank_complete')
