-- 1042_bellflower_reconcile.sql
-- Phase 156 Wave 1 (BLFL-01): reconcile City of Bellflower structural defects.
-- Gov d34bdac8-e928-45c5-aaa8-ca3950ec2d6c 'City of Bellflower, California, US'.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-22 (156-01 Task 1): NO DRIFT.
--
-- BELLFLOWER IS BY-DISTRICT WITH A ROTATIONAL MAYOR (RESEARCH §Form of Government Verdict,
-- HIGH confidence via bellflower.ca.gov: five geographic council districts since Ordinance
-- No. 1410 (Nov 2021); "The Mayor is elected by the Council from among its membership").
-- This is a COMPOSITE of the Norwalk 1034 LOCAL_EXEC-Mayor-mis-seed conversion + one-directional
-- back-pointer repair + geo_id backfill, PLUS the Palmdale 918 by-district relabel/split.
--
-- The DB models Bellflower as a separate directly-elected LOCAL_EXEC Mayor (Ray Dunton, district
-- "Bellflower Mayor" b0002e15) + a single shared At-Large district (8db5a2e5) holding 3 council
-- offices. BOTH are wrong: convert Dunton's LOCAL_EXEC office to a District 5 council seat, and
-- split the shared At-Large district into 5 distinct LOCAL districts D1-D5.
--
-- District map (RESEARCH §Roster Verdict, HIGH): D1=Morse, D2=Koops, D3=Santa Ines (Wave 2),
-- D4=Sanchez, D5=Dunton.
--
-- Fixes:
--   (1) Backfill geo_id '0604982' (was NULL), empty-string-safe guard.
--   (2) Repair the FOUR one-directional back-pointers (politicians.office_id NULL):
--       Dunton (pol 31c35458 -> office bdd2040f), Koops (pol dd2c2cfd -> office 3935cd4b),
--       Morse (pol d18dcb81 -> office 7408185f), Sanchez (pol 4384a5d8 -> office 581c5602).
--       All 4 are LEGITIMATE current council members per RESEARCH §Roster Verdict. DO NOT unlink.
--   (3) BY-DISTRICT relabel/split (Palmdale 918 pattern): relabel the shared At-Large district
--       8db5a2e5 -> 'District 1' (Morse stays on it); INSERT four new LOCAL districts D2/D3/D4/D5
--       mirroring 8db5a2e5 (geo_id 0604982, state CA, mtfcc G4110, district_type LOCAL,
--       government_id NULL to match the existing rows). NO chamber merge (single chamber).
--   (4) Re-point Koops's office (3935cd4b) -> D2 and Sanchez's office (581c5602) -> D4.
--       Morse's office (7408185f) stays on 8db5a2e5 (now D1) -- no re-point. D3 stays empty
--       (Santa Ines seated in Wave 2).
--   (5) LOCAL_EXEC Mayor -> District 5 council seat conversion (Norwalk 1034 pattern): re-point
--       Dunton's office (bdd2040f) district b0002e15 -> D5 and set title 'Councilmember'. Then
--       assert the LOCAL_EXEC district b0002e15 is empty and delete it.
--   (6) Title normalization: set Koops/Morse/Sanchez to 'Councilmember' so no 'Council Member'
--       (space) string remains. (Dunton set to 'Councilmember' in (5). Wave 2 overwrites
--       Sanchez->'Mayor Pro Tem' and seats Santa Ines->'Mayor'.)
--
-- NOTE ON districts.government_id: the existing Bellflower district rows (and all Palmdale
-- by-district rows) carry government_id NULL -- districts link to the gov via geo_id, not
-- government_id. New D2-D5 rows therefore keep government_id NULL to match. Verification queries
-- key on geo_id='0604982', NOT government_id.
--
-- NOT done here (Wave 2 handles): seat Santa Ines (D3, -701003, rotational Mayor), set
--   Mayor/Mayor Pro Tem titles, official_count=5.
-- OUT OF SCOPE (untouched): Bellflower Unified School District gov f85ca154-68c4-4cd5-92c0-adba01d992cc.

BEGIN;

-- (1) geo_id backfill (empty-string-safe guard)
UPDATE essentials.governments
   SET geo_id = '0604982'
 WHERE id = 'd34bdac8-e928-45c5-aaa8-ca3950ec2d6c'
   AND (geo_id IS NULL OR geo_id = '');

-- (2) Repair the FOUR one-directional back-pointers (politicians.office_id NULL).
-- Guarded IS DISTINCT FROM (idempotent).
UPDATE essentials.politicians
   SET office_id = 'bdd2040f-8f8d-4543-b017-3caad9be4510'
 WHERE id = '31c35458-6cc0-43ad-b431-841846e81875'
   AND office_id IS DISTINCT FROM 'bdd2040f-8f8d-4543-b017-3caad9be4510'; -- Ray Dunton (D5)

