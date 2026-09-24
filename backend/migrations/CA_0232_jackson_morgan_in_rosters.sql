-- CA_0232_jackson_morgan_in_rosters.sql
--
-- Jackson and Morgan County (Indiana) rosters, checked against each county's own council page and the 2022 /
-- 2024 general-election results, plus four Jackson officer handovers the data never recorded.
-- Run scripts/load-indiana-wayeo-council-boundaries.ts FIRST (it now also loads Jackson 2-4 and Morgan 1-3);
-- this file refuses to run without those six boundaries.
--
-- WHY (measured 2026-09-24)
-- -------------------------
--   Each county council has seven members (four districts, three at large). The data held Jackson 3 of 7
--   (District 1, two at large) and Morgan 4 of 7 (District 4, three at large). Official rosters:
--     Morgan  https://morgancounty.in.gov/department/index.php?structureid=11 (read 2026-09-24)
--             District 1 Chip Keller (president), 2 Melissa Greene, 3 Brian Culp (vice president), 4 Troy
--             Sprinkle; at large Kim Merideth, Vickie Kivett, Joe Crone. Ballotpedia's 2022 general lists
--             exactly Keller / Greene / Culp / Sprinkle for Districts 1-4.
--     Jackson https://jacksoncounty.in.gov/government/departments_a-h/county_council/index.php (read 2026-09-24)
--             District 1 Michael Davidson, 2 Jacquelyn Jasinski, 3 Brian Thompson, 4 Brady Riley; at large
--             Brett Turner, Amanda Lowery, John L. Nolting. The page lists each district's precincts; they
--             match the X0062 boundaries' numbering exactly (every 2024 precinct, all four districts).
--             2022 general: Districts 2 and 4 were won by Jake Brown and Austin Edington, so Jasinski and
--             Riley came in later by caucus; no source found gives the date -> start_precision 'unknown'.
--   Jackson officers whose holder in the data has left (The (Seymour) Tribune):
--     Commissioner District 3  Matt Reedy retired effective 2025-09-16 (tribtown.com 2025-08-29); a caucus
--                              on 2025-09-11 chose Andrew Stauffer (tribtown.com 2025-09-12).
--     Auditor                  the data holds Jamie Pyle, the interim; Hans Eilbracht was sworn in
--                              2024-07-29 (tribtown.com 2025-08-29) and resigned in 2025; the 2025-09-11
--                              caucus chose Melissa Gray.
--     Coroner                  Paul Foster resigned in 2025; the 2025-09-11 caucus chose Lauren Earl.
--     Circuit Court Clerk      the data holds Amanda Lowery, elected clerk in 2022, who has held an
--                              at-large council seat since January 2025; the clerk is Hope Cissna
--                              ("county Clerk Hope Cissna", tribtown.com 2025-09-26). No source gives
--                              Cissna's start: OPERATOR DECISION 2026-09-24 (Chris Andrews) — seat her from
--                              2025 with year precision and close Lowery's clerk term 2024-12-31, the last
--                              day before her council term.
--
-- DATES — what each start asserts
-- --------------------------------
--   2023-01-01 'year'   Keller, Greene, Culp, Thompson: won the 2022 general; a term begins January 1.
--   2025-01-01 'year'   Lowery (council at large): won the 2024 general. Cissna (clerk): operator decision.
--   unknown             Jasinski, Riley: appointed after the 2022 election, date not found.
--   2024-07-29 'day'    Eilbracht (auditor), sworn in; closes Pyle's interim term 2024-07-28.
--   2025-09-11 'month'  Gray (auditor), Earl (coroner): chosen by caucus that day; sworn-in day not found.
--                       Closes Eilbracht / Foster 2025-09-10 (they had resigned by 2025-08-29; exact days
--                       not found — office_terms has no end precision, so this is the latest end possible).
--   2025-09-17 'month'  Stauffer (commissioner): Reedy's retirement took effect 2025-09-16.
--
-- SHAPE — the Monroe / CA_0208 pattern
-- ------------------------------------
--   Each new district seat gets its own chamber 'Council - District N' with name_formal '<County> County
--   Council' (so it groups with the rest), its own COUNTY district on its X0062 boundary (geo_id
--   '18<fips3>0000N'), and an office copied from the county's existing district seat. Jackson's third at-large
--   seat is a new office in the existing at-large chamber on the existing county-wide at-large district.
--   Reedy, Foster and Pyle hold nothing afterwards: is_incumbent -> false (the incumbents-only reads filter
--   on it; check:occupancy requires every politicians INSERT to name it).
--
-- NOT CHANGED: Turner / Nolting / Davidson / Sprinkle / Merideth / Kivett / Crone (already seated, start
--   unknown from the 2026-07 backfill); no race row.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews). Loader first (6 new X0062 boundaries,
--   every gate passed; X0062 holds 33). Dry run: every gate passed, ROLLBACK; apply: COMMIT; re-run inside
--   BEGIN/ROLLBACK: every INSERT 0, UPDATE 0, every gate passed. Live address search:
--     220 N Chestnut St, Seymour      council District 4 Riley + at large Lowery / Turner / Nolting; Auditor Gray,
--                                     Clerk Cissna, Commissioner D3 Stauffer, Coroner Earl
--     180 S Main St, Martinsville     council District 1 Keller + at large Crone / Kivett / Merideth
--   check:reachability OK (UNREACHABLE 9/9).
--
-- ROLLBACK: delete the office_terms rows whose source starts 'CA_0232' and reopen the four closed ones
--   (term_end = NULL, how_ended = NULL on Reedy / Pyle / Foster / Lowery-clerk, and delete Eilbracht's),
--   then delete the seven new offices, six districts, six chambers and eleven politicians by the ids below,
--   and set is_incumbent back to true for Reedy, Foster, Pyle.
-- IDEMPOTENT: fixed ids with NOT EXISTS guards; seat_officeholder is idempotent; a re-run changes 0 rows.

BEGIN;

CREATE TEMP TABLE ca0232_seat ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Jackson County', '071', 2, '4bca64cf-8ab7-464e-9e94-2129b8fe0b2b'::uuid, 'b2f71ad2-d059-4b14-8bf8-8bab113fadee'::uuid, '5c363e73-cf7a-453c-95cf-500dfb0c7419'::uuid, '5cc8797a-9b42-4b6b-ab58-e60b3f35e3f1'::uuid, '07c56245-8884-46dd-9c1b-86bedf377274'::uuid, '0c9e55f8-3b7e-4a9f-884b-4c2234eaba94'::uuid, '1807100002', 'd9b5f5d0-1523-4c6d-b298-87ec66001c24'::uuid),
  ('Jackson County', '071', 3, '4bca64cf-8ab7-464e-9e94-2129b8fe0b2b'::uuid, 'b2f71ad2-d059-4b14-8bf8-8bab113fadee'::uuid, '5c363e73-cf7a-453c-95cf-500dfb0c7419'::uuid, 'e91d796a-54a7-44a9-9f5f-c61c1d531c5d'::uuid, '915d8ba6-4146-40bd-819d-6a2d6e4f1a2b'::uuid, 'c2ac8190-ff70-4116-88be-287f3c3c0b12'::uuid, '1807100003', 'aaa06b3b-5452-4516-8f5a-5bb6a1628318'::uuid),
  ('Jackson County', '071', 4, '4bca64cf-8ab7-464e-9e94-2129b8fe0b2b'::uuid, 'b2f71ad2-d059-4b14-8bf8-8bab113fadee'::uuid, '5c363e73-cf7a-453c-95cf-500dfb0c7419'::uuid, '3776af11-0b4b-4e61-ae31-d189667fd0ea'::uuid, '172085e3-eab5-4ef0-b8b2-316e8c17bdba'::uuid, '8d8a3ab2-634c-4523-98df-a36dcb16e53a'::uuid, '1807100004', 'cdf7ed2f-ad5c-45f6-85c1-ef5355e45cc3'::uuid),
  ('Morgan County', '109', 1, 'f6ff6700-572d-449d-9154-e8079d9349f8'::uuid, '5b3b5e69-fbb6-48a6-b7ef-bcb6eeae4659'::uuid, '7867f1a3-78b4-4bc5-b0d1-ca6893cae309'::uuid, 'b50f16bb-b91a-4436-b99a-6e80bd8c9839'::uuid, '4e52e612-3a64-4a7a-b4fd-88eb5a0de8d8'::uuid, '5683a0ef-48ff-446e-9170-90465453c868'::uuid, '1810900001', '82be1f5e-ddc1-4b8e-8f02-e763d04a73b5'::uuid),
  ('Morgan County', '109', 2, 'f6ff6700-572d-449d-9154-e8079d9349f8'::uuid, '5b3b5e69-fbb6-48a6-b7ef-bcb6eeae4659'::uuid, '7867f1a3-78b4-4bc5-b0d1-ca6893cae309'::uuid, 'ae2dbf4d-4f2c-44ec-8be2-3cfa654635eb'::uuid, '0a24b571-e531-44a9-be37-98c036c5614c'::uuid, '64759b09-077d-4c78-8b84-1b67095adafd'::uuid, '1810900002', 'd23c0a7a-b4b4-41eb-9bae-23ed923eb10e'::uuid),
  ('Morgan County', '109', 3, 'f6ff6700-572d-449d-9154-e8079d9349f8'::uuid, '5b3b5e69-fbb6-48a6-b7ef-bcb6eeae4659'::uuid, '7867f1a3-78b4-4bc5-b0d1-ca6893cae309'::uuid, 'f4ed9cb0-c376-40cc-92dd-16ee7937b7bf'::uuid, '485937a8-36ad-4b42-a706-4db19b06452b'::uuid, '3d8f7fe6-4d02-4350-a4ae-2867834b64fb'::uuid, '1810900003', '633a162f-00b3-40ec-a963-3030ee4bbc73'::uuid)
) AS v(county, fips3, n, tmpl_office, tmpl_chamber, tmpl_district, chamber_id, district_id, office_id, geo_id, politician_id);

