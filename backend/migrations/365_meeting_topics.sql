-- Migration 365: meeting_topics — AI-predicted Compass-issue tags on meeting
-- discussion sections (Phase 6). topic_key is a soft reference to
-- inform.compass_topics.topic_key (resolved by join to the live version).

CREATE TABLE IF NOT EXISTS meetings.meeting_topics (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  meeting_id     UUID NOT NULL REFERENCES meetings.meetings(id) ON DELETE CASCADE,
  section_index  INT  NOT NULL,
  topic_key      TEXT NOT NULL,
  status         TEXT NOT NULL DEFAULT 'predicted',
  confidence     REAL,
  model          TEXT,
  section_title  TEXT,
  section_type   TEXT,
  start_time     REAL,
  end_time       REAL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS meeting_topics_topic_key_idx ON meetings.meeting_topics(topic_key);
CREATE INDEX IF NOT EXISTS meeting_topics_meeting_id_idx ON meetings.meeting_topics(meeting_id);
