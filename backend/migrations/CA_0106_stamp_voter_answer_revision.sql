BEGIN;

-- =============================================================================
-- CA_0106: Stamp voter compass answers with the revision they were given against
-- =============================================================================
-- Implements ev-cto decision 0011 (accepted 2026-09-01, Chris Andrews).
--
-- THE GAP THIS CLOSES. inform.compass_responses.answered_revision_id was added by
-- CA_0012 (ADR 0004 §5) and the READ path already consumes it:
-- compassUserLensService.getRecalibrationFlags treats a NULL as "fresh, do not
-- flag". But the WRITE path never filled it. The live RPC
-- public.upsert_compass_answer (migration 149, unchanged by 253) inserted no
-- revision, and POST /api/compass/answers passes none. Only CA_0012's one-time
-- backfill ever stamped a row. So every answer written since 2026-08-21 is NULL,
-- the stale-answer notice is silently disabled for it, and its raw 1-5 value is
-- re-interpreted against whatever ladder the current season serves — the voter
-- analogue of the "unevidenced claim expressed as a number" CLAUDE.md forbids.
--
-- WHAT THIS DOES.
--   1. A canonical write-side resolver, inform.compass_effective_revision_id().
--   2. Redefines upsert_compass_answer to stamp it on INSERT and on the
--      ON CONFLICT re-answer, into compass_responses AND compass_change_history.
--   3. Backfills the rows written NULL since CA_0012.
--   4. A post-verify gate: the resolver agrees with the read path for every
--      promoted topic, the RPC actually stamps (self-test in a rolled-back
--      subtransaction), and no NULL survives on either table.
--
-- IT DOES NOT change the topic/revision/season model, and it does NOT add a
-- season gate to voter writes (decision 0011: reads follow the person; a voter
-- answer stays one row per (user, topic), overwritten in place). It is
-- independent of the CC_0002 scaffold and does not touch politician_answers.
--
-- WHICH REVISION. The revision the voter actually saw:
--   * promoted topic  -> the season-effective revision (ADR 0006 Option Y): the
--     latest published/superseded revision of the VERSION the open season pinned.
--     This is exactly what getPromotedTopics served, so answered_version equals
--     effective_version and no false stale-flag fires.
--   * live-but-not-promoted topic (no season pin) -> the topic's current
--     published revision, i.e. what compass_topics_current serves. This is the
--     ONLY case where is_current is the right answer; there is no pin to prefer.
--     Decision confirmed by Chris Andrews 2026-09-01.
--
-- HOUSE STYLE. Idempotent (CREATE OR REPLACE; backfill guarded on IS NULL;
-- gate is read-only apart from a self-test that rolls itself back). Dry-run
-- against prod under BEGIN; ... ROLLBACK; before applying, and confirm the
-- revert. Take the next free CA_ slot and verify with
-- `npm run check:migrations --prefix backend` after `git fetch origin`.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. The canonical write-side resolver.
-- -----------------------------------------------------------------------------
-- 🔴 KEEP IN SYNC WITH THE READ PATH. The season-effective branch below mirrors
-- the LATERAL in compassService.getPromotedTopics and
-- compassUserLensService.getRecalibrationFlags byte-for-byte in intent (ADR 0006
-- Option Y). The write path must stamp exactly the revision the read path served;
-- if that lateral ever changes, change this too. The post-verify gate asserts the
-- two agree for every promoted topic, so a divergence fails the next migration
-- that touches this — but a reader editing only the TS lateral would not be
-- caught until then. A later cleanup could repoint the two reads onto this
-- function; that is out of scope here and deliberately not done, to keep this
-- migration DB-only and low-risk.
CREATE OR REPLACE FUNCTION inform.compass_effective_revision_id(p_topic_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT COALESCE(
    -- Season-effective: latest published/superseded revision of the version the
    -- OPEN season pinned for this topic. NULL when the topic is not promoted.
    ( SELECT e.id
        FROM inform.compass_topics_promoted p
        JOIN inform.compass_topic_revisions pin ON pin.id = p.season_revision_id
        JOIN inform.compass_topic_revisions e
          ON e.topic_id = pin.topic_id
         AND e.version  = pin.version
         AND e.status IN ('published', 'superseded')
       WHERE p.id = p_topic_id
       ORDER BY e.revision DESC
       LIMIT 1 ),
    -- Fallback: the topic's current published revision (what compass_topics_current
    -- serves). Only reached for a live topic the open season does not promote.
    ( SELECT c.revision_id FROM inform.compass_topics_current c WHERE c.id = p_topic_id )
  );
