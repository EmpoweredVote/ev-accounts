-- CC_0026_ga_legislature_incumbents.sql
-- Knight Foundation program, wave GA-2 (occupancy half).
--
-- Seats 235 Georgia legislators: 180 Representatives + 55 Senators.
-- 233 new politician rows + 2 REUSED. Senate District 12 gets NO person and NO term:
-- the structure migration flagged it vacant, and the reason is in that file's header.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 NO term_start IS ASSERTED, BECAUSE GEORGIA PUBLISHES NONE.
-- A Georgia member page carries name, district, party, city, capitol and district addresses,
-- staff, birthday and spouse -- and no service-start of any kind. Checked against a member who
-- arrived after a 2025-10-12 vacancy: the whole About block is "Birthday / Spouse". FL-2 could
-- lift continuous occupancy from each member's own "Legislative Service" line; there is no
-- equivalent here. So every term goes in OPEN-ENDED with start_precision 'unknown', which is
-- what the NC waves did for the same reason.
-- ⚠ The 2024 general election date is the start of the current TERM, not of continuous
-- occupancy, and re-election does not end an occupancy. Do not reach for it.
-- ⚠ Ballotpedia publishes assumed-office dates for some members. It is a third party, and this
-- wave does not write dates it cannot source from the body itself.
--
-- 🔴 IDENTITY IS KEYED ON external_id, AND A NAME MATCH IS NOT IDENTITY. Four roster names
-- already existed in production and only TWO of them are the same person:
--
--   Houston Gaines  -131001  REUSED. GA House D120, and our row is the GA-10 US House
--                            candidate he won the nomination for in May 2026. Same person;
--                            he already carries compass answers, so a second row would split him.
--   Jasmine Clark   -131301  REUSED. GA House D108, and our row is the GA-13 candidate.
--   John Carson     -810030  NOT REUSED -- that row is a COLORADO STATE SENATOR.
--   Kim Jackson     -364328  NOT REUSED -- that row is a UTAH COUNTY TREASURER.
--
-- The last two are the Robert Nash failure waiting to happen: a name-based guard would have
-- seated a Colorado senator and a Utah treasurer in the Georgia General Assembly. Both get a
-- fresh row here.
--
-- 🔴 NO NAME PARSING. Georgia publishes structured name parts (first / last / middle / suffix /
-- nickname), so first_name and last_name are taken from the source rather than split out of a
-- display string. splitName() is not involved, and the four shapes that would have broken it --
-- Reynaldo "Rey" Martinez, Noel Williams Jr., Regina Lewis-Ward, Holly El-Mahdi -- never need
-- splitting.
--
-- Party is deliberately absent. Party lives on races.primary_party, never on a person.
--
-- Idempotent: politicians are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate.

BEGIN;

-- ─── The people ──────────────────────────────────────────────────────────────

