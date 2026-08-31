-- 1850_compass_topics_on_inform_profiles.sql
-- Move the user's compass (which 8 topics they chose) off a Connected-tier table.
--
-- THE PROBLEM, STATED PLAINLY. A user's compass ANSWERS live in
-- inform.compass_responses, which every authenticated user can write to. Their
-- SELECTION — which questions those answers are about — lived in
-- connect.connected_profiles.selected_topic_ids, which only Connected-tier users
-- have a row in. `Profile absence = Inform tier` (middleware/auth.ts), so an
-- Inform user could answer questions all day and never keep their compass.
--
-- That was invisible for three months because PUT /compass/selected-topics
-- answered 200 [] when the UPDATE matched no rows (fixed in #225, which now
-- answers 409). Measured 2026-08-29: 9 of 23 accounts had no connected profile,
-- and 2 of those had already answered 34 and 20 questions respectively.
--
-- It is not a regression. Before Inform accounts existed every signup needed an
-- invite code and went through Connect, so every user had a profile and the
-- storage choice was invisible. Inform accounts removed the invite requirement;
-- the compass became reachable by users the storage could not serve.
--
-- 🔴 THE FIX IS NOT TO CREATE A connected_profiles ROW. That row IS the tier
-- marker, written by POST /connect/complete beside tier_promotion_log. Creating
-- one to make a compass save would hand out invite-gated Connected tier as a
-- side effect. The storage moves instead.
--
-- inform.inform_profiles is the right home: migration 084 gives it a trigger that
-- creates a row for every new user plus a backfill, so it covers 23/23 accounts
-- today and every future one. It is also in the same schema as the answers it
-- belongs with.
--
-- The old column is deliberately NOT dropped. Nothing reads it after this
-- change, but leaving it makes the cutover reversible for a release. Drop it in a
-- later migration once this has been live long enough to trust.

-- 1. The new home.
alter table inform.inform_profiles
  add column if not exists selected_topic_ids jsonb not null default '[]'::jsonb;

-- 2. Carry existing selections across. Only touches rows that have something to
--    copy and nothing to lose, so it is safe to re-run.
update inform.inform_profiles ip
   set selected_topic_ids = cp.selected_topic_ids
  from connect.connected_profiles cp
 where cp.user_id = ip.user_id
   and cp.deleted_at is null
   and jsonb_typeof(coalesce(cp.selected_topic_ids, '[]'::jsonb)) = 'array'
   and jsonb_array_length(coalesce(cp.selected_topic_ids, '[]'::jsonb)) > 0
   and jsonb_array_length(ip.selected_topic_ids) = 0;

-- 3. Reset must clear the new home too.
--
-- Step 2 of the original cleared connect.connected_profiles. Left alone, a user
-- who reset their compass would have their answers soft-deleted while their topic
-- selection survived in the new column — a reset that visibly did not reset.
-- Both are cleared during the transition; the connect clause goes when the column
-- is dropped.
create or replace function public.reset_compass_answers(p_user_id uuid, p_full_reset boolean default false)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
BEGIN

  -- Step 1: Soft-delete all active compass responses for this user.
  -- NULL deleted_at = active row; we set it to now() to mark as deleted.
  -- Hard deletes are not used — preserves data for recovery and audit.
  UPDATE inform.compass_responses
    SET deleted_at = now()
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;

  -- Step 2: Clear the user's selected topic IDs.
  -- Resetting answers makes any prior topic selection stale.
  --
  -- inform_profiles is the source of truth as of migration 1850. Every user has
  -- a row (migration 084's trigger), so this is the clause that actually runs for
  -- an Inform-tier user.
  UPDATE inform.inform_profiles
    SET selected_topic_ids = '[]'::jsonb
    WHERE user_id = p_user_id;

  -- Transitional: the legacy column is no longer read, but it is still written
  -- here so a rollback to the previous release does not resurrect a stale
  -- compass. Remove together with the column.
  UPDATE connect.connected_profiles
    SET selected_topic_ids = '[]'::jsonb,
        updated_at         = now()
    WHERE user_id = p_user_id;

  -- Step 3: (optional) Reset onboarding flag so the user goes through the
  -- onboarding flow again on next login. Only triggered for full resets
  -- (e.g. admin-initiated or user-requested clean slate).
  IF p_full_reset THEN
    UPDATE connect.connected_profiles
      SET completed_onboarding = false,
          updated_at            = now()
      WHERE user_id = p_user_id;
  END IF;

EXCEPTION WHEN OTHERS THEN
  RAISE;

END;
$function$;
