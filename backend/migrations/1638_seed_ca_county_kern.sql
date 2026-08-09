-- 1638_seed_ca_county_kern.sql
--
-- CA county wave: Kern County. 5 countywide elected officials, 913,820 residents.
-- Wave total: 10 counties, 49 seats, 19.25M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- kerncounty.com 403s ordinary fetches and kernvote.com's Form 700 page lists offices without
-- names, so the roster comes from the county's own ACFR "DIRECTORY OF COUNTY OFFICIALS", section
-- headed ELECTED, read as a binary PDF (page 6 of the FY2024 report):
--   https://www.auditor.co.kern.ca.us/cafr/24CAFR.pdf
-- Titles below are that directory's, normalised from its all-caps.
--
-- 🔴 THE PRIMARY SOURCE REMOVED AN OFFICE I HAD ASSUMED. Kern was expected to elect a
-- Superintendent of Schools (San Bernardino and Alameda both do). The directory lists FIVE elected
-- countywide officers and no Superintendent -- Kern's is a separate entity from county government,
-- as in Riverside. Templating would have created a sixth office with nobody in it.
--
-- Cross-check: the five names and offices here match what web search returned independently, with
-- no row shift. That agreement is worth recording precisely because Fresno's did NOT agree
-- (migration 1633) -- the check is cheap and the failure is invisible without it.
--
-- 🔴 SOURCE VINTAGE. The FY2024 ACFR was published January 2025, so it is ~19 months old. All five
-- were elected to terms running past 2026 (2022 winners take office 2023-01-02 and serve to
-- 2027-01-04), and each name was separately confirmed against a current county or news page while
-- researching the dates below. Kern's Assessor-Recorder and Auditor-Controller-County Clerk were
-- both on the 2026-06-02 ballot; winners take office January 2027, so these holders are correct
-- through December 2026 and this county needs a post-turnover re-check with the rest of the wave.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Avila / Espinoza  assumed office 2023-01-02                     day
--   Zimmer            elected 2018-06-05, sworn 2019-01-11          day
--   Youngblood        elected 2006, took office 2007; no day named  year
--   Kaufman           serving since 2015; no day named              year
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq); 0 collisions.
-- Surname sweep found only unrelated people (Alejandra Avila, Rosemary Lim Youngblood, several
-- Kaufmans) -- all different first names, none deduped into.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor-Recorder',                     -62029001,'Laura Avila','Laura','Avila',NULL,'2023-01-02','day','elected'),
  ('Auditor-Controller-County Clerk',       -62029002,'Aimee X. Espinoza','Aimee','Espinoza','X','2023-01-02','day','elected'),
  ('District Attorney',                     -62029003,'Cynthia Zimmer','Cynthia','Zimmer',NULL,'2019-01-11','day','elected'),
  ('Sheriff-Coroner-Public Administrator',  -62029004,'Donny Youngblood','Donny','Youngblood',NULL,'2007-01-01','year','elected'),
  ('Treasurer-Tax Collector',               -62029005,'Jordan Kaufman','Jordan','Kaufman',NULL,'2015-01-01','year','elected');

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
SELECT 'Kern County, California, US', 'County', 'CA', '06029'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06029' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06029'
   AND g.geo_id='06029' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Kern County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06029' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Kern County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1638 — Kern County ACFR FY2024 Directory of County Officials (ELECTED), read 2026-08-08',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Kern County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06029'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06029' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1638 — Kern County ACFR FY2024 Directory of County Officials (ELECTED), read 2026-08-08',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06029';
  IF v_offices <> 5 THEN RAISE EXCEPTION 'Expected 5 Kern offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06029'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 5 THEN RAISE EXCEPTION 'Expected 5 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06029'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;
END $$;

COMMIT;
