BEGIN;

-- =============================================================================
-- CA_0102: grant the engine's DB role (ev_api) access to the trivia schema
-- =============================================================================
-- Created 2026-09-02 with Chris Andrews.
--
-- WHAT THIS DOES
-- Grants role `ev_api` — the role the ev-accounts engine connects to Postgres as —
-- read + write access to the `trivia` schema, matching what `ctc_app` already holds.
--
-- WHY
-- Engine consolidation Phase 1 (PR #344) folded the Civic Trivia Championships (CTC)
-- backend into ev-accounts-api. The standalone civic-trivia-backend service connects
-- as `ctc_app` (which has trivia privileges); the engine connects as `ev_api`, which
-- had NONE. The folded CTC endpoints therefore failed with "permission denied for
-- schema trivia" (collections/game/session) until this grant. The ALTER DEFAULT
-- PRIVILEGES lines keep FUTURE trivia tables reachable so the gap cannot silently
-- return when CTC adds a table.
--
-- APPLIED LIVE 2026-09-02 via the Supabase MCP on project kxsdzaojfaibhuzmclfq;
-- recorded here for reproducibility. There is no migration runner (see CLAUDE.md) —
-- this file documents the change and lets a DB rebuild re-apply it. Idempotent:
-- GRANT / ALTER DEFAULT PRIVILEGES are safe to re-run.
-- =============================================================================

-- Existing objects.
GRANT USAGE ON SCHEMA trivia TO ev_api;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA trivia TO ev_api;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA trivia TO ev_api;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA trivia TO ev_api;

-- Future objects created by the schema owner (postgres) auto-grant to ev_api.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA trivia
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ev_api;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA trivia
  GRANT USAGE, SELECT ON SEQUENCES TO ev_api;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA trivia
  GRANT EXECUTE ON FUNCTIONS TO ev_api;

-- Post-verify gate — fail loudly if ev_api still cannot reach the trivia schema.
DO $$
BEGIN
  IF NOT has_schema_privilege('ev_api', 'trivia', 'USAGE') THEN
    RAISE EXCEPTION 'CA_0102: ev_api lacks USAGE on schema trivia';
  END IF;
  IF NOT has_table_privilege('ev_api', 'trivia.collections', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0102: ev_api lacks SELECT on trivia.collections';
  END IF;
  IF NOT has_table_privilege('ev_api', 'trivia.questions', 'INSERT') THEN
    RAISE EXCEPTION 'CA_0102: ev_api lacks INSERT on trivia.questions';
  END IF;
  IF NOT has_table_privilege('ev_api', 'trivia.questions', 'UPDATE') THEN
    RAISE EXCEPTION 'CA_0102: ev_api lacks UPDATE on trivia.questions';
  END IF;
  RAISE NOTICE 'CA_0102 OK — ev_api granted USAGE + SELECT/INSERT/UPDATE/DELETE on trivia (tables, sequences, functions), with default privileges for future objects';
END $$;

COMMIT;
