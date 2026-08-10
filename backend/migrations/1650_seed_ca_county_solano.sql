-- 1650_seed_ca_county_solano.sql
--
-- CA county wave: Solano County. 5 countywide elected officials, 449,218 residents.
-- Wave total: 17 counties, 85 seats, 23.57M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- solanocounty.gov is NOT bot-walled; everything below downloads with plain curl except the ROV
-- roster, whose panels render client-side (Playwright). Three county primary documents:
--
--   1. ACFR for FY ended 2025-06-30, "Organizational Chart" (printed p.12) -- which has an explicit
--      ELECTED OFFICIALS column -- and "Department Head Listings" (printed p.13). Front matter is
--      roman-numbered, so printed p.12 = PDF p.20:
--      https://content.solanocounty.gov/sites/default/files/2026-02/2025_ACFR_FINAL_v2.pdf
--   2. The Registrar of Voters' "Elected and Appointed Officials" page, SOLANO COUNTY ELECTED
--      OFFICIALS panel, with term ranges and appointment footnotes:
--      /government/registrar-voters/elected-appointed-officials
--   3. The certified District Results Report for the 2026-06-02 primary (185 pp., certified
--      2026-06-30): .../files/2026-06/District_Results-6-30-2026_10-59-52_AM.pdf
--
-- Each holder was then re-confirmed on their own department page (2026-08-10).
--
-- ── 🔴🔴 THE NEWEST, MOST OFFICIAL-LOOKING COUNTY DOCUMENT NAMES THE WRONG SHERIFF ─────────────
-- The FY2025 ACFR was published in February 2026 -- six months ago -- and its Elected Officials
-- chart shows Sheriff/Coroner TOM A. FERRARA, with a photograph. Ferrara is gone. He retired and
-- the Board appointed Undersheriff BRAD DeWALL on 2025-09-26; the ACFR is captioned "June 30, 2025"
-- and is simply reporting the fiscal year it covers. Seeding from the ACFR alone -- the document
-- this wave has leaned on hardest (Kern 1638, Ventura 1639, Tulare 1645) -- would have put a
-- retired sheriff in a live seat, and every count-based gate would have passed.
-- This is the San Mateo/Corpus failure (migration 1642) repeating with a different document class.
-- **Ask what the document is AS OF, not when it was published.** A guard below fails if a
-- "Ferrara" is ever seated in this county.
--
-- ── 🔴 THE SUPERINTENDENT OF SCHOOLS: EXCLUDED, AND THE TWO SOURCES DISAGREE ────────────────────
-- The ROV roster lists SUPERINTENDENT OF SCHOOLS (Nicola Parr) under "SOLANO COUNTY ELECTED
-- OFFICIALS", and the office was on the June 2026 county ballot. It is still not seeded, for the
-- same reason as Tulare (1645), Kern (1638) and Riverside (1630):
--   * the ACFR's ELECTED OFFICIALS column lists five officers and no Superintendent;
--   * the Department Head Listing has no Office of Education entry;
--   * Parr's address on the ROV's own roster is 5100 Business Center Dr / NParr@solanocoe.net --
--     the Solano County Office of Education, a separate legal entity.
-- 🔴 AND THE ROV PAGE SETTLES ITS OWN AUTHORITY: the same page also lists CITY OF BENICIA, CITY OF
-- FAIRFIELD and CITY OF VALLEJO officials, nine school districts, three community colleges and four
-- special districts. It is an ELECTIONS DIRECTORY of every office on the county's ballots, not a
-- roster of county government. Nobody would call Vallejo's city council a county office; the
-- Superintendent is there for exactly the same reason. Sharpens the rule from 1645: the
-- discriminator is the county's own GOVERNMENT roster, and a ballot directory is not one.
--
-- 🔴 THE REGISTRAR OF VOTERS IS APPOINTED HERE TOO (Tim P. Flanagan, who is also the CIO). Seventh
-- distinct office set in the wave: Assessor+Recorder combined, but Treasurer+Tax Collector+County
-- Clerk combined SEPARATELY from the Recorder -- a split no earlier county in this wave has.
--
-- ── 🔴 AB 759, SEVENTH COUNTY -- AND HERE THE COUNTY CITES THE BILL BY NAME ─────────────────────
-- The certified June 2026 results contain no Sheriff and no District Attorney contest. The ROV
-- roster explains why in its own footnote: "**With passage of AB 759, District Attorney and Sheriff
-- elections will move to be in line with Presidential Elections beginning in 2028**", and prints
-- both terms as 2022-2028. Stanislaus (1643) stated it as data; Solano states it as law. Two
-- independent county sources now name the statute.
--
-- ── 🔴 ONE SEAT TURNS OVER IN JANUARY 2027 ─────────────────────────────────────────────────────
-- Certified June 2026 results, all three county contests single-candidate:
--   Assessor/Recorder                      GLENN ZOOK   75,242  -> re-elected, continues
--   Auditor-Controller                     JANINE HARRIS 74,801 -> won her first full term, continues
--   Treasurer/Tax Collector/County Clerk   DENISE DIX    74,051 -> TAKES OFFICE JANUARY 2027
-- Dix is not seeded. The county's own press release of 2026-02-27 says Chuck Lomeli "will retire on
-- December 28, 2026, after 33 years in public service, including 28 years as Solano County's
-- elected Treasurer-Tax Collector-County Clerk", and that he endorsed his Assistant
-- Treasurer-Tax Collector-County Clerk, Denise Dix, to succeed him. That is the Contra Costa (1637)
-- and Sonoma (1644) shape a third time: the deputy standing unopposed because the incumbent is
-- leaving. Lomeli holds the seat through 2026-12-28. A guard below fails if Dix is seated early.
-- **Re-check this county in January 2027.**
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   DeWall  2025-09-26  day    "On September 26, 2025, Brad was appointed Sheriff of Solano County
--                              by the Solano County Board of Supervisors" -- his own county bio
--                              page, /government/sheriff-coroner/sheriff-coroner-brad-dewall. He is
--                              the ONLY one of the five with a bio page on the county site.
--   Harris  2025-02-01  month  ROV roster footnote: "*Appointed by the Board of Supervisors
--                              February 2025". A county source; no day given.
--   Zook    2023-01-01  month  elected June 2022 to succeed Marc Tonnesen, who served four terms
--                              through 2022; took his first oath 2022-12-30 and the term begins the
--                              first Monday after January 1. No county document names the day.
--   Lomeli  1999-01-01  year   derived from the county's own press release above: retiring
--                              2026-12-28 after 28 years as the elected officer puts his start in
--                              January 1999. Year precision because the county states a duration,
--                              not a date.
--   Abrams  2014-01-01  year   she won the June 2014 election, and the Board appointed her early --
--                              in August 2014 -- when Donald du Bain resigned to join the San
--                              Francisco DA's office, so occupancy runs from 2014, not from the
--                              January 2015 date she was originally due to start. Same shape as
--                              Keokham (1641) and Burgh (1639). No county document read for the
--                              month, so YEAR precision, as with Nasarenko (1639).
--
-- ── STORED official_web_url WAS A DEAD HOST ────────────────────────────────────────────────────
-- districts.official_web_url held "http://www.co.solano.ca.us" (migration 1619), classified DEAD in
-- the 2026-08-09 sweep (.planning/todos/2026-08-09-ca-county-url-rot.md) -- it fails to connect at
-- all. Repointed to https://www.solanocounty.gov/, which is where solanocounty.com also lands.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62095001..5.
-- Pre-flight: 0 external_id collisions. No existing Glenn Zook, Janine Harris, Krishna Abrams,
-- DeWall or Charles/Chuck Lomeli anywhere in the corpus; the surname sweep found three unrelated
-- Abramses (Dawn, Nathan L, Karen S, all in positive external_id bands) and a George G. Lomeli, so
-- nothing is deduped into.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor/Recorder',                    -62095001,'Glenn Zook','Glenn','Zook',NULL,'2023-01-01','month','elected'),
  ('Auditor-Controller',                   -62095002,'Janine Harris','Janine','Harris',NULL,'2025-02-01','month','appointed'),
  ('District Attorney',                    -62095003,'Krishna A. Abrams','Krishna','Abrams','A','2014-01-01','year','appointed'),
  ('Sheriff/Coroner',                      -62095004,'Brad DeWall','Brad','DeWall',NULL,'2025-09-26','day','appointed'),
  ('Treasurer/Tax Collector/County Clerk', -62095005,'Charles A. Lomeli','Charles','Lomeli','A','1999-01-01','year','elected');

