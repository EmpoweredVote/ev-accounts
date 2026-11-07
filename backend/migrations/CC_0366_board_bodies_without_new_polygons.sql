-- CC_0366 — the nine tier-3 board seats that need NO NEW POLYGON, and the four bodies they
--           sit in: 26 seats created and seated, 16 congressional polygons copied, 9 results.
--
-- 🔴🔴 TIER 3 SAID ALL 49 OF ITS SEATS NEEDED REAL SUB-STATE GEOMETRY. NINE DO NOT.
--   The inventory was built from Ballotpedia's office titles, and a title that reads
--   "District 3" or "Place 1" reads as districted. Two of these four bodies are not:
--     · GEORGIA'S PSC — "Though each commissioner must be a resident of the district he
--       represents for 12 months prior to election, commissioners are chosen in STATEWIDE
--       ELECTIONS and not by the citizens of their district." The district is a residency
--       rule on the candidate. Every Georgia voter votes in every PSC race.
--     · ALABAMA'S PSC — Place 1 and Place 2 are the last two seats filled under a THREE-MEMBER
--       AT-LARGE commission. HB475, the Power to the People Act, took effect 2026-06-01 and
--       moves the body to seven members elected by congressional district, but its own
--       phase-in says "November 2026: two commissioners elected under the prior at-large
--       structure". These two are those two.
--   ▶ A DISTRICT IN THE TITLE IS A CLAIM ABOUT THE CANDIDATE, NOT NECESSARILY ABOUT THE
--     ELECTORATE. Read who votes before deciding a seat needs geometry.
--
-- 🟢 THE OTHER SEVEN REUSE A POLYGON PRODUCTION ALREADY HOLDS. Colorado's State Board of
--   Education and the University of Colorado Board of Regents are each nine members: eight
--   elected BY CONGRESSIONAL DISTRICT and one at large. Both boards' own sites list every
--   member against a congressional district. So each board district is a COPY, taken inside
--   the database, of the TIGER congressional polygon for that district:
--     INSERT ... SELECT gb.geometry FROM essentials.geofence_boundaries gb
--      WHERE gb.mtfcc = 'G5200' AND gb.geo_id = '080N'
--   Nothing is downloaded, reprojected or digitised, so the CRS hazard CLAUDE.md records
--   cannot arise — and all eight sources were measured SRID 4326 and ST_IsValid before the
--   copy, with the gates below asserting it again at run time.
--   ⚠ Colorado has no G5200V26 rows, so there is exactly one congressional map in production
--     and no vintage to choose between.
--
-- 🔴 A NEW LAYER FOR A STATE BOARD NEEDS A READ-PATH LINE, AND ONLY ONE OF THE TWO DID.
--   X0003 is already admitted for STATE_BOARD_EDUCATION (Utah's board) and the rule is not
--   state-scoped, so Colorado's eight education districts join with NO code change. The
--   Regents are STATE_BOARD, and the X catch-all admits only LOCAL, COUNTY and JUDICIAL, so
--   X-ST-BOARD is added explicitly to BOTH districtQueries.ts and geoIdGuard.ts — the two
--   files say in their own comments that they must stay in step, and
--   check-address-reachability.mjs reads the guard out of geoIdGuard.ts so there is one
--   definition in play. X-CA-SBOE is the template.
--
-- WHAT IT WRITES:
--   4 chambers · 20 districts (4 statewide, 16 congressional) · 16 geofence polygons
--   26 offices · 26 office_terms · 9 races · 44 politicians · 23 candidacies (9 won)
--
--   AL PSC       3 seats · statewide               · 2026: Place 1, Place 2
--   GA PSC       5 seats · statewide               · 2026: District 3, District 5
--   CO SBE       9 seats · congressional districts · 2026: District 1, District 7
--   CO REGENTS   9 seats · congressional districts · 2026: District 2, District 6, District 7
--
-- 🔴 AN OFFICE WITH NO office_terms ROW RAISES THE DRIFT BASELINE, so every one of the 26
--   offices is created WITH its current member seated, from the body's OWN roster, and the
--   post-verify asserts the unflagged baseline is still exactly 238.
--   ⚠ THE HOLDER IS NOT THE WINNER: 4 of the 9 winners are someone other than the sitting
--     member (Matt Gentry for Jeremy H. Oden, Jim Zeigler for Chris V. Beeker III, Shelia
--     Edwards for Stan Wise, Edie Hooton for Callie Rennison).
--
-- ⚠ COLORADO'S STATE BOARD DISTRICT 3 IS CREATED AND SEATED BUT CARRIES NO RACE. It was on
--   the 2026 ballot — Ballotpedia's published rotation puts Districts 1, 3 and 7 in this
--   cycle, and all three have a votebox — but Ballotpedia has called no winner in District 3,
--   so the seat belongs to the uncalled pass and nothing is written for it here. The seat
--   table carries both facts separately: on_ballot_2026 and race_recorded.
--
-- IDENTITY. All 44 people are new; nothing is pinned and no collision is excused. Both
--   sweeps — full name, and surname + first initial — returned only plainly different people
--   (Jimmy Gordon @MN for James O. Gordon, Jeanette and Johnny Shaw for Jason Shaw, Faye
--   Johnson for Fitz Johnson, Scott and Stephanie Wise for Stan Wise, Rex and Rick Scott for
--   Ray Scott, Patricia Mueller for Paul Mueller, and so on).
--   🟢 The sweep is not blind: production holds 64 Colorado House and 35 Senate members and
--     180 Georgia House and 55 Senate members, so it can see those states. It holds NO Alabama
--     state legislators at all, which is why Cynthia Lee Almond — a former Alabama state
--     representative — is new rather than matched.
--
-- 🔴 NO TERM START IS INVENTED. Every term is open-ended with start_precision 'unknown': not
--   one of these rosters publishes when the member took the seat. 9 of the 26 seats publish a
--   term-END year (the Regents' own site gives all nine), and a gate checks each against the
--   ballot column — on the 2026 ballot means the term ends 2027, otherwise later.
--
-- ▶ FOLLOW-UP, JANUARY 2027: HB475 has Alabama's governor appoint four more commissioners,
--   two to two-year and two to four-year terms. Create those four seats and raise the
--   chamber's official_count from 3 to 7. From November 2028 Alabama's elected PSC seats
--   become congressional-district seats and will need exactly what Colorado gets here.
--
-- Applied to production 2026-11-07 by Chris Cantrell. Slot reserved via steward.

BEGIN;

-- ─── 1. The four bodies and their 26 seats ───
CREATE TEMP TABLE body (
  bkey text PRIMARY KEY, st text NOT NULL, state_name text NOT NULL, fips text NOT NULL,
  gov_id uuid NOT NULL, election_id uuid NOT NULL, chamber_name text NOT NULL, chamber_formal text NOT NULL,
  official_count int NOT NULL, term_length text NOT NULL, website text NOT NULL, electorate text NOT NULL,
  statewide_label text NOT NULL, cd_district_type text, cd_mtfcc text, cd_label_prefix text
) ON COMMIT DROP;
INSERT INTO body VALUES
  ('AL PSC', 'AL', 'Alabama', '01',
   'f427572f-d37a-4828-b68b-7f2c4e6ee4cd'::uuid, '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, 'Public Service Commission', 'Alabama Public Service Commission',
   3, '4 years (6 years for terms elected after 2026-06-01)', 'https://psc.alabama.gov/', 'statewide',
   'Alabama Public Service Commission', NULL, NULL, NULL),
  ('GA PSC', 'GA', 'Georgia', '13',
   'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf'::uuid, 'e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7'::uuid, 'Public Service Commission', 'Georgia Public Service Commission',
   5, '6 years', 'https://psc.ga.gov/about-the-psc/commissioners/', 'statewide',
   'Georgia Public Service Commission', NULL, NULL, NULL),
  ('CO SBE', 'CO', 'Colorado', '08',
   '41ad933e-ba54-48a3-baef-83fbdca9a9d5'::uuid, 'ae041272-78b1-4840-862c-797118b79afe'::uuid, 'State Board of Education', 'Colorado State Board of Education',
   9, '6 years', 'https://www.cde.state.co.us/cdeboard', 'congressional districts',
   'Colorado State Board of Education At-Large', 'STATE_BOARD_EDUCATION', 'X0003', 'Colorado State Board of Education District'),
  ('CO REGENTS', 'CO', 'Colorado', '08',
   '41ad933e-ba54-48a3-baef-83fbdca9a9d5'::uuid, 'ae041272-78b1-4840-862c-797118b79afe'::uuid, 'Board of Regents', 'University of Colorado Board of Regents',
   9, '6 years', 'https://regents.cu.edu/meet-the-regents', 'congressional districts',
   'University of Colorado Board of Regents At-Large', 'STATE_BOARD', 'X-ST-BOARD', 'University of Colorado Board of Regents District');

CREATE TEMP TABLE seat (
  skey text PRIMARY KEY, bkey text NOT NULL, title text NOT NULL, who text NOT NULL,
  on_ballot_2026 boolean NOT NULL, race_recorded boolean NOT NULL, term_ends_year int,
  geometry text NOT NULL, cd int, race_title text
) ON COMMIT DROP;
INSERT INTO seat VALUES
  ('AL PSC#1', 'AL PSC', 'Public Service Commission President', 'Cynthia Lee Almond', false, false, NULL, 'statewide', NULL, NULL),
  ('AL PSC#2', 'AL PSC', 'Public Service Commissioner, Place 1', 'Jeremy H. Oden', true, true, NULL, 'statewide', NULL, 'Alabama Public Service Commission Place 1'),
  ('AL PSC#3', 'AL PSC', 'Public Service Commissioner, Place 2', 'Chris V. Beeker III', true, true, NULL, 'statewide', NULL, 'Alabama Public Service Commission Place 2'),
  ('GA PSC#1', 'GA PSC', 'Public Service Commissioner, District 1', 'Jason Shaw', false, false, NULL, 'statewide', NULL, NULL),
  ('GA PSC#2', 'GA PSC', 'Public Service Commissioner, District 2', 'Alicia M. Johnson', false, false, NULL, 'statewide', NULL, NULL),
  ('GA PSC#3', 'GA PSC', 'Public Service Commissioner, District 3', 'Peter Hubbard', true, true, NULL, 'statewide', NULL, 'Georgia Public Service Commission District 3'),
  ('GA PSC#4', 'GA PSC', 'Public Service Commissioner, District 4', 'Lauren McDonald', false, false, NULL, 'statewide', NULL, NULL),
  ('GA PSC#5', 'GA PSC', 'Public Service Commissioner, District 5', 'Stan Wise', true, true, NULL, 'statewide', NULL, 'Georgia Public Service Commission District 5'),
  ('CO SBE#1', 'CO SBE', 'State Board of Education Member, District 1', 'Lisa Escárcega', true, true, NULL, 'cd', 1, 'Colorado State Board of Education District 1'),
  ('CO SBE#2', 'CO SBE', 'State Board of Education Member, District 2', 'Kathy Gebhardt', false, false, NULL, 'cd', 2, NULL),
  ('CO SBE#3', 'CO SBE', 'State Board of Education Member, District 3', 'Sherri Wright', true, false, NULL, 'cd', 3, NULL),
  ('CO SBE#4', 'CO SBE', 'State Board of Education Member, District 4', 'Kristi Burton Brown', false, false, NULL, 'cd', 4, NULL),
  ('CO SBE#5', 'CO SBE', 'State Board of Education Member, District 5', 'Steve Durham', false, false, NULL, 'cd', 5, NULL),
  ('CO SBE#6', 'CO SBE', 'State Board of Education Member, District 6', 'Rebecca McClellan', false, false, NULL, 'cd', 6, NULL),
  ('CO SBE#7', 'CO SBE', 'State Board of Education Member, District 7', 'Karla Esser', true, true, NULL, 'cd', 7, 'Colorado State Board of Education District 7'),
  ('CO SBE#8', 'CO SBE', 'State Board of Education Member, District 8', 'Yazmin Navarro', false, false, NULL, 'cd', 8, NULL),
  ('CO SBE#9', 'CO SBE', 'State Board of Education Member, At-Large', 'Kathy Plomer', false, false, NULL, 'statewide', NULL, NULL),
  ('CO REGENTS#1', 'CO REGENTS', 'University of Colorado Regent, District 1', 'Wanda James', false, false, 2029, 'cd', 1, NULL),
  ('CO REGENTS#2', 'CO REGENTS', 'University of Colorado Regent, District 2', 'Callie Rennison', true, true, 2027, 'cd', 2, 'University of Colorado Board of Regents District 2'),
  ('CO REGENTS#3', 'CO REGENTS', 'University of Colorado Regent, District 3', 'Ray Scott', false, false, 2031, 'cd', 3, NULL),
  ('CO REGENTS#4', 'CO REGENTS', 'University of Colorado Regent, District 4', 'Frank McNulty', false, false, 2029, 'cd', 4, NULL),
  ('CO REGENTS#5', 'CO REGENTS', 'University of Colorado Regent, District 5', 'Ken Montera', false, false, 2031, 'cd', 5, NULL),
  ('CO REGENTS#6', 'CO REGENTS', 'University of Colorado Regent, District 6', 'Ilana Spiegel', true, true, 2027, 'cd', 6, 'University of Colorado Board of Regents District 6'),
  ('CO REGENTS#7', 'CO REGENTS', 'University of Colorado Regent, District 7', 'Nolbert Chavez', true, true, 2027, 'cd', 7, 'University of Colorado Board of Regents District 7'),
  ('CO REGENTS#8', 'CO REGENTS', 'University of Colorado Regent, District 8', 'Mark VanDriel', false, false, 2029, 'cd', 8, NULL),
  ('CO REGENTS#9', 'CO REGENTS', 'University of Colorado Regent, At-Large', 'Elliott Hood', false, false, 2031, 'statewide', NULL, NULL);

-- ─── Pre-gates ───
DO $$ DECLARE txt text; n int; BEGIN
  SELECT count(*) INTO n FROM body; IF n <> 4 THEN RAISE EXCEPTION 'expected 4 bodies, found %', n; END IF;
  SELECT count(*) INTO n FROM seat; IF n <> 26 THEN RAISE EXCEPTION 'expected 26 seats, found %', n; END IF;

  -- every body is created WHOLE
  SELECT string_agg(b.bkey || ': ' || z.n || ' seats for official_count ' || b.official_count, '; ') INTO txt
    FROM body b JOIN LATERAL (SELECT count(*) AS n FROM seat s WHERE s.bkey = b.bkey) z ON true
   WHERE z.n <> b.official_count;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a body does not create its whole membership: %', txt; END IF;

  -- 🔴 the ballot column is checked against the term-end years the bodies publish
  SELECT string_agg(s.skey || ' (' || s.who || '): on_ballot=' || s.on_ballot_2026 || ' but the body says the term ends ' || s.term_ends_year, '; ') INTO txt
    FROM seat s WHERE s.term_ends_year IS NOT NULL
     AND ((s.on_ballot_2026 AND s.term_ends_year <> 2027) OR (NOT s.on_ballot_2026 AND s.term_ends_year <= 2027));
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seat is marked against its own published term end: %', txt; END IF;
  SELECT string_agg(s.skey || ' records a race but was not on the 2026 ballot', '; ') INTO txt
    FROM seat s WHERE s.race_recorded AND NOT s.on_ballot_2026;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is recorded for a seat that was not on the ballot: %', txt; END IF;
  SELECT count(*) INTO n FROM seat WHERE race_recorded;
  IF n <> 9 THEN RAISE EXCEPTION 'expected 9 races, found %', n; END IF;

  -- a cd seat needs a district number and a statewide seat must not have one
  SELECT string_agg(s.skey || ' geometry=' || s.geometry || ' cd=' || coalesce(s.cd::text,'(null)'), '; ') INTO txt
    FROM seat s WHERE (s.geometry = 'cd' AND s.cd IS NULL) OR (s.geometry = 'statewide' AND s.cd IS NOT NULL)
       OR s.geometry NOT IN ('cd','statewide');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seat''s geometry and district number disagree: %', txt; END IF;
  -- a body with cd seats must declare the layer they load into
  SELECT string_agg(b.bkey || ' has cd seats but no layer', '; ') INTO txt FROM body b
   WHERE EXISTS (SELECT 1 FROM seat s WHERE s.bkey = b.bkey AND s.geometry = 'cd')
     AND (b.cd_mtfcc IS NULL OR b.cd_district_type IS NULL);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a body would load polygons into no layer: %', txt; END IF;

  SELECT string_agg(b.bkey || ' -> government ' || b.gov_id, '; ') INTO txt
    FROM body b LEFT JOIN essentials.governments g ON g.id = b.gov_id WHERE g.id IS NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a government row does not exist: %', txt; END IF;
  SELECT string_agg(b.bkey || ' -> ' || coalesce(e.name,'(missing)'), '; ') INTO txt
    FROM body b LEFT JOIN essentials.elections e ON e.id = b.election_id
   WHERE e.id IS NULL OR e.election_date <> DATE '2026-11-03' OR e.state IS DISTINCT FROM b.st;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an election row is not the 2026-11-03 general of its state: %', txt; END IF;
  SELECT string_agg(b.bkey || ': this file says FIPS ' || b.fips || ' but ' || b.st || ' uses ' || d.geo_id, '; ') INTO txt
    FROM body b JOIN LATERAL (SELECT DISTINCT d2.geo_id FROM essentials.districts d2
      WHERE upper(d2.state) = b.st AND d2.district_type = 'STATE_EXEC' LIMIT 1) d ON true WHERE d.geo_id <> b.fips;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a FIPS disagrees with the state''s existing districts: %', txt; END IF;

  -- nothing this file creates may already exist
  SELECT string_agg(b.bkey || ' -> ' || c.name_formal, '; ') INTO txt
    FROM body b JOIN essentials.chambers c ON c.name_formal = b.chamber_formal;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a chamber this file creates already exists: %', txt; END IF;
  SELECT string_agg(s.skey || ': ' || o.title || ' already exists as ' || d.district_type || ' ' || o.id, '; ') INTO txt
    FROM seat s JOIN body b ON b.bkey = s.bkey
    JOIN essentials.districts d ON upper(d.state) = b.st JOIN essentials.offices o ON o.district_id = d.id
   WHERE lower(o.title) = lower(s.title);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;

  -- 🔴🔴 THE SOURCE POLYGONS. Every congressional district this file copies must exist, be
  --   SRID 4326 and be valid — a polygon can be the right shape in the wrong CRS and pass
  --   every other check. This is measured here, on the real rows, before anything is written.
  SELECT string_agg(s.skey || ' needs ' || b.fips || lpad(s.cd::text, 2, '0') || ' and it is missing', '; ') INTO txt
    FROM seat s JOIN body b ON b.bkey = s.bkey
    LEFT JOIN essentials.geofence_boundaries src ON src.mtfcc = 'G5200' AND src.geo_id = b.fips || lpad(s.cd::text, 2, '0')
   WHERE s.geometry = 'cd' AND src.id IS NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a congressional source polygon does not exist: %', txt; END IF;
  SELECT string_agg(src.geo_id || ' srid=' || ST_SRID(src.geometry) || ' valid=' || ST_IsValid(src.geometry), '; ') INTO txt
    FROM seat s JOIN body b ON b.bkey = s.bkey
    JOIN essentials.geofence_boundaries src ON src.mtfcc = 'G5200' AND src.geo_id = b.fips || lpad(s.cd::text, 2, '0')
   WHERE s.geometry = 'cd' AND (ST_SRID(src.geometry) <> 4326 OR NOT ST_IsValid(src.geometry) OR ST_IsEmpty(src.geometry));
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a congressional source polygon is not a valid 4326 polygon: %', txt; END IF;
  -- and there must be no 2026-vintage congressional map for these states, or this file is
  -- silently choosing between two maps
  SELECT string_agg(DISTINCT b.st || ' has G5200V26 rows', '; ') INTO txt FROM body b
    JOIN essentials.geofence_boundaries v ON v.mtfcc = 'G5200V26' AND v.state = b.fips
   WHERE EXISTS (SELECT 1 FROM seat s WHERE s.bkey = b.bkey AND s.geometry = 'cd');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'two congressional vintages exist and this file picks one blind: %', txt; END IF;

  SELECT string_agg(s.skey, '; ') INTO txt FROM seat s JOIN body b ON b.bkey = s.bkey
    JOIN essentials.geofence_boundaries gb ON gb.mtfcc = b.cd_mtfcc
     AND gb.geo_id = 'ocd-division/country:us/state:' || lower(b.st) || '/' || CASE WHEN b.cd_mtfcc = 'X0003' THEN 'sboe' ELSE 'regent' END || ':' || s.cd
   WHERE s.geometry = 'cd';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a board polygon this file loads already exists: %', txt; END IF;
END $$;

-- ─── 2. The polygons: a copy of each congressional district, taken inside the database ───
CREATE TEMP TABLE made_poly (skey text PRIMARY KEY, geo_id text NOT NULL, src_geo_id text NOT NULL) ON COMMIT DROP;
INSERT INTO made_poly
SELECT s.skey,
       'ocd-division/country:us/state:' || lower(b.st) || '/' || CASE WHEN b.cd_mtfcc = 'X0003' THEN 'sboe' ELSE 'regent' END || ':' || s.cd,
       b.fips || lpad(s.cd::text, 2, '0')
  FROM seat s JOIN body b ON b.bkey = s.bkey WHERE s.geometry = 'cd';

INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
SELECT mp.geo_id, mp.geo_id, b.chamber_formal || ' District ' || s.cd, b.fips, b.cd_mtfcc, src.geometry,
       'copied from TIGER congressional district ' || mp.src_geo_id || ' (mtfcc G5200) inside the database — '
       || b.chamber_formal || ' elects this seat by congressional district, per ' || b.website || ' read 2026-11-07; CC_0366',
       now()
  FROM made_poly mp JOIN seat s ON s.skey = mp.skey JOIN body b ON b.bkey = s.bkey
  JOIN essentials.geofence_boundaries src ON src.mtfcc = 'G5200' AND src.geo_id = mp.src_geo_id;

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM made_poly; IF n <> 16 THEN RAISE EXCEPTION 'expected 16 polygons, found %', n; END IF;
  -- 🔴 EACH COPY MUST BE THE POLYGON IT CLAIMS TO BE, not merely some polygon
  SELECT string_agg(mp.geo_id || ' is not identical to ' || mp.src_geo_id, '; ') INTO txt
    FROM made_poly mp JOIN seat s ON s.skey = mp.skey JOIN body b ON b.bkey = s.bkey
    JOIN essentials.geofence_boundaries dst ON dst.mtfcc = b.cd_mtfcc AND dst.geo_id = mp.geo_id
    JOIN essentials.geofence_boundaries src ON src.mtfcc = 'G5200' AND src.geo_id = mp.src_geo_id
   WHERE NOT ST_Equals(dst.geometry, src.geometry) OR ST_SRID(dst.geometry) <> 4326;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a copied polygon is not its source: %', txt; END IF;
END $$;

-- ─── 3. Chambers, districts, offices ───
CREATE TEMP TABLE made_chamber (bkey text PRIMARY KEY, chamber_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,
                                   official_count, term_length, staggered_term, website_url)
  SELECT b.chamber_name, b.chamber_formal, b.gov_id, 'full', b.official_count, b.term_length, true, b.website
    FROM body b RETURNING id, name_formal)
INSERT INTO made_chamber SELECT b.bkey, ins.id FROM ins JOIN body b ON b.chamber_formal = ins.name_formal;

-- one statewide district per body (for the at-large and the statewide-elected seats) ...
CREATE TEMP TABLE made_statewide (bkey text PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT 'STATE_EXEC', b.st, b.fips, 'ocd-division/country:us/state:' || lower(b.st), b.statewide_label, '', '', 'residency'
    FROM body b WHERE EXISTS (SELECT 1 FROM seat s WHERE s.bkey = b.bkey AND s.geometry = 'statewide')
  RETURNING id, label)
INSERT INTO made_statewide SELECT b.bkey, ins.id FROM ins JOIN body b ON b.statewide_label = ins.label;

-- ... and one district per congressional-district seat, keyed on the polygon just loaded
CREATE TEMP TABLE made_cd (skey text PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT b.cd_district_type, lower(b.st), mp.geo_id, mp.geo_id, b.chamber_formal || ' District ' || s.cd,
         b.cd_mtfcc, s.cd::text, 'residency'
    FROM made_poly mp JOIN seat s ON s.skey = mp.skey JOIN body b ON b.bkey = s.bkey
  RETURNING id, geo_id)
INSERT INTO made_cd SELECT mp.skey, ins.id FROM ins JOIN made_poly mp ON mp.geo_id = ins.geo_id;

CREATE TEMP TABLE made_office (skey text PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,
                                  is_vacant, faces_retention_vote, is_appointed_position, description)
  SELECT s.title, mc.chamber_id, coalesce(mcd.district_id, msw.district_id), b.st, 'full', false, false, false, s.skey
    FROM seat s JOIN body b ON b.bkey = s.bkey JOIN made_chamber mc ON mc.bkey = s.bkey
    LEFT JOIN made_cd mcd ON mcd.skey = s.skey LEFT JOIN made_statewide msw ON msw.bkey = s.bkey
  RETURNING id, description)
