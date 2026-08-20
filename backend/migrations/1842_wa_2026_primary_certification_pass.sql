-- 1842_wa_2026_primary_certification_pass.sql
--
-- THE CERTIFICATION CULL for every race on the WA 2026 Statewide General
-- (election 51e7a875-bff9-4e96-adcf-41736454d25d). Migrations 1747 and 1750 seeded the
-- 2026-08-04 top-two primary field from a PRE-CERTIFICATION results feed and wrote, in
-- prose, "Pre-certification field; cull gates on the certified canvass" with
-- provisional_until = 2026-08-24. This is that gate.
--
-- ============================================================================
-- WHAT MAKES THE SOURCE CERTIFIED, AND HOW THAT WAS PROVEN RATHER THAN ASSUMED
-- ============================================================================
-- WA county canvassing boards certified the August primary on 2026-08-18; the Secretary of
-- State's deadline to certify the state primary is 2026-08-21. All three results feeds now
-- carry election.isOfficialResults = true:
--
--   statewide  results.votewa.gov/results/public/api/elections/washington/20260804/data
--              lastUpdated 2026-08-19T13:39:21Z   (10 congressional + 98 house + 24 senate)
--   King       results.votewa.gov/results/public/api/elections/king-county-wa/20260804/data
--              lastUpdated 2026-08-18T21:36:40Z   (Assessor, Council 2/8, Seattle Council 5)
--   Kitsap     results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data
--              lastUpdated 2026-08-18T00:01:49Z   (7 county offices)
--
-- 🔴 A FLAG IN A FEED IS THE FEED'S OWN CLAIM. Each was checked against the jurisdiction's
-- own certified document before a single row was culled:
--   King:   webresults-20260818-final.csv (cdn.kingcounty.gov/-/media/king-county/depts/
--           elections/results/2026/08/) — Assessor, Council 2, Council 8 and Seattle 5 match
--           candidate-for-candidate. Total Ballots Cast 534,500 matches the feed exactly.
--   Kitsap: the Auditor's own cumulative report (kitsap.gov/auditor/Documents/results.html),
--           header "Primary 8/4/2026 Official Results ... Run Date 08/18/2026 ... Precincts
--           Reporting 321 of 321 = 100.00%" — all 7 county contests match to the vote.
--   State:  four districts wholly inside King County (LD 37 Senate, LD 43 Pos. 2, LD 46
--           Pos. 1, LD 47 Pos. 1) return numbers IDENTICAL to King's certified CSV, which is
--           what an aggregate of certified county canvasses should do.
--
-- 🔴 A WEB SEARCH SUMMARY CONTRADICTED THE FEED ON THE KITSAP SHERIFF RACE and was wrong:
-- it reported Myers 28,094 / Kuss 19,827 against the correct 48,117 / 34,768. The ratio was
-- right and the magnitude was not, which is exactly what a garbled figure looks like. The
-- Auditor's own report settled it. Raw jurisdiction documents only.
--
-- ============================================================================
-- 🔴 THE ONE RACE THIS MIGRATION REFUSES TO CULL: LD 42 STATE SENATE
-- ============================================================================
-- Certified: Creydt (REP) 22,125 / Shepard (DEM) 13,125 / Collins (DEM) 13,121 / Bowman 1,248.
-- SECOND AND THIRD ARE FOUR VOTES APART — 0.015% of their combined total. RCW 29A.64.021
-- makes a HAND recount mandatory under 150 votes and 0.25%, and Whatcom County has scheduled
-- it for 2026-08-25 08:00 at the Election Center, Whatcom County Courthouse. A certified cut
-- line inside the mandatory-recount margin is not a settled field: culling Collins today
-- would delete a candidate who may be on the November ballot.
-- All four LD 42 rows therefore keep result = NULL and get provisional_until = 2026-09-04.
-- Re-enter after the recount is certified: .planning/todos/2026-08-25-wa-ld42-senate-recount.md
--
-- The check that found it is a MARGIN test, not a tie test. An exact-tie guard would have
-- passed this race green and shipped the cull.
--
-- ============================================================================
-- WHY THE WRITE-IN LINE IS EXCLUDED BY NAME AND NOT BY ITS FLAG
-- ============================================================================
-- 🔴 ballotOptions.isWriteIn IS UNRELIABLE IN THIS FEED: 3 of 137 write-in lines statewide
-- and 41 of 60 in the King feed carry isWriteIn = false. Trusting the flag puts a line called
-- "Write-in" into the candidate ranking. It changed no disposition here only because every
-- affected contest had a single real candidate, so the write-in took an unoccupied second
-- slot — in a three-way contest it would have displaced a real advancer. Detection is by
-- name; an actually-qualified write-in appears under the person's own name, never "Write-in".
--
-- ============================================================================
-- DISPOSITION OF ALL 394 ROWS ON THIS ELECTION
-- ============================================================================
--   262  result = 'advanced'      top two (or the sole candidate) in a certified contest
--   119  result = 'not_nominated' ran and did not make the top two
--     5  result = 'withdrew'      withdrew before the ballot; ABSENT from the certified canvass
--     4  result stays NULL        LD 42 Senate — mandatory hand recount, see above
--     4  result stays NULL        4 King County offices that HELD NO PRIMARY (sole filer)
--
-- essentials.is_live_candidate (migration 1582) is what makes this a cull: 'not_nominated'
-- and candidate_status 'withdrawn' both drop out of every read path. Live field afterwards is
-- 262 + 4 (LD 42) + 4 (unopposed King County) = 270 of 394.
--
-- 🔴 THE 4 KING COUNTY OFFICES WITH NO PRIMARY DO NOT GET A RESULT. King County Council
-- Districts 4 and 6, Director of Elections and Prosecuting Attorney drew a single filer each,
-- and under WA law a nonpartisan race with no more than twice as many candidates as positions
-- skips the primary entirely. There is no canvass line to cite, so there is no result to
-- record — but their ABSENCE from a certified canvass does confirm the field, so
-- provisional_until goes to NULL. Writing 'advanced' here would cite a contest that was
-- never held.
--
-- 🔴 THE 5 WITHDRAWN ROWS ARE CONFIRMED BY ABSENCE, AND THAT IS A REAL FINDING. Joel Ard
-- (LD 23 Pos. 1), Brett Johnson (LD 29 Pos. 1), Julia Payne (LD 6 Pos. 1), Emijah Smith
-- (LD 37 Senate) and Douglas McKinley (LD 8 Senate) appear NOWHERE in the certified canvass
-- of their race, which is what a pre-ballot withdrawal looks like. Note Julia Payne is a
-- LIVE candidate in LD 6 Position 2 in the same certified canvass — she moved position, she
-- did not leave the ballot, and only the Position 1 row is closed here.
--
-- MATCHING. 143 of 147 races mapped to a certified contest by parsed district/position
-- number, never by fuzzy title. Candidate matching is 1:1 within the matched contest on an
-- NFD-stripped normalised name; ONE row needed a fallback (last name + first initial, unique
-- on both sides): "Suzan K. DelBene" -> "Suzan DelBene". Zero certified candidates were
-- missing from our field in any race, and zero of our rows went unexplained.
--
-- Idempotent: every UPDATE is guarded on the value it is about to write.

BEGIN;

-- ── the certified tally, one row per candidate, from the feeds named above ──────────────────
CREATE TEMP TABLE wa_cert_tally (
  position_name text NOT NULL,
  cand_name     text NOT NULL,
  feed_name     text NOT NULL,
  votes         integer NOT NULL,
  disposition   text NOT NULL CHECK (disposition IN ('advanced','not_nominated'))
) ON COMMIT DROP;

