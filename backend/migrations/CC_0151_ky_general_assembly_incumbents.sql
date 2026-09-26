-- CC_0151_ky_general_assembly_incumbents.sql
-- Knight Foundation program, wave KY-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0150, which creates the chambers and the 138 offices.
--
-- Seats all 138 sitting members of the Kentucky General Assembly: 100 Representatives and 38
-- Senators. Creates 138 people and 138 open-ended terms. 0 vacancies.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE ROSTER WAS READ FROM ALL 138 MEMBER PAGES, AND IT HAD TO BE.
--
-- The LRC GIS layer Ky_Legislative_Districts_WGS84WM serves Legislator/Full_Name beside the
-- polygons, and KY-1 used that same layer as its GEOMETRY authority and proved it 138/138. Its
-- ROSTER is STALE: Senate District 37 still reads 'Yates, David', while the chamber's own list and
-- Clemons' own profile both read Gary Clemons. David Yates resigned 2025-10-08 to become Jefferson
-- County Clerk; Clemons won the 2025-12-16 special election.
-- ▶ A SOURCE CAN BE AUTHORITATIVE FOR ONE FIELD AND STALE FOR ANOTHER. Proving a layer's geometry
-- says nothing about the attributes riding along with it.
--
-- A DEPARTED KENTUCKY LEGISLATOR HAS NO PAGE AT ALL. The profile URL is keyed to the SEAT
-- (DistrictNumber only), so a successor replaces the predecessor and a departure marker can never
-- appear. The cross-source diff is the only change-check that works in Kentucky, and it is what
-- caught SD-37.
--
-- ONE MEMBER HAS HELD ONE SEAT UNDER THREE PUBLISHED NAMES. House District 81:
-- 'Frazier, Deanna' (2019-2021) -> 'Frazier Gordon, Deanna' (2021-2025) -> 'Gordon, Deanna'
-- (2025- ). A name-keyed diff reads that as two departures and two arrivals. Matching Kentucky
-- legislators by name across time is unsafe; this migration keys on the SEAT.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- TERM DATES: 7 day, 131 year, 0 unknown, 0 invented.
--
-- Ky. Const. s 30 makes a term begin on 1 January of the year succeeding the election, and an
-- earlier draft of this wave used that as a blanket day for 126 seats. IT WAS WRONG:
--   * the LRC 'Service' string is CHAMBER-scoped, not seat-scoped;
--   * 13 members carry a gap or a chamber switch ('House 1994 - 22, House 2025 - Present'), so the
--     FIRST year can miss by up to 31 years and can name the wrong chamber entirely;
--   * 3 still-serving members changed DISTRICT NUMBER in the 2022 remap (D90->D14, D88->D43,
--     D82->D49), measured against archived 2022 and 2023 LRC rosters;
--   * 9 arrived mid-term by special election;
--   * 8 more were caught by replaying 45 archived LRC rosters -- absent from an early snapshot of
--     their claimed year, present in a later one;
--   * and that detector has blind spots: 40 members predate snapshot coverage, and Peyton Griffee,
--     a confirmed March 2024 arrival, is NOT flagged by it.
-- ▶ So a DAY is claimed only where the arrival was individually sourced. Everything else takes the
-- last service segment's YEAR at year precision, which UNDER-claims rather than over-claims.
-- The gap between a special election and the oath measured 6, 7, 7 and 20 days -- IT IS NOT A RULE
-- AND MUST NOT BE COMPUTED (ND-3's finding, reproduced here). Two January 2014 arrivals (Miles
-- House 7, Thomas Senate 13) are deliberately left at year precision because sources disagree
-- across Jan 2 / Jan 4 / Jan 7 and Kentucky publishes NO House or Senate Journal online.
--
-- external_id block -2763000..-2762601 was measured EMPTY on 2026-09-26; the nearest occupied id
-- below it is -2770001. An external_id collision seats the WRONG person silently.
--
-- Party is NOT written. Party is antipartisan and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 1. The 134 people whose names collide with nobody ─────────────────────────

