-- CC_0348 — all 470 federal offices for 2026-11-03 take office 2027-01-03.
--
-- Piece 4, federal tier. The whole tier is one rule, one date, fifty states, and no per-state
-- research at all:
--
--   U.S. Const. amend. XX, § 1 — "The terms of the President and the Vice President shall end at
--   noon on the 20th day of January, and the terms of Senators and Representatives at noon on
--   the 3d day of January, of the years in which such terms would have ended if this article had
--   not been ratified; and the terms of their successors shall then begin."
--
-- Read from https://constitution.congress.gov/constitution/amendment-20/ on 2026-11-04.
--
-- 435 Representatives + 35 Senators. Measured first: every one of the 470 carries
-- `voting_powers = 'full'` and `representation_basis = 'residency'`, so none of the exceptions
-- ADR 0003 describes is in this set.
--
-- ▶ WHY THAT CHECK MATTERED. The six territory/DC non-voting House seats and DC's two shadow
-- senators sit in the same two district types (migration 1719). Their terms are NOT set by
-- amend. XX § 1, and a `district_type IN ('NATIONAL_LOWER','NATIONAL_UPPER')` predicate would
-- have swept any of them on this ballot into this date without a word. The post-verify gate
-- below re-asserts it rather than trusting the measurement to still hold at apply time.
--
-- ============================================================================================
-- 🔴🔴 THIS DATE DOES NOT BEND AROUND THE CALENDAR, AND EVERY OTHER DATE IN THIS PROGRAMME DOES
-- ============================================================================================
--
-- 3 January 2027 is a SUNDAY.
--
-- Every California rule piece 4 has written is a weekday rule that moves with the calendar —
-- "the second Friday in December" (Educ. Code § 5017), "noon on the first Friday in December"
-- (Elec. Code § 10554), "the first Monday after 1 January" (Gov. Code § 24200), "the second
-- Monday in December" (LA Charter § 205(c)), "the next regularly scheduled council meeting"
-- (Elec. Code § 10263(b)). After four migrations of those, the reflex on seeing a Sunday is to
-- move the date to the 4th.
--
-- It does not move. § 1 names a DAY OF THE MONTH, not a weekday, and a constitutional term
-- begins at noon on it whatever day of the week that is. `federal-swearing-in.mjs` has no
-- weekday arithmetic on purpose, and its test pins the Sunday so that nothing adds any.
--
-- ⚠ A DIFFERENT EVENT DOES MOVE, AND IT IS THE ONE PEOPLE WATCH. Amend. XX § 2 has Congress
-- assemble on 3 January "unless they shall by law appoint a different day", and Congress
-- routinely appoints another when the 3rd is a weekend. Members take the oath on the day their
-- chamber convenes — AFTER their terms have already begun. That is the same commencement-versus-
-- oath split as Cal. Educ. Code §§ 5017 and 35143, and `swearing_in_date` holds the
-- COMMENCEMENT, because the commencement is what decides who holds the seat.
--
-- `window_end_date` is therefore NULL: § 1 fixes an exact day. The oath may be later, but no
-- authority gives a window within which the TERM begins.
--
-- No value is overwritten and no row is deleted: not one federal office has a row in this table.
--
-- ⚠ THIS DATES THE SEATS; IT DOES NOT SEAT ANYONE. Nothing here writes `office_terms`. Wave 1
-- still needs its 35 Senate results and wave 2 its 435 House results before any winner can be
-- seated at this date.

CREATE TEMP TABLE fed_2026 ON COMMIT DROP AS
SELECT DISTINCT
       o.id AS office_id,
       d.district_type,
       o.voting_powers,
       d.representation_basis
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices   o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER');

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT office_id,
       DATE '2026-11-03',
       DATE '2027-01-03',
       'statute',
       'us-const-amend-xx-1',
       'U.S. Const. amend. XX, § 1 — the terms of Senators and Representatives end at noon on the 3d day of January, and the terms of their successors then begin',
       'https://constitution.congress.gov/constitution/amendment-20/ (read 2026-11-04)',
       '3 January 2027 is a Sunday and the date does NOT move: § 1 names a day of the month, not a weekday. What moves is a different event — amend. XX § 2 lets Congress appoint another day to assemble, and members take the oath when their chamber convenes, after their terms have already begun. This column holds the commencement.'
  FROM fed_2026
 -- 🔴 Only full-voting residency seats. A non-voting delegate or a DC shadow senator shares
 -- these district types and is NOT governed by amend. XX § 1.
 WHERE voting_powers = 'full'
   AND representation_basis = 'residency'
