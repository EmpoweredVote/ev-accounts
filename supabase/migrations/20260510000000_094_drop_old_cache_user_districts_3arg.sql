-- =============================================================================
-- Migration 094: Phase 71 fix — drop ambiguous 3-arg cache_user_districts
--
-- Migration 093 used CREATE OR REPLACE to update cache_user_districts with a
-- 4-arg signature (uuid, float8, float8, text[] DEFAULT ...). Because the old
-- function from migration 090 had a different 3-arg signature (uuid, float8,
-- float8), CREATE OR REPLACE created a NEW overload instead of replacing it.
--
-- This left two overloads, causing "function is not unique" errors whenever
-- the function was called with 3 positional args (all existing call sites),
-- which Postgres refused to resolve. The error was silently swallowed in
-- connect.ts set-location (fail-open), so user_districts was never populated.
--
-- Fix: drop the old 3-arg version. The 4-arg version with a default p_layers
-- array is the canonical implementation; calling it with 3 args works
-- correctly because Postgres fills in the default for the 4th parameter.
-- =============================================================================

DROP FUNCTION IF EXISTS essentials.cache_user_districts(uuid, double precision, double precision);
