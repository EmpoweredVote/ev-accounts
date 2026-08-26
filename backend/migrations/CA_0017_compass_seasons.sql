BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-25. Verified: both tables + the season_status
-- enum (draft,open,closed) + the seasons_one_open partial unique index are live,
-- 0 rows in each new table, 44 topics / 46 revisions / 33,164 answers untouched.
-- Dry-run first inside BEGIN…ROLLBACK; the rollback was confirmed to revert
-- (to_regclass NULL on both tables, enum gone, index gone) before applying.
-- Constraints exercised against real data in a rolled-back transaction, 9/9:
--   1 draft season                      -> inserted
--   2 status='open' with NULL opened_at -> refused by seasons_dates_follow_status
--   3 first open season                 -> inserted
--   4 second open season                -> refused by seasons_one_open
--   5 draft alongside an open season    -> inserted (allowed by design)
--   6 question pinned to a real revision-> inserted
--   7 duplicate question_number         -> refused by UNIQUE (season_id, question_number)
--   8 bogus topic_revision_id           -> refused by FK
--   9 DELETE the season                 -> questions cascaded, no orphans
-- Nothing left behind: 0 seasons, 0 season_questions after the probe rolled back.

-- =============================================================================
-- CA_0017: Compass seasons — the season and its per-question pin
-- =============================================================================
-- Task 1 of docs/superpowers/plans/2026-08-25-compass-seasons.md.
-- Spec: docs/superpowers/specs/2026-08-25-compass-seasons-design.md.
--
-- Purely additive. Nothing reads these tables yet, so this migration carries no
-- risk to live reads. It creates the two carriers of the season model:
--
--   inform.seasons           — one row per season. At most one is 'open'.
--   inform.season_questions  — the question set of a season, one row per topic,
--                              each PINNED to the ladder revision that was
--                              current when the season opened.
--
-- THE PIN IS THE WHOLE POINT. An answer stored against a season means "this
-- rung, of THAT ladder text". Editing a ladder afterwards publishes a new
-- revision; the season keeps pointing at the old one, so the meaning of an
-- answer already stored cannot change under it.
--
-- Slot note: CA_0013 and CA_0014 stay unused — ADR 0004 reserves them for the
-- read-path repoint and the ReadRank split, which must land in that order.
--
-- Later tasks depend on the UNIQUE (season_id, topic_id, topic_revision_id)
-- constraint below as a composite foreign-key target. Do not drop it.
-- =============================================================================

DO $$ BEGIN
  CREATE TYPE inform.season_status AS ENUM ('draft', 'open', 'closed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS inform.seasons (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  number      integer NOT NULL UNIQUE,
  name        text    NOT NULL,
  status      inform.season_status NOT NULL DEFAULT 'draft',
  opened_at   timestamptz,
  closed_at   timestamptz,
  public_note text    NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT seasons_dates_follow_status CHECK (
    (status = 'draft'  AND opened_at IS NULL AND closed_at IS NULL) OR
    (status = 'open'   AND opened_at IS NOT NULL AND closed_at IS NULL) OR
    (status = 'closed' AND opened_at IS NOT NULL AND closed_at IS NOT NULL)
  )
);

-- At most one open season. A draft may be prepared while one is open.
CREATE UNIQUE INDEX IF NOT EXISTS seasons_one_open
  ON inform.seasons ((status)) WHERE status = 'open';

CREATE TABLE IF NOT EXISTS inform.season_questions (
  season_id         uuid    NOT NULL REFERENCES inform.seasons(id) ON DELETE CASCADE,
  topic_id          uuid    NOT NULL REFERENCES inform.compass_topics(id) ON DELETE RESTRICT,
  topic_revision_id uuid    NOT NULL REFERENCES inform.compass_topic_revisions(id),
  question_number   integer NOT NULL,
  display_order     integer NOT NULL,
  PRIMARY KEY (season_id, topic_id),
  UNIQUE (season_id, question_number),
  UNIQUE (season_id, display_order),
  -- Foreign-key target for the answer tables in Task 6. Without this the
  -- composite FK will not compile.
  UNIQUE (season_id, topic_id, topic_revision_id)
);

COMMENT ON COLUMN inform.season_questions.topic_revision_id IS
  'THE PIN. The ladder revision current when this season opened. Immutable once '
  'the season leaves draft, enforced by a trigger added in a later migration of '
  'the compass-seasons plan (Task 3). Deliberately unnumbered here: that slot is '
  'not claimed yet, and a wrong number written into a COMMENT outlives the fix.';
COMMENT ON COLUMN inform.season_questions.question_number IS
  'A human-facing label, per season. NOT identity — seeding joins on topic_id. '
  'Matching the previous season''s number is best practice, warned not enforced.';

DO $$
DECLARE v_missing text[] := '{}';
BEGIN
  IF to_regclass('inform.seasons') IS NULL THEN
    v_missing := v_missing || 'seasons'; END IF;
  IF to_regclass('inform.season_questions') IS NULL THEN
    v_missing := v_missing || 'season_questions'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes
                 WHERE schemaname='inform' AND indexname='seasons_one_open') THEN
    v_missing := v_missing || 'seasons_one_open'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
    WHERE t.relname='season_questions' AND c.contype='u'
      AND pg_get_constraintdef(c.oid) LIKE '%season_id, topic_id, topic_revision_id%'
  ) THEN v_missing := v_missing || 'fk-target unique'; END IF;

  IF array_length(v_missing,1) > 0 THEN
    RAISE EXCEPTION 'CA_0017_compass_seasons INCOMPLETE: missing %',
      array_to_string(v_missing, ', ');
  END IF;

  -- This migration must not have touched existing content.
  IF (SELECT count(*) FROM inform.compass_topics) <> 44 THEN
    RAISE EXCEPTION 'topic count changed: expected 44, got %',
      (SELECT count(*) FROM inform.compass_topics);
  END IF;

  RAISE NOTICE 'compass seasons OK — 2 tables, 0 seasons, 44 topics untouched';
END $$;

COMMIT;
