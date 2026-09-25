-- backend/migrations/CA_0292_codebook_reliability_schema.sql
BEGIN;

-- ⚠ NOT APPLIED until the operator says so. Dry-run first inside BEGIN…ROLLBACK.
-- =============================================================================
-- CA_0292: codebook + inter-coder reliability schema
-- =============================================================================
-- Spec: docs/superpowers/specs/2026-09-25-stance-quote-codebook-reliability-design.md §4.
--
--   source_snapshots           what the coders saw — full text for public records / own site /
--                              transcripts, excerpt windows only for news and pointers (§5.4).
--                              id is DETERMINISTIC (UUIDv5 layout over batch|url|page_sha256|
--                              sha256(snapshot_text), snapshotSources.ts snapshotIdFor): a re-run of
--                              the same page and excerpt reproduces the id the coders cited, and a
--                              changed excerpt gets a new id. So id is the only uniqueness needed.
--   stance_coder_labels        one row per coder per (batch, politician, office, topic)
--   stance_gold_labels         one row per HUMAN decision. APPEND-ONLY: the chair a person chose
--                              must not be rewritten by later answer writes (today it lives only in
--                              politician_answers, which later writes change — Moore/social-security
--                              was approved as 4 and reads 5 today). A correction is a new row with
--                              supersedes_id. Only excluded_from_cert, politician_id, office_id and
--                              review_id may be updated — the first two for duplicate-person merges,
--                              the last two nulled by ON DELETE SET NULL on office retirement /
--                              review-row delete.
--   reliability_certifications one row per computation; never updated. decidePublish (P3) reads the
--                              newest row per key.
--
-- 🔴 Duplicate-person merge migrations must re-point politician_id on stance_coder_labels and
--    stance_gold_labels exactly as they do on stance_research_review.
-- Office retirements and review-row deletes null the gold row's office_id/review_id (the decision
-- itself — chair, blind answer — stays locked).
-- Purely additive. RLS default-deny (CTO decision 0015): the API reads through the pool.
-- =============================================================================

CREATE TABLE IF NOT EXISTS inform.source_snapshots (
  id              uuid PRIMARY KEY,  -- no default: the caller supplies the deterministic id
  batch_id        text NOT NULL,
  url             text NOT NULL,
  source_kind     text NOT NULL CHECK (source_kind IN ('public-record', 'own-site', 'news', 'pointer', 'transcript')),
  fetched_at      timestamptz NOT NULL DEFAULT now(),
  fetched_by      text NOT NULL CHECK (fetched_by IN ('code', 'human')),
  page_sha256     text NOT NULL CHECK (page_sha256 ~ '^[0-9a-f]{64}$'),
  snapshot_text   text NOT NULL CHECK (btrim(snapshot_text) <> ''),
  excerpt_only    boolean NOT NULL,
  CHECK (excerpt_only = (source_kind IN ('news', 'pointer')))
);

CREATE TABLE IF NOT EXISTS inform.stance_coder_labels (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id            text NOT NULL,
  review_id           uuid REFERENCES inform.stance_research_review(id) ON DELETE SET NULL,
  politician_id       uuid NOT NULL REFERENCES essentials.politicians(id),
  office_id           uuid NOT NULL REFERENCES essentials.offices(id) ON DELETE CASCADE,
  topic_id            uuid NOT NULL REFERENCES inform.compass_topics(id),
  season_id           uuid NOT NULL REFERENCES inform.seasons(id),
  served_revision_id  uuid NOT NULL REFERENCES inform.compass_topic_revisions(id),
  coder_slot          smallint NOT NULL CHECK (coder_slot BETWEEN 1 AND 4),
  is_diagnostic       boolean NOT NULL DEFAULT false,
  -- The seat's level (coding-context.json seat.level) — the reliability stratum's level (spec §3.2).
  level               text CHECK (level IS NULL OR level IN ('federal', 'state', 'local', 'judicial', 'school')),
  model               text NOT NULL,
  codebook_version    text NOT NULL,
  value               smallint CHECK (value BETWEEN 1 AND 5),
  blank_reason        text CHECK (blank_reason IN ('no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable')),
  rests_on            uuid[] NOT NULL DEFAULT '{}',
  source_codes        jsonb NOT NULL DEFAULT '[]',
  quote_codes         jsonb NOT NULL DEFAULT '[]',
  needs_source        jsonb NOT NULL DEFAULT '[]',
  valid               boolean NOT NULL,
  validation_errors   text[] NOT NULL DEFAULT '{}',
  label_sha256        text NOT NULL CHECK (label_sha256 ~ '^[0-9a-f]{64}$'),
  raw_output          jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),
  CHECK (NOT valid OR ((value IS NULL) = (blank_reason IS NOT NULL))),
  CONSTRAINT stance_coder_labels_diagnostic_is_slot_4 CHECK (is_diagnostic = (coder_slot = 4)),
  UNIQUE (batch_id, politician_id, office_id, topic_id, coder_slot)
);

