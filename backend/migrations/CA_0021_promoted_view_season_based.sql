BEGIN;

-- 🔴 NOT APPLIED. Written and dry-run 2026-08-27.
--
-- Its dependency is now SATISFIED: CA_0020 was applied 2026-08-27 21:10 UTC, so
-- season 1 is open and this migration's gate would pass (the season-based
-- promoted set reads 44). It is held back only because the promotion READ-PATH
-- REPOINT is not written yet, and there is no reason to change a view's shape in
-- prod before the callers that will use it exist.
--
-- Dry-run evidence, both directions:
--   · chained after CA_0020 → OK. "promoted = 44 topics from the open season,
--     answerable dropped". 44 rows, 44 distinct topics (no fan-out), pins all
--     equal to the current revision, content views untouched at 44/220.
--   · alone, before CA_0020 → FAILED as designed:
--     "CA_0021: promoted view returns 0 rows — no season is open. Apply CA_0020
--     first." That refusal is the feature; see the gate at the foot of this file.
--
-- =============================================================================
-- CA_0021: Promotion comes from the open season, not from is_live.
--          And answerability was never a view.
-- =============================================================================
-- 🔴 APPLY CA_0020 FIRST. This migration's post-verify gate asserts that the
-- redefined promoted view returns 44 rows. With no open season it returns 0 and
-- the gate fails — deliberately. A promoted view that silently returns nothing
-- is the exact failure this migration exists to prevent; it must not be possible
-- to install one.
--
-- Supersedes two of the four views CA_0013 created. CA_0013 stays on disk as
-- applied, uncorrected, because its reasoning is the record of what we believed
-- before anyone noticed the season model had already shipped in PR #177.
--
-- -----------------------------------------------------------------------------
-- 1. compass_topics_promoted — right name, wrong authority
-- -----------------------------------------------------------------------------
-- CA_0013 defined it as `compass_topics_current WHERE is_live = true`. That
-- returns the correct 44 topics today, and it will keep returning 44 forever,
-- because nothing about a season touches `is_live`. Promotion is a property of
-- (season, jurisdiction) — ADR 0005 — and the season half of that now exists.
--
-- `is_live` IS NOT DROPPED and this migration does not touch it. CA_0013's scope
-- correction still holds: the admin Topics page reads AND writes it as a live
-- archive/unarchive toggle, and there is no equivalent column on
-- compass_topic_revisions. It stops being the AUTHORITY on promotion here; it
-- does not stop existing. Retiring it needs the admin control replaced first.
--
-- The jurisdiction half is NOT built. `season_questions` has no
-- jurisdiction_geoid column, so this view answers "promoted in the open season"
-- and cannot yet answer "promoted HERE". Named in ADR 0005 as the next piece of
-- work; the view's shape does not have to change to gain it, only its WHERE.
--
-- -----------------------------------------------------------------------------
-- 2. compass_topics_answerable — dropped
-- -----------------------------------------------------------------------------
-- Two independent reasons, either sufficient.
--
-- It never filtered anything. Its live definition is a bare column-narrowed
-- SELECT over compass_topics_current, with no WHERE clause at all. It returns
-- all 44 topics. It names a rule without encoding one, which is worse than
-- absent: a reader repointing onto it believes a check is being applied.
--
-- And the rule it names is overruled. ADR 0004 §12 asserted answerability must
-- stay permissive — that promotion "must never decide what may be RECORDED".
-- The shipped model decides otherwise, and enforces it in the schema, not in
-- query text: politician_answers.season_id and .topic_revision_id are both NOT
-- NULL, and politician_answers_pin_fkey is a composite FK onto
-- season_questions(season_id, topic_id, topic_revision_id). An answer to a topic
-- the open season does not ask HAS NO PIN AND CANNOT BE WRITTEN. No view can
-- make it permissive. See ADR 0004 §12 as corrected, and ADR 0005.
--
-- What §12 got right is that the two questions differ, and they still do — but
-- the split is not the one it drew:
--   · may an EXISTING answer survive its topic leaving a season?  YES. Untouched.
--     Reads follow the person (seasonService.newestAnswerLateral), not the
--     calendar, so a season-1 answer stays readable forever.
--   · may a NEW answer be written outside the open season?        NO. By FK.
-- Neither of those needs a view. The first is a read shape; the second is a
-- constraint. Nothing is created to replace this.
--
-- SAFE TO DROP: verified 2026-08-27, zero readers across backend/src, admin/src
-- and app/src. The one proposed reader — routes/compassContributor.ts on branch
-- wip/ca0013-repoint — is not merged and must not be; see ADR 0005.
-- =============================================================================

