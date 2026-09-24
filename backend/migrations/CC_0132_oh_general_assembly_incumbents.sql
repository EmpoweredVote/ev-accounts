-- CC_0132_oh_general_assembly_incumbents.sql
-- Knight Foundation program, wave OH-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0131, which creates the chambers and the 132 offices.
--
-- Seats 130 of Ohio's 132 legislative offices:
--    130 people created here (128 under the live name guard + 2 namesakes with it scoped off), external_id band -2760200 .. -2760001 (used: -2760130 .. -2760001)
--    0 people reused
--    2 offices left unseated ON PURPOSE -- HD-66 and SD-13 are vacant, and CC_0131 flags them
--
-- 🔴 EVERY TERM IS OPEN-ENDED AT 'unknown' PRECISION, AND NOTHING IS GUESSED. Neither chamber
-- publishes a service-start date anywhere on a member page: a date probe over a member page found
-- no "assumed office", no "term", and no arrival sentence of any kind -- the only date on the page
-- tested was an unrelated news item. Ohio Const. art. II s 2 does fix commencement at "the first
-- day of January next after their election", but that governs a member who ARRIVED AT A GENERAL
-- ELECTION and says nothing about the many who arrive by caucus appointment mid-term. Writing
-- 2025-01-01 for all 130 would be the San Jose D8/D10 error at scale: a rule that is true of most
-- rows, applied to rows it does not govern. This is the GA-2 / IN-2 / MN-2 / PA-2 pattern.
-- essentials.seat_officeholder() is NOT used: it refuses a NULL term_start by design.
-- ▶ Dating these 130 arrivals is a recorded debt, not a thing to invent here.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 PARTY IS NOT WRITTEN. Both directories carry it; party lives on races.primary_party.
--
-- 🔴🔴 TWO NAME COLLISIONS EXIST, BOTH ARE DIFFERENT PEOPLE, AND MY OWN CHECKS FOUND ONLY ONE
-- OF THEM. The database's guard found the other and aborted the first dry run. Full account at
-- step 2 below, including the key that finally worked.
--
-- 🔴 THE ROSTER WAS CHANGE-CHECKED PAGE BY PAGE. All 130 individual member pages were fetched and
-- every one names its own member's surname AND its own district number; none contains the word
-- "Vacant". The detector was controlled on a real page: the correct surname and district match, a
-- wrong surname and a wrong district do not.
-- ⚠ The sweep was rate-limited at HTTP 429 when run with 8 workers, and 79 of 130 pages came back
-- 429 -- which a less careful pass would have recorded as 79 roster failures. It was re-run
-- serially with backoff and every page answered.
--
-- ⚠ THE SENATE DIRECTORY IS NOT WHERE THE OBVIOUS URL POINTS. ohiosenate.gov/senators/directory
-- returns HTTP 200 and renders the word "ERROR" with a "(c) null" footer -- a clean 200 carrying
-- an error page. The real list is ohiosenate.gov/members/directory. Neither chamber's member pages
-- are reachable by district number: /members/district/<n> 404s on all 132, because member pages
-- are NAME-keyed.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- ─── 1. The 130 sitting members ───────────────────────────────────────────────

