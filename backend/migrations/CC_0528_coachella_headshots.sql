-- CC_0528_coachella_headshots.sql
-- CC_0528: headshots for six Coachella officials created by CC_0527 (requires it applied first).
--
-- SOURCE. The city's own portraits on coachella.org, read 2026-11-28 with headless Chrome:
--   city-government/city-council: Figueroa (showpublishedimage/6976, 1920x2396), Yadira Perez (7922, 1920x2450),
--   Stephanie Virgen (6978, 1920x2719), Denise Delgado (7926, 1920x2617), Juan M. Martinez (9410, 1143x1599);
--   departments/city-treasurer: Mayra Perez (8024, 186x234 -- the only size published).
-- Every file was looked at: colour, outdoor portrait of the named person (each sits under that person's name on the
-- page), no frame or disc. Processing with @napi-rs/canvas: crop 4:5 to head and shoulders, two-step resize to 600x750,
-- JPEG q90, nothing composited. Mayra Perez: 180x225 enlarged x3.33, marked REPLACE.
-- Uploaded as new objects politician_photos/<politician id>-headshot.jpg; each public copy re-downloaded byte-identical
-- (sha256 prefixes: Figueroa 0801acdb, Y. Perez b580b9fa, Delgado 325b88bf, Virgen f2d4a7ee, Martinez 689ba207,
-- M. Perez 6a63536d). Copies in backend/data/seed-coachella-2026/headshots/.
-- NOT COVERED: City Clerk Angela M. Zepeda (no photo on the clerk page) and the two incoming councilmembers.
-- ⚠ check-portrait-framing.mjs / check-headshot-faces.py not run (no ffmpeg / Python here); by-eye review only.
-- OVERWRITTEN VALUES: none -- the six people were created by CC_0527 with no image row and NULL photo columns.
BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id IN ('73d6844b-850d-43c7-ae74-2eb274fb83ad','4adead28-7a33-4c8c-80b6-c1d3211e6082','171263cc-12f0-4151-be88-7ce4da1d9048',
                'e7f3f51b-a89e-44a1-ac7a-fce2992c4aef','b3fef4b0-9849-479b-9964-21e46fe44eed','b8030f58-9d58-434f-8efd-897302c6f244');
  IF n <> 6 THEN RAISE EXCEPTION 'CC_0528 precondition: expected the 6 people from CC_0527, found % (apply it first)', n; END IF;
END $$;

CREATE TEMP TABLE cc0528_new ON COMMIT DROP AS
SELECT v.img::uuid AS img_id, v.pid::uuid AS pid, v.name, v.origin, v.small,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || v.pid || '-headshot.jpg' AS url
  FROM (VALUES
    ('4d81edbb-99c8-4578-9226-a219c3bcf08e','73d6844b-850d-43c7-ae74-2eb274fb83ad','Frank Figueroa','https://www.coachella.org/city-government/city-council',false),
    ('d8b03163-69c5-4843-9357-ff15603f171b','4adead28-7a33-4c8c-80b6-c1d3211e6082','Yadira Perez','https://www.coachella.org/city-government/city-council',false),
    ('927e8825-2553-4cff-bedf-556e35618d98','171263cc-12f0-4151-be88-7ce4da1d9048','Denise Delgado','https://www.coachella.org/city-government/city-council',false),
    ('4bfe3d02-6a8a-4099-b2d7-7b99de6ff158','e7f3f51b-a89e-44a1-ac7a-fce2992c4aef','Stephanie Virgen','https://www.coachella.org/city-government/city-council',false),
    ('9158e486-9fed-4e69-bfba-ce6f50749b30','b3fef4b0-9849-479b-9964-21e46fe44eed','Juan M. Martinez','https://www.coachella.org/city-government/city-council',false),
    ('0ebb9cf7-7730-47ce-b89a-f19bb58c19ab','b8030f58-9d58-434f-8efd-897302c6f244','Mayra Perez','https://www.coachella.org/departments/city-treasurer',true)
  ) AS v(img, pid, name, origin, small);

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT n.img_id, n.pid, n.url, 'default',
       CASE WHEN n.small
         THEN 'City of Coachella official portrait (coachella.org City Treasurer page, read 2026-11-28); published at 186x234 only, cropped 4:5 and enlarged x3.33 to 600x750, REPLACE. No rights statement found on the page. (CC_0528)'
         ELSE 'City of Coachella official portrait (coachella.org City Council page, read 2026-11-28); 1143-1920px original cropped 4:5 and downscaled to 600x750, nothing composited. No rights statement found on the page. (CC_0528)'
       END
  FROM cc0528_new n
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = n.pid);

UPDATE essentials.politicians p
   SET photo_custom_url = n.url, photo_origin_url = n.origin
  FROM cc0528_new n
 WHERE p.id = n.pid AND p.photo_custom_url IS NULL AND p.photo_origin_url IS NULL;

DO $$
DECLARE bad text;
BEGIN
  SELECT string_agg(coalesce(p.full_name, n.name), ', ') INTO bad
    FROM cc0528_new n LEFT JOIN essentials.politicians p ON p.id = n.pid
   WHERE p.full_name IS DISTINCT FROM n.name
      OR (SELECT count(*) FROM essentials.politician_images i WHERE i.politician_id = n.pid AND i.id = n.img_id AND i.url = n.url) <> 1
      OR p.photo_custom_url IS DISTINCT FROM n.url OR p.photo_origin_url IS DISTINCT FROM n.origin;
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0528: image wiring wrong for: %', bad; END IF;
  RAISE NOTICE 'CC_0528 OK: 6 Coachella headshots wired';
END $$;

COMMIT;
