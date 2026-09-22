-- CA_0140_monroe_clearcreek_trustee_profiles.sql
--
-- Clear Creek Township Trustee race (Monroe County, IN, Nov 3 2026) profile enrichment, sourced
-- from the Bloomington Chamber of Commerce 2026 voter guide (photos the Phase-2 agents could not
-- reach behind Cloudflare; the image files themselves are directly fetchable). Portraits + websites
-- only. Party never stored.
--
-- ⚠ The Chamber page's ALT-TEXT is scrambled (it mislabels several photos), but the image
-- FILENAMES are reliable — verified by cross-check: dave-hall.jpg is Hall, and amy-oliver.jpg
-- matches our known Amy Oliver photo. Each image used here was also viewed directly.
--
-- WHAT THIS DOES:
--   1. Steve Hinds (R, incumbent trustee candidate; politician ca5f69c1) — sets his portrait
--      (dual write photo_custom_url + politician_images + card photo_url), image pre-hosted in the
--      bucket. He already has a website.
--   2. Susan Luther (D; race_candidate 2aedf86c was name-only/unlinked) — links it to her existing
--      seeded record "Susan Kay Luther" (ba1e…0009), and sets her website to her campaign Facebook
--      page (urls empty -> set; + card website_url).
--      🔴 Her photo is DELIBERATELY LEFT ALONE: ba1e…0009 has photo_custom_url_manual_override=TRUE
--         (someone is curating her portrait by hand — D-08). A Chamber photo of her exists but is
--         intentionally NOT imported here.
--
-- Ordering: politician fields set before the rc link so the mig-775 mirror trigger no-ops.
-- Idempotent: NOT EXISTS / empty-only / IS DISTINCT guards.

BEGIN;

-- ── pre-flight gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  -- Hinds rc + politician exist on the target election
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
   WHERE rc.id='ac336db7-9055-4909-8971-2cccd2fdb12e' AND r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'
     AND rc.politician_id='ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d';
  IF n<>1 THEN RAISE EXCEPTION 'Hinds rc not linked to expected politician on election (found %)', n; END IF;

  -- Hinds portrait target not hand-locked
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id='ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d' AND photo_custom_url_manual_override IS TRUE;
  IF n<>0 THEN RAISE EXCEPTION 'Hinds portrait is manual-override locked — aborting'; END IF;

  -- Luther rc exists on the target election; her link-target politician exists
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
   WHERE rc.id='2aedf86c-39ce-4461-baf9-8cceddc65a1e' AND r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c';
  IF n<>1 THEN RAISE EXCEPTION 'Luther rc not on target election (found %)', n; END IF;
  SELECT count(*) INTO n FROM essentials.politicians WHERE id='ba1e0001-2026-4000-8000-000000000009';
  IF n<>1 THEN RAISE EXCEPTION 'Luther link-target politician missing'; END IF;
END $$;

-- ── 1. Hinds portrait (dual write) ───────────────────────────────────────────────────────────
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d-headshot.jpg',
       'default','press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id='ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d');

UPDATE essentials.politicians
SET photo_custom_url='https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d-headshot.jpg',
    photo_origin_url='https://www.chamberbloomington.org/2026-election-candidates.html'
WHERE id='ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d'
  AND photo_custom_url_manual_override IS NOT TRUE
  AND coalesce(photo_custom_url,'')='' AND coalesce(photo_origin_url,'')='';

UPDATE essentials.race_candidates
SET photo_url='https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d-headshot.jpg'
WHERE id='ac336db7-9055-4909-8971-2cccd2fdb12e' AND coalesce(photo_url,'')='';

-- ── 2. Luther: website on politician (NOT photo — override respected) ─────────────────────────
UPDATE essentials.politicians
SET urls = ARRAY['https://www.facebook.com/profile.php?id=61587744325986']
WHERE id='ba1e0001-2026-4000-8000-000000000009'
  AND coalesce(array_length(urls,1),0)=0 AND coalesce(web_form_url,'')='';

-- link the name-only Luther race_candidate to her existing record
UPDATE essentials.race_candidates
SET politician_id='ba1e0001-2026-4000-8000-000000000009'
WHERE id='2aedf86c-39ce-4461-baf9-8cceddc65a1e' AND politician_id IS NULL;

UPDATE essentials.race_candidates
SET website_url='https://www.facebook.com/profile.php?id=61587744325986'
WHERE id='2aedf86c-39ce-4461-baf9-8cceddc65a1e' AND coalesce(website_url,'')='';

-- ── post-verify gate ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_img int; n_custom int; n_rcphoto int; n_link int; n_url int; n_rcsite int; n_lockphoto int;
BEGIN
  SELECT count(*) INTO n_img FROM essentials.politician_images
   WHERE politician_id='ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d' AND url LIKE '%ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d-headshot.jpg';
  IF n_img<>1 THEN RAISE EXCEPTION 'expected Hinds image row, found %', n_img; END IF;
  SELECT count(*) INTO n_custom FROM essentials.politicians
   WHERE id='ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d' AND photo_custom_url LIKE '%storage.supabase.co%';
  IF n_custom<>1 THEN RAISE EXCEPTION 'expected Hinds photo_custom_url, found %', n_custom; END IF;
  SELECT count(*) INTO n_rcphoto FROM essentials.race_candidates
   WHERE id='ac336db7-9055-4909-8971-2cccd2fdb12e' AND coalesce(photo_url,'')<>'';
  IF n_rcphoto<>1 THEN RAISE EXCEPTION 'expected Hinds card photo, found %', n_rcphoto; END IF;

  SELECT count(*) INTO n_link FROM essentials.race_candidates
   WHERE id='2aedf86c-39ce-4461-baf9-8cceddc65a1e' AND politician_id='ba1e0001-2026-4000-8000-000000000009';
  IF n_link<>1 THEN RAISE EXCEPTION 'expected Luther linked, found %', n_link; END IF;
  SELECT count(*) INTO n_url FROM essentials.politicians
   WHERE id='ba1e0001-2026-4000-8000-000000000009' AND coalesce(array_length(urls,1),0)>0;
  IF n_url<>1 THEN RAISE EXCEPTION 'expected Luther website, found %', n_url; END IF;
  SELECT count(*) INTO n_rcsite FROM essentials.race_candidates
   WHERE id='2aedf86c-39ce-4461-baf9-8cceddc65a1e' AND coalesce(website_url,'')<>'';
  IF n_rcsite<>1 THEN RAISE EXCEPTION 'expected Luther card website, found %', n_rcsite; END IF;

  -- assert we did NOT set a photo on the override-locked Luther record
  SELECT count(*) INTO n_lockphoto FROM essentials.politicians
   WHERE id='ba1e0001-2026-4000-8000-000000000009' AND coalesce(photo_custom_url,'')<>'';
  IF n_lockphoto<>0 THEN RAISE EXCEPTION 'Luther photo was set despite override lock — aborting'; END IF;

  RAISE NOTICE 'ok CA_0140: Hinds portrait set; Luther linked + FB website (photo lock respected)';
END $$;

COMMIT;
