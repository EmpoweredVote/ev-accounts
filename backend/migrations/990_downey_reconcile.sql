-- 990_downey_reconcile.sql
-- Phase 150 Wave 1 (DWNY-01): reconcile City of Downey structural defects.
-- Gov 1a31cf01-5e05-46d9-88f3-6b94aaa0c607 'City of Downey, California, US'.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-20 (150-01 Task 1).
--
-- NOTE: File numbered 990 (not 985 as planned) because files 985-989 were taken by
--       state_exec_headshots_batch_a-e (audit-only, added after plan authoring). On-disk MAX = 989.
--
-- Fixes:
--   (1) Backfill geo_id '0619766' (was empty string ''), empty-string-safe.
--   (2) Merge the two duplicate 'City Council' chambers via move-then-delete:
--       move the orphan-chamber (a30fd533) office -- Trujillo 2afa4fd2 --
--       into the survivor 7cb8a90c FIRST, assert the doomed chamber is empty, THEN delete it.
--   (3) BY-DISTRICT form of government: relabel the wrongly-'At-Large' district rows to
--       'District 1'..'District 5' per the RESEARCH §D-03 occupant map.
--       Pre-flight found a TRIPLE shared-district defect: district 22ff630a had 3 office refs
--       (Pemberton 3718d3c0, Saab 44ca5c68, Pelc 2ecc0a3e). Resolution: repoint Pemberton's
--       office to the unused orphan row 8468daf6, relabel it 'District 3'. Saab + Pelc remain
--       on 22ff630a (stale members, unlinked in Plan 02). Two unused orphan district rows
--       (8468daf6 → D3, 39e05679 → D1) repurposed instead of creating new rows.
--   (4) COLLAPSE the rotational mayor (Palmdale D-08): Sosa's LOCAL_EXEC district row (22ebdde5)
--       converted to district_type='LOCAL', relabeled 'District 2'. Sosa's office cc3bacd0
--       already has title='Mayor' (pre-existing partial update) -- idempotent guard handles it.
--   (5) DELETE the unused 'Downey Mayor' LOCAL_EXEC district row fd6d5d3a (0 office refs).
--       Pre-flight found this extra LOCAL_EXEC row not mentioned in the plan -- it must be
--       removed to achieve ZERO LOCAL_EXEC rows under gov 1a31cf01.
--   (6) Fix Trujillo's corrupted name: first_name='Mario', last_name='Trujillo'.
--
-- Occupant -> district assignment map (pre-flight confirmed):
--   Sosa    (office cc3bacd0, dist 22ebdde5 LOCAL_EXEC) -> 'District 2', LOCAL (mayor collapse)
--   Pemberton(office 3718d3c0, was shared 22ff630a)     -> 'District 3' (repurposed orphan 8468daf6)
--   Frometa (office 6fa79f0e, dist 9c06376f LOCAL)      -> 'District 4'
--   Trujillo(office 2afa4fd2, dist 996396b2 LOCAL)      -> 'District 5' (after chamber move)
--   Ortiz   (no office yet; orphan 39e05679)             -> 'District 1' (seat created in Plan 02)
--   Saab    (office 44ca5c68, dist 22ff630a LOCAL)      -> STALE; unlink in Plan 02
--   Pelc    (office 2ecc0a3e, dist 22ff630a LOCAL)      -> STALE; unlink in Plan 02
-- 'Downey Mayor' (district fd6d5d3a, LOCAL_EXEC, 0 refs) -> DELETED (unused, achieve 0 LOCAL_EXEC)

BEGIN;

-- (1) geo_id backfill (empty-string guard per Pitfall 8)
UPDATE essentials.governments
   SET geo_id = '0619766'
 WHERE id = '1a31cf01-5e05-46d9-88f3-6b94aaa0c607'
   AND (geo_id IS NULL OR geo_id = '');

-- (2) MERGE duplicate chamber -- move the orphan-chamber office into the survivor FIRST.
-- Target by UUID ONLY (both chambers share name 'City Council' / slug 'downey-city-council').
UPDATE essentials.offices
   SET chamber_id = '7cb8a90c-1214-4840-bd75-5f6b9504532d'
 WHERE chamber_id = 'a30fd533-2188-4f36-bf23-a76d75296f2e';

