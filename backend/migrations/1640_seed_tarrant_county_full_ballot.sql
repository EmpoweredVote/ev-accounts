-- 1640: seed the remaining 42 Tarrant County contests on the Nov 3 2026 ballot.
--
-- Completes what 1636 started. 1636 covered only the 3 contests whose offices already
-- existed (County Judge, Commissioner Pct 2, Commissioner Pct 4). The other 42 had NO
-- office rows at all, so this creates the offices, their chambers, the races, and the
-- candidates -- 7 chambers, 42 offices, 42 races, 60 candidates, 60 new politicians.
--
-- CHAMBER MODEL follows Racine County, Wisconsin, which is the closest existing precedent:
--   County Board                 -> governing body      (Tarrant: Commissioners Court, exists)
--   Countywide Elected Officials -> Clerk / DA / etc.   (also used by Deschutes County, OR)
--   Circuit Court                -> the judges          (Tarrant: one chamber per court type)
--
-- 🔑 THE 13 'Nth District Court' SEATS ARE TEXAS STATE COURTS, and they are modelled here
-- under the COUNTY government on purpose. Wisconsin circuit courts are likewise state trial
-- courts, and Racine County models them under the county. The rule is that geo_id encodes
-- WHO VOTES, not which level of government owns the office: only Tarrant voters elect these
-- judges, so all 42 offices reuse the existing Tarrant County district row
--   0d533885-23fb-4f13-8084-fe01dc57372b  (COUNTY / geo_id 48439 / G4020)
-- Using the Texas statewide geofence ('48') would surface Tarrant's judges to every voter
-- in Texas. Compare Indiana in essentials.districts: statewide retentions use geo_id '18',
-- but 'Greene County Superior Court Judge' uses '18055'.
--
-- NO district rows are created for the 8 JP precincts. Tarrant has exactly two geofences --
-- the county and one unrelated town -- so a JP-precinct geo_id would be backed by nothing,
-- and a district whose geo_id matches no geofence renders the office INVISIBLE rather than
-- erroring (the failure behind the 504 NULL-geo_id CA judicial rows). The 4 commissioner
-- precincts already share the county district row, so this is the established convention.
-- Consequence, accepted: a Tarrant voter sees all 8 JP races though they vote in one.
-- Over-showing is visible and fixable; under-showing is silent. Real fix = load precinct
-- geofences from Tarrant GIS first, then split the districts.
--
-- ⚠ 'David Cook', the Criminal Court No. 1 incumbent, is NOT the David Cook already in
-- essentials.politicians (a Texas State Representative with 7 compass answers). A separate
-- record is created deliberately -- linking them would graft a legislator's compass record
-- onto a judicial race. He was the ONLY name collision among all 60 candidates.
--
-- OCCUPANCY: the 35 candidates Ballotpedia marks as incumbents are seeded as current
-- officeholders. ⚠ 7 seats have NO incumbent on the ballot (the sitting judge is not seeking
-- re-election), so their current occupant is unknown to us: those offices get is_vacant=false
-- with no holder. DO NOT read the missing holder as a vacancy -- that is the exact mistake
-- 1628 made for Euless. Sourcing those 7 occupants is a follow-up.
--
-- Source: https://ballotpedia.org/Municipal_elections_in_Tarrant_County,_Texas_(2026)
-- fetched 2026-08-09. Ballotpedia carries a standing 'list may not be complete' notice; the
-- March 3 primaries are decided so major-party nominees are settled. last_verified_at stamped.

BEGIN;

DO $$
DECLARE v_gov uuid; v_extra int;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE name = 'Tarrant County, Texas, US';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'Pre-flight FAILED: Tarrant County government missing'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'TX 2026 Statewide General') THEN
    RAISE EXCEPTION 'Pre-flight FAILED: election missing'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.districts WHERE id = '0d533885-23fb-4f13-8084-fe01dc57372b') THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Tarrant County district row missing'; END IF;
  SELECT count(*) INTO v_extra FROM essentials.chambers
   WHERE government_id = v_gov AND name <> 'Commissioners Court';
  IF v_extra <> 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: % extra Tarrant chambers exist - already applied?', v_extra; END IF;
