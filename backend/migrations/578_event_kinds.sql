-- Migration 578: Add flexible titles and event kinds to meetings.
--
-- Existing rows retain their current display because title is nullable,
-- event_kind backfills to council, and city values are unchanged.

BEGIN;

ALTER TABLE meetings.meetings
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS event_kind TEXT NOT NULL DEFAULT 'council',
  ALTER COLUMN city DROP NOT NULL;

COMMIT;
