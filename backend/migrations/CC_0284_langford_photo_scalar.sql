-- CC_0284_langford_photo_scalar.sql
--
-- Points Joy Langford's photo scalar at the portrait of her that is ALREADY in our bucket.
-- She is Director, Division 1, on the Board of Directors of the Water Replenishment District
-- of Southern California (politician e569ab1d-d9cf-5364-82c8-faaca133921e).
--
-- No new image is published here. The picture below already renders on her compass page. This
-- migration only makes the OTHER read paths reach it.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- WHY. The nightly `headshot faces` job failed three consecutive nights (2026-10-22, -23, -24)
-- with one flag, and the flag was correct:
--
--   NEW  UNDECODABLE  best=0.00  Joy Langford  [profile]  https://www.wrd.org/board-profiles
--
-- It scored 0.00 because there is nothing to decode. That URL is not an image. Fetched
-- 2026-10-24 it answers `200, content-type: text/html, 105,066 bytes` -- it is the WRD board
-- INDEX PAGE. It sat in essentials.politicians.photo_origin_url, which every read path treats
-- as an image URL.
--
-- 🔴 SO THIS WAS A LIVE BROKEN IMAGE, NOT A DETECTOR ARTEFACT. photo_custom_url is NULL, so
-- the scalar falls through to photo_origin_url, and the COALESCE in
--   backend/src/lib/districtQueries.ts:51
--   backend/src/lib/essentialsBrowseService.ts            (eight sites)
--   backend/src/lib/campaignFinanceSearchService.ts:100
-- is COALESCE(photo_custom_url, photo_origin_url, '') with NO pi.url in the chain. Those pages
-- emitted <img src="https://www.wrd.org/board-profiles">. Only compassService.ts (lines 425 and
-- 550) puts pi.url in the chain, which is why she looked fine there and nowhere else.
-- ⚠ essentialsBodiesService.ts:110 does fall back to politician_images -- but only AFTER
-- `CASE WHEN p.photo_origin_url LIKE 'http%' THEN p.photo_origin_url END`, which the page URL
-- matches. So it was broken there too. The images[] fallback never got a turn.
--
-- This is the house rule firing exactly as written: THE GRID READS images[] FIRST, THE BACKEND
-- READS THE SCALAR. The two disagreed, and the scalar won on every page a voter is likely to
-- land on.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- WHAT WAS VERIFIED BEFORE WRITING THIS, because "there is already an image row" is not
-- evidence that the image is any good.
--
-- The bucket object e569ab1d-...-headshot.jpg was fetched (200, image/jpeg, 59,125 bytes,
-- 464x580) and LOOKED AT. It is a single front-facing portrait, eyes to camera, correctly
-- framed, portrait aspect, in colour. Not a seal, not a map, not a torso, not a vignette.
--
-- 🔴 AND IT WAS CHECKED THAT IT IS HER, because a plausible wrong face is the failure a contact
-- sheet cannot catch. The WRD board page's card for her links /director-joy-langford and
-- carries this image, with per-image alt text:
--   "A woman with long, wavy hair smiles in a professional outfit, posed against a softly
--    blurred background."
-- That matches the frame we hold and names nobody else. (An alt naming a different person
-- OUTVOTES the page -- this one does not.)
--
-- NO BETTER SOURCE EXISTS, and that was measured rather than assumed. The board page serves the
-- portrait through imgix at ?w=720&h=720&fit=max. `fit=max` never upscales, and it returns
-- 532x580 -- the SAME height as our 464x580 copy, merely wider. So our frame is already at full
-- source height and is simply cropped tighter. There is no larger original to re-crop from.
-- ⚠ imgix's own ?fm=json could NOT be used to confirm the native size: this account signs its
-- URLs, and changing the parameters invalidates the signature (`403 sig_invalid`). The fit=max
-- ceiling is the evidence instead.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- WHAT CHANGES, AND WHY photo_origin_url IS CORRECTED RATHER THAN CLEARED.
--
--   photo_custom_url  NULL  ->  the bucket object (what every read path will now serve)
--   photo_origin_url  the board INDEX PAGE  ->  the imgix asset that page publishes for her
--
-- Setting photo_custom_url alone would be enough to turn the gate green, because the COALESCE
-- never reaches the second column again. That is precisely why the second column must not be
-- left holding an HTML page: the landmine would be invisible, and the next person to clear
-- photo_custom_url would reintroduce this exact defect with nothing to warn them. It is how
-- she got here.
--
-- Clearing it to NULL was the other option and is rejected: CC_0267's post-verify refuses a
-- NULL photo_origin_url on the ground that the licence claim becomes uncheckable later, and
-- that reasoning applies unchanged here.
--
-- 🔴 THE PROVENANCE URL MUST CARRY ITS SIGNATURE OR IT IS A DEAD LINK. The bare asset path
-- returns `403 sig_invalid`; only the signed form the page itself emits resolves. The signed
-- URL is therefore stored whole. If WRD ever rotates the signature it will 403 -- harmless,
-- because with photo_custom_url set nothing renders from this column, and the asset path still
-- identifies the file. A 403 on a provenance URL is a worse record than a live one and a far
-- better one than a page that was never an image.
--
-- NOT TOUCHED:
-- ▶ politician_images.url and photo_license ('press_use') are already correct. The image is not
--   being replaced, so no new licence decision arises -- WRD already publishes this portrait of
--   its own director and we already serve it.
-- ▶ race_candidates.photo_url -- she has no candidacy rows at all (verified: 0). The column
--   that outranks everything on ballot pages is empty for her, so there is nothing to clear.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ OUT OF SCOPE, DELIBERATELY. The same query found exactly one other row in this class:
-- Joseph G Husk (85194f5e-6574-4371-97da-f1cc89568870), active incumbent, photo_custom_url
-- NULL, a good verified portrait in politician_images, and BOTH scalars NULL -- so he renders
-- blank rather than broken, which is why no gate flags him. His default image is filed under a
-- DIFFERENT uuid (04d2e529-...), the signature of a person merge. He belongs to reserved slot
-- 1937 ("merge 6 officeholder/candidate person splits ... Husk IN") and is left alone here;
-- fixing his scalar before that merge decides which row survives would be work done twice.
--
-- Idempotent: re-running changes nothing.

