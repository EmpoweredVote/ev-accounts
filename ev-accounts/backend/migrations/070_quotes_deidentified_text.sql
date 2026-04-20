-- 070: Add deidentified_text column + snapshot backup to essentials.quotes
--
-- Quick task 260420-rh4 (Read-Rank quote limit + deidentification).
--
-- Adds a nullable `deidentified_text` column so Claude-rewritten speaker-obscured
-- quote versions can coexist with originals. The backend serves
--   COALESCE(q.deidentified_text, q.quote_text)
-- as the public `text` field to Read-Rank, so NULL means "original is safe to
-- serve as-is".
--
-- Also creates a one-time snapshot backup table `essentials.quotes_backup_260420`
-- BEFORE the interactive curation step (Task 2) runs any DELETEs. The backup is
-- an immutable snapshot — it is NOT a live mirror and must not be modified by
-- later curation scripts.
--
-- Schema observed before migration (information_schema.columns, 2026-04-20):
--   id            uuid        NOT NULL  default gen_random_uuid()  PRIMARY KEY
--   politician_id uuid        NOT NULL
--   topic_key     text        NOT NULL
--   quote_text    text        NOT NULL
--   source_url    text        NULL
--   source_name   text        NULL
--   created_at    timestamptz NULL
--   updated_at    timestamptz NULL
-- Row count at migration time: 114. Only PK constraint present — no
-- (politician_id, topic_key) uniqueness (deliberate: Task 2 caps at 2 per group).

BEGIN;

ALTER TABLE essentials.quotes
  ADD COLUMN IF NOT EXISTS deidentified_text TEXT;

COMMENT ON COLUMN essentials.quotes.deidentified_text IS
  'Claude-rewritten speaker-obscured version. NULL = original safe to serve. Populated by scripts/deidentifyQuotes.ts with human approval (260420-rh4).';

-- Snapshot backup of the full quotes table BEFORE curation deletes anything.
-- Safe to re-run: if the backup table already exists we keep the original snapshot
-- (do NOT overwrite it — the whole point is pre-curation state).
CREATE TABLE IF NOT EXISTS essentials.quotes_backup_260420 AS
  TABLE essentials.quotes;

COMMENT ON TABLE essentials.quotes_backup_260420 IS
  'Immutable pre-curation snapshot of essentials.quotes taken 2026-04-20 before quick task 260420-rh4 interactive curation deletes. Do not modify.';

COMMIT;
