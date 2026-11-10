BEGIN;

-- =============================================================================
-- CA_0367: signed-in users can read their own compass answers again
-- =============================================================================
-- Created 2026-11-06. Steward slot CA_0367. Repairs a regression from CA_0348.
--
-- THE BUG
-- GET /api/compass/answers returns 500 for signed-in users on the Supabase-token
-- path. Render log: `[GET /compass/answers] Supabase error: code 42501,
-- permission denied for view compass_topics_promoted`. POST still returns 200,
-- because it writes through adminRpc (service_role). CompassV2's smoke suite
-- (authed-answer-reaches-server, authed-hydrates-server-answers,
-- guest-lenses-promote-on-sign-in) has failed since; it last passed 2026-11-02.
--
-- WHY
-- On that path requestDb() returns createUserClient, so the read runs as
-- `authenticated`. The route reads inform.compass_responses_effective, which
-- LEFT JOINs inform.compass_answer_dispositions, which reads
-- inform.compass_topics_promoted. All three are security_invoker, so the caller
-- needs SELECT on every object underneath. CA_0348 (2026-11-02) made
-- compass_topics_promoted security_invoker and REVOKED SELECT on it from
-- `authenticated`, and gave its new dependency inform.season_questions to
-- service_role only. Its usage survey (pg_stat_statements) saw no `authenticated`
-- reader, but this one is indirect, through two invoker views. Same class as
-- CA_0110: a backend read that reaches a table through a security_invoker view.
--
-- WHAT THIS DOES
-- 1. GRANT SELECT ON inform.compass_topics_promoted TO authenticated.
-- 2. GRANT SELECT ON inform.season_questions TO authenticated. The promoted view
--    joins it, and as an invoker view the caller needs its own grant.
--    inform.seasons is already readable by authenticated (grant + CA_0110 policy).
-- anon stays revoked: no anon path reads compass_responses_effective.
--
-- WHAT THIS EXPOSES
-- Nothing private. compass_topics_promoted is the open season's question list,
-- and every column of it is public ladder content already served by the public
-- topic endpoints. season_questions is which topic revision each season pins
-- (season, topic, question number, display order). RLS is off on season_questions;
-- neither table holds user data.
--
-- VALUES THIS OVERWRITES (for the rule in CLAUDE.md), read on prod 2026-11-06
-- * inform.compass_topics_promoted relacl:
--     {postgres=arwdDxtm/postgres,ev_api=arwd/postgres,service_role=r/postgres}
-- * inform.season_questions relacl:
--     {postgres=arwdDxtm/postgres,ev_api=arwd/postgres,service_role=r/postgres}
-- To undo: REVOKE SELECT ON both FROM authenticated (this reopens the 500).
--
-- PROOF BEFORE WRITING (prod, rolled back): as `authenticated` with the claims of
-- the user holding the most answers, reading compass_responses_effective raised
-- 42501 on compass_topics_promoted. After the two grants inside the same
-- transaction, it read 61 rows, equal to what postgres reads for that user.
--
-- Idempotent: GRANT is safe to re-run.
-- =============================================================================

GRANT SELECT ON inform.compass_topics_promoted TO authenticated;
GRANT SELECT ON inform.season_questions        TO authenticated;

-- Post-verify gate. Reads as the role the route uses, because a grant that exists
-- is not the same as a read that works (watchlist #57).
DO $$
DECLARE
  v_uid   uuid;
  v_owner bigint;
  v_n     bigint;
BEGIN
  SELECT user_id INTO v_uid
    FROM inform.compass_responses_effective
   WHERE deleted_at IS NULL
   GROUP BY user_id ORDER BY count(*) DESC LIMIT 1;

  IF v_uid IS NOT NULL THEN
    SELECT count(*) INTO v_owner
      FROM inform.compass_responses_effective
     WHERE user_id = v_uid AND deleted_at IS NULL;

    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
    SET LOCAL ROLE authenticated;
    SELECT count(*) INTO v_n
      FROM inform.compass_responses_effective
     WHERE user_id = v_uid AND deleted_at IS NULL;
    RESET ROLE;

    IF v_n <> v_owner THEN
      RAISE EXCEPTION 'CA_0367: authenticated reads % of its own answers, postgres reads %',
        v_n, v_owner;
    END IF;
  END IF;

  IF has_table_privilege('anon', 'inform.compass_topics_promoted', 'SELECT')
     OR has_table_privilege('anon', 'inform.season_questions', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0367: anon can SELECT promoted or season_questions';
  END IF;

  RAISE NOTICE 'CA_0367 OK — authenticated reads its own compass_responses_effective rows (% of %); anon still closed.',
    v_n, v_owner;
END $$;

COMMIT;
