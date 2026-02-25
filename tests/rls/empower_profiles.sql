-- RLS Verification Tests: empower schema (empowered_profiles)
--
-- Key design rules (from CONTEXT.md):
--   - Active profiles: readable by anon AND authenticated (public candidate pages)
--   - Inactive profiles (is_active = false): readable by OWNER ONLY
--   - legal_name: readable on ACTIVE profiles (civic leader public name)
--   - legal_name on INACTIVE profiles: inaccessible (entire row hidden, not just the column)
--
-- Pattern: Each test block is a self-contained BEGIN/ROLLBACK transaction.
--
-- Usage: psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/rls/empower_profiles.sql

-- Helper: seed an auth.users + public.users + connect.connected_profiles + empower.empowered_profiles chain
-- We repeat this inline per test to keep tests self-contained.

-- ============================================================
-- Test 1: Anon user CAN read active empowered_profiles
-- ============================================================
-- Expected: unauthenticated visitor sees active profile (Phase 8 public candidate pages).
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'candidate-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (id, user_id, display_name)
    VALUES ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO empower.empowered_profiles (user_id, connected_profile_id, legal_name, candidate_page_slug, is_active)
    VALUES (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0001-000000000001',
      'Alice Johnson',
      'alice-johnson-a1b2',
      true
    )
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate anon
  SET LOCAL role TO anon;
  SET LOCAL "request.jwt.claims" TO '{"role": "anon"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM empower.empowered_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001'
        AND is_active = true;
    IF v_count != 1 THEN
      RAISE EXCEPTION 'Test 1 FAILED: Anon should see active empowered profile, got % rows', v_count;
    END IF;
    RAISE NOTICE 'Test 1 PASSED: Anon can read active empowered_profiles';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 2: Anon user CANNOT read inactive empowered_profiles
-- ============================================================
-- Expected: demoted candidate's profile is invisible to anon.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'candidate-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (id, user_id, display_name)
    VALUES ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  -- Seed: INACTIVE profile (demoted)
  INSERT INTO empower.empowered_profiles (user_id, connected_profile_id, legal_name, candidate_page_slug, is_active)
    VALUES (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0001-000000000001',
      'Alice Johnson',
      'alice-johnson-a1b2',
      false    -- demoted
    )
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate anon
  SET LOCAL role TO anon;
  SET LOCAL "request.jwt.claims" TO '{"role": "anon"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM empower.empowered_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 2 FAILED: Anon should not see inactive empowered profile, got % rows', v_count;
    END IF;
    RAISE NOTICE 'Test 2 PASSED: Anon cannot read inactive (demoted) empowered_profiles';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 3: Owner CAN read their own inactive empowered_profiles
-- ============================================================
-- Expected: demoted user still sees their own row (needed for re-entry flow in Phase 5).
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'candidate-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (id, user_id, display_name)
    VALUES ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO empower.empowered_profiles (user_id, connected_profile_id, legal_name, candidate_page_slug, is_active)
    VALUES (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0001-000000000001',
      'Alice Johnson',
      'alice-johnson-a1b2',
      false    -- demoted
    )
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate the owner (User A)
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT count(*) INTO v_count
      FROM empower.empowered_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001'
        AND is_active = false;
    IF v_count != 1 THEN
      RAISE EXCEPTION 'Test 3 FAILED: Owner should see their own inactive profile, got % rows', v_count;
    END IF;
    RAISE NOTICE 'Test 3 PASSED: Owner can read their own inactive empowered_profiles';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 4: legal_name IS readable on active empowered_profiles (for anon and authenticated)
