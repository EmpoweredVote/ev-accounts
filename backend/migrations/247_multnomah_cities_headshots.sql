-- Migration 247: Multnomah Smaller Cities Official Headshots
-- AUDIT-ONLY: captures the live politician_images INSERTs performed during Phase 84-02
-- execution on 2026-06-01.
-- DO NOT apply via Supabase ledger -- actual DB writes happened live via
-- scripts/_tmp-cities-headshots.py (Python PIL + Supabase Storage API) plus
-- targeted fix inserts for Ripma, Carol Allen, Patricia Smith, and Rios-Campos URL correction.
-- Pattern matches 245_multnomah_county_headshots.sql / 225_or_headshots.sql.
--
-- 31 officials documented across 5 cities:
--   GRESHAM (7 officials, external_ids -4131251..-4131257): all have photos on greshamoregon.gov
--   TROUTDALE (7 officials, external_ids -4174851..-4174857): photos on troutdaleoregon.gov (WebP)
--   FAIRVIEW (7 officials, external_ids -4124251..-4124257): no photos on official site
--   WOOD VILLAGE (5 officials, external_ids -4183951..-4183955): photos on woodvillageor.gov
--   MAYWOOD PARK (5 officials, external_ids -4146731..-4146735): no photos on official site
--
-- Photo processing: crop 4:5 first, resize 600x750 Lanczos q90.
-- Storage bucket: politician_photos; path: {politician_id}-headshot.jpg.
-- Note: Gresham thumbnails served as WebP from /globalassets/ CDN despite .jpg extension.
--   All other sources: Troutdale = WebP; Wood Village = JPEG/PNG.

-- ============================================================
-- GRESHAM (7 officials)
-- ============================================================

-- Travis Stovall (-4131251) — Mayor
-- source: https://www.greshamoregon.gov/globalassets/government/mayor-and-council/meet-the-council/mayor-stovall-thumbnail.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4131251),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8152aa41-5920-4b77-9b4b-14c5bde40c44-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4131251)
);

-- Kayla Brown (-4131252) — Council Member (Position 1)
-- source: https://www.greshamoregon.gov/globalassets/government/mayor-and-council/meet-the-council/kaylabrown-portrait-thumb.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4131252),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1fc5a9ec-086d-4f15-9d35-c11149783b82-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4131252)
);

-- Eddy Morales (-4131253) — Council Member (Position 2)
-- source: https://www.greshamoregon.gov/globalassets/government/mayor-and-council/meet-the-council/councilor-morales-thumbnail.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4131253),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/15010acf-81a8-467b-9a84-18de494c2d67-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4131253)
);

-- Cathy Keathley (-4131254) — Council Member (Position 3)
-- source: https://www.greshamoregon.gov/globalassets/government/mayor-and-council/meet-the-council/cathy-keathley-thumbnail.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4131254),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81648f4a-eb28-43dd-9368-97ccc19463bc-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4131254)
);

-- Jerry Hinton (-4131255) — Council Member (Position 4)
-- source: https://www.greshamoregon.gov/globalassets/government/mayor-and-council/meet-the-council/councilor-hinton-thumbnail.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4131255),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2efbeccb-be43-4637-ba5f-4b78aa169574-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4131255)
);

-- Sue Piazza (-4131256) — Council Member (Position 5)
-- source: https://www.greshamoregon.gov/globalassets/government/mayor-and-council/meet-the-council/councilor-piazza-thumbnail.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4131256),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/436f618a-84ec-48cf-a16d-e1b5532b8fd4-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4131256)
);

-- Janine Gladfelter (-4131257) — Council Member (Position 6)
-- source: https://www.greshamoregon.gov/globalassets/government/mayor-and-council/meet-the-council/councilor-gladfelter-thumbnail.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4131257),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3881e5da-ad55-4f1e-b6b5-5091332ad2e7-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4131257)
);

-- ============================================================
-- TROUTDALE (7 officials)
-- ============================================================

-- David Ripma (-4174851) — Mayor
-- source: https://www.troutdaleoregon.gov/sites/g/files/vyhlif13696/files/styles/convert_image_to_webp/public/styles/directory_listings_body_4_column/public/media/mayorcitycouncil/image/821/david_ripma_new_2023_color.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174851),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3d541a36-ded8-4526-ab81-a19e347dc7cd-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174851)
);

-- Carol Allen (-4174852) — City Councilor
-- source: https://www.troutdaleoregon.gov/sites/g/files/vyhlif13696/files/styles/convert_image_to_webp/public/styles/directory_listings_body_4_column/public/media/mayorcitycouncil/image/30261/carol_allen_color.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174852),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bcb580d9-b8a5-49fe-8c94-b45d502b7501-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174852)
);

-- Jesse Davidson (-4174853) — City Councilor
-- source: https://www.troutdaleoregon.gov/sites/g/files/vyhlif13696/files/styles/convert_image_to_webp/public/styles/directory_listings_body_4_column/public/media/mayorcitycouncil/image/30266/jesse_davidson_color.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174853),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9fbd31da-61c3-4cfb-97d7-b46e5662d685-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174853)
);

