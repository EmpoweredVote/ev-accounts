-- CC_0394 — carry term start dates from the deprecated per-person snapshot onto the tenure.
--
-- CC_0391 moved the read path off essentials.politicians.valid_from and onto the tenure. That was
-- a large net gain (4,048 seats began showing a date) and it had one honest cost: 617 current,
-- held seats whose PERSON carried a valid_from but whose TENURE carries no term_start stopped
-- showing a date at all. ▶ The repair is a backfill, not a read-path fallback: a fallback would
-- reach for the wrong entity again and defeat the guard CC_0391 added.
--
-- This migration writes NO new term. It sets term_start and start_precision on term rows that
-- already exist and already have a holder. Nothing is seated, nothing is vacated, no office is
-- created, and essentials.offices is not touched at all.
--
-- ============================================================================================
-- WHAT IT OVERWRITES  (there is no history table and no schema_migrations to replay from)
-- ============================================================================================
--   office_terms.term_start      NULL  ->  the carried date        (nothing is destroyed)
--   office_terms.start_precision 'unknown' -> 'day' | 'month' | 'year'
--   office_terms.source          APPENDED to, never replaced.
--
-- All 290 target rows read start_precision = 'unknown' before this runs, and 289 of them carry
-- the source 'backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)'.
-- The 290th is Jaisen Rutledge (Princeton TX Place 4), whose source records a 2026-06-13 special
-- election runoff in full. ⚠ That is why source is APPENDED: overwriting it would destroy a
-- sourced account of how the seat was filled, to record something weaker.
--
-- politicians.valid_from / valid_to / term_date_precision are LEFT ALONE. Nothing in backend/src
-- reads them any more (CC_0391 plus the fourth rule in check-office-occupancy.mjs), but the
-- staging importer still writes them. Retiring the columns is a separate decision.
--
-- ============================================================================================
-- 🔴 WHO IS EXCLUDED, AND WHY — 617 candidates become 290
-- ============================================================================================
-- 🔴 324 rows come from people whose source is 'ballotready'. BALLOTREADY IS NOT A SOURCE THIS
--    REPO USES. They are excluded on that ground alone. Independently, 319 of the 324 are dated
--    exactly 01-01 of some year — the documented convention for "the source said only a year" —
--    so they carry no day-level information even if the provenance were acceptable.
--
-- 🔴 3 rows belong to people holding more than one current seat. valid_from is a PER-PERSON
--    column, so for a two-seat holder it CANNOT say which tenure it describes. Writing it onto
--    either seat would be a guess. (One of the three is Cambridge MA's Sumbul Siddiqui, who holds
--    both Mayor and City Councillor.) This is the exact defect ADR 0002 replaced the column over,
--    and it is the one case where the column's shape makes the answer unknowable.
--
-- ============================================================================================
-- 🔴 THE PRECISION RULE: TAKE THE COARSER OF WHAT THE RECORD CLAIMS AND WHAT THE VALUE SHOWS
-- ============================================================================================
-- Two signals disagree, and NEITHER is reliable on its own. Measured over the 290 eligible rows:
--
--   stated precision   date shape        n    agree?
--   ----------------   --------------  ---   ------
--   month              first-of-month  151   yes
--   <none>             real day        106   no contradiction
--   month              REAL DAY         18   🔴 CONTRADICT
--   day                real day          7   yes
--   <none>             first-of-month    5   ambiguous
--   <none>             01-01             2   ambiguous
--   year               01-01             1   yes
--
-- ⚠ The value's SHAPE is evidence, because the house convention writes a coarse date as the first
--   of the period: "2017" is stored 2017-01-01 with precision 'year'. So a date landing on the
--   1st may be a real 1st or a placeholder, and the two are indistinguishable.
--
-- ⚠ The STATED column is evidence too, and it is sometimes stale. 16 of the 18 contradicting rows
--   are Cambridge MA, all dated 2026-01-05 — a Monday, and Cambridge's real inauguration day. The
--   day is almost certainly genuine there and 'month' is the stale half. The other two are Texas
--   municipalities sworn in at a specific council meeting.
--
-- 🔴 SO THE RULE IS AN ASYMMETRY, NOT A WINNER. Under-claiming precision shows a voter less than
--    we know. OVER-claiming tells a voter something false. "January 2026" is true whether the
--    real answer is the 5th or merely sometime that month; "January 5, 2026" is a lie if the day
--    was a placeholder. Only one of those two errors can mislead, so every row takes the COARSER
--    of the two signals and the date is TRUNCATED to it. The 18 Cambridge/Texas rows therefore
--    ship as 'month' and show a month, which is a real loss, recorded here so a later pass can
--    sharpen them from each city's own clerk — not quietly taken as resolved.
--
-- 🔴 THESE ROWS MUST NOT BE TAGGED '| unverified CC_0394'. That tag (CA_0171) makes
--    essentials.office_holders_as_of SKIP a term, because it marks a term that may not be a real
--    tenure at all. These ARE real tenures with real holders — only the DATE is carried over — so
--    the tag would delete a sitting officeholder from every historical query. The provenance is
--    written into source as prose instead.
--
-- Every target row has term_end IS NULL, so narrowing an unbounded range can create no overlap
-- and cannot trip office_terms_dates_sane. Measured: 290 pairs resolve to exactly 290 term rows.
--
-- Idempotent: the plan is built from term_start IS NULL, so a second run selects nothing, updates
-- nothing, and the gate still passes (before = updated = 0, remaining = 0).
--
-- Applied to production 2026-11-10: 290 tenures dated (113 day, 174 month, 3 year), 0 eligible
-- left undated, unflagged offices_missing_terms still 238. Re-running plans 0 and still passes.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- 1. Build the plan. One row per tenure to be dated.
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE cc0394_plan ON COMMIT DROP AS
WITH held AS (
  SELECT och.office_id, och.politician_id
    FROM essentials.office_current_holder och
   WHERE och.politician_id IS NOT NULL
     AND och.term_start IS NULL
),
person AS (
  SELECT h.office_id,
         h.politician_id,
         btrim(p.valid_from)                                           AS raw_value,
         substring(btrim(p.valid_from) from 1 for 10)::date            AS raw_date,
         CASE WHEN p.term_date_precision IN ('day','month','year')
              THEN p.term_date_precision END                           AS stated_precision,
         coalesce(nullif(btrim(p.source), ''), '<none>')               AS person_source
    FROM held h
    JOIN essentials.politicians p ON p.id = h.politician_id
   WHERE coalesce(btrim(p.valid_from), '') <> ''
     -- Defensive: only parse what is already date-shaped. All 617 candidates match.
     AND btrim(p.valid_from) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
     -- 🔴 BallotReady is not a source this repo uses.
     AND coalesce(nullif(btrim(p.source), ''), '<none>') <> 'ballotready'
     -- 🔴 A per-person date cannot say WHICH seat it describes.
     AND (SELECT count(*) FROM essentials.office_current_holder o2
           WHERE o2.politician_id = h.politician_id) = 1
),
graded AS (
  SELECT pr.*,
         CASE WHEN to_char(pr.raw_date, 'MM-DD') = '01-01' THEN 'year'
              WHEN extract(day from pr.raw_date) = 1       THEN 'month'
              ELSE                                              'day'
         END AS shape_precision
    FROM person pr
),
resolved AS (
  SELECT g.*,
         -- The coarser of the two signals. A stated precision of NULL asserts nothing and so
         -- never coarsens; it simply lets the shape stand.
         CASE least(
                CASE g.shape_precision WHEN 'year' THEN 1 WHEN 'month' THEN 2 ELSE 3 END,
                coalesce(CASE g.stated_precision WHEN 'year' THEN 1 WHEN 'month' THEN 2
                                                 WHEN 'day' THEN 3 END, 3))
           WHEN 1 THEN 'year' WHEN 2 THEN 'month' ELSE 'day'
         END AS new_precision
    FROM graded g
)
SELECT ot.id                        AS term_id,
       r.office_id,
       r.politician_id,
       r.raw_value,
       r.stated_precision,
       r.shape_precision,
       r.new_precision,
       CASE r.new_precision
         WHEN 'year'  THEN date_trunc('year',  r.raw_date)::date
         WHEN 'month' THEN date_trunc('month', r.raw_date)::date
         ELSE              r.raw_date
       END                          AS new_start,
       ot.source                    AS source_before,
       ot.start_precision           AS precision_before
  FROM resolved r
  JOIN essentials.office_terms ot
    ON ot.office_id     = r.office_id
   AND ot.politician_id = r.politician_id
   AND ot.term_start IS NULL
   AND daterange(ot.term_start, ot.term_end, '[]') @> CURRENT_DATE;

