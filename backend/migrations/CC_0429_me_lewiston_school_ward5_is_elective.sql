-- CC_0429: Lewiston, Maine -- a WARD school-committee seat was published to voters as NOT ELECTED
--          because the person holding it was appointed to fill a vacancy. The appointment is a
--          fact about HER ARRIVAL and it is already recorded, in the column that exists for it.
--
-- The last of the eight appointed-flagged Maine offices `CC_0427` classified, and the one it had
-- to leave open. It is now closed, and NOT by the route that was expected.
--
-- ═══ 🔴🔴 THE ANSWER WAS IN OUR OWN DATA, NOT IN THE BODY'S ROSTER ═══
-- `CC_0427` said this needed the Lewiston city clerk's election returns, because the committee
-- publishes its membership as an IMAGE. It needed neither. `essentials.office_terms` already
-- carries `how_started`, and both of this committee's appointees are marked with it:
--
--   Ward 5  Lynnea Hawkins   how_started = 'appointed'   office is_appointed_position = TRUE
--   Ward 7  Emily Levasseur  how_started = 'appointed'   office is_appointed_position = FALSE
--
-- 🟢 **THE CONTROL WAS ONE SEAT OVER ON THE SAME COMMITTEE.** Migration 1467 seated Levasseur
--    after Mayor Sheline appointed her on 2026-07-23 to finish a term, and it set `how_started`
--    and left the OFFICE elective -- which is right. Two identical situations on one body, two
--    opposite office flags. The charter says which of the two is correct.
-- ▶ **BEFORE GOING OUT FOR A SOURCE, ASK WHETHER THE SCHEMA ALREADY DISTINGUISHES THE TWO THINGS
--   YOU ARE TRYING TO TELL APART.** `how_started` is a property of a TENURE; `is_appointed_position`
--   is a property of a SEAT. The defect was a person-fact written onto an office.
--
-- ═══ WHAT THE CHARTER SAYS (committed under
--     backend/data/seed-me-municipal-2026/sources/me-lewiston-charter-2026-11-14.txt) ═══
--   "The qualified voters of each of the seven (7) wards of the city shall nominate and elect a
--    school committee member who shall be qualified to vote in the ward from which elected and the
--    qualified voters of the entire city shall nominate and elect one (1) at-large school
--    committee member..."
-- Every ward seat and the at-large seat are ELECTIVE. Filling a vacancy by appointment does not
-- change what the seat is.
--
-- ═══ 🔴 AND THE SAME CLAUSE FOUND A MISSING SEAT. THE COMMITTEE IS NINE; WE HOLD EIGHT. ═══
--   "There shall be a school committee of NINE (9) MEMBERS, composed of one (1) qualified voter to
--    be elected from each ward, one (1) at-large member to be elected from any ward, ... AND ONE
--    (1) CITY COUNCIL MEMBER TO BE NOMINATED BY THE MAYOR AND APPOINTED BY THE CITY COUNCIL from
--    any ward, who shall serve a one (1) year term..."
-- 7 wards + 1 at-large = our 8. The ninth is a sitting city councillor, appointed by the council
-- for one year -- and it is the ONLY genuinely appointed seat on this body. We do not model it.
--
-- ⚠ NOT CREATED HERE, DELIBERATELY. Creating an office is an occupancy act: it must seat its
--   holder or the 238 drift baseline rises (CLAUDE.md). Naming that holder needs the committee's
--   roster, and this committee publishes its membership as an image -- no page found names the
--   councillor who sits in it. 🔴 A NAME IS NOT GUESSABLE AND NAMESAKES REACH PRODUCTION. Written
--   up in ROSTERS.md as a dated follow-up instead.
--
-- 🟢 THIS IS WHY `official_count` IS SET: 9, FROM THE CHARTER, AGAINST OUR 8 ROWS. It records the
--    body's real size so the shortfall is COUNTABLE instead of invisible -- which is exactly what
--    made Bangor findable in `CC_0427` and what South Portland's self-confirming 8 could not do in
--    `CC_0428`.
--    ⚠ MEASURED BEFORE SETTING IT: `official_count` IS READ BY NOTHING IN `backend/src` -- zero
--      occurrences. It is metadata for sessions and gates, not a voter-facing field, so recording
--      a size larger than our row count cannot render a phantom vacancy to anybody. It is
--      documentation that a later pass can gate on.
--
-- ═══ 🔴 VALUES OVERWRITTEN -- NO HISTORY TABLE FOR EITHER ═══
--   offices e4117d9e-d048-4ba2-b13e-c65607fec97f  Lewiston School Committee Member (Ward 5)
--     is_appointed_position  true  -> false
--   chambers 72841b2e-34a0-4a24-a27d-cded6a0442ab  Lewiston Public Schools School Committee
--     official_count         NULL  -> 9           (charter: "nine (9) members")
--
-- Nothing is seated, unseated, created or deleted. `office_terms` is not written at all: Hawkins'
-- `how_started = 'appointed'` and its source stay exactly as they are, because they are correct
-- and they are the record of how she arrived.
--
-- ⚠ AFTER THIS, MAINE CARRIES 3 APPOINTED-FLAGGED OFFICES AND ALL 3 ARE CORRECT: the Attorney
--   General, the Secretary of State and the Treasurer, whom Maine's LEGISLATURE chooses. The
--   sweep `CC_0427` opened is closed.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 0. Pin both seats, and pin the CONTROL this file reasons from. If Ward 7 did not show the
--    same appointment recorded the other way, the comparison that settles Ward 5 would not exist.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_current_holder och
      JOIN essentials.politicians p ON p.id = och.politician_id
      JOIN essentials.office_terms t ON t.office_id = och.office_id AND t.politician_id = p.id
     WHERE och.office_id = 'e4117d9e-d048-4ba2-b13e-c65607fec97f'
       AND p.full_name = 'Lynnea Hawkins' AND t.how_started = 'appointed'
  ) THEN
    RAISE EXCEPTION 'CC_0429: Ward 5 is not held by Lynnea Hawkins on an appointed term -- the premise of this file is wrong.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.offices o
      JOIN essentials.office_current_holder och ON och.office_id = o.id
      JOIN essentials.politicians p ON p.id = och.politician_id
      JOIN essentials.office_terms t ON t.office_id = o.id AND t.politician_id = p.id
     WHERE o.id = '5a64e180-1934-4a3e-b06c-402809209720'
       AND p.full_name = 'Emily Levasseur'
       AND t.how_started = 'appointed'
       AND o.is_appointed_position = false
  ) THEN
    RAISE EXCEPTION 'CC_0429: the Ward 7 control is gone -- an appointee on an ELECTIVE office is what makes Ward 5 the odd one out.';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 1. The seat is elective. How its holder arrived stays on her TERM, where it belongs.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices
   SET is_appointed_position = false
 WHERE id = 'e4117d9e-d048-4ba2-b13e-c65607fec97f';

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 2. Record the body's real size, so the ninth seat is countable rather than invisible.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.chambers
   SET official_count = 9
 WHERE id = '72841b2e-34a0-4a24-a27d-cded6a0442ab';

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-VERIFY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_offices    integer;
  v_flagged    integer;
  v_appointed  integer;
  v_count      integer;
  v_me_scope   integer;
  v_me_flag    integer;
  v_state_exec integer;
  v_unflagged  integer;
