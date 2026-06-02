-- Migration 235: Fix Phase 77 omission — set politicians.is_appointed=true for Lee III and Taylor
-- Applied: 2026-05-30
--
-- Phase 77 (migration 231) seeded 16 Portland officials. The offices rows for two
-- appointed officials were correctly flagged as appointed positions, but the
-- corresponding politicians rows were left with is_appointed=false. This migration
-- corrects that omission.
--
-- Target rows:
--   external_id=-690003  Raymond C. Lee III   City Administrator (appointed)
--   external_id=-690004  Robert L. Taylor     City Attorney (appointed)
--
-- The offices rows for both officials are already correct and are NOT modified
-- by this migration. Only essentials.politicians is touched.
--
-- Idempotency: re-running is safe — UPDATE on already-true rows is a no-op;
-- ledger INSERT uses ON CONFLICT (version) DO NOTHING.

BEGIN;

UPDATE essentials.politicians
SET is_appointed = true
WHERE external_id IN (-690003, -690004);

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('235')
ON CONFLICT (version) DO NOTHING;

COMMIT;
