-- 154-verify.sql — Phase 154 read-only PRE-SEEDING baseline gate (USHC2-01).
--
-- SELECT-only. This is a DIAGNOSTIC pre-seeding gate (RESEARCH §Pattern 3), NOT a
-- post-seeding candidate gate like 149-verify.sql. It asserts the read-only DB
-- baseline that the Wave-2 seeding phases (155/156/157/159) build on:
--   A1 — per-state NATIONAL_LOWER district counts: PA 17 / IL 17 / OH 15 / GA 14 /
--        NC 14 / MI 13 / NJ 12 / VA 11 = 113 total.
--   A2 — 0 race_candidates seeded on ANY 2026-11-03 Wave-2 US House race (no candidate
--        data exists yet anywhere). Wave-1 baseline finding: VA's 11 House races are
--        ALREADY scaffolded (0 candidates each) under "2026 Virginia General Election";
--        the other 7 states have 0 races. So A2 asserts the candidate-level invariant
--        (0 race_candidates) AND the race split (exactly 11 races, all VA; 0 non-VA).
--   A3 — holder invariant: every NATIONAL_LOWER district in the 8 states has exactly
--        1 incumbent holder EXCEPT the expected 0-holder special seat(s). Per the
--        live Wave-1 diagnostic (154-incumbent-map.csv) the ONLY 0-holder is
--        GA-13 ('1313'); GA-14 (Fuller), NJ-11 (Mejia) and VA-11 (Walkinshaw) are
--        already correctly seeded 1-holder incumbents. Assert the set of non-1-holder
--        districts equals exactly {'1313'} (no surprises in either direction).
--
-- INTENTIONALLY ABSENT: any assertion about MI or VA 2026 nominees / race_candidates.
-- Both MI and VA hold their congressional primaries on Aug 4, 2026, so their Nov-3
-- fields are not knowable yet (CONTEXT D-01; RESEARCH Pitfall 1). Asserting an MI/VA
-- decided field here would false-fail. MI+VA are seeded + gated in the date-gated
-- Phase 159, not here. This gate makes NO reference to race_candidates for any state.
--
-- WRITE-FREE: no INSERT/UPDATE/DELETE into essentials|inform. The only writes are
--   `CREATE TEMP TABLE ... ON COMMIT DROP` for diffing (149/148-verify.sql precedent).
--   SELECT-only against production; never `--commit`.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/154-verify.sql
--
-- Wave-2 FIPS: PA 42 / IL 17 / OH 39 / GA 13 / NC 37 / MI 26 / NJ 34 / VA 51.
-- Join path: races.election_id -> elections.id; races.office_id -> offices.id;
--            offices.district_id -> districts.id; district geo via districts.geo_id.

\set ON_ERROR_STOP on

DO $$
DECLARE
  v_total      int;
  v_mismatch   text;
  v_rc_seeded  int;
  v_va_races   int;
  v_nonva_races int;
  v_diff       text;
