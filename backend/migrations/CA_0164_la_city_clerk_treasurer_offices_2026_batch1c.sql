-- CA_0164_la_city_clerk_treasurer_offices_2026_batch1c.sql
-- LA-cities slice, batch 1c: the ELECTED City Clerk and City Treasurer of 7 at-large LA-County cities.
-- None of these offices existed in the DB (the 2025 CA Roster import loaded councils and mayors only), so their
-- Nov 3 2026 contests had nothing to bind to. This file creates each office, seats its current holder, and seeds
-- the contest.
--
-- MODEL (the Carson City Clerk / City Treasurer pattern already in the DB): one office per elected post on the city's
-- existing LOCAL_EXEC whole-city district (geo_id = Census place; Burbank's and South Gate's had no office yet), each
-- under its own chamber ("City Clerk" / "City Treasurer") belonging to the city's government. Fixed ids -> re-runnable.
--
-- HOLDERS (each confirmed on an official city source, read 2026-09-22; quote + URL in office_terms.source):
--   Hawthorne    City Clerk     Dayna Williams-Hunter      start unknown (unknown)
--   Hawthorne    City Treasurer Marie Poindexter-Hornback  start unknown (unknown)
--   South Gate   City Clerk     Yodit Glaze                start unknown (unknown)
--   South Gate   City Treasurer Jose De La Paz             start unknown (unknown)
--   Burbank      City Clerk     Kimberley Clark            start unknown (unknown)
--   Burbank      City Treasurer Krystle Ang Palmer         start unknown (unknown)
--   Baldwin Park City Clerk     Christopher Saenz          start unknown (unknown)
--   Baldwin Park City Treasurer Joanna Valenzuela          start unknown (unknown)
--   Lawndale     City Clerk     Erica Harbison             start unknown (unknown)
--   Monrovia     City Clerk     Alice D. Atkins            start 2022-01-01 (year)
--   Monrovia     City Treasurer Janet Wall                 start 2022-08-02 (day)
--   San Gabriel  City Clerk     Julie Nguyen               start unknown (unknown)
--   San Gabriel  City Treasurer Kevin B. Sawkins           start unknown (unknown)
-- Start dates only where the source states them (Monrovia). Hawthorne's Treasurer is named on an archived copy
-- (2026-04-10) of the city's own Treasurer page -- the live page shows no name; she did not file for re-election.
-- Baldwin Park's Clerk is evidenced by the city's certified candidate list (ballot designation "City Clerk, City of
-- Baldwin Park").
--
-- CONTESTS (city clerk lists, verified name by name against the original documents; same sources as CA_0160/CA_0163):
--   Hawthorne City Clerk          1 candidate(s)  1 incumbent(s)  (uncontested)
--   Hawthorne City Treasurer      2 candidate(s)  0 incumbent(s)
--   South Gate City Treasurer     1 candidate(s)  1 incumbent(s)  (uncontested)
--   South Gate City Clerk         1 candidate(s)  1 incumbent(s)  (uncontested)
--   Burbank City Clerk            1 candidate(s)  1 incumbent(s)  (uncontested)
--   Burbank City Treasurer        1 candidate(s)  1 incumbent(s)  (uncontested)
--   Baldwin Park City Clerk       1 candidate(s)  1 incumbent(s)  (uncontested)
--   Baldwin Park City Treasurer   1 candidate(s)  1 incumbent(s)  (uncontested)
--   Lawndale City Clerk           1 candidate(s)  1 incumbent(s)  (uncontested)
--   Monrovia City Clerk           1 candidate(s)  1 incumbent(s)  (uncontested)
--   Monrovia City Treasurer       1 candidate(s)  1 incumbent(s)  (uncontested)
--   San Gabriel City Clerk        1 candidate(s)  1 incumbent(s)  (uncontested)
--   San Gabriel City Treasurer    1 candidate(s)  1 incumbent(s)  (uncontested)
-- Every uncontested contest here stays on the ballot as far as the city record shows: Monrovia's 9/15/2026 clerk update
-- confirms it; South Gate, Baldwin Park, San Gabriel and Lawndale agendas / election pages show no appointment in lieu.
--
-- RACES go on '2026 LA County General' (d91a20ce-557e-4615-a31b-5b2b3df2ed14); primary_party NULL; no party stored.

BEGIN;

-- ─── C1. One chamber per new office, under the city's government (the Carson City Clerk pattern) ──
INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)  -- slug is generated
SELECT v.id, (SELECT c.government_id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                JOIN essentials.chambers c ON c.id = o.chamber_id
               WHERE d.geo_id = v.place AND d.district_type = 'LOCAL' ORDER BY o.id LIMIT 1),
       v.name, v.name_formal, 'full'
  FROM (VALUES
    ('9a7f16c5-0cb5-4865-ad1c-0dbc4d61f87b'::uuid, '0632548', 'City Clerk', 'Hawthorne City Clerk'),
    ('fb82b309-ae08-4307-95b0-15914e7b8110'::uuid, '0632548', 'City Treasurer', 'Hawthorne City Treasurer'),
    ('0f13b3f1-f5e0-4a8c-97be-bb1e9b8804e3'::uuid, '0673080', 'City Clerk', 'South Gate City Clerk'),
    ('14d718bd-a118-4136-b43b-1a5d41e24479'::uuid, '0673080', 'City Treasurer', 'South Gate City Treasurer'),
    ('6ac2d956-4ff6-43d6-92ec-ba9022386690'::uuid, '0608954', 'City Clerk', 'Burbank City Clerk'),
    ('54183001-9bfb-42e1-81b5-b5f15352decb'::uuid, '0608954', 'City Treasurer', 'Burbank City Treasurer'),
    ('e2b8ac95-de76-408d-9ea9-0eb5ebcf778a'::uuid, '0603666', 'City Clerk', 'Baldwin Park City Clerk'),
    ('5a26476f-23de-4c4b-a3d3-26365caf9057'::uuid, '0603666', 'City Treasurer', 'Baldwin Park City Treasurer'),
    ('b8934c15-9583-4ad1-ae87-65d40e7592a5'::uuid, '0640886', 'City Clerk', 'Lawndale City Clerk'),
    ('168cbd66-f576-41a3-977b-23f33d03a7bf'::uuid, '0648648', 'City Clerk', 'Monrovia City Clerk'),
    ('6786e438-fd0d-474d-b9ea-0ca6013a7ec4'::uuid, '0648648', 'City Treasurer', 'Monrovia City Treasurer'),
    ('60b324d3-3183-4008-a6f0-cb1b26acb907'::uuid, '0667042', 'City Clerk', 'San Gabriel City Clerk'),
    ('a4d73c80-6f7e-46fb-b0a5-b133392020c9'::uuid, '0667042', 'City Treasurer', 'San Gabriel City Treasurer')
  ) AS v(id, place, name, name_formal)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = v.id);

