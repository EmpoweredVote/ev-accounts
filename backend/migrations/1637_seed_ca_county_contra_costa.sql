-- 1637_seed_ca_county_contra_costa.sql
--
-- CA county wave: Contra Costa County. 6 countywide elected officials, 1.16M residents.
-- Wave total: 9 counties, 44 seats, 18.34M residents.
--
-- Titles are verbatim from the county's own ORGANISATIONAL CHART, where italics mark the elected
-- offices (contracosta.ca.gov/DocumentCenter/View/39121/ContraCostaCountyOrgChart, read as a PDF).
-- The chart names the offices but no people, so each holder was confirmed from a county-published
-- page, one at a time -- never from a search summary (see migration 1633 for why).
--   Assessor                        Directory.aspx?DID=16 + the 2026-27 assessment roll letter
--   Auditor-Controller              /192/Auditor-Controller and Directory.aspx?DID=57
--   County Clerk-Recorder/Elections contracostavote.gov
--   District Attorney               /9975 (contracostada.org redirects here)
--   Sheriff-Coroner                 cocosheriff.org sheriff biography
--   Treasurer/Tax Collector         /199/Treasurer---Tax-Collector
--
-- 🔴 A STALE PRIOR BELIEF, CORRECTED BY CHECKING. Robert Campbell was Auditor-Controller for 30+
-- years and is the name most sources still carry. He RETIRED; the Board appointed Joanne Bohren
-- effective 2025-08-11, and she is not running in 2026. Seeding Campbell would have been wrong.
--
-- 🔴 CROSS-STATE HOMONYM -- NOT DEDUPED INTO. essentials.politicians already holds a
-- "David Livingston" (external_id -4006055) who is an ARIZONA State Representative for State House
-- District 28. Contra Costa's Sheriff-Coroner is a different person, so a new row is created. This
-- is why the surname sweep runs before every seed.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Becton      appointed; sworn 2017-09-17                          day
--   Mierzwa     appointed by the Board effective 2024-01-01           day  (sworn 2024-01-04)
--   Bohren      appointed effective 2025-08-11                        day
--   Livingston  elected 2010-06-08; sworn 2011-01-03                  day
--   Kramer      first elected 1994; CA county officers take office the following January, and no
--               source names the day, so 1995 at YEAR precision -- the year is inferred from the
--               election calendar, the day is not invented
--   Connelly    first term, elected 2022; no source names the day     year
--
-- 🔴 The 2026-06-02 primary elected a NEW Assessor and a NEW Clerk-Recorder. They take office in
-- January 2027, so the holders below are correct through December 2026. This county needs a
-- re-check after the January 2027 turnover, along with the other 2026 winners across the wave.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq); 0 collisions.
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor',                        -62013001,'Gus Kramer','Gus','Kramer',NULL,'1995-01-01','year','elected'),
  ('Auditor-Controller',              -62013002,'Joanne M. Bohren','Joanne','Bohren','M','2025-08-11','day','appointed'),
  ('County Clerk-Recorder/Elections', -62013003,'Kristin B. Connelly','Kristin','Connelly','B','2023-01-01','year','elected'),
  ('District Attorney',               -62013004,'Diana Becton','Diana','Becton',NULL,'2017-09-17','day','appointed'),
  ('Sheriff-Coroner',                 -62013005,'David O. Livingston','David','Livingston','O','2011-01-03','day','elected'),
  ('Treasurer/Tax Collector',         -62013006,'Dan M. Mierzwa','Dan','Mierzwa','M','2024-01-01','day','appointed');

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
SELECT 'Contra Costa County, California, US', 'County', 'CA', '06013'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06013' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06013'
   AND g.geo_id='06013' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Contra Costa County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06013' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Contra Costa County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1637 — Contra Costa County published department/roster pages, read 2026-08-08',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Contra Costa County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06013'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06013' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1637 — Contra Costa County published department/roster pages, read 2026-08-08',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_az text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06013';
  IF v_offices <> 6 THEN RAISE EXCEPTION 'Expected 6 Contra Costa offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06013'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 6 THEN RAISE EXCEPTION 'Expected 6 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06013'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- The Arizona David Livingston must not have been dragged into a California seat.
  SELECT string_agg(o.title || ' @ ' || d.label, '; ') INTO v_az
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id=och.politician_id
    JOIN essentials.offices o ON o.id=och.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE p.external_id = -4006055 AND lower(d.state) = 'ca';
  IF v_az IS NOT NULL THEN
    RAISE EXCEPTION 'Arizona Rep. David Livingston (-4006055) was seated in California: %', v_az;
  END IF;
END $$;

COMMIT;
