-- 209_sd_headshots.sql
-- Phase 65 -- San Diego deep seed: headshot uploads (AUDIT ONLY)
--
-- IMPORTANT: This file is AUDIT-ONLY. It records the politician_images INSERTs
-- and politicians.photo_origin_url UPDATEs that were executed live during the
-- /find-headshots skill loop in Phase 65, Plan 03.
--
-- This file is NOT applied via the Supabase migrations ledger. The actual
-- SQL was executed against the live DB during the skill loop. This file
-- exists for audit, replay (e.g., bootstrapping a new environment), and
-- traceability -- NOT for the migration sequence.
--
-- Supabase migrations ledger sequence for Phase 65: 207, 208. (No 209.)
-- This mirrors the SF Phase 63 pattern (200_sf_headshots.sql, also audit-only).
--
-- Source: All 11 URLs scraped from official sandiego.gov pages -- public_domain.
-- Executed: 2026-05-22

BEGIN;

-- ============================================================
-- MAYOR (1)
-- ============================================================

-- Todd Gloria (-650001)
-- Source: https://www.sandiego.gov/sites/default/files/todd-gloria-2.png
-- Original: 379x400 RGBA PNG; cropped wide to 320x400; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a975b943-f3e0-492a-bd26-9f5993a5c094-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650001)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/todd-gloria-2.png'
WHERE external_id = -650001 AND photo_origin_url IS NULL;

-- ============================================================
-- CITY ATTORNEY (1)
-- ============================================================

-- Heather Ferbert (-650002)
-- Source: https://www.sandiego.gov/sites/default/files/2025-08/city-attorney-ferbert-headshot.jpg
-- Original: 2048x2560 JPEG; ratio already 4:5; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0d81c306-514e-455c-988e-b0d04f7e0897-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650002)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/2025-08/city-attorney-ferbert-headshot.jpg'
WHERE external_id = -650002 AND photo_origin_url IS NULL;

-- ============================================================
-- CITY COUNCIL (9)
-- ============================================================

-- Joe LaCava (D1, -650010)
-- Source: https://www.sandiego.gov/sites/default/files/joe-lacava-sq.jpg (stripped ?v=1)
-- Original: 300x300 JPEG square; cropped wide to 240x300; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1e93b635-3706-4268-91e2-97abae0c54a0-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650010)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/joe-lacava-sq.jpg'
WHERE external_id = -650010 AND photo_origin_url IS NULL;

-- Jennifer Campbell (D2, -650011)
-- Source: https://www.sandiego.gov/sites/default/files/jennifer-campbell-sq.jpg
-- Original: 300x300 JPEG square; cropped wide to 240x300; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c6d7ea83-d6ee-4d08-a183-effd36f6a2cc-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650011)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/jennifer-campbell-sq.jpg'
WHERE external_id = -650011 AND photo_origin_url IS NULL;

-- Stephen Whitburn (D3, -650012)
-- Source: https://www.sandiego.gov/sites/default/files/2024-10/stephen-whitburn-v2.jpg
-- Original: 300x300 JPEG square; cropped wide to 240x300; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f86591f9-4341-4e3a-a9cb-f284887ccf74-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650012)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/2024-10/stephen-whitburn-v2.jpg'
WHERE external_id = -650012 AND photo_origin_url IS NULL;

-- Henry L. Foster III (D4, -650013)
-- Source: https://www.sandiego.gov/sites/default/files/2024-04/cd7-henry-foster-iii.png
-- NOTE: CMS NAMING ANOMALY -- filename says "cd7" but URL was scraped from the D4 section of
-- sandiego.gov/citycouncil. Image must be visually verified to show Henry L. Foster III (D4
-- council member). Human verification checkpoint required before SUMMARY creation.
-- Original: 300x300 PNG RGB; cropped wide to 240x300; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/296b5d71-954a-46db-8055-17299abb86fa-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650013)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/2024-04/cd7-henry-foster-iii.png'
WHERE external_id = -650013 AND photo_origin_url IS NULL;

-- Marni von Wilpert (D5, -650014)
-- Source: https://www.sandiego.gov/sites/default/files/2024-10/councilmember-marni-von-wilpert.jpg
-- Original: 200x200 JPEG square; cropped wide to 160x200; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3f1fad4-46cd-4f2f-8723-d7a3f99dca65-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650014)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/2024-10/councilmember-marni-von-wilpert.jpg'
WHERE external_id = -650014 AND photo_origin_url IS NULL;

-- Kent Lee (D6, -650015)
-- Source: https://www.sandiego.gov/sites/default/files/councilmember-kent-lee-cd6.jpg
-- Original: 400x400 JPEG square; cropped wide to 320x400; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650015),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3fb56c85-f8b7-4732-88e1-f79b56750428-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650015)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/councilmember-kent-lee-cd6.jpg'
WHERE external_id = -650015 AND photo_origin_url IS NULL;

-- Raul Campillo (D7, -650016)
-- Source: https://www.sandiego.gov/sites/default/files/raul-campillo-sq.jpg (stripped ?v=1)
-- Original: 300x300 JPEG square; cropped wide to 240x300; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650016),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/84ba4a09-a90f-4ad4-9fa3-995961bd839c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650016)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/raul-campillo-sq.jpg'
WHERE external_id = -650016 AND photo_origin_url IS NULL;

-- Vivian Moreno (D8, -650017)
-- Source: https://www.sandiego.gov/sites/default/files/2024-05/councilmember-vivian-moreno-headshot.jpg
-- Original: 300x300 JPEG square; cropped wide to 240x300; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650017),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0b16443e-fec4-4f33-abbc-eb1331e3b42d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650017)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/2024-05/councilmember-vivian-moreno-headshot.jpg'
WHERE external_id = -650017 AND photo_origin_url IS NULL;

-- Sean Elo-Rivera (D9, -650018)
-- Source: https://www.sandiego.gov/sites/default/files/sean-elo-rivera-sq.jpg (stripped ?v=2)
-- Original: 300x300 JPEG square; cropped wide to 240x300; resized 600x750 JPEG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -650018),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc3d8a98-07ce-4797-bc84-957a72fd854f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -650018)
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.sandiego.gov/sites/default/files/sean-elo-rivera-sq.jpg'
WHERE external_id = -650018 AND photo_origin_url IS NULL;

COMMIT;
