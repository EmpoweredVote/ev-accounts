-- CC_0170_ms_legislature_incumbents.sql
-- Knight Foundation program, wave MS-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0169, which creates the 2 chambers and the 174 offices.
--
-- Seats all 174 members of the Mississippi Legislature: 52 senators and 122 representatives.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE ROSTER CAME FROM THE MEMBER PAGES, NOT FROM THE LEGISLATURE'S OWN MEMBER LIST, AND
-- THAT IS THE INVERSE OF EVERY EARLIER WAVE. MN-2 and MI-2 both had a fresh-looking list that had
-- not noticed a departure. Mississippi's lists are the STALE documents and only Last-Modified
-- could say so:
--     ss_membs.xml  last modified 2025-07-01
--     hr_membs.xml  last modified 2025-10-14
-- Both PREDATE the court-ordered special elections of 2025-11-04, while individual member pages
-- are current to 2026-08-18. The Senate list therefore still declares "Vacancy - District 24" and
-- "Vacancy - District 26" -- both filled since -- and still carries John Polk, who retired.
-- ▶ A DOCUMENT'S CONTENT CANNOT TELL YOU ITS AGE; ASK THE SERVER. Justin Pope's page looks exactly
--   like a sitting member's (six committees, a capitol phone, "2026-present") because he IS one.
-- ⚠ AND A PAGE EXISTING IS NOT MEMBERSHIP: senate/polk.xml resolves HTTP 200 with full detail.
-- ⚠ AND STALENESS IS NOT DEPARTURE: 13 of 170 pages predate the specials and most are sitting
--   members in districts the remedy never touched. A page is only edited when something changes.
--
-- 🟢 EIGHT SEATS TURNED OVER SINCE THE LIST, EACH ESTABLISHED BY TWO INDEPENDENT HALVES --
-- the list holder's page predates the specials, AND Open States names a different surname in that
-- district and that person nowhere in the chamber -- after which the successor's own page had to
-- carry the expected <DISTRICT>:
--     Senate  2   David Parker            -> Theresa Gillespie-Isom
--     Senate 24   (list said VACANT)      -> Justin L. Pope
--     Senate 26   (list said VACANT)      -> Kamesha B. Mumford
--     Senate 42   Robin Robinson          -> Don Hartness
--     Senate 44   John A. Polk (retired)  -> Chris Johnson
--     Senate 45   (absent from the list)  -> Johnny L. DuPree
--     House  22   Jonathan Ray Lancaster  -> Justin Crosby
--     House  26   Orlando Paden           -> Otha Williams
-- 🟢 AND THE ARITHMETIC CLOSES WITHOUT SLACK, which is the real control: 52 and 122 exactly.
--
-- 🔴 A NICKNAME IS NOT A DIFFERENT PERSON, AND TWELVE OF THEM WOULD HAVE HIDDEN THESE EIGHT.
-- Open States writes the name people use and the Legislature writes the name on the roll:
-- Chuck/Charles Younger, Bubba/Joseph Tubb, Hank/Henry Zuber, Zack/Zachary Grady, Bubba/Lester
-- Carpenter, Jeff/Jeffrey Guice, Greg/Gregory Holloway, Sam/Samuel Creekmore. None is a prefix
-- rule -- "Bubba" is not short for "Lester" -- so only the SURNAME can carry that test. Every one
-- of the eight turnovers above is a surname change.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 SEVEN TERMS ARE DATED AT YEAR PRECISION AND 167 ARE OPEN-ENDED AT 'unknown'. No Mississippi
-- member page publishes an arrival DATE, and the oath date must not be computed. What the pages
-- do publish is <LEG_EXP><STRETCH>. For the seven members whose only stretch is "2026-present"
-- that is the body's own statement that their service began in 2026, written as 2026-01-01 at
-- 'year' precision. For everyone else a stretch is a CAREER, not a SEAT.
-- 🔴 CHRIS JOHNSON IS THE COUNTER-EXAMPLE AND HE IS IN THIS WAVE. His page reads "2020-present"
-- and "House 2016-2019", but he moved from Senate District 45 to Senate District 44 in 2026, so
-- dating SD-44 from his stretch would assert he held that seat from 2020 -- six years during which
-- John Polk actually held it. office_terms is a SEAT, not a career (MI-4, where two commissioners
-- were dated to the year they CHANGED DISTRICT NUMBER). He is written 'unknown', deliberately.
--
-- 🔴 EVERY politicians INSERT NAMES is_incumbent EXPLICITLY. It defaults to false since CA_0188,
-- and a seated person inserted without it is hidden from address search.
--
-- 🔴 PARTY IS NOT WRITTEN. The member pages carry <PARTY>; party lives on races.primary_party in
-- this schema, never on a person or an office.
--
-- 🔴 external_id BAND -2766400 .. -2766227 (174 ids). The band ACTUALLY USED was re-checked
-- against production on 2026-09-28 and holds 0 rows; the adjacent -2766200..-2766000 holds 1.
-- ND-2's rule: check the band you use, not a neighbouring one.

BEGIN;

-- ─── 1. The 170 people whose name collides with nobody ─────────────────────────────

