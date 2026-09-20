-- CC_0126_sc_legislature_incumbents.sql
-- Knight Foundation program, wave SC-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0125, which creates the chambers and the 170 offices.
--
-- Seats all 170 of South Carolina's legislative offices:
--    169 people created here, external_id band -2745200 .. -2745001
--    1 person REUSED from a row production already holds
--    0 offices left unseated — neither chamber has a vacancy today
--
-- 🔴🔴 17 TERMS ARE DATED, AND THE DATE IS THE OATH, NOT THE ELECTION. A member page that
-- says "Elected in Special Election June 3, 2025" is not saying when that person took the seat:
-- HD-50's oath was administered on 2026-01-13, SEVEN MONTHS later, because the House was not
-- sitting in between. A member-elect is not a member. Every date below was read out of that
-- chamber's own journal by scripts/find-sc-oath-dates.mjs:
--     H-18   2022-06-15  T. Alan Morgan, Jr.
--     H-19   2020-01-14  Patrick B. Haddon
--     H-21   2026-01-13  Dianne Mitchell
--     H-50   2026-01-13  Keishan M. Scott
--     H-69   2018-05-08  Chris Wooten
--     H-84   2020-01-14  Melissa Lackey Oremus
--     H-88   2026-01-13  John T. Lastinger, Jr.
--     H-97   2022-06-15  Robby Robbins
--     H-98   2026-01-13  Greg Ford
--     H-100  2016-06-15  Sylleste H. Davis
--     H-109  2024-04-09  Tiffany R. Spann-Wilder
--     H-115  2020-09-15  Elizabeth "Spencer" Wetmore
--     S-3    2017-06-06  Richard J. Cash
--     S-12   2026-01-13  Lee Bright
--     S-19   2024-01-09  Tameika Isaac Devine
--     S-31   2022-04-05  Mike Reichenbach
--     S-45   2016-01-13  Margie Bright Matthews
--
-- 🔴 THE REMAINING 153 SEATS HAVE NO term_start TO BE HAD, AND NONE IS INVENTED. Neither
-- chamber publishes a service-start date for a member who arrived at a general election, and
-- "first elected" is not a term start in either direction. Those terms are written OPEN-ENDED
-- with start_precision 'unknown', the GA-2 / IN-2 / MN-2 / PA-2 pattern.
-- essentials.seat_officeholder() is NOT used: it refuses a NULL term_start by design.
--
-- ⚠ SD-26's page carries an arrival line too — "Elected in Special Election October 29, 2013" —
-- and it is NOT used. That line dates a HOUSE seat he held ten years before entering the Senate;
-- 78 Senate journal days record no oath for him. An arrival line on a member page can belong to
-- the other chamber, and running the search against the chamber the member sits in TODAY is what
-- catches it.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate. SD-15's holder
-- has signed an irrevocable resignation effective 2026-11-03; he is seated here without an end
-- date, and closing that term on the day is a recorded debt, not a thing to write early.
--
-- 🔴 PARTY IS NOT WRITTEN. All three sources carry it; party lives on races.primary_party.
--
-- 🔴🔴 THREE NAME COLLISIONS, AND ONE OF THEM IS INSIDE THIS WAVE. Each was READ before it was
-- classified. TWO roster names match a row production already held; the THIRD is a collision
-- between two rows this migration creates — HD-14 Luke S. Rankin and SD-33 Luke A. Rankin are two
-- different sitting legislators who share a first and last name, so the House row makes the
-- Senate row a duplicate of a person who did not exist when this wave began. A pre-flight that
-- compares the roster only against PRODUCTION cannot see that; the generator now asserts the
-- armed set does not collide with itself.
--
--   SAME PERSON, ROW REUSED (no insert):
--     S-15   Wes Climer, existing SC-5 congressional candidate row (external_id -450501, has a headshot) (4c07dfea-0219-410e-a1f8-baf079c012d4)
--
--   DIFFERENT PEOPLE, INSERTED WITH THE GUARD DELIBERATELY LIFTED:
--     H-49   The existing John King holds COUNCIL MEMBER in CALIFORNIA (data_source: the California Secretary of State's cities-and-towns roster). The roster John Richard C. King is the representative for South Carolina House 49, Rock Hill. Different state, different office, different person.
--     S-33   HD-14 Luke S. Rankin (born 1997-08-16, Laurens County, code 1510227092) and SD-33 Luke A. Rankin (born 1962-04-09, Horry County, chairman of Senate Judiciary, code 1511363455) are TWO DIFFERENT SITTING LEGISLATORS who share a first and last name. Both are created by this migration; the House row is inserted with the guard armed and this one with it lifted.
--
-- ⚠ THE GUARD IS LIFTED FOR 2 ROWS, NOT FOR THE MIGRATION. essentials.politicians carries a
-- BEFORE INSERT trigger that refuses a name an active row already holds. The 167 rows with no
-- namesake are inserted with it ARMED, so a namesake nobody anticipated still stops this
-- migration. Only then is essentials.allow_duplicate_name set to 'on', for the rows named above.
--
-- 🔴 THE (first_name, last_name) PAIR IS NOT THE ONLY PASS RUN. Matching the roster on the exact
-- pair found TWO existing rows. A second pass on SURNAME ALONE, restricted to rows with any South
-- Carolina connection, found three more -- James E. Clyburn, Lindsey Graham and Tim Scott, all
-- federal officials and all different people from the state legislators who share those surnames.
-- PA-2 paid for this pass: there, one of the surname-only hits WAS the same person.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── 167 people with no active namesake — guard ARMED ──────────────────────────────

CREATE TEMP TABLE sc_new_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc_new_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2745001, 'William R. "Bill" Whitmire', 'William', 'Whitmire', '{}'::text[]),
  (-2745002, 'Adam L. Duncan', 'Adam', 'Duncan', '{}'::text[]),
  (-2745003, 'Phillip Bowers', 'Phillip', 'Bowers', '{}'::text[]),
  (-2745004, 'David R. Hiott', 'David', 'Hiott', '{}'::text[]),
  (-2745005, 'Neal A. Collins', 'Neal', 'Collins', '{}'::text[]),
  (-2745006, 'April Cromer', 'April', 'Cromer', '{}'::text[]),
  (-2745007, 'Thomas Lee Gilreath', 'Thomas', 'Gilreath', '{}'::text[]),
  (-2745008, 'Donald G. "Don" Chapman', 'Donald', 'Chapman', '{}'::text[]),
  (-2745009, 'Richard Blake Sanders', 'Richard', 'Sanders', '{}'::text[]),
  (-2745010, 'Thomas Beach', 'Thomas', 'Beach', '{}'::text[]),
  (-2745011, 'Craig A. Gagnon', 'Craig', 'Gagnon', '{}'::text[]),
  (-2745012, 'Daniel Gibson', 'Daniel', 'Gibson', '{}'::text[]),
  (-2745013, 'John R. McCravy III', 'John', 'McCravy', '{}'::text[]),
  (-2745014, 'Luke S. Rankin', 'Luke', 'Rankin', '{}'::text[]),
  (-2745015, 'JA Moore', 'JA', 'Moore', '{}'::text[]),
  (-2745016, 'Mark N. Willis', 'Mark', 'Willis', '{}'::text[]),
  (-2745017, 'James Mikell "Mike" Burns', 'James', 'Burns', '{}'::text[]),
  (-2745018, 'T. Alan Morgan, Jr.', 'T.', 'Morgan', '{}'::text[]),
  (-2745019, 'Patrick B. Haddon', 'Patrick', 'Haddon', '{}'::text[]),
  (-2745020, 'Stephen D. Frank', 'Stephen', 'Frank', '{}'::text[]),
  (-2745021, 'Dianne Mitchell', 'Dianne', 'Mitchell', '{}'::text[]),
  (-2745022, 'Paul B. Wickensimer', 'Paul', 'Wickensimer', '{}'::text[]),
  (-2745023, 'Chandra E. Dillard', 'Chandra', 'Dillard', '{}'::text[]),
  (-2745024, 'Bruce W. Bannister', 'Bruce', 'Bannister', '{}'::text[]),
  (-2745025, 'Wendell K. Jones', 'Wendell', 'Jones', '{}'::text[]),
  (-2745026, 'David Martin', 'David', 'Martin', '{}'::text[]),
  (-2745027, 'David Vaughan', 'David', 'Vaughan', '{}'::text[]),
  (-2745028, 'William C. "Chris" Huff', 'William', 'Huff', '{}'::text[]),
  (-2745029, 'Dennis C. Moss', 'Dennis', 'Moss', '{}'::text[]),
  (-2745030, 'M. Brian Lawson', 'M.', 'Lawson', '{}'::text[]),
  (-2745031, 'Rosalyn D. Henderson-Myers, Ph.D.', 'Rosalyn', 'Henderson-Myers', '{}'::text[]),
  (-2745032, 'W. Scott Montgomery IV', 'W.', 'Montgomery', '{}'::text[]),
  (-2745033, 'Travis A. Moore', 'Travis', 'Moore', '{}'::text[]),
  (-2745034, 'Sarita L. Edgerton', 'Sarita', 'Edgerton', '{}'::text[]),
  (-2745035, 'William M. "Bill" Chumley', 'William', 'Chumley', '{}'::text[]),
  (-2745036, 'Robert J. "Rob" Harris', 'Robert', 'Harris', '{}'::text[]),
  (-2745037, 'Steven Wayne Long', 'Steven', 'Long', '{}'::text[]),
  (-2745038, 'Josiah Magnuson', 'Josiah', 'Magnuson', '{}'::text[]),
  (-2745039, 'Cally R. "Cal" Forrest, Jr.', 'Cally', 'Forrest', '{}'::text[]),
  (-2745040, 'Joseph S. "Joe" White', 'Joseph', 'White', '{}'::text[]),
  (-2745041, 'Annie E. McDaniel', 'Annie', 'McDaniel', '{}'::text[]),
  (-2745042, 'Leon D. "Doug" Gilliam', 'Leon', 'Gilliam', '{}'::text[]),
  (-2745043, 'Thomas R. "Randy" Ligon', 'Thomas', 'Ligon', '{}'::text[]),
  (-2745044, 'Mike M. Neese', 'Mike', 'Neese', '{}'::text[]),
  (-2745045, 'Brandon Newton', 'Brandon', 'Newton', '{}'::text[]),
  (-2745046, 'Heath Sessions', 'Heath', 'Sessions', '{}'::text[]),
  (-2745047, 'Thomas E. "Tommy" Pope', 'Thomas', 'Pope', '{}'::text[]),
  (-2745048, 'Brandon Guffey', 'Brandon', 'Guffey', '{}'::text[]),
  (-2745050, 'Keishan M. Scott', 'Keishan', 'Scott', '{}'::text[]),
  (-2745051, 'J. David Weeks', 'J.', 'Weeks', '{}'::text[]),
  (-2745052, 'Jermaine L. Johnson, Sr.', 'Jermaine', 'Johnson', '{}'::text[]),
  (-2745053, 'Richard L. "Richie" Yow', 'Richard', 'Yow', '{}'::text[]),
  (-2745054, 'Jason Luck', 'Jason', 'Luck', '{}'::text[]),
  (-2745055, 'Jackie E. "Coach" Hayes', 'Jackie', 'Hayes', '{}'::text[]),
  (-2745056, 'Timothy A. "Tim" McGinnis', 'Timothy', 'McGinnis', '{}'::text[]),
  (-2745057, 'Lucas Atkinson', 'Lucas', 'Atkinson', '{}'::text[]),
  (-2745058, 'Jeffrey E. "Jeff" Johnson', 'Jeffrey', 'Johnson', '{}'::text[]),
  (-2745059, 'Terry Alexander', 'Terry', 'Alexander', '{}'::text[]),
  (-2745060, 'Phillip D. Lowe', 'Phillip', 'Lowe', '{}'::text[]),
  (-2745061, 'Carla M. Schuessler', 'Carla', 'Schuessler', '{}'::text[]),
  (-2745062, 'Robert Q. Williams', 'Robert', 'Williams', '{}'::text[]),
  (-2745063, 'Wallace H. "Jay" Jordan, Jr.', 'Wallace', 'Jordan', '{}'::text[]),
  (-2745064, 'Fawn M. Pedalino', 'Fawn', 'Pedalino', '{}'::text[]),
  (-2745065, 'Cody T. Mitchell', 'Cody', 'Mitchell', '{}'::text[]),
  (-2745066, 'Jackie R. Terribile', 'Jackie', 'Terribile', '{}'::text[]),
  (-2745067, 'G. Murrell Smith, Jr.', 'G.', 'Smith', '{}'::text[]),
  (-2745068, 'Heather Ammons Crawford', 'Heather', 'Crawford', '{}'::text[]),
  (-2745069, 'Chris Wooten', 'Chris', 'Wooten', '{}'::text[]),
  (-2745070, 'Robert T. Reese', 'Robert', 'Reese', '{}'::text[]),
  (-2745071, 'Nathan Ballentine', 'Nathan', 'Ballentine', '{}'::text[]),
  (-2745072, 'Seth Rose', 'Seth', 'Rose', '{}'::text[]),
  (-2745073, 'Christopher R. "Chris" Hart', 'Christopher', 'Hart', '{}'::text[]),
  (-2745074, 'J. Todd Rutherford', 'J.', 'Rutherford', '{}'::text[]),
  (-2745075, 'Heather Bauer', 'Heather', 'Bauer', '{}'::text[]),
  (-2745076, 'Leon Howard', 'Leon', 'Howard', '{}'::text[]),
  (-2745077, 'Kambrell H. Garvin', 'Kambrell', 'Garvin', '{}'::text[]),
  (-2745078, 'Beth E. Bernstein', 'Beth', 'Bernstein', '{}'::text[]),
  (-2745079, 'Hamilton R. Grant', 'Hamilton', 'Grant', '{}'::text[]),
  (-2745080, 'Kathy Landing', 'Kathy', 'Landing', '{}'::text[]),
  (-2745081, 'Charles V. Hartz', 'Charles', 'Hartz', '{}'::text[]),
  (-2745082, 'William "Bill" Clyburn', 'William', 'Clyburn', '{}'::text[]),
  (-2745083, 'William M. "Bill" Hixon', 'William', 'Hixon', '{}'::text[]),
  (-2745084, 'Melissa Lackey Oremus', 'Melissa', 'Oremus', '{}'::text[]),
  (-2745085, 'John Gregory "Jay" Kilmartin', 'John', 'Kilmartin', '{}'::text[]),
  (-2745086, 'Bill Taylor', 'Bill', 'Taylor', '{}'::text[]),
  (-2745087, 'Paula Rawl Calhoon', 'Paula', 'Calhoon', '{}'::text[]),
  (-2745088, 'John T. Lastinger, Jr.', 'John', 'Lastinger', '{}'::text[]),
  (-2745089, 'Micajah P. "Micah" Caskey IV', 'Micajah', 'Caskey', '{}'::text[]),
  (-2745090, 'Justin T. Bamberg', 'Justin', 'Bamberg', '{}'::text[]),
  (-2745091, 'Lonnie Hosey', 'Lonnie', 'Hosey', '{}'::text[]),
  (-2745092, 'Brandon L. Cox', 'Brandon', 'Cox', '{}'::text[]),
  (-2745093, 'Jerry N. Govan, Jr.', 'Jerry', 'Govan', '{}'::text[]),
  (-2745094, 'Gil Gatch', 'Gil', 'Gatch', '{}'::text[]),
  (-2745095, 'Gilda Cobb-Hunter', 'Gilda', 'Cobb-Hunter', '{}'::text[]),
  (-2745096, 'Donald Ryan McCabe, Jr.', 'Donald', 'McCabe', '{}'::text[]),
  (-2745097, 'Robby Robbins', 'Robby', 'Robbins', '{}'::text[]),
  (-2745098, 'Greg Ford', 'Greg', 'Ford', '{}'::text[]),
  (-2745099, 'Marvin "Mark" Smith', 'Marvin', 'Smith', '{}'::text[]),
  (-2745100, 'Sylleste H. Davis', 'Sylleste', 'Davis', '{}'::text[]),
  (-2745101, 'Roger K. Kirby', 'Roger', 'Kirby', '{}'::text[]),
  (-2745102, 'Harriet A. Holman', 'Harriet', 'Holman', '{}'::text[]),
  (-2745103, 'Carl L. Anderson', 'Carl', 'Anderson', '{}'::text[]),
  (-2745104, 'William H. Bailey', 'William', 'Bailey', '{}'::text[]),
  (-2745105, 'Kevin Hardee', 'Kevin', 'Hardee', '{}'::text[]),
  (-2745106, 'Thomas Duval "Val" Guest, Jr.', 'Thomas', 'Guest', '{}'::text[]),
  (-2745107, 'T. Case Brittain, Jr.', 'T.', 'Brittain', '{}'::text[]),
  (-2745108, 'Lee Hewitt', 'Lee', 'Hewitt', '{}'::text[]),
  (-2745109, 'Tiffany R. Spann-Wilder', 'Tiffany', 'Spann-Wilder', '{}'::text[]),
  (-2745110, 'Thomas F. "Tom" Hartnett, Jr.', 'Thomas', 'Hartnett', '{}'::text[]),
  (-2745111, 'Wendell G. Gilliard', 'Wendell', 'Gilliard', '{}'::text[]),
  (-2745112, 'Joseph M. "Joe" Bustos', 'Joseph', 'Bustos', '{}'::text[]),
  (-2745113, 'Courtney S. Waters', 'Courtney', 'Waters', '{}'::text[]),
  (-2745114, 'Gary S. Brewer, Jr.', 'Gary', 'Brewer', '{}'::text[]),
  (-2745115, 'Elizabeth "Spencer" Wetmore', 'Elizabeth', 'Wetmore', '{}'::text[]),
  (-2745116, 'James E. Teeple', 'James', 'Teeple', '{}'::text[]),
  (-2745117, 'Jordan S. Pace', 'Jordan', 'Pace', '{}'::text[]),
  (-2745118, 'William G. "Bill" Herbkersman', 'William', 'Herbkersman', '{}'::text[]),
  (-2745119, 'Leonidas E. "Leon" Stavrinakis', 'Leonidas', 'Stavrinakis', '{}'::text[]),
  (-2745120, 'Wm. Weston J. Newton', 'Wm.', 'Newton', '{}'::text[]),
  (-2745121, 'Michael F. Rivers, Sr.', 'Michael', 'Rivers', '{}'::text[]),
  (-2745122, 'William "Bill" Hager', 'William', 'Hager', '{}'::text[]),
  (-2745123, 'Jeff Bradley', 'Jeff', 'Bradley', '{}'::text[]),
  (-2745124, 'Shannon S. Erickson', 'Shannon', 'Erickson', '{}'::text[]),
  (-2745125, 'Thomas C. Alexander', 'Thomas', 'Alexander', '{}'::text[]),
  (-2745126, 'Rex F. Rice', 'Rex', 'Rice', '{}'::text[]),
  (-2745127, 'Richard J. Cash', 'Richard', 'Cash', '{}'::text[]),
  (-2745128, 'Michael W. Gambrell', 'Michael', 'Gambrell', '{}'::text[]),
  (-2745129, 'Thomas D. "Tom" Corbin', 'Thomas', 'Corbin', '{}'::text[]),
  (-2745130, 'Jason Elliott', 'Jason', 'Elliott', '{}'::text[]),
  (-2745131, 'Karl B. Allen', 'Karl', 'Allen', '{}'::text[]),
  (-2745132, 'Ross Turner', 'Ross', 'Turner', '{}'::text[]),
  (-2745133, 'Daniel B. "Danny" Verdin III', 'Daniel', 'Verdin', '{}'::text[]),
  (-2745134, 'Billy Garrett', 'Billy', 'Garrett', '{}'::text[]),
  (-2745135, 'Josh Kimbrell', 'Josh', 'Kimbrell', '{}'::text[]),
  (-2745136, 'Lee Bright', 'Lee', 'Bright', '{}'::text[]),
  (-2745137, 'Shane R. Martin', 'Shane', 'Martin', '{}'::text[]),
  (-2745138, 'Harvey S. Peeler, Jr.', 'Harvey', 'Peeler', '{}'::text[]),
  (-2745139, 'Michael Johnson', 'Michael', 'Johnson', '{}'::text[]),
  (-2745140, 'Everett Stubbs', 'Everett', 'Stubbs', '{}'::text[]),
  (-2745141, 'Ronnie W. Cromer', 'Ronnie', 'Cromer', '{}'::text[]),
  (-2745142, 'Tameika Isaac Devine', 'Tameika', 'Isaac Devine', '{}'::text[]),
  (-2745143, 'Ed Sutton', 'Ed', 'Sutton', '{}'::text[]),
  (-2745144, 'Darrell Jackson', 'Darrell', 'Jackson', '{}'::text[]),
  (-2745145, 'Overture Walker', 'Overture', 'Walker', '{}'::text[]),
  (-2745146, 'Carlisle Kennedy', 'Carlisle', 'Kennedy', '{}'::text[]),
  (-2745147, 'Tom Young, Jr.', 'Tom', 'Young', '{}'::text[]),
  (-2745148, 'A. Shane Massey', 'A.', 'Massey', '{}'::text[]),
  (-2745149, 'Russell L. Ott', 'Russell', 'Ott', '{}'::text[]),
  (-2745150, 'Allen Blackmon', 'Allen', 'Blackmon', '{}'::text[]),
  (-2745151, 'Greg Hembree', 'Greg', 'Hembree', '{}'::text[]),
  (-2745152, 'JD Chaplin', 'JD', 'Chaplin', '{}'::text[]),
  (-2745153, 'Kent M. Williams', 'Kent', 'Williams', '{}'::text[]),
  (-2745154, 'Mike Reichenbach', 'Mike', 'Reichenbach', '{}'::text[]),
  (-2745155, 'Ronnie A. Sabb', 'Ronnie', 'Sabb', '{}'::text[]),
  (-2745157, 'Stephen L. Goldfinch', 'Stephen', 'Goldfinch', '{}'::text[]),
  (-2745158, 'Jeffrey R. Graham', 'Jeffrey', 'Graham', '{}'::text[]),
  (-2745159, 'Jeff Zell', 'Jeff', 'Zell', '{}'::text[]),
  (-2745160, 'Lawrence K. "Larry" Grooms', 'Lawrence', 'Grooms', '{}'::text[]),
  (-2745161, 'Sean M. Bennett', 'Sean', 'Bennett', '{}'::text[]),
  (-2745162, 'Tom Fernandez', 'Tom', 'Fernandez', '{}'::text[]),
  (-2745163, 'Brad Hutto', 'Brad', 'Hutto', '{}'::text[]),
  (-2745164, 'Matthew W. "Matt" Leber', 'Matthew', 'Leber', '{}'::text[]),
  (-2745165, 'Deon T. Tedder', 'Deon', 'Tedder', '{}'::text[]),
  (-2745166, 'George E. "Chip" Campsen III', 'George', 'Campsen', '{}'::text[]),
  (-2745167, 'Brian Adams', 'Brian', 'Adams', '{}'::text[]),
  (-2745168, 'Margie Bright Matthews', 'Margie', 'Bright Matthews', '{}'::text[]),
  (-2745169, 'Tom Davis', 'Tom', 'Davis', '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'South Carolina General Assembly member lists, https://www.scstatehouse.gov/member.php?chamber=H and ?chamber=S; reconciled against Open States, https://data.openstates.org/people/current/sc.csv, and against the state''s own RFA district layers at gis.state.sc.us; change-checked against all 170 individual member pages; arrivals dated from the chambers'' own journals, read 2026-09-20 (SC-2) (CC_0126, SC-2)', n.alternate_names
FROM sc_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2 people who share a name with a DIFFERENT person — guard lifted ─────────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE sc_namesake_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc_namesake_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2745049, 'John Richard C. King', 'John', 'King', '{}'::text[]),
  (-2745156, 'Luke A. Rankin', 'Luke', 'Rankin', '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'South Carolina General Assembly member lists, https://www.scstatehouse.gov/member.php?chamber=H and ?chamber=S; reconciled against Open States, https://data.openstates.org/people/current/sc.csv, and against the state''s own RFA district layers at gis.state.sc.us; change-checked against all 170 individual member pages; arrivals dated from the chambers'' own journals, read 2026-09-20 (SC-2) (CC_0126, SC-2)', n.alternate_names
FROM sc_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 170 terms, one per office ────────────────────────────────────────────────
-- Each row carries EITHER an external_id (a person created above) or a politician_id (a row
-- production already held). The join below accepts one or the other and nothing else.

CREATE TEMP TABLE sc_terms(geo_id text, district_type text, external_id bigint, politician_id uuid,
                           term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO sc_terms(geo_id, district_type, external_id, politician_id, term_start, start_precision, how_started) VALUES
  ('45001', 'STATE_LOWER', -2745001::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45002', 'STATE_LOWER', -2745002::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45003', 'STATE_LOWER', -2745003::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45004', 'STATE_LOWER', -2745004::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45005', 'STATE_LOWER', -2745005::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45006', 'STATE_LOWER', -2745006::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45007', 'STATE_LOWER', -2745007::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45008', 'STATE_LOWER', -2745008::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45009', 'STATE_LOWER', -2745009::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45010', 'STATE_LOWER', -2745010::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45011', 'STATE_LOWER', -2745011::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45012', 'STATE_LOWER', -2745012::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45013', 'STATE_LOWER', -2745013::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45014', 'STATE_LOWER', -2745014::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45015', 'STATE_LOWER', -2745015::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45016', 'STATE_LOWER', -2745016::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45017', 'STATE_LOWER', -2745017::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45018', 'STATE_LOWER', -2745018::bigint, NULL::uuid, '2022-06-15'::date, 'day', 'elected'),
  ('45019', 'STATE_LOWER', -2745019::bigint, NULL::uuid, '2020-01-14'::date, 'day', 'elected'),
  ('45020', 'STATE_LOWER', -2745020::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45021', 'STATE_LOWER', -2745021::bigint, NULL::uuid, '2026-01-13'::date, 'day', 'elected'),
  ('45022', 'STATE_LOWER', -2745022::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45023', 'STATE_LOWER', -2745023::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45024', 'STATE_LOWER', -2745024::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45025', 'STATE_LOWER', -2745025::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45026', 'STATE_LOWER', -2745026::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45027', 'STATE_LOWER', -2745027::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45028', 'STATE_LOWER', -2745028::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45029', 'STATE_LOWER', -2745029::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45030', 'STATE_LOWER', -2745030::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45031', 'STATE_LOWER', -2745031::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45032', 'STATE_LOWER', -2745032::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45033', 'STATE_LOWER', -2745033::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45034', 'STATE_LOWER', -2745034::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45035', 'STATE_LOWER', -2745035::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45036', 'STATE_LOWER', -2745036::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45037', 'STATE_LOWER', -2745037::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45038', 'STATE_LOWER', -2745038::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45039', 'STATE_LOWER', -2745039::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45040', 'STATE_LOWER', -2745040::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45041', 'STATE_LOWER', -2745041::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45042', 'STATE_LOWER', -2745042::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45043', 'STATE_LOWER', -2745043::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45044', 'STATE_LOWER', -2745044::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45045', 'STATE_LOWER', -2745045::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45046', 'STATE_LOWER', -2745046::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45047', 'STATE_LOWER', -2745047::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45048', 'STATE_LOWER', -2745048::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45049', 'STATE_LOWER', -2745049::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45050', 'STATE_LOWER', -2745050::bigint, NULL::uuid, '2026-01-13'::date, 'day', 'elected'),
  ('45051', 'STATE_LOWER', -2745051::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45052', 'STATE_LOWER', -2745052::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45053', 'STATE_LOWER', -2745053::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45054', 'STATE_LOWER', -2745054::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45055', 'STATE_LOWER', -2745055::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45056', 'STATE_LOWER', -2745056::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45057', 'STATE_LOWER', -2745057::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45058', 'STATE_LOWER', -2745058::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45059', 'STATE_LOWER', -2745059::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45060', 'STATE_LOWER', -2745060::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45061', 'STATE_LOWER', -2745061::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45062', 'STATE_LOWER', -2745062::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45063', 'STATE_LOWER', -2745063::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45064', 'STATE_LOWER', -2745064::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45065', 'STATE_LOWER', -2745065::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45066', 'STATE_LOWER', -2745066::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45067', 'STATE_LOWER', -2745067::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45068', 'STATE_LOWER', -2745068::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45069', 'STATE_LOWER', -2745069::bigint, NULL::uuid, '2018-05-08'::date, 'day', 'elected'),
  ('45070', 'STATE_LOWER', -2745070::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45071', 'STATE_LOWER', -2745071::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45072', 'STATE_LOWER', -2745072::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45073', 'STATE_LOWER', -2745073::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45074', 'STATE_LOWER', -2745074::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45075', 'STATE_LOWER', -2745075::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45076', 'STATE_LOWER', -2745076::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45077', 'STATE_LOWER', -2745077::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45078', 'STATE_LOWER', -2745078::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45079', 'STATE_LOWER', -2745079::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45080', 'STATE_LOWER', -2745080::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45081', 'STATE_LOWER', -2745081::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45082', 'STATE_LOWER', -2745082::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45083', 'STATE_LOWER', -2745083::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45084', 'STATE_LOWER', -2745084::bigint, NULL::uuid, '2020-01-14'::date, 'day', 'elected'),
  ('45085', 'STATE_LOWER', -2745085::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45086', 'STATE_LOWER', -2745086::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45087', 'STATE_LOWER', -2745087::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45088', 'STATE_LOWER', -2745088::bigint, NULL::uuid, '2026-01-13'::date, 'day', 'elected'),
  ('45089', 'STATE_LOWER', -2745089::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45090', 'STATE_LOWER', -2745090::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45091', 'STATE_LOWER', -2745091::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45092', 'STATE_LOWER', -2745092::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45093', 'STATE_LOWER', -2745093::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45094', 'STATE_LOWER', -2745094::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45095', 'STATE_LOWER', -2745095::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45096', 'STATE_LOWER', -2745096::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45097', 'STATE_LOWER', -2745097::bigint, NULL::uuid, '2022-06-15'::date, 'day', 'elected'),
  ('45098', 'STATE_LOWER', -2745098::bigint, NULL::uuid, '2026-01-13'::date, 'day', 'elected'),
  ('45099', 'STATE_LOWER', -2745099::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45100', 'STATE_LOWER', -2745100::bigint, NULL::uuid, '2016-06-15'::date, 'day', 'elected'),
  ('45101', 'STATE_LOWER', -2745101::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45102', 'STATE_LOWER', -2745102::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45103', 'STATE_LOWER', -2745103::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45104', 'STATE_LOWER', -2745104::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45105', 'STATE_LOWER', -2745105::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45106', 'STATE_LOWER', -2745106::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45107', 'STATE_LOWER', -2745107::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45108', 'STATE_LOWER', -2745108::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45109', 'STATE_LOWER', -2745109::bigint, NULL::uuid, '2024-04-09'::date, 'day', 'elected'),
  ('45110', 'STATE_LOWER', -2745110::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45111', 'STATE_LOWER', -2745111::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45112', 'STATE_LOWER', -2745112::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45113', 'STATE_LOWER', -2745113::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45114', 'STATE_LOWER', -2745114::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45115', 'STATE_LOWER', -2745115::bigint, NULL::uuid, '2020-09-15'::date, 'day', 'elected'),
  ('45116', 'STATE_LOWER', -2745116::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45117', 'STATE_LOWER', -2745117::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45118', 'STATE_LOWER', -2745118::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45119', 'STATE_LOWER', -2745119::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45120', 'STATE_LOWER', -2745120::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45121', 'STATE_LOWER', -2745121::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45122', 'STATE_LOWER', -2745122::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45123', 'STATE_LOWER', -2745123::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45124', 'STATE_LOWER', -2745124::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45001', 'STATE_UPPER', -2745125::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45002', 'STATE_UPPER', -2745126::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45003', 'STATE_UPPER', -2745127::bigint, NULL::uuid, '2017-06-06'::date, 'day', 'elected'),
  ('45004', 'STATE_UPPER', -2745128::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45005', 'STATE_UPPER', -2745129::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45006', 'STATE_UPPER', -2745130::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45007', 'STATE_UPPER', -2745131::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45008', 'STATE_UPPER', -2745132::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45009', 'STATE_UPPER', -2745133::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45010', 'STATE_UPPER', -2745134::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45011', 'STATE_UPPER', -2745135::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45012', 'STATE_UPPER', -2745136::bigint, NULL::uuid, '2026-01-13'::date, 'day', 'elected'),
  ('45013', 'STATE_UPPER', -2745137::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45014', 'STATE_UPPER', -2745138::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45015', 'STATE_UPPER', NULL::bigint, '4c07dfea-0219-410e-a1f8-baf079c012d4'::uuid, NULL::date, 'unknown', 'unknown'),
  ('45016', 'STATE_UPPER', -2745139::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45017', 'STATE_UPPER', -2745140::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45018', 'STATE_UPPER', -2745141::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45019', 'STATE_UPPER', -2745142::bigint, NULL::uuid, '2024-01-09'::date, 'day', 'elected'),
  ('45020', 'STATE_UPPER', -2745143::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45021', 'STATE_UPPER', -2745144::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45022', 'STATE_UPPER', -2745145::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45023', 'STATE_UPPER', -2745146::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45024', 'STATE_UPPER', -2745147::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45025', 'STATE_UPPER', -2745148::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45026', 'STATE_UPPER', -2745149::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45027', 'STATE_UPPER', -2745150::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45028', 'STATE_UPPER', -2745151::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45029', 'STATE_UPPER', -2745152::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45030', 'STATE_UPPER', -2745153::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45031', 'STATE_UPPER', -2745154::bigint, NULL::uuid, '2022-04-05'::date, 'day', 'elected'),
  ('45032', 'STATE_UPPER', -2745155::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45033', 'STATE_UPPER', -2745156::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45034', 'STATE_UPPER', -2745157::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45035', 'STATE_UPPER', -2745158::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45036', 'STATE_UPPER', -2745159::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45037', 'STATE_UPPER', -2745160::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45038', 'STATE_UPPER', -2745161::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45039', 'STATE_UPPER', -2745162::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45040', 'STATE_UPPER', -2745163::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45041', 'STATE_UPPER', -2745164::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45042', 'STATE_UPPER', -2745165::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45043', 'STATE_UPPER', -2745166::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45044', 'STATE_UPPER', -2745167::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('45045', 'STATE_UPPER', -2745168::bigint, NULL::uuid, '2016-01-13'::date, 'day', 'elected'),
  ('45046', 'STATE_UPPER', -2745169::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started, 'South Carolina General Assembly member lists, https://www.scstatehouse.gov/member.php?chamber=H and ?chamber=S; reconciled against Open States, https://data.openstates.org/people/current/sc.csv, and against the state''s own RFA district layers at gis.state.sc.us; change-checked against all 170 individual member pages; arrivals dated from the chambers'' own journals, read 2026-09-20 (SC-2) (CC_0126, SC-2)'
FROM sc_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'sc'
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
  v_offices  int;
  v_terms    int;
  v_seated   int;
  v_dated    int;
  v_ended    int;
  v_fanout   int;
  v_reuse    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2745200 AND -2745001;
  IF v_people <> 169 THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected 169 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_offices <> 170 THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected 170 South Carolina legislative offices, got %', v_offices;
  END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_terms <> 170 THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected 170 terms, got %', v_terms;
  END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*). office_current_holder LEFT JOINs from offices,
  -- so an unseated office is a row with a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> 170 THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected 170 seated offices, got %', v_seated;
  END IF;

  SELECT count(*) INTO v_dated
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    AND ot.term_start IS NOT NULL;
  IF v_dated <> 17 THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected 17 dated term(s), got %', v_dated;
  END IF;

  -- The anchor: HD-50, elected 2025-06-03 and sworn 2026-01-13. If this row ever carries the
  -- ELECTION date, the wave has written a seven-month overstatement.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'sc' AND d.district_type::text = 'STATE_LOWER' AND d.geo_id = '45050'
      AND ot.term_start = DATE '2026-01-13' AND ot.start_precision = 'day'
  ) THEN
    RAISE EXCEPTION 'SC-2 occupancy: HD-50 is not seated from 2026-01-13 at day precision — the OATH date, not the election';
  END IF;

  SELECT count(*) INTO v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'SC-2 occupancy: % term(s) carry a term_end — a future end date self-vacates a seat', v_ended;
  END IF;

  -- 🔴 NOBODY SEATED HERE HOLDS TWO SOUTH CAROLINA LEGISLATIVE SEATS. The exclusion constraint on
  -- office_terms forbids two people on one office; it CANNOT see one person on two, which is the
  -- direction that fans a politician-rooted join out.
  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY ot.politician_id HAVING count(*) > 1
  ) x;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION 'SC-2 occupancy: % person(s) hold more than one South Carolina legislative seat', v_fanout;
  END IF;

  -- The reuse actually reused: SD-15 must be held by the EXISTING row, not by a second Wes Climer.
  SELECT count(*) INTO v_reuse
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text = 'STATE_UPPER' AND d.geo_id = '45015'
    AND ot.politician_id = '4c07dfea-0219-410e-a1f8-baf079c012d4';
  IF v_reuse <> 1 THEN
    RAISE EXCEPTION 'SC-2 occupancy: SD-15 is not held by the existing Wes Climer row (got %)', v_reuse;
  END IF;

  RAISE NOTICE 'SC-2 occupancy OK: 170 offices, 170 terms, 170 seated, 17 dated, 0 ended, 1 reused';
END $$;

COMMIT;
