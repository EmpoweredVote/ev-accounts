BEGIN;

-- =============================================================================
-- Migration 014: Phase 3 Alpha Enrollment — Invite system, notification events,
-- and Connect flow schema additions
-- =============================================================================
-- New tables:     connect.invite_codes, connect.invite_chains,
--                 public.notification_events
-- ALTER tables:   connect.connected_profiles (legal_name, home_address, TR default)
--                 connect.verification_sessions (draft columns, UNIQUE, CHECK)
-- View:           connect.connected_profiles_public (recreated to exclude new PII)
-- RLS + grants:   all new tables
-- RPC function:   connect.adjust_inviter_tolerance_rating (SECURITY DEFINER)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Section 1: New tables
-- -----------------------------------------------------------------------------

-- 1a. connect.invite_codes
-- Stores invite codes used to gate Alpha enrollment.
-- created_by NULL  = admin-generated code (no accountability chain)
-- claimed_by NULL  = not yet claimed
-- No INSERT/UPDATE RLS for authenticated — all writes go through service layer.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS connect.invite_codes (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  code         TEXT        NOT NULL UNIQUE,
  created_by   UUID        REFERENCES public.users(id),   -- NULL = admin-created
  claimed_by   UUID        REFERENCES public.users(id),   -- NULL until claimed
  is_claimed   BOOLEAN     NOT NULL DEFAULT false,
  claimed_at   TIMESTAMPTZ,
  expires_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invite_codes_code
  ON connect.invite_codes(code);

CREATE INDEX IF NOT EXISTS idx_invite_codes_created_by
  ON connect.invite_codes(created_by);

CREATE INDEX IF NOT EXISTS idx_invite_codes_claimed_by
  ON connect.invite_codes(claimed_by)
  WHERE claimed_by IS NOT NULL;


-- 1b. connect.invite_chains
-- One record per invitee — permanent accountability link between inviter and
-- invitee. UNIQUE(invitee_id) enforces: one invite chain per person, ever.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS connect.invite_chains (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id     UUID        NOT NULL REFERENCES public.users(id),
  invitee_id     UUID        NOT NULL REFERENCES public.users(id),
  invite_code_id UUID        NOT NULL REFERENCES connect.invite_codes(id),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (invitee_id)
);

CREATE INDEX IF NOT EXISTS idx_invite_chains_inviter
  ON connect.invite_chains(inviter_id);

CREATE INDEX IF NOT EXISTS idx_invite_chains_invitee
  ON connect.invite_chains(invitee_id);


-- 1c. public.notification_events
-- In-app notification log used by the TR adjustment RPC and other domain events.
-- read_at NULL = unread. Partial index on unread records for efficient queries.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.notification_events (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES public.users(id),
  event_type TEXT        NOT NULL,
  metadata   JSONB,
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notification_events_user
  ON public.notification_events(user_id);

CREATE INDEX IF NOT EXISTS idx_notification_events_unread
  ON public.notification_events(user_id)
  WHERE read_at IS NULL;


-- -----------------------------------------------------------------------------
-- Section 2: ALTER existing tables
-- -----------------------------------------------------------------------------

-- 2a. connect.connected_profiles
-- Add PII columns collected during the Connect verification flow.
-- Set tolerance_rating DEFAULT to 10.00 so new Connected users start at max TR.
-- legal_name and home_address are internal-only — NEVER returned to non-owning
-- users. Enforced at view layer (see Section 3) and serialization layer.
-- -----------------------------------------------------------------------------

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS legal_name   TEXT,
  ADD COLUMN IF NOT EXISTS home_address TEXT;

ALTER TABLE connect.connected_profiles
  ALTER COLUMN tolerance_rating SET DEFAULT 10.00;


-- 2b. connect.verification_sessions
-- Add draft columns for the multi-step Connect flow.
-- Add UNIQUE(user_id) to support upsert (INSERT ... ON CONFLICT DO UPDATE).
-- Add CHECK on step_reached to enforce the flow state machine.
-- Migration 005 did not add a CHECK on step_reached, so this is a new constraint.
-- -----------------------------------------------------------------------------

ALTER TABLE connect.verification_sessions
  ADD COLUMN IF NOT EXISTS legal_name_draft      TEXT,
  ADD COLUMN IF NOT EXISTS home_address_draft    TEXT,
  ADD COLUMN IF NOT EXISTS invite_code_id        UUID REFERENCES connect.invite_codes(id),
  ADD COLUMN IF NOT EXISTS compass_import_draft  JSONB;

ALTER TABLE connect.verification_sessions
  ADD CONSTRAINT verification_sessions_user_id_unique
  UNIQUE (user_id);

ALTER TABLE connect.verification_sessions
  ADD CONSTRAINT verification_sessions_step_check
  CHECK (step_reached IN ('invite', 'profile', 'review', 'complete'));


-- -----------------------------------------------------------------------------
-- Section 3: Recreate connected_profiles_public view
-- -----------------------------------------------------------------------------
-- Drop and recreate to exclude legal_name and home_address in addition to
-- tolerance_rating. All three columns are PII that non-owning users must never
-- receive. This mirrors the split-visibility pattern established in migration 008.
-- -----------------------------------------------------------------------------

DROP VIEW IF EXISTS connect.connected_profiles_public;

CREATE OR REPLACE VIEW connect.connected_profiles_public AS
  SELECT
    id,
    user_id,
    display_name,
    account_standing,
    verification_status,
    verification_method,
    verified_region,
    xp,
    gem_balance,
    gem_reserve_cap,
    veracity_rating,
    -- tolerance_rating intentionally OMITTED
    -- legal_name intentionally OMITTED
    -- home_address intentionally OMITTED
    deleted_at,
    created_at,
    updated_at
  FROM connect.connected_profiles
  WHERE deleted_at IS NULL;

GRANT SELECT ON connect.connected_profiles_public TO authenticated;


-- -----------------------------------------------------------------------------
-- Section 4: RLS policies on new tables
-- -----------------------------------------------------------------------------

-- 4a. connect.invite_codes
-- Creator sees their own codes; claimant sees the code they used.
-- No INSERT/UPDATE/DELETE policies — writes go through service layer only.
-- -----------------------------------------------------------------------------

ALTER TABLE connect.invite_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invite_codes: creator sees own codes"
  ON connect.invite_codes FOR SELECT TO authenticated
  USING ((select auth.uid()) = created_by);

CREATE POLICY "invite_codes: claimant sees claimed code"
  ON connect.invite_codes FOR SELECT TO authenticated
  USING ((select auth.uid()) = claimed_by);


-- 4b. connect.invite_chains
-- Both the inviter and invitee can see their chain record.
-- No INSERT/UPDATE/DELETE policies — record created atomically by service layer.
-- -----------------------------------------------------------------------------

ALTER TABLE connect.invite_chains ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invite_chains: inviter sees own chain"
  ON connect.invite_chains FOR SELECT TO authenticated
  USING ((select auth.uid()) = inviter_id);

CREATE POLICY "invite_chains: invitee sees own chain"
  ON connect.invite_chains FOR SELECT TO authenticated
  USING ((select auth.uid()) = invitee_id);


-- 4c. public.notification_events
-- Owner-only SELECT. Writes come from SECURITY DEFINER RPC functions only.
-- -----------------------------------------------------------------------------

ALTER TABLE public.notification_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_events: owner sees own"
  ON public.notification_events FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);


-- -----------------------------------------------------------------------------
-- Section 5: Grants on new tables
-- -----------------------------------------------------------------------------
-- SELECT only for authenticated. No INSERT/UPDATE/DELETE grants — all writes
-- are performed by SECURITY DEFINER functions or the service layer (pg pool).
-- -----------------------------------------------------------------------------

GRANT SELECT ON connect.invite_codes          TO authenticated;
GRANT SELECT ON connect.invite_chains         TO authenticated;
GRANT SELECT ON public.notification_events    TO authenticated;


-- -----------------------------------------------------------------------------
-- Section 6: RPC function — connect.adjust_inviter_tolerance_rating
-- -----------------------------------------------------------------------------
-- Called by the admin/moderation layer when an invitee is sanctioned.
-- Decrements inviter's tolerance_rating by 0.10, floors at 0.00.
-- Auto-suspends the inviter's Connected account if TR reaches 0.00.
-- Inserts a notification_events record so the inviter is informed.
-- SECURITY DEFINER so it can write to notification_events and update
-- connected_profiles without requiring caller to have those grants.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION connect.adjust_inviter_tolerance_rating(p_invitee_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, connect
AS $$
DECLARE
  v_inviter_id  UUID;
  v_new_tr      NUMERIC(4,2);
BEGIN
  -- Find the direct inviter from the accountability chain.
  SELECT inviter_id INTO v_inviter_id
  FROM connect.invite_chains
  WHERE invitee_id = p_invitee_id;

  -- No chain record = admin-created invite; no TR adjustment applies.
  IF v_inviter_id IS NULL THEN
    RETURN;
  END IF;

  -- Decrement TR by 0.10, floor at 0.00.
  -- COALESCE handles rows that pre-date the DEFAULT 10.00 column change.
  UPDATE connect.connected_profiles
  SET
    tolerance_rating = GREATEST(0.00, COALESCE(tolerance_rating, 10.00) - 0.10),
    updated_at       = now()
  WHERE user_id = v_inviter_id
  RETURNING tolerance_rating INTO v_new_tr;

  -- Auto-suspend the inviter if TR hits the floor.
  IF v_new_tr = 0.00 THEN
    UPDATE connect.connected_profiles
    SET account_standing = 'suspended',
        updated_at       = now()
    WHERE user_id = v_inviter_id;
  END IF;

  -- Notify the inviter so they are aware of the adjustment.
  INSERT INTO public.notification_events (user_id, event_type, metadata)
  VALUES (
    v_inviter_id,
    'tolerance_rating_adjusted',
    jsonb_build_object(
      'reason',                'invitee_sanctioned',
      'invitee_id',            p_invitee_id,
      'new_tolerance_rating',  v_new_tr
    )
  );
END;
$$;

COMMIT;
