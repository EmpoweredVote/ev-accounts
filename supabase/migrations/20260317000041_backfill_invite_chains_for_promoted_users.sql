-- =============================================================================
-- Migration 041: Backfill invite_chains for admin-promoted alpha accounts
-- =============================================================================
-- Three users were promoted to Connected via the admin tool before migration 040
-- added the chain row to promote_to_connected. This backfills those rows so
-- candrews, chantrygilbert, and kppatel053 are linked to chris@empowered.vote
-- as their invite chain seed.
--
-- Uses ON CONFLICT (invitee_id) DO NOTHING — safe to re-run if needed.
-- =============================================================================

DO $$
DECLARE
  v_chris_id    UUID;
  v_user_id     UUID;
  v_email_prefix TEXT;
BEGIN

  -- Resolve Chris's user ID
  SELECT id INTO v_chris_id
    FROM auth.users
    WHERE email = 'chris@empowered.vote';

  IF v_chris_id IS NULL THEN
    RAISE EXCEPTION 'chris@empowered.vote not found in auth.users — check email spelling';
  END IF;

  -- Insert chain rows for each promoted user, looked up by email prefix
  FOREACH v_email_prefix IN ARRAY ARRAY['candrews', 'chantrygilbert', 'kppatel053']
  LOOP
    SELECT id INTO v_user_id
      FROM auth.users
      WHERE split_part(email, '@', 1) = v_email_prefix;

    IF v_user_id IS NULL THEN
      RAISE WARNING 'User with email prefix "%" not found — skipping', v_email_prefix;
      CONTINUE;
    END IF;

    INSERT INTO connect.invite_chains (inviter_id, invitee_id, invite_code_id)
      VALUES (v_chris_id, v_user_id, NULL)
      ON CONFLICT (invitee_id) DO NOTHING;

    RAISE NOTICE 'Linked % (%) → chris@empowered.vote', v_email_prefix, v_user_id;
  END LOOP;

END $$;
