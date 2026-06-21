-- 1000_elmonte_reconcile.sql
-- Phase 151 Wave 1 (ELMN-01): reconcile City of El Monte structural defects.
-- Gov f5fe3651-75c2-4ede-86e2-c13fc008d545 'City of El Monte, California, US'.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-21 (151-01 Task 1).
--
-- EL MONTE IS BY-DISTRICT WITH A DIRECTLY-ELECTED MAYOR (RESEARCH §D-02 Resolution, Ord. 3010
-- Apr 5 2022): SIX single-member council districts (D1-D6) + a separately, directly-elected
-- citywide Mayor (LOCAL_EXEC). This OVERTURNS the CONTEXT.md At-Large default. Pasadena (946) /
-- Pomona by-district relabel pattern for the council; Lancaster/Pasadena directly-elected-Mayor
-- pattern for Ancona (NOT the Downey rotational collapse).
--
-- Fixes:
--   (1) Backfill geo_id '0622230' (was NULL), empty-string-safe.
--   (2) Merge the two duplicate 'City Council' chambers via move-then-delete:
--       move BOTH doomed-chamber (b41e0065) offices -- Longoria 3040818a + Ruedas 06d458fe --
--       into the survivor 5ca38f3a FIRST, assert the doomed chamber is empty, THEN delete it.
--   (3) BY-DISTRICT form of government: relabel/create district rows D1-D6 per RESEARCH §D-02/D-03.
--       Pre-flight found a 3-WAY shared-district defect: row ee390480 'At-Large' had 3 office refs
--       (Crippen-Thomas 211af77a, Galvan 3ffcb893, Herrera 7e9eac5e). No unused orphan At-Large
--       row exists (unlike Pasadena 946 / Downey 990), so the displaced occupants get NEW rows:
--         ee390480 -> relabel 'District 1' (keep Crippen-Thomas, office 211af77a)
--         NEW row   -> 'District 2', repoint Herrera (office 7e9eac5e)
--         717a7d6d  -> relabel 'District 3' (Ruedas's own row, office 06d458fe)
--         12026291  -> relabel 'District 4' (Longoria's own row, office 3040818a)
--         NEW row   -> 'District 5', repoint Galvan (office 3ffcb893)
--         NEW row   -> 'District 6' (Cortez; politician + seat created in Plan 02 / mig 1001)
--   (4) KEEP the directly-elected Mayor EXACTLY AS-IS: Ancona office 57d646fc, district 2c00ef36
--       'El Monte Mayor' LOCAL_EXEC. Do NOT relabel, collapse, or change district_type.
--
-- OUT OF SCOPE (untouched): the 'South El Monte Mayor' LOCAL_EXEC district row mis-tagged with
--   geo_id '0622230' belongs to South El Monte (gov 71d17594) -- a pre-existing cross-gov stray
--   of the same class as the documented 'South Pasadena Mayor'/0656000 mislabel. Left as-is.
--   (Cortez creation/seat, back-pointer repair, official_count are all Plan 02 / mig 1001.)

BEGIN;

-- (1) geo_id backfill (empty-string-safe)
UPDATE essentials.governments
   SET geo_id = '0622230'
 WHERE id = 'f5fe3651-75c2-4ede-86e2-c13fc008d545'
   AND (geo_id IS NULL OR geo_id = '');

-- (2) MERGE duplicate chamber -- move BOTH doomed-chamber offices into the survivor FIRST.
-- Target by UUID ONLY (both chambers share name 'City Council' / slug 'el-monte-city-council').
UPDATE essentials.offices
   SET chamber_id = '5ca38f3a-ea2e-4160-abb5-f897702b6cb6'
 WHERE chamber_id = 'b41e0065-40ed-4486-8ff1-6fe73e0c2532';

-- Assert the doomed chamber is empty before deleting it.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE chamber_id = 'b41e0065-40ed-4486-8ff1-6fe73e0c2532') > 0 THEN
    RAISE EXCEPTION 'Chamber b41e0065 still has offices; aborting before delete';
  END IF;
END $$;

DELETE FROM essentials.chambers WHERE id = 'b41e0065-40ed-4486-8ff1-6fe73e0c2532';

-- (3) BY-DISTRICT relabel + create (resolve the 3-way shared-district defect on ee390480).
-- Create new rows for the two displaced occupants (Herrera D2, Galvan D5) + Cortez (D6). Guarded.
INSERT INTO essentials.districts (label, district_type, geo_id, state)
SELECT 'District 2', 'LOCAL', '0622230', 'CA'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label = 'District 2' AND geo_id = '0622230');
INSERT INTO essentials.districts (label, district_type, geo_id, state)
SELECT 'District 5', 'LOCAL', '0622230', 'CA'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label = 'District 5' AND geo_id = '0622230');
INSERT INTO essentials.districts (label, district_type, geo_id, state)
SELECT 'District 6', 'LOCAL', '0622230', 'CA'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label = 'District 6' AND geo_id = '0622230');

