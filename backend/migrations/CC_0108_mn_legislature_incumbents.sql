-- CC_0108_mn_legislature_incumbents.sql
-- Knight Foundation program, wave MN-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0107, which creates the chambers and the 201 offices.
--
-- Seats 200 of Minnesota's 201 legislative offices:
--    198 people created here, external_id band -2732201 .. -2732001
--    2 people REUSED from rows production already holds
--    1 office left unseated -- HD-21A, flagged vacant by CC_0107
--
-- 🔴 THERE IS NO term_start TO BE HAD, AND NONE IS INVENTED. The richest per-member pages either
-- chamber publishes give "Elected: 2010 / Term: 8th" (House) and "re-elected 2020, 2022 / Term:
-- 4th" (Senate) -- an election YEAR and an ordinal, never a date. The Legislative Reference
-- Library's legislator database gives biennia ("House 1971-72"), also not a date. At least six
-- sitting members took their seats at a 2025 SPECIAL election rather than at the start of the
-- biennium, so the constitutional first-Monday-in-January date would be positively wrong for
-- them and is not a fact about anyone else either. Every term is therefore written OPEN-ENDED
-- with start_precision 'unknown' -- the GA-2 and IN-2 pattern.
-- essentials.seat_officeholder() is NOT used: it refuses a NULL term_start by design.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 PARTY IS NOT WRITTEN. All three sources carry it; party lives on races.primary_party.
--
-- 🔴🔴 FIVE ROSTER NAMES COLLIDE WITH AN ACTIVE POLITICIAN ROW, AND THEY SPLIT TWO WAYS. Each was
-- READ before it was classified -- 2 of 4 name hits in the Georgia wave were a Colorado senator
-- and a Utah treasurer, so a shared surname is never the answer on its own.
--
--   SAME PERSON, ROW REUSED (no insert):
--     54   Eric Pratt -- The existing row is a candidate in the same MN-02 race (external_id -270201). Eric Pratt is the sitting Minnesota senator for district 54 and the Republican nominee for MN-02. One person.
--     55B  Kaela Berg -- The existing row is a candidate in the MN 2nd congressional district race (external_id -270203). Kaela Berg represents Burnsville in the Minnesota House (55B) and ran in the MN-02 DFL primary on 2026-08-11. A sitting legislator running for a different seat is one person with two roles.
--
--   DIFFERENT PEOPLE, INSERTED WITH THE GUARD DELIBERATELY LIFTED:
--     64   -- The existing Erin J. Murphy (external_id -2507000004) holds City Councillor At-Large in Boston, MASSACHUSETTS. The roster Erin P. Murphy is the senator for Minnesota Senate 64. Different middle initial, different state, different office.
--     20B  -- The existing Steven Jacob (external_id -200105) is the LIBERTARIAN candidate for KANSAS 1st congressional district, from Lawrence, Kansas. The roster Steven Jacob is the Republican representative for Minnesota House 20B. Different state, different party, different person.
--     9B   -- The existing Tom Murphy (external_id -4014001) holds Mayor of the Town of Sahuarita, ARIZONA. The roster Tom Murphy is the representative for Minnesota House 9B.
--
-- ⚠ THE GUARD IS LIFTED FOR THREE ROWS, NOT FOR THE MIGRATION. essentials.politicians carries a
-- BEFORE INSERT trigger that refuses a name an active row already holds. The 195 rows with no
-- namesake are inserted with it ARMED, so a namesake nobody anticipated still stops this
-- migration. Only then is essentials.allow_duplicate_name set to 'on', for the three rows named
-- above, and set back to 'off' immediately afterwards.
--
-- 🟢 first_name AND full_name COME FROM THE SAME SOURCE, WHICH IS LOAD-BEARING HERE. An earlier
-- draft of the roster builder took full_name from the chamber and first_name from Open States,
-- writing "Steven Jacob" with first_name "Steve". The guard keys on (first_name, last_name), so
-- that mismatch hid the Kansas Steven Jacob from the reuse search entirely.
--
-- 🟢 NAMES ARE HTML-DECODED. house.mn.gov encodes eight member names; `Mar&#237;a Isa
-- P&#233;rez-Vega` reaches a voter-facing field as mojibake if it is captured raw.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── 195 people with no active namesake -- guard ARMED ──────────────────────────────