INSERT INTO wa_cert_tally (position_name, cand_name, feed_name, votes, disposition) VALUES
  ('King County Assessor', 'Rob Foxcurran', 'Rob Foxcurran', 231854, 'advanced'),
  ('King County Assessor', 'Dominique M Scarimbolo', 'Dominique M Scarimbolo', 94725, 'advanced'),
  ('King County Assessor', 'Christopher Roberts', 'Christopher Roberts', 91770, 'not_nominated'),
  ('King County Assessor', 'Al Dams', 'Al Dams', 72783, 'not_nominated'),
  ('King County Council District 2', 'Rebecca Saldaña', 'Rebecca Saldaña', 35247, 'advanced'),
  ('King County Council District 2', 'Toshiko Grace Hasegawa', 'Toshiko Grace Hasegawa', 22120, 'advanced'),
  ('King County Council District 2', 'Miriam Mboya', 'Miriam Mboya', 5525, 'not_nominated'),
  ('King County Council District 8', 'Teresa Mosqueda', 'Teresa Mosqueda', 39909, 'advanced'),
  ('King County Council District 8', 'Nick Duda', 'Nick Duda', 15000, 'advanced'),
  ('King County Council District 8', 'Mia Jacobson', 'Mia Jacobson', 5090, 'not_nominated'),
  ('Kitsap County Assessor', 'Michael Simonds', 'Michael Simonds', 43260, 'advanced'),
  ('Kitsap County Assessor', 'Phil Cook', 'Phil Cook', 39175, 'advanced'),
  ('Kitsap County Auditor', 'Paul Andrews', 'Paul Andrews', 57656, 'advanced'),
  ('Kitsap County Clerk', 'David T Lewis III', 'David T Lewis III', 40614, 'advanced'),
  ('Kitsap County Clerk', 'Brien Kennedy', 'Brien Kennedy', 23363, 'advanced'),
  ('Kitsap County Commissioner District 3', 'Katie Walters', 'Katie Walters', 14965, 'advanced'),
  ('Kitsap County Commissioner District 3', 'Kevin Tisdel', 'Kevin Tisdel', 10223, 'advanced'),
  ('Kitsap County Prosecuting Attorney', 'Joe Lombardi', 'Joe Lombardi', 34183, 'advanced'),
  ('Kitsap County Prosecuting Attorney', 'Chad M. Enright', 'Chad M. Enright', 29689, 'advanced'),
  ('Kitsap County Sheriff', 'Brandon L. Myers', 'Brandon L. Myers', 48117, 'advanced'),
  ('Kitsap County Sheriff', 'Rick Kuss', 'Rick Kuss', 34768, 'advanced'),
  ('Kitsap County Treasurer', 'Pete Boissonneau', 'Pete Boissonneau', 56614, 'advanced'),
  ('Seattle City Council District 5', 'Nilu Jenks', 'Nilu Jenks', 16287, 'advanced'),
  ('Seattle City Council District 5', 'Julie Kang', 'Julie Kang', 9956, 'advanced'),
  ('Seattle City Council District 5', 'Dimitri Georgakopoulos', 'Dimitri Georgakopoulos', 2423, 'not_nominated'),
  ('Seattle City Council District 5', 'Silas James', 'Silas James', 1451, 'not_nominated'),
  ('U.S. Representative District 1', 'Suzan K. DelBene', 'Suzan DelBene', 85156, 'advanced'),
  ('U.S. Representative District 1', 'Mary Silva', 'Mary Silva', 42088, 'advanced'),
  ('U.S. Representative District 1', 'James Etzkorn', 'James Etzkorn', 12023, 'not_nominated'),
  ('U.S. Representative District 1', 'Hunter Gordon', 'Hunter Gordon', 10014, 'not_nominated'),
  ('U.S. Representative District 1', 'Bryce Nickel', 'Bryce Nickel', 3929, 'not_nominated'),
  ('U.S. Representative District 1', 'Benjamin Kincaid', 'Benjamin Kincaid', 3580, 'not_nominated'),
  ('U.S. Representative District 1', 'Catherine Hildebrand', 'Catherine Hildebrand', 3562, 'not_nominated'),
  ('U.S. Representative District 10', 'Marilyn Strickland', 'Marilyn Strickland', 73689, 'advanced'),
  ('U.S. Representative District 10', 'Chris D. Chung', 'Chris D. Chung', 48953, 'advanced'),
  ('U.S. Representative District 10', 'Alex Scheel', 'Alex Scheel', 16074, 'not_nominated'),
  ('U.S. Representative District 10', 'Adam Arafat', 'Adam Arafat', 14695, 'not_nominated'),
  ('U.S. Representative District 10', 'Derek Maynes', 'Derek Maynes', 1431, 'not_nominated'),
  ('U.S. Representative District 10', 'Kurtis Engle', 'Kurtis Engle', 713, 'not_nominated'),
  ('U.S. Representative District 2', 'Rick Larsen', 'Rick Larsen', 88708, 'advanced'),
  ('U.S. Representative District 2', 'Edwin H. Feller', 'Edwin H. Feller', 68713, 'advanced'),
  ('U.S. Representative District 2', 'Tomas Scheel', 'Tomas Scheel', 29133, 'not_nominated'),
  ('U.S. Representative District 2', 'Devin Hermanson', 'Devin Hermanson', 22775, 'not_nominated'),
  ('U.S. Representative District 3', 'John Braun', 'John Braun', 85064, 'advanced'),
  ('U.S. Representative District 3', 'Marie Gluesenkamp Perez', 'Marie Gluesenkamp Perez', 78025, 'advanced'),
  ('U.S. Representative District 3', 'Brent Hennrich', 'Brent Hennrich', 35820, 'not_nominated'),
  ('U.S. Representative District 3', 'John P. Roco', 'John P. Roco', 4102, 'not_nominated'),
  ('U.S. Representative District 3', 'John Saulie-Rohman', 'John Saulie-Rohman', 3549, 'not_nominated'),
  ('U.S. Representative District 3', 'Lawrence Kellogg', 'Lawrence Kellogg', 2727, 'not_nominated'),
  ('U.S. Representative District 3', 'Troy Rasband', 'Troy Rasband', 2058, 'not_nominated'),
  ('U.S. Representative District 3', 'Austin Braswell', 'Austin Braswell', 1656, 'not_nominated'),
  ('U.S. Representative District 3', 'Antony Barran', 'Antony Barran', 1345, 'not_nominated'),
  ('U.S. Representative District 4', 'Amanda McKinney', 'Amanda McKinney', 49652, 'advanced'),
  ('U.S. Representative District 4', 'John Duresky', 'John Duresky', 42681, 'advanced'),
  ('U.S. Representative District 4', 'Jerrod Sessler', 'Jerrod Sessler', 20808, 'not_nominated'),
  ('U.S. Representative District 4', 'Matt Boehnke', 'Matt Boehnke', 15013, 'not_nominated'),
  ('U.S. Representative District 4', 'Favian Valencia', 'Favian Valencia', 5776, 'not_nominated'),
  ('U.S. Representative District 4', 'Jacek "Jack" Kobiesa', 'Jacek "Jack" Kobiesa', 2214, 'not_nominated'),
  ('U.S. Representative District 4', 'Devin Poore', 'Devin Poore', 1956, 'not_nominated'),
  ('U.S. Representative District 4', 'John C. Hughs', 'John C. Hughs', 1695, 'not_nominated'),
  ('U.S. Representative District 4', 'Elpidia Saavedra', 'Elpidia Saavedra', 1393, 'not_nominated'),
  ('U.S. Representative District 4', 'Zac Rossi', 'Zac Rossi', 879, 'not_nominated'),
  ('U.S. Representative District 4', 'Ken Vaz', 'Ken Vaz', 477, 'not_nominated'),
  ('U.S. Representative District 5', 'Michael Baumgartner', 'Michael Baumgartner', 96791, 'advanced'),
  ('U.S. Representative District 5', 'Carmela Conroy', 'Carmela Conroy', 38487, 'advanced'),
  ('U.S. Representative District 5', 'Nate Powell', 'Nate Powell', 33443, 'not_nominated'),
  ('U.S. Representative District 5', 'Kevin Fagan', 'Kevin Fagan', 9048, 'not_nominated'),
  ('U.S. Representative District 5', 'David Womack', 'David Womack', 7242, 'not_nominated'),
  ('U.S. Representative District 5', 'Bajun R. Mavalwalla', 'Bajun R. Mavalwalla', 6482, 'not_nominated'),
  ('U.S. Representative District 5', 'Ann Marie Danimus', 'Ann Marie Danimus', 2920, 'not_nominated'),
  ('U.S. Representative District 5', 'Richard Freudenberg', 'Richard Freudenberg', 2866, 'not_nominated'),
  ('U.S. Representative District 5', 'Matthew Hayes', 'Matthew Hayes', 2417, 'not_nominated'),
  ('U.S. Representative District 5', 'Kyle Usrey', 'Kyle Usrey', 2274, 'not_nominated'),
  ('U.S. Representative District 5', 'Michael McGarr', 'Michael McGarr', 1152, 'not_nominated'),
  ('U.S. Representative District 5', 'Andrew Bartleson', 'Andrew Bartleson', 915, 'not_nominated'),
  ('U.S. Representative District 6', 'Emily Randall', 'Emily Randall', 132805, 'advanced'),
  ('U.S. Representative District 6', 'Teresa Fox', 'Teresa Fox', 57700, 'advanced'),
  ('U.S. Representative District 6', 'Leon Lawson', 'Leon Lawson', 21965, 'not_nominated'),
  ('U.S. Representative District 6', 'Brian P. O''Gorman', 'Brian P. O''Gorman', 7307, 'not_nominated'),
  ('U.S. Representative District 6', 'Macy Jones', 'Macy Jones', 6044, 'not_nominated'),
  ('U.S. Representative District 7', 'Pramila Jayapal', 'Pramila Jayapal', 182844, 'advanced'),
  ('U.S. Representative District 7', 'Nirav Sheth', 'Nirav Sheth', 21282, 'advanced'),
  ('U.S. Representative District 7', 'Gwen Kirkland', 'Gwen Kirkland', 7519, 'not_nominated'),
  ('U.S. Representative District 7', 'David W. Blomstrom', 'David W. Blomstrom', 4294, 'not_nominated'),
  ('U.S. Representative District 8', 'Kim Schrier', 'Kim Schrier', 102853, 'advanced'),
  ('U.S. Representative District 8', 'Spencer Meline', 'Spencer Meline', 30324, 'advanced'),
  ('U.S. Representative District 8', 'Trinh Ha', 'Trinh Ha', 28340, 'not_nominated'),
  ('U.S. Representative District 8', 'Bob Hagglund', 'Bob Hagglund', 20382, 'not_nominated'),
  ('U.S. Representative District 8', 'Keith Arnold', 'Keith Arnold', 4777, 'not_nominated'),
  ('U.S. Representative District 8', 'Andres Valleza', 'Andres Valleza', 4549, 'not_nominated'),
  ('U.S. Representative District 9', 'Adam Smith', 'Adam Smith', 67095, 'advanced'),
  ('U.S. Representative District 9', 'Doug Basler', 'Doug Basler', 31070, 'advanced'),
  ('U.S. Representative District 9', 'Kshama Sawant', 'Kshama Sawant', 24583, 'not_nominated'),
  ('U.S. Representative District 9', 'Melissa Chaudhry', 'Melissa Chaudhry', 17811, 'not_nominated'),
  ('U.S. Representative District 9', 'Jacob Perasso', 'Jacob Perasso', 1588, 'not_nominated'),
  ('WA House of Representatives Legislative District 1 Position 1', 'Davina Duerr', 'Davina Duerr', 29426, 'advanced'),
  ('WA House of Representatives Legislative District 1 Position 1', 'Maggie Wang', 'Maggie Wang', 9878, 'advanced'),
  ('WA House of Representatives Legislative District 1 Position 2', 'Shelley Kloba', 'Shelley Kloba', 19150, 'advanced'),
  ('WA House of Representatives Legislative District 1 Position 2', 'Cliff Moon', 'Cliff Moon', 9110, 'advanced'),
  ('WA House of Representatives Legislative District 1 Position 2', 'Jenne Alderks', 'Jenne Alderks', 8974, 'not_nominated'),
  ('WA House of Representatives Legislative District 1 Position 2', 'Jeff Lyon', 'Jeff Lyon', 2190, 'not_nominated'),
  ('WA House of Representatives Legislative District 10 Position 1', 'Clyde Shavers', 'Clyde Shavers', 28026, 'advanced'),
  ('WA House of Representatives Legislative District 10 Position 1', 'Robert (Chili) Hicks', 'Robert (Chili) Hicks', 20190, 'advanced'),
  ('WA House of Representatives Legislative District 10 Position 2', 'Dave Paul', 'Dave Paul', 28301, 'advanced'),
  ('WA House of Representatives Legislative District 10 Position 2', 'Tim Hazelo', 'Tim Hazelo', 10584, 'advanced'),
  ('WA House of Representatives Legislative District 10 Position 2', 'Carrie R. Kennedy', 'Carrie R. Kennedy', 9285, 'not_nominated'),
  ('WA House of Representatives Legislative District 11 Position 1', 'David Hackney', 'David Hackney', 10998, 'advanced'),
  ('WA House of Representatives Legislative District 11 Position 1', 'Ashley Fedan', 'Ashley Fedan', 8298, 'advanced'),
  ('WA House of Representatives Legislative District 11 Position 1', 'Christian Rombough', 'Christian Rombough', 6639, 'not_nominated'),
  ('WA House of Representatives Legislative District 11 Position 2', 'Steve Bergquist', 'Steve Bergquist', 19576, 'advanced'),
  ('WA House of Representatives Legislative District 12 Position 1', 'Brian Burnett', 'Brian Burnett', 22207, 'advanced'),
  ('WA House of Representatives Legislative District 12 Position 1', 'Stacy Willoughby', 'Stacy Willoughby', 22033, 'advanced'),
  ('WA House of Representatives Legislative District 12 Position 2', 'Mike Steele', 'Mike Steele', 18242, 'advanced'),
  ('WA House of Representatives Legislative District 12 Position 2', 'Maggie Adams', 'Maggie Adams', 15035, 'advanced'),
  ('WA House of Representatives Legislative District 12 Position 2', 'Adam James', 'Adam James', 11041, 'not_nominated'),
  ('WA House of Representatives Legislative District 13 Position 1', 'Tom Dent', 'Tom Dent', 21849, 'advanced'),
  ('WA House of Representatives Legislative District 13 Position 1', 'Juan "Jerry" Garcia', 'Juan "Jerry" Garcia', 8898, 'advanced'),
  ('WA House of Representatives Legislative District 13 Position 2', 'Deanna Martinez', 'Deanna Martinez', 9713, 'advanced'),
  ('WA House of Representatives Legislative District 13 Position 2', 'Joshua Thompson', 'Joshua Thompson', 8924, 'advanced'),
  ('WA House of Representatives Legislative District 13 Position 2', 'Don Myers', 'Don Myers', 7003, 'not_nominated'),
  ('WA House of Representatives Legislative District 14 Position 1', 'Gloria Mendoza', 'Gloria Mendoza', 6759, 'advanced'),
  ('WA House of Representatives Legislative District 14 Position 1', 'Chelsea Dimas', 'Chelsea Dimas', 5640, 'advanced'),
  ('WA House of Representatives Legislative District 14 Position 1', 'William Chichenoff', 'William Chichenoff', 706, 'not_nominated'),
  ('WA House of Representatives Legislative District 14 Position 2', 'Deb Manjarrez', 'Deb Manjarrez', 6700, 'advanced'),
  ('WA House of Representatives Legislative District 14 Position 2', 'Ezequiel Morfin', 'Ezequiel Morfin', 3992, 'advanced'),
  ('WA House of Representatives Legislative District 14 Position 2', 'Tony G Sandoval', 'Tony G Sandoval', 2406, 'not_nominated'),
  ('WA House of Representatives Legislative District 15 Position 1', 'Chris Corry', 'Chris Corry', 20900, 'advanced'),
  ('WA House of Representatives Legislative District 15 Position 1', 'Jack McEntire', 'Jack McEntire', 10159, 'advanced'),
  ('WA House of Representatives Legislative District 15 Position 2', 'Reedy Berg', 'Reedy Berg', 14710, 'advanced'),
  ('WA House of Representatives Legislative District 15 Position 2', 'Liz Hallock', 'Liz Hallock', 9136, 'advanced'),
  ('WA House of Representatives Legislative District 15 Position 2', 'Chase Foster', 'Chase Foster', 6448, 'not_nominated'),
  ('WA House of Representatives Legislative District 16 Position 1', 'Mark Klicker', 'Mark Klicker', 21367, 'advanced'),
  ('WA House of Representatives Legislative District 16 Position 1', 'Kyle Palmer', 'Kyle Palmer', 13998, 'advanced'),
  ('WA House of Representatives Legislative District 16 Position 2', 'Skyler Rude', 'Skyler Rude', 20493, 'advanced'),
  ('WA House of Representatives Legislative District 16 Position 2', 'Derek Sarley', 'Derek Sarley', 14831, 'advanced'),
  ('WA House of Representatives Legislative District 17 Position 1', 'Ben Christly', 'Ben Christly', 24703, 'advanced'),
  ('WA House of Representatives Legislative District 17 Position 1', 'Kevin Waters', 'Kevin Waters', 20718, 'advanced'),
  ('WA House of Representatives Legislative District 17 Position 1', 'Thomas Everett Haynes', 'Thomas Everett Haynes', 1711, 'not_nominated'),
  ('WA House of Representatives Legislative District 17 Position 2', 'Diana H. Perez', 'Diana H. Perez', 25825, 'advanced'),
  ('WA House of Representatives Legislative District 17 Position 2', 'David Stuebe', 'David Stuebe', 21170, 'advanced'),
  ('WA House of Representatives Legislative District 18 Position 1', 'Randi L. Knott', 'Randi L. Knott', 22859, 'advanced'),
  ('WA House of Representatives Legislative District 18 Position 1', 'Stephanie McClintock', 'Stephanie McClintock', 21014, 'advanced'),
  ('WA House of Representatives Legislative District 18 Position 2', 'Deken Letinich', 'Deken Letinich', 23407, 'advanced'),
  ('WA House of Representatives Legislative District 18 Position 2', 'John Ley', 'John Ley', 20325, 'advanced'),
  ('WA House of Representatives Legislative District 19 Position 1', 'Jim Walsh', 'Jim Walsh', 24113, 'advanced'),
  ('WA House of Representatives Legislative District 19 Position 1', 'Kevin Moynihan', 'Kevin Moynihan', 19272, 'advanced'),
  ('WA House of Representatives Legislative District 19 Position 2', 'Terry Carlson', 'Terry Carlson', 18354, 'advanced'),
  ('WA House of Representatives Legislative District 19 Position 2', 'Joel McEntire', 'Joel McEntire', 17670, 'advanced'),
  ('WA House of Representatives Legislative District 19 Position 2', 'Jimi O''Hagan', 'Jimi O''Hagan', 3404, 'not_nominated'),
  ('WA House of Representatives Legislative District 19 Position 2', 'Daniel William Bradley', 'Daniel William Bradley', 2958, 'not_nominated'),
  ('WA House of Representatives Legislative District 2 Position 1', 'Andrew Barkis', 'Andrew Barkis', 18389, 'advanced'),
  ('WA House of Representatives Legislative District 2 Position 1', 'William Dehnel', 'William Dehnel', 13214, 'advanced'),
  ('WA House of Representatives Legislative District 2 Position 2', 'Matt Marshall', 'Matt Marshall', 18054, 'advanced'),
  ('WA House of Representatives Legislative District 2 Position 2', 'Angela Taylor', 'Angela Taylor', 10650, 'advanced'),
  ('WA House of Representatives Legislative District 2 Position 2', 'Martin L Miller', 'Martin L Miller', 2986, 'not_nominated'),
  ('WA House of Representatives Legislative District 20 Position 1', 'Peter Abbarno', 'Peter Abbarno', 31475, 'advanced'),
  ('WA House of Representatives Legislative District 20 Position 1', 'Andy Zahn', 'Andy Zahn', 16418, 'advanced'),
  ('WA House of Representatives Legislative District 20 Position 2', 'Ed Orcutt', 'Ed Orcutt', 30140, 'advanced'),
  ('WA House of Representatives Legislative District 20 Position 2', 'Evan Jones', 'Evan Jones', 17728, 'advanced'),
  ('WA House of Representatives Legislative District 21 Position 1', 'Strom Peterson', 'Strom Peterson', 16344, 'advanced'),
  ('WA House of Representatives Legislative District 21 Position 1', 'Jason Moon', 'Jason Moon', 13379, 'advanced'),
  ('WA House of Representatives Legislative District 21 Position 2', 'Lillian Ortiz-Self', 'Lillian Ortiz-Self', 22909, 'advanced'),
  ('WA House of Representatives Legislative District 21 Position 2', 'Bruce Guthrie', 'Bruce Guthrie', 8430, 'advanced'),
  ('WA House of Representatives Legislative District 22 Position 1', 'Beth Doglio', 'Beth Doglio', 33979, 'advanced'),
  ('WA House of Representatives Legislative District 22 Position 1', 'Don Hewett', 'Don Hewett', 12329, 'advanced'),
  ('WA House of Representatives Legislative District 22 Position 2', 'Lisa Parshley', 'Lisa Parshley', 28156, 'advanced'),
  ('WA House of Representatives Legislative District 22 Position 2', 'Jamie Keenan-deVargas', 'Jamie Keenan-deVargas', 11907, 'advanced'),
  ('WA House of Representatives Legislative District 23 Position 1', 'Tarra Simmons', 'Tarra Simmons', 24583, 'advanced'),
  ('WA House of Representatives Legislative District 23 Position 1', 'Daria Ilgen', 'Daria Ilgen', 16753, 'advanced'),
  ('WA House of Representatives Legislative District 23 Position 2', 'Greg Nance', 'Greg Nance', 27915, 'advanced'),
  ('WA House of Representatives Legislative District 23 Position 2', 'Lance Byrd', 'Lance Byrd', 14202, 'advanced'),
  ('WA House of Representatives Legislative District 23 Position 2', 'Kristin Lillegard', 'Kristin Lillegard', 5882, 'not_nominated'),
  ('WA House of Representatives Legislative District 24 Position 1', 'Adam Bernbaum', 'Adam Bernbaum', 32592, 'advanced'),
  ('WA House of Representatives Legislative District 24 Position 1', 'Eric W. Pratt', 'Eric W. Pratt', 11779, 'advanced'),
  ('WA House of Representatives Legislative District 24 Position 1', 'Aiden I.R. Hamilton', 'Aiden I.R. Hamilton', 5930, 'not_nominated'),
  ('WA House of Representatives Legislative District 24 Position 1', 'Ted Bowen', 'Ted Bowen', 3643, 'not_nominated'),
  ('WA House of Representatives Legislative District 24 Position 2', 'Marcia Kelbon', 'Marcia Kelbon', 19818, 'advanced'),
  ('WA House of Representatives Legislative District 24 Position 2', 'Kaylee Kuehn', 'Kaylee Kuehn', 13617, 'advanced'),
  ('WA House of Representatives Legislative District 24 Position 2', 'Patrick DePoe', 'Patrick DePoe', 12699, 'not_nominated'),
  ('WA House of Representatives Legislative District 24 Position 2', 'Mark Hodgson', 'Mark Hodgson', 3644, 'not_nominated'),
  ('WA House of Representatives Legislative District 24 Position 2', 'Bradley Nemo Callaway', 'Bradley Nemo Callaway', 2374, 'not_nominated'),
  ('WA House of Representatives Legislative District 25 Position 1', 'Michael Keaton', 'Michael Keaton', 14460, 'advanced'),
  ('WA House of Representatives Legislative District 25 Position 1', 'David Berg', 'David Berg', 10454, 'advanced'),
  ('WA House of Representatives Legislative District 25 Position 1', 'Nick Oloo', 'Nick Oloo', 3880, 'not_nominated'),
  ('WA House of Representatives Legislative District 25 Position 2', 'Cyndy Jacobsen', 'Cyndy Jacobsen', 14005, 'advanced'),
  ('WA House of Representatives Legislative District 25 Position 2', 'Jenn Marie Strickling', 'Jenn Marie Strickling', 13466, 'advanced'),
  ('WA House of Representatives Legislative District 25 Position 2', 'Ren Fanony', 'Ren Fanony', 1333, 'not_nominated'),
  ('WA House of Representatives Legislative District 26 Position 1', 'David Olson', 'David Olson', 22256, 'advanced'),
  ('WA House of Representatives Legislative District 26 Position 1', 'Adison Richards', 'Adison Richards', 17012, 'advanced'),
  ('WA House of Representatives Legislative District 26 Position 1', 'Natalie Bornfleth', 'Natalie Bornfleth', 11467, 'not_nominated'),
  ('WA House of Representatives Legislative District 26 Position 2', 'Katy Cornell', 'Katy Cornell', 22635, 'advanced'),
  ('WA House of Representatives Legislative District 26 Position 2', 'Renee Hernandez Greenfield', 'Renee Hernandez Greenfield', 20023, 'advanced'),
  ('WA House of Representatives Legislative District 26 Position 2', 'Tedd Wetherbee', 'Tedd Wetherbee', 6720, 'not_nominated'),
  ('WA House of Representatives Legislative District 26 Position 2', 'Randy Phillips', 'Randy Phillips', 1213, 'not_nominated'),
  ('WA House of Representatives Legislative District 27 Position 1', 'Laurie Jinkins', 'Laurie Jinkins', 26099, 'advanced'),
  ('WA House of Representatives Legislative District 27 Position 1', 'Carole Sue Braaten', 'Carole Sue Braaten', 7580, 'advanced'),
  ('WA House of Representatives Legislative District 27 Position 2', 'Jake Fey', 'Jake Fey', 26333, 'advanced'),
  ('WA House of Representatives Legislative District 28 Position 1', 'Mari Leavitt', 'Mari Leavitt', 16321, 'advanced'),
  ('WA House of Representatives Legislative District 28 Position 1', 'Kathy Richardson', 'Kathy Richardson', 8927, 'advanced'),
  ('WA House of Representatives Legislative District 28 Position 2', 'Dan Bronoske', 'Dan Bronoske', 17782, 'advanced'),
  ('WA House of Representatives Legislative District 29 Position 1', 'Krista Perez', 'Krista Perez', 8245, 'advanced'),
  ('WA House of Representatives Legislative District 29 Position 1', 'Melanie Morgan', 'Melanie Morgan', 7858, 'advanced'),
  ('WA House of Representatives Legislative District 29 Position 2', 'Joe Bushnell', 'Joe Bushnell', 4092, 'advanced'),
  ('WA House of Representatives Legislative District 29 Position 2', 'Patrick Stickney', 'Patrick Stickney', 3784, 'advanced'),
  ('WA House of Representatives Legislative District 29 Position 2', 'Natasha Laitila', 'Natasha Laitila', 3612, 'not_nominated'),
  ('WA House of Representatives Legislative District 29 Position 2', 'Darek Blum', 'Darek Blum', 3332, 'not_nominated'),
  ('WA House of Representatives Legislative District 29 Position 2', 'Sheri Hayes', 'Sheri Hayes', 2255, 'not_nominated'),
  ('WA House of Representatives Legislative District 29 Position 2', 'Erin Chapman-Smith', 'Erin Chapman-Smith', 1793, 'not_nominated'),
  ('WA House of Representatives Legislative District 3 Position 1', 'Natasha Hill', 'Natasha Hill', 27075, 'advanced'),
  ('WA House of Representatives Legislative District 3 Position 1', 'Tony Kiepe', 'Tony Kiepe', 12705, 'advanced'),
  ('WA House of Representatives Legislative District 3 Position 1', 'John Kness', 'John Kness', 2197, 'not_nominated'),
  ('WA House of Representatives Legislative District 3 Position 2', 'Natalie Poulson', 'Natalie Poulson', 13790, 'advanced'),
  ('WA House of Representatives Legislative District 3 Position 2', 'Luc Jasmin III', 'Luc Jasmin III', 13581, 'advanced'),
  ('WA House of Representatives Legislative District 3 Position 2', 'Pam Kohlmeier', 'Pam Kohlmeier', 12662, 'not_nominated'),
  ('WA House of Representatives Legislative District 3 Position 2', 'Donovan Arnold DeLeon', 'Donovan Arnold DeLeon', 1850, 'not_nominated'),
  ('WA House of Representatives Legislative District 30 Position 1', 'Jamila E. Taylor', 'Jamila E. Taylor', 14957, 'advanced'),
  ('WA House of Representatives Legislative District 30 Position 1', 'Tiffany Bowyer', 'Tiffany Bowyer', 8404, 'advanced'),
  ('WA House of Representatives Legislative District 30 Position 2', 'Kristine Reeves', 'Kristine Reeves', 14714, 'advanced'),
  ('WA House of Representatives Legislative District 30 Position 2', 'Paul McDaniel', 'Paul McDaniel', 8275, 'advanced'),
  ('WA House of Representatives Legislative District 31 Position 1', 'Drew Stokesbary', 'Drew Stokesbary', 19674, 'advanced'),
  ('WA House of Representatives Legislative District 31 Position 1', 'Stephen Szczurko-Walton', 'Stephen Szczurko-Walton', 14299, 'advanced'),
  ('WA House of Representatives Legislative District 31 Position 2', 'Joshua Penner', 'Joshua Penner', 19039, 'advanced'),
  ('WA House of Representatives Legislative District 31 Position 2', 'John Bielka', 'John Bielka', 14915, 'advanced'),
  ('WA House of Representatives Legislative District 32 Position 1', 'Keith Scully', 'Keith Scully', 10698, 'advanced'),
  ('WA House of Representatives Legislative District 32 Position 1', 'Danica Noble', 'Danica Noble', 9735, 'advanced'),
  ('WA House of Representatives Legislative District 32 Position 1', 'Lisa Rezac', 'Lisa Rezac', 7612, 'not_nominated'),
  ('WA House of Representatives Legislative District 32 Position 1', 'Will Chen', 'Will Chen', 4415, 'not_nominated'),
  ('WA House of Representatives Legislative District 32 Position 1', 'Chris Bloomquist', 'Chris Bloomquist', 4044, 'not_nominated'),
  ('WA House of Representatives Legislative District 32 Position 1', 'Jenna Nand', 'Jenna Nand', 3697, 'not_nominated'),
  ('WA House of Representatives Legislative District 32 Position 2', 'Lauren Davis', 'Lauren Davis', 26708, 'advanced'),
  ('WA House of Representatives Legislative District 32 Position 2', 'Imraan Siddiqi', 'Imraan Siddiqi', 9791, 'advanced'),
  ('WA House of Representatives Legislative District 33 Position 1', 'Edwin Obras', 'Edwin Obras', 18352, 'advanced'),
  ('WA House of Representatives Legislative District 33 Position 1', 'Chris Martinez', 'Chris Martinez', 3934, 'advanced'),
  ('WA House of Representatives Legislative District 33 Position 1', 'Darryl K. Jones', 'Darryl K. Jones', 3567, 'not_nominated'),
  ('WA House of Representatives Legislative District 33 Position 2', 'Mia Su-Ling Gregerson', 'Mia Su-Ling Gregerson', 13795, 'advanced'),
  ('WA House of Representatives Legislative District 33 Position 2', 'Yuri Marinchik', 'Yuri Marinchik', 6317, 'advanced'),
  ('WA House of Representatives Legislative District 33 Position 2', 'Alex Andrade', 'Alex Andrade', 5717, 'not_nominated'),
  ('WA House of Representatives Legislative District 34 Position 1', 'Brianna K. Thomas', 'Brianna K. Thomas', 34217, 'advanced'),
  ('WA House of Representatives Legislative District 34 Position 2', 'Joe Fitzgibbon', 'Joe Fitzgibbon', 30680, 'advanced'),
  ('WA House of Representatives Legislative District 34 Position 2', 'Mary Anito', 'Mary Anito', 9999, 'advanced'),
  ('WA House of Representatives Legislative District 35 Position 1', 'Dan Griffey', 'Dan Griffey', 26669, 'advanced'),
  ('WA House of Representatives Legislative District 35 Position 1', 'Jim Pierson', 'Jim Pierson', 14047, 'advanced'),
  ('WA House of Representatives Legislative District 35 Position 1', 'Shaena Garberich', 'Shaena Garberich', 9320, 'not_nominated'),
  ('WA House of Representatives Legislative District 35 Position 2', 'Travis Couture', 'Travis Couture', 26651, 'advanced'),
  ('WA House of Representatives Legislative District 35 Position 2', 'Maria Littlesun', 'Maria Littlesun', 23368, 'advanced'),
  ('WA House of Representatives Legislative District 36 Position 1', 'Julia Grant Reed', 'Julia Grant Reed', 40696, 'advanced'),
  ('WA House of Representatives Legislative District 36 Position 2', 'Liz Berry', 'Liz Berry', 40870, 'advanced'),
  ('WA House of Representatives Legislative District 37 Position 1', 'Kelabe Tewolde', 'Kelabe Tewolde', 19902, 'advanced'),
  ('WA House of Representatives Legislative District 37 Position 1', 'Sharon Tomiko Santos', 'Sharon Tomiko Santos', 18517, 'advanced'),
  ('WA House of Representatives Legislative District 37 Position 2', 'Jaelynn Scott', 'Jaelynn Scott', 33678, 'advanced'),
  ('WA House of Representatives Legislative District 37 Position 2', 'Evon McCorkle', 'Evon McCorkle', 4143, 'advanced'),
  ('WA House of Representatives Legislative District 38 Position 1', 'Julio Cortes', 'Julio Cortes', 13707, 'advanced'),
  ('WA House of Representatives Legislative District 38 Position 1', 'Thomas (Jeff) Kelly', 'Thomas (Jeff) Kelly', 7627, 'advanced'),
  ('WA House of Representatives Legislative District 38 Position 1', 'Annie Fitzgerald', 'Annie Fitzgerald', 5176, 'not_nominated'),
  ('WA House of Representatives Legislative District 38 Position 2', 'Mary Fosse', 'Mary Fosse', 20443, 'advanced'),
  ('WA House of Representatives Legislative District 39 Position 1', 'Kathryn Lewandowsky', 'Kathryn Lewandowsky', 15940, 'advanced'),
  ('WA House of Representatives Legislative District 39 Position 1', 'Sam Low', 'Sam Low', 15836, 'advanced'),
  ('WA House of Representatives Legislative District 39 Position 1', 'Dusty Wisniew', 'Dusty Wisniew', 4912, 'not_nominated'),
  ('WA House of Representatives Legislative District 39 Position 2', 'Ida Keeley', 'Ida Keeley', 16742, 'advanced'),
  ('WA House of Representatives Legislative District 39 Position 2', 'Steve Ewing', 'Steve Ewing', 9817, 'advanced'),
  ('WA House of Representatives Legislative District 39 Position 2', 'Robert J Sutherland', 'Robert J Sutherland', 9072, 'not_nominated'),
  ('WA House of Representatives Legislative District 39 Position 2', 'Lacey Sauvageau', 'Lacey Sauvageau', 937, 'not_nominated'),
  ('WA House of Representatives Legislative District 4 Position 1', 'Hillary Q. Pham', 'Hillary Q. Pham', 11278, 'advanced'),
  ('WA House of Representatives Legislative District 4 Position 1', 'Trent Maier', 'Trent Maier', 10583, 'advanced'),
  ('WA House of Representatives Legislative District 4 Position 1', 'Debra Long', 'Debra Long', 6498, 'not_nominated'),
  ('WA House of Representatives Legislative District 4 Position 1', 'George Wagner', 'George Wagner', 6002, 'not_nominated'),
  ('WA House of Representatives Legislative District 4 Position 2', 'Rob Chase', 'Rob Chase', 17757, 'advanced'),
  ('WA House of Representatives Legislative District 4 Position 2', 'Rob Tupper', 'Rob Tupper', 16778, 'advanced'),
  ('WA House of Representatives Legislative District 4 Position 2', 'Bob Curtis', 'Bob Curtis', 6731, 'not_nominated'),
  ('WA House of Representatives Legislative District 40 Position 1', 'Debra Lekanoff', 'Debra Lekanoff', 34514, 'advanced'),
  ('WA House of Representatives Legislative District 40 Position 1', 'Cindy Carter', 'Cindy Carter', 12966, 'advanced'),
  ('WA House of Representatives Legislative District 40 Position 2', 'Alex Ramel', 'Alex Ramel', 31216, 'advanced'),
  ('WA House of Representatives Legislative District 40 Position 2', 'Joseph Segault', 'Joseph Segault', 5988, 'advanced'),
  ('WA House of Representatives Legislative District 40 Position 2', 'Salomon Rodrigue Mbouombouo', 'Salomon Rodrigue Mbouombouo', 4903, 'not_nominated'),
  ('WA House of Representatives Legislative District 40 Position 2', 'Monte Jay Mahan', 'Monte Jay Mahan', 3833, 'not_nominated'),
  ('WA House of Representatives Legislative District 41 Position 1', 'Janice Zahn', 'Janice Zahn', 26578, 'advanced'),
  ('WA House of Representatives Legislative District 41 Position 1', 'Elle Nguyen', 'Elle Nguyen', 9871, 'advanced'),
  ('WA House of Representatives Legislative District 41 Position 1', 'Alex Tsimerman', 'Alex Tsimerman', 385, 'not_nominated'),
  ('WA House of Representatives Legislative District 41 Position 2', 'My-Linh T Thai', 'My-Linh T Thai', 24035, 'advanced'),
  ('WA House of Representatives Legislative District 41 Position 2', 'Michael Rosen', 'Michael Rosen', 12106, 'advanced'),
  ('WA House of Representatives Legislative District 42 Position 1', 'Alicia Rule', 'Alicia Rule', 27934, 'advanced'),
  ('WA House of Representatives Legislative District 42 Position 1', 'Misty Flowers', 'Misty Flowers', 21655, 'advanced'),
  ('WA House of Representatives Legislative District 42 Position 2', 'Joe Timmons', 'Joe Timmons', 26802, 'advanced'),
  ('WA House of Representatives Legislative District 42 Position 2', 'Justin Pike', 'Justin Pike', 22911, 'advanced'),
  ('WA House of Representatives Legislative District 43 Position 1', 'Nicole Macri', 'Nicole Macri', 32872, 'advanced'),
  ('WA House of Representatives Legislative District 43 Position 1', 'Alby Clendennin', 'Alby Clendennin', 2647, 'advanced'),
  ('WA House of Representatives Legislative District 43 Position 2', 'Shaun Scott', 'Shaun Scott', 29474, 'advanced'),
  ('WA House of Representatives Legislative District 44 Position 1', 'Brandy Donaghy', 'Brandy Donaghy', 21460, 'advanced'),
  ('WA House of Representatives Legislative District 44 Position 1', 'Chris Elder', 'Chris Elder', 14485, 'advanced'),
  ('WA House of Representatives Legislative District 44 Position 2', 'April Berg', 'April Berg', 22107, 'advanced'),
  ('WA House of Representatives Legislative District 44 Position 2', 'Tonya Stadlman', 'Tonya Stadlman', 13863, 'advanced'),
  ('WA House of Representatives Legislative District 45 Position 1', 'Roger Goodman', 'Roger Goodman', 27038, 'advanced'),
  ('WA House of Representatives Legislative District 45 Position 1', 'JoAnn Tolentino', 'JoAnn Tolentino', 9967, 'advanced'),
  ('WA House of Representatives Legislative District 45 Position 2', 'Vanessa Kritzer', 'Vanessa Kritzer', 22890, 'advanced'),
  ('WA House of Representatives Legislative District 45 Position 2', 'John P Gibbons', 'John P Gibbons', 7630, 'advanced'),
  ('WA House of Representatives Legislative District 45 Position 2', 'Chandler Torbett', 'Chandler Torbett', 5873, 'not_nominated'),
  ('WA House of Representatives Legislative District 46 Position 1', 'Gerry Pollet', 'Gerry Pollet', 22807, 'advanced'),
  ('WA House of Representatives Legislative District 46 Position 1', 'Will Dreher', 'Will Dreher', 13592, 'advanced'),
  ('WA House of Representatives Legislative District 46 Position 1', 'Ron Davis', 'Ron Davis', 7441, 'not_nominated'),
  ('WA House of Representatives Legislative District 46 Position 2', 'Darya Farivar', 'Darya Farivar', 39373, 'advanced'),
  ('WA House of Representatives Legislative District 46 Position 2', 'Rodney ''Star'' Thornley', 'Rodney ''Star'' Thornley', 4386, 'advanced'),
  ('WA House of Representatives Legislative District 47 Position 1', 'Debra Jean Entenman', 'Debra Jean Entenman', 10619, 'advanced'),
  ('WA House of Representatives Legislative District 47 Position 1', 'Cobi Clark', 'Cobi Clark', 8361, 'advanced'),
  ('WA House of Representatives Legislative District 47 Position 1', 'Jasnoor Kaur Hans', 'Jasnoor Kaur Hans', 5647, 'not_nominated'),
  ('WA House of Representatives Legislative District 47 Position 1', 'Logan Evans', 'Logan Evans', 3047, 'not_nominated'),
  ('WA House of Representatives Legislative District 47 Position 2', 'Chris Stearns', 'Chris Stearns', 17457, 'advanced'),
  ('WA House of Representatives Legislative District 47 Position 2', 'Ted Cooke', 'Ted Cooke', 11521, 'advanced'),
  ('WA House of Representatives Legislative District 48 Position 1', 'Osman Salahuddin', 'Osman Salahuddin', 18388, 'advanced'),
  ('WA House of Representatives Legislative District 48 Position 1', 'Jeffery Poppe', 'Jeffery Poppe', 7599, 'advanced'),
  ('WA House of Representatives Legislative District 48 Position 2', 'Jessica Forsythe', 'Jessica Forsythe', 11708, 'advanced'),
  ('WA House of Representatives Legislative District 48 Position 2', 'Amy Walen', 'Amy Walen', 11691, 'advanced'),
  ('WA House of Representatives Legislative District 49 Position 1', 'Kim D. Harless', 'Kim D. Harless', 17809, 'advanced'),
  ('WA House of Representatives Legislative District 49 Position 1', 'Sarah Mittelman', 'Sarah Mittelman', 9652, 'advanced'),
  ('WA House of Representatives Legislative District 49 Position 1', 'Mike Pond', 'Mike Pond', 6387, 'not_nominated'),
  ('WA House of Representatives Legislative District 49 Position 2', 'Monica Jurado Stonier', 'Monica Jurado Stonier', 24398, 'advanced'),
  ('WA House of Representatives Legislative District 49 Position 2', 'Derek Thompson', 'Derek Thompson', 9095, 'advanced'),
  ('WA House of Representatives Legislative District 5 Position 1', 'Zach Hall', 'Zach Hall', 18294, 'advanced'),
  ('WA House of Representatives Legislative District 5 Position 1', 'Michelle Bennett', 'Michelle Bennett', 17681, 'advanced'),
  ('WA House of Representatives Legislative District 5 Position 1', 'Aimee Warmerdam', 'Aimee Warmerdam', 3994, 'not_nominated'),
  ('WA House of Representatives Legislative District 5 Position 1', 'Topher Leritz', 'Topher Leritz', 1083, 'not_nominated'),
  ('WA House of Representatives Legislative District 5 Position 2', 'Lisa Callan', 'Lisa Callan', 23812, 'advanced'),
  ('WA House of Representatives Legislative District 5 Position 2', 'Patrick Peacock', 'Patrick Peacock', 17449, 'advanced'),
  ('WA House of Representatives Legislative District 6 Position 1', 'Michaela Kelso', 'Michaela Kelso', 11093, 'advanced'),
  ('WA House of Representatives Legislative District 6 Position 1', 'Alan Nolan', 'Alan Nolan', 9450, 'advanced'),
  ('WA House of Representatives Legislative District 6 Position 1', 'Isaiah Paine', 'Isaiah Paine', 7035, 'not_nominated'),
  ('WA House of Representatives Legislative District 6 Position 1', 'Nicolette Ocheltree', 'Nicolette Ocheltree', 4313, 'not_nominated'),
  ('WA House of Representatives Legislative District 6 Position 1', 'Jennifer Morton', 'Jennifer Morton', 2640, 'not_nominated'),
  ('WA House of Representatives Legislative District 6 Position 1', 'Sueann Davis', 'Sueann Davis', 1732, 'not_nominated'),
  ('WA House of Representatives Legislative District 6 Position 2', 'Jonathan Bingle', 'Jonathan Bingle', 18651, 'advanced'),
  ('WA House of Representatives Legislative District 6 Position 2', 'Julia Payne', 'Julia Payne', 9209, 'advanced'),
  ('WA House of Representatives Legislative District 6 Position 2', 'Aaron M. Croft', 'Aaron M. Croft', 8950, 'not_nominated'),
  ('WA House of Representatives Legislative District 7 Position 1', 'Andrew Engell', 'Andrew Engell', 30454, 'advanced'),
  ('WA House of Representatives Legislative District 7 Position 2', 'Hunter Abell', 'Hunter Abell', 30220, 'advanced'),
  ('WA House of Representatives Legislative District 8 Position 1', 'Stephanie Barnard', 'Stephanie Barnard', 24103, 'advanced'),
  ('WA House of Representatives Legislative District 8 Position 2', 'April Connors', 'April Connors', 24314, 'advanced'),
  ('WA House of Representatives Legislative District 9 Position 1', 'Mary Dye', 'Mary Dye', 29519, 'advanced'),
  ('WA House of Representatives Legislative District 9 Position 2', 'Joe Schmick', 'Joe Schmick', 26118, 'advanced'),
  ('WA House of Representatives Legislative District 9 Position 2', 'Karina Wallace', 'Karina Wallace', 15534, 'advanced'),
  ('WA State Senate Legislative District 13', 'Alex Ybarra', 'Alex Ybarra', 23489, 'advanced'),
  ('WA State Senate Legislative District 15', 'Jeremie Dufault', 'Jeremie Dufault', 23718, 'advanced'),
  ('WA State Senate Legislative District 21', 'Marko Liias', 'Marko Liias', 23290, 'advanced'),
  ('WA State Senate Legislative District 21', 'Riaz Khan', 'Riaz Khan', 8873, 'advanced'),
  ('WA State Senate Legislative District 26', 'Deborah Krishnadasan', 'Deborah Krishnadasan', 28575, 'advanced'),
  ('WA State Senate Legislative District 26', 'Gary Parker', 'Gary Parker', 22328, 'advanced'),
  ('WA State Senate Legislative District 29', 'Sharlett Mena', 'Sharlett Mena', 12071, 'advanced'),
  ('WA State Senate Legislative District 29', 'David Anderson', 'David Anderson', 4440, 'advanced'),
  ('WA State Senate Legislative District 30', 'Claire Wilson', 'Claire Wilson', 14561, 'advanced'),
  ('WA State Senate Legislative District 30', 'Michael Rutland', 'Michael Rutland', 8865, 'advanced'),
  ('WA State Senate Legislative District 31', 'Phil Fortunato', 'Phil Fortunato', 18583, 'advanced'),
  ('WA State Senate Legislative District 31', 'Tamara Stramel', 'Tamara Stramel', 15638, 'advanced'),
  ('WA State Senate Legislative District 32', 'Cindy Ryu', 'Cindy Ryu', 17876, 'advanced'),
  ('WA State Senate Legislative District 32', 'Jesse Salomon', 'Jesse Salomon', 15221, 'advanced'),
  ('WA State Senate Legislative District 32', 'Ira McBee', 'Ira McBee', 7312, 'not_nominated'),
  ('WA State Senate Legislative District 33', 'Tina L. Orwall', 'Tina L. Orwall', 19890, 'advanced'),
  ('WA State Senate Legislative District 34', 'Emily Alvarado', 'Emily Alvarado', 34790, 'advanced'),
  ('WA State Senate Legislative District 35', 'Drew C MacEwen', 'Drew C MacEwen', 25643, 'advanced'),
  ('WA State Senate Legislative District 35', 'Carolina Mejia', 'Carolina Mejia', 24574, 'advanced'),
  ('WA State Senate Legislative District 36', 'Noel C. Frame', 'Noel C. Frame', 42548, 'advanced'),
  ('WA State Senate Legislative District 36', 'Jillian England', 'Jillian England', 5876, 'advanced'),
  ('WA State Senate Legislative District 37', 'Chipalo Street', 'Chipalo Street', 28196, 'advanced'),
  ('WA State Senate Legislative District 37', 'Tatiana Brown', 'Tatiana Brown', 9729, 'advanced'),
  ('WA State Senate Legislative District 38', 'June Robinson', 'June Robinson', 18608, 'advanced'),
  ('WA State Senate Legislative District 38', 'Brad Bender', 'Brad Bender', 9450, 'advanced'),
  ('WA State Senate Legislative District 43', 'Jamie Pedersen', 'Jamie Pedersen', 25454, 'advanced'),
  ('WA State Senate Legislative District 43', 'Hannah Sabio-Howell', 'Hannah Sabio-Howell', 8990, 'advanced'),
  ('WA State Senate Legislative District 43', 'Heather-Marie Wilson', 'Heather-Marie Wilson', 3638, 'not_nominated'),
  ('WA State Senate Legislative District 44', 'John Lovick', 'John Lovick', 22347, 'advanced'),
  ('WA State Senate Legislative District 44', 'Sherri Larkin', 'Sherri Larkin', 13724, 'advanced'),
  ('WA State Senate Legislative District 45', 'Manka Dhingra', 'Manka Dhingra', 26547, 'advanced'),
  ('WA State Senate Legislative District 46', 'Javier Valdez', 'Javier Valdez', 40980, 'advanced'),
  ('WA State Senate Legislative District 46', 'Sandra Stephens', 'Sandra Stephens', 4153, 'advanced'),
  ('WA State Senate Legislative District 47', 'Claudia Kauffman', 'Claudia Kauffman', 17258, 'advanced'),
  ('WA State Senate Legislative District 47', 'Kristina Soltys', 'Kristina Soltys', 11807, 'advanced'),
  ('WA State Senate Legislative District 48', 'Vandana Slatter', 'Vandana Slatter', 19677, 'advanced'),
  ('WA State Senate Legislative District 6', 'Jeff Holy', 'Jeff Holy', 24422, 'advanced'),
  ('WA State Senate Legislative District 7', 'Shelly Short', 'Shelly Short', 24089, 'advanced'),
  ('WA State Senate Legislative District 7', 'Ronald L McCoy', 'Ronald L McCoy', 11061, 'advanced'),
  ('WA State Senate Legislative District 7', 'Brandon Ray Medina', 'Brandon Ray Medina', 3489, 'not_nominated'),
  ('WA State Senate Legislative District 7', 'David Swoap', 'David Swoap', 2341, 'not_nominated'),
  ('WA State Senate Legislative District 8', 'Nikki Torres', 'Nikki Torres', 16065, 'advanced'),
  ('WA State Senate Legislative District 8', 'Gabe Galbraith', 'Gabe Galbraith', 14297, 'advanced');