END $$;

-- 1. Seven chambers.
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), v.name, v.formal,
       (SELECT id FROM essentials.governments WHERE name = 'Tarrant County, Texas, US'), v.cnt
FROM (VALUES
  ('Countywide Elected Officials','Tarrant County Elected Officials',3),
  ('County Courts at Law','Tarrant County Courts at Law',3),
  ('County Criminal Courts','Tarrant County Criminal Courts',10),
  ('Criminal District Courts','Tarrant County Criminal District Courts',3),
  ('District Courts','Texas District Courts serving Tarrant County',13),
  ('Justice Courts','Tarrant County Justice Courts',8),
  ('Probate Courts','Tarrant County Probate Courts',2)
) AS v(name, formal, cnt);

-- 2. Forty-two offices, all on the county district row (see header).
INSERT INTO essentials.offices
  (id, chamber_id, district_id, title, representing_state, representing_city, seats,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), c.id, '0d533885-23fb-4f13-8084-fe01dc57372b', v.title, 'TX', NULL, 1, false, false, NULL
FROM (VALUES
  ('Countywide Elected Officials','County Clerk'),
  ('Countywide Elected Officials','District Attorney'),
  ('Countywide Elected Officials','District Clerk'),
  ('County Courts at Law','Judge, County Court at Law No. 1'),
  ('County Courts at Law','Judge, County Court at Law No. 2'),
  ('County Courts at Law','Judge, County Court at Law No. 3'),
  ('County Criminal Courts','Judge, County Criminal Court No. 1'),
  ('County Criminal Courts','Judge, County Criminal Court No. 2'),
  ('County Criminal Courts','Judge, County Criminal Court No. 3'),
  ('County Criminal Courts','Judge, County Criminal Court No. 4'),
  ('County Criminal Courts','Judge, County Criminal Court No. 5'),
  ('County Criminal Courts','Judge, County Criminal Court No. 6'),
  ('County Criminal Courts','Judge, County Criminal Court No. 7'),
  ('County Criminal Courts','Judge, County Criminal Court No. 8'),
  ('County Criminal Courts','Judge, County Criminal Court No. 9'),
  ('County Criminal Courts','Judge, County Criminal Court No. 10'),
  ('Criminal District Courts','Judge, Criminal District Court No. 1'),
  ('Criminal District Courts','Judge, Criminal District Court No. 3'),
  ('Criminal District Courts','Judge, Criminal District Court No. 4'),
  ('District Courts','Judge, 141st District Court'),
  ('District Courts','Judge, 231st District Court'),
  ('District Courts','Judge, 233rd District Court'),
  ('District Courts','Judge, 236th District Court'),
  ('District Courts','Judge, 297th District Court'),
  ('District Courts','Judge, 322nd District Court'),
  ('District Courts','Judge, 323rd District Court'),
  ('District Courts','Judge, 324th District Court'),
  ('District Courts','Judge, 325th District Court'),
  ('District Courts','Judge, 371st District Court'),
  ('District Courts','Judge, 372nd District Court'),
  ('District Courts','Judge, 432nd District Court'),
  ('District Courts','Judge, 485th District Court'),
  ('Justice Courts','Justice of the Peace, Precinct 1'),
  ('Justice Courts','Justice of the Peace, Precinct 2'),
  ('Justice Courts','Justice of the Peace, Precinct 3'),
  ('Justice Courts','Justice of the Peace, Precinct 4'),
  ('Justice Courts','Justice of the Peace, Precinct 5'),
  ('Justice Courts','Justice of the Peace, Precinct 6'),
  ('Justice Courts','Justice of the Peace, Precinct 7'),
  ('Justice Courts','Justice of the Peace, Precinct 8'),
  ('Probate Courts','Judge, Probate Court No. 1'),
  ('Probate Courts','Judge, Probate Court No. 2')
) AS v(chamber, title)
JOIN essentials.chambers c ON c.name = v.chamber
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'Tarrant County, Texas, US';

