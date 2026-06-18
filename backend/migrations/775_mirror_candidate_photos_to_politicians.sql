-- Migration 775: mirror candidate-only fields (photo, website) onto linked politician records
--
-- BACKGROUND
--   Some data is captured on essentials.race_candidates but the candidate PROFILE renders the
--   linked essentials.politicians record (for any candidate with a politician_id). Fields that
--   live on the candidate row but not on the politician therefore show on the election CARD but
--   are missing from the profile:
--     • photo:   race_candidates.photo_url  vs  politicians.photo_custom_url/photo_origin_url + politician_images
--     • website: race_candidates.website_url vs  politicians.urls (text[]) / web_form_url
--   This happens because uploads/enrichment ran while the candidate was unlinked, then a later
--   step (e.g. migration 772, which created minimal sos_filing politician records) linked the
--   candidate without copying its data over. Confirmed 2026-06-18: 59 linked candidates missing
--   a photo, 51 missing a website, on their politician record.
--   (Endpoints: /race-candidates/:id reads rc.* and shows them; /politicians/:id reads p.* only.)
--
-- WHAT THIS DOES
--   1. essentials.mirror_candidate_data_to_politician(politician_id, photo_url, website_url) —
--      reusable, NON-DESTRUCTIVE: fills the politician's photo and/or website from the candidate
--      ONLY when the politician has none of its own (and, for the photo, is not manual-override
--      locked — D-08, migration 192). Never overwrites existing politician data.
--   2. One-time backfill: runs the function for every linked candidate carrying a photo or website.
--   3. AFTER INSERT OR UPDATE OF (politician_id, photo_url, website_url) trigger on race_candidates,
--      so any future link / photo / website change auto-mirrors. Covers the migration-based linking
--      vector that the TS upload script alone cannot.
--
-- Idempotent and safe to re-run: the function only ever fills empties; CREATE OR REPLACE /
--   DROP ... IF EXISTS guard the DDL. Forward-only.
-- NOTE: applied to production 2026-06-18 (photo gap 59->0, website gap 51->0; trigger
--   race_candidate_mirror_data live). Recorded here for history. Re-applying is a safe no-op.

BEGIN;

-- Drop the photo-only objects from this migration's earlier draft, if they were ever applied.
DROP TRIGGER  IF EXISTS race_candidate_mirror_photo ON essentials.race_candidates;
DROP FUNCTION IF EXISTS essentials.trg_race_candidate_mirror_photo();
DROP FUNCTION IF EXISTS essentials.mirror_candidate_photo_to_politician(uuid, text);

-- ── 1. Reusable mirror function ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION essentials.mirror_candidate_data_to_politician(
  p_politician_id uuid,
  p_photo_url     text,
  p_website_url   text
) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_politician_id IS NULL THEN
    RETURN;
  END IF;

  -- ── Photo ── only when the politician has no photo of its own and is not override-locked.
  IF coalesce(p_photo_url, '') <> ''
     AND EXISTS (
           SELECT 1 FROM essentials.politicians p
           WHERE p.id = p_politician_id
             AND coalesce(p.photo_custom_url, '') = ''
             AND coalesce(p.photo_origin_url, '') = ''
             AND p.photo_custom_url_manual_override IS NOT TRUE
         )
     AND NOT EXISTS (
           SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p_politician_id
         )
  THEN
    -- Feeds the profile's `images` array.
    INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
    SELECT gen_random_uuid(), p_politician_id, p_photo_url, 'default', 'sourced'
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.politician_images
      WHERE politician_id = p_politician_id AND type = 'default'
    );

    -- Feeds the profile's main photo field, COALESCE(photo_custom_url, photo_origin_url, '').
    UPDATE essentials.politicians
    SET photo_custom_url = p_photo_url
    WHERE id = p_politician_id
      AND coalesce(photo_custom_url, '') = ''
      AND photo_custom_url_manual_override IS NOT TRUE;
  END IF;

  -- ── Website ── only when the politician has no url of its own (urls empty AND web_form_url empty).
  IF coalesce(p_website_url, '') <> ''
     AND EXISTS (
           SELECT 1 FROM essentials.politicians p
           WHERE p.id = p_politician_id
             AND coalesce(array_length(p.urls, 1), 0) = 0
             AND coalesce(p.web_form_url, '') = ''
         )
  THEN
    UPDATE essentials.politicians
    SET urls = ARRAY[p_website_url]
    WHERE id = p_politician_id
      AND coalesce(array_length(urls, 1), 0) = 0
      AND coalesce(web_form_url, '') = '';
  END IF;
