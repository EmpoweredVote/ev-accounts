-- =============================================================================
-- CA_0300 — evidence tier on the published stance (codebook V6 "Evidence tier",
-- ruling 2026-10-06, Chris Andrews, option C)
-- =============================================================================
-- One chair-shaped source may seat a chair, but the voter sees how much evidence
-- stands behind it. The tier is COMPUTED by code (backend/scripts/lib/evidenceTier.ts)
-- from the coders' shared `rests_on` — never typed by a coder or an editor.
--
-- Where: inform.politician_context, not politician_answers. The tier describes the
-- evidence, and the context row is the evidence's home: same key (politician, topic,
-- season), same season pin, and it is the row the voter's "Why this position?" reads.
-- politician_answers stays a pure chair; stance_research_review is a queue, not
-- what voters see.
--
-- NULL means "not computed": every row written before this ruling, and every row
-- written outside the coder pipeline (editor or contributor). The read path must show
-- NULL as nothing, never as either tier. Nothing is backfilled here — a Season 1 row
-- has no coder labels to compute from, and guessing a tier is the defect this
-- column exists to prevent.
--
-- A tier never upgrades a blank: a context row whose answer in the same season is a
-- blank (value = 0) must carry no tier. A CHECK cannot cross tables, so the
-- post-verify gate below checks it, and the writer must not set one.
--
-- Purely additive. Idempotent.
-- =============================================================================

BEGIN;

ALTER TABLE inform.politician_context
  ADD COLUMN IF NOT EXISTS evidence_tier text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'politician_context_evidence_tier_check'
       AND conrelid = 'inform.politician_context'::regclass
  ) THEN
    ALTER TABLE inform.politician_context
      ADD CONSTRAINT politician_context_evidence_tier_check
      CHECK (evidence_tier IS NULL OR evidence_tier IN ('corroborated', 'single-source'));
  END IF;
END $$;

COMMENT ON COLUMN inform.politician_context.evidence_tier IS
  'CA_0300 / codebook V6 Evidence tier (ruling 2026-10-06): corroborated = >=2 independent sources '
  'each supporting the chair alone; single-source = otherwise. Computed by evidenceTier.ts from the '
  'coders'' shared rests_on, never coded. NULL = not computed (legacy or editor-written) and must '
  'render as nothing. Never set on a blank (value 0) answer.';

-- Post-verify gate.
DO $$
DECLARE
  n_col int;
  n_set int;
  n_on_blank int;
BEGIN
  SELECT count(*) INTO n_col
    FROM information_schema.columns
   WHERE table_schema = 'inform' AND table_name = 'politician_context' AND column_name = 'evidence_tier';
  IF n_col <> 1 THEN
    RAISE EXCEPTION 'CA_0300: evidence_tier column missing (found %)', n_col;
  END IF;

  -- Additive only: on first apply no row carries a tier.
  SELECT count(*) INTO n_set FROM inform.politician_context WHERE evidence_tier IS NOT NULL;
  RAISE NOTICE 'CA_0300: % context rows carry a tier', n_set;

  SELECT count(*) INTO n_on_blank
    FROM inform.politician_context c
    JOIN inform.politician_answers a
      ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id AND a.season_id = c.season_id
   WHERE c.evidence_tier IS NOT NULL AND a.value = 0;
  IF n_on_blank <> 0 THEN
    RAISE EXCEPTION 'CA_0300: % blank answers carry an evidence tier (a tier never upgrades a blank)', n_on_blank;
  END IF;
END $$;

COMMIT;
