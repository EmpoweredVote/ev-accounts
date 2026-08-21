-- 1848_co_2026_general_races.sql
-- Colorado 2026 general election: the ballot a Colorado Springs voter actually receives.
--
-- Extends the existing 'CO 2026 Statewide General' election (2026-11-03), which until now
-- held ONLY the 8 U.S. House races and U.S. Senate, and held them incompletely.
--
-- ADDS 17 RACES / 56 CANDIDATES:
--   5   statewide executive  Governor, Lt. Governor, Attorney General, Secretary of State,
--                            Treasurer
--   3   State Senate         SD 9, 11, 35 -- the only Colorado Springs-area Senate seats on
--                            the 2026 ballot. SD 10 and SD 12 are mid-term and are NOT up;
--                            Colorado's Senate is staggered, 21 of 35 seats this cycle.
--   9   State House          HD 14, 15, 16, 17, 18, 20, 21, 22, 56 -- every House district
--                            that overlaps Colorado Springs. All 65 House seats are up
--                            statewide; only these nine reach a Colorado Springs ballot.
-- ...and TOPS UP the 9 existing federal races with 27 candidates they were missing.
--
-- 🔴 THE EXISTING FEDERAL RACES WERE INCOMPLETE. They were seeded from Wikipedia, which
-- carried only the major-party field: 16 U.S. House candidates where the state lists 38,
-- and 4 for U.S. Senate where the state lists 9. Every missing one is a minor-party or
-- unaffiliated candidate. Publishing a two-name race for a five-name ballot is a false
-- statement about the ballot, so this fixes it from the state's own list.
--
-- SOURCE. The Colorado Secretary of State's own general-election candidate list. The
-- 2026-06-30 primary is decided, so this is the general field, not a primary field.
--
-- ⚠ THE SOURCE CALLS ITSELF UNOFFICIAL and that word is kept in the source string. The
-- county ballot-certification deadline has not passed, so the list can still move. It is
-- nonetheless the state's own list and strictly better than the news-derived field it
-- replaces. Re-check before treating any of this as final.
--
-- ⚠ THE FILE IS BEHIND A WAF. A plain fetch returns HTTP 403 with a Cloudflare challenge
-- page, browser headers and a Referer included. It has to be pulled through a real browser
-- session. A naive scraper will "succeed" with 4.5 KB of HTML that is not a spreadsheet.
--
-- WRITE-IN CANDIDATES ARE NOT ON THE PRINTED BALLOT. 10 of these are certified
-- write-ins. They are real -- a vote for them counts -- but listing them alongside printed
-- candidates would misrepresent the ballot, so they carry candidate_status='filed' while
-- printed candidates carry 'active'. Colorado Springs is directly affected: CD-5's Steven
-- Fuller, HD 16's Isaac Contreras and HD 17's Sherrea Sterling are all write-ins.
--
-- PARTY IS DELIBERATELY NOT STORED PER CANDIDATE. race_candidates has no party column and
-- must not gain one: party lives on races.primary_party, which records WHICH BALLOT A VOTER
-- REQUESTS. This is a general election, so primary_party is NULL for every race here. The
-- SoS list carries party for all 56 candidates and it is discarded on purpose.
--
-- INCUMBENT LINKING IS BY SEAT, NOT BY NAME SEARCH. A candidate is linked to a politician
-- row ONLY when they are the current holder of that exact seat, matched on surname plus
-- forename initial against the holder we already seated. Challengers are left with
-- politician_id NULL rather than guessed at -- name matching fails on real people, and a
-- wrong link attaches one person's record to another's candidacy.
--
-- INCUMBENTS NOT SEEKING THE SEAT (all verified against the list, none is an error):
--   Polis, Primavera        term-limited
--   Phil Weiser (AG)        running for GOVERNOR
--   Jena Griswold (SoS)     running for ATTORNEY GENERAL
--   Dave Young (Treasurer)  not on the ballot
--   Lynda Zamora Wilson SD 9, Scott Bottoms HD 15, Rebecca Keltie HD 16, Mary Bradfield HD 21
-- Michael J. Allen, the El Paso County District Attorney seated in 1846, appears here as the
-- Republican candidate for Attorney General. Jeff Bridges, the SD 26 senator seated in 1844,
-- appears as the Democratic candidate for Treasurer. Neither is linked: they are candidates
-- for a DIFFERENT office than the one they hold, and race_candidates.politician_id linking
-- here is reserved for the incumbent OF THIS SEAT.
--
-- HD 20 HAS EXACTLY ONE CANDIDATE. Jarvis Caldwell is unopposed. That is what the state
-- lists; a one-candidate race is not a truncated import.
--
-- EL PASO COUNTY RACES ARE NOT HERE. Commissioner districts 1 and 5 plus the county row
-- offices are on the 2026 ballot, but the county has not certified its candidate list --
-- clerkandrecorder.elpasoco.com publishes no 2026 candidate document as of 2026-08-21.
-- Seeding empty race shells would show a voter an office with no candidates, so they wait.
--
-- IDEMPOTENCY: races guard on (election_id, position_name); candidates on
-- (race_id, full_name). Neither has a unique index, so NOT EXISTS, never ON CONFLICT.

