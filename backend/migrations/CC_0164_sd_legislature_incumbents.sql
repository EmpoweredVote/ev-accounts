-- CC_0164_sd_legislature_incumbents.sql
-- Knight Foundation program, wave SD-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0163, which creates the 2 chambers and the 105 offices.
--
-- Seats all 105 members of the 101st South Dakota Legislature: 35 senators and 70 representatives.
-- Creates 104 new people, reuses 0, and creates 1 more under a lifted duplicate-name guard.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 EVERY ONE OF THE 105 TERMS IS DATED TO THE DAY. NONE IS 'unknown'. That is unusual in this
-- program -- ND-2 wrote 133 of 141 open-ended -- and it is possible because South Dakota's
-- Legislature publishes its own oath record and its Governor publishes his own appointments.
--
--   98 terms  2025-01-14  how_started 'elected'   -- the first-day oath lists, Journal of the
--                                                    House (doc 274999, pp.4-5, 68 names) and
--                                                    Journal of the Senate (doc 274997, p.4,
--                                                    33 names), oath administered by Justice
--                                                    Patricia J. DeVaney and Chief Justice
--                                                    Steven R. Jensen respectively; plus Rep.
--                                                    Peri Pourier, whose oath the 2nd-day House
--                                                    journal records as taken "at 1:15 p.m. on
--                                                    Tuesday, January 14, 2025".
--    2 terms  2025-01-15  how_started 'elected'   -- Sens. Sydney Davis and Larry Zikmund, who
--                                                    were EXCUSED on the first day; the 2nd-day
--                                                    Senate journal (doc 274998) records their
--                                                    oath, administered by President Larry Rhoden.
--    5 terms  various     how_started 'appointed' -- the Governor's own announcements:
--                          2025-02-05 Jack R. Kolbeck   H-13  (after Venhuizen left 2025-01-29)
--                          2025-02-12 Tim Czmowski      H-06  (seat never filled on day one)
--                          2025-07-10 Brandon Wipf      S-22  (after Wheeler left 2025-04-24)
--                          2025-08-05 Nick Fosness      H-01  (after Reder left 2025-05-01)
--                          2025-09-17 John Shubeck      H-16  (after Vasgaard left 2025-08-27)
--                        Every appointment date falls AFTER its predecessor's departure date --
--                        checked, not assumed.
--
-- 🔴 THE OATH LIST AND THE ROLL CALL ARE DIFFERENT EVENTS, AND CONFUSING THEM LOSES A MEMBER.
-- Rep. Keri K. Weems appears in the first-day oath list AND in the "excused" line of the same
-- day's roll call. Matching on the roll would have wrongly sent her for research; matching on the
-- oath list is correct. Only Pourier, Davis and Zikmund are genuinely absent from an oath list.
--
-- 🔴 A ROSTER LABEL SAYS HOW SOMEONE ARRIVED, NOT WHEN. The API's MemberTermName carries
-- "New Member" (40), "Incumbent" (53), "Governor's Appointment" (5) and "Other House" (7). NONE of
-- those is a date, and "Other House" means only that the member previously served in the other
-- chamber -- all 7 were elected to their current seat in November 2024 and took the first-day
-- oath with everyone else. The 5 appointments are the only rows whose start differs for that
-- reason.
--
-- ⚠ A WEB SEARCH SUMMARY CLAIMED POURIER WAS SWORN AT 1:15 P.M. ON THE FIRST DAY AND THE FIRST-DAY
-- JOURNAL CONTRADICTS IT -- she is absent from that day's oath list and excused from every roll.
-- The claim turned out to be true, but the evidence for it is in the SECOND day's journal. The
-- date written here comes from that document, not from the summary.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 ONE NAME COLLIDES WITH A DIFFERENT PERSON. Production already holds a 'Lauren Nelson'
-- (external_id -840005), and she is the EL PASO COUNTY COMMISSIONER FOR DISTRICT 5 IN COLORADO,
-- not South Dakota's senator for District 18. The row is NOT reused; a new person is created with
-- the duplicate-name guard lifted for that one statement, exactly as ND-2 did for Dick Anderson.
-- Checked, not assumed -- 2 of 4 name hits in the GA wave were a Colorado senator and a Utah
-- treasurer.
--
-- 🔴 THE JOIN KEY IS (geo_id, district_type, slot), NEVER geo_id ALONE. '46020' is BOTH Senate
-- District 20 and House District 20, and seventeen South Dakota counties carry a geo_id inside the
-- Senate range -- Aurora County is '46003' and so is Senate District 3. The slot is what resolves
-- the two interchangeable House offices within a whole district.
--
-- 🔴 is_incumbent IS SET EXPLICITLY ON EVERY INSERT. It defaults to false since CA_0188, and a
-- seated person inserted without it is HIDDEN from address search.
--
-- 🔴 PARTY IS NOT WRITTEN. The roster carries it (97 R, 8 D); party lives on races.primary_party.
--
-- 🟢 THE RESERVED external_id BAND IS -2766000 .. -2765896 (105 ids), MEASURED EMPTY on
-- 2026-09-28 before this file was written. ND-2's first choice of band was already occupied.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The 104 new people ─────────────────────────────────────────────────────

