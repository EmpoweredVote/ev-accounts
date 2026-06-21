-- verify-phase-141.sql
-- Phase gate for v2.18 (State Leaders) Phase 141: elected Big-5 statewide-exec roster lock + seed (records + headshots).
-- Labeled assertions for SEXR-01..04 + D-09/D-10. Read-only; RAISE EXCEPTION on failure, RAISE NOTICE on pass.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-141.sql
--
-- NOTE: This gate is authored in plan 141-01 (Wave 0) and is the Nyquist proof for the whole phase.
-- It will RAISE on SEXR-01/02 (count < 209) and SEXR-04 (missing headshots) UNTIL all seed batches
-- (plans 141-02..07) and headshot batches (141-08..12) have been applied. That is expected mid-phase.
-- The gate fully PASSES only at phase end.
--
-- ============================ THE 209-OFFICE DENOMINATOR ============================
-- In-scope = an office joined to a STATE_EXEC district with role_canonical IN
--   ('governor','lt_governor','attorney_general','secretary_of_state','treasurer').
-- Per-role breakdown (matrix-derived, 141-RESEARCH.md §"Validated 50-State Elected Big-5 Matrix"):
--   governor            = 50  (all 50 states popularly elect a governor)
--   lt_governor         = 43  (excl. ME/NH/OR/WY = office NONE; TN/WV = Senate-President not elected;
--                              AZ = DEFERRED, office not seated until Jan 2027 — documented exclusion)
--   attorney_general    = 43  (excl. AK/HI/NH/NJ/WY = appointed; ME = legislature; TN = Supreme-Court-appointed)
--   secretary_of_state  = 35  (excl. AK/HI/UT = office NONE; DE/FL/NJ/NY/OK/PA/TX/VA = appointed; ME/NH/TN = legislature)
--   treasurer           = 38  (50 - 12 excl: MN/MT abolished [2]; AK/GA/HI/MI/NJ/VA appointed [6];
--                              ME/MD/NH/TN legislature [4]. NY Comptroller + TX Comptroller + FL CFO ARE
--                              counted as treasurer per D-01; MD elected Comptroller is NOT — separate
--                              appointed Treasurer, D-02).
--   TOTAL               = 209
-- AZ seeding denominator is 4 now (Gov+AG+SoS+Treasurer); AZ LtGov added post-2026 election (future milestone).

\echo '============================================================'
\echo 'Phase 141 gate — elected Big-5 statewide-exec roster'
\echo '============================================================'

-- ===== SEXR-01: exactly 209 distinct in-scope (state, role_canonical) STATE_EXEC office pairs =====
DO $$
DECLARE v_pairs INT;
BEGIN
  SELECT COUNT(DISTINCT (d.state, o.role_canonical)) INTO v_pairs
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer');
  IF v_pairs <> 209 THEN
    RAISE EXCEPTION 'SEXR-01 FAILED: expected 209 distinct in-scope (state, role_canonical) STATE_EXEC pairs, found % (a missed backfill or seed shows here as < 209)', v_pairs;
  END IF;
  RAISE NOTICE 'SEXR-01 PASS: 209 distinct in-scope (state, role_canonical) STATE_EXEC office pairs';
END $$;

-- ===== SEXR-02: per-role counts match the matrix (50/43/43/35/38) =====
DO $$
DECLARE v_gov INT; v_lt INT; v_ag INT; v_sos INT; v_tre INT;
BEGIN
  SELECT
    COUNT(*) FILTER (WHERE o.role_canonical='governor'),
    COUNT(*) FILTER (WHERE o.role_canonical='lt_governor'),
    COUNT(*) FILTER (WHERE o.role_canonical='attorney_general'),
    COUNT(*) FILTER (WHERE o.role_canonical='secretary_of_state'),
    COUNT(*) FILTER (WHERE o.role_canonical='treasurer')
  INTO v_gov, v_lt, v_ag, v_sos, v_tre
  FROM (
    SELECT DISTINCT d.state, o.role_canonical
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type='STATE_EXEC'
      AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
  ) o;
  IF v_gov <> 50 OR v_lt <> 43 OR v_ag <> 43 OR v_sos <> 35 OR v_tre <> 38 THEN
    RAISE EXCEPTION 'SEXR-02 FAILED: per-role counts gov=%/50 lt=%/43 ag=%/43 sos=%/35 tre=%/38 (AZ LtGov absence is expected → 43 not 44)', v_gov, v_lt, v_ag, v_sos, v_tre;
  END IF;
  RAISE NOTICE 'SEXR-02 PASS: gov=50 lt=43 ag=43 sos=35 treasurer=38 (209 total)';
END $$;

