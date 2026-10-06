-- CC_0191_duvall_redmond_occupancy.sql
-- Duvall + Redmond WA deep seed, wave 2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0190, which creates the 16 offices this seats.
--
-- Creates 16 people and 16 office_terms rows. Creates no office and no district.
--
-- Roster and every citation: backend/data/seed-duvall-redmond-2026/ROSTERS.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 FOUR OF THE SIXTEEN ARE APPOINTEES, AND THE CERTIFIED WINNER IS NOT THE SITTING MEMBER.
-- A join from certified results on name would seat the wrong person in all four:
--
--   Redmond Pos 1  certified Osman Salahuddin (2023)  -> SITTING Sayna Parsi,       sworn 2026-01-20
--   Duvall  Pos 2  certified Rick Shaffer     (2023)  -> SITTING Linda Conway,      sworn 2026-09-01
--   Duvall  Pos 3  certified Loren Kosloske   (2025)  -> SITTING Sara Taylor,       sworn 2026-08-18
--   Duvall  Pos 7  certified Carol Kufeldt    (2023)  -> SITTING Jennifer Hernandez, sworn 2026-01-20
--
-- Each date is the oath recorded in that meeting's own minutes, not the date the seat fell vacant
-- and not the predecessor's election. All four carry how_started = 'appointed'.
--
-- 🔴🔴 TWO SITTING MEMBERS LOST A DIFFERENT SEAT IN THE SAME ELECTION.
--   Sara Taylor        lost Duvall Position 1 to Adam Olen    (34.91%) and sits in Position 3.
--   Jennifer Hernandez lost Duvall Position 6 to Paul Wiggins (34.53%) and sits in Position 7.
-- A name match against the Nov 2025 certified results seats each of them in the seat they LOST.
-- The gate at the bottom asserts the correct pairing explicitly, because nothing else would.
--
-- 🔴 DUVALL POSITION 5 IS ONE CONTINUOUS TERM, NOT TWO. Position 5's regular cycle is 2021/2025
-- (Michelle Hogg won it in 2021), so Mike Supple's 2023 win was an UNEXPIRED short term and his
-- 2025 win the following full term. One row from 2024-01-01.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 TERM STARTS ARE JANUARY 1, by RCW 29A.60.280(2): for city offices "the term of incumbents
-- ends and the term of successors begins ... immediately after December 31st following the
-- election". Each start below is the January 1 after the election that seated that person in THAT
-- position, walked back through six certified cycles until the person is absent from the seat.
-- Nothing here is a guess; every start is day-precision.
--
-- 🔴 NO PREDECESSOR ROWS AND NO VACANCY SPANS ARE WRITTEN. This seed records only the sitting
-- holder, so each office gets exactly one open-ended term. office_holders_as_of() will return
-- nobody for the four appointed seats during their real gap, which is accurate. Writing a vacancy
-- span would need a start date the sources do not give — Redmond says only "in November".
--
-- 🔴 is_incumbent IS SET EXPLICITLY ON ALL 16. It defaults to false, and a seated person inserted
-- without it is HIDDEN from address search. check:occupancy fails an INSERT that omits it.
--
-- ⚠ DUPLICATE-NAME GUARD, run 2026-10-06 against production, with a positive control that found
-- Balducci / Dunn / Zahilay: none of the 16 (first_name, last_name) pairs exists. A looser
-- last-name-only sweep found same-surname strangers — Dan/David/Steve Conway, Maurice Mercer,
-- Ace Parsi, Brice Wiggins, David/Richard/Russell Stuart, many Hernandezes and many Taylors —
-- and none is our person. Note the near-miss: a `Sara Hernandez` already exists, while this wave
-- seats a Sara TAYLOR and a Jennifer HERNANDEZ. All 16 are new rows.
--
-- ⚠ Party is deliberately absent. Both cities are non-partisan and the certified results carry NP.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 0. Refuse to run before CC_0190 ──────────────────────────────────────────

DO $$
DECLARE v_off int;
BEGIN
  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND g.mtfcc = 'G4110';
  IF v_off <> 16 THEN
    RAISE EXCEPTION 'WA-2 pre-flight: expected the 16 offices from CC_0190, found % — apply CC_0190 first', v_off;
  END IF;
END $$;

-- ─── 1. The sixteen people ────────────────────────────────────────────────────