-- Assert the doomed chamber is empty before deleting it
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE chamber_id = 'a30fd533-2188-4f36-bf23-a76d75296f2e') > 0 THEN
    RAISE EXCEPTION 'Chamber a30fd533 still has offices; aborting before delete';
  END IF;
END $$;

DELETE FROM essentials.chambers WHERE id = 'a30fd533-2188-4f36-bf23-a76d75296f2e';

-- (3a) Resolve Pemberton's shared-district defect: repoint office 3718d3c0 to unused orphan row 8468daf6.
-- (Saab 44ca5c68 and Pelc 2ecc0a3e remain on 22ff630a -- they are stale and will be unlinked in Plan 02.)
UPDATE essentials.offices
   SET district_id = '8468daf6-6faa-49f2-b034-af135d008300'
 WHERE id = '3718d3c0-f7f0-40d0-8a8e-f8654ba779b8'
   AND district_id IS DISTINCT FROM '8468daf6-6faa-49f2-b034-af135d008300'; -- Pemberton

-- (3b) Relabel district rows to real district numbers (non-mayor seats: label only; geo_id/state unchanged).
-- District 1 (Ortiz): repurpose unused orphan row 39e05679 (seat created in Plan 02).
UPDATE essentials.districts SET label = 'District 1'
 WHERE id = '39e05679-110c-48be-be51-5434b5da6727'
   AND label IS DISTINCT FROM 'District 1'; -- Ortiz placeholder (Plan 02 seats him)

-- District 3 (Pemberton): the repurposed orphan row 8468daf6 (repointed above).
UPDATE essentials.districts SET label = 'District 3'
 WHERE id = '8468daf6-6faa-49f2-b034-af135d008300'
   AND label IS DISTINCT FROM 'District 3'; -- Pemberton

-- District 4 (Frometa): her own row 9c06376f.
UPDATE essentials.districts SET label = 'District 4'
 WHERE id = '9c06376f-3510-40ee-be67-ca8d84d6ad9e'
   AND label IS DISTINCT FROM 'District 4'; -- Frometa

-- District 5 (Trujillo): his row 996396b2 (now in survivor chamber after step 2).
UPDATE essentials.districts SET label = 'District 5'
 WHERE id = '996396b2-872e-4d83-a9fb-27d57acdcb4c'
   AND label IS DISTINCT FROM 'District 5'; -- Trujillo

-- (4) COLLAPSE the rotational mayor (Palmdale D-08 pattern):
--     Convert Sosa's LOCAL_EXEC district row to LOCAL + relabel 'District 2'.
--     Sosa's office cc3bacd0 already has title='Mayor' from a pre-existing partial update;
--     the IS DISTINCT FROM guard makes this a no-op on re-run.
UPDATE essentials.districts
   SET district_type = 'LOCAL',
       label = 'District 2'
 WHERE id = '22ebdde5-9e8d-4a2c-9646-9509e7c6707b'
   AND (district_type IS DISTINCT FROM 'LOCAL' OR label IS DISTINCT FROM 'District 2'); -- Sosa

-- Sosa's office title (idempotent -- already 'Mayor' in pre-flight, guard ensures no-op on re-run).
UPDATE essentials.offices
   SET title = 'Mayor'
 WHERE id = 'cc3bacd0-5026-4914-b271-c6e40c929a9c'
   AND title IS DISTINCT FROM 'Mayor'; -- Sosa

-- Ensure the 4 non-mayor council seats have title='Councilmember' (idempotent).
UPDATE essentials.offices
   SET title = 'Councilmember'
 WHERE id IN (
     '3718d3c0-f7f0-40d0-8a8e-f8654ba779b8', -- Pemberton (D3)
     '6fa79f0e-a3d8-47f3-b67d-29009818f2ee', -- Frometa (D4)
     '2afa4fd2-708e-4990-9b9a-c01131e2226b'  -- Trujillo (D5)
     -- Note: Saab (44ca5c68) and Pelc (2ecc0a3e) are stale; their titles fixed in Plan 02
 )
   AND title IS DISTINCT FROM 'Councilmember';

