-- =============================================================================
-- Default-deny row-level security on essentials.source_hubs
-- =============================================================================
-- Created 2026-09-21. Source: CTO weekly review 2026-09-21, task
-- ev-cto/tasks/2026-09-21-rls-on-new-treasury-tables.md (the seventh flagged
-- table). Founder decision 2026-09-21 (Chris Andrews): the on-the-record owner
-- adds this table's RLS, not the treasury-tracker cleanup.
--
-- Why a standalone forward migration rather than an edit to 1869:
-- source_hubs was created by 1869_source_hubs.sql (Slice 2B), which merged to
-- master via PR #533 and was applied to prod 2026-09-18 WITHOUT an RLS line.
-- 1869 is already merged and applied, so it is immutable history; this file
-- carries the fix forward. It restores the "RLS on everywhere it can be on" end
-- state set by the 2026-09-10 audit (CTO decision 0015) and matched by the
-- treasury sibling
-- (treasury-tracker 20260921120000_rls_new_treasury_tables_default_deny.sql).
--
-- BUCKET: PROTECTED (default-deny). RLS-on with NO policy denies every row to any
-- role that does not bypass RLS. source_hubs holds source-polling config only
-- (name / scope / state / kind / poll_method / domain / query_template /
-- tos_bucket / active / added_via / notes) -- no user identity, no PII -- so this
-- is a classification gap, not a leak. `essentials` is NOT served by PostgREST
-- (verified 2026-09-21), so anon cannot reach the table today even though it
-- holds a schema-default SELECT grant; enabling RLS writes the intent down
-- instead of leaving it implied by an absent setting, and clears the Supabase
-- linter's rls_disabled_in_public count for the table.
--
-- Safe for the backend: postgres, service_role, ev_api and civic_spaces_app all
-- bypass RLS (rolbypassrls = true, verified 2026-09-21), so the discovery
-- pipeline's server-side reads (on-the-record src/discovery/hubs.py::load_hubs)
-- are unaffected -- exactly as for the already-default-deny siblings
-- essentials.discovered_sources and essentials.source_outlets that the pipeline
-- reads and writes today. RLS is deliberately NOT forced, matching the
-- 2026-09-10 sweep and the treasury sibling.
--
-- Idempotent: ENABLE ROW LEVEL SECURITY is a no-op when already on. Applies to
-- the shared project kxsdzaojfaibhuzmclfq ("E.V Backend"); this ALTER was already
-- applied there on 2026-09-21, so on prod this file is a verified no-op that only
-- brings the migration source into step with live state.
-- -----------------------------------------------------------------------------

ALTER TABLE essentials.source_hubs ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- Post-verify gate -- abort the migration if RLS is not actually on.
-- =============================================================================
-- Runs live at apply time: this is the authoritative check that RLS is on in the
-- database this file runs against.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'essentials'
      AND c.relname = 'source_hubs'
      AND c.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'row-level security is not enabled on essentials.source_hubs after migration';
  END IF;

  RAISE NOTICE 'OK -- essentials.source_hubs default-deny RLS (RLS on, no policy)';
END $$;
