-- CC_0526_indio_dsusd_cvusd_headshots.sql
-- CC_0526: headshots for Indio's new officials (CC_0523) and both school boards (CC_0524, CC_0525), and provenance
-- for the five Indio council photos already on file. Requires CC_0523, CC_0524 and CC_0525 applied first.
--
-- WHAT WAS CHECKED (2026-11-27). Every file was downloaded and looked at side by side with its source.
--   COUNCIL (5, unchanged files): our stored 600x750 photos of Miller, Fermon, Holmes, Oscar Ortiz and Guitron IV
--     are crops of the same official portraits the city publishes today on each member's staff-directory page
--     (indio.org/Home/Components/StaffDirectory/StaffDirectory/<36|40|38|42|224>/181; originals 1920x2880, Holmes
--     1920x2400) -- same photograph, same backdrop, same clothes. Only provenance changes here.
--   NEW FILES (15), all colour, head and shoulders, no frame or disc; processed with @napi-rs/canvas (crop to 4:5,
--   two-step resize to 600x750, JPEG q90, nothing composited); uploaded as new objects
--   politician_photos/<politician id>-headshot.jpg; the public copy of each was re-downloaded and is byte-identical.
--   Copies: backend/data/seed-indio-2026/headshots/.
--     Cynthia Hernandez  indio.org showpublishedimage/2404 (1920x2880), crop 1440x1800 @ (340,380), x0.417  sha256 161af1c3...
--     Rob Rockwell       indio.org showpublishedimage/2408 (1920x2880), crop 1440x1800 @ (240,420), x0.417  sha256 49e1f2ad...
--     Felipe Ortiz       ortizforindio.com (Wix media 3e705d_930b6c16...~mv2.jpg, 2668x4000), crop 840x1050 @ (1180,540),
--                        x0.714. The source is a two-person outdoor photo on the candidate's own site; the crop holds
--                        him alone. Identity: the same man as the captioned banner "FELIPE ORTIZ / INDIO CITY COUNCIL
--                        DISTRICT 4" (gpsbusinessinsider.com, 2026-05-15). Campaign photo, press_use.   sha256 6f944d48...
--     DSUSD x5           dsusd.us board page, the ONLY size the district publishes: 100x127 (Porras 100x125); top 100x125
--                        taken and enlarged x6. Badly soft. REPLACE when larger photos are found.
--     CVUSD x7           cvusd.us/trustees, unsized originals on files.smartsites.parentsquare.com: 512x768 / 512x811
--                        (Acuña 284x427). Crop 384x480 @ (64,0), x1.5625 (Acuña 224x280 @ (30,0), x2.68). Studio portraits
--                        cut at the waist; the crop keeps head and shoulders.
--   ⚠ check-portrait-framing.mjs and check-headshot-faces.py were NOT run (no ffmpeg or Python on this machine);
--     the by-eye review above is the only framing check these files have had.
--
-- LICENCE TEXT. A California city's or school district's photo is not a U.S. federal work, and none of the three
-- bodies publishes a rights statement on the pages read. So the five council rows' 'us_government_work' is replaced
-- by a statement of what is known, the way CC_0520 did for Fremont.
-- 🔴 OVERWRITTEN VALUES.
--   politician_images.photo_license = 'us_government_work' on:
--     9f23add6-5f94-4457-9517-8395b8637660 Glenn Miller     5db10e36-92e7-4c72-8111-7e065ec34851 Waymond Fermon
--     ed64874d-0258-4449-b211-5af076c21ae4 Elaine Holmes    827f0d70-bbdb-47d2-af36-07e6c7f85951 Oscar Ortiz
--     b43e3c9b-1769-4255-be09-244e690222df Benjamin Guitron IV
--   politicians.photo_origin_url = NULL for those five. photo_custom_url / photo_origin_url NULL for the 15 people
--   created by CC_0523-CC_0525 (no image rows existed).
BEGIN;

-- ─── 0. Preconditions: the 15 people exist, have no image yet, and carry the expected names ───
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians p
    JOIN (VALUES
      ('f4f88028-b420-4279-be23-47de511ef541'::uuid,'Cynthia Hernandez'), ('052aa5d2-4f68-47f3-8f24-6fb62afe8878'::uuid,'Rob Rockwell'),
      ('67b41cba-1524-49a1-a8b5-91624b5bbbee'::uuid,'Felipe Ortiz'),
      ('2589df6a-1fa4-4d4d-9d61-e0b7d37c42e4'::uuid,'Kailee Watson'), ('d0c29a3a-e8ed-43f3-8c61-af527f4e1838'::uuid,'Humberto Alvarez'),
      ('8d749ca0-9347-493f-b11c-5c63839c51c0'::uuid,'Tricia Pearce'), ('09bc7941-af71-46fd-b00d-532dca925615'::uuid,'Linda Porras'),
      ('742d9b54-3b5b-41cc-a829-5475ced070a4'::uuid,'Michael Duran'),
      ('1280541b-a136-4e31-86ea-17976e201833'::uuid,'Valerie García'), ('4ca4150d-e69c-4e82-900e-57220c37d7ae'::uuid,'Trinidad Arredondo'),
      ('041e8979-7aec-422b-a536-9d57c9aeb039'::uuid,'Joey Acuña Jr.'), ('ea334ce1-68cb-4bf8-8b9d-d821aeb0e75b'::uuid,'Alena Callimanis'),
      ('fe743dbf-d2f5-4948-93cf-706ee1e1b8a5'::uuid,'Jesus Gonzalez'), ('649fbabe-eda0-4b05-a651-e39268b928a7'::uuid,'Thomas Tortez'),
      ('cc308e9e-d302-4d67-b3b3-6f3fa8dae8db'::uuid,'Jocelyn Vargas')
    ) AS v(id, name) ON v.id = p.id AND v.name = p.full_name;
  IF n <> 15 THEN RAISE EXCEPTION 'CC_0526 precondition: expected the 15 people from CC_0523-CC_0525, found % (apply those first)', n; END IF;
