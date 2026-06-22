-- 1034_norwalk_reconcile.sql
-- Phase 155 Wave 1 (NRWK-01): reconcile City of Norwalk structural defects.
-- Gov 15897159-e6bf-4d7e-9b45-44d62c4ebb8a 'City of Norwalk, California, US'.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-22 (155-01 Task 1): NO DRIFT.
--
-- NORWALK IS AT-LARGE WITH A ROTATIONAL MAYOR (RESEARCH §Form of Government Verdict;
-- confirmed via norwalkca.gov, HIGH confidence: "Each year the Council selects one of its
-- members to serve as Mayor"). FIVE at-large council seats elected citywide + a ROTATIONAL
-- council-selected Mayor (title on a seat, NOT a separate LOCAL_EXEC office). No CVRA district
-- transition. This is the West Covina/Downey/Burbank rotational model.
--
-- KEY NORWALK-SPECIFIC STEP (no exact prior analog): the DB models Norwalk as a separate
-- directly-elected LOCAL_EXEC Mayor (Tony Ayala, district "Norwalk Mayor" 4126e079). That is a
-- MIS-SEED -> convert Ayala's office to a 5th At-Large council seat and drop the LOCAL_EXEC district.
--
-- Fixes (Burbank-class merge + the LOCAL_EXEC conversion):
--   (1) Backfill geo_id '0652526' (was NULL), empty-string-safe guard.
--   (2) Repair the FOUR one-directional back-pointers BEFORE chamber move:
--       Ayala (pol 5e8bcf17 -> office 5edc1993), Ramirez (pol e3b9af1b -> office 119e0ffd),
--       Rios (pol bd64253b -> office 87df841f), Valencia (pol ba647863 -> office 4d8a62f7)
--       have politicians.office_id NULL; set to match offices.politician_id.
--       All 5 are LEGITIMATE current council members per RESEARCH §Roster Verdict. DO NOT unlink.
--   (3) Merge duplicate 'City Council' chambers via move-then-delete: move the doomed-chamber
--       (e7e787f7) office -- Perez 8e25ebb7 -- into the survivor 97397b0f FIRST, assert the
--       doomed chamber is empty, THEN delete it. Target chambers BY UUID ONLY (both share name
--       'City Council' / slug 'norwalk-city-council').
--   (4) Re-point Perez's moved office from the doomed At-Large district (f9e8037d) to the
--       surviving At-Large district (5677c0ab). No relabel: all seats are 'At-Large' and stay so.
--   (5) Delete the now-orphaned doomed At-Large district f9e8037d (guarded NOT EXISTS).
--   (6) LOCAL_EXEC Mayor -> At-Large council seat conversion (Norwalk-specific): Ayala's office
--       (5edc1993) is ALREADY in the survivor chamber 97397b0f, so re-point its district
--       4126e079 -> 5677c0ab and set title 'Councilmember' (guard on district_id). Then assert
--       the LOCAL_EXEC district is empty and delete it (4126e079).
--   (7) Title normalization: set Ramirez/Rios/Valencia non-Mayor seats to 'Councilmember' so no
--       'Council Member' (space) string remains. (Perez already 'Councilmember'; Ayala set in (6).
--       Wave 2 overwrites Perez->Mayor and Rios->Vice Mayor.)
--
-- NOT done here (Wave 2 handles): rotational Mayor (Perez) / Vice Mayor (Rios) titles, official_count=5.
-- OUT OF SCOPE (untouched): Norwalk-La Mirada Unified School District gov d4f9a7fa-8f22-40cd-90d8-639f9a6c2c8c.

BEGIN;

-- (1) geo_id backfill (empty-string-safe guard)
UPDATE essentials.governments
   SET geo_id = '0652526'
 WHERE id = '15897159-e6bf-4d7e-9b45-44d62c4ebb8a'
   AND (geo_id IS NULL OR geo_id = '');

-- (2) Repair the FOUR one-directional back-pointers (politicians.office_id NULL).
-- Guarded IS DISTINCT FROM (idempotent). Perez is bidirectional-clean -> no repair.
UPDATE essentials.politicians
   SET office_id = '5edc1993-9e73-44e9-ae71-1107626d4ec2'
 WHERE id = '5e8bcf17-3a4d-4614-a71c-c4ea8396f7cb'
   AND office_id IS DISTINCT FROM '5edc1993-9e73-44e9-ae71-1107626d4ec2'; -- Tony Ayala

UPDATE essentials.politicians
   SET office_id = '119e0ffd-f6cb-414e-8eb2-a1fe42bfee6d'
 WHERE id = 'e3b9af1b-3704-4bc5-a6ef-ab1f814bd29d'
   AND office_id IS DISTINCT FROM '119e0ffd-f6cb-414e-8eb2-a1fe42bfee6d'; -- Rick Ramirez

UPDATE essentials.politicians
   SET office_id = '87df841f-00bb-479c-8b40-f98490ce7fb1'
 WHERE id = 'bd64253b-0bd1-4b9f-85b1-76180c760d07'
   AND office_id IS DISTINCT FROM '87df841f-00bb-479c-8b40-f98490ce7fb1'; -- Margarita L. Rios (Vice Mayor, Wave 2)

UPDATE essentials.politicians
   SET office_id = '4d8a62f7-5a9b-4dd1-ba3c-63d2ca097470'
 WHERE id = 'ba647863-25fb-4ccf-9cb0-5a1c912d1b27'
   AND office_id IS DISTINCT FROM '4d8a62f7-5a9b-4dd1-ba3c-63d2ca097470'; -- Ana Valencia

-- (3) MERGE duplicate chamber -- move the doomed-chamber office (Perez) into the survivor FIRST.
-- Target by UUID ONLY (both chambers share name 'City Council' / slug 'norwalk-city-council').
UPDATE essentials.offices
   SET chamber_id = '97397b0f-61f1-4251-bf29-3fd5f99c0108'  -- SURVIVOR
 WHERE chamber_id = 'e7e787f7-4695-4747-9dd7-b111472ca9ae'; -- DOOMED

-- Assert the doomed chamber is empty before deleting it.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE chamber_id = 'e7e787f7-4695-4747-9dd7-b111472ca9ae') > 0 THEN
    RAISE EXCEPTION 'Chamber e7e787f7 still has offices; aborting before delete';
  END IF;
