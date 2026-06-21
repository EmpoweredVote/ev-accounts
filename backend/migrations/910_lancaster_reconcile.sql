-- 910_lancaster_reconcile.sql
-- Phase 145 (Lancaster deep-seed) Wave 1 — STRUCTURAL (registers in schema_migrations)
-- Reconcile the pre-existing Lancaster seed:
--   (1) backfill geo_id 0640130 (was NULL)
--   (2) merge the duplicate "City Council" chamber (move-then-delete; UUID-targeted)
--   (3) repair the offices.politician_id <-> politicians.office_id bidirectional link for the
--       3 continuing members (Parris/Hughes-Leslie/Mann) whose back-pointer was NULL
--   (4) set survivor official_count = 5
-- Mayor office (ed37230d) is already district_type LOCAL_EXEC (confirmed read-only in pre-flight).
-- Stale members (Malhi -201280 lost, Crist 686320 retired) are RETIRED in Wave 2 (911), not here.
-- DB-verified live state 2026-06-20. Idempotent: re-running changes 0 rows.

BEGIN;

-- (1) geo_id backfill (guarded)
UPDATE essentials.governments
SET geo_id = '0640130'
WHERE id = 'f6732517-76d8-4f5f-b528-e49d60f32a4c' AND geo_id IS NULL;

-- (2) move the duplicate chamber's office (Crist's, afd045ec) into the survivor chamber
UPDATE essentials.offices
SET chamber_id = '9b9014b4-0106-417f-a104-ac2055fc8134'
WHERE chamber_id = 'a9be708e-1b42-42ac-92ec-e8e56f9c6474';

-- (3) assert the duplicate is now empty, then delete it (UUID-targeted; both share name/slug)
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
      WHERE chamber_id = 'a9be708e-1b42-42ac-92ec-e8e56f9c6474') > 0 THEN
    RAISE EXCEPTION 'Chamber a9be708e still has offices — aborting delete';
  END IF;
END $$;

DELETE FROM essentials.chambers WHERE id = 'a9be708e-1b42-42ac-92ec-e8e56f9c6474';

-- (4) repair bidirectional link for the 3 CONTINUING members (back-pointer was NULL)
UPDATE essentials.politicians SET office_id = 'ed37230d-28cf-4d5e-bf86-3292dfca6d08'
WHERE external_id = -200795 AND office_id IS DISTINCT FROM 'ed37230d-28cf-4d5e-bf86-3292dfca6d08'; -- R. Rex Parris (Mayor)
UPDATE essentials.politicians SET office_id = '052a2e17-622b-49ed-8ee6-eace538fe34c'
WHERE external_id = -201279 AND office_id IS DISTINCT FROM '052a2e17-622b-49ed-8ee6-eace538fe34c'; -- Lauren Hughes-Leslie
UPDATE essentials.politicians SET office_id = '6e17ff80-4b2c-4bd0-8a8e-8369e04010d8'
WHERE external_id = -201281 AND office_id IS DISTINCT FROM '6e17ff80-4b2c-4bd0-8a8e-8369e04010d8'; -- Ken Mann

-- (5) survivor official_count
UPDATE essentials.chambers SET official_count = 5
WHERE id = '9b9014b4-0106-417f-a104-ac2055fc8134' AND official_count IS DISTINCT FROM 5;

COMMIT;
