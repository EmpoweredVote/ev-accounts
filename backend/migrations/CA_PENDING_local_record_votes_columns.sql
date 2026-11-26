-- Migration CA_PENDING_local_record_votes_columns: link member votes to their roll call
--
-- WHY: the council-record writer stores each member's vote in essentials.legislative_votes and ties it to a roll
--   call, the name as the city printed it, whether the position was worked out from the tally, and the document it
--   was confirmed from.
-- WHAT: four nullable columns, ADD COLUMN IF NOT EXISTS, no DEFAULT. On the ~10M-row table this is metadata-only
--   (no rewrite). Existing rows stay NULL. The index on roll_call_id is a separate file (it must be CONCURRENTLY).
-- Needs the roll_calls and source_documents files applied first. No grant or RLS change: the table already has them.
-- Slot: named CA_PENDING until a CA number is reserved. Not applied by this commit. Idempotent.

ALTER TABLE essentials.legislative_votes
  ADD COLUMN IF NOT EXISTS roll_call_id uuid REFERENCES essentials.legislative_roll_calls(id),
  ADD COLUMN IF NOT EXISTS name_as_printed text,
  ADD COLUMN IF NOT EXISTS worked_out boolean,
  ADD COLUMN IF NOT EXISTS confirmed_from uuid REFERENCES essentials.local_record_source_documents(id);

-- Post-verify: all four columns exist.
DO $$
BEGIN
  IF (SELECT count(*) FROM information_schema.columns
       WHERE table_schema = 'essentials' AND table_name = 'legislative_votes'
         AND column_name IN ('roll_call_id', 'name_as_printed', 'worked_out', 'confirmed_from')) <> 4 THEN
    RAISE EXCEPTION 'legislative_votes: expected the 4 council-record columns';
  END IF;
END $$;
