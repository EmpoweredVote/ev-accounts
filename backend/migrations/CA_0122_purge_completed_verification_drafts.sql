-- CA_0122 — Retroactive purge of identity drafts on COMPLETED verification sessions.
--
-- Companion to CA_0121 (which stops NEW completions retaining drafts). This
-- clears the plaintext name + raw address already sitting on sessions that
-- completed before that fix. Scope is step_reached = 'complete' ONLY: in-progress
-- sessions (invite/profile/review) must keep their drafts so the member can resume.
--
-- Plain purge, no seal: Phase A has no production id_vault key, and those addresses
-- were never vaulted and are unrecoverable elsewhere (060 dropped the column; the
-- §4.7 name backfill does not cover addresses). This completes what
-- docs/PRIVACY-DATA-MODEL.md §5 always intended. Needs no key — safe to apply now.
-- Idempotent: a re-run matches zero rows.
BEGIN;

UPDATE connect.verification_sessions
SET legal_name_draft   = NULL,
    home_address_draft = NULL,
    updated_at         = now()
WHERE step_reached = 'complete'
  AND (legal_name_draft IS NOT NULL OR home_address_draft IS NOT NULL);

-- Post-verify gate: zero completed sessions may still carry an identity draft.
DO $$
DECLARE
  v_leftover int;
BEGIN
  SELECT count(*) INTO v_leftover
  FROM connect.verification_sessions
  WHERE step_reached = 'complete'
    AND (legal_name_draft IS NOT NULL OR home_address_draft IS NOT NULL);
  IF v_leftover <> 0 THEN
    RAISE EXCEPTION 'CA_0122: % completed verification_sessions still carry identity drafts', v_leftover;
  END IF;
END $$;

COMMIT;
