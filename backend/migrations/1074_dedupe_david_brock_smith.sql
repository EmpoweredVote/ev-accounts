-- Migration 1074: Dedupe duplicate "David Brock Smith" politician records
--
-- Two records existed for the same person:
--   KEEP 5350c0ba (ext -4110001): real OR State Senate office ("Senator", incumbent),
--        3 stances (abortion/climate/taxes — ALL also present on the other record).
--   ae7e8d67 (ext -400139): "Candidate for U.S. Senate - Oregon" shell, but holds the
--        richer 27 stances + the imported headshot + the 2026 US Senate race_candidate link.
--
-- Decided survivor: ae7e8d67 (preserves the 27 stances, headshot, and race link with the
-- least row movement). Consolidate by moving his REAL Senate office onto it, marking it
-- incumbent, removing the redundant candidate-shell office (candidacy is represented by the
-- race_candidate link, not an office), then deleting the duplicate 5350c0ba and its
-- now-redundant child rows (its 3 stances are duplicates of the kept 27).
--
-- Reference scan confirmed only 5 tables hold rows for either id: offices, politician_images,
-- race_candidates (keep only), politician_answers, politician_context.

BEGIN;

-- Guard: both must be David Brock Smith.
DO $$
DECLARE v_keep text; v_dup text;
BEGIN
  SELECT full_name INTO v_keep FROM essentials.politicians WHERE id='ae7e8d67-e8a4-49a7-bb5c-715c99168374';
  SELECT full_name INTO v_dup  FROM essentials.politicians WHERE id='5350c0ba-0ef4-4021-a620-90820df859b7';
  IF v_keep IS DISTINCT FROM 'David Brock Smith' OR v_dup IS DISTINCT FROM 'David Brock Smith' THEN
    RAISE EXCEPTION 'name guard failed: keep=%, dup=%', v_keep, v_dup;
  END IF;
END $$;

-- 1. Remove the redundant candidate-shell office on the survivor (only if no race points to it).
DELETE FROM essentials.offices o
 WHERE o.politician_id='ae7e8d67-e8a4-49a7-bb5c-715c99168374'
   AND o.title LIKE 'Candidate for U.S. Senate%'
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);

-- 2. Move the real OR State Senate office from the duplicate onto the survivor.
UPDATE essentials.offices SET politician_id='ae7e8d67-e8a4-49a7-bb5c-715c99168374'
 WHERE politician_id='5350c0ba-0ef4-4021-a620-90820df859b7';

-- 3. Survivor is a sitting incumbent (state senator).
UPDATE essentials.politicians SET is_incumbent=true
 WHERE id='ae7e8d67-e8a4-49a7-bb5c-715c99168374';

-- 4. Delete the duplicate's now-redundant children (its 3 stances duplicate the kept 27).
DELETE FROM inform.politician_context  WHERE politician_id='5350c0ba-0ef4-4021-a620-90820df859b7';
DELETE FROM inform.politician_answers  WHERE politician_id='5350c0ba-0ef4-4021-a620-90820df859b7';
DELETE FROM essentials.politician_images WHERE politician_id='5350c0ba-0ef4-4021-a620-90820df859b7';

-- 5. Delete the duplicate politician row.
DELETE FROM essentials.politicians WHERE id='5350c0ba-0ef4-4021-a620-90820df859b7';

-- Verify final consolidated state of the survivor + that the dup is gone.
SELECT
  (SELECT count(*) FROM essentials.politicians WHERE id='5350c0ba-0ef4-4021-a620-90820df859b7') AS dup_remaining,
  p.is_incumbent,
  (SELECT count(*) FROM essentials.offices o WHERE o.politician_id=p.id) AS offices,
  (SELECT string_agg(o.title,', ') FROM essentials.offices o WHERE o.politician_id=p.id) AS office_titles,
  (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id=p.id) AS stances,
  (SELECT count(*) FROM essentials.politician_images i WHERE i.politician_id=p.id) AS images,
  (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id=p.id) AS race_links
FROM essentials.politicians p WHERE p.id='ae7e8d67-e8a4-49a7-bb5c-715c99168374';

COMMIT;