-- 3. Sixty candidate records. is_incumbent set EXPLICITLY -- the column defaults to true,
--    which would silently mislabel all 25 challengers.
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_incumbent, is_vacant, office_id, data_source)
SELECT gen_random_uuid(), v.fullname, v.fname, v.lname, NULL, true, v.inc, false, NULL, 'Tarrant County full-ballot seed 2026-08-09; Ballotpedia Municipal elections in Tarrant County, Texas (2026)'
FROM (VALUES
  ('Mary Louise Nicholson','Mary','Nicholson',true),
  ('Lydia Bean','Lydia','Bean',false),
  ('Phil Sorrells','Phil','Sorrells',true),
  ('Tiffany Burks','Tiffany','Burks',false),
  ('Thomas Wilder','Thomas','Wilder',true),
  ('Nathan Smith','Nathan','Smith',false),
  ('Don Pierson','Don','Pierson',true),
  ('Jennifer Rymell','Jennifer','Rymell',true),
  ('Mike Hrabal','Mike','Hrabal',true),
  ('David Cook','David','Cook',true),
  ('Carey Walker','Carey','Walker',true),
  ('Bob McCoy','Bob','McCoy',true),
  ('Deborah Nekhom','Deborah','Nekhom',true),
  ('Julya Billhymer','Julya','Billhymer',false),
  ('Brad Clark','Brad','Clark',true),
  ('Randi Hartin','Randi','Hartin',true),
  ('Eric Starnes','Eric','Starnes',true),
  ('Charles Vanover','Charles','Vanover',true),
  ('Lesa Pamplin','Lesa','Pamplin',false),
  ('Brian Bolton','Brian','Bolton',true),
  ('Trent Loftin','Trent','Loftin',true),
  ('Cindy Stormer','Cindy','Stormer',false),
  ('Sherri Wagner','Sherri','Wagner',false),
  ('Douglas A. Allen','Douglas','Allen',true),
  ('John Brender','John','Brender',false),
  ('Andy Porter','Andy','Porter',true),
  ('John P. Chupp','John','Chupp',true),
  ('Lyndsay Newell','Lyndsay','Newell',false),
  ('Leslie Barrows','Leslie','Barrows',false),
  ('Kenneth Newell','Kenneth','Newell',true),
  ('Katherine Kim','Katherine','Kim',false),
  ('Dusty Fillmore','Dusty','Fillmore',false),
  ('Fred Howey','Fred','Howey',false),
  ('Amy Allin','Amy','Allin',true),
  ('James Munford','James','Munford',true),
  ('Brian Willett','Brian','Willett',false),
  ('Alex Kim','Alex','Kim',true),
  ('Crystal Gayden','Crystal','Gayden',false),
  ('Andy Hsu','Andy','Hsu',false),
  ('Andy Griffin','Andy','Griffin',false),
  ('Cynthia Terry','Cynthia','Terry',true),
  ('Marq Clayton','Marq','Clayton',false),
  ('Ryan Hill','Ryan','Hill',true),
  ('Julie Lugo','Julie','Lugo',true),
  ('Courtney Miller','Courtney','Miller',false),
  ('Lee Sorrells','Lee','Sorrells',false),
  ('Steven Jumes','Steven','Jumes',true),
  ('Ricky Rodriguez','Ricky','Rodriguez',false),
  ('Celina Vasquez','Celina','Vasquez',false),
  ('Mary Tom Curnutt','Mary','Curnutt',true),
  ('Bill Brandt','Bill','Brandt',true),
  ('Rodney Lee','Rodney','Lee',false),
  ('Christopher Gregory','Christopher','Gregory',true),
  ('Sergio De Leon','Sergio','De Leon',true),
  ('Jason Charbonnet','Jason','Charbonnet',true),
  ('Kenneth Sanders','Kenneth','Sanders',true),
  ('Paige Payne-Neal','Paige','Payne-Neal',false),
  ('Lisa Woodard','Lisa','Woodard',true),
  ('Patricia Burns','Patricia','Burns',true),
  ('Brook Bell','Brook','Bell',false)
) AS v(fullname, fname, lname, inc);

