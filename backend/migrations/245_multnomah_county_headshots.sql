-- Migration 245: Multnomah County Official Headshots
-- AUDIT-ONLY: captures the live politician_images INSERTs performed during Phase 83-02
-- execution on 2026-05-31.
-- DO NOT apply via Supabase ledger -- actual DB writes happened live via
-- scripts/_tmp-multnomah-headshots.py (Python PIL + Supabase Storage API).
-- This is AUDIT-ONLY in the same pattern as 225_or_headshots.sql, 200_sf_headshots.sql, etc.
--
-- 5 Multnomah County officials:
--   external_id -410001  — Jessica Vega Pederson (County Chair)
--   external_id -410010  — Meghan Moyer (Commissioner District 1)
--   external_id -410011  — Shannon Singleton (Commissioner District 2)
--   external_id -410012  — Julia Brim-Edwards (Commissioner District 3)
--   external_id -410013  — Vince Jones-Dixon (Commissioner District 4)
--
-- Sources: multco.us official profile pages (public domain — government portraits)
--   Primary URL pattern: https://multco.us/sites/default/files/styles/1_1_large/public/{date}/{filename}.jpg.webp
--   Fallback JPEG URLs (stripping /styles/1_1_large/) returned HTTP 404 on multco.us;
--   all 5 images sourced from primary WebP /styles/1_1_large/ Drupal style.
--
-- Photo processing: 330x330 square WebP source → center-crop 264x330 (4:5) → resize 600x750 Lanczos JPEG q90.
-- Storage bucket: politician_photos; path: {politician_id}-headshot.jpg.

-- ============================================================
-- MULTNOMAH COUNTY BOARD OF COMMISSIONERS (5 officials)
-- ============================================================

-- Jessica Vega Pederson (-410001) — County Chair
-- source: https://multco.us/sites/default/files/styles/1_1_large/public/2026-01/54a2249-edit-chair-8x10-1.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/27f6b552-0e36-429a-a6fd-bb7108b80b35-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410001)
);

-- Meghan Moyer (-410010) — Commissioner District 1
-- source: https://multco.us/sites/default/files/styles/1_1_large/public/2026-01/moyer-2026-portrait-a2_0.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bfaf8f7d-59f9-4747-925b-c546d84b58ad-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410010)
);

-- Shannon Singleton (-410011) — Commissioner District 2
-- source: https://multco.us/sites/default/files/styles/1_1_large/public/2024-12/20241202-commissioner-shannon-singleton-mn-04-4x3.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9c2b5568-9201-4d99-95e3-f2ecc1eaf2d3-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410011)
);

-- Julia Brim-Edwards (-410012) — Commissioner District 3
-- source: https://multco.us/sites/default/files/styles/1_1_large/public/2023-06/20230526-D3-Commissioner-Jullia-Brim-Edwards-MN-%252816x9%2529.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0e37f57f-ccdb-4a6c-90b9-8f5fd7410080-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410012)
);

-- Vince Jones-Dixon (-410013) — Commissioner District 4
-- source: https://multco.us/sites/default/files/styles/1_1_large/public/2024-12/20241217-commissioner-vince-jones-dixon-mn-4x6.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -410013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/28a723ed-300a-4ed6-8454-fca5bdb4ae4a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410013)
);