CREATE TEMP TABLE ca0232_person ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('82be1f5e-ddc1-4b8e-8f02-e763d04a73b5'::uuid, 'keller', 'Chip', 'Keller', 'Chip Keller', '{}'::text[], false, true),
  ('d23c0a7a-b4b4-41eb-9bae-23ed923eb10e'::uuid, 'greene', 'Melissa', 'Greene', 'Melissa Greene', '{}'::text[], false, true),
  ('633a162f-00b3-40ec-a963-3030ee4bbc73'::uuid, 'culp', 'Brian', 'Culp', 'Brian Culp', '{}'::text[], false, true),
  ('d9b5f5d0-1523-4c6d-b298-87ec66001c24'::uuid, 'jasinski', 'Jacquelyn', 'Jasinski', 'Jacquelyn Jasinski', '{"Jacquelyn Hackman Jasinski"}'::text[], true, true),
  ('aaa06b3b-5452-4516-8f5a-5bb6a1628318'::uuid, 'thompson', 'Brian', 'Thompson', 'Brian H. Thompson', '{"Brian Thompson"}'::text[], false, true),
  ('cdf7ed2f-ad5c-45f6-85c1-ef5355e45cc3'::uuid, 'riley', 'Brady', 'Riley', 'Brady Riley', '{"Brady A. Riley"}'::text[], true, true),
  ('979bdcf7-0f4d-4d0e-a341-fe5daac6cafc'::uuid, 'stauffer', 'Andrew', 'Stauffer', 'Andrew Stauffer', '{}'::text[], true, true),
  ('6c7fbc00-35c6-4ee4-b2bf-2d3e01e74478'::uuid, 'gray', 'Melissa', 'Gray', 'Melissa Gray', '{}'::text[], true, true),
  ('eba9189b-4e0b-4b6e-8ab7-a05ec5439482'::uuid, 'earl', 'Lauren', 'Earl', 'Lauren Earl', '{}'::text[], true, true),
  ('7e6c22dc-8550-4a28-aebb-94c5d9c34de2'::uuid, 'cissna', 'Hope', 'Cissna', 'Hope Cissna', '{}'::text[], false, true),
  ('5056319d-4e60-49c5-9c0a-70fe8fbed106'::uuid, 'eilbracht', 'Hans', 'Eilbracht', 'Hans Eilbracht', '{}'::text[], true, false)
) AS v(id, k, first_name, last_name, full_name, alternate_names, is_appointed, is_incumbent);

