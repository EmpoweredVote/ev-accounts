-- RLS and RPC Verification Tests: connect.xp_transactions, calculate_level, award_xp
--
-- Key tests:
--   1:   calculate_level — tier 1 boundary values (levels 1–3)
--   2:   calculate_level — tier 2 boundary values (levels 4–9)
--   3:   calculate_level — tier 3 boundary values (levels 10–29)
--   4:   calculate_level — tier 4 boundary values (level 30+)
--   5:   award_xp — first-time award (new ledger row, profile update)
--   6:   award_xp — idempotent replay (same key returns is_duplicate=true, no second row)
--   7:   award_xp — level advancement (6,000 XP crosses tier 1→2 boundary)
--   8:   RLS — authenticated owner sees own xp_transactions rows
--   9:   RLS — non-owner (different authenticated user) sees zero rows
--   10:  RLS — anon sees zero rows
--   11:  award_xp — non-existent user raises exception
--   12:  award_xp — negative amount raises exception
--
-- Pattern: Each test block is a self-contained BEGIN/ROLLBACK transaction.
--
-- Usage: psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/rls/xp_transactions.sql


-- ============================================================
-- Test 1: calculate_level — tier 1 boundary values
-- ============================================================
-- Expected: XP 0, 1999, 2000, 5999 all resolve to correct
--           level, xp_in_level, and xp_to_next_level values.
--   Tier 1: levels 1–3, 2,000 XP each (XP 0–5,999)
-- ============================================================
BEGIN;

  DO $$
  DECLARE
    v_level          INT;
    v_xp_in_level    INT;
    v_xp_to_next     INT;
  BEGIN

    -- XP = 0: level 1, xp_in_level=0, xp_to_next_level=2000
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(0);
    IF v_level != 1 OR v_xp_in_level != 0 OR v_xp_to_next != 2000 THEN
      RAISE EXCEPTION 'Test 1 FAILED at XP=0: expected (1, 0, 2000), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    -- XP = 1999: level 1, xp_in_level=1999, xp_to_next_level=1
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(1999);
    IF v_level != 1 OR v_xp_in_level != 1999 OR v_xp_to_next != 1 THEN
      RAISE EXCEPTION 'Test 1 FAILED at XP=1999: expected (1, 1999, 1), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    -- XP = 2000: level 2, xp_in_level=0, xp_to_next_level=2000
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(2000);
    IF v_level != 2 OR v_xp_in_level != 0 OR v_xp_to_next != 2000 THEN
      RAISE EXCEPTION 'Test 1 FAILED at XP=2000: expected (2, 0, 2000), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    -- XP = 5999: level 3, xp_in_level=1999, xp_to_next_level=1
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(5999);
    IF v_level != 3 OR v_xp_in_level != 1999 OR v_xp_to_next != 1 THEN
      RAISE EXCEPTION 'Test 1 FAILED at XP=5999: expected (3, 1999, 1), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    RAISE NOTICE 'Test 1 PASSED: calculate_level tier 1 boundaries (XP 0, 1999, 2000, 5999)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 2: calculate_level — tier 2 boundary values
-- ============================================================
-- Expected: XP 6000, 23999 resolve correctly.
--   Tier 2: levels 4–9, 3,000 XP each (XP 6,000–23,999)
--   At XP=6000: level 4 (first level of tier 2)
--   At XP=23999: level 9 (last XP before tier 3 boundary)
-- ============================================================
BEGIN;

  DO $$
  DECLARE
    v_level          INT;
    v_xp_in_level    INT;
    v_xp_to_next     INT;
  BEGIN

    -- XP = 6000: level 4, xp_in_level=0, xp_to_next_level=3000
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(6000);
    IF v_level != 4 OR v_xp_in_level != 0 OR v_xp_to_next != 3000 THEN
      RAISE EXCEPTION 'Test 2 FAILED at XP=6000: expected (4, 0, 3000), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    -- XP = 23999: level 9, xp_in_level=2999, xp_to_next_level=1
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(23999);
    IF v_level != 9 OR v_xp_in_level != 2999 OR v_xp_to_next != 1 THEN
      RAISE EXCEPTION 'Test 2 FAILED at XP=23999: expected (9, 2999, 1), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    RAISE NOTICE 'Test 2 PASSED: calculate_level tier 2 boundaries (XP 6000, 23999)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 3: calculate_level — tier 3 boundary values
