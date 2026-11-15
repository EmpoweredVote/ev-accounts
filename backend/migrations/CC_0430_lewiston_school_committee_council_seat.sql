-- CC_0430 — Lewiston ME school committee: create and seat the council-appointed NINTH seat.
--
-- Closes the follow-up `CC_0429` left open and dated 2026-11-14 (ROSTERS.md R9l). Lewiston's
-- charter creates a committee of NINE and we hold EIGHT:
--
--   "There shall be a school committee of nine (9) members, composed of one (1) qualified voter
--    to be elected from each ward, one (1) at-large member to be elected from any ward, ... and
--    one (1) city council member to be nominated by the mayor and appointed by the city council
--    from any ward, who shall serve a one (1) year term"
--
--   7 wards + 1 at-large = our 8. This file creates the ninth.
--
-- 🔴 WHY IT WAS NOT CREATED BEFORE, AND WHAT CHANGED. `CC_0429` deliberately stopped short:
-- creating an office is an occupancy act, so it must seat its holder or the 238 drift baseline
-- rises, and naming that councillor needed a roster this committee publishes as an IMAGE. A name
-- is not guessable and namesakes reach production. The name is now sourced twice, from the two
-- bodies' own records rather than from a name search:
--
--   1. lewistonpublicschools.org school committee page. The roster is still images — but each
--      member card carries an `aria-label` with the name, and the page carries exactly NINE:
--      the eight we hold (Hawkins only as lhawkins@lewistonpublicschools.org, exactly as R9j
--      recorded) plus "Scott Harriman".
--   2. lewistonmaine.gov DocumentCenter/View/376, "City of Lewiston Boards and Committees",
--      the city's own appointment listing, generated 2026-10-21:
--
--         School Committee Representative   City Councilor   1/4/2027   Ward 3
--         01/05/2026 Scott Harriman
--
-- And the council's own minutes for 2026-01-05 (ArchiveCenter/ViewFile/Item/6695) record the act:
--   "ELECTION OF CITY COUNCIL MEMBER TO SERVE ON THE SCHOOL COMMITTEE FOR 2026 ...
--    To receive the Mayor's nomination of Councilor Harriman and to elect Councilor Harriman as
--    the City Councilor to serve on the School Committee, said term to expire January 4, 2027."
--
-- 🔴 `is_appointed_position = TRUE`, AND THIS IS THE ONE SEAT ON THIS BODY WHERE THAT IS RIGHT.
-- `CC_0429` cleared the flag off Ward 5 because filling a vacancy by appointment does not change
-- what the SEAT is. This seat is the opposite case: the charter makes it appointive, residents
-- never vote on it, and the API publishes `is_elected` as this column's negation. So the eight
-- elected seats stay false and this one is true. ⚠ ROSTERS.md R9h records Maine as holding
-- exactly THREE appointed-flagged offices (AG, Secretary of State, Treasurer). This file makes it
-- FOUR, on purpose, and R9h is updated in the same commit. `CC_0429`'s gate was a one-time
-- post-verify and `audit-is-appointed.ts` is read-only and not wired into CI, so nothing standing
-- breaks.
--
-- 🔴 term_start IS 2026-01-05, AND THE EIGHT SIBLING ROWS ARE NOT THE PRECEDENT THEY LOOK LIKE.
-- All eight carry term_start NULL / start_precision 'unknown', which reads like a house style for
-- this committee. It is not: every one of them says `source = 'backfill from
-- essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)'`. They are undated because
-- the backfill had no date to give, not because somebody judged the date unknowable.
--
-- This seat IS dated, twice, and `essentials.office_terms` is a table of TERMS. The council elects
-- this seat ANNUALLY ("...FOR 2026") for a defined one-year term, and its own minutes record this
-- term beginning on 2026-01-05. So the row asserts "a term began on 2026-01-05", which is exactly
-- what the record says — NOT "his tenure began then".
--
-- ⚠ WHETHER HE SERVED BEFORE 2026 IS STILL UNKNOWN, and this file does not claim otherwise. Two
-- committee members objected to him continuing, which READS like prior service but does not say
-- so, and the minutes say "elect", never "re-elect". If he did serve earlier, those are PRIOR
-- terms we simply do not hold — a gap, not a misstatement. ▶ Anyone dating them should close this
-- term's predecessor rather than editing this row.
--
-- (`seat_officeholder` refuses a NULL start by design — "requires a real term_start" — which is
-- the same judgement arrived at from the other side.)
--
-- ⚠ term_end IS ALSO NULL, THOUGH THE COUNCIL PUBLISHED 2027-01-04. ROSTERS.md R4 forbids writing
-- a published expiry to `term_end`, and the reason bites here: the view resolves occupancy by date
-- containment, so a dated end would silently UNSEAT this seat on 2027-01-05 and raise the drift
-- baseline with no human act. ▶ The January 2027 re-election is a follow-up, recorded in R9l.
--
-- ⚠ FOUND WHILE DOING THIS, NOT FIXED HERE: we hold Scott Harriman as TWO politician rows —
-- `c7088ceb` "Scott A. Harriman" (Lewiston Council Member, Ward 3) and `9664affa` "Scott Harriman"
-- (Maine House District 94, whose own roster reads "Harriman, Scott ... (D - Lewiston)"). They are
-- very probably one man who won a February 2026 special election while keeping his council seat.
-- A person merge carries FK, stance-research and season-floor obligations and is its own decision,
-- so this file only SEATS, and seats the COUNCIL row, because the charter seats him here as the
-- City Councilor. If the rows are later merged the seat moves with the merge.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0430_lewiston_school_committee_council_seat.sql

