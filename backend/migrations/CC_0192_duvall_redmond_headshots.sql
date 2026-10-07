-- CC_0192_duvall_redmond_headshots.sql
-- Duvall + Redmond WA deep seed, wave 3 (headshots). Slot RESERVED from the allocator.
--
-- Sets photo_custom_url on 13 of the 16 officeholders seated by CC_0191.
--
-- 🔴 photo_custom_url IS WHAT RENDERS. The objects were uploaded to Supabase Storage by
-- backend/scripts/_tmp-wa-duvall-redmond-headshots.py, and that upload ALONE changes nothing a
-- voter sees — a politician_images row would not either. This migration is the visible half.
--
-- Pipeline, the house standard: source cropped to 4:5 FIRST (never stretched), resized 600x750
-- Lanczos q90, uploaded to politician_photos/{politician_id}-headshot.jpg with x-upsert.
-- Verified after upload: all 13 served HTTP 200 image/jpeg, against a positive control — an
-- absent object returns 400, so the served check can fail.
--
-- Provenance and the full contact sheet: backend/data/seed-duvall-redmond-2026/HEADSHOTS.md
--   Duvall  — each member's own page on duvallwa.gov, every image carrying the page's own
--             alt="Profile picture of <NAME>" as a second factor.
--   Redmond — redmond.gov/189/City-Council (councilmembers) and /284/Office-of-the-Mayor,
--             each image carrying an alt naming the person.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THREE SEATS ARE DELIBERATELY LEFT WITHOUT A PHOTO. A blank beats a wrong or barred face.
--
--   Duvall  Position 2  Linda Conway    — appointed 2026-09-01; the city has published no
--                                         member page for her, so there is no portrait at all.
--   Duvall  Position 3  Sara Taylor     — appointed 2026-08-18; same.
--   Redmond Position 2  Vivek Prakriya  — the city's own 1864x1864 portrait is BLACK AND WHITE.
--                                         Ruled out 2026-10-06 (Cantrell): no monochrome.
--
-- ⚠ Prakriya's frame is why a saturation threshold is not a monochrome test. His black and white
-- carries a cool tint, so mean R-G-B spread measured 15.0 and cleared a threshold of 6. A
-- hue-variance test then failed the other way, flagging six colour portraits as mono because a
-- face crop is mostly skin and skin is one hue. The test that works is chromaticity constancy
-- over the WHOLE frame: greyscale control 0.0, colour control 87.6, Prakriya 6.4, every other
-- frame 47.7-164.1.
--
-- ⚠ Mike Supple's source is only 165x231 — the largest the City of Duvall publishes — so his
-- 600x750 object is an upscale and will read softer than the other twelve. Published knowingly
-- (Cantrell, 2026-10-06). Replace it if the city ever posts a larger one.
--
-- ⚠ Six frames were cropped to remove a circular mask or a flat border before resizing: Forsythe,
-- Stuart, Kritzer, Soni and Nuevacamina were a circle on a flat ground, and Birney had a light
-- border. The card renders a 4:5 box with object-cover, so the mask corners would otherwise show.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