-- ---------------------------------------------------------------------------
-- 0. Pre-flight.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; n2 int; n3 int; n4 int;
BEGIN
  -- 0a. The six boundaries are loaded.
  SELECT count(*) INTO n FROM ca0232_seat s JOIN essentials.geofence_boundaries gb ON gb.geo_id = s.geo_id AND gb.mtfcc = 'X0062';
  IF n <> 6 THEN RAISE EXCEPTION 'X0062 boundaries for the new seats: % of 6 — run the loader first', n; END IF;

  -- 0b. Templates are the rows the header describes.
  SELECT count(*) INTO n FROM ca0232_seat s
    JOIN essentials.offices o ON o.id = s.tmpl_office AND o.chamber_id = s.tmpl_chamber AND o.district_id = s.tmpl_district
    JOIN essentials.chambers ch ON ch.id = s.tmpl_chamber AND ch.name_formal = s.county || ' Council'
    JOIN essentials.districts d ON d.id = s.tmpl_district AND d.district_type = 'COUNTY' AND d.mtfcc = 'X0062';
  IF n <> 6 THEN RAISE EXCEPTION 'templates: % of 6 as recorded', n; END IF;

  -- 0c. The new ids are free or already this file's rows; no other office already holds these seat titles.
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
   WHERE ch.government_id IN ('28d0d034-b742-4660-9a57-406f3950d075', '9fc0a81a-ae72-43f1-94c2-d1c2de4cdc91')
     AND (o.title, ch.government_id) IN (SELECT 'Council - District ' || s.n,
            CASE s.county WHEN 'Jackson County' THEN '28d0d034-b742-4660-9a57-406f3950d075'::uuid ELSE '9fc0a81a-ae72-43f1-94c2-d1c2de4cdc91'::uuid END FROM ca0232_seat s)
     AND o.id NOT IN (SELECT office_id FROM ca0232_seat);
  SELECT count(*) INTO n2 FROM essentials.districts WHERE geo_id IN (SELECT geo_id FROM ca0232_seat) AND id NOT IN (SELECT district_id FROM ca0232_seat);
  IF n > 0 OR n2 > 0 THEN RAISE EXCEPTION 'seat titles already held by other offices: %, geo_ids on other districts: %', n, n2; END IF;

  -- 0d. None of the eleven people exists under another id (name + not this file's id).
  SELECT count(*) INTO n FROM essentials.politicians p JOIN ca0232_person c ON lower(p.full_name) = lower(c.full_name) AND p.id <> c.id;
  IF n > 0 THEN RAISE EXCEPTION '% politician(s) with one of these names already exist under another id', n; END IF;

  -- 0e. The four officer offices hold the predecessor (first run) or the successor (re-run).
  SELECT count(*) INTO n3 FROM (VALUES
      ('249e19ad-f296-4cca-9713-87243ed9f2b1'::uuid, 'f4f70426-fcc3-4919-948b-04b5fa77a84f'::uuid, 'stauffer'),
      ('aa4f02eb-ef84-467a-9904-70eec2891e0e', 'fed8dfce-0492-45cc-9e66-3c36c2924e3e', 'gray'),
      ('e5b5ee18-4ba2-4e82-a032-67755874fa6a', '7eef9bfd-c6ad-4335-b289-0147e8c696ff', 'earl'),
      ('427ebaee-751e-472c-82b2-0dcf2ed9ec22', '929dae10-0eda-4c53-bfa7-0216f2f10e16', 'cissna')) AS x(office_id, prev_pid, succ)
    JOIN essentials.office_current_holder och ON och.office_id = x.office_id
   WHERE och.politician_id = x.prev_pid OR och.politician_id = (SELECT id FROM ca0232_person WHERE k = x.succ);
  IF n3 <> 4 THEN RAISE EXCEPTION 'officer offices: % of 4 hold the recorded predecessor or successor', n3; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. People.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, is_active, is_incumbent, is_vacant,
                                    is_appointed, data_source, alternate_names)