CREATE TEMP TABLE oh_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO oh_new_people(external_id, full_name, first_name, last_name) VALUES
  (-2760001, 'Dontavius L. Jarrells', 'Dontavius', 'Jarrells'),
  (-2760002, 'Latyna M. Humphrey', 'Latyna', 'Humphrey'),
  (-2760003, 'Ismail Mohamed', 'Ismail', 'Mohamed'),
  (-2760004, 'Beryl Brown Piccolantonio', 'Beryl', 'Piccolantonio'),
  (-2760005, 'Meredith R. Lawson-Rowe', 'Meredith', 'Lawson-Rowe'),
  (-2760006, 'Christine Cockley', 'Christine', 'Cockley'),
  (-2760007, 'C. Allison Russo', 'C.', 'Russo'),
  (-2760008, 'Anita Somani', 'Anita', 'Somani'),
  (-2760009, 'Munira Abdullahi', 'Munira', 'Abdullahi'),
  (-2760010, 'Mark Sigrist', 'Mark', 'Sigrist'),
  (-2760011, 'Crystal Lett', 'Crystal', 'Lett'),
  (-2760012, 'Brian Stewart', 'Brian', 'Stewart'),
  (-2760013, 'Tristan Rader', 'Tristan', 'Rader'),
  (-2760014, 'Sean P. Brennan', 'Sean', 'Brennan'),
  (-2760015, 'Chris Glassburn', 'Chris', 'Glassburn'),
  (-2760016, 'Bride Rose Sweeney', 'Bride', 'Sweeney'),
  (-2760017, 'Michael D. Dovilla', 'Michael', 'Dovilla'),
  (-2760018, 'Juanita O. Brent', 'Juanita', 'Brent'),
  (-2760019, 'Phillip M. Robinson, Jr.', 'Phillip', 'Robinson'),
  (-2760020, 'Terrence Upchurch', 'Terrence', 'Upchurch'),
  (-2760021, 'Eric Synenberg', 'Eric', 'Synenberg'),
  (-2760022, 'Darnell T. Brewer', 'Darnell', 'Brewer'),
  (-2760023, 'Daniel P. Troy', 'Daniel', 'Troy'),
  (-2760024, 'Dani Isaacsohn', 'Dani', 'Isaacsohn'),
  (-2760025, 'Cecil Thomas', 'Cecil', 'Thomas'),
  (-2760026, 'Ashley Bryant Bailey', 'Ashley', 'Bailey'),
  (-2760027, 'Rachel B. Baker', 'Rachel', 'Baker'),
  (-2760028, 'Karen Brownlee', 'Karen', 'Brownlee'),
  (-2760029, 'Cindy Abrams', 'Cindy', 'Abrams'),
  (-2760030, 'Mike Odioso', 'Mike', 'Odioso'),
  (-2760031, 'Bill Roemer', 'Bill', 'Roemer'),
  (-2760032, 'Jack K. Daniels', 'Jack', 'Daniels'),
  (-2760033, 'Veronica R. Sims', 'Veronica', 'Sims'),
  (-2760034, 'Derrick Hall', 'Derrick', 'Hall'),
  (-2760035, 'Steve Demetriou', 'Steve', 'Demetriou'),
  (-2760036, 'Andrea White', 'Andrea', 'White'),
  (-2760038, 'Desiree Tims', 'Desiree', 'Tims'),
  (-2760039, 'Phil Plummer', 'Phil', 'Plummer'),
  (-2760040, 'Rodney Creech', 'Rodney', 'Creech'),
  (-2760041, 'Erika White', 'Erika', 'White'),
  (-2760042, 'Elgin Rogers, Jr.', 'Elgin', 'Rogers'),
  (-2760043, 'Michele Grim', 'Michele', 'Grim'),
  (-2760044, 'Josh Williams', 'Josh', 'Williams'),
  (-2760045, 'Jennifer Gross', 'Jennifer', 'Gross'),
  (-2760046, 'Thomas Hall', 'Thomas', 'Hall'),
  (-2760047, 'Diane Mullins', 'Diane', 'Mullins'),
  (-2760048, 'Scott Oelslager', 'Scott', 'Oelslager'),
  (-2760049, 'Jim Thomas', 'Jim', 'Thomas'),
  (-2760050, 'Matthew Kishman', 'Matthew', 'Kishman'),
  (-2760051, 'Jodi Salvo', 'Jodi', 'Salvo'),
  (-2760052, 'Gayle Manning', 'Gayle', 'Manning'),
  (-2760053, 'Joseph A. Miller, III', 'Joseph', 'Miller'),
  (-2760054, 'Kellie Deeter', 'Kellie', 'Deeter'),
  (-2760055, 'Michelle Teska', 'Michelle', 'Teska'),
  (-2760056, 'Adam Mathews', 'Adam', 'Mathews'),
  (-2760057, 'Jamie Callender', 'Jamie', 'Callender'),
  (-2760058, 'Lauren McNally', 'Lauren', 'McNally'),
  (-2760059, 'Tex Fischer', 'Tex', 'Fischer'),
  (-2760060, 'Brian Lorenz', 'Brian', 'Lorenz'),
  (-2760061, 'Beth Lear', 'Beth', 'Lear'),
  (-2760062, 'Jean Schmidt', 'Jean', 'Schmidt'),
  (-2760063, 'Adam C. Bird', 'Adam', 'Bird'),
  (-2760064, 'Nick Santucci', 'Nick', 'Santucci'),
  (-2760065, 'David Thomas', 'David', 'Thomas'),
  (-2760066, 'Melanie Miller', 'Melanie', 'Miller'),
  (-2760067, 'Thaddeus J. Claggett', 'Thaddeus', 'Claggett'),
  (-2760068, 'Kevin D. Miller', 'Kevin', 'Miller'),
  (-2760069, 'Brian Lampton', 'Brian', 'Lampton'),
  (-2760070, 'Levi Dean', 'Levi', 'Dean'),
  (-2760071, 'Heidi Workman', 'Heidi', 'Workman'),
  (-2760072, 'Jeff LaRe', 'Jeff', 'LaRe'),
  (-2760073, 'Bernard Willis', 'Bernard', 'Willis'),
  (-2760074, 'Haraz N. Ghanbari', 'Haraz', 'Ghanbari'),
  (-2760075, 'Marilyn John', 'Marilyn', 'John'),
  (-2760076, 'Meredith Craig', 'Meredith', 'Craig'),
  (-2760077, 'Matt Huffman', 'Matt', 'Huffman'),
  (-2760078, 'Monica Robb Blasdel', 'Monica', 'Blasdel'),
  (-2760079, 'Johnathan Newman', 'Johnathan', 'Newman'),
  (-2760080, 'James M. Hoops', 'James', 'Hoops'),
  (-2760081, 'Roy Klopfenstein', 'Roy', 'Klopfenstein'),
  (-2760082, 'Ty D. Mathews', 'Ty', 'Mathews'),
  (-2760083, 'Angela N. King', 'Angela', 'King'),
  (-2760084, 'Tim Barhorst', 'Tim', 'Barhorst'),
  (-2760085, 'Tracy M. Richardson', 'Tracy', 'Richardson'),
  (-2760086, 'Riordan T. McClain', 'Riordan', 'McClain'),
  (-2760087, 'Gary Click', 'Gary', 'Click'),
  (-2760088, 'D. J. Swearingen', 'D.', 'Swearingen'),
  (-2760089, 'Justin Pizzulli', 'Justin', 'Pizzulli'),
  (-2760090, 'Bob Peterson', 'Bob', 'Peterson'),
  (-2760092, 'Jason Stephens', 'Jason', 'Stephens'),
  (-2760093, 'Kevin Ritter', 'Kevin', 'Ritter'),
  (-2760094, 'Ty Moore', 'Ty', 'Moore'),
  (-2760095, 'Ron Ferguson', 'Ron', 'Ferguson'),
  (-2760096, 'Adam Holmes', 'Adam', 'Holmes'),
  (-2760097, 'Mark Hiner', 'Mark', 'Hiner'),
  (-2760098, 'Sarah Fowler Arthur', 'Sarah', 'Arthur'),
  (-2760099, 'Rob McColley', 'Rob', 'McColley'),
  (-2760100, 'Theresa Gavarone', 'Theresa', 'Gavarone'),
  (-2760101, 'Michele Reynolds', 'Michele', 'Reynolds'),
  (-2760102, 'George F. Lang', 'George', 'Lang'),
  (-2760103, 'Stephen A. Huffman', 'Stephen', 'Huffman'),
  (-2760104, 'Willis E. Blackshear, Jr.', 'Willis', 'Blackshear'),
  (-2760105, 'Steve Wilson', 'Steve', 'Wilson'),
  (-2760106, 'Louis W. Blessing, III', 'Louis', 'Blessing'),
  (-2760107, 'Catherine D. Ingram', 'Catherine', 'Ingram'),
  (-2760108, 'Kyle Koehler', 'Kyle', 'Koehler'),
  (-2760109, 'Paula Hicks-Hudson', 'Paula', 'Hicks-Hudson'),
  (-2760110, 'Susan Manchester', 'Susan', 'Manchester'),
  (-2760111, 'Terry Johnson', 'Terry', 'Johnson'),
  (-2760112, 'Hearcel F. Craig', 'Hearcel', 'Craig'),
  (-2760113, 'Beth Liston', 'Beth', 'Liston'),
  (-2760114, 'Shane Wilkin', 'Shane', 'Wilkin'),
  (-2760115, 'Jerry C. Cirino', 'Jerry', 'Cirino'),
  (-2760116, 'Andrew O. Brenner', 'Andrew', 'Brenner'),
  (-2760117, 'Tim Schaffer', 'Tim', 'Schaffer'),
  (-2760118, 'Kent Smith', 'Kent', 'Smith'),
  (-2760119, 'Mark Romanchuk', 'Mark', 'Romanchuk'),
  (-2760120, 'Nickie J. Antonio', 'Nickie', 'Antonio'),
  (-2760121, 'Thomas F. Patton', 'Thomas', 'Patton'),
  (-2760122, 'William P. DeMora', 'William', 'DeMora'),
  (-2760123, 'Bill Reineke', 'Bill', 'Reineke'),
  (-2760124, 'Kristina D. Roegner', 'Kristina', 'Roegner'),
  (-2760125, 'Casey Weinstein', 'Casey', 'Weinstein'),
  (-2760126, 'Jane M. Timken', 'Jane', 'Timken'),
  (-2760127, 'Brian M. Chavez', 'Brian', 'Chavez'),
  (-2760128, 'Al Landis', 'Al', 'Landis'),
  (-2760129, 'Sandra O''Brien', 'Sandra', 'O''Brien'),
  (-2760130, 'Al Cutrona', 'Al', 'Cutrona');
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Ohio House of Representatives member directory, https://ohiohouse.gov/members/directory, and Ohio Senate member directory, https://ohiosenate.gov/members/directory; reconciled against Open States, https://data.openstates.org/people/current/oh.csv; change-checked against all 130 individual member pages, every one of which names its own member and its own district; read 2026-09-23 (OH-2) (CC_0132, OH-2)',
       true, true
