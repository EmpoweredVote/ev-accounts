-- CA_0417_indiana_cities_wave_a_people.sql
-- Indiana cities Wave A, occupancy half. Slot RESERVED from the allocator. Follows CA_0416, which
-- created the 13 governments and 139 offices with no holder.
--
-- 🔴 WHY THIS HAS TO FOLLOW CA_0416 PROMPTLY: an office with a polygon and no holder that is not
-- flagged vacant is DEAD_GEOGRAPHY to check:reachability. CA_0416 alone took in|LOCAL from 12 to 101
-- (the 89 new districts). This migration seats 138 offices and flags 1 vacant, so every one of
-- the 89 districts resolves someone or says it is vacant.
--
-- Seats 138 of 139 offices: 133 new people (external_id -18417001 .. -18417133,
-- asserted empty below) and 5 existing rows reused. 1 office flagged vacant.
--
-- 🟢 EVERY NAME WAS CHECKED AGAINST A SAVED COPY OF ITS SOURCE PAGE (verify-collect.mjs in
-- backend/data/seed-in-cities-wave-a/, which runs an absent-name and a planted-name control first).
-- The city's own page is the source for every holder except Westfield, whose site refuses this
-- machine: Westfield's names come from the city's own GIS "Elected Officials" layer and agree with the
-- 2023 general election results.
--
-- 🔴 TERM START IS 'unknown', NOT GUESSED. Most of these people began on 2024-01-01 after the 2023
-- election, but some are re-elected incumbents (occupancy began earlier; re-election does not end
-- an occupancy) and some were seated mid-term by caucus (Evansville Districts 2 and 4, South Bend
-- District 4, likely Lafayette District 2), with no date on the page. Writing 2024-01-01 for all of
-- them would put a sourced-looking but false date on real people. term_start is NULL with
-- start_precision 'unknown' -- the shape migration 1459's backfill used.
--
-- 🔴 NO term_end IS WRITTEN. These terms run to 2027-12-31; a future term_end would vacate every
-- seat on that date with no successor.
--
-- 🔴 ONE OFFICE IS FLAGGED VACANT, NOT SEATED: Muncie Council District 4. The city page still lists
-- Sara Gullion, but she won Indiana House District 34 on 2026-11-03 and "winning the House seat
-- meant resigning from the Council"; the Delaware County Democratic Party holds a caucus on
-- 2026-11-30 to fill it (Muncie Voice, saved raw/muncie-in/voice-surveillance.html). She already
-- holds HD-34 in production (CA_0396). The resignation DAY is not published, so vacant_since stays
-- NULL rather than a guessed date. ▶ Seat the caucus winner after 2026-11-30.
--
-- REUSED PEOPLE (each matched by surname + first name, then checked by hand; Sharon Tucker was the
-- positive control and matched):
--   Mary Allen       97243dc4-1b2c-4e37-b480-264f47b3f1bd  same person: the at-large Evansville councilor ran for Indiana's 8th Congressional District in 2026 (row holds that candidacy)
--   Heidi Beidinger  5c85d165-6c32-415b-a220-d51b42668cf6  inactive indiana_discovery stub (Indiana elected officials), deactivated by CC_0101; no other row
--   Dale Basham      245d3807-f6ee-44be-a321-bd597d0aab7a  inactive indiana_discovery stub, deactivated by CC_0101; no other row
--   Aaron Mishler    c2cfdf00-d537-4c57-92a8-27dadf7a0274  inactive indiana_discovery stub, deactivated by CC_0101; no other row
--   Scott Hawkins    856009a9-d2f9-4984-bbe9-76c261c72f94  inactive indiana_discovery stub, deactivated by CC_0101; no other row
--   The four indiana_discovery stubs are re-activated (is_active = true): an inactive person in a
--   seat is hidden by the reps feed, which check:reachability counts as REPS_FILTER_HIDDEN.
-- SAME NAME, DIFFERENT PERSON (new rows made, existing ones untouched):
--   Mike Moore     existing row is a 2026 candidate for State House District 60 (Monroe County);
--                  this one is the Mayor of Jeffersonville (Clark County)
--   Steve Webb     existing 'Steven E. Webb' is a Clear Creek Township (Monroe County) candidate
--   Dave Wood      existing row is a Colorado congressional candidate
--
-- 🔴 PARTY IS NOT WRITTEN (it lives on races.primary_party). alternate_names is never NULL.
-- 🔴 The at-large seats share one title, so they are matched on the internal ordinal CA_0416 wrote
-- into description. Which person gets which ordinal is arbitrary and means nothing.
--
-- Idempotent: people NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- The duplicate-name guard stops on exactly one row, Mike Moore, and he is a different person: the
-- existing row (c554cb1f, source sos_excel) is a 2026 Republican primary candidate for Indiana House
-- District 60 (Morgan/Monroe counties, against Peggy Mayfield); this one is the sitting Mayor of
-- Jeffersonville, Clark County. Dry-run without this line names Mike Moore and nobody else.
SET LOCAL essentials.allow_duplicate_name = 'on';

