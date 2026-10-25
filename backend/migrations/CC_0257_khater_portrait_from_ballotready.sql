-- CC_0257_khater_portrait_from_ballotready.sql
--
-- Seats a real portrait for Tayler Khater, reversing the blank written by CC_0256.
--
-- CC_0256 blanked them because their published headshot was a FAMILY HOLIDAY PHOTOGRAPH -- five
-- people, and no way to tell which one was the candidate. BallotReady carries a solo portrait on
-- their own candidate profile, and BallotReady is already a source in this corpus
-- (politicians.source='ballotready'); it is what resolved three comparable Utah candidates in
-- CC_0255.
--
--   https://www.ballotready.org/people/tayler-khater
--   -> https://assets.civicengine.com/uploads/candidate/headshot/944861/944861.jpg   300x296
--
-- IDENTITY, checked on three independent facts rather than the name alone:
--   * the profile page states "Candidate for Utah State Senate - District 14"; our
--     race_candidates row reads position_name 'Utah State Senate District 14', filed
--     source='sos_filing'
--   * the website on that race row is khaterforutah.com -- the same campaign whose site served
--     the family photograph CC_0256 removed
--   * the file is the one THAT PERSON'S OWN PAGE DISPLAYS (alt "Headshot of Tayler"), never a
--     name-derived guess; a guessed civicengine filename 403'd during CC_0255's pass
--
-- 🔴 THE FACE COUNT IS THE CHECK THAT MATTERS HERE, and it is the one the gate could not do for
-- the old file: this frame contains exactly ONE detected face. The photograph it replaces
-- contained FIVE and passed the gate clean. Counting faces is cheap and would have caught it --
-- but a crowd of one is also what a WRONG person's portrait looks like, so it is a necessary
-- check, never a sufficient one.
--
-- ⚠ 2.53x UPSCALE from 300x296 -- visibly soft. It is the only solo portrait of them in policy:
-- their campaign site serves only the family photograph, and utelection.info does not list them.
-- A soft photograph of the right person beats a blank, and beats five people in a canyon.
-- Flagged so a better source can replace it.
--
-- ⚠ THIS CANDIDATE IS RECORDED AS WITHDRAWN (race_candidates.candidate_status='withdrawn',
-- Utah State Senate District 14, Democratic primary). The row is still is_active, so it still
-- renders; seating a correct portrait is right either way. Whether a withdrawn candidate should
-- remain active is a separate question and is NOT touched here.
--
-- Face-checked after cropping: 0.95 at rotation 0, eye line -7.4 degrees. Byte-verified served:
-- HTTP 200, image/jpeg, sha256 identical to the local file.
-- 🔴 ?v=20261019c, because overwriting a storage object does not change what the CDN serves.
-- BOTH SIDES written. Idempotent.

BEGIN;

CREATE TEMP TABLE _khater (
  politician_id uuid PRIMARY KEY,
  name_like     text NOT NULL,
  url           text NOT NULL,
  origin_url    text NOT NULL,
  photo_license text NOT NULL
) ON COMMIT DROP;

INSERT INTO _khater (politician_id, name_like, url, origin_url, photo_license) VALUES
  ('28df85e8-73c8-4def-bdd1-6929ff083590'::uuid, 'Tayler Khater',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/28df85e8-73c8-4def-bdd1-6929ff083590-headshot.jpg?v=20261019c',
   'https://www.ballotready.org/people/tayler-khater', 'press_use');

-- Guard: the id must resolve to Tayler Khater, and must still be the row CC_0256 blanked.
-- If something has since seated a photo, REFUSE rather than overwrite it.
DO $$
DECLARE v_name text; v_custom text; v_images int;
BEGIN
  SELECT p.full_name, p.photo_custom_url,
         (SELECT count(*) FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
    INTO v_name, v_custom, v_images
    FROM essentials.politicians p JOIN _khater k ON k.politician_id = p.id;

  IF v_name IS NULL THEN
    RAISE EXCEPTION 'CC_0257: id matches no politician row';
  END IF;
  IF v_name <> 'Tayler Khater' THEN
    RAISE EXCEPTION 'CC_0257: id resolves to "%", expected "Tayler Khater"', v_name;
  END IF;
  IF v_custom IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0257: photo_custom_url is already set (%) - something seated a photo since CC_0256, REFUSING', v_custom;
  END IF;
  IF v_images <> 0 THEN
    RAISE EXCEPTION 'CC_0257: % politician_images row(s) already exist, REFUSING', v_images;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT k.politician_id, k.url, 'default', k.photo_license FROM _khater k;

UPDATE essentials.politicians p
SET photo_custom_url = k.url,
    photo_origin_url = k.origin_url
FROM _khater k
WHERE p.id = k.politician_id;

DO $$
DECLARE n_both int; n_multi int;
BEGIN
  SELECT count(*) INTO n_both
    FROM _khater k
    JOIN essentials.politicians p ON p.id = k.politician_id
     AND p.photo_custom_url = k.url AND p.photo_origin_url = k.origin_url
    JOIN essentials.politician_images pi ON pi.politician_id = k.politician_id
     AND pi.type = 'default' AND pi.url = k.url AND pi.photo_license = k.photo_license;
  IF n_both <> 1 THEN
    RAISE EXCEPTION 'CC_0257: expected 1 row written on both sides, found %', n_both;
  END IF;

  SELECT count(*) INTO n_multi FROM (
    SELECT pi.politician_id FROM essentials.politician_images pi
    JOIN _khater k ON k.politician_id = pi.politician_id
    WHERE pi.type = 'default' GROUP BY pi.politician_id HAVING count(*) > 1) x;
  IF n_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0257: more than one default image row';
  END IF;

  RAISE NOTICE 'CC_0257 OK - Khater seated from BallotReady, both sides written';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- STILL OWED across CC_0253-CC_0257
--   Three soft upscales, each the in-policy ceiling for that person on 2026-10-19:
--     Brent Bowles    4.69x from 136x160
--     Traci Crockett  3.00x from 250x250
--     Tayler Khater   2.53x from 300x296
--   🔴 The face gate still cannot see the WRONG PERSON. Counting faces (added as a note here)
--     catches a crowd, never an impostor.
-- ───────────────────────────────────────────────────────────────────────────────────────────