-- ============================================================
-- Expected: XP 24000, 103999 resolve correctly.
--   Tier 3: levels 10–29, 4,000 XP each (XP 24,000–103,999)
--   At XP=24000: level 10 (first level of tier 3)
--   At XP=103999: level 29 (last XP before tier 4 boundary)
-- ============================================================
BEGIN;

  DO $$
  DECLARE
    v_level          INT;
    v_xp_in_level    INT;
    v_xp_to_next     INT;
  BEGIN

    -- XP = 24000: level 10, xp_in_level=0, xp_to_next_level=4000
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(24000);
    IF v_level != 10 OR v_xp_in_level != 0 OR v_xp_to_next != 4000 THEN
      RAISE EXCEPTION 'Test 3 FAILED at XP=24000: expected (10, 0, 4000), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    -- XP = 103999: level 29, xp_in_level=3999, xp_to_next_level=1
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(103999);
    IF v_level != 29 OR v_xp_in_level != 3999 OR v_xp_to_next != 1 THEN
      RAISE EXCEPTION 'Test 3 FAILED at XP=103999: expected (29, 3999, 1), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    RAISE NOTICE 'Test 3 PASSED: calculate_level tier 3 boundaries (XP 24000, 103999)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 4: calculate_level — tier 4 boundary values
-- ============================================================
-- Expected: XP 104000, 109000 resolve correctly.
--   Tier 4: level 30+, 5,000 XP each (XP 104,000+)
--   At XP=104000: level 30 (first level of tier 4)
--   At XP=109000: level 31 (second tier-4 level; 104000 + 5000)
-- ============================================================
BEGIN;

  DO $$
  DECLARE
    v_level          INT;
    v_xp_in_level    INT;
    v_xp_to_next     INT;
  BEGIN

    -- XP = 104000: level 30, xp_in_level=0, xp_to_next_level=5000
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(104000);
    IF v_level != 30 OR v_xp_in_level != 0 OR v_xp_to_next != 5000 THEN
      RAISE EXCEPTION 'Test 4 FAILED at XP=104000: expected (30, 0, 5000), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    -- XP = 109000: level 31, xp_in_level=0, xp_to_next_level=5000
    SELECT level, xp_in_level, xp_to_next_level
      INTO v_level, v_xp_in_level, v_xp_to_next
      FROM connect.calculate_level(109000);
    IF v_level != 31 OR v_xp_in_level != 0 OR v_xp_to_next != 5000 THEN
      RAISE EXCEPTION 'Test 4 FAILED at XP=109000: expected (31, 0, 5000), got (%, %, %)',
        v_level, v_xp_in_level, v_xp_to_next;
    END IF;

    RAISE NOTICE 'Test 4 PASSED: calculate_level tier 4 boundaries (XP 104000, 109000)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 5: award_xp — first-time award
