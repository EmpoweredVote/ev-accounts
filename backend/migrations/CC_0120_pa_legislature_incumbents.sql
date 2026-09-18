-- CC_0120_pa_legislature_incumbents.sql
-- Knight Foundation program, wave PA-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0119, which creates the chambers and the 253 offices.
--
-- Seats all 253 of Pennsylvania's legislative offices:
--    252 people created here, external_id band -2742260 .. -2742001
--    1 person REUSED from a row production already holds
--    0 offices left unseated — neither chamber has a vacancy today
--
-- 🔴 THERE IS NO term_start TO BE HAD FOR 252 SEATS, AND NONE IS INVENTED. Neither chamber
-- publishes service dates: the member pages carry a biography and no dates at all, on a
-- first-term member and on a 26-year veteran alike, and there is no member-history endpoint
-- (four candidate URLs all 404). A constitutional first-Tuesday-in-December date would be
-- positively WRONG for anyone who arrived at a special election — HD-12 is exactly that case —
-- and is not a fact about the others either. Terms are written OPEN-ENDED with start_precision
-- 'unknown', the GA-2 / IN-2 / MN-2 pattern.
-- essentials.seat_officeholder() is NOT used: it refuses a NULL term_start by design.
--
-- 🟢 THE ONE DOCUMENTED ARRIVAL IS WRITTEN AT DAY PRECISION:
--     H-12   2026-09-08 (day) — Brandon Dukes won the 2026-08-18 SPECIAL election for the seat Stephenie Scialabba resigned in March 2026, and was sworn in on 2026-09-08. The date is the SWEARING-IN, not the election and not "first elected".
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 PARTY IS NOT WRITTEN. All three sources carry it; party lives on races.primary_party.
--
-- 🔴🔴 THREE ROSTER NAMES MATCH AN EXISTING ROW, AND THEY SPLIT TWO WAYS. Each was READ before it
-- was classified.
--
--   SAME PERSON, ROW REUSED (no insert):
--     H-200  Chris Rabb, existing PA-3 congressional candidate row (013bf70b-627c-4699-b11d-67924e6916a2)
--
--   DIFFERENT PEOPLE, INSERTED WITH THE GUARD DELIBERATELY LIFTED:
--     H-74   The existing Dan Williams (external_id -1211107) is a CANDIDATE FOR U.S. REPRESENTATIVE IN FLORIDA''S 11TH DISTRICT, election 2026-11-03. The roster Dan K. Williams is the representative for Pennsylvania House 74. Different state, different office, different person.
--     H-202  The existing Jared Solomon (external_id -2420054) holds DELEGATE, MARYLAND state legislative district 18. The roster Jared G. Solomon is the representative for Pennsylvania House 202, Philadelphia. Two state legislators of the same name in two states.
--
-- ⚠ THE GUARD IS LIFTED FOR 2 ROWS, NOT FOR THE MIGRATION. essentials.politicians carries a
-- BEFORE INSERT trigger that refuses a name an active row already holds. The 250 rows with no
-- namesake are inserted with it ARMED, so a namesake nobody anticipated still stops this
-- migration. Only then is essentials.allow_duplicate_name set to 'on', for the rows named above.
--
-- 🔴🔴 THE (first_name, last_name) GUARD IS NOT ENOUGH ON ITS OWN, AND THAT IS MEASURED. Matching
-- the roster on the exact pair found TWO existing rows. A second pass matching on SURNAME ALONE,
-- restricted to rows with any Pennsylvania connection, found THREE MORE — and one of them,
-- 'Chris Rabb' against the chamber's 'Christopher M. Rabb', is the same person. A diminutive
-- defeats the pair guard exactly the way MN-2's Steve/Steven did. A punctuation-blind pass over
-- the same population found nothing further.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── 250 people with no active namesake — guard ARMED ──────────────────────────────

