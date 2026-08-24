BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-21. Verified: 44 revisions / 220 rungs, all
-- (version 1, revision 1, published, is_current, rung_map NULL); one distinct
-- public_note across all 44; rationale flagged on exactly the six pre-revised
-- topics; zero text drift; 184 responses + 1,819 history rows stamped, none
-- pointing at another topic's revision; views 44/220 with no fan-out; all four
-- triggers armed AND proven to fire (8/8 guard tests passed).

-- =============================================================================
-- CA_0012: Backfill compass content revisions from the live rows
-- =============================================================================
-- Implements ADR 0004 migration-path step 2. Requires CA_0011.
--
-- Reads the 44 live topics and their 220 rungs and records each as revision 1,
-- version 1. Adds answer provenance to compass_responses and
-- compass_change_history. Creates the compatibility views. Freezes in-place
-- content edits for the duration of the transition (Section 5 — read that one
-- before objecting to it).
--
-- 🔴 CLEAN SLATE: EVERY TOPIC IS version 1. Decided 2026-08-21. Six topics
-- (ai-regulation, deportation, healthcare, housing, immigration, taxes) carry
-- version = 2 in the legacy column, and their version-1 rows were DELETED in April
-- 2026. An earlier draft of this migration carried that 2 forward. It no longer
-- does: the record starts now, and everything live today is version 1.
--
-- Note what that does and does not claim. "First tracked version of this topic" is
-- true of all 44 and asserts nothing about what came before. It is not a claim that
-- the topic has never changed. The fact that six of them DID change before tracking
-- began is preserved in `rationale`, which is internal and never served — so the
-- team keeps the knowledge without a version-2 signal reaching readers.
--
-- 🔴 DOES NOT invent prior wording, ever. The deleted April content is not
-- recoverable from the database and we are not reconstructing it from git.
--
-- Consequence, accepted: until CA_0013 drops inform.compass_topics.version, that
-- column says 2 for those six while the revision says 1. Nothing reads the revision
-- version until the repoint, and CA_0013 removes the disagreement by deleting the
-- older of the two.
--
-- Counts are asserted as invariants ("nothing left NULL"), not as literals.
-- compass_change_history grew from 1,818 to 1,819 rows in the hour between
-- drafting and writing this; a hardcoded count would already be wrong.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- Section 1: Preconditions
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  IF to_regclass('inform.compass_topic_revisions') IS NULL THEN
    RAISE EXCEPTION 'CA_0012: CA_0011 has not been applied — compass_topic_revisions does not exist';
  END IF;

  -- Idempotence: re-running must not create a second revision 1.
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions) THEN
    RAISE NOTICE 'CA_0012: revisions already present — insert steps will no-op via NOT EXISTS guards';
  END IF;

  -- The shape this backfill assumes. If the corpus has drifted, stop rather than
  -- silently record a topic with four rungs as though a ladder were complete.
  IF EXISTS (
    SELECT 1 FROM inform.compass_stances GROUP BY topic_id HAVING count(*) <> 5
  ) THEN
    RAISE EXCEPTION 'CA_0012: a topic does not have exactly 5 rungs — investigate before backfilling';
  END IF;

  IF EXISTS (
    SELECT 1 FROM inform.compass_topics t
    WHERE NOT EXISTS (SELECT 1 FROM inform.compass_stances s WHERE s.topic_id = t.id)
  ) THEN
    RAISE EXCEPTION 'CA_0012: a topic has no rungs at all — investigate before backfilling';
  END IF;
END $$;


-- ---------------------------------------------------------------------------
-- Section 2: Topic revisions
-- ---------------------------------------------------------------------------
-- revision = 1 and version = 1, for all 44. Clean slate: the public record begins
--             here. Only revisions written AFTER this migration carry history.
-- rung_map  = NULL: there is no prior ladder in this table to map from. Legal per
--             CA_0011's validator (which was tested for exactly this case).
-- ---------------------------------------------------------------------------

