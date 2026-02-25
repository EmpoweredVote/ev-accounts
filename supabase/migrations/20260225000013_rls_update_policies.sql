BEGIN;

-- public.users: owner can update display_name and avatar_url
CREATE POLICY "users: owner update"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = id AND deleted_at IS NULL)
  WITH CHECK ((select auth.uid()) = id AND deleted_at IS NULL);

GRANT UPDATE (display_name, avatar_url, updated_at) ON public.users TO authenticated;

-- connect.connected_profiles: owner can update display_name only
CREATE POLICY "connected_profiles: owner update"
  ON connect.connected_profiles
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id AND deleted_at IS NULL)
  WITH CHECK ((select auth.uid()) = user_id AND deleted_at IS NULL);

GRANT UPDATE (display_name, updated_at) ON connect.connected_profiles TO authenticated;

COMMIT;
