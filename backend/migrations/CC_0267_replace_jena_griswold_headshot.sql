-- CC_0267_replace_jena_griswold_headshot.sql
--
-- Replaces the published headshot of Jena Griswold (31667cca-d1c9-43f5-bc82-45312793aad0),
-- Colorado Secretary of State and the 2026 Democratic candidate for Attorney General.
--
-- WHY. CC_0266 linked her candidacy to her politician row, which put her photograph onto the
-- Attorney General ballot page as well as her profile. The photograph was a defect: a
-- near-profile, mid-speech press frame -- mouth open, eyes off camera, a microphone across
-- the lower left. It scores 0.920 on the YuNet face gate and passes every automated check we
-- own. Only looking at it caught it. Operator ruled 2026-10-19 to replace it.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE SOURCE THE OPERATOR APPROVED WAS NOT THE SOURCE USED, AND THE REASON IS A LICENCE.
--
-- The option put to the operator was the official portrait on the Colorado Secretary of
-- State's own biography page (coloradosos.gov/pubs/images/Griswold.png, alt="Jena Griswold").
-- It is the correct picture -- front-facing, eyes to camera, scores 0.948 -- but it is
-- 250x376, so our 600x750 would have been a 2.4x ENLARGEMENT. The operator accepted that
-- trade. It was then NOT used, because the licence does not permit it.
--
-- coloradosos.gov PUBLISHES a policy (coloradosos.gov/pubs/info_center/terms.html). This is
-- not the "site is silent, and silence is not a grant" case recorded elsewhere in this
-- column -- it is an express reservation, and it names images twice:
--
--   Copyright:    "Some of the publications made available on this website are the
--                  intellectual property of the Colorado Secretary of State, and are
--                  protected by applicable law and may not be reproduced, in whole or in
--                  part, without the prior written permission of the Colorado Secretary of
--                  State."
--   Terms of use: "Use of computerized 'robots' or 'data mining' of the information and
--                  images presented here is prohibited."
--
-- ⚠ So the state office whose own portrait of its own officeholder this is reserves the right
-- to it and forbids the automated retrieval we would use to get it. We do not take it.
-- ⚠ AND THE CHECK CAME TOO LATE: the option was offered to the operator BEFORE the terms were
-- read. The licence belongs in the shortlist, not in the implementation.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- WHAT IS PUBLISHED INSTEAD, AND WHY IT IS BETTER ON EVERY AXIS.
--
-- Her own campaign's portrait, from jenaforcolorado.com -- the candidate publishing her own
-- photograph, which is press_use by the same convention that covers ~4,500 rows in this
-- column. Served through the campaign's imgix account:
--   https://run.imgix.net/1e37d20f-4e35-4f4e-89f8-d4c0ffba61da/
--     30266a04-72c3-41c7-aacd-29132448906b/30266a04-72c3-41c7-aacd-29132448906b.jpeg
-- Native 2301x2051. It is the home page hero on her campaign site.
--
-- 🔴 THE BARE IMGIX URL SERVES A RECOMPRESSED FILE, NOT THE ORIGINAL. Fetched with no query
-- string it returns 425,088 bytes at Laplacian variance 64.4. The SAME pixel dimensions
-- requested as `?q=100&fm=jpg&w=2301` return 1,870,983 bytes at variance 128.5 -- twice the
-- detail. imgix's own `?fm=json` reports the original as 3,115,763 bytes, which is how the
-- gap was noticed. The crop below is taken from the q=100 render.
-- ⚠ This is the "the resize can be in the query string" rule running backwards: the query
-- string is also where the quality LOSS hides, and a bare URL is not evidence of an original.
--
-- CROP GEOMETRY, MEASURED AND NOT EYEBALLED (house rule). YuNet located the face at native
-- resolution; everything below is derived from that box, not chosen by eye:
--   face box      x=952 y=517 w=413 h=522   eye line y=705   eye centre x=1192
--   head          hair top 335 -> chin 1040 = 705px
--   crop          (706, 194) to (1679, 1410) = 973x1216, ratio 0.8002 (target 0.8000)
--   head share    58.0% of the crop height          (target 58%)
--   eye line      42.0% down the crop               (target 42%)
--   headroom      140px above the hair = 0.90 ear heights   (house rule: about 1 ear)
--   skin centroid 43.2% across the eye band         (target ~50%; the eyes are centred by
--                 construction, the centroid sits left because her hair falls to one side)
--   monochrome    no -- chroma 44.2, neutral share 0.11
--
-- 🟢 AND IT IS A DOWNSCALE, NOT AN UPSCALE. 973x1216 -> 600x750 is x0.617. The enlargement
-- the operator agreed to accept is not needed: this source is large enough that the finished
-- frame loses nothing. Final face score 0.954 at rotation 0, eye angle -0.4 degrees.
--
-- ⚠ WHAT THE CONTACT SHEET CAUGHT. jenaforcolorado.com also serves three large lifestyle
-- photographs -- a family with a dog, a group outside a house, people at a picnic table --
-- that are STOCK and are not Griswold. Their alt text is generic ("hero image",
-- "Introductory photo", "Announcement photo"), so nothing but looking distinguishes them from
-- the real portraits. This is the bb-fireman-headshot.jpg trap again, on a different site:
-- a plausible image file on the candidate's own domain that is not the candidate.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE URL GAINS A ?v= CACHE KEY. The object is overwritten in place with x-upsert, and an
-- x-upsert overwrite does NOT reliably change what the CDN serves. Both the bare URL and the
-- ?v= URL were fetched after upload and both returned sha256 9a89f5672f75322f, matching the
-- bytes uploaded -- but that is one edge answering at one moment, not a guarantee for every
-- edge and every browser cache that already holds the old file. The version key makes it
-- certain. 37 rows in this column already carry a query string, so this is the house pattern.
--
-- Written to BOTH places, because they are read by different code paths: the grid reads
-- images[] first, the backend reads the scalar.
--   essentials.politician_images.url     (type='default')
--   essentials.politicians.photo_custom_url
-- photo_origin_url is also set -- it was NULL, which is the gap other rows in this column
-- record as the reason a licence claim could not be checked later.
--
-- ▶ race_candidates.photo_url is NULL on her candidacy row and STAYS NULL, so the Attorney
-- General ballot page reaches this image through the COALESCE. Nothing to clear.
-- ▶ The old frame (Jeffrey Beall, CC BY 4.0, Wikimedia Commons) is not deleted from storage;
-- it is simply no longer referenced, having been overwritten at the same object path.
--
-- Idempotent: re-running changes nothing.

