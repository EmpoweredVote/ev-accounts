-- 1658_seed_ca_county_placer.sql
--
-- CA county wave: Placer County. 6 countywide elected officials, 423,561 residents.
-- Wave total: 20 counties, 101 seats, 24.87M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- placer.ca.gov answers plain curl (no WAF). placercountyelections.gov 403s curl but renders in
-- Playwright. Everything below is a county document:
--
--   Office set + winners: the certified "2026 Statewide Direct Primary June 2, 2026 FINAL RESULTS"
--     (data refreshed 2026-06-29), placercountyelections.gov/Uploads/documents/06022026/
--     06022026_WCAG_Final_Results.pdf -- 9 pp., county contests on p.9.
--   Holders + dates: each office's own department page and the county staff directory
--     (placer.ca.gov/directory.aspx?EID=...), read 2026-08-10.
--   Sheriff's start:  the Board of Supervisors agenda for 2022-07-26, item 1.A.
--
-- 🔴 THE ACFR TRICK FAILS HERE TOO -- THIRD COUNTY RUNNING. Placer publishes a 12 MB ACFR whose
-- Introductory Section contains only a letter of transmittal: no principal-officials list, no org
-- chart (same as Santa Barbara 1652 and San Joaquin 1641). Read the TOC before planning around it.
-- The ACFR is still useful for one thing: its cover names the Auditor-Controller.
--
-- ── 🔴 SIX OFFICES, INCLUDING A MARSHAL -- A COMBINATION NEW TO THIS WAVE ──────────────────────
-- Placer's sheriff is the **Sheriff-Coroner-Marshal** (the county's own staff-directory title, and
-- the title the Board used in its appointment action). Every earlier county in the wave folded at
-- most Coroner into the office; Placer folds in the Marshal as well. Eighth distinct office set.
--
-- ── 🔴 THREE OF SIX REACHED OFFICE BY MID-TERM APPOINTMENT ─────────────────────────────────────
-- Woo (2022), Gire (2020) and Ronco (2016) were each appointed by the Board to finish a
-- predecessor's unexpired term and were subsequently elected. Only Maynard and Butcher started at
-- the statutory January date. This keeps proving the wave's rule that `term_start` is OCCUPANCY
-- start, not current-term start: seating Woo from his election would be six months late, and Gire
-- and Ronco would be years late.
--
-- ── 🔴 AB 759, TENTH COUNTY ────────────────────────────────────────────────────────────────────
-- The certified June 2026 results contain Assessor, Auditor-Controller, Clerk-Recorder-Registrar of
-- Voters and Treasurer-Tax Collector, plus two supervisors and the Superintendent -- and no
-- District Attorney and no Sheriff. Both are on the presidential cycle, next elected 2028.
--
-- ── 🔴 THE SUPERINTENDENT OF SCHOOLS IS ON THE COUNTY BALLOT AND IS NOT SEEDED ─────────────────
-- Gayle Garbolino-Mojica took 98.01% of the June 2026 vote for County Superintendent of Schools.
-- Excluded, as in Kern (1638), Riverside (1630), Tulare (1645), Solano (1650), Santa Barbara (1652)
-- and Monterey (1656): the Placer County Office of Education is a separate entity and no county
-- department listing carries it. A guard below fails if such an office is ever created here.
--
-- ── 🔴 NO JANUARY 2027 TURNOVER ────────────────────────────────────────────────────────────────
-- All four county contests were won by their own incumbents, effectively unopposed (write-ins
-- only): Maynard 99.00%, Sisk 99.00%, Ronco 99.18%, Butcher 98.84%. Placer needs no January 2027
-- re-check -- the third such county, after Tulare (1645) and Monterey (1656).
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Woo      2022-07-26  day    Board of Supervisors agenda, Tuesday 2022-07-26, item 1.A:
--                               "Appoint Undersheriff Wayne Woo as the Placer County
--                               Sheriff-Coroner-Marshal to serve the remainder of Sheriff Devon
--                               Bell's current unexpired term which ends January 2, 2023. If
--                               approved by the Board, the appointment would take effect
--                               immediately." He had already won the June 2022 election.
--                               🔴 His own county bio says only "He was elected Sheriff of Placer
--                               County in 2022" and never mentions the appointment -- seeding from
--                               the bio alone would put his start six months late.
--   Ronco    2016-05-01  month  appointed by the Board on 2016-05-17 to succeed Jim McCauley, then
--                               elected in June 2018. The county's own news release announcing it
--                               now 404s, so this is recorded at MONTH precision rather than the
--                               day the vote is reported to have happened.
--   Gire     2020-04-01  month  appointed by the Board in April 2020 after DA Scott Owens retired
--                               in December 2019; elected subsequently. No live county page names
--                               the day.
--   Maynard  2023-01-01  month  "Matthew R. Maynard was elected to office on January 1, 2023" --
--                               the county's own About the Assessor page. That sentence conflates
--                               the election (June 2022) with taking office, so it is not treated
--                               as a day-level fact; see the note below.
--   Butcher  2023-01-01  month  elected June 2022 to succeed the retiring Jenine Windeshausen;
--                               term began January 2023.
--   Sisk     2012-01-01  year   "Andrew C. Sisk has served as Auditor-Controller since 2012" --
--                               the county staff directory. 🔴 **`how_started` is left NULL for
--                               this row**: no source read establishes whether he was elected or
--                               appointed in 2012, and the column is nullable. An honest NULL beats
--                               defaulting to 'elected'.
--
-- 🔴 A COUNTY NEWS RELEASE SPELLED OUT WHY AN OATH DATE IS NOT A START DATE. Placer's "Seven
-- elected officials take oath of office" (published 2023-01-10) says: "Today's ceremonial
-- swearing-in was preceded by the administration of an official oath of office for each elected
-- representative that was **conducted prior to the end of 2022**." So for these officials there are
-- THREE candidate dates -- an official oath in late 2022, the statutory term start on 2023-01-02,
-- and a ceremonial oath on 2023-01-10 -- and none of them is the ceremony. Month precision on
-- January 2023 is the only honest encoding. This is the same trap as Solano's Zook (1650), stated
-- outright by a county source for once.
--
-- ── official_web_url ──────────────────────────────────────────────────────────────────────────
-- Stored "http://www.placer.ca.gov" was classified OK in the 2026-08-09 sweep (resolves to the
-- county on the same host). Normalised to https, guarded on end state.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62061001..6.
-- Pre-flight: 0 external_id collisions, and no politician in the corpus matches any of these six on
-- first+last name. No pre-existing Placer chamber or government row.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor',                            -62061001,'Matthew R. Maynard','Matthew','Maynard','R','2023-01-01','month','elected'),
  ('Auditor-Controller',                  -62061002,'Andrew C. Sisk','Andrew','Sisk','C','2012-01-01','year',NULL),
  ('Clerk-Recorder-Registrar of Voters',  -62061003,'Ryan Ronco','Ryan','Ronco',NULL,'2016-05-01','month','appointed'),
  ('District Attorney',                   -62061004,'Morgan Gire','Morgan','Gire',NULL,'2020-04-01','month','appointed'),
  ('Sheriff-Coroner-Marshal',             -62061005,'Wayne Woo','Wayne','Woo',NULL,'2022-07-26','day','appointed'),
  ('Treasurer-Tax Collector',             -62061006,'Tristan Butcher','Tristan','Butcher',NULL,'2023-01-01','month','elected');

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
SELECT 'Placer County, California, US', 'County', 'CA', '06061'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06061' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061'
   AND g.geo_id='06061' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

