-- Migration 255: OR School District Board Member Headshots
-- AUDIT-ONLY: captures the live politician_images INSERTs performed during Phase 86-02
-- execution on 2026-06-01.
-- DO NOT apply via Supabase ledger -- actual DB writes happened live via
-- scripts/_tmp-or-school-headshots.py (Python PIL + Supabase Storage API).
-- Pattern matches 247_multnomah_cities_headshots.sql / 245_multnomah_county_headshots.sql.
--
-- 38 officials documented across 6 districts:
--   PORTLAND PUBLIC SCHOOLS (7 officials, external_ids -860001..-860007)
--   PARKROSE (5 officials, external_ids -860011..-860015)
--   REYNOLDS (7 officials, external_ids -860021..-860027)
--   CENTENNIAL (7 officials, external_ids -860031..-860037)
--   DAVID DOUGLAS (7 officials, external_ids -860041..-860047)
--   RIVERDALE (5 officials, external_ids -860051..-860055)
--
-- Photo processing: crop to 4:5 first, then resize 600x750 Lanczos q90.
-- Storage bucket: politician_photos; path: {politician_id}-headshot.jpg.
-- politician_images.type = 'default' (UI filter: .find(img => img.type === 'default')).
--
-- Migration number discrepancy: RESEARCH.md and CONTEXT.md referenced "migration 254"
-- for headshots. Plan 01 used 254 (253_fix_ca_legislature_orphan_context_rows.sql was
-- already taken, bumping seed to 254). This headshots audit migration is therefore 255.
--
-- All 38/38 board members uploaded successfully (0 documented gaps).
-- Run: 2026-06-01

-- Safety guard: this file is AUDIT-ONLY. Abort if applied directly.
DO $$
BEGIN
  RAISE EXCEPTION 'Migration 255 is AUDIT-ONLY and must not be applied. Actual DB writes happened live via scripts/_tmp-or-school-headshots.py.';
END $$;

-- ====================== PORTLAND PUBLIC SCHOOLS (PPS) ======================

-- Edward Wang (-860001) — Board Member (Zone 7), Chair
-- source: https://ppsnet.finalsite.com/fs/resource-manager/view/5d026714-5d57-4225-b3a0-e7d067cbbbe9
-- original: 375x500 WebP (4:5 ratio after top-crop 375x468, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860001)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860001)
);

-- Michelle DePass (-860002) — Board Member (Zone 2), Vice-Chair
-- source: https://ppsnet.finalsite.com/fs/resource-manager/view/b829e8be-7795-430e-8db8-847b17768da3
-- original: 375x500 WebP (top-crop 375x468, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860002)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860002)
);

-- Christy Splitt (-860003) — Board Member (Zone 1)
-- source: https://ppsnet.finalsite.com/fs/resource-manager/view/234d98ce-926d-4f30-a3e9-34c0af846c5a
-- original: 375x500 WebP (top-crop 375x468, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860003)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860003)
);

-- Patte Sullivan (-860004) — Board Member (Zone 3)
-- source: https://ppsnet.finalsite.com/fs/resource-manager/view/8c104d6e-dcaf-4bb2-8c30-45b23c95506a
-- original: 375x500 WebP (top-crop 375x468, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860004)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860004)
);

-- Rashelle Chase-Miller (-860005) — Board Member (Zone 4)
-- source: https://ppsnet.finalsite.com/fs/resource-manager/view/ec5c3590-e78c-42d7-b439-9a7db96fbb5e
-- original: 375x500 WebP (top-crop 375x468, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860005)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860005)
);

-- Virginia La Forte (-860006) — Board Member (Zone 5)
-- source: https://ppsnet.finalsite.com/fs/resource-manager/view/d9272c7d-e554-4902-bd43-08da1a04fdf9
-- original: 375x500 WebP (top-crop 375x468, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860006)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860006)
);

-- Stephanie Engelsman (-860007) — Board Member (Zone 6)
-- source: https://ppsnet.finalsite.com/fs/resource-manager/view/95fba4d1-6618-47f1-b3a4-2580dfea8221
-- original: 375x500 WebP (top-crop 375x468, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860007)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860007)
);

-- ====================== PARKROSE ======================

-- Paul Tabron Jr. (-860011) — Board Member (Position 1), Chair
-- source: https://www.parkrose.com/images/about/school_board/paul-web.jpg
-- original: 1024x768 JPEG landscape (center-crop 614x768, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860011)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860011)
);

-- Brenda Rivas (-860012) — Board Member (Position 2), Vice-Chair
-- source: https://www.parkrose.com/images/about/school_board/brenda.jpg
-- original: 1024x768 JPEG landscape (center-crop 614x768, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860012)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860012)
);