INSERT INTO made_office SELECT ins.description, ins.id FROM ins;
UPDATE essentials.offices o SET description = NULL FROM made_office mo WHERE o.id = mo.office_id;

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM made_chamber;   IF n <> 4 THEN RAISE EXCEPTION 'only % chambers were created', n; END IF;
  SELECT count(*) INTO n FROM made_statewide; IF n <> 4 THEN RAISE EXCEPTION 'only % statewide districts were created', n; END IF;
  SELECT count(*) INTO n FROM made_cd;        IF n <> 16 THEN RAISE EXCEPTION 'only % congressional districts were created', n; END IF;
  SELECT count(*) INTO n FROM made_office;    IF n <> 26 THEN RAISE EXCEPTION 'only % offices were created', n; END IF;
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id WHERE o.description IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% office(s) kept the seat key in description', n; END IF;
  -- every office is on the district its seat calls for, and no cd office landed on the statewide one
  SELECT string_agg(s.skey || ' is on the wrong district', '; ') INTO txt
    FROM seat s JOIN made_office mo ON mo.skey = s.skey JOIN essentials.offices o ON o.id = mo.office_id
    LEFT JOIN made_cd mcd ON mcd.skey = s.skey LEFT JOIN made_statewide msw ON msw.bkey = s.bkey
   WHERE o.district_id IS DISTINCT FROM CASE WHEN s.geometry = 'cd' THEN mcd.district_id ELSE msw.district_id END;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an office is not on its seat''s district: %', txt; END IF;