END $$;

-- ─── 1. Image rows and person columns for the 15 ───
CREATE TEMP TABLE cc0526_new ON COMMIT DROP AS
SELECT v.img::uuid AS img_id, v.pid::uuid AS pid, v.origin, v.lic,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || v.pid || '-headshot.jpg' AS url
  FROM (VALUES
    ('87ba46ad-6831-41ea-b1c3-b4a57c2e08df','f4f88028-b420-4279-be23-47de511ef541','https://www.indio.org/departments/city-clerk/elected-city-clerk','indio'),
    ('fa3723c0-6537-4e8d-a1da-de9ccf58af52','052aa5d2-4f68-47f3-8f24-6fb62afe8878','https://www.indio.org/departments/city-council/other-elected-officials/city-treasurer','indio'),
    ('7b0788b7-1397-4017-b9ac-108a8242a062','67b41cba-1524-49a1-a8b5-91624b5bbbee','https://www.ortizforindio.com/','felipe'),
    ('db453a56-3237-4f28-99c4-5ef1b3372f2a','2589df6a-1fa4-4d4d-9d61-e0b7d37c42e4','https://www.dsusd.us/about_dsusd/board_of_education/board_members','dsusd'),
    ('673fe00d-5964-4727-9830-75eb48fa6136','d0c29a3a-e8ed-43f3-8c61-af527f4e1838','https://www.dsusd.us/about_dsusd/board_of_education/board_members','dsusd'),
    ('9aed0742-b4a9-4b83-bcd8-cefc2867fcb0','8d749ca0-9347-493f-b11c-5c63839c51c0','https://www.dsusd.us/about_dsusd/board_of_education/board_members','dsusd'),
    ('c6b34a5f-e773-4256-aa8e-301999ea7622','09bc7941-af71-46fd-b00d-532dca925615','https://www.dsusd.us/about_dsusd/board_of_education/board_members','dsusd'),
    ('d9e4d225-d1e5-438a-9167-70f9b433e5ef','742d9b54-3b5b-41cc-a829-5475ced070a4','https://www.dsusd.us/about_dsusd/board_of_education/board_members','dsusd'),
    ('a848279b-f6b9-428c-b3eb-488361ba6501','1280541b-a136-4e31-86ea-17976e201833','https://www.cvusd.us/trustees','cvusd'),
    ('8abfd6a6-a4f7-4d62-b6dc-dba17b64dd21','4ca4150d-e69c-4e82-900e-57220c37d7ae','https://www.cvusd.us/trustees','cvusd'),
    ('b5b2a7d1-12bb-4579-91eb-7f65c3662e0d','041e8979-7aec-422b-a536-9d57c9aeb039','https://www.cvusd.us/trustees','cvusd_small'),
    ('c2c87da9-e245-4584-a1e4-c87936dd1d04','ea334ce1-68cb-4bf8-8b9d-d821aeb0e75b','https://www.cvusd.us/trustees','cvusd'),
    ('3500a03d-d0dd-4ee1-98cf-0d856a2ca324','fe743dbf-d2f5-4948-93cf-706ee1e1b8a5','https://www.cvusd.us/trustees','cvusd'),
    ('eefb3e19-afea-4020-b42e-b1e67527c900','649fbabe-eda0-4b05-a651-e39268b928a7','https://www.cvusd.us/trustees','cvusd'),
    ('647bb86d-b247-43d4-9380-530974382255','cc308e9e-d302-4d67-b3b3-6f3fa8dae8db','https://www.cvusd.us/trustees','cvusd')
  ) AS v(img, pid, origin, lic);

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT n.img_id, n.pid, n.url, 'default', l.txt
  FROM cc0526_new n
  JOIN (VALUES
    ('indio', 'City of Indio official portrait (indio.org, read 2026-11-27); 1920x2880 original, cropped 4:5 and downscaled to 600x750, nothing composited. No rights statement found on the page. (CC_0526)'),
    ('felipe', 'Campaign photo from the candidate''s own site, ortizforindio.com (candidate campaign, press_use); 2668x4000 two-person photo cropped to the candidate alone and downscaled to 600x750. (CC_0526)'),
    ('dsusd', 'Desert Sands Unified School District official board portrait (dsusd.us Board Members page, read 2026-11-27); the district publishes it at 100x127 only, so this 600x750 file is a x6 upscale, REPLACE. Rights statement not checked. (CC_0526)'),
    ('cvusd', 'Coachella Valley Unified School District official trustee portrait (cvusd.us/trustees, read 2026-11-27); 512px-wide original cropped to head and shoulders and enlarged x1.56 to 600x750. Rights statement not checked. (CC_0526)'),
    ('cvusd_small', 'Coachella Valley Unified School District official trustee portrait (cvusd.us/trustees, read 2026-11-27); 284x427 original cropped to head and shoulders and enlarged x2.68 to 600x750, REPLACE if a larger copy is published. Rights statement not checked. (CC_0526)')
  ) AS l(k, txt) ON l.k = n.lic
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = n.pid);