INSERT INTO inform.compass_topic_revisions (
  topic_id, revision, version, change_class,
  title, short_title, question_text,
  rationale, public_note, rung_map,
  status, is_current,
  proposed_by, proposed_at, approved_by, approved_at, published_by, published_at
)
SELECT
  t.id,
  1,
  1,                                    -- clean slate: everything live today is v1
  'substantive',                        -- founding content, not an edit
  t.title,
  t.short_title,
  t.question_text,
  -- INTERNAL. Carries the one fact the uniform public note deliberately omits, so
  -- the team does not lose it: six topics were edited before tracking existed.
  'Backfilled by CA_0012 at the introduction of content versioning (ADR 0004). '
    || 'This content predates the revision model, so its original decision reasoning '
    || 'was never recorded and is not recoverable. '
    || CASE WHEN COALESCE(t.version, 1) > 1 THEN
         'NOTE: inform.compass_topics.version read ' || t.version || ' at backfill time, '
         || 'meaning this topic was revised at least once before tracking began. That '
         || 'earlier wording was deleted in April 2026 and is not in the database. '
         || 'Recorded here as version 1 by decision of 2026-08-21 (clean slate); the '
         || 'public note is uniform across all 44 topics and does not surface this.'
       ELSE
         'No prior revision of this topic is known.'
       END,
  -- PUBLIC. Uniform across all 44. True of every one, and asserts nothing about
  -- what came before — it is not a claim that the topic has never changed.
  'First tracked version of this topic.',
  NULL,                                 -- no prior ladder to map from
  'published',
  true,
  NULL,                                 -- author unknown
  t.created_at,
  NULL, NULL,                           -- never went through review
  NULL,
  COALESCE(t.went_live_at, t.created_at)
FROM inform.compass_topics t
WHERE NOT EXISTS (
  SELECT 1 FROM inform.compass_topic_revisions r WHERE r.topic_id = t.id
);


-- ---------------------------------------------------------------------------
-- Section 3: Ladder revisions
-- ---------------------------------------------------------------------------

INSERT INTO inform.compass_stance_revisions (
  topic_revision_id, value, text, description, supporting_points, example_perspectives
)
SELECT r.id, s.value, s.text, s.description, s.supporting_points, s.example_perspectives
FROM inform.compass_stances s
JOIN inform.compass_topic_revisions r
  ON r.topic_id = s.topic_id AND r.revision = 1
WHERE NOT EXISTS (
  SELECT 1 FROM inform.compass_stance_revisions sr
  WHERE sr.topic_revision_id = r.id AND sr.value = s.value
);


-- ---------------------------------------------------------------------------
-- Section 4: Answer provenance (ADR §5)
-- ---------------------------------------------------------------------------
-- Without this, "you answered this when the question read X" is unanswerable and
-- a ladder cutover cannot tell a stale answer from a fresh one.
-- ---------------------------------------------------------------------------

ALTER TABLE inform.compass_responses
  ADD COLUMN IF NOT EXISTS answered_revision_id UUID
    REFERENCES inform.compass_topic_revisions(id);

ALTER TABLE inform.compass_change_history
  ADD COLUMN IF NOT EXISTS answered_revision_id UUID
    REFERENCES inform.compass_topic_revisions(id);

UPDATE inform.compass_responses resp
SET answered_revision_id = r.id
FROM inform.compass_topic_revisions r
WHERE r.topic_id = resp.topic_id
  AND r.is_current
  AND resp.answered_revision_id IS NULL;

UPDATE inform.compass_change_history h
SET answered_revision_id = r.id
FROM inform.compass_topic_revisions r
WHERE r.topic_id = h.topic_id
  AND r.is_current
  AND h.answered_revision_id IS NULL;

COMMENT ON COLUMN inform.compass_responses.answered_revision_id IS
  'ADR 0004 §5. Which topic revision this answer was given against. Backfilled by CA_0012 to revision 1 — pre-dating the revision model, these answers were not actually given against a known revision, they are merely attributed to the only one that exists.';


