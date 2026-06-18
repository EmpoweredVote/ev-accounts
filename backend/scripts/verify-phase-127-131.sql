-- verify-phase-127-131.sql
-- Consolidated phase gate for v2.16 (US House Rep Stances, Tier 2 — FL/NY/PA/IL).
-- Labeled assertions for USHS-01..05. Read-only; RAISE EXCEPTION on failure, RAISE NOTICE on pass.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-127-131.sql
--
-- In-scope reps = FL/NY/PA/IL US House, identified by external_id state-FIPS ranges:
--   FL (FIPS 12) = -12999..-12001   NY (FIPS 36) = -36999..-36001
--   PA (FIPS 42) = -42999..-42001   IL (FIPS 17) = -17999..-17001
-- Coverage = a rep with >=1 inform.politician_answers row. All 87 in-scope reps are covered,
-- so no rep-level honest-skip exemptions are needed (per-topic skips are expected and fine).

-- ===== USHS-01 (FL): all 27 FL House reps have >=1 sourced stance =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -12999 AND -12001
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 27 THEN
    RAISE EXCEPTION 'USHS-01 FAILED: expected 27 FL reps with stances, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-01 PASS: 27/27 FL House reps have sourced stances';
END $$;

-- ===== USHS-02 (NY): all 26 NY House reps have >=1 sourced stance =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -36999 AND -36001
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 26 THEN
    RAISE EXCEPTION 'USHS-02 FAILED: expected 26 NY reps with stances, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-02 PASS: 26/26 NY House reps have sourced stances';
END $$;

-- ===== USHS-03 (PA): all 17 PA House reps have >=1 sourced stance =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -42999 AND -42001
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 17 THEN
    RAISE EXCEPTION 'USHS-03 FAILED: expected 17 PA reps with stances, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-03 PASS: 17/17 PA House reps have sourced stances';
END $$;

-- ===== USHS-04 (IL): all 17 IL House reps have >=1 sourced stance =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE p.external_id BETWEEN -17999 AND -17001
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 17 THEN
    RAISE EXCEPTION 'USHS-04 FAILED: expected 17 IL reps with stances, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-04 PASS: 17/17 IL House reps have sourced stances';
END $$;

-- ===== USHS-05 (a): combined in-scope coverage = 87 reps =====
DO $$
DECLARE v_covered INT;
BEGIN
  SELECT COUNT(*) INTO v_covered FROM essentials.politicians p
  WHERE (p.external_id BETWEEN -12999 AND -12001
      OR p.external_id BETWEEN -36999 AND -36001
      OR p.external_id BETWEEN -42999 AND -42001
      OR p.external_id BETWEEN -17999 AND -17001)
    AND EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_covered <> 87 THEN
    RAISE EXCEPTION 'USHS-05a FAILED: expected 87 in-scope reps covered, found %', v_covered;
  END IF;
  RAISE NOTICE 'USHS-05a PASS: 87/87 in-scope FL/NY/PA/IL House reps covered';
END $$;

-- ===== USHS-05 (b): ZERO in-scope answers lack a paired context row with a real (http) source =====
DO $$
DECLARE v_unsourced INT;
BEGIN
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE (p.external_id BETWEEN -12999 AND -12001
      OR p.external_id BETWEEN -36999 AND -36001
      OR p.external_id BETWEEN -42999 AND -42001
      OR p.external_id BETWEEN -17999 AND -17001)
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = pa.politician_id
        AND pc.topic_id = pa.topic_id
        AND pc.sources IS NOT NULL
        AND array_length(pc.sources, 1) >= 1
        AND pc.sources[1] LIKE 'http%'
    );
  IF v_unsourced <> 0 THEN
    RAISE EXCEPTION 'USHS-05b FAILED: % in-scope answer row(s) lack a real-sourced context row', v_unsourced;
  END IF;
  RAISE NOTICE 'USHS-05b PASS: 0 in-scope answers lack a paired context row with a real (http) source';
END $$;

-- If we reach here with no exception, all v2.16 assertions passed.
DO $$ BEGIN RAISE NOTICE 'verify-phase-127-131: ALL USHS-01..05 ASSERTIONS PASSED'; END $$;
