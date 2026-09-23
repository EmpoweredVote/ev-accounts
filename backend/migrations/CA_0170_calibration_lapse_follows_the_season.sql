BEGIN;

-- =============================================================================
-- CA_0170: the calibration lapse holds Empowered users to what the season asks
-- =============================================================================
-- Created 2026-09-23 with Chris Andrews. Slot allocated by the steward.
--
-- `public.get_calibration_lapsed_users(p_days_threshold)` feeds the nightly
-- calibration-lapse job (pg_cron job 18 'ev-calibration-lapse', 02:00 UTC ->
-- cronService.runCalibrationLapseJob). An active Empowered user who has not
-- answered a required topic is warned at day 25 and day 30, and DEMOTED at
-- day 31: empowered_profiles.is_active goes false and every compass answer they
-- hold is set private (empower.execute_demotion).
--
-- 🔴 BECOMING AND STAYING EMPOWERED WERE TWO DIFFERENT RULES.
--
--   BECOME  run_empower_preflight -> get_compass_completeness(user, candidate_role):
--           the topics the OPEN season asks that compass_topic_roles marks
--           is_required for that role, answered = a row in
--           compass_responses_effective. Moved onto the season by CC_0069.
--   STAY    this function: every compass_topics row with is_live = true,
--           answered = ANY row in the base compass_responses table, clock =
--           compass_topics.went_live_at.
--
-- Measured on prod 2026-09-23 (read-only), three consequences:
--
--   1. It ignored the 17 Season 2 topics that are is_live = false (created
--      staged; opening a season flips no boolean) — so the rule an Empowered
--      profile publishes against was not the rule it was held to.
--   2. It still required `immigration`, which Season 1 asked and Season 2
--      dropped. CC_0066's write gate refuses an answer to a topic the open
--      season does not ask (TOPIC_NOT_FOUND), so nobody who joined after
--      2026-09-04 can ever satisfy it.
--   3. The clock was went_live_at — 2026-03-15..2026-05-07 for all 44 live
--      topics — not the day the obligation began. Any overdue topic was already
--      past day 31 on the user's first night, so the job went straight to
--      demotion with no warning. With (2), the first person to become Empowered
--      would have been demoted the next night, with no way to fix it.
--
-- Nobody was hurt: prod holds 0 empowered_profiles, and the job has recorded 0
-- warnings and 0 demotions across its 206 runs (2026-03-01..2026-09-23).
--
-- 🟢 THE FIX IS ONE RULE, NOT TWO THAT AGREE TODAY.
--
--   inform.compass_required_topic_ids(role) is the required set, defined once.
--   get_compass_completeness now reads it instead of its own copy, and so does
--   this function. The required set is therefore identical by construction:
--   same promoted topics, same role filter, same answered-predicate
--   (compass_responses_effective). The body of get_compass_completeness is
--   otherwise unchanged, and the gate below proves its `required` count is
--   what it was, for every role.
--
--   This follows the CC_0069 ruling (Cantrell, 2026-09-04): when a season
--   raises the bar under an Empowered candidate, they DO have to update their
--   compass. No grandfathering, no pinning to the season they signed up under.
--   This function is the humane half of that ruling — warnings first.
--
-- 🟢 THE CLOCK STARTS WHEN THE OBLIGATION STARTS: the latest of
--
--   · the open season's opened_at   — a new season's topics give everyone a
--                                     full 25/30/31-day window;
--   · empowered_profiles.empowered_at — a new (or re-empowered: execute_
--                                     empowerment resets it) user gets one too;
--   · the tombstone's deleted_at     — an answer the user deleted stops
--                                     counting from the day they deleted it;
--   · the published_at of the revision that set the answer aside — CC_0061's
--                                     moved/invalidated answers stop counting
--                                     when the rung under them moved, which a
--                                     minor revision can do mid-season.
--
--   Without the last two, a reset or a rung move in the middle of a season
--   would be timed from season open and could demote on the first night again.
--
-- ⚠ NO OPEN SEASON => NOBODY LAPSES. The promoted set is empty, so there is
-- nothing to be owed — the same answer get_compass_completeness gives
-- (required 0 => complete). A changeover gap must not demote anyone.
--
-- ⚠ KNOWN RESIDUAL. season_questions carries no created_at, so a topic added
-- to an ALREADY-OPEN season would be timed from the season's opened_at. Seasons
-- are composed while draft, so this is not a path today; if it becomes one,
-- give season_questions a timestamp and add it to the GREATEST below.
--
-- ALSO DROPPED: the zero-argument overload get_calibration_lapsed_users(). It
-- still read is_live, and nothing calls it — cronService, pg_cron job 18 and
-- every repo in the workspace use the p_days_threshold form only (checked
-- 2026-09-23).
--
-- Grants: CREATE OR REPLACE keeps the existing ACL on both changed functions
-- (postgres + service_role only). The new helper gets no grant at all — only
-- the SECURITY DEFINER functions above, which run as its owner, call it.
--
-- Dry-run first: replace the final COMMIT with ROLLBACK.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. The required set, defined once
-- -----------------------------------------------------------------------------
-- EXISTS rather than get_compass_completeness' old JOIN; identical rows because
-- compass_topic_roles' primary key is (topic_id, role_scope), so the JOIN could
-- never produce a topic twice. A NULL role means "every promoted topic", which is
-- what get_compass_completeness(user, NULL) always meant.
CREATE OR REPLACE FUNCTION inform.compass_required_topic_ids(p_role_scope text)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SET search_path TO ''
AS $function$
  SELECT p.id
    FROM inform.compass_topics_promoted p
   WHERE p_role_scope IS NULL
      OR EXISTS (
        SELECT 1 FROM inform.compass_topic_roles ctr
         WHERE ctr.topic_id = p.id
           AND ctr.role_scope = p_role_scope
           AND ctr.is_required = true);
