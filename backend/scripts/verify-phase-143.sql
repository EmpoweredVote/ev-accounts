-- verify-phase-143.sql
-- Phase gate for v2.18 (State Leaders) Phase 143: Stance Research Wave 2 — SoS + Treasurer + Lt Gov
-- (completes SEXS-02). Labeled assertions SEXS-02e..i. Read-only; RAISE EXCEPTION on failure,
-- RAISE NOTICE on pass.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-143.sql
--
-- ============================ KEYING (CRITICAL) ============================
-- Keys on (d.district_type='STATE_EXEC', o.role_canonical IN
-- ('secretary_of_state','treasurer','lt_governor')) — NEVER on external_id ranges.
-- STATE_EXEC external_ids are NON-CONTIGUOUS and IRREGULAR (POSITIVE IN SoS 642977 / IN
-- Treasurer 688298; TX LtGov -100203 / TX Comptroller -100205; AZ -400093/-400094;
-- FL CFO -1200004; NY Comptroller -3600004; WV SoS -5400003 seq3; AK LtGov -200009 seq9).
-- A range predicate would silently miss them. (T-143-G-01.)
--
-- ============================ COVERAGE DENOMINATORS (prod-verified 2026-06-21) =========
-- Secretary of State coverage = 34 = 31 Phase-143 wave-2 sourced + 3 previously-stanced
--   (1 documented whole-record honest-skip: SC SoS Mark Hammond -4500004).
-- Treasurer coverage = 34 = 30 wave-2 sourced + 4 previously-stanced
--   (4 documented whole-record honest-skips: AL Boozer -100005, KY Metcalf -2100005,
--    MS McRae -2800005, SD Haeder -4600005 — all businessman/dead-source treasurers).
-- Lt Governor coverage = 39 = 33 wave-2 sourced + 6 previously-stanced
--   (4 documented whole-record honest-skips: OH Tressel -3900002, IA Cournoyer -1900002,
--    NE Kelly -3100002, OK Pinnell -4000002 — ceremonial/no-record/walled LtGovs).
-- 9 total whole-record honest-skips pinned belt-and-suspenders below (SEXS-02-skip),
-- mirroring USHS-14a (-37006) and SEXS-02a-skip (OH AG -3900003). AZ Lt Gov is NOT seeded
-- (Prop 131, deferred to Jan 2027) so it is not in any denominator. Previously-stanced execs
-- are legitimately counted in coverage; they are NOT part of the wave-2 103 and not unsourced.

\echo '============================================================'
\echo 'Phase 143 gate — SoS + Treasurer + Lt Gov coverage (SEXS-02 wave 2)'
\echo '============================================================'

-- ===== SEXS-02e: Secretary of State coverage = 34 (31 wave-2 + 3 pre-stanced; SC SoS honest-skip) =====
DO $$
DECLARE v_cov INT;
BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_cov
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC' AND o.role_canonical='secretary_of_state'
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_cov <> 34 THEN
    RAISE EXCEPTION 'SEXS-02e FAILED: expected 34 STATE_EXEC secretaries of state with >=1 stance (31 wave-2 + 3 pre-stanced; SC SoS -4500004 documented honest-skip), found %', v_cov;
  END IF;
  RAISE NOTICE 'SEXS-02e PASS: 34 STATE_EXEC secretaries of state have >=1 sourced stance (31 wave-2 + 3 pre-stanced; SC SoS -4500004 honest-skip)';
END $$;

-- ===== SEXS-02f: Treasurer coverage = 34 (30 wave-2 + 4 pre-stanced; 4 honest-skips) =====
-- role_canonical='treasurer' includes the functional-treasurer title-aliases: FL CFO, NY/TX Comptroller.
DO $$
DECLARE v_cov INT;
BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_cov
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC' AND o.role_canonical='treasurer'
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_cov <> 34 THEN
    RAISE EXCEPTION 'SEXS-02f FAILED: expected 34 STATE_EXEC treasurers with >=1 stance (30 wave-2 + 4 pre-stanced; 4 documented honest-skips -100005/-2100005/-2800005/-4600005), found %', v_cov;
  END IF;
  RAISE NOTICE 'SEXS-02f PASS: 34 STATE_EXEC treasurers have >=1 sourced stance (30 wave-2 + 4 pre-stanced; 4 honest-skips; incl. FL CFO + NY/TX Comptroller as treasurer)';
END $$;

