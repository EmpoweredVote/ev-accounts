-- 1467_lewiston_ward7_levasseur_appointment.sql
-- Lewiston School Committee Ward 7: Donna Gallant -> Emily Levasseur, by mayoral appointment on
-- 2026-07-23. Idempotent. Requires 1458 + 1459 + 1462 + 1463 + 1464.
--
-- WHY. Migration 265 seeded Gallant (-890017) on Ward 7 and she was correct at the time. She
--   RESIGNED in June 2026, and the mayor appointed Emily Levasseur on 2026-07-23 to serve the
--   remainder of the term. Found by auditing all five Maine school boards against live sources on
--   2026-07-26; Ward 7 was the only stale seat across Lewiston, Bangor, Auburn and Biddeford (the
--   other 29 seats all verified correct).
--
--   Migration 1465 already KNEW this fact — its header cites "Levasseur to Ward 7 July 2026" as
--   evidence that Lewiston fills vacancies by prompt appointment, using it to argue the Ward 5
--   timeline. It did not act on it because its scope was strictly the five offices where
--   offices.is_vacant contradicted a current term, and Ward 7 was never flagged vacant. So this is a
--   known-but-unactioned gap being closed, not a newly discovered one.
--
-- SOURCES.
--   [S1] sunjournal.com 2026-07-23, "Mayor appoints Lewiston parent to fill Ward 7 vacancy on
--        school committee" — Mayor Carl Sheline appointed Emily Levasseur (28) on Tuesday
--        2026-07-23; she replaces Donna Gallant, who resigned in June 2026; the term she is
--        finishing expires 2026-12-31; her first meeting is 2026-08-03. She intends to run for the
--        seat in the November 2026 election.
--   [S2] sunjournal.com 2026-06-19, "Lewiston municipal election nomination papers available
--        Monday" — lists the four school committee seats up in Nov 2026 with sitting incumbents,
--        Ward 7 still Donna Gallant. Brackets the resignation to between 2026-06-19 and 2026-07-23.
--   [S3] sunjournal.com 2023-10-13, "Ward 7: Donna Gallant vies for Ward 7 Lewiston School
--        Committee seat" — establishes Gallant as the elected Ward 7 member, i.e. a real
--        officeholder, not a seeding guess.
--
-- THIS IS THE FIRST SEAT IN THIS SERIES WITH A REAL DATED HAND-OFF, so unlike 1465 and 1466 it uses
--   essentials.seat_officeholder(). 2026-07-23 is published, not derived, and the start is therefore
--   start_precision 'day' with how_started 'appointed'.
--
-- THE ONE APPROXIMATION, stated plainly. Gallant's resignation is sourced only to the MONTH ("a
--   spot opened up on the committee in June when Donna Gallant, Ward 7, resigned" [S1]); no source
--   gives the day. seat_officeholder closes the predecessor the day before the successor starts, so
--   Gallant's term_end lands on 2026-07-22 and the seat shows continuous occupancy across a gap that
--   was really vacant for up to five weeks.
--
--   That is a deliberate choice between two imperfect records, because office_terms has a
--   start_precision column but NO end_precision, so "ended sometime in June 2026" is not
--   expressible:
--     - Closing her at 2026-06-30 instead would invent a specific last day (and CLAUDE.md forbids
--       writing a vacancy span whose start is unknown, which is what the resulting gap would need).
--     - Closing her the day before the successor is seat_officeholder's documented contract and a
--       boundary CONVENTION, not an assertion about her last day in the room.
--   The convention is the smaller lie and the sanctioned one. how_ended = 'resigned' keeps the
--   REASON truthful even though the boundary is approximate. If anyone finds the actual resignation
--   date, the honest refinement is to move Gallant's term_end back and simply leave the intervening
--   days with no term row at all — a gap already reads as vacant through
--   essentials.office_current_holder, so no vacancy span needs inventing.
--
-- TERM_END IS WRITTEN, and that is intentional. Levasseur finishes a term expiring 2026-12-31 [S1],
--   so from 2027-01-01 this seat correctly reads VACANT until the November 2026 winner is seated.
--   That is ADR 0002 working as designed — a term that ends with no successor reads as vacant, with
--   nothing scheduled to make it happen. FOLLOW-UP REQUIRED after the 2026-11-03 election: seat the
--   winner (Levasseur intends to run) with a real term_start. Leaving term_end NULL instead would
--   have claimed she holds the seat indefinitely, which the source contradicts.
--
-- seat_officeholder takes no term_end, so the returned term id is used to set it in the same
--   transaction. -890020 continues Lewiston's block (-890011..-890018 from 265, -890019 = Hawkins
--   from 1465). Verified free in prod before writing.
--
-- NOT TOUCHED: offices.is_appointed_position stays false on Ward 7. The seat is ELECTIVE and merely
--   happens to be filled by appointment right now; that fact belongs to the tenure
--   (office_terms.how_started = 'appointed'), not to the seat. Note Ward 5 carries the flag as true
--   from 265, which is arguably the same error in the other direction — out of scope here.
BEGIN;

