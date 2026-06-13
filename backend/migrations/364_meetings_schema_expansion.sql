-- Migration 364: Expand meetings.* schema for on-the-record pipeline integration.
--
-- The on-the-record pipeline (CouncilScribe) publishes processed city council
-- meeting recordings here instead of the civic.* schema. Key changes:
--   - meetings.meetings: add on-the-record fields, fix date type, make state nullable
--   - meetings.speakers: add politician_slug for slug-based cross-referencing
--   - meetings.segments: add denormalized display fields + full-text search

-- ── meetings.meetings ──────────────────────────────────────────────────────────

ALTER TABLE meetings.meetings
  ADD COLUMN IF NOT EXISTS body_slug          TEXT,
  ADD COLUMN IF NOT EXISTS source_url         TEXT,
  ADD COLUMN IF NOT EXISTS playback_kind      TEXT,
  ADD COLUMN IF NOT EXISTS slug               TEXT,
  ADD COLUMN IF NOT EXISTS summary            JSONB,
  ADD COLUMN IF NOT EXISTS processing_metadata JSONB;

-- state was NOT NULL; on-the-record pipeline doesn't always know the state
ALTER TABLE meetings.meetings
  ALTER COLUMN state DROP NOT NULL;

-- date was timestamptz; on-the-record works with calendar dates only
ALTER TABLE meetings.meetings
  ALTER COLUMN date TYPE DATE USING date::DATE;

-- slug is unique when present (NULL rows are not compared)
CREATE UNIQUE INDEX IF NOT EXISTS meetings_meetings_slug_key
  ON meetings.meetings(slug)
  WHERE slug IS NOT NULL;

-- ── meetings.speakers ─────────────────────────────────────────────────────────

-- politician_slug allows cross-referencing with essentials schema without
-- requiring the UUID to be present (pipeline may only know the slug)
ALTER TABLE meetings.speakers
  ADD COLUMN IF NOT EXISTS politician_slug TEXT;

-- ── meetings.segments ─────────────────────────────────────────────────────────

-- Denormalized from speakers for efficient transcript rendering (avoids a join
-- per segment on every transcript page load)
ALTER TABLE meetings.segments
  ADD COLUMN IF NOT EXISTS speaker_name    TEXT,
  ADD COLUMN IF NOT EXISTS politician_slug TEXT,
  ADD COLUMN IF NOT EXISTS confidence      REAL;

-- Full-text search over transcript text
ALTER TABLE meetings.segments
  ADD COLUMN IF NOT EXISTS tsv TSVECTOR;

CREATE OR REPLACE FUNCTION meetings.update_segment_tsv()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.tsv := to_tsvector('english', COALESCE(NEW.text, ''));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS segments_tsv_trigger ON meetings.segments;
CREATE TRIGGER segments_tsv_trigger
  BEFORE INSERT OR UPDATE OF text ON meetings.segments
  FOR EACH ROW EXECUTE FUNCTION meetings.update_segment_tsv();

CREATE INDEX IF NOT EXISTS meetings_segments_tsv_idx
  ON meetings.segments USING GIN(tsv);

CREATE INDEX IF NOT EXISTS meetings_segments_politician_slug_idx
  ON meetings.segments(politician_slug);

CREATE INDEX IF NOT EXISTS meetings_segments_meeting_id_idx
  ON meetings.segments(meeting_id);

CREATE INDEX IF NOT EXISTS meetings_speakers_meeting_id_idx
  ON meetings.speakers(meeting_id);
