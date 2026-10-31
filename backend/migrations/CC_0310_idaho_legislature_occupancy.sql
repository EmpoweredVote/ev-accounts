-- CC_0310_idaho_legislature_occupancy.sql
-- Idaho Legislature — occupancy: seat the 105 sitting members created by CC_0309.
--
-- Roster, sources, identity rulings and source defects:
--   backend/data/seed-id-legislature-2026/ROSTERS.md
--
-- ═══ 🔴 EVERY ROW IN THIS MIGRATION EXPIRES ON 2026-12-01 ═══
--
-- Idaho Const. Art. III §3: senators and representatives are "elected for the term of two years,
-- FROM AND AFTER THE FIRST DAY OF DECEMBER next following the general election". All 105 seats
-- were on the 2026-11-03 ballot, so every term written here ends 2026-11-30 and the winners'
-- terms begin 2026-12-01 — 32 days after this migration was written.
--
-- ▶ THE RE-SEAT IS NOT A RE-RUN OF THIS FILE. Use essentials.seat_officeholder(office_id,
--   politician_id, DATE '2026-12-01', source), which closes the predecessor's term the day
--   before. 99 of the 105 incumbents sought re-election, so most rows survive unchanged.
--   Do NOT re-run CC_0309 either — the offices are already there.
--
-- ⚠ Seating today is still correct today. An office with no office_terms row is INVISIBLE:
--   no holder, so the member never appears in Essentials, stance research, coverage or campaign
--   finance, and NOTHING ERRORS. Leaving 105 offices unseated for 32 days is not the safe option.
--
-- ═══ 🔴 THE "MIKE LEE FAILURE" IS LIVE IN THIS ROSTER, EXACTLY ONCE ═══
--
-- Production already holds an ACTIVE, INCUMBENT Mark Harris (external_id -37008) who is the
-- U.S. REPRESENTATIVE FOR NORTH CAROLINA's 8th congressional district. Idaho's SENATE DISTRICT 35
-- member is also called Mark Harris and is a different person — home city Soda Springs, in the
-- Idaho Senate since 2022-12-01.
--
-- 🔴 A plain "insert where no (first_name, last_name) match exists" guard SILENTLY SKIPS the
--    Idaho row and then resolves politician_id to the North Carolina congressman, seating a
--    sitting member of the U.S. House in the Idaho Senate. No error, no warning — one wrong face
--    and one wrong voting record on a state legislator's page.
--
-- ▶ Handled in two passes below: 104 inserts run with the duplicate-name guard ARMED, and the
--   guard is lowered for the single Mark Harris row and raised again immediately. That row is
--   then resolved by source, which is unique to this migration — resolving it by name would put
--   back exactly the ambiguity the two passes just removed.
--
-- 🟢 The scan that found this ran all 105 (first_name, last_name) pairs against every active
--    politician in production and returned exactly one row. It is recorded in ROSTERS.md.
--
-- ═══ DATES ═══
--
-- office_terms.term_start is the start of CONTINUOUS OCCUPANCY, not of the current term;
-- re-election does not end an occupancy. Ballotpedia's "date assumed office" carries the earlier
-- arrival for appointees and is used for that reason.
--
--   101 day-precision, 4 year-precision, 0 unknown.
--    91 'elected'   — a 1 December arrival, which IS the constitutional term start.
--    14 'appointed' — Idaho fills a legislative vacancy by gubernatorial appointment from three
--                     names submitted by the district central committee (Idaho Code §59-904A),
--                     NEVER by special election, so a non-December-1 arrival can only be one.
--
-- 🔴 THE FOUR YEAR-ONLY ARRIVALS ARE NOT GUESSED INTO DAYS. Ballotpedia gives Crane 2006, Boyle
--    2008, Palmer 2008 and Anthon 2015 with no month. They are written at start_precision =>
--    'year' on YYYY-01-01. Their how_started comes from the CALENDAR rather than a guess: Idaho
--    elects legislators only in EVEN years, so 2006 and 2008 can be elections and 2015 CANNOT
--    BE — Anthon's row is therefore an appointment.
--
-- ═══ ⚠ WHAT THIS MIGRATION DELIBERATELY DOES NOT WRITE ═══
--
--  1. NO term_end. A future term_end makes a seat silently self-vacate — and with every Idaho
--     term ending 2026-11-30, writing one here would vacate the entire legislature on schedule
--     whether or not anybody had seated the successors.
--  2. NO party. These are partisan offices and the roster prints a party letter for all 105, but
--     party lives on races.primary_party. The gate asserts 0 legislators carry one.
--  3. NO portraits — that is CC_0314.

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_off int; v_terms int; v_harris int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives');
  IF v_off <> 105 THEN
    RAISE EXCEPTION 'CC_0310 pre-flight: expected 105 Idaho legislative offices from CC_0309, found % — apply CC_0309 first', v_off;
  END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives');
  IF v_terms <> 0 THEN
    RAISE EXCEPTION 'CC_0310 pre-flight: % Idaho legislative office(s) already carry a term — this '
                    'is meant to be a greenfield seating, so read those rows before going further', v_terms;
  END IF;

  -- 🔴 The lookalike must still be who the ruling says he is, so a later reader can see that
  --    lowering the guard for this one name was deliberate rather than an oversight.
  SELECT count(*) INTO v_harris FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE p.external_id = -37008 AND p.full_name = 'Mark Harris'
     AND g.name = 'United States Federal Government' AND upper(d.state) = 'NC';
  IF v_harris <> 1 THEN
    RAISE EXCEPTION 'CC_0310 pre-flight: the Mark Harris lookalike (-37008, U.S. House, North '
                    'Carolina) is not where the ruling left him (found %) — re-read the identity '
                    'scan in ROSTERS.md before inserting an Idaho person of the same name', v_harris;
  END IF;