BEGIN;

-- Guard: exactly one default image, currently the old URL or already the new one, and the
-- person is who this migration researched.
DO $$
DECLARE v_name text; v_imgs int; v_url text; v_custom text;
  c_new CONSTANT text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31667cca-d1c9-43f5-bc82-45312793aad0-headshot.jpg?v=20261019';
  c_old CONSTANT text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31667cca-d1c9-43f5-bc82-45312793aad0-headshot.jpg';
BEGIN
  SELECT p.full_name, p.photo_custom_url INTO v_name, v_custom
    FROM essentials.politicians p WHERE p.id = '31667cca-d1c9-43f5-bc82-45312793aad0'::uuid;
  IF v_name IS NULL THEN
    RAISE EXCEPTION 'CC_0267: the politician row does not exist';
  END IF;
  IF v_name <> 'Jena Griswold' THEN
    RAISE EXCEPTION 'CC_0267: politician resolves to "%", expected "Jena Griswold"', v_name;
  END IF;

  SELECT count(*) INTO v_imgs FROM essentials.politician_images pi
   WHERE pi.politician_id = '31667cca-d1c9-43f5-bc82-45312793aad0'::uuid AND pi.type = 'default';
  IF v_imgs <> 1 THEN
    RAISE EXCEPTION 'CC_0267: she has % default images, expected 1', v_imgs;
  END IF;

  SELECT pi.url INTO v_url FROM essentials.politician_images pi
   WHERE pi.politician_id = '31667cca-d1c9-43f5-bc82-45312793aad0'::uuid AND pi.type = 'default';
  IF v_url NOT IN (c_old, c_new) THEN
    RAISE EXCEPTION 'CC_0267: her default image is "%", which is neither the frame this '
                    'migration replaces nor the one it writes - something else has changed '
                    'it, REFUSING', v_url;
  END IF;
  IF v_custom IS NOT NULL AND v_custom NOT IN (c_old, c_new) THEN
    RAISE EXCEPTION 'CC_0267: photo_custom_url is "%", unexpected - REFUSING', v_custom;
  END IF;
END $$;

