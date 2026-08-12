-- 1708_massachusetts_legislature_headshots.sql
--
-- Portraits for the 5 Massachusetts state legislators in the headshot backlog: 3 House members
-- and 2 Senators, all at 1000px — large enough that reaching 600x750 DOWNSCALES them, the best
-- source quality in the program so far.
--
-- Massachusetts listed 118 real officeholders (zero candidate contamination, checked against
-- essentials.politician_occupancy_evidence), 37 of them carrying researched stances. Only these
-- 5 are imported, and the reason is a finding rather than a shortfall — see below.
--
-- HOW THE STATE ROWS WERE FOUND. malegislature.gov encodes the image width in the PATH:
-- /Legislators/Profile/70/DMR1.jpg is a 70x107 thumbnail and /Legislators/Profile/1000/DMR1.jpg
-- is the same portrait at 1000x1535. Same trick class as the wsimg / Wix / Next.js strips.
--
-- 🔴 THE BUG THAT HID THIS FOR TWO FULL PASSES: the harvester required images to be at least
-- 120x120. Massachusetts rosters serve 70x107 thumbnails, so every legitimate portrait was
-- silently discarded and the wave returned 0 of 118 twice over. A filter bug and an empty site
-- are indistinguishable in a log. Lower the floor, THEN judge the source.
--
-- WHY THE OTHER 113 ARE NOT HERE. A search-driven URL pass replaced every guessed roster path
-- with the real one, then each was opened in a browser and its images inspected:
--   Newton council      — all 25 names, zero portraits (spacer GIFs and nav chrome only)
--   Waltham /1341/      — all 11 names, images are site logo, search icon, footer logo, socials
--   Fall River          — 9 of 10 names, single 3000x1621 banner
--   Medford council     — 8 of 13 names, single 800x450 banner
--   Quincy              — 21 images, none portrait-shaped
--   Newton Schools      — courtyard photo, a careers ad, city hall, calendar icons
--   Medford Schools     — one "Website Cover Photo"
--   Lynn Schools        — 3 images, none portrait-shaped
--   Lowell              — city logo plus social icons
-- Massachusetts municipal and school-committee rosters publish NAMES WITHOUT FACES. That is a
-- property of the sources, established by inspection, not an inference from a failed crawl.
-- Genuinely unresolved: New Bedford (11 targets) answers 403 even to a real browser.
--
-- The contact-sheet review rejected 1 of 6 candidates: Ziqiang Yuan (Quincy) matched cleanly and
-- resolved to a BLANK WHITE 64x64 image.
--
-- Sets BOTH photo_custom_url and photo_origin_url: the read path is
-- COALESCE(photo_custom_url, photo_origin_url, ''), so writing only the origin renders broken.
--
-- Idempotent: re-running inserts nothing and updates nothing.

BEGIN;

CREATE TEMP TABLE _ma_headshots (
  politician_id uuid PRIMARY KEY,
  bucket_url    text NOT NULL,
  source_page   text NOT NULL,
  license       text NOT NULL
) ON COMMIT DROP;

INSERT INTO _ma_headshots (politician_id, bucket_url, source_page, license) VALUES
  ('2c5eb897-6ea2-4f1c-ba6e-eadc8539914e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2c5eb897-6ea2-4f1c-ba6e-eadc8539914e-headshot.jpg', 'https://malegislature.gov/Legislators/Members/House', 'press_use'),
  ('81dbc898-213c-4789-8c0d-59fd6faa1202'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81dbc898-213c-4789-8c0d-59fd6faa1202-headshot.jpg', 'https://malegislature.gov/Legislators/Members/House', 'press_use'),
  ('81a138f1-805e-46e0-ae95-e75c2211f6ea'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81a138f1-805e-46e0-ae95-e75c2211f6ea-headshot.jpg', 'https://malegislature.gov/Legislators/Members/House', 'press_use'),
  ('a6b82d2e-d562-4ca6-a09b-a396d45cf1a7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a6b82d2e-d562-4ca6-a09b-a396d45cf1a7-headshot.jpg', 'https://malegislature.gov/Legislators/Members/Senate', 'press_use'),
  ('215462b8-ddd2-4a38-bcca-b5f240944479'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/215462b8-ddd2-4a38-bcca-b5f240944479-headshot.jpg', 'https://malegislature.gov/Legislators/Members/Senate', 'press_use');

DO $$
DECLARE n_missing int; n_override int; n_placeholder int;
BEGIN
  SELECT count(*) INTO n_missing FROM _ma_headshots t
  LEFT JOIN essentials.politicians p ON p.id = t.politician_id WHERE p.id IS NULL;
  IF n_missing <> 0 THEN
    RAISE EXCEPTION 'aborting: % target politicians no longer exist', n_missing;
  END IF;

  SELECT count(*) INTO n_override FROM _ma_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) carry photo_custom_url_manual_override', n_override;
  END IF;

  SELECT count(DISTINCT t.politician_id) INTO n_placeholder
  FROM _ma_headshots t
  JOIN essentials.politician_occupancy_evidence e ON e.politician_id = t.politician_id
  WHERE e.is_placeholder_occupancy;
  IF n_placeholder <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) are placeholder occupancies, not officeholders',
      n_placeholder;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT t.politician_id, t.bucket_url, 'default', t.license
FROM _ma_headshots t
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                  WHERE pi.politician_id = t.politician_id AND pi.url = t.bucket_url);

UPDATE essentials.politicians p
SET photo_custom_url = t.bucket_url,
    photo_origin_url = t.source_page
FROM _ma_headshots t
WHERE p.id = t.politician_id
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND (p.photo_custom_url IS DISTINCT FROM t.bucket_url
    OR p.photo_origin_url IS DISTINCT FROM t.source_page);

DO $$
DECLARE n_img int; n_custom int; n_render int;
BEGIN
  SELECT count(*) INTO n_img FROM _ma_headshots t
  JOIN essentials.politician_images pi
    ON pi.politician_id = t.politician_id AND pi.url = t.bucket_url;
  IF n_img <> 5 THEN RAISE EXCEPTION 'expected 5 image rows, found %', n_img; END IF;

  SELECT count(*) INTO n_custom FROM _ma_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url = t.bucket_url
    AND p.photo_custom_url LIKE '%storage.supabase.co%';
  IF n_custom <> 5 THEN
    RAISE EXCEPTION 'expected 5 rows with photo_custom_url on the bucket, found %', n_custom;
  END IF;

  -- HAS_RENDERABLE_PHOTO_SQL, copied from backend/src/lib/photoCoverage.ts verbatim
  SELECT count(*) INTO n_render FROM _ma_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_render < 5 THEN
    RAISE EXCEPTION 'only % of 5 satisfy HAS_RENDERABLE_PHOTO_SQL', n_render;
  END IF;

  RAISE NOTICE 'ok: 5 Massachusetts legislators renderable';
END $$;

COMMIT;
