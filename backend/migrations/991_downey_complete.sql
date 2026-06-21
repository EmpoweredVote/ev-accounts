-- 991_downey_complete.sql
-- Phase 150 (Downey deep-seed) Wave 2 — STRUCTURAL (registers in schema_migrations). Idempotent.
-- Runs after 990 (single 'City Council' chamber 7cb8a90c, 6 offices, districts D1-D5 relabeled,
--   Trujillo moved + name fixed, Sosa title='Mayor' on District 2, ZERO LOCAL_EXEC rows).
--
-- Pre-flight 2026-06-20 (150-02 Task 1):
--   Trujillo (-201200): office_id=NULL (desync after Plan 01 chamber move — must repair).
--   Sosa (675353): office_id=cc3bacd0 OK. Pemberton (675360): office_id=3718d3c0 OK.
--   Frometa (675361): office_id=6fa79f0e OK.
--   Saab (-700160, office 44ca5c68): is_active=true, office_id set — will unlink.
--   Pelc (-700161, office 2ecc0a3e): is_active=true, office_id set — will unlink.
--   Ortiz: ABSENT from DB (must create).
--   Next free custom ext_id: -700991 (range -700659 to -700990 fully empty; using -700991 to align
--     with migration number 991).
--   schema_migrations MAX = 990; this migration = 991.
--   Chamber 7cb8a90c: official_count=5 (already set in Plan 01 — guard is idempotent).
--   District 1 UUID: 39e05679-110c-48be-be51-5434b5da6727 (confirmed 'District 1', LOCAL).
--   Saab's office 44ca5c68 repurposed for Ortiz (D1) — both on district 22ff630a (At-Large stale)
--     which is updated to point at District 1 via offices.district_id change.
--   Pelc's office 2ecc0a3e: surplus — politician_id NULLed (no seat lacks an office; D1 covered
--     via the repurposed Saab office; exactly 5 occupied offices will remain).
--
-- Part A: CREATE Horacio Ortiz (D1, Mayor Pro Tem) + SEAT into repurposed office 44ca5c68.
-- Part B: UNLINK stale Saab (-700160) + Pelc (-700161) — null both pointers, deactivate. KEEP rows.
-- Part C: REPAIR Trujillo's back-pointer (politicians.office_id was NULL). Set official_count=5.
--
-- DO NOT: slug / offices.district_type / DELETE any politician/stance/image row /
--         create LOCAL_EXEC Mayor or Mayor Pro Tem office.

BEGIN;

-- ============================================================
-- Part A: Create Horacio Ortiz (D1) + seat in repurposed office 44ca5c68
-- ============================================================

-- A1: Insert Ortiz politician row (guarded by external_id conflict)
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name,
   is_active, is_appointed, is_incumbent, is_vacant,
   source, alternate_names)
VALUES
  (gen_random_uuid(), -700991, 'Horacio Ortiz', 'Horacio', 'Ortiz',
   true, false, true, false,
   'downeyca.org', '{}')
ON CONFLICT (external_id) DO NOTHING;

-- A2: Repurpose Saab's freed office 44ca5c68 → District 1 office for Ortiz
--   Set politician_id to Ortiz, district_id to District 1 (39e05679), title='Council Member'.
--   Saab was on 22ff630a (At-Large stale district) — update district_id to 39e05679.
UPDATE essentials.offices
   SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -700991),
       district_id   = '39e05679-110c-48be-be51-5434b5da6727',
       title         = 'Council Member'
 WHERE id = '44ca5c68-3e7e-4e96-93eb-3c1773df842a'
   AND (politician_id IS DISTINCT FROM (SELECT id FROM essentials.politicians WHERE external_id = -700991)
    OR district_id IS DISTINCT FROM '39e05679-110c-48be-be51-5434b5da6727'
    OR title IS DISTINCT FROM 'Council Member');

-- A3: Back-pointer — set Ortiz.office_id → 44ca5c68
UPDATE essentials.politicians
   SET office_id = '44ca5c68-3e7e-4e96-93eb-3c1773df842a'
 WHERE external_id = -700991
   AND office_id IS DISTINCT FROM '44ca5c68-3e7e-4e96-93eb-3c1773df842a';

-- ============================================================
-- Part B: Unlink stale Saab + Pelc — null links, deactivate; KEEP their politician rows
-- ============================================================

-- B1: Null Saab's back-pointer + deactivate (KEEP row — unlink-not-delete precedent)
UPDATE essentials.politicians
   SET office_id = NULL,
       is_active = false
 WHERE external_id = -700160
   AND (office_id IS NOT NULL OR is_active = true);

-- B2: Null Pelc's back-pointer + deactivate (KEEP row)
UPDATE essentials.politicians
   SET office_id = NULL,
       is_active = false
 WHERE external_id = -700161
   AND (office_id IS NOT NULL OR is_active = true);

