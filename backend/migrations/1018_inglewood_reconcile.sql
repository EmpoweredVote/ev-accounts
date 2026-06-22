-- 1018_inglewood_reconcile.sql
-- Phase 153 Wave 1 (INGL-01): reconcile City of Inglewood structural defects.
-- Gov af811c4b-e4da-4f30-ac33-9a7fe7d434ba 'City of Inglewood, California, US'.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-21 (153-01 Task 1): NO DRIFT.
--
-- INGLEWOOD IS BY-DISTRICT WITH A DIRECTLY-ELECTED MAYOR (RESEARCH §CQ-1, verified on
-- cityofinglewood.org district pages + Mayor bio): FOUR single-member council districts
-- (D1-D4) + a DIRECTLY-ELECTED citywide Mayor (James T. Butts Jr., LOCAL_EXEC, in office
-- since 2011). This is the El Monte (151) / Lancaster (145) directly-elected-Mayor model
-- (Mayor is a SEPARATE LOCAL_EXEC office, KEPT as-is) -- NOT West Covina's rotational title.
--
-- Fixes (the messiest reconcile in the 142-152 series):
--   (1) Backfill geo_id '0636546' (was NULL), empty-string-safe.
--   (2) Repair the two persisting one-directional back-pointers (politicians.office_id NULL):
--       Butts (pol f5775ca1 -> office 90121859) and Dotson (pol 3e73448b -> office 6b20a733),
--       so both link directions are live before the chamber move. (Eloy Jr's third
--       one-directional link is resolved by the dedup unlink in step 3, not repaired here.)
--   (3) ELOY MORALES DEDUP (CONTEXT D-01b; RESEARCH CQ-3 -- CONFIRMED SAME PERSON, the D3
--       councilman since 2003): "Eloy Morales Jr." (-201081, pol ff97a6bb, office 7fd55592,
--       1 image, one-directional) and "Eloy Morales" (666263, pol 6ed19c10, office ddcd280b,
--       0 images, bidirectional, SURVIVOR). FIRST migrate the dup's image to the survivor,
--       THEN unlink-not-delete the dup person (-201081 / ff97a6bb -- politician + image rows
--       KEPT, both link directions nulled), THEN delete the now-empty duplicate office shell
--       7fd55592 (no politician, no data -- the dedup collapsing the duplicate SEAT; the
--       duplicate PERSON is preserved). [DEVIATION from plan step (4)'s "move 7fd55592
--       harmlessly": deleting the empty dup office achieves the plan's own expected survivor
--       count of 5 and the CONTEXT end-state of Mayor + D1-D4 = 5 offices, and avoids a
--       phantom At-Large seat -- documented in 153-01-SUMMARY.]
--   (4) Merge the two duplicate 'City Council' chambers via move-then-delete: move the two
--       REMAINING doomed-chamber (8b99bcf0) offices -- Butts 90121859 + Dotson 6b20a733 --
--       into the survivor a25a6dea FIRST, assert the doomed chamber is empty, THEN delete it.
--       Target chambers BY UUID ONLY (both share name 'City Council' / slug
--       'inglewood-city-council').
--   (5) BY-DISTRICT relabel of the three CURRENT council districts (each had exactly ONE
--       office ref in pre-flight -> no shared-district split needed; the doomed shared row
--       d01253fb held only the two unlinked/departed offices):
--         Gray  office 8e9b0c61 -> district 5b24e423 -> 'District 1'
--         Eloy  office ddcd280b -> district d3690d9d -> 'District 3'
--         Faulk office 35b92278 -> district 63d01cea -> 'District 4'
--       District 2 (Padilla) + Dotson unlink + official_count are Wave 2 (mig 1019).
--   (6) Keep Mayor Butts as-is: office 90121859 / district 3f3c583e stays LOCAL_EXEC title
--       'Inglewood Mayor' -- UNTOUCHED (El Monte 1000 directly-elected-Mayor convention).
--
-- OUT OF SCOPE (untouched): the same-name Inglewood Unified School District gov
--   3c4c8dca-894e-403f-8935-272989bc3c46. NEVER referenced here.

BEGIN;

-- (1) geo_id backfill (empty-string-safe)
UPDATE essentials.governments
   SET geo_id = '0636546'
 WHERE id = 'af811c4b-e4da-4f30-ac33-9a7fe7d434ba'
   AND (geo_id IS NULL OR geo_id = '');

-- (2) Repair the two PERSISTING one-directional back-pointers (guarded IS DISTINCT FROM).
-- Butts (Mayor, stays) and Dotson (stays through Wave 1; unlinked in Wave 2).
UPDATE essentials.politicians
   SET office_id = '90121859-d5d4-4b0f-950e-5f6e9262abb4'
 WHERE id = 'f5775ca1-99f4-4cc2-acf2-5afaacdd94b3'
   AND office_id IS DISTINCT FROM '90121859-d5d4-4b0f-950e-5f6e9262abb4'; -- Butts (Mayor)
