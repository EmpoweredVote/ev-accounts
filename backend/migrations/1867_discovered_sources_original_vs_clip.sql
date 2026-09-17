-- Persist the classifier's clip/full-event judgment on discovered rows.
-- Spec: on-the-record/docs/superpowers/specs/2026-09-16-discovery-review-reorg-design.md
ALTER TABLE essentials.discovered_sources
  ADD COLUMN IF NOT EXISTS original_vs_clip text
  CHECK (original_vs_clip IS NULL OR original_vs_clip IN ('original','clip'));

-- Heuristic backfill (Chris's call): a row the classifier already routed to
-- 'quote_source' is treated as a clip; an 'ingest' row as the full/original event.
-- route is NOT NULL, so every existing row gets a value.
UPDATE essentials.discovered_sources
SET original_vs_clip = CASE route
      WHEN 'quote_source' THEN 'clip'
      WHEN 'ingest'       THEN 'original'
    END
WHERE original_vs_clip IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='essentials' AND table_name='discovered_sources'
                   AND column_name='original_vs_clip') THEN
    RAISE EXCEPTION 'discovered_sources.original_vs_clip missing after migration';
  END IF;
END $$;
