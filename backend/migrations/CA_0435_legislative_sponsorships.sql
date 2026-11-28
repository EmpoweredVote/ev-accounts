-- Migration CA_0435_legislative_sponsorships: who sponsored or co-sponsored a council item or amendment, with proof
--
-- WHY: the council record shows which members authored and co-sponsored each item and amendment. Each row must be
--   backed by a source, and the sentence shown to readers is written only when every name in it resolves.
-- WHAT: essentials.legislative_sponsorships. One row per (bill, amendment, member). amendment_label is NULL for the
--   item itself, else the roll-call question form ("Amendment 01", "Reasonable Condition 2"). role is 'sponsor' or
--   'cosponsor'. name_as_printed is the name exactly as the source prints it. sentence is the finished text.
--   source_kind says where the proof comes from: 'legislation_feed', 'memorandum' or 'minutes'; source_document_id
--   points at the saved copy. Unique on (bill_id, coalesce(amendment_label, ''), politician_id), which is the key
--   the writer upserts on. No party column (antipartisan rule). Nothing here reads the old
--   legislative_bills.sponsor_id rows.
-- PUBLIC READ: anon/authenticated may SELECT (policy "public read"); only service role / API may write.
-- Needs CA_0426_local_record_source_documents.sql applied first (source_document_id references it). Does not depend
--   on CA_0436, and CA_0436 does not depend on this file.
-- Slot: CA_0435, reserved by the owner. Not applied by this commit. Idempotent.

CREATE TABLE IF NOT EXISTS essentials.legislative_sponsorships (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  city_scope         text NOT NULL,
  bill_id            uuid NOT NULL REFERENCES essentials.legislative_bills(id),
  amendment_label    text,
  politician_id      uuid NOT NULL REFERENCES essentials.politicians(id),
  role               text NOT NULL CHECK (role IN ('sponsor', 'cosponsor')),
  name_as_printed    text NOT NULL,
  sentence           text NOT NULL,
  source_kind        text NOT NULL CHECK (source_kind IN ('legislation_feed', 'memorandum', 'minutes')),
  source_document_id uuid NOT NULL REFERENCES essentials.local_record_source_documents(id),
  created_at         timestamptz DEFAULT now(),
  updated_at         timestamptz DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS legislative_sponsorships_bill_amendment_politician_uq
  ON essentials.legislative_sponsorships (bill_id, coalesce(amendment_label, ''), politician_id);
CREATE INDEX IF NOT EXISTS legislative_sponsorships_politician_idx
  ON essentials.legislative_sponsorships (politician_id);

ALTER TABLE essentials.legislative_sponsorships ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON essentials.legislative_sponsorships FROM PUBLIC, anon, authenticated;
GRANT SELECT ON essentials.legislative_sponsorships TO anon, authenticated;
GRANT ALL ON essentials.legislative_sponsorships TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON essentials.legislative_sponsorships TO ev_api;

DROP POLICY IF EXISTS "public read" ON essentials.legislative_sponsorships;
CREATE POLICY "public read"
  ON essentials.legislative_sponsorships FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS legislative_sponsorships_service ON essentials.legislative_sponsorships;
CREATE POLICY legislative_sponsorships_service
  ON essentials.legislative_sponsorships FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS legislative_sponsorships_api ON essentials.legislative_sponsorships;
CREATE POLICY legislative_sponsorships_api
  ON essentials.legislative_sponsorships FOR ALL TO ev_api USING (true) WITH CHECK (true);

-- Post-verify: the shape this file creates.
DO $$
BEGIN
  IF to_regclass('essentials.legislative_sponsorships') IS NULL THEN
    RAISE EXCEPTION 'legislative_sponsorships missing';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'essentials.legislative_sponsorships'::regclass) THEN
    RAISE EXCEPTION 'legislative_sponsorships: RLS is off';
  END IF;
  IF to_regclass('essentials.legislative_sponsorships_bill_amendment_politician_uq') IS NULL THEN
    RAISE EXCEPTION 'legislative_sponsorships: unique index missing';
  END IF;
  IF has_table_privilege('anon', 'essentials.legislative_sponsorships', 'INSERT')
     OR has_table_privilege('anon', 'essentials.legislative_sponsorships', 'UPDATE')
     OR has_table_privilege('anon', 'essentials.legislative_sponsorships', 'DELETE')
     OR has_table_privilege('authenticated', 'essentials.legislative_sponsorships', 'INSERT')
     OR has_table_privilege('authenticated', 'essentials.legislative_sponsorships', 'UPDATE')
     OR has_table_privilege('authenticated', 'essentials.legislative_sponsorships', 'DELETE') THEN
    RAISE EXCEPTION 'legislative_sponsorships: anon/authenticated can write';
  END IF;
END $$;
