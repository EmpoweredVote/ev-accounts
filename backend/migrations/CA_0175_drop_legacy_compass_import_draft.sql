BEGIN;

-- =============================================================================
-- CA_0175: drop the dead legacy compass import draft
-- =============================================================================
-- Created 2026-09-23 with Chris Andrews. Slot allocated by the steward.
--
-- PR #636 removed the legacy stance_id branch of POST /api/connect/compass-import.
-- That branch was the ONLY writer of connect.verification_sessions.
-- compass_import_draft (supabase/migrations/20260225000014), and GET
-- /compass/answers was the only caller of public.promote_compass_import_draft
-- (last redefined in CC_0046), which moved such a draft into compass_responses.
-- Both callers are gone, so both objects are dead:
--
--   · public.promote_compass_import_draft(uuid) — SECURITY DEFINER, EXECUTE
--     granted to postgres + service_role only.
--   · connect.verification_sessions.compass_import_draft jsonb.
--
-- Measured on prod 2026-09-23 (read-only), before writing this:
--   · 0 verification_sessions rows, so 0 drafts — nothing is lost.
--   · no other function body, view, matview, RLS policy, trigger, pg_depend
--     entry or pg_cron job names either object (control: the body scan finds
--     the RPC itself, so it is not blind).
--   · 0 requests to /api/connect/compass-import in the Render logs retained
--     that day (2026-09-09 onward); no client in the workspace calls it.
--
-- 🔴 IT REFUSES TO DROP A DRAFT. The pre-check below raises if any row holds a
-- compass_import_draft: that would be a calibration nobody has promoted yet,
-- and with the promoter gone it could never be. Promote or discard it first.
--
-- No CASCADE on either DROP, on purpose: if something unexpected depends on
-- them, the statement fails and the whole migration rolls back.
--
-- Idempotent: every step is IF EXISTS, and the pre-check skips once the column
-- is gone. Dry-run first: replace the final COMMIT with ROLLBACK.
-- =============================================================================

DO $$
DECLARE
  v_drafts int;
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'connect' AND table_name = 'verification_sessions'
       AND column_name = 'compass_import_draft'
  ) THEN
    EXECUTE 'SELECT count(*) FROM connect.verification_sessions WHERE compass_import_draft IS NOT NULL'
       INTO v_drafts;
    IF v_drafts > 0 THEN
      RAISE EXCEPTION 'CA_0175: % verification session(s) still hold a compass_import_draft — promote or discard them before dropping the column', v_drafts;
    END IF;
  END IF;
END $$;

DROP FUNCTION IF EXISTS public.promote_compass_import_draft(uuid);

ALTER TABLE connect.verification_sessions DROP COLUMN IF EXISTS compass_import_draft;


-- -----------------------------------------------------------------------------
-- Post-verify
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_n int;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'promote_compass_import_draft') THEN
    RAISE EXCEPTION 'CA_0175: a promote_compass_import_draft overload still exists';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'connect' AND table_name = 'verification_sessions'
       AND column_name = 'compass_import_draft'
  ) THEN
    RAISE EXCEPTION 'CA_0175: connect.verification_sessions.compass_import_draft still exists';
  END IF;

  -- Nothing left may name either object: a surviving body would fail with
  -- 42703/42883 the first time it ran.
  SELECT count(*) INTO v_n
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE p.prokind IN ('f', 'p')
     AND n.nspname NOT IN ('pg_catalog', 'information_schema')
     AND pg_get_functiondef(p.oid) ~ '(compass_import_draft|promote_compass_import_draft)';
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CA_0175: % function(s) still name the dropped draft or its promoter', v_n;
  END IF;

  -- The live import path is untouched.
  IF to_regprocedure('public.import_compass_calibrations(uuid,jsonb,boolean)') IS NULL THEN
    RAISE EXCEPTION 'CA_0175: import_compass_calibrations is missing — the live import path must survive';
  END IF;

  RAISE NOTICE 'CA_0175 OK: promote_compass_import_draft and verification_sessions.compass_import_draft dropped; nothing references them; the live import RPC is intact.';
END $$;

COMMIT;
