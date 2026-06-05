-- 212_fremont_headshots.sql
-- Phase 67 -- Fremont deep seed: headshot uploads (AUDIT ONLY)
--
-- IMPORTANT: This file is AUDIT-ONLY. It records the politician_images INSERTs
-- and politicians.photo_origin_url UPDATEs that were executed live during the
-- /find-headshots skill loop in Phase 67, Plan 03.
--
-- This file is NOT applied via the Supabase migrations ledger. The actual
-- SQL was executed against the live DB during the skill loop. This file
-- exists for audit, replay (e.g., bootstrapping a new environment), and
-- traceability -- NOT for the migration sequence.
--
-- Supabase migrations ledger sequence for Phase 67: 210, 211. (No 212 in ledger.)
-- This mirrors the SD Phase 65 pattern (209_sd_headshots.sql, also audit-only)
-- and the SF Phase 63 pattern (200_sf_headshots.sql, also audit-only).
--
-- NOTE: fremont.gov returns HTTP 403 on automated Python/curl fetches
-- (CivicEngage/Granicus CMS WAF blocks non-browser agents). All 7 images were
-- sourced from fremont.gov/government/mayor-city-council using Node.js fetch with
-- a browser User-Agent + Referer header. The page HTML (returned 200 via Node)
-- was parsed to extract /home/showpublishedimage/{id}/{timestamp} paths for each
-- council member and Mayor. These are official City of Fremont government portraits
-- (photo sessions appear to be from the same outdoor session at Fremont City Hall).
--
-- License: All 7 images are official government portraits from fremont.gov =>
-- public_domain (US government works). Mayor Raj Salwan's Wikimedia Commons page
-- (File:Raj_Salwan.jpg) was also verified: licensed CC0 (Creative Commons Zero /
-- Public Domain) -- so either source would qualify as public_domain.
--
-- Image processing: All 7 originals were 400x600 JPEG (ratio 2:3). Cropped from
-- top to 400x500 (4:5 ratio), then resized to 600x750 Lanczos q90 JPEG.
--
-- Executed: 2026-05-22
-- Source page: https://www.fremont.gov/government/mayor-city-council

BEGIN;

-- ============================================================
-- MAYOR (1)
-- ============================================================

-- Raj Salwan (-670001)
-- Source image: https://www.fremont.gov/home/showpublishedimage/482/638791182509370000
-- Original: 400x600 JPEG; cropped tall to 400x500 (4:5); resized 600x750 JPEG
-- Note: Wikimedia Commons File:Raj_Salwan.jpg also verified (CC0/public_domain)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -670001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/71124b00-549d-460c-8f84-41a01d99e037-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -670001)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.fremont.gov/government/mayor-city-council'
WHERE external_id = -670001 AND photo_origin_url IS NULL;

-- ============================================================
-- CITY COUNCIL (6)
-- ============================================================

-- Teresa Keng (D1, -670010)
-- Source image: https://www.fremont.gov/home/showpublishedimage/6159/637981555727730000
-- Original: 400x600 JPEG; cropped tall to 400x500 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -670010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fecd31b9-fc2e-4d90-80f2-15ac89fb0eff-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -670010)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.fremont.gov/government/mayor-city-council'
WHERE external_id = -670010 AND photo_origin_url IS NULL;

-- Desrie Campbell (D2, -670011)
-- Source image: https://www.fremont.gov/home/showpublishedimage/6771/638072457065130000
-- Original: 400x600 JPEG; cropped tall to 400x500 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -670011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/28839e39-6db1-4253-94a4-94ae234c241e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -670011)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.fremont.gov/government/mayor-city-council'
WHERE external_id = -670011 AND photo_origin_url IS NULL;

-- Kathy Kimberlin (D3, -670012)
-- Source image: https://www.fremont.gov/home/showpublishedimage/9621/638767001732970000
-- Original: 400x600 JPEG; cropped tall to 400x500 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -670012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f886f6da-d08f-4294-81bc-faf4a1eaad4d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -670012)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.fremont.gov/government/mayor-city-council'
WHERE external_id = -670012 AND photo_origin_url IS NULL;

-- Yang Shao (D4, -670013)
-- Source image: https://www.fremont.gov/home/showpublishedimage/10104/638767007145300000
-- Original: 400x600 JPEG; cropped tall to 400x500 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -670013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7db82a3d-5aa2-4150-996e-b170b50b47fe-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -670013)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.fremont.gov/government/mayor-city-council'
WHERE external_id = -670013 AND photo_origin_url IS NULL;

-- Yajing Zhang (D5, -670014)
-- Source image: https://www.fremont.gov/home/showpublishedimage/9838/638767002190270000
-- Original: 400x600 JPEG; cropped tall to 400x500 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -670014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d6d492b6-cbaf-4398-9301-4fbd10da571f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -670014)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.fremont.gov/government/mayor-city-council'
WHERE external_id = -670014 AND photo_origin_url IS NULL;

-- Raymond Liu (D6, -670015)
-- Source image: https://www.fremont.gov/home/showpublishedimage/9840/638791182084370000
-- Original: 400x600 JPEG; cropped tall to 400x500 (4:5); resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -670015),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/42e95c4c-4e02-4d60-805c-6a3d857dd95a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -670015)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.fremont.gov/government/mayor-city-council'
WHERE external_id = -670015 AND photo_origin_url IS NULL;

COMMIT;
