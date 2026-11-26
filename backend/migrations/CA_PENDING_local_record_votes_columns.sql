-- Migration CA_PENDING_local_record_votes_columns: link member votes to their roll call
--
-- WHY: the council-record writer stores each member's vote in essentials.legislative_votes and ties it to a roll
--   call, the name as the city printed it, whether the position was worked out from the tally, and the document it
--   was confirmed from.
-- WHAT: four nullable columns, ADD COLUMN IF NOT EXISTS, no DEFAULT and no REFERENCES. Without a default or an
--   inline FK, adding a column to the ~10M-row table is metadata-only (an inline REFERENCES would scan every row
--   for validation while holding ACCESS EXCLUSIVE). The two foreign keys are added NOT VALID (no scan; guarded by a
--   pg_constraint check so the file is idempotent). They are validated afterwards by
--   CA_PENDING_local_record_votes_validate_fks.sql. Existing rows stay NULL.
-- The index on roll_call_id is a separate file (it must be CONCURRENTLY).
-- Needs the roll_calls and source_documents files applied first. No grant or RLS change: the table already has them.
-- Slot: named CA_PENDING until a CA number is reserved. Not applied by this commit. Idempotent.

ALTER TABLE essentials.legislative_votes
  ADD COLUMN IF NOT EXISTS roll_call_id uuid,
  ADD COLUMN IF NOT EXISTS name_as_printed text,
  ADD COLUMN IF NOT EXISTS worked_out boolean,
  ADD COLUMN IF NOT EXISTS confirmed_from uuid;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conrelid = 'essentials.legislative_votes'::regclass
                    AND conname = 'legislative_votes_roll_call_id_fkey') THEN
    ALTER TABLE essentials.legislative_votes
      ADD CONSTRAINT legislative_votes_roll_call_id_fkey
      FOREIGN KEY (roll_call_id) REFERENCES essentials.legislative_roll_calls(id) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conrelid = 'essentials.legislative_votes'::regclass
                    AND conname = 'legislative_votes_confirmed_from_fkey') THEN
    ALTER TABLE essentials.legislative_votes
      ADD CONSTRAINT legislative_votes_confirmed_from_fkey
      FOREIGN KEY (confirmed_from) REFERENCES essentials.local_record_source_documents(id) NOT VALID;
  END IF;
END $$;

-- Post-verify: all four columns exist.
DO $$
BEGIN
  IF (SELECT count(*) FROM information_schema.columns
       WHERE table_schema = 'essentials' AND table_name = 'legislative_votes'
         AND column_name IN ('roll_call_id', 'name_as_printed', 'worked_out', 'confirmed_from')) <> 4 THEN
    RAISE EXCEPTION 'legislative_votes: expected the 4 council-record columns';
  END IF;
END $$;
