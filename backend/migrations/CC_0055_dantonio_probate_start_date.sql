-- CC_0055_dantonio_probate_start_date.sql
--
-- Muscogee County, GA — date the one Columbus occupancy row that has a sourced start and was
-- written open-ended anyway. A GA-4 amendment, raised by GA-5's carry-over re-check.
--
-- Spec:    docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
-- Notes:   .planning/knight-foundation/ga.md  (GA-4 carry-over, and GA-6)
-- Tracker: .planning/knight-foundation/PROGRAM.md
--
-- ── WHAT IS WRONG ────────────────────────────────────────────────────────────────────────────
-- CC_0036 seated Marc D'Antonio as Judge of the Muscogee County Probate Court open-ended, at
-- start_precision 'unknown', because at the time no start was known:
--
--     term_start NULL, start_precision 'unknown', how_started 'elected'
--
-- That was the honest write then. A start has since been sourced, so the row now understates what
-- is known. This migration changes ONE COLUMN PAIR ON ONE ROW and nothing else.
--
-- ── THE DERIVATION, AND WHY IT IS 'year' RATHER THAN 'day' ───────────────────────────────────
-- Ballotpedia's person page for Marc Eric D'Antonio (re-read 2026-09-02, rendered, not cached):
--
--     "He first served the court as an appointed associate judge from 2009 until being elected
--      judge in 2012 to replace Julia W. Lumpkin"
--
-- Georgia county officers take office the January following their election, so his occupancy of
-- THE JUDGESHIP begins 2013-01-01.
--
-- ⚠ THE 2009 APPOINTMENT WAS TO A DIFFERENT OFFICE — associate judge, not judge. It is not the
--   start of this occupancy and is deliberately not written.
--
-- 🔴 PRECISION IS 'year', NOT 'day'. The year is sourced; the day is a rule applied to it, and no
--    source publishes an oath date. This is the IDENTICAL shape as Bibb's David Davis and Sarah S.
--    Harris in CC_0051 — both 2013-01-01 at 'year', both from "elected in November 2012" plus the
--    same commencement rule — and this migration matches them deliberately.
--    ⚠ It is NOT the shape of Macon-Bibb's commissioners, who are written at 'day': their CHARTER
--      states the commencement rule in terms (Sec. 9(c), Sec. 10(b)) and the county restates it as
--      fact for the 2025 cohort. No such instrument was read for the probate judgeship.
--
-- ── WHAT THIS MIGRATION DOES NOT DO ──────────────────────────────────────────────────────────
-- 🔴 IT DOES NOT DECIDE WHETHER HE IS STILL THERE. GA-5's re-check established no departure AND
--    no currency: his own court page still does not name its judge, and the Ballotpedia page's
--    newest fact is 2016 while describing him in the present tense. Present-tense prose on a
--    nine-year-old page is not currency — that is exactly the Baldwin coroner failure, where every
--    source agreed and all of them predated the retirement. The seat stays as CC_0036 wrote it.
--    A start date is a claim about when a tenure BEGAN; it asserts nothing about today.
-- 🔴 IT WRITES NO term_end. A future term_end makes a seat silently self-vacate on the day it
--    arrives.
--
-- Idempotent: the UPDATE is guarded on the row still being undated, so a re-run is a no-op.

BEGIN;

UPDATE essentials.office_terms ot
   SET term_start      = DATE '2013-01-01',
       start_precision = 'year',
       source          = ot.source || ' + ballotpedia-marc-eric-dantonio-read-2026-09-02 '
                         || '(''elected judge in 2012 to replace Julia W. Lumpkin''), '
                         || 'Georgia county officers taking office the following January; '
                         || 'year precision because the day is the rule, not the source. '
                         || 'The 2009 appointment was to associate judge, a different office, '
                         || 'and is not written.'
  FROM essentials.offices o
  JOIN essentials.chambers c    ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE ot.office_id = o.id
   AND g.geo_id = '1319000'
   AND o.title = 'Judge of Probate Court'
   -- ⚠ The person is matched with EXISTS, not another FROM join: in UPDATE … FROM, the target
   --   table cannot be referenced from inside a join's ON clause, so `ON p.id = ot.politician_id`
   --   is a parse error rather than a filter that silently does nothing.
   AND EXISTS (SELECT 1 FROM essentials.politicians p
                WHERE p.id = ot.politician_id
                  AND p.full_name = 'Marc D''Antonio')
   AND ot.term_start IS NULL             -- the guard: only the undated row, so a re-run is a no-op
   AND ot.start_precision = 'unknown';

DO $$
DECLARE
  v_n     integer;
  v_start date;
  v_prec  text;
  v_how   text;
BEGIN
  -- 1. Exactly one Muscogee probate term row, held by exactly this person, and it is dated.
  SELECT count(*), min(ot.term_start), min(ot.start_precision), min(ot.how_started)
    INTO v_n, v_start, v_prec, v_how
    FROM essentials.office_terms ot
    JOIN essentials.offices o     ON o.id = ot.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE g.geo_id = '1319000'
     AND o.title = 'Judge of Probate Court'
     AND p.full_name = 'Marc D''Antonio';

  IF v_n <> 1 THEN
    RAISE EXCEPTION 'dantonio start date: expected exactly 1 term row, found %. The seat has moved since 2026-09-02 — re-read the GA-4 carry-over block in .planning/knight-foundation/ga.md before re-running', v_n;
  END IF;
  IF v_start <> DATE '2013-01-01' THEN
    RAISE EXCEPTION 'dantonio start date: term_start is %, expected 2013-01-01', v_start;
  END IF;
  IF v_prec <> 'year' THEN
    RAISE EXCEPTION 'dantonio start date: start_precision is %, expected year', v_prec;
  END IF;
  IF v_how <> 'elected' THEN
    RAISE EXCEPTION 'dantonio start date: how_started is %, expected elected (this migration must not change it)', v_how;
  END IF;

  -- 2. No term_end was introduced.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms ot
    JOIN essentials.offices o     ON o.id = ot.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '1319000'
     AND o.title = 'Judge of Probate Court'
     AND ot.term_end IS NOT NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'dantonio start date: % term row(s) carry a term_end; none should', v_n;
  END IF;

  -- 3. BLAST RADIUS. Columbus held 13 undated rows of its 16 (measured 2026-09-02); exactly ONE
  --    of them was to change. If a later edit widens the WHERE clause, this is what catches it:
  --    the other 12 must still be undated, because no start has been sourced for any of them.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms ot
    JOIN essentials.offices o     ON o.id = ot.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '1319000'
     AND ot.term_start IS NULL
     AND ot.start_precision = 'unknown';
  IF v_n <> 12 THEN
    RAISE EXCEPTION 'dantonio start date: expected 12 remaining undated Columbus rows, found % — this migration must touch exactly one row', v_n;
  END IF;

  RAISE NOTICE 'dantonio start date: 1 row dated 2013-01-01 at year precision; 12 Columbus rows remain correctly undated';
END $$;

COMMIT;
