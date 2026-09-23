-- CA_0160_seed_la_city_atlarge_councils_2026_batch1.sql
-- Seed the Nov 3 2026 AT-LARGE city council (and directly elected mayor) contests of 13 LA-County cities, so an
-- address in each city returns its municipal contest. Batch 1 of the LA-cities slice.
--
-- WHY THESE ARE MISSING: city candidates file with each CITY CLERK, so none are on the LA RR/CC certified list
-- (lavote.gov/Apps/CandidateList/Index?id=4348) that the school / special-district seeds (CA_0142...) came from.
-- The RR/CC "2026 Scheduled Elections" list (content.lavote.gov/docs/rrcc/documents/scheduled-elections-5-5.pdf)
-- names 65 cities with a Nov 3 general municipal election. Election method is from the RR/CC precinct layer
-- (public.gis.lacounty.gov/.../Political_Boundaries/MapServer/34, DST_CITY/DIV_CITY): every city here shows only
-- DIV_CITY 0 = at large, and no candidate list names a district.
--
-- SOURCES: every candidate is from the city clerk's own list, read 2026-09-22 and cited per row in
-- race_candidates.source. Each list was re-checked name by name against the original document (PDFs text-
-- extracted; Lawndale's scanned certified list read from the image). Names are the clerk's ballot names;
-- ballot designations are stored where the clerk publishes them.
--
--   Santa Monica City Council          3 seat(s)  12 candidate(s)  2 incumbent(s)
--   Culver City City Council           2 seat(s)   5 candidate(s)  1 incumbent(s)
--   West Hollywood City Council        3 seat(s)  14 candidate(s)  1 incumbent(s)
--   Manhattan Beach City Council       2 seat(s)   4 candidate(s)  1 incumbent(s)
--   Norwalk City Council               2 seat(s)   6 candidate(s)  1 incumbent(s)
--   Lynwood City Council               3 seat(s)   6 candidate(s)  3 incumbent(s)
--   Cudahy City Council                3 seat(s)   5 candidate(s)  1 incumbent(s)
--   Hawthorne City Council             2 seat(s)   3 candidate(s)  2 incumbent(s)
--   South Gate City Council            2 seat(s)   5 candidate(s)  2 incumbent(s)
--   Burbank City Council               3 seat(s)  13 candidate(s)  2 incumbent(s)
--   Baldwin Park City Council          2 seat(s)   3 candidate(s)  2 incumbent(s)
--   Lawndale Mayor                     1 seat(s)   2 candidate(s)  1 incumbent(s)
--   Monrovia Mayor                     1 seat(s)   1 candidate(s)  1 incumbent(s)  (uncontested)
--
-- OFFICE BINDING: each at-large council race binds to the lowest-id council office on the city's whole-city
-- LOCAL district (geo_id = Census place, G4110) purely for geography -- the CA_0142 at-large pattern. A mayor race
-- binds to the Mayor office on the LOCAL_EXEC place district. No new office.
--
-- INCUMBENTS link to the row essentials.office_current_holder names for a seat in the same city (the gate re-checks
-- every link). In two cities the council-chosen mayor holds a separate Mayor office, so that member running for
-- council links to the Mayor holder row (Howorth, Manhattan Beach; Avila, Baldwin Park). One sitting official
-- running for ANOTHER seat is linked as a non-incumbent: Councilmember Frank ("Francisco M.") Talavera,
-- running for Lawndale Mayor.
-- Party is cleared on every linked row (antipartisan; 2026-09-22 operator decision, same as the school rosters).
--
-- NOT IN THIS BATCH (owed, tracked):
--   * City Clerk / City Treasurer contests of Hawthorne, South Gate, Burbank, Baldwin Park, Lawndale, Monrovia: no
--     such office exists in the DB yet (needs the office + its current holder first).
--   * Lawndale and Monrovia council contests (and Malibu, Rosemead, San Gabriel, Pico Rivera, Bell Gardens): an
--     incumbent candidate is missing from the DB roster (usually the Mayor Pro Tem) -> roster fix first.
--   * El Segundo: the clerk publishes only "nomination papers pulled/returned", not a qualified list.
--   * Hermosa Beach: the city site denies access; no official list could be read.
--   * La Puente: NO contest -- Resolution 26-6015 (8/19/2026) appointed the two nominees in lieu of election.
--
-- RACES go on '2026 LA County General' (d91a20ce-557e-4615-a31b-5b2b3df2ed14), as the LA City / Compton / Pomona
-- city races already do; nonpartisan -> primary_party NULL; party is never stored on candidates. Uncontested
-- contests are included (decision 2026-09-22).
--
-- IDEMPOTENT: races on (election_id, position_name); candidates on (race_id, lower(full_name)).

BEGIN;

-- ─── 0. Pre-flight: every binding target exists ───────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (VALUES
    ('0670000', 'LOCAL', NULL, 'Santa Monica City Council'),
    ('0617568', 'LOCAL', NULL, 'Culver City City Council'),
    ('0684410', 'LOCAL', NULL, 'West Hollywood City Council'),
    ('0645400', 'LOCAL', NULL, 'Manhattan Beach City Council'),
    ('0652526', 'LOCAL', NULL, 'Norwalk City Council'),
    ('0644574', 'LOCAL', NULL, 'Lynwood City Council'),
    ('0617498', 'LOCAL', NULL, 'Cudahy City Council'),
    ('0632548', 'LOCAL', NULL, 'Hawthorne City Council'),
    ('0673080', 'LOCAL', NULL, 'South Gate City Council'),
    ('0608954', 'LOCAL', NULL, 'Burbank City Council'),
    ('0603666', 'LOCAL', NULL, 'Baldwin Park City Council'),
    ('0640886', 'LOCAL_EXEC', 'Mayor', 'Lawndale Mayor'),
    ('0648648', 'LOCAL_EXEC', 'Mayor', 'Monrovia Mayor')
  ) AS v(place, dtype, otitle, pos)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                      WHERE d.geo_id = v.place AND d.district_type = v.dtype AND (v.otitle IS NULL OR o.title = v.otitle));
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: % race(s) with no office to bind to', n; END IF;
END $$;

