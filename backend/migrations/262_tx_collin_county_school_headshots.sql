-- Migration 262: TX Collin County School Board Member Headshots
-- AUDIT-ONLY: captures the live politician_images INSERTs performed during Phase 88-02
-- execution on 2026-06-03.
-- DO NOT apply via Supabase ledger -- actual DB writes happened live via headshot upload script.
-- Pattern matches 258_ca_city_school_headshots.sql / 255_or_school_headshots.sql.
--
-- 35 officials documented across 5 ISDs:
--   Plano ISD      (7 officials, external_ids -880001..-880007) -- 7/7 photos found
--   McKinney ISD   (7 officials, external_ids -880008..-880014) -- 6/7 photos found (Roxane Morrison N/A)
--   Allen ISD      (7 officials, external_ids -880015..-880021) -- 0/7 no photos on official site
--   Frisco ISD     (7 officials, external_ids -880022..-880028) -- 7/7 photos found
--   Richardson ISD (7 officials, external_ids -880029..-880035) -- 7/7 photos found
--
-- Total uploaded: 27/35 officials
-- No photo: 7 Allen ISD (no photos on allenisd.org), 1 McKinney ISD (Roxane Morrison — no photo on official page)
--
-- Photo processing: crop to 4:5 ratio (center-crop wide / top-crop tall), then resize 600x750 Lanczos q90.
-- Storage bucket: politician_photos; path: {politician_id}-headshot.jpg.
-- politician_images.type = 'default' (UI filter: .find(img => img.type === 'default')).
--
-- Run: 2026-06-03

-- Safety guard: this file is AUDIT-ONLY. Abort if applied directly.
DO $$
BEGIN
  RAISE EXCEPTION 'Migration 262 is AUDIT-ONLY and must not be applied. Actual DB writes happened live via headshot upload during Phase 88-02.';
END $$;

-- ====================== PLANO ISD ======================
-- All 7 photos sourced from pisd.edu trustee profile pages (Finalsite CMS).
-- Profile pages: https://www.pisd.edu/about-our-district/board-of-trustees/trustee-profiles/[name]-profile
-- Images served from Finalsite CDN (resources.finalsite.net).

-- Dr. Lauren Tyra (-880001) — Board Member, Place 1
-- source: https://www.pisd.edu/about-our-district/board-of-trustees/trustee-profiles/dr-lauren-tyra-profile (Finalsite CDN)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880001)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880001)
);

-- Sam Johnson (-880002) — Board Member, Place 2
-- source: https://www.pisd.edu/about-our-district/board-of-trustees/trustee-profiles/sam-johnson-profile (Finalsite CDN)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880002)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880002)
);

-- Nancy Humphrey (-880003) — Board Member, Place 3
-- source: https://www.pisd.edu/about-our-district/board-of-trustees/trustee-profiles/nancy-humphrey-profile (Finalsite CDN)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880003)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880003)
);

-- Michael Cook (-880004) — Board Member, Place 4
-- source: https://www.pisd.edu/about-our-district/board-of-trustees/trustee-profiles/michael-cook-profile (Finalsite CDN)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880004)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880004)
);

-- Tarrah Lantz (-880005) — Board Member, Place 5
-- source: https://www.pisd.edu/about-our-district/board-of-trustees/trustee-profiles/tarrah-lantz-profile (Finalsite CDN)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880005)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880005)
);

-- Elisa Klein (-880006) — Board Member, Place 6
-- source: https://www.pisd.edu/about-our-district/board-of-trustees/trustee-profiles/elisa-klein-profile (Finalsite CDN)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880006)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880006)
);

-- Katherine Goodwin (-880007) — Board Member, Place 7
-- source: https://www.pisd.edu/about-our-district/board-of-trustees/trustee-profiles/katherine-goodwin-profile (Finalsite CDN)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880007)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880007)
);

-- ====================== McKINNEY ISD ======================
-- 6 of 7 photos sourced from mckinneyisd.net board page (Thrillshare CMS).
-- Roxane Morrison (Place 4): no photo found on official board page.

-- Harvey Oaxaca (-880008) — Board Member, Place 1
-- source: https://www.mckinneyisd.net/page/board-of-trustees (Thrillshare CMS)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880008)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880008)
);

-- Kenneth Ussery (-880009) — Board Member, Place 2
-- source: https://www.mckinneyisd.net/page/board-of-trustees (Thrillshare CMS)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880009)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880009)
);

-- Corey Homer (-880010) — Board Member, Place 3
-- source: https://www.mckinneyisd.net/page/board-of-trustees (Thrillshare CMS)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880010)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880010)
);

-- Roxane Morrison (-880011): No photo found on official ISD website.
-- URL checked: https://www.mckinneyisd.net/page/board-of-trustees

-- Lynn Sperry (-880012) — Board Member, Place 5
-- source: https://www.mckinneyisd.net/page/board-of-trustees (Thrillshare CMS)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880012)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880012)
);

-- Stephanie O'Dell (-880013) — Board Member, Place 6
-- source: https://www.mckinneyisd.net/page/board-of-trustees (Thrillshare CMS)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880013)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880013)
);

-- Amy Dankel (-880014) — Board Member, Place 7
-- source: https://www.mckinneyisd.net/page/board-of-trustees (Thrillshare CMS)
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880014)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880014)
);

-- ====================== ALLEN ISD ======================
-- No photos on official website.
-- allenisd.org/page/board-of-trustees confirmed to have no member photos (names and titles only).
-- All 7 Allen ISD officials have no politician_images rows.