-- ---------------------------------------------------------------------------------------------
-- 2. Refuse to write a plan that is not what this file describes.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_plan     int;
  v_distinct int;
  v_bad      int;
  v_future   int;
BEGIN
  SELECT count(*) INTO v_plan FROM cc0394_plan;

  -- One tenure per plan row, and one plan row per tenure.
  SELECT count(DISTINCT term_id) INTO v_distinct FROM cc0394_plan;
  IF v_distinct <> v_plan THEN
    RAISE EXCEPTION 'CC_0394 pre-gate: % plan rows resolve to only % distinct term(s)',
                    v_plan, v_distinct;
  END IF;

  -- Every precision must be one the CHECK constraint and the API vocabulary both admit.
  -- 'unknown' is deliberately not reachable here: a row we are giving a DATE is not undated.
  SELECT count(*) INTO v_bad FROM cc0394_plan
   WHERE new_precision NOT IN ('day','month','year');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0394 pre-gate: % plan row(s) carry an unusable precision', v_bad;
  END IF;

  -- The derived date must honour the derived precision, or the two halves disagree on disk.
  SELECT count(*) INTO v_bad FROM cc0394_plan
   WHERE (new_precision = 'year'  AND to_char(new_start,'MM-DD') <> '01-01')
      OR (new_precision = 'month' AND extract(day from new_start) <> 1);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0394 pre-gate: % row(s) were not truncated to their own precision', v_bad;
  END IF;

  -- 🔴 Never coarsen in the wrong direction: the written precision may not be FINER than either
  --    signal. This is the whole asymmetry the header argues for, asserted rather than trusted.
  SELECT count(*) INTO v_bad FROM cc0394_plan
   WHERE CASE new_precision WHEN 'year' THEN 1 WHEN 'month' THEN 2 ELSE 3 END
       > least(CASE shape_precision WHEN 'year' THEN 1 WHEN 'month' THEN 2 ELSE 3 END,
               coalesce(CASE stated_precision WHEN 'year' THEN 1 WHEN 'month' THEN 2
                                              WHEN 'day' THEN 3 END, 3));
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0394 pre-gate: % row(s) claim a FINER precision than their evidence', v_bad;
  END IF;

  -- A CURRENT holder whose tenure begins after today is incoherent.
  SELECT count(*) INTO v_future FROM cc0394_plan WHERE new_start > CURRENT_DATE;
  IF v_future <> 0 THEN
    RAISE EXCEPTION 'CC_0394 pre-gate: % row(s) would start in the future', v_future;
  END IF;

  -- Nothing may already be dated, or this is not the population the header measured.
  SELECT count(*) INTO v_bad FROM cc0394_plan WHERE precision_before <> 'unknown';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0394 pre-gate: % row(s) already carry a precision other than unknown',
                    v_bad;
  END IF;

  RAISE NOTICE 'CC_0394 plan: % tenure(s) to date (% day, % month, % year)',
               v_plan,
               (SELECT count(*) FROM cc0394_plan WHERE new_precision = 'day'),
               (SELECT count(*) FROM cc0394_plan WHERE new_precision = 'month'),
               (SELECT count(*) FROM cc0394_plan WHERE new_precision = 'year');