CREATE TEMP TABLE ms_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ms_people(external_id, full_name, first_name, last_name) VALUES
  (-2766400::bigint, 'Michael McLendon', 'Michael', 'McLendon'),
  (-2766399::bigint, 'Theresa Gillespie-Isom', 'Theresa', 'Gillespie-Isom'),
  (-2766398::bigint, 'Kathy L. Chism', 'Kathy', 'Chism'),
  (-2766397::bigint, 'Rita Potts Parks', 'Rita', 'Parks'),
  (-2766396::bigint, 'Daniel H. Sparks', 'Daniel', 'Sparks'),
  (-2766395::bigint, 'Chad McMahan', 'Chad', 'McMahan'),
  (-2766394::bigint, 'Hob Bryan', 'Hob', 'Bryan'),
  (-2766393::bigint, 'Benjamin Suber', 'Benjamin', 'Suber'),
  (-2766392::bigint, 'Nicole Boyd', 'Nicole', 'Boyd'),
  (-2766391::bigint, 'Neil S. Whaley', 'Neil', 'Whaley'),
  (-2766390::bigint, 'Reginald Jackson', 'Reginald', 'Jackson'),
  (-2766389::bigint, 'Derrick T. Simmons', 'Derrick', 'Simmons'),
  (-2766388::bigint, 'Sarita Simmons', 'Sarita', 'Simmons'),
  (-2766387::bigint, 'Lydia Graves Chassaniol', 'Lydia', 'Chassaniol'),
  (-2766386::bigint, 'Bart Williams', 'Bart', 'Williams'),
  (-2766385::bigint, 'Angela Turner Ford', 'Angela', 'Turner Ford'),
  (-2766384::bigint, 'Charles Younger', 'Charles', 'Younger'),
  (-2766383::bigint, 'Lane Taylor', 'Lane', 'Taylor'),
  (-2766382::bigint, 'Kevin Blackwell', 'Kevin', 'Blackwell'),
  (-2766381::bigint, 'Josh Harkins', 'Josh', 'Harkins'),
  (-2766380::bigint, 'Bradford Blackmon', 'Bradford', 'Blackmon'),
  (-2766379::bigint, 'Joseph Thomas', 'Joseph', 'Thomas'),
  (-2766378::bigint, 'W. Briggs Hopson III', 'W.', 'Hopson'),
  (-2766377::bigint, 'Justin L. Pope', 'Justin', 'Pope'),
  (-2766376::bigint, 'J. Walter Michel', 'J.', 'Michel'),
  (-2766375::bigint, 'Kamesha B. Mumford', 'Kamesha', 'Mumford'),
  (-2766374::bigint, 'Hillman Terome Frazier', 'Hillman', 'Frazier'),
  (-2766373::bigint, 'Sollie B. Norwood', 'Sollie', 'Norwood'),
  (-2766372::bigint, 'David Blount', 'David', 'Blount'),
  (-2766371::bigint, 'Dean Kirby', 'Dean', 'Kirby'),
  (-2766370::bigint, 'Tyler McCaughn', 'Tyler', 'McCaughn'),
  (-2766369::bigint, 'Rod Hickman', 'Rod', 'Hickman'),
  (-2766368::bigint, 'Jeff Tate', 'Jeff', 'Tate'),
  (-2766367::bigint, 'Juan Barnett', 'Juan', 'Barnett'),
  (-2766366::bigint, 'Andy Berry', 'Andy', 'Berry'),
  (-2766365::bigint, 'Brian Rhodes', 'Brian', 'Rhodes'),
  (-2766364::bigint, 'Albert Butler', 'Albert', 'Butler'),
  (-2766363::bigint, 'Gary Brumfield', 'Gary', 'Brumfield'),
  (-2766362::bigint, 'Jason T Barrett', 'Jason', 'Barrett'),
  (-2766361::bigint, 'Angela Burks Hill', 'Angela', 'Hill'),
  (-2766360::bigint, 'Joey Fillingane', 'Joey', 'Fillingane'),
  (-2766359::bigint, 'Don Hartness', 'Don', 'Hartness'),
  (-2766358::bigint, 'Dennis DeBar, Jr.', 'Dennis', 'DeBar'),
  (-2766356::bigint, 'Johnny L. DuPree', 'Johnny', 'DuPree'),
  (-2766355::bigint, 'Philman A. Ladner', 'Philman', 'Ladner'),
  (-2766354::bigint, 'Joseph M. Seymour', 'Joseph', 'Seymour'),
  (-2766352::bigint, 'Joel R. Carter, Jr.', 'Joel', 'Carter'),
  (-2766351::bigint, 'Scott DeLano', 'Scott', 'DeLano'),
  (-2766350::bigint, 'Jeremy England', 'Jeremy', 'England'),
  (-2766349::bigint, 'Brice Wiggins', 'Brice', 'Wiggins'),
  (-2766348::bigint, 'Lester Carpenter', 'Lester', 'Carpenter'),
  (-2766347::bigint, 'Brad Mattox', 'Brad', 'Mattox'),
  (-2766346::bigint, 'William Tracy Arnold', 'William', 'Arnold'),
  (-2766345::bigint, 'Jody Steverson', 'Jody', 'Steverson'),
  (-2766344::bigint, 'John G. Faulkner', 'John', 'Faulkner'),
  (-2766343::bigint, 'Justin Keen', 'Justin', 'Keen'),
  (-2766342::bigint, 'Kimberly Remak', 'Kimberly', 'Remak'),
  (-2766341::bigint, 'John Thomas "Trey" Lamar', 'John', 'Lamar'),
  (-2766340::bigint, 'Cedric Burnett', 'Cedric', 'Burnett'),
  (-2766339::bigint, 'Josh Hawkins', 'Josh', 'Hawkins'),
  (-2766338::bigint, 'Lataisha Jackson', 'Lataisha', 'Jackson'),
  (-2766337::bigint, 'Clay Deweese', 'Clay', 'Deweese'),
  (-2766336::bigint, 'Steve Massengill', 'Steve', 'Massengill'),
  (-2766335::bigint, 'Samuel Creekmore IV', 'Samuel', 'Creekmore'),
  (-2766334::bigint, 'Beth Luther Waldo', 'Beth', 'Waldo'),
  (-2766333::bigint, 'Rickey Thompson', 'Rickey', 'Thompson'),
  (-2766332::bigint, 'Shane Aguirre', 'Shane', 'Aguirre'),
  (-2766331::bigint, 'Jerry R. Turner', 'Jerry', 'Turner'),
  (-2766330::bigint, 'Randy P. Boyd', 'Randy', 'Boyd'),
  (-2766329::bigint, 'Rodney Hall', 'Rodney', 'Hall'),
  (-2766328::bigint, 'Donnie Bell', 'Donnie', 'Bell'),
  (-2766327::bigint, 'Justin Crosby', 'Justin', 'Crosby'),
  (-2766326::bigint, 'Perry Bailey', 'Perry', 'Bailey'),
  (-2766325::bigint, 'Jeff Hale', 'Jeff', 'Hale'),
  (-2766324::bigint, 'Dan Eubanks', 'Dan', 'Eubanks'),
  (-2766323::bigint, 'Otha Williams', 'Otha', 'Williams'),
  (-2766322::bigint, 'Kenji Holloway', 'Kenji', 'Holloway'),
  (-2766321::bigint, 'W. I. Harris', 'W.', 'Harris'),
  (-2766320::bigint, 'Robert L. Sanders', 'Robert', 'Sanders'),
  (-2766319::bigint, 'Tracey T. Rosebud', 'Tracey', 'Rosebud'),
  (-2766318::bigint, 'Otis Anthony', 'Otis', 'Anthony'),
  (-2766317::bigint, 'Solomon C. Osborne', 'Solomon', 'Osborne'),
  (-2766316::bigint, 'Jim Estrada', 'Jim', 'Estrada'),
  (-2766315::bigint, 'Kevin Horan', 'Kevin', 'Horan'),
  (-2766314::bigint, 'Joey Hood', 'Joey', 'Hood'),
  (-2766313::bigint, 'Karl Gibbs', 'Karl', 'Gibbs'),
  (-2766312::bigint, 'Andy Boyd', 'Andy', 'Boyd'),
  (-2766311::bigint, 'Cheikh Taylor', 'Cheikh', 'Taylor'),
  (-2766310::bigint, 'Dana McLean', 'Dana', 'McLean'),
  (-2766309::bigint, 'Hester Jackson McCray', 'Hester', 'Jackson McCray'),
  (-2766308::bigint, 'Kabir Karriem', 'Kabir', 'Karriem'),
  (-2766307::bigint, 'Carl L. Mickens', 'Carl', 'Mickens'),
  (-2766306::bigint, 'Rob Roberson', 'Rob', 'Roberson'),
  (-2766305::bigint, 'C. Scott Bounds', 'C.', 'Bounds'),
  (-2766304::bigint, 'Keith Jackson', 'Keith', 'Jackson'),
  (-2766303::bigint, 'Karl Oliver', 'Karl', 'Oliver'),
  (-2766302::bigint, 'Bryant W. Clark', 'Bryant', 'Clark'),
  (-2766301::bigint, 'Jason White', 'Jason', 'White'),
  (-2766300::bigint, 'Willie Bailey', 'Willie', 'Bailey'),
  (-2766299::bigint, 'John W. Hines, Sr.', 'John', 'Hines'),
  (-2766298::bigint, 'Timaka James-Jones', 'Timaka', 'James-Jones'),
  (-2766297::bigint, 'Bill Kinkade', 'Bill', 'Kinkade'),
  (-2766296::bigint, 'Vince Mangold', 'Vince', 'Mangold'),
  (-2766295::bigint, 'Kevin Ford', 'Kevin', 'Ford'),
  (-2766294::bigint, 'Oscar Denton', 'Oscar', 'Denton'),
  (-2766293::bigint, 'Clay Mansell', 'Clay', 'Mansell'),
  (-2766292::bigint, 'Lawrence Blackmon', 'Lawrence', 'Blackmon'),
  (-2766291::bigint, 'Jonathan McMillan', 'Jonathan', 'McMillan'),
  (-2766290::bigint, 'Brent Powell', 'Brent', 'Powell'),
  (-2766289::bigint, 'Fred Shanks', 'Fred', 'Shanks'),
  (-2766288::bigint, 'Gene Newman', 'Gene', 'Newman'),
  (-2766287::bigint, 'Lance Varner', 'Lance', 'Varner'),
  (-2766286::bigint, 'Stephanie Foster', 'Stephanie', 'Foster'),
  (-2766285::bigint, 'Shanda Yates', 'Shanda', 'Yates'),
  (-2766284::bigint, 'Christopher Bell', 'Christopher', 'Bell'),
  (-2766283::bigint, 'Fabian Nelson', 'Fabian', 'Nelson'),
  (-2766282::bigint, 'Earle S. Banks', 'Earle', 'Banks'),
  (-2766281::bigint, 'Zakiya Summers', 'Zakiya', 'Summers'),
  (-2766280::bigint, 'Grace Butler-Washington', 'Grace', 'Butler-Washington'),
  (-2766279::bigint, 'Bo Brown', 'Bo', 'Brown'),
  (-2766278::bigint, 'Ronnie C. Crudup', 'Ronnie', 'Crudup'),
  (-2766277::bigint, 'Justis Gibbs', 'Justis', 'Gibbs'),
  (-2766276::bigint, 'Jill Ford', 'Jill', 'Ford'),
  (-2766275::bigint, 'Lee Yancey', 'Lee', 'Yancey'),
  (-2766274::bigint, 'Celeste Hurst', 'Celeste', 'Hurst'),
  (-2766273::bigint, 'Gregory Holloway', 'Gregory', 'Holloway'),
  (-2766272::bigint, 'Price Wallace', 'Price', 'Wallace'),
  (-2766271::bigint, 'Randy Rushing', 'Randy', 'Rushing'),
  (-2766270::bigint, 'Mark Tullos', 'Mark', 'Tullos'),
  (-2766269::bigint, 'Omeria Scott', 'Omeria', 'Scott'),
  (-2766268::bigint, 'Stephen A. (Steve) Horne', 'Stephen', 'Horne'),
  (-2766267::bigint, 'Gregory Elliott', 'Gregory', 'Elliott'),
  (-2766266::bigint, 'Billy Adam Calvert', 'Billy', 'Calvert'),
  (-2766265::bigint, 'Troy Smith', 'Troy', 'Smith'),
  (-2766264::bigint, 'Jeffery Harness', 'Jeffery', 'Harness'),
  (-2766263::bigint, 'Shane Barnett', 'Shane', 'Barnett'),
  (-2766262::bigint, 'Joseph Tubb', 'Joseph', 'Tubb'),
  (-2766261::bigint, 'Charles Blackwell', 'Charles', 'Blackwell'),
  (-2766260::bigint, 'Donnie Scoggin', 'Donnie', 'Scoggin'),
  (-2766259::bigint, 'Noah Sanford', 'Noah', 'Sanford'),
  (-2766258::bigint, 'Bob Evans', 'Bob', 'Evans'),
  (-2766257::bigint, 'Becky Currie', 'Becky', 'Currie'),
  (-2766256::bigint, 'Timmy Ladner', 'Timmy', 'Ladner'),
  (-2766254::bigint, 'Jay McKnight', 'Jay', 'McKnight'),
  (-2766253::bigint, 'Angela Cockerham', 'Angela', 'Cockerham'),
  (-2766252::bigint, 'Sam C. Mims, V', 'Sam', 'Mims'),
  (-2766251::bigint, 'Daryl Porter', 'Daryl', 'Porter'),
  (-2766250::bigint, 'Bill Pigott', 'Bill', 'Pigott'),
  (-2766249::bigint, 'Ken Morgan', 'Ken', 'Morgan'),
  (-2766248::bigint, 'Kent McCarty', 'Kent', 'McCarty'),
  (-2766247::bigint, 'Missy McGee', 'Missy', 'McGee'),
  (-2766246::bigint, 'Percy W. Watson', 'Percy', 'Watson'),
  (-2766245::bigint, 'Larry Byrd', 'Larry', 'Byrd'),
  (-2766244::bigint, 'Elliot Burch', 'Elliot', 'Burch'),
  (-2766243::bigint, 'Jansen T. Owen', 'Jansen', 'Owen'),
  (-2766242::bigint, 'Steve Lott', 'Steve', 'Lott'),
  (-2766241::bigint, 'Stacey Hobgood-Wilkes', 'Stacey', 'Hobgood-Wilkes'),
  (-2766240::bigint, 'Manly Barton', 'Manly', 'Barton'),
  (-2766239::bigint, 'Jeramey Anderson', 'Jeramey', 'Anderson'),
  (-2766238::bigint, 'Jimmy Fondren', 'Jimmy', 'Fondren'),
  (-2766237::bigint, 'John Read', 'John', 'Read'),
  (-2766236::bigint, 'Henry Zuber III', 'Henry', 'Zuber'),
  (-2766235::bigint, 'Jeffrey S. Guice', 'Jeffrey', 'Guice'),
  (-2766234::bigint, 'Zachary Grady', 'Zachary', 'Grady'),
  (-2766233::bigint, 'Casey Eure', 'Casey', 'Eure'),
  (-2766232::bigint, 'Kevin Felsher', 'Kevin', 'Felsher'),
  (-2766231::bigint, 'Greg Haney', 'Greg', 'Haney'),
  (-2766230::bigint, 'Jeffrey Hulum III', 'Jeffrey', 'Hulum'),
  (-2766228::bigint, 'Carolyn Crawford', 'Carolyn', 'Crawford'),
  (-2766227::bigint, 'Brent Anderson', 'Brent', 'Anderson');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Mississippi Legislature member pages, https://billstatus.ls.state.ms.us/members/ — each seat read from the member’s OWN page, whose <DISTRICT> element is the only place the Legislature publishes a seat number (the roster list documents carry names only). Read 2026-09-28. The list documents ss_membs.xml and hr_membs.xml were last modified 2025-07-01 and 2025-10-14, BOTH BEFORE the court-ordered special elections of 2025-11-04, so their membership and their vacancy markers are stale; eight seats were resolved from the members’ own pages instead, each requiring both that the list holder’s page predates the specials and that Open States names a different surname there and that person nowhere in the chamber. (MS-2)', true, true