SELECT c.id, c.first_name, c.last_name, c.full_name, NULL, true, c.is_incumbent, false, c.is_appointed,
       CASE WHEN c.k IN ('keller', 'greene', 'culp') THEN 'https://morgancounty.in.gov/department/index.php?structureid=11 (read 2026-09-24)' ELSE 'https://jacksoncounty.in.gov/government/departments_a-h/county_council/index.php (read 2026-09-24)' END, c.alternate_names
  FROM ca0232_person c
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = c.id);

-- ---------------------------------------------------------------------------
-- 2. Six district seats: chamber, district, office — each copied from the county's existing district seat.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.chambers (id, external_id, government_id, name, name_formal, official_count, term_limit, term_length,
                                 inauguration_rules, election_frequency, election_rules, vacancy_rules, remarks, staggered_term,
                                 website_url, policy_engagement_level, election_method)
SELECT s.chamber_id, NULL, t.government_id, 'Council - District ' || s.n, t.name_formal, t.official_count, t.term_limit, t.term_length,
       t.inauguration_rules, t.election_frequency, t.election_rules, t.vacancy_rules, t.remarks, t.staggered_term,
       t.website_url, t.policy_engagement_level, t.election_method
  FROM ca0232_seat s JOIN essentials.chambers t ON t.id = s.tmpl_chamber
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = s.chamber_id);