-- Repoint the two displaced occupants off the shared row ee390480 to their NEW rows.
UPDATE essentials.offices
   SET district_id = (SELECT id FROM essentials.districts WHERE label = 'District 2' AND geo_id = '0622230')
 WHERE id = '7e9eac5e-ffd7-4a6a-a417-01e3607b733d'
   AND district_id IS DISTINCT FROM
       (SELECT id FROM essentials.districts WHERE label = 'District 2' AND geo_id = '0622230'); -- Herrera
UPDATE essentials.offices
   SET district_id = (SELECT id FROM essentials.districts WHERE label = 'District 5' AND geo_id = '0622230')
 WHERE id = '3ffcb893-5924-47f6-b861-9eda1ac18f25'
   AND district_id IS DISTINCT FROM
       (SELECT id FROM essentials.districts WHERE label = 'District 5' AND geo_id = '0622230'); -- Galvan

-- Relabel the three single-occupant rows (label only; district_type/geo_id/state unchanged; guarded).
UPDATE essentials.districts SET label = 'District 1'
 WHERE id = 'ee390480-3d15-4fee-a181-e75c53e2b7cb' AND label IS DISTINCT FROM 'District 1'; -- Crippen-Thomas
UPDATE essentials.districts SET label = 'District 3'
 WHERE id = '717a7d6d-24ea-48ad-afe0-9890afb700d2' AND label IS DISTINCT FROM 'District 3'; -- Ruedas
UPDATE essentials.districts SET label = 'District 4'
 WHERE id = '12026291-cf3a-447e-bbba-42a51ba5bc2b' AND label IS DISTINCT FROM 'District 4'; -- Longoria

-- (4) Mayor Ancona (office 57d646fc, district 2c00ef36 'El Monte Mayor' LOCAL_EXEC) untouched.

COMMIT;

-- Register structural migration in the ledger.
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1000', 'elmonte_reconcile')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. gov geo_id = '0622230'
--    SELECT geo_id, state FROM essentials.governments WHERE id='f5fe3651-75c2-4ede-86e2-c13fc008d545';
-- 2. exactly one 'City Council' chamber (survivor 5ca38f3a); b41e0065 gone
--    SELECT id, name FROM essentials.chambers WHERE government_id='f5fe3651-75c2-4ede-86e2-c13fc008d545';
-- 3. survivor 5ca38f3a has 6 offices (Cortez D6 -> 7 is Plan 02)
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='5ca38f3a-ea2e-4160-abb5-f897702b6cb6';
-- 4. council seats D1-D6 (LOCAL, 6 rows incl. unoccupied D6) + 'El Monte Mayor' (LOCAL_EXEC) under gov;
--    each occupant on the right district: Crippen-Thomas D1, Herrera D2, Ruedas D3, Longoria D4, Galvan D5
-- 5. Ancona's office 57d646fc still LOCAL_EXEC 'El Monte Mayor'; exactly 1 LOCAL_EXEC office under the gov
-- 6. feedback_section_split_check -> 0 rows for El Monte (gov f5fe3651)
-- 7. migration 1000 registered in schema_migrations
