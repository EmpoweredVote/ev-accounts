-- CA_0165_la_city_atlarge_councils_2026_batch2.sql
-- LA-cities slice, batch 2: 11 more at-large LA-County cities. Seats the council member the 2025 CA Roster import
-- left out of 10 of them, repairs one truncated name, and seeds all 11 Nov 3 2026 council contests.
--
-- ROSTER FIX. Each of these councils had 4 of its 5 members (Artesia already had 5). Each missing member is
-- confirmed on the city's own council page, read 2026-09-22 (URL + quote in office_terms.source of each row):
--   San Marino           Tony Chou              start unknown    unknown https://sanmarinoca.gov/government/mayor___city_council_/index.php
--   Walnut               Ritchie Cajulis        start unknown    unknown https://www.walnutca.gov/My-Government/Walnut-City-Council
--   Maywood              Heber Marquez          start unknown    unknown https://www.cityofmaywood.com/186/City-Council
--   Irwindale            H. Manuel Ortiz        start unknown    unknown https://www.irwindaleca.gov/132/City-Council
--   Commerce             Kevin Lainez           start unknown    unknown https://www.commerceca.gov/city-hall/mayor-city-council/mayor-kevin-lainez
--   Hawaiian Gardens     Maria Teresa Del Rio   start unknown    unknown https://www.hgcity.org/government/city-council
--   Rancho Palos Verdes  Paul Seo               start 2022-12-06 day     https://www.rpvca.gov/168/City-Council
--   Rolling Hills        Bea Dieringer          start 2024-11-01 month   https://www.rolling-hills.org/government/city_council/index.php
--   South El Monte       Hector Delgado         start unknown    unknown https://www.cityofsouthelmonte.org/211/City-Council
--   Santa Fe Springs     Joe Angel Zamora       start unknown    unknown https://www.santafesprings.gov/193/Mayor
-- Each gets a seat cloned from the city's lowest-id council office. Start dates only where the page states them.
-- Maywood: "Eddie De La" (first "Eddie De", last "La") is completed to "Eddie De La Riva" per the council page.
--
-- RACES. Candidates from each city clerk's own list, re-checked name by name against the original document (the
-- Santa Fe Springs certified list is a scanned image, read from the rendered page):
--   Rancho Palos Verdes City Council         3 seat(s)   6 candidate(s)  0 incumbent(s)
--   Rolling Hills City Council               3 seat(s)   4 candidate(s)  3 incumbent(s)
--   San Marino City Council                  3 seat(s)   4 candidate(s)  2 incumbent(s)
--   Walnut City Council                      2 seat(s)   4 candidate(s)  2 incumbent(s)
--   Artesia City Council                     3 seat(s)   5 candidate(s)  3 incumbent(s)
--   Maywood City Council                     3 seat(s)   9 candidate(s)  2 incumbent(s)
--   Irwindale City Council                   2 seat(s)   3 candidate(s)  1 incumbent(s)
--   South El Monte City Council              2 seat(s)   3 candidate(s)  2 incumbent(s)
--   Santa Fe Springs City Council            3 seat(s)   6 candidate(s)  3 incumbent(s)
--   Commerce City Council                    3 seat(s)   6 candidate(s)  2 incumbent(s)
--   Hawaiian Gardens City Council            3 seat(s)   5 candidate(s)  3 incumbent(s)
-- Incumbents link to the current holder: Santa Fe Springs' Bill ("William") Rounds is the DB's William K. Rounds;
-- Maywood's "Eduardo Eddie De La Riva" is the renamed row. Commerce's list marks no incumbents; Lainez (Mayor) and
-- Garcia (Mayor Pro Tem) are the sitting members on it (city council pages).
--
-- NOT IN THIS BATCH: cancelled by appointment in lieu of election (EC 10229) -- Agoura Hills (Res. 26-2145), Calabasas
-- (Res. 2026-2033), Hidden Hills (Res. 1064), Westlake Village (Res. 2467-26), Sierra Madre (Res. 26-82), Signal Hill
-- (Res. 2026-08-6962, incl. Clerk + Treasurer), La Habra Heights (Res. 2026-20). On hold, status unclear: Palos Verdes
-- Estates (city lists 3 qualified for 3 seats; the RR/CC list shows only Lozzi) and Rolling Hills Estates (2 for 2,
-- "not more candidates than offices" notice, no 2026 resolution posted).
--
-- RACES go on '2026 LA County General' (d91a20ce-557e-4615-a31b-5b2b3df2ed14); primary_party NULL; party never stored
-- on candidates and cleared on every linked row. IDEMPOTENT: fixed ids; every insert NOT EXISTS-guarded.

BEGIN;

-- ─── R1. Maywood: complete a truncated name ─────────────────────────────────────────────
-- The 2025-roster import stored Council Member Eddie De La Riva as "Eddie De La" (first "Eddie De", last "La").
-- The city council page (cityofmaywood.com/186/City-Council, read 2026-09-22) lists "Eddie De La Riva".
UPDATE essentials.politicians
   SET full_name = 'Eddie De La Riva', first_name = 'Eddie', last_name = 'De La Riva',
       alternate_names = ARRAY(SELECT DISTINCT unnest(coalesce(alternate_names, '{}'::text[]) || ARRAY['Eddie De La', 'Eduardo Eddie De La Riva', 'Eduardo De La Riva']::text[]))
 WHERE id = '0e1d1f05-8cef-4e33-9847-d27100ddb2d4' AND full_name = 'Eddie De La';

-- ─── R2. Politician rows for the missing members (party never stored) ─────────────────────
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, is_active, is_incumbent, is_vacant,
                                    is_appointed, data_source, alternate_names)
