-- 1026_burbank_reconcile.sql
-- Phase 154 Wave 1 (BURB-01): reconcile City of Burbank structural defects.
-- Gov 3e3deaea-c5f4-4a68-b3ae-a79589f544ea 'City of Burbank, California, US'.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-22 (154-01 Task 1): NO DRIFT.
--
-- BURBANK IS AT-LARGE WITH A ROTATIONAL MAYOR (RESEARCH §Form of Government Verdict;
-- confirmed via burbankca.gov/council-manager-form-of-government + myBurbank.com Dec 2025):
-- FIVE at-large council seats elected citywide + a ROTATIONAL council-selected Mayor (title
-- on a seat, NOT a separate LOCAL_EXEC office). CVRA lawsuit ongoing; at-large confirmed
-- through at least Nov 2026 ballot measures. This is the West Covina/Downey rotational model.
--
-- Fixes (simpler than Inglewood 153 — no person-dedup, no by-district relabel):
--   (1) Backfill geo_id '0608954' (was empty string), empty-string-safe guard.
--   (2) Repair the two one-directional back-pointers BEFORE chamber move:
--       Anthony (pol 6c4c7919 -> office 1294961c) and Mullins (pol f933bd87 -> office 9969febe)
--       have politicians.office_id NULL; set to match offices.politician_id.
--       Mullins is a LEGITIMATE seated council member (Vice Mayor) per RESEARCH §Roster Verdict.
--       DO NOT unlink Mullins.
--   (3) Merge duplicate 'City Council' chambers via move-then-delete: move BOTH doomed-chamber
--       (6a72dbe8) offices -- Anthony 1294961c + Mullins 9969febe -- into the survivor 73422d25
--       FIRST, assert the doomed chamber is empty, THEN delete it.
--       Target chambers BY UUID ONLY (both share name 'City Council' / slug
--       'burbank-city-council').
--   (4) Re-point the two moved offices (Anthony 1294961c + Mullins 9969febe) from the doomed
--       At-Large district (809bbb35) to the surviving At-Large district (15458750). No relabel
--       needed: all 5 seats are 'At-Large' and stay 'At-Large' (Burbank is NOT by-district).
--   (5) Delete the now-orphaned doomed At-Large district 809bbb35 (guarded: only if no office
--       references it after the repoint above).
--
-- NOT done here (Wave 2 handles): rotational Mayor/Vice Mayor titles on seats, official_count=5.
-- OUT OF SCOPE (untouched): Burbank Unified School District gov d5ffbb65-f0db-41ad-8d11-278b8fb9aedc.

BEGIN;

-- (1) geo_id backfill (empty-string-safe guard)
UPDATE essentials.governments
   SET geo_id = '0608954'
 WHERE id = '3e3deaea-c5f4-4a68-b3ae-a79589f544ea'
   AND (geo_id IS NULL OR geo_id = '');

-- (2) Repair the two one-directional back-pointers (politicians.office_id NULL).
-- Anthony and Mullins are in the DOOMED chamber; repair BEFORE moving offices.
-- Guarded IS DISTINCT FROM (idempotent).
UPDATE essentials.politicians
   SET office_id = '1294961c-40db-47ed-8caf-9a721073d902'
 WHERE id = '6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7'
   AND office_id IS DISTINCT FROM '1294961c-40db-47ed-8caf-9a721073d902'; -- Konstantine Anthony

UPDATE essentials.politicians
   SET office_id = '9969febe-0fe8-4a66-af5e-49eea7367390'
 WHERE id = 'f933bd87-d397-4ef1-873b-57559b629000'
   AND office_id IS DISTINCT FROM '9969febe-0fe8-4a66-af5e-49eea7367390'; -- Zizette Mullins (Vice Mayor, NOT City Clerk)

-- (3) MERGE duplicate chamber -- move BOTH doomed-chamber offices into the survivor FIRST.
-- Target by UUID ONLY (both chambers share name 'City Council' / slug 'burbank-city-council').
UPDATE essentials.offices
   SET chamber_id = '73422d25-c0a6-477a-b74f-2b38b94b6389'  -- SURVIVOR
 WHERE chamber_id = '6a72dbe8-06fa-4148-9152-1c8e2f11b30e'; -- DOOMED