-- =============================================================================
-- Pre-flight: the seat exists and holds who we think it holds
-- =============================================================================
DO $$
DECLARE
  v_office  uuid;
  v_holder  uuid;
  v_gallant uuid;
BEGIN
  SELECT o.id INTO v_office
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'Lewiston Public Schools, Maine, US'
     AND ch.name = 'School Committee'
     AND o.title = 'School Committee Member (Ward 7)';
  IF v_office IS NULL THEN
    RAISE EXCEPTION 'Lewiston School Committee Ward 7 office not found — migration 265 not applied?';
  END IF;

  SELECT id INTO v_gallant FROM essentials.politicians WHERE external_id = -890017;
  IF v_gallant IS NULL THEN
    RAISE EXCEPTION 'Donna Gallant (-890017) not found — unexpected; re-verify before writing';
  END IF;

  SELECT och.politician_id INTO v_holder
    FROM essentials.office_current_holder och WHERE och.office_id = v_office;

  -- Accept exactly two states: already applied, or still Gallant (the state to fix).
  --
  -- "Already applied" is tested by the EXISTENCE of Levasseur's term, NOT by her being the current
  -- holder. That distinction matters: this migration writes a term that EXPIRES on 2026-12-31, so
  -- from 2027-01-01 the seat correctly resolves to nobody. Keying the guard on the current holder
  -- would make a re-run after that date abort with "held by <NULL>" — an idempotency trap in a
  -- migration whose whole point is a dated expiry.
  IF EXISTS (
    SELECT 1 FROM essentials.office_terms t
      JOIN essentials.politicians p ON p.id = t.politician_id
     WHERE t.office_id = v_office AND p.external_id = -890020
  ) THEN
    RAISE NOTICE 'Ward 7 already carries Emily Levasseur''s term — verifying end state only';
  ELSIF v_holder IS DISTINCT FROM v_gallant THEN
    RAISE EXCEPTION 'Ward 7 is held by politician % — expected Donna Gallant (%). Re-verify '
                    'before overwriting.', v_holder, v_gallant;
  END IF;
END $$;

-- =============================================================================
-- 1. The appointee
-- =============================================================================
-- is_appointed = true matches 1465's treatment of Lynnea Hawkins, the other sitting appointee.
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed,
   is_vacant, is_incumbent, external_id, data_source)
VALUES (gen_random_uuid(), 'Emily Levasseur', 'Emily', 'Levasseur', NULL,
        true, true, false, true, -890020, 'sunjournal.com')
ON CONFLICT (external_id) DO NOTHING;

-- =============================================================================
-- 2. Retire Gallant — a real former member, kept as a row
-- =============================================================================
UPDATE essentials.politicians
   SET is_incumbent = false
 WHERE external_id = -890017
   AND is_incumbent IS DISTINCT FROM false;

-- =============================================================================
-- 3. The hand-off, via the sanctioned helper, then the known term_end
-- =============================================================================
DO $$
DECLARE
  v_office uuid;
  v_emily  uuid;
  v_term   uuid;