-- ── per-contest provenance, used to BUILD result_source from the same numbers ───────────────
CREATE TEMP TABLE wa_cert_contest (
  position_name text PRIMARY KEY,
  contest_name  text NOT NULL,
  feed_url      text NOT NULL,
  cert_note     text NOT NULL,
  total_votes   integer NOT NULL,   -- contest total INCLUDING the write-in line
  writein_votes integer NOT NULL
) ON COMMIT DROP;

INSERT INTO wa_cert_contest VALUES
  ('King County Assessor', 'Assessor', 'results.votewa.gov/results/public/api/elections/king-county-wa/20260804/data', 'King County Canvassing Board certification 2026-08-18; verified line-by-line against King County Elections webresults-20260818-final.csv', 492609, 1477),
  ('King County Council District 2', 'Metropolitan King County - Council District No. 2', 'results.votewa.gov/results/public/api/elections/king-county-wa/20260804/data', 'King County Canvassing Board certification 2026-08-18; verified line-by-line against King County Elections webresults-20260818-final.csv', 63185, 293),
  ('King County Council District 8', 'Metropolitan King County - Council District No. 8', 'results.votewa.gov/results/public/api/elections/king-county-wa/20260804/data', 'King County Canvassing Board certification 2026-08-18; verified line-by-line against King County Elections webresults-20260818-final.csv', 60188, 189),
  ('Kitsap County Assessor', 'Kitsap County Assessor', 'results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data', 'Kitsap County Canvassing Board certification 2026-08-18; verified line-by-line against the Kitsap County Auditor cumulative report (kitsap.gov/auditor/Documents/results.html, "Official Results", Run Date 08/18/2026, 321 of 321 precincts)', 82548, 113),
  ('Kitsap County Auditor', 'Kitsap County Auditor', 'results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data', 'Kitsap County Canvassing Board certification 2026-08-18; verified line-by-line against the Kitsap County Auditor cumulative report (kitsap.gov/auditor/Documents/results.html, "Official Results", Run Date 08/18/2026, 321 of 321 precincts)', 62155, 4499),
  ('Kitsap County Clerk', 'Kitsap County Clerk', 'results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data', 'Kitsap County Canvassing Board certification 2026-08-18; verified line-by-line against the Kitsap County Auditor cumulative report (kitsap.gov/auditor/Documents/results.html, "Official Results", Run Date 08/18/2026, 321 of 321 precincts)', 68932, 4955),
  ('Kitsap County Commissioner District 3', 'Kitsap County Commissioner District 3 Comm Dist 3', 'results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data', 'Kitsap County Canvassing Board certification 2026-08-18; verified line-by-line against the Kitsap County Auditor cumulative report (kitsap.gov/auditor/Documents/results.html, "Official Results", Run Date 08/18/2026, 321 of 321 precincts)', 25215, 27),
  ('Kitsap County Prosecuting Attorney', 'Kitsap County Prosecuting Attorney', 'results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data', 'Kitsap County Canvassing Board certification 2026-08-18; verified line-by-line against the Kitsap County Auditor cumulative report (kitsap.gov/auditor/Documents/results.html, "Official Results", Run Date 08/18/2026, 321 of 321 precincts)', 68803, 4931),
  ('Kitsap County Sheriff', 'Kitsap County Sheriff', 'results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data', 'Kitsap County Canvassing Board certification 2026-08-18; verified line-by-line against the Kitsap County Auditor cumulative report (kitsap.gov/auditor/Documents/results.html, "Official Results", Run Date 08/18/2026, 321 of 321 precincts)', 82990, 105),
  ('Kitsap County Treasurer', 'Kitsap County Treasurer', 'results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data', 'Kitsap County Canvassing Board certification 2026-08-18; verified line-by-line against the Kitsap County Auditor cumulative report (kitsap.gov/auditor/Documents/results.html, "Official Results", Run Date 08/18/2026, 321 of 321 precincts)', 60827, 4213),
  ('Seattle City Council District 5', 'Seattle City Council - District No. 5', 'results.votewa.gov/results/public/api/elections/king-county-wa/20260804/data', 'King County Canvassing Board certification 2026-08-18; verified line-by-line against King County Elections webresults-20260818-final.csv', 30191, 74),
  ('U.S. Representative District 1', 'U.S. Representative - Congressional District 1', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 160573, 221),
  ('U.S. Representative District 10', 'U.S. Representative - Congressional District 10', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 155922, 367),
  ('U.S. Representative District 2', 'U.S. Representative - Congressional District 2', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 209510, 181),
  ('U.S. Representative District 3', 'U.S. Representative - Congressional District 3', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 214491, 145),
  ('U.S. Representative District 4', 'U.S. Representative - Congressional District 4', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 142661, 117),
  ('U.S. Representative District 5', 'U.S. Representative - Congressional District 5', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 204209, 172),
  ('U.S. Representative District 6', 'U.S. Representative - Congressional District 6', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 225962, 141),
  ('U.S. Representative District 7', 'U.S. Representative - Congressional District 7', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 216741, 802),
  ('U.S. Representative District 8', 'U.S. Representative - Congressional District 8', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 191585, 360),
  ('U.S. Representative District 9', 'U.S. Representative - Congressional District 9', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 142356, 209),
  ('WA House of Representatives Legislative District 1 Position 1', 'State Representative Pos. 1 - Legislative District 1', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 39374, 70),
  ('WA House of Representatives Legislative District 1 Position 2', 'State Representative Pos. 2 - Legislative District 1', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 39457, 33),
  ('WA House of Representatives Legislative District 10 Position 1', 'State Representative Pos. 1 - Legislative District 10', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 48256, 40),
  ('WA House of Representatives Legislative District 10 Position 2', 'State Representative Pos. 2 - Legislative District 10', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 48227, 57),
  ('WA House of Representatives Legislative District 11 Position 1', 'State Representative Pos. 1 - Legislative District 11', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 25968, 33),
  ('WA House of Representatives Legislative District 11 Position 2', 'State Representative Pos. 2 - Legislative District 11', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 20659, 1083),
  ('WA House of Representatives Legislative District 12 Position 1', 'State Representative Pos. 1 - Legislative District 12', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 44276, 36),
  ('WA House of Representatives Legislative District 12 Position 2', 'State Representative Pos. 2 - Legislative District 12', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 44348, 30),
  ('WA House of Representatives Legislative District 13 Position 1', 'State Representative Pos. 1 - Legislative District 13', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 30807, 60),
  ('WA House of Representatives Legislative District 13 Position 2', 'State Representative Pos. 2 - Legislative District 13', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 26114, 474),
  ('WA House of Representatives Legislative District 14 Position 1', 'State Representative Pos. 1 - Legislative District 14', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 13151, 46),
  ('WA House of Representatives Legislative District 14 Position 2', 'State Representative Pos. 2 - Legislative District 14', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 13128, 30),
  ('WA House of Representatives Legislative District 15 Position 1', 'State Representative Pos. 1 - Legislative District 15', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 31126, 67),
  ('WA House of Representatives Legislative District 15 Position 2', 'State Representative Pos. 2 - Legislative District 15', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 30425, 131),
  ('WA House of Representatives Legislative District 16 Position 1', 'State Representative Pos. 1 - Legislative District 16', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 35397, 32),
  ('WA House of Representatives Legislative District 16 Position 2', 'State Representative Pos. 2 - Legislative District 16', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 35351, 27),
  ('WA House of Representatives Legislative District 17 Position 1', 'State Representative Pos. 1 - Legislative District 17', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 47191, 59),
  ('WA House of Representatives Legislative District 17 Position 2', 'State Representative Pos. 2 - Legislative District 17', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 47067, 72),
  ('WA House of Representatives Legislative District 18 Position 1', 'State Representative Pos. 1 - Legislative District 18', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 43945, 72),
  ('WA House of Representatives Legislative District 18 Position 2', 'State Representative Pos. 2 - Legislative District 18', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 43818, 86),
  ('WA House of Representatives Legislative District 19 Position 1', 'State Representative Pos. 1 - Legislative District 19', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 43450, 65),
  ('WA House of Representatives Legislative District 19 Position 2', 'State Representative Pos. 2 - Legislative District 19', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 42453, 67),
  ('WA House of Representatives Legislative District 2 Position 1', 'State Representative Pos. 1 - Legislative District 2', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 31660, 57),
  ('WA House of Representatives Legislative District 2 Position 2', 'State Representative Pos. 2 - Legislative District 2', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 31732, 42),
  ('WA House of Representatives Legislative District 20 Position 1', 'State Representative Pos. 1 - Legislative District 20', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 47975, 82),
  ('WA House of Representatives Legislative District 20 Position 2', 'State Representative Pos. 2 - Legislative District 20', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 47945, 77),
  ('WA House of Representatives Legislative District 21 Position 1', 'State Representative Pos. 1 - Legislative District 21', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 30274, 551),
  ('WA House of Representatives Legislative District 21 Position 2', 'State Representative Pos. 2 - Legislative District 21', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 31554, 215),
  ('WA House of Representatives Legislative District 22 Position 1', 'State Representative Pos. 1 - Legislative District 22', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 46436, 128),
  ('WA House of Representatives Legislative District 22 Position 2', 'State Representative Pos. 2 - Legislative District 22', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41278, 1215),
  ('WA House of Representatives Legislative District 23 Position 1', 'State Representative Pos. 1 - Legislative District 23', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 42944, 1608),
  ('WA House of Representatives Legislative District 23 Position 2', 'State Representative Pos. 2 - Legislative District 23', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 48036, 37),
  ('WA House of Representatives Legislative District 24 Position 1', 'State Representative Pos. 1 - Legislative District 24', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 53986, 42),
  ('WA House of Representatives Legislative District 24 Position 2', 'State Representative Pos. 2 - Legislative District 24', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 52420, 268),
  ('WA House of Representatives Legislative District 25 Position 1', 'State Representative Pos. 1 - Legislative District 25', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 28812, 18),
  ('WA House of Representatives Legislative District 25 Position 2', 'State Representative Pos. 2 - Legislative District 25', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 28823, 19),
  ('WA House of Representatives Legislative District 26 Position 1', 'State Representative Pos. 1 - Legislative District 26', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 50761, 26),
  ('WA House of Representatives Legislative District 26 Position 2', 'State Representative Pos. 2 - Legislative District 26', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 50619, 28),
  ('WA House of Representatives Legislative District 27 Position 1', 'State Representative Pos. 1 - Legislative District 27', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 33783, 104),
  ('WA House of Representatives Legislative District 27 Position 2', 'State Representative Pos. 2 - Legislative District 27', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 27563, 1230),
  ('WA House of Representatives Legislative District 28 Position 1', 'State Representative Pos. 1 - Legislative District 28', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 25307, 59),
  ('WA House of Representatives Legislative District 28 Position 2', 'State Representative Pos. 2 - Legislative District 28', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 19608, 1826),
  ('WA House of Representatives Legislative District 29 Position 1', 'State Representative Pos. 1 - Legislative District 29', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 16876, 773),
  ('WA House of Representatives Legislative District 29 Position 2', 'State Representative Pos. 2 - Legislative District 29', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 18899, 31),
  ('WA House of Representatives Legislative District 3 Position 1', 'State Representative Pos. 1 - Legislative District 3', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 42060, 83),
  ('WA House of Representatives Legislative District 3 Position 2', 'State Representative Pos. 2 - Legislative District 3', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41926, 43),
  ('WA House of Representatives Legislative District 30 Position 1', 'State Representative Pos. 1 - Legislative District 30', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 23390, 29),
  ('WA House of Representatives Legislative District 30 Position 2', 'State Representative Pos. 2 - Legislative District 30', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 23092, 103),
  ('WA House of Representatives Legislative District 31 Position 1', 'State Representative Pos. 1 - Legislative District 31', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 33996, 23),
  ('WA House of Representatives Legislative District 31 Position 2', 'State Representative Pos. 2 - Legislative District 31', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 33986, 32),
  ('WA House of Representatives Legislative District 32 Position 1', 'State Representative Pos. 1 - Legislative District 32', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 40234, 33),
  ('WA House of Representatives Legislative District 32 Position 2', 'State Representative Pos. 2 - Legislative District 32', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 37293, 794),
  ('WA House of Representatives Legislative District 33 Position 1', 'State Representative Pos. 1 - Legislative District 33', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 25919, 66),
  ('WA House of Representatives Legislative District 33 Position 2', 'State Representative Pos. 2 - Legislative District 33', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 25882, 53),
  ('WA House of Representatives Legislative District 34 Position 1', 'State Representative Pos. 1 - Legislative District 34', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 35161, 944),
  ('WA House of Representatives Legislative District 34 Position 2', 'State Representative Pos. 2 - Legislative District 34', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41171, 492),
  ('WA House of Representatives Legislative District 35 Position 1', 'State Representative Pos. 1 - Legislative District 35', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 50069, 33),
  ('WA House of Representatives Legislative District 35 Position 2', 'State Representative Pos. 2 - Legislative District 35', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 50070, 51),
  ('WA House of Representatives Legislative District 36 Position 1', 'State Representative Pos. 1 - Legislative District 36', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41442, 746),
  ('WA House of Representatives Legislative District 36 Position 2', 'State Representative Pos. 2 - Legislative District 36', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41647, 777),
  ('WA House of Representatives Legislative District 37 Position 1', 'State Representative Pos. 1 - Legislative District 37', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 38669, 250),
  ('WA House of Representatives Legislative District 37 Position 2', 'State Representative Pos. 2 - Legislative District 37', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 38138, 317),
  ('WA House of Representatives Legislative District 38 Position 1', 'State Representative Pos. 1 - Legislative District 38', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 26825, 315),
  ('WA House of Representatives Legislative District 38 Position 2', 'State Representative Pos. 2 - Legislative District 38', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 22087, 1644),
  ('WA House of Representatives Legislative District 39 Position 1', 'State Representative Pos. 1 - Legislative District 39', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 36718, 30),
  ('WA House of Representatives Legislative District 39 Position 2', 'State Representative Pos. 2 - Legislative District 39', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 36598, 30),
  ('WA House of Representatives Legislative District 4 Position 1', 'State Representative Pos. 1 - Legislative District 4', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 35780, 1419),
  ('WA House of Representatives Legislative District 4 Position 2', 'State Representative Pos. 2 - Legislative District 4', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41405, 139),
  ('WA House of Representatives Legislative District 40 Position 1', 'State Representative Pos. 1 - Legislative District 40', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 47539, 59),
  ('WA House of Representatives Legislative District 40 Position 2', 'State Representative Pos. 2 - Legislative District 40', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 46061, 121),
  ('WA House of Representatives Legislative District 41 Position 1', 'State Representative Pos. 1 - Legislative District 41', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 36891, 57),
  ('WA House of Representatives Legislative District 41 Position 2', 'State Representative Pos. 2 - Legislative District 41', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 36241, 100),
  ('WA House of Representatives Legislative District 42 Position 1', 'State Representative Pos. 1 - Legislative District 42', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 49691, 102),
  ('WA House of Representatives Legislative District 42 Position 2', 'State Representative Pos. 2 - Legislative District 42', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 49773, 60),
  ('WA House of Representatives Legislative District 43 Position 1', 'State Representative Pos. 1 - Legislative District 43', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 35913, 394),
  ('WA House of Representatives Legislative District 43 Position 2', 'State Representative Pos. 2 - Legislative District 43', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 30450, 976),
  ('WA House of Representatives Legislative District 44 Position 1', 'State Representative Pos. 1 - Legislative District 44', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 35980, 35),
  ('WA House of Representatives Legislative District 44 Position 2', 'State Representative Pos. 2 - Legislative District 44', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 36007, 37),
  ('WA House of Representatives Legislative District 45 Position 1', 'State Representative Pos. 1 - Legislative District 45', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 37093, 88),
  ('WA House of Representatives Legislative District 45 Position 2', 'State Representative Pos. 2 - Legislative District 45', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 36498, 105),
  ('WA House of Representatives Legislative District 46 Position 1', 'State Representative Pos. 1 - Legislative District 46', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 44205, 365),
  ('WA House of Representatives Legislative District 46 Position 2', 'State Representative Pos. 2 - Legislative District 46', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 44038, 279),
  ('WA House of Representatives Legislative District 47 Position 1', 'State Representative Pos. 1 - Legislative District 47', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 27988, 314),
  ('WA House of Representatives Legislative District 47 Position 2', 'State Representative Pos. 2 - Legislative District 47', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 29024, 46),
  ('WA House of Representatives Legislative District 48 Position 1', 'State Representative Pos. 1 - Legislative District 48', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 26047, 60),
  ('WA House of Representatives Legislative District 48 Position 2', 'State Representative Pos. 2 - Legislative District 48', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 23916, 517),
  ('WA House of Representatives Legislative District 49 Position 1', 'State Representative Pos. 1 - Legislative District 49', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 33901, 53),
  ('WA House of Representatives Legislative District 49 Position 2', 'State Representative Pos. 2 - Legislative District 49', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 33600, 107),
  ('WA House of Representatives Legislative District 5 Position 1', 'State Representative Pos. 1 - Legislative District 5', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41084, 32),
  ('WA House of Representatives Legislative District 5 Position 2', 'State Representative Pos. 2 - Legislative District 5', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41300, 39),
  ('WA House of Representatives Legislative District 6 Position 1', 'State Representative Pos. 1 - Legislative District 6', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 36358, 95),
  ('WA House of Representatives Legislative District 6 Position 2', 'State Representative Pos. 2 - Legislative District 6', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 36884, 74),
  ('WA House of Representatives Legislative District 7 Position 1', 'State Representative Pos. 1 - Legislative District 7', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 31519, 1065),
  ('WA House of Representatives Legislative District 7 Position 2', 'State Representative Pos. 2 - Legislative District 7', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 31266, 1046),
  ('WA House of Representatives Legislative District 8 Position 1', 'State Representative Pos. 1 - Legislative District 8', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 24751, 648),
  ('WA House of Representatives Legislative District 8 Position 2', 'State Representative Pos. 2 - Legislative District 8', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 24979, 665),
  ('WA House of Representatives Legislative District 9 Position 1', 'State Representative Pos. 1 - Legislative District 9', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 31209, 1690),
  ('WA House of Representatives Legislative District 9 Position 2', 'State Representative Pos. 2 - Legislative District 9', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41729, 77),
  ('WA State Senate Legislative District 13', 'State Senator - Legislative District 13', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 24154, 665),
  ('WA State Senate Legislative District 15', 'State Senator - Legislative District 15', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 24885, 1167),
  ('WA State Senate Legislative District 21', 'State Senator - Legislative District 21', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 32323, 160),
  ('WA State Senate Legislative District 26', 'State Senator - Legislative District 26', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 50944, 41),
  ('WA State Senate Legislative District 29', 'State Senator - Legislative District 29', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 17162, 651),
  ('WA State Senate Legislative District 30', 'State Senator - Legislative District 30', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 23441, 15),
  ('WA State Senate Legislative District 31', 'State Senator - Legislative District 31', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 34247, 26),
  ('WA State Senate Legislative District 32', 'State Senator - Legislative District 32', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 40458, 49),
  ('WA State Senate Legislative District 33', 'State Senator - Legislative District 33', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 20893, 1003),
  ('WA State Senate Legislative District 34', 'State Senator - Legislative District 34', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 35730, 940),
  ('WA State Senate Legislative District 35', 'State Senator - Legislative District 35', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 50277, 60),
  ('WA State Senate Legislative District 36', 'State Senator - Legislative District 36', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 48523, 99),
  ('WA State Senate Legislative District 37', 'State Senator - Legislative District 37', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 38230, 305),
  ('WA State Senate Legislative District 38', 'State Senator - Legislative District 38', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 28112, 54),
  ('WA State Senate Legislative District 43', 'State Senator - Legislative District 43', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 38177, 95),
  ('WA State Senate Legislative District 44', 'State Senator - Legislative District 44', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 36118, 47),
  ('WA State Senate Legislative District 45', 'State Senator - Legislative District 45', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 28952, 2405),
  ('WA State Senate Legislative District 46', 'State Senator - Legislative District 46', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 45250, 117),
  ('WA State Senate Legislative District 47', 'State Senator - Legislative District 47', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 29098, 33),
  ('WA State Senate Legislative District 48', 'State Senator - Legislative District 48', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 20639, 962),
  ('WA State Senate Legislative District 6', 'State Senator - Legislative District 6', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 26665, 2243),
  ('WA State Senate Legislative District 7', 'State Senator - Legislative District 7', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 41252, 272),
  ('WA State Senate Legislative District 8', 'State Senator - Legislative District 8', 'results.votewa.gov/results/public/api/elections/washington/20260804/data', 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)', 30873, 511);