$$;

COMMENT ON FUNCTION inform.compass_effective_revision_id(uuid) IS
  'Decision 0011. The revision a voter answer is given against: the season-'
  'effective revision for a promoted topic (ADR 0006 Option Y), else the current '
  'published revision. Mirrors getPromotedTopics/getRecalibrationFlags; keep in sync.';


-- -----------------------------------------------------------------------------
-- 2. Redefine upsert_compass_answer to stamp the revision.
-- -----------------------------------------------------------------------------
-- Same signature as migration 149. Keeps 149's undelete fix (deleted_at = NULL)
-- and adds answered_revision_id on both the INSERT and the ON CONFLICT re-answer,
-- plus on the change_history audit row. A re-answer re-stamps to the currently
-- served revision, because re-answering IS answering against today's ladder.
CREATE OR REPLACE FUNCTION public.upsert_compass_answer(
  p_user_id       UUID,
  p_topic_id      UUID,
  p_value         NUMERIC,
  p_write_in_text TEXT    DEFAULT NULL,
  p_inverted      BOOLEAN DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old_value     NUMERIC;
  v_effective_rev UUID;
  v_result        inform.compass_responses;
BEGIN
  -- Validate topic exists and is live
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE id = p_topic_id AND is_live = true
  ) THEN
    RAISE EXCEPTION 'TOPIC_NOT_FOUND';
  END IF;

  -- The revision this answer is being given against (decision 0011).
  v_effective_rev := inform.compass_effective_revision_id(p_topic_id);

  -- Capture old value for change_history (NULL on first calibration)
  SELECT value INTO v_old_value
  FROM inform.compass_responses
  WHERE user_id = p_user_id AND topic_id = p_topic_id;

  -- UPSERT the response; deleted_at = NULL restores a re-answered deleted topic
  INSERT INTO inform.compass_responses
    (user_id, topic_id, value, write_in_text, inverted, answered_revision_id, updated_at)
  VALUES
    (p_user_id, p_topic_id, p_value, p_write_in_text, p_inverted, v_effective_rev, now())
  ON CONFLICT (user_id, topic_id) DO UPDATE
    SET value                = EXCLUDED.value,
        write_in_text        = EXCLUDED.write_in_text,
        inverted             = EXCLUDED.inverted,
        answered_revision_id = EXCLUDED.answered_revision_id,
        updated_at           = now(),
        deleted_at           = NULL
  RETURNING * INTO v_result;

  -- Append to change_history (always — even same-value recalibration)
  INSERT INTO inform.compass_change_history
    (user_id, topic_id, old_value, new_value, answered_revision_id)
  VALUES (p_user_id, p_topic_id, v_old_value, p_value, v_effective_rev);

  RETURN row_to_json(v_result)::jsonb;
END;
$$;


-- -----------------------------------------------------------------------------
-- 3. Backfill the rows written NULL since the CA_0012 backfill.
-- -----------------------------------------------------------------------------
-- These are post-CA_0012 rows the unstamped write path left NULL. They are
-- stamped to the CURRENTLY effective revision, not necessarily the revision live
-- at write time — an approximation, honest because Season 1 content has had no
-- major (version-bumping) republish, so the effective revision for these topics
-- has not moved since they were written. Guarded on IS NULL, so re-running this
-- migration touches nothing.
UPDATE inform.compass_responses r
   SET answered_revision_id = inform.compass_effective_revision_id(r.topic_id)
 WHERE r.answered_revision_id IS NULL;

