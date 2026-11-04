-- CC_0338 — seat_officeholder: a re-elected incumbent gets a FRESH TERM ROW, and the silent
--            no-op that used to swallow that case is now impossible.
--
-- THE DEFECT. The helper's same-politician branch read:
--
--     IF v_prev_pol IS NOT DISTINCT FROM p_politician_id THEN
--       RETURN v_prev_id;          -- "nothing to hand over"
--     END IF;
--
-- so calling it with the SITTING HOLDER returned the existing term and wrote nothing. Measured
-- against production 2026-11-04, before this file: seating the sitting Texas senator at
-- 2027-01-03 left `terms_for_holder = 1`. No new row, no closed predecessor, no error.
--
-- 🔴 WHY THAT MATTERS NOW, AND AT SCALE. Re-election is the MAJORITY case, not an edge case.
-- Of the 2,078 races on 2026-11-03 whose office has a current holder, **1,088 (52%) have that
-- holder on their own ballot — 378 of 468 federal seats (81%)**. A transition tracker that
-- defines "seated" as "a future-dated term exists" would report every one of those as
-- permanently unfinished.
--
-- 🔴 AND FOR A HOLDER WHOSE TERM ALREADY ENDS, THE NO-OP IS ACTIVELY WRONG. Two federal seats
-- (SC Senate, one GA U.S. House) carry `term_end = 2027-01-03`. If such a holder is re-elected
-- and the helper no-ops, the office resolves as UNHELD from 2027-01-04 — an address search
-- returning a seat with no name.
--
-- A term is a TENURE. Re-election starts a new one, and "when did the current term begin" has
-- to stay answerable.
--
-- 🔴 WHY A NEW PARAMETER RATHER THAN JUST DELETING THE BRANCH. Deleting it would silently change
-- behaviour for every existing caller across ~2,469 migration slots: any re-run that passed the
-- same person with a DIFFERENT date would start creating terms where it used to create none.
-- Instead the case becomes explicit and, when not requested, LOUD:
--
--     p_allow_reelection => false (default)  the same person already covering the date is an
--                                            ERROR naming the choice. Never silent again.
--     p_allow_reelection => true             close the old term at p_term_start - 1 and insert
--                                            a new one, exactly as a handover to someone else.
--
-- Existing callers keep their behaviour everywhere except this one case, where a silent no-op
-- becomes a raised exception — recoverable, and visible, which the no-op was not.
--
-- ⚠ IDEMPOTENCY IS NARROWER THAN IT LOOKS AND ALWAYS WAS. The re-run check at the top matches
-- on (office_id, politician_id, term_start). A repeat call with the SAME date is still a no-op.
-- A repeat call with a DIFFERENT date and p_allow_reelection => true creates a third term. So a
-- caller must pass the term start from a dated source, NEVER `CURRENT_DATE`.
--
-- Everything else about the function is unchanged, including the guard that refuses a
-- predecessor starting on or after the successor, and `SET search_path TO ''`.

BEGIN;

-- 🔴 THE OLD 7-ARGUMENT FUNCTION MUST BE DROPPED, NOT REPLACED. `CREATE OR REPLACE` matches on
-- the full argument list, so adding p_allow_reelection would create an OVERLOAD beside the old
-- function rather than replacing it -- and then every existing 4-argument call site
-- (`seat_officeholder(office, politician, date, source)`) matches BOTH via their defaults and
-- fails with "function essentials.seat_officeholder(...) is not unique". Dropping first is what
-- makes this a replacement.
DROP FUNCTION IF EXISTS essentials.seat_officeholder(uuid, uuid, date, text, text, text, text);

CREATE OR REPLACE FUNCTION essentials.seat_officeholder(
  p_office_id        uuid,
  p_politician_id    uuid,
  p_term_start       date,
  p_source           text,
  p_how_started      text    DEFAULT 'elected',
  p_start_precision  text    DEFAULT 'day',
  p_how_ended_prev   text    DEFAULT 'term_expired',
  p_allow_reelection boolean DEFAULT false
)
RETURNS uuid
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
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
    -- The same person is already holding through this date. This is re-election (or a
    -- correction). It is NEVER a silent no-op: either the caller asked for it, or it raises.
    IF v_prev_pol IS NOT DISTINCT FROM p_politician_id AND NOT p_allow_reelection THEN
      RAISE EXCEPTION 'seat_officeholder: % already holds office % through % (term % starts %). '
                      'If this is re-election, pass p_allow_reelection => true to close that term '
                      'at % and open a new one. If it is not, the winner or the date is wrong.',
                      p_politician_id, p_office_id, p_term_start, v_prev_id, v_prev_start,
                      p_term_start - 1;
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
END $function$;

COMMENT ON FUNCTION essentials.seat_officeholder(uuid, uuid, date, text, text, text, text, boolean) IS
  'Seat an officeholder from a date, closing the predecessor the day before. '
  'Idempotent on (office_id, politician_id, term_start). '
  'Re-election (the same person already covering the date) requires p_allow_reelection => true; '
  'without it the call RAISES rather than silently doing nothing. CC_0338.';

COMMIT;