BEGIN;

-- ── Premise. If any of this is not true, the file is reasoning about a body that has changed. ──
DO $$
DECLARE
  v_offices  int;
  v_stated   int;
  v_name     text;
BEGIN
  SELECT ch.official_count,
         (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id)
    INTO v_stated, v_offices
    FROM essentials.chambers ch
   WHERE ch.id = '72841b2e-34a0-4a24-a27d-cded6a0442ab';

  IF v_stated IS DISTINCT FROM 9 THEN
    RAISE EXCEPTION 'CC_0430: Lewiston School Committee official_count is %, expected 9 (CC_0429 set it).', v_stated;
  END IF;
  IF v_offices <> 8 THEN
    RAISE EXCEPTION 'CC_0430: expected 8 existing offices on this committee, found %.', v_offices;
  END IF;

  -- 🔴 A NAME MATCH IS A HYPOTHESIS — ASK WHAT THAT PERSON ALREADY HOLDS. This asserts the row we
  -- are about to seat is the Ward 3 COUNCILLOR, not a namesake and not the State House row.
  SELECT p.full_name INTO v_name
    FROM essentials.politicians p
    JOIN essentials.office_terms t ON t.politician_id = p.id
    JOIN essentials.offices o ON o.id = t.office_id
   WHERE p.id = 'c7088ceb-3326-40ac-81b7-d93926c6060f'
     AND o.chamber_id = 'cd753079-75f0-461a-8e86-619cf8899066'   -- Lewiston City Council
     AND o.title = 'Council Member (Ward 3)'
     AND t.term_end IS NULL;

  IF v_name IS DISTINCT FROM 'Scott A. Harriman' THEN
    RAISE EXCEPTION
      'CC_0430: politician c7088ceb does not currently hold Lewiston Council Member (Ward 3); got %. '
      'The charter seats this person as the City Councilor, so if he no longer is one, the whole '
      'premise of this file is wrong.', coalesce(v_name, '(no such current term)');
  END IF;

  -- He must not already sit on this committee, or we would be creating a second seat for him.
  IF EXISTS (
    SELECT 1 FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
     WHERE o.chamber_id = '72841b2e-34a0-4a24-a27d-cded6a0442ab'
       AND t.politician_id = 'c7088ceb-3326-40ac-81b7-d93926c6060f'
  ) THEN
    RAISE EXCEPTION 'CC_0430: Scott A. Harriman already holds a seat on this committee.';
  END IF;
END $$;

-- ── Capture the before-state, in this transaction (see _templates/body_completeness_delta.sql) ──
CREATE TEMP TABLE _bc_before ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM essentials.offices)                                     AS offices,
  (SELECT count(*) FROM essentials.offices o
     WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id))
                                                                                AS termless_offices,
  (SELECT count(*) FROM essentials.offices_missing_terms m
     JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant)      AS drift_unflagged;

-- ── The seat ───────────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, is_vacant, voting_powers)
SELECT '72841b2e-34a0-4a24-a27d-cded6a0442ab',
       'eb583223-6ddc-4c0e-97e9-795ba88d4aa0',
       'School Committee Member (City Council Representative)',
       'ME',
       true,     -- see the header: the only genuinely appointive seat on this body
       false,
       'full'    -- the charter makes the council member a full member, not an ex-officio observer
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices
   WHERE chamber_id = '72841b2e-34a0-4a24-a27d-cded6a0442ab'
     AND title = 'School Committee Member (City Council Representative)'
);

