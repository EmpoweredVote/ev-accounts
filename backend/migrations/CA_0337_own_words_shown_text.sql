-- CA_0337_own_words_shown_text.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-10-29.
--
-- ⚠ NOT APPLIED until Chris Andrews says so.
-- =============================================================================
-- CA_0337: inform.own_words_passages.shown_text — party labels bracketed out
-- =============================================================================
-- Ruling: .claude/skills/season-topic-prep/RULINGS.md "Party labels never reach a reader; shown quotes bracket
-- them out" (2026-10-29). A quote shown to voters replaces each party label with a bracketed neutral word from a
-- fixed list ("Sen. Jim Risch […] wrote", "[Some lawmakers] want you to…"), so the edit is visible and the
-- person's point is kept. The exact words stay in `passage`; the source link shown under every passage is where
-- a reader sees them whole.
--
--   shown_text  the text voters see, when a party label was bracketed out; NULL when the passage has none (voters
--               then see `passage`). Own words only: a local record's note is our own text and names no party.
--               Written only by `topic:stage5-write`, which stores it only when the quote check wrote it, hashed
--               it (shown_sha256), and bracketEditProblem (backend/src/lib/partyLabels.ts) finds that it changes
--               nothing but party labels, each into a listed bracket word.
--
-- Readers: compassService.getResearchStates serves COALESCE(shown_text, passage) as `passage`.
-- Purely additive: a nullable column, no row changes. ADD COLUMN fires no row trigger, so the closed-season
-- trigger (CC_0044) does not block it, and closed seasons' rows are untouched (all NULL).
-- =============================================================================
BEGIN;

ALTER TABLE inform.own_words_passages
  ADD COLUMN IF NOT EXISTS shown_text text;

ALTER TABLE inform.own_words_passages
  DROP CONSTRAINT IF EXISTS own_words_passages_shown_text_check;
ALTER TABLE inform.own_words_passages
  ADD CONSTRAINT own_words_passages_shown_text_check CHECK (
    shown_text IS NULL
    OR (kind = 'own-words' AND btrim(shown_text) <> '' AND shown_text <> passage AND strpos(shown_text, '[') > 0)
  );

COMMENT ON COLUMN inform.own_words_passages.shown_text IS
  'CA_0337: the passage as voters see it, each party label replaced by a listed bracket word (RULINGS.md "Party '
  'labels never reach a reader"). NULL = shown as passage. passage keeps the exact words.';
COMMENT ON TABLE inform.own_words_passages IS
  'Passages shown as own words, not a position on the scale (spec §8 case 2). Only a passed AI quote check '
  'may be stored (CHECK). passage is never edited; party labels are bracketed out in shown_text (CA_0337). '
  'Duplicate-person merges must re-point politician_id here.';

-- -----------------------------------------------------------------------------
-- Verification.
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = 'inform' AND table_name = 'own_words_passages' AND column_name = 'shown_text'
                    AND is_nullable = 'YES') THEN
    RAISE EXCEPTION 'CA_0337: inform.own_words_passages.shown_text is missing or NOT NULL';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.own_words_passages'::regclass
                  AND conname = 'own_words_passages_shown_text_check') THEN
    RAISE EXCEPTION 'CA_0337: own_words_passages_shown_text_check is missing';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.own_words_passages WHERE shown_text IS NOT NULL) THEN
    RAISE EXCEPTION 'CA_0337: rows already carry shown_text; this migration writes none';
  END IF;
  IF has_table_privilege('anon', 'inform.own_words_passages', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0337: anon can SELECT inform.own_words_passages';
  END IF;
END $$;

COMMIT;