DROP VIEW IF EXISTS inform.compass_topics_answerable;

-- DROP then CREATE, not CREATE OR REPLACE. The column list changes — the old
-- definition ended in `is_live`, this one ends in the season columns — and
-- Postgres refuses to rename a view column in place ("cannot change name of view
-- column is_live to season_id"). Safe: nothing depends on this view, verified.
DROP VIEW IF EXISTS inform.compass_topics_promoted;

CREATE VIEW inform.compass_topics_promoted AS
  SELECT c.id,
         c.topic_key,
         c.title,
         c.short_title,
         c.question_text,
         c.version,
         c.revision,
         c.revision_id,
         c.change_class,
         c.public_note,
         c.published_at,
         c.fc_community_slug,
         c.judicial_role,
         c.created_at,
         c.updated_at,
         sq.season_id,
         sq.question_number,
         sq.display_order,
         -- The pin. NOT the same as c.revision_id once a ladder is reworded
         -- mid-season: c.revision_id follows the current revision, this follows
         -- what the season asks. A caller rendering the question a person is
         -- being ASKED wants this one.
         sq.topic_revision_id AS season_revision_id
    FROM inform.compass_topics_current c
    JOIN inform.season_questions sq ON sq.topic_id = c.id
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open';

COMMENT ON VIEW inform.compass_topics_promoted IS
  'Topics the OPEN season asks, resolved to their current content plus the '
  'season''s pinned revision. Empty when no season is open — that is honest, not '
  'a fault, but a caller must treat 0 rows as an error rather than as "no '
  'topics". Not yet jurisdiction-aware: season_questions has no geoid column, so '
  'this is "promoted in the open season", not "promoted here" (ADR 0005).';

-- -----------------------------------------------------------------------------
-- Post-verify gate.
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_promoted int; v_pinned int;
BEGIN
  IF to_regclass('inform.compass_topics_answerable') IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0021: compass_topics_answerable should be dropped';
  END IF;

  IF to_regclass('inform.compass_topics_promoted') IS NULL THEN
    RAISE EXCEPTION 'CA_0021: compass_topics_promoted is missing';
  END IF;

  SELECT count(*) INTO v_promoted FROM inform.compass_topics_promoted;
  SELECT count(*) INTO v_pinned
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open';

  -- 🔴 THE POINT OF THIS GATE. 0 here means no season is open, which means
  -- CA_0020 has not been applied. Installing the view anyway would leave a
  -- silent 0-row trap in prod for the next person who repoints onto it.
  IF v_promoted = 0 THEN
    RAISE EXCEPTION
      'CA_0021: promoted view returns 0 rows — no season is open. Apply CA_0020 first.';
  END IF;

  IF v_promoted <> v_pinned THEN
    RAISE EXCEPTION 'CA_0021: promoted view returns % rows, open season pins %',
      v_promoted, v_pinned;
  END IF;

  -- One row per topic. A season_questions PK of (season_id, topic_id) plus one
  -- open season guarantees it, but assert it: this view is destined for a list
  -- query, and a fan-out there duplicates topics in a voter's compass.
  IF v_promoted <> (SELECT count(DISTINCT id) FROM inform.compass_topics_promoted) THEN
    RAISE EXCEPTION 'CA_0021: promoted view fans out — % rows, % distinct topics',
      v_promoted, (SELECT count(DISTINCT id) FROM inform.compass_topics_promoted);
  END IF;

  RAISE NOTICE 'CA_0021 OK — promoted = % topics from the open season, answerable dropped',
    v_promoted;
END $$;

COMMIT;
