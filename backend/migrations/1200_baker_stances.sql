-- Migration 1200: Edgar Baker (Councilor, Cornelius OR) compass stances -- AUDIT-ONLY (not registered
-- in the ledger).
-- HONEST BLANK: 0 cited stances. Baker was appointed to the Cornelius City Council on June 1, 2026 --
-- weeks before this research was conducted -- so essentially no post-appointment council record exists
-- yet to cite. The council-minutes archive scanned (Nov 2025-Jul 2026, all posted regular/special
-- meetings) contains only his oath-of-office item at the June 1, 2026 meeting; no subsequent minutes
-- with council votes or reports attributable to him have been posted as of this research date, and no
-- independent news coverage of him as a councilor was found.
--
-- Prior to his appointment, Baker's only recorded public involvement was a public-comment statement at
-- the November 17, 2025 council meeting (as a private citizen and former Planning Commissioner, not yet
-- a councilor), in which he defended the fairness of Citlalli Nunez-Barragan's appointment process
-- against another resident's claim that it prioritized diversity/equity over qualifications. That
-- statement is about the fairness of a specific appointment decision, not a documented position on any
-- of the 36 non-judicial live compass topics -- citing it here would force an ill-fitting chair onto
-- evidence that does not actually address a compass topic, which the no-default / no-padding rule
-- (D-08) forbids. Per the thin-appointee-record allowance in the plan's acceptance criteria, this is an
-- honest zero-stance file rather than a padded one: no VALUES block is authored because there is nothing
-- to author. Appointed-seat context: Baker holds his seat by council appointment (is_appointed = true
-- on essentials.politicians), not by election.

BEGIN;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): confirm the hardcoded UUID belongs to the intended
  -- official before asserting anything about his (lack of) stance rows.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = '31df8939-d8ba-4b54-9c69-18317d7096ee';
  IF v_ext IS DISTINCT FROM -4115553 THEN
    RAISE EXCEPTION 'UUID 31df8939-d8ba-4b54-9c69-18317d7096ee does not belong to external_id -4115553 (Edgar Baker) -- found %', v_ext;
  END IF;

  -- Zero-count gate: this migration intentionally inserts nothing. Assert
  -- that no pre-existing politician_answers/politician_context rows exist
  -- for Edgar Baker, so a genuine future gap is never silently confused with
  -- a data-entry omission this migration failed to catch.
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = '31df8939-d8ba-4b54-9c69-18317d7096ee';
  IF n <> 0 THEN
    RAISE EXCEPTION 'Expected 0 pre-existing politician_answers rows for Edgar Baker (this is an intentional honest-blank migration with no evidence found) -- found % -- investigate before treating this as a genuine zero-yield record', n;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = '31df8939-d8ba-4b54-9c69-18317d7096ee';
  IF n <> 0 THEN
    RAISE EXCEPTION 'Expected 0 pre-existing politician_context rows for Edgar Baker (this is an intentional honest-blank migration with no evidence found) -- found % -- investigate before treating this as a genuine zero-yield record', n;
  END IF;

  -- Content-correspondence gate (WR-04) is vacuously satisfied: with 0 rows
  -- in both tables there can be no set-mismatch between them.
  RAISE NOTICE 'Edgar Baker (external_id -4115553): 0 evidence-based compass stances authored. Appointed June 1, 2026 (weeks before this research); no post-appointment council record posted yet; his sole pre-appointment public-comment record does not correspond to a compass topic. Honest blank per D-08 no-default rule -- not a data gap.';
END $$;

COMMIT;
