-- 1019_inglewood_complete.sql
-- Phase 153 (Inglewood deep-seed) Wave 2 — STRUCTURAL (registers in schema_migrations). Idempotent.
-- Runs after 1018 (single 'City Council' chamber a25a6dea; Mayor Butts LOCAL_EXEC kept; Gray D1 /
--   Eloy D3 / Faulk D4 relabeled; Eloy dedup done; Dotson still At-Large, one bidirectional link).
--
-- Pre-flight 2026-06-21 (153-02 Task 1):
--   Padilla: ABSENT from DB as an Inglewood official (only seated "Alex Padilla" is -6000201 = the
--     US SENATOR, federal scheme, different person) -> CREATE fresh.
--   Next free custom ext_id: -701002 (range -7010xx: -701001 = El Monte Cortez; -701002 free;
--     aligns with this migration number 1019's city). Confirmed 0 rows for -701002.
--   Dotson -201082: STILL linked (office_id 6b20a733, office.politician_id 3e73448b) -> UNLINK.
--     Dotson lost the March 2023 D1 runoff to Gloria Gray (RESEARCH CQ-2) — he is the FORMER D1
--     councilman, NOT a D2 holder, so his vacated office/district are NOT reused for Padilla.
--   Gray (666261) re-confirmed seated D1 (health-excused since Dec 2025 != vacated, RESEARCH A3) -> KEEP.
--   Current-member back-pointers: all bidirectional already (pre-flight nonbidir_current = 0); guarded anyway.
--   official_count: 5 (stale) -> set to 4 (council seats only; directly-elected Mayor EXCLUDED — El
--     Monte 151 / Pasadena / Pomona convention).
--
-- Part A: CREATE Alex Padilla (D2 incumbent, re-elected 2022) + a NEW District 2 row + office in a25a6dea.
-- Part B: UNLINK departed Dotson (rows KEPT) + delete his emptied office shell + orphan At-Large
--         district + repair any NULL back-pointers + official_count = 4.
--
-- DO NOT: slug / offices.district_type / DELETE any politician/stance/image row / create a second
--         Mayor office / collapse Butts's LOCAL_EXEC seat / count the Mayor / reuse Dotson's D1 seat for D2.

BEGIN;

-- ============================================================
-- Part A: Create Alex Padilla (D2) + a NEW District 2 office in survivor chamber a25a6dea
-- ============================================================

-- A0: New 'District 2' districts row for geo_id 0636546 (guarded NOT EXISTS)
INSERT INTO essentials.districts (label, district_type, geo_id, state)
SELECT 'District 2', 'LOCAL', '0636546', 'CA'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label = 'District 2' AND geo_id = '0636546');

-- A1: Insert Padilla politician row (guarded by external_id conflict)
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name,
   is_active, is_appointed, is_incumbent, is_vacant,
   source, alternate_names)
VALUES
  (gen_random_uuid(), -701002, 'Alex Padilla', 'Alex', 'Padilla',
   true, false, true, false,
   'cityofinglewood.org', '{}')
ON CONFLICT (external_id) DO NOTHING;

-- A2: Create the NEW District 2 office in the survivor chamber (guarded NOT EXISTS on chamber+district)
INSERT INTO essentials.offices
  (id, politician_id, chamber_id, district_id, title, representing_state, representing_city,
   description, seats, normalized_position_name, partisan_type, salary,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT
  gen_random_uuid(),
  (SELECT id FROM essentials.politicians WHERE external_id = -701002),
  'a25a6dea-7f26-4f5e-bc6a-2a5d321063d5',
  (SELECT id FROM essentials.districts WHERE label = 'District 2' AND geo_id = '0636546'),
  'Councilmember', 'CA', 'Inglewood',
  '', 0, 'Council Member', '', '',
  false, false, false
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices
   WHERE chamber_id = 'a25a6dea-7f26-4f5e-bc6a-2a5d321063d5'
     AND district_id = (SELECT id FROM essentials.districts WHERE label = 'District 2' AND geo_id = '0636546'));

