-- 999_downey_orphan_office_cleanup.sql
-- Phase 150 gap-closure — corrective STRUCTURAL migration (registers in schema_migrations).
--
-- WHY: The 6→5 roster reconcile (migration 991) unlinked stale member Pelc (-700161) by NULLing
-- his office's politician_id rather than removing the surplus office row. That left an ORPHAN office
-- (2ecc0a3e, politician_id NULL, label 'At-Large') attached to the Downey 'City Council' chamber —
-- a stale office row that would render as a phantom 6th "At-Large" vacancy in the browse view.
-- DWNY-01 SC5 requires "no duplicate/stale office rows". Verified: 0 essentials.races reference this
-- office, and politician_id IS NULL — safe to delete. Idempotent + guarded.
--
-- Survivor chamber: 7cb8a90c-1214-4840-bd75-5f6b9504532d

BEGIN;

-- Delete the orphan office only if it is genuinely unoccupied (guard against deleting a live seat)
DELETE FROM essentials.offices
WHERE id = '2ecc0a3e-c147-4310-9a8c-5b777cad6dba'
  AND politician_id IS NULL
  AND chamber_id = '7cb8a90c-1214-4840-bd75-5f6b9504532d';

-- Assert: the chamber now holds exactly 5 offices, all occupied, all LOCAL District 1-5
DO $$
DECLARE
  office_count int;
  occupied_count int;
BEGIN
  SELECT count(*) INTO office_count
  FROM essentials.offices
  WHERE chamber_id = '7cb8a90c-1214-4840-bd75-5f6b9504532d';
  IF office_count <> 5 THEN
    RAISE EXCEPTION 'Expected exactly 5 offices in Downey chamber after cleanup, found %', office_count;
  END IF;

  SELECT count(*) INTO occupied_count
  FROM essentials.offices
  WHERE chamber_id = '7cb8a90c-1214-4840-bd75-5f6b9504532d' AND politician_id IS NOT NULL;
  IF occupied_count <> 5 THEN
    RAISE EXCEPTION 'Expected all 5 Downey offices occupied after cleanup, found % occupied', occupied_count;
  END IF;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('999')
ON CONFLICT (version) DO NOTHING;

COMMIT;