END $$;

-- ─── 4. The people ───
CREATE TEMP TABLE seed_people (
  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people VALUES
  ('Cynthia Lee Almond', 'Cynthia Lee', 'Almond',
   'https://ballotpedia.org/Cynthia_Lee_Almond (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Jeremy H. Oden', 'Jeremy H.', 'Oden',
   'https://ballotpedia.org/Jeremy_H._Oden (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Matt Gentry', 'Matt', 'Gentry',
   'https://ballotpedia.org/Matt_Gentry (Ballotpedia, read 2026-11-07); CC_0366'),
  ('James O. Gordon', 'James O.', 'Gordon',
   'https://ballotpedia.org/James_O._Gordon (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Chris V. Beeker III', 'Chris V.', 'Beeker III',
   'https://ballotpedia.org/Chris_V._Beeker_III (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Jim Zeigler', 'Jim', 'Zeigler',
   'https://ballotpedia.org/Jim_Zeigler (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Sheila McNeil', 'Sheila', 'McNeil',
   'https://ballotpedia.org/Sheila_McNeil (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Jason Shaw', 'Jason', 'Shaw',
   'https://ballotpedia.org/Jason_Shaw (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Alicia M. Johnson', 'Alicia M.', 'Johnson',
   'https://ballotpedia.org/Alicia_M._Johnson (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Peter Hubbard', 'Peter', 'Hubbard',
   'https://ballotpedia.org/Peter_Hubbard (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Fitz Johnson', 'Fitz', 'Johnson',
   'https://ballotpedia.org/Fitz_Johnson (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Lauren McDonald', 'Lauren', 'McDonald',
   'https://ballotpedia.org/Lauren_McDonald (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Stan Wise', 'Stan', 'Wise',
   'https://ballotpedia.org/Stan_Wise (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Shelia Edwards', 'Shelia', 'Edwards',
   'https://ballotpedia.org/Shelia_Edwards (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Josh Tolbert', 'Josh', 'Tolbert',
   'https://ballotpedia.org/Josh_Tolbert (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Lisa Escárcega', 'Lisa', 'Escárcega',
   'https://ballotpedia.org/Lisa_Escárcega (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Frederick Espinoza', 'Frederick', 'Espinoza',
   'https://ballotpedia.org/Frederick_Espinoza (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Clayton Casciato', 'Clayton', 'Casciato',
   'https://ballotpedia.org/Clayton_Casciato (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Kathy Gebhardt', 'Kathy', 'Gebhardt',
   'https://ballotpedia.org/Kathy_Gebhardt (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Sherri Wright', 'Sherri', 'Wright',
   'https://ballotpedia.org/Sherri_Wright (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Kristi Burton Brown', 'Kristi', 'Burton Brown',
   'https://ballotpedia.org/Kristi_Burton_Brown (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Steve Durham', 'Steve', 'Durham',
   'https://ballotpedia.org/Steve_Durham (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Rebecca McClellan', 'Rebecca', 'McClellan',
   'https://ballotpedia.org/Rebecca_McClellan (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Karla Esser', 'Karla', 'Esser',
   'https://ballotpedia.org/Karla_Esser (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Steve Barton', 'Steve', 'Barton',
   'https://ballotpedia.org/Steve_Barton (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Ross Klopf', 'Ross', 'Klopf',
   'https://ballotpedia.org/Ross_Klopf (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Yazmin Navarro', 'Yazmin', 'Navarro',
   'https://ballotpedia.org/Yazmin_Navarro (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Kathy Plomer', 'Kathy', 'Plomer',
   'https://ballotpedia.org/Kathy_Plomer (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Wanda James', 'Wanda', 'James',
   'https://ballotpedia.org/Wanda_James (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Callie Rennison', 'Callie', 'Rennison',
   'https://ballotpedia.org/Callie_Rennison (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Edie Hooton', 'Edie', 'Hooton',
   'https://ballotpedia.org/Edie_Hooton (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Marty Neilson', 'Marty', 'Neilson',
   'https://ballotpedia.org/Marty_Neilson (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Richard Friend', 'Richard', 'Friend',
   'https://ballotpedia.org/Richard_Friend (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Ray Scott', 'Ray', 'Scott',
   'https://ballotpedia.org/Ray_Scott (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Frank McNulty', 'Frank', 'McNulty',
   'https://ballotpedia.org/Frank_McNulty (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Ken Montera', 'Ken', 'Montera',
   'https://ballotpedia.org/Ken_Montera (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Ilana Spiegel', 'Ilana', 'Spiegel',
   'https://ballotpedia.org/Ilana_Spiegel (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Veanessa Burbage', 'Veanessa', 'Burbage',
   'https://ballotpedia.org/Veanessa_Burbage (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Joe Johnson', 'Joe', 'Johnson',
   'https://ballotpedia.org/Joe_Johnson (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Nolbert Chavez', 'Nolbert', 'Chavez',
   'https://ballotpedia.org/Nolbert_Chavez (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Paul Mueller', 'Paul', 'Mueller',
   'https://ballotpedia.org/Paul_Mueller (Ballotpedia, read 2026-11-07); CC_0366'),
  ('BetteRose Ryan', 'BetteRose', 'Ryan',
   'https://ballotpedia.org/BetteRose_Ryan (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Mark VanDriel', 'Mark', 'VanDriel',
   'https://ballotpedia.org/Mark_VanDriel (Ballotpedia, read 2026-11-07); CC_0366'),
  ('Elliott Hood', 'Elliott', 'Hood',
   'https://ballotpedia.org/Elliott_Hood (Ballotpedia, read 2026-11-07); CC_0366');

-- 🔴 EMPTY ON PURPOSE: no name this file seeds collides with an existing politician.
CREATE TEMP TABLE allowed_name_collisions (full_name text PRIMARY KEY) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT lower(translate(coalesce(t, ''), 'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇçʻ‘’',
                                          'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc''''''')
  )
$f$;

CREATE TEMP TABLE pol_keys ON COMMIT DROP AS
SELECT id, full_name, first_name, last_name, is_active, source,
       pg_temp.namekey(full_name) AS k_full, pg_temp.namekey(first_name) AS k_first, pg_temp.namekey(last_name) AS k_last
  FROM essentials.politicians;
CREATE INDEX ON pol_keys (k_full);
CREATE INDEX ON pol_keys (k_first, k_last);
ANALYZE pol_keys;

DO $$ DECLARE txt text; n int; BEGIN
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Jon Rosenthal');
  IF n < 1 THEN RAISE EXCEPTION 'the name index cannot see a politician known to exist — the guard below would pass vacuously'; END IF;
  SELECT count(*) INTO n FROM pol_keys; IF n < 50000 THEN RAISE EXCEPTION 'the name index holds only % rows', n; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ', active=' || p.is_active || ')' AS msg
      FROM seed_people s JOIN pol_keys p ON p.k_full = pg_temp.namekey(s.full_name)
     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)
    UNION
    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ')'
      FROM seed_people s JOIN pol_keys p ON p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name)
     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;

  SELECT count(*) INTO n FROM allowed_name_collisions a JOIN seed_people s ON s.full_name = a.full_name
   WHERE NOT EXISTS (SELECT 1 FROM pol_keys p WHERE p.source IS DISTINCT FROM s.source
                       AND (p.k_full = pg_temp.namekey(s.full_name)
                         OR (p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name))));
  IF n <> 0 THEN RAISE EXCEPTION '% allowed collision(s) no longer collide — the allowance is stale', n; END IF;

  -- 🔴 the split must reconstruct the name EXACTLY; "ends with the surname" has failed four times
  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt
    FROM seed_people s WHERE s.full_name <> s.first_name || ' ' || s.last_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;
  SELECT string_agg(s.full_name || ' -> ' || s.source, '; ') INTO txt FROM seed_people s
   WHERE s.source NOT LIKE 'https://ballotpedia.org/%' OR s.source LIKE '%#%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is not a plain Ballotpedia page: %', txt; END IF;