BEGIN;

CREATE TEMP TABLE co_race_seed (
  seat text, position_name text, district_type text, mtfcc text, geo_id text,
  office_title text, exec_district text
) ON COMMIT DROP;
INSERT INTO co_race_seed VALUES
  ('X:Governor', 'Colorado Governor', 'STATE_EXEC', NULL, NULL, 'Governor', 'Colorado Governor'),
  ('X:Lieutenant Governor', 'Colorado Lieutenant Governor', 'STATE_EXEC', NULL, NULL, 'Lieutenant Governor', 'Colorado Lieutenant Governor'),
  ('X:Attorney General', 'Colorado Attorney General', 'STATE_EXEC', NULL, NULL, 'Attorney General', 'Colorado Attorney General'),
  ('X:Secretary of State', 'Colorado Secretary of State', 'STATE_EXEC', NULL, NULL, 'Secretary of State', 'Colorado Secretary of State'),
  ('X:Treasurer', 'Colorado Treasurer', 'STATE_EXEC', NULL, NULL, 'Treasurer', 'Colorado Treasurer'),
  ('S9', 'State Senator District 9', 'STATE_UPPER', 'G5210', '08009', 'State Senator', NULL),
  ('S11', 'State Senator District 11', 'STATE_UPPER', 'G5210', '08011', 'State Senator', NULL),
  ('S35', 'State Senator District 35', 'STATE_UPPER', 'G5210', '08035', 'State Senator', NULL),
  ('H14', 'State Representative District 14', 'STATE_LOWER', 'G5220', '08014', 'State Representative', NULL),
  ('H15', 'State Representative District 15', 'STATE_LOWER', 'G5220', '08015', 'State Representative', NULL),
  ('H16', 'State Representative District 16', 'STATE_LOWER', 'G5220', '08016', 'State Representative', NULL),
  ('H17', 'State Representative District 17', 'STATE_LOWER', 'G5220', '08017', 'State Representative', NULL),
  ('H18', 'State Representative District 18', 'STATE_LOWER', 'G5220', '08018', 'State Representative', NULL),
  ('H20', 'State Representative District 20', 'STATE_LOWER', 'G5220', '08020', 'State Representative', NULL),
  ('H21', 'State Representative District 21', 'STATE_LOWER', 'G5220', '08021', 'State Representative', NULL),
  ('H22', 'State Representative District 22', 'STATE_LOWER', 'G5220', '08022', 'State Representative', NULL),
  ('H56', 'State Representative District 56', 'STATE_LOWER', 'G5220', '08056', 'State Representative', NULL);

