-- 946_pasadena_reconcile.sql
-- Phase 149 Wave 1 (PASA-01): reconcile City of Pasadena structural defects.
-- Gov d25619a9-7276-4e8b-b7ae-8028e408aee0 'City of Pasadena, California, US'.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-20 (149-01 Task 1).
--
-- Fixes:
--   (1) Backfill geo_id '0656000' (was NULL), empty-string-safe.
--   (2) Merge the two duplicate 'City Council' chambers via move-then-delete:
--       move BOTH doomed-chamber (bdd1acad) offices -- Gordo/Mayor fc5e372a + Hampton 0c357b48 --
--       into the survivor 2e7f01d0 FIRST, assert the doomed chamber is empty, THEN delete it.
--   (3) BY-DISTRICT form of government: relabel the wrongly-'At-Large' council district rows to
--       'District 1'..'District 7' per the RESEARCH §3 occupant map. A shared-district defect was
--       found (Madison f2cb13dd + Rivas 7bdb4f77 BOTH pointed at 4c08b6d3) -- resolved Pomona-style
--       by repurposing the unused orphan At-Large row ab0a29ee (0 office refs) as Rivas's District 5,
--       repointing Rivas's office off the shared row, then relabeling the shared row to District 6.
--   (4) Dedupe Jason Lyon's duplicate politician_images row (two rows, identical URL).
--
-- Occupant -> district map (RESEARCH §3, authoritative):
--   Hampton (office 0c357b48, district c9408f3e) -> District 1
--   Cole    (office 7ab2730c, district f34e6ce9) -> District 2
--   Jones   (office e3617ff5, district 9747b1a0) -> District 3
--   Masuda  (office 0bc62efd, district 5bb79df7) -> District 4
--   Rivas   (office 7bdb4f77, was shared 4c08b6d3) -> District 5 (repurposed orphan ab0a29ee)
--   Madison (office f2cb13dd, district 4c08b6d3)  -> District 6
--   Lyon    (office 0cd97f4e, district b8f9ba37)  -> District 7
--   Gordo   (office fc5e372a, district 3bb6c470 'Pasadena Mayor' LOCAL_EXEC) -> KEEP as-is (only moved)
-- 'South Pasadena Mayor' (district 66e1c2b0, also geo_id 0656000) -> OUT OF SCOPE, untouched.

BEGIN;

-- (1) geo_id backfill (Pitfall 8: empty-string guard)
UPDATE essentials.governments
   SET geo_id = '0656000'
 WHERE id = 'd25619a9-7276-4e8b-b7ae-8028e408aee0'
   AND (geo_id IS NULL OR geo_id = '');

-- (2) MERGE duplicate chamber -- move BOTH doomed-chamber offices into the survivor FIRST.
UPDATE essentials.offices
   SET chamber_id = '2e7f01d0-69dd-4301-b24c-58d83eb19f47'
 WHERE chamber_id = 'bdd1acad-f22d-4fa3-8ab5-667eed0e3d82';

-- assert the doomed chamber is empty before deleting it
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE chamber_id = 'bdd1acad-f22d-4fa3-8ab5-667eed0e3d82') > 0 THEN
    RAISE EXCEPTION 'Chamber bdd1acad still has offices; aborting before delete';
  END IF;
END $$;

DELETE FROM essentials.chambers WHERE id = 'bdd1acad-f22d-4fa3-8ab5-667eed0e3d82';

-- (3) BY-DISTRICT relabel (label only; district_type/geo_id/state unchanged; each guarded).
UPDATE essentials.districts SET label = 'District 1'
 WHERE id = 'c9408f3e-ba83-4249-9998-2e19a07e4043' AND label IS DISTINCT FROM 'District 1'; -- Hampton
UPDATE essentials.districts SET label = 'District 2'
 WHERE id = 'f34e6ce9-f96b-4937-a003-58ad0fa01bbd' AND label IS DISTINCT FROM 'District 2'; -- Cole
UPDATE essentials.districts SET label = 'District 3'
 WHERE id = '9747b1a0-438d-495e-b369-049711aa9646' AND label IS DISTINCT FROM 'District 3'; -- Jones
UPDATE essentials.districts SET label = 'District 4'
 WHERE id = '5bb79df7-028e-43b7-a4cf-6a587c1bbada' AND label IS DISTINCT FROM 'District 4'; -- Masuda
UPDATE essentials.districts SET label = 'District 7'
 WHERE id = 'b8f9ba37-9540-44e4-9d1f-076c1b87c916' AND label IS DISTINCT FROM 'District 7'; -- Lyon

-- Resolve Madison/Rivas shared-district defect (4c08b6d3 had 2 office refs):
--   a) repurpose unused orphan At-Large row ab0a29ee as District 5 (Rivas)
UPDATE essentials.districts SET label = 'District 5'
 WHERE id = 'ab0a29ee-67dc-4f1b-ac42-78ecdaa7cace' AND label IS DISTINCT FROM 'District 5'; -- Rivas
--   b) repoint Rivas's office off the shared row to District 5
UPDATE essentials.offices SET district_id = 'ab0a29ee-67dc-4f1b-ac42-78ecdaa7cace'
 WHERE id = '7bdb4f77-18c6-472a-bb68-704a7d1d0b3a'
   AND district_id IS DISTINCT FROM 'ab0a29ee-67dc-4f1b-ac42-78ecdaa7cace'; -- Rivas
--   c) the shared row now belongs to Madison only -> District 6
UPDATE essentials.districts SET label = 'District 6'
 WHERE id = '4c08b6d3-a63c-4125-bc52-3b7d35ab94a3' AND label IS DISTINCT FROM 'District 6'; -- Madison

-- (4) Dedupe Jason Lyon's duplicate image (both rows point at the same storage object).
--     Keep the press_use row (95d15841); delete the cc_by_sa duplicate. Wave 3 re-verifies license.
DELETE FROM essentials.politician_images
 WHERE id = '81333d16-4eee-45b2-8fa2-c65e83a8c75e';

COMMIT;

-- Register structural migration in the ledger.
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('946', 'pasadena_reconcile')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. gov geo_id = '0656000'
--    SELECT geo_id, state FROM essentials.governments WHERE id='d25619a9-7276-4e8b-b7ae-8028e408aee0';
-- 2. exactly one 'City Council' chamber (survivor 2e7f01d0); bdd1acad gone
--    SELECT id, name FROM essentials.chambers WHERE government_id='d25619a9-7276-4e8b-b7ae-8028e408aee0';
-- 3. survivor has 8 offices
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='2e7f01d0-69dd-4301-b24c-58d83eb19f47';
-- 4. 8 Pasadena district rows: 'Pasadena Mayor' (LOCAL_EXEC) + 'District 1'..'District 7' (LOCAL)
--    each council office -> correct district label (Hampton D1 .. Lyon D7)
-- 5. Lyon (657582) has exactly 1 image; Rivas (-700150) linked to office 7bdb4f77 on District 5
-- 6. feedback_section_split_check -> 0 rows for Pasadena