-- ---------------------------------------------------------------------------
-- Section 5: Freeze in-place content edits
-- ---------------------------------------------------------------------------
-- 🔴 THE WINDOW THIS CLOSES. Between this migration and the repoint (CA_0013),
-- inform.compass_topics still holds title/question_text and the revision table
-- also holds them. Two authoritative copies. If anyone edits a topic in place
-- during that window — via PATCH /api/compass/stances/update, or a hand-written
-- migration — the revision row silently goes stale, and CA_0013's repoint would
-- then REVERT published content to the older text. That is the worst available
-- outcome of this whole project, and it is silent.
--
-- So content edits to the old tables raise. This is safe to do abruptly because
-- the in-place path has never been used: admin_audit_log holds ZERO
-- compass:stance:batch-update or compass:topic:* actions in its entire history.
--
-- is_live / went_live_at / updated_at are deliberately still editable, so
-- archiving a topic does not require dropping the guard.
--
-- 🔴 REMOVE THESE **BEFORE** CA_0013, NOT AFTER. compass_topics_content_frozen is
-- an `UPDATE OF <column>` trigger, so pg_trigger holds a reference to title,
-- short_title, question_text and version. CA_0013 drops exactly those columns, and
-- ALTER TABLE ... DROP COLUMN will not silently step over a dependent trigger. So
-- CA_0013 must open with:
--   DROP TRIGGER IF EXISTS compass_topics_content_frozen  ON inform.compass_topics;
--   DROP TRIGGER IF EXISTS compass_stances_content_frozen ON inform.compass_stances;
-- and only then drop the columns. Dropping the guard is safe at that point: once
-- the duplicated columns are gone there is nothing left for an in-place edit to
-- corrupt, which is the entire window this guard exists to cover.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.compass_legacy_content_frozen()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION
    'LEGACY_CONTENT_FROZEN: % is no longer the source of truth for compass content. '
    'Write a new row in inform.compass_topic_revisions instead (ADR 0004). '
    'This guard exists because an in-place edit here would be silently reverted by CA_0013.',
    TG_TABLE_NAME;
END;
$$;

DROP TRIGGER IF EXISTS compass_topics_content_frozen ON inform.compass_topics;
CREATE TRIGGER compass_topics_content_frozen
  BEFORE UPDATE OF title, short_title, question_text, version
  ON inform.compass_topics
  FOR EACH ROW EXECUTE FUNCTION inform.compass_legacy_content_frozen();

DROP TRIGGER IF EXISTS compass_stances_content_frozen ON inform.compass_stances;
CREATE TRIGGER compass_stances_content_frozen
  BEFORE UPDATE OR DELETE ON inform.compass_stances
  FOR EACH ROW EXECUTE FUNCTION inform.compass_legacy_content_frozen();


-- ---------------------------------------------------------------------------
-- Section 6: Compatibility views
-- ---------------------------------------------------------------------------
-- Reproduce TODAY's exact column shape so the ~13 backend files that read
-- compass_topics move with a one-line change in CA_0013, rather than a rewrite.
-- Nothing reads these yet.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE VIEW inform.compass_topics_live AS
SELECT
  t.id,
  t.topic_key,
  r.title,
  r.short_title,
  r.question_text,
  true              AS is_live,
  true              AS is_active,     -- the dropped GENERATED compat column
  r.version,
  r.published_at    AS went_live_at,
  t.office_scope,
  t.fc_community_slug,
  t.judicial_role,
  t.created_at,
  r.id              AS revision_id,
  r.revision,
  r.change_class,
  r.public_note
FROM inform.compass_topics t
JOIN inform.compass_topic_revisions r
  ON r.topic_id = t.id AND r.is_current;

CREATE OR REPLACE VIEW inform.compass_stances_live AS
SELECT
  sr.id,
  r.topic_id,
  sr.value,
  sr.text,
  sr.description,
  sr.supporting_points,
  sr.example_perspectives,
  sr.topic_revision_id
FROM inform.compass_stance_revisions sr
JOIN inform.compass_topic_revisions r
  ON r.id = sr.topic_revision_id AND r.is_current;

GRANT SELECT ON inform.compass_topics_live  TO anon, authenticated;
GRANT SELECT ON inform.compass_stances_live TO anon, authenticated;

COMMENT ON VIEW inform.compass_topics_live IS
  'ADR 0004. Today''s compass_topics column shape, resolved from the current revision. Migration target for existing readers. is_live/is_active are literal true: a non-current revision is simply absent.';


-- ---------------------------------------------------------------------------
-- Section 7: Post-verify gate
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_topics      INT;
  v_revs        INT;
  v_current     INT;
  v_rungs       INT;
  v_rung_revs   INT;
  v_bad         INT;
  v_view_topics INT;
