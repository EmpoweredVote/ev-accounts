-- CC_0095_lake_county.sql
-- Knight Foundation program, wave IN-6 (stage 4, Lake County). Slot RESERVED from the allocator.
--
-- ONE migration carrying offices AND people, per spec §3 (the Nashville correction).
--
--   Board of Commissioners  official_count 3   3 offices, ALL COUNTYWIDE
--   Elected Officials       official_count 9   the 9 county officers
--   Lake County Council     official_count 7   ZERO offices — all seven are DEFERRED
--
--   12 offices, 12 people, 12 terms, 0 vacancies.  external_id band -1332198 .. -1332187.
--
-- 🔴🔴 LAKE'S COUNCIL IS SEVEN SINGLE-MEMBER DISTRICTS WITH NO AT-LARGE SEATS. Allen County's is
-- FOUR by district plus THREE at large. Two Indiana counties in one slice, two different councils --
-- the DESCRIBE-REAL-POWERS rule again, and the reason Allen's shape was not inherited here.
--
-- 🔴🔴 ALL SEVEN COUNCIL DISTRICT SEATS ARE DEFERRED FOR WANT OF GEOMETRY, exactly as Gary's six
-- were in IN-4. Lake County publishes every map as "printable PDF files", and its open-data
-- organisation (owner `lakecountyod`, 174 layers) is cadastral and physical -- parcels, centerlines,
-- wetlands, building footprints -- with NO electoral district layer at all. Creating seven offices
-- without geometry would make seven seats no address can reach, which is the defect this slice
-- measured at 671 offices. The post-verify gate ASSERTS their absence.
--   The seven, recorded so the next wave does not re-research them:
--     D1 David Hamm · D2 Ronald G. Brewer Sr. · D3 Charlie Brown · D4 Pete Lindemulder
--     D5 Christine Cid (President) · D6 Ted Bilski · D7 Randy Niemeyer
--
-- 🔴 RONALD G. BREWER SR. IS THE MAN WHO LEFT GARY'S AT-LARGE COUNCIL SEAT (IN-4's change-check
-- found the vacancy but not where he went). He now sits on Lake County Council District 2. He is
-- NOT seated by this migration -- that seat is deferred -- but when it is written, check first
-- whether he already holds a Gary office. This slice has now seen TWO people move between
-- jurisdictions mid-term: Mark Spencer (Gary at-large -> Senate District 3) and Brewer.
--
-- 🔴🔴 THE COMMISSIONERS ARE COUNTYWIDE, as in Allen: Indiana law requires a commissioner to RESIDE
-- in a district but elects them COUNTY-WIDE. All three hang on 18089/G4020. Hanging them on
-- district polygons would show a voter one of the three they elect.
--
-- 🔴🔴 AN AGGREGATED SEARCH RETURNED THREE WRONG COMMISSIONERS, AND THE COUNTY'S OWN PAGES CAUGHT
-- IT. A roster search named "Barry Shullanberger, James Williams, Mark Albertson" as Lake County's
-- commissioners, and described a Clerk who is also "Recorder, Auditor, Public Administrator and
-- Surveyor" -- a combined office no Indiana county has. Those belong to a Lake County in ANOTHER
-- STATE. The names below come from lakecountyin.gov's own department pages, read one office at a
-- time. ▶ There are Lake Counties in Indiana, Illinois, Ohio, Florida, California, Colorado,
-- Oregon, Montana, Michigan, Minnesota, Tennessee and South Dakota: for a county this generically
-- named, an aggregated source is a jurisdiction-collision risk, not merely a staleness risk.
--
-- 🔴 ALL TWELVE TERMS ARE 'unknown'. Ballotpedia returns 404 for all thirteen Lake County officials
-- tried. That is NOT a broken method: the same batch returned 14 of 19 for Allen County and 9 of 9
-- for Fort Wayne minutes earlier. Ballotpedia simply does not cover Lake County's officials, as it
-- does not cover Gary's. The county's own pages publish no tenure. GA-2 wrote all 235 Georgia
-- legislative terms 'unknown' for the same reason. No date is invented.
--
-- 🔴 NO term_end. 🔴 NO PARTY. 🔴 alternate_names IS NOT NULL DEFAULT '{}'.
--
-- Idempotent throughout. Ends with a post-verify gate.

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id='18089' AND district_type='COUNTY' AND lower(state)='in') THEN
    RAISE EXCEPTION 'IN-6 pre-flight: the Lake County COUNTY district (18089) is missing.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='18089' AND mtfcc='G4020') THEN
    RAISE EXCEPTION 'IN-6 pre-flight: the Lake County boundary (18089/G4020) is missing; every office would be unreachable.';
  END IF;