BEGIN
  -- Every seat we hold on this committee is elective, which is what the charter says they are.
  SELECT count(*), count(*) FILTER (WHERE o.is_appointed_position)
    INTO v_offices, v_flagged
    FROM essentials.offices o
   WHERE o.chamber_id = '72841b2e-34a0-4a24-a27d-cded6a0442ab';
  IF v_offices <> 8 THEN
    RAISE EXCEPTION 'CC_0429: the committee holds % offices, not the 8 this file accounts for.', v_offices;
  END IF;
  IF v_flagged <> 0 THEN
    RAISE EXCEPTION 'CC_0429: % Lewiston school seat(s) still publish as not elected.', v_flagged;
  END IF;

  -- 🔴 THE FACT MUST NOT HAVE MOVED. Both appointments stay recorded on their TERMS. Clearing an
  --    office flag must not quietly erase how either person arrived.
  SELECT count(*) INTO v_appointed
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE o.chamber_id = '72841b2e-34a0-4a24-a27d-cded6a0442ab'
     AND t.how_started = 'appointed'
     AND p.full_name IN ('Lynnea Hawkins', 'Emily Levasseur');
  IF v_appointed <> 2 THEN
    RAISE EXCEPTION 'CC_0429: % of the 2 appointments are still recorded on their office_terms rows.', v_appointed;
  END IF;

  -- Hawkins still holds Ward 5. A flag change moves nobody.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_current_holder och
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE och.office_id = 'e4117d9e-d048-4ba2-b13e-c65607fec97f' AND p.full_name = 'Lynnea Hawkins'
  ) THEN RAISE EXCEPTION 'CC_0429: Lynnea Hawkins no longer holds Ward 5.'; END IF;

  -- The charter's number, and the gap it makes countable.
  SELECT official_count INTO v_count
    FROM essentials.chambers WHERE id = '72841b2e-34a0-4a24-a27d-cded6a0442ab';
  IF v_count IS DISTINCT FROM 9 THEN
    RAISE EXCEPTION 'CC_0429: the committee states its size as %, not the charter''s 9.', v_count;
  END IF;
  IF v_count - v_offices <> 1 THEN
    RAISE EXCEPTION 'CC_0429: the committee is short by % seats, not the 1 council-appointed seat this file documents.', v_count - v_offices;
  END IF;

  -- 🟢 THE SWEEP CC_0427 OPENED IS CLOSED: Maine's only remaining appointed offices are the three
  --    its LEGISLATURE chooses.
  SELECT count(*), count(*) FILTER (WHERE o.is_appointed_position)
    INTO v_me_scope, v_me_flag
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me';
  IF v_me_scope < 400 THEN
    RAISE EXCEPTION 'CC_0429: the Maine sweep examined only % offices -- it is reading the wrong rows.', v_me_scope;
  END IF;
  IF v_me_flag <> 3 THEN
    RAISE EXCEPTION 'CC_0429: Maine carries % appointed-flagged offices, not the 3 legislature-chosen ones.', v_me_flag;
  END IF;

  SELECT count(*) INTO v_state_exec
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_EXEC'
     AND o.title IN ('Attorney General', 'Secretary of State', 'Treasurer')
     AND o.is_appointed_position = true;
  IF v_state_exec <> 3 THEN
    RAISE EXCEPTION 'CC_0429: the 3 remaining Maine flags are not the legislature-chosen state offices (% matched).', v_state_exec;
  END IF;

  -- A flag is not a seating.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN
    RAISE EXCEPTION 'CC_0429: drift baseline reads %, not 238.', v_unflagged;
  END IF;

  RAISE NOTICE 'CC_0429 OK: all 8 Lewiston school seats publish as elected, both appointments still recorded on their terms, committee states 9 against 8 rows (the council-appointed seat, documented), Maine down to 3 flags and all 3 correct, % offices examined, drift baseline 238.', v_me_scope;
END $$;

COMMIT;