CREATE TEMP TABLE co_cand_seed (
  seat text, position_name text, full_name text, first_name text, last_name text,
  is_incumbent boolean, candidate_status text, politician_id uuid
) ON COMMIT DROP;
INSERT INTO co_cand_seed VALUES
  ('X:Governor', 'Colorado Governor', 'Victor Marx', 'Victor', 'Marx', false, 'active', NULL::uuid),
  ('X:Governor', 'Colorado Governor', 'Phil Weiser', 'Phil', 'Weiser', false, 'active', NULL::uuid),
  ('X:Governor', 'Colorado Governor', 'Stephen T. Hamilton', 'Stephen', 'Hamilton', false, 'active', NULL::uuid),
  ('X:Governor', 'Colorado Governor', 'Eric Mulder', 'Eric', 'Mulder', false, 'active', NULL::uuid),
  ('X:Governor', 'Colorado Governor', 'Jeff Peckman', 'Jeff', 'Peckman', false, 'active', NULL::uuid),
  ('X:Governor', 'Colorado Governor', 'Erik Underwood', 'Erik', 'Underwood', false, 'active', NULL::uuid),
  ('X:Governor', 'Colorado Governor', 'Greg Lopez', 'Greg', 'Lopez', false, 'active', NULL::uuid),
  ('X:Lieutenant Governor', 'Colorado Lieutenant Governor', 'George Washington Markert', 'George', 'Markert', false, 'active', NULL::uuid),
  ('X:Lieutenant Governor', 'Colorado Lieutenant Governor', 'Lesley Dahlkemper', 'Lesley', 'Dahlkemper', false, 'active', NULL::uuid),
  ('X:Lieutenant Governor', 'Colorado Lieutenant Governor', 'James K Treibert', 'James', 'Treibert', false, 'active', NULL::uuid),
  ('X:Lieutenant Governor', 'Colorado Lieutenant Governor', 'Wayne Harlos', 'Wayne', 'Harlos', false, 'active', NULL::uuid),
  ('X:Lieutenant Governor', 'Colorado Lieutenant Governor', 'T.J. Cole', 'T.J.', 'Cole', false, 'active', NULL::uuid),
  ('X:Lieutenant Governor', 'Colorado Lieutenant Governor', 'Frank Atwood', 'Frank', 'Atwood', false, 'active', NULL::uuid),
  ('X:Lieutenant Governor', 'Colorado Lieutenant Governor', 'Taralyn Romero', 'Taralyn', 'Romero', false, 'active', NULL::uuid),
  ('X:Attorney General', 'Colorado Attorney General', 'Michael J. Allen', 'Michael', 'Allen', false, 'active', NULL::uuid),
  ('X:Attorney General', 'Colorado Attorney General', 'Jena Griswold', 'Jena', 'Griswold', false, 'active', NULL::uuid),
  ('X:Secretary of State', 'Colorado Secretary of State', 'Amanda Gonzalez', 'Amanda', 'Gonzalez', false, 'active', NULL::uuid),
  ('X:Secretary of State', 'Colorado Secretary of State', 'James Wiley', 'James', 'Wiley', false, 'active', NULL::uuid),
  ('X:Secretary of State', 'Colorado Secretary of State', 'Alex Astley', 'Alex', 'Astley', false, 'active', NULL::uuid),
  ('X:Secretary of State', 'Colorado Secretary of State', 'Amanda Campbell', 'Amanda', 'Campbell', false, 'active', NULL::uuid),
  ('X:Secretary of State', 'Colorado Secretary of State', 'Celeste Landry', 'Celeste', 'Landry', false, 'active', NULL::uuid),
  ('X:Treasurer', 'Colorado Treasurer', 'Jeff Bridges', 'Jeff', 'Bridges', false, 'active', NULL::uuid),
  ('X:Treasurer', 'Colorado Treasurer', 'Kevin Grantham', 'Kevin', 'Grantham', false, 'active', NULL::uuid),
  ('X:Treasurer', 'Colorado Treasurer', 'Jodie Barr', 'Jodie', 'Barr', false, 'active', NULL::uuid),
  ('X:Treasurer', 'Colorado Treasurer', 'Marilee Langner Sturgis', 'Marilee', 'Sturgis', false, 'active', NULL::uuid),
  ('S9', 'State Senator District 9', 'Terri Carver', 'Terri', 'Carver', false, 'active', NULL::uuid),
  ('S9', 'State Senator District 9', 'William Delano Moses III', 'William', 'Moses III', false, 'active', NULL::uuid),
  ('S11', 'State Senator District 11', 'Tony Exum Sr', 'Tony', 'Exum Sr', true, 'active', '92fbd4c0-34a6-4561-8916-fb56f5096ad0'::uuid),
  ('S11', 'State Senator District 11', 'Levon Stilson', 'Levon', 'Stilson', false, 'active', NULL::uuid),
  ('S11', 'State Senator District 11', 'Janet Turner', 'Janet', 'Turner', false, 'active', NULL::uuid),
  ('S35', 'State Senator District 35', 'Rod Pelton', 'Rod', 'Pelton', true, 'active', '543138e3-02f3-4926-bdf6-0cd126f63c2b'::uuid),
  ('S35', 'State Senator District 35', 'Duane L Gurule', 'Duane', 'Gurule', false, 'active', NULL::uuid),
  ('S35', 'State Senator District 35', 'Richard Graf', 'Richard', 'Graf', false, 'active', NULL::uuid),
  ('S35', 'State Senator District 35', 'Travis Star Nelson', 'Travis', 'Nelson', false, 'active', NULL::uuid),
  ('H14', 'State Representative District 14', 'Ava Flanell', 'Ava', 'Flanell', true, 'active', '09938d3a-c60f-4096-a217-4efdc3a604b1'::uuid),
  ('H14', 'State Representative District 14', 'Sarah Emery', 'Sarah', 'Emery', false, 'active', NULL::uuid),
  ('H15', 'State Representative District 15', 'Jeff K. Livingston', 'Jeff', 'Livingston', false, 'active', NULL::uuid),
  ('H15', 'State Representative District 15', 'Pricella Tiegen', 'Pricella', 'Tiegen', false, 'active', NULL::uuid),
  ('H15', 'State Representative District 15', 'Doug Jones', 'Doug', 'Jones', false, 'active', NULL::uuid),
  ('H16', 'State Representative District 16', 'Jill Haffley', 'Jill', 'Haffley', false, 'active', NULL::uuid),
  ('H16', 'State Representative District 16', 'Steph Vigil', 'Steph', 'Vigil', false, 'active', NULL::uuid),
  ('H16', 'State Representative District 16', 'John C Hjersman', 'John', 'Hjersman', false, 'active', NULL::uuid),
  ('H16', 'State Representative District 16', 'Isaac Contreras', 'Isaac', 'Contreras', false, 'filed', NULL::uuid),
  ('H17', 'State Representative District 17', 'Regina English', 'Regina', 'English', true, 'active', '50a9c77a-3089-4ea6-b3f8-021b5a204e37'::uuid),
  ('H17', 'State Representative District 17', 'Laura Martin', 'Laura', 'Martin', false, 'active', NULL::uuid),
  ('H17', 'State Representative District 17', 'John Michael Angle', 'John', 'Angle', false, 'active', NULL::uuid),
  ('H17', 'State Representative District 17', 'Sherrea Sterling', 'Sherrea', 'Sterling', false, 'filed', NULL::uuid),
  ('H18', 'State Representative District 18', 'Amy T Paschal', 'Amy', 'Paschal', true, 'active', '8b032c7b-415f-4a7d-90fe-6b4017092c67'::uuid),
  ('H18', 'State Representative District 18', 'Adriana Cuva', 'Adriana', 'Cuva', false, 'active', NULL::uuid),
  ('H20', 'State Representative District 20', 'Jarvis Caldwell', 'Jarvis', 'Caldwell', true, 'active', '2f0cf2a3-d80a-40cb-b89a-3c4a61f4f777'::uuid),
  ('H21', 'State Representative District 21', 'Brenda Miller', 'Brenda', 'Miller', false, 'active', NULL::uuid),
  ('H21', 'State Representative District 21', 'Michelle Tweed', 'Michelle', 'Tweed', false, 'active', NULL::uuid),
  ('H22', 'State Representative District 22', 'Michael Pierson', 'Michael', 'Pierson', false, 'active', NULL::uuid),
  ('H22', 'State Representative District 22', 'Ken deGraaf', 'Ken', 'deGraaf', true, 'active', 'e6ff0305-e3a8-4cd3-bd4c-2941fc094c78'::uuid),
  ('H56', 'State Representative District 56', 'Chris Richardson', 'Chris', 'Richardson', true, 'active', 'd221a252-f3f9-44d5-93ba-2d26771efd66'::uuid),
  ('H56', 'State Representative District 56', 'Amy L. Lunde', 'Amy', 'Lunde', false, 'active', NULL::uuid);

