BEGIN;

-- Migration 026: Fix users_public SECURITY DEFINER view
--
-- Problem: public.users_public was an implicit SECURITY DEFINER view (ran as the
-- view owner, postgres) which bypassed RLS on public.users. The Supabase linter
-- correctly flags this pattern.
--
-- Fix: Introduce public.users_public_data — a dedicated table holding only the safe
-- public columns (id, display_name, avatar_url) for non-deleted users. The view is
-- recreated with security_invoker = on, pointing at this table.  A trigger on
-- public.users keeps it in sync automatically.
--
-- Application code uses the same view name (users_public) — no app changes needed.

-- -------------------------------------------------------------------------
-- 1. Backing table: only safe public columns
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users_public_data (
  id           UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url   TEXT
);

-- -------------------------------------------------------------------------
-- 2. Backfill from existing active users
-- -------------------------------------------------------------------------
INSERT INTO public.users_public_data (id, display_name, avatar_url)
SELECT id, display_name, avatar_url
FROM public.users
WHERE deleted_at IS NULL
ON CONFLICT (id) DO NOTHING;

-- -------------------------------------------------------------------------
-- 3. RLS: any authenticated user may read; no row is sensitive here
-- -------------------------------------------------------------------------
ALTER TABLE public.users_public_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_public_data: authenticated read"
  ON public.users_public_data
  FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON public.users_public_data TO authenticated;

-- -------------------------------------------------------------------------
-- 4. Sync trigger: keep users_public_data current with public.users
--    Handles: new signups, display_name/avatar_url edits, soft deletes
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_users_public_data()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Auto-insert on new signup (display_name/avatar_url may be NULL initially)
    IF NEW.deleted_at IS NULL THEN
      INSERT INTO public.users_public_data (id, display_name, avatar_url)
      VALUES (NEW.id, NEW.display_name, NEW.avatar_url)
      ON CONFLICT (id) DO UPDATE
        SET display_name = EXCLUDED.display_name,
            avatar_url   = EXCLUDED.avatar_url;
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
      -- User was just soft-deleted: remove from public data
      DELETE FROM public.users_public_data WHERE id = NEW.id;
    ELSIF NEW.deleted_at IS NULL THEN
      -- Active user: upsert safe public fields
      INSERT INTO public.users_public_data (id, display_name, avatar_url)
      VALUES (NEW.id, NEW.display_name, NEW.avatar_url)
      ON CONFLICT (id) DO UPDATE
        SET display_name = EXCLUDED.display_name,
            avatar_url   = EXCLUDED.avatar_url;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_users_sync_public_data
  AFTER INSERT OR UPDATE OF display_name, avatar_url, deleted_at
  ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_users_public_data();

-- -------------------------------------------------------------------------
-- 5. Recreate the view with security_invoker = on (no RLS bypass)
--    No WHERE clause needed: the backing table only holds active users.
-- -------------------------------------------------------------------------
DROP VIEW IF EXISTS public.users_public;

CREATE VIEW public.users_public
  WITH (security_invoker = on)
AS
  SELECT id, display_name, avatar_url
  FROM public.users_public_data;

-- Re-grant SELECT on the view (the DROP removed the old grant)
GRANT SELECT ON public.users_public TO authenticated;

COMMIT;