END $$;

-- ---------------------------------------------------------------------------------------------
-- 3. Write it. Guarded on term_start IS NULL, so a re-run is a no-op.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.office_terms ot
   SET term_start      = pl.new_start,
       start_precision = pl.new_precision,
       source          = ot.source
                         || ' | CC_0394: term_start ' || to_char(pl.new_start, 'YYYY-MM-DD')
                         || ' (' || pl.new_precision || ' precision) carried over from the'
                         || ' deprecated politicians.valid_from snapshot, which read "'
                         || pl.raw_value || '"'
                         || CASE WHEN pl.stated_precision IS NOT NULL
                                 THEN ' with stated precision ' || pl.stated_precision
                                 ELSE ' with no stated precision' END
                         || '. The date is not independently sourced and the day was not'
                         || ' established against the body''s own record.'
  FROM cc0394_plan pl
 WHERE ot.id = pl.term_id
   AND ot.term_start IS NULL;

-- ---------------------------------------------------------------------------------------------
-- 4. Post-verify. Gated on the DELTA this transaction created, not on a repo-wide total.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_plan      int;
  v_written   int;
  v_remaining int;
  v_bad       int;
  v_drift     int;
BEGIN
  SELECT count(*) INTO v_plan FROM cc0394_plan;

  -- Every planned tenure now carries exactly the date and precision the plan derived.
  SELECT count(*) INTO v_written
    FROM cc0394_plan pl
    JOIN essentials.office_terms ot ON ot.id = pl.term_id
   WHERE ot.term_start = pl.new_start
     AND ot.start_precision = pl.new_precision;
  IF v_written <> v_plan THEN
    RAISE EXCEPTION 'CC_0394 gate: planned % tenure(s), only % carry the planned values',
                    v_plan, v_written;
  END IF;

  -- The source of every one of them records where the date came from.
  SELECT count(*) INTO v_bad
    FROM cc0394_plan pl
    JOIN essentials.office_terms ot ON ot.id = pl.term_id
   WHERE ot.source NOT LIKE '%CC_0394: term_start%'
      OR position(pl.source_before in ot.source) <> 1;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0394 gate: % row(s) lost their prior source or carry no provenance', v_bad;
  END IF;

  -- 🔴 The view must agree. A write that the read path cannot see is not a fix.
  SELECT count(*) INTO v_bad
    FROM cc0394_plan pl
    JOIN essentials.office_current_holder och ON och.office_id = pl.office_id
   WHERE och.politician_id IS DISTINCT FROM pl.politician_id
      OR och.term_start    IS DISTINCT FROM pl.new_start
      OR och.start_precision IS DISTINCT FROM pl.new_precision;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0394 gate: % seat(s) do not read back through office_current_holder', v_bad;
  END IF;

  -- Rebuilt from scratch, not from the plan: no eligible tenure may be left undated.
  SELECT count(*) INTO v_remaining
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.politician_id IS NOT NULL
     AND och.term_start IS NULL
     AND coalesce(btrim(p.valid_from), '') <> ''
     AND btrim(p.valid_from) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND coalesce(nullif(btrim(p.source), ''), '<none>') <> 'ballotready'
     AND (SELECT count(*) FROM essentials.office_current_holder o2
           WHERE o2.politician_id = och.politician_id) = 1;
  IF v_remaining <> 0 THEN
    RAISE EXCEPTION 'CC_0394 gate: % eligible tenure(s) are still undated', v_remaining;
  END IF;

  -- 🔴 Nobody excluded may have been written. Checked against the live rows, not the plan.
  SELECT count(*) INTO v_bad
    FROM cc0394_plan pl
    JOIN essentials.politicians p ON p.id = pl.politician_id
   WHERE coalesce(nullif(btrim(p.source), ''), '<none>') = 'ballotready';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0394 gate: % BallotReady-sourced row(s) were written', v_bad;
  END IF;
  SELECT count(*) INTO v_bad
    FROM cc0394_plan pl
   WHERE (SELECT count(*) FROM essentials.office_current_holder o2
           WHERE o2.politician_id = pl.politician_id) > 1;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0394 gate: % multi-seat holder(s) were written', v_bad;
  END IF;

  -- This migration creates and closes no tenure, so the occupancy drift baseline cannot move.
  SELECT count(*) INTO v_drift
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id
   WHERE NOT o.is_vacant;
  IF v_drift <> 238 THEN
    RAISE EXCEPTION 'CC_0394 gate: unflagged offices_missing_terms is %, baseline 238', v_drift;
  END IF;

  RAISE NOTICE 'CC_0394 OK: % tenure(s) dated (% day, % month, % year) · 0 eligible left undated'
               ' · drift baseline 238 intact',
               v_plan,
               (SELECT count(*) FROM cc0394_plan WHERE new_precision = 'day'),
               (SELECT count(*) FROM cc0394_plan WHERE new_precision = 'month'),
               (SELECT count(*) FROM cc0394_plan WHERE new_precision = 'year');
END $$;

COMMIT;
