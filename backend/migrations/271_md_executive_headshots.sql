-- Migration 271: MD Executive Officials Headshots
-- AUDIT-ONLY: captures the live politician_images INSERTs performed during
-- Phase 92-02 execution on 2026-06-05.
-- DO NOT apply via Supabase ledger — actual DB writes happened live via
-- scripts/md_executives_headshots.py (Python PIL + Supabase Storage API)
-- and psql direct inserts.
-- This is AUDIT-ONLY in the same pattern as 245_multnomah_county_headshots.sql,
-- 225_or_headshots.sql, 200_sf_headshots.sql, etc.
--
-- 5 Maryland constitutional officers:
--   external_id -240001 — Wes Moore (Governor)
--   external_id -240002 — Aruna Miller (Lieutenant Governor)
--   external_id -240003 — Anthony G. Brown (Attorney General)
--   external_id -240004 — Brooke Lierman (Comptroller)
--   external_id -240005 — Dereck E. Davis (State Treasurer)
--
-- Sources:
--   Moore:   cdn.maryland.gov — WebP 504x672 -> crop 504x630 -> resize 600x750 (public_domain)
--   Miller:  cdn.maryland.gov — WebP 504x672 -> crop 504x630 -> resize 600x750 (public_domain)
--   Brown:   oag.maryland.gov — JPEG 192x240 (already 4:5) -> resize 600x750 (public_domain)
--   Lierman: marylandcomptroller.gov — PNG 1280x1488 -> crop 1190x1488 -> resize 600x750 (public_domain)
--   Davis:   Wikimedia Commons — JPEG 989x1319 -> crop 989x1236 -> resize 600x750 (public_domain)
--
-- Photo processing: Pillow LANCZOS resize at q90; crop 4:5 BEFORE resize (never stretch).
-- Storage bucket: politician_photos; path: {politician_id}-headshot.jpg.
-- Storage URL: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
-- Column: url (NOT storage_url — RESEARCH.md Pitfall 4 confirmed via information_schema.columns)

-- ============================================================
-- MARYLAND EXECUTIVE OFFICIALS (5 officials)
-- ============================================================

-- Wes Moore (-240001) — Governor
-- UUID: 21e534c8-c0c0-42f5-b52b-5eb2f246d632
-- source: https://cdn.maryland.gov/maryland-cms/prod/governor/s3fs-public/styles/3_4_504x672_focal_point_webp/public/images/2026-04/gov%201st%20size.png.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -240001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/21e534c8-c0c0-42f5-b52b-5eb2f246d632-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -240001)
);

-- Aruna Miller (-240002) — Lieutenant Governor (D-01: standalone chamber)
-- UUID: ea9fc2d6-3b26-469a-978c-e8c846d2d49a
-- source: https://cdn.maryland.gov/maryland-cms/prod/governor/s3fs-public/styles/3_4_504x672_focal_point_webp/public/images/2026-04/lg%201st%20size.png.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -240002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ea9fc2d6-3b26-469a-978c-e8c846d2d49a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -240002)
);

-- Anthony G. Brown (-240003) — Attorney General
-- UUID: 60329719-1d5b-4bb4-8295-38ea18f6f378
-- source: https://oag.maryland.gov/our-office/PublishingImages/AttorneyGeneral.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -240003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/60329719-1d5b-4bb4-8295-38ea18f6f378-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -240003)
);

-- Brooke Lierman (-240004) — Comptroller
-- UUID: b26fb5d2-90eb-4108-8ce5-838df719473d
-- source: https://www.marylandcomptroller.gov/about/brooke-lierman/_jcr_content/root/container/heroContainer/hero.coreimg.png/1740686184941/comptroller-portrait-cropped.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -240004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b26fb5d2-90eb-4108-8ce5-838df719473d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -240004)
);

-- Dereck E. Davis (-240005) — State Treasurer (D-03: is_appointed_position=true)
-- UUID: 75378a96-8886-46eb-b0c1-37cbe2579265
-- source: https://upload.wikimedia.org/wikipedia/commons/c/cb/Dereck_E._Davis_4_23_2025_%2854473095147%29_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -240005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/75378a96-8886-46eb-b0c1-37cbe2579265-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -240005)
);