CREATE TEMP TABLE mn_new_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO mn_new_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2732001, 'John Burkel', 'John', 'Burkel', '{}'::text[]),
  (-2732002, 'Steve Gander', 'Steve', 'Gander', '{}'::text[]),
  (-2732003, 'Bidal Duran', 'Bidal', 'Duran', '{}'::text[]),
  (-2732004, 'Matt Bliss', 'Matt', 'Bliss', '{}'::text[]),
  (-2732005, 'Roger Skraba', 'Roger', 'Skraba', '{}'::text[]),
  (-2732006, 'Natalie Zeleznikar', 'Natalie', 'Zeleznikar', '{}'::text[]),
  (-2732007, 'Heather Keeler', 'Heather', 'Keeler', '{}'::text[]),
  (-2732008, 'Jim Joy', 'Jim', 'Joy', '{}'::text[]),
  (-2732009, 'Krista Knudsen', 'Krista', 'Knudsen', '{}'::text[]),
  (-2732010, 'Mike Wiener', 'Mike', 'Wiener', '{}'::text[]),
  (-2732011, 'Ben Davis', 'Ben', 'Davis', '{}'::text[]),
  (-2732012, 'Josh Heintzeman', 'Josh', 'Heintzeman', '{}'::text[]),
  (-2732013, 'Spencer Igo', 'Spencer', 'Igo', '{}'::text[]),
  (-2732014, 'Cal Warwas', 'Cal', 'Warwas', '{}'::text[]),
  (-2732015, 'Pete Johnson', 'Pete', 'Johnson', '{}'::text[]),
  (-2732016, 'Liish Kozlowski', 'Liish', 'Kozlowski', '{}'::text[]),
  (-2732017, 'Jeff Backer', 'Jeff', 'Backer', '{}'::text[]),
  (-2732019, 'Ron Kresha', 'Ron', 'Kresha', '{}'::text[]),
  (-2732020, 'Isaac Schultz', 'Isaac', 'Schultz', '{}'::text[]),
  (-2732021, 'Jeff Dotseth', 'Jeff', 'Dotseth', '{}'::text[]),
  (-2732022, 'Nathan Nelson', 'Nathan', 'Nelson', '{}'::text[]),
  (-2732023, 'Paul Anderson', 'Paul', 'Anderson', '{}'::text[]),
  (-2732024, 'Mary Franson', 'Mary', 'Franson', '{}'::text[]),
  (-2732025, 'Lisa Demuth', 'Lisa', 'Demuth', '{}'::text[]),
  (-2732026, 'Tim O''Driscoll', 'Tim', 'O''Driscoll', '{}'::text[]),
  (-2732027, 'Bernie Perryman', 'Bernie', 'Perryman', '{}'::text[]),
  (-2732028, 'Dan Wolgamott', 'Dan', 'Wolgamott', '{}'::text[]),
  (-2732029, 'Chris Swedzinski', 'Chris', 'Swedzinski', '{}'::text[]),
  (-2732030, 'Paul Torkelson', 'Paul', 'Torkelson', '{}'::text[]),
  (-2732031, 'Scott Van Binsbergen', 'Scott', 'Van Binsbergen', '{}'::text[]),
  (-2732032, 'Dave Baker', 'Dave', 'Baker', '{}'::text[]),
  (-2732033, 'Dawn Gillman', 'Dawn', 'Gillman', '{}'::text[]),
  (-2732034, 'Bobbie Harder', 'Bobbie', 'Harder', '{}'::text[]),
  (-2732035, 'Erica Schwartz', 'Erica', 'Schwartz', '{}'::text[]),
  (-2732036, 'Luke Frederick', 'Luke', 'Frederick', '{}'::text[]),
  (-2732037, 'Keith Allen', 'Keith', 'Allen', '{}'::text[]),
  (-2732038, 'Tom Sexton', 'Tom', 'Sexton', '{}'::text[]),
  (-2732039, 'Pam Altendorf', 'Pam', 'Altendorf', '{}'::text[]),
  (-2732041, 'Marj Fogelman', 'Marj', 'Fogelman', '{}'::text[]),
  (-2732042, 'Bjorn Olson', 'Bjorn', 'Olson', '{}'::text[]),
  (-2732043, 'Terry Stier', 'Terry', 'Stier', '{}'::text[]),
  (-2732044, 'Peggy Bennett', 'Peggy', 'Bennett', '{}'::text[]),
  (-2732045, 'Patricia Mueller', 'Patricia', 'Mueller', ARRAY['Patty Mueller']::text[]),
  (-2732046, 'Duane Quam', 'Duane', 'Quam', '{}'::text[]),
  (-2732047, 'Tina Liebling', 'Tina', 'Liebling', '{}'::text[]),
  (-2732048, 'Kim Hicks', 'Kim', 'Hicks', '{}'::text[]),
  (-2732049, 'Andy Smith', 'Andy', 'Smith', '{}'::text[]),
  (-2732050, 'Aaron Repinski', 'Aaron', 'Repinski', ARRAY['Ripper Repinski']::text[]),
  (-2732051, 'Greg Davids', 'Greg', 'Davids', '{}'::text[]),
  (-2732052, 'Shane Mekeland', 'Shane', 'Mekeland', '{}'::text[]),
  (-2732053, 'Bryan Lawrence', 'Bryan', 'Lawrence', '{}'::text[]),
  (-2732054, 'Jimmy Gordon', 'Jimmy', 'Gordon', '{}'::text[]),
  (-2732055, 'Max Rymer', 'Max', 'Rymer', '{}'::text[]),
  (-2732056, 'Joe McDonald', 'Joe', 'McDonald', '{}'::text[]),
  (-2732057, 'Marion Rarick', 'Marion', 'Rarick', '{}'::text[]),
  (-2732058, 'Walter Hudson', 'Walter', 'Hudson', '{}'::text[]),
  (-2732059, 'Paul Novotny', 'Paul', 'Novotny', '{}'::text[]),
  (-2732060, 'Harry Niska', 'Harry', 'Niska', '{}'::text[]),
  (-2732061, 'Peggy Scott', 'Peggy', 'Scott', '{}'::text[]),
  (-2732062, 'Nolan West', 'Nolan', 'West', '{}'::text[]),
  (-2732063, 'Matt Norris', 'Matt', 'Norris', '{}'::text[]),
  (-2732064, 'Patti Anderson', 'Patti', 'Anderson', '{}'::text[]),
  (-2732065, 'Josiah Hill', 'Josiah', 'Hill', '{}'::text[]),
  (-2732066, 'Danny Nadeau', 'Danny', 'Nadeau', '{}'::text[]),
  (-2732067, 'Xp Lee', 'Xp', 'Lee', '{}'::text[]),
  (-2732068, 'Zack Stephenson', 'Zack', 'Stephenson', '{}'::text[]),
  (-2732069, 'Kari Rehrauer', 'Kari', 'Rehrauer', '{}'::text[]),
  (-2732070, 'Elliott Engen', 'Elliott', 'Engen', '{}'::text[]),
  (-2732071, 'Brion Curran', 'Brion', 'Curran', '{}'::text[]),
  (-2732072, 'Kristin Robbins', 'Kristin', 'Robbins', '{}'::text[]),
  (-2732073, 'Kristin Bahner', 'Kristin', 'Bahner', '{}'::text[]),
  (-2732074, 'Huldah Momanyi-Hiltsley', 'Huldah', 'Momanyi-Hiltsley', ARRAY['Huldah Hiltsley']::text[]),
  (-2732075, 'Samantha Vang', 'Samantha', 'Vang', '{}'::text[]),
  (-2732076, 'Erin Koegel', 'Erin', 'Koegel', '{}'::text[]),
  (-2732077, 'Sandra Feist', 'Sandra', 'Feist', '{}'::text[]),
  (-2732078, 'Kelly Moller', 'Kelly', 'Moller', '{}'::text[]),
  (-2732079, 'David Gottfried', 'David', 'Gottfried', '{}'::text[]),
  (-2732080, 'Wayne Johnson', 'Wayne', 'Johnson', '{}'::text[]),
  (-2732081, 'Tom Dippel', 'Tom', 'Dippel', '{}'::text[]),
  (-2732082, 'Ned Carroll', 'Ned', 'Carroll', '{}'::text[]),
  (-2732083, 'Ginny Klevorn', 'Ginny', 'Klevorn', '{}'::text[]),
  (-2732084, 'Cedrick Frazier', 'Cedrick', 'Frazier', '{}'::text[]),
  (-2732085, 'Mike Freiberg', 'Mike', 'Freiberg', '{}'::text[]),
  (-2732086, 'Peter Fischer', 'Peter', 'Fischer', '{}'::text[]),
  (-2732087, 'Leon Lillie', 'Leon', 'Lillie', '{}'::text[]),
  (-2732088, 'Andrew Myers', 'Andrew', 'Myers', '{}'::text[]),
  (-2732089, 'Patty Acomb', 'Patty', 'Acomb', '{}'::text[]),
  (-2732090, 'Larry Kraft', 'Larry', 'Kraft', '{}'::text[]),
  (-2732091, 'Cheryl Youakim', 'Cheryl', 'Youakim', '{}'::text[]),
  (-2732092, 'Shelley Buck', 'Shelley', 'Buck', '{}'::text[]),
  (-2732093, 'Ethan Cha', 'Ethan', 'Cha', '{}'::text[]),
  (-2732094, 'Jim Nash', 'Jim', 'Nash', '{}'::text[]),
  (-2732095, 'Lucy Rehm', 'Lucy', 'Rehm', '{}'::text[]),
  (-2732096, 'Alex Falconer', 'Alex', 'Falconer', '{}'::text[]),
  (-2732097, 'Carlie Kotyza-Witthuhn', 'Carlie', 'Kotyza-Witthuhn', '{}'::text[]),
  (-2732098, 'Julie Greene', 'Julie', 'Greene', '{}'::text[]),
  (-2732099, 'Steve Elkins', 'Steve', 'Elkins', '{}'::text[]),
  (-2732100, 'Michael Howard', 'Michael', 'Howard', ARRAY['Mike Howard']::text[]),
  (-2732101, 'Nathan Coulter', 'Nathan', 'Coulter', '{}'::text[]),
  (-2732102, 'Liz Reyer', 'Liz', 'Reyer', '{}'::text[]),
  (-2732103, 'Bianca Virnig', 'Bianca', 'Virnig', '{}'::text[]),
  (-2732104, 'Mary Frances Clardy', 'Mary', 'Clardy', ARRAY['Mary Clardy']::text[]),
  (-2732105, 'Rick Hansen', 'Rick', 'Hansen', '{}'::text[]),
  (-2732106, 'Brad Tabke', 'Brad', 'Tabke', '{}'::text[]),
  (-2732107, 'Ben Bakeberg', 'Ben', 'Bakeberg', '{}'::text[]),
  (-2732108, 'Jessica Hanson', 'Jessica', 'Hanson', ARRAY['Jess Hanson']::text[]),
  (-2732109, 'Robert Bierman', 'Robert', 'Bierman', '{}'::text[]),
  (-2732110, 'John Huot', 'John', 'Huot', '{}'::text[]),
  (-2732111, 'Jon Koznick', 'Jon', 'Koznick', '{}'::text[]),
  (-2732112, 'Jeff Witte', 'Jeff', 'Witte', '{}'::text[]),
  (-2732113, 'Kristi Pursell', 'Kristi', 'Pursell', '{}'::text[]),
  (-2732114, 'Drew Roach', 'Drew', 'Roach', '{}'::text[]),
  (-2732115, 'Fue Lee', 'Fue', 'Lee', '{}'::text[]),
  (-2732116, 'Esther Agbaje', 'Esther', 'Agbaje', '{}'::text[]),
  (-2732117, 'Sydney Jordan', 'Sydney', 'Jordan', '{}'::text[]),
  (-2732118, 'Mohamud Noor', 'Mohamud', 'Noor', '{}'::text[]),
  (-2732119, 'Katie Jones', 'Katie', 'Jones', '{}'::text[]),
  (-2732120, 'Jamie Long', 'Jamie', 'Long', '{}'::text[]),
  (-2732121, 'Aisha Gomez', 'Aisha', 'Gomez', '{}'::text[]),
  (-2732122, 'Anquam Mahamoud', 'Anquam', 'Mahamoud', '{}'::text[]),
  (-2732123, 'Samantha Sencer-Mura', 'Samantha', 'Sencer-Mura', '{}'::text[]),
  (-2732124, 'Emma Greenman', 'Emma', 'Greenman', '{}'::text[]),
  (-2732125, 'Meg Luger-Nikolai', 'Meg', 'Luger-Nikolai', '{}'::text[]),
  (-2732126, 'Dave Pinto', 'Dave', 'Pinto', '{}'::text[]),
  (-2732127, 'Samakab Hussein', 'Samakab', 'Hussein', '{}'::text[]),
  (-2732128, 'María Isa Pérez-Vega', 'María', 'Pérez-Vega', '{}'::text[]),
  (-2732129, 'Leigh Finke', 'Leigh', 'Finke', '{}'::text[]),
  (-2732130, 'Athena Hollins', 'Athena', 'Hollins', '{}'::text[]),
  (-2732131, 'Liz Lee', 'Liz', 'Lee', '{}'::text[]),
  (-2732132, 'Jay Xiong', 'Jay', 'Xiong', '{}'::text[]),
  (-2732133, 'Mark T. Johnson', 'Mark', 'Johnson', ARRAY['Mark Johnson']::text[]),
  (-2732134, 'Steve Green', 'Steve', 'Green', '{}'::text[]),
  (-2732135, 'Grant Hauschild', 'Grant', 'Hauschild', '{}'::text[]),
  (-2732136, 'Robert J. Kupec', 'Robert', 'Kupec', ARRAY['Rob Kupec']::text[]),
  (-2732137, 'Paul J. Utke', 'Paul', 'Utke', ARRAY['Paul Utke']::text[]),
  (-2732138, 'Keri Heintzeman', 'Keri', 'Heintzeman', '{}'::text[]),
  (-2732139, 'Robert D. Farnsworth', 'Robert', 'Farnsworth', ARRAY['Rob Farnsworth']::text[]),
  (-2732140, 'Jennifer A. McEwen', 'Jennifer', 'McEwen', ARRAY['Jen McEwen']::text[]),
  (-2732141, 'Jordan Rasmusson', 'Jordan', 'Rasmusson', '{}'::text[]),
  (-2732142, 'Nathan Wesenberg', 'Nathan', 'Wesenberg', '{}'::text[]),
  (-2732143, 'Jason Rarick', 'Jason', 'Rarick', '{}'::text[]),
  (-2732144, 'Torrey N. Westrom', 'Torrey', 'Westrom', ARRAY['Torrey Westrom']::text[]),
  (-2732145, 'Jeff R. Howe', 'Jeff', 'Howe', ARRAY['Jeff Howe']::text[]),
  (-2732146, 'Aric Putnam', 'Aric', 'Putnam', '{}'::text[]),
  (-2732147, 'Gary H. Dahms', 'Gary', 'Dahms', ARRAY['Gary Dahms']::text[]),
  (-2732148, 'Andrew R. Lang', 'Andrew', 'Lang', ARRAY['Andrew Lang']::text[]),
  (-2732149, 'Glenn H. Gruenhagen', 'Glenn', 'Gruenhagen', ARRAY['Glenn Gruenhagen']::text[]),
  (-2732150, 'Nick A. Frentz', 'Nick', 'Frentz', ARRAY['Nick Frentz']::text[]),
  (-2732151, 'John R. Jasinski', 'John', 'Jasinski', ARRAY['John Jasinski']::text[]),
  (-2732152, 'Steve Drazkowski', 'Steve', 'Drazkowski', '{}'::text[]),
  (-2732153, 'Bill Weber', 'Bill', 'Weber', '{}'::text[]),
  (-2732154, 'Rich Draheim', 'Rich', 'Draheim', '{}'::text[]),
  (-2732155, 'Gene Dornink', 'Gene', 'Dornink', '{}'::text[]),
  (-2732156, 'Carla J. Nelson', 'Carla', 'Nelson', ARRAY['Carla Nelson']::text[]),
  (-2732157, 'Liz Boldon', 'Liz', 'Boldon', '{}'::text[]),
  (-2732158, 'Jeremy R. Miller', 'Jeremy', 'Miller', ARRAY['Jeremy Miller']::text[]),
  (-2732159, 'Andrew Mathews', 'Andrew', 'Mathews', '{}'::text[]),
  (-2732160, 'Mark W. Koran', 'Mark', 'Koran', ARRAY['Mark Koran']::text[]),
  (-2732161, 'Michael W. Holmstrom', 'Michael', 'Holmstrom', ARRAY['Mike Holmstrom']::text[]),
  (-2732162, 'Eric Lucero', 'Eric', 'Lucero', '{}'::text[]),
  (-2732163, 'Calvin K. Bahr', 'Calvin', 'Bahr', ARRAY['Cal Bahr']::text[]),
  (-2732164, 'Michael E. Kreun', 'Michael', 'Kreun', ARRAY['Michael Kreun']::text[]),
  (-2732165, 'Karin Housley', 'Karin', 'Housley', '{}'::text[]),
  (-2732166, 'John A. Hoffman', 'John', 'Hoffman', ARRAY['John Hoffman']::text[]),
  (-2732167, 'Jim Abeler', 'Jim', 'Abeler', '{}'::text[]),
  (-2732168, 'Heather Gustafson', 'Heather', 'Gustafson', '{}'::text[]),
  (-2732169, 'Warren Limmer', 'Warren', 'Limmer', '{}'::text[]),
  (-2732170, 'Susan Pha', 'Susan', 'Pha', '{}'::text[]),
  (-2732171, 'Mary K. Kunesh', 'Mary', 'Kunesh', ARRAY['Mary Kunesh']::text[]),
  (-2732172, 'John Marty', 'John', 'Marty', '{}'::text[]),
  (-2732173, 'Judy Seeberger', 'Judy', 'Seeberger', '{}'::text[]),
  (-2732174, 'Bonnie S. Westlin', 'Bonnie', 'Westlin', ARRAY['Bonnie Westlin']::text[]),
  (-2732175, 'Ann H. Rest', 'Ann', 'Rest', ARRAY['Ann Rest']::text[]),
  (-2732176, 'Tou Xiong', 'Tou', 'Xiong', '{}'::text[]),
  (-2732177, 'Ann M. Johnson Stewart', 'Ann', 'Johnson Stewart', ARRAY['Ann Johnson Stewart']::text[]),
  (-2732178, 'Ron Latz', 'Ron', 'Latz', '{}'::text[]),
  (-2732179, 'Amanda H. Hemmingsen-Jaeger', 'Amanda', 'Hemmingsen-Jaeger', ARRAY['Amanda Hemmingsen-Jaeger']::text[]),
  (-2732180, 'Julia E. Coleman', 'Julia', 'Coleman', ARRAY['Julia Coleman']::text[]),
  (-2732181, 'Steve A. Cwodzinski', 'Steve', 'Cwodzinski', ARRAY['Steve Cwodzinski']::text[]),
  (-2732182, 'Alice Mann', 'Alice', 'Mann', '{}'::text[]),
  (-2732183, 'Melissa H. Wiklund', 'Melissa', 'Wiklund', ARRAY['Melissa Wiklund']::text[]),
  (-2732184, 'Jim Carlson', 'Jim', 'Carlson', '{}'::text[]),
  (-2732185, 'Matt D. Klein', 'Matt', 'Klein', ARRAY['Matt Klein']::text[]),
  (-2732186, 'Lindsey Port', 'Lindsey', 'Port', '{}'::text[]),
  (-2732187, 'Erin K. Maye Quade', 'Erin', 'Maye Quade', ARRAY['Erin Maye Quade']::text[]),
  (-2732188, 'Zach Duckworth', 'Zach', 'Duckworth', '{}'::text[]),
  (-2732189, 'Bill Lieske', 'Bill', 'Lieske', '{}'::text[]),
  (-2732190, 'Bobby Joe Champion', 'Bobby', 'Champion', '{}'::text[]),
  (-2732191, 'Doron Clark', 'Doron', 'Clark', '{}'::text[]),
  (-2732192, 'D. Scott Dibble', 'D.', 'Dibble', ARRAY['Scott Dibble']::text[]),
  (-2732193, 'Omar Fateh', 'Omar', 'Fateh', '{}'::text[]),
  (-2732194, 'Zaynab Mohamed', 'Zaynab', 'Mohamed', '{}'::text[]),
  (-2732196, 'Sandra L. Pappas', 'Sandra', 'Pappas', ARRAY['Sandy Pappas']::text[]),
  (-2732197, 'Clare Oumou Verbeten', 'Clare', 'Oumou Verbeten', '{}'::text[]),
  (-2732198, 'Foung Hawj', 'Foung', 'Hawj', '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Minnesota House of Representatives member list, https://www.house.mn.gov/members/; Minnesota Senate, https://www.senate.mn/api/members; reconciled against Open States, https://data.openstates.org/people/current/mn.csv; change-checked against all 201 individual member pages, read 2026-09-14 (MN-2)', n.alternate_names
FROM mn_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 3 people who share a name with a DIFFERENT person -- guard lifted ──────────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE mn_namesake_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO mn_namesake_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2732018, 'Tom Murphy', 'Tom', 'Murphy', '{}'::text[]),
  (-2732040, 'Steven Jacob', 'Steven', 'Jacob', ARRAY['Steve Jacob']::text[]),
  (-2732195, 'Erin P. Murphy', 'Erin', 'Murphy', ARRAY['Erin Murphy']::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Minnesota House of Representatives member list, https://www.house.mn.gov/members/; Minnesota Senate, https://www.senate.mn/api/members; reconciled against Open States, https://data.openstates.org/people/current/mn.csv; change-checked against all 201 individual member pages, read 2026-09-14 (MN-2)', n.alternate_names
FROM mn_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 200 terms, one per seated office ────────────────────────────────────────

CREATE TEMP TABLE mn_terms(geo_id text, district_type text, external_id bigint, politician_id uuid)
  ON COMMIT DROP;
INSERT INTO mn_terms(geo_id, district_type, external_id, politician_id) VALUES
  ('2701A', 'STATE_LOWER', -2732001::bigint, NULL::uuid),
  ('2701B', 'STATE_LOWER', -2732002::bigint, NULL::uuid),
  ('2702A', 'STATE_LOWER', -2732003::bigint, NULL::uuid),
  ('2702B', 'STATE_LOWER', -2732004::bigint, NULL::uuid),
  ('2703A', 'STATE_LOWER', -2732005::bigint, NULL::uuid),
  ('2703B', 'STATE_LOWER', -2732006::bigint, NULL::uuid),
  ('2704A', 'STATE_LOWER', -2732007::bigint, NULL::uuid),
  ('2704B', 'STATE_LOWER', -2732008::bigint, NULL::uuid),
  ('2705A', 'STATE_LOWER', -2732009::bigint, NULL::uuid),
  ('2705B', 'STATE_LOWER', -2732010::bigint, NULL::uuid),
  ('2706A', 'STATE_LOWER', -2732011::bigint, NULL::uuid),
  ('2706B', 'STATE_LOWER', -2732012::bigint, NULL::uuid),
  ('2707A', 'STATE_LOWER', -2732013::bigint, NULL::uuid),
  ('2707B', 'STATE_LOWER', -2732014::bigint, NULL::uuid),
  ('2708A', 'STATE_LOWER', -2732015::bigint, NULL::uuid),
  ('2708B', 'STATE_LOWER', -2732016::bigint, NULL::uuid),
  ('2709A', 'STATE_LOWER', -2732017::bigint, NULL::uuid),
  ('2709B', 'STATE_LOWER', -2732018::bigint, NULL::uuid),
  ('2710A', 'STATE_LOWER', -2732019::bigint, NULL::uuid),
  ('2710B', 'STATE_LOWER', -2732020::bigint, NULL::uuid),
  ('2711A', 'STATE_LOWER', -2732021::bigint, NULL::uuid),
  ('2711B', 'STATE_LOWER', -2732022::bigint, NULL::uuid),
  ('2712A', 'STATE_LOWER', -2732023::bigint, NULL::uuid),
  ('2712B', 'STATE_LOWER', -2732024::bigint, NULL::uuid),
  ('2713A', 'STATE_LOWER', -2732025::bigint, NULL::uuid),
  ('2713B', 'STATE_LOWER', -2732026::bigint, NULL::uuid),
  ('2714A', 'STATE_LOWER', -2732027::bigint, NULL::uuid),
  ('2714B', 'STATE_LOWER', -2732028::bigint, NULL::uuid),
  ('2715A', 'STATE_LOWER', -2732029::bigint, NULL::uuid),
  ('2715B', 'STATE_LOWER', -2732030::bigint, NULL::uuid),
  ('2716A', 'STATE_LOWER', -2732031::bigint, NULL::uuid),
  ('2716B', 'STATE_LOWER', -2732032::bigint, NULL::uuid),
  ('2717A', 'STATE_LOWER', -2732033::bigint, NULL::uuid),
  ('2717B', 'STATE_LOWER', -2732034::bigint, NULL::uuid),
  ('2718A', 'STATE_LOWER', -2732035::bigint, NULL::uuid),
  ('2718B', 'STATE_LOWER', -2732036::bigint, NULL::uuid),
  ('2719A', 'STATE_LOWER', -2732037::bigint, NULL::uuid),
  ('2719B', 'STATE_LOWER', -2732038::bigint, NULL::uuid),
  ('2720A', 'STATE_LOWER', -2732039::bigint, NULL::uuid),
  ('2720B', 'STATE_LOWER', -2732040::bigint, NULL::uuid),
  ('2721B', 'STATE_LOWER', -2732041::bigint, NULL::uuid),
  ('2722A', 'STATE_LOWER', -2732042::bigint, NULL::uuid),
  ('2722B', 'STATE_LOWER', -2732043::bigint, NULL::uuid),
  ('2723A', 'STATE_LOWER', -2732044::bigint, NULL::uuid),
  ('2723B', 'STATE_LOWER', -2732045::bigint, NULL::uuid),
  ('2724A', 'STATE_LOWER', -2732046::bigint, NULL::uuid),
  ('2724B', 'STATE_LOWER', -2732047::bigint, NULL::uuid),
  ('2725A', 'STATE_LOWER', -2732048::bigint, NULL::uuid),
  ('2725B', 'STATE_LOWER', -2732049::bigint, NULL::uuid),
  ('2726A', 'STATE_LOWER', -2732050::bigint, NULL::uuid),
  ('2726B', 'STATE_LOWER', -2732051::bigint, NULL::uuid),
  ('2727A', 'STATE_LOWER', -2732052::bigint, NULL::uuid),
  ('2727B', 'STATE_LOWER', -2732053::bigint, NULL::uuid),
  ('2728A', 'STATE_LOWER', -2732054::bigint, NULL::uuid),
  ('2728B', 'STATE_LOWER', -2732055::bigint, NULL::uuid),
  ('2729A', 'STATE_LOWER', -2732056::bigint, NULL::uuid),
  ('2729B', 'STATE_LOWER', -2732057::bigint, NULL::uuid),
  ('2730A', 'STATE_LOWER', -2732058::bigint, NULL::uuid),
  ('2730B', 'STATE_LOWER', -2732059::bigint, NULL::uuid),
  ('2731A', 'STATE_LOWER', -2732060::bigint, NULL::uuid),
  ('2731B', 'STATE_LOWER', -2732061::bigint, NULL::uuid),
  ('2732A', 'STATE_LOWER', -2732062::bigint, NULL::uuid),
  ('2732B', 'STATE_LOWER', -2732063::bigint, NULL::uuid),
  ('2733A', 'STATE_LOWER', -2732064::bigint, NULL::uuid),
  ('2733B', 'STATE_LOWER', -2732065::bigint, NULL::uuid),
  ('2734A', 'STATE_LOWER', -2732066::bigint, NULL::uuid),
  ('2734B', 'STATE_LOWER', -2732067::bigint, NULL::uuid),
  ('2735A', 'STATE_LOWER', -2732068::bigint, NULL::uuid),
  ('2735B', 'STATE_LOWER', -2732069::bigint, NULL::uuid),
  ('2736A', 'STATE_LOWER', -2732070::bigint, NULL::uuid),
  ('2736B', 'STATE_LOWER', -2732071::bigint, NULL::uuid),
  ('2737A', 'STATE_LOWER', -2732072::bigint, NULL::uuid),
  ('2737B', 'STATE_LOWER', -2732073::bigint, NULL::uuid),
  ('2738A', 'STATE_LOWER', -2732074::bigint, NULL::uuid),
  ('2738B', 'STATE_LOWER', -2732075::bigint, NULL::uuid),
  ('2739A', 'STATE_LOWER', -2732076::bigint, NULL::uuid),
  ('2739B', 'STATE_LOWER', -2732077::bigint, NULL::uuid),
  ('2740A', 'STATE_LOWER', -2732078::bigint, NULL::uuid),
  ('2740B', 'STATE_LOWER', -2732079::bigint, NULL::uuid),
  ('2741A', 'STATE_LOWER', -2732080::bigint, NULL::uuid),
  ('2741B', 'STATE_LOWER', -2732081::bigint, NULL::uuid),
  ('2742A', 'STATE_LOWER', -2732082::bigint, NULL::uuid),
  ('2742B', 'STATE_LOWER', -2732083::bigint, NULL::uuid),
  ('2743A', 'STATE_LOWER', -2732084::bigint, NULL::uuid),
  ('2743B', 'STATE_LOWER', -2732085::bigint, NULL::uuid),
  ('2744A', 'STATE_LOWER', -2732086::bigint, NULL::uuid),
  ('2744B', 'STATE_LOWER', -2732087::bigint, NULL::uuid),
  ('2745A', 'STATE_LOWER', -2732088::bigint, NULL::uuid),
  ('2745B', 'STATE_LOWER', -2732089::bigint, NULL::uuid),
  ('2746A', 'STATE_LOWER', -2732090::bigint, NULL::uuid),
  ('2746B', 'STATE_LOWER', -2732091::bigint, NULL::uuid),
  ('2747A', 'STATE_LOWER', -2732092::bigint, NULL::uuid),
  ('2747B', 'STATE_LOWER', -2732093::bigint, NULL::uuid),
  ('2748A', 'STATE_LOWER', -2732094::bigint, NULL::uuid),
  ('2748B', 'STATE_LOWER', -2732095::bigint, NULL::uuid),
  ('2749A', 'STATE_LOWER', -2732096::bigint, NULL::uuid),
  ('2749B', 'STATE_LOWER', -2732097::bigint, NULL::uuid),
  ('2750A', 'STATE_LOWER', -2732098::bigint, NULL::uuid),
  ('2750B', 'STATE_LOWER', -2732099::bigint, NULL::uuid),
  ('2751A', 'STATE_LOWER', -2732100::bigint, NULL::uuid),
  ('2751B', 'STATE_LOWER', -2732101::bigint, NULL::uuid),
  ('2752A', 'STATE_LOWER', -2732102::bigint, NULL::uuid),
  ('2752B', 'STATE_LOWER', -2732103::bigint, NULL::uuid),
  ('2753A', 'STATE_LOWER', -2732104::bigint, NULL::uuid),
  ('2753B', 'STATE_LOWER', -2732105::bigint, NULL::uuid),
  ('2754A', 'STATE_LOWER', -2732106::bigint, NULL::uuid),
  ('2754B', 'STATE_LOWER', -2732107::bigint, NULL::uuid),
  ('2755A', 'STATE_LOWER', -2732108::bigint, NULL::uuid),
  ('2755B', 'STATE_LOWER', NULL::bigint, 'a89ba4b9-a684-40a6-b5ec-db0876a65b8d'::uuid),
  ('2756A', 'STATE_LOWER', -2732109::bigint, NULL::uuid),
  ('2756B', 'STATE_LOWER', -2732110::bigint, NULL::uuid),
  ('2757A', 'STATE_LOWER', -2732111::bigint, NULL::uuid),
  ('2757B', 'STATE_LOWER', -2732112::bigint, NULL::uuid),
  ('2758A', 'STATE_LOWER', -2732113::bigint, NULL::uuid),
  ('2758B', 'STATE_LOWER', -2732114::bigint, NULL::uuid),
  ('2759A', 'STATE_LOWER', -2732115::bigint, NULL::uuid),
  ('2759B', 'STATE_LOWER', -2732116::bigint, NULL::uuid),
  ('2760A', 'STATE_LOWER', -2732117::bigint, NULL::uuid),
  ('2760B', 'STATE_LOWER', -2732118::bigint, NULL::uuid),
  ('2761A', 'STATE_LOWER', -2732119::bigint, NULL::uuid),
  ('2761B', 'STATE_LOWER', -2732120::bigint, NULL::uuid),
  ('2762A', 'STATE_LOWER', -2732121::bigint, NULL::uuid),
  ('2762B', 'STATE_LOWER', -2732122::bigint, NULL::uuid),
  ('2763A', 'STATE_LOWER', -2732123::bigint, NULL::uuid),
  ('2763B', 'STATE_LOWER', -2732124::bigint, NULL::uuid),
  ('2764A', 'STATE_LOWER', -2732125::bigint, NULL::uuid),
  ('2764B', 'STATE_LOWER', -2732126::bigint, NULL::uuid),
  ('2765A', 'STATE_LOWER', -2732127::bigint, NULL::uuid),
  ('2765B', 'STATE_LOWER', -2732128::bigint, NULL::uuid),
  ('2766A', 'STATE_LOWER', -2732129::bigint, NULL::uuid),
  ('2766B', 'STATE_LOWER', -2732130::bigint, NULL::uuid),
  ('2767A', 'STATE_LOWER', -2732131::bigint, NULL::uuid),
  ('2767B', 'STATE_LOWER', -2732132::bigint, NULL::uuid),
  ('27001', 'STATE_UPPER', -2732133::bigint, NULL::uuid),
  ('27002', 'STATE_UPPER', -2732134::bigint, NULL::uuid),
  ('27003', 'STATE_UPPER', -2732135::bigint, NULL::uuid),
  ('27004', 'STATE_UPPER', -2732136::bigint, NULL::uuid),
  ('27005', 'STATE_UPPER', -2732137::bigint, NULL::uuid),
  ('27006', 'STATE_UPPER', -2732138::bigint, NULL::uuid),
  ('27007', 'STATE_UPPER', -2732139::bigint, NULL::uuid),
  ('27008', 'STATE_UPPER', -2732140::bigint, NULL::uuid),
  ('27009', 'STATE_UPPER', -2732141::bigint, NULL::uuid),
  ('27010', 'STATE_UPPER', -2732142::bigint, NULL::uuid),
  ('27011', 'STATE_UPPER', -2732143::bigint, NULL::uuid),
  ('27012', 'STATE_UPPER', -2732144::bigint, NULL::uuid),
  ('27013', 'STATE_UPPER', -2732145::bigint, NULL::uuid),
  ('27014', 'STATE_UPPER', -2732146::bigint, NULL::uuid),
  ('27015', 'STATE_UPPER', -2732147::bigint, NULL::uuid),
  ('27016', 'STATE_UPPER', -2732148::bigint, NULL::uuid),
  ('27017', 'STATE_UPPER', -2732149::bigint, NULL::uuid),
  ('27018', 'STATE_UPPER', -2732150::bigint, NULL::uuid),
  ('27019', 'STATE_UPPER', -2732151::bigint, NULL::uuid),
  ('27020', 'STATE_UPPER', -2732152::bigint, NULL::uuid),
  ('27021', 'STATE_UPPER', -2732153::bigint, NULL::uuid),
  ('27022', 'STATE_UPPER', -2732154::bigint, NULL::uuid),
  ('27023', 'STATE_UPPER', -2732155::bigint, NULL::uuid),
  ('27024', 'STATE_UPPER', -2732156::bigint, NULL::uuid),
  ('27025', 'STATE_UPPER', -2732157::bigint, NULL::uuid),
  ('27026', 'STATE_UPPER', -2732158::bigint, NULL::uuid),
  ('27027', 'STATE_UPPER', -2732159::bigint, NULL::uuid),
  ('27028', 'STATE_UPPER', -2732160::bigint, NULL::uuid),
  ('27029', 'STATE_UPPER', -2732161::bigint, NULL::uuid),
  ('27030', 'STATE_UPPER', -2732162::bigint, NULL::uuid),
  ('27031', 'STATE_UPPER', -2732163::bigint, NULL::uuid),
  ('27032', 'STATE_UPPER', -2732164::bigint, NULL::uuid),
  ('27033', 'STATE_UPPER', -2732165::bigint, NULL::uuid),
  ('27034', 'STATE_UPPER', -2732166::bigint, NULL::uuid),
  ('27035', 'STATE_UPPER', -2732167::bigint, NULL::uuid),
  ('27036', 'STATE_UPPER', -2732168::bigint, NULL::uuid),
  ('27037', 'STATE_UPPER', -2732169::bigint, NULL::uuid),
  ('27038', 'STATE_UPPER', -2732170::bigint, NULL::uuid),
  ('27039', 'STATE_UPPER', -2732171::bigint, NULL::uuid),
  ('27040', 'STATE_UPPER', -2732172::bigint, NULL::uuid),
  ('27041', 'STATE_UPPER', -2732173::bigint, NULL::uuid),
  ('27042', 'STATE_UPPER', -2732174::bigint, NULL::uuid),
  ('27043', 'STATE_UPPER', -2732175::bigint, NULL::uuid),
  ('27044', 'STATE_UPPER', -2732176::bigint, NULL::uuid),
  ('27045', 'STATE_UPPER', -2732177::bigint, NULL::uuid),
  ('27046', 'STATE_UPPER', -2732178::bigint, NULL::uuid),
  ('27047', 'STATE_UPPER', -2732179::bigint, NULL::uuid),
  ('27048', 'STATE_UPPER', -2732180::bigint, NULL::uuid),
  ('27049', 'STATE_UPPER', -2732181::bigint, NULL::uuid),
  ('27050', 'STATE_UPPER', -2732182::bigint, NULL::uuid),
  ('27051', 'STATE_UPPER', -2732183::bigint, NULL::uuid),
  ('27052', 'STATE_UPPER', -2732184::bigint, NULL::uuid),
  ('27053', 'STATE_UPPER', -2732185::bigint, NULL::uuid),
  ('27054', 'STATE_UPPER', NULL::bigint, 'fa8d5cfb-5feb-4112-b68b-f1c2de963dc3'::uuid),
  ('27055', 'STATE_UPPER', -2732186::bigint, NULL::uuid),
  ('27056', 'STATE_UPPER', -2732187::bigint, NULL::uuid),
  ('27057', 'STATE_UPPER', -2732188::bigint, NULL::uuid),
  ('27058', 'STATE_UPPER', -2732189::bigint, NULL::uuid),
  ('27059', 'STATE_UPPER', -2732190::bigint, NULL::uuid),
  ('27060', 'STATE_UPPER', -2732191::bigint, NULL::uuid),
  ('27061', 'STATE_UPPER', -2732192::bigint, NULL::uuid),
  ('27062', 'STATE_UPPER', -2732193::bigint, NULL::uuid),
  ('27063', 'STATE_UPPER', -2732194::bigint, NULL::uuid),
  ('27064', 'STATE_UPPER', -2732195::bigint, NULL::uuid),
  ('27065', 'STATE_UPPER', -2732196::bigint, NULL::uuid),
  ('27066', 'STATE_UPPER', -2732197::bigint, NULL::uuid),
  ('27067', 'STATE_UPPER', -2732198::bigint, NULL::uuid);

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown', 'Minnesota House of Representatives member list, https://www.house.mn.gov/members/; Minnesota Senate, https://www.senate.mn/api/members; reconciled against Open States, https://data.openstates.org/people/current/mn.csv; change-checked against all 201 individual member pages, read 2026-09-14 (MN-2) (CC_0108, MN-2)'
FROM mn_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'mn'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p
  ON (t.politician_id IS NOT NULL AND p.id = t.politician_id)
  OR (t.external_id  IS NOT NULL AND p.external_id = t.external_id)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people   int;
  v_terms    int;
  v_seated   int;
  v_offices  int;
  v_dated    int;
  v_ended    int;
  v_vacseat  int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2732201 AND -2732001;
  IF v_people <> 198 THEN
    RAISE EXCEPTION 'MN-2 occupancy: expected 198 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_offices <> 201 THEN
    RAISE EXCEPTION 'MN-2 occupancy: expected 201 Minnesota legislative offices, got %', v_offices;
  END IF;

  -- och.politician_id, never count(*): office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> 200 THEN
    RAISE EXCEPTION 'MN-2 occupancy: expected 200 seated Minnesota legislative offices, got %', v_seated;
  END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_terms <> 200 THEN
    RAISE EXCEPTION 'MN-2 occupancy: expected 200 term rows, got %', v_terms;
  END IF;

  SELECT count(*) FILTER (WHERE t.term_start IS NOT NULL),
         count(*) FILTER (WHERE t.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_dated <> 0 OR v_ended <> 0 THEN
    RAISE EXCEPTION 'MN-2 occupancy: % dated and % ended terms; every Minnesota term is open-ended and unknown', v_dated, v_ended;
  END IF;

  -- The vacant seat must still be vacant and still unseated.
  SELECT count(och.politician_id) INTO v_vacseat
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'mn' AND d.geo_id = '2721A' AND d.district_type::text = 'STATE_LOWER';
  IF v_vacseat <> 0 THEN
    RAISE EXCEPTION 'MN-2 occupancy: HD-21A is seated by % holder(s); it is vacant', v_vacseat;
  END IF;

  RAISE NOTICE 'MN-2 occupancy OK: % people in band, % offices, % seated, % terms, % dated, % ended, 21A vacant',
    v_people, v_offices, v_seated, v_terms, v_dated, v_ended;
END $$;

COMMIT;
