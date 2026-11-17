-- CA_0388 — record: public.roles 'listening_moderator' required_tier empowered -> connected
--
-- RECORDS A CHANGE ALREADY MADE IN PRODUCTION. On 2026-11-17 production was changed by hand:
--
--   UPDATE public.roles SET required_tier = 'connected' WHERE slug = 'listening_moderator';
--
-- OLD VALUE (overwritten): required_tier = 'empowered'.
-- NEW VALUE:               required_tier = 'connected'.
-- Verified in production 2026-11-17 before this file was written: the row already reads
-- 'connected', so applying this file there is a no-op (the UPDATE matches zero rows).
--
-- Why: Empowered Listening's moderator gate could not see the role (it read the token, and
-- WorkOS tokens never carry Supabase app_metadata; ev-cto decision 0041 moves role checks to
-- the database). Two moderators were then granted listening_moderator through grant_role, which
-- refuses a role whose required_tier the grantee has not reached — and the Empowered tier does
-- not exist for anyone yet. Lowering the tier to 'connected' is what let those grants through.
--
-- ⚠ TEMPORARY. Revisit when the Empowered tier is live (ev-cto watchlist #98).
-- ⚠ required_tier gates grant_role ONLY. It is checked when a role is granted, never when a
--   held role is read, so raising it back to 'empowered' later will NOT revoke anyone who
--   already holds listening_moderator. Revoke explicitly if that is the intent.
--
-- The listening_moderator row itself was created outside the repo (no migration inserts it).
-- This file does not create it: on a database without the row it is a no-op and says so.
--
-- Idempotent: guarded UPDATE. Post-verify gate below.

BEGIN;

UPDATE public.roles
   SET required_tier = 'connected'
 WHERE slug = 'listening_moderator'
   AND required_tier IS DISTINCT FROM 'connected';

DO $$
DECLARE
  v_tier text;
  v_found boolean;
BEGIN
  SELECT required_tier, true INTO v_tier, v_found
    FROM public.roles
   WHERE slug = 'listening_moderator';

  IF v_found IS NULL THEN
    RAISE NOTICE 'CA_0388: no listening_moderator role on this database; nothing to record';
  ELSIF v_tier IS DISTINCT FROM 'connected' THEN
    RAISE EXCEPTION 'CA_0388: listening_moderator required_tier is %, expected connected', v_tier;
  END IF;
END $$;

COMMIT;