-- 🔴 RENUMBER REPAIR. This file was written, dry-run and APPLIED as 1649, then renumbered when a
-- parallel session in this shared worktree turned out to hold an (untracked) 1649_deconflate_
-- padilla_senate_vs_inglewood_records.sql. The number is only a filename label to a human, but it
-- is also embedded in `source` text ALREADY WRITTEN TO PROD, so repoint those rows. Guarded and
-- idempotent; a no-op on a fresh database. Second time this wave (see migration 1641) --
-- `check:migrations` compares against origin/master AND local files, so run it immediately before
-- committing, not only when you write the file.
UPDATE essentials.politicians
   SET source = replace(source, 'migration 1649 — Solano', 'migration 1650 — Solano')
 WHERE source LIKE 'migration 1649 — Solano%';

UPDATE essentials.office_terms
   SET source = replace(source, 'migration 1649 — Solano', 'migration 1650 — Solano')
 WHERE source LIKE 'migration 1649 — Solano%';

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
SELECT 'Solano County, California, US', 'County', 'CA', '06095'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06095' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095'
   AND g.geo_id='06095' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

-- co.solano.ca.us does not resolve at all -- see header.
UPDATE essentials.districts d
   SET official_web_url = 'https://www.solanocounty.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095'
   AND d.official_web_url IS DISTINCT FROM 'https://www.solanocounty.gov/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Solano County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06095' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Solano County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1650 — Solano County ACFR FY2025 elected-officials org chart + Registrar of Voters roster + certified 2026-06-02 District Results + department pages, read 2026-08-10',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Solano County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1650 — Solano County ACFR FY2025 elected-officials org chart + Registrar of Voters roster + certified 2026-06-02 District Results + department pages, read 2026-08-10',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095';
  IF v_offices <> 5 THEN RAISE EXCEPTION 'Expected 5 Solano offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 5 THEN RAISE EXCEPTION 'Expected 5 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- Ferrara retired in September 2025; the FY2025 ACFR still pictures him as Sheriff. See header.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
               JOIN essentials.office_current_holder och ON och.office_id=o.id
               JOIN essentials.politicians p ON p.id=och.politician_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095'
                AND p.last_name ILIKE 'Ferrara') THEN
    RAISE EXCEPTION 'Tom Ferrara is seated as Solano Sheriff -- he retired 2025-09; see migration 1650 header';
  END IF;

  -- Denise Dix won the June 2026 election but does not take office until January 2027.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
               JOIN essentials.office_current_holder och ON och.office_id=o.id
               JOIN essentials.politicians p ON p.id=och.politician_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095'
                AND p.last_name ILIKE 'Dix') THEN
    RAISE EXCEPTION 'Denise Dix is seated in Solano County but does not take office until 2027';
  END IF;

  -- The Superintendent of Schools heads a separate entity here -- see header.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095'
                AND o.title ILIKE '%Superintendent%') THEN
    RAISE EXCEPTION 'A Superintendent of Schools office exists in Solano County -- see migration 1650 header';
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095'
     AND g.geo_id='06095' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Solano district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06095';
  IF v_url IS DISTINCT FROM 'https://www.solanocounty.gov/' THEN
    RAISE EXCEPTION 'Solano official_web_url is %, expected https://www.solanocounty.gov/', v_url;
  END IF;
END $$;

COMMIT;