END;
$$;

-- ── 2. One-time backfill over all linked candidates that carry a photo and/or website ──────────
DO $$
DECLARE
  rec           RECORD;
  v_photo_before int; v_photo_after int;
  v_web_before   int; v_web_after   int;
BEGIN
  SELECT
    count(*) FILTER (WHERE coalesce(rc.photo_url, '') <> ''
                       AND coalesce(p.photo_custom_url, '') = ''
                       AND coalesce(p.photo_origin_url, '') = ''
                       AND p.photo_custom_url_manual_override IS NOT TRUE
                       AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)),
    count(*) FILTER (WHERE coalesce(rc.website_url, '') <> ''
                       AND coalesce(array_length(p.urls, 1), 0) = 0
                       AND coalesce(p.web_form_url, '') = '')
    INTO v_photo_before, v_web_before
  FROM essentials.race_candidates rc
  JOIN essentials.politicians p ON p.id = rc.politician_id;

  FOR rec IN
    SELECT rc.politician_id, rc.photo_url, rc.website_url
    FROM essentials.race_candidates rc
    WHERE rc.politician_id IS NOT NULL
      AND (coalesce(rc.photo_url, '') <> '' OR coalesce(rc.website_url, '') <> '')
  LOOP
    PERFORM essentials.mirror_candidate_data_to_politician(rec.politician_id, rec.photo_url, rec.website_url);
  END LOOP;

  SELECT
    count(*) FILTER (WHERE coalesce(rc.photo_url, '') <> ''
                       AND coalesce(p.photo_custom_url, '') = ''
                       AND coalesce(p.photo_origin_url, '') = ''
                       AND p.photo_custom_url_manual_override IS NOT TRUE
                       AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)),
    count(*) FILTER (WHERE coalesce(rc.website_url, '') <> ''
                       AND coalesce(array_length(p.urls, 1), 0) = 0
                       AND coalesce(p.web_form_url, '') = '')
    INTO v_photo_after, v_web_after
  FROM essentials.race_candidates rc
  JOIN essentials.politicians p ON p.id = rc.politician_id;

  RAISE NOTICE 'mirror_candidate_data: photo gap % -> % ; website gap % -> % (both expect 0; manual-override-locked photos are intentionally skipped)',
    v_photo_before, v_photo_after, v_web_before, v_web_after;
END $$;

-- ── 3. Trigger: auto-mirror on future links / photo / website changes ──────────────────────────
CREATE OR REPLACE FUNCTION essentials.trg_race_candidate_mirror_data()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM essentials.mirror_candidate_data_to_politician(NEW.politician_id, NEW.photo_url, NEW.website_url);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS race_candidate_mirror_data ON essentials.race_candidates;
CREATE TRIGGER race_candidate_mirror_data
  AFTER INSERT OR UPDATE OF politician_id, photo_url, website_url
  ON essentials.race_candidates
  FOR EACH ROW
  EXECUTE FUNCTION essentials.trg_race_candidate_mirror_data();

COMMIT;

-- ROLLBACK (emergency, manual):
--   DROP TRIGGER IF EXISTS race_candidate_mirror_data ON essentials.race_candidates;
--   DROP FUNCTION IF EXISTS essentials.trg_race_candidate_mirror_data();
--   DROP FUNCTION IF EXISTS essentials.mirror_candidate_data_to_politician(uuid, text, text);
--   -- (mirrored photos/urls remain in politician_images / photo_custom_url / urls; remove per-row if needed.)