UPDATE essentials.districts d
   SET official_web_url = 'https://www.placer.ca.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061'
   AND d.official_web_url IS DISTINCT FROM 'https://www.placer.ca.gov/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Placer County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06061' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Placer County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1658 — Placer County certified 2026-06-02 final results + department pages + county staff directory + BoS agenda 2022-07-26, read 2026-08-10',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Placer County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1658 — Placer County certified 2026-06-02 final results + department pages + county staff directory + BoS agenda 2022-07-26, read 2026-08-10',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061';
  IF v_offices <> 6 THEN RAISE EXCEPTION 'Expected 6 Placer offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 6 THEN RAISE EXCEPTION 'Expected 6 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- Woo's predecessor retired mid-term in 2022; fail if a stale roster ever seats him here.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
               JOIN essentials.office_current_holder och ON och.office_id=o.id
               JOIN essentials.politicians p ON p.id=och.politician_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061'
                AND p.last_name ILIKE 'Bell') THEN
    RAISE EXCEPTION 'Devon Bell is seated as Placer Sheriff -- he retired in 2022; see migration 1658 header';
  END IF;

  -- The Superintendent of Schools heads a separate entity here -- see header.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061'
                AND o.title ILIKE '%Superintendent%') THEN
    RAISE EXCEPTION 'A Superintendent of Schools office exists in Placer County -- see migration 1658 header';
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061'
     AND g.geo_id='06061' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Placer district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06061';
  IF v_url IS DISTINCT FROM 'https://www.placer.ca.gov/' THEN
    RAISE EXCEPTION 'Placer official_web_url is %, expected https://www.placer.ca.gov/', v_url;
  END IF;
END $$;

COMMIT;