CREATE TEMP TABLE co_fed_topup (
  race_id uuid, full_name text, first_name text, last_name text, candidate_status text
) ON COMMIT DROP;
INSERT INTO co_fed_topup VALUES
  ('75218390-3c57-4427-a984-8f41f6ba25a0'::uuid, 'Christopher Baum', 'Christopher', 'Baum', 'active'),
  ('75218390-3c57-4427-a984-8f41f6ba25a0'::uuid, 'Blake Huber', 'Blake', 'Huber', 'active'),
  ('75218390-3c57-4427-a984-8f41f6ba25a0'::uuid, 'Donald Willoughby', 'Donald', 'Willoughby', 'filed'),
  ('75218390-3c57-4427-a984-8f41f6ba25a0'::uuid, 'Will Powers', 'Will', 'Powers', 'filed'),
  ('75218390-3c57-4427-a984-8f41f6ba25a0'::uuid, 'Ryan Apelbaum', 'Ryan', 'Apelbaum', 'filed'),
  ('16745bfe-3b25-471e-9556-3fd3ba0e12d6'::uuid, 'Critter Milton', 'Critter', 'Milton', 'active'),
  ('16745bfe-3b25-471e-9556-3fd3ba0e12d6'::uuid, 'Chad Humphrey', 'Chad', 'Humphrey', 'active'),
  ('16745bfe-3b25-471e-9556-3fd3ba0e12d6'::uuid, 'Shimon Blau', 'Shimon', 'Blau', 'active'),
  ('16745bfe-3b25-471e-9556-3fd3ba0e12d6'::uuid, 'Kevin StClair', 'Kevin', 'StClair', 'filed'),
  ('16745bfe-3b25-471e-9556-3fd3ba0e12d6'::uuid, 'John Wren', 'John', 'Wren', 'filed'),
  ('16745bfe-3b25-471e-9556-3fd3ba0e12d6'::uuid, 'Stephen Replin', 'Stephen', 'Replin', 'filed'),
  ('8db96b05-62b6-4ce6-b83a-490d5681d5f2'::uuid, 'Gaylon Kent', 'Gaylon', 'Kent', 'active'),
  ('ce19d3f5-742e-4c5e-8fa6-a12dda3c4c57'::uuid, 'Cory Robertson', 'Cory', 'Robertson', 'active'),
  ('ce19d3f5-742e-4c5e-8fa6-a12dda3c4c57'::uuid, 'Clifton Brown', 'Clifton', 'Brown', 'active'),
  ('f2a99107-c9b6-4201-8b2c-6548d5969fe1'::uuid, 'Douglas Mangeris', 'Douglas', 'Mangeris', 'active'),
  ('f2a99107-c9b6-4201-8b2c-6548d5969fe1'::uuid, 'Luis Galvan', 'Luis', 'Galvan', 'filed'),
  ('9973aa26-88fd-417c-8332-dee3923caa59'::uuid, 'Christopher Mitchell', 'Christopher', 'Mitchell', 'active'),
  ('9973aa26-88fd-417c-8332-dee3923caa59'::uuid, 'Mark "Marky Jr" Elworth', 'Mark', 'Elworth', 'active'),
  ('9973aa26-88fd-417c-8332-dee3923caa59'::uuid, 'Steven Fuller', 'Steven', 'Fuller', 'filed'),
  ('66014b5d-488a-4952-802d-64d863e6b5f5'::uuid, 'Patty McMahon', 'Patty', 'McMahon', 'active'),
  ('66014b5d-488a-4952-802d-64d863e6b5f5'::uuid, 'Meredith Ryan', 'Meredith', 'Ryan', 'active'),
  ('66014b5d-488a-4952-802d-64d863e6b5f5'::uuid, 'Samir Ezzeldin Witta', 'Samir', 'Witta', 'active'),
  ('344ac3ce-9414-42ac-91b7-da2282c694b6'::uuid, 'Susan Hall', 'Susan', 'Hall', 'active'),
  ('344ac3ce-9414-42ac-91b7-da2282c694b6'::uuid, 'Lawrence Kyle Clark', 'Lawrence', 'Clark', 'active'),
  ('344ac3ce-9414-42ac-91b7-da2282c694b6'::uuid, 'Dan "Kilo" Sallis', 'Dan', 'Sallis', 'active'),
  ('344ac3ce-9414-42ac-91b7-da2282c694b6'::uuid, 'Joe Krzeczkowski', 'Joe', 'Krzeczkowski', 'active'),
  ('c29b675f-8d49-422f-9c5e-db7477d8f453'::uuid, 'Dave Wood', 'Dave', 'Wood', 'active');

