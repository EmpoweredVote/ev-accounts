-- 1571_wi_supreme_court_bradley_out_taylor_in.sql
--
-- Flip the incumbency flags on the Wisconsin Supreme Court seat that changed hands on 2026-08-01:
-- Rebecca Bradley out, Chris Taylor in. Both people and both terms are already correct in the data;
-- only the two `is_incumbent` booleans are stale.
--
--   Found by: the seeded-councillor sweep (data/stance-research/seeded-roster-sweep/FINDINGS.md)
--   Rollback: UPDATE essentials.politicians SET is_incumbent = true
--              WHERE external_id = -5530003;                       -- Rebecca Bradley
--             UPDATE essentials.politicians SET is_incumbent = false
--              WHERE external_id = -5530008;                       -- Chris Taylor
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1571_wi_supreme_court_bradley_out_taylor_in.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- HOW A ROSTER-COUNT CHECK FOUND A DATE PROBLEM
-- ---------------------------------------------------------------------------------------------------
-- The sweep compared every seeded chamber's occupant count against `chambers.official_count`. Of 20
-- mismatches, 19 were NEGATIVE — partially seeded rosters, a coverage gap, not a fabrication. A
-- fabricated extra person shows a POSITIVE delta, and there was exactly one worth reading:
--
--     Wisconsin Supreme Court — official_count 7, seated 8.
--
-- All eight are real justices. The eighth is a handoff that has already happened:
--   * Rebecca Grassl Bradley — term_start 2016-08-01, term_end 2026-07-31, is_incumbent TRUE
--   * Chris Taylor          — term_start 2026-08-01, term_end 2036-07-31, is_incumbent FALSE
--
-- Taylor won on 2026-04-07 and was sworn in 2026-08-01, succeeding Bradley, who did not seek
-- re-election (wicourts.gov Third Branch eNews, April 2026; WPR and Wisconsin Examiner, 2026-04-07).
-- Today is 2026-08-06, so the flags are five days stale and they disagree with the term dates.
--
-- 🔴 WHY THIS IS VOTER-FACING, NOT COSMETIC. Occupancy is a TWO-GATE model — `term_end` AND
-- `is_incumbent`. Under it, Bradley is excluded by her date gate but Taylor is ALSO excluded, by his
-- flag. Wisconsin's newest justice can therefore be invisible while the seat reads as empty or as
-- still hers, depending on which gate a given query applies. This is the Beverly Hills / Mirisch shape
-- again: a handoff that passed without the flags being flipped.
--
-- 🔑 GENERALISABLE: a seat-count check is a cheap detector for BOTH defects it was not designed for —
-- fabricated extra people (positive delta) and stale handoffs (positive delta). Negative deltas are a
-- different finding entirely and must not be read as either.
--
-- ⚠ This migration touches NO stance data. Neither justice holds any compass answers, asserted below.
-- ===================================================================================================

BEGIN;

DO $$
DECLARE v_cnt int;
BEGIN
  -- Both people are who we think they are, on the seat we think, with the terms we read.
  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE external_id = -5530003 AND full_name = 'Rebecca Bradley' AND is_incumbent = true;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'PRE: Rebecca Bradley not as expected (found %)', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE external_id = -5530008 AND full_name = 'Chris Taylor' AND is_incumbent = false;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'PRE: Chris Taylor not as expected (found %)', v_cnt; END IF;

  -- The handoff has actually passed. If this fires, the migration is being run too early.
  SELECT count(*) INTO v_cnt
  FROM essentials.office_terms ot
  JOIN essentials.politicians p ON p.id = ot.politician_id
  WHERE p.external_id = -5530003 AND ot.term_end < CURRENT_DATE;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'PRE: Bradley term_end is not in the past'; END IF;

  SELECT count(*) INTO v_cnt
  FROM essentials.office_terms ot
  JOIN essentials.politicians p ON p.id = ot.politician_id
  WHERE p.external_id = -5530008 AND ot.term_start <= CURRENT_DATE;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'PRE: Taylor term_start has not arrived'; END IF;

  -- No stance data is at stake.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers a
   JOIN essentials.politicians p ON p.id = a.politician_id
   WHERE p.external_id IN (-5530003, -5530008);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: % compass answers on these justices — review first', v_cnt; END IF;
END $$;

UPDATE essentials.politicians SET is_incumbent = false WHERE external_id = -5530003;  -- Bradley out
UPDATE essentials.politicians SET is_incumbent = true  WHERE external_id = -5530008;  -- Taylor in

DO $$
DECLARE v_cnt int;
BEGIN
  -- Exactly seven sitting justices, matching official_count, and Taylor is one of them.
  SELECT count(*) INTO v_cnt
  FROM essentials.politicians p
  JOIN essentials.office_terms ot ON ot.politician_id = p.id
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.state = 'WI' AND ch.name = 'Supreme Court' AND p.is_incumbent = true;
  IF v_cnt <> 7 THEN RAISE EXCEPTION 'POST: % sitting WI justices, expected 7', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE external_id = -5530008 AND is_incumbent = true;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'POST: Taylor is not seated'; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE external_id = -5530003 AND is_incumbent = false;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'POST: Bradley is still flagged incumbent'; END IF;

  -- Nobody was deactivated: both rows survive, only the flags moved.
  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE external_id IN (-5530003, -5530008) AND is_active = true;
  IF v_cnt <> 2 THEN RAISE EXCEPTION 'POST: a justice row was deactivated'; END IF;
END $$;

COMMIT;
