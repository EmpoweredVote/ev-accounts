BEGIN;

-- =============================================================================
-- CC_0066: a user may answer what the open season ASKS, not what is_live says
-- =============================================================================
-- Created 2026-09-04 with Chris Cantrell, from a smoke-suite failure minutes
-- after Season 2 opened.
--
-- 🔴 SEVENTEEN OF THE SIXTY QUESTIONS THE APP SERVES WERE SILENTLY DISCARDING
-- ANSWERS. `upsert_compass_answer` opened with
--
--     IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
--                     WHERE id = p_topic_id AND is_live = true)
--       THEN RAISE EXCEPTION 'TOPIC_NOT_FOUND';
--
-- while the READ path serves `inform.compass_topics_promoted` — the open
-- season's question set. Season 2 promoted 60 topics; 43 of them carry
-- is_live = true. So the compass offered a question, the user answered it, and
-- the write was refused with a 404.
--
-- ⚠ AND THE FRONTEND POSTS AUTHED ANSWERS FIRE-AND-FORGET, so there was no
-- error anywhere the user could see. The answer was simply gone. Measured in the
-- Render request log: POST /api/compass/answers returned 404 at 14:36:43Z and
-- 14:40:53Z, each time followed by two 200s — which is exactly the smoke
-- scenario "answered 3 questions but the server has 2".
--
-- 🔴 THIS IS THE THIRD INSTANCE OF ONE DEFECT, AND THE FIX IS THE SAME ONE
-- TWICE ALREADY APPLIED. compassService says it plainly, twice:
--
--   "This replaced `compass_topics WHERE is_live = true`, which gave the right
--    44 rows for the wrong reason — `is_live` is a global boolean that cannot
--    notice a season dropping a topic, and cannot ever say *promoted where*."
--
--   "It used to check `is_live = true`. That was the same defect as
--    compassContributor's old pre-flight: a global boolean standing in for a
--    per-season, eventually per-jurisdiction question, right for the wrong
--    reason while 44/44 topics are live."
--
-- 44/44 were live, so both read sites were right for the wrong reason and the
-- write gate looked fine beside them. At 43/60 "the wrong reason" stopped
-- producing the right answer. So the gate moves to the same source of truth the
-- read path uses, rather than flipping seventeen booleans and leaving the two
-- concepts free to drift apart again.
--
-- ⚠ NOT THE POLITICIAN-ANSWER WRITE GATE. That one is
-- `seasonService.writableTopicIds`, and compassService is explicit that the two
-- must not be merged. This is the USER answer path only, where the question is
-- "do we ask this?" — which is what the promoted set means.
--
-- ⚠ `is_live` IS NOT DROPPED AND NOT FLIPPED. It remains the admin promotion
-- flag and `compassStatsService` still REPORTS it on purpose. Nothing here
-- changes what any surface displays; it changes only which questions may be
-- answered, from "globally live" to "asked by the open season".

CREATE OR REPLACE FUNCTION public.upsert_compass_answer(
  p_user_id uuid,
  p_topic_id uuid,
  p_value numeric,
  p_write_in_text text DEFAULT NULL::text,
  p_inverted boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_old_value NUMERIC;
  v_result    inform.compass_responses;
BEGIN
  -- CC_0066: the open season's question set, not the global is_live flag. A
  -- topic the season does not ask is genuinely not answerable; a topic it does
  -- ask must be, whatever is_live happens to say.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = p_topic_id) THEN
    RAISE EXCEPTION 'TOPIC_NOT_FOUND';
  END IF;

  SELECT value INTO v_old_value FROM inform.compass_responses_current
   WHERE user_id = p_user_id AND topic_id = p_topic_id AND deleted_at IS NULL;

  INSERT INTO inform.compass_responses (user_id, topic_id, value, write_in_text, inverted, updated_at)
  VALUES (p_user_id, p_topic_id, p_value, p_write_in_text, p_inverted, now())
  ON CONFLICT (user_id, topic_id, season_id) DO UPDATE
    SET value=EXCLUDED.value, write_in_text=EXCLUDED.write_in_text,
        inverted=EXCLUDED.inverted, updated_at=now(), deleted_at=NULL
  RETURNING * INTO v_result;

  INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
  VALUES (p_user_id, p_topic_id, v_old_value, p_value);

  RETURN row_to_json(v_result)::jsonb;
END;
$function$;