-- ─── C2. The office, on the city's existing LOCAL_EXEC (whole-city) district ─────────────────
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers)
SELECT v.oid, v.cid, d.id, v.title, 'CA', 1, v.title, false, false, false, 'full'
  FROM (VALUES
    ('1ca3356d-4f4c-4e4d-b09a-9c4cf12ee444'::uuid, '9a7f16c5-0cb5-4865-ad1c-0dbc4d61f87b'::uuid, '0632548', 'City Clerk'),
    ('56407b26-a0a8-4e10-9895-6ebde9f3f4ca'::uuid, 'fb82b309-ae08-4307-95b0-15914e7b8110'::uuid, '0632548', 'City Treasurer'),
    ('ab376f16-ad38-4769-9360-a3df2b24f6b4'::uuid, '0f13b3f1-f5e0-4a8c-97be-bb1e9b8804e3'::uuid, '0673080', 'City Clerk'),
    ('9f260a99-8f9d-4f88-ba9f-907edc5e24b7'::uuid, '14d718bd-a118-4136-b43b-1a5d41e24479'::uuid, '0673080', 'City Treasurer'),
    ('58f1acf6-6744-4462-a7ae-b4e47fdbd43c'::uuid, '6ac2d956-4ff6-43d6-92ec-ba9022386690'::uuid, '0608954', 'City Clerk'),
    ('da4ebba9-806c-4b84-ac44-3bbebc3f976d'::uuid, '54183001-9bfb-42e1-81b5-b5f15352decb'::uuid, '0608954', 'City Treasurer'),
    ('8d1840cb-71a5-4081-a06e-f3476aceadb2'::uuid, 'e2b8ac95-de76-408d-9ea9-0eb5ebcf778a'::uuid, '0603666', 'City Clerk'),
    ('7cc42f99-b1a3-413e-b6e4-2d9df04584fc'::uuid, '5a26476f-23de-4c4b-a3d3-26365caf9057'::uuid, '0603666', 'City Treasurer'),
    ('59be4eef-c727-43fe-97b8-0f36034465eb'::uuid, 'b8934c15-9583-4ad1-ae87-65d40e7592a5'::uuid, '0640886', 'City Clerk'),
    ('4dbafd93-34e4-4ca1-b053-6dbb6c0c45dc'::uuid, '168cbd66-f576-41a3-977b-23f33d03a7bf'::uuid, '0648648', 'City Clerk'),
    ('959d5374-d0c5-4c55-bfbb-d96aefb79d99'::uuid, '6786e438-fd0d-474d-b9ea-0ca6013a7ec4'::uuid, '0648648', 'City Treasurer'),
    ('da02e4d7-debf-448e-bfbe-b6f5b7aeeaee'::uuid, '60b324d3-3183-4008-a6f0-cb1b26acb907'::uuid, '0667042', 'City Clerk'),
    ('2074953c-5155-4107-8f2e-ae79ff5a1df1'::uuid, 'a4d73c80-6f7e-46fb-b0a5-b133392020c9'::uuid, '0667042', 'City Treasurer')
  ) AS v(oid, cid, place, title)
  JOIN essentials.districts d ON d.geo_id = v.place AND d.district_type = 'LOCAL_EXEC'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.oid);

