-- =============================================================================
-- Phase 41 Plan 02: trivia_service Postgres Role
-- =============================================================================
-- Purpose: dedicated low-privilege role for CTC's direct PostgreSQL connection.
-- CTC connects to ev-accounts Postgres via DATABASE_URL using this role.
-- Scoped to the trivia schema only — cannot read connect/empower/inform/public
-- user data. BYPASSRLS because trivia tables do not contain user PII (they
-- store game data and stats) and CTC needs full DML access.
--
-- Password is NOT stored here. Set at role creation time via execute_sql
-- (see Plan 02 execution notes). Use a strong random 40-char password.
--
-- To create the role (run once via MCP execute_sql or supabase db query):
--   CREATE ROLE trivia_service WITH LOGIN PASSWORD '<REDACTED>';
--   GRANT USAGE ON SCHEMA trivia TO trivia_service;
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA trivia TO trivia_service;
--   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA trivia TO trivia_service;
--   ALTER DEFAULT PRIVILEGES IN SCHEMA trivia GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO trivia_service;
--   ALTER DEFAULT PRIVILEGES IN SCHEMA trivia GRANT USAGE, SELECT ON SEQUENCES TO trivia_service;
--   ALTER ROLE trivia_service SET search_path = trivia;
--   ALTER ROLE trivia_service BYPASSRLS;
-- =============================================================================

-- This migration file documents the intent and grants.
-- Role already created via execute_sql with redacted password.
-- Running these grants again is idempotent.

GRANT USAGE ON SCHEMA trivia TO trivia_service;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA trivia TO trivia_service;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA trivia TO trivia_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA trivia GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO trivia_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA trivia GRANT USAGE, SELECT ON SEQUENCES TO trivia_service;
ALTER ROLE trivia_service SET search_path = trivia;
ALTER ROLE trivia_service BYPASSRLS;
