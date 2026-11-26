-- Migration CA_PENDING_local_record_exceptions: things a person must look at in the council record
--
-- WHY: when the weekly run cannot confirm a vote (unknown name, tally mismatch, a file that changed ...) it logs
--   one row here instead of guessing. A person reads the report and resolves each row.
-- WHAT: essentials.local_record_exceptions. One row per (city_scope, cause, subject). The writer reopens a resolved
--   row only when its detail changed. opened_at is when the row opened, and restarts on a reopen; the weekly report
--   dates exceptions by it. cause CHECK = EXCEPTION_CAUSES in backend/src/lib/localRecord/types.ts (13 values; a
--   test keeps them equal). 'minutes_disagree' = formal Minutes disagree with a vote already confirmed from the
--   Memorandum (decision D14).
-- PRIVATE: service role / API only. No anon or authenticated grant or policy. RLS is on.
-- Slot: named CA_PENDING until a CA number is reserved. Not applied by this commit. Idempotent.

CREATE TABLE IF NOT EXISTS essentials.local_record_exceptions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  city_scope  text NOT NULL,
  run_id      text NOT NULL,
  cause       text NOT NULL CHECK (cause IN (
                'unknown_name', 'not_seated', 'tally_mismatch', 'unplaced_note', 'outcome_conflict',
                'unknown_item', 'feed_missing_final', 'file_changed', 'control_failed', 'unparsed_roll_call',
                'inventory_disagrees', 'spot_check_failed', 'minutes_disagree')),
  subject     text NOT NULL,
  detail      jsonb NOT NULL,
  status      text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
  resolved_by text,
  resolution  text,
  opened_at   timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now(),
  UNIQUE (city_scope, cause, subject)
);

ALTER TABLE essentials.local_record_exceptions ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON essentials.local_record_exceptions FROM PUBLIC, anon, authenticated;
GRANT ALL ON essentials.local_record_exceptions TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON essentials.local_record_exceptions TO ev_api;

DROP POLICY IF EXISTS local_record_exceptions_service ON essentials.local_record_exceptions;
CREATE POLICY local_record_exceptions_service
  ON essentials.local_record_exceptions FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS local_record_exceptions_api ON essentials.local_record_exceptions;
CREATE POLICY local_record_exceptions_api
  ON essentials.local_record_exceptions FOR ALL TO ev_api USING (true) WITH CHECK (true);

-- Post-verify: the shape this file creates.
DO $$
BEGIN
  IF to_regclass('essentials.local_record_exceptions') IS NULL THEN
    RAISE EXCEPTION 'local_record_exceptions missing';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'essentials.local_record_exceptions'::regclass) THEN
    RAISE EXCEPTION 'local_record_exceptions: RLS is off';
  END IF;
  IF has_table_privilege('anon', 'essentials.local_record_exceptions', 'SELECT')
     OR has_table_privilege('authenticated', 'essentials.local_record_exceptions', 'SELECT') THEN
    RAISE EXCEPTION 'local_record_exceptions: anon/authenticated can still read';
  END IF;
END $$;
