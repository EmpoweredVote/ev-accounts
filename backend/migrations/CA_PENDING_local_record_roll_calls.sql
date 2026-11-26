-- Migration CA_PENDING_local_record_roll_calls: one row per council roll call
--
-- WHY: the voting record needs the vote itself (question, tally, outcome) separate from each member's vote, and it
--   needs to say whether the city's vote document has confirmed it yet.
-- WHAT: essentials.legislative_roll_calls. state 'pending_minutes' = seen in the city's legislation feed, not yet
--   confirmed from a vote document; 'confirmed' = confirmed from confirmed_from (a source document).
--   feed_disagreement: text when the feed and the document differ on a count. Unique on (city_scope, external_vote_id),
--   which is the key the writer upserts on.
-- PUBLIC READ: anon/authenticated may SELECT (policy "public read"); only service role / API may write.
-- Needs CA_PENDING_local_record_source_documents.sql applied first (confirmed_from references it).
-- Slot: named CA_PENDING until a CA number is reserved. Not applied by this commit. Idempotent.

CREATE TABLE IF NOT EXISTS essentials.legislative_roll_calls (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  city_scope        text NOT NULL,
  bill_id           uuid NOT NULL REFERENCES essentials.legislative_bills(id),
  external_vote_id  text NOT NULL,
  meeting_date      date NOT NULL,
  question          text NOT NULL,
  question_order    int NOT NULL,
  outcome           text NOT NULL CHECK (outcome IN ('passed', 'failed', 'vetoed')),
  yes_count         int,
  no_count          int,
  abstain_count     int,
  not_present_count int,
  state             text NOT NULL CHECK (state IN ('pending_minutes', 'confirmed')),
  confirmed_from    uuid REFERENCES essentials.local_record_source_documents(id),
  feed_disagreement text,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now(),
  UNIQUE (city_scope, external_vote_id)
);

ALTER TABLE essentials.legislative_roll_calls ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON essentials.legislative_roll_calls FROM PUBLIC, anon, authenticated;
GRANT SELECT ON essentials.legislative_roll_calls TO anon, authenticated;
GRANT ALL ON essentials.legislative_roll_calls TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON essentials.legislative_roll_calls TO ev_api;

DROP POLICY IF EXISTS "public read" ON essentials.legislative_roll_calls;
CREATE POLICY "public read"
  ON essentials.legislative_roll_calls FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS legislative_roll_calls_service ON essentials.legislative_roll_calls;
CREATE POLICY legislative_roll_calls_service
  ON essentials.legislative_roll_calls FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS legislative_roll_calls_api ON essentials.legislative_roll_calls;
CREATE POLICY legislative_roll_calls_api
  ON essentials.legislative_roll_calls FOR ALL TO ev_api USING (true) WITH CHECK (true);

-- Post-verify: the shape this file creates.
DO $$
BEGIN
  IF to_regclass('essentials.legislative_roll_calls') IS NULL THEN
    RAISE EXCEPTION 'legislative_roll_calls missing';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'essentials.legislative_roll_calls'::regclass) THEN
    RAISE EXCEPTION 'legislative_roll_calls: RLS is off';
  END IF;
  IF has_table_privilege('anon', 'essentials.legislative_roll_calls', 'INSERT')
     OR has_table_privilege('anon', 'essentials.legislative_roll_calls', 'UPDATE')
     OR has_table_privilege('anon', 'essentials.legislative_roll_calls', 'DELETE')
     OR has_table_privilege('authenticated', 'essentials.legislative_roll_calls', 'INSERT')
     OR has_table_privilege('authenticated', 'essentials.legislative_roll_calls', 'UPDATE')
     OR has_table_privilege('authenticated', 'essentials.legislative_roll_calls', 'DELETE') THEN
    RAISE EXCEPTION 'legislative_roll_calls: anon/authenticated can write';
  END IF;
END $$;
