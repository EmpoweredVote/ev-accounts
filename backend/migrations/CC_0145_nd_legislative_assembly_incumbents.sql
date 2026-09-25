-- CC_0145_nd_legislative_assembly_incumbents.sql
-- Knight Foundation program, wave ND-2 (occupancy half). Slot RESERVED from the allocator.
-- Applies immediately after CC_0144, which created the two chambers and the 141 offices.
--
-- Seats all 141 members of the 69th North Dakota Legislative Assembly: 47 senators and 94
-- representatives. Creates 141 people and 141 terms. NO office is left vacant.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE ROSTER THAT LOOKS RIGHT HOLDS 148 MEMBERS, AND SEATING IT WOULD HAVE PUT SEVEN EXTRA
-- PEOPLE INTO 141 SEATS.
--
-- ndlegis.gov publishes THREE member lists for this assembly -- Regular Session, Jan 2026 Special
-- Session and Sep 2026 Special Session. The regular-session list is CUMULATIVE: it retains
-- everyone who held a seat at any point, so SEVEN districts list FOUR members. North Dakota's
-- House is legitimately TWO-per-district, so "four in a district" reads as 2x2 and survives a
-- shape check that would have caught it instantly in a single-member state.
-- ▶ The roster used here is the Sep 2026 Special Session's, convened 2026-09-02: exactly 141
--   members, 47 senators and 94 representatives, every district one senator and two
--   representatives.
--
-- 🟢 AND THE MEMBER PAGES WERE READ ANYWAY, ALL 141 OF THEM. MN-2's rule is that a roster list
-- page is not a change-check. Every member's own biography page was fetched and its <h1> asserted
-- to name that member; ZERO carry a departure marker on a 69th-Assembly row.
-- 🔴 THAT ZERO WAS CONTROLLED. A uniform answer is a broken detector until proved otherwise, so
-- the identical sweep was re-run over the 148-member cumulative roster: it found all SEVEN
-- departures and every one of them is dated to the day --
--   Liz Conmy (D11) deceased 2026-04-25 · Jared C. Hagert (D20) resigned 2026-02-09 ·
--   Cynthia Schreiber-Beck (D25) deceased 2025-05-18 · Jeremy L. Olson (D26) resigned 2025-05-05 ·
--   Josh Christy (D27) deceased 2025-02-18 · Emily O'Brien (D42) resigned 2025-08-19 ·
--   Josh Boschee (SD44) resigned 2026-08-04.
-- None of the seven is written by this migration. They are history, and the seat is held today by
-- the successor.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 NORTH DAKOTA DATES ITS ARRIVALS, WHICH MICHIGAN AND MINNESOTA COULD NOT.
--
-- EIGHT members carry an exact `Active <date>` line on the body's own page, and those eight terms
-- are written at DAY precision with how_started 'appointed':
--
--   Jamie Selzler      SD44  2026-08-05   Karen Grindberg   HD41  2024-12-01
--   Adam Goldwyn       HD11  2026-06-01   Dave Rustebakke   HD20  2026-04-21
--   Kathy Skroch       HD25  2025-09-10   Kelby Timmons     HD26  2025-05-29
--   TJ Brown           HD27  2025-03-10   Dustin McNally    HD42  2025-09-19
--
-- The mechanism is not inferred from the date: N.D.C.C. 16.1-13-10 fills a legislative vacancy by
-- appointment of the vacating legislator's district party committee, and two cases were confirmed
-- against contemporaneous reporting -- the District 44 Dem-NPL executive committee appointed
-- Selzler on 2026-08-04, and the District 41 Republican executive committee appointed Grindberg
-- to the remainder of Michelle Strinden's term after Strinden resigned to become lieutenant
-- governor.
-- ⚠ AND THE TWO SOURCES DISAGREE BY ONE DAY ON GRINDBERG, WHICH IS RECORDED RATHER THAN SMOOTHED.
-- The Legislative Branch says `Active December 1, 2024`; contemporaneous reporting says she was
-- SWORN IN on December 2, 2024, Strinden's resignation having taken effect December 1. The body's
-- own record is the one written here. "First sworn" and "active from" are different facts and this
-- is a case where they differ.
--
-- 🔴 THE OTHER 133 TERMS ARE OPEN-ENDED AT `unknown`, AND NOTHING IS GUESSED. This is deliberate
-- and it is NOT for want of a number:
--   * N.D. Const. art. IV s 7 says terms begin on the first day of December following the
--     election, so a date exists in the abstract -- but senators and representatives both serve
--     FOUR-year terms (art. IV s 4) and North Dakota staggers them, so whether a given member's
--     current term began 2022-12-01 or 2024-12-01 is not knowable from any source read here.
--   * A RE-ELECTION DOES NOT RESTART AN OCCUPANCY (the SC-3 rule), so even the correct term start
--     would be the wrong value for a member who has held the seat continuously since before it.
--   * The bio pages publish "Senate since 1987"-style lines, but that is a fact about service in
--     the CHAMBER, not about this SEAT -- and North Dakota redrew its map in 2021 and again by
--     court order effective 2024-01-08. Writing 1987-01-01 would assert tenure in a seat that did
--     not exist in that shape.
--   Those `since` years ARE captured, in backend/data/seed-nd-2026/nd-members.json, as evidence
--   for a later dating pass. This is the same disposition OH-2 and MN-2 reached, with more of the
--   reasoning available.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TWO OFFICES SHARE ONE DISTRICT, SO (geo_id, district_type) IS NOT A KEY HERE. Every earlier
-- wave in this program could match a member to an office through the district alone. In North
-- Dakota 46 House districts hold TWO interchangeable offices, and the seats carry no position
-- number on any ballot, so there is no natural fact that says which member holds which row.
-- ▶ The assignment is therefore made deterministic rather than meaningful: offices are ranked by
--   their own id, members by full_name, and slot N is matched to slot N. Both keys are stable, so
--   a re-run reproduces the same pairing -- which is what makes this migration idempotent. The
--   pairing asserts nothing about the world, and nothing downstream may read meaning into it.
--
-- 🔴 A MEMBER'S OWN DISTRICT LABEL IS NOT THE ACCORDION HEADING IT SITS UNDER. Lisa Finley-DeVille
-- and Clayton Fegley both appear under the heading "District 4", and their own rows say 4A and 4B.
-- The heading is what the roster groups by; the member's label is what identifies the seat. Using
-- the heading would have tried to join both to a STATE_LOWER district '38004', which does not
-- exist -- a loud failure rather than a silent one, but only by luck of North Dakota having no
-- whole House District 4.
--
-- 🔴 ONE NAME COLLIDES WITH A DIFFERENT PERSON ALREADY IN PRODUCTION, AND THE GUARD IS LIFTED FOR
-- EXACTLY ONE ROW. `Dick Anderson`, Representative for North Dakota House District 6 (Republican,
-- farmer, UND, House since 2011), shares first_name/last_name with -4110005 `Dick Anderson`, who
-- SITS TODAY as an OREGON STATE SENATOR for OR SD-5. A person cannot hold an Oregon Senate seat
-- and a North Dakota House seat at once, so these are different people -- the same structural
-- evidence the GA roster trap needed, where 2 of 4 name hits were a Colorado senator and a Utah
-- treasurer.
-- ⚠ The sweep was run on the GUARD'S OWN KEY (first_name, last_name), which is OH-2's lesson, and
-- it was controlled: the same query reports 66 active `Johnson`s and 37 active `Anderson`s, so the
-- single hit is a true single and not an empty detector.
--
-- 🔴 PARTY IS NOT WRITTEN. The rosters carry it; party lives on races.primary_party.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded on a stable key. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The 140 people whose names collide with nobody ────────────────────────