-- ── resolve to race_candidates rows, 1:1, and REFUSE to proceed on any ambiguity ────────────
CREATE TEMP TABLE wa_cert_target AS
SELECT rc.id AS rc_id, t.position_name, t.cand_name, t.votes, t.disposition,
       'CERTIFIED canvass of the 2026-08-04 Washington top-two primary, "' || c.contest_name || '" ('
         || c.feed_url || ', election.isOfficialResults = true; ' || c.cert_note || '; fetched 2026-08-20). '
         || 'Advancing to the 2026-11-03 general: ' || adv.names || '. '
         || 'Full certified tally: ' || tot.tally || '. '
         || 'Contest total ' || to_char(c.total_votes, 'FM999,999,999') || ' votes'
         || CASE WHEN c.writein_votes > 0 THEN ' (including ' || to_char(c.writein_votes, 'FM999,999,999') || ' write-in)' ELSE '' END
         || '.' AS result_source
  FROM wa_cert_tally t
  JOIN wa_cert_contest c ON c.position_name = t.position_name
  JOIN essentials.races r
    ON r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
   AND r.position_name = t.position_name
  JOIN essentials.race_candidates rc
    ON rc.race_id = r.id
   AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key(t.cand_name)
  CROSS JOIN LATERAL (
    SELECT string_agg(t2.feed_name, ' and ' ORDER BY t2.votes DESC) AS names
      FROM wa_cert_tally t2
     WHERE t2.position_name = t.position_name AND t2.disposition = 'advanced'
  ) adv
  CROSS JOIN LATERAL (
    SELECT string_agg(t3.feed_name || ' ' || to_char(t3.votes, 'FM999,999,999'), ' / ' ORDER BY t3.votes DESC) AS tally
      FROM wa_cert_tally t3
     WHERE t3.position_name = t.position_name
  ) tot;