-- ─── 0. Pre-flight ───────────────────────────────────────────────────────────
DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM essentials.politicians WHERE external_id BETWEEN -18417133 AND -18417001;
  IF v NOT IN (0, 133) THEN RAISE EXCEPTION 'CA_0417 pre-flight: external_id band holds % rows, expected 0 (or 133 on a re-run)', v; END IF;
  SELECT count(*) INTO v FROM essentials.politicians WHERE id IN ('97243dc4-1b2c-4e37-b480-264f47b3f1bd', '5c85d165-6c32-415b-a220-d51b42668cf6', '245d3807-f6ee-44be-a321-bd597d0aab7a', 'c2cfdf00-d537-4c57-92a8-27dadf7a0274', '856009a9-d2f9-4984-bbe9-76c261c72f94');
  IF v <> 5 THEN RAISE EXCEPTION 'CA_0417 pre-flight: % of 5 reused people exist', v; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '97243dc4-1b2c-4e37-b480-264f47b3f1bd' AND full_name = 'Mary Allen') THEN
    RAISE EXCEPTION 'CA_0417 pre-flight: reused row 97243dc4-1b2c-4e37-b480-264f47b3f1bd is no longer named Mary Allen'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '5c85d165-6c32-415b-a220-d51b42668cf6' AND full_name = 'Heidi Beidinger') THEN
    RAISE EXCEPTION 'CA_0417 pre-flight: reused row 5c85d165-6c32-415b-a220-d51b42668cf6 is no longer named Heidi Beidinger'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '245d3807-f6ee-44be-a321-bd597d0aab7a' AND full_name = 'Dale Basham') THEN
    RAISE EXCEPTION 'CA_0417 pre-flight: reused row 245d3807-f6ee-44be-a321-bd597d0aab7a is no longer named Dale Basham'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = 'c2cfdf00-d537-4c57-92a8-27dadf7a0274' AND full_name = 'Aaron Mishler') THEN
    RAISE EXCEPTION 'CA_0417 pre-flight: reused row c2cfdf00-d537-4c57-92a8-27dadf7a0274 is no longer named Aaron Mishler'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '856009a9-d2f9-4984-bbe9-76c261c72f94' AND full_name = 'Scott Hawkins') THEN
    RAISE EXCEPTION 'CA_0417 pre-flight: reused row 856009a9-d2f9-4984-bbe9-76c261c72f94 is no longer named Scott Hawkins'; END IF;
  SELECT count(*) INTO v FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Evansville, Indiana, US', 'City of South Bend, Indiana, US', 'City of Carmel, Indiana, US', 'City of Lafayette, Indiana, US', 'City of Muncie, Indiana, US', 'City of Westfield, Indiana, US', 'City of Terre Haute, Indiana, US', 'City of Elkhart, Indiana, US', 'City of Jeffersonville, Indiana, US', 'City of Mishawaka, Indiana, US', 'City of Lawrence, Indiana, US', 'City of New Albany, Indiana, US', 'City of Goshen, Indiana, US');
  IF v <> 139 THEN RAISE EXCEPTION 'CA_0417 pre-flight: % offices in the 13 cities, expected 139 (is CA_0416 applied?)', v; END IF;
END $$;

