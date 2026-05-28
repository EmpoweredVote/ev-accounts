-- 219_sj_headshots.sql
-- Phase 77 -- San Jose deep seed: headshot uploads (AUDIT ONLY)
--
-- IMPORTANT: This file is AUDIT-ONLY. It records the politician_images INSERTs
-- and politicians.photo_origin_url UPDATEs that were executed live during the
-- /find-headshots skill loop in Phase 77, Plan 01.
--
-- This file is NOT applied via the Supabase migrations ledger. The actual
-- SQL was executed against the live DB during the skill loop. This file
-- exists for audit, replay (e.g., bootstrapping a new environment), and
-- traceability -- NOT for the migration sequence.
--
-- Supabase migrations ledger sequence for Phase 77: 217, 218. (No 219 in ledger.)
-- This mirrors the Berkeley/Fremont/SD/SF audit-only headshots pattern.
--
-- Image processing: Mixed sources and crop strategies per official.
--   - Wikimedia Commons sources (Mahan, Ortiz, Doan, Candelas, Foley): downloaded with
--     Wikimedia User-Agent; cropped from portrait or square to 4:5; resized 600x750 Lanczos q90
--   - sanjoseca.gov sources (Kamei, Mulcahy): pre-downloaded via Node.js WAF bypass
--     (direct HTTP request with browser User-Agent); resized 600x750 Lanczos q90
--   - Squarespace CDN sources (Campos, Tordillos, Cohen, Casey): fetched with
--     browser User-Agent + Referer; cropped to 4:5 where needed; resized 600x750 Lanczos q90
--   All images stored as JPEG quality 90, type='default'.
--
-- Executed: 2026-05-23
-- Source pages: https://www.sanjoseca.gov/your-government/elected-officials/city-council
--               https://www.sanjoseca.gov/your-government/departments-offices/mayor

BEGIN;

-- ============================================================
-- MAYOR (1)
-- ============================================================

-- Matt Mahan (-640001)
-- Source image: https://upload.wikimedia.org/wikipedia/commons/a/ae/Matt_Mahan_portrait_2025.jpg
-- License: cc-by-sa-4.0 (Wikimedia Commons)
-- Original: portrait JPEG; cropped from bottom to get 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/41949a2b-563a-4608-91c6-951c63252a91-headshot.jpg',
       'default', 'cc-by-sa-4.0'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640001)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/a/ae/Matt_Mahan_portrait_2025.jpg'
WHERE external_id = -640001 AND photo_origin_url IS NULL;

-- ============================================================
-- CITY COUNCIL (10)
-- ============================================================

-- Rosemary Kamei (D1, -640010)
-- Source image: https://www.sanjoseca.gov/your-government/elected-officials/city-council/district-1-rosemary-kamei
-- (sanjoseca.gov official portrait, public domain; pre-downloaded via Node.js WAF bypass)
-- Original: 1920x1920 JPEG (1:1 square); cropped to 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7921e8f3-2e6f-47f8-bc2b-95b81bab6516-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640010)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sanjoseca.gov/your-government/elected-officials/city-council/district-1-rosemary-kamei'
WHERE external_id = -640010 AND photo_origin_url IS NULL;

-- Pamela Campos (D2, -640011)
-- Source image: https://images.squarespace-cdn.com/content/v1/6942f53c3db83d0e41471664/d9561bd5-aae8-4d86-99df-390794b8bfed/Official+Portrait-Councilmember+Campos.jpg?format=2500w
-- (sjdistrict2.org official portrait, public domain; Squarespace CDN)
-- Original: 1950x2524 portrait JPEG; cropped to 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/104cca89-3420-457b-a35d-b446be2d72ab-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640011)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://images.squarespace-cdn.com/content/v1/6942f53c3db83d0e41471664/d9561bd5-aae8-4d86-99df-390794b8bfed/Official+Portrait-Councilmember+Campos.jpg?format=2500w'
WHERE external_id = -640011 AND photo_origin_url IS NULL;

-- Anthony Tordillos (D3, -640012)
-- Source image: https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/51c8e8fe-edad-4a15-89b7-0906009f2f9f/CM+Tordillos+First+Day.png?format=2500w
-- (sjdistrict3.org official portrait, public domain; Squarespace CDN)
-- Original: 1080x1350 portrait PNG; cropped to 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7b527446-d801-42c6-9233-053c2b02e128-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640012)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/51c8e8fe-edad-4a15-89b7-0906009f2f9f/CM+Tordillos+First+Day.png?format=2500w'
WHERE external_id = -640012 AND photo_origin_url IS NULL;

