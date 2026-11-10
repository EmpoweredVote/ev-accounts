BEGIN;

-- =============================================================================
-- CA_0372: inform.politician_answers_effective runs as its caller
-- =============================================================================
-- Created 2026-11-09 with Chris Andrews. Steward slot CA_0372. Clears the last
-- Supabase security advisor ERROR `security_definer_view` (1 finding, on this
-- view), as pulled 2026-11-09.
--
-- WHY CA_0348 MISSED IT
-- CA_0348 (2026-11-02) switched every view the advisor flagged that day. This view
-- did not exist yet: CC_0349 created it on 2026-11-04 with a plain CREATE VIEW, so
-- it took the Postgres default (owner's rights, postgres, which bypasses RLS).
--
-- WHAT THIS DOES
-- 1. ALTER VIEW inform.politician_answers_effective SET (security_invoker = true).
--    The caller's own grants and RLS now apply to the tables the view reads.
-- 2. REVOKE SELECT ON inform.politician_answers_effective FROM anon.
--    The view reads inform.compass_topics_promoted, and CA_0348 already revoked
--    anon's SELECT on that view. As an invoker view, anon's read now fails with
--    "permission denied for view compass_topics_promoted". Keeping the grant would
--    only turn a clear refusal into a confusing one about an object anon never named.
--
-- WHO READS THIS VIEW, MEASURED 2026-11-09 BEFORE WRITING
-- * Code: six functions in backend/src/lib/compassService.ts (getCandidateAnswers,
--   getPoliticianAnswers, compareWithPoliticians, getBatchPoliticianAnswers,
--   getPoliticianCitations, getTopicAnswerStats). All use pool.query, the backend's
--   DATABASE_URL pool. No supabase-js `.from()` and no other app repo names it.
--   No function in pg_proc names it, SECURITY DEFINER or otherwise.
-- * extensions.pg_stat_statements: every statement naming the view ran as ev_api
--   (546 calls). None as anon, authenticated or service_role.
-- * Tables and functions the view reaches, and each role's access:
--     inform.politician_answers         RLS on; SELECT ev_api, service_role,
--                                        authenticated, anon; policy read-all for
--                                        authenticated, anon
--     inform.compass_topic_revisions    RLS on; SELECT all four; policy admits
--                                        published/superseded for authenticated, anon
--     inform.compass_stance_revisions   RLS on; SELECT all four; policy follows the
--                                        parent revision's status
--     inform.compass_topics_promoted    invoker view (CA_0348); SELECT ev_api,
--                                        service_role, authenticated — not anon
--       -> inform.seasons, inform.season_questions (RLS on, CA_0371), compass_topics_current
--     inform.compass_answer_disposition() SECURITY INVOKER, reads the two revision tables
--   ev_api, service_role and postgres hold BYPASSRLS.
-- * Dry run, BEGIN ... ROLLBACK on prod: with security_invoker set, postgres,
--   ev_api, service_role and authenticated each read 41,231 rows, the same as the
--   definer view; anon gets permission denied (see 2).
--
-- VALUES THIS OVERWRITES (for the rule in CLAUDE.md)
-- * reloptions: NULL (no security_invoker; definer behaviour).
-- * relacl: {postgres=arwdDxtm/postgres,ev_api=arwd/postgres,anon=r/postgres,
--            authenticated=r/postgres,service_role=r/postgres}
-- To undo: ALTER VIEW inform.politician_answers_effective RESET (security_invoker);
--          GRANT SELECT ON inform.politician_answers_effective TO anon;
--
-- Writes no rows. Idempotent: ALTER VIEW SET and REVOKE are safe to re-run.
-- =============================================================================

ALTER VIEW inform.politician_answers_effective SET (security_invoker = true);

REVOKE SELECT ON inform.politician_answers_effective FROM anon;

-- Post-verify gate. Every check reads as the role that uses the view, because a
-- grant that exists is not the same as a read that works (watchlist #57). Each role
-- must see the same ROWS as postgres, not just the same count.
DO $$
DECLARE
  v_roles      text[] := ARRAY['ev_api', 'service_role', 'authenticated'];
  v_role       text;
  v_owner_n    bigint;
  v_owner_hash text;
  v_n          bigint;
  v_hash       text;
  v_sql        text := $q$
    SELECT count(*),
           md5(coalesce(string_agg(
             concat_ws('|', politician_id, topic_id, season_id, value, topic_revision_id),
             ',' ORDER BY politician_id, topic_id, season_id), ''))
      FROM inform.politician_answers_effective $q$;
BEGIN
  -- (a) the view now carries security_invoker.
  IF NOT EXISTS (SELECT 1 FROM pg_class
                  WHERE oid = 'inform.politician_answers_effective'::regclass
                    AND 'security_invoker=true' = ANY (reloptions)) THEN
    RAISE EXCEPTION 'CA_0372: inform.politician_answers_effective is still a security-definer view';
  END IF;

  -- (b) baseline as postgres (owner, BYPASSRLS).
  EXECUTE v_sql INTO v_owner_n, v_owner_hash;
  IF v_owner_n = 0 THEN
    RAISE EXCEPTION 'CA_0372: postgres reads 0 rows from the view; the check below would be vacuous';
  END IF;

  -- (c) every role the backend can read it as gets the same rows.
  FOREACH v_role IN ARRAY v_roles LOOP
    EXECUTE format('SET LOCAL ROLE %I', v_role);
    EXECUTE v_sql INTO v_n, v_hash;
    RESET ROLE;
    IF v_n <> v_owner_n OR v_hash <> v_owner_hash THEN
      RAISE EXCEPTION 'CA_0372: % reads % rows (hash %) from the view, postgres reads % (hash %)',
        v_role, v_n, v_hash, v_owner_n, v_owner_hash;
    END IF;
  END LOOP;

  -- (d) the anon revoke landed.
  IF has_table_privilege('anon', 'inform.politician_answers_effective', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0372: anon can still SELECT inform.politician_answers_effective';
  END IF;

  RAISE NOTICE 'CA_0372 OK — politician_answers_effective is security_invoker; ev_api, service_role and authenticated each read the same % rows as postgres; anon revoked.',
    v_owner_n;
END $$;

COMMIT;