CREATE TABLE IF NOT EXISTS inform.stance_gold_labels (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id           uuid REFERENCES inform.stance_research_review(id) ON DELETE SET NULL,
  politician_id       uuid NOT NULL REFERENCES essentials.politicians(id),
  office_id           uuid REFERENCES essentials.offices(id) ON DELETE SET NULL,
  topic_id            uuid NOT NULL REFERENCES inform.compass_topics(id),
  season_id           uuid NOT NULL REFERENCES inform.seasons(id),
  served_revision_id  uuid NOT NULL REFERENCES inform.compass_topic_revisions(id),
  mode                text NOT NULL CHECK (mode IN ('blind', 'standard', 'audit')),
  blind_value         smallint CHECK (blind_value BETWEEN 1 AND 5),
  blind_blank_reason  text CHECK (blind_blank_reason IN ('no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable')),
  blind_submitted_at  timestamptz,
  final_value         smallint CHECK (final_value BETWEEN 1 AND 5),
  final_blank_reason  text CHECK (final_blank_reason IN ('no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable')),
  source_judgments    jsonb NOT NULL DEFAULT '[]',
  reject_reason       text CHECK (reject_reason IN ('wrong-person', 'off-question', 'direction-only', 'adjacent-chairs', 'wrong-chair', 'source-fails', 'pre-seating', 'study-directive', 'near-unanimous', 'multi-subject', 'scope-unavailable', 'other')),
  reject_note         text,
  codebook_version    text NOT NULL,
  reviewer_id         uuid NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),
  excluded_from_cert  boolean NOT NULL DEFAULT false,
  supersedes_id       uuid REFERENCES inform.stance_gold_labels(id),
  -- A blind answer, once submitted, is a chair XOR a blank reason.
  CHECK (blind_submitted_at IS NULL OR ((blind_value IS NULL) = (blind_blank_reason IS NOT NULL))),
  CHECK (reject_reason IS DISTINCT FROM 'other' OR btrim(coalesce(reject_note, '')) <> '')
);

CREATE TABLE IF NOT EXISTS inform.reliability_certifications (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  level             text NOT NULL CHECK (level IN ('federal', 'state', 'local', 'judicial', 'school')),
  evidence_class    text NOT NULL CHECK (evidence_class IN ('record', 'statement-answer', 'statement-other')),
  topic_id          uuid REFERENCES inform.compass_topics(id),
  codebook_version  text NOT NULL,
  model_set         text[] NOT NULL,
  n                 integer NOT NULL,
  m1_alpha          numeric,
  m2_alpha          numeric,
  m3_wilson_low     numeric,
  m4_severe         integer NOT NULL,
  certified         boolean NOT NULL,
  reason            text[] NOT NULL DEFAULT '{}',
  computed_at       timestamptz NOT NULL DEFAULT now(),
  CHECK (NOT certified OR evidence_class <> 'statement-other')  -- ruling Q2: never certifies
);