CREATE TEMP TABLE ga_people(ext_id int, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO ga_people(ext_id, full_name, first_name, last_name) VALUES
  (-1330001, 'Mike Cameron', 'Mike', 'Cameron'),
  (-1330002, 'Steve Tarvin', 'Steve', 'Tarvin'),
  (-1330003, 'Mitchell Horner', 'Mitchell', 'Horner'),
  (-1330004, 'Kasey Carpenter', 'Kasey', 'Carpenter'),
  (-1330005, 'Matt Barton', 'Matt', 'Barton'),
  (-1330006, 'Jason Ridley', 'Jason', 'Ridley'),
  (-1330007, 'Johnny Chastain', 'Johnny', 'Chastain'),
  (-1330008, 'Stan Gunter', 'Stan', 'Gunter'),
  (-1330009, 'Will Wade', 'Will', 'Wade'),
  (-1330010, 'Victor Anderson', 'Victor', 'Anderson'),
  (-1330011, 'Rick Jasperse', 'Rick', 'Jasperse'),
  (-1330012, 'Eddie Lumsden', 'Eddie', 'Lumsden'),
  (-1330013, 'Katie Dempsey', 'Katie', 'Dempsey'),
  (-1330014, 'Mitchell Scoggins', 'Mitchell', 'Scoggins'),
  (-1330015, 'Matthew Gambill', 'Matthew', 'Gambill'),
  (-1330016, 'Trey Kelley', 'Trey', 'Kelley'),
  (-1330017, 'Martin Momtahan', 'Martin', 'Momtahan'),
  (-1330018, 'Tyler Paul Smith', 'Tyler Paul', 'Smith'),
  (-1330019, 'Joseph Gullett', 'Joseph', 'Gullett'),
  (-1330020, 'Charlice Byrd', 'Charlice', 'Byrd'),
  (-1330021, 'Brad Thomas', 'Brad', 'Thomas'),
  (-1330022, 'Jordan Ridley', 'Jordan', 'Ridley'),
  (-1330023, 'Bill Fincher', 'Bill', 'Fincher'),
  (-1330024, 'Carter Barrett', 'Carter', 'Barrett'),
  (-1330025, 'Todd Jones', 'Todd', 'Jones'),
  (-1330026, 'Lauren McDonald III', 'Lauren', 'McDonald III'),
  (-1330027, 'Lee Hawkins', 'Lee', 'Hawkins'),
  (-1330028, 'Brent Cox', 'Brent', 'Cox'),
  (-1330029, 'Matt Dubnik', 'Matt', 'Dubnik'),
  (-1330030, 'Derrick McCollum', 'Derrick', 'McCollum'),
  (-1330031, 'Emory Dunahoo', 'Emory', 'Dunahoo'),
  (-1330032, 'Chris Erwin', 'Chris', 'Erwin'),
  (-1330033, 'Alan Powell', 'Alan', 'Powell'),
  (-1330034, 'Devan Seabaugh', 'Devan', 'Seabaugh'),
  (-1330035, 'Lisa Campbell', 'Lisa', 'Campbell'),
  (-1330036, 'Ginny Ehrhart', 'Ginny', 'Ehrhart'),
  (-1330037, 'Mary Frances Williams', 'Mary Frances', 'Williams'),
  (-1330038, 'David Wilkerson', 'David', 'Wilkerson'),
  (-1330039, 'Terry Cummings', 'Terry', 'Cummings'),
  (-1330040, 'Kimberly New', 'Kimberly', 'New'),
  (-1330041, 'Michael Smith', 'Michael', 'Smith'),
  (-1330042, 'Gabriel Sanchez', 'Gabriel', 'Sanchez'),
  (-1330043, 'Solomon Adesanya', 'Solomon', 'Adesanya'),
  (-1330044, 'Don Parsons', 'Don', 'Parsons'),
  (-1330045, 'Sharon Cooper', 'Sharon', 'Cooper'),
  (-1330046, 'John Carson', 'John', 'Carson'),
  (-1330047, 'Jan Jones', 'Jan', 'Jones'),
  (-1330048, 'Scott Hilton', 'Scott', 'Hilton'),
  (-1330049, 'Chuck Martin', 'Charles', 'Martin'),
  (-1330050, 'Michelle Au', 'Michelle', 'Au'),
  (-1330051, 'Esther Panitch', 'Esther', 'Panitch'),
  (-1330052, 'Shea Roberts', 'Shea', 'Roberts'),
  (-1330053, 'Deborah Silcox', 'Deborah', 'Silcox'),
  (-1330054, 'Betsy Holland', 'Betsy', 'Holland'),
  (-1330055, 'Inga Willis', 'Inga', 'Willis'),
  (-1330056, 'Bryce Berry', 'Bryce', 'Berry'),
  (-1330057, 'Stacey Evans', 'Stacey', 'Evans'),
  (-1330058, 'Park Cannon', 'Park', 'Cannon'),
  (-1330059, 'Phil Olaleye', 'Phil', 'Olaleye'),
  (-1330060, 'Sheila Jones', 'Sheila', 'Jones'),
  (-1330061, 'Mekyah McQueen', 'Mekyah', 'McQueen'),
  (-1330062, 'Tanya F. Miller', 'Tanya', 'Miller'),
  (-1330063, 'Kim Schofield', 'Kim', 'Schofield'),
  (-1330064, 'Sylvia Wayfer Baker', 'Sylvia Wayfer', 'Baker'),
  (-1330065, 'Robert Dawson', 'Robert', 'Dawson'),
  (-1330066, 'Kimberly Alexander', 'Kimberly', 'Alexander'),
  (-1330067, 'Lydia Glaize', 'Lydia', 'Glaize'),
  (-1330068, 'Derrick Jackson', 'Derrick', 'Jackson'),
  (-1330069, 'Debra Bazemore', 'Debra', 'Bazemore'),
  (-1330070, 'Lynn Smith', 'Lynn', 'Smith'),
  (-1330071, 'Jutt Howard', 'Justin', 'Howard'),
  (-1330072, 'David Huddleston', 'David', 'Huddleston'),
  (-1330073, 'Josh Bonner', 'Josh', 'Bonner'),
  (-1330074, 'Robert Flournoy', 'Robert', 'Flournoy'),
  (-1330075, 'Eric Bell', 'Eric', 'Bell'),
  (-1330076, 'Sandra Scott', 'Sandra', 'Scott'),
  (-1330077, 'Rhonda Burnough', 'Rhonda', 'Burnough'),
  (-1330078, 'Demetrius Douglas', 'Demetrius', 'Douglas'),
  (-1330079, 'Yasmin Neal', 'Yasmin', 'Neal'),
  (-1330080, 'Long Tran', 'Long', 'Tran'),
  (-1330081, 'Noelle Kahaian', 'Noelle', 'Kahaian'),
  (-1330082, 'Karen Mathiak', 'Karen', 'Mathiak'),
  (-1330083, 'Karen Lupton', 'Karen', 'Lupton'),
  (-1330084, 'Mary Margaret Oliver', 'Mary', 'Oliver'),
  (-1330085, 'Karla Drenner', 'Karla', 'Drenner'),
  (-1330086, 'Imani Barnes', 'Imani', 'Barnes'),
  (-1330087, 'Viola Davis', 'Viola', 'Davis'),
  (-1330088, 'Billy Mitchell', 'Billy', 'Mitchell'),
  (-1330089, 'Omari Crawford', 'Omari', 'Crawford'),
  (-1330090, 'Saira Draper', 'Saira', 'Draper'),
  (-1330091, 'Angela Moore', 'Angela', 'Moore'),
  (-1330092, 'Rhonda Taylor', 'Rhonda', 'Taylor'),
  (-1330093, 'Doreen Carter', 'Doreen', 'Carter'),
  (-1330094, 'Venola Mason', 'Venola', 'Mason'),
  (-1330095, 'Dar''shun Kendrick', 'Dar''shun', 'Kendrick'),
  (-1330096, 'Arlene Beckles', 'Arlene', 'Beckles'),
  (-1330097, 'Ruwa Romman', 'Ruwa', 'Romman'),
  (-1330098, 'Marvin Lim', 'Marvin', 'Lim'),
  (-1330099, 'Matt Reeves', 'Matt', 'Reeves'),
  (-1330100, 'David Clark', 'David', 'Clark'),
  (-1330101, 'Scott Holcomb', 'Scott', 'Holcomb'),
  (-1330102, 'Gabe Okoye', 'Gabe', 'Okoye'),
  (-1330103, 'Soo Hong', 'Soo', 'Hong'),
  (-1330104, 'Chuck Efstration', 'Chuck', 'Efstration'),
  (-1330105, 'Sandy Donatucci', 'Sandy', 'Donatucci'),
  (-1330106, 'Akbar Ali', 'Akbar', 'Ali'),
  (-1330107, 'Sam Park', 'Sam', 'Park'),
  (-1330109, 'Dewey McClain', 'Dewey', 'McClain'),
  (-1330110, 'Segun Adeyina', 'Segun', 'Adeyina'),
  (-1330111, 'Reynaldo "Rey" Martinez', 'Reynaldo', 'Martinez'),
  (-1330112, 'Bruce Williamson', 'Bruce', 'Williamson'),
  (-1330113, 'Sharon Henderson', 'Sharon', 'Henderson'),
  (-1330114, 'Tim Fleming', 'Tim', 'Fleming'),
  (-1330115, 'Regina Lewis-Ward', 'Regina', 'Lewis-Ward'),
  (-1330116, 'El-Mahdi Holly', 'El-Mahdi', 'Holly'),
  (-1330117, 'Mary Ann Santos', 'Mary Ann', 'Santos'),
  (-1330118, 'Clint Crowe', 'Clint', 'Crowe'),
  (-1330119, 'Holt Persinger', 'Holt', 'Persinger'),
  (-1330121, 'Eric Gisler', 'Eric', 'Gisler'),
  (-1330122, 'Spencer Frye', 'Spencer', 'Frye'),
  (-1330123, 'Rob Leverett', 'Rob', 'Leverett'),
  (-1330124, 'Trey Rhodes', 'Trey', 'Rhodes'),
  (-1330125, 'Gary Richardson', 'Gary', 'Richardson'),
  (-1330126, 'L.C. Myles', 'L.C.', 'Myles'),
  (-1330127, 'Mark Newton', 'Mark', 'Newton'),
  (-1330128, 'Mack Jackson', 'Mack', 'Jackson'),
  (-1330129, 'Karlton Howard', 'Karlton', 'Howard'),
  (-1330130, 'Sheila Nelson', 'Sheila', 'Nelson'),
  (-1330131, 'Rob Clifton', 'Rob', 'Clifton'),
  (-1330132, 'Brian Prince', 'Brian', 'Prince'),
  (-1330133, 'Danny Mathis', 'Danny', 'Mathis'),
  (-1330134, 'Robert Dickey', 'Robert', 'Dickey'),
  (-1330135, 'Beth Camp', 'Beth', 'Camp'),
  (-1330136, 'David Jenkins', 'David', 'Jenkins'),
  (-1330137, 'Debbie Buckner', 'Debbie', 'Buckner'),
  (-1330138, 'Vance Smith', 'Vance', 'Smith'),
  (-1330139, 'Carmen Rice', 'Carmen', 'Rice'),
  (-1330140, 'Tremaine Teddy Reese', 'Tremaine', 'Reese'),
  (-1330141, 'Carolyn Hugley', 'Carolyn', 'Hugley'),
  (-1330142, 'Miriam Paris', 'Miriam', 'Paris'),
  (-1330143, 'Anissa Jones', 'Anissa', 'Jones'),
  (-1330144, 'Dale Washburn', 'Dale', 'Washburn'),
  (-1330145, 'Tangie Herring', 'Tangie', 'Herring'),
  (-1330146, 'Shaw Blackmon', 'Shaw', 'Blackmon'),
  (-1330147, 'Bethany Ballard', 'Bethany', 'Ballard'),
  (-1330148, 'Noel Williams, Jr.', 'Noel', 'Williams, Jr.'),
  (-1330149, 'Floyd Griffin', 'Floyd', 'Griffin'),
  (-1330150, 'Patty Marie Stinson', 'Patty Marie', 'Stinson'),
  (-1330151, 'Mike Cheokas', 'Mike', 'Cheokas'),
  (-1330152, 'Bill Yearta', 'Bill', 'Yearta'),
  (-1330153, 'David Sampson', 'David', 'Sampson'),
  (-1330154, 'Gerald Greene', 'Gerald', 'Greene'),
  (-1330155, 'Matt Hatchett', 'Matt', 'Hatchett'),
  (-1330156, 'Leesa Hagan', 'Leesa', 'Hagan'),
  (-1330157, 'Bill Werkheiser', 'Bill', 'Werkheiser'),
  (-1330158, 'Butch Parrish', 'Butch', 'Parrish'),
  (-1330159, 'Jon Burns', 'Jon', 'Burns'),
  (-1330160, 'Lehman Franklin', 'Lehman', 'Franklin'),
  (-1330161, 'Bill Hitchens', 'Bill', 'Hitchens'),
  (-1330162, 'Carl Gilliard', 'Carl', 'Gilliard'),
  (-1330163, 'Anne Allen Westbrook', 'Anne Allen', 'Westbrook'),
  (-1330164, 'Ron Stephens', 'Ron', 'Stephens'),
  (-1330165, 'Edna Jackson', 'Edna', 'Jackson'),
  (-1330166, 'Jesse Petrea', 'Jesse', 'Petrea'),
  (-1330167, 'Buddy DeLoach', 'Buddy', 'DeLoach'),
  (-1330168, 'Al Williams', 'Al', 'Williams'),
  (-1330169, 'Angie O''Steen', 'Angie', 'O''Steen'),
  (-1330170, 'Jaclyn Ford', 'Jaclyn', 'Ford'),
  (-1330171, 'Joe Campbell', 'Joe', 'Campbell'),
  (-1330172, 'Chas Cannon', 'Chas', 'Cannon'),
  (-1330173, 'Darlene Taylor', 'Darlene', 'Taylor'),
  (-1330174, 'John Corbett', 'John', 'Corbett'),
  (-1330175, 'John LaHood', 'John', 'LaHood'),
  (-1330176, 'James Burchett', 'James', 'Burchett'),
  (-1330177, 'Alvin Payton', 'Alvin', 'Payton'),
  (-1330178, 'Steven Meeks', 'Steven', 'Meeks'),
  (-1330179, 'Rick Townsend', 'Rick', 'Townsend'),
  (-1330180, 'Steven Sainz', 'Steven', 'Sainz'),
  (-1330201, 'Ben Watson', 'Ben', 'Watson'),
  (-1330202, 'Derek Mallow', 'Derek', 'Mallow'),
  (-1330203, 'Mike Hodges', 'Mike', 'Hodges'),
  (-1330204, 'Billy Hickman', 'Billy', 'Hickman'),
  (-1330205, 'Sheikh Rahman', 'Sheikh', 'Rahman'),
  (-1330206, 'Matt Brass', 'Matt', 'Brass'),
  (-1330207, 'Adrienne White Carden', 'Adrienne White', 'Carden'),
  (-1330208, 'Russ Goodman', 'Russ', 'Goodman'),
  (-1330209, 'Nikki Merritt', 'Nikki', 'Merritt'),
  (-1330210, 'Emanuel Jones', 'Emanuel', 'Jones'),
  (-1330211, 'Sam Watson', 'Sam', 'Watson'),
  (-1330213, 'Carden Summers', 'Carden', 'Summers'),
  (-1330214, 'Josh McLaurin', 'Josh', 'McLaurin'),
  (-1330215, 'Ed Harbison', 'Ed', 'Harbison'),
  (-1330216, 'Marty Harbin', 'Marty', 'Harbin'),
  (-1330217, 'Gail Davenport', 'Gail', 'Davenport'),
  (-1330218, 'Steven McNeel', 'Steven', 'McNeel'),
  (-1330219, 'Blake Tillery', 'Blake', 'Tillery'),
  (-1330220, 'Larry Walker, III', 'Larry', 'Walker, III'),
  (-1330221, 'Jason T. Dickerson', 'Jason T.', 'Dickerson'),
  (-1330222, 'Harold Jones II', 'Harold', 'Jones II'),
  (-1330223, 'Max Burns', 'Max', 'Burns'),
  (-1330224, 'Lee Anderson', 'Lee', 'Anderson'),
  (-1330225, 'Rick Williams', 'Rick', 'Williams'),
  (-1330226, 'David Lucas', 'David', 'Lucas'),
  (-1330227, 'Greg Dolezal', 'Greg', 'Dolezal'),
  (-1330228, 'Donzella James', 'Donzella', 'James'),
  (-1330229, 'Randy Robertson', 'Randy', 'Robertson'),
  (-1330230, 'Timothy Bearden', 'Timothy', 'Bearden'),
  (-1330231, 'Jason Anavitarte', 'Jason', 'Anavitarte'),
  (-1330232, 'Kay Kirkpatrick', 'Kay', 'Kirkpatrick'),
  (-1330233, 'Michael ''Doc'' Rhett', 'Michael ''Doc''', 'Rhett'),
  (-1330234, 'Kenya Wicks', 'Kenya', 'Wicks'),
  (-1330235, 'Jaha Howard', 'Jaha', 'Howard'),
  (-1330236, 'Nan Orrock', 'Nan', 'Orrock'),
  (-1330237, 'Ed Setzler', 'Ed', 'Setzler'),
  (-1330238, 'RaShaun Kemp', 'RaShaun', 'Kemp'),
  (-1330239, 'Sonya Halpern', 'Sonya', 'Halpern'),
  (-1330240, 'Sally Harrell', 'Sally', 'Harrell'),
  (-1330241, 'Kim Jackson', 'Kim', 'Jackson'),
  (-1330242, 'Brian Strickland', 'Brian', 'Strickland'),
  (-1330243, 'Tonya Anderson', 'Tonya', 'Anderson'),
  (-1330244, 'Elena Parent', 'Elena', 'Parent'),
  (-1330245, 'Clint Dixon', 'Clint', 'Dixon'),
  (-1330246, 'Bill Cowsert', 'Bill', 'Cowsert'),
  (-1330247, 'Frank Ginn', 'Frank', 'Ginn'),
  (-1330248, 'Shawn Still', 'Shawn', 'Still'),
  (-1330249, 'Drew Echols', 'Drew', 'Echols'),
  (-1330250, 'Bo Hatchett', 'Bo', 'Hatchett'),
  (-1330251, 'Steve Gooch', 'Steve', 'Gooch'),
  (-1330252, 'Chuck Hufstetler', 'Chuck', 'Hufstetler'),
  (-1330253, 'Lanny Thomas', 'Lanny', 'Thomas'),
  (-1330254, 'Chuck Payne', 'Chuck', 'Payne'),
  (-1330255, 'Randal Mangham', 'Randal', 'Mangham'),
  (-1330256, 'John Albers', 'John', 'Albers');

CREATE TEMP TABLE ga_seats(ext_id int, geo_id text, district_type text, full_name text) ON COMMIT DROP;
INSERT INTO ga_seats(ext_id, geo_id, district_type, full_name) VALUES
  (-1330001, '13001', 'STATE_LOWER', 'Mike Cameron'),
  (-1330002, '13002', 'STATE_LOWER', 'Steve Tarvin'),
  (-1330003, '13003', 'STATE_LOWER', 'Mitchell Horner'),
  (-1330004, '13004', 'STATE_LOWER', 'Kasey Carpenter'),
  (-1330005, '13005', 'STATE_LOWER', 'Matt Barton'),
  (-1330006, '13006', 'STATE_LOWER', 'Jason Ridley'),
  (-1330007, '13007', 'STATE_LOWER', 'Johnny Chastain'),
  (-1330008, '13008', 'STATE_LOWER', 'Stan Gunter'),
  (-1330009, '13009', 'STATE_LOWER', 'Will Wade'),
  (-1330010, '13010', 'STATE_LOWER', 'Victor Anderson'),
  (-1330011, '13011', 'STATE_LOWER', 'Rick Jasperse'),
  (-1330012, '13012', 'STATE_LOWER', 'Eddie Lumsden'),
  (-1330013, '13013', 'STATE_LOWER', 'Katie Dempsey'),
  (-1330014, '13014', 'STATE_LOWER', 'Mitchell Scoggins'),
  (-1330015, '13015', 'STATE_LOWER', 'Matthew Gambill'),
  (-1330016, '13016', 'STATE_LOWER', 'Trey Kelley'),
  (-1330017, '13017', 'STATE_LOWER', 'Martin Momtahan'),
  (-1330018, '13018', 'STATE_LOWER', 'Tyler Paul Smith'),
  (-1330019, '13019', 'STATE_LOWER', 'Joseph Gullett'),
  (-1330020, '13020', 'STATE_LOWER', 'Charlice Byrd'),
  (-1330021, '13021', 'STATE_LOWER', 'Brad Thomas'),
  (-1330022, '13022', 'STATE_LOWER', 'Jordan Ridley'),
  (-1330023, '13023', 'STATE_LOWER', 'Bill Fincher'),
  (-1330024, '13024', 'STATE_LOWER', 'Carter Barrett'),
  (-1330025, '13025', 'STATE_LOWER', 'Todd Jones'),
  (-1330026, '13026', 'STATE_LOWER', 'Lauren McDonald III'),
  (-1330027, '13027', 'STATE_LOWER', 'Lee Hawkins'),
  (-1330028, '13028', 'STATE_LOWER', 'Brent Cox'),
  (-1330029, '13029', 'STATE_LOWER', 'Matt Dubnik'),
  (-1330030, '13030', 'STATE_LOWER', 'Derrick McCollum'),
  (-1330031, '13031', 'STATE_LOWER', 'Emory Dunahoo'),
  (-1330032, '13032', 'STATE_LOWER', 'Chris Erwin'),
  (-1330033, '13033', 'STATE_LOWER', 'Alan Powell'),
  (-1330034, '13034', 'STATE_LOWER', 'Devan Seabaugh'),
  (-1330035, '13035', 'STATE_LOWER', 'Lisa Campbell'),
  (-1330036, '13036', 'STATE_LOWER', 'Ginny Ehrhart'),
  (-1330037, '13037', 'STATE_LOWER', 'Mary Frances Williams'),
  (-1330038, '13038', 'STATE_LOWER', 'David Wilkerson'),
  (-1330039, '13039', 'STATE_LOWER', 'Terry Cummings'),
  (-1330040, '13040', 'STATE_LOWER', 'Kimberly New'),
  (-1330041, '13041', 'STATE_LOWER', 'Michael Smith'),
  (-1330042, '13042', 'STATE_LOWER', 'Gabriel Sanchez'),
  (-1330043, '13043', 'STATE_LOWER', 'Solomon Adesanya'),
  (-1330044, '13044', 'STATE_LOWER', 'Don Parsons'),
  (-1330045, '13045', 'STATE_LOWER', 'Sharon Cooper'),
  (-1330046, '13046', 'STATE_LOWER', 'John Carson'),
  (-1330047, '13047', 'STATE_LOWER', 'Jan Jones'),
  (-1330048, '13048', 'STATE_LOWER', 'Scott Hilton'),
  (-1330049, '13049', 'STATE_LOWER', 'Chuck Martin'),
  (-1330050, '13050', 'STATE_LOWER', 'Michelle Au'),
  (-1330051, '13051', 'STATE_LOWER', 'Esther Panitch'),
  (-1330052, '13052', 'STATE_LOWER', 'Shea Roberts'),
  (-1330053, '13053', 'STATE_LOWER', 'Deborah Silcox'),
  (-1330054, '13054', 'STATE_LOWER', 'Betsy Holland'),
  (-1330055, '13055', 'STATE_LOWER', 'Inga Willis'),
  (-1330056, '13056', 'STATE_LOWER', 'Bryce Berry'),
  (-1330057, '13057', 'STATE_LOWER', 'Stacey Evans'),
  (-1330058, '13058', 'STATE_LOWER', 'Park Cannon'),
  (-1330059, '13059', 'STATE_LOWER', 'Phil Olaleye'),
  (-1330060, '13060', 'STATE_LOWER', 'Sheila Jones'),
  (-1330061, '13061', 'STATE_LOWER', 'Mekyah McQueen'),
  (-1330062, '13062', 'STATE_LOWER', 'Tanya F. Miller'),
  (-1330063, '13063', 'STATE_LOWER', 'Kim Schofield'),
  (-1330064, '13064', 'STATE_LOWER', 'Sylvia Wayfer Baker'),
  (-1330065, '13065', 'STATE_LOWER', 'Robert Dawson'),
  (-1330066, '13066', 'STATE_LOWER', 'Kimberly Alexander'),
  (-1330067, '13067', 'STATE_LOWER', 'Lydia Glaize'),
  (-1330068, '13068', 'STATE_LOWER', 'Derrick Jackson'),
  (-1330069, '13069', 'STATE_LOWER', 'Debra Bazemore'),
  (-1330070, '13070', 'STATE_LOWER', 'Lynn Smith'),
  (-1330071, '13071', 'STATE_LOWER', 'Jutt Howard'),
  (-1330072, '13072', 'STATE_LOWER', 'David Huddleston'),
  (-1330073, '13073', 'STATE_LOWER', 'Josh Bonner'),
  (-1330074, '13074', 'STATE_LOWER', 'Robert Flournoy'),
  (-1330075, '13075', 'STATE_LOWER', 'Eric Bell'),
  (-1330076, '13076', 'STATE_LOWER', 'Sandra Scott'),
  (-1330077, '13077', 'STATE_LOWER', 'Rhonda Burnough'),
  (-1330078, '13078', 'STATE_LOWER', 'Demetrius Douglas'),
  (-1330079, '13079', 'STATE_LOWER', 'Yasmin Neal'),
  (-1330080, '13080', 'STATE_LOWER', 'Long Tran'),
  (-1330081, '13081', 'STATE_LOWER', 'Noelle Kahaian'),
  (-1330082, '13082', 'STATE_LOWER', 'Karen Mathiak'),
  (-1330083, '13083', 'STATE_LOWER', 'Karen Lupton'),
  (-1330084, '13084', 'STATE_LOWER', 'Mary Margaret Oliver'),
  (-1330085, '13085', 'STATE_LOWER', 'Karla Drenner'),
  (-1330086, '13086', 'STATE_LOWER', 'Imani Barnes'),
  (-1330087, '13087', 'STATE_LOWER', 'Viola Davis'),
  (-1330088, '13088', 'STATE_LOWER', 'Billy Mitchell'),
  (-1330089, '13089', 'STATE_LOWER', 'Omari Crawford'),
  (-1330090, '13090', 'STATE_LOWER', 'Saira Draper'),
  (-1330091, '13091', 'STATE_LOWER', 'Angela Moore'),
  (-1330092, '13092', 'STATE_LOWER', 'Rhonda Taylor'),
  (-1330093, '13093', 'STATE_LOWER', 'Doreen Carter'),
  (-1330094, '13094', 'STATE_LOWER', 'Venola Mason'),
  (-1330095, '13095', 'STATE_LOWER', 'Dar''shun Kendrick'),
  (-1330096, '13096', 'STATE_LOWER', 'Arlene Beckles'),
  (-1330097, '13097', 'STATE_LOWER', 'Ruwa Romman'),
  (-1330098, '13098', 'STATE_LOWER', 'Marvin Lim'),
  (-1330099, '13099', 'STATE_LOWER', 'Matt Reeves'),
  (-1330100, '13100', 'STATE_LOWER', 'David Clark'),
  (-1330101, '13101', 'STATE_LOWER', 'Scott Holcomb'),
  (-1330102, '13102', 'STATE_LOWER', 'Gabe Okoye'),
  (-1330103, '13103', 'STATE_LOWER', 'Soo Hong'),
  (-1330104, '13104', 'STATE_LOWER', 'Chuck Efstration'),
  (-1330105, '13105', 'STATE_LOWER', 'Sandy Donatucci'),
  (-1330106, '13106', 'STATE_LOWER', 'Akbar Ali'),
  (-1330107, '13107', 'STATE_LOWER', 'Sam Park'),
  (-131301, '13108', 'STATE_LOWER', 'Jasmine Clark'),
  (-1330109, '13109', 'STATE_LOWER', 'Dewey McClain'),
  (-1330110, '13110', 'STATE_LOWER', 'Segun Adeyina'),
  (-1330111, '13111', 'STATE_LOWER', 'Reynaldo "Rey" Martinez'),
  (-1330112, '13112', 'STATE_LOWER', 'Bruce Williamson'),
  (-1330113, '13113', 'STATE_LOWER', 'Sharon Henderson'),
  (-1330114, '13114', 'STATE_LOWER', 'Tim Fleming'),
  (-1330115, '13115', 'STATE_LOWER', 'Regina Lewis-Ward'),
  (-1330116, '13116', 'STATE_LOWER', 'El-Mahdi Holly'),
  (-1330117, '13117', 'STATE_LOWER', 'Mary Ann Santos'),
  (-1330118, '13118', 'STATE_LOWER', 'Clint Crowe'),
  (-1330119, '13119', 'STATE_LOWER', 'Holt Persinger'),
  (-131001, '13120', 'STATE_LOWER', 'Houston Gaines'),
  (-1330121, '13121', 'STATE_LOWER', 'Eric Gisler'),
  (-1330122, '13122', 'STATE_LOWER', 'Spencer Frye'),
  (-1330123, '13123', 'STATE_LOWER', 'Rob Leverett'),
  (-1330124, '13124', 'STATE_LOWER', 'Trey Rhodes'),
  (-1330125, '13125', 'STATE_LOWER', 'Gary Richardson'),
  (-1330126, '13126', 'STATE_LOWER', 'L.C. Myles'),
  (-1330127, '13127', 'STATE_LOWER', 'Mark Newton'),
  (-1330128, '13128', 'STATE_LOWER', 'Mack Jackson'),
  (-1330129, '13129', 'STATE_LOWER', 'Karlton Howard'),
  (-1330130, '13130', 'STATE_LOWER', 'Sheila Nelson'),
  (-1330131, '13131', 'STATE_LOWER', 'Rob Clifton'),
  (-1330132, '13132', 'STATE_LOWER', 'Brian Prince'),
  (-1330133, '13133', 'STATE_LOWER', 'Danny Mathis'),
  (-1330134, '13134', 'STATE_LOWER', 'Robert Dickey'),
  (-1330135, '13135', 'STATE_LOWER', 'Beth Camp'),
  (-1330136, '13136', 'STATE_LOWER', 'David Jenkins'),
  (-1330137, '13137', 'STATE_LOWER', 'Debbie Buckner'),
  (-1330138, '13138', 'STATE_LOWER', 'Vance Smith'),
  (-1330139, '13139', 'STATE_LOWER', 'Carmen Rice'),
  (-1330140, '13140', 'STATE_LOWER', 'Tremaine Teddy Reese'),
  (-1330141, '13141', 'STATE_LOWER', 'Carolyn Hugley'),
  (-1330142, '13142', 'STATE_LOWER', 'Miriam Paris'),
  (-1330143, '13143', 'STATE_LOWER', 'Anissa Jones'),
  (-1330144, '13144', 'STATE_LOWER', 'Dale Washburn'),
  (-1330145, '13145', 'STATE_LOWER', 'Tangie Herring'),
  (-1330146, '13146', 'STATE_LOWER', 'Shaw Blackmon'),
  (-1330147, '13147', 'STATE_LOWER', 'Bethany Ballard'),
  (-1330148, '13148', 'STATE_LOWER', 'Noel Williams, Jr.'),
  (-1330149, '13149', 'STATE_LOWER', 'Floyd Griffin'),
  (-1330150, '13150', 'STATE_LOWER', 'Patty Marie Stinson'),
  (-1330151, '13151', 'STATE_LOWER', 'Mike Cheokas'),
  (-1330152, '13152', 'STATE_LOWER', 'Bill Yearta'),
  (-1330153, '13153', 'STATE_LOWER', 'David Sampson'),
  (-1330154, '13154', 'STATE_LOWER', 'Gerald Greene'),
  (-1330155, '13155', 'STATE_LOWER', 'Matt Hatchett'),
  (-1330156, '13156', 'STATE_LOWER', 'Leesa Hagan'),
  (-1330157, '13157', 'STATE_LOWER', 'Bill Werkheiser'),
  (-1330158, '13158', 'STATE_LOWER', 'Butch Parrish'),
  (-1330159, '13159', 'STATE_LOWER', 'Jon Burns'),
  (-1330160, '13160', 'STATE_LOWER', 'Lehman Franklin'),
  (-1330161, '13161', 'STATE_LOWER', 'Bill Hitchens'),
  (-1330162, '13162', 'STATE_LOWER', 'Carl Gilliard'),
  (-1330163, '13163', 'STATE_LOWER', 'Anne Allen Westbrook'),
  (-1330164, '13164', 'STATE_LOWER', 'Ron Stephens'),
  (-1330165, '13165', 'STATE_LOWER', 'Edna Jackson'),
  (-1330166, '13166', 'STATE_LOWER', 'Jesse Petrea'),
  (-1330167, '13167', 'STATE_LOWER', 'Buddy DeLoach'),
  (-1330168, '13168', 'STATE_LOWER', 'Al Williams'),
  (-1330169, '13169', 'STATE_LOWER', 'Angie O''Steen'),
  (-1330170, '13170', 'STATE_LOWER', 'Jaclyn Ford'),
  (-1330171, '13171', 'STATE_LOWER', 'Joe Campbell'),
  (-1330172, '13172', 'STATE_LOWER', 'Chas Cannon'),
  (-1330173, '13173', 'STATE_LOWER', 'Darlene Taylor'),
  (-1330174, '13174', 'STATE_LOWER', 'John Corbett'),
  (-1330175, '13175', 'STATE_LOWER', 'John LaHood'),
  (-1330176, '13176', 'STATE_LOWER', 'James Burchett'),
  (-1330177, '13177', 'STATE_LOWER', 'Alvin Payton'),
  (-1330178, '13178', 'STATE_LOWER', 'Steven Meeks'),
  (-1330179, '13179', 'STATE_LOWER', 'Rick Townsend'),
  (-1330180, '13180', 'STATE_LOWER', 'Steven Sainz'),
  (-1330201, '13001', 'STATE_UPPER', 'Ben Watson'),
  (-1330202, '13002', 'STATE_UPPER', 'Derek Mallow'),
  (-1330203, '13003', 'STATE_UPPER', 'Mike Hodges'),
  (-1330204, '13004', 'STATE_UPPER', 'Billy Hickman'),
  (-1330205, '13005', 'STATE_UPPER', 'Sheikh Rahman'),
  (-1330206, '13006', 'STATE_UPPER', 'Matt Brass'),
  (-1330207, '13007', 'STATE_UPPER', 'Adrienne White Carden'),
  (-1330208, '13008', 'STATE_UPPER', 'Russ Goodman'),
  (-1330209, '13009', 'STATE_UPPER', 'Nikki Merritt'),
  (-1330210, '13010', 'STATE_UPPER', 'Emanuel Jones'),
  (-1330211, '13011', 'STATE_UPPER', 'Sam Watson'),
  (-1330213, '13013', 'STATE_UPPER', 'Carden Summers'),
  (-1330214, '13014', 'STATE_UPPER', 'Josh McLaurin'),
  (-1330215, '13015', 'STATE_UPPER', 'Ed Harbison'),
  (-1330216, '13016', 'STATE_UPPER', 'Marty Harbin'),
  (-1330217, '13017', 'STATE_UPPER', 'Gail Davenport'),
  (-1330218, '13018', 'STATE_UPPER', 'Steven McNeel'),
  (-1330219, '13019', 'STATE_UPPER', 'Blake Tillery'),
  (-1330220, '13020', 'STATE_UPPER', 'Larry Walker, III'),
  (-1330221, '13021', 'STATE_UPPER', 'Jason T. Dickerson'),
  (-1330222, '13022', 'STATE_UPPER', 'Harold Jones II'),
  (-1330223, '13023', 'STATE_UPPER', 'Max Burns'),
  (-1330224, '13024', 'STATE_UPPER', 'Lee Anderson'),
  (-1330225, '13025', 'STATE_UPPER', 'Rick Williams'),
  (-1330226, '13026', 'STATE_UPPER', 'David Lucas'),
  (-1330227, '13027', 'STATE_UPPER', 'Greg Dolezal'),
  (-1330228, '13028', 'STATE_UPPER', 'Donzella James'),
  (-1330229, '13029', 'STATE_UPPER', 'Randy Robertson'),
  (-1330230, '13030', 'STATE_UPPER', 'Timothy Bearden'),
  (-1330231, '13031', 'STATE_UPPER', 'Jason Anavitarte'),
  (-1330232, '13032', 'STATE_UPPER', 'Kay Kirkpatrick'),
  (-1330233, '13033', 'STATE_UPPER', 'Michael ''Doc'' Rhett'),
  (-1330234, '13034', 'STATE_UPPER', 'Kenya Wicks'),
  (-1330235, '13035', 'STATE_UPPER', 'Jaha Howard'),
  (-1330236, '13036', 'STATE_UPPER', 'Nan Orrock'),
  (-1330237, '13037', 'STATE_UPPER', 'Ed Setzler'),
  (-1330238, '13038', 'STATE_UPPER', 'RaShaun Kemp'),
  (-1330239, '13039', 'STATE_UPPER', 'Sonya Halpern'),
  (-1330240, '13040', 'STATE_UPPER', 'Sally Harrell'),
  (-1330241, '13041', 'STATE_UPPER', 'Kim Jackson'),
  (-1330242, '13042', 'STATE_UPPER', 'Brian Strickland'),
  (-1330243, '13043', 'STATE_UPPER', 'Tonya Anderson'),
  (-1330244, '13044', 'STATE_UPPER', 'Elena Parent'),
  (-1330245, '13045', 'STATE_UPPER', 'Clint Dixon'),
  (-1330246, '13046', 'STATE_UPPER', 'Bill Cowsert'),
  (-1330247, '13047', 'STATE_UPPER', 'Frank Ginn'),
  (-1330248, '13048', 'STATE_UPPER', 'Shawn Still'),
  (-1330249, '13049', 'STATE_UPPER', 'Drew Echols'),
  (-1330250, '13050', 'STATE_UPPER', 'Bo Hatchett'),
  (-1330251, '13051', 'STATE_UPPER', 'Steve Gooch'),
  (-1330252, '13052', 'STATE_UPPER', 'Chuck Hufstetler'),
  (-1330253, '13053', 'STATE_UPPER', 'Lanny Thomas'),
  (-1330254, '13054', 'STATE_UPPER', 'Chuck Payne'),
  (-1330255, '13055', 'STATE_UPPER', 'Randal Mangham'),
  (-1330256, '13056', 'STATE_UPPER', 'John Albers');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ga_people;
  IF n <> 233 THEN RAISE EXCEPTION 'payload: expected 233 new people, got %', n; END IF;
  SELECT count(*) INTO n FROM ga_seats;
  IF n <> 235 THEN RAISE EXCEPTION 'payload: expected 235 seats, got %', n; END IF;
  SELECT count(*) INTO n FROM (SELECT ext_id FROM ga_people GROUP BY ext_id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'payload: % duplicate external_id(s)', n; END IF;

  -- 🔴 BAND GUARD, IN THE SHAPE FL-6 ARRIVED AT: every new id inside the new sub-range, and
  -- exactly the declared reuses outside it -- asserted POSITIVELY, by id and by name.
  SELECT count(*) INTO n FROM ga_people WHERE ext_id NOT BETWEEN -1330256 AND -1330001;
  IF n <> 0 THEN RAISE EXCEPTION '% new id(s) fall outside the GA-2 band', n; END IF;

  SELECT count(*) INTO n FROM ga_seats WHERE ext_id NOT BETWEEN -1330256 AND -1330001;
  IF n <> 2 THEN RAISE EXCEPTION 'expected exactly 2 reused id(s) outside the band, got %', n; END IF;

  -- Each reused id must ALREADY exist and still be the person we checked.
  SELECT count(*) INTO n FROM essentials.politicians WHERE external_id = -131001 AND full_name = 'Houston Gaines';
  IF n <> 1 THEN RAISE EXCEPTION 'reuse -131001 does not resolve to a single Houston Gaines -- re-verify identity before proceeding'; END IF;
  SELECT count(*) INTO n FROM essentials.politicians WHERE external_id = -131301 AND full_name = 'Jasmine Clark';
  IF n <> 1 THEN RAISE EXCEPTION 'reuse -131301 does not resolve to a single Jasmine Clark -- re-verify identity before proceeding'; END IF;

  -- And the two look-alikes must NOT be reused.
  SELECT count(*) INTO n FROM ga_people WHERE ext_id IN (-810030, -364328);
  IF n <> 0 THEN RAISE EXCEPTION 'a Colorado senator or a Utah treasurer is being written as a Georgia legislator'; END IF;
END $$;

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, is_active, is_incumbent,
        alternate_names, photo_custom_url_manual_override, bio_text_manual_override,
        full_name_manual_override)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, true, true, '{}', false, false, false
  FROM ga_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

-- ─── The terms ───────────────────────────────────────────────────────────────
-- Open-ended, start_precision 'unknown'. See the header: Georgia publishes no service-start.

INSERT INTO essentials.office_terms
       (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT o.id, p.id, NULL, 'unknown', 'unknown', 'Georgia General Assembly member list, https://www.legis.ga.gov/members/{house,senate}, reconciled against the Find Your Legislator district map, read 2026-08-31 (CC_0026, GA-2)'
  FROM ga_seats s
  JOIN essentials.districts d
    ON d.geo_id = s.geo_id AND d.district_type = s.district_type AND lower(d.state) = 'ga'
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.politicians p ON p.external_id = s.ext_id
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

-- ─── Post-verify ─────────────────────────────────────────────────────────────

DO $$
DECLARE n_seated int; n_off int; n_wrong int; n_sd12 int;
BEGIN
  -- office_current_holder LEFT JOINs from offices, so a vacancy is a NULL politician_id, never
  -- an absent row. Count the politician_id.
  SELECT count(*), count(och.politician_id) INTO n_off, n_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'ga' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> 236 THEN RAISE EXCEPTION 'expected 236 GA legislative offices, got %', n_off; END IF;
  IF n_seated <> 235 THEN RAISE EXCEPTION 'expected 235 seated, got %', n_seated; END IF;

  -- The right person in the right seat, for every one of them.
  SELECT count(*) INTO n_wrong
    FROM ga_seats s
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id AND d.district_type = s.district_type AND lower(d.state) = 'ga'
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.full_name IS DISTINCT FROM s.full_name;
  IF n_wrong <> 0 THEN RAISE EXCEPTION '% Georgia legislative seat(s) hold the wrong person', n_wrong; END IF;

  -- SD-12 must hold NOBODY and stay flagged.
  SELECT count(och.politician_id) INTO n_sd12
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.geo_id = '13012' AND d.district_type = 'STATE_UPPER' AND lower(d.state) = 'ga';
  IF n_sd12 <> 0 THEN RAISE EXCEPTION 'SD-12 was seated; it is vacant'; END IF;

  RAISE NOTICE 'OK: 235 Georgia legislators seated across 236 offices; SD-12 vacant';
END $$;

COMMIT;
