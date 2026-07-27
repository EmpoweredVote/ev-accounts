-- verify-phase-141-144.sql
-- CONSOLIDATED phase gate for v2.18 (State Leaders) — folds the three already-passing single-phase gates
-- (verify-phase-141.sql records+headshots, verify-phase-142.sql Gov+AG stances, verify-phase-143.sql
-- SoS+Treasurer+LtGov stances) into ONE read-only pass, and ADDS the SEXR-05 feed-surfacing smoke test as a
-- SQL simulation of the production feed predicate. This is the FINAL gate for the v2.18 milestone: it closes
-- SEXR-05 (feed surfacing) and SEXS-03 (consolidated verification), and re-asserts every v2.18 invariant
-- (SEXR-01..04 records + SEXS-02 stance coverage) so a single command proves the whole milestone.
-- Read-only: RAISE EXCEPTION on failure, RAISE NOTICE on pass. No writes, no DDL.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-141-144.sql
--
-- ============================ KEYING (CRITICAL) ============================
-- Keys on (d.district_type='STATE_EXEC', o.role_canonical IN
-- ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')) — NEVER on external_id
-- ranges. STATE_EXEC external_ids are NON-CONTIGUOUS and IRREGULAR (POSITIVE IN SoS 642977 / IN Treasurer
-- 688298; TX LtGov -100203 / TX Comptroller -100205; AZ -400093/-400094; FL CFO -1200004; NY Comptroller
-- -3600004; WV SoS -5400003 seq3; AK LtGov -200009 seq9). A range predicate would silently miss them.
--
-- ============================ THE 209-OFFICE DENOMINATOR (prod-verified 2026-06-22) ============================
-- In-scope = an office joined to a STATE_EXEC district with role_canonical in the Big-5 set.
--   governor            = 50  (all 50 states popularly elect a governor)
--   lt_governor         = 43  (excl. ME/NH/OR/WY = office NONE; TN/WV = Senate-President not elected;
--                              AZ = DEFERRED — Prop 131, office not seated until Jan 2027 — KNOWN EXCLUSION,
--                              already baked into the 43, NOT a miss)
--   attorney_general    = 43  (excl. AK/HI/NH/NJ/WY = appointed; ME = legislature; TN = Supreme-Court-appointed)
--   secretary_of_state  = 35  (excl. AK/HI/UT = office NONE; DE/FL/NJ/NY/OK/PA/TX/VA = appointed; ME/NH/TN = legislature)
--   treasurer           = 38  (50 - 12 excl. NY Comptroller + TX Comptroller + FL CFO counted AS treasurer;
--                              MD elected Comptroller is NOT — separate appointed Treasurer)
--   TOTAL               = 209
--
-- ============================ COVERAGE (prod-verified 2026-06-22) ============================
-- 199 covered = Gov 50 + AG 42 + SoS 34 + Treasurer 34 + LtGov 39.  In-scope 209 - 199 covered = 10 honest-skips.
-- The 10 documented whole-record honest-skips (1 AG + 1 SoS + 4 Treasurer + 4 LtGov), pinned by exact external_id
-- in SEXS-03-skip (USHS-14a / SEXS-02-skip pattern): OH AG Andy Wilson (-3900003); SC SoS Mark Hammond (-4500004);
-- Treasurers Boozer-AL (-100005)/Metcalf-KY (-2100005)/McRae-MS (-2800005)/Haeder-SD (-4600005);
-- LtGovs Cournoyer-IA (-1900002)/Kelly-NE (-3100002)/Tressel-OH (-3900002)/Pinnell-OK (-4000002).

\echo '============================================================'
\echo 'Phase 141-144 CONSOLIDATED gate (v2.18 State Leaders) — SEXR-01..05 + SEXS-03'
\echo '============================================================'

-- ===== SEXR-01/02-consolidated: 209 in-scope STATE_EXEC offices seeded (per-role 50/43/43/35/38) =====
DO $$
DECLARE v_total INT; v_gov INT; v_lt INT; v_ag INT; v_sos INT; v_treas INT;
BEGIN
  SELECT count(DISTINCT (d.state, o.role_canonical)) INTO v_total
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer');
  SELECT
    count(DISTINCT d.state) FILTER (WHERE o.role_canonical='governor'),
    count(DISTINCT d.state) FILTER (WHERE o.role_canonical='lt_governor'),
    count(DISTINCT d.state) FILTER (WHERE o.role_canonical='attorney_general'),
    count(DISTINCT d.state) FILTER (WHERE o.role_canonical='secretary_of_state'),
    count(DISTINCT d.state) FILTER (WHERE o.role_canonical='treasurer')
  INTO v_gov, v_lt, v_ag, v_sos, v_treas
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer');
  IF v_total <> 209 THEN
    RAISE EXCEPTION 'SEXR-01/02-consolidated FAILED: expected 209 in-scope (state,role_canonical) STATE_EXEC offices, found %', v_total;
  END IF;
  IF (v_gov, v_lt, v_ag, v_sos, v_treas) IS DISTINCT FROM (50, 43, 43, 35, 38) THEN
    RAISE EXCEPTION 'SEXR-01/02-consolidated FAILED: per-role counts expected gov=50/lt=43/ag=43/sos=35/treas=38, found gov=%/lt=%/ag=%/sos=%/treas=%', v_gov, v_lt, v_ag, v_sos, v_treas;
  END IF;
  RAISE NOTICE 'SEXR-01/02-consolidated PASS: 209 in-scope STATE_EXEC offices (gov 50 / lt 43 / ag 43 / sos 35 / treas 38); AZ LtGov deferred per Prop 131 (baked into lt=43)';
END $$;

-- ===== SEXR-03-consolidated: every in-scope (state,role_canonical) pair is represented exactly once per state =====
-- role_canonical is populated on all 209 in-scope offices BY CONSTRUCTION (SEXR-01/02 above asserts exact per-role
-- state counts 50/43/43/35/38 — a missing canonical row would drop that count). So the meaningful SEXR-03 check is
-- that no state has a DUPLICATE in-scope (state, role_canonical) pair (the dedup invariant from migration 192).
-- NOTE: out-of-scope STATE_EXEC offices (ME AG/SoS/Treasurer = legislature-selected; MD elected Comptroller + MD
-- appointed Treasurer; IN Comptroller; plus legacy duplicate "State of Indiana" rows for IN SoS/Treasurer) correctly
-- carry NULL role_canonical and are intentionally NOT in scope — we do NOT flag NULL-role offices by title.
DO $$
DECLARE v_dup INT;
BEGIN
  SELECT count(*) INTO v_dup FROM (
    SELECT d.state, o.role_canonical
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type='STATE_EXEC'
      AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    GROUP BY d.state, o.role_canonical HAVING count(*) > 1
  ) dups;
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'SEXR-03-consolidated FAILED: % in-scope (state,role_canonical) STATE_EXEC pair(s) duplicated', v_dup;
  END IF;
  RAISE NOTICE 'SEXR-03-consolidated PASS: no in-scope (state,role_canonical) pair duplicated (role_canonical populated by construction per SEXR-01/02)';
END $$;

-- ===== SEXR-04-consolidated: every newly-seeded exec has a politician_images.url headshot =====
-- Newly-seeded set = states NOT IN the 9 pre-existing STATE_EXEC states, OR the two re-linked IN positive ids.
DO $$
DECLARE v_missing INT;
BEGIN
  SELECT count(DISTINCT p.id) INTO v_missing
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND (d.state NOT IN ('CA','IN','MA','MD','ME','OR','TX','UT','VA') OR p.external_id IN (642977, 688298))
    AND NOT EXISTS (
      SELECT 1 FROM essentials.politician_images pi
      WHERE pi.politician_id = p.id AND pi.url IS NOT NULL AND pi.url <> ''
    );
  IF v_missing <> 0 THEN
    RAISE EXCEPTION 'SEXR-04-consolidated FAILED: % newly-seeded exec(s) lack a politician_images.url headshot', v_missing;
  END IF;
  RAISE NOTICE 'SEXR-04-consolidated PASS: every newly-seeded exec has a politician_images.url headshot';
END $$;

-- ===== SEXS-03-hygiene: in-scope Big-5 STATE_EXEC districts have state=upper(state) AND non-empty geo_id =====
-- CRITICAL SCOPING (mirror 141 D-10a/D-10b): scope to o.role_canonical IN the Big-5 set. A BARE
-- whole-district_type='STATE_EXEC' count returns 2 (legacy non-Big-5 rows: CA "Board of Equalization Member"
-- geo_id='' and IN "Indiana" geo_id='', both NULL-role) and would FALSE-FAIL. Those 2 legacy rows are NOT
-- in-scope Big-5 offices and are correctly excluded.
DO $$
DECLARE v_bad INT;
BEGIN
  SELECT count(DISTINCT d.id) INTO v_bad
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND (d.state <> upper(d.state) OR d.geo_id IS NULL OR d.geo_id = '');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'SEXS-03-hygiene FAILED: % in-scope Big-5 STATE_EXEC district(s) have a non-uppercase state or NULL/empty geo_id', v_bad;
  END IF;
  RAISE NOTICE 'SEXS-03-hygiene PASS: all in-scope Big-5 STATE_EXEC districts have uppercase state + non-empty geo_id (2 legacy non-Big-5 rows correctly excluded)';
END $$;

-- ===== SEXS-03-coverage: per-role stance coverage = gov 50 / ag 42 / sos 34 / treas 34 / lt 39 (199 total) =====
DO $$
DECLARE v_gov INT; v_ag INT; v_sos INT; v_treas INT; v_lt INT;
BEGIN
  SELECT
    count(DISTINCT p.id) FILTER (WHERE o.role_canonical='governor'),
    count(DISTINCT p.id) FILTER (WHERE o.role_canonical='attorney_general'),
    count(DISTINCT p.id) FILTER (WHERE o.role_canonical='secretary_of_state'),
    count(DISTINCT p.id) FILTER (WHERE o.role_canonical='treasurer'),
    count(DISTINCT p.id) FILTER (WHERE o.role_canonical='lt_governor')
  INTO v_gov, v_ag, v_sos, v_treas, v_lt
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF (v_gov, v_ag, v_sos, v_treas, v_lt) IS DISTINCT FROM (50, 42, 34, 34, 39) THEN
    RAISE EXCEPTION 'SEXS-03-coverage FAILED: expected gov=50/ag=42/sos=34/treas=34/lt=39 (199), found gov=%/ag=%/sos=%/treas=%/lt=%', v_gov, v_ag, v_sos, v_treas, v_lt;
  END IF;
  RAISE NOTICE 'SEXS-03-coverage PASS: 199 in-scope execs sourced (gov 50 / ag 42 / sos 34 / treas 34 / lt 39)';
END $$;

-- ===== SEXS-03-skip: the in-scope-uncovered exec set across ALL 5 roles = EXACTLY the 10 documented honest-skips =====
-- Belt-and-suspenders (USHS-14a / SEXS-02-skip pattern): pins every documented whole-record honest-skip to its
-- exact external_id so a real future miss fails loudly here rather than being absorbed into a slack count.
-- v_expected was captured VERBATIM from the live production query (ORDER BY o.role_canonical, p.external_id) on
-- 2026-06-22 — NOT hand-ordered (143 lesson: the expected literal MUST match the query ORDER BY exactly).
DO $$
DECLARE v_uncovered TEXT;
DECLARE v_expected TEXT := '-3900003 Andy Wilson (OH/attorney_general); -4000002 Matt Pinnell (OK/lt_governor); -3900002 Jim Tressel (OH/lt_governor); -3100002 Joe Kelly (NE/lt_governor); -1900002 Chris Cournoyer (IA/lt_governor); -4500004 Mark Hammond (SC/secretary_of_state); -4600005 Josh Haeder (SD/treasurer); -2800005 David McRae (MS/treasurer); -2100005 Mark Metcalf (KY/treasurer); -100005 Young Boozer (AL/treasurer)';
BEGIN
  SELECT string_agg(p.external_id::text || ' ' || p.full_name || ' (' || d.state || '/' || o.role_canonical || ')', '; ' ORDER BY o.role_canonical, p.external_id)
  INTO v_uncovered
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_uncovered IS DISTINCT FROM v_expected THEN
    RAISE EXCEPTION 'SEXS-03-skip FAILED: in-scope-uncovered exec set should be exactly the 10 documented honest-skips, found: %', COALESCE(v_uncovered, '(none)');
  END IF;
  RAISE NOTICE 'SEXS-03-skip PASS: the 10 uncovered in-scope execs are exactly the documented whole-record honest-skips (1 AG + 1 SoS + 4 Treasurer + 4 LtGov)';
END $$;

-- ===== SEXS-03-unsourced: ZERO in-scope STATE_EXEC answer rows lack a paired context row with a real (http) source =====
DO $$
DECLARE v_un INT;
BEGIN
  SELECT count(*) INTO v_un
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN inform.politician_context c ON c.politician_id = pa.politician_id AND c.topic_id = pa.topic_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND (c.politician_id IS NULL OR c.sources IS NULL OR array_length(c.sources,1) < 1 OR c.sources[1] NOT LIKE 'http%');
  IF v_un <> 0 THEN
    RAISE EXCEPTION 'SEXS-03-unsourced FAILED: % in-scope STATE_EXEC answer row(s) lack an http-sourced paired context row', v_un;
  END IF;
  RAISE NOTICE 'SEXS-03-unsourced PASS: 0 in-scope STATE_EXEC answer rows lack a paired http-sourced context row';
END $$;

-- ===== SEXR-05 feed-surfacing smoke test =====
-- Replicates the production GET /representatives/me STATE_EXEC feed predicate (essentialsService.ts line ~706,
-- identical at ~1589): district_type='STATE_EXEC' AND d.state=$1 AND (p.is_active OR o.is_vacant) AND
-- COALESCE(p.is_incumbent,true). Narrowed to the Big-5 in-scope set. NC/WA/CO are NEWLY-SEEDED states
-- (zero STATE_EXEC records before v2.18); each must surface all 5 of its Big-5 execs incl. its seeded governor.

-- ===== SEXR-05-feed-A (NC): exactly 5 execs surface, incl. governor -3700001 (Josh Stein) =====
DO $$
DECLARE v_n INT; v_gov INT;
BEGIN
  SELECT count(*),
         count(*) FILTER (WHERE o.role_canonical='governor' AND p.external_id = -3700001)
  INTO v_n, v_gov
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE d.district_type='STATE_EXEC' AND d.state='NC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND (p.is_active=true OR o.is_vacant=true) AND COALESCE(p.is_incumbent,true)=true;
  IF v_n <> 5 OR v_gov <> 1 THEN
    RAISE EXCEPTION 'SEXR-05-feed-A FAILED: NC feed should surface 5 execs incl. governor -3700001, found % execs (gov match=%)', v_n, v_gov;
  END IF;
  RAISE NOTICE 'SEXR-05-feed-A PASS: NC surfaces 5 newly-seeded execs incl. governor -3700001 (Josh Stein)';
END $$;

-- ===== SEXR-05-feed-B (WA): exactly 5 execs surface, incl. governor -5300001 (Bob Ferguson) =====
DO $$
DECLARE v_n INT; v_gov INT;
BEGIN
  SELECT count(*),
         count(*) FILTER (WHERE o.role_canonical='governor' AND p.external_id = -5300001)
  INTO v_n, v_gov
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE d.district_type='STATE_EXEC' AND d.state='WA'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND (p.is_active=true OR o.is_vacant=true) AND COALESCE(p.is_incumbent,true)=true;
  IF v_n <> 5 OR v_gov <> 1 THEN
    RAISE EXCEPTION 'SEXR-05-feed-B FAILED: WA feed should surface 5 execs incl. governor -5300001, found % execs (gov match=%)', v_n, v_gov;
  END IF;
  RAISE NOTICE 'SEXR-05-feed-B PASS: WA surfaces 5 newly-seeded execs incl. governor -5300001 (Bob Ferguson)';
END $$;

-- ===== SEXR-05-feed-C (CO): exactly 5 execs surface, incl. governor -800001 (Jared Polis) =====
DO $$
DECLARE v_n INT; v_gov INT;
BEGIN
  SELECT count(*),
         count(*) FILTER (WHERE o.role_canonical='governor' AND p.external_id = -800001)
  INTO v_n, v_gov
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE d.district_type='STATE_EXEC' AND d.state='CO'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND (p.is_active=true OR o.is_vacant=true) AND COALESCE(p.is_incumbent,true)=true;
  IF v_n <> 5 OR v_gov <> 1 THEN
    RAISE EXCEPTION 'SEXR-05-feed-C FAILED: CO feed should surface 5 execs incl. governor -800001, found % execs (gov match=%)', v_n, v_gov;
  END IF;
  RAISE NOTICE 'SEXR-05-feed-C PASS: CO surfaces 5 newly-seeded execs incl. governor -800001 (Jared Polis)';
END $$;

-- If we reach here with no exception, all v2.18 assertions passed.
DO $$ BEGIN RAISE NOTICE 'verify-phase-141-144: ALL SEXR-01..05 + SEXS-03 ASSERTIONS PASSED'; END $$;

\echo '============================================================'
\echo 'v2.18 CONSOLIDATED gate complete — all assertions above PASS'
\echo '209 records (gov50/lt43/ag43/sos35/treas38); 199 stance-covered (gov50/ag42/sos34/treas34/lt39);'
\echo '10 documented honest-skips; 0 unsourced; NC/WA/CO feed each surfaces 5 execs.'
\echo 'AZ Lt Gov deferred (Prop 131, eff. Jan 2027) — known exclusion, not a miss.'
\echo '============================================================'