UPDATE essentials.politicians
   SET office_id = '3935cd4b-727b-41fb-96c3-87f66b0c385c'
 WHERE id = 'dd2c2cfd-401f-4b35-916f-caba8ca9b722'
   AND office_id IS DISTINCT FROM '3935cd4b-727b-41fb-96c3-87f66b0c385c'; -- Dan Koops (D2)

UPDATE essentials.politicians
   SET office_id = '7408185f-600c-4b02-8949-431347f21390'
 WHERE id = 'd18dcb81-ad41-468f-9b12-a70ed21fd3a7'
   AND office_id IS DISTINCT FROM '7408185f-600c-4b02-8949-431347f21390'; -- Wendi Morse (D1)

UPDATE essentials.politicians
   SET office_id = '581c5602-b72c-49f6-8b6e-c3e653eefbce'
 WHERE id = '4384a5d8-68b2-4e24-81e2-5208f5c61a34'
   AND office_id IS DISTINCT FROM '581c5602-b72c-49f6-8b6e-c3e653eefbce'; -- Victor A. Sanchez (D4, Mayor Pro Tem in Wave 2)

-- (3) BY-DISTRICT relabel/split (Palmdale 918 pattern).
-- Relabel the shared At-Large district 8db5a2e5 -> 'District 1' (Morse stays on it).
UPDATE essentials.districts
   SET label = 'District 1'
 WHERE id = '8db5a2e5-2172-474a-be23-e51c2a53f970'
   AND label IS DISTINCT FROM 'District 1';

-- INSERT new LOCAL districts D2/D3/D4/D5, mirroring 8db5a2e5's columns. Guarded NOT EXISTS on
-- (label, geo_id) so a re-run is a no-op. ocd_id is place-level (shared). government_id stays NULL
-- to match the existing D1 row. district_id='0' matches the legacy value on 8db5a2e5 (no unique
-- constraint -- Palmdale's D1/D5 also share '0').
INSERT INTO essentials.districts
  (ocd_id, label, district_type, district_id, state, num_officials, mtfcc, geo_id, is_judicial, has_unknown_boundaries, retention)
SELECT 'ocd-division/country:us/state:ca/place:bellflower', 'District 2', 'LOCAL', '0', 'CA', 1, 'G4110', '0604982', false, false, false
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label='District 2' AND geo_id='0604982');

INSERT INTO essentials.districts
  (ocd_id, label, district_type, district_id, state, num_officials, mtfcc, geo_id, is_judicial, has_unknown_boundaries, retention)
SELECT 'ocd-division/country:us/state:ca/place:bellflower', 'District 3', 'LOCAL', '0', 'CA', 1, 'G4110', '0604982', false, false, false
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label='District 3' AND geo_id='0604982');

INSERT INTO essentials.districts
  (ocd_id, label, district_type, district_id, state, num_officials, mtfcc, geo_id, is_judicial, has_unknown_boundaries, retention)
SELECT 'ocd-division/country:us/state:ca/place:bellflower', 'District 4', 'LOCAL', '0', 'CA', 1, 'G4110', '0604982', false, false, false
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label='District 4' AND geo_id='0604982');

INSERT INTO essentials.districts
  (ocd_id, label, district_type, district_id, state, num_officials, mtfcc, geo_id, is_judicial, has_unknown_boundaries, retention)
SELECT 'ocd-division/country:us/state:ca/place:bellflower', 'District 5', 'LOCAL', '0', 'CA', 1, 'G4110', '0604982', false, false, false
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label='District 5' AND geo_id='0604982');

-- (4) Re-point Koops -> D2 and Sanchez -> D4 (resolve the new district UUIDs at apply time).
-- Morse stays on 8db5a2e5 (now District 1) -- no re-point. Guarded IS DISTINCT FROM.
UPDATE essentials.offices
   SET district_id = (SELECT id FROM essentials.districts WHERE label='District 2' AND geo_id='0604982')
 WHERE id = '3935cd4b-727b-41fb-96c3-87f66b0c385c'                                   -- Koops office
   AND district_id IS DISTINCT FROM (SELECT id FROM essentials.districts WHERE label='District 2' AND geo_id='0604982');

UPDATE essentials.offices
   SET district_id = (SELECT id FROM essentials.districts WHERE label='District 4' AND geo_id='0604982')
 WHERE id = '581c5602-b72c-49f6-8b6e-c3e653eefbce'                                   -- Sanchez office
   AND district_id IS DISTINCT FROM (SELECT id FROM essentials.districts WHERE label='District 4' AND geo_id='0604982');