SELECT v.id, v.first_name, v.last_name, v.full_name, NULL, true, true, false, false, v.url, v.alt
  FROM (VALUES
    ('c8205802-dc59-44d0-a7fc-a39c34dea7e1'::uuid, 'Tony', 'Chou', 'Tony Chou', 'https://sanmarinoca.gov/government/mayor___city_council_/index.php', '{}'::text[]),
    ('5b6091fd-b81d-4a23-9164-27bef304955b'::uuid, 'Ritchie', 'Cajulis', 'Ritchie Cajulis', 'https://www.walnutca.gov/My-Government/Walnut-City-Council', ARRAY['Richard "Ritchie" Cajulis', 'Richard Cajulis']::text[]),
    ('9104a01d-65c9-4eab-883e-e11c990caab7'::uuid, 'Heber', 'Marquez', 'Heber Marquez', 'https://www.cityofmaywood.com/186/City-Council', '{}'::text[]),
    ('d65eb776-529f-4502-9b3b-ce079b830817'::uuid, 'Manuel', 'Ortiz', 'H. Manuel Ortiz', 'https://www.irwindaleca.gov/132/City-Council', ARRAY['Hector "Manuel" Ortiz', 'Hector Manuel Ortiz']::text[]),
    ('00271c72-2fff-42f9-a568-03066e6201cb'::uuid, 'Kevin', 'Lainez', 'Kevin Lainez', 'https://www.commerceca.gov/city-hall/mayor-city-council/mayor-kevin-lainez', '{}'::text[]),
    ('63fb6abf-499e-4a3c-b2ce-3383b7652d7c'::uuid, 'Maria Teresa', 'Del Rio', 'Maria Teresa Del Rio', 'https://www.hgcity.org/government/city-council', '{}'::text[]),
    ('cb39159d-d293-41c7-a1ac-a379c39de3c4'::uuid, 'Paul', 'Seo', 'Paul Seo', 'https://www.rpvca.gov/168/City-Council', '{}'::text[]),
    ('6661aded-8733-4c13-abae-d4f1e0f96648'::uuid, 'Bea', 'Dieringer', 'Bea Dieringer', 'https://www.rolling-hills.org/government/city_council/index.php', '{}'::text[]),
    ('77343ceb-ee93-4c1c-8c0d-83dc27bd9f8b'::uuid, 'Hector', 'Delgado', 'Hector Delgado', 'https://www.cityofsouthelmonte.org/211/City-Council', '{}'::text[]),
    ('1679c021-b442-49ae-9f9e-0506c76dcdc2'::uuid, 'Joe', 'Zamora', 'Joe Angel Zamora', 'https://www.santafesprings.gov/193/Mayor', ARRAY['Joe Zamora']::text[])
  ) AS v(id, first_name, last_name, full_name, url, alt)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

-- ─── R3. The missing seat: clone the city's lowest-id council office ─────────────────────────
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
                                normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
                                faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT v.oid, t.chamber_id, t.district_id, t.title, t.representing_state, t.representing_city, t.description, t.seats,
       t.normalized_position_name, t.partisan_type, t.salary, t.is_appointed_position, false, NULL,
       t.faces_retention_vote, t.role_canonical, t.voting_powers, t.representation_note
  FROM (VALUES
    ('14f4dfcc-77a1-4954-9e91-396a06963b42'::uuid, '0668224'),
    ('03dca496-c61c-4c85-847c-87b1a44e3d99'::uuid, '0683332'),
    ('e959d9a1-e0bb-4b81-a11a-9a368009324d'::uuid, '0646492'),
    ('cd492fb4-047f-4add-89b0-fd3c0b4e78f5'::uuid, '0636826'),
    ('06cc41a4-d450-4bde-9967-ab103c2631c0'::uuid, '0614974'),
    ('e26e0013-15b5-4f6c-bacc-a89691e24017'::uuid, '0632506'),
    ('8624a727-7029-4433-aef1-e4a1a13c6b87'::uuid, '0659514'),
    ('eacb1032-75ba-4821-8d6a-35373d53a675'::uuid, '0662602'),
    ('f53f79f3-0242-4032-af8f-258265ad5bce'::uuid, '0672996'),
    ('a392136b-e79b-4256-bacd-c8d559ac7f50'::uuid, '0669154')
  ) AS v(oid, place)
  CROSS JOIN LATERAL (SELECT o.* FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                       WHERE d.geo_id = v.place AND d.district_type = 'LOCAL' ORDER BY o.id LIMIT 1) t
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices x WHERE x.id = v.oid);

