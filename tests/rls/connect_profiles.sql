-- RLS Verification Tests: connect schema (connected_profiles + tolerance_rating masking)
--
-- Key tests:
--   2A: Non-owner can read connected_profiles existence via the public view
--   2B: Non-owner receives tolerance_rating ABSENT (column not on view) — not just NULL
--   2C: Owner reads own connected_profiles row and receives the REAL tolerance_rating value
--
-- Pattern: Each test block is a self-contained BEGIN/ROLLBACK transaction.
--
-- Usage: psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/rls/connect_profiles.sql

-- ============================================================
-- Test 1: Authenticated user can see their OWN connected_profiles row
-- ============================================================
-- Expected: owner sees their own full row from the base table.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name, tolerance_rating)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A', 7.50)
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate User A (the owner)
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM connect.connected_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 1 THEN
      RAISE EXCEPTION 'Test 1 FAILED: Owner should see their own connected_profiles row, got % rows', v_count;
    END IF;
    RAISE NOTICE 'Test 1 PASSED: Owner sees own connected_profiles row';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 2A: Non-owning authenticated user CAN read another user's
--          connected_profiles via the public view (existence is public)
-- ============================================================
-- Expected: User B sees User A's profile row via connected_profiles_public view.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated'),
      ('00000000-0000-0000-0000-000000000002', 'user-b@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'User A'),
      ('00000000-0000-0000-0000-000000000002', 'User B')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name, tolerance_rating)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A', 7.50)
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate User B (non-owner)
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    -- Non-owner must use the public view, not the base table
    SELECT count(*) INTO v_count
      FROM connect.connected_profiles_public
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 1 THEN
      RAISE EXCEPTION 'Test 2A FAILED: Non-owner should see connected_profiles existence via public view, got % rows', v_count;
    END IF;
    RAISE NOTICE 'Test 2A PASSED: Non-owner can see connected profile existence via connected_profiles_public view';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 2B: tolerance_rating column is ABSENT from connected_profiles_public view
-- ============================================================
-- Expected: tolerance_rating does not exist as a column on the public view.
-- The column absence (not just NULL) satisfies "tests must assert ABSENCE".
-- Seeding a real non-NULL value (7.50) ensures we are not testing a null storage case.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated'),
      ('00000000-0000-0000-0000-000000000002', 'user-b@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'User A'),
      ('00000000-0000-0000-0000-000000000002', 'User B')
  ON CONFLICT (id) DO NOTHING;

  -- Seed with a KNOWN non-NULL tolerance_rating (7.50) so we know the value exists
  INSERT INTO connect.connected_profiles (user_id, display_name, tolerance_rating)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A', 7.50)
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate User B (non-owner)
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  DO $$
  DECLARE
    v_col_count INTEGER;
  BEGIN
    -- Verify: tolerance_rating column does NOT exist on the public view
    -- This is a schema check, not a data check — the column is structurally absent.
    SELECT count(*) INTO v_col_count
      FROM information_schema.columns
      WHERE table_schema = 'connect'
        AND table_name   = 'connected_profiles_public'
        AND column_name  = 'tolerance_rating';
    IF v_col_count != 0 THEN
      RAISE EXCEPTION 'Test 2B FAILED: tolerance_rating should be ABSENT from connected_profiles_public view, but found % column(s)', v_col_count;
    END IF;
    RAISE NOTICE 'Test 2B PASSED: tolerance_rating column is absent from connected_profiles_public view (non-owner cannot access it)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 2C: Owner reads own connected_profiles base table and receives REAL tolerance_rating
-- ============================================================
-- Expected: the stored value 7.50 is returned to the owner from the base table.
-- Confirms masking only applies to non-owners; owner gets the real value.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name, tolerance_rating)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A', 7.50)
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate User A (the owner)
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}';

  DO $$
  DECLARE
    v_tolerance NUMERIC(4,2);
  BEGIN
    SELECT tolerance_rating INTO v_tolerance
      FROM connect.connected_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_tolerance IS NULL THEN
      RAISE EXCEPTION 'Test 2C FAILED: Owner should see real tolerance_rating (7.50), got NULL';
    END IF;
    IF v_tolerance != 7.50 THEN
      RAISE EXCEPTION 'Test 2C FAILED: Owner should see tolerance_rating = 7.50, got %', v_tolerance;
    END IF;
    RAISE NOTICE 'Test 2C PASSED: Owner sees real tolerance_rating value (%) from base table', v_tolerance;
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 3: Non-owner CANNOT read connected_profiles base table directly
-- ============================================================
-- Expected: User B gets 0 rows from connect.connected_profiles base table for User A.
-- Non-owners must use the public view; the base table policy is owner-only.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated'),
      ('00000000-0000-0000-0000-000000000002', 'user-b@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'User A'),
      ('00000000-0000-0000-0000-000000000002', 'User B')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name, tolerance_rating)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A', 7.50)
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate User B
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM connect.connected_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 3 FAILED: Non-owner should get 0 rows from base table, got %', v_count;
    END IF;
    RAISE NOTICE 'Test 3 PASSED: Non-owner cannot read base connected_profiles table directly';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 4: Anon user CANNOT read connected_profiles (neither base table nor public view)
