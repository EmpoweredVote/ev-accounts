-- 060_chambers_slug.sql
-- Phase 107 — Add kebab-case slug column to essentials.chambers, generated from
-- name_formal using the existing public.f_unaccent IMMUTABLE wrapper (migration 040).
-- Slug rules (D-03): lowercase -> strip accents -> '&'->and -> drop ' ’ . -> non-alnum runs -> '-' -> btrim '-'
--
-- Also adds idempotent indexes on join columns used by the new roster endpoint
-- (offices.chamber_id, offices.politician_id, politician_images.politician_id) to
-- protect the <500ms p95 target (D-26/D-27).

BEGIN;

-- 1. Generated slug column. STORED so lookups are plain index scans.
ALTER TABLE essentials.chambers
  ADD COLUMN IF NOT EXISTS slug TEXT GENERATED ALWAYS AS (
    btrim(
      regexp_replace(
        translate(
          replace(
            public.f_unaccent(lower(coalesce(name_formal, ''))),
            '&', 'and'
          ),
          '''’.', ''
        ),
        '[^a-z0-9]+', '-', 'g'
      ),
      '-'
    )
  ) STORED;

-- 2. Non-unique B-tree index for slug lookup (D-04: not unique — duplicates aggregate per D-13).
CREATE INDEX IF NOT EXISTS idx_chambers_slug
  ON essentials.chambers (slug);

-- 3. Join-column indexes (D-27). IF NOT EXISTS makes these safe if live DB already has them.
CREATE INDEX IF NOT EXISTS idx_offices_chamber_id
  ON essentials.offices (chamber_id);
CREATE INDEX IF NOT EXISTS idx_offices_politician_id
  ON essentials.offices (politician_id);
CREATE INDEX IF NOT EXISTS idx_politician_images_politician_id
  ON essentials.politician_images (politician_id);

-- 4. D-05 sanity check: Bloomington Common Council must resolve to 'bloomington-common-council'.
DO $$
DECLARE
  v_slug TEXT;
BEGIN
  SELECT slug INTO v_slug
  FROM essentials.chambers
  WHERE name_formal = 'Bloomington Common Council'
  LIMIT 1;
  IF v_slug IS NULL THEN
    RAISE NOTICE 'No row matched name_formal = Bloomington Common Council — verify data load.';
  ELSIF v_slug <> 'bloomington-common-council' THEN
    RAISE EXCEPTION 'Slug mismatch: expected bloomington-common-council, got %', v_slug;
  END IF;
END $$;

COMMIT;
