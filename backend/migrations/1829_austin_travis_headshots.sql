-- 1829_austin_travis_headshots.sql
--
-- Austin TX / Travis County deep seed, wave 1 — 20 portraits for the 23 seats created by
-- 1827 and seated by 1828.
--
-- All 20 were staged to 600x750 (4:5), Lanczos, JPEG q90, uploaded to storage bucket
-- politician_photos as <politician_id>-headshot.jpg, and reviewed by Chris on a contact-sheet
-- Artifact before this ran. No social media, no monochrome, no group crops.
-- Every bucket URL was HEAD-checked and returns 200 image/jpeg before this migration was written.
--
-- 🔴 photo_custom_url IS SET DELIBERATELY, not just photo_origin_url. The backend read path is
--    COALESCE(photo_custom_url, photo_origin_url, '') and ev-ui does photo_origin_url ||
--    images[0].url, so a source-PAGE url sitting alone in photo_origin_url WINS over the mirrored
--    image and renders a BROKEN portrait. That silently broke 48 WI profiles (migs 1472-1474)
--    until 1475 Part B repaired it. Same pattern as 1822.
--
-- WHAT THE CONTACT SHEET CAUGHT (it has caught something on every wave; this was no exception)
--   * A 1080x1080 image on Ann Howard's own precinct page is NOT a portrait — it is a departmental
--     graphic reading "When you need help, who should you contact?". It was a candidate purely
--     because of its size and location. REJECTED. She is imported from the 400px file instead,
--     which is why her row is soft.
--   * The county publishes DEPARTMENT STAFF portraits beside the electeds: kate-garza.jpg sits on
--     the County Judge's page and Grace_Inman_headshot.JPG elsewhere. Matching a filename
--     containing "headshot" would have filed a staffer's face under an officeholder's name. All
--     20 images here were confirmed by eye against the office they are attached to.
--   * A first pass converted RGBA straight to RGB, which turned transparent PNG corners BLACK on
--     the DA's circular-vignette portrait and on Brigid Shea's PNG. Alpha is now flattened onto
--     white before conversion.
--
-- RESOLUTION. The gate is the UPSCALE FACTOR, 600/crop_width, not a pixel floor.
--   * 13 clean rows at 0.37x-0.71x — genuine downscales.
--     The 11 city portraits come from Austin's Widen DAM at ~2000px.
--   * 7 SOFT rows at 1.5x-3.0x, every one flagged REPLACE in photo_license with its source
--     dimensions, per the established convention. Shipped on the standing call that an upscale
--     beats a blank spot. At 3.0x the pixels are largely invented; these are placeholders that
--     happen to be the right person.
--   * The DA's asset is named "...1727-x-2506-px..." but serves at 300x300; its srcset confirms
--     300w is the largest that exists. The filename's dimensions are decoration, not a hint.
--
-- NOT IMPORTED — 3 of 23 seats still have no portrait, and it is a genuine absence rather than a
-- failed fetch. Sheriff Sally Hernandez (tcsheriff.org), Tax Assessor-Collector Celia Israel
-- (tax-office.traviscountytx.gov) and County Treasurer Dolores Ortega Carter each sit on a separate
-- domain from the main county site, and none publishes a portrait of the officeholder. Tracked in
-- .planning/todos/2026-08-18-austin-tx-deep-seed.md.
--
-- Idempotent: politician_images is NOT EXISTS-guarded per (politician_id, url); the UPDATEs are
-- guarded so a re-run changes nothing.

BEGIN;

CREATE TEMP TABLE _hs (
  pid         uuid PRIMARY KEY,
  full_name   text NOT NULL,
  bucket_url  text NOT NULL,
  source_page text NOT NULL,
  license     text NOT NULL
) ON COMMIT DROP;