-- 4. Occupancy for the 35 incumbents (header explains the 7 unknown seats).
INSERT INTO essentials.office_terms
  (id, office_id, politician_id, term_start, term_end, start_precision, source)
SELECT gen_random_uuid(), o.id, p.id, NULL, NULL, 'day', 'Tarrant County full-ballot seed 2026-08-09; Ballotpedia Municipal elections in Tarrant County, Texas (2026)'
FROM (VALUES
  ('County Clerk','Mary Louise Nicholson'),
  ('District Attorney','Phil Sorrells'),
  ('District Clerk','Thomas Wilder'),
  ('Judge, County Court at Law No. 1','Don Pierson'),
  ('Judge, County Court at Law No. 2','Jennifer Rymell'),
  ('Judge, County Court at Law No. 3','Mike Hrabal'),
  ('Judge, County Criminal Court No. 1','David Cook'),
  ('Judge, County Criminal Court No. 2','Carey Walker'),
  ('Judge, County Criminal Court No. 3','Bob McCoy'),
  ('Judge, County Criminal Court No. 4','Deborah Nekhom'),
  ('Judge, County Criminal Court No. 5','Brad Clark'),
  ('Judge, County Criminal Court No. 6','Randi Hartin'),
  ('Judge, County Criminal Court No. 7','Eric Starnes'),
  ('Judge, County Criminal Court No. 8','Charles Vanover'),
  ('Judge, County Criminal Court No. 9','Brian Bolton'),
  ('Judge, County Criminal Court No. 10','Trent Loftin'),
  ('Judge, Criminal District Court No. 3','Douglas A. Allen'),
  ('Judge, Criminal District Court No. 4','Andy Porter'),
  ('Judge, 141st District Court','John P. Chupp'),
  ('Judge, 233rd District Court','Kenneth Newell'),
  ('Judge, 297th District Court','Amy Allin'),
  ('Judge, 322nd District Court','James Munford'),
  ('Judge, 323rd District Court','Alex Kim'),
  ('Judge, 325th District Court','Cynthia Terry'),
  ('Judge, 371st District Court','Ryan Hill'),
  ('Judge, 372nd District Court','Julie Lugo'),
  ('Judge, 485th District Court','Steven Jumes'),
  ('Justice of the Peace, Precinct 2','Mary Tom Curnutt'),
  ('Justice of the Peace, Precinct 3','Bill Brandt'),
  ('Justice of the Peace, Precinct 4','Christopher Gregory'),
  ('Justice of the Peace, Precinct 5','Sergio De Leon'),
  ('Justice of the Peace, Precinct 6','Jason Charbonnet'),
  ('Justice of the Peace, Precinct 7','Kenneth Sanders'),
  ('Justice of the Peace, Precinct 8','Lisa Woodard'),
  ('Judge, Probate Court No. 1','Patricia Burns')
) AS v(otitle, pname)
JOIN essentials.offices o ON o.title = v.otitle
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'Tarrant County, Texas, US'
JOIN essentials.politicians p ON p.full_name = v.pname AND p.data_source = 'Tarrant County full-ballot seed 2026-08-09; Ballotpedia Municipal elections in Tarrant County, Texas (2026)';

-- 5. Forty-two races on the existing statewide general row.
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT gen_random_uuid(), (SELECT id FROM essentials.elections WHERE name = 'TX 2026 Statewide General'),
       o.id, v.pos, NULL, 1