ON CONFLICT (office_id, election_date) DO NOTHING;

-- --------------------------------------------------------------------------------------------
-- Post-verify. Gates the delta this file creates, in its own transaction.
-- --------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_set      bigint;
  v_house    bigint;
  v_senate   bigint;
  v_written  bigint;
  v_excluded bigint;
  v_offdate  bigint;
BEGIN
  SELECT count(*) INTO v_set FROM fed_2026;
  IF v_set <> 470 THEN
    RAISE EXCEPTION 'CC_0348: expected 470 federal offices on this ballot, found % — re-measure before trusting the counts', v_set;
  END IF;

  -- 🔴 THE EXCEPTION CHECK, RE-ASSERTED AT APPLY TIME. If a non-voting delegate or a shadow
  -- senator appears in this set, it is deliberately NOT dated here, and the counts below must
  -- not silently absorb it.
  SELECT count(*) INTO v_excluded
    FROM fed_2026
   WHERE voting_powers <> 'full' OR representation_basis <> 'residency';
  IF v_excluded <> 0 THEN
    RAISE EXCEPTION 'CC_0348: % federal office(s) are non-voting or non-residency and are not governed by amend. XX § 1 — date them separately', v_excluded;
  END IF;

  SELECT count(*) INTO v_house
    FROM essentials.office_swearing_in s
    JOIN fed_2026 f ON f.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND f.district_type = 'NATIONAL_LOWER';
  IF v_house <> 435 THEN RAISE EXCEPTION 'CC_0348: expected 435 House rows, found %', v_house; END IF;

  SELECT count(*) INTO v_senate
    FROM essentials.office_swearing_in s
    JOIN fed_2026 f ON f.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND f.district_type = 'NATIONAL_UPPER';
  IF v_senate <> 35 THEN RAISE EXCEPTION 'CC_0348: expected 35 Senate rows, found %', v_senate; END IF;

  -- 🔴 NOT ONE FEDERAL ROW MAY SIT ANYWHERE BUT 2027-01-03. This is the gate that catches a
  -- weekday "correction" to the 4th — the single most likely wrong edit to this file, because
  -- every other rule piece 4 has written is a weekday rule and 3 January 2027 is a Sunday.
  SELECT count(*) INTO v_offdate
    FROM essentials.office_swearing_in s
    JOIN fed_2026 f ON f.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date <> DATE '2027-01-03';
  IF v_offdate <> 0 THEN
    RAISE EXCEPTION 'CC_0348: % federal row(s) are not on 2027-01-03 — amend. XX § 1 names a day of the month, not a weekday', v_offdate;
  END IF;

  -- A federal term's start is exact. A window here would assert an authority that does not exist.
  SELECT count(*) INTO v_offdate
    FROM essentials.office_swearing_in s
    JOIN fed_2026 f ON f.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND (s.window_end_date IS NOT NULL OR s.basis <> 'statute');
  IF v_offdate <> 0 THEN
    RAISE EXCEPTION 'CC_0348: % federal row(s) carry a window or a non-statute basis', v_offdate;
  END IF;

  SELECT count(*) INTO v_written
    FROM essentials.office_swearing_in WHERE election_date = DATE '2026-11-03';
  IF v_written <> 806 THEN
    RAISE EXCEPTION 'CC_0348: expected 806 rows for this election (336 California + 470 federal), found %', v_written;
  END IF;

  RAISE NOTICE 'CC_0348 OK: 470 federal offices dated 2027-01-03 (% House, % Senate); 806 rows for this election',
    v_house, v_senate;
END $$;