FROM oh_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2 people who share a name with a DIFFERENT person — guard lifted ─────────
--
-- 🔴🔴 THE DATABASE'S OWN GUARD FOUND BOTH OF THESE, AND TWO OF MY DETECTORS HAD MISSED THEM.
-- An exact full_name sweep returned 0 of 130. A looser sweep on (first token, last token) found
-- only the Mark Johnson pair. Both missed Tom Young, because the existing row's full_name is
-- "Tom Young, Jr." -- its last token is "Jr.", not "Young". The trigger
-- essentials.politician_name_duplicate_guard keys on (first_name, last_name), which is the
-- correct key, and it aborted the first dry run. Re-running the sweep on the GUARD'S key, with a
-- control (65 active rows share last_name 'Smith'), returns exactly these two and nothing else.
-- ▶ WHEN A CONSTRAINT CATCHES SOMETHING YOUR OWN CHECK DID NOT, ADOPT THE CONSTRAINT'S KEY AND
--   RE-RUN THE WHOLE SWEEP. The first dry run is a detector too.
--
-- Both are DIFFERENT PEOPLE, and the evidence is structural rather than a judgement about names:
--   · HD-37 Tom Young  vs  -2745147 'Tom Young, Jr.', who SITS TODAY as a SOUTH CAROLINA
--     STATE SENATOR for SC SD-24 (seated by CC_0126, SC-2).
--   · HD-92 Mark Johnson  vs  -2732133 'Mark T. Johnson', who SITS TODAY as a MINNESOTA STATE
--     SENATOR (seated by the MN wave).
-- A person cannot simultaneously hold a Senate seat in another state and a seat in the Ohio
-- House, so these cannot be the same people. This is the GA roster trap, where 2 of 4 name hits
-- turned out to be a Colorado senator and a Utah treasurer.
--
-- The override is scoped to these two statements and switched back off immediately, so the other
-- 128 rows were inserted with the guard live.

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE oh_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO oh_namesake_people(external_id, full_name, first_name, last_name) VALUES
  (-2760037, 'Tom Young', 'Tom', 'Young'),
  (-2760091, 'Mark Johnson', 'Mark', 'Johnson');
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Ohio House of Representatives member directory, https://ohiohouse.gov/members/directory, and Ohio Senate member directory, https://ohiosenate.gov/members/directory; reconciled against Open States, https://data.openstates.org/people/current/oh.csv; change-checked against all 130 individual member pages, every one of which names its own member and its own district; read 2026-09-23 (OH-2) (CC_0132, OH-2)',
       true, true
