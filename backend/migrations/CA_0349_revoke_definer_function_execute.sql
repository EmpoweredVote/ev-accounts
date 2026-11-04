BEGIN;

-- =============================================================================
-- CA_0349: close SECURITY DEFINER functions that no front end calls
-- =============================================================================
-- Created 2026-11-02 with Chris Andrews. Steward slot CA_0349. Addresses the
-- Supabase security advisor's WARN `anon_security_definer_function_executable`
-- (14) and `authenticated_security_definer_function_executable` (21), as pulled
-- 2026-11-02.
--
-- WHAT THIS DOES
-- Revokes EXECUTE from PUBLIC, anon and authenticated on nine functions:
--
--   Trigger functions — nobody calls these; Postgres does not check EXECUTE when
--   a trigger fires, only when the trigger is created:
--     connect.bump_claim_child_counts()      connect.bump_claim_rating_aggregate()
--     connect.derive_claim_position()        connect.log_claim_edit()
--     connect.seed_community_root_claim()
--
--   Helpers only the backend or other definer functions call:
--     connect.calculate_level(bigint)        backend adminRpc() as service_role
--     connect.gen_referral_code()            called inside unlock_referral_code,
--                                            maybe_refresh_referral_for_invitee,
--                                            get_my_invitees (all SECURITY DEFINER)
--     connect.get_xp_leaderboard(text,int)   no caller found in any repo
--     essentials.resolve_user_districts(...) called inside cache_user_districts
--                                            (SECURITY DEFINER, ev_api-only)
--
-- service_role, postgres and ev_api keep exactly what they had.
--
-- WHAT THIS LEAVES ALONE, AND WHY (these findings stay on the advisor on purpose)
-- * civic_spaces.get_public_feed / _post / _replies / _slice — the civic-spaces
--   app calls them as anon and authenticated (src/hooks/usePublicFeed.ts,
--   usePublicThread.ts, usePublicSlice.ts). They are the deliberate public-read
--   surface; scripts/check-anon-read.mjs there asserts they stay DEFINER.
-- * civic_spaces.get_mod_queue, mod_action, is_blocked_by — called from
--   useModQueue.ts and useBlock.ts as authenticated.
-- * civic_spaces.is_moderator() — four RLS policies (action_log, flags) call it
--   for authenticated; revoking would deny moderators.
-- * listening.current_user_is_participant(uuid) — RLS policies on
--   listening.debates / debate_segments / debate_speakers call it for anon and
--   authenticated.
-- * public.st_estimatedextent (3 overloads) — PostGIS, owned and granted by
--   supabase_admin. Tested 2026-11-02 in a rolled-back transaction: postgres's
--   REVOKE is a silent no-op. Only a Supabase support relocation (decision 0006
--   Option B) clears it.
--
-- WHO CALLS WHAT — searched 2026-11-02 across every app repo under
-- ~/Documents/GitHub (CompassV2, civic-spaces, essentials, read-rank, CTC,
-- Empowered-Listening, focused-communities, treasury-tracker, validation-quests,
-- on-the-record, ev-landing, ev-ui, ev-accounts backend/admin/frontend/supabase).
-- No column DEFAULT or RLS policy uses any of the nine revoked functions.
--
-- VALUES THIS OVERWRITES (proacl before this migration)
--   connect.bump_claim_child_counts()        {=X/postgres,postgres=X/postgres,service_role=X/postgres}
--   connect.bump_claim_rating_aggregate()    {=X/postgres,postgres=X/postgres,service_role=X/postgres}
--   connect.derive_claim_position()          {=X/postgres,postgres=X/postgres,service_role=X/postgres}
--   connect.log_claim_edit()                 {=X/postgres,postgres=X/postgres,service_role=X/postgres}
--   connect.seed_community_root_claim()      {=X/postgres,postgres=X/postgres,service_role=X/postgres}
--   connect.calculate_level(bigint)          {postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}
--   connect.gen_referral_code()              {postgres=X/postgres,service_role=X/postgres,authenticated=X/postgres}
--   connect.get_xp_leaderboard(text,integer) {postgres=X/postgres,service_role=X/postgres,authenticated=X/postgres}
--   essentials.resolve_user_districts(double precision,double precision,text[])
--                                            {=X/postgres,postgres=X/postgres,authenticated=X/postgres,anon=X/postgres}
-- To undo, re-GRANT EXECUTE to the roles shown.
--
-- Idempotent: REVOKE is safe to re-run.
-- =============================================================================

