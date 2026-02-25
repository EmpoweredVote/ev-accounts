BEGIN;

-- Migration 002: public.users table and auth trigger
--
-- Extends auth.users with application-level profile data.
-- Soft delete via deleted_at (NULL = active).
-- Deleted users are preserved in the invite chain for Tolerance Rating accountability.
-- The on_auth_user_created trigger auto-creates a public.users row on signup (supports AUTH-01).

CREATE TABLE IF NOT EXISTS public.users (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url   TEXT,
  deleted_at   TIMESTAMPTZ,              -- soft delete; NULL = active
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- Trigger function: auto-create public.users row on auth.users INSERT
-- SECURITY DEFINER with SET search_path = '' prevents search_path hijacking.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.users (id) VALUES (NEW.id);
  RETURN NEW;
END;
$$;

-- Drop and recreate trigger to ensure idempotency on re-runs
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

COMMIT;
