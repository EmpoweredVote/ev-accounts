-- CC_0334_blank_unsupported_licence.sql
--
-- Blank the last unsupported Creative Commons claim. One row: Sid Miller.
-- After this, NO portrait in the table claims the unversioned 'cc_by-sa'.
--
-- 🔴 THE VALUE THIS OVERWRITES
--      image  9647dd35-6a81-4f10-96ce-361598e4a811  (Sid Miller, politician c924a088-…fda28d)
--      photo_license  'cc_by-sa'  ->  NULL
--    That is the whole change. The photograph, its storage object and photo_origin_url are all
--    left exactly as they are.
--
-- WHY BLANK RATHER THAN CORRECT IT
--   `CC_0333` replaced 25 portraits and left this one alone because no usable source could be
--   found for it. Four routes failed: the photograph is not the Wikipedia article's lead image,
--   not elsewhere on that article, not in its infobox at any point in its history, and not
--   findable on Commons by name. 🔴 Both Commons candidates also defeated the face detector
--   outright — it locked onto a patch of cloud on one and a gold necklace against denim on the
--   other — and texasagriculture.gov publishes only a 250x375 portrait.
--
--   So the claim cannot be supported, and an unsupported CC licence is not a neutral placeholder:
--   it tells the public they may reuse a photograph under terms nobody granted. A blank says we
--   do not know, which is true. ▶ Operator ruling 2026-11-02: blank it.
--
-- ⚠ WHAT A BLANK DOES AND DOES NOT DO
--   NULL, not 'unknown'. The credit the API serves (backend/src/lib/photoCredit.ts) requires a
--   non-empty licence, so NULL means no credit line renders at all. 'unknown' would instead
--   render "Photo: source" linking his photo_origin_url — a Wikipedia ARTICLE page that we have
--   established is NOT where this file came from. Pointing a reader at a wrong source is worse
--   than pointing them at none.
--
--   🟢 photo_origin_url IS DELIBERATELY KEPT. It records where somebody looked, which is a lead
--   for whoever researches this row next. With the licence NULL it is inert — nothing displays
--   it — so keeping it costs a reader nothing and keeps the trail.
--
-- ⚠ THIS DOES NOT MAKE THE ROW FINISHED. He still has a photograph of unestablished origin. The
--   row leaves the "unsupported claim" population and joins the "no provenance recorded" one,
--   which is where the remaining 43 rows from CC_0326 already sit.

BEGIN;

CREATE TEMP TABLE lic_before ON COMMIT DROP AS
  SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
    FROM essentials.politician_images GROUP BY 1;

-- ---------------------------------------------------------------------------------------------
-- Pre-flight.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  -- Exactly one row may be in this state, and it must be the one this file names. If another
  -- appeared since CC_0333, it has not been researched and must not be swept up here.
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'pre-flight: expected exactly 1 unversioned cc_by-sa row, found %', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM essentials.politician_images pi
   WHERE pi.id = '9647dd35-6a81-4f10-96ce-361598e4a811'::uuid
     AND pi.politician_id = 'c924a088-546a-49ad-b836-f5e278fda28d'::uuid
     AND pi.type = 'default'
     AND pi.photo_license = 'cc_by-sa';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'pre-flight: the named image is not Sid Miller''s default cc_by-sa portrait';
  END IF;

  -- 🔴 Recomputed from the database, not asserted: the row this file names really is the one
  --    row in that state. A hard-coded id that had drifted onto somebody else would pass the
  --    two checks above and still blank the wrong person's licence.
  SELECT count(*) INTO v_n
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE pi.photo_license = 'cc_by-sa'
     AND (pi.id <> '9647dd35-6a81-4f10-96ce-361598e4a811'::uuid OR p.full_name <> 'Sid Miller');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: the remaining cc_by-sa row is not the one this file names';
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politician_images
   SET photo_license = NULL
 WHERE id = '9647dd35-6a81-4f10-96ce-361598e4a811'::uuid
   AND photo_license = 'cc_by-sa';

-- ---------------------------------------------------------------------------------------------
-- Post-verify.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_before int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.politician_images
   WHERE id = '9647dd35-6a81-4f10-96ce-361598e4a811'::uuid AND photo_license IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION 'post-verify: the licence was not blanked'; END IF;

  -- The invariant this migration exists to establish.
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa';
  IF v_n <> 0 THEN RAISE EXCEPTION 'post-verify: % unversioned cc_by-sa row(s) remain', v_n; END IF;

  -- 🔴 The photograph and its provenance lead are untouched. Blanking the licence must not
  --    quietly take the file or the trail with it.
  SELECT count(*) INTO v_n FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE pi.id = '9647dd35-6a81-4f10-96ce-361598e4a811'::uuid
     AND pi.url LIKE '%supabase.co/storage/v1/object/public/%'
     AND coalesce(p.photo_origin_url, '') <> '';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'post-verify: the photograph or its origin lead did not survive';
  END IF;

  -- 🔴 Delta: exactly one row left cc_by-sa, and nothing else in the table moved.
  SELECT coalesce((SELECT n FROM lic_before WHERE lic = 'cc_by-sa'), 0) INTO v_before;
  IF v_before <> 1 THEN RAISE EXCEPTION 'post-verify: census disagrees, before was %', v_before; END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
      FROM essentials.politician_images GROUP BY 1
  ) a
  FULL JOIN lic_before b ON b.lic = a.lic
   WHERE coalesce(a.n, 0) <> coalesce(b.n, 0)
     AND coalesce(a.lic, b.lic) NOT IN ('cc_by-sa', '<null>');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % licence value(s) outside the blanked row changed count', v_n;
  END IF;
END $$;

COMMIT;
