-- CA_0238_orange_county_supervisors.sql
--
-- Orange County (California) Board of Supervisors: all five seats, on the county's own district boundaries,
-- under the one Orange County government.
-- Run scripts/load-orange-county-supervisor-boundaries.ts FIRST (five X-OC-SUP boundaries); this file refuses
-- to run without them.
--
-- WHY (measured 2026-09-24)
-- -------------------------
--   1. The board had 2 of 5 seats: District 1 Janet Nguyen and District 4 Doug Chaffee. Districts 2, 3 and 5
--      did not exist.
--   2. Both seats sat on OCD geo_ids ('ocd-division/country:us/state:ca/county:orange/council_district:N') with
--      no geofence, so no address reached either (reachability baseline UNREACHABLE ca|COUNTY 2).
--   3. There were TWO "Orange County, California, US" government rows. The board's chamber hung on one with no
--      geo_id (8343cd8c); the seven countywide officers hang on the 06059 one (870b1c33). Nothing but that
--      chamber references 8343cd8c (the only FK to governments is districts.government_id: 0 rows; chambers:
--      1 row, the board).
--
-- SOURCES (read 2026-09-24)
-- -------------------------
--   Roster   board.oc.gov: D1 Janet Nguyen, D2 Vicente Sarmiento, D3 Donald P. Wagner, D4 Doug Chaffee (Chairman),
--            D5 Katrina Foley (Vice Chair). The ocgis.com district layer's NAME field carries the same five.
--   Terms    Wikipedia, "2022 Orange County Board of Supervisors election": Districts 2, 4, 5 on the ballot;
--            Sarmiento won D2, Foley won D5. "2024 Orange County Board of Supervisors election": Districts 1
--            and 3 on the ballot, Republicans won both; Wagner is the sitting D3 supervisor. Supervisorial terms
--            begin the first Monday after January 1 after the election (Wikipedia, "Orange County Board of
--            Supervisors"). Exact swearing-in days disagree between sources, so every start is 'year'.
--   Wagner   The existing politician c09bed40 "Donald P. Wagner" (source race_candidates, the 2026 CA Secretary
--            of State race, advanced) is the same person: "Orange County Supervisor Don Wagner Launches Campaign
--            for California Secretary of State" (wagnerforcalifornia.com). Reused, not duplicated.
--
-- DATES — what each start asserts
-- --------------------------------
--   2023-01-01 'year'  Sarmiento (D2), Foley (D5): won the 2022 election for these districts. Foley served
--                      District 2 from 2021 (special election) under the pre-2021 map; that seat is not modelled.
--   2025-01-01 'year'  Wagner (D3): won the 2024 election. His D3 service from 2019 (special) was on the old map.
--   Nguyen (D1) and Chaffee (D4) keep their 2026-07 backfill terms (start unknown) — not changed here.
--
-- SHAPE
-- -----
--   The board chamber moves to the 06059 government; the empty duplicate government row is deleted
--   (pre-image below). D2/D3/D5 get a district (copied from D1, on its X-OC-SUP boundary) and an office
--   (copied from D1's, title 'Supervisor'). All five districts carry mtfcc 'X-OC-SUP' — electionService matches
--   race geography on gbo.mtfcc = d.mtfcc, so the district must name its boundary's code. government_bodies
--   gets the three missing (state, geo_id, body_key) rows, and all five get the board's URL.
--
-- PRE-IMAGE of the deleted row: essentials.governments (id 8343cd8c-1f33-4956-a932-5eda7c0efbbd,
--   name 'Orange County, California, US', type 'County', state 'CA', city NULL, geo_id NULL).
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: NOT APPLIED.
--
-- ROLLBACK: delete the office_terms rows whose source starts 'CA_0238', the three offices, three districts, the
--   three government_bodies rows and two politicians by the ids below; set website_url back to '' on the D1/D4
--   government_bodies rows; set districts.mtfcc back to NULL on D1/D4; set Wagner's is_incumbent back to false;
--   re-insert the pre-image government row and move chamber 9e68f81c back to it.
-- IDEMPOTENT: fixed ids with NOT EXISTS guards; seat_officeholder is idempotent; a re-run changes 0 rows.

BEGIN;

CREATE TEMP TABLE ca0238_seat ON COMMIT DROP AS
SELECT * FROM (VALUES
  (2, 'e054a0e6-e4db-469d-b79a-c13b51de9b56'::uuid, 'b8e92fa2-4d5e-432a-b547-0f3c6bcf94cc'::uuid, '840c78ce-1a3e-4455-b987-9024b8af739e'::uuid, DATE '2023-01-01',
      'CA_0238: Orange County Supervisor District 2; Vicente Sarmiento won the 2022 election (Wikipedia, 2022 Orange County Board of Supervisors election); terms begin the first Monday after January 1; roster board.oc.gov (read 2026-09-24)'),
  (3, '9a71a87f-1e08-4a64-b378-10738a15e2e4'::uuid, '417eab95-63d3-4c6e-8528-70b43dce1f8f'::uuid, 'c09bed40-e329-45a5-a5f1-5293e038cc66'::uuid, DATE '2025-01-01',
      'CA_0238: Orange County Supervisor District 3; District 3 was on the 2024 ballot (Wikipedia, 2024 Orange County Board of Supervisors election) and Donald P. Wagner holds it; terms begin the first Monday after January 1; earlier D3 service from 2019 was on the pre-2021 map; roster board.oc.gov (read 2026-09-24)'),
  (5, 'd017979d-6c39-456a-b75f-d154770a6ed8'::uuid, '008f88fb-5835-46b7-816c-9e446767b0e2'::uuid, '928e3dc2-a725-4fa9-bca4-aa08574dc5ff'::uuid, DATE '2023-01-01',
      'CA_0238: Orange County Supervisor District 5; Katrina Foley won the 2022 election (Wikipedia, 2022 Orange County Board of Supervisors election); terms begin the first Monday after January 1; her 2021-2022 District 2 service was on the pre-2021 map; roster board.oc.gov (read 2026-09-24)')
) AS v(n, district_id, office_id, politician_id, term_start, source);

-- ---------------------------------------------------------------------------
-- 0. Pre-flight.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; n2 int;
BEGIN
  -- 0a. The five boundaries are loaded.
  SELECT count(*) INTO n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X-OC-SUP' AND geo_id IN (SELECT 'ocd-division/country:us/state:ca/county:orange/council_district:' || g FROM generate_series(1, 5) g);
  IF n <> 5 THEN RAISE EXCEPTION 'X-OC-SUP boundaries: % of 5 — run the loader first', n; END IF;

  -- 0b. The board chamber is on the duplicate government (first run) or the 06059 one (re-run); the 06059 row is the one expected.
  SELECT count(*) INTO n FROM essentials.chambers WHERE id = '9e68f81c-065a-4665-9687-b2dcd903fae3'
     AND name_formal = 'Orange County Board of Supervisors'
     AND government_id IN ('8343cd8c-1f33-4956-a932-5eda7c0efbbd', '870b1c33-ada6-4963-a073-6b183e54790f');
  SELECT count(*) INTO n2 FROM essentials.governments WHERE id = '870b1c33-ada6-4963-a073-6b183e54790f' AND geo_id = '06059' AND state = 'CA';
  IF n <> 1 OR n2 <> 1 THEN RAISE EXCEPTION 'board chamber as recorded: %, 06059 government: %', n, n2; END IF;

  -- 0c. Nothing but the board chamber references the duplicate government.
  SELECT (SELECT count(*) FROM essentials.chambers WHERE government_id = '8343cd8c-1f33-4956-a932-5eda7c0efbbd' AND id <> '9e68f81c-065a-4665-9687-b2dcd903fae3')
       + (SELECT count(*) FROM essentials.districts WHERE government_id = '8343cd8c-1f33-4956-a932-5eda7c0efbbd') INTO n;
  IF n > 0 THEN RAISE EXCEPTION '% other row(s) reference the duplicate government', n; END IF;

  -- 0d. D1 / D4 are the template seats the header describes, held by Nguyen / Chaffee.
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE (o.id, d.id, och.politician_id) IN (
     ('0dc6a5d3-b72f-4ad0-b739-b89ca4014472'::uuid, '5393320a-27d0-4f51-846d-354717aabf5b'::uuid, '347da039-8904-42b7-b4c8-76a8cf8891e9'::uuid),
     ('76d1633d-63ec-4363-8eaf-2f85ef32ad9d', 'da597252-46be-452b-b496-bd6e63f9a91e', '4197ba7e-fcae-4111-bd81-615bb1527677'))
     AND o.chamber_id = '9e68f81c-065a-4665-9687-b2dcd903fae3' AND d.district_type = 'COUNTY';
  IF n <> 2 THEN RAISE EXCEPTION 'D1/D4 template seats: % of 2 as recorded', n; END IF;

  -- 0e. No other district already carries a D2/D3/D5 geo_id; Wagner is the recorded row; no Sarmiento / Foley person row exists.
  SELECT count(*) INTO n FROM essentials.districts
   WHERE geo_id IN (SELECT 'ocd-division/country:us/state:ca/county:orange/council_district:' || s.n FROM ca0238_seat s)
     AND id NOT IN (SELECT district_id FROM ca0238_seat);
  IF n > 0 THEN RAISE EXCEPTION '% other district(s) already carry a D2/D3/D5 geo_id', n; END IF;
  SELECT count(*) INTO n FROM essentials.politicians WHERE id = 'c09bed40-e329-45a5-a5f1-5293e038cc66' AND full_name = 'Donald P. Wagner';
  IF n <> 1 THEN RAISE EXCEPTION 'Wagner politician row not as recorded'; END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE lower(full_name) IN ('vicente sarmiento', 'katrina foley')
     AND id NOT IN ('840c78ce-1a3e-4455-b987-9024b8af739e', '928e3dc2-a725-4fa9-bca4-aa08574dc5ff');
  IF n > 0 THEN RAISE EXCEPTION '% Sarmiento / Foley row(s) already exist under another id', n; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. One government: move the board, delete the empty duplicate.
-- ---------------------------------------------------------------------------
UPDATE essentials.chambers SET government_id = '870b1c33-ada6-4963-a073-6b183e54790f'
 WHERE id = '9e68f81c-065a-4665-9687-b2dcd903fae3' AND government_id = '8343cd8c-1f33-4956-a932-5eda7c0efbbd';

DELETE FROM essentials.governments g
 WHERE g.id = '8343cd8c-1f33-4956-a932-5eda7c0efbbd' AND g.geo_id IS NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.government_id = g.id);

-- ---------------------------------------------------------------------------
-- 2. People.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, is_active, is_incumbent, is_vacant,
                                    is_appointed, data_source, alternate_names, urls)