END $$;

-- ── Roster ────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE id_leg(
  ch            text NOT NULL,
  district      int  NOT NULL,
  seat          text,
  full_name     text NOT NULL,
  first_name    text NOT NULL,
  last_name     text NOT NULL,
  suffix        text,
  term_start    date NOT NULL,
  precision     text NOT NULL,
  how_started   text NOT NULL,
  source        text NOT NULL,
  office_id     uuid,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO id_leg(ch, district, seat, full_name, first_name, last_name, suffix, term_start, precision, how_started, source) VALUES
  ('S', 1, NULL, 'James W. "Jim" Woodward', 'James', 'Woodward', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 1. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 2, NULL, 'Phil Hart', 'Phil', 'Hart', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 2. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 3, NULL, 'Doug Okuniewicz', 'Doug', 'Okuniewicz', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 3. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 4, NULL, 'Ben Toews', 'Ben', 'Toews', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 4. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 5, NULL, 'Carl J. Bjerke', 'Carl', 'Bjerke', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 5. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 6, NULL, 'Daniel D. Foreman', 'Daniel', 'Foreman', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 6. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 7, NULL, 'Cindy J. Carlson', 'Cindy', 'Carlson', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 7. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 8, NULL, 'Christy Zito', 'Christy', 'Zito', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 8. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 9, NULL, 'Brandon Shippy', 'Brandon', 'Shippy', NULL, DATE '2024-07-18', 'day', 'appointed', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 9. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('S', 10, NULL, 'Tammy Nichols', 'Tammy', 'Nichols', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 10. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 11, NULL, 'Camille Blaylock', 'Camille', 'Blaylock', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 11. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 12, NULL, 'Ben Adams', 'Ben', 'Adams', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 12. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 13, NULL, 'Brian Lenney', 'Brian', 'Lenney', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 13. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 14, NULL, 'C. Scott Grow', 'C.', 'Grow', NULL, DATE '2018-08-15', 'day', 'appointed', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 14. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('S', 15, NULL, 'Codi Galloway', 'Codi', 'Galloway', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 15. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 16, NULL, 'Alison "Ali" Rabe', 'Alison', 'Rabe', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 16. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 17, NULL, 'Carrie Semmelroth', 'Carrie', 'Semmelroth', NULL, DATE '2021-11-30', 'day', 'appointed', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 17. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('S', 18, NULL, 'Janie Ward-Engelking', 'Janie', 'Ward-Engelking', NULL, DATE '2014-01-08', 'day', 'appointed', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 18. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('S', 19, NULL, 'Melissa Wintrow', 'Melissa', 'Wintrow', NULL, DATE '2020-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 19. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 20, NULL, 'Josh Keyser', 'Josh', 'Keyser', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 20. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 21, NULL, 'Treg A. Bernt', 'Treg', 'Bernt', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 21. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 22, NULL, 'Lori Den Hartog', 'Lori', 'Den Hartog', NULL, DATE '2014-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 22. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 23, NULL, 'Todd M. Lakey', 'Todd', 'Lakey', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 23. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 24, NULL, 'Glenneda Zuiderveld', 'Glenneda', 'Zuiderveld', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 24. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 25, NULL, 'Joshua Kohl', 'Joshua', 'Kohl', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 25. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 26, NULL, 'Ron C. Taylor', 'Ron', 'Taylor', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 26. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 27, NULL, 'Kelly Arthur Anthon', 'Kelly', 'Anthon', NULL, DATE '2015-01-01', 'year', 'appointed', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 27. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. Ballotpedia gives the YEAR only, so start_precision is ''year'' at 2015-01-01 and the day is not invented. An ODD year — Idaho elects legislators only in even years, so this arrival can only be a gubernatorial appointment.'),
  ('S', 28, NULL, 'Jim Guthrie', 'Jim', 'Guthrie', NULL, DATE '2012-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 28. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 29, NULL, 'James D. Ruchti', 'James', 'Ruchti', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 29. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 30, NULL, 'Julie VanOrden', 'Julie', 'VanOrden', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 30. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 31, NULL, 'Van T. Burtenshaw', 'Van', 'Burtenshaw', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 31. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 32, NULL, 'Kevin Cook', 'Kevin', 'Cook', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 32. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 33, NULL, 'Dave Lent', 'Dave', 'Lent', NULL, DATE '2018-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 33. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 34, NULL, 'Doug Ricks', 'Doug', 'Ricks', NULL, DATE '2020-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 34. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('S', 35, NULL, 'Mark Harris', 'Mark', 'Harris', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov Senate membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 35. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 1, 'A', 'Mark Sauter', 'Mark', 'Sauter', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 1, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 1, 'B', 'Cornel S. Rasor', 'Cornel', 'Rasor', NULL, DATE '2024-09-30', 'day', 'appointed', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 1, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('H', 2, 'A', 'Heather Scott', 'Heather', 'Scott', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 2, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 2, 'B', 'Dale R. Hawkins', 'Dale', 'Hawkins', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 2, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 3, 'A', 'Vito Barbieri', 'Vito', 'Barbieri', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 3, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 3, 'B', 'Jordan Redman', 'Jordan', 'Redman', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 3, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 4, 'A', 'Joe Alfieri', 'Joe', 'Alfieri', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 4, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 4, 'B', 'Elaine Price', 'Elaine', 'Price', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 4, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 5, 'A', 'Ron Mendive', 'Ron', 'Mendive', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 5, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 5, 'B', 'Tony Wisniewski', 'Tony', 'Wisniewski', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 5, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 6, 'A', 'Lori Ann McCann', 'Lori', 'McCann', NULL, DATE '2021-05-17', 'day', 'appointed', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 6, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('H', 6, 'B', 'Brandon Mitchell', 'Brandon', 'Mitchell', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 6, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 7, 'A', 'Kyle Harris', 'Kyle', 'Harris', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 7, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 7, 'B', 'Charlie Shepherd', 'Charlie', 'Shepherd', NULL, DATE '2020-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 7, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 8, 'A', 'Robert "Rob" Beiswenger', 'Robert', 'Beiswenger', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 8, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 8, 'B', 'Faye Thompson', 'Faye', 'Thompson', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 8, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 9, 'A', 'John Shirts', 'John', 'Shirts', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 9, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 9, 'B', 'Judy Boyle', 'Judy', 'Boyle', NULL, DATE '2008-01-01', 'year', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 9, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. Ballotpedia gives the YEAR only, so start_precision is ''year'' at 2008-01-01 and the day is not invented. An even year, and Idaho legislative terms begin 1 December of even years, so this is an election.'),
  ('H', 10, 'A', 'Mike Moyle', 'Mike', 'Moyle', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 10, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 10, 'B', 'Bruce D. Skaug', 'Bruce', 'Skaug', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 10, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 11, 'A', 'Kent A. Marmon', 'Kent', 'Marmon', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 11, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 11, 'B', 'Lucas B. Cayler', 'Lucas', 'Cayler', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 11, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 12, 'A', 'Jeff J. Cornilles', 'Jeff', 'Cornilles', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 12, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 12, 'B', 'Jaron Crane', 'Jaron', 'Crane', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 12, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 13, 'A', 'Brent Crane', 'Brent', 'Crane', NULL, DATE '2006-01-01', 'year', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 13, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. Ballotpedia gives the YEAR only, so start_precision is ''year'' at 2006-01-01 and the day is not invented. An even year, and Idaho legislative terms begin 1 December of even years, so this is an election.'),
  ('H', 13, 'B', 'Steven Tanner', 'Steven', 'Tanner', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 13, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 14, 'A', 'Ted Hill', 'Ted', 'Hill', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 14, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 14, 'B', 'Josh Tanner', 'Josh', 'Tanner', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 14, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 15, 'A', 'Steve Berch', 'Steve', 'Berch', NULL, DATE '2018-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 15, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 15, 'B', 'Dori Healey', 'Dori', 'Healey', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 15, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 16, 'A', 'Soñia R. Galaviz', 'Soñia', 'Galaviz', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 16, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 16, 'B', 'Anne Henderson Haws', 'Anne', 'Haws', NULL, DATE '2025-07-22', 'day', 'appointed', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 16, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('H', 17, 'A', 'John Gannon', 'John', 'Gannon', NULL, DATE '2012-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 17, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 17, 'B', 'Megan Egbert', 'Megan', 'Egbert', NULL, DATE '2024-05-07', 'day', 'appointed', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 17, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('H', 18, 'A', 'Ilana Rubel', 'Ilana', 'Rubel', NULL, DATE '2014-01-08', 'day', 'appointed', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 18, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('H', 18, 'B', 'Brooke Green', 'Brooke', 'Green', NULL, DATE '2018-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 18, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 19, 'A', 'Monica C. Church', 'Monica', 'Church', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 19, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 19, 'B', 'Chris Mathias', 'Chris', 'Mathias', NULL, DATE '2020-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 19, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 20, 'A', 'Joe A. Palmer', 'Joe', 'Palmer', NULL, DATE '2008-01-01', 'year', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 20, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. Ballotpedia gives the YEAR only, so start_precision is ''year'' at 2008-01-01 and the day is not invented. An even year, and Idaho legislative terms begin 1 December of even years, so this is an election.'),
  ('H', 20, 'B', 'James Holtzclaw', 'James', 'Holtzclaw', NULL, DATE '2012-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 20, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 21, 'A', 'James Petzke', 'James', 'Petzke', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 21, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 21, 'B', 'Jeff Ehlers', 'Jeff', 'Ehlers', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 21, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 22, 'A', 'John Vander Woude', 'John', 'Vander Woude', NULL, DATE '2012-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 22, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 22, 'B', 'Jason A. Monks', 'Jason', 'Monks', NULL, DATE '2012-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 22, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 23, 'A', 'Chris Bruce', 'Chris', 'Bruce', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 23, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 23, 'B', 'Shawn Dygert', 'Shawn', 'Dygert', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 23, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 24, 'A', 'Clint Hostetler', 'Clint', 'Hostetler', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 24, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 24, 'B', 'Steve Miller', 'Steve', 'Miller', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 24, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 25, 'A', 'Don Hall', 'Don', 'Hall', NULL, DATE '2025-12-12', 'day', 'appointed', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 25, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('H', 25, 'B', 'David J. Leavitt', 'David', 'Leavitt', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 25, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 26, 'A', 'Mike J. Pohanka', 'Mike', 'Pohanka', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 26, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 26, 'B', 'Jack Nelsen', 'Jack', 'Nelsen', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 26, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 27, 'A', 'Douglas T. Pickett', 'Douglas', 'Pickett', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 27, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 27, 'B', 'Clay Handy', 'Clay', 'Handy', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 27, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 28, 'A', 'Richard W. "Rick" Cheatum', 'Richard', 'Cheatum', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 28, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 28, 'B', 'Dan Garner', 'Dan', 'Garner', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 28, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 29, 'A', 'Dustin Manwaring', 'Dustin', 'Manwaring', NULL, DATE '2020-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 29, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 29, 'B', 'Tanya Burgoyne', 'Tanya', 'Burgoyne', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 29, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 30, 'A', 'David M. Cannon', 'David', 'Cannon', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 30, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 30, 'B', 'Ben G. Fuhriman', 'Ben', 'Fuhriman', NULL, DATE '2024-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 30, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 31, 'A', 'Jerald Raymond', 'Jerald', 'Raymond', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 31, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 31, 'B', 'Rod Furniss', 'Rod', 'Furniss', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 31, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 32, 'A', 'Stephanie Jo Mickelsen', 'Stephanie', 'Mickelsen', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 32, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 32, 'B', 'Erin M. Bingham', 'Erin', 'Bingham', NULL, DATE '2026-01-10', 'day', 'appointed', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 32, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('H', 33, 'A', 'Barbara Ehardt', 'Barbara', 'Ehardt', NULL, DATE '2017-12-27', 'day', 'appointed', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 33, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('H', 33, 'B', 'Marco Adam Erickson', 'Marco', 'Erickson', NULL, DATE '2020-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 33, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 34, 'A', 'Jon O. Weber', 'Jon', 'Weber', NULL, DATE '2020-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 34, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 34, 'B', 'Britt Raybould', 'Britt', 'Raybould', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 34, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'),
  ('H', 35, 'A', 'Michael Leman Veile', 'Michael', 'Veile', NULL, DATE '2025-09-24', 'day', 'appointed', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 35, Seat A. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.'),
  ('H', 35, 'B', 'Josh Wheeler', 'Josh', 'Wheeler', NULL, DATE '2022-12-01', 'day', 'elected', 'legislature.idaho.gov House membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District 35, Seat B. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia''s date assumed office, which is continuous occupancy of this chamber rather than the current term. A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.');

-- Resolve each roster row to its office. Senate and House districts SHARE a geo_id in Idaho
-- (both are 16019 for district 19), so the join pairs geo_id with mtfcc AND district_type, and
-- the House additionally matches the seat letter carried in the office title.
UPDATE id_leg r SET office_id = o.id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE g.name = 'State of Idaho'
   AND lower(d.state) = 'id'
   AND d.geo_id = '16' || lpad(r.district::text, 3, '0')
   AND ((r.ch = 'S' AND c.name = 'Idaho Senate'
         AND d.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER'
         AND o.title = 'Senator')
     OR (r.ch = 'H' AND c.name = 'Idaho House of Representatives'
         AND d.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER'
         AND o.title = 'Representative, Seat ' || r.seat));

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM id_leg WHERE office_id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0310: % roster row(s) did not resolve to an Idaho legislative office', n; END IF;
  SELECT count(DISTINCT office_id) INTO n FROM id_leg;
  IF n <> 105 THEN RAISE EXCEPTION 'CC_0310: 105 roster rows collapsed to % distinct offices — two members resolved to one seat', n; END IF;
END $$;

-- ── People ────────────────────────────────────────────────────────────────────
-- 🔴 is_incumbent EXPLICITLY true. It defaults to false, and a seated person inserted without it
--    is HIDDEN from address search; check:occupancy fails an INSERT that omits it.
--    party stays NULL — see the header.
--
-- Pass 1 — the 104 with no name collision. THE DUPLICATE-NAME GUARD STAYS ARMED, because it is
-- the only thing standing between this seed and a second row for somebody already here.
INSERT INTO essentials.politicians (full_name, first_name, last_name, name_suffix, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, r.suffix, true, true, r.source
  FROM id_leg r
 WHERE r.full_name <> 'Mark Harris'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.politicians p
      WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
        AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
        AND p.is_active);

-- Pass 2 — the ONE row the guard is right to stop, lowered for exactly that row and raised again
-- immediately. Production's Mark Harris is the U.S. Representative for North Carolina's 8th
-- district; Idaho's Senate District 35 member is a different person. See the header.
SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (full_name, first_name, last_name, name_suffix, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, r.suffix, true, true, r.source
  FROM id_leg r WHERE r.full_name = 'Mark Harris';
SET LOCAL essentials.allow_duplicate_name = 'off';

-- 🔴 Resolved by SOURCE, not by name. source is unique to this migration and this row, so it
--    separates the Idaho Mark Harris from the North Carolina one.
UPDATE id_leg r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE p.is_active AND p.source = r.source
   AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name));

-- Anyone who already existed under a different source (none expected, but pass 1's guard would
-- have skipped them) resolves by name — never Mark Harris, who is already resolved above.
UPDATE id_leg r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE r.politician_id IS NULL AND p.is_active
   AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
   AND r.full_name <> 'Mark Harris';

-- ── Seating ───────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM id_leg ORDER BY ch, district, seat LOOP
    IF r.politician_id IS NULL THEN
      RAISE EXCEPTION 'CC_0310: % district % seat % did not resolve to a person', r.ch, r.district, coalesce(r.seat,'-');
    END IF;
    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, start_precision, how_started, source)
    VALUES (r.office_id, r.politician_id, r.term_start, r.precision, r.how_started, r.source);
    n := n + 1;
  END LOOP;
  IF n <> 105 THEN RAISE EXCEPTION 'CC_0310: expected 105 seatings, got %', n; END IF;
END $$;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_held int; v_sen int; v_hse int; v_people int; v_party int; v_notinc int;
  v_day int; v_year int; v_unknown int; v_elected int; v_appt int;
  v_termend int; v_harris_total int; v_harris_nc int; v_harris_id int; v_dupe int;
BEGIN
  -- 🔴 count(och.politician_id), never count(*): office_current_holder LEFT JOINs from offices,
  --    so a vacancy is a NULL politician_id rather than an absent row and count(*) passes vacuously.
  SELECT count(och.politician_id),
         count(och.politician_id) FILTER (WHERE c.name = 'Idaho Senate'),
         count(och.politician_id) FILTER (WHERE c.name = 'Idaho House of Representatives')
    INTO v_held, v_sen, v_hse
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives');
  IF v_held <> 105 OR v_sen <> 35 OR v_hse <> 70 THEN
    RAISE EXCEPTION 'CC_0310 gate: expected 105 held seats (35 Senate + 70 House), found % (% + %)', v_held, v_sen, v_hse;
  END IF;

  -- No person may hold two Idaho legislative seats.
  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives')
       AND och.politician_id IS NOT NULL
     GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'CC_0310 gate: % person(s) hold more than one Idaho legislative seat', v_dupe;
  END IF;

  SELECT count(*) INTO v_people FROM essentials.politicians WHERE source LIKE '%(CC_0310)%' AND is_active;
  IF v_people <> 105 THEN RAISE EXCEPTION 'CC_0310 gate: expected 105 people stamped CC_0310, found %', v_people; END IF;

  SELECT count(*) INTO v_notinc FROM essentials.politicians
   WHERE source LIKE '%(CC_0310)%' AND (NOT is_incumbent OR NOT is_active);
  IF v_notinc <> 0 THEN
    RAISE EXCEPTION 'CC_0310 gate: % seated Idaho legislator(s) are not active incumbents — they '
                    'would be HIDDEN from address search', v_notinc;
  END IF;

  SELECT count(*) INTO v_party FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives')
     AND coalesce(btrim(p.party),'') <> '';
  IF v_party <> 0 THEN
    RAISE EXCEPTION 'CC_0310 gate: % Idaho legislator(s) carry a party; it belongs on races.primary_party', v_party;
  END IF;

  SELECT count(*) FILTER (WHERE t.start_precision = 'day'),
         count(*) FILTER (WHERE t.start_precision = 'year'),
         count(*) FILTER (WHERE t.start_precision = 'unknown'),
         count(*) FILTER (WHERE t.how_started = 'elected'),
         count(*) FILTER (WHERE t.how_started = 'appointed'),
         count(*) FILTER (WHERE t.term_end IS NOT NULL)
    INTO v_day, v_year, v_unknown, v_elected, v_appt, v_termend
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives');
  IF v_day <> 101 OR v_year <> 4 OR v_unknown <> 0 THEN
    RAISE EXCEPTION 'CC_0310 gate: expected 101 day / 4 year / 0 unknown precisions, got % / % / %', v_day, v_year, v_unknown;
  END IF;
  IF v_elected <> 91 OR v_appt <> 14 THEN
    RAISE EXCEPTION 'CC_0310 gate: expected 91 elected / 14 appointed, got % / %', v_elected, v_appt;
  END IF;
  -- 🔴 Every Idaho term ends 2026-11-30. Writing that term_end HERE would vacate the whole
  --    legislature on schedule whether or not anyone had seated the successors.
  IF v_termend <> 0 THEN
    RAISE EXCEPTION 'CC_0310 gate: % Idaho legislative term(s) carry a term_end; a future term_end '
                    'makes a seat silently self-vacate', v_termend;
  END IF;

  -- 🔴 The lookalike stayed where he was, and an Idaho Mark Harris now exists beside him.
  SELECT count(*) INTO v_harris_total FROM essentials.politicians WHERE full_name = 'Mark Harris' AND is_active;
  SELECT count(*) INTO v_harris_nc FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE p.external_id = -37008 AND upper(d.state) = 'NC';
  SELECT count(*) INTO v_harris_id FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE p.full_name = 'Mark Harris' AND g.name = 'State of Idaho' AND c.name = 'Idaho Senate';
  IF v_harris_total < 2 OR v_harris_nc <> 1 OR v_harris_id <> 1 THEN
    RAISE EXCEPTION 'CC_0310 gate: expected TWO active Mark Harrises — the North Carolina '
                    'congressman (found % on an NC seat) and the Idaho senator (found % on an '
                    'Idaho Senate seat), % active in total. Fewer than two means the duplicate-name '
                    'guard silently skipped the Idaho row and the congressman was seated in Boise.',
                    v_harris_nc, v_harris_id, v_harris_total;
  END IF;

  RAISE NOTICE 'CC_0310 OK: 105 seated (35 Senate + 70 House), 105 people, 101 day / 4 year, 91 elected / 14 appointed, 0 party, 0 term_end, both Mark Harrises intact.';
END $$;