-- ─── 1. Races ─────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid, t.office_id, t.pos, NULL, t.seats
  FROM (SELECT v.pos, v.seats,
               (SELECT o.id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                 WHERE d.geo_id = v.place AND d.district_type = v.dtype AND (v.otitle IS NULL OR o.title = v.otitle)
                 ORDER BY o.id LIMIT 1) AS office_id
          FROM (VALUES
    ('0670000', 'LOCAL', NULL, 'Santa Monica City Council', 3),
    ('0617568', 'LOCAL', NULL, 'Culver City City Council', 2),
    ('0684410', 'LOCAL', NULL, 'West Hollywood City Council', 3),
    ('0645400', 'LOCAL', NULL, 'Manhattan Beach City Council', 2),
    ('0652526', 'LOCAL', NULL, 'Norwalk City Council', 2),
    ('0644574', 'LOCAL', NULL, 'Lynwood City Council', 3),
    ('0617498', 'LOCAL', NULL, 'Cudahy City Council', 3),
    ('0632548', 'LOCAL', NULL, 'Hawthorne City Council', 2),
    ('0673080', 'LOCAL', NULL, 'South Gate City Council', 2),
    ('0608954', 'LOCAL', NULL, 'Burbank City Council', 3),
    ('0603666', 'LOCAL', NULL, 'Baldwin Park City Council', 2),
    ('0640886', 'LOCAL_EXEC', 'Mayor', 'Lawndale Mayor', 1),
    ('0648648', 'LOCAL_EXEC', 'Mayor', 'Monrovia Mayor', 1)
          ) AS v(place, dtype, otitle, pos, seats)) t
 WHERE t.office_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = t.pos);

-- ─── 2. Candidates ────────────────────────────────────────────────────────────────────
INSERT INTO essentials.race_candidates
       (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, occupational_designation, source)
