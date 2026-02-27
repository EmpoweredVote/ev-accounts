BEGIN;

-- =============================================================================
-- Migration 020: Phase 6 role system — ENUM to lookup table migration
-- =============================================================================
-- Context: public.user_roles was created in migration 003 with a `role_type`
-- column typed as the `public.role_type` ENUM. ENUMs are rigid — adding new
-- role values requires ALTER TYPE (DDL lock on the type + dependent tables).
-- The CONTEXT.md decision is to migrate to a lookup table (`public.roles`)
-- so that new roles can be added by inserting rows, not running DDL.
--
-- Migration strategy (all steps in one atomic transaction):
--   1. Create public.roles lookup table
--   2. Seed 5 active Alpha roles + 6 legacy ENUM values (inactive) for backfill
--   3. Add nullable role_id FK column to user_roles
--   4. Backfill role_id from existing role_type values
--   5. Make role_id NOT NULL
--   6. Drop old UNIQUE constraint on (user_id, role_type), add partial unique index
--      on (user_id, role_id) WHERE revoked_at IS NULL
--   7. Drop role_type column and the ENUM type
--
-- After this migration:
--   - Active roles = user_roles WHERE revoked_at IS NULL
--   - Re-grant a revoked role = INSERT a new row (old row preserved for history)
--   - Add a new role = INSERT a row into public.roles (no DDL required)
-- =============================================================================


-- =============================================================================
-- Step 1: Create public.roles lookup table
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.roles (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT    NOT NULL UNIQUE,
  slug          TEXT    NOT NULL UNIQUE,
  required_tier TEXT    CHECK (required_tier IN ('connected', 'empowered')),
  description   TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- =============================================================================
-- Step 2: Seed Alpha roles + legacy ENUM values
-- =============================================================================
-- Active roles (is_active = true): 5 Alpha-launch roles
--   contributor  — data input; topics/stances are attributed to this role holder
--   candidate    — civic/political leader; required_tier NULL for Alpha (admin grants)
--   maven        — empowered civic expert (requires Empowered tier)
--   educator     — placeholder; enforcement logic deferred
--   journalist   — placeholder; enforcement logic deferred
--
-- Legacy inactive roles (is_active = false): present in Phase 1 ENUM so that
-- the backfill UPDATE in Step 4 can map existing user_roles rows to a role_id.
-- These are not usable for new grants.

INSERT INTO public.roles (name, slug, required_tier, description, is_active) VALUES
  ('Contributor', 'contributor', NULL,         'Data input role; attributed to topics/stances written by this user', true),
  ('Candidate',   'candidate',  NULL,          'Civic/political leader; increases discoverability', true),
  ('Maven',       'maven',      'empowered',   'Empowered civic expert', true),
  ('Educator',    'educator',   'empowered',   'Educational role — placeholder', false),
  ('Journalist',  'journalist', 'empowered',   'Journalist role — placeholder', false),
  ('Arbiter',     'arbiter',    NULL,           'Legacy role from Phase 1 ENUM — inactive', false),
  ('Moderator',   'moderator',  NULL,           'Legacy role from Phase 1 ENUM — inactive', false),
  ('Juror',       'juror',      NULL,           'Legacy role from Phase 1 ENUM — inactive', false),
  ('Guide',       'guide',      NULL,           'Legacy role from Phase 1 ENUM — inactive', false),
  ('Scribe',      'scribe',     NULL,           'Legacy role from Phase 1 ENUM — inactive', false),
  ('Journo',      'journo',     NULL,           'Legacy alias for journalist — inactive', false)
ON CONFLICT (slug) DO NOTHING;


-- =============================================================================
-- Step 3: Add nullable role_id FK to user_roles
-- =============================================================================
-- Nullable during migration so existing rows do not immediately violate NOT NULL.
-- Made NOT NULL in Step 5 after backfill.

ALTER TABLE public.user_roles
  ADD COLUMN role_id UUID REFERENCES public.roles(id);


-- =============================================================================
-- Step 4: Backfill role_id from existing role_type values
-- =============================================================================
-- Maps each existing ENUM value to the corresponding roles.slug.
-- Legacy ENUM values (arbiter, moderator, juror, guide, scribe, journo) map to
-- the inactive legacy rows seeded in Step 2.

UPDATE public.user_roles ur
SET role_id = r.id
FROM public.roles r
WHERE r.slug = ur.role_type::text;


-- =============================================================================
-- Step 5: Make role_id NOT NULL
-- =============================================================================
-- All rows must have been backfilled in Step 4. Any unmapped rows would cause
-- this step to fail, which is the desired safety behavior.

ALTER TABLE public.user_roles ALTER COLUMN role_id SET NOT NULL;


-- =============================================================================
-- Step 6: Replace old UNIQUE constraint with partial unique index
-- =============================================================================
-- Old constraint: UNIQUE (user_id, role_type) — prevents any duplicate role.
-- New constraint: UNIQUE (user_id, role_id) WHERE revoked_at IS NULL
--   Allows the same role to be re-granted after revocation (new row per grant),
--   while still preventing two simultaneous active grants for the same role.

ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_role_type_key;

-- A user can only hold ONE active grant per role at any time.
-- Revoked rows (revoked_at IS NOT NULL) do not count — they are history.
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_roles_active_unique
  ON public.user_roles(user_id, role_id) WHERE revoked_at IS NULL;


-- =============================================================================
-- Step 7: Drop role_type column and ENUM type
-- =============================================================================

ALTER TABLE public.user_roles DROP COLUMN role_type;
DROP TYPE IF EXISTS public.role_type;


COMMIT;
