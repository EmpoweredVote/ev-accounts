-- CA_0419_indiana_cities_wave_a_people.sql
-- Indiana cities Wave A, occupancy half, for Hammond, Kokomo, Greenwood. Slot RESERVED from the
-- allocator. Follows the structure migration that created these 3 governments and 33 offices.
--
-- 🔴 APPLY IT THE SAME DAY AS THE STRUCTURE MIGRATION: an office with a polygon and no holder that is not
-- flagged vacant is DEAD_GEOGRAPHY to check:reachability. The post-verify below gates that at zero.
--
-- Seats 33 of 33 offices: 32 new people (external_id -18419001 .. -18419032,
-- asserted empty below) and 1 existing rows reused. 0 office(s) flagged vacant.
--
-- 🟢 EVERY NAME WAS CHECKED AGAINST A SAVED COPY OF ITS SOURCE PAGE (verify-collect.mjs in
-- backend/data/seed-in-cities-wave-a/, which runs an absent-name and a planted-name control first).
--
-- 🔴 TERM START IS 'unknown', NOT GUESSED. Most holders began on 2024-01-01 after the 2023 election, but
-- re-elected incumbents began earlier (re-election does not end an occupancy) and caucus appointees began
-- mid-term on dates the pages do not give. term_start is NULL with start_precision 'unknown' -- the
-- shape migration 1459's backfill used -- rather than a sourced-looking date that is false for some.
--
-- 🔴 NO term_end IS WRITTEN. These terms run to 2027-12-31; a future term_end would vacate every seat on
-- that date with no successor.
--
-- GREENWOOD ROSTER, TWO CONFLICTS RESOLVED FROM THE CITY'S OWN PAGE (raw/greenwood-in/officials.html,
-- read 2026-11-24) AGAINST THE CITY'S GIS LAYER (Greenwood_Common_Council, last edited 2026-10-06):
--   District 3  the layer says "(Vacant)" (photo file still Michael Williams, elected 2023); the city
--               page names Darin Hoggatt with his own hoggattd@ address, so he was seated after
--               2026-10-06. The page gives no date, so his term start is 'unknown' like every other.
--   At-large    the layer says Erin Betron; the city page says Erin Kasch with the address
--               betrone@greenwood.in.gov. One person under a new surname; Betron is kept in
--               alternate_names.
--
-- REUSED PEOPLE (matched by surname + first name in match-people.mjs, whose positive control is
-- Sharon Tucker, then checked by hand):
--   Ray Collins      f0e871d5-01a2-4fa3-81f7-479855896f16  inactive indiana_discovery stub, deactivated by CC_0101; no other row, no race
--   Each is set is_active = true: an inactive person in a seat is hidden by the reps feed, which
--   check:reachability counts as REPS_FILTER_HIDDEN.
-- FORMER NAMES kept in alternate_names:
--   Erin Kasch (Erin Betron): Greenwood's officials page lists 'Erin Kasch, At-Large' with the email betrone@greenwood.in.gov; she was caucused in and elected as Erin Betron
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
  SELECT count(*) INTO v FROM essentials.politicians WHERE external_id BETWEEN -18419032 AND -18419001;
  IF v NOT IN (0, 32) THEN RAISE EXCEPTION 'CA_0419 pre-flight: external_id band holds % rows, expected 0 (or 32 on a re-run)', v; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = 'f0e871d5-01a2-4fa3-81f7-479855896f16' AND full_name = 'Ray Collins') THEN
    RAISE EXCEPTION 'CA_0419 pre-flight: reused row f0e871d5-01a2-4fa3-81f7-479855896f16 is missing or no longer named Ray Collins'; END IF;
  SELECT count(*) INTO v FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Hammond, Indiana, US', 'City of Kokomo, Indiana, US', 'City of Greenwood, Indiana, US');
  IF v <> 33 THEN RAISE EXCEPTION 'CA_0419 pre-flight: % offices in these cities, expected 33 (is the structure migration applied?)', v; END IF;
END $$;

