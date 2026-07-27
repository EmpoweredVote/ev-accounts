-- 160-verify.sql — Phase 160 read-only PRE-SEEDING baseline gate (USHC3-01).
--
-- ⚠ HISTORICALLY OBSOLETE AS A WHOLE-FILE RUN (noted 2026-07-26). A2 asserts the pre-seeding race
--   baseline — including "the other 33 states have 0 pre-seeded 2026-11-03 races" — which was true
--   when this gate was authored and is PERMANENTLY FALSE now that Wave-3 seeding (161-165) shipped;
--   a live run stops at `FAIL A2b ... got 144`. That is the gate doing its job on a premise that has
--   since expired, NOT a defect. Do not "fix" A2 by relaxing it; the post-seeding gate for these
--   178 districts is backend/scripts/166-verify.sql. A1 and A3 remain live-meaningful standalone.
--
-- OCCUPANCY PORT (2026-07-26): A3 previously read essentials.offices.politician_id, dropped by
--   ADR 0002 phase 5 / migration 1463, so it was broken at runtime. It now resolves occupancy
--   through essentials.office_current_holder. Verified standalone against prod on 2026-07-26:
--   the Wave-3-scoped A3 returns empty, matching its expectation of no non-1-holder district.
--
-- SELECT-only. This is a DIAGNOSTIC pre-seeding gate (RESEARCH §Pattern 3), NOT a
-- post-seeding candidate gate like 149/152-verify.sql. It asserts the read-only DB
-- baseline that the Wave-3 seeding phases (161/162/163/164/165) build on:
--   A1 — per-state NATIONAL_LOWER district counts: all 38 Wave-3 states = 178 total.
--   A2 — the DISCOVERED 29-race pre-existing baseline (ME 2 / MD 8 / MA 9 / NV 4 /
--        OR 6), NOT a blanket 0-races claim like Phase 154's A2. The ROADMAP's
--        "none of the 38 states have pre-seeded 2026 House races" assumption is
--        FALSE for these 5 states (RESEARCH.md Critical Finding 4, confirmed live
--        via 160-race-preexistence-audit.csv). This gate asserts (a) those 5
--        states' 2026-11-03 NATIONAL_LOWER race counts sum to exactly 29, (b) the
--        other 33 states have 0 pre-seeded 2026-11-03 races, and (c) the
--        race_candidates counts match the discovered baseline: NV=9 (all 4
--        incumbents + 5 challengers, essentially complete already), MA=2
--        (Clark MA-5 + Pressley MA-7, get-ahead placeholders), ME=2 (Pingree
--        ME-1 + LePage ME-2 general rows — the 8 stale June-9-primary rows are
--        excluded by the 2026-11-03 election_date filter), MD=0, OR=0 (races
--        scaffolded, empty). Do NOT assert a blanket 0-candidate claim.
--   A3 — holder invariant: every one of the 178 NATIONAL_LOWER districts has
--        exactly 1 incumbent holder. Wave-3's live diagnostic (Query C) returned
--        0 rows — there is NO known expected-vacant special seat this session
--        (unlike Wave-2's GA-13) — so the expected-vacant set is EMPTY and this
--        assertion fails on ANY district without exactly 1 holder.
--
-- INTENTIONALLY ABSENT: any assertion forcing a specific general-ballot nominee
-- for the 90 late-primary districts (their fields are not knowable yet — resolved
-- per-district in the owning seeding phase, not here) and any assertion about the
-- 16 negative-external_id collisions found in 160-negative-id-audit.csv (that
-- finding is informational only — reported via RAISE NOTICE, never a hard gate
-- failure; collisions are handled by seeding-time live-checks, not this baseline).
--
-- WRITE-FREE: no INSERT/UPDATE/DELETE into essentials|inform. The only writes are
--   `CREATE TEMP TABLE ... ON COMMIT DROP` for diffing (149/148/154-verify.sql precedent).
--   SELECT-only against production; never `--commit`.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/160-verify.sql
--
-- Wave-3 FIPS (38 states): WA53 AZ04 TN47 MA25 IN18 MD24 MN27 MO29 WI55 CO08 AL01
--   SC45 LA22 KY21 OR41 CT09 OK40 AR05 IA19 KS20 MS28 NV32 UT49 NM35 NE31 WV54
--   ID16 HI15 ME23 NH33 RI44 MT30 AK02 DE10 ND38 SD46 VT50 WY56.
-- Join path: races.office_id -> offices.id; offices.district_id -> districts.id;
--            races.election_id -> elections.id; district geo via districts.geo_id.

\set ON_ERROR_STOP on

DO $$
DECLARE
  v_total        int;
  v_mismatch     text;
  v_race_mismatch text;
  v_nonexpected_races int;
  v_cand_mismatch text;
  v_diff         text;
BEGIN
  -- ==========================================================================
  -- A1 — per-state NATIONAL_LOWER district counts (expected 178 total, 38 states).
  -- ==========================================================================
  CREATE TEMP TABLE _expected_counts (fips text, st text, n int) ON COMMIT DROP;
  INSERT INTO _expected_counts (fips, st, n) VALUES
    ('53','WA',10), ('04','AZ',9), ('47','TN',9), ('25','MA',9), ('18','IN',9),
    ('24','MD',8), ('27','MN',8), ('29','MO',8), ('55','WI',8), ('08','CO',8),
    ('01','AL',7), ('45','SC',7), ('22','LA',6), ('21','KY',6), ('41','OR',6),
    ('09','CT',5), ('40','OK',5), ('05','AR',4), ('19','IA',4), ('20','KS',4),
    ('28','MS',4), ('32','NV',4), ('49','UT',4), ('35','NM',3), ('31','NE',3),
    ('54','WV',2), ('16','ID',2), ('15','HI',2), ('23','ME',2), ('33','NH',2),
    ('44','RI',2), ('30','MT',2), ('02','AK',1), ('10','DE',1), ('38','ND',1),
    ('46','SD',1), ('50','VT',1), ('56','WY',1);

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
  IF v_total <> 178 THEN
    RAISE EXCEPTION 'FAIL A1: expected 178 total Wave-3 NATIONAL_LOWER districts, got %', v_total;
  END IF;
  RAISE NOTICE 'PASS A1: 38-state NATIONAL_LOWER district counts = 178';

  -- ==========================================================================
  -- A2 — DISCOVERED pre-existing-race baseline (NOT a blanket 0-races claim).
  -- ME/MD/MA/NV/OR already have 2026-11-03 NATIONAL_LOWER races scaffolded
  -- (RESEARCH.md Critical Finding 4). Assert the exact per-state race counts,
  -- 0 pre-seeded races for the other 33 states, and the discovered
  -- race_candidates counts (NV=9, MA=2, ME=2; MD=0, OR=0).
  -- ==========================================================================
  CREATE TEMP TABLE _expected_races (fips text, st text, n int) ON COMMIT DROP;
  INSERT INTO _expected_races (fips, st, n) VALUES
    ('23','ME',2), ('24','MD',8), ('25','MA',9), ('32','NV',4), ('41','OR',6);

  -- A2a — the 5 states' 2026-11-03 NATIONAL_LOWER race counts match the discovered
  -- baseline exactly (sum 29).
  CREATE TEMP TABLE _actual_races ON COMMIT DROP AS
  SELECT substr(d.geo_id,1,2) AS fips, COUNT(DISTINCT r.id) AS n
  FROM essentials.races r
  JOIN essentials.elections el ON el.id = r.election_id
  JOIN essentials.offices o    ON o.id = r.office_id
  JOIN essentials.districts d  ON d.id = o.district_id
  WHERE el.election_date = DATE '2026-11-03'
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN (SELECT fips FROM _expected_counts)
  GROUP BY substr(d.geo_id,1,2);

  SELECT string_agg(e.st || ' expected ' || e.n || ' got ' || COALESCE(a.n,0), ', ' ORDER BY e.st)
    INTO v_race_mismatch
  FROM _expected_races e
  LEFT JOIN _actual_races a ON a.fips = e.fips
  WHERE COALESCE(a.n,0) <> e.n;
  IF v_race_mismatch IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL A2a: discovered pre-existing-race baseline mismatch (ME2/MD8/MA9/NV4/OR6): %', v_race_mismatch;
  END IF;

  -- A2b — the other 33 states have 0 pre-seeded 2026-11-03 NATIONAL_LOWER races.
  SELECT COALESCE(SUM(a.n),0) INTO v_nonexpected_races
  FROM _actual_races a
  WHERE a.fips NOT IN (SELECT fips FROM _expected_races);
  IF v_nonexpected_races <> 0 THEN
    RAISE EXCEPTION 'FAIL A2b: expected 0 pre-seeded 2026-11-03 races for the other 33 Wave-3 states, got %', v_nonexpected_races;
  END IF;
  RAISE NOTICE 'PASS A2a/A2b: discovered 29-race baseline confirmed (ME2/MD8/MA9/NV4/OR6); 0 pre-seeded races for the other 33 states';

  -- A2c — race_candidates counts on those 2026-11-03 races match the discovered
  -- baseline: NV=9, MA=2, ME=2 (general only — the 8 stale June-9-primary ME rows
  -- are on a different election_date and correctly excluded); MD=0, OR=0.
  CREATE TEMP TABLE _expected_cands (fips text, st text, n int) ON COMMIT DROP;
  INSERT INTO _expected_cands (fips, st, n) VALUES
    ('23','ME',2), ('24','MD',0), ('25','MA',2), ('32','NV',9), ('41','OR',0);

  CREATE TEMP TABLE _actual_cands ON COMMIT DROP AS
  SELECT substr(d.geo_id,1,2) AS fips, COUNT(rc.id) AS n
  FROM essentials.races r
  JOIN essentials.elections el ON el.id = r.election_id
  JOIN essentials.offices o    ON o.id = r.office_id
  JOIN essentials.districts d  ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  WHERE el.election_date = DATE '2026-11-03'
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN (SELECT fips FROM _expected_races)
  GROUP BY substr(d.geo_id,1,2);

  SELECT string_agg(e.st || ' expected ' || e.n || ' got ' || COALESCE(a.n,0), ', ' ORDER BY e.st)
    INTO v_cand_mismatch
  FROM _expected_cands e
  LEFT JOIN _actual_cands a ON a.fips = e.fips
  WHERE COALESCE(a.n,0) <> e.n;
  IF v_cand_mismatch IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL A2c: discovered race_candidates baseline mismatch (NV=9/MA=2/ME=2/MD=0/OR=0): %', v_cand_mismatch;
  END IF;
  RAISE NOTICE 'PASS A2c: race_candidates baseline confirmed (NV=9, MA=2, ME=2 general, MD=0, OR=0) — not a blanket 0-candidate claim';

  -- ==========================================================================
  -- A3 — holder invariant: EVERY one of the 178 NATIONAL_LOWER districts has
  -- exactly 1 incumbent holder. Wave-3's live diagnostic found no expected
  -- vacancy this session (unlike Wave-2's GA-13) — the expected-vacant set is
  -- EMPTY, so this assertion fails on ANY district without exactly 1 holder.
  -- ==========================================================================
  -- Occupancy is resolved at read time through essentials.office_current_holder (ADR 0002).
  -- This block previously counted essentials.offices.politician_id, dropped by ADR 0002 phase 5 /
  -- migration 1463, which left this gate broken at runtime. The view is exactly one row per
  -- office (guaranteed by office_terms' exclusion constraint), so it cannot fan the group out,
  -- and COUNT() skips the NULL politician_id a vacancy span carries.
  CREATE TEMP TABLE _actual_nonone ON COMMIT DROP AS
  SELECT d.geo_id
  FROM essentials.districts d
  LEFT JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN (SELECT fips FROM _expected_counts)
  GROUP BY d.geo_id
  HAVING COUNT(och.politician_id) <> 1;

  SELECT string_agg(geo_id, ', ' ORDER BY geo_id) INTO v_diff FROM _actual_nonone;
  IF v_diff IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL A3: expected 0 non-1-holder districts (no known Wave-3 vacancy this session), got: %', v_diff;
  END IF;
  RAISE NOTICE 'PASS A3: all 178 NATIONAL_LOWER districts have exactly 1 incumbent holder (no vacancies)';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (160 baseline)';
END $$;
