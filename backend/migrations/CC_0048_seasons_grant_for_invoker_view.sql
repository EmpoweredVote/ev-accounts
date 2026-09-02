BEGIN;

-- =============================================================================
-- CC_0048: grant SELECT on inform.seasons so the season-collapse view works
-- =============================================================================
-- HOTFIX, applied to prod 2026-09-02 within minutes of the CC_0046 deploy going
-- live. Written up here after the fact; the grant is already in place. This file
-- is the record and makes the change reproducible in another environment.
--
-- 🔴 WHAT BROKE. CC_0046 pointed GET /compass/answers at
-- inform.compass_responses_current, which is `security_invoker = on`. That flag
-- is what keeps the base table's owner-only RLS applying to the caller — it is
-- not optional, and without it the view would have served every authenticated
-- caller every user's answers.
--
-- But security_invoker cuts both ways: the CALLER's role must hold SELECT on
-- EVERY table the view touches, not just the one it is about. The view joins
-- inform.seasons to order by season number, and `authenticated` had no grant on
-- inform.seasons. Result, for every signed-in user:
--
--     42501: permission denied for table seasons
--     GET /api/compass/answers -> 500
--
-- ⚠ THE SMOKE SUITE COULD NOT HAVE CAUGHT THIS, and that is the lesson. It ran
-- green immediately before the deploy — against the NEW schema but the OLD code,
-- which still read the base table. The failure needed both halves live at once.
-- A migration that is safe on its own plus code that is safe on its own can
-- still break on contact. What caught it was hitting the deployed endpoint as a
-- real authenticated user afterwards.
--
-- WHY THIS GRANT IS SAFE. inform.seasons is non-sensitive metadata: number,
-- name, status, opened_at/closed_at, and a public-facing note ("Season 2 is
-- adding a few new topics..."). Every season-derived field it feeds is already
-- public through /compass/topics. RLS on the table is off and STAYS off; what
-- changes is only that the table becomes readable, to two roles, SELECT only.
--
-- ⚠ anon IS DELIBERATELY NOT GRANTED. Nothing anonymous reads the view, and the
-- inform-schema audit convention here is that RLS-off tables stay unreachable
-- rather than policy-protected — so the surface widens by exactly the two roles
-- that demonstrably need it and no further.
--
-- service_role needs it for the same reason as authenticated: candidateService
-- and profileService reach the view through supabaseAdmin, and security_invoker
-- means bypassing RLS does not substitute for holding the grant.
-- =============================================================================

GRANT SELECT ON inform.seasons TO authenticated;
GRANT SELECT ON inform.seasons TO service_role;

DO $$
DECLARE
  v_missing text;
BEGIN
  SELECT string_agg(r.role, ', ')
    INTO v_missing
    FROM (VALUES ('authenticated'), ('service_role')) AS r(role)
   WHERE NOT EXISTS (
     SELECT 1 FROM information_schema.role_table_grants g
      WHERE g.table_schema = 'inform'
        AND g.table_name  = 'seasons'
        AND g.grantee     = r.role
        AND g.privilege_type = 'SELECT'
   );

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION
      'CC_0048: % still lack SELECT on inform.seasons — compass_responses_current will 42501 for them',
      v_missing;
  END IF;

  -- anon must NOT have picked it up.
  IF EXISTS (
    SELECT 1 FROM information_schema.role_table_grants
     WHERE table_schema = 'inform' AND table_name = 'seasons' AND grantee = 'anon'
  ) THEN
    RAISE EXCEPTION 'CC_0048: anon has a grant on inform.seasons — wider than intended';
  END IF;

  RAISE NOTICE 'CC_0048 OK: authenticated + service_role can read inform.seasons; anon cannot.';
END $$;

COMMIT;
