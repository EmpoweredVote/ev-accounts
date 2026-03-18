-- Fix FK constraints on tables that reference public.users without proper
-- delete rules, causing user deletion to fail with FK violations.

-- invite_chains: invitee row should cascade (user gone = chain entry gone)
ALTER TABLE connect.invite_chains
  DROP CONSTRAINT IF EXISTS invite_chains_invitee_id_fkey,
  ADD CONSTRAINT invite_chains_invitee_id_fkey
    FOREIGN KEY (invitee_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- invite_chains: inviter row should also cascade (inviter gone = chain entries gone)
ALTER TABLE connect.invite_chains
  DROP CONSTRAINT IF EXISTS invite_chains_inviter_id_fkey,
  ADD CONSTRAINT invite_chains_inviter_id_fkey
    FOREIGN KEY (inviter_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- invite_codes: claimed_by / created_by → SET NULL (keep code record, lose user ref)
ALTER TABLE connect.invite_codes
  DROP CONSTRAINT IF EXISTS invite_codes_claimed_by_fkey,
  ADD CONSTRAINT invite_codes_claimed_by_fkey
    FOREIGN KEY (claimed_by) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE connect.invite_codes
  DROP CONSTRAINT IF EXISTS invite_codes_created_by_fkey,
  ADD CONSTRAINT invite_codes_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;

-- tier_promotion_log: SET NULL so audit history is preserved without the user ref
ALTER TABLE connect.tier_promotion_log
  DROP CONSTRAINT IF EXISTS tier_promotion_log_target_user_id_fkey,
  ADD CONSTRAINT tier_promotion_log_target_user_id_fkey
    FOREIGN KEY (target_user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE connect.tier_promotion_log
  DROP CONSTRAINT IF EXISTS tier_promotion_log_admin_id_fkey,
  ADD CONSTRAINT tier_promotion_log_admin_id_fkey
    FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;

-- notification_events: cascade (no point keeping notifications for deleted user)
ALTER TABLE public.notification_events
  DROP CONSTRAINT IF EXISTS notification_events_user_id_fkey,
  ADD CONSTRAINT notification_events_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
