-- CC_0530_la_quinta_headshots.sql
-- CC_0530: headshots for La Quinta's Mayor and four councilmembers, created by CC_0529 (requires it applied first).
--
-- SOURCE. The city's own portraits on laquintaca.gov/business/city-council/council-member-profiles, read 2026-11-28
-- with headless Chrome. Each image sits directly under that person's name heading on the page:
--   Linda Evans showpublishedimage/11250, Kathleen Fitzpatrick 11252, Deborah McGarrey 10466 (a 782x1138 PNG),
--   John Peña 11254, Steve Sanchez 11256 (800x1000 each).
-- Every file was looked at: colour studio portraits, head and shoulders, no frame or disc.
-- Processing (@napi-rs/canvas, JPEG q90, nothing composited): the four 800x1000 files are already 4:5 and were only
-- downscaled to 600x750; McGarrey cropped 700x875 at (41,40) and downscaled.
-- Uploaded as new objects politician_photos/<politician id>-headshot.jpg; each public copy re-downloaded byte-identical
-- (sha256 prefixes: Evans 1ae585b1, Fitzpatrick 45ea83fb, McGarrey c7487391, Peña 26fa78b4, Sanchez d8c94d2a).
-- Copies in backend/data/seed-la-quinta-2026/headshots/.
-- ⚠ check-portrait-framing.mjs / check-headshot-faces.py not run (no ffmpeg / Python here); by-eye review only.
-- OVERWRITTEN VALUES: none -- the five people were created by CC_0529 with no image row and NULL photo columns.
BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id IN ('ac2c538d-62f2-44fe-9522-04b0ba67471a','bda43e19-e04a-47ae-b057-224927e55ad0','1f3fffda-43d7-405f-8913-56ea9b0b0bbd',
                '8098a198-d452-4e68-ab0f-b2c9ddc3d3f8','41208252-af67-4abf-bb02-7ca00f34221c');
  IF n <> 5 THEN RAISE EXCEPTION 'CC_0530 precondition: expected the 5 people from CC_0529, found % (apply it first)', n; END IF;
END $$;

CREATE TEMP TABLE cc0530_new ON COMMIT DROP AS
SELECT v.img::uuid AS img_id, v.pid::uuid AS pid, v.name,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || v.pid || '-headshot.jpg' AS url
  FROM (VALUES
    ('72de401a-0c69-4b27-82df-28dea3b36f04','ac2c538d-62f2-44fe-9522-04b0ba67471a','Linda Evans'),
    ('3a6c7763-0f18-41b0-a6f0-15b1d9e05b22','bda43e19-e04a-47ae-b057-224927e55ad0','Kathleen Fitzpatrick'),
    ('994b565d-ba78-46f5-9185-5b447e2601d1','1f3fffda-43d7-405f-8913-56ea9b0b0bbd','Deborah McGarrey'),
    ('4c83ff17-315c-4092-bd6b-6017fb0975ab','8098a198-d452-4e68-ab0f-b2c9ddc3d3f8','John Peña'),
    ('04108e38-9305-4d63-a614-47f87bfaba64','41208252-af67-4abf-bb02-7ca00f34221c','Steve Sanchez')
  ) AS v(img, pid, name);

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT n.img_id, n.pid, n.url, 'default',
       'City of La Quinta official portrait (laquintaca.gov Council Member Profiles page, read 2026-11-28); 800px original downscaled (McGarrey cropped) to 600x750, nothing composited. No rights statement found on the page. (CC_0530)'
  FROM cc0530_new n
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = n.pid);

UPDATE essentials.politicians p
   SET photo_custom_url = n.url, photo_origin_url = 'https://www.laquintaca.gov/business/city-council/council-member-profiles'
  FROM cc0530_new n
 WHERE p.id = n.pid AND p.photo_custom_url IS NULL AND p.photo_origin_url IS NULL;

DO $$
DECLARE bad text;
BEGIN
  SELECT string_agg(coalesce(p.full_name, n.name), ', ') INTO bad
    FROM cc0530_new n LEFT JOIN essentials.politicians p ON p.id = n.pid
   WHERE p.full_name IS DISTINCT FROM n.name
      OR (SELECT count(*) FROM essentials.politician_images i WHERE i.politician_id = n.pid AND i.id = n.img_id AND i.url = n.url) <> 1
      OR p.photo_custom_url IS DISTINCT FROM n.url
      OR p.photo_origin_url IS DISTINCT FROM 'https://www.laquintaca.gov/business/city-council/council-member-profiles';
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0530: image wiring wrong for: %', bad; END IF;
  RAISE NOTICE 'CC_0530 OK: 5 La Quinta headshots wired';
END $$;

COMMIT;