END $$;

-- ─── 1. Government ───────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Lake County, Indiana, US', 'County', 'IN', NULL, '18089'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Lake County, Indiana, US');

-- ─── 2. Three chambers ───────────────────────────────────────────────────────
-- 🔴 Lake County Council is created with official_count 7 and ZERO offices. The count records the
-- body's real size; the absence of offices records that their geometry does not exist yet.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM essentials.governments g
JOIN (VALUES
  ('Board of Commissioners', 3),
  ('Lake County Council',    7),
  ('Elected Officials',      9)
) AS v(name, official_count) ON true
WHERE g.name = 'Lake County, Indiana, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Twelve countywide offices ────────────────────────────────────────────

CREATE TEMP TABLE lc_offices(chamber_name text, title text, description text) ON COMMIT DROP;
INSERT INTO lc_offices VALUES
  ('Board of Commissioners', 'Commissioner, District 1',
   'Elected by the whole county; District 1 is a residency requirement for the officeholder, not an electorate.'),
  ('Board of Commissioners', 'Commissioner, District 2',
   'Elected by the whole county; District 2 is a residency requirement for the officeholder, not an electorate.'),
  ('Board of Commissioners', 'Commissioner, District 3',
   'Elected by the whole county; District 3 is a residency requirement for the officeholder, not an electorate.'),
  ('Elected Officials', 'Assessor',              NULL),
  ('Elected Officials', 'Auditor',               NULL),
  ('Elected Officials', 'Clerk of the Circuit Court', 'Clerk of the Lake Circuit and Superior Courts.'),
  ('Elected Officials', 'Coroner',               NULL),
  ('Elected Officials', 'Recorder',              NULL),
  ('Elected Officials', 'Sheriff',               NULL),
  ('Elected Officials', 'Surveyor',              NULL),
  ('Elected Officials', 'Treasurer',             NULL),
  ('Elected Officials', 'Prosecuting Attorney',  'Elected in the 31st Judicial Circuit, which is coterminous with Lake County.');

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'IN', 1, false, 'full'
FROM lc_offices n
JOIN essentials.districts d ON d.geo_id = '18089' AND d.district_type = 'COUNTY' AND lower(d.state) = 'in'
JOIN essentials.governments g ON g.name = 'Lake County, Indiana, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title);

-- ─── 4. Twelve people ────────────────────────────────────────────────────────

CREATE TEMP TABLE lc_people(external_id bigint, full_name text, first_name text, last_name text, title text) ON COMMIT DROP;
INSERT INTO lc_people VALUES
  (-1332187, 'Kyle W. Allen Sr.',    'Kyle',    'Allen',           'Commissioner, District 1'),
  (-1332188, 'Jerry Tippy',          'Jerry',   'Tippy',           'Commissioner, District 2'),
  (-1332189, 'Michael C. Repay',     'Michael', 'Repay',           'Commissioner, District 3'),
  (-1332190, 'LaTonya Spearman',     'LaTonya', 'Spearman',        'Assessor'),
  (-1332191, 'Peggy Holinga Katona', 'Peggy',   'Holinga Katona',  'Auditor'),
  (-1332192, 'Michael A. Brown',     'Michael', 'Brown',           'Clerk of the Circuit Court'),
  (-1332193, 'David J. Pastrick',    'David',   'Pastrick',        'Coroner'),
  (-1332194, 'Gina Pimentel',        'Gina',    'Pimentel',        'Recorder'),
  (-1332195, 'Oscar Martinez',       'Oscar',   'Martinez',        'Sheriff'),
  (-1332196, 'Bill Emerson Jr.',     'Bill',    'Emerson',         'Surveyor'),
  (-1332197, 'John Petalas',         'John',    'Petalas',         'Treasurer'),
  (-1332198, 'Bernard A. Carter',    'Bernard', 'Carter',          'Prosecuting Attorney');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Lake County, Indiana department pages on lakecountyin.gov, read one office at a time 2026-09-10 (CC_0095, IN-6)',
       '{}'
