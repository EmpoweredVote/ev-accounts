-- 1339_indio_headshots.sql
-- Phase 203 Plan 03 (CV-03): AUDIT-ONLY -- politician_images rows for all 5
-- sitting City of Indio (California) City Council members. NOT registered in the
-- migration ledger; the ledger table stays unchanged (audit-only, no ledger
-- footer). Applied via `psql -f` (NOT apply_migration) AFTER the pipeline
-- (_tmp-indio-headshots.py) uploads all 5 processed images to Storage.
--
-- Sources: all 5 are the full-resolution studio portraits published on the
-- official city-hosted indio.org CivicPlus StaffDirectory (indio.org/home/
-- showpublishedimage/*). The CivicWeb portal (indio.civicweb.net) only carried
-- 165x215 thumbnails, too small to upscale; indio.org WAF-403s plain bots so the
-- originals were fetched via a real browser session. All processed 4:5 crop-first
-- -> 600x750 Lanczos q90 (the four 1920x2880 sources tightened to ~9% headroom).
-- Every image is served from the official city government site (never campaign/
-- press/Wikimedia) -> photo_license='us_government_work' on every row.
--   -4012001 Glenn Miller           -- indio.org StaffDirectory (us_government_work)
--   -4012002 Waymond Fermon (MPT)   -- indio.org StaffDirectory (us_government_work)
--   -4012003 Elaine Holmes (Mayor)  -- indio.org StaffDirectory (us_government_work)
--   -4012004 Oscar Ortiz            -- indio.org StaffDirectory (us_government_work)
--   -4012005 Benjamin Guitron IV    -- indio.org StaffDirectory (us_government_work)
--
-- Columns: exactly (id, politician_id, url, type, photo_license). type='default'
-- (the UI filters on it). politician UUIDs below are from 203-02-SUMMARY.md's
-- manifest (they appear only in the CDN Storage path); politician_id is resolved
-- by external_id at apply time. WHERE NOT EXISTS on politician_id for idempotency.

-- ============================================================
-- City Council (5 rows)
-- ============================================================

-- Glenn Miller (District 1, external_id=-4012001)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4012001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4012001)
);

-- Waymond Fermon (District 2, Mayor Pro Tem, external_id=-4012002)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4012002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/86fe2b91-d1fa-4c65-8d75-90f181624fe4-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4012002)
);

-- Elaine Holmes (District 3, Mayor, external_id=-4012003)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4012003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dea49bf0-12b4-40b7-a48c-a3eda018ef04-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4012003)
);

-- Oscar Ortiz (District 4, external_id=-4012004)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4012004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4bbba476-c442-42d5-8b5d-07e8fac1481c-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4012004)
);

-- Benjamin Guitron IV (District 5, external_id=-4012005)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4012005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f13b83e3-e086-479a-b6e4-9ad63f89f308-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4012005)
);