-- B3: Free Pelc's surplus office 2ecc0a3e — null its politician_id.
--   (Saab's office 44ca5c68 already repurposed for Ortiz in Part A.)
--   After this, exactly 5 occupied offices remain under 7cb8a90c
--   (Ortiz/Sosa/Pemberton/Frometa/Trujillo). Pelc's office is left unoccupied.
UPDATE essentials.offices
   SET politician_id = NULL
 WHERE id = '2ecc0a3e-c147-4310-9a8c-5b777cad6dba'
   AND politician_id IS NOT NULL;

-- ============================================================
-- Part C: Repair back-pointers + set official_count=5
-- ============================================================

-- C1: Repair Trujillo's back-pointer (politicians.office_id was NULL after Plan 01 move)
UPDATE essentials.politicians
   SET office_id = '2afa4fd2-708e-4990-9b9a-c01131e2226b'
 WHERE external_id = -201200
   AND office_id IS DISTINCT FROM '2afa4fd2-708e-4990-9b9a-c01131e2226b';

-- C2: Guard-verify remaining current members' back-pointers (already correct per pre-flight;
--     kept for idempotency and auditability).
UPDATE essentials.politicians
   SET office_id = 'cc3bacd0-5026-4914-b271-c6e40c929a9c'
 WHERE external_id = 675353
   AND office_id IS DISTINCT FROM 'cc3bacd0-5026-4914-b271-c6e40c929a9c'; -- Sosa D2

UPDATE essentials.politicians
   SET office_id = '3718d3c0-f7f0-40d0-8a8e-f8654ba779b8'
 WHERE external_id = 675360
   AND office_id IS DISTINCT FROM '3718d3c0-f7f0-40d0-8a8e-f8654ba779b8'; -- Pemberton D3

UPDATE essentials.politicians
   SET office_id = '6fa79f0e-a3d8-47f3-b67d-29009818f2ee'
 WHERE external_id = 675361
   AND office_id IS DISTINCT FROM '6fa79f0e-a3d8-47f3-b67d-29009818f2ee'; -- Frometa D4

-- C3: Survivor chamber official_count = 5 (rotational mayor IS one of the 5 council seats;
--     Palmdale model — NOT excluded like Pasadena's LOCAL_EXEC mayor).
UPDATE essentials.chambers
   SET official_count = 5
 WHERE id = '7cb8a90c-1214-4840-bd75-5f6b9504532d'
   AND official_count IS DISTINCT FROM 5;

-- Register this structural migration
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('991', 'downey_complete')
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ============================ POST-VERIFICATION =============================
-- Run these after COMMIT to confirm end state:
--
-- 1. Exactly 5 active members with CONSISTENT bidirectional links in 7cb8a90c:
-- SELECT p.external_id, p.first_name, p.last_name, o.title, d.label,
--        (p.office_id = o.id) as pol_ptr_ok, (o.politician_id = p.id) as off_ptr_ok
--   FROM essentials.offices o
--   JOIN essentials.politicians p ON p.id = o.politician_id
--   JOIN essentials.districts d ON d.id = o.district_id
--  WHERE o.chamber_id = '7cb8a90c-1214-4840-bd75-5f6b9504532d'
--  ORDER BY d.label;
-- Expect: Ortiz D1 Council Member / Sosa D2 Mayor / Pemberton D3 Councilmember /
--         Frometa D4 Councilmember / Trujillo D5 Councilmember
--
-- 2. Exactly 5 active members with BOTH pointers in sync:
-- SELECT COUNT(*) FROM essentials.politicians p
--   JOIN essentials.offices o ON o.id=p.office_id AND o.politician_id=p.id
--  WHERE o.chamber_id='7cb8a90c-1214-4840-bd75-5f6b9504532d' AND p.is_active=true;
-- Expect: 5
--
-- 3. Saab + Pelc rows KEPT (not deleted); office_id NULL; is_active=false:
-- SELECT external_id, first_name, last_name, office_id, is_active
--   FROM essentials.politicians WHERE external_id IN (-700160,-700161);
-- Expect: 2 rows, both office_id NULL, is_active=false
--
-- 4. official_count = 5:
-- SELECT official_count FROM essentials.chambers WHERE id='7cb8a90c-1214-4840-bd75-5f6b9504532d';
-- Expect: 5
--
-- 5. No LOCAL_EXEC rows:
-- SELECT COUNT(*) FROM essentials.districts d
--   JOIN essentials.offices o ON o.district_id=d.id
--   JOIN essentials.chambers c ON c.id=o.chamber_id
--  WHERE c.government_id='1a31cf01-5e05-46d9-88f3-6b94aaa0c607' AND d.district_type='LOCAL_EXEC';
-- Expect: 0
--
-- 6. Migration 991 registered:
-- SELECT version FROM supabase_migrations.schema_migrations WHERE version='991';
-- Expect: '991'
--
-- 7. Feedback section-split check (0 rows for Downey):
-- SELECT gb.name FROM essentials.governments g
--   JOIN essentials.chambers c ON c.government_id=g.id
--   LEFT JOIN essentials.offices o ON o.chamber_id=c.id
--  WHERE g.geo_id='0619766'
-- GROUP BY g.id, g.name, c.id, c.name HAVING COUNT(DISTINCT o.district_id) > 1
--    AND COUNT(DISTINCT (SELECT district_type FROM essentials.districts d WHERE d.id=o.district_id)) > 1;
-- Expect: 0 rows