INSERT INTO essentials.politicians (full_name, first_name, last_name, is_incumbent, is_active, data_source)
SELECT v.full_name, v.first_name, v.last_name, true, true, 'CC_0191 duvall redmond deep seed'
FROM (VALUES
  ('Amy McHenry',        'Amy',      'McHenry'),
  ('Adam Olen',          'Adam',     'Olen'),
  ('Linda Conway',       'Linda',    'Conway'),
  ('Sara Taylor',        'Sara',     'Taylor'),
  ('Ronn Mercer',        'Ronn',     'Mercer'),
  ('Mike Supple',        'Mike',     'Supple'),
  ('Paul Wiggins',       'Paul',     'Wiggins'),
  ('Jennifer Hernandez', 'Jennifer', 'Hernandez'),
  ('Angela Birney',      'Angela',   'Birney'),
  ('Sayna Parsi',        'Sayna',    'Parsi'),
  ('Vivek Prakriya',     'Vivek',    'Prakriya'),
  ('Jessica Forsythe',   'Jessica',  'Forsythe'),
  ('Melissa Stuart',     'Melissa',  'Stuart'),
  ('Vanessa Kritzer',    'Vanessa',  'Kritzer'),
  ('Menka Soni',         'Menka',    'Soni'),
  ('Angie Nuevacamina',  'Angie',    'Nuevacamina')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p
   WHERE p.first_name = v.first_name AND p.last_name = v.last_name
     AND p.data_source = 'CC_0191 duvall redmond deep seed');

-- ─── 2. Seat all sixteen through the helper ───────────────────────────────────
-- Never hand-roll the two-step. seat_officeholder closes any predecessor term the day before and
-- is idempotent; there are no predecessors here, so each call inserts one open-ended term.

DO $$
DECLARE
  r record; v_office uuid; v_pol uuid;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      -- geo_id,  office title,                  first,      last,          term_start,   how_started
      ('5319035', 'Mayor',                       'Amy',      'McHenry',     DATE '2026-01-01', 'elected'),
      ('5319035', 'Councilmember, Position 1',   'Adam',     'Olen',        DATE '2026-01-01', 'elected'),
      ('5319035', 'Councilmember, Position 2',   'Linda',    'Conway',      DATE '2026-09-01', 'appointed'),
      ('5319035', 'Councilmember, Position 3',   'Sara',     'Taylor',      DATE '2026-08-18', 'appointed'),
      ('5319035', 'Councilmember, Position 4',   'Ronn',     'Mercer',      DATE '2024-01-01', 'elected'),
      ('5319035', 'Councilmember, Position 5',   'Mike',     'Supple',      DATE '2024-01-01', 'elected'),
      ('5319035', 'Councilmember, Position 6',   'Paul',     'Wiggins',     DATE '2026-01-01', 'elected'),
      ('5319035', 'Councilmember, Position 7',   'Jennifer', 'Hernandez',   DATE '2026-01-20', 'appointed'),
      ('5357535', 'Mayor',                       'Angela',   'Birney',      DATE '2020-01-01', 'elected'),
      ('5357535', 'Councilmember, Position 1',   'Sayna',    'Parsi',       DATE '2026-01-20', 'appointed'),
      ('5357535', 'Councilmember, Position 2',   'Vivek',    'Prakriya',    DATE '2026-01-01', 'elected'),
      ('5357535', 'Councilmember, Position 3',   'Jessica',  'Forsythe',    DATE '2020-01-01', 'elected'),
      ('5357535', 'Councilmember, Position 4',   'Melissa',  'Stuart',      DATE '2022-01-01', 'elected'),
      ('5357535', 'Councilmember, Position 5',   'Vanessa',  'Kritzer',     DATE '2020-01-01', 'elected'),
      ('5357535', 'Councilmember, Position 6',   'Menka',    'Soni',        DATE '2026-01-01', 'elected'),
      ('5357535', 'Councilmember, Position 7',   'Angie',    'Nuevacamina', DATE '2024-01-01', 'elected')
    ) AS t(geo_id, title, first_name, last_name, term_start, how_started)
  LOOP
    SELECT o.id INTO v_office
      FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.geo_id = r.geo_id AND g.mtfcc = 'G4110' AND o.title = r.title;
    IF v_office IS NULL THEN
      RAISE EXCEPTION 'WA-2: no office % in government %', r.title, r.geo_id;
    END IF;

    SELECT p.id INTO v_pol
      FROM essentials.politicians p
     WHERE p.first_name = r.first_name AND p.last_name = r.last_name
       AND p.data_source = 'CC_0191 duvall redmond deep seed';
    IF v_pol IS NULL THEN
      RAISE EXCEPTION 'WA-2: no politician % %', r.first_name, r.last_name;
    END IF;

    PERFORM essentials.seat_officeholder(
      v_office, v_pol, r.term_start,
      'King County Elections certified results 2015-2025; city rosters and council minutes; see backend/data/seed-duvall-redmond-2026/ROSTERS.md (CC_0191)',
      r.how_started, 'day');
  END LOOP;
END $$;