-- ─── C3. The current holder (party never stored) ────────────────────────────────────────────
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, is_active, is_incumbent, is_vacant,
                                    is_appointed, data_source, alternate_names)
SELECT v.id, v.first_name, v.last_name, v.full_name, NULL, true, true, false, false, v.url, v.alt
  FROM (VALUES
    ('8190afe1-1fcf-4b1a-9925-56b3666fcfaa'::uuid, 'Dayna', 'Williams-Hunter', 'Dayna Williams-Hunter', 'https://www.cityofhawthorne.org/government/city-clerk', ARRAY['Dayna S. Williams-Hunter']::text[]),
    ('b19b4ced-ba4e-4194-8d3b-baf2e13de4a9'::uuid, 'Marie', 'Poindexter-Hornback', 'Marie Poindexter-Hornback', 'http://web.archive.org/web/20260410150721/https://www.cityofhawthorne.org/government/city-treasurer', '{}'::text[]),
    ('4927f8bc-8c74-4e35-ad4a-dd1b0567506d'::uuid, 'Yodit', 'Glaze', 'Yodit Glaze', 'https://cityofsouthgate.granicus.com/AgendaViewer.php?view_id=1&event_id=680', '{}'::text[]),
    ('51e26673-6c1e-4045-8b96-d1f4dbb61d44'::uuid, 'Jose', 'De La Paz', 'Jose De La Paz', 'https://cityofsouthgate.granicus.com/AgendaViewer.php?view_id=1&event_id=680', '{}'::text[]),
    ('aec84b9f-5dad-4acf-a775-4f62a4e741d1'::uuid, 'Kimberley', 'Clark', 'Kimberley Clark', 'https://www.burbankca.gov/elected-officials', '{}'::text[]),
    ('0bf0c706-c02f-41dd-815c-8823de6ce2a6'::uuid, 'Krystle', 'Palmer', 'Krystle Ang Palmer', 'https://www.burbankca.gov/elected-officials', ARRAY['Krystle Palmer']::text[]),
    ('0a8e5d45-8656-4661-bd68-74973fce2618'::uuid, 'Christopher', 'Saenz', 'Christopher Saenz', 'https://www.baldwinpark.com/DocumentCenter/View/5174/Baldwin-Park----Certified-List-of-Candidates-list-2026-PDF', '{}'::text[]),
    ('1533649a-faa6-4137-a1c9-72237d0b61a6'::uuid, 'Joanna', 'Valenzuela', 'Joanna Valenzuela', 'https://www.baldwinpark.com/directory.aspx?did=8', '{}'::text[]),
    ('54cca76a-0c5c-45f9-b6ab-64737c42775b'::uuid, 'Erica', 'Harbison', 'Erica Harbison', 'https://www.lawndale.ca.gov/i_want_to/learn_about/elections', '{}'::text[]),
    ('4441953d-967f-4b0a-9927-7295647c2398'::uuid, 'Alice', 'Atkins', 'Alice D. Atkins', 'https://www.monroviaca.gov/your-government/city-council/meet-the-city-council', ARRAY['Alice Atkins']::text[]),
    ('8d08dee2-284d-4351-ad96-2205f90a1917'::uuid, 'Janet', 'Wall', 'Janet Wall', 'https://www.monroviaca.gov/your-government/city-council/meet-the-city-council', '{}'::text[]),
    ('bad84e9c-fcb4-468d-ab7f-e17bb8ad8c6c'::uuid, 'Julie', 'Nguyen', 'Julie Nguyen', 'https://www.sangabrielcity.com/AgendaCenter/ViewFile/Agenda/_09152026-1475', ARRAY['Thu Nguyen', 'Thu "Julie" Nguyen']::text[]),
    ('94739984-6d96-41ee-b146-ad2b4056120b'::uuid, 'Kevin', 'Sawkins', 'Kevin B. Sawkins', 'https://www.sangabrielcity.com/AgendaCenter/ViewFile/Agenda/_09152026-1475', ARRAY['Kevin Sawkins']::text[])
  ) AS v(id, first_name, last_name, full_name, url, alt)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, v.ts, v.prec, v.how, v.src
  FROM (VALUES
    ('1ca3356d-4f4c-4e4d-b09a-9c4cf12ee444'::uuid, '8190afe1-1fcf-4b1a-9925-56b3666fcfaa'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per https://www.cityofhawthorne.org/government/city-clerk (read 2026-09-22) -- city clerk page lists "Dayna Williams-Hunter, City Clerk". Start not researched.'),
    ('56407b26-a0a8-4e10-9895-6ebde9f3f4ca'::uuid, 'b19b4ced-ba4e-4194-8d3b-baf2e13de4a9'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per http://web.archive.org/web/20260410150721/https://www.cityofhawthorne.org/government/city-treasurer (read 2026-09-22) -- archived copy (2026-04-10) of the official City Treasurer page names her; she did not file for re-election (the clerk extended nominations for Treasurer on 8/7/2026). Start not researched.'),
    ('ab376f16-ad38-4769-9360-a3df2b24f6b4'::uuid, '4927f8bc-8c74-4e35-ad4a-dd1b0567506d'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per https://cityofsouthgate.granicus.com/AgendaViewer.php?view_id=1&event_id=680 (read 2026-09-22) -- city council agenda header: "CITY CLERK, Yodit Glaze". Start not researched.'),
    ('9f260a99-8f9d-4f88-ba9f-907edc5e24b7'::uuid, '51e26673-6c1e-4045-8b96-d1f4dbb61d44'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per https://cityofsouthgate.granicus.com/AgendaViewer.php?view_id=1&event_id=680 (read 2026-09-22) -- city council agenda header: "CITY TREASURER, Jose De La Paz". Start not researched.'),
    ('58f1acf6-6744-4462-a7ae-b4e47fdbd43c'::uuid, 'aec84b9f-5dad-4acf-a775-4f62a4e741d1'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per https://www.burbankca.gov/elected-officials (read 2026-09-22) -- Elected Officials page: "City Clerk Kimberley Clark". Start not researched.'),
    ('da4ebba9-806c-4b84-ac44-3bbebc3f976d'::uuid, '0bf0c706-c02f-41dd-815c-8823de6ce2a6'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per https://www.burbankca.gov/elected-officials (read 2026-09-22) -- Elected Officials page: "City Treasurer Krystle Ang Palmer". Start not researched.'),
    ('8d1840cb-71a5-4081-a06e-f3476aceadb2'::uuid, '0a8e5d45-8656-4661-bd68-74973fce2618'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per https://www.baldwinpark.com/DocumentCenter/View/5174/Baldwin-Park----Certified-List-of-Candidates-list-2026-PDF (read 2026-09-22) -- the city''s Certified List of Qualified Candidates (8/13/2026) gives his ballot designation as "City Clerk, City of Baldwin Park". Start not researched.'),
    ('7cc42f99-b1a3-413e-b6e4-2d9df04584fc'::uuid, '1533649a-faa6-4137-a1c9-72237d0b61a6'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per https://www.baldwinpark.com/directory.aspx?did=8 (read 2026-09-22) -- city staff directory: "Joanna Valenzuela, City Treasurer". Start not researched.'),
    ('59be4eef-c727-43fe-97b8-0f36034465eb'::uuid, '54cca76a-0c5c-45f9-b6ab-64737c42775b'::uuid, NULL::date, 'unknown', 'elected', 'CA_0164: seated per https://www.lawndale.ca.gov/i_want_to/learn_about/elections (read 2026-09-22) -- election page: "City Clerk Erica Harbison (Elected) November 2026". Start not researched.'),
    ('4dbafd93-34e4-4ca1-b053-6dbb6c0c45dc'::uuid, '4441953d-967f-4b0a-9927-7295647c2398'::uuid, '2022-01-01'::date, 'year', 'elected', 'CA_0164: seated per https://www.monroviaca.gov/your-government/city-council/meet-the-city-council (read 2026-09-22) -- council page: appointed City Clerk 2009, elected 2013, "re-elected in 2017 and 2022" -> current term from 2022. Start as stated.'),
    ('959d5374-d0c5-4c55-bfbb-d96aefb79d99'::uuid, '8d08dee2-284d-4351-ad96-2205f90a1917'::uuid, '2022-08-02'::date, 'day', 'appointed', 'CA_0164: seated per https://www.monroviaca.gov/your-government/city-council/meet-the-city-council (read 2026-09-22) -- council page: "Janet was appointed City Treasurer on August 2, 2022". Start as stated.'),
    ('da02e4d7-debf-448e-bfbe-b6f5b7aeeaee'::uuid, 'bad84e9c-fcb4-468d-ab7f-e17bb8ad8c6c'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per https://www.sangabrielcity.com/AgendaCenter/ViewFile/Agenda/_09152026-1475 (read 2026-09-22) -- city council agenda (9/15/2026) lists "Julie Nguyen, City Clerk". Start not researched.'),
    ('2074953c-5155-4107-8f2e-ae79ff5a1df1'::uuid, '94739984-6d96-41ee-b146-ad2b4056120b'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0164: seated per https://www.sangabrielcity.com/AgendaCenter/ViewFile/Agenda/_09152026-1475 (read 2026-09-22) -- city council agenda (9/15/2026) lists "Kevin B. Sawkins, City Treasurer". Start not researched.')
  ) AS v(oid, pid, ts, prec, how, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid AND t.politician_id = v.pid);

-- ─── 0. Pre-flight: every binding target exists ───────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (VALUES
    ('0632548', 'LOCAL_EXEC', 'City Clerk', 'Hawthorne City Clerk'),
    ('0632548', 'LOCAL_EXEC', 'City Treasurer', 'Hawthorne City Treasurer'),
    ('0673080', 'LOCAL_EXEC', 'City Treasurer', 'South Gate City Treasurer'),
    ('0673080', 'LOCAL_EXEC', 'City Clerk', 'South Gate City Clerk'),
    ('0608954', 'LOCAL_EXEC', 'City Clerk', 'Burbank City Clerk'),
    ('0608954', 'LOCAL_EXEC', 'City Treasurer', 'Burbank City Treasurer'),
    ('0603666', 'LOCAL_EXEC', 'City Clerk', 'Baldwin Park City Clerk'),
    ('0603666', 'LOCAL_EXEC', 'City Treasurer', 'Baldwin Park City Treasurer'),
    ('0640886', 'LOCAL_EXEC', 'City Clerk', 'Lawndale City Clerk'),
    ('0648648', 'LOCAL_EXEC', 'City Clerk', 'Monrovia City Clerk'),
    ('0648648', 'LOCAL_EXEC', 'City Treasurer', 'Monrovia City Treasurer'),
    ('0667042', 'LOCAL_EXEC', 'City Clerk', 'San Gabriel City Clerk'),
    ('0667042', 'LOCAL_EXEC', 'City Treasurer', 'San Gabriel City Treasurer')
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
    ('0632548', 'LOCAL_EXEC', 'City Clerk', 'Hawthorne City Clerk', 1),
    ('0632548', 'LOCAL_EXEC', 'City Treasurer', 'Hawthorne City Treasurer', 1),
    ('0673080', 'LOCAL_EXEC', 'City Treasurer', 'South Gate City Treasurer', 1),
    ('0673080', 'LOCAL_EXEC', 'City Clerk', 'South Gate City Clerk', 1),
    ('0608954', 'LOCAL_EXEC', 'City Clerk', 'Burbank City Clerk', 1),
    ('0608954', 'LOCAL_EXEC', 'City Treasurer', 'Burbank City Treasurer', 1),
    ('0603666', 'LOCAL_EXEC', 'City Clerk', 'Baldwin Park City Clerk', 1),
    ('0603666', 'LOCAL_EXEC', 'City Treasurer', 'Baldwin Park City Treasurer', 1),
    ('0640886', 'LOCAL_EXEC', 'City Clerk', 'Lawndale City Clerk', 1),
    ('0648648', 'LOCAL_EXEC', 'City Clerk', 'Monrovia City Clerk', 1),
    ('0648648', 'LOCAL_EXEC', 'City Treasurer', 'Monrovia City Treasurer', 1),
    ('0667042', 'LOCAL_EXEC', 'City Clerk', 'San Gabriel City Clerk', 1),
    ('0667042', 'LOCAL_EXEC', 'City Treasurer', 'San Gabriel City Treasurer', 1)
          ) AS v(place, dtype, otitle, pos, seats)) t
 WHERE t.office_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = t.pos);

-- ─── 2. Candidates ────────────────────────────────────────────────────────────────────
INSERT INTO essentials.race_candidates
       (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, occupational_designation, source)
SELECT r.id, v.pid, v.full_name, v.first_name, v.last_name, v.inc, 'active', v.desig, v.src
  FROM (VALUES
    ('Hawthorne City Clerk', 'Dayna S. Williams-Hunter', 'Dayna', 'Williams-Hunter', '8190afe1-1fcf-4b1a-9925-56b3666fcfaa'::uuid, true, NULL, 'City of Hawthorne, Notice of Qualified Candidates for Public Office, dated 8/17/2026 (cityofhawthorne.org/government/city-clerk/election-information-and-voting). Retrieved 2026-09-22.'),
    ('Hawthorne City Treasurer', 'L. David Patterson', 'L.', 'Patterson', NULL::uuid, false, NULL, 'City of Hawthorne, Notice of Qualified Candidates for Public Office, dated 8/17/2026 (cityofhawthorne.org/government/city-clerk/election-information-and-voting). Retrieved 2026-09-22.'),
    ('Hawthorne City Treasurer', 'Raymond Vergara', 'Raymond', 'Vergara', NULL::uuid, false, NULL, 'City of Hawthorne, Notice of Qualified Candidates for Public Office, dated 8/17/2026 (cityofhawthorne.org/government/city-clerk/election-information-and-voting). Retrieved 2026-09-22.'),
    ('South Gate City Treasurer', 'Jose De La Paz', 'Jose', 'De La Paz', '51e26673-6c1e-4045-8b96-d1f4dbb61d44'::uuid, true, NULL, 'City of South Gate City Clerk, List of Qualified Candidates, November 3, 2026 General Election, dated 8/18/2026 (cityofsouthgate.org/files/sharedassets/public/v/2/government/departments/city-clerks-office/elections/documents/list-of-qualified-candidates-nov-3-2026-general-election-2.pdf). Retrieved 2026-09-22.'),
    ('South Gate City Clerk', 'Yodit Glaze', 'Yodit', 'Glaze', '4927f8bc-8c74-4e35-ad4a-dd1b0567506d'::uuid, true, NULL, 'City of South Gate City Clerk, List of Qualified Candidates, November 3, 2026 General Election, dated 8/18/2026 (cityofsouthgate.org/files/sharedassets/public/v/2/government/departments/city-clerks-office/elections/documents/list-of-qualified-candidates-nov-3-2026-general-election-2.pdf). Retrieved 2026-09-22.'),
    ('Burbank City Clerk', 'Kimberley Clark', 'Kimberley', 'Clark', 'aec84b9f-5dad-4acf-a775-4f62a4e741d1'::uuid, true, 'Burbank City Clerk', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Burbank City Treasurer', 'Krystle Palmer', 'Krystle', 'Palmer', '0bf0c706-c02f-41dd-815c-8823de6ce2a6'::uuid, true, 'Incumbent', 'City of Burbank City Clerk, November 3, 2026 General Municipal Election Candidates, in ballot order with ballot designations (burbankca.gov/web/city-clerks-office/november-3-2026-candidates). Retrieved 2026-09-22.'),
    ('Baldwin Park City Clerk', 'Christopher Saenz', 'Christopher', 'Saenz', '0a8e5d45-8656-4661-bd68-74973fce2618'::uuid, true, 'City Clerk, City of Baldwin Park', 'City of Baldwin Park, Certified List of Qualified Candidates, 8/13/2026 (baldwinpark.com/DocumentCenter/View/5174). Retrieved 2026-09-22.'),
    ('Baldwin Park City Treasurer', 'Joanna Valenzuela', 'Joanna', 'Valenzuela', '1533649a-faa6-4137-a1c9-72237d0b61a6'::uuid, true, 'Elected City Treasuer', 'City of Baldwin Park, Certified List of Qualified Candidates, 8/13/2026 (baldwinpark.com/DocumentCenter/View/5174). Retrieved 2026-09-22.'),
    ('Lawndale City Clerk', 'Erica Harbison', 'Erica', 'Harbison', '54cca76a-0c5c-45f9-b6ab-64737c42775b'::uuid, true, 'Incumbent', 'City of Lawndale, Certified List of Qualified Candidates, approved 8/11/2026 (lawndale.ca.gov/.../2026 Election/Lawndale Certified List of Candidates Form_Online signed.pdf). Retrieved 2026-09-22.'),
    ('Monrovia City Clerk', 'Alice D. Atkins', 'Alice', 'Atkins', '4441953d-967f-4b0a-9927-7295647c2398'::uuid, true, NULL, 'City of Monrovia City Clerk, November 3, 2026 General Municipal Election Qualified Candidates, 8/7/2026 (monroviaca.gov/home/showpublisheddocument/41152/639217168700800000). Retrieved 2026-09-22.'),
    ('Monrovia City Treasurer', 'Janet Wall', 'Janet', 'Wall', '8d08dee2-284d-4351-ad96-2205f90a1917'::uuid, true, NULL, 'City of Monrovia City Clerk, November 3, 2026 General Municipal Election Qualified Candidates, 8/7/2026 (monroviaca.gov/home/showpublisheddocument/41152/639217168700800000). Retrieved 2026-09-22.'),
    ('San Gabriel City Clerk', 'Thu “Julie” Nguyen', 'Thu', 'Nguyen', 'bad84e9c-fcb4-468d-ab7f-e17bb8ad8c6c'::uuid, true, NULL, 'City of San Gabriel, November 3, 2026 General Municipal Election Candidate List with Qualified column, 9/9/2026 (sangabrielcity.com/DocumentCenter/View/25195). Retrieved 2026-09-22.'),
    ('San Gabriel City Treasurer', 'Kevin Sawkins', 'Kevin', 'Sawkins', '94739984-6d96-41ee-b146-ad2b4056120b'::uuid, true, NULL, 'City of San Gabriel, November 3, 2026 General Municipal Election Candidate List with Qualified column, 9/9/2026 (sangabrielcity.com/DocumentCenter/View/25195). Retrieved 2026-09-22.')
  ) AS v(pos, full_name, first_name, last_name, pid, inc, desig, src)
  JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.pos
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name));

-- ─── 3. Antipartisan: clear the stored party on every linked candidate row ──────────
UPDATE essentials.politicians SET party = NULL
 WHERE party IS NOT NULL AND id IN ('0a8e5d45-8656-4661-bd68-74973fce2618', '0bf0c706-c02f-41dd-815c-8823de6ce2a6', '1533649a-faa6-4137-a1c9-72237d0b61a6', '4441953d-967f-4b0a-9927-7295647c2398', '4927f8bc-8c74-4e35-ad4a-dd1b0567506d', '51e26673-6c1e-4045-8b96-d1f4dbb61d44', '54cca76a-0c5c-45f9-b6ab-64737c42775b', '8190afe1-1fcf-4b1a-9925-56b3666fcfaa', '8d08dee2-284d-4351-ad96-2205f90a1917', '94739984-6d96-41ee-b146-ad2b4056120b', 'aec84b9f-5dad-4acf-a775-4f62a4e741d1', 'bad84e9c-fcb4-468d-ab7f-e17bb8ad8c6c');

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  pos text[] := ARRAY['Hawthorne City Clerk', 'Hawthorne City Treasurer', 'South Gate City Treasurer', 'South Gate City Clerk', 'Burbank City Clerk', 'Burbank City Treasurer', 'Baldwin Park City Clerk', 'Baldwin Park City Treasurer', 'Lawndale City Clerk', 'Monrovia City Clerk', 'Monrovia City Treasurer', 'San Gabriel City Clerk', 'San Gabriel City Treasurer'];
  n_races int; n_cands int; n_null int; n_party int; n_badcount int; n_inc int; n_badinc int; n_extralink int; n_linked int;
  n_overinc int; n_unreach int; n_pparty int; n_newheld int; n_ch int;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE r.office_id IS NULL), count(*) FILTER (WHERE r.primary_party IS NOT NULL)
    INTO n_races, n_null, n_party FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  SELECT count(*) INTO n_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  -- each race carries exactly the clerk's field, on the expected seat count
  SELECT count(*) INTO n_badcount FROM (VALUES
      ('Hawthorne City Clerk', 1, 1, 1),
      ('Hawthorne City Treasurer', 1, 2, 0),
      ('South Gate City Treasurer', 1, 1, 1),
      ('South Gate City Clerk', 1, 1, 1),
      ('Burbank City Clerk', 1, 1, 1),
      ('Burbank City Treasurer', 1, 1, 1),
      ('Baldwin Park City Clerk', 1, 1, 1),
      ('Baldwin Park City Treasurer', 1, 1, 1),
      ('Lawndale City Clerk', 1, 1, 1),
      ('Monrovia City Clerk', 1, 1, 1),
      ('Monrovia City Treasurer', 1, 1, 1),
      ('San Gabriel City Clerk', 1, 1, 1),
      ('San Gabriel City Treasurer', 1, 1, 1)
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
  IF n_cands <> 14 THEN RAISE EXCEPTION 'expected 14 candidates, got %', n_cands; END IF;
  IF n_null <> 0 OR n_party <> 0 THEN RAISE EXCEPTION 'office-less (%) or partisan (%) race', n_null, n_party; END IF;
  IF n_badcount <> 0 THEN RAISE EXCEPTION '% race(s) whose seats / candidates / incumbents differ from the clerk list', n_badcount; END IF;
  IF n_inc <> 12 THEN RAISE EXCEPTION 'expected 12 incumbents, got %', n_inc; END IF;
  IF n_badinc <> 0 THEN RAISE EXCEPTION '% incumbent(s) left unlinked', n_badinc; END IF;
  IF n_extralink <> 0 THEN RAISE EXCEPTION '% linked candidate(s) are not a current holder in their city', n_extralink; END IF;
  IF n_linked <> 12 THEN RAISE EXCEPTION 'expected 12 linked candidates, got %', n_linked; END IF;
  IF n_overinc <> 0 THEN RAISE EXCEPTION '% race(s) with more incumbents than seats', n_overinc; END IF;
  IF n_unreach <> 0 THEN RAISE EXCEPTION '% race(s) not reached from inside their own city', n_unreach; END IF;
  IF n_pparty <> 0 THEN RAISE EXCEPTION '% linked candidate row(s) still carry a party', n_pparty; END IF;
  -- every new office exists on its city's LOCAL_EXEC district, under its own chamber, and is held by its named holder
  SELECT count(*) INTO n_newheld FROM (VALUES
      ('1ca3356d-4f4c-4e4d-b09a-9c4cf12ee444'::uuid, '8190afe1-1fcf-4b1a-9925-56b3666fcfaa'::uuid, '0632548', 'City Clerk'),
      ('56407b26-a0a8-4e10-9895-6ebde9f3f4ca'::uuid, 'b19b4ced-ba4e-4194-8d3b-baf2e13de4a9'::uuid, '0632548', 'City Treasurer'),
      ('ab376f16-ad38-4769-9360-a3df2b24f6b4'::uuid, '4927f8bc-8c74-4e35-ad4a-dd1b0567506d'::uuid, '0673080', 'City Clerk'),
      ('9f260a99-8f9d-4f88-ba9f-907edc5e24b7'::uuid, '51e26673-6c1e-4045-8b96-d1f4dbb61d44'::uuid, '0673080', 'City Treasurer'),
      ('58f1acf6-6744-4462-a7ae-b4e47fdbd43c'::uuid, 'aec84b9f-5dad-4acf-a775-4f62a4e741d1'::uuid, '0608954', 'City Clerk'),
      ('da4ebba9-806c-4b84-ac44-3bbebc3f976d'::uuid, '0bf0c706-c02f-41dd-815c-8823de6ce2a6'::uuid, '0608954', 'City Treasurer'),
      ('8d1840cb-71a5-4081-a06e-f3476aceadb2'::uuid, '0a8e5d45-8656-4661-bd68-74973fce2618'::uuid, '0603666', 'City Clerk'),
      ('7cc42f99-b1a3-413e-b6e4-2d9df04584fc'::uuid, '1533649a-faa6-4137-a1c9-72237d0b61a6'::uuid, '0603666', 'City Treasurer'),
      ('59be4eef-c727-43fe-97b8-0f36034465eb'::uuid, '54cca76a-0c5c-45f9-b6ab-64737c42775b'::uuid, '0640886', 'City Clerk'),
      ('4dbafd93-34e4-4ca1-b053-6dbb6c0c45dc'::uuid, '4441953d-967f-4b0a-9927-7295647c2398'::uuid, '0648648', 'City Clerk'),
      ('959d5374-d0c5-4c55-bfbb-d96aefb79d99'::uuid, '8d08dee2-284d-4351-ad96-2205f90a1917'::uuid, '0648648', 'City Treasurer'),
      ('da02e4d7-debf-448e-bfbe-b6f5b7aeeaee'::uuid, 'bad84e9c-fcb4-468d-ab7f-e17bb8ad8c6c'::uuid, '0667042', 'City Clerk'),
      ('2074953c-5155-4107-8f2e-ae79ff5a1df1'::uuid, '94739984-6d96-41ee-b146-ad2b4056120b'::uuid, '0667042', 'City Treasurer')
    ) AS v(oid, pid, place, title)
    JOIN essentials.offices o ON o.id = v.oid AND o.title = v.title
    JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = v.place AND d.district_type = 'LOCAL_EXEC'
    JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id = v.pid;
  SELECT count(*) INTO n_ch FROM essentials.chambers c WHERE c.government_id IS NOT NULL AND c.id IN ('9a7f16c5-0cb5-4865-ad1c-0dbc4d61f87b', 'fb82b309-ae08-4307-95b0-15914e7b8110', '0f13b3f1-f5e0-4a8c-97be-bb1e9b8804e3', '14d718bd-a118-4136-b43b-1a5d41e24479', '6ac2d956-4ff6-43d6-92ec-ba9022386690', '54183001-9bfb-42e1-81b5-b5f15352decb', 'e2b8ac95-de76-408d-9ea9-0eb5ebcf778a', '5a26476f-23de-4c4b-a3d3-26365caf9057', 'b8934c15-9583-4ad1-ae87-65d40e7592a5', '168cbd66-f576-41a3-977b-23f33d03a7bf', '6786e438-fd0d-474d-b9ea-0ca6013a7ec4', '60b324d3-3183-4008-a6f0-cb1b26acb907', 'a4d73c80-6f7e-46fb-b0a5-b133392020c9');
  IF n_newheld <> 13 THEN RAISE EXCEPTION 'clerk/treasurer: % of 13 new offices held by their named holder', n_newheld; END IF;
  IF n_ch <> 13 THEN RAISE EXCEPTION 'clerk/treasurer: % of 13 chambers carry a government', n_ch; END IF;
  RAISE NOTICE 'CA_0164 applied: % races, % candidates, % incumbents linked', n_races, n_cands, n_inc;
END $$;

COMMIT;