BEGIN
  -- ==========================================================================
  -- A1 — per-state NATIONAL_LOWER district counts (expected 113 total).
  -- ==========================================================================
  CREATE TEMP TABLE _expected_counts (fips text, st text, n int) ON COMMIT DROP;
  INSERT INTO _expected_counts (fips, st, n) VALUES
    ('42','PA',17), ('17','IL',17), ('39','OH',15), ('13','GA',14),
    ('37','NC',14), ('26','MI',13), ('34','NJ',12), ('51','VA',11);

  CREATE TEMP TABLE _actual_counts ON COMMIT DROP AS
  SELECT substr(d.geo_id,1,2) AS fips, COUNT(*) AS n
  FROM essentials.districts d
  WHERE d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN (SELECT fips FROM _expected_counts)
  GROUP BY substr(d.geo_id,1,2);

  SELECT string_agg(e.st || ' expected ' || e.n || ' got ' || COALESCE(a.n,0), ', ' ORDER BY e.st)
    INTO v_mismatch
  FROM _expected_counts e
  LEFT JOIN _actual_counts a ON a.fips = e.fips
  WHERE COALESCE(a.n,0) <> e.n;
  IF v_mismatch IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL A1: per-state NATIONAL_LOWER district count mismatch: %', v_mismatch;
  END IF;

  SELECT COALESCE(SUM(n),0) INTO v_total FROM _actual_counts;
  IF v_total <> 113 THEN
    RAISE EXCEPTION 'FAIL A1: expected 113 total Wave-2 NATIONAL_LOWER districts, got %', v_total;
  END IF;
  RAISE NOTICE 'PASS A1: 8-state NATIONAL_LOWER district counts = 113 (PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / MI 13 / NJ 12 / VA 11)';

  -- ==========================================================================
  -- A2 — pre-seeding candidate invariant + VA race-scaffold split.
  -- The thing that MUST hold before seeding: NO candidates are wired yet on any
  -- 2026-11-03 Wave-2 House race (else duplicate-candidate risk). VA's 11 races
  -- already exist (scaffold, 0 candidates) and the other 7 states have 0 races.
  -- ==========================================================================
  -- A2a — 0 race_candidates on any 2026-11-03 Wave-2 House race.
  SELECT COUNT(*) INTO v_rc_seeded
  FROM essentials.race_candidates rc
  JOIN essentials.races r      ON r.id = rc.race_id
  JOIN essentials.elections el ON el.id = r.election_id
  JOIN essentials.offices o    ON o.id = r.office_id
  JOIN essentials.districts d  ON d.id = o.district_id
  WHERE el.election_date = DATE '2026-11-03'
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN (SELECT fips FROM _expected_counts);
  IF v_rc_seeded <> 0 THEN
    RAISE EXCEPTION 'FAIL A2a: expected 0 race_candidates on 2026-11-03 Wave-2 House races (none seeded yet), got %', v_rc_seeded;
  END IF;

  -- A2b — exactly 11 pre-scaffolded 2026-11-03 Wave-2 House races, all VA ('51'); 0 non-VA.
  SELECT
    COUNT(*) FILTER (WHERE substr(d.geo_id,1,2) = '51'),
    COUNT(*) FILTER (WHERE substr(d.geo_id,1,2) <> '51')
    INTO v_va_races, v_nonva_races
  FROM essentials.races r
  JOIN essentials.elections el ON el.id = r.election_id
  JOIN essentials.offices o    ON o.id = r.office_id
  JOIN essentials.districts d  ON d.id = o.district_id
  WHERE el.election_date = DATE '2026-11-03'
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN (SELECT fips FROM _expected_counts);
  IF v_nonva_races <> 0 THEN
    RAISE EXCEPTION 'FAIL A2b: expected 0 pre-seeded non-VA 2026-11-03 Wave-2 House races, got % (PA/IL/OH/GA/NC/NJ/MI races are authored during seeding)', v_nonva_races;
  END IF;
  IF v_va_races <> 11 THEN
    RAISE EXCEPTION 'FAIL A2b: expected exactly 11 pre-scaffolded VA House races, got % (field table existing_race_id pins all 11)', v_va_races;
  END IF;
  RAISE NOTICE 'PASS A2: 0 race_candidates seeded on any Wave-2 House race; 11 VA races pre-scaffolded (reuse in Phase 159), 0 non-VA races (authored during seeding)';

  -- ==========================================================================
  -- A3 — holder invariant: non-1-holder districts must equal exactly the expected
  --      0-holder special-seat set {'1313'} (GA-13). Per the live Wave-1 diagnostic,
  --      GA-14/NJ-11/VA-11 are already 1-holder seeded incumbents (NOT vacant).
  -- ==========================================================================
  CREATE TEMP TABLE _expected_vacant (geo_id text) ON COMMIT DROP;
  INSERT INTO _expected_vacant (geo_id) VALUES ('1313');  -- GA-13 (David Scott deceased Apr 2026)

  CREATE TEMP TABLE _actual_nonone ON COMMIT DROP AS
  SELECT d.geo_id
  FROM essentials.districts d
  LEFT JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN (SELECT fips FROM _expected_counts)
  GROUP BY d.geo_id
  HAVING COUNT(o.politician_id) <> 1;

  -- Symmetric difference: any actual-not-expected (surprise vacancy/anomaly) OR
  -- any expected-not-actual (special seat unexpectedly filled) fails the invariant.
  SELECT string_agg(geo_id || ':' || src, ', ' ORDER BY geo_id)
    INTO v_diff
  FROM (
    SELECT geo_id, 'unexpected-non-1-holder' AS src FROM _actual_nonone
    WHERE geo_id NOT IN (SELECT geo_id FROM _expected_vacant)
    UNION ALL
    SELECT geo_id, 'expected-vacant-now-filled' AS src FROM _expected_vacant
    WHERE geo_id NOT IN (SELECT geo_id FROM _actual_nonone)
  ) q;
  IF v_diff IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL A3: holder-invariant mismatch vs expected 0-holder set {1313}: %', v_diff;
  END IF;
  RAISE NOTICE 'PASS A3: non-1-holder districts = exactly {1313} (GA-13 vacant); all other 112 districts have exactly 1 incumbent holder';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (154 baseline)';
END $$;
