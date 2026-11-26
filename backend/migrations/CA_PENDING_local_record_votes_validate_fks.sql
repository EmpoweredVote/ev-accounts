-- Migration CA_PENDING_local_record_votes_validate_fks: validate the two council-record foreign keys
--
-- WHY: CA_PENDING_local_record_votes_columns.sql adds the foreign keys NOT VALID so it holds ACCESS EXCLUSIVE only
--   briefly. A NOT VALID key is already enforced for new and changed rows; this file checks the existing rows.
-- WHAT: VALIDATE CONSTRAINT on legislative_votes_roll_call_id_fkey and legislative_votes_confirmed_from_fkey.
--   Run it AFTER the columns file, in its own transaction (apply-migration-file.mjs is fine). It scans the table
--   but takes only SHARE UPDATE EXCLUSIVE, so reads and writes continue. Validating an already-valid constraint is
--   a no-op, so the file is safe to re-run. At first apply every existing row has NULL in both columns, so the
--   check passes. Not applied by this commit.
-- Slot: named CA_PENDING until a CA number is reserved.

ALTER TABLE essentials.legislative_votes VALIDATE CONSTRAINT legislative_votes_roll_call_id_fkey;
ALTER TABLE essentials.legislative_votes VALIDATE CONSTRAINT legislative_votes_confirmed_from_fkey;

-- Post-verify: both constraints are validated.
DO $$
BEGIN
  IF (SELECT count(*) FROM pg_constraint
       WHERE conrelid = 'essentials.legislative_votes'::regclass
         AND conname IN ('legislative_votes_roll_call_id_fkey', 'legislative_votes_confirmed_from_fkey')
         AND convalidated) <> 2 THEN
    RAISE EXCEPTION 'legislative_votes: council-record foreign keys not both validated';
  END IF;
END $$;