-- Assert the doomed chamber is empty before deleting it.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE chamber_id = '6a72dbe8-06fa-4148-9152-1c8e2f11b30e') > 0 THEN
    RAISE EXCEPTION 'Chamber 6a72dbe8 still has offices; aborting before delete';
  END IF;
END $$;

DELETE FROM essentials.chambers WHERE id = '6a72dbe8-06fa-4148-9152-1c8e2f11b30e';

-- (4) Re-point the two moved offices from the doomed At-Large district to the surviving one.
-- Guarded IS DISTINCT FROM (idempotent).
-- DO NOT relabel the surviving district (stays 'At-Large' — Burbank is at-large through Nov 2026).
UPDATE essentials.offices
   SET district_id = '15458750-78aa-4b9a-ade4-247e28bc25c2'  -- surviving At-Large district
 WHERE id IN (
   '1294961c-40db-47ed-8caf-9a721073d902',  -- Anthony
   '9969febe-0fe8-4a66-af5e-49eea7367390'   -- Mullins
 )
   AND district_id IS DISTINCT FROM '15458750-78aa-4b9a-ade4-247e28bc25c2';

-- (5) Delete the now-orphaned doomed 'At-Large' district (guarded: only if no office
-- references it after the repoint above).
DELETE FROM essentials.districts d
 WHERE d.id = '809bbb35-8d84-4e51-aef8-44547b32d063'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

COMMIT;

-- Register structural migration in the ledger (OUTSIDE the transaction block).
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1026', 'burbank_reconcile')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. gov geo_id = '0608954', state 'CA'
--    SELECT geo_id, state FROM essentials.governments WHERE id='3e3deaea-c5f4-4a68-b3ae-a79589f544ea';
-- 2. exactly one 'City Council' chamber (survivor 73422d25); 6a72dbe8 gone
--    SELECT id, name FROM essentials.chambers WHERE government_id='3e3deaea-c5f4-4a68-b3ae-a79589f544ea';
--    SELECT COUNT(*) FROM essentials.chambers WHERE id='6a72dbe8-06fa-4148-9152-1c8e2f11b30e';
-- 3. survivor 73422d25 has 5 offices (all At-Large, bidirectional)
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='73422d25-c0a6-477a-b74f-2b38b94b6389';
-- 4. all 5 offices bidirectional (0 mismatches)
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id
--      WHERE o.chamber_id='73422d25-c0a6-477a-b74f-2b38b94b6389' AND p.office_id<>o.id;
-- 5. Anthony (-201161) + Mullins (-201162) office_id NOT NULL
--    SELECT external_id, office_id FROM essentials.politicians WHERE external_id IN (-201161,-201162);
-- 6. doomed At-Large district 809bbb35 deleted
--    SELECT COUNT(*) FROM essentials.districts WHERE id='809bbb35-8d84-4e51-aef8-44547b32d063';
-- 7. all 5 offices on At-Large district (no relabel)
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
--      WHERE o.chamber_id='73422d25-c0a6-477a-b74f-2b38b94b6389' AND d.label='At-Large';
-- 8. split-section check returns 0 rows for gov 3e3deaea
--    SELECT g.name, COUNT(DISTINCT gb.mtfcc) section_count
--    FROM essentials.governments g
--    JOIN essentials.government_bodies gb ON gb.government_id = g.id
--    WHERE g.id = '3e3deaea-c5f4-4a68-b3ae-a79589f544ea'
--    GROUP BY g.name HAVING COUNT(DISTINCT gb.mtfcc) > 1;
-- 9. migration 1026 registered in schema_migrations
--    SELECT version, name FROM supabase_migrations.schema_migrations WHERE version='1026';
-- 10. one-liner health check:
--    SELECT
--      (SELECT geo_id FROM essentials.governments WHERE id='3e3deaea-c5f4-4a68-b3ae-a79589f544ea') as geo_id,
--      (SELECT COUNT(*) FROM essentials.chambers WHERE government_id='3e3deaea-c5f4-4a68-b3ae-a79589f544ea') as chamber_count,
--      (SELECT official_count FROM essentials.chambers WHERE id='73422d25-c0a6-477a-b74f-2b38b94b6389') as official_count;
-- Expected: geo_id='0608954', chamber_count=1, official_count=5 (official_count finalized in Wave 2)
