-- CA_0163_la_city_roster_fix_councils_2026_batch1b.sql
-- LA-cities slice, batch 1b: seat the council member the DB is missing in 7 at-large LA-County cities, then seed
-- their Nov 3 2026 council contests (the incumbent could not be linked until the seat existed -- see CA_0160).
--
-- ROSTER FIX. The councils come from the 2025 California Roster import; each of these 7 had 4 of its 5 members
-- (Bell Gardens had 5 rows, but one was a fragment of another member's name). Each missing member is confirmed
-- on the city's own council page, read 2026-09-22 (URL + quote in the office_terms.source of each row):
--   Malibu        Marianne Riggins     start 2022-11-01 month   https://www.malibucity.org/207/City-Council
--   Lawndale      Pat Kearney          start unknown    unknown https://www.lawndale.ca.gov/government/city_council/city_council_contact_information
--   Rosemead      Sandra Armenta       start unknown    unknown https://rosemeadca.gov/city_hall/city_council/index.php
--   San Gabriel   John Wu              start unknown    unknown https://www.sangabrielcity.com/87/City-Council
--   Monrovia      Tamala Kelly         start 2022-01-01 year    https://www.monroviaca.gov/your-government/city-council/meet-the-city-council
--   Pico Rivera   Gustavo V. Camacho   start unknown    unknown https://www.pico-rivera.org/our-city/city-council/
--   Bell Gardens  Isabel Guillén       start unknown    unknown https://www.bellgardens.org/government/city-council
-- Six get a new seat cloned from the city's lowest-id council office; Bell Gardens reuses the fragment's seat.
-- Start dates are written only where the page states them (Riggins "November 2022", Kelly "elected ... in 2022");
-- the rest are start_precision unknown, exactly like every other member of these councils in the DB.
-- Bell Gardens: "Francis De" is renamed "Francis De Leon Sanchez" (the row that carries her 200 campaign-finance
-- links); the "Leon Sanchez" fragment's term, its duplicate headshot row and its generic city-website contact are
-- removed, and the fragment row deleted after a scan of every politician-id column finds no reference left.
-- NOT FIXED HERE (cosmetic, owed): in cities whose council picks its mayor, the LOCAL_EXEC "Mayor" office still
-- holds the 2025 roster's mayor (e.g. Malibu Stewart; the 2026 mayor is Silverstein). Membership is right; the
-- title is stale.
--
-- RACES (same pattern as CA_0160 -- city clerk lists, verified name by name against the original documents):
--   Malibu City Council            2 seat(s)   4 candidate(s)  2 incumbent(s)
--   Lawndale City Council          2 seat(s)   2 candidate(s)  2 incumbent(s)  (uncontested)
--   Rosemead City Council          3 seat(s)   4 candidate(s)  2 incumbent(s)
--   San Gabriel City Council       3 seat(s)   5 candidate(s)  3 incumbent(s)
--   Monrovia City Council          2 seat(s)   3 candidate(s)  2 incumbent(s)
--   Pico Rivera City Council       2 seat(s)   3 candidate(s)  2 incumbent(s)
--   Bell Gardens City Council      3 seat(s)   5 candidate(s)  3 incumbent(s)
-- Lawndale's council contest is uncontested; the city's election page shows no appointment in lieu of election
-- (checked 2026-09-22), so it is seeded like the other uncontested contests (decision 2026-09-22).
-- Clerk/Treasurer contests (Lawndale, Monrovia, San Gabriel) wait for the clerk & treasurer slice.
--
-- RACES go on '2026 LA County General' (d91a20ce-557e-4615-a31b-5b2b3df2ed14); primary_party NULL; party never
-- stored on candidates, and cleared on every linked politician row.
--
-- IDEMPOTENT: fixed ids for the new offices and politicians; every insert NOT EXISTS-guarded; the rename and the
-- fragment removal are guarded on the old values.

BEGIN;

-- ─── R1. Bell Gardens: repair the split name ─────────────────────────────────────────
-- The 2025-roster import split "Francis De Leon Sanchez" into two holder rows, "Francis De" and
-- "Leon Sanchez". The city council page (bellgardens.org/government/city-council, read 2026-09-22) lists
-- "Councilwoman Dr. Francis De Leon Sanchez" and no "Leon Sanchez". The "Francis De" row is the real one
-- (it carries the 200 campaign-finance source links); it is renamed. The fragment row's seat is Mayor Pro
-- Tem Isabel Guillén's, who was missing from the DB.
UPDATE essentials.politicians
   SET full_name = 'Francis De Leon Sanchez', first_name = 'Francis', last_name = 'De Leon Sanchez',
       alternate_names = ARRAY(SELECT DISTINCT unnest(coalesce(alternate_names, '{}'::text[]) || ARRAY['Francis De', 'Dr. Francis De Leon Sanchez']::text[]))
 WHERE id = 'e086df00-1e48-4882-9594-82f4e9ee273c' AND full_name = 'Francis De';

DELETE FROM essentials.office_terms
 WHERE politician_id = 'f56a4c3b-82a1-4879-8a99-6ff6b5fdf5bf' AND office_id = 'e5adc4ea-c977-4f02-809e-fddda6d4914e' AND term_start IS NULL AND term_end IS NULL;

-- The fragment row also carries a copy of her headshot (same photo_origin_url, the city page for Francis De
-- Leon Sanchez) and the generic city-website contact -- duplicates of what the renamed row already has.
DELETE FROM essentials.politician_images WHERE politician_id = 'f56a4c3b-82a1-4879-8a99-6ff6b5fdf5bf' AND url LIKE '%/la_county/2026-audit/f56a4c3b-82a1-4879-8a99-6ff6b5fdf5bf.jpg';
DELETE FROM essentials.politician_contacts WHERE politician_id = 'f56a4c3b-82a1-4879-8a99-6ff6b5fdf5bf' AND contact_type = 'city_website'
   AND coalesce(email, '') = '' AND coalesce(phone, '') = '' AND coalesce(fax, '') = '';

DO $$
DECLARE r record; n bigint; n_refs bigint := 0; hits text := '';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = 'f56a4c3b-82a1-4879-8a99-6ff6b5fdf5bf') THEN RETURN; END IF;
  FOR r IN SELECT c.table_schema, c.table_name, c.column_name FROM information_schema.columns c
             JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name
            WHERE t.table_type = 'BASE TABLE' AND c.data_type = 'uuid'
              AND c.column_name IN ('politician_id', 'essentials_politician_id', 'essentials_id')
              AND c.table_schema NOT IN ('pg_catalog', 'information_schema')
  LOOP
    EXECUTE format('SELECT count(*) FROM %I.%I WHERE %I = %L', r.table_schema, r.table_name, r.column_name, 'f56a4c3b-82a1-4879-8a99-6ff6b5fdf5bf') INTO n;
    IF n > 0 THEN n_refs := n_refs + n; hits := hits || r.table_schema || '.' || r.table_name || '.' || r.column_name || '=' || n || ' '; END IF;
  END LOOP;
  IF n_refs <> 0 THEN RAISE EXCEPTION 'aborting: the Leon Sanchez fragment row is still referenced: %', hits; END IF;
  DELETE FROM essentials.politicians WHERE id = 'f56a4c3b-82a1-4879-8a99-6ff6b5fdf5bf' AND full_name = 'Leon Sanchez';
