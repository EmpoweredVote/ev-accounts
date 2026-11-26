-- Migration CA_PENDING_local_record_source_documents: saved copies of the city's vote documents
--
-- WHY: the Bloomington Common Council voting record (design: docs/superpowers, "council record") confirms
--   each vote from a document the city publishes. We keep the exact bytes we read, so a later reader can see what
--   a vote was confirmed from, and so a file the city changes after the fact is noticed (new sha256).
-- WHAT: essentials.local_record_source_documents. One row per (source_url, sha256). The bytes live in storage at
--   storage_path. At most one row per URL is current (superseded_by IS NULL); older copies point at the current one.
--   kind: 'memorandum' (the clerk's Memorandum, which confirms votes: decision D14), 'minutes' (the formal minutes,
--   rechecked later), 'item_text' (the text of a legislation item).
-- PRIVATE: service role / API only. No anon or authenticated grant and no policy for them. RLS is on. New tables in
--   this schema get anon/authenticated SELECT by default privileges, so they are revoked here explicitly.
-- Slot: named CA_PENDING until a CA number is reserved; rename (and update the header) at reservation.
-- Create order: this file first, then roll_calls (it references this table), then exceptions, votes columns, index.
-- Not applied by this commit. Idempotent: safe to re-run.

CREATE TABLE IF NOT EXISTS essentials.local_record_source_documents (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  city_scope    text NOT NULL,
  kind          text NOT NULL CHECK (kind IN ('memorandum', 'minutes', 'item_text')),
  source_url    text NOT NULL,
  city_file_id  text,
  fetched_at    timestamptz NOT NULL,
  sha256        text NOT NULL,
  storage_path  text NOT NULL,
  superseded_by uuid REFERENCES essentials.local_record_source_documents(id),
  UNIQUE (source_url, sha256)
);

ALTER TABLE essentials.local_record_source_documents ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON essentials.local_record_source_documents FROM anon, authenticated;
GRANT ALL ON essentials.local_record_source_documents TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON essentials.local_record_source_documents TO ev_api;

DROP POLICY IF EXISTS local_record_source_documents_service ON essentials.local_record_source_documents;
CREATE POLICY local_record_source_documents_service
  ON essentials.local_record_source_documents FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS local_record_source_documents_api ON essentials.local_record_source_documents;
CREATE POLICY local_record_source_documents_api
  ON essentials.local_record_source_documents FOR ALL TO ev_api USING (true) WITH CHECK (true);

-- Post-verify: the shape this file creates.
DO $$
BEGIN
  IF to_regclass('essentials.local_record_source_documents') IS NULL THEN
    RAISE EXCEPTION 'local_record_source_documents missing';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'essentials.local_record_source_documents'::regclass) THEN
    RAISE EXCEPTION 'local_record_source_documents: RLS is off';
  END IF;
  IF has_table_privilege('anon', 'essentials.local_record_source_documents', 'SELECT')
     OR has_table_privilege('authenticated', 'essentials.local_record_source_documents', 'SELECT') THEN
    RAISE EXCEPTION 'local_record_source_documents: anon/authenticated can still read';
  END IF;
END $$;