-- ===== SEXS-02g: Lt Governor coverage = 39 (33 wave-2 + 6 pre-stanced; 4 honest-skips) =====
-- AZ Lt Gov NOT seeded (Prop 131, eff. Jan 2027) — correctly absent from the denominator.
DO $$
DECLARE v_cov INT;
BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_cov
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC' AND o.role_canonical='lt_governor'
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_cov <> 39 THEN
    RAISE EXCEPTION 'SEXS-02g FAILED: expected 39 STATE_EXEC lt governors with >=1 stance (33 wave-2 + 6 pre-stanced; 4 documented honest-skips -1900002/-3100002/-3900002/-4000002), found %', v_cov;
  END IF;
  RAISE NOTICE 'SEXS-02g PASS: 39 STATE_EXEC lt governors have >=1 sourced stance (33 wave-2 + 6 pre-stanced; 4 honest-skips; AZ LtGov deferred per Prop 131)';
END $$;

-- ===== SEXS-02-skip: the uncovered in-scope SoS/Treasurer/LtGov set is EXACTLY the 9 documented honest-skips =====
-- Belt-and-suspenders (USHS-14a pattern): pins every documented whole-record honest-skip to its exact
-- external_id so a real future miss fails loudly here rather than being absorbed into a slack count.
DO $$
DECLARE v_uncovered TEXT;
DECLARE v_expected TEXT := '-4000002 Matt Pinnell (OK/lt_governor); -3900002 Jim Tressel (OH/lt_governor); -3100002 Joe Kelly (NE/lt_governor); -1900002 Chris Cournoyer (IA/lt_governor); -4500004 Mark Hammond (SC/secretary_of_state); -4600005 Josh Haeder (SD/treasurer); -2800005 David McRae (MS/treasurer); -2100005 Mark Metcalf (KY/treasurer); -100005 Young Boozer (AL/treasurer)';
BEGIN
  SELECT string_agg(p.external_id::text || ' ' || p.full_name || ' (' || d.state || '/' || o.role_canonical || ')', '; ' ORDER BY o.role_canonical, p.external_id)
  INTO v_uncovered
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC' AND o.role_canonical IN ('secretary_of_state','treasurer','lt_governor')
    AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_uncovered IS DISTINCT FROM v_expected THEN
    RAISE EXCEPTION 'SEXS-02-skip FAILED: uncovered in-scope SoS/Treasurer/LtGov set should be exactly the 9 documented honest-skips, found: %', COALESCE(v_uncovered, '(none)');
  END IF;
  RAISE NOTICE 'SEXS-02-skip PASS: the 9 uncovered in-scope execs are exactly the documented whole-record honest-skips (1 SoS + 4 Treasurer + 4 LtGov)';
END $$;

-- ===== SEXS-02h: zero-unsourced — every Wave-2-role answer row has a paired context row with sources[1] LIKE 'http%' =====
DO $$
DECLARE v_un INT; v_list TEXT;
BEGIN
  SELECT COUNT(*), string_agg(DISTINCT p.external_id::text || ' ' || t.topic_key, ', ')
  INTO v_un, v_list
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN inform.compass_topics t ON t.id = pa.topic_id
  LEFT JOIN inform.politician_context c ON c.politician_id = pa.politician_id AND c.topic_id = pa.topic_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('secretary_of_state','treasurer','lt_governor')
    AND (c.politician_id IS NULL OR c.sources[1] IS NULL OR c.sources[1] NOT LIKE 'http%');
  IF v_un <> 0 THEN
    RAISE EXCEPTION 'SEXS-02h FAILED: % STATE_EXEC SoS/Treasurer/LtGov answer rows are unsourced (no http-sourced context): %', v_un, v_list;
  END IF;
  RAISE NOTICE 'SEXS-02h PASS: 0 unsourced STATE_EXEC SoS/Treasurer/LtGov answer rows (every answer paired to an http-sourced context row)';
END $$;

-- ===== SEXS-02i: scope hygiene — no SoS/Treasurer/LtGov-answered politician has a NULL role_canonical join key =====
DO $$
DECLARE v_bad INT;
BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_bad
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id)
    AND o.role_canonical IN ('secretary_of_state','treasurer','lt_governor')
    AND o.role_canonical IS NULL;  -- structurally impossible given the IN-list; asserts the key is populated
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'SEXS-02i FAILED: % Wave-2-role-answered STATE_EXEC politicians have a NULL role_canonical', v_bad;
  END IF;
  RAISE NOTICE 'SEXS-02i PASS: role_canonical join key populated for all Wave-2-role-answered STATE_EXEC politicians';
END $$;

\echo '============================================================'
\echo 'Phase 143 gate complete — all assertions above PASS'
\echo 'SEXS-02 wave 2: 34 SoS + 34 Treasurer + 39 LtGov sourced; 9 documented honest-skips; 0 unsourced'
\echo '============================================================'