-- David Cohen (D4, -640013)
-- Source image: https://images.squarespace-cdn.com/content/v1/6201a5e40577d74133ad4cad/d95c1d21-c133-483a-b929-d1ebcbd43456/Davidatstorm.png?format=2500w
-- (sanjosedistrict4.com official portrait, public domain; Squarespace CDN)
-- Original: 1600x1600 PNG (1:1 square); cropped to 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/83292881-92b3-4257-b291-4b02509a167c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640013)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://images.squarespace-cdn.com/content/v1/6201a5e40577d74133ad4cad/d95c1d21-c133-483a-b929-d1ebcbd43456/Davidatstorm.png?format=2500w'
WHERE external_id = -640013 AND photo_origin_url IS NULL;

-- Peter Ortiz (D5, -640014)
-- Source image: https://upload.wikimedia.org/wikipedia/commons/9/96/Peter_Ortiz%2C_San_Jos%C3%A9_City_Councilman.png
-- License: public_domain (Wikimedia Commons)
-- Original: 200x200 PNG (1:1 square); upscaled with Lanczos; cropped to 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a464cef9-de7f-45a3-8ff3-9bab20275db4-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640014)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/9/96/Peter_Ortiz%2C_San_Jos%C3%A9_City_Councilman.png'
WHERE external_id = -640014 AND photo_origin_url IS NULL;

-- Michael Mulcahy (D6, -640015)
-- Source image: https://www.sanjoseca.gov/your-government/elected-officials/city-council/district-6-michael-mulcahy
-- (sanjoseca.gov official portrait, public domain; pre-downloaded via Node.js WAF bypass)
-- Original: 495x640 portrait JPEG; cropped to 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640015),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a05e1faa-c780-4a65-b01f-cca7e6f0210b-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640015)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sanjoseca.gov/your-government/elected-officials/city-council/district-6-michael-mulcahy'
WHERE external_id = -640015 AND photo_origin_url IS NULL;

-- Bien Doan (D7, -640016)
-- Source image: https://upload.wikimedia.org/wikipedia/commons/5/50/Bien_Doan%2C_San_Jos%C3%A9_City_Councilman.png
-- License: public_domain (Wikimedia Commons)
-- Original: 200x200 PNG (1:1 square); upscaled with Lanczos; cropped to 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640016),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e4ac6674-1fa3-422a-857f-570873b86da3-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640016)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/5/50/Bien_Doan%2C_San_Jos%C3%A9_City_Councilman.png'
WHERE external_id = -640016 AND photo_origin_url IS NULL;

-- Domingo Candelas (D8, -640017)
-- Source image: https://upload.wikimedia.org/wikipedia/commons/1/15/Domingo_Candelas%2C_San_Jos%C3%A9_City_Councilman.png
-- License: public_domain (Wikimedia Commons)
-- Original: 200x200 PNG (1:1 square); upscaled with Lanczos; cropped to 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640017),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ab7cf49d-73af-4391-9a15-ebe0522e5bc5-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640017)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/1/15/Domingo_Candelas%2C_San_Jos%C3%A9_City_Councilman.png'
WHERE external_id = -640017 AND photo_origin_url IS NULL;

-- Pam Foley (D9, -640018)
-- Source image: https://upload.wikimedia.org/wikipedia/commons/1/11/Foley_Pam_-_San_Jos%C3%A9_City_Councilwoman.jpg
-- License: public_domain (Wikimedia Commons)
-- Original: 1536x1920 portrait JPEG; cropped to 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640018),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3c9b607b-5dd6-43ab-ac4f-cab553adb7ab-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640018)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/1/11/Foley_Pam_-_San_Jos%C3%A9_City_Councilwoman.jpg'
WHERE external_id = -640018 AND photo_origin_url IS NULL;

-- George Casey (D10, -640019)
-- Source image: https://images.squarespace-cdn.com/content/v1/67d36df71d3cca0e7ebe4c0e/824d19c7-6a09-482a-8000-c2faa6c4dee9/George+Casey+higher+quality+square+photo.jpg?format=2500w
-- (sjdistrict10.org official photo, public domain; Squarespace CDN)
-- Original: 2048x1365 landscape JPEG; center-crop to portrait; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -640019),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f0d4ce8b-4ed7-45ec-b08e-439dded83313-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -640019)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://images.squarespace-cdn.com/content/v1/67d36df71d3cca0e7ebe4c0e/824d19c7-6a09-482a-8000-c2faa6c4dee9/George+Casey+higher+quality+square+photo.jpg?format=2500w'
WHERE external_id = -640019 AND photo_origin_url IS NULL;

COMMIT;