INSERT INTO essentials.districts (id, external_id, ocd_id, label, district_type, district_id, subtype, state, city, num_officials,
                                  valid_from, valid_to, last_update_date, mtfcc, geo_id, is_judicial, has_unknown_boundaries,
                                  retention, tiger_geoid, government_id, population, population_source_year, official_web_url,
                                  census_unit_id, representation_basis)
SELECT s.district_id, NULL, t.ocd_id, 'District ' || s.n, t.district_type, s.n::text, t.subtype, t.state, t.city, t.num_officials,
       t.valid_from, t.valid_to, t.last_update_date, 'X0062', s.geo_id, t.is_judicial, t.has_unknown_boundaries,
       t.retention, NULL, t.government_id, NULL, NULL, t.official_web_url, NULL, t.representation_basis
  FROM ca0232_seat s JOIN essentials.districts t ON t.id = s.tmpl_district
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = s.district_id);

INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
                                normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
                                faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT s.office_id, s.chamber_id, s.district_id, 'Council - District ' || s.n, t.representing_state, t.representing_city,
       t.description, t.seats, t.normalized_position_name, t.partisan_type, t.salary, t.is_appointed_position, false, NULL,
       t.faces_retention_vote, t.role_canonical, t.voting_powers, t.representation_note
  FROM ca0232_seat s JOIN essentials.offices t ON t.id = s.tmpl_office
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = s.office_id);

-- Jackson's third at-large seat: a new office in the existing at-large chamber and district.
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
                                normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
                                faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT 'd03079ac-7b6b-4f7d-946b-ee6e9cf6a9e9'::uuid, t.chamber_id, t.district_id, t.title, t.representing_state, t.representing_city, t.description, t.seats,
       t.normalized_position_name, t.partisan_type, t.salary, t.is_appointed_position, false, NULL,
       t.faces_retention_vote, t.role_canonical, t.voting_powers, t.representation_note
  FROM essentials.offices t WHERE t.id = 'ffb7f219-4c5d-4fdc-83e4-64e8065144a1'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = 'd03079ac-7b6b-4f7d-946b-ee6e9cf6a9e9');

-- ---------------------------------------------------------------------------
-- 3. Terms on the new seats.
-- ---------------------------------------------------------------------------
SELECT essentials.seat_officeholder(s.office_id, s.politician_id, DATE '2023-01-01',
         'CA_0232: ' || CASE c.k WHEN 'keller' THEN 'Morgan County Council District 1; won the 2022 general (Ballotpedia, Morgan County, Indiana, elections, 2022); Indiana county council terms begin January 1 after the election; earlier service not researched. Roster: https://morgancounty.in.gov/department/index.php?structureid=11 (read 2026-09-24)' WHEN 'greene' THEN 'Morgan County Council District 2; won the 2022 general (Ballotpedia 2022); term began January 2023; earlier service not researched. Roster: https://morgancounty.in.gov/department/index.php?structureid=11 (read 2026-09-24)'
                               WHEN 'culp' THEN 'Morgan County Council District 3; won the 2022 general (Ballotpedia 2022); term began January 2023; earlier service not researched. Roster: https://morgancounty.in.gov/department/index.php?structureid=11 (read 2026-09-24)' ELSE 'Jackson County Council District 3; Brian H. Thompson won the 2022 general (Ballotpedia, Jackson County, Indiana, elections, 2022); term began January 2023; earlier service not researched. Roster: https://jacksoncounty.in.gov/government/departments_a-h/county_council/index.php (read 2026-09-24)' END,
         'elected', 'year')
  FROM ca0232_seat s JOIN ca0232_person c ON c.id = s.politician_id
 WHERE c.k IN ('keller', 'greene', 'culp', 'thompson');

SELECT essentials.seat_officeholder('d03079ac-7b6b-4f7d-946b-ee6e9cf6a9e9'::uuid, '929dae10-0eda-4c53-bfa7-0216f2f10e16'::uuid, DATE '2025-01-01', 'CA_0232: ' || 'Jackson County Council at large; Amanda Cunningham Lowery won the 2024 general, three seats (Ballotpedia, Jackson County, Indiana, elections, 2024); term began January 2025. Roster: https://jacksoncounty.in.gov/government/departments_a-h/county_council/index.php (read 2026-09-24)', 'elected', 'year');

