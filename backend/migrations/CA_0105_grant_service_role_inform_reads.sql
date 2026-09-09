BEGIN;

-- =============================================================================
-- CA_0105: grant service_role SELECT on the six inform objects authenticated reads
-- =============================================================================
-- Created 2026-09-09 with Chris Andrews. Steward slot CA_0105.
--
-- WHAT THIS DOES
-- Grants role `service_role` SELECT on the six `inform` tables/views that
-- `authenticated` can already read but `service_role` could not:
--   compass_stance_revisions, compass_stances_current, compass_topic_revisions,
--   compass_topics_current, compass_topics_promoted, compass_verdicts.
--
-- WHY
-- requestDb() in src/lib/supabase.ts hands every WorkOS-issued session the
-- service_role client, because PostgREST cannot verify a WorkOS JWT until
-- decision-0002 Phase 4 lands. That code assumed service_role can read whatever
-- authenticated can. It bypasses RLS but holds no GRANT on these six objects, so
-- GET /api/compass/answers and POST /api/compass/answers/batch returned 500
-- (42501 "permission denied for view compass_topics_promoted") for every
-- logged-in user. Observed 2026-09-09 04:24 UTC; pre-dates that day's deploys.
--
-- WHY NOW AND NOT EARLIER
-- Granting service_role anything widens what the service_role KEY can read.
-- That key was publicly leaked (ev-cto watchlist #38) and stayed live until the
-- legacy JWT keys were disabled on 2026-09-09 ~12:52 UTC. This grant was held
-- until after that toggle so it never widened a leaked credential.
--
-- SCOPE
-- Exactly the set where has_table_privilege('authenticated', obj, 'SELECT') is
-- true and has_table_privilege('service_role', obj, 'SELECT') is false, measured
-- live. SELECT only — no writes; writes on these paths go through SECURITY DEFINER
-- RPCs. No ALTER DEFAULT PRIVILEGES: inform grants to authenticated are made
-- per-table, so service_role is kept in step the same way. Phase 4 makes this
-- grant redundant, not wrong.
--
-- APPLIED LIVE 2026-09-09 via the Supabase MCP on project kxsdzaojfaibhuzmclfq;
-- recorded here for reproducibility. Idempotent: GRANT is safe to re-run.
-- =============================================================================

GRANT SELECT ON inform.compass_stance_revisions TO service_role;
GRANT SELECT ON inform.compass_stances_current  TO service_role;
GRANT SELECT ON inform.compass_topic_revisions  TO service_role;
GRANT SELECT ON inform.compass_topics_current   TO service_role;
GRANT SELECT ON inform.compass_topics_promoted  TO service_role;
GRANT SELECT ON inform.compass_verdicts         TO service_role;

-- Post-verify gate — fail loudly if any of the six is still unreadable.
DO $$
DECLARE obj text;
BEGIN
  FOREACH obj IN ARRAY ARRAY[
    'inform.compass_stance_revisions', 'inform.compass_stances_current',
    'inform.compass_topic_revisions',  'inform.compass_topics_current',
    'inform.compass_topics_promoted',  'inform.compass_verdicts'] LOOP
    IF NOT has_table_privilege('service_role', obj, 'SELECT') THEN
      RAISE EXCEPTION 'CA_0105: service_role lacks SELECT on %', obj;
    END IF;
  END LOOP;
  RAISE NOTICE 'CA_0105 OK — service_role can SELECT the six inform objects authenticated reads';
END $$;

COMMIT;