COMMENT ON FUNCTION public.upsert_compass_answer(uuid, uuid, numeric, text, boolean) IS
  'Record a user''s compass answer. Answerability is membership of the OPEN season''s '
  'promoted set, NOT compass_topics.is_live — a global boolean cannot notice a season '
  '(CC_0066). Not the politician-answer write gate; that is seasonService.writableTopicIds.';

-- -----------------------------------------------------------------------------
-- Prove the gate now admits every question the app serves, and that it would
-- have rejected seventeen of them a moment ago.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_served int; v_old_would_reject int; v_def text;
  v_user uuid; v_topic uuid; v_title text; v_written jsonb;
BEGIN
  SELECT count(*) INTO v_served FROM inform.compass_topics_promoted;

  -- What the OLD guard would have refused, of the questions being served.
  SELECT count(*) INTO v_old_would_reject
    FROM inform.compass_topics_promoted p
    JOIN inform.compass_topics t ON t.id = p.id
   WHERE t.is_live IS NOT TRUE;

  IF v_old_would_reject = 0 THEN
    RAISE WARNING 'CC_0066: the old is_live gate would refuse nothing today. Either every promoted topic is live again or the season changed — this migration is then a hardening, not a fix.';
  END IF;

  -- And the defect cannot come back by someone restoring the old predicate.
  --
  -- ⚠ COMMENTS ARE STRIPPED FIRST, and that is not fastidiousness: the first
  -- version of this check read the raw definition and tripped on the explanatory
  -- comment two dozen lines above, which names `is_live` in order to say the
  -- gate no longer uses it. A guard that fires on its own documentation is a
  -- guard that gets deleted.
  -- 'gn' is Postgres's newline-sensitive mode, so `$` ends at each line and no
  -- backslash escape is needed in the pattern at all.
  v_def := regexp_replace(
    pg_get_functiondef('public.upsert_compass_answer(uuid,uuid,numeric,text,boolean)'::regprocedure),
    '--.*$', '', 'gn');
  IF v_def LIKE '%is_live%' THEN
    RAISE EXCEPTION 'CC_0066: upsert_compass_answer still references is_live in CODE — the write gate has drifted back off the season';
  END IF;
  IF v_def NOT LIKE '%compass_topics_promoted%' THEN
    RAISE EXCEPTION 'CC_0066: upsert_compass_answer no longer gates on the promoted set';
  END IF;

  -- 🔴 THE CHECK THAT ACTUALLY PROVES IT: write an answer to one of the
  -- questions the old gate refused, and see it accepted. A subtransaction, so
  -- the row never survives — an assertion about a served question must not
  -- become a row in somebody's compass.
  SELECT user_id INTO v_user FROM inform.compass_responses LIMIT 1;
  SELECT p.id, tc.title INTO v_topic, v_title
    FROM inform.compass_topics_promoted p
    JOIN inform.compass_topics t ON t.id = p.id
    LEFT JOIN inform.compass_topics_current tc ON tc.id = p.id
   WHERE t.is_live IS NOT TRUE
     AND NOT EXISTS (
       SELECT 1 FROM inform.compass_responses r
        WHERE r.user_id = v_user AND r.topic_id = p.id
          AND r.season_id = (SELECT id FROM inform.seasons WHERE status = 'open'))
   ORDER BY tc.title LIMIT 1;

  IF v_user IS NULL OR v_topic IS NULL THEN
    RAISE WARNING 'CC_0066: no (user, previously-refused topic) pair to probe with — the gate is installed but NOT exercised. Verify by hand.';
  ELSE
    BEGIN
      v_written := public.upsert_compass_answer(v_user, v_topic, 3::numeric, NULL, false);
      IF v_written IS NULL OR (v_written ->> 'value') IS NULL THEN
        RAISE EXCEPTION 'CC_0066: the write returned nothing for "%"', v_title;
      END IF;
      RAISE NOTICE 'CC_0066 probe: "%" now accepts an answer (it returned TOPIC_NOT_FOUND before). Rolled back.', v_title;
      RAISE EXCEPTION 'CC_0066_PROBE_ROLLBACK';
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLERRM = 'TOPIC_NOT_FOUND' THEN
          RAISE EXCEPTION 'CC_0066: the gate STILL refuses "%", which the open season asks', v_title;
        ELSIF SQLERRM <> 'CC_0066_PROBE_ROLLBACK' THEN
          RAISE;
        END IF;
    END;
  END IF;

  RAISE NOTICE 'CC_0066 OK: % questions served, all answerable. The old is_live gate would have refused % of them.',
    v_served, v_old_would_reject;
END $$;

COMMIT;
