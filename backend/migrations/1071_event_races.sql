-- Migration 1071: meetings.event_races — a meeting belongs to MANY races.
-- Replaces the single meetings.meetings.race_id (dropped in 1072, after the
-- API is switched to read this table). Backfills existing single-race links.

BEGIN;

CREATE TABLE IF NOT EXISTS meetings.event_races (
  meeting_id UUID NOT NULL REFERENCES meetings.meetings(id) ON DELETE CASCADE,
  race_id    UUID NOT NULL REFERENCES essentials.races(id),
  PRIMARY KEY (meeting_id, race_id)          -- serves meeting -> races
);

CREATE INDEX IF NOT EXISTS event_races_race_id_idx
  ON meetings.event_races (race_id);          -- serves race -> meetings

-- Backfill from the existing single-race column.
INSERT INTO meetings.event_races (meeting_id, race_id)
SELECT id, race_id
FROM meetings.meetings
WHERE race_id IS NOT NULL
ON CONFLICT DO NOTHING;

COMMIT;
