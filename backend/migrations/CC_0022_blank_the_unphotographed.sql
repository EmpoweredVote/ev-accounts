-- CC_0022_blank_the_unphotographed.sql
-- Make two officeholders with NO available photograph read as BLANK rather than covered.
--
-- Ankit Jain and Paul Strauss, the District of Columbia's two US shadow senators, hold a
-- photo_origin_url and nothing else. With photo_custom_url empty that value is also what the
-- read path serves, so each renders an HTML PAGE into an <img src>:
--   Ankit Jain    https://senatorjaindc.com/about                  (live page, no portrait on it)
--   Paul Strauss  https://statehood.dc.gov/page/shadow-senators    (404)
--
-- 🔴 A BLANK IS BETTER THAN A LINK HERE, AND THAT IS THE WHOLE POINT.
-- HAS_RENDERABLE_PHOTO_SQL counts anything LIKE 'http%' as coverage
-- (backend/src/lib/photoCoverage.ts), so these two count as photographed while rendering
-- broken -- strictly worse than empty, because a blank puts the person IN the headshot
-- backlog and a page URL hides them from it. Clearing the field is the same disposition
-- scripts/verify-photo-origin-urls.mjs --fix-sql has always emitted for a dead link.
--
-- WHY NOT JUST FIND THEM A PHOTO. Searched 2026-08-30; there is no usable one under the
-- standing rules (press, official or public domain only; never a social network).
--   * Paul Strauss -- Wikimedia Commons holds three images, ALL rejected on inspection: a
--     2015 rally candid with a microphone across his face and a bystander's head in frame,
--     a 2021 photo in which he is wearing a face mask, and an older outdoor candid with a
--     man drinking behind him. His remaining presence is Instagram and X, which are out.
--   * Ankit Jain -- his Wikipedia article carries no image, and his own site has only
--     banner and event photographs, no portrait.
-- Neither is a failure to look. Both are honest blanks, and blanking them is what puts them
-- back in the queue for when an official portrait appears.
--
-- NOT touched: Jeffrey Lytton, the third and last remaining broken render. His placeholder
-- stays because his SEAT is unresolved -- Lawrence County's roster says District 4 is Larry
-- Arnold, and no source dates the change. See
-- .planning/todos/2026-08-30-headshot-check-found-two-stale-rosters.md.
--
-- Guarded on the exact value being replaced, so a re-run is a no-op and a row that has since
-- been given a real photo is left alone.

BEGIN;

UPDATE essentials.politicians p
   SET photo_origin_url = NULL
  FROM (VALUES
      ('239d8ac5-4dc5-4266-831d-5aa821996435'::uuid, 'https://senatorjaindc.com/about'),               -- Ankit Jain
      ('71e0a6de-fd71-45ab-a591-9e3c376ac23d'::uuid, 'https://statehood.dc.gov/page/shadow-senators')  -- Paul Strauss
  ) AS v(pid, old_url)
 WHERE p.id = v.pid
   AND p.photo_origin_url = v.old_url
   AND btrim(COALESCE(p.photo_custom_url, '')) = ''
   AND NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = p.id);

DO $$
DECLARE
  n_covered int;
BEGIN
  -- Neither may still read as photo-covered by any of the three routes the predicate allows.
  SELECT count(*) INTO n_covered
    FROM essentials.politicians p
    LEFT JOIN essentials.politician_images i ON i.politician_id = p.id
   WHERE p.id IN ('239d8ac5-4dc5-4266-831d-5aa821996435', '71e0a6de-fd71-45ab-a591-9e3c376ac23d')
     AND (i.politician_id IS NOT NULL
          OR btrim(COALESCE(p.photo_custom_url, '')) <> ''
          OR (btrim(COALESCE(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%'));
  IF n_covered <> 0 THEN
    RAISE EXCEPTION '% shadow senator(s) still read as photo-covered', n_covered;
  END IF;

  RAISE NOTICE 'OK: both DC shadow senators now read as blank, and are back in the headshot backlog';
END $$;

COMMIT;