DO $$
DECLARE n_tally int; n_target int; n_dupe int;
BEGIN
  SELECT count(*) INTO n_tally  FROM wa_cert_tally;
  SELECT count(*) INTO n_target FROM wa_cert_target;
  SELECT count(*) INTO n_dupe   FROM (SELECT rc_id FROM wa_cert_target GROUP BY rc_id HAVING count(*) > 1) x;
  IF n_tally <> 381 THEN RAISE EXCEPTION 'tally is % rows, expected 381', n_tally; END IF;
  IF n_target <> 381 THEN RAISE EXCEPTION 'resolved % of 381 tally rows to race_candidates — a name did not match', n_target; END IF;
  IF n_dupe > 0 THEN RAISE EXCEPTION '% race_candidates rows matched more than one tally row', n_dupe; END IF;
END $$;

-- ── 1. the cull ────────────────────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET result = t.disposition,
       result_source = t.result_source,
       result_recorded_at = now(),
       last_verified_at = now(),
       provisional_until = NULL,
       updated_at = now()
  FROM wa_cert_target t
 WHERE rc.id = t.rc_id
   AND (rc.result IS DISTINCT FROM t.disposition
        OR rc.result_source IS DISTINCT FROM t.result_source
        OR rc.provisional_until IS NOT NULL);

