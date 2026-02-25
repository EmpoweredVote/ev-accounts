BEGIN;

-- Migration 012: Grant anon SELECT on connect.connected_profiles
--
-- With RLS enabled and no anon policy, anon gets 0 rows (correct).
-- Without this GRANT, anon gets permission denied instead of 0 rows,
-- which breaks RLS tests that assert the row count.
--
-- The connected_profiles_public VIEW is intentionally authenticated-only
-- (not granted to anon) — anon should not be able to browse connected profiles.

GRANT SELECT ON connect.connected_profiles TO anon;

COMMIT;
