-- 1478: headshot for James "Mac" McLaughlin, candidate for Deschutes County Sheriff
--
-- The 7th of the 13 Bend pins, and the only one that did NOT come out of the headshot sweep:
-- it fell out of the sheriff-race stance research. His KTVZ press release links
-- **votemacforsheriff.com** — a domain that appears in neither of the two the wave-1 trail
-- recorded as his (`macforsheriff.com`, since repurposed to a different person in Arkansas;
-- `mclaughlinforsheriff.com`, a parked lander). The lesson is in the todo: a dead-domain list is
-- not proof that no site exists, and a candidate's own press release is the cheapest way to find
-- the real one.
--
-- Source: the site's hero image, a professional campaign portrait at Smith Rock, 7008x4672 —
-- the largest source in either Bend wave. Cropped head-and-shoulders to the 600x750 house spec
-- (0.43x downscale, no upscaling). press_use, 2026-07-08 policy basis, correct-person guard
-- applied (his own campaign domain, named in his own release).
--
-- Sets photo_custom_url as well as photo_origin_url, per migration 1475 Part B — the read path is
-- COALESCE(photo_custom_url, photo_origin_url, ''), so a source-page URL alone renders a broken
-- portrait. Same form as 1477.
--
-- Bend headshots after this: 32 of 38 imported, 6 pinned.
-- Idempotent: insert is NOT EXISTS-guarded; both updates guard on current state.

BEGIN;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd59d9496-073b-4cb0-88d8-37cb59f0e412'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/'
         || 'd59d9496-073b-4cb0-88d8-37cb59f0e412-headshot.jpg',
       'default',
       'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
   WHERE pi.politician_id = 'd59d9496-073b-4cb0-88d8-37cb59f0e412'::uuid
     AND pi.type = 'default'
);

UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.votemacforsheriff.com/'
 WHERE id = 'd59d9496-073b-4cb0-88d8-37cb59f0e412'::uuid
   AND photo_origin_url IS DISTINCT FROM 'https://www.votemacforsheriff.com/';

UPDATE essentials.politicians p
   SET photo_custom_url = pi.url
  FROM essentials.politician_images pi
 WHERE pi.politician_id = p.id
   AND pi.type = 'default'
   AND p.id = 'd59d9496-073b-4cb0-88d8-37cb59f0e412'::uuid
   AND p.photo_custom_url IS NULL
   AND coalesce(p.photo_custom_url_manual_override, false) = false;

DO $$
DECLARE
  v_id uuid := 'd59d9496-073b-4cb0-88d8-37cb59f0e412';
  v_imgs int; v_broken int; v_bend_total int;
BEGIN
  SELECT count(*) INTO v_imgs FROM essentials.politician_images
   WHERE politician_id = v_id AND type = 'default';
  IF v_imgs <> 1 THEN
    RAISE EXCEPTION '1478 gate: expected exactly 1 default headshot for McLaughlin, found %', v_imgs;
  END IF;

  SELECT count(*) INTO v_broken FROM essentials.politicians
   WHERE id = v_id
     AND coalesce(photo_custom_url, photo_origin_url, '') NOT LIKE '%storage.supabase.co%';
  IF v_broken <> 0 THEN
    RAISE EXCEPTION '1478 gate: row resolves to a page URL, not an image (the 1475 Part B bug)';
  END IF;

  -- Bend cohort progress: city -41058xx plus county/school/park -410 17xx-19xx, plus HD-53 Summers
  SELECT count(*) INTO v_bend_total
    FROM essentials.politicians p
    JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
   WHERE p.external_id BETWEEN -4105899 AND -4105800
      OR p.external_id BETWEEN -4101999 AND -4101700
      OR p.external_id = -4129001;
  RAISE NOTICE '1478 PASSED: McLaughlin imported; Bend cohort now % with a default headshot.', v_bend_total;
END $$;

COMMIT;