-- (5) DELETE the unused 'Downey Mayor' LOCAL_EXEC district (fd6d5d3a, 0 office refs).
-- Pre-flight confirmed 0 office references -- safe to delete.
-- This achieves the target of ZERO LOCAL_EXEC rows under gov 1a31cf01.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE district_id = 'fd6d5d3a-ece3-49f2-8908-a10b507ebf9c') > 0 THEN
    RAISE EXCEPTION 'District fd6d5d3a still has office references; aborting delete';
  END IF;
END $$;

DELETE FROM essentials.districts WHERE id = 'fd6d5d3a-ece3-49f2-8908-a10b507ebf9c';

-- (6) Fix Trujillo's corrupted name (pre-flight: first_name='Mario Trujillo', last_name='-').
-- Guard: only update if last_name is '-' or NULL (idempotent on re-run).
UPDATE essentials.politicians
   SET first_name = 'Mario',
       last_name  = 'Trujillo'
 WHERE external_id = -201200
   AND (last_name = '-' OR last_name IS NULL);

COMMIT;

-- Register structural migration in the ledger.
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('990', 'downey_reconcile')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- Run these read-only checks after applying:
--
-- 1. gov geo_id = '0619766'
--    SELECT geo_id, state FROM essentials.governments WHERE id='1a31cf01-5e05-46d9-88f3-6b94aaa0c607';
--    Expected: geo_id='0619766', state='CA'
--
-- 2. exactly one 'City Council' chamber (survivor 7cb8a90c); a30fd533 gone
--    SELECT id, name FROM essentials.chambers WHERE government_id='1a31cf01-5e05-46d9-88f3-6b94aaa0c607';
--    Expected: 1 row (7cb8a90c)
--
-- 3. survivor has 6 offices (Trujillo moved in; 6->5 roster reconcile is Plan 02)
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='7cb8a90c-1214-4840-bd75-5f6b9504532d';
--    Expected: 6
--
-- 4. district rows for geo_id 0619766: 'District 1'..'District 5' + 'At-Large' (Saab+Pelc's shared row)
--    All LOCAL, ZERO LOCAL_EXEC.
--    SELECT id, label, district_type,
--           (SELECT COUNT(*) FROM essentials.offices o WHERE o.district_id=d.id) AS refs
--    FROM essentials.districts d WHERE d.geo_id='0619766' ORDER BY d.district_type, d.label;
--    Expected: 6 rows total (D1-D5 LOCAL + 22ff630a 'At-Large' LOCAL with 2 refs); 0 LOCAL_EXEC
--
-- 5. Sosa's office cc3bacd0 title='Mayor', district='District 2' (LOCAL)
--    SELECT o.title, d.label, d.district_type
--    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
--    WHERE o.id='cc3bacd0-5026-4914-b271-c6e40c929a9c';
--    Expected: title='Mayor', label='District 2', district_type='LOCAL'
--
-- 6. Trujillo (-201200): first_name='Mario', last_name='Trujillo'
--    SELECT first_name, last_name FROM essentials.politicians WHERE external_id=-201200;
--    Expected: first_name='Mario', last_name='Trujillo'
--
-- 7. ZERO LOCAL_EXEC rows under gov 1a31cf01
--    SELECT COUNT(*) FROM essentials.districts WHERE geo_id='0619766' AND district_type='LOCAL_EXEC';
--    Expected: 0
--
-- 8. feedback_section_split_check -> 0 rows for Downey
--    SELECT c.government_id, g.name, c.name AS chamber_name, d.label, d.district_type,
--           COUNT(DISTINCT o.id) AS office_count
--    FROM essentials.chambers c
--    JOIN essentials.governments g ON g.id = c.government_id
--    JOIN essentials.offices o ON o.chamber_id = c.id
--    JOIN essentials.districts d ON d.id = o.district_id
--    WHERE g.geo_id = '0619766'
--    GROUP BY c.government_id, g.name, c.name, d.label, d.district_type
--    HAVING COUNT(DISTINCT o.id) > 0
--    ORDER BY d.district_type, d.label;
--    Expected: 0 rows (no split-section defect)
--
-- 9. migration 990 registered in schema_migrations
--    SELECT version, name FROM supabase_migrations.schema_migrations WHERE version='990';
--    Expected: 1 row
