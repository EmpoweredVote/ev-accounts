-- CA_0121 — complete_connect_flow nulls verification_sessions identity drafts.
--
-- Follow-up to the identity-vault review (spec
-- docs/superpowers/specs/2026-09-17-verification-sessions-draft-purge-design.md).
-- Before this, complete_connect_flow marked the session complete but LEFT
-- legal_name_draft and home_address_draft in place — a plaintext name + raw
-- address readable by the BYPASSRLS ev_api role. The /complete route now seals
-- both into id_vault first (when the vault is enabled); this RPC nulls both
-- drafts in the SAME UPDATE that advances step_reached, atomically with profile
-- creation. Supersedes migration 060's "home_address_draft ... intentionally NOT
-- removed here" comment.
--
-- Body is copied byte-for-byte from CA_0120_complete_connect_flow_seal_parity.sql
-- (the current live definition); the only changes are the two NULL assignments
-- in the "advance session to complete" UPDATE and its preceding comment.
-- Signature, p_seal_name CASE, ACL and post-verify gate are unchanged.
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

  -- Advance session to complete AND purge the transient identity drafts.
  -- v_session captured them above (SELECT INTO), so the INSERT still had them;
  -- nulling here is atomic with profile creation. This is the whole point of the
  -- migration.
  UPDATE connect.verification_sessions
  SET step_reached       = 'complete',
      legal_name_draft   = NULL,
      home_address_draft = NULL,
      updated_at         = now()
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