FROM (VALUES
  ('County Clerk','Tarrant County Clerk'),
  ('District Attorney','Tarrant County District Attorney'),
  ('District Clerk','Tarrant County District Clerk'),
  ('Judge, County Court at Law No. 1','Tarrant County Court at Law No. 1'),
  ('Judge, County Court at Law No. 2','Tarrant County Court at Law No. 2'),
  ('Judge, County Court at Law No. 3','Tarrant County Court at Law No. 3'),
  ('Judge, County Criminal Court No. 1','Tarrant County Criminal Court No. 1'),
  ('Judge, County Criminal Court No. 2','Tarrant County Criminal Court No. 2'),
  ('Judge, County Criminal Court No. 3','Tarrant County Criminal Court No. 3'),
  ('Judge, County Criminal Court No. 4','Tarrant County Criminal Court No. 4'),
  ('Judge, County Criminal Court No. 5','Tarrant County Criminal Court No. 5'),
  ('Judge, County Criminal Court No. 6','Tarrant County Criminal Court No. 6'),
  ('Judge, County Criminal Court No. 7','Tarrant County Criminal Court No. 7'),
  ('Judge, County Criminal Court No. 8','Tarrant County Criminal Court No. 8'),
  ('Judge, County Criminal Court No. 9','Tarrant County Criminal Court No. 9'),
  ('Judge, County Criminal Court No. 10','Tarrant County Criminal Court No. 10'),
  ('Judge, Criminal District Court No. 1','Tarrant County Criminal District Court No. 1'),
  ('Judge, Criminal District Court No. 3','Tarrant County Criminal District Court No. 3'),
  ('Judge, Criminal District Court No. 4','Tarrant County Criminal District Court No. 4'),
  ('Judge, 141st District Court','Texas 141st District Court'),
  ('Judge, 231st District Court','Texas 231st District Court'),
  ('Judge, 233rd District Court','Texas 233rd District Court'),
  ('Judge, 236th District Court','Texas 236th District Court'),
  ('Judge, 297th District Court','Texas 297th District Court'),
  ('Judge, 322nd District Court','Texas 322nd District Court'),
  ('Judge, 323rd District Court','Texas 323rd District Court'),
  ('Judge, 324th District Court','Texas 324th District Court'),
  ('Judge, 325th District Court','Texas 325th District Court'),
  ('Judge, 371st District Court','Texas 371st District Court'),
  ('Judge, 372nd District Court','Texas 372nd District Court'),
  ('Judge, 432nd District Court','Texas 432nd District Court'),
  ('Judge, 485th District Court','Texas 485th District Court'),
  ('Justice of the Peace, Precinct 1','Tarrant County Justice of the Peace Precinct 1'),
  ('Justice of the Peace, Precinct 2','Tarrant County Justice of the Peace Precinct 2'),
  ('Justice of the Peace, Precinct 3','Tarrant County Justice of the Peace Precinct 3'),
  ('Justice of the Peace, Precinct 4','Tarrant County Justice of the Peace Precinct 4'),
  ('Justice of the Peace, Precinct 5','Tarrant County Justice of the Peace Precinct 5'),
  ('Justice of the Peace, Precinct 6','Tarrant County Justice of the Peace Precinct 6'),
  ('Justice of the Peace, Precinct 7','Tarrant County Justice of the Peace Precinct 7'),
  ('Justice of the Peace, Precinct 8','Tarrant County Justice of the Peace Precinct 8'),
  ('Judge, Probate Court No. 1','Tarrant County Probate Court No. 1'),
  ('Judge, Probate Court No. 2','Tarrant County Probate Court No. 2')
) AS v(otitle, pos)
JOIN essentials.offices o ON o.title = v.otitle
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'Tarrant County, Texas, US';

