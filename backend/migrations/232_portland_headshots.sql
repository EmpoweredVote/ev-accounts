-- 232_portland_headshots.sql
-- Phase 77 -- Portland officials: headshot uploads (AUDIT ONLY)
--
-- IMPORTANT: This file is AUDIT-ONLY. It records the politician_images INSERTs
-- and politicians.photo_origin_url UPDATEs that were executed live during Phase 77
-- Plan 03 headshot processing loop.
--
-- This file is NOT applied via the Supabase migrations ledger. The actual SQL
-- was executed against the live DB during plan execution. This file exists for
-- audit, replay (e.g., bootstrapping a new environment), and traceability --
-- NOT for the migration sequence.
--
-- Supabase migrations ledger sequence for Phase 77: 230, 231. (No 232 in ledger.)
-- This mirrors the Berkeley Phase 68 pattern (215_berkeley_headshots.sql, audit-only),
-- the Fremont Phase 67 pattern (212_fremont_headshots.sql, audit-only),
-- and the OR Legislature pattern (228_or_legislature_headshots.sql, audit-only).
--
-- All 14 source images from portland.gov (government official portraits, public_domain).
-- Note: portland.gov blocks direct /public/ file access via WAF. Images downloaded
-- from Drupal 1_1_320w style CDN URLs (320x320 square), which return HTTP 200.
-- Original 320x320 JPEG/WebP: horizontally center-cropped to 256x320 (4:5),
-- then resized to 600x750 Lanczos q90 JPEG.
-- photo_origin_url records the canonical full-size path (sans Drupal style prefix)
-- for traceability, even though the 320w style URL was the actual download source.
--
-- Executed: 2026-05-30
-- Source page: https://www.portland.gov/auditor/elections/elected-city-officials
-- 14 elected officials: Mayor + City Auditor + 12 City Councilors (3 per district)
-- Excluded: City Administrator (-690003, appointed) + City Attorney (-690004, appointed)

BEGIN;

-- ============================================================
-- MAYOR (1)
-- ============================================================

-- Keith Wilson (-690001)
-- Source image: https://www.portland.gov/sites/default/files/public/2024/Wilson-Blue-Background_0.png
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bd39d61e-3040-4ec1-815e-df16b1f9a8a0-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690001)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2024/Wilson-Blue-Background_0.png'
WHERE external_id = -690001;

-- ============================================================
-- CITY AUDITOR (1)
-- ============================================================

-- Simone Rede (-690002)
-- Source image: https://www.portland.gov/sites/default/files/public/2022/auditor-simone-rede_1.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f797e87b-65dd-44c0-8d9d-967893d8ed3d-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690002)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2022/auditor-simone-rede_1.jpg'
WHERE external_id = -690002;

-- ============================================================
-- DISTRICT 1 COUNCIL (3)
-- ============================================================

-- Candace Avalos (D1, -690010)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Pink-Official-Background_0.png
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c5db367e-9403-4a88-a95f-bf864279e13b-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690010)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Pink-Official-Background_0.png'
WHERE external_id = -690010;

-- Jamie Dunphy (D1, -690011)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Dunphy---IMG_8672---square---web.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/14ebbd1c-597e-483a-a846-73a7aca54ed2-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690011)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Dunphy---IMG_8672---square---web.jpg'
WHERE external_id = -690011;

-- Loretta Smith (D1, -690012)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/CouncilorSmithheadshot.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e6682850-601f-4017-b4e7-d9cd4be47aea-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690012)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/CouncilorSmithheadshot.jpg'
WHERE external_id = -690012;

-- ============================================================
-- DISTRICT 2 COUNCIL (3)
-- ============================================================

-- Dan Ryan (D2, -690013)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Ryan---IMG_8965---square---web.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/60fa9870-d984-46a7-a6ed-5f6fbebe72ce-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690013)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Ryan---IMG_8965---square---web.jpg'
WHERE external_id = -690013;

-- Elana Pirtle-Guiney (D2, -690014)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Pirtle-Guiney---IMG_8935---square---web.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/987e0304-acd0-4b00-bf65-9e4fdbe4af3a-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690014)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Pirtle-Guiney---IMG_8935---square---web.jpg'
WHERE external_id = -690014;

-- Sameer Kanal (D2, -690015)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Kanal---IMG_9048---square---web_0.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690015),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc00f7c1-54d1-46d8-8b35-545abdd38d8d-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690015)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Kanal---IMG_9048---square---web_0.jpg'
WHERE external_id = -690015;

-- ============================================================
-- DISTRICT 3 COUNCIL (3)
-- ============================================================

-- Angelita Morillo (D3, -690016)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Morillo---IMG_9092---square---web.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690016),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c6799d98-362a-4e27-b7c5-be45a82a150f-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690016)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Morillo---IMG_9092---square---web.jpg'
WHERE external_id = -690016;

-- Steve Novick (D3, -690017)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Novick---IMG_9553---square---web.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690017),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c9e19031-259e-4133-b5d9-96cf1a5f31ff-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690017)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Novick---IMG_9553---square---web.jpg'
WHERE external_id = -690017;

-- Tiffany Koyama Lane (D3, -690018)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Koyama-Lane---IMG_9037---square---web.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690018),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2947c92f-fee2-46e4-b472-9fd89a8f0f65-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690018)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Koyama-Lane---IMG_9037---square---web.jpg'
WHERE external_id = -690018;

-- ============================================================
-- DISTRICT 4 COUNCIL (3)
-- ============================================================

-- Eric Zimmerman (D4, -690019)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Profile-Photo.png
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
-- Note: Zimmerman uses generic 'Profile-Photo.png' filename (not IMG_XXXX---square pattern)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690019),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1518349b-3d63-49d0-9411-be19f86a7ea7-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690019)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Profile-Photo.png'
WHERE external_id = -690019;

-- Mitch Green (D4, -690020)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Green---IMG_8827---square---web.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690020),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/acc73d7e-6522-40a9-bbe0-17cf56a96466-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690020)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Green---IMG_8827---square---web.jpg'
WHERE external_id = -690020;

-- Olivia Clark (D4, -690021)
-- Source image: https://www.portland.gov/sites/default/files/public/2025/Clark---IMG_9110---square---web_0.jpg
-- Downloaded via: 1_1_320w style, 320x320 WebP; cropped center to 256x320 (4:5); resized 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -690021),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c06d9bab-e31e-41e7-82d6-955c9309a3d4-headshot.jpg',
       'default', 'public_domain', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -690021)
    AND type = 'default'
);

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.portland.gov/sites/default/files/public/2025/Clark---IMG_9110---square---web_0.jpg'
WHERE external_id = -690021;

-- NOTE: Do NOT INSERT INTO supabase_migrations.schema_migrations for this migration.
-- This is audit-only. Ledger sequence for Phase 77 is 230, 231 only.
-- See 215_berkeley_headshots.sql, 212_fremont_headshots.sql, 228_or_legislature_headshots.sql
-- for precedent.

COMMIT;
