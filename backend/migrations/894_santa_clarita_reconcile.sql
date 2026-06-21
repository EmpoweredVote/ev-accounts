-- 894_santa_clarita_reconcile.sql
-- Phase 143 / Plan 01 — Santa Clarita structural reconcile (idempotent).
--
-- Reconciles the EXISTING partial, duplicate-chamber Santa Clarita seed. NO greenfield rebuild.
--
-- PRE-FLIGHT FINDING (2026-06-19) that overrides RESEARCH.md/CONTEXT D-02:
--   Duplicate "Chamber A" (315e67c5, external_id -200978) held THREE seated politicians, not
--   "1 empty Mayor + 2 council w/ only Smyth":
--     * Marsha McLean  9476ec1c  external_id -201394  ("Council Member", LOCAL At-Large 388fccb6)
--     * Cameron Smyth  dcf156cb  external_id -700180  ("Council Member", LOCAL At-Large 388fccb6)
--     * Bill Miranda   069fc0f2  external_id -200980  ("Mayor", LOCAL_EXEC "SC Mayor" d8663b4b)
--   McLean & Miranda are REAL current councilmembers that already exist (each with 1 image).
--   DECISION (user-approved): RESEAT the existing McLean/Miranda rows into the surviving Chamber B
--   in Plan 02 (no duplicate -700181/-700182 people). This migration 894 only RETIRES Smyth and
--   tears down Chamber A (offices + chamber + its two now-orphaned districts). McLean & Miranda
--   become office-less here and are re-seated in 895.
--
-- Surviving "Chamber B": eeabd028 (external_id 11243) — Ayala 665689 / Gibbs 665692 / Weste 665693.
-- chambers.slug is GENERATED — never written. All statements idempotent.

BEGIN;

-- (1) Backfill government geo_id (D-01 / SCLR-01)
UPDATE essentials.governments
   SET geo_id = '0669088'
 WHERE id = '42164a8f-2e0a-4786-9099-ce36f3f97101'
   AND geo_id IS NULL;

-- (2) RETIRE Cameron Smyth (departed Dec 10 2024) — detach office_id BEFORE deleting his office.
--     Do NOT reseat (Pitfall 1). Never delete the politician row.
UPDATE essentials.politicians
   SET office_id = NULL, is_incumbent = false, is_active = false
 WHERE external_id = -700180;

-- (2b) Detach McLean & Miranda politician.office_id if it points into a Chamber A office
--      (already NULL in pre-flight; guarded for safety/idempotency). They stay active/incumbent.
UPDATE essentials.politicians p
   SET office_id = NULL
 WHERE p.external_id IN (-201394, -200980)
   AND p.office_id IN (SELECT id FROM essentials.offices
                        WHERE chamber_id = '315e67c5-9fb3-480b-8647-a05a86a0cefd');

-- (3) DELETE all Chamber A offices (target chamber by UUID only — both chambers share name
--     'City Council'; T-143-01). FK-safe: offices before chamber/districts.
DELETE FROM essentials.offices
 WHERE chamber_id = '315e67c5-9fb3-480b-8647-a05a86a0cefd';

-- (4) DELETE Chamber A itself.
DELETE FROM essentials.chambers
 WHERE id = '315e67c5-9fb3-480b-8647-a05a86a0cefd';

-- (5) DELETE the two now-orphaned Chamber-A districts (no offices/children/inform refs — verified):
--     388fccb6 (LOCAL At-Large, Chamber-A only) and d8663b4b (stale LOCAL_EXEC "SC Mayor",
--     contradicts D-05 rotational-mayor model). Guarded: only delete if no office references them.
-- (districts.district_id is a TEXT code, not a uuid self-FK; child/inform refs verified 0 in pre-flight)
DELETE FROM essentials.districts d
 WHERE d.id IN ('388fccb6-b4cd-4b06-a3e2-d116a692d2c4',
                'd8663b4b-a6e6-46f1-ad43-af617acbb6c5')
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- (6) Dedupe Jason Gibbs images 2->1: keep press_use, drop scraped_no_license (Pitfall 6).
--     Scoped by politician + license (never bulk-delete by politician_id).
DELETE FROM essentials.politician_images
 WHERE politician_id = '434cd9b0-ce80-42fd-b71d-f221349e33f5'
   AND photo_license = 'scraped_no_license';

-- (7) Normalize surviving Chamber B titles to 'Councilmember' (kill any 'Council Member' space-variant; D-03).
UPDATE essentials.offices
   SET title = 'Councilmember'
 WHERE chamber_id = 'eeabd028-35b3-4aae-97ec-0fba4c829c00'
   AND title <> 'Councilmember';

-- (8) Back-fill politicians.office_id for any of Gibbs/Weste/Ayala where NULL (link to their Chamber B office).
UPDATE essentials.politicians p
   SET office_id = o.id
  FROM essentials.offices o
 WHERE o.chamber_id = 'eeabd028-35b3-4aae-97ec-0fba4c829c00'
   AND o.politician_id = p.id
   AND p.office_id IS DISTINCT FROM o.id
   AND p.external_id IN (665689, 665692, 665693);

-- (9) Surviving Chamber B official_count = 5 (final roster after 895 reseats McLean+Miranda).
UPDATE essentials.chambers
   SET official_count = 5
 WHERE id = 'eeabd028-35b3-4aae-97ec-0fba4c829c00'
   AND official_count IS DISTINCT FROM 5;

COMMIT;
