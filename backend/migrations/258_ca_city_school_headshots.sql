-- Migration 258: CA City School Board Member Headshots
-- AUDIT-ONLY: captures the live politician_images INSERTs performed during Phase 87-02
-- execution on 2026-06-02.
-- DO NOT apply via Supabase ledger -- actual DB writes happened live via
-- scripts/_tmp-ca-school-headshots.py (Python PIL + direct psql).
-- Pattern matches 255_or_school_headshots.sql / 247_multnomah_cities_headshots.sql.
--
-- 34 officials documented across 6 districts:
--   SFUSD  (7 officials, external_ids -870001..-870007) — 7/7 photos found
--   SDUSD  (5 officials, external_ids -870008..-870012) — 4/5 photos found (Whitehurst-Payne N/A)
--   SCUSD  (7 officials, external_ids -870013..-870019) — 7/7 photos found
--   SJUSD  (5 officials, external_ids -870020..-870024) — 0/5 no photos on official site
--   FUSD   (5 officials, external_ids -870025..-870029) — 5/5 photos found
--   BUSD   (5 officials, external_ids -870030..-870034) — 5/5 photos found
--
-- Total uploaded: 28/34 officials
-- No photo: 5 SJUSD (no photos on sjusd.org), 1 SDUSD (Whitehurst-Payne — Cloudflare-blocked)
--
-- Photo processing: crop to 4:5 ratio (center-crop wide / top-crop tall), then resize 600x750 Lanczos q90.
-- Storage bucket: politician_photos; path: {politician_id}-headshot.jpg.
-- politician_images.type = 'default' (UI filter: .find(img => img.type === 'default')).
--
-- Run: 2026-06-02

-- Safety guard: this file is AUDIT-ONLY. Abort if applied directly.
DO $$
BEGIN
  RAISE EXCEPTION 'Migration 258 is AUDIT-ONLY and must not be applied. Actual DB writes happened live via scripts/_tmp-ca-school-headshots.py.';
END $$;

-- ====================== SAN FRANCISCO UNIFIED (SFUSD) ======================
-- All 7 photos sourced from sfusd.edu/about-sfusd/board-education (Drupal CMS)
-- Images are black-and-white headshots on individual commissioner pages.

-- Phil Kim (-870001) — Commissioner, Board President
-- source: https://www.sfusd.edu/sites/default/files/styles/max_635/public/2025-01/Phil%20Kim%20B%26W.jpg?itok=EUZO8Wq_
-- original: 635x953 JPEG portrait (top-crop 635x793 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870001)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870001)
);

-- Jaime Huling (-870002) — Commissioner, Board Vice President
-- source: https://www.sfusd.edu/sites/default/files/styles/max_635/public/2025-01/Jaime%20Huling%20B%26W.jpg?itok=ik27of31
-- original: 635x953 JPEG portrait (top-crop 635x793 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870002)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870002)
);

-- Matt Alexander (-870003) — Commissioner
-- source: https://www.sfusd.edu/sites/default/files/styles/max_635/public/Matt%20Alexander%20-%20Headshot_%203.jpg?itok=0SftV0wW
-- original: 635x954 JPEG portrait (top-crop 635x793 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870003)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870003)
);

-- Alida Fisher (-870004) — Commissioner
-- source: https://www.sfusd.edu/sites/default/files/styles/max_635/public/2023-01/Alida%20bw%202.jpg?itok=0EVJMR-l
-- original: 635x637 JPEG near-square (top-crop 635x793 exceeds height -> center-crop 508x637 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870004)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870004)
);

-- Parag Gupta (-870005) — Commissioner
-- source: https://www.sfusd.edu/sites/default/files/styles/max_635/public/2025-01/Parag%20Gupta%20B%26W.jpg?itok=W2YaVrR3
-- original: 635x953 JPEG portrait (top-crop 635x793 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870005)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870005)
);

-- Supryia Ray (-870006) — Commissioner
-- source: https://www.sfusd.edu/sites/default/files/styles/max_635/public/2025-01/Supryia%20Ray%20headshot%20B%26W.jpg?itok=vUF8d72u
-- original: 635x953 JPEG portrait (top-crop 635x793 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870006)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870006)
);

-- Lisa Weissman-Ward (-870007) — Commissioner
-- source: https://www.sfusd.edu/sites/default/files/styles/max_635/public/2022-05/Lisa_BW.jpeg?itok=UNsNi4tK
-- original: 635x620 JPEG near-square (center-crop 496x620 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870007)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870007)
);

-- ====================== SAN DIEGO UNIFIED (SDUSD) ======================
-- Photos sourced from sandiegounified.org -> sharpschool CDN
-- Site is Cloudflare-protected; individual bio pages inaccessible via automation.
-- Confirmed image URLs extracted from research document (3 pre-confirmed + 1 via redirect test).
-- Sharon Whitehurst-Payne (-870012): no URL found via automated discovery — no photo row.

