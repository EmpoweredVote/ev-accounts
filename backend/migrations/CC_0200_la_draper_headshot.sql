-- CC_0200 — replace Robert S. Draper's headshot (LA replenish, batch 5)
--
-- WHY. The weakest image left on the Los Angeles page: a LANDSCAPE 672x446 video grab of him
-- outside a courthouse plaza, mid-sentence, off-centre, with flags and patio furniture behind.
--
-- WHAT IT ACTUALLY WAS. Our stored file is byte-identical to LAist's 672x446 web variant of
-- `screenshot-2026-04-27-at-4-13-39-pm.png` (confirmed: mean absolute pixel difference 0.00 against
-- the CDN response). LAist's S3 original of that same frame is 1342x890 — twice the linear size —
-- so the better crop was sitting behind the variant we had taken.
--
-- WHAT SHIPS. The same frame, recropped from the 1342x890 original to 592x741. Head 60.9% of frame,
-- eye line 31.0%, chroma 25.8 — passes the no-monochrome gate. A pure crop: nothing enlarged.
--
-- Operator chose this over a Los Angeles Times staff portrait (5891x3927 by Robert Gauthier,
-- caption "Superior Court Judge Robert Draper, who sought reelection, outside the Ronald Reagan
-- Federal Building"). That photograph is far better made — and he wears OPAQUE DARK SUNGLASSES in
-- it with his face turned away, so at card size it reads as a dark rectangle with sunglasses in it.
-- A headshot's job is recognition. Both were rendered in the page's own card chrome before the call.
--
-- Also rejected: judgerobertdraper.com now returns 410 Gone (the campaign site came down after he
-- lost). Recovered from the Wayback Machine, snapshot 2026-05-22: its only portrait is
-- `judge-draper-hero.jpg` at 376x284, below the floor, heavily compressed, and he is looking down at
-- papers. Its Next.js image optimiser returned the same 376x284 when asked for w=3840, so nothing
-- larger sits behind it. Ballotpedia has no photograph of him, only a "Submit photo" placeholder.
--
-- 🔴 THE CROP IS CENTRED ON A MEASURED FACE BOX, NOT AN EYEBALLED ONE. Reading the face position
-- off a labelled grid by eye put the face at the frame edge twice in this batch. The window is
-- centred on an OpenCV face box (x486 y77 w383 in the 1342x890 original), and that detector was
-- proved on two crops whose answer was already known before it was trusted here. The shipped crop
-- puts the face centre at exactly 50.0% of the width.
--
-- ⚠ HE LEAVES THIS SEAT ON 2027-01-04 — he lost the 2026-06-02 primary to Tal Khan Valbuena. The
-- handover is CC_0201 (dated rows, applied now) and CC_0202 (the cached columns, January). This
-- photograph therefore has about twelve weeks of life; the operator chose to replace it anyway.
--
-- 🔴 WRITES BOTH FIELDS. The browse grid reads essentials.politician_images first and falls back to
-- politicians.photo_custom_url; the backend read paths do the reverse. The gate requires the pair
-- to agree.
--
-- Rollback is one UPDATE; the old object is still in the bucket:
--   photo_custom_url was https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fa932212-a2cf-4fa1-97ab-c6619e3db610-headshot.jpg
--   photo_origin_url was https://laist.com/news/politics/la-county-judge-up-for-re-election-accused-of-violating-ethics-rules
--   photo_license    was press_use (unchanged — same newsroom, same photograph)
--
-- Idempotent: both UPDATEs are guarded on the value they write.

BEGIN;

UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/fa932212-a2cf-4fa1-97ab-c6619e3db610.jpg',
       photo_origin_url = 'https://scpr-brightspot.s3.us-west-2.amazonaws.com/4b/6b/63c84cf745ff951845d296acb182/screenshot-2026-04-27-at-4-13-39-pm.png',
       last_update_date = now()
 WHERE id = 'fa932212-a2cf-4fa1-97ab-c6619e3db610'
   AND full_name = 'Robert S. Draper'
   AND photo_custom_url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/fa932212-a2cf-4fa1-97ab-c6619e3db610.jpg';

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/fa932212-a2cf-4fa1-97ab-c6619e3db610.jpg',
       photo_license = 'LAist / Southern California Public Radio news frame, recropped from the publisher''s own 1342x890 original. Same newsroom and same photograph as the file this replaces.'
 WHERE politician_id = 'fa932212-a2cf-4fa1-97ab-c6619e3db610'
   AND type = 'default'
   AND url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/fa932212-a2cf-4fa1-97ab-c6619e3db610.jpg';

DO $$
DECLARE
  r          record;
  v_expected text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/'
                     || 'politician_photos/la_city/2026-10-replenish/'
                     || 'fa932212-a2cf-4fa1-97ab-c6619e3db610.jpg';
BEGIN
  SELECT p.id, p.full_name, p.photo_custom_url, p.photo_origin_url,
         coalesce(p.photo_custom_url_manual_override, false) AS override,
         (SELECT count(*) FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default')         AS n_default,
         (SELECT i.url FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1) AS default_url
    INTO r
    FROM essentials.politicians p
   WHERE p.id = 'fa932212-a2cf-4fa1-97ab-c6619e3db610';

  IF r.id IS NULL THEN
    RAISE EXCEPTION 'CC_0200: politician fa932212-a2cf-4fa1-97ab-c6619e3db610 not found';
  END IF;
  IF r.override THEN
    RAISE EXCEPTION 'CC_0200: % carries photo_custom_url_manual_override — refusing', r.full_name;
  END IF;
  IF r.n_default <> 1 THEN
    RAISE EXCEPTION 'CC_0200: % has % rows of type=default, expected exactly 1', r.full_name, r.n_default;
  END IF;
  IF r.photo_custom_url IS DISTINCT FROM v_expected THEN
    RAISE EXCEPTION 'CC_0200: % has photo_custom_url %, expected %',
      r.full_name, coalesce(r.photo_custom_url, '<null>'), v_expected;
  END IF;
  IF r.default_url IS DISTINCT FROM r.photo_custom_url THEN
    RAISE EXCEPTION 'CC_0200: % renders % in the grid but % through the API — they must agree',
      r.full_name, coalesce(r.default_url, '<null>'), coalesce(r.photo_custom_url, '<null>');
  END IF;
  -- Provenance must name the publisher's file, not the article page it appeared on and not our CDN.
  IF r.photo_origin_url IS NULL
     OR r.photo_origin_url LIKE '%kxsdzaojfaibhuzmclfq%'
     OR r.photo_origin_url !~ '\.(png|jpg|jpeg|webp)$' THEN
    RAISE EXCEPTION 'CC_0200: % has photo_origin_url %, expected an external image file',
      r.full_name, coalesce(r.photo_origin_url, '<null>');
  END IF;

  RAISE NOTICE 'CC_0200: Draper repointed to the recropped LAist original; grid and API agree';
END $$;

COMMIT;
