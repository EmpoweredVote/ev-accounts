-- 1662_seed_ca_county_san_luis_obispo.sql
--
-- CA county wave: San Luis Obispo County. 5 countywide elected officials, 281,639 residents.
-- Wave total: 22 counties, 111 seats, 25.44M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- slocounty.ca.gov answers plain curl -- no WAF, no client-side rendering. Everything below is a
-- county document, read 2026-08-10:
--
--   Office set:   the FY2024-25 ACFR "LIST OF ELECTED AND APPOINTED OFFICIALS / JUNE 30, 2025",
--                 printed p. 10 = PDF p. 20, plus the org chart facing it. Five Elected officials
--                 (besides the Board) and twenty-one Appointed ones.
--   Titles:       the certified "Final Official Election Results" for 2026-06-02 (updated
--                 6/25/2026), which agree with the ACFR line for line.
--   Holders:      each office's own department page, all five naming the same people today.
--   Terms:        the Clerk-Recorder's "Current Officeholders Information" page.
--   Start dates:  Board of Supervisors agenda-item transmittals and minutes -- see below.
--
-- 🔴 THE BOARD MINUTES CHANNEL, SECOND COUNTY RUNNING. SLO publishes on Granicus
-- (slocounty.granicus.com/ViewPublisher.php?view_id=46), whose index runs back to **2006** and
-- carries a MinutesViewer page per meeting listing every agenda item, each linking the item's own
-- PDF transmittal. Three of the five start dates came from there. Retrieval notes for next time:
--   * the item PDFs 404 on slocounty.granicus.com -- fetch them from agenda.slocounty.ca.gov
--     (/iip/sanluisobispo/file/getfile/<id>), which serves the same ids;
--   * meetings before ~2011 use the older DocumentViewer.php?file=slocounty_<hash>.pdf instead of
--     the item list, and that PDF is the actual minutes with motions and votes.
--
-- ── 🔴🔴 SLO SEATS ITS OFFICERS-ELECT EARLY WHEN THE INCUMBENT RETIRES ────────────────────────
-- Three of five reached office by Board appointment, and TWO of those had already won their
-- election and were seated weeks ahead of the January term they had won:
--
--   Dow       BoS item 10/7/2014: "It is recommended that the Board appoint District Attorney
--             -Elect Dan Dow to take office on November 7, 2014 to replace current District
--             Attorney Gerald Shea, who will be retiring November 6, 2014." Nearly two months
--             before the statutory January 2015 start.
--   Hamilton  BoS item 12/11/2018: "appoint Auditor-Controller-Treasurer-Tax Collector-Public
--             Administrator (ACTTC) Elect, James W. Hamilton, to take office as ACTTC on
--             December 15, 2018, to replace current ACTTC, James P. Erb, who is retiring
--             December 14, 2018."
--
-- This is the same habit Merced showed (1660: Warnke, May, Adams all seated in late December).
-- Two counties running, so treat "the winner starts in January" as a hypothesis to be checked in
-- the minutes, not a default -- the error is systematically in the same direction.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Bordonaro  2003-01-01  month  elected. The county's certified "Final Official Results" for the
--                                 March 5, 2002 Consolidated Primary show ASSESSOR: TOM BORDONARO
--                                 28,824 def. DICK FRANK 27,127 -- Frank being the sitting
--                                 incumbent, the seat never fell vacant, so no early seating could
--                                 have happened and the term began the following January. Granicus
--                                 does not reach January 2003, so no county document names the
--                                 day and MONTH precision is the honest encoding. He appears as a
--                                 **re-elected** official in the swearing-in minutes of both
--                                 2007-01-08 and 2011-01-03, which confirms he held the office
--                                 before 2007.
--                                 🔴 THE RESULTS PDF'S TEXT LAYER IS SHIFTED BY A ROW: extracting
--                                 it pairs Bordonaro with Frank's total and drops a line. The
--                                 numbers above are read off the rendered page. Same class as the
--                                 Fresno roster off-by-one (1633) -- read the primary document.
--   Parkinson  2011-01-03  day    elected. BoS minutes 2011-01-03, item S-1, "the time set for the
--                                 swearing in of re-elected and elected County Officials":
--                                 "Ms. Rodewald: Clerk-Recorder, swears in the following Officials:
--                                 Sheriff Elect Ian Parkinson..." Patrick Hedges was still Sheriff
--                                 in August 2010 and a sweep of all 2009-2010 minutes found no
--                                 appointment item, so unlike his colleagues he was not seated
--                                 early. 2011-01-03 is the statutory first Monday after January 1
--                                 AND the date the county records the oath.
--   Dow        2014-11-07  day    appointed (as DA-elect). See above.
--   Hamilton   2018-12-15  day    appointed (as ACTTC-elect). See above.
--   Cano       2021-11-14  day    appointed. Clerk-Recorder Tommy Gong resigned mid-term; the
--                                 Board discussed filling "the remainder of the unexpired term"
--                                 on 2021-07-13, interviewed candidates on 2021-10-12, and on
--                                 2021-11-02 approved "the attached employment agreement with
--                                 Elaina Cano who will serve as the County of San Luis Obispo's
--                                 County Clerk-Recorder, **effective November 14, 2021**, until
--                                 January 2, 2023." She was elected in her own right in 2022 and
--                                 re-elected in 2026.
--
-- 🔴 A CEREMONY IS NOT A START DATE, STATED BY THE COUNTY -- AGAIN. The 2007-01-08 minutes record
-- the Clerk swearing in the re-elected officials and note that "the District Attorney, Gerald Shea,
-- couldn't be here today but was sworn in **last week** in her office." Placer (1658) made the same
-- point from a press release. Only Parkinson's row takes a day from an oath, and only because that
-- oath fell on the statutory term-start date itself.
--
-- ── 🔴 THE OFFICE SET CHANGED WITHIN LIVING MEMORY -- SIX SEATS BECAME FIVE ───────────────────
-- The FY2011-12 ACFR lists SIX elected offices: Assessor (Bordonaro), Auditor-Controller (Gere W.
-- Sibbach), Clerk-Recorder (Julie L. Rodewald), District Attorney (Gerald T. Shea), Sheriff-Coroner
-- (Parkinson) and Treasurer/Tax Collector/Public Administrator (Frank L. Freitas). By FY2013-14 the
-- last two had merged into the single Auditor-Controller-Treasurer-Tax Collector-Public
-- Administrator, first held by James P. Erb. Hamilton's occupancy is recorded against the MERGED
-- office he actually holds; he was a deputy in that department in FY2011-12, not an elected officer.
-- Ninth distinct office set in the wave, and the only one where an ACFR run documents the merger.
--
-- ── 🔴 AB 759, TWELFTH COUNTY -- AND THE MOST PRECISE CITATION YET ────────────────────────────
-- SLO's Current Officeholders page prints the District Attorney and Sheriff-Coroner as "TERM OF
-- OFFICE: Six Years*  TERM EXPIRES: 01/08/2029*" and footnotes them "Gov't. Code 24200,
-- *Elections Code 1300(d)" -- the amended SUBDIVISION, where Stanislaus (1643) stated it only as
-- data and Solano (1650) cited the bill by name. The certified June 2026 ballot agrees from the
-- other side: no DA and no Sheriff contest.
--
-- ── 🔴 NO JANUARY 2027 TURNOVER IN THE SEEDED SEATS ───────────────────────────────────────────
-- Certified June 2026: Bordonaro 71,400 (100.00%, sole candidate), Hamilton 64,656 (100.00%, sole),
-- and Cano 53,455 (63.53%) over Vanessa Rozo 22,482 (26.72%) and Gaea Powell 8,210 (9.76%) -- a
-- majority in the primary, so no November runoff. Fifth county in the wave needing no re-check,
-- after Tulare (1645), Monterey (1656), Placer (1658) and Merced (1660).
--
-- ── 🔴 SUPERINTENDENT OF SCHOOLS -- NOT SEEDED, AND IT IS THE ONE SEAT THAT DOES TURN OVER ────
-- The Clerk-Recorder's officeholders page lists County Superintendent of Schools (James Brescia)
-- under COUNTY OFFICES, but that page is a ballot directory: it also carries city offices and
-- points readers at school and special districts. The discriminator is the county's own government
-- roster, and the ACFR's LIST OF ELECTED AND APPOINTED OFFICIALS carries no Superintendent in
-- EITHER column, nor does the department directory (SLOCOE is a separate entity at slocoe.org).
-- Excluded, as in Kern (1638), Riverside (1630), Tulare (1645), Solano (1650), Santa Barbara
-- (1652), Monterey (1656), Placer (1658) and Merced (1660). Worth recording that Brescia did not
-- run and **Joe Koski** won the seat unopposed in June 2026 -- so a future decision to seed county
-- superintendents must not take Brescia from this page.
--
-- ── official_web_url ──────────────────────────────────────────────────────────────────────────
-- Stored "http://www.co.slo.ca.us" **does not resolve at all** (NXDOMAIN) -- one of the genuinely
-- dead hosts from the 2026-08-09 58-county sweep, not a redirect like Merced's. Repointed to
-- https://www.slocounty.ca.gov/ and guarded on end state.
--
-- 🔴 geo_id 06079 IS SHARED with **Assembly District 79** (district_type STATE_LOWER, state 'CA'),
-- which already carries an office. Every predicate below is scoped by district_type.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62079001..5.
-- Pre-flight: 0 external_id collisions; no politician in the corpus matches any of these five on
-- first+last name (the nearest is Orange County's Auditor-Controller **Andrew N.** Hamilton, a
-- different person -- which is why the identity gate below compares FULL names).
-- No pre-existing SLO chamber, government row or office.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.
-- Board of Supervisors NOT seeded: CA supervisors are elected by sub-county district and those
-- polygons do not exist, so seating them would manufacture unreachable officeholders.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text, suffix text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor',                                                       -62079001,'Tom J. Bordonaro Jr.','Tom','Bordonaro','J','Jr.','2003-01-01','month','elected'),
  ('Auditor-Controller-Treasurer-Tax Collector-Public Administrator',-62079002,'James W. Hamilton','James','Hamilton','W',NULL,'2018-12-15','day','appointed'),
  ('County Clerk-Recorder',                                          -62079003,'Elaina Cano','Elaina','Cano',NULL,NULL,'2021-11-14','day','appointed'),
  ('District Attorney',                                              -62079004,'Dan Dow','Dan','Dow',NULL,NULL,'2014-11-07','day','appointed'),
  ('Sheriff-Coroner',                                                -62079005,'Ian Parkinson','Ian','Parkinson',NULL,NULL,'2011-01-03','day','elected');

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
SELECT 'San Luis Obispo County, California, US', 'County', 'CA', '06079'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06079' AND g.type='County');