-- Jasinski and Riley: appointed after the 2022 election; no date found. seat_officeholder refuses a NULL start,
-- so the open-ended 'unknown' term is written directly — the new offices have no other term to collide with.
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT s.office_id, s.politician_id, NULL, NULL, 'unknown', 'appointed',
       'CA_0232: Jackson County Council District ' || s.n || '; on the county council roster (https://jacksoncounty.in.gov/government/departments_a-h/county_council/index.php (read 2026-09-24)); the 2022 general '
       || 'was won by ' || CASE s.n WHEN 2 THEN 'Jake Brown' ELSE 'Austin Edington' END || ' (Ballotpedia 2022), so the seat '
       || 'was filled later by caucus; appointment date not found'
  FROM ca0232_seat s JOIN ca0232_person c ON c.id = s.politician_id
 WHERE c.k IN ('jasinski', 'riley')
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = s.office_id);

-- ---------------------------------------------------------------------------
-- 4. Jackson officer handovers (seat_officeholder closes each predecessor the day before).
-- ---------------------------------------------------------------------------
SELECT essentials.seat_officeholder('aa4f02eb-ef84-467a-9904-70eec2891e0e'::uuid, (SELECT id FROM ca0232_person WHERE k = 'eilbracht'),
         DATE '2024-07-29', 'CA_0232: Jackson County Auditor; Hans Eilbracht appointed and sworn in 2024-07-29, replacing interim '
         || 'Auditor Jamie Pyle (tribtown.com 2025-08-29, "Caucus to replace three elected officials who recently resigned")',
         'appointed', 'day', 'unknown');
SELECT essentials.seat_officeholder('aa4f02eb-ef84-467a-9904-70eec2891e0e'::uuid, (SELECT id FROM ca0232_person WHERE k = 'gray'),
         DATE '2025-09-11', 'CA_0232: Jackson County Auditor; Melissa Gray chosen by the Republican caucus of 2025-09-11 to replace '
         || 'Hans Eilbracht, who resigned (tribtown.com 2025-09-12); sworn-in day not found',
         'appointed', 'month', 'resigned');
SELECT essentials.seat_officeholder('e5b5ee18-4ba2-4e82-a032-67755874fa6a'::uuid, (SELECT id FROM ca0232_person WHERE k = 'earl'),
         DATE '2025-09-11', 'CA_0232: Jackson County Coroner; Lauren Earl chosen by the caucus of 2025-09-11 to replace Paul Foster, '
         || 'who resigned (tribtown.com 2025-09-12); sworn-in day not found',
         'appointed', 'month', 'resigned');
SELECT essentials.seat_officeholder('249e19ad-f296-4cca-9713-87243ed9f2b1'::uuid, (SELECT id FROM ca0232_person WHERE k = 'stauffer'),
         DATE '2025-09-17', 'CA_0232: Jackson County Commissioner District 3; Andrew Stauffer chosen by the caucus of 2025-09-11 '
         || '(tribtown.com 2025-09-12) to replace Matt Reedy, whose retirement took effect 2025-09-16 (tribtown.com 2025-08-29)',
         'appointed', 'month', 'retired');
SELECT essentials.seat_officeholder('427ebaee-751e-472c-82b2-0dcf2ed9ec22'::uuid, (SELECT id FROM ca0232_person WHERE k = 'cissna'),
         DATE '2025-01-01', 'CA_0232: Jackson County Circuit Court Clerk; Hope Cissna ("county Clerk Hope Cissna", tribtown.com '
         || '2025-09-26). Start not found: OPERATOR DECISION 2026-09-24 — year 2025, closing Amanda Lowery''s clerk term '
         || '2024-12-31, the day before her at-large council term began',
         'unknown', 'year', 'unknown');

UPDATE essentials.politicians SET is_incumbent = false
 WHERE id IN ('f4f70426-fcc3-4919-948b-04b5fa77a84f', '7eef9bfd-c6ad-4335-b289-0147e8c696ff', 'fed8dfce-0492-45cc-9e66-3c36c2924e3e')
   AND is_incumbent = true
   AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = politicians.id);