END $$;

-- ─── R2. Politician rows for the missing members (party never stored) ─────────────────────
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, is_active, is_incumbent, is_vacant,
                                    is_appointed, data_source, alternate_names)
SELECT v.id, v.first_name, v.last_name, v.full_name, NULL, true, true, false, false, v.url, v.alt
  FROM (VALUES
    ('568865fe-c1f8-4a7d-8efc-625e61bd21a4'::uuid, 'Marianne', 'Riggins', 'Marianne Riggins', 'https://www.malibucity.org/207/City-Council', '{}'::text[]),
    ('66b6eead-a9e1-42e7-8759-feef3fd39181'::uuid, 'Pat', 'Kearney', 'Pat Kearney', 'https://www.lawndale.ca.gov/government/city_council/city_council_contact_information', '{}'::text[]),
    ('f952eaca-052a-4395-b98e-b6968a13286c'::uuid, 'Sandra', 'Armenta', 'Sandra Armenta', 'https://rosemeadca.gov/city_hall/city_council/index.php', '{}'::text[]),
    ('fc470102-b27b-41f7-896a-ff516e01a234'::uuid, 'John', 'Wu', 'John Wu', 'https://www.sangabrielcity.com/87/City-Council', '{}'::text[]),
    ('54354e2b-7ac9-47f6-ad3f-df4ede0f0107'::uuid, 'Tamala', 'Kelly', 'Tamala Kelly', 'https://www.monroviaca.gov/your-government/city-council/meet-the-city-council', ARRAY['Tamala P. Kelly', 'Dr. Tamala Kelly']::text[]),
    ('8e393d1f-6b87-4db3-b4df-638e16806809'::uuid, 'Gustavo', 'Camacho', 'Gustavo V. Camacho', 'https://www.pico-rivera.org/our-city/city-council/', '{}'::text[]),
    ('566324a4-cbd9-4566-9cf2-4544eb645c4c'::uuid, 'Isabel', 'Guillén', 'Isabel Guillén', 'https://www.bellgardens.org/government/city-council', ARRAY['Isabel Guillen']::text[])
  ) AS v(id, first_name, last_name, full_name, url, alt)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

