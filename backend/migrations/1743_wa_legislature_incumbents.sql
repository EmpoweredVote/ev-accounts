-- 1743_wa_legislature_incumbents.sql
-- Seats all 147 Washington state legislators (49 senators + 98 representatives).
--
-- SOURCES
--   Identity, district, party, email  : OFFICIAL WA Legislature web service
--     (wslwebservices.leg.wa.gov SponsorService, biennium 2025-26)
--   Seat position, assumed-office date : Ballotpedia chamber rosters
--
-- The official service alone is NOT sufficient: it returns the whole biennium
-- SPONSOR list (104 House / 54 Senate = 158 entries), which includes members who
-- left mid-term, and it carries no seat position for House members. Ballotpedia
-- is not trusted for identity. So all 147 seats were reconciled between the two
-- by (surname, district, chamber); 146 matched automatically and the single
-- remainder was resolved by hand. 8 official entries hold no current seat --
-- mid-biennium departures (incl. Senate LD34 Joe Nguyen and Senate LD5 Bill
-- Ramos, both replaced) plus 3 non-member committee sponsors -- and are
-- correctly NOT seated here.
--
-- NAME CONFLICTS -- the official source wins on every one, with the Ballotpedia
-- variant kept in alternate_names so the person stays findable either way:
--   LD26 Pos2  Michelle Valdez  Ballotpedia still lists her as Michelle Caldier.
--                               She legally changed her name after marrying
--                               (announced 2026-01-09) and the Legislature
--                               updated all official records. Same person, same
--                               seat. This was the one unreconciled seat.
--   LD7 Pos1   Andrew Engell    Ballotpedia "David Engell" -- he is David Andrew
--                               Engell Jr. and goes by Andrew.
--   LD31 Pos1  Joshua Penner    Ballotpedia "Josh Penner".
--   SD13       Judy Warnick     Ballotpedia "Judith Warnick".
--   SD37       Rebecca Saldana  Ballotpedia dropped the diacritic (n-tilde).
--
-- DATE PRECISION is recorded, never fabricated: 120 seats have a full
-- assumed-office date (start_precision='day'); 27 carry only a year, stored as
-- YYYY-01-01 with start_precision='year' so day and month are explicitly NOT
-- being claimed.
--
-- how_started is left NULL throughout. Several members arrived by county council
-- appointment to fill a vacancy rather than by election, and that distinction was
-- not verified per member. Recorded in WA-GAPS.md.
--
-- term_end is NULL for all (currently serving) but term_start is ALWAYS
-- populated: a NULL/NULL pair reads downstream as "currently serving" and would
-- mask a later departure.
--
-- IDEMPOTENCY: politicians uses ON CONFLICT (external_id) DO NOTHING (real unique
-- index). office_terms uses NOT EXISTS -- it has no unique constraint on the
-- dedupe key, so ON CONFLICT would be wrong there.
--
-- EXTERNAL IDS: Senate LD n -> -(5310000+n); House LD n Position p ->
-- -(5320000 + (n-1)*2 + p). Collision-free; the -5400000..-5300000 band
-- previously held only the 5 statewide executives.
--
-- Joins key on (geo_id, district_type, mtfcc) because geo_id is NOT unique
-- across MTFCCs in WA. STATE_UPPER=G5210, STATE_LOWER=G5220 (inverted vs a plain
-- TIGER reading).
--
-- Single statement by necessity: the office_terms insert must resolve
-- politician_id for rows the same statement creates, so the politician insert is
-- a data-modifying CTE and its RETURNING output is unioned with any pre-existing
-- rows.

