BEGIN;

-- =============================================================================
-- CA_0110: restore authenticated's read of inform.seasons under RLS
-- =============================================================================
-- Steward slot CA_0110. Fixes the regression CA_0109 introduced on 2026-09-10.
--
-- 🔴 WHAT BROKE. CA_0109 enabled default-deny ROW LEVEL SECURITY on
-- inform.seasons with NO policy. RLS-on-with-no-policy denies every row to any
-- role that does not bypass RLS. The `authenticated` role does not bypass.
--
-- GET /api/compass/answers reads inform.compass_responses_effective, which reads
-- inform.compass_responses_current. Both views are `security_invoker = on`
-- (CC_0062, CC_0046), and compass_responses_current INNER JOINs inform.seasons
-- to order by season number. security_invoker means the CALLER's role must be
-- able to read every table the view touches. On the Supabase-token path
-- (lib/supabase.ts requestDb -> createUserClient), that caller is `authenticated`.
--
-- After CA_0109, `authenticated` sees zero rows in inform.seasons, so the inner
-- join drops every answer and GET /api/compass/answers returns [] with HTTP 200 —
-- a SILENT failure, not a 500, because RLS filters rows rather than erroring.
-- Result: signed-in users' compass answers still WRITE (POST uses adminRpc /
-- upsert_compass_answer, SECURITY DEFINER, which bypasses RLS) but cannot be READ
-- back or hydrated. The CompassV2 `smoke` job caught it on 2026-09-11
-- (authed-answer-reaches-server, authed-hydrates-server-answers).
--
-- This is the exact dependency CC_0048 documented on 2026-09-02, when the same
-- view first shipped: it granted SELECT on inform.seasons to `authenticated`
-- precisely so the security_invoker view would work, and it stated the invariant
-- "RLS on the table is off and STAYS off". CA_0109 turned RLS on and voided that
-- invariant. The GRANT from CC_0048 is still present; RLS default-deny now sits
-- on top of it and filters the rows to zero.
--
-- THE FIX. Keep RLS enabled — CA_0109's advisor goal and the founder decision
-- "protect them all" both hold — and add a SELECT policy so `authenticated` may
-- read the rows again. inform.seasons is non-sensitive metadata (number, name,
-- status, opened_at/closed_at, a public note), already public through
-- /api/compass/topics, so USING (true) exposes nothing new. This restores
-- exactly the pre-CA_0109 reach: authenticated may read; anon may not.
--
-- ⚠ anon IS DELIBERATELY NOT GIVEN A POLICY. Nothing anonymous reads the view.
-- service_role and ev_api need no policy — they bypass RLS (rolbypassrls = true)
-- and already hold the CC_0048 grant.
--
-- IDEMPOTENT: DROP POLICY IF EXISTS then CREATE. Safe to re-run.
--
-- REVERSAL: DROP POLICY IF EXISTS seasons_read_authenticated ON inform.seasons;
-- (which re-breaks the compass read path — do not, unless also disabling RLS).
-- =============================================================================

DROP POLICY IF EXISTS seasons_read_authenticated ON inform.seasons;
CREATE POLICY seasons_read_authenticated ON inform.seasons
  FOR SELECT
  TO authenticated
  USING (true);

-- =============================================================================
-- Post-verify gate — fail loudly if the fix is not exactly as intended.
-- =============================================================================
DO $$
BEGIN
  -- 1. RLS is STILL enabled on inform.seasons — CA_0109's protection is intact.
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'inform' AND c.relname = 'seasons' AND c.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'CA_0110: RLS is not enabled on inform.seasons — CA_0109 protection was lost';
  END IF;

  -- 2. The read policy exists, is SELECT-only, and targets exactly authenticated.
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'inform' AND tablename = 'seasons'
      AND policyname = 'seasons_read_authenticated'
      AND cmd = 'SELECT'
      AND roles = ARRAY['authenticated']::name[]
  ) THEN
    RAISE EXCEPTION 'CA_0110: seasons_read_authenticated is missing or not SELECT/authenticated-only';
  END IF;

  -- 3. No policy on inform.seasons reaches anon or public — the surface stays
  --    exactly two roles wider (authenticated) and no further.
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'inform' AND tablename = 'seasons'
      AND (roles && ARRAY['anon', 'public']::name[])
  ) THEN
    RAISE EXCEPTION 'CA_0110: a policy on inform.seasons reaches anon/public — wider than intended';
  END IF;

  RAISE NOTICE 'CA_0110 OK: authenticated may SELECT inform.seasons under RLS; anon/public cannot; RLS stays enabled.';
END $$;

COMMIT;