-- ─── R3. The missing seat: clone the city's lowest-id council office (Bell Gardens reuses the fragment's seat)
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
                                normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
                                faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT v.oid, t.chamber_id, t.district_id, t.title, t.representing_state, t.representing_city, t.description, t.seats,
       t.normalized_position_name, t.partisan_type, t.salary, t.is_appointed_position, false, NULL,
       t.faces_retention_vote, t.role_canonical, t.voting_powers, t.representation_note
  FROM (VALUES
    ('4e2a7a98-23e0-4977-b782-d185f560fe99'::uuid, '0645246'),
    ('0bc4b61f-6b5b-40cb-b20f-a03173186787'::uuid, '0640886'),
    ('bc77e649-f070-4e67-83ed-750f31983678'::uuid, '0662896'),
    ('766b44ec-9a13-45e9-ae2b-e99fe96fe475'::uuid, '0667042'),
    ('030adc17-ec8a-46c6-beda-26ed8663ad54'::uuid, '0648648'),
    ('20b2a73b-bf98-415b-ab13-8c0139bad946'::uuid, '0656924')
  ) AS v(oid, place)
  CROSS JOIN LATERAL (SELECT o.* FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                       WHERE d.geo_id = v.place AND d.district_type = 'LOCAL' ORDER BY o.id LIMIT 1) t
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices x WHERE x.id = v.oid);