-- ===== SEXR-03: no in-scope (state, role_canonical) pair is duplicated (dual-office / double-seed guard) =====
-- Catches the IN dual-office risk (Pitfall 2) and any accidental re-seed (D-09). A duplicated pair means
-- two offices claim the same state+role — exactly the failure mode the no-reseed guarantee must prevent.
DO $$
DECLARE v_dupes INT;
BEGIN
  SELECT COUNT(*) INTO v_dupes FROM (
    SELECT d.state, o.role_canonical, COUNT(*) AS n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type='STATE_EXEC'
      AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    GROUP BY d.state, o.role_canonical
    HAVING COUNT(*) > 1
  ) x;
  IF v_dupes <> 0 THEN
    RAISE EXCEPTION 'SEXR-03 FAILED: % in-scope (state, role_canonical) pairs are duplicated (double-seed or dual-office — D-09 violated)', v_dupes;
  END IF;
  RAISE NOTICE 'SEXR-03 PASS: no in-scope (state, role_canonical) pair duplicated';
  -- Secondary structural check: no phase-labeled Big-5 district (FIPS geo_id + Big-5 title) has a NULL-role office.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type='STATE_EXEC'
      AND d.geo_id ~ '^[0-9][0-9]$'
      AND (d.label ~* '(Governor|Attorney General|Secretary of State|Treasurer|Comptroller|Chief Financial Officer)')
      AND o.role_canonical IS NULL
      -- exclude documented out-of-scope labeled offices that legitimately stay NULL:
      AND d.label NOT IN ('Maryland Comptroller','Maryland State Treasurer','Utah State Auditor')
  ) THEN
    RAISE EXCEPTION 'SEXR-03 FAILED: a phase-labeled Big-5 STATE_EXEC district has an office with NULL role_canonical (missed backfill)';
  END IF;
  RAISE NOTICE 'SEXR-03 PASS (secondary): every phase-labeled Big-5 district office has role_canonical set';
END $$;

-- ===== SEXR-04: every NEWLY-SEEDED exec has a politician_images row (except documented honest-skips) =====
-- Newly-seeded set = the 41 empty states (external_id in the -(fips*100000+seq) range, i.e. <= -100001
-- AND a STATE_EXEC in-scope office) PLUS Indiana's two re-linked execs Morales (642977) + Elliott (688298),
-- which have POSITIVE external_ids. EXCLUDE Utah (-49000xx) and the 8 other pre-existing states — those are
-- existing records, not newly-seeded, and no headshot plan covers them (their headshot gaps are out of scope
-- for Phase 141). Scoped by the STATE_EXEC + role_canonical join, never by a bare external_id sign test.
DO $$
DECLARE v_missing INT; v_list TEXT;
BEGIN
  SELECT COUNT(*), string_agg(p.external_id::text || ' ' || p.full_name, ', ')
  INTO v_missing, v_list
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND (
      (p.external_id <= -100001 AND p.external_id NOT BETWEEN -4900009 AND -4900001)  -- 41 empty states, exclude UT
      OR p.external_id IN (642977, 688298)                                            -- IN Morales + Elliott
    )
    AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);
  IF v_missing <> 0 THEN
    -- Honest-skips (no portrait found after all sources) are documented in the relevant 141-08..12 SUMMARY.
    -- Until headshot batches run, this RAISES by design. Documented honest-skips are surfaced here for review.
    RAISE EXCEPTION 'SEXR-04 FAILED: % newly-seeded execs lack a politician_images row: %', v_missing, v_list;
  END IF;
  RAISE NOTICE 'SEXR-04 PASS: every newly-seeded exec has a headshot (or documented honest-skip)';
END $$;

-- ===== D-10a: no in-scope Big-5 STATE_EXEC district has a non-uppercase state code (223a lowercase trap) =====
DO $$
DECLARE v_bad INT;
BEGIN
  SELECT COUNT(DISTINCT d.id) INTO v_bad
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND d.state <> upper(d.state);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'D-10a FAILED: % in-scope Big-5 STATE_EXEC districts have a non-uppercase state code', v_bad;
  END IF;
  RAISE NOTICE 'D-10a PASS: all in-scope Big-5 STATE_EXEC districts have uppercase state codes';
END $$;

-- ===== D-10b: no in-scope Big-5 STATE_EXEC district has a NULL/empty geo_id =====
-- Scoped to districts that host at least one in-scope (role_canonical) office — this cleanly excludes the
-- legacy non-Big-5 shared districts ("Indiana" geo_id='', CA "Board of Equalization Member" geo_id='').
DO $$
DECLARE v_bad INT;
BEGIN
  SELECT COUNT(DISTINCT d.id) INTO v_bad
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
    AND (d.geo_id IS NULL OR d.geo_id = '');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'D-10b FAILED: % in-scope Big-5 STATE_EXEC districts have NULL/empty geo_id', v_bad;
  END IF;
  RAISE NOTICE 'D-10b PASS: all in-scope Big-5 STATE_EXEC districts have a non-empty FIPS geo_id';
END $$;

\echo '============================================================'
\echo 'Phase 141 gate complete — all assertions above PASS'
\echo '(headshot mechanism: essentials.politician_images.url, NOT photo_origin_url — confirmed migration 271)'
\echo '============================================================'