-- Sarah Mitchell (-880015): No photo found on official ISD website.
-- URL checked: https://www.allenisd.org/page/board-of-trustees

-- Veronica Yost (-880016): No photo found on official ISD website.
-- URL checked: https://www.allenisd.org/page/board-of-trustees

-- John Holley (-880017): No photo found on official ISD website.
-- URL checked: https://www.allenisd.org/page/board-of-trustees

-- Becca Kinnear (-880018): No photo found on official ISD website.
-- URL checked: https://www.allenisd.org/page/board-of-trustees

-- Amanda Campbell (-880019): No photo found on official ISD website.
-- URL checked: https://www.allenisd.org/page/board-of-trustees

-- Dr. Polly Montgomery (-880020): No photo found on official ISD website.
-- URL checked: https://www.allenisd.org/page/board-of-trustees

-- Bill Parker (-880021): No photo found on official ISD website.
-- URL checked: https://www.allenisd.org/page/board-of-trustees

-- ====================== FRISCO ISD ======================
-- All 7 photos sourced from friscoisd.org board members page (SiteImprove/Finalsite CMS).
-- URL pattern: https://www.friscoisd.org/images/default-source/board-members/[lastname].jpg?sfvrsn=[version]
-- All 7 members confirmed present on meet-the-board page.

-- Suresh Manduva (-880022) — Board Member, Place 1
-- source: https://www.friscoisd.org/images/default-source/board-members/manduva.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880022),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880022)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880022)
);

-- Renee Sample (-880023) — Board Member, Place 2
-- source: https://www.friscoisd.org/images/default-source/board-members/sample.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880023),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880023)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880023)
);

-- Stephanie Elad (-880024) — Board Member, Place 3
-- source: https://www.friscoisd.org/images/default-source/board-members/elad.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880024),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880024)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880024)
);

-- Dynette Davis (-880025) — Board Member, Place 4
-- source: https://www.friscoisd.org/images/default-source/board-members/davis.jpg?sfvrsn=9697fd7_3
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880025),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880025)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880025)
);

-- Mark Hill (-880026) — Board Member, Place 5
-- source: https://www.friscoisd.org/images/default-source/board-members/hill.jpg?sfvrsn=43583c7e_2
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880026),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880026)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880026)
);

-- Sherrie Salas (-880027) — Board Member, Place 6
-- source: https://www.friscoisd.org/images/default-source/board-members/salas.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880027),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880027)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880027)
);

-- Keith Maddox (-880028) — Board Member, Place 7
-- source: https://www.friscoisd.org/images/default-source/board-members/maddox.jpg?sfvrsn=6d996ddc_5
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880028),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880028)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880028)
);

-- ====================== RICHARDSON ISD ======================
-- All 7 photos sourced from web.risd.org board pages (WordPress).
-- URL pattern: https://web.risd.org/board/wp-content/uploads/[FirstNameLastInitial].jpg
-- Note: Districts 1-5 use 'Board Member, District [N]'; At-Large 6-7 use 'Board Member, Place [N]'.

-- Megan Timme (-880029) — Board Member, District 1
-- source: https://web.risd.org/board/wp-content/uploads/MeganT.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880029),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880029)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880029)
);

-- Vanessa Pacheco (-880030) — Board Member, District 2
-- source: https://web.risd.org/board/wp-content/uploads/VanessaP.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880030),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880030)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880030)
);

-- Debbie Rentería (-880031) — Board Member, District 3
-- source: https://web.risd.org/board/wp-content/uploads/DebbieR.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880031),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880031)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880031)
);

-- Regina Harris (-880032) — Board Member, District 4
-- source: https://web.risd.org/board/wp-content/uploads/ReginaH.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880032),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880032)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880032)
);

-- Rachel McGowan (-880033) — Board Member, District 5
-- source: https://web.risd.org/board/wp-content/uploads/RachelM-1.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880033),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880033)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880033)
);

-- Eric Eager (-880034) — Board Member, Place 6
-- source: https://web.risd.org/board/wp-content/uploads/EricE.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880034),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880034)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880034)
);

-- Chris Poteet (-880035) — Board Member, Place 7
-- source: https://web.risd.org/board/wp-content/uploads/ChrisP.jpg
-- original: JPEG portrait (crop to 4:5, resize 600x750 Lanczos q90)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -880035),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -880035)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -880035)
);

-- =============== SUMMARY ===============
-- Total officials: 35
-- Headshots uploaded: 27
--   Plano ISD:      7/7 (pisd.edu Finalsite CMS, individual trustee profile pages)
--   McKinney ISD:   6/7 (mckinneyisd.net Thrillshare CMS; Roxane Morrison Place 4 has no photo on official page)
--   Allen ISD:      0/7 (no photos on allenisd.org board page)
--   Frisco ISD:     7/7 (friscoisd.org; URL pattern: /images/default-source/board-members/[lastname].jpg)
--   Richardson ISD: 7/7 (web.risd.org WordPress; URL pattern: /board/wp-content/uploads/[FirstNameLastInitial].jpg)
-- No photo: 8 officials (7 Allen ISD + 1 McKinney ISD Roxane Morrison)
-- Live DB verified: SELECT COUNT(*) FROM essentials.politician_images pi
--   JOIN essentials.politicians p ON p.id = pi.politician_id
--   WHERE p.external_id BETWEEN -880035 AND -880001
--   AND pi.type = 'default'
-- Result: 27
-- =====================================