-- ─── 3. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_seated int; v_unflagged int; v_vac int; v_notinc int; v_prec int; v_appt int; v_pairs int;
BEGIN
  -- 🔴 count och.politician_id, NOT count(*). office_current_holder LEFT JOINs from offices, so
  -- count(*) would pass vacuously on 16 empty seats.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.geo_id IN ('5319035','5357535') AND g.mtfcc = 'G4110';
  IF v_seated <> 16 THEN RAISE EXCEPTION 'WA-2 gate: expected 16 seated, got %', v_seated; END IF;

  -- 🔴 THE PAIRING ASSERTION. Nothing else catches Taylor being seated in the Position 1 she lost
  -- or Hernandez in the Position 6 she lost. Named seats, named people, all 16.
  SELECT count(*) INTO v_pairs FROM (
    SELECT g.geo_id, o.title, p.first_name, p.last_name
      FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
      JOIN essentials.office_current_holder och ON och.office_id = o.id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE g.geo_id IN ('5319035','5357535')
    INTERSECT
    SELECT * FROM (VALUES
      ('5319035','Mayor','Amy','McHenry'),
      ('5319035','Councilmember, Position 1','Adam','Olen'),
      ('5319035','Councilmember, Position 2','Linda','Conway'),
      ('5319035','Councilmember, Position 3','Sara','Taylor'),
      ('5319035','Councilmember, Position 4','Ronn','Mercer'),
      ('5319035','Councilmember, Position 5','Mike','Supple'),
      ('5319035','Councilmember, Position 6','Paul','Wiggins'),
      ('5319035','Councilmember, Position 7','Jennifer','Hernandez'),
      ('5357535','Mayor','Angela','Birney'),
      ('5357535','Councilmember, Position 1','Sayna','Parsi'),
      ('5357535','Councilmember, Position 2','Vivek','Prakriya'),
      ('5357535','Councilmember, Position 3','Jessica','Forsythe'),
      ('5357535','Councilmember, Position 4','Melissa','Stuart'),
      ('5357535','Councilmember, Position 5','Vanessa','Kritzer'),
      ('5357535','Councilmember, Position 6','Menka','Soni'),
      ('5357535','Councilmember, Position 7','Angie','Nuevacamina')
    ) AS expected(geo_id, title, first_name, last_name)
  ) x;
  IF v_pairs <> 16 THEN
    RAISE EXCEPTION 'WA-2 gate: only % of 16 (seat, person) pairs match the evidenced roster', v_pairs;
  END IF;

  -- 🔴 The four appointees must carry how_started = appointed AND a start LATER than the January
  -- after their predecessor's election. 2024-01-01 / 2026-01-01 would be the predecessor's start.
  SELECT count(*) INTO v_appt
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.term_end IS NULL AND t.how_started = 'appointed'
     AND (g.geo_id, o.title, t.term_start) IN (
       ('5357535','Councilmember, Position 1', DATE '2026-01-20'),
       ('5319035','Councilmember, Position 2', DATE '2026-09-01'),
       ('5319035','Councilmember, Position 3', DATE '2026-08-18'),
       ('5319035','Councilmember, Position 7', DATE '2026-01-20'));
  IF v_appt <> 4 THEN
    RAISE EXCEPTION 'WA-2 gate: expected 4 appointed terms on their recorded oath dates, got %', v_appt;
  END IF;

  -- Every start is day-precision; none was guessed.
  SELECT count(*) INTO v_prec
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND t.term_end IS NULL
     AND (t.start_precision <> 'day' OR t.term_start IS NULL);
  IF v_prec <> 0 THEN RAISE EXCEPTION 'WA-2 gate: % term(s) are not day-precision', v_prec; END IF;

  -- 🔴 is_incumbent on every one of the 16, or they are hidden from address search.
  SELECT count(*) INTO v_notinc
    FROM essentials.politicians p
   WHERE p.data_source = 'CC_0191 duvall redmond deep seed'
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_notinc <> 0 THEN RAISE EXCEPTION 'WA-2 gate: % of the 16 are not is_incumbent/is_active', v_notinc; END IF;

  SELECT count(*) INTO v_vac
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND o.is_vacant IS true;
  IF v_vac <> 0 THEN RAISE EXCEPTION 'WA-2 gate: % office(s) flagged vacant', v_vac; END IF;

  -- 🔴 Back to the CLAUDE.md baseline. CC_0190 pushed it 239 -> 255 by creating 16 termless
  -- offices; seating all 16 must put it back. A different number is drift, in either direction.
  SELECT count(*) FILTER (WHERE NOT is_vacant) INTO v_unflagged FROM essentials.offices_missing_terms;
  IF v_unflagged <> 239 THEN
    RAISE EXCEPTION 'WA-2 gate: offices_missing_terms unflagged is %, expected the 239 baseline', v_unflagged;
  END IF;

  RAISE NOTICE 'WA-2 occupancy gate PASSED';
END $$;

COMMIT;
