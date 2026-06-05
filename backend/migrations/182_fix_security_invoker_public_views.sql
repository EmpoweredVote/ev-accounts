-- Fix SECURITY DEFINER views on public.connected_profiles and public.action_log.
-- Both views are owned by postgres (superuser), causing them to bypass RLS.
-- Setting security_invoker = on makes queries run with the calling user's permissions,
-- enforcing the RLS policies that already exist on the underlying civic_spaces tables.
-- Underlying tables have RLS enabled and grant SELECT to the authenticated role.

ALTER VIEW public.connected_profiles SET (security_invoker = on);
ALTER VIEW public.action_log SET (security_invoker = on);