-- ── 2. the 5 pre-ballot withdrawals, confirmed by ABSENCE from the certified canvass ────────
UPDATE essentials.race_candidates rc
   SET result = 'withdrew',
       result_source = 'Withdrew before the ballot was set. ABSENT from the certified canvass of the 2026-08-04 Washington top-two primary, "' || w.contest_name || '" (results.votewa.gov/results/public/api/elections/washington/20260804/data, election.isOfficialResults = true, WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; fetched 2026-08-20), which lists every name that appeared on the primary ballot for this contest. candidate_status was already ''withdrawn'' from the WA SoS candidate filings; this records the certified confirmation.',
       result_recorded_at = now(),
       last_verified_at = now(),
       provisional_until = NULL,
       updated_at = now()
  FROM (VALUES
        ('WA House of Representatives Legislative District 23 Position 1', 'Joel Ard', 'State Representative Pos. 1 - Legislative District 23'),
        ('WA House of Representatives Legislative District 29 Position 1', 'Brett Johnson', 'State Representative Pos. 1 - Legislative District 29'),
        ('WA House of Representatives Legislative District 6 Position 1', 'Julia Payne', 'State Representative Pos. 1 - Legislative District 6'),
        ('WA State Senate Legislative District 37', 'Emijah Smith', 'State Senator - Legislative District 37'),
        ('WA State Senate Legislative District 8', 'Douglas McKinley', 'State Senator - Legislative District 8')
       ) AS w(position_name, cand_name, contest_name)
  JOIN essentials.races r
    ON r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
   AND r.position_name = w.position_name
 WHERE rc.race_id = r.id
   AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key(w.cand_name)
   AND rc.candidate_status = 'withdrawn'
   AND (rc.result IS DISTINCT FROM 'withdrew' OR rc.provisional_until IS NOT NULL);

