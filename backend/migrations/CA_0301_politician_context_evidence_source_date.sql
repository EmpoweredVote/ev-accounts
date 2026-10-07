-- =============================================================================
-- CA_0301 — the date of each published source, and the tier carried through review
-- =============================================================================
-- Operator request 2026-10-06 (Chris Andrews): list a date next to each source, so a
-- voter can see when the person said or did the thing cited — and can judge for
-- themselves whether two sources are one occasion or two (codebook V6 Evidence tier).
--
-- No new table. politician_context_evidence is already the one-row-per-published-source
-- table that the voter-facing citations read (compassService.getPoliticianCitations).
-- The date already exists upstream: each coder passage carries it
-- (stance_coder_labels.source_codes[].date). The coder-pipeline writer
-- (scripts/queue-coded-batch.ts → resolveResearchReview) copies it here on approval.
--
-- Precision follows the office_terms honesty rule: a source dated only "2017" is stored
-- as 2017-01-01 with precision 'year', never as an invented day. Both columns are NULL
-- when the date is not known — every row written before this migration, and every
-- human-added URL. The read path must show NULL as no date.
--
-- Also inform.stance_research_review.evidence_tier: the CA_0300 tier, computed by code
-- (evidenceTier.ts) when the coder pipeline queues the row. The API cannot import the
-- scripts' coder libraries, so approval copies this value into politician_context —
-- and only when the approved chair equals the coders' consensus_value. A reviewer who
-- changes the chair publishes no tier: the coders read their sources for their chair.
--
-- Purely additive. Idempotent.
-- =============================================================================

BEGIN;

ALTER TABLE inform.politician_context_evidence
  ADD COLUMN IF NOT EXISTS source_date           date,
  ADD COLUMN IF NOT EXISTS source_date_precision text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'pce_source_date_precision_check'
       AND conrelid = 'inform.politician_context_evidence'::regclass
  ) THEN
    ALTER TABLE inform.politician_context_evidence
      ADD CONSTRAINT pce_source_date_precision_check CHECK (
        (source_date IS NULL AND source_date_precision IS NULL)
        OR (source_date IS NOT NULL AND (
              source_date_precision = 'day'
           OR (source_date_precision = 'month' AND extract(day FROM source_date) = 1)
           OR (source_date_precision = 'year'  AND extract(day FROM source_date) = 1
                                               AND extract(month FROM source_date) = 1))));
  END IF;
END $$;

ALTER TABLE inform.stance_research_review
  ADD COLUMN IF NOT EXISTS evidence_tier text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'stance_research_review_evidence_tier_check'
       AND conrelid = 'inform.stance_research_review'::regclass
  ) THEN
    ALTER TABLE inform.stance_research_review
      ADD CONSTRAINT stance_research_review_evidence_tier_check
      CHECK (evidence_tier IS NULL OR evidence_tier IN ('corroborated', 'single-source'));
  END IF;
END $$;

COMMENT ON COLUMN inform.stance_research_review.evidence_tier IS
  'CA_0301: the codebook V6 tier evidenceTier.ts computed for consensus_value at queue time. '
  'Approval copies it to politician_context.evidence_tier only when the approved value = consensus_value.';

COMMENT ON COLUMN inform.politician_context_evidence.source_date IS
  'CA_0301: when the person said or did what this source cites (the coder passage date). '
  'Read with source_date_precision; NULL = unknown, render as no date.';
COMMENT ON COLUMN inform.politician_context_evidence.source_date_precision IS
  'CA_0301: day | month | year. A year-only source is stored as YYYY-01-01 with precision year — '
  'never render it as a day.';

-- Post-verify gate.
DO $$
DECLARE
  n_col int;
  n_dated int;
BEGIN
  SELECT count(*) INTO n_col
    FROM information_schema.columns
   WHERE table_schema = 'inform' AND table_name = 'politician_context_evidence'
     AND column_name IN ('source_date', 'source_date_precision');
  IF n_col <> 2 THEN
    RAISE EXCEPTION 'CA_0301: expected 2 new evidence columns, found %', n_col;
  END IF;
  SELECT count(*) INTO n_col
    FROM information_schema.columns
   WHERE table_schema = 'inform' AND table_name = 'stance_research_review' AND column_name = 'evidence_tier';
  IF n_col <> 1 THEN
    RAISE EXCEPTION 'CA_0301: stance_research_review.evidence_tier missing';
  END IF;

  SELECT count(*) INTO n_dated FROM inform.politician_context_evidence WHERE source_date IS NOT NULL;
  RAISE NOTICE 'CA_0301: % evidence rows carry a source date', n_dated;
END $$;

COMMIT;
