-- 1035_norwalk_complete.sql
-- Phase 155 Wave 2 (NRWK-01): finalize Norwalk's 5-seat at-large roster.
-- Gov 15897159-e6bf-4d7e-9b45-44d62c4ebb8a; survivor council chamber 97397b0f-61f1-4251-bf29-3fd5f99c0108
-- (5 bidirectional offices after mig 1034).
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-22 (155-02 Task 1): NO DRIFT.
--
-- ROTATIONAL MAYOR = TITLE ON A SEAT (West Covina 1011 / Downey / Burbank 1027 model).
-- Norwalk is AT-LARGE with a ROTATIONAL Mayor (no directly-elected LOCAL_EXEC Mayor; the
-- mis-seeded LOCAL_EXEC Mayor office was converted to an At-Large council seat in mig 1034).
-- Five council seats elected citywide; Mayor selected annually by/from the council, one-year term.
-- Current rotational state (Dec 9, 2025 reorganization, valid through Dec 2026 — re-confirmed live
-- against norwalkca.gov/government/mayor_and_city_council 2026-06-22):
--   Mayor       = Jennifer Perez     (pol 3ed36508-9ae9-41af-aaba-e5e39bb87aa7)
--   Vice Mayor  = Margarita L. Rios  (pol bd64253b-0bd1-4b9f-85b1-76180c760d07)
-- Assumption A1: Dec 2025 reorg still current (next rotation Dec 2026; no mid-year change). Re-confirmed.
-- NO new politician. NO unlink. All 5 confirmed current per RESEARCH §Roster Verdict
--   (Ramirez/Rios/Valencia won re-election Nov 2024; Ayala/Perez mid-term).
-- CRITICAL: official_count=5 (rotational Mayor IS one of the 5 at-large seats — NOT 4).
--   Unlike Inglewood's directly-elected Mayor (excluded from council count), Norwalk's
--   rotational Mayor is just one of the 5 at-large council seats. West Covina/Burbank precedent.
-- PITFALL 2: do NOT set Mayor on Ayala (he was Mayor Dec 2024-Dec 2025; current Mayor is Perez).
-- DO NOT create a LOCAL_EXEC Mayor office. DO NOT relabel 'At-Large' districts.
-- OUT OF SCOPE (untouched): Norwalk-La Mirada Unified School District gov d4f9a7fa-8f22-40cd-90d8-639f9a6c2c8c.

BEGIN;

-- Part A: Mayor / Vice Mayor titles (rotational, title-on-seat), keep the rest 'Councilmember'.
-- All guarded IS DISTINCT FROM for idempotency (re-run safe). WHERE by politician_id (unambiguous).

UPDATE essentials.offices SET title = 'Mayor'
 WHERE politician_id = '3ed36508-9ae9-41af-aaba-e5e39bb87aa7'
   AND title IS DISTINCT FROM 'Mayor'; -- Jennifer Perez (current Mayor)

UPDATE essentials.offices SET title = 'Vice Mayor'
 WHERE politician_id = 'bd64253b-0bd1-4b9f-85b1-76180c760d07'
   AND title IS DISTINCT FROM 'Vice Mayor'; -- Margarita L. Rios (current Vice Mayor)

UPDATE essentials.offices SET title = 'Councilmember'
 WHERE politician_id IN (
   '5e8bcf17-3a4d-4614-a71c-c4ea8396f7cb',  -- Tony Ayala (was Mayor 2024-2025; now Councilmember)
   'e3b9af1b-3704-4bc5-a6ef-ab1f814bd29d',  -- Rick Ramirez
   'ba647863-25fb-4ccf-9cb0-5a1c912d1b27'   -- Ana Valencia
 )
   AND title IS DISTINCT FROM 'Councilmember';

-- Part B: official_count = 5 (all 5 are council seats; rotational Mayor is included, not excluded).
UPDATE essentials.chambers SET official_count = 5
 WHERE id = '97397b0f-61f1-4251-bf29-3fd5f99c0108'
   AND official_count IS DISTINCT FROM 5;

-- Part C: exactly-one-Mayor assert (adapted from 992_downey_mayor_correction.sql).
DO $$
DECLARE mayor_ct int;
BEGIN
  SELECT COUNT(*) INTO mayor_ct FROM essentials.offices
    WHERE chamber_id = '97397b0f-61f1-4251-bf29-3fd5f99c0108' AND title = 'Mayor';
  IF mayor_ct <> 1 THEN
    RAISE EXCEPTION 'Expected exactly 1 Mayor in chamber 97397b0f, found %', mayor_ct;
  END IF;
END $$;

COMMIT;

-- Register structural migration in the ledger (OUTSIDE the transaction block).
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1035', 'norwalk_complete')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. 5 occupied offices under 97397b0f, all bidirectional:
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id
--      WHERE o.chamber_id='97397b0f-61f1-4251-bf29-3fd5f99c0108' AND p.office_id=o.id;  -> 5
-- 2. titles: Mayor=Perez (666845), Vice Mayor=Rios (-201328), Councilmember=Ayala/-Ramirez/-Valencia:
--    SELECT o.title, p.full_name, p.external_id FROM essentials.offices o
--      JOIN essentials.politicians p ON p.id=o.politician_id
--      WHERE o.chamber_id='97397b0f-61f1-4251-bf29-3fd5f99c0108' ORDER BY p.external_id;
-- 3. exactly one Mayor:
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='97397b0f-61f1-4251-bf29-3fd5f99c0108' AND title='Mayor';  -> 1
-- 4. Ayala NOT Mayor:
--    SELECT o.title FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id WHERE p.external_id=-200876;  -> 'Councilmember'
-- 5. ZERO LOCAL_EXEC offices under this gov:
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
--      WHERE d.government_id='15897159-e6bf-4d7e-9b45-44d62c4ebb8a' AND d.district_type='LOCAL_EXEC';  -> 0
-- 6. official_count=5:
--    SELECT official_count FROM essentials.chambers WHERE id='97397b0f-61f1-4251-bf29-3fd5f99c0108';  -> 5
-- 7. all 5 district labels 'At-Large' (no relabel):
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
--      WHERE o.chamber_id='97397b0f-61f1-4251-bf29-3fd5f99c0108' AND d.label='At-Large';  -> 5
-- 8. ledger MAX includes 1035:
--    SELECT version, name FROM supabase_migrations.schema_migrations WHERE version='1035';