-- 1. the rendered image row (the grid reads this first)
UPDATE essentials.politician_images pi
SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31667cca-d1c9-43f5-bc82-45312793aad0-headshot.jpg?v=20261019',
    photo_license = 'Campaign portrait published on her own campaign site, jenaforcolorado.com, as the home page hero (candidate campaign, press_use). Served via the campaign''s imgix account, asset 30266a04-72c3-41c7-aacd-29132448906b, native 2301x2051; fetched at ?q=100 because the bare URL returns a recompressed file at half the detail. Cropped 4:5 to 973x1216 on measured face geometry, then DOWNSCALED x0.617 to 600x750 -- nothing enlarged, nothing composited. Replaces a Wikimedia Commons frame (Jeffrey Beall, CC BY 4.0) that was a near-profile mid-speech photograph with a microphone in shot; it scored 0.920 on the face gate and passed every automated check. The Colorado Secretary of State''s own official portrait was preferred but is NOT usable: coloradosos.gov expressly reserves reproduction without prior written permission and prohibits automated retrieval of its images.'
WHERE pi.politician_id = '31667cca-d1c9-43f5-bc82-45312793aad0'::uuid
  AND pi.type = 'default';

-- 2. the scalar the backend reads, plus the provenance that was missing
UPDATE essentials.politicians p
SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31667cca-d1c9-43f5-bc82-45312793aad0-headshot.jpg?v=20261019',
    photo_origin_url = 'https://run.imgix.net/1e37d20f-4e35-4f4e-89f8-d4c0ffba61da/30266a04-72c3-41c7-aacd-29132448906b/30266a04-72c3-41c7-aacd-29132448906b.jpeg'
WHERE p.id = '31667cca-d1c9-43f5-bc82-45312793aad0'::uuid;

-- post-verify
DO $$
DECLARE v_url text; v_custom text; v_origin text; n_rc int;
  c_new CONSTANT text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31667cca-d1c9-43f5-bc82-45312793aad0-headshot.jpg?v=20261019';
BEGIN
  SELECT pi.url INTO v_url FROM essentials.politician_images pi
   WHERE pi.politician_id = '31667cca-d1c9-43f5-bc82-45312793aad0'::uuid AND pi.type = 'default';
  SELECT p.photo_custom_url, p.photo_origin_url INTO v_custom, v_origin
    FROM essentials.politicians p WHERE p.id = '31667cca-d1c9-43f5-bc82-45312793aad0'::uuid;

  IF v_url IS DISTINCT FROM c_new THEN
    RAISE EXCEPTION 'CC_0267: politician_images.url is "%", expected the versioned URL', v_url;
  END IF;
  -- 🔴 BOTH, or the grid and the backend disagree about what her face is
  IF v_custom IS DISTINCT FROM c_new THEN
    RAISE EXCEPTION 'CC_0267: photo_custom_url is "%", expected the versioned URL', v_custom;
  END IF;
  IF v_origin IS NULL THEN
    RAISE EXCEPTION 'CC_0267: photo_origin_url is still NULL - the licence claim would be '
                    'uncheckable later, which is the defect other rows in this column record';
  END IF;

  -- the ballot page must still reach the image through the COALESCE, not around it
  SELECT count(*) INTO n_rc FROM essentials.race_candidates rc
   WHERE rc.politician_id = '31667cca-d1c9-43f5-bc82-45312793aad0'::uuid
     AND rc.photo_url IS NOT NULL;
  IF n_rc <> 0 THEN
    RAISE EXCEPTION 'CC_0267: % of her candidacy rows now carry their own photo_url, which '
                    'would OUTRANK this image on the ballot page', n_rc;
  END IF;

  RAISE NOTICE 'CC_0267 OK - Griswold now publishes her campaign portrait, both columns agree';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: READ THE LICENCE BEFORE YOU OFFER THE OPTION, NOT BEFORE YOU WRITE THE CODE.
-- The operator approved a 2.4x enlargement as the price of a correct portrait. The price was
-- never payable -- the source reserves its images and bars automated retrieval -- and the
-- better source, which needed no enlargement at all, was one search away. Offering an
-- unlicensable option spends the operator's decision on a choice that did not exist.
-- ⚠ A GOVERNMENT SITE IS NOT AUTOMATICALLY A PERMISSIVE ONE. "Official" is an argument about
-- provenance, not about rights. coloradosos.gov is a state office publishing its own
-- officeholder's portrait and it still says no.
-- ⚠ A BARE CDN URL IS NOT THE ORIGINAL. imgix served half the detail with no query string and
-- said so itself under ?fm=json. Ask the host what the original is before cropping from it.
-- ───────────────────────────────────────────────────────────────────────────────────────────
