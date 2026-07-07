-- 1230_quotes_editor_note.sql
-- Adds a freeform editor rationale to essentials.quotes: why the quote was
-- selected and, if edited, what changed and why. Nullable; no backfill.
BEGIN;

ALTER TABLE essentials.quotes
  ADD COLUMN IF NOT EXISTS editor_note text;

COMMENT ON COLUMN essentials.quotes.editor_note IS
  'Editor rationale: why this quote was selected and, if edited, what changed and why. Freeform.';

COMMIT;
