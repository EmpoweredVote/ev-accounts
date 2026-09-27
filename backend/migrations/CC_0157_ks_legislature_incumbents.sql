-- CC_0157_ks_legislature_incumbents.sql
-- Knight Foundation program, wave KS-2 (occupancy half). Slot RESERVED from the allocator.
-- Apply immediately after CC_0156, which creates the 165 offices this migration seats.
--
-- Seats all 165 members of the Kansas Legislature: 125 Representatives and 40 Senators.
-- Creates 161 people, reuses 4, and writes 165 office_terms rows.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ARRIVAL DATES ARE SOURCED, NOT COMPUTED -- AND KANSAS IS THE BEST-DATED SLICE IN THIS PROGRAM.
-- 163 of 165 are DAY precision and 2 are MONTH; none are year and none unknown.
--
-- The 157 members still holding the seat they were sworn into carry 2025-01-13, and that date
-- is STATED rather than derived. Journal of the House and Journal of the Senate, FIRST DAY, Monday
-- January 13 2025, each quote the Secretary of State's certification of December 2 2024 and then
-- record the oath -- "administered to them by Chief Justice Marla Luckert" for the House, and
-- Justice Dan Biles for the Senate, whose jurat reads "before me this 13th day of January, 2025".
-- The certification's phrase "a two-year term beginning on the second Monday of January" is NOT
-- what is used: three states in this program have already paid for a computed oath date, so the
-- date comes from the Journal's own header and jurat.
--
-- The 8 interim arrivals are individually certified in the House Journal, each naming its own
-- appointment date, its predecessor and the officer who administered the oath:
--   House  85 Steven Brunk        2025-06-24  (resignation of Patrick Penn)
--   House  70 Gregory Wilson      2025-07-30  (resignation of Scott Hill)
--   House  33 Carolyn Caiharr     2025-09-05  (resignation of Michael Thompson)
--   House   5 Courtney Sappington 2025-10-13  (resignation of Carrie Barth)
--   House  86 Abi Boatman         2026-01-12  (resignation of Silas Miller)
--   House 121 Mike Storm          2026-03-16  (DEATH of Rep. John Resman)
--   Senate 24 Scott Hill          2025-06     (resignation of J.R. Claeys)      <- month
--   Senate 25 Silas Miller        2025-12     (resignation of Mary Ware)        <- month
-- In every House case the appointment date and the oath date coincide. THAT IS NOT TREATED AS A
-- RULE -- ND-3 measured gaps of 6, 7, 7 and 20 days -- the Journal simply states both.
--
-- THE TWO SENATE ARRIVALS ARE MONTH PRECISION BECAUSE NO DAY EXISTS IN ANY PUBLISHED RECORD, AND
-- THAT WAS ESTABLISHED UNDER CONTROL. All 54 Senate journal days of the 2026 session were swept:
-- the phrase "appointed by the Governor" appears on exactly three and all three are BILL TEXT about
-- boards and commissions. The identical sweep found five real records in the House, so this is the
-- Senate not publishing them. The Senate's 2026 First Day gives Hill and Miller only a CEREMONIAL
-- oath, which dates a ceremony and not an arrival -- KY-3's re-swearing trap. And a contemporaneous
-- report of Hill's selection says "As of June 18, Hill does not know the specific date and place of
-- his swear-in", so even the appointee did not know: the "June 26" figure elsewhere is an
-- anticipation, not a record. What IS sourced is the precinct convention: 2025-06-16 for Hill and
-- 2025-12-04 for Miller.
--
-- SIX NAME COLLISIONS WITH ACTIVE ROWS, SPLITTING TWO WAYS. Checked with the duplicate guard's OWN
-- predicate (active rows, lower(btrim()) on the first_name/last_name PAIR), with the pair taken from
-- ONE source -- the first-party CSV -- never mixed with the member page or the Journal.
--   SAME PERSON, reused, NOT inserted (all four are sitting senators running for higher office,
--   which the guard's own message calls "the normal case, not a different person"):
--     Senate  7 Ethan Corson     candidate for Governor of Kansas (D)
--     Senate  8 Cindy Holscher   candidate for Governor of Kansas (D)
--     Senate 16 Ty Masterson     candidate for Governor of Kansas (R)
--     Senate 19 Patrick Schmidt  candidate for U.S. Senate, Kansas (D)
--   DIFFERENT PERSON, guard lifted for those two rows ONLY, never for the migration:
--     House 120 Adam Smith    -- existing row is the U.S. Representative for WASHINGTON District 9
--     Senate 10 Mike Thompson -- existing row is the U.S. Representative for CALIFORNIA District 4
--
-- THERE ARE THREE MIKE THOMPSONS AND TWO SAT IN THIS LEGISLATURE AT ONCE: the California
-- congressman; Kansas Senate 10, seated here; and Michael Thompson of Kansas House 33, sworn the
-- SAME DAY in the other chamber and since resigned. Two men of one name sworn into different
-- chambers on one day is proof on its face that they are different people. The House one is
-- published as "Mike Thompson" in the sworn list but "Michael Thompson" in the resignation record,
-- so the guard's exact-pair test would not even have matched him.
--
-- external_id block -2765000..-2764840 was measured EMPTY on 2026-09-27; the nearest occupied id
-- below is -2770001 and the nearest above is -2763000 (Kentucky's block). An external_id collision
-- seats the WRONG person silently.
--
-- Party is NOT written. Party is antipartisan and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 1. The 159 people whose names collide with nobody ─────────────────────────

CREATE TEMP TABLE ks_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ks_new_people(external_id, full_name, first_name, last_name) VALUES
  (-2765000, 'John Alcala', 'John', 'Alcala'),
  (-2764999, 'Mike Amyx', 'Mike', 'Amyx'),
  (-2764998, 'Avery Anderson', 'Avery', 'Anderson'),
  (-2764997, 'Francis Awerkamp', 'Francis', 'Awerkamp'),
  (-2764996, 'Barbara Ballard', 'Barbara', 'Ballard'),
  (-2764995, 'Bradley Barrett', 'Bradley', 'Barrett'),
  (-2764994, 'Brian Bergkamp', 'Brian', 'Bergkamp'),
  (-2764993, 'Emil Bergquist', 'Emil', 'Bergquist'),
  (-2764992, 'Doug Blex', 'Doug', 'Blex'),
  (-2764991, 'Lewis "Bill" Bloom', 'Lewis', 'Bloom'),
  (-2764990, 'Abi Boatman', 'Abi', 'Boatman'),
  (-2764989, 'Lauren Bohi', 'Lauren', 'Bohi'),
  (-2764988, 'Jesse Borjon', 'Jesse', 'Borjon'),
  (-2764987, 'Sherri Brantley', 'Sherri', 'Brantley'),
  (-2764986, 'Wanda Brownlee Paige', 'Wanda', 'Brownlee Paige'),
  (-2764985, 'Steve Brunk', 'Steve', 'Brunk'),
  (-2764984, 'Ron Bryce', 'Ron', 'Bryce'),
  (-2764983, 'David Buehler', 'David', 'Buehler'),
  (-2764982, 'Nathan Butler', 'Nathan', 'Butler'),
  (-2764981, 'Carolyn Caiharr', 'Carolyn', 'Caiharr'),
  (-2764980, 'Sydney Carlin', 'Sydney', 'Carlin'),
  (-2764979, 'John Carmichael', 'John', 'Carmichael'),
  (-2764978, 'Blake Carpenter', 'Blake', 'Carpenter'),
  (-2764977, 'Will Carpenter', 'Will', 'Carpenter'),
  (-2764976, 'Ford Carr', 'Ford', 'Carr'),
  (-2764975, 'Shawn Chauncey', 'Shawn', 'Chauncey'),
  (-2764974, 'Kenneth Collins', 'Kenneth', 'Collins'),
  (-2764973, 'Ken Corbet', 'Ken', 'Corbet'),
  (-2764972, 'Chris Croft', 'Chris', 'Croft'),
  (-2764971, 'Pam Curtis', 'Pam', 'Curtis'),
  (-2764970, 'Leo Delperdang', 'Leo', 'Delperdang'),
  (-2764969, 'Duane Droge', 'Duane', 'Droge'),
  (-2764968, 'Ronald Ellis', 'Ronald', 'Ellis'),
  (-2764967, 'Charlotte Esau', 'Charlotte', 'Esau'),
  (-2764966, 'Robyn R. Essex', 'Robyn', 'Essex'),
  (-2764965, 'Susan Estes', 'Susan', 'Estes'),
  (-2764964, 'Brett Fairchild', 'Brett', 'Fairchild'),
  (-2764963, 'Linda Featherston', 'Linda', 'Featherston'),
  (-2764962, 'Shannon Francis', 'Shannon', 'Francis'),
  (-2764961, 'Fred Gardner', 'Fred', 'Gardner'),
  (-2764960, 'Dan Goddard', 'Dan', 'Goddard'),
  (-2764959, 'Jason W. Goetz', 'Jason', 'Goetz'),
  (-2764958, 'Kirk Haskins', 'Kirk', 'Haskins'),
  (-2764957, 'Daniel Hawkins', 'Daniel', 'Hawkins'),
  (-2764956, 'Henry Helgerson', 'Henry', 'Helgerson'),
  (-2764955, 'Dale Helwig', 'Dale', 'Helwig'),
  (-2764954, 'Kyle Hoffman', 'Kyle', 'Hoffman'),
  (-2764953, 'Nick Hoheisel', 'Nick', 'Hoheisel'),
  (-2764952, 'Steven K. Howe', 'Steven', 'Howe'),
  (-2764951, 'Leah Howell', 'Leah', 'Howell'),
  (-2764950, 'Cyndi Howerton', 'Cyndi', 'Howerton'),
  (-2764949, 'Jo Ella Hoye', 'Jo Ella', 'Hoye'),
  (-2764948, 'Steve Huebert', 'Steve', 'Huebert'),
  (-2764947, 'Susan Humphries', 'Susan', 'Humphries'),
  (-2764946, 'Rick James', 'Rick', 'James'),
  (-2764945, 'Timothy Johnson', 'Timothy', 'Johnson'),
  (-2764944, 'Tom Kessler', 'Tom', 'Kessler'),
  (-2764943, 'Mike King', 'Mike', 'King'),
  (-2764942, 'Bob Lewis', 'Bob', 'Lewis'),
  (-2764941, 'Marty Long', 'Marty', 'Long'),
  (-2764940, 'Angela Martinez', 'Angela', 'Martinez'),
  (-2764939, 'Nikki McDonald', 'Nikki', 'McDonald'),
  (-2764938, 'Kyle McNorton', 'Kyle', 'McNorton'),
  (-2764937, 'Lynn Melton', 'Lynn', 'Melton'),
  (-2764936, 'Heather Meyer', 'Heather', 'Meyer'),
  (-2764935, 'Jim Minnix', 'Jim', 'Minnix'),
  (-2764934, 'Lisa M. Moser', 'Lisa', 'Moser'),
  (-2764933, 'Brooklynne Mosley', 'Brooklynne', 'Mosley'),
  (-2764932, 'Lance W. Neelly', 'Lance', 'Neelly'),
  (-2764931, 'Cindy Neighbor', 'Cindy', 'Neighbor'),
  (-2764930, 'KC Ohaebosim', 'KC', 'Ohaebosim'),
  (-2764929, 'Melissa Oropeza', 'Melissa', 'Oropeza'),
  (-2764928, 'Dan Osman', 'Dan', 'Osman'),
  (-2764927, 'Jarrod Ousley', 'Jarrod', 'Ousley'),
  (-2764926, 'Sandy Pickert', 'Sandy', 'Pickert'),
  (-2764925, 'Lon Pishny', 'Lon', 'Pishny'),
  (-2764924, 'Samantha Poetter Parshall', 'Samantha', 'Poetter Parshall'),
  (-2764923, 'Mari-Lynn Poskin', 'Mari-Lynn', 'Poskin'),
  (-2764922, 'Pat Proctor', 'Pat', 'Proctor'),
  (-2764921, 'Ken Rahjes', 'Ken', 'Rahjes'),
  (-2764920, 'Allen Reavis', 'Allen', 'Reavis'),
  (-2764919, 'Bill Rhiley', 'Bill', 'Rhiley'),
  (-2764918, 'Angelina Roeser', 'Angelina', 'Roeser'),
  (-2764917, 'Webster T. Roth', 'Webster', 'Roth'),
  (-2764916, 'Louis Ruiz', 'Louis', 'Ruiz'),
  (-2764915, 'Susan Ruiz', 'Susan', 'Ruiz'),
  (-2764914, 'Clarke Sanders', 'Clarke', 'Sanders'),
  (-2764913, 'Courtney Sappington', 'Courtney', 'Sappington'),
  (-2764912, 'Tom Sawyer', 'Tom', 'Sawyer'),
  (-2764911, 'Stephanie Sawyer Clayton', 'Stephanie', 'Sawyer Clayton'),
  (-2764910, 'Tobias Schlingensiepen', 'Tobias', 'Schlingensiepen'),
  (-2764909, 'Rebecca Schmoe', 'Rebecca', 'Schmoe'),
  (-2764908, 'Mark Schreiber', 'Mark', 'Schreiber'),
  (-2764907, 'Kevin Schwertfeger', 'Kevin', 'Schwertfeger'),
  (-2764906, 'Joe Seiwert', 'Joe', 'Seiwert'),
  (-2764905, 'Alexis Simmons', 'Alexis', 'Simmons'),
  (-2764903, 'Chuck Smith', 'Chuck', 'Smith'),
  (-2764902, 'Megan Steele', 'Megan', 'Steele'),
  (-2764901, 'Angela Stiens', 'Angela', 'Stiens'),
  (-2764900, 'Jerry Stogsdill', 'Jerry', 'Stogsdill'),
  (-2764899, 'Mike Storm', 'Mike', 'Storm'),
  (-2764898, 'Bill Sutton', 'Bill', 'Sutton'),
  (-2764897, 'Kyler Sweely', 'Kyler', 'Sweely'),
  (-2764896, 'Sean Tarwater', 'Sean', 'Tarwater'),
  (-2764895, 'Adam Turk', 'Adam', 'Turk'),
  (-2764894, 'Carl Turner', 'Carl', 'Turner'),
  (-2764893, 'Chip VanHouden', 'Charles', 'VanHouden'),
  (-2764892, 'Lindsay Vaughn', 'Lindsay', 'Vaughn'),
  (-2764891, 'Paul Waggoner', 'Paul', 'Waggoner'),
  (-2764890, 'Jill Ward', 'Jill', 'Ward'),
  (-2764889, 'Barb Wasinger', 'Barb', 'Wasinger'),
  (-2764888, 'Troy Waymaster', 'Troy', 'Waymaster'),
  (-2764887, 'Virgil Weigel', 'Virgil', 'Weigel'),
  (-2764886, 'Gary White', 'Gary', 'White'),
  (-2764885, 'Suzanne Wikle', 'Suzanne', 'Wikle'),
  (-2764884, 'Rick Wilborn', 'Rick', 'Wilborn'),
  (-2764883, 'Sean Willcott', 'Sean', 'Willcott'),
  (-2764882, 'Laura Williams', 'Laura', 'Williams'),
  (-2764881, 'Kristey Williams', 'Kristey', 'Williams'),
  (-2764880, 'Greg Wilson', 'Greg', 'Wilson'),
  (-2764879, 'Valdenia Winn', 'Valdenia', 'Winn'),
  (-2764878, 'Dawn Wolf', 'Dawn', 'Wolf'),
  (-2764877, 'Brandon Woodard', 'Brandon', 'Woodard'),
  (-2764876, 'Rui Xu', 'Rui', 'Xu'),
  (-2764875, 'Larry Alley', 'Larry', 'Alley'),
  (-2764874, 'Mike Argabright', 'Mike', 'Argabright'),
  (-2764873, 'Rick Billinger', 'Rick', 'Billinger'),
  (-2764872, 'Chase Blasi', 'Chase', 'Blasi'),
  (-2764871, 'Tory Marie Blew', 'Tory Marie', 'Blew'),
  (-2764870, 'Elaine Bowers', 'Elaine', 'Bowers'),
  (-2764869, 'Craig Bowser', 'Craig', 'Bowser'),
  (-2764868, 'Joseph Claeys', 'Joseph', 'Claeys'),
  (-2764867, 'William Clifford', 'William', 'Clifford'),
  (-2764866, 'Brenda Dietrich', 'Brenda', 'Dietrich'),
  (-2764865, 'Renee Erickson', 'Renee', 'Erickson'),
  (-2764864, 'Michael Fagg', 'Michael', 'Fagg'),
  (-2764863, 'Oletha Faust Goudeau', 'Oletha', 'Faust Goudeau'),
  (-2764862, 'Marci Francisco', 'Marci', 'Francisco'),
  (-2764861, 'Beverly Gossage', 'Beverly', 'Gossage'),
  (-2764860, 'David Haley', 'David', 'Haley'),
  (-2764859, 'Scott Hill', 'Scott', 'Hill'),
  (-2764858, 'Jeff Klemp', 'Jeff', 'Klemp'),
  (-2764857, 'Rick Kloos', 'Rick', 'Kloos'),
  (-2764856, 'Silas Miller', 'Silas', 'Miller'),
  (-2764855, 'Michael Murphy', 'Michael', 'Murphy'),
  (-2764854, 'Stephen Owens', 'Stephen', 'Owens'),
  (-2764853, 'Virgil Peck', 'Virgil', 'Peck'),
  (-2764852, 'Mike Petersen', 'Mike', 'Petersen'),
  (-2764851, 'Pat Pettey', 'Pat', 'Pettey'),
  (-2764850, 'TJ Rose', 'TJ', 'Rose'),
  (-2764849, 'Ronald Ryckman', 'Ronald', 'Ryckman'),
  (-2764848, 'Tim Shallenburger', 'Tim', 'Shallenburger'),
  (-2764847, 'Doug Shane', 'Doug', 'Shane'),
  (-2764846, 'Brad Starnes', 'Brad', 'Starnes'),
  (-2764845, 'Dinah Sykes', 'Dinah', 'Sykes'),
  (-2764844, 'Adam Thomas', 'Adam', 'Thomas'),
  (-2764842, 'Kenny Titus', 'Kenny', 'Titus'),
  (-2764841, 'Caryn Tyson', 'Caryn', 'Tyson'),
  (-2764840, 'Kellie Warren', 'Kellie', 'Warren');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Kansas Legislature. Roster from the Legislature''s own first-party CSV at kslegislature.gov/b2025_26/{house/representatives,senate/senators}/csv/ (125 and 40 rows, District, Fullname, Party and County as columns), with every one of the 165 individual member pages swept and each confirmed to name the same member at the same seat. Arrival dates from the chambers'' own Journals: Journal of the House and Journal of the Senate, FIRST DAY, Monday January 13 2025, which quote the Secretary of State''s certification of December 2 2024 and record the oath administered by Chief Justice Marla Luckert and Justice Dan Biles respectively; interim appointments from the House Journal FIRST DAY January 12 2026 and the House Journal of March 16 2026, each certifying its own appointment and oath date. The Senate publishes no interim-oath record anywhere in its 54 journal days of the 2026 session, so its two appointees carry month precision. Read 2026-09-27 (KS-2) (CC_0157, KS-2)', true, true
FROM ks_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 2 namesakes — guard lifted for this statement only ──────────────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE ks_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ks_namesake_people(external_id, full_name, first_name, last_name) VALUES
  (-2764904, 'Adam Smith', 'Adam', 'Smith'),
  (-2764843, 'Mike Thompson', 'Mike', 'Thompson');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Kansas Legislature. Roster from the Legislature''s own first-party CSV at kslegislature.gov/b2025_26/{house/representatives,senate/senators}/csv/ (125 and 40 rows, District, Fullname, Party and County as columns), with every one of the 165 individual member pages swept and each confirmed to name the same member at the same seat. Arrival dates from the chambers'' own Journals: Journal of the House and Journal of the Senate, FIRST DAY, Monday January 13 2025, which quote the Secretary of State''s certification of December 2 2024 and record the oath administered by Chief Justice Marla Luckert and Justice Dan Biles respectively; interim appointments from the House Journal FIRST DAY January 12 2026 and the House Journal of March 16 2026, each certifying its own appointment and oath date. The Senate publishes no interim-oath record anywhere in its 54 journal days of the 2026 session, so its two appointees carry month precision. Read 2026-09-27 (KS-2) (CC_0157, KS-2)', true, true
FROM ks_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

RESET essentials.allow_duplicate_name;

-- ─── 3. The 4 who already exist — UPDATE, never INSERT ────────────────────
--
-- is_incumbent is set EXPLICITLY here for the same reason it is on every insert: it is a cached
-- flag the incumbents-only reads filter on, and these four carry is_incumbent = false today
-- because they were created as 2026 candidates. Seating them without this leaves them hidden
-- from address search.

UPDATE essentials.politicians SET is_incumbent = true
 WHERE id IN (
   '48d821c9-86ef-4d9d-978f-17bb59ac7fd3'::uuid,
   'e80123eb-87f0-4e90-a661-29da53de972a'::uuid,
   '7dbc13d8-f39d-4783-9f84-83fb31053a8c'::uuid,
   'b21b5e5e-3359-4692-a60d-47d459bbb198'::uuid
 ) AND is_incumbent IS DISTINCT FROM true;

-- ─── 4. The 165 terms ─────────────────────────────────────────────────────────

CREATE TEMP TABLE ks_terms(geo_id text, district_type text, external_id bigint,
                           term_start date, start_precision text, how_started text)
  ON COMMIT DROP;

INSERT INTO ks_terms(geo_id, district_type, external_id, term_start, start_precision, how_started) VALUES
  ('20057', 'STATE_LOWER', -2765000, DATE '2025-01-13', 'day', 'elected'),
  ('20045', 'STATE_LOWER', -2764999, DATE '2025-01-13', 'day', 'elected'),
  ('20072', 'STATE_LOWER', -2764998, DATE '2025-01-13', 'day', 'elected'),
  ('20061', 'STATE_LOWER', -2764997, DATE '2025-01-13', 'day', 'elected'),
  ('20044', 'STATE_LOWER', -2764996, DATE '2025-01-13', 'day', 'elected'),
  ('20076', 'STATE_LOWER', -2764995, DATE '2025-01-13', 'day', 'elected'),
  ('20093', 'STATE_LOWER', -2764994, DATE '2025-01-13', 'day', 'elected'),
  ('20091', 'STATE_LOWER', -2764993, DATE '2025-01-13', 'day', 'elected'),
  ('20012', 'STATE_LOWER', -2764992, DATE '2025-01-13', 'day', 'elected'),
  ('20064', 'STATE_LOWER', -2764991, DATE '2025-01-13', 'day', 'elected'),
  ('20086', 'STATE_LOWER', -2764990, DATE '2026-01-12', 'day', 'appointed'),
  ('20015', 'STATE_LOWER', -2764989, DATE '2025-01-13', 'day', 'elected'),
  ('20052', 'STATE_LOWER', -2764988, DATE '2025-01-13', 'day', 'elected'),
  ('20112', 'STATE_LOWER', -2764987, DATE '2025-01-13', 'day', 'elected'),
  ('20035', 'STATE_LOWER', -2764986, DATE '2025-01-13', 'day', 'elected'),
  ('20085', 'STATE_LOWER', -2764985, DATE '2025-06-24', 'day', 'appointed'),
  ('20011', 'STATE_LOWER', -2764984, DATE '2025-01-13', 'day', 'elected'),
  ('20040', 'STATE_LOWER', -2764983, DATE '2025-01-13', 'day', 'elected'),
  ('20068', 'STATE_LOWER', -2764982, DATE '2025-01-13', 'day', 'elected'),
  ('20033', 'STATE_LOWER', -2764981, DATE '2025-09-05', 'day', 'appointed'),
  ('20066', 'STATE_LOWER', -2764980, DATE '2025-01-13', 'day', 'elected'),
  ('20092', 'STATE_LOWER', -2764979, DATE '2025-01-13', 'day', 'elected'),
  ('20081', 'STATE_LOWER', -2764978, DATE '2025-01-13', 'day', 'elected'),
  ('20075', 'STATE_LOWER', -2764977, DATE '2025-01-13', 'day', 'elected'),
  ('20084', 'STATE_LOWER', -2764976, DATE '2025-01-13', 'day', 'elected'),
  ('20065', 'STATE_LOWER', -2764975, DATE '2025-01-13', 'day', 'elected'),
  ('20002', 'STATE_LOWER', -2764974, DATE '2025-01-13', 'day', 'elected'),
  ('20054', 'STATE_LOWER', -2764973, DATE '2025-01-13', 'day', 'elected'),
  ('20008', 'STATE_LOWER', -2764972, DATE '2025-01-13', 'day', 'elected'),
  ('20032', 'STATE_LOWER', -2764971, DATE '2025-01-13', 'day', 'elected'),
  ('20094', 'STATE_LOWER', -2764970, DATE '2025-01-13', 'day', 'elected'),
  ('20013', 'STATE_LOWER', -2764969, DATE '2025-01-13', 'day', 'elected'),
  ('20047', 'STATE_LOWER', -2764968, DATE '2025-01-13', 'day', 'elected'),
  ('20014', 'STATE_LOWER', -2764967, DATE '2025-01-13', 'day', 'elected'),
  ('20078', 'STATE_LOWER', -2764966, DATE '2025-01-13', 'day', 'elected'),
  ('20087', 'STATE_LOWER', -2764965, DATE '2025-01-13', 'day', 'elected'),
  ('20113', 'STATE_LOWER', -2764964, DATE '2025-01-13', 'day', 'elected'),
  ('20016', 'STATE_LOWER', -2764963, DATE '2025-01-13', 'day', 'elected'),
  ('20125', 'STATE_LOWER', -2764962, DATE '2025-01-13', 'day', 'elected'),
  ('20009', 'STATE_LOWER', -2764961, DATE '2025-01-13', 'day', 'elected'),
  ('20007', 'STATE_LOWER', -2764960, DATE '2025-01-13', 'day', 'elected'),
  ('20119', 'STATE_LOWER', -2764959, DATE '2025-01-13', 'day', 'elected'),
  ('20053', 'STATE_LOWER', -2764958, DATE '2025-01-13', 'day', 'elected'),
  ('20100', 'STATE_LOWER', -2764957, DATE '2025-01-13', 'day', 'elected'),
  ('20083', 'STATE_LOWER', -2764956, DATE '2025-01-13', 'day', 'elected'),
  ('20001', 'STATE_LOWER', -2764955, DATE '2025-01-13', 'day', 'elected'),
  ('20116', 'STATE_LOWER', -2764954, DATE '2025-01-13', 'day', 'elected'),
  ('20097', 'STATE_LOWER', -2764953, DATE '2025-01-13', 'day', 'elected'),
  ('20071', 'STATE_LOWER', -2764952, DATE '2025-01-13', 'day', 'elected'),
  ('20082', 'STATE_LOWER', -2764951, DATE '2025-01-13', 'day', 'elected'),
  ('20098', 'STATE_LOWER', -2764950, DATE '2025-01-13', 'day', 'elected'),
  ('20017', 'STATE_LOWER', -2764949, DATE '2025-01-13', 'day', 'elected'),
  ('20090', 'STATE_LOWER', -2764948, DATE '2025-01-13', 'day', 'elected'),
  ('20099', 'STATE_LOWER', -2764947, DATE '2025-01-13', 'day', 'elected'),
  ('20004', 'STATE_LOWER', -2764946, DATE '2025-01-13', 'day', 'elected'),
  ('20038', 'STATE_LOWER', -2764945, DATE '2025-01-13', 'day', 'elected'),
  ('20096', 'STATE_LOWER', -2764944, DATE '2025-01-13', 'day', 'elected'),
  ('20074', 'STATE_LOWER', -2764943, DATE '2025-01-13', 'day', 'elected'),
  ('20123', 'STATE_LOWER', -2764942, DATE '2025-01-13', 'day', 'elected'),
  ('20124', 'STATE_LOWER', -2764941, DATE '2025-01-13', 'day', 'elected'),
  ('20103', 'STATE_LOWER', -2764940, DATE '2025-01-13', 'day', 'elected'),
  ('20049', 'STATE_LOWER', -2764939, DATE '2025-01-13', 'day', 'elected'),
  ('20050', 'STATE_LOWER', -2764938, DATE '2025-01-13', 'day', 'elected'),
  ('20036', 'STATE_LOWER', -2764937, DATE '2025-01-13', 'day', 'elected'),
  ('20029', 'STATE_LOWER', -2764936, DATE '2025-01-13', 'day', 'elected'),
  ('20118', 'STATE_LOWER', -2764935, DATE '2025-01-13', 'day', 'elected'),
  ('20106', 'STATE_LOWER', -2764934, DATE '2025-01-13', 'day', 'elected'),
  ('20046', 'STATE_LOWER', -2764933, DATE '2025-01-13', 'day', 'elected'),
  ('20042', 'STATE_LOWER', -2764932, DATE '2025-01-13', 'day', 'elected'),
  ('20018', 'STATE_LOWER', -2764931, DATE '2025-01-13', 'day', 'elected'),
  ('20089', 'STATE_LOWER', -2764930, DATE '2025-01-13', 'day', 'elected'),
  ('20037', 'STATE_LOWER', -2764929, DATE '2025-01-13', 'day', 'elected'),
  ('20048', 'STATE_LOWER', -2764928, DATE '2025-01-13', 'day', 'elected'),
  ('20024', 'STATE_LOWER', -2764927, DATE '2025-01-13', 'day', 'elected'),
  ('20088', 'STATE_LOWER', -2764926, DATE '2025-01-13', 'day', 'elected'),
  ('20122', 'STATE_LOWER', -2764925, DATE '2025-01-13', 'day', 'elected'),
  ('20006', 'STATE_LOWER', -2764924, DATE '2025-01-13', 'day', 'elected'),
  ('20020', 'STATE_LOWER', -2764923, DATE '2025-01-13', 'day', 'elected'),
  ('20041', 'STATE_LOWER', -2764922, DATE '2025-01-13', 'day', 'elected'),
  ('20110', 'STATE_LOWER', -2764921, DATE '2025-01-13', 'day', 'elected'),
  ('20063', 'STATE_LOWER', -2764920, DATE '2025-01-13', 'day', 'elected'),
  ('20080', 'STATE_LOWER', -2764919, DATE '2025-01-13', 'day', 'elected'),
  ('20067', 'STATE_LOWER', -2764918, DATE '2025-01-13', 'day', 'elected'),
  ('20079', 'STATE_LOWER', -2764917, DATE '2025-01-13', 'day', 'elected'),
  ('20031', 'STATE_LOWER', -2764916, DATE '2025-01-13', 'day', 'elected'),
  ('20023', 'STATE_LOWER', -2764915, DATE '2025-01-13', 'day', 'elected'),
  ('20069', 'STATE_LOWER', -2764914, DATE '2025-01-13', 'day', 'elected'),
  ('20005', 'STATE_LOWER', -2764913, DATE '2025-10-13', 'day', 'appointed'),
  ('20095', 'STATE_LOWER', -2764912, DATE '2025-01-13', 'day', 'elected'),
  ('20019', 'STATE_LOWER', -2764911, DATE '2025-01-13', 'day', 'elected'),
  ('20055', 'STATE_LOWER', -2764910, DATE '2025-01-13', 'day', 'elected'),
  ('20059', 'STATE_LOWER', -2764909, DATE '2025-01-13', 'day', 'elected'),
  ('20060', 'STATE_LOWER', -2764908, DATE '2025-01-13', 'day', 'elected'),
  ('20114', 'STATE_LOWER', -2764907, DATE '2025-01-13', 'day', 'elected'),
  ('20101', 'STATE_LOWER', -2764906, DATE '2025-01-13', 'day', 'elected'),
  ('20058', 'STATE_LOWER', -2764905, DATE '2025-01-13', 'day', 'elected'),
  ('20120', 'STATE_LOWER', -2764904, DATE '2025-01-13', 'day', 'elected'),
  ('20003', 'STATE_LOWER', -2764903, DATE '2025-01-13', 'day', 'elected'),
  ('20051', 'STATE_LOWER', -2764902, DATE '2025-01-13', 'day', 'elected'),
  ('20039', 'STATE_LOWER', -2764901, DATE '2025-01-13', 'day', 'elected'),
  ('20021', 'STATE_LOWER', -2764900, DATE '2025-01-13', 'day', 'elected'),
  ('20121', 'STATE_LOWER', -2764899, DATE '2026-03-16', 'day', 'appointed'),
  ('20043', 'STATE_LOWER', -2764898, DATE '2025-01-13', 'day', 'elected'),
  ('20102', 'STATE_LOWER', -2764897, DATE '2025-01-13', 'day', 'elected'),
  ('20027', 'STATE_LOWER', -2764896, DATE '2025-01-13', 'day', 'elected'),
  ('20117', 'STATE_LOWER', -2764895, DATE '2025-01-13', 'day', 'elected'),
  ('20028', 'STATE_LOWER', -2764894, DATE '2025-01-13', 'day', 'elected'),
  ('20026', 'STATE_LOWER', -2764893, DATE '2025-01-13', 'day', 'elected'),
  ('20022', 'STATE_LOWER', -2764892, DATE '2025-01-13', 'day', 'elected'),
  ('20104', 'STATE_LOWER', -2764891, DATE '2025-01-13', 'day', 'elected'),
  ('20105', 'STATE_LOWER', -2764890, DATE '2025-01-13', 'day', 'elected'),
  ('20111', 'STATE_LOWER', -2764889, DATE '2025-01-13', 'day', 'elected'),
  ('20109', 'STATE_LOWER', -2764888, DATE '2025-01-13', 'day', 'elected'),
  ('20056', 'STATE_LOWER', -2764887, DATE '2025-01-13', 'day', 'elected'),
  ('20115', 'STATE_LOWER', -2764886, DATE '2025-01-13', 'day', 'elected'),
  ('20010', 'STATE_LOWER', -2764885, DATE '2025-01-13', 'day', 'elected'),
  ('20073', 'STATE_LOWER', -2764884, DATE '2025-01-13', 'day', 'elected'),
  ('20062', 'STATE_LOWER', -2764883, DATE '2025-01-13', 'day', 'elected'),
  ('20030', 'STATE_LOWER', -2764882, DATE '2025-01-13', 'day', 'elected'),
  ('20077', 'STATE_LOWER', -2764881, DATE '2025-01-13', 'day', 'elected'),
  ('20070', 'STATE_LOWER', -2764880, DATE '2025-07-30', 'day', 'appointed'),
  ('20034', 'STATE_LOWER', -2764879, DATE '2025-01-13', 'day', 'elected'),
  ('20107', 'STATE_LOWER', -2764878, DATE '2025-01-13', 'day', 'elected'),
  ('20108', 'STATE_LOWER', -2764877, DATE '2025-01-13', 'day', 'elected'),
  ('20025', 'STATE_LOWER', -2764876, DATE '2025-01-13', 'day', 'elected'),
  ('20032', 'STATE_UPPER', -2764875, DATE '2025-01-13', 'day', 'elected'),
  ('20017', 'STATE_UPPER', -2764874, DATE '2025-01-13', 'day', 'elected'),
  ('20040', 'STATE_UPPER', -2764873, DATE '2025-01-13', 'day', 'elected'),
  ('20026', 'STATE_UPPER', -2764872, DATE '2025-01-13', 'day', 'elected'),
  ('20033', 'STATE_UPPER', -2764871, DATE '2025-01-13', 'day', 'elected'),
  ('20036', 'STATE_UPPER', -2764870, DATE '2025-01-13', 'day', 'elected'),
  ('20001', 'STATE_UPPER', -2764869, DATE '2025-01-13', 'day', 'elected'),
  ('20027', 'STATE_UPPER', -2764868, DATE '2025-01-13', 'day', 'elected'),
  ('20039', 'STATE_UPPER', -2764867, DATE '2025-01-13', 'day', 'elected'),
  ('20020', 'STATE_UPPER', -2764866, DATE '2025-01-13', 'day', 'elected'),
  ('20030', 'STATE_UPPER', -2764865, DATE '2025-01-13', 'day', 'elected'),
  ('20014', 'STATE_UPPER', -2764864, DATE '2025-01-13', 'day', 'elected'),
  ('20029', 'STATE_UPPER', -2764863, DATE '2025-01-13', 'day', 'elected'),
  ('20002', 'STATE_UPPER', -2764862, DATE '2025-01-13', 'day', 'elected'),
  ('20009', 'STATE_UPPER', -2764861, DATE '2025-01-13', 'day', 'elected'),
  ('20004', 'STATE_UPPER', -2764860, DATE '2025-01-13', 'day', 'elected'),
  ('20024', 'STATE_UPPER', -2764859, DATE '2025-06-01', 'month', 'appointed'),
  ('20005', 'STATE_UPPER', -2764858, DATE '2025-01-13', 'day', 'elected'),
  ('20003', 'STATE_UPPER', -2764857, DATE '2025-01-13', 'day', 'elected'),
  ('20025', 'STATE_UPPER', -2764856, DATE '2025-12-01', 'month', 'appointed'),
  ('20034', 'STATE_UPPER', -2764855, DATE '2025-01-13', 'day', 'elected'),
  ('20031', 'STATE_UPPER', -2764854, DATE '2025-01-13', 'day', 'elected'),
  ('20015', 'STATE_UPPER', -2764853, DATE '2025-01-13', 'day', 'elected'),
  ('20028', 'STATE_UPPER', -2764852, DATE '2025-01-13', 'day', 'elected'),
  ('20006', 'STATE_UPPER', -2764851, DATE '2025-01-13', 'day', 'elected'),
  ('20035', 'STATE_UPPER', -2764850, DATE '2025-01-13', 'day', 'elected'),
  ('20038', 'STATE_UPPER', -2764849, DATE '2025-01-13', 'day', 'elected'),
  ('20013', 'STATE_UPPER', -2764848, DATE '2025-01-13', 'day', 'elected'),
  ('20037', 'STATE_UPPER', -2764847, DATE '2025-01-13', 'day', 'elected'),
  ('20022', 'STATE_UPPER', -2764846, DATE '2025-01-13', 'day', 'elected'),
  ('20021', 'STATE_UPPER', -2764845, DATE '2025-01-13', 'day', 'elected'),
  ('20023', 'STATE_UPPER', -2764844, DATE '2025-01-13', 'day', 'elected'),
  ('20010', 'STATE_UPPER', -2764843, DATE '2025-01-13', 'day', 'elected'),
  ('20018', 'STATE_UPPER', -2764842, DATE '2025-01-13', 'day', 'elected'),
  ('20012', 'STATE_UPPER', -2764841, DATE '2025-01-13', 'day', 'elected'),
  ('20011', 'STATE_UPPER', -2764840, DATE '2025-01-13', 'day', 'elected');

CREATE TEMP TABLE ks_terms_existing(geo_id text, district_type text, politician_id uuid,
                                    term_start date, start_precision text, how_started text)
  ON COMMIT DROP;

INSERT INTO ks_terms_existing(geo_id, district_type, politician_id, term_start, start_precision, how_started) VALUES
  ('20007', 'STATE_UPPER', '48d821c9-86ef-4d9d-978f-17bb59ac7fd3'::uuid, DATE '2025-01-13', 'day', 'elected'),
  ('20008', 'STATE_UPPER', 'e80123eb-87f0-4e90-a661-29da53de972a'::uuid, DATE '2025-01-13', 'day', 'elected'),
  ('20016', 'STATE_UPPER', '7dbc13d8-f39d-4783-9f84-83fb31053a8c'::uuid, DATE '2025-01-13', 'day', 'elected'),
  ('20019', 'STATE_UPPER', 'b21b5e5e-3359-4692-a60d-47d459bbb198'::uuid, DATE '2025-01-13', 'day', 'elected');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started, 'Kansas Legislature. Roster from the Legislature''s own first-party CSV at kslegislature.gov/b2025_26/{house/representatives,senate/senators}/csv/ (125 and 40 rows, District, Fullname, Party and County as columns), with every one of the 165 individual member pages swept and each confirmed to name the same member at the same seat. Arrival dates from the chambers'' own Journals: Journal of the House and Journal of the Senate, FIRST DAY, Monday January 13 2025, which quote the Secretary of State''s certification of December 2 2024 and record the oath administered by Chief Justice Marla Luckert and Justice Dan Biles respectively; interim appointments from the House Journal FIRST DAY January 12 2026 and the House Journal of March 16 2026, each certifying its own appointment and oath date. The Senate publishes no interim-oath record anywhere in its 54 journal days of the 2026 session, so its two appointees carry month precision. Read 2026-09-27 (KS-2) (CC_0157, KS-2)'
FROM ks_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type = t.district_type AND lower(d.state) = 'ks'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c ON c.id = o.chamber_id
 AND c.name_formal IN ('Kansas House of Representatives','Kansas Senate')
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, t.politician_id, t.term_start, NULL, t.start_precision, t.how_started, 'Kansas Legislature. Roster from the Legislature''s own first-party CSV at kslegislature.gov/b2025_26/{house/representatives,senate/senators}/csv/ (125 and 40 rows, District, Fullname, Party and County as columns), with every one of the 165 individual member pages swept and each confirmed to name the same member at the same seat. Arrival dates from the chambers'' own Journals: Journal of the House and Journal of the Senate, FIRST DAY, Monday January 13 2025, which quote the Secretary of State''s certification of December 2 2024 and record the oath administered by Chief Justice Marla Luckert and Justice Dan Biles respectively; interim appointments from the House Journal FIRST DAY January 12 2026 and the House Journal of March 16 2026, each certifying its own appointment and oath date. The Senate publishes no interim-oath record anywhere in its 54 journal days of the 2026 session, so its two appointees carry month precision. Read 2026-09-27 (KS-2) (CC_0157, KS-2)'
FROM ks_terms_existing t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type = t.district_type AND lower(d.state) = 'ks'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c ON c.id = o.chamber_id
 AND c.name_formal IN ('Kansas House of Representatives','Kansas Senate')
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── 5. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_offices int; v_terms int; v_day int; v_month int; v_year int; v_unknown int;
  v_ended int; v_seated int; v_notinc int; v_elected int; v_appointed int; v_dupseat int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2765000 AND -2764840;
  IF v_people <> 161 THEN
    RAISE EXCEPTION 'KS-2 occupancy: expected 161 people in the reserved external_id block, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Kansas House of Representatives','Kansas Senate');
  IF v_offices <> 165 THEN
    RAISE EXCEPTION 'KS-2 occupancy: expected 165 Kansas legislative offices, got % - run CC_0156 first', v_offices;
  END IF;

  SELECT count(*),
         count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'month'),
         count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL),
         count(*) FILTER (WHERE ot.how_started = 'elected'),
         count(*) FILTER (WHERE ot.how_started = 'appointed')
    INTO v_terms, v_day, v_month, v_year, v_unknown, v_ended, v_elected, v_appointed
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Kansas House of Representatives','Kansas Senate');

  IF v_terms <> 165 THEN
    RAISE EXCEPTION 'KS-2 occupancy: expected 165 terms, got %', v_terms;
  END IF;
  IF v_day <> 163 THEN
    RAISE EXCEPTION 'KS-2 occupancy: expected 163 day-precision terms, got %', v_day;
  END IF;
  IF v_month <> 2 THEN
    RAISE EXCEPTION 'KS-2 occupancy: expected 2 month-precision terms (the two Senate appointees), got %', v_month;
  END IF;
  IF v_year <> 0 OR v_unknown <> 0 THEN
    RAISE EXCEPTION 'KS-2 occupancy: % year and % unknown precision term(s); this wave dates every seat', v_year, v_unknown;
  END IF;
  IF v_elected <> 157 OR v_appointed <> 8 THEN
    RAISE EXCEPTION 'KS-2 occupancy: expected 157 elected and 8 appointed, got % and %', v_elected, v_appointed;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'KS-2 occupancy: % term(s) already carry a term_end; every seat here is current', v_ended;
  END IF;

  -- Occupancy is counted through the view, and NOT with count(*): office_current_holder LEFT JOINs
  -- from offices, so a vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Kansas House of Representatives','Kansas Senate');
  IF v_seated <> 165 THEN
    RAISE EXCEPTION 'KS-2 occupancy: expected 165 seated holders through office_current_holder, got %', v_seated;
  END IF;

  -- Every seated Kansas legislator must read as an incumbent, including the four reused rows.
  SELECT count(*) INTO v_notinc
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE c.name_formal IN ('Kansas House of Representatives','Kansas Senate')
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_notinc <> 0 THEN
    RAISE EXCEPTION 'KS-2 occupancy: % seated Kansas legislator(s) are not is_incumbent/is_active - they would be hidden from address search', v_notinc;
  END IF;

  -- No person may hold two Kansas legislative seats.
  SELECT count(*) INTO v_dupseat FROM (
    SELECT och.politician_id
      FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.name_formal IN ('Kansas House of Representatives','Kansas Senate')
       AND och.politician_id IS NOT NULL
     GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dupseat <> 0 THEN
    RAISE EXCEPTION 'KS-2 occupancy: % person(s) hold more than one Kansas legislative seat', v_dupseat;
  END IF;

  RAISE NOTICE 'KS-2 occupancy OK: 165 terms, % day / % month, % elected / % appointed, 165 seated, 0 non-incumbent, 0 double seats',
    v_day, v_month, v_elected, v_appointed;
END $$;

COMMIT;