SELECT essentials.seat_officeholder(
  (SELECT id FROM essentials.offices
    WHERE chamber_id = '72841b2e-34a0-4a24-a27d-cded6a0442ab'
      AND title = 'School Committee Member (City Council Representative)'),
  'c7088ceb-3326-40ac-81b7-d93926c6060f',
  DATE '2026-01-05',
  'Lewiston city charter art. VI (nine-member committee incl. one city councillor nominated by the '
  'mayor and appointed by the council, one-year term); sources/me-lewiston-charter-2026-11-14.txt. '
  'HOLDER sourced twice from the two bodies'' own records: lewistonpublicschools.org school '
  'committee page lists exactly nine members and "Scott Harriman" is the ninth; lewistonmaine.gov '
  'DocumentCenter/View/376 "City of Lewiston Boards and Committees" (generated 2026-10-21) prints '
  '"School Committee Representative / City Councilor / Ward 3 / 01/05/2026 Scott Harriman", term '
  'expiring 1/4/2027. The council elected him on 2026-01-05 (council minutes, '
  'lewistonmaine.gov/ArchiveCenter/ViewFile/Item/6695: "ELECTION OF CITY COUNCIL MEMBER TO SERVE '
  'ON THE SCHOOL COMMITTEE FOR 2026 ... said term to expire January 4, 2027"). term_start is THIS '
  'TERM''s start, which the council dated; the seat is re-elected annually, so whether he served '
  'before 2026 is not established -- the minutes say "elect", never "re-elect" -- and any earlier '
  'terms are simply not held. term_end is NULL per ROSTERS.md R4: writing the published 2027-01-04 '
  'expiry would unseat this seat on 2027-01-05 with no human act. CC_0430.',
  'appointed',   -- p_how_started: nominated by the mayor, elected by the council, never by voters
  'day'          -- p_start_precision
);

-- ── Post-verify ────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_offices   int;
  v_people    int;
  v_stated    int;
  v_appointed int;
  v_holder    text;
  v_new_off   int;
  v_new_term  int;
  v_drift     int;
BEGIN
  SELECT ch.official_count,
         (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id),
         (SELECT count(DISTINCT t.politician_id)
            FROM essentials.offices o
            JOIN essentials.office_terms t ON t.office_id = o.id
           WHERE o.chamber_id = ch.id AND t.politician_id IS NOT NULL
             AND (t.term_end IS NULL OR t.term_end >= current_date)),
         (SELECT count(*) FROM essentials.offices o
           WHERE o.chamber_id = ch.id AND o.is_appointed_position)
    INTO v_stated, v_offices, v_people, v_appointed
    FROM essentials.chambers ch
   WHERE ch.id = '72841b2e-34a0-4a24-a27d-cded6a0442ab';

  IF v_offices <> 9 THEN
    RAISE EXCEPTION 'CC_0430: committee holds % offices, expected 9.', v_offices;
  END IF;
  IF v_offices <> v_stated THEN
    RAISE EXCEPTION 'CC_0430: % offices against an official_count of % -- check:body-completeness would fire.', v_offices, v_stated;
  END IF;

  -- 🔴 ASK HOW MANY DISTINCT PEOPLE HOLD THE BODY'S OFFICES. South Portland read "every seat
  -- occupied" with 8 offices and 7 people. Nine here means nobody holds two seats on this body.
  IF v_people <> 9 THEN
    RAISE EXCEPTION 'CC_0430: 9 offices but % distinct current holders -- somebody holds two seats.', v_people;
  END IF;

  -- The eight elected seats must NOT have acquired the flag, and the new one must carry it.
  IF v_appointed <> 1 THEN
    RAISE EXCEPTION
      'CC_0430: % appointed-flagged offices on this committee, expected exactly 1. The API '
      'publishes is_elected as this column''s negation, so a wrong flag tells residents they do '
      'not elect a seat they do elect.', v_appointed;
  END IF;

  SELECT p.full_name INTO v_holder
    FROM essentials.offices o
    JOIN essentials.office_terms t ON t.office_id = o.id
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE o.chamber_id = '72841b2e-34a0-4a24-a27d-cded6a0442ab'
     AND o.title = 'School Committee Member (City Council Representative)'
     AND t.term_end IS NULL;

  IF v_holder IS DISTINCT FROM 'Scott A. Harriman' THEN
    RAISE EXCEPTION 'CC_0430: the new seat is held by %, expected Scott A. Harriman.', coalesce(v_holder, 'nobody');
  END IF;

  -- ── The delta guards. Gate on the change this file makes, never on a total another session
  --    can move while the file is being written.
  SELECT (SELECT count(*) FROM essentials.offices) - b.offices,
         (SELECT count(*) FROM essentials.offices o
            WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id))
           - b.termless_offices,
         (SELECT count(*) FROM essentials.offices_missing_terms m
            JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant)
           - b.drift_unflagged
    INTO v_new_off, v_new_term, v_drift
    FROM _bc_before b;

  IF v_new_off <> 1 THEN
    RAISE EXCEPTION 'CC_0430: created % offices, expected exactly 1.', v_new_off;
  END IF;
  IF v_new_term <> 0 THEN
    RAISE EXCEPTION
      'CC_0430: the office this file created carries no office_terms row. An unseated office is '
      'invisible everywhere and nothing errors. That is the whole reason CC_0429 did not create it.';
  END IF;
  IF v_drift <> 0 THEN
    RAISE EXCEPTION
      'CC_0430: the unflagged drift baseline moved by % -- creating this seat must leave the 238 '
      'baseline exactly where it was.', v_drift;
  END IF;

  RAISE NOTICE 'CC_0430 OK: Lewiston School Committee 8 -> 9 offices, 9 distinct holders, 1 appointed seat (Scott A. Harriman), drift baseline unmoved.';
END $$;

COMMIT;