CREATE TEMP TABLE ky_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ky_new_people(external_id, full_name, first_name, last_name) VALUES
  (-2763000, 'Steven Rudy', 'Steven', 'Rudy'),
  (-2762999, 'Kim Holloway', 'Kim', 'Holloway'),
  (-2762998, 'Randy Bridges', 'Randy', 'Bridges'),
  (-2762997, 'Wade Williams', 'Wade', 'Williams'),
  (-2762996, 'Mary Beth Imes', 'Mary', 'Imes'),
  (-2762995, 'Chris Freeland', 'Chris', 'Freeland'),
  (-2762994, 'Suzanne Miles', 'Suzanne', 'Miles'),
  (-2762993, 'Walker Thomas', 'Walker', 'Thomas'),
  (-2762992, 'Myron Dossett', 'Myron', 'Dossett'),
  (-2762991, 'Josh Calloway', 'Josh', 'Calloway'),
  (-2762990, 'J.T. Payne', 'J.T.', 'Payne'),
  (-2762989, 'Jim Gooch Jr.', 'Jim', 'Jr.'),
  (-2762988, 'DJ Johnson', 'DJ', 'Johnson'),
  (-2762987, 'Scott Lewis', 'Scott', 'Lewis'),
  (-2762986, 'Rebecca Raymer', 'Rebecca', 'Raymer'),
  (-2762985, 'Jason Petrie', 'Jason', 'Petrie'),
  (-2762984, 'Robert Duvall', 'Robert', 'Duvall'),
  (-2762983, 'Samara Heavrin', 'Samara', 'Heavrin'),
  (-2762982, 'Michael Meredith', 'Michael', 'Meredith'),
  (-2762981, 'Kevin Jackson', 'Kevin', 'Jackson'),
  (-2762980, 'Amy Neighbors', 'Amy', 'Neighbors'),
  (-2762979, 'Shawn McPherson', 'Shawn', 'McPherson'),
  (-2762978, 'Steve Riley', 'Steve', 'Riley'),
  (-2762977, 'Ryan Bivens', 'Ryan', 'Bivens'),
  (-2762976, 'Steve Bratcher', 'Steve', 'Bratcher'),
  (-2762975, 'Peyton Griffee', 'Peyton', 'Griffee'),
  (-2762974, 'Nancy Tate', 'Nancy', 'Tate'),
  (-2762973, 'Jared Bauman', 'Jared', 'Bauman'),
  (-2762972, 'Chris Lewis', 'Chris', 'Lewis'),
  (-2762971, 'Daniel Grossberg', 'Daniel', 'Grossberg'),
  (-2762970, 'Susan Witten', 'Susan', 'Witten'),
  (-2762969, 'Tina Bojanowski', 'Tina', 'Bojanowski'),
  (-2762968, 'Jason Nemes', 'Jason', 'Nemes'),
  (-2762967, 'Sarah Stalker', 'Sarah', 'Stalker'),
  (-2762966, 'Lisa Willner', 'Lisa', 'Willner'),
  (-2762965, 'John Hodgson', 'John', 'Hodgson'),
  (-2762964, 'Emily Callaway', 'Emily', 'Callaway'),
  (-2762963, 'Rachel Roarx', 'Rachel', 'Roarx'),
  (-2762962, 'Matt Lockett', 'Matt', 'Lockett'),
  (-2762961, 'Nima Kulkarni', 'Nima', 'Kulkarni'),
  (-2762960, 'Mary Lou Marzian', 'Mary', 'Marzian'),
  (-2762959, 'Joshua Watkins', 'Joshua', 'Watkins'),
  (-2762958, 'Pamela Stevenson', 'Pamela', 'Stevenson'),
  (-2762957, 'Beverly Chester-Burton', 'Beverly', 'Chester-Burton'),
  (-2762956, 'Adam Moore', 'Adam', 'Moore'),
  (-2762955, 'Al Gentry', 'Al', 'Gentry'),
  (-2762954, 'Felicia Rabourn', 'Felicia', 'Rabourn'),
  (-2762953, 'Ken Fleming', 'Ken', 'Fleming'),
  (-2762952, 'Thomas Huff', 'Thomas', 'Huff'),
  (-2762951, 'Candy Massaroni', 'Candy', 'Massaroni'),
  (-2762950, 'Michael Sarge Pollock', 'Michael', 'Pollock'),
  (-2762949, 'Ken Upchurch', 'Ken', 'Upchurch'),
  (-2762948, 'James Tipton', 'James', 'Tipton'),
  (-2762946, 'Kim King', 'Kim', 'King'),
  (-2762945, 'Daniel Fister', 'Daniel', 'Fister'),
  (-2762944, 'Erika Hancock', 'Erika', 'Hancock'),
  (-2762943, 'Jennifer Decker', 'Jennifer', 'Decker'),
  (-2762942, 'David W. Osborne', 'David', 'Osborne'),
  (-2762941, 'Marianne Proctor', 'Marianne', 'Proctor'),
  (-2762940, 'Savannah Maddox', 'Savannah', 'Maddox'),
  (-2762939, 'Tony Hampton', 'Tony', 'Hampton'),
  (-2762938, 'Kim Banta', 'Kim', 'Banta'),
  (-2762937, 'Kimberly Poore Moser', 'Kimberly', 'Moser'),
  (-2762936, 'Stephanie Dietz', 'Stephanie', 'Dietz'),
  (-2762935, 'T.J. Roberts', 'T.J.', 'Roberts'),
  (-2762933, 'Mike Clines', 'Mike', 'Clines'),
  (-2762932, 'Steven Doan', 'Steven', 'Doan'),
  (-2762930, 'Josh Bray', 'Josh', 'Bray'),
  (-2762929, 'Matthew Koch', 'Matthew', 'Koch'),
  (-2762928, 'Ryan Dotson', 'Ryan', 'Dotson'),
  (-2762927, 'David Hale', 'David', 'Hale'),
  (-2762926, 'Lindsey Burke', 'Lindsey', 'Burke'),
  (-2762925, 'Anne Gay Donworth', 'Anne', 'Donworth'),
  (-2762924, 'George Brown Jr.', 'George', 'Jr.'),
  (-2762923, 'Mark Hart', 'Mark', 'Hart'),
  (-2762922, 'Chad Aull', 'Chad', 'Aull'),
  (-2762921, 'David Meade', 'David', 'Meade'),
  (-2762920, 'Deanna Gordon', 'Deanna', 'Gordon'),
  (-2762919, 'Nick Wilson', 'Nick', 'Wilson'),
  (-2762918, 'Josh Branscum', 'Josh', 'Branscum'),
  (-2762917, 'Chris Fugate', 'Chris', 'Fugate'),
  (-2762916, 'Shane Baker', 'Shane', 'Baker'),
  (-2762915, 'Tom Smith', 'Tom', 'Smith'),
  (-2762914, 'Adam Bowling', 'Adam', 'Bowling'),
  (-2762913, 'Vanessa Grossl', 'Vanessa', 'Grossl'),
  (-2762912, 'Timmy Truett', 'Timmy', 'Truett'),
  (-2762911, 'Derek Lewis', 'Derek', 'Lewis'),
  (-2762910, 'Bill Wesley', 'Bill', 'Wesley'),
  (-2762909, 'John Blanton', 'John', 'Blanton'),
  (-2762908, 'Adrielle Camuel', 'Adrielle', 'Camuel'),
  (-2762907, 'Mitch Whitaker', 'Mitch', 'Whitaker'),
  (-2762906, 'Ashley Tackett Laferty', 'Ashley', 'Laferty'),
  (-2762905, 'Patrick Flannery', 'Patrick', 'Flannery'),
  (-2762904, 'Bobby McCool', 'Bobby', 'McCool'),
  (-2762903, 'Aaron Thompson', 'Aaron', 'Thompson'),
  (-2762902, 'Richard White', 'Richard', 'White'),
  (-2762901, 'Scott Sharp', 'Scott', 'Sharp'),
  (-2762900, 'Jason Howell', 'Jason', 'Howell'),
  (-2762899, 'Danny Carroll', 'Danny', 'Carroll'),
  (-2762898, 'Craig Richardson', 'Craig', 'Richardson'),
  (-2762897, 'Robby Mills', 'Robby', 'Mills'),
  (-2762896, 'Stephen Meredith', 'Stephen', 'Meredith'),
  (-2762895, 'Lindsey Tichenor', 'Lindsey', 'Tichenor'),
  (-2762894, 'Aaron Reed', 'Aaron', 'Reed'),
  (-2762893, 'Gary Boswell', 'Gary', 'Boswell'),
  (-2762892, 'David P. Givens', 'David', 'Givens'),
  (-2762891, 'Matthew Deneen', 'Matthew', 'Deneen'),
  (-2762890, 'Steve Rawlings', 'Steve', 'Rawlings'),
  (-2762889, 'Amanda Mays Bledsoe', 'Amanda', 'Bledsoe'),
  (-2762888, 'Reginald L. Thomas', 'Reginald', 'Thomas'),
  (-2762887, 'Jimmy Higdon', 'Jimmy', 'Higdon'),
  (-2762886, 'Rick Girdler', 'Rick', 'Girdler'),
  (-2762885, 'Max Wise', 'Max', 'Wise'),
  (-2762884, 'Matt Nunn', 'Matt', 'Nunn'),
  (-2762883, 'Robin L. Webb', 'Robin', 'Webb'),
  (-2762882, 'Cassie Chambers Armstrong', 'Cassie', 'Armstrong'),
  (-2762881, 'Gex Williams', 'Gex', 'Williams'),
  (-2762880, 'Brandon J. Storm', 'Brandon', 'Storm'),
  (-2762879, 'Donald Douglas', 'Donald', 'Douglas'),
  (-2762878, 'Christian McDaniel', 'Christian', 'McDaniel'),
  (-2762877, 'Shelley Funke Frommeyer', 'Shelley', 'Frommeyer'),
  (-2762876, 'Robert Stivers', 'Robert', 'Stivers'),
  (-2762875, 'Karen Berg', 'Karen', 'Berg'),
  (-2762874, 'Stephen West', 'Stephen', 'West'),
  (-2762873, 'Greg Elkins', 'Greg', 'Elkins'),
  (-2762872, 'Scott Madon', 'Scott', 'Madon'),
  (-2762870, 'Phillip Wheeler', 'Phillip', 'Wheeler'),
  (-2762869, 'Mike Wilson', 'Mike', 'Wilson'),
  (-2762868, 'Gerald A. Neal', 'Gerald', 'Neal'),
  (-2762867, 'Jared Carpenter', 'Jared', 'Carpenter'),
  (-2762866, 'Keturah J. Herron', 'Keturah', 'Herron'),
  (-2762865, 'Julie Raque Adams', 'Julie', 'Adams'),
  (-2762864, 'Gary Clemons', 'Gary', 'Clemons'),
  (-2762863, 'Michael J. Nemes', 'Michael', 'Nemes');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Kentucky Legislative Research Commission. Roster read from all 138 individual member profile pages at https://legislature.ky.gov/Legislators/Pages/Legislator-Profile.aspx?DistrictNumber=N (House N=1..100, Senate N=101..138), each of which names its own member and chamber; cross-checked against apps.legislature.ky.gov/Legislators/{h,s}members_district.html and against the Legislator attributes on the LRC GIS layer Ky_Legislative_Districts_WGS84WM, which was found STALE on Senate District 37 (it still named David Yates, who resigned 2025-10-08). Arrival days claimed only where individually sourced; otherwise the year of the last service segment at year precision. Read 2026-09-26 (KY-2) (CC_0151, KY-2)', true, true