-- (5) LOCAL_EXEC Mayor -> District 5 council seat conversion (Norwalk 1034 pattern).
-- Re-point Dunton's office (bdd2040f) from LOCAL_EXEC district b0002e15 to the new D5 LOCAL
-- district and set title 'Councilmember'. The At-Large/LOCAL_EXEC type lives on the district,
-- so re-pointing district_id to the new LOCAL D5 row makes it a council seat. Guard on district_id.
UPDATE essentials.offices
   SET district_id = (SELECT id FROM essentials.districts WHERE label='District 5' AND geo_id='0604982'),
       title = 'Councilmember'
 WHERE id = 'bdd2040f-8f8d-4543-b017-3caad9be4510'                                   -- Dunton's (formerly LOCAL_EXEC) office
   AND district_id IS DISTINCT FROM (SELECT id FROM essentials.districts WHERE label='District 5' AND geo_id='0604982');

-- Assert the LOCAL_EXEC "Bellflower Mayor" district is empty, then delete it.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE district_id = 'b0002e15-e006-4791-b2f7-7a3389f58cb3') > 0 THEN
    RAISE EXCEPTION 'LOCAL_EXEC district b0002e15 still has offices; aborting before delete';
  END IF;
END $$;

DELETE FROM essentials.districts d
 WHERE d.id = 'b0002e15-e006-4791-b2f7-7a3389f58cb3'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- (6) Title normalization -- eliminate the 'Council Member' (space) space-form on Koops/Morse/Sanchez.
-- Guarded IS DISTINCT FROM (idempotent). (Dunton set in (5). Wave 2 overwrites Sanchez->'Mayor Pro Tem'.)
UPDATE essentials.offices
   SET title = 'Councilmember'
 WHERE id IN (
   '3935cd4b-727b-41fb-96c3-87f66b0c385c',  -- Koops (D2)
   '7408185f-600c-4b02-8949-431347f21390',  -- Morse (D1)
   '581c5602-b72c-49f6-8b6e-c3e653eefbce'   -- Sanchez (D4; -> Mayor Pro Tem in Wave 2)
 )
   AND title IS DISTINCT FROM 'Councilmember';

COMMIT;

-- Register structural migration in the ledger (OUTSIDE the transaction block).
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1042', 'bellflower_reconcile')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. gov geo_id = '0604982', state 'CA'
--    SELECT geo_id, state FROM essentials.governments WHERE id='d34bdac8-e928-45c5-aaa8-ca3950ec2d6c';
-- 2. exactly one 'City Council' chamber (a89b567a)
--    SELECT COUNT(*) FROM essentials.chambers WHERE government_id='d34bdac8-e928-45c5-aaa8-ca3950ec2d6c' AND name='City Council';
-- 3. 4 offices in chamber (Santa Ines added in Wave 2), all bidirectional (0 mismatches)
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6';
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id
--      WHERE o.chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' AND p.office_id<>o.id;
-- 4. Dunton(-200583)/Koops(-201149)/Morse(-201150)/Sanchez(-201151) office_id NOT NULL
--    SELECT external_id, office_id FROM essentials.politicians WHERE external_id IN (-200583,-201149,-201150,-201151);
-- 5. LOCAL_EXEC district b0002e15 deleted; NO LOCAL_EXEC office under the gov
--    SELECT COUNT(*) FROM essentials.districts WHERE id='b0002e15-e006-4791-b2f7-7a3389f58cb3';
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
--      WHERE o.chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' AND d.district_type='LOCAL_EXEC';
-- 6. 5 distinct LOCAL districts D1-D5 (keyed on geo_id, NOT government_id which is NULL)
--    SELECT COUNT(*) FROM essentials.districts WHERE geo_id='0604982' AND district_type='LOCAL' AND label IN ('District 1','District 2','District 3','District 4','District 5');
-- 7. no two offices share a district_id
--    SELECT district_id, COUNT(*) FROM essentials.offices WHERE chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' GROUP BY district_id HAVING COUNT(*) > 1;
-- 8. district map: Morse=D1, Koops=D2, Sanchez=D4, Dunton=D5 (D3 empty)
--    SELECT p.external_id, d.label FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id JOIN essentials.districts d ON d.id=o.district_id WHERE o.chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' ORDER BY d.label;
-- 9. no 'Council Member' (space) titles remain
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' AND title='Council Member';
-- 10. migration 1042 registered
--    SELECT version, name FROM supabase_migrations.schema_migrations WHERE version='1042';
