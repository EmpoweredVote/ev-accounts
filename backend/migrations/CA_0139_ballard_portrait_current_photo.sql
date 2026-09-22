-- CA_0139_ballard_portrait_current_photo.sql
--
-- Greg Ballard (Indiana Secretary of State candidate 2026; politician 8cd8842e-…) portrait
-- refresh. CA_0131 seeded a public-domain but DATED (2007, mayor-era) Wikimedia photo. The image
-- bytes at his bucket path have now been replaced (out-of-band, same URL, x-upsert) with his
-- CURRENT campaign portrait (sourced from the Bloomington Chamber of Commerce 2026 voter guide,
-- 640x800 -> cropped 4:5 600x750). This migration corrects the now-stale METADATA on the row so the
-- attribution matches the image actually served:
--   photo_license   : public_domain  -> press_use   (campaign / voter-guide portrait)
--   photo_origin_url: commons.wikimedia.org/... -> https://gregballard.com/  (his official site)
--
-- The bucket URL (photo_custom_url / politician_images.url / race_candidates.photo_url) is
-- UNCHANGED — only the image bytes and this metadata change. Idempotent (IS DISTINCT guards).

BEGIN;

UPDATE essentials.politician_images
SET photo_license = 'press_use'
WHERE politician_id = '8cd8842e-5162-4f60-b8bd-d10eca847785'
  AND url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8cd8842e-5162-4f60-b8bd-d10eca847785-headshot.jpg'
  AND photo_license IS DISTINCT FROM 'press_use';

UPDATE essentials.politicians
SET photo_origin_url = 'https://gregballard.com/'
WHERE id = '8cd8842e-5162-4f60-b8bd-d10eca847785'
  AND photo_custom_url_manual_override IS NOT TRUE
  AND photo_origin_url IS DISTINCT FROM 'https://gregballard.com/';

DO $$
DECLARE n_lic int; n_origin int; n_custom int;
BEGIN
  SELECT count(*) INTO n_lic FROM essentials.politician_images
   WHERE politician_id='8cd8842e-5162-4f60-b8bd-d10eca847785'
     AND url LIKE '%8cd8842e-5162-4f60-b8bd-d10eca847785-headshot.jpg' AND photo_license='press_use';
  IF n_lic <> 1 THEN RAISE EXCEPTION 'expected Ballard image license=press_use, found %', n_lic; END IF;

  SELECT count(*) INTO n_origin FROM essentials.politicians
   WHERE id='8cd8842e-5162-4f60-b8bd-d10eca847785' AND photo_origin_url='https://gregballard.com/';
  IF n_origin <> 1 THEN RAISE EXCEPTION 'expected Ballard photo_origin_url updated, found %', n_origin; END IF;

  -- portrait still renders: photo_custom_url still on the bucket
  SELECT count(*) INTO n_custom FROM essentials.politicians
   WHERE id='8cd8842e-5162-4f60-b8bd-d10eca847785' AND photo_custom_url LIKE '%storage.supabase.co%';
  IF n_custom <> 1 THEN RAISE EXCEPTION 'Ballard photo_custom_url lost its bucket URL!'; END IF;

  RAISE NOTICE 'ok CA_0139: Ballard portrait metadata refreshed (press_use + gregballard.com)';
END $$;

COMMIT;