-- ============================================================
-- Expected:
--   - Returns exactly 1 row with is_duplicate = FALSE
--   - returned total_xp = 500, current_level = 1
--   - connected_profiles.total_xp = 500 after call
--   - xp_transactions has exactly 1 row for this user
--
-- Seed user: 00000000-0000-0000-0000-000000000010
-- RESET role before calling award_xp (SECURITY DEFINER runs as function owner)
-- ============================================================
BEGIN;

  -- Seed auth.users
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000010', 'xp-user-10@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  -- Seed public.users
  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (id) DO NOTHING;

  -- Seed connected_profiles (required by award_xp profile row check)
  INSERT INTO connect.connected_profiles (user_id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (user_id) DO NOTHING;

  RESET role;  -- SECURITY DEFINER runs as postgres (function owner)

  DO $$
  DECLARE
    v_row_count      INT;
    v_is_duplicate   BOOLEAN;
    v_total_xp       BIGINT;
    v_current_level  INT;
    v_profile_xp     BIGINT;
    v_ledger_count   INT;
  BEGIN

    -- Call award_xp and verify return values
    SELECT count(*), bool_and(is_duplicate), max(total_xp), max(current_level)
      INTO v_row_count, v_is_duplicate, v_total_xp, v_current_level
      FROM connect.award_xp(
        '00000000-0000-0000-0000-000000000010',
        'test_source',
        500,
        'test-key-001',
        NULL
      );

    IF v_row_count != 1 THEN
      RAISE EXCEPTION 'Test 5 FAILED: award_xp should return 1 row, got %', v_row_count;
    END IF;
    IF v_is_duplicate != FALSE THEN
      RAISE EXCEPTION 'Test 5 FAILED: first award should have is_duplicate=FALSE, got %', v_is_duplicate;
    END IF;
    IF v_total_xp != 500 THEN
      RAISE EXCEPTION 'Test 5 FAILED: returned total_xp should be 500, got %', v_total_xp;
    END IF;
    IF v_current_level != 1 THEN
      RAISE EXCEPTION 'Test 5 FAILED: returned current_level should be 1, got %', v_current_level;
    END IF;

    -- Verify connected_profiles.total_xp was updated
    SELECT cp.total_xp INTO v_profile_xp
      FROM connect.connected_profiles cp
      WHERE cp.user_id = '00000000-0000-0000-0000-000000000010';
    IF v_profile_xp != 500 THEN
      RAISE EXCEPTION 'Test 5 FAILED: connected_profiles.total_xp should be 500, got %', v_profile_xp;
    END IF;

    -- Verify exactly 1 ledger row exists for this user
    SELECT count(*) INTO v_ledger_count
      FROM connect.xp_transactions
      WHERE user_id = '00000000-0000-0000-0000-000000000010';
    IF v_ledger_count != 1 THEN
      RAISE EXCEPTION 'Test 5 FAILED: xp_transactions should have 1 row, got %', v_ledger_count;
    END IF;

    RAISE NOTICE 'Test 5 PASSED: award_xp first-time award (total_xp=500, level=1, 1 ledger row)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 6: award_xp — idempotent replay
-- ============================================================
-- Expected:
--   - First call: is_duplicate=FALSE, total_xp=500, 1 ledger row
--   - Second call (same key): is_duplicate=TRUE, total_xp still 500,
--     still exactly 1 ledger row (no second insert)
--
-- Seed user: 00000000-0000-0000-0000-000000000010
-- ============================================================
BEGIN;

  -- Seed
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000010', 'xp-user-10@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (user_id) DO NOTHING;

  RESET role;

  DO $$
  DECLARE
    v_is_duplicate  BOOLEAN;
    v_total_xp      BIGINT;
    v_ledger_count  INT;
  BEGIN

    -- First call
    SELECT is_duplicate, total_xp
      INTO v_is_duplicate, v_total_xp
      FROM connect.award_xp(
        '00000000-0000-0000-0000-000000000010',
        'test_source',
        500,
        'idempotent-key-001',
        NULL
      );
    IF v_is_duplicate != FALSE THEN
      RAISE EXCEPTION 'Test 6 FAILED: first call should have is_duplicate=FALSE, got %', v_is_duplicate;
    END IF;
    IF v_total_xp != 500 THEN
      RAISE EXCEPTION 'Test 6 FAILED: first call total_xp should be 500, got %', v_total_xp;
    END IF;

    SELECT count(*) INTO v_ledger_count
      FROM connect.xp_transactions
      WHERE user_id = '00000000-0000-0000-0000-000000000010';
    IF v_ledger_count != 1 THEN
      RAISE EXCEPTION 'Test 6 FAILED: after first call, ledger should have 1 row, got %', v_ledger_count;
    END IF;

    -- Second call (same idempotency key — replay)
    SELECT is_duplicate, total_xp
      INTO v_is_duplicate, v_total_xp
      FROM connect.award_xp(
        '00000000-0000-0000-0000-000000000010',
        'test_source',
        500,
        'idempotent-key-001',  -- same key
        NULL
      );
    IF v_is_duplicate != TRUE THEN
      RAISE EXCEPTION 'Test 6 FAILED: second call should have is_duplicate=TRUE, got %', v_is_duplicate;
    END IF;
    IF v_total_xp != 500 THEN
      RAISE EXCEPTION 'Test 6 FAILED: second call total_xp should still be 500 (no double-credit), got %', v_total_xp;
    END IF;

    SELECT count(*) INTO v_ledger_count
      FROM connect.xp_transactions
      WHERE user_id = '00000000-0000-0000-0000-000000000010';
    IF v_ledger_count != 1 THEN
      RAISE EXCEPTION 'Test 6 FAILED: after duplicate call, ledger should STILL have 1 row, got %', v_ledger_count;
    END IF;

    RAISE NOTICE 'Test 6 PASSED: award_xp idempotent replay (is_duplicate=TRUE, no second ledger row)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 7: award_xp — level advancement (tier 1→2 boundary)
-- ============================================================
-- Expected:
--   - Award 6,000 XP to a fresh user
--   - current_level = 4 (first level of tier 2)
--   - total_xp = 6000
--
-- Seed user: 00000000-0000-0000-0000-000000000011
-- ============================================================
BEGIN;

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000011', 'xp-user-11@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000011', 'XP User 11')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000011', 'XP User 11')
  ON CONFLICT (user_id) DO NOTHING;

  RESET role;

  DO $$
  DECLARE
    v_current_level INT;
    v_total_xp      BIGINT;
  BEGIN

    SELECT current_level, total_xp
      INTO v_current_level, v_total_xp
      FROM connect.award_xp(
        '00000000-0000-0000-0000-000000000011',
        'test_source',
        6000,
        'level-advance-key-001',
        NULL
      );

    IF v_total_xp != 6000 THEN
      RAISE EXCEPTION 'Test 7 FAILED: total_xp should be 6000, got %', v_total_xp;
    END IF;
    IF v_current_level != 4 THEN
      RAISE EXCEPTION 'Test 7 FAILED: current_level should be 4 (tier 2 boundary), got %', v_current_level;
    END IF;

    RAISE NOTICE 'Test 7 PASSED: award_xp level advancement to level 4 at 6000 XP (tier 1→2 boundary)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 8: RLS — authenticated owner sees own xp_transactions