FROM oh_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 3. The 130 terms ─────────────────────────────────────────────────────────
-- Keyed on (geo_id, district_type), never geo_id alone: '39031' is Senate District 31 AND an
-- Ohio county.

CREATE TEMP TABLE oh_terms(geo_id text, district_type text, external_id bigint) ON COMMIT DROP;

INSERT INTO oh_terms(geo_id, district_type, external_id) VALUES
  ('39001', 'STATE_LOWER', -2760001::bigint),
  ('39002', 'STATE_LOWER', -2760002::bigint),
  ('39003', 'STATE_LOWER', -2760003::bigint),
  ('39004', 'STATE_LOWER', -2760004::bigint),
  ('39005', 'STATE_LOWER', -2760005::bigint),
  ('39006', 'STATE_LOWER', -2760006::bigint),
  ('39007', 'STATE_LOWER', -2760007::bigint),
  ('39008', 'STATE_LOWER', -2760008::bigint),
  ('39009', 'STATE_LOWER', -2760009::bigint),
  ('39010', 'STATE_LOWER', -2760010::bigint),
  ('39011', 'STATE_LOWER', -2760011::bigint),
  ('39012', 'STATE_LOWER', -2760012::bigint),
  ('39013', 'STATE_LOWER', -2760013::bigint),
  ('39014', 'STATE_LOWER', -2760014::bigint),
  ('39015', 'STATE_LOWER', -2760015::bigint),
  ('39016', 'STATE_LOWER', -2760016::bigint),
  ('39017', 'STATE_LOWER', -2760017::bigint),
  ('39018', 'STATE_LOWER', -2760018::bigint),
  ('39019', 'STATE_LOWER', -2760019::bigint),
  ('39020', 'STATE_LOWER', -2760020::bigint),
  ('39021', 'STATE_LOWER', -2760021::bigint),
  ('39022', 'STATE_LOWER', -2760022::bigint),
  ('39023', 'STATE_LOWER', -2760023::bigint),
  ('39024', 'STATE_LOWER', -2760024::bigint),
  ('39025', 'STATE_LOWER', -2760025::bigint),
  ('39026', 'STATE_LOWER', -2760026::bigint),
  ('39027', 'STATE_LOWER', -2760027::bigint),
  ('39028', 'STATE_LOWER', -2760028::bigint),
  ('39029', 'STATE_LOWER', -2760029::bigint),
  ('39030', 'STATE_LOWER', -2760030::bigint),
  ('39031', 'STATE_LOWER', -2760031::bigint),
  ('39032', 'STATE_LOWER', -2760032::bigint),
  ('39033', 'STATE_LOWER', -2760033::bigint),
  ('39034', 'STATE_LOWER', -2760034::bigint),
  ('39035', 'STATE_LOWER', -2760035::bigint),
  ('39036', 'STATE_LOWER', -2760036::bigint),
  ('39037', 'STATE_LOWER', -2760037::bigint),
  ('39038', 'STATE_LOWER', -2760038::bigint),
  ('39039', 'STATE_LOWER', -2760039::bigint),
  ('39040', 'STATE_LOWER', -2760040::bigint),
  ('39041', 'STATE_LOWER', -2760041::bigint),
  ('39042', 'STATE_LOWER', -2760042::bigint),
  ('39043', 'STATE_LOWER', -2760043::bigint),
  ('39044', 'STATE_LOWER', -2760044::bigint),
  ('39045', 'STATE_LOWER', -2760045::bigint),
  ('39046', 'STATE_LOWER', -2760046::bigint),
  ('39047', 'STATE_LOWER', -2760047::bigint),
  ('39048', 'STATE_LOWER', -2760048::bigint),
  ('39049', 'STATE_LOWER', -2760049::bigint),
  ('39050', 'STATE_LOWER', -2760050::bigint),
  ('39051', 'STATE_LOWER', -2760051::bigint),
  ('39052', 'STATE_LOWER', -2760052::bigint),
  ('39053', 'STATE_LOWER', -2760053::bigint),
  ('39054', 'STATE_LOWER', -2760054::bigint),
  ('39055', 'STATE_LOWER', -2760055::bigint),
  ('39056', 'STATE_LOWER', -2760056::bigint),
  ('39057', 'STATE_LOWER', -2760057::bigint),
  ('39058', 'STATE_LOWER', -2760058::bigint),
  ('39059', 'STATE_LOWER', -2760059::bigint),
  ('39060', 'STATE_LOWER', -2760060::bigint),
  ('39061', 'STATE_LOWER', -2760061::bigint),
  ('39062', 'STATE_LOWER', -2760062::bigint),
  ('39063', 'STATE_LOWER', -2760063::bigint),
  ('39064', 'STATE_LOWER', -2760064::bigint),
  ('39065', 'STATE_LOWER', -2760065::bigint),
  ('39067', 'STATE_LOWER', -2760066::bigint),
  ('39068', 'STATE_LOWER', -2760067::bigint),
  ('39069', 'STATE_LOWER', -2760068::bigint),
  ('39070', 'STATE_LOWER', -2760069::bigint),
  ('39071', 'STATE_LOWER', -2760070::bigint),
  ('39072', 'STATE_LOWER', -2760071::bigint),
  ('39073', 'STATE_LOWER', -2760072::bigint),
  ('39074', 'STATE_LOWER', -2760073::bigint),
  ('39075', 'STATE_LOWER', -2760074::bigint),
  ('39076', 'STATE_LOWER', -2760075::bigint),
  ('39077', 'STATE_LOWER', -2760076::bigint),
  ('39078', 'STATE_LOWER', -2760077::bigint),
  ('39079', 'STATE_LOWER', -2760078::bigint),
  ('39080', 'STATE_LOWER', -2760079::bigint),
  ('39081', 'STATE_LOWER', -2760080::bigint),
  ('39082', 'STATE_LOWER', -2760081::bigint),
  ('39083', 'STATE_LOWER', -2760082::bigint),
  ('39084', 'STATE_LOWER', -2760083::bigint),
  ('39085', 'STATE_LOWER', -2760084::bigint),
  ('39086', 'STATE_LOWER', -2760085::bigint),
  ('39087', 'STATE_LOWER', -2760086::bigint),
  ('39088', 'STATE_LOWER', -2760087::bigint),
  ('39089', 'STATE_LOWER', -2760088::bigint),
  ('39090', 'STATE_LOWER', -2760089::bigint),
  ('39091', 'STATE_LOWER', -2760090::bigint),
  ('39092', 'STATE_LOWER', -2760091::bigint),
  ('39093', 'STATE_LOWER', -2760092::bigint),
  ('39094', 'STATE_LOWER', -2760093::bigint),
  ('39095', 'STATE_LOWER', -2760094::bigint),
  ('39096', 'STATE_LOWER', -2760095::bigint),
  ('39097', 'STATE_LOWER', -2760096::bigint),
  ('39098', 'STATE_LOWER', -2760097::bigint),
  ('39099', 'STATE_LOWER', -2760098::bigint),
  ('39001', 'STATE_UPPER', -2760099::bigint),
  ('39002', 'STATE_UPPER', -2760100::bigint),
  ('39003', 'STATE_UPPER', -2760101::bigint),
  ('39004', 'STATE_UPPER', -2760102::bigint),
  ('39005', 'STATE_UPPER', -2760103::bigint),
  ('39006', 'STATE_UPPER', -2760104::bigint),
  ('39007', 'STATE_UPPER', -2760105::bigint),
  ('39008', 'STATE_UPPER', -2760106::bigint),
  ('39009', 'STATE_UPPER', -2760107::bigint),
  ('39010', 'STATE_UPPER', -2760108::bigint),
  ('39011', 'STATE_UPPER', -2760109::bigint),
  ('39012', 'STATE_UPPER', -2760110::bigint),
  ('39014', 'STATE_UPPER', -2760111::bigint),
  ('39015', 'STATE_UPPER', -2760112::bigint),
  ('39016', 'STATE_UPPER', -2760113::bigint),
  ('39017', 'STATE_UPPER', -2760114::bigint),
  ('39018', 'STATE_UPPER', -2760115::bigint),
  ('39019', 'STATE_UPPER', -2760116::bigint),
  ('39020', 'STATE_UPPER', -2760117::bigint),
  ('39021', 'STATE_UPPER', -2760118::bigint),
  ('39022', 'STATE_UPPER', -2760119::bigint),
  ('39023', 'STATE_UPPER', -2760120::bigint),
  ('39024', 'STATE_UPPER', -2760121::bigint),
  ('39025', 'STATE_UPPER', -2760122::bigint),
  ('39026', 'STATE_UPPER', -2760123::bigint),
  ('39027', 'STATE_UPPER', -2760124::bigint),
  ('39028', 'STATE_UPPER', -2760125::bigint),
  ('39029', 'STATE_UPPER', -2760126::bigint),
  ('39030', 'STATE_UPPER', -2760127::bigint),
  ('39031', 'STATE_UPPER', -2760128::bigint),
  ('39032', 'STATE_UPPER', -2760129::bigint),
  ('39033', 'STATE_UPPER', -2760130::bigint);
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',
       'Ohio House of Representatives member directory, https://ohiohouse.gov/members/directory, and Ohio Senate member directory, https://ohiosenate.gov/members/directory; reconciled against Open States, https://data.openstates.org/people/current/oh.csv; change-checked against all 130 individual member pages, every one of which names its own member and its own district; read 2026-09-23 (OH-2) (CC_0132, OH-2)'
