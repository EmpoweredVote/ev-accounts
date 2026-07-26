-- 1464_office_terms_seeding_helpers.sql
-- Make the ADR 0002 occupancy model safe to SEED against. Idempotent. Requires 1458 + 1459 + 1462.
--
-- WHY THIS EXISTS. Phase 5 made essentials.office_terms the only source of occupancy, but left
--   seeding harder than it was: setting an occupant used to be one column write, and is now a
--   TWO-STEP (close the predecessor's term, then insert the successor) because an open-ended term
--   is an INFINITE range that overlaps every future span. Every seeder re-implementing that
--   two-step by hand is a defect waiting to happen -- and the failure is silent in one direction:
--   create a seat, forget the term, and the official simply never appears anywhere. No error.
--
--   So: one sanctioned function for each operation, plus a view that makes the silent case visible.
--
-- NOT a replacement for writing migrations carefully. These are conveniences that encode the
--   constraint semantics once. Straight INSERTs into office_terms remain perfectly valid.
BEGIN;

-- ── seat_officeholder: the two-step, done correctly, idempotently ──
-- Returns the office_terms.id of the term the officeholder now occupies.
CREATE OR REPLACE FUNCTION essentials.seat_officeholder(
  p_office_id       uuid,
  p_politician_id   uuid,
  p_term_start      date,
  p_source          text,
  p_how_started     text DEFAULT 'elected',
  p_start_precision text DEFAULT 'day',
  p_how_ended_prev  text DEFAULT 'term_expired'
) RETURNS uuid
LANGUAGE plpgsql
SET search_path TO ''
AS $fn$
DECLARE
  v_existing_id  uuid;
  v_prev_id      uuid;
  v_prev_start   date;
  v_prev_pol     uuid;
  v_new_id       uuid;
BEGIN
  IF p_term_start IS NULL THEN
    RAISE EXCEPTION 'seat_officeholder requires a real term_start. If the source gives only a year, '
                    'pass Jan 1 with p_start_precision => ''year'' rather than NULL.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = p_office_id) THEN
    RAISE EXCEPTION 'office % does not exist', p_office_id;
  END IF;

  -- Already seated with exactly this term? Then this is a re-run: do nothing.
  SELECT t.id INTO v_existing_id
    FROM essentials.office_terms t
   WHERE t.office_id = p_office_id
     AND t.politician_id IS NOT DISTINCT FROM p_politician_id
     AND t.term_start IS NOT DISTINCT FROM p_term_start;
  IF v_existing_id IS NOT NULL THEN
    RETURN v_existing_id;
  END IF;

  -- Find the term that would collide with the new one: the term covering p_term_start, which
  -- includes any open-ended term (term_end IS NULL) starting on or before it.
  SELECT t.id, t.term_start, t.politician_id
    INTO v_prev_id, v_prev_start, v_prev_pol
    FROM essentials.office_terms t
   WHERE t.office_id = p_office_id
     AND (t.term_start IS NULL OR t.term_start <= p_term_start)
     AND (t.term_end   IS NULL OR t.term_end   >= p_term_start)
   ORDER BY t.term_start DESC NULLS LAST
   LIMIT 1;

  IF v_prev_id IS NOT NULL THEN
    -- Same person already holding through this date: nothing to hand over.
    IF v_prev_pol IS NOT DISTINCT FROM p_politician_id THEN
      RETURN v_prev_id;
    END IF;
    -- A predecessor that STARTS on/after the successor's start cannot simply be closed -- that
    -- would need term_end < term_start and trip office_terms_dates_sane. Refuse, loudly.
    IF v_prev_start IS NOT NULL AND v_prev_start >= p_term_start THEN
      RAISE EXCEPTION 'cannot seat % on office % at %: an existing term starts % (on/after that '
                      'date). Fix the dates or close that term explicitly.',
                      p_politician_id, p_office_id, p_term_start, v_prev_start;
    END IF;
    UPDATE essentials.office_terms
       SET term_end  = p_term_start - 1,
           how_ended = COALESCE(how_ended, p_how_ended_prev)
     WHERE id = v_prev_id;
  END IF;

  INSERT INTO essentials.office_terms
    (office_id, politician_id, term_start, start_precision, how_started, source)
  VALUES
    (p_office_id, p_politician_id, p_term_start, p_start_precision, p_how_started, p_source)
  RETURNING id INTO v_new_id;

  RETURN v_new_id;
END $fn$;

COMMENT ON FUNCTION essentials.seat_officeholder(uuid, uuid, date, text, text, text, text) IS
  'Seat an officeholder on an office from a date, closing the predecessor''s term the day before '
  '(ADR 0002). Idempotent: re-running with the same (office, politician, term_start) is a no-op. '
  'Refuses a NULL term_start -- pass Jan 1 with start_precision => ''year'' when a source gives '
  'only a year. Use this instead of hand-writing the close-then-insert two-step.';

-- ── vacate_office: close a term with NO successor ──
-- p_as_of is the FIRST day the seat is vacant, so the outgoing term ends the day before.
-- Also syncs the is_vacant/vacant_since signals, which is the pairing that keeps them honest.
CREATE OR REPLACE FUNCTION essentials.vacate_office(
  p_office_id uuid,
  p_as_of     date,
  p_source    text,
  p_how_ended text DEFAULT 'resigned'
) RETURNS boolean
LANGUAGE plpgsql
SET search_path TO ''
AS $fn$
DECLARE v_id uuid;
BEGIN
  IF p_as_of IS NULL THEN
    RAISE EXCEPTION 'vacate_office requires the date the seat became vacant. If it is unknown, do '
                    'NOT invent one -- set essentials.offices.is_vacant and leave the span unwritten '
                    '(ADR 0002).';
  END IF;

  SELECT t.id INTO v_id
    FROM essentials.office_terms t
   WHERE t.office_id = p_office_id
     AND t.politician_id IS NOT NULL
     AND (t.term_start IS NULL OR t.term_start <= p_as_of)
     AND (t.term_end   IS NULL OR t.term_end   >= p_as_of)
   ORDER BY t.term_start DESC NULLS LAST
   LIMIT 1;

  UPDATE essentials.offices
     SET is_vacant = true, vacant_since = COALESCE(vacant_since, p_as_of)
   WHERE id = p_office_id;

  IF v_id IS NULL THEN
    RETURN false;   -- nothing was open; the is_vacant flag is still now set
  END IF;

  UPDATE essentials.office_terms
     SET term_end  = p_as_of - 1,
         how_ended = p_how_ended,
         source    = source || ' | vacated: ' || p_source
   WHERE id = v_id
     AND term_end IS DISTINCT FROM p_as_of - 1;   -- idempotent re-run

  RETURN true;
END $fn$;

COMMENT ON FUNCTION essentials.vacate_office(uuid, date, text, text) IS
  'Close the current term on an office with no successor, as of the first VACANT day, and set '
  'is_vacant/vacant_since to match (ADR 0002). Refuses a NULL date: an undated vacancy should be '
  'the is_vacant flag alone, not an invented span.';

-- ── The drift detector: the failure mode CI cannot catch ──
CREATE OR REPLACE VIEW essentials.offices_missing_terms AS
SELECT o.id AS office_id,
       o.title,
       o.representing_city,
       o.representing_state,
       o.chamber_id,
       o.district_id,
       o.is_vacant,
       o.vacant_since
  FROM essentials.offices o
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

COMMENT ON VIEW essentials.offices_missing_terms IS
  'Seats with NO occupancy record at all. Since ADR 0002 phase 5 an office carries no occupant '
  'column, so a seeder that creates a seat and forgets its office_terms row produces an official '
  'who is invisible everywhere -- with no error. This view is how that is noticed. '
  'BASELINE at migration 1464: 857 rows, of which 158 are legitimately flagged is_vacant and 699 '
  'are unknown occupancy predating the phase-2 backfill (which deliberately skipped them rather '
  'than invent vacancy spans). Filter is_vacant IS DISTINCT FROM true and treat a count above 699 '
  'as new drift from a seeder, not as history.';

-- ── Post-verify gate ──
DO $$
DECLARE
  n_missing int; n_unflagged int; n_fn int; v_office uuid; v_pol uuid; v_term uuid; n_terms_before int;
BEGIN
  SELECT count(*) INTO n_fn FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname='essentials' AND p.proname IN ('seat_officeholder','vacate_office');
  IF n_fn <> 2 THEN RAISE EXCEPTION 'expected 2 helper functions, found %', n_fn; END IF;

  SELECT count(*) INTO n_missing   FROM essentials.offices_missing_terms;
  SELECT count(*) INTO n_unflagged FROM essentials.offices_missing_terms
   WHERE is_vacant IS DISTINCT FROM true;
  IF n_missing <> 857 OR n_unflagged <> 699 THEN
    RAISE NOTICE 'drift baseline moved: % missing / % unflagged (documented baseline 857 / 699)',
      n_missing, n_unflagged;
  END IF;

  -- BEHAVIOUR TEST: seat a successor on a real office inside this transaction, assert the two-step
  -- happened and the exclusion constraint stayed satisfied, then undo it. Proves the function works
  -- against real data rather than trusting that it compiles.
  SELECT t.office_id, t.politician_id INTO v_office, v_pol
    FROM essentials.office_terms t
   WHERE t.term_end IS NULL AND t.politician_id IS NOT NULL
   LIMIT 1;

  SELECT count(*) INTO n_terms_before FROM essentials.office_terms WHERE office_id = v_office;

  -- pick any OTHER politician as the notional successor
  SELECT p.id INTO v_pol FROM essentials.politicians p WHERE p.id <> v_pol LIMIT 1;

  v_term := essentials.seat_officeholder(
    v_office, v_pol, CURRENT_DATE + 30, 'behaviour test in migration 1464', 'elected');

  IF v_term IS NULL THEN RAISE EXCEPTION 'seat_officeholder returned NULL'; END IF;
  IF (SELECT count(*) FROM essentials.office_terms WHERE office_id = v_office) <> n_terms_before + 1 THEN
    RAISE EXCEPTION 'seat_officeholder did not add exactly one term';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms
                  WHERE office_id = v_office AND term_end = CURRENT_DATE + 29) THEN
    RAISE EXCEPTION 'predecessor term was not closed the day before the successor started';
  END IF;
  -- idempotency: calling again must not add a second row
  IF essentials.seat_officeholder(v_office, v_pol, CURRENT_DATE + 30,
       'behaviour test in migration 1464', 'elected') <> v_term THEN
    RAISE EXCEPTION 'seat_officeholder is not idempotent';
  END IF;

  RAISE NOTICE 'helpers verify PASSED: seat_officeholder two-step + idempotency proven on office %; drift view at %/% (missing/unflagged).',
    v_office, n_missing, n_unflagged;

  -- undo the behaviour test
  DELETE FROM essentials.office_terms WHERE id = v_term;
  UPDATE essentials.office_terms SET term_end = NULL, how_ended = NULL
   WHERE office_id = v_office AND term_end = CURRENT_DATE + 29;
END $$;

COMMIT;