UPDATE essentials.politicians p
   SET photo_custom_url = v.url,
       photo_origin_url = v.origin
  FROM (VALUES
    ('80492335-efc1-4a51-bfad-e17c4c0e363c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/80492335-efc1-4a51-bfad-e17c4c0e363c-headshot.jpg', 'https://www.duvallwa.gov/ImageRepository/Document?documentID=14439'),
    ('72663bb1-7b11-42ba-a75a-748e4edc1c96'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/72663bb1-7b11-42ba-a75a-748e4edc1c96-headshot.jpg', 'https://www.duvallwa.gov/ImageRepository/Document?documentID=13383'),
    ('1b29e084-8849-4731-98bf-dd97706ea320'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1b29e084-8849-4731-98bf-dd97706ea320-headshot.jpg', 'https://www.duvallwa.gov/ImageRepository/Document?documentID=14773'),
    ('ad0e32d8-1b8c-4bc2-856f-e2323b942ec4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ad0e32d8-1b8c-4bc2-856f-e2323b942ec4-headshot.jpg', 'https://www.duvallwa.gov/ImageRepository/Document?documentID=8889'),
    ('d7fa2d62-1058-434a-83fb-1a972e15ee12'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d7fa2d62-1058-434a-83fb-1a972e15ee12-headshot.jpg', 'https://www.duvallwa.gov/ImageRepository/Document?documentID=14441'),
    ('628c3b92-99eb-44e3-9f9d-fec8dcff8bd2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/628c3b92-99eb-44e3-9f9d-fec8dcff8bd2-headshot.jpg', 'https://www.duvallwa.gov/ImageRepository/Document?documentID=14626'),
    ('9f0f1719-3d68-4ea9-b0a4-c46013cd8b30'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9f0f1719-3d68-4ea9-b0a4-c46013cd8b30-headshot.jpg', 'https://www.redmond.gov/ImageRepository/Document?documentId=157'),
    ('2135cd0a-1358-4ca4-8d30-0d808ede5336'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2135cd0a-1358-4ca4-8d30-0d808ede5336-headshot.jpg', 'https://www.redmond.gov/ImageRepository/Document?documentId=40581'),
    ('6b0a5417-9094-447f-8df7-d868aab762eb'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b0a5417-9094-447f-8df7-d868aab762eb-headshot.jpg', 'https://www.redmond.gov/ImageRepository/Document?documentId=21593'),
    ('9a1fcca3-a4c7-47bd-8c8b-34b2a8c97e95'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9a1fcca3-a4c7-47bd-8c8b-34b2a8c97e95-headshot.jpg', 'https://www.redmond.gov/ImageRepository/Document?documentId=21592'),
    ('21a8e1cc-f52d-439e-a0d0-50c5f6720bed'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/21a8e1cc-f52d-439e-a0d0-50c5f6720bed-headshot.jpg', 'https://www.redmond.gov/ImageRepository/Document?documentId=11885'),
    ('6d577801-27bd-41ce-b71d-f8c83d66cd8c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6d577801-27bd-41ce-b71d-f8c83d66cd8c-headshot.jpg', 'https://www.redmond.gov/ImageRepository/Document?documentID=40269'),
    ('709a988c-9853-40d9-9849-841fa964782f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/709a988c-9853-40d9-9849-841fa964782f-headshot.jpg', 'https://www.redmond.gov/ImageRepository/Document?documentId=30947')
  ) AS v(pid, url, origin)
 WHERE p.id = v.pid
   AND (p.photo_custom_url IS DISTINCT FROM v.url OR p.photo_origin_url IS DISTINCT FROM v.origin);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE v_set int; v_blank int; v_mono int; v_wrong int;
BEGIN
  -- exactly 13 of the 16 carry a photo, and every URL is the storage object named for that person
  SELECT count(*) INTO v_set
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND g.mtfcc = 'G4110'
     AND p.photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || p.id::text || '-headshot.jpg';
  IF v_set <> 13 THEN
    RAISE EXCEPTION 'WA-3 gate: expected 13 self-named photo_custom_url, got %', v_set;
  END IF;

  -- 🔴 A URL that does not contain its own politician id is the <uuid>/default.jpeg failure:
  -- the importer that wrote one person's object under another person's name.
  SELECT count(*) INTO v_wrong
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535')
     AND p.photo_custom_url IS NOT NULL
     AND position(p.id::text in p.photo_custom_url) = 0;
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'WA-3 gate: % photo_custom_url(s) do not name their own politician id', v_wrong;
  END IF;

  -- the three deliberate blanks are still blank
  SELECT count(*) INTO v_blank
    FROM essentials.politicians p
   WHERE p.id IN ('25a0dfc4-733c-465a-867e-2bc0a1112767',   -- Linda Conway
                  'e52161da-1cd0-4939-bd8f-9f77aaca20f1',   -- Sara Taylor
                  '4df8bf54-08d5-4ca8-8ed6-01c570575670')   -- Vivek Prakriya (monochrome)
     AND p.photo_custom_url IS NULL;
  IF v_blank <> 3 THEN
    RAISE EXCEPTION 'WA-3 gate: expected Conway, Taylor and Prakriya to stay blank, % are', v_blank;
  END IF;

  -- and nobody else in either city picked one up
  SELECT count(*) INTO v_mono
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND p.photo_custom_url IS NOT NULL;
  IF v_mono <> 13 THEN
    RAISE EXCEPTION 'WA-3 gate: % of the 16 carry a photo, expected exactly 13', v_mono;
  END IF;

  RAISE NOTICE 'WA-3 headshot gate PASSED: 13 of 16 photo_custom_url set, each naming its own politician id; Conway, Taylor and Prakriya deliberately blank.';
END $$;

COMMIT;