-- 6. Sixty candidates, every one linked to its politician row.
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, last_verified_at, source)
SELECT gen_random_uuid(), r.id, p.id, v.fullname, v.fname, v.lname, v.inc, 'active', now(), 'Tarrant County full-ballot seed 2026-08-09; Ballotpedia Municipal elections in Tarrant County, Texas (2026)'
FROM (VALUES
  ('Tarrant County Clerk','Mary Louise Nicholson','Mary','Nicholson',true),
  ('Tarrant County Clerk','Lydia Bean','Lydia','Bean',false),
  ('Tarrant County District Attorney','Phil Sorrells','Phil','Sorrells',true),
  ('Tarrant County District Attorney','Tiffany Burks','Tiffany','Burks',false),
  ('Tarrant County District Clerk','Thomas Wilder','Thomas','Wilder',true),
  ('Tarrant County District Clerk','Nathan Smith','Nathan','Smith',false),
  ('Tarrant County Court at Law No. 1','Don Pierson','Don','Pierson',true),
  ('Tarrant County Court at Law No. 2','Jennifer Rymell','Jennifer','Rymell',true),
  ('Tarrant County Court at Law No. 3','Mike Hrabal','Mike','Hrabal',true),
  ('Tarrant County Criminal Court No. 1','David Cook','David','Cook',true),
  ('Tarrant County Criminal Court No. 2','Carey Walker','Carey','Walker',true),
  ('Tarrant County Criminal Court No. 3','Bob McCoy','Bob','McCoy',true),
  ('Tarrant County Criminal Court No. 4','Deborah Nekhom','Deborah','Nekhom',true),
  ('Tarrant County Criminal Court No. 5','Julya Billhymer','Julya','Billhymer',false),
  ('Tarrant County Criminal Court No. 5','Brad Clark','Brad','Clark',true),
  ('Tarrant County Criminal Court No. 6','Randi Hartin','Randi','Hartin',true),
  ('Tarrant County Criminal Court No. 7','Eric Starnes','Eric','Starnes',true),
  ('Tarrant County Criminal Court No. 8','Charles Vanover','Charles','Vanover',true),
  ('Tarrant County Criminal Court No. 9','Lesa Pamplin','Lesa','Pamplin',false),
  ('Tarrant County Criminal Court No. 9','Brian Bolton','Brian','Bolton',true),
  ('Tarrant County Criminal Court No. 10','Trent Loftin','Trent','Loftin',true),
  ('Tarrant County Criminal District Court No. 1','Cindy Stormer','Cindy','Stormer',false),
  ('Tarrant County Criminal District Court No. 1','Sherri Wagner','Sherri','Wagner',false),
  ('Tarrant County Criminal District Court No. 3','Douglas A. Allen','Douglas','Allen',true),
  ('Tarrant County Criminal District Court No. 4','John Brender','John','Brender',false),
  ('Tarrant County Criminal District Court No. 4','Andy Porter','Andy','Porter',true),
  ('Texas 141st District Court','John P. Chupp','John','Chupp',true),
  ('Texas 231st District Court','Lyndsay Newell','Lyndsay','Newell',false),
  ('Texas 231st District Court','Leslie Barrows','Leslie','Barrows',false),
  ('Texas 233rd District Court','Kenneth Newell','Kenneth','Newell',true),
  ('Texas 236th District Court','Katherine Kim','Katherine','Kim',false),
  ('Texas 236th District Court','Dusty Fillmore','Dusty','Fillmore',false),
  ('Texas 297th District Court','Fred Howey','Fred','Howey',false),
  ('Texas 297th District Court','Amy Allin','Amy','Allin',true),
  ('Texas 322nd District Court','James Munford','James','Munford',true),
  ('Texas 323rd District Court','Brian Willett','Brian','Willett',false),
  ('Texas 323rd District Court','Alex Kim','Alex','Kim',true),
  ('Texas 324th District Court','Crystal Gayden','Crystal','Gayden',false),
  ('Texas 324th District Court','Andy Hsu','Andy','Hsu',false),
  ('Texas 325th District Court','Andy Griffin','Andy','Griffin',false),
  ('Texas 325th District Court','Cynthia Terry','Cynthia','Terry',true),
  ('Texas 371st District Court','Marq Clayton','Marq','Clayton',false),
  ('Texas 371st District Court','Ryan Hill','Ryan','Hill',true),
  ('Texas 372nd District Court','Julie Lugo','Julie','Lugo',true),
  ('Texas 432nd District Court','Courtney Miller','Courtney','Miller',false),
  ('Texas 432nd District Court','Lee Sorrells','Lee','Sorrells',false),
  ('Texas 485th District Court','Steven Jumes','Steven','Jumes',true),
  ('Tarrant County Justice of the Peace Precinct 1','Ricky Rodriguez','Ricky','Rodriguez',false),
  ('Tarrant County Justice of the Peace Precinct 2','Celina Vasquez','Celina','Vasquez',false),
  ('Tarrant County Justice of the Peace Precinct 2','Mary Tom Curnutt','Mary','Curnutt',true),
  ('Tarrant County Justice of the Peace Precinct 3','Bill Brandt','Bill','Brandt',true),
  ('Tarrant County Justice of the Peace Precinct 4','Rodney Lee','Rodney','Lee',false),
  ('Tarrant County Justice of the Peace Precinct 4','Christopher Gregory','Christopher','Gregory',true),
  ('Tarrant County Justice of the Peace Precinct 5','Sergio De Leon','Sergio','De Leon',true),
  ('Tarrant County Justice of the Peace Precinct 6','Jason Charbonnet','Jason','Charbonnet',true),
  ('Tarrant County Justice of the Peace Precinct 7','Kenneth Sanders','Kenneth','Sanders',true),
  ('Tarrant County Justice of the Peace Precinct 7','Paige Payne-Neal','Paige','Payne-Neal',false),
  ('Tarrant County Justice of the Peace Precinct 8','Lisa Woodard','Lisa','Woodard',true),
  ('Tarrant County Probate Court No. 1','Patricia Burns','Patricia','Burns',true),
  ('Tarrant County Probate Court No. 2','Brook Bell','Brook','Bell',false)
) AS v(pos, fullname, fname, lname, inc)
JOIN essentials.races r ON r.position_name = v.pos
JOIN essentials.elections e ON e.id = r.election_id AND e.name = 'TX 2026 Statewide General'
JOIN essentials.politicians p ON p.full_name = v.fullname AND p.data_source = 'Tarrant County full-ballot seed 2026-08-09; Ballotpedia Municipal elections in Tarrant County, Texas (2026)';

