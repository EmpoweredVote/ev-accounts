-- CA_0424_indiana_cities_wave_b_people.sql
-- @incumbency-decision: no-effect — every office this writes a term on is BRAND NEW (created by this wave's structure migration) and carries no race; the post-verify below asserts 0 races on these governments' offices.
-- Indiana cities Wave B, occupancy half, for Michigan City, Greensburg, Jasper, New Haven, Warsaw, Bluffton, Beech Grove. Slot RESERVED from the
-- allocator. Follows the structure migration that created these 7 governments and 65 offices.
--
-- 🔴 APPLY IT THE SAME DAY AS THE STRUCTURE MIGRATION: an office with a polygon and no holder that is not
-- flagged vacant is DEAD_GEOGRAPHY to check:reachability. The post-verify below gates that at zero.
--
-- Seats 64 of 65 offices: 64 new people (external_id -18424001 .. -18424064,
-- asserted empty below) and 0 existing rows reused. 1 office(s) flagged vacant.
--
-- 🟢 EVERY NAME WAS CHECKED AGAINST A SAVED COPY OF ITS SOURCE PAGE (verify-collect.mjs in
-- backend/data/seed-in-cities-wave-b/, which runs an absent-name and a planted-name control first).
--
-- 🔴 TERM START IS 'unknown', NOT GUESSED. Most holders began on 2024-01-01 after the 2023 election, but
-- re-elected incumbents began earlier (re-election does not end an occupancy) and caucus appointees began
-- mid-term on dates the pages do not give. term_start is NULL with start_precision 'unknown' -- the
-- shape migration 1459's backfill used -- rather than a sourced-looking date that is false for some.
--
-- 🔴 NO term_end IS WRITTEN. These terms run to 2027-12-31; a future term_end would vacate every seat on
-- that date with no successor.
--
-- Bluffton Council District 2 is flagged vacant: the city's Common Council page lists "(Vacant Seat)" for the
-- 2nd District, and the city's council-district map layer says the same (raw/bluffton-in/council.html, read
-- 2026-11-24). No vacancy date is published, so vacant_since stays NULL.
-- Jasper numbers its five council districts 2 through 6 (council page); there is no District 1.
-- Greensburg's page titles its clerk "City Clerk-Treasurer"; the office is stored as Clerk-Treasurer, the
-- statutory third-class office.
--
-- NO EXISTING PERSON IS REUSED: match-people.mjs found no same-name row for any holder here (its positive
-- control, Sharon Tucker, matched).
--
-- 🔴 PARTY IS NOT WRITTEN (it lives on races.primary_party). alternate_names is never NULL.
-- 🔴 The at-large seats share one title, so they are matched on the internal ordinal the structure
-- migration wrote into description. Which person gets which ordinal is arbitrary and means nothing.
--
-- Idempotent: people NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- ─── 0. Pre-flight ───────────────────────────────────────────────────────────
DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM essentials.politicians WHERE external_id BETWEEN -18424064 AND -18424001;
  IF v NOT IN (0, 64) THEN RAISE EXCEPTION 'CA_0424 pre-flight: external_id band holds % rows, expected 0 (or 64 on a re-run)', v; END IF;

  SELECT count(*) INTO v FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Michigan City, Indiana, US', 'City of Greensburg, Indiana, US', 'City of Jasper, Indiana, US', 'City of New Haven, Indiana, US', 'City of Warsaw, Indiana, US', 'City of Bluffton, Indiana, US', 'City of Beech Grove, Indiana, US');
  IF v <> 65 THEN RAISE EXCEPTION 'CA_0424 pre-flight: % offices in these cities, expected 65 (is the structure migration applied?)', v; END IF;
END $$;

