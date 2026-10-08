-- CC_0201 — prepare the Draper → Valbuena handover as DATED TERMS (safe to apply today)
--
-- WHY. Robert S. Draper lost the 2026-06-02 nonpartisan primary for his Los Angeles County Superior
-- Court seat to Tal Khan Valbuena, 43.2% to 56.8%. Valbuena won outright, so the 2026-11-03 general
-- for this seat was CANCELLED. Ballotpedia's page on Draper states: "His current term ends on
-- January 4, 2027." (Read from the page's own HTML, not from a search summary.)
--
-- 🔴 THIS DOES NOT CHANGE WHO HOLDS THE SEAT TODAY, AND MUST NOT. A certified result is not a fact
-- about who holds the seat. Draper is the sitting judge until his term ends. What this migration
-- does is write the handover as dated rows so the calendar performs it, which is the entire point
-- of the temporal model (ADR 0002):
--
--     essentials.current_office_holders filters
--       (term_start IS NULL OR term_start <= CURRENT_DATE)
--       AND (term_end IS NULL OR term_end >= CURRENT_DATE)
--
--   so Valbuena's 2027-01-05 row is INVISIBLE until that date, and Draper's row — now closed at
--   2027-01-04 instead of open-ended — keeps him current until then. No trigger, no job, no deploy.
--
-- HOW. One call to the helper, which does the two-step by design: it finds the term covering the
-- new start (Draper's open-ended row), sets its term_end to the day before, and inserts the
-- successor. It is idempotent, and it handles a predecessor whose term_start is NULL — which
-- Draper's is, because CA_0183 seated him from the court's roster with no start date in the source.
--
-- ⚠ THE DATE IS DERIVED, AND HERE IS THE DERIVATION. The source dates the END of Draper's term to
-- 2027-01-04, so his last day held is 2027-01-04 and the successor's first day is 2027-01-05.
-- I did NOT find a document stating Valbuena's own swearing-in date. California superior court
-- terms conventionally begin the Monday after 1 January, which in 2027 is 4 January — one day
-- earlier than this. If the court's own record gives that day, correct this row; the two candidate
-- dates differ by one day and nothing downstream turns on which it is until January.
--
-- 🔴 WHAT THIS MIGRATION DELIBERATELY DOES NOT DO. Two columns cache "current" and will NOT flip
-- when the calendar advances — exactly the thing CLAUDE.md warns against caching:
--
--     politicians.is_incumbent   Draper true,  Valbuena false
--     politicians.office_id      Draper holds the office id, Valbuena NULL   (legacy snapshot)
--
--   Nothing in the codebase recomputes either: is_incumbent is only READ, as a filter, in four
--   places in essentialsBrowseService.ts. Flipping them today would make TODAY wrong, so they are
--   left alone here and handled by CC_0202, which is written and must NOT be applied before
--   2027-01-05.
--
-- Rollback: delete the inserted term and restore Draper's row to term_end NULL, how_ended NULL.
--   DELETE FROM essentials.office_terms
--    WHERE office_id = '83969e0c-c530-4649-bf82-68e25eca0c85'
--      AND politician_id = '917d6200-f048-4b7b-85f7-3a390abeecf2';
--   UPDATE essentials.office_terms SET term_end = NULL, how_ended = NULL
--    WHERE id = 'a001db41-eb2d-43fa-8f8c-e7e3c42d658c';

BEGIN;

SELECT essentials.seat_officeholder(
  '83969e0c-c530-4649-bf82-68e25eca0c85'::uuid,   -- Judge, LA County Superior Court (Draper's seat)
  '917d6200-f048-4b7b-85f7-3a390abeecf2'::uuid,   -- Tal K. Valbuena
  DATE '2027-01-05',
  'CC_0201 (2026-10-08): elected 2026-06-02, winning the nonpartisan primary outright against '
  || 'incumbent Robert S. Draper 56.8% to 43.2%; the 2026-11-03 general for this seat was '
  || 'cancelled. Start derived from the sourced end of the predecessor''s term — Ballotpedia '
  || 'states Draper''s current term ends 2027-01-04 — not from a document stating Valbuena''s own '
  || 'swearing-in date. Correct if the court publishes that day.',
  p_how_started     => 'elected',
  p_start_precision => 'day',
  p_how_ended_prev  => 'term_expired'
);

DO $$
DECLARE
  v_office     uuid := '83969e0c-c530-4649-bf82-68e25eca0c85';
  v_draper     uuid := 'fa932212-a2cf-4fa1-97ab-c6619e3db610';
  v_valbuena   uuid := '917d6200-f048-4b7b-85f7-3a390abeecf2';
  v_now_holder uuid;
  v_d_end      date;
  v_v_start    date;
  v_v_end      date;
  v_terms      int;
BEGIN
  -- 🔴 THE ASSERTION THAT MATTERS MOST: today is unchanged. Draper still holds the seat.
  SELECT politician_id INTO v_now_holder
    FROM essentials.office_current_holder WHERE office_id = v_office;
  IF v_now_holder IS DISTINCT FROM v_draper THEN
    RAISE EXCEPTION 'CC_0201: the CURRENT holder of % is now %, expected Draper (%). This migration '
                    'must not change who holds the seat today.', v_office,
                    coalesce(v_now_holder::text,'<vacant>'), v_draper;
  END IF;

  SELECT term_end INTO v_d_end
    FROM essentials.office_terms WHERE office_id = v_office AND politician_id = v_draper;
  IF v_d_end IS DISTINCT FROM DATE '2027-01-04' THEN
    RAISE EXCEPTION 'CC_0201: Draper''s term_end is %, expected 2027-01-04',
      coalesce(v_d_end::text,'<null>');
  END IF;

  SELECT term_start, term_end INTO v_v_start, v_v_end
    FROM essentials.office_terms WHERE office_id = v_office AND politician_id = v_valbuena;
  IF v_v_start IS DISTINCT FROM DATE '2027-01-05' THEN
    RAISE EXCEPTION 'CC_0201: Valbuena''s term_start is %, expected 2027-01-05',
      coalesce(v_v_start::text,'<null>');
  END IF;
  IF v_v_end IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0201: Valbuena''s term_end is %, expected NULL (open-ended)', v_v_end;
  END IF;

  -- Exactly two terms on this seat, and no gap between them.
  SELECT count(*) INTO v_terms FROM essentials.office_terms WHERE office_id = v_office;
  IF v_terms <> 2 THEN
    RAISE EXCEPTION 'CC_0201: office % has % term rows, expected 2', v_office, v_terms;
  END IF;
  IF v_v_start <> v_d_end + 1 THEN
    RAISE EXCEPTION 'CC_0201: a gap or overlap between the terms — Draper ends %, Valbuena starts %',
      v_d_end, v_v_start;
  END IF;

  -- And prove the handover actually fires, by asking the same predicate the view uses
  -- for a date after the boundary. This is the positive control: if it still answered
  -- "Draper", the dated rows would be decoration.
  IF (SELECT politician_id FROM essentials.office_terms
       WHERE office_id = v_office
         AND (term_start IS NULL OR term_start <= DATE '2027-01-05')
         AND (term_end   IS NULL OR term_end   >= DATE '2027-01-05')) IS DISTINCT FROM v_valbuena THEN
    RAISE EXCEPTION 'CC_0201: as of 2027-01-05 the seat does not resolve to Valbuena';
  END IF;
  IF (SELECT politician_id FROM essentials.office_terms
       WHERE office_id = v_office
         AND (term_start IS NULL OR term_start <= DATE '2027-01-04')
         AND (term_end   IS NULL OR term_end   >= DATE '2027-01-04')) IS DISTINCT FROM v_draper THEN
    RAISE EXCEPTION 'CC_0201: as of 2027-01-04 the seat does not resolve to Draper';
  END IF;

  RAISE NOTICE 'CC_0201: Draper holds the seat through 2027-01-04; Valbuena from 2027-01-05. '
               'Today is unchanged. CC_0202 still owes the cached columns.';
END $$;

COMMIT;
