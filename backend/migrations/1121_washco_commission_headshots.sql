-- Migration 1121: Washington County Board of County Commissioners Headshots
-- AUDIT-ONLY: captures the live politician_images INSERTs performed during Phase 175-02
-- execution after scripts/_tmp-washco-headshots.py uploads to Supabase Storage.
-- DO NOT register in supabase_migrations.schema_migrations — audit-only pattern
-- (same as 245_multnomah_county_headshots.sql, 200_sf_headshots.sql, etc.).
-- Apply via: psql "$DATABASE_URL" -f migrations/1121_washco_commission_headshots.sql
--
-- 5 Washington County Board of County Commissioners:
--   external_id -410100  -- Kathryn Harrington (County Chair, at-large)
--   external_id -410110  -- Nafisa Fai (Commissioner District 1)
--   external_id -410111  -- Pam Treece (Commissioner District 2)
--   external_id -410112  -- Jason Snider (Commissioner District 3)
--   external_id -410113  -- Jerry Willey (Commissioner District 4)
--
-- Source: media-production.washcotech.net CDN via washingtoncountyor.gov/elections/county-officials
--   URL pattern: https://media-production.washcotech.net/styles/max_966_wide/s3/YYYY-MM/FILENAME.jpg
--   All 5 images are Oregon county government official portraits.
--
-- Photo processing: source JPEG/PNG -> RGBA-to-white-composite if transparent ->
--   crop to 4:5 ratio FIRST -> resize 600x750 Lanczos JPEG q90.
-- Storage bucket: politician_photos; path: {politician_uuid}-headshot.jpg.
-- type='default', photo_license='us_government_work'.
--
-- NOTE: Storage URLs below use the politician UUID as the file key
-- (politician_photos/{uuid}-headshot.jpg). The inline orchestrator fills these
-- after running _tmp-washco-headshots.py and confirming each upload succeeded.
-- Commissioners for whom the pipeline logged a GAP are omitted; their office
-- rows still exist from structural migration 1120.

-- ============================================================
-- WASHINGTON COUNTY BOARD OF COUNTY COMMISSIONERS (5 officials)
-- ============================================================

-- Kathryn Harrington (-410100) -- County Chair (at-large, county-wide seat)
-- source: https://media-production.washcotech.net/styles/max_966_wide/s3/2023-01/Chair%20Harrington%2022.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410100),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/76b00811-8bf8-46c0-bb0c-9867c90fe9d4-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410100)
);

-- Nafisa Fai (-410110) -- Commissioner District 1
-- source: https://media-production.washcotech.net/styles/max_966_wide/s3/2023-01/Fai%20D1%2022.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410110),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a1fe6f71-0d44-4c85-957f-06ffb6a4f825-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410110)
);

-- Pam Treece (-410111) -- Commissioner District 2
-- source: https://media-production.washcotech.net/styles/max_966_wide/s3/2023-01/Treece%20D2%2022.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410111),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0cb0bffc-efea-4e0b-93e0-7a53eae10a42-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410111)
);

-- Jason Snider (-410112) -- Commissioner District 3
-- source: https://media-production.washcotech.net/styles/max_966_wide/s3/2025-01/snider.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410112),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a98aeea6-c7cf-475c-96f2-100119c9037a-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410112)
);

-- Jerry Willey (-410113) -- Commissioner District 4
-- source: https://media-production.washcotech.net/styles/max_966_wide/s3/2023-01/Willey%20D4%2022.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410113),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f010b78a-9050-4bba-baed-0070037cd2da-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410113)
);