CREATE TEMP TABLE nd_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO nd_new_people(external_id, full_name, first_name, last_name) VALUES
  (-2762400, 'Brad Bekkedahl', 'Brad', 'Bekkedahl'),
  (-2762399, 'Mark Enget', 'Mark', 'Enget'),
  (-2762398, 'Bob Paulson', 'Bob', 'Paulson'),
  (-2762397, 'Chuck Walen', 'Chuck', 'Walen'),
  (-2762396, 'Randy A. Burckhard', 'Randy', 'Burckhard'),
  (-2762395, 'Paul J. Thomas', 'Paul', 'Thomas'),
  (-2762394, 'Michelle Axtman', 'Michelle', 'Axtman'),
  (-2762393, 'Jeffery J. Magrum', 'Jeffery', 'Magrum'),
  (-2762392, 'Richard Marcellais', 'Richard', 'Marcellais'),
  (-2762391, 'Ryan Braunberger', 'Ryan', 'Braunberger'),
  (-2762390, 'Tim Mathern', 'Tim', 'Mathern'),
  (-2762389, 'Cole Conley', 'Cole', 'Conley'),
  (-2762388, 'Judy Lee', 'Judy', 'Lee'),
  (-2762387, 'Jerry Klein', 'Jerry', 'Klein'),
  (-2762386, 'Kent Weston', 'Kent', 'Weston'),
  (-2762385, 'David A. Clemens', 'David', 'Clemens'),
  (-2762384, 'Jonathan Sickler', 'Jonathan', 'Sickler'),
  (-2762383, 'Scott Meyer', 'Scott', 'Meyer'),
  (-2762382, 'Janne Myrdal', 'Janne', 'Myrdal'),
  (-2762381, 'Randy D. Lemm', 'Randy', 'Lemm'),
  (-2762380, 'Kathy Hogan', 'Kathy', 'Hogan'),
  (-2762379, 'Mark F. Weber', 'Mark', 'Weber'),
  (-2762378, 'Todd Beard', 'Todd', 'Beard'),
  (-2762377, 'Mike Wobbema', 'Mike', 'Wobbema'),
  (-2762376, 'Larry Luick', 'Larry', 'Luick'),
  (-2762375, 'Dale Patten', 'Dale', 'Patten'),
  (-2762374, 'Kristin Roers', 'Kristin', 'Roers'),
  (-2762373, 'Robert Erbele', 'Robert', 'Erbele'),
  (-2762372, 'Terry M. Wanzek', 'Terry', 'Wanzek'),
  (-2762371, 'Diane Larson', 'Diane', 'Larson'),
  (-2762370, 'Donald Schaible', 'Donald', 'Schaible'),
  (-2762369, 'Dick Dever', 'Dick', 'Dever'),
  (-2762368, 'Keith Boehm', 'Keith', 'Boehm'),
  (-2762367, 'Justin Gerhardt', 'Justin', 'Gerhardt'),
  (-2762366, 'Sean Cleary', 'Sean', 'Cleary'),
  (-2762365, 'Desiree van Oosting', 'Desiree', 'Oosting'),
  (-2762364, 'Dean Rummel', 'Dean', 'Rummel'),
  (-2762363, 'David Hogue', 'David', 'Hogue'),
  (-2762362, 'Greg Kessel', 'Greg', 'Kessel'),
  (-2762361, 'Jose L. Castaneda', 'Jose', 'Castaneda'),
  (-2762360, 'Kyle Davison', 'Kyle', 'Davison'),
  (-2762359, 'Claire Cory', 'Claire', 'Cory'),
  (-2762358, 'Jeff Barta', 'Jeff', 'Barta'),
  (-2762357, 'Jamie Selzler', 'Jamie', 'Selzler'),
  (-2762356, 'Ronald Sorvaag', 'Ronald', 'Sorvaag'),
  (-2762355, 'Michelle Powers', 'Michelle', 'Powers'),
  (-2762354, 'Michael Dwyer', 'Michael', 'Dwyer'),
  (-2762353, 'David Richter', 'David', 'Richter'),
  (-2762352, 'Patrick R. Hatlestad', 'Patrick', 'Hatlestad'),
  (-2762351, 'Bert Anderson', 'Bert', 'Anderson'),
  (-2762350, 'Donald W. Longmuir', 'Donald', 'Longmuir'),
  (-2762349, 'Jeff Hoverson', 'Jeff', 'Hoverson'),
  (-2762348, 'Lori VanWinkle', 'Lori', 'VanWinkle'),
  (-2762347, 'Clayton Fegley', 'Clayton', 'Fegley'),
  (-2762346, 'Lisa Finley-DeVille', 'Lisa', 'Finley-DeVille'),
  (-2762345, 'Jay Fisher', 'Jay', 'Fisher'),
  (-2762344, 'Scott Louser', 'Scott', 'Louser'),
  (-2762343, 'Daniel R. Vollmer', 'Daniel', 'Vollmer'),
  (-2762341, 'Jason Dockter', 'Jason', 'Dockter'),
  (-2762340, 'Matthew Heilman', 'Matthew', 'Heilman'),
  (-2762339, 'Mike Berg', 'Mike', 'Berg'),
  (-2762338, 'SuAnn Olson', 'SuAnn', 'Olson'),
  (-2762337, 'Collette Brown', 'Collette', 'Brown'),
  (-2762336, 'Jayme Davis', 'Jayme', 'Davis'),
  (-2762335, 'Jared Hendrix', 'Jared', 'Hendrix'),
  (-2762334, 'Steve Swiontek', 'Steve', 'Swiontek'),
  (-2762333, 'Adam Goldwyn', 'Adam', 'Goldwyn'),
  (-2762332, 'Gretchen Dobervich', 'Gretchen', 'Dobervich'),
  (-2762331, 'Bernie Satrom', 'Bernie', 'Satrom'),
  (-2762330, 'Mitch Ostlie', 'Mitch', 'Ostlie'),
  (-2762329, 'Austen Schauer', 'Austen', 'Schauer'),
  (-2762328, 'Jim Jonas', 'Jim', 'Jonas'),
  (-2762327, 'Jon O. Nelson', 'Jon', 'Nelson'),
  (-2762326, 'Robin Weisz', 'Robin', 'Weisz'),
  (-2762325, 'Donna Henderson', 'Donna', 'Henderson'),
  (-2762324, 'Kathy Frelich', 'Kathy', 'Frelich'),
  (-2762323, 'Andrew Marschall', 'Andrew', 'Marschall'),
  (-2762322, 'Ben Koppelman', 'Ben', 'Koppelman'),
  (-2762321, 'Landon Bahl', 'Landon', 'Bahl'),
  (-2762320, 'Mark Sanford', 'Mark', 'Sanford'),
  (-2762319, 'Nels Christianson', 'Nels', 'Christianson'),
  (-2762318, 'Steve Vetter', 'Steve', 'Vetter'),
  (-2762317, 'David Monson', 'David', 'Monson'),
  (-2762316, 'Karen A. Anderson', 'Karen', 'Anderson'),
  (-2762315, 'Dave Rustebakke', 'Dave', 'Rustebakke'),
  (-2762314, 'Mike Beltz', 'Mike', 'Beltz'),
  (-2762313, 'LaurieBeth Hager', 'LaurieBeth', 'Hager'),
  (-2762312, 'Mary Schneider', 'Mary', 'Schneider'),
  (-2762311, 'Brandy L. Pyle', 'Brandy', 'Pyle'),
  (-2762310, 'Jonathan Warrey', 'Jonathan', 'Warrey'),
  (-2762309, 'Dennis Nehring', 'Dennis', 'Nehring'),
  (-2762308, 'Nico Rios', 'Nico', 'Rios'),
  (-2762307, 'Daniel Johnston', 'Daniel', 'Johnston'),
  (-2762306, 'Dwight Kiefert', 'Dwight', 'Kiefert'),
  (-2762305, 'Alisa Mitskog', 'Alisa', 'Mitskog'),
  (-2762304, 'Kathy Skroch', 'Kathy', 'Skroch'),
  (-2762303, 'Kelby Timmons', 'Kelby', 'Timmons'),
  (-2762302, 'Roger A. Maki', 'Roger', 'Maki'),
  (-2762301, 'Gregory Stemen', 'Gregory', 'Stemen'),
  (-2762300, 'TJ Brown', 'TJ', 'Brown'),
  (-2762299, 'Jim Grueneich', 'Jim', 'Grueneich'),
  (-2762298, 'Mike Brandenburg', 'Mike', 'Brandenburg'),
  (-2762297, 'Craig Headland', 'Craig', 'Headland'),
  (-2762296, 'Don Vigesaa', 'Don', 'Vigesaa'),
  (-2762295, 'Glenn Bosch', 'Glenn', 'Bosch'),
  (-2762294, 'Mike Nathe', 'Mike', 'Nathe'),
  (-2762293, 'Dawson Holle', 'Dawson', 'Holle'),
  (-2762292, 'Karen M. Rohr', 'Karen', 'Rohr'),
  (-2762291, 'Lisa Meier', 'Lisa', 'Meier'),
  (-2762290, 'Pat D. Heinert', 'Pat', 'Heinert'),
  (-2762289, 'Anna S. Novak', 'Anna', 'Novak'),
  (-2762288, 'Bill Tveit', 'Bill', 'Tveit'),
  (-2762287, 'Nathan Toman', 'Nathan', 'Toman'),
  (-2762286, 'Todd Porter', 'Todd', 'Porter'),
  (-2762285, 'Bob Martinson', 'Bob', 'Martinson'),
  (-2762284, 'Karen Karls', 'Karen', 'Karls'),
  (-2762283, 'Dori Hauck', 'Dori', 'Hauck'),
  (-2762282, 'Ty Dressler', 'Ty', 'Dressler'),
  (-2762281, 'Mike Lefor', 'Mike', 'Lefor'),
  (-2762280, 'Vicky Steiner', 'Vicky', 'Steiner'),
  (-2762279, 'Christina Wolff', 'Christina', 'Wolff'),
  (-2762278, 'Dan Ruby', 'Dan', 'Ruby'),
  (-2762277, 'Keith Kempenich', 'Keith', 'Kempenich'),
  (-2762276, 'Mike Schatz', 'Mike', 'Schatz'),
  (-2762275, 'Macy Bolinske', 'Macy', 'Bolinske'),
  (-2762274, 'Matthew Ruby', 'Matthew', 'Ruby'),
  (-2762273, 'Jorin Johnson', 'Jorin', 'Johnson'),
  (-2762272, 'Karen Grindberg', 'Karen', 'Grindberg'),
  (-2762271, 'Doug Osowski', 'Doug', 'Osowski'),
  (-2762270, 'Dustin McNally', 'Dustin', 'McNally'),
  (-2762269, 'Eric J. Murphy', 'Eric', 'Murphy'),
  (-2762268, 'Zachary Ista', 'Zachary', 'Ista'),
  (-2762267, 'Austin Foss', 'Austin', 'Foss'),
  (-2762266, 'Karla Rose Hanson', 'Karla', 'Hanson'),
  (-2762265, 'Carrie McLeod', 'Carrie', 'McLeod'),
  (-2762264, 'Scott Wagner', 'Scott', 'Wagner'),
  (-2762263, 'Desiree Morton', 'Desiree', 'Morton'),
  (-2762262, 'Jim Kasper', 'Jim', 'Kasper'),
  (-2762261, 'Lawrence R. Klemin', 'Lawrence', 'Klemin'),
  (-2762260, 'Mike Motschenbacher', 'Mike', 'Motschenbacher');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'North Dakota Legislative Branch, 69th Legislative Assembly Sep 2026 Special Session member roster, https://ndlegis.gov/assembly/69-2025/special-2/members/members-by-district (convened 2026-09-02); change-checked against all 141 individual member biography pages at https://ndlegis.gov/biography/<member>, every one of which names its own member, chamber and district, and none of which carries a departure marker on a 69th-Assembly row; the same sweep over the CUMULATIVE regular-session roster found all 7 departures, each dated to the day; read 2026-09-25 (ND-2) (CC_0145, ND-2)', true, true
