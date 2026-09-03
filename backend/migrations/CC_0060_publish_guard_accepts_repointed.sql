BEGIN;

-- =============================================================================
-- CC_0060: the publish guard learns what "already re-pointed" looks like
-- =============================================================================
-- Created 2026-09-03 with Chris Cantrell. The last code-level thing between the
-- Season 2 re-pointing and opening the season.
--
-- WHAT IT REFUSES TODAY. `inform.admin_publish_topic_revision` raises
-- REPOINTING_NOT_IMPLEMENTED on ANY non-identity rung_map:
--
--   SELECT string_agg(...) INTO v_moved
--     FROM jsonb_each(v_rev.rung_map) e WHERE (e.value #>> '{}') <> e.key;
--   IF v_moved IS NOT NULL THEN RAISE EXCEPTION 'REPOINTING_NOT_IMPLEMENTED: ...
--
-- That was correct when it was written: publishing a moved ladder would have
-- left existing answers indexing positions that no longer meant the same thing,
-- and the re-pointing did not exist. Its own message says so — "Answer
-- re-pointing and the answer_delete_context_guard are not built yet (ADR 0004
-- sec 4) ... or build the re-pointing migration first."
--
-- CC_0058 built it. 2,685 answers now sit in Season 2 at their mapped rungs, and
-- the 28 with nowhere to go are blanked. The guard has no way to know that, so it
-- keeps refusing — and it is called in a loop by `admin_open_season`, where one
-- refusal aborts the whole changeover. Two of the 28 approved revisions trip it:
-- Affordable Housing v2 and Same-Sex Marriage v2.
--
-- 🔴 THE GUARD IS NOT BEING REMOVED. It is being taught the question it was
-- always a proxy for. "Does this rung map move anything" was a stand-in for
-- "would publishing this strand answers on a ladder that changed under them".
-- The real question is answerable now: have the affected answers already been
-- written into the season that pins this revision?
--
-- WHY `season_questions` IS THE RIGHT SOURCE. `politician_answers_pin_fkey`
-- requires (season_id, topic_id, topic_revision_id) to exist in season_questions,
-- so an answer can only reference a revision its own season pins. That gives two
-- things for free: the target season is derivable from the revision, and a
-- revision no season pins cannot have answers at all.
--
-- ⚠ A BLANK COUNTS AS RE-POINTED, AND MUST. The 28 invalidated Same-Sex Marriage
-- answers were written as value 0 (CC_0057), not skipped. They have a Season 2
-- row, so they satisfy this check — which is the whole reason blanking was
-- modelled as a row rather than an absence.
--
-- ⚠ USER ANSWERS ARE DELIBERATELY OUT OF SCOPE. `inform.compass_responses` was
-- NOT re-pointed (Chris's decision, 2026-09-03: a user's answer is their own
-- statement, not a claim we make about them). Including them here would block the
-- publish permanently, because nothing will ever write those rows. The user side
-- is handled by making calibration RE-ASK a topic whose ladder has moved — a
-- product change, not a data one, and still outstanding. Do not "fix" this
-- function to consider compass_responses.

CREATE OR REPLACE FUNCTION inform.admin_publish_topic_revision(
  p_revision_id uuid,
  p_actor_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_rev inform.compass_topic_revisions%ROWTYPE;
  v_cur inform.compass_topic_revisions%ROWTYPE;
  v_moved TEXT;
  v_pins int;
  v_stranded int;
  v_example text;
BEGIN
  SELECT * INTO v_rev FROM inform.compass_topic_revisions WHERE id = p_revision_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: revision %', p_revision_id; END IF;
  IF v_rev.status <> 'approved' THEN
    RAISE EXCEPTION 'NOT_APPROVED: revision % is % - a Compass Stance Editor must approve it first',
      p_revision_id, v_rev.status;
  END IF;

  IF v_rev.rung_map IS NOT NULL THEN
    SELECT string_agg(e.key || '->' || (e.value #>> '{}'), ', ' ORDER BY e.key) INTO v_moved
    FROM jsonb_each(v_rev.rung_map) e WHERE (e.value #>> '{}') <> e.key;

    IF v_moved IS NOT NULL THEN
      -- Which season pins this revision? That is the season the answers must
      -- already have been re-pointed INTO.
      SELECT count(*) INTO v_pins
        FROM inform.season_questions sq WHERE sq.topic_revision_id = p_revision_id;

      IF v_pins = 0 THEN
        -- No season asks this revision, so there is no target to re-point into
        -- and nothing to verify. Publishing it would still move is_current under
        -- a ladder whose rungs mean something new, so keep refusing — the same
        -- answer the old guard gave, for a reason it can now state.
        RAISE EXCEPTION
          'REPOINTING_NOT_IMPLEMENTED: rung map moves or invalidates rungs (%), and no season pins this revision — there is no target season for the answers to have been re-pointed into. Add it to a season''s question set first, re-point, then publish.', v_moved;
      END IF;

      -- Anyone holding an answer on this topic in an EARLIER season who has no
      -- row in the pinning season is about to be stranded: their stored rung
      -- would be read against a ladder that moved beneath it.
      SELECT count(*), min(p.full_name)
        INTO v_stranded, v_example
        FROM inform.season_questions sq
        JOIN inform.seasons s_target ON s_target.id = sq.season_id
        JOIN inform.politician_answers old_a ON old_a.topic_id = sq.topic_id
        JOIN inform.seasons s_old ON s_old.id = old_a.season_id
                                 AND s_old.number < s_target.number
        LEFT JOIN essentials.politicians p ON p.id = old_a.politician_id
       WHERE sq.topic_revision_id = p_revision_id
         AND NOT EXISTS (
           SELECT 1 FROM inform.politician_answers new_a
            WHERE new_a.politician_id = old_a.politician_id
              AND new_a.topic_id      = sq.topic_id
              AND new_a.season_id     = sq.season_id);

      IF v_stranded > 0 THEN
        RAISE EXCEPTION
          'REPOINTING_INCOMPLETE: rung map moves or invalidates rungs (%), and % answer(s) from an earlier season have no row in the season that pins this revision (for example %). Run the re-pointing for this topic first — a blanked answer counts, but it must exist as a row (value 0), not be left out.',
          v_moved, v_stranded, coalesce(v_example, 'unknown politician');
      END IF;
    END IF;
  END IF;

  SELECT * INTO v_cur FROM inform.compass_topic_revisions
  WHERE topic_id = v_rev.topic_id AND is_current;
  IF NOT FOUND THEN RAISE EXCEPTION 'NO_CURRENT_REVISION: topic % has nothing to supersede', v_rev.topic_id; END IF;

  IF v_rev.version NOT IN (v_cur.version, v_cur.version + 1) THEN
    RAISE EXCEPTION 'STALE_VERSION: this draft was numbered v%, but the current revision is now v%. Re-propose it.',
      v_rev.version, v_cur.version;
  END IF;

  UPDATE inform.compass_topic_revisions SET is_current = false, status = 'superseded' WHERE id = v_cur.id;
  UPDATE inform.compass_topic_revisions
  SET is_current = true, status = 'published', published_by = p_actor_id, published_at = now()
  WHERE id = p_revision_id;

  RETURN jsonb_build_object('published_revision', v_rev.revision,
    'published_version', v_rev.version, 'superseded_revision', v_cur.revision);
END;
$function$;

-- -----------------------------------------------------------------------------
-- Prove it, in both directions, then throw the proof away
-- -----------------------------------------------------------------------------
-- A guard that was only ever observed to PASS is not a guard. This publishes the
-- re-pointed Housing revision (must succeed), then deletes one Season 2 answer
-- and tries again (must refuse) — the failure mode the relaxation could have
-- introduced. Both are rolled back.
DO $$
DECLARE
  v_housing_v2 CONSTANT uuid := '598c879d-f387-461c-9120-fbbbf6314bbc';
  v_housing uuid; v_s2 uuid; v_victim uuid;
  v_published boolean := false;
  v_refused_when_stranded boolean := false;
  v_refused_msg text := '';
BEGIN
  SELECT id INTO v_housing FROM inform.compass_topics WHERE topic_key = 'housing';
  SELECT id INTO v_s2 FROM inform.seasons WHERE number = 2;

  -- 1. the re-pointed revision must now publish
  BEGIN
    PERFORM inform.admin_publish_topic_revision(v_housing_v2, NULL);
    v_published := true;
    RAISE EXCEPTION 'PROBE_RB_1';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM <> 'PROBE_RB_1' THEN
      RAISE EXCEPTION 'CC_0060: publishing the RE-POINTED Housing revision still failed: %', SQLERRM;
    END IF;
  END;

  -- 2. strand one answer, and it must refuse again
  BEGIN
    SELECT politician_id INTO v_victim
      FROM inform.politician_answers
     WHERE topic_id = v_housing AND season_id = v_s2 LIMIT 1;

    DELETE FROM inform.politician_answers
     WHERE politician_id = v_victim AND topic_id = v_housing AND season_id = v_s2;

    BEGIN
      PERFORM inform.admin_publish_topic_revision(v_housing_v2, NULL);
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM LIKE 'REPOINTING_INCOMPLETE:%' THEN
        v_refused_when_stranded := true;
        v_refused_msg := left(SQLERRM, 60);
      ELSE
        RAISE;
      END IF;
    END;

    RAISE EXCEPTION 'PROBE_RB_2';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM <> 'PROBE_RB_2' THEN RAISE; END IF;
  END;

  IF NOT v_published THEN
    RAISE EXCEPTION 'CC_0060: the re-pointed revision did not publish — admin_open_season would still abort';
  END IF;
  IF NOT v_refused_when_stranded THEN
    RAISE EXCEPTION 'CC_0060: publishing was ALLOWED with an answer stranded in an earlier season — the guard was removed, not taught';
  END IF;

  RAISE NOTICE 'CC_0060 OK: re-pointed revision publishes; a stranded answer still refuses (%).', v_refused_msg;
END $$;

-- -----------------------------------------------------------------------------
-- Nothing was published
-- -----------------------------------------------------------------------------
-- The probe rolls itself back, but "the probe rolled back" and "no revision
-- changed state" are different claims. Assert the second.
DO $$
DECLARE v_approved int; v_housing_status text;
BEGIN
  SELECT count(*) INTO v_approved FROM inform.compass_topic_revisions WHERE status = 'approved';
  SELECT status INTO v_housing_status FROM inform.compass_topic_revisions
   WHERE id = '598c879d-f387-461c-9120-fbbbf6314bbc';

  IF v_approved <> 28 THEN
    RAISE EXCEPTION 'CC_0060: % revision(s) are approved, expected 28 — the probe leaked a publish', v_approved;
  END IF;
  IF v_housing_status <> 'approved' THEN
    RAISE EXCEPTION 'CC_0060: the Housing v2 revision is now % — the probe leaked a publish', v_housing_status;
  END IF;
  RAISE NOTICE 'CC_0060: 28 revisions still approved, Housing v2 still approved. This migration publishes nothing.';
END $$;

COMMIT;