-- ---------------------------------------------------------------------------
-- 5. Post-verify.
-- ---------------------------------------------------------------------------
DO $$
DECLARE r record; n int;
BEGIN
  -- 5a. Each council has seven held seats, and the holders are the roster.
  FOR r IN
    SELECT g.name AS gov, count(*) AS seats, count(och.politician_id) AS held,
           string_agg(p.last_name, ',' ORDER BY p.last_name) AS names
      FROM essentials.governments g JOIN essentials.chambers ch ON ch.government_id = g.id
      JOIN essentials.offices o ON o.chamber_id = ch.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE g.id IN ('28d0d034-b742-4660-9a57-406f3950d075', '9fc0a81a-ae72-43f1-94c2-d1c2de4cdc91') AND ch.name_formal LIKE '% County Council'
     GROUP BY g.name
  LOOP
    IF r.seats <> 7 OR r.held <> 7 OR r.names NOT IN ('Davidson,Jasinski,Lowery,Nolting,Riley,Thompson,Turner',
                                                      'Crone,Culp,Greene,Keller,Kivett,Merideth,Sprinkle') THEN
      RAISE EXCEPTION '%: % seats, % held, holders % (want 7, 7, the roster)', r.gov, r.seats, r.held, r.names;
    END IF;
  END LOOP;

  -- 5b. The four Jackson officer offices hold their successors; the auditor chain is Pyle -> Eilbracht -> Gray.
  SELECT count(*) INTO n FROM (VALUES
      ('249e19ad-f296-4cca-9713-87243ed9f2b1'::uuid, 'stauffer'), ('aa4f02eb-ef84-467a-9904-70eec2891e0e', 'gray'),
      ('e5b5ee18-4ba2-4e82-a032-67755874fa6a', 'earl'), ('427ebaee-751e-472c-82b2-0dcf2ed9ec22', 'cissna')) AS x(office_id, k)
    JOIN essentials.office_current_holder och ON och.office_id = x.office_id
    JOIN ca0232_person c ON c.k = x.k AND c.id = och.politician_id;
  IF n <> 4 THEN RAISE EXCEPTION 'officer successors seated: % of 4', n; END IF;
  SELECT count(*) INTO n FROM essentials.office_terms t JOIN ca0232_person c ON c.id = t.politician_id AND c.k = 'eilbracht'
   WHERE t.office_id = 'aa4f02eb-ef84-467a-9904-70eec2891e0e' AND t.term_start = DATE '2024-07-29' AND t.term_end = DATE '2025-09-10';
  IF n <> 1 THEN RAISE EXCEPTION 'Eilbracht auditor term 2024-07-29..2025-09-10: % row(s)', n; END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE office_id = '249e19ad-f296-4cca-9713-87243ed9f2b1'
     AND politician_id = 'f4f70426-fcc3-4919-948b-04b5fa77a84f' AND term_end = DATE '2025-09-16' AND how_ended = 'retired';
  IF n <> 1 THEN RAISE EXCEPTION 'Reedy closed 2025-09-16 retired: % row(s)', n; END IF;

  -- 5c. A point on each new boundary reaches its new district through the address join.
  SELECT count(*) INTO n FROM ca0232_seat s JOIN essentials.geofence_boundaries gb0 ON gb0.geo_id = s.geo_id AND gb0.mtfcc = 'X0062'
   WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb JOIN essentials.districts d ON d.geo_id = gb.geo_id
                  AND gb.mtfcc LIKE 'X%' AND gb.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d.district_type IN ('LOCAL','COUNTY')
                 WHERE ST_Covers(gb.geometry, ST_PointOnSurface(gb0.geometry)) AND d.id = s.district_id);
  IF n <> 6 THEN RAISE EXCEPTION 'address round trip: % of 6', n; END IF;

  -- 5d. Nobody left behind as a seatless incumbent.
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id IN ('f4f70426-fcc3-4919-948b-04b5fa77a84f', '7eef9bfd-c6ad-4335-b289-0147e8c696ff', 'fed8dfce-0492-45cc-9e66-3c36c2924e3e')
     AND p.is_incumbent;
  IF n > 0 THEN RAISE EXCEPTION '% departed officer(s) still flagged is_incumbent', n; END IF;

  RAISE NOTICE 'OK: Jackson and Morgan councils 7/7 each on the official rosters; Jackson commissioner D3 / auditor / coroner / clerk on their successors';
END $$;

COMMIT;
