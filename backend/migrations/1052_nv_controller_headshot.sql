-- 1052_nv_controller_headshot.sql
-- Phase 159 (NV-STATE-01): AUDIT-ONLY — politician_images row for the NV State Controller.
-- NOT registered in the migration ledger; the ledger stays at 1050.
-- Applied via mcp__supabase-local__execute_sql (not apply_migration) AFTER the headshot
--   script (_tmp-nv-controller-headshot.py) uploads the image to Storage.
-- Source: Wikimedia Commons "Andy_Matthews_by_Gage_Skidmore.jpg" — CC BY-SA 3.0 (Gage Skidmore).
-- Storage path: politician_photos/{controller_uuid}-headshot.jpg
-- Columns: exactly (id, politician_id, url, type, photo_license) — the origin-url column was removed from the schema.
--
-- ORCHESTRATOR NOTE: the url literal below already carries Andy Matthews' actual politician
--   UUID (07a8598f-666f-4ac5-b6ee-09cb9f815783), captured from migration 1050 in Task 2.
--   If the migration is ever re-run against a DB where the UUID differs, re-derive the UUID
--   via: SELECT id FROM essentials.politicians WHERE external_id = -3200006; and substitute it.

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3200006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/07a8598f-666f-4ac5-b6ee-09cb9f815783-headshot.jpg',
       'default', 'cc_by_sa_3.0'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3200006)
);
