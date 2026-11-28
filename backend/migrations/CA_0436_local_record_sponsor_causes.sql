-- Migration CA_0436_local_record_sponsor_causes: sponsor exception causes and the legislation_feed document kind
--
-- WHY: the council sponsors work logs a row instead of guessing when a sponsor name does not resolve to one member
--   or when two sources name different sponsors. It also keeps a copy of the legislation feed as proof.
-- WHAT: widens two CHECK constraints, both created inline (so Postgres named them <table>_<column>_check).
--   essentials.local_record_exceptions.cause: adds 'sponsor_unresolved' and 'sponsor_disagrees' (13 -> 15 values).
--     The CHECK list equals EXCEPTION_CAUSES in backend/src/lib/localRecord/types.ts; a test keeps them equal.
--   essentials.local_record_source_documents.kind: adds 'legislation_feed' (3 -> 4 values).
-- Needs CA_0426 and CA_0428 applied first. Does not depend on CA_0435, and CA_0435 does not depend on this file.
-- Overwrites nothing: it only loosens two CHECKs, so every existing row still passes. Old lists, for reference:
--   cause: unknown_name, not_seated, tally_mismatch, unplaced_note, outcome_conflict, unknown_item,
--     feed_missing_final, file_changed, control_failed, unparsed_roll_call, inventory_disagrees, spot_check_failed,
--     minutes_disagree. kind: memorandum, minutes, item_text.
-- Slot: CA_0436, reserved by the owner. Not applied by this commit. Idempotent.

ALTER TABLE essentials.local_record_exceptions
  DROP CONSTRAINT IF EXISTS local_record_exceptions_cause_check;
ALTER TABLE essentials.local_record_exceptions
  ADD CONSTRAINT local_record_exceptions_cause_check CHECK (cause IN (
    'unknown_name', 'not_seated', 'tally_mismatch', 'unplaced_note', 'outcome_conflict',
    'unknown_item', 'feed_missing_final', 'file_changed', 'control_failed', 'unparsed_roll_call',
    'inventory_disagrees', 'spot_check_failed', 'minutes_disagree',
    'sponsor_unresolved', 'sponsor_disagrees'));

ALTER TABLE essentials.local_record_source_documents
  DROP CONSTRAINT IF EXISTS local_record_source_documents_kind_check;
ALTER TABLE essentials.local_record_source_documents
  ADD CONSTRAINT local_record_source_documents_kind_check CHECK (kind IN (
    'memorandum', 'minutes', 'item_text', 'legislation_feed'));

-- Post-verify: both constraints exist and carry the new values.
DO $$
DECLARE
  cause_def text;
  kind_def  text;
BEGIN
  SELECT pg_get_constraintdef(oid) INTO cause_def FROM pg_constraint
    WHERE conrelid = 'essentials.local_record_exceptions'::regclass
      AND conname = 'local_record_exceptions_cause_check';
  SELECT pg_get_constraintdef(oid) INTO kind_def FROM pg_constraint
    WHERE conrelid = 'essentials.local_record_source_documents'::regclass
      AND conname = 'local_record_source_documents_kind_check';
  IF cause_def IS NULL OR cause_def NOT LIKE '%sponsor_unresolved%' OR cause_def NOT LIKE '%sponsor_disagrees%'
     OR cause_def NOT LIKE '%minutes_disagree%' THEN
    RAISE EXCEPTION 'local_record_exceptions cause CHECK is wrong: %', cause_def;
  END IF;
  IF kind_def IS NULL OR kind_def NOT LIKE '%legislation_feed%' OR kind_def NOT LIKE '%item_text%' THEN
    RAISE EXCEPTION 'local_record_source_documents kind CHECK is wrong: %', kind_def;
  END IF;
END $$;