UPDATE inform.compass_change_history h
   SET answered_revision_id = inform.compass_effective_revision_id(h.topic_id)
 WHERE h.answered_revision_id IS NULL;


-- -----------------------------------------------------------------------------
-- 4. Post-verify gate.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_n         int;
  v_user      uuid;
  v_topic     uuid;
  v_expected  uuid;
  v_got       uuid;
BEGIN
  -- (a) The resolver must agree with the read path for every promoted topic, or
  --     a fresh answer would be stamped to a revision the voter did not see and
  --     the stale notice would mis-fire.
  IF EXISTS (
    SELECT 1
      FROM inform.compass_topics_promoted p
      JOIN LATERAL (
        SELECT e.id
          FROM inform.compass_topic_revisions pin
          JOIN inform.compass_topic_revisions e
            ON e.topic_id = pin.topic_id
           AND e.version  = pin.version
           AND e.status IN ('published', 'superseded')
         WHERE pin.id = p.season_revision_id
         ORDER BY e.revision DESC
         LIMIT 1
      ) eff ON true
     WHERE inform.compass_effective_revision_id(p.id) IS DISTINCT FROM eff.id
  ) THEN
    RAISE EXCEPTION
      'CA_0106: resolver disagrees with the promoted read lateral for some topic';
  END IF;

  -- (b) The RPC actually stamps. Exercise it against a real user and a real
  --     promoted topic inside a subtransaction, capture what it wrote, then abort
  --     the subtransaction so nothing persists (the answer and its change_history
  --     row are both rolled back). Variable assignments survive the abort; the
  --     database write does not. Skipped only if there is no user or no promoted
  --     topic to exercise it with.
  SELECT id INTO v_user  FROM public.users LIMIT 1;
  SELECT id INTO v_topic FROM inform.compass_topics_promoted ORDER BY id LIMIT 1;

  IF v_user IS NOT NULL AND v_topic IS NOT NULL THEN
    v_expected := inform.compass_effective_revision_id(v_topic);
    BEGIN
      PERFORM public.upsert_compass_answer(v_user, v_topic, 3::numeric, NULL, false);
      SELECT answered_revision_id INTO v_got
        FROM inform.compass_responses
       WHERE user_id = v_user AND topic_id = v_topic;
      RAISE EXCEPTION 'CA_0106_SELFTEST_ROLLBACK';   -- undo the self-test write
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM <> 'CA_0106_SELFTEST_ROLLBACK' THEN RAISE; END IF;
    END;

    IF v_got IS NULL THEN
      RAISE EXCEPTION 'CA_0106 SELFTEST: RPC left answered_revision_id NULL';
    END IF;
    IF v_got IS DISTINCT FROM v_expected THEN
      RAISE EXCEPTION 'CA_0106 SELFTEST: RPC stamped %, resolver expected %',
        v_got, v_expected;
    END IF;
    RAISE NOTICE 'CA_0106 selftest OK — RPC stamped effective revision %, rolled back',
      v_expected;
  ELSE
    RAISE NOTICE 'CA_0106 selftest skipped — no users or no promoted topics';
  END IF;

  -- (c) No NULL may survive on either table.
  SELECT count(*) INTO v_n FROM inform.compass_responses WHERE answered_revision_id IS NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0106: % compass_responses rows still have a NULL answered_revision_id', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM inform.compass_change_history WHERE answered_revision_id IS NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0106: % compass_change_history rows still have a NULL answered_revision_id', v_n;
  END IF;

  RAISE NOTICE 'CA_0106 OK — write path stamps the effective revision, backfill complete, 0 NULLs';
END $$;

COMMIT;
