-- 1885_evidence_review_reason.sql
-- Structured reject reason for the evidence review surface. Idempotent; hand-applied.
ALTER TABLE inform.evidence_items ADD COLUMN IF NOT EXISTS review_reason text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'evidence_items_review_reason_check'
      AND conrelid = 'inform.evidence_items'::regclass
  ) THEN
    ALTER TABLE inform.evidence_items
      ADD CONSTRAINT evidence_items_review_reason_check
      CHECK (review_reason IS NULL OR review_reason IN
        ('off-question','goal-only','not-verbatim','not-primary','not-forward',
         'is-attack','stale','other'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='inform' AND table_name='evidence_items'
                   AND column_name='review_reason') THEN
    RAISE EXCEPTION 'review_reason column missing after migration';
  END IF;
END $$;