-- ─── 1. 32 new people ─────────────────────────────────────────────────────
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, alternate_names, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.name_suffix, n.source, n.alternate_names::text[], true
FROM (VALUES
  (-18419001, 'Thomas M. McDermott Jr.', 'Thomas', 'McDermott', NULL, 'Jr.', 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/mayor/, read 2026-11-24', '{}'),
  (-18419002, 'Robert J. Golec', 'Robert', 'Golec', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/?p=319, read 2026-11-24', '{}'),
  (-18419003, 'Katrina Alexander', 'Katrina', 'Alexander', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/city-council/, read 2026-11-24', '{}'),
  (-18419004, 'Dan Spitale', 'Dan', 'Spitale', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/city-council/, read 2026-11-24', '{}'),
  (-18419005, 'Janet Venecz', 'Janet', 'Venecz', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/city-council/, read 2026-11-24', '{}'),
  (-18419006, 'Mark Kalwinski', 'Mark', 'Kalwinski', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/city-council/, read 2026-11-24', '{}'),
  (-18419007, 'Alfonso Salinas III', 'Alfonso', 'Salinas', NULL, 'III', 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/city-council/, read 2026-11-24', '{}'),
  (-18419008, 'Barry Tyler, Jr.', 'Barry', 'Tyler', NULL, 'Jr.', 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/city-council/, read 2026-11-24', '{}'),
  (-18419009, 'William Emerson', 'William', 'Emerson', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/city-council/, read 2026-11-24', '{}'),
  (-18419010, 'Dave Woerpel', 'Dave', 'Woerpel', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/city-council/, read 2026-11-24', '{}'),
  (-18419011, 'Scott Rakos', 'Scott', 'Rakos', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.gohammond.com/city-council/, read 2026-11-24', '{}'),
  (-18419012, 'Tyler O. Moore', 'Tyler', 'Moore', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/mayor_s_office/index.php, read 2026-11-24', '{}'),
  (-18419013, 'Diane Howard', 'Diane', 'Howard', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/city_clerk/index.php, read 2026-11-24', '{}'),
  (-18419014, 'Dave Capshaw', 'Dave', 'Capshaw', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/common_council/index.php, read 2026-11-24', '{}'),
  (-18419015, 'Bob Stephenson', 'Bob', 'Stephenson', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/common_council/index.php, read 2026-11-24', '{}'),
  (-18419016, 'Jeff Plough', 'Jeff', 'Plough', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/common_council/index.php, read 2026-11-24', '{}'),
  (-18419017, 'Greg Davis', 'Greg', 'Davis', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/common_council/index.php, read 2026-11-24', '{}'),
  (-18419018, 'Crystal Sanburn', 'Crystal', 'Sanburn', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/common_council/index.php, read 2026-11-24', '{}'),
  (-18419019, 'Tony Stewart', 'Tony', 'Stewart', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/common_council/index.php, read 2026-11-24', '{}'),
  (-18419020, 'Matt Grecu', 'Matt', 'Grecu', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/common_council/index.php, read 2026-11-24', '{}'),
  (-18419021, 'Tom Miklik', 'Tom', 'Miklik', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://cityofkokomo.org/departments/common_council/index.php, read 2026-11-24', '{}'),
  (-18419022, 'Mark W. Myers', 'Mark', 'Myers', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/department/index.php?structureid=30, read 2026-11-24', '{}'),
  (-18419023, 'Jeannine Myers', 'Jeannine', 'Myers', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/clerk, read 2026-11-24', '{}'),
  (-18419024, 'Mike Campbell', 'Mike', 'Campbell', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/officials, read 2026-11-24', '{}'),
  (-18419025, 'Erin Kasch', 'Erin', 'Kasch', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/officials, read 2026-11-24', '{"Erin Betron"}'),
  (-18419026, 'Steven Moan', 'Steven', 'Moan', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/officials, read 2026-11-24', '{}'),
  (-18419027, 'Linda Gibson', 'Linda', 'Gibson', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/officials, read 2026-11-24', '{}'),
  (-18419028, 'Ezra Hill', 'Ezra', 'Hill', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/officials, read 2026-11-24', '{}'),
  (-18419029, 'Darin Hoggatt', 'Darin', 'Hoggatt', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/officials, read 2026-11-24', '{}'),
  (-18419030, 'Teri Manship', 'Teri', 'Manship', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/officials, read 2026-11-24', '{}'),
  (-18419031, 'J. David Hopper', 'J.', 'Hopper', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/officials, read 2026-11-24', '{}'),
  (-18419032, 'Dave Lekse', 'Dave', 'Lekse', NULL, NULL, 'CA_0419 Indiana cities Wave A: https://www.greenwood.in.gov/officials, read 2026-11-24', '{}')
) AS n(external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, alternate_names)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Re-activate reused people ────────────────────────────────────────────
UPDATE essentials.politicians SET is_active = true
 WHERE id IN ('f0e871d5-01a2-4fa3-81f7-479855896f16') AND is_active IS DISTINCT FROM true;

-- ─── 3. 33 terms ──────────────────────────────────────────────────────────
CREATE TEMP TABLE w_terms(ext bigint, pid uuid, gov text, geo_id text, title text, ordinal int, of_n int, src text) ON COMMIT DROP;
INSERT INTO w_terms VALUES
  (-18419001, NULL, 'City of Hammond, Indiana, US', '1831000', 'Mayor', NULL, NULL, 'https://www.gohammond.com/mayor/'),
  (-18419002, NULL, 'City of Hammond, Indiana, US', '1831000', 'City Clerk', NULL, NULL, 'https://www.gohammond.com/?p=319'),
  (-18419003, NULL, 'City of Hammond, Indiana, US', '1831000', 'Council Member, At Large', 1, 3, 'https://www.gohammond.com/city-council/'),
  (-18419004, NULL, 'City of Hammond, Indiana, US', '1831000', 'Council Member, At Large', 2, 3, 'https://www.gohammond.com/city-council/'),
  (-18419005, NULL, 'City of Hammond, Indiana, US', '1831000', 'Council Member, At Large', 3, 3, 'https://www.gohammond.com/city-council/'),
  (-18419006, NULL, 'City of Hammond, Indiana, US', 'hammond-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.gohammond.com/city-council/'),
  (-18419007, NULL, 'City of Hammond, Indiana, US', 'hammond-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.gohammond.com/city-council/'),
  (-18419008, NULL, 'City of Hammond, Indiana, US', 'hammond-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.gohammond.com/city-council/'),
  (-18419009, NULL, 'City of Hammond, Indiana, US', 'hammond-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.gohammond.com/city-council/'),
  (-18419010, NULL, 'City of Hammond, Indiana, US', 'hammond-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.gohammond.com/city-council/'),
  (-18419011, NULL, 'City of Hammond, Indiana, US', 'hammond-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://www.gohammond.com/city-council/'),
  (-18419012, NULL, 'City of Kokomo, Indiana, US', '1840392', 'Mayor', NULL, NULL, 'https://cityofkokomo.org/departments/mayor_s_office/index.php'),
  (-18419013, NULL, 'City of Kokomo, Indiana, US', '1840392', 'City Clerk', NULL, NULL, 'https://cityofkokomo.org/departments/city_clerk/index.php'),
  (-18419014, NULL, 'City of Kokomo, Indiana, US', 'kokomo-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://cityofkokomo.org/departments/common_council/index.php'),
  (-18419015, NULL, 'City of Kokomo, Indiana, US', 'kokomo-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://cityofkokomo.org/departments/common_council/index.php'),
  (NULL, 'f0e871d5-01a2-4fa3-81f7-479855896f16', 'City of Kokomo, Indiana, US', 'kokomo-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://cityofkokomo.org/departments/common_council/index.php'),
  (-18419016, NULL, 'City of Kokomo, Indiana, US', 'kokomo-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://cityofkokomo.org/departments/common_council/index.php'),
  (-18419017, NULL, 'City of Kokomo, Indiana, US', 'kokomo-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://cityofkokomo.org/departments/common_council/index.php'),
  (-18419018, NULL, 'City of Kokomo, Indiana, US', 'kokomo-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://cityofkokomo.org/departments/common_council/index.php'),
  (-18419019, NULL, 'City of Kokomo, Indiana, US', '1840392', 'Council Member, At Large', 1, 3, 'https://cityofkokomo.org/departments/common_council/index.php'),
  (-18419020, NULL, 'City of Kokomo, Indiana, US', '1840392', 'Council Member, At Large', 2, 3, 'https://cityofkokomo.org/departments/common_council/index.php'),
  (-18419021, NULL, 'City of Kokomo, Indiana, US', '1840392', 'Council Member, At Large', 3, 3, 'https://cityofkokomo.org/departments/common_council/index.php'),
  (-18419022, NULL, 'City of Greenwood, Indiana, US', '1829898', 'Mayor', NULL, NULL, 'https://www.greenwood.in.gov/department/index.php?structureid=30'),
  (-18419023, NULL, 'City of Greenwood, Indiana, US', '1829898', 'City Clerk', NULL, NULL, 'https://www.greenwood.in.gov/clerk'),
  (-18419024, NULL, 'City of Greenwood, Indiana, US', '1829898', 'Council Member, At Large', 1, 3, 'https://www.greenwood.in.gov/officials'),
  (-18419025, NULL, 'City of Greenwood, Indiana, US', '1829898', 'Council Member, At Large', 2, 3, 'https://www.greenwood.in.gov/officials'),
  (-18419026, NULL, 'City of Greenwood, Indiana, US', '1829898', 'Council Member, At Large', 3, 3, 'https://www.greenwood.in.gov/officials'),
  (-18419027, NULL, 'City of Greenwood, Indiana, US', 'greenwood-in-council-district-1', 'Council Member, District 1', NULL, NULL, 'https://www.greenwood.in.gov/officials'),
  (-18419028, NULL, 'City of Greenwood, Indiana, US', 'greenwood-in-council-district-2', 'Council Member, District 2', NULL, NULL, 'https://www.greenwood.in.gov/officials'),
  (-18419029, NULL, 'City of Greenwood, Indiana, US', 'greenwood-in-council-district-3', 'Council Member, District 3', NULL, NULL, 'https://www.greenwood.in.gov/officials'),
  (-18419030, NULL, 'City of Greenwood, Indiana, US', 'greenwood-in-council-district-4', 'Council Member, District 4', NULL, NULL, 'https://www.greenwood.in.gov/officials'),
  (-18419031, NULL, 'City of Greenwood, Indiana, US', 'greenwood-in-council-district-5', 'Council Member, District 5', NULL, NULL, 'https://www.greenwood.in.gov/officials'),
  (-18419032, NULL, 'City of Greenwood, Indiana, US', 'greenwood-in-council-district-6', 'Council Member, District 6', NULL, NULL, 'https://www.greenwood.in.gov/officials');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',
       'CA_0419 Indiana cities Wave A: holder named on ' || t.src || ', read 2026-11-24; start date not published'
FROM w_terms t
JOIN essentials.governments g ON g.name = t.gov
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = t.title
 AND (t.ordinal IS NULL OR o.description LIKE 'Internal ordinal ' || t.ordinal || ' of ' || t.of_n || '.%')
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = t.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.politicians p ON (t.pid IS NOT NULL AND p.id = t.pid) OR (t.ext IS NOT NULL AND p.external_id = t.ext)
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── 4. Vacancy ──────────────────────────────────────────────────────────────


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
  WHERE g.name IN ('City of Hammond, Indiana, US', 'City of Kokomo, Indiana, US', 'City of Greenwood, Indiana, US');
  IF v_off <> 33 OR v_seat <> 33 OR v_vac <> 0 OR v_dead <> 0 OR v_held_vac <> 0 THEN
    RAISE EXCEPTION 'CA_0419: offices %/33, seated %/33, vacant %/0, unseated-unflagged % (want 0), seated-and-flagged % (want 0)',
      v_off, v_seat, v_vac, v_dead, v_held_vac;
  END IF;

  -- No person holds two seats in these cities (a loose at-large match would seat one person three times).
  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE g.name IN ('City of Hammond, Indiana, US', 'City of Kokomo, Indiana, US', 'City of Greenwood, Indiana, US') GROUP BY och.politician_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'CA_0419: % people hold more than one seat in these cities', v_dupe; END IF;

  SELECT count(*) FILTER (WHERE NOT p.is_active), count(*) FILTER (WHERE ot.term_end IS NOT NULL), count(*)
    INTO v_inact, v_ended, v_terms
  FROM essentials.office_terms ot
  JOIN essentials.politicians p ON p.id = ot.politician_id
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name IN ('City of Hammond, Indiana, US', 'City of Kokomo, Indiana, US', 'City of Greenwood, Indiana, US');
  IF v_inact <> 0 OR v_ended <> 0 OR v_terms <> 33 THEN
    RAISE EXCEPTION 'CA_0419: % inactive holders, % ended terms, % terms (want 0, 0, 33)', v_inact, v_ended, v_terms;
  END IF;

  RAISE NOTICE 'CA_0419 OK: 33 offices, 33 seated (32 new + 1 reused), 0 vacant, 0 dead, 0 doubled';
END $$;

COMMIT;
