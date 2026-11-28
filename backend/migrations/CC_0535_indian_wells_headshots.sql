-- CC_0535_indian_wells_headshots.sql
-- CC_0535: headshots for the five sitting Indian Wells councilmembers created by CC_0534 (requires it applied first).
--
-- SOURCE. The city's own member pages, indianwellsca.gov/city_government/city_council/<member>.php, read 2026-11-28.
-- Each page shows one image named for its member ("DR.TOPER TAYLOR.jpg", "BRIAN M PENNA.jpg", "BRUCE WHITMAN.jpg",
-- "DANA REED.jpg", "GREG SANDERS.jpg"), each 513x779: a cut-out colour portrait on white ABOVE A BURGUNDY NAME PLATE
-- carrying the member's name, title and the city's triangle logo.
-- PROCESSING (@napi-rs/canvas, JPEG q90): crop 420x525 at (46,0) -- entirely above the name plate and its logo, so no
-- text, logo or plate is kept -- and enlarged x1.43 to 600x750. Nothing composited by us; the white background is the
-- city's own cut-out. Looked at by eye after cropping: head and shoulders, no plate, no text, no frame.
-- Uploaded as new objects politician_photos/<politician id>-headshot.jpg; each public copy re-downloaded byte-identical
-- (sha256 prefixes: Taylor 89b8075d, Penna a715bf3d, Whitman 4fef6e16, Reed c32c8acf, Sanders e4537fc4).
-- Copies in backend/data/seed-indian-wells-2026/headshots/. The incoming members (Zwemmer, Hazelton) have none yet.
-- ⚠ check-portrait-framing.mjs / check-headshot-faces.py not run (no ffmpeg / Python here); by-eye review only.
-- OVERWRITTEN VALUES: none -- the five people were created by CC_0534 with no image row and NULL photo columns.
BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id IN ('9539b162-ee7f-4b3a-aa2b-69e87c0f348b','669e5a51-68b9-4f18-a81d-12d433f9e443','5d0f3b5c-72f5-4b5f-95ac-2b2ae40e09b1',
                '479f2b6d-2491-4898-95fc-caddfedce6ab','5780646e-5522-4bd3-8c73-3a753ec49307');
  IF n <> 5 THEN RAISE EXCEPTION 'CC_0535 precondition: expected the 5 people from CC_0534, found % (apply it first)', n; END IF;
END $$;

CREATE TEMP TABLE cc0535_new ON COMMIT DROP AS
SELECT v.img::uuid AS img_id, v.pid::uuid AS pid, v.name, v.page,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || v.pid || '-headshot.jpg' AS url
  FROM (VALUES
    ('c9a9d2b8-21d3-4a77-afab-f31cc23372c8','9539b162-ee7f-4b3a-aa2b-69e87c0f348b','Toper Taylor','mayor_dr_toper_taylor'),
    ('68099ee1-c8d7-4fa4-896a-3262469af685','669e5a51-68b9-4f18-a81d-12d433f9e443','Brian M. Penna','mayor_pro_tem_brian_penna'),
    ('ccbc43ac-a415-4806-a059-cbc83925a3a8','5d0f3b5c-72f5-4b5f-95ac-2b2ae40e09b1','Bruce Whitman','council_member_bruce_whitman'),
    ('0646b007-75d0-4592-b511-ed71d07ea066','479f2b6d-2491-4898-95fc-caddfedce6ab','Dana Reed','council_member_dana_reed'),
    ('c8c24d86-d458-4a30-9435-1058bfbb81de','5780646e-5522-4bd3-8c73-3a753ec49307','Greg Sanders','council_member_greg_sanders')
  ) AS v(img, pid, name, page);

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT n.img_id, n.pid, n.url, 'default',
       'City of Indian Wells official portrait (indianwellsca.gov member page, read 2026-11-28); 513x779 name card cropped above its name plate and logo, enlarged x1.43 to 600x750, nothing composited by us. No rights statement found on the page. (CC_0535)'
  FROM cc0535_new n
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = n.pid);

UPDATE essentials.politicians p
   SET photo_custom_url = n.url,
       photo_origin_url = 'https://www.indianwellsca.gov/city_government/city_council/' || n.page || '.php'
  FROM cc0535_new n
 WHERE p.id = n.pid AND p.photo_custom_url IS NULL AND p.photo_origin_url IS NULL;

DO $$
DECLARE bad text;
BEGIN
  SELECT string_agg(coalesce(p.full_name, n.name), ', ') INTO bad
    FROM cc0535_new n LEFT JOIN essentials.politicians p ON p.id = n.pid
   WHERE p.full_name IS DISTINCT FROM n.name
      OR (SELECT count(*) FROM essentials.politician_images i WHERE i.politician_id = n.pid AND i.id = n.img_id AND i.url = n.url) <> 1
      OR p.photo_custom_url IS DISTINCT FROM n.url
      OR p.photo_origin_url IS DISTINCT FROM 'https://www.indianwellsca.gov/city_government/city_council/' || n.page || '.php';
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0535: image wiring wrong for: %', bad; END IF;
  RAISE NOTICE 'CC_0535 OK: 5 Indian Wells headshots wired';
END $$;

COMMIT;
