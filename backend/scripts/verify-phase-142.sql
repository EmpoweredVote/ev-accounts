-- verify-phase-142.sql
-- Phase gate for v2.18 (State Leaders) Phase 142: Stance Research Wave 1 — Governors + AGs (SEXS-02 partial).
-- Labeled assertions for SEXS-02a..d. Read-only; RAISE EXCEPTION on failure, RAISE NOTICE on pass.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-142.sql
--
-- ============================ KEYING (CRITICAL) ============================
-- This gate keys on (d.district_type='STATE_EXEC', o.role_canonical IN ('governor','attorney_general')) —
-- NEVER on external_id ranges. STATE_EXEC external_ids are NON-CONTIGUOUS and IRREGULAR
-- (IN AG Rokita POSITIVE 499453, TX -100202/-100204, AZ -400091/-400092, ME Gov -230001, WV AG -5400002 seq2).
-- A range predicate would silently miss them. (T-142-G-01.)
--
-- ============================ COVERAGE DENOMINATORS ============================
-- Governor coverage = 50 = 43 Phase-142 wave-1 (previously-unstanced) + 7 previously-stanced
--   (CA Newsom, IN Braun, MA Healey, MD Moore, OR Kotek, UT Cox, VA Spanberger).
-- Attorney General coverage = 42 = 36 wave-1 sourced + 6 previously-stanced
--   (CA Bonta, MA Campbell, MD Brown, OR Rayfield, UT Brown, VA Jones).
--   The 37th wave-1 AG — OH AG Andy Wilson (external_id -3900003) — is a DOCUMENTED HONEST-SKIP:
--   Dave Yost resigned 2026-06-07; Wilson was sworn in 2026-06-08 (13 days before research) and has
--   essentially no compass record; the researcher correctly refused to attribute Yost's record to him
--   (no-inference rule). Pinned belt-and-suspenders below (SEXS-02a-skip), mirroring USHS-14a (-37006).
--   So 43 elected AGs total - 1 honest-skip = 42 covered.
-- Previously-stanced execs are legitimately counted in coverage (they have answers); they are NOT part of
-- the wave-1 80 and are NOT flagged as unsourced.

\echo '============================================================'
\echo 'Phase 142 gate — Gov + AG stance coverage (SEXS-02 wave 1)'
\echo '============================================================'

-- ===== SEXS-02a: Governor coverage = 50 (43 wave-1 + 7 pre-stanced) =====
DO $$
DECLARE v_cov INT;
BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_cov
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical='governor'
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_cov <> 50 THEN
    RAISE EXCEPTION 'SEXS-02a FAILED: expected 50 STATE_EXEC governors with >=1 stance (43 wave-1 + 7 pre-stanced), found %', v_cov;
  END IF;
  RAISE NOTICE 'SEXS-02a PASS: 50 STATE_EXEC governors have >=1 sourced stance (43 wave-1 + 7 pre-stanced)';
END $$;

-- ===== SEXS-02b: Attorney General coverage = 42 (36 wave-1 sourced + 6 pre-stanced; OH AG honest-skip) =====
DO $$
DECLARE v_cov INT;
BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_cov
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical='attorney_general'
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_cov <> 42 THEN
    RAISE EXCEPTION 'SEXS-02b FAILED: expected 42 STATE_EXEC attorneys general with >=1 stance (36 wave-1 + 6 pre-stanced; OH AG -3900003 documented honest-skip), found %', v_cov;
  END IF;
  RAISE NOTICE 'SEXS-02b PASS: 42 STATE_EXEC attorneys general have >=1 sourced stance (36 wave-1 + 6 pre-stanced; OH AG -3900003 honest-skip)';
END $$;

-- ===== SEXS-02a-skip: the ONLY uncovered in-scope Gov/AG is exactly OH AG Andy Wilson (-3900003) =====
-- Belt-and-suspenders (USHS-14a pattern): pins the documented honest-skip to its exact external_id so a
-- real future miss fails loudly here rather than being absorbed into a slackened coverage count.
DO $$
DECLARE v_uncovered TEXT;
BEGIN
  SELECT string_agg(p.external_id::text || ' ' || p.full_name || ' (' || d.state || '/' || o.role_canonical || ')', ', ' ORDER BY p.external_id)
  INTO v_uncovered
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','attorney_general')
    AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_uncovered IS DISTINCT FROM '-3900003 Andy Wilson (OH/attorney_general)' THEN
    RAISE EXCEPTION 'SEXS-02a-skip FAILED: uncovered in-scope Gov/AG set should be exactly {-3900003 OH AG}, found: %', COALESCE(v_uncovered, '(none)');
  END IF;
  RAISE NOTICE 'SEXS-02a-skip PASS: sole uncovered in-scope Gov/AG is the documented honest-skip OH AG Andy Wilson (-3900003)';
END $$;

-- ===== SEXS-02c: zero-unsourced — every Gov/AG answer row has a paired context row with sources[1] LIKE 'http%' =====
DO $$
DECLARE v_un INT; v_list TEXT;
BEGIN
  SELECT COUNT(*), string_agg(DISTINCT p.external_id::text || ' ' || t.topic_key, ', ')
  INTO v_un, v_list
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN inform.compass_topics t ON t.id = pa.topic_id
  LEFT JOIN inform.politician_context c ON c.politician_id = pa.politician_id AND c.topic_id = pa.topic_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','attorney_general')
    AND (c.politician_id IS NULL OR c.sources[1] IS NULL OR c.sources[1] NOT LIKE 'http%');
  IF v_un <> 0 THEN
    RAISE EXCEPTION 'SEXS-02c FAILED: % STATE_EXEC Gov/AG answer rows are unsourced (no http-sourced context): %', v_un, v_list;
  END IF;
  RAISE NOTICE 'SEXS-02c PASS: 0 unsourced STATE_EXEC Gov/AG answer rows (every answer paired to an http-sourced context row)';
END $$;

-- ===== SEXS-02d: scope hygiene — no Gov/AG-answered politician has a NULL role_canonical join key =====
DO $$
DECLARE v_bad INT;
BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_bad
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id)
    AND o.role_canonical IN ('governor','attorney_general')
    AND o.role_canonical IS NULL;  -- structurally impossible given the IN-list, but asserts the key is populated
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'SEXS-02d FAILED: % Gov/AG-answered STATE_EXEC politicians have a NULL role_canonical', v_bad;
  END IF;
  RAISE NOTICE 'SEXS-02d PASS: role_canonical join key populated for all Gov/AG-answered STATE_EXEC politicians';
END $$;

\echo '============================================================'
\echo 'Phase 142 gate complete — all assertions above PASS'
\echo 'SEXS-02 wave 1: 50 Gov + 42 AG sourced; OH AG -3900003 honest-skip; 0 unsourced'
\echo '============================================================'
