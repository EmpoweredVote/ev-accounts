BEGIN;

-- =============================================================================
-- CA_0348: the ten flagged views run as their caller, not as their owner
-- =============================================================================
-- Created 2026-11-02 with Chris Andrews. Steward slot CA_0348. Clears the
-- Supabase security advisor's ERROR `security_definer_view` (10 findings) and
-- WARN `materialized_view_in_api` (1 finding), as pulled 2026-11-02.
--
-- WHAT THIS DOES
-- 1. Sets security_invoker = true on ten views. A view without it reads its
--    tables with the OWNER's rights (postgres, which bypasses RLS), so any role
--    granted the view reads every row whatever the tables' RLS says. With it,
--    the caller's own grants and RLS apply.
--      essentials.politician_occupancy_evidence   essentials.stale_provisional_candidates
--      essentials.current_office_holders          essentials.offices_missing_terms
--      essentials.office_current_holder           essentials.v_duplicate_person_suspects
--      essentials.geofence_child_county_stale
--      inform.compass_topics_current              inform.compass_stances_current
--      inform.compass_topics_promoted
-- 2. GRANT SELECT ON inform.season_questions TO service_role. compass_topics_promoted
--    joins it, and as an invoker view the caller now needs its own grant. CA_0105
--    gave service_role SELECT on the view for the requestDb() path (watchlist #57);
--    this keeps that working. RLS is off on season_questions and service_role
--    bypasses RLS anyway, so this widens nothing service_role could not already
--    read through the view.
-- 3. REVOKE SELECT ON inform.compass_topics_promoted FROM anon, authenticated.
--    Under invoker rights they could no longer read it anyway (no grant on
--    season_questions; anon has none on seasons either), so the grant would only
--    turn a clear refusal into a confusing one about a table they never named.
-- 4. REVOKE SELECT ON essentials.geofence_child_county (materialized view) FROM
--    anon, authenticated.
--
-- WHO READS THESE, MEASURED 2026-11-02 BEFORE WRITING
-- * extensions.pg_stat_statements (since its reset on 2026-05-20): every statement
--   naming any of these eleven objects ran as ev_api (67,562 calls) or postgres
--   (8,826). None as anon, authenticated or service_role.
-- * Both of those roles hold BYPASSRLS and already have SELECT on every table the
--   views read, so invoker rights change nothing for them. Checked per table with
--   has_table_privilege('ev_api', ...).
-- * The essentials schema is not in pgrst.db_schemas, so PostgREST cannot serve
--   the seven essentials views or the materialized view to anyone.
-- * Code search across every app repo under ~/Documents/GitHub: all readers are raw
--   SQL over a DATABASE_URL pool (ev-accounts backend, on-the-record, ev-landing
--   briefing, CI check scripts). No supabase-js `.from()` names any of them.
-- * inform.compass_topics_current and compass_stances_current stay readable by
--   anon and authenticated: they hold SELECT on the base tables, compass_topics
--   has a read-all policy, and compass_topic_revisions' policy admits
--   published/superseded — and 0 current revisions are in any other status.
--
-- VALUES THIS OVERWRITES (for the rule in CLAUDE.md)
-- * reloptions on all ten views: NULL (no security_invoker; definer behaviour).
-- * inform.compass_topics_promoted relacl:
--     {postgres=arwdDxtm/postgres,ev_api=arwd/postgres,anon=r/postgres,
--      authenticated=r/postgres,service_role=r/postgres}
-- * essentials.geofence_child_county relacl:
--     {postgres=arwdDxtm/postgres,anon=r/postgres,authenticated=r/postgres,ev_api=arwd/postgres}
-- * inform.season_questions relacl: {postgres=arwdDxtm/postgres,ev_api=arwd/postgres}
-- To undo: ALTER VIEW ... RESET (security_invoker) and re-grant the lines above.
--
-- Idempotent: ALTER VIEW SET, GRANT and REVOKE are all safe to re-run.
-- =============================================================================

ALTER VIEW essentials.politician_occupancy_evidence SET (security_invoker = true);
ALTER VIEW essentials.stale_provisional_candidates  SET (security_invoker = true);
ALTER VIEW essentials.current_office_holders        SET (security_invoker = true);
ALTER VIEW essentials.offices_missing_terms         SET (security_invoker = true);
ALTER VIEW essentials.office_current_holder         SET (security_invoker = true);
ALTER VIEW essentials.v_duplicate_person_suspects   SET (security_invoker = true);
ALTER VIEW essentials.geofence_child_county_stale   SET (security_invoker = true);
ALTER VIEW inform.compass_topics_current            SET (security_invoker = true);
ALTER VIEW inform.compass_stances_current           SET (security_invoker = true);
ALTER VIEW inform.compass_topics_promoted           SET (security_invoker = true);

GRANT  SELECT ON inform.season_questions              TO   service_role;
REVOKE SELECT ON inform.compass_topics_promoted       FROM anon, authenticated;
REVOKE SELECT ON essentials.geofence_child_county     FROM anon, authenticated;

-- Post-verify gate. Every check reads as the role that uses the object, because a
-- grant that exists is not the same as a read that works (watchlist #57).
DO $$
DECLARE
  v_view   text;
  v_n      bigint;
  v_views  text[] := ARRAY[
    'essentials.politician_occupancy_evidence', 'essentials.stale_provisional_candidates',
    'essentials.current_office_holders',        'essentials.offices_missing_terms',
    'essentials.office_current_holder',         'essentials.v_duplicate_person_suspects',
    'essentials.geofence_child_county_stale',
    'inform.compass_topics_current', 'inform.compass_stances_current',
    'inform.compass_topics_promoted'];
  v_owner_counts bigint[] := '{}';
BEGIN
  -- (a) every view now carries security_invoker.
  FOREACH v_view IN ARRAY v_views LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_class
                    WHERE oid = v_view::regclass
                      AND 'security_invoker=true' = ANY (reloptions)) THEN
      RAISE EXCEPTION 'CA_0348: % is still a security-definer view', v_view;
    END IF;
  END LOOP;

  -- (b) ev_api, the backend's pool role, reads every view and gets the same rows
  --     postgres does. Counted as postgres first, then as ev_api.
  FOREACH v_view IN ARRAY v_views LOOP
    EXECUTE format('SELECT count(*) FROM %s', v_view) INTO v_n;
    v_owner_counts := v_owner_counts || v_n;
  END LOOP;
  SET LOCAL ROLE ev_api;
  FOR i IN 1 .. array_length(v_views, 1) LOOP
    EXECUTE format('SELECT count(*) FROM %s', v_views[i]) INTO v_n;
    IF v_n <> v_owner_counts[i] THEN
      RESET ROLE;
      RAISE EXCEPTION 'CA_0348: ev_api reads % rows from %, postgres reads %',
        v_n, v_views[i], v_owner_counts[i];
    END IF;
  END LOOP;
  RESET ROLE;

  -- (c) service_role (the requestDb() path, CA_0105) still reads the three inform views.
  FOR i IN 8 .. 10 LOOP
    SET LOCAL ROLE service_role;
    EXECUTE format('SELECT count(*) FROM %s', v_views[i]) INTO v_n;
    RESET ROLE;
    IF v_n <> v_owner_counts[i] THEN
      RAISE EXCEPTION 'CA_0348: service_role reads % rows from %, postgres reads %',
        v_n, v_views[i], v_owner_counts[i];
    END IF;
  END LOOP;

  -- (d) anon and authenticated still read the two public ladder views in full.
  FOR i IN 8 .. 9 LOOP
    SET LOCAL ROLE anon;
    EXECUTE format('SELECT count(*) FROM %s', v_views[i]) INTO v_n;
    RESET ROLE;
    IF v_n <> v_owner_counts[i] THEN
      RAISE EXCEPTION 'CA_0348: anon reads % rows from %, postgres reads %',
        v_n, v_views[i], v_owner_counts[i];
    END IF;
    SET LOCAL ROLE authenticated;
    EXECUTE format('SELECT count(*) FROM %s', v_views[i]) INTO v_n;
    RESET ROLE;
    IF v_n <> v_owner_counts[i] THEN
      RAISE EXCEPTION 'CA_0348: authenticated reads % rows from %, postgres reads %',
        v_n, v_views[i], v_owner_counts[i];
    END IF;
  END LOOP;

  -- (e) the revokes landed.
  IF has_table_privilege('anon', 'inform.compass_topics_promoted', 'SELECT')
     OR has_table_privilege('authenticated', 'inform.compass_topics_promoted', 'SELECT')
     OR has_table_privilege('anon', 'essentials.geofence_child_county', 'SELECT')
     OR has_table_privilege('authenticated', 'essentials.geofence_child_county', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0348: anon or authenticated can still SELECT a revoked object';
  END IF;

  RAISE NOTICE 'CA_0348 OK — 10 views now security_invoker; ev_api reads all 10 with the same counts as postgres (office_current_holder %, compass_topics_promoted %), service_role reads the 3 inform views, anon/authenticated read compass_topics_current (%) and compass_stances_current (%) in full; promoted and geofence_child_county closed to anon/authenticated.',
    v_owner_counts[5], v_owner_counts[10], v_owner_counts[8], v_owner_counts[9];
END $$;

COMMIT;
