-- 1438_office_terms_backfill.sql
-- ADR 0002 phase 2: give every currently-occupied office one open-ended term, so that
-- essentials.current_office_holders reproduces today's answers exactly. Idempotent.
--
-- Requires 1458. Changes no existing behaviour: nothing reads office_terms until phase 3.
--
-- SCOPE — occupied offices only. Of 83,186 office rows, 82,329 have a politician_id and 857 do
--   not. Only the 82,329 get a term.
--
--   The 857 are deliberately skipped. A term row with politician_id NULL asserts "this seat was
--   VACANT across this span", and for most of those offices we do not know that — 696 of them are
--   not even flagged is_vacant, so "no occupant recorded" means "unknown", not "empty". Writing
--   vacancy spans we cannot date would be inventing history, which is the same mistake as
--   inventing 2017-01-01 for a source that said only "2017".
--
--   Real vacancies keep their existing signal on essentials.offices.is_vacant until we learn the
--   DATE they began. Caledonia Trustee Seat 2 is the worked example: we know from the village's
--   own board page that it is vacant now (Balch vacated it on becoming President), but not the
--   day, so there is no honest span to write yet. That is a data-gathering task, not a backfill.
--
-- SHAPE OF THE BACKFILLED TERM: term_start NULL, term_end NULL, start_precision 'unknown',
--   how_started NULL. We are asserting only "this person holds this office now", which is exactly
--   what offices.politician_id already claimed — no more. Dates get filled in as they are learned,
--   per office, from real sources.
--
--   Consequence to expect in phase 4: because an open-ended term is an INFINITE range, seating a
--   successor in one of these offices requires closing the backfilled term first (see 1458's
--   header). That is the intended behaviour and the reason the exclusion constraint exists.
--
-- EQUIVALENCE IS THE POINT. The gate below asserts that current_office_holders and
--   offices.politician_id agree on every occupied office, in both directions, with zero
--   divergence. Until that holds, phase 3 cannot safely move a single read path.
BEGIN;

INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, o.politician_id, NULL, NULL, 'unknown', NULL,
       'backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)'
FROM essentials.offices o
WHERE o.politician_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id
  );

-- ── Post-verify gate ──
DO $$
DECLARE
  n_occupied int; n_terms int; n_missing int; n_extra int;
  n_divergent int; n_skipped int; n_dupe int;
BEGIN
  SELECT count(*) INTO n_occupied FROM essentials.offices WHERE politician_id IS NOT NULL;
  SELECT count(*) INTO n_terms    FROM essentials.office_terms;

  -- one term per occupied office, no more
  SELECT count(*) INTO n_dupe FROM (
    SELECT office_id FROM essentials.office_terms GROUP BY office_id HAVING count(*) > 1
  ) d;
  IF n_dupe <> 0 THEN
    RAISE EXCEPTION '% offices have more than one backfilled term', n_dupe;
  END IF;

  -- every occupied office must now resolve to a current holder
  SELECT count(*) INTO n_missing
    FROM essentials.offices o
   WHERE o.politician_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.current_office_holders c WHERE c.office_id = o.id);
  IF n_missing <> 0 THEN
    RAISE EXCEPTION '% occupied offices have no current term', n_missing;
  END IF;

  -- and nothing may resolve that offices does not also claim
  SELECT count(*) INTO n_extra
    FROM essentials.current_office_holders c
    JOIN essentials.offices o ON o.id = c.office_id
   WHERE o.politician_id IS NULL;
  IF n_extra <> 0 THEN
    RAISE EXCEPTION '% current terms exist for offices with no occupant', n_extra;
  END IF;

  -- THE equivalence check: same office => same politician, both directions
  SELECT count(*) INTO n_divergent
    FROM essentials.current_office_holders c
    JOIN essentials.offices o ON o.id = c.office_id
   WHERE c.politician_id IS DISTINCT FROM o.politician_id;
  IF n_divergent <> 0 THEN
    RAISE EXCEPTION 'current_office_holders disagrees with offices.politician_id on % offices', n_divergent;
  END IF;

  SELECT count(*) INTO n_skipped FROM essentials.offices WHERE politician_id IS NULL;

  RAISE NOTICE 'office_terms backfill PASSED: % terms for % occupied offices, 0 divergence from offices.politician_id; % unoccupied offices intentionally skipped.',
    n_terms, n_occupied, n_skipped;
END $$;

COMMIT;