FROM nd_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The one namesake — guard lifted for this statement only ───────────────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE nd_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO nd_namesake_people(external_id, full_name, first_name, last_name) VALUES
  (-2762342, 'Dick Anderson', 'Dick', 'Anderson');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'North Dakota Legislative Branch, 69th Legislative Assembly Sep 2026 Special Session member roster, https://ndlegis.gov/assembly/69-2025/special-2/members/members-by-district (convened 2026-09-02); change-checked against all 141 individual member biography pages at https://ndlegis.gov/biography/<member>, every one of which names its own member, chamber and district, and none of which carries a departure marker on a 69th-Assembly row; the same sweep over the CUMULATIVE regular-session roster found all 7 departures, each dated to the day; read 2026-09-25 (ND-2) (CC_0145, ND-2)', true, true
FROM nd_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 3. The 141 terms ─────────────────────────────────────────────────────────
-- 🔴 Keyed on (geo_id, district_type, slot). '38020' is BOTH Senate District 20 and House
-- District 20, and 24 North Dakota counties also carry a geo_id inside the Senate range, so
-- geo_id alone is never the key. The slot is what resolves the two interchangeable House offices.

CREATE TEMP TABLE nd_terms(
  geo_id text, district_type text, external_id bigint,
  sort_key text, term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO nd_terms(geo_id, district_type, external_id, sort_key, term_start, start_precision, how_started) VALUES
  ('38001', 'STATE_UPPER', -2762400::bigint, 'Brad Bekkedahl', NULL, 'unknown', 'unknown'),
  ('38002', 'STATE_UPPER', -2762399::bigint, 'Mark Enget', NULL, 'unknown', 'unknown'),
  ('38003', 'STATE_UPPER', -2762398::bigint, 'Bob Paulson', NULL, 'unknown', 'unknown'),
  ('38004', 'STATE_UPPER', -2762397::bigint, 'Chuck Walen', NULL, 'unknown', 'unknown'),
  ('38005', 'STATE_UPPER', -2762396::bigint, 'Randy A. Burckhard', NULL, 'unknown', 'unknown'),
  ('38006', 'STATE_UPPER', -2762395::bigint, 'Paul J. Thomas', NULL, 'unknown', 'unknown'),
  ('38007', 'STATE_UPPER', -2762394::bigint, 'Michelle Axtman', NULL, 'unknown', 'unknown'),
  ('38008', 'STATE_UPPER', -2762393::bigint, 'Jeffery J. Magrum', NULL, 'unknown', 'unknown'),
  ('38009', 'STATE_UPPER', -2762392::bigint, 'Richard Marcellais', NULL, 'unknown', 'unknown'),
  ('38010', 'STATE_UPPER', -2762391::bigint, 'Ryan Braunberger', NULL, 'unknown', 'unknown'),
  ('38011', 'STATE_UPPER', -2762390::bigint, 'Tim Mathern', NULL, 'unknown', 'unknown'),
  ('38012', 'STATE_UPPER', -2762389::bigint, 'Cole Conley', NULL, 'unknown', 'unknown'),
  ('38013', 'STATE_UPPER', -2762388::bigint, 'Judy Lee', NULL, 'unknown', 'unknown'),
  ('38014', 'STATE_UPPER', -2762387::bigint, 'Jerry Klein', NULL, 'unknown', 'unknown'),
  ('38015', 'STATE_UPPER', -2762386::bigint, 'Kent Weston', NULL, 'unknown', 'unknown'),
  ('38016', 'STATE_UPPER', -2762385::bigint, 'David A. Clemens', NULL, 'unknown', 'unknown'),
  ('38017', 'STATE_UPPER', -2762384::bigint, 'Jonathan Sickler', NULL, 'unknown', 'unknown'),
  ('38018', 'STATE_UPPER', -2762383::bigint, 'Scott Meyer', NULL, 'unknown', 'unknown'),
  ('38019', 'STATE_UPPER', -2762382::bigint, 'Janne Myrdal', NULL, 'unknown', 'unknown'),
  ('38020', 'STATE_UPPER', -2762381::bigint, 'Randy D. Lemm', NULL, 'unknown', 'unknown'),
  ('38021', 'STATE_UPPER', -2762380::bigint, 'Kathy Hogan', NULL, 'unknown', 'unknown'),
  ('38022', 'STATE_UPPER', -2762379::bigint, 'Mark F. Weber', NULL, 'unknown', 'unknown'),
  ('38023', 'STATE_UPPER', -2762378::bigint, 'Todd Beard', NULL, 'unknown', 'unknown'),
  ('38024', 'STATE_UPPER', -2762377::bigint, 'Mike Wobbema', NULL, 'unknown', 'unknown'),
  ('38025', 'STATE_UPPER', -2762376::bigint, 'Larry Luick', NULL, 'unknown', 'unknown'),
  ('38026', 'STATE_UPPER', -2762375::bigint, 'Dale Patten', NULL, 'unknown', 'unknown'),
  ('38027', 'STATE_UPPER', -2762374::bigint, 'Kristin Roers', NULL, 'unknown', 'unknown'),
  ('38028', 'STATE_UPPER', -2762373::bigint, 'Robert Erbele', NULL, 'unknown', 'unknown'),
  ('38029', 'STATE_UPPER', -2762372::bigint, 'Terry M. Wanzek', NULL, 'unknown', 'unknown'),
  ('38030', 'STATE_UPPER', -2762371::bigint, 'Diane Larson', NULL, 'unknown', 'unknown'),
  ('38031', 'STATE_UPPER', -2762370::bigint, 'Donald Schaible', NULL, 'unknown', 'unknown'),
  ('38032', 'STATE_UPPER', -2762369::bigint, 'Dick Dever', NULL, 'unknown', 'unknown'),
  ('38033', 'STATE_UPPER', -2762368::bigint, 'Keith Boehm', NULL, 'unknown', 'unknown'),
  ('38034', 'STATE_UPPER', -2762367::bigint, 'Justin Gerhardt', NULL, 'unknown', 'unknown'),
  ('38035', 'STATE_UPPER', -2762366::bigint, 'Sean Cleary', NULL, 'unknown', 'unknown'),
  ('38036', 'STATE_UPPER', -2762365::bigint, 'Desiree van Oosting', NULL, 'unknown', 'unknown'),
  ('38037', 'STATE_UPPER', -2762364::bigint, 'Dean Rummel', NULL, 'unknown', 'unknown'),
  ('38038', 'STATE_UPPER', -2762363::bigint, 'David Hogue', NULL, 'unknown', 'unknown'),
  ('38039', 'STATE_UPPER', -2762362::bigint, 'Greg Kessel', NULL, 'unknown', 'unknown'),
  ('38040', 'STATE_UPPER', -2762361::bigint, 'Jose L. Castaneda', NULL, 'unknown', 'unknown'),
  ('38041', 'STATE_UPPER', -2762360::bigint, 'Kyle Davison', NULL, 'unknown', 'unknown'),
  ('38042', 'STATE_UPPER', -2762359::bigint, 'Claire Cory', NULL, 'unknown', 'unknown'),
  ('38043', 'STATE_UPPER', -2762358::bigint, 'Jeff Barta', NULL, 'unknown', 'unknown'),
  ('38044', 'STATE_UPPER', -2762357::bigint, 'Jamie Selzler', DATE '2026-08-05', 'day', 'appointed'),
  ('38045', 'STATE_UPPER', -2762356::bigint, 'Ronald Sorvaag', NULL, 'unknown', 'unknown'),
  ('38046', 'STATE_UPPER', -2762355::bigint, 'Michelle Powers', NULL, 'unknown', 'unknown'),
  ('38047', 'STATE_UPPER', -2762354::bigint, 'Michael Dwyer', NULL, 'unknown', 'unknown'),
  ('38001', 'STATE_LOWER', -2762353::bigint, 'David Richter', NULL, 'unknown', 'unknown'),
  ('38001', 'STATE_LOWER', -2762352::bigint, 'Patrick R. Hatlestad', NULL, 'unknown', 'unknown'),
  ('38002', 'STATE_LOWER', -2762351::bigint, 'Bert Anderson', NULL, 'unknown', 'unknown'),
  ('38002', 'STATE_LOWER', -2762350::bigint, 'Donald W. Longmuir', NULL, 'unknown', 'unknown'),
  ('38003', 'STATE_LOWER', -2762349::bigint, 'Jeff Hoverson', NULL, 'unknown', 'unknown'),
  ('38003', 'STATE_LOWER', -2762348::bigint, 'Lori VanWinkle', NULL, 'unknown', 'unknown'),
  ('3804B', 'STATE_LOWER', -2762347::bigint, 'Clayton Fegley', NULL, 'unknown', 'unknown'),
  ('3804A', 'STATE_LOWER', -2762346::bigint, 'Lisa Finley-DeVille', NULL, 'unknown', 'unknown'),
  ('38005', 'STATE_LOWER', -2762345::bigint, 'Jay Fisher', NULL, 'unknown', 'unknown'),
  ('38005', 'STATE_LOWER', -2762344::bigint, 'Scott Louser', NULL, 'unknown', 'unknown'),
  ('38006', 'STATE_LOWER', -2762343::bigint, 'Daniel R. Vollmer', NULL, 'unknown', 'unknown'),
  ('38006', 'STATE_LOWER', -2762342::bigint, 'Dick Anderson', NULL, 'unknown', 'unknown'),
  ('38007', 'STATE_LOWER', -2762341::bigint, 'Jason Dockter', NULL, 'unknown', 'unknown'),
  ('38007', 'STATE_LOWER', -2762340::bigint, 'Matthew Heilman', NULL, 'unknown', 'unknown'),
  ('38008', 'STATE_LOWER', -2762339::bigint, 'Mike Berg', NULL, 'unknown', 'unknown'),
  ('38008', 'STATE_LOWER', -2762338::bigint, 'SuAnn Olson', NULL, 'unknown', 'unknown'),
  ('38009', 'STATE_LOWER', -2762337::bigint, 'Collette Brown', NULL, 'unknown', 'unknown'),
  ('38009', 'STATE_LOWER', -2762336::bigint, 'Jayme Davis', NULL, 'unknown', 'unknown'),
  ('38010', 'STATE_LOWER', -2762335::bigint, 'Jared Hendrix', NULL, 'unknown', 'unknown'),
  ('38010', 'STATE_LOWER', -2762334::bigint, 'Steve Swiontek', NULL, 'unknown', 'unknown'),
  ('38011', 'STATE_LOWER', -2762333::bigint, 'Adam Goldwyn', DATE '2026-06-01', 'day', 'appointed'),
  ('38011', 'STATE_LOWER', -2762332::bigint, 'Gretchen Dobervich', NULL, 'unknown', 'unknown'),
  ('38012', 'STATE_LOWER', -2762331::bigint, 'Bernie Satrom', NULL, 'unknown', 'unknown'),
  ('38012', 'STATE_LOWER', -2762330::bigint, 'Mitch Ostlie', NULL, 'unknown', 'unknown'),
  ('38013', 'STATE_LOWER', -2762329::bigint, 'Austen Schauer', NULL, 'unknown', 'unknown'),
  ('38013', 'STATE_LOWER', -2762328::bigint, 'Jim Jonas', NULL, 'unknown', 'unknown'),
  ('38014', 'STATE_LOWER', -2762327::bigint, 'Jon O. Nelson', NULL, 'unknown', 'unknown'),
  ('38014', 'STATE_LOWER', -2762326::bigint, 'Robin Weisz', NULL, 'unknown', 'unknown'),
  ('38015', 'STATE_LOWER', -2762325::bigint, 'Donna Henderson', NULL, 'unknown', 'unknown'),
  ('38015', 'STATE_LOWER', -2762324::bigint, 'Kathy Frelich', NULL, 'unknown', 'unknown'),
  ('38016', 'STATE_LOWER', -2762323::bigint, 'Andrew Marschall', NULL, 'unknown', 'unknown'),
  ('38016', 'STATE_LOWER', -2762322::bigint, 'Ben Koppelman', NULL, 'unknown', 'unknown'),
  ('38017', 'STATE_LOWER', -2762321::bigint, 'Landon Bahl', NULL, 'unknown', 'unknown'),
  ('38017', 'STATE_LOWER', -2762320::bigint, 'Mark Sanford', NULL, 'unknown', 'unknown'),
  ('38018', 'STATE_LOWER', -2762319::bigint, 'Nels Christianson', NULL, 'unknown', 'unknown'),
  ('38018', 'STATE_LOWER', -2762318::bigint, 'Steve Vetter', NULL, 'unknown', 'unknown'),
  ('38019', 'STATE_LOWER', -2762317::bigint, 'David Monson', NULL, 'unknown', 'unknown'),
  ('38019', 'STATE_LOWER', -2762316::bigint, 'Karen A. Anderson', NULL, 'unknown', 'unknown'),
  ('38020', 'STATE_LOWER', -2762315::bigint, 'Dave Rustebakke', DATE '2026-04-21', 'day', 'appointed'),
  ('38020', 'STATE_LOWER', -2762314::bigint, 'Mike Beltz', NULL, 'unknown', 'unknown'),
  ('38021', 'STATE_LOWER', -2762313::bigint, 'LaurieBeth Hager', NULL, 'unknown', 'unknown'),
  ('38021', 'STATE_LOWER', -2762312::bigint, 'Mary Schneider', NULL, 'unknown', 'unknown'),
  ('38022', 'STATE_LOWER', -2762311::bigint, 'Brandy L. Pyle', NULL, 'unknown', 'unknown'),
  ('38022', 'STATE_LOWER', -2762310::bigint, 'Jonathan Warrey', NULL, 'unknown', 'unknown'),
  ('38023', 'STATE_LOWER', -2762309::bigint, 'Dennis Nehring', NULL, 'unknown', 'unknown'),
  ('38023', 'STATE_LOWER', -2762308::bigint, 'Nico Rios', NULL, 'unknown', 'unknown'),
  ('38024', 'STATE_LOWER', -2762307::bigint, 'Daniel Johnston', NULL, 'unknown', 'unknown'),
  ('38024', 'STATE_LOWER', -2762306::bigint, 'Dwight Kiefert', NULL, 'unknown', 'unknown'),
  ('38025', 'STATE_LOWER', -2762305::bigint, 'Alisa Mitskog', NULL, 'unknown', 'unknown'),
  ('38025', 'STATE_LOWER', -2762304::bigint, 'Kathy Skroch', DATE '2025-09-10', 'day', 'appointed'),
  ('38026', 'STATE_LOWER', -2762303::bigint, 'Kelby Timmons', DATE '2025-05-29', 'day', 'appointed'),
  ('38026', 'STATE_LOWER', -2762302::bigint, 'Roger A. Maki', NULL, 'unknown', 'unknown'),
  ('38027', 'STATE_LOWER', -2762301::bigint, 'Gregory Stemen', NULL, 'unknown', 'unknown'),
  ('38027', 'STATE_LOWER', -2762300::bigint, 'TJ Brown', DATE '2025-03-10', 'day', 'appointed'),
  ('38028', 'STATE_LOWER', -2762299::bigint, 'Jim Grueneich', NULL, 'unknown', 'unknown'),
  ('38028', 'STATE_LOWER', -2762298::bigint, 'Mike Brandenburg', NULL, 'unknown', 'unknown'),
  ('38029', 'STATE_LOWER', -2762297::bigint, 'Craig Headland', NULL, 'unknown', 'unknown'),
  ('38029', 'STATE_LOWER', -2762296::bigint, 'Don Vigesaa', NULL, 'unknown', 'unknown'),
  ('38030', 'STATE_LOWER', -2762295::bigint, 'Glenn Bosch', NULL, 'unknown', 'unknown'),
  ('38030', 'STATE_LOWER', -2762294::bigint, 'Mike Nathe', NULL, 'unknown', 'unknown'),
  ('38031', 'STATE_LOWER', -2762293::bigint, 'Dawson Holle', NULL, 'unknown', 'unknown'),
  ('38031', 'STATE_LOWER', -2762292::bigint, 'Karen M. Rohr', NULL, 'unknown', 'unknown'),
  ('38032', 'STATE_LOWER', -2762291::bigint, 'Lisa Meier', NULL, 'unknown', 'unknown'),
  ('38032', 'STATE_LOWER', -2762290::bigint, 'Pat D. Heinert', NULL, 'unknown', 'unknown'),
  ('38033', 'STATE_LOWER', -2762289::bigint, 'Anna S. Novak', NULL, 'unknown', 'unknown'),
  ('38033', 'STATE_LOWER', -2762288::bigint, 'Bill Tveit', NULL, 'unknown', 'unknown'),
  ('38034', 'STATE_LOWER', -2762287::bigint, 'Nathan Toman', NULL, 'unknown', 'unknown'),
  ('38034', 'STATE_LOWER', -2762286::bigint, 'Todd Porter', NULL, 'unknown', 'unknown'),
  ('38035', 'STATE_LOWER', -2762285::bigint, 'Bob Martinson', NULL, 'unknown', 'unknown'),
  ('38035', 'STATE_LOWER', -2762284::bigint, 'Karen Karls', NULL, 'unknown', 'unknown'),
  ('38036', 'STATE_LOWER', -2762283::bigint, 'Dori Hauck', NULL, 'unknown', 'unknown'),
  ('38036', 'STATE_LOWER', -2762282::bigint, 'Ty Dressler', NULL, 'unknown', 'unknown'),
  ('38037', 'STATE_LOWER', -2762281::bigint, 'Mike Lefor', NULL, 'unknown', 'unknown'),
  ('38037', 'STATE_LOWER', -2762280::bigint, 'Vicky Steiner', NULL, 'unknown', 'unknown'),
  ('38038', 'STATE_LOWER', -2762279::bigint, 'Christina Wolff', NULL, 'unknown', 'unknown'),
  ('38038', 'STATE_LOWER', -2762278::bigint, 'Dan Ruby', NULL, 'unknown', 'unknown'),
  ('38039', 'STATE_LOWER', -2762277::bigint, 'Keith Kempenich', NULL, 'unknown', 'unknown'),
  ('38039', 'STATE_LOWER', -2762276::bigint, 'Mike Schatz', NULL, 'unknown', 'unknown'),
  ('38040', 'STATE_LOWER', -2762275::bigint, 'Macy Bolinske', NULL, 'unknown', 'unknown'),
  ('38040', 'STATE_LOWER', -2762274::bigint, 'Matthew Ruby', NULL, 'unknown', 'unknown'),
  ('38041', 'STATE_LOWER', -2762273::bigint, 'Jorin Johnson', NULL, 'unknown', 'unknown'),
  ('38041', 'STATE_LOWER', -2762272::bigint, 'Karen Grindberg', DATE '2024-12-01', 'day', 'appointed'),
  ('38042', 'STATE_LOWER', -2762271::bigint, 'Doug Osowski', NULL, 'unknown', 'unknown'),
  ('38042', 'STATE_LOWER', -2762270::bigint, 'Dustin McNally', DATE '2025-09-19', 'day', 'appointed'),
  ('38043', 'STATE_LOWER', -2762269::bigint, 'Eric J. Murphy', NULL, 'unknown', 'unknown'),
  ('38043', 'STATE_LOWER', -2762268::bigint, 'Zachary Ista', NULL, 'unknown', 'unknown'),
  ('38044', 'STATE_LOWER', -2762267::bigint, 'Austin Foss', NULL, 'unknown', 'unknown'),
  ('38044', 'STATE_LOWER', -2762266::bigint, 'Karla Rose Hanson', NULL, 'unknown', 'unknown'),
  ('38045', 'STATE_LOWER', -2762265::bigint, 'Carrie McLeod', NULL, 'unknown', 'unknown'),
  ('38045', 'STATE_LOWER', -2762264::bigint, 'Scott Wagner', NULL, 'unknown', 'unknown'),
  ('38046', 'STATE_LOWER', -2762263::bigint, 'Desiree Morton', NULL, 'unknown', 'unknown'),
  ('38046', 'STATE_LOWER', -2762262::bigint, 'Jim Kasper', NULL, 'unknown', 'unknown'),
  ('38047', 'STATE_LOWER', -2762261::bigint, 'Lawrence R. Klemin', NULL, 'unknown', 'unknown'),
  ('38047', 'STATE_LOWER', -2762260::bigint, 'Mike Motschenbacher', NULL, 'unknown', 'unknown');

WITH office_slots AS (
  SELECT o.id AS office_id, d.geo_id, d.district_type::text AS dt,
         row_number() OVER (PARTITION BY o.district_id ORDER BY o.id) AS slot
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
),
member_slots AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.geo_id, t.district_type ORDER BY t.sort_key) AS slot
  FROM nd_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, ms.term_start, NULL, ms.start_precision, ms.how_started, 'North Dakota Legislative Branch, 69th Legislative Assembly Sep 2026 Special Session member roster, https://ndlegis.gov/assembly/69-2025/special-2/members/members-by-district (convened 2026-09-02); change-checked against all 141 individual member biography pages at https://ndlegis.gov/biography/<member>, every one of which names its own member, chamber and district, and none of which carries a departure marker on a 69th-Assembly row; the same sweep over the CUMULATIVE regular-session roster found all 7 departures, each dated to the day; read 2026-09-25 (ND-2) (CC_0145, ND-2)'
