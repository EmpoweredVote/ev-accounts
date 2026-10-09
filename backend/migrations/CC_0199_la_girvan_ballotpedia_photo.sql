-- CC_0199 — switch Barri Worth Girvan to the Ballotpedia photograph (supersedes CC_0198)
--
-- WHY. Operator ruling, 2026-10-07. CC_0198 shipped her campaign-site cutout recomposited onto a
-- neutral studio backdrop. The operator wanted the BALLOTPEDIA photograph instead. I had read an
-- earlier instruction as "use a neutral background" when it meant "use the alternative source",
-- and CC_0198 is what that misreading shipped.
--
-- 🔴 I ALSO ARGUED AGAINST THIS SOURCE ON A NUMBER THAT WAS WRONG. CC_0198's header and the review
-- notes said the Ballotpedia file had "the head at roughly 12% of the frame" and would "crop to
-- about 400x500". Both were eyeballed off a contact-sheet thumbnail. Measured on the actual file:
-- the head is 400 px of 1574, which is 25.4% of the frame, and it crops to 720x900 — LARGER than
-- the 680x850 composite CC_0198 shipped. The rejection rested on a figure nobody had measured.
--
-- WHAT SHIPS. s3.amazonaws.com/ballotpedia-api4/files/DSC4920_20260714_204927_31330_1.jpeg
-- (1213x1574), cropped 4:5 to 720x900. Head 44.4% of frame, eye line 27.8%, chroma 37.4 — passes
-- the no-monochrome gate. A pure crop: nothing enlarged, and nothing composited, so this also
-- retires the "this image is composited" caveat CC_0198 had to carry.
--
-- Identity: Ballotpedia's own alt text reads "Image of Barri Worth Girvan" — the name is on the
-- image, not merely near it. A negative control confirmed the host distinguishes hits from misses:
-- a fabricated filename under the same prefix returns 404 while this one returns 200.
--
-- 🔴 THE HORIZONTAL CENTRE WAS MEASURED, NOT EYEBALLED — twice I misread it off a labelled grid and
-- cut her face to the edge of the frame. The crop window is centred on a skin-tone column-density
-- weighted centroid taken across the eye band (y 200-320), which put the face at x=622 against the
-- 430 I had guessed. In the shipped crop the face centre sits at exactly 50.0% of the width.
--
-- 🔴 WRITES BOTH FIELDS. The browse grid reads essentials.politician_images first and falls back to
-- politicians.photo_custom_url; the backend read paths do the reverse. The gate requires the pair
-- to agree.
--
-- Rollback is one UPDATE, and BOTH earlier objects are still in the bucket:
--   CC_0198 (the grey composite)  …/la_city/2026-10-replenish/2cea762f-17c0-42a4-a83f-678a2941c8c9.jpg
--   pre-CC_0198 (the white block) …/la_county/2026-audit/2cea762f-17c0-42a4-a83f-678a2941c8c9.jpg
--   photo_origin_url was https://static.wixstatic.com/media/6cb43e_7f10fc86c80748738de01fb06eb84db1~mv2.png
--
-- Idempotent: both UPDATEs are guarded on the value they write.

BEGIN;

UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/2cea762f-17c0-42a4-a83f-678a2941c8c9-bp.jpg',
       photo_origin_url = 'https://s3.amazonaws.com/ballotpedia-api4/files/DSC4920_20260714_204927_31330_1.jpeg',
       last_update_date = now()
 WHERE id = '2cea762f-17c0-42a4-a83f-678a2941c8c9'
   AND full_name = 'Barri Worth Girvan'
   AND photo_custom_url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/2cea762f-17c0-42a4-a83f-678a2941c8c9-bp.jpg';

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/2cea762f-17c0-42a4-a83f-678a2941c8c9-bp.jpg',
       photo_license = 'Candidate photograph published by Ballotpedia (ballotpedia.org), alt text "Image of Barri Worth Girvan". Cropped only; not composited.'
 WHERE politician_id = '2cea762f-17c0-42a4-a83f-678a2941c8c9'
   AND type = 'default'
   AND url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/2cea762f-17c0-42a4-a83f-678a2941c8c9-bp.jpg';

DO $$
DECLARE
  r          record;
  v_expected text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/'
                     || 'politician_photos/la_city/2026-10-replenish/'
                     || '2cea762f-17c0-42a4-a83f-678a2941c8c9-bp.jpg';
BEGIN
  SELECT p.id, p.full_name, p.photo_custom_url, p.photo_origin_url,
         coalesce(p.photo_custom_url_manual_override, false) AS override,
         (SELECT count(*) FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default')         AS n_default,
         (SELECT i.url FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1) AS default_url,
         (SELECT i.photo_license FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1) AS lic
    INTO r
    FROM essentials.politicians p
   WHERE p.id = '2cea762f-17c0-42a4-a83f-678a2941c8c9';

  IF r.id IS NULL THEN
    RAISE EXCEPTION 'CC_0199: politician 2cea762f-17c0-42a4-a83f-678a2941c8c9 not found';
  END IF;

  IF r.override THEN
    RAISE EXCEPTION 'CC_0199: % carries photo_custom_url_manual_override — refusing to claim it',
      r.full_name;
  END IF;

  IF r.n_default <> 1 THEN
    RAISE EXCEPTION 'CC_0199: % has % rows of type=default, expected exactly 1',
      r.full_name, r.n_default;
  END IF;

  IF r.photo_custom_url IS DISTINCT FROM v_expected THEN
    RAISE EXCEPTION 'CC_0199: % has photo_custom_url %, expected %',
      r.full_name, coalesce(r.photo_custom_url, '<null>'), v_expected;
  END IF;

  IF r.default_url IS DISTINCT FROM r.photo_custom_url THEN
    RAISE EXCEPTION 'CC_0199: % renders % in the grid but % through the API — they must agree',
      r.full_name, coalesce(r.default_url, '<null>'), coalesce(r.photo_custom_url, '<null>');
  END IF;

  -- Provenance must now name Ballotpedia's file, not the Wix cutout CC_0198 recorded.
  IF r.photo_origin_url IS DISTINCT FROM
     'https://s3.amazonaws.com/ballotpedia-api4/files/DSC4920_20260714_204927_31330_1.jpeg' THEN
    RAISE EXCEPTION 'CC_0199: % has photo_origin_url %, expected the Ballotpedia file',
      r.full_name, coalesce(r.photo_origin_url, '<null>');
  END IF;

  -- The composited-image caveat must be gone: this photograph is cropped only.
  IF r.lic IS NULL OR r.lic ILIKE '%recomposited%' THEN
    RAISE EXCEPTION 'CC_0199: % still carries the composited-image licence (%)', r.full_name, r.lic;
  END IF;

  RAISE NOTICE 'CC_0199: Girvan now on the Ballotpedia photograph, cropped only; grid and API agree';
END $$;

COMMIT;