BEGIN
  SELECT count(*) INTO v_topics FROM inform.compass_topics;
  SELECT count(*) INTO v_revs   FROM inform.compass_topic_revisions;
  SELECT count(*) INTO v_rungs  FROM inform.compass_stances;
  SELECT count(*) INTO v_rung_revs FROM inform.compass_stance_revisions;
  SELECT count(*) INTO v_current FROM inform.compass_topic_revisions WHERE is_current;

  -- One revision per topic, and one current revision per topic.
  IF v_revs <> v_topics THEN
    RAISE EXCEPTION 'CA_0012: % topics but % revisions', v_topics, v_revs;
  END IF;
  IF v_current <> v_topics THEN
    RAISE EXCEPTION 'CA_0012: % topics but % current revisions', v_topics, v_current;
  END IF;
  IF v_rung_revs <> v_rungs THEN
    RAISE EXCEPTION 'CA_0012: % rungs but % rung revisions', v_rungs, v_rung_revs;
  END IF;

  -- Content must match what it was copied from, exactly. This is the assertion
  -- that a clean run of the INSERTs does not by itself give you.
  SELECT count(*) INTO v_bad
  FROM inform.compass_topics t
  JOIN inform.compass_topic_revisions r ON r.topic_id = t.id AND r.is_current
  WHERE t.title         IS DISTINCT FROM r.title
     OR t.short_title   IS DISTINCT FROM r.short_title
     OR t.question_text IS DISTINCT FROM r.question_text;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CA_0012: % topics whose revision text differs from the source row', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
  FROM inform.compass_stances s
  JOIN inform.compass_topic_revisions r  ON r.topic_id = s.topic_id AND r.is_current
  LEFT JOIN inform.compass_stance_revisions sr
         ON sr.topic_revision_id = r.id AND sr.value = s.value
  WHERE sr.id IS NULL
     OR s.text        IS DISTINCT FROM sr.text
     OR s.description IS DISTINCT FROM sr.description;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CA_0012: % rungs whose revision text differs from the source row', v_bad;
  END IF;

  -- Clean slate: every backfilled revision is version 1, revision 1. A stray 2
  -- here would mean the GREATEST() logic from the earlier draft survived a merge.
  SELECT count(*) INTO v_bad
  FROM inform.compass_topic_revisions
  WHERE version <> 1 OR revision <> 1;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CA_0012: % revisions are not version 1 / revision 1 — clean slate violated', v_bad;
  END IF;

  -- The internal rationale must carry the prior-edit note for exactly the topics
  -- whose legacy version column is above 1. If this drifts, the team silently loses
  -- the only remaining record that those six were ever edited.
  SELECT count(*) INTO v_bad
  FROM inform.compass_topics t
  JOIN inform.compass_topic_revisions r ON r.topic_id = t.id AND r.is_current
  WHERE (COALESCE(t.version, 1) > 1) <> (r.rationale LIKE '%before tracking began%');
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CA_0012: % topics whose rationale does not match their legacy version', v_bad;
  END IF;

  -- And no reader-facing note may leak a version-2 signal.
  SELECT count(*) INTO v_bad
  FROM inform.compass_topic_revisions
  WHERE public_note <> 'First tracked version of this topic.';
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CA_0012: % public notes are not the uniform clean-slate text', v_bad;
  END IF;

  -- Provenance: invariant, not a literal count.
  SELECT count(*) INTO v_bad FROM inform.compass_responses WHERE answered_revision_id IS NULL;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CA_0012: % compass_responses rows left without answered_revision_id', v_bad;
  END IF;

  SELECT count(*) INTO v_bad FROM inform.compass_change_history WHERE answered_revision_id IS NULL;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CA_0012: % compass_change_history rows left without answered_revision_id', v_bad;
  END IF;

  -- The view must be exactly one row per topic — a fan-out here would silently
  -- multiply every topic list in the product.
  SELECT count(*) INTO v_view_topics FROM inform.compass_topics_live;
  IF v_view_topics <> v_topics THEN
    RAISE EXCEPTION 'CA_0012: compass_topics_live returns % rows for % topics', v_view_topics, v_topics;
  END IF;

  IF (SELECT count(*) FROM inform.compass_stances_live) <> v_rungs THEN
    RAISE EXCEPTION 'CA_0012: compass_stances_live row count does not match compass_stances';
  END IF;

  -- The freeze must actually bite.
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'compass_topics_content_frozen' AND NOT tgisinternal
  ) THEN
    RAISE EXCEPTION 'CA_0012: the legacy content freeze trigger is missing';
  END IF;

  RAISE NOTICE 'CA_0012 OK — % topics / % rungs recorded as revision 1, all answers stamped, views agree, freeze armed.',
    v_topics, v_rungs;
END $$;

COMMIT;