FROM lc_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 5. Twelve terms, all open-ended at 'unknown' ────────────────────────────

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',
       'Lake County IN-6 (CC_0095): no tenure start is published. Ballotpedia returns 404 for every Lake County official (the same batch returned 14/19 for Allen County), and the county publishes none.'
FROM lc_people n
JOIN essentials.districts d ON d.geo_id = '18089' AND d.district_type = 'COUNTY' AND lower(d.state) = 'in'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = n.title
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'Lake County, Indiana, US'
JOIN essentials.politicians p ON p.external_id = n.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_ch int; v_off int; v_seated int; v_comm int; v_officers int; v_cncl int; v_ended int; v_dated int; v_cncl_count int;
BEGIN
  SELECT count(*) INTO v_ch FROM essentials.chambers c
   JOIN essentials.governments g ON g.id=c.government_id WHERE g.name='Lake County, Indiana, US';
  IF v_ch <> 3 THEN RAISE EXCEPTION 'IN-6: % chambers, expected 3', v_ch; END IF;

  SELECT count(o.id), count(och.politician_id) INTO v_off, v_seated
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id=o.chamber_id
  JOIN essentials.governments g ON g.id=c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
  WHERE g.name='Lake County, Indiana, US';
  IF v_off <> 12 OR v_seated <> 12 THEN
    RAISE EXCEPTION 'IN-6: expected 12 offices all seated, got % offices / % seated', v_off, v_seated;
  END IF;

  SELECT count(*) INTO v_comm FROM essentials.offices o
   JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.governments g ON g.id=c.government_id
   JOIN essentials.districts d ON d.id=o.district_id
   WHERE g.name='Lake County, Indiana, US' AND c.name='Board of Commissioners' AND d.geo_id='18089';
  IF v_comm <> 3 THEN
    RAISE EXCEPTION 'IN-6: % commissioner office(s) on the county polygon, expected 3 -- Indiana elects them county-wide', v_comm;
  END IF;

  SELECT count(*) INTO v_officers FROM essentials.offices o
   JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.governments g ON g.id=c.government_id
   WHERE g.name='Lake County, Indiana, US' AND c.name='Elected Officials';
  IF v_officers <> 9 THEN RAISE EXCEPTION 'IN-6: % elected officers, expected 9', v_officers; END IF;

  -- 🔴 The seven council seats MUST NOT exist. Their geometry does not, so they would be unreachable.
  SELECT count(*) INTO v_cncl FROM essentials.offices o
   JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.governments g ON g.id=c.government_id
   WHERE g.name='Lake County, Indiana, US' AND c.name='Lake County Council';
  IF v_cncl <> 0 THEN
    RAISE EXCEPTION 'IN-6: % Lake County Council office(s) exist. All seven are deferred until district geometry is obtained -- Lake publishes maps as PDF only.', v_cncl;
  END IF;

  SELECT official_count INTO v_cncl_count FROM essentials.chambers c
   JOIN essentials.governments g ON g.id=c.government_id
   WHERE g.name='Lake County, Indiana, US' AND c.name='Lake County Council';
  IF v_cncl_count <> 7 THEN
    RAISE EXCEPTION 'IN-6: Lake County Council official_count is %, expected 7 -- it records the body size, not the seated count', v_cncl_count;
  END IF;

  SELECT count(*) FILTER (WHERE ot.term_start IS NOT NULL), count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id=ot.office_id
  JOIN essentials.chambers c ON c.id=o.chamber_id
  JOIN essentials.governments g ON g.id=c.government_id
  WHERE g.name='Lake County, Indiana, US';
  IF v_dated <> 0 OR v_ended <> 0 THEN
    RAISE EXCEPTION 'IN-6: % terms carry a term_start and % a term_end; no tenure start is published for any Lake County official', v_dated, v_ended;
  END IF;

  RAISE NOTICE 'IN-6 OK: 12 offices, 12 seated, 3 commissioners countywide, 9 officers, 0 council offices (7 deferred), all terms unknown';
END $$;

COMMIT;