-- Joash Bullock (-860013) — Board Member (Position 3)
-- source: https://www.parkrose.com/images/about/school_board/joash-bullock.jpg
-- original: 1024x768 JPEG landscape (center-crop 614x768, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860013)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860013)
);

-- Adolfo Jimenez (-860014) — Board Member (Position 4)
-- source: https://www.parkrose.com/images/about/school_board/adolfo-jimenez.jpg
-- original: 1024x768 JPEG landscape (center-crop 614x768, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860014)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860014)
);

-- Mariah Galaviz (-860015) — Board Member (Position 5)
-- source: https://www.parkrose.com/images/about/school_board/mariah.jpg
-- original: 1024x768 JPEG landscape (center-crop 614x768, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860015),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860015)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860015)
);

-- ====================== REYNOLDS ======================
-- All Reynolds photos sourced from per-member profile pages with Drupal itok tokens.
-- Source: https://www.reynolds.k12.or.us/schoolboard/{member-slug}

-- Aaron Muñoz (-860021) — Board Member (Position 1)
-- source: https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/53775/aaron.png?itok=gc8gKxir
-- original: 500x498 PNG near-square (center-crop 398x498, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860021),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860021)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860021)
);

-- Joyce Rosenau (-860022) — Board Member (Position 2), Vice-Chair
-- source: https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/69022/joyce.png?itok=-AC0wI1w
-- original: 500x498 PNG near-square (center-crop 398x498, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860022),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860022)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860022)
);

-- Michael Reyes (-860023) — Board Member (Position 3), Chair
-- source: https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/53783/michael.png?itok=ZrKNrFMD
-- original: 500x498 PNG near-square (center-crop 398x498, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860023),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860023)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860023)
);

-- Cayle Tern (-860024) — Board Member (Position 4)
-- source: https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/53779/cayle.png?itok=umD8fUNi
-- original: 500x498 PNG near-square (center-crop 398x498, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860024),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860024)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860024)
);

-- Patty Carrera (-860025) — Board Member (Position 5)
-- source: https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/1844/patty.png?itok=iZHI5YhF
-- original: 500x498 PNG near-square (center-crop 398x498, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860025),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860025)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860025)
);

-- Ana Gonzalez Muñoz (-860026) — Board Member (Position 6)
-- source: https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/32631/ana.png?itok=T4LCbGIE
-- original: 500x498 PNG near-square (center-crop 398x498, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860026),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860026)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860026)
);

-- Francisco Ibarra (-860027) — Board Member (Position 7)
-- source: https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/66219/francisco.png?itok=Af7aHLtS
-- original: 500x498 PNG near-square (center-crop 398x498, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860027),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860027)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860027)
);

-- ====================== CENTENNIAL ======================
-- All Centennial photos sourced from https://csd28j.org/boardmembers (ParentSquare/SmartSites CMS)
-- CDN: https://files.smartsites.parentsquare.com/3490/{filename}

-- David Linn (-860031) — Board Member (Position 1)
-- source: https://files.smartsites.parentsquare.com/3490/img_pd_123745_ogjxu5.png
-- original: 1800x2250 PNG portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860031),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860031)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860031)
);

-- Ronald Hardin (-860032) — Board Member (Position 2)
-- source: https://files.smartsites.parentsquare.com/3490/img_pd_123745_ovdfak.png
-- original: 1800x2250 PNG portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860032),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860032)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860032)
);

-- Will Mohring (-860033) — Board Member (Position 3), Vice-Chair
-- source: https://files.smartsites.parentsquare.com/3490/Will Mohring P6 At-Large (1)_1752530741.png
-- original: 1200x1500 PNG portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860033),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860033)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860033)
);

-- Melissa Standley (-860034) — Board Member (Position 4)
-- source: https://files.smartsites.parentsquare.com/3490/img_pd_123745_kaakwr.png
-- original: 1800x2250 PNG portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860034),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860034)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860034)
);

-- Rose Solowski (-860035) — Board Member (Position 5), Chair
-- source: https://files.smartsites.parentsquare.com/3490/img_pd_123745_ybmchp.png
-- original: 1800x2250 PNG portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860035),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860035)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860035)
);

-- Michael Newman (-860036) — Board Member (Position 6)
-- source: https://files.smartsites.parentsquare.com/3490/Michael Newman P6 At-Large (1)_1752531598.png
-- original: 1200x1500 PNG portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860036),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860036)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860036)
);

-- Pam Shields (-860037) — Board Member (Position 7)
-- source: https://files.smartsites.parentsquare.com/3490/img_pd_123745_zdv1ht.png
-- original: 1800x2250 PNG portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860037),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860037)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860037)
);

