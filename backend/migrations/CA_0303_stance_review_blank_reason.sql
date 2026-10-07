BEGIN;

-- ⚠ NOT APPLIED. Dry-run on production inside BEGIN…ROLLBACK first; apply only with the
-- operator's explicit OK.

-- =============================================================================
-- CA_0303: a Season 2 blank can be queued for review
-- =============================================================================
-- Spec: docs/superpowers/specs/2026-10-07-season2-blank-review-design.md §3.4 (option A,
-- operator rulings 2026-10-07).
--
-- A blank is a value-0 answer in the open season plus a context row naming the sources the
-- coder examined (season2-prestage correction 2026-09-23). Until now no research row could reach
-- the review queue as a blank: verify-stance-research skipped it, and nothing on the queue row
-- could say WHY the coder found no chair. This adds that:
--
--   proposed_blank_reason  one of codebook V6's six blank reasons (scripts/lib/coderLabel.ts
--                          BLANK_REASONS). Set exactly when proposed_value = 0.
--   evidence_type 'blank'  the row's sources are the EXAMINED sources, not a record or a
--                          statement the chair rests on.
--
-- Purely additive. proposed_blank_reason is NULLABLE and every existing row leaves it NULL; the
-- backend names it in the queue INSERT only once it exists
-- (researchEvidenceService.reviewOptionalColumns) and refuses to queue a blank without it.
-- =============================================================================

ALTER TABLE inform.stance_research_review
  ADD COLUMN IF NOT EXISTS proposed_blank_reason text;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conrelid = 'inform.stance_research_review'::regclass
                    AND conname = 'stance_research_review_blank_reason_check') THEN
    ALTER TABLE inform.stance_research_review
      ADD CONSTRAINT stance_research_review_blank_reason_check
      CHECK (proposed_blank_reason IS NULL OR proposed_blank_reason IN
        ('no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial',
         'record-vs-statement-conflict', 'scope-unavailable'));
  END IF;

  -- A blank and its reason travel together: a 0 with no reason is not a proposal anyone can
  -- review, and a reason beside a chair contradicts it. NULL proposed_value is left alone.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conrelid = 'inform.stance_research_review'::regclass
                    AND conname = 'stance_research_review_blank_pair_check') THEN
    ALTER TABLE inform.stance_research_review
      ADD CONSTRAINT stance_research_review_blank_pair_check
      CHECK ((proposed_value = 0) = (proposed_blank_reason IS NOT NULL)
             OR proposed_value IS NULL);
  END IF;

  -- Widen evidence_type (CA_0285) by 'blank'. Replaced only while it still lacks 'blank', so a
  -- re-run is a no-op.
  IF EXISTS (SELECT 1 FROM pg_constraint
              WHERE conrelid = 'inform.stance_research_review'::regclass
                AND conname = 'stance_research_review_evidence_type_check'
                AND pg_get_constraintdef(oid) NOT LIKE '%blank%') THEN
    ALTER TABLE inform.stance_research_review
      DROP CONSTRAINT stance_research_review_evidence_type_check;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conrelid = 'inform.stance_research_review'::regclass
                    AND conname = 'stance_research_review_evidence_type_check') THEN
    ALTER TABLE inform.stance_research_review
      ADD CONSTRAINT stance_research_review_evidence_type_check
      CHECK (evidence_type IS NULL OR evidence_type IN ('record', 'statement', 'blank'));
  END IF;
END $$;

COMMENT ON COLUMN inform.stance_research_review.proposed_blank_reason IS
  'CA_0303: codebook V6 blank reason when proposed_value = 0 (a Season 2 blank). '
  'NULL for a chair. Approval writes the open-season answer value 0 and a context row '
  'naming the examined sources (researchEvidenceService.resolveResearchReview).';

DO $$
DECLARE
  v_cols int;
  v_def  text;
BEGIN
  SELECT count(*) INTO v_cols FROM information_schema.columns
   WHERE table_schema = 'inform' AND table_name = 'stance_research_review'
     AND column_name = 'proposed_blank_reason' AND data_type = 'text' AND is_nullable = 'YES';
  IF v_cols <> 1 THEN
    RAISE EXCEPTION 'CA_0303: proposed_blank_reason (nullable text) missing';
  END IF;

  IF (SELECT count(*) FROM pg_constraint
       WHERE conrelid = 'inform.stance_research_review'::regclass AND contype = 'c'
         AND conname IN ('stance_research_review_blank_reason_check',
                         'stance_research_review_blank_pair_check')) <> 2 THEN
    RAISE EXCEPTION 'CA_0303: a blank CHECK is missing';
  END IF;

  SELECT pg_get_constraintdef(oid) INTO v_def FROM pg_constraint
   WHERE conrelid = 'inform.stance_research_review'::regclass
     AND conname = 'stance_research_review_evidence_type_check' AND contype = 'c';
  IF v_def IS NULL OR v_def NOT LIKE '%record%' OR v_def NOT LIKE '%statement%' OR v_def NOT LIKE '%blank%' THEN
    RAISE EXCEPTION 'CA_0303: evidence_type CHECK is %, expected record | statement | blank', v_def;
  END IF;

  IF col_description('inform.stance_research_review'::regclass,
       (SELECT attnum FROM pg_attribute WHERE attrelid = 'inform.stance_research_review'::regclass
          AND attname = 'proposed_blank_reason')) IS NULL THEN
    RAISE EXCEPTION 'CA_0303: column COMMENT missing';
  END IF;

  RAISE NOTICE 'CA_0303 ok: proposed_blank_reason + blank CHECKs; evidence_type now record | statement | blank';
END $$;

COMMIT;