CREATE TEMP TABLE sd_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO sd_new_people(external_id, full_name, first_name, last_name) VALUES
  (-2765896::bigint, 'Logan Manhart', 'Logan', 'Manhart'),
  (-2765897::bigint, 'Nick Fosness', 'Nick', 'Fosness'),
  (-2765898::bigint, 'David Kull', 'David', 'Kull'),
  (-2765899::bigint, 'John Sjaarda', 'John', 'Sjaarda'),
  (-2765900::bigint, 'Al Novstrup', 'Al', 'Novstrup'),
  (-2765901::bigint, 'Brandei Schaefbauer', 'Brandei', 'Schaefbauer'),
  (-2765902::bigint, 'Dylan C. Jordan', 'Dylan', 'Jordan'),
  (-2765903::bigint, 'Kent Roe', 'Kent', 'Roe'),
  (-2765904::bigint, 'Josephine Garcia', 'Josephine', 'Garcia'),
  (-2765905::bigint, 'Matt Roby', 'Matt', 'Roby'),
  (-2765906::bigint, 'Aaron Aylward', 'Aaron', 'Aylward'),
  (-2765907::bigint, 'Tim Czmowski', 'Tim', 'Czmowski'),
  (-2765908::bigint, 'Mellissa Heermann', 'Mellissa', 'Heermann'),
  (-2765909::bigint, 'Roger DeGroot', 'Roger', 'DeGroot'),
  (-2765910::bigint, 'Tim Reisch', 'Tim', 'Reisch'),
  (-2765911::bigint, 'Tim Walburg', 'Tim', 'Walburg'),
  (-2765912::bigint, 'Bethany Soye', 'Bethany', 'Soye'),
  (-2765913::bigint, 'Tesa Schwans', 'Tesa', 'Schwans'),
  (-2765914::bigint, 'Bobbi L. Andera', 'Bobbi', 'Andera'),
  (-2765915::bigint, 'Erin Healy', 'Erin', 'Healy'),
  (-2765916::bigint, 'Brian Mulder', 'Brian', 'Mulder'),
  (-2765917::bigint, 'Keri K. Weems', 'Keri', 'Weems'),
  (-2765918::bigint, 'Amber Arlint', 'Amber', 'Arlint'),
  (-2765919::bigint, 'Greg Jamison', 'Greg', 'Jamison'),
  (-2765920::bigint, 'Jack R. Kolbeck', 'Jack', 'Kolbeck'),
  (-2765921::bigint, 'John Hughes', 'John', 'Hughes'),
  (-2765922::bigint, 'Taylor Rehfeldt', 'Taylor', 'Rehfeldt'),
  (-2765923::bigint, 'Tony Kayser', 'Tony', 'Kayser'),
  (-2765924::bigint, 'Erik Muckey', 'Erik', 'Muckey'),
  (-2765925::bigint, 'Kadyn Wittman', 'Kadyn', 'Wittman'),
  (-2765926::bigint, 'John Shubeck', 'John', 'Shubeck'),
  (-2765927::bigint, 'Karla J. Lems', 'Karla', 'Lems'),
  (-2765928::bigint, 'Chris Kassin', 'Chris', 'Kassin'),
  (-2765929::bigint, 'William Shorma', 'William', 'Shorma'),
  (-2765930::bigint, 'Julie Auch', 'Julie', 'Auch'),
  (-2765931::bigint, 'Mike Stevens', 'Mike', 'Stevens'),
  (-2765932::bigint, 'Drew Peterson', 'Drew', 'Peterson'),
  (-2765933::bigint, 'Jessica Bahmuller', 'Jessica', 'Bahmuller'),
  (-2765934::bigint, 'Jeff Bathke', 'Jeff', 'Bathke'),
  (-2765935::bigint, 'Kaley Nolz', 'Kaley', 'Nolz'),
  (-2765936::bigint, 'Jim Halverson', 'Jim', 'Halverson'),
  (-2765937::bigint, 'Marty Overweg', 'Marty', 'Overweg'),
  (-2765938::bigint, 'Kevin Van Diepen', 'Kevin', 'Van Diepen'),
  (-2765939::bigint, 'Lana J. Greenfield', 'Lana', 'Greenfield'),
  (-2765940::bigint, 'Scott Moore', 'Scott', 'Moore'),
  (-2765941::bigint, 'Spencer Gosch', 'Spencer', 'Gosch'),
  (-2765942::bigint, 'Mike Weisgram', 'Mike', 'Weisgram'),
  (-2765943::bigint, 'Will Mortenson', 'Will', 'Mortenson'),
  (-2765944::bigint, 'Jon Hansen', 'Jon', 'Hansen'),
  (-2765945::bigint, 'Leslie J. Heinemann', 'Leslie', 'Heinemann'),
  (-2765946::bigint, 'Liz M. May', 'Liz', 'May'),
  (-2765947::bigint, 'Peri Pourier', 'Peri', 'Pourier'),
  (-2765948::bigint, 'Kathy Rice', 'Kathy', 'Rice'),
  (-2765949::bigint, 'Terri Jorgenson', 'Terri', 'Jorgenson'),
  (-2765950::bigint, 'Tim Goodwin', 'Tim', 'Goodwin'),
  (-2765951::bigint, 'Trish Ladner', 'Trish', 'Ladner'),
  (-2765952::bigint, 'Mary J. Fitzgerald', 'Mary', 'Fitzgerald'),
  (-2765953::bigint, 'Scott Odenbach', 'Scott', 'Odenbach'),
  (-2765954::bigint, 'Nicole Uhre-Balk', 'Nicole', 'Uhre-Balk'),
  (-2765955::bigint, 'Steve Duffy', 'Steve', 'Duffy'),
  (-2765956::bigint, 'Curt Massie', 'Curt', 'Massie'),
  (-2765957::bigint, 'Phil Jensen', 'Phil', 'Jensen'),
  (-2765958::bigint, 'Heather Baxter', 'Heather', 'Baxter'),
  (-2765959::bigint, 'Mike Derby', 'Mike', 'Derby'),
  (-2765960::bigint, 'Tina L. Mulally', 'Tina', 'Mulally'),
  (-2765961::bigint, 'Tony Randolph', 'Tony', 'Randolph'),
  (-2765962::bigint, 'Eric Emery', 'Eric', 'Emery'),
  (-2765963::bigint, 'Rebecca Reimer', 'Rebecca', 'Reimer'),
  (-2765964::bigint, 'Jana Hunt', 'Jana', 'Hunt'),
  (-2765965::bigint, 'Travis Ismay', 'Travis', 'Ismay'),
  (-2765966::bigint, 'Michael H. Rohl', 'Michael', 'Rohl'),
  (-2765967::bigint, 'Steve Kolbeck', 'Steve', 'Kolbeck'),
  (-2765968::bigint, 'Carl Perry', 'Carl', 'Perry'),
  (-2765969::bigint, 'Stephanie Sauder', 'Stephanie', 'Sauder'),
  (-2765970::bigint, 'Glen Vilhauer', 'Glen', 'Vilhauer'),
  (-2765971::bigint, 'Ernie Otten', 'Ernie', 'Otten'),
  (-2765972::bigint, 'Tim S. Reed', 'Tim', 'Reed'),
  (-2765973::bigint, 'Casey Crabtree', 'Casey', 'Crabtree'),
  (-2765974::bigint, 'Joy A. Hohn', 'Joy', 'Hohn'),
  (-2765975::bigint, 'Liz Larson', 'Liz', 'Larson'),
  (-2765976::bigint, 'Chris Karr', 'Chris', 'Karr'),
  (-2765977::bigint, 'Arch Beal', 'Arch', 'Beal'),
  (-2765978::bigint, 'Sue Peterson', 'Sue', 'Peterson'),
  (-2765979::bigint, 'Larry P. Zikmund', 'Larry', 'Zikmund'),
  (-2765980::bigint, 'Jamie Smith', 'Jamie', 'Smith'),
  (-2765981::bigint, 'Kevin D. Jensen', 'Kevin', 'Jensen'),
  (-2765982::bigint, 'Sydney Davis', 'Sydney', 'Davis'),
  (-2765984::bigint, 'Kyle Schoenfish', 'Kyle', 'Schoenfish'),
  (-2765985::bigint, 'Paul R. Miskimins', 'Paul', 'Miskimins'),
  (-2765986::bigint, 'Mykala Voita', 'Mykala', 'Voita'),
  (-2765987::bigint, 'Brandon Wipf', 'Brandon', 'Wipf'),
  (-2765988::bigint, 'Mark Lapka', 'Mark', 'Lapka'),
  (-2765989::bigint, 'Jim Mehlhaff', 'Jim', 'Mehlhaff'),
  (-2765990::bigint, 'Tom Pischke', 'Tom', 'Pischke'),
  (-2765991::bigint, 'Tamara R. Grove', 'Tamara', 'Grove'),
  (-2765992::bigint, 'Red Dawn Foster', 'Red Dawn', 'Foster'),
  (-2765993::bigint, 'Sam S. Marty', 'Sam', 'Marty'),
  (-2765994::bigint, 'John Carley', 'John', 'Carley'),
  (-2765995::bigint, 'Amber Hulse', 'Amber', 'Hulse'),
  (-2765996::bigint, 'Randy Deibert', 'Randy', 'Deibert'),
  (-2765997::bigint, 'Helene Duhamel', 'Helene', 'Duhamel'),
  (-2765998::bigint, 'Curt Voight', 'Curt', 'Voight'),
  (-2765999::bigint, 'Taffy Howard', 'Taffy', 'Howard'),
  (-2766000::bigint, 'Greg Blanc', 'Greg', 'Blanc');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'South Dakota Legislature, 101st Session (2026) member roster, https://sdlegislature.gov/api/SessionMembers/Session/71 — 105 members, 0 InactiveDate, read 2026-09-28. Term starts are DATED from the body’s own record: the oath lists in the Journal of the House and Journal of the Senate, 100th Session, 1st Legislative Day, 2025-01-14 (docs 274999 and 274997), plus the 2nd Legislative Day journals (docs 275000 and 274998) for Pourier, Davis and Zikmund, and the Office of the Governor of South Dakota’s own appointment announcements for the five Governor’s appointments (SD-2) (CC_0164, SD-2)', true, true