END $$;

SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT s.full_name, s.first_name, s.last_name, s.source, true,
       EXISTS (SELECT 1 FROM seat st WHERE st.who = s.full_name)
  FROM seed_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source);
SET LOCAL essentials.allow_duplicate_name = 'off';

CREATE TEMP TABLE person (who text PRIMARY KEY, pid uuid NOT NULL) ON COMMIT DROP;
INSERT INTO person SELECT s.full_name, p.id FROM seed_people s
  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source = s.source;
DO $$ DECLARE n int; BEGIN SELECT count(*) INTO n FROM person;
  IF n <> 44 THEN RAISE EXCEPTION 'only % of the 44 people resolved to exactly one row', n; END IF; END $$;

-- ─── 5. Seat every current member ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT mo.office_id, pe.pid, NULL, NULL, 'unknown', 'unknown',
       b.website || ' (the body''s own roster, read 2026-11-07) — CC_0366'
  FROM seat s JOIN body b ON b.bkey = s.bkey JOIN made_office mo ON mo.skey = s.skey JOIN person pe ON pe.who = s.who;

DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.skey = s.skey
    JOIN essentials.office_current_holder och ON och.office_id = mo.office_id
    JOIN person pe ON pe.who = s.who AND pe.pid = och.politician_id;
  IF n <> 26 THEN RAISE EXCEPTION 'only % of the 26 seats resolve to the member this file names', n; END IF;