FROM ms_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 4 namesakes — guard lifted for THESE STATEMENTS ONLY ──────────────────
-- 🔴 Measured against production 2026-09-28 on the guard's own key, lower(first_name) and
-- lower(last_name), active rows only, WITH A POSITIVE CONTROL: the same key returns 72 active
-- Smiths, 70 Johnsons and 45 Williamses, so these 4 hits are a measurement and not a broken
-- sweep. Every one is a DIFFERENT PERSON, checked individually:
--   Senate  44  Chris Johnson — existing active "Chris Johnson" (external_id -220603) is a LOUISIANA U.S. House District 6 candidate in the LA 2026 Statewide General — no office, no term, one race_candidates row. Different person.
--   Senate  48  Mike Thompson — existing active "Mike Thompson" matches TWO other people — a CALIFORNIA U.S. Representative for Congressional District 4 and a KANSAS state senator for State Senate District 10. Different person from both.
--   House   94  Robert L. Johnson III — existing active "Robert B Johnson" is an INDIANA state representative for House District 100. Different person.
--   House  120  Richard Bennett — existing active row has first_name "Richard", last_name "Bennett" and full_name "Rick Bennett" — a MAINE state senator for State Senate District 18. Different person, and the pair guard sees it while a full_name comparison would not.
-- ⚠ The Chris Johnson row is the one that had to be checked rather than assumed. It carries no
-- office and is_incumbent = false, which is exactly the shape of a candidate row this programme
-- normally REUSES — MI-2 seated four sitting legislators that way and then found them hidden
-- because they inherited is_incumbent = false. It is not reusable here.

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE ms_namesakes(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ms_namesakes(external_id, full_name, first_name, last_name) VALUES
  (-2766357::bigint, 'Chris Johnson', 'Chris', 'Johnson'),
  (-2766353::bigint, 'Mike Thompson', 'Mike', 'Thompson'),
  (-2766255::bigint, 'Robert L. Johnson III', 'Robert', 'Johnson'),
  (-2766229::bigint, 'Richard Bennett', 'Richard', 'Bennett');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Mississippi Legislature member pages, https://billstatus.ls.state.ms.us/members/ — each seat read from the member’s OWN page, whose <DISTRICT> element is the only place the Legislature publishes a seat number (the roster list documents carry names only). Read 2026-09-28. The list documents ss_membs.xml and hr_membs.xml were last modified 2025-07-01 and 2025-10-14, BOTH BEFORE the court-ordered special elections of 2025-11-04, so their membership and their vacancy markers are stale; eight seats were resolved from the members’ own pages instead, each requiring both that the list holder’s page predates the specials and that Open States names a different surname there and that person nowhere in the chamber. (MS-2)', true, true
FROM ms_namesakes n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 3. The 174 terms ─────────────────────────────────────────────────────────

CREATE TEMP TABLE ms_terms(
  geo_id text, district_type text, external_id bigint,
  sort_key text, term_start date, start_precision text
) ON COMMIT DROP;

INSERT INTO ms_terms(geo_id, district_type, external_id, sort_key, term_start, start_precision) VALUES
  ('28001', 'STATE_UPPER', -2766400::bigint, 'Michael McLendon', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28002', 'STATE_UPPER', -2766399::bigint, 'Theresa Gillespie-Isom', '2026-01-01'::date, 'year'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28003', 'STATE_UPPER', -2766398::bigint, 'Kathy L. Chism', NULL::date, 'unknown'),
  ('28004', 'STATE_UPPER', -2766397::bigint, 'Rita Potts Parks', NULL::date, 'unknown'),
  ('28005', 'STATE_UPPER', -2766396::bigint, 'Daniel H. Sparks', NULL::date, 'unknown'),
  ('28006', 'STATE_UPPER', -2766395::bigint, 'Chad McMahan', NULL::date, 'unknown'),
  ('28007', 'STATE_UPPER', -2766394::bigint, 'Hob Bryan', NULL::date, 'unknown'),
  ('28008', 'STATE_UPPER', -2766393::bigint, 'Benjamin Suber', NULL::date, 'unknown'),
  ('28009', 'STATE_UPPER', -2766392::bigint, 'Nicole Boyd', NULL::date, 'unknown'),
  ('28010', 'STATE_UPPER', -2766391::bigint, 'Neil S. Whaley', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28011', 'STATE_UPPER', -2766390::bigint, 'Reginald Jackson', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28012', 'STATE_UPPER', -2766389::bigint, 'Derrick T. Simmons', NULL::date, 'unknown'),
  ('28013', 'STATE_UPPER', -2766388::bigint, 'Sarita Simmons', NULL::date, 'unknown'),
  ('28014', 'STATE_UPPER', -2766387::bigint, 'Lydia Graves Chassaniol', NULL::date, 'unknown'),
  ('28015', 'STATE_UPPER', -2766386::bigint, 'Bart Williams', NULL::date, 'unknown'),
  ('28016', 'STATE_UPPER', -2766385::bigint, 'Angela Turner Ford', NULL::date, 'unknown'),
  ('28017', 'STATE_UPPER', -2766384::bigint, 'Charles Younger', NULL::date, 'unknown'),
  ('28018', 'STATE_UPPER', -2766383::bigint, 'Lane Taylor', NULL::date, 'unknown'),
  ('28019', 'STATE_UPPER', -2766382::bigint, 'Kevin Blackwell', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28020', 'STATE_UPPER', -2766381::bigint, 'Josh Harkins', NULL::date, 'unknown'),
  ('28021', 'STATE_UPPER', -2766380::bigint, 'Bradford Blackmon', NULL::date, 'unknown'),
  ('28022', 'STATE_UPPER', -2766379::bigint, 'Joseph Thomas', NULL::date, 'unknown'),
  ('28023', 'STATE_UPPER', -2766378::bigint, 'W. Briggs Hopson III', NULL::date, 'unknown'),
  ('28024', 'STATE_UPPER', -2766377::bigint, 'Justin L. Pope', '2026-01-01'::date, 'year'),
  ('28025', 'STATE_UPPER', -2766376::bigint, 'J. Walter Michel', NULL::date, 'unknown'),
  ('28026', 'STATE_UPPER', -2766375::bigint, 'Kamesha B. Mumford', '2026-01-01'::date, 'year'),
  ('28027', 'STATE_UPPER', -2766374::bigint, 'Hillman Terome Frazier', NULL::date, 'unknown'),
  ('28028', 'STATE_UPPER', -2766373::bigint, 'Sollie B. Norwood', NULL::date, 'unknown'),
  ('28029', 'STATE_UPPER', -2766372::bigint, 'David Blount', NULL::date, 'unknown'),
  ('28030', 'STATE_UPPER', -2766371::bigint, 'Dean Kirby', NULL::date, 'unknown'),
  ('28031', 'STATE_UPPER', -2766370::bigint, 'Tyler McCaughn', NULL::date, 'unknown'),
  ('28032', 'STATE_UPPER', -2766369::bigint, 'Rod Hickman', NULL::date, 'unknown'),
  ('28033', 'STATE_UPPER', -2766368::bigint, 'Jeff Tate', NULL::date, 'unknown'),
  ('28034', 'STATE_UPPER', -2766367::bigint, 'Juan Barnett', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28035', 'STATE_UPPER', -2766366::bigint, 'Andy Berry', NULL::date, 'unknown'),
  ('28036', 'STATE_UPPER', -2766365::bigint, 'Brian Rhodes', NULL::date, 'unknown'),
  ('28037', 'STATE_UPPER', -2766364::bigint, 'Albert Butler', NULL::date, 'unknown'),
  ('28038', 'STATE_UPPER', -2766363::bigint, 'Gary Brumfield', NULL::date, 'unknown'),
  ('28039', 'STATE_UPPER', -2766362::bigint, 'Jason T Barrett', NULL::date, 'unknown'),
  ('28040', 'STATE_UPPER', -2766361::bigint, 'Angela Burks Hill', NULL::date, 'unknown'),
  ('28041', 'STATE_UPPER', -2766360::bigint, 'Joey Fillingane', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28042', 'STATE_UPPER', -2766359::bigint, 'Don Hartness', '2026-01-01'::date, 'year'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28043', 'STATE_UPPER', -2766358::bigint, 'Dennis DeBar, Jr.', NULL::date, 'unknown'),
  ('28044', 'STATE_UPPER', -2766357::bigint, 'Chris Johnson', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28045', 'STATE_UPPER', -2766356::bigint, 'Johnny L. DuPree', '2026-01-01'::date, 'year'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28046', 'STATE_UPPER', -2766355::bigint, 'Philman A. Ladner', NULL::date, 'unknown'),
  ('28047', 'STATE_UPPER', -2766354::bigint, 'Joseph M. Seymour', NULL::date, 'unknown'),
  ('28048', 'STATE_UPPER', -2766353::bigint, 'Mike Thompson', NULL::date, 'unknown'),
  ('28049', 'STATE_UPPER', -2766352::bigint, 'Joel R. Carter, Jr.', NULL::date, 'unknown'),
  ('28050', 'STATE_UPPER', -2766351::bigint, 'Scott DeLano', NULL::date, 'unknown'),
  ('28051', 'STATE_UPPER', -2766350::bigint, 'Jeremy England', NULL::date, 'unknown'),
  ('28052', 'STATE_UPPER', -2766349::bigint, 'Brice Wiggins', NULL::date, 'unknown'),
  ('28001', 'STATE_LOWER', -2766348::bigint, 'Lester Carpenter', NULL::date, 'unknown'),
  ('28002', 'STATE_LOWER', -2766347::bigint, 'Brad Mattox', NULL::date, 'unknown'),
  ('28003', 'STATE_LOWER', -2766346::bigint, 'William Tracy Arnold', NULL::date, 'unknown'),
  ('28004', 'STATE_LOWER', -2766345::bigint, 'Jody Steverson', NULL::date, 'unknown'),
  ('28005', 'STATE_LOWER', -2766344::bigint, 'John G. Faulkner', NULL::date, 'unknown'),
  ('28006', 'STATE_LOWER', -2766343::bigint, 'Justin Keen', NULL::date, 'unknown'),
  ('28007', 'STATE_LOWER', -2766342::bigint, 'Kimberly Remak', NULL::date, 'unknown'),
  ('28008', 'STATE_LOWER', -2766341::bigint, 'John Thomas "Trey" Lamar', NULL::date, 'unknown'),
  ('28009', 'STATE_LOWER', -2766340::bigint, 'Cedric Burnett', NULL::date, 'unknown'),
  ('28010', 'STATE_LOWER', -2766339::bigint, 'Josh Hawkins', NULL::date, 'unknown'),
  ('28011', 'STATE_LOWER', -2766338::bigint, 'Lataisha Jackson', NULL::date, 'unknown'),
  ('28012', 'STATE_LOWER', -2766337::bigint, 'Clay Deweese', NULL::date, 'unknown'),
  ('28013', 'STATE_LOWER', -2766336::bigint, 'Steve Massengill', NULL::date, 'unknown'),
  ('28014', 'STATE_LOWER', -2766335::bigint, 'Samuel Creekmore IV', NULL::date, 'unknown'),
  ('28015', 'STATE_LOWER', -2766334::bigint, 'Beth Luther Waldo', NULL::date, 'unknown'),
  ('28016', 'STATE_LOWER', -2766333::bigint, 'Rickey Thompson', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28017', 'STATE_LOWER', -2766332::bigint, 'Shane Aguirre', NULL::date, 'unknown'),
  ('28018', 'STATE_LOWER', -2766331::bigint, 'Jerry R. Turner', NULL::date, 'unknown'),
  ('28019', 'STATE_LOWER', -2766330::bigint, 'Randy P. Boyd', NULL::date, 'unknown'),
  ('28020', 'STATE_LOWER', -2766329::bigint, 'Rodney Hall', NULL::date, 'unknown'),
  ('28021', 'STATE_LOWER', -2766328::bigint, 'Donnie Bell', NULL::date, 'unknown'),
  ('28022', 'STATE_LOWER', -2766327::bigint, 'Justin Crosby', '2026-01-01'::date, 'year'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28023', 'STATE_LOWER', -2766326::bigint, 'Perry Bailey', NULL::date, 'unknown'),
  ('28024', 'STATE_LOWER', -2766325::bigint, 'Jeff Hale', NULL::date, 'unknown'),
  ('28025', 'STATE_LOWER', -2766324::bigint, 'Dan Eubanks', NULL::date, 'unknown'),
  ('28026', 'STATE_LOWER', -2766323::bigint, 'Otha Williams', '2026-01-01'::date, 'year'),
  ('28027', 'STATE_LOWER', -2766322::bigint, 'Kenji Holloway', NULL::date, 'unknown'),
  ('28028', 'STATE_LOWER', -2766321::bigint, 'W. I. Harris', NULL::date, 'unknown'),
  ('28029', 'STATE_LOWER', -2766320::bigint, 'Robert L. Sanders', NULL::date, 'unknown'),
  ('28030', 'STATE_LOWER', -2766319::bigint, 'Tracey T. Rosebud', NULL::date, 'unknown'),
  ('28031', 'STATE_LOWER', -2766318::bigint, 'Otis Anthony', NULL::date, 'unknown'),
  ('28032', 'STATE_LOWER', -2766317::bigint, 'Solomon C. Osborne', NULL::date, 'unknown'),
  ('28033', 'STATE_LOWER', -2766316::bigint, 'Jim Estrada', NULL::date, 'unknown'),
  ('28034', 'STATE_LOWER', -2766315::bigint, 'Kevin Horan', NULL::date, 'unknown'),
  ('28035', 'STATE_LOWER', -2766314::bigint, 'Joey Hood', NULL::date, 'unknown'),
  ('28036', 'STATE_LOWER', -2766313::bigint, 'Karl Gibbs', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28037', 'STATE_LOWER', -2766312::bigint, 'Andy Boyd', NULL::date, 'unknown'),
  ('28038', 'STATE_LOWER', -2766311::bigint, 'Cheikh Taylor', NULL::date, 'unknown'),
  ('28039', 'STATE_LOWER', -2766310::bigint, 'Dana McLean', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28040', 'STATE_LOWER', -2766309::bigint, 'Hester Jackson McCray', NULL::date, 'unknown'),
  ('28041', 'STATE_LOWER', -2766308::bigint, 'Kabir Karriem', NULL::date, 'unknown'),   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon
  ('28042', 'STATE_LOWER', -2766307::bigint, 'Carl L. Mickens', NULL::date, 'unknown'),
  ('28043', 'STATE_LOWER', -2766306::bigint, 'Rob Roberson', NULL::date, 'unknown'),
  ('28044', 'STATE_LOWER', -2766305::bigint, 'C. Scott Bounds', NULL::date, 'unknown'),
  ('28045', 'STATE_LOWER', -2766304::bigint, 'Keith Jackson', NULL::date, 'unknown'),
  ('28046', 'STATE_LOWER', -2766303::bigint, 'Karl Oliver', NULL::date, 'unknown'),
  ('28047', 'STATE_LOWER', -2766302::bigint, 'Bryant W. Clark', NULL::date, 'unknown'),
  ('28048', 'STATE_LOWER', -2766301::bigint, 'Jason White', NULL::date, 'unknown'),
  ('28049', 'STATE_LOWER', -2766300::bigint, 'Willie Bailey', NULL::date, 'unknown'),
  ('28050', 'STATE_LOWER', -2766299::bigint, 'John W. Hines, Sr.', NULL::date, 'unknown'),
  ('28051', 'STATE_LOWER', -2766298::bigint, 'Timaka James-Jones', NULL::date, 'unknown'),
  ('28052', 'STATE_LOWER', -2766297::bigint, 'Bill Kinkade', NULL::date, 'unknown'),
  ('28053', 'STATE_LOWER', -2766296::bigint, 'Vince Mangold', NULL::date, 'unknown'),
  ('28054', 'STATE_LOWER', -2766295::bigint, 'Kevin Ford', NULL::date, 'unknown'),
  ('28055', 'STATE_LOWER', -2766294::bigint, 'Oscar Denton', NULL::date, 'unknown'),
  ('28056', 'STATE_LOWER', -2766293::bigint, 'Clay Mansell', NULL::date, 'unknown'),
  ('28057', 'STATE_LOWER', -2766292::bigint, 'Lawrence Blackmon', NULL::date, 'unknown'),
  ('28058', 'STATE_LOWER', -2766291::bigint, 'Jonathan McMillan', NULL::date, 'unknown'),
  ('28059', 'STATE_LOWER', -2766290::bigint, 'Brent Powell', NULL::date, 'unknown'),
  ('28060', 'STATE_LOWER', -2766289::bigint, 'Fred Shanks', NULL::date, 'unknown'),
  ('28061', 'STATE_LOWER', -2766288::bigint, 'Gene Newman', NULL::date, 'unknown'),
  ('28062', 'STATE_LOWER', -2766287::bigint, 'Lance Varner', NULL::date, 'unknown'),
  ('28063', 'STATE_LOWER', -2766286::bigint, 'Stephanie Foster', NULL::date, 'unknown'),
  ('28064', 'STATE_LOWER', -2766285::bigint, 'Shanda Yates', NULL::date, 'unknown'),
  ('28065', 'STATE_LOWER', -2766284::bigint, 'Christopher Bell', NULL::date, 'unknown'),
  ('28066', 'STATE_LOWER', -2766283::bigint, 'Fabian Nelson', NULL::date, 'unknown'),
  ('28067', 'STATE_LOWER', -2766282::bigint, 'Earle S. Banks', NULL::date, 'unknown'),
  ('28068', 'STATE_LOWER', -2766281::bigint, 'Zakiya Summers', NULL::date, 'unknown'),
  ('28069', 'STATE_LOWER', -2766280::bigint, 'Grace Butler-Washington', NULL::date, 'unknown'),
  ('28070', 'STATE_LOWER', -2766279::bigint, 'Bo Brown', NULL::date, 'unknown'),
  ('28071', 'STATE_LOWER', -2766278::bigint, 'Ronnie C. Crudup', NULL::date, 'unknown'),
  ('28072', 'STATE_LOWER', -2766277::bigint, 'Justis Gibbs', NULL::date, 'unknown'),
  ('28073', 'STATE_LOWER', -2766276::bigint, 'Jill Ford', NULL::date, 'unknown'),
  ('28074', 'STATE_LOWER', -2766275::bigint, 'Lee Yancey', NULL::date, 'unknown'),
  ('28075', 'STATE_LOWER', -2766274::bigint, 'Celeste Hurst', NULL::date, 'unknown'),
  ('28076', 'STATE_LOWER', -2766273::bigint, 'Gregory Holloway', NULL::date, 'unknown'),
  ('28077', 'STATE_LOWER', -2766272::bigint, 'Price Wallace', NULL::date, 'unknown'),
  ('28078', 'STATE_LOWER', -2766271::bigint, 'Randy Rushing', NULL::date, 'unknown'),
  ('28079', 'STATE_LOWER', -2766270::bigint, 'Mark Tullos', NULL::date, 'unknown'),
  ('28080', 'STATE_LOWER', -2766269::bigint, 'Omeria Scott', NULL::date, 'unknown'),
  ('28081', 'STATE_LOWER', -2766268::bigint, 'Stephen A. (Steve) Horne', NULL::date, 'unknown'),
  ('28082', 'STATE_LOWER', -2766267::bigint, 'Gregory Elliott', NULL::date, 'unknown'),
  ('28083', 'STATE_LOWER', -2766266::bigint, 'Billy Adam Calvert', NULL::date, 'unknown'),
  ('28084', 'STATE_LOWER', -2766265::bigint, 'Troy Smith', NULL::date, 'unknown'),
  ('28085', 'STATE_LOWER', -2766264::bigint, 'Jeffery Harness', NULL::date, 'unknown'),
  ('28086', 'STATE_LOWER', -2766263::bigint, 'Shane Barnett', NULL::date, 'unknown'),
  ('28087', 'STATE_LOWER', -2766262::bigint, 'Joseph Tubb', NULL::date, 'unknown'),
  ('28088', 'STATE_LOWER', -2766261::bigint, 'Charles Blackwell', NULL::date, 'unknown'),
  ('28089', 'STATE_LOWER', -2766260::bigint, 'Donnie Scoggin', NULL::date, 'unknown'),
  ('28090', 'STATE_LOWER', -2766259::bigint, 'Noah Sanford', NULL::date, 'unknown'),
  ('28091', 'STATE_LOWER', -2766258::bigint, 'Bob Evans', NULL::date, 'unknown'),
  ('28092', 'STATE_LOWER', -2766257::bigint, 'Becky Currie', NULL::date, 'unknown'),
  ('28093', 'STATE_LOWER', -2766256::bigint, 'Timmy Ladner', NULL::date, 'unknown'),
  ('28094', 'STATE_LOWER', -2766255::bigint, 'Robert L. Johnson III', NULL::date, 'unknown'),
  ('28095', 'STATE_LOWER', -2766254::bigint, 'Jay McKnight', NULL::date, 'unknown'),
  ('28096', 'STATE_LOWER', -2766253::bigint, 'Angela Cockerham', NULL::date, 'unknown'),
  ('28097', 'STATE_LOWER', -2766252::bigint, 'Sam C. Mims, V', NULL::date, 'unknown'),
  ('28098', 'STATE_LOWER', -2766251::bigint, 'Daryl Porter', NULL::date, 'unknown'),
  ('28099', 'STATE_LOWER', -2766250::bigint, 'Bill Pigott', NULL::date, 'unknown'),
  ('28100', 'STATE_LOWER', -2766249::bigint, 'Ken Morgan', NULL::date, 'unknown'),
  ('28101', 'STATE_LOWER', -2766248::bigint, 'Kent McCarty', NULL::date, 'unknown'),
  ('28102', 'STATE_LOWER', -2766247::bigint, 'Missy McGee', NULL::date, 'unknown'),
  ('28103', 'STATE_LOWER', -2766246::bigint, 'Percy W. Watson', NULL::date, 'unknown'),
  ('28104', 'STATE_LOWER', -2766245::bigint, 'Larry Byrd', NULL::date, 'unknown'),
  ('28105', 'STATE_LOWER', -2766244::bigint, 'Elliot Burch', NULL::date, 'unknown'),
  ('28106', 'STATE_LOWER', -2766243::bigint, 'Jansen T. Owen', NULL::date, 'unknown'),
  ('28107', 'STATE_LOWER', -2766242::bigint, 'Steve Lott', NULL::date, 'unknown'),
  ('28108', 'STATE_LOWER', -2766241::bigint, 'Stacey Hobgood-Wilkes', NULL::date, 'unknown'),
  ('28109', 'STATE_LOWER', -2766240::bigint, 'Manly Barton', NULL::date, 'unknown'),
  ('28110', 'STATE_LOWER', -2766239::bigint, 'Jeramey Anderson', NULL::date, 'unknown'),
  ('28111', 'STATE_LOWER', -2766238::bigint, 'Jimmy Fondren', NULL::date, 'unknown'),
  ('28112', 'STATE_LOWER', -2766237::bigint, 'John Read', NULL::date, 'unknown'),
  ('28113', 'STATE_LOWER', -2766236::bigint, 'Henry Zuber III', NULL::date, 'unknown'),
  ('28114', 'STATE_LOWER', -2766235::bigint, 'Jeffrey S. Guice', NULL::date, 'unknown'),
  ('28115', 'STATE_LOWER', -2766234::bigint, 'Zachary Grady', NULL::date, 'unknown'),
  ('28116', 'STATE_LOWER', -2766233::bigint, 'Casey Eure', NULL::date, 'unknown'),
  ('28117', 'STATE_LOWER', -2766232::bigint, 'Kevin Felsher', NULL::date, 'unknown'),
  ('28118', 'STATE_LOWER', -2766231::bigint, 'Greg Haney', NULL::date, 'unknown'),
  ('28119', 'STATE_LOWER', -2766230::bigint, 'Jeffrey Hulum III', NULL::date, 'unknown'),
  ('28120', 'STATE_LOWER', -2766229::bigint, 'Richard Bennett', NULL::date, 'unknown'),
  ('28121', 'STATE_LOWER', -2766228::bigint, 'Carolyn Crawford', NULL::date, 'unknown'),
  ('28122', 'STATE_LOWER', -2766227::bigint, 'Brent Anderson', NULL::date, 'unknown');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, source)
SELECT o.id, p.id, t.term_start, t.start_precision, 'Mississippi Legislature member pages, https://billstatus.ls.state.ms.us/members/ — each seat read from the member’s OWN page, whose <DISTRICT> element is the only place the Legislature publishes a seat number (the roster list documents carry names only). Read 2026-09-28. The list documents ss_membs.xml and hr_membs.xml were last modified 2025-07-01 and 2025-10-14, BOTH BEFORE the court-ordered special elections of 2025-11-04, so their membership and their vacancy markers are stale; eight seats were resolved from the members’ own pages instead, each requiring both that the list holder’s page predates the specials and that Open States names a different surname there and that person nowhere in the chamber. (MS-2)'
FROM ms_terms t
JOIN essentials.districts d ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'ms'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms x WHERE x.office_id = o.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people   int;
  v_terms    int;
  v_seated   int;
  v_unseated int;
  v_dated    int;
  v_notinc   int;
  v_dupdist  int;
  v_johnson  int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN -2766400 AND -2766227;
  IF v_people <> 174 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 174 people in the external_id band, found %', v_people;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_terms <> 174 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 174 MS legislative terms, found %', v_terms;
  END IF;

  -- 🔴 COUNT och.politician_id, NOT rows. office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_seated <> 174 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 174 seated MS legislative offices, found %', v_seated;
  END IF;

  SELECT count(*) INTO v_unseated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);
  IF v_unseated <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % MS legislative office(s) carry no term — an office with no term row is INVISIBLE and nothing errors', v_unseated;
  END IF;

  SELECT count(*) INTO v_dated
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND ot.term_start IS NOT NULL;
  IF v_dated <> 7 THEN
    RAISE EXCEPTION 'MS-2 gate: expected exactly 7 dated MS legislative terms (the members whose only service stretch is "2026-present"), found %', v_dated;
  END IF;

  SELECT count(*) INTO v_notinc FROM essentials.politicians
   WHERE external_id BETWEEN -2766400 AND -2766227 AND is_incumbent IS DISTINCT FROM true;
  IF v_notinc <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % newly seated MS legislator(s) are not flagged is_incumbent — they would be hidden from address search', v_notinc;
  END IF;

  -- 🔴 One holder per district, asserted per district. 174 in total is also what 173 correct
  -- districts plus one carrying two holders and one carrying none would give.
  SELECT count(*) INTO v_dupdist
    FROM essentials.districts d
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND (SELECT count(och.politician_id)
            FROM essentials.office_current_holder och
            JOIN essentials.offices o ON o.id = och.office_id
           WHERE o.district_id = d.id) <> 1;
  IF v_dupdist <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % MS legislative district(s) do not resolve to exactly one holder', v_dupdist;
  END IF;

  -- 🔴 Chris Johnson must be UNDATED. His page says "2020-present" and he moved from SD-45 to
  -- SD-44 in 2026; dating this seat from his career would assert he held it while John Polk did.
  SELECT count(*) INTO v_johnson
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text = 'STATE_UPPER' AND d.geo_id = '28044'
     AND p.full_name = 'Chris Johnson' AND ot.term_start IS NULL AND ot.start_precision = 'unknown';
  IF v_johnson <> 1 THEN
    RAISE EXCEPTION 'MS-2 gate: Senate District 44 must be held by Chris Johnson with an UNDATED term (office_terms is a seat, not a career), found %', v_johnson;
  END IF;

  RAISE NOTICE 'MS-2 occupancy gate PASSED: 174 people, 174 terms, 174 seated, 0 unseated offices, 7 dated at year precision, every district exactly one holder, SD-44 undated.';
END $$;

COMMIT;