FROM member_slots ms
JOIN office_slots os
  ON os.geo_id = ms.geo_id AND os.dt = ms.district_type AND os.slot = ms.slot
JOIN essentials.politicians p ON p.external_id = ms.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people    int;
  v_offices   int;
  v_terms     int;
  v_seated    int;
  v_dated     int;
  v_ended     int;
  v_unseated  int;
  v_two       int;
  v_gf        int;
  v_dup       int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2762400 AND -2762260;
  IF v_people <> 141 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 141 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_offices <> 141 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 141 ND legislative offices from CC_0144, got %', v_offices;
  END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_terms <> 141 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 141 terms, got %', v_terms;
  END IF;

  -- 🔴 Count och.politician_id, never rows: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id rather than an absent row and count(*) passes vacuously.
  SELECT count(och.politician_id) INTO v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_seated <> 141 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 141 seated ND legislative offices, got %', v_seated;
  END IF;

  -- Exactly the eight dated arrivals, and nothing else carries a date.
  SELECT count(*) FILTER (WHERE ot.term_start IS NOT NULL AND ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_dated <> 8 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected exactly 8 day-precision ND terms (the published Active dates), got %', v_dated;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'ND-2 occupancy: % ND term(s) carry a term_end — a future end self-vacates a seat', v_ended;
  END IF;

  -- No office left unseated.
  SELECT count(*) INTO v_unseated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
    AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);
  IF v_unseated <> 0 THEN
    RAISE EXCEPTION 'ND-2 occupancy: % ND legislative office(s) hold no term', v_unseated;
  END IF;

  -- 🔴 THE MULTI-MEMBER ASSERTION. Every whole House district must resolve to TWO DIFFERENT
  -- people; the subdistricts to one each. Two terms naming the SAME person would satisfy a count.
  SELECT count(*) INTO v_two
  FROM essentials.districts d
  WHERE lower(d.state) = 'nd' AND d.district_type::text = 'STATE_LOWER'
    AND d.geo_id NOT IN ('3804A', '3804B')
    AND (SELECT count(DISTINCT och.politician_id)
           FROM essentials.offices o
           JOIN essentials.office_current_holder och ON och.office_id = o.id
          WHERE o.district_id = d.id) <> 2;
  IF v_two <> 0 THEN
    RAISE EXCEPTION 'ND-2 occupancy: % whole House district(s) do not hold exactly 2 DISTINCT holders', v_two;
  END IF;

  -- 🔴 Nobody holds two North Dakota legislative seats. The exclusion constraint forbids two
  -- people on one office; it cannot see one person on two, which is the CLAUDE.md fan-out.
  SELECT count(*) INTO v_dup
  FROM (SELECT och.politician_id
          FROM essentials.office_current_holder och
          JOIN essentials.offices o ON o.id = och.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
           AND och.politician_id IS NOT NULL
         GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'ND-2 occupancy: % person/people hold more than one ND legislative seat', v_dup;
  END IF;

  -- 🟢 This slice's own jurisdiction: Grand Forks city spans four districts (17, 18, 42, 43), so
  -- a Grand Forks address must be able to reach 4 senators and 8 representatives.
  SELECT count(och.politician_id) INTO v_gf
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'nd'
    AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
    AND d.geo_id IN ('38017', '38018', '38042', '38043');
  IF v_gf <> 12 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 12 seated offices across Grand Forks 4 districts (4 senators + 8 representatives), got %', v_gf;
  END IF;

  RAISE NOTICE 'ND-2 occupancy gate PASSED: 141 people, 141 offices, 141 terms, 141 seated, 8 dated, 0 ended, every whole House district holds 2 distinct members, nobody holds two seats, Grand Forks reaches 12.';
END $$;

COMMIT;