-- ============================================================
-- Expected: User A (owner) sees their own xp_transactions row via SELECT.
-- Seed: insert xp_transaction directly as postgres (bypasses RLS).
-- Then impersonate User A and verify count = 1.
-- ============================================================
BEGIN;

  -- Seed User A
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000010', 'xp-user-10@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (user_id) DO NOTHING;

  -- Insert a ledger row directly as postgres (SECURITY DEFINER path bypasses RLS)
  INSERT INTO connect.xp_transactions (user_id, source, amount, idempotency_key)
    VALUES ('00000000-0000-0000-0000-000000000010', 'rls_test', 100, 'rls-test-key-owner-001')
  ON CONFLICT (idempotency_key) DO NOTHING;

  -- Impersonate User A (the owner)
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000010", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count INT;
  BEGIN
    SELECT count(*) INTO v_count
      FROM connect.xp_transactions
      WHERE user_id = '00000000-0000-0000-0000-000000000010';
    IF v_count != 1 THEN
      RAISE EXCEPTION 'Test 8 FAILED: owner should see 1 xp_transactions row, got %', v_count;
    END IF;
    RAISE NOTICE 'Test 8 PASSED: authenticated owner sees own xp_transactions row';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 9: RLS — non-owner sees zero xp_transactions
-- ============================================================
-- Expected: User B (non-owner) sees 0 rows for User A's transactions.
-- Same seed as Test 8; impersonate User B instead.
-- ============================================================
BEGIN;

  -- Seed User A and User B
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES
      ('00000000-0000-0000-0000-000000000010', 'xp-user-10@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated'),
      ('00000000-0000-0000-0000-000000000012', 'xp-user-12@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES
      ('00000000-0000-0000-0000-000000000010', 'XP User 10'),
      ('00000000-0000-0000-0000-000000000012', 'XP User 12')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name)
    VALUES
      ('00000000-0000-0000-0000-000000000010', 'XP User 10'),
      ('00000000-0000-0000-0000-000000000012', 'XP User 12')
  ON CONFLICT (user_id) DO NOTHING;

  -- Insert User A's ledger row as postgres
  INSERT INTO connect.xp_transactions (user_id, source, amount, idempotency_key)
    VALUES ('00000000-0000-0000-0000-000000000010', 'rls_test', 100, 'rls-test-key-nonowner-001')
  ON CONFLICT (idempotency_key) DO NOTHING;

  -- Impersonate User B (non-owner)
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000012", "role": "authenticated"}';

  DO $$
  DECLARE
    v_count INT;
  BEGIN
    SELECT count(*) INTO v_count
      FROM connect.xp_transactions
      WHERE user_id = '00000000-0000-0000-0000-000000000010';
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 9 FAILED: non-owner should see 0 xp_transactions rows, got %', v_count;
    END IF;
    RAISE NOTICE 'Test 9 PASSED: non-owner sees zero xp_transactions rows (RLS enforced)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 10: RLS — anon sees zero xp_transactions