FROM sd_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The one namesake — guard lifted for this statement only ───────────────
-- 'Lauren Nelson' already exists as an El Paso County, COLORADO commissioner. Different person.

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE sd_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO sd_namesake_people(external_id, full_name, first_name, last_name) VALUES
  (-2765983::bigint, 'Lauren Nelson', 'Lauren', 'Nelson');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'South Dakota Legislature, 101st Session (2026) member roster, https://sdlegislature.gov/api/SessionMembers/Session/71 — 105 members, 0 InactiveDate, read 2026-09-28. Term starts are DATED from the body’s own record: the oath lists in the Journal of the House and Journal of the Senate, 100th Session, 1st Legislative Day, 2025-01-14 (docs 274999 and 274997), plus the 2nd Legislative Day journals (docs 275000 and 274998) for Pourier, Davis and Zikmund, and the Office of the Governor of South Dakota’s own appointment announcements for the five Governor’s appointments (SD-2) (CC_0164, SD-2)', true, true
FROM sd_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 3. The 105 terms ─────────────────────────────────────────────────────────

CREATE TEMP TABLE sd_terms(
  geo_id text, district_type text, external_id bigint,
  sort_key text, term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO sd_terms(geo_id, district_type, external_id, sort_key, term_start, start_precision, how_started) VALUES
  ('46001', 'STATE_LOWER', -2765896::bigint, 'Logan Manhart', '2025-01-14'::date, 'day', 'elected'),
  ('46001', 'STATE_LOWER', -2765897::bigint, 'Nick Fosness', '2025-08-05'::date, 'day', 'appointed'),
  ('46002', 'STATE_LOWER', -2765898::bigint, 'David Kull', '2025-01-14'::date, 'day', 'elected'),
  ('46002', 'STATE_LOWER', -2765899::bigint, 'John Sjaarda', '2025-01-14'::date, 'day', 'elected'),
  ('46003', 'STATE_LOWER', -2765900::bigint, 'Al Novstrup', '2025-01-14'::date, 'day', 'elected'),
  ('46003', 'STATE_LOWER', -2765901::bigint, 'Brandei Schaefbauer', '2025-01-14'::date, 'day', 'elected'),
  ('46004', 'STATE_LOWER', -2765902::bigint, 'Dylan C. Jordan', '2025-01-14'::date, 'day', 'elected'),
  ('46004', 'STATE_LOWER', -2765903::bigint, 'Kent Roe', '2025-01-14'::date, 'day', 'elected'),
  ('46005', 'STATE_LOWER', -2765904::bigint, 'Josephine Garcia', '2025-01-14'::date, 'day', 'elected'),
  ('46005', 'STATE_LOWER', -2765905::bigint, 'Matt Roby', '2025-01-14'::date, 'day', 'elected'),
  ('46006', 'STATE_LOWER', -2765906::bigint, 'Aaron Aylward', '2025-01-14'::date, 'day', 'elected'),
  ('46006', 'STATE_LOWER', -2765907::bigint, 'Tim Czmowski', '2025-02-12'::date, 'day', 'appointed'),
  ('46007', 'STATE_LOWER', -2765908::bigint, 'Mellissa Heermann', '2025-01-14'::date, 'day', 'elected'),
  ('46007', 'STATE_LOWER', -2765909::bigint, 'Roger DeGroot', '2025-01-14'::date, 'day', 'elected'),
  ('46008', 'STATE_LOWER', -2765910::bigint, 'Tim Reisch', '2025-01-14'::date, 'day', 'elected'),
  ('46008', 'STATE_LOWER', -2765911::bigint, 'Tim Walburg', '2025-01-14'::date, 'day', 'elected'),
  ('46009', 'STATE_LOWER', -2765912::bigint, 'Bethany Soye', '2025-01-14'::date, 'day', 'elected'),
  ('46009', 'STATE_LOWER', -2765913::bigint, 'Tesa Schwans', '2025-01-14'::date, 'day', 'elected'),
  ('46010', 'STATE_LOWER', -2765914::bigint, 'Bobbi L. Andera', '2025-01-14'::date, 'day', 'elected'),
  ('46010', 'STATE_LOWER', -2765915::bigint, 'Erin Healy', '2025-01-14'::date, 'day', 'elected'),
  ('46011', 'STATE_LOWER', -2765916::bigint, 'Brian Mulder', '2025-01-14'::date, 'day', 'elected'),
  ('46011', 'STATE_LOWER', -2765917::bigint, 'Keri K. Weems', '2025-01-14'::date, 'day', 'elected'),
  ('46012', 'STATE_LOWER', -2765918::bigint, 'Amber Arlint', '2025-01-14'::date, 'day', 'elected'),
  ('46012', 'STATE_LOWER', -2765919::bigint, 'Greg Jamison', '2025-01-14'::date, 'day', 'elected'),
  ('46013', 'STATE_LOWER', -2765920::bigint, 'Jack R. Kolbeck', '2025-02-05'::date, 'day', 'appointed'),
  ('46013', 'STATE_LOWER', -2765921::bigint, 'John Hughes', '2025-01-14'::date, 'day', 'elected'),
  ('46014', 'STATE_LOWER', -2765922::bigint, 'Taylor Rehfeldt', '2025-01-14'::date, 'day', 'elected'),
  ('46014', 'STATE_LOWER', -2765923::bigint, 'Tony Kayser', '2025-01-14'::date, 'day', 'elected'),
  ('46015', 'STATE_LOWER', -2765924::bigint, 'Erik Muckey', '2025-01-14'::date, 'day', 'elected'),
  ('46015', 'STATE_LOWER', -2765925::bigint, 'Kadyn Wittman', '2025-01-14'::date, 'day', 'elected'),
  ('46016', 'STATE_LOWER', -2765926::bigint, 'John Shubeck', '2025-09-17'::date, 'day', 'appointed'),
  ('46016', 'STATE_LOWER', -2765927::bigint, 'Karla J. Lems', '2025-01-14'::date, 'day', 'elected'),
  ('46017', 'STATE_LOWER', -2765928::bigint, 'Chris Kassin', '2025-01-14'::date, 'day', 'elected'),
  ('46017', 'STATE_LOWER', -2765929::bigint, 'William Shorma', '2025-01-14'::date, 'day', 'elected'),
  ('46018', 'STATE_LOWER', -2765930::bigint, 'Julie Auch', '2025-01-14'::date, 'day', 'elected'),
  ('46018', 'STATE_LOWER', -2765931::bigint, 'Mike Stevens', '2025-01-14'::date, 'day', 'elected'),
  ('46019', 'STATE_LOWER', -2765932::bigint, 'Drew Peterson', '2025-01-14'::date, 'day', 'elected'),
  ('46019', 'STATE_LOWER', -2765933::bigint, 'Jessica Bahmuller', '2025-01-14'::date, 'day', 'elected'),
  ('46020', 'STATE_LOWER', -2765934::bigint, 'Jeff Bathke', '2025-01-14'::date, 'day', 'elected'),
  ('46020', 'STATE_LOWER', -2765935::bigint, 'Kaley Nolz', '2025-01-14'::date, 'day', 'elected'),
  ('46021', 'STATE_LOWER', -2765936::bigint, 'Jim Halverson', '2025-01-14'::date, 'day', 'elected'),
  ('46021', 'STATE_LOWER', -2765937::bigint, 'Marty Overweg', '2025-01-14'::date, 'day', 'elected'),
  ('46022', 'STATE_LOWER', -2765938::bigint, 'Kevin Van Diepen', '2025-01-14'::date, 'day', 'elected'),
  ('46022', 'STATE_LOWER', -2765939::bigint, 'Lana J. Greenfield', '2025-01-14'::date, 'day', 'elected'),
  ('46023', 'STATE_LOWER', -2765940::bigint, 'Scott Moore', '2025-01-14'::date, 'day', 'elected'),
  ('46023', 'STATE_LOWER', -2765941::bigint, 'Spencer Gosch', '2025-01-14'::date, 'day', 'elected'),
  ('46024', 'STATE_LOWER', -2765942::bigint, 'Mike Weisgram', '2025-01-14'::date, 'day', 'elected'),
  ('46024', 'STATE_LOWER', -2765943::bigint, 'Will Mortenson', '2025-01-14'::date, 'day', 'elected'),
  ('46025', 'STATE_LOWER', -2765944::bigint, 'Jon Hansen', '2025-01-14'::date, 'day', 'elected'),
  ('46025', 'STATE_LOWER', -2765945::bigint, 'Leslie J. Heinemann', '2025-01-14'::date, 'day', 'elected'),
  ('46027', 'STATE_LOWER', -2765946::bigint, 'Liz M. May', '2025-01-14'::date, 'day', 'elected'),
  ('46027', 'STATE_LOWER', -2765947::bigint, 'Peri Pourier', '2025-01-14'::date, 'day', 'elected'),
  ('46029', 'STATE_LOWER', -2765948::bigint, 'Kathy Rice', '2025-01-14'::date, 'day', 'elected'),
  ('46029', 'STATE_LOWER', -2765949::bigint, 'Terri Jorgenson', '2025-01-14'::date, 'day', 'elected'),
  ('46030', 'STATE_LOWER', -2765950::bigint, 'Tim Goodwin', '2025-01-14'::date, 'day', 'elected'),
  ('46030', 'STATE_LOWER', -2765951::bigint, 'Trish Ladner', '2025-01-14'::date, 'day', 'elected'),
  ('46031', 'STATE_LOWER', -2765952::bigint, 'Mary J. Fitzgerald', '2025-01-14'::date, 'day', 'elected'),
  ('46031', 'STATE_LOWER', -2765953::bigint, 'Scott Odenbach', '2025-01-14'::date, 'day', 'elected'),
  ('46032', 'STATE_LOWER', -2765954::bigint, 'Nicole Uhre-Balk', '2025-01-14'::date, 'day', 'elected'),
  ('46032', 'STATE_LOWER', -2765955::bigint, 'Steve Duffy', '2025-01-14'::date, 'day', 'elected'),
  ('46033', 'STATE_LOWER', -2765956::bigint, 'Curt Massie', '2025-01-14'::date, 'day', 'elected'),
  ('46033', 'STATE_LOWER', -2765957::bigint, 'Phil Jensen', '2025-01-14'::date, 'day', 'elected'),
  ('46034', 'STATE_LOWER', -2765958::bigint, 'Heather Baxter', '2025-01-14'::date, 'day', 'elected'),
  ('46034', 'STATE_LOWER', -2765959::bigint, 'Mike Derby', '2025-01-14'::date, 'day', 'elected'),
  ('46035', 'STATE_LOWER', -2765960::bigint, 'Tina L. Mulally', '2025-01-14'::date, 'day', 'elected'),
  ('46035', 'STATE_LOWER', -2765961::bigint, 'Tony Randolph', '2025-01-14'::date, 'day', 'elected'),
  ('4626A', 'STATE_LOWER', -2765962::bigint, 'Eric Emery', '2025-01-14'::date, 'day', 'elected'),
  ('4626B', 'STATE_LOWER', -2765963::bigint, 'Rebecca Reimer', '2025-01-14'::date, 'day', 'elected'),
  ('4628A', 'STATE_LOWER', -2765964::bigint, 'Jana Hunt', '2025-01-14'::date, 'day', 'elected'),
  ('4628B', 'STATE_LOWER', -2765965::bigint, 'Travis Ismay', '2025-01-14'::date, 'day', 'elected'),
  ('46001', 'STATE_UPPER', -2765966::bigint, 'Michael H. Rohl', '2025-01-14'::date, 'day', 'elected'),
  ('46002', 'STATE_UPPER', -2765967::bigint, 'Steve Kolbeck', '2025-01-14'::date, 'day', 'elected'),
  ('46003', 'STATE_UPPER', -2765968::bigint, 'Carl Perry', '2025-01-14'::date, 'day', 'elected'),
  ('46004', 'STATE_UPPER', -2765969::bigint, 'Stephanie Sauder', '2025-01-14'::date, 'day', 'elected'),
  ('46005', 'STATE_UPPER', -2765970::bigint, 'Glen Vilhauer', '2025-01-14'::date, 'day', 'elected'),
  ('46006', 'STATE_UPPER', -2765971::bigint, 'Ernie Otten', '2025-01-14'::date, 'day', 'elected'),
  ('46007', 'STATE_UPPER', -2765972::bigint, 'Tim S. Reed', '2025-01-14'::date, 'day', 'elected'),
  ('46008', 'STATE_UPPER', -2765973::bigint, 'Casey Crabtree', '2025-01-14'::date, 'day', 'elected'),
  ('46009', 'STATE_UPPER', -2765974::bigint, 'Joy A. Hohn', '2025-01-14'::date, 'day', 'elected'),
  ('46010', 'STATE_UPPER', -2765975::bigint, 'Liz Larson', '2025-01-14'::date, 'day', 'elected'),
  ('46011', 'STATE_UPPER', -2765976::bigint, 'Chris Karr', '2025-01-14'::date, 'day', 'elected'),
  ('46012', 'STATE_UPPER', -2765977::bigint, 'Arch Beal', '2025-01-14'::date, 'day', 'elected'),
  ('46013', 'STATE_UPPER', -2765978::bigint, 'Sue Peterson', '2025-01-14'::date, 'day', 'elected'),
  ('46014', 'STATE_UPPER', -2765979::bigint, 'Larry P. Zikmund', '2025-01-15'::date, 'day', 'elected'),
  ('46015', 'STATE_UPPER', -2765980::bigint, 'Jamie Smith', '2025-01-14'::date, 'day', 'elected'),
  ('46016', 'STATE_UPPER', -2765981::bigint, 'Kevin D. Jensen', '2025-01-14'::date, 'day', 'elected'),
  ('46017', 'STATE_UPPER', -2765982::bigint, 'Sydney Davis', '2025-01-15'::date, 'day', 'elected'),
  ('46018', 'STATE_UPPER', -2765983::bigint, 'Lauren Nelson', '2025-01-14'::date, 'day', 'elected'),
  ('46019', 'STATE_UPPER', -2765984::bigint, 'Kyle Schoenfish', '2025-01-14'::date, 'day', 'elected'),
  ('46020', 'STATE_UPPER', -2765985::bigint, 'Paul R. Miskimins', '2025-01-14'::date, 'day', 'elected'),
  ('46021', 'STATE_UPPER', -2765986::bigint, 'Mykala Voita', '2025-01-14'::date, 'day', 'elected'),
  ('46022', 'STATE_UPPER', -2765987::bigint, 'Brandon Wipf', '2025-07-10'::date, 'day', 'appointed'),
  ('46023', 'STATE_UPPER', -2765988::bigint, 'Mark Lapka', '2025-01-14'::date, 'day', 'elected'),
  ('46024', 'STATE_UPPER', -2765989::bigint, 'Jim Mehlhaff', '2025-01-14'::date, 'day', 'elected'),
  ('46025', 'STATE_UPPER', -2765990::bigint, 'Tom Pischke', '2025-01-14'::date, 'day', 'elected'),
  ('46026', 'STATE_UPPER', -2765991::bigint, 'Tamara R. Grove', '2025-01-14'::date, 'day', 'elected'),
  ('46027', 'STATE_UPPER', -2765992::bigint, 'Red Dawn Foster', '2025-01-14'::date, 'day', 'elected'),
  ('46028', 'STATE_UPPER', -2765993::bigint, 'Sam S. Marty', '2025-01-14'::date, 'day', 'elected'),
  ('46029', 'STATE_UPPER', -2765994::bigint, 'John Carley', '2025-01-14'::date, 'day', 'elected'),
  ('46030', 'STATE_UPPER', -2765995::bigint, 'Amber Hulse', '2025-01-14'::date, 'day', 'elected'),
  ('46031', 'STATE_UPPER', -2765996::bigint, 'Randy Deibert', '2025-01-14'::date, 'day', 'elected'),
  ('46032', 'STATE_UPPER', -2765997::bigint, 'Helene Duhamel', '2025-01-14'::date, 'day', 'elected'),
  ('46033', 'STATE_UPPER', -2765998::bigint, 'Curt Voight', '2025-01-14'::date, 'day', 'elected'),
  ('46034', 'STATE_UPPER', -2765999::bigint, 'Taffy Howard', '2025-01-14'::date, 'day', 'elected'),
  ('46035', 'STATE_UPPER', -2766000::bigint, 'Greg Blanc', '2025-01-14'::date, 'day', 'elected');

WITH office_slots AS (
  SELECT o.id AS office_id, d.geo_id, d.district_type::text AS dt,
         row_number() OVER (PARTITION BY o.district_id ORDER BY o.id) AS slot
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
),
member_slots AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.geo_id, t.district_type ORDER BY t.sort_key) AS slot
  FROM sd_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, ms.term_start, NULL, ms.start_precision, ms.how_started, 'South Dakota Legislature, 101st Session (2026) member roster, https://sdlegislature.gov/api/SessionMembers/Session/71 — 105 members, 0 InactiveDate, read 2026-09-28. Term starts are DATED from the body’s own record: the oath lists in the Journal of the House and Journal of the Senate, 100th Session, 1st Legislative Day, 2025-01-14 (docs 274999 and 274997), plus the 2nd Legislative Day journals (docs 275000 and 274998) for Pourier, Davis and Zikmund, and the Office of the Governor of South Dakota’s own appointment announcements for the five Governor’s appointments (SD-2) (CC_0164, SD-2)'
