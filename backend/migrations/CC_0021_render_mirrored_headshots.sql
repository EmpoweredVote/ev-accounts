-- CC_0021_render_mirrored_headshots.sql
-- Make 370 sitting officeholders RENDER the headshots we already host.
--
-- THESE ARE NOT MISSING HEADSHOTS. Every one of these people already has a
-- politician_images row pointing at an object in our own Supabase bucket, and every one of
-- those objects was byte-checked before this migration was written: 370 of 370 return a
-- real JPEG/PNG magic number. Nothing needs fetching, cropping or approving. The pictures
-- are ours; they are simply not what the read path serves.
--
-- WHY THEY RENDER A WEB PAGE INSTEAD. The read paths build the photo from
--     COALESCE(p.photo_custom_url, p.photo_origin_url, '')
-- backend/src/lib/districtQueries.ts (DISTRICT_SELECT_FIELDS -- the address-search path)
-- NEVER READS essentials.politician_images at all; essentialsBodiesService.ts reads it
-- only third. So with photo_custom_url empty, the fallback is photo_origin_url, which for
-- these rows is a legitimate SOURCE PAGE -- a chamber roster, a council page, a bio. An
-- HTML page handed to an <img src>. All 147 Washington legislators share one such URL:
-- https://leg.wa.gov/legislators/.
--
-- Same defect as CC_0018 (155 Florida legislators) and CC_0019 (71 Florida local
-- officials), now swept corpus-wide. The importer was fixed in the same series so new
-- waves cannot reintroduce it (scripts/import-headshot-candidates.py writes
-- photo_custom_url).
--
-- 🔴 photo_origin_url IS DELIBERATELY NOT TOUCHED. It already holds correct provenance --
-- these are source pages, not raw image URLs. Only the RENDER field is missing, and the
-- gate below asserts the provenance survived.
--
-- Guarded on photo_custom_url still being empty and on the image row living in OUR bucket,
-- so a re-run is a no-op and no third-party URL is ever promoted to the render field.
--
-- Measured before writing (2026-08-30): wa 176, tx 90, co 35, nc 31, dc 14, ma 10, ca 5,
-- me 3, and one each in as, gu, md, mp, pr, vi.

BEGIN;

-- Freeze the exact population first, so the gate checks the rows this migration claimed
-- rather than re-deriving a predicate that the UPDATE itself has just falsified.
CREATE TEMP TABLE _to_render ON COMMIT DROP AS
WITH held AS (
  SELECT DISTINCT och.politician_id AS pid
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE och.politician_id IS NOT NULL
), img AS (
  SELECT DISTINCT ON (politician_id) politician_id, url
    FROM essentials.politician_images ORDER BY politician_id, id
)
SELECT p.id AS pid, i.url AS cdn_url, p.photo_origin_url AS source_page
  FROM held h
  JOIN essentials.politicians p ON p.id = h.pid
  JOIN img i ON i.politician_id = p.id
 WHERE btrim(COALESCE(p.photo_custom_url, '')) = ''
   AND i.url LIKE '%storage.supabase.co%'
   AND p.photo_origin_url LIKE 'http%'
   AND p.photo_origin_url !~* '\.(jpg|jpeg|png|webp|gif)(\?|$)';

UPDATE essentials.politicians p
   SET photo_custom_url = t.cdn_url
  FROM _to_render t
 WHERE p.id = t.pid
   AND btrim(COALESCE(p.photo_custom_url, '')) = '';

DO $$
DECLARE
  n_total     int;
  n_no_render int;
  n_lost_prov int;
  n_left      int;
BEGIN
  SELECT count(*) INTO n_total FROM _to_render;
  IF n_total = 0 THEN
    RAISE EXCEPTION 'no rows matched -- either already applied, or the predicate drifted';
  END IF;

  -- END STATE, not the delta: every row claimed must now render from our own bucket.
  SELECT count(*) INTO n_no_render
    FROM _to_render t JOIN essentials.politicians p ON p.id = t.pid
   WHERE COALESCE(NULLIF(btrim(p.photo_custom_url), ''), p.photo_origin_url, '')
         NOT LIKE '%storage.supabase.co%';
  IF n_no_render <> 0 THEN
    RAISE EXCEPTION '% officeholder(s) would still render from something other than our bucket', n_no_render;
  END IF;

  -- Provenance must survive untouched.
  SELECT count(*) INTO n_lost_prov
    FROM _to_render t JOIN essentials.politicians p ON p.id = t.pid
   WHERE p.photo_origin_url IS DISTINCT FROM t.source_page;
  IF n_lost_prov <> 0 THEN
    RAISE EXCEPTION '% row(s) had their photo_origin_url provenance altered', n_lost_prov;
  END IF;

  -- And the class must be empty afterwards: no sitting officeholder should still hold a
  -- mirrored image in our bucket while rendering a page.
  SELECT count(*) INTO n_left
    FROM (
      SELECT DISTINCT och.politician_id AS pid
        FROM essentials.offices o
        JOIN essentials.districts d ON d.id = o.district_id
        JOIN essentials.office_current_holder och ON och.office_id = o.id
       WHERE och.politician_id IS NOT NULL) h
    JOIN essentials.politicians p ON p.id = h.pid
    JOIN (SELECT DISTINCT ON (politician_id) politician_id, url
            FROM essentials.politician_images ORDER BY politician_id, id) i
      ON i.politician_id = p.id
   WHERE btrim(COALESCE(p.photo_custom_url, '')) = ''
     AND i.url LIKE '%storage.supabase.co%'
     AND p.photo_origin_url LIKE 'http%'
     AND p.photo_origin_url !~* '\.(jpg|jpeg|png|webp|gif)(\?|$)';
  IF n_left <> 0 THEN
    RAISE EXCEPTION '% officeholder(s) still mirrored-but-not-rendered', n_left;
  END IF;

  RAISE NOTICE 'OK: % officeholders now render the headshots we already host', n_total;
END $$;

COMMIT;
