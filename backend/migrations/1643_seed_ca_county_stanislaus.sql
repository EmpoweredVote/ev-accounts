-- 1643_seed_ca_county_stanislaus.sql
--
-- CA county wave: Stanislaus County. 6 countywide elected officials, 551,430 residents.
-- Wave total: 14 counties, 72 seats, 22.16M residents.
--
-- ── SOURCE: THE BEST ROSTER DOCUMENT THIS WAVE HAS FOUND ───────────────────────────────────────
-- The Registrar of Voters publishes a maintained "Elected Officials" list as a PDF:
--   https://www.stanvote.com/pdf/elected-officials-list.pdf   (read as a PDF; header "Updated 7/27/26")
-- Its COUNTY OFFICES table gives office, name, election year and TERM EXPIRES in one place, and it
-- marks appointees with "(A)". Two weeks old at the time of seeding. This is the same source class
-- as Riverside's /elected-officials-compensation page (migration 1630) and is worth looking for
-- first in every remaining county: an ROV roster beats reading six department pages.
--
-- Every name was still confirmed a second time against that office's own page (2026-08-09):
--   Assessor                stancounty.com/news-room/bios/assessor.shtm
--   Auditor-Controller      stancounty.com/news-room/bios/auditor-controller.shtm
--   County Clerk-Recorder   stancounty.com/news-room/bios/clerk-recorder.shtm
--   District Attorney       stanislaus-da.org/da-bio.shtm
--   Sheriff-Coroner         scsdonline.com/administration/office-of-the-sheriff/sheriff-dirkse
--   Treasurer-Tax Collector stancounty.com/news-room/bios/tr-tax.shtm
-- Both sources agree on all six, with no row shift (the check migration 1633 exists to force).
--
-- TITLES are the ROV list's: note "Sheriff-Coroner", not "Sheriff", and "County Clerk-Recorder",
-- though that department's own bio page calls the role "Clerk-Recorder, Registrar of Voters".
--
-- 🔴 A NAME-SHAPED REGEX FOUND A MURDER DEFENDANT. Scanning the DA site for "District Attorney
-- <Name>" returned "District Attorney Peterson" -- from office news about the SCOTT PETERSON case,
-- not the officeholder, who is Jeff Laugero. Nothing but reading the page catches that. Pattern
-- matching over a department site finds the office's subject matter as readily as its staff.
--
-- ── 🔴 AB 759 CONFIRMED BY A COUNTY DOCUMENT ──────────────────────────────────────────────────
-- Migration 1642 established from the bill text that DA and Sheriff moved to the presidential
-- cycle with six-year terms for those elected in 2022. Stanislaus' ROV list states it as data:
--   District Attorney   Jeff Laugero   election year 2028   term expires 1-8-29
--   Sheriff-Coroner     Jeff Dirkse    election year 2028   term expires 1-8-29
--   (Assessor, Auditor-Controller, County Clerk-Recorder, Treasurer-Tax Collector: 2026, 1-4-27)
-- An independent county source agreeing with the statute is the confirmation that pattern needed.
-- So: re-check the other four after January 2027; leave DA and Sheriff-Coroner until 2029.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Laugero    2023-01-03  day    "He was sworn in as Stanislaus County District Attorney
--                                 January 3, 2023" -- his own office's biography page.
--   Dirkse     2019-01-07  day    "Jeff Dirkse was sworn into office as Sheriff-Coroner on
--                                 January 7, 2019" -- his own office's biography page.
--   Gaekle     2013-10-01  month  "has served as Stanislaus County Assessor since October of
--                                 2013. Originally appointed by the Board of Supervisors, he was
--                                 elected ... in 2014 and re-elected in 2018" -- county bio.
--                                 Occupancy runs from the APPOINTMENT, not either election.
--   Dhillon    2024-10-01  month  "Appointed as Auditor-Controller in October 2024" -- county
--                                 bio; the ROV list independently flags him "(A)" for appointed.
--   Linder     2019-01-01  month  elected 2018-06-05; no document names her day
--   Riley      2019-01-01  month  elected 2018-06-05; no document names her day
--
-- 🔴 WHY LINDER AND RILEY ARE MONTH AND NOT 'day', AND WHY JANUARY 2019 AND NOT 2018. San Joaquin
-- (migration 1641) turned up a treasurer who was already signing certified reports five months
-- BEFORE the January his election implied, so "elected in June => took office in January" is not
-- safe on its own. Here the January is carried by the county's own term arithmetic -- the ROV list
-- puts both terms expiring 1-4-27, which is two four-year terms back from January 2019 -- and by
-- the peer elected the same day, Dirkse, being sworn 2019-01-07. The early-start check that caught
-- San Joaquin was attempted and came back INCONCLUSIVE: Stanislaus' November 2018 Statement of the
-- Vote is a ~50 MB scan that would not download intact, and the HTML summary carries no signature
-- block. Month precision is therefore the honest ceiling for these two, and the day is not
-- promoted by analogy with Dirkse.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62099001..6.
-- Pre-flight: 0 external_id collisions. Surname sweep found no Gaekle, Linder, Laugero or Dirkse,
-- one unrelated "Randeep S. Dhillon" (no external_id, no office) and six unrelated Rileys, none
-- named Donna -- all different first names, so nothing is deduped into.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor',                -62099001,'Don H. Gaekle','Don','Gaekle','H','2013-10-01','month','appointed'),
  ('Auditor-Controller',      -62099002,'Mandip Dhillon','Mandip','Dhillon',NULL,'2024-10-01','month','appointed'),
  ('County Clerk-Recorder',   -62099003,'Donna Linder','Donna','Linder',NULL,'2019-01-01','month','elected'),
  ('District Attorney',       -62099004,'Jeff Laugero','Jeff','Laugero',NULL,'2023-01-03','day','elected'),
  ('Sheriff-Coroner',         -62099005,'Jeff Dirkse','Jeff','Dirkse',NULL,'2019-01-07','day','elected'),
  ('Treasurer-Tax Collector', -62099006,'Donna Riley','Donna','Riley',NULL,'2019-01-01','month','elected');

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
SELECT 'Stanislaus County, California, US', 'County', 'CA', '06099'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06099' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06099'
   AND g.geo_id='06099' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Stanislaus County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06099' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Stanislaus County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1643 — Stanislaus County Registrar of Voters Elected Officials list (updated 2026-07-27) + department biographies, read 2026-08-09',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Stanislaus County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06099'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06099' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1643 — Stanislaus County Registrar of Voters Elected Officials list (updated 2026-07-27) + department biographies, read 2026-08-09',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06099';
  IF v_offices <> 6 THEN RAISE EXCEPTION 'Expected 6 Stanislaus offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06099'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 6 THEN RAISE EXCEPTION 'Expected 6 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06099'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06099'
     AND g.geo_id='06099' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Stanislaus district not linked to its government row (%)', v_gov; END IF;
END $$;

COMMIT;
