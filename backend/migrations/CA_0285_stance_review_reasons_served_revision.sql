BEGIN;

-- ⚠ NOT APPLIED. Dry-run on production 2026-09-24 inside BEGIN…ROLLBACK (see
-- .superpowers/sdd/2026-09-23-stance-program-reconciliation/final-fix2-report.md);
-- apply only with the operator's explicit OK.

-- =============================================================================
-- CA_0285: a queued stance-review row records WHY it was queued, its evidence
--          class, and the SERVED ladder revision the researcher was shown
-- =============================================================================
-- Final whole-branch review of claude/stance-research-hardening, findings I2 and C1.
--
--   queue_reasons       decidePublish's reasons (scripts/lib/stancePublishPolicy.ts):
--                       statement-evidence, gate-medium, value-change,
--                       review-all-mode, unresolved-politician, below-threshold.
--                       Under review-all every stance is queued, so without this
--                       a statement row, a gate-medium row and a clean record row
--                       look the same to the reviewer.
--   evidence_type       record | statement, from research.csv.
--   served_revision_id  the SERVED revision (ADR 0006: the latest published /
--                       superseded revision of the pin's version) whose rung text
--                       the researcher was shown. topic_revision_id (CA_0264)
--                       stays the PIN — what the answer write records. Approval
--                       refuses a row when either one no longer matches the open
--                       season: a clarifying publish moves the served text
--                       without moving the pin, and research is judged against
--                       served text.
--
-- 🔴 NO BACKFILL, on purpose, as in CA_0264. A row queued before this migration
-- never recorded any of the three, and none can be reconstructed. They read as
-- NULL = "not recorded"; the review page says so, and approval falls back to the
-- pin comparison alone.
--
-- Purely additive and NULLABLE. The backend probes information_schema and names
-- these columns in the queue INSERT only once they exist
-- (researchEvidenceService.reviewOptionalColumns), and reads them through `r.*`,
-- so the code runs unchanged before and after this apply.
-- =============================================================================

ALTER TABLE inform.stance_research_review
  ADD COLUMN IF NOT EXISTS served_revision_id uuid REFERENCES inform.compass_topic_revisions(id),
  ADD COLUMN IF NOT EXISTS queue_reasons      text[],
  ADD COLUMN IF NOT EXISTS evidence_type      text;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conrelid = 'inform.stance_research_review'::regclass
                    AND conname = 'stance_research_review_evidence_type_check') THEN
    ALTER TABLE inform.stance_research_review
      ADD CONSTRAINT stance_research_review_evidence_type_check
      CHECK (evidence_type IS NULL OR evidence_type IN ('record', 'statement'));
  END IF;
END $$;

COMMENT ON COLUMN inform.stance_research_review.served_revision_id IS
  'The SERVED ladder revision (ADR 0006: latest published/superseded revision of '
  'the pin''s version) whose rung text the researcher was shown — topics.json '
  'served_revision_id, written by verify-stance-research.ts at queue time. '
  'topic_revision_id stays the pin. NULL = queued before CA_0285 (2026-09-24), '
  'not backfilled.';
COMMENT ON COLUMN inform.stance_research_review.queue_reasons IS
  'Why decidePublish (scripts/lib/stancePublishPolicy.ts) queued this row: '
  'statement-evidence, gate-medium, value-change, review-all-mode, '
  'unresolved-politician, below-threshold. NULL = queued before CA_0285, not backfilled.';
COMMENT ON COLUMN inform.stance_research_review.evidence_type IS
  'record | statement, from the batch research.csv. NULL = queued before CA_0285, not backfilled.';

DO $$
DECLARE
  v_cols int;
  v_fk   regclass;
BEGIN
  SELECT count(*) INTO v_cols FROM information_schema.columns
   WHERE table_schema = 'inform' AND table_name = 'stance_research_review' AND is_nullable = 'YES'
     AND ((column_name = 'served_revision_id' AND data_type = 'uuid')
       OR (column_name = 'queue_reasons'      AND data_type = 'ARRAY' AND udt_name = '_text')
       OR (column_name = 'evidence_type'      AND data_type = 'text'));
  IF v_cols <> 3 THEN
    RAISE EXCEPTION 'CA_0285: expected 3 nullable columns (served_revision_id uuid, queue_reasons text[], evidence_type text), found %', v_cols;
  END IF;

  SELECT c.confrelid::regclass INTO v_fk
    FROM pg_constraint c
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
   WHERE c.contype = 'f' AND c.conrelid = 'inform.stance_research_review'::regclass
     AND a.attname = 'served_revision_id';
  IF v_fk IS DISTINCT FROM 'inform.compass_topic_revisions'::regclass THEN
    RAISE EXCEPTION 'CA_0285: served_revision_id FK points at %, expected inform.compass_topic_revisions', v_fk;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conrelid = 'inform.stance_research_review'::regclass
                    AND conname = 'stance_research_review_evidence_type_check' AND contype = 'c') THEN
    RAISE EXCEPTION 'CA_0285: evidence_type CHECK is missing';
  END IF;

  IF (SELECT count(*) FROM pg_attribute
       WHERE attrelid = 'inform.stance_research_review'::regclass
         AND attname IN ('served_revision_id', 'queue_reasons', 'evidence_type')
         AND col_description(attrelid, attnum) IS NOT NULL) <> 3 THEN
    RAISE EXCEPTION 'CA_0285: a column COMMENT is missing';
  END IF;

  RAISE NOTICE 'CA_0285 ok: served_revision_id -> %, queue_reasons text[], evidence_type (record|statement); legacy rows left NULL', v_fk;
END $$;

COMMIT;