INSERT INTO _hs (pid, full_name, bucket_url, source_page, license) VALUES
('d3e165d2-27df-4c27-a2b7-807013c20bba', 'Kirk Watson', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d3e165d2-27df-4c27-a2b7-807013c20bba-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('0b0d0019-9c0e-4d92-bb55-6e7740ddbd54', 'Natasha Harper-Madison', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0b0d0019-9c0e-4d92-bb55-6e7740ddbd54-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('061deb47-b0e1-4c55-98e3-3a393a8f2a4d', 'Vanessa Fuentes', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/061deb47-b0e1-4c55-98e3-3a393a8f2a4d-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('f6e876bd-94ee-4105-911c-18d66851b6bd', 'José Velásquez', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f6e876bd-94ee-4105-911c-18d66851b6bd-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('b69491e9-a952-4f51-bb80-cb46c791f8c2', 'José "Chito" Vela', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b69491e9-a952-4f51-bb80-cb46c791f8c2-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('0c16476b-f75d-40e3-a2e9-84c7cc636ed3', 'Ryan Alter', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0c16476b-f75d-40e3-a2e9-84c7cc636ed3-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('9a61967e-9522-43bc-83ed-f00589a12b7e', 'Krista Laine', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9a61967e-9522-43bc-83ed-f00589a12b7e-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('b1e0e5c1-9951-44c2-8141-7ef2088764ba', 'Mike Siegel', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b1e0e5c1-9951-44c2-8141-7ef2088764ba-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('00588388-34f8-40a9-af9f-f756972a186a', 'Paige Ellis', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/00588388-34f8-40a9-af9f-f756972a186a-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('e6904957-1d36-4bc5-9ed4-2b1822c0c804', 'Zohaib "Zo" Qadri', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e6904957-1d36-4bc5-9ed4-2b1822c0c804-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('26371523-dd82-48fa-ab72-2806df7e4523', 'Marc Duchen', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/26371523-dd82-48fa-ab72-2806df7e4523-headshot.jpg', 'https://www.austintexas.gov/government', 'City of Austin official council portrait (austintexas.gov / austin.widen.net DAM, municipal government work, press use)'),
('15b879c0-97bc-4b97-b16c-5534fc4bc330', 'George Morales III', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/15b879c0-97bc-4b97-b16c-5534fc4bc330-headshot.jpg', 'https://www.traviscountytx.gov/commissioners-court/precinct-four', 'Travis County official portrait (traviscountytx.gov, county government work, press use)'),
('e0d9989c-af22-42a5-a6b0-f77073d20386', 'Brigid Shea', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e0d9989c-af22-42a5-a6b0-f77073d20386-headshot.jpg', 'https://www.traviscountytx.gov/commissioners-court/precinct-two', 'Travis County official portrait (traviscountytx.gov, county government work, press use)'),
('193123e1-8c6b-48b4-9581-2305ba4128b2', 'Delia Garza', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/193123e1-8c6b-48b4-9581-2305ba4128b2-headshot.jpg', 'https://www.traviscountytx.gov/county-attorney', 'Travis County Attorney official portrait as published on traviscountytx.gov (county government work, press use; asset filename indicates a League of Women Voters origin — provenance noted, rights not independently confirmed) — 400x499 source, upscaled x1.5, REPLACE'),
('ccaf36cf-65a7-43d4-9f6e-6d8071b5f8bd', 'Ann Howard', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ccaf36cf-65a7-43d4-9f6e-6d8071b5f8bd-headshot.jpg', 'https://www.traviscountytx.gov/commissioners-court/precinct-three', 'Travis County official portrait (traviscountytx.gov, county government work, press use) — 400x400 source, upscaled x1.88, REPLACE'),
('8feee56c-d748-4ad8-9c4c-01a363bf1fc1', 'José Garza', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8feee56c-d748-4ad8-9c4c-01a363bf1fc1-headshot.jpg', 'https://districtattorney.traviscountytx.gov/', 'Travis County District Attorney official portrait (districtattorney.traviscountytx.gov, county government work, press use) — 300x300 source, upscaled x2.5, REPLACE'),
('f7583cbb-70e8-42ee-a0c9-f6e07ca41ec1', 'Jeffrey W. Travillion, Sr.', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f7583cbb-70e8-42ee-a0c9-f6e07ca41ec1-headshot.jpg', 'https://www.traviscountytx.gov/commissioners-court/precinct-one', 'Travis County official portrait (traviscountytx.gov, county government work, press use) — 227x300 source, upscaled x2.64, REPLACE'),
('d0e80e1b-32d3-4b10-9fd1-e90afc412a12', 'Andy Brown', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d0e80e1b-32d3-4b10-9fd1-e90afc412a12-headshot.jpg', 'https://www.traviscountytx.gov/commissioners-court/county-judge', 'Travis County official portrait (traviscountytx.gov, county government work, press use) — 200x266 source, upscaled x3.0, REPLACE'),
('2b65e9a8-23a3-4328-bddb-272bdbf9757a', 'Velva L. Price', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2b65e9a8-23a3-4328-bddb-272bdbf9757a-headshot.jpg', 'https://www.traviscountytx.gov/district-clerk', 'Travis County official portrait (traviscountytx.gov, county government work, press use) — 200x300 source, upscaled x3.0, REPLACE'),
('7000d6cc-4e21-4aa4-a573-d6cbf36caba9', 'Dyana Limon-Mercado', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7000d6cc-4e21-4aa4-a573-d6cbf36caba9-headshot.jpg', 'https://countyclerk.traviscountytx.gov/', 'Travis County Clerk official portrait (countyclerk.traviscountytx.gov, county government work, press use) — 200x300 source, upscaled x3.0, REPLACE');

-- Name check BEFORE writing: every pid must still be the person we cropped. Guards against a
-- politician_id drifting between the seating migration and this one.
DO $$
DECLARE bad text;
BEGIN
  SELECT string_agg(h.full_name || ' != ' || coalesce(p.full_name, '<missing>'), '; ') INTO bad
  FROM _hs h LEFT JOIN essentials.politicians p ON p.id = h.pid
  WHERE p.id IS NULL OR p.full_name <> h.full_name;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'politician_id/full_name mismatch, refusing to attach photos: %', bad;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.pid, h.bucket_url, 'default', h.license
FROM _hs h
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
   WHERE pi.politician_id = h.pid AND pi.url = h.bucket_url
);

-- photo_custom_url must hold the BUCKET url (see the read-path note in the header).
UPDATE essentials.politicians p
   SET photo_custom_url = h.bucket_url
  FROM _hs h
 WHERE p.id = h.pid
   AND coalesce(p.photo_custom_url, '') <> h.bucket_url;

-- photo_origin_url records WHERE THE PHOTO WAS FOUND (a page), which is why it must never be the
-- only thing set.
UPDATE essentials.politicians p
   SET photo_origin_url = h.source_page
  FROM _hs h
 WHERE p.id = h.pid
   AND coalesce(p.photo_origin_url, '') <> h.source_page;

DO $$
DECLARE
  img_ct       int;
  renderable   int;
  soft_flagged int;
  not_bucket   int;
  still_blank  int;
BEGIN
  SELECT count(*) INTO img_ct
    FROM essentials.politician_images pi JOIN _hs h ON h.pid = pi.politician_id
   WHERE pi.url = h.bucket_url;
  IF img_ct <> 20 THEN
    RAISE EXCEPTION 'expected 20 politician_images rows, found %', img_ct;
  END IF;

  -- Assert the RENDERABLE predicate, not merely "a url is present" — the whole point of
  -- photoCoverage.HAS_RENDERABLE_PHOTO_SQL is that a non-empty column is not the same as a
  -- portrait that can paint.
  SELECT count(*) INTO renderable
    FROM _hs h
    JOIN essentials.politicians p ON p.id = h.pid
    LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
   WHERE (img.politician_id IS NOT NULL
          OR btrim(coalesce(p.photo_custom_url, '')) <> ''
          OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%'));
  IF renderable < 20 THEN
    RAISE EXCEPTION 'only % of 20 staged rows satisfy the renderable-photo predicate', renderable;
  END IF;

  -- Every staged row must resolve to the BUCKET, not to a source page.
  SELECT count(*) INTO not_bucket
    FROM _hs h JOIN essentials.politicians p ON p.id = h.pid
   WHERE coalesce(p.photo_custom_url, p.photo_origin_url, '') NOT LIKE '%storage.supabase.co%';
  IF not_bucket <> 0 THEN
    RAISE EXCEPTION '% staged row(s) still resolve to a source page, not the bucket', not_bucket;
  END IF;

  SELECT count(*) INTO soft_flagged
    FROM essentials.politician_images pi JOIN _hs h ON h.pid = pi.politician_id
   WHERE pi.url = h.bucket_url AND pi.photo_license LIKE '%REPLACE%';
  IF soft_flagged <> 7 THEN
    RAISE EXCEPTION 'expected 7 REPLACE-flagged soft portraits, found %', soft_flagged;
  END IF;

  -- The 3 known-absent officials must STILL have no photo. If one of them gained one, a pid was
  -- crossed and somebody else's face just landed on their profile.
  SELECT count(*) INTO still_blank
    FROM essentials.politicians p
    LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
   WHERE p.full_name IN ('Sally Hernandez', 'Celia Israel', 'Dolores Ortega Carter')
     AND img.politician_id IS NULL
     AND btrim(coalesce(p.photo_custom_url, '')) = '';
  IF still_blank <> 3 THEN
    RAISE EXCEPTION 'expected the 3 portrait-less officials to remain blank, found % blank', still_blank;
  END IF;

  RAISE NOTICE 'OK: 20 Austin/Travis portraits attached (13 clean, 7 soft flagged REPLACE); 3 officials remain deliberately blank.';
END $$;

COMMIT;