$function$;

REVOKE ALL ON FUNCTION inform.compass_required_topic_ids(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.compass_required_topic_ids(text) FROM anon, authenticated, service_role;

COMMENT ON FUNCTION inform.compass_required_topic_ids(text) IS
  'The topics an account in this role must have answered: what the OPEN season asks '
  '(compass_topics_promoted), narrowed to compass_topic_roles.is_required for the role; '
  'NULL role = every promoted topic. The ONE definition shared by get_compass_completeness '
  '(becoming Empowered) and get_calibration_lapsed_users (staying Empowered) — CA_0170.';


-- -----------------------------------------------------------------------------
-- 2. Completeness reads the shared set. Nothing else in its body changes.
-- -----------------------------------------------------------------------------
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
  -- Denominator: what the OPEN season asks, for this role. Defined once in
  -- inform.compass_required_topic_ids, which the calibration lapse also reads,
  -- so becoming and staying Empowered cannot drift apart (CA_0170).
  SELECT array_agg(t.topic_id) INTO v_topic_ids
    FROM inform.compass_required_topic_ids(p_role_scope) AS t(topic_id);

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
  'stand. Denominator is inform.compass_required_topic_ids (CA_0170; the promoted set, '
  'not compass_topics.is_live); numerator is compass_responses_effective (CC_0069). Feeds '
  'run_empower_preflight''s eligibility gate. Shares its required set with '
  'get_calibration_lapsed_users.';


-- -----------------------------------------------------------------------------
-- 3. The lapse holds users to the same set, on a clock that starts when they owe
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_calibration_lapsed_users(p_days_threshold integer DEFAULT 30)
RETURNS TABLE(user_id uuid, overdue_topic_ids uuid[], days_overdue integer)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO ''
AS $function$
  WITH open_season AS (
    -- At most one row (seasons_one_open). None => nothing is owed.
    SELECT s.opened_at FROM inform.seasons s WHERE s.status = 'open'
  ),
  owed AS (
    SELECT ep.user_id,
           req.topic_id,
           -- GREATEST ignores NULLs: each term applies only when it exists.
           GREATEST(
             os.opened_at,
             ep.empowered_at,
             cr.deleted_at,
             CASE WHEN d.disposition IN ('moved', 'invalidated') THEN er.published_at END
           ) AS owed_since
      FROM empower.empowered_profiles ep
      CROSS JOIN open_season os
      -- user_id is UNIQUE on connected_profiles, so this cannot fan out. The
      -- role is the one run_empower_preflight passes to get_compass_completeness.
      LEFT JOIN connect.connected_profiles cp ON cp.user_id = ep.user_id
      CROSS JOIN LATERAL inform.compass_required_topic_ids(cp.candidate_role) AS req(topic_id)
      -- @suppression-scope: all-answers — _current is read ONLY to date a
      --   tombstone (deleted_at). Whether the topic is answered is decided by
      --   compass_responses_effective below, which is what completeness counts.
      LEFT JOIN inform.compass_responses_current cr
        ON cr.user_id = ep.user_id AND cr.topic_id = req.topic_id
      LEFT JOIN inform.compass_answer_dispositions d
        ON d.user_id = ep.user_id AND d.topic_id = req.topic_id
      LEFT JOIN inform.compass_topic_revisions er ON er.id = d.effective_revision_id
     WHERE ep.is_active = true
       AND NOT EXISTS (
         SELECT 1 FROM inform.compass_responses_effective e
          WHERE e.user_id = ep.user_id AND e.topic_id = req.topic_id)
  )
  SELECT o.user_id,
         array_agg(o.topic_id ORDER BY o.topic_id)          AS overdue_topic_ids,
         (CURRENT_DATE - MIN(o.owed_since)::date)::integer  AS days_overdue
    FROM owed o
   WHERE o.owed_since <= now() - (p_days_threshold || ' days')::interval
   GROUP BY o.user_id;
$function$;

COMMENT ON FUNCTION public.get_calibration_lapsed_users(integer) IS
  'Active Empowered users owing an answer for at least p_days_threshold days. Owed = '
  'inform.compass_required_topic_ids(candidate_role) with no row in '
  'compass_responses_effective — the same rule get_compass_completeness applies at '
  'empowerment. Clock = latest of season opened_at, empowered_at, the tombstone, and '
  'the revision that set the answer aside (CA_0170; was is_live + went_live_at).';

DROP FUNCTION IF EXISTS public.get_calibration_lapsed_users();


-- -----------------------------------------------------------------------------
-- 4. Post-verify
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_def      text;
  v_role     text;
  v_old      int;
  v_new      int;
  v_req      int;
  v_promoted int;
  v_lapsed   int;
BEGIN
  -- No code path of the three may read is_live, and each must read its source.
  FOR v_def IN
    SELECT regexp_replace(pg_get_functiondef(p), '--.*$', '', 'gn')
      FROM unnest(ARRAY[
        'inform.compass_required_topic_ids(text)'::regprocedure,
        'public.get_compass_completeness(uuid,text)'::regprocedure,
        'public.get_calibration_lapsed_users(integer)'::regprocedure]) AS p
  LOOP
    IF v_def LIKE '%is_live%' OR v_def LIKE '%went_live_at%' THEN
      RAISE EXCEPTION 'CA_0170: a function still reads is_live/went_live_at in CODE: %', left(v_def, 120);
    END IF;
  END LOOP;

  v_def := pg_get_functiondef('inform.compass_required_topic_ids(text)'::regprocedure);
  IF v_def NOT LIKE '%compass_topics_promoted%' OR v_def NOT LIKE '%compass_topic_roles%' THEN
    RAISE EXCEPTION 'CA_0170: the required set no longer comes from the promoted set + roles';
  END IF;
  FOR v_def IN
    SELECT regexp_replace(pg_get_functiondef(p), '--.*$', '', 'gn')
      FROM unnest(ARRAY[
        'public.get_compass_completeness(uuid,text)'::regprocedure,
        'public.get_calibration_lapsed_users(integer)'::regprocedure]) AS p
  LOOP
    IF v_def NOT LIKE '%compass_required_topic_ids%' OR v_def NOT LIKE '%compass_responses_effective%' THEN
      RAISE EXCEPTION 'CA_0170: completeness and the lapse must both read the shared set and the effective view';
    END IF;
  END LOOP;

  IF to_regprocedure('public.get_calibration_lapsed_users()') IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0170: the zero-argument is_live overload is still present';
  END IF;

  -- 🔴 Completeness must not move. For every role and for NULL, the shared set
  -- has exactly the rows the old inline JOIN produced, and get_compass_completeness
  -- reports that count (required does not depend on the user).
  SELECT count(*) INTO v_promoted FROM inform.compass_topics_promoted;
  FOR v_role IN SELECT DISTINCT role_scope FROM inform.compass_topic_roles
                UNION ALL SELECT NULL LOOP
    IF v_role IS NULL THEN
      v_old := v_promoted;
    ELSE
      SELECT count(*) INTO v_old
        FROM inform.compass_topics_promoted p
        JOIN inform.compass_topic_roles ctr
          ON ctr.topic_id = p.id AND ctr.role_scope = v_role AND ctr.is_required = true;
    END IF;
    SELECT count(*) INTO v_new FROM inform.compass_required_topic_ids(v_role);
    v_req := (public.get_compass_completeness(gen_random_uuid(), v_role)->>'required')::int;
    IF v_new <> v_old OR v_req <> v_old THEN
      RAISE EXCEPTION 'CA_0170: role % required moved: old % / helper % / completeness %',
        coalesce(v_role, '<null>'), v_old, v_new, v_req;
    END IF;
  END LOOP;

  -- The helper is internal: no API role may call it.
  IF has_function_privilege('anon', 'inform.compass_required_topic_ids(text)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'inform.compass_required_topic_ids(text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0170: compass_required_topic_ids is executable by an API role';
  END IF;
  -- And the lapse keeps its lock-down (CREATE OR REPLACE preserves the ACL).
  IF has_function_privilege('anon', 'public.get_calibration_lapsed_users(integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0170: get_calibration_lapsed_users became executable by anon';
  END IF;

  -- It runs. Its result is what it is; today prod holds no Empowered profile.
  SELECT count(*) INTO v_lapsed FROM public.get_calibration_lapsed_users(31);

  RAISE NOTICE 'CA_0170 OK: one required set (% promoted topics), completeness unchanged for every role, % user(s) past day 31.',
    v_promoted, v_lapsed;
END $$;

COMMIT;