-- ─── R4. Seat them ─────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, v.ts, v.prec, v.how, v.src
  FROM (VALUES
    ('4e2a7a98-23e0-4977-b782-d185f560fe99'::uuid, '568865fe-c1f8-4a7d-8efc-625e61bd21a4'::uuid, '2022-11-01'::date, 'month', 'elected', 'CA_0163: seated per https://www.malibucity.org/207/City-Council (read 2026-09-22) -- city council page: "Marianne Riggins ... Term: November 2022 - November 2026". The 2025 CA Roster import omitted this member.'),
    ('0bc4b61f-6b5b-40cb-b20f-a03173186787'::uuid, '66b6eead-a9e1-42e7-8759-feef3fd39181'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0163: seated per https://www.lawndale.ca.gov/government/city_council/city_council_contact_information (read 2026-09-22) -- city council contact page lists "Pat Kearney" as a Councilmember; start not researched. The 2025 CA Roster import omitted this member.'),
    ('bc77e649-f070-4e67-83ed-750f31983678'::uuid, 'f952eaca-052a-4395-b98e-b6968a13286c'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0163: seated per https://rosemeadca.gov/city_hall/city_council/index.php (read 2026-09-22) -- city council page: "Sandra Armenta - Mayor" (council-chosen mayor); start not researched. The 2025 CA Roster import omitted this member.'),
    ('766b44ec-9a13-45e9-ae2b-e99fe96fe475'::uuid, 'fc470102-b27b-41f7-896a-ff516e01a234'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0163: seated per https://www.sangabrielcity.com/87/City-Council (read 2026-09-22) -- city council page lists "John Wu, Councilmember"; start not researched. The 2025 CA Roster import omitted this member.'),
    ('030adc17-ec8a-46c6-beda-26ed8663ad54'::uuid, '54354e2b-7ac9-47f6-ad3f-df4ede0f0107'::uuid, '2022-01-01'::date, 'year', 'elected', 'CA_0163: seated per https://www.monroviaca.gov/your-government/city-council/meet-the-city-council (read 2026-09-22) -- city council page: "Dr. Tamala Kelly was elected to the Monrovia City Council in 2022". The 2025 CA Roster import omitted this member.'),
    ('20b2a73b-bf98-415b-ab13-8c0139bad946'::uuid, '8e393d1f-6b87-4db3-b4df-638e16806809'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0163: seated per https://www.pico-rivera.org/our-city/city-council/ (read 2026-09-22) -- city council page: "Councilmember Gustavo V. Camacho"; start not researched. The 2025 CA Roster import omitted this member.'),
    ('e5adc4ea-c977-4f02-809e-fddda6d4914e'::uuid, '566324a4-cbd9-4566-9cf2-4544eb645c4c'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0163: seated per https://www.bellgardens.org/government/city-council (read 2026-09-22) -- city council page: "Mayor Pro Tem Isabel Guillén"; start not researched. The 2025 CA Roster import omitted this member.')
  ) AS v(oid, pid, ts, prec, how, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid AND t.politician_id = v.pid);

-- ─── 0. Pre-flight: every binding target exists ───────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (VALUES
    ('0645246', 'LOCAL', NULL, 'Malibu City Council'),
    ('0640886', 'LOCAL', NULL, 'Lawndale City Council'),
    ('0662896', 'LOCAL', NULL, 'Rosemead City Council'),
    ('0667042', 'LOCAL', NULL, 'San Gabriel City Council'),
    ('0648648', 'LOCAL', NULL, 'Monrovia City Council'),
    ('0656924', 'LOCAL', NULL, 'Pico Rivera City Council'),
    ('0604996', 'LOCAL', NULL, 'Bell Gardens City Council')
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
    ('0645246', 'LOCAL', NULL, 'Malibu City Council', 2),
    ('0640886', 'LOCAL', NULL, 'Lawndale City Council', 2),
    ('0662896', 'LOCAL', NULL, 'Rosemead City Council', 3),
    ('0667042', 'LOCAL', NULL, 'San Gabriel City Council', 3),
    ('0648648', 'LOCAL', NULL, 'Monrovia City Council', 2),
    ('0656924', 'LOCAL', NULL, 'Pico Rivera City Council', 2),
    ('0604996', 'LOCAL', NULL, 'Bell Gardens City Council', 3)
          ) AS v(place, dtype, otitle, pos, seats)) t
 WHERE t.office_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = t.pos);

-- ─── 2. Candidates ────────────────────────────────────────────────────────────────────
INSERT INTO essentials.race_candidates
       (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, occupational_designation, source)
SELECT r.id, v.pid, v.full_name, v.first_name, v.last_name, v.inc, 'active', v.desig, v.src
  FROM (VALUES
    ('Malibu City Council', 'A. Sam Dibaei', 'A.', 'Dibaei', NULL::uuid, false, NULL, 'City of Malibu City Clerk, Election Information: November 3, 2026 Election Candidates ("The following candidates qualified for inclusion on the ballot") (malibucity.org/190/Election-Information). Retrieved 2026-09-22.'),
    ('Malibu City Council', 'Danny Smith', 'Danny', 'Smith', NULL::uuid, false, NULL, 'City of Malibu City Clerk, Election Information: November 3, 2026 Election Candidates ("The following candidates qualified for inclusion on the ballot") (malibucity.org/190/Election-Information). Retrieved 2026-09-22.'),
    ('Malibu City Council', 'Doug Stewart', 'Doug', 'Stewart', '28413e59-5cf6-416f-89c2-85a13ffdccc5'::uuid, true, NULL, 'City of Malibu City Clerk, Election Information: November 3, 2026 Election Candidates ("The following candidates qualified for inclusion on the ballot") (malibucity.org/190/Election-Information). Retrieved 2026-09-22.'),
    ('Malibu City Council', 'Marianne Riggins', 'Marianne', 'Riggins', '568865fe-c1f8-4a7d-8efc-625e61bd21a4'::uuid, true, NULL, 'City of Malibu City Clerk, Election Information: November 3, 2026 Election Candidates ("The following candidates qualified for inclusion on the ballot") (malibucity.org/190/Election-Information). Retrieved 2026-09-22.'),
    ('Lawndale City Council', 'Bernadette Lourdes Suarez', 'Bernadette', 'Suarez', '3377a5d0-7e65-4e38-b5a1-d359c0a7f2ab'::uuid, true, 'Lawndale City Councilmember', 'City of Lawndale, Certified List of Qualified Candidates, approved 8/11/2026 (lawndale.ca.gov/.../2026 Election/Lawndale Certified List of Candidates Form_Online signed.pdf). Retrieved 2026-09-22.'),
    ('Lawndale City Council', 'Pat Kearney', 'Pat', 'Kearney', '66b6eead-a9e1-42e7-8759-feef3fd39181'::uuid, true, 'City Council Member', 'City of Lawndale, Certified List of Qualified Candidates, approved 8/11/2026 (lawndale.ca.gov/.../2026 Election/Lawndale Certified List of Candidates Form_Online signed.pdf). Retrieved 2026-09-22.'),
    ('Rosemead City Council', 'Sandra Armenta', 'Sandra', 'Armenta', 'f952eaca-052a-4395-b98e-b6968a13286c'::uuid, true, 'Mayor of Rosemead/District Representative', 'City of Rosemead City Clerk, Official Candidates for Rosemead General Municipal Election, November 3, 2026, dated 8/18/2026 (rosemeadca.gov/Documents/Departments/City Clerk/Elections/11-03-26 General Municipal Election/). Retrieved 2026-09-22.'),
    ('Rosemead City Council', 'Diana Lam', 'Diana', 'Lam', NULL::uuid, false, 'Career Education Manager', 'City of Rosemead City Clerk, Official Candidates for Rosemead General Municipal Election, November 3, 2026, dated 8/18/2026 (rosemeadca.gov/Documents/Departments/City Clerk/Elections/11-03-26 General Municipal Election/). Retrieved 2026-09-22.'),
    ('Rosemead City Council', 'Steven Ly', 'Steven', 'Ly', '7fe63cdf-13a0-4150-a378-7ec6d4e0def1'::uuid, true, 'Councilmember, City of Rosemead', 'City of Rosemead City Clerk, Official Candidates for Rosemead General Municipal Election, November 3, 2026, dated 8/18/2026 (rosemeadca.gov/Documents/Departments/City Clerk/Elections/11-03-26 General Municipal Election/). Retrieved 2026-09-22.'),
    ('Rosemead City Council', 'John Tran', 'John', 'Tran', NULL::uuid, false, 'Business Owner/Rosemead Commissioner', 'City of Rosemead City Clerk, Official Candidates for Rosemead General Municipal Election, November 3, 2026, dated 8/18/2026 (rosemeadca.gov/Documents/Departments/City Clerk/Elections/11-03-26 General Municipal Election/). Retrieved 2026-09-22.'),
    ('San Gabriel City Council', 'Jordan Guzman', 'Jordan', 'Guzman', NULL::uuid, false, NULL, 'City of San Gabriel, November 3, 2026 General Municipal Election Candidate List with Qualified column, 9/9/2026 (sangabrielcity.com/DocumentCenter/View/25195). Retrieved 2026-09-22.'),
    ('San Gabriel City Council', 'Denise Menchaca', 'Denise', 'Menchaca', 'bfa60e39-6a47-4d12-a26b-4742f6b139ab'::uuid, true, NULL, 'City of San Gabriel, November 3, 2026 General Municipal Election Candidate List with Qualified column, 9/9/2026 (sangabrielcity.com/DocumentCenter/View/25195). Retrieved 2026-09-22.'),
    ('San Gabriel City Council', 'Wendy Wang', 'Wendy', 'Wang', NULL::uuid, false, NULL, 'City of San Gabriel, November 3, 2026 General Municipal Election Candidate List with Qualified column, 9/9/2026 (sangabrielcity.com/DocumentCenter/View/25195). Retrieved 2026-09-22.'),
    ('San Gabriel City Council', 'John Wu', 'John', 'Wu', 'fc470102-b27b-41f7-896a-ff516e01a234'::uuid, true, NULL, 'City of San Gabriel, November 3, 2026 General Municipal Election Candidate List with Qualified column, 9/9/2026 (sangabrielcity.com/DocumentCenter/View/25195). Retrieved 2026-09-22.'),
    ('San Gabriel City Council', 'Eric L. Chan', 'Eric', 'Chan', '28ec5db0-6daa-4f01-9825-2193ba21e349'::uuid, true, NULL, 'City of San Gabriel, November 3, 2026 General Municipal Election Candidate List with Qualified column, 9/9/2026 (sangabrielcity.com/DocumentCenter/View/25195). Retrieved 2026-09-22.'),
    ('Monrovia City Council', 'Tamala P. Kelly', 'Tamala', 'Kelly', '54354e2b-7ac9-47f6-ad3f-df4ede0f0107'::uuid, true, NULL, 'City of Monrovia City Clerk, November 3, 2026 General Municipal Election Qualified Candidates, 8/7/2026 (monroviaca.gov/home/showpublisheddocument/41152/639217168700800000). Retrieved 2026-09-22.'),
    ('Monrovia City Council', 'Larry J. Spicer', 'Larry', 'Spicer', 'fda02d25-60dd-44b6-9e9b-67108ec03e9e'::uuid, true, NULL, 'City of Monrovia City Clerk, November 3, 2026 General Municipal Election Qualified Candidates, 8/7/2026 (monroviaca.gov/home/showpublisheddocument/41152/639217168700800000). Retrieved 2026-09-22.'),
    ('Monrovia City Council', 'Jesus Rojas', 'Jesus', 'Rojas', NULL::uuid, false, NULL, 'City of Monrovia City Clerk, November 3, 2026 General Municipal Election Qualified Candidates, 8/7/2026 (monroviaca.gov/home/showpublisheddocument/41152/639217168700800000). Retrieved 2026-09-22.'),
    ('Pico Rivera City Council', 'Gustavo V. Camacho', 'Gustavo', 'Camacho', '8e393d1f-6b87-4db3-b4df-638e16806809'::uuid, true, NULL, 'City of Pico Rivera City Clerk, posting notice "Who is running for Pico Rivera City Council?" with Qualified for the Ballot column, 8/11/2026 (pico-rivera.org/wp-content/uploads/8-10-26-Posting-Notice-Who-is-running-for-city-council.pdf). Retrieved 2026-09-22.'),
    ('Pico Rivera City Council', 'John R. Garcia', 'John', 'Garcia', '6940b872-1458-4612-85aa-0c6704b0bb62'::uuid, true, NULL, 'City of Pico Rivera City Clerk, posting notice "Who is running for Pico Rivera City Council?" with Qualified for the Ballot column, 8/11/2026 (pico-rivera.org/wp-content/uploads/8-10-26-Posting-Notice-Who-is-running-for-city-council.pdf). Retrieved 2026-09-22.'),
    ('Pico Rivera City Council', 'Genaro Moreno', 'Genaro', 'Moreno', NULL::uuid, false, NULL, 'City of Pico Rivera City Clerk, posting notice "Who is running for Pico Rivera City Council?" with Qualified for the Ballot column, 8/11/2026 (pico-rivera.org/wp-content/uploads/8-10-26-Posting-Notice-Who-is-running-for-city-council.pdf). Retrieved 2026-09-22.'),
    ('Bell Gardens City Council', 'Samuel Perez', 'Samuel', 'Perez', NULL::uuid, false, NULL, 'City of Bell Gardens City Clerk, Nominees for Public Office (signed by City Clerk Daisy Gomez) and Ballot Order of Qualified Candidates updated 9/8/2026 (bellgardens.org/home/showpublisheddocument/11670 and /11770). Retrieved 2026-09-22.'),
    ('Bell Gardens City Council', 'Miguel De La Rosa', 'Miguel', 'De La Rosa', 'f3a0a939-0bd3-4cc5-b613-7ef379372694'::uuid, true, NULL, 'City of Bell Gardens City Clerk, Nominees for Public Office (signed by City Clerk Daisy Gomez) and Ballot Order of Qualified Candidates updated 9/8/2026 (bellgardens.org/home/showpublisheddocument/11670 and /11770). Retrieved 2026-09-22.'),
    ('Bell Gardens City Council', 'Francis De Leon Sanchez', 'Francis', 'De Leon Sanchez', 'e086df00-1e48-4882-9594-82f4e9ee273c'::uuid, true, NULL, 'City of Bell Gardens City Clerk, Nominees for Public Office (signed by City Clerk Daisy Gomez) and Ballot Order of Qualified Candidates updated 9/8/2026 (bellgardens.org/home/showpublisheddocument/11670 and /11770). Retrieved 2026-09-22.'),
    ('Bell Gardens City Council', 'Marco Barcena', 'Marco', 'Barcena', '50f4b2ea-42b6-42ea-8e0f-d7e749cb9b50'::uuid, true, NULL, 'City of Bell Gardens City Clerk, Nominees for Public Office (signed by City Clerk Daisy Gomez) and Ballot Order of Qualified Candidates updated 9/8/2026 (bellgardens.org/home/showpublisheddocument/11670 and /11770). Retrieved 2026-09-22.'),
    ('Bell Gardens City Council', 'Jorge O. Verdin', 'Jorge', 'Verdin', NULL::uuid, false, NULL, 'City of Bell Gardens City Clerk, Nominees for Public Office (signed by City Clerk Daisy Gomez) and Ballot Order of Qualified Candidates updated 9/8/2026 (bellgardens.org/home/showpublisheddocument/11670 and /11770). Retrieved 2026-09-22.')
  ) AS v(pos, full_name, first_name, last_name, pid, inc, desig, src)
  JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.pos
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name));

-- ─── 3. Antipartisan: clear the stored party on every linked candidate row ──────────
UPDATE essentials.politicians SET party = NULL
 WHERE party IS NOT NULL AND id IN ('28413e59-5cf6-416f-89c2-85a13ffdccc5', '28ec5db0-6daa-4f01-9825-2193ba21e349', '3377a5d0-7e65-4e38-b5a1-d359c0a7f2ab', '50f4b2ea-42b6-42ea-8e0f-d7e749cb9b50', '54354e2b-7ac9-47f6-ad3f-df4ede0f0107', '568865fe-c1f8-4a7d-8efc-625e61bd21a4', '66b6eead-a9e1-42e7-8759-feef3fd39181', '6940b872-1458-4612-85aa-0c6704b0bb62', '7fe63cdf-13a0-4150-a378-7ec6d4e0def1', '8e393d1f-6b87-4db3-b4df-638e16806809', 'bfa60e39-6a47-4d12-a26b-4742f6b139ab', 'e086df00-1e48-4882-9594-82f4e9ee273c', 'f3a0a939-0bd3-4cc5-b613-7ef379372694', 'f952eaca-052a-4395-b98e-b6968a13286c', 'fc470102-b27b-41f7-896a-ff516e01a234', 'fda02d25-60dd-44b6-9e9b-67108ec03e9e');

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  pos text[] := ARRAY['Malibu City Council', 'Lawndale City Council', 'Rosemead City Council', 'San Gabriel City Council', 'Monrovia City Council', 'Pico Rivera City Council', 'Bell Gardens City Council'];
  n_races int; n_cands int; n_null int; n_party int; n_badcount int; n_inc int; n_badinc int; n_extralink int; n_linked int;
  n_overinc int; n_unreach int; n_pparty int; n_newheld int; n_size int; n_frag int; n_keep int;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE r.office_id IS NULL), count(*) FILTER (WHERE r.primary_party IS NOT NULL)
    INTO n_races, n_null, n_party FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  SELECT count(*) INTO n_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  -- each race carries exactly the clerk's field, on the expected seat count
  SELECT count(*) INTO n_badcount FROM (VALUES
      ('Malibu City Council', 2, 4, 2),
      ('Lawndale City Council', 2, 2, 2),
      ('Rosemead City Council', 3, 4, 2),
      ('San Gabriel City Council', 3, 5, 3),
      ('Monrovia City Council', 2, 3, 2),
      ('Pico Rivera City Council', 2, 3, 2),
      ('Bell Gardens City Council', 3, 5, 3)
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
  IF n_races <> 7 THEN RAISE EXCEPTION 'expected 7 races, got %', n_races; END IF;
  IF n_cands <> 26 THEN RAISE EXCEPTION 'expected 26 candidates, got %', n_cands; END IF;
  IF n_null <> 0 OR n_party <> 0 THEN RAISE EXCEPTION 'office-less (%) or partisan (%) race', n_null, n_party; END IF;
  IF n_badcount <> 0 THEN RAISE EXCEPTION '% race(s) whose seats / candidates / incumbents differ from the clerk list', n_badcount; END IF;
  IF n_inc <> 16 THEN RAISE EXCEPTION 'expected 16 incumbents, got %', n_inc; END IF;
  IF n_badinc <> 0 THEN RAISE EXCEPTION '% incumbent(s) left unlinked', n_badinc; END IF;
  IF n_extralink <> 0 THEN RAISE EXCEPTION '% linked candidate(s) are not a current holder in their city', n_extralink; END IF;
  IF n_linked <> 16 THEN RAISE EXCEPTION 'expected 16 linked candidates, got %', n_linked; END IF;
  IF n_overinc <> 0 THEN RAISE EXCEPTION '% race(s) with more incumbents than seats', n_overinc; END IF;
  IF n_unreach <> 0 THEN RAISE EXCEPTION '% race(s) not reached from inside their own city', n_unreach; END IF;
  IF n_pparty <> 0 THEN RAISE EXCEPTION '% linked candidate row(s) still carry a party', n_pparty; END IF;
  -- roster fix: every missing member now holds exactly the seat created (or reused) for them
  SELECT count(*) INTO n_newheld FROM (VALUES
      ('4e2a7a98-23e0-4977-b782-d185f560fe99'::uuid, '568865fe-c1f8-4a7d-8efc-625e61bd21a4'::uuid),
      ('0bc4b61f-6b5b-40cb-b20f-a03173186787'::uuid, '66b6eead-a9e1-42e7-8759-feef3fd39181'::uuid),
      ('bc77e649-f070-4e67-83ed-750f31983678'::uuid, 'f952eaca-052a-4395-b98e-b6968a13286c'::uuid),
      ('766b44ec-9a13-45e9-ae2b-e99fe96fe475'::uuid, 'fc470102-b27b-41f7-896a-ff516e01a234'::uuid),
      ('030adc17-ec8a-46c6-beda-26ed8663ad54'::uuid, '54354e2b-7ac9-47f6-ad3f-df4ede0f0107'::uuid),
      ('20b2a73b-bf98-415b-ab13-8c0139bad946'::uuid, '8e393d1f-6b87-4db3-b4df-638e16806809'::uuid),
      ('e5adc4ea-c977-4f02-809e-fddda6d4914e'::uuid, '566324a4-cbd9-4566-9cf2-4544eb645c4c'::uuid)
    ) AS v(oid, pid) JOIN essentials.office_current_holder och ON och.office_id = v.oid AND och.politician_id = v.pid;
  -- and each of the seven councils now has exactly its five sitting members (council + Mayor offices on the place)
  SELECT count(*) INTO n_size FROM (
    SELECT d.geo_id FROM essentials.districts d JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id IN ('0645246', '0640886', '0662896', '0667042', '0648648', '0656924', '0604996') AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
     GROUP BY d.geo_id HAVING count(DISTINCT och.politician_id) = 5) x;
  SELECT count(*) INTO n_frag FROM essentials.politicians WHERE id = 'f56a4c3b-82a1-4879-8a99-6ff6b5fdf5bf';
  SELECT count(*) INTO n_keep FROM essentials.politicians p WHERE p.id = 'e086df00-1e48-4882-9594-82f4e9ee273c' AND p.full_name = 'Francis De Leon Sanchez'
     AND (SELECT count(*) FROM transparent_motivations.politician_sources ps WHERE ps.essentials_politician_id = p.id) = 200;
  IF n_newheld <> 7 THEN RAISE EXCEPTION 'roster: % of 7 missing members seated', n_newheld; END IF;
  IF n_size <> 7 THEN RAISE EXCEPTION 'roster: only % of 7 councils have exactly 5 sitting members', n_size; END IF;
  IF n_frag <> 0 OR n_keep <> 1 THEN RAISE EXCEPTION 'Bell Gardens: fragment row present (%) or renamed row wrong (%)', n_frag, n_keep; END IF;
  RAISE NOTICE 'CA_0163 applied: % races, % candidates, % incumbents linked', n_races, n_cands, n_inc;
END $$;

COMMIT;