-- ============================================================
-- Expected: anon role sees 0 rows (GRANT SELECT exists but no anon RLS policy
-- means empty set, not permission denied — matches connect schema convention).
-- ============================================================
BEGIN;

  -- Seed User A
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000010', 'xp-user-10@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (user_id) DO NOTHING;

  -- Insert ledger row as postgres
  INSERT INTO connect.xp_transactions (user_id, source, amount, idempotency_key)
    VALUES ('00000000-0000-0000-0000-000000000010', 'rls_test', 100, 'rls-test-key-anon-001')
  ON CONFLICT (idempotency_key) DO NOTHING;

  -- Impersonate anon
  SET LOCAL role TO anon;
  SET LOCAL "request.jwt.claims" TO '{"role": "anon"}';

  DO $$
  DECLARE
    v_count INT;
  BEGIN
    -- anon has GRANT SELECT but no RLS policy → empty set (not permission denied)
    SELECT count(*) INTO v_count
      FROM connect.xp_transactions;
    IF v_count != 0 THEN
      RAISE EXCEPTION 'Test 10 FAILED: anon should see 0 xp_transactions rows, got %', v_count;
    END IF;
    RAISE NOTICE 'Test 10 PASSED: anon sees zero xp_transactions rows (no anon RLS policy)';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 11: award_xp — non-existent user raises exception
-- ============================================================
-- Expected: calling award_xp for a UUID with no connected_profiles row
-- raises an exception. The function checks for profile existence and
-- raises "User % has no connected_profiles row" when not found.
-- ============================================================
BEGIN;

  RESET role;  -- postgres (SECURITY DEFINER runs as function owner)

  DO $$
  DECLARE
    v_raised BOOLEAN := FALSE;
  BEGIN
    BEGIN
      -- UUID 00000000-0000-0000-0000-DEADBEEF0001 has no seed rows
      PERFORM connect.award_xp(
        '00000000-0000-0000-0000-deadbeef0001',
        'test_source',
        100,
        'no-user-test-key-001',
        NULL
      );
    EXCEPTION WHEN OTHERS THEN
      v_raised := TRUE;
    END;

    IF NOT v_raised THEN
      RAISE EXCEPTION 'Test 11 FAILED: expected exception for non-existent user was not raised';
    END IF;
    RAISE NOTICE 'Test 11 PASSED: award_xp raises exception for user with no connected_profiles row';
  END;
  $$;

ROLLBACK;


-- ============================================================
-- Test 12: award_xp — negative amount raises exception
-- ============================================================
-- Expected: calling award_xp with amount = -5 raises an exception.
-- The function validates p_amount > 0 before any DB operations.
-- ============================================================
BEGIN;

  -- Seed a valid user so the failure is from amount validation, not missing profile
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
    VALUES ('00000000-0000-0000-0000-000000000010', 'xp-user-10@test.example', 'hash', now(), now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.users (id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO connect.connected_profiles (user_id, display_name)
    VALUES ('00000000-0000-0000-0000-000000000010', 'XP User 10')
  ON CONFLICT (user_id) DO NOTHING;

  RESET role;

  DO $$
  DECLARE
    v_raised BOOLEAN := FALSE;
  BEGIN
    BEGIN
      PERFORM connect.award_xp(
        '00000000-0000-0000-0000-000000000010',
        'test_source',
        -5,           -- negative amount — must be rejected
        'negative-amount-test-key-001',
        NULL
      );
    EXCEPTION WHEN OTHERS THEN
      v_raised := TRUE;
    END;

    IF NOT v_raised THEN
      RAISE EXCEPTION 'Test 12 FAILED: expected exception for negative amount was not raised';
    END IF;
    RAISE NOTICE 'Test 12 PASSED: award_xp raises exception for negative amount';
  END;
  $$;

ROLLBACK;