SELECT v.id, v.first_name, v.last_name, v.full_name, NULL, true, true, false, false,
       'https://board.oc.gov/ (read 2026-09-24)', '{}'::text[], v.urls
  FROM (VALUES
    ('840c78ce-1a3e-4455-b987-9024b8af739e'::uuid, 'Vicente', 'Sarmiento', 'Vicente Sarmiento', '{https://bos2.ocgov.com}'::text[]),
    ('928e3dc2-a725-4fa9-bca4-aa08574dc5ff'::uuid, 'Katrina', 'Foley', 'Katrina Foley', '{https://bos5.ocgov.com}'::text[])
  ) AS v(id, first_name, last_name, full_name, urls)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

-- Wagner now holds a seat (check:occupancy / the incumbents-only reads filter on is_incumbent).
UPDATE essentials.politicians SET is_incumbent = true
 WHERE id = 'c09bed40-e329-45a5-a5f1-5293e038cc66' AND is_incumbent = false;

-- ---------------------------------------------------------------------------
-- 3. Districts 2, 3, 5 (copied from District 1) and the boundary code on all five.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.districts (id, external_id, ocd_id, label, district_type, district_id, subtype, state, city, num_officials,
                                  valid_from, valid_to, last_update_date, mtfcc, geo_id, is_judicial, has_unknown_boundaries,
                                  retention, tiger_geoid, government_id, population, population_source_year, official_web_url,
                                  census_unit_id, representation_basis)