-- ─── R4. Seat them ─────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, v.ts, v.prec, v.how, v.src
  FROM (VALUES
    ('14f4dfcc-77a1-4954-9e91-396a06963b42'::uuid, 'c8205802-dc59-44d0-a7fc-a39c34dea7e1'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0165: seated per https://sanmarinoca.gov/government/mayor___city_council_/index.php (read 2026-09-22) -- Mayor & City Council page: "Tony Chou, Mayor" (a different person from Council Member John Chou, elected 2024). The 2025 CA Roster import omitted this member; start not researched.'),
    ('03dca496-c61c-4c85-847c-87b1a44e3d99'::uuid, '5b6091fd-b81d-4a23-9164-27bef304955b'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0165: seated per https://www.walnutca.gov/My-Government/Walnut-City-Council (read 2026-09-22) -- City Council page: "Ritchie Cajulis, Council Member". The 2025 CA Roster import omitted this member; start not researched.'),
    ('e959d9a1-e0bb-4b81-a11a-9a368009324d'::uuid, '9104a01d-65c9-4eab-883e-e11c990caab7'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0165: seated per https://www.cityofmaywood.com/186/City-Council (read 2026-09-22) -- City Council page: "Heber Marquez, Mayor" (council-chosen). The 2025 CA Roster import omitted this member; start not researched.'),
    ('cd492fb4-047f-4add-89b0-fd3c0b4e78f5'::uuid, 'd65eb776-529f-4502-9b3b-ce079b830817'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0165: seated per https://www.irwindaleca.gov/132/City-Council (read 2026-09-22) -- City Council page: "H. Manuel Ortiz, Mayor". The 2025 CA Roster import omitted this member; start not researched.'),
    ('06cc41a4-d450-4bde-9967-ab103c2631c0'::uuid, '00271c72-2fff-42f9-a568-03066e6201cb'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0165: seated per https://www.commerceca.gov/city-hall/mayor-city-council/mayor-kevin-lainez (read 2026-09-22) -- Mayor & City Council pages: "Mayor Kevin Lainez". The 2025 CA Roster import omitted this member; start not researched.'),
    ('e26e0013-15b5-4f6c-bacc-a89691e24017'::uuid, '63fb6abf-499e-4a3c-b2ce-3383b7652d7c'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0165: seated per https://www.hgcity.org/government/city-council (read 2026-09-22) -- City Council page: "Maria Teresa Del Rio, Mayor". The 2025 CA Roster import omitted this member; start not researched.'),
    ('8624a727-7029-4433-aef1-e4a1a13c6b87'::uuid, 'cb39159d-d293-41c7-a1ac-a379c39de3c4'::uuid, '2022-12-06'::date, 'day', 'elected', 'CA_0165: seated per https://www.rpvca.gov/168/City-Council (read 2026-09-22) -- City Council page: "Paul Seo" -- sworn in 12/06/22, term ends 12/01/26, elected 11/08/22 (not a 2026 candidate). The 2025 CA Roster import omitted this member; start as stated.'),
    ('eacb1032-75ba-4821-8d6a-35373d53a675'::uuid, '6661aded-8733-4c13-abae-d4f1e0f96648'::uuid, '2024-11-01'::date, 'month', 'elected', 'CA_0165: seated per https://www.rolling-hills.org/government/city_council/index.php (read 2026-09-22) -- City Council page: "Mayor Bea Dieringer, Term Began 11/2024, Term Ends 12/2028". The 2025 CA Roster import omitted this member; start as stated.'),
    ('f53f79f3-0242-4032-af8f-258265ad5bce'::uuid, '77343ceb-ee93-4c1c-8c0d-83dc27bd9f8b'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0165: seated per https://www.cityofsouthelmonte.org/211/City-Council (read 2026-09-22) -- City Council page: "Hector Delgado, Councilmember" (not up until 2028). The 2025 CA Roster import omitted this member; start not researched.'),
    ('a392136b-e79b-4256-bacd-c8d559ac7f50'::uuid, '1679c021-b442-49ae-9f9e-0506c76dcdc2'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0165: seated per https://www.santafesprings.gov/193/Mayor (read 2026-09-22) -- Mayor page: "Joe Angel Zamora, Mayor" (selected by the council January 13, 2026). The 2025 CA Roster import omitted this member; start not researched.')
  ) AS v(oid, pid, ts, prec, how, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid AND t.politician_id = v.pid);

-- ─── 0. Pre-flight: every binding target exists ───────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (VALUES
    ('0659514', 'LOCAL', NULL, 'Rancho Palos Verdes City Council'),
    ('0662602', 'LOCAL', NULL, 'Rolling Hills City Council'),
    ('0668224', 'LOCAL', NULL, 'San Marino City Council'),
    ('0683332', 'LOCAL', NULL, 'Walnut City Council'),
    ('0602896', 'LOCAL', NULL, 'Artesia City Council'),
    ('0646492', 'LOCAL', NULL, 'Maywood City Council'),
    ('0636826', 'LOCAL', NULL, 'Irwindale City Council'),
    ('0672996', 'LOCAL', NULL, 'South El Monte City Council'),
    ('0669154', 'LOCAL', NULL, 'Santa Fe Springs City Council'),
    ('0614974', 'LOCAL', NULL, 'Commerce City Council'),
    ('0632506', 'LOCAL', NULL, 'Hawaiian Gardens City Council')
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
    ('0659514', 'LOCAL', NULL, 'Rancho Palos Verdes City Council', 3),
    ('0662602', 'LOCAL', NULL, 'Rolling Hills City Council', 3),
    ('0668224', 'LOCAL', NULL, 'San Marino City Council', 3),
    ('0683332', 'LOCAL', NULL, 'Walnut City Council', 2),
    ('0602896', 'LOCAL', NULL, 'Artesia City Council', 3),
    ('0646492', 'LOCAL', NULL, 'Maywood City Council', 3),
    ('0636826', 'LOCAL', NULL, 'Irwindale City Council', 2),
    ('0672996', 'LOCAL', NULL, 'South El Monte City Council', 2),
    ('0669154', 'LOCAL', NULL, 'Santa Fe Springs City Council', 3),
    ('0614974', 'LOCAL', NULL, 'Commerce City Council', 3),
    ('0632506', 'LOCAL', NULL, 'Hawaiian Gardens City Council', 3)
          ) AS v(place, dtype, otitle, pos, seats)) t
 WHERE t.office_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = t.pos);

-- ─── 2. Candidates ────────────────────────────────────────────────────────────────────
INSERT INTO essentials.race_candidates
       (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, occupational_designation, source)
SELECT r.id, v.pid, v.full_name, v.first_name, v.last_name, v.inc, 'active', v.desig, v.src
  FROM (VALUES
    ('Rancho Palos Verdes City Council', 'David Chura', 'David', 'Chura', NULL::uuid, false, NULL, 'City of Rancho Palos Verdes City Clerk, November 3, 2026 General Municipal Election page, qualified candidates in ballot order (rpvca.gov/1881/November-3-2026-General-Municipal-Election). Retrieved 2026-09-22.'),
    ('Rancho Palos Verdes City Council', 'Michele Patrick Carbone', 'Michele', 'Carbone', NULL::uuid, false, NULL, 'City of Rancho Palos Verdes City Clerk, November 3, 2026 General Municipal Election page, qualified candidates in ballot order (rpvca.gov/1881/November-3-2026-General-Municipal-Election). Retrieved 2026-09-22.'),
    ('Rancho Palos Verdes City Council', 'John Cruikshank', 'John', 'Cruikshank', NULL::uuid, false, NULL, 'City of Rancho Palos Verdes City Clerk, November 3, 2026 General Municipal Election page, qualified candidates in ballot order (rpvca.gov/1881/November-3-2026-General-Municipal-Election). Retrieved 2026-09-22.'),
    ('Rancho Palos Verdes City Council', 'Matthew Brach', 'Matthew', 'Brach', NULL::uuid, false, NULL, 'City of Rancho Palos Verdes City Clerk, November 3, 2026 General Municipal Election page, qualified candidates in ballot order (rpvca.gov/1881/November-3-2026-General-Municipal-Election). Retrieved 2026-09-22.'),
    ('Rancho Palos Verdes City Council', 'Jessica Patton Vlaco', 'Jessica', 'Vlaco', NULL::uuid, false, NULL, 'City of Rancho Palos Verdes City Clerk, November 3, 2026 General Municipal Election page, qualified candidates in ballot order (rpvca.gov/1881/November-3-2026-General-Municipal-Election). Retrieved 2026-09-22.'),
    ('Rancho Palos Verdes City Council', 'Tina Funiciello, Esq.', 'Tina', 'Funiciello', NULL::uuid, false, NULL, 'City of Rancho Palos Verdes City Clerk, November 3, 2026 General Municipal Election page, qualified candidates in ballot order (rpvca.gov/1881/November-3-2026-General-Municipal-Election). Retrieved 2026-09-22.'),
    ('Rolling Hills City Council', 'James Black, M.D.', 'James', 'Black', '3f6742b8-3fb8-43b9-b0e2-79114c5cce7d'::uuid, true, NULL, 'City of Rolling Hills City Clerk, Notice of Election / Nominees, 8/14/2026 (rolling-hills.org/CL_PBN_260814_NoticeOfElectionNominees_F_E.pdf). Retrieved 2026-09-22.'),
    ('Rolling Hills City Council', 'Jeanevra Calhoun', 'Jeanevra', 'Calhoun', NULL::uuid, false, NULL, 'City of Rolling Hills City Clerk, Notice of Election / Nominees, 8/14/2026 (rolling-hills.org/CL_PBN_260814_NoticeOfElectionNominees_F_E.pdf). Retrieved 2026-09-22.'),
    ('Rolling Hills City Council', 'Leah Mirsch', 'Leah', 'Mirsch', '090a9148-f355-47a3-b87d-ff56c5b6ec1c'::uuid, true, NULL, 'City of Rolling Hills City Clerk, Notice of Election / Nominees, 8/14/2026 (rolling-hills.org/CL_PBN_260814_NoticeOfElectionNominees_F_E.pdf). Retrieved 2026-09-22.'),
    ('Rolling Hills City Council', 'Pat Wilson', 'Pat', 'Wilson', '527baa04-a1ec-47e0-9fa9-f5ca47c540c7'::uuid, true, NULL, 'City of Rolling Hills City Clerk, Notice of Election / Nominees, 8/14/2026 (rolling-hills.org/CL_PBN_260814_NoticeOfElectionNominees_F_E.pdf). Retrieved 2026-09-22.'),
    ('San Marino City Council', 'Shelley Boyle', 'Shelley', 'Boyle', NULL::uuid, false, NULL, 'City of San Marino, 2026 City Council Candidates: "Qualified Candidates for the Election" (sanmarinoca.gov/government/elections/2026_city_council_candidates.php). Retrieved 2026-09-22.'),
    ('San Marino City Council', 'Tony Chou', 'Tony', 'Chou', 'c8205802-dc59-44d0-a7fc-a39c34dea7e1'::uuid, true, NULL, 'City of San Marino, 2026 City Council Candidates: "Qualified Candidates for the Election" (sanmarinoca.gov/government/elections/2026_city_council_candidates.php). Retrieved 2026-09-22.'),
    ('San Marino City Council', 'John Dustin', 'John', 'Dustin', NULL::uuid, false, NULL, 'City of San Marino, 2026 City Council Candidates: "Qualified Candidates for the Election" (sanmarinoca.gov/government/elections/2026_city_council_candidates.php). Retrieved 2026-09-22.'),
    ('San Marino City Council', 'Calvin Lo', 'Calvin', 'Lo', '1d1839db-1906-4498-af2f-8ba0a255f2a3'::uuid, true, NULL, 'City of San Marino, 2026 City Council Candidates: "Qualified Candidates for the Election" (sanmarinoca.gov/government/elections/2026_city_council_candidates.php). Retrieved 2026-09-22.'),
    ('Walnut City Council', 'Allen Wu', 'Allen', 'Wu', '3f238e45-43ca-4691-bc74-0c2496823a00'::uuid, true, NULL, 'City of Walnut City Clerk, Elections page: candidate table with Qualified column (walnutca.gov/My-Government/Elections). Retrieved 2026-09-22.'),
    ('Walnut City Council', 'Richard "Ritchie" Cajulis', 'Richard', 'Cajulis', '5b6091fd-b81d-4a23-9164-27bef304955b'::uuid, true, NULL, 'City of Walnut City Clerk, Elections page: candidate table with Qualified column (walnutca.gov/My-Government/Elections). Retrieved 2026-09-22.'),
    ('Walnut City Council', 'Hong "Diana" Zhao', 'Hong', 'Zhao', NULL::uuid, false, NULL, 'City of Walnut City Clerk, Elections page: candidate table with Qualified column (walnutca.gov/My-Government/Elections). Retrieved 2026-09-22.'),
    ('Walnut City Council', 'Stefanie Leilua', 'Stefanie', 'Leilua', NULL::uuid, false, NULL, 'City of Walnut City Clerk, Elections page: candidate table with Qualified column (walnutca.gov/My-Government/Elections). Retrieved 2026-09-22.'),
    ('Artesia City Council', 'Dan Rocha', 'Dan', 'Rocha', NULL::uuid, false, 'Family Caregiver', 'City of Artesia City Clerk, 2026 Election Information: qualified candidates with candidate statements (cityofartesia.us/1618/2026-Election-Information). Retrieved 2026-09-22.'),
    ('Artesia City Council', 'Melissa Ramoso', 'Melissa', 'Ramoso', '0d4b6036-0898-444f-a01a-91847f33855d'::uuid, true, 'Mayor Pro Tem', 'City of Artesia City Clerk, 2026 Election Information: qualified candidates with candidate statements (cityofartesia.us/1618/2026-Election-Information). Retrieved 2026-09-22.'),
    ('Artesia City Council', 'Ali Taj', 'Ali', 'Taj', '2382e3c5-f6ff-4aeb-88c6-8538df3ea05d'::uuid, true, 'Grandfather / Businessman / Councilmember', 'City of Artesia City Clerk, 2026 Election Information: qualified candidates with candidate statements (cityofartesia.us/1618/2026-Election-Information). Retrieved 2026-09-22.'),
    ('Artesia City Council', 'Rene J. Trevino', 'Rene', 'Trevino', '21ad587e-dfcd-405e-8bfb-f03c299e542f'::uuid, true, 'Mayor / Business Owner', 'City of Artesia City Clerk, 2026 Election Information: qualified candidates with candidate statements (cityofartesia.us/1618/2026-Election-Information). Retrieved 2026-09-22.'),
    ('Artesia City Council', 'Craig Francis', 'Craig', 'Francis', NULL::uuid, false, NULL, 'City of Artesia City Clerk, 2026 Election Information: qualified candidates with candidate statements (cityofartesia.us/1618/2026-Election-Information). Retrieved 2026-09-22.'),
    ('Maywood City Council', 'Maritza Cruz', 'Maritza', 'Cruz', NULL::uuid, false, NULL, 'City of Maywood City Clerk, qualified candidate list, November 3, 2026 General Municipal Election, 8/21/2026 (cityofmaywood.com/DocumentCenter/View/3810). Retrieved 2026-09-22.'),
    ('Maywood City Council', 'Mayra Aguiluz', 'Mayra', 'Aguiluz', '80d61182-1d3a-4b9e-891a-ac6851875b16'::uuid, true, NULL, 'City of Maywood City Clerk, qualified candidate list, November 3, 2026 General Municipal Election, 8/21/2026 (cityofmaywood.com/DocumentCenter/View/3810). Retrieved 2026-09-22.'),
    ('Maywood City Council', 'Aleyda Lemus', 'Aleyda', 'Lemus', NULL::uuid, false, NULL, 'City of Maywood City Clerk, qualified candidate list, November 3, 2026 General Municipal Election, 8/21/2026 (cityofmaywood.com/DocumentCenter/View/3810). Retrieved 2026-09-22.'),
    ('Maywood City Council', 'Eduardo Eddie De La Riva', 'Eduardo', 'De La Riva', '0e1d1f05-8cef-4e33-9847-d27100ddb2d4'::uuid, true, NULL, 'City of Maywood City Clerk, qualified candidate list, November 3, 2026 General Municipal Election, 8/21/2026 (cityofmaywood.com/DocumentCenter/View/3810). Retrieved 2026-09-22.'),
    ('Maywood City Council', 'Gabriela A. Bernal', 'Gabriela', 'Bernal', NULL::uuid, false, NULL, 'City of Maywood City Clerk, qualified candidate list, November 3, 2026 General Municipal Election, 8/21/2026 (cityofmaywood.com/DocumentCenter/View/3810). Retrieved 2026-09-22.'),
    ('Maywood City Council', 'Veronica Peral Bernabe', 'Veronica', 'Bernabe', NULL::uuid, false, NULL, 'City of Maywood City Clerk, qualified candidate list, November 3, 2026 General Municipal Election, 8/21/2026 (cityofmaywood.com/DocumentCenter/View/3810). Retrieved 2026-09-22.'),
    ('Maywood City Council', 'Edith Rodriguez', 'Edith', 'Rodriguez', NULL::uuid, false, NULL, 'City of Maywood City Clerk, qualified candidate list, November 3, 2026 General Municipal Election, 8/21/2026 (cityofmaywood.com/DocumentCenter/View/3810). Retrieved 2026-09-22.'),
    ('Maywood City Council', 'Gustavo Villa', 'Gustavo', 'Villa', NULL::uuid, false, NULL, 'City of Maywood City Clerk, qualified candidate list, November 3, 2026 General Municipal Election, 8/21/2026 (cityofmaywood.com/DocumentCenter/View/3810). Retrieved 2026-09-22.'),
    ('Maywood City Council', 'Thomas Ramon Martin', 'Thomas', 'Martin', NULL::uuid, false, NULL, 'City of Maywood City Clerk, qualified candidate list, November 3, 2026 General Municipal Election, 8/21/2026 (cityofmaywood.com/DocumentCenter/View/3810). Retrieved 2026-09-22.'),
    ('Irwindale City Council', 'Hector "Manuel" Ortiz', 'Hector', 'Ortiz', 'd65eb776-529f-4502-9b3b-ce079b830817'::uuid, true, NULL, 'City of Irwindale City Clerk, City Council General Municipal Election page, qualified candidates, 8/17/2026 (irwindaleca.gov/589/). Retrieved 2026-09-22.'),
    ('Irwindale City Council', 'Marguerite S. Lopez-Sapien', 'Marguerite', 'Lopez-Sapien', NULL::uuid, false, NULL, 'City of Irwindale City Clerk, City Council General Municipal Election page, qualified candidates, 8/17/2026 (irwindaleca.gov/589/). Retrieved 2026-09-22.'),
    ('Irwindale City Council', 'Maricela Romero Frymark', 'Maricela', 'Frymark', NULL::uuid, false, NULL, 'City of Irwindale City Clerk, City Council General Municipal Election page, qualified candidates, 8/17/2026 (irwindaleca.gov/589/). Retrieved 2026-09-22.'),
    ('South El Monte City Council', 'Manuel "Manny" Acosta', 'Manuel', 'Acosta', '52a27f1b-ec40-42d4-a0c3-d5c370fef60e'::uuid, true, 'Professor/Incumbent Councilmember', 'City of South El Monte City Clerk, 2026 List of Qualified Candidates, 8/6/2026 (cityofsouthelmonte.org/DocumentCenter/View/7639). Retrieved 2026-09-22.'),
    ('South El Monte City Council', 'Rudy Bojorquez', 'Rudy', 'Bojorquez', '8d4396fa-1637-4502-844d-1b7e5dbe8e0f'::uuid, true, 'Councilmember', 'City of South El Monte City Clerk, 2026 List of Qualified Candidates, 8/6/2026 (cityofsouthelmonte.org/DocumentCenter/View/7639). Retrieved 2026-09-22.'),
    ('South El Monte City Council', 'Kimberly "Kim" Valencia', 'Kimberly', 'Valencia', NULL::uuid, false, 'Continuing Education Manager', 'City of South El Monte City Clerk, 2026 List of Qualified Candidates, 8/6/2026 (cityofsouthelmonte.org/DocumentCenter/View/7639). Retrieved 2026-09-22.'),
    ('Santa Fe Springs City Council', 'Johnny Hernandez', 'Johnny', 'Hernandez', NULL::uuid, false, 'Retiree', 'City of Santa Fe Springs, Certified List of Qualified Candidates, approved by the City Clerk 8/13/2026 (santafesprings.gov/DocumentCenter/View/1299). Retrieved 2026-09-22.'),
    ('Santa Fe Springs City Council', 'Julian Jackson', 'Julian', 'Jackson', NULL::uuid, false, 'MPA', 'City of Santa Fe Springs, Certified List of Qualified Candidates, approved by the City Clerk 8/13/2026 (santafesprings.gov/DocumentCenter/View/1299). Retrieved 2026-09-22.'),
    ('Santa Fe Springs City Council', 'Juanita Martin', 'Juanita', 'Martin', 'd4e58a72-03c0-47f6-9b9d-0ff3db70d3d0'::uuid, true, 'Incumbent', 'City of Santa Fe Springs, Certified List of Qualified Candidates, approved by the City Clerk 8/13/2026 (santafesprings.gov/DocumentCenter/View/1299). Retrieved 2026-09-22.'),
    ('Santa Fe Springs City Council', 'Annette Rodriguez', 'Annette', 'Rodriguez', '751a4678-0c36-443b-8ccb-30a52c94c494'::uuid, true, 'Incumbent', 'City of Santa Fe Springs, Certified List of Qualified Candidates, approved by the City Clerk 8/13/2026 (santafesprings.gov/DocumentCenter/View/1299). Retrieved 2026-09-22.'),
    ('Santa Fe Springs City Council', 'Bill "William" Rounds', 'Bill', 'Rounds', 'd3550d8d-754a-4966-b1b0-4b8036e75da2'::uuid, true, 'Incumbent', 'City of Santa Fe Springs, Certified List of Qualified Candidates, approved by the City Clerk 8/13/2026 (santafesprings.gov/DocumentCenter/View/1299). Retrieved 2026-09-22.'),
    ('Santa Fe Springs City Council', 'Odalys Valladares', 'Odalys', 'Valladares', NULL::uuid, false, 'Business Owner', 'City of Santa Fe Springs, Certified List of Qualified Candidates, approved by the City Clerk 8/13/2026 (santafesprings.gov/DocumentCenter/View/1299). Retrieved 2026-09-22.'),
    ('Commerce City Council', 'Kevin Lainez', 'Kevin', 'Lainez', '00271c72-2fff-42f9-a568-03066e6201cb'::uuid, true, NULL, 'City of Commerce, List of qualified Candidates, November 3, 2026 (commerceca.gov/home/showpublisheddocument/5531). Retrieved 2026-09-22.'),
    ('Commerce City Council', 'Mireya Garcia', 'Mireya', 'Garcia', '09da90d6-7ab7-494a-a4b6-9665a30aed16'::uuid, true, NULL, 'City of Commerce, List of qualified Candidates, November 3, 2026 (commerceca.gov/home/showpublisheddocument/5531). Retrieved 2026-09-22.'),
    ('Commerce City Council', 'Vanessa Haro', 'Vanessa', 'Haro', NULL::uuid, false, NULL, 'City of Commerce, List of qualified Candidates, November 3, 2026 (commerceca.gov/home/showpublisheddocument/5531). Retrieved 2026-09-22.'),
    ('Commerce City Council', 'Leonard Mendoza', 'Leonard', 'Mendoza', NULL::uuid, false, NULL, 'City of Commerce, List of qualified Candidates, November 3, 2026 (commerceca.gov/home/showpublisheddocument/5531). Retrieved 2026-09-22.'),
    ('Commerce City Council', 'Jaime Valencia', 'Jaime', 'Valencia', NULL::uuid, false, NULL, 'City of Commerce, List of qualified Candidates, November 3, 2026 (commerceca.gov/home/showpublisheddocument/5531). Retrieved 2026-09-22.'),
    ('Commerce City Council', 'Nick Padilla', 'Nick', 'Padilla', NULL::uuid, false, NULL, 'City of Commerce, List of qualified Candidates, November 3, 2026 (commerceca.gov/home/showpublisheddocument/5531). Retrieved 2026-09-22.'),
    ('Hawaiian Gardens City Council', 'Dandy De Paula', 'Dandy', 'De Paula', '8bfc4fb1-527a-4cb8-b0c4-439a3a015857'::uuid, true, 'Incumbent', 'City of Hawaiian Gardens City Clerk, List of Official Candidates, November 3, 2026 General Municipal Election, ballot order with qualified dates (hgcity.org/government/departments/city-clerk/candidates-2020-elections). Retrieved 2026-09-22.'),
    ('Hawaiian Gardens City Council', 'Maria Teresa Del Rio', 'Maria Teresa', 'Del Rio', '63fb6abf-499e-4a3c-b2ce-3383b7652d7c'::uuid, true, 'Incumbent', 'City of Hawaiian Gardens City Clerk, List of Official Candidates, November 3, 2026 General Municipal Election, ballot order with qualified dates (hgcity.org/government/departments/city-clerk/candidates-2020-elections). Retrieved 2026-09-22.'),
    ('Hawaiian Gardens City Council', 'Luis Roa', 'Luis', 'Roa', 'b10c4a24-a504-403b-820f-e0115578715a'::uuid, true, 'Incumbent', 'City of Hawaiian Gardens City Clerk, List of Official Candidates, November 3, 2026 General Municipal Election, ballot order with qualified dates (hgcity.org/government/departments/city-clerk/candidates-2020-elections). Retrieved 2026-09-22.'),
    ('Hawaiian Gardens City Council', 'Luis Gonzalez', 'Luis', 'Gonzalez', NULL::uuid, false, 'Accounting Technician', 'City of Hawaiian Gardens City Clerk, List of Official Candidates, November 3, 2026 General Municipal Election, ballot order with qualified dates (hgcity.org/government/departments/city-clerk/candidates-2020-elections). Retrieved 2026-09-22.'),
    ('Hawaiian Gardens City Council', 'Jesus Mendoza', 'Jesus', 'Mendoza', NULL::uuid, false, 'UPS Package Handler', 'City of Hawaiian Gardens City Clerk, List of Official Candidates, November 3, 2026 General Municipal Election, ballot order with qualified dates (hgcity.org/government/departments/city-clerk/candidates-2020-elections). Retrieved 2026-09-22.')
  ) AS v(pos, full_name, first_name, last_name, pid, inc, desig, src)
  JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.pos
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name));

-- ─── 3. Antipartisan: clear the stored party on every linked candidate row ──────────
UPDATE essentials.politicians SET party = NULL
 WHERE party IS NOT NULL AND id IN ('00271c72-2fff-42f9-a568-03066e6201cb', '090a9148-f355-47a3-b87d-ff56c5b6ec1c', '09da90d6-7ab7-494a-a4b6-9665a30aed16', '0d4b6036-0898-444f-a01a-91847f33855d', '0e1d1f05-8cef-4e33-9847-d27100ddb2d4', '1d1839db-1906-4498-af2f-8ba0a255f2a3', '21ad587e-dfcd-405e-8bfb-f03c299e542f', '2382e3c5-f6ff-4aeb-88c6-8538df3ea05d', '3f238e45-43ca-4691-bc74-0c2496823a00', '3f6742b8-3fb8-43b9-b0e2-79114c5cce7d', '527baa04-a1ec-47e0-9fa9-f5ca47c540c7', '52a27f1b-ec40-42d4-a0c3-d5c370fef60e', '5b6091fd-b81d-4a23-9164-27bef304955b', '63fb6abf-499e-4a3c-b2ce-3383b7652d7c', '751a4678-0c36-443b-8ccb-30a52c94c494', '80d61182-1d3a-4b9e-891a-ac6851875b16', '8bfc4fb1-527a-4cb8-b0c4-439a3a015857', '8d4396fa-1637-4502-844d-1b7e5dbe8e0f', 'b10c4a24-a504-403b-820f-e0115578715a', 'c8205802-dc59-44d0-a7fc-a39c34dea7e1', 'd3550d8d-754a-4966-b1b0-4b8036e75da2', 'd4e58a72-03c0-47f6-9b9d-0ff3db70d3d0', 'd65eb776-529f-4502-9b3b-ce079b830817');

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  pos text[] := ARRAY['Rancho Palos Verdes City Council', 'Rolling Hills City Council', 'San Marino City Council', 'Walnut City Council', 'Artesia City Council', 'Maywood City Council', 'Irwindale City Council', 'South El Monte City Council', 'Santa Fe Springs City Council', 'Commerce City Council', 'Hawaiian Gardens City Council'];
  n_races int; n_cands int; n_null int; n_party int; n_badcount int; n_inc int; n_badinc int; n_extralink int; n_linked int;
  n_overinc int; n_unreach int; n_pparty int; n_newheld int; n_size int; n_eddie int;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE r.office_id IS NULL), count(*) FILTER (WHERE r.primary_party IS NOT NULL)
    INTO n_races, n_null, n_party FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  SELECT count(*) INTO n_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  -- each race carries exactly the clerk's field, on the expected seat count
  SELECT count(*) INTO n_badcount FROM (VALUES
      ('Rancho Palos Verdes City Council', 3, 6, 0),
      ('Rolling Hills City Council', 3, 4, 3),
      ('San Marino City Council', 3, 4, 2),
      ('Walnut City Council', 2, 4, 2),
      ('Artesia City Council', 3, 5, 3),
      ('Maywood City Council', 3, 9, 2),
      ('Irwindale City Council', 2, 3, 1),
      ('South El Monte City Council', 2, 3, 2),
      ('Santa Fe Springs City Council', 3, 6, 3),
      ('Commerce City Council', 3, 6, 2),
      ('Hawaiian Gardens City Council', 3, 5, 3)
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
  IF n_races <> 11 THEN RAISE EXCEPTION 'expected 11 races, got %', n_races; END IF;
  IF n_cands <> 55 THEN RAISE EXCEPTION 'expected 55 candidates, got %', n_cands; END IF;
  IF n_null <> 0 OR n_party <> 0 THEN RAISE EXCEPTION 'office-less (%) or partisan (%) race', n_null, n_party; END IF;
  IF n_badcount <> 0 THEN RAISE EXCEPTION '% race(s) whose seats / candidates / incumbents differ from the clerk list', n_badcount; END IF;
  IF n_inc <> 23 THEN RAISE EXCEPTION 'expected 23 incumbents, got %', n_inc; END IF;
  IF n_badinc <> 0 THEN RAISE EXCEPTION '% incumbent(s) left unlinked', n_badinc; END IF;
  IF n_extralink <> 0 THEN RAISE EXCEPTION '% linked candidate(s) are not a current holder in their city', n_extralink; END IF;
  IF n_linked <> 23 THEN RAISE EXCEPTION 'expected 23 linked candidates, got %', n_linked; END IF;
  IF n_overinc <> 0 THEN RAISE EXCEPTION '% race(s) with more incumbents than seats', n_overinc; END IF;
  IF n_unreach <> 0 THEN RAISE EXCEPTION '% race(s) not reached from inside their own city', n_unreach; END IF;
  IF n_pparty <> 0 THEN RAISE EXCEPTION '% linked candidate row(s) still carry a party', n_pparty; END IF;
  -- roster fix: every missing member now holds exactly the seat created for them
  SELECT count(*) INTO n_newheld FROM (VALUES
      ('14f4dfcc-77a1-4954-9e91-396a06963b42'::uuid, 'c8205802-dc59-44d0-a7fc-a39c34dea7e1'::uuid),
      ('03dca496-c61c-4c85-847c-87b1a44e3d99'::uuid, '5b6091fd-b81d-4a23-9164-27bef304955b'::uuid),
      ('e959d9a1-e0bb-4b81-a11a-9a368009324d'::uuid, '9104a01d-65c9-4eab-883e-e11c990caab7'::uuid),
      ('cd492fb4-047f-4add-89b0-fd3c0b4e78f5'::uuid, 'd65eb776-529f-4502-9b3b-ce079b830817'::uuid),
      ('06cc41a4-d450-4bde-9967-ab103c2631c0'::uuid, '00271c72-2fff-42f9-a568-03066e6201cb'::uuid),
      ('e26e0013-15b5-4f6c-bacc-a89691e24017'::uuid, '63fb6abf-499e-4a3c-b2ce-3383b7652d7c'::uuid),
      ('8624a727-7029-4433-aef1-e4a1a13c6b87'::uuid, 'cb39159d-d293-41c7-a1ac-a379c39de3c4'::uuid),
      ('eacb1032-75ba-4821-8d6a-35373d53a675'::uuid, '6661aded-8733-4c13-abae-d4f1e0f96648'::uuid),
      ('f53f79f3-0242-4032-af8f-258265ad5bce'::uuid, '77343ceb-ee93-4c1c-8c0d-83dc27bd9f8b'::uuid),
      ('a392136b-e79b-4256-bacd-c8d559ac7f50'::uuid, '1679c021-b442-49ae-9f9e-0506c76dcdc2'::uuid)
    ) AS v(oid, pid) JOIN essentials.office_current_holder och ON och.office_id = v.oid AND och.politician_id = v.pid;
  -- each of the 11 councils now has exactly its five sitting members (council + Mayor offices on the place)
  SELECT count(*) INTO n_size FROM (
    SELECT d.geo_id FROM essentials.districts d JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id IN ('0659514', '0662602', '0668224', '0683332', '0602896', '0646492', '0636826', '0672996', '0669154', '0614974', '0632506') AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
     GROUP BY d.geo_id HAVING count(DISTINCT och.politician_id) = 5) x;
  SELECT count(*) INTO n_eddie FROM essentials.politicians WHERE id = '0e1d1f05-8cef-4e33-9847-d27100ddb2d4' AND full_name = 'Eddie De La Riva';
  IF n_newheld <> 10 THEN RAISE EXCEPTION 'roster: % of 10 missing members seated', n_newheld; END IF;
  IF n_size <> 11 THEN RAISE EXCEPTION 'roster: only % of 11 councils have exactly 5 sitting members', n_size; END IF;
  IF n_eddie <> 1 THEN RAISE EXCEPTION 'Maywood: Eddie De La Riva rename missing'; END IF;
  RAISE NOTICE 'CA_0165 applied: % races, % candidates, % incumbents linked', n_races, n_cands, n_inc;
END $$;

COMMIT;