-- ============================================================
-- Expected: legal_name is available on active profiles — civic leaders' names are public.
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'candidate-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated'),
      ('00000000-0000-0000-0000-000000000002', 'voter-b@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'Candidate A'),
      ('00000000-0000-0000-0000-000000000002', 'Voter B')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (id, user_id, display_name)
    VALUES ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO empower.empowered_profiles (user_id, connected_profile_id, legal_name, is_active)
    VALUES (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0001-000000000001',
      'Alice Johnson',
      true
    )
  ON CONFLICT (user_id) DO NOTHING;

  -- Test 4a: Anon user reads legal_name on active profile
  SET LOCAL role TO anon;
  SET LOCAL "request.jwt.claims" TO '{"role": "anon"}';

  DO $$
  DECLARE
    v_legal_name TEXT;
  BEGIN
    SELECT legal_name INTO v_legal_name
      FROM empower.empowered_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001'
        AND is_active = true;
    IF v_legal_name IS NULL OR v_legal_name != 'Alice Johnson' THEN
      RAISE EXCEPTION 'Test 4a FAILED: Anon should see legal_name on active profile, got ''%''', v_legal_name;
    END IF;
    RAISE NOTICE 'Test 4a PASSED: Anon can read legal_name on active empowered profile';
  END;
  $$;

  -- Test 4b: Non-owning authenticated user reads legal_name on active profile
  RESET role;
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  DO $$
  DECLARE
    v_legal_name TEXT;
  BEGIN
    SELECT legal_name INTO v_legal_name
      FROM empower.empowered_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001'
        AND is_active = true;
    IF v_legal_name IS NULL OR v_legal_name != 'Alice Johnson' THEN
      RAISE EXCEPTION 'Test 4b FAILED: Non-owner authenticated should see legal_name on active profile, got ''%''', v_legal_name;
    END IF;
    RAISE NOTICE 'Test 4b PASSED: Non-owning authenticated user can read legal_name on active empowered profile';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 5: Anon user CANNOT read legal_name on inactive empowered_profiles
-- ============================================================
-- Expected: 0 rows (the entire row is hidden — legal_name inaccessibility is
-- a consequence of row invisibility, not column-level masking).
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'candidate-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (id, user_id, display_name)
    VALUES ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO empower.empowered_profiles (user_id, connected_profile_id, legal_name, is_active)
    VALUES (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0001-000000000001',
      'Alice Johnson',
      false    -- demoted
    )
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate anon
  SET LOCAL role TO anon;
  SET LOCAL "request.jwt.claims" TO '{"role": "anon"}';

  DO $$
  DECLARE
    v_count     INTEGER;
    v_legal_name TEXT;
  BEGIN
    SELECT count(*), min(legal_name) INTO v_count, v_legal_name
      FROM empower.empowered_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 5 FAILED: Anon should get 0 rows for inactive profile (row hidden), got % rows with legal_name = ''%''', v_count, v_legal_name;
    END IF;
    RAISE NOTICE 'Test 5 PASSED: Anon gets 0 rows for inactive profile — legal_name inaccessible via row hiding';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 6: Non-owning authenticated user CANNOT read legal_name on inactive profiles
-- ============================================================
-- Expected: 0 rows — the row is hidden; legal_name inaccessibility is a consequence
-- of row invisibility (RLS blocks the row entirely when is_active = false for non-owners).
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'candidate-a@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated'),
      ('00000000-0000-0000-0000-000000000002', 'voter-b@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES
      ('00000000-0000-0000-0000-000000000001', 'Candidate A'),
      ('00000000-0000-0000-0000-000000000002', 'Voter B')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (id, user_id, display_name)
    VALUES ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', 'Candidate A')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO empower.empowered_profiles (user_id, connected_profile_id, legal_name, is_active)
    VALUES (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0001-000000000001',
      'Alice Johnson',
      false    -- demoted
    )
  ON CONFLICT (user_id) DO NOTHING;

  -- Impersonate Voter B (non-owner)
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count      INTEGER;
    v_legal_name TEXT;
  BEGIN
    SELECT count(*), min(legal_name) INTO v_count, v_legal_name
      FROM empower.empowered_profiles
      WHERE user_id = '00000000-0000-0000-0000-000000000001';
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 6 FAILED: Non-owning authenticated user should get 0 rows for inactive profile, got % rows with legal_name = ''%''', v_count, v_legal_name;
    END IF;
    RAISE NOTICE 'Test 6 PASSED: Non-owning authenticated user gets 0 rows for inactive profile — legal_name inaccessible via row hiding';
  END;
  $$;

ROLLBACK;
