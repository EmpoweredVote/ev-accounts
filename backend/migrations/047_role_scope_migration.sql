BEGIN;

-- =============================================================================
-- Migration 047: Role Scope Columns, Audit Log, Scoped RPCs, Seed Data
-- =============================================================================
-- Adds feature_scope / jurisdiction_geoid / resource_id to public.user_roles,
-- creates role_audit_log, replaces grant_role / revoke_role / get_user_roles
-- with scope-aware versions, and seeds five initial role slugs.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: Add scope columns to public.user_roles
-- ---------------------------------------------------------------------------

ALTER TABLE public.user_roles ADD COLUMN IF NOT EXISTS feature_scope text;
ALTER TABLE public.user_roles ADD COLUMN IF NOT EXISTS jurisdiction_geoid text;
ALTER TABLE public.user_roles ADD COLUMN IF NOT EXISTS resource_id text;

-- Backfill existing rows before applying NOT NULL
UPDATE public.user_roles SET feature_scope = 'platform' WHERE feature_scope IS NULL;

ALTER TABLE public.user_roles ALTER COLUMN feature_scope SET NOT NULL;
ALTER TABLE public.user_roles ALTER COLUMN feature_scope SET DEFAULT 'platform';

-- CHECK constraint on feature_scope
DO $$ BEGIN
  ALTER TABLE public.user_roles ADD CONSTRAINT chk_user_roles_feature_scope
    CHECK (feature_scope IN ('platform', 'jurisdiction', 'resource'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Section 2: Replace unique index (create new before dropping old)
-- ---------------------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_roles_scope_active_unique
  ON public.user_roles (user_id, role_id, feature_scope, jurisdiction_geoid, resource_id)
  NULLS NOT DISTINCT
  WHERE revoked_at IS NULL;

DROP INDEX IF EXISTS idx_user_roles_active_unique;

-- ---------------------------------------------------------------------------
-- Section 3: Create role_audit_log table
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.role_audit_log (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id          uuid        NOT NULL REFERENCES public.users(id),
  target_user_id    uuid        NOT NULL REFERENCES public.users(id),
  feature_scope     text,
  jurisdiction_geoid text,
  resource_id       text,
  action            text        NOT NULL,
  target_type       text,
  target_id         text,
  fields_changed    text[],
  snapshot_after    jsonb,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_role_audit_log_actor_id
  ON public.role_audit_log (actor_id);

CREATE INDEX IF NOT EXISTS idx_role_audit_log_target_user_id
  ON public.role_audit_log (target_user_id);

CREATE INDEX IF NOT EXISTS idx_role_audit_log_feature_scope
  ON public.role_audit_log (feature_scope);

CREATE INDEX IF NOT EXISTS idx_role_audit_log_created_at
  ON public.role_audit_log (created_at DESC);

-- ---------------------------------------------------------------------------
-- Section 4: Replace grant_role RPC (scope-aware, SET search_path = '')
-- ---------------------------------------------------------------------------
-- NOTE: DROP old 2-param overloads first. CREATE OR REPLACE cannot change
-- a function's parameter signature — it creates a new overload instead.
-- IF EXISTS guards make this idempotent on fresh databases.
DROP FUNCTION IF EXISTS public.grant_role(uuid, text);
DROP FUNCTION IF EXISTS public.revoke_role(uuid, text);

CREATE OR REPLACE FUNCTION public.grant_role(
  p_user_id         uuid,
  p_role_slug       text,
  p_feature_scope   text DEFAULT 'platform',
  p_jurisdiction_geoid text DEFAULT NULL,
  p_resource_id     text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role_id            uuid;
  v_role_required_tier text;
  v_role_is_active     bool;
BEGIN
  SELECT id, required_tier, is_active
  INTO v_role_id, v_role_required_tier, v_role_is_active
  FROM public.roles
  WHERE slug = p_role_slug;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ROLE_NOT_FOUND';
  END IF;

  IF NOT v_role_is_active THEN
    RAISE EXCEPTION 'ROLE_INACTIVE';
  END IF;

  IF v_role_required_tier = 'empowered' THEN
    IF NOT EXISTS (
      SELECT 1 FROM empower.empowered_profiles
      WHERE user_id = p_user_id AND is_active = true
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  ELSIF v_role_required_tier = 'connected' THEN
    IF NOT EXISTS (
      SELECT 1 FROM connect.connected_profiles
      WHERE user_id = p_user_id AND verification_status = 'verified'
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  END IF;

  BEGIN
    INSERT INTO public.user_roles (user_id, role_id, feature_scope, jurisdiction_geoid, resource_id)
    VALUES (p_user_id, v_role_id, p_feature_scope, p_jurisdiction_geoid, p_resource_id);
  EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION 'ROLE_ALREADY_GRANTED';
  END;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 5: Replace revoke_role RPC (scope-aware, IS NOT DISTINCT FROM)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.revoke_role(
  p_user_id            uuid,
  p_role_slug          text,
  p_feature_scope      text DEFAULT 'platform',
  p_jurisdiction_geoid text DEFAULT NULL,
  p_resource_id        text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.user_roles ur
  SET revoked_at = now()
  FROM public.roles r
  WHERE ur.role_id = r.id
    AND ur.user_id = p_user_id
    AND r.slug = p_role_slug
    AND ur.revoked_at IS NULL
    AND ur.feature_scope = p_feature_scope
    AND (ur.jurisdiction_geoid IS NOT DISTINCT FROM p_jurisdiction_geoid)
    AND (ur.resource_id IS NOT DISTINCT FROM p_resource_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 6: Replace get_user_roles RPC (extended return with scope fields)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_user_roles(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(row_to_json(t))
  INTO v_result
  FROM (
    SELECT ur.role_id, r.slug, r.name, ur.granted_at,
           ur.feature_scope, ur.jurisdiction_geoid, ur.resource_id
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id AND ur.revoked_at IS NULL
    ORDER BY ur.granted_at DESC
  ) t;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 7: Seed five role slugs
-- ---------------------------------------------------------------------------

INSERT INTO public.roles (name, slug, required_tier, is_active)
VALUES
  ('Compass Stance Editor',  'compass_stance_editor',   'connected', true),
  ('Campaign Manager',       'campaign_manager',         'connected', true),
  ('CTC Content Editor',     'ctc_content_editor',       'connected', true),
  ('Essentials Data Editor', 'essentials_data_editor',   'connected', true),
  ('Volunteer',              'volunteer',                'connected', true)
ON CONFLICT DO NOTHING;

COMMIT;
