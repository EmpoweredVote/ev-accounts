-- 118: Add per-field is_manual_override flags on essentials.politicians (D-08).
-- Phase 133. Re-runs of UT roster scrapers must NOT overwrite fields the staging
-- workflow has manually edited. This migration adds boolean flags; loaders consult
-- them via `WHERE photo_custom_url_manual_override IS NOT TRUE` etc.
--
-- Forward-only; idempotent via IF NOT EXISTS.

ALTER TABLE essentials.politicians
  ADD COLUMN IF NOT EXISTS photo_custom_url_manual_override boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS bio_text_manual_override         boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS full_name_manual_override        boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN essentials.politicians.photo_custom_url_manual_override IS
  'Phase 133 D-08: when true, re-scrape loaders skip updating photo_custom_url.';
COMMENT ON COLUMN essentials.politicians.bio_text_manual_override IS
  'Phase 133 D-08: when true, re-scrape loaders skip updating bio_text.';
COMMENT ON COLUMN essentials.politicians.full_name_manual_override IS
  'Phase 133 D-08: when true, re-scrape loaders skip updating full_name/first_name/last_name.';

-- ROLLBACK (emergency, manual):
--   ALTER TABLE essentials.politicians
--     DROP COLUMN photo_custom_url_manual_override,
--     DROP COLUMN bio_text_manual_override,
--     DROP COLUMN full_name_manual_override;