-- Sabrina Bazzo (-870008) — Board Member (District A), Vice President
-- source: https://cdnsm5-ss18.sharpschool.com/UserFiles/Servers/Server_27732394/Image/%20About/Board%20of%20Edu/Sabrina%20Bazzo%20official%20photo.jpg
-- original: 778x900 JPEG portrait (center-crop 720x900 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870008)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870008)
);

-- Shana Hazan (-870009) — Board Member (District B)
-- source: https://cdnsm5-ss18.sharpschool.com/UserFiles/Servers/Server_27732394/Image/%20About/Board%20of%20Edu/Shana%20Hazan%20Head%20Shot%20V2.jpg
-- original: 1293x1500 JPEG portrait (center-crop 1200x1500 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870009)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870009)
);

-- Cody Petterson (-870010) — Board Member (District C)
-- source: https://cdnsm5-ss18.sharpschool.com/UserFiles/Servers/Server_27732394/Image/%20About/Board%20of%20Edu/Cody%20Petterson.jpg
-- original: 998x1153 JPEG portrait (top-crop 998x1247 exceeds height -> center-crop 922x1153 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870010)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870010)
);

-- Richard Barrera (-870011) — Board Member (District D), Board President
-- source: https://www.sandiegounified.org/UserFiles/Servers/Server_27732394/Image/%20About/Board%20of%20Edu/Richard%20NEW%202020-21.jpg
-- (redirects to cdnsm5-ss18.sharpschool.com)
-- original: 851x1280 JPEG portrait (top-crop 851x1063 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870011)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870011)
);

-- Sharon Whitehurst-Payne (-870012) — Board Member (District E)
-- No photo found on official district website. sandiegounified.org is Cloudflare-protected;
-- automated URL discovery was not possible. No politician_images row inserted.
-- Future plan: manual browser visit to sandiegounified.org/about/board_of_education/overview/sharon_whitehurst-payne

-- ====================== SACRAMENTO CITY UNIFIED (SCUSD) ======================
-- All 7 photos sourced from scusd.edu/about/board-of-education (Finalsite CMS)
-- Image URLs extracted from data-image-sizes attributes on the board page.

-- Tara Jeane (-870013) — Board Member (Area 1), Board President
-- source: https://resources.finalsite.net/images/f_auto,q_auto/v1752791745/scusdedu/sksvju79a67qu49jjnco/jeane1.png
-- original: 728x761 PNG portrait (top-crop 728x910 exceeds height -> center-crop 608x761 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870013)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870013)
);

-- Jasjit Singh (-870014) — Board Member (Area 2)
-- source: https://resources.finalsite.net/images/f_auto,q_auto/v1752791344/scusdedu/qzfhkawj2dolcm6eddwb/singh1.png
-- original: 728x756 PNG portrait (center-crop 604x756 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870014)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870014)
);

-- Jose M. Navarro (-870015) — Board Member (Area 3)
-- source: https://resources.finalsite.net/images/f_auto,q_auto/v1752792366/scusdedu/xjez6fqoedzzi197aeyi/navarro.png
-- original: 728x757 PNG portrait (center-crop 605x757 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870015),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870015)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870015)
);

-- April K. Ybarra (-870016) — Board Member (Area 4), 2nd Vice President
-- source: https://resources.finalsite.net/images/f_auto,q_auto/v1752792669/scusdedu/vumecisyrtglkl9atesh/ybarra.png
-- original: 730x756 PNG portrait (center-crop 604x756 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870016),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870016)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870016)
);

-- Chinua Rhodes (-870017) — Board Member (Area 5)
-- source: https://resources.finalsite.net/images/f_auto,q_auto/v1752792006/scusdedu/vrywfan1apzfqnacaq4v/rhodes.png
-- original: 731x760 PNG portrait (center-crop 608x760 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870017),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870017)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870017)
);

-- Taylor Kayatta (-870018) — Board Member (Area 6), 1st Vice President
-- source: https://resources.finalsite.net/images/f_auto,q_auto/v1752793725/scusdedu/hzojfcvvwnpefoktu6sz/kayatta.png
-- original: 730x760 PNG portrait (center-crop 608x760 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870018),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870018)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870018)
);

-- Michael Benjamin (-870019) — Board Member (Area 7)
-- source: https://resources.finalsite.net/images/f_auto,q_auto/v1752793933/scusdedu/xvqvvubib1usdpwko3h3/benjamin.png
-- original: 489x620 PNG portrait (center-crop 392x490 -> 4:5 approx -> resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870019),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870019)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870019)
);