-- John Leamy (-4174854) — City Councilor
-- source: https://www.troutdaleoregon.gov/sites/g/files/vyhlif13696/files/styles/convert_image_to_webp/public/styles/directory_listings_body_4_column/public/media/mayorcitycouncil/image/30271/john_leamy_color.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174854),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f0a0b603-5252-4814-b806-36f9811d4cb7-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174854)
);

-- Glenn White (-4174855) — City Councilor
-- source: https://www.troutdaleoregon.gov/sites/g/files/vyhlif13696/files/styles/convert_image_to_webp/public/styles/directory_listings_body_4_column/public/media/mayorcitycouncil/image/30276/glenn_white_color.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174855),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fa52105e-0278-44a3-bc6f-5c4a83b9bf2e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174855)
);

-- Geoffrey Wunn (-4174856) — City Councilor
-- source: https://www.troutdaleoregon.gov/sites/g/files/vyhlif13696/files/styles/convert_image_to_webp/public/styles/directory_listings_body_4_column/public/media/mayorcitycouncil/image/811/geoffrey_2023_color.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174856),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8c90648b-d5a5-45e9-8bf2-72bb2bb41c38-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174856)
);

-- Zach Andrews (-4174857) — City Councilor
-- source: https://www.troutdaleoregon.gov/sites/g/files/vyhlif13696/files/styles/convert_image_to_webp/public/styles/directory_listings_body_4_column/public/media/mayorcitycouncil/image/30281/zach_andrews_color.jpg.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174857),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cc6afbef-7404-4b5b-b8f6-6e9771fac247-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174857)
);

-- ============================================================
-- FAIRVIEW (7 officials) — no photos on official city website
-- ============================================================

-- Keith Kudrna (-4124251) — Mayor
-- No photo found on official city website (fairvieworegon.gov).
-- No politician_images row inserted.

-- Jeff Dennerline (-4124252) — Council Member (Position 1)
-- No photo found on official city website (fairvieworegon.gov).
-- No politician_images row inserted.

-- Steve Marker (-4124253) — Council Member (Position 2)
-- No photo found on official city website (fairvieworegon.gov).
-- No politician_images row inserted.

-- E'an Todd (-4124254) — Council Member (Position 3)
-- No photo found on official city website (fairvieworegon.gov).
-- No politician_images row inserted.

-- Jenni Weber (-4124255) — Council Member (Position 4)
-- No photo found on official city website (fairvieworegon.gov).
-- No politician_images row inserted.

-- Steve Owen (-4124256) — Council Member (Position 5)
-- No photo found on official city website (fairvieworegon.gov).
-- No politician_images row inserted.

-- Paul Copeland (-4124257) — Council Member (Position 6)
-- No photo found on official city website (fairvieworegon.gov).
-- No politician_images row inserted.

-- ============================================================
-- WOOD VILLAGE (5 officials)
-- ============================================================

-- Jairo Rios-Campos (-4183951) — Mayor
-- source: https://www.woodvillageor.gov/wp-content/uploads/Campos188_RT-5x7-1-1143x1600.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4183951),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/964c9691-3f40-4b95-86c9-d22cf10cc92d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4183951)
);

-- Dara Tan (-4183952) — Council President
-- source: https://www.woodvillageor.gov/wp-content/uploads/Tan-0257_RT-5x7-1-1143x1600.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4183952),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0f7137d2-e780-4ca1-bdc4-7406f13df4ca-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4183952)
);

-- John Miner (-4183953) — City Councilor
-- source: https://www.woodvillageor.gov/wp-content/uploads/IMG_8898_Miner-571x800-1-243x340.jpeg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4183953),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/28119052-7b7e-4bb5-b4f4-fce0afcc88d4-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4183953)
);

-- Charlene Gothard (-4183954) — City Councilor
-- source: https://www.woodvillageor.gov/wp-content/uploads/Councilor-Gothard-1280x1600.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4183954),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/40d9f9da-55d0-451b-827d-113d75ea3a6e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4183954)
);

-- Patricia Smith (-4183955) — City Councilor
-- source: https://www.woodvillageor.gov/wp-content/uploads/IMG_8248-533x800.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4183955),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2411c25a-4141-4b5b-9e36-3b137430dec3-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4183955)
);

-- ============================================================
-- MAYWOOD PARK (5 officials) — no photos on official city website
-- ============================================================

-- Jim Akers (-4146731) — Mayor
-- No photo found on official city website (cityofmaywoodpark.com).
-- No politician_images row inserted.

-- Kevin Bussema (-4146732) — Council President
-- No photo found on official city website (cityofmaywoodpark.com).
-- No politician_images row inserted.

-- Jeff Baltzell (-4146733) — City Councilor
-- No photo found on official city website (cityofmaywoodpark.com).
-- No politician_images row inserted.

-- Miriam Berman (-4146734) — City Councilor
-- No photo found on official city website (cityofmaywoodpark.com).
-- No politician_images row inserted.

-- Thomas Welander (-4146735) — City Councilor
-- No photo found on official city website (cityofmaywoodpark.com).
-- No politician_images row inserted.

-- =============== SUMMARY ===============
-- Total officials: 31
-- Headshots uploaded: 19 (Gresham 7, Troutdale 7, Wood Village 5, Maywood Park 0)
-- No photo documented: 12 (Fairview 7, Maywood Park 5)
-- =====================================
