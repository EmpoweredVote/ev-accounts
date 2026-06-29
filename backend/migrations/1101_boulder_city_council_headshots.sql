-- Migration 1101: Boulder City City Council headshots (politician_images)
-- Phase 165 Plan 02 — CLARK-05 (headshot portion).
--
-- AUDIT-ONLY: NOT registered in the migration ledger; the structural ledger stays
-- at 1100. There is no ledger-registration INSERT in this file.
--
-- Columns are exactly (id, politician_id, url, type, photo_license). The removed
-- image-origin column is intentionally absent. type='default' on all rows.
-- politician_id resolved by stable external_id (minted by mig 1100). Idempotent
-- via NOT EXISTS. photo_license per member from the headshot manifest.
--
-- Sources (all clean head-and-shoulders portraits, no overlay, correct-person
-- spot-checked at execution; flybouldercity.com ImageRepository — clean, no WAF):
--   Hardy (Mayor)  — flybouldercity.com documentId=10964  (us_government_work)
--   Jorgensen      — flybouldercity.com documentId=9459    (us_government_work)
--   Booth          — flybouldercity.com documentId=10924   (us_government_work)
--   Walton         — flybouldercity.com documentId=10899   (us_government_work)
--   Ashurst        — flybouldercity.com documentId=14763   (us_government_work)
-- 5/5 sourced; 0 gaps.

BEGIN;

-- -3208001 Joe Hardy (Mayor)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3208001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/df1a6a02-6248-41df-8274-b589f6770aee-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3208001)
);

-- -3208002 Sherri Jorgensen (Council Member)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3208002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d604777b-9e3a-4f3b-b1a3-3ee965177788-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3208002)
);

-- -3208003 Cokie Booth (Council Member)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3208003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/49226ba0-9a4f-4269-8415-eac2395fe696-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3208003)
);

-- -3208004 Steve Walton (Council Member)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3208004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/59d2cdfd-ca4a-4a1b-9a62-1e00ec79b549-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3208004)
);

-- -3208005 Denise E. Ashurst (Council Member)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3208005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d593c322-4c04-409a-9da4-c77294b1772d-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3208005)
);

COMMIT;
-- AUDIT-ONLY: no schema_migrations INSERT (structural ledger stays at 1100).
