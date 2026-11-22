-- =============================================================================
-- CA_0415 — inform.politician_context.summary_sha256: marks reasoning as a checked
-- position summary
-- =============================================================================
-- A blank spoke (politician_answers.value = 0) may still carry a `reasoning` text in
-- politician_context. That text is shown to a voter only when it is a CHECKED position
-- summary: written by the Stage 5 summary recipe and verified against its sources.
-- This column is the mark. It holds the SHA-256 (64 lowercase hex characters) of the
-- exact `reasoning` text that was checked.
--
-- The read compares it with encode(sha256(convert_to(reasoning, 'UTF8')), 'hex') and
-- shows a blank's reasoning ONLY when they match. If the reasoning is edited after the
-- check, the hashes differ and the text silently stops being shown, which is the safe
-- failure. NULL = never checked (every row that exists today) and means "do not show".
--
-- Nothing is backfilled: no existing row has been checked, and guessing a mark is the
-- defect this column exists to prevent. Purely additive. Idempotent (IF NOT EXISTS).
--
-- NO GRANT OR RLS CHANGE, and why. No migration in this directory grants on or enables
-- RLS for inform.politician_context specifically: 026_inform_schema_repair_and_candidates.sql
-- creates it, and CA_0109_default_deny_rls_essentials_inform_tm_meetings_trivia.sql lists
-- only inform.seasons for the inform schema. A table-level privilege in Postgres covers
-- every column, including one added later, and RLS is per-row, so neither needs a change
-- for a new column. (Same shape as CA_0300 evidence_tier, also added to this table with no
-- grant.) Not measured against prod here: this file was written without a database
-- connection, so the controller's dry run is the place to read the live grants.
--
-- SIZE NOTE for the post-verify: the "every row is NULL" read is written as
-- NOT EXISTS (... WHERE summary_sha256 IS NOT NULL), never count(*). politician_context
-- is not on the "never aggregate" list in CLAUDE.md, but it carries a reasoning text per
-- (politician, topic, season), so an unfiltered count would read every row's heap pages.
-- =============================================================================

BEGIN;

ALTER TABLE inform.politician_context
  ADD COLUMN IF NOT EXISTS summary_sha256 text
  CONSTRAINT politician_context_summary_sha256_hex_check
  CHECK (summary_sha256 IS NULL OR summary_sha256 ~ '^[0-9a-f]{64}$');

COMMENT ON COLUMN inform.politician_context.summary_sha256 IS
  'CA_0415: marks `reasoning` as a checked position summary. Holds sha256 (64 lowercase hex) of the '
  'exact reasoning text that was checked. The read compares it with '
  'encode(sha256(convert_to(reasoning, ''UTF8'')), ''hex'') and shows a blank''s (value 0) reasoning '
  'only when they match, so an edit after the check hides the text. NULL = never checked: do not show.';

-- Post-verify gate.
DO $$
DECLARE
  n_col int;
  n_chk int;
BEGIN
  SELECT count(*) INTO n_col
    FROM information_schema.columns
   WHERE table_schema = 'inform' AND table_name = 'politician_context'
     AND column_name = 'summary_sha256' AND data_type = 'text';
  IF n_col <> 1 THEN
    RAISE EXCEPTION 'CA_0415: summary_sha256 text column missing (found %)', n_col;
  END IF;

  SELECT count(*) INTO n_chk
    FROM pg_constraint
   WHERE conname = 'politician_context_summary_sha256_hex_check'
     AND conrelid = 'inform.politician_context'::regclass;
  IF n_chk <> 1 THEN
    RAISE EXCEPTION 'CA_0415: hex CHECK constraint missing (found %)', n_chk;
  END IF;

  -- Additive only: on first apply no row is marked.
  IF EXISTS (SELECT 1 FROM inform.politician_context WHERE summary_sha256 IS NOT NULL) THEN
    RAISE EXCEPTION 'CA_0415: some politician_context row already carries summary_sha256 (nothing should before this migration)';
  END IF;
END $$;

COMMIT;
