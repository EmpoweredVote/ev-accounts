BEGIN;

-- Migration 027: Enable RLS on PostGIS system table public.spatial_ref_sys
--
-- PostGIS installs spatial_ref_sys in the public schema automatically.
-- Supabase's linter flags any public-schema table without RLS enabled.
-- We enable RLS with no policies — deny-by-default for all non-service-role
-- connections. The app never queries this table directly; PostGIS uses it
-- internally via SECURITY DEFINER functions that bypass RLS.

ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;

COMMIT;
