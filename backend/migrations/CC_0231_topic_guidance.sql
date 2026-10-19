-- CC_0231 — `guidance`: the one line that says what a question is TRYING TO TELL APART.
--
-- Applies with `DATABASE_URL` (`ev_api`). DDL (one column, one trigger) plus the seed DML.
--
--
-- ══ WHAT THIS IS FOR ═════════════════════════════════════════════════════════════════════════
--
-- On the full calibration page the line under the question is meant to orient you. Today it
-- renders `parseTensionTitle(topic).name` — and not one of the 44 promoted titles contains a
-- colon, so that parser returns the short_title every time and the line restates the heading
-- in grey. Forty-four questions, forty-four slots, zero information.
--
-- `guidance` fills it: editorial's own sentence on what the question is asking you to
-- distinguish. It is NOT the designer diary. `public_note` says why we CHANGED a question and
-- is shown to someone whose stored answer was flagged; `guidance` says what the question ASKS
-- and is shown to everyone, every season, change or no change. Two jobs, two columns.
--
--
-- ══ 🔴 WHY IT LIVES ON THE REVISION, NOT ON THE TOPIC ════════════════════════════════════════
--
-- Because it is WORDING, and in this schema wording follows the season's pinned revision.
-- `getPromotedTopics` already takes title, short_title, question_text and version from `eff`
-- (the served revision) and never from the frozen `compass_topics` text columns — ADR 0006
-- Option Y. A `guidance` hung on `compass_topics` would be the one piece of question text that
-- ignored the pin, so a season serving v3's wording would serve v5's guidance beside it. The
-- bug would be invisible until the two disagreed, which is exactly when it matters.
--
--
-- ══ 🔴 THE TRIGGER IS NOT DECORATION — WITHOUT IT THE COLUMN EMPTIES ITSELF ═══════════════════
--
-- `inform.propose_revision` (CA_0016) inserts a new revision with an EXPLICIT column list:
--
--     INSERT INTO inform.compass_topic_revisions (
--       topic_id, revision, version, change_class,
--       title, short_title, question_text,
--       rationale, public_note, review_ref, rung_map,
--       status, is_current, proposed_by) VALUES (...)
--
-- Nothing carries forward that is not named there, and `guidance` is not a parameter of that
-- function. So the FIRST revision proposed on a topic after this migration would land with
-- guidance NULL and the line would go back to grey — silently, months from now, with no edit
-- that mentions guidance anywhere in its diff. `CA_0026`'s admin create path has the same
-- shape, and so will the next insert site nobody has written yet.
--
-- A trigger is used in preference to re-emitting `propose_revision` for exactly that reason:
-- the rule belongs to the column, not to one of the three functions that happen to write it.
--
-- INHERITANCE IS ONLY FOR NULL. An explicit empty string is a deliberate blank and survives —
-- that is how an editor says "this question needs no gloss" without the trigger helpfully
-- undoing them on the next revision. The read side treats '' and NULL alike (absent), so the
-- distinction costs the API nothing and keeps the editor's intent recoverable.

BEGIN;

ALTER TABLE inform.compass_topic_revisions
  ADD COLUMN IF NOT EXISTS guidance TEXT;

COMMENT ON COLUMN inform.compass_topic_revisions.guidance IS
  'One voter-facing line on what this question asks you to tell apart. Shown under the '
  'question to EVERY user, every season. Not public_note: that explains why a question '
  'CHANGED and is shown only to users whose answer was flagged. NULL inherits the topic''s '
  'current revision on insert (CC_0231 trigger); empty string is a deliberate blank.';

CREATE OR REPLACE FUNCTION inform.compass_revision_inherit_guidance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Only NULL inherits. '' is an editor's deliberate blank and is left alone.
  IF NEW.guidance IS NULL THEN
    SELECT r.guidance INTO NEW.guidance
      FROM inform.compass_topic_revisions r
     WHERE r.topic_id = NEW.topic_id
       AND r.is_current
     LIMIT 1;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS compass_revision_inherit_guidance ON inform.compass_topic_revisions;
CREATE TRIGGER compass_revision_inherit_guidance
  BEFORE INSERT ON inform.compass_topic_revisions
  FOR EACH ROW
  EXECUTE FUNCTION inform.compass_revision_inherit_guidance();

COMMIT;