END $$;

-- ─── 6. The nine races and their results ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT b.election_id, mo.office_id, s.race_title, NULL, 1,
       'The seat held by ' || s.who || '. ' || b.chamber_formal || ' is elected ' || b.electorate || '.'
  FROM seat s JOIN body b ON b.bkey = s.bkey JOIN made_office mo ON mo.skey = s.skey WHERE s.race_recorded;

CREATE TEMP TABLE calls (
  skey text NOT NULL, who text NOT NULL, result text NOT NULL, is_write_in boolean NOT NULL,
  is_incumbent boolean NOT NULL, PRIMARY KEY (skey, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  ('AL PSC#2', 'Matt Gentry', 'won', false, false),
  ('AL PSC#2', 'James O. Gordon', 'lost', false, false),
  ('AL PSC#3', 'Jim Zeigler', 'won', false, false),
  ('AL PSC#3', 'Sheila McNeil', 'lost', false, false),
  ('GA PSC#3', 'Peter Hubbard', 'won', false, true),
  ('GA PSC#3', 'Fitz Johnson', 'lost', false, false),
  ('GA PSC#5', 'Shelia Edwards', 'won', false, false),
  ('GA PSC#5', 'Josh Tolbert', 'lost', false, false),
  ('CO SBE#1', 'Lisa Escárcega', 'won', false, true),
  ('CO SBE#1', 'Frederick Espinoza', 'lost', false, false),
  ('CO SBE#1', 'Clayton Casciato', 'lost', false, false),
  ('CO SBE#7', 'Karla Esser', 'won', false, true),
  ('CO SBE#7', 'Steve Barton', 'lost', false, false),
  ('CO SBE#7', 'Ross Klopf', 'lost', false, false),
  ('CO REGENTS#2', 'Edie Hooton', 'won', false, false),
  ('CO REGENTS#2', 'Marty Neilson', 'lost', false, false),
  ('CO REGENTS#2', 'Richard Friend', 'lost', false, false),
  ('CO REGENTS#6', 'Ilana Spiegel', 'won', false, true),
  ('CO REGENTS#6', 'Veanessa Burbage', 'lost', false, false),
  ('CO REGENTS#6', 'Joe Johnson', 'lost', false, false),
  ('CO REGENTS#7', 'Nolbert Chavez', 'won', false, true),
  ('CO REGENTS#7', 'Paul Mueller', 'lost', false, false),
  ('CO REGENTS#7', 'BetteRose Ryan', 'lost', false, false);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls; IF n <> 23 THEN RAISE EXCEPTION 'expected 23 candidacies, found %', n; END IF;
  SELECT string_agg(z.skey || ': ' || z.w || ' winner(s)', '; ') INTO txt FROM (
    SELECT c.skey, count(*) FILTER (WHERE c.result = 'won') AS w FROM calls c GROUP BY c.skey) z WHERE z.w <> 1;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a single-seat race does not hold exactly one winner: %', txt; END IF;
  SELECT string_agg(c.who || ' in ' || c.skey, '; ') INTO txt FROM calls c LEFT JOIN person pe ON pe.who = c.who WHERE pe.pid IS NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy resolves to no person: %', txt; END IF;
  SELECT string_agg(c.who || ' in ' || c.skey, '; ') INTO txt FROM calls c JOIN seat s ON s.skey = c.skey
   WHERE c.is_incumbent <> (s.who = c.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an incumbent flag disagrees with the seat''s holder: %', txt; END IF;
  SELECT count(*) INTO n FROM calls WHERE result = 'won';
  IF n <> 9 THEN RAISE EXCEPTION 'expected 9 winners, found %', n; END IF;
END $$;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, pl.id, pl.full_name, pl.first_name, pl.last_name, c.is_incumbent, 'active', c.is_write_in,
       'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0366',
       c.result, 'called',
       'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0366', now()
  FROM calls c JOIN made_office mo ON mo.skey = c.skey
  JOIN essentials.races r ON r.office_id = mo.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN person pe ON pe.who = c.who JOIN essentials.politicians pl ON pl.id = pe.pid;

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.skey = s.skey
    JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03' WHERE s.race_recorded;
  IF n <> 9 THEN RAISE EXCEPTION 'expected 9 new races, found %', n; END IF;
  SELECT count(*) INTO n FROM calls c JOIN made_office mo ON mo.skey = c.skey
    JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN person pe ON pe.who = c.who
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = pe.pid
   WHERE rc.result = c.result AND rc.result_certainty = 'called' AND rc.is_write_in = c.is_write_in;
  IF n <> 23 THEN RAISE EXCEPTION 'only % of the 23 candidacies hold their stated result', n; END IF;

  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED
  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 26 offices have no term and would raise the drift metric', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;

  -- each body is whole
  SELECT string_agg(b.bkey || ': ' || z.n || ' offices for official_count ' || b.official_count, '; ') INTO txt
    FROM body b JOIN made_chamber mc ON mc.bkey = b.bkey
    JOIN LATERAL (SELECT count(*) AS n FROM essentials.offices o WHERE o.chamber_id = mc.chamber_id) z ON true
   WHERE z.n <> b.official_count;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a chamber is not whole: %', txt; END IF;

  -- 🔴🔴 THE GEOMETRY ACTUALLY ROUTES. For every congressional-district seat, a point on the
  --   surface of its polygon must fall inside EXACTLY ONE district of that body — the one it
  --   belongs to. This is the question the voter asks, answered against the rows just written
  --   rather than reasoned about.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT mp.geo_id || ' contains a point that falls in ' || (
      SELECT count(*) FROM made_poly mp2 JOIN seat s2 ON s2.skey = mp2.skey
        JOIN body b2 ON b2.bkey = s2.bkey
        JOIN essentials.geofence_boundaries g2 ON g2.mtfcc = b2.cd_mtfcc AND g2.geo_id = mp2.geo_id
       WHERE s2.bkey = s.bkey AND ST_Intersects(g2.geometry, ST_PointOnSurface(g1.geometry))
    ) || ' districts of its own body' AS msg
      FROM made_poly mp JOIN seat s ON s.skey = mp.skey JOIN body b ON b.bkey = s.bkey
      JOIN essentials.geofence_boundaries g1 ON g1.mtfcc = b.cd_mtfcc AND g1.geo_id = mp.geo_id
     WHERE (SELECT count(*) FROM made_poly mp2 JOIN seat s2 ON s2.skey = mp2.skey
              JOIN body b2 ON b2.bkey = s2.bkey
              JOIN essentials.geofence_boundaries g2 ON g2.mtfcc = b2.cd_mtfcc AND g2.geo_id = mp2.geo_id
             WHERE s2.bkey = s.bkey AND ST_Intersects(g2.geometry, ST_PointOnSurface(g1.geometry))) <> 1) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a board district does not uniquely contain its own interior point: %', txt; END IF;

  -- 🔴 and the geofence row and the district row must actually meet on (geo_id, mtfcc) —
  --   a district whose key matches nothing is invisible to every address.
  SELECT count(*) INTO n FROM made_cd mcd JOIN essentials.districts d ON d.id = mcd.district_id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc;
  IF n <> 16 THEN RAISE EXCEPTION 'only % of the 16 board districts meet a geofence row on (geo_id, mtfcc)', n; END IF;
  SELECT count(*) INTO n FROM made_statewide msw JOIN essentials.districts d ON d.id = msw.district_id
   WHERE d.district_type <> 'STATE_EXEC' OR coalesce(d.geo_id,'') = '';
  IF n <> 0 THEN RAISE EXCEPTION '% statewide district(s) are not statewide-reachable', n; END IF;

  -- no term claims a date
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE t.term_start IS NOT NULL OR t.term_end IS NOT NULL OR t.start_precision <> 'unknown';
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) claim a date this file cannot source', n; END IF;

  RAISE NOTICE 'CC_0366 OK — 4 bodies, 26 seats, 16 copied polygons, 9 races, 23 candidacies, 44 people seeded.';
END $$;

COMMIT;
