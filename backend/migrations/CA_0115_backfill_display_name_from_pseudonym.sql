BEGIN;

-- =============================================================================
-- CA_0115: backfill null/empty public.users.display_name from the Connected pseudonym
-- =============================================================================
-- Created 2026-09-13 with Chris Andrews. ev-cto watchlist #70.
--
-- WHY
-- getAccountMe returned a null base name for 3 Connected users whose chosen pseudonym
-- (chantrygilbert / Explorer / TESTING-Info-ev) lives only in connect.connected_profiles.
-- The folded Civic Spaces assigner writes that null into the NOT NULL
-- civic_spaces.connected_profiles.display_name and 500s on /assign. For the other 9
-- Connected users the base name already equals the pseudonym; these 3 are the rows where
-- the base name was left null by the WorkOS/older path. Restore the invariant.
--
-- A user with no pseudonym anywhere (none today) is left null and covered by the runtime
-- guard added alongside this migration (lib/displayName.ts); SQL does not own the word
-- lists, so it mints no auto-names here.
--
-- No migration runner (see CLAUDE.md): applied once, ad hoc. Idempotent — safe to re-run.
-- =============================================================================

UPDATE public.users u
   SET display_name = btrim(cp.display_name),
       updated_at   = now()
  FROM connect.connected_profiles cp
 WHERE cp.user_id = u.id
   AND (u.display_name IS NULL OR btrim(u.display_name) = '')
   AND cp.display_name IS NOT NULL
   AND btrim(cp.display_name) <> '';

-- Post-verify gate: no Connected user may keep a null/empty base name while a usable
-- pseudonym exists.
DO $$
DECLARE
  remaining int;
BEGIN
  SELECT count(*) INTO remaining
    FROM connect.connected_profiles cp
    JOIN public.users u ON u.id = cp.user_id
   WHERE (u.display_name IS NULL OR btrim(u.display_name) = '')
     AND cp.display_name IS NOT NULL
     AND btrim(cp.display_name) <> '';
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'CA_0115 backfill incomplete: % Connected users still lack a base name but have a pseudonym', remaining;
  END IF;
END $$;

COMMIT;