-- ─── Races ───────────────────────────────────────────────────────────────────
-- primary_party is NULL throughout: this is a GENERAL election, and that column
-- records which primary ballot a voter requests, not a candidate's affiliation.

INSERT INTO essentials.races (election_id, office_id, position_name, seats)
SELECT 'ae041272-78b1-4840-862c-797118b79afe'::uuid, o.id, s.position_name, 1
FROM co_race_seed s
JOIN essentials.districts d
  ON ( (s.geo_id IS NOT NULL AND d.geo_id = s.geo_id AND d.district_type = s.district_type AND d.mtfcc = s.mtfcc)
    OR (s.exec_district IS NOT NULL AND d.label = s.exec_district AND d.district_type = 'STATE_EXEC') )
 AND d.state ILIKE 'co'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.office_title
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id = 'ae041272-78b1-4840-862c-797118b79afe'::uuid
    AND r.position_name = s.position_name
);

-- ─── Candidates on the new races ─────────────────────────────────────────────

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name,
       cs.is_incumbent, cs.candidate_status, 'Colorado Secretary of State, 2026 General Election Unofficial Candidate List (sos.state.co.us/pubs/elections/vote/files/2026/2026GeneralCandidateListUnofficial.xlsx), updated 2026-08-20, retrieved 2026-08-21.'
