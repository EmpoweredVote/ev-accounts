-- 903_glendale_complete.sql
-- Phase 144 / Plan 02 — Glendale roster completion (idempotent, structural).
--
-- Post-June-2-2026-election roster change (orchestrator decisions #1 + #2, user-approved
-- certification gate on 2026-06-19 — "Approved, seat Bartrosouf now"):
--   * Ara Najarian (-700100) did NOT re-run → RETIRE (not delete).
--   * Alek Bartrosouf won his seat → seat him as Councilmember.
--
-- PRE-FLIGHT FINDING (DB-verified 2026-06-19) that refines the plan's "INSERT new -700101 person":
--   A real Alek Bartrosouf person row ALREADY EXISTS — 66cd60ba-a8b5-495f-9be5-b2360e1041a8
--   (first 'Alek', last 'Bartrosouf', external_id NULL, is_active=true, office_id NULL,
--   source 'race_candidate' — an election-candidate row). Per CONTEXT D-01 "reseat, never
--   duplicate people" and the plan's Pitfall-4 STOP rule, we RESEAT this existing row rather
--   than INSERT a duplicate -700101 person (same decision as SC McLean/Miranda in 895).
--   The two inactive 'BARTROSOUF FOR CITY COUNCIL 2026' cal_access committee rows are junk —
--   left untouched (already inactive).
--
-- Because Najarian's seat (office c6f4e77d) is IN the survivor chamber (not a torn-down one),
-- we SEAT-SWAP: reassign his vacated office c6f4e77d to Bartrosouf. This keeps exactly 5
-- offices in chamber 771727ec (no orphan office, no 6th office), reuses the existing LOCAL
-- district fdfb8511 ('At-Large'), and creates no new districts/geofences/LOCAL_EXEC.
--
-- Live anchors:
--   gov 771727ec? no — survivor council chamber 771727ec-684b-4eb8-98a6-d7205d9bbac0 (ext 10450)
--   LOCAL district fdfb8511-2403-4cdf-ac1f-5567fdf30d57 ('At-Large', LOCAL, state CA) — survivor offices use it
--   Najarian office c6f4e77d-8a24-4bd2-b9c2-ba2dd13679ae (Councilmember) → reassigned to Bartrosouf
--   external_id -700101 confirmed VACANT (pre-flight COUNT 0)
--
-- chambers.slug GENERATED — never written. All statements idempotent. Structural migration 903.

BEGIN;

-- Part A — RETIRE Ara Najarian (-700100): detach + deactivate, NEVER delete (orchestrator #1).
UPDATE essentials.politicians
   SET office_id = NULL, is_incumbent = false, is_active = false
 WHERE external_id = -700100
   AND (is_active OR is_incumbent OR office_id IS NOT NULL);

-- Part B — RESEAT the existing Alek Bartrosouf person row (66cd60ba) as the new Councilmember.
-- B1: promote the candidate row to a seated official (assign reserved external_id -700101).
UPDATE essentials.politicians
   SET external_id = -700101,
       is_incumbent = true,
       is_appointed = false,
       is_vacant = false,
       is_active = true,
       source = 'glendaleca.gov'
 WHERE id = '66cd60ba-a8b5-495f-9be5-b2360e1041a8'
   AND external_id IS DISTINCT FROM -700101;

-- B2: reassign Najarian's vacated council seat (office c6f4e77d) to Bartrosouf (seat swap).
UPDATE essentials.offices
   SET politician_id = '66cd60ba-a8b5-495f-9be5-b2360e1041a8',
       title = 'Councilmember'
 WHERE id = 'c6f4e77d-8a24-4bd2-b9c2-ba2dd13679ae'
   AND politician_id IS DISTINCT FROM '66cd60ba-a8b5-495f-9be5-b2360e1041a8';

-- B3: back-fill Bartrosouf's office_id link.
UPDATE essentials.politicians
   SET office_id = 'c6f4e77d-8a24-4bd2-b9c2-ba2dd13679ae'
 WHERE id = '66cd60ba-a8b5-495f-9be5-b2360e1041a8'
   AND office_id IS DISTINCT FROM 'c6f4e77d-8a24-4bd2-b9c2-ba2dd13679ae';

-- Part C — survivor chamber active roster = 5 (Kassakhian/Asatryan/Gharpetian/Brotman/Bartrosouf).
UPDATE essentials.chambers
   SET official_count = 5
 WHERE id = '771727ec-684b-4eb8-98a6-d7205d9bbac0'
   AND official_count IS DISTINCT FROM 5;

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('903')
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ============================================================================
-- POST-VERIFICATION (run after apply)
-- ============================================================================
-- Najarian retired:  SELECT is_incumbent, is_active, office_id FROM essentials.politicians WHERE external_id=-700100; -- f,f,NULL
-- Bartrosouf seated: SELECT external_id, is_active, is_incumbent, office_id FROM essentials.politicians WHERE id='66cd60ba...'; -- -700101,t,t,c6f4e77d
-- 5 active office-linked members in 771727ec; Najarian not among them
-- official_count = 5; feedback_section_split_check → 0 rows for Glendale
