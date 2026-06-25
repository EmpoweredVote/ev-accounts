-- Migration 1065: Security advisor remediation — RLS Disabled in Public (2 ERRORs)
--
-- Supabase security advisor flagged two ERROR-level "rls_disabled_in_public":
--   1. treasury.org_financial_summary  (owner: postgres        — FIXED here)
--   2. public.spatial_ref_sys          (owner: supabase_admin  — see note)
--
-- (1) treasury.org_financial_summary
--     Served ONLY via the backend pg pool. treasuryService.ts is explicit:
--     "ALL treasury reads AND writes must use pool.query() (direct postgres)";
--     supabaseAnon.schema('treasury') fails at runtime. The pool connects as
--     the table owner (postgres), which BYPASSES RLS (we ENABLE, not FORCE).
--     Every other treasury table already has RLS enabled (backend-only ones
--     carry zero policies). This brings org_financial_summary in line:
--     enable RLS, no policy -> anon/authenticated get no PostgREST access,
--     the financial-summary route (pool.query) is unaffected.
--
-- (2) public.spatial_ref_sys
--     A PostGIS system table owned by supabase_admin; the application role
--     cannot ALTER it. It holds public EPSG coordinate-system reference data
--     (no sensitive content) — a well-known benign advisor finding. The DO
--     block attempts the change and no-ops (with a NOTICE) if privileges are
--     insufficient, so this migration applies cleanly either way.

BEGIN;

-- (1) Critical fix — we own this table.
ALTER TABLE treasury.org_financial_summary ENABLE ROW LEVEL SECURITY;

-- (2) Best-effort fix for the PostGIS reference table; safe to skip.
DO $$
BEGIN
  EXECUTE 'ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY';
  -- EPSG reference data is meant to be world-readable; preserve that under RLS.
  EXECUTE 'CREATE POLICY "spatial_ref_sys public read" ON public.spatial_ref_sys FOR SELECT USING (true)';
  RAISE NOTICE 'spatial_ref_sys: RLS enabled + public-read policy created';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'spatial_ref_sys: skipped as % (%) — owned by supabase_admin; benign EPSG reference data', current_user, SQLERRM;
END $$;

-- Verify the critical fix landed.
SELECT 'treasury.org_financial_summary'::text AS table, relrowsecurity AS rls_on
FROM pg_class WHERE oid = 'treasury.org_financial_summary'::regclass;

COMMIT;
