-- CC_0204 — replace Scott Schmerelson's headshot (LA replenish, batch 6)
--
-- WHY. The live 600x750 is an ENLARGEMENT of something small: heavily blurred, with the top of his
-- head clipped by the frame. Its pixel count is not information. Measured edge energy (mean
-- absolute neighbour difference over the luma plane) is 1.15, against 7.15 for the replacement —
-- SIX TIMES less real detail in a file with nearly three times the pixels.
--
-- WHAT SHIPS. `SMS-squaresredlanyard-triangle-hands.jpg` from boardmemberscott.org, his own site:
-- seated outdoors in a checked blazer and red lanyard, looking at the camera. 947x615 is the
-- ORIGINAL — the page's srcset tops out at 771w and the unsuffixed WordPress file is this one, so
-- there is nothing larger behind it. Cropped 4:5 to 360x451. Head 43.0% of frame, eye line 31.0%,
-- air above the hair 10.0%, chroma 18.3 — passes the no-monochrome gate. A pure crop: nothing
-- enlarged, and nothing clipped.
--
-- ⚠ 360x451 IS THE SMALLEST THING SHIPPED IN THIS RUN. It clears the 300 px floor, and the operator
-- took it over the larger blurred file on the strength of the detail measurement, seeing both. His
-- own site publishes no larger portrait; lausd.org and boe.lausd.org both answer 403 to a real
-- browser, not just to curl; every other picture on his site is a classroom or cafeteria scene with
-- no usable portrait in it.
--
-- 🔴 THIS ALSO FIXES A CLAIM WITH NOTHING BEHIND IT. Today his photo_origin_url is NULL while the
-- politician_images row asserts licence `government-official`. Nothing recorded where that file
-- came from, so the licence asserted a provenance the record could not support — the same defect
-- class as Price's `cc_by_sa_4.0` in CC_0195. Provenance is written here for the first time and the
-- licence now says what is actually true.
--
-- 🔴 THE CROP IS CENTRED ON A MEASURED FACE BOX. Reading a face position off a labelled grid by eye
-- put a face at the frame edge three times in this run. The window is centred on an OpenCV face box
-- (x416 y74 w165 in the 947x615 original), and the detector was proved on a crop whose answer was
-- already known before it was trusted here. The shipped crop puts the face centre at exactly 50.0%
-- of the width.
--
-- 🔴 WRITES BOTH FIELDS. The browse grid reads essentials.politician_images first and falls back to
-- politicians.photo_custom_url; the backend read paths do the reverse. The gate requires the pair
-- to agree.
--
-- Rollback is one UPDATE; the old object is still in the bucket:
--   photo_custom_url was https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/fcafc695-2a41-41c0-831d-da28c5bf3c9e-headshot.jpg
--   photo_origin_url was NULL
--   photo_license    was government-official

BEGIN;

UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/fcafc695-2a41-41c0-831d-da28c5bf3c9e.jpg',
       photo_origin_url = 'https://boardmemberscott.org/wp-content/uploads/2021/10/SMS-squaresredlanyard-triangle-hands.jpg',
       last_update_date = now()
 WHERE id = 'fcafc695-2a41-41c0-831d-da28c5bf3c9e'
   AND full_name = 'Scott Schmerelson'
   AND photo_custom_url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/fcafc695-2a41-41c0-831d-da28c5bf3c9e.jpg';

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/fcafc695-2a41-41c0-831d-da28c5bf3c9e.jpg',
       photo_license = 'Published by the board member''s own site, boardmemberscott.org. The site states no use policy. (Replaces a `government-official` claim made while photo_origin_url was NULL.)'
 WHERE politician_id = 'fcafc695-2a41-41c0-831d-da28c5bf3c9e'
   AND type = 'default'
   AND url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/fcafc695-2a41-41c0-831d-da28c5bf3c9e.jpg';

DO $$
DECLARE
  r          record;
  v_expected text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/'
                     || 'politician_photos/la_city/2026-10-replenish/'
                     || 'fcafc695-2a41-41c0-831d-da28c5bf3c9e.jpg';
BEGIN
  SELECT p.id, p.full_name, p.photo_custom_url, p.photo_origin_url,
         coalesce(p.photo_custom_url_manual_override, false) AS override,
         (SELECT count(*) FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default')              AS n_default,
         (SELECT i.url FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1)      AS default_url,
         (SELECT i.photo_license FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1)      AS lic
    INTO r
    FROM essentials.politicians p
   WHERE p.id = 'fcafc695-2a41-41c0-831d-da28c5bf3c9e';

  IF r.id IS NULL THEN
    RAISE EXCEPTION 'CC_0204: politician fcafc695-2a41-41c0-831d-da28c5bf3c9e not found';
  END IF;
  IF r.override THEN
    RAISE EXCEPTION 'CC_0204: % carries photo_custom_url_manual_override — refusing', r.full_name;
  END IF;
  IF r.n_default <> 1 THEN
    RAISE EXCEPTION 'CC_0204: % has % rows of type=default, expected exactly 1', r.full_name, r.n_default;
  END IF;
  IF r.photo_custom_url IS DISTINCT FROM v_expected THEN
    RAISE EXCEPTION 'CC_0204: % has photo_custom_url %, expected %',
      r.full_name, coalesce(r.photo_custom_url, '<null>'), v_expected;
  END IF;
  IF r.default_url IS DISTINCT FROM r.photo_custom_url THEN
    RAISE EXCEPTION 'CC_0204: % renders % in the grid but % through the API — they must agree',
      r.full_name, coalesce(r.default_url, '<null>'), coalesce(r.photo_custom_url, '<null>');
  END IF;
  -- Provenance must now exist and name an external image file. It was NULL before this migration,
  -- which is what made the old licence claim unsupportable.
  IF r.photo_origin_url IS NULL
     OR r.photo_origin_url LIKE '%kxsdzaojfaibhuzmclfq%'
     OR r.photo_origin_url !~ '\.(png|jpg|jpeg|webp)$' THEN
    RAISE EXCEPTION 'CC_0204: % has photo_origin_url %, expected an external image file',
      r.full_name, coalesce(r.photo_origin_url, '<null>');
  END IF;
  -- And the unsupported claim must be gone.
  IF r.lic IS NULL OR r.lic = 'government-official' THEN
    RAISE EXCEPTION 'CC_0204: % still carries the unsupported licence (%)', r.full_name, r.lic;
  END IF;

  RAISE NOTICE 'CC_0204: Schmerelson repointed to a real portrait with provenance; grid and API agree';
END $$;

COMMIT;
