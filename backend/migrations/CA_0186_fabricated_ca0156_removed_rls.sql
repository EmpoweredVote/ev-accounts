-- =============================================================================
-- Default-deny row-level security on essentials._fabricated_ca0156_removed
-- =============================================================================
-- Created 2026-09-23. Source: follow-on to CTO task
-- ev-cto/tasks/2026-09-21-rls-on-new-treasury-tables.md (now archived). That task
-- restored the "RLS on everywhere it can be on" end state set by the 2026-09-10
-- audit (CTO decision 0015). This table drifted BACK into the gap after that task
-- closed: the Supabase linter's rls_disabled_in_public rose from 1 to 2 again, the
-- new offender being this table. Founder decision 2026-09-23 (Chris Andrews):
-- enable default-deny.
--
-- Why a standalone forward migration rather than an edit to CA_0156:
-- CA_0156_la_unified_unsourced_holder_audit.sql created this table with
-- `CREATE TABLE IF NOT EXISTS essentials._fabricated_ca0156_removed AS ...` to
-- ARCHIVE fabricated officeholder-term rows before deleting them, and did not add
-- an RLS line. CA_0156 is merged and applied, so it is immutable history; this
-- file carries the fix forward, exactly as 1891 did for source_hubs.
--
-- BUCKET: PROTECTED (default-deny). RLS-on with NO policy denies every row to any
-- role that does not bypass RLS. The table holds archived essentials.office_terms
-- rows (public-record officeholder tenure data: politician_id, office_id, dates,
-- reason) -- no user identity, no PII -- so this is a classification gap, not a
-- leak, and it matches the live essentials.office_terms table, which is itself
-- default-deny. `essentials` is NOT served by PostgREST (verified 2026-09-21/23),
-- so anon cannot reach the table today even though it holds a schema-default
-- SELECT grant; enabling RLS writes the intent down instead of leaving it implied
-- by an absent setting, and clears the linter's rls_disabled_in_public for it.
--
-- Safe for the backend: postgres, service_role, ev_api and civic_spaces_app all
-- bypass RLS (rolbypassrls = true, verified 2026-09-21), so any server-side read
-- of this audit backup is unaffected. RLS is deliberately NOT forced, matching the
-- 2026-09-10 sweep and the source_hubs / treasury siblings.
--
-- Idempotent: ENABLE ROW LEVEL SECURITY is a no-op when already on. Applies to the
-- shared project kxsdzaojfaibhuzmclfq ("E.V Backend"); this ALTER was already
-- applied there on 2026-09-23, so on prod this file is a verified no-op that only
-- brings the migration source into step with live state.
-- -----------------------------------------------------------------------------

ALTER TABLE essentials._fabricated_ca0156_removed ENABLE ROW LEVEL SECURITY;

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
      AND c.relname = '_fabricated_ca0156_removed'
      AND c.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'row-level security is not enabled on essentials._fabricated_ca0156_removed after migration';
  END IF;

  RAISE NOTICE 'OK -- essentials._fabricated_ca0156_removed default-deny RLS (RLS on, no policy)';
END $$;
