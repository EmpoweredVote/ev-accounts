-- 1639_seed_ca_county_ventura.sql
--
-- CA county wave: Ventura County. 6 countywide elected officials, 829,590 residents.
-- Wave total: 11 counties, 55 seats, 20.08M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- venturacounty.gov and every department subdomain sit behind a WAF that answers plain fetches
-- with "The requested URL was rejected" (HTTP 200, 269 bytes -- it does NOT look like an error to
-- a status-code check). vcportal.venturacounty.gov is NOT walled, so the roster comes from the
-- county's own ACFR, "LISTING OF PRINCIPAL OFFICIALS / JUNE 30, 2025", section headed
-- ELECTED OFFICIALS -> Other Elected Officials, read as a binary PDF (page 14, PDF page 20 of):
--   https://vcportal.venturacounty.gov/auditor/docs/financial-reports/
--     Annual%20Comprehensive%20Financial%20Reports-2025/Annual%20Comprehensive%20Financial%20Report%202025.pdf
-- That page lists exactly six non-supervisor elected officers, in a two-column office/name table.
-- Read directly rather than via search, per migration 1633: search summarised Fresno's roster off
-- by one row and the identity gate below cannot catch that (it compares the seated name to what
-- this file INTENDED to seat, so a shifted table produces a green run and wrong data).
--
-- TITLES are verbatim from the county's canonical list of elected offices,
-- venturacounty.gov/government/elected-officials/ (rendered in Playwright), which names the seven
-- elected offices and no people: Assessor, Auditor-Controller, Board of Supervisors,
-- "Clerk-Recorder, Registrar of Voters", District Attorney, Sheriff, Treasurer-Tax Collector.
-- The ACFR calls the third one "Clerk and Recorder"; the department's own site banner reads
-- "County Clerk-Recorder & Registrar of Voters". The county's elected-officials page wins.
-- The Board of Supervisors is out of scope here, as in every other migration of this wave
-- (sub-county districts; the polygons do not exist). Ventura's five supervisors are named on the
-- same ACFR page and remain unseated -- see the wave's todo file.
--
-- ── EACH HOLDER RE-CONFIRMED AGAINST A CURRENT PAGE (the ACFR is 13 months old) ────────────────
--   Taylor      assessor.venturacounty.gov home + press release "Ventura County Assessor
--               Certifies 2026-27 Roll", 2026-07-02
--   Burgh       venturacounty.gov/auditor-controllers-office/ names him Auditor-Controller; the
--               FY2025 ACFR transmittal letter is over his signature
--   Ascencion   clerkrecorder.venturacounty.gov department banner, "Michelle Ascencion: County
--               Clerk and Recorder/Registrar of Voters", on every section of the site
--   Nasarenko   da.venturacounty.gov home + /meet-the-da-and-team/ (site carries an 2026-08 release)
--   Fryhoff     sheriff.venturacounty.gov/welcome/sheriff-james-fryhoff/
--   Horgan      venturacounty.gov/ttc/organization-treasuretax-collector/
--
-- 🔴 ALL SIX OF THESE SEATS WERE ON THE 2026-06-02 PRIMARY BALLOT (four-year terms last filled in
-- June 2022). Winners take office in JANUARY 2027, so the holders below are correct through
-- December 2026 and this county needs the same post-turnover re-check as the rest of the wave.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Fryhoff     2023-01-02  day    His own office publishes "Sheriffs Day 1 Message 1/2/2023".
--   Horgan      2023-01-01  month  The county's TTC page: "elected ... in June, 2022, and began
--                                  her 4 year term in January, 2023." Month named, day not.
--   Taylor      2023-01-01  year   Elected June 2022; the county newsroom calls the June 2023 roll
--                                  "his first certification". No source names month or day.
--   Ascencion   2023-01-01  year   Elected 2022 (first woman/person of colour in the office).
--                                  No county source names the month or day.
--   Nasarenko   2021-01-01  year   APPOINTED, not elected, to succeed Gregory D. Totten -- his own
--                                  office's "Past District Attorneys" page ends Totten at 2021,
--                                  and his bio dates his ELECTION to 2022-06-07, so occupancy
--                                  began in 2021. A widely repeated 2021-01-26 Board vote could
--                                  not be verified against a county document, so it is not used.
--   Burgh       2014-01-01  year   Bracketed from his own office's letterhead, read as PDFs:
--                                  he signs "Assistant Auditor-Controller" on 2014-01-30 and
--                                  2014-04-25, and "Auditor-Controller" on the FY2014-15 Internal
--                                  Audit Plan and the 2015-01-27 board letter. He was elected
--                                  unopposed in June 2014. Occupancy therefore began in 2014,
--                                  mid-year; the day and month are not sourced, so YEAR precision
--                                  with the corpus' 01-01 placeholder (as migration 1637 did for
--                                  Gus Kramer). The stored day is a placeholder, not a claim.
--
-- 🔴 NO DATE IS PROMOTED TO 'day' BY ANALOGY. Kern (migration 1638) could write 2023-01-02 at day
-- precision because its sources named the day. Four of these six could not, and the California
-- rule that county officers take office the first Monday after 1 January is NOT a source for an
-- individual's occupancy -- it is the reason the wave records precision at all.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62111001..6.
-- Pre-flight: 0 external_id collisions; surname sweep over Taylor/Burgh/Ascencion/Nasarenko/
-- Fryhoff/Horgan found no matching person (29 unrelated Taylors, none named Keith), so no row is
-- deduped into.
--
-- Also repoints the district's official_web_url: countyofventura.org still 301s to
-- venturacounty.gov, but the county has moved and the canonical host is the one to store.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor',                            -62111001,'Keith Taylor','Keith','Taylor',NULL,'2023-01-01','year','elected'),
  ('Auditor-Controller',                  -62111002,'Jeffery S. Burgh','Jeffery','Burgh','S','2014-01-01','year','elected'),
  ('Clerk-Recorder, Registrar of Voters', -62111003,'Michelle Ascencion','Michelle','Ascencion',NULL,'2023-01-01','year','elected'),
  ('District Attorney',                   -62111004,'Erik Nasarenko','Erik','Nasarenko',NULL,'2021-01-01','year','appointed'),
  ('Sheriff',                             -62111005,'James Fryhoff','James','Fryhoff',NULL,'2023-01-02','day','elected'),
  ('Treasurer-Tax Collector',             -62111006,'Sue Horgan','Sue','Horgan',NULL,'2023-01-01','month','elected');

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
SELECT 'Ventura County, California, US', 'County', 'CA', '06111'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06111' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06111'
   AND g.geo_id='06111' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

UPDATE essentials.districts d
   SET official_web_url = 'https://venturacounty.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06111'
   AND d.official_web_url IS DISTINCT FROM 'https://venturacounty.gov/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Ventura County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06111' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Ventura County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1639 — Ventura County ACFR FY2025 Listing of Principal Officials (Other Elected Officials), read 2026-08-08',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Ventura County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06111'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06111' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1639 — Ventura County ACFR FY2025 Listing of Principal Officials (Other Elected Officials), read 2026-08-08',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06111';
  IF v_offices <> 6 THEN RAISE EXCEPTION 'Expected 6 Ventura offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06111'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 6 THEN RAISE EXCEPTION 'Expected 6 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06111'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06111'
     AND g.geo_id='06111' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Ventura district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06111';
  IF v_url IS DISTINCT FROM 'https://venturacounty.gov/' THEN
    RAISE EXCEPTION 'Ventura official_web_url is %, expected https://venturacounty.gov/', v_url;
  END IF;
END $$;

COMMIT;
