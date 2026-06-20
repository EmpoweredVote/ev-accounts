-- verify-phase-132-140.sql
-- Consolidated phase gate for v2.17 (US House Rep Stances, Tier 2 continuation — the remaining 38 states).
-- Labeled assertions for USHS-06..14. Read-only; RAISE EXCEPTION on failure, RAISE NOTICE on pass.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-132-140.sql
--
-- In-scope reps = the v2.17 set: essentials.politicians with external_id BETWEEN -56999 AND -1000
-- whose state FIPS = floor((-external_id)/1000) falls in the 38 states covered by phases 132-139.
-- The full national House set in this range = 299 seeded = v2.16's 87 (FL/NY/PA/IL) + v2.17's 212,
-- so per-state-FIPS counts are clean (no cross-milestone contamination).
-- Coverage = a rep with >=1 inform.politician_answers row.
--
-- ONE DOCUMENTED EXEMPTION: Addison McDowell (NC-6, external_id -37006) is a Phase-132 honest-skip —
-- a brand-new freshman with no documentable record (recorded in 132-VERIFICATION.md). He is the single
-- uncovered in-scope rep BY DESIGN, so OH+NC coverage is 28/29 and the v2.17 total is 211/212 covered.
-- USHS-14a pins the sole gap to exactly -37006 so any OTHER missing rep fails loudly.
-- Per-topic honest-skips (a covered rep lacking some topics) are expected and fine.

-- ===== USHS-06 (OH+NC): 28 of 29 reps covered (McDowell -37006 documented honest-skip) =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN (39, 37)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 28 THEN
    RAISE EXCEPTION 'USHS-06 FAILED: expected 28 OH+NC reps covered (29 seeded minus McDowell -37006 honest-skip), found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-06 PASS: 28/29 OH+NC House reps covered (McDowell NC-6 -37006 = documented honest-skip)';
END $$;

-- ===== USHS-07 (GA+MI): all 26 reps covered =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN (13, 26)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 26 THEN
    RAISE EXCEPTION 'USHS-07 FAILED: expected 26 GA+MI reps covered, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-07 PASS: 26/26 GA+MI House reps covered';
END $$;

-- ===== USHS-08 (NJ+WA+AZ): all 31 reps covered =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN (34, 53, 4)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 31 THEN
    RAISE EXCEPTION 'USHS-08 FAILED: expected 31 NJ+WA+AZ reps covered, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-08 PASS: 31/31 NJ+WA+AZ House reps covered';
END $$;

-- ===== USHS-09 (TN+CO+MN+MO): all 33 reps covered =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN (47, 8, 27, 29)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 33 THEN
    RAISE EXCEPTION 'USHS-09 FAILED: expected 33 TN+CO+MN+MO reps covered, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-09 PASS: 33/33 TN+CO+MN+MO House reps covered';
END $$;

-- ===== USHS-10 (WI+AL+SC+KY): all 28 reps covered =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN (55, 1, 45, 21)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 28 THEN
    RAISE EXCEPTION 'USHS-10 FAILED: expected 28 WI+AL+SC+KY reps covered, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-10 PASS: 28/28 WI+AL+SC+KY House reps covered';
END $$;

-- ===== USHS-11 (LA+CT+IN+OK+AR+IA): all 29 reps covered =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN (22, 9, 18, 40, 5, 19)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 29 THEN
    RAISE EXCEPTION 'USHS-11 FAILED: expected 29 LA+CT+IN+OK+AR+IA reps covered, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-11 PASS: 29/29 LA+CT+IN+OK+AR+IA House reps covered';
END $$;

-- ===== USHS-12 (KS+MS+NV+NE+NM): all 18 reps covered =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN (20, 28, 32, 31, 35)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 18 THEN
    RAISE EXCEPTION 'USHS-12 FAILED: expected 18 KS+MS+NV+NE+NM reps covered, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-12 PASS: 18/18 KS+MS+NV+NE+NM House reps covered';
END $$;

-- ===== USHS-13 (single/low-rep states): all 18 reps covered =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN (15, 16, 30, 33, 44, 54, 2, 10, 38, 46, 50, 56)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 18 THEN
    RAISE EXCEPTION 'USHS-13 FAILED: expected 18 single/low-rep-state reps covered, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-13 PASS: 18/18 single/low-rep-state House reps covered (HI/ID/MT/NH/RI/WV + AK/DE/ND/SD/VT/WY)';
END $$;

-- ===== USHS-14a: consolidated coverage = 211/212, and the SOLE uncovered rep is exactly -37006 =====
DO $$
DECLARE v_covered INT; v_other_uncovered INT;
BEGIN
  -- 38-state v2.17 in-scope set
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN
      (1,2,4,5,8,9,10,13,15,16,18,19,20,21,22,26,27,28,29,30,31,32,33,34,35,37,38,39,40,44,45,46,47,50,53,54,55,56)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 211 THEN
    RAISE EXCEPTION 'USHS-14a FAILED: expected 211 in-scope reps covered (212 minus McDowell -37006), found %', v_covered;
  END IF;
  -- any in-scope rep WITHOUT answers other than the documented honest-skip -37006 is a regression
  SELECT COUNT(*) INTO v_other_uncovered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN
      (1,2,4,5,8,9,10,13,15,16,18,19,20,21,22,26,27,28,29,30,31,32,33,34,35,37,38,39,40,44,45,46,47,50,53,54,55,56)
    AND p.external_id <> -37006
    AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_other_uncovered <> 0 THEN
    RAISE EXCEPTION 'USHS-14a FAILED: % in-scope rep(s) other than McDowell -37006 lack stances', v_other_uncovered;
  END IF;
  RAISE NOTICE 'USHS-14a PASS: 211/212 in-scope v2.17 reps covered; sole gap = McDowell NC-6 (-37006), the documented honest-skip';
END $$;

-- ===== USHS-14b: ZERO in-scope answers lack a paired context row with a real (http) source =====
DO $$
DECLARE v_unsourced INT;
BEGIN
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND floor((-p.external_id)/1000) IN
      (1,2,4,5,8,9,10,13,15,16,18,19,20,21,22,26,27,28,29,30,31,32,33,34,35,37,38,39,40,44,45,46,47,50,53,54,55,56)
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = pa.politician_id
        AND pc.topic_id = pa.topic_id
        AND pc.sources IS NOT NULL
        AND array_length(pc.sources, 1) >= 1
        AND pc.sources[1] LIKE 'http%'
    );
  IF v_unsourced <> 0 THEN
    RAISE EXCEPTION 'USHS-14b FAILED: % in-scope answer row(s) lack a real-sourced context row', v_unsourced;
  END IF;
  RAISE NOTICE 'USHS-14b PASS: 0 in-scope answers lack a paired context row with a real (http) source';
END $$;

-- If we reach here with no exception, all v2.17 assertions passed.
DO $$ BEGIN RAISE NOTICE 'verify-phase-132-140: ALL USHS-06..14 ASSERTIONS PASSED'; END $$;
