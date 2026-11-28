-- CC_0522_fremont_ying_min_li_headshot.sql
-- CC_0522: headshot for Ying Min Li (Fremont City Council District 4, incoming 2026-12-08 per CC_0521).
--
-- SOURCE. The candidate's own campaign site, yingminli.com ("Ying-Min Li for Fremont City Council 2026"):
-- the banner portrait used as the CSS background of the home and About pages,
-- https://yingminli.com/wp-content/uploads/2026/06/YML-landscapes-1538x500-2.jpg (1538x500; the "-1" copy is
-- byte-identical; no larger original was found at the unsized or "-scaled" names). The site has no dedicated
-- headshot; its gallery is event photography, and the home page also carries ENDORSERS' 200x250 portraits
-- (Fiona Ma, David Haubert, Yajing Zhang, Yang Shao) -- deliberately NOT used. Identity: the banner is the
-- candidate's own hero image on the candidate's own site, and the same person is the one constant across the
-- gallery images named "YML-..." (the candidate's initials).
--
-- PROCESSING. Cropped 4:5 from the full height, x 872..1272, y 0..500 (400x500), and ENLARGED x1.5 to 600x750
-- (canvas, high-quality smoothing). Nothing composited by us; the lake-and-hills backdrop itself looks
-- composited in the source. Uploaded as a new object
--   politician_photos/d7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788-headshot.jpg
--   sha256 79f26fd9e555f80ab9ad198d7f3d317d8b27e2b1ec2d153331dce5bea3a2a22e, 73,652 bytes (public URL byte-identical).
-- Looked at by eye before upload (colour, head and shoulders, centred, no frame). check-portrait-framing.mjs and
-- check-headshot-faces.py could not run on this machine (no ffmpeg / Python).
--
-- WRITES. One essentials.politician_images row (pinned id) and politicians.photo_custom_url / photo_origin_url
-- for Li. 🔴 OVERWRITTEN VALUES: both politicians columns were NULL (row created by CC_0521 on 2026-11-28).
BEGIN;

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT '5c0a3f52-7b3e-4f0e-9a51-2d8a6b1c9e47', 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788-headshot.jpg',
       'default',
       'Campaign portrait, yingminli.com home and About page banner (YML-landscapes-1538x500-2.jpg; candidate campaign, press_use) - 1538x500 source, cropped 4:5 to 400x500 and upscaled x1.5, REPLACE if a larger portrait is published. The backdrop appears composited in the source. (CC_0522)'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788');

UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788-headshot.jpg',
       photo_origin_url = 'https://yingminli.com/'
 WHERE id = 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788'
   AND full_name = 'Ying Min Li'
   AND photo_custom_url IS NULL AND photo_origin_url IS NULL;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.politicians p JOIN essentials.politician_images i ON i.politician_id = p.id
   WHERE p.id = 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788' AND p.full_name = 'Ying Min Li'
     AND i.url = p.photo_custom_url AND p.photo_origin_url = 'https://yingminli.com/'
     AND i.photo_license LIKE '%(CC_0522)';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0522: expected Ying Min Li with one image matching photo_custom_url, found %', n; END IF;
  -- the image is Li's alone: no other politician points at this file
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE photo_custom_url LIKE '%d7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788-headshot.jpg' AND id <> 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0522: % other politician(s) point at Li''s headshot', n; END IF;
  RAISE NOTICE 'CC_0522 OK: Ying Min Li headshot set';
END $$;

COMMIT;
