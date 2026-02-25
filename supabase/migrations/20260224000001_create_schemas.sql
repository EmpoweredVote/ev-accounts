BEGIN;

-- Migration 001: Create schema namespaces
--
-- Creates all 4 schema namespaces for the Empowered Accounts system.
-- The `public` schema already exists in PostgreSQL and is not recreated.
-- The `inform` schema is a namespace-only placeholder for Phase 1;
-- compass tables (topics, stances, responses, change_history) are added in Phase 4.

CREATE SCHEMA IF NOT EXISTS connect;
CREATE SCHEMA IF NOT EXISTS empower;
CREATE SCHEMA IF NOT EXISTS inform;

COMMIT;
