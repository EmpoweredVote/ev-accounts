BEGIN;

-- =============================================================================
-- Migration 018: Phase 5 Empower Flow schema changes
-- =============================================================================
-- Extends existing tables and creates new infrastructure for the full
-- empowerment and demotion lifecycle. Changes in order:
--   1. connect.connected_profiles  — ADD candidate_role column
--   2. empower.empowered_profiles  — ADD demoted_at, demotion_reason columns
--   3. empower.consent_records     — CREATE TABLE (durable consent audit log)
--   4. empower.execute_empowerment — UPDATE: p_reserved_slug param, re-empower path, retry loop
--   5. empower.execute_demotion    — UPDATE: p_demotion_reason param, sets demoted_at
--
-- All functions:
--   - SECURITY DEFINER (runs with definer's privileges, bypasses RLS)
--   - SET search_path = '' (prevents search_path injection attacks)
--   - Fully-qualified schema.table references throughout
--   - CREATE OR REPLACE preserves existing grants on the functions
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. connect.connected_profiles: ADD candidate_role
-- -----------------------------------------------------------------------------
-- Stores the scope/level of office the user intends to pursue as an Empowered
-- candidate. The preflight validation reads this field to determine which
-- compass topics must be calibrated (role-specific threshold check).
--
-- Values:
--   city_council      — local/municipal office
--   state_legislature — state house or senate
--   us_congress       — federal house or senate
--   president         — US president
--
-- NULL until the user sets their role (before calling preflight).
-- -----------------------------------------------------------------------------

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS candidate_role TEXT
    CHECK (candidate_role IN ('city_council', 'state_legislature', 'us_congress', 'president'));


-- -----------------------------------------------------------------------------
-- 2. empower.empowered_profiles: ADD demoted_at, demotion_reason
-- -----------------------------------------------------------------------------
-- demoted_at:     Set by execute_demotion when is_active flips to false.
--                 NULL for currently active Empowered users.
--                 Preserved on record even if re-empowered (for audit trail).
-- demotion_reason: JSONB payload set by execute_demotion. Shape:
--                  { lapsed_topic_ids: string[], lapsed_at: string,
--                    triggered_by: 'cron' | 'admin' }
--                  NULL for active users or if no reason was provided.
-- -----------------------------------------------------------------------------

ALTER TABLE empower.empowered_profiles
  ADD COLUMN IF NOT EXISTS demoted_at      TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS demotion_reason JSONB;


-- -----------------------------------------------------------------------------
-- 3. empower.consent_records: CREATE TABLE
-- -----------------------------------------------------------------------------
-- Durable audit log for empowerment consent. Users must consent to three
-- things before empowerment: (1) legal name published publicly, (2) compass
-- stances made public, (3) platform terms and candidate pledge.
--
-- Writes go through the service layer (pg pool, SECURITY DEFINER functions)
-- only. No INSERT/UPDATE/DELETE RLS policies — authenticated users may only
-- read their own records.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS empower.consent_records (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  consent_given_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  consent_version  TEXT        NOT NULL DEFAULT '1.0',
  consented_items  TEXT[]      NOT NULL,
  ip_address       TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_consent_records_user_id
  ON empower.consent_records(user_id);

-- RLS: enable and restrict to owner-only reads.
-- Writes are via service layer only — no INSERT/UPDATE/DELETE policies.
ALTER TABLE empower.consent_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY consent_records_owner_select
  ON empower.consent_records
  FOR SELECT
  USING (auth.uid() = user_id);

-- Authenticated users may read their own consent records via the RLS policy above.
GRANT SELECT ON empower.consent_records TO authenticated;


-- -----------------------------------------------------------------------------
-- 4. empower.execute_empowerment (updated for Phase 5)
-- -----------------------------------------------------------------------------
-- Phase 5 changes from Phase 4 version (migration 017):
--   - New parameter: p_reserved_slug (from slug reservation at preflight)
--   - Re-empowerment path: if a demoted row exists (is_active = false), UPDATE
--     it to restore is_active = true, clear demoted_at/demotion_reason, and
--     preserve the original candidate_page_slug (prior links remain valid).
--   - Fresh empowerment path: use p_reserved_slug if provided, else generate.
--     Slug INSERT retries up to 5 times on unique_violation before re-raising.
--   - compass_responses visibility => 'public' preserved from Phase 4.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION empower.execute_empowerment(
  p_user_id              UUID,
  p_legal_name           TEXT,
  p_connected_profile_id UUID,
  p_reserved_slug        TEXT DEFAULT NULL
)
RETURNS empower.empowered_profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_slug     TEXT;
  v_suffix   TEXT;
  v_result   empower.empowered_profiles;
  v_attempts INT := 0;
  v_existing empower.empowered_profiles;
BEGIN

  -- -------------------------------------------------------------------------
  -- Path A: Re-empowerment — demoted row already exists (is_active = false)
  -- -------------------------------------------------------------------------
  -- Restore is_active, clear demotion fields, preserve original slug.
  -- No slug generation needed — original slug is already on the row.
  -- -------------------------------------------------------------------------

  SELECT * INTO v_existing
  FROM empower.empowered_profiles
  WHERE user_id = p_user_id
    AND is_active = false;

  IF FOUND THEN
    UPDATE empower.empowered_profiles
      SET
        is_active        = true,
        empowered_at     = now(),
        demoted_at       = NULL,
        demotion_reason  = NULL,
        updated_at       = now()
      WHERE user_id = p_user_id
        AND is_active = false;

    SELECT * INTO v_result
    FROM empower.empowered_profiles
    WHERE user_id = p_user_id;

  ELSE

    -- -----------------------------------------------------------------------
    -- Path B: Fresh empowerment — no existing row for this user
    -- -----------------------------------------------------------------------
    -- Use reserved slug if provided; otherwise generate kebab-case + 4-char
    -- random suffix. Retry INSERT up to 5 times on unique_violation.
    -- -----------------------------------------------------------------------

    IF p_reserved_slug IS NOT NULL THEN
      v_slug := p_reserved_slug;
    ELSE
      -- Generate initial slug
      v_suffix := substring(md5(gen_random_uuid()::text) FROM 1 FOR 4);
      v_slug := rtrim(
        lower(regexp_replace(p_legal_name, '[^a-zA-Z0-9]+', '-', 'g')),
        '-'
      ) || '-' || v_suffix;
    END IF;

    -- Retry loop: handle unique_violation on candidate_page_slug up to 5 times.
    -- If p_reserved_slug was provided and collides, we still regenerate a fresh
    -- suffix on retry (reservation race condition — extremely rare).
    LOOP
      BEGIN
        INSERT INTO empower.empowered_profiles (
          user_id,
          connected_profile_id,
          legal_name,
          candidate_page_slug,
          empowered_at
        ) VALUES (
          p_user_id,
          p_connected_profile_id,
          p_legal_name,
          v_slug,
          now()
        )
        RETURNING * INTO v_result;

        -- INSERT succeeded — exit the loop
        EXIT;

      EXCEPTION WHEN unique_violation THEN
        v_attempts := v_attempts + 1;
        IF v_attempts >= 5 THEN
          -- 5 consecutive slug collisions — propagate to caller
          RAISE;
        END IF;
        -- Generate a new random suffix and rebuild the slug
        v_suffix := substring(md5(gen_random_uuid()::text) FROM 1 FOR 4);
        v_slug := rtrim(
          lower(regexp_replace(p_legal_name, '[^a-zA-Z0-9]+', '-', 'g')),
          '-'
        ) || '-' || v_suffix;
      END;
    END LOOP;

  END IF;

  -- -------------------------------------------------------------------------
  -- Common post-empowerment step (both paths): make compass data public.
  -- Runs atomically with the INSERT/UPDATE above.
  -- -------------------------------------------------------------------------
  UPDATE inform.compass_responses
    SET visibility = 'public',
        updated_at = now()
    WHERE user_id = p_user_id;

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  -- Re-raise the original exception; Postgres rolls back all changes in this block.
  RAISE;
END;
$$;


-- -----------------------------------------------------------------------------
-- 5. empower.execute_demotion (updated for Phase 5)
-- -----------------------------------------------------------------------------
-- Phase 5 changes from Phase 4 version (migration 017):
--   - New parameter: p_demotion_reason JSONB (shape: { lapsed_topic_ids,
--     lapsed_at, triggered_by: 'cron' | 'admin' })
--   - Sets demoted_at = now() alongside is_active = false
--   - compass_responses visibility => 'private' preserved from Phase 4.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION empower.execute_demotion(
  p_user_id        UUID,
  p_demotion_reason JSONB DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE empower.empowered_profiles
    SET
      is_active        = false,
      demoted_at       = now(),
      demotion_reason  = p_demotion_reason,
      updated_at       = now()
    WHERE user_id = p_user_id
      AND is_active = true;

  -- Phase 4: revoke public visibility on all compass responses after demotion.
  -- Runs atomically with the empowered_profiles UPDATE above.
  UPDATE inform.compass_responses
    SET visibility = 'private',
        updated_at = now()
    WHERE user_id = p_user_id;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;


COMMIT;