FROM ky_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 4 namesakes — guard lifted for this statement only ──────────────
--
-- Each was checked against the existing row and is a DIFFERENT person:
--   Daniel Elliott (House 54): existing row is the INDIANA State Treasurer (source: cicero)
--   Matthew Lehman (House 67): existing row is from the INDIANA discovery cohort, is_active=false
--   William Lawrence (House 70): existing row is a MICHIGAN U.S. House District 7 candidate
--   Brandon Smith (Senate 30): existing row is a Longview, TEXAS city council candidate

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE ky_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ky_namesake_people(external_id, full_name, first_name, last_name) VALUES
  (-2762947, 'Daniel Elliott', 'Daniel', 'Elliott'),
  (-2762934, 'Matthew Lehman', 'Matthew', 'Lehman'),
  (-2762931, 'William Lawrence', 'William', 'Lawrence'),
  (-2762871, 'Brandon Smith', 'Brandon', 'Smith');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Kentucky Legislative Research Commission. Roster read from all 138 individual member profile pages at https://legislature.ky.gov/Legislators/Pages/Legislator-Profile.aspx?DistrictNumber=N (House N=1..100, Senate N=101..138), each of which names its own member and chamber; cross-checked against apps.legislature.ky.gov/Legislators/{h,s}members_district.html and against the Legislator attributes on the LRC GIS layer Ky_Legislative_Districts_WGS84WM, which was found STALE on Senate District 37 (it still named David Yates, who resigned 2025-10-08). Arrival days claimed only where individually sourced; otherwise the year of the last service segment at year precision. Read 2026-09-26 (KY-2) (CC_0151, KY-2)', true, true