-- ── 3. the 4 King County offices that held no primary: field confirmed, no result to cite ───
UPDATE essentials.race_candidates rc
   SET provisional_until = NULL,
       last_verified_at = now(),
       updated_at = now()
  FROM essentials.races r
 WHERE rc.race_id = r.id
   AND r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
   AND r.position_name IN ('King County Council District 4', 'King County Council District 6', 'King County Director of Elections', 'King County Prosecuting Attorney')
   AND rc.provisional_until IS NOT NULL;

-- ── 4. LD 42 Senate: HELD for the 2026-08-25 mandatory hand recount ─────────────────────────
UPDATE essentials.race_candidates rc
   SET provisional_until = DATE '2026-09-04',
       last_verified_at = now(),
       updated_at = now()
  FROM essentials.races r
 WHERE rc.race_id = r.id
   AND r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
   AND r.position_name = 'WA State Senate Legislative District 42'
   AND rc.provisional_until IS DISTINCT FROM DATE '2026-09-04';

-- ── POST-VERIFY: every assertion below is a POSITIVE fact about the end state ───────────────
DO $$
DECLARE
  n_adv int; n_not int; n_wd int; n_null int; n_live int;
  n_ld42 int; n_ld42_prov int; n_noprim int; n_stale int; n_overfull int; n_nosrc int;