-- Scoped by district_type: geo_id 06079 is also Assembly District 79.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079'
   AND g.geo_id='06079' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

UPDATE essentials.districts d
   SET official_web_url = 'https://www.slocounty.ca.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079'
   AND d.official_web_url IS DISTINCT FROM 'https://www.slocounty.ca.gov/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'San Luis Obispo County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06079' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='San Luis Obispo County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, name_suffix, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid, s.suffix,
       'migration 1662 — San Luis Obispo County FY2024-25 ACFR List of Elected and Appointed Officials + certified 2026-06-02 final official results + department pages + Clerk-Recorder current officeholders + BoS items 2014-10-07/2018-12-11/2021-11-02 and minutes 2011-01-03, read 2026-08-10',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='San Luis Obispo County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1662 — San Luis Obispo County FY2024-25 ACFR List of Elected and Appointed Officials + certified 2026-06-02 final official results + department pages + Clerk-Recorder current officeholders + BoS items 2014-10-07/2018-12-11/2021-11-02 and minutes 2011-01-03, read 2026-08-10',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text; v_stale text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079';
  IF v_offices <> 5 THEN RAISE EXCEPTION 'Expected 5 San Luis Obispo offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 5 THEN RAISE EXCEPTION 'Expected 5 seated holders, found %', v_seated; END IF;

  -- Counting cannot see WHO is in a seat. FULL names: Orange County already has an
  -- Auditor-Controller surnamed Hamilton.
  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- Every one of these predecessors left mid-term or was defeated. Fail if a stale roster seats one.
  SELECT string_agg(p.full_name, ', ') INTO v_stale
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
    JOIN essentials.politicians p ON p.id=och.politician_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079'
     AND ((p.last_name ILIKE 'Erb'   AND p.first_name ILIKE 'James%')
       OR (p.last_name ILIKE 'Gong'  AND p.first_name ILIKE 'Tommy%')
       OR (p.last_name ILIKE 'Shea'  AND p.first_name ILIKE 'Gerald%')
       OR (p.last_name ILIKE 'Hedges' AND p.first_name ILIKE 'Pat%')
       OR (p.last_name ILIKE 'Frank' AND p.first_name ILIKE 'Dick%'));
  IF v_stale IS NOT NULL THEN
    RAISE EXCEPTION 'A departed San Luis Obispo officeholder is seated (%) -- see migration 1662 header', v_stale;
  END IF;

  -- The Superintendent of Schools heads a separate entity here -- see header. Note the incumbent
  -- named on the county's ballot directory (Brescia) is in any case leaving in January 2027.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079'
                AND o.title ILIKE '%Superintendent%') THEN
    RAISE EXCEPTION 'A Superintendent of Schools office exists in San Luis Obispo County -- see migration 1662 header';
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079'
     AND g.geo_id='06079' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'San Luis Obispo district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06079';
  IF v_url IS DISTINCT FROM 'https://www.slocounty.ca.gov/' THEN
    RAISE EXCEPTION 'San Luis Obispo official_web_url is %, expected https://www.slocounty.ca.gov/', v_url;
  END IF;
END $$;

COMMIT;