WITH seed (ext_id, full_name, first_name, last_name, party, party_short, email,
           aliases, geo_id, dtype, mtfcc, title, term_start, precision) AS (
  VALUES
  (-5320001::bigint, 'Davina Duerr'::text, 'Davina'::text, 'Duerr'::text, 'Democratic'::text, 'D'::text, 'davina.duerr@leg.wa.gov'::text, ARRAY[]::text[], '53001'::text, 'STATE_LOWER'::text, 'G5220'::text, 'State Representative (Position 1)'::text, DATE '2019-01-01', 'year'::text),
  (-5320002, 'Shelley Kloba', 'Shelley', 'Kloba', 'Democratic', 'D', 'shelley.kloba@leg.wa.gov', ARRAY[]::text[], '53001', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2017-01-09', 'day'),
  (-5320003, 'Andrew Barkis', 'Andrew', 'Barkis', 'Republican', 'R', 'andrew.barkis@leg.wa.gov', ARRAY[]::text[], '53002', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2016-02-16', 'day'),
  (-5320004, 'Matt Marshall', 'Matt', 'Marshall', 'Republican', 'R', 'Matt.Marshall@leg.wa.gov', ARRAY[]::text[], '53002', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320005, 'Natasha Hill', 'Natasha', 'Hill', 'Democratic', 'D', 'Natasha.Hill@leg.wa.gov', ARRAY[]::text[], '53003', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-13', 'day'),
  (-5320006, 'Timm Ormsby', 'Timm', 'Ormsby', 'Democratic', 'D', 'timm.ormsby@leg.wa.gov', ARRAY[]::text[], '53003', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2003-01-01', 'year'),
  (-5320007, 'Suzanne Schmidt', 'Suzanne', 'Schmidt', 'Republican', 'R', 'Suzanne.Schmidt@leg.wa.gov', ARRAY[]::text[], '53004', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2023-01-09', 'day'),
  (-5320008, 'Rob Chase', 'Rob', 'Chase', 'Republican', 'R', 'Rob.Chase@leg.wa.gov', ARRAY[]::text[], '53004', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320009, 'Zach Hall', 'Zach', 'Hall', 'Democratic', 'D', 'HALL_ZA@leg.wa.gov', ARRAY[]::text[], '53005', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-06-03', 'day'),
  (-5320010, 'Lisa Callan', 'Lisa', 'Callan', 'Democratic', 'D', 'lisa.callan@leg.wa.gov', ARRAY[]::text[], '53005', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2019-01-14', 'day'),
  (-5320011, 'Mike Volz', 'Mike', 'Volz', 'Republican', 'R', 'mike.volz@leg.wa.gov', ARRAY[]::text[], '53006', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2017-01-09', 'day'),
  (-5320012, 'Jenny Graham', 'Jenny', 'Graham', 'Republican', 'R', 'jenny.graham@leg.wa.gov', ARRAY[]::text[], '53006', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2019-01-14', 'day'),
  (-5320013, 'Andrew Engell', 'Andrew', 'Engell', 'Republican', 'R', 'Andrew.Engell@leg.wa.gov', ARRAY['David Engell']::text[], '53007', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-13', 'day'),
  (-5320014, 'Hunter Abell', 'Hunter', 'Abell', 'Republican', 'R', 'Hunter.Abell@leg.wa.gov', ARRAY[]::text[], '53007', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320015, 'Stephanie Barnard', 'Stephanie', 'Barnard', 'Republican', 'R', 'Stephanie.Barnard@leg.wa.gov', ARRAY[]::text[], '53008', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2023-01-09', 'day'),
  (-5320016, 'April Connors', 'April', 'Connors', 'Republican', 'R', 'April.Connors@leg.wa.gov', ARRAY[]::text[], '53008', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2023-01-09', 'day'),
  (-5320017, 'Mary Dye', 'Mary', 'Dye', 'Republican', 'R', 'mary.dye@leg.wa.gov', ARRAY[]::text[], '53009', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2015-05-08', 'day'),
  (-5320018, 'Joe Schmick', 'Joe', 'Schmick', 'Republican', 'R', 'joe.schmick@leg.wa.gov', ARRAY[]::text[], '53009', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2007-01-01', 'year'),
  (-5320019, 'Clyde Shavers', 'Clyde', 'Shavers', 'Democratic', 'D', 'Clyde.Shavers@leg.wa.gov', ARRAY[]::text[], '53010', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2023-01-09', 'day'),
  (-5320020, 'Dave Paul', 'Dave', 'Paul', 'Democratic', 'D', 'dave.paul@leg.wa.gov', ARRAY[]::text[], '53010', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2019-01-14', 'day'),
  (-5320021, 'David Hackney', 'David', 'Hackney', 'Democratic', 'D', 'David.Hackney@leg.wa.gov', ARRAY[]::text[], '53011', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2021-01-11', 'day'),
  (-5320022, 'Steve Bergquist', 'Steve', 'Bergquist', 'Democratic', 'D', 'steve.bergquist@leg.wa.gov', ARRAY[]::text[], '53011', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2013-01-14', 'day'),
  (-5320023, 'Brian Burnett', 'Brian', 'Burnett', 'Republican', 'R', 'Brian.Burnett@leg.wa.gov', ARRAY[]::text[], '53012', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-13', 'day'),
  (-5320024, 'Mike Steele', 'Mike', 'Steele', 'Republican', 'R', 'mike.steele@leg.wa.gov', ARRAY[]::text[], '53012', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2017-01-09', 'day'),
  (-5320025, 'Tom Dent', 'Tom', 'Dent', 'Republican', 'R', 'tom.dent@leg.wa.gov', ARRAY[]::text[], '53013', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2015-01-12', 'day'),
  (-5320026, 'Alex Ybarra', 'Alex', 'Ybarra', 'Republican', 'R', 'alex.ybarra@leg.wa.gov', ARRAY[]::text[], '53013', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2019-01-14', 'day'),
  (-5320027, 'Gloria Mendoza', 'Gloria', 'Mendoza', 'Republican', 'R', 'Gloria.Mendoza@leg.wa.gov', ARRAY[]::text[], '53014', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-13', 'day'),
  (-5320028, 'Deb Manjarrez', 'Deb', 'Manjarrez', 'Republican', 'R', 'Deb.Manjarrez@leg.wa.gov', ARRAY[]::text[], '53014', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320029, 'Chris Corry', 'Chris', 'Corry', 'Republican', 'R', 'chris.corry@leg.wa.gov', ARRAY[]::text[], '53015', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-13', 'day'),
  (-5320030, 'Jeremie Dufault', 'Jeremie', 'Dufault', 'Republican', 'R', 'DUFAULT_JE@leg.wa.gov', ARRAY[]::text[], '53015', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320031, 'Mark Klicker', 'Mark', 'Klicker', 'Republican', 'R', 'Mark.Klicker@leg.wa.gov', ARRAY[]::text[], '53016', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2021-01-11', 'day'),
  (-5320032, 'Skyler Rude', 'Skyler', 'Rude', 'Republican', 'R', 'skyler.rude@leg.wa.gov', ARRAY[]::text[], '53016', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2019-01-14', 'day'),
  (-5320033, 'Kevin Waters', 'Kevin', 'Waters', 'Republican', 'R', 'Kevin.Waters@leg.wa.gov', ARRAY[]::text[], '53017', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2023-01-09', 'day'),
  (-5320034, 'David Stuebe', 'David', 'Stuebe', 'Republican', 'R', 'David.Stuebe@leg.wa.gov', ARRAY[]::text[], '53017', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320035, 'Stephanie McClintock', 'Stephanie', 'McClintock', 'Republican', 'R', 'Stephanie.McClintock@leg.wa.gov', ARRAY[]::text[], '53018', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2023-01-09', 'day'),
  (-5320036, 'John Ley', 'John', 'Ley', 'Republican', 'R', 'John.Ley@leg.wa.gov', ARRAY[]::text[], '53018', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320037, 'Jim Walsh', 'Jim', 'Walsh', 'Republican', 'R', 'jim.walsh@leg.wa.gov', ARRAY[]::text[], '53019', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2017-01-09', 'day'),
  (-5320038, 'Joel McEntire', 'Joel', 'McEntire', 'Republican', 'R', 'Joel.McEntire@leg.wa.gov', ARRAY[]::text[], '53019', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2021-01-11', 'day'),
  (-5320039, 'Peter Abbarno', 'Peter', 'Abbarno', 'Republican', 'R', 'Peter.Abbarno@leg.wa.gov', ARRAY[]::text[], '53020', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2021-01-11', 'day'),
  (-5320040, 'Ed Orcutt', 'Ed', 'Orcutt', 'Republican', 'R', 'ed.orcutt@leg.wa.gov', ARRAY[]::text[], '53020', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2003-01-01', 'year'),
  (-5320041, 'Strom Peterson', 'Strom', 'Peterson', 'Democratic', 'D', 'strom.peterson@leg.wa.gov', ARRAY[]::text[], '53021', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2015-01-12', 'day'),
  (-5320042, 'Lillian Ortiz-Self', 'Lillian', 'Ortiz-Self', 'Democratic', 'D', 'lillian.ortiz-self@leg.wa.gov', ARRAY[]::text[], '53021', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2014-01-22', 'day'),
  (-5320043, 'Beth Doglio', 'Beth', 'Doglio', 'Democratic', 'D', 'beth.doglio@leg.wa.gov', ARRAY[]::text[], '53022', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2023-01-09', 'day'),
  (-5320044, 'Lisa Parshley', 'Lisa', 'Parshley', 'Democratic', 'D', 'Lisa.Parshley@leg.wa.gov', ARRAY[]::text[], '53022', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320045, 'Tarra Simmons', 'Tarra', 'Simmons', 'Democratic', 'D', 'Tarra.Simmons@leg.wa.gov', ARRAY[]::text[], '53023', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2021-01-11', 'day'),
  (-5320046, 'Greg Nance', 'Greg', 'Nance', 'Democratic', 'D', 'Greg.Nance@leg.wa.gov', ARRAY[]::text[], '53023', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2023-09-18', 'day'),
  (-5320047, 'Adam Bernbaum', 'Adam', 'Bernbaum', 'Democratic', 'D', 'BERNBAUM_AD@leg.wa.gov', ARRAY[]::text[], '53024', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-13', 'day'),
  (-5320048, 'Steve Tharinger', 'Steve', 'Tharinger', 'Democratic', 'D', 'steve.tharinger@leg.wa.gov', ARRAY[]::text[], '53024', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2011-01-01', 'year'),
  (-5320049, 'Michael Keaton', 'Michael', 'Keaton', 'Republican', 'R', 'Michael.Keaton@leg.wa.gov', ARRAY[]::text[], '53025', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-13', 'day'),
  (-5320050, 'Cyndy Jacobsen', 'Cyndy', 'Jacobsen', 'Republican', 'R', 'Cyndy.Jacobsen@leg.wa.gov', ARRAY[]::text[], '53025', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2021-01-11', 'day'),
  (-5320051, 'Adison Richards', 'Adison', 'Richards', 'Democratic', 'D', 'RICHARDS_AD@leg.wa.gov', ARRAY[]::text[], '53026', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-13', 'day'),
  (-5320052, 'Michelle Valdez', 'Michelle', 'Valdez', 'Republican', 'R', 'Michelle.Valdez@leg.wa.gov', ARRAY['Michelle Caldier']::text[], '53026', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2015-01-12', 'day'),
  (-5320053, 'Laurie Jinkins', 'Laurie', 'Jinkins', 'Democratic', 'D', 'laurie.jinkins@leg.wa.gov', ARRAY[]::text[], '53027', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2011-01-01', 'year'),
  (-5320054, 'Jake Fey', 'Jake', 'Fey', 'Democratic', 'D', 'jake.fey@leg.wa.gov', ARRAY[]::text[], '53027', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2013-01-14', 'day'),
  (-5320055, 'Mari Leavitt', 'Mari', 'Leavitt', 'Democratic', 'D', 'mari.leavitt@leg.wa.gov', ARRAY[]::text[], '53028', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2019-01-14', 'day'),
  (-5320056, 'Dan Bronoske', 'Dan', 'Bronoske', 'Democratic', 'D', 'Dan.Bronoske@leg.wa.gov', ARRAY[]::text[], '53028', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2021-01-11', 'day'),
  (-5320057, 'Melanie Morgan', 'Melanie', 'Morgan', 'Democratic', 'D', 'melanie.morgan@leg.wa.gov', ARRAY[]::text[], '53029', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2019-01-14', 'day'),
  (-5320058, 'Sharlett Mena', 'Sharlett', 'Mena', 'Democratic', 'D', 'sharlett.mena@leg.wa.gov', ARRAY[]::text[], '53029', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2023-01-09', 'day'),
  (-5320059, 'Jamila Taylor', 'Jamila', 'Taylor', 'Democratic', 'D', 'Jamila.Taylor@leg.wa.gov', ARRAY[]::text[], '53030', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2021-01-11', 'day'),
  (-5320060, 'Kristine Reeves', 'Kristine', 'Reeves', 'Democratic', 'D', 'kristine.reeves@leg.wa.gov', ARRAY[]::text[], '53030', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2023-01-09', 'day'),
  (-5320061, 'Drew Stokesbary', 'Drew', 'Stokesbary', 'Republican', 'R', 'drew.stokesbary@leg.wa.gov', ARRAY[]::text[], '53031', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2015-01-12', 'day'),
  (-5320062, 'Joshua Penner', 'Joshua', 'Penner', 'Republican', 'R', 'Joshua.Penner@leg.wa.gov', ARRAY['Josh Penner']::text[], '53031', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320063, 'Cindy Ryu', 'Cindy', 'Ryu', 'Democratic', 'D', 'cindy.ryu@leg.wa.gov', ARRAY[]::text[], '53032', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2011-01-01', 'year'),
  (-5320064, 'Lauren Davis', 'Lauren', 'Davis', 'Democratic', 'D', 'lauren.davis@leg.wa.gov', ARRAY[]::text[], '53032', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2019-01-14', 'day'),
  (-5320065, 'Edwin Obras', 'Edwin', 'Obras', 'Democratic', 'D', 'Edwin.Obras@leg.wa.gov', ARRAY[]::text[], '53033', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2024-12-11', 'day'),
  (-5320066, 'Mia Gregerson', 'Mia', 'Gregerson', 'Democratic', 'D', 'mia.gregerson@leg.wa.gov', ARRAY[]::text[], '53033', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2013-01-01', 'year'),
  (-5320067, 'Brianna Thomas', 'Brianna', 'Thomas', 'Democratic', 'D', 'THOMAS_BR@leg.wa.gov', ARRAY[]::text[], '53034', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-21', 'day'),
  (-5320068, 'Joe Fitzgibbon', 'Joe', 'Fitzgibbon', 'Democratic', 'D', 'joe.fitzgibbon@leg.wa.gov', ARRAY[]::text[], '53034', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2011-01-01', 'year'),
  (-5320069, 'Dan Griffey', 'Dan', 'Griffey', 'Republican', 'R', 'dan.griffey@leg.wa.gov', ARRAY[]::text[], '53035', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2015-01-12', 'day'),
  (-5320070, 'Travis Couture', 'Travis', 'Couture', 'Republican', 'R', 'Travis.Couture@leg.wa.gov', ARRAY[]::text[], '53035', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2023-01-09', 'day'),
  (-5320071, 'Julia Reed', 'Julia', 'Reed', 'Democratic', 'D', 'Julia.Reed@leg.wa.gov', ARRAY[]::text[], '53036', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2023-01-09', 'day'),
  (-5320072, 'Liz Berry', 'Liz', 'Berry', 'Democratic', 'D', 'Liz.Berry@leg.wa.gov', ARRAY[]::text[], '53036', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2021-01-11', 'day'),
  (-5320073, 'Sharon Tomiko Santos', 'Sharon Tomiko', 'Santos', 'Democratic', 'D', 'sharontomiko.santos@leg.wa.gov', ARRAY[]::text[], '53037', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '1999-01-01', 'year'),
  (-5320074, 'Chipalo Street', 'Chipalo', 'Street', 'Democratic', 'D', 'Chipalo.Street@leg.wa.gov', ARRAY[]::text[], '53037', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2023-01-09', 'day'),
  (-5320075, 'Julio Cortes', 'Julio', 'Cortes', 'Democratic', 'D', 'Julio.Cortes@leg.wa.gov', ARRAY[]::text[], '53038', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2023-01-09', 'day'),
  (-5320076, 'Mary Fosse', 'Mary', 'Fosse', 'Democratic', 'D', 'Mary.Fosse@leg.wa.gov', ARRAY[]::text[], '53038', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2023-01-09', 'day'),
  (-5320077, 'Sam Low', 'Sam', 'Low', 'Republican', 'R', 'Sam.Low@leg.wa.gov', ARRAY[]::text[], '53039', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2023-01-09', 'day'),
  (-5320078, 'Carolyn Eslick', 'Carolyn', 'Eslick', 'Republican', 'R', 'carolyn.eslick@leg.wa.gov', ARRAY[]::text[], '53039', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2017-01-01', 'year'),
  (-5320079, 'Debra Lekanoff', 'Debra', 'Lekanoff', 'Democratic', 'D', 'debra.lekanoff@leg.wa.gov', ARRAY[]::text[], '53040', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2019-01-14', 'day'),
  (-5320080, 'Alex Ramel', 'Alex', 'Ramel', 'Democratic', 'D', 'alex.ramel@leg.wa.gov', ARRAY[]::text[], '53040', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2020-01-06', 'day'),
  (-5320081, 'Janice Zahn', 'Janice', 'Zahn', 'Democratic', 'D', 'Janice.Zahn@leg.wa.gov', ARRAY[]::text[], '53041', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-21', 'day'),
  (-5320082, 'My-Linh Thai', 'My-Linh', 'Thai', 'Democratic', 'D', 'my-linh.thai@leg.wa.gov', ARRAY[]::text[], '53041', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2019-01-14', 'day'),
  (-5320083, 'Alicia Rule', 'Alicia', 'Rule', 'Democratic', 'D', 'Alicia.Rule@leg.wa.gov', ARRAY[]::text[], '53042', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2021-01-11', 'day'),
  (-5320084, 'Joe Timmons', 'Joe', 'Timmons', 'Democratic', 'D', 'Joe.Timmons@leg.wa.gov', ARRAY[]::text[], '53042', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2022-12-21', 'day'),
  (-5320085, 'Nicole Macri', 'Nicole', 'Macri', 'Democratic', 'D', 'nicole.macri@leg.wa.gov', ARRAY[]::text[], '53043', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2017-01-09', 'day'),
  (-5320086, 'Shaun Scott', 'Shaun', 'Scott', 'Democratic', 'D', 'Shaun.Scott@leg.wa.gov', ARRAY[]::text[], '53043', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2025-01-13', 'day'),
  (-5320087, 'Brandy Donaghy', 'Brandy', 'Donaghy', 'Democratic', 'D', 'Brandy.Donaghy@leg.wa.gov', ARRAY[]::text[], '53044', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2021-12-15', 'day'),
  (-5320088, 'April Berg', 'April', 'Berg', 'Democratic', 'D', 'April.Berg@leg.wa.gov', ARRAY[]::text[], '53044', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2021-01-11', 'day'),
  (-5320089, 'Roger Goodman', 'Roger', 'Goodman', 'Democratic', 'D', 'roger.goodman@leg.wa.gov', ARRAY[]::text[], '53045', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2007-01-01', 'year'),
  (-5320090, 'Larry Springer', 'Larry', 'Springer', 'Democratic', 'D', 'larry.springer@leg.wa.gov', ARRAY[]::text[], '53045', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2005-01-01', 'year'),
  (-5320091, 'Gerry Pollet', 'Gerry', 'Pollet', 'Democratic', 'D', 'gerry.pollet@leg.wa.gov', ARRAY[]::text[], '53046', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2011-01-01', 'year'),
  (-5320092, 'Darya Farivar', 'Darya', 'Farivar', 'Democratic', 'D', 'Darya.Farivar@leg.wa.gov', ARRAY[]::text[], '53046', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2023-01-09', 'day'),
  (-5320093, 'Debra Entenman', 'Debra', 'Entenman', 'Democratic', 'D', 'debra.entenman@leg.wa.gov', ARRAY[]::text[], '53047', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2019-01-14', 'day'),
  (-5320094, 'Chris Stearns', 'Chris', 'Stearns', 'Democratic', 'D', 'Chris.Stearns@leg.wa.gov', ARRAY[]::text[], '53047', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2023-01-09', 'day'),
  (-5320095, 'Osman Salahuddin', 'Osman', 'Salahuddin', 'Democratic', 'D', 'Osman.Salahuddin@leg.wa.gov', ARRAY[]::text[], '53048', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2025-01-07', 'day'),
  (-5320096, 'Amy Walen', 'Amy', 'Walen', 'Democratic', 'D', 'amy.walen@leg.wa.gov', ARRAY[]::text[], '53048', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2019-01-14', 'day'),
  (-5320097, 'Sharon Wylie', 'Sharon', 'Wylie', 'Democratic', 'D', 'sharon.wylie@leg.wa.gov', ARRAY[]::text[], '53049', 'STATE_LOWER', 'G5220', 'State Representative (Position 1)', DATE '2011-01-01', 'year'),
  (-5320098, 'Monica Jurado Stonier', 'Monica Jurado', 'Stonier', 'Democratic', 'D', 'monica.stonier@leg.wa.gov', ARRAY[]::text[], '53049', 'STATE_LOWER', 'G5220', 'State Representative (Position 2)', DATE '2017-01-09', 'day'),
  (-5310001, 'Derek Stanford', 'Derek', 'Stanford', 'Democratic', 'D', 'derek.stanford@leg.wa.gov', ARRAY[]::text[], '53001', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2019-07-01', 'day'),
  (-5310002, 'Jim McCune', 'Jim', 'McCune', 'Republican', 'R', 'jim.mccune@leg.wa.gov', ARRAY[]::text[], '53002', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2021-01-11', 'day'),
  (-5310003, 'Marcus Riccelli', 'Marcus', 'Riccelli', 'Democratic', 'D', 'marcus.riccelli@leg.wa.gov', ARRAY[]::text[], '53003', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-01-13', 'day'),
  (-5310004, 'Leonard Christian', 'Leonard', 'Christian', 'Republican', 'R', 'leonard.christian@leg.wa.gov', ARRAY[]::text[], '53004', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-01-13', 'day'),
  (-5310005, 'Victoria Hunt', 'Victoria', 'Hunt', 'Democratic', 'D', 'Victoria.Hunt@leg.wa.gov', ARRAY[]::text[], '53005', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-06-03', 'day'),
  (-5310006, 'Jeff Holy', 'Jeff', 'Holy', 'Republican', 'R', 'jeff.holy@leg.wa.gov', ARRAY[]::text[], '53006', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2019-01-01', 'year'),
  (-5310007, 'Shelly Short', 'Shelly', 'Short', 'Republican', 'R', 'shelly.short@leg.wa.gov', ARRAY[]::text[], '53007', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2017-01-01', 'year'),
  (-5310008, 'Matt Boehnke', 'Matt', 'Boehnke', 'Republican', 'R', 'matt.boehnke@leg.wa.gov', ARRAY[]::text[], '53008', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2023-01-09', 'day'),
  (-5310009, 'Mark Schoesler', 'Mark', 'Schoesler', 'Republican', 'R', 'mark.schoesler@leg.wa.gov', ARRAY[]::text[], '53009', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2005-01-01', 'year'),
  (-5310010, 'Ron Muzzall', 'Ron', 'Muzzall', 'Republican', 'R', 'ron.muzzall@leg.wa.gov', ARRAY[]::text[], '53010', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2019-10-18', 'day'),
  (-5310011, 'Bob Hasegawa', 'Bob', 'Hasegawa', 'Democratic', 'D', 'bob.hasegawa@leg.wa.gov', ARRAY[]::text[], '53011', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2013-01-14', 'day'),
  (-5310012, 'Keith Goehner', 'Keith', 'Goehner', 'Republican', 'R', 'keith.goehner@leg.wa.gov', ARRAY[]::text[], '53012', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-01-13', 'day'),
  (-5310013, 'Judy Warnick', 'Judy', 'Warnick', 'Republican', 'R', 'judith.warnick@leg.wa.gov', ARRAY['Judith Warnick']::text[], '53013', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2015-01-12', 'day'),
  (-5310014, 'Curtis King', 'Curtis', 'King', 'Republican', 'R', 'curtis.king@leg.wa.gov', ARRAY[]::text[], '53014', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2007-01-01', 'year'),
  (-5310015, 'Nikki Torres', 'Nikki', 'Torres', 'Republican', 'R', 'Nikki.Torres@leg.wa.gov', ARRAY[]::text[], '53015', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2023-01-09', 'day'),
  (-5310016, 'Perry Dozier', 'Perry', 'Dozier', 'Republican', 'R', 'Perry.Dozier@leg.wa.gov', ARRAY[]::text[], '53016', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2021-01-11', 'day'),
  (-5310017, 'Paul Harris', 'Paul', 'Harris', 'Republican', 'R', 'paul.harris@leg.wa.gov', ARRAY[]::text[], '53017', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-01-13', 'day'),
  (-5310018, 'Adrian Cortes', 'Adrian', 'Cortes', 'Democratic', 'D', 'Adrian.Cortes@leg.wa.gov', ARRAY[]::text[], '53018', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-01-13', 'day'),
  (-5310019, 'Jeff Wilson', 'Jeff', 'Wilson', 'Republican', 'R', 'Jeff.Wilson@leg.wa.gov', ARRAY[]::text[], '53019', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2021-01-11', 'day'),
  (-5310020, 'John Braun', 'John', 'Braun', 'Republican', 'R', 'John.Braun@leg.wa.gov', ARRAY[]::text[], '53020', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2013-01-14', 'day'),
  (-5310021, 'Marko Liias', 'Marko', 'Liias', 'Democratic', 'D', 'marko.liias@leg.wa.gov', ARRAY[]::text[], '53021', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2014-01-01', 'year'),
  (-5310022, 'Jessica Bateman', 'Jessica', 'Bateman', 'Democratic', 'D', 'jessica.bateman@leg.wa.gov', ARRAY[]::text[], '53022', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-01-13', 'day'),
  (-5310023, 'Drew Hansen', 'Drew', 'Hansen', 'Democratic', 'D', 'drew.hansen@leg.wa.gov', ARRAY[]::text[], '53023', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2023-08-28', 'day'),
  (-5310024, 'Mike Chapman', 'Mike', 'Chapman', 'Democratic', 'D', 'mike.chapman@leg.wa.gov', ARRAY[]::text[], '53024', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-01-13', 'day'),
  (-5310025, 'Chris Gildon', 'Chris', 'Gildon', 'Republican', 'R', 'chris.gildon@leg.wa.gov', ARRAY[]::text[], '53025', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2021-01-11', 'day'),
  (-5310026, 'Deborah Krishnadasan', 'Deborah', 'Krishnadasan', 'Democratic', 'D', 'Deborah.Krishnadasan@leg.wa.gov', ARRAY[]::text[], '53026', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2024-12-11', 'day'),
  (-5310027, 'Yasmin Trudeau', 'Yasmin', 'Trudeau', 'Democratic', 'D', 'yasmin.trudeau@leg.wa.gov', ARRAY[]::text[], '53027', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2021-11-02', 'day'),
  (-5310028, 'T''wina Nobles', 'T''wina', 'Nobles', 'Democratic', 'D', 'T''wina.Nobles@leg.wa.gov', ARRAY[]::text[], '53028', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2021-01-11', 'day'),
  (-5310029, 'Steve Conway', 'Steve', 'Conway', 'Democratic', 'D', 'steve.conway@leg.wa.gov', ARRAY[]::text[], '53029', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2011-01-01', 'year'),
  (-5310030, 'Claire Wilson', 'Claire', 'Wilson', 'Democratic', 'D', 'claire.wilson@leg.wa.gov', ARRAY[]::text[], '53030', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2019-01-01', 'year'),
  (-5310031, 'Phil Fortunato', 'Phil', 'Fortunato', 'Republican', 'R', 'phil.fortunato@leg.wa.gov', ARRAY[]::text[], '53031', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2017-01-07', 'day'),
  (-5310032, 'Jesse Salomon', 'Jesse', 'Salomon', 'Democratic', 'D', 'jesse.salomon@leg.wa.gov', ARRAY[]::text[], '53032', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2019-01-01', 'year'),
  (-5310033, 'Tina Orwall', 'Tina', 'Orwall', 'Democratic', 'D', 'tina.orwall@leg.wa.gov', ARRAY[]::text[], '53033', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2024-12-11', 'day'),
  (-5310034, 'Emily Alvarado', 'Emily', 'Alvarado', 'Democratic', 'D', 'Emily.Alvarado@leg.wa.gov', ARRAY[]::text[], '53034', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-01-21', 'day'),
  (-5310035, 'Drew MacEwen', 'Drew', 'MacEwen', 'Republican', 'R', 'drew.macewen@leg.wa.gov', ARRAY[]::text[], '53035', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2023-01-09', 'day'),
  (-5310036, 'Noel Frame', 'Noel', 'Frame', 'Democratic', 'D', 'noel.frame@leg.wa.gov', ARRAY[]::text[], '53036', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2023-01-09', 'day'),
  (-5310037, 'Rebecca Saldaña', 'Rebecca', 'Saldaña', 'Democratic', 'D', 'rebecca.saldana@leg.wa.gov', ARRAY['Rebecca Saldana']::text[], '53037', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2016-01-01', 'year'),
  (-5310038, 'June Robinson', 'June', 'Robinson', 'Democratic', 'D', 'june.robinson@leg.wa.gov', ARRAY[]::text[], '53038', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2020-05-13', 'day'),
  (-5310039, 'Keith Wagoner', 'Keith', 'Wagoner', 'Republican', 'R', 'keith.wagoner@leg.wa.gov', ARRAY[]::text[], '53039', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2018-01-03', 'day'),
  (-5310040, 'Liz Lovelett', 'Liz', 'Lovelett', 'Democratic', 'D', 'liz.lovelett@leg.wa.gov', ARRAY[]::text[], '53040', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2019-01-01', 'year'),
  (-5310041, 'Lisa Wellman', 'Lisa', 'Wellman', 'Democratic', 'D', 'lisa.wellman@leg.wa.gov', ARRAY[]::text[], '53041', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2017-01-09', 'day'),
  (-5310042, 'Sharon Shewmake', 'Sharon', 'Shewmake', 'Democratic', 'D', 'sharon.shewmake@leg.wa.gov', ARRAY[]::text[], '53042', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2022-12-09', 'day'),
  (-5310043, 'Jamie Pedersen', 'Jamie', 'Pedersen', 'Democratic', 'D', 'jamie.pedersen@leg.wa.gov', ARRAY[]::text[], '53043', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2013-01-01', 'year'),
  (-5310044, 'John Lovick', 'John', 'Lovick', 'Democratic', 'D', 'john.lovick@leg.wa.gov', ARRAY[]::text[], '53044', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2021-12-15', 'day'),
  (-5310045, 'Manka Dhingra', 'Manka', 'Dhingra', 'Democratic', 'D', 'manka.dhingra@leg.wa.gov', ARRAY[]::text[], '53045', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2017-01-01', 'year'),
  (-5310046, 'Javier Valdez', 'Javier', 'Valdez', 'Democratic', 'D', 'javier.valdez@leg.wa.gov', ARRAY[]::text[], '53046', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2023-01-09', 'day'),
  (-5310047, 'Claudia Kauffman', 'Claudia', 'Kauffman', 'Democratic', 'D', 'claudia.kauffman@leg.wa.gov', ARRAY[]::text[], '53047', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2023-01-09', 'day'),
  (-5310048, 'Vandana Slatter', 'Vandana', 'Slatter', 'Democratic', 'D', 'vandana.slatter@leg.wa.gov', ARRAY[]::text[], '53048', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2025-01-07', 'day'),
  (-5310049, 'Annette Cleveland', 'Annette', 'Cleveland', 'Democratic', 'D', 'Annette.Cleveland@leg.wa.gov', ARRAY[]::text[], '53049', 'STATE_UPPER', 'G5210', 'State Senator', DATE '2013-01-14', 'day')
),
ins AS (
  INSERT INTO essentials.politicians
    (external_id, full_name, first_name, last_name, party, party_short_name,
     email_addresses, alternate_names, is_incumbent, is_active, data_source)
  SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.party, s.party_short,
         ARRAY[s.email]::text[], s.aliases, true, true, 'WA Legislature member web service (wslwebservices.leg.wa.gov SponsorService, biennium 2025-26) for identity/district/party/email; Ballotpedia chamber rosters for seat position and assumed-office date; all 147 seats reconciled across both. Retrieved 2026-08-13.'
  FROM seed s
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id, external_id
),
pol AS (
  SELECT id, external_id FROM ins
  UNION
  SELECT p.id, p.external_id
  FROM essentials.politicians p
  JOIN seed s ON s.ext_id = p.external_id
)
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, source)
SELECT o.id, pol.id, s.term_start, NULL, s.precision, 'WA Legislature member web service (wslwebservices.leg.wa.gov SponsorService, biennium 2025-26) for identity/district/party/email; Ballotpedia chamber rosters for seat position and assumed-office date; all 147 seats reconciled across both. Retrieved 2026-08-13.'
FROM seed s
JOIN essentials.districts d
  ON d.geo_id = s.geo_id AND d.state ILIKE 'wa'
 AND d.district_type = s.dtype AND d.mtfcc = s.mtfcc
JOIN essentials.offices o
  ON o.district_id = d.id AND o.title = s.title
JOIN pol ON pol.external_id = s.ext_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot
  WHERE ot.office_id = o.id AND ot.politician_id = pol.id
);