BEGIN
  SELECT count(*) FILTER (WHERE rc.result = 'advanced'),
         count(*) FILTER (WHERE rc.result = 'not_nominated'),
         count(*) FILTER (WHERE rc.result = 'withdrew'),
         count(*) FILTER (WHERE rc.result IS NULL),
         count(*) FILTER (WHERE essentials.is_live_candidate(rc.candidate_status, rc.result))
    INTO n_adv, n_not, n_wd, n_null, n_live
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d';

  IF n_adv <> 262 THEN RAISE EXCEPTION 'advanced = %, expected 262', n_adv; END IF;
  IF n_not <> 119 THEN RAISE EXCEPTION 'not_nominated = %, expected 119', n_not; END IF;
  IF n_wd  <> 5   THEN RAISE EXCEPTION 'withdrew = %, expected 5', n_wd; END IF;
  IF n_null <> 8  THEN RAISE EXCEPTION 'result IS NULL = %, expected 8 (4 LD42 + 4 unopposed King County)', n_null; END IF;
  IF n_live <> 270 THEN RAISE EXCEPTION 'live candidates = %, expected 270', n_live; END IF;

  -- LD 42 must still be a FOUR-WAY UNRESOLVED field held to 2026-09-04. Asserting the
  -- positive fact, not "nothing was culled" — a count of 0 culls would pass vacuously.
  SELECT count(*), count(*) FILTER (WHERE rc.provisional_until = DATE '2026-09-04' AND rc.result IS NULL)
    INTO n_ld42, n_ld42_prov
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
     AND r.position_name = 'WA State Senate Legislative District 42';
  IF n_ld42 <> 4 OR n_ld42_prov <> 4 THEN
    RAISE EXCEPTION 'LD 42 Senate: % rows, % held unresolved to 2026-09-04 — expected 4 and 4', n_ld42, n_ld42_prov;
  END IF;

  -- The 4 unopposed King County offices: one live candidate each, no result, no expiry.
  SELECT count(*) INTO n_noprim
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
     AND r.position_name IN ('King County Council District 4', 'King County Council District 6', 'King County Director of Elections', 'King County Prosecuting Attorney')
     AND rc.result IS NULL AND rc.provisional_until IS NULL
     AND essentials.is_live_candidate(rc.candidate_status, rc.result);
  IF n_noprim <> 4 THEN RAISE EXCEPTION 'unopposed King County offices: % live unexpiring rows, expected 4', n_noprim; END IF;

  -- No race may carry more than TWO live candidates: that is what a top-two general is.
  SELECT count(*) INTO n_overfull FROM (
    SELECT r.id
      FROM essentials.races r
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
       AND r.position_name <> 'WA State Senate Legislative District 42'
       AND essentials.is_live_candidate(rc.candidate_status, rc.result)
     GROUP BY r.id HAVING count(*) > 2
  ) x;
  IF n_overfull > 0 THEN RAISE EXCEPTION '% races still carry more than two live candidates', n_overfull; END IF;

  -- Nothing on this election may be left stale (provisional_until in the past, unverified).
  SELECT count(*) INTO n_stale
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
     AND rc.provisional_until IS NOT NULL
     AND rc.provisional_until <= CURRENT_DATE
     AND (rc.last_verified_at IS NULL OR rc.last_verified_at < rc.provisional_until);
  IF n_stale > 0 THEN RAISE EXCEPTION '% rows left stale on this election', n_stale; END IF;

  -- result without a citation is what the CHECK forbids; prove it did not happen anyway.
  SELECT count(*) INTO n_nosrc
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
     AND rc.result IS NOT NULL
     AND (rc.result_source IS NULL OR rc.result_source NOT LIKE '%2026-08-04%');
  IF n_nosrc > 0 THEN RAISE EXCEPTION '% result rows do not cite the 2026-08-04 canvass', n_nosrc; END IF;

  RAISE NOTICE 'WA 2026 certification pass OK: % advanced, % not_nominated, % withdrew, % held, % live of 394',
    n_adv, n_not, n_wd, n_null, n_live;
END $$;

COMMIT;