FROM oh_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'oh'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people   int;
  v_offices  int;
  v_terms    int;
  v_dated    int;
  v_ended    int;
  v_fanout   int;
  v_two      int;
  v_unseated int;
  v_akron    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2760200 AND -2760001;
  IF v_people <> 130 THEN
    RAISE EXCEPTION 'OH-2 occupancy: expected 130 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_offices <> 132 THEN
    RAISE EXCEPTION 'OH-2 occupancy: expected 132 Ohio legislative offices, got %', v_offices;
  END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_terms <> 130 THEN
    RAISE EXCEPTION 'OH-2 occupancy: expected 130 terms, got %', v_terms;
  END IF;

  -- Nothing may carry a date or an end: every arrival here is unsourced by design.
  SELECT count(*) FILTER (WHERE ot.term_start IS NOT NULL OR ot.start_precision <> 'unknown'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_dated <> 0 THEN
    RAISE EXCEPTION 'OH-2 occupancy: % Ohio legislative term(s) carry a start date this wave cannot source', v_dated;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'OH-2 occupancy: % Ohio legislative term(s) carry a term_end — a future end self-vacates a seat', v_ended;
  END IF;

  -- One term per office. The exclusion constraint already forbids two PEOPLE on one office; it
  -- cannot see one PERSON ON TWO OFFICES, which is the next check.
  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.office_id FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'oh' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY ot.office_id HAVING count(*) <> 1) x;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION 'OH-2 occupancy: % Ohio legislative office(s) do not have exactly one term', v_fanout;
  END IF;

  SELECT count(*) INTO v_two FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
    WHERE ot.politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -2760200 AND -2760001)
    GROUP BY ot.politician_id HAVING count(*) <> 1) y;
  IF v_two <> 0 THEN
    RAISE EXCEPTION 'OH-2 occupancy: % person/people created by this wave hold more than one office', v_two;
  END IF;

  -- The two vacancies must still be unseated, and they must be the RIGHT two.
  SELECT count(*) INTO v_unseated
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id)
    AND NOT (o.is_vacant AND ((d.district_type::text = 'STATE_LOWER' AND d.geo_id = '39066')
                           OR (d.district_type::text = 'STATE_UPPER' AND d.geo_id = '39013')));
  IF v_unseated <> 0 THEN
    RAISE EXCEPTION 'OH-2 occupancy: % Ohio legislative office(s) have no term and are not one of the two known vacancies', v_unseated;
  END IF;

  -- 🟢 The wave's own jurisdiction, asserted by name rather than by count: Akron City Hall sits in
  -- HD-33 and SD-28, and both must now return a seated member.
  SELECT count(*) INTO v_akron
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh'
    AND ((d.district_type::text = 'STATE_LOWER' AND d.geo_id = '39033')
      OR (d.district_type::text = 'STATE_UPPER' AND d.geo_id = '39028'));
  IF v_akron <> 2 THEN
    RAISE EXCEPTION 'OH-2 occupancy: Akron''s own HD-33 and SD-28 do not both carry a term (got %)', v_akron;
  END IF;

  RAISE NOTICE 'OH-2 occupancy OK: 130 people, 130 terms, 132 offices, 2 vacancies intact, Akron HD-33 + SD-28 seated';
END $$;

COMMIT;