DO $$
DECLARE v_ch int; v_off int; v_vac int; v_race int; v_cand int; v_unlinked int; v_terms int;
BEGIN
  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = 'Tarrant County, Texas, US';
  SELECT count(*), count(*) FILTER (WHERE o.is_vacant) INTO v_off, v_vac
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = 'Tarrant County, Texas, US';
  SELECT count(DISTINCT r.id), count(rc.id), count(*) FILTER (WHERE rc.politician_id IS NULL)
    INTO v_race, v_cand, v_unlinked
    FROM essentials.races r JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id WHERE g.name = 'Tarrant County, Texas, US';
  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = 'Tarrant County, Texas, US';
  -- 8 chambers = 1 + 7 | 47 offices = 5 + 42 | 45 races = 3 + 42
  -- 66 candidates = 6 + 60 | 40 terms = 5 + 35 | 0 vacant
  IF v_ch <> 8 OR v_off <> 47 OR v_vac <> 0 OR v_race <> 45 OR v_cand <> 66
     OR v_unlinked <> 0 OR v_terms <> 40 THEN
    RAISE EXCEPTION 'Post-check FAILED: ch=% off=% vac=% race=% cand=% unlinked=% terms=% (want 8/47/0/45/66/0/40)',
      v_ch, v_off, v_vac, v_race, v_cand, v_unlinked, v_terms;
  END IF;
END $$;

COMMIT;