FROM ky_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 3. The 138 terms ─────────────────────────────────────────────────────────

CREATE TEMP TABLE ky_terms(
  geo_id text, district_type text, external_id bigint, term_start date, start_precision text
) ON COMMIT DROP;

INSERT INTO ky_terms(geo_id, district_type, external_id, term_start, start_precision) VALUES
  ('21001', 'STATE_LOWER', -2763000, DATE '2005-01-01', 'year'),
  ('21002', 'STATE_LOWER', -2762999, DATE '2025-01-01', 'year'),
  ('21003', 'STATE_LOWER', -2762998, DATE '2019-01-01', 'year'),
  ('21004', 'STATE_LOWER', -2762997, DATE '2023-01-01', 'year'),
  ('21005', 'STATE_LOWER', -2762996, DATE '2021-01-01', 'year'),
  ('21006', 'STATE_LOWER', -2762995, DATE '2019-01-01', 'year'),
  ('21007', 'STATE_LOWER', -2762994, DATE '2014-01-01', 'year'),
  ('21008', 'STATE_LOWER', -2762993, DATE '2017-01-01', 'year'),
  ('21009', 'STATE_LOWER', -2762992, DATE '2007-01-01', 'year'),
  ('21010', 'STATE_LOWER', -2762991, DATE '2021-01-01', 'year'),
  ('21011', 'STATE_LOWER', -2762990, DATE '2025-01-01', 'year'),
  ('21012', 'STATE_LOWER', -2762989, DATE '1995-01-01', 'year'),
  ('21013', 'STATE_LOWER', -2762988, DATE '2021-01-01', 'year'),
  ('21014', 'STATE_LOWER', -2762987, DATE '2023-01-01', 'year'),
  ('21015', 'STATE_LOWER', -2762986, DATE '2023-01-01', 'year'),
  ('21016', 'STATE_LOWER', -2762985, DATE '2017-01-01', 'year'),
  ('21017', 'STATE_LOWER', -2762984, DATE '2023-01-01', 'year'),
  ('21018', 'STATE_LOWER', -2762983, DATE '2019-01-01', 'year'),
  ('21019', 'STATE_LOWER', -2762982, DATE '2011-01-01', 'year'),
  ('21020', 'STATE_LOWER', -2762981, DATE '2023-01-01', 'year'),
  ('21021', 'STATE_LOWER', -2762980, DATE '2023-01-01', 'year'),
  ('21022', 'STATE_LOWER', -2762979, DATE '2021-01-01', 'year'),
  ('21023', 'STATE_LOWER', -2762978, DATE '2017-01-01', 'year'),
  ('21024', 'STATE_LOWER', -2762977, DATE '2025-01-01', 'year'),
  ('21025', 'STATE_LOWER', -2762976, DATE '2023-01-01', 'year'),
  ('21026', 'STATE_LOWER', -2762975, DATE '2024-03-25', 'day'),
  ('21027', 'STATE_LOWER', -2762974, DATE '2019-01-01', 'year'),
  ('21028', 'STATE_LOWER', -2762973, DATE '2023-01-01', 'year'),
  ('21029', 'STATE_LOWER', -2762972, DATE '2025-01-01', 'year'),
  ('21030', 'STATE_LOWER', -2762971, DATE '2023-01-01', 'year'),
  ('21031', 'STATE_LOWER', -2762970, DATE '2023-01-01', 'year'),
  ('21032', 'STATE_LOWER', -2762969, DATE '2019-01-01', 'year'),
  ('21033', 'STATE_LOWER', -2762968, DATE '2017-01-01', 'year'),
  ('21034', 'STATE_LOWER', -2762967, DATE '2023-01-01', 'year'),
  ('21035', 'STATE_LOWER', -2762966, DATE '2019-01-01', 'year'),
  ('21036', 'STATE_LOWER', -2762965, DATE '2023-01-01', 'year'),
  ('21037', 'STATE_LOWER', -2762964, DATE '2023-01-01', 'year'),
  ('21038', 'STATE_LOWER', -2762963, DATE '2023-01-01', 'year'),
  ('21039', 'STATE_LOWER', -2762962, DATE '2021-01-01', 'year'),
  ('21040', 'STATE_LOWER', -2762961, DATE '2019-01-01', 'year'),
  ('21041', 'STATE_LOWER', -2762960, DATE '2025-01-01', 'year'),
  ('21042', 'STATE_LOWER', -2762959, DATE '2025-01-01', 'year'),
  ('21043', 'STATE_LOWER', -2762958, DATE '2023-01-01', 'year'),
  ('21044', 'STATE_LOWER', -2762957, DATE '2023-01-01', 'year'),
  ('21045', 'STATE_LOWER', -2762956, DATE '2025-01-01', 'year'),
  ('21046', 'STATE_LOWER', -2762955, DATE '2017-01-01', 'year'),
  ('21047', 'STATE_LOWER', -2762954, DATE '2021-01-01', 'year'),
  ('21048', 'STATE_LOWER', -2762953, DATE '2021-01-01', 'year'),
  ('21049', 'STATE_LOWER', -2762952, DATE '2023-01-01', 'year'),
  ('21050', 'STATE_LOWER', -2762951, DATE '2023-01-01', 'year'),
  ('21051', 'STATE_LOWER', -2762950, DATE '2021-01-01', 'year'),
  ('21052', 'STATE_LOWER', -2762949, DATE '2013-01-01', 'year'),
  ('21053', 'STATE_LOWER', -2762948, DATE '2015-01-01', 'year'),
  ('21054', 'STATE_LOWER', -2762947, DATE '2016-03-15', 'day'),
  ('21055', 'STATE_LOWER', -2762946, DATE '2011-01-01', 'year'),
  ('21056', 'STATE_LOWER', -2762945, DATE '2021-01-01', 'year'),
  ('21057', 'STATE_LOWER', -2762944, DATE '2025-01-01', 'year'),
  ('21058', 'STATE_LOWER', -2762943, DATE '2021-01-01', 'year'),
  ('21059', 'STATE_LOWER', -2762942, DATE '2005-01-01', 'year'),
  ('21060', 'STATE_LOWER', -2762941, DATE '2023-01-01', 'year'),
  ('21061', 'STATE_LOWER', -2762940, DATE '2019-01-01', 'year'),
  ('21062', 'STATE_LOWER', -2762939, DATE '2025-01-01', 'year'),
  ('21063', 'STATE_LOWER', -2762938, DATE '2019-01-01', 'year'),
  ('21064', 'STATE_LOWER', -2762937, DATE '2017-01-01', 'year'),
  ('21065', 'STATE_LOWER', -2762936, DATE '2023-01-01', 'year'),
  ('21066', 'STATE_LOWER', -2762935, DATE '2025-01-01', 'year'),
  ('21067', 'STATE_LOWER', -2762934, DATE '2025-01-01', 'year'),
  ('21068', 'STATE_LOWER', -2762933, DATE '2023-01-01', 'year'),
  ('21069', 'STATE_LOWER', -2762932, DATE '2023-01-01', 'year'),
  ('21070', 'STATE_LOWER', -2762931, DATE '2021-01-01', 'year'),
  ('21071', 'STATE_LOWER', -2762930, DATE '2021-01-01', 'year'),
  ('21072', 'STATE_LOWER', -2762929, DATE '2019-01-01', 'year'),
  ('21073', 'STATE_LOWER', -2762928, DATE '2021-01-01', 'year'),
  ('21074', 'STATE_LOWER', -2762927, DATE '2015-01-01', 'year'),
  ('21075', 'STATE_LOWER', -2762926, DATE '2023-01-01', 'year'),
  ('21076', 'STATE_LOWER', -2762925, DATE '2025-01-01', 'year'),
  ('21077', 'STATE_LOWER', -2762924, DATE '2015-01-01', 'year'),
  ('21078', 'STATE_LOWER', -2762923, DATE '2017-01-01', 'year'),
  ('21079', 'STATE_LOWER', -2762922, DATE '2023-01-01', 'year'),
  ('21080', 'STATE_LOWER', -2762921, DATE '2013-01-01', 'year'),
  ('21081', 'STATE_LOWER', -2762920, DATE '2019-01-01', 'year'),
  ('21082', 'STATE_LOWER', -2762919, DATE '2023-01-01', 'year'),
  ('21083', 'STATE_LOWER', -2762918, DATE '2021-01-01', 'year'),
  ('21084', 'STATE_LOWER', -2762917, DATE '2017-01-01', 'year'),
  ('21085', 'STATE_LOWER', -2762916, DATE '2021-01-01', 'year'),
  ('21086', 'STATE_LOWER', -2762915, DATE '2021-01-01', 'year'),
  ('21087', 'STATE_LOWER', -2762914, DATE '2019-01-01', 'year'),
  ('21088', 'STATE_LOWER', -2762913, DATE '2025-01-01', 'year'),
  ('21089', 'STATE_LOWER', -2762912, DATE '2021-01-01', 'year'),
  ('21090', 'STATE_LOWER', -2762911, DATE '2019-01-01', 'year'),
  ('21091', 'STATE_LOWER', -2762910, DATE '2021-01-01', 'year'),
  ('21092', 'STATE_LOWER', -2762909, DATE '2017-01-01', 'year'),
  ('21093', 'STATE_LOWER', -2762908, DATE '2023-01-01', 'year'),
  ('21094', 'STATE_LOWER', -2762907, DATE '2025-01-01', 'year'),
  ('21095', 'STATE_LOWER', -2762906, DATE '2019-01-01', 'year'),
  ('21096', 'STATE_LOWER', -2762905, DATE '2021-01-01', 'year'),
  ('21097', 'STATE_LOWER', -2762904, DATE '2019-01-01', 'year'),
  ('21098', 'STATE_LOWER', -2762903, DATE '2025-01-01', 'year'),
  ('21099', 'STATE_LOWER', -2762902, DATE '2020-03-03', 'day'),
  ('21100', 'STATE_LOWER', -2762901, DATE '2021-01-01', 'year'),
  ('21001', 'STATE_UPPER', -2762900, DATE '2021-01-01', 'year'),
  ('21002', 'STATE_UPPER', -2762899, DATE '2015-01-01', 'year'),
  ('21003', 'STATE_UPPER', -2762898, DATE '2025-01-01', 'year'),
  ('21004', 'STATE_UPPER', -2762897, DATE '2019-01-01', 'year'),
  ('21005', 'STATE_UPPER', -2762896, DATE '2017-01-01', 'year'),
  ('21006', 'STATE_UPPER', -2762895, DATE '2023-01-01', 'year'),
  ('21007', 'STATE_UPPER', -2762894, DATE '2025-01-01', 'year'),
  ('21008', 'STATE_UPPER', -2762893, DATE '2023-01-01', 'year'),
  ('21009', 'STATE_UPPER', -2762892, DATE '2009-01-01', 'year'),
  ('21010', 'STATE_UPPER', -2762891, DATE '2023-01-01', 'year'),
  ('21011', 'STATE_UPPER', -2762890, DATE '2025-01-01', 'year'),
  ('21012', 'STATE_UPPER', -2762889, DATE '2023-01-01', 'year'),
  ('21013', 'STATE_UPPER', -2762888, DATE '2014-01-01', 'year'),
  ('21014', 'STATE_UPPER', -2762887, DATE '2009-01-01', 'year'),
  ('21015', 'STATE_UPPER', -2762886, DATE '2017-01-01', 'year'),
  ('21016', 'STATE_UPPER', -2762885, DATE '2015-01-01', 'year'),
  ('21017', 'STATE_UPPER', -2762884, DATE '2025-01-01', 'year'),
  ('21018', 'STATE_UPPER', -2762883, DATE '2009-01-01', 'year'),
  ('21019', 'STATE_UPPER', -2762882, DATE '2023-01-01', 'year'),
  ('21020', 'STATE_UPPER', -2762881, DATE '2023-01-01', 'year'),
  ('21021', 'STATE_UPPER', -2762880, DATE '2021-01-01', 'year'),
  ('21022', 'STATE_UPPER', -2762879, DATE '2021-01-01', 'year'),
  ('21023', 'STATE_UPPER', -2762878, DATE '2013-01-01', 'year'),
  ('21024', 'STATE_UPPER', -2762877, DATE '2023-01-01', 'year'),
  ('21025', 'STATE_UPPER', -2762876, DATE '1997-01-01', 'year'),
  ('21026', 'STATE_UPPER', -2762875, DATE '2020-07-13', 'day'),
  ('21027', 'STATE_UPPER', -2762874, DATE '2015-01-01', 'year'),
  ('21028', 'STATE_UPPER', -2762873, DATE '2023-01-01', 'year'),
  ('21029', 'STATE_UPPER', -2762872, DATE '2025-01-01', 'year'),
  ('21030', 'STATE_UPPER', -2762871, DATE '2008-02-11', 'day'),
  ('21031', 'STATE_UPPER', -2762870, DATE '2019-01-01', 'year'),
  ('21032', 'STATE_UPPER', -2762869, DATE '2011-01-01', 'year'),
  ('21033', 'STATE_UPPER', -2762868, DATE '1989-01-01', 'year'),
  ('21034', 'STATE_UPPER', -2762867, DATE '2011-01-01', 'year'),
  ('21035', 'STATE_UPPER', -2762866, DATE '2025-01-01', 'year'),
  ('21036', 'STATE_UPPER', -2762865, DATE '2015-01-01', 'year'),
  ('21037', 'STATE_UPPER', -2762864, DATE '2026-01-06', 'day'),
  ('21038', 'STATE_UPPER', -2762863, DATE '2020-01-21', 'day');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, 'elected', 'Kentucky Legislative Research Commission. Roster read from all 138 individual member profile pages at https://legislature.ky.gov/Legislators/Pages/Legislator-Profile.aspx?DistrictNumber=N (House N=1..100, Senate N=101..138), each of which names its own member and chamber; cross-checked against apps.legislature.ky.gov/Legislators/{h,s}members_district.html and against the Legislator attributes on the LRC GIS layer Ky_Legislative_Districts_WGS84WM, which was found STALE on Senate District 37 (it still named David Yates, who resigned 2025-10-08). Arrival days claimed only where individually sourced; otherwise the year of the last service segment at year precision. Read 2026-09-26 (KY-2) (CC_0151, KY-2)'