FROM member_slots ms
JOIN office_slots os
  ON os.geo_id = ms.geo_id AND os.dt = ms.district_type AND os.slot = ms.slot
JOIN essentials.politicians p ON p.external_id = ms.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people    int;
  v_terms     int;
  v_seated_s  int;
  v_seated_h  int;
  v_unknown   int;
  v_notday    int;
  v_appointed int;
  v_elected   int;
  v_noninc    int;
  v_twoseat   int;
  v_dupe      int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2766000 AND -2765896;
  IF v_people <> 105 THEN
    RAISE EXCEPTION 'SD-2 occupancy gate: expected 105 people in the reserved band, got %', v_people;
  END IF;

  -- 🔴 Count och.politician_id, NOT *: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated_s
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'sd' AND d.district_type::text = 'STATE_UPPER';
  SELECT count(och.politician_id) INTO v_seated_h
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'sd' AND d.district_type::text = 'STATE_LOWER';
  IF v_seated_s <> 35 OR v_seated_h <> 70 THEN
    RAISE EXCEPTION 'SD-2 occupancy gate: expected 35 Senate and 70 House seated, found % and %', v_seated_s, v_seated_h;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_terms <> 105 THEN
    RAISE EXCEPTION 'SD-2 occupancy gate: expected 105 SD legislative terms, found %', v_terms;
  END IF;

  -- 🟢 Every term dated to the day. This is the claim the wave is proudest of, so it is asserted.
  SELECT count(*) INTO v_notday
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND (ot.start_precision <> 'day' OR ot.term_start IS NULL);
  IF v_notday <> 0 THEN
    RAISE EXCEPTION 'SD-2 occupancy gate: % SD legislative term(s) are not day-precision with a real date', v_notday;
  END IF;

  SELECT count(*) INTO v_appointed
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND ot.how_started = 'appointed';
  SELECT count(*) INTO v_elected
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND ot.how_started = 'elected';
  IF v_appointed <> 5 OR v_elected <> 100 THEN
    RAISE EXCEPTION 'SD-2 occupancy gate: expected 5 appointed and 100 elected, found % and %', v_appointed, v_elected;
  END IF;

  -- 🔴 Every seated person must carry is_incumbent, or address search hides them.
  SELECT count(*) INTO v_noninc
    FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2766000 AND -2765896
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'SD-2 occupancy gate: % SD legislator(s) are not is_incumbent/is_active', v_noninc;
  END IF;

  -- 🔴 The multi-member shape, re-asserted on OCCUPANCY rather than on offices: each whole House
  -- district must hold two DISTINCT people. Two terms on one person would pass a count of 70.
  SELECT count(*) INTO v_twoseat
    FROM essentials.districts d
   WHERE lower(d.state) = 'sd' AND d.district_type::text = 'STATE_LOWER'
     AND d.geo_id NOT IN ('4626A', '4626B', '4628A', '4628B')
     AND (SELECT count(DISTINCT ot.politician_id)
            FROM essentials.offices o
            JOIN essentials.office_terms ot ON ot.office_id = o.id
           WHERE o.district_id = d.id) <> 2;
  IF v_twoseat <> 0 THEN
    RAISE EXCEPTION 'SD-2 occupancy gate: % whole House district(s) do not hold 2 DISTINCT people', v_twoseat;
  END IF;

  -- No person holds two SD legislative seats.
  SELECT count(*) INTO v_dupe FROM (
    SELECT ot.politician_id
      FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'sd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'SD-2 occupancy gate: % person(s) hold more than one SD legislative seat', v_dupe;
  END IF;

  RAISE NOTICE 'SD-2 occupancy gate PASSED: 105 people, 105 terms, 35 Senate + 70 House seated, 0 vacant, ALL day-precision, 100 elected + 5 appointed, 33 whole House districts hold 2 distinct people each.';
END $$;

COMMIT;