FROM co_cand_seed cs
JOIN essentials.races r
  ON r.election_id = 'ae041272-78b1-4840-862c-797118b79afe'::uuid
 AND r.position_name = cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(cs.full_name)
);

-- ─── Federal top-up ──────────────────────────────────────────────────────────

INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT t.race_id, t.full_name, t.first_name, t.last_name, false, t.candidate_status, 'Colorado Secretary of State, 2026 General Election Unofficial Candidate List (sos.state.co.us/pubs/elections/vote/files/2026/2026GeneralCandidateListUnofficial.xlsx), updated 2026-08-20, retrieved 2026-08-21.'
FROM co_fed_topup t
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = t.race_id AND lower(rc.full_name) = lower(t.full_name)
);

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE v_races int; v_new int; v_orphan int; v_fed int; v_dup int;
BEGIN
  SELECT count(*) INTO v_races FROM essentials.races
   WHERE election_id = 'ae041272-78b1-4840-862c-797118b79afe'::uuid;

  SELECT count(*) INTO v_new
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN co_cand_seed cs ON cs.position_name = r.position_name AND lower(cs.full_name) = lower(rc.full_name)
   WHERE r.election_id = 'ae041272-78b1-4840-862c-797118b79afe'::uuid;

  -- 🔴 A race with a NULL office_id never resolves to a district and is invisible
  -- to address-based elections lookup. Never allow one.
  SELECT count(*) INTO v_orphan FROM essentials.races
   WHERE election_id = 'ae041272-78b1-4840-862c-797118b79afe'::uuid AND office_id IS NULL;

  SELECT count(*) INTO v_fed
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'ae041272-78b1-4840-862c-797118b79afe'::uuid
     AND (r.position_name LIKE 'U.S.%');

  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n
      FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
     WHERE r.election_id = 'ae041272-78b1-4840-862c-797118b79afe'::uuid
     GROUP BY 1,2 HAVING count(*) > 1) x;

  IF v_races <> 26 THEN RAISE EXCEPTION 'CO 2026 races: expected 26, got %', v_races; END IF;
  IF v_new <> 56 THEN RAISE EXCEPTION 'new race candidates: expected 56, got %', v_new; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% race(s) with NULL office_id — invisible to address lookup', v_orphan; END IF;
  IF v_fed <> 47 THEN RAISE EXCEPTION 'federal candidates after top-up: expected 47 (38 US House + 9 US Senate), got %', v_fed; END IF;
  IF v_dup <> 0 THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
END $$;

COMMIT;
