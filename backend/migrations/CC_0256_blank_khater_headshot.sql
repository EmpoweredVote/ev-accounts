-- CC_0256_blank_khater_headshot.sql
--
-- Blanks ONE headshot: Tayler Khater (Utah candidate, active, non-incumbent).
--
-- Her published headshot is a FAMILY HOLIDAY PHOTOGRAPH -- two adults and three children posed
-- in a canyon -- served from her campaign site:
--   https://khaterforutah.com/wp-content/uploads/imgi_4_E2E9C3AA-...-_1_201_a_heic.jpeg  419x501
--
-- 🔴 IT PASSES EVERY CHECK WE HAVE, INCLUDING THE NEW ONE. check-headshot-faces.py (CC_0253)
-- asks whether the frame contains a face. This frame contains five. A group photo is exactly the
-- shape the face gate cannot see, and only looking at it caught this.
--
-- 🔴 IT WAS NOT CROPPED TO A FACE, DELIBERATELY. The obvious "fix" is to crop to the detected
-- face -- and there is NO WAY TO TELL WHICH ADULT IS THE CANDIDATE. Cropping to a guess is the
-- wrong-person error, which is the dominant failure mode in headshot work and the one no
-- automated check can catch. CC_0254 therefore mirrored 14 of 15 external images and left this
-- row alone, asserting in its own post-verify that exactly one row still rendered off-site.
--
-- A BLANK BEATS A LINK. Leaving the family photo in place publishes a holiday snapshot as a
-- civic portrait of a named candidate, and -- because photo_origin_url is non-empty -- it also
-- reads as COVERAGE, hiding her from every "who still needs a headshot" query. An honest NULL is
-- findable. This is the same ruling recorded for page-URLs-as-photos in
-- project_photo_custom_url_is_what_renders.
--
-- Safe because there is nothing else to lose, verified before writing and asserted below:
--   photo_custom_url  IS NULL   (nothing was rendering from the scalar)
--   politician_images  0 rows   (no CDN copy exists; nothing is orphaned by this)
-- So this clears the ONLY photo reference she has, and introduces no new image.
-- Nothing is deleted from storage: no object was ever uploaded for her.
--
-- ▶ OWED: a real portrait. She is a candidate in the 2026-11-03 general election. utelection.info
-- (which supplied Bowles, Paxman and Herrin in CC_0254) does not list her, and her campaign site
-- serves only this family photograph. BallotReady was the source that resolved three comparable
-- Utah candidates in CC_0255 and is the obvious next place to look.
--
-- Idempotent: re-running changes nothing.

BEGIN;

-- Guard: the id must resolve to Tayler Khater, and she must still be in the state this
-- migration measured. If she has since gained a real photo, REFUSE -- do not blank it.
DO $$
DECLARE v_name text; v_custom text; v_images int;
BEGIN
  SELECT p.full_name, p.photo_custom_url,
         (SELECT count(*) FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
    INTO v_name, v_custom, v_images
    FROM essentials.politicians p
   WHERE p.id = '28df85e8-73c8-4def-bdd1-6929ff083590'::uuid;

  IF v_name IS NULL THEN
    RAISE EXCEPTION 'CC_0256: id matches no politician row';
  END IF;
  IF v_name <> 'Tayler Khater' THEN
    RAISE EXCEPTION 'CC_0256: id resolves to "%", expected "Tayler Khater"', v_name;
  END IF;
  IF v_custom IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0256: photo_custom_url is now set (%) - she has a real photo, REFUSING to blank', v_custom;
  END IF;
  IF v_images <> 0 THEN
    RAISE EXCEPTION 'CC_0256: % politician_images row(s) now exist - she has a real photo, REFUSING to blank', v_images;
  END IF;
END $$;

UPDATE essentials.politicians
SET photo_origin_url = NULL
WHERE id = '28df85e8-73c8-4def-bdd1-6929ff083590'::uuid
  AND photo_origin_url IS NOT NULL;

-- post-verify: she now renders nothing, and NO active row renders from an off-site URL.
DO $$
DECLARE v_origin text; v_custom text; n_offsite int;
BEGIN
  SELECT photo_origin_url, photo_custom_url INTO v_origin, v_custom
    FROM essentials.politicians WHERE id = '28df85e8-73c8-4def-bdd1-6929ff083590'::uuid;
  IF v_origin IS NOT NULL OR v_custom IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0256: Khater still carries a photo reference (custom=%, origin=%)', v_custom, v_origin;
  END IF;

  SELECT count(*) INTO n_offsite
    FROM essentials.politicians p
   WHERE p.is_active = true
     AND p.photo_custom_url IS NULL
     AND p.photo_origin_url IS NOT NULL AND p.photo_origin_url <> ''
     AND p.photo_origin_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_offsite <> 0 THEN
    RAISE EXCEPTION 'CC_0256: expected 0 active rows rendering off-site, found %', n_offsite;
  END IF;

  RAISE NOTICE 'CC_0256 OK - Khater blanked; 0 active rows now render from an off-site URL';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS ROW PAID FOR: THE FACE GATE CANNOT TELL A GROUP PHOTO FROM A PORTRAIT.
-- check-headshot-faces.py answers "is there a face in this frame", which is the right question
-- for a seal, a map, a yard sign or a blank -- and the wrong question for a family snapshot, a
-- crowd shot, or the wrong person entirely. Those still need an eye.
-- ───────────────────────────────────────────────────────────────────────────────────────────
