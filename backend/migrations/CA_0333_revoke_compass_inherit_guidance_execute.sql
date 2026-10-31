-- CA_0333: revoke public EXECUTE on inform.compass_revision_inherit_guidance()
--
-- CC_0231 created this SECURITY DEFINER trigger function with the default
-- PUBLIC EXECUTE grant. It is the only SECURITY DEFINER trigger function in the
-- project still open that way: the other seven (connect.log_post_edit,
-- civic_spaces.notify_on_reply, inform.handle_new_user, ...) are already revoked.
--
-- Not an exposure: Postgres refuses a direct call of a trigger function and
-- PostgREST does not offer trigger functions as /rpc endpoints. But the Supabase
-- advisor (0028/0029, "SECURITY DEFINER function executable") flags it anyway,
-- and a warning that is always there and means nothing teaches people to ignore
-- that warning. Measured 2026-10-26: advisor 0028 count 6, this function the
-- only one added since the accepted 5.
--
-- Postgres checks EXECUTE when a trigger is CREATED, not when it fires, so the
-- compass_revision_inherit_guidance trigger on inform.compass_topic_revisions
-- keeps filling NEW.guidance. Verified on prod in a rolled-back transaction
-- before applying.
--
-- ⚠ Dropping and re-creating the function restores the PUBLIC grant. A plain
-- CREATE OR REPLACE keeps this revoke.

REVOKE EXECUTE ON FUNCTION inform.compass_revision_inherit_guidance() FROM PUBLIC, anon, authenticated;

DO $$
BEGIN
  IF has_function_privilege('anon', 'inform.compass_revision_inherit_guidance()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'inform.compass_revision_inherit_guidance()', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0333: inform.compass_revision_inherit_guidance() is still executable by anon or authenticated';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger
                  WHERE tgname = 'compass_revision_inherit_guidance'
                    AND tgrelid = 'inform.compass_topic_revisions'::regclass
                    AND tgenabled <> 'D') THEN
    RAISE EXCEPTION 'CA_0333: the compass_revision_inherit_guidance trigger is missing or disabled';
  END IF;
END $$;
