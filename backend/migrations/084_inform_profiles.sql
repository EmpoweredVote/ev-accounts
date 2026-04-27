-- =============================================================================
-- Phase 66 — Inform Profiles Backend Foundation
-- Migration 084: inform.inform_profiles table + trigger + backfill (IBAK-01, IBAK-02)
-- =============================================================================

-- 1. Table creation
CREATE TABLE IF NOT EXISTS inform.inform_profiles (
  user_id                  UUID        PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  yellow_gem_balance       INT         NOT NULL DEFAULT 0,
  last_essentials_location JSONB,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Index on created_at (for future queries ordered by join date)
CREATE INDEX IF NOT EXISTS idx_inform_profiles_created_at
  ON inform.inform_profiles (created_at);

-- 3. Trigger function — auto-creates inform_profiles row on new user
CREATE OR REPLACE FUNCTION inform.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO inform.inform_profiles (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- 4. Trigger — fires AFTER INSERT on public.users
DROP TRIGGER IF EXISTS trg_create_inform_profile ON public.users;
CREATE TRIGGER trg_create_inform_profile
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION inform.handle_new_user();

-- 5. Backfill existing users (idempotent via ON CONFLICT DO NOTHING)
INSERT INTO inform.inform_profiles (user_id)
SELECT id FROM public.users
ON CONFLICT (user_id) DO NOTHING;
