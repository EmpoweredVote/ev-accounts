-- CC_0198 — replace Barri Worth Girvan's headshot (LA replenish, batch 3)
--
-- WHY. The live image carried a hard WHITE RECTANGLE burned into its top-right corner — the only
-- defect on the Los Angeles page that a voter noticed immediately. Diagnosed 2026-10-07:
-- barriforthevalley.com publishes her portrait as a TRANSPARENT-BACKGROUND CUTOUT
-- (static.wixstatic.com/media/6cb43e_7f10fc86c80748738de01fb06eb84db1~mv2.png, 1000x1465, RGBA).
-- Something composited that cutout onto a leafy backdrop and left white where a corner fill failed.
-- The photograph underneath was never the problem — same blue blazer, same white top, same
-- necklace in both.
--
-- WHAT SHIPS. The same cutout, composited onto a neutral studio backdrop (a soft radial grey, lit
-- behind the head) and cropped 4:5 to 680x850. Head 48.8% of frame, eye line 27.1%, chroma 21.8 —
-- passes the no-monochrome gate. A pure crop of the composite: nothing is enlarged.
--
-- ⚠ THIS IMAGE IS COMPOSITED, and the house rule is that pixel work must not silently alter a
-- photograph. It is recorded here because it is not silent and not a judgement call I made alone:
-- the operator reviewed the white-background version rendered in the live card and asked for a
-- neutral backdrop instead, because a white cutout blends into the white card and reads as
-- floating. The SUBJECT pixels are untouched; only the background behind the alpha is new.
--
-- 🔴 The cutout was checked for a white matte before compositing, because a cutout matted on white
-- grows a pale halo when you put it on grey. Measured: semi-transparent rim luma 40.7 against
-- 78.2 for the opaque pixels just inside it — the rim is DARKER by 37.5, so this is straight alpha
-- with no matte baked in, and the composite is clean. A white matte would have made the rim far
-- brighter. The edges were then looked at at 3x against the new backdrop.
--
-- Rejected alternative, recorded so nobody re-finds it: Ballotpedia holds a larger file
-- (DSC4920_20260714_204927_31330_1.jpeg, 1213x1574) whose alt text names her, which is good
-- identity evidence — but it is a half-body street shot with the head at roughly 12% of the frame,
-- and cropping it tight would leave about 400x500.
--
-- 🔴 WRITES BOTH FIELDS. The essentials browse grid (PoliticianGrid.getImageData) reads the
-- politician_images array first and falls back to politicians.photo_custom_url only when it is
-- empty; the backend read paths do the reverse. The gate requires the pair to agree.
--
-- photo_origin_url moves from her homepage to the cutout file itself, which is what provenance
-- should name. photo_license was 'press_use'; the file is a campaign-published portrait and the
-- site states no use policy, so that is what the licence now records.
--
-- Rollback is one UPDATE; the old object is still in the bucket:
--   photo_custom_url was https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit/2cea762f-17c0-42a4-a83f-678a2941c8c9.jpg
--   photo_origin_url was https://www.barriforthevalley.com/
--   photo_license    was press_use
--
-- Idempotent: both UPDATEs are guarded on the value they write.

BEGIN;

UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/2cea762f-17c0-42a4-a83f-678a2941c8c9.jpg',
       photo_origin_url = 'https://static.wixstatic.com/media/6cb43e_7f10fc86c80748738de01fb06eb84db1~mv2.png',
       last_update_date = now()
 WHERE id = '2cea762f-17c0-42a4-a83f-678a2941c8c9'
   AND full_name = 'Barri Worth Girvan'
   AND photo_custom_url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/2cea762f-17c0-42a4-a83f-678a2941c8c9.jpg';

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/2cea762f-17c0-42a4-a83f-678a2941c8c9.jpg',
       photo_license = 'Campaign portrait published by barriforthevalley.com as a transparent-background cutout; recomposited onto a neutral backdrop by us, subject pixels untouched. The site states no use policy.'
 WHERE politician_id = '2cea762f-17c0-42a4-a83f-678a2941c8c9'
   AND type = 'default'
   AND url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/2cea762f-17c0-42a4-a83f-678a2941c8c9.jpg';

DO $$
DECLARE
  r          record;
  v_expected text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/'
                     || 'politician_photos/la_city/2026-10-replenish/'
                     || '2cea762f-17c0-42a4-a83f-678a2941c8c9.jpg';
BEGIN
  SELECT p.id, p.full_name, p.photo_custom_url, p.photo_origin_url,
         coalesce(p.photo_custom_url_manual_override, false) AS override,
         (SELECT count(*) FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default')         AS n_default,
         (SELECT i.url FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1) AS default_url
    INTO r
    FROM essentials.politicians p
   WHERE p.id = '2cea762f-17c0-42a4-a83f-678a2941c8c9';

  IF r.id IS NULL THEN
    RAISE EXCEPTION 'CC_0198: politician 2cea762f-17c0-42a4-a83f-678a2941c8c9 not found';
  END IF;

  IF r.override THEN
    RAISE EXCEPTION 'CC_0198: % carries photo_custom_url_manual_override — refusing to claim it',
      r.full_name;
  END IF;

  IF r.n_default <> 1 THEN
    RAISE EXCEPTION 'CC_0198: % has % rows of type=default, expected exactly 1',
      r.full_name, r.n_default;
  END IF;

  IF r.photo_custom_url IS DISTINCT FROM v_expected THEN
    RAISE EXCEPTION 'CC_0198: % has photo_custom_url %, expected %',
      r.full_name, coalesce(r.photo_custom_url, '<null>'), v_expected;
  END IF;

  -- 🔴 The grid reads the images row, the backend reads the scalar. They must agree.
  IF r.default_url IS DISTINCT FROM r.photo_custom_url THEN
    RAISE EXCEPTION 'CC_0198: % renders % in the grid but % through the API — they must agree',
      r.full_name, coalesce(r.default_url, '<null>'), coalesce(r.photo_custom_url, '<null>');
  END IF;

  -- Provenance names the source file, never our own CDN and never a bare homepage.
  IF r.photo_origin_url IS NULL
     OR r.photo_origin_url LIKE '%kxsdzaojfaibhuzmclfq%'
     OR r.photo_origin_url !~ '\.(png|jpg|jpeg|webp)$' THEN
    RAISE EXCEPTION 'CC_0198: % has photo_origin_url %, expected an external image file',
      r.full_name, coalesce(r.photo_origin_url, '<null>');
  END IF;

  RAISE NOTICE 'CC_0198: Girvan repointed to the recomposited portrait; grid and API agree';
END $$;

COMMIT;
