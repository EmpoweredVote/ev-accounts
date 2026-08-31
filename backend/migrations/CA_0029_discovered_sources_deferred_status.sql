-- CA_0029_discovered_sources_deferred_status.sql
-- Adds the 'deferred' status to essentials.discovered_sources. 'deferred' hides a
-- low-value discovered item from the human triage queue WITHOUT deleting it: the
-- zero-source alarm (essentials.discovered_sources status IN ('approved','ingested'))
-- is unaffected, so a starved race still alarms and a person can restore a deferred
-- item. Idempotent; safe to re-run.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'essentials.discovered_sources'::regclass
      AND conname  = 'discovered_sources_status_check'
      AND pg_get_constraintdef(oid) LIKE '%deferred%'
  ) THEN
    ALTER TABLE essentials.discovered_sources
      DROP CONSTRAINT IF EXISTS discovered_sources_status_check;
    ALTER TABLE essentials.discovered_sources
      ADD CONSTRAINT discovered_sources_status_check
      CHECK (status = ANY (ARRAY[
        'pending'::text, 'auto_filtered'::text, 'approved'::text,
        'rejected'::text, 'ingested'::text, 'superseded'::text,
        'deferred'::text]));
  END IF;
END $$;

-- post-verify gate: the constraint must now admit 'deferred'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'essentials.discovered_sources'::regclass
      AND conname  = 'discovered_sources_status_check'
      AND pg_get_constraintdef(oid) LIKE '%deferred%'
  ) THEN
    RAISE EXCEPTION 'CA_0029 post-verify failed: deferred not admitted by discovered_sources_status_check';
  END IF;
END $$;
