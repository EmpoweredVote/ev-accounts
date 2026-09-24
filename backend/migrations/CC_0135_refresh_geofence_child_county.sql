-- CC_0135_refresh_geofence_child_county.sql
-- Slot RESERVED from the allocator (steward: CC_0135).
--
-- Lets the TIGER boundary loader refresh essentials.geofence_child_county itself.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHY A FUNCTION EXISTS AT ALL. essentials.geofence_child_county is a materialized view
-- (migration 1696) holding the child→county spatial assignment, because recomputing it per
-- request cost 15.9 s. It is correct until boundaries are loaded and stale immediately after.
-- The loaders connect as `ev_api`; REFRESH requires OWNERSHIP, and the matview is owned by
-- postgres. Measured 2026-09-24 on prod: as ev_api, "permission denied for materialized view".
-- So no loader could refresh it even if it wanted to, and the job fell to a human reading a
-- printed notice.
--
-- 🔴 THAT NOTICE FAILED TWICE, WHICH IS THE ACTUAL REASON FOR THIS MIGRATION. The 2026-08-14
-- Washington load (281 places) left CI red until someone refreshed by hand. The 2026-09-18..20
-- loads added 5,155 children and the nightly `child→county mapping` job then failed SIX nights
-- running (09-18..09-23) before anyone refreshed. Every affected jurisdiction showed with NO
-- county on the coverage dashboard throughout. A guard that depends on someone reading a line
-- of stdout is not a guard.
--
-- ⚠ CONCURRENTLY INSIDE A FUNCTION IS FINE. The loader's own comment claimed it "cannot run
-- inside a transaction block" — that restriction belongs to CREATE INDEX CONCURRENTLY, not to
-- REFRESH MATERIALIZED VIEW CONCURRENTLY, which is transactional. Measured on prod 2026-09-24
-- inside a plpgsql block: CONCURRENTLY succeeded. It matters: the non-concurrent form takes an
-- AccessExclusiveLock and would stall every coverage-map read for ~17 s mid-load.
--
-- ⚠⚠ EXECUTE IS REVOKED FROM **PUBLIC**, NOT FROM anon. CREATE FUNCTION grants EXECUTE to PUBLIC
-- by default on this instance and `anon` is a member of PUBLIC, so a new function in a served
-- schema lands callable by anonymous internet users. The ACL's leading `=X/` IS that grant;
-- revoking from anon alone is a silent no-op that looks like a fix. ALTER DEFAULT PRIVILEGES
-- does NOT suppress it here (measured, watchlist #74) — every function must revoke for itself.
--
-- IDEMPOTENT: CREATE OR REPLACE, and the grants are absolute rather than incremental.

CREATE OR REPLACE FUNCTION essentials.refresh_geofence_child_county()
RETURNS TABLE (stale_before bigint, stale_after bigint)
LANGUAGE plpgsql
SECURITY DEFINER
-- Every object below is schema-qualified, so nothing is resolved out of the caller's search_path.
SET search_path = pg_catalog
AS $fn$
BEGIN
  -- Counted either side so the caller can log a falsifiable result — "5155 → 0" rather than
  -- "done". A refresh that leaves rows stale means the cause is not staleness, and the loader
  -- reports that as a problem rather than as success.
  SELECT count(*) INTO stale_before FROM essentials.geofence_child_county_stale;

  REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county;

  SELECT count(*) INTO stale_after FROM essentials.geofence_child_county_stale;
  RETURN NEXT;
END;
$fn$;

COMMENT ON FUNCTION essentials.refresh_geofence_child_county() IS
  'Refreshes the child->county matview and returns the unmapped-child count either side. '
  'SECURITY DEFINER because REFRESH needs ownership and the loaders connect as ev_api. '
  'EXECUTE is revoked from PUBLIC and granted to ev_api only. See CC_0135.';

REVOKE EXECUTE ON FUNCTION essentials.refresh_geofence_child_county() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION essentials.refresh_geofence_child_county() TO ev_api;

-- ── POST-VERIFY GATE ─────────────────────────────────────────────────────────────────────
-- House style: assert, do not assume. Each of these has a way of being quietly false — the
-- function landing as INVOKER, the revoke being a no-op, the grant going to the wrong role.
DO $gate$
DECLARE
  v_secdef  boolean;
  v_anon    boolean;
  v_evapi   boolean;
  v_acl     text;
BEGIN
  SELECT p.prosecdef, p.proacl::text
    INTO v_secdef, v_acl
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'essentials' AND p.proname = 'refresh_geofence_child_county';

  IF v_secdef IS NULL THEN
    RAISE EXCEPTION 'CC_0135: essentials.refresh_geofence_child_county() was not created';
  END IF;
  IF NOT v_secdef THEN
    RAISE EXCEPTION 'CC_0135: the function is SECURITY INVOKER — ev_api still cannot refresh';
  END IF;

  v_anon  := has_function_privilege('anon', 'essentials.refresh_geofence_child_county()', 'EXECUTE');
  v_evapi := has_function_privilege('ev_api', 'essentials.refresh_geofence_child_county()', 'EXECUTE');

  IF v_anon THEN
    RAISE EXCEPTION 'CC_0135: anon can EXECUTE this SECURITY DEFINER function. ACL is %. '
      'The revoke must name PUBLIC — revoking from anon alone is a no-op here.', v_acl;
  END IF;
  IF NOT v_evapi THEN
    RAISE EXCEPTION 'CC_0135: ev_api cannot EXECUTE it, so the loader still cannot refresh. ACL is %', v_acl;
  END IF;

  RAISE NOTICE 'CC_0135 OK — SECURITY DEFINER, anon denied, ev_api granted. ACL %', v_acl;
END;
$gate$;