-- ─── 1. 64 new people ─────────────────────────────────────────────────────
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, alternate_names, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.name_suffix, n.source, n.alternate_names::text[], true
FROM (VALUES
  (-18424001, 'Angie Nelson Deuitch', 'Angie', 'Deuitch', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/city-departments/mayors-office/, read 2026-11-24', '{}'),
  (-18424002, 'Gale Neulieb', 'Gale', 'Neulieb', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/city-departments/city-clerk/, read 2026-11-24', '{}'),
  (-18424003, 'Gregory Coulter', 'Gregory', 'Coulter', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/government/boards-commissions/city-council/, read 2026-11-24', '{}'),
  (-18424004, 'Daisy Lee', 'Daisy', 'Lee', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/government/boards-commissions/city-council/, read 2026-11-24', '{}'),
  (-18424005, 'Joseph Nelson', 'Joseph', 'Nelson', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/government/boards-commissions/city-council/, read 2026-11-24', '{}'),
  (-18424006, 'Tim Bietry', 'Tim', 'Bietry', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/government/boards-commissions/city-council/, read 2026-11-24', '{}'),
  (-18424007, 'Tracie Tillman', 'Tracie', 'Tillman', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/government/boards-commissions/city-council/, read 2026-11-24', '{}'),
  (-18424008, 'Nancy Moldenhauer', 'Nancy', 'Moldenhauer', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/government/boards-commissions/city-council/, read 2026-11-24', '{}'),
  (-18424009, 'Bryant Dabney', 'Bryant', 'Dabney', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/government/boards-commissions/city-council/, read 2026-11-24', '{}'),
  (-18424010, 'Donald Przybylinski', 'Donald', 'Przybylinski', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/government/boards-commissions/city-council/, read 2026-11-24', '{}'),
  (-18424011, 'Vidya Kora', 'Vidya', 'Kora', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://michigancityin.gov/government/boards-commissions/city-council/, read 2026-11-24', '{}'),
  (-18424012, 'Joshua Marsh', 'Joshua', 'Marsh', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.cityofgreensburg.com/government/office-of-the-mayor/, read 2026-11-24', '{}'),
  (-18424013, 'Amy Borns', 'Amy', 'Borns', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.cityofgreensburg.com/government/clerk-treasurer/, read 2026-11-24', '{}'),
  (-18424014, 'Kevin Fleetwood', 'Kevin', 'Fleetwood', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.cityofgreensburg.com/government/city-council/, read 2026-11-24', '{}'),
  (-18424015, 'Rodney King', 'Rodney', 'King', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.cityofgreensburg.com/government/city-council/, read 2026-11-24', '{}'),
  (-18424016, 'Jamie Cain', 'Jamie', 'Cain', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.cityofgreensburg.com/government/city-council/, read 2026-11-24', '{}'),
  (-18424017, 'Darrell Poling', 'Darrell', 'Poling', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.cityofgreensburg.com/government/city-council/, read 2026-11-24', '{}'),
  (-18424018, 'Mark Carman', 'Mark', 'Carman', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.cityofgreensburg.com/government/city-council/, read 2026-11-24', '{}'),
  (-18424019, 'Vietta McKenzie', 'Vietta', 'McKenzie', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.cityofgreensburg.com/government/city-council/, read 2026-11-24', '{}'),
  (-18424020, 'Daryl Tressler', 'Daryl', 'Tressler', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.cityofgreensburg.com/government/city-council/, read 2026-11-24', '{}'),
  (-18424021, 'Ryan Craig', 'Ryan', 'Craig', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.jasperindiana.gov/department/index.php?structureid=16, read 2026-11-24', '{}'),
  (-18424022, 'Kiersten Knies', 'Kiersten', 'Knies', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.jasperindiana.gov/department/index.php?structureid=11, read 2026-11-24', '{}'),
  (-18424023, 'John Schroeder', 'John', 'Schroeder', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.jasperindiana.gov/council, read 2026-11-24', '{}'),
  (-18424024, 'Chad Lueken', 'Chad', 'Lueken', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.jasperindiana.gov/council, read 2026-11-24', '{}'),
  (-18424025, 'Vince Helming', 'Vince', 'Helming', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.jasperindiana.gov/council, read 2026-11-24', '{}'),
  (-18424026, 'Paul Lorey', 'Paul', 'Lorey', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.jasperindiana.gov/council, read 2026-11-24', '{}'),
  (-18424027, 'Kevin Manley', 'Kevin', 'Manley', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.jasperindiana.gov/council, read 2026-11-24', '{}'),
  (-18424028, 'Phil Mundy', 'Phil', 'Mundy', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.jasperindiana.gov/council, read 2026-11-24', '{}'),
  (-18424029, 'Nancy Eckerle', 'Nancy', 'Eckerle', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.jasperindiana.gov/council, read 2026-11-24', '{}'),
  (-18424030, 'Steve McMichael', 'Steve', 'McMichael', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.newhaven.in.gov/574/Meet-the-Council, read 2026-11-24', '{}'),
  (-18424031, 'Angie Hamrick', 'Angie', 'Hamrick', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.newhaven.in.gov/574/Meet-the-Council, read 2026-11-24', '{}'),
  (-18424032, 'Matt Newbauer', 'Matt', 'Newbauer', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.newhaven.in.gov/574/Meet-the-Council, read 2026-11-24', '{}'),
  (-18424033, 'Jeff Turner', 'Jeff', 'Turner', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.newhaven.in.gov/574/Meet-the-Council, read 2026-11-24', '{}'),
  (-18424034, 'Craig Dellinger', 'Craig', 'Dellinger', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.newhaven.in.gov/574/Meet-the-Council, read 2026-11-24', '{}'),
  (-18424035, 'Mike Mowery', 'Mike', 'Mowery', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.newhaven.in.gov/574/Meet-the-Council, read 2026-11-24', '{}'),
  (-18424036, 'Amelia Gascoigne', 'Amelia', 'Gascoigne', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.newhaven.in.gov/574/Meet-the-Council, read 2026-11-24', '{}'),
  (-18424037, 'Bob Byrd', 'Bob', 'Byrd', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.newhaven.in.gov/574/Meet-the-Council, read 2026-11-24', '{}'),
  (-18424038, 'Terry Werling', 'Terry', 'Werling', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.newhaven.in.gov/574/Meet-the-Council, read 2026-11-24', '{}'),
  (-18424039, 'Jeff R. Grose', 'Jeff', 'Grose', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.warsaw.in.gov/Directory.aspx, read 2026-11-24', '{}'),
  (-18424040, 'Lynne Christiansen', 'Lynne', 'Christiansen', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.warsaw.in.gov/Directory.aspx, read 2026-11-24', '{}'),
  (-18424041, 'Juergen Voss', 'Juergen', 'Voss', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.warsaw.in.gov/Directory.aspx, read 2026-11-24', '{}'),
  (-18424042, 'Josh Finch', 'Josh', 'Finch', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.warsaw.in.gov/Directory.aspx, read 2026-11-24', '{}'),
  (-18424043, 'Michael Klondaris', 'Michael', 'Klondaris', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.warsaw.in.gov/Directory.aspx, read 2026-11-24', '{}'),
  (-18424044, 'William G. Frush', 'William', 'Frush', 'Jerry', NULL, 'CA_0424 Indiana cities Wave B: https://www.warsaw.in.gov/Directory.aspx, read 2026-11-24', '{}'),
  (-18424045, 'Diane L. Quance', 'Diane', 'Quance', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.warsaw.in.gov/Directory.aspx, read 2026-11-24', '{}'),
  (-18424046, 'Cindy A. Dobbins', 'Cindy', 'Dobbins', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.warsaw.in.gov/Directory.aspx, read 2026-11-24', '{}'),
  (-18424047, 'Jack Wilhite', 'Jack', 'Wilhite', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.warsaw.in.gov/Directory.aspx, read 2026-11-24', '{}'),
  (-18424048, 'Scott Mentzer', 'Scott', 'Mentzer', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.blufftonindiana.net/297/Mayor, read 2026-11-24', '{}'),
  (-18424049, 'Bri Lautzenheiser', 'Bri', 'Lautzenheiser', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.blufftonindiana.net/m/directory/department?did=22, read 2026-11-24', '{}'),
  (-18424050, 'Ron Neuenschwander', 'Ron', 'Neuenschwander', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.blufftonindiana.net/197/Common-Council, read 2026-11-24', '{}'),
  (-18424051, 'Janella Stronczek', 'Janella', 'Stronczek', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.blufftonindiana.net/197/Common-Council, read 2026-11-24', '{}'),
  (-18424052, 'David Teeple', 'David', 'Teeple', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.blufftonindiana.net/197/Common-Council, read 2026-11-24', '{}'),
  (-18424053, 'Sarah Reed', 'Sarah', 'Reed', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.blufftonindiana.net/197/Common-Council, read 2026-11-24', '{}'),
  (-18424054, 'Rick Elwell', 'Rick', 'Elwell', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.blufftonindiana.net/197/Common-Council, read 2026-11-24', '{}'),
  (-18424055, 'Josh Hunt', 'Josh', 'Hunt', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.blufftonindiana.net/197/Common-Council, read 2026-11-24', '{}'),
  (-18424056, 'James W. Coffman', 'James', 'Coffman', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://beechgrove.com/mayors-office, read 2026-11-24', '{}'),
  (-18424057, 'Samantha S. Stratton', 'Samantha', 'Stratton', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.beechgrove.com/clerk-treasurers-office, read 2026-11-24', '{}'),
  (-18424058, 'Elizabeth Lamping', 'Elizabeth', 'Lamping', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.beechgrove.com/common-council, read 2026-11-24', '{}'),
  (-18424059, 'Ryan Matkins', 'Ryan', 'Matkins', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.beechgrove.com/common-council, read 2026-11-24', '{}'),
  (-18424060, 'Michael Hemmelgarn', 'Michael', 'Hemmelgarn', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.beechgrove.com/common-council, read 2026-11-24', '{}'),
  (-18424061, 'Avis Frieson', 'Avis', 'Frieson', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.beechgrove.com/common-council, read 2026-11-24', '{}'),
  (-18424062, 'Mike Earnest', 'Mike', 'Earnest', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.beechgrove.com/common-council, read 2026-11-24', '{}'),
  (-18424063, 'Dan McMillan', 'Dan', 'McMillan', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.beechgrove.com/common-council, read 2026-11-24', '{}'),
  (-18424064, 'Chris Duffer', 'Chris', 'Duffer', NULL, NULL, 'CA_0424 Indiana cities Wave B: https://www.beechgrove.com/common-council, read 2026-11-24', '{}')
) AS n(external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, alternate_names)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. (no reused people) ───────────────────────────────────────────────────

-- ─── 3. 64 terms ──────────────────────────────────────────────────────────
CREATE TEMP TABLE w_terms(ext bigint, pid uuid, gov text, geo_id text, title text, ordinal int, of_n int, src text) ON COMMIT DROP;
INSERT INTO w_terms VALUES
  (-18424001, NULL, 'City of Michigan City, Indiana, US', '1848798', 'Mayor', NULL, NULL, 'https://michigancityin.gov/city-departments/mayors-office/'),
  (-18424002, NULL, 'City of Michigan City, Indiana, US', '1848798', 'City Clerk', NULL, NULL, 'https://michigancityin.gov/city-departments/city-clerk/'),
  (-18424003, NULL, 'City of Michigan City, Indiana, US', 'michigan-city-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://michigancityin.gov/government/boards-commissions/city-council/'),
  (-18424004, NULL, 'City of Michigan City, Indiana, US', 'michigan-city-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://michigancityin.gov/government/boards-commissions/city-council/'),
  (-18424005, NULL, 'City of Michigan City, Indiana, US', 'michigan-city-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://michigancityin.gov/government/boards-commissions/city-council/'),
  (-18424006, NULL, 'City of Michigan City, Indiana, US', 'michigan-city-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://michigancityin.gov/government/boards-commissions/city-council/'),
  (-18424007, NULL, 'City of Michigan City, Indiana, US', 'michigan-city-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://michigancityin.gov/government/boards-commissions/city-council/'),
  (-18424008, NULL, 'City of Michigan City, Indiana, US', 'michigan-city-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://michigancityin.gov/government/boards-commissions/city-council/'),
  (-18424009, NULL, 'City of Michigan City, Indiana, US', '1848798', 'Council Member, At Large', 1, 3, 'https://michigancityin.gov/government/boards-commissions/city-council/'),
  (-18424010, NULL, 'City of Michigan City, Indiana, US', '1848798', 'Council Member, At Large', 2, 3, 'https://michigancityin.gov/government/boards-commissions/city-council/'),
  (-18424011, NULL, 'City of Michigan City, Indiana, US', '1848798', 'Council Member, At Large', 3, 3, 'https://michigancityin.gov/government/boards-commissions/city-council/'),
  (-18424012, NULL, 'City of Greensburg, Indiana, US', '1829718', 'Mayor', NULL, NULL, 'https://www.cityofgreensburg.com/government/office-of-the-mayor/'),
  (-18424013, NULL, 'City of Greensburg, Indiana, US', '1829718', 'Clerk-Treasurer', NULL, NULL, 'https://www.cityofgreensburg.com/government/clerk-treasurer/'),
  (-18424014, NULL, 'City of Greensburg, Indiana, US', 'greensburg-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.cityofgreensburg.com/government/city-council/'),
  (-18424015, NULL, 'City of Greensburg, Indiana, US', 'greensburg-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.cityofgreensburg.com/government/city-council/'),
  (-18424016, NULL, 'City of Greensburg, Indiana, US', 'greensburg-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.cityofgreensburg.com/government/city-council/'),
  (-18424017, NULL, 'City of Greensburg, Indiana, US', 'greensburg-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.cityofgreensburg.com/government/city-council/'),
  (-18424018, NULL, 'City of Greensburg, Indiana, US', '1829718', 'Council Member, At Large', 1, 3, 'https://www.cityofgreensburg.com/government/city-council/'),
  (-18424019, NULL, 'City of Greensburg, Indiana, US', '1829718', 'Council Member, At Large', 2, 3, 'https://www.cityofgreensburg.com/government/city-council/'),
  (-18424020, NULL, 'City of Greensburg, Indiana, US', '1829718', 'Council Member, At Large', 3, 3, 'https://www.cityofgreensburg.com/government/city-council/'),
  (-18424021, NULL, 'City of Jasper, Indiana, US', '1837782', 'Mayor', NULL, NULL, 'https://www.jasperindiana.gov/department/index.php?structureid=16'),
  (-18424022, NULL, 'City of Jasper, Indiana, US', '1837782', 'Clerk-Treasurer', NULL, NULL, 'https://www.jasperindiana.gov/department/index.php?structureid=11'),
  (-18424023, NULL, 'City of Jasper, Indiana, US', 'jasper-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.jasperindiana.gov/council'),
  (-18424024, NULL, 'City of Jasper, Indiana, US', 'jasper-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.jasperindiana.gov/council'),
  (-18424025, NULL, 'City of Jasper, Indiana, US', 'jasper-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.jasperindiana.gov/council'),
  (-18424026, NULL, 'City of Jasper, Indiana, US', 'jasper-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.jasperindiana.gov/council'),
  (-18424027, NULL, 'City of Jasper, Indiana, US', 'jasper-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://www.jasperindiana.gov/council'),
  (-18424028, NULL, 'City of Jasper, Indiana, US', '1837782', 'Council Member, At Large', 1, 2, 'https://www.jasperindiana.gov/council'),
  (-18424029, NULL, 'City of Jasper, Indiana, US', '1837782', 'Council Member, At Large', 2, 2, 'https://www.jasperindiana.gov/council'),
  (-18424030, NULL, 'City of New Haven, Indiana, US', '1852992', 'Mayor', NULL, NULL, 'https://www.newhaven.in.gov/574/Meet-the-Council'),
  (-18424031, NULL, 'City of New Haven, Indiana, US', '1852992', 'Clerk-Treasurer', NULL, NULL, 'https://www.newhaven.in.gov/574/Meet-the-Council'),
  (-18424032, NULL, 'City of New Haven, Indiana, US', 'new-haven-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.newhaven.in.gov/574/Meet-the-Council'),
  (-18424033, NULL, 'City of New Haven, Indiana, US', 'new-haven-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.newhaven.in.gov/574/Meet-the-Council'),
  (-18424034, NULL, 'City of New Haven, Indiana, US', 'new-haven-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.newhaven.in.gov/574/Meet-the-Council'),
  (-18424035, NULL, 'City of New Haven, Indiana, US', 'new-haven-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.newhaven.in.gov/574/Meet-the-Council'),
  (-18424036, NULL, 'City of New Haven, Indiana, US', 'new-haven-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.newhaven.in.gov/574/Meet-the-Council'),
  (-18424037, NULL, 'City of New Haven, Indiana, US', '1852992', 'Council Member, At Large', 1, 2, 'https://www.newhaven.in.gov/574/Meet-the-Council'),
  (-18424038, NULL, 'City of New Haven, Indiana, US', '1852992', 'Council Member, At Large', 2, 2, 'https://www.newhaven.in.gov/574/Meet-the-Council'),
  (-18424039, NULL, 'City of Warsaw, Indiana, US', '1880306', 'Mayor', NULL, NULL, 'https://www.warsaw.in.gov/Directory.aspx'),
  (-18424040, NULL, 'City of Warsaw, Indiana, US', '1880306', 'Clerk-Treasurer', NULL, NULL, 'https://www.warsaw.in.gov/Directory.aspx'),
  (-18424041, NULL, 'City of Warsaw, Indiana, US', 'warsaw-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.warsaw.in.gov/Directory.aspx'),
  (-18424042, NULL, 'City of Warsaw, Indiana, US', 'warsaw-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.warsaw.in.gov/Directory.aspx'),
  (-18424043, NULL, 'City of Warsaw, Indiana, US', 'warsaw-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.warsaw.in.gov/Directory.aspx'),
  (-18424044, NULL, 'City of Warsaw, Indiana, US', 'warsaw-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.warsaw.in.gov/Directory.aspx'),
  (-18424045, NULL, 'City of Warsaw, Indiana, US', 'warsaw-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.warsaw.in.gov/Directory.aspx'),
  (-18424046, NULL, 'City of Warsaw, Indiana, US', '1880306', 'Council Member, At Large', 1, 2, 'https://www.warsaw.in.gov/Directory.aspx'),
  (-18424047, NULL, 'City of Warsaw, Indiana, US', '1880306', 'Council Member, At Large', 2, 2, 'https://www.warsaw.in.gov/Directory.aspx'),
  (-18424048, NULL, 'City of Bluffton, Indiana, US', '1806220', 'Mayor', NULL, NULL, 'https://www.blufftonindiana.net/297/Mayor'),
  (-18424049, NULL, 'City of Bluffton, Indiana, US', '1806220', 'Clerk-Treasurer', NULL, NULL, 'https://www.blufftonindiana.net/m/directory/department?did=22'),
  (-18424050, NULL, 'City of Bluffton, Indiana, US', 'bluffton-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.blufftonindiana.net/197/Common-Council'),
  (-18424051, NULL, 'City of Bluffton, Indiana, US', 'bluffton-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.blufftonindiana.net/197/Common-Council'),
  (-18424052, NULL, 'City of Bluffton, Indiana, US', 'bluffton-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.blufftonindiana.net/197/Common-Council'),
  (-18424053, NULL, 'City of Bluffton, Indiana, US', 'bluffton-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.blufftonindiana.net/197/Common-Council'),
  (-18424054, NULL, 'City of Bluffton, Indiana, US', '1806220', 'Council Member, At Large', 1, 2, 'https://www.blufftonindiana.net/197/Common-Council'),
  (-18424055, NULL, 'City of Bluffton, Indiana, US', '1806220', 'Council Member, At Large', 2, 2, 'https://www.blufftonindiana.net/197/Common-Council'),
  (-18424056, NULL, 'City of Beech Grove, Indiana, US', '1804204', 'Mayor', NULL, NULL, 'https://beechgrove.com/mayors-office'),
  (-18424057, NULL, 'City of Beech Grove, Indiana, US', '1804204', 'Clerk-Treasurer', NULL, NULL, 'https://www.beechgrove.com/clerk-treasurers-office'),
  (-18424058, NULL, 'City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.beechgrove.com/common-council'),
  (-18424059, NULL, 'City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.beechgrove.com/common-council'),
  (-18424060, NULL, 'City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.beechgrove.com/common-council'),
  (-18424061, NULL, 'City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.beechgrove.com/common-council'),
  (-18424062, NULL, 'City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.beechgrove.com/common-council'),
  (-18424063, NULL, 'City of Beech Grove, Indiana, US', '1804204', 'Council Member, At Large', 1, 2, 'https://www.beechgrove.com/common-council'),
  (-18424064, NULL, 'City of Beech Grove, Indiana, US', '1804204', 'Council Member, At Large', 2, 2, 'https://www.beechgrove.com/common-council');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',
       'CA_0424 Indiana cities Wave B: holder named on ' || t.src || ', read 2026-11-24; start date not published'
FROM w_terms t
JOIN essentials.governments g ON g.name = t.gov
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = t.title
 AND (t.ordinal IS NULL OR o.description LIKE 'Internal ordinal ' || t.ordinal || ' of ' || t.of_n || '.%')
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = t.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.politicians p ON (t.pid IS NOT NULL AND p.id = t.pid) OR (t.ext IS NOT NULL AND p.external_id = t.ext)
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── 4. Vacancy ──────────────────────────────────────────────────────────────
UPDATE essentials.offices o SET is_vacant = true, vacant_since = NULL
  FROM essentials.chambers c, essentials.governments g, essentials.districts d
 WHERE c.id = o.chamber_id AND g.id = c.government_id AND d.id = o.district_id
   AND g.name = 'City of Bluffton, Indiana, US' AND o.title = 'Council Member, District 2' AND d.geo_id = 'bluffton-in-council-district-2';

-- ─── 5. Post-verify ──────────────────────────────────────────────────────────
DO $$
DECLARE v_off int; v_seat int; v_vac int; v_dead int; v_held_vac int; v_dupe int; v_inact int; v_ended int; v_terms int;
BEGIN
  -- count(och.politician_id), never count(*): the view LEFT JOINs from offices.
  SELECT count(o.id), count(och.politician_id), count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE och.politician_id IS NULL AND NOT coalesce(o.is_vacant, false)),
         count(*) FILTER (WHERE och.politician_id IS NOT NULL AND o.is_vacant)
    INTO v_off, v_seat, v_vac, v_dead, v_held_vac
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.name IN ('City of Michigan City, Indiana, US', 'City of Greensburg, Indiana, US', 'City of Jasper, Indiana, US', 'City of New Haven, Indiana, US', 'City of Warsaw, Indiana, US', 'City of Bluffton, Indiana, US', 'City of Beech Grove, Indiana, US');
  IF v_off <> 65 OR v_seat <> 64 OR v_vac <> 1 OR v_dead <> 0 OR v_held_vac <> 0 THEN
    RAISE EXCEPTION 'CA_0424: offices %/65, seated %/64, vacant %/1, unseated-unflagged % (want 0), seated-and-flagged % (want 0)',
      v_off, v_seat, v_vac, v_dead, v_held_vac;
  END IF;

  -- No person holds two seats in these cities (a loose at-large match would seat one person three times).
  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE g.name IN ('City of Michigan City, Indiana, US', 'City of Greensburg, Indiana, US', 'City of Jasper, Indiana, US', 'City of New Haven, Indiana, US', 'City of Warsaw, Indiana, US', 'City of Bluffton, Indiana, US', 'City of Beech Grove, Indiana, US') GROUP BY och.politician_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'CA_0424: % people hold more than one seat in these cities', v_dupe; END IF;

  SELECT count(*) FILTER (WHERE NOT p.is_active), count(*) FILTER (WHERE ot.term_end IS NOT NULL), count(*)
    INTO v_inact, v_ended, v_terms
  FROM essentials.office_terms ot
  JOIN essentials.politicians p ON p.id = ot.politician_id
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name IN ('City of Michigan City, Indiana, US', 'City of Greensburg, Indiana, US', 'City of Jasper, Indiana, US', 'City of New Haven, Indiana, US', 'City of Warsaw, Indiana, US', 'City of Bluffton, Indiana, US', 'City of Beech Grove, Indiana, US');
  IF v_inact <> 0 OR v_ended <> 0 OR v_terms <> 64 THEN
    RAISE EXCEPTION 'CA_0424: % inactive holders, % ended terms, % terms (want 0, 0, 64)', v_inact, v_ended, v_terms;
  END IF;

  -- Backs the @incumbency-decision line: a term on an office with a race would restate race_candidates.is_incumbent.
  IF EXISTS (SELECT 1 FROM essentials.races r JOIN essentials.offices o ON o.id = r.office_id
               JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
              WHERE g.name IN ('City of Michigan City, Indiana, US', 'City of Greensburg, Indiana, US', 'City of Jasper, Indiana, US', 'City of New Haven, Indiana, US', 'City of Warsaw, Indiana, US', 'City of Bluffton, Indiana, US', 'City of Beech Grove, Indiana, US')) THEN
    RAISE EXCEPTION 'CA_0424: an office in these cities carries a race; the no-effect incumbency decision is false';
  END IF;

  RAISE NOTICE 'CA_0424 OK: 65 offices, 64 seated (64 new + 0 reused), 1 vacant, 0 dead, 0 doubled';
END $$;

COMMIT;
