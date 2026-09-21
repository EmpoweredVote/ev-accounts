-- CA_0120 — Seal parity for the /complete enrollment path (spec §4.4, final-review fix wave).
--
-- Only routes/auth.ts's signup_with_invite path sealed the Connect legal_name today.
-- routes/connect.ts's POST /complete calls this RPC directly and INSERTs
-- v_session.legal_name_draft into connect.connected_profiles.legal_name verbatim, so a
-- member enrolling via /complete got a PLAINTEXT name written even with the vault enabled.
--
-- Fix: add a trailing defaulted p_seal_name param. The route seals the draft name into
-- id_vault (via upsertSeal) BEFORE calling this RPC when isVaultEnabled(), then passes
-- p_seal_name = true so the INSERT writes NULL for legal_name instead of the plaintext
-- draft — mirroring the seal-first-then-NULL pattern signup_with_invite already uses.
-- p_seal_name defaults to false, so any caller still on the 1-arg signature is unaffected
-- until Postgres resolves it to this 2-arg overload with the default applied — same
-- behaviour as before this migration.
--
-- Postgres treats a 2-arg call as a DIFFERENT function from the 1-arg one, so the old
-- single-arg function is dropped first; CREATE OR REPLACE then defines the 2-arg version
-- in its place. Everything else in the body is copied byte-for-byte from
-- migrations/060_drop_home_address.sql (the current live definition) — only the
-- `legal_name` value in the INSERT changes.
BEGIN;

DROP FUNCTION IF EXISTS public.complete_connect_flow(uuid);

CREATE OR REPLACE FUNCTION public.complete_connect_flow(p_user_id uuid, p_seal_name boolean DEFAULT false)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_session connect.verification_sessions;
BEGIN
  -- Lock the verification_session row for this transaction
  SELECT * INTO v_session
  FROM connect.verification_sessions
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SESSION';
  END IF;

  IF v_session.step_reached != 'review' THEN
    RAISE EXCEPTION 'INCOMPLETE_SESSION';
  END IF;

  IF v_session.display_name_draft IS NULL
     OR v_session.legal_name_draft IS NULL
     OR v_session.region_draft IS NULL
     OR v_session.home_address_draft IS NULL
  THEN
    RAISE EXCEPTION 'MISSING_REQUIRED_FIELDS';
  END IF;

  -- Idempotency check
  IF EXISTS (SELECT 1 FROM connect.connected_profiles WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'ALREADY_CONNECTED';
  END IF;

  -- Create connected_profiles record (home_address intentionally excluded, per 060).
  -- legal_name is NULLed when the caller has already sealed it into id_vault
  -- (p_seal_name = true); otherwise the draft is written as before.
  INSERT INTO connect.connected_profiles
    (user_id, display_name, legal_name, account_standing, verification_status, tolerance_rating, verified_region)
  VALUES
    (p_user_id, v_session.display_name_draft,
     CASE WHEN p_seal_name THEN NULL ELSE v_session.legal_name_draft END,
     'active', 'verified', 10.00, v_session.region_draft);

  -- Advance session to complete
  UPDATE connect.verification_sessions
  SET step_reached = 'complete', updated_at = now()
  WHERE user_id = p_user_id;

  -- Sync display_name to public.users
  UPDATE public.users
  SET display_name = v_session.display_name_draft, updated_at = now()
  WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'connected', true,
    'verification_status', 'verified',
    'tier', 'connected'
  );
END;
$$;

-- Reproduce the original restrictive ACL: service_role only (adminRpc calls this),
-- never PUBLIC. A fresh CREATE re-grants PUBLIC EXECUTE by the built-in default, which
-- would expose this SECURITY DEFINER function to anon/authenticated via PostgREST.
REVOKE ALL ON FUNCTION public.complete_connect_flow(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_connect_flow(uuid, boolean) TO service_role;

-- Post-verify gate: the 2-arg overload exists (p_user_id uuid, p_seal_name boolean,
-- exactly one defaulted argument, matching names), and the 1-arg overload is gone so
-- every caller resolves to this one. to_regprocedure resolves an exact signature to
-- its OID (or NULL) — more robust than comparing pg_get_function_arguments' formatted
-- text, which can vary across Postgres versions.
DO $$
DECLARE
  v_two_arg_oid regprocedure;
  v_pronargdefaults int;
  v_proargnames text[];
BEGIN
  v_two_arg_oid := to_regprocedure('public.complete_connect_flow(uuid, boolean)');
  IF v_two_arg_oid IS NULL THEN
    RAISE EXCEPTION 'public.complete_connect_flow(uuid, boolean) not found after migration';
  END IF;

  SELECT p.pronargdefaults, p.proargnames
    INTO v_pronargdefaults, v_proargnames
    FROM pg_proc p
    WHERE p.oid = v_two_arg_oid::oid;

  IF v_pronargdefaults <> 1 THEN
    RAISE EXCEPTION 'public.complete_connect_flow(uuid, boolean) must have exactly one defaulted arg, found %', v_pronargdefaults;
  END IF;

  IF v_proargnames <> ARRAY['p_user_id', 'p_seal_name'] THEN
    RAISE EXCEPTION 'public.complete_connect_flow(uuid, boolean) arg names must be (p_user_id, p_seal_name), found %', v_proargnames;
  END IF;

  IF to_regprocedure('public.complete_connect_flow(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'public.complete_connect_flow(uuid) 1-arg overload still present after DROP';
  END IF;

  IF has_function_privilege('public', 'public.complete_connect_flow(uuid, boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'complete_connect_flow must not be EXECUTE-able by PUBLIC';
  END IF;
  IF NOT has_function_privilege('service_role', 'public.complete_connect_flow(uuid, boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'service_role must have EXECUTE on complete_connect_flow';
  END IF;
END $$;

COMMIT;