FROM ky_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type = t.district_type AND lower(d.state) = 'ky'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c ON c.id = o.chamber_id
 AND c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_day int; v_year int; v_unknown int;
  v_ended int; v_dupes int; v_offices int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2763000 AND -2762601;
  IF v_people <> 138 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 138 people in the reserved external_id block, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate');
  IF v_offices <> 138 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 138 Kentucky legislative offices, got % - run CC_0150 first', v_offices;
  END IF;

  SELECT count(*), count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_terms, v_day, v_year, v_unknown, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate');

  IF v_terms <> 138 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 138 terms, got %', v_terms;
  END IF;
  IF v_day <> 7 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 7 day-precision terms, got %', v_day;
  END IF;
  IF v_year <> 131 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 131 year-precision terms, got %', v_year;
  END IF;
  IF v_unknown <> 0 THEN
    RAISE EXCEPTION 'KY-2 occupancy: % term(s) have unknown precision; this wave dates every seat', v_unknown;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'KY-2 occupancy: % term(s) already ended; every seat here is currently held', v_ended;
  END IF;

  -- Count och.politician_id, never rows: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate');
  IF v_seated <> 138 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 138 seated, got %', v_seated;
  END IF;

  -- Nobody may hold two Kentucky legislative seats.
  SELECT count(*) INTO v_dupes FROM (
    SELECT ot.politician_id
      FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dupes <> 0 THEN
    RAISE EXCEPTION 'KY-2 occupancy: % person/people hold more than one Kentucky legislative seat', v_dupes;
  END IF;

  RAISE NOTICE 'KY-2 occupancy OK: 138 people, 138 terms, 138 seated, % day / % year / 0 unknown', v_day, v_year;
END $$;

COMMIT;
