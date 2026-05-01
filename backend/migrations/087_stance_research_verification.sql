-- 087_stance_research_verification.sql
-- New tables for the snippet-based stance research verification pipeline.
-- See docs/superpowers/specs/2026-04-30-stance-research-verification-design.md

BEGIN;

-- Persisted snippets for every successfully-verified (politician, topic, source).
-- Replaced wholesale on re-research/upsert (delete by composite key, then insert).
CREATE TABLE IF NOT EXISTS inform.politician_context_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  politician_id uuid NOT NULL REFERENCES essentials.politicians(id) ON DELETE CASCADE,
  topic_id uuid NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  source_url text NOT NULL,
  snippet text NOT NULL,
  snippet_index int NOT NULL,
  verified_at timestamptz NOT NULL DEFAULT now(),
  batch_id text,
  FOREIGN KEY (politician_id, topic_id)
    REFERENCES inform.politician_context(politician_id, topic_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pce_politician_topic
  ON inform.politician_context_evidence (politician_id, topic_id);
CREATE INDEX IF NOT EXISTS idx_pce_source_url
  ON inform.politician_context_evidence (source_url);
CREATE UNIQUE INDEX IF NOT EXISTS uq_pce_pol_topic_url_idx
  ON inform.politician_context_evidence (politician_id, topic_id, source_url, snippet_index);

-- Review queue for rows that fail verification after a single re-research attempt.
-- evidence jsonb captures every snippet's verdict and failure reason.
CREATE TABLE IF NOT EXISTS inform.stance_research_review (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id text NOT NULL,
  politician_id uuid REFERENCES essentials.politicians(id),
  full_name_raw text NOT NULL,
  topic_id uuid REFERENCES inform.compass_topics(id),
  topic_key text NOT NULL,
  proposed_value smallint,
  proposed_reasoning text,
  evidence jsonb NOT NULL,
  verified_source_count int NOT NULL,
  threshold int NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  re_research_attempted boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  resolved_by uuid,
  notes text,
  CONSTRAINT srr_status_check CHECK (status IN
    ('pending','resolved','rejected','superseded','unresolved_politician'))
);

CREATE INDEX IF NOT EXISTS idx_srr_status_batch
  ON inform.stance_research_review (status, batch_id);
CREATE INDEX IF NOT EXISTS idx_srr_politician_topic
  ON inform.stance_research_review (politician_id, topic_id);

-- Idempotent upsert key for re-runs of the same batch.
CREATE UNIQUE INDEX IF NOT EXISTS uq_srr_batch_pol_topic
  ON inform.stance_research_review (batch_id, COALESCE(politician_id::text, full_name_raw), topic_key);

COMMIT;
