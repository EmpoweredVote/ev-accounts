BEGIN;

-- =============================================================================
-- CC_0069: compass completeness measures the season, on answers that stand
-- =============================================================================
-- Created 2026-09-04 with Chris Cantrell. The fourth and last instance of the
-- `is_live` defect, and a second bug sitting on top of it.
--
-- 🔴 DEFECT 1 — THE DENOMINATOR IGNORED THE SEASON. `get_compass_completeness`
-- built its required set from `compass_topics WHERE is_live = true`: 44 topics,
-- while the open season asks 60. So the progress endpoint reported "44
-- required" beside a calibration header counting "/ 60", and a user who
-- answered all 44 read 100% with 16 questions untouched.
--
-- This is the same defect CC_0066 fixed in the write gate and compassService
-- fixed twice in the read path — "a global boolean that cannot notice a season".
-- Fixed the same way: the promoted set is the source of truth for "do we ask
-- this?".
--
-- 🔴 DEFECT 2 — THE NUMERATOR COUNTED ROWS, NOT ANSWERS. It read the BASE table
-- `inform.compass_responses` with no season collapse and no `deleted_at` filter:
--
--     SELECT COUNT(*) FROM inform.compass_responses
--      WHERE user_id = p_user_id AND topic_id = ANY(v_topic_ids);
--
-- One row per season per topic, tombstones included. Measured on prod the day
-- Season 2 opened, for the smoke account: "Abortion" contributed 2 to `answered`
-- and BOTH ROWS WERE SOFT-DELETED; six topics contributed 2 each because they
-- were answered in both seasons. Nobody had crossed 100% yet only because few
-- Season 2 answers existed — the moment a user re-answers a compass they had
-- already completed, `answered` doubles and `percent` runs past 200.
--
-- It now reads `inform.compass_responses_effective` (CC_0062), which is one row
-- per topic for the newest season answered, excludes tombstones, and excludes
-- the answers CC_0061 set aside. So `answered` can no longer exceed `required`,
-- and a suppressed answer correctly stops counting as a stated position — which
-- is the point of the re-ask: their compass IS less complete until they answer
-- again, and the flag is already telling them so.
--
-- ⚠ THE ELIGIBILITY GATE THIS FEEDS, AND WHY IT IS SAFE TODAY.
-- `public.run_empower_preflight` adds a failure when `complete` is false, and
-- any failure sets `eligible: false`. So this function gates becoming an
-- Empowered candidate, through the p_role_scope branch. Measured before
-- changing it, the required counts move:
--
--     federal   26 -> 34        judicial   8 -> 8
--     local     22 -> 35        state     28 -> 40
--
-- which would make a previously-eligible candidate ineligible. It is safe now
-- because THERE ARE NONE: 12 connected profiles, 0 with a candidate_role, 0
-- empowered profiles. Nobody can lose eligibility they do not have.
--
-- 🟢 RULING (Cantrell, 2026-09-04), AND IT IS THE WHOLE POINT RATHER THAN A
-- HAZARD TO REVISIT. Empowered Accounts are coming. When a season raises the
-- question count under a candidate who was already complete, we DO insist that
-- they update their compass before using Empowered features. The bar rising
-- mid-flight is intended: an Empowered profile publishes a compass to voters,
-- and a compass that answers 41 of the 60 questions currently being asked is
-- not a current statement of anybody's positions.
--
-- So the tightening measured above (federal 26 -> 34, local 22 -> 35, state
-- 28 -> 40) is the designed behaviour of the gate, not a regression to guard
-- against. Do NOT "fix" this later by pinning a candidate to the season they
-- signed up under, or by grandfathering existing Empowered profiles past the
-- new count, without reopening that decision with Chris.
--
-- ⚠ WHAT DOES STILL NEED BUILDING is the humane half: a candidate who becomes
-- incomplete at a changeover should be TOLD, and told which questions are
-- missing, rather than discovering it as a refused action. The re-ask already
-- does exactly this for ordinary users — GET /compass/recalibration-flags plus
-- the compass markers and the off-compass summary (CC_0061/CC_0062, PRs #368-
-- #370 and CompassV2 #86-87). An Empowered surface will want the same
-- treatment, sourced from `required` minus `answered` here.
--
-- ⚠ `live_but_not_asked` IS DROPPED FROM `required`, DELIBERATELY. One federal
-- and one state topic are is_live and marked required for their role but are not
-- in Season 2's set. Holding somebody to a question the season does not ask
-- makes completeness unreachable — there is no way to answer it, and CC_0066's
-- gate would refuse the attempt.

CREATE OR REPLACE FUNCTION public.get_compass_completeness(
  p_user_id uuid,
  p_role_scope text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_topic_ids uuid[];
  v_required  int;
  v_answered  int;
  v_percent   int;
BEGIN
  -- Denominator: what the OPEN season asks. `compass_topics_promoted` is the
  -- same source the read path and the write gate use.
  IF p_role_scope IS NOT NULL THEN
    SELECT array_agg(p.id) INTO v_topic_ids
      FROM inform.compass_topics_promoted p
      JOIN inform.compass_topic_roles ctr
        ON ctr.topic_id = p.id
       AND ctr.role_scope = p_role_scope
       AND ctr.is_required = true;
  ELSE
    SELECT array_agg(p.id) INTO v_topic_ids
      FROM inform.compass_topics_promoted p;
  END IF;

  v_required := COALESCE(array_length(v_topic_ids, 1), 0);

  IF v_required = 0 THEN
    RETURN jsonb_build_object('required', 0, 'answered', 0, 'percent', 100, 'complete', true);
  END IF;

  -- Numerator: answers that STAND. compass_responses_effective is one row per
  -- topic (newest season answered), tombstones excluded, and the answers CC_0061
  -- calls moved or invalidated excluded. Reading the base table here is what
  -- made `answered` count seasons and tombstones instead of positions.
  SELECT count(*)::int INTO v_answered
    FROM inform.compass_responses_effective e
   WHERE e.user_id = p_user_id
     AND e.topic_id = ANY(v_topic_ids);

  v_percent := round((v_answered::numeric / v_required) * 100);

  RETURN jsonb_build_object(
    'required',  v_required,
    'answered',  v_answered,
    'percent',   v_percent,
    'complete',  v_answered >= v_required
  );
END;
$function$;

COMMENT ON FUNCTION public.get_compass_completeness(uuid, text) IS
  'Progress against the OPEN season''s question set, counting only answers that still '
  'stand. Denominator is compass_topics_promoted, not compass_topics.is_live; numerator '
  'is compass_responses_effective, not the base table — which counted one row per season '
  'per topic including tombstones (CC_0069). Feeds run_empower_preflight''s eligibility gate.';

-- -----------------------------------------------------------------------------
-- Prove the denominator follows the season and the numerator cannot overshoot.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_def       text;
  v_promoted  int;
  v_result    jsonb;
  v_user      uuid;
  v_bad       int;
  v_role      text;
BEGIN
  v_def := regexp_replace(
    pg_get_functiondef('public.get_compass_completeness(uuid,text)'::regprocedure),
    '--.*$', '', 'gn');
  IF v_def LIKE '%is_live%' THEN
    RAISE EXCEPTION 'CC_0069: get_compass_completeness still reads is_live in CODE';
  END IF;
  IF v_def NOT LIKE '%compass_topics_promoted%' THEN
    RAISE EXCEPTION 'CC_0069: the denominator no longer comes from the promoted set';
  END IF;
  IF v_def NOT LIKE '%compass_responses_effective%' THEN
    RAISE EXCEPTION 'CC_0069: the numerator no longer reads the effective view';
  END IF;

  SELECT count(*) INTO v_promoted FROM inform.compass_topics_promoted;

  -- The default branch must now agree with what the season serves.
  SELECT user_id INTO v_user FROM inform.compass_responses LIMIT 1;
  IF v_user IS NOT NULL THEN
    v_result := public.get_compass_completeness(v_user, NULL);
    IF (v_result->>'required')::int <> v_promoted THEN
      RAISE EXCEPTION 'CC_0069: required is % but the season asks %',
        (v_result->>'required')::int, v_promoted;
    END IF;
    IF (v_result->>'answered')::int > (v_result->>'required')::int THEN
      RAISE EXCEPTION 'CC_0069: answered % exceeds required % — the numerator is still counting rows',
        (v_result->>'answered')::int, (v_result->>'required')::int;
    END IF;
  END IF;

  -- 🔴 The invariant the old numerator broke, checked across EVERY user rather
  -- than the one sampled above: nobody may report more answers than the season
  -- asks, and so nobody may exceed 100%.
  SELECT count(*) INTO v_bad
    FROM (SELECT DISTINCT user_id FROM inform.compass_responses) u
   WHERE ((public.get_compass_completeness(u.user_id, NULL))->>'answered')::int > v_promoted;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0069: % user(s) still report more answers than the season asks', v_bad;
  END IF;

  -- And every role branch stays within its own required set.
  FOR v_role IN SELECT DISTINCT role_scope FROM inform.compass_topic_roles LOOP
    IF v_user IS NOT NULL THEN
      v_result := public.get_compass_completeness(v_user, v_role);
      IF (v_result->>'answered')::int > (v_result->>'required')::int THEN
        RAISE EXCEPTION 'CC_0069: role % reports answered % > required %',
          v_role, (v_result->>'answered')::int, (v_result->>'required')::int;
      END IF;
    END IF;
  END LOOP;

  RAISE NOTICE 'CC_0069 OK: required now % (the open season''s set), and no user can exceed it.', v_promoted;
END $$;

COMMIT;