SELECT r.id, v.pid, v.full_name, v.first_name, v.last_name, v.inc, 'active', v.desig, v.src
  FROM (VALUES
    ('Santa Monica City Council', 'Wade Kelley', 'Wade', 'Kelley', NULL::uuid, false, 'Singer/Songwriter', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Ashley Oelsen', 'Ashley', 'Oelsen', NULL::uuid, false, 'Scientist/Commissioner', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Ericka Lesley', 'Ericka', 'Lesley', NULL::uuid, false, 'Rent Control Boardmember', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Lindsay Davis', 'Lindsay', 'Davis', NULL::uuid, false, 'Yoga Instructor', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Lana Negrete', 'Lana', 'Negrete', '5604c5ae-d10d-4ca3-920d-dd3592278777'::uuid, true, 'Councilmember/ Businesswoman/Mother', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Phil Brock', 'Phil', 'Brock', NULL::uuid, false, 'Businessperson/Board member', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Daniel Ivanov', 'Daniel', 'Ivanov', NULL::uuid, false, 'Rent Control Board Chair/Attorney', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Eli Gill', 'Eli', 'Gill', NULL::uuid, false, 'Business Operations Manager', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Brett Morrow', 'Brett', 'Morrow', NULL::uuid, false, 'Health Official /Commissioner', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Derrick Townsend', 'Derrick', 'Townsend', NULL::uuid, false, 'Healthcare/Rehabilitation Specialist', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Caroline Torosis', 'Caroline', 'Torosis', '0314141a-3444-4382-a9ae-84394bbd486f'::uuid, true, 'Mayor/Attorney', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Santa Monica City Council', 'Doug Trussler', 'Doug', 'Trussler', NULL::uuid, false, 'Businessman/Coach/Parent', 'City of Santa Monica City Clerk, General Election 2026 candidate list, City Council 4-year, with ballot designations (santamonica.gov/elections/2026-11-02/general-election-2026). Retrieved 2026-09-22.'),
    ('Culver City City Council', 'Jeannine Wisnosky Stehlin', 'Jeannine', 'Stehlin', NULL::uuid, false, 'Small Business Owner', 'City of Culver City City Clerk, List of Qualified Candidates Running for Culver City City Council, updated 8/14/2026 (culvercity.gov/files/assets/public/v/1/documents/city-clerk/election-info/2026-nov-3-election/2026-08-14__official-list-of-qualified-candidates__final.pdf). Retrieved 2026-09-22.'),
    ('Culver City City Council', 'Franklin Carvajal', 'Franklin', 'Carvajal', NULL::uuid, false, 'Psychologist', 'City of Culver City City Clerk, List of Qualified Candidates Running for Culver City City Council, updated 8/14/2026 (culvercity.gov/files/assets/public/v/1/documents/city-clerk/election-info/2026-nov-3-election/2026-08-14__official-list-of-qualified-candidates__final.pdf). Retrieved 2026-09-22.'),
    ('Culver City City Council', 'Freddy Puza', 'Freddy', 'Puza', '1bb7df04-db6e-447f-b358-3f12526eb32e'::uuid, true, 'Mayor/Education Director', 'City of Culver City City Clerk, List of Qualified Candidates Running for Culver City City Council, updated 8/14/2026 (culvercity.gov/files/assets/public/v/1/documents/city-clerk/election-info/2026-nov-3-election/2026-08-14__official-list-of-qualified-candidates__final.pdf). Retrieved 2026-09-22.'),
    ('Culver City City Council', 'Thomas Aujero Small', 'Thomas', 'Small', NULL::uuid, false, 'Urban Development Strategist', 'City of Culver City City Clerk, List of Qualified Candidates Running for Culver City City Council, updated 8/14/2026 (culvercity.gov/files/assets/public/v/1/documents/city-clerk/election-info/2026-nov-3-election/2026-08-14__official-list-of-qualified-candidates__final.pdf). Retrieved 2026-09-22.'),
    ('Culver City City Council', 'Kimberley “Kim” Griffin', 'Kimberley', 'Griffin', NULL::uuid, false, 'Community Volunteer', 'City of Culver City City Clerk, List of Qualified Candidates Running for Culver City City Council, updated 8/14/2026 (culvercity.gov/files/assets/public/v/1/documents/city-clerk/election-info/2026-nov-3-election/2026-08-14__official-list-of-qualified-candidates__final.pdf). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Helen Krieger', 'Helen', 'Krieger', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Kody Christiansen', 'Kody', 'Christiansen', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Jonathan Cottrell', 'Jonathan', 'Cottrell', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Stephen Post', 'Stephen', 'Post', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Joel Zaldivar', 'Joel', 'Zaldivar', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Kevin Ligon', 'Kevin', 'Ligon', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Tom Demille', 'Tom', 'Demille', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'John Duran', 'John', 'Duran', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Larry Block', 'Larry', 'Block', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Kyle Brazeal', 'Kyle', 'Brazeal', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Chelsea Byers', 'Chelsea', 'Byers', 'a3aac8fc-d8cb-4cb7-b6be-e5b0fa97c15a'::uuid, true, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Alden “Marlon” Gobel', 'Alden', 'Gobel', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Chukwudubem “Chiedu” Egbuniwe', 'Chukwudubem', 'Egbuniwe', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('West Hollywood City Council', 'Tatyana “Tanya” Tsikanovsky', 'Tatyana', 'Tsikanovsky', NULL::uuid, false, NULL, 'City of West Hollywood City Clerk, Notice of Nominees for Public Office, posted 8/19/2026 (weho.org/home/showpublisheddocument/66013/639227456423830000). Retrieved 2026-09-22.'),
    ('Manhattan Beach City Council', 'Richard P. Montgomery', 'Richard', 'Montgomery', NULL::uuid, false, NULL, 'City of Manhattan Beach City Clerk, Qualified City Council Candidates for November 3, 2026 General Municipal Election (manhattanbeach.gov/departments/city-clerk/elections). Retrieved 2026-09-22.'),
    ('Manhattan Beach City Council', 'Amy Howorth', 'Amy', 'Howorth', '5b0b0edf-c2f2-4359-92d5-d245f8826111'::uuid, true, NULL, 'City of Manhattan Beach City Clerk, Qualified City Council Candidates for November 3, 2026 General Municipal Election (manhattanbeach.gov/departments/city-clerk/elections). Retrieved 2026-09-22.'),
    ('Manhattan Beach City Council', 'Mark Burton', 'Mark', 'Burton', NULL::uuid, false, NULL, 'City of Manhattan Beach City Clerk, Qualified City Council Candidates for November 3, 2026 General Municipal Election (manhattanbeach.gov/departments/city-clerk/elections). Retrieved 2026-09-22.'),
    ('Manhattan Beach City Council', 'Joseph Ungoco', 'Joseph', 'Ungoco', NULL::uuid, false, NULL, 'City of Manhattan Beach City Clerk, Qualified City Council Candidates for November 3, 2026 General Municipal Election (manhattanbeach.gov/departments/city-clerk/elections). Retrieved 2026-09-22.'),
    ('Norwalk City Council', 'Tony Ayala', 'Tony', 'Ayala', '5e8bcf17-3a4d-4614-a71c-c4ea8396f7cb'::uuid, true, NULL, 'City of Norwalk City Clerk, Qualified Candidates, November 3, 2026, dated 8/13/2026 (norwalkca.gov/Documents/Departments & Services/City Clerk/Elections/Candidate List - public.pdf). Retrieved 2026-09-22.'),
    ('Norwalk City Council', 'Rachell Jaimes', 'Rachell', 'Jaimes', NULL::uuid, false, NULL, 'City of Norwalk City Clerk, Qualified Candidates, November 3, 2026, dated 8/13/2026 (norwalkca.gov/Documents/Departments & Services/City Clerk/Elections/Candidate List - public.pdf). Retrieved 2026-09-22.'),
    ('Norwalk City Council', 'Richard LeGaspi', 'Richard', 'LeGaspi', NULL::uuid, false, NULL, 'City of Norwalk City Clerk, Qualified Candidates, November 3, 2026, dated 8/13/2026 (norwalkca.gov/Documents/Departments & Services/City Clerk/Elections/Candidate List - public.pdf). Retrieved 2026-09-22.'),
    ('Norwalk City Council', 'Daniel Moreno', 'Daniel', 'Moreno', NULL::uuid, false, NULL, 'City of Norwalk City Clerk, Qualified Candidates, November 3, 2026, dated 8/13/2026 (norwalkca.gov/Documents/Departments & Services/City Clerk/Elections/Candidate List - public.pdf). Retrieved 2026-09-22.'),
    ('Norwalk City Council', 'Leonard Shryock', 'Leonard', 'Shryock', NULL::uuid, false, NULL, 'City of Norwalk City Clerk, Qualified Candidates, November 3, 2026, dated 8/13/2026 (norwalkca.gov/Documents/Departments & Services/City Clerk/Elections/Candidate List - public.pdf). Retrieved 2026-09-22.'),
    ('Norwalk City Council', 'Nikolas Woods', 'Nikolas', 'Woods', NULL::uuid, false, NULL, 'City of Norwalk City Clerk, Qualified Candidates, November 3, 2026, dated 8/13/2026 (norwalkca.gov/Documents/Departments & Services/City Clerk/Elections/Candidate List - public.pdf). Retrieved 2026-09-22.'),
    ('Lynwood City Council', 'Mishaun Watkins', 'Mishaun', 'Watkins', NULL::uuid, false, 'Planning Commissioner', 'City of Lynwood City Clerk, Qualified Candidate Filing List, November 3, 2026 General Municipal Election, updated 8/14/2026 (lynwoodca.gov/DocumentCenter/View/2632). Retrieved 2026-09-22.'),
    ('Lynwood City Council', 'Gabriela Camacho', 'Gabriela', 'Camacho', '90b0fc60-30ca-4388-92b0-ff5dd2b443cb'::uuid, true, 'Mayor, Teacher, Mom', 'City of Lynwood City Clerk, Qualified Candidate Filing List, November 3, 2026 General Municipal Election, updated 8/14/2026 (lynwoodca.gov/DocumentCenter/View/2632). Retrieved 2026-09-22.'),
    ('Lynwood City Council', 'Luis Gerardo Cuellar', 'Luis', 'Cuellar', '4110139f-8a59-40fb-a10a-cad9a224bb80'::uuid, true, 'Appointed Councilmember / Businessman', 'City of Lynwood City Clerk, Qualified Candidate Filing List, November 3, 2026 General Municipal Election, updated 8/14/2026 (lynwoodca.gov/DocumentCenter/View/2632). Retrieved 2026-09-22.'),
    ('Lynwood City Council', 'Emiliano Arellano', 'Emiliano', 'Arellano', NULL::uuid, false, 'Public Safety Commissioner', 'City of Lynwood City Clerk, Qualified Candidate Filing List, November 3, 2026 General Municipal Election, updated 8/14/2026 (lynwoodca.gov/DocumentCenter/View/2632). Retrieved 2026-09-22.'),
    ('Lynwood City Council', 'Alfonso Morales', 'Alfonso', 'Morales', NULL::uuid, false, 'Attorney/School Boardmember', 'City of Lynwood City Clerk, Qualified Candidate Filing List, November 3, 2026 General Municipal Election, updated 8/14/2026 (lynwoodca.gov/DocumentCenter/View/2632). Retrieved 2026-09-22.'),
    ('Lynwood City Council', 'Juan Muñoz-Guevara', 'Juan', 'Muñoz-Guevara', 'de2ca46a-652a-4620-bfc7-8ff1006b26d3'::uuid, true, 'Councilmember/Labor Organizer', 'City of Lynwood City Clerk, Qualified Candidate Filing List, November 3, 2026 General Municipal Election, updated 8/14/2026 (lynwoodca.gov/DocumentCenter/View/2632). Retrieved 2026-09-22.'),
    ('Cudahy City Council', 'Cynthia Gonzalez', 'Cynthia', 'Gonzalez', NULL::uuid, false, NULL, 'City of Cudahy City Clerk, List of Potential/Qualified Candidates for Member of City Council, each marked "Qualified as a Candidate" (cityofcudahyca.gov/DocumentCenter/View/2610). Retrieved 2026-09-22.'),
    ('Cudahy City Council', 'Martin U. Fuentes', 'Martin', 'Fuentes', '433cc087-78b2-4d09-b2d8-c15b5f202008'::uuid, true, NULL, 'City of Cudahy City Clerk, List of Potential/Qualified Candidates for Member of City Council, each marked "Qualified as a Candidate" (cityofcudahyca.gov/DocumentCenter/View/2610). Retrieved 2026-09-22.'),
    ('Cudahy City Council', 'Richard Corvera-Hernandez', 'Richard', 'Corvera-Hernandez', NULL::uuid, false, NULL, 'City of Cudahy City Clerk, List of Potential/Qualified Candidates for Member of City Council, each marked "Qualified as a Candidate" (cityofcudahyca.gov/DocumentCenter/View/2610). Retrieved 2026-09-22.'),
    ('Cudahy City Council', 'Jose R. Gonzalez', 'Jose', 'Gonzalez', NULL::uuid, false, NULL, 'City of Cudahy City Clerk, List of Potential/Qualified Candidates for Member of City Council, each marked "Qualified as a Candidate" (cityofcudahyca.gov/DocumentCenter/View/2610). Retrieved 2026-09-22.'),
    ('Cudahy City Council', 'Cynthia Romo', 'Cynthia', 'Romo', NULL::uuid, false, NULL, 'City of Cudahy City Clerk, List of Potential/Qualified Candidates for Member of City Council, each marked "Qualified as a Candidate" (cityofcudahyca.gov/DocumentCenter/View/2610). Retrieved 2026-09-22.'),
    ('Hawthorne City Council', 'Katrina Manning', 'Katrina', 'Manning', 'fc64110f-80f5-43a8-b5c2-f814219024fc'::uuid, true, NULL, 'City of Hawthorne, Notice of Qualified Candidates for Public Office, dated 8/17/2026 (cityofhawthorne.org/government/city-clerk/election-information-and-voting). Retrieved 2026-09-22.'),
    ('Hawthorne City Council', 'Alexandre ''Alex'' Monteiro', 'Alexandre', 'Monteiro', '3b4186ff-c161-4f7f-832e-b0faae340ed5'::uuid, true, NULL, 'City of Hawthorne, Notice of Qualified Candidates for Public Office, dated 8/17/2026 (cityofhawthorne.org/government/city-clerk/election-information-and-voting). Retrieved 2026-09-22.'),
    ('Hawthorne City Council', 'Sergio Roberto Mortara', 'Sergio', 'Mortara', NULL::uuid, false, NULL, 'City of Hawthorne, Notice of Qualified Candidates for Public Office, dated 8/17/2026 (cityofhawthorne.org/government/city-clerk/election-information-and-voting). Retrieved 2026-09-22.'),
    ('South Gate City Council', 'Alfonso (Al) Rios', 'Alfonso', 'Rios', '8247e088-2ac8-4ae1-bac9-ff537dd27fec'::uuid, true, NULL, 'City of South Gate City Clerk, List of Qualified Candidates, November 3, 2026 General Election, dated 8/18/2026 (cityofsouthgate.org/files/sharedassets/public/v/2/government/departments/city-clerks-office/elections/documents/list-of-qualified-candidates-nov-3-2026-general-election-2.pdf). Retrieved 2026-09-22.'),
    ('South Gate City Council', 'Joshua Barron', 'Joshua', 'Barron', 'e109a1be-eff6-4982-af5a-ac1923f43f10'::uuid, true, NULL, 'City of South Gate City Clerk, List of Qualified Candidates, November 3, 2026 General Election, dated 8/18/2026 (cityofsouthgate.org/files/sharedassets/public/v/2/government/departments/city-clerks-office/elections/documents/list-of-qualified-candidates-nov-3-2026-general-election-2.pdf). Retrieved 2026-09-22.'),
    ('South Gate City Council', 'Alan Garcia', 'Alan', 'Garcia', NULL::uuid, false, NULL, 'City of South Gate City Clerk, List of Qualified Candidates, November 3, 2026 General Election, dated 8/18/2026 (cityofsouthgate.org/files/sharedassets/public/v/2/government/departments/city-clerks-office/elections/documents/list-of-qualified-candidates-nov-3-2026-general-election-2.pdf). Retrieved 2026-09-22.'),
    ('South Gate City Council', 'Edgar Pelayo', 'Edgar', 'Pelayo', NULL::uuid, false, NULL, 'City of South Gate City Clerk, List of Qualified Candidates, November 3, 2026 General Election, dated 8/18/2026 (cityofsouthgate.org/files/sharedassets/public/v/2/government/departments/city-clerks-office/elections/documents/list-of-qualified-candidates-nov-3-2026-general-election-2.pdf). Retrieved 2026-09-22.'),
    ('South Gate City Council', 'Jimmy Ozaeta', 'Jimmy', 'Ozaeta', NULL::uuid, false, NULL, 'City of South Gate City Clerk, List of Qualified Candidates, November 3, 2026 General Election, dated 8/18/2026 (cityofsouthgate.org/files/sharedassets/public/v/2/government/departments/city-clerks-office/elections/documents/list-of-qualified-candidates-nov-3-2026-general-election-2.pdf). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Jackie Waltman', 'Jackie', 'Waltman', NULL::uuid, false, 'Retired', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Samantha Wick', 'Samantha', 'Wick', NULL::uuid, false, 'Nonprofit Grant Writer', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Eddy Polon', 'Eddy', 'Polon', NULL::uuid, false, 'Community Advocate/Screenwriter', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'JT Parr', 'JT', 'Parr', NULL::uuid, false, 'Comedian', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Nikki Perez', 'Nikki', 'Perez', '96f91743-def6-436c-9537-a4b836c1b3eb'::uuid, true, 'Burbank City Council Member', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Jonathan Ontiveros', 'Jonathan', 'Ontiveros', NULL::uuid, false, 'Civil Engineering Professional', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'David Donahue', 'David', 'Donahue', NULL::uuid, false, 'Small Business Owner', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Nolan Southerland', 'Nolan', 'Southerland', NULL::uuid, false, 'Film Editor', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Robbie Brody', 'Robbie', 'Brody', NULL::uuid, false, 'Administrative Law Judge', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Chris Yoosefi', 'Chris', 'Yoosefi', NULL::uuid, false, 'Small Business Owner', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Mike Van Gorder', 'Mike', 'Van Gorder', NULL::uuid, false, 'Housing Policy Analyst', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Hovanes Tonoyan', 'Hovanes', 'Tonoyan', NULL::uuid, false, 'Cyber Security Professional', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Council', 'Tamala Takahashi', 'Tamala', 'Takahashi', 'ea6f7109-6067-4a48-bbdf-2a8b9cffe05f'::uuid, true, 'Incumbent', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Baldwin Park City Council', 'Alejandra Avila', 'Alejandra', 'Avila', '5cf487ec-b383-466f-a5db-b01b607acd9c'::uuid, true, 'Councilmember', 'City of Baldwin Park, Certified List of Qualified Candidates, 8/13/2026 (baldwinpark.com/DocumentCenter/View/5174). Retrieved 2026-09-22.'),
    ('Baldwin Park City Council', 'Jean M. Ayala', 'Jean', 'Ayala', '493de696-aa12-4234-82db-8ec90619afa2'::uuid, true, 'Teacher/Vice Mayor', 'City of Baldwin Park, Certified List of Qualified Candidates, 8/13/2026 (baldwinpark.com/DocumentCenter/View/5174). Retrieved 2026-09-22.'),
    ('Baldwin Park City Council', 'Jeanette Cardoza', 'Jeanette', 'Cardoza', NULL::uuid, false, 'HR Professional/Mother', 'City of Baldwin Park, Certified List of Qualified Candidates, 8/13/2026 (baldwinpark.com/DocumentCenter/View/5174). Retrieved 2026-09-22.'),
    ('Lawndale Mayor', 'Robert Pullen-Miles', 'Robert', 'Pullen-Miles', '92ad78e2-845b-4fbf-9a58-01347b8c81db'::uuid, true, 'Mayor, City of Lawndale', 'City of Lawndale, Certified List of Qualified Candidates, approved 8/11/2026 (lawndale.ca.gov/.../2026 Election/Lawndale Certified List of Candidates Form_Online signed.pdf). Retrieved 2026-09-22.'),
    ('Lawndale Mayor', 'Francisco M. Talavera', 'Francisco', 'Talavera', 'c5384731-1bde-469b-b40a-4057f7ea4ae7'::uuid, false, 'Councilmember, City of Lawndale', 'City of Lawndale, Certified List of Qualified Candidates, approved 8/11/2026 (lawndale.ca.gov/.../2026 Election/Lawndale Certified List of Candidates Form_Online signed.pdf). Retrieved 2026-09-22.'),
    ('Monrovia Mayor', 'Becky A. Shevlin', 'Becky', 'Shevlin', 'd90648b6-f36e-4111-a361-ea34b34dd67d'::uuid, true, NULL, 'City of Monrovia City Clerk, November 3, 2026 General Municipal Election Qualified Candidates, 8/7/2026 (monroviaca.gov/home/showpublisheddocument/41152/639217168700800000). Retrieved 2026-09-22.')
  ) AS v(pos, full_name, first_name, last_name, pid, inc, desig, src)
  JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.pos
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name));

-- ─── 3. Antipartisan: clear the stored party on every linked candidate row ──────────
UPDATE essentials.politicians SET party = NULL
 WHERE party IS NOT NULL AND id IN ('0314141a-3444-4382-a9ae-84394bbd486f', '1bb7df04-db6e-447f-b358-3f12526eb32e', '3b4186ff-c161-4f7f-832e-b0faae340ed5', '4110139f-8a59-40fb-a10a-cad9a224bb80', '433cc087-78b2-4d09-b2d8-c15b5f202008', '493de696-aa12-4234-82db-8ec90619afa2', '5604c5ae-d10d-4ca3-920d-dd3592278777', '5b0b0edf-c2f2-4359-92d5-d245f8826111', '5cf487ec-b383-466f-a5db-b01b607acd9c', '5e8bcf17-3a4d-4614-a71c-c4ea8396f7cb', '8247e088-2ac8-4ae1-bac9-ff537dd27fec', '90b0fc60-30ca-4388-92b0-ff5dd2b443cb', '92ad78e2-845b-4fbf-9a58-01347b8c81db', '96f91743-def6-436c-9537-a4b836c1b3eb', 'a3aac8fc-d8cb-4cb7-b6be-e5b0fa97c15a', 'c5384731-1bde-469b-b40a-4057f7ea4ae7', 'd90648b6-f36e-4111-a361-ea34b34dd67d', 'de2ca46a-652a-4620-bfc7-8ff1006b26d3', 'e109a1be-eff6-4982-af5a-ac1923f43f10', 'ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'fc64110f-80f5-43a8-b5c2-f814219024fc');

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  pos text[] := ARRAY['Santa Monica City Council', 'Culver City City Council', 'West Hollywood City Council', 'Manhattan Beach City Council', 'Norwalk City Council', 'Lynwood City Council', 'Cudahy City Council', 'Hawthorne City Council', 'South Gate City Council', 'Burbank City Council', 'Baldwin Park City Council', 'Lawndale Mayor', 'Monrovia Mayor'];
  n_races int; n_cands int; n_null int; n_party int; n_badcount int; n_inc int; n_badinc int; n_extralink int; n_linked int;
  n_overinc int; n_unreach int; n_pparty int;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE r.office_id IS NULL), count(*) FILTER (WHERE r.primary_party IS NOT NULL)
    INTO n_races, n_null, n_party FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  SELECT count(*) INTO n_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  -- each race carries exactly the clerk's field, on the expected seat count
  SELECT count(*) INTO n_badcount FROM (VALUES
      ('Santa Monica City Council', 3, 12, 2),
      ('Culver City City Council', 2, 5, 1),
      ('West Hollywood City Council', 3, 14, 1),
      ('Manhattan Beach City Council', 2, 4, 1),
      ('Norwalk City Council', 2, 6, 1),
      ('Lynwood City Council', 3, 6, 3),
      ('Cudahy City Council', 3, 5, 1),
      ('Hawthorne City Council', 2, 3, 2),
      ('South Gate City Council', 2, 5, 2),
      ('Burbank City Council', 3, 13, 2),
      ('Baldwin Park City Council', 2, 3, 2),
      ('Lawndale Mayor', 1, 2, 1),
      ('Monrovia Mayor', 1, 1, 1)
    ) AS v(pos, seats, n_cand, n_inc)
    LEFT JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.pos
   WHERE r.id IS NULL OR r.seats <> v.seats
      OR (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id) <> v.n_cand
      OR (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.is_incumbent) <> v.n_inc;
  -- every incumbent is linked, and EVERY linked candidate (incumbent, or a sitting official running for
  -- another seat) is a CURRENT holder of an office in the same city (any district whose geo_id is the place)
  SELECT count(*) FILTER (WHERE rc.is_incumbent),
         count(*) FILTER (WHERE rc.is_incumbent AND rc.politician_id IS NULL),
         count(*) FILTER (WHERE rc.politician_id IS NOT NULL AND NOT EXISTS (
           SELECT 1 FROM essentials.office_current_holder och JOIN essentials.offices o2 ON o2.id = och.office_id
             JOIN essentials.districts d2 ON d2.id = o2.district_id
            WHERE och.politician_id = rc.politician_id
              AND d2.geo_id = (SELECT d.geo_id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE o.id = r.office_id))),
         count(*) FILTER (WHERE rc.politician_id IS NOT NULL)
    INTO n_inc, n_badinc, n_extralink, n_linked
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  SELECT count(*) INTO n_overinc FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos)
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.is_incumbent) > r.seats;
  -- END TO END: an interior point of each race's own polygon reaches that race
  SELECT count(*) INTO n_unreach FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.geofence_boundaries me ON me.geo_id = d.geo_id AND me.mtfcc = d.mtfcc
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos)
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND (d.mtfcc IS NULL OR gb.mtfcc = d.mtfcc)
                        AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(me.geometry)));
  SELECT count(*) INTO n_pparty FROM essentials.politicians p WHERE p.party IS NOT NULL AND p.id IN (
    SELECT rc.politician_id FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
     WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos) AND rc.politician_id IS NOT NULL);
  IF n_races <> 13 THEN RAISE EXCEPTION 'expected 13 races, got %', n_races; END IF;
  IF n_cands <> 79 THEN RAISE EXCEPTION 'expected 79 candidates, got %', n_cands; END IF;
  IF n_null <> 0 OR n_party <> 0 THEN RAISE EXCEPTION 'office-less (%) or partisan (%) race', n_null, n_party; END IF;
  IF n_badcount <> 0 THEN RAISE EXCEPTION '% race(s) whose seats / candidates / incumbents differ from the clerk list', n_badcount; END IF;
  IF n_inc <> 20 THEN RAISE EXCEPTION 'expected 20 incumbents, got %', n_inc; END IF;
  IF n_badinc <> 0 THEN RAISE EXCEPTION '% incumbent(s) left unlinked', n_badinc; END IF;
  IF n_extralink <> 0 THEN RAISE EXCEPTION '% linked candidate(s) are not a current holder in their city', n_extralink; END IF;
  IF n_linked <> 21 THEN RAISE EXCEPTION 'expected 21 linked candidates, got %', n_linked; END IF;
  IF n_overinc <> 0 THEN RAISE EXCEPTION '% race(s) with more incumbents than seats', n_overinc; END IF;
  IF n_unreach <> 0 THEN RAISE EXCEPTION '% race(s) not reached from inside their own city', n_unreach; END IF;
  IF n_pparty <> 0 THEN RAISE EXCEPTION '% linked candidate row(s) still carry a party', n_pparty; END IF;
  RAISE NOTICE 'CA_0160 applied: % races, % candidates, % incumbents linked', n_races, n_cands, n_inc;
END $$;

COMMIT;
