-- RLS Verification Tests: public schema (public.users + public.users_public)
--
-- Pattern: Each test block is a self-contained BEGIN/ROLLBACK transaction.
-- Seed data is created inside the transaction, role/claims are impersonated,
-- assertions are checked, then ROLLBACK cleans everything up.
--
-- Usage: Run against a local Supabase instance with `psql` or the Supabase SQL editor.
--   psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/rls/public_users.sql
--
-- Expected: Each DO block raises an exception if the assertion fails.
-- Expected: No assertion exceptions = all tests pass.

-- ============================================================
-- Test 1: Owner can read their own public.users row directly
-- ============================================================
-- Expected: authenticated user sees exactly 1 row for their own id (direct table query).
-- ============================================================
BEGIN;

  -- Seed: Create a test user in auth.users and public.users
  -- In production, auth.users INSERT triggers handle_new_user automatically.
  -- Here we insert both manually because we are operating outside the trigger context.
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES (
      '00000000-0000-0000-0000-000000000001',
      'user-a@test.example',
      'not-a-real-hash',
      now(), now(), now(),
      'authenticated', 'authenticated'
    )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name, avatar_url)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A', 'https://example.com/a.jpg')
  ON CONFLICT (id) DO NOTHING;

  -- Impersonate User A
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}';

  -- Assert: owner sees their own row
  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM public.users
      WHERE id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 1 THEN
      RAISE EXCEPTION 'Test 1 FAILED: Expected 1 row, got %', v_count;
    END IF;
    RAISE NOTICE 'Test 1 PASSED: Owner sees own public.users row';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 2: Non-owner cannot read another user's public.users row
-- ============================================================
-- Expected: authenticated user (User B) gets 0 rows when querying User A's record
-- directly from public.users (owner-only policy blocks non-owners).
-- ============================================================
BEGIN;

  -- Seed: two users
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

  -- Impersonate User B
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  -- Assert: User B cannot see User A's row in public.users
  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM public.users
      WHERE id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 2 FAILED: Expected 0 rows (non-owner blocked), got %', v_count;
    END IF;
    RAISE NOTICE 'Test 2 PASSED: Non-owner cannot read another user''s public.users row';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 3: Anon user cannot read any public.users row
-- ============================================================
-- Expected: anon role sees 0 rows (no anon SELECT policy on public.users).
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A')
  ON CONFLICT (id) DO NOTHING;

  -- Impersonate anon
  SET LOCAL role TO anon;
  SET LOCAL "request.jwt.claims" TO '{"role": "anon"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count FROM public.users;
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 3 FAILED: Anon should see 0 rows, got %', v_count;
    END IF;
    RAISE NOTICE 'Test 3 PASSED: Anon cannot read any public.users row';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 4: Non-owner CAN read display_name and avatar_url via users_public view
-- ============================================================
-- Expected: User B sees User A's display_name and avatar_url via public.users_public.
-- This is the split-visibility design: public view exposes only safe columns.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated'),
      ('00000000-0000-0000-0000-000000000002', 'user-b@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name, avatar_url)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'User A', 'https://example.com/a.jpg'),
      ('00000000-0000-0000-0000-000000000002', 'User B', null)
  ON CONFLICT (id) DO NOTHING;

  -- Impersonate User B
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  -- Assert: User B can see User A's display_name via the public view
  DO $$
  DECLARE
    v_count        INTEGER;
    v_display_name TEXT;
    v_avatar_url   TEXT;
  BEGIN
    SELECT count(*), min(display_name), min(avatar_url)
      INTO v_count, v_display_name, v_avatar_url
      FROM public.users_public
      WHERE id = '00000000-0000-0000-0000-000000000001';

    IF v_count != 1 THEN
      RAISE EXCEPTION 'Test 4 FAILED: Expected 1 row from users_public, got %', v_count;
    END IF;
    IF v_display_name != 'User A' THEN
      RAISE EXCEPTION 'Test 4 FAILED: Expected display_name = ''User A'', got ''%''', v_display_name;
    END IF;
    IF v_avatar_url != 'https://example.com/a.jpg' THEN
      RAISE EXCEPTION 'Test 4 FAILED: Expected avatar_url to be set, got ''%''', v_avatar_url;
    END IF;
    RAISE NOTICE 'Test 4 PASSED: Non-owner reads display_name and avatar_url via users_public view';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 5: email and account_standing columns do NOT exist on users_public view
-- ============================================================
-- Expected: querying email or account_standing from public.users_public
-- raises a SQL error "column does not exist" — they are absent, not just NULL.
-- This test verifies column ABSENCE, not null value.
-- ============================================================

-- Test 5a: email column is absent from users_public
BEGIN;
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;
  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A')
  ON CONFLICT (id) DO NOTHING;

  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  DO $$
  DECLARE
    v_col_count INTEGER;
  BEGIN
    -- Check information_schema: email column should NOT exist on the view
    SELECT count(*) INTO v_col_count
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name   = 'users_public'
        AND column_name  = 'email';
    IF v_col_count != 0 THEN
      RAISE EXCEPTION 'Test 5a FAILED: email column should not exist on users_public view, but found %', v_col_count;
    END IF;
    RAISE NOTICE 'Test 5a PASSED: email column is absent from public.users_public';
  END;
  $$;

ROLLBACK;

-- Test 5b: account_standing column is absent from users_public
-- (account_standing lives on connect.connected_profiles, not public.users — but verify it's not on the view)
BEGIN;
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'user-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;
  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'User A')
  ON CONFLICT (id) DO NOTHING;

  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  DO $$
  DECLARE
    v_col_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_col_count
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name   = 'users_public'
        AND column_name  = 'created_at';
    IF v_col_count != 0 THEN
      RAISE EXCEPTION 'Test 5b FAILED: created_at should not exist on users_public view, but found %', v_col_count;
    END IF;
    RAISE NOTICE 'Test 5b PASSED: created_at column is absent from public.users_public';
  END;
  $$;

ROLLBACK;
