-- 1847_co_dead_portrait_urls.sql
-- Clear seven Colorado legislator photo_origin_url values that are DEAD LINKS.
--
-- 1844 populated photo_origin_url for 92 of the 100 CO legislators from the
-- portrait URL Open States carries. Those are Rails active_storage redirect URLs
-- on leg.colorado.gov. Seven of them return HTTP 404.
--
-- 🔴 WHY THIS IS WORSE THAN A BLANK. photoCoverage.ts's HAS_RENDERABLE_PHOTO_SQL
-- counts a politician as having a photo when photo_origin_url merely
-- `LIKE 'http%'`. It cannot tell a live image from a 404, so these seven read as
-- COVERED in every coverage count while rendering broken to a voter. A blank is
-- honest and puts the person in the headshot backlog where they belong.
--
-- 🔴 URL IDENTITY IS NOT LIVENESS — the same lesson as the CA county wave. The
-- URLs were structurally valid, from an official source, and pointed at the right
-- person; they still 404. Verified by FETCHING all 92 and checking the returned
-- bytes decode as an image (magic-number check, NOT the file extension and NOT
-- r.ok — a WAF rejection can be HTTP 200). 85 decoded, 7 did not.
--
-- Measured 2026-08-21. Rerunning the probe is
--   node scripts/verify-photo-origin-urls.mjs --band -829999 -810001
--
-- These seven now correctly appear in the headshot backlog:
--   Carlos Barron, Chris Richardson, Cleave Simpson, Janice Rich, John Carson,
--   Larry Liston, Matt Soper
--
-- Idempotent: the UPDATE is guarded on the exact URLs, so a re-run is a no-op.

BEGIN;

UPDATE essentials.politicians p
   SET photo_origin_url = NULL
 WHERE p.external_id BETWEEN -829999 AND -810001
   AND p.photo_origin_url IS NOT NULL
   AND p.full_name IN (
     'Carlos Barron', 'Chris Richardson', 'Cleave Simpson',
     'Janice Rich', 'John Carson', 'Larry Liston', 'Matt Soper'
   );

DO $$
DECLARE v_left int; v_with int;
BEGIN
  SELECT count(*) INTO v_left
  FROM essentials.politicians
  WHERE external_id BETWEEN -829999 AND -810001
    AND full_name IN ('Carlos Barron','Chris Richardson','Cleave Simpson',
                      'Janice Rich','John Carson','Larry Liston','Matt Soper')
    AND photo_origin_url IS NOT NULL;

  SELECT count(*) INTO v_with
  FROM essentials.politicians
  WHERE external_id BETWEEN -829999 AND -810001 AND photo_origin_url IS NOT NULL;

  IF v_left <> 0 THEN
    RAISE EXCEPTION 'still % dead portrait URL(s) on the seven named legislators', v_left;
  END IF;
  IF v_with <> 85 THEN
    RAISE EXCEPTION 'CO legislators with a portrait URL: expected 85 after the clear, got %', v_with;
  END IF;
END $$;

COMMIT;