UPDATE essentials.politicians
   SET office_id = '6b20a733-45f1-4db1-a528-029aeca8aba3'
 WHERE id = '3e73448b-bd10-4e6b-bf2a-c9368cf64af9'
   AND office_id IS DISTINCT FROM '6b20a733-45f1-4db1-a528-029aeca8aba3'; -- Dotson

-- (3) ELOY MORALES DEDUP (same person; survivor = 666263 / 6ed19c10).
-- (3a) Migrate the dup's single image to the survivor FIRST (survivor had 0 images).
UPDATE essentials.politician_images
   SET politician_id = '6ed19c10-7b34-47f0-8705-0d154271e362'   -- Eloy Morales 666263 (survivor)
 WHERE politician_id = 'ff97a6bb-0c1c-465a-9300-817385a8fceb';  -- Eloy Morales Jr. -201081 (dup)
-- (3b) Unlink-not-delete the dup PERSON (both directions; politician + image rows KEPT).
UPDATE essentials.offices
   SET politician_id = NULL
 WHERE id = '7fd55592-c8e9-45a7-9ddf-a2d1a9af5435'
   AND politician_id IS NOT NULL;                               -- dup office, now empty
UPDATE essentials.politicians
   SET office_id = NULL
 WHERE id = 'ff97a6bb-0c1c-465a-9300-817385a8fceb'
   AND office_id IS NOT NULL;                                   -- dup person, unlinked (KEPT)
-- (3c) Delete the now-empty duplicate office SHELL (guarded: only if vacated).
DELETE FROM essentials.offices
 WHERE id = '7fd55592-c8e9-45a7-9ddf-a2d1a9af5435'
   AND politician_id IS NULL;

-- (4) MERGE duplicate chamber -- move the two REMAINING doomed-chamber offices into the
-- survivor FIRST. Target by UUID ONLY (both chambers share name + slug).
UPDATE essentials.offices
   SET chamber_id = 'a25a6dea-7f26-4f5e-bc6a-2a5d321063d5'
 WHERE chamber_id = '8b99bcf0-813d-459a-b7e1-f82e12080ffc';

-- Assert the doomed chamber is empty before deleting it.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE chamber_id = '8b99bcf0-813d-459a-b7e1-f82e12080ffc') > 0 THEN
    RAISE EXCEPTION 'Chamber 8b99bcf0 still has offices; aborting before delete';
  END IF;
END $$;

DELETE FROM essentials.chambers WHERE id = '8b99bcf0-813d-459a-b7e1-f82e12080ffc';

-- (5) BY-DISTRICT relabel of the three current council districts (label only; each row had a
-- single office ref in pre-flight; guarded IS DISTINCT FROM). D2 is Wave 2.
UPDATE essentials.districts SET label = 'District 1'
 WHERE id = '5b24e423-9dad-4655-814f-6c4954d91943' AND label IS DISTINCT FROM 'District 1'; -- Gray
UPDATE essentials.districts SET label = 'District 3'
 WHERE id = 'd3690d9d-c70a-426d-9826-074d01f05fc5' AND label IS DISTINCT FROM 'District 3'; -- Eloy Morales (666263)
UPDATE essentials.districts SET label = 'District 4'
 WHERE id = '63d01cea-17b9-44f1-93b1-c0fe236fc0ae' AND label IS DISTINCT FROM 'District 4'; -- Faulk

-- (6) Mayor Butts kept as-is: office 90121859 / district 3f3c583e stays LOCAL_EXEC
-- 'Inglewood Mayor' -- intentionally UNTOUCHED (directly-elected Mayor, El Monte convention).

COMMIT;

-- Register structural migration in the ledger.
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1018', 'inglewood_reconcile')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. gov geo_id = '0636546', state 'CA'
--    SELECT geo_id, state FROM essentials.governments WHERE id='af811c4b-e4da-4f30-ac33-9a7fe7d434ba';
-- 2. exactly one 'City Council' chamber (survivor a25a6dea); 8b99bcf0 gone
--    SELECT id, name FROM essentials.chambers WHERE government_id='af811c4b-e4da-4f30-ac33-9a7fe7d434ba';
-- 3. survivor a25a6dea has 5 offices (Gray D1, Eloy D3, Faulk D4, Butts Mayor, Dotson At-Large[Wave2])
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='a25a6dea-7f26-4f5e-bc6a-2a5d321063d5';
-- 4. Eloy dup unlinked + image migrated: -201081 office_id NULL; 666263 has 1 image; dup office 7fd55592 gone
-- 5. bidirectional integrity for current survivors (666263,666264,666261,-200740): 0 mismatches
-- 6. council districts D1/D3/D4 relabeled (no 'At-Large' on Gray/Eloy/Faulk); Mayor LOCAL_EXEC intact
-- 7. feedback_section_split_check -> 0 rows for Inglewood (gov af811c4b)
-- 8. migration 1018 registered in schema_migrations