CREATE TEMP TABLE pa_new_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO pa_new_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2742001, 'Patrick J. Harkins', 'Patrick', 'Harkins', '{}'::text[]),
  (-2742002, 'Robert E. Merski', 'Robert', 'Merski', '{}'::text[]),
  (-2742003, 'Ryan A. Bizzarro', 'Ryan', 'Bizzarro', '{}'::text[]),
  (-2742004, 'Jacob D. Banta', 'Jacob', 'Banta', '{}'::text[]),
  (-2742005, 'Eric J. Weaknecht', 'Eric', 'Weaknecht', '{}'::text[]),
  (-2742006, 'Brad Roae', 'Brad', 'Roae', '{}'::text[]),
  (-2742007, 'Parke Wentling', 'Parke', 'Wentling', '{}'::text[]),
  (-2742008, 'Aaron Bernstine', 'Aaron', 'Bernstine', '{}'::text[]),
  (-2742009, 'Marla Brown', 'Marla', 'Brown', '{}'::text[]),
  (-2742010, 'Amen Brown', 'Amen', 'Brown', '{}'::text[]),
  (-2742011, 'Marci Mustello', 'Marci', 'Mustello', '{}'::text[]),
  (-2742012, 'Brandon Dukes', 'Brandon', 'Dukes', '{}'::text[]),
  (-2742013, 'John A. Lawrence', 'John', 'Lawrence', '{}'::text[]),
  (-2742014, 'Roman Kozak', 'Roman', 'Kozak', '{}'::text[]),
  (-2742015, 'Joshua D. Kail', 'Joshua', 'Kail', '{}'::text[]),
  (-2742016, 'Robert F. Matzie', 'Robert', 'Matzie', '{}'::text[]),
  (-2742017, 'Timothy R. Bonner', 'Timothy', 'Bonner', '{}'::text[]),
  (-2742018, 'Kathleen C. Tomlinson', 'Kathleen', 'Tomlinson', '{}'::text[]),
  (-2742019, 'Aerion Abney', 'Aerion', 'Abney', '{}'::text[]),
  (-2742020, 'Emily Kinkead', 'Emily', 'Kinkead', '{}'::text[]),
  (-2742021, 'Lindsay Powell', 'Lindsay', 'Powell', '{}'::text[]),
  (-2742022, 'Ana Tiburcio', 'Ana', 'Tiburcio', '{}'::text[]),
  (-2742023, 'Dan Frankel', 'Dan', 'Frankel', '{}'::text[]),
  (-2742024, 'La''Tasha D. Mayes', 'La''Tasha', 'Mayes', '{}'::text[]),
  (-2742025, 'Brandon J. Markosek', 'Brandon', 'Markosek', '{}'::text[]),
  (-2742026, 'Paul Friel', 'Paul', 'Friel', '{}'::text[]),
  (-2742027, 'Daniel J. Deasy', 'Daniel', 'Deasy', '{}'::text[]),
  (-2742028, 'Jeremy Shaffer', 'Jeremy', 'Shaffer', '{}'::text[]),
  (-2742029, 'Tim Brennan', 'Tim', 'Brennan', '{}'::text[]),
  (-2742030, 'Arvind Venkat', 'Arvind', 'Venkat', '{}'::text[]),
  (-2742031, 'Perry S. Warren', 'Perry', 'Warren', '{}'::text[]),
  (-2742032, 'Joe McAndrew', 'Joe', 'McAndrew', '{}'::text[]),
  (-2742033, 'Mandy Steele', 'Mandy', 'Steele', '{}'::text[]),
  (-2742034, 'Abigail Salisbury', 'Abigail', 'Salisbury', '{}'::text[]),
  (-2742035, 'Dan Goughnour', 'Dan', 'Goughnour', '{}'::text[]),
  (-2742036, 'Jessica Benham', 'Jessica', 'Benham', '{}'::text[]),
  (-2742037, 'Mindy Fee', 'Mindy', 'Fee', '{}'::text[]),
  (-2742038, 'John C. Inglis III', 'John', 'Inglis', '{}'::text[]),
  (-2742039, 'Andrew Kuzma', 'Andrew', 'Kuzma', '{}'::text[]),
  (-2742040, 'Natalie Mihalek', 'Natalie', 'Mihalek', '{}'::text[]),
  (-2742041, 'Brett R. Miller', 'Brett', 'Miller', '{}'::text[]),
  (-2742042, 'Jen Mazzocco', 'Jen', 'Mazzocco', '{}'::text[]),
  (-2742043, 'Keith J. Greiner', 'Keith', 'Greiner', '{}'::text[]),
  (-2742044, 'Valerie S. Gaydos', 'Valerie', 'Gaydos', '{}'::text[]),
  (-2742045, 'Anita Astorino Kulik', 'Anita', 'Kulik', '{}'::text[]),
  (-2742046, 'Jason Ortitay', 'Jason', 'Ortitay', '{}'::text[]),
  (-2742047, 'Joseph D''Orsie', 'Joseph', 'D''Orsie', '{}'::text[]),
  (-2742048, 'Timothy J. O''Neal', 'Timothy', 'O''Neal', '{}'::text[]),
  (-2742049, 'Ismail Smith-Wade-El', 'Ismail', 'Smith-Wade-El', '{}'::text[]),
  (-2742050, 'Bud Cook', 'Bud', 'Cook', '{}'::text[]),
  (-2742051, 'Charity Grimm Krupa', 'Charity', 'Krupa', '{}'::text[]),
  (-2742052, 'Ryan Warner', 'Ryan', 'Warner', '{}'::text[]),
  (-2742053, 'Steven R. Malagari', 'Steven', 'Malagari', '{}'::text[]),
  (-2742054, 'Greg Scott', 'Greg', 'Scott', '{}'::text[]),
  (-2742055, 'Jill N. Cooper', 'Jill', 'Cooper', '{}'::text[]),
  (-2742056, 'Brian C. Rasel', 'Brian', 'Rasel', '{}'::text[]),
  (-2742057, 'Eric R. Nelson', 'Eric', 'Nelson', '{}'::text[]),
  (-2742058, 'Eric Davanzo', 'Eric', 'Davanzo', '{}'::text[]),
  (-2742059, 'Leslie Rossi', 'Leslie', 'Rossi', '{}'::text[]),
  (-2742060, 'Abby Major', 'Abby', 'Major', '{}'::text[]),
  (-2742061, 'Liz Hanbidge', 'Liz', 'Hanbidge', '{}'::text[]),
  (-2742062, 'James B. Struzzi', 'James', 'Struzzi', '{}'::text[]),
  (-2742063, 'Josh Bashline', 'Josh', 'Bashline', '{}'::text[]),
  (-2742064, 'R. Lee James', 'R.', 'James', '{}'::text[]),
  (-2742065, 'Kathy L. Rapp', 'Kathy', 'Rapp', '{}'::text[]),
  (-2742066, 'Brian Smith', 'Brian', 'Smith', '{}'::text[]),
  (-2742067, 'Martin T. Causer', 'Martin', 'Causer', '{}'::text[]),
  (-2742068, 'Clint Owlett', 'Clint', 'Owlett', '{}'::text[]),
  (-2742069, 'Carl Walker Metzgar', 'Carl', 'Metzgar', '{}'::text[]),
  (-2742070, 'Matthew D. Bradford', 'Matthew', 'Bradford', '{}'::text[]),
  (-2742071, 'Jim Rigby', 'Jim', 'Rigby', '{}'::text[]),
  (-2742072, 'Frank Burns', 'Frank', 'Burns', '{}'::text[]),
  (-2742073, 'Dallas Kephart', 'Dallas', 'Kephart', '{}'::text[]),
  (-2742075, 'Mike Armanini', 'Mike', 'Armanini', '{}'::text[]),
  (-2742076, 'Stephanie Borowicz', 'Stephanie', 'Borowicz', '{}'::text[]),
  (-2742077, 'Scott Conklin', 'Scott', 'Conklin', '{}'::text[]),
  (-2742078, 'Jesse Topper', 'Jesse', 'Topper', '{}'::text[]),
  (-2742079, 'Andrea C. Verobish', 'Andrea', 'Verobish', '{}'::text[]),
  (-2742080, 'Scott Barger', 'Scott', 'Barger', '{}'::text[]),
  (-2742081, 'Rich Irvin', 'Rich', 'Irvin', '{}'::text[]),
  (-2742082, 'Paul Takac', 'Paul', 'Takac', '{}'::text[]),
  (-2742083, 'Jamie L. Flick', 'Jamie', 'Flick', '{}'::text[]),
  (-2742084, 'Joe Hamm', 'Joe', 'Hamm', '{}'::text[]),
  (-2742085, 'David H. Rowe', 'David', 'Rowe', '{}'::text[]),
  (-2742086, 'Perry A. Stambaugh', 'Perry', 'Stambaugh', '{}'::text[]),
  (-2742087, 'Thomas H. Kutz', 'Thomas', 'Kutz', '{}'::text[]),
  (-2742088, 'Sheryl M. Delozier', 'Sheryl', 'Delozier', '{}'::text[]),
  (-2742089, 'Rob W. Kauffman', 'Rob', 'Kauffman', '{}'::text[]),
  (-2742090, 'Chad G. Reichard', 'Chad', 'Reichard', '{}'::text[]),
  (-2742091, 'Dan Moul', 'Dan', 'Moul', '{}'::text[]),
  (-2742092, 'Marc S. Anderson', 'Marc', 'Anderson', '{}'::text[]),
  (-2742093, 'Mike Jones', 'Mike', 'Jones', '{}'::text[]),
  (-2742094, 'Wendy Fink', 'Wendy', 'Fink', '{}'::text[]),
  (-2742095, 'Carol Hill-Evans', 'Carol', 'Hill-Evans', '{}'::text[]),
  (-2742096, 'Nikki Rivera', 'Nikki', 'Rivera', '{}'::text[]),
  (-2742097, 'Steven C. Mentzer', 'Steven', 'Mentzer', '{}'::text[]),
  (-2742098, 'Tom Jones', 'Tom', 'Jones', '{}'::text[]),
  (-2742099, 'David H. Zimmerman', 'David', 'Zimmerman', '{}'::text[]),
  (-2742100, 'Bryan Cutler', 'Bryan', 'Cutler', '{}'::text[]),
  (-2742101, 'John A. Schlegel', 'John', 'Schlegel', '{}'::text[]),
  (-2742102, 'Russ Diamond', 'Russ', 'Diamond', '{}'::text[]),
  (-2742103, 'Nathan Davidson', 'Nathan', 'Davidson', '{}'::text[]),
  (-2742104, 'Dave Madsen', 'Dave', 'Madsen', '{}'::text[]),
  (-2742105, 'Justin C. Fleming', 'Justin', 'Fleming', '{}'::text[]),
  (-2742106, 'Thomas L. Mehaffie', 'Thomas', 'Mehaffie', '{}'::text[]),
  (-2742107, 'Joanne Stehr', 'Joanne', 'Stehr', '{}'::text[]),
  (-2742108, 'Michael Stender', 'Michael', 'Stender', '{}'::text[]),
  (-2742109, 'Robert Leadbeter', 'Robert', 'Leadbeter', '{}'::text[]),
  (-2742110, 'Tina Pickett', 'Tina', 'Pickett', '{}'::text[]),
  (-2742111, 'Jonathan Fritz', 'Jonathan', 'Fritz', '{}'::text[]),
  (-2742112, 'Kyle J. Mullins', 'Kyle', 'Mullins', '{}'::text[]),
  (-2742113, 'Kyle Donahue', 'Kyle', 'Donahue', '{}'::text[]),
  (-2742114, 'Bridget M. Kosierowski', 'Bridget', 'Kosierowski', '{}'::text[]),
  (-2742115, 'Maureen E. Madden', 'Maureen', 'Madden', '{}'::text[]),
  (-2742116, 'Dane Watro', 'Dane', 'Watro', '{}'::text[]),
  (-2742117, 'Jamie Walsh', 'Jamie', 'Walsh', '{}'::text[]),
  (-2742118, 'Jim Haddock', 'Jim', 'Haddock', '{}'::text[]),
  (-2742119, 'Alec J. Ryncavage', 'Alec', 'Ryncavage', '{}'::text[]),
  (-2742120, 'Brenda M. Pugh', 'Brenda', 'Pugh', '{}'::text[]),
  (-2742121, 'Eddie Day Pashinski', 'Eddie', 'Pashinski', '{}'::text[]),
  (-2742122, 'Doyle Heffley', 'Doyle', 'Heffley', '{}'::text[]),
  (-2742123, 'Tim Twardzik', 'Tim', 'Twardzik', '{}'::text[]),
  (-2742124, 'Jamie Barton', 'Jamie', 'Barton', '{}'::text[]),
  (-2742125, 'Joe Kerwin', 'Joe', 'Kerwin', '{}'::text[]),
  (-2742126, 'Jacklyn Rusnock', 'Jacklyn', 'Rusnock', '{}'::text[]),
  (-2742127, 'Manuel Guzman', 'Manuel', 'Guzman', '{}'::text[]),
  (-2742128, 'Mark M. Gillen', 'Mark', 'Gillen', '{}'::text[]),
  (-2742129, 'Johanny Cepeda-Freytiz', 'Johanny', 'Cepeda-Freytiz', '{}'::text[]),
  (-2742130, 'David M. Maloney', 'David', 'Maloney', '{}'::text[]),
  (-2742131, 'Milou Mackenzie', 'Milou', 'Mackenzie', '{}'::text[]),
  (-2742132, 'Michael H. Schlossberg', 'Michael', 'Schlossberg', '{}'::text[]),
  (-2742133, 'Jeanne McNeill', 'Jeanne', 'McNeill', '{}'::text[]),
  (-2742134, 'Peter Schweyer', 'Peter', 'Schweyer', '{}'::text[]),
  (-2742135, 'Steve Samuelson', 'Steve', 'Samuelson', '{}'::text[]),
  (-2742136, 'Robert Freeman', 'Robert', 'Freeman', '{}'::text[]),
  (-2742137, 'Joe Emrick', 'Joe', 'Emrick', '{}'::text[]),
  (-2742138, 'Ann Flood', 'Ann', 'Flood', '{}'::text[]),
  (-2742139, 'Jeff Olsommer', 'Jeff', 'Olsommer', '{}'::text[]),
  (-2742140, 'Jim Prokopiak', 'Jim', 'Prokopiak', '{}'::text[]),
  (-2742141, 'Tina M. Davis', 'Tina', 'Davis', '{}'::text[]),
  (-2742142, 'Joe Hogan', 'Joe', 'Hogan', '{}'::text[]),
  (-2742143, 'Shelby Labs', 'Shelby', 'Labs', '{}'::text[]),
  (-2742144, 'Brian Munroe', 'Brian', 'Munroe', '{}'::text[]),
  (-2742145, 'Craig T. Staats', 'Craig', 'Staats', '{}'::text[]),
  (-2742146, 'Joe Ciresi', 'Joe', 'Ciresi', '{}'::text[]),
  (-2742147, 'Donna Scheuren', 'Donna', 'Scheuren', '{}'::text[]),
  (-2742148, 'Mary Jo Daley', 'Mary', 'Daley', '{}'::text[]),
  (-2742149, 'Tim Briggs', 'Tim', 'Briggs', '{}'::text[]),
  (-2742150, 'Joe Webster', 'Joe', 'Webster', '{}'::text[]),
  (-2742151, 'Melissa Cerrato', 'Melissa', 'Cerrato', '{}'::text[]),
  (-2742152, 'Nancy Guenst', 'Nancy', 'Guenst', '{}'::text[]),
  (-2742153, 'Benjamin V. Sanchez', 'Benjamin', 'Sanchez', '{}'::text[]),
  (-2742154, 'Napoleon J. Nelson', 'Napoleon', 'Nelson', '{}'::text[]),
  (-2742155, 'Danielle Friel Otten', 'Danielle', 'Otten', '{}'::text[]),
  (-2742156, 'Chris Pielli', 'Chris', 'Pielli', '{}'::text[]),
  (-2742157, 'Melissa L. Shusterman', 'Melissa', 'Shusterman', '{}'::text[]),
  (-2742158, 'Christina D. Sappey', 'Christina', 'Sappey', '{}'::text[]),
  (-2742159, 'Carol Kazeem', 'Carol', 'Kazeem', '{}'::text[]),
  (-2742160, 'Craig Williams', 'Craig', 'Williams', '{}'::text[]),
  (-2742161, 'Leanne Krueger', 'Leanne', 'Krueger', '{}'::text[]),
  (-2742162, 'David M. Delloso', 'David', 'Delloso', '{}'::text[]),
  (-2742163, 'Heather Boyd', 'Heather', 'Boyd', '{}'::text[]),
  (-2742164, 'Gina H. Curry', 'Gina', 'Curry', '{}'::text[]),
  (-2742165, 'Jennifer O''Mara', 'Jennifer', 'O''Mara', '{}'::text[]),
  (-2742166, 'Greg Vitali', 'Greg', 'Vitali', '{}'::text[]),
  (-2742167, 'Kristine C. Howard', 'Kristine', 'Howard', '{}'::text[]),
  (-2742168, 'Lisa A. Borowski', 'Lisa', 'Borowski', '{}'::text[]),
  (-2742169, 'Kate A. Klunk', 'Kate', 'Klunk', '{}'::text[]),
  (-2742170, 'Martina A. White', 'Martina', 'White', '{}'::text[]),
  (-2742171, 'Kerry A. Benninghoff', 'Kerry', 'Benninghoff', '{}'::text[]),
  (-2742172, 'Sean Dougherty', 'Sean', 'Dougherty', '{}'::text[]),
  (-2742173, 'Pat Gallagher', 'Pat', 'Gallagher', '{}'::text[]),
  (-2742174, 'Ed Neilson', 'Ed', 'Neilson', '{}'::text[]),
  (-2742175, 'MaryLouise Isaacson', 'MaryLouise', 'Isaacson', '{}'::text[]),
  (-2742176, 'Jack Rader', 'Jack', 'Rader', '{}'::text[]),
  (-2742177, 'Joseph C. Hohenstein', 'Joseph', 'Hohenstein', '{}'::text[]),
  (-2742178, 'Kristin Marcell', 'Kristin', 'Marcell', '{}'::text[]),
  (-2742179, 'Jason Dawkins', 'Jason', 'Dawkins', '{}'::text[]),
  (-2742180, 'Jose Giral', 'Jose', 'Giral', '{}'::text[]),
  (-2742181, 'Malcolm Kenyatta', 'Malcolm', 'Kenyatta', '{}'::text[]),
  (-2742182, 'Ben Waxman', 'Ben', 'Waxman', '{}'::text[]),
  (-2742183, 'Zachary Mako', 'Zachary', 'Mako', '{}'::text[]),
  (-2742184, 'Elizabeth Fiedler', 'Elizabeth', 'Fiedler', '{}'::text[]),
  (-2742185, 'Regina G. Young', 'Regina', 'Young', '{}'::text[]),
  (-2742186, 'Jordan A. Harris', 'Jordan', 'Harris', '{}'::text[]),
  (-2742187, 'Gary W. Day', 'Gary', 'Day', '{}'::text[]),
  (-2742188, 'Rick Krajewski', 'Rick', 'Krajewski', '{}'::text[]),
  (-2742189, 'Tarah Probst', 'Tarah', 'Probst', '{}'::text[]),
  (-2742190, 'G. Roni Green', 'G.', 'Green', '{}'::text[]),
  (-2742191, 'Joanna E. McClinton', 'Joanna', 'McClinton', '{}'::text[]),
  (-2742192, 'Morgan Cephas', 'Morgan', 'Cephas', '{}'::text[]),
  (-2742193, 'Catherine I Wallen', 'Catherine', 'Wallen', '{}'::text[]),
  (-2742194, 'Tarik Khan', 'Tarik', 'Khan', '{}'::text[]),
  (-2742195, 'Keith S. Harris', 'Keith', 'Harris', '{}'::text[]),
  (-2742196, 'George H Margetas', 'George', 'Margetas', '{}'::text[]),
  (-2742197, 'Danilo Burgos', 'Danilo', 'Burgos', '{}'::text[]),
  (-2742198, 'Darisha K. Parker', 'Darisha', 'Parker', '{}'::text[]),
  (-2742199, 'Barbara Gleim', 'Barbara', 'Gleim', '{}'::text[]),
  (-2742200, 'Andre D. Carroll', 'Andre', 'Carroll', '{}'::text[]),
  (-2742202, 'Anthony A. Bellmon', 'Anthony', 'Bellmon', '{}'::text[]),
  (-2742203, 'Nikil Saval', 'Nikil', 'Saval', '{}'::text[]),
  (-2742204, 'Christine M. Tartaglione', 'Christine', 'Tartaglione', '{}'::text[]),
  (-2742205, 'Sharif Street', 'Sharif', 'Street', '{}'::text[]),
  (-2742206, 'Art Haywood', 'Art', 'Haywood', '{}'::text[]),
  (-2742207, 'Joe Picozzi', 'Joe', 'Picozzi', '{}'::text[]),
  (-2742208, 'Frank A. Farry', 'Frank', 'Farry', '{}'::text[]),
  (-2742209, 'Vincent J. Hughes', 'Vincent', 'Hughes', '{}'::text[]),
  (-2742210, 'Anthony H. Williams', 'Anthony', 'Williams', '{}'::text[]),
  (-2742211, 'John I. Kane', 'John', 'Kane', '{}'::text[]),
  (-2742212, 'Steven J. Santarsiero', 'Steven', 'Santarsiero', '{}'::text[]),
  (-2742213, 'Judith L. Schwank', 'Judith', 'Schwank', '{}'::text[]),
  (-2742214, 'Maria Collett', 'Maria', 'Collett', '{}'::text[]),
  (-2742215, 'Scott Martin', 'Scott', 'Martin', '{}'::text[]),
  (-2742216, 'Nick Miller', 'Nick', 'Miller', '{}'::text[]),
  (-2742217, 'Patty Kim', 'Patty', 'Kim', '{}'::text[]),
  (-2742218, 'Jarrett Coleman', 'Jarrett', 'Coleman', '{}'::text[]),
  (-2742219, 'Amanda M. Cappelletti', 'Amanda', 'Cappelletti', '{}'::text[]),
  (-2742220, 'Lisa M. Boscola', 'Lisa', 'Boscola', '{}'::text[]),
  (-2742221, 'Carolyn T. Comitta', 'Carolyn', 'Comitta', '{}'::text[]),
  (-2742222, 'Lisa Baker', 'Lisa', 'Baker', '{}'::text[]),
  (-2742223, 'Scott E. Hutchinson', 'Scott', 'Hutchinson', '{}'::text[]),
  (-2742224, 'Marty Flynn', 'Marty', 'Flynn', '{}'::text[]),
  (-2742225, 'Gene Yaw', 'Gene', 'Yaw', '{}'::text[]),
  (-2742226, 'Tracy Pennycuick', 'Tracy', 'Pennycuick', '{}'::text[]),
  (-2742227, 'Cris Dush', 'Cris', 'Dush', '{}'::text[]),
  (-2742228, 'Timothy P. Kearney', 'Timothy', 'Kearney', '{}'::text[]),
  (-2742229, 'Lynda Schlegel Culver', 'Lynda', 'Culver', '{}'::text[]),
  (-2742230, 'Kristin Phillips-Hill', 'Kristin', 'Phillips-Hill', '{}'::text[]),
  (-2742231, 'David G. Argall', 'David', 'Argall', '{}'::text[]),
  (-2742232, 'Judy Ward', 'Judy', 'Ward', '{}'::text[]),
  (-2742233, 'Dawn W. Keefer', 'Dawn', 'Keefer', '{}'::text[]),
  (-2742234, 'Patrick J. Stefano', 'Patrick', 'Stefano', '{}'::text[]),
  (-2742235, 'Doug Mastriano', 'Doug', 'Mastriano', '{}'::text[]),
  (-2742236, 'Greg Rothman', 'Greg', 'Rothman', '{}'::text[]),
  (-2742237, 'Wayne Langerholc', 'Wayne', 'Langerholc', '{}'::text[]),
  (-2742238, 'James Andrew Malone', 'James', 'Malone', '{}'::text[]),
  (-2742239, 'Devlin J. Robinson', 'Devlin', 'Robinson', '{}'::text[]),
  (-2742240, 'Lindsey M. Williams', 'Lindsey', 'Williams', '{}'::text[]),
  (-2742241, 'Kim L. Ward', 'Kim', 'Ward', '{}'::text[]),
  (-2742242, 'Rosemary M. Brown', 'Rosemary', 'Brown', '{}'::text[]),
  (-2742243, 'Joe Pittman', 'Joe', 'Pittman', '{}'::text[]),
  (-2742244, 'Wayne D. Fontana', 'Wayne', 'Fontana', '{}'::text[]),
  (-2742245, 'Jay Costa', 'Jay', 'Costa', '{}'::text[]),
  (-2742246, 'Katie J. Muth', 'Katie', 'Muth', '{}'::text[]),
  (-2742247, 'Nick Pisciottano', 'Nick', 'Pisciottano', '{}'::text[]),
  (-2742248, 'Camera Bartolotta', 'Camera', 'Bartolotta', '{}'::text[]),
  (-2742249, 'Elder A. Vogel', 'Elder', 'Vogel', '{}'::text[]),
  (-2742250, 'Chris Gebhard', 'Chris', 'Gebhard', '{}'::text[]),
  (-2742251, 'Daniel Laughlin', 'Daniel', 'Laughlin', '{}'::text[]),
  (-2742252, 'Michele Brooks', 'Michele', 'Brooks', '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Pennsylvania General Assembly member lists, https://www.legis.state.pa.us/cfdocs/legis/home/member_information/mbrList.cfm (body=H and body=S); reconciled against Open States, https://data.openstates.org/people/current/pa.csv, and against PennDOT''s own district layers via PASDA; change-checked against all 253 individual member pages, read 2026-09-18 (PA-2) (CC_0120, PA-2)', n.alternate_names
FROM pa_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2 people who share a name with a DIFFERENT person — guard lifted ──────────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE pa_namesake_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO pa_namesake_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2742074, 'Dan K. Williams', 'Dan', 'Williams', '{}'::text[]),
  (-2742201, 'Jared G. Solomon', 'Jared', 'Solomon', '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Pennsylvania General Assembly member lists, https://www.legis.state.pa.us/cfdocs/legis/home/member_information/mbrList.cfm (body=H and body=S); reconciled against Open States, https://data.openstates.org/people/current/pa.csv, and against PennDOT''s own district layers via PASDA; change-checked against all 253 individual member pages, read 2026-09-18 (PA-2) (CC_0120, PA-2)', n.alternate_names
FROM pa_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 253 terms, one per office ────────────────────────────────────────────────
-- Each row carries EITHER an external_id (a person created above) or a politician_id (a row
-- production already held). The join below accepts one or the other and nothing else.

CREATE TEMP TABLE pa_terms(geo_id text, district_type text, external_id bigint, politician_id uuid,
                           term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO pa_terms(geo_id, district_type, external_id, politician_id, term_start, start_precision, how_started) VALUES
  ('42001', 'STATE_LOWER', -2742001::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42002', 'STATE_LOWER', -2742002::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42003', 'STATE_LOWER', -2742003::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42004', 'STATE_LOWER', -2742004::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42005', 'STATE_LOWER', -2742005::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42006', 'STATE_LOWER', -2742006::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42007', 'STATE_LOWER', -2742007::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42008', 'STATE_LOWER', -2742008::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42009', 'STATE_LOWER', -2742009::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42010', 'STATE_LOWER', -2742010::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42011', 'STATE_LOWER', -2742011::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42012', 'STATE_LOWER', -2742012::bigint, NULL::uuid, '2026-09-08'::date, 'day', 'elected'),
  ('42013', 'STATE_LOWER', -2742013::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42014', 'STATE_LOWER', -2742014::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42015', 'STATE_LOWER', -2742015::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42016', 'STATE_LOWER', -2742016::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42017', 'STATE_LOWER', -2742017::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42018', 'STATE_LOWER', -2742018::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42019', 'STATE_LOWER', -2742019::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42020', 'STATE_LOWER', -2742020::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42021', 'STATE_LOWER', -2742021::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42022', 'STATE_LOWER', -2742022::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42023', 'STATE_LOWER', -2742023::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42024', 'STATE_LOWER', -2742024::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42025', 'STATE_LOWER', -2742025::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42026', 'STATE_LOWER', -2742026::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42027', 'STATE_LOWER', -2742027::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42028', 'STATE_LOWER', -2742028::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42029', 'STATE_LOWER', -2742029::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42030', 'STATE_LOWER', -2742030::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42031', 'STATE_LOWER', -2742031::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42032', 'STATE_LOWER', -2742032::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42033', 'STATE_LOWER', -2742033::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42034', 'STATE_LOWER', -2742034::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42035', 'STATE_LOWER', -2742035::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42036', 'STATE_LOWER', -2742036::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42037', 'STATE_LOWER', -2742037::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42038', 'STATE_LOWER', -2742038::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42039', 'STATE_LOWER', -2742039::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42040', 'STATE_LOWER', -2742040::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42041', 'STATE_LOWER', -2742041::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42042', 'STATE_LOWER', -2742042::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42043', 'STATE_LOWER', -2742043::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42044', 'STATE_LOWER', -2742044::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42045', 'STATE_LOWER', -2742045::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42046', 'STATE_LOWER', -2742046::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42047', 'STATE_LOWER', -2742047::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42048', 'STATE_LOWER', -2742048::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42049', 'STATE_LOWER', -2742049::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42050', 'STATE_LOWER', -2742050::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42051', 'STATE_LOWER', -2742051::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42052', 'STATE_LOWER', -2742052::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42053', 'STATE_LOWER', -2742053::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42054', 'STATE_LOWER', -2742054::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42055', 'STATE_LOWER', -2742055::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42056', 'STATE_LOWER', -2742056::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42057', 'STATE_LOWER', -2742057::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42058', 'STATE_LOWER', -2742058::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42059', 'STATE_LOWER', -2742059::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42060', 'STATE_LOWER', -2742060::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42061', 'STATE_LOWER', -2742061::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42062', 'STATE_LOWER', -2742062::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42063', 'STATE_LOWER', -2742063::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42064', 'STATE_LOWER', -2742064::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42065', 'STATE_LOWER', -2742065::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42066', 'STATE_LOWER', -2742066::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42067', 'STATE_LOWER', -2742067::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42068', 'STATE_LOWER', -2742068::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42069', 'STATE_LOWER', -2742069::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42070', 'STATE_LOWER', -2742070::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42071', 'STATE_LOWER', -2742071::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42072', 'STATE_LOWER', -2742072::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42073', 'STATE_LOWER', -2742073::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42074', 'STATE_LOWER', -2742074::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42075', 'STATE_LOWER', -2742075::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42076', 'STATE_LOWER', -2742076::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42077', 'STATE_LOWER', -2742077::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42078', 'STATE_LOWER', -2742078::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42079', 'STATE_LOWER', -2742079::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42080', 'STATE_LOWER', -2742080::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42081', 'STATE_LOWER', -2742081::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42082', 'STATE_LOWER', -2742082::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42083', 'STATE_LOWER', -2742083::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42084', 'STATE_LOWER', -2742084::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42085', 'STATE_LOWER', -2742085::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42086', 'STATE_LOWER', -2742086::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42087', 'STATE_LOWER', -2742087::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42088', 'STATE_LOWER', -2742088::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42089', 'STATE_LOWER', -2742089::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42090', 'STATE_LOWER', -2742090::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42091', 'STATE_LOWER', -2742091::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42092', 'STATE_LOWER', -2742092::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42093', 'STATE_LOWER', -2742093::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42094', 'STATE_LOWER', -2742094::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42095', 'STATE_LOWER', -2742095::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42096', 'STATE_LOWER', -2742096::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42097', 'STATE_LOWER', -2742097::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42098', 'STATE_LOWER', -2742098::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42099', 'STATE_LOWER', -2742099::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42100', 'STATE_LOWER', -2742100::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42101', 'STATE_LOWER', -2742101::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42102', 'STATE_LOWER', -2742102::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42103', 'STATE_LOWER', -2742103::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42104', 'STATE_LOWER', -2742104::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42105', 'STATE_LOWER', -2742105::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42106', 'STATE_LOWER', -2742106::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42107', 'STATE_LOWER', -2742107::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42108', 'STATE_LOWER', -2742108::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42109', 'STATE_LOWER', -2742109::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42110', 'STATE_LOWER', -2742110::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42111', 'STATE_LOWER', -2742111::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42112', 'STATE_LOWER', -2742112::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42113', 'STATE_LOWER', -2742113::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42114', 'STATE_LOWER', -2742114::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42115', 'STATE_LOWER', -2742115::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42116', 'STATE_LOWER', -2742116::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42117', 'STATE_LOWER', -2742117::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42118', 'STATE_LOWER', -2742118::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42119', 'STATE_LOWER', -2742119::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42120', 'STATE_LOWER', -2742120::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42121', 'STATE_LOWER', -2742121::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42122', 'STATE_LOWER', -2742122::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42123', 'STATE_LOWER', -2742123::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42124', 'STATE_LOWER', -2742124::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42125', 'STATE_LOWER', -2742125::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42126', 'STATE_LOWER', -2742126::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42127', 'STATE_LOWER', -2742127::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42128', 'STATE_LOWER', -2742128::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42129', 'STATE_LOWER', -2742129::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42130', 'STATE_LOWER', -2742130::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42131', 'STATE_LOWER', -2742131::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42132', 'STATE_LOWER', -2742132::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42133', 'STATE_LOWER', -2742133::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42134', 'STATE_LOWER', -2742134::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42135', 'STATE_LOWER', -2742135::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42136', 'STATE_LOWER', -2742136::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42137', 'STATE_LOWER', -2742137::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42138', 'STATE_LOWER', -2742138::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42139', 'STATE_LOWER', -2742139::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42140', 'STATE_LOWER', -2742140::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42141', 'STATE_LOWER', -2742141::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42142', 'STATE_LOWER', -2742142::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42143', 'STATE_LOWER', -2742143::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42144', 'STATE_LOWER', -2742144::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42145', 'STATE_LOWER', -2742145::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42146', 'STATE_LOWER', -2742146::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42147', 'STATE_LOWER', -2742147::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42148', 'STATE_LOWER', -2742148::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42149', 'STATE_LOWER', -2742149::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42150', 'STATE_LOWER', -2742150::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42151', 'STATE_LOWER', -2742151::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42152', 'STATE_LOWER', -2742152::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42153', 'STATE_LOWER', -2742153::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42154', 'STATE_LOWER', -2742154::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42155', 'STATE_LOWER', -2742155::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42156', 'STATE_LOWER', -2742156::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42157', 'STATE_LOWER', -2742157::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42158', 'STATE_LOWER', -2742158::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42159', 'STATE_LOWER', -2742159::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42160', 'STATE_LOWER', -2742160::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42161', 'STATE_LOWER', -2742161::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42162', 'STATE_LOWER', -2742162::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42163', 'STATE_LOWER', -2742163::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42164', 'STATE_LOWER', -2742164::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42165', 'STATE_LOWER', -2742165::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42166', 'STATE_LOWER', -2742166::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42167', 'STATE_LOWER', -2742167::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42168', 'STATE_LOWER', -2742168::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42169', 'STATE_LOWER', -2742169::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42170', 'STATE_LOWER', -2742170::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42171', 'STATE_LOWER', -2742171::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42172', 'STATE_LOWER', -2742172::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42173', 'STATE_LOWER', -2742173::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42174', 'STATE_LOWER', -2742174::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42175', 'STATE_LOWER', -2742175::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42176', 'STATE_LOWER', -2742176::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42177', 'STATE_LOWER', -2742177::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42178', 'STATE_LOWER', -2742178::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42179', 'STATE_LOWER', -2742179::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42180', 'STATE_LOWER', -2742180::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42181', 'STATE_LOWER', -2742181::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42182', 'STATE_LOWER', -2742182::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42183', 'STATE_LOWER', -2742183::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42184', 'STATE_LOWER', -2742184::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42185', 'STATE_LOWER', -2742185::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42186', 'STATE_LOWER', -2742186::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42187', 'STATE_LOWER', -2742187::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42188', 'STATE_LOWER', -2742188::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42189', 'STATE_LOWER', -2742189::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42190', 'STATE_LOWER', -2742190::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42191', 'STATE_LOWER', -2742191::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42192', 'STATE_LOWER', -2742192::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42193', 'STATE_LOWER', -2742193::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42194', 'STATE_LOWER', -2742194::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42195', 'STATE_LOWER', -2742195::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42196', 'STATE_LOWER', -2742196::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42197', 'STATE_LOWER', -2742197::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42198', 'STATE_LOWER', -2742198::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42199', 'STATE_LOWER', -2742199::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42200', 'STATE_LOWER', NULL::bigint, '013bf70b-627c-4699-b11d-67924e6916a2'::uuid, NULL::date, 'unknown', 'unknown'),
  ('42201', 'STATE_LOWER', -2742200::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42202', 'STATE_LOWER', -2742201::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42203', 'STATE_LOWER', -2742202::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42001', 'STATE_UPPER', -2742203::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42002', 'STATE_UPPER', -2742204::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42003', 'STATE_UPPER', -2742205::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42004', 'STATE_UPPER', -2742206::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42005', 'STATE_UPPER', -2742207::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42006', 'STATE_UPPER', -2742208::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42007', 'STATE_UPPER', -2742209::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42008', 'STATE_UPPER', -2742210::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42009', 'STATE_UPPER', -2742211::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42010', 'STATE_UPPER', -2742212::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42011', 'STATE_UPPER', -2742213::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42012', 'STATE_UPPER', -2742214::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42013', 'STATE_UPPER', -2742215::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42014', 'STATE_UPPER', -2742216::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42015', 'STATE_UPPER', -2742217::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42016', 'STATE_UPPER', -2742218::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42017', 'STATE_UPPER', -2742219::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42018', 'STATE_UPPER', -2742220::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42019', 'STATE_UPPER', -2742221::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42020', 'STATE_UPPER', -2742222::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42021', 'STATE_UPPER', -2742223::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42022', 'STATE_UPPER', -2742224::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42023', 'STATE_UPPER', -2742225::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42024', 'STATE_UPPER', -2742226::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42025', 'STATE_UPPER', -2742227::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42026', 'STATE_UPPER', -2742228::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42027', 'STATE_UPPER', -2742229::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42028', 'STATE_UPPER', -2742230::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42029', 'STATE_UPPER', -2742231::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42030', 'STATE_UPPER', -2742232::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42031', 'STATE_UPPER', -2742233::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42032', 'STATE_UPPER', -2742234::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42033', 'STATE_UPPER', -2742235::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42034', 'STATE_UPPER', -2742236::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42035', 'STATE_UPPER', -2742237::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42036', 'STATE_UPPER', -2742238::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42037', 'STATE_UPPER', -2742239::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42038', 'STATE_UPPER', -2742240::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42039', 'STATE_UPPER', -2742241::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42040', 'STATE_UPPER', -2742242::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42041', 'STATE_UPPER', -2742243::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42042', 'STATE_UPPER', -2742244::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42043', 'STATE_UPPER', -2742245::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42044', 'STATE_UPPER', -2742246::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42045', 'STATE_UPPER', -2742247::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42046', 'STATE_UPPER', -2742248::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42047', 'STATE_UPPER', -2742249::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42048', 'STATE_UPPER', -2742250::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42049', 'STATE_UPPER', -2742251::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown'),
  ('42050', 'STATE_UPPER', -2742252::bigint, NULL::uuid, NULL::date, 'unknown', 'unknown');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started, 'Pennsylvania General Assembly member lists, https://www.legis.state.pa.us/cfdocs/legis/home/member_information/mbrList.cfm (body=H and body=S); reconciled against Open States, https://data.openstates.org/people/current/pa.csv, and against PennDOT''s own district layers via PASDA; change-checked against all 253 individual member pages, read 2026-09-18 (PA-2) (CC_0120, PA-2)'
FROM pa_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'pa'
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
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2742260 AND -2742001;
  IF v_people <> 252 THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected 252 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_offices <> 253 THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected 253 Pennsylvania legislative offices, got %', v_offices;
  END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_terms <> 253 THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected 253 terms, got %', v_terms;
  END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*). office_current_holder LEFT JOINs from offices,
  -- so an unseated office is a row with a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> 253 THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected 253 seated offices, got %', v_seated;
  END IF;

  -- Exactly one dated term, and it is HD-12's.
  SELECT count(*) INTO v_dated
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    AND ot.term_start IS NOT NULL;
  IF v_dated <> 1 THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected 1 dated term(s), got %', v_dated;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'pa' AND d.district_type::text = 'STATE_LOWER' AND d.geo_id = '42012'
      AND ot.term_start = DATE '2026-09-08' AND ot.start_precision = 'day'
  ) THEN
    RAISE EXCEPTION 'PA-2 occupancy: HD-12 is not seated from 2026-09-08 at day precision';
  END IF;

  SELECT count(*) INTO v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'PA-2 occupancy: % term(s) carry a term_end — a future end date self-vacates a seat', v_ended;
  END IF;

  -- 🔴 NOBODY SEATED HERE HOLDS TWO PENNSYLVANIA LEGISLATIVE SEATS. The exclusion constraint on
  -- office_terms forbids two people on one office; it CANNOT see one person on two, which is the
  -- direction that fans a politician-rooted join out.
  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY ot.politician_id HAVING count(*) > 1
  ) x;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION 'PA-2 occupancy: % person(s) hold more than one Pennsylvania legislative seat', v_fanout;
  END IF;

  RAISE NOTICE 'PA-2 occupancy OK: 253 offices, 253 terms, 253 seated, 1 dated, 0 ended';
END $$;

COMMIT;
