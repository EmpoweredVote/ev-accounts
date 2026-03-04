BEGIN;

-- Migration 028: Grant UPDATE on selected_topic_ids to authenticated role
--
-- The existing owner-update RLS policy on connect.connected_profiles allows
-- owners to update their own row. However, the column-level GRANT from migration
-- 013 only covers (display_name, updated_at).
--
-- Routes that save a user's selected compass topics need to update selected_topic_ids
-- via createUserClient (RLS-enforced, no service role needed). This grant enables
-- that without widening the RLS policy or granting access to sensitive columns
-- (tolerance_rating, verification_status, etc. remain ungranted).

GRANT UPDATE (selected_topic_ids) ON connect.connected_profiles TO authenticated;

COMMIT;
