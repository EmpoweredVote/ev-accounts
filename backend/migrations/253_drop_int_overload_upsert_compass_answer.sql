-- 232_drop_int_overload_upsert_compass_answer.sql
--
-- Fix: compass answers fail to persist (CompassV2 shows "localStorage only —
-- server sync failed"), and consumers like essentials see no comparison data.
--
-- Root cause: two overloads of public.upsert_compass_answer coexist:
--   * (uuid, uuid, INTEGER, text, boolean)  — original, from migration 025
--   * (uuid, uuid, NUMERIC, text, boolean)  — from migration 030 (0.5-step support)
--
-- Migration 030 used CREATE OR REPLACE to change p_value INT -> NUMERIC, but
-- because the argument *type* changed, Postgres created a SECOND function
-- rather than replacing the first. With both present, calling the RPC with an
-- integer value (e.g. 5) is ambiguous: PostgREST cannot choose a single
-- candidate (PGRST203) and the call errors -> backend returns 500 -> the
-- client reports a failed server sync. Half-step values (e.g. 4.5) matched only
-- the NUMERIC overload and quietly succeeded, which made the bug look
-- intermittent.
--
-- Fix: drop the stale INTEGER overload. The NUMERIC overload remains and
-- accepts integer inputs (1 -> 1.0) losslessly, so all callers keep working.
--
-- Idempotent: DROP FUNCTION IF EXISTS with the exact signature is safe to
-- re-run; if the INTEGER overload is already gone this is a no-op.

BEGIN;

DROP FUNCTION IF EXISTS public.upsert_compass_answer(uuid, uuid, integer, text, boolean);

COMMIT;