-- ====================== SAN JOSE UNIFIED (SJUSD) ======================
-- No photos on official website.
-- sjusd.org/about/board-of-education confirmed to have no photos (names and titles only).
-- web.sjusd.org subdomain returned ECONNREFUSED during research.
-- All 5 SJUSD officials have no politician_images rows.

-- Teresa Castellanos (-870020): No photo found on official district website.
-- Jose Magana (-870021): No photo found on official district website.
-- Carla Collins (-870022): No photo found on official district website.
-- Brian Wheatley (-870023): No photo found on official district website.
-- Nicole Gribstad (-870024): No photo found on official district website.

-- ====================== FREMONT UNIFIED (FUSD) ======================
-- All 5 photos sourced from fremontunified.org (WordPress media library).
-- Direct image URLs confirmed by user on 2026-06-02.

-- Sharon Coco (-870025) — Board Member (Area 1), Vice President
-- source: https://fremontunified.org/wp-content/uploads/2023/05/sharon-coco.jpeg
-- original: JPEG portrait (crop to 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870025),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870025)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870025)
);

-- Larry Sweeney (-870026) — Board Member (Area 2)
-- source: https://fremontunified.org/wp-content/uploads/2023/06/l-sweeney.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870026),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870026)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870026)
);

-- Dianne Jones (-870027) — Board Member (Area 3), President
-- source: https://fremontunified.org/wp-content/uploads/2023/07/Dianne-Jones-240x300-1.jpg
-- original: 240x300 JPEG portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870027),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870027)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870027)
);

-- Rinu Nair (-870028) — Board Member (Area 4)
-- source: https://fremontunified.org/wp-content/uploads/2024/12/Rinu-Nair-.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870028),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870028)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870028)
);

-- Vivek Prasad (-870029) — Board Member (Area 5), Clerk
-- source: https://fremontunified.org/wp-content/uploads/2023/05/vivek-prasad.jpeg
-- original: JPEG portrait (crop to 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870029),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870029)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870029)
);

-- ====================== BERKELEY UNIFIED (BUSD) ======================
-- All 5 photos sourced from berkeleyschools.net/schoolboard/ (WordPress media library)
-- Name-to-photo mapping verified from alt text and adjacent name text on page.

-- Mike Chang (-870030) — Board Member, President (2026)
-- source: https://www.berkeleyschools.net/wp-content/uploads/2022/12/Screen-Shot-2022-12-15-at-9.09.01-AM.png
-- original: 188x208 PNG portrait (center-crop 166x208 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870030),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870030)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870030)
);

-- Jennifer Corn (-870031) — Board Member, Vice President (2028)
-- source: https://www.berkeleyschools.net/wp-content/uploads/2024/12/2024-Jen-Headshots-250-1.jpg
-- original: 1003x1440 JPEG portrait (top-crop 1003x1253 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870031),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870031)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870031)
);

-- Ka'Dijah Brown (-870032) — Director (2026)
-- source: https://www.berkeleyschools.net/wp-content/uploads/2018/12/KaDijah-320x342.jpg
-- original: 320x342 JPEG portrait (top-crop 320x400 exceeds height -> center-crop 273x342 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870032),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870032)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870032)
);

-- Ana Vasudeo (-870033) — Director (2028)
-- source: https://www.berkeleyschools.net/wp-content/uploads/2025/01/DSC1433-2-scaled.jpg
-- original: 2560x1707 JPEG landscape (center-crop 1365x1707 -> 4:5 portrait -> resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870033),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870033)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870033)
);

-- Jennifer Shanoski (-870034) — Director/Clerk (2026)
-- source: https://www.berkeleyschools.net/wp-content/uploads/2022/12/Screen-Shot-2022-12-15-at-9.16.22-AM.png
-- original: 500x536 PNG portrait (RGBA -> RGB, center-crop 428x536 -> 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -870034),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -870034)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -870034)
);

-- =============== SUMMARY ===============
-- Total officials: 34
-- Headshots uploaded: 28
--   SFUSD: 7/7 (sfusd.edu Drupal CMS)
--   SDUSD: 4/5 (sharpschool CDN; Whitehurst-Payne photo URL not found via automation)
--   SCUSD: 7/7 (resources.finalsite.net Finalsite CDN)
--   SJUSD: 0/5 (no photos on sjusd.org)
--   FUSD:  5/5 (fremontunified.org WordPress media; URLs confirmed by user 2026-06-02)
--   BUSD:  5/5 (berkeleyschools.net WordPress media)
-- No photo: 6 officials (5 SJUSD + 1 SDUSD Whitehurst-Payne)
-- Live DB verified: SELECT COUNT(*) FROM essentials.politician_images pi
--   JOIN essentials.politicians p ON p.id = pi.politician_id
--   WHERE p.external_id BETWEEN -870034 AND -870001
--   AND pi.type = 'default'
-- Result: 28
-- =====================================