BEGIN;

-- Guard: she exists, is who this migration researched, has exactly the one image row it
-- inspected, and nothing has already moved the scalar somewhere unexpected.
DO $$
DECLARE v_name text; v_imgs int; v_url text; v_custom text; v_origin text; n_rc int;
  c_bucket CONSTANT text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e569ab1d-d9cf-5364-82c8-faaca133921e-headshot.jpg';
  c_page   CONSTANT text := 'https://www.wrd.org/board-profiles';
  c_imgix  CONSTANT text := 'https://streamline.imgix.net/fdb1e6f8-7a76-48e6-8d7a-02f9bbc2e2d1/ef897800-70d6-4ddb-9058-bb3183dfd8c4/board1.jpg?ixlib=rb-1.1.0&or=0&w=720&h=720&fit=max&auto=format%2Ccompress&s=e9a117e2232a16e9ed0dbbf7c5a24679';
BEGIN
  SELECT p.full_name, p.photo_custom_url, p.photo_origin_url
    INTO v_name, v_custom, v_origin
    FROM essentials.politicians p WHERE p.id = 'e569ab1d-d9cf-5364-82c8-faaca133921e'::uuid;

  IF v_name IS NULL THEN
    RAISE EXCEPTION 'CC_0284: the politician row does not exist';
  END IF;
  IF v_name <> 'Joy Langford' THEN
    RAISE EXCEPTION 'CC_0284: politician resolves to "%", expected "Joy Langford"', v_name;
  END IF;

  SELECT count(*) INTO v_imgs FROM essentials.politician_images pi
   WHERE pi.politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e'::uuid AND pi.type = 'default';
  IF v_imgs <> 1 THEN
    RAISE EXCEPTION 'CC_0284: she has % default images, expected 1 - this migration assumes '
                    'the single row it inspected', v_imgs;
  END IF;

  -- 🔴 THE WHOLE POINT OF THE CHANGE IS THAT THIS ROW IS GOOD. If it is not the frame that was
  -- fetched and looked at, pointing the scalar at it would publish something unverified.
  SELECT pi.url INTO v_url FROM essentials.politician_images pi
   WHERE pi.politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e'::uuid AND pi.type = 'default';
  IF v_url IS DISTINCT FROM c_bucket THEN
    RAISE EXCEPTION 'CC_0284: her default image is "%", not the frame this migration verified '
                    '- REFUSING to point the scalar at an unexamined image', v_url;
  END IF;

  IF v_custom IS NOT NULL AND v_custom IS DISTINCT FROM c_bucket THEN
    RAISE EXCEPTION 'CC_0284: photo_custom_url is already "%", which is neither NULL nor the '
                    'bucket object - somebody else has set it, REFUSING', v_custom;
  END IF;
  IF v_origin IS DISTINCT FROM c_page AND v_origin IS DISTINCT FROM c_imgix THEN
    RAISE EXCEPTION 'CC_0284: photo_origin_url is "%", neither the board page this migration '
                    'corrects nor the imgix asset it writes - REFUSING', v_origin;
  END IF;

  -- The ballot column outranks both of the above on election pages. It must stay empty.
  SELECT count(*) INTO n_rc FROM essentials.race_candidates rc
   WHERE rc.politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e'::uuid
     AND rc.photo_url IS NOT NULL;
  IF n_rc <> 0 THEN
    RAISE EXCEPTION 'CC_0284: % candidacy row(s) now carry their own photo_url, which would '
                    'OUTRANK this image on ballot pages - unexpected, REFUSING', n_rc;
  END IF;