-- A3: Back-pointer — set Padilla.office_id → his new D2 office
UPDATE essentials.politicians
   SET office_id = (SELECT id FROM essentials.offices
                      WHERE chamber_id = 'a25a6dea-7f26-4f5e-bc6a-2a5d321063d5'
                        AND district_id = (SELECT id FROM essentials.districts WHERE label = 'District 2' AND geo_id = '0636546'))
 WHERE external_id = -701002
   AND office_id IS DISTINCT FROM (SELECT id FROM essentials.offices
                      WHERE chamber_id = 'a25a6dea-7f26-4f5e-bc6a-2a5d321063d5'
                        AND district_id = (SELECT id FROM essentials.districts WHERE label = 'District 2' AND geo_id = '0636546'));

-- ============================================================
-- Part B: Unlink departed Dotson (rows KEPT) + cleanup + official_count = 4
-- ============================================================

-- B1: Unlink-not-delete George Dotson (defeated March 2023). Person + any stance/image rows KEPT.
UPDATE essentials.offices
   SET politician_id = NULL
 WHERE id = '6b20a733-45f1-4db1-a528-029aeca8aba3'
   AND politician_id IS NOT NULL;
UPDATE essentials.politicians
   SET office_id = NULL
 WHERE external_id = -201082
   AND office_id IS NOT NULL;

-- B1b: Delete Dotson's now-empty office SHELL (his former D1/At-Large seat; guarded: only if vacated).
DELETE FROM essentials.offices
 WHERE id = '6b20a733-45f1-4db1-a528-029aeca8aba3'
   AND politician_id IS NULL;

-- B1c: Delete the orphan 'At-Large' district row d01253fb (held only the two now-removed doomed
--      offices; guarded: only if no office references it). Prevents a stale At-Large row under 0636546.
DELETE FROM essentials.districts d
 WHERE d.id = 'd01253fb-1348-4179-8003-a053a0f9aa8c'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- B2: Repair any remaining NULL back-pointers for current members (guarded; all already bidirectional).
UPDATE essentials.politicians SET office_id = '8e9b0c61-0379-4a50-943d-951fdd8e632f'
 WHERE external_id = 666261 AND office_id IS DISTINCT FROM '8e9b0c61-0379-4a50-943d-951fdd8e632f'; -- Gray D1
UPDATE essentials.politicians SET office_id = 'ddcd280b-565d-496c-9ec4-0e43abb7b580'
 WHERE external_id = 666263 AND office_id IS DISTINCT FROM 'ddcd280b-565d-496c-9ec4-0e43abb7b580'; -- Eloy D3
UPDATE essentials.politicians SET office_id = '35b92278-1f5f-4f1a-91f9-e1b642f580cf'
 WHERE external_id = 666264 AND office_id IS DISTINCT FROM '35b92278-1f5f-4f1a-91f9-e1b642f580cf'; -- Faulk D4
UPDATE essentials.politicians SET office_id = '90121859-d5d4-4b0f-950e-5f6e9262abb4'
 WHERE external_id = -200740 AND office_id IS DISTINCT FROM '90121859-d5d4-4b0f-950e-5f6e9262abb4'; -- Butts Mayor

-- B3: official_count = 4 (council seats only; directly-elected Mayor EXCLUDED).
UPDATE essentials.chambers
   SET official_count = 4
 WHERE id = 'a25a6dea-7f26-4f5e-bc6a-2a5d321063d5'
   AND official_count IS DISTINCT FROM 4;

COMMIT;

-- Register this structural migration
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1019', 'inglewood_complete')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. Final roster = 5 active bidirectional members in a25a6dea:
--    Mayor Butts (LOCAL_EXEC) / Gray D1 / Padilla D2 / Eloy Morales D3 / Faulk D4
-- 2. Dotson (-201082) unlinked (office_id NULL); his politician row still exists
-- 3. Padilla (-701002) seated on District 2 (new office), bidirectional, NOT a Mayor
-- 4. official_count = 4; exactly 1 LOCAL_EXEC office (Butts) under gov af811c4b
-- 5. ZERO 'At-Large' offices in a25a6dea (Dotson shell + orphan district removed)
-- 6. feedback_section_split_check -> 0 rows for Inglewood (geo_id 0636546)
-- 7. migration 1019 registered
