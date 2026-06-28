-- Migration 1076: City of Las Vegas City Council headshots (politician_images)
--
-- Phase 162 (CLARK-02) — AUDIT-ONLY. Applied via execute_sql after the headshot
-- upload pipeline (_tmp-lv-city-council-headshots.py) ran and uploaded all 7
-- 600x750 portraits to the politician_photos bucket. This file is NOT registered
-- in the migration ledger; the structural ledger stays at 1075.
--
-- 7/7 council members uploaded, 0 documented gaps. Each portrait was crop-to-4:5
-- then resized to 600x750 (Lanczos, q90); Olivia Diaz's 600x400 landscape source
-- was center-cropped to 320x400 then upscaled. Sources are official lasvegasnevada.gov
-- portraits served from Azure Blob → photo_license='us_government_work'.
--
-- One idempotent INSERT per member (WHERE NOT EXISTS on politician_id). politician_id
-- resolved via external_id subquery. Column list is exactly (id, politician_id, url,
-- type, photo_license) — the removed image-origin column is intentionally absent.

BEGIN;

-- -3205001 Shelley Berkley (Mayor)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3205001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2568b40c-a517-4eaa-b0da-eb946f9b6df9-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3205001)
);

-- -3205002 Brian Knudsen (Ward 1)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3205002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/169596c9-1ece-4a8a-b601-ce87af369a33-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3205002)
);

-- -3205003 Kara Kelley (Ward 2)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3205003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1c488168-519f-4119-bce6-ae848a6d3001-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3205003)
);

-- -3205004 Olivia Diaz (Ward 3) [600x400 landscape source — center-cropped to 320x400 then upscaled]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3205004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/168705cc-2899-4432-b062-cb8583ac99e6-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3205004)
);

-- -3205005 Francis Allen-Palenske (Ward 4)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3205005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/91544dd2-07c7-4885-943f-f431836ddecf-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3205005)
);

-- -3205006 Shondra Summers-Armstrong (Ward 5)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3205006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6f433371-e691-41ed-9f0e-580626e0cb32-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3205006)
);

-- -3205007 Nancy E. Brune (Ward 6)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3205007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0a0ea0c6-ed7b-4e84-833d-f6a04d3350e9-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3205007)
);

COMMIT;