END $$;

-- The scalar the backend reads, and the provenance corrected from a page to the image.
UPDATE essentials.politicians p
SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e569ab1d-d9cf-5364-82c8-faaca133921e-headshot.jpg',
    photo_origin_url = 'https://streamline.imgix.net/fdb1e6f8-7a76-48e6-8d7a-02f9bbc2e2d1/ef897800-70d6-4ddb-9058-bb3183dfd8c4/board1.jpg?ixlib=rb-1.1.0&or=0&w=720&h=720&fit=max&auto=format%2Ccompress&s=e9a117e2232a16e9ed0dbbf7c5a24679'
WHERE p.id = 'e569ab1d-d9cf-5364-82c8-faaca133921e'::uuid;

-- post-verify
DO $$
DECLARE v_custom text; v_origin text; v_served text; n_other int; v_names text;
  c_bucket CONSTANT text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e569ab1d-d9cf-5364-82c8-faaca133921e-headshot.jpg';
BEGIN
  SELECT p.photo_custom_url, p.photo_origin_url,
         NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '')
    INTO v_custom, v_origin, v_served
    FROM essentials.politicians p WHERE p.id = 'e569ab1d-d9cf-5364-82c8-faaca133921e'::uuid;

  IF v_custom IS DISTINCT FROM c_bucket THEN
    RAISE EXCEPTION 'CC_0284: photo_custom_url is "%", expected the bucket object', v_custom;
  END IF;

  -- 🔴 THE END STATE THE GATE ACTUALLY READS, asserted in the gate's own shape rather than
  -- inferred from the UPDATE having run. check-headshot-faces.py --external-only selects on
  -- COALESCE(photo_custom_url, photo_origin_url) NOT LIKE the bucket path, and zero rows is
  -- the pass condition.
  IF v_served NOT LIKE '%supabase.co/storage/v1/object/public/%' THEN
    RAISE EXCEPTION 'CC_0284: the scalar still serves "%", which the nightly headshot gate '
                    'will flag as an off-site link', v_served;
  END IF;

  -- The landmine check: the second column must no longer hold a non-image.
  IF v_origin IS NULL OR v_origin LIKE 'https://www.wrd.org/board-profiles%' THEN
    RAISE EXCEPTION 'CC_0284: photo_origin_url is "%", still the board page (or cleared) - the '
                    'defect would return the moment photo_custom_url is cleared', v_origin;
  END IF;

  -- ⚠ WARNING, NOT AN EXCEPTION, AND ON PURPOSE. Any OTHER active politician serving an
  -- off-site link also reddens the nightly, but it is not this migration's row and refusing
  -- here would roll back a correct fix over somebody else's drift. Report it loudly instead.
  SELECT count(*), coalesce(string_agg(p.full_name, ', ' ORDER BY p.full_name), '')
    INTO n_other, v_names
    FROM essentials.politicians p
   WHERE p.is_active = true
     AND p.id <> 'e569ab1d-d9cf-5364-82c8-faaca133921e'::uuid
     AND NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '') IS NOT NULL
     AND NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '')
         NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_other > 0 THEN
    RAISE WARNING 'CC_0284: Langford is fixed, but % other active politician(s) still serve an '
                  'off-site photo and will keep the nightly red: %', n_other, v_names;
  ELSE
    RAISE NOTICE 'CC_0284 OK - Langford serves the bucket portrait, and no active politician '
                 'serves an off-site photo; the headshot gate should pass';
  END IF;
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS ROW PAID FOR: A PAGE URL IN AN IMAGE COLUMN IS A BROKEN IMAGE, AND ONLY THE
-- FACE GATE COULD SEE IT. Nothing else could. The row had a non-null photo, an image file in
-- our own bucket, a populated politician_images row and a valid licence code; every count-based
-- and null-based check it passes. It took a detector that opens the bytes to notice that what
-- the backend actually serves was 105 KB of HTML.
-- ⚠ AND THE TWO COLUMNS CAN DISAGREE SILENTLY FOR MONTHS. She rendered correctly on the compass
-- the entire time, because that one service puts pi.url in the COALESCE. A spot check of the
-- wrong page would have cleared her.
-- ───────────────────────────────────────────────────────────────────────────────────────────