SELECT s.district_id, NULL, 'ocd-division/country:us/state:ca/county:orange/council_district:' || s.n, 'District ' || s.n,
       t.district_type, s.n::text, t.subtype, t.state, t.city, t.num_officials,
       t.valid_from, t.valid_to, t.last_update_date, 'X-OC-SUP', 'ocd-division/country:us/state:ca/county:orange/council_district:' || s.n,
       t.is_judicial, t.has_unknown_boundaries, t.retention, NULL, t.government_id, NULL, NULL, t.official_web_url, NULL, t.representation_basis
  FROM ca0238_seat s JOIN essentials.districts t ON t.id = '5393320a-27d0-4f51-846d-354717aabf5b'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = s.district_id);

UPDATE essentials.districts SET mtfcc = 'X-OC-SUP'
 WHERE id IN ('5393320a-27d0-4f51-846d-354717aabf5b', 'da597252-46be-452b-b496-bd6e63f9a91e') AND mtfcc IS DISTINCT FROM 'X-OC-SUP';

-- ---------------------------------------------------------------------------
-- 4. Offices 2, 3, 5 (copied from District 1's) and their terms.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
                                normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
                                faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT s.office_id, t.chamber_id, s.district_id, t.title, t.representing_state, t.representing_city, t.description, t.seats,
       t.normalized_position_name, t.partisan_type, t.salary, t.is_appointed_position, false, NULL,
       t.faces_retention_vote, t.role_canonical, t.voting_powers, t.representation_note
  FROM ca0238_seat s JOIN essentials.offices t ON t.id = '0dc6a5d3-b72f-4ad0-b739-b89ca4014472'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = s.office_id);