BEGIN
  SELECT o.id INTO v_office
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'Lewiston Public Schools, Maine, US'
     AND ch.name = 'School Committee'
     AND o.title = 'School Committee Member (Ward 7)';

  SELECT id INTO v_emily FROM essentials.politicians WHERE external_id = -890020;
  IF v_emily IS NULL THEN
    RAISE EXCEPTION 'Emily Levasseur (-890020) missing — step 1 did not insert';
  END IF;

  -- Closes Gallant at 2026-07-22 and opens Levasseur at 2026-07-23. Idempotent: a re-run finds the
  -- identical (office, politician, term_start) and returns the existing row without adding another.
  v_term := essentials.seat_officeholder(
    v_office,
    v_emily,
    DATE '2026-07-23',
    'migration 1467: sunjournal.com 2026-07-23 "Mayor appoints Lewiston parent to fill Ward 7 '
    'vacancy on school committee" — Mayor Sheline appointed Levasseur 2026-07-23 to finish the term '
    'expiring 2026-12-31. NOTE Gallant resigned in JUNE 2026 (day not published), so her term_end '
    'of 2026-07-22 is seat_officeholder''s day-before boundary convention, not her last day served; '
    'the seat was actually vacant for part of that span. office_terms has no end_precision column '
    'to record that.',
    'appointed',        -- how_started
    'day',              -- start_precision: 2026-07-23 is published, not derived
    'resigned'          -- how_ended on Gallant's term: the reason is certain, the date approximate
  );

  -- Her term is a REMAINDER with a published expiry, so record it rather than leaving it open-ended.
  UPDATE essentials.office_terms
     SET term_end = DATE '2026-12-31'
   WHERE id = v_term
     AND term_end IS DISTINCT FROM DATE '2026-12-31';

  RAISE NOTICE 'Ward 7: Gallant closed 2026-07-22 (resigned), Levasseur seated 2026-07-23 through '
               '2026-12-31 on office % (term %)', v_office, v_term;
END $$;

-- =============================================================================
-- Post-verify gate
-- =============================================================================
-- Asserts against FIXED dates via office_holders_as_of, not "today": this migration must keep
-- passing when re-run after 2026-12-31, at which point the seat legitimately reads vacant.
DO $$
DECLARE
  v_office   uuid;
  v_emily    uuid;
  v_gallant  uuid;
  v_now      uuid;
  v_before   uuid;
  v_after    uuid;
  v_terms    int;
  v_end      date;
BEGIN
  SELECT o.id INTO v_office
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'Lewiston Public Schools, Maine, US'
     AND ch.name = 'School Committee'
     AND o.title = 'School Committee Member (Ward 7)';

  SELECT id INTO v_emily   FROM essentials.politicians WHERE external_id = -890020;
  SELECT id INTO v_gallant FROM essentials.politicians WHERE external_id = -890017;

  -- 1. Levasseur holds the seat on a date inside her term.
  SELECT politician_id INTO v_now
    FROM essentials.office_holders_as_of(DATE '2026-08-01') WHERE office_id = v_office;
  IF v_now IS DISTINCT FROM v_emily THEN
    RAISE EXCEPTION 'as of 2026-08-01 Ward 7 should be Emily Levasseur, got %', v_now;
  END IF;

  -- 2. History preserved: Gallant still answers for an earlier date.
  SELECT politician_id INTO v_before
    FROM essentials.office_holders_as_of(DATE '2026-01-01') WHERE office_id = v_office;
  IF v_before IS DISTINCT FROM v_gallant THEN
    RAISE EXCEPTION 'as of 2026-01-01 Ward 7 should still be Donna Gallant, got %', v_before;
  END IF;

  -- 3. The seat reads VACANT once her remainder term expires — the intended dated consequence.
  SELECT politician_id INTO v_after
    FROM essentials.office_holders_as_of(DATE '2027-01-01') WHERE office_id = v_office;
  IF v_after IS NOT NULL THEN
    RAISE EXCEPTION 'as of 2027-01-01 Ward 7 should have no holder (term expired), got %', v_after;
  END IF;

  -- 4. Her term carries the published expiry.
  SELECT term_end INTO v_end
    FROM essentials.office_terms WHERE office_id = v_office AND politician_id = v_emily;
  IF v_end IS DISTINCT FROM DATE '2026-12-31' THEN
    RAISE EXCEPTION 'Levasseur term_end should be 2026-12-31, got %', v_end;
  END IF;

  -- 5. Exactly two terms on this seat, and no double-occupancy on any date.
  SELECT count(*) INTO v_terms FROM essentials.office_terms WHERE office_id = v_office;
  IF v_terms <> 2 THEN
    RAISE EXCEPTION 'expected exactly 2 terms on Ward 7 (Gallant + Levasseur), found %', v_terms;
  END IF;

  -- 6. Gallant is no longer flagged an incumbent anywhere.
  IF (SELECT is_incumbent FROM essentials.politicians WHERE external_id = -890017) THEN
    RAISE EXCEPTION 'Donna Gallant is still flagged is_incumbent';
  END IF;

  RAISE NOTICE 'Lewiston Ward 7 PASSED: Gallant -> Levasseur on 2026-07-23, term_end 2026-12-31; '
               'history intact as of 2026-01-01; seat reads vacant from 2027-01-01 (needs the '
               'Nov 2026 winner seated).';
END $$;

COMMIT;
