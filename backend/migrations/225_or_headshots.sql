-- Migration 225: OR Official Headshots
-- AUDIT-ONLY: captures the live politician_images INSERTs performed during Phase 74-03
-- execution on 2026-05-29.
-- DO NOT apply via Supabase ledger -- actual DB writes happened live via psql + Supabase Storage API.
-- Next applied migration number remains 225 for the next non-audit migration (Phase 75 or similar).
-- This is AUDIT-ONLY in the same pattern as 200_sf_headshots.sql, 209_sd_headshots.sql,
-- 212_fremont_headshots.sql, 215_berkeley_headshots.sql.
--
-- 13 OR officials:
--   external_ids -4100001..-4100005 (5 OR constitutional officers)
--   external_ids -4101001..-4101002 (2 OR US Senators)
--   external_ids -4102001..-4102006 (6 OR US House representatives)
--
-- Sources:
--   Executives + Senators: sos.oregon.gov Blue Book (public domain — state government portraits)
--   Rayfield: doj.state.or.us (public domain — DOJ official portrait)
--   House reps: unitedstates/images GitHub gh-pages (public domain)
--
-- Notes:
--   sos.oregon.gov: No 403 encountered; HTTP 200 with browser User-Agent + Referer headers.
--   Val Hoyle (H001094.jpg): pre-verified present at unitedstates/images before download.
--   All images processed: crop to 4:5 from top, resize to 600x750 Lanczos q90.
--   Storage bucket: politician_photos; path: {politician_id}-headshot.jpg.

BEGIN;

-- ============================================================
-- OR CONSTITUTIONAL OFFICERS (5)
-- ============================================================

-- Kotek (-4100001) — source: https://sos.oregon.gov/blue-book/PublishingImages/Kotek.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/66c3bd97-94d1-4287-b1b8-86605a38cb97-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100001)
);

-- Rayfield (-4100002) — source: https://doj.state.or.us/wp-content/uploads/2024/12/Rayfield_400x600x96_4-17x6-25.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/15dbbf1b-da3d-4fb9-8fc5-67b734e7979e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100002)
);

-- Read (-4100003) — source: https://sos.oregon.gov/blue-book/PublishingImages/state/executive/SOSTobiasRead.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/94105ea6-e6f7-4629-b30c-a8fe713e1cad-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100003)
);

-- Steiner (-4100004) — source: https://sos.oregon.gov/blue-book/PublishingImages/state/executive/TreasurerElizabethSteiner.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c712d9cb-6a42-4fc6-b025-67cd5064605f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100004)
);

-- Stephenson (-4100005) — source: https://sos.oregon.gov/blue-book/PublishingImages/StephensonC_Web.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8548989d-ff40-4b25-bb42-e1a7cbb03c88-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100005)
);

-- ============================================================
-- OR US SENATORS (2)
-- ============================================================

-- Wyden (-4101001) — source: https://sos.oregon.gov/blue-book/PublishingImages/national/senator-wydenr1.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4101001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2147281e-e1b1-4416-a5d9-dae9d4f31be0-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101001)
);

-- Merkley (-4101002) — source: https://sos.oregon.gov/blue-book/PublishingImages/national/senator-merkleyj1.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4101002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0eabc969-c1a1-47b7-8d34-6113b723a170-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101002)
);

-- ============================================================
-- OR US HOUSE REPRESENTATIVES (6)
-- ============================================================

-- Bonamici (-4102001, CD-01) — source: https://raw.githubusercontent.com/unitedstates/images/gh-pages/congress/original/B001278.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4102001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6ffb9093-7489-4197-aebc-67065c239fc3-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4102001)
);

-- Bentz (-4102002, CD-02) — source: https://raw.githubusercontent.com/unitedstates/images/gh-pages/congress/original/B000668.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4102002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fb00c887-11f5-46f2-b822-f9848368bbd2-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4102002)
);

-- Dexter (-4102003, CD-03) — source: https://raw.githubusercontent.com/unitedstates/images/gh-pages/congress/original/D000635.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4102003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/13dcf1a8-c0bf-4e2f-92aa-46637182b42a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4102003)
);

-- Hoyle (-4102004, CD-04) — source: https://raw.githubusercontent.com/unitedstates/images/gh-pages/congress/original/H001094.jpg
-- Note: Val Hoyle's H001094.jpg was pre-verified present before download (assumption A1 confirmed).
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4102004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f6202cef-4e46-4db5-a9c0-c69ac9a8eccd-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4102004)
);

-- Bynum (-4102005, CD-05) — source: https://raw.githubusercontent.com/unitedstates/images/gh-pages/congress/original/B001326.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4102005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7aad2a83-2f05-4570-aa7a-eb7a8c602ebd-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4102005)
);

-- Salinas (-4102006, CD-06) — source: https://raw.githubusercontent.com/unitedstates/images/gh-pages/congress/original/S001226.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4102006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5f6c498b-87dd-48fe-b744-62c8dced2ac3-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4102006)
);

COMMIT;