SELECT essentials.seat_officeholder(s.office_id, s.politician_id, s.term_start, s.source, 'elected', 'year')
  FROM ca0238_seat s ORDER BY s.n;

-- ---------------------------------------------------------------------------
-- 5. Body rows (heading + link) for all five districts.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.government_bodies (state, geo_id, body_key, display_name, website_url)
SELECT 'CA', 'ocd-division/country:us/state:ca/county:orange/council_district:' || s.n, 'Orange County Board of Supervisors',
       'Orange County Board of Supervisors', 'https://board.oc.gov/'
  FROM ca0238_seat s
ON CONFLICT (state, geo_id, body_key) DO NOTHING;

UPDATE essentials.government_bodies SET website_url = 'https://board.oc.gov/'
 WHERE state = 'CA' AND body_key = 'Orange County Board of Supervisors'
   AND geo_id LIKE 'ocd-division/country:us/state:ca/county:orange/council_district:_'
   AND website_url IS DISTINCT FROM 'https://board.oc.gov/';

-- ---------------------------------------------------------------------------
-- 6. Post-verify.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; names text;
BEGIN
  -- 6a. Five seats, all held, holders are the roster by district.
  SELECT count(*), string_agg(d.district_id || ':' || p.last_name, ',' ORDER BY d.district_id) INTO n, names
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.chamber_id = '9e68f81c-065a-4665-9687-b2dcd903fae3';
  IF n <> 5 OR names <> '1:Nguyen,2:Sarmiento,3:Wagner,4:Chaffee,5:Foley' THEN
    RAISE EXCEPTION 'board: % held seats, holders % (want 5, 1:Nguyen,2:Sarmiento,3:Wagner,4:Chaffee,5:Foley)', n, names;
  END IF;

  -- 6b. One Orange County government, carrying both chambers.
  SELECT count(*) INTO n FROM essentials.governments WHERE state = 'CA' AND name = 'Orange County, California, US';
  IF n <> 1 THEN RAISE EXCEPTION '% Orange County government rows (want 1)', n; END IF;
  SELECT count(*) INTO n FROM essentials.chambers WHERE government_id = '870b1c33-ada6-4963-a073-6b183e54790f'
     AND name_formal IN ('Orange County Board of Supervisors', 'Orange County Countywide Elected Officials');
  IF n <> 2 THEN RAISE EXCEPTION '06059 government carries % of the 2 chambers', n; END IF;

  -- 6c. A point in each boundary reaches its district, and only its district, through the address join.
  SELECT count(*) INTO n FROM essentials.geofence_boundaries gb0
   WHERE gb0.mtfcc = 'X-OC-SUP'
     AND (SELECT count(*) FROM essentials.geofence_boundaries gb
            JOIN essentials.districts d ON d.geo_id = gb.geo_id AND gb.mtfcc LIKE 'X%'
             AND gb.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d.district_type IN ('LOCAL','COUNTY')
            JOIN essentials.offices o ON o.district_id = d.id AND o.chamber_id = '9e68f81c-065a-4665-9687-b2dcd903fae3'
           WHERE ST_Covers(gb.geometry, ST_PointOnSurface(gb0.geometry))) = 1
     AND EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = gb0.geo_id AND d.mtfcc = 'X-OC-SUP');
  IF n <> 5 THEN RAISE EXCEPTION 'address round trip: % of 5', n; END IF;

  -- 6d. Body rows for all five.
  SELECT count(*) INTO n FROM essentials.government_bodies
   WHERE state = 'CA' AND body_key = 'Orange County Board of Supervisors' AND website_url = 'https://board.oc.gov/'
     AND geo_id LIKE 'ocd-division/country:us/state:ca/county:orange/council_district:_';
  IF n <> 5 THEN RAISE EXCEPTION 'government_bodies rows: % of 5', n; END IF;

  RAISE NOTICE 'OK: Orange County Board of Supervisors 5/5 on X-OC-SUP boundaries, under the one 06059 government';
END $$;

COMMIT;
