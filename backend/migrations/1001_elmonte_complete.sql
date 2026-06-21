-- 1001_elmonte_complete.sql
-- Phase 151 (El Monte deep-seed) Wave 2 — STRUCTURAL (registers in schema_migrations). Idempotent.
-- Runs after 1000 (single 'City Council' chamber 5ca38f3a, 6 offices, districts relabeled D1-D5 +
--   District 6 row created (0e2b4e3b, unoccupied), Mayor Ancona LOCAL_EXEC untouched).
--
-- Pre-flight 2026-06-21 (151-02 Task 1):
--   Cortez: ABSENT from DB (SELECT by name = 0 rows) — must create.
--   Next free custom ext_id: -701001 (range -700990..-701100 shows only -700991 taken (Downey Ortiz);
--     -701001 aligns with this migration number 1001).
--   Back-pointers NULL (must repair): Crippen-Thomas -201202 (office 211af77a), Herrera -201204
--     (7e9eac5e), Galvan -201203 (3ffcb893), Ancona -200669 (57d646fc). Already OK: Longoria 657386
--     (3040818a), Ruedas 657390 (06d458fe).
--   official_count: NULL (set to 6 — council seats only; the directly-elected Mayor is EXCLUDED,
--     Pasadena/Pomona precedent, RESEARCH §Pitfall 3).
--   District 6 UUID (from Plan 01): 0e2b4e3b-be0b-4919-b0b2-f19ce898b23b.
--   No departed/stale member surfaced — Cortez is net-new; no unlink needed.
--
-- Part A: CREATE Marisol Cortez (D6 incumbent, elected Nov 2022 term Nov 2026 — she LOST the 2024
--         mayor race to Ancona but retained her D6 seat; she is NOT a Mayor) + seat into a NEW
--         District 6 office in chamber 5ca38f3a.
-- Part B: REPAIR the 4 NULL back-pointers + set official_count=6.
--
-- DO NOT: slug / offices.district_type / DELETE any politician/stance/image row /
--         create a second Mayor office / collapse Ancona's LOCAL_EXEC seat / count the Mayor.

BEGIN;

-- ============================================================
-- Part A: Create Marisol Cortez (D6) + seat into a NEW District 6 office
-- ============================================================

-- A1: Insert Cortez politician row (guarded by external_id conflict)
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name,
   is_active, is_appointed, is_incumbent, is_vacant,
   source, alternate_names)
VALUES
  (gen_random_uuid(), -701001, 'Marisol Cortez', 'Marisol', 'Cortez',
   true, false, true, false,
   'ci.el-monte.ca.us', '{}')
ON CONFLICT (external_id) DO NOTHING;

-- A2: Create the NEW District 6 office in the survivor chamber (guarded NOT EXISTS on
--     chamber_id + district_id so a re-run cannot create a second D6 office). Mirrors the
--     El Monte council office shape (Ruedas 06d458fe).
INSERT INTO essentials.offices
  (id, politician_id, chamber_id, district_id, title, representing_state, representing_city,
   description, seats, normalized_position_name, partisan_type, salary,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT
  gen_random_uuid(),
  (SELECT id FROM essentials.politicians WHERE external_id = -701001),
  '5ca38f3a-ea2e-4160-abb5-f897702b6cb6',
  '0e2b4e3b-be0b-4919-b0b2-f19ce898b23b',
  'Councilmember', 'CA', 'El Monte',
  '', 0, 'Council Member', '', '',
  false, false, false
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices
   WHERE chamber_id = '5ca38f3a-ea2e-4160-abb5-f897702b6cb6'
     AND district_id = '0e2b4e3b-be0b-4919-b0b2-f19ce898b23b');

-- A3: Back-pointer — set Cortez.office_id → her new D6 office
UPDATE essentials.politicians
   SET office_id = (SELECT id FROM essentials.offices
                      WHERE chamber_id = '5ca38f3a-ea2e-4160-abb5-f897702b6cb6'
                        AND district_id = '0e2b4e3b-be0b-4919-b0b2-f19ce898b23b')
 WHERE external_id = -701001
   AND office_id IS DISTINCT FROM (SELECT id FROM essentials.offices
                      WHERE chamber_id = '5ca38f3a-ea2e-4160-abb5-f897702b6cb6'
                        AND district_id = '0e2b4e3b-be0b-4919-b0b2-f19ce898b23b');

-- ============================================================
-- Part B: Repair back-pointers (4 NULL) + set official_count=6
-- ============================================================

UPDATE essentials.politicians SET office_id = '211af77a-4c4f-4f5b-b604-3bd99b57210f'
 WHERE external_id = -201202 AND office_id IS DISTINCT FROM '211af77a-4c4f-4f5b-b604-3bd99b57210f'; -- Crippen-Thomas D1
UPDATE essentials.politicians SET office_id = '7e9eac5e-ffd7-4a6a-a417-01e3607b733d'
 WHERE external_id = -201204 AND office_id IS DISTINCT FROM '7e9eac5e-ffd7-4a6a-a417-01e3607b733d'; -- Herrera D2
UPDATE essentials.politicians SET office_id = '06d458fe-8cef-481f-bf6c-ece8fed8df29'
 WHERE external_id = 657390 AND office_id IS DISTINCT FROM '06d458fe-8cef-481f-bf6c-ece8fed8df29';  -- Ruedas D3 (guard)
UPDATE essentials.politicians SET office_id = '3040818a-533a-4f59-85a5-6bbcdf3d42a9'
 WHERE external_id = 657386 AND office_id IS DISTINCT FROM '3040818a-533a-4f59-85a5-6bbcdf3d42a9';  -- Longoria D4 (guard)
UPDATE essentials.politicians SET office_id = '3ffcb893-5924-47f6-b861-9eda1ac18f25'
 WHERE external_id = -201203 AND office_id IS DISTINCT FROM '3ffcb893-5924-47f6-b861-9eda1ac18f25'; -- Galvan D5
UPDATE essentials.politicians SET office_id = '57d646fc-7679-409b-85d4-942ede30336b'
 WHERE external_id = -200669 AND office_id IS DISTINCT FROM '57d646fc-7679-409b-85d4-942ede30336b'; -- Ancona Mayor

-- official_count = 6 (the 6 council district seats; the directly-elected Mayor is the 7th office
-- but EXCLUDED from the count — Pasadena/Pomona precedent, RESEARCH §Pitfall 3).
UPDATE essentials.chambers
   SET official_count = 6
 WHERE id = '5ca38f3a-ea2e-4160-abb5-f897702b6cb6'
   AND official_count IS DISTINCT FROM 6;

-- Register this structural migration
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1001', 'elmonte_complete')
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ============================ POST-VERIFICATION =============================
-- 1. 7 active members with CONSISTENT bidirectional links in 5ca38f3a:
--    Crippen-Thomas D1 / Herrera D2 / Ruedas D3 / Longoria D4 / Galvan D5 / Cortez D6 / Ancona Mayor
-- 2. exactly 7 occupied offices under 5ca38f3a
-- 3. Cortez (-701001) seated on District 6 (office on 0e2b4e3b), title 'Councilmember', NOT a Mayor
-- 4. Ancona office 57d646fc still LOCAL_EXEC 'El Monte Mayor'; exactly 1 LOCAL_EXEC office under gov
-- 5. official_count = 6
-- 6. feedback_section_split_check -> 0 rows for El Monte
-- 7. migration 1001 registered