-- ─── 1. 133 new people ─────────────────────────────────────────────────────
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, alternate_names, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.name_suffix, n.source, n.alternate_names::text[], true
FROM (VALUES
  (-18417001, 'Stephanie Terry', 'Stephanie', 'Terry', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/department/index.php?structureid=8, read 2026-11-24', '{}'),
  (-18417002, 'Laura Windhorst', 'Laura', 'Windhorst', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/department/index.php?structureid=15, read 2026-11-24', '{}'),
  (-18417003, 'Ben Trockman', 'Ben', 'Trockman', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16, read 2026-11-24', '{}'),
  (-18417004, 'Rita Taylor', 'Rita', 'Taylor', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16, read 2026-11-24', '{}'),
  (-18417005, 'Zac Heronemus', 'Zac', 'Heronemus', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16, read 2026-11-24', '{}'),
  (-18417006, 'Kendra Hatfield', 'Kendra', 'Hatfield', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16, read 2026-11-24', '{}'),
  (-18417007, 'Angela Koehler Lindsey', 'Angela', 'Lindsey', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16, read 2026-11-24', '{}'),
  (-18417008, 'Jim Brinkmeyer', 'Jim', 'Brinkmeyer', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16, read 2026-11-24', '{}'),
  (-18417009, 'Paul Green', 'Paul', 'Green', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16, read 2026-11-24', '{}'),
  (-18417010, 'Courtney Johnson', 'Courtney', 'Johnson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16, read 2026-11-24', '{}'),
  (-18417011, 'James Mueller', 'James', 'Mueller', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417012, 'Bianca Tirado', 'Bianca', 'Tirado', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417013, 'Canneth Lee', 'Canneth', 'Lee', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417014, 'Ophelia Gooden-Rodgers', 'Ophelia', 'Gooden-Rodgers', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417015, 'Sharon McBride', 'Sharon', 'McBride', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417016, 'Sherry Bolden-Simpson', 'Sherry', 'Bolden-Simpson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417017, 'Sheila Niezgodski', 'Sheila', 'Niezgodski', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417018, 'Oliver Davis', 'Oliver', 'Davis', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417019, 'Karen White', 'Karen', 'White', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417020, 'Rachel Tomas Morgan', 'Rachel', 'Morgan', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://southbendin.gov/official/, read 2026-11-24', '{}'),
  (-18417021, 'Sue Finkam', 'Sue', 'Finkam', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20260129213512/https://www.carmel.in.gov/government/mayor, read 2026-11-24', '{}'),
  (-18417022, 'Jacob Quinn', 'Jacob', 'Quinn', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20251220010312/https://www.carmel.in.gov/government/clerk-of-the-city/staff-directory, read 2026-11-24', '{}'),
  (-18417023, 'Teresa Ayers', 'Teresa', 'Ayers', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council, read 2026-11-24', '{}'),
  (-18417024, 'Shannon Minnaar', 'Shannon', 'Minnaar', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council, read 2026-11-24', '{}'),
  (-18417025, 'Adam Aasen', 'Adam', 'Aasen', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council, read 2026-11-24', '{}'),
  (-18417026, 'Ryan Locke', 'Ryan', 'Locke', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council, read 2026-11-24', '{}'),
  (-18417027, 'Tony Green', 'Tony', 'Green', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council, read 2026-11-24', '{}'),
  (-18417028, 'Anita Joshi', 'Anita', 'Joshi', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council, read 2026-11-24', '{}'),
  (-18417029, 'Matthew Snyder', 'Matthew', 'Snyder', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council, read 2026-11-24', '{}'),
  (-18417030, 'Rich Taylor', 'Rich', 'Taylor', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council, read 2026-11-24', '{}'),
  (-18417031, 'Jeff Worrell', 'Jeff', 'Worrell', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council, read 2026-11-24', '{}'),
  (-18417032, 'Tony Roswarski', 'Tony', 'Roswarski', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20260822112159/https://www.lafayette.in.gov/657/Mayors-Office, read 2026-11-24', '{}'),
  (-18417033, 'Cindy Murray', 'Cindy', 'Murray', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20260105172504/http://lafayette.in.gov/153/City-Clerk, read 2026-11-24', '{}'),
  (-18417034, 'Jerry Reynolds', 'Jerry', 'Reynolds', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council, read 2026-11-24', '{}'),
  (-18417035, 'Eileen Hession Weiss', 'Eileen', 'Weiss', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council, read 2026-11-24', '{}'),
  (-18417036, 'Perry E. Brown', 'Perry', 'Brown', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council, read 2026-11-24', '{}'),
  (-18417037, 'Lauren Ahlersmeyer', 'Lauren', 'Ahlersmeyer', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council, read 2026-11-24', '{}'),
  (-18417038, 'Melissa Weast-Williamson', 'Melissa', 'Weast-Williamson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council, read 2026-11-24', '{}'),
  (-18417039, 'Bob Downing', 'Bob', 'Downing', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council, read 2026-11-24', '{}'),
  (-18417040, 'Kevin Klinker', 'Kevin', 'Klinker', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council, read 2026-11-24', '{}'),
  (-18417041, 'Nancy Nargi', 'Nancy', 'Nargi', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council, read 2026-11-24', '{}'),
  (-18417042, 'Steve Snyder', 'Steve', 'Snyder', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council, read 2026-11-24', '{}'),
  (-18417043, 'Dan Ridenour', 'Dan', 'Ridenour', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.muncie.in.gov/department/index.php?structureid=14, read 2026-11-24', '{}'),
  (-18417044, 'Belinda Munson', 'Belinda', 'Munson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.muncie.in.gov/department/index.php?structureid=17, read 2026-11-24', '{}'),
  (-18417045, 'Jeff Green', 'Jeff', 'Green', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.muncie.in.gov/council, read 2026-11-24', '{}'),
  (-18417046, 'Nora Powell', 'Nora', 'Powell', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.muncie.in.gov/council, read 2026-11-24', '{}'),
  (-18417047, 'Brandon Garrett', 'Brandon', 'Garrett', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.muncie.in.gov/council, read 2026-11-24', '{}'),
  (-18417048, 'Jerry D. Dishman', 'Jerry', 'Dishman', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.muncie.in.gov/council, read 2026-11-24', '{}'),
  (-18417049, 'Harold Mason Jr.', 'Harold', 'Mason', NULL, 'Jr.', 'CA_0417 Indiana cities Wave A: https://www.muncie.in.gov/council, read 2026-11-24', '{}'),
  (-18417050, 'Ro Selvey', 'Ro', 'Selvey', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.muncie.in.gov/council, read 2026-11-24', '{}'),
  (-18417051, 'William McIntosh Sr.', 'William', 'McIntosh', NULL, 'Sr.', 'CA_0417 Indiana cities Wave A: https://www.muncie.in.gov/council, read 2026-11-24', '{}'),
  (-18417052, 'Scott Willis', 'Scott', 'Willis', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0, read 2026-11-24', '{}'),
  (-18417053, 'Marla Ailor', 'Marla', 'Ailor', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0, read 2026-11-24', '{}'),
  (-18417054, 'Jon Dartt', 'Jon', 'Dartt', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0, read 2026-11-24', '{}'),
  (-18417055, 'Victor McCarty', 'Victor', 'McCarty', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0, read 2026-11-24', '{}'),
  (-18417056, 'Joe Duepner', 'Joe', 'Duepner', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0, read 2026-11-24', '{}'),
  (-18417057, 'Patrick Tamm', 'Patrick', 'Tamm', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0, read 2026-11-24', '{}'),
  (-18417058, 'Noah Herron', 'Noah', 'Herron', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0, read 2026-11-24', '{}'),
  (-18417059, 'Chad Huff', 'Chad', 'Huff', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0, read 2026-11-24', '{}'),
  (-18417060, 'Kurt Wanninger', 'Kurt', 'Wanninger', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0, read 2026-11-24', '{}'),
  (-18417061, 'Brandon Sakbun', 'Brandon', 'Sakbun', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.terrehaute.in.gov/government/city_council/index.php, read 2026-11-24', '{}'),
  (-18417062, 'Michelle Edwards', 'Michelle', 'Edwards', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.terrehaute.in.gov/departments/staff_directory/index.php, read 2026-11-24', '{}'),
  (-18417063, 'Kandace Hinton', 'Kandace', 'Hinton', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://terrehaute.in.gov/government/city_council/city_council_district_maps.php, read 2026-11-24', '{}'),
  (-18417064, 'Amanda Thompson', 'Amanda', 'Thompson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://terrehaute.in.gov/government/city_council/city_council_district_maps.php, read 2026-11-24', '{}'),
  (-18417065, 'Cheryl Loudermilk', 'Cheryl', 'Loudermilk', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://terrehaute.in.gov/government/city_council/city_council_district_maps.php, read 2026-11-24', '{}'),
  (-18417066, 'Todd Nation', 'Todd', 'Nation', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://terrehaute.in.gov/government/city_council/city_council_district_maps.php, read 2026-11-24', '{}'),
  (-18417067, 'James Chalos', 'James', 'Chalos', 'Jim', NULL, 'CA_0417 Indiana cities Wave A: https://terrehaute.in.gov/government/city_council/city_council_district_maps.php, read 2026-11-24', '{}'),
  (-18417068, 'Anthony Dinkel', 'Anthony', 'Dinkel', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://terrehaute.in.gov/government/city_council/city_council_district_maps.php, read 2026-11-24', '{}'),
  (-18417069, 'George J. Azar', 'George', 'Azar', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.terrehaute.in.gov/government/city_council/index.php, read 2026-11-24', '{}'),
  (-18417070, 'Tammy Boland', 'Tammy', 'Boland', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.terrehaute.in.gov/government/city_council/index.php, read 2026-11-24', '{}'),
  (-18417071, 'Curtis A. DeBaun IV', 'Curtis', 'DeBaun', NULL, 'IV', 'CA_0417 Indiana cities Wave A: https://www.terrehaute.in.gov/government/city_council/index.php, read 2026-11-24', '{}'),
  (-18417072, 'Rod Roberson', 'Rod', 'Roberson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/departments/mayors-office/about-mayor-roberson/, read 2026-11-24', '{}'),
  (-18417073, 'Debra D. Barrett', 'Debra', 'Barrett', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/city-clerk-city-council/office-of-the-city-clerk/, read 2026-11-24', '{}'),
  (-18417074, 'Chad Crabtree', 'Chad', 'Crabtree', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/city-council/, read 2026-11-24', '{}'),
  (-18417075, 'David Henke', 'David', 'Henke', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/city-council/, read 2026-11-24', '{}'),
  (-18417076, 'Dwight Fish', 'Dwight', 'Fish', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/city-council/, read 2026-11-24', '{}'),
  (-18417077, 'Brent Curry', 'Brent', 'Curry', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/city-council/, read 2026-11-24', '{}'),
  (-18417078, 'LaTonya King', 'LaTonya', 'King', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/city-council/, read 2026-11-24', '{}'),
  (-18417079, 'Arvis Dawson', 'Arvis', 'Dawson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/city-council/, read 2026-11-24', '{}'),
  (-18417080, 'Alex Holtz', 'Alex', 'Holtz', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/city-council/, read 2026-11-24', '{}'),
  (-18417081, 'Tonda Hines', 'Tonda', 'Hines', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://www.cityofelkhartin.gov/city-council/, read 2026-11-24', '{}'),
  (-18417082, 'Mike Moore', 'Mike', 'Moore', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-council/, read 2026-11-24', '{}'),
  (-18417083, 'Lisa Gill', 'Lisa', 'Gill', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-clerk/, read 2026-11-24', '{}'),
  (-18417084, 'Dustin White', 'Dustin', 'White', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-council/, read 2026-11-24', '{}'),
  (-18417085, 'Bill Burns', 'Bill', 'Burns', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-council/, read 2026-11-24', '{}'),
  (-18417086, 'Amy Semones', 'Amy', 'Semones', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-council/, read 2026-11-24', '{}'),
  (-18417087, 'Scott Anderson', 'Scott', 'Anderson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-council/, read 2026-11-24', '{}'),
  (-18417088, 'Donna Reed', 'Donna', 'Reed', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-council/, read 2026-11-24', '{}'),
  (-18417089, 'Steve Webb', 'Steve', 'Webb', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-council/, read 2026-11-24', '{}'),
  (-18417090, 'Jacky Snelling', 'Jacky', 'Snelling', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-council/, read 2026-11-24', '{}'),
  (-18417091, 'Evan Stoner', 'Evan', 'Stoner', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofjeff.net/city-council/, read 2026-11-24', '{}'),
  (-18417092, 'Dave Wood', 'Dave', 'Wood', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/elected-appointed-officials/mayor/, read 2026-11-24', '{}'),
  (-18417093, 'Deborah S. Block', 'Deborah', 'Block', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/elected-appointed-officials/office-of-the-city-clerk/, read 2026-11-24', '{"Deborah Ladyga"}'),
  (-18417094, 'Dale Emmons', 'Dale', 'Emmons', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/city-directory, read 2026-11-24', '{}'),
  (-18417095, 'Matt Carroll', 'Matt', 'Carroll', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/city-directory, read 2026-11-24', '{}'),
  (-18417096, 'Lou Ann Hazen', 'Lou', 'Hazen', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/city-directory, read 2026-11-24', '{}'),
  (-18417097, 'Kate Voelker', 'Kate', 'Voelker', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/city-directory, read 2026-11-24', '{}'),
  (-18417098, 'Anthony Violi', 'Anthony', 'Violi', 'Tony', NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/city-directory, read 2026-11-24', '{}'),
  (-18417099, 'Ron Banicki', 'Ron', 'Banicki', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/city-directory, read 2026-11-24', '{}'),
  (-18417100, 'Gregg Hixenbaugh', 'Gregg', 'Hixenbaugh', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/city-directory, read 2026-11-24', '{}'),
  (-18417101, 'Lacy Hahn', 'Lacy', 'Hahn', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/city-directory, read 2026-11-24', '{}'),
  (-18417102, 'Matt Mammolenti', 'Matt', 'Mammolenti', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://mishawaka.in.gov/government/city-directory, read 2026-11-24', '{}'),
  (-18417103, 'Deborah Whitfield', 'Deborah', 'Whitfield', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/mayor, read 2026-11-24', '{}'),
  (-18417104, 'Leatrice Adkisson', 'Leatrice', 'Adkisson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/clerk, read 2026-11-24', '{}'),
  (-18417105, 'Tyrrell Giles', 'Tyrrell', 'Giles', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/node/163?year=2023, read 2026-11-24', '{}'),
  (-18417106, 'Rick Wells', 'Rick', 'Wells', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/node/163?year=2023, read 2026-11-24', '{}'),
  (-18417107, 'Sherron Freeman', 'Sherron', 'Freeman', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/node/163?year=2023, read 2026-11-24', '{}'),
  (-18417108, 'Carlos Jennings', 'Carlos', 'Jennings', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/node/163?year=2023, read 2026-11-24', '{}'),
  (-18417109, 'Zach Cramer', 'Zach', 'Cramer', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/node/163?year=2023, read 2026-11-24', '{}'),
  (-18417110, 'Kristie Krone', 'Kristie', 'Krone', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/node/163?year=2023, read 2026-11-24', '{}'),
  (-18417111, 'Tracy Boyd', 'Tracy', 'Boyd', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/node/163?year=2023, read 2026-11-24', '{}'),
  (-18417112, 'David Roberts', 'David', 'Roberts', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/node/163?year=2023, read 2026-11-24', '{}'),
  (-18417113, 'Betty Robinson', 'Betty', 'Robinson', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityoflawrence.org/node/163?year=2023, read 2026-11-24', '{}'),
  (-18417114, 'Jeff Gahan', 'Jeff', 'Gahan', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/wp-content/uploads/2026/01/100625-ccmin.pdf, read 2026-11-24', '{}'),
  (-18417115, 'Vicki Glotzbach', 'Vicki', 'Glotzbach', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-clerk/, read 2026-11-24', '{}'),
  (-18417116, 'Elaine Murphy', 'Elaine', 'Murphy', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-council/, read 2026-11-24', '{}'),
  (-18417117, 'Don Unruh', 'Don', 'Unruh', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-council/, read 2026-11-24', '{}'),
  (-18417118, 'Stefanie Griffith', 'Stefanie', 'Griffith', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-council/, read 2026-11-24', '{}'),
  (-18417119, 'Jennie Collier', 'Jennie', 'Collier', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-council/, read 2026-11-24', '{}'),
  (-18417120, 'Adam Dickey', 'Adam', 'Dickey', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-council/, read 2026-11-24', '{}'),
  (-18417121, 'Greg Phipps', 'Greg', 'Phipps', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-council/, read 2026-11-24', '{}'),
  (-18417122, 'Chris FitzGerald', 'Chris', 'FitzGerald', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-council/, read 2026-11-24', '{}'),
  (-18417123, 'Louise Gohmann', 'Louise', 'Gohmann', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-council/, read 2026-11-24', '{}'),
  (-18417124, 'Scott Blair', 'Scott', 'Blair', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://cityofnewalbany.com/city-council/, read 2026-11-24', '{}'),
  (-18417125, 'Gina Leichty', 'Gina', 'Leichty', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://goshen.in.gov/?p=5557, read 2026-11-24', '{}'),
  (-18417126, 'Richard R. Aguirre', 'Richard', 'Aguirre', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://goshen.in.gov/?p=5557, read 2026-11-24', '{}'),
  (-18417127, 'Brett Weddell', 'Brett', 'Weddell', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://goshen.in.gov/?p=5557, read 2026-11-24', '{}'),
  (-18417128, 'Linda Gerber', 'Linda', 'Gerber', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://goshen.in.gov/?p=5557, read 2026-11-24', '{}'),
  (-18417129, 'Don Riegsecker', 'Don', 'Riegsecker', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://goshen.in.gov/?p=5557, read 2026-11-24', '{}'),
  (-18417130, 'Doug Nisley', 'Doug', 'Nisley', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://goshen.in.gov/?p=5557, read 2026-11-24', '{}'),
  (-18417131, 'Matt Schrock', 'Matt', 'Schrock', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://goshen.in.gov/?p=5557, read 2026-11-24', '{}'),
  (-18417132, 'Megan Peel', 'Megan', 'Peel', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://goshen.in.gov/?p=5557, read 2026-11-24', '{}'),
  (-18417133, 'Phil Lederach', 'Phil', 'Lederach', NULL, NULL, 'CA_0417 Indiana cities Wave A: https://goshen.in.gov/?p=5557, read 2026-11-24', '{}')
) AS n(external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, alternate_names)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Re-activate the reused discovery stubs ───────────────────────────────
UPDATE essentials.politicians SET is_active = true
 WHERE id IN ('97243dc4-1b2c-4e37-b480-264f47b3f1bd', '5c85d165-6c32-415b-a220-d51b42668cf6', '245d3807-f6ee-44be-a321-bd597d0aab7a', 'c2cfdf00-d537-4c57-92a8-27dadf7a0274', '856009a9-d2f9-4984-bbe9-76c261c72f94') AND is_active IS DISTINCT FROM true;

-- ─── 3. 138 terms ──────────────────────────────────────────────────────────
CREATE TEMP TABLE w_terms(ext bigint, pid uuid, gov text, geo_id text, title text, ordinal int, of_n int, src text) ON COMMIT DROP;
INSERT INTO w_terms VALUES
  (-18417001, NULL, 'City of Evansville, Indiana, US', '1822000', 'Mayor', NULL, NULL, 'https://www.evansvillegov.org/department/index.php?structureid=8'),
  (-18417002, NULL, 'City of Evansville, Indiana, US', '1822000', 'City Clerk', NULL, NULL, 'https://www.evansvillegov.org/department/index.php?structureid=15'),
  (-18417003, NULL, 'City of Evansville, Indiana, US', 'evansville-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16'),
  (-18417004, NULL, 'City of Evansville, Indiana, US', 'evansville-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16'),
  (-18417005, NULL, 'City of Evansville, Indiana, US', 'evansville-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16'),
  (-18417006, NULL, 'City of Evansville, Indiana, US', 'evansville-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16'),
  (-18417007, NULL, 'City of Evansville, Indiana, US', 'evansville-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16'),
  (-18417008, NULL, 'City of Evansville, Indiana, US', 'evansville-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16'),
  (NULL, '97243dc4-1b2c-4e37-b480-264f47b3f1bd', 'City of Evansville, Indiana, US', '1822000', 'Council Member, At Large', 1, 3, 'https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16'),
  (-18417009, NULL, 'City of Evansville, Indiana, US', '1822000', 'Council Member, At Large', 2, 3, 'https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16'),
  (-18417010, NULL, 'City of Evansville, Indiana, US', '1822000', 'Council Member, At Large', 3, 3, 'https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16'),
  (-18417011, NULL, 'City of South Bend, Indiana, US', '1871000', 'Mayor', NULL, NULL, 'https://southbendin.gov/official/'),
  (-18417012, NULL, 'City of South Bend, Indiana, US', '1871000', 'City Clerk', NULL, NULL, 'https://southbendin.gov/official/'),
  (-18417013, NULL, 'City of South Bend, Indiana, US', 'south-bend-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://southbendin.gov/official/'),
  (-18417014, NULL, 'City of South Bend, Indiana, US', 'south-bend-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://southbendin.gov/official/'),
  (-18417015, NULL, 'City of South Bend, Indiana, US', 'south-bend-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://southbendin.gov/official/'),
  (NULL, '5c85d165-6c32-415b-a220-d51b42668cf6', 'City of South Bend, Indiana, US', 'south-bend-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://southbendin.gov/official/'),
  (-18417016, NULL, 'City of South Bend, Indiana, US', 'south-bend-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://southbendin.gov/official/'),
  (-18417017, NULL, 'City of South Bend, Indiana, US', 'south-bend-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://southbendin.gov/official/'),
  (-18417018, NULL, 'City of South Bend, Indiana, US', '1871000', 'Council Member, At Large', 1, 3, 'https://southbendin.gov/official/'),
  (-18417019, NULL, 'City of South Bend, Indiana, US', '1871000', 'Council Member, At Large', 2, 3, 'https://southbendin.gov/official/'),
  (-18417020, NULL, 'City of South Bend, Indiana, US', '1871000', 'Council Member, At Large', 3, 3, 'https://southbendin.gov/official/'),
  (-18417021, NULL, 'City of Carmel, Indiana, US', '1810342', 'Mayor', NULL, NULL, 'https://web.archive.org/web/20260129213512/https://www.carmel.in.gov/government/mayor'),
  (-18417022, NULL, 'City of Carmel, Indiana, US', '1810342', 'City Clerk', NULL, NULL, 'https://web.archive.org/web/20251220010312/https://www.carmel.in.gov/government/clerk-of-the-city/staff-directory'),
  (-18417023, NULL, 'City of Carmel, Indiana, US', 'carmel-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council'),
  (-18417024, NULL, 'City of Carmel, Indiana, US', 'carmel-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council'),
  (-18417025, NULL, 'City of Carmel, Indiana, US', 'carmel-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council'),
  (-18417026, NULL, 'City of Carmel, Indiana, US', 'carmel-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council'),
  (-18417027, NULL, 'City of Carmel, Indiana, US', 'carmel-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council'),
  (-18417028, NULL, 'City of Carmel, Indiana, US', 'carmel-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council'),
  (-18417029, NULL, 'City of Carmel, Indiana, US', '1810342', 'Council Member, At Large', 1, 3, 'https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council'),
  (-18417030, NULL, 'City of Carmel, Indiana, US', '1810342', 'Council Member, At Large', 2, 3, 'https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council'),
  (-18417031, NULL, 'City of Carmel, Indiana, US', '1810342', 'Council Member, At Large', 3, 3, 'https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council'),
  (-18417032, NULL, 'City of Lafayette, Indiana, US', '1840788', 'Mayor', NULL, NULL, 'https://web.archive.org/web/20260822112159/https://www.lafayette.in.gov/657/Mayors-Office'),
  (-18417033, NULL, 'City of Lafayette, Indiana, US', '1840788', 'City Clerk', NULL, NULL, 'https://web.archive.org/web/20260105172504/http://lafayette.in.gov/153/City-Clerk'),
  (-18417034, NULL, 'City of Lafayette, Indiana, US', 'lafayette-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council'),
  (-18417035, NULL, 'City of Lafayette, Indiana, US', 'lafayette-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council'),
  (-18417036, NULL, 'City of Lafayette, Indiana, US', 'lafayette-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council'),
  (-18417037, NULL, 'City of Lafayette, Indiana, US', 'lafayette-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council'),
  (-18417038, NULL, 'City of Lafayette, Indiana, US', 'lafayette-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council'),
  (-18417039, NULL, 'City of Lafayette, Indiana, US', 'lafayette-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council'),
  (-18417040, NULL, 'City of Lafayette, Indiana, US', '1840788', 'Council Member, At Large', 1, 3, 'https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council'),
  (-18417041, NULL, 'City of Lafayette, Indiana, US', '1840788', 'Council Member, At Large', 2, 3, 'https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council'),
  (-18417042, NULL, 'City of Lafayette, Indiana, US', '1840788', 'Council Member, At Large', 3, 3, 'https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council'),
  (-18417043, NULL, 'City of Muncie, Indiana, US', '1851876', 'Mayor', NULL, NULL, 'https://www.muncie.in.gov/department/index.php?structureid=14'),
  (-18417044, NULL, 'City of Muncie, Indiana, US', '1851876', 'City Clerk', NULL, NULL, 'https://www.muncie.in.gov/department/index.php?structureid=17'),
  (-18417045, NULL, 'City of Muncie, Indiana, US', 'muncie-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.muncie.in.gov/council'),
  (-18417046, NULL, 'City of Muncie, Indiana, US', 'muncie-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.muncie.in.gov/council'),
  (-18417047, NULL, 'City of Muncie, Indiana, US', 'muncie-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.muncie.in.gov/council'),
  (-18417048, NULL, 'City of Muncie, Indiana, US', 'muncie-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.muncie.in.gov/council'),
  (-18417049, NULL, 'City of Muncie, Indiana, US', 'muncie-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://www.muncie.in.gov/council'),
  (NULL, '245d3807-f6ee-44be-a321-bd597d0aab7a', 'City of Muncie, Indiana, US', '1851876', 'Council Member, At Large', 1, 3, 'https://www.muncie.in.gov/council'),
  (-18417050, NULL, 'City of Muncie, Indiana, US', '1851876', 'Council Member, At Large', 2, 3, 'https://www.muncie.in.gov/council'),
  (-18417051, NULL, 'City of Muncie, Indiana, US', '1851876', 'Council Member, At Large', 3, 3, 'https://www.muncie.in.gov/council'),
  (-18417052, NULL, 'City of Westfield, Indiana, US', '1882700', 'Mayor', NULL, NULL, 'https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0'),
  (-18417053, NULL, 'City of Westfield, Indiana, US', '1882700', 'Clerk-Treasurer', NULL, NULL, 'https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0'),
  (-18417054, NULL, 'City of Westfield, Indiana, US', 'westfield-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0'),
  (-18417055, NULL, 'City of Westfield, Indiana, US', 'westfield-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0'),
  (-18417056, NULL, 'City of Westfield, Indiana, US', 'westfield-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0'),
  (-18417057, NULL, 'City of Westfield, Indiana, US', 'westfield-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0'),
  (-18417058, NULL, 'City of Westfield, Indiana, US', 'westfield-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0'),
  (-18417059, NULL, 'City of Westfield, Indiana, US', '1882700', 'Council Member, At Large', 1, 2, 'https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0'),
  (-18417060, NULL, 'City of Westfield, Indiana, US', '1882700', 'Council Member, At Large', 2, 2, 'https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0'),
  (-18417061, NULL, 'City of Terre Haute, Indiana, US', '1875428', 'Mayor', NULL, NULL, 'https://www.terrehaute.in.gov/government/city_council/index.php'),
  (-18417062, NULL, 'City of Terre Haute, Indiana, US', '1875428', 'City Clerk', NULL, NULL, 'https://www.terrehaute.in.gov/departments/staff_directory/index.php'),
  (-18417063, NULL, 'City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://terrehaute.in.gov/government/city_council/city_council_district_maps.php'),
  (-18417064, NULL, 'City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://terrehaute.in.gov/government/city_council/city_council_district_maps.php'),
  (-18417065, NULL, 'City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://terrehaute.in.gov/government/city_council/city_council_district_maps.php'),
  (-18417066, NULL, 'City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://terrehaute.in.gov/government/city_council/city_council_district_maps.php'),
  (-18417067, NULL, 'City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://terrehaute.in.gov/government/city_council/city_council_district_maps.php'),
  (-18417068, NULL, 'City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://terrehaute.in.gov/government/city_council/city_council_district_maps.php'),
  (-18417069, NULL, 'City of Terre Haute, Indiana, US', '1875428', 'Council Member, At Large', 1, 3, 'https://www.terrehaute.in.gov/government/city_council/index.php'),
  (-18417070, NULL, 'City of Terre Haute, Indiana, US', '1875428', 'Council Member, At Large', 2, 3, 'https://www.terrehaute.in.gov/government/city_council/index.php'),
  (-18417071, NULL, 'City of Terre Haute, Indiana, US', '1875428', 'Council Member, At Large', 3, 3, 'https://www.terrehaute.in.gov/government/city_council/index.php'),
  (-18417072, NULL, 'City of Elkhart, Indiana, US', '1820728', 'Mayor', NULL, NULL, 'https://www.cityofelkhartin.gov/departments/mayors-office/about-mayor-roberson/'),
  (-18417073, NULL, 'City of Elkhart, Indiana, US', '1820728', 'City Clerk', NULL, NULL, 'https://www.cityofelkhartin.gov/city-clerk-city-council/office-of-the-city-clerk/'),
  (NULL, 'c2cfdf00-d537-4c57-92a8-27dadf7a0274', 'City of Elkhart, Indiana, US', 'elkhart-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.cityofelkhartin.gov/city-council/'),
  (-18417074, NULL, 'City of Elkhart, Indiana, US', 'elkhart-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.cityofelkhartin.gov/city-council/'),
  (-18417075, NULL, 'City of Elkhart, Indiana, US', 'elkhart-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.cityofelkhartin.gov/city-council/'),
  (-18417076, NULL, 'City of Elkhart, Indiana, US', 'elkhart-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.cityofelkhartin.gov/city-council/'),
  (-18417077, NULL, 'City of Elkhart, Indiana, US', 'elkhart-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.cityofelkhartin.gov/city-council/'),
  (-18417078, NULL, 'City of Elkhart, Indiana, US', 'elkhart-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://www.cityofelkhartin.gov/city-council/'),
  (-18417079, NULL, 'City of Elkhart, Indiana, US', '1820728', 'Council Member, At Large', 1, 3, 'https://www.cityofelkhartin.gov/city-council/'),
  (-18417080, NULL, 'City of Elkhart, Indiana, US', '1820728', 'Council Member, At Large', 2, 3, 'https://www.cityofelkhartin.gov/city-council/'),
  (-18417081, NULL, 'City of Elkhart, Indiana, US', '1820728', 'Council Member, At Large', 3, 3, 'https://www.cityofelkhartin.gov/city-council/'),
  (-18417082, NULL, 'City of Jeffersonville, Indiana, US', '1838358', 'Mayor', NULL, NULL, 'https://cityofjeff.net/city-council/'),
  (-18417083, NULL, 'City of Jeffersonville, Indiana, US', '1838358', 'City Clerk', NULL, NULL, 'https://cityofjeff.net/city-clerk/'),
  (-18417084, NULL, 'City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://cityofjeff.net/city-council/'),
  (-18417085, NULL, 'City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://cityofjeff.net/city-council/'),
  (-18417086, NULL, 'City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://cityofjeff.net/city-council/'),
  (-18417087, NULL, 'City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://cityofjeff.net/city-council/'),
  (-18417088, NULL, 'City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://cityofjeff.net/city-council/'),
  (-18417089, NULL, 'City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://cityofjeff.net/city-council/'),
  (NULL, '856009a9-d2f9-4984-bbe9-76c261c72f94', 'City of Jeffersonville, Indiana, US', '1838358', 'Council Member, At Large', 1, 3, 'https://cityofjeff.net/city-council/'),
  (-18417090, NULL, 'City of Jeffersonville, Indiana, US', '1838358', 'Council Member, At Large', 2, 3, 'https://cityofjeff.net/city-council/'),
  (-18417091, NULL, 'City of Jeffersonville, Indiana, US', '1838358', 'Council Member, At Large', 3, 3, 'https://cityofjeff.net/city-council/'),
  (-18417092, NULL, 'City of Mishawaka, Indiana, US', '1849932', 'Mayor', NULL, NULL, 'https://mishawaka.in.gov/government/elected-appointed-officials/mayor/'),
  (-18417093, NULL, 'City of Mishawaka, Indiana, US', '1849932', 'City Clerk', NULL, NULL, 'https://mishawaka.in.gov/government/elected-appointed-officials/office-of-the-city-clerk/'),
  (-18417094, NULL, 'City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://mishawaka.in.gov/government/city-directory'),
  (-18417095, NULL, 'City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://mishawaka.in.gov/government/city-directory'),
  (-18417096, NULL, 'City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://mishawaka.in.gov/government/city-directory'),
  (-18417097, NULL, 'City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://mishawaka.in.gov/government/city-directory'),
  (-18417098, NULL, 'City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://mishawaka.in.gov/government/city-directory'),
  (-18417099, NULL, 'City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://mishawaka.in.gov/government/city-directory'),
  (-18417100, NULL, 'City of Mishawaka, Indiana, US', '1849932', 'Council Member, At Large', 1, 3, 'https://mishawaka.in.gov/government/city-directory'),
  (-18417101, NULL, 'City of Mishawaka, Indiana, US', '1849932', 'Council Member, At Large', 2, 3, 'https://mishawaka.in.gov/government/city-directory'),
  (-18417102, NULL, 'City of Mishawaka, Indiana, US', '1849932', 'Council Member, At Large', 3, 3, 'https://mishawaka.in.gov/government/city-directory'),
  (-18417103, NULL, 'City of Lawrence, Indiana, US', '1842426', 'Mayor', NULL, NULL, 'https://cityoflawrence.org/mayor'),
  (-18417104, NULL, 'City of Lawrence, Indiana, US', '1842426', 'City Clerk', NULL, NULL, 'https://cityoflawrence.org/clerk'),
  (-18417105, NULL, 'City of Lawrence, Indiana, US', 'lawrence-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://cityoflawrence.org/node/163?year=2023'),
  (-18417106, NULL, 'City of Lawrence, Indiana, US', 'lawrence-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://cityoflawrence.org/node/163?year=2023'),
  (-18417107, NULL, 'City of Lawrence, Indiana, US', 'lawrence-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://cityoflawrence.org/node/163?year=2023'),
  (-18417108, NULL, 'City of Lawrence, Indiana, US', 'lawrence-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://cityoflawrence.org/node/163?year=2023'),
  (-18417109, NULL, 'City of Lawrence, Indiana, US', 'lawrence-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://cityoflawrence.org/node/163?year=2023'),
  (-18417110, NULL, 'City of Lawrence, Indiana, US', 'lawrence-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://cityoflawrence.org/node/163?year=2023'),
  (-18417111, NULL, 'City of Lawrence, Indiana, US', '1842426', 'Council Member, At Large', 1, 3, 'https://cityoflawrence.org/node/163?year=2023'),
  (-18417112, NULL, 'City of Lawrence, Indiana, US', '1842426', 'Council Member, At Large', 2, 3, 'https://cityoflawrence.org/node/163?year=2023'),
  (-18417113, NULL, 'City of Lawrence, Indiana, US', '1842426', 'Council Member, At Large', 3, 3, 'https://cityoflawrence.org/node/163?year=2023'),
  (-18417114, NULL, 'City of New Albany, Indiana, US', '1852326', 'Mayor', NULL, NULL, 'https://cityofnewalbany.com/wp-content/uploads/2026/01/100625-ccmin.pdf'),
  (-18417115, NULL, 'City of New Albany, Indiana, US', '1852326', 'City Clerk', NULL, NULL, 'https://cityofnewalbany.com/city-clerk/'),
  (-18417116, NULL, 'City of New Albany, Indiana, US', '1852326', 'Council Member, At Large', 1, 3, 'https://cityofnewalbany.com/city-council/'),
  (-18417117, NULL, 'City of New Albany, Indiana, US', '1852326', 'Council Member, At Large', 2, 3, 'https://cityofnewalbany.com/city-council/'),
  (-18417118, NULL, 'City of New Albany, Indiana, US', '1852326', 'Council Member, At Large', 3, 3, 'https://cityofnewalbany.com/city-council/'),
  (-18417119, NULL, 'City of New Albany, Indiana, US', 'new-albany-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://cityofnewalbany.com/city-council/'),
  (-18417120, NULL, 'City of New Albany, Indiana, US', 'new-albany-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://cityofnewalbany.com/city-council/'),
  (-18417121, NULL, 'City of New Albany, Indiana, US', 'new-albany-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://cityofnewalbany.com/city-council/'),
  (-18417122, NULL, 'City of New Albany, Indiana, US', 'new-albany-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://cityofnewalbany.com/city-council/'),
  (-18417123, NULL, 'City of New Albany, Indiana, US', 'new-albany-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://cityofnewalbany.com/city-council/'),
  (-18417124, NULL, 'City of New Albany, Indiana, US', 'new-albany-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://cityofnewalbany.com/city-council/'),
  (-18417125, NULL, 'City of Goshen, Indiana, US', '1828386', 'Mayor', NULL, NULL, 'https://goshen.in.gov/?p=5557'),
  (-18417126, NULL, 'City of Goshen, Indiana, US', '1828386', 'Clerk-Treasurer', NULL, NULL, 'https://goshen.in.gov/?p=5557'),
  (-18417127, NULL, 'City of Goshen, Indiana, US', '1828386', 'Council Member, At Large', 1, 2, 'https://goshen.in.gov/?p=5557'),
  (-18417128, NULL, 'City of Goshen, Indiana, US', '1828386', 'Council Member, At Large', 2, 2, 'https://goshen.in.gov/?p=5557'),
  (-18417129, NULL, 'City of Goshen, Indiana, US', 'goshen-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://goshen.in.gov/?p=5557'),
  (-18417130, NULL, 'City of Goshen, Indiana, US', 'goshen-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://goshen.in.gov/?p=5557'),
  (-18417131, NULL, 'City of Goshen, Indiana, US', 'goshen-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://goshen.in.gov/?p=5557'),
  (-18417132, NULL, 'City of Goshen, Indiana, US', 'goshen-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://goshen.in.gov/?p=5557'),
  (-18417133, NULL, 'City of Goshen, Indiana, US', 'goshen-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://goshen.in.gov/?p=5557');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',
       'CA_0417 Indiana cities Wave A: holder named on ' || t.src || ', read 2026-11-24; start date not published'
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
   AND g.name = 'City of Muncie, Indiana, US' AND o.title = 'Council Member, District 4' AND d.geo_id = 'muncie-in-council-district-4';

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
  WHERE g.name IN ('City of Evansville, Indiana, US', 'City of South Bend, Indiana, US', 'City of Carmel, Indiana, US', 'City of Lafayette, Indiana, US', 'City of Muncie, Indiana, US', 'City of Westfield, Indiana, US', 'City of Terre Haute, Indiana, US', 'City of Elkhart, Indiana, US', 'City of Jeffersonville, Indiana, US', 'City of Mishawaka, Indiana, US', 'City of Lawrence, Indiana, US', 'City of New Albany, Indiana, US', 'City of Goshen, Indiana, US');
  IF v_off <> 139 OR v_seat <> 138 OR v_vac <> 1 OR v_dead <> 0 OR v_held_vac <> 0 THEN
    RAISE EXCEPTION 'CA_0417: offices %/139, seated %/138, vacant %/1, unseated-unflagged % (want 0), seated-and-flagged % (want 0)',
      v_off, v_seat, v_vac, v_dead, v_held_vac;
  END IF;

  -- No person holds two seats in these cities (a loose at-large match would seat one person three times).
  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE g.name IN ('City of Evansville, Indiana, US', 'City of South Bend, Indiana, US', 'City of Carmel, Indiana, US', 'City of Lafayette, Indiana, US', 'City of Muncie, Indiana, US', 'City of Westfield, Indiana, US', 'City of Terre Haute, Indiana, US', 'City of Elkhart, Indiana, US', 'City of Jeffersonville, Indiana, US', 'City of Mishawaka, Indiana, US', 'City of Lawrence, Indiana, US', 'City of New Albany, Indiana, US', 'City of Goshen, Indiana, US') GROUP BY och.politician_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'CA_0417: % people hold more than one seat in these cities', v_dupe; END IF;

  SELECT count(*) FILTER (WHERE NOT p.is_active), count(*) FILTER (WHERE ot.term_end IS NOT NULL), count(*)
    INTO v_inact, v_ended, v_terms
  FROM essentials.office_terms ot
  JOIN essentials.politicians p ON p.id = ot.politician_id
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name IN ('City of Evansville, Indiana, US', 'City of South Bend, Indiana, US', 'City of Carmel, Indiana, US', 'City of Lafayette, Indiana, US', 'City of Muncie, Indiana, US', 'City of Westfield, Indiana, US', 'City of Terre Haute, Indiana, US', 'City of Elkhart, Indiana, US', 'City of Jeffersonville, Indiana, US', 'City of Mishawaka, Indiana, US', 'City of Lawrence, Indiana, US', 'City of New Albany, Indiana, US', 'City of Goshen, Indiana, US');
  IF v_inact <> 0 OR v_ended <> 0 OR v_terms <> 138 THEN
    RAISE EXCEPTION 'CA_0417: % inactive holders, % ended terms, % terms (want 0, 0, 138)', v_inact, v_ended, v_terms;
  END IF;

  RAISE NOTICE 'CA_0417 OK: 139 offices, 138 seated (133 new + 5 reused), 1 vacant, 0 dead, 0 doubled';
END $$;

COMMIT;
