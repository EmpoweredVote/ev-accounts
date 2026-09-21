BEGIN;

-- =============================================================================
-- CC_0116: statement logging on `postgres`, so a staff stance read is visible
-- =============================================================================
-- Created 2026-09-17 with Chris Andrews. Implements ADR 0007 §5 (privacy floors);
-- mechanism designed in
-- docs/superpowers/specs/2026-09-15-stance-read-audit-design.md.
--
-- WHAT THIS DOES
-- Turns on per-statement logging for the `postgres` role ONLY. A stance read
-- performed by a human then appears in the Postgres logs; the same read performed
-- by the application does not.
--
-- WHY ONLY `postgres`, AND WHY THAT IS ENOUGH
-- Measured against production on 2026-09-17. Five roles can read
-- inform.compass_responses in full:
--
--   ev_api                   direct grant + BYPASSRLS   the application  (not logged, deliberate)
--   service_role             direct grant + BYPASSRLS   the application  (not logged, deliberate)
--   postgres                 direct grant + pg_read_all_data             <- THIS FILE
--   supabase_read_only_user  pg_read_all_data + BYPASSRLS   Supabase's
--   supabase_etl_admin       pg_read_all_data + BYPASSRLS   Supabase's
--   supabase_admin           superuser                      Supabase's
--
-- `postgres` is the ONLY one of those whose credential an EV human can obtain — it
-- is the role the Dashboard hands out. The bottom three are platform-operated and
-- their credentials are held by Supabase, not by us; `ALTER ROLE` on them is
-- refused (this role has CREATEROLE but is not superuser and holds no admin option
-- over them), and `supabase_admin` additionally carries log_statement=none set by
-- the platform. Vendor access is real and is NOT auditable from inside the vendor's
-- own database — see ADR 0007 §5, which scopes the floor to EV's conduct.
--
-- cli_login_postgres inherits read access through membership of `postgres` and is
-- NOT covered here, because rolconfig applies to the session's login role and does
-- not inherit. It does not need to be: its password expired 2026-08-17. The guard
-- (check-stance-audit.mjs) asserts it STAYS expired, because renewing it would
-- silently reopen an unlogged path.
--
-- WHY NOT log the application roles
-- inform.compass_responses is read on ordinary product paths many times a request.
-- Logging ev_api or service_role would produce a firehose in which a single human
-- read is invisible — the opposite of the goal. Auditing the API's own reads is a
-- different problem, handled by the visibility-gate test, not by logging.
--
-- COST, AND THE ONE THING TO KNOW ABOUT IT
-- Production stopped authenticating as `postgres` on 2026-09-09, so the only
-- traffic this logs is human and management-API activity. Volume is small.
--
-- ⚠ It logs STATEMENT TEXT, which can embed personal data — an admin query with an
-- email in a WHERE clause puts that email in the log. ADR 0007 §5a caps retention
-- at 7 days (the Supabase Pro observability window), which bounds the exposure.
-- Anyone widening retention must revisit that trade, not just the number.
--
-- REVERSAL
--   ALTER ROLE postgres RESET log_statement;
-- Nothing else to undo. No schema change, no data change.
--
-- There is no migration runner (see CLAUDE.md): this file documents the change and
-- lets a DB rebuild re-apply it. Idempotent — safe to re-run.
-- =============================================================================

ALTER ROLE postgres SET log_statement = 'all';

-- Verify in the same transaction, so a silent no-op cannot pass as success.
DO $verify$
DECLARE v_cfg text[];
BEGIN
  SELECT rolconfig INTO v_cfg FROM pg_roles WHERE rolname = 'postgres';

  IF v_cfg IS NULL OR NOT ('log_statement=all' = ANY (v_cfg)) THEN
    RAISE EXCEPTION
      'CC_0116: log_statement=all is not set on postgres after ALTER ROLE (rolconfig = %)',
      COALESCE(array_to_string(v_cfg, ', '), '(null)');
  END IF;

  RAISE NOTICE 'CC_0116: log_statement=all is set on postgres.';
END
$verify$;

COMMIT;
