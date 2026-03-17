-- Fix admin_audit_log.target_user_id FK to use ON DELETE SET NULL.
-- Preserves audit records when a user account is deleted — the log entry
-- shows the admin action happened, with target_user_id nulled out.
ALTER TABLE public.admin_audit_log
  DROP CONSTRAINT admin_audit_log_target_user_id_fkey;

ALTER TABLE public.admin_audit_log
  ADD CONSTRAINT admin_audit_log_target_user_id_fkey
  FOREIGN KEY (target_user_id)
  REFERENCES public.users(id)
  ON DELETE SET NULL;