END $$;

DELETE FROM essentials.chambers WHERE id = 'e7e787f7-4695-4747-9dd7-b111472ca9ae';

-- (4) Re-point Perez's moved office from the doomed At-Large district to the surviving one.
-- Guarded IS DISTINCT FROM (idempotent). No relabel (Norwalk stays at-large).
UPDATE essentials.offices
   SET district_id = '5677c0ab-e038-45d9-a744-141b28329036'  -- surviving At-Large district
 WHERE id = '8e25ebb7-3ee3-45f8-89c5-72ea60732cd0'           -- Perez office
   AND district_id IS DISTINCT FROM '5677c0ab-e038-45d9-a744-141b28329036';

-- (5) Delete the now-orphaned doomed 'At-Large' district (guarded NOT EXISTS).
DELETE FROM essentials.districts d
 WHERE d.id = 'f9e8037d-e311-4583-9623-3201259ba7e4'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- (6) LOCAL_EXEC Mayor -> At-Large council seat conversion (Norwalk-specific mis-seed fix).
-- Ayala's office (5edc1993) is ALREADY in the survivor chamber 97397b0f, so re-point its
-- district (4126e079 LOCAL_EXEC -> 5677c0ab At-Large) and set title 'Councilmember'.
-- Guard on district_id so re-runs are no-ops. (Wave 1 title = 'Councilmember'; Ayala is NOT the
-- current Mayor -- Perez is, set in Wave 2.)
UPDATE essentials.offices
   SET district_id = '5677c0ab-e038-45d9-a744-141b28329036',
       title = 'Councilmember'
 WHERE id = '5edc1993-9e73-44e9-ae71-1107626d4ec2'           -- Ayala's (formerly LOCAL_EXEC) office
   AND district_id IS DISTINCT FROM '5677c0ab-e038-45d9-a744-141b28329036';

-- Assert the LOCAL_EXEC "Norwalk Mayor" district is empty, then delete it.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE district_id = '4126e079-d0ff-494e-8371-d6ef2e98da3f') > 0 THEN
    RAISE EXCEPTION 'LOCAL_EXEC district 4126e079 still has offices; aborting before delete';
  END IF;
