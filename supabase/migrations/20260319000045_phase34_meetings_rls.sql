-- Phase 34: RLS + grants for meetings schema (7 tables)
-- All tables are public-read. No INSERT/UPDATE/DELETE policies — all writes via service role (pool.query()).

BEGIN;

-- ============================================================
-- Section 1: Enable RLS on every table
-- ============================================================
ALTER TABLE meetings.meeting_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings.meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings.segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings.speakers ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings.summary_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings.vote_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings.votes ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Section 2: Public-read policies
-- ============================================================
CREATE POLICY "meeting_summaries: public read"
  ON meetings.meeting_summaries FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "meetings: public read"
  ON meetings.meetings FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "segments: public read"
  ON meetings.segments FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "speakers: public read"
  ON meetings.speakers FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "summary_sections: public read"
  ON meetings.summary_sections FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "vote_records: public read"
  ON meetings.vote_records FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "votes: public read"
  ON meetings.votes FOR SELECT TO anon, authenticated USING (true);

-- ============================================================
-- Section 3: Grants
-- ============================================================
GRANT USAGE ON SCHEMA meetings TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA meetings TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA meetings GRANT SELECT ON TABLES TO anon, authenticated;

COMMIT;
