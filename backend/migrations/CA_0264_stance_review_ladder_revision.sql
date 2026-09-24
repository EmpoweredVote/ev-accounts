BEGIN;

-- ⚠ NOT APPLIED. Dry-run on production 2026-09-24 inside BEGIN…ROLLBACK (see
-- the task-4 report); apply only with the operator's explicit OK.

-- =============================================================================
-- CA_0264: a queued stance-review row remembers the ladder it was researched
--          against (inform.stance_research_review.topic_revision_id + season_id)
-- =============================================================================
-- Task 4 of docs/superpowers/plans/2026-09-23-stance-program-reconciliation.md.
--
-- A proposed value is an answer to ONE ladder's wording. verify-stance-research.ts
-- already refuses a batch whose bundle revision is no longer the open season's
-- pin — but only at queue time. A row can then sit in the review queue while the
-- open season re-pins the topic, and approving it would publish an answer to a
-- sentence the researcher never read. So the queue row now carries:
--
--   topic_revision_id  the bundle's topic_revision_id (topics.json) the row was
--                      researched and verified against;
--   season_id          the season that was open when the row was queued.
--
-- resolveResearchReview refuses (409) a row whose revision is known and differs
-- from the open season's current pin for the topic.
--
-- 🔴 NO BACKFILL, on purpose. Every row queued before this migration (51 on
-- 2026-09-24: 28 pending, 23 resolved) keeps NULL in both columns. Their
-- revision is UNKNOWN: the review row never recorded which bundle it came from,
-- and "the pin at the time it was queued" cannot be reconstructed — guessing
-- today's pin would assert a match nobody checked. The approval path allows a
-- NULL row and the admin page says "ladder revision unknown (queued before
-- 2026-09-24)", so a person decides with that fact in front of them.
--
-- Purely additive: both columns are NULLABLE, so the pre-migration INSERT (which
-- names neither column) keeps working, and the backend reads `r.*`, so no read
-- depends on this having run.
-- =============================================================================

ALTER TABLE inform.stance_research_review
  ADD COLUMN IF NOT EXISTS topic_revision_id uuid REFERENCES inform.compass_topic_revisions(id),
  ADD COLUMN IF NOT EXISTS season_id         uuid REFERENCES inform.seasons(id);

COMMENT ON COLUMN inform.stance_research_review.topic_revision_id IS
  'The ladder revision (compass_topic_revisions.id) this row was researched and '
  'verified against — the bundle''s topic_revision_id from topics.json, written '
  'by verify-stance-research.ts at queue time. Approval refuses the row when this '
  'differs from the open season''s current pin for the topic. NULL = queued '
  'before CA_0264 (2026-09-24): the revision is unknown and was deliberately not '
  'backfilled.';
COMMENT ON COLUMN inform.stance_research_review.season_id IS
  'The season that was open when this row was queued. Provenance only; approval '
  'compares topic_revision_id, not this. NULL = queued before CA_0264 '
  '(2026-09-24), not backfilled.';

DO $$
DECLARE
  v_cols    int;
  v_rev_fk  regclass;
  v_sea_fk  regclass;
BEGIN
  SELECT count(*) INTO v_cols FROM information_schema.columns
   WHERE table_schema = 'inform' AND table_name = 'stance_research_review'
     AND column_name IN ('topic_revision_id', 'season_id')
     AND data_type = 'uuid' AND is_nullable = 'YES';
  IF v_cols <> 2 THEN
    RAISE EXCEPTION 'CA_0264: expected 2 nullable uuid columns (topic_revision_id, season_id), found %', v_cols;
  END IF;

  -- FK targets read from the catalog (confrelid), not from pg_get_constraintdef,
  -- which prints the target unqualified when its schema is on the search_path.
  SELECT c.confrelid::regclass INTO v_rev_fk
    FROM pg_constraint c
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
   WHERE c.contype = 'f' AND c.conrelid = 'inform.stance_research_review'::regclass
     AND a.attname = 'topic_revision_id';
  IF v_rev_fk IS DISTINCT FROM 'inform.compass_topic_revisions'::regclass THEN
    RAISE EXCEPTION 'CA_0264: topic_revision_id FK points at %, expected inform.compass_topic_revisions', v_rev_fk;
  END IF;

  SELECT c.confrelid::regclass INTO v_sea_fk
    FROM pg_constraint c
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
   WHERE c.contype = 'f' AND c.conrelid = 'inform.stance_research_review'::regclass
     AND a.attname = 'season_id';
  IF v_sea_fk IS DISTINCT FROM 'inform.seasons'::regclass THEN
    RAISE EXCEPTION 'CA_0264: season_id FK points at %, expected inform.seasons', v_sea_fk;
  END IF;

  IF col_description('inform.stance_research_review'::regclass,
       (SELECT attnum FROM pg_attribute WHERE attrelid = 'inform.stance_research_review'::regclass
          AND attname = 'topic_revision_id')) IS NULL
  OR col_description('inform.stance_research_review'::regclass,
       (SELECT attnum FROM pg_attribute WHERE attrelid = 'inform.stance_research_review'::regclass
          AND attname = 'season_id')) IS NULL THEN
    RAISE EXCEPTION 'CA_0264: a column COMMENT is missing';
  END IF;

  RAISE NOTICE 'CA_0264 ok: topic_revision_id -> %, season_id -> %; legacy rows left NULL', v_rev_fk, v_sea_fk;
END $$;

COMMIT;
