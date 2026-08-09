-- 1644_seed_ca_county_sonoma.sql
--
-- CA county wave: Sonoma County. 4 countywide elected officials, 481,812 residents.
-- Wave total: 15 counties, 76 seats, 22.64M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- sonomacounty.gov is not bot-walled. Office set from the Registrar of Voters' official
-- "Candidates on the Ballot" page for the 2026-06-02 primary, whose COUNTY OFFICES section lists
-- exactly: County Supervisor 2nd District, County Supervisor 4th District,
-- Auditor-Controller-Treasurer-Tax Collector, County Clerk-Recorder-Assessor. Holders confirmed
-- one at a time on their own department's page (2026-08-09):
--   County Clerk-Recorder-Assessor            .../clerk-recorder-assessor/assessor/about-us
--   Auditor-Controller-Treasurer-Tax Collector .../auditor-controller-treasurer-tax-collector
--   District Attorney                          da.sonomacounty.ca.gov/about-us
--   Sheriff-Coroner                            sonomasheriff.org/sheriff
--
-- 🔴 SONOMA HAS THE MOST CONSOLIDATED OFFICE SET IN THE WAVE: FOUR. Two mega-combined offices do
-- the work that took six seats in Ventura and San Mateo -- one officer is Auditor AND Controller
-- AND Treasurer AND Tax Collector; another is County Clerk AND Recorder AND Assessor (and serves
-- as Registrar of Voters). Sonoma is also the fifth distinct office set in this wave. A template
-- built on any earlier county would have invented two or three seats here with nobody in them.
--
-- 🔴 AB 759 AGAIN (see migrations 1642, 1643): no District Attorney and no Sheriff contest on the
-- 2026 ballot -- both are on the presidential cycle now, next elected 2028, taking office 2029.
-- Only the two seats above turn over in January 2027.
--
-- 🔴 ONE SEAT TURNS OVER IN JANUARY 2027, AND THE CANDIDATE LIST IS WHAT REVEALED IT. The sole
-- candidate for Auditor-Controller-Treasurer-Tax Collector is AMANDA RUCH, whose ballot
-- designation is "Assistant Auditor-Controller" -- i.e. the incumbent did not run. That is the
-- Contra Costa shape (migration 1637), where the deputy standing for the seat meant the incumbent
-- had already retired mid-term. Checked here rather than assumed: the department's own page still
-- describes Erick Roeser in office, so he is the correct holder through December 2026 and Ruch
-- takes office in January 2027. Re-check this county then.
--   Deva Marie Proto ran unopposed for re-election and continues.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Engram    2023-01-02  day    "Eddie was elected June of 2022 as Sonoma County's 35th elected
--                                Sheriff and took office January 2, 2023" -- his own office.
--   Roeser    2017-06-01  month  "Following his predecessor's retirement, the Board of Supervisors
--                                appointed Mr. Roeser as the Auditor-Controller-Treasurer-Tax
--                                Collector in June of 2017. He then went on to win his first
--                                election in June of 2018 and was most recently re-elected in June
--                                of 2022" -- his own department's page. Occupancy runs from the
--                                APPOINTMENT, not from either election.
--   Proto     2019-01-01  month  elected June 2018, sworn in January 2019; no county page names
--                                the day.
--   Rodriguez 2023-01-01  month  elected unopposed June 2022, took office January 2023. Reported
--                                as January 3, but only by press coverage, and a second account
--                                puts the Board's induction of elected officials on January 10 --
--                                two secondary sources that disagree on the day is exactly when
--                                month precision is the honest answer.
--
-- ── 🔴 THE STORED official_web_url POINTED AT A PRIVATE BUSINESS ───────────────────────────────
-- districts.official_web_url held "http://www.sonomacounty.org" (from migration 1619). That domain
-- no longer belongs to the county: it now 301s to https://www.winecountry.com/, a commercial
-- tourism site. This is worse than the stale-alias case fixed for Ventura in migration 1639, where
-- countyofventura.org still redirected to the county. Repointed to https://sonomacounty.gov/.
-- Worth sweeping the other 57 CA counties for the same failure -- a county URL that resolves is
-- not evidence that it resolves to the COUNTY.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62097001..4.
-- Pre-flight: 0 external_id collisions. Surname sweep found no Proto, Roeser or Engram, and twelve
-- unrelated Rodriguezes (none named Carla), so nothing is deduped into.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('County Clerk-Recorder-Assessor',             -62097001,'Deva Marie Proto','Deva','Proto',NULL,'2019-01-01','month','elected'),
  ('Auditor-Controller-Treasurer-Tax Collector', -62097002,'Erick Roeser','Erick','Roeser',NULL,'2017-06-01','month','appointed'),
  ('District Attorney',                          -62097003,'Carla Rodriguez','Carla','Rodriguez',NULL,'2023-01-01','month','elected'),
  ('Sheriff-Coroner',                            -62097004,'Eddie Engram','Eddie','Engram',NULL,'2023-01-02','day','elected');

-- Refuse to run if any external_id already belongs to somebody else (see migration 1631).
DO $$
DECLARE v_bad text;
BEGIN
  SELECT string_agg(p.external_id::text || ' is already ' || p.full_name || ' (wanted ' || s.full_name || ')', '; ')
    INTO v_bad FROM _seed s JOIN essentials.politicians p ON p.external_id = s.ext_id
   WHERE p.full_name IS DISTINCT FROM s.full_name;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'external_id collision -- refusing to seed: %', v_bad;
  END IF;
END $$;

INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'Sonoma County, California, US', 'County', 'CA', '06097'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06097' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097'
   AND g.geo_id='06097' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

-- The old domain now redirects to a commercial tourism site -- see header.
UPDATE essentials.districts d
   SET official_web_url = 'https://sonomacounty.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097'
   AND d.official_web_url IS DISTINCT FROM 'https://sonomacounty.gov/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Sonoma County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06097' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Sonoma County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1644 — Sonoma County Registrar of Voters 2026-06-02 candidates-on-the-ballot list + department pages, read 2026-08-09',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Sonoma County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1644 — Sonoma County Registrar of Voters 2026-06-02 candidates-on-the-ballot list + department pages, read 2026-08-09',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097';
  IF v_offices <> 4 THEN RAISE EXCEPTION 'Expected 4 Sonoma offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 4 THEN RAISE EXCEPTION 'Expected 4 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- The 2026 winner must not be seated early: she takes office January 2027.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
               JOIN essentials.office_current_holder och ON och.office_id=o.id
               JOIN essentials.politicians p ON p.id=och.politician_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097'
                AND p.last_name ILIKE 'Ruch') THEN
    RAISE EXCEPTION 'Amanda Ruch is seated in Sonoma County but does not take office until 2027';
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097'
     AND g.geo_id='06097' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Sonoma district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06097';
  IF v_url IS DISTINCT FROM 'https://sonomacounty.gov/' THEN
    RAISE EXCEPTION 'Sonoma official_web_url is %, expected https://sonomacounty.gov/', v_url;
  END IF;
END $$;

COMMIT;
