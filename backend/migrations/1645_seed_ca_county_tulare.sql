-- 1645_seed_ca_county_tulare.sql
--
-- CA county wave: Tulare County. 4 countywide elected officials, 479,468 residents.
-- Wave total: 16 counties, 80 seats, 23.12M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- tularecounty.ca.gov 403s plain curl and WebFetch (its own "Access denied" template, HTTP 403),
-- so every page below was read through Playwright. Two county primary documents carry the roster:
--
--   1. The county's ACFR for FY ended 2025-06-30, section "LIST OF ELECTED AND APPOINTED OFFICIALS
--      / June 30, 2025" -- printed page 15, PDF page 15 (printed page == PDF page in this report):
--      https://tc-web.widen.net/s/ldfs6xbkn5/tulare-county-acfr-24-25  (6.1 MB, plain curl works --
--      the widen.net CDN is NOT walled even though the county site is).
--   2. The certified Statement of Vote for the 2026-06-02 primary, certified 2026-06-29 by
--      Registrar of Voters Michelle Baldwin:
--      https://tc-web.widen.net/s/fkq6vdxkxx/june-2-2026-statement-of-vote  (352 pp.)
--
-- The ACFR's list gives exactly four elected officers besides the five supervisors, and the SOV's
-- table of contents names the same offices under COUNTY. Each holder was then re-confirmed on that
-- office's own page (2026-08-09).
--
-- 🔴 THE ROV'S OWN "ELECTED OFFICIALS INFORMATION" PAGE IS NOT A ROSTER. Tulare's Registrar
-- publishes a page under exactly the name that produced Stanislaus' roster PDF in migration 1643
-- (/elections/registrar-of-voters/elected-officials), but it contains only links to STATE and
-- FEDERAL officeholders plus a statutory terms-of-office table -- no county names at all. The
-- source class is real (migration 1643) but the page TITLE does not identify it; open it and read
-- it before planning around it.
--
-- 🔴 THE SUPERINTENDENT OF SCHOOLS IS ON THE COUNTY BALLOT AND IS STILL NOT SEEDED -- and the two
-- primary documents disagree about this in a way worth writing down. The SOV lists "County
-- Superintendent of Schools" under its COUNTY heading (Tim A. Hire, unopposed, 54,025 votes), which
-- reads as a county office. The ACFR's list of county elected officials does NOT include it, the
-- county's organizational chart does not show it, and the department directory has no Office of
-- Education entry at all. Same conclusion as Kern (migration 1638) and Riverside (1630): the ROV
-- CONDUCTS the election because that is its job, which is not evidence that the office belongs to
-- county government. Where San Bernardino, Alameda and Fresno DO seed a Superintendent (1631,
-- 1633), it was because each county's own elected-officials roster listed it. The discriminator is
-- the county's roster, never the ballot.
--
-- 🔴 THE REGISTRAR OF VOTERS IS APPOINTED HERE (Michelle Baldwin), per the same ACFR list -- she
-- appears under Appointed Officials. Several counties in this wave elect a Clerk-Recorder who
-- serves as ROV; Tulare folds the Clerk-Recorder into the Assessor and staffs the ROV separately.
-- Sixth distinct office set in the wave.
--
-- ── 🔴 TULARE IS THE FIRST COUNTY IN THIS WAVE WITH NO JANUARY 2027 TURNOVER ────────────────────
-- Both seats on the 2026-06-02 ballot were won by their incumbents, unopposed, with 100.00% of the
-- vote: TARA K. FREITAS (Assessor/Clerk-Recorder, 53,045) and CASS COOK
-- (Auditor-Controller/Treasurer-Tax Collector, 52,618). Every other county in this wave has had at
-- least one seat changing hands in January 2027; this one does not, so it needs no post-turnover
-- re-check. Freitas' own department page states the re-election independently.
--
-- 🔴 AB 759 AGAIN, SIXTH COUNTY (see 1641-1644): no District Attorney and no Sheriff contest on the
-- 2026 ballot -- both are on the presidential cycle, next elected 2028, taking office 2029. A
-- pre-existing junk row in essentials.politicians from cal_access_discovery, the committee
-- "BOUDREAUX FOR SHERIFF 2028", says the same thing from an unrelated direction.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Freitas   2021-04-01  month  "Tara K. Freitas was appointed by the Board of Supervisors to
--                                serve as the 26th Assessor/Clerk-Recorder of Tulare County in
--                                April 2021, elected by voters in 2022, and reelected in 2026" --
--                                the county's own /assessorclerk-recorder/about-us page. No day.
--   Cook      2017-10-01  month  bracketed off his own office's letterhead -- see below.
--   Ward      2012-01-01  year   "Tim has served as District Attorney since 2012" -- his own
--                                office, tulareda.org/tim-ward-da. No county document names the
--                                month; secondary accounts say the Board appointed him after Phil
--                                Cline's retirement and LinkedIn says December, so the year is the
--                                honest answer (the Nasarenko case, migration 1639).
--   Boudreaux 2013-10-08  day    "he was appointed Sheriff-Coroner of Tulare County by the Board of
--                                Supervisors on October 8, 2013. He was elected as the 30th Sheriff
--                                of Tulare County in 2014 and was re-elected in 2018 and 2022" --
--                                his official witness biography filed with the U.S. House Judiciary
--                                Committee for its 2024-09-10 hearing, congress.gov
--                                /118/meeting/house/117608/witnesses/HHRG-118-JU00-Bio-BoudreauxM-20240910-U1.pdf
--
-- 🔴 THE LETTERHEAD TRICK WORKED AGAIN -- BUT THE LETTERHEAD LIED AND THE SIGNATURE BLOCK DID NOT.
-- Tulare publishes the Treasurer's monthly and quarterly investment reports back to 2007. Reading
-- three consecutive ones brackets Cook's start inside two weeks:
--   report dated 2017-10-03 (month ending Aug 31): letterhead Rita A. Woodard, SIGNED Rita A. Woodard
--   report dated 2017-10-20 (quarter ending Sep 30): letterhead Cass Cook, SIGNED Cass Cook
--   report dated 2017-11-17 (month ending Oct 31): letterhead RITA A. WOODARD, SIGNED CASS COOK
-- The November document's letterhead had simply not been updated -- it names a person who had
-- already left, a month after a document that names her successor in both places. Ventura's case
-- (migration 1639) read a start date OFF the letterhead; here the letterhead would have been wrong
-- in both directions. Prefer the signature block: it is what the officer actually asserted.
-- Woodard retired mid-term, so Cook reached office by appointment and was elected in 2018.
--
-- ── STORED official_web_url WAS A DEAD .ca.us HOST ─────────────────────────────────────────────
-- districts.official_web_url held "http://www.co.tulare.ca.us" (from migration 1619), which does
-- not resolve to the county; repointed to https://tularecounty.ca.gov/. This is the benign class
-- from the 2026-08-09 sweep (.planning/todos/2026-08-09-ca-county-url-rot.md), not the Sierra class
-- -- see migration 1646 for that one.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62107001..4.
-- Pre-flight: 0 external_id collisions. Surname sweep found no Boudreaux, no Cass Cook and no Tara
-- Freitas (Ron Freitas is San Joaquin's DA, migration 1641 -- different person, different county),
-- and no Tim/Timothy Ward. The only Boudreaux row in the corpus is a cal_access campaign committee,
-- not a person, so nothing is deduped into.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor/Clerk-Recorder',                    -62107001,'Tara K. Freitas','Tara','Freitas','K','2021-04-01','month','appointed'),
  ('Auditor-Controller/Treasurer-Tax Collector', -62107002,'Cass Cook','Cass','Cook',NULL,'2017-10-01','month','appointed'),
  ('District Attorney',                          -62107003,'Tim Ward','Tim','Ward',NULL,'2012-01-01','year','appointed'),
  ('Sheriff-Coroner',                            -62107004,'Mike Boudreaux','Mike','Boudreaux',NULL,'2013-10-08','day','appointed');

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
SELECT 'Tulare County, California, US', 'County', 'CA', '06107'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06107' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107'
   AND g.geo_id='06107' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

-- co.tulare.ca.us no longer resolves to the county -- see header.
UPDATE essentials.districts d
   SET official_web_url = 'https://tularecounty.ca.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107'
   AND d.official_web_url IS DISTINCT FROM 'https://tularecounty.ca.gov/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Tulare County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06107' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Tulare County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1645 — Tulare County ACFR FY2025 "List of Elected and Appointed Officials" + certified 2026-06-02 Statement of Vote + department pages, read 2026-08-09',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Tulare County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1645 — Tulare County ACFR FY2025 "List of Elected and Appointed Officials" + certified 2026-06-02 Statement of Vote + department pages, read 2026-08-09',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107';
  IF v_offices <> 4 THEN RAISE EXCEPTION 'Expected 4 Tulare offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 4 THEN RAISE EXCEPTION 'Expected 4 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- The Superintendent of Schools is elected on the county ballot but is NOT a county office here
  -- (see header). Fail if a future edit seats Tim A. Hire against that reasoning.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107'
                AND o.title ILIKE '%Superintendent%') THEN
    RAISE EXCEPTION 'A Superintendent of Schools office exists in Tulare County -- see migration 1645 header';
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107'
     AND g.geo_id='06107' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Tulare district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06107';
  IF v_url IS DISTINCT FROM 'https://tularecounty.ca.gov/' THEN
    RAISE EXCEPTION 'Tulare official_web_url is %, expected https://tularecounty.ca.gov/', v_url;
  END IF;
END $$;

COMMIT;