REVOKE EXECUTE ON FUNCTION connect.bump_claim_child_counts()       FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION connect.bump_claim_rating_aggregate()   FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION connect.derive_claim_position()         FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION connect.log_claim_edit()                FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION connect.seed_community_root_claim()     FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION connect.calculate_level(bigint)         FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION connect.gen_referral_code()             FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION connect.get_xp_leaderboard(text, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION essentials.resolve_user_districts(double precision, double precision, text[])
  FROM PUBLIC, anon, authenticated;

DO $$
DECLARE
  v_fn   text;
  v_role text;
  v_lvl  int;
  v_revoked text[] := ARRAY[
    'connect.bump_claim_child_counts()', 'connect.bump_claim_rating_aggregate()',
    'connect.derive_claim_position()',   'connect.log_claim_edit()',
    'connect.seed_community_root_claim()', 'connect.calculate_level(bigint)',
    'connect.gen_referral_code()',       'connect.get_xp_leaderboard(text,integer)',
    'essentials.resolve_user_districts(double precision,double precision,text[])'];
BEGIN
  -- (a) anon and authenticated can execute none of the nine.
  FOREACH v_fn IN ARRAY v_revoked LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
      IF has_function_privilege(v_role, v_fn, 'EXECUTE') THEN
        RAISE EXCEPTION 'CA_0349: % can still EXECUTE %', v_role, v_fn;
      END IF;
    END LOOP;
  END LOOP;

  -- (b) the callers that remain keep working, tested as the calling role.
  SET LOCAL ROLE service_role;
  SELECT level INTO v_lvl FROM connect.calculate_level(0::bigint);
  RESET ROLE;
  IF v_lvl IS NULL THEN
    RAISE EXCEPTION 'CA_0349: service_role could not run connect.calculate_level';
  END IF;
  IF NOT has_function_privilege('service_role', 'connect.get_xp_leaderboard(text,integer)', 'EXECUTE')
     OR NOT has_function_privilege('ev_api', 'essentials.cache_user_districts(uuid,double precision,double precision,text[])', 'EXECUTE')
     OR NOT has_function_privilege('ev_api', 'connect.unlock_referral_code(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0349: a backend caller lost EXECUTE it needs';
  END IF;

  -- (c) every function that calls a revoked helper is SECURITY DEFINER, so it runs
  --     as its owner and the revoke cannot reach it. A new invoker caller fails here.
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname IN ('connect', 'essentials', 'civic_spaces', 'inform', 'treasury', 'public')
       AND NOT p.prosecdef
       AND p.prosrc ~ '(calculate_level|gen_referral_code|get_xp_leaderboard|resolve_user_districts)\s*\('
       AND p.proname NOT IN ('calculate_level', 'gen_referral_code', 'get_xp_leaderboard', 'resolve_user_districts')) THEN
    RAISE EXCEPTION 'CA_0349: a SECURITY INVOKER function calls a helper this migration closes';
  END IF;

  -- (d) the deliberate public surface is untouched.
  IF NOT has_function_privilege('anon', 'civic_spaces.get_public_feed(text,text,integer,timestamp with time zone,uuid)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'civic_spaces.is_moderator()', 'EXECUTE')
     OR NOT has_function_privilege('anon', 'listening.current_user_is_participant(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0349: a function a live front end or RLS policy uses lost EXECUTE';
  END IF;

  RAISE NOTICE 'CA_0349 OK — 9 SECURITY DEFINER functions closed to PUBLIC/anon/authenticated (5 trigger functions, calculate_level, gen_referral_code, get_xp_leaderboard, resolve_user_districts); service_role runs calculate_level (level % at 0 XP); civic_spaces and listening functions untouched.', v_lvl;
END $$;

COMMIT;