-- ====================== DAVID DOUGLAS ======================
-- All David Douglas photos sourced from https://www.ddouglas.k12.or.us/school-board/board-members/
-- (WordPress self-hosted; some URLs are http:// — requests follows redirect to https)

-- Althea Ender (-860041) — Board Member (Position 1)
-- source: http://www.ddouglas.k12.or.us/wp-content/uploads/2026/02/Althea-Ender-scaled.jpg
-- original: 1707x2560 JPEG tall portrait (top-crop 1707x2133 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860041),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860041)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860041)
);

-- Stephanie Stephens (-860042) — Board Member (Position 2)
-- source: http://www.ddouglas.k12.or.us/wp-content/uploads/2014/06/Stephanie-Stephens-2017-683x1024.jpg
-- original: 683x1024 JPEG tall portrait (top-crop 683x853 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860042),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860042)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860042)
);

-- Sara Epstein (-860043) — Board Member (Position 3)
-- source: https://www.ddouglas.k12.or.us/wp-content/uploads/2025/07/Sara-Ruth-Epstein-Picture-edited.jpg
-- original: 447x671 JPEG tall portrait (top-crop 447x558 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860043),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860043)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860043)
);

-- Muriel Jordan (-860044) — Board Member (Position 4)
-- source: https://www.ddouglas.k12.or.us/wp-content/uploads/2025/09/Muriel-Jordan-edited-2-scaled.jpg
-- original: 1707x2560 JPEG tall portrait (top-crop 1707x2133 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860044),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860044)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860044)
);

-- Thomas Stephenson (-860045) — Board Member (Position 5)
-- source: https://www.ddouglas.k12.or.us/wp-content/uploads/2025/07/Thomas-Stephenson-edited-683x1024.png
-- original: 683x1024 PNG tall portrait (top-crop 683x853 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860045),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860045)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860045)
);

-- Heather Franklin (-860046) — Board Member (Position 6), Board Chair
-- source: http://www.ddouglas.k12.or.us/wp-content/uploads/2022/08/Heather-Franklin_683x1024-crop-2-683x1024.png
-- original: 683x1024 PNG tall portrait (top-crop 683x853 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860046),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860046)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860046)
);

-- José Gamero-Georgeson (-860047) — Board Member (Position 7), Vice-Chair
-- source: https://www.ddouglas.k12.or.us/wp-content/uploads/2024/12/Jose-Gamero-Georgeson_headshot-2.png
-- original: 1024x1536 PNG tall portrait (top-crop 1024x1280 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860047),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860047)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860047)
);

-- ====================== RIVERDALE ======================
-- All Riverdale photos sourced from https://www.riverdaleschool.com/about-us/school-board-policy
-- Finalsite CMS; direct CDN URLs extracted from img data-image-sizes attributes (resources.finalsite.net).

-- Shaina Weinstein (-860051) — Board Member (Seat 1), Vice-Chair
-- source: https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1734406260/riverdalek12orus/rp9b3bblxbqtq5hklire/ShainaWeinsteinHeadshot.jpg
-- original: 256x346 WebP portrait (top-crop 256x320 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860051),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860051)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860051)
);

-- Mina Stricklin (-860052) — Board Member (Seat 2), Chair
-- source: https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1686937338/riverdalek12orus/f6qecratmahpa7xtdgtk/MinaStricklin.jpg
-- original: 256x341 WebP portrait (top-crop 256x320 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860052),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860052)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860052)
);

-- Michele Rosenbaum (-860053) — Board Member (Seat 3), Director
-- source: https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1670002047/riverdalek12orus/fqhcryczbw8iibp7h9j4/MicheleRosenbaum.png
-- original: 256x320 WebP portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860053),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860053)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860053)
);

-- Ali Lanenga (-860054) — Board Member (Seat 4), Director
-- source: https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1752528365/riverdalek12orus/rtj34pqwy2v45xtuj3ff/AliLanengaPortrait.jpg
-- original: 256x320 WebP portrait (already 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860054),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860054)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860054)
);

-- Milessa Lowrie (-860055) — Board Member (Seat 5), Director
-- source: https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1752528078/riverdalek12orus/fovh1trcg6hv8m8jmr6s/MilessaLowrieHeadshot_1.jpg
-- original: 256x205 WebP landscape (center-crop 164x205 → 4:5, resize 600x750)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -860055),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
         (SELECT id FROM essentials.politicians WHERE external_id = -860055)::text || '-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -860055)
);

-- =============== SUMMARY ===============
-- Total officials: 38
-- Headshots uploaded: 38 (PPS 7, Parkrose 5, Reynolds 7, Centennial 7, David Douglas 7, Riverdale 5)
-- No photo documented: 0
-- All 38/38 board members had official website photos available.
-- Live DB verified: SELECT COUNT(*) FROM essentials.politician_images pi
--   JOIN essentials.politicians p ON p.id = pi.politician_id
--   WHERE p.external_id BETWEEN -860055 AND -860001
--   AND pi.type = 'default'
-- Result: 38
-- =====================================