ALTER TABLE inform.stance_research_review
  ADD COLUMN IF NOT EXISTS review_mode      text,
  ADD COLUMN IF NOT EXISTS codebook_version text,
  ADD COLUMN IF NOT EXISTS unanimous        boolean,
  ADD COLUMN IF NOT EXISTS consensus_value  smallint,
  ADD COLUMN IF NOT EXISTS office_id        uuid REFERENCES essentials.offices(id) ON DELETE SET NULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.stance_research_review'::regclass
                  AND conname = 'stance_research_review_review_mode_check') THEN
    ALTER TABLE inform.stance_research_review ADD CONSTRAINT stance_research_review_review_mode_check
      CHECK (review_mode IS NULL OR review_mode IN ('blind', 'standard', 'audit'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.stance_research_review'::regclass
                  AND conname = 'stance_research_review_consensus_value_check') THEN
    ALTER TABLE inform.stance_research_review ADD CONSTRAINT stance_research_review_consensus_value_check
      CHECK (consensus_value IS NULL OR consensus_value BETWEEN 1 AND 5);
  END IF;
END $$;

-- Append-only guards.
CREATE OR REPLACE FUNCTION inform.gold_labels_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'TRUNCATE' THEN
    RAISE EXCEPTION 'stance_gold_labels is append-only: write a superseding row instead of truncating';
  END IF;
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'stance_gold_labels is append-only: write a superseding row instead of deleting %', OLD.id;
  END IF;
  IF (to_jsonb(NEW) - 'excluded_from_cert' - 'politician_id' - 'office_id' - 'review_id')
     IS DISTINCT FROM (to_jsonb(OLD) - 'excluded_from_cert' - 'politician_id' - 'office_id' - 'review_id') THEN
    RAISE EXCEPTION 'stance_gold_labels is append-only: only excluded_from_cert, politician_id, office_id and review_id may change (row %)', OLD.id;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS gold_labels_append_only ON inform.stance_gold_labels;
CREATE TRIGGER gold_labels_append_only BEFORE UPDATE OR DELETE ON inform.stance_gold_labels
  FOR EACH ROW EXECUTE FUNCTION inform.gold_labels_append_only();
-- A row trigger does not fire on TRUNCATE; a statement trigger does.
DROP TRIGGER IF EXISTS gold_labels_no_truncate ON inform.stance_gold_labels;
CREATE TRIGGER gold_labels_no_truncate BEFORE TRUNCATE ON inform.stance_gold_labels
  FOR EACH STATEMENT EXECUTE FUNCTION inform.gold_labels_append_only();

CREATE OR REPLACE FUNCTION inform.certifications_immutable() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'reliability_certifications rows are never changed: insert a new row (decertification is a new row)';
END $$;
DROP TRIGGER IF EXISTS certifications_immutable ON inform.reliability_certifications;
CREATE TRIGGER certifications_immutable BEFORE UPDATE OR DELETE ON inform.reliability_certifications
  FOR EACH ROW EXECUTE FUNCTION inform.certifications_immutable();
DROP TRIGGER IF EXISTS certifications_no_truncate ON inform.reliability_certifications;
CREATE TRIGGER certifications_no_truncate BEFORE TRUNCATE ON inform.reliability_certifications
  FOR EACH STATEMENT EXECUTE FUNCTION inform.certifications_immutable();

-- RLS default-deny.
ALTER TABLE inform.source_snapshots            ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.stance_coder_labels         ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.stance_gold_labels          ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.reliability_certifications  ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON inform.source_snapshots, inform.stance_coder_labels, inform.stance_gold_labels,
              inform.reliability_certifications FROM anon, authenticated;

COMMENT ON TABLE inform.stance_gold_labels IS
  'Human stance decisions (spec 2026-09-25 §4.3). APPEND-ONLY (trigger). Only mode IN (blind, audit) '
  'with blind_submitted_at set and NOT excluded_from_cert counts toward certification. '
  'Duplicate-person merges must re-point politician_id here.';
COMMENT ON TABLE inform.stance_coder_labels IS
  'One row per coder per (batch, politician, office, topic) (spec §4.2). coder_slot 4 = the '
  'diagnostic other-vendor coder (ruling Q6), never counted. Duplicate-person merges must re-point '
  'politician_id here.';
COMMENT ON TABLE inform.source_snapshots IS
  'What the coders saw (spec §1.2). news/pointer = excerpt windows only (400 words max); page_sha256 '
  'hashes the fetched page text. id is deterministic over batch|url|page_sha256|sha256(snapshot_text).';

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM pg_tables WHERE schemaname = 'inform' AND rowsecurity
     AND tablename IN ('source_snapshots', 'stance_coder_labels', 'stance_gold_labels', 'reliability_certifications');
  IF v <> 4 THEN RAISE EXCEPTION 'CA_0292: expected 4 new RLS-enabled tables, found %', v; END IF;
  SELECT count(*) INTO v FROM information_schema.columns
   WHERE table_schema = 'inform' AND table_name = 'stance_research_review'
     AND column_name IN ('review_mode', 'codebook_version', 'unanimous', 'consensus_value', 'office_id');
  IF v <> 5 THEN RAISE EXCEPTION 'CA_0292: expected 5 new review columns, found %', v; END IF;
  SELECT count(*) INTO v FROM pg_trigger
   WHERE tgname IN ('gold_labels_append_only', 'certifications_immutable', 'gold_labels_no_truncate', 'certifications_no_truncate')
     AND NOT tgisinternal
     AND tgrelid IN ('inform.stance_gold_labels'::regclass, 'inform.reliability_certifications'::regclass);
  IF v <> 4 THEN RAISE EXCEPTION 'CA_0292: expected 4 append-only triggers (2 row + 2 truncate), found %', v; END IF;

  -- stance_coder_labels.level exists, with its CHECK.
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = 'inform' AND table_name = 'stance_coder_labels' AND column_name = 'level') THEN
    RAISE EXCEPTION 'CA_0292: inform.stance_coder_labels.level is missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.stance_coder_labels'::regclass
                  AND conname = 'stance_coder_labels_diagnostic_is_slot_4') THEN
    RAISE EXCEPTION 'CA_0292: CHECK stance_coder_labels_diagnostic_is_slot_4 is missing';
  END IF;
  -- reliability_certifications.level accepts judicial.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.reliability_certifications'::regclass
                  AND contype = 'c' AND pg_get_constraintdef(oid) LIKE '%judicial%') THEN
    RAISE EXCEPTION 'CA_0292: reliability_certifications.level CHECK does not allow judicial';
  END IF;
  -- source_snapshots: id is the conflict target (PRIMARY KEY, no default); the old
  -- UNIQUE (batch_id, url, page_sha256) is gone — it refused a changed excerpt of the same page.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.source_snapshots'::regclass AND contype = 'p') THEN
    RAISE EXCEPTION 'CA_0292: inform.source_snapshots has no PRIMARY KEY';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.source_snapshots'::regclass AND contype = 'u') THEN
    RAISE EXCEPTION 'CA_0292: inform.source_snapshots still carries a UNIQUE constraint besides its id';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'inform' AND table_name = 'source_snapshots'
              AND column_name = 'id' AND column_default IS NOT NULL) THEN
    RAISE EXCEPTION 'CA_0292: inform.source_snapshots.id must have no default (ids are deterministic)';
  END IF;

  IF has_table_privilege('anon', 'inform.source_snapshots', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0292: REVOKE did not take — anon can SELECT inform.source_snapshots';
  END IF;
  IF has_table_privilege('anon', 'inform.stance_coder_labels', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0292: REVOKE did not take — anon can SELECT inform.stance_coder_labels';
  END IF;
  IF has_table_privilege('anon', 'inform.stance_gold_labels', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0292: REVOKE did not take — anon can SELECT inform.stance_gold_labels';
  END IF;
  IF has_table_privilege('anon', 'inform.reliability_certifications', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0292: REVOKE did not take — anon can SELECT inform.reliability_certifications';
  END IF;
END $$;

COMMIT;