END $$;

DELETE FROM essentials.districts d
 WHERE d.id = '4126e079-d0ff-494e-8371-d6ef2e98da3f'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- (7) Title normalization -- eliminate the 'Council Member' (space) space-form on the remaining
-- non-Mayor seats. Guarded IS DISTINCT FROM (idempotent). Wave 2 overwrites Perez->Mayor, Rios->Vice Mayor.
UPDATE essentials.offices
   SET title = 'Councilmember'
 WHERE id IN (
   '119e0ffd-f6cb-414e-8eb2-a1fe42bfee6d',  -- Ramirez
   '87df841f-00bb-479c-8b40-f98490ce7fb1',  -- Rios (normalized now; -> Vice Mayor in Wave 2)
   '4d8a62f7-5a9b-4dd1-ba3c-63d2ca097470'   -- Valencia
 )
   AND title IS DISTINCT FROM 'Councilmember';

COMMIT;

-- Register structural migration in the ledger (OUTSIDE the transaction block).
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1034', 'norwalk_reconcile')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. gov geo_id = '0652526', state 'CA'
--    SELECT geo_id, state FROM essentials.governments WHERE id='15897159-e6bf-4d7e-9b45-44d62c4ebb8a';
-- 2. exactly one 'City Council' chamber (survivor 97397b0f); e7e787f7 gone
--    SELECT COUNT(*) FROM essentials.chambers WHERE government_id='15897159-e6bf-4d7e-9b45-44d62c4ebb8a' AND name='City Council';
--    SELECT COUNT(*) FROM essentials.chambers WHERE id='e7e787f7-4695-4747-9dd7-b111472ca9ae';
-- 3. survivor 97397b0f has 5 offices (all At-Large, bidirectional)
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='97397b0f-61f1-4251-bf29-3fd5f99c0108';
-- 4. all 5 offices bidirectional (0 mismatches)
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id
--      WHERE o.chamber_id='97397b0f-61f1-4251-bf29-3fd5f99c0108' AND p.office_id<>o.id;
-- 5. Ayala(-200876)/Ramirez(-201327)/Rios(-201328)/Valencia(-201329) office_id NOT NULL
--    SELECT external_id, office_id FROM essentials.politicians WHERE external_id IN (-200876,-201327,-201328,-201329);
-- 6. doomed At-Large district f9e8037d deleted; LOCAL_EXEC district 4126e079 deleted
--    SELECT COUNT(*) FROM essentials.districts WHERE id IN ('f9e8037d-e311-4583-9623-3201259ba7e4','4126e079-d0ff-494e-8371-d6ef2e98da3f');
-- 7. NO LOCAL_EXEC office under the gov
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
--      JOIN essentials.chambers c ON c.id=o.chamber_id
--      WHERE c.government_id='15897159-e6bf-4d7e-9b45-44d62c4ebb8a' AND d.district_type='LOCAL_EXEC';
-- 8. no 'Council Member' (space) titles remain
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='97397b0f-61f1-4251-bf29-3fd5f99c0108' AND title='Council Member';
-- 9. split-section check returns 0 rows for gov 15897159
--    SELECT g.name, COUNT(DISTINCT gb.mtfcc) section_count
--    FROM essentials.governments g
--    JOIN essentials.government_bodies gb ON gb.government_id = g.id
--    WHERE g.id = '15897159-e6bf-4d7e-9b45-44d62c4ebb8a'
--    GROUP BY g.name HAVING COUNT(DISTINCT gb.mtfcc) > 1;
-- 10. migration 1034 registered
--    SELECT version, name FROM supabase_migrations.schema_migrations WHERE version='1034';
-- 11. one-liner health check:
--    SELECT
--      (SELECT geo_id FROM essentials.governments WHERE id='15897159-e6bf-4d7e-9b45-44d62c4ebb8a') as geo_id,
--      (SELECT COUNT(*) FROM essentials.chambers WHERE government_id='15897159-e6bf-4d7e-9b45-44d62c4ebb8a') as chamber_count;
-- Expected: geo_id='0652526', chamber_count=1 (official_count finalized in Wave 2)
