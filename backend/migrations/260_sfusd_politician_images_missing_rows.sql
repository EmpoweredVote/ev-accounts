-- Migration 260: Insert 4 missing politician_images rows for SFUSD commissioners
-- AUDIT-ONLY: already applied 2026-06-02 via direct SQL (found during Phase 87 re-UAT)
--
-- Root cause: sfusd-headshot-fixes.py and sfusd-headshot-fixes-2.py only upserted
-- to Supabase Storage but never inserted essentials.politician_images rows.
-- Affects: Jaime Huling, Matt Alexander, Parag Gupta, Supryia Ray (external_ids -870002/-870003/-870005/-870006)

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
VALUES
  ('6ef8e4aa-1262-4461-9124-93ef2aa34dc5',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6ef8e4aa-1262-4461-9124-93ef2aa34dc5-headshot.jpg',
   'default', 'cc_by'),
  ('f7d1b584-8c95-4e68-bedb-6f1b3fabab87',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f7d1b584-8c95-4e68-bedb-6f1b3fabab87-headshot.jpg',
   'default', 'cc_by'),
  ('8ca7781e-b688-4979-870d-80e36e21169f',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8ca7781e-b688-4979-870d-80e36e21169f-headshot.jpg',
   'default', 'cc_by'),
  ('61965a0c-e156-4a4a-bd4e-229ea6a15bf2',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/61965a0c-e156-4a4a-bd4e-229ea6a15bf2-headshot.jpg',
   'default', 'cc_by')
ON CONFLICT DO NOTHING;
