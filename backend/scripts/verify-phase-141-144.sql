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

-- ===== SEXR-03-consolidated: role_canonical populated (non-NULL, Big-5 set) and no in-scope (state,role) duplicated =====
DO $$
DECLARE v_dup INT; v_null INT;
BEGIN
  SELECT count(*) INTO v_dup FROM (
    SELECT d.state, o.role_canonical
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type='STATE_EXEC'
      AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    GROUP BY d.state, o.role_canonical HAVING count(*) > 1
  ) dups;
  -- An in-scope office whose role_canonical is NULL is structurally excluded by the IN-list; this asserts the
  -- join key is populated for every STATE_EXEC office that carries one of the Big-5 role values.
  SELECT count(*) INTO v_null
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC' AND o.role_canonical IS NULL
    AND o.title IS NOT NULL
    AND o.title ~* '(governor|attorney general|secretary of state|treasurer|comptroller|chief financial)';
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'SEXR-03-consolidated FAILED: % in-scope (state,role_canonical) STATE_EXEC pair(s) duplicated', v_dup;
  END IF;
  IF v_null <> 0 THEN
    RAISE EXCEPTION 'SEXR-03-consolidated FAILED: % STATE_EXEC office(s) with a Big-5-looking title have NULL role_canonical', v_null;
  END IF;
  RAISE NOTICE 'SEXR-03-consolidated PASS: role_canonical populated, no in-scope (state,role) pair duplicated';
END $$;

-- ===== SEXR-04-consolidated: every newly-seeded exec has a politician_images.url headshot =====
-- Newly-seeded set = states NOT IN the 9 pre-existing STATE_EXEC states, OR the two re-linked IN positive ids.
DO $$
DECLARE v_missing INT;
BEGIN
  SELECT count(DISTINCT p.id) INTO v_missing
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
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
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF (v_gov, v_ag, v_sos, v_treas, v_lt) IS DISTINCT FROM (50, 42, 34, 34, 39) THEN
    RAISE EXCEPTION 'SEXS-03-coverage FAILED: expected gov=50/ag=42/sos=34/treas=34/lt=39 (199), found gov=%/ag=%/sos=%/treas=%/lt=%', v_gov, v_ag, v_sos, v_treas, v_lt;
  END IF;
  RAISE NOTICE 'SEXS-03-coverage PASS: 199 in-scope execs sourced (gov 50 / ag 42 / sos 34 / treas 34 / lt 39)';
END $$;
