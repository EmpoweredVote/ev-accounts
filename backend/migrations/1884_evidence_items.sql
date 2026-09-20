-- 1884_evidence_items.sql
-- New evidence store for the on-the-record trust-core pipeline. Standalone verbatim
-- evidence items (quotes now; votes/actions later), season-agnostic, with a human
-- review state. Idempotent; safe to re-run. Applied by hand (no runner).

CREATE TABLE IF NOT EXISTS inform.evidence_items (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  politician_id     uuid NOT NULL REFERENCES essentials.politicians(id) ON DELETE CASCADE,
  topic_id          uuid REFERENCES inform.compass_topics(id),
  issue             text NOT NULL,
  evidence_type     text NOT NULL DEFAULT 'quote' CHECK (evidence_type IN ('quote')),
  verbatim_text     text NOT NULL,
  source_url        text NOT NULL,
  deep_link         text,
  context           text,
  source_type       text NOT NULL,
  source_cycle_year text,
  machine_status    text NOT NULL CHECK (machine_status IN ('green','flagged')),
  gate_flags        jsonb NOT NULL DEFAULT '{}'::jsonb,
  provenance        jsonb NOT NULL DEFAULT '{}'::jsonb,
  batch_id          text,
  review_status     text NOT NULL DEFAULT 'pending'
                      CHECK (review_status IN ('pending','accepted','rejected')),
  reviewed_by       uuid,
  reviewed_at       timestamptz,
  review_note       text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_evidence_pol_src_text
  ON inform.evidence_items (politician_id, source_url, md5(lower(verbatim_text)));
CREATE INDEX IF NOT EXISTS idx_evidence_politician_issue
  ON inform.evidence_items (politician_id, issue);
CREATE INDEX IF NOT EXISTS idx_evidence_topic
  ON inform.evidence_items (topic_id) WHERE topic_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_evidence_review_status
  ON inform.evidence_items (review_status);

-- Post-verify gate (house style): fail loudly if the shape isn't what we expect.
DO $$
BEGIN
  IF to_regclass('inform.evidence_items') IS NULL THEN
    RAISE EXCEPTION 'inform.evidence_items missing after migration';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes
                 WHERE schemaname='inform' AND indexname='uq_evidence_pol_src_text') THEN
    RAISE EXCEPTION 'uq_evidence_pol_src_text missing after migration';
  END IF;
END $$;
