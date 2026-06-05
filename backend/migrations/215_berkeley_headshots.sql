-- 215_berkeley_headshots.sql
-- Phase 68 -- Berkeley deep seed: headshot uploads (AUDIT ONLY)
--
-- IMPORTANT: This file is AUDIT-ONLY. It records the politician_images INSERTs
-- and politicians.photo_origin_url UPDATEs that were executed live during the
-- /find-headshots skill loop in Phase 68, Plan 03.
--
-- This file is NOT applied via the Supabase migrations ledger. The actual
-- SQL was executed against the live DB during the skill loop. This file
-- exists for audit, replay (e.g., bootstrapping a new environment), and
-- traceability -- NOT for the migration sequence.
--
-- Supabase migrations ledger sequence for Phase 68: 213, 214. (No 215 in ledger.)
-- This mirrors the Fremont Phase 67 pattern (212_fremont_headshots.sql, audit-only),
-- the SD Phase 65 pattern (209_sd_headshots.sql, audit-only),
-- and the SF Phase 63 pattern (200_sf_headshots.sql, audit-only).
--
-- All 10 source images from berkeleyca.gov (government portraits, public_domain).
-- berkeleyca.gov returned HTTP 200 on all 10 URLs with standard User-Agent header.
-- No 403 workaround was required (unlike fremont.gov).
--
-- Image processing: All 10 originals were 300x300 JPEG (square, ratio 1:1).
-- Cropped from top to 300x375 would be 4:5 -- but since 1:1 is wider than 4:5,
-- crop horizontally: new_w = int(300 * 4/5) = 240, then centered crop (left=30).
-- Final: cropped to 240x300, then resized to 600x750 Lanczos q90 JPEG.
--
-- Executed: 2026-05-22
-- Source page: https://berkeleyca.gov/your-government/elected-officials

BEGIN;

-- ============================================================
-- MAYOR (1)
-- ============================================================

-- Adena Ishii (-680001)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/adena-ishii.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/965de422-660e-4e24-9fe6-717cc0313403-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680001)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/adena-ishii.jpg'
WHERE external_id = -680001 AND photo_origin_url IS NULL;

-- ============================================================
-- CITY AUDITOR (1)
-- ============================================================

-- Jenny Wong (-680002)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/Jenny_Wong.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3342ae40-cc86-43e5-8581-3237b6aa8f08-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680002)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/Jenny_Wong.jpg'
WHERE external_id = -680002 AND photo_origin_url IS NULL;

-- ============================================================
-- CITY COUNCIL (8)
-- ============================================================

-- Rashi Kesarwani (D1, -680010)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/kesarwani.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d2013613-769f-4374-809e-a018dbc1e683-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680010)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/kesarwani.jpg'
WHERE external_id = -680010 AND photo_origin_url IS NULL;

-- Terry Taplin (D2, -680011)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/Terry%20Taplin.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bcdb549a-48bf-400f-9d23-c93e2e71007c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680011)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/Terry%20Taplin.jpg'
WHERE external_id = -680011 AND photo_origin_url IS NULL;

-- Ben Bartlett (D3, -680012)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/Ben-Bartlet.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eaab41f8-71c8-47db-bd0b-62da46b5607b-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680012)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/Ben-Bartlet.jpg'
WHERE external_id = -680012 AND photo_origin_url IS NULL;

-- Igor Tregub (D4, -680013)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/Igor-Tregub-headshot.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9f9a35a9-0226-45f0-9fd8-ef46163f7245-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680013)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/Igor-Tregub-headshot.jpg'
WHERE external_id = -680013 AND photo_origin_url IS NULL;

-- Shoshana O'Keefe (D5, -680014)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/OKeefe240628-499.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8cc1c412-fe14-4bc6-b1e2-02d95997fd47-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680014)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/OKeefe240628-499.jpg'
WHERE external_id = -680014 AND photo_origin_url IS NULL;

-- Brent Blackaby (D6, -680015)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/brent_blackaby_square_headshot-medium.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680015),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/424eb63b-9976-4059-8049-365c09719cc6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680015)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/brent_blackaby_square_headshot-medium.jpg'
WHERE external_id = -680015 AND photo_origin_url IS NULL;

-- Cecilia Lunaparra (D7, -680016)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/cecilia-lunaparra.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680016),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/116aace8-9440-498b-bf1d-ebb196727c85-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680016)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/cecilia-lunaparra.jpg'
WHERE external_id = -680016 AND photo_origin_url IS NULL;

-- Mark Humbert (D8, -680017)
-- Source image: https://berkeleyca.gov/sites/default/files/elected-office-holder/Mark-Humbert-300px.jpg
-- Original: 300x300 JPEG (1:1 square); cropped horizontally to 240x300 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -680017),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7833be90-c693-40b8-a309-61ee77b4ba03-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -680017)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://berkeleyca.gov/sites/default/files/elected-office-holder/Mark-Humbert-300px.jpg'
WHERE external_id = -680017 AND photo_origin_url IS NULL;

COMMIT;