UPDATE essentials.politicians p
   SET photo_custom_url = n.url, photo_origin_url = n.origin
  FROM cc0526_new n
 WHERE p.id = n.pid AND p.photo_custom_url IS NULL AND p.photo_origin_url IS NULL;

-- ─── 2. Council provenance (files unchanged) ───
UPDATE essentials.politicians p
   SET photo_origin_url = 'https://www.indio.org/Home/Components/StaffDirectory/StaffDirectory/' || v.staff || '/181'
  FROM (VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2'::uuid, 36), ('86fe2b91-d1fa-4c65-8d75-90f181624fe4'::uuid, 40),
               ('dea49bf0-12b4-40b7-a48c-a3eda018ef04'::uuid, 38), ('4bbba476-c442-42d5-8b5d-07e8fac1481c'::uuid, 42),
               ('f13b83e3-e086-479a-b6e4-9ad63f89f308'::uuid, 224)) AS v(pid, staff)
 WHERE p.id = v.pid AND p.photo_origin_url IS NULL;

UPDATE essentials.politician_images
   SET photo_license = 'City of Indio official portrait (indio.org staff-directory page, read 2026-11-27): the stored 600x750 file is a crop of the 1920px original the city publishes today. No rights statement found on the page. Replaces an unsupported ''us_government_work'' claim -- a city photo is not a federal work. (CC_0526)'
 WHERE id IN ('9f23add6-5f94-4457-9517-8395b8637660','5db10e36-92e7-4c72-8111-7e065ec34851','ed64874d-0258-4449-b211-5af076c21ae4',
              '827f0d70-bbdb-47d2-af36-07e6c7f85951','b43e3c9b-1769-4255-be09-244e690222df')
   AND photo_license = 'us_government_work';

-- ─── 3. Post-verify ───
DO $$
DECLARE n int; bad text;
BEGIN
  -- each of the 15: exactly one image row, on their own object, and the person columns agree with it
  SELECT string_agg(p.full_name, ', ') INTO bad
    FROM cc0526_new n JOIN essentials.politicians p ON p.id = n.pid
   WHERE (SELECT count(*) FROM essentials.politician_images i WHERE i.politician_id = n.pid AND i.url = n.url AND i.id = n.img_id) <> 1
      OR p.photo_custom_url IS DISTINCT FROM n.url OR p.photo_origin_url IS DISTINCT FROM n.origin
      OR n.url NOT LIKE '%/' || n.pid::text || '-headshot.jpg';
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0526: image wiring wrong for: %', bad; END IF;

  -- the body-specific licence text sits on the body's own people (a crossed id would mislabel a photo)
  SELECT count(*) INTO n FROM essentials.politician_images i
    JOIN essentials.office_terms t ON t.politician_id = i.politician_id
    JOIN essentials.offices o ON o.id = t.office_id JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE (c.government_id = 'a6928990-7771-480e-91a3-fa19b84cc11f' AND i.photo_license NOT LIKE 'Desert Sands Unified%')
      OR (c.government_id = 'f4848009-c694-42e5-9be9-356c1277564d' AND i.photo_license NOT LIKE 'Coachella Valley Unified%');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0526: % school-board image row(s) carry another body''s licence text', n; END IF;

  -- council: five rewritten licences and five origin pages, none 'us_government_work' left in the city
  SELECT count(*) INTO n FROM essentials.politician_images i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.external_id BETWEEN -4012005 AND -4012001 AND i.photo_license LIKE 'City of Indio official portrait%(CC_0526)'
     AND p.photo_origin_url LIKE 'https://www.indio.org/Home/Components/StaffDirectory/StaffDirectory/%/181';
  IF n <> 5 THEN RAISE EXCEPTION 'CC_0526: expected 5 council rows with provenance, found %', n; END IF;

  RAISE NOTICE 'CC_0526 OK: 15 new headshots wired, 5 council provenance rows rewritten';
END $$;

COMMIT;