-- ============================================================
-- Expected: anon gets 0 rows (no anon policy on either table or view).
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A')
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate anon
  SET LOCAL role TO anon;
  SET LOCAL "request.jwt.claims" TO '{"role": "anon"}';

  DO $$
  DECLARE
    v_count_base INTEGER;
    v_count_view INTEGER;
  BEGIN
    -- Base table: anon has GRANT SELECT but no RLS policy → 0 rows
    SELECT count(*) INTO v_count_base FROM connect.connected_profiles;
    IF v_count_base != 0 THEN
      RAISE EXCEPTION 'Test 4 FAILED: Anon should see 0 rows on base table, got %', v_count_base;
    END IF;

    -- View: authenticated-only (no GRANT to anon). Permission denied is acceptable.
    BEGIN
      SELECT count(*) INTO v_count_view FROM connect.connected_profiles_public;
      IF v_count_view != 0 THEN
        RAISE EXCEPTION 'Test 4 FAILED: Anon should see 0 rows on public view, got %', v_count_view;
      END IF;
    EXCEPTION WHEN insufficient_privilege THEN
      NULL; -- permission denied on view is correct: view is authenticated-only
    END;

    RAISE NOTICE 'Test 4 PASSED: Anon cannot read connected_profiles (base table or public view)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 5: Soft-deleted profile (deleted_at IS NOT NULL) is NOT visible
-- ============================================================
-- Expected: a profile with deleted_at set returns 0 rows from the public view.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated'),
      ('00000000-0000-0000-0000-000000000002', 'user-b@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'User A'),
      ('00000000-0000-0000-0000-000000000002', 'User B')
  ON CONFLICT (id) DO NOTHING;

  -- Seed: User A's profile is soft-deleted
  INSERT INTO connect.connected_profiles (user_id, display_name, deleted_at)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A', now())
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate User B (non-owner)
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM connect.connected_profiles_public
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 5 FAILED: Soft-deleted profile should return 0 rows, got %', v_count;
    END IF;
    RAISE NOTICE 'Test 5 PASSED: Soft-deleted profile is not visible via public view';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 6: Verification sessions are only visible to the owning user
-- ============================================================
-- Expected: User B gets 0 rows for User A's verification session.
-- Owner (User A) gets 1 row for their own session.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated'),
      ('00000000-0000-0000-0000-000000000002', 'user-b@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'User A'),
      ('00000000-0000-0000-0000-000000000002', 'User B')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.verification_sessions (user_id, step_reached, display_name_draft)
    VALUES ('00000000-0000-0000-0000-000000000001', 'name', 'User A Public Name');

  -- Test 6a: Non-owner (User B) cannot see User A's session
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM connect.verification_sessions
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 6a FAILED: Non-owner should not see verification session, got % rows', v_count;
    END IF;
    RAISE NOTICE 'Test 6a PASSED: Non-owner cannot read verification sessions of another user';
  END;
  $$;

  -- Reset role and test owner access
  RESET role;
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM connect.verification_sessions
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 1 THEN
      RAISE EXCEPTION 'Test 6b FAILED: Owner should see their own verification session, got % rows', v_count;
    END IF;
    RAISE NOTICE 'Test 6b PASSED: Owner can read their own verification session';
  END;
  $$;

ROLLBACK;
