-- Migration 1072: drop the single-race column now that meetings.event_races is
-- the source of truth and all readers/writers use it. GATED: apply only after
-- the ev-accounts API (event_races reads) and the on-the-record pipeline
-- (event_races writes) are both deployed.

BEGIN;

DROP INDEX IF EXISTS meetings.meetings_meetings_race_id_idx;

ALTER TABLE meetings.meetings
  DROP COLUMN IF EXISTS race_id;

COMMIT;
